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
      WHERE    flvv.lookup_type               = p_attribute5
        AND    flvv.enabled_flag              = 'Y'
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
      WHERE    flvv.lookup_type               = 'XXCSO1_IB_PV_COLUMN_DEF'
        AND    flvv.lookup_code               = iv_column_code
        AND    flvv.enabled_flag              = 'Y'
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
      WHERE    flvv.lookup_type in
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
    in_cust_account_id  IN  NUMBER
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sp_dec_header_id';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_sp_decision_header_id     hz_cust_accounts.account_number%TYPE;
--
  -- �L���ŐVSP�ꌈ�w�b�_ID�擾
  BEGIN
--
    BEGIN
     SELECT   MAX(xsdh.sp_decision_header_id) AS sp_decision_header_id
     INTO     lv_sp_decision_header_id
     FROM     xxcso_sp_decision_headers xsdh
             ,xxcso_sp_decision_custs xsdc
     WHERE    xsdc.sp_decision_customer_class = '1'
       AND    xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
       AND    xsdh.status = '3'
       AND    xsdc.customer_id = in_cust_account_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sp_decision_header_id := NULL;
        RETURN lv_sp_decision_header_id;
      WHEN TOO_MANY_ROWS THEN
        lv_sp_decision_header_id := NULL;
        RETURN lv_sp_decision_header_id;
    END;
