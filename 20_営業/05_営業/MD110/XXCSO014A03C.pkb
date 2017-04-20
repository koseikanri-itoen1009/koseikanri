CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A03C(body)
 * Description      : 訪問のみ情報をＥＢＳのタスク情報へ登録します。
 *                    
 * MD.050           : MD050_CSO_014_A03_訪問のみ
 *                    
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_profile_info            プロファイル値取得                              (A-2)
 *  open_csv_file               CSVファイルオープン                             (A-3)
 *  file_format_check           ファイルフォーマットチェック                    (A-5)
 *  chk_mst_is_exists           マスタ存在チェック                              (A-6)
 *  insert_visit_data           訪問のみ情報登録処理                            (A-7)
 *  close_csv_file              CSVファイルクローズ処理                         (A-9)
 *  submain                     メイン処理プロシージャ(
 *                                CSVファイルデータ抽出                         (A-4)
 *                                セーブポイント設定                            (A-8)
 *                              )
 *  main                        コンカレント実行ファイル登録プロシージャ(
 *                                終了処理                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-8     1.0   Kenji.Sai        新規作成
 *  2009-05-01   1.1   Tomoko.Mori      T1_0897対応
 *  2009-05-07   1.2   Tomoko.Mori      T1_0912対応
 *  2017-04-18   1.3   Naoki.Watanabe   [E_本稼動_14025] HHTからのシステム日付連携追加
 *
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal       CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn         CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part            CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont            CONSTANT VARCHAR2(3) := '.';
--
-- #######################  固定グローバル定数宣言部 END   #########################
--
-- #######################  固定グローバル変数宣言部 START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- 対象件数
  gn_normal_cnt          NUMBER;                    -- 正常件数
  gn_error_cnt           NUMBER;                    -- エラー件数
--
-- #######################  固定グローバル変数宣言部 END   #########################
--
-- #######################  固定共通例外宣言部 START       #########################
--
  --*** 処理部共通例外 ***
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  固定共通例外宣言部 END         #########################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A03C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- アクティブ
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- 有効
  cv_enable_houmon_kubun CONSTANT VARCHAR2(1)   := '0';                 -- 有効訪問区分　訪問：0
  cv_insert_kubun        CONSTANT VARCHAR2(1)   := '1';                 -- 登録区分　訪問のみ（HHT）：1
  cv_false               CONSTANT VARCHAR2(10)  := 'FALSE';             -- FALSE
  cv_true                CONSTANT VARCHAR2(10)  := 'TRUE';              -- TRUE  
  cb_false               CONSTANT BOOLEAN       := FALSE;               -- FALSE
  cb_true                CONSTANT BOOLEAN       := TRUE;                -- TRUE  
  cv_r                   CONSTANT VARCHAR2(10)  := 'r';                 -- CSVファイル読み込みフラグ  
--
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00023';  -- パラメータNULLエラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00108';  -- CSVファイル存在チェックエラー
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00247';  -- CSVファイル抽出エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00109';  -- データ抽出エラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00110';  -- 顧客存在チェックエラー
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00111';  -- 営業員コード存在チェックエラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00501';  -- 訪問日の締め日超過エラー
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00174';  -- 訪問区分コード存在チェックエラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00112';  -- データ追加エラー
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00113';  -- データ項目数チェックエラー  
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- DATE型チェックエラー
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00114';  -- 必須チェックエラー
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルクローズエラー
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- パラメータ出力ファイル名  
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00030';  -- サイズチェックエラー
--
  -- トークンコード
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20)  := 'CSV_LOCATION';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20)  := 'CSV_FILE_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_item            CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20)  := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20)  := 'CUSTOMERNAME';
  cv_tkn_sales_cd        CONSTANT VARCHAR2(20)  := 'SALESCODE';
  cv_tkn_sales_nm        CONSTANT VARCHAR2(20)  := 'SALESNAME';
  cv_date_time           CONSTANT VARCHAR2(20)  := 'DATETIME';
  cv_lookup_cd           CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20)  := 'TABLE';  
  cv_tkn_cnt             CONSTANT VARCHAR2(20)  := 'COUNT';
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'csv_dir               = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := 'task_type             = ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'task_status_closed_id = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'ロールバックしました。';    
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'セーブポイントへロールバックしました。';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 行単位データを格納する配列
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- 訪問区分コードテーブル
  TYPE g_houmon_kubun_cd_ttype IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
  -- 訪問実績データ＆関連情報抽出データ
  TYPE g_visit_data_rtype IS RECORD(
    account_number       hz_cust_accounts.account_number%TYPE,     -- 顧客コード
    employee_number      xxcso_resources_v.employee_number%TYPE,   -- 営業員コード
    dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 訪問区分コード１
    dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 訪問区分コード２
    dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 訪問区分コード３
    dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 訪問区分コード４
    dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 訪問区分コード５
    description          jtf_tasks_tl.description%TYPE,            -- 詳細内容
    visit_date           VARCHAR2(8),                              -- 訪問日    YYYYMMDD
    visit_time           VARCHAR2(4),                              -- 訪問時刻  HH24MI
    visit_datetime       DATE,                                     -- 訪問日時  DATE
    resource_id          jtf_rs_resource_extns.resource_id%TYPE,   -- リソースID
    party_id             hz_parties.party_id%TYPE,                 -- パーティID
    party_name           hz_parties.party_name%TYPE,               -- パーティ名称
    account_name         hz_cust_accounts.account_name%TYPE,       -- 顧客名称
    employee_name        xxcso_resources_v.full_name%TYPE,         -- 営業員名称
    customer_status      hz_parties.duns_number_c%TYPE,            -- 顧客ステータス
-- Ver1.3 ADD Start
    input_date           VARCHAR2(8),                              -- システム日付  YYYYMMDD
    input_datetime       DATE                                      -- システム日時（HHT入力日時）
-- Ver1.3 ADD End
  );
  -- *** ユーザー定義グローバル例外 ***
  global_skip_error_expt EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  gv_houmon_csv_file_nm  VARCHAR2(1000);                           -- 訪問CSVファイル名
  gv_hht_in_csv_dir      VARCHAR2(1000);                           -- HHT連携用CSVファイル取得先
  gv_hht_task_type       VARCHAR2(100);                            -- タスクタイプ
  gv_task_status_close   VARCHAR2(100);                            -- タスクステータス
