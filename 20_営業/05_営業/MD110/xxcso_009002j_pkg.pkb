CREATE OR REPLACE PACKAGE BODY APPS.xxcso_009002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_009002j_pkg(BODY)
 * Description      : 顧客情報セキュリティ
 * MD.050/070       : 
 * Version          : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  init_transaction            P  -     トランザクション初期化
 *  get_party_upd_prdct         F  V     パーティ（HZ_PARTIES）更新時の追加条件取得
 *  get_org_pro_ext_ins_prdct   F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）作成時の
 *                                       追加条件取得
 *  get_org_pro_ext_upd_prdct   F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）更新時の
 *                                       追加条件取得
 *  get_org_pro_ext_del_prdct   F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）削除時の
 *                                       追加条件取得
 *  get_location_upd_prdct      F  V     所在地（HZ_LOCATIONS）更新時の追加条件取得
 *  get_account_ins_prdct       F  V     アカウント（HZ_CUST_ACCOUNTS）作成時の追加条件取得
 *  get_account_upd_prdct       F  V     アカウント（HZ_CUST_ACCOUNTS）更新時の追加条件取得
 *  get_acct_site_ins_prdct     F  V     アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）作成時の追加条件取得
 *  get_site_use_ins_prdct      F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）作成時の追加条件取得
 *  get_site_use_upd_prdct      F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）更新時の追加条件取得
 *  get_site_use_del_prdct      F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）削除時の追加条件取得
 *  get_lead_upd_prdct          F  V     商談（AS_LEADS_ALL）更新時の追加条件取得
 *  get_task_ins_prdct          F  V     タスク（JTF_TASKS_B）作成時の追加条件取得
 *  get_task_upd_prdct          F  V     タスク（JTF_TASKS_B）更新時の追加条件取得
 *  get_task_del_prdct          F  V     タスク（JTF_TASKS_B）削除時の追加条件取得
 *  chk_party_upd_enabled       F  V     パーティ（HZ_PARTIES）更新可能チェック
 *  chk_org_pro_ext_ins_enabled F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）
 *                                       作成可能チェック
 *  chk_org_pro_ext_upd_enabled F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）
 *                                       更新可能チェック
 *  chk_org_pro_ext_del_enabled F  V     組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）
 *                                       削除可能チェック
 *  chk_location_upd_enabled    F  V     所在地（HZ_LOCATIONS）更新可能チェック
 *  chk_account_ins_enabled     F  V     アカウント（HZ_CUST_ACCOUNTS）作成可能チェック
 *  chk_account_upd_enabled     F  V     アカウント（HZ_CUST_ACCOUNTS）更新可能チェック
 *  chk_acct_site_ins_enabled   F  V     アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）
 *                                       作成可能チェック
 *  chk_site_use_ins_enabled    F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）作成可能チェック
 *  chk_site_use_upd_enabled    F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）更新可能チェック
 *  chk_site_use_del_enabled    F  V     サイト使用目的（HZ_CUST_SITE_USES_ALL）削除可能チェック
 *  chk_lead_upd_enabled        F  V     商談（AS_LEADS_ALL）更新可能チェック
 *  chk_task_ins_enabled        F  V     タスク（JTF_TASKS_B）作成可能チェック
 *  chk_task_upd_enabled        F  V     タスク（JTF_TASKS_B）更新可能チェック
 *  chk_task_del_enabled        F  V     タスク（JTF_TASKS_B）削除可能チェック
 *  get_security_class_name     F  V     セキュリティ実装クラス名取得
 *  chk_customer_status         P  -     顧客ステータスチェック
 *  get_cust_descriptive_info   P  -     顧客追加情報取得
 *  get_login_user_info         P  -     ログインユーザー情報取得
 *  chk_within_parent_sale_base F  V     売上拠点の1つ上の組織配下かどうかのチェック
 *  get_sales_person            F  V     担当営業員取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Ogawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2009-06-02    1.2   M.Ohtsuki        T1_0956対応
 *  2009-12-07    1.3   T.Maruyama       E_本稼動_00111対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_009002j_pkg';   -- パッケージ名
  gv_sec_level_oco    CONSTANT VARCHAR2(1)   := '1';
  gv_sec_level_oso    CONSTANT VARCHAR2(1)   := '2';
  /* 2009.12.07 T.Maruyama E_本稼動_00111 START */
  gv_sec_level_oco_new CONSTANT VARCHAR2(1)  := '3'; --セキュリティ変更対応
  /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  security_except     EXCEPTION;
  PRAGMA EXCEPTION_INIT(security_except, -28115);
