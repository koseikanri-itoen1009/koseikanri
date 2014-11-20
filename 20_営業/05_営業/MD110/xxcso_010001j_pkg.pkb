CREATE OR REPLACE PACKAGE BODY APPS.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Function Name    : xxcso_010001j_pkg(BODY)
 * Description      : ��������֐�(XXCSO���[�e�B���e�B�j
 * MD.050/070       : 
 * Version          : 1.4
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     ��������֐�
 *  chk_latest_contract         F    V     �ŐV�_�񏑃`�F�b�N�֐�
 *  chk_cancel_contract         F    V     �_�񏑎���`�F�b�N�֐�
 *  chk_cooperate_wait          F    V     �}�X�^�A�g�҂��`�F�b�N�֐�
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa          �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *  2009/09/09    1.2   D.Abe            �����e�X�g��Q�Ή�(0001323)
 *  2010/02/10    1.3   D.Abe            E_�{�ғ�_01538�Ή�
 *  2012/08/10    1.4   K.kiriu          E_�{�ғ�_09914�Ή�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_010001j_pkg';   -- �p�b�P�[�W��
   /**********************************************************************************
   * Function Name    : get_Authority
   * Description      : ��������֐�
   ***********************************************************************************/
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER           -- SP�ꌈ�w�b�_ID
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_authority';
    cv_lookup_type               CONSTANT VARCHAR2(100)   := 'XXCSO1_POSITION_SECURITY';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_sales_person_cd         VARCHAR2(5);         -- �S���c�ƈ�
    ln_sp_decision_header_id   NUMBER;              -- SP�ꌈ�w�b�_ID
    lv_employee_number         VARCHAR2(30);        -- �]�ƈ��ԍ�
    lv_return_cd               VARCHAR2(1) := '0';  -- ���^�[���R�[�h(0:��������,1:�����L��)
    lv_base_code               VARCHAR2(150);       -- �Ζ��n���_�R�[�h
    lv_login_user_id           VARCHAR2(30);        -- ���O�C�����[�U�[
  BEGIN
--
    /*���O�C�����[�U�[ID���擾*/
    SELECT FND_GLOBAL.USER_ID
    INTO   lv_login_user_id
    FROM   DUAL;
--
    /*�S���c�ƈ��擾*/
    BEGIN
--      SELECT xxcso_route_common_pkg.get_sales_person_cd(xcav.account_number,sysdate)
      SELECT xcrv.employee_number
      INTO   lv_sales_person_cd
      FROM   xxcso_sp_decision_headers xsdh
            ,xxcso_sp_decision_custs xsdc
            ,xxcso_cust_accounts_v xcav
            ,xxcso_cust_resources_v2 xcrv
      WHERE  xsdh.sp_decision_header_id = iv_sp_decision_header_id
        AND  xsdc.sp_decision_customer_class = '1'
        AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
        AND  xcav.cust_account_id       = xsdc.customer_id
        AND  xcrv.cust_account_id       = xcav.cust_account_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lv_sales_person_cd := NULL;
    WHEN TOO_MANY_ROWS THEN
        lv_sales_person_cd := NULL;
    END;
--
   /*�l���c�ƈ��`�F�b�N*/
    BEGIN
      SELECT xsdh.sp_decision_header_id
      INTO   ln_sp_decision_header_id
      FROM   xxcso_sp_decision_headers xsdh
            ,xxcso_sp_decision_custs xsdc
            ,xxcso_employees_v2 xev
            ,xxcso_cust_accounts_v xcav
      WHERE  xsdh.sp_decision_header_id = iv_sp_decision_header_id
        AND  xev.user_id                = lv_login_user_id
        AND  xsdc.sp_decision_customer_class = '1'
        AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
        AND  xcav.cust_account_id       = xsdc.customer_id
        AND  xcav.cnvs_business_person  = xev.employee_number;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_sp_decision_header_id := NULL;
--
       /*�S���c�ƈ��`�F�b�N*/
       BEGIN
         SELECT xev.employee_number
         INTO   lv_employee_number
         FROM   xxcso_employees_v2 xev
         WHERE  xev.user_id         = lv_login_user_id
           AND  xev.employee_number = lv_sales_person_cd;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          lv_employee_number := NULL;
       END;
    END;
--
    IF ln_sp_decision_header_id IS NOT NULL
    OR lv_employee_number IS NOT NULL THEN
       lv_return_cd := '1';
--
    ELSE
     /*�S���c�ƈ��̏㒷�`�F�b�N*/
     BEGIN
        SELECT CASE
                 WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_new
                 WHEN xev.issue_date > TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_old
               END
        INTO   lv_base_code
        /* 2009.09.09 D.Abe 0001323�Ή� START */
        --FROM   xxcso_employees_v xev
        FROM   xxcso_employees_v2 xev
        /* 2009.09.09 D.Abe 0001323�Ή� END */
              ,fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type      = cv_lookup_type
          AND  flvv.attribute2       = gv_y
          AND  NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND  NVL(flvv.end_date_active,   TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND  xev.user_id           = lv_login_user_id
          AND  (
                (
                 xev.issue_date        <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 AND
                 xev.position_code_new = flvv.lookup_code
                )
                OR
                (
                 xev.issue_date        > TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 AND
                 xev.position_code_old = flvv.lookup_code
                )
               );
        BEGIN
           SELECT xev.employee_number
           INTO   lv_employee_number
           /* 2009.09.09 D.Abe 0001323�Ή� START */
           --FROM   xxcso_employees_v xev
           FROM   xxcso_employees_v2 xev
           /* 2009.09.09 D.Abe 0001323�Ή� END */
           WHERE  xev.employee_number   = lv_sales_person_cd
             AND  (
                   (
                    xev.issue_date        <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                    AND
                    xev.work_base_code_new = lv_base_code
                   )
                   OR
                   (
                    xev.issue_date        > TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                    AND
                    xev.work_base_code_old = lv_base_code
                   )
                  );
           /*�㒷�Ɣ��f�ł����ꍇ*/
           lv_return_cd := '1';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_return_cd := '0';
        END;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
       lv_return_cd := '0';
     END;
--
    END IF;
--
--lv_return_cd := '1';  -- �e�X�g
--
    RETURN lv_return_cd;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_authority;
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� START */
   /**********************************************************************************
   * Function Name    : chk_latest_contract
   * Description      : �ŐV�_�񏑃`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION chk_latest_contract(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_latest_contract';
    cv_contract_status_input     CONSTANT VARCHAR2(1)     := '0';
    cv_contract_status_submit    CONSTANT VARCHAR2(1)     := '1';  -- �X�e�[�^�X���m���
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
    ln_count                 NUMBER;
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Add Start */
    ln_contract_id           xxcso_contract_managements.contract_management_id%TYPE;
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Add End   */
  BEGIN
--
    lv_contract_number := NULL;

    -- �_�񏑂̃X�e�[�^�X���쐬�����`�F�b�N
    SELECT COUNT('x')
    INTO   ln_count
    FROM   xxcso_contract_managements xcm
    WHERE  xcm.contract_number = iv_contract_number --�_�񏑔ԍ�
    AND    xcm.status          = cv_contract_status_input
    ;

    -- �쐬���̏ꍇ�A�ŐV�_�񏑂��`�F�b�N
    IF ( ln_count <> 0 ) THEN
      BEGIN
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Add Start */
        --�_��ID���擾
        SELECT xcm.contract_management_id contract_management_id
        INTO   ln_contract_id
        FROM   xxcso_contract_managements xcm
        WHERE  xcm.contract_number = iv_contract_number
        ;
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Add End   */
        -- �ڋq�R�[�h�ɕR�t���ŐV�̌_�񏑂��擾
        SELECT xcm.contract_number
        INTO   lv_contract_number
        FROM   xxcso_contract_managements xcm
        WHERE  xcm.contract_number IN 
              (
               SELECT MAX(xcm2.contract_number)
               FROM   xxcso_contract_managements xcm2
               WHERE  xcm2.install_account_number = iv_account_number --�ڋq�R�[�h
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Mod Start */
--               AND    xcm2.contract_number        > iv_contract_number --�_�񏑔ԍ�
               AND    xcm2.contract_management_id > ln_contract_id --�_��ID
/* 2012/08/10 K.Kiriu E_�{�ғ�_09914�Ή� Mod End   */
               AND    ( (xcm2.status = cv_contract_status_submit
                        AND
                         xcm2.cooperate_flag    IS NOT NULL
                        )
                      OR
                        (xcm2.status = cv_contract_status_input)
                      )
              )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_contract_number := NULL;
      END;
      --
    END IF;
    --
    RETURN lv_contract_number;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_latest_contract;
--
   /**********************************************************************************
   * Function Name    : chk_cancel_contract
   * Description      : �_�񏑎���`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION chk_cancel_contract(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_cancel_contract';
    cv_contract_status_cancel    CONSTANT VARCHAR2(1)     := '9';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
    ln_count                 NUMBER;
  BEGIN
--
    lv_contract_number := NULL;

    -- �_�񏑂̃X�e�[�^�X������ς݂��`�F�b�N
    BEGIN
      SELECT xcm.contract_number
      INTO   lv_contract_number
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_number = iv_contract_number --�_�񏑔ԍ�
      AND    xcm.status          = cv_contract_status_cancel
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
    END;
    --
    RETURN lv_contract_number;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_cancel_contract;
--
   /**********************************************************************************
   * Function Name    : chk_cooperate_wait
   * Description      : �}�X�^�A�g�҂��`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION chk_cooperate_wait(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_cooperate_wait';
    cv_contract_status_submit    CONSTANT VARCHAR2(1)     := '1';  -- �X�e�[�^�X���m���
    cv_un_cooperate              CONSTANT VARCHAR2(1)     := '0';  -- �}�X�^�A�g�t���O�����A�g
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
  BEGIN
--
    lv_contract_number := NULL;

    -- �}�X�^�A�g�҂��̃`�F�b�N
    BEGIN
      SELECT xcm.contract_number
      INTO   lv_contract_number
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_number   = iv_contract_number --�_�񏑔ԍ�
      AND    xcm.status            = cv_contract_status_submit
      AND    xcm.cooperate_flag    = cv_un_cooperate
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_contract_number := NULL;
    END;
    --
    RETURN lv_contract_number;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
  WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_cooperate_wait;
--
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� END */
END xxcso_010001j_pkg;
/
