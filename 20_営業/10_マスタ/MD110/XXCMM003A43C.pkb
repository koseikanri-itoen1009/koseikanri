CREATE OR REPLACE PACKAGE BODY APPS.XXCMM003A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM003A43C(body)
 * Description      : 店舗情報マスタ連携（eSM）
 * MD.050           : 店舗情報マスタ連携（eSM） MD050_CMM_003_A43
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          ファイルオープン処理(A-2)
 *  get_cust_data          店舗マスタ情報取得処理(A-3)
 *                         CSV出力処理(A-4)
 *  upd_vdms_if_control    更新処理(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/03/24    1.0   S.Yamashita      新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  no_output_data_expt       EXCEPTION;                                         -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM003A43C';               -- パッケージ名
  -- アプリケーション短縮名
  cv_app_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';                      -- マスタ領域
  cv_app_name_xxccp    CONSTANT VARCHAR2(5)   := 'XXCCP';                      -- 共通・IF領域
  -- プロファイル
  cv_pro_out_file_dir  CONSTANT VARCHAR2(22)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- 自販機CSVファイル出力先
  cv_pro_out_file_name CONSTANT VARCHAR2(22)  := 'XXCMM1_003A43_OUT_FILE';     -- 連携用CSVファイル名
  -- トークン
  cv_tkn_date_from     CONSTANT VARCHAR2(10)  := 'DATE_FROM';                  -- 日付FROM
  cv_tkn_date_to       CONSTANT VARCHAR2(8)   := 'DATE_TO';                    -- 日付TO
  cv_tkn_from_value    CONSTANT VARCHAR2(10)  := 'FROM_VALUE';                 -- FROM
  cv_tkn_to_value      CONSTANT VARCHAR2(8)   := 'TO_VALUE';                   -- TO
  cv_tkn_cust_cd       CONSTANT VARCHAR2(8)   := 'CUST_CD';                    -- 顧客コード
  cv_tok_ng_profile    CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル
  cv_tok_filename      CONSTANT VARCHAR2(9)   := 'FILE_NAME';                  -- ファイル名
  cv_tkn_table         CONSTANT VARCHAR2(5)   := 'TABLE';                      -- テーブル名
  cv_tkn_ng_err        CONSTANT VARCHAR2(7)   := 'ERR_MSG';                    -- SQLERRM
  -- メッセージ
  cv_msg_00001         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- 対象データ無し
  cv_msg_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_00010         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00018         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00052         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00052';           -- 抽出エラー
  cv_msg_00054         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00054';           -- 挿入エラー
  cv_msg_00055         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00055';           -- 更新エラー
  cv_msg_00056         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00056';           -- パラメータ指定エラー
  cv_msg_00399         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00399';           -- 入力パラメータ文字列
  cv_msg_00392         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00392';           -- 電話番号20桁超エラー
  cv_msg_00393         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00393';           -- 担当営業員設定エラー
  cv_msg_00394         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00394';           -- CSVヘッダ文字列（店舗情報マスタ連携）
  cv_msg_05132         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  --
  cv_msg_00395         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00395';           -- 文言：最終更新日時（開始）
  cv_msg_00396         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00396';           -- 文言：最終更新日時（終了）
  cv_msg_00397         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00397';           -- 文言：店舗
  cv_msg_00398         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00398';           -- 文言：，（全角カンマ）
  cv_msg_00386         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00386';           -- 文言：自販機S連携制御テーブル
  -- 参照タイプ
  cv_xxcmm_chain_code  CONSTANT VARCHAR2(20)  := 'XXCMM_CHAIN_CODE';           -- 参照タイプ(チェーン店コード)
  -- 実行フラグ
  cv_flg_t             CONSTANT VARCHAR2(1)   := 'T';                          -- 実行フラグ(T:定期)
  cv_flg_r             CONSTANT VARCHAR2(1)   := 'R';                          -- 実行フラグ(R:随時(リカバリ))
  -- 汎用
  cv_date_time         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';      -- 日時フォーマット
  cn_2                 CONSTANT NUMBER(1)     := 2;                            -- 汎用 NUMBER:2
  cv_y                 CONSTANT VARCHAR(1)    := 'Y';                          -- 汎用 'Y'
  cv_n                 CONSTANT VARCHAR(1)    := 'N';                          -- 汎用 'N'
  cv_1                 CONSTANT VARCHAR(1)    := '1';                          -- 汎用 '1'
  -- 言語
  ct_lang              CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 抽出条件用
  gd_process_date       DATE;                                                  -- 業務日付
  gd_from_date          DATE;                                                  -- 最終更新日時（開始）
  gd_to_date            DATE;                                                  -- 最終更新日時（終了）
  gv_run_flg            VARCHAR2(1);                                           -- 実行フラグ(T:定期、R:随時(リカバリ))
  -- ファイル出力関連
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;   -- CSVファイル出力先
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;   -- CSVファイル名
  gf_file_handler       utl_file.file_type;                                    -- CSVファイル出力用ハンドラ
--
  -- 担当営業員取得用レコード変数
  TYPE gr_employee_num_rec IS RECORD
    (
      employee_num      hz_org_profiles_ext_b.c_ext_attr1%TYPE      -- 担当営業員コード
     ,hopeb_start_date  hz_org_profiles_ext_b.d_ext_attr1%TYPE      -- 適用開始日
     ,hopeb_update_date hz_org_profiles_ext_b.last_update_date%TYPE -- 最終更新日
    );
--
  --  拠点情報格納用テーブル
  TYPE gt_employee_num_ttype IS TABLE OF gr_employee_num_rec INDEX BY BINARY_INTEGER;
  gt_employee_tab  gt_employee_num_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from   IN  VARCHAR2     -- 1.最終更新日時（開始）
   ,iv_update_to     IN  VARCHAR2     -- 2.最終更新日時（終了）
   ,ov_errbuf        OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_last_process_date      DATE;            -- 前回実行時間
    lb_file_exists            BOOLEAN;         -- ファイル存在判断
    ln_file_length            NUMBER(30);      -- ファイルの文字列数
    lbi_block_size            BINARY_INTEGER;  -- ブロックサイズ
    lv_out_msg                VARCHAR2(5000);  -- 出力用
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------------------------------------------------
    -- 業務日付の取得
    ----------------------------------------------------------------
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name_xxcmm  -- アプリケーション短縮名
                   , iv_name        => cv_msg_00018       -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- 定期・随時処理の判定
    ----------------------------------------------------------------
    -- 実行フラグの取得
    IF ( iv_update_from IS NULL ) THEN
      -- 定期実行時
      gv_run_flg := cv_flg_t;
    ELSE
      -- 随時(リカバリ)時
      gv_run_flg := cv_flg_r;
    END IF;
--
    ----------------------------------------------------------------
    -- 抽出開始、終了時間を設定
    ----------------------------------------------------------------
    -- 抽出条件設定
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- 定期処理時の場合
      BEGIN
        -- 自販機S連携日時(前回実行時間)を取得
        SELECT xvic.vdms_interface_date vdms_interface_date
        INTO   ld_last_process_date
        FROM   xxcmm_vdms_if_control xvic  -- 自販機S連携制御テーブル
        WHERE  control_id = cn_2  --制御ID（店舗情報マスタ連携)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        --エラーメッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm  -- マスタ領域
                      ,iv_name         => cv_msg_00052       -- メッセージ:抽出エラー
                      ,iv_token_name1  => cv_tkn_table       -- トークン  :TABLE
                      ,iv_token_value1 => cv_msg_00386       -- 値        :自販機S連携制御テーブル
                      ,iv_token_name2  => cv_tkn_ng_err      -- トークン  :VALUE
                      ,iv_token_value2 => SQLERRM            -- 値        :SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      gd_from_date := ld_last_process_date; -- 前回連携日時から
      gd_to_date   := cd_last_update_date;  -- 実行時のSYSTEM日付まで
    ELSE
      -- 随時(リカバリ)時
      gd_from_date := TO_DATE( iv_update_from, cv_date_time);  --パラメータ指定（開始）から
      gd_to_date   := TO_DATE( iv_update_to,   cv_date_time);  --パラメータ指定（終了）まで
    END IF;
