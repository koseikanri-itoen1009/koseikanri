CREATE OR REPLACE PACKAGE BODY XXCFF017A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A03C(body)
 * Description      : 自販機情報FA連携処理リース(FA)
 * MD.050           : MD050_CFF_017_A03_自販機情報FA連携処理
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          初期処理                                  (A-1)
 *  get_profile_values            プロファイル値取得                        (A-2)
 *  get_period                    会計期間チェック                          (A-3)
 *  get_vd_object_add_data        自販機物件（未確定）登録データ抽出        (A-4)
 *  get_vd_object_trnsf_data      自販機物件（移動）登録データ抽出          (A-5)
 *  get_vd_object_modify_data     自販機物件（修正）登録データ抽出          (A-6)
 *  get_vd_object_ritire_data     自販機物件（除売却未確定）登録データ抽出  (A-7)
 *  get_deprn_ccid                減価償却費勘定CCID取得                    (A-8-1)
 *  update_vd_object_headers      自販機物件管理の更新                      (A-8-2)
 *  update_vd_object_histories    自販機物件履歴の更新                      (A-8-3)
 *  insert_vd_object_histories    自販機物件履歴の作成                      (A-8-4)
 *  chk_object_trnsf_data         移動詳細情報変更チェック                  (A-8-5)
 *  submain                       メイン処理プロシージャ
 *  main                          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/08/01    1.0   SCSK小路         新規作成
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
  cv_msg_part                 CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3) := '.';
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
  --*** 会計期間名チェックエラー
  chk_period_name_expt      EXCEPTION;
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロック(ビジー)エラー
  lock_expt              EXCEPTION;
  chk_no_data_found_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A03C'; -- パッケージ名
  cd_processing_date          CONSTANT DATE          := SYSDATE;        -- 処理日
  cd_fa_if_date               CONSTANT DATE          := SYSDATE;        -- FA情報連携日
  cd_od_sysdate               CONSTANT DATE          := SYSDATE;        -- システム日付
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_017a03_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_017a03_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- 会計期間チェックエラー  
  cv_msg_017a03_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ロックエラー
  cv_msg_017a03_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00101'; -- 取得エラー
  cv_msg_017a03_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00214'; -- 自販機物件（未確定）作成メッセージ
  cv_msg_017a03_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00215'; -- 自販機物件（移動）作成メッセージ
  cv_msg_017a03_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00216'; -- 自販機物件（修正）作成メッセージ
  cv_msg_017a03_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00217'; -- 自販機物件（除売却未確定）作成メッセージ
  cv_msg_017a03_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無しメッセージ
  cv_msg_017a03_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- 参照タイプ取得エラー
  cv_msg_017a03_m_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00225'; -- 自販機物件FA連携エラー
  cv_msg_017a03_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00228'; -- 自販機物件FA連携項目存在チェックエラー
  cv_msg_017a03_m_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00229'; -- 自販機物件FA連携項目日付チェックエラー
  cv_msg_017a03_m_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00235'; -- 自販機物件（移動）変更項目なし警告
  cv_msg_017a03_m_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00236'; -- 最新会計期間名取得警告
--
  -- ***メッセージ名(トークン)
  cv_msg_017a03_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; -- XXCFF:会社コード_本社
  cv_msg_017a03_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; -- XXCFF:部門コード_調整部門
  cv_msg_017a03_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_msg_017a03_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50231'; -- 自販機物件（未確定）情報
  cv_msg_017a03_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50260'; -- 自販機物件管理
  cv_msg_017a03_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50230'; -- 減価償却期間
  cv_msg_017a03_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50232'; -- 自販機物件（移動）情報
  cv_msg_017a03_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50235'; -- 固定資産（移動）情報
  cv_msg_017a03_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50238'; -- カレンダ期間クローズ日
  cv_msg_017a03_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50233'; -- 自販機物件（修正）情報
  cv_msg_017a03_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50236'; -- 固定資産（修正）情報
  cv_msg_017a03_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50234'; -- 自販機物件（除売却）情報
  cv_msg_017a03_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50237'; -- 固定資産（除売却）情報
  cv_msg_017a03_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50256'; -- 資産詳細情報
  cv_msg_017a03_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50257'; -- 自販機資産カテゴリ固定値
  cv_msg_017a03_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50261'; -- メーカー名 機種 年式
  cv_msg_017a03_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50240'; -- 機器区分
  cv_msg_017a03_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50262'; -- 事業供用日
  cv_msg_017a03_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50263'; -- 取得価格
  cv_msg_017a03_t_029 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50181'; -- 数量
  cv_msg_017a03_t_030 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50264'; -- 移動日
  cv_msg_017a03_t_031 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50246'; -- 申告地
  cv_msg_017a03_t_032 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50243'; -- 管理部門
  cv_msg_017a03_t_033 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50265'; -- 事業所
  cv_msg_017a03_t_034 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50266'; -- 設置場所
  cv_msg_017a03_t_035 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50267'; -- 本社/工場区分
  cv_msg_017a03_t_036 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50272'; -- 除・売却日
  cv_msg_017a03_t_037 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; -- XXCFF: 按分方法_月末
--
  -- ***トークン名
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type     CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period      CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_info        CONSTANT VARCHAR2(20) := 'INFO';
  cv_tkn_get_data    CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_lookup_type CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';
  cv_tkn_param_val1  CONSTANT VARCHAR2(20) := 'PARAM_VAL1';
  cv_tkn_param_val2  CONSTANT VARCHAR2(20) := 'PARAM_VAL2';
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';
--
  -- ***プロファイル
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';     -- 会社コード_本社
  cv_dep_cd_chosei        CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';        -- 部門コード_調整部門
  cv_fixed_asset_register CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER'; -- 台帳種類_固定資産台帳
  cv_prt_conv_cd_ed       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';       -- 按分方法_月末
--
  -- ***ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ログ出力
--
  -- ***ステータス/処理区分
  cv_status_101    CONSTANT VARCHAR2(3) := '101'; -- 未確定
  cv_status_102    CONSTANT VARCHAR2(3) := '102'; -- 確定済
  cv_status_103    CONSTANT VARCHAR2(3) := '103'; -- 移動
  cv_status_104    CONSTANT VARCHAR2(3) := '104'; -- 修正
  cv_status_105    CONSTANT VARCHAR2(3) := '105'; -- 除売却未確定
  cv_status_106    CONSTANT VARCHAR2(3) := '106'; -- 除売却
--
  -- ***減価償却費セグメント ダミー値
  cv_sub_acct_dummy CONSTANT VARCHAR2(30) := '00000';     -- 補助科目
  cv_ptnr_cd_dummy  CONSTANT VARCHAR2(30) := '000000000'; -- 顧客コード
  cv_busi_cd_dummy  CONSTANT VARCHAR2(30) := '000000';    -- 企業コード
  cv_project_dummy  CONSTANT VARCHAR2(30) := '0';         -- 予備1
  cv_future_dummy   CONSTANT VARCHAR2(30) := '0';         -- 予備2
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  TYPE g_object_header_id_ttype        IS TABLE OF xxcff_vd_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_internal_id_ttype      IS TABLE OF xxcff_vd_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype             IS TABLE OF xxcff_vd_object_headers.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_type_ttype      IS TABLE OF xxcff_vd_object_headers.owner_company_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype         IS TABLE OF xxcff_vd_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_machine_type_ttype            IS TABLE OF xxcff_vd_object_headers.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_manufacturer_name_ttype       IS TABLE OF xxcff_vd_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_model_ttype                   IS TABLE OF xxcff_vd_object_headers.model%TYPE INDEX BY PLS_INTEGER;
  TYPE g_age_type_ttype                IS TABLE OF xxcff_vd_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payables_units_ttype          IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fixed_assets_units_ttype      IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_units_ttype       IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_date_placed_in_service_ttype  IS TABLE OF xxcff_vd_object_headers.date_placed_in_service%TYPE INDEX BY PLS_INTEGER;
  TYPE g_assets_cost_ttype             IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cost_ttype                    IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payables_cost_ttype           IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype           IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_assets_date_ttype             IS TABLE OF xxcff_vd_object_headers.assets_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cat_attribute2_ttype          IS TABLE OF xxcff_vd_object_headers.assets_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_moved_date_ttype              IS TABLE OF xxcff_vd_object_headers.moved_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_address_ttype    IS TABLE OF xxcff_vd_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dclr_place_ttype              IS TABLE OF xxcff_vd_object_headers.dclr_place%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ttype                IS TABLE OF xxcff_vd_object_headers.location%TYPE INDEX BY PLS_INTEGER;
  TYPE g_date_retired_ttype            IS TABLE OF xxcff_vd_object_headers.date_retired%TYPE INDEX BY PLS_INTEGER;
  TYPE g_proceeds_of_sale_ttype        IS TABLE OF xxcff_vd_object_headers.proceeds_of_sale%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cost_of_removal_ttype         IS TABLE OF xxcff_vd_object_headers.cost_of_removal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_category_ccid_ttype           IS TABLE OF fa_categories.category_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_ccid_ttype              IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ccid_ttype           IS TABLE OF fa_locations.location_id%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_object_header_id_tab         g_object_header_id_ttype;       -- 物件ID
  g_object_internal_id_tab       g_object_internal_id_ttype;     -- 自販機物件内部ID
  g_object_code_tab              g_object_code_ttype;            -- 物件コード
  g_owner_company_type_tab       g_owner_company_type_ttype;     -- 本社/工場区分
  g_department_code_tab          g_department_code_ttype;        -- 管理部門
  g_machine_type_tab             g_machine_type_ttype;           -- 機器区分
  g_manufacturer_name_tab        g_manufacturer_name_ttype;      -- メーカ名
  g_model_tab                    g_model_ttype;                  -- 機種
  g_age_type_tab                 g_age_type_ttype;               -- 年式
  g_payables_units_tab           g_payables_units_ttype;         -- AP数量
  g_fixed_assets_units_tab       g_fixed_assets_units_ttype;     -- 単位数量
  g_transaction_units_tab        g_transaction_units_ttype;      -- 単位
  g_date_placed_in_service_tab   g_date_placed_in_service_ttype; -- 事業供用日
  g_assets_cost_tab              g_assets_cost_ttype;            -- 取得価格
  g_cost_tab                     g_cost_ttype;                   -- 取得価額
  g_payables_cost_tab            g_payables_cost_ttype;          -- 資産当初取得価額
  g_original_cost_tab            g_original_cost_ttype;          -- 当初取得価額
  g_assets_date_tab              g_assets_date_ttype;            -- 取得日
  g_cat_attribute2_tab           g_cat_attribute2_ttype;         -- カテゴリDFF2
  g_moved_date_tab               g_moved_date_ttype;             -- 移動日
  g_installation_address_tab     g_installation_address_ttype;   -- 設置場所
  g_dclr_place_tab               g_dclr_place_ttype;             -- 申告地
  g_location_tab                 g_location_ttype;               -- 事業所
  g_date_retired_tab             g_date_retired_ttype;           -- 除･売却日
  g_proceeds_of_sale_tab         g_proceeds_of_sale_ttype;       -- 売却価額
  g_cost_of_removal_tab          g_cost_of_removal_ttype;        -- 撤去費用
  g_category_ccid_tab            g_category_ccid_ttype;          -- 資産カテゴリCCID
  g_deprn_ccid_tab               g_deprn_ccid_ttype;             -- 減価償却費勘定CCID
  g_location_ccid_tab            g_location_ccid_ttype;          -- 事業所フレックスフィールドCCID
--
  -- ***処理件数
  gn_vd_target_cnt         NUMBER;     -- 処理中のレコード
  -- 自販機物件(未確定)登録処理における件数
  gn_vd_add_target_cnt     NUMBER;     -- 対象件数
  gn_vd_add_normal_cnt     NUMBER;     -- 正常件数
  gn_vd_add_warn_cnt       NUMBER;     -- 警告件数
  gn_vd_add_error_cnt      NUMBER;     -- エラー件数
  -- 自販機物件(移動)登録処理における件数
  gn_vd_trnsf_target_cnt   NUMBER;     -- 対象件数
  gn_vd_trnsf_normal_cnt   NUMBER;     -- 正常件数
  gn_vd_trnsf_warn_cnt     NUMBER;     -- 警告件数
  gn_vd_trnsf_error_cnt    NUMBER;     -- エラー件数
  -- 自販機物件(修正)登録処理における件数
  gn_vd_modify_target_cnt  NUMBER;     -- 対象件数
  gn_vd_modify_normal_cnt  NUMBER;     -- 正常件数
  gn_vd_modify_warn_cnt    NUMBER;     -- 警告件数
  gn_vd_modify_error_cnt   NUMBER;     -- エラー件数
  -- 自販機物件(除売却未確定)登録処理における件数
  gn_vd_retire_target_cnt  NUMBER;     -- 対象件数
  gn_vd_retire_normal_cnt  NUMBER;     -- 正常件数
  gn_vd_retire_warn_cnt    NUMBER;     -- 警告件数
  gn_vd_retire_error_cnt   NUMBER;     -- エラー件数