--
  g_visit_data_rec               g_visit_data_rtype;               -- CSVファイルから抽出された分割データ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     iv_file_name         IN         VARCHAR2   -- ファイル名
    ,ov_errbuf            OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_prm_msg    VARCHAR2(5000);  -- 入力パラメータメッセージ格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- パラメータ値出力 
    -- =======================================
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_16             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_fnm               -- トークンコード1
                      ,iv_token_value1 => iv_file_name                 -- トークン値1
                    );
    -- メッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''         || CHR(10) ||     -- 空行の挿入
                lv_prm_msg || CHR(10) ||
                 ''                          -- 空行の挿入
    );
--
    -- CSVファイルがNULLの場合
    IF (iv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    g_visit_data_rec := NULL;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_profile_info(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- プロファイル名 (XXCSO: HHT連携用CSVファイル取得先（XXCSO1_HHT_IN_CSV_DIR）)
    cv_prfnm_hht_in_csv_dir          CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_IN_CSV_DIR';
    -- プロファイル名 (XXCSO: タスクタイプ（タスク登録時の設定値）（XXCSO1_HHT_TASK_TYPE）)
    cv_prfnm_hht_task_type           CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_TASK_TYPE';
    -- プロファイル名 (XXCSO: タスクステータス（クローズ）（XXCSO1_TASK_STATUS_CLOSED_ID）)
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';    
--
    -- *** ローカル変数 ***
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                      VARCHAR2(4000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 変数初期化処理 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_hht_in_csv_dir
                   ,val  => gv_hht_in_csv_dir
                   ); -- HHT連携用CSVファイル取得先
    FND_PROFILE.GET(
                    name => cv_prfnm_hht_task_type
                   ,val  => gv_hht_task_type
                   ); -- タスクタイプ
    FND_PROFILE.GET(
                    name => cv_prfnm_task_status_closed_id
                   ,val  => gv_task_status_close
                   ); -- タスクステータス
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || gv_hht_in_csv_dir    || CHR(10) ||
                 cv_debug_msg3  || gv_hht_task_type     || CHR(10) ||
                 cv_debug_msg4 || gv_task_status_close || CHR(10) ||
                 ''
    );
--
    -- プロファイル値取得に失敗した場合
    -- HHT連携用CSVファイル取得先取得失敗時
    IF (gv_hht_in_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_hht_in_csv_dir;
    -- タスクタイプ取得失敗時
    ELSIF (gv_hht_task_type IS NULL) THEN
      lv_tkn_value := cv_prfnm_hht_task_type;
    -- タスクステータス取得失敗時
    ELSIF (gv_task_status_close IS NULL) THEN
      lv_tkn_value := cv_prfnm_task_status_closed_id;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_05             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END get_profile_info;
--
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_w            CONSTANT VARCHAR2(1) := 'r';
--
    -- *** ローカル変数 ***
    -- ファイル存在チェック戻り値用
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_hht_in_csv_dir                -- CSVファイル取得先
      ,filename    => gv_houmon_csv_file_nm            -- CSVファイル名
      ,fexists     => lb_retcd                         -- 戻り値
      ,file_length => ln_file_size                     -- ファイルサイズ
      ,block_size  => ln_block_size                    -- ファイルブロックのサイズ
    );
--
    -- ファイルが存在しない場合
    IF (lb_retcd = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                    ,iv_token_value1 => gv_hht_in_csv_dir            --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                    ,iv_token_value2 => gv_houmon_csv_file_nm        --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => gv_hht_in_csv_dir
                        ,filename   => gv_houmon_csv_file_nm
                        ,open_mode  => cv_r
                      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03       --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc         --トークンコード1
                      ,iv_token_value1 => gv_hht_in_csv_dir      --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm         --トークンコード1
                      ,iv_token_value2 => gv_houmon_csv_file_nm  --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : file_format_check           
   * Description      : ファイルフォーマットチェック (A-5)
   ***********************************************************************************/
--
  PROCEDURE file_format_check(
     iv_base_value       IN  VARCHAR2                -- 当該行データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード             -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'file_format_check';       -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- Ver1.3 MOD Start
--    cv_format_col_cnt       CONSTANT NUMBER        := 9;                    -- 項目数
    cv_format_col_cnt       CONSTANT NUMBER        := 10;                    -- 項目数
-- Ver1.3 MOD End
    cv_account_number_len   CONSTANT NUMBER        := 9;                    -- 顧客コードバイト数
    cv_employee_number_len  CONSTANT NUMBER        := 5;                    -- 営業員コードバイト数
    cv_houmon_kubun_len     CONSTANT NUMBER        := 2;                    -- 訪問区分バイト数
    cv_description_cut_len  CONSTANT NUMBER        := 2000;                 -- 詳細内容範囲
    cv_visit_date_len       CONSTANT NUMBER        := 8;                    -- 訪問日
    cv_visit_time_len       CONSTANT NUMBER        := 4;                    -- 訪問時刻
    cv_visit_date_fmt       CONSTANT VARCHAR2(100) := 'YYYYMMDDHH24MI';     -- DATE型
    /*20090507_mori_T1_0912 START*/
    cv_blank                CONSTANT VARCHAR2(1)   := ' ';                  -- 空白
    /*20090507_mori_T1_0912 END*/
--Ver1.3 ADD Start
    cv_input_date_fmt       CONSTANT VARCHAR2(100) := 'YYYYMMDDHH24MI';     -- DATE型
--Ver1.3 ADD End
--
    -- *** ローカル変数 ***
    l_col_data_tab          g_col_data_ttype;       -- 分割後項目データを格納する配列
    lv_item_nm              VARCHAR2(100);         -- 該当項目名
    lv_visit_date           VARCHAR2(100);         -- 訪問日時
    lb_return               BOOLEAN;               -- リターンステータス
-- Ver1.3 ADD Start
    lv_input_date           VARCHAR2(100);         -- システム日時（HHT入力日時）
-- Ver1.3 ADD End
--
    loop_cnt                NUMBER;
    lv_tmp                  VARCHAR2(2000);
    ln_pos                  NUMBER;
    ln_cnt                  NUMBER  := 1;
    lb_format_flag          BOOLEAN := TRUE;
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- 抽出データレコード変数初期化
    g_visit_data_rec := NULL;
    -- 項目数を取得
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.項目数チェック
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cv_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_base_val              -- トークンコード1
                       ,iv_token_value1 => iv_base_value                -- トークン値1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.データ型（半角数字／日付）のチェック、サイズチェック
    ELSE
--
      -- 共通関数によって分割した項目データ取得
      <<delim_partition_loop>>
-- Ver1.3 MOD Start
--      FOR loop_cnt IN 1..9 LOOP
      FOR loop_cnt IN 1..10 LOOP
-- Ver1.3 MOD End
        l_col_data_tab(loop_cnt) := TRIM(
                                      REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, loop_cnt)
                                                , '"', '')
                                     );
      END LOOP delim_partition_loop;
--
      lb_return  := TRUE;
      lv_item_nm := '';
--
      -- 1). 必須チェック
      IF l_col_data_tab(1) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '顧客コード';
      ELSIF l_col_data_tab(2) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '営業員コード';
      ELSIF l_col_data_tab(8) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問日';
      ELSIF l_col_data_tab(9) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問時刻';