--
    ----------------------------------------------------------------
    -- 随時処理の場合、パラメータの指定チェック
    ----------------------------------------------------------------
    -- 随時(リカバリ)時
    IF ( gv_run_flg = cv_flg_r ) THEN
      -- パラメータ指定日時のチェック
      IF ( gd_from_date >= gd_to_date ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- マスタ領域
                      ,iv_name         => cv_msg_00056        -- メッセージ:パラメータ指定エラー
                      ,iv_token_name1  => cv_tkn_from_value   -- トークン  :FROM_VALUE
                      ,iv_token_value1 => cv_msg_00395        -- 値        :最終更新日時(開始)
                      ,iv_token_name2  => cv_tkn_to_value     -- トークン  :TO_VALUE
                      ,iv_token_value2 => cv_msg_00396        -- 値        :最終更新日時(終了)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    ----------------------------------------------------------------
    -- 抽出開始日時、抽出終了日時出力
    ----------------------------------------------------------------
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm                    -- マスタ領域
                  ,iv_name         => cv_msg_00399                         -- メッセージ:入力パラメータ文字列
                  ,iv_token_name1  => cv_tkn_date_from                     -- トークン  :DATE_FROM
                  ,iv_token_value1 => TO_CHAR(gd_from_date, cv_date_time)  -- 値        :最終更新日時(開始)
                  ,iv_token_name2  => cv_tkn_date_to                       -- トークン  :DATE_TO
                  ,iv_token_value2 => TO_CHAR(gd_to_date, cv_date_time)    -- 値        :最終更新日時(終了)
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    ----------------------------------------------------------------
    -- プロファイルの取得
    ----------------------------------------------------------------
    -- ファイルパス取得
    gv_csv_file_dir := fnd_profile.value( cv_pro_out_file_dir );
    -- 取得に失敗した場合
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00002         -- メッセージ:プロファイル取得エラー
                    ,iv_token_name1  => cv_tok_ng_profile    -- トークン  :NG_PROFILE
                    ,iv_token_value1 => cv_pro_out_file_dir  -- 値        :CSVファイル出力先
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ファイル名取得
    gv_csv_file_name := fnd_profile.value( cv_pro_out_file_name );
    -- 取得に失敗した場合
    IF ( gv_csv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00002         -- メッセージ:プロファイル取得エラー
                    ,iv_token_name1  => cv_tok_ng_profile    -- トークン  :NG_PROFILE
                    ,iv_token_value1 => cv_pro_out_file_name -- 値        :CSVファイル名
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- CSVファイル存在チェック
    ----------------------------------------------------------------
    -- ファイル情報を取得
    utl_file.fgetattr(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- ファイル重複チェック(ファイル存在の有無)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00010         -- メッセージ:CSVファイル存在チェック
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- ファイル名出力
    ----------------------------------------------------------------
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxccp     -- マスタ領域
                   ,iv_name         => cv_msg_05132          -- メッセージ:ファイル名出力メッセージ
                   ,iv_token_name1  => cv_tok_filename       -- トークン  :FILE_NAME
                   ,iv_token_value1 => gv_csv_file_name      -- 値        :取得したファイル名
                  );
    -- ファイル名をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN
     -- *** 処理部共通例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- ファイルオープンモード(書き込みモード)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------------------------------------------------
    -- CSVファイルを'W'(書き込み)でオープン
    ----------------------------------------------------------------
    -- ファイルを開く
    gf_file_handler := utl_file.fopen(
                          location   => gv_csv_file_dir     -- 出力先
                         ,filename   => gv_csv_file_name    -- ファイル名
                         ,open_mode  => cv_csv_mode_w       -- ファイルオープンモード
                       );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : 店舗情報マスタ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_com           CONSTANT VARCHAR2(1)   := ',';    -- カンマ(区切り文字)
    cv_hyphen        CONSTANT VARCHAR2(1)   := '-';    -- ハイフン
    
--
    -- *** ローカル変数 ***
    lv_warning_flag      VARCHAR2(1);          -- 警告判定用
    lv_store_type        VARCHAR2(10);         -- 文字列：店舗
    lv_em_com            VARCHAR2(10);         -- 文字列：，（全角カンマ）
    lv_hdr_text          VARCHAR2(2000);       -- ヘッダ文字列格納用変数
    lv_csv_text          VARCHAR2(5000);       -- 出力１行分文字列変数
    lv_sales_chain_name  VARCHAR2(200);        -- 販売先チェーン名称
    
--
    -- *** ローカル例外 ***
    output_skip_expt EXCEPTION;                        -- CSVファイル出力スキップ例外
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 店舗情報マスタ取得カーソル
    CURSOR get_cust_cur
    IS
      SELECT  hp.party_name             AS  party_name                      -- 顧客名
             ,hca.account_number        AS  account_number                  -- 顧客コード
             ,xca.sales_chain_code      AS  sales_chain_code                -- 販売先チェーンコード
             ,flv.meaning               AS  sales_chain_name                -- 販売先チェーンコード名称
             ,hl.postal_code            AS  postal_code                     -- 郵便番号
             ,hl.state || hl.city || hl.address1 || hl.address2 AS address  -- 住所
             ,hl.address_lines_phonetic AS  address_lines_phonetic          -- 電話番号
             ,xca.sale_base_code        AS  sale_base_code                  -- 売上拠点
             ,hp.last_update_date       AS  hp_update_date                  -- 最終更新日(パーティ)
             ,hca.last_update_date      AS  hca_update_date                 -- 最終更新日(顧客マスタ)
             ,xca.last_update_date      AS  xca_update_date                 -- 最終更新日(顧客追加情報)
             ,hl.last_update_date       AS  hl_update_date                  -- 最終更新日(顧客事業所)
             ,flv.last_update_date      AS  flv_update_date                 -- 最終更新日(参照タイプ)
      FROM    hz_parties                 hp     -- パーティ
             ,hz_cust_accounts           hca    -- 顧客マスタ
             ,xxcmm_cust_accounts        xca    -- 顧客追加情報
             ,hz_cust_acct_sites         hcas   -- 顧客サイト
             ,hz_party_sites             hps    -- パーティサイト
             ,hz_locations               hl     -- 顧客事業所
             ,fnd_lookup_values          flv    -- 参照タイプ
      WHERE   hca.party_id                         = hp.party_id
      AND     hca.cust_account_id                  = xca.customer_id
      AND     hca.cust_account_id                  = hcas.cust_account_id
      AND     hcas.party_site_id                   = hps.party_site_id
      AND     hps.location_id                      = hl.location_id
      AND     flv.lookup_type                      = cv_xxcmm_chain_code      -- タイプ
      AND     flv.language                         = ct_lang                  -- 言語
      AND     flv.enabled_flag                     = cv_y                     -- 有効フラグ
      AND     NVL(flv.start_date_active, gd_process_date) <= gd_process_date  -- 有効開始日
      AND     NVL(flv.end_date_active  , gd_process_date) >= gd_process_date  -- 有効終了日
      AND     flv.lookup_code                      = xca.sales_chain_code     -- コード
      AND     xca.esm_target_div                   = cv_1                     -- ストレポ&商談くん連携対象フラグ
      ;
    -- 出力対象顧客情報取得レコード型
    get_cust_rec get_cust_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 固定文字列取得
    -- 文字列：店舗
    lv_store_type := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- アプリケーション短縮名
                     , iv_name         => cv_msg_00397        -- メッセージコード
                     );
    -- 文字列：，（全角カンマ）
    lv_em_com     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- アプリケーション短縮名
                     , iv_name         => cv_msg_00398        -- メッセージコード
                     );