--
  -- 初期値情報
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name VARCHAR2(100);
--
  -- ***プロファイル値
  gv_comp_cd_itoen         VARCHAR2(100); -- 会社コード_本社
  gv_dep_cd_chosei         VARCHAR2(100); -- 部門コード_調整部門
  gv_fixed_asset_register  VARCHAR2(100); -- 台帳種類_固定資産台帳
  gv_prt_conv_cd_ed        VARCHAR2(100); -- 按分方法_月末
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- カレンダ期間クローズ日
  g_cal_per_close_date     DATE;

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
    g_object_header_id_tab.DELETE;
    g_object_internal_id_tab.DELETE;
    g_object_code_tab.DELETE;
    g_owner_company_type_tab.DELETE;
    g_department_code_tab.DELETE;
    g_machine_type_tab.DELETE;
    g_manufacturer_name_tab.DELETE;
    g_model_tab.DELETE;
    g_age_type_tab.DELETE;
    g_payables_units_tab.DELETE;
    g_fixed_assets_units_tab.DELETE;
    g_transaction_units_tab.DELETE;
    g_date_placed_in_service_tab.DELETE;
    g_assets_cost_tab.DELETE;
    g_cost_tab.DELETE;
    g_payables_cost_tab.DELETE;
    g_original_cost_tab.DELETE;
    g_assets_date_tab.DELETE;
    g_cat_attribute2_tab.DELETE;
    g_moved_date_tab.DELETE;
    g_installation_address_tab.DELETE;
    g_dclr_place_tab.DELETE;
    g_location_tab.DELETE;
    g_date_retired_tab.DELETE;
    g_proceeds_of_sale_tab.DELETE;
    g_cost_of_removal_tab.DELETE;
    g_category_ccid_tab.DELETE;
    g_deprn_ccid_tab.DELETE;
    g_location_ccid_tab.DELETE;
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
   * Procedure Name   : insert_vd_object_histories
   * Description      : 自販機物件履歴の作成 (A-8-4)
   ***********************************************************************************/
  PROCEDURE insert_vd_object_histories(
     iv_object_header_id  IN     NUMBER    -- 物件ID
    ,iv_object_status     IN     NUMBER    -- 処理区分
    ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT    VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_vd_object_histories'; -- プログラム名
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
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 自販機物件履歴の作成
    INSERT INTO xxcff_vd_object_histories(
      object_header_id       -- 物件ID
     ,object_code            -- 物件コード
     ,history_num            -- 履歴番号
     ,process_type           -- 処理区分
     ,process_date           -- 処理日
     ,object_status          -- 物件ステータス
     ,owner_company_type     -- 本社/工場区分
     ,department_code        -- 管理部門
     ,machine_type           -- 機器区分
     ,manufacturer_name      -- メーカ名
     ,model                  -- 機種
     ,age_type               -- 年式
     ,customer_code          -- 顧客コード
     ,quantity               -- 数量
     ,date_placed_in_service -- 事業供用日
     ,assets_cost            -- 取得価格
     ,month_lease_charge     -- 月額リース料
     ,re_lease_charge        -- 再リース料
     ,assets_date            -- 取得日
     ,moved_date             -- 移動日
     ,installation_place     -- 設置先
     ,installation_address   -- 設置場所
     ,dclr_place             -- 申告地
     ,location               -- 事業所
     ,date_retired           -- 除･売却日
     ,proceeds_of_sale       -- 売却価額
     ,cost_of_removal        -- 撤去費用
     ,retired_flag           -- 除売却確定フラグ
     ,ib_if_date             -- 設置ベース情報連携日
     ,fa_if_date             -- FA情報連携日
     ,fa_if_flag             -- FA連携フラグ
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
    SELECT
      voh.object_header_id        -- 物件ID
     ,voh.object_code             -- 物件コード
     ,(
      SELECT MAX(vohi.history_num) + 1
        FROM xxcff_vd_object_histories vohi
       WHERE voh.object_header_id = vohi.object_header_id
       ) history_num              -- 履歴番号
     ,iv_object_status            -- 処理区分
     ,cd_processing_date          -- 処理日
     ,voh.object_status           -- 物件ステータス
     ,voh.owner_company_type      -- 本社/工場区分
     ,voh.department_code         -- 管理部門
     ,voh.machine_type            -- 機器区分
     ,voh.manufacturer_name       -- メーカ名
     ,voh.model                   -- 機種
     ,voh.age_type                -- 年式
     ,voh.customer_code           -- 顧客コード
     ,voh.quantity                -- 数量
     ,voh.date_placed_in_service  -- 事業供用日
     ,voh.assets_cost             -- 取得価格
     ,month_lease_charge          -- 月額リース料
     ,re_lease_charge             -- 再リース料
     ,voh.assets_date             -- 取得日
     ,voh.moved_date              -- 移動日
     ,voh.installation_place      -- 設置先
     ,voh.installation_address    -- 設置場所
     ,voh.dclr_place              -- 申告地
     ,voh.location                -- 事業所
     ,voh.date_retired            -- 除･売却日
     ,voh.proceeds_of_sale        -- 売却価額
     ,voh.cost_of_removal         -- 撤去費用
     ,voh.retired_flag            -- 除売却確定フラグ
     ,voh.ib_if_date              -- 設置ベース情報連携日
     ,cd_fa_if_date               -- FA情報連携日
     ,cv_yes                      -- FA連携フラグ
     ,cn_created_by               -- 作成者
     ,cd_creation_date            -- 作成日
     ,cn_last_updated_by          -- 最終更新者
     ,cd_last_update_date         -- 最終更新日
     ,cn_last_update_login        -- 最終更新ログイン
     ,cn_request_id               -- 要求ID
     ,cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
     ,cn_program_id               -- コンカレント・プログラムID
     ,cd_program_update_date      -- プログラム更新日
    FROM
           xxcff_vd_object_headers   voh
    WHERE
           voh.object_header_id = iv_object_header_id
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
  END insert_vd_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_vd_object_histories
   * Description      : 自販機物件履歴の更新 (A-8-3)
   ***********************************************************************************/
  PROCEDURE update_vd_object_histories(
     iv_object_header_id  IN     NUMBER    -- 物件ID
    ,iv_object_status     IN     NUMBER    -- 処理区分
    ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT    VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_vd_object_histories'; -- プログラム名
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
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 自販機物件履歴の更新
    UPDATE xxcff_vd_object_histories
    SET
           fa_if_date             = cd_fa_if_date              -- FA情報連携日
          ,fa_if_flag             = cv_yes                     -- FA連携フラグ
          ,last_updated_by        = cn_last_updated_by         -- 最終更新者
          ,last_update_date       = cd_last_update_date        -- 最終更新日
          ,last_update_login      = cn_last_update_login       -- 最終更新ログイン
          ,request_id             = cn_request_id              -- 要求ID
          ,program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
          ,program_id             = cn_program_id              -- コンカレント・プログラムID
          ,program_update_date    = cd_program_update_date     -- プログラム更新日
    WHERE
           object_header_id = iv_object_header_id
    AND    process_type     = iv_object_status
    AND    fa_if_flag       = cv_no
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
  END update_vd_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_vd_object_headers
   * Description      : 自販機物件管理の更新 (A-8-2)
   ***********************************************************************************/
  PROCEDURE update_vd_object_headers(
     iv_object_header_id  IN     NUMBER    -- 物件ID
    ,iv_object_status     IN     NUMBER    -- 物件ステータス
    ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT    VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_vd_object_headers'; -- プログラム名
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
    -- 自販機物件管理の更新
    UPDATE xxcff_vd_object_headers
    SET
           object_status          = iv_object_status           -- 物件ステータス
          ,last_updated_by        = cn_last_updated_by         -- 最終更新者
          ,last_update_date       = cd_last_update_date        -- 最終更新日
          ,last_update_login      = cn_last_update_login       -- 最終更新ログイン
          ,request_id             = cn_request_id              -- 要求ID
          ,program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
          ,program_id             = cn_program_id              -- コンカレント・プログラムID
          ,program_update_date    = cd_program_update_date     -- プログラム更新日
    WHERE
           object_header_id = iv_object_header_id
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
  END update_vd_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_ccid
   * Description      : 減価償却費勘定CCID取得 (A-8-1)
   ***********************************************************************************/
  PROCEDURE get_deprn_ccid(
     iot_segments  IN OUT fnd_flex_ext.segmentarray                     -- 1.セグメント値配列
    ,ot_deprn_ccid OUT    gl_code_combinations.code_combination_id%TYPE -- 2.減価償却費勘定CCID
    ,ov_errbuf     OUT    VARCHAR2                                      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT    VARCHAR2                                      --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT    VARCHAR2)                                     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_ccid'; -- プログラム名
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
    cn_segment_count CONSTANT NUMBER := 8; -- セグメント数
--
    -- *** ローカル変数 ***
    -- 関数リターンコード
    lb_ret BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 部門コード設定
    iot_segments(2) := gv_dep_cd_chosei;
    -- 補助科目設定
    iot_segments(4) := cv_sub_acct_dummy;
    -- 顧客コード設定
    iot_segments(5) := cv_ptnr_cd_dummy;
    -- 企業コード設定
    iot_segments(6) := cv_busi_cd_dummy;
    -- 予備1設定
    iot_segments(7) := cv_project_dummy;
    -- 予備2設定
    iot_segments(8) := cv_future_dummy;
--
    -- CCID取得関数呼び出し
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => g_init_rec.gl_application_short_name -- アプリケーション短縮名(GL)
                ,key_flex_code           => g_init_rec.id_flex_code              -- キーフレックスコード
                ,structure_number        => g_init_rec.chart_of_accounts_id      -- 勘定科目体系番号
                ,validation_date         => g_init_rec.process_date              -- 日付チェック
                ,n_segments              => cn_segment_count                     -- セグメント数
                ,segments                => iot_segments                         -- セグメント値配列
                ,combination_id          => ot_deprn_ccid                        -- CCID
                );
    IF NOT lb_ret THEN
      lv_errmsg := fnd_flex_ext.get_message;
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
  END get_deprn_ccid;
--
  /**********************************************************************************
   * Procedure Name   : chk_object_trnsf_data
   * Description      : 移動詳細情報変更チェック (A-8-5)
   ***********************************************************************************/
  PROCEDURE chk_object_trnsf_data(
     iv_object_code          IN     VARCHAR2                  -- 物件コード
    ,iv_dclr_place           IN     VARCHAR2                  -- 申告地
    ,iv_department_code      IN     VARCHAR2                  -- 管理部門
    ,iv_location             IN     VARCHAR2                  -- 事業所
    ,iv_installation_address IN     VARCHAR2                  -- 場所
    ,iv_owner_company_type   IN     VARCHAR2                  -- 本社工場区分
    ,iv_modify_flg           OUT    VARCHAR2                  -- 変更フラグ
    ,ov_errbuf               OUT    VARCHAR2                  -- エラー・メッセージ           --# 固定 # 
    ,ov_retcode              OUT    VARCHAR2                  -- リターン・コード             --# 固定 #
    ,ov_errmsg               OUT    VARCHAR2)                 -- ユーザー・エラー・メッセージ --# 固定 #

  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_trnsf_data'; -- プログラム名
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
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ローカル変数 ***
    ln_deprn_ccid_new     gl_code_combinations.code_combination_id%TYPE; -- 移動後減価償却費勘定CCID
    ln_deprn_ccid_org     NUMBER;                                        -- 移動元減価償却費勘定CCID
    ln_location_ccid_new  fa_locations.location_id%TYPE;                 -- 移動後事業所CCID
    ln_location_ccid_org  NUMBER;                                        -- 移動元事業所CCID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 減価償却費勘定CCID取得 (A-8-5-1) 
    --==============================================================
    -- A-8-1を呼び出し、減価償却費勘定CCIDを取得
    get_deprn_ccid(
       iot_segments     => g_segments_tab     -- セグメント値配列
      ,ot_deprn_ccid    => ln_deprn_ccid_new  -- 減価償却費勘定CCID
      ,ov_errbuf        => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
      ,ov_retcode       => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 事業所CCID取得 (A-8-5-2)
    --==============================================================
    xxcff_common1_pkg.chk_fa_location(
       iv_segment1      => iv_dclr_place            -- 申告地
      ,iv_segment2      => iv_department_code       -- 管理部門
      ,iv_segment3      => iv_location              -- 事業所
      ,iv_segment4      => iv_installation_address  -- 場所
      ,iv_segment5      => iv_owner_company_type    -- 本社工場区分
      ,on_location_id   => ln_location_ccid_new     -- 事業所CCID
      ,ov_errbuf        => lv_errbuf                -- エラー・メッセージ           --# 固定 # 
      ,ov_retcode       => lv_retcode               -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 移動元詳細情報取得 (A-8-5-3)
    --==============================================================
    SELECT
           fdh.code_combination_id     -- 減価償却費CCID
          ,fdh.location_id             -- 事業所ID
    INTO
           ln_deprn_ccid_org           -- 移動元減価償却費勘定CCID
          ,ln_location_ccid_org        -- 移動元事業所CCID
    FROM
           fa_additions_b          fab -- 資産詳細情報
          ,fa_distribution_history fdh -- 資産割当履歴情報
    WHERE
          fab.tag_number = iv_object_code
    AND   fab.asset_id = fdh.asset_id
    AND   fdh.date_ineffective IS NULL
    AND   fdh.book_type_code = gv_fixed_asset_register
    ;
--
    --==============================================================
    -- 移動詳細情報変更チェック (A-8-5-4)
    --==============================================================
    -- 減価償却費勘定CCIDの比較
    IF ( ln_deprn_ccid_org <> ln_deprn_ccid_new ) THEN
      iv_modify_flg := cv_yes;
    ELSE
      IF ( ln_location_ccid_org <> ln_location_ccid_new ) THEN
        iv_modify_flg := cv_yes;
      ELSE
        iv_modify_flg := cv_no;
      END IF;
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
  END chk_object_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_ritire_data
   * Description      : 自販機物件（除売却未確定）登録データ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE get_vd_object_ritire_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_ritire_data'; -- プログラム名
    cv_type_code_sale    CONSTANT VARCHAR2(4)   := 'SALE';                      -- 除売却タイプ：除却
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_cost_0            CONSTANT NUMBER        := 0;
    cn_count_0          CONSTANT NUMBER        := 0;
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
--
    -- *** ローカル変数 ***
    lv_warnmsg                VARCHAR2(5000);  -- 警告メッセージ
    lv_warn_flg               VARCHAR2(1);     -- 警告フラグ
    lv_asset_number           VARCHAR2(15);    -- 資産番号
    lv_ret_type_code          VARCHAR2(15);    -- 除売却タイプ
    ln_cost_retired           NUMBER;          -- 除･売却取得価格
    ln_proceeds_of_sale       NUMBER;          -- 売却価額
    ln_cost_of_removal        NUMBER;          -- 撤去費用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機物件（除売却未確定）カーソル
    CURSOR vd_object_ritire_cur
    IS
      SELECT
             vohe.object_header_id        AS object_header_id        -- 物件ID
            ,vohe.object_code             AS object_code             -- 物件コード
            ,vohe.date_retired            AS date_retired            -- 除・売却日
            ,vohe.proceeds_of_sale        AS proceeds_of_sale        -- 売却価額
            ,vohe.cost_of_removal         AS cost_of_removal         -- 撤去費用
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- 物件ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- 自販機物件履歴
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA未連携
                                        AND voh.process_type = cv_status_105 -- 除売却未確定
                                        AND voh.retired_flag = cv_yes        -- 除売却確定フラグ
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
      ;
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
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN vd_object_ritire_cur;
    -- データの一括取得
    FETCH vd_object_ritire_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- 物件ID
                      ,g_object_code_tab             -- 物件コード
                      ,g_date_retired_tab            -- 除・売却日
                      ,g_proceeds_of_sale_tab        -- 売却価額
                      ,g_cost_of_removal_tab         -- 撤去費用
    ;
    -- 移動対象件数カウント
    gn_vd_retire_target_cnt := g_object_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE vd_object_ritire_cur;
--
    IF ( gn_vd_retire_target_cnt = cn_count_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_017a03_t_021) -- 自販機物件（除売却）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理④
    --==============================================================
    <<vd_object_trnsf_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- 警告フラグを初期化する
      lv_warn_flg := cv_no;
      -- 処理中の件数取得
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- 項目値チェック（除売却未確定） (A-7-1)
      --==============================================================
      -- 1.除・売却日の存在チェックをする
      IF ( g_date_retired_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグに'Y'をセット
        lv_warn_flg := cv_yes;
        -- 除売却未確定スキップ件数カウント
        gn_vd_retire_warn_cnt := gn_vd_retire_warn_cnt + 1;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_036)                     -- 除・売却日
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 除売却日の日付チェック処理
      -- 除売却日が存在する場合
      IF ( g_date_retired_tab(ln_loop_cnt) IS NOT NULL ) THEN
        -- カレンダ期間クローズ日を取得していない場合
        IF ( g_cal_per_close_date IS NULL ) THEN
          BEGIN
            -- 最新のカレンダ期間クローズ日を取得
            SELECT
                   MAX(fdp.calendar_period_close_date)               -- カレンダ期間クローズ日
            INTO
                   g_cal_per_close_date
            FROM   fa_deprn_periods     fdp                          -- 減価償却期間
            WHERE
                   fdp.book_type_code   = gv_fixed_asset_register    -- 台帳種類
            AND    fdp.period_close_date IS NOT NULL                 -- クローズ済
            ;
          EXCEPTION
            -- カレンダ期間クローズ日が取得できない場合
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                            ,cv_msg_017a03_m_013     -- 取得エラー
                                                            ,cv_tkn_table            -- トークン'TABLE_NAME'
                                                            ,cv_msg_017a03_t_015     -- 減価償却期間
                                                            ,cv_tkn_info             -- トークン'INFO'
                                                            ,cv_msg_017a03_t_018)    -- カレンダ期間クローズ日
                                                            ,1
                                                            ,5000);
              RAISE chk_no_data_found_expt;
          END;
        END IF;
        -- 除売却日がカレンダ期間クローズ日以前の場合
        IF ( trunc(g_date_retired_tab(ln_loop_cnt)) <= trunc(g_cal_per_close_date) ) THEN
          -- 警告フラグが'N'の場合
          IF ( lv_warn_flg = cv_no ) THEN
            -- 警告フラグに'Y'をセット
            lv_warn_flg := cv_yes;
            -- 除売却未確定スキップ件数カウント
            gn_vd_retire_warn_cnt := gn_vd_retire_warn_cnt + 1;
          END IF;
          -- 警告メッセージをセット
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_022                      -- 自販機物件FA連携項目存在チェックエラー
                                                         ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                         ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                         ,cv_tkn_param_name                        -- トークン'param_name'
                                                         ,cv_msg_017a03_t_036)                     -- 除・売却日
                                                         ,1
                                                         ,2000);
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
      END IF;
--
      -- 警告フラグが'N'の場合
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- 固定資産情報取得（除売却未確定） (A-7-2)
        --==============================================================
        BEGIN
          SELECT 
                 fab.asset_number                  -- 資産番号
                ,fb.cost                           -- 取得価格
          INTO
                 lv_asset_number                   -- 資産番号
                ,ln_cost_retired                   -- 除･売却取得価格
          FROM
                fa_additions_b  fab                -- 資産詳細情報
               ,fa_books        fb                 -- 資産台帳情報
          WHERE
                fab.tag_number      = g_object_code_tab(ln_loop_cnt)
          AND   fab.asset_id        = fb.asset_id
          AND   fb.book_type_code   = gv_fixed_asset_register
          AND   fb.date_ineffective IS NULL
          ;
        EXCEPTION
          -- 固定資産情報が取得できない場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- 取得エラー
                                                          ,cv_tkn_table            -- トークン'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- 資産詳細情報
                                                          ,cv_tkn_info             -- トークン'INFO'
                                                          ,cv_msg_017a03_t_022)    -- 固定資産（除売却）情報
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        -- 除売却タイプの取得
        IF ( (g_proceeds_of_sale_tab(ln_loop_cnt) = cn_cost_0)
          OR (g_proceeds_of_sale_tab(ln_loop_cnt) IS NULL)) THEN
          -- 売却価額が0、またはNULLの場合、除却：NULL
          lv_ret_type_code := NULL;
        ELSE
          -- 上記以外の場合、売却：'SALE'
          lv_ret_type_code := cv_type_code_sale;
        END IF;
        -- 売却価額の取得
        IF (g_proceeds_of_sale_tab(ln_loop_cnt) IS NULL) THEN
          -- 売却価額がNULLの場合、0
          ln_proceeds_of_sale := cn_cost_0;
        ELSE
          -- 上記以外の場合、A-7カーソル取得値
          ln_proceeds_of_sale := g_proceeds_of_sale_tab(ln_loop_cnt);
        END IF;
        -- 撤去費用の取得
        IF (g_cost_of_removal_tab(ln_loop_cnt) IS NULL) THEN
          -- 撤去費用がNULLの場合、0
          ln_cost_of_removal := cn_cost_0;
        ELSE
          -- 上記以外の場合、A-7カーソル取得値
          ln_cost_of_removal := g_cost_of_removal_tab(ln_loop_cnt);
        END IF;
