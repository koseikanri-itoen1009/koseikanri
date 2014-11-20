CREATE OR REPLACE PACKAGE BODY APPS.xxcso_012001j_pkg
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso012001j_pkg';   -- �p�b�P�[�W��
--
   /**********************************************************************************
   * Function Name    : get_extract_term
   * Description      : �����ėp���������擾�֐�
   ***********************************************************************************/
  FUNCTION get_extract_term(
    iv_column_code          IN  VARCHAR2,
    iv_extract_method_code  IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_extract_term';
    cv_replace_word              CONSTANT VARCHAR2(3)     := '$S1';
    cv_space                     CONSTANT VARCHAR2(1)     := ' ';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_lookup_code               fnd_lookup_values_vl.lookup_code%TYPE;
    lv_description               VARCHAR2(4000);
    lv_meaning                   fnd_lookup_values_vl.meaning%TYPE;
    lv_attribute5                fnd_lookup_values_vl.attribute5%TYPE;
    lv_extract_term              VARCHAR2(4000);
--
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    CURSOR extract_term_cur(
      p_attribute5 fnd_lookup_values_vl.attribute5%TYPE)
    IS
      SELECT   flvv.description
      FROM     fnd_lookup_values_vl flvv
      WHERE    flvv.lookup_type   = p_attribute5
        AND    flvv.enabled_flag  = 'Y'
        AND    NVL(flvv.start_date_active, TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                                 <= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
        AND    NVL(flvv.end_date_active,   TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                                 >= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
      ORDER BY flvv.lookup_code
      ;
--
  -- �����ėp���������擾
  BEGIN
--
    -- �N�C�b�N�R�[�h�̔ėp�������`�^�C�v��蒊�o�����N�C�b�N�R�[�h�̃^�C�v���擾
    BEGIN
      SELECT   flvv.attribute5
      INTO     lv_attribute5
      FROM     fnd_lookup_values_vl flvv
      WHERE    flvv.lookup_type   = 'XXCSO1_IB_PV_COLUMN_DEF'
        AND    flvv.lookup_code   = iv_column_code
        AND    flvv.enabled_flag  = 'Y'
        AND    NVL(flvv.start_date_active, TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                                 <= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
        AND    NVL(flvv.end_date_active,   TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                                 >= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_extract_term := NULL;
      RETURN lv_extract_term;
    END;
--
    -- ���o�����̃^�C�v��茟���������擾���܂�
    <<extract_term_rec>>
    FOR extract_term_rec IN extract_term_cur(lv_attribute5)
    LOOP
      lv_description := lv_description || cv_space || extract_term_rec.description;
    END LOOP extract_term_rec;
--
    --���o���@���擾���܂�
    BEGIN
      SELECT   NVL(flvv.attribute1, flvv.meaning) AS meaning
      INTO     lv_meaning
      FROM     fnd_lookup_values_vl flvv
      WHERE    flvv.lookup_type IN
                 (
                   'XXCSO1_IB_PV_VARCHAR2'
                  ,'XXCSO1_IB_PV_NUMBER'
                  ,'XXCSO1_IB_PV_DATE'
                  ,'XXCSO1_IB_PV_MATCH'
                 )
        AND    flvv.lookup_code = iv_extract_method_code
        AND    NVL(flvv.start_date_active, TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                               <= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
        AND    NVL(flvv.end_date_active,   TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate))
                               >= TRUNC(XXCSO_UTIL_COMMON_PKG.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_extract_term := NULL;
        RETURN lv_extract_term;
    END;
--
    -- �������ꂽ���o�������̒u�����𒊏o���@�Œu�����܂�
    lv_extract_term := REPLACE(lv_description, cv_replace_word, lv_meaning);
--
    -- �u��������ꂽ���o������ԋp
    RETURN lv_extract_term;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_extract_term;
--
   /**********************************************************************************
   * Function Name    : get_sp_dec_header_id
   * Description      : �L���ŐVSP�ꌈ�w�b�_ID�擾�֐�
   ***********************************************************************************/
  FUNCTION get_sp_dec_header_id(
    it_cust_account_id  IN  xxcso_cust_accounts_v.cust_account_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_header_id%TYPE
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sp_dec_header_id';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_sp_decision_header_id     xxcso_sp_decision_headers.sp_decision_header_id%TYPE;
--
  -- �L���ŐVSP�ꌈ�w�b�_ID�擾
  BEGIN
--
    BEGIN
     SELECT   MAX(xsdh.sp_decision_header_id) AS sp_decision_header_id
     INTO     lt_sp_decision_header_id
     FROM     xxcso_sp_decision_headers xsdh
             ,xxcso_sp_decision_custs xsdc
     WHERE    xsdc.sp_decision_customer_class = '1'
       AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
       AND    xsdh.status                     = '3'
       AND    xsdc.customer_id                = it_cust_account_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_sp_decision_header_id := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_sp_decision_header_id := NULL;
    END;
--
    RETURN lt_sp_decision_header_id;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_sp_dec_header_id;
--
   /**********************************************************************************
   * Function Name    : get_dept_code
   * Description      : ���_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_dept_code(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.sale_base_code%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_dept_code';
    lt_sale_base_code            xxcso_cust_accounts_v.sale_base_code%TYPE;
  BEGIN
    lt_sale_base_code := NULL;
    BEGIN
      SELECT   xcasv.sale_base_code
      INTO     lt_sale_base_code
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_sale_base_code := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_sale_base_code := NULL;
    END;
--
    RETURN lt_sale_base_code;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_dept_code;
--
   /**********************************************************************************
   * Function Name    : get_vendor_type
   * Description      : �@��敪�擾�֐�
   ***********************************************************************************/
  FUNCTION get_vendor_type(
    it_hazard_class_id       IN po_un_numbers_vl.hazard_class_id%TYPE
  )
  RETURN po_hazard_classes_vl.hazard_class%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_vendor_type';
    lt_hazard_class              po_hazard_classes_vl.hazard_class%TYPE;
  BEGIN
    lt_hazard_class := NULL;
    BEGIN
      SELECT phcv.hazard_class
      INTO   lt_hazard_class
      FROM   po_hazard_classes_vl phcv
      WHERE  phcv.hazard_class_id = it_hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_hazard_class := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_hazard_class := NULL;
    END;
--
    RETURN lt_hazard_class;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_vendor_type;
--
   /**********************************************************************************
   * Function Name    : get_account_number
   * Description      : �ڋq�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_account_number(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.account_number%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_account_number';
    lt_account_number            xxcso_cust_accounts_v.account_number%TYPE;
  BEGIN
    lt_account_number := NULL;
    BEGIN
      SELECT   xcasv.account_number
      INTO     lt_account_number
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_account_number := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_account_number := NULL;
    END;
--
    RETURN lt_account_number;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_account_number;
--
   /**********************************************************************************
   * Function Name    : get_party_name
   * Description      : �ڋq���擾�֐�
   ***********************************************************************************/
  FUNCTION get_party_name(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_name';
    lt_patry_name                xxcso_cust_accounts_v.party_name%TYPE;
  BEGIN
    lt_patry_name := NULL;
    BEGIN
      SELECT   xcasv.party_name
      INTO     lt_patry_name
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_patry_name := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_patry_name := NULL;
    END;
--
    RETURN lt_patry_name;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_party_name;
--
   /**********************************************************************************
   * Function Name    : get_lease_start_date
   * Description      : ���[�X�J�n�N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_start_date(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_start_date%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_start_date';
    lt_lease_start_date          xxcff_contract_headers.lease_start_date%TYPE;
  BEGIN
    lt_lease_start_date := NULL;
    BEGIN
      SELECT  xch.lease_start_date
      INTO    lt_lease_start_date
      FROM    xxcff_object_headers   xoh
             ,xxcff_contract_lines   xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code        = it_install_code
        AND   xcl.object_header_id   = xoh.object_header_id
        AND   xch.re_lease_times     = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_lease_start_date := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_lease_start_date := NULL;
    END;
--
    RETURN lt_lease_start_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_lease_start_date;
--
   /**********************************************************************************
   * Function Name    : get_first_charge
   * Description      : ���񌎊z���[�X���擾�֐�
   ***********************************************************************************/
  FUNCTION get_first_charge(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.first_charge%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_first_charge';
    lt_first_charge              xxcff_contract_lines.first_charge%TYPE;
  BEGIN
    lt_first_charge := NULL;
    BEGIN
      SELECT  xcl.first_charge
      INTO    lt_first_charge
      FROM    xxcff_object_headers   xoh
             ,xxcff_contract_lines   xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code        = it_install_code
        AND   xcl.object_header_id   = xoh.object_header_id
        AND   xch.re_lease_times     = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_first_charge := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_first_charge := NULL;
    END;
--
    RETURN lt_first_charge;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_first_charge;
--
   /**********************************************************************************
   * Function Name    : get_second_charge
   * Description      : 2��ڈȍ~���z���[�X���擾�֐�
   ***********************************************************************************/
  FUNCTION get_second_charge(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.second_charge%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_second_charge';
    lt_second_charge             xxcff_contract_lines.second_charge%TYPE;
  BEGIN
    lt_second_charge := NULL;
    BEGIN
      SELECT  xcl.second_charge
      INTO    lt_second_charge
      FROM    xxcff_object_headers xoh
             ,xxcff_contract_lines xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code        = it_install_code
        AND   xcl.object_header_id   = xoh.object_header_id
        AND   xch.re_lease_times     = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_second_charge := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_second_charge := NULL;
    END;
--
    RETURN lt_second_charge;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_second_charge;
--
   /**********************************************************************************
   * Function Name    : get_address1
   * Description      : �ݒu�Z��1�擾�֐�
   ***********************************************************************************/
  FUNCTION get_address1(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address1%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_address1';
    lt_address1                  xxcso_cust_acct_sites_v.address1%TYPE;
  BEGIN
    lt_address1 := NULL;
    BEGIN
      SELECT   xcasv.address1
      INTO     lt_address1
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
     ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_address1 := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_address1 := NULL;
    END;
    RETURN lt_address1;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_address1;
--
   /**********************************************************************************
   * Function Name    : get_address2
   * Description      : �ݒu�Z��2�擾�֐�
   ***********************************************************************************/
  FUNCTION get_address2(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_acct_sites_v.address2%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_address2';
    lt_address2                  xxcso_cust_acct_sites_v.address2%TYPE;
  BEGIN
    lt_address2 := NULL;
    BEGIN
      SELECT   xcasv.address2
      INTO     lt_address2
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_address2 := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_address2 := NULL;
    END;
--
    RETURN lt_address2;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_address2;
--
   /**********************************************************************************
   * Function Name    : get_install_industry_type
   * Description      : �ݒu�Ǝ�敪�擾�֐�
   ***********************************************************************************/
  FUNCTION get_install_industry_type(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_install_industry_type';
    lt_install_industry_type     fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lt_install_industry_type := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                  'XXCMM_CUST_GYOTAI_KBN'
                 ,xcasv.industry_div
                 ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lt_install_industry_type
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_install_industry_type := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_install_industry_type := NULL;
    END;
--
    RETURN lt_install_industry_type;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_install_industry_type;
--
   /**********************************************************************************
   * Function Name    : get_contract_number
   * Description      : �_�񏑔ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_contract_number(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_contract_managements.contract_number%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_contract_number';
    lt_contract_number           xxcso_contract_managements.contract_number%TYPE;
  BEGIN
    lt_contract_number := NULL;
    BEGIN
      SELECT   xcm.contract_number
      INTO     lt_contract_number
      FROM     xxcso_contract_managements xcm
              ,xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
        AND    xcm.sp_decision_header_id = XXCSO_012001j_PKG.get_sp_dec_header_id(xcasv.cust_account_id)
        AND    xcm.contract_management_id =
               (
                 SELECT   MAX(xcm2.contract_management_id)
                 FROM     xxcso_contract_managements xcm2
                 WHERE    xcm2.sp_decision_header_id = XXCSO_012001j_PKG.get_sp_dec_header_id(xcasv.cust_account_id)
                   AND    xcm2.status                = '1'
                   AND    xcm2.contract_effect_date <= XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_number := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_number := NULL;
    END;
--
    RETURN lt_contract_number;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_resource_name
   * Description      : �S���Җ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_resource_name(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_employees_v2.full_name%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_resource_name';
    lt_resource_name             xxcso_employees_v2.full_name%TYPE;
  BEGIN
    lt_resource_name := NULL;
    BEGIN
      SELECT  xev2.full_name
      INTO    lt_resource_name
      FROM    xxcso_employees_v2 xev2
             ,xxcso_cust_resources_v2 xcrv2
      WHERE   xcrv2.party_id = it_install_party_id
        AND   xev2.employee_number = xcrv2.employee_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_resource_name := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_resource_name := NULL;
    END;
--
    RETURN lt_resource_name;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_resource_name;
--
   /**********************************************************************************
   * Function Name    : get_area_code
   * Description      : �n��R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_area_code(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
-- 20090625_N.Yanagitaira 0000142 Mod START
--  RETURN NUMBER
  RETURN xxcso_cust_acct_sites_v.area_code%TYPE
-- 20090625_N.Yanagitaira 0000142 Mod END
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_area_code';
    lt_area_code                 xxcso_cust_acct_sites_v.area_code%TYPE;
  BEGIN
    lt_area_code := NULL;
    BEGIN
      SELECT   xcasv.area_code
      INTO     lt_area_code
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_area_code := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_area_code := NULL;
    END;
--
    RETURN lt_area_code;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_area_code;
--
   /**********************************************************************************
   * Function Name    : get_orig_lease_contract_number
   * Description      : ���_��ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_orig_lease_contract_number(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_orig_lease_contract_number';
    lt_contract_number           xxcff_contract_headers.contract_number%TYPE;
  BEGIN
    lt_contract_number := NULL;
    BEGIN
      SELECT   xch.contract_number
      INTO     lt_contract_number
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
        AND    xch.lease_type         = '0'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_number := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_number := NULL;
    END;
--
    RETURN lt_contract_number;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_orig_lease_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_orig_lease_branch_number
   * Description      : ���_��ԍ�-�}�Ԏ擾�֐�
   ***********************************************************************************/
  FUNCTION get_orig_lease_branch_number(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_orig_lease_branch_number';
    lt_contract_line_num         xxcff_contract_lines.contract_line_num%TYPE;
  BEGIN
    lt_contract_line_num := NULL;
    BEGIN
      SELECT   xcl.contract_line_num
      INTO     lt_contract_line_num
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
        AND    xch.lease_type         = '0'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_line_num := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_line_num := NULL;
    END;
--
    RETURN lt_contract_line_num;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_orig_lease_branch_number;
--
   /**********************************************************************************
   * Function Name    : get_party_name_phonetic
   * Description      : �ڋq��(�J�i)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_party_name_phonetic(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_cust_accounts_v.organization_name_phonetic%TYPE
  IS
    cv_prg_name                        CONSTANT VARCHAR2(100)   := 'get_party_name_phonetic';
    lt_organization_name_phonetic      xxcso_cust_accounts_v.organization_name_phonetic%TYPE;
  BEGIN
    lt_organization_name_phonetic := NULL;
    BEGIN
      SELECT   xcasv.organization_name_phonetic
      INTO     lt_organization_name_phonetic
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_organization_name_phonetic := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_organization_name_phonetic := NULL;
    END;
--
    RETURN lt_organization_name_phonetic;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_party_name_phonetic;
--
   /**********************************************************************************
   * Function Name    : get_contract_number
   * Description      : ���_��N����
   ***********************************************************************************/
  FUNCTION get_lease_contract_date(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_date%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_contract_date';
    lt_contract_date             xxcff_contract_headers.contract_date%TYPE;
  BEGIN
    lt_contract_date := NULL;
    BEGIN
      SELECT   xch.contract_date
      INTO     lt_contract_date
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_date := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_date := NULL;
    END;
--
    RETURN lt_contract_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_lease_contract_date;
--
   /**********************************************************************************
   * Function Name    : get_lease_contract_number
   * Description      : ���[�X���_��ԍ�
   ***********************************************************************************/
  FUNCTION get_lease_contract_number(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.contract_number%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_contract_number';
    lt_contract_number           xxcff_contract_headers.contract_number%TYPE;
  BEGIN
    lt_contract_number := NULL;
    BEGIN
      SELECT   xch.contract_number
      INTO     lt_contract_number
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_number := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_number := NULL;
    END;
--
    RETURN lt_contract_number;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_lease_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_lease_branch_number
   * Description      : ���[�X���_��ԍ��}�Ԏ擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_branch_number(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.contract_line_num%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_branch_number';
    lt_contract_line_num         xxcff_contract_lines.contract_line_num%TYPE;
  BEGIN
    lt_contract_line_num := NULL;
    BEGIN
      SELECT   xcl.contract_line_num
      INTO     lt_contract_line_num
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_contract_line_num := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_contract_line_num := NULL;
    END;
--
    RETURN lt_contract_line_num;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_lease_branch_number;
--
   /**********************************************************************************
   * Function Name    : get_lease_status
   * Description      : ���[�X���(�ă��[�X)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_status(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN fnd_lookup_values_vl.description%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_status';
    lt_object_status             fnd_lookup_values_vl.description%TYPE;
  BEGIN
    lt_object_status := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_description(
                 'XXCFF1_OBJECT_STATUS'
                ,xoh.object_status
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               ) object_status
      INTO     lt_object_status
      FROM     xxcff_object_headers xoh
      WHERE    xoh.object_code = it_install_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_object_status := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_object_status := NULL;
    END;
--
    RETURN lt_object_status;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_status;
--
   /**********************************************************************************
   * Function Name    : get_payment_frequency
   * Description      : �x���񐔎擾�֐�
   ***********************************************************************************/
  FUNCTION get_payment_frequency(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.payment_frequency%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_payment_frequency';
    lt_payment_frequency         xxcff_contract_headers.payment_frequency%TYPE;
  BEGIN
    lt_payment_frequency := NULL;
    BEGIN
          SELECT   xch.payment_frequency
          INTO     lt_payment_frequency
          FROM     xxcff_object_headers   xoh
                  ,xxcff_contract_lines   xcl
                  ,xxcff_contract_headers xch
          WHERE    xoh.object_code        = it_install_code
            AND    xcl.object_header_id   = xoh.object_header_id
            AND    xch.re_lease_times     = xoh.re_lease_times
            AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_payment_frequency := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_payment_frequency := NULL;
    END;
--
    RETURN lt_payment_frequency;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_payment_frequency;
--
   /**********************************************************************************
   * Function Name    : get_lease_end_date
   * Description      : ���[�X�I���N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_end_date(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_headers.lease_end_date%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_end_date';
    lt_lease_end_date            xxcff_contract_headers.lease_end_date%TYPE;
  BEGIN
    lt_lease_end_date := NULL;
    BEGIN
      SELECT   xch.lease_end_date
      INTO     lt_lease_end_date
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_lease_end_date := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_lease_end_date := NULL;
    END;
--
    RETURN lt_lease_end_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_lease_end_date;
--
   /**********************************************************************************
   * Function Name    : get_sp_decision_number
   * Description      : SP�ꌈ�ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_sp_decision_number(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN xxcso_sp_decision_headers.sp_decision_number%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sp_decision_number';
    lt_sp_decision_number        xxcso_sp_decision_headers.sp_decision_number%TYPE;
  BEGIN
    lt_sp_decision_number := NULL;
    BEGIN
      SELECT   xsdh.sp_decision_number
      INTO     lt_sp_decision_number
      FROM     xxcso_sp_decision_headers xsdh
      WHERE    sp_decision_header_id = 
               (
                 SELECT   MAX(xsdh2.sp_decision_header_id) AS sp_decision_header_id
                 FROM     xxcso_sp_decision_headers xsdh2
                         ,xxcso_sp_decision_custs   xsdc
                         ,xxcso_cust_accounts_v     xcasv
                 WHERE    xsdc.sp_decision_customer_class = '1'
                   AND    xsdc.sp_decision_header_id      = xsdh2.sp_decision_header_id
                   AND    xcasv.party_id                  = it_install_party_id
                   AND    xsdc.customer_id                = xcasv.cust_account_id
                   AND    xsdh2.status                    = '3'
               )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_sp_decision_number := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_sp_decision_number := NULL;
    END;
--
    RETURN lt_sp_decision_number;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_sp_decision_number;
--
   /**********************************************************************************
   * Function Name    : get_install_location
   * Description      : VD�ݒu�ꏊ�擾�֐�
   ***********************************************************************************/
  FUNCTION get_install_location(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_status';
    lt_establishment_location    fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lt_establishment_location := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                 'XXCMM_CUST_VD_SECCHI_BASYO'
                ,xcasv.establishment_location
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lt_establishment_location
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_establishment_location := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_establishment_location := NULL;
    END;
--
    RETURN lt_establishment_location;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_install_location;
--
   /**********************************************************************************
   * Function Name    : get_vendor_form
   * Description      : �Ƒ�(������)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_vendor_form(
    it_install_party_id       IN  xxcso_install_base_v.install_party_id%TYPE
  )
  RETURN fnd_lookup_values_vl.meaning%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_vendor_form';
    lt_business_low_type         fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lt_business_low_type := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                 'XXCMM_CUST_GYOTAI_SHO'
                ,xcasv.business_low_type
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lt_business_low_type
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = it_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_business_low_type := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_business_low_type := NULL;
    END;
--
    RETURN lt_business_low_type;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_vendor_form;
--
   /**********************************************************************************
   * Function Name    : get_last_party_name
   * Description      : �ڋq��(���g�O)�֐�
   ***********************************************************************************/
  FUNCTION get_last_party_name(
    it_ven_kyaku_last       IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.party_name%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_last_party_name';
    lt_party_name                xxcso_cust_accounts_v.party_name%TYPE;
  BEGIN
    lt_party_name := NULL;
    BEGIN
      SELECT   xcav.party_name
      INTO     lt_party_name
      FROM     xxcso_cust_accounts_v xcav
      WHERE    xcav.account_number = it_ven_kyaku_last
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_party_name := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_party_name := NULL;
    END;
--
    RETURN lt_party_name;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_last_party_name;
--
   /**********************************************************************************
   * Function Name    : get_last_install_place_name
   * Description      : �ݒu�於(���g�O)�֐�
   ***********************************************************************************/
  FUNCTION get_last_install_place_name(
    it_ven_kyaku_last       IN  xxcso_install_base_v.ven_kyaku_last%TYPE
  )
  RETURN xxcso_cust_accounts_v.established_site_name%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_last_install_place_name';
    lt_established_site_name     xxcso_cust_accounts_v.established_site_name%TYPE;
  BEGIN
    lt_established_site_name := NULL;
    BEGIN
      SELECT   xcav.established_site_name
      INTO     lt_established_site_name
      FROM     xxcso_cust_accounts_v xcav
      WHERE    xcav.account_number = it_ven_kyaku_last
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_established_site_name := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_established_site_name := NULL;
    END;
--
    RETURN lt_established_site_name;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_last_install_place_name;
--
   /**********************************************************************************
   * Function Name    : get_purchase_amount
   * Description      : �w�����z�擾�֐�
   ***********************************************************************************/
  FUNCTION get_purchase_amount(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.estimated_cash_price%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_purchase_amount';
    lt_estimated_cash_price      xxcff_contract_lines.estimated_cash_price%TYPE;
  BEGIN
    lt_estimated_cash_price := NULL;
    BEGIN
      SELECT   xcl.estimated_cash_price
      INTO     lt_estimated_cash_price
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_estimated_cash_price := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_estimated_cash_price := NULL;
    END;
--
    RETURN lt_estimated_cash_price;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_purchase_amount;
--
   /**********************************************************************************
   * Function Name    : get_cancellation_date
   * Description      : ���[�X���N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_cancellation_date(
    it_install_code       IN  xxcso_install_base_v.install_code%TYPE
  )
  RETURN xxcff_contract_lines.cancellation_date%TYPE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_cancellation_date';
    lt_cancellation_date         xxcff_contract_lines.cancellation_date%TYPE;
  BEGIN
    lt_cancellation_date := NULL;
    BEGIN
      SELECT   xcl.cancellation_date
      INTO     lt_cancellation_date
      FROM     xxcff_object_headers   xoh
              ,xxcff_contract_lines   xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code        = it_install_code
        AND    xcl.object_header_id   = xoh.object_header_id
        AND    xch.re_lease_times     = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_cancellation_date := NULL;
      WHEN TOO_MANY_ROWS THEN
        lt_cancellation_date := NULL;
    END;
--
    RETURN lt_cancellation_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
  END get_cancellation_date;
--
END xxcso_012001j_pkg;
/