--
    -- ===============================
    -- CSV出力処理(A-4)
    -- ===============================
    ----------------------------------------------------------------
    -- CSVヘッダ取得
    ----------------------------------------------------------------
    lv_hdr_text := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm   -- アプリケーション短縮名
                   , iv_name         => cv_msg_00394        -- メッセージコード
                   );
--
    ----------------------------------------------------------------
    -- CSVファイルヘッダ出力
    ----------------------------------------------------------------
    -- ファイル書き込み
    UTL_FILE.PUT_LINE( gf_file_handler, lv_hdr_text );
--
    <<get_cust_loop>>
    FOR get_cust_rec IN get_cust_cur LOOP
--
      -- 初期化
      lv_warning_flag := cv_n;  -- 警告フラグ
--
      ----------------------------------------------------------------
      -- 担当営業員チェック
      ----------------------------------------------------------------
      SELECT  hopeb.c_ext_attr1          AS  employee_number   -- 担当営業員コード
             ,hopeb.d_ext_attr1          AS  hopeb_start_date  -- 適用開始日(組織プロファイル拡張)
             ,hopeb.last_update_date     AS  hopeb_update_date -- 最終更新日(組織プロファイル拡張)
      BULK COLLECT INTO gt_employee_tab
      FROM    hz_parties                 hp     -- パーティ
             ,hz_cust_accounts           hca    -- 顧客マスタ
             ,hz_organization_profiles   hop    -- 組織プロファイル
             ,fnd_application            fa     -- アプリケーションマスタ
             ,ego_fnd_dsc_flx_ctx_ext    efdfce -- 摘要フレックスコンテキスト拡張
             ,hz_org_profiles_ext_b      hopeb  -- 組織プロファイル拡張
      WHERE   hca.party_id                         = hp.party_id
      AND     hop.party_id                         = hp.party_id
      AND     hop.effective_end_date               IS NULL
      AND     fa.application_short_name            = 'AR'
      AND     efdfce.application_id                = fa.application_id
      AND     efdfce.descriptive_flexfield_name    = 'HZ_ORG_PROFILES_GROUP'
      AND     efdfce.descriptive_flex_context_code = 'RESOURCE'
      AND     hopeb.attr_group_id                  = efdfce.attr_group_id
      AND     hopeb.organization_profile_id        = hop.organization_profile_id
      AND (
             (    gv_run_flg                       = cv_flg_t                -- 定期実行の場合
              AND hopeb.d_ext_attr1                <= TRUNC(gd_process_date + 1)
              AND NVL(hopeb.d_ext_attr2, TRUNC(gd_process_date + 1)) >= TRUNC(gd_process_date + 1)
             )
        OR   (    gv_run_flg                       = cv_flg_r                -- 随時実行の場合
              AND hopeb.d_ext_attr1                <= TRUNC(gd_process_date)
              AND NVL(hopeb.d_ext_attr2, TRUNC(gd_process_date)) >= TRUNC(gd_process_date)
             )
          )
      AND     hca.account_number                   = get_cust_rec.account_number  -- 顧客コード
      ;
