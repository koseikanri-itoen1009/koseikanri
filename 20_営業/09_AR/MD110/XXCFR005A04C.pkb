CREATE OR REPLACE PACKAGE BODY XXCFR005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A04C(body)
 * Description      : ロックボックス入金処理
 * MD.050           : MD050_CFR_005_A04_ロックボックス入金処理
 * MD.070           : MD050_CFR_005_A04_ロックボックス入金処理
 * Version          : 1.02
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_fb_data            FBファイル取込処理 (A-2)
 *  get_bank_info          入金24時間化銀行情報取得処理 (A-11)
 *  get_receive_method     支払方法取得処理 (A-3)
 *  get_receipt_customer   入金先顧客取得処理 (A-4)
 *  get_fb_out_acct_number 自動消込対象外顧客取得処理 (A-5)
 *  get_trx_amount         対象債権総額処理 (A-6)
 *  exec_cash_api          入金API起動処理 (A-7)
 *  insert_table           ロックボックス入金消込ワークテーブル登録処理 (A-8)
 *  update_table           パラレル実行区分付与処理 (A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/15    1.00 SCS 廣瀬 真佐人  初回作成
 *  2013/07/22    1.01 SCSK 中村 健一   E_本稼動_10950 消費税増税対応
 *  2015/05/29    1.02 SCSK 小路 恭弘   E_本稼動_13114 振込24時間化対応
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  global_lock_err_expt      EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A04C'; -- パッケージ名
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- 記号
  cv_msg_brack_point CONSTANT VARCHAR2(5)   := '・';
  cv_msg_under_score CONSTANT VARCHAR2(5)   := '_';
  cv_msg_dott        CONSTANT VARCHAR2(5)   := '.';
--
  -- メッセージ番号
  cv_msg_005a04_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ロックエラー
  cv_msg_005a04_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_005a04_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- 業務処理日付取得エラーメッセージ
  cv_msg_005a04_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- データ挿入エラーメッセージ
  cv_msg_005a04_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; -- データ更新エラーメッセージ
  cv_msg_005a04_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- 対象データなしメッセージ
  cv_msg_005a04_029  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; -- 取込ファイル名出力メッセージ
  cv_msg_005a04_039  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; -- 取込ファイル存在なしエラー
  cv_msg_005a04_113  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00113'; -- FBファイル名定義なしエラーメッセージ
  cv_msg_005a04_114  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00114'; -- 手数料限度額定義なしエラーメッセージ
  cv_msg_005a04_115  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00115'; -- 対象支払方法なしエラーメッセージ
  cv_msg_005a04_116  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00116'; -- 対象顧客なしメッセージ
  cv_msg_005a04_117  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00117'; -- 入金APIエラーメッセージ
  cv_msg_005a04_118  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00118'; -- 不明入金件数メッセージ
  cv_msg_005a04_119  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00119'; -- 日付変換エラーメッセージ
  cv_msg_005a04_120  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00120'; -- 数値変換エラーメッセージ
  cv_msg_005a04_121  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00121'; -- 入力パラメータ「ワークテーブル作成フラグ」未設定エラーメッセージ
  cv_msg_005a04_122  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00122'; -- ファイル名出力対象なしメッセージ
  cv_msg_005a04_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00025'; -- 警告件数メッセージ
  cv_msg_005a04_126  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00126'; -- 対象支払方法重複エラーメッセージ
  cv_msg_005a04_127  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00127'; -- 対象支払方法出力メッセージ
  cv_msg_005a04_128  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00128'; -- 自動消込対象件数メッセージ
-- 2015/05/29 Ver1.02 Add Start
  cv_msg_005a04_151  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00151'; -- 入金番号管理テーブル削除エラーメッセージ
-- 2015/05/29 Ver1.02 Add End
--
-- トークン
  cv_tkn_param_name            CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_param_val             CONSTANT VARCHAR2(20) := 'PARAM_VAL';
  cv_tkn_prof_name             CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_lookup_type           CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';
  cv_tkn_table                 CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_file_name             CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_file_path             CONSTANT VARCHAR2(20) := 'FILE_PATH';
  cv_tkn_receipt_number        CONSTANT VARCHAR2(20) := 'RECEIPT_NUMBER';
  cv_tkn_account_number        CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';
  cv_tkn_receipt_method        CONSTANT VARCHAR2(20) := 'RECEIPT_METHOD';
  cv_tkn_receipt_date          CONSTANT VARCHAR2(20) := 'RECEIPT_DATE';
  cv_tkn_amount                CONSTANT VARCHAR2(20) := 'AMOUNT';
  cv_tkn_trx_number            CONSTANT VARCHAR2(20) := 'TRX_NUMBER';
  cv_tkn_count                 CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_ref_number            CONSTANT VARCHAR2(20) := 'REF_NUMBER';
  cv_tkn_bank_number           CONSTANT VARCHAR2(20) := 'BANK_NUMBER';
  cv_tkn_bank_num              CONSTANT VARCHAR2(20) := 'BANK_NUM';
  cv_tkn_bank_account_type     CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_TYPE';
  cv_tkn_bank_account_num      CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_NUM';
  cv_tkn_alt_name              CONSTANT VARCHAR2(20) := 'ALT_NAME';
  cv_tkn_receipt_method_owner  CONSTANT VARCHAR2(20) := 'RECEIPT_METHOD_OWNER';
  cv_tkn_bank_account_owner    CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_OWNER';
-- 2015/05/29 Ver1.02 Add Start
  cv_tkn_retention_date        CONSTANT VARCHAR2(20) := 'RETENTION_DATE';
-- 2015/05/29 Ver1.02 Add End
--
  --プロファイル
  cv_prf_fb_path        CONSTANT VARCHAR2(30) := 'XXCFR1_FB_FILEPATH';    -- FBファイル格納パス
  cv_prf_par_cnt        CONSTANT VARCHAR2(30) := 'XXCFR1_PARALLEL_COUNT'; -- パラレル実行数
  cv_set_of_bks_id      CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';      -- 会計帳簿ID
  cv_org_id             CONSTANT VARCHAR2(30) := 'ORG_ID';                -- 営業単位ID
-- 2015/05/29 Ver1.02 Add Start
  cv_retention_period   CONSTANT VARCHAR2(30) := 'XXCFR1_RETENTION_PERIOD'; -- 入金番号管理テーブル保持期間
-- 2015/05/29 Ver1.02 Add End
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';           -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';              -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';   -- 日付フォーマット（年月日）
  cv_format_ymd         CONSTANT VARCHAR2(10) := 'YYYYMMDD';     -- 日付フォーマット（年月日）
  cv_format_rmd         CONSTANT VARCHAR2(6)  := 'RRMMDD';       -- 日付フォーマット（和暦）
  cv_format_nls_cal     CONSTANT VARCHAR2(40) := 'NLS_CALENDAR=''JAPANESE IMPERIAL''';  -- 
-- 2015/05/29 Ver1.02 Add Start
  cv_format_dd          CONSTANT VARCHAR2(2)  := 'DD';           -- 日付フォーマット（年月）
-- 2015/05/29 Ver1.02 Add End
--
  -- テーブル名
  cv_tkn_rock_wk        CONSTANT VARCHAR2(50) := 'XXCFR_ROCKBOX_WK';  -- ロックボックス入金消込ワークテーブル
-- 2015/05/29 Ver1.02 Add Start
  cv_tkn_xcrnc          CONSTANT VARCHAR2(50) := 'XXCFR_CASH_RECEIPTS_NO_CONTROL';  -- 入金番号管理テーブル
-- 2015/05/29 Ver1.02 Add END
--
  -- リテラル値
  cb_true               CONSTANT BOOLEAN := TRUE;
  cb_false              CONSTANT BOOLEAN := FALSE;
--
  cv_flag_y             CONSTANT VARCHAR2(10) := 'Y';  -- フラグ値：Y
-- 2015/05/29 Ver1.02 Add Start
  cv_flag_n             CONSTANT VARCHAR2(10) := 'N';  -- フラグ値：N
-- 2015/05/29 Ver1.02 Add End
  cv_need               CONSTANT VARCHAR2(1)  := '1';  -- 要
  cv_no_need            CONSTANT VARCHAR2(1)  := '0';  -- 否
--
  -- 参照タイプ系
  ct_lc_fb_file_name    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_FILE_NAME';        -- 参照タイプ「FBファイル名」
  ct_out_acct_number    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_OUT_ACCT_NUMBER';  -- 参照タイプ「自動消込対象外顧客」
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE rockbox_table_ttype     IS TABLE OF xxcfr_rockbox_wk%ROWTYPE
                                  INDEX BY PLS_INTEGER;  -- FBデータ
  TYPE fnd_lookup_values_ttype IS TABLE OF fnd_lookup_values_vl.description%TYPE
                                  INDEX BY PLS_INTEGER;  -- FBファイル名
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル値
  gt_prf_fb_path        all_directories.directory_name%TYPE;        -- FBファイルパス
  gn_prf_par_cnt        NUMBER;                                     -- パラレル実行数
  gt_set_of_bks_id      gl_sets_of_books.set_of_books_id%TYPE;      -- 会計帳簿ID
  gn_org_id             NUMBER;                                     -- 営業単位
-- 2015/05/29 Ver1.02 Add Start
  gn_retention_period   NUMBER;                                     -- 入金番号管理テーブル保持期間
-- 2015/05/29 Ver1.02 Add End
  -- その他
  gd_process_date       DATE;                                       -- 業務処理日付
  gt_tolerance_limit    ap_bank_charge_lines.tolerance_limit%TYPE;  -- 手数料限度額
  gn_no_customer_cnt    NUMBER;                                     -- 不明入金件数
  gn_auto_apply_cnt     NUMBER;                                     -- 自動消込対象件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_fb_file_name      IN         VARCHAR2,                 -- パラメータ．FBファイル名
    iv_table_insert_flag IN         VARCHAR2,                 -- パラメータ．ワークテーブル作成フラグ
    o_fb_file_name_tab   OUT NOCOPY fnd_lookup_values_ttype,  -- FBファイル名
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
    cv_ar  CONSTANT VARCHAR2(2) := 'AR';
--
    -- *** ローカル変数 ***
    ln_count           PLS_INTEGER;              -- ループカウンタ
    l_fb_file_name_tab fnd_lookup_values_ttype;  -- FBファイル名
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- 配列
    l_fb_file_name_tab.DELETE;
    o_fb_file_name_tab.DELETE;
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ログ出力
      ,iv_conc_param1  => iv_fb_file_name       -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_table_insert_flag  -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- ログ出力
      ,iv_conc_param1  => iv_fb_file_name       -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_table_insert_flag  -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 入力パラメータ必須チェック
    --==============================================================
    -- パラメータ．ワークテーブル作成フラグの必須チェック
    IF (iv_table_insert_flag IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_121
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 業務処理日付取得処理
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 取得エラー時
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_006
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイル値の取得
    --==============================================================
    -- FBファイルパス
    gt_prf_fb_path      := FND_PROFILE.VALUE( cv_prf_fb_path );
    IF ( gt_prf_fb_path IS NULL ) THEN    -- 取得エラー時
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_prf_fb_path )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- パラレル実行数
    gn_prf_par_cnt      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_par_cnt ) );
    IF ( gn_prf_par_cnt IS NULL ) THEN    -- 取得エラー時
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_prf_par_cnt )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 会計帳簿ID
    gt_set_of_bks_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id ) );
    IF ( gt_set_of_bks_id IS NULL ) THEN    -- 取得エラー時
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 営業単位
    gn_org_id           := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ) );
    IF ( gn_org_id IS NULL ) THEN    -- 取得エラー時
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_org_id )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2015/05/29 Ver1.02 Add Start
    -- 入金番号管理テーブル保持期間
    gn_retention_period    := TO_NUMBER( FND_PROFILE.VALUE( cv_retention_period ) );
    IF ( gn_retention_period IS NULL ) THEN    -- 取得エラー時
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_retention_period )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2015/05/29 Ver1.02 Add End
--
    --==============================================================
    -- 参照タイプの取得
    --==============================================================
    -- FBファイル名
    -- パラメータ．FBファイル名がNULLであれば参照タイプから取得
    IF ( iv_fb_file_name IS NULL ) THEN
