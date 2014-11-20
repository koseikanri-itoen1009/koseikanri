CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A07C(body)
 * Description      : 拠点別営業人員を情報系システムへ連携するための
 *                    ＣＳＶファイルを作成します。
 * MD.050           : MD050_CSO_016_A07_情報系-EBSインターフェース：
 *                    (OUT)拠点別営業人員
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_param_year         データ抽出パラメータ(年度)取得 (A-2)
 *  get_profile_info       プロファイル値取得 (A-3)
 *  open_csv_file          営業員別計画データCSVファイルオープン (A-4)
 *  create_csv_rec         営業員別計画データCSV出力 (A-6)
 *  close_csv_file         CSVファイルクローズ処理   (A-7)
 *  submain                メイン処理プロシージャ
 *                           拠点別営業人員抽出 (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-03-02    1.0   Mio.Maruyama     新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2009-07-21    1.2   Mio.Maruyama     統合テスト障害(0000783)対応
 *  2011-02-07    1.3   N.Horigome       E_本稼動_02682対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCSO016A01C';  -- パッケージ名
  cv_app_name         CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00149';  -- 年度取得エラー
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラーメッセージ
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00549';  -- CSVファイル出力エラー(拠点別営業人員)
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00148';  -- パラメータ（年度）
  /* 2009.07.21 Mio.Maruyama 0000783 対応 START */  
  -- cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラーメッセージ
  /* 2009.07.21 Mio.Maruyama 0000783 対応 END */  
  -- トークンコード
  cv_tkn_errmsg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_prof_nm      CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc      CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm      CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_fiscl_year   CONSTANT VARCHAR2(20) := 'FISCAL_YEAR';
  cv_tkn_ym           CONSTANT VARCHAR2(20) := 'YEAR_MONTH';
  cv_tkn_bs_cd        CONSTANT VARCHAR2(20) := 'BASE_CODE';
  cv_tkn_sls_stff     CONSTANT VARCHAR2(20) := 'SALES_STAFF';
  cv_tkn_bsnss_year   CONSTANT VARCHAR2(20) := 'BUSINESS_YEAR';
--
  cb_true             CONSTANT BOOLEAN := TRUE;
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1       CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2       CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3       CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4       CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5       CONSTANT VARCHAR2(200) := '<< 年度取得処理 >>';
  cv_debug_msg6       CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg7       CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg8       CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg9       CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg10      CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg11      CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg12      CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg13      CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  /* 2011.02.07 N.Horigome E_本稼動_02682 START */
  cv_debug_msg14      CONSTANT VARCHAR2(200) := '<< 前月年度取得処理 >>';
  cv_debug_msg15      CONSTANT VARCHAR2(200) := 'ln_business_pre_year = ';
  /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
  cv_debug_msg_fnm    CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls   CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn   CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1  CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2  CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1   CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2   CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3   CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4   CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5   CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6   CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
    company_cd   VARCHAR2(3),                               -- 会社コード
    fiscal_year  xxcso_dept_sales_staffs.fiscal_year%TYPE,  -- 年度
    year_month   xxcso_dept_sales_staffs.year_month%TYPE,   -- 年月
    base_code    xxcso_dept_sales_staffs.base_code%TYPE,    -- 拠点ＣＤ
    sales_staff  xxcso_dept_sales_staffs.sales_staff%TYPE,  -- 営業人員
    cprtn_date   DATE                                       -- 連携日時
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate  OUT DATE             -- システム日付
    ,ov_errbuf   OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode  OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg   OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf    VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- アプリケーション短縮名
    -- *** ローカル変数 ***
    lv_noprm_msg       VARCHAR2(4000);  -- コンカレント入力パラメータなしメッセージ格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08             --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
  EXCEPTION
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
   * Procedure Name   : get_param_year
   * Description      : データ抽出パラメータ(年度)取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_param_year(
     on_year             OUT NUMBER                  -- データ抽出パラメータ(年度)
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ,on_pre_year         OUT NUMBER                  -- データ抽出パラメータ（前月年度）
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_param_year';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
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
    ld_process_date  DATE;           -- 業務処理日付格納用
    ln_business_year NUMBER;         -- 現在年度格納用
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ln_business_pre_year NUMBER;     -- 先月年度格納
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
    lv_msg           VARCHAR2(4000); -- 取得データメッセージ出力用
  BEGIN
--
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- 年度取得処理 
    -- =====================
    ln_business_year := xxcso_util_common_pkg.get_business_year(
                          TO_CHAR(ld_process_date,'yyyymm')
                        );
    -- *** DEBUG_LOG ***
    -- 取得した年度をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 cv_debug_msg6 || ln_business_year || CHR(10) ||
                 ''
    );
--
    -- 年度取得に失敗した場合
    IF (ln_business_year IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    -- =====================
    -- 前月年度取得処理 
    -- =====================
    ln_business_pre_year := xxcso_util_common_pkg.get_business_year(
                              TO_CHAR(ADD_MONTHS(ld_process_date,-1),'yyyymm')
                            );
    -- *** DEBUG_LOG ***
    -- 取得した年度をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg14 || CHR(10) ||
                 cv_debug_msg15 || ln_business_pre_year || CHR(10) ||
                 ''
    );
--
    -- 年度取得に失敗した場合
    IF (ln_business_pre_year IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    
    -- 戻り値に取得した前月年度を設定
    on_pre_year := ln_business_pre_year;
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
--
    -- 戻り値に取得した年度を設定
    on_year := ln_business_year;
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
  END get_param_year;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得 (A-3)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd  OUT NOCOPY VARCHAR2  -- 会社コード（固定値001）
    ,ov_csv_dir     OUT NOCOPY VARCHAR2  -- CSVファイル出力先
    ,ov_csv_nm      OUT NOCOPY VARCHAR2  -- CSVファイル名
    ,ov_errbuf      OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf       VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- プロファイル名
    -- XXCSO:情報系連携用会社コード
    cv_prfnm_cmp_cd       CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:情報系連携用CSVファイル出力先
    cv_prfnm_csv_dir      CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:情報系連携用CSVファイル名(営業人員)
    cv_prfnm_csv_sls_pln  CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_SLSPER_NUM';
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値格納用
    lv_company_cd         VARCHAR2(2000);      -- 会社コード（固定値001）
    lv_csv_dir            VARCHAR2(2000);      -- CSVファイル出力先
    lv_csv_nm             VARCHAR2(2000);      -- CSVファイル名
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value          VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                VARCHAR2(4000);
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
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- 会社コード（固定値001）
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_sls_pln
                   ,val  => lv_csv_nm
                   ); -- CSVファイル名
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7  || CHR(10) ||
                 cv_debug_msg8  || lv_company_cd || CHR(10) ||
                 cv_debug_msg9  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg10 || lv_csv_nm     || CHR(10) ||
                 ''
    );