--
        --==============================================================
        -- 除売却OIF登録 (A-7-3)
        --==============================================================
        -- 除売却OIF登録
        INSERT INTO xx01_retire_oif(
           retire_oif_id                  -- ID
          ,book_type_code                 -- 台帳名
          ,asset_number                   -- 資産番号
          ,date_retired                   -- 除･売却日
          ,posting_flag                   -- 転記ﾁｪｯｸﾌﾗｸﾞ
          ,status                         -- ｽﾃｰﾀｽ
          ,cost_retired                   -- 除･売却取得価格
          ,retirement_type_code           -- 除売却タイプ
          ,proceeds_of_sale               -- 売却価額
          ,cost_of_removal                -- 撤去費用
          ,retirement_prorate_convention  -- 除･売却年度償却
          ,created_by                     -- 作成者
          ,creation_date                  -- 作成日
          ,last_updated_by                -- 最終更新者
          ,last_update_date               -- 最終更新日
          ,last_update_login              -- 最終更新ﾛｸﾞｲﾝ
          ,request_id                     -- ﾘｸｴｽﾄID
          ,program_application_id         -- ｱﾌﾟﾘｹｰｼｮﾝID
          ,program_id                     -- ﾌﾟﾛｸﾞﾗﾑID
          ,program_update_date            -- ﾌﾟﾛｸﾞﾗﾑ最終更新
        ) VALUES (
           xx01_retire_oif_s.NEXTVAL      -- ID
          ,gv_fixed_asset_register        -- 台帳名
          ,lv_asset_number                -- 資産番号
          ,g_date_retired_tab(ln_loop_cnt)  -- 除･売却日
          ,cv_yes                         -- 転記ﾁｪｯｸﾌﾗｸﾞ
          ,cv_status                      -- ｽﾃｰﾀｽ
          ,ln_cost_retired                -- 除･売却取得価格
          ,lv_ret_type_code               -- 除売却タイプ
          ,ln_proceeds_of_sale            -- 売却価額
          ,ln_cost_of_removal             -- 撤去費用
          ,gv_prt_conv_cd_ed              -- 除･売却年度償却
          ,cn_created_by                  -- 作成者
          ,cd_creation_date               -- 作成日
          ,cn_last_updated_by             -- 最終更新者
          ,cd_last_update_date            -- 最終更新日
          ,cn_last_update_login           -- 最終更新ログインID
          ,cn_request_id                  -- リクエストID
          ,cn_program_application_id      -- アプリケーションID
          ,cn_program_id                  -- プログラムID
          ,cd_program_update_date         -- プログラム最終更新日
        )
        ;
--
        --==============================================================
        -- 自販機物件管理の更新（除売却未確定） (A-7-4)
        --==============================================================
        update_vd_object_headers(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_106                        -- 物件ステータス
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 自販機物件履歴の更新（除売却未確定） (A-7-5)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_105                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 自販機物件履歴の作成（除売却） (A-7-6)
        --==============================================================
        insert_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_106                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 作成に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 自販機物件(除売却未確定)登録件数カウント
        gn_vd_retire_normal_cnt := gn_vd_retire_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_trnsf_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_017a03_t_014) -- 自販機物件管理
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 取得件数がゼロ件のエラーハンドラ ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_vd_object_ritire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_modify_data
   * Description      : 自販機物件（修正）登録データ抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_vd_object_modify_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_modify_data'; -- プログラム名
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_period_ctr_0      CONSTANT NUMBER        := 0;
    cn_count_0           CONSTANT NUMBER        := 0;
    cv_date_type         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
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
--
    -- *** ローカル変数 ***
    lv_warnmsg                     VARCHAR2(5000);  -- 警告メッセージ
    lv_warn_flg                    VARCHAR2(1);     -- 警告フラグ
    ln_life_in_monsths             NUMBER;          -- 耐用年数+月数
    lv_description                 VARCHAR2(80);    -- 摘要
    ln_reval_rsv                   NUMBER;          -- 再評価積立金
    ln_deprn_exp                   NUMBER;          -- 減価償却費
    lv_attribute2                  VARCHAR2(10);    -- カテゴリDFF02