--
      -- 担当営業員が取得できない、または複数取得できる場合
      IF ( gt_employee_tab.COUNT <> 1 ) THEN
      -- 担当営業員設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm           -- マスタ領域
                      ,iv_name         => cv_msg_00393                -- メッセージ:担当営業員設定エラー
                      ,iv_token_name1  => cv_tkn_cust_cd              -- トークン  :CUST_CD
                      ,iv_token_value1 => get_cust_rec.account_number -- 値        :顧客コード
                     );
        lv_errbuf := lv_errmsg;
        FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
        );
--
        -- 対象件数カウント
        gn_target_cnt   := gn_target_cnt + 1;
        -- 警告件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- 担当営業員が正常に取得できる場合
      ELSE
--
        -- 対象レコードが連携対象の場合(最終更新日の条件に合致する場合)
        IF (  (get_cust_rec.hp_update_date          >= gd_from_date AND get_cust_rec.hp_update_date          < gd_to_date)  -- パーティ
           OR (get_cust_rec.hca_update_date         >= gd_from_date AND get_cust_rec.hca_update_date         < gd_to_date)  -- 顧客マスタ
           OR (get_cust_rec.xca_update_date         >= gd_from_date AND get_cust_rec.xca_update_date         < gd_to_date)  -- 顧客追加情報
           OR (get_cust_rec.hl_update_date          >= gd_from_date AND get_cust_rec.hl_update_date          < gd_to_date)  -- 顧客事業所
           OR (get_cust_rec.flv_update_date         >= gd_from_date AND get_cust_rec.flv_update_date         < gd_to_date)  -- 参照タイプ
           OR (gt_employee_tab(1).hopeb_update_date >= gd_from_date AND gt_employee_tab(1).hopeb_update_date < gd_to_date)  -- 組織プロファイル拡張
           OR (gv_run_flg = cv_flg_t AND gt_employee_tab(1).hopeb_start_date = TRUNC(gd_process_date + 1)) -- 定期実行：適用開始日(組織プロファイル拡張)
           OR (gv_run_flg = cv_flg_r AND gt_employee_tab(1).hopeb_start_date = TRUNC(gd_process_date))     -- 随時実行：適用開始日(組織プロファイル拡張)
           )
        THEN
