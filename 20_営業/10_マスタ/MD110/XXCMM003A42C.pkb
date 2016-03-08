CREATE OR REPLACE PACKAGE BODY APPS.XXCMM003A42C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMM003A42C(body)
 * Description      : ロケーションマスタIF出力（自販機管理）
 * MD.050           : ロケーションマスタIF出力（自販機管理） MD050_CMM_003_A42
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          ファイルオープン処理(A-2)
 *  get_target_cust_data   対象顧客取得処理(A-3)
 *  get_detail_cust_data   顧客詳細情報取得(A-4)
 *                         禁則文字チェック処理(A-5)
 *                         CSV出力処理(A-6)
 *  upd_vdms_if_control    更新処理(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/02/04    1.0   K.Kiriu          新規作成
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
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM003A04C';               -- パッケージ名
  -- アプリケーション短縮名
  cv_app_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';                      -- マスタ領域
  cv_app_name_xxccp    CONSTANT VARCHAR2(5)   := 'XXCCP';                      -- 共通・IF領域
  -- プロファイル
  cv_pro_out_file_dir  CONSTANT VARCHAR2(22)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- 自販機CSVファイル出力先
  cv_pro_out_file_file CONSTANT VARCHAR2(22)  := 'XXCMM1_003A42_OUT_FILE';     -- 連携用CSVファイル名
  -- トークン
  cv_tkn_param         CONSTANT VARCHAR2(5)   := 'PARAM';                      -- 入力パラメータ
  cv_tkn_value         CONSTANT VARCHAR2(5)   := 'VALUE';                      -- 入力パラメータ値
  cv_tkn_from_value    CONSTANT VARCHAR2(10)  := 'FROM_VALUE';                 -- パラメータFROM
  cv_tkn_to_value      CONSTANT VARCHAR2(8)   := 'TO_VALUE';                   -- パラメータTO
  cv_tok_ng_profile    CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル
  cv_tok_filename      CONSTANT VARCHAR2(9)   := 'FILE_NAME';                  -- ファイル名
  cv_tkn_table         CONSTANT VARCHAR2(5)   := 'TABLE';                      -- テーブル名
  cv_tkn_ng_err        CONSTANT VARCHAR2(7)   := 'ERR_MSG';                    -- SQLERRM
  cv_tok_rangefrom     CONSTANT VARCHAR2(10)  := 'RANGE_FROM';                 -- 範囲（開始）
  cv_tok_rangeto       CONSTANT VARCHAR2(8)   := 'RANGE_TO';                   -- 範囲（終了）
  cv_tkn_ng_value      CONSTANT VARCHAR2(8)   := 'NG_VALUE';                   -- 項目名
  cv_tkn_word          CONSTANT VARCHAR2(7)   := 'NG_WORD';                    -- 項目名
  cv_tkn_data          CONSTANT VARCHAR2(7)   := 'NG_DATA';                    -- データ
  -- メッセージ
  cv_msg_00001         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- 対象データ無し
  cv_msg_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_00010         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00037         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- 入力パラメータ
  cv_msg_00049         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00049';           -- 文言（最終更新日時（FROM））
  cv_msg_00050         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00050';           -- 文言（最終更新日時（TO））
  cv_msg_00051         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00051';           -- 文言（XXCMM:自販機(OUTBOUND)連携用CSVファイル出力先）
  cv_msg_00052         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00052';           -- 抽出エラー
  cv_msg_00053         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00053';           -- 取得範囲
  cv_msg_00054         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00054';           -- 挿入エラー
  cv_msg_00055         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00055';           -- 更新エラー
  cv_msg_00056         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00056';           -- パラメータ指定エラー
  cv_msg_00216         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00216';           -- 禁則文字存在チェックメッセージ
  cv_msg_00385         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00385';           -- 文言（XXCMM:ロケーションマスタIF出力（自販機管理）連携用CSVファイル名）
  cv_msg_00386         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00386';           -- 文言（自販機S連携制御テーブル）
  cv_msg_00387         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00387';           -- 文言（自販機S連携ロケーション一時表）
  cv_msg_00388         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00388';           -- 文言（顧客コード）
  cv_msg_00389         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00389';           -- 文言（設置先名（社名））
  cv_msg_00390         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00390';           -- 文言（設置先カナ）
  cv_msg_00391         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00391';           -- 文言（設置先FAX）
  cv_msg_05132         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  -- 参照タイプ
  cv_cust_class        CONSTANT VARCHAR2(22)  := 'XXCMM_VD_CUSTOMER_CODE';     -- 自販機S連携対象顧客区分
  cv_cust_vd_place     CONSTANT VARCHAR2(26)  := 'XXCMM_CUST_VD_SECCHI_BASYO'; -- VD設置場所
  -- 実行フラグ
  cv_flg_t             CONSTANT VARCHAR2(1)   := 'T';                          -- 実行フラグ(T:定期)
  cv_flg_r             CONSTANT VARCHAR2(1)   := 'R';                          -- 実行フラグ(R:随時(リカバリ))
  -- 禁則文字チェック用
  cv_chk_cd            CONSTANT VARCHAR2(22)  := 'VENDING_MACHINE_SYSTEM';     -- 自販機システムチェック
  -- 汎用
  cv_date_time         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';      -- 日時フォーマット
  cv_date              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                   -- 日付フォーマット
  cn_one               CONSTANT NUMBER(1)     := 1;                            -- 汎用 NUMBER1
  cv_one               CONSTANT NUMBER(1)     := '1';                          -- 汎用 VARCHAR1
  cv_y                 CONSTANT VARCHAR(1)    := 'Y';                          -- 汎用 'Y'
  cv_n                 CONSTANT VARCHAR(1)    := 'N';                          -- 汎用 'N'
  -- 言語
  cv_language_ja       CONSTANT VARCHAR2(2)   := 'JA';                         -- 言語(JA)
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
  gd_from_date          DATE;                                                  -- 最終更新日（開始）
  gd_to_date            DATE;                                                  -- 最終更新日（終了）
  gv_run_flg            VARCHAR2(1);                                           -- 実行フラグ(T:定期、R:随時(リカバリ))
  -- ファイル出力関連
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;   -- CSVファイル出力先
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;   -- CSVファイル名
  gf_file_handler       utl_file.file_type;                                    -- CSVファイル出力用ハンドラ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from   IN  VARCHAR2,     -- 1.最終更新日（開始）
    iv_update_to     IN  VARCHAR2,     -- 1.最終更新日（終了）
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_process_date           DATE;            -- 前回実行時間
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
    -- ============================================================
    --  固定出力(入力パラメータ部)
    -- ============================================================
    -- 入力パラメータ
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm      -- マスタ領域
                  ,iv_name         => cv_msg_00037           -- メッセージ:入力パラメータ出力メッセージ
                  ,iv_token_name1  => cv_tkn_param           -- トークン  :PARAM
                  ,iv_token_value1 => cv_msg_00049           -- 値        :最終更新日時(FROM)
                  ,iv_token_name2  => cv_tkn_value           -- トークン  :VALUE
                  ,iv_token_value2 => iv_update_from         -- 値        :入力パラメータ「最終更新日時(FROM)」の値
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm      -- マスタ領域
                  ,iv_name         => cv_msg_00037           -- メッセージ:入力パラメータ出力メッセージ
                  ,iv_token_name1  => cv_tkn_param           -- トークン  :PARAM
                  ,iv_token_value1 => cv_msg_00050           -- 値        :最終更新日時(TO)
                  ,iv_token_name2  => cv_tkn_value           -- トークン  :VALUE
                  ,iv_token_value2 => iv_update_to           -- 値        :入力パラメータ「最終更新日時(TO)」の値
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    ----------------------------------------------------------------
    -- 1.業務日付取得を行います。
    ----------------------------------------------------------------
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    ----------------------------------------------------------------
    -- 2．定期・随時処理の処理判定を行います。
    ----------------------------------------------------------------
--
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
    -- 3．定期・随時処理の抽出開始、終了時間を取得します。
    ----------------------------------------------------------------
--
    -- 抽出条件設定
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- 定期処理時
      BEGIN
        -- 自販機S連携制御テーブルより自販機S連携日時(前回実行時間)を取得
        SELECT xvic.vdms_interface_date vdms_interface_date
        INTO   ld_process_date
        FROM   xxcmm_vdms_if_control xvic
        WHERE  control_id = cn_one  --制御ID（ロケーションマスタIF出力)
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
      gd_from_date := ld_process_date;     -- 前回連携日時から
      gd_to_date   := cd_last_update_date; -- 実行時のSYSTEM日付まで
    ELSE
      -- 随時(再送信)時
      gd_from_date := TO_DATE( iv_update_from, cv_date_time);  --パラメータ指定（開始）から
      gd_to_date   := TO_DATE( iv_update_to,   cv_date_time);  --パラメータ指定（終了）まで
    END IF;