--
    -- OIF登録用変数
    ln_asset_id                    NUMBER;          -- 資産ID
    lv_asset_number_old            VARCHAR2(15);    -- 資産番号
    ld_dpis_old                    DATE;            -- 事業供用日（修正前）
    ln_category_id_old             NUMBER;          -- 資産カテゴリID（修正前）
    lv_cat_attribute_category_old  VARCHAR2(210);   -- 資産カテゴリコード（修正前）
    lv_amortized_flag              VARCHAR2(3);     -- 修正額償却フラグ
    ld_amortization_start_date     DATE;            -- 償却開始日
    lv_asset_number_new            VARCHAR2(15);    -- 資産番号（修正後）
    lv_tag_number                  VARCHAR2(15);    -- 現品票番号
    ln_category_id_new             NUMBER;          -- 資産カテゴリID（修正後）
    lv_serial_number               VARCHAR2(35);    -- シリアル番号
    ln_asset_key_ccid              NUMBER;          -- 資産キーCCID
    lv_key_segment1                VARCHAR2(30);    -- 資産キーセグメント1
    lv_key_segment2                VARCHAR2(30);    -- 資産キーセグメント2
    ln_parent_asset_id             NUMBER;          -- 親資産ID
    ln_lease_id                    NUMBER;          -- リースID
    lv_model_number                VARCHAR2(40);    -- モデル
    lv_in_use_flag                 VARCHAR2(3);     -- 使用状況
    lv_inventorial                 VARCHAR2(3);     -- 実地棚卸フラグ
    lv_owned_leased                VARCHAR2(15);    -- 所有権
    lv_new_used                    VARCHAR2(4);     -- 新品/中古
    lv_cat_attribute1              VARCHAR2(150);   -- カテゴリDFF1
    lv_cat_attribute3              VARCHAR2(150);   -- カテゴリDFF3
    lv_cat_attribute4              VARCHAR2(150);   -- カテゴリDFF4
    lv_cat_attribute5              VARCHAR2(150);   -- カテゴリDFF5
    lv_cat_attribute6              VARCHAR2(150);   -- カテゴリDFF6
    lv_cat_attribute7              VARCHAR2(150);   -- カテゴリDFF7
    lv_cat_attribute8              VARCHAR2(150);   -- カテゴリDFF8
    lv_cat_attribute9              VARCHAR2(150);   -- カテゴリDFF9
    lv_cat_attribute10             VARCHAR2(150);   -- カテゴリDFF10
    lv_cat_attribute11             VARCHAR2(150);   -- カテゴリDFF11
    lv_cat_attribute12             VARCHAR2(150);   -- カテゴリDFF12
    lv_cat_attribute13             VARCHAR2(150);   -- カテゴリDFF13
    lv_cat_attribute14             VARCHAR2(150);   -- カテゴリDFF14
    lv_cat_attribute15             VARCHAR2(150);   -- カテゴリDFF15
    lv_cat_attribute16             VARCHAR2(150);   -- カテゴリDFF16
    lv_cat_attribute17             VARCHAR2(150);   -- カテゴリDFF17
    lv_cat_attribute18             VARCHAR2(150);   -- カテゴリDFF18
    lv_cat_attribute19             VARCHAR2(150);   -- カテゴリDFF19
    lv_cat_attribute20             VARCHAR2(150);   -- カテゴリDFF20
    lv_cat_attribute21             VARCHAR2(150);   -- カテゴリDFF21
    lv_cat_attribute22             VARCHAR2(150);   -- カテゴリDFF22
    lv_cat_attribute23             VARCHAR2(150);   -- カテゴリDFF23
    lv_cat_attribute24             VARCHAR2(150);   -- カテゴリDFF24
    lv_cat_attribute25             VARCHAR2(150);   -- カテゴリDFF27
    lv_cat_attribute26             VARCHAR2(150);   -- カテゴリDFF25
    lv_cat_attribute27             VARCHAR2(150);   -- カテゴリDFF26
    lv_cat_attribute28             VARCHAR2(150);   -- カテゴリDFF28
    lv_cat_attribute29             VARCHAR2(150);   -- カテゴリDFF29
    lv_cat_attribute30             VARCHAR2(150);   -- カテゴリDFF30
    lv_cat_attribute_category_new  VARCHAR2(210);   -- 資産カテゴリコード（修正後）
    ln_salvage_value               NUMBER;          -- 残存価額
    ln_percent_salvage_value       NUMBER;          -- 残存価額%
    ln_allowed_deprn_limit_amount  NUMBER;          -- 償却限度額
    ln_allowed_deprn_limit         NUMBER;          -- 償却限度率
    ln_ytd_deprn                   NUMBER;          -- 年償却累計額
    ln_deprn_reserve               NUMBER;          -- 償却累計額
    lv_depreciate_flag             VARCHAR2(3);     -- 償却費計上フラグ
    lv_deprn_method_code           VARCHAR2(12);    -- 償却方法
    ln_basic_rate                  NUMBER;          -- 普通償却率
    ln_adjusted_rate               NUMBER;          -- 割増後償却率
    ln_life_years                  NUMBER;          -- 耐用年数
    ln_life_months                 NUMBER;          -- 月数
    lv_bonus_rule                  VARCHAR2(30);    -- ボーナスルール
    ln_bonus_ytd_deprn             NUMBER;          -- ボーナス年償却累計額
    ln_bonus_deprn_reserve         NUMBER;          -- ボーナス償却累計額
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機物件（修正）カーソル
    CURSOR vd_object_modify_cur
    IS
      SELECT
             vohe.object_header_id        AS object_header_id        -- 物件ID
            ,vohe.object_code             AS object_code             -- 物件コード
            ,vohe.date_placed_in_service  AS date_placed_in_service  -- 事業共用日
            ,vohe.manufacturer_name       AS manufacturer_name       -- メーカー
            ,vohe.model                   AS model                   -- 機種
            ,vohe.age_type                AS age_type                -- 年式
            ,vohe.quantity                AS quantity                -- 数量
            ,vohe.assets_date             AS assets_date             -- 取得日
            ,vohe.assets_cost             AS assets_cost1            -- 取得価格
            ,vohe.assets_cost             AS assets_cost2            -- 取得価格
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- 物件ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- 自販機物件履歴
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA未連携
                                        AND voh.process_type = cv_status_104 -- 修正
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
      ;
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
    -- ローカル変数初期化処理
    ln_life_years                  := NULL;  -- 耐用年数
    ln_life_months                 := NULL;  -- 月数

    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN vd_object_modify_cur;
    -- データの一括取得
    FETCH vd_object_modify_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- 物件ID
                      ,g_object_code_tab             -- 物件コード
                      ,g_date_placed_in_service_tab  -- 事業共用日
                      ,g_manufacturer_name_tab       -- メーカー
                      ,g_model_tab                   -- 機種
                      ,g_age_type_tab                -- 年式
                      ,g_transaction_units_tab       -- 単位
                      ,g_cat_attribute2_tab          -- カテゴリDFF2
                      ,g_cost_tab                    -- 取得価額
                      ,g_original_cost_tab           -- 当初取得価額
    ;
    -- 修正対象件数カウント
    gn_vd_modify_target_cnt := g_object_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE vd_object_modify_cur;
--
    IF ( gn_vd_modify_target_cnt = cn_count_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_017a03_t_019) -- 自販機物件（修正）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理③
    --==============================================================
    <<vd_object_modify_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- 警告フラグを初期化する
      lv_warn_flg := cv_no;
      -- 処理中の件数取得
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- 項目値チェック（修正） (A-6-1)
      --==============================================================
      -- 1.事業供用日の存在チェックをする
      IF ( g_date_placed_in_service_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグに'Y'をセット
        lv_warn_flg := cv_yes;
        -- 修正スキップ件数カウント
        gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_027)                     -- 事業供用日
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.摘要の存在チェックをする
      IF ( g_manufacturer_name_tab(ln_loop_cnt)||g_model_tab(ln_loop_cnt)||g_age_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 修正スキップ件数カウント
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_025)                     -- メーカー名 機種 年式
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.数量（単位）の存在チェックをする
      IF ( g_transaction_units_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 修正スキップ件数カウント
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_029)                     -- 数量
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.取得価格（取得価額）の存在チェックをする
      IF ( g_cost_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 修正スキップ件数カウント
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_028)                     -- 取得価格
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 警告フラグが'N'の場合
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- 固定資産情報取得（修正） (A-6-2)
        --==============================================================
        BEGIN
          SELECT
                 fab.asset_id                    -- 資産ID
                ,fab.asset_number                -- 資産番号
                ,fb.date_placed_in_service       -- 事業供用日（修正前）
                ,fab.asset_category_id           -- 資産カテゴリID（修正前）
                ,fab.attribute_category_code     -- 資産カテゴリコード（修正前）
                ,fbc.amortize_flag               -- 修正額償却フラグ
                ,fth.amortization_start_date     -- 償却開始日
                ,fab.asset_number                -- 資産番号（修正後）
                ,fab.tag_number                  -- 現品票番号
                ,fab.asset_category_id           -- 資産カテゴリID（修正後）
                ,fab.serial_number               -- シリアル番号
                ,fab.asset_key_ccid              -- 資産キーCCID
                ,fak.segment1                    -- 資産キーセグメント1
                ,fak.segment2                    -- 資産キーセグメント2
                ,fab.parent_asset_id             -- 親資産ID
                ,fab.lease_id                    -- リースID
                ,fab.model_number                -- モデル
                ,fab.in_use_flag                 -- 使用状況
                ,fab.inventorial                 -- 実地棚卸フラグ
                ,fab.owned_leased                -- 所有権
                ,fab.new_used                    -- 新品/中古
                ,fab.attribute1                  -- カテゴリDFF1
                ,fab.attribute3                  -- カテゴリDFF3
                ,fab.attribute4                  -- カテゴリDFF4
                ,fab.attribute5                  -- カテゴリDFF5
                ,fab.attribute6                  -- カテゴリDFF6
                ,fab.attribute7                  -- カテゴリDFF7
                ,fab.attribute8                  -- カテゴリDFF8
                ,fab.attribute9                  -- カテゴリDFF9
                ,fab.attribute10                 -- カテゴリDFF10
                ,fab.attribute11                 -- カテゴリDFF11
                ,fab.attribute12                 -- カテゴリDFF12
                ,fab.attribute13                 -- カテゴリDFF13
                ,fab.attribute14                 -- カテゴリDFF14
                ,fab.attribute15                 -- カテゴリDFF15
                ,fab.attribute16                 -- カテゴリDFF16
                ,fab.attribute17                 -- カテゴリDFF17
                ,fab.attribute18                 -- カテゴリDFF18
                ,fab.attribute19                 -- カテゴリDFF19
                ,fab.attribute20                 -- カテゴリDFF20
                ,fab.attribute21                 -- カテゴリDFF21
                ,fab.attribute22                 -- カテゴリDFF22
                ,fab.attribute23                 -- カテゴリDFF23
                ,fab.attribute24                 -- カテゴリDFF24
                ,fab.attribute25                 -- カテゴリDFF27
                ,fab.attribute26                 -- カテゴリDFF25
                ,fab.attribute27                 -- カテゴリDFF26
                ,fab.attribute28                 -- カテゴリDFF28
                ,fab.attribute29                 -- カテゴリDFF29
                ,fab.attribute30                 -- カテゴリDFF30
                ,fab.attribute_category_code     -- 資産カテゴリコード（修正後）
                ,fb.salvage_value                -- 残存価額
                ,fb.percent_salvage_value        -- 残存価額%
                ,fb.allowed_deprn_limit_amount   -- 償却限度額
                ,fb.allowed_deprn_limit          -- 償却限度率
                ,fb.depreciate_flag              -- 償却費計上フラグ
                ,fb.deprn_method_code            -- 償却方法
                ,fb.basic_rate                   -- 普通償却率
                ,fb.adjusted_rate                -- 割増後償却率
                ,fb.life_in_months               -- 耐用年数+月数
                ,fb.bonus_rule                   -- ボーナスルール
          INTO
                 ln_asset_id                    -- 資産ID
                ,lv_asset_number_old            -- 資産番号
                ,ld_dpis_old                    -- 事業供用日（修正前）
                ,ln_category_id_old             -- 資産カテゴリID（修正前）
                ,lv_cat_attribute_category_old  -- 資産カテゴリコード（修正前）
                ,lv_amortized_flag              -- 修正額償却フラグ
                ,ld_amortization_start_date     -- 償却開始日
                ,lv_asset_number_new            -- 資産番号（修正後）
                ,lv_tag_number                  -- 現品票番号
                ,ln_category_id_new             -- 資産カテゴリID（修正後）
                ,lv_serial_number               -- シリアル番号
                ,ln_asset_key_ccid              -- 資産キーCCID
                ,lv_key_segment1                -- 資産キーセグメント1
                ,lv_key_segment2                -- 資産キーセグメント2
                ,ln_parent_asset_id             -- 親資産ID
                ,ln_lease_id                    -- リースID
                ,lv_model_number                -- モデル
                ,lv_in_use_flag                 -- 使用状況
                ,lv_inventorial                 -- 実地棚卸フラグ
                ,lv_owned_leased                -- 所有権
                ,lv_new_used                    -- 新品/中古
                ,lv_cat_attribute1              -- カテゴリDFF1
                ,lv_cat_attribute3              -- カテゴリDFF3
                ,lv_cat_attribute4              -- カテゴリDFF4
                ,lv_cat_attribute5              -- カテゴリDFF5
                ,lv_cat_attribute6              -- カテゴリDFF6
                ,lv_cat_attribute7              -- カテゴリDFF7
                ,lv_cat_attribute8              -- カテゴリDFF8
                ,lv_cat_attribute9              -- カテゴリDFF9
                ,lv_cat_attribute10             -- カテゴリDFF10
                ,lv_cat_attribute11             -- カテゴリDFF11
                ,lv_cat_attribute12             -- カテゴリDFF12
                ,lv_cat_attribute13             -- カテゴリDFF13
                ,lv_cat_attribute14             -- カテゴリDFF14
                ,lv_cat_attribute15             -- カテゴリDFF15
                ,lv_cat_attribute16             -- カテゴリDFF16
                ,lv_cat_attribute17             -- カテゴリDFF17
                ,lv_cat_attribute18             -- カテゴリDFF18
                ,lv_cat_attribute19             -- カテゴリDFF19
                ,lv_cat_attribute20             -- カテゴリDFF20
                ,lv_cat_attribute21             -- カテゴリDFF21
                ,lv_cat_attribute22             -- カテゴリDFF22
                ,lv_cat_attribute23             -- カテゴリDFF23
                ,lv_cat_attribute24             -- カテゴリDFF24
                ,lv_cat_attribute25             -- カテゴリDFF27
                ,lv_cat_attribute26             -- カテゴリDFF25
                ,lv_cat_attribute27             -- カテゴリDFF26
                ,lv_cat_attribute28             -- カテゴリDFF28
                ,lv_cat_attribute29             -- カテゴリDFF29
                ,lv_cat_attribute30             -- カテゴリDFF30
                ,lv_cat_attribute_category_new  -- 資産カテゴリコード（修正後）
                ,ln_salvage_value               -- 残存価額
                ,ln_percent_salvage_value       -- 残存価額%
                ,ln_allowed_deprn_limit_amount  -- 償却限度額
                ,ln_allowed_deprn_limit         -- 償却限度率
                ,lv_depreciate_flag             -- 償却費計上フラグ
                ,lv_deprn_method_code           -- 償却方法
                ,ln_basic_rate                  -- 普通償却率
                ,ln_adjusted_rate               -- 割増後償却率
                ,ln_life_in_monsths             -- 耐用年数+月数
                ,lv_bonus_rule                  -- ボーナスルール
          FROM
                fa_additions_b          fab      -- 資産詳細情報
               ,fa_asset_keywords       fak      -- 資産キー
               ,fa_books                fb       -- 資産台帳情報
               ,fa_book_controls        fbc      -- 資産台帳
               ,fa_transaction_headers  fth      -- 資産取引ヘッダ-
          WHERE
                fab.asset_key_ccid           = fak.code_combination_id(+)
          AND   fab.asset_id                 = fb.asset_id
          AND   fb.book_type_code            = fbc.book_type_code(+)
          AND   fb.transaction_header_id_in  = fth.transaction_header_id(+)
          AND   fab.tag_number               = g_object_code_tab(ln_loop_cnt)
          AND   fb.book_type_code            = gv_fixed_asset_register
          AND   fb.date_ineffective          IS NULL
          ;
        EXCEPTION
          -- 固定資産情報が取得できない場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- 取得エラー
                                                          ,cv_tkn_table            -- トークン'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- 資産詳細情報
                                                          ,cv_tkn_info             -- トークン'INFO'
                                                          ,cv_msg_017a03_t_020)    -- 固定資産（修正）情報
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        -- 償却累計額・年償却累計額・ボーナス償却累計額・ボーナス年償却累計額の取得
        xx01_conc_util_pkg.query_balances_bonus(
           in_asset_id         => ln_asset_id             -- 資産ID
          ,iv_book_type_code   => gv_fixed_asset_register -- XXCFF:台帳種類_固定資産台帳（プロファイル値）
          ,on_deprn_rsv        => ln_deprn_reserve        -- 償却累計額
          ,on_reval_rsv        => ln_reval_rsv            -- 再評価積立金
          ,on_ytd_deprn        => ln_ytd_deprn            -- 年償却累計額
          ,on_deprn_exp        => ln_deprn_exp            -- 減価償却費
          ,on_bonus_deprn_rsv  => ln_bonus_deprn_reserve  -- ボーナス償却累計額
          ,on_bonus_ytd_deprn  => ln_bonus_ytd_deprn      -- ボーナス年償却累計額
          ,in_period_ctr       => cn_period_ctr_0         -- 固定値：0
        );