--
          -- 対象件数カウント
          gn_target_cnt   := gn_target_cnt + 1;
--
          ----------------------------------------------------------------
          -- 半角文字を全角文字に変換
          ----------------------------------------------------------------
          lv_sales_chain_name := TO_MULTI_BYTE( get_cust_rec.sales_chain_name );
          ----------------------------------------------------------------
          -- カンマを除去
          ----------------------------------------------------------------
          get_cust_rec.party_name := REPLACE( get_cust_rec.party_name, lv_em_com, '' );  -- 顧客名
          get_cust_rec.address    := REPLACE( get_cust_rec.address   , lv_em_com, '' );  -- 住所
          lv_sales_chain_name     := REPLACE( lv_sales_chain_name    , lv_em_com, '' );  -- 販売先チェーンコード名称
--
          ----------------------------------------------------------------
          -- 電話番号形式チェック
          ----------------------------------------------------------------
          IF ( LENGTHB(get_cust_rec.address_lines_phonetic) > 20 ) THEN
            -- 電話番号20桁超エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name_xxcmm           -- マスタ領域
                          ,iv_name         => cv_msg_00392                -- メッセージ:電話番号20桁超エラー
                          ,iv_token_name1  => cv_tkn_cust_cd              -- トークン  :CUST_CD
                          ,iv_token_value1 => get_cust_rec.account_number -- 値        :顧客コード
                         );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- 警告フラグを設定
            lv_warning_flag := cv_y;
          END IF;