--
    -- 取得したCSVファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09      --メッセージコード
                ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                ,iv_token_value1 => lv_csv_nm             --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- 空行の挿入
    );
--
    -- プロファイル値取得に失敗した場合
    -- 会社コード取得失敗時
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSVファイル出力先取得失敗時
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSVファイル名取得失敗時
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_sls_pln;
    END IF;
--
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_03             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_company_cd     :=  lv_company_cd;       -- 会社コード（固定値001）
    ov_csv_dir        :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm         :=  lv_csv_nm;           -- CSVファイル名
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
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : 拠点別営業人員CSVファイルオープン (A-4)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir   IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm    IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf    OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode   OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg    OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf     VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_w            CONSTANT VARCHAR2(1) := 'w';
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
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_04             --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                    ,iv_token_value1 => iv_csv_dir                   --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード1
                    ,iv_token_value2 => iv_csv_nm                    --トークン値1
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
                         location   => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- ファイルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc       --トークンコード1
                      ,iv_token_value1 => iv_csv_dir           --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --トークンコード1
                      ,iv_token_value2 => iv_csv_nm            --トークン値1
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
   * Procedure Name   : create_csv_rec
   * Description      : 営業員別計画データCSV出力 (A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_xdss_data   IN  g_get_data_rtype    -- 拠点別営業人員抽出データ
    ,ov_errbuf      OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com       CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot     CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data          VARCHAR2(4000);  -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_xdss_data_rec  g_get_data_rtype; -- INパラメータ.営業員別計画抽出データ格納
    lv_company_cd    VARCHAR2(2000);   -- INパラメータ.会社コード格納
    ld_sysdate       DATE;             -- INパラメータ.システム日付格納
    -- *** ローカル例外 ***
    file_put_line_expt   EXCEPTION;    -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_xdss_data_rec := ir_xdss_data; -- 営業員別計画抽出データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot || l_xdss_data_rec.company_cd || cv_sep_wquot        -- 会社コード
        || cv_sep_com || l_xdss_data_rec.fiscal_year                               -- 年度
        || cv_sep_com || l_xdss_data_rec.year_month                                -- 年月
        || cv_sep_com ||
        cv_sep_wquot  || l_xdss_data_rec.base_code          || cv_sep_wquot        -- 拠点ＣＤ
        || cv_sep_com || l_xdss_data_rec.sales_staff                               -- 営業人員
        || cv_sep_com || TO_CHAR(l_xdss_data_rec.cprtn_date, 'yyyymmddhh24miss');  -- 連携日時
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_06             --メッセージコード
                      ,iv_token_name1  => cv_tkn_fiscl_year            --トークンコード1
                      ,iv_token_value1 => l_xdss_data_rec.fiscal_year  --トークン値1
                      ,iv_token_name2  => cv_tkn_ym                    --トークンコード2
                      ,iv_token_value2 => l_xdss_data_rec.year_month   --トークン値2
                      ,iv_token_name3  => cv_tkn_bs_cd                 --トークンコード3
                      ,iv_token_value3 => l_xdss_data_rec.base_code    --トークン値3
                      ,iv_token_name4  => cv_tkn_sls_stff              --トークンコード4
                      ,iv_token_value4 => l_xdss_data_rec.sales_staff  --トークン値4
                      ,iv_token_name5  => cv_tkn_errmsg                --トークンコード5
                      ,iv_token_value5 => SQLERRM                      --トークン値5
                     );
        lv_errbuf := lv_errmsg;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-7)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir  IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm   IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf   OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode  OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg   OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'close_csv_file';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf    VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
    -- *** DEBUG_LOG ***
    -- ファイルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg12   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_07             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード1
                      ,iv_token_value2 => iv_csv_nm                    --トークン値1
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
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
  PROCEDURE submain(
     ov_errbuf   OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode  OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf    VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    dflt_num        CONSTANT NUMBER(1)  := 0;
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    ld_sysdate      DATE;           -- システム日付
    ln_year         NUMBER;         -- データ抽出パラメータ(年度)
    lv_company_cd   VARCHAR2(2000); -- 会社コード（固定値001）
    lv_csv_dir      VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm       VARCHAR2(2000); -- CSVファイル名
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    ln_pre_year     NUMBER;         -- データ抽出パラメータ（前月年度）
    ln_end_year     NUMBER;         -- LOOP終了条件(現年度)
    /* 2011.02.07 N.Horigome E_本稼動_02682 END ´  */
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
    CURSOR xdss_data_cur
    IS
      SELECT  xdss.year_month   year_month   -- 年月
             ,xdss.base_code    base_code    -- 拠点ＣＤ
             ,xdss.fiscal_year  fiscal_year  -- 年度
             ,xdss.sales_staff  sales_staff  -- 営業人員
      FROM   xxcso_dept_sales_staffs  xdss   -- 拠点別営業人員テーブル
      WHERE  xdss.fiscal_year = TO_CHAR(ln_year);
--
    -- *** ローカル・レコード ***
    l_xdss_data_rec    xdss_data_cur%ROWTYPE;
    l_get_data_rec     g_get_data_rtype;
    -- *** ローカル例外 ***
    no_data_expt       EXCEPTION;
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
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       od_sysdate => ld_sysdate          -- システム日付
      ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.データ抽出パラメータ(年度)取得 
    -- ========================================
    get_param_year(
       on_year     => ln_year            -- データ抽出パラメータ(年度)
       /* 2011.02.07 N.Horigome E_本稼動_02682 START */
      ,on_pre_year => ln_pre_year        -- データ抽出パラメータ(前月年度)
       /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
      ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-3.プロファイル値取得 
    -- ========================================
    get_profile_info(
       ov_company_cd  => lv_company_cd  -- 会社コード（固定値001）
      ,ov_csv_dir     => lv_csv_dir     -- CSVファイル出力先
      ,ov_csv_nm      => lv_csv_nm      -- CSVファイル名
      ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- =================================================
    -- A-4.営業員別計画データCSVファイルオープン 
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-5.営業員別月別計画抽出 
    -- ========================================
    -- データ抽出パラメータ(年度)をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_10             --メッセージコード
                    ,iv_token_name1  => cv_tkn_bsnss_year            --トークンコード1
                    ,iv_token_value1 => TO_CHAR(ln_year)             --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                  -- 空行の挿入
    );
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    
    -- LOOP終了条件格納
    ln_end_year := ln_year;
--
    <<increment_year_loop>>
    FOR ln_loop_year IN ln_pre_year..ln_end_year LOOP
      -- データ取得条件格納
      ln_year := ln_loop_year;
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
--
      -- カーソルオープン
      OPEN xdss_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn || CHR(10) ||
                   ''
      );
--
      <<get_data_loop>>
      LOOP
        FETCH xdss_data_cur INTO l_xdss_data_rec;
        -- 処理対象件数格納
        gn_target_cnt := xdss_data_cur%ROWCOUNT;
--
        EXIT WHEN xdss_data_cur%NOTFOUND
        OR  xdss_data_cur%ROWCOUNT = 0;
        -- レコード変数初期化
        l_get_data_rec := NULL;
        -- 取得データを格納
        l_get_data_rec.company_cd   := lv_company_cd;                              -- 会社コード
        l_get_data_rec.fiscal_year  := l_xdss_data_rec.fiscal_year;                -- 年度
        l_get_data_rec.year_month   := l_xdss_data_rec.year_month;                 -- 年月
        l_get_data_rec.base_code    := l_xdss_data_rec.base_code;                  -- 拠点ＣＤ
        l_get_data_rec.sales_staff  := NVL(l_xdss_data_rec.sales_staff,dflt_num);  -- 営業人員(NULLの場合は0をセット)
        l_get_data_rec.cprtn_date   := ld_sysdate;                                 -- 連携日時
--
        -- ========================================
        -- A-6.営業員別計画データCSV出力 
        -- ========================================
        create_csv_rec(
          ir_xdss_data   =>  l_get_data_rec        -- 営業員別計画抽出データ
         ,ov_errbuf      =>  lv_errbuf             -- エラー・メッセージ
         ,ov_retcode     =>  lv_retcode            -- リターン・コード
         ,ov_errmsg      =>  lv_errmsg             -- ユーザー・エラー・メッセージ
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- 正常件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP get_data_loop;
--
      -- カーソルクローズ
      CLOSE xdss_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                   ''
      );
--
    /* 2011.02.07 N.Horigome E_本稼動_02682 START */
    END LOOP increment_year_loop;
    /* 2011.02.07 N.Horigome E_本稼動_02682 END   */
  /* 2009.07.21 Mio.Maruyama 0000783 対応 START */  
  --  -- 処理対象件数が0件の場合
  --  IF (gn_target_cnt = 0) THEN
  --    -- エラーメッセージ取得
  --    lv_errmsg := xxccp_common_pkg.get_msg(
  --                 iv_application  => cv_app_name                  --アプリケーション短縮名
  --                ,iv_name         => cv_tkn_number_11             --メッセージコード
  --               );
  --    lv_errbuf := lv_errmsg || SQLERRM;
  --    RAISE no_data_expt;
  --  END IF;
  /* 2009.07.21 Mio.Maruyama 0000783 対応 END */  
--
    -- ========================================
    -- CSVファイルクローズ (A-7) 
    -- ========================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
  /* 2009.07.21 Mio.Maruyama 0000783 対応 START */  
  --  -- *** 処理対象データ0件例外ハンドラ ***
  --  WHEN no_data_expt THEN
  --    -- エラー件数カウント
  --    gn_error_cnt := gn_error_cnt + 1;
--
  --    lb_fopn_retcd := UTL_FILE.IS_OPEN (
  --                       file =>gf_file_hand
  --                     );
  --    -- ファイルがクローズされていない場合
  --    IF (lb_fopn_retcd = cb_true) THEN
  --      -- ファイルクローズ
  --      UTL_FILE.FCLOSE(
  --        file =>gf_file_hand
  --      );
  --    -- *** DEBUG_LOG ***
  --    -- ファイルクローズしたことをログ出力
  --    fnd_file.put_line(
  --       which  => FND_FILE.LOG
  --      ,buff   => cv_debug_msg_fcls || CHR(10) ||
  --                 cv_prg_name       || cv_msg_part ||
  --                 cv_debug_msg_err5 || cv_msg_part ||
  --                 cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
  --                 ''
  --    );
  --    END IF;
--
  --    -- カーソルがクローズされていない場合
  --    IF (xdss_data_cur%ISOPEN) THEN
  --      -- カーソルクローズ
  --      CLOSE xdss_data_cur;
  --    -- *** DEBUG_LOG ***
  --    -- カーソルクローズしたことをログ出力
  --    fnd_file.put_line(
  --       which  => FND_FILE.LOG
  --      ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
  --                 cv_prg_name       || cv_msg_part ||
  --                 cv_debug_msg_err5 || CHR(10) ||
  --                 ''
  --    );
  --    END IF;
--
  --    ov_errmsg  := lv_errmsg;
  --    ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
  --    ov_retcode := cv_status_error;
  /* 2009.07.21 Mio.Maruyama 0000783 対応 END */  
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xdss_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xdss_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xdss_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xdss_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xdss_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xdss_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf      OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode     OUT NOCOPY VARCHAR2 )  --   リターン・コード    --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    lv_errbuf          VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-8.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg13 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg13 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg13 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A07C;
/