--
        -- 耐用年数+月数がNULLではない場合
        IF ( ln_life_in_monsths IS NOT NULL ) THEN
          -- 耐用年数の取得
          ln_life_years  := trunc(ln_life_in_monsths / 12);
          -- 耐用月数の取得
          ln_life_months := mod(ln_life_in_monsths, 12);
        END IF;
--
        -- 摘要を取得する
        lv_description := SUBSTRB(g_manufacturer_name_tab(ln_loop_cnt) || ' ' ||
                                  g_model_tab(ln_loop_cnt) || ' ' ||
                                  g_age_type_tab(ln_loop_cnt)
                                  , 1, 80);
--
        --==============================================================
        -- 修正OIF登録 (A-6-3)
        --==============================================================
        -- カテゴリDFF02の取得
        IF (g_cat_attribute2_tab(ln_loop_cnt) IS NULL) THEN
          -- カテゴリDFF02(取得日)がNULLの時、事業供用日をYYYY/MM/DD型でセットする
          lv_attribute2 := to_char(g_date_placed_in_service_tab(ln_loop_cnt), cv_date_type);
        ELSE
          -- DFF02(取得日)が存在する時、DFF02(取得日)をYYYY/MM/DD型でセットする
          lv_attribute2 := to_char(g_cat_attribute2_tab(ln_loop_cnt), cv_date_type);
        END IF;
--
        -- 修正OIF登録
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- 台帳名
          ,asset_number_old                -- 資産番号
          ,dpis_old                        -- 事業供用日（修正前）
          ,category_id_old                 -- 資産カテゴリID（修正前）
          ,cat_attribute_category_old      -- 資産カテゴリコード（修正前）
          ,dpis_new                        -- 事業供用日（修正後）
          ,description                     -- 摘要（修正後）
          ,transaction_units               -- 単位
          ,cat_attribute2                  -- カテゴリDFF2
          ,cost                            -- 取得価額
          ,original_cost                   -- 当初取得価額
          ,posting_flag                    -- 転記チェックフラグ
          ,status                          -- ステータス
          ,amortized_flag                  -- 修正額償却フラグ
          ,amortization_start_date         -- 償却開始日
          ,asset_number_new                -- 資産番号（修正後）
          ,tag_number                      -- 現品票番号
          ,category_id_new                 -- 資産カテゴリID（修正後）
          ,serial_number                   -- シリアル番号
          ,asset_key_ccid                  -- 資産キーCCID
          ,key_segment1                    -- 資産キーセグメント1
          ,key_segment2                    -- 資産キーセグメント2
          ,parent_asset_id                 -- 親資産ID
          ,lease_id                        -- リースID
          ,model_number                    -- モデル
          ,in_use_flag                     -- 使用状況
          ,inventorial                     -- 実地棚卸フラグ
          ,owned_leased                    -- 所有権
          ,new_used                        -- 新品/中古
          ,cat_attribute1                  -- カテゴリDFF1
          ,cat_attribute3                  -- カテゴリDFF3
          ,cat_attribute4                  -- カテゴリDFF4
          ,cat_attribute5                  -- カテゴリDFF5
          ,cat_attribute6                  -- カテゴリDFF6
          ,cat_attribute7                  -- カテゴリDFF7
          ,cat_attribute8                  -- カテゴリDFF8
          ,cat_attribute9                  -- カテゴリDFF9
          ,cat_attribute10                 -- カテゴリDFF10
          ,cat_attribute11                 -- カテゴリDFF11
          ,cat_attribute12                 -- カテゴリDFF12
          ,cat_attribute13                 -- カテゴリDFF13
          ,cat_attribute14                 -- カテゴリDFF14
          ,cat_attribute15                 -- カテゴリDFF15
          ,cat_attribute16                 -- カテゴリDFF16
          ,cat_attribute17                 -- カテゴリDFF17
          ,cat_attribute18                 -- カテゴリDFF18
          ,cat_attribute19                 -- カテゴリDFF19
          ,cat_attribute20                 -- カテゴリDFF20
          ,cat_attribute21                 -- カテゴリDFF21
          ,cat_attribute22                 -- カテゴリDFF22
          ,cat_attribute23                 -- カテゴリDFF23
          ,cat_attribute24                 -- カテゴリDFF24
          ,cat_attribute25                 -- カテゴリDFF27
          ,cat_attribute26                 -- カテゴリDFF25
          ,cat_attribute27                 -- カテゴリDFF26
          ,cat_attribute28                 -- カテゴリDFF28
          ,cat_attribute29                 -- カテゴリDFF29
          ,cat_attribute30                 -- カテゴリDFF30
          ,cat_attribute_category_new      -- 資産カテゴリコード（修正後）
          ,salvage_value                   -- 残存価額
          ,percent_salvage_value           -- 残存価額%
          ,allowed_deprn_limit_amount      -- 償却限度額
          ,allowed_deprn_limit             -- 償却限度率
          ,ytd_deprn                       -- 年償却累計額
          ,deprn_reserve                   -- 償却累計額
          ,depreciate_flag                 -- 償却費計上フラグ
          ,deprn_method_code               -- 償却方法
          ,basic_rate                      -- 普通償却率
          ,adjusted_rate                   -- 割増後償却率
          ,life_years                      -- 耐用年数
          ,life_months                     -- 月数
          ,bonus_rule                      -- ボーナスルール
          ,bonus_ytd_deprn                 -- ボーナス年償却累計額
          ,bonus_deprn_reserve             -- ボーナス償却累計額
          ,created_by                      -- 作成者
          ,creation_date                   -- 作成日
          ,last_updated_by                 -- 最終更新者
          ,last_update_date                -- 最終更新日
          ,last_update_login               -- 最終更新ログインID
          ,request_id                      -- リクエストID
          ,program_application_id          -- アプリケーションID
          ,program_id                      -- プログラムID
          ,program_update_date             -- プログラム最終更新日
        ) VALUES (
           xx01_adjustment_oif_s.NEXTVAL                           -- ID
          ,gv_fixed_asset_register                                 -- 台帳名
          ,lv_asset_number_old                                     -- 資産番号
          ,ld_dpis_old                                             -- 事業供用日（修正前）
          ,ln_category_id_old                                      -- 資産カテゴリID（修正前）
          ,lv_cat_attribute_category_old                           -- 資産カテゴリコード（修正前）
          ,g_date_placed_in_service_tab(ln_loop_cnt)               -- 事業供用日（修正後）
          ,lv_description                                          -- 摘要（修正後）
          ,g_transaction_units_tab(ln_loop_cnt)                    -- 単位
          ,lv_attribute2                                           -- カテゴリDFF2
          ,g_cost_tab(ln_loop_cnt)                                 -- 取得価額
          ,g_original_cost_tab(ln_loop_cnt)                        -- 当初取得価額
          ,cv_yes                                                  -- 転記チェックフラグ
          ,cv_status                                               -- ステータス
          ,lv_amortized_flag                                       -- 修正額償却フラグ
          ,ld_amortization_start_date                              -- 償却開始日
          ,lv_asset_number_new                                     -- 資産番号（修正後）
          ,lv_tag_number                                           -- 現品票番号
          ,ln_category_id_new                                      -- 資産カテゴリID（修正後）
          ,lv_serial_number                                        -- シリアル番号
          ,ln_asset_key_ccid                                       -- 資産キーCCID
          ,lv_key_segment1                                         -- 資産キーセグメント1
          ,lv_key_segment2                                         -- 資産キーセグメント2
          ,ln_parent_asset_id                                      -- 親資産ID
          ,ln_lease_id                                             -- リースID
          ,lv_model_number                                         -- モデル
          ,lv_in_use_flag                                          -- 使用状況
          ,lv_inventorial                                          -- 実地棚卸フラグ
          ,lv_owned_leased                                         -- 所有権
          ,lv_new_used                                             -- 新品/中古
          ,lv_cat_attribute1                                       -- カテゴリDFF1
          ,lv_cat_attribute3                                       -- カテゴリDFF3
          ,lv_cat_attribute4                                       -- カテゴリDFF4
          ,lv_cat_attribute5                                       -- カテゴリDFF5
          ,lv_cat_attribute6                                       -- カテゴリDFF6
          ,lv_cat_attribute7                                       -- カテゴリDFF7
          ,lv_cat_attribute8                                       -- カテゴリDFF8
          ,lv_cat_attribute9                                       -- カテゴリDFF9
          ,lv_cat_attribute10                                      -- カテゴリDFF10
          ,lv_cat_attribute11                                      -- カテゴリDFF11
          ,lv_cat_attribute12                                      -- カテゴリDFF12
          ,lv_cat_attribute13                                      -- カテゴリDFF13
          ,lv_cat_attribute14                                      -- カテゴリDFF14
          ,lv_cat_attribute15                                      -- カテゴリDFF15
          ,lv_cat_attribute16                                      -- カテゴリDFF16
          ,lv_cat_attribute17                                      -- カテゴリDFF17
          ,lv_cat_attribute18                                      -- カテゴリDFF18
          ,lv_cat_attribute19                                      -- カテゴリDFF19
          ,lv_cat_attribute20                                      -- カテゴリDFF20
          ,lv_cat_attribute21                                      -- カテゴリDFF21
          ,lv_cat_attribute22                                      -- カテゴリDFF22
          ,lv_cat_attribute23                                      -- カテゴリDFF23
          ,lv_cat_attribute24                                      -- カテゴリDFF24
          ,lv_cat_attribute25                                      -- カテゴリDFF27
          ,lv_cat_attribute26                                      -- カテゴリDFF25
          ,lv_cat_attribute27                                      -- カテゴリDFF26
          ,lv_cat_attribute28                                      -- カテゴリDFF28
          ,lv_cat_attribute29                                      -- カテゴリDFF29
          ,lv_cat_attribute30                                      -- カテゴリDFF30
          ,lv_cat_attribute_category_new                           -- 資産カテゴリコード（修正後）
          ,ln_salvage_value                                        -- 残存価額
          ,ln_percent_salvage_value                                -- 残存価額%
          ,ln_allowed_deprn_limit_amount                           -- 償却限度額
          ,ln_allowed_deprn_limit                                  -- 償却限度率
          ,ln_ytd_deprn                                            -- 年償却累計額
          ,ln_deprn_reserve                                        -- 償却累計額
          ,lv_depreciate_flag                                      -- 償却費計上フラグ
          ,lv_deprn_method_code                                    -- 償却方法
          ,ln_basic_rate                                           -- 普通償却率
          ,ln_adjusted_rate                                        -- 割増後償却率
          ,ln_life_years                                           -- 耐用年数+月数
          ,ln_life_months                                          -- 月数
          ,lv_bonus_rule                                           -- ボーナスルール
          ,ln_bonus_ytd_deprn                                      -- ボーナス年償却累計額
          ,ln_bonus_deprn_reserve                                  -- ボーナス償却累計額
          ,cn_created_by                                           -- 作成者
          ,cd_creation_date                                        -- 作成日
          ,cn_last_updated_by                                      -- 最終更新者
          ,cd_last_update_date                                     -- 最終更新日
          ,cn_last_update_login                                    -- 最終更新ログインID
          ,cn_request_id                                           -- リクエストID
          ,cn_program_application_id                               -- アプリケーションID
          ,cn_program_id                                           -- プログラムID
          ,cd_program_update_date                                  -- プログラム最終更新日
        )
        ;