--
      BEGIN
--
        SELECT flvv.meaning AS meaning
        BULK COLLECT INTO l_fb_file_name_tab
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = ct_lc_fb_file_name  -- 参照タイプ
        AND    flvv.enabled_flag = cv_flag_y           -- 有効フラグ
        AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )  -- 有効日(自)
                                   AND NVL( flvv.end_date_active  , gd_process_date )  -- 有効日(至)
        AND    flvv.meaning IS NOT NULL  -- FBファイル名がNULL以外
        ;
--
        -- クイックコードが登録されていないとき
        IF (l_fb_file_name_tab.COUNT < 1) THEN
          RAISE NO_DATA_FOUND;
        END IF;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_113
                        ,iv_token_name1  => cv_tkn_lookup_type
                        ,iv_token_value1 => ct_lc_fb_file_name
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
    -- パラメータ．FBファイル名がNULLでなければパラメータ.FBファイル名を設定
    ELSE
      l_fb_file_name_tab(0) := iv_fb_file_name;
    END IF;
--
    -- 取得した、取込対象のFBファイル名をメッセージ出力する。
    <<loop_message>>
    FOR ln_count IN l_fb_file_name_tab.FIRST..l_fb_file_name_tab.LAST LOOP
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_029
                      ,iv_token_name1  => cv_tkn_file_name
                      ,iv_token_value1 => l_fb_file_name_tab( ln_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END LOOP loop_message;
    -- 改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- OUTパラメータに設定
    o_fb_file_name_tab := l_fb_file_name_tab;
--
    --==============================================================
    -- 手数料限度額の取得
    --==============================================================
    BEGIN
      SELECT abcl.tolerance_limit AS tolerance_limit
      INTO   gt_tolerance_limit
      FROM   ap_bank_charges      abc   -- 銀行手数料
            ,ap_bank_charge_lines abcl  -- 銀行手数料明細
      WHERE  abc.bank_charge_id    = abcl.bank_charge_id  -- 内部ID
      AND    abc.transfer_priority = cv_ar                -- 優先度
-- Mod 2013/07/22 Ver1.01 Start
--      AND    gd_process_date BETWEEN NVL( abcl.start_date, gd_process_date )  -- 開始日
--                                 AND NVL( abcl.end_date  , gd_process_date )  -- 終了日
      AND    abcl.start_date                          <= gd_process_date  -- 開始日
      AND    NVL( abcl.end_date, gd_process_date + 1 ) > gd_process_date  -- 終了日
-- Mod 2013/07/22 Ver1.01 End
      AND    abcl.tolerance_limit IS NOT NULL  -- 手数料限度額がNULL以外
      ;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_114
-- 2015/05/29 Ver1.02 Add Start
                      ,iv_token_name1  => cv_tkn_receipt_date
                      ,iv_token_value1 => TO_CHAR(gd_process_date, cv_format_date_ymd)
-- 2015/05/29 Ver1.02 Add End
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
-- 2015/05/29 Ver1.02 Add Start
    --==============================================================
    -- 管理テーブル保持期間を過ぎたレコードの削除
    --==============================================================
    BEGIN
      DELETE FROM XXCFR_CASH_RECEIPTS_NO_CONTROL xcrnc   -- 入金番号管理テーブル
      WHERE  xcrnc.receipt_date <= gd_process_date - gn_retention_period  -- 業務日付-入金番号管理テーブル保持期間
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr                                                      -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_005a04_151                                                   -- メッセージ
                                             ,iv_token_name1  => cv_tkn_retention_date                                               -- トークンコード
                                             ,iv_token_value1 => TO_CHAR(gd_process_date - gn_retention_period, cv_format_date_ymd)  -- トークン：業務日付-入金番号管理テーブル保持期間
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2015/05/29 Ver1.02 Add End
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_fb_data
   * Description      : FBファイル取込処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_fb_data(
    i_fb_file_name_tab   IN         fnd_lookup_values_ttype,  -- FBファイル名
    o_rockbox_table_tab  OUT NOCOPY rockbox_table_ttype,      -- FBデータ
    ob_warn_end          OUT NOCOPY BOOLEAN,                  -- 終了ステータス制御
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_data'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    cv_open_mode_r     CONSTANT VARCHAR2(1) := 'r';   -- ファイルオープンモード（読み込み）
    cv_div_header      CONSTANT VARCHAR2(1) := '1';   -- FBデータヘッダ部
    cv_div_data        CONSTANT VARCHAR2(1) := '2';   -- FBデータデータ部
    cv_kind_receipt    CONSTANT VARCHAR2(2) := '03';  -- 種別コード
    cv_payment_receipt CONSTANT VARCHAR2(1) := '1';   -- 入払区分
    cv_trance_receipt  CONSTANT VARCHAR2(2) := '11';  -- 取引区分
--
    -- *** ローカル変数 ***
--
    lf_file_hand        UTL_FILE.FILE_TYPE;  -- ファイル・ハンドルの宣言（読込時用）
    lv_csv_text         VARCHAR2(32000);     -- ファイル内データ受取用変数
    -- カウンタ
    ln_count            PLS_INTEGER;  -- ループカウンタ
    ln_read_count       PLS_INTEGER;  -- 読み取りレコード数のカウンタ
    ln_line_cnt         PLS_INTEGER;  -- データ部カウンタ
    -- ヘッダ部変数
    lt_h_kind_code      xxcfr_rockbox_wk.kind_code%TYPE;         -- 種別コード
    lt_h_bank_number    xxcfr_rockbox_wk.bank_number%TYPE;       -- 銀行コード
    lt_h_bank_num       xxcfr_rockbox_wk.bank_num%TYPE;          -- 支店コード
    lt_h_account_type   xxcfr_rockbox_wk.account_type%TYPE;      -- 口座種別
    lt_h_account_num    xxcfr_rockbox_wk.account_num%TYPE;       -- 口座番号
    -- データ部変数
    lt_l_payment_code   xxcfr_rockbox_wk.payment_code%TYPE;      -- 入払区分
    lt_l_trans_code     xxcfr_rockbox_wk.trans_code%TYPE;        -- 取引区分
    lt_l_ref_number     xxcfr_rockbox_wk.ref_number%TYPE;        -- 参照番号
    lt_l_alt_name       xxcfr_rockbox_wk.alt_name%TYPE;          -- 振込依頼人名
    lt_l_comments       xxcfr_rockbox_wk.comments%TYPE;          -- 注釈
    lt_l_file_name      xxcfr_rockbox_wk.in_file_name%TYPE;      -- ファイル名
    lt_l_receipt_date   ar_cash_receipts_all.receipt_date%TYPE;  -- 入金日
    lt_l_amount         ar_cash_receipts_all.amount%TYPE;        -- 入金額
    lv_l_receipt_date   VARCHAR2(20);                            -- 入金日(一時格納)
    lv_l_amount         VARCHAR2(20);                            -- 入金額(一時格納)
--
    lb_open_error      BOOLEAN;  -- ファイルOPENエラー
    lb_validate_error  BOOLEAN;  -- 妥当性エラー
--
    l_wk_tab           rockbox_table_ttype;  -- ヘッダ部、データ部格納用
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- 
    ob_warn_end := cb_false;  -- 終了ステータス制御
    ln_line_cnt := 0;         -- FBファイルの内、取込対象のレコード数
--
    -- 読み取り対象のFBファイル分ループ
    <<loop_get_fb_data>>
    FOR ln_count IN i_fb_file_name_tab.FIRST..i_fb_file_name_tab.LAST LOOP
--
      BEGIN
--
        -- 初期化
        lb_open_error := cb_false;
        -- ファイルを開く
        lf_file_hand := UTL_FILE.FOPEN(
                          location  => gt_prf_fb_path
                         ,filename  => i_fb_file_name_tab(ln_count)
                         ,open_mode => cv_open_mode_r
                        );
--
      EXCEPTION
--
        WHEN UTL_FILE.INVALID_OPERATION THEN  -- ファイルが開けない(権限、存在しない)
--
          -- ファイルが開いていたら閉じる
          IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
            UTL_FILE.FCLOSE( lf_file_hand ) ;
          END IF;
--
          -- ファイルがない旨を出力
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfr
                          ,iv_name         => cv_msg_005a04_039
                          ,iv_token_name1  => cv_tkn_file_name
                          ,iv_token_value1 => i_fb_file_name_tab(ln_count)
                          ,iv_token_name2  => cv_tkn_file_path
                          ,iv_token_value2 => gt_prf_fb_path
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
--
          -- ファイルOPEN時にエラー発生
          lb_open_error := cb_true;
          ob_warn_end   := cb_true;  -- コンカレントを警告終了にする
--
        WHEN OTHERS THEN
--
          -- ファイルが開いていたら閉じる
          IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
            UTL_FILE.FCLOSE( lf_file_hand ) ;
          END IF;
--
          RAISE global_api_expt;
      END;
--
      -- ファイルが開けたとき
      IF NOT( lb_open_error ) THEN
--
        -- 読み込んだレコード数を初期化
        ln_read_count := 0;
--
        -- ファイル内のデータを1レコードずつ読み取る
        <<loop_get_data>>
        LOOP
--
          BEGIN
--
            -- ファイル内のデータを読み取ります。ファイル内にデータがなければ、例外終了(NO_DATA_FOUND)
            UTL_FILE.GET_LINE(
              file   => lf_file_hand
             ,buffer => lv_csv_text
            );
--
            -- 読み込んだレコード数をカウントアップ
            ln_read_count := ln_read_count + 1;
--
            -- ヘッダ部
            IF   ( SUBSTRB( lv_csv_text, 1, 1 ) = cv_div_header ) THEN
              lt_h_kind_code    := SUBSTRB( lv_csv_text, 2 , 2  );  -- 種別コード
              lt_h_bank_number  := SUBSTRB( lv_csv_text, 23, 4  );  -- 銀行コード
              lt_h_bank_num     := SUBSTRB( lv_csv_text, 42, 3  );  -- 支店コード
              lt_h_account_type := SUBSTRB( lv_csv_text, 63, 1  );  -- 口座種別
              lt_h_account_num  := SUBSTRB( lv_csv_text, 64, 10 );  -- 口座番号
            -- データ部
            ELSIF( SUBSTRB( lv_csv_text, 1, 1 ) = cv_div_data ) THEN
--
              -- 妥当性エラーチェックを初期化
              lb_validate_error := cb_false;
--
              -- FBファイルのデータを取得する
              lt_l_ref_number   := SUBSTRB( lv_csv_text, 2 , 8  );            -- 照会番号
              lv_l_receipt_date := SUBSTRB( lv_csv_text, 10, 6  );            -- 入金日
              lt_l_payment_code := SUBSTRB( lv_csv_text, 22, 1  );            -- 入払区分
              lt_l_trans_code   := SUBSTRB( lv_csv_text, 23, 2  );            -- 取引区分
              lv_l_amount       := SUBSTRB( lv_csv_text, 25, 12 );            -- 入金額
              lt_l_alt_name     := RTRIM( SUBSTRB( lv_csv_text, 82 , 48 ) );  -- 振込依頼人
              lt_l_comments     := RTRIM( SUBSTRB( lv_csv_text, 160, 20 ) );  -- 注釈
              lt_l_file_name    := SUBSTRB( i_fb_file_name_tab( ln_count )
                                          , 1
                                          , INSTRB( i_fb_file_name_tab( ln_count )
                                                  , cv_msg_dott
                                           ) - 1
                                   );                                  -- ファイル名
--
              -- 入金明細であるときは、配列に格納する。
              IF ( ( lt_h_kind_code    = cv_kind_receipt    )  -- 種別コード
               AND ( lt_l_payment_code = cv_payment_receipt )  -- 入払区分
               AND ( lt_l_trans_code   = cv_trance_receipt  )  -- 取引区分
              ) THEN
--
                -- 対象件数をカウントアップ
                gn_target_cnt := gn_target_cnt + 1;
--
                -- データの妥当性チェック
                -- １．入金日
                -- 勘定日(入金日)がNULLの時はエラーメッセージを出力する
                IF( lv_l_receipt_date IS NULL) THEN
                  -- NULL値エラー
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_005a04_119
                                  ,iv_token_name1  => cv_tkn_receipt_date
                                  ,iv_token_value1 => lv_l_receipt_date
                                  ,iv_token_name2  => cv_tkn_ref_number
                                  ,iv_token_value2 => lt_l_ref_number
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.OUTPUT
                    ,buff   => gv_out_msg
                  );
--
                  lb_validate_error := cb_true;            -- 妥当性エラー時は、配列に格納しない。
--
                -- 勘定日(入金日)がNULL以外の時は日付に変換する
                ELSE
--
                  BEGIN
--
                    lt_l_receipt_date := TO_DATE( lv_l_receipt_date
                                                , cv_format_rmd
                                                , cv_format_nls_cal
                                         );
                  EXCEPTION
                    WHEN OTHERS THEN
                      -- 日付変換エラー
                      gv_out_msg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_msg_kbn_cfr
                                      ,iv_name         => cv_msg_005a04_119
                                      ,iv_token_name1  => cv_tkn_receipt_date
                                      ,iv_token_value1 => lv_l_receipt_date
                                      ,iv_token_name2  => cv_tkn_ref_number
                                      ,iv_token_value2 => lt_l_ref_number
                                     );
                      FND_FILE.PUT_LINE(
                         which  => FND_FILE.OUTPUT
                        ,buff   => gv_out_msg
                      );
