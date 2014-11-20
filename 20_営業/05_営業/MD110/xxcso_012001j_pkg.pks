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
    in_cust_account_id  IN  NUMBER
  )
  RETURN VARCHAR2;
--
  -- 拠点コード取得関数
  FUNCTION get_dept_code(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 機器区分取得関数
  FUNCTION get_vendor_type(
    iv_hazard_class_id   IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 顧客コード取得関数
  FUNCTION get_account_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 顧客名取得関数
  FUNCTION get_party_name(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- リース開始年月日取得関数
  FUNCTION get_lease_start_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- 初回月額リース料取得関数
  FUNCTION get_first_charge(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- 2回目以降月額リース料取得関数
  FUNCTION get_second_charge(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- 設置住所1取得関数
  FUNCTION get_address1(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 設置住所2取得関数
  FUNCTION get_address2(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 設置業種区分取得関数
  FUNCTION get_install_industry_type(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 契約書番号取得関数
  FUNCTION get_contract_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 担当者名取得関数
  FUNCTION get_resource_name(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 地区コード取得関数
  FUNCTION get_area_code(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- 原契約番号取得関数
  FUNCTION get_orig_lease_contract_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 原契約番号-枝番取得関数
  FUNCTION get_orig_lease_branch_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
--
  -- 顧客名(カナ)取得関数
  FUNCTION get_party_name_phonetic(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--

  -- 現契約年月日取得関数
  FUNCTION get_lease_contract_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- リース現契約番号取得関数
  FUNCTION get_lease_contract_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- リース現契約番号枝番取得関数
  FUNCTION get_lease_branch_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- リース状態(再リース)取得関数
  FUNCTION get_lease_status(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 支払回数取得関数
  FUNCTION get_payment_frequency(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- リース終了年月日取得関数
  FUNCTION get_lease_end_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- SP専決番号取得関数
  FUNCTION get_sp_decision_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- VD設置場所取得関数
  FUNCTION get_install_location(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 業態(小分類)取得関数
  FUNCTION get_vendor_form(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 顧客名(引揚前)関数
  FUNCTION get_last_party_name(
    iv_ven_kyaku_last  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 設置先名(引揚前)関数
  FUNCTION get_last_install_place_name(
    iv_ven_kyaku_last  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- 購入金額取得関数
  FUNCTION get_purchase_amount(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- リース解約年月日取得関数
  FUNCTION get_cancellation_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
END xxcso_012001j_pkg;
/
