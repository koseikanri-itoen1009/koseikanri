CREATE OR REPLACE PACKAGE APPS.xxcso_012001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_012001j_pkg(SPEC)
 * Description      : 物件情報汎用検索共通関数
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_extract_term          F    V      物件汎用検索条件取得関数
 *  get_sp_dec_header_id      F    V      有効最新SP専決ヘッダID取得関数
 *  get_dept_code             F    V      拠点コード取得関数
 *  get_vendor_type           F    V      機器区分取得関数
 *  get_account_number        F    V      顧客コード取得関数
 *  get_party_name            F    V      顧客名取得関数
 *  get_lease_start_date      F    D      リース開始年月日取得関数
 *  get_first_charge          F    N      初回月額リース料取得関数
 *  get_second_charge         F    N      2回目以降月額リース料取得関数
 *  get_address1              F    V      設置住所1取得関数
 *  get_address2              F    V      設置住所2取得関数
 *  get_install_industry_type F    V      設置業種区分取得関数
 *  get_contract_number       F    N      契約書番号取得関数
 *  get_resource_name         F    V      担当者名取得関数
 *  get_area_code             F    N      地区コード取得関数
 *  get_orig_lease_contract_number F  V   原契約番号取得関数
 *  get_orig_lease_branch_number F    N   原契約番号-枝番取得関数
 *  get_party_name_phonetic   F    V      顧客名(カナ)取得関数
 *  get_lease_contract_date   F    D      現契約年月日取得関数
 *  get_lease_contract_number F    V      リース現契約番号取得関数
 *  get_lease_branch_number   F    N      リース現契約番号枝番取得関数
 *  get_lease_status          F    V      リース状態(再リース)取得関数
 *  get_payment_frequency     F    V      支払回数取得関数
 *  get_lease_end_date        F    D      リース終了年月日取得関数
 *  get_sp_decision_number    F    N      SP専決番号取得関数
 *  get_install_location      F    V      VD設置場所取得関数
 *  get_vendor_form           F    V      業態(小分類)取得関数
 *  get_last_party_name       F    V      顧客名(引揚前)関数
 *  get_last_install_place_name F  V      設置先名(引揚前)関数
 *  get_purchase_amount       F    N      購入金額取得関数
 *  get_cancellation_date     F    D      リース解約年月日取得関数
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   N.Yanagitaira    新規作成
 *  2009/06/25    1.1   N.Yanagitaira    [障害0000142]FUNCTION型不正対応
 *
 *****************************************************************************************/
--
  -- 物件汎用検索条件取得関数
  FUNCTION get_extract_term(
    iv_column_code          IN  VARCHAR2,
    iv_extract_method_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 有効最新SP専決ヘッダID取得関数
  FUNCTION get_sp_dec_header_id(
    it_cust_account_id   IN  xxcso_cust_accounts_v.cust_account_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_header_id%TYPE;
--
  -- 拠点コード取得関数
  FUNCTION get_dept_code(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.sale_base_code%TYPE;
--
  -- 機器区分取得関数
  FUNCTION get_vendor_type(
    it_hazard_class_id   IN  po_un_numbers_vl.hazard_class_id%TYPE
  )
  RETURN po_hazard_classes_vl.hazard_class%TYPE;
--
  -- 顧客コード取得関数
  FUNCTION get_account_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.account_number%TYPE;
--
  -- 顧客名取得関数
  FUNCTION get_party_name(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE;
--
  -- リース開始年月日取得関数
  FUNCTION get_lease_start_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_start_date%TYPE;
--
  -- 初回月額リース料取得関数
  FUNCTION get_first_charge(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.first_charge%TYPE;
--
  -- 2回目以降月額リース料取得関数
  FUNCTION get_second_charge(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.second_charge%TYPE;
--
  -- 設置住所1取得関数
  FUNCTION get_address1(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address1%TYPE;
--
  -- 設置住所2取得関数
  FUNCTION get_address2(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address2%TYPE;
--
  -- 設置業種区分取得関数
  FUNCTION get_install_industry_type(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- 契約書番号取得関数
  FUNCTION get_contract_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_contract_managements.contract_number%TYPE;
--
  -- 担当者名取得関数
  FUNCTION get_resource_name(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_employees_v2.full_name%TYPE;
--
  -- 地区コード取得関数
  FUNCTION get_area_code(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
-- 20090625_N.Yanagitaira 0000142 Mod START
--  RETURN NUMBER
  RETURN xxcso_cust_acct_sites_v.area_code%TYPE;
-- 20090625_N.Yanagitaira 0000142 Mod END
--
  -- 原契約番号取得関数
  FUNCTION get_orig_lease_contract_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE;
--
  -- 原契約番号-枝番取得関数
  FUNCTION get_orig_lease_branch_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE;
--
  -- 顧客名(カナ)取得関数
  FUNCTION get_party_name_phonetic(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.organization_name_phonetic%TYPE;
--
  -- 現契約年月日取得関数
  FUNCTION get_lease_contract_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_date%TYPE;
--
  -- リース現契約番号取得関数
  FUNCTION get_lease_contract_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE;
--
  -- リース現契約番号枝番取得関数
  FUNCTION get_lease_branch_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE;
--
  -- リース状態(再リース)取得関数
  FUNCTION get_lease_status(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN fnd_lookup_values_vl.description%TYPE;
--
  -- 支払回数取得関数
  FUNCTION get_payment_frequency(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.payment_frequency%TYPE;
--
  -- リース終了年月日取得関数
  FUNCTION get_lease_end_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_end_date%TYPE;
--
  -- SP専決番号取得関数
  FUNCTION get_sp_decision_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_number%TYPE;
--
  -- VD設置場所取得関数
  FUNCTION get_install_location(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- 業態(小分類)取得関数
  FUNCTION get_vendor_form(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- 顧客名(引揚前)関数
  FUNCTION get_last_party_name(
    it_ven_kyaku_last    IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE;
--
  -- 設置先名(引揚前)関数
  FUNCTION get_last_install_place_name(
    it_ven_kyaku_last    IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.established_site_name%TYPE;
--
  -- 購入金額取得関数
  FUNCTION get_purchase_amount(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.estimated_cash_price%TYPE;
--
  -- リース解約年月日取得関数
  FUNCTION get_cancellation_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.cancellation_date%TYPE;
--
END xxcso_012001j_pkg;
/