--
                      lb_validate_error := cb_true;            -- 妥当性エラー時は、配列に格納しない。
--
                  END;
--
                END IF;
--
                -- ２．入金額
                -- 入力金額(入金額)がNULLの時はエラーメッセージを出力する
                IF ( lv_l_amount IS NULL ) THEN
                  -- NULL値エラー
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_005a04_120
                                  ,iv_token_name1  => cv_tkn_amount
                                  ,iv_token_value1 => lv_l_amount
                                  ,iv_token_name2  => cv_tkn_ref_number
                                  ,iv_token_value2 => lt_l_ref_number
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.OUTPUT
                    ,buff   => gv_out_msg
                  );
--
                  lb_validate_error := cb_true;            -- 妥当性エラー時は、配列に格納しない。
--
                -- 入力金額(入金額)がNULL以外の時は数値に変換する
                ELSE
--
                  BEGIN
--
                    lt_l_amount       := TO_NUMBER( lv_l_amount );
--
                  EXCEPTION
                    WHEN OTHERS THEN
                      -- 数値変換エラー
                      gv_out_msg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_msg_kbn_cfr
                                      ,iv_name         => cv_msg_005a04_120
                                      ,iv_token_name1  => cv_tkn_amount
                                      ,iv_token_value1 => lv_l_amount
                                      ,iv_token_name2  => cv_tkn_ref_number
                                      ,iv_token_value2 => lt_l_ref_number
                                     );
                      FND_FILE.PUT_LINE(
                         which  => FND_FILE.OUTPUT
                        ,buff   => gv_out_msg
                      );
--
                      lb_validate_error := cb_true;            -- 妥当性エラー時は、配列に格納しない。
--
                  END;
--
                END IF;
--
                -- 妥当性チェックでエラーが発生しているときは、警告件数をカウントアップする。
                IF ( lb_validate_error ) THEN
                  gn_warn_cnt := gn_warn_cnt   + 1;  -- 警告件数をカウントアップ
                -- 妥当性チェックでエラーが発生していないときは、配列に格納する。
                ELSE
--
                  ln_line_cnt := ln_line_cnt + 1;
--
                  l_wk_tab(ln_line_cnt).kind_code    := lt_h_kind_code;     -- 種別コード
                  l_wk_tab(ln_line_cnt).bank_number  := lt_h_bank_number;   -- 銀行コード
                  l_wk_tab(ln_line_cnt).bank_num     := lt_h_bank_num;      -- 支店コード
                  l_wk_tab(ln_line_cnt).account_type := lt_h_account_type;  -- 口座種別
                  l_wk_tab(ln_line_cnt).account_num  := lt_h_account_num;   -- 口座番号
                  l_wk_tab(ln_line_cnt).ref_number   := lt_l_ref_number;    -- 参照番号
                  l_wk_tab(ln_line_cnt).payment_code := lt_l_payment_code;  -- 入払区分
                  l_wk_tab(ln_line_cnt).trans_code   := lt_l_trans_code;    -- 取引区分
                  l_wk_tab(ln_line_cnt).alt_name     := lt_l_alt_name;      -- 振込依頼人
                  l_wk_tab(ln_line_cnt).receipt_date := lt_l_receipt_date;  -- 入金日
                  l_wk_tab(ln_line_cnt).amount       := lt_l_amount;        -- 入金額
                  l_wk_tab(ln_line_cnt).comments     := lt_l_comments;      -- 注釈
                  l_wk_tab(ln_line_cnt).cash_flag    := cv_need;            -- 入金要否フラグ(要)
                  l_wk_tab(ln_line_cnt).apply_flag   := cv_need;            -- 消込要否フラグ(要)
                  l_wk_tab(ln_line_cnt).in_file_name := lt_l_file_name;     -- ファイル名
--
                END IF;
--
              END IF;
            -- トレーラ部、エンド部
            ELSE
              NULL;
            END IF;
--
          EXCEPTION
--
            WHEN NO_DATA_FOUND THEN
--
              -- ファイルが開いていたら閉じる
              IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
                UTL_FILE.FCLOSE( lf_file_hand ) ;
              END IF;
--
              -- ファイル内にデータが存在しない場合は、メッセージ出力
              IF (ln_read_count = 0) THEN
--
                -- データがない旨を出力
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_005a04_122
                                ,iv_token_name1  => cv_tkn_file_name
                                ,iv_token_value1 => i_fb_file_name_tab( ln_count )
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg
                );
--
                ob_warn_end   := cb_true;  -- コンカレントを警告終了にする
--
              END IF;
--
              EXIT;  -- loop_get_dataを脱出。loop_get_fb_dataの次レコードへ。
--
            WHEN OTHERS THEN
--
              -- ファイルが開いていたら閉じる
              IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
                UTL_FILE.FCLOSE( lf_file_hand ) ;
              END IF;
--
              RAISE global_api_expt;
          END;
--
        END LOOP loop_get_data;  -- FBデータ取得ループ
--
      END IF;  -- ファイルOPENエラー
--
    END LOOP loop_get_fb_data;  -- ファイルOPENループ
--
    -- OUTパラメータに設定
    o_rockbox_table_tab := l_wk_tab;
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
  END get_fb_data;
