CREATE OR REPLACE PACKAGE APPS.xxcso_012001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_012001j_pkg(SPEC)
 * Description      : �������ėp�������ʊ֐�
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_extract_term          F    V      �����ėp���������擾�֐�
 *  get_sp_dec_header_id      F    V      �L���ŐVSP�ꌈ�w�b�_ID�擾�֐�
 *  get_dept_code             F    V      ���_�R�[�h�擾�֐�
 *  get_vendor_type           F    V      �@��敪�擾�֐�
 *  get_account_number        F    V      �ڋq�R�[�h�擾�֐�
 *  get_party_name            F    V      �ڋq���擾�֐�
 *  get_lease_start_date      F    D      ���[�X�J�n�N�����擾�֐�
 *  get_first_charge          F    N      ���񌎊z���[�X���擾�֐�
 *  get_second_charge         F    N      2��ڈȍ~���z���[�X���擾�֐�
 *  get_address1              F    V      �ݒu�Z��1�擾�֐�
 *  get_address2              F    V      �ݒu�Z��2�擾�֐�
 *  get_install_industry_type F    V      �ݒu�Ǝ�敪�擾�֐�
 *  get_contract_number       F    N      �_�񏑔ԍ��擾�֐�
 *  get_resource_name         F    V      �S���Җ��擾�֐�
 *  get_area_code             F    N      �n��R�[�h�擾�֐�
 *  get_orig_lease_contract_number F  V   ���_��ԍ��擾�֐�
 *  get_orig_lease_branch_number F    N   ���_��ԍ�-�}�Ԏ擾�֐�
 *  get_party_name_phonetic   F    V      �ڋq��(�J�i)�擾�֐�
 *  get_lease_contract_date   F    D      ���_��N�����擾�֐�
 *  get_lease_contract_number F    V      ���[�X���_��ԍ��擾�֐�
 *  get_lease_branch_number   F    N      ���[�X���_��ԍ��}�Ԏ擾�֐�
 *  get_lease_status          F    V      ���[�X���(�ă��[�X)�擾�֐�
 *  get_payment_frequency     F    V      �x���񐔎擾�֐�
 *  get_lease_end_date        F    D      ���[�X�I���N�����擾�֐�
 *  get_sp_decision_number    F    N      SP�ꌈ�ԍ��擾�֐�
 *  get_install_location      F    V      VD�ݒu�ꏊ�擾�֐�
 *  get_vendor_form           F    V      �Ƒ�(������)�擾�֐�
 *  get_last_party_name       F    V      �ڋq��(���g�O)�֐�
 *  get_last_install_place_name F  V      �ݒu�於(���g�O)�֐�
 *  get_purchase_amount       F    N      �w�����z�擾�֐�
 *  get_cancellation_date     F    D      ���[�X���N�����擾�֐�
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   N.Yanagitaira    �V�K�쐬
 *  2009/06/25    1.1   N.Yanagitaira    [��Q0000142]FUNCTION�^�s���Ή�
 *
 *****************************************************************************************/
--
  -- �����ėp���������擾�֐�
  FUNCTION get_extract_term(
    iv_column_code          IN  VARCHAR2,
    iv_extract_method_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �L���ŐVSP�ꌈ�w�b�_ID�擾�֐�
  FUNCTION get_sp_dec_header_id(
    it_cust_account_id   IN  xxcso_cust_accounts_v.cust_account_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_header_id%TYPE;
--
  -- ���_�R�[�h�擾�֐�
  FUNCTION get_dept_code(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.sale_base_code%TYPE;
--
  -- �@��敪�擾�֐�
  FUNCTION get_vendor_type(
    it_hazard_class_id   IN  po_un_numbers_vl.hazard_class_id%TYPE
  )
  RETURN po_hazard_classes_vl.hazard_class%TYPE;
--
  -- �ڋq�R�[�h�擾�֐�
  FUNCTION get_account_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.account_number%TYPE;
--
  -- �ڋq���擾�֐�
  FUNCTION get_party_name(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE;
--
  -- ���[�X�J�n�N�����擾�֐�
  FUNCTION get_lease_start_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_start_date%TYPE;
--
  -- ���񌎊z���[�X���擾�֐�
  FUNCTION get_first_charge(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.first_charge%TYPE;
--
  -- 2��ڈȍ~���z���[�X���擾�֐�
  FUNCTION get_second_charge(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.second_charge%TYPE;
--
  -- �ݒu�Z��1�擾�֐�
  FUNCTION get_address1(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address1%TYPE;
--
  -- �ݒu�Z��2�擾�֐�
  FUNCTION get_address2(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address2%TYPE;
--
  -- �ݒu�Ǝ�敪�擾�֐�
  FUNCTION get_install_industry_type(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- �_�񏑔ԍ��擾�֐�
  FUNCTION get_contract_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_contract_managements.contract_number%TYPE;
--
  -- �S���Җ��擾�֐�
  FUNCTION get_resource_name(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_employees_v2.full_name%TYPE;
--
  -- �n��R�[�h�擾�֐�
  FUNCTION get_area_code(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
-- 20090625_N.Yanagitaira 0000142 Mod START
--  RETURN NUMBER
  RETURN xxcso_cust_acct_sites_v.area_code%TYPE;
-- 20090625_N.Yanagitaira 0000142 Mod END
--
  -- ���_��ԍ��擾�֐�
  FUNCTION get_orig_lease_contract_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE;
--
  -- ���_��ԍ�-�}�Ԏ擾�֐�
  FUNCTION get_orig_lease_branch_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE;
--
  -- �ڋq��(�J�i)�擾�֐�
  FUNCTION get_party_name_phonetic(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.organization_name_phonetic%TYPE;
--
  -- ���_��N�����擾�֐�
  FUNCTION get_lease_contract_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_date%TYPE;
--
  -- ���[�X���_��ԍ��擾�֐�
  FUNCTION get_lease_contract_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE;
--
  -- ���[�X���_��ԍ��}�Ԏ擾�֐�
  FUNCTION get_lease_branch_number(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE;
--
  -- ���[�X���(�ă��[�X)�擾�֐�
  FUNCTION get_lease_status(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN fnd_lookup_values_vl.description%TYPE;
--
  -- �x���񐔎擾�֐�
  FUNCTION get_payment_frequency(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.payment_frequency%TYPE;
--
  -- ���[�X�I���N�����擾�֐�
  FUNCTION get_lease_end_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_end_date%TYPE;
--
  -- SP�ꌈ�ԍ��擾�֐�
  FUNCTION get_sp_decision_number(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_number%TYPE;
--
  -- VD�ݒu�ꏊ�擾�֐�
  FUNCTION get_install_location(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- �Ƒ�(������)�擾�֐�
  FUNCTION get_vendor_form(
    it_install_party_id  IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE;
--
  -- �ڋq��(���g�O)�֐�
  FUNCTION get_last_party_name(
    it_ven_kyaku_last    IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE;
--
  -- �ݒu�於(���g�O)�֐�
  FUNCTION get_last_install_place_name(
    it_ven_kyaku_last    IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.established_site_name%TYPE;
--
  -- �w�����z�擾�֐�
  FUNCTION get_purchase_amount(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.estimated_cash_price%TYPE;
--
  -- ���[�X���N�����擾�֐�
  FUNCTION get_cancellation_date(
    it_install_code      IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.cancellation_date%TYPE;
--
END xxcso_012001j_pkg;
/
