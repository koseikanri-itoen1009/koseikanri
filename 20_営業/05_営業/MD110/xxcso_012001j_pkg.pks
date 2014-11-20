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
    in_cust_account_id  IN  NUMBER
  )
  RETURN VARCHAR2;
--
  -- ���_�R�[�h�擾�֐�
  FUNCTION get_dept_code(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �@��敪�擾�֐�
  FUNCTION get_vendor_type(
    iv_hazard_class_id   IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ڋq�R�[�h�擾�֐�
  FUNCTION get_account_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ڋq���擾�֐�
  FUNCTION get_party_name(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- ���[�X�J�n�N�����擾�֐�
  FUNCTION get_lease_start_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- ���񌎊z���[�X���擾�֐�
  FUNCTION get_first_charge(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- 2��ڈȍ~���z���[�X���擾�֐�
  FUNCTION get_second_charge(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- �ݒu�Z��1�擾�֐�
  FUNCTION get_address1(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ݒu�Z��2�擾�֐�
  FUNCTION get_address2(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ݒu�Ǝ�敪�擾�֐�
  FUNCTION get_install_industry_type(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �_�񏑔ԍ��擾�֐�
  FUNCTION get_contract_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �S���Җ��擾�֐�
  FUNCTION get_resource_name(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �n��R�[�h�擾�֐�
  FUNCTION get_area_code(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- ���_��ԍ��擾�֐�
  FUNCTION get_orig_lease_contract_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- ���_��ԍ�-�}�Ԏ擾�֐�
  FUNCTION get_orig_lease_branch_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
--
  -- �ڋq��(�J�i)�擾�֐�
  FUNCTION get_party_name_phonetic(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--

  -- ���_��N�����擾�֐�
  FUNCTION get_lease_contract_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- ���[�X���_��ԍ��擾�֐�
  FUNCTION get_lease_contract_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- ���[�X���_��ԍ��}�Ԏ擾�֐�
  FUNCTION get_lease_branch_number(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- ���[�X���(�ă��[�X)�擾�֐�
  FUNCTION get_lease_status(
    iv_install_code  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �x���񐔎擾�֐�
  FUNCTION get_payment_frequency(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- ���[�X�I���N�����擾�֐�
  FUNCTION get_lease_end_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
  -- SP�ꌈ�ԍ��擾�֐�
  FUNCTION get_sp_decision_number(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- VD�ݒu�ꏊ�擾�֐�
  FUNCTION get_install_location(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �Ƒ�(������)�擾�֐�
  FUNCTION get_vendor_form(
    iv_install_party_id  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ڋq��(���g�O)�֐�
  FUNCTION get_last_party_name(
    iv_ven_kyaku_last  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �ݒu�於(���g�O)�֐�
  FUNCTION get_last_install_place_name(
    iv_ven_kyaku_last  IN  VARCHAR2
  )
  RETURN VARCHAR2;
--
  -- �w�����z�擾�֐�
  FUNCTION get_purchase_amount(
    iv_install_code  IN  VARCHAR2
  )
  RETURN NUMBER;
--
  -- ���[�X���N�����擾�֐�
  FUNCTION get_cancellation_date(
    iv_install_code  IN  VARCHAR2
  )
  RETURN DATE;
--
END xxcso_012001j_pkg;
/
