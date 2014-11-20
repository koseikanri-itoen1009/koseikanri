CREATE OR REPLACE PACKAGE BODY apps.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Function Name    : xxcso_010001j_pkg(BODY)
 * Description      : ��������֐�(XXCSO���[�e�B���e�B�j
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     ��������֐�
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa          �V�K�쐬
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
        FROM   xxcso_employees_v xev
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
           FROM   xxcso_employees_v xev
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
END xxcso_010001j_pkg;
/