--
        --==============================================================
        -- 自販機物件履歴の更新（修正） (A-6-4)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_104                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 自販機物件(修正)登録件数カウント
        gn_vd_modify_normal_cnt := gn_vd_modify_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_modify_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_017a03_t_014) -- 自販機物件管理
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 取得件数がゼロ件のエラーハンドラ ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_vd_object_modify_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_trnsf_data
   * Description      : 自販機物件（移動）登録データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_vd_object_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_trnsf_data'; -- プログラム名
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_lang_ja           CONSTANT VARCHAR2(2)   := 'JA';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_count_0           CONSTANT NUMBER        := 0;
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
--
    -- *** ローカル変数 ***
    lv_warnmsg                VARCHAR2(5000);  -- 警告メッセージ
    lv_warn_flg               VARCHAR2(1);     -- 警告フラグ
    lv_asset_number           VARCHAR2(15);    -- 資産番号
    lv_comp_cd                VARCHAR2(25);    -- 会社コード
    lv_segment4               VARCHAR2(25);    -- 減価償却費勘定セグメント-勘定科目
    lv_modify_flg             VARCHAR2(1);     -- 変更フラグ
    ln_current_units          NUMBER;          -- 単位数量
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機物件（移動）カーソル
    CURSOR vd_object_trnsf_cur
    IS
      SELECT
             vohe.object_header_id                   AS object_header_id        -- 物件ID
            ,vohe.object_code                        AS object_code             -- 物件コード
            ,vohe.moved_date                         AS moved_date              -- 移動日
            ,vohe.machine_type                       AS machine_type            -- 機器区分
            ,vohe.dclr_place                         AS dclr_place              -- 申告地
            ,vohe.department_code                    AS department_code         -- 管理部門
            ,vohe.location                           AS location                -- 事業所
            ,substrb(vohe.installation_address,1,30) AS installation_address    -- 設置場所
            ,vohe.owner_company_type                 AS owner_company_type      -- 本社工場区分
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- 物件ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- 自販機物件履歴
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA未連携
                                        AND voh.process_type = cv_status_103 -- 移動
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
      ;
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
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN vd_object_trnsf_cur;
    -- データの一括取得
    FETCH vd_object_trnsf_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- 物件ID
                      ,g_object_code_tab             -- 物件コード
                      ,g_moved_date_tab              -- 移動日
                      ,g_machine_type_tab            -- 機器区分
                      ,g_dclr_place_tab              -- 申告地
                      ,g_department_code_tab         -- 管理部門
                      ,g_location_tab                -- 事業所
                      ,g_installation_address_tab    -- 設置場所
                      ,g_owner_company_type_tab      -- 本社工場区分
    ;
    -- 移動対象件数カウント
    gn_vd_trnsf_target_cnt := g_object_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE vd_object_trnsf_cur;
--
    IF ( gn_vd_trnsf_target_cnt = cn_count_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_017a03_t_016) -- 自販機物件（移動）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理②
    --==============================================================
    <<vd_object_trnsf_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- 警告フラグを初期化する
      lv_warn_flg := cv_no;
      -- 処理中の件数取得
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- 項目値チェック（移動） (A-5-1)
      --==============================================================
      -- 1.移動日の存在チェックをする
      IF ( g_moved_date_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグに'Y'をセット
        lv_warn_flg := cv_yes;
        -- 移動スキップ件数カウント
        gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_030)                     -- 移動日
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.機器区分の存在チェックをする
      IF ( g_machine_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_026)                     -- 機器区分
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.申告地の存在チェックをする
      IF ( g_dclr_place_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_031)                     -- 申告地
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.管理部門の存在チェックをする
      IF ( g_department_code_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_032)                     -- 管理部門
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 5.事業所の存在チェックをする
      IF ( g_location_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_033)                     -- 事業所
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 6.設置場所の存在チェックをする
      IF ( g_installation_address_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_034)                     -- 設置場所
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 7.本社/工場区分の存在チェックをする
      IF ( g_owner_company_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_035)                     -- 本社/工場区分
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 移動日の日付チェック処理
      -- 移動日が存在する場合
      IF ( g_moved_date_tab(ln_loop_cnt) IS NOT NULL ) THEN
        -- カレンダ期間クローズ日を取得していない場合
        IF ( g_cal_per_close_date IS NULL ) THEN
          BEGIN
            -- 最新のカレンダ期間クローズ日を取得
            SELECT
                   MAX(fdp.calendar_period_close_date)               -- カレンダ期間クローズ日
            INTO
                   g_cal_per_close_date
            FROM   fa_deprn_periods     fdp                          -- 減価償却期間
            WHERE
                   fdp.book_type_code   = gv_fixed_asset_register    -- 台帳種類
            AND    fdp.period_close_date IS NOT NULL                 -- クローズ済
            ;
          EXCEPTION
            -- カレンダ期間クローズ日が取得できない場合
            WHEN NO_DATA_FOUND THEN
                          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- 取得エラー
                                                          ,cv_tkn_table            -- トークン'TABLE_NAME'
                                                          ,cv_msg_017a03_t_015     -- 減価償却期間
                                                          ,cv_tkn_info             -- トークン'INFO'
                                                          ,cv_msg_017a03_t_018)    -- カレンダ期間クローズ日
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
          END;
        END IF;
        -- 移動日がカレンダ期間クローズ日以前の場合
        IF ( trunc(g_moved_date_tab(ln_loop_cnt)) <= trunc(g_cal_per_close_date) ) THEN
          -- 警告フラグが'N'の場合
          IF ( lv_warn_flg = cv_no ) THEN
            -- 警告フラグに'Y'をセット
            lv_warn_flg := cv_yes;
            -- 移動スキップ件数カウント
            gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
          END IF;
          -- 警告メッセージをセット
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_022                      -- 自販機物件FA連携項目存在チェックエラー
                                                         ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                         ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                         ,cv_tkn_param_name                        -- トークン'param_name'
                                                         ,cv_msg_017a03_t_030)                     -- 移動日
                                                         ,1
                                                         ,2000);
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
      END IF;
--
      -- 警告フラグが'N'の場合
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- 固定資産情報取得（移動） (A-5-2)
        --==============================================================
        BEGIN
          SELECT 
                 fab.asset_number   -- 資産番号
                ,fab.current_units  -- 単位数量
          INTO
                 lv_asset_number    -- 資産番号
                ,ln_current_units   -- 単位数量
          FROM
                fa_additions_b  fab
               ,fa_books        fb
          WHERE
                fab.tag_number      = g_object_code_tab(ln_loop_cnt)
          AND   fab.asset_id        = fb.asset_id
          AND   fb.book_type_code   = gv_fixed_asset_register
          AND   fb.date_ineffective IS NULL
          ;
        EXCEPTION
          -- 固定資産情報が取得できない場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- 取得エラー
                                                          ,cv_tkn_table            -- トークン'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- 資産詳細情報
                                                          ,cv_tkn_info             -- トークン'INFO'
                                                          ,cv_msg_017a03_t_017)    -- 固定資産（移動）情報
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        --==============================================================
        -- 減価償却費勘定セグメント値取得 (A-5-3)
        --==============================================================
        -- 会社コードに本社コードを設定
        lv_comp_cd := gv_comp_cd_itoen;
--
        -- 減価償却勘定の償却科目を取得
        BEGIN
          SELECT 
                 flv.attribute4   -- 償却科目
          INTO
                 lv_segment4      -- 勘定科目
          FROM
                fnd_lookup_values  flv
          WHERE
                flv.lookup_type  = cv_asset_category_id
          AND   flv.lookup_code  = g_machine_type_tab(ln_loop_cnt)
          AND   flv.language     = cv_lang_ja
          AND   flv.enabled_flag = cv_yes
          AND   TRUNC(cd_od_sysdate) BETWEEN TRUNC(NVL(flv.start_date_active, cd_od_sysdate)) 
                                         AND TRUNC(NVL(flv.end_date_active, cd_od_sysdate))
          ;
        EXCEPTION
          -- 減価償却勘定の償却科目が取得できない場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_019     -- 参照タイプ取得エラー
                                                          ,cv_tkn_lookup_type      -- トークン'LOOKUP_TYPE'
                                                          ,cv_msg_017a03_t_024)    -- 自販機資産カテゴリ固定値
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        --==============================================================
        -- 移動OIF登録 (A-5-4)
        --==============================================================
--
        -- セグメント値配列設定(SEG1:会社) : 本社コードを設定
        g_segments_tab(1) := gv_comp_cd_itoen;
        -- セグメント値配列設定(SEG3:勘定科目) : A-5-3で取得した償却科目を設定
        g_segments_tab(3) := lv_segment4;
