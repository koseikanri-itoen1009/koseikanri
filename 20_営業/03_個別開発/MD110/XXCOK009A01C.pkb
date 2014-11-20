CREATE OR REPLACE PACKAGE BODY XXCOK009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK009A01C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F����E���㌴���U�֎d��̍쐬 �̔����� MD050_COK_009_A01
 * Version          : 1.6
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                       ��������(A-1)
 *  chk_status_p               ��v���ԃX�e�[�^�X�`�F�b�N(A-2)
 *  get_object_journal_p       �d��Ώێ擾(A-3)
 *  get_entry_accession_info_p �o�^�t�����擾(A-4)
 *  make_gloif_data_p          �d��쐬(A-5)
 *  ins_gl_interface_p         ��ʉ�vOIF�o�^(A-6)
 *  upd_jounal_create_p        �d��쐬�t���O�X�V(A-7)
 *  dlt_decision_flash_p       ������ѐU�֏��e�[�u���̑���f�[�^�폜(A-8)
 *  dlt_decision_fixedness_p   ������ѐU�֏��e�[�u���̊m��f�[�^�폜(A-9)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/12/17     1.0   SCS K.SUENAGA    �V�K�쐬
 * 2009/02/10     1.1   SCS T.OSADA      [��QCOK_027]����v������o�����Ή�
 *                                       [��QCOK_028]���㌴�� NULL �Ή�
 * 2009/05/20     1.2   SCS M.HIRUTA     [��QT1_1099]������ѐU�֏��e�[�u����茴�������擾����ۂ̃J�����ύX
 *                                                    ���㌴�����z �� �c�ƌ���
 * 2009/09/08     1.3   SCS K.YAMAGUCHI  [��Q0001318]���\���P
 * 2009/10/09     1.4   SCS S.MORIYAMA   [��QE_T3_00632]�`�[���͎҂�U�֌��ڋq�̒S���c�ƈ��֕ύX
 *                                                       �d��W��P�ʂɐU�֌��ڋq��ǉ�
 * 2009/12/21     1.5   SCS K.NAKAMURA   [��QE_�{�ғ�_00562]�S���c�ƈ��擾�̔�������C��
 * 2010/01/28     1.6   SCS Y.KUBOSHIMA  [��QE_�{�ғ�_01297]������z,�c�ƌ������}�C�i�X�̏ꍇ�A�d����z�̕������]����悤�ύX
 *
 *****************************************************************************************/
  --===============================
  --�O���[�o���萔
  --===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';
  --�p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(50)  := 'XXCOK009A01C';                     -- �p�b�P�[�W��
  --�v���t�@�C��
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_set_of_bks_name          CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_NAME';               -- ��v���떼
  cv_comp_code                CONSTANT VARCHAR2(100) := 'XXCOK1_AFF1_COMPANY_CODE';         -- ��ЃR�[�h
  cv_table_keep_period        CONSTANT VARCHAR2(100) := 'XXCOK1_TABLE_KEEP_PERIOD';         -- ������ѐU�֏��ێ�����
  cv_acct_prod_sale           CONSTANT VARCHAR2(100) := 'XXCOK1_AFF3_PROD_SALE';            -- ���i���㍂
  cv_acct_prod_sale_cost      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF3_PROD_SALE_COST';       -- ���i���㌴��
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(100) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- �⏕�Ȗڂ̃_�~�[�l
  cv_assi_prod_sale_cost      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF4_PROD_SALE_COST';       -- �󕥕\(���i����)
  cv_gl_category_results      CONSTANT VARCHAR2(100) := 'XXCOK1_GL_CATEGORY_RESULTS';       -- �d��J�e�S��
  cv_gl_source_results        CONSTANT VARCHAR2(100) := 'XXCOK1_GL_SOURCE_RESULTS';         -- �d��\�[�X
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- �ڋq�R�[�h�̃_�~�[�l
  cv_aff6_compuny_dummy       CONSTANT VARCHAR2(100) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- ��ƃR�[�h�̃_�~�[�l
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(100) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- �\��1�̃_�~�[�l
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(100) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- �\��2�̃_�~�[�l
  cv_selling_without_tax_code CONSTANT VARCHAR2(100) := 'XXCOK1_SELLING_WITHOUT_TAX_CODE';  -- �ېŔ���O�ŏ���ŃR�[�h
  --���b�Z�[�W
  cv_lock_err_msg             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10049';                 -- ���b�N�G���[���b�Z�[�W
  cv_concurrent_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';                 -- �p�����[�^�Ȃ����b�Z�[�W
  cv_operation_date           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';                 -- �Ɩ������擾�G���[
  cv_profile_msg              CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_batch_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00026';                 -- �o�b�`���擾�G���[
  cv_group_id_msg             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';                 -- �O���[�vID�擾�G���[
  cv_currency_code_msg        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00029';                 -- �@�\�ʉ݃R�[�h�擾�G���[
  cv_acctg_calendar_msg       CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';                 -- ��v���ԏ��擾�G���[
  cv_open_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';                 -- ��v���ԃI�[�v���G���[
  cv_data_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';                 -- �Ώۃf�[�^���G���[
  cv_slip_number_msg          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';                 -- �`�[�ԍ��擾�G���[
  cv_oif_msg                  CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10041';                 -- ��ʉ�vOIF�o�^�G���[
  cv_upd_msg                  CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10042';                 -- �d��쐬�t���O�X�V�G���[
  cv_lock_warn_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10008';                 -- ���b�N�x�����b�Z�[�W
  cv_flash_flag_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10390';                 -- ����폜�G���[���b�Z�[�W
  cv_settlement_flag_msg      CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10391';                 -- �m��폜�G���[���b�Z�[�W
  cv_normal_msg               CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_warn_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';                 -- �G���[�I�����b�Z�[�W
  cv_error_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';                 -- �x���I�����b�Z�[�W
  cv_target_count_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';                 -- �Ώی������b�Z�[�W
  cv_normal_count_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';                 -- �����������b�Z�[�W
  cv_err_count_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';                 -- �G���[�������b�Z�[�W
  cv_warn_count_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';                 -- �X�L�b�v�������b�Z�[�W
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
  cv_sales_staff_code_msg     CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00033';                 -- �c�ƒS�����擾�G���[���b�Z�[�W
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
  --�X�e�[�^�X
  cv_new_status               CONSTANT VARCHAR2(5)  := 'NEW';                               -- �X�e�[�^�X
  --�t���O
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                                 -- �����t���O
  cv_report_decision_flag     CONSTANT VARCHAR2(1)  := '1';                                 -- ����m��t���O1(�m��)
  cv_flash_report_flag        CONSTANT VARCHAR2(1)  := '0';                                 -- ����m��t���O0(����)
  cv_info_interface_flag      CONSTANT VARCHAR2(1)  := '1';                                 -- ���nI/F�t���O1(I/F��)
  cv_unsettled_interface_flag CONSTANT VARCHAR2(1)  := '0';                                 -- �d��쐬�t���O0(����)
  cv_finish_interface_flag    CONSTANT VARCHAR2(1)  := '1';                                 -- �d��쐬�t���O1(��)
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                                 -- ���уt���O
  --�g�[�N��
  cv_profile_token            CONSTANT VARCHAR2(15) := 'PROFILE';                           -- �g�[�N����
  cv_sales_token              CONSTANT VARCHAR2(15) := 'SALES_DATE';                        -- �g�[�N����
  cv_location_token           CONSTANT VARCHAR2(15) := 'LOCATION_CODE';                     -- �g�[�N����
  cv_proc_token               CONSTANT VARCHAR2(15) := 'PROC_DATE';                         -- �g�[�N����
  cv_count                    CONSTANT VARCHAR2(10) := 'COUNT';                             -- �J�E���g
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
  cv_cust_code_token          CONSTANT VARCHAR2(10) := 'CUST_CODE';                         -- �g�[�N����
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
  --�A�v���P�[�V�����Z�k��
  cv_appli_ar_name            CONSTANT VARCHAR2(10) := 'AR';                                -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name         CONSTANT VARCHAR2(10) := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name         CONSTANT VARCHAR2(10) := 'XXCCP';                             -- �A�v���P�[�V�����Z�k��
  --===============================
  --�O���[�o���ϐ�
  --===============================
  gn_target_cnt               NUMBER         DEFAULT NULL;   -- �Ώی���
  gn_normal_cnt               NUMBER         DEFAULT NULL;   -- ���팏��
  gn_error_cnt                NUMBER         DEFAULT NULL;   -- �G���[����
  gn_warn_cnt                 NUMBER         DEFAULT NULL;   -- �X�L�b�v����
  gn_set_of_bks_id            NUMBER         DEFAULT NULL;   -- ��v����ID
  gv_set_of_bks_name          VARCHAR2(100)  DEFAULT NULL;   -- ��v���떼
  gv_comp_code                VARCHAR2(100)  DEFAULT NULL;   -- ��ЃR�[�h
  gv_table_keep_period        VARCHAR2(100)  DEFAULT NULL;   -- �ێ�����(����)
  gv_acct_prod_sale           VARCHAR2(100)  DEFAULT NULL;   -- ����ȖڃR�[�h(���i���㍂)
  gv_acct_prod_sale_cost      VARCHAR2(100)  DEFAULT NULL;   -- ����ȖڃR�[�h(���i���㌴��)
  gv_aff4_subacct_dummy       VARCHAR2(100)  DEFAULT NULL;   -- �⏕�Ȗڂ̃_�~�[�l
  gv_assi_prod_sale_cost      VARCHAR2(100)  DEFAULT NULL;   -- ���i���㌴��_�󕥕\(���i����)
  gv_gl_category_results      VARCHAR2(100)  DEFAULT NULL;   -- �d��J�e�S��
  gv_gl_source_results        VARCHAR2(100)  DEFAULT NULL;   -- �d��\�[�X
  gv_aff5_customer_dummy      VARCHAR2(100)  DEFAULT NULL;   -- �ڋq�R�[�h�̃_�~�[�l
  gv_aff6_compuny_dummy       VARCHAR2(100)  DEFAULT NULL;   -- ��ƃR�[�h�̃_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(100)  DEFAULT NULL;   -- �\��1�̃_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(100)  DEFAULT NULL;   -- �\��2�̃_�~�[�l
  gv_selling_without_tax_code VARCHAR2(100)  DEFAULT NULL;   -- �ېŔ���O�ŏ���ŃR�[�h
  gd_selling_date             DATE           DEFAULT NULL;   -- ����v���(�O������)
  gv_slip_number              VARCHAR2(100)  DEFAULT NULL;   -- �`�[�ԍ�
  gv_currency_code            VARCHAR2(100)  DEFAULT NULL;   -- �@�\�ʉ݃R�[�h
  gv_batch_name               VARCHAR2(100)  DEFAULT NULL;   -- �o�b�`��
  gv_period_name              VARCHAR2(100)  DEFAULT NULL;   -- ��v���Ԗ�
  gn_group_id                 NUMBER         DEFAULT NULL;   -- �O���[�vID
  gv_division                 VARCHAR2(100)  DEFAULT NULL;   -- ����
  gn_debit_amt                NUMBER         DEFAULT NULL;   -- �ؕ����z
  gn_credit_amt               NUMBER         DEFAULT NULL;   -- �ݕ����z
  gd_operation_date           DATE           DEFAULT NULL;   -- �Ɩ��������t
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR START
--  CURSOR g_get_journal_cur
--  IS
--    SELECT   xsti.selling_date            AS xsti_selling_date           -- ����v���
---- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR START
--           , xsti.selling_from_cust_code  AS selling_from_cust_code      -- ����U�֌��ڋq�R�[�h
---- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR END
--           , xsti.base_code               AS base_code                   -- ����U�֐拒�_�R�[�h
--           , xsti.delivery_base_code      AS delivery_base_code          -- ����U�֌����_�R�[�h
--           , SUM(xsti.selling_amt_no_tax) AS selling_amt                 -- ������z
---- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
----           , SUM(xsti.selling_cost_amt)   AS selling_cost_amt            -- ���㌴�����z
--           , SUM(xsti.trading_cost)       AS trading_cost                -- �c�ƌ���
---- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    FROM     xxcok_selling_trns_info         xsti                        -- ������ѐU�֏��e�[�u��
---- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
----    WHERE    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
----                                          =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- A-2�Ŏ擾��������v���
--    WHERE    xsti.selling_date           >=              TRUNC( gd_selling_date,'MM' )      -- A-2�Ŏ擾��������v���
--    AND      xsti.selling_date            <  ADD_MONTHS( TRUNC( gd_selling_date,'MM' ), 1 ) -- A-2�Ŏ擾��������v���+1����
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--    AND      xsti.report_decision_flag    =  cv_report_decision_flag     -- ����m��t���O1(�m��)
--    AND      xsti.info_interface_flag     =  cv_info_interface_flag      -- ���nI/F�t���O1(I/F��)
--    AND      xsti.gl_interface_flag       =  cv_unsettled_interface_flag -- �d��쐬�t���O0(�d��쐬����)
--    GROUP BY xsti.selling_date
--           , xsti.base_code
--           , xsti.delivery_base_code;
--
  CURSOR g_get_journal_cur
  IS
    SELECT   xsti.selling_date            AS xsti_selling_date           -- ����v���
           , xsti.selling_from_cust_code  AS selling_from_cust_code      -- ����U�֌��ڋq�R�[�h
           , xsti.base_code               AS base_code                   -- ����U�֐拒�_�R�[�h
           , xsti.delivery_base_code      AS delivery_base_code          -- ����U�֌����_�R�[�h
           , SUM(xsti.selling_amt_no_tax) AS selling_amt                 -- ������z
           , SUM(xsti.trading_cost)       AS trading_cost                -- �c�ƌ���
    FROM     xxcok_selling_trns_info         xsti                        -- ������ѐU�֏��e�[�u��
    WHERE    xsti.selling_date           >=              TRUNC( gd_selling_date,'MM' )      -- A-2�Ŏ擾��������v���
    AND      xsti.selling_date            <  ADD_MONTHS( TRUNC( gd_selling_date,'MM' ), 1 ) -- A-2�Ŏ擾��������v���+1����
    AND      xsti.report_decision_flag    =  cv_report_decision_flag     -- ����m��t���O1(�m��)
    AND      xsti.info_interface_flag     =  cv_info_interface_flag      -- ���nI/F�t���O1(I/F��)
    AND      xsti.gl_interface_flag       =  cv_unsettled_interface_flag -- �d��쐬�t���O0(�d��쐬����)
    GROUP BY xsti.selling_date
           , xsti.selling_from_cust_code
           , xsti.base_code
           , xsti.delivery_base_code
    ORDER BY xsti.selling_date
           , xsti.selling_from_cust_code
           , xsti.base_code
           , xsti.delivery_base_code;
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR END
--
  -- ===============================
  -- �O���[�o�����R�[�h�^�C�v
  -- ===============================
  g_get_journal_rtype g_get_journal_cur%ROWTYPE;
    --===============================
  --�O���[�o����O
  --===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�G���[ **
  lock_err_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : dlt_decision_fixedness_p
   * Description      : ������ѐU�֏��e�[�u���̊m��f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE dlt_decision_fixedness_p(
    ov_errbuf  OUT VARCHAR2                                             -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                             -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_decision_fixedness_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;                 -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;                 -- ���b�Z�[�W�o�͕ϐ�
    ld_dlt_possible_date   DATE           DEFAULT NULL;                 -- �i�[�ϐ�
    lv_out_msg             VARCHAR2(5000) DEFAULT NULL;                 -- ���b�Z�[�W�o�͕ϐ�
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR dlt_cur(
             id_dlt_possible_date IN DATE
           )
    IS
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      SELECT 'X'
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
      FROM   xxcok_selling_trns_info     xsti
      WHERE  xsti.selling_date        <= id_dlt_possible_date    -- ADD_MONTHS(�Ɩ��������t, - A-1�Ŏ擾�����ێ�����)
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE START
--      AND    xsti.report_decision_flag = cv_report_decision_flag -- ����m��t���O1(�m��)
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE END
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================================
    --�J�[�\���I�[�v��
    --================================================================
    ld_dlt_possible_date := ADD_MONTHS( gd_operation_date, - gv_table_keep_period );
--
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--    OPEN  dlt_cur(
--            ld_dlt_possible_date
--          );
--    CLOSE dlt_cur;
--    --================================================================
--    --������ѐU�֏��e�[�u���̍폜����
--    --================================================================
--    BEGIN
--      DELETE FROM xxcok_selling_trns_info     xsti
--      WHERE       xsti.selling_date        <= ld_dlt_possible_date     --ADD_MONTHS(�Ɩ��������t,-A-1�Ŏ擾�����ێ�����)
--      AND         xsti.report_decision_flag = cv_report_decision_flag; --����m��t���O1(�m��)
--    EXCEPTION
--      -- *** �m��f�[�^�폜�G���[ ***
--      WHEN OTHERS THEN
--        lv_out_msg  := xxccp_common_pkg.get_msg(
--                         cv_appli_xxcok_name
--                       , cv_settlement_flag_msg
--                       );
--        lb_retcode  := xxcok_common_pkg.put_message_f( 
--                         FND_FILE.OUTPUT    -- �o�͋敪
--                       , lv_out_msg         -- ���b�Z�[�W
--                       , 0                  -- ���s
--                       );
--        ov_errmsg   := NULL;
--        ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode  := cv_status_error;
--    END;
    << purge_loop >>
    FOR dlt_rec IN dlt_cur( ld_dlt_possible_date ) LOOP
      --================================================================
      --������ѐU�֏��e�[�u���̍폜����
      --================================================================
      BEGIN
        DELETE
        FROM  xxcok_selling_trns_info   xsti
        WHERE xsti.selling_trns_info_id = dlt_rec.selling_trns_info_id
        ;
      EXCEPTION
        -- *** �m��f�[�^�폜�G���[ ***
        WHEN OTHERS THEN
          lv_out_msg  := xxccp_common_pkg.get_msg(
                           cv_appli_xxcok_name
                         , cv_settlement_flag_msg
                         );
          lb_retcode  := xxcok_common_pkg.put_message_f( 
                           FND_FILE.OUTPUT    -- �o�͋敪
                         , lv_out_msg         -- ���b�Z�[�W
                         , 0                  -- ���s
                         );
          ov_errmsg   := NULL;
          ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode  := cv_status_error;
          EXIT purge_loop;
      END;
    END LOOP purge_loop;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ���b�N�x�����b�Z�[�W ***
    WHEN lock_err_expt THEN
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE START
--      gn_warn_cnt := gn_warn_cnt + 1;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE END
      lv_out_msg  := xxccp_common_pkg.get_msg(
                       cv_appli_xxcok_name
                     , cv_lock_warn_msg
                     );
      lb_retcode  := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg   := NULL;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode  := cv_status_warn;
      ov_retcode  := cv_status_error;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END dlt_decision_fixedness_p;
--
  /**********************************************************************************
   * Procedure Name   : dlt_decision_flash_p
   * Description      : ������ѐU�֏��e�[�u���̑���f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE dlt_decision_flash_p(
    ov_errbuf  OUT VARCHAR2                                         -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                         -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_decision_flash_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                         -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                         -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode BOOLEAN        DEFAULT NULL;                         -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                         -- ���b�Z�[�W�o�͕ϐ�
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR l_dlt_cur
    IS
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      SELECT 'X'
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
      FROM  xxcok_selling_trns_info      xsti                       -- ������ѐU�֏��e�[�u��
      WHERE xsti.selling_date         <= gd_selling_date            -- ����v���
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD START
      AND   xsti.selling_date         >= TRUNC( ADD_MONTHS( gd_selling_date, -1 ), 'MM' ) -- ����v����̑O������
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD END
      AND   xsti.report_decision_flag  = cv_flash_report_flag       -- ����m��t���O0(����)
      AND   xsti.info_interface_flag   = cv_info_interface_flag     -- ���nI/F�t���O1(I/F��)
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--    --================================================================
--    --�J�[�\���I�[�v��
--    --================================================================
--    OPEN  l_dlt_cur;
--    CLOSE l_dlt_cur;
--    --================================================================
--    --������ѐU�֏��e�[�u���̍폜����
--    --================================================================
--    BEGIN
--      DELETE FROM  xxcok_selling_trns_info      xsti
--      WHERE        xsti.selling_date         <= gd_selling_date         -- ����v���
--      AND          xsti.report_decision_flag  = cv_flash_report_flag    -- ����m��t���O0(����)
--      AND          xsti.info_interface_flag   = cv_info_interface_flag; -- ���nI/F�t���O1(I/F��)
--    EXCEPTION
--      -- *** ����f�[�^�폜�G���[ ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_flash_flag_msg
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- �o�͋敪
--                      , lv_out_msg         -- ���b�Z�[�W
--                      , 0                  -- ���s
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
    --================================================================
    --�J�[�\���I�[�v��
    --================================================================
    << dlt_decision_flash_loop >>
    FOR l_dlt_rec IN l_dlt_cur LOOP
      --================================================================
      --������ѐU�֏��e�[�u���̍폜����
      --================================================================
      BEGIN
        DELETE
        FROM  xxcok_selling_trns_info      xsti
        WHERE xsti.selling_trns_info_id = l_dlt_rec.selling_trns_info_id
        ;
      EXCEPTION
        -- *** ����f�[�^�폜�G���[ ***
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_flash_flag_msg
                        );
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- �o�͋敪
                        , lv_out_msg         -- ���b�Z�[�W
                        , 0                  -- ���s
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
          EXIT dlt_decision_flash_loop;
      END;
    END LOOP dlt_decision_flash_loop;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ���b�N�x�����b�Z�[�W ***
    WHEN lock_err_expt THEN
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE START
--      gn_warn_cnt:= gn_warn_cnt + 1;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE END
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_warn_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode := cv_status_warn;
      ov_retcode := cv_status_error;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END dlt_decision_flash_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_jounal_create_p
   * Description      : �d��쐬�t���O�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_jounal_create_p(
    ov_errbuf  OUT VARCHAR2                                        -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                        -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                       -- ���R�[�h����
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_jounal_create_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                        -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                        -- ���b�Z�[�W�o�͕ϐ�
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama UPD START
--    CURSOR l_upd_cur
--    IS
---- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
----      SELECT 'X'
--      SELECT /*+
--               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
--             */
--             xsti.selling_trns_info_id  AS selling_trns_info_id
---- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--      FROM   xxcok_selling_trns_info     xsti                         -- ������ѐU�֏��e�[�u��
--      WHERE  xsti.report_decision_flag = cv_report_decision_flag      -- ����m��t���O1(�m��)
--      AND    xsti.info_interface_flag  = cv_info_interface_flag       -- ���nI/F�t���O1(I/F��)
--      AND    xsti.gl_interface_flag    = cv_unsettled_interface_flag  -- �d��쐬�t���O0(�d��쐬����)
---- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
----      AND    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
----                                       =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- ����v���
--      AND    xsti.selling_date         = i_get_rec.xsti_selling_date  -- ����v���
---- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--      AND    xsti.base_code            = i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
--      AND    xsti.delivery_base_code   = i_get_rec.delivery_base_code -- ����U�֌����_�R�[�h
--      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
    CURSOR l_upd_cur
    IS
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
      FROM   xxcok_selling_trns_info     xsti                         -- ������ѐU�֏��e�[�u��
      WHERE  xsti.report_decision_flag = cv_report_decision_flag      -- ����m��t���O1(�m��)
      AND    xsti.info_interface_flag  = cv_info_interface_flag       -- ���nI/F�t���O1(I/F��)
      AND    xsti.gl_interface_flag    = cv_unsettled_interface_flag  -- �d��쐬�t���O0(�d��쐬����)
      AND    xsti.selling_date         = i_get_rec.xsti_selling_date  -- ����v���
      AND    xsti.base_code            = i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
      AND    xsti.delivery_base_code   = i_get_rec.delivery_base_code -- ����U�֌����_�R�[�h
      AND    xsti.selling_from_cust_code = i_get_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama UPD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�J�[�\���I�[�v��
    --==============================================================
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--    OPEN  l_upd_cur;
--    CLOSE l_upd_cur;
--    --==============================================================
--    --������ѐU�֏��e�[�u���̍X�V����
--    --===============================================================
--    BEGIN
----
--      UPDATE xxcok_selling_trns_info       xsti
--      SET    xsti.gl_interface_flag      = cv_finish_interface_flag      -- �d��쐬�t���O1(�d��쐬��)
--           , xsti.org_slip_number        = gv_slip_number                -- A-4�Ŏ擾�����`�[�ԍ�
--           , xsti.last_updated_by        = cn_last_updated_by            -- ���O�C�����[�U�[ID
--           , xsti.last_update_date       = SYSDATE                       -- �V�X�e�����t
--           , xsti.last_update_login      = cn_last_update_login          -- ���O�C��ID
--           , xsti.request_id             = cn_request_id                 -- �R���J�����g�v��ID
--           , xsti.program_application_id = cn_program_application_id     -- �v���O�����E�A�v���P�[�V����ID
--           , xsti.program_id             = cn_program_id                 -- �R���J�����g�E�v���O����ID
--           , xsti.program_update_date    = SYSDATE                       -- �V�X�e�����t
--      WHERE  xsti.report_decision_flag   = cv_report_decision_flag       -- ����m��t���O1(�m��)
--      AND    xsti.info_interface_flag    = cv_info_interface_flag        -- ���nI/F�t���O1(I/F��)
--      AND    xsti.gl_interface_flag      = cv_unsettled_interface_flag   -- �d��쐬�t���O0(�d��쐬����)
--      AND    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
--                                         =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- ����v���
--      AND    xsti.base_code              = i_get_rec.base_code           -- ����U�֐拒�_�R�[�h
--      AND    xsti.delivery_base_code     = i_get_rec.delivery_base_code; -- ����U�֌����_�R�[�h
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- *** �d��쐬�t���O�X�V�G���[ ***
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_upd_msg
--                      , cv_sales_token
--                      , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
--                      , cv_location_token
--                      , i_get_rec.base_code
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- �o�͋敪
--                      , lv_out_msg         -- ���b�Z�[�W
--                      , 0                  -- ���s
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
    << update_xsti_loop >>
    FOR l_upd_rec IN l_upd_cur LOOP
      --==============================================================
      --������ѐU�֏��e�[�u���̍X�V����
      --===============================================================
      BEGIN
        UPDATE xxcok_selling_trns_info       xsti
        SET    xsti.gl_interface_flag      = cv_finish_interface_flag      -- �d��쐬�t���O1(�d��쐬��)
             , xsti.org_slip_number        = gv_slip_number                -- A-4�Ŏ擾�����`�[�ԍ�
             , xsti.last_updated_by        = cn_last_updated_by            -- ���O�C�����[�U�[ID
             , xsti.last_update_date       = SYSDATE                       -- �V�X�e�����t
             , xsti.last_update_login      = cn_last_update_login          -- ���O�C��ID
             , xsti.request_id             = cn_request_id                 -- �R���J�����g�v��ID
             , xsti.program_application_id = cn_program_application_id     -- �v���O�����E�A�v���P�[�V����ID
             , xsti.program_id             = cn_program_id                 -- �R���J�����g�E�v���O����ID
             , xsti.program_update_date    = SYSDATE                       -- �V�X�e�����t
        WHERE  xsti.selling_trns_info_id   = l_upd_rec.selling_trns_info_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- *** �d��쐬�t���O�X�V�G���[ ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_upd_msg
                        , cv_sales_token
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--                        , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                        , TO_CHAR(i_get_rec.xsti_selling_date,'YYYY/MM/DD')
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
                        , cv_location_token
                        , i_get_rec.base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- �o�͋敪
                        , lv_out_msg         -- ���b�Z�[�W
                        , 0                  -- ���s
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
          EXIT update_xsti_loop;
      END;
    END LOOP update_xsti_loop;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ���b�N�G���[���b�Z�[�W ***
    WHEN lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
                    , cv_sales_token
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    , TO_CHAR(i_get_rec.xsti_selling_date,'YYYY/MM/DD')
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
                    , cv_location_token
                    , i_get_rec.base_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_jounal_create_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface_p
   * Description      : ��ʉ�vOIF�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface_p(
    ov_errbuf          OUT VARCHAR2                               -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2                               -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2                               -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_division        IN  VARCHAR2                               -- ����
  , iv_account_class   IN  VARCHAR2                               -- ����Ȗ�
  , iv_adminicle_class IN  VARCHAR2                               -- �⏕�Ȗ�
  , in_debit_amt       IN  NUMBER                                 -- �ؕ����z
  , in_credit_amt      IN  NUMBER                                 -- �ݕ����z
  , iv_base_code       IN  VARCHAR2                               -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
  , iv_sales_staff_code IN VARCHAR2                               -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_interface_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                       -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode BOOLEAN        DEFAULT NULL;                       -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                       -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --��ʉ�vOIF�փ��R�[�h�̒ǉ�
    --==================================================================
    BEGIN
      INSERT INTO gl_interface(
        status                                          -- �X�e�[�^�X
      , set_of_books_id                                 -- ��v����ID
      , accounting_date                                 -- �d��L�����t
      , currency_code                                   -- �ʉ݃R�[�h
      , date_created                                    -- �V�K�쐬���t
      , created_by                                      -- �V�K�쐬��ID
      , actual_flag                                     -- �c���^�C�v
      , user_je_category_name                           -- �d��J�e�S����
      , user_je_source_name                             -- �d��\�[�X��
      , segment1                                        -- ���
      , segment2                                        -- ����
      , segment3                                        -- ����Ȗ�
      , segment4                                        -- �⏕�Ȗ�
      , segment5                                        -- �ڋq�R�[�h
      , segment6                                        -- ��ƃR�[�h
      , segment7                                        -- �\��1
      , segment8                                        -- �\��2
      , entered_dr                                      -- �ؕ����z
      , entered_cr                                      -- �ݕ����z
      , reference1                                      -- �o�b�`��
      , reference4                                      -- �d��
      , period_name                                     -- ��v���Ԗ�
      , group_id                                        -- �O���[�vID
      , attribute1                                      -- �ŋ敪
      , attribute3                                      -- �`�[�ԍ�
      , attribute4                                      -- �N�[����
      , attribute5                                      -- �`�[���͎�
      , context                                         -- DFF�R���e�L�X�g
      )
      VALUES(
        cv_new_status                                  -- 'NEW'
      , gn_set_of_bks_id                               -- A-1�Ŏ擾������v����ID
      , gd_selling_date                                -- A-2�Ŏ擾��������v���
      , gv_currency_code                               -- A-1�Ŏ擾�����@�\�ʉ݃R�[�h
      , SYSDATE                                        -- SYSDATE
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      , cn_last_update_login                           -- ���O�C�����[�U�[ID
      , cn_created_by                                  -- ���O�C�����[�U�[ID
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
      , cv_result_flag                                 -- 'A'(����)
      , gv_gl_category_results                         -- A-1�Ŏ擾�����d��J�e�S����
      , gv_gl_source_results                           -- A-1�Ŏ擾�����d��\�[�X��
      , gv_comp_code                                   -- A-1�Ŏ擾������ЃR�[�h
      , iv_division                                    -- �p�����[�^����
      , iv_account_class                               -- �p�����[�^����Ȗ�
      , iv_adminicle_class                             -- �p�����[�^�⏕�Ȗ�
      , gv_aff5_customer_dummy                         -- A-1�Ŏ擾�����ڋq�R�[�h�_�~�[�l
      , gv_aff6_compuny_dummy                          -- A-1�Ŏ擾������ƃR�[�h�_�~�[�l
      , gv_aff7_preliminary1_dummy                     -- A-1�Ŏ擾�����\���P�_�~�[�l
      , gv_aff8_preliminary2_dummy                     -- A-1�Ŏ擾�����\���Q�_�~�[�l
      , in_debit_amt                                   -- �p�����[�^�ؕ����z
      , in_credit_amt                                  -- �p�����[�^�ݕ����z
      , gv_batch_name                                  -- A-1�Ŏ擾�����o�b�`��
      , gv_slip_number                                 -- A-4�Ŏ擾�����`�[�ԍ�
      , gv_period_name                                 -- A-2�Ŏ擾������v���Ԗ�
      , gn_group_id                                    -- A-1�Ŏ擾�����O���[�vID
      , gv_selling_without_tax_code                    -- A-1�Ŏ擾�����ېŔ���O�ŏ���ŃR�[�h
      , gv_slip_number                                 -- A-4�Ŏ擾�����`�[�ԍ�
      , iv_base_code                                   -- A-3�Ŏ擾��������U�֐拒�_�R�[�h
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      , cn_last_update_login                           -- ���O�C�����[�U�[ID
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR START
--      , cn_created_by                                  -- ���O�C�����[�U�[ID
      , iv_sales_staff_code                            -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama REPAIR END
      , gv_set_of_bks_name                             -- A-1�Ŏ擾������v���떼
      );
    EXCEPTION
      -- *** ��ʉ�vOIF�o�^�G���[ ***
      WHEN OTHERS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                         cv_appli_xxcok_name
                       , cv_oif_msg
                       , cv_sales_token
                       , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                       , cv_location_token
                       , iv_base_code
                       );
        lb_retcode  := xxcok_common_pkg.put_message_f( 
                         FND_FILE.OUTPUT    -- �o�͋敪
                       , lv_out_msg         -- ���b�Z�[�W
                       , 0                  -- ���s
                       );
        ov_errmsg   := NULL;
        ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode  := cv_status_error;
    END;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
  END ins_gl_interface_p;
--
  /**********************************************************************************
   * Procedure Name   : make_gloif_data_p
   * Description      : �d��쐬(A-5)
   ***********************************************************************************/
  PROCEDURE make_gloif_data_p(
    ov_errbuf  OUT VARCHAR2                                      -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                      -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                     -- ���R�[�h�̈���
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
  , iv_sales_staff IN jtf_rs_resource_extns.source_number%TYPE   -- �U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
    )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_gloif_data_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                      -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                      -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --���d��p�^�[��1���W�v��̔�����z>0(�ݎ�)
    --==================================================================
    IF( i_get_rec.selling_amt > 0 ) THEN
      --================================================================
      --ins_gl_interface_p�Ăяo��(��ʉ�vOIF�o�^(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- ����(����U�֌����_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale            -- ����Ȗ�(A-1�Ŏ擾��������ȖڃR�[�h(���i���㍂))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- �⏕�Ȗ�(�_�~�[�l)
      , in_debit_amt       => i_get_rec.selling_amt        -- �ؕ����z(������z)
      , in_credit_amt      => 0                            -- �ݕ����z(0)
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- ����(����U�֐拒�_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale            -- ����Ȗ�(A-1�Ŏ擾��������ȖڃR�[�h(���i���㍂))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- �⏕�Ȗ�(�_�~�[�l)
      , in_debit_amt       => 0                            -- �ؕ����z(0)
      , in_credit_amt      => i_get_rec.selling_amt        -- �ݕ����z(������z)
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
    --==================================================================
    --���d��p�^�[��2���W�v��̔�����z<0(�ݎ�)
    --==================================================================
    IF( i_get_rec.selling_amt < 0 ) THEN
      --================================================================
      --ins_gl_interface_p�Ăяo��(��ʉ�vOIF�o�^(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- ����(����U�֌����_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale            -- ����Ȗ�(A-1�Ŏ擾��������ȖڃR�[�h(���i���㍂))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- �⏕�Ȗ�(�_�~�[�l)
      , in_debit_amt       => 0                            -- �ؕ����z(0)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD START
--      , in_credit_amt      => i_get_rec.selling_amt        -- �ݕ����z(������z)
        -- ���z�̕������]
      , in_credit_amt      => -( i_get_rec.selling_amt )   -- �ݕ����z(������z)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD END
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- ����(����U�֐拒�_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale            -- ����Ȗ�(A-1�Ŏ擾��������ȖڃR�[�h(���i���㍂))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- �⏕�Ȗ�(�_�~�[�l)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD START
--      , in_debit_amt       => i_get_rec.selling_amt        -- �ؕ����z(������z)
        -- ���z�̕������]
      , in_debit_amt       => -( i_get_rec.selling_amt )   -- �ؕ����z(������z)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD END
      , in_credit_amt      => 0                            -- �ݕ����z(0)
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    --==================================================================
--    --���d��p�^�[��3���W�v��̔��㌴�����z>0(�ݎ�)
--    --==================================================================
--    IF( i_get_rec.selling_cost_amt > 0 ) THEN
--
    --==================================================================
    --���d��p�^�[��3���W�v��̉c�ƌ���>0(�ݎ�)
    --==================================================================
    IF( i_get_rec.trading_cost > 0 ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      --================================================================
      --ins_gl_interface_p�Ăяo��(��ʉ�vOIF�o�^(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- ����(����U�֌����_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale_cost       -- ����Ȗ�(����ȖڃR�[�h(���i���㌴��))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- �⏕�Ȗ�(���i���㌴��_�󕥕\(���i����))
      , in_debit_amt       => 0                            -- �ؕ����z(0)
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_credit_amt      => i_get_rec.selling_cost_amt   -- �ݕ����z(���㌴�����z)
      , in_credit_amt      => i_get_rec.trading_cost       -- �ݕ����z(�c�ƌ���)
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- ����(����U�֐拒�_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale_cost       -- ����Ȗ�(����ȖڃR�[�h(���i���㌴��))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- �⏕�Ȗ�(���i���㌴��_�󕥕\(���i����))
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_debit_amt       => i_get_rec.selling_cost_amt   -- �ؕ����z(���㌴�����z)
      , in_debit_amt       => i_get_rec.trading_cost       -- �ؕ����z(�c�ƌ���)
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , in_credit_amt      => 0                            -- �ݕ����z(0)
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    --==================================================================
--    --���d��p�^�[��4���W�v��̔��㌴�����z<0(�ؕ�)
--    --==================================================================
--    IF( i_get_rec.selling_cost_amt < 0 ) THEN
--
    --==================================================================
    --���d��p�^�[��4���W�v��̉c�ƌ���<0(�ؕ�)
    --==================================================================
    IF( i_get_rec.trading_cost < 0 ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      --================================================================
      --ins_gl_interface_p�Ăяo��(��ʉ�vOIF�o�^(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- ����(����U�֌����_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale_cost       -- ����Ȗ�(����ȖڃR�[�h(���i���㌴��))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- �⏕�Ȗ�(���i���㌴��_�󕥕\(���i����))
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_debit_amt       => i_get_rec.selling_cost_amt   -- �ؕ����z(���㌴�����z)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD START
--      , in_debit_amt       => i_get_rec.trading_cost       -- �ؕ����z(�c�ƌ���)
        -- ���z�̕������]
      , in_debit_amt       => -( i_get_rec.trading_cost )  -- �ؕ����z(�c�ƌ���)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD END
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , in_credit_amt      => 0                            -- �ؕ����z(0)
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- ����(����U�֐拒�_�R�[�h)
      , iv_account_class   => gv_acct_prod_sale_cost       -- ����Ȗ�(����ȖڃR�[�h(���i���㌴��))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- �⏕�Ȗ�(���i���㌴��_�󕥕\(���i����))
      , in_debit_amt       => 0                            -- �ؕ����z(0)
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_credit_amt      => i_get_rec.selling_cost_amt   -- �ݕ����z(���㌴�����z)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD START
--      , in_credit_amt      => i_get_rec.trading_cost       -- �ݕ����z(�c�ƌ���)
        -- ���z�̕������]
      , in_credit_amt      => -( i_get_rec.trading_cost )  -- �ݕ����z(�c�ƌ���)
-- 2010/01/28 Ver.1.6 [��QE_�{�ғ�_01297] SCS Y.Kuboshima MOD END
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , iv_base_code       => i_get_rec.base_code          -- ����U�֐拒�_�R�[�h
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- ����U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END make_gloif_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_entry_accession_info_p
   * Description      : �o�^�t�����擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_entry_accession_info_p(
    ov_errbuf  OUT VARCHAR2                                               -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                               -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                              -- ���R�[�h����
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_entry_accession_info_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;                           -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;                           -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode     BOOLEAN        DEFAULT NULL;                           -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL;                           -- ���b�Z�[�W�o�͕ϐ�
    --===============================
    --���[�J����O
    --===============================
    get_slip_number_expt EXCEPTION;                                       -- �`�[�ԍ��擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --�o�^�t�����擾
    --==================================================================
    gv_slip_number := xxcok_common_pkg.get_slip_number_f(
                        cv_pkg_name -- �{�@�\�̃p�b�P�[�W��
                      );
    IF( gv_slip_number IS NULL ) THEN
      RAISE get_slip_number_expt;
    END IF;
--
  EXCEPTION
    -- *** �`�[�ԍ��擾�G���[ ***
    WHEN get_slip_number_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_slip_number_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***	
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_entry_accession_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_object_journal_p
   * Description      : �d��Ώێ擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_journal_p(
    ov_errbuf  OUT VARCHAR2                                         -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                         -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_journal_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)    DEFAULT NULL;              -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode            BOOLEAN        DEFAULT NULL;              -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg            VARCHAR2(5000) DEFAULT NULL;              -- ���b�Z�[�W�o�͕ϐ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
    lt_sales_staff_code jtf_rs_resource_extns.source_number%TYPE;   -- �S���c�ƈ��R�[�h
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura DEL START
--    lt_selling_from_cust  xxcok_selling_trns_info.selling_from_cust_code%TYPE;   -- �U�֌��ڋq
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura DEL END
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
    --===============================
    --���[�J����O
    --===============================
    taget_data_expt        EXCEPTION;                               -- �Ώۃf�[�^���G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    <<journal_loop>>
    FOR g_get_journal_rec IN g_get_journal_cur LOOP
      --================================================================
      --�Ώی���
      --================================================================
      gn_target_cnt := gn_target_cnt + 1;
      --================================================================
      --�`�[�ԍ�������
      --================================================================
      gv_slip_number := NULL;
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura MOD START
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
--      IF ( g_get_journal_rec.selling_from_cust_code != lt_selling_from_cust
--          OR g_get_journal_rec.selling_from_cust_code IS NULL )
--      THEN
--        lt_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
--                                   iv_customer_code => g_get_journal_rec.selling_from_cust_code
--                                 , id_proc_date     => g_get_journal_rec.xsti_selling_date
--                               );
--      END IF;
      lt_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
                                 iv_customer_code => g_get_journal_rec.selling_from_cust_code
                               , id_proc_date     => g_get_journal_rec.xsti_selling_date
                             );
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura MOD END
--
      IF ( lt_sales_staff_code IS NOT NULL ) THEN
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
--
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      --================================================================
--      --������z(�Ŕ���)�A���㌴�����z������0�ȊO�̏ꍇ
--      --================================================================
--      IF NOT( (     g_get_journal_rec.selling_amt         = 0 )
--        AND   ( NVL(g_get_journal_rec.selling_cost_amt,0) = 0 ) ) THEN
--
        --================================================================
        --������z(�Ŕ���)�A�c�ƌ���������0�ȊO�̏ꍇ
        --================================================================
        IF NOT( (     g_get_journal_rec.selling_amt     = 0 )
        AND   ( NVL(g_get_journal_rec.trading_cost,0) = 0 ) ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
          --================================================================
          --get_entry_accession_info_p�Ăяo��(�o�^�t�����擾(A-4))
          --================================================================
          get_entry_accession_info_p(
            ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode         -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_get_rec  => g_get_journal_rec  -- ���R�[�h����
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --================================================================
          --make_gloif_data_p�Ăяo��(�d��쐬(A-5))
          --================================================================
          make_gloif_data_p(
            ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode         -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_get_rec  => g_get_journal_rec  -- ���R�[�h����
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
          , iv_sales_staff => lt_sales_staff_code  -- �U�֌��ڋq�S���c�ƈ�
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --================================================================
        --upd_jounal_create_p�Ăяo��(�d��쐬�t���O�X�V(A-7))
        --================================================================
        upd_jounal_create_p(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode         -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_get_rec  => g_get_journal_rec  -- ���R�[�h����
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --==============================================================
        --���������J�E���g
        --==============================================================
        gn_normal_cnt := gn_normal_cnt + 1;
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD START
      ELSE
        --==============================================================
        --�x�������J�E���g
        --==============================================================
        gn_warn_cnt := gn_warn_cnt + 1;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_sales_staff_code_msg
                      , cv_cust_code_token
                      , g_get_journal_rec.selling_from_cust_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_out_msg         -- ���b�Z�[�W
                      , 0                  -- ���s
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
        ov_retcode := cv_status_warn;
      END IF;
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura DEL START
--      lt_selling_from_cust := g_get_journal_rec.selling_from_cust_code;
-- 2009/12/21 Ver.1.5 [��QE_�{�ғ�_00562] SCS K.Nakamura DEL START
-- 2009/10/09 Ver.1.4 [��QE_T3_00632] SCS S.Moriyama ADD END
--
    END LOOP journal_loop;
    --==============================================================
    --�Ώی����̃`�F�b�N
    --==============================================================
    IF( gn_target_cnt = 0 ) THEN
      RAISE taget_data_expt;
    END IF;
--
  EXCEPTION
    --*** �Ώۃf�[�^���G���[ ***
    WHEN taget_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_data_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi REPAIR END
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_object_journal_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_status_p
   * Description      : ��v���ԃX�e�[�^�X�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_status_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_status_p'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;          -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;          -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode        BOOLEAN        DEFAULT NULL;          -- ���b�Z�[�W�o�͕ϐ�
    ln_period_year    NUMBER         DEFAULT NULL;          -- ��v�N�x
    lv_closing_status VARCHAR2(100)  DEFAULT NULL;          -- �X�e�[�^�X
    lb_closing_status BOOLEAN        DEFAULT NULL;          -- �X�e�[�^�X(BOOLEAN)
    lv_out_msg        VARCHAR2(5000) DEFAULT NULL;          -- ���b�Z�[�W�o�͕ϐ�
    --===============================
    --���[�J����O
    --===============================
    acctg_calendar_close_expt EXCEPTION;                    -- �I�[�v���t�@�C�����݃G���[
  --
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --����v���(�O������)���擾
    --==================================================================
    gd_selling_date := LAST_DAY( ADD_MONTHS ( gd_operation_date, -1 ) );
    --==================================================================
    --��v���Ԃ̃X�e�[�^�X���擾
    --==================================================================
    xxcok_common_pkg.get_acctg_calendar_p(
      ov_errbuf                 => lv_errbuf                    -- ���^�[���R�[�h
    , ov_retcode                => lv_retcode                   -- �G���[�o�b�t�@
    , ov_errmsg                 => lv_errmsg                    -- �G���[���b�Z�[�W
    , in_set_of_books_id        => gn_set_of_bks_id             -- A-1�Ŏ擾������v����ID
    , iv_application_short_name => cv_appli_ar_name             -- 'AR'
    , id_object_date            => gd_selling_date              -- ��L�Ŏ擾��������v���
    , iv_adjustment_period_flag => cv_adjustment_period_flag    -- 'N'
    , on_period_year            => ln_period_year               -- ��v�N�x
    , ov_period_name            => gv_period_name               -- ��v���Ԗ�
    , ov_closing_status         => lv_closing_status            -- �X�e�[�^�X
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      -- *** ��v���ԏ��擾�G���[ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_acctg_calendar_msg
                    , cv_proc_token
                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      RAISE global_api_expt;
    END IF;
    --==================================================================
    --��v���Ԃ̃X�e�[�^�X�`�F�b�N
    --==================================================================
    lb_closing_status := xxcok_common_pkg.check_acctg_period_f(
                           gn_set_of_bks_id                     -- A-1�Ŏ擾������v����ID
                         , gd_selling_date                      -- ��L�Ŏ擾��������v���
                         , cv_appli_ar_name                     -- �A�v���P�[�V�����Z�k��
                         );
    IF( lb_closing_status = FALSE ) THEN
      RAISE acctg_calendar_close_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃI�[�v���G���[ ***
    WHEN acctg_calendar_close_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_open_msg
                    , cv_proc_token
                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_status_p;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                         -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                         -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode         BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
    lv_token_value     VARCHAR2(100)  DEFAULT NULL; -- �g�[�N����
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
    --===============================
    --���[�J����O
    --===============================
    profile_expt        EXCEPTION;                  -- �v���t�@�C���擾�G���[
    operation_date_expt EXCEPTION;                  -- �Ɩ��������t�G���[
    batch_expt          EXCEPTION;                  -- �o�b�`�擾�G���[
    group_id_expt       EXCEPTION;                  -- �O���[�vID�擾�G���[
    currency_code_expt  EXCEPTION;                  -- �@�\�ʉ݃R�[�h�擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�R���J�����g���̓p�����[�^�Ȃ����ڂ����b�Z�[�W�o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_concurrent_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    --==============================================================
    --�Ɩ��������t���擾
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --�v���t�@�C�����擾
    --==============================================================
    gn_set_of_bks_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id           )); -- ��v����ID
    gv_set_of_bks_name          := FND_PROFILE.VALUE( cv_set_of_bks_name          ); -- ��v���떼
    gv_comp_code                := FND_PROFILE.VALUE( cv_comp_code                ); -- ��ЃR�[�h
    gv_table_keep_period        := FND_PROFILE.VALUE( cv_table_keep_period        ); -- �ێ�����(����)
    gv_acct_prod_sale           := FND_PROFILE.VALUE( cv_acct_prod_sale           ); -- ����ȖڃR�[�h(���i���㍂)
    gv_aff4_subacct_dummy       := FND_PROFILE.VALUE( cv_aff4_subacct_dummy       ); -- �⏕�Ȗڂ̃_�~�[�l
    gv_acct_prod_sale_cost      := FND_PROFILE.VALUE( cv_acct_prod_sale_cost      ); -- ����ȖڃR�[�h(���i���㌴��)
    gv_assi_prod_sale_cost      := FND_PROFILE.VALUE( cv_assi_prod_sale_cost      ); -- ���i���㌴��_�󕥕\(���i����)
    gv_gl_category_results      := FND_PROFILE.VALUE( cv_gl_category_results      ); -- �d��J�e�S��
    gv_gl_source_results        := FND_PROFILE.VALUE( cv_gl_source_results        ); -- �d��\�[�X
    gv_aff5_customer_dummy      := FND_PROFILE.VALUE( cv_aff5_customer_dummy      ); -- �ڋq�R�[�h�̃_�~�[�l
    gv_aff6_compuny_dummy       := FND_PROFILE.VALUE( cv_aff6_compuny_dummy       ); -- ��ƃR�[�h�̃_�~�[�l
    gv_aff7_preliminary1_dummy  := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy  ); -- �\��1�̃_�~�[�l
    gv_aff8_preliminary2_dummy  := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy  ); -- �\��2�̃_�~�[�l
    gv_selling_without_tax_code := FND_PROFILE.VALUE( cv_selling_without_tax_code ); -- �ېŔ���O�ŏ���ŃR�[�h
--
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_set_of_bks_id );
      RAISE profile_expt;
--
    ELSIF( gv_set_of_bks_name IS NULL ) THEN
      lv_token_value := cv_set_of_bks_name;
      RAISE profile_expt;
--
    ELSIF( gv_comp_code IS NULL ) THEN
      lv_token_value := cv_comp_code;
      RAISE profile_expt;
--
    ELSIF( gv_table_keep_period IS NULL ) THEN
      lv_token_value := cv_table_keep_period;
      RAISE profile_expt;
--
    ELSIF( gv_acct_prod_sale IS NULL ) THEN
      lv_token_value := cv_acct_prod_sale;
      RAISE profile_expt;
--
    ELSIF( gv_acct_prod_sale_cost IS NULL ) THEN
      lv_token_value := cv_acct_prod_sale_cost;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_subacct_dummy IS NULL ) THEN
      lv_token_value := cv_aff4_subacct_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_assi_prod_sale_cost IS NULL ) THEN
      lv_token_value := cv_assi_prod_sale_cost;
      RAISE profile_expt;
--
    ELSIF( gv_gl_category_results IS NULL ) THEN
      lv_token_value := cv_gl_category_results;
      RAISE profile_expt;
--
    ELSIF( gv_gl_source_results IS NULL ) THEN
      lv_token_value := cv_gl_source_results;
      RAISE profile_expt;
--
    ELSIF( gv_aff5_customer_dummy IS NULL ) THEN
      lv_token_value := cv_aff5_customer_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff6_compuny_dummy IS NULL ) THEN
      lv_token_value := cv_aff6_compuny_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff7_preliminary1_dummy IS NULL ) THEN
      lv_token_value := cv_aff7_preliminary1_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff8_preliminary2_dummy IS NULL ) THEN
      lv_token_value := cv_aff8_preliminary2_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_selling_without_tax_code IS NULL ) THEN
      lv_token_value := cv_selling_without_tax_code;
      RAISE profile_expt;
    END IF;
    --==============================================================
    --�o�b�`�����擾
    --==============================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f(
                       gv_gl_category_results -- �d��J�e�S��
                     );
    IF( gv_batch_name IS NULL ) THEN
      RAISE batch_expt;
    END IF;
      --==============================================================
      --�O���[�vID���擾
      --==============================================================
      BEGIN
        SELECT gjs.attribute1         AS group_id -- �O���[�vID
        INTO   gn_group_id
        FROM   gl_je_sources             gjs      -- �d��\�[�X�}�X�^
        WHERE  gjs.user_je_source_name = gv_gl_source_results;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE group_id_expt;
      END;
      --==============================================================
      --�@�\�ʉ݃R�[�h���擾
      --==============================================================
      BEGIN
        SELECT gsob.currency_code  AS currency_code -- �@�\�ʉ݃R�[�h
        INTO   gv_currency_code
        FROM   gl_sets_of_books       gsob          -- ��v����}�X�^
        WHERE  gsob.set_of_books_id = gn_set_of_bks_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE currency_code_expt;
      END;
--
  EXCEPTION
    -- *** �Ɩ��������t�擾�G���[ ***
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_operation_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_msg
                    , cv_profile_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �o�b�`���擾�G���[ ***
    WHEN batch_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_batch_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �O���[�vID�擾�G���[ ***
    WHEN group_id_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_group_id_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �@�\�ʉ݃R�[�h�擾�G���[ ***
    WHEN currency_code_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_currency_code_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                            -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                            -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;            -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;            -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================================
    --�O���[�o���ϐ��̏�����
    --================================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --================================================================
    --init�̌Ăяo��(��������(A-1))
    --================================================================
    init(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --================================================================
    --chk_status_p�Ăяo��(��v���ԃX�e�[�^�X�`�F�b�N(A-2))
    --================================================================
    chk_status_p(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD START
    --================================================================
    --dlt_decision_flash_p�Ăяo��(����m��t���O�u����v�폜(A-8))
    --================================================================
    dlt_decision_flash_p(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --================================================================
    --dlt_decision_fixedness_p�Ăяo��(����m��t���O�u�m��v�폜(A-9))
    --================================================================
    dlt_decision_fixedness_p(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD END
    --================================================================
    --get_object_journal_p�Ăяo��(�d��Ώێ擾(A-3))
    --================================================================
    get_object_journal_p(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD START
    ELSIF( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE START
--    --================================================================
--    --dlt_decision_flash_p�Ăяo��(����m��t���O�u����v�폜(A-8))
--    --================================================================
--    dlt_decision_flash_p(
--      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_warn;
--    END IF;
--    --================================================================
--    --dlt_decision_fixedness_p�Ăяo��(����m��t���O�u�m��v�폜(A-9))
--    --================================================================
--    dlt_decision_fixedness_p(
--      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_warn;
--    END IF;
-- 2009/09/08 Ver.1.3 [��Q0001318] SCS K.Yamaguchi DELETE END
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                              -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                              -- ���^�[���E�R�[�h
  )
  IS
    --===============================
    --���[�J���萔
    --===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    --===============================
    --���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                      -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;                      -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                      -- ���b�Z�[�W�R�[�h
    lb_retcode      BOOLEAN        DEFAULT NULL;                      -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg      VARCHAR2(5000) DEFAULT NULL;                      -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
    --================================================================
    --�R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --================================================================
    --submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    --================================================================
    submain(
      ov_errbuf  => lv_errbuf   -- ���^�[���E�R�[�h
    , ov_retcode => lv_retcode  -- �G���[�E���b�Z�[�W
    , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --================================================================
    --�G���[�o��
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_errmsg          -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- �o�͋敪
                    , lv_errbuf          -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    END IF;
    --================================================================
    --�x���o��
    --================================================================
    IF( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_errmsg          -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- �o�͋敪
                    , lv_errbuf          -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    END IF;
    --================================================================
    --�Ώی����o��
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
    END IF;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_target_count_msg
                    , cv_count
                    , TO_CHAR( gn_target_cnt )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    --================================================================
    --���������o��
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_normal_count_msg
                  , cv_count
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --================================================================
    --�G���[�����o��
    --================================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_err_count_msg
                  , cv_count
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --================================================================
    --�X�L�b�v�����o��
    --================================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_warn_count_msg
                  , cv_count
                  , TO_CHAR( gn_warn_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --================================================================
    --�I�����b�Z�[�W
    --================================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
      retcode         := cv_status_warn;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
      retcode         := cv_status_error;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
  END main;
--
END XXCOK009A01C;
/