--
-- 2015/05/29 Ver1.02 Add Start
  /**********************************************************************************
   * Procedure Name   : get_bank_info
   * Description      : 入金24時間化銀行情報取得処理 (A-11)
   ***********************************************************************************/
  PROCEDURE get_bank_info(
    it_bank_number       IN         xxcfr_rockbox_wk.bank_number%TYPE,      -- 銀行コード
    it_receipt_date      IN         xxcfr_rockbox_wk.receipt_date%TYPE,     -- 入金日(IN)
    ot_receipt_date      OUT NOCOPY xxcfr_rockbox_wk.receipt_date%TYPE,     -- 入金日(OUT)
    ot_bank_code_flag    OUT NOCOPY VARCHAR2,                               -- 24時間化対応銀行フラグ
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bank_info'; -- プログラム名
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
    -- *** ローカル定数 ***
    ct_fb_bank_code24    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_BANK_CODE24';  -- 参照タイプ「FB24時間化対応銀行」
--
    -- *** ローカル変数 ***
    cn_count_bank_number NUMBER;              -- 24時間化対応銀行カウント
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_receipt_date      := gd_process_date;   -- 入金日(OUT)に業務日付をセット
    ot_bank_code_flag    := cv_flag_n;         -- 24時間化対応銀行フラグ：'N'
    cn_count_bank_number := 0;
--
    -- 24時間化対応銀行取得
    SELECT COUNT(flvv.lookup_code)  AS count_bank_number  -- 銀行コードカウント
    INTO   cn_count_bank_number
    FROM   fnd_lookup_values_vl flvv  -- 参照表
    WHERE  flvv.lookup_type  = ct_fb_bank_code24   -- 参照タイプ
    AND    flvv.lookup_code  = it_bank_number      -- 銀行コード
    AND    flvv.enabled_flag = cv_flag_y           -- 有効フラグ
    AND    it_receipt_date BETWEEN NVL( flvv.start_date_active, it_receipt_date )  -- 有効日(自)
                               AND NVL( flvv.end_date_active  , it_receipt_date )  -- 有効日(至)
    ;
--
    -- 24時間化対応銀行の場合
    IF ( cn_count_bank_number > 0) THEN
      -- 入金日(OUT)に入金日をセット
      ot_receipt_date   := it_receipt_date;
      -- 24時間化対応銀行フラグを'Y'にする
      ot_bank_code_flag := cv_flag_y;
    END IF;
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
  END get_bank_info;
--
-- 2015/05/29 Ver1.02 Add End
  /**********************************************************************************
   * Procedure Name   : get_receive_method
   * Description      : 支払方法取得処理 (A-3)
   ***********************************************************************************/
  PROCEDURE get_receive_method(
    it_bank_number         IN         xxcfr_rockbox_wk.bank_number%TYPE,          -- 銀行コード
    it_bank_num            IN         xxcfr_rockbox_wk.bank_num%TYPE,             -- 支店コード
    it_account_type        IN         xxcfr_rockbox_wk.account_type%TYPE,         -- 口座種別
    it_account_num         IN         xxcfr_rockbox_wk.account_num%TYPE,          -- 口座番号
    it_ref_number          IN         xxcfr_rockbox_wk.ref_number%TYPE,           -- 参照番号
    ot_receipt_method_id   OUT NOCOPY xxcfr_rockbox_wk.receipt_method_id%TYPE,    -- 支払方法ID
    ot_receipt_method_name OUT NOCOPY xxcfr_rockbox_wk.receipt_method_name%TYPE,  -- 支払方法名称
    ot_cash_flag           OUT NOCOPY xxcfr_rockbox_wk.cash_flag%TYPE,            -- 入金要否フラグ
    ot_apply_flag          OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,           -- 消込要否フラグ
    ov_errbuf              OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receive_method'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_staus_a           CONSTANT VARCHAR2(1)  := 'A';
    cv_my_part           CONSTANT VARCHAR2(10) := 'INTERNAL';
    cv_account_num_left  CONSTANT VARCHAR2(10) := '0000000000';
--
    -- *** ローカル変数 ***
    ln_count   PLS_INTEGER;  -- ループカウンタ
--
    -- *** ローカル・カーソル ***
    -- 支払方法取得
    CURSOR get_receipt_method_cur(
             p_bank_number  xxcfr_rockbox_wk.bank_number%TYPE   -- 銀行コード
            ,p_bank_num     xxcfr_rockbox_wk.bank_num%TYPE      -- 支店コード
            ,p_account_type xxcfr_rockbox_wk.account_type%TYPE  -- 口座種別
            ,p_account_num  xxcfr_rockbox_wk.account_num%TYPE   -- 口座番号
           )
    IS
      SELECT arm.receipt_method_id  AS receipt_method_id    -- 支払方法内部ID
            ,arm.name               AS receipt_method_name  -- 支払方法名称
            ,arm.attribute1         AS receipt_method_owner -- 支払方法入金拠点
            ,aba.attribute1         AS bank_account_owner   -- 口座所有部門
      FROM   ar_receipt_methods  arm  -- AR支払方法テーブル
            ,ap_bank_branches    abb  -- 銀行支店
            ,ap_bank_accounts    aba  -- 銀行口座情報マルチオルグビュー
            ,ar_lockboxes        ala  -- ロックボックスマルチオルグビュー
      WHERE  arm.receipt_method_id = ala.receipt_method_id        -- 内部ID
      AND    aba.bank_account_num  = ala.bank_origination_number  -- 内部ID
      AND    abb.bank_branch_id    = aba.bank_branch_id           -- 内部ID
      AND    abb.bank_number       = p_bank_number    -- 銀行コード
      AND    abb.bank_num          = p_bank_num       -- 支店コード
      AND    aba.bank_account_type = p_account_type   -- 口座種別
      AND    SUBSTRB(cv_account_num_left   -- FBデータは左ゼロ埋めで作成されているため。
                  || aba.bank_account_num  -- 口座番号が7桁以外でも対応可能とした。
                   ,-10
             )                     = p_account_num    -- 口座番号
      AND    aba.set_of_books_id   = gt_set_of_bks_id  -- 会計帳簿ID
      AND    ala.status            = cv_staus_a  -- ステータス
      AND    aba.account_type      = cv_my_part  -- 当方口座
      AND    TRUNC( SYSDATE ) BETWEEN NVL( arm.start_date, TRUNC( SYSDATE ) )  -- 開始日
                                  AND NVL( arm.end_date  , TRUNC( SYSDATE ) )  -- 終了日
      AND    TRUNC( SYSDATE )       < NVL( aba.inactive_date, TRUNC( SYSDATE ) + 1 )  -- 銀行口座の無効日
      ;
--
    TYPE ttype_get_rec_method IS TABLE OF get_receipt_method_cur%ROWTYPE
                                 INDEX BY PLS_INTEGER;
    l_get_rec_method_tab ttype_get_rec_method;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_receipt_method_id   := NULL;        -- 支払方法内部ID
    ot_receipt_method_name := NULL;        -- 支払方法名称
    ot_cash_flag           := cv_no_need;  -- 入金要否フラグ(否)
    ot_apply_flag          := cv_no_need;  -- 消込要否フラグ(否)
    -- 配列
    l_get_rec_method_tab.DELETE;
--
    OPEN get_receipt_method_cur(
      p_bank_number  => it_bank_number   -- 銀行コード
     ,p_bank_num     => it_bank_num      -- 支店コード
     ,p_account_type => it_account_type  -- 口座種別
     ,p_account_num  => it_account_num   -- 口座番号
    );
--
    FETCH get_receipt_method_cur BULK COLLECT INTO l_get_rec_method_tab;
    CLOSE get_receipt_method_cur;
--
    IF   ( l_get_rec_method_tab.COUNT < 1 ) THEN
--
      -- 支払方法が取得できなかった旨を出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_115
                      ,iv_token_name1  => cv_tkn_bank_number
                      ,iv_token_value1 => it_bank_number
                      ,iv_token_name2  => cv_tkn_bank_num
                      ,iv_token_value2 => it_bank_num
                      ,iv_token_name3  => cv_tkn_bank_account_type
                      ,iv_token_value3 => it_account_type
                      ,iv_token_name4  => cv_tkn_bank_account_num
                      ,iv_token_value4 => it_account_num
                      ,iv_token_name5  => cv_tkn_ref_number
                      ,iv_token_value5 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
      gn_warn_cnt := gn_warn_cnt + 1;  -- 警告件数をカウントアップ
--
    ELSIF( l_get_rec_method_tab.COUNT > 1 ) THEN
--
      -- 支払方法が複数取得できた旨を出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_126
                      ,iv_token_name1  => cv_tkn_bank_number
                      ,iv_token_value1 => it_bank_number
                      ,iv_token_name2  => cv_tkn_bank_num
                      ,iv_token_value2 => it_bank_num
                      ,iv_token_name3  => cv_tkn_bank_account_type
                      ,iv_token_value3 => it_account_type
                      ,iv_token_name4  => cv_tkn_bank_account_num
                      ,iv_token_value4 => it_account_num
                      ,iv_token_name5  => cv_tkn_ref_number
                      ,iv_token_value5 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 複数取得した支払方法を出力
      <<message_loop>>
      FOR ln_count IN l_get_rec_method_tab.FIRST..l_get_rec_method_tab.LAST LOOP
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_127
                        ,iv_token_name1  => cv_tkn_receipt_method
                        ,iv_token_value1 => l_get_rec_method_tab(ln_count).receipt_method_name
                        ,iv_token_name2  => cv_tkn_receipt_method_owner
                        ,iv_token_value2 => l_get_rec_method_tab(ln_count).receipt_method_owner
                        ,iv_token_name3  => cv_tkn_bank_account_owner
                        ,iv_token_value3 => l_get_rec_method_tab(ln_count).bank_account_owner
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END LOOP message_loop;
--
      gn_warn_cnt := gn_warn_cnt + 1;  -- 警告件数をカウントアップ
--
    ELSE
      -- 正常に取得できた場合
      ot_receipt_method_id   := l_get_rec_method_tab(l_get_rec_method_tab.FIRST).receipt_method_id;    -- 支払方法ID
      ot_receipt_method_name := l_get_rec_method_tab(l_get_rec_method_tab.FIRST).receipt_method_name;  -- 支払方法名称
      ot_cash_flag           := cv_need;                                                               -- 入金要否フラグ(要)
      ot_apply_flag          := cv_need;                                                               -- 消込要否フラグ(要)
    END IF;
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
--
      IF ( get_receipt_method_cur%ISOPEN ) THEN
        CLOSE get_receipt_method_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_receive_method;
--
  /**********************************************************************************
   * Procedure Name   : get_receipt_customer
   * Description      : 入金先顧客取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_receipt_customer(
    it_alt_name          IN         xxcfr_rockbox_wk.alt_name%TYPE,         -- 振込依頼人名
    it_ref_number        IN         xxcfr_rockbox_wk.ref_number%TYPE,       -- 参照番号
    ot_cust_account_id   OUT NOCOPY xxcfr_rockbox_wk.cust_account_id%TYPE,  -- 顧客ID
    ot_account_number    OUT NOCOPY xxcfr_rockbox_wk.account_number%TYPE,   -- 顧客名称
    ot_apply_flag        OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,       -- 消込要否フラグ
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_customer'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_status_a  CONSTANT VARCHAR2(1) := 'A';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_cust_account_id := NULL;        -- 顧客ID
    ot_account_number  := NULL;        -- 顧客番号
    ot_apply_flag      := cv_no_need;  -- 消込要否フラグ(否)
--
    -- 入金顧客取得
    SELECT hca.cust_account_id  AS cust_account_id  -- 顧客ID
          ,xcan.account_number  AS account_number   -- 顧客番号
    INTO   ot_cust_account_id
          ,ot_account_number
    FROM   xxcfr_cust_alt_name  xcan  -- 振込依頼人マスタ
          ,hz_cust_accounts     hca   -- 顧客マスタ
    WHERE  xcan.alt_name       = it_alt_name         -- 振込依頼人名
    AND    xcan.account_number = hca.account_number  -- 顧客番号
    AND    hca.status          = cv_status_a         -- ステータス(有効)
    ;
--
    -- 正常に取得できた場合
    ot_apply_flag := cv_need;     -- 消込要否フラグ(要)
--
  EXCEPTION
    -- 対象データなし
    WHEN NO_DATA_FOUND THEN
      -- 入金先顧客が取得できなかった旨を出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_116
                      ,iv_token_name1  => cv_tkn_alt_name
                      ,iv_token_value1 => it_alt_name
                      ,iv_token_name2  => cv_tkn_ref_number
                      ,iv_token_value2 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      gn_no_customer_cnt := gn_no_customer_cnt + 1;  -- 不明入金件数をカウントアップ
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
  END get_receipt_customer;
--
  /**********************************************************************************
   * Procedure Name   : get_fb_out_acct_number
   * Description      : 自動消込対象外顧客取得処理 (A-5)
   ***********************************************************************************/
  PROCEDURE get_fb_out_acct_number(
    it_account_number    IN         xxcfr_rockbox_wk.account_number%TYPE,  -- 顧客番号
-- 2015/05/29 Ver1.02 Add Start
    it_receipt_date      IN         xxcfr_rockbox_wk.receipt_date%TYPE,    -- 入金日
-- 2015/05/29 Ver1.02 Add End
    ot_apply_flag        OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,      -- 消込要否フラグ
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_out_acct_number'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count   PLS_INTEGER;
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_apply_flag := cv_need;  -- 消込要否フラグ(要)
    --
    ln_count  := 0;
--
    --自動消込対象外顧客取得
    SELECT COUNT(ROWNUM) AS cnt
    INTO   ln_count
    FROM   fnd_lookup_values_vl flvv  -- 参照タイプマスタ
    WHERE  flvv.lookup_type  = ct_out_acct_number  -- 参照タイプ
    AND    flvv.lookup_code  = it_account_number   -- 参照コード
    AND    flvv.enabled_flag = cv_flag_y           -- 有効フラグ
-- 2015/05/29 Ver1.02 Mod Start
--    AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )  -- 有効日(自)
--                               AND NVL( flvv.end_date_active  , gd_process_date )  -- 有効日(至)
    AND    it_receipt_date BETWEEN NVL( flvv.start_date_active, it_receipt_date )
                               AND NVL( flvv.end_date_active  , it_receipt_date )
-- 2015/05/29 Ver1.02 Mod End
    ;
--
    -- 対象が取得できる場合
    IF ( ln_count > 0 )THEN
      ot_apply_flag := cv_no_need;  -- 消込要否フラグ(否)
    END IF;
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
  END get_fb_out_acct_number;
--
  /**********************************************************************************
   * Procedure Name   : get_trx_amount
   * Description      : 対象債権総額処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_trx_amount(
    it_cust_account_id        IN         xxcfr_rockbox_wk.cust_account_id%TYPE,         -- 顧客ID
    it_amount                 IN         xxcfr_rockbox_wk.amount%TYPE,                  -- 入金額
-- 2015/05/29 Ver1.02 Add Start
    it_receipt_date           IN         xxcfr_rockbox_wk.receipt_date%TYPE,            -- 入金日
    it_bank_code_flag         IN         VARCHAR2,                                      -- 24時間化対応銀行フラグ
-- 2015/05/29 Ver1.02 Add End
    ot_apply_flag             OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,              -- 消込要否フラグ
    ot_factor_discount_amount OUT NOCOPY xxcfr_rockbox_wk.factor_discount_amount%TYPE,  -- 手数料
    ot_apply_trx_count        OUT NOCOPY xxcfr_rockbox_wk.apply_trx_count%TYPE,         -- 消込対象件数
    ov_errbuf                 OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_amount'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_op    CONSTANT VARCHAR2(2) := 'OP';   -- オープン
    cv_rec   CONSTANT VARCHAR2(3) := 'REC';  -- 売掛／未収金
-- 2015/05/29 Ver1.02 Add Start
    cv_ar  CONSTANT VARCHAR2(2)   := 'AR';
-- 2015/05/29 Ver1.02 Add End
--
    -- *** ローカル変数 ***
    lt_amount_due_remaining  ar_payment_schedules_all.amount_due_remaining%TYPE := NULL;  -- 未回収残高
    lt_apply_trx_count       xxcfr_rockbox_wk.apply_trx_count%TYPE              := NULL;  -- 消込対象件数
-- 2015/05/29 Ver1.02 Add Start
    lt_tolerance_limit       ap_bank_charge_lines.tolerance_limit%TYPE          := NULL;  -- 手数料限度額
-- 2015/05/29 Ver1.02 Add End
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_apply_flag             := cv_no_need;  -- 消込要否フラグ(否)
    ot_factor_discount_amount := NULL;        -- 手数料
    ot_apply_trx_count        := NULL;        -- 消込対象件数
-- 2015/05/29 Ver1.02 Add Start
    lt_tolerance_limit        := NULL;        -- 手数料限度額
--
    -- 24時間化対応銀行の場合
    IF ( it_bank_code_flag = cv_flag_y ) THEN
      -- 手数料限度額を入金日で取得し直す
      BEGIN
        SELECT abcl.tolerance_limit AS tolerance_limit
        INTO   lt_tolerance_limit
        FROM   ap_bank_charges      abc   -- 銀行手数料
              ,ap_bank_charge_lines abcl  -- 銀行手数料明細
        WHERE  abc.bank_charge_id    = abcl.bank_charge_id  -- 内部ID
        AND    abc.transfer_priority = cv_ar                -- 優先度
        AND    abcl.start_date                          <= it_receipt_date  -- 開始日
        AND    NVL( abcl.end_date, it_receipt_date + 1 ) > it_receipt_date  -- 終了日
        AND    abcl.tolerance_limit IS NOT NULL  -- 手数料限度額がNULL以外
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_114
                        ,iv_token_name1  => cv_tkn_receipt_date
                        ,iv_token_value1 => TO_CHAR(it_receipt_date, cv_format_date_ymd)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
    -- 24時間化対応銀行ではない場合
    ELSIF ( it_bank_code_flag = cv_flag_n ) THEN
      -- 業務日付で取得した手数料限度額をセット
      lt_tolerance_limit := gt_tolerance_limit;
    END IF;
-- 2015/05/29 Ver1.02 Add End
--
    -- 未回収残高取得
    SELECT SUM( xrctm.amount_due_remaining ) AS amount_due_remaining  -- 未回収残高合計
          ,COUNT( ROWNUM )                   AS cnt                   -- 消込対象本数
    INTO   lt_amount_due_remaining
          ,lt_apply_trx_count
    FROM   xxcfr_rock_cust_trx_mv   xrctm   -- 債権マテビュー
          ,xxcfr_cust_hierarchy_mv  xchm    -- 請求顧客マテビュー
    WHERE xchm.bill_account_id = xrctm.bill_to_customer_id  -- 内部ID
    AND   xchm.cash_account_id = it_cust_account_id         -- 入金顧客ID
    ;
--
    -- 対象の債権が存在し、且つ手数料が限度額以内であるかを判定し、手数料を決定する。
-- 2015/05/29 Ver1.02 Mod Start
--    IF ( ( gt_tolerance_limit >= ABS( lt_amount_due_remaining - it_amount ) ) -- 手数料限度額 >= ABS(未回収残高合計 - 入金額)
    IF ( ( lt_tolerance_limit >= ABS( lt_amount_due_remaining - it_amount ) ) -- 手数料限度額 >= ABS(未回収残高合計 - 入金額)
-- 2015/05/29 Ver1.02 Mod End
     AND ( lt_apply_trx_count >  0                                          ) -- 消込対象本数 >  0
    ) THEN 
--
      -- 未回収残高合計が入金額以上であるときは、その差額を手数料として作成する
      IF ( lt_amount_due_remaining >= it_amount ) THEN  -- 未回収残高合計 >= 入金額
        ot_factor_discount_amount := lt_amount_due_remaining - it_amount; -- 手数料(未回収残高合計 - 入金額)
      ELSE
        ot_factor_discount_amount := 0;                                   -- ゼロ
      END IF;
--
      ot_apply_trx_count := lt_apply_trx_count;  -- 消込対象件数
      ot_apply_flag      := cv_need;             -- 消込要否フラグ(要)
--
    END IF;
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
  END get_trx_amount;
--
  /**********************************************************************************
   * Procedure Name   : exec_cash_api
   * Description      : 入金API起動処理 (A-7)
   ***********************************************************************************/
  PROCEDURE exec_cash_api(
    it_amount                 IN            xxcfr_rockbox_wk.amount%TYPE,                  -- 入金額
    it_factor_discount_amount IN            xxcfr_rockbox_wk.factor_discount_amount%TYPE,  -- 手数料
    it_receipt_number         IN            xxcfr_rockbox_wk.receipt_number%TYPE,          -- 入金番号
    it_receipt_date           IN            xxcfr_rockbox_wk.receipt_date%TYPE,            -- 入金日
    it_cust_account_id        IN            xxcfr_rockbox_wk.cust_account_id%TYPE,         -- 顧客ID
    it_account_number         IN            xxcfr_rockbox_wk.account_number%TYPE,          -- 顧客番号
    it_receipt_method_id      IN            xxcfr_rockbox_wk.receipt_method_id%TYPE,       -- 支払方法ID
    it_receipt_method_name    IN            xxcfr_rockbox_wk.receipt_method_name%TYPE,     -- 支払方法名
    it_alt_name               IN            xxcfr_rockbox_wk.alt_name%TYPE,                -- 振込依頼人名
    it_comments               IN            xxcfr_rockbox_wk.comments%TYPE,                -- 注釈
    it_ref_number             IN            xxcfr_rockbox_wk.ref_number%TYPE,              -- 参照番号
    iot_apply_flag            IN OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,              -- 消込要否フラグ 
    ot_cash_receipt_id        OUT    NOCOPY xxcfr_rockbox_wk.cash_receipt_id%TYPE,         -- 入金ID
    ov_errbuf                 OUT    NOCOPY VARCHAR2,  --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT    NOCOPY VARCHAR2,  --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT    NOCOPY VARCHAR2)  --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_cash_api'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
    l_attribute_rec    ar_receipt_api_pub.attribute_rec_type := NULL;  -- attribute用
--
    -- *** ローカル・カーソル ***
    cv_status_n  CONSTANT VARCHAR2(1) := 'N';
    cv_status_s  CONSTANT VARCHAR2(1) := 'S';
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_cash_receipt_id := NULL;        -- 入金内部ID
--
    -- 付加フレックスフィールドの設定
    l_attribute_rec.attribute_category := TO_CHAR(gn_org_id);  -- 営業単位
    l_attribute_rec.attribute1         := it_alt_name;         -- 振込依頼人名
--
    -- 入金消込API起動
    ar_receipt_api_pub.create_cash(
       p_api_version                 => 1.0
      ,p_init_msg_list               => FND_API.G_TRUE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_amount                      => it_amount                 -- 入金額
      ,p_factor_discount_amount      => it_factor_discount_amount -- 手数料
      ,p_receipt_number              => it_receipt_number         -- 入金番号
      ,p_receipt_date                => it_receipt_date           -- 入金日
      ,p_gl_date                     => it_receipt_date           -- GL記帳日
      ,p_customer_id                 => it_cust_account_id        -- 顧客内部ID
      ,p_receipt_method_id           => it_receipt_method_id      -- 入金方法
      ,p_override_remit_account_flag => cv_status_n               -- 送金銀行口座上書許可フラグ(Y/N)
      ,p_attribute_rec               => l_attribute_rec           -- 付加フレックス
      ,p_comments                    => it_comments               -- 注釈
      ,p_cr_id                       => ot_cash_receipt_id        -- (戻り値)入金内部ID
    );
--
    -- 入金APIが成功したとき
    IF ( lv_return_status = cv_status_s ) THEN
      -- 不明入金でなければ、成功件数をカウントアップ
      IF NOT( it_cust_account_id IS NULL ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    -- 入金APIが失敗したとき
    ELSE
      --エラー処理
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr
                     ,iv_name         => cv_msg_005a04_117
                     ,iv_token_name1  => cv_tkn_receipt_number
                     ,iv_token_value1 => it_receipt_number
                     ,iv_token_name2  => cv_tkn_account_number
                     ,iv_token_value2 => it_account_number
                     ,iv_token_name3  => cv_tkn_receipt_method
                     ,iv_token_value3 => it_receipt_method_name
                     ,iv_token_name4  => cv_tkn_receipt_date
                     ,iv_token_value4 => TO_CHAR( it_receipt_date,cv_format_date_ymd )
                     ,iv_token_name5  => cv_tkn_amount
                     ,iv_token_value5 => TO_CHAR( it_amount )
                     ,iv_token_name6  => cv_tkn_ref_number
                     ,iv_token_value6 => it_ref_number
                   );
      -- 入金APIエラーメッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API標準エラーメッセージ出力
      IF (ln_msg_count = 1) THEN
        -- API標準エラーメッセージが１件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_msg_brack_point || lv_msg_data
        );
--
      ELSE
        -- API標準エラーメッセージが複数件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_msg_brack_point || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                                   ,1
                                                   ,5000
                                                 )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_msg_brack_point || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                                     ,1
                                                     ,5000
                                                   )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- 警告件数をカウントアップ
      gn_warn_cnt := gn_warn_cnt + 1;
      -- 不明入金のときは、不明入金数をカウントダウンする
      IF ( it_cust_account_id IS NULL ) THEN
        gn_no_customer_cnt := gn_no_customer_cnt - 1;
      END IF;
      -- 消込要否フラグ(否)
      iot_apply_flag := cv_no_need;
    END IF;
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
  END exec_cash_api;