--
        -- 移動詳細情報変更チェックを呼出、情報の変更有無をチェックする
        chk_object_trnsf_data(
           iv_object_code          => g_object_code_tab(ln_loop_cnt)          -- 物件コード
          ,iv_dclr_place           => g_dclr_place_tab(ln_loop_cnt)           -- 申告地
          ,iv_department_code      => g_department_code_tab(ln_loop_cnt)      -- 管理部門
          ,iv_location             => g_location_tab(ln_loop_cnt)             -- 事業所
          ,iv_installation_address => g_installation_address_tab(ln_loop_cnt) -- 場所
          ,iv_owner_company_type   => g_owner_company_type_tab(ln_loop_cnt)   -- 本社工場区分
          ,iv_modify_flg           => lv_modify_flg                           -- 変更フラグ
          ,ov_errbuf               => lv_errbuf                               -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode              => lv_retcode                              -- リターン・コード             --# 固定 #
          ,ov_errmsg               => lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 変更がある場合
        IF ( lv_modify_flg = cv_yes ) THEN
          -- 移動OIF登録
          INSERT INTO xx01_transfer_oif(
             transfer_oif_id           -- ID
            ,book_type_code            -- 台帳名
            ,asset_number              -- 資産番号
            ,transaction_date_entered  -- 振替日
            ,transaction_units         -- 単位変更
            ,posting_flag              -- 転記チェックフラグ
            ,status                    -- ステータス
            ,segment1                  -- 減価償却費勘定セグメント-会社
            ,segment2                  -- 減価償却費勘定セグメント-部門
            ,segment3                  -- 減価償却費勘定セグメント-勘定科目
            ,segment4                  -- 減価償却費勘定セグメント-補助科目
            ,segment5                  -- 減価償却費勘定セグメント-顧客
            ,segment6                  -- 減価償却費勘定セグメント-企業
            ,segment7                  -- 減価償却費勘定セグメント-予備1
            ,segment8                  -- 減価償却費勘定セグメント-予備2
            ,loc_segment1              -- 申告地
            ,loc_segment2              -- 管理部門
            ,loc_segment3              -- 事業所
            ,loc_segment4              -- 場所
            ,loc_segment5              -- 本社工場区分
            ,created_by                -- 作成者
            ,creation_date             -- 作成日
            ,last_updated_by           -- 最終更新者
            ,last_update_date          -- 最終更新日
            ,last_update_login         -- 最終更新ログインID
            ,request_id                -- リクエストID
            ,program_application_id    -- アプリケーションID
            ,program_id                -- プログラムID
            ,program_update_date       -- プログラム最終更新日
          ) VALUES (
             xx01_transfer_oif_s.NEXTVAL              -- ID
            ,gv_fixed_asset_register                  -- 台帳名
            ,lv_asset_number                          -- 資産番号
            ,g_moved_date_tab(ln_loop_cnt)            -- 振替日
            ,ln_current_units                         -- 単位変更
            ,cv_yes                                   -- 転記チェックフラグ
            ,cv_status                                -- ステータス
            ,lv_comp_cd                               -- 減価償却費勘定セグメント-会社
            ,gv_dep_cd_chosei                         -- 減価償却費勘定セグメント-部門
            ,lv_segment4                              -- 減価償却費勘定セグメント-勘定科目
            ,cv_sub_acct_dummy                        -- 減価償却費勘定セグメント-補助科目
            ,cv_ptnr_cd_dummy                         -- 減価償却費勘定セグメント-顧客
            ,cv_busi_cd_dummy                         -- 減価償却費勘定セグメント-企業
            ,cv_project_dummy                         -- 減価償却費勘定セグメント-予備1
            ,cv_future_dummy                          -- 減価償却費勘定セグメント-予備2
            ,g_dclr_place_tab(ln_loop_cnt)            -- 申告地
            ,g_department_code_tab(ln_loop_cnt)       -- 管理部門
            ,g_location_tab(ln_loop_cnt)              -- 事業所
            ,g_installation_address_tab(ln_loop_cnt)  -- 場所
            ,g_owner_company_type_tab(ln_loop_cnt)    -- 本社工場区分
            ,cn_created_by                            -- 作成者
            ,cd_creation_date                         -- 作成日
            ,cn_last_updated_by                       -- 最終更新者
            ,cd_last_update_date                      -- 最終更新日
            ,cn_last_update_login                     -- 最終更新ログインID
            ,cn_request_id                            -- リクエストID
            ,cn_program_application_id                -- アプリケーションID
            ,cn_program_id                            -- プログラムID
            ,cd_program_update_date                   -- プログラム最終更新日
          )
          ;
        ELSE
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 移動スキップ件数カウント
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
          -- 警告メッセージをセット
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_023                      -- 自販機物件FA連携項目存在チェックエラー
                                                         ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                         ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt))                     -- 除・売却日
                                                         ,1
                                                         ,2000);
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
--
        --==============================================================
        -- 自販機物件履歴の更新（移動） (A-5-5)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_103                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 警告がない場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 自販機物件(移動)登録件数カウント
          gn_vd_trnsf_normal_cnt := gn_vd_trnsf_normal_cnt + 1;
        END IF;
--
      END IF;
--
    END LOOP vd_object_trnsf_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_017a03_t_014) -- 自販機物件管理
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 取得件数がゼロ件のエラーハンドラ ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_vd_object_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_add_data
   * Description      : 自販機物件（未確定）登録データ抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_vd_object_add_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_add_data'; -- プログラム名
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_lang_ja           CONSTANT VARCHAR2(2)   := 'JA';
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_date_type         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
    cv_posting_status    CONSTANT VARCHAR2(4)   := 'POST';
    cv_queue_name        CONSTANT VARCHAR2(4)   := 'POST';
    cv_depreciate_flag   CONSTANT VARCHAR2(3)   := 'YES';
    cv_asset_type        CONSTANT VARCHAR2(11)  := 'CAPITALIZED';
    cn_count_0           CONSTANT NUMBER        := 0;
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
--
    -- *** ローカル変数 ***
    lv_warnmsg                VARCHAR2(5000);  -- 警告メッセージ
    lv_warn_flg               VARCHAR2(1);     -- 警告フラグ
    lv_segment1               VARCHAR2(150);   -- 種類
    lv_segment2               VARCHAR2(150);   -- 償却申告
    lv_segment3               VARCHAR2(150);   -- 資産勘定
    lv_segment4               VARCHAR2(150);   -- 償却科目
    lv_segment5               VARCHAR2(150);   -- 耐用年数
    lv_segment6               VARCHAR2(150);   -- 償却方法
    lv_segment7               VARCHAR2(150);   -- リース種別
    lv_description            VARCHAR2(80);    -- 摘要
    lv_attribute2             VARCHAR2(150);   -- DFF02（取得日）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機物件（未確定）カーソル
    CURSOR vd_object_add_cur
    IS
      SELECT
             vohe.object_header_id                    AS object_header_id        -- 物件ID
            ,vohe.object_code                         AS object_code             -- 物件コード
            ,vohe.manufacturer_name                   AS manufacturer_name       -- メーカー名
            ,vohe.model                               AS model                   -- 機種
            ,vohe.age_type                            AS age_type                -- 年式
            ,vohe.machine_type                        AS machine_type            -- 機器区分
            ,vohe.date_placed_in_service              AS date_placed_in_service  -- 事業供用日
            ,vohe.assets_cost                         AS assets_cost             -- 取得価額
            ,vohe.quantity                            AS payables_units          -- AP数量
            ,vohe.quantity                            AS fixed_assets_units      -- 単位数量
            ,vohe.dclr_place                          AS dclr_place              -- 申告地
            ,vohe.department_code                     AS department_code         -- 管理部門
            ,vohe.location                            AS location                -- 事業所
            ,substrb(vohe.installation_address,1,30)  AS installation_address    -- 設置場所
            ,vohe.owner_company_type                  AS owner_company_type      -- 本社工場区分
            ,vohe.assets_cost                         AS payables_cost           -- 資産当初取得価額
            ,vohe.assets_date                         AS attribute2              -- DFF02（取得日）
            ,vohe.object_header_id                    AS attribute14             -- DFF14（自販機物件内部ID）
      FROM
            xxcff_vd_object_headers  vohe                            -- 自販機物件管理
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- 物件ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- 自販機物件履歴
                                      WHERE
                                             voh.fa_if_flag             =  cv_no                                       -- FA未連携
                                      AND    voh.process_type           =  cv_status_101                               -- 未確定
                                      AND    voh.date_placed_in_service <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- 会計期間
                                      )
      ORDER BY
            vohe.object_code                                         -- 物件コード昇順
        FOR UPDATE NOWAIT
      ;
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
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN vd_object_add_cur;
    -- データの一括取得
    FETCH vd_object_add_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- 物件ID
                      ,g_object_code_tab             -- 物件コード
                      ,g_manufacturer_name_tab       -- メーカー名
                      ,g_model_tab                   -- 機種
                      ,g_age_type_tab                -- 年式
                      ,g_machine_type_tab            -- 機器区分
                      ,g_date_placed_in_service_tab  -- 事業供用日
                      ,g_assets_cost_tab             -- 取得価額
                      ,g_payables_units_tab          -- AP数量
                      ,g_fixed_assets_units_tab      -- 単位数量
                      ,g_dclr_place_tab              -- 申告地
                      ,g_department_code_tab         -- 管理部門
                      ,g_location_tab                -- 事業所
                      ,g_installation_address_tab    -- 設置場所
                      ,g_owner_company_type_tab      -- 本社工場区分
                      ,g_payables_cost_tab           -- 資産当初取得価額
                      ,g_assets_date_tab             -- DFF02（取得日）
                      ,g_object_internal_id_tab      -- DFF14（自販機物件内部ID）
    ;
    -- 未確定対象件数カウント
    gn_vd_add_target_cnt := g_object_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE vd_object_add_cur;
