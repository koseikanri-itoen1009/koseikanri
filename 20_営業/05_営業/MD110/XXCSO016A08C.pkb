CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO016A08C(bosy)
 * Description      : 減価償却額情報を物件別減価償却額情報テーブルに登録します。
 *
 * MD.050           : MD050_CSO_016_A08_物件別減価償却額更新
 *
 * Version          : 1.00
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  get_profile_info            プロファイル値取得 (A-2)
 *  delete_object_deprn_data    物件別減価償却額情報テーブル削除 (A-3)
 *  insert_object_deprn_data    物件別減価償却額情報登録 (A-4)
 *  create_csv_rec              物件別減価償却額情報CSV出力 (A-5)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018-10-31    1.0   Yazaki.Eiji        新規作成
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
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
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- 抽出対象なしエラー
  no_data_expt EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A08C';                   -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';                          -- アプリケーション短縮名
  cv_app_name_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP';                          -- アドオン：共通・IF領域
--
  -- 括り文字
  cv_dqu                     CONSTANT VARCHAR2(1)     := '"';                         -- 文字列括り
  cv_comma                   CONSTANT VARCHAR2(1)     := ',';                         -- カンマ
  -- リース区分
  cv_fin_lease_kbn           CONSTANT VARCHAR2(1)     := '1';                        -- リース区分：FINリース台帳
  cv_fixed_assets_lease_kbn  CONSTANT VARCHAR2(1)     := '4';                        -- リース区分：固定資産台帳
--
  -- ***情報抽出用
  cv_flag_y              CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n              CONSTANT VARCHAR2(1)  := 'N';
  ct_language            CONSTANT fnd_lookup_values.language%TYPE      := USERENV('LANG');
  ct_adj_type_expense    CONSTANT fa_adjustments.adjustment_type%TYPE  := 'EXPENSE'; -- 調整タイプ
--
  -- メッセージコード
  cv_msg_ccp_90008    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- コンカレント入力パラメータなしメッセージ
  cv_msg_cso_00014    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- プロファイル取得エラーメッセージ
  cv_msg_cso_00278    CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00278';     -- ロックエラーメッセージ
  cv_msg_cso_00072    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';     -- データ削除エラーメッセージ
  cv_msg_cso_00399    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00399';     -- 対象件数0件メッセージ
  cv_msg_cso_00886    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00886';     -- データ登録エラー
  cv_msg_cso_00016    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- データ抽出エラーメッセージ
  cv_msg_cso_00888    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00888';     -- 物件別減価償却額情報CSV出力ヘッダノート
  cv_msg_ccp_90000    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';     -- 対象件数メッセージ
  cv_msg_ccp_90001    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';     -- 成功件数メッセージ
  cv_msg_ccp_90002    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';     -- エラー件数メッセージ
  cv_msg_ccp_90004    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';     -- 正常終了メッセージ
  cv_msg_ccp_90005    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';     -- 警告終了メッセージ
  cv_msg_ccp_90006    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';     -- エラー終了全ロールバックメッセージ
--
  -- トークンコード
  cv_tkn_err_msg      CONSTANT VARCHAR2(20) := 'ERR_MSG';               -- SQLエラーメッセージ
  cv_tkn_err_msg2     CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';           -- SQLエラーメッセージ2
  cv_tkn_prof_name    CONSTANT VARCHAR2(20) := 'PROF_NAME';             -- プロファイル名
  cv_tkn_proc_name    CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';       -- 抽出処理名
  cv_tkn_table        CONSTANT VARCHAR2(20) := 'TABLE';                 -- テーブル名
  cv_tkn_count        CONSTANT VARCHAR2(20) := 'COUNT';                 -- 処理件数
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
--
  -- ***プロファイル
  cv_fin_lease_books          CONSTANT VARCHAR2(40) := 'XXCFF1_FIN_LEASE_BOOKS';     -- 台帳名_FINリース台帳
  cv_fixed_assets_books       CONSTANT VARCHAR2(40) := 'XXCFF1_FIXED_ASSETS_BOOKS';  -- 台帳名
  cv_prof_fin_lease_books     CONSTANT VARCHAR2(40) := 'XXCFF:台帳名_FINリース台帳'; -- プロファイル:FINリース台帳
  cv_prof_fixed_assets_books  CONSTANT VARCHAR2(40) := 'XXCFF:台帳名';               -- プロファイル:固定資産台帳
--
  cv_table_name       CONSTANT VARCHAR2(100) := '物件別減価償却額情報テーブル'; -- 物件別減価償却額情報テーブル
  cv_proc_name        CONSTANT VARCHAR2(100) := '物件別減価償却額情報';         -- 物件別減価償却額情報
--
  -- ***日付書式
  cv_yyyymm              CONSTANT VARCHAR2(7)  := 'YYYY-MM';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  -- ***バルクフェッチ用定義
  TYPE g_lease_kbn_ttype              IS TABLE OF XXCSO_object_deprn.lease_kbn%TYPE INDEX BY PLS_INTEGER;
  TYPE g_period_name_ttype            IS TABLE OF XXCSO_object_deprn.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype       IS TABLE OF XXCSO_object_deprn.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype            IS TABLE OF XXCSO_object_deprn.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype            IS TABLE OF XXCSO_object_deprn.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_machine_type_ttype           IS TABLE OF XXCSO_object_deprn.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype     IS TABLE OF XXCSO_object_deprn.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_number_ttype        IS TABLE OF XXCSO_object_deprn.contract_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype       IS TABLE OF XXCSO_object_deprn.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_num_ttype      IS TABLE OF XXCSO_object_deprn.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_id_ttype               IS TABLE OF XXCSO_object_deprn.asset_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_number_ttype           IS TABLE OF XXCSO_object_deprn.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_amount_ttype           IS TABLE OF XXCSO_object_deprn.deprn_amount%TYPE INDEX BY PLS_INTEGER;
--
  -- ***バルクフェッチ用定義 物件別減価償却額情報テーブル
  TYPE g_t_depreciation_id_ttype        IS TABLE OF XXCSO_object_deprn.depreciation_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_lease_kbn_ttype              IS TABLE OF XXCSO_object_deprn.lease_kbn%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_period_name_ttype            IS TABLE OF XXCSO_object_deprn.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_object_header_id_ttype       IS TABLE OF XXCSO_object_deprn.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_object_code_ttype            IS TABLE OF XXCSO_object_deprn.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_lease_class_ttype            IS TABLE OF XXCSO_object_deprn.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_machine_type_ttype           IS TABLE OF XXCSO_object_deprn.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_header_id_ttype     IS TABLE OF XXCSO_object_deprn.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_number_ttype        IS TABLE OF XXCSO_object_deprn.contract_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_line_id_ttype       IS TABLE OF XXCSO_object_deprn.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_line_num_ttype      IS TABLE OF XXCSO_object_deprn.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_asset_id_ttype               IS TABLE OF XXCSO_object_deprn.asset_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_asset_number_ttype           IS TABLE OF XXCSO_object_deprn.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_deprn_amount_ttype           IS TABLE OF XXCSO_object_deprn.deprn_amount%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_created_by_ttype             IS TABLE OF XXCSO_object_deprn.created_by%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_creation_date_ttype          IS TABLE OF XXCSO_object_deprn.creation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_updated_by_ttype        IS TABLE OF XXCSO_object_deprn.last_updated_by%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_update_date_ttype       IS TABLE OF XXCSO_object_deprn.last_update_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_update_login_ttype      IS TABLE OF XXCSO_object_deprn.last_update_login%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_request_id_ttype             IS TABLE OF XXCSO_object_deprn.request_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_appli_id_ttype       IS TABLE OF XXCSO_object_deprn.program_application_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_id_ttype             IS TABLE OF XXCSO_object_deprn.program_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_update_date_ttype    IS TABLE OF XXCSO_object_deprn.program_update_date%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_lease_kbn_tab               g_lease_kbn_ttype;
  g_period_name_tab             g_period_name_ttype;
  g_object_header_id_tab        g_object_header_id_ttype;
  g_object_code_tab             g_object_code_ttype;
  g_lease_class_tab             g_lease_class_ttype;
  g_machine_type_tab            g_machine_type_ttype;
  g_contract_header_id_tab      g_contract_header_id_ttype;
  g_contract_number_tab         g_contract_number_ttype;
  g_contract_line_id_tab        g_contract_line_id_ttype;
  g_contract_line_num_tab       g_contract_line_num_ttype;
  g_asset_id_tab                g_asset_id_ttype;
  g_asset_number_tab            g_asset_number_ttype;
  g_deprn_amount_tab            g_deprn_amount_ttype;
--
  -- ***バルクフェッチ用定義  物件別減価償却額情報テーブル
  g_t_depreciation_id_tab         g_t_depreciation_id_ttype;
  g_t_lease_kbn_tab               g_t_lease_kbn_ttype;
  g_t_period_name_tab             g_t_period_name_ttype;
  g_t_object_header_id_tab        g_t_object_header_id_ttype;
  g_t_object_code_tab             g_t_object_code_ttype;
  g_t_lease_class_tab             g_t_lease_class_ttype;
  g_t_machine_type_tab            g_t_machine_type_ttype;
  g_t_contract_header_id_tab      g_t_contract_header_id_ttype;
  g_t_contract_number_tab         g_t_contract_number_ttype;
  g_t_contract_line_id_tab        g_t_contract_line_id_ttype;
  g_t_contract_line_num_tab       g_t_contract_line_num_ttype;
  g_t_asset_id_tab                g_t_asset_id_ttype;
  g_t_asset_number_tab            g_t_asset_number_ttype;
  g_t_deprn_amount_tab            g_t_deprn_amount_ttype;
  g_t_created_by_tab              g_t_created_by_ttype;
  g_t_creation_date_tab           g_t_creation_date_ttype;
  g_t_last_updated_by_tab         g_t_last_updated_by_ttype;
  g_t_last_update_date_tab        g_t_last_update_date_ttype;
  g_t_last_update_login_tab       g_t_last_update_login_ttype;
  g_t_request_id_tab              g_t_request_id_ttype;
  g_t_program_application_id_tab  g_t_program_appli_id_ttype;
  g_t_program_id_tab              g_t_program_id_ttype;
  g_t_program_update_date_tab     g_t_program_update_date_ttype;
--
  -- プロファイル値
  gv_fin_lease_books           VARCHAR2(100);    -- FINリース台帳名
  gv_fixed_assets_books        VARCHAR2(100);    -- 固定資産台帳名
--
  -- 最新会計期間名
  gv_max_period_name           VARCHAR2(100);    -- 最新会計期間名
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : コレクション削除
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- プログラム名
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
    --コレクション結合配列の削除
    g_lease_kbn_tab.DELETE;           -- リース区分
    g_period_name_tab.DELETE;         -- 会計期間名
    g_object_header_id_tab.DELETE;    -- 物件内部ID
    g_object_code_tab.DELETE;         -- 物件コード
    g_lease_class_tab.DELETE;         -- リース種別
    g_machine_type_tab.DELETE;        -- 機器区分
    g_contract_header_id_tab.DELETE;  -- 契約内部ID
    g_contract_number_tab.DELETE;     -- 契約番号
    g_contract_line_id_tab.DELETE;    -- 契約明細内部ID
    g_contract_line_num_tab.DELETE;   -- 契約明細番号
    g_asset_id_tab.DELETE;            -- 資産ID
    g_asset_number_tab.DELETE;        -- 資産番号
    g_deprn_amount_tab.DELETE;        -- 減価償却額
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
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections_tbl
   * Description      : コレクション削除
   ***********************************************************************************/
  PROCEDURE delete_collections_tbl(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections_tbl'; -- プログラム名
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
    --コレクション結合配列の削除
    g_t_depreciation_id_tab.DELETE;        -- 減価償却額ID
    g_t_lease_kbn_tab.DELETE;              -- リース区分
    g_t_period_name_tab.DELETE;            -- 会計期間名
    g_t_object_header_id_tab.DELETE;       -- 物件内部ID
    g_t_object_code_tab.DELETE;            -- 物件コード
    g_t_lease_class_tab.DELETE;            -- リース種別
    g_t_machine_type_tab.DELETE;           -- 機器区分
    g_t_contract_header_id_tab.DELETE;     -- 契約内部ID
    g_t_contract_number_tab.DELETE;        -- 契約番号
    g_t_contract_line_id_tab.DELETE;       -- 契約明細内部ID
    g_t_contract_line_num_tab.DELETE;      -- 契約明細番号
    g_t_asset_id_tab.DELETE;               -- 資産ID
    g_t_asset_number_tab.DELETE;           -- 資産番号
    g_t_deprn_amount_tab.DELETE;           -- 減価償却額
    g_t_created_by_tab.DELETE;             -- 作成者
    g_t_creation_date_tab.DELETE;          -- 作成日
    g_t_last_updated_by_tab.DELETE;        -- 最終更新者
    g_t_last_update_date_tab.DELETE;       -- 最終更新日
    g_t_last_update_login_tab.DELETE;      -- 最終更新ログイン
    g_t_request_id_tab.DELETE;             -- 要求ID
    g_t_program_application_id_tab.DELETE; -- コンカレント・プログラム・アプリケーションID
    g_t_program_id_tab.DELETE;             -- コンカレント・プログラムID
    g_t_program_update_date_tab.DELETE;    -- プログラム更新日
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
  END delete_collections_tbl;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
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
    lv_sysdate           VARCHAR2(100);    -- システム日付
    lv_init_msg          VARCHAR2(5000);   -- エラーメッセージを格納
    lv_csv_header        VARCHAR2(5000);   -- CSVヘッダ項目出力用
--
    -- *** ローカル・カーソル ***
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
    -- システム日付取得
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- 取得したシステム日付をログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- 入力パラメータなしメッセージ出力
    lv_init_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_ccp       --アプリケーション短縮名
                      ,iv_name         => cv_msg_ccp_90008      --メッセージコード
                     );
    --メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_init_msg  || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- CSVヘッダ項目出力
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cso_00888    -- メッセージコード
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- プログラム名
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
    -- ===============================
    -- プロファイル値を取得
    -- ===============================
--
    -- 台帳名_FINリース台帳
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cso_00014             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name             -- トークンコード1
                    ,iv_token_value1 => cv_prof_fin_lease_books      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 台帳名
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cso_00014             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name             -- トークンコード1
                    ,iv_token_value1 => cv_prof_fixed_assets_books   -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : delete_object_deprn_data
   * Description      : 物件別減価償却額情報テーブル削除(A-3)
   ***********************************************************************************/
--
  PROCEDURE delete_object_deprn_data(
     ov_errbuf            OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_object_deprn_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode            VARCHAR2(1);         -- リターン・コード
    lv_errmsg             VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    --  ロック取得用
    CURSOR  lock_cur
    IS
      SELECT  xod.ROWID            lock_rowid      -- ロック用擬似列
      FROM    xxcso_object_deprn   xod             -- 物件別減価償却額情報テーブル
      WHERE   xod.period_name = gv_max_period_name -- 会計期間名
      FOR UPDATE NOWAIT;
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
  -- 最大会計期間取得
    SELECT  MAX(fdp.period_name)    max_period_name                           -- 最大会計期間
    INTO    gv_max_period_name                                                -- 会計期間名
    FROM    fa_deprn_periods        fdp                                       -- 減価償却期間
    WHERE   fdp.book_type_code IN(gv_fin_lease_books ,gv_fixed_assets_books)  -- 資産台帳コード
    AND     fdp.deprn_run  = cv_flag_y;                                       -- 減価償却実行フラグ
--
    --== 物件別減価償却額情報テーブルロック ==--
      --  ロック用カーソルオープン
      OPEN  lock_cur;
      --  ロック用カーソルクローズ
      CLOSE lock_cur;
--
    BEGIN
    -- 最大会計期間データ削除
      DELETE FROM
        xxcso_object_deprn  xod                          -- 物件別減価償却額情報テーブル
      WHERE   xod.period_name = gv_max_period_name;      -- 会計期間名
--
    EXCEPTION
      WHEN OTHERS THEN
      -- データ削除エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00072     -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table         -- トークンコード1
                     ,iv_token_value1 => cv_table_name        -- エラー発生のテーブル名
                     ,iv_token_name2  => cv_tkn_err_msg2      -- トークンコード2
                     ,iv_token_value2 => SQLERRM              -- トークン値2
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END;
---
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00278         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                     ,iv_token_value1 => cv_table_name            -- エラー発生のテーブル名
                     ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
                     ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
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
  END delete_object_deprn_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_object_deprn_data
   * Description      : 物件別減価償却額情報登録 (A-4)
   ***********************************************************************************/
  PROCEDURE insert_object_deprn_data(
    ov_errbuf         OUT    VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_deprn_data'; -- プログラム名
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
--
    -- *** ローカル定数 ***
  -- ***参照タイプ
    cv_xxcff1_lease_class_check  CONSTANT VARCHAR2(30)   := 'XXCFF1_LEASE_CLASS_CHECK'; -- リース種別チェック
    cv_xxcff1_asset_category_id  CONSTANT VARCHAR2(30)  := 'XXCFF1_ASSET_CATEGORY_ID';  -- 参照タイプ：自販機資産カテゴリ固定値
--
    cv_attribute9_1           CONSTANT VARCHAR2(1)    := '1';                        -- DFF9：1
    cv_attribute9_3           CONSTANT VARCHAR2(1)    := '3';                        -- DFF9：3
--
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 物件別減価償却データ抽出カーソル
    CURSOR gl_get_object_deprn_cur
    IS
      SELECT xod.lease_kbn             lease_kbn                  -- リース区分
            ,xod.period_name           period_name                -- 会計期間名
            ,xod.object_header_id      object_header_id           -- 物件内部ID
            ,xod.object_code           object_code                -- 物件コード
            ,xod.lease_class           lease_class                -- リース種別
            ,xod.machine_type          machine_type               -- 機器区分
            ,xod.contract_header_id    contract_header_id         -- 契約内部ID
            ,xod.contract_number       contract_number            -- 契約番号
            ,xod.contract_line_id      contract_line_id           -- 契約明細内部ID
            ,xod.contract_line_num     contract_line_num          -- 契約明細番号
            ,xod.asset_id              asset_id                   -- 資産ID
            ,xod.asset_number          asset_number               -- 資産番号
            ,SUM(xod.deprn_amount)     deprn_amount               -- 減価償却額
      FROM  (SELECT
                    /*+ 
                        LEADING(fdp fdd fab)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(obh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_N4)
                        INDEX(xch XXCFF_CONTRACT_HEADERS_PK)
                     */
                    cv_fin_lease_kbn          lease_kbn           -- リース区分
                   ,fdp.period_name           period_name         -- 会計期間名
                   ,obh.object_header_id      object_header_id    -- 物件内部ID
                   ,obh.object_code           object_code         -- 物件コード
                   ,obh.lease_class           lease_class         -- リース種別
                   ,NULL                      machine_type        -- 機器区分
                   ,xch.contract_header_id    contract_header_id  -- 契約内部ID
                   ,xch.contract_number       contract_number     -- 契約番号
                   ,xcl.contract_line_id      contract_line_id    -- 契約明細内部ID
                   ,xcl.contract_line_num     contract_line_num   -- 契約明細番号
                   ,fab.asset_id              asset_id            -- 資産ID
                   ,fab.asset_number          asset_number        -- 資産番号
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount  deprn_amount    -- 減価償却額
             FROM
                   fa_deprn_detail            fdd       -- 減価償却詳細情報
                  ,fa_additions_b             fab       -- 資産詳細情報
                  ,fa_deprn_periods           fdp       -- 減価償却期間
                  ,gl_code_combinations       gcc       -- 勘定科目組合せマスタ
                  ,xxcff_object_headers       obh       -- リース物件
                  ,xxcff_contract_headers     xch       -- リース契約ヘッダ
                  ,xxcff_contract_lines       xcl       -- リース契約明細
             WHERE    fab.asset_id                                  = fdd.asset_id                    -- 物件内部ID
             AND      fdp.book_type_code                            = gv_fin_lease_books              -- 資産台帳コード
             AND      fdp.book_type_code                            = fdd.book_type_code              -- 資産台帳コード
             AND      fdp.period_counter                            = fdd.period_counter              -- 会計期間
             AND      fdd.deprn_expense_je_line_num                 IS NOT NULL                       -- 減価償却支払詳細番号
             AND      fdd.deprn_expense_ccid                        = gcc.code_combination_id         -- ＣＣＩＤ
             AND      gv_max_period_name                            = fdp.period_name                 -- 最新会計期間
             AND      xcl.object_header_id                          = obh.object_header_id            -- 物件ID
             AND      TO_NUMBER(fab.attribute10)                    = xcl.contract_line_id            -- 契約明細内部ID
             AND      xcl.contract_header_id                        = xch.contract_header_id          -- 契約内部ID
             AND      (obh.lease_class ,gcc.segment3 ,gcc.segment4) IN (SELECT
                                                                               /*+ 
                                                                                   LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                                                                   INDEX(flv FND_LOOKUP_VALUES_U2)
                                                                                   INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                                                                   INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                                                                   INDEX(xlcv.ffvs FND_FLEX_VALUE_SETS_U2)
                                                                                */
                                                                               xlcv.lease_class_code  lease_class_code -- リース種別コード
                                                                              ,xlcv.deprn_acct        deprn_acct       -- 振替元勘定科目
                                                                              ,xlcv.deprn_sub_acct    deprn_sub_acct   -- 振替元補助科目
                                                                        FROM   xxcff_lease_class_v   xlcv  -- リース種別ビュー
                                                                              ,fnd_lookup_values     flv   -- リース種別チェック
                                                                        WHERE  flv.lookup_code                              = xlcv.lease_class_code
                                                                        AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                                                                        AND    flv.attribute1                               = cv_flag_y
                                                                        AND    flv.language                                 = ct_language
                                                                        AND    flv.enabled_flag                             = cv_flag_y
                                                                        AND    LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                                                                                AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       )
             UNION ALL
             SELECT
                    /*+ 
                        LEADING(b)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(obh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                        INDEX(xch XXCFF_CONTRACT_HEADERS_PK)
                     */
                    cv_fin_lease_kbn          lease_kbn           -- リース区分
                   ,fdp.period_name           period_name         -- 会計期間名
                   ,obh.object_header_id      object_header_id    -- 物件内部ID
                   ,obh.object_code           object_code         -- 物件コード
                   ,obh.lease_class           lease_class         -- リース種別
                   ,NULL                      machine_type        -- 機器区分
                   ,xch.contract_header_id    contract_header_id  -- 契約内部ID
                   ,xch.contract_number       contract_number     -- 契約番号
                   ,xcl.contract_line_id      contract_line_id    -- 契約明細内部ID
                   ,xcl.contract_line_num     contract_line_num   -- 契約明細番号
                   ,fab.asset_id              asset_id            -- 資産ID
                   ,fab.asset_number          asset_number        -- 資産番号
                   ,faj.adjustment_amount     deprn_amount        -- 減価償却額
             FROM
                   fa_adjustments             faj       -- 資産調整情報
                  ,fa_additions_b             fab       -- 資産詳細情報
                  ,fa_deprn_periods           fdp       -- 減価償却期間
                  ,gl_code_combinations       gcc       -- 勘定科目組合せマスタ
                  ,xxcff_object_headers       obh       -- リース物件
                  ,(SELECT
                           /*+ 
                               QB_NAME(b)
                               LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                               INDEX(flv FND_LOOKUP_VALUES_U2)
                               INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                               INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                               INDEX(xlcv.ffvs FND_FLEX_VALUE_SETS_U2)
                            */
                           xlcv.lease_class_code  lease_class_code -- リース種別コード
                          ,xlcv.deprn_acct        deprn_acct       -- 振替元勘定科目
                          ,xlcv.deprn_sub_acct    deprn_sub_acct   -- 振替元補助科目
                    FROM   xxcff_lease_class_v   xlcv  -- リース種別ビュー
                          ,fnd_lookup_values     flv   -- リース種別チェック
                    WHERE  flv.lookup_code                              = xlcv.lease_class_code
                    AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                    AND    flv.attribute1                               = cv_flag_y
                    AND    flv.language                                 = ct_language
                    AND    flv.enabled_flag                             = cv_flag_y
                    AND    LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                            AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                   )                          xlcv2
                  ,xxcff_contract_headers     xch       -- リース契約ヘッダ
                  ,xxcff_contract_lines       xcl       -- リース契約明細
             WHERE    fab.asset_id                  = faj.asset_id                    -- 物件内部ID
             AND      fdp.book_type_code            = gv_fin_lease_books              -- 資産台帳コード
             AND      fdp.book_type_code            = faj.book_type_code              -- 資産台帳コード
             AND      fdp.period_counter            = faj.period_counter_created      -- 会計期間
             AND      faj.adjustment_type           = ct_adj_type_expense             -- 調整タイプ：EXPENSE
             AND      faj.code_combination_id      = gcc.code_combination_id          -- ＣＣＩＤ
             AND      gcc.segment3                  = xlcv2.deprn_acct                -- 振替元勘定科目
             AND      gcc.segment4                  = xlcv2.deprn_sub_acct            -- 振替元補助勘定科目
             AND      gv_max_period_name            = fdp.period_name                 -- 最新会計期間
             AND      xcl.object_header_id          = obh.object_header_id            -- 物件ID
             AND      TO_NUMBER(fab.attribute10)    = xcl.contract_line_id            -- 契約明細内部ID
             AND      xcl.contract_header_id        = xch.contract_header_id          -- 契約内部ID
             AND      obh.lease_class               = xlcv2.lease_class_code          -- リース種別
             UNION ALL
             SELECT
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    cv_fixed_assets_lease_kbn lease_kbn           -- リース区分
                   ,fdp.period_name           period_name         -- 会計期間名
                   ,xvoh.object_header_id     object_header_id    -- 物件内部ID
                   ,xvoh.object_code          object_code         -- 物件コード
                   ,xvoh.lease_class          lease_class         -- リース種別
                   ,xvoh.machine_type         machine_type        -- 機器区分
                   ,NULL                      contract_header_id  -- 契約内部ID
                   ,NULL                      contract_number     -- 契約番号
                   ,NULL                      contract_line_id    -- 契約明細内部ID
                   ,NULL                      contract_line_num   -- 契約明細番号
                   ,fab.asset_id              asset_id            -- 資産ID
                   ,fab.asset_number          asset_number        -- 資産番号
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount  deprn_amount    -- 減価償却額
             FROM
                   fa_deprn_detail            fdd       -- 減価償却詳細情報
                  ,fa_additions_b             fab       -- 資産詳細情報
                  ,fa_deprn_periods           fdp       -- 減価償却期間
                  ,gl_code_combinations       gcc       -- 勘定科目組合せマスタ
                  ,xxcff_vd_object_headers    xvoh      -- 自販機物件
                  ,fnd_lookup_values          flv       -- 自販機資産カテゴリ固定値
             WHERE    fab.asset_id                  = fdd.asset_id                    -- 物件内部ID
             AND      fdp.book_type_code            = gv_fixed_assets_books           -- 資産台帳コード
             AND      fdp.book_type_code            = fdd.book_type_code              -- 台帳台帳コード
             AND      fdp.period_counter            = fdd.period_counter              -- 会計期間
             AND      fdd.deprn_expense_je_line_num IS NOT NULL                       -- 減価償却支払詳細番号
             AND      fdd.deprn_expense_ccid        = gcc.code_combination_id         -- ＣＣＩＤ
             AND      gcc.segment3                  = flv.attribute4                  -- 振替元勘定科目
             AND      gcc.segment4                  = flv.attribute8                  -- 振替元補助勘定科目
             AND      gv_max_period_name            = fdp.period_name                 -- 最新会計期間
             AND      fab.tag_number                = xvoh.object_code                -- 物件コード
             AND      xvoh.machine_type             = flv.lookup_code                 -- 自販機資産カテゴリ固定値
             AND      flv.lookup_type               = cv_xxcff1_asset_category_id
             AND      flv.attribute9                IN (cv_attribute9_1 ,cv_attribute9_3)
             AND      flv.language                  = ct_language
             AND      flv.enabled_flag              = cv_flag_y
             AND      LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
             UNION ALL
             SELECT
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    cv_fixed_assets_lease_kbn lease_kbn           -- リース区分
                   ,fdp.period_name           period_name         -- 会計期間名
                   ,xvoh.object_header_id     object_header_id    -- 物件内部ID
                   ,xvoh.object_code          object_code         -- 物件コード
                   ,xvoh.lease_class          lease_class         -- リース種別
                   ,xvoh.machine_type         machine_type        -- 機器区分
                   ,NULL                      contract_header_id  -- 契約内部ID
                   ,NULL                      contract_number     -- 契約番号
                   ,NULL                      contract_line_id    -- 契約明細内部ID
                   ,NULL                      contract_line_num   -- 契約明細番号
                   ,fab.asset_id              asset_id            -- 資産ID
                   ,fab.asset_number          asset_number        -- 資産番号
                   ,faj.adjustment_amount     deprn_amount        -- 減価償却額
             FROM
                   fa_adjustments             faj       -- 資産調整情報
                  ,fa_additions_b             fab       -- 資産詳細情報
                  ,fa_deprn_periods           fdp       -- 減価償却期間
                  ,gl_code_combinations       gcc       -- 勘定科目組合せマスタ
                  ,xxcff_vd_object_headers    xvoh      -- 自販機物件
                  ,fnd_lookup_values          flv       -- 自販機資産カテゴリ固定値
             WHERE    fab.asset_id                  = faj.asset_id                    -- 物件内部ID
             AND      fdp.book_type_code            = gv_fixed_assets_books           -- 資産台帳コード
             AND      fdp.book_type_code            = faj.book_type_code              -- 台帳台帳コード
             AND      fdp.period_counter            = faj.period_counter_created      -- 会計期間
             AND      faj.adjustment_type           = ct_adj_type_expense             -- 調整タイプ
             AND      gv_max_period_name            = fdp.period_name                 -- 最新会計期間
             AND      fab.tag_number                = xvoh.object_code                -- 物件コード
             AND      faj.code_combination_id      = gcc.code_combination_id          -- ＣＣＩＤ
             AND      gcc.segment3                  = flv.attribute4                  -- 振替元勘定科目
             AND      gcc.segment4                  = flv.attribute8                  -- 振替元補助勘定科目
             AND      xvoh.machine_type             = flv.lookup_code                --  自販機資産カテゴリ固定値
             AND      flv.lookup_type               = cv_xxcff1_asset_category_id
             AND      flv.attribute9                IN (cv_attribute9_1 ,cv_attribute9_3)
             AND      flv.language                  = ct_language
             AND      flv.enabled_flag              = cv_flag_y
             AND      LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
             ) xod
      GROUP BY xod.lease_kbn
              ,xod.period_name
              ,xod.object_header_id
              ,xod.object_code
              ,xod.lease_class
              ,xod.machine_type
              ,xod.contract_header_id
              ,xod.contract_number
              ,xod.contract_line_id
              ,xod.contract_line_num
              ,xod.asset_id
              ,xod.asset_number
--
      ;
    g_gl_get_object_deprn_rec  gl_get_object_deprn_cur%ROWTYPE;
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
    -- ***************************************
--
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 減価償却額データの取得
    OPEN  gl_get_object_deprn_cur;
    FETCH gl_get_object_deprn_cur
    BULK COLLECT INTO
                      g_lease_kbn_tab            -- リース区分
                     ,g_period_name_tab          -- 会計期間名
                     ,g_object_header_id_tab     -- 物件内部ID
                     ,g_object_code_tab          -- 物件コード
                     ,g_lease_class_tab          -- リース種別
                     ,g_machine_type_tab         -- 機器区分
                     ,g_contract_header_id_tab   -- 契約内部ID
                     ,g_contract_number_tab      -- 契約番号
                     ,g_contract_line_id_tab     -- 契約明細内部ID
                     ,g_contract_line_num_tab    -- 契約明細番号
                     ,g_asset_id_tab             -- 資産ID
                     ,g_asset_number_tab         -- 資産番号
                     ,g_deprn_amount_tab         -- 減価償却額
                     ;
    --対象件数カウント
    gn_target_cnt := g_lease_kbn_tab.COUNT;
    CLOSE gl_get_object_deprn_cur;
--
    BEGIN
      -- 取得した件数が0件の場合
      IF ( gn_target_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_app_name      -- アプリケーション短縮名
                      ,iv_name          => cv_msg_cso_00399 -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      -- 取得した件数が1件以上の場合
      ELSE
        <<gl_get_object_deprn_loop>>
        FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
--
          -- 物件別減価償却額情報テーブルへ登録
          INSERT INTO xxcso_object_deprn(
             depreciation_id             -- 減価償却額ID
            ,lease_kbn                  -- リース区分
            ,period_name                -- 会計期間名
            ,object_header_id           -- 物件内部ID
            ,object_code                -- 物件コード
            ,lease_class                -- リース種別
            ,machine_type               -- 機器区分
            ,contract_header_id         -- 契約内部ID
            ,contract_number            -- 契約番号
            ,contract_line_id           -- 契約明細内部ID
            ,contract_line_num          -- 契約明細番号
            ,asset_id                   -- 資産ID
            ,asset_number               -- 資産番号
            ,deprn_amount               -- 減価償却額
            ,created_by                 -- 作成者
            ,creation_date              -- 作成日
            ,last_updated_by            -- 最終更新者
            ,last_update_date           -- 最終更新日
            ,last_update_login          -- 最終更新ログイン
            ,request_id                 -- 要求ID
            ,program_application_id     -- コンカレント・プログラム・アプリケーションID
            ,program_id                 -- コンカレント・プログラムID
            ,program_update_date        -- プログラム更新日
          ) VALUES (
             xxcso_object_deprn_s01.nextval               -- 減価償却額ID
            ,g_lease_kbn_tab(ln_loop_cnt)                 -- リース区分会計
            ,g_period_name_tab(ln_loop_cnt)               -- 会計期間名仕訳
            ,g_object_header_id_tab(ln_loop_cnt)          -- 物件内部ID
            ,g_object_code_tab(ln_loop_cnt)               -- 物件コード
            ,g_lease_class_tab(ln_loop_cnt)               -- リース種別
            ,g_machine_type_tab(ln_loop_cnt)              -- 機器区分
            ,g_contract_header_id_tab(ln_loop_cnt)        -- 契約内部ID
            ,g_contract_number_tab(ln_loop_cnt)           -- 契約番号
            ,g_contract_line_id_tab(ln_loop_cnt)          -- 契約明細内部ID
            ,g_contract_line_num_tab(ln_loop_cnt)         -- 契約明細番号
            ,g_asset_id_tab(ln_loop_cnt)                  -- 資産ID
            ,g_asset_number_tab(ln_loop_cnt)              -- 資産番号
            ,g_deprn_amount_tab(ln_loop_cnt)              -- 減価償却額
            ,cn_created_by                                -- 作成者
            ,cd_creation_date                             -- 作成日
            ,cn_last_updated_by                           -- 最終更新者
            ,cd_last_update_date                          -- 最終更新日
            ,cn_last_update_login                         -- 最終更新ログイン
            ,cn_request_id                                -- 要求ID
            ,cn_program_application_id                    -- コンカレント・プログラム・アプリケーション
            ,cn_program_id                                -- コンカレント・プログラムID
            ,cd_program_update_date                       -- プログラム更新日
          );
--
        END LOOP gl_get_object_deprn_loop;
--
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name             --アプリケーション短縮名
               ,iv_name         => cv_msg_cso_00886        --メッセージコード
               ,iv_token_name1  => cv_tkn_table            --トークンコード1
               ,iv_token_value1 => cv_table_name           --トークン値1
               ,iv_token_name2  => cv_tkn_err_msg2         --トークンコード2
               ,iv_token_value2 => SQLERRM                 --トークン値2
              );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END;
--
  EXCEPTION
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
  END insert_object_deprn_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 物件別減価償却額情報CSV出力 (A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_op_str                                 VARCHAR2(5000)  := NULL; -- 出力文字列格納用変数
--
    -- *** ローカル・カーソル ***
    CURSOR gl_get_object_deprn_tbl_cur
    IS
      SELECT xod.depreciation_id           depreciation_id           -- 減価償却額ID
            ,xod.lease_kbn                 lease_kbn                 -- リース区分
            ,xod.period_name               period_name               -- 会計期間名
            ,xod.object_header_id          object_header_id          -- 物件内部ID
            ,xod.object_code               object_code               -- 物件コード
            ,xod.lease_class               lease_class               -- リース種別
            ,xod.machine_type              machine_type              -- 機器区分
            ,xod.contract_header_id        contract_header_id        -- 契約内部ID
            ,xod.contract_number           contract_number           -- 契約番号
            ,xod.contract_line_id          contract_line_id          -- 契約明細内部ID
            ,xod.contract_line_num         contract_line_num         -- 契約明細番号
            ,xod.asset_id                  asset_id                  -- 資産ID
            ,xod.asset_number              asset_number              -- 資産番号
            ,xod.deprn_amount              deprn_amount              -- 減価償却額
            ,xod.created_by                created_by                -- 作成者
            ,xod.creation_date             creation_date             -- 作成日
            ,xod.last_updated_by           last_updated_by           -- 最終更新者
            ,xod.last_update_date          last_update_date          -- 最終更新日
            ,xod.last_update_login         last_update_login         -- 最終更新ログイン
            ,xod.request_id                request_id                -- 要求ID
            ,xod.program_application_id    program_application_id    -- コンカレント・プログラム・アプリケーションID
            ,xod.program_id                program_id                -- コンカレント・プログラムID
            ,xod.program_update_date       program_update_date       -- プログラム更新日
      FROM   xxcso_object_deprn   xod                                -- 物件別減価償却額情報テーブル
      WHERE  xod.period_name = gv_max_period_name                    -- 最新会計期間
      ORDER BY xod.lease_kbn
              ,xod.lease_class
              ,xod.object_code
      ;
    g_gl_get_object_deprn_tbl_rec  gl_get_object_deprn_tbl_cur%ROWTYPE;
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
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections_tbl(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ================================================
    -- 物件別減価償却額情報テーブルのデータ取得(A-5-1)
    -- ================================================
--
    BEGIN
      OPEN  gl_get_object_deprn_tbl_cur;
      FETCH gl_get_object_deprn_tbl_cur
      BULK COLLECT INTO
                       g_t_depreciation_id_tab           -- 減価償却額ID
                      ,g_t_lease_kbn_tab                 -- リース区分
                      ,g_t_period_name_tab               -- 会計期間名
                      ,g_t_object_header_id_tab          -- 物件内部ID
                      ,g_t_object_code_tab               -- 物件コード
                      ,g_t_lease_class_tab               -- リース種別
                      ,g_t_machine_type_tab              -- 機器区分
                      ,g_t_contract_header_id_tab        -- 契約内部ID
                      ,g_t_contract_number_tab           -- 契約番号
                      ,g_t_contract_line_id_tab          -- 契約明細内部ID
                      ,g_t_contract_line_num_tab         -- 契約明細番号
                      ,g_t_asset_id_tab                  -- 資産ID
                      ,g_t_asset_number_tab              -- 資産番号
                      ,g_t_deprn_amount_tab              -- 減価償却額
                      ,g_t_created_by_tab                -- 作成者
                      ,g_t_creation_date_tab             -- 作成日
                      ,g_t_last_updated_by_tab           -- 最終更新者
                      ,g_t_last_update_date_tab          -- 最終更新日
                      ,g_t_last_update_login_tab         -- 最終更新ログイン
                      ,g_t_request_id_tab                -- 要求ID
                      ,g_t_program_application_id_tab    -- コンカレント・プログラム・アプリケーションID
                      ,g_t_program_id_tab                -- コンカレント・プログラムID
                      ,g_t_program_update_date_tab       -- プログラム更新日
                      ;
      CLOSE gl_get_object_deprn_tbl_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
      --物件別減価償却額情報テーブル抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name               -- アプリケーション短縮名
                            ,iv_name         => cv_msg_cso_00016          -- メッセージコード
                            ,iv_token_name1  => cv_tkn_proc_name          -- トークンコード1
                            ,iv_token_value1 => cv_proc_name              -- トークン値1
                            ,iv_token_name2  => cv_tkn_err_msg2           -- トークンコード2
                            ,iv_token_value2 => SQLERRM                   -- トークン値2
                );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;--
    END;
  -- 取得した件数が1件以上の場合
    <<gl_get_object_deprn_tbl_loop>>
    FOR g_gl_get_object_deprn_tbl_rec IN gl_get_object_deprn_tbl_cur
    LOOP
    -- ===============================
    -- CSVファイル出力(A-5-2)
    -- ===============================
--
      --出力文字列作成
      lv_op_str :=                          cv_dqu || g_gl_get_object_deprn_tbl_rec.depreciation_id         || cv_dqu ;   -- 減価償却額ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.lease_kbn               || cv_dqu ;   -- リース区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.period_name             || cv_dqu ;   -- 会計期間名
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.object_header_id        || cv_dqu ;   -- 物件内部ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.object_code             || cv_dqu ;   -- 物件コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.lease_class             || cv_dqu ;   -- リース種別
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.machine_type            || cv_dqu ;   -- 機器区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_header_id      || cv_dqu ;   -- 契約内部ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_number         || cv_dqu ;   -- 契約番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_line_id        || cv_dqu ;   -- 契約明細内部ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_line_num       || cv_dqu ;   -- 契約明細番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.asset_id                || cv_dqu ;   -- 資産ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.asset_number            || cv_dqu ;   -- 資産番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.deprn_amount            || cv_dqu ;   -- 減価償却額
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.created_by              || cv_dqu ;   -- 作成者
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.creation_date           || cv_dqu ;   -- 作成日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_updated_by         || cv_dqu ;   -- 最終更新者
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_update_date        || cv_dqu ;   -- 最終更新日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_update_login       || cv_dqu ;   -- 最終更新ログイン
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.request_id              || cv_dqu ;   -- 要求ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_application_id  || cv_dqu ;   -- コンカレント・プログラム・アプリケーションID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_id              || cv_dqu ;   -- コンカレント・プログラムID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_update_date     || cv_dqu ;   -- プログラム更新日
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP gl_get_object_deprn_tbl_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT NOCOPY VARCHAR2,      -- エラー・メッセージ            --# 固定 #
     ov_retcode       OUT NOCOPY VARCHAR2,      -- リターン・コード              --# 固定 #
     ov_errmsg        OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理
    -- ================================
    init(
      ov_errbuf           => lv_errbuf,        -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,       -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.プロファイル値取得
    -- =================================================
    get_profile_info(
       ov_errbuf      => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
       ov_retcode     => lv_retcode,     -- リターン・コード              --# 固定 #
       ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.物件別減価償却額情報テーブル削除
    -- =================================================
--
    delete_object_deprn_data(
       ov_errbuf    => lv_errbuf,    -- エラー・メッセージ            --# 固定 #
       ov_retcode   => lv_retcode,   -- リターン・コード              --# 固定 #
       ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.物件別減価償却額情報登録
    -- =================================================
--
    insert_object_deprn_data(
       ov_errbuf    => lv_errbuf,     -- エラー・メッセージ            --# 固定 #
       ov_retcode   => lv_retcode,    -- リターン・コード              --# 固定 #
       ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data_expt;
    END IF;
--
    -- =================================================
    -- A-5.物件別減価償却額情報CSV出力
    -- =================================================
--
    create_csv_rec(
       ov_errbuf    => lv_errbuf,      -- エラー・メッセージ            --# 固定 #
       ov_retcode   => lv_retcode,    -- リターン・コード              --# 固定 #
       ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 抽出対象なし例外(警告）ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
     errbuf              OUT NOCOPY VARCHAR2,     -- エラー・メッセージ  --# 固定 #
     retcode             OUT NOCOPY VARCHAR2      -- リターン・コード    --# 固定 #
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
    IF lv_retcode IN (cv_status_error ,cv_status_warn)  THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                   --エラーメッセージ
      );
    END IF;
--
    -- =======================
    -- A-8.終了処理
    -- =======================
    --空行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --===============================================================
    -- エラー時の出力件数設定
    --===============================================================
    IF (lv_retcode = cv_status_error) THEN
      -- 成功件数をゼロにクリアする
      gn_normal_cnt      := 0;
      -- エラー件数に1を設定する
      gn_error_cnt       := 1;
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
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
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A08C;
/