--
  /**********************************************************************************
   * Procedure Name   : insert_table
   * Description      : ロックボックス入金消込ワークテーブル登録処理 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_table(
    i_rockbox_table_tab IN         rockbox_table_ttype,  -- FBデータ
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_table'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
--
    BEGIN
--
      <<insert_loop>>
      FOR ln_count IN i_rockbox_table_tab.FIRST..i_rockbox_table_tab.LAST LOOP
--
        -- 消込要否(要)のときは、ワークテーブルに対象データを登録する
        IF (i_rockbox_table_tab(ln_count).apply_flag = cv_need) THEN
--
          INSERT INTO xxcfr_rockbox_wk(
            parallel_type          -- パラレル実行区分
           ,kind_code              -- 種別コード
           ,bank_number            -- 銀行コード
           ,bank_num               -- 支店コード
           ,account_type           -- 口座種別
           ,account_num            -- 口座番号
           ,ref_number             -- 照会番号
           ,payment_code           -- 入払区分
           ,trans_code             -- 取引区分
           ,alt_name               -- 振込依頼人名
           ,cust_account_id        -- 顧客ID
           ,account_number         -- 顧客番号
           ,cash_receipt_id        -- 入金内部ID
           ,receipt_number         -- 入金番号
           ,receipt_date           -- 入金日
           ,amount                 -- 入金額
           ,factor_discount_amount -- 手数料
           ,receipt_method_name    -- 支払方法名称
           ,receipt_method_id      -- 支払方法ID
           ,comments               -- 注釈
           ,cash_flag              -- 入金要否フラグ
           ,apply_flag             -- 消込要否フラグ
           ,apply_trx_count        -- 消込対象件数
           ,in_file_name           -- 取込ファイル名
           ,created_by             -- 作成者
           ,creation_date          -- 作成日
           ,last_updated_by        -- 最終更新者
           ,last_update_date       -- 最終更新日
           ,last_update_login      -- 最終更新ログイン
           ,request_id             -- 要求ID
           ,program_application_id -- コンカレント・プログラム・アプリケーションID
           ,program_id             -- コンカレント・プログラムID
           ,program_update_date    -- プログラム更新日
          )
          VALUES
          (
           NULL                                               -- パラレル実行区分
          ,i_rockbox_table_tab(ln_count).kind_code               -- 種別コード
          ,i_rockbox_table_tab(ln_count).bank_number             -- 銀行コード
          ,i_rockbox_table_tab(ln_count).bank_num                -- 支店コード
          ,i_rockbox_table_tab(ln_count).account_type            -- 口座種別
          ,i_rockbox_table_tab(ln_count).account_num             -- 口座番号
          ,i_rockbox_table_tab(ln_count).ref_number              -- 照会番号
          ,i_rockbox_table_tab(ln_count).payment_code            -- 入払区分
          ,i_rockbox_table_tab(ln_count).trans_code              -- 取引区分
          ,i_rockbox_table_tab(ln_count).alt_name                -- 振込依頼人名
          ,i_rockbox_table_tab(ln_count).cust_account_id         -- 顧客ID
          ,i_rockbox_table_tab(ln_count).account_number          -- 顧客番号
          ,i_rockbox_table_tab(ln_count).cash_receipt_id         -- 入金内部ID
          ,i_rockbox_table_tab(ln_count).receipt_number          -- 入金番号
          ,i_rockbox_table_tab(ln_count).receipt_date            -- 入金日
          ,i_rockbox_table_tab(ln_count).amount                  -- 入金額
          ,i_rockbox_table_tab(ln_count).factor_discount_amount  -- 手数料
          ,i_rockbox_table_tab(ln_count).receipt_method_name     -- 支払方法名称
          ,i_rockbox_table_tab(ln_count).receipt_method_id       -- 支払方法ID
          ,i_rockbox_table_tab(ln_count).comments                -- 注釈
          ,i_rockbox_table_tab(ln_count).cash_flag               -- 入金要否フラグ
          ,i_rockbox_table_tab(ln_count).apply_flag              -- 消込要否フラグ
          ,i_rockbox_table_tab(ln_count).apply_trx_count         -- 消込対象件数
          ,i_rockbox_table_tab(ln_count).in_file_name            -- 取込ファイル名
          ,cn_created_by                                      -- 作成者
          ,cd_creation_date                                   -- 作成日
          ,cn_last_updated_by                                 -- 最終更新者
          ,cd_last_update_date                                -- 最終更新日
          ,cn_last_update_login                               -- 最終更新ログイン
          ,cn_request_id                                      -- 要求ID
          ,cn_program_application_id                          -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                      -- コンカレント・プログラムID
          ,cd_program_update_date                             -- プログラム更新日
          )
          ;
--
          gn_auto_apply_cnt := gn_auto_apply_cnt + 1;  -- 自動消込対象件数をカウントアップ
--
        END IF;
--
      END LOOP insert_loop;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        -- 登録エラーの旨を出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_016
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
    END
    ;
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
  END insert_table;
--
  /**********************************************************************************
   * Procedure Name   : update_table
   * Description      : パラレル実行区分付与処理 (A-9)
   ***********************************************************************************/
  PROCEDURE update_table(
    ov_errbuf            OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_table'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count   PLS_INTEGER;  -- ループカウンタ
--
    -- *** ローカル・カーソル ***
    CURSOR upd_rock_cur
    IS
      SELECT xrw.rowid AS row_id
            ,MOD( ( ROW_NUMBER() OVER (ORDER BY xrw.apply_trx_count DESC) ) + gn_prf_par_cnt - 1
                                      , gn_prf_par_cnt
             ) + 1     AS parallel_type  -- パラレル実行区分
      FROM   xxcfr_rockbox_wk xrw  -- ロックボックス入金消込ワーク
      WHERE  xrw.request_id  = cn_request_id  -- 要求ID
      AND    xrw.apply_flag  = cv_need        -- 消込要否フラグ(要)
      FOR UPDATE NOWAIT
      ;
--
    TYPE upd_rock_ttype IS TABLE OF upd_rock_cur%ROWTYPE
                           INDEX BY PLS_INTEGER;  -- FBデータ
    l_upd_rock_tab  upd_rock_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- 配列
    l_upd_rock_tab.DELETE;
--
    BEGIN
--
      OPEN upd_rock_cur;
      FETCH upd_rock_cur BULK COLLECT INTO l_upd_rock_tab;
      CLOSE upd_rock_cur;
--
      <<update_loop>>
      FOR ln_count IN 1..l_upd_rock_tab.COUNT LOOP
--
        UPDATE xxcfr_rockbox_wk xrw  -- ロックボックス入金消込ワーク
        SET    xrw.parallel_type = l_upd_rock_tab(ln_count).parallel_type  -- パラレル実行区分
        WHERE  xrw.rowid = l_upd_rock_tab(ln_count).row_id
        ;
--
      END LOOP update_loop;
--
    EXCEPTION
      WHEN global_lock_err_expt THEN
--
        -- カーソルが開いていたら閉じる
        IF ( upd_rock_cur%ISOPEN ) THEN
          CLOSE upd_rock_cur;
        END IF;
--
        -- ロックエラーが発生した旨を出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_003
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
--
        -- カーソルが開いていたら閉じる
        IF ( upd_rock_cur%ISOPEN ) THEN
          CLOSE upd_rock_cur;
        END IF;
--
        -- 更新エラーが発生した旨を出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_017
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
    END
    ;
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
  END update_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_fb_file_name       IN         VARCHAR2,  -- パラメータ．FBファイル名
    iv_table_insert_flag  IN         VARCHAR2,  -- パラメータ．ワークテーブル作成フラグ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count          PLS_INTEGER;  -- ループカウンタ
    ln_cash_cnt       PLS_INTEGER;  -- 入金番号に使用する連番の採番用
    lb_warn_end       BOOLEAN;      -- 終了ステータス制御
-- 2015/05/29 Ver1.02 Add Start
    ln_cash_cnt2         PLS_INTEGER;  -- 24時間化対応銀行の入金番号に使用する連番の採番用
    lv_bank_code_flag    VARCHAR2(1);  -- 24時間化対応銀行フラグ
    lv_registration_flag VARCHAR2(1);  -- 入金番号管理テーブル登録フラグ
--
    lt_receipt_date      xxcfr_rockbox_wk.receipt_date%TYPE := NULL;  -- 入金日
-- 2015/05/29 Ver1.02 Add End
--
    l_rockbox_table_tab  rockbox_table_ttype;      -- FBデータ
    l_fb_file_name_tab   fnd_lookup_values_ttype;  -- FBファイル名
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    -- 戻り値
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- グローバル変数
    gn_target_cnt      := 0;  -- 対象件数
    gn_normal_cnt      := 0;  -- 成功件数
    gn_error_cnt       := 0;  -- エラー件数
    gn_warn_cnt        := 0;  -- 警告件数
    gn_no_customer_cnt := 0;  -- 不明入金件数
    gn_auto_apply_cnt  := 0;  -- 自動消込対象件数
    -- 配列
    l_rockbox_table_tab.DELETE;
    l_fb_file_name_tab.DELETE;
    -- ローカル変数
    ln_cash_cnt := 0;
    lb_warn_end := cb_false;
-- 2015/05/29 Ver1.02 Add Start
    ln_cash_cnt2         := 0;
    lv_bank_code_flag    := cv_flag_n;
    lv_registration_flag := cv_flag_n;
-- 2015/05/29 Ver1.02 Add End
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  初期処理 (A-1)
    -- =====================================================
    init(
       iv_fb_file_name      => iv_fb_file_name       -- パラメータ．FBファイル名
      ,iv_table_insert_flag => iv_table_insert_flag  -- パラメータ．ワークテーブル作成フラグ
      ,o_fb_file_name_tab   => l_fb_file_name_tab    -- FBファイル名
      ,ov_errbuf            => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode           => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg            => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  FBファイル取込処理 (A-2)
    -- =====================================================
    get_fb_data(
       i_fb_file_name_tab  => l_fb_file_name_tab  -- FBファイル名
      ,o_rockbox_table_tab => l_rockbox_table_tab -- FBデータ
      ,ob_warn_end         => lb_warn_end         -- 終了ステータス制御
      ,ov_errbuf           => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象データが存在しないときは、警告終了
    IF ( l_rockbox_table_tab.COUNT = 0 ) THEN
--
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
      -- 対象データなしメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_024
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
      ov_retcode := cv_status_warn;
--
    ELSE
--
      -- FBファイルのレコード分ループ
      <<loop_fb_data>>
      FOR ln_count IN l_rockbox_table_tab.FIRST..l_rockbox_table_tab.LAST LOOP
--
-- 2015/05/29 Ver1.02 Add Start
        -- =====================================================
        --  入金24時間化銀行情報取得処理 (A-11)
        -- =====================================================
        get_bank_info(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- 銀行コード
          ,it_receipt_date        => l_rockbox_table_tab(ln_count).receipt_date         -- 入金日(IN)
          ,ot_receipt_date        => lt_receipt_date                                    -- 入金日(OUT)
          ,ot_bank_code_flag      => lv_bank_code_flag                                  -- 24時間化対応銀行フラグ
          ,ov_errbuf              => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode             => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg              => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2015/05/29 Ver1.02 Add End
        -- =====================================================
        --  支払方法取得処理 (A-3)
        -- =====================================================
        get_receive_method(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- 銀行コード
          ,it_bank_num            => l_rockbox_table_tab(ln_count).bank_num             -- 支店コード
          ,it_account_type        => l_rockbox_table_tab(ln_count).account_type         -- 口座種別
          ,it_account_num         => l_rockbox_table_tab(ln_count).account_num          -- 口座番号
          ,it_ref_number          => l_rockbox_table_tab(ln_count).ref_number           -- 参照番号
          ,ot_receipt_method_id   => l_rockbox_table_tab(ln_count).receipt_method_id    -- 支払方法ID
          ,ot_receipt_method_name => l_rockbox_table_tab(ln_count).receipt_method_name  -- 支払方法名称
          ,ot_cash_flag           => l_rockbox_table_tab(ln_count).cash_flag            -- 入金要否フラグ
          ,ot_apply_flag          => l_rockbox_table_tab(ln_count).apply_flag           -- 消込要否フラグ
          ,ov_errbuf              => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode             => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg              => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 入金対象フラグが'1'(要)のとき。(支払方法が取得できたとき)
        IF ( l_rockbox_table_tab(ln_count).cash_flag = cv_need ) THEN
--
          -- =====================================================
          --  入金先顧客取得処理 (A-4)
          -- =====================================================
          get_receipt_customer(
             it_alt_name        => l_rockbox_table_tab(ln_count).alt_name         -- 振込依頼人名
            ,it_ref_number      => l_rockbox_table_tab(ln_count).ref_number       -- 参照番号
            ,ot_cust_account_id => l_rockbox_table_tab(ln_count).cust_account_id  -- 顧客ID
            ,ot_account_number  => l_rockbox_table_tab(ln_count).account_number   -- 顧客番号
            ,ot_apply_flag      => l_rockbox_table_tab(ln_count).apply_flag       -- 消込要否フラグ
            ,ov_errbuf          => lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,ov_retcode         => lv_retcode  -- リターン・コード             --# 固定 #
            ,ov_errmsg          => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 消込対象フラグが'1'(要)のとき(不明入金ではないとき)、且つ、パラメータ．ワークテーブル作成フラグが（Y）のとき
          IF (  ( l_rockbox_table_tab(ln_count).apply_flag = cv_need )  -- 自動消込要否が'1'(要)
            AND ( iv_table_insert_flag = cv_flag_y                   )  -- パラメータ．ワークテーブル作成フラグが'Y'
          ) THEN
--
            -- =====================================================
            --  自動消込対象外顧客取得処理 (A-5)
            -- =====================================================
            get_fb_out_acct_number(
               it_account_number  => l_rockbox_table_tab(ln_count).account_number   -- 顧客番号
-- 2015/05/29 Ver1.02 Add Start
              ,it_receipt_date    => lt_receipt_date                                -- 入金日
-- 2015/05/29 Ver1.02 Add End
              ,ot_apply_flag      => l_rockbox_table_tab(ln_count).apply_flag       -- 消込要否フラグ
              ,ov_errbuf          => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode         => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg          => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- 消込対象フラグが'1'(要)のとき、且つ、パラメータ．ワークテーブル作成フラグが（Y）のとき
          IF (  ( l_rockbox_table_tab(ln_count).apply_flag = cv_need )  -- 自動消込要否が'1'(要)
            AND ( iv_table_insert_flag = cv_flag_y                   )  -- パラメータ．ワークテーブル作成フラグが'Y'
          ) THEN
--
            -- =====================================================
            --  対象債権総額処理 (A-6)
            -- =====================================================
            get_trx_amount(
               it_cust_account_id        => l_rockbox_table_tab(ln_count).cust_account_id         -- 顧客ID
              ,it_amount                 => l_rockbox_table_tab(ln_count).amount                  -- 入金額
-- 2015/05/29 Ver1.02 Add Start
              ,it_receipt_date           => lt_receipt_date                                       -- 入金日
              ,it_bank_code_flag         => lv_bank_code_flag                                     -- 24時間化対応銀行フラグ
-- 2015/05/29 Ver1.02 Add End
              ,ot_apply_flag             => l_rockbox_table_tab(ln_count).apply_flag              -- 消込要否フラグ
              ,ot_factor_discount_amount => l_rockbox_table_tab(ln_count).factor_discount_amount  -- 手数料
              ,ot_apply_trx_count        => l_rockbox_table_tab(ln_count).apply_trx_count         -- 消込対象本数
              ,ov_errbuf                 => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode                => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg                 => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;  -- 支払方法が取得できたとき
--
      END LOOP loop_fb_data;
--
      -- FBファイルのレコード分ループ
      <<loop_exec_api>>
      FOR ln_count IN l_rockbox_table_tab.FIRST..l_rockbox_table_tab.LAST LOOP
--
        -- 入金要否フラグが（要）のときは入金を作成する
        IF ( l_rockbox_table_tab(ln_count).cash_flag = cv_need ) THEN
--
-- 2015/05/29 Ver1.02 Add Start
        -- =====================================================
        --  入金24時間化銀行情報取得処理 (A-11)
        -- =====================================================
        get_bank_info(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- 銀行コード
          ,it_receipt_date        => l_rockbox_table_tab(ln_count).receipt_date         -- 入金日(IN)
          ,ot_receipt_date        => lt_receipt_date                                    -- 入金日(OUT)
          ,ot_bank_code_flag      => lv_bank_code_flag                                  -- 24時間化対応銀行フラグ
          ,ov_errbuf              => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode             => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg              => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2015/05/29 Ver1.02 Add End
          -- =====================================================
          --  入金API起動処理 (A-7)
          -- =====================================================
-- 2015/05/29 Ver1.02 Mod Start
--          -- 入金番号の連番を採番する変数をカウントアップ
--          ln_cash_cnt := ln_cash_cnt + 1;
--          -- 入金番号の採番
--          l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FBファイル名
--                                                       || cv_msg_under_score                         -- アンダースコア
--                                                       || TO_CHAR( gd_process_date, cv_format_ymd )  -- 業務日付
--                                                       || cv_msg_under_score                         -- アンダースコア
--                                                       || TO_CHAR( ln_cash_cnt )                     -- 連番
--          ;
          -- 1.24時間化対応銀行ではない場合
          IF ( lv_bank_code_flag = cv_flag_n ) THEN
            -- 入金番号の連番を採番する変数をカウントアップ
            ln_cash_cnt := ln_cash_cnt + 1;
            -- 入金番号の採番
            l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FBファイル名
                                                         || cv_msg_under_score                         -- アンダースコア
                                                         || TO_CHAR( gd_process_date, cv_format_ymd )  -- 業務日付
                                                         || cv_msg_under_score                         -- アンダースコア
                                                         || TO_CHAR( ln_cash_cnt )                     -- 連番
            ;
--
          -- 2.24時間化対応銀行の場合
          ELSIF ( lv_bank_code_flag = cv_flag_y ) THEN
            -- 2-1.連番の取得
            -- 2-1-1.最初のレコードもしくは、前レコードと銀行コードもしくは入金日が違う場合
            IF ( ( ln_count = l_rockbox_table_tab.FIRST )
              OR ( l_rockbox_table_tab(ln_count).bank_number  <> l_rockbox_table_tab(ln_count-1).bank_number  )
              OR ( l_rockbox_table_tab(ln_count).receipt_date <> l_rockbox_table_tab(ln_count-1).receipt_date ) ) THEN
              -- 入金番号管理テーブルから連番を取得
              BEGIN
                SELECT xcrnc.receipt_num  AS receipt_num
                INTO   ln_cash_cnt2
                FROM   xxcfr_cash_receipts_no_control xcrnc
                WHERE  xcrnc.bank_cd                           = l_rockbox_table_tab(ln_count).bank_number
                AND    TRUNC(xcrnc.receipt_date, cv_format_dd) = TRUNC(l_rockbox_table_tab(ln_count).receipt_date, cv_format_dd)
                ;
              EXCEPTION
                -- 銀行コード・入金日単位で未登録の場合
                WHEN NO_DATA_FOUND THEN
                  -- 連番を0にする
                  ln_cash_cnt2 := 0;
                  -- 入金番号管理テーブル登録フラグを'Y'にする
                  lv_registration_flag := cv_flag_y;
              END;
              -- 入金番号の連番をカウントアップ
              ln_cash_cnt2 := ln_cash_cnt2 + 1;
            -- 2-1-2.前レコードと銀行コード・入金日が同じ場合
            ELSIF ( ( l_rockbox_table_tab(ln_count).bank_number  = l_rockbox_table_tab(ln_count-1).bank_number  )
              AND   ( l_rockbox_table_tab(ln_count).receipt_date = l_rockbox_table_tab(ln_count-1).receipt_date ) ) THEN
              -- 入金番号の連番をカウントアップ
              ln_cash_cnt2 := ln_cash_cnt2 + 1;
            END IF;
            -- 2-2.入金番号の採番
            l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FBファイル名
                                                         || cv_msg_under_score                         -- アンダースコア
                                                         || TO_CHAR( lt_receipt_date, cv_format_ymd )  -- 入金日付
                                                         || cv_msg_under_score                         -- アンダースコア
                                                         || TO_CHAR( ln_cash_cnt2 )                    -- 連番
            ;
            -- 2-3.最後のレコードもしくは、次レコードと銀行コードもしくは入金日が違う場合、入金番号管理テーブルの登録
            IF ( ( ln_count = l_rockbox_table_tab.LAST )
              OR ( l_rockbox_table_tab(ln_count).bank_number  <> l_rockbox_table_tab(ln_count+1).bank_number  )
              OR ( l_rockbox_table_tab(ln_count).receipt_date <> l_rockbox_table_tab(ln_count+1).receipt_date ) ) THEN
              -- 2-3-1.入金番号管理テーブル登録フラグが'Y'の場合
              IF ( lv_registration_flag = cv_flag_y ) THEN
                BEGIN
                  -- 入金番号管理テーブルに挿入
                  INSERT INTO xxcfr_cash_receipts_no_control(
                    bank_cd                 -- 銀行コード
                   ,receipt_date            -- 入金日
                   ,receipt_num             -- 番号
                   ,created_by              -- 作成者
                   ,creation_date           -- 作成日
                   ,last_updated_by         -- 最終更新者
                   ,last_update_date        -- 最終更新日
                   ,last_update_login       -- 最終更新ログイン
                   ,request_id              -- 要求ID
                   ,program_application_id  -- コンカレント・プログラム・アプリケーションID
                   ,program_id              -- コンカレント・プログラムID
                   ,program_update_date     -- プログラム更新日
                  )
                  VALUES
                  (
                    l_rockbox_table_tab(ln_count).bank_number   -- 銀行コード
                   ,l_rockbox_table_tab(ln_count).receipt_date  -- 入金日
                   ,ln_cash_cnt2                                -- 番号
                   ,cn_created_by                               -- 作成者
                   ,cd_creation_date                            -- 作成日
                   ,cn_last_updated_by                          -- 最終更新者
                   ,cd_last_update_date                         -- 最終更新日
                   ,cn_last_update_login                        -- 最終更新ログイン
                   ,cn_request_id                               -- 要求ID
                   ,cn_program_application_id                   -- コンカレント・プログラム・アプリケーションID
                   ,cn_program_id                               -- コンカレント・プログラムID
                   ,cd_program_update_date                      -- プログラム更新日
                  )
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    -- 登録エラーの旨を出力
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cfr
                                    ,iv_name         => cv_msg_005a04_016
                                    ,iv_token_name1  => cv_tkn_table
                                    ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_xcrnc)
                                   );
                    lv_errbuf := SUBSTRB(SQLERRM,1,5000);
                    RAISE global_process_expt;
                END;
                -- 入金番号管理テーブル登録フラグを'N'にする
                lv_registration_flag := cv_flag_n;
              -- 2-3-2.入金番号管理テーブル登録フラグが'N'の場合
              ELSIF ( lv_registration_flag = cv_flag_n ) THEN
                BEGIN
                  -- 入金番号管理テーブルを更新
                  UPDATE xxcfr_cash_receipts_no_control xcrnc
                  SET    xcrnc.receipt_num         = ln_cash_cnt2            -- 番号
                        ,xcrnc.last_updated_by     = cn_last_updated_by      -- 最終更新者
                        ,xcrnc.last_update_date    = cd_last_update_date     -- 最終更新日
                        ,xcrnc.last_update_login   = cn_last_update_login    -- 最終更新ログイン
                        ,xcrnc.program_update_date = cd_program_update_date  -- プログラム更新日
                  WHERE  xcrnc.bank_cd                           = l_rockbox_table_tab(ln_count).bank_number
                  AND    TRUNC(xcrnc.receipt_date, cv_format_dd) = TRUNC(l_rockbox_table_tab(ln_count).receipt_date, cv_format_dd)
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    -- 更新エラーの旨を出力
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cfr
                                    ,iv_name         => cv_msg_005a04_017
                                    ,iv_token_name1  => cv_tkn_table
                                    ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_xcrnc)
                                   );
                    lv_errbuf := SUBSTRB(SQLERRM,1,5000);
                    RAISE global_process_expt;
                END;
              END IF;
            END IF;
          END IF;
-- 2015/05/29 Ver1.02 Mod End
--
          exec_cash_api(
             it_amount                 => l_rockbox_table_tab(ln_count).amount                  -- 入金額
            ,it_factor_discount_amount => l_rockbox_table_tab(ln_count).factor_discount_amount  -- 手数料
            ,it_receipt_number         => l_rockbox_table_tab(ln_count).receipt_number          -- 入金番号
            ,it_receipt_date           => l_rockbox_table_tab(ln_count).receipt_date            -- 入金日
            ,it_cust_account_id        => l_rockbox_table_tab(ln_count).cust_account_id         -- 顧客ID
            ,it_account_number         => l_rockbox_table_tab(ln_count).account_number          -- 顧客番号
            ,it_receipt_method_id      => l_rockbox_table_tab(ln_count).receipt_method_id       -- 支払方法ID
            ,it_receipt_method_name    => l_rockbox_table_tab(ln_count).receipt_method_name     -- 支払方法名
            ,it_alt_name               => l_rockbox_table_tab(ln_count).alt_name                -- 振込依頼人名
            ,it_comments               => l_rockbox_table_tab(ln_count).comments                -- 注釈
            ,it_ref_number             => l_rockbox_table_tab(ln_count).ref_number              -- 参照番号
            ,iot_apply_flag            => l_rockbox_table_tab(ln_count).apply_flag              -- 消込フラグ
            ,ot_cash_receipt_id        => l_rockbox_table_tab(ln_count).cash_receipt_id         -- 入金ID
            ,ov_errbuf                 => lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,ov_retcode                => lv_retcode  -- リターン・コード             --# 固定 #
            ,ov_errmsg                 => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END LOOP loop_exec_api;
--
      -- パラメータ．ワークテーブル作成フラグが'Y'のときは登録する。
      IF ( iv_table_insert_flag = cv_flag_y ) THEN
--
        -- =====================================================
        --  ロックボックス入金消込ワークテーブル登録処理 (A-8)
        -- =====================================================
        insert_table(
           i_rockbox_table_tab => l_rockbox_table_tab -- FBデータ
          ,ov_errbuf           => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode          => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg           => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  パラレル実行区分付与処理 (A-9)
        -- =====================================================
        update_table(
           ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ファイル読み取りエラーが発生していたら、警告終了
      IF ( ( lb_warn_end            )  -- ファイル読み取りエラー
        OR ( gn_warn_cnt        > 0 )  -- 警告件数
        OR ( gn_no_customer_cnt > 0 )  -- 不明入金件数
      ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    END IF;  -- データ存在なし条件分岐
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode               OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_fb_file_name       IN         VARCHAR2,  -- パラメータ．FBファイル名
    iv_table_insert_flag  IN         VARCHAR2   -- パラメータ．ワークテーブル作成フラグ
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
       iv_fb_file_name      => iv_fb_file_name      -- FBファイル名
      ,iv_table_insert_flag => iv_table_insert_flag -- ワークテーブル削除フラグ
      ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
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
    --不明入金件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_118
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_no_customer_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_025
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --自動消込対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_128
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_auto_apply_cnt)
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
END XXCFR005A04C;
/