CREATE OR REPLACE PACKAGE APPS.xxcso_009002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_009002j_pkg(SPEC)
 * Description      : 顧客情報セキュリティ
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
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
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Ogawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  -- パーティ（HZ_PARTIES）更新時の追加条件取得
  FUNCTION get_party_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）作成時の追加条件取得
  FUNCTION get_org_pro_ext_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）更新時の追加条件取得
  FUNCTION get_org_pro_ext_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）削除時の追加条件取得
  FUNCTION get_org_pro_ext_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 所在地（HZ_LOCATIONS）更新時の追加条件取得
  FUNCTION get_location_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- アカウント（HZ_CUST_ACCOUNTS）作成時の追加条件取得
  FUNCTION get_account_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- アカウント（HZ_CUST_ACCOUNTS）更新時の追加条件取得
  FUNCTION get_account_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）作成時の追加条件取得
  FUNCTION get_acct_site_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）作成時の追加条件取得
  FUNCTION get_site_use_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）更新時の追加条件取得
  FUNCTION get_site_use_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）削除時の追加条件取得
  FUNCTION get_site_use_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 商談（AS_LEADS_ALL）更新時の追加条件取得
  FUNCTION get_lead_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）作成時の追加条件取得
  FUNCTION get_task_ins_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）更新時の追加条件取得
  FUNCTION get_task_upd_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）削除時の追加条件取得
  FUNCTION get_task_del_prdct(
    iv_schema_name         IN  VARCHAR2
   ,iv_object_name         IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- パーティ（HZ_PARTIES）更新可能チェック
  FUNCTION chk_party_upd_enabled(
    in_party_id            IN  NUMBER
   ,iv_duns_number_c       IN  VARCHAR2
   ,in_created_by          IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）作成可能チェック
  FUNCTION chk_org_pro_ext_ins_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）更新可能チェック
  FUNCTION chk_org_pro_ext_upd_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 組織プロファイル拡張（HZ_ORG_PROFILES_EXT_B）削除可能チェック
  FUNCTION chk_org_pro_ext_del_enabled(
    in_org_profile_id      IN  NUMBER
   ,iv_ext_attr1           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 所在地（HZ_LOCATIONS）更新可能チェック
  FUNCTION chk_location_upd_enabled(
    in_location_id         IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- アカウント（HZ_CUST_ACCOUNTS）作成可能チェック
  FUNCTION chk_account_ins_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- アカウント（HZ_CUST_ACCOUNTS）更新可能チェック
  FUNCTION chk_account_upd_enabled(
    in_party_id            IN  NUMBER
   ,in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- アカウント・サイト（HZ_CUST_ACCT_SITES_ALL）作成可能チェック
  FUNCTION chk_acct_site_ins_enabled(
    in_cust_account_id     IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）作成可能チェック
  FUNCTION chk_site_use_ins_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）更新可能チェック
  FUNCTION chk_site_use_upd_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- サイト使用目的（HZ_CUST_SITE_USES_ALL）削除可能チェック
  FUNCTION chk_site_use_del_enabled(
    in_cust_acct_site_id   IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- 商談（AS_LEADS_ALL）更新可能チェック
  FUNCTION chk_lead_upd_enabled(
    in_customer_id         IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）作成可能チェック
  FUNCTION chk_task_ins_enabled(
    in_source_object_id    IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）更新可能チェック
  FUNCTION chk_task_upd_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- タスク（JTF_TASKS_B）削除可能チェック
  FUNCTION chk_task_del_enabled(
    in_owner_id            IN  NUMBER
   ,iv_source_object_type  IN  VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_009002j_pkg;
/