--
          -- 警告エラーが発生していない場合
          IF ( lv_warning_flag = cv_n ) THEN
            ----------------------------------------------------------------
            -- 出力項目編集
            ----------------------------------------------------------------
            lv_csv_text :=
                           ''                                             -- チェーン情報コード（チェーン情報）
              || cv_com || ''                                             -- 顧客名（チェーン情報）（※必須項目です）
              || cv_com || get_cust_rec.sales_chain_code                  -- チェーン店コード（チェーン情報）
              || cv_com || SUBSTR( get_cust_rec.party_name, 1, 100 )      -- 店舗/商談名（店舗）（※必須項目です）
              || cv_com || lv_store_type                                  -- 店舗/商談タイプ（店舗）（※必須項目です）
              || cv_com || get_cust_rec.sales_chain_code                  -- チェーン店コード（店舗）
              || cv_com || SUBSTR( lv_sales_chain_name, 1, 40 )           -- チェーン店コード名称（店舗）
              || cv_com || get_cust_rec.account_number                    -- 顧客コード（9桁）（店舗）
              || cv_com || gt_employee_tab(1).employee_num                -- 自社担当者（店舗）（※必須項目です）
              || cv_com || gt_employee_tab(1).employee_num                -- 主担当者（店舗）
              || cv_com || SUBSTR( get_cust_rec.postal_code, 1, 3 )
                        || cv_hyphen
                        || SUBSTR( get_cust_rec.postal_code, 4, 7 )       -- 郵便番号（店舗）
              || cv_com || SUBSTR( get_cust_rec.address, 1, 450 )         -- 住所（店舗）
              || cv_com || get_cust_rec.address_lines_phonetic            -- 電話番号（店舗）
              || cv_com || get_cust_rec.sale_base_code                    -- 自社担当部署（店舗）
              || cv_com || get_cust_rec.sale_base_code                    -- 主担当(自社担当部署)（店舗）
            ;