--
    IF ( gn_vd_add_target_cnt = cn_count_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_017a03_t_013) -- 自販機物件（未確定）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理①
    --==============================================================
    <<vd_object_add_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- 警告フラグを初期化する
      lv_warn_flg := cv_no;
      -- 処理中の件数取得
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- 項目値チェック（未確定） (A-4-1)
      --==============================================================
      -- 1.摘要の存在チェックをする
      IF ( g_manufacturer_name_tab(ln_loop_cnt)||g_model_tab(ln_loop_cnt)||g_age_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグに'Y'をセット
        lv_warn_flg := cv_yes;
        -- 未確定スキップ件数カウント
        gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_025)                     -- メーカー名 機種 年式
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.機器区分の存在チェックをする
      IF ( g_machine_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 未確定スキップ件数カウント
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_026)                     -- 機器区分
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.事業供用日の存在チェックをする
      IF ( g_date_placed_in_service_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 未確定スキップ件数カウント
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_027)                     -- 事業供用日
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.取得価格（取得価額）の存在チェックをする
      IF ( g_assets_cost_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 未確定スキップ件数カウント
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_028)                     -- 取得価格
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 5.数量（AP数量）の存在チェックをする
      IF ( g_payables_units_tab(ln_loop_cnt) IS NULL ) THEN
        -- 警告フラグがNの場合
        IF ( lv_warn_flg = cv_no ) THEN
          -- 警告フラグに'Y'をセット
          lv_warn_flg := cv_yes;
          -- 未確定スキップ件数カウント
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- 警告メッセージをセット
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- 自販機物件FA連携項目存在チェックエラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- 物件コード
                                                       ,cv_tkn_param_name                        -- トークン'param_name'
                                                       ,cv_msg_017a03_t_029)                     -- 数量
                                                       ,1
                                                       ,2000);
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 警告フラグが'N'の場合
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- 資産カテゴリCCID取得 (A-4-2)
        --==============================================================
        -- 資産カテゴリのセグメント値を取得する
        BEGIN
          SELECT 
                 attribute1  -- 種類
                ,attribute2  -- 償却申告
                ,attribute3  -- 資産勘定
                ,attribute4  -- 償却科目
                ,attribute5  -- 耐用年数
                ,attribute6  -- 償却方法
                ,attribute7  -- リース種別
          INTO
                 lv_segment1  -- 種類
                ,lv_segment2  -- 償却申告
                ,lv_segment3  -- 資産勘定
                ,lv_segment4  -- 償却科目
                ,lv_segment5  -- 耐用年数
                ,lv_segment6  -- 償却方法
                ,lv_segment7  -- リース種別
          FROM
                fnd_lookup_values  flv
          WHERE
                flv.lookup_type  = cv_asset_category_id
          AND   flv.lookup_code  = g_machine_type_tab(ln_loop_cnt)
          AND   flv.language     = cv_lang_ja
          AND   flv.enabled_flag = cv_yes
          AND   TRUNC(cd_od_sysdate) BETWEEN TRUNC(NVL(flv.start_date_active, cd_od_sysdate)) 
                                         AND TRUNC(NVL(flv.end_date_active, cd_od_sysdate))
          ;
        EXCEPTION
          -- 資産カテゴリのセグメント値の取得件数がゼロ件の場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_019     -- 取得エラー
                                                          ,cv_tkn_lookup_type      -- トークン'LOOKUP_TYPE'
                                                          ,cv_msg_017a03_t_024)    -- 自販機資産カテゴリ固定値
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
        -- 資産カテゴリの組合せチェックおよび、資産カテゴリCCIDを取得
        xxcff_common1_pkg.chk_fa_category(
           iv_segment1      => lv_segment1 -- 種類
          ,iv_segment2      => lv_segment2 -- 償却申告
          ,iv_segment3      => lv_segment3 -- 資産勘定
          ,iv_segment4      => lv_segment4 -- 償却科目
          ,iv_segment5      => lv_segment5 -- 耐用年数
          ,iv_segment6      => lv_segment6 -- 償却方法
          ,iv_segment7      => lv_segment7 -- リース種別
          ,on_category_id   => g_category_ccid_tab(ln_loop_cnt)  -- 資産カテゴリCCID
          ,ov_errbuf        => lv_errbuf                         -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode       => lv_retcode                        -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 減価償却費勘定CCID取得 (A-4-3)
        --==============================================================
--
        -- セグメント値配列設定(SEG1:会社) : 本社コードを設定
        g_segments_tab(1) := gv_comp_cd_itoen;
        -- セグメント値配列設定(SEG3:勘定科目) : A-4-2で取得した償却科目を設定
        g_segments_tab(3) := lv_segment4;
--
        -- 減価償却費勘定CCID取得
        get_deprn_ccid(
           iot_segments     => g_segments_tab                  -- セグメント値配列
          ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- 減価償却費勘定CCID
          ,ov_errbuf        => lv_errbuf                       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode       => lv_retcode                      -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 事業所CCID取得 (A-4-4)
        --==============================================================
        xxcff_common1_pkg.chk_fa_location(
           iv_segment1      => g_dclr_place_tab(ln_loop_cnt)           -- 申告地
          ,iv_segment2      => g_department_code_tab(ln_loop_cnt)      -- 管理部門
          ,iv_segment3      => g_location_tab(ln_loop_cnt)             -- 事業所
          ,iv_segment4      => g_installation_address_tab(ln_loop_cnt) -- 場所
          ,iv_segment5      => g_owner_company_type_tab(ln_loop_cnt)   -- 本社工場区分
          ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)        -- 事業所CCID
          ,ov_errbuf        => lv_errbuf                               -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode       => lv_retcode                              -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 追加OIF登録 (A-4-5)
        --==============================================================
        -- 摘要を取得する
        lv_description := SUBSTRB(g_manufacturer_name_tab(ln_loop_cnt) || ' ' ||
                                  g_model_tab(ln_loop_cnt) || ' ' ||
                                  g_age_type_tab(ln_loop_cnt)
                                  , 1, 80);
        -- DFF02(取得日)の取得
        IF (g_assets_date_tab(ln_loop_cnt) IS NULL) THEN
          -- DFF02(取得日)がNULLの時、事業供用日をYYYY/MM/DD型でセットする
          lv_attribute2 := to_char(g_date_placed_in_service_tab(ln_loop_cnt), cv_date_type);
        ELSE
          -- DFF02(取得日)が存在する時、DFF02(取得日)をYYYY/MM/DD型でセットする
          lv_attribute2 := to_char(g_assets_date_tab(ln_loop_cnt), cv_date_type);
        END IF;
--
        -- 追加OIF登録
        INSERT INTO fa_mass_additions(
           mass_addition_id              -- 追加OIF内部ID
          ,asset_number                  -- 資産番号
          ,tag_number                    -- 現伝票番号
          ,description                   -- 摘要
          ,asset_category_id             -- 資産カテゴリCCID
          ,book_type_code                -- 台帳
          ,date_placed_in_service        -- 事業供用日
          ,fixed_assets_cost             -- 取得価額
          ,payables_units                -- AP数量
          ,fixed_assets_units            -- 単位数量
          ,expense_code_combination_id   -- 減価償却費勘定CCID
          ,location_id                   -- 事業所フレックスフィールドCCID
          ,posting_status                -- 転記ステータス
          ,queue_name                    -- キュー名
          ,payables_cost                 -- 資産当初取得価額
          ,depreciate_flag               -- 償却費計上フラグ
          ,asset_type                    -- 資産タイプ
          ,attribute2                    -- DFF02（取得日）
          ,attribute14                   -- DFF14（自販機物件内部ID）
          ,last_update_date              -- 最終更新日
          ,last_updated_by               -- 最終更新者
          ,created_by                    -- 作成者ID
          ,creation_date                 -- 作成日
          ,last_update_login             -- 最終更新ログインID
        ) VALUES (
           fa_mass_additions_s.NEXTVAL               -- 追加OIF内部ID
          ,NULL                                      -- 資産番号
          ,g_object_code_tab(ln_loop_cnt)            -- 現伝票番号
          ,lv_description                            -- 摘要
          ,g_category_ccid_tab(ln_loop_cnt)          -- 資産カテゴリCCID
          ,gv_fixed_asset_register                   -- 台帳
          ,g_date_placed_in_service_tab(ln_loop_cnt) -- 事業供用日
          ,g_assets_cost_tab(ln_loop_cnt)            -- 取得価額
          ,g_payables_units_tab(ln_loop_cnt)         -- AP数量
          ,g_fixed_assets_units_tab(ln_loop_cnt)     -- 単位数量
          ,g_deprn_ccid_tab(ln_loop_cnt)             -- 減価償却費勘定CCID
          ,g_location_ccid_tab(ln_loop_cnt)          -- 事業所フレックスフィールドCCID
          ,cv_posting_status                         -- 転記ステータス
          ,cv_queue_name                             -- キュー名
          ,g_assets_cost_tab(ln_loop_cnt)            -- 資産当初取得価額
          ,cv_depreciate_flag                        -- 償却費計上フラグ
          ,cv_asset_type                             -- 資産タイプ
          ,lv_attribute2                             -- DFF02（取得日）
          ,g_object_internal_id_tab(ln_loop_cnt)     -- DFF14（自販機物件内部ID）
          ,cd_last_update_date                       -- 最終更新日
          ,cn_last_updated_by                        -- 最終更新者
          ,cn_created_by                             -- 作成者ID
          ,cd_creation_date                          -- 作成日
          ,cn_last_update_login                      -- 最終更新ログインID
        )
        ;
--
        --==============================================================
        -- 自販機物件管理の更新（未確定） (A-4-6)
        --==============================================================
        update_vd_object_headers(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_102                        -- 物件ステータス
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 自販機物件履歴の更新（未確定） (A-4-7)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_101                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 更新に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- 自販機物件履歴の作成（確定） (A-4-8)
        --==============================================================
        insert_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- 物件ID
          ,iv_object_status     => cv_status_102                        -- 処理区分
          ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 作成に失敗した場合、処理中止
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 自販機物件(未確定)登録件数カウント
        gn_vd_add_normal_cnt := gn_vd_add_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_add_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_017a03_t_014) -- 自販機物件管理
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 取得件数がゼロ件のエラーハンドラ ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_vd_object_add_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
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
    cv_yes                   CONSTANT VARCHAR2(1)     := 'Y';
--
    -- *** ローカル変数 ***
    lv_deprn_run              VARCHAR2(1);  -- 資産台帳名
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
    -- コンカレントパラメータがない場合
    IF (gv_period_name IS NULL) THEN
      -- 最新の会計期間名を取得する
      SELECT 
             MAX(fdp.period_name)                              -- 最新会計期間名
      INTO
             gv_period_name
      FROM
             fa_deprn_periods     fdp                          -- 減価償却期間
      WHERE
             fdp.book_type_code   = gv_fixed_asset_register    -- 台帳種類
      ;
      -- 最新会計期間が取得できない場合
      IF (gv_period_name IS NULL) THEN
        RAISE chk_period_name_expt;
      END IF;
    END IF;

    BEGIN
      -- 会計期間チェック
      SELECT
             fdp.deprn_run        AS deprn_run      -- 減価償却実行フラグ
        INTO
             lv_deprn_run
        FROM
             fa_deprn_periods     fdp   -- 減価償却期間
       WHERE
             fdp.book_type_code    = gv_fixed_asset_register
         AND fdp.period_name       = gv_period_name
         AND fdp.period_close_date IS NULL
           ;
    EXCEPTION
      -- 会計期間の取得件数がゼロ件の場合
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- 減価償却が実行されている場合
    IF lv_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間名取得エラーハンドラ ***
    WHEN chk_period_name_expt THEN
      -- 警告メッセージをセット
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                     ,cv_msg_017a03_m_024                      -- 最新会計期間名取得警告
                                                     ,cv_tkn_param_name                        -- トークン'PARAM_NAME'
                                                     ,gv_fixed_asset_register)                 -- 台帳種類
                                                     ,1
                                                     ,2000);
      -- 警告メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 終了ステータスは警告とする
      ov_retcode := cv_status_warn;
--
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- 警告メッセージをセット
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                    ,cv_msg_017a03_m_011     -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type          -- トークン'BOOK_TYPE_CODE'
                                                    ,gv_fixed_asset_register -- 資産台帳名
                                                    ,cv_tkn_period           -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)         -- 会計期間名
                                                    ,1
                                                    ,5000);
      -- 警告メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 終了ステータスは警告とする
      ov_retcode := cv_status_warn;
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
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
    -- XXCFF:会社コード_本社
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_017a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_017a03_t_010) -- XXCFF:会社コード_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:部門コード_調整部門
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_017a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_017a03_t_011) -- XXCFF:部門コード_調整部門
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_017a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_017a03_t_012) -- XXCFF:台帳種類_固定資産台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:按分方法_月末
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_017a03_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_017a03_t_037) -- XXCFF:按分方法_月末
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
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
    cn_count_1   CONSTANT NUMBER        := 1;
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
--
    -- グローバル変数の初期化
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_vd_target_cnt         := 0;
    gn_vd_add_target_cnt     := 0;
    gn_vd_add_normal_cnt     := 0;
    gn_vd_add_warn_cnt       := 0;
    gn_vd_add_error_cnt      := 0;
    gn_vd_trnsf_target_cnt   := 0;
    gn_vd_trnsf_normal_cnt   := 0;
    gn_vd_trnsf_warn_cnt     := 0;
    gn_vd_trnsf_error_cnt    := 0;
    gn_vd_modify_target_cnt  := 0;
    gn_vd_modify_normal_cnt  := 0;
    gn_vd_modify_warn_cnt    := 0;
    gn_vd_modify_error_cnt   := 0;
    gn_vd_retire_target_cnt  := 0;
    gn_vd_retire_normal_cnt  := 0;
    gn_vd_retire_warn_cnt    := 0;
    gn_vd_retire_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-3で警告がない場合、処理を継続する
    IF (lv_retcode = cv_status_normal) THEN
      -- =========================================
      -- 自販機物件（未確定）登録データ抽出 (A-4)
      -- =========================================
      get_vd_object_add_data(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- A-4がエラーの場合
      IF (lv_retcode = cv_status_error) THEN
        -- エラー件数を1件とする
        gn_vd_add_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 自販機物件（移動）登録データ抽出理 (A-5)
      -- =========================================
      get_vd_object_trnsf_data(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- A-5がエラーの場合
      IF (lv_retcode = cv_status_error) THEN
        -- エラー件数を1件とする
        gn_vd_trnsf_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 自販機物件（修正）登録データ抽出 (A-6)
      -- =========================================
      get_vd_object_modify_data(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- A-6がエラーの場合
      IF (lv_retcode = cv_status_error) THEN
        -- エラー件数を1件とする
        gn_vd_modify_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 自販機物件（除売却未確定）登録データ抽出 (A-7)
      -- =========================================
      get_vd_object_ritire_data(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- A-7がエラーの場合
      IF (lv_retcode = cv_status_error) THEN
        -- エラー件数を1件とする
        gn_vd_retire_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN  VARCHAR2       --   1.会計期間名
  )
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
    cn_count_0         CONSTANT NUMBER        := 0;
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
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
  /**********************************************************************************
   * Description      : 終了処理(A-9)
   ***********************************************************************************/
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
      -- 対象件数がカウントされている場合
      IF ( gn_vd_target_cnt    > 0 ) THEN
        -- 連携エラーの自販機物件情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_020                      -- 自販機物件FA連携エラー
                                                       ,cv_tkn_param_val1                        -- トークン'PARAM_VAL1'
                                                       ,g_object_header_id_tab(gn_vd_target_cnt) -- 物件ID
                                                       ,cv_tkn_param_val2                        -- トークン'PARAM_VAL2'
                                                       ,g_object_code_tab(gn_vd_target_cnt))     -- 物件コード
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 1件でも警告があった場合
    ELSIF (gn_vd_add_warn_cnt +
           gn_vd_trnsf_warn_cnt +
           gn_vd_modify_warn_cnt +
           gn_vd_retire_warn_cnt > cn_count_0) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    -- 対象件数が0件だった場合
    ELSIF ( gn_vd_add_target_cnt +
            gn_vd_trnsf_target_cnt +
            gn_vd_modify_target_cnt +
            gn_vd_retire_target_cnt = cn_count_0 ) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --自販機物件（未確定）登録処理における件数出力
    --===============================================================
    --自販機物件（未確定）作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_014
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --自販機物件（移動）登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --自販機物件（移動）作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --自販機物件（修正）登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --自販機物件（修正）作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_016
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --自販機物件（除売却未確定）登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --自販機物件（除売却未確定）作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_error_cnt)
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
END XXCFF017A03C;
/
