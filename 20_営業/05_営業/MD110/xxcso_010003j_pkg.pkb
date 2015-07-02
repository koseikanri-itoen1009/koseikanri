CREATE OR REPLACE PACKAGE BODY APPS.xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : �����̔��@�ݒu�_����o�^�X�V_���ʊ֐�
 * MD.050/070       : 
 * Version          : 1.14
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  decode_bm_info            F    V      BM��񕪊�擾
 *  get_base_leader_name      F    V      ���s���������擾
 *  get_base_leader_pos_name  F    V      ���s���������E�ʖ��擾
 *  chk_double_byte_kana      F    V      �S�p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_tel_format            F    V      �d�b�ԍ��`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_duplicate_vendor_name F    V      ���t�於�d���`�F�b�N
 *  get_authority             F    V      ��������֐�
 *  chk_bfa_single_byte_kana  F    V      ���p�J�i�`�F�b�N�iBFA�֐����b�s���O�j
 *  decode_cont_manage_info   F    V      �_��Ǘ���񕪊�擾
 *  get_sales_charge          F    V      �̔��萔�������۔���
 *  chk_double_byte           F    V      �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_single_byte_kana      F    V      ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_cooperate_wait        F    V      �}�X�^�A�g�҂��`�F�b�N
 *  reflect_contract_status   P    -      �_�񏑊m���񔽉f����
 *  chk_validate_db           P    -      �c�a�X�V����`�F�b�N
 *  chk_cash_payment          F    V      �����x���`�F�b�N
 *  chk_install_code          F    V      �����R�[�h�`�F�b�N
 *  chk_bank_branch           F    V      ��s�x�X�}�X�^�`�F�b�N
 *  chk_supplier              F    V      �d����}�X�^�`�F�b�N
 *  chk_bank_account          F    V      ��s�����}�X�^�`�F�b�N
 *  chk_bank_account_change   F    V      ��s�����}�X�^�ύX�`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   H.Ogawa          �V�K�쐬
 *  2009/02/16    1.0   N.Yanagitaira    [UT��C��]chk_bfa_single_byte_kana�ǉ�
 *  2009/02/17    1.1   N.Yanagitaira    [CT1-012]decode_cont_manage_info�ǉ�
 *  2009/02/23    1.1   N.Yanagitaira    [������Q-028]�S�p�J�i�`�F�b�N�����s���C��
 *  2009/03/12    1.1   N.Yanagitaira    [CT2-058]get_sales_charge�ǉ�
 *  2009/04/03    1.2   N.Yanagitaira    [ST��QT1_0223]chk_duplicate_vendor_name�C��
 *  2009/04/27    1.3   N.Yanagitaira    [ST��QT1_0708]���͍��ڃ`�F�b�N��������C��
 *                                                      chk_double_byte
 *                                                      chk_single_byte_kana
 *  2009/05/01    1.4   T.Mori           [ST��QT1_0897]�X�L�[�}���ݒ�
 *  2009/06/05    1.5   N.Yanagitaira    [ST��QT1_1307]chk_single_byte_kana�C��
 *  2009/09/09    1.6   Daisuke.Abe      �����e�X�g��Q�Ή�(0001323)
 *  2010/02/10    1.7   D.Abe            E_�{�ғ�_01538�Ή�
 *  2010/03/01    1.8   D.Abe            E_�{�ғ�_01678,E_�{�ғ�_01868�Ή�
 *  2010/11/17    1.9   S.Arizumi        E_�{�ғ�_01954�Ή�
 *  2011/01/06    1.10  K.Kiriu          E_�{�ғ�_02498�Ή�
 *  2011/06/06    1.11  K.Kiriu          E_�{�ғ�_01963�Ή�
 *  2012/08/10    1.12  K.Kiriu          E_�{�ғ�_09914�Ή�
 *  2013/04/01    1.13  K.Kiriu          E_�{�ғ�_10413�Ή�
 *  2015/04/17    1.14  K.Kiriu          E_�{�ғ�_13002�Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_010003j_pkg';   -- �p�b�P�[�W��
--
  /**********************************************************************************
   * Function Name    : decode_bm_info
   * Description      : BM��񕪊�擾
   ***********************************************************************************/
  FUNCTION decode_bm_info(
    in_customer_id              NUMBER
   ,iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'decode_bm_info';
    cv_contract_status_input     CONSTANT VARCHAR2(1)     := '0';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_normal  CONSTANT VARCHAR2(1)     := '0';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    IF ( in_customer_id IS NULL ) THEN
--
      lv_return_value := iv_transaction_value;
--
    ELSE
--
      IF ( iv_contract_status = cv_contract_status_input ) THEN
--
        lv_return_value := iv_transaction_value;
--
      ELSE
--
        IF ( iv_cooperate_flag = cv_cooperate_none ) THEN
--
          lv_return_value := iv_transaction_value;
--
        ELSE
--
          lv_return_value := iv_master_value;
--
        END IF;
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
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
  END decode_bm_info;
--
  /**********************************************************************************
   * Function Name    : get_base_leader_name
   * Description      : ���s���������擾
   ***********************************************************************************/
  FUNCTION get_base_leader_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_leader_name';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_leader_name               xxcso_employees_v2.full_name%TYPE;
--
  BEGIN
--
    BEGIN
--
      SELECT  xev.full_name
      INTO    lv_leader_name
      FROM    xxcso_employees_v2  xev
      WHERE   (
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_new = iv_base_code)
                AND
                (xev.position_code_new  = '002')
               )
               OR
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_old = iv_base_code)
                AND
                (xev.position_code_old  = '002')
               )
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF ( lv_leader_name IS NULL ) THEN
--
      BEGIN
--
        SELECT  xev.full_name
        INTO    lv_leader_name
        FROM    xxcso_employees_v2  xev
        WHERE   (
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_new = iv_base_code)
                  AND
                  (xev.position_code_new  = '003')
                 )
                 OR
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_old = iv_base_code)
                  AND
                  (xev.position_code_old  = '003')
                 )
                )
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    RETURN lv_leader_name;
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_leader_name;
--
  /**********************************************************************************
   * Function Name    : get_base_leader_pos_name
   * Description      : ���s���������E�ʖ��擾
   ***********************************************************************************/
  FUNCTION get_base_leader_pos_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_leader_pos_name';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_position_name             xxcso_employees_v2.position_name_new%TYPE;
--
  BEGIN
--
    BEGIN
--
      SELECT  xxcso_util_common_pkg.get_emp_parameter(
                xev.position_name_new
               ,xev.position_name_old
               ,xev.issue_date
               ,xxcso_util_common_pkg.get_online_sysdate
              )
      INTO    lv_position_name
      FROM    xxcso_employees_v2  xev
      WHERE   (
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_new = iv_base_code)
                AND
                (xev.position_code_new  = '002')
               )
               OR
               (
                (TO_DATE(xev.issue_date, 'YYYYMMDD')
                  > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                AND
                (xev.work_base_code_old = iv_base_code)
                AND
                (xev.position_code_old  = '002')
               )
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF ( lv_position_name IS NULL ) THEN
--
      BEGIN
--
        SELECT  xxcso_util_common_pkg.get_emp_parameter(
                  xev.position_name_new
                 ,xev.position_name_old
                 ,xev.issue_date
                 ,xxcso_util_common_pkg.get_online_sysdate
                )
        INTO    lv_position_name
        FROM    xxcso_employees_v2  xev
        WHERE   (
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_new = iv_base_code)
                  AND
                  (xev.position_code_new  = '003')
                 )
                 OR
                 (
                  (TO_DATE(xev.issue_date, 'YYYYMMDD')
                    > TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                  AND
                  (xev.work_base_code_old = iv_base_code)
                  AND
                  (xev.position_code_old  = '003')
                 )
                )
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    RETURN lv_position_name;
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_leader_pos_name;
--
  /**********************************************************************************
   * Function Name    : chk_double_byte_kana
   * Description      : �S�p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte_kana';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
    ln_length                    NUMBER;
--
  BEGIN
--
    lv_return_value := '1';
    ln_length := LENGTH(iv_value);
--
    << dobule_byte_check_loop >>
    FOR idx IN 1..ln_length
    LOOP
--
      lb_return_value := xxccp_common_pkg.chk_double_byte_kana(SUBSTR(iv_value, idx, 1));
--
      IF NOT ( lb_return_value ) THEN
--
        lv_return_value := '0';
        EXIT dobule_byte_check_loop;
--
      END IF;
--
    END LOOP dobule_byte_check_loop;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_double_byte_kana;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : �d�b�ԍ��`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_tel_format';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xxccp_common_pkg.chk_tel_format(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_tel_format;