--
  /**********************************************************************************
   * Function Name    : get_party_upd_prdct
   * Description      : パーティ（HZ_PARTIES）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_party_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_party_upd_enabled(' ||
                         'PARTY_ID, DUNS_NUMBER_C, CREATED_BY) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_party_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_org_pro_ext_ins_prdct
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）作成時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_org_pro_ext_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_org_pro_ext_ins_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_org_pro_ext_ins_enabled(' ||
                          'ORGANIZATION_PROFILE_ID, C_EXT_ATTR1) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_org_pro_ext_ins_prdct;
--
  /**********************************************************************************
   * Function Name    : get_org_pro_ext_upd_prdct
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_org_pro_ext_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_org_pro_ext_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_org_pro_ext_upd_enabled(' ||
                          'ORGANIZATION_PROFILE_ID, C_EXT_ATTR1) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_org_pro_ext_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_org_pro_ext_del_prdct
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）削除時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_org_pro_ext_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_org_pro_ext_del_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_org_pro_ext_del_enabled(' ||
                          'ORGANIZATION_PROFILE_ID, C_EXT_ATTR1) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_org_pro_ext_del_prdct;
--
  /**********************************************************************************
   * Function Name    : get_location_upd_prdct
   * Description      : 所在地（HZ_LOCATIONS）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_location_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_location_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_location_upd_enabled(LOCATION_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_location_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_account_ins_prdct
   * Description      : アカウント（HZ_CUST_ACCOUNTS）作成時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_account_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_account_ins_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_account_ins_enabled(' ||
                          'PARTY_ID, CUST_ACCOUNT_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_account_ins_prdct;
--
  /**********************************************************************************
   * Function Name    : get_account_upd_prdct
   * Description      : アカウント（HZ_CUST_ACCOUNTS）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_account_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_account_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_account_upd_enabled(' ||
                          'PARTY_ID, CUST_ACCOUNT_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_account_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_acct_site_ins_prdct
   * Description      : アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）作成時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_acct_site_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_acct_site_ins_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_acct_site_ins_enabled(CUST_ACCOUNT_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_acct_site_ins_prdct;
--
  /**********************************************************************************
   * Function Name    : get_site_use_ins_prdct
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）作成時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_site_use_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_site_use_ins_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_site_use_ins_enabled(CUST_ACCT_SITE_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_site_use_ins_prdct;
--
  /**********************************************************************************
   * Function Name    : get_site_use_upd_prdct
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_site_use_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_site_use_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_site_use_upd_enabled(CUST_ACCT_SITE_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_site_use_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_site_use_del_prdct
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）削除時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_site_use_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_site_use_del_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_site_use_del_enabled(CUST_ACCT_SITE_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_site_use_del_prdct;
--
  /**********************************************************************************
   * Function Name    : get_lead_upd_prdct
   * Description      : 商談（AS_LEADS_ALL）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_lead_upd_prdct(
    iv_schema_name     IN  VARCHAR2
   ,iv_object_name     IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lead_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_lead_upd_enabled(CUSTOMER_ID) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_lead_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_task_ins_prdct
   * Description      : タスク（JTF_TASKS_B）作成時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_task_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_task_ins_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_task_ins_enabled(' ||
                          'SOURCE_OBJECT_ID, SOURCE_OBJECT_TYPE_CODE) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_task_ins_prdct;
--
  /**********************************************************************************
   * Function Name    : get_task_upd_prdct
   * Description      : タスク（JTF_TASKS_B）更新時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_task_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_task_upd_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_task_upd_enabled(' ||
                          'OWNER_ID, SOURCE_OBJECT_TYPE_CODE) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_task_upd_prdct;
--
  /**********************************************************************************
   * Function Name    : get_task_del_prdct
   * Description      : タスク（JTF_TASKS_B）削除時の追加条件取得
   ***********************************************************************************/
  FUNCTION get_task_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_task_del_prdct';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    lv_return_value := 'xxcso_009002j_pkg.chk_task_del_enabled(' ||
                          'OWNER_ID, SOURCE_OBJECT_TYPE_CODE) = ''1''';
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_task_del_prdct;
--
  /**********************************************************************************
   * Function Name    : chk_customer_status
   * Description      : 顧客ステータスチェック
   ***********************************************************************************/
  PROCEDURE chk_customer_status(
    iv_duns_number_c        IN  VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_customer_status';
    cn_limit_status              CONSTANT NUMBER          := 25;
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_duns_number_c             NUMBER;
--
  BEGIN
--
    BEGIN
      ln_duns_number_c := TO_NUMBER(iv_duns_number_c);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE security_except;
    END;
--
    IF ( ln_duns_number_c >= cn_limit_status ) THEN
      RAISE security_except;
    END IF;
--
  END chk_customer_status;
--
  /**********************************************************************************
   * Function Name    : get_cust_descriptive_info
   * Description      : 顧客追加情報取得
   ***********************************************************************************/
  PROCEDURE get_cust_descriptive_info(
    in_cust_account_id      IN  NUMBER
   ,ov_sale_base_code       OUT VARCHAR2
   ,ov_mng_base_code        OUT VARCHAR2
   ,ov_mng_sale_base_code   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_cust_descriptive_info';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
--
    SELECT  xca1.sale_base_code
           ,xca1.management_base_code
           ,xca2.sale_base_code
    INTO    ov_sale_base_code
           ,ov_mng_base_code
           ,ov_mng_sale_base_code
    FROM    xxcmm_cust_accounts  xca1
           ,xxcmm_cust_accounts  xca2
    WHERE   xca1.customer_id      = in_cust_account_id
    AND     xca2.customer_code(+) = xca1.management_base_code
    ;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_sale_base_code     := NULL;
      ov_mng_base_code      := NULL;
      ov_mng_sale_base_code := NULL;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_cust_descriptive_info;
--
  /**********************************************************************************
   * Function Name    : get_login_user_info
   * Description      : ログインユーザー情報取得
   ***********************************************************************************/
  PROCEDURE get_login_user_info(
    ov_employee_number      OUT VARCHAR2
   ,ov_work_base_code       OUT VARCHAR2
   ,ov_job_type_code        OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_login_user_info';
    -- ===============================
    -- ローカル変数
    -- ===============================
--
  BEGIN
--
    SELECT  xev.employee_number
           ,xxcso_util_common_pkg.get_emp_parameter(
              xev.work_base_code_new
             ,xev.work_base_code_old
             ,xev.issue_date
             ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
            )
           ,xxcso_util_common_pkg.get_emp_parameter(
              xev.job_type_code_new
             ,xev.job_type_code_old
             ,xev.issue_date
             ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
            )
    INTO    ov_employee_number
           ,ov_work_base_code
           ,ov_job_type_code
    FROM    xxcso_employees_v2   xev
    WHERE   xev.user_id    = fnd_global.user_id
    ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_login_user_info;
--
  /**********************************************************************************
   * Function Name    : chk_within_parent_sale_base
   * Description      : 売上拠点の1つ上の組織配下かどうかのチェック
   ***********************************************************************************/
  FUNCTION chk_within_parent_sale_base(
    iv_work_base_code       IN  VARCHAR2
   ,iv_sale_base_code       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_within_parent_sale_base';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
--
  BEGIN
--
    lv_return_value := '1';
--
    BEGIN
--
      SELECT  '1'
      INTO    lv_return_value
      FROM    xxcso_aff_base_level_v2  xablv
      WHERE   xablv.base_code       = xxcso_util_common_pkg.get_parent_base_code(
                                        iv_work_base_code
                                       ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                      )
      AND     xablv.child_base_code = iv_sale_base_code
      AND     ROWNUM                = 1
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_return_value := '0';
    END;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_within_parent_sale_base;
--
  /**********************************************************************************
   * Function Name    : get_sales_person
   * Description      : 担当営業員取得
   ***********************************************************************************/
  FUNCTION get_sales_person(
    in_party_id             IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sales_person';
    cv_application_ar            CONSTANT VARCHAR2(2)     := 'AR';
    cv_desc_flexfield_name       CONSTANT VARCHAR2(30)    := 'HZ_ORG_PROFILES_GROUP';
    cv_flex_context_code         CONSTANT VARCHAR2(30)    := 'RESOURCE';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    BEGIN
      SELECT  hopeb.c_ext_attr1
      INTO    lv_sales_person
      FROM    hz_organization_profiles  hop
             ,fnd_application           fa
             ,ego_fnd_dsc_flx_ctx_ext   efdfce
             ,hz_org_profiles_ext_b     hopeb
      WHERE   hop.party_id                         = in_party_id
      AND     hop.effective_end_date IS NULL
      AND     fa.application_short_name            = cv_application_ar
      AND     efdfce.application_id                = fa.application_id
      AND     efdfce.descriptive_flexfield_name    = cv_desc_flexfield_name
      AND     efdfce.descriptive_flex_context_code = cv_flex_context_code
      AND     hopeb.attr_group_id                  = efdfce.attr_group_id
      AND     hopeb.organization_profile_id        = hop.organization_profile_id
      AND     hopeb.d_ext_attr1 <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(hopeb.d_ext_attr2, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     ROWNUM                               = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sales_person := NULL;
    END;
--
    RETURN lv_sales_person;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_sales_person;
--
  /**********************************************************************************
   * Function Name    : chk_party_upd_enabled
   * Description      : パーティ（HZ_PARTIES）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_party_upd_enabled(
    in_party_id            IN  NUMBER
   ,iv_duns_number_c       IN  VARCHAR2
   ,in_created_by          IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_party_upd_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => iv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      BEGIN
        SELECT  hca.cust_account_id
        INTO    ln_cust_account_id
        FROM    hz_cust_accounts     hca
        WHERE   hca.party_id       = in_party_id
        ;
--
        get_cust_descriptive_info(
          in_cust_account_id    => ln_cust_account_id
         ,ov_sale_base_code     => lv_sale_base_code
         ,ov_mng_base_code      => lv_mng_base_code
         ,ov_mng_sale_base_code => lv_mng_sale_base_code
        );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(in_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (in_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => iv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    ELSIF ( lv_security_level = gv_sec_level_oso ) THEN
--
      /* 20090602_Ohtsuki_T1_0956 START*/   -- 営業ダッシュボードからの顧客の更新はすべて可能にする。
/*
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => iv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(in_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( lv_sales_person = lv_employee_number ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--
*/
      RETURN '1';
      /* 20090602_Ohtsuki_T1_0956 END */
    END IF;
--
    RETURN lv_return_value;
--
  END chk_party_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_org_pro_ext_ins_enabled
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）作成可能チェック
   ***********************************************************************************/
  FUNCTION chk_org_pro_ext_ins_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_org_pro_ext_ins_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
 
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_org_pro_ext_ins_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_org_pro_ext_upd_enabled
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_org_pro_ext_upd_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_org_pro_ext_upd_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_org_pro_ext_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_org_pro_ext_del_enabled
   * Description      : 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）削除可能チェック
   ***********************************************************************************/
  FUNCTION chk_org_pro_ext_del_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_org_pro_ext_del_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_organization_profiles  hop
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hop.organization_profile_id = in_org_profile_id
      AND     hp.party_id                 = hop.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_org_pro_ext_del_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_location_upd_enabled
   * Description      : 所在地（HZ_LOCATIONS）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_location_upd_enabled(
    in_location_id         IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_location_upd_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_party_sites            hps
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hps.location_id             = in_location_id
      AND     hp.party_id                 = hps.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_party_sites            hps
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hps.location_id             = in_location_id
      AND     hp.party_id                 = hps.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    ELSIF ( lv_security_level = gv_sec_level_oso ) THEN
--
      /* 20090602_Ohtsuki_T1_0956 START*/   -- 営業ダッシュボードからの顧客の更新はすべて可能にする。
/*
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者ID、アカウントIDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_party_sites            hps
             ,hz_parties                hp
             ,hz_cust_accounts          hca
      WHERE   hps.location_id             = in_location_id
      AND     hp.party_id                 = hps.party_id
      AND     hca.party_id(+)             = hp.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( lv_sales_person = lv_employee_number ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--
*/
      RETURN '1';
      /* 20090602_Ohtsuki_T1_0956 END */
    END IF;
--
    RETURN lv_return_value;
--
  END chk_location_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_account_ins_enabled
   * Description      : アカウント（HZ_CUST_ACCOUNTS）作成可能チェック
   ***********************************************************************************/
  FUNCTION chk_account_ins_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_account_ins_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_parties                hp
      WHERE   hp.party_id                 = in_party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => in_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(in_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_parties                hp
      WHERE   hp.party_id                 = in_party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_account_ins_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_account_upd_enabled
   * Description      : アカウント（HZ_CUST_ACCOUNTS）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_account_upd_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_account_upd_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_parties                hp
      WHERE   hp.party_id                 = in_party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => in_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(in_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_parties                hp
      WHERE   hp.party_id                 = in_party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_account_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_acct_site_ins_enabled
   * Description      : アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）作成可能チェック
   ***********************************************************************************/
  FUNCTION chk_acct_site_ins_enabled(
    in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_acct_site_ins_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hca.cust_account_id         = in_cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => in_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
      FROM    hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hca.cust_account_id         = in_cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_acct_site_ins_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_site_use_ins_enabled
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）作成可能チェック
   ***********************************************************************************/
  FUNCTION chk_site_use_ins_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_site_use_ins_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_site_use_ins_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_site_use_upd_enabled
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_site_use_upd_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_site_use_upd_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_site_use_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_site_use_del_enabled
   * Description      : サイト使用目的（HZ_CUST_SITE_USES_ALL）削除可能チェック
   ***********************************************************************************/
  FUNCTION chk_site_use_del_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_site_use_del_enabled';
    cv_job_type_inter            CONSTANT VARCHAR2(2)     := '03';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_duns_number_c             hz_parties.duns_number_c%TYPE;
    ln_created_by                hz_parties.created_by%TYPE;
    ln_cust_account_id           hz_cust_accounts.cust_account_id%TYPE;
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_mng_base_code             xxcmm_cust_accounts.management_base_code%TYPE;
    lv_mng_sale_base_code        xxcmm_cust_accounts.sale_base_code%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_base_code                 fnd_flex_values.flex_value%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oco ) THEN
--
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
--
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--
      -------------------------------------------------------------------------
      -- 売上拠点コード、管理元拠点コードを取得
      -------------------------------------------------------------------------
      get_cust_descriptive_info(
        in_cust_account_id    => ln_cust_account_id
       ,ov_sale_base_code     => lv_sale_base_code
       ,ov_mng_base_code      => lv_mng_base_code
       ,ov_mng_sale_base_code => lv_mng_sale_base_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
      -------------------------------------------------------------------------
      get_login_user_info(
        ov_employee_number  => lv_employee_number
       ,ov_work_base_code   => lv_work_base_code
       ,ov_job_type_code    => lv_job_type_code
      );
--
      -------------------------------------------------------------------------
      -- ログインユーザーの勤務地拠点が売上拠点の場合正常終了
      -------------------------------------------------------------------------
      IF ( lv_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点かどうか
      -------------------------------------------------------------------------
      IF ( lv_mng_sale_base_code = lv_work_base_code ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているか
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが内務員で
      -- 売上拠点の管理元拠点がログインユーザーの勤務地拠点の
      -- 一つ上の組織（AFF部門マスタ上）の配下の拠点に含まれているかを確認
      -------------------------------------------------------------------------
      IF ( (lv_job_type_code = cv_job_type_inter) AND (lv_mng_sale_base_code IS NOT NULL) ) THEN
--
        lv_return_value := chk_within_parent_sale_base(lv_work_base_code, lv_mng_sale_base_code);
        IF ( lv_return_value = '1' ) THEN
          RETURN '1';
        END IF;
--
      END IF;
--
      -------------------------------------------------------------------------
      -- 担当営業員を取得
      -------------------------------------------------------------------------
      lv_sales_person := get_sales_person(ln_party_id);
--
      -------------------------------------------------------------------------
      -- ログインユーザーが担当営業員か
      -------------------------------------------------------------------------
      IF ( (lv_sale_base_code IS NULL) AND (lv_sales_person = lv_employee_number) ) THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- ログインユーザーが作成者か
      -------------------------------------------------------------------------
      IF (  (lv_sale_base_code IS NULL)
        AND (lv_sales_person   IS NULL)
        AND (ln_created_by = fnd_global.user_id)
         )
      THEN
        RETURN '1';
      END IF;
--
      -------------------------------------------------------------------------
      -- どれにも引っかからない場合は、セキュリティ違反
      -------------------------------------------------------------------------
      RAISE security_except;
--  
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */    
    ELSIF ( lv_security_level = gv_sec_level_oco_new ) THEN
      
      -------------------------------------------------------------------------
      -- パーティID、顧客ステータス、作成者IDを取得
      -------------------------------------------------------------------------
      SELECT  hp.party_id
             ,hp.duns_number_c
             ,hp.created_by
             ,hca.cust_account_id
      INTO    ln_party_id
             ,lv_duns_number_c
             ,ln_created_by
             ,ln_cust_account_id
      FROM    hz_cust_acct_sites        hcas
             ,hz_cust_accounts          hca
             ,hz_parties                hp
      WHERE   hcas.cust_acct_site_id      = in_cust_acct_site_id
      AND     hca.cust_account_id         = hcas.cust_account_id
      AND     hp.party_id                 = hca.party_id
      ;
      
      -------------------------------------------------------------------------
      -- 顧客ステータスを確認
      -------------------------------------------------------------------------
      chk_customer_status(
        iv_duns_number_c => lv_duns_number_c
      );
--      
      RETURN '1';
--    
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_site_use_del_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_lead_upd_enabled
   * Description      : 商談（AS_LEADS_ALL）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_lead_upd_enabled(
    in_customer_id         IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_lead_upd_enabled';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_CUST_SECURITY_LEVEL');
--
    IF ( lv_security_level = gv_sec_level_oso ) THEN
--
      BEGIN
--
        SELECT  '1'
        INTO    lv_return_value
        FROM    hz_organization_profiles  hop
               ,fnd_application           fa
               ,ego_fnd_dsc_flx_ctx_ext   efdfce
               ,xxcso_employees_v2        xev
               ,hz_org_profiles_ext_b     hopeb
        WHERE   hop.party_id                         = in_customer_id
        AND     hop.effective_end_date IS NULL
        AND     fa.application_short_name            = 'AR'
        AND     efdfce.application_id                = fa.application_id
        AND     efdfce.descriptive_flexfield_name    = 'HZ_ORG_PROFILES_GROUP'
        AND     efdfce.descriptive_flex_context_code = 'RESOURCE'
        AND     xev.user_id                          = fnd_global.user_id
        AND     hopeb.attr_group_id                  = efdfce.attr_group_id
        AND     hopeb.c_ext_attr1                    = xev.employee_number
        AND     hopeb.organization_profile_id        = hop.organization_profile_id
        AND     hopeb.d_ext_attr1
                  <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        AND     NVL(hopeb.d_ext_attr2, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_return_value := '0';
      END;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END chk_lead_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_task_ins_enabled
   * Description      : タスク（JTF_TASKS_B）作成可能チェック
   ***********************************************************************************/
  FUNCTION chk_task_ins_enabled(
    in_source_object_id    IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_task_ins_enabled';
    cv_source_object_party       CONSTANT VARCHAR2(30)    := 'PARTY';
    cv_source_object_opportunity CONSTANT VARCHAR2(30)    := 'OPPORTUNITY';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_party_id                  hz_parties.party_id%TYPE;
    lv_employee_number           xxcso_employees_v2.employee_number%TYPE;
    lv_work_base_code            xxcso_employees_v2.work_base_code_new%TYPE;
    lv_job_type_code             xxcso_employees_v2.job_type_code_new%TYPE;
    lv_sales_person              hz_org_profiles_ext_b.c_ext_attr1%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_TASK_SECURITY_LEVEL');
--
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */
    --IF ( lv_security_level = gv_sec_level_oco ) THEN
    IF ( lv_security_level = gv_sec_level_oco ) OR
    ( lv_security_level = gv_sec_level_oco_new ) THEN
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
        -------------------------------------------------------------------------
        get_login_user_info(
          ov_employee_number  => lv_employee_number
         ,ov_work_base_code   => lv_work_base_code
         ,ov_job_type_code    => lv_job_type_code
        );
--
        -------------------------------------------------------------------------
        -- 担当営業員を取得
        -------------------------------------------------------------------------
        lv_sales_person := get_sales_person(in_source_object_id);
--
        -------------------------------------------------------------------------
        -- ログインユーザーが担当営業員か
        -------------------------------------------------------------------------
        IF ( lv_sales_person = lv_employee_number ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RAISE security_except;
--
      END IF;
--
    ELSIF ( lv_security_level = gv_sec_level_oso ) THEN
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
        -------------------------------------------------------------------------
        get_login_user_info(
          ov_employee_number  => lv_employee_number
         ,ov_work_base_code   => lv_work_base_code
         ,ov_job_type_code    => lv_job_type_code
        );
--
        -------------------------------------------------------------------------
        -- 担当営業員を取得
        -------------------------------------------------------------------------
        lv_sales_person := get_sales_person(in_source_object_id);
--
        -------------------------------------------------------------------------
        -- ログインユーザーが担当営業員か
        -------------------------------------------------------------------------
        IF ( lv_sales_person = lv_employee_number ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_opportunity ) THEN
--
        -------------------------------------------------------------------------
        -- 顧客IDを取得
        -------------------------------------------------------------------------
        SELECT  ala.customer_id
        INTO    ln_party_id
        FROM    as_leads_all   ala
        WHERE   ala.lead_id    = in_source_object_id
        ;
--
        -------------------------------------------------------------------------
        -- ログインユーザーの従業員番号、勤務地拠点コード、職種コードを取得
        -------------------------------------------------------------------------
        get_login_user_info(
          ov_employee_number  => lv_employee_number
         ,ov_work_base_code   => lv_work_base_code
         ,ov_job_type_code    => lv_job_type_code
        );
--
        -------------------------------------------------------------------------
        -- 担当営業員を取得
        -------------------------------------------------------------------------
        lv_sales_person := get_sales_person(ln_party_id);
--
        -------------------------------------------------------------------------
        -- ログインユーザーが担当営業員か
        -------------------------------------------------------------------------
        IF ( lv_sales_person = lv_employee_number ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RAISE security_except;
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_task_ins_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_task_upd_enabled
   * Description      : タスク（JTF_TASKS_B）更新可能チェック
   ***********************************************************************************/
  FUNCTION chk_task_upd_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_task_upd_enabled';
    cv_source_object_party       CONSTANT VARCHAR2(30)    := 'PARTY';
    cv_source_object_opportunity CONSTANT VARCHAR2(30)    := 'OPPORTUNITY';
    cv_source_object_task        CONSTANT VARCHAR2(30)    := 'TASK';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_user_id                   xxcso_resources_v2.user_id%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_TASK_SECURITY_LEVEL');
--
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */
    --IF ( lv_security_level = gv_sec_level_oco ) THEN
    IF ( lv_security_level = gv_sec_level_oco ) OR
    ( lv_security_level = gv_sec_level_oco_new ) THEN
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_task ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      END IF;
--
    ELSIF ( lv_security_level = gv_sec_level_oso ) THEN
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_opportunity ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_task ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_task_upd_enabled;
--
  /**********************************************************************************
   * Function Name    : chk_task_del_enabled
   * Description      : タスク（JTF_TASKS_B）削除可能チェック
   ***********************************************************************************/
  FUNCTION chk_task_del_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_task_del_enabled';
    cv_source_object_party       CONSTANT VARCHAR2(30)    := 'PARTY';
    cv_source_object_opportunity CONSTANT VARCHAR2(30)    := 'OPPORTUNITY';
    cv_source_object_task        CONSTANT VARCHAR2(30)    := 'TASK';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_security_level            VARCHAR2(1);
    ln_user_id                   xxcso_resources_v2.user_id%TYPE;
--
  BEGIN
--
    lv_return_value := '1';
    lv_security_level := fnd_profile.value('XXCSO1_TASK_SECURITY_LEVEL');
--
    /* 2009.12.07 T.Maruyama E_本稼動_00111 START */
    --IF ( lv_security_level = gv_sec_level_oco ) THEN
    IF ( lv_security_level = gv_sec_level_oco ) OR
    ( lv_security_level = gv_sec_level_oco_new ) THEN
    /* 2009.12.07 T.Maruyama E_本稼動_00111 END */
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_task ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      END IF;
--
    ELSIF ( lv_security_level = gv_sec_level_oso ) THEN
--
      IF ( iv_source_object_type = cv_source_object_party ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_opportunity ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      ELSIF ( iv_source_object_type = cv_source_object_task ) THEN
--
        -------------------------------------------------------------------------
        -- 所有者がログインユーザーかどうか
        -------------------------------------------------------------------------
        SELECT  xrv.user_id
        INTO    ln_user_id
        FROM    xxcso_resources_v2  xrv
        WHERE   xrv.resource_id = in_owner_id
        ;
--
        IF ( ln_user_id = fnd_global.user_id ) THEN
          RETURN '1';
        END IF;
--
        -------------------------------------------------------------------------
        -- どれにも引っかからない場合は、セキュリティ違反
        -------------------------------------------------------------------------
        RETURN '0';
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
--
  END chk_task_del_enabled;
--
END xxcso_009002j_pkg;
/