--
            ----------------------------------------------------------------
            -- 2.ファイルへの出力
            ----------------------------------------------------------------
            -- ファイル書き込み
            utl_file.put_line( gf_file_handler, lv_csv_text );
--
            -- 正常件数カウント
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            -- 警告件数カウント
            gn_warn_cnt   := gn_warn_cnt + 1;
          END IF;
        END IF;
      END IF;
--
    END LOOP get_cust_loop;
--
    -- ファイルクローズ
    utl_file.fclose( gf_file_handler );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( get_cust_cur%ISOPEN ) THEN
        CLOSE get_cust_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( get_cust_cur%ISOPEN ) THEN
        CLOSE get_cust_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cust_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vdms_if_control
   * Description      : 更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE upd_vdms_if_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vdms_if_control';   -- プログラム名
    --
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      ----------------------------------------------------------------
      -- 自販機S連携制御の更新
      ----------------------------------------------------------------
      UPDATE  xxcmm_vdms_if_control xvif  -- 自販機S連携制御テーブル
      SET     xvif.vdms_interface_date    = gd_to_date                 -- 抽出終了日時
             ,xvif.last_updated_by        = cn_last_updated_by
             ,xvif.last_update_date       = cd_last_update_date
             ,xvif.last_update_login      = cn_last_update_login
             ,xvif.request_id             = cn_request_id
             ,xvif.program_application_id = cn_program_application_id
             ,xvif.program_id             = cn_program_id
             ,xvif.program_update_date    = cd_program_update_date
      WHERE  xvif.control_id = cn_2  --制御ID（店舗情報マスタ連携)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 更新エラーメッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm  -- マスタ領域
                        ,iv_name         => cv_msg_00055       -- メッセージ:更新エラー
                        ,iv_token_name1  => cv_tkn_table       -- トークン  :TALBE
                        ,iv_token_value1 => cv_msg_00386       -- 値        :自販機S連携制御テーブル
                        ,iv_token_name2  => cv_tkn_ng_err      -- トークン  :ERR_MSG
                        ,iv_token_value2 => SQLERRM            -- 値        :SQLERRM
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_vdms_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_update_from  IN  VARCHAR2,     -- 1.最終更新日時（開始）
    iv_update_to    IN  VARCHAR2,     -- 2.最終更新日時（終了）
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  初期処理プロシージャ(A-1)
    -- ===============================
    init(
       iv_update_from  => iv_update_from  -- 最終更新日時（開始）
      ,iv_update_to    => iv_update_to    -- 最終更新日時（終了）
      ,ov_errbuf       => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    --  ファイルオープン処理(A-2)
    -- ===============================================
    open_csv_file(
       ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 店舗マスタ情報取得処理(A-3)、CSV出力処理(A-4)
    -- ===============================
    get_cust_data(
       ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 0件の場合、メッセージ出力後、処理終了
    IF ( gn_target_cnt = 0 ) THEN
      -- コンカレント・出力とログへメッセージ出力
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00001         -- エラー  :対象データなし
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- 対象データ無し例外をスロー
      RAISE no_output_data_expt;
    END IF;
--
    -- 定期処理時のみ更新
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- ===============================
      -- 更新処理(A-5)
      -- ===============================
      upd_vdms_if_control(
         ov_errbuf       => lv_errbuf    -- エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode   -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 警告件数が0でない場合は警告とする
    IF ( gn_warn_cnt <> 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
    -- *** 対象データ無し例外ハンドラ(正常終了) ***
    WHEN no_output_data_expt THEN
      ov_retcode := cv_status_normal;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- ファイルクローズ
      IF ( utl_file.is_open(gf_file_handler) ) THEN
        utl_file.fclose(gf_file_handler);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ
      IF ( utl_file.is_open(gf_file_handler) ) THEN
        utl_file.fclose(gf_file_handler);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode         OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_update_from  IN  VARCHAR2      --   1.最終更新日時（開始）
   ,iv_update_to    IN  VARCHAR2      --   2.最終更新日時（終了）
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_update_from  -- 最終更新日時（開始）
      ,iv_update_to    -- 最終更新日時（終了）
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 件数
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 正常件数
      gn_warn_cnt   := 0; -- スキップ件数
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM003A43C;
/