-- Ver1.3 ADD Start
      ELSIF l_col_data_tab(10) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := 'システム日付(HHT入力日)';
-- Ver1.3 ADD End
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). 日付書式チェック
      -- 訪問日時
      lv_visit_date := TO_CHAR(l_col_data_tab(8)) || l_col_data_tab(9);
--
      lb_return := xxcso_util_common_pkg.check_date(lv_visit_date, cv_visit_date_fmt);
      IF (lb_return = FALSE) THEN
        lv_item_nm := '訪問日時';
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
-- Ver1.3 ADD Start
      -- システム日時（HHT入力日時）
      lv_input_date := TO_CHAR(l_col_data_tab(10)) || l_col_data_tab(9);
--
      lb_return := xxcso_util_common_pkg.check_date(lv_input_date, cv_input_date_fmt);
      IF (lb_return = FALSE) THEN
        lv_item_nm := 'システム日時（HHT入力日時）';
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
-- Ver1.3 ADD End
--
      -- 3). サイズチェック
      /*20090507_mori_T1_0912 START*/
      -- 末尾半角スペース削除
      l_col_data_tab(3)         := TRIM(cv_blank from l_col_data_tab(3));             -- 訪問区分1
      l_col_data_tab(4)         := TRIM(cv_blank from l_col_data_tab(4));             -- 訪問区分2
      l_col_data_tab(5)         := TRIM(cv_blank from l_col_data_tab(5));             -- 訪問区分3
      l_col_data_tab(6)         := TRIM(cv_blank from l_col_data_tab(6));             -- 訪問区分4
      l_col_data_tab(7)         := TRIM(cv_blank from l_col_data_tab(7));             -- 訪問区分5
      /*20090507_mori_T1_0912 END*/
      IF (LENGTHB(l_col_data_tab(1)) <> cv_account_number_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '顧客コード';
      ELSIF (LENGTHB(l_col_data_tab(2)) <> cv_employee_number_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '営業員コード';
      ELSIF (l_col_data_tab(3) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(3)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問区分１';
      ELSIF (l_col_data_tab(4) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(4)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問区分２';
      ELSIF (l_col_data_tab(5) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(5)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問区分３';
      ELSIF (l_col_data_tab(6) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(6)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問区分４';
      ELSIF (l_col_data_tab(7) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(7)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問区分５';
      ELSIF (LENGTHB(l_col_data_tab(9)) <> cv_visit_time_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '訪問時刻';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_17             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
    END IF;
    -- チェック済みの分割データをグローバル変数にセット
    g_visit_data_rec.account_number  := l_col_data_tab(1);             -- 顧客コード
    g_visit_data_rec.employee_number := l_col_data_tab(2);             -- 営業員コード
    g_visit_data_rec.dff1_cd         := l_col_data_tab(3);             -- 訪問区分1
    g_visit_data_rec.dff2_cd         := l_col_data_tab(4);             -- 訪問区分2
    g_visit_data_rec.dff3_cd         := l_col_data_tab(5);             -- 訪問区分3
    g_visit_data_rec.dff4_cd         := l_col_data_tab(6);             -- 訪問区分4
    g_visit_data_rec.dff5_cd         := l_col_data_tab(7);             -- 訪問区分5
    g_visit_data_rec.visit_date      := TO_CHAR(l_col_data_tab(8));    -- 訪問日     
    g_visit_data_rec.visit_time      := l_col_data_tab(9);             -- 訪問時刻
    g_visit_data_rec.visit_datetime  := TO_DATE(g_visit_data_rec.visit_date||g_visit_data_rec.visit_time
                                                , cv_visit_date_fmt);
-- Ver1.3 ADD Start
    g_visit_data_rec.input_date      := TO_CHAR(l_col_data_tab(10));   -- システム日付(HHT入力日)
    g_visit_data_rec.input_datetime  := TO_DATE(g_visit_data_rec.input_date||g_visit_data_rec.visit_time
                                                , cv_input_date_fmt);  -- システム日時(HHT入力日時)
-- Ver1.3 ADD End
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END file_format_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : マスタ存在チェック (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCSO_ASN_HOUMON_KUBUN';
    cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';
    cv_resource_table_nm      CONSTANT VARCHAR2(100) := 'リソースマスタビュー';
    cv_account_table_vl_nm    CONSTANT VARCHAR2(100) := '顧客マスタビュー';
    cv_lookup_table_nm        CONSTANT VARCHAR2(100) := '参照タイプテーブル';
    cv_false                  CONSTANT VARCHAR2(100) := 'FALSE';
    -- *** ローカル変数 ***
    lv_lookup_cd              VARCHAR2(10);            -- 訪問区分コード
    lv_lookup_cd_tab          g_houmon_kubun_cd_ttype; -- 訪問区分コードを保持するPLSQL表
    ld_visite_date            DATE;                    -- 訪問日時
    lv_houmon_kubun           VARCHAR2(10);            -- 訪問区分
    loop_cnt                  NUMBER;

    lv_gl_period_statuses     VARCHAR2(100); -- 「訪問日時」に該当する対象の会計期間がクローズ

--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 顧客コードのマスタ存在チェック *** --
    BEGIN
--
      -- *** 1. パーティID、パーティ名称と顧客ステータスを抽出 *** --
      SELECT xcav.party_id party_id                 -- パーティID
            ,xcav.party_name party_name             -- パーティ名称
            ,xcav.account_name account_name         -- 顧客名称
            ,xcav.customer_status customer_status   -- 顧客ステータス
      INTO   g_visit_data_rec.party_id              -- パーティID
            ,g_visit_data_rec.party_name            -- パーティ名称
            ,g_visit_data_rec.account_name          -- 顧客名称
            ,g_visit_data_rec.customer_status       -- 顧客ステータス
      FROM   xxcso_cust_accounts_v xcav             -- 顧客マスタビュー
      WHERE  xcav.account_number = g_visit_data_rec.account_number
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status   = cv_active_status;
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_account_table_vl_nm           -- トークン値1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- トークンコード2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- トークン値3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- トークン値4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- トークン値5                       
                       ,iv_token_name6  => cv_date_time                     -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値6
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
--
      -- 抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_account_table_vl_nm           -- トークン値1                       
                       ,iv_token_name2  => cv_tkn_err_msg                   -- トークンコード2
                       ,iv_token_value2 => SQLERRM                          -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- トークン値3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- トークン値4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- トークン値5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- トークン値6                       
                       ,iv_token_name7  => cv_date_time                     -- トークンコード7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値7
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 2. 営業員コードのマスタ存在チェック *** --
--
    ld_visite_date := TRUNC(g_visit_data_rec.visit_datetime);
--
    BEGIN
      -- *** リソースマスタビューからリソースIDを抽出 *** --
      SELECT xrv.resource_id resource_id         -- リソースID
            ,xrv.full_name employee_name         -- 営業員名称
      INTO   g_visit_data_rec.resource_id        -- リソースID
            ,g_visit_data_rec.employee_name      -- 営業員名称
      FROM   xxcso_resources_v xrv               -- リソースマスタビュー
      WHERE  xrv.employee_number = g_visit_data_rec.employee_number
        AND ld_visite_date BETWEEN TRUNC(xrv.employee_start_date) 
          AND TRUNC(NVL(xrv.employee_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.resource_start_date)
          AND TRUNC(NVL(xrv.resource_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.assign_start_date)
          AND TRUNC(NVL(xrv.assign_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.start_date)
          AND TRUNC(NVL(xrv.end_date, ld_visite_date));
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_resource_table_nm             -- トークン値1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- トークンコード2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- トークン値3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- トークン値4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- トークン値5                       
                       ,iv_token_name6  => cv_date_time                     -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値6
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_resource_table_nm             -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                   -- トークンコード2
                       ,iv_token_value2 => SQLERRM                          -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- トークン値3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- トークン値4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- トークン値5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- トークン値6                       
                       ,iv_token_name7  => cv_date_time                     -- トークンコード7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 3. 参照タイプテーブルから訪問区分コードの存在チェック *** --
    -- CSV抽出データの訪問区分をPLSQL表にセット
    lv_lookup_cd_tab(1)  := g_visit_data_rec.dff1_cd;  -- 訪問区分コード１
    lv_lookup_cd_tab(2)  := g_visit_data_rec.dff2_cd;  -- 訪問区分コード２
    lv_lookup_cd_tab(3)  := g_visit_data_rec.dff3_cd;  -- 訪問区分コード３
    lv_lookup_cd_tab(4)  := g_visit_data_rec.dff4_cd;  -- 訪問区分コード４
    lv_lookup_cd_tab(5)  := g_visit_data_rec.dff5_cd;  -- 訪問区分コード５    
--
    BEGIN
      -- 訪問区分コードがNULLではない場合、参照コードテーブルに該当訪問区分コードが存在するかをチェック
      <<lookup_code_loop>>
      FOR loop_cnt IN 1..5 LOOP
        IF lv_lookup_cd_tab(loop_cnt) IS NOT NULL THEN
          lv_lookup_cd := lv_lookup_cd_tab(loop_cnt);
          SELECT   flvv.lookup_code       houmon_kubun              -- 訪問区分
          INTO     lv_houmon_kubun                                  -- 訪問区分
          FROM     fnd_lookup_values_vl   flvv                      -- 参照コードテーブル
          WHERE    flvv.lookup_type                 = cv_lookup_type
            AND    ld_visite_date BETWEEN NVL(flvv.start_date_active, ld_visite_date) 
              AND  NVL(flvv.end_date_active, ld_visite_date)
            AND    flvv.enabled_flag                = cv_flag_y
            AND    flvv.attribute2                  = cv_flag_y
            AND    flvv.lookup_code                 = lv_lookup_cd;
        END IF;
      END LOOP lookup_code_loop;
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_lookup_table_nm               -- トークン値1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- トークンコード2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- トークン値3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- トークン値4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- トークン値5                       
                       ,iv_token_name6  => cv_date_time                     -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値6
                       ,iv_token_name7  => cv_lookup_cd                     -- トークンコード7
                       ,iv_token_value7 => lv_lookup_cd                     -- トークン値7 
                     );
          lv_errbuf := lv_errmsg||SQLERRM;
          RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                       ,iv_token_value1 => cv_lookup_table_nm               -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                   -- トークンコード2
                       ,iv_token_value2 => SQLERRM                          -- トークン値2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- トークン値3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- トークン値4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- トークンコード5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- トークン値5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- トークンコード6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- トークン値6                       
                       ,iv_token_name7  => cv_date_time                     -- トークンコード7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値7
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 4. 「訪問日時」に該当する対象の会計期間がクローズされているかをチェック *** --
    -- 会計期間チェック関数を使用
    lv_gl_period_statuses := xxcso_util_common_pkg.check_ar_gl_period_status(g_visit_data_rec.visit_datetime);
    -- チェック関数のリターン値が'FALSE'(クローズされている)の場合
    IF lv_gl_period_statuses = cv_false THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09                 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_cstm_cd                   -- トークンコード1
                     ,iv_token_value1 => g_visit_data_rec.account_number  -- トークン値1
                     ,iv_token_name2  => cv_tkn_cstm_nm                   -- トークンコード2
                     ,iv_token_value2 => g_visit_data_rec.account_name    -- トークン値2
                     ,iv_token_name3  => cv_tkn_sales_cd                  -- トークンコード3
                     ,iv_token_value3 => g_visit_data_rec.employee_number -- トークン値3                       
                     ,iv_token_name4  => cv_tkn_sales_nm                  -- トークンコード4
                     ,iv_token_value4 => g_visit_data_rec.employee_name   -- トークン値4
                     ,iv_token_name5  => cv_date_time                     -- トークンコード5
                     ,iv_token_value5 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time   -- トークン値5   
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : 訪問のみ情報登録処理 (A-7)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_task_table_nm   CONSTANT VARCHAR2(100) := 'タスクテーブル';
    -- *** ローカル変数 ***
    ln_task_id         NUMBER;            -- タスクID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 訪問のみ情報登録 
    -- =======================
    xxcso_task_common_pkg.create_task(
        in_resource_id            => g_visit_data_rec.resource_id         -- 営業員コードのリソースID
       ,in_party_id               => g_visit_data_rec.party_id            -- 顧客のパーティID
       ,iv_party_name             => g_visit_data_rec.party_name          -- 顧客のパーティ名称
-- Ver1.3 ADD Start
       ,id_input_date             => g_visit_data_rec.input_datetime      -- データ入力日時
-- Ver1.3 ADD End
       ,id_visit_date             => g_visit_data_rec.visit_datetime      -- 実績終了日（訪問日時）
       ,iv_description            => g_visit_data_rec.description         -- 詳細内容
       ,iv_attribute1             => g_visit_data_rec.dff1_cd             -- DFF1 訪問区分１
       ,iv_attribute2             => g_visit_data_rec.dff2_cd             -- DFF2 訪問区分２
       ,iv_attribute3             => g_visit_data_rec.dff3_cd             -- DFF3 訪問区分３
       ,iv_attribute4             => g_visit_data_rec.dff4_cd             -- DFF4 訪問区分４
       ,iv_attribute5             => g_visit_data_rec.dff5_cd             -- DFF5 訪問区分５
       ,iv_attribute11            => cv_enable_houmon_kubun               -- DFF11 有効訪問区分 訪問：0
       ,iv_attribute12            => cv_insert_kubun                      -- DFF12 登録区分 訪問のみ（HHT）：1
       ,iv_attribute13            => NULL                                 -- DFF13　登録区分番号
       ,iv_attribute14            => g_visit_data_rec.customer_status     -- DFF14　顧客ステータス
       ,on_task_id                => ln_task_id                           -- タスクID
       ,ov_errbuf                 => lv_errbuf                            -- エラー・メッセージ
       ,ov_retcode                => lv_retcode                           -- 正常:0、警告:1、異常:2
       ,ov_errmsg                 => lv_errmsg                            -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11                 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl                       -- トークンコード1
                     ,iv_token_value1 => cv_task_table_nm                 -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg                   -- トークンコード2
                     ,iv_token_value2 => SQLERRM                          -- トークン値2
                     ,iv_token_name3  => cv_tkn_cstm_cd                   -- トークンコード3
                     ,iv_token_value3 => g_visit_data_rec.account_number  -- トークン値3
                     ,iv_token_name4  => cv_tkn_cstm_nm                   -- トークンコード4
                     ,iv_token_value4 => g_visit_data_rec.account_name    -- トークン値4                       
                     ,iv_token_name5  => cv_tkn_sales_cd                  -- トークンコード5
                     ,iv_token_value5 => g_visit_data_rec.employee_number -- トークン値5
                     ,iv_token_name6  => cv_tkn_sales_nm                  -- トークンコード6
                     ,iv_token_value6 => g_visit_data_rec.employee_name   -- トークン値6                       
                     ,iv_token_name7  => cv_date_time                     -- トークンコード7
                     ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- トークン値7
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-9)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
--
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_15             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => gv_hht_in_csv_dir            --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                      ,iv_token_value2 => gv_houmon_csv_file_nm        --トークン値2
                      ,iv_token_name3  => cv_tkn_err_msg               --トークンコード3
                      ,iv_token_value3 => SQLERRM                      --トークン値3                      
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
--
  PROCEDURE submain(
     iv_file_name        IN VARCHAR2           -- 訪問のみCSVファイル名
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_base_value           VARCHAR2(5000);         -- 当該行データ
    ln_task_id              NUMBER;                 -- タスクＩＤ
    ln_task_count           NUMBER;                 -- 抽出件数
    lb_fopn_retcd           BOOLEAN;                -- CSVファイルオープン戻り値
--
    -- *** ローカル例外 ***
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
       iv_file_name => gv_houmon_csv_file_nm  -- 訪問のみCSVファイル名
      ,ov_errbuf    => lv_errbuf              -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode             -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg              -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.プロファイル値取得 
    -- ========================================
    get_profile_info(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSVファイルオープン 
    -- =================================================
    open_csv_file(
       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ファイルデータループ
    <<get_visit_data_loop>>
    LOOP
      BEGIN
        -- A-4.CSVデータ抽出      
        BEGIN
          UTL_FILE.GET_LINE(gf_file_hand, lv_base_value, 32767);    
        EXCEPTION
          -- CSVファイルにデータがない場合、ループを抜ける
          WHEN NO_DATA_FOUND THEN
            EXIT;
          -- 想定外エラーの場合、警告スキップ
          WHEN OTHERS  THEN                      -- それ以外のエラー
            -- エラーメッセージ取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name            --アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_04       --メッセージコード
                           ,iv_token_name1  => cv_tkn_csv_loc         --トークンコード1
                           ,iv_token_value1 => gv_hht_in_csv_dir      --トークン値1
                           ,iv_token_name2  => cv_tkn_csv_fnm         --トークンコード2
                           ,iv_token_value2 => gv_houmon_csv_file_nm  --トークン値2
                           ,iv_token_name3  => cv_tkn_err_msg         --トークンコード3
                           ,iv_token_value3 => SQLERRM                --トークン値3  
                         );
            lv_errbuf := lv_errmsg || SQLERRM;
            RAISE global_skip_error_expt;
--
        END;
--
        -- 対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;
--
        -- =================================================
        -- A-5.ファイルフォマットチェック
        -- =================================================
        file_format_check(
           iv_base_value    => lv_base_value    -- 当該行データ
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-6.マスタ存在チェック 
        -- =============================
        chk_mst_is_exists(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-7.訪問のみ情報登録処理 
        -- =============================
        insert_visit_data(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- A-8.SAVEPOINT発行
        SAVEPOINT visit;
--
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** スキップ例外ハンドラ ***
        WHEN global_skip_error_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gn_normal_cnt > 0 THEN
            ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK TO SAVEPOINT
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          ELSE
            ROLLBACK;          -- ROLLBACK
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg7|| CHR(10)
            );
          END IF;
          -- 全体の処理ステータスに警告セット
          ov_retcode := cv_status_warn;
--
        -- *** スキップ例外OTHERSハンドラ ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gn_normal_cnt > 0 THEN
            ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK TO SAVEPOINT
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          ELSE
            ROLLBACK;          -- ROLLBACK
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg7|| CHR(10)
            );
          END IF;
          -- 全体の処理ステータスに警告セット
          ov_retcode := cv_status_warn;
--
      END;
    END LOOP get_visit_data_loop;
--
    -- ========================================
    -- CSVファイルクローズ (A-9) 
    -- ========================================
    close_csv_file(
       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- エラー・メッセージ  -- # 固定 #
    ,retcode       OUT NOCOPY VARCHAR2          -- リターン・コード    -- # 固定 #
    ,iv_file_name  IN         VARCHAR2          -- ファイル名
  )    
--
-- ###########################  固定部 START   ###########################
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
-- ###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  固定部 END   #############################
--
    -- *** 入力パラメータをセット
    gv_houmon_csv_file_nm := iv_file_name;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_file_name => gv_houmon_csv_file_nm  -- 訪問のみCSVファイル名
      ,ov_errbuf    => lv_errbuf              -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode             -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg              -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf                  -- エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-10.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- 空行
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCSO014A03C;
/