--
    --
    RETURN lv_sp_decision_header_id;
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


   /**********************************************************************************
   * Function Name    : get_dept_code
   * Description      : ���_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_dept_code(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_dept_code';
    lv_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;
  BEGIN
    lv_sale_base_code := NULL;
    BEGIN
      SELECT   xcasv.sale_base_code
      INTO     lv_sale_base_code
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sale_base_code := NULL;
        RETURN lv_sale_base_code;
      WHEN TOO_MANY_ROWS THEN
        lv_sale_base_code := NULL;
        RETURN lv_sale_base_code;
    END;
    RETURN lv_sale_base_code;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_dept_code;
--
   /**********************************************************************************
   * Function Name    : get_vendor_type
   * Description      : �@��敪�擾�֐�
   ***********************************************************************************/
  FUNCTION get_vendor_type(
    iv_hazard_class_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_vendor_type';
    lv_hazard_class              po_hazard_classes_vl.hazard_class%TYPE;
  BEGIN
    lv_hazard_class := NULL;
    BEGIN
      SELECT phcv.hazard_class
      INTO   lv_hazard_class
      FROM   po_hazard_classes_vl phcv
      WHERE  phcv.hazard_class_id = iv_hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_hazard_class := NULL;
        RETURN lv_hazard_class;
      WHEN TOO_MANY_ROWS THEN
        lv_hazard_class := NULL;
        RETURN lv_hazard_class;
    END;
    RETURN lv_hazard_class;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_vendor_type;
--

   /**********************************************************************************
   * Function Name    : get_account_number
   * Description      : �ڋq�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_account_number(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_account_number';
    lv_account_number            hz_cust_accounts.account_number%TYPE;
  BEGIN
    lv_account_number := NULL;
    BEGIN
      SELECT   xcasv.account_number
      INTO     lv_account_number
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_account_number := NULL;
        RETURN lv_account_number;
      WHEN TOO_MANY_ROWS THEN
        lv_account_number := NULL;
        RETURN lv_account_number;
    END;
    RETURN lv_account_number;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_account_number;
--
   /**********************************************************************************
   * Function Name    : get_party_name
   * Description      : �ڋq���擾�֐�
   ***********************************************************************************/
  FUNCTION get_party_name(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_name';
    lv_patry_name                hz_parties.party_name%TYPE;
  BEGIN
    lv_patry_name := NULL;
    BEGIN
      SELECT   xcasv.party_name
      INTO     lv_patry_name
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_patry_name := NULL;
        RETURN lv_patry_name;
      WHEN TOO_MANY_ROWS THEN
        lv_patry_name := NULL;
        RETURN lv_patry_name;
    END;
    RETURN lv_patry_name;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_party_name;
--
   /**********************************************************************************
   * Function Name    : get_lease_start_date
   * Description      : ���[�X�J�n�N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_start_date(
    iv_install_code       IN  VARCHAR2
  )
  RETURN DATE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_start_date';
    ld_lease_start_date          xxcff_contract_headers.lease_start_date%TYPE;
  BEGIN
    ld_lease_start_date := NULL;
    BEGIN
      SELECT  xch.lease_start_date
      INTO    ld_lease_start_date
      FROM    xxcff_object_headers xoh
             ,xxcff_contract_lines xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code = iv_install_code
        AND   xcl.object_header_id = xoh.object_header_id
        AND   xch.re_lease_times = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ld_lease_start_date := NULL;
        RETURN ld_lease_start_date;
      WHEN TOO_MANY_ROWS THEN
        ld_lease_start_date := NULL;
        RETURN ld_lease_start_date;
    END;
    RETURN ld_lease_start_date;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_start_date;
--
   /**********************************************************************************
   * Function Name    : get_first_charge
   * Description      : ���񌎊z���[�X���擾�֐�
   ***********************************************************************************/
  FUNCTION get_first_charge(
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_first_charge';
    ln_first_charge              xxcff_contract_lines.first_charge%TYPE;
  BEGIN
    ln_first_charge := NULL;
    BEGIN
      SELECT  xcl.first_charge
      INTO    ln_first_charge
      FROM    xxcff_object_headers xoh
             ,xxcff_contract_lines xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code = iv_install_code
        AND   xcl.object_header_id = xoh.object_header_id
        AND   xch.re_lease_times = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_first_charge := NULL;
        RETURN ln_first_charge;
      WHEN TOO_MANY_ROWS THEN
        ln_first_charge := NULL;
        RETURN ln_first_charge;
    END;
    RETURN ln_first_charge;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_first_charge;
--
   /**********************************************************************************
   * Function Name    : get_second_charge
   * Description      : 2��ڈȍ~���z���[�X���擾�֐�
   ***********************************************************************************/
  FUNCTION get_second_charge(
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_second_charge';
    ln_second_charge             xxcff_contract_lines.second_charge%TYPE;
  BEGIN
    ln_second_charge := NULL;
    BEGIN
      SELECT  xcl.second_charge
      INTO    ln_second_charge
      FROM    xxcff_object_headers xoh
             ,xxcff_contract_lines xcl
             ,xxcff_contract_headers xch
      WHERE   xoh.object_code = iv_install_code
        AND   xcl.object_header_id = xoh.object_header_id
        AND   xch.re_lease_times = xoh.re_lease_times
        AND   xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_second_charge := NULL;
        RETURN ln_second_charge;
      WHEN TOO_MANY_ROWS THEN
        ln_second_charge := NULL;
        RETURN ln_second_charge;
    END;
    RETURN ln_second_charge;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_second_charge;
--
   /**********************************************************************************
   * Function Name    : get_address1
   * Description      : �ݒu�Z��1�擾�֐�
   ***********************************************************************************/
  FUNCTION get_address1(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_address1';
    lv_address1                  hz_locations.address1%TYPE;
  BEGIN
    lv_address1 := NULL;
    BEGIN
      SELECT   xcasv.address1
      INTO     lv_address1
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
     ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_address1 := NULL;
        RETURN lv_address1;
      WHEN TOO_MANY_ROWS THEN
        lv_address1 := NULL;
        RETURN lv_address1;
    END;
    RETURN lv_address1;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_address1;
--
   /**********************************************************************************
   * Function Name    : get_address2
   * Description      : �ݒu�Z��2�擾�֐�
   ***********************************************************************************/
  FUNCTION get_address2(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_address2';
    lv_address2                  hz_locations.address2%TYPE;
  BEGIN
    lv_address2 := NULL;
    BEGIN
      SELECT   xcasv.address2
      INTO     lv_address2
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_address2 := NULL;
        RETURN lv_address2;
      WHEN TOO_MANY_ROWS THEN
        lv_address2 := NULL;
        RETURN lv_address2;
    END;
    RETURN lv_address2;
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
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_install_industry_type';
    lv_install_industry_type     fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lv_install_industry_type := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                  'XXCMM_CUST_GYOTAI_KBN'
                 ,xcasv.industry_div
                 ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lv_install_industry_type
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_install_industry_type := NULL;
        RETURN lv_install_industry_type;
      WHEN TOO_MANY_ROWS THEN
        lv_install_industry_type := NULL;
        RETURN lv_install_industry_type;
    END;
    RETURN lv_install_industry_type;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_install_industry_type;
--
   /**********************************************************************************
   * Function Name    : get_contract_number
   * Description      : �_�񏑔ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_contract_number(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_contract_number';
    lv_contract_number           xxcso_contract_managements.contract_number%TYPE;
  BEGIN
    lv_contract_number := NULL;
    BEGIN
      SELECT   xcm.contract_number
      INTO     lv_contract_number
      FROM     xxcso_contract_managements xcm
              ,xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
        AND    xcm.sp_decision_header_id = XXCSO_012001j_PKG.get_sp_dec_header_id(xcasv.cust_account_id)
        AND    xcm.contract_management_id =
               (
                 SELECT   MAX(xcm2.contract_management_id)
                 FROM     xxcso_contract_managements xcm2
                 WHERE    xcm2.sp_decision_header_id = XXCSO_012001j_PKG.get_sp_dec_header_id(xcasv.cust_account_id)
                   AND    xcm2.status = '1'
                   AND    xcm2.contract_effect_date <= XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
      WHEN TOO_MANY_ROWS THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
    END;
    RETURN lv_contract_number;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_resource_name
   * Description      : �S���Җ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_resource_name(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_resource_name';
    lv_resource_name             xxcso_employees_v2.full_name%TYPE;
  BEGIN
    lv_resource_name := NULL;
    BEGIN
      SELECT  xev2.full_name
      INTO    lv_resource_name
      FROM    xxcso_employees_v2 xev2
             ,xxcso_cust_resources_v2 xcrv2
      WHERE   xcrv2.party_id = iv_install_party_id
        AND   xev2.employee_number = xcrv2.employee_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_resource_name := NULL;
        RETURN lv_resource_name;
      WHEN TOO_MANY_ROWS THEN
        lv_resource_name := NULL;
        RETURN lv_resource_name;
    END;
    RETURN lv_resource_name;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_resource_name;
--
   /**********************************************************************************
   * Function Name    : get_area_code
   * Description      : �n��R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_area_code(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_area_code';
    ln_area_code                 hz_locations.address3%TYPE;
  BEGIN
    ln_area_code := NULL;
    BEGIN
      SELECT   xcasv.area_code
      INTO     ln_area_code
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_area_code := NULL;
        RETURN ln_area_code;
      WHEN TOO_MANY_ROWS THEN
        ln_area_code := NULL;
        RETURN ln_area_code;
    END;
    RETURN ln_area_code;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_area_code;
--
   /**********************************************************************************
   * Function Name    : get_orig_lease_contract_number
   * Description      : ���_��ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_orig_lease_contract_number(
    iv_install_code       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_orig_lease_contract_number';
    lv_contract_number           xxcff_contract_headers.contract_number%TYPE;
  BEGIN
    lv_contract_number := NULL;
    BEGIN
      SELECT   xch.contract_number
      INTO     lv_contract_number
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
        AND    xch.lease_type = '0'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
      WHEN TOO_MANY_ROWS THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
    END;
    RETURN lv_contract_number;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_orig_lease_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_orig_lease_branch_number
   * Description      : ���_��ԍ�-�}�Ԏ擾�֐�
   ***********************************************************************************/
  FUNCTION get_orig_lease_branch_number(
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_orig_lease_branch_number';
    ln_contract_line_num         xxcff_contract_lines.contract_line_num%TYPE;
  BEGIN
    ln_contract_line_num := NULL;
    BEGIN
      SELECT   xcl.contract_line_num
      INTO     ln_contract_line_num
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
        AND    xch.lease_type = '0'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_contract_line_num := NULL;
        RETURN ln_contract_line_num;
      WHEN TOO_MANY_ROWS THEN
        ln_contract_line_num := NULL;
        RETURN ln_contract_line_num;
    END;
    RETURN ln_contract_line_num;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_orig_lease_branch_number;
--
   /**********************************************************************************
   * Function Name    : get_party_name_phonetic
   * Description      : �ڋq��(�J�i)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_party_name_phonetic(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_name_phonetic';
    lv_organization_name_phonetic      hz_parties.organization_name_phonetic%TYPE;
  BEGIN
    lv_organization_name_phonetic := NULL;
    BEGIN
      SELECT   xcasv.organization_name_phonetic
      INTO     lv_organization_name_phonetic
      FROM     xxcso_cust_accounts_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_organization_name_phonetic := NULL;
        RETURN lv_organization_name_phonetic;
      WHEN TOO_MANY_ROWS THEN
        lv_organization_name_phonetic := NULL;
        RETURN lv_organization_name_phonetic;
    END;
    RETURN lv_organization_name_phonetic;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_party_name_phonetic;
--
   /**********************************************************************************
   * Function Name    : get_contract_number
   * Description      : ���_��N����
   ***********************************************************************************/
  FUNCTION get_lease_contract_date(
    iv_install_code       IN  VARCHAR2
  )
  RETURN DATE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_contract_date';
    ld_contract_date             xxcff_contract_headers.contract_date%TYPE;
  BEGIN
    ld_contract_date := NULL;
    BEGIN
      SELECT   xch.contract_date
      INTO     ld_contract_date
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ld_contract_date := NULL;
        RETURN ld_contract_date;
      WHEN TOO_MANY_ROWS THEN
        ld_contract_date := NULL;
        RETURN ld_contract_date;
    END;
    RETURN ld_contract_date;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_contract_date;
--
   /**********************************************************************************
   * Function Name    : get_lease_contract_number
   * Description      : ���[�X���_��ԍ�
   ***********************************************************************************/
  FUNCTION get_lease_contract_number(
    iv_install_code       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_contract_number';
    lv_contract_number           xxcff_contract_headers.contract_number%TYPE;
  BEGIN
    lv_contract_number := NULL;
    BEGIN
      SELECT   xch.contract_number
      INTO     lv_contract_number
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
      WHEN TOO_MANY_ROWS THEN
        lv_contract_number := NULL;
        RETURN lv_contract_number;
    END;
    RETURN lv_contract_number;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_contract_number;
--
   /**********************************************************************************
   * Function Name    : get_lease_branch_number
   * Description      : ���[�X���_��ԍ��}�Ԏ擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_branch_number(
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_branch_number';
    ln_contract_line_num         xxcff_contract_lines.contract_line_num%TYPE;
  BEGIN
    ln_contract_line_num := NULL;
    BEGIN
      SELECT   xcl.contract_line_num
      INTO     ln_contract_line_num
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_contract_line_num := NULL;
        RETURN ln_contract_line_num;
      WHEN TOO_MANY_ROWS THEN
        ln_contract_line_num := NULL;
        RETURN ln_contract_line_num;
    END;
    RETURN ln_contract_line_num;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_branch_number;
--
   /**********************************************************************************
   * Function Name    : get_lease_status
   * Description      : ���[�X���(�ă��[�X)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_status(
    iv_install_code       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_status';
    lv_object_status             fnd_lookup_values_vl.description%TYPE;
  BEGIN
    lv_object_status := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_description(
                 'XXCFF1_OBJECT_STATUS'
                ,xoh.object_status
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               ) object_status
      INTO     lv_object_status
      FROM     xxcff_object_headers xoh
      WHERE    xoh.object_code = iv_install_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_object_status := NULL;
        RETURN lv_object_status;
      WHEN TOO_MANY_ROWS THEN
        lv_object_status := NULL;
        RETURN lv_object_status;
    END;
    RETURN lv_object_status;
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
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_payment_frequency';
    ln_payment_frequency         xxcff_contract_headers.payment_frequency%TYPE;
  BEGIN
    ln_payment_frequency := NULL;
    BEGIN
          SELECT   xch.payment_frequency
          INTO     ln_payment_frequency
          FROM     xxcff_object_headers xoh
                  ,xxcff_contract_lines xcl
                  ,xxcff_contract_headers xch
          WHERE    xoh.object_code = iv_install_code
            AND    xcl.object_header_id = xoh.object_header_id
            AND    xch.re_lease_times = xoh.re_lease_times
            AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_payment_frequency := NULL;
        RETURN ln_payment_frequency;
      WHEN TOO_MANY_ROWS THEN
        ln_payment_frequency := NULL;
        RETURN ln_payment_frequency;
    END;
    RETURN ln_payment_frequency;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_payment_frequency;
--
   /**********************************************************************************
   * Function Name    : get_lease_end_date
   * Description      : ���[�X�I���N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_lease_end_date(
    iv_install_code       IN  VARCHAR2
  )
  RETURN DATE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_end_date';
    ld_lease_end_date            xxcff_contract_headers.lease_end_date%TYPE;
  BEGIN
    ld_lease_end_date := NULL;
    BEGIN
          SELECT   xch.lease_end_date
          INTO     ld_lease_end_date
          FROM     xxcff_object_headers xoh
                  ,xxcff_contract_lines xcl
                  ,xxcff_contract_headers xch
          WHERE    xoh.object_code = iv_install_code
            AND    xcl.object_header_id = xoh.object_header_id
            AND    xch.re_lease_times = xoh.re_lease_times
            AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ld_lease_end_date := NULL;
        RETURN ld_lease_end_date;
      WHEN TOO_MANY_ROWS THEN
        ld_lease_end_date := NULL;
        RETURN ld_lease_end_date;

    END;
    RETURN ld_lease_end_date;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_lease_end_date;
--
   /**********************************************************************************
   * Function Name    : get_sp_decision_number
   * Description      : SP�ꌈ�ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_sp_decision_number(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sp_decision_number';
    ln_sp_decision_number        xxcso_sp_decision_headers.sp_decision_number%TYPE;
  BEGIN
    ln_sp_decision_number := NULL;
    BEGIN
      SELECT   xsdh.sp_decision_number
      INTO     ln_sp_decision_number
      FROM     xxcso_sp_decision_headers xsdh
      WHERE    sp_decision_header_id = 
               (
                 SELECT   MAX(xsdh2.sp_decision_header_id) AS sp_decision_header_id
                 FROM     xxcso_sp_decision_headers xsdh2
                         ,xxcso_sp_decision_custs xsdc
                         ,xxcso_cust_accounts_v xcasv
                 WHERE    xsdc.sp_decision_customer_class = '1'
                   AND    xsdc.sp_decision_header_id = xsdh2.sp_decision_header_id
                   AND    xcasv.party_id = iv_install_party_id
                   AND    xsdc.customer_id = xcasv.cust_account_id
                   AND    xsdh2.status = '3'
               )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_sp_decision_number := NULL;
        RETURN ln_sp_decision_number;
      WHEN TOO_MANY_ROWS THEN
        ln_sp_decision_number := NULL;
        RETURN ln_sp_decision_number;
    END;
    RETURN ln_sp_decision_number;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_sp_decision_number;
--
   /**********************************************************************************
   * Function Name    : get_install_location
   * Description      : VD�ݒu�ꏊ�擾�֐�
   ***********************************************************************************/
  FUNCTION get_install_location(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lease_status';
    lv_establishment_location    fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lv_establishment_location := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                 'XXCMM_CUST_VD_SECCHI_BASYO'
                ,xcasv.establishment_location
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lv_establishment_location
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_establishment_location := NULL;
        RETURN lv_establishment_location;
      WHEN TOO_MANY_ROWS THEN
        lv_establishment_location := NULL;
        RETURN lv_establishment_location;
    END;
    RETURN lv_establishment_location;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_install_location;
--
   /**********************************************************************************
   * Function Name    : get_vendor_form
   * Description      : �Ƒ�(������)�擾�֐�
   ***********************************************************************************/
  FUNCTION get_vendor_form(
    iv_install_party_id       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_vendor_form';
    lv_business_low_type         fnd_lookup_values_vl.meaning%TYPE;
  BEGIN
    lv_business_low_type := NULL;
    BEGIN
      SELECT   XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                 'XXCMM_CUST_GYOTAI_SHO'
                ,xcasv.business_low_type
                ,XXCSO_UTIL_COMMON_PKG.get_online_sysdate
               )
      INTO     lv_business_low_type
      FROM     xxcso_cust_acct_sites_v xcasv
      WHERE    xcasv.party_id = iv_install_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_business_low_type := NULL;
        RETURN lv_business_low_type;
      WHEN TOO_MANY_ROWS THEN
        lv_business_low_type := NULL;
        RETURN lv_business_low_type;
    END;
    RETURN lv_business_low_type;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_vendor_form;
--
   /**********************************************************************************
   * Function Name    : get_last_party_name
   * Description      : �ڋq��(���g�O)�֐�
   ***********************************************************************************/
  FUNCTION get_last_party_name(
    iv_ven_kyaku_last       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_last_party_name';
    lv_party_name                hz_parties.party_name%TYPE;
  BEGIN
    lv_party_name := NULL;
    BEGIN
      SELECT   xcav.party_name
      INTO     lv_party_name
      FROM     xxcso_cust_accounts_v xcav
      WHERE    xcav.account_number = iv_ven_kyaku_last
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_party_name := NULL;
        RETURN lv_party_name;
      WHEN TOO_MANY_ROWS THEN
        lv_party_name := NULL;
        RETURN lv_party_name;
    END;
    RETURN lv_party_name;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_last_party_name;
--
   /**********************************************************************************
   * Function Name    : get_last_install_place_name
   * Description      : �ݒu�於(���g�O)�֐�
   ***********************************************************************************/
  FUNCTION get_last_install_place_name(
    iv_ven_kyaku_last       IN  VARCHAR2
  )
  RETURN VARCHAR2
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_last_install_place_name';
    lv_established_site_name     xxcmm_cust_accounts.established_site_name%TYPE;
  BEGIN
    lv_established_site_name := NULL;
    BEGIN
      SELECT   xcav.established_site_name
      INTO     lv_established_site_name
      FROM     xxcso_cust_accounts_v xcav
      WHERE    xcav.account_number = iv_ven_kyaku_last
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_established_site_name := NULL;
        RETURN lv_established_site_name;
      WHEN TOO_MANY_ROWS THEN
        lv_established_site_name := NULL;
        RETURN lv_established_site_name;
    END;
    RETURN lv_established_site_name;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_last_install_place_name;
--
   /**********************************************************************************
   * Function Name    : get_purchase_amount
   * Description      : �w�����z�擾�֐�
   ***********************************************************************************/
  FUNCTION get_purchase_amount(
    iv_install_code       IN  VARCHAR2
  )
  RETURN NUMBER
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_purchase_amount';
    ln_estimated_cash_price      xxcff_contract_lines.estimated_cash_price%TYPE;
  BEGIN
    ln_estimated_cash_price := NULL;
    BEGIN
      SELECT   xcl.estimated_cash_price
      INTO     ln_estimated_cash_price
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_estimated_cash_price := NULL;
        RETURN ln_estimated_cash_price;
      WHEN TOO_MANY_ROWS THEN
        ln_estimated_cash_price := NULL;
        RETURN ln_estimated_cash_price;
    END;
    RETURN ln_estimated_cash_price;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_purchase_amount;
--
   /**********************************************************************************
   * Function Name    : get_cancellation_date
   * Description      : ���[�X���N�����擾�֐�
   ***********************************************************************************/
  FUNCTION get_cancellation_date(
    iv_install_code       IN  VARCHAR2
  )
  RETURN DATE
  IS
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_cancellation_date';
    ld_cancellation_date         xxcff_contract_lines.cancellation_date%TYPE;
  BEGIN
    ld_cancellation_date := NULL;
    BEGIN
      SELECT   xcl.cancellation_date
      INTO     ld_cancellation_date
      FROM     xxcff_object_headers xoh
              ,xxcff_contract_lines xcl
              ,xxcff_contract_headers xch
      WHERE    xoh.object_code = iv_install_code
        AND    xcl.object_header_id = xoh.object_header_id
        AND    xch.re_lease_times = xoh.re_lease_times
        AND    xch.contract_header_id = xcl.contract_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ld_cancellation_date := NULL;
        RETURN ld_cancellation_date;
      WHEN TOO_MANY_ROWS THEN
        ld_cancellation_date := NULL;
        RETURN ld_cancellation_date;
    END;
    RETURN ld_cancellation_date;
  EXCEPTION
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
  END get_cancellation_date;
--
END xxcso_012001j_pkg;
/