--
    ----------------------------------------------------------------
    -- 4．随時処理の場合、パラメータの指定チェックを行います。
    ----------------------------------------------------------------
--
    -- 随時(再送信)時
    IF ( gv_run_flg = cv_flg_r ) THEN
      -- パラメータ指定日時分秒の指定チェック
      IF ( gd_from_date >= gd_to_date ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- マスタ領域
                      ,iv_name         => cv_msg_00056        -- メッセージ:パラメータ指定エラー
                      ,iv_token_name1  => cv_tkn_from_value   -- トークン  :FROM_VALUE
                      ,iv_token_value1 => cv_msg_00049        -- 値        :最終更新日時(FROM)
                      ,iv_token_name2  => cv_tkn_to_value     -- トークン  :TO_VALUE
                      ,iv_token_value2 => cv_msg_00050        -- 値        :最終更新日時(TO)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    ----------------------------------------------------------------
    -- 5．プロファイルの取得を行います。
    ----------------------------------------------------------------
--
    -- XXCMM:自販機(OUTBOUND)連携用CSVファイル出力先を取得
    gv_csv_file_dir    := fnd_profile.value( cv_pro_out_file_dir );
    -- XXCMM:自販機(OUTBOUND)連携用CSVファイル出力先の取得内容チェック
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00002         -- メッセージ:プロファイル取得エラー
                    ,iv_token_name1  => cv_tok_ng_profile    -- トークン  :NG_PROFILE
                    ,iv_token_value1 => cv_msg_00051         -- 値        :CSVファイル出力先
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXCMM:ロケーションマスタ（自販機管理）連携用CSVファイル名を取得
    gv_csv_file_name    := fnd_profile.value( cv_pro_out_file_file );
    -- XXCMM:ロケーションマスタ（自販機管理）連携用CSVファイル名の取得内容チェック
    IF ( gv_csv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- マスタ領域
                    ,iv_name         => cv_msg_00002         -- メッセージ:プロファイル取得エラー
                    ,iv_token_name1  => cv_tok_ng_profile    -- トークン  :NG_PROFILE
                    ,iv_token_value1 => cv_msg_00385         -- 値        :CSVファイル名
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- 6．CSVファイル存在チェックを行います。
    ----------------------------------------------------------------
--
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
    -- データ取得開始・終了の日時を出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxcmm                      -- マスタ領域
                   ,iv_name         => cv_msg_00053                           -- メッセージ:データ取得範囲
                   ,iv_token_name1  => cv_tok_rangefrom                       -- トークン  :RANGE_FROM
                   ,iv_token_value1 => TO_CHAR(gd_from_date,  cv_date_time)   -- 値        :抽出開始日時分秒
                   ,iv_token_name2  => cv_tok_rangeto                         -- トークン  :RANGE_TO
                   ,iv_token_value2 => TO_CHAR(gd_to_date,    cv_date_time)   -- 値        :抽出終了日時分秒
                  );
    -- データ取得範囲をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ファイル名の出力メッセージを取得
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
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
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
    -- 1．CSVファイルを'W'(書き込み)でオープンします。
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
   * Procedure Name   : get_target_cust_data
   * Description      : 対象顧客取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_cust_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_target_cust_data';   -- プログラム名
--
    cv_duns_number_c  CONSTANT VARCHAR2(2)   := '25';                     -- 抽出対象の顧客ステータス(SP決裁済)
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
      -- 1．パーティの登録・変更データ挿入処理
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( hp )
               INDEX( hp xxcmm_hz_parties_n14 )
               USE_NL( hp hca flv )
             */
             hca.cust_account_id      cust_account_id     -- 顧客ID
      FROM   hz_parties               hp                  -- パーティ
            ,hz_cust_accounts         hca                 -- 顧客マスタ
            ,fnd_lookup_values        flv                 -- 参照タイプ
      WHERE  hp.last_update_date   >= gd_from_date        -- 抽出開始日時(時分秒)
      AND    hp.last_update_date   <  gd_to_date          -- 抽出終了日時(時分秒)
      AND    hp.duns_number_c      >= cv_duns_number_c    -- 対象の顧客ステータス(SP決裁済以降)
      AND    hp.party_id           =  hca.party_id
      AND    flv.lookup_type       =  cv_cust_class       -- 自販機S連携対象顧客区分
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      ;
--
      ----------------------------------------------------------------
      -- 2．顧客追加情報の登録・変更データ挿入処理
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( xca )
               INDEX( xca xxcmm_cust_accounts_n20 )
               USE_NL( xca hca hp flv )
            */
             hca.cust_account_id      cust_account_id     -- 顧客ID
      FROM   xxcmm_cust_accounts      xca                 -- 顧客追加情報
            ,hz_cust_accounts         hca                 -- 顧客マスタ
            ,hz_parties               hp                  -- パーティ
            ,fnd_lookup_values        flv                 -- 参照タイプ
      WHERE  xca.last_update_date  >= gd_from_date        -- 抽出開始日時(時分秒)
      AND    xca.last_update_date  <  gd_to_date          -- 抽出終了日時(時分秒)
      AND    xca.customer_id       =  hca.cust_account_id
      AND    hca.party_id          =  hp.party_id
      AND    hp.duns_number_c      >= cv_duns_number_c    -- 対象の顧客ステータス(SP決裁済以降)
      AND    flv.lookup_type       =  cv_cust_class       -- 自販機S連携対象顧客区分
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      AND    NOT EXISTS(
               SELECT /*+
                        USE_NL(xtvli)
                      */
                      1
               FROM   xxcmm_tmp_vdms_location_if xtvli
               WHERE  xtvli.cust_account_id = hca.cust_account_id
             )  --パーティのINSERTで挿入された顧客は対象外とする。
      ;
--
      ----------------------------------------------------------------
      -- 3．顧客事業所の登録・変更データ挿入処理
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( hl )
               INDEX( hl xxcmm_hz_locations_n13 )
               USE_NL( hl hps hcas hca hp flv )
             */
             hca.cust_account_id      cust_account_id     -- 顧客ID
      FROM   hz_locations             hl                  -- 顧客事業所
            ,hz_party_sites           hps                 -- パーティサイト
            ,hz_cust_acct_sites       hcas                -- 顧客サイト
            ,hz_cust_accounts         hca                 -- 顧客マスタ
            ,hz_parties               hp                  -- パーティ
            ,fnd_lookup_values        flv                 -- 参照タイプ
      WHERE  hl.last_update_date   >= gd_from_date
      AND    hl.last_update_date   <  gd_to_date
      AND    hl.location_id        =  hps.location_id
      AND    hps.party_site_id     =  hcas.party_site_id
      AND    hcas.cust_account_id  =  hca.cust_account_id
      AND    hca.party_id          =  hp.party_id
      AND    hp.duns_number_c      >= cv_duns_number_c    -- 対象の顧客ステータス(SP決裁済以降)
      AND    flv.lookup_type       =  cv_cust_class       -- 自販機S連携対象顧客区分
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      AND    NOT EXISTS(
               SELECT /*+
                        USE_NL(xtvli)
                      */
                      1
               FROM   xxcmm_tmp_vdms_location_if xtvli
               WHERE  xtvli.cust_account_id = hca.cust_account_id
             )  --パーティ・顧客追加情報のINSERTで挿入された顧客は対象外とする。
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 挿入エラーメッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm  -- マスタ領域
                        ,iv_name         => cv_msg_00054       -- メッセージ:挿入エラー
                        ,iv_token_name1  => cv_tkn_table       -- トークン  :TABLE
                        ,iv_token_value1 => cv_msg_00387       -- 値        :自販機S連携ロケーション一時表
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
  END get_target_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_cust_data
   * Description      : 顧客詳細情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_detail_cust_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_cust_data'; -- プログラム名
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
    cv_dqu           CONSTANT VARCHAR2(1)   := '"';    -- ダブルクォーテーション(括り文字)
    cv_area_code_1   CONSTANT VARCHAR2(2)   := '00';   -- 抽出項目NULL時の値(設置先都道府県CD)
    cv_area_code_2   CONSTANT VARCHAR2(3)   := '000';  -- 抽出項目NULL時の値(設置先市区郡CD)
    cv_in_out_kbn    CONSTANT VARCHAR2(1)   := '1';    -- 抽出項目NULL時の値(室内外区分)
    cv_hyphen        CONSTANT VARCHAR2(1)   := '-';    -- NULLに置換する文字
--
    -- *** ローカル変数 ***
    lv_warning_flag  VARCHAR2(1);                      -- 警告判定用
    lv_csv_text      VARCHAR2(2000);                   -- 出力１行分文字列変数
--
    -- *** ローカル例外 ***
    output_skip_expt EXCEPTION;                        -- CSVファイル出力スキップ例外
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 出力対象顧客情報取得カーソル
    CURSOR get_cust_cur
    IS
      SELECT /*+
               LEADING( xtvli )
               USE_NL( xtvli hca hp xca hcas hps hl )
             */
              hca.account_number                                         account_number              -- ロケCD
             ,NULL                                                       branch_base                 -- 支社コード
             ,( SELECT  SUBSTRB( hlb.address3, 1, 2 ) address3
                FROM    hz_cust_accounts    hcab                      -- 顧客マスタ
                       ,hz_cust_acct_sites  hcasb                     -- 顧客サイト
                       ,hz_party_sites      hpsb                      -- パーティサイト
                       ,hz_locations        hlb                       -- 顧客事業所
                WHERE  hcab.account_number      = xca.sale_base_code
                AND    hcab.customer_class_code = cv_one              -- 拠点
                AND    hcab.cust_account_id     = hcasb.cust_account_id
                AND    hcasb.party_site_id      = hpsb.party_site_id
                AND    hpsb.location_id         = hlb.location_id
              )                                                          area_code                   -- 支店CD
             ,xca.sale_base_code                                         sale_base_code              -- 営業所CD
             ,NULL                                                       loot_man_code               -- ルートマンコード
             ,SUBSTRB( hp.party_name, 1, 100)                            party_name                  -- 設置先名（社名）
             ,NULL                                                       party_name_abbreviation     -- 設置先略名
             ,SUBSTRB( hp.organization_name_phonetic, 1, 50 )            organization_name_phonetic  -- 設置先ｶﾅ
             ,NULL                                                       party_name_header           -- 設置先名頭文字
             ,hl.postal_code                                             postal_code                 -- 設置先郵便番号
             ,NVL( SUBSTRB( hl.address3, 1, 2 ), cv_area_code_1 )        area_code_1                 -- 設置先都道府県CD
             ,NVL( SUBSTRB( hl.address3, 3, 3 ), cv_area_code_2 )        area_code_2                 -- 設置先市区郡CD
             ,hl.state||hl.city                                          state_city                  -- 設置先住所１
             ,SUBSTRB( hl.address1, 1, 150)                              address1                    -- 設置先住所２
             ,SUBSTRB( hl.address2, 1, 150)                              address2                    -- 設置先住所３
             ,SUBSTRB( REPLACE( hl.address_lines_phonetic, cv_hyphen ), 1, 20 )
                                                                         address_lines_phonetic      -- 設置先TEL
             ,SUBSTRB( REPLACE( hl.address4, cv_hyphen ), 1, 20 )        address4                    -- 設置先FAX
             ,NULL                                                       address_url                 -- 設置先ＵＲＬ
             ,xca.business_low_type                                      business_low_type           -- 取引形態区分
             ,NULL                                                       location_kbn                -- ロケーション区分
             ,NULL                                                       customers                   -- 得意先CD
             ,TO_CHAR( xca.start_tran_date,    cv_date )                 start_tran_date             -- 取引開始日
             ,TO_CHAR( xca.stop_approval_date, cv_date )                 stop_approval_date          -- 取引中止日
             ,NVL(
                   ( SELECT  flv.attribute1    attribute1
                      FROM   fnd_lookup_values flv
                      WHERE  flv.lookup_type     = cv_cust_vd_place
                      AND    flv.lookup_code     = xca.establishment_location
                      AND    flv.enabled_flag    = cv_y
                      AND    flv.language        = cv_language_ja
                      AND    gd_process_date     BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND     NVL( flv.end_date_active,   gd_process_date )
                   )
                  ,cv_in_out_kbn
              )                                                          in_and_out_kbn              -- 室内外区分
             ,NULL                                                       chain_store_code            -- チェーンCD
             ,SUBSTRB(industry_div, 1, 1)                                industry_div_1              -- 大業種CD
             ,SUBSTRB(industry_div, 2, 1)                                industry_div_2              -- 小業種CD
             ,hp.duns_number_c                                           duns_number_c               -- 顧客ステータス
             ,NULL                                                       creation_date               -- ﾚｺｰﾄﾞ作成日
             ,NULL                                                       creation_pg                 -- ﾚｺｰﾄﾞ作成PG
             ,NULL                                                       created_by                  -- ﾚｺｰﾄﾞ作成者
             ,NULL                                                       last_update_date            -- ﾚｺｰﾄﾞ更新日
             ,NULL                                                       last_update_pg              -- ﾚｺｰﾄﾞ更新PG
             ,NULL                                                       last_updated_by             -- ﾚｺｰﾄﾞ更新者
             ,NULL                                                       delete_date                 -- ﾚｺｰﾄﾞ削除日
             ,NULL                                                       delete_pg                   -- ﾚｺｰﾄﾞ削除PG
             ,NULL                                                       deleted_by                  -- ﾚｺｰﾄﾞ削除者
      FROM    xxcmm_tmp_vdms_location_if xtvli -- 自販機S連携ロケーション一時表
             ,hz_cust_accounts           hca   -- 顧客マスタ
             ,hz_parties                 hp    -- パーティ
             ,xxcmm_cust_accounts        xca   -- 顧客追加情報
             ,hz_cust_acct_sites         hcas  -- 顧客サイト
             ,hz_party_sites             hps   -- パーティサイト
             ,hz_locations               hl    -- 顧客事業所
      WHERE   xtvli.cust_account_id    = hca.cust_account_id
      AND     hca.party_id             = hp.party_id
      AND     hca.cust_account_id      = xca.customer_id
      AND     hca.cust_account_id      = hcas.cust_account_id
      AND     hcas.party_site_id       = hps.party_site_id
      AND     hps.location_id          = hl.location_id
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
    <<get_cust_loop>>
    FOR get_cust_rec IN get_cust_cur LOOP
--
      -- 初期化
      lv_warning_flag := cv_n;  -- 警告フラグ
      -- 対象件数カウント
      gn_target_cnt   := gn_target_cnt + 1;
--
      BEGIN
--
        -- ===============================
        -- 禁則文字チェック処理(A-5)
        -- ===============================
--
        -- 設置先名（社名）
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.party_name, cv_chk_cd) = FALSE) THEN
          -- 禁則文字存在チェックメッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- マスタ領域
                        ,iv_name         => cv_msg_00216                  -- メッセージ:禁則文字存在チェックメッセージ
                        ,iv_token_name1  => cv_tkn_ng_value               -- トークン  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00389                  -- 値        :設置先名（社名）
                        ,iv_token_name2  => cv_tkn_word                   -- トークン  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- 値        :顧客コード
                        ,iv_token_name3  => cv_tkn_data                   -- トークン  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- 値        :取得した顧客コードの値
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --フラグON
          lv_warning_flag := cv_y;
        END IF;
        -- 設置先ｶﾅ
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.organization_name_phonetic, cv_chk_cd) = FALSE) THEN
          -- 禁則文字存在チェックメッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- マスタ領域
                        ,iv_name         => cv_msg_00216                  -- メッセージ:禁則文字存在チェックメッセージ
                        ,iv_token_name1  => cv_tkn_ng_value               -- トークン  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00390                  -- 値        :設置先カナ
                        ,iv_token_name2  => cv_tkn_word                   -- トークン  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- 値        :顧客コード
                        ,iv_token_name3  => cv_tkn_data                   -- トークン  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- 値        :取得した顧客コードの値
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- フラグON
          lv_warning_flag := cv_y;
        END IF;
        -- 設置先FAX
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.address4, cv_chk_cd) = FALSE) THEN
          -- 禁則文字存在チェックメッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- マスタ領域
                        ,iv_name         => cv_msg_00216                  -- メッセージ:禁則文字存在チェックメッセージ
                        ,iv_token_name1  => cv_tkn_ng_value               -- トークン  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00391                  -- 値        :設置先FAX
                        ,iv_token_name2  => cv_tkn_word                   -- トークン  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- 値        :顧客コード
                        ,iv_token_name3  => cv_tkn_data                   -- トークン  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- 値        :取得した顧客コードの値
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- フラグON
          lv_warning_flag := cv_y;
        END IF;