--
  /**********************************************************************************
   * Function Name    : chk_duplicate_vendor_name
   * Description      : ���t�於�d���`�F�b�N
   ***********************************************************************************/
-- 20090408_N.Yanagitaira T1_0364 Mod START
--  FUNCTION chk_duplicate_vendor_name(
--    iv_dm1_vendor_name             IN  VARCHAR2
--   ,iv_dm2_vendor_name             IN  VARCHAR2
--   ,iv_dm3_vendor_name             IN  VARCHAR2
--   ,in_contract_management_id      IN  NUMBER
--   ,in_dm1_supplier_id             IN  NUMBER
--   ,in_dm2_supplier_id             IN  NUMBER
--   ,in_dm3_supplier_id             IN  NUMBER
--
--  ) RETURN VARCHAR2
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_duplicate_vendor_name';
--    -- ===============================
--    -- ���[�J���ϐ�
--    -- ===============================
--    lv_return_value              VARCHAR2(1);
--    ln_cnt                       NUMBER;
----
--  BEGIN
----
--    lv_return_value := 0;
----
--    ln_cnt := 0;
----
--    BEGIN
----
--      -- ���t��e�[�u���d���`�F�b�N
--      SELECT    COUNT(delivery_id)
--      INTO      ln_cnt
--      FROM      xxcso_destinations xd
--      WHERE     xd.payment_name IN (iv_dm1_vendor_name, iv_dm2_vendor_name, iv_dm3_vendor_name)
---- 20090403_N.Yanagitaira T1_0223 Mod START
----        AND     xd.supplier_id NOT IN (in_dm1_supplier_id, in_dm2_supplier_id, in_dm3_supplier_id)
----        AND     (
----                  (
----                    ( in_contract_management_id IS NOT NULL ) AND (xd.contract_management_id <> in_contract_management_id)
----                  )
----                  OR
----                  (
----                    ( in_contract_management_id IS NULL) AND (1 = 1)
----                  )
----                )
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    xxcso_destinations xd2
--                  WHERE   xd2.contract_management_id = xd.contract_management_id
--                    AND   xd2.contract_management_id = NVL(in_contract_management_id, fnd_api.g_miss_num)
--                )
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    xxcso_destinations xd2
--                  WHERE   xd2.contract_management_id = xd.contract_management_id
--                    AND   xd2.supplier_id IN
--                            (
--                              NVL(in_dm1_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm2_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm3_supplier_id, fnd_api.g_miss_num)
--                            )
--                )
---- 20090403_N.Yanagitaira T1_0223 Mod END
--        AND      ROWNUM = 1
--      ;
----
--      IF ( ln_cnt <> 0) THEN
--        lv_return_value := '1';
--        RETURN lv_return_value;
--      END IF;
----
--    END;
----
--    ln_cnt := 0;
----
--    BEGIN
----
--      -- �d����}�X�^�d���`�F�b�N
--      SELECT    COUNT(vendor_id)
--      INTO      ln_cnt
--      FROM      po_vendors pv
--      WHERE     pv.vendor_name IN (iv_dm1_vendor_name, iv_dm2_vendor_name, iv_dm3_vendor_name)
---- 20090403_N.Yanagitaira T1_0223 Mod START
----        AND     pv.vendor_id NOT IN (in_dm1_supplier_id, in_dm2_supplier_id, in_dm3_supplier_id)
--        AND     NOT EXISTS
--                (
--                  SELECT  1
--                  FROM    po_vendors pv2
--                  WHERE   pv2.vendor_id = pv.vendor_id
--                    AND   pv2.vendor_id IN
--                            (
--                              NVL(in_dm1_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm2_supplier_id, fnd_api.g_miss_num)
--                             ,NVL(in_dm3_supplier_id, fnd_api.g_miss_num)
--                            )
--                )
---- 20090403_N.Yanagitaira T1_0223 Mod END
--        AND     ROWNUM = 1
--      ;
----
--      IF ( ln_cnt <> 0) THEN
--        lv_return_value := '1';
--        RETURN lv_return_value;
--      END IF;
----
--    END;
----
--    RETURN lv_return_value;
----
  PROCEDURE chk_duplicate_vendor_name(
    iv_bm1_vendor_name             IN  VARCHAR2
   ,iv_bm2_vendor_name             IN  VARCHAR2
   ,iv_bm3_vendor_name             IN  VARCHAR2
   ,in_bm1_supplier_id             IN  NUMBER
   ,in_bm2_supplier_id             IN  NUMBER
   ,in_bm3_supplier_id             IN  NUMBER
   ,iv_operation_mode              IN  VARCHAR2
   ,on_bm1_dup_count               OUT NUMBER
   ,on_bm2_dup_count               OUT NUMBER
   ,on_bm3_dup_count               OUT NUMBER
   ,ov_bm1_contract_number         OUT VARCHAR2
   ,ov_bm2_contract_number         OUT VARCHAR2
   ,ov_bm3_contract_number         OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_duplicate_vendor_name';
    cv_operation_apply           CONSTANT VARCHAR2(30)    := 'APPLY';
    cv_operation_submit          CONSTANT VARCHAR2(30)    := 'SUBMIT';
    cv_contract_status_submit    CONSTANT VARCHAR2(1)     := '1';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_err_vendor_duplicate      CONSTANT VARCHAR2(1)     := '1';
    cv_err_cooperate             CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_bm1_dup_count             NUMBER;
    ln_bm2_dup_count             NUMBER;
    ln_bm3_dup_count             NUMBER;
    lv_bm1_contract_number       xxcso_contract_managements.contract_number%TYPE;
    lv_bm2_contract_number       xxcso_contract_managements.contract_number%TYPE;
    lv_bm3_contract_number       xxcso_contract_managements.contract_number%TYPE;
--
  BEGIN
--
    -- ������
    ln_bm1_dup_count       := 0;
    ln_bm2_dup_count       := 0;
    ln_bm3_dup_count       := 0;
    lv_bm1_contract_number := NULL;
    lv_bm2_contract_number := NULL;
    lv_bm3_contract_number := NULL;
    on_bm1_dup_count       := 0;
    on_bm2_dup_count       := 0;
    on_bm3_dup_count       := 0;
    ov_bm1_contract_number := NULL;
    ov_bm2_contract_number := NULL;
    ov_bm3_contract_number := NULL;
    ov_retcode             := xxcso_common_pkg.gv_status_normal;
    ov_errbuf              := NULL;
    ov_errmsg              := NULL;
--
    BEGIN
--
      -- �d����}�X�^�d���`�F�b�N
      SELECT   (
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm1_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv1
                             WHERE   pv1.vendor_id = pv.vendor_id
                               AND   pv1.vendor_id = NVL(in_bm1_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm1_count
              ,(
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm2_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv2
                             WHERE   pv2.vendor_id = pv.vendor_id
                               AND   pv2.vendor_id = NVL(in_bm2_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm2_count
              ,(
                 SELECT    COUNT('X')
                 FROM      po_vendors pv
                 WHERE     pv.vendor_name = iv_bm3_vendor_name
                 AND       NOT EXISTS
                           (
                             SELECT  1
                             FROM    po_vendors pv3
                             WHERE   pv3.vendor_id = pv.vendor_id
                               AND   pv3.vendor_id = NVL(in_bm3_supplier_id, fnd_api.g_miss_num)
                           )
                 AND       ROWNUM = 1
               ) AS bm3_count
      INTO     ln_bm1_dup_count
              ,ln_bm2_dup_count
              ,ln_bm3_dup_count
      FROM     DUAL
      ;
    END;
--
    -- �d���`�F�b�N���� BM1�`3��1���ł����݂���ꍇ�̓G���[�Ƃ���
    IF ( ( ln_bm1_dup_count <> 0) OR ( ln_bm2_dup_count <> 0) OR ( ln_bm3_dup_count <> 0) ) THEN
        on_bm1_dup_count := ln_bm1_dup_count;
        on_bm2_dup_count := ln_bm2_dup_count;
        on_bm3_dup_count := ln_bm3_dup_count;
        ov_retcode       := cv_err_vendor_duplicate;
      RETURN;
    END IF;
--
    -- �m��{�^���̏ꍇ�̂݃`�F�b�N
    IF ( iv_operation_mode = cv_operation_submit ) THEN
--
      ln_bm1_dup_count := 0;
      ln_bm2_dup_count := 0;
      ln_bm3_dup_count := 0;
--
      BEGIN
--
        -- ���t��e�[�u���d���`�F�b�N
        SELECT    (
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm1_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd1
                                WHERE   xd1.contract_management_id = xd.contract_management_id
                                  AND   xd1.supplier_id            = NVL(in_bm1_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm1_dup_number
                 ,(
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm2_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd2
                                WHERE   xd2.contract_management_id = xd.contract_management_id
                                  AND   xd2.supplier_id            = NVL(in_bm2_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm2_dup_number
                 ,(
                    SELECT    xcm.contract_number
                    FROM      xxcso_contract_managements xcm
                             ,xxcso_destinations xd
                    WHERE     xcm.status                 = cv_contract_status_submit
                    AND       xcm.cooperate_flag         = cv_cooperate_none
                    AND       xd.contract_management_id  = xcm.contract_management_id
                    AND       xd.payment_name            = iv_bm3_vendor_name
                    AND       NOT EXISTS
                              (
                                SELECT  1
                                FROM    xxcso_destinations xd3
                                WHERE   xd3.contract_management_id = xd.contract_management_id
                                  AND   xd3.supplier_id            = NVL(in_bm3_supplier_id, fnd_api.g_miss_num)
                              )
                    AND       ROWNUM = 1
                  ) AS bm3_dup_number
        INTO      lv_bm1_contract_number
                 ,lv_bm2_contract_number
                 ,lv_bm3_contract_number
        FROM      DUAL
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_contract_number := NULL;
          lv_bm2_contract_number := NULL;
          lv_bm3_contract_number := NULL;
      END;
--
      -- ��ʂł�BM1�`3����̂��ߌ����̐ݒ�
      IF ( lv_bm1_contract_number IS NOT NULL) THEN
        ln_bm1_dup_count := 1;
      END IF;
      IF ( lv_bm2_contract_number IS NOT NULL) THEN
        ln_bm2_dup_count := 1;
      END IF;
      IF ( lv_bm3_contract_number IS NOT NULL) THEN
        ln_bm3_dup_count := 1;
      END IF;
--
      -- �d���`�F�b�N���� BM1�`3��1���ł����݂���ꍇ�̓G���[�Ƃ���
      IF (    ( lv_bm1_contract_number IS NOT NULL )
           OR ( lv_bm2_contract_number IS NOT NULL )
           OR ( lv_bm3_contract_number IS NOT NULL )
         ) THEN
         on_bm1_dup_count         := ln_bm1_dup_count;
         on_bm2_dup_count         := ln_bm2_dup_count;
         on_bm3_dup_count         := ln_bm3_dup_count;
         ov_bm1_contract_number   := lv_bm1_contract_number;
         ov_bm2_contract_number   := lv_bm2_contract_number;
         ov_bm3_contract_number   := lv_bm3_contract_number;
         ov_retcode               := cv_err_cooperate;
        RETURN;
      END IF;
--
    END IF;
--
-- 20090408_N.Yanagitaira T1_0364 Mod End
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_duplicate_vendor_name;
--
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
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
    cv_cntr_chg_authority        CONSTANT VARCHAR2(100)   := 'XXCSO1_CONTRACT_CHG_AUTHORITY'; --XXCSO:�_��ύX����
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_login_user_id           VARCHAR2(30);        -- ���O�C�����[�U�[
    lv_sales_employee_number   VARCHAR2(30);        -- ����S���c�ƈ� �]�ƈ��ԍ�
    lv_base_code               VARCHAR2(150);       -- ����S���c�ƈ� �������_�R�[�h
    lv_leader_employee_number  VARCHAR2(30);        -- ����S���c�ƈ��㒷 �]�ƈ��ԍ�
    lv_employee_number         VARCHAR2(30);        -- �]�ƈ��ԍ�
    ln_sp_decision_header_id   NUMBER;              -- SP�ꌈ�w�b�_ID
    lv_return_cd               VARCHAR2(1) := '0';  -- ���^�[���R�[�h(0:��������, 1:�c�ƈ�����, 2:���_������)
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
    lt_login_resp              fnd_profile_option_values.profile_option_value%TYPE;  -- �_��ύX����
    lv_sales_emp_base          VARCHAR2(150);       -- �S���c�Ƃ̏������_�R�[�h
    lv_login_emp_base          VARCHAR2(150);
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
  BEGIN
--
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
    /*�v���t�@�C���uXXCSO:�_��ύX�����v���擾*/
    lt_login_resp := fnd_profile.value(cv_cntr_chg_authority);
--
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    -- ���O�C�����[�U�[�̃��[�U�[ID���擾
    SELECT FND_GLOBAL.USER_ID
    INTO   lv_login_user_id
    FROM   DUAL;
--
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
    -- *******************************
    -- ���O�C�����[�U�̏������_�擾
    -- *******************************
    BEGIN
      SELECT ( CASE
                 WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                   xev.work_base_code_new
                 WHEN xev.issue_date > TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                   xev.work_base_code_old
                END
              ) AS login_emp_base
      INTO    lv_login_emp_base
      FROM    xxcso_employees_v2 xev
      WHERE   xev.user_id = lv_login_user_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_login_emp_base := NULL;
    END;
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    -- ************************
    -- ����S���c�ƈ��擾
    -- ************************
    BEGIN
      SELECT   xev.employee_number
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
              ,( CASE
                  WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_new
                  WHEN xev.issue_date >  TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                    xev.work_base_code_old
                  END
               ) AS sales_emp_base
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
      INTO     lv_sales_employee_number
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
              ,lv_sales_emp_base
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
      FROM     xxcso_sp_decision_headers xsdh
              ,xxcso_sp_decision_custs xsdc
              ,xxcso_cust_accounts_v xcav
              ,xxcso_cust_resources_v2 xcrv
              ,xxcso_employees_v2 xev
      WHERE    xsdh.sp_decision_header_id      = iv_sp_decision_header_id
        AND    xsdc.sp_decision_customer_class = '1'
        AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
        AND    xcav.cust_account_id            = xsdc.customer_id
        AND    xcrv.cust_account_id            = xcav.cust_account_id
        AND    xev.employee_number             = xcrv.employee_number
        ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lv_sales_employee_number := NULL;
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
        lv_sales_emp_base        := NULL;
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    WHEN TOO_MANY_ROWS THEN
        lv_sales_employee_number := NULL;
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
        lv_sales_emp_base        := NULL;
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    END;
--
    -- ************************
    -- ����S���c�ƈ��`�F�b�N
    -- ************************
    BEGIN
      SELECT   xev.employee_number
      INTO     lv_employee_number
      FROM     xxcso_employees_v2 xev
      WHERE    xev.user_id         = lv_login_user_id
        AND    xev.employee_number = lv_sales_employee_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_employee_number := NULL;
    END;
--
    -- *******************************************
    -- �l���c�ƈ��`�F�b�N
    -- *******************************************
    BEGIN
      SELECT   xsdh.sp_decision_header_id
      INTO     ln_sp_decision_header_id
      FROM     xxcso_sp_decision_headers xsdh
              ,xxcso_sp_decision_custs xsdc
              ,xxcso_employees_v2 xev
              ,xxcso_cust_accounts_v xcav
      WHERE    xsdh.sp_decision_header_id      = iv_sp_decision_header_id
        AND    xev.user_id                     = lv_login_user_id
        AND    xsdc.sp_decision_customer_class = '1'
        AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
        AND    xcav.cust_account_id            = xsdc.customer_id
        AND    xcav.cnvs_business_person       = xev.employee_number
        ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_sp_decision_header_id := NULL;
    END;
--
    -- ���O�C�����[�U�[�̒S���c�ƈ��A�l���c�ƈ��`�F�b�N
    IF ( ln_sp_decision_header_id IS NOT NULL ) OR ( lv_employee_number IS NOT NULL ) THEN
       lv_return_cd := '1';
    END IF;
--
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add Start */
    -- �S���c�ƈ��Ɠ��ꏊ�����_�̓����`�F�b�N
    IF (
         ( lt_login_resp = '1' )
         AND 
         ( lv_sales_emp_base IS NOT NULL AND lv_login_emp_base IS NOT NULL )
         AND
         ( lv_sales_emp_base = lv_login_emp_base )
       ) THEN
      lv_return_cd := '1';
    END IF;
--
/* 2015/04/17 K.Kiriu E_�{�ғ�_13002�Ή� Add End   */
    -- ����S���c�ƈ����ݒ肳��Ă���ꍇ�̂ݏ㒷�`�F�b�N���{
    IF ( lv_sales_employee_number IS NOT NULL ) THEN
--
      -- ************************
      -- �S���c�ƈ��̏㒷�`�F�b�N
      -- ************************
      BEGIN
        -- ���O�C�����[�U�[�̏㒷�`�F�b�N�A���_�擾
        SELECT   (
                   CASE
                     WHEN xev.issue_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                       xev.work_base_code_new
                     WHEN xev.issue_date > TRUNC(xxcso_util_common_pkg.get_online_sysdate) THEN
                       xev.work_base_code_old
                   END
                 ) AS base_code
        INTO     lv_base_code
        /* 2009.09.09 D.Abe 0001323�Ή� START */
        --FROM     xxcso_employees_v xev
        FROM     xxcso_employees_v2 xev
        /* 2009.09.09 D.Abe 0001323�Ή� END */
                ,fnd_lookup_values_vl flvv
        WHERE    flvv.lookup_type      = cv_lookup_type
          AND    flvv.attribute2       = 'Y'
          AND    NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND    NVL(flvv.end_date_active,   TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND    xev.user_id           = lv_login_user_id
          AND    (
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
                 )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN lv_return_cd;
      END;
--
      -- ���_�R�[�h�擾���̂ݔ���S���c�ƈ��̏㒷�`�F�b�N���{
      BEGIN
        SELECT   xev.employee_number
        INTO     lv_employee_number
        /* 2009.09.09 D.Abe 0001323�Ή� START */
        --FROM     xxcso_employees_v xev
        FROM     xxcso_employees_v2 xev
        /* 2009.09.09 D.Abe 0001323�Ή� END */
        WHERE    xev.employee_number   = lv_sales_employee_number
          AND    (
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
                 )
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN lv_return_cd;
      END;
--
      -- �㒷�Ɣ��f�ł����ꍇ
      IF (lv_employee_number IS NOT NULL) THEN
        lv_return_cd := '2';
      END IF;
--
    END IF;
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
--
  /**********************************************************************************
   * Function Name    : chk_bfa_single_byte_kana
   * Description      : ���p�J�i�`�F�b�N�iBFA�֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_bfa_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_bfa_single_byte_kana';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xx03_chk_kana_pkg.chk_kana(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_bfa_single_byte_kana;
--
  /**********************************************************************************
   * Function Name    : decode_cont_manage_info
   * Description      : �_��Ǘ���񕪊�擾
   ***********************************************************************************/
  FUNCTION decode_cont_manage_info(
    iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'decode_cont_manage_info';
    cv_contract_status_input     CONSTANT VARCHAR2(1)     := '0';
    cv_cooperate_none            CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_normal  CONSTANT VARCHAR2(1)     := '0';
    cv_batch_proc_status_link    CONSTANT VARCHAR2(1)     := '1';
    cv_batch_proc_status_error   CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
--
  BEGIN
--
    IF ( iv_contract_status = cv_contract_status_input ) THEN
--
      lv_return_value := iv_transaction_value;
--
    ELSE
--
      IF ( iv_cooperate_flag = cv_cooperate_none ) THEN
--
        lv_return_value := iv_transaction_value;
--
      ELSE
--
        IF ( iv_batch_proc_status = cv_batch_proc_status_link ) THEN
--
          lv_return_value := iv_master_value;
--
        ELSE
--
          lv_return_value := iv_transaction_value;
--
        END IF;
--
      END IF;
--
    END IF;
--
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END decode_cont_manage_info;
--
  /**********************************************************************************
   * Function Name    : get_sales_charge
   * Description      : �̔��萔�������۔���
   ***********************************************************************************/
  FUNCTION get_sales_charge(
    in_sp_decision_header_id    NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_sales_charge';
    cv_electricity_type_flat     CONSTANT VARCHAR2(1)     := '1';
    cv_electricity_type_change   CONSTANT VARCHAR2(1)     := '2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lv_electricity_type          xxcso_sp_decision_headers.electricity_type%TYPE;
    ln_count                     NUMBER;
--
  BEGIN
--
    -- ���^�[���l��������
    lv_return_value := '0';
--
    BEGIN
      -- �d�C��敪�̎擾
      SELECT xsdh.electricity_type
      INTO   lv_electricity_type
      FROM   xxcso_sp_decision_headers xsdh
      WHERE  xsdh.sp_decision_header_id = in_sp_decision_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_return_value := '1';
    END;
--
-- 2010/11/17 Ver.1.9 [E_�{�ғ�_01954] SCS S.Arizumi MOD START
--    -- �d�C��敪=��z�̏ꍇ�͔̔��萔��������
--    IF ( lv_electricity_type = cv_electricity_type_flat ) THEN
    -- �d�C��敪=��z or �ϓ��̏ꍇ�͔̔��萔��������
    IF (    ( lv_electricity_type = cv_electricity_type_flat   )
         OR ( lv_electricity_type = cv_electricity_type_change ) ) THEN
-- 2010/11/17 Ver.1.9 [E_�{�ғ�_01954] SCS S.Arizumi MOD END
       lv_return_value := '1';
    END IF;
--
    -- BM1�`BM3�̗��E���z�����͂���Ă��邩
    BEGIN
      SELECT COUNT('x')
      INTO   ln_count
      FROM   xxcso_sp_decision_lines xsdl
      WHERE  xsdl.sp_decision_header_id = in_sp_decision_header_id
      AND    (
               (NVL(xsdl.bm1_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm2_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm3_bm_rate, 0) <> 0)
               OR
               (NVL(xsdl.bm1_bm_amount, 0) <> 0)
               OR
               (NVL(xsdl.bm2_bm_amount, 0) <> 0)
               OR
               (NVL(xsdl.bm3_bm_amount, 0) <> 0)
             )
      AND    ROWNUM = 1
      ;
    END;
--
    -- 1���ł����͂���Ă���ꍇ�͔̔��萔������
    IF ( ln_count > 0 ) THEN
       lv_return_value := '1';
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_sales_charge;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  /**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
    lb_return_value := xxccp_common_pkg.chk_double_byte(iv_value);
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_double_byte;
--
  /**********************************************************************************
   * Function Name    : chk_single_byte_kana
   * Description      : ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_single_byte_kana';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
-- 20090605_N.Yanagitaira T1_1307 Mod START
--    lb_return_value := xxccp_common_pkg.chk_single_byte_kana(iv_value);
    -- ���ʊ֐��̔��p�����`�F�b�N���s��
    lb_return_value := xxccp_common_pkg.chk_single_byte(iv_value);
-- 20090605_N.Yanagitaira T1_1307 Mod END
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_single_byte_kana;
--
-- 20090427_N.Yanagitaira T1_0708 Add END
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� START */
   /**********************************************************************************
   * Function Name    : chk_cooperate_wait
   * Description      : �}�X�^�A�g�҂��`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_cooperate_wait(
    iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
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
      -- �}�X�^�A�g�҂��̌_�񏑂��擾
      SELECT xcm1.contract_number
      INTO   lv_contract_number
      FROM   xxcso_contract_managements xcm1
      WHERE  xcm1.contract_management_id IN
            (
             SELECT MAX(xcm2.contract_management_id)
             FROM   xxcso.xxcso_contract_managements xcm2
             WHERE  xcm2.install_account_number = iv_account_number --�ڋq�R�[�h
             AND    xcm2.status            = cv_contract_status_submit
             AND    xcm2.cooperate_flag    = cv_un_cooperate
             AND    xcm2.batch_proc_status IS NULL
            )
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
   /**********************************************************************************
   * Function Name    : reflect_contract_status
   * Description      : �_�񏑊m���񔽉f����
   ***********************************************************************************/
  PROCEDURE reflect_contract_status(
    iv_contract_management_id     IN  VARCHAR2         -- �_��ID
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_status                     IN  VARCHAR2         -- �X�e�[�^�X
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'reflect_contract_status';
    cv_contract_status_apply  CONSTANT VARCHAR2(1)   := '0'; -- �X�e�[�^�X�����͒�
    cv_contract_status_submit CONSTANT VARCHAR2(1)   := '1'; -- �X�e�[�^�X���m���
    cv_contract_status_cancel CONSTANT VARCHAR2(1)   := '9'; -- �X�e�[�^�X�������
    cv_un_cooperate           CONSTANT VARCHAR2(1)   := '0'; -- �}�X�^�A�g�t���O�����A�g
    cv_finish_cooperate       CONSTANT VARCHAR2(1)   := '1'; -- �}�X�^�A�g�t���O���A�g��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_contract_number       xxcso_contract_managements.contract_number%TYPE;
    ln_count                 NUMBER;
    ld_sysdate       DATE;
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ld_sysdate := SYSDATE;

    -- �m��ς݂̏ꍇ
    IF (iv_status = cv_contract_status_submit) THEN
      -- �}�X�^�A�g�҂��̌_�񏑂��X�V
      UPDATE  xxcso_contract_managements xcm
      SET     xcm.status            = cv_contract_status_cancel
             ,xcm.last_updated_by   = fnd_global.user_id
             ,xcm.last_update_date  = ld_sysdate
             ,xcm.last_update_login = fnd_global.login_id
      WHERE  xcm.install_account_number = iv_account_number --�ڋq�R�[�h
      AND    xcm.status             = cv_contract_status_submit
      AND    xcm.cooperate_flag     = cv_un_cooperate
      AND    xcm.batch_proc_status IS NULL
      AND    xcm.contract_management_id <> TO_NUMBER(iv_contract_management_id)
      ;
      
      -- �쐬���̌_�񏑂��X�V
      UPDATE  xxcso_contract_managements xcm
      SET     xcm.status            = cv_contract_status_cancel
             ,xcm.last_updated_by   = fnd_global.user_id
             ,xcm.last_update_date  = ld_sysdate
             ,xcm.last_update_login = fnd_global.login_id
      WHERE  xcm.install_account_number = iv_account_number --�ڋq�R�[�h
      AND    xcm.status             = cv_contract_status_apply
      ;
    
    END IF;

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
  END reflect_contract_status;
--
  /**********************************************************************************
   * Function Name    : chk_validate_db
   * Description      : �c�a�X�V����`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_validate_db(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_validate_db';

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_last_update_date          DATE;
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    lb_return_value := FALSE;

    SELECT  xcm.last_update_date
    INTO    ld_last_update_date
    FROM    xxcso_contract_managements  xcm
    WHERE   xcm.contract_number = iv_contract_number
    ;

    IF ( id_last_update_date < ld_last_update_date ) THEN
      lb_return_value := TRUE;
    END IF;

    IF (lb_return_value) THEN
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_validate_db;
--
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� END */
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� START */
  /**********************************************************************************
   * Function Name    : chk_payment_type_cash
   * Description      : �����x���`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_payment_type_cash(
     in_sp_decision_header_id     IN  NUMBER           -- SP�ꌈ�w�b�_ID
    ,in_supplier_id               IN  NUMBER           -- ���t��ID
    ,iv_delivery_div              IN  VARCHAR2         -- ���t�敪
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_payment_type_cash';
    cv_bm_payment_type4          CONSTANT VARCHAR2(1)     := '4'; -- �����x��
    ct_sp_cust_class_bm1         CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '3'; -- �r�o�ꌈ�ڋq�a�l�P
    ct_sp_cust_class_bm2         CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '4'; -- �r�o�ꌈ�ڋq�a�l�Q
    ct_sp_cust_class_bm3         CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '5'; -- �r�o�ꌈ�ڋq�a�l�R
    ct_delivery_div_bm1          CONSTANT xxcso_destinations.delivery_div%TYPE                    := '1'; -- ���t��a�l�P
    ct_delivery_div_bm2          CONSTANT xxcso_destinations.delivery_div%TYPE                    := '2'; -- ���t��a�l�Q
    ct_delivery_div_bm3          CONSTANT xxcso_destinations.delivery_div%TYPE                    := '3'; -- ���t��a�l�R
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_bm_payment_type           xxcso_sp_decision_custs.bm_payment_type%TYPE;
    ln_customer_id               xxcso_sp_decision_custs.customer_id%TYPE;
    lv_return_value              VARCHAR2(1);
--
  BEGIN
--
    lv_return_value := NULL;
--
    -- SP�̎x���敪�A�x���_ID���擾
    SELECT xsdc.bm_payment_type
          ,xsdc.customer_id
    INTO   lv_bm_payment_type
          ,ln_customer_id
    FROM   xxcso_sp_decision_custs xsdc
    WHERE  xsdc.sp_decision_header_id = in_sp_decision_header_id
    AND    xsdc.sp_decision_customer_class = DECODE(iv_delivery_div
                                                   ,ct_delivery_div_bm1, ct_sp_cust_class_bm1
                                                   ,ct_delivery_div_bm2, ct_sp_cust_class_bm2
                                                   ,ct_delivery_div_bm3, ct_sp_cust_class_bm3
                                                   ) -- �r�o�ꌈ�ڋq�敪
    ;

    -- �x���_ID�����͂���Ă���ꍇ
    IF (ln_customer_id IS NOT NULL) THEN
      -- �r�o�̃x���_ID�ő��t��}�X�^�̎x�����@���擾
      SELECT pvs.attribute4
      INTO   lv_bm_payment_type
      FROM   po_vendor_sites pvs
      WHERE  pvs.vendor_id   = ln_customer_id
      ;
    END IF;
    -- �x�����@�������x���ȊO�̏ꍇ
    IF (lv_bm_payment_type <> cv_bm_payment_type4) THEN
      lv_return_value := '1';
    END IF;

    -- SP�̎x�����@�������x���@���_�񏑂����t��w��̏ꍇ
    IF (lv_return_value IS NULL AND in_supplier_id IS NOT NULL) THEN
      -- �_�񏑂̑��t��}�X�^�̌����x�����擾
      SELECT pvs.attribute4
      INTO   lv_bm_payment_type
      FROM   po_vendor_sites pvs
      WHERE  pvs.vendor_id   = in_supplier_id
      ;
      IF (lv_bm_payment_type <> cv_bm_payment_type4) THEN
        lv_return_value := '2';
      END IF;
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_payment_type_cash;
--
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� END */
/* 2010.03.01 D.Abe E_�{�ғ�_01868�Ή� START */
  /**********************************************************************************
   * Function Name    : chk_install_code
   * Description      : �����R�[�h�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_install_code(
     iv_install_code              IN  VARCHAR2       -- �����R�[�h
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_install_code';
    cv_flag_no                   CONSTANT VARCHAR2(1)     := 'N';      -- �t���ON
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
    lv_return_value              VARCHAR2(1);
--
  BEGIN
--
    lv_return_value := '1';
--
    SELECT COUNT('x')
    INTO   ln_count
    FROM   csi_item_instances cii -- �C���X�g�[���x�[�X�}�X�^
    WHERE  cii.external_reference = iv_install_code
    AND    cii.attribute4         = cv_flag_no;

    IF (ln_count = 0) THEN
      lv_return_value := '1';
    ELSE
      lv_return_value := '0';
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_install_code;
--
/* 2010.03.01 D.Abe E_�{�ғ�_01868�Ή� END */
/* 2011/01/07 Ver1.10 K.Kiriu E_�{�ғ�_02498�Ή� START */
  /**********************************************************************************
   * Function Name    : chk_bank_branch
   * Description      : ��s�x�X�}�X�^�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_bank_branch(
    iv_bank_number  IN  VARCHAR2                       --��s�ԍ�
   ,iv_bank_num     IN  VARCHAR2                       --�x�X�ԍ�
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_bank_branch';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    ln_count                     NUMBER;
--
  BEGIN
--
    ln_count        := 0;
    lv_return_value := 0;
--
    --��s�x�X�}�X�^�̎擾
    SELECT COUNT('x')
    INTO   ln_count
    FROM   ap_bank_branches abb
    WHERE  abb.bank_number = iv_bank_number
    AND    abb.bank_num    = iv_bank_num;
--
    --�f�[�^����
    IF (ln_count = 0) THEN
      lv_return_value := '1';
    --�f�[�^�d��
    ELSIF (ln_count > 1) THEN
      lv_return_value := '2';
    --����
    ELSE
      lv_return_value := '0';
    END IF;
--
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_bank_branch;
/* 2011/01/07 Ver1.10 K.Kiriu E_�{�ғ�_02498�Ή� END */
/* 2011/06/06 Ver1.11 K.Kiriu E_�{�ғ�_01963�Ή� START */
  /**********************************************************************************
   * Function Name    : chk_supplier
   * Description      : �d����}�X�^�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_supplier(
    iv_customer_code    IN  VARCHAR2                   -- �ڋq�R�[�h
   ,in_supplier_id      IN  NUMBER                     -- �d����ID
   ,iv_contract_number  IN  VARCHAR2                   -- �_�񏑔ԍ�
   ,iv_delivery_div     IN  VARCHAR2                   -- ���t�敪
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_supplier';
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_contract_status_submit CONSTANT VARCHAR2(1)   := '1';      -- �X�e�[�^�X���m���
    cv_finish_cooperate       CONSTANT VARCHAR2(1)   := '1';      -- �}�X�^�A�g�t���O���A�g��
    cv_create_vendor          CONSTANT VARCHAR2(6)   := 'CREATE'; -- �O��_�񂪎d����쐬�\��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_vendor_code            po_vendors.segment1%TYPE;      -- �߂�l�p
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR cur_bef_supplier
    IS
      SELECT  bfct.cooperate_flag   cooperate_flag
             ,bfct.supplier_id      supplier_id
             ,bfct.delivery_id      delivery_id
             ,( SELECT pv.segment1 vendor_code
                FROM   po_vendors pv
                WHERE  pv.vendor_id = bfct.supplier_id
              )                     vendor_code
      FROM    (
                SELECT  /*+ LEADING(xcm) */
                        xcm.cooperate_flag  cooperate_flag  -- �}�X�^�A�g�σt���O
                       ,xcd.delivery_id     delivery_id     -- ���t��ID
                       ,xcd.supplier_id     supplier_id     -- �d����ID
                FROM    xxcso_contract_managements xcm   -- �_��Ǘ��}�X�^
                       ,xxcso_destinations         xcd   -- ���t��}�X�^
                WHERE   xcm.install_account_number = iv_customer_code           -- ����̌ڋq
                AND     xcm.status                 = cv_contract_status_submit  -- �m���
                AND     xcm.contract_management_id = xcd.contract_management_id(+)
                AND     xcd.delivery_div(+)        = iv_delivery_div            -- BM1,BM2,BM3�̂����ꂩ
                AND     xcm.contract_number NOT IN (
                          SELECT xcms.contract_number
                          FROM   xxcso_contract_managements xcms
                          WHERE  xcms.contract_number = iv_contract_number
                        )                                                       -- �������g�ȊO
                ORDER BY
/* 2012/08/10 Ver1.12 K.Kiriu E_�{�ғ�_09914�Ή� START */
--                        xcm.contract_number DESC
                        xcm.contract_management_id DESC
/* 2012/08/10 Ver1.12 K.Kiriu E_�{�ғ�_09914�Ή� End   */
              ) bfct
      WHERE   ROWNUM < 3  --�ߋ����߂̂Q�_��̂�(�ő�Ŗ��A�g�ƘA�g�ς̂Q�`�[���`�F�b�N�����)
      ;
--
    rec_bef_supplier cur_bef_supplier%ROWTYPE;
--
  BEGIN
--
    --�߂�l�̏�����
    lt_vendor_code := NULL;
--
    OPEN  cur_bef_supplier;
--
    <<chk_supplier>>
    LOOP
--
      FETCH cur_bef_supplier INTO rec_bef_supplier;
      EXIT WHEN cur_bef_supplier%NOTFOUND;
--
      --�ߋ��_�񂪖��A�g�A���A�Ώۂ̑��t��}�X�^�����݂���ꍇ
      IF ( rec_bef_supplier.cooperate_flag <> cv_finish_cooperate )
        AND ( rec_bef_supplier.delivery_id IS NOT NULL ) THEN
--
        --�ߋ��_��E����_��̂����ꂩ���V�K�Ɏd������쐬�����Ԃ̏ꍇ
        IF ( rec_bef_supplier.supplier_id IS NULL OR in_supplier_id IS NULL ) THEN
          --�ߋ��_��Ɏd���悪�ݒ肳��Ă���ꍇ
          IF ( rec_bef_supplier.supplier_id IS NOT NULL ) THEN
            --�߂�l�ɑO��̎d����R�[�h��ݒ�
            lt_vendor_code := rec_bef_supplier.vendor_code;
          ELSE
            --�߂�l�ɉߋ��_�񂪎d����쐬�\��ł���Ɣ��肷��l��ݒ�
            lt_vendor_code := cv_create_vendor;
          END IF;
          EXIT;  --���[�v�I��
        END IF;
--
      --�ߋ��_�񂪘A�g�ρA���A�Ώۂ̑��t��}�X�^�����݂���ꍇ
      ELSIF ( rec_bef_supplier.cooperate_flag = cv_finish_cooperate )
        AND ( rec_bef_supplier.delivery_id IS NOT NULL ) THEN
--
        --����_�񂪎d�����V�K�ɍ쐬����ꍇ
        IF ( in_supplier_id IS NULL ) THEN
          --�߂�l�ɑO��̎d����R�[�h��ݒ�
          lt_vendor_code := rec_bef_supplier.vendor_code;
          EXIT;  --���[�v�I��
        END IF;
--
      END IF;
--
      --���߂̂P�_��ڂ��m��ς̏ꍇ��1�`�[�̂݃`�F�b�N����ׁA���[�v�I��
      IF ( rec_bef_supplier.cooperate_flag = cv_contract_status_submit ) THEN
        EXIT;  --���[�v�I��
      END IF;
--
    END LOOP chk_supplier;
--
    CLOSE cur_bef_supplier;
--
    RETURN lt_vendor_code;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( cur_bef_supplier%ISOPEN ) THEN
        CLOSE cur_bef_supplier;
      END IF;
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_supplier;
--
  /**********************************************************************************
   * Function Name    : chk_bank_account
   * Description      : ��s�����}�X�^�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_bank_account(
    iv_bank_number         IN  VARCHAR2         -- ��s�ԍ�
   ,iv_bank_num            IN  VARCHAR2         -- �x�X�ԍ�
   ,iv_bank_account_num    IN  VARCHAR2         -- �����ԍ�
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_bank_account';
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_flag_yes                  CONSTANT VARCHAR2(1)     := 'Y';
    cd_process_date              CONSTANT DATE            := TRUNC(xxccp_common_pkg2.get_process_date);  -- �Ɩ��������t
    cv_separate                  CONSTANT VARCHAR2(3)     := ' , ';                                      -- ��ؕ���
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(32767);
    ln_count                     NUMBER;
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR cur_bank_supplier
    IS
      SELECT pv.segment1  vendor_number -- �d����R�[�h
      FROM   ap_bank_branches     bbr   -- ��s�}�X�^
            ,ap_bank_accounts     bac   -- �����}�X�^�r���[
            ,ap_bank_account_uses bau   -- ���������}�X�^�r���[
            ,po_vendors           pv    -- �d����}�X�^
      WHERE  bbr.bank_number                             =  iv_bank_number       -- ��s�ԍ�
      AND    bbr.bank_num                                =  iv_bank_num          -- �x�X�ԍ�
      AND    bbr.bank_branch_id                          =  bac.bank_branch_id
      AND    bac.bank_account_num                        =  iv_bank_account_num  -- �����ԍ�
      AND    bac.bank_account_id                         =  bau.external_bank_account_id
      AND    bau.primary_flag                            =  cv_flag_yes
      AND    TRUNC(NVL(bau.start_date, cd_process_date)) <= cd_process_date      -- �c�Ɠ�
      AND    bau.end_date                                IS NULL                 -- �I�����̐ݒ肪�Ȃ�
      AND    bau.vendor_id                               =  pv.vendor_id
      ORDER BY
             pv.segment1 DESC
      ;
--
    rec_bank_supplier cur_bank_supplier%ROWTYPE;
--
  BEGIN
--
    --������
    ln_count        := 0;
    lv_return_value := NULL;
--
    OPEN  cur_bank_supplier;
--
    <<chk_bank_supplier>>
    LOOP
--
      FETCH cur_bank_supplier INTO rec_bank_supplier;
      EXIT WHEN cur_bank_supplier%NOTFOUND;
--
      -- �����J�E���g
      ln_count := ln_count + 1;
--
      IF ( ln_count = 1) THEN
        -- �d����R�[�h��ݒ肷��
        lv_return_value := rec_bank_supplier.vendor_number;
      ELSE
        -- �d����R�[�h��ݒ肷��(��ؕ����őO�d����R�[�h�ƘA��)
        lv_return_value := lv_return_value || cv_separate || rec_bank_supplier.vendor_number;
      END IF;
--
    END LOOP chk_bank_supplier;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_bank_account;
/* 2011/06/06 Ver1.11 K.Kiriu E_�{�ғ�_01963�Ή� END */
/* 2013/04/01 Ver1.13 K.Kiriu E_�{�ғ�_10413�Ή� START */
  /**********************************************************************************
   * Function Name    : chk_bank_account_change
   * Description      : ��s�����}�X�^�ύX�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_bank_account_change(
    iv_bank_number             IN  VARCHAR2         -- ��s�ԍ�
   ,iv_bank_num                IN  VARCHAR2         -- �x�X�ԍ�
   ,iv_bank_account_num        IN  VARCHAR2         -- �����ԍ�
   ,iv_bank_account_type       IN  VARCHAR2         -- �������(��ʓ��͒l)
   ,iv_account_holder_name_alt IN  VARCHAR2         -- �������`�J�i(��ʓ��͒l)
   ,iv_account_holder_name     IN  VARCHAR2         -- �������`����(��ʓ��͒l)
   ,ov_bank_account_type       OUT VARCHAR2         -- �������(�}�X�^)
   ,ov_account_holder_name_alt OUT VARCHAR2         -- �������`�J�i(�}�X�^)
   ,ov_account_holder_name     OUT VARCHAR2         -- �������`����(�}�X�^)
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_bank_account_change';
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_flag_yes                  CONSTANT VARCHAR2(1)     := 'Y';                                        -- ��t���O
    cd_process_date              CONSTANT DATE            := TRUNC(xxccp_common_pkg2.get_process_date);  -- �Ɩ��������t
    cv_vendor_type               CONSTANT VARCHAR2(3)     := 'VD';                                       -- �d����^�C�v
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
--
  BEGIN
--
    --������
    lv_return_value            := '0';
    ov_bank_account_type       := NULL;
    ov_account_holder_name_alt := NULL;
    ov_account_holder_name     := NULL;
--
    --�w�肳�ꂽ������VD�ȊO�̗L���Ȏd���悪�R�t���ꍇ�A���������擾
    BEGIN
      SELECT bac.bank_account_type       bank_account_type       -- �������
            ,bac.account_holder_name_alt account_holder_name_alt -- �������`�J�i
            ,bac.account_holder_name     account_holder_name     -- �������`
      INTO   ov_bank_account_type
            ,ov_account_holder_name_alt
            ,ov_account_holder_name
      FROM   ap_bank_branches     bbr   -- ��s�}�X�^
            ,ap_bank_accounts     bac   -- �����}�X�^�r���[
            ,ap_bank_account_uses bau   -- ���������}�X�^�r���[
            ,po_vendors           pv    -- �d����}�X�^
      WHERE  bbr.bank_number                             =  iv_bank_number       -- ��s�ԍ�
      AND    bbr.bank_num                                =  iv_bank_num          -- �x�X�ԍ�
      AND    bbr.bank_branch_id                          =  bac.bank_branch_id
      AND    bac.bank_account_num                        =  iv_bank_account_num  -- �����ԍ�
      AND    bac.bank_account_id                         =  bau.external_bank_account_id
      AND    bau.primary_flag                            =  cv_flag_yes    -- ��t���O
      AND    bau.vendor_id                               =  pv.vendor_id
      AND    TRUNC(NVL(bau.start_date, cd_process_date))
                                                        <= cd_process_date -- �J�n��
      AND    TRUNC(NVL(bau.end_date, cd_process_date))
                                                        >= cd_process_date -- �I����
      AND    pv.vendor_type_lookup_code                 <> cv_vendor_type  -- VD(���̋@)�ȊO
      AND    ROWNUM = 1
      ;
      lv_return_value := '1';    --�f�[�^������
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_return_value := '0';  --�f�[�^�����݂��Ȃ�
    END;
--
    --�w�肳�ꂽ������VD�ȊO�̎d���悪���݂���ꍇ
    IF ( lv_return_value <> '0' ) THEN
      --��ʂ�����͂��ꂽ�l�Ɣ�r
      IF   ( iv_bank_account_type       <> ov_bank_account_type )       --������ʂ��قȂ�
        OR ( iv_account_holder_name_alt <> ov_account_holder_name_alt ) --�������`�J�i���قȂ�
        OR ( iv_account_holder_name     <> ov_account_holder_name )     --�������`�������قȂ�
      THEN
        lv_return_value := '2';  --������񂪕ύX����Ă���
      END IF;
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_bank_account_change;
/* 2013/04/01 Ver1.13 K.Kiriu E_�{�ғ�_10413�Ή� END */
--
END xxcso_010003j_pkg;
/