--
        -- チェックエラー時
        IF ( lv_warning_flag = cv_y ) THEN
          -- CSV出力処理(A-6)をスキップする
          RAISE output_skip_expt;
        END IF;
--
        -- ===============================
        -- CSV出力処理(A-6)
        -- ===============================
--
        ----------------------------------------------------------------
        -- 1.出力項目編集
        ----------------------------------------------------------------
        lv_csv_text :=
            cv_dqu || get_cust_rec.account_number             || cv_dqu || cv_com ||  -- ロケCD
            cv_dqu || get_cust_rec.branch_base                || cv_dqu || cv_com ||  -- 支社コード
            cv_dqu || get_cust_rec.area_code                  || cv_dqu || cv_com ||  -- 支店CD
            cv_dqu || get_cust_rec.sale_base_code             || cv_dqu || cv_com ||  -- 営業所CD
            cv_dqu || get_cust_rec.loot_man_code              || cv_dqu || cv_com ||  -- ルートマンコード
            cv_dqu || get_cust_rec.party_name                 || cv_dqu || cv_com ||  -- 設置先名（社名）
            cv_dqu || get_cust_rec.party_name_abbreviation    || cv_dqu || cv_com ||  -- 設置先略名
            cv_dqu || get_cust_rec.organization_name_phonetic || cv_dqu || cv_com ||  -- 設置先ｶﾅ
            cv_dqu || get_cust_rec.party_name_header          || cv_dqu || cv_com ||  -- 設置先名頭文字
            cv_dqu || get_cust_rec.postal_code                || cv_dqu || cv_com ||  -- 設置先郵便番号
            cv_dqu || get_cust_rec.area_code_1                || cv_dqu || cv_com ||  -- 設置先都道府県CD
            cv_dqu || get_cust_rec.area_code_2                || cv_dqu || cv_com ||  -- 設置先市区郡CD
            cv_dqu || get_cust_rec.state_city                 || cv_dqu || cv_com ||  -- 設置先住所１
            cv_dqu || get_cust_rec.address1                   || cv_dqu || cv_com ||  -- 設置先住所２
            cv_dqu || get_cust_rec.address2                   || cv_dqu || cv_com ||  -- 設置先住所３
            cv_dqu || get_cust_rec.address_lines_phonetic     || cv_dqu || cv_com ||  -- 設置先TEL
            cv_dqu || get_cust_rec.address4                   || cv_dqu || cv_com ||  -- 設置先FAX
            cv_dqu || get_cust_rec.address_url                || cv_dqu || cv_com ||  -- 設置先ＵＲＬ
            cv_dqu || get_cust_rec.business_low_type          || cv_dqu || cv_com ||  -- 取引形態区分
            cv_dqu || get_cust_rec.location_kbn               || cv_dqu || cv_com ||  -- ロケーション区分
            cv_dqu || get_cust_rec.customers                  || cv_dqu || cv_com ||  -- 得意先CD
            cv_dqu || get_cust_rec.start_tran_date            || cv_dqu || cv_com ||  -- 取引開始日
            cv_dqu || get_cust_rec.stop_approval_date         || cv_dqu || cv_com ||  -- 取引中止日
            cv_dqu || get_cust_rec.in_and_out_kbn             || cv_dqu || cv_com ||  -- 室内外区分
            cv_dqu || get_cust_rec.chain_store_code           || cv_dqu || cv_com ||  -- チェーンCD
            cv_dqu || get_cust_rec.industry_div_1             || cv_dqu || cv_com ||  -- 大業種CD
            cv_dqu || get_cust_rec.industry_div_2             || cv_dqu || cv_com ||  -- 小業種CD
            cv_dqu || get_cust_rec.duns_number_c              || cv_dqu || cv_com ||  -- 顧客ステータス
            cv_dqu || get_cust_rec.creation_date              || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ作成日
            cv_dqu || get_cust_rec.creation_pg                || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ作成PG
            cv_dqu || get_cust_rec.created_by                 || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ作成者
            cv_dqu || get_cust_rec.last_update_date           || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ更新日
            cv_dqu || get_cust_rec.last_update_pg             || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ更新PG
            cv_dqu || get_cust_rec.last_updated_by            || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ更新者
            cv_dqu || get_cust_rec.delete_date                || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ削除日
            cv_dqu || get_cust_rec.delete_pg                  || cv_dqu || cv_com ||  -- ﾚｺｰﾄﾞ削除PG
            cv_dqu || get_cust_rec.deleted_by                 || cv_dqu               -- ﾚｺｰﾄﾞ削除者
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
      EXCEPTION
        -- 禁則文字エラー
        WHEN output_skip_expt THEN
          gn_warn_cnt := gn_warn_cnt + 1;  --顧客単位に警告件数をカウント
      END;
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
  END get_detail_cust_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vdms_if_control
   * Description      : 更新処理(A-7)
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
      -- 1.自販機S連携制御の更新
      ----------------------------------------------------------------
      UPDATE  xxcmm_vdms_if_control xvif
      SET     xvif.vdms_interface_date    = gd_to_date                 -- 抽出終了日時
             ,xvif.last_updated_by        = cn_last_updated_by
             ,xvif.last_update_date       = cd_last_update_date
             ,xvif.last_update_login      = cn_last_update_login
             ,xvif.request_id             = cn_request_id
             ,xvif.program_application_id = cn_program_application_id
             ,xvif.program_id             = cn_program_id
             ,xvif.program_update_date    = cd_program_update_date
      WHERE  xvif.control_id = cn_one
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
    iv_update_from  IN  VARCHAR2,     -- 1.最終更新日（開始）
    iv_update_to    IN  VARCHAR2,     -- 2.最終更新日（終了）
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
       iv_update_from  => iv_update_from  -- 最終更新日（開始）
      ,iv_update_to    => iv_update_to    -- 最終更新日（終了）
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
    -- 対象顧客取得処理(A-3)
    -- ===============================
    get_target_cust_data(
       ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 顧客詳細情報取得処理(A-4)
    -- ===============================
    get_detail_cust_data(
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
      -- 更新処理(A-7)
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_update_from  IN  VARCHAR2,      --   1.最終更新日（開始）
    iv_update_to    IN  VARCHAR2       --   2.最終更新日（終了）
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
       iv_update_from  -- 最終更新日（開始）
      ,iv_update_to    -- 最終更新日（終了）
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
END XXCMM003A42C;
/
