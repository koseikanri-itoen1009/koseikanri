CREATE OR REPLACE PACKAGE BODY XXCOK017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK017A01C(body)
 * Description      : �u�{�U�pFB�f�[�^�쐬�v�ɂĎx���ΏۂƂȂ���
 *                     ���̋@�̔��萔���Ɋւ���d����쐬���AGL���W���[���֘A�g
 * MD.050           : GL�C���^�[�t�F�C�X�iGL I/F�j MD050_COK_017_A01
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_acctg_period     �Ó����`�F�b�N���� (A-2)
 *  get_gl_interface       GL�A�g�f�[�^�̎擾 (A-3)
 *  get_interface_add_info GL�A�g�f�[�^�t�����̎擾 (A-4)
 *  set_insert_info        �d��쐬
 *  insert_interface_info  GL�A�g�f�[�^�̓o�^ (A-5)
 *  update_interface_info  �A�g���ʂ̍X�V (A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   A.Yano           �V�K�쐬
 *  2009/03/03    1.1   A.Yano           [��QCOK_071] GL�L�����̕s��Ή�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                    CONSTANT VARCHAR2(20)  := 'XXCOK017A01C';
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn                 CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error                CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by                  CONSTANT NUMBER        := fnd_global.user_id;         -- CREATED_BY
  cn_last_updated_by             CONSTANT NUMBER        := fnd_global.user_id;         -- LAST_UPDATED_BY
  cn_last_update_login           CONSTANT NUMBER        := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER        := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER        := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER        := fnd_global.conc_program_id; -- PROGRAM_ID
  -- �Z�p���[�^
  cv_msg_part                    CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(1)   := '.';
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_ccp                CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_app_name_cok                CONSTANT VARCHAR2(5)   := 'XXCOK';
  cv_app_short_name              CONSTANT VARCHAR2(5)   := 'SQLGL';
  -- ���b�Z�[�W
  cv_target_rec_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';      -- �Ώی������b�Z�[�W
  cv_success_rec_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';      -- �����������b�Z�[�W
  cv_error_rec_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';      -- �G���[�������b�Z�[�W
  cv_normal_msg                  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';      -- ����I�����b�Z�[�W
  cv_error_msg                   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';      -- �G���[�I���S���[���o�b�N
  cv_no_parameter_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';      -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_process_date_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';      -- �Ɩ��������t�擾�G���[
  cv_profile_err_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';      -- �v���t�@�C���l�擾�G���[
  cv_acctg_chk_err_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00042';      -- ��v���ԃ`�F�b�N�G���[
  cv_gl_info_err_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10265';      -- GL�A�g���擾�G���[
  cv_sales_staff_code_err_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00033';      -- �c�ƒS�����擾�G���[
  cv_acctg_calendar_err_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00011';      -- ��v�J�����_���擾�G���[
  cv_slip_number_err_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00025';      -- �`�[�ԍ��擾�G���[
  cv_group_id_err_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00024';      -- �O���[�vID�擾�G���[
  cv_gl_insert_err_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10268';      -- GL�A�g�f�[�^�o�^�G���[
  cv_bm_balance_err_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00053';      -- �̎�c���e�[�u�����b�N�G���[
  cv_gl_if_update_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10270';      -- GL�A�g���ʍX�V�G���[
  -- �g�[�N��
  cv_cnt_token                   CONSTANT VARCHAR2(10)  := 'COUNT';                 -- �������b�Z�[�W�p�g�[�N����
  cv_profile_token               CONSTANT VARCHAR2(10)  := 'PROFILE';               -- �v���t�@�C����
  cv_proc_date_token             CONSTANT VARCHAR2(10)  := 'PROC_DATE';             -- ������
  cv_dept_code_token             CONSTANT VARCHAR2(10)  := 'DEPT_CODE';             -- ���_�R�[�h
  cv_vend_code_token             CONSTANT VARCHAR2(10)  := 'VEND_CODE';             -- �d����R�[�h
  cv_vend_site_code_token        CONSTANT VARCHAR2(20)  := 'VEND_SITE_CODE';        -- �d����T�C�g�R�[�h
  cv_cust_code_token             CONSTANT VARCHAR2(10)  := 'CUST_CODE';             -- �ڋq�R�[�h
  cv_pay_date_token              CONSTANT VARCHAR2(10)  := 'PAY_DATE';              -- �x����
  -- �v���t�@�C����
  -- ��v���떼
  cv_set_of_bks_name             CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_NAME';
  -- ��v����ID
  cv_set_of_bks_id               CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID';
  -- COK:��ЃR�[�h
  cv_aff1_company_code           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF1_COMPANY_CODE';
  -- COK:����R�[�h_�����o����
  cv_aff2_dept_fin               CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_FIN';
  -- COK:�ڋq�R�[�h_�_�~�[�l
  cv_aff5_customer_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';
  -- COK:��ƃR�[�h_�_�~�[�l
  cv_aff6_company_dummy          CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF6_COMPANY_DUMMY';
  -- COK:�\���R�[�h�P_�_�~�[�l
  cv_aff7_preliminary1_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';
  -- COK:�\���R�[�h�Q_�_�~�[�l
  cv_aff8_preliminary2_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';
  -- COK:����Ȗ�_���̋@�̔��萔��
  cv_aff3_vend_sales_commission  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_VEND_SALES_COMMISSION';
  -- COK:����Ȗ�_�萔��
  cv_aff3_fee                    CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF3_FEE';
  -- COK:����Ȗ�_��������œ�
  cv_aff3_payment_excise_tax     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX';
  -- COK:����Ȗ�_�����a��
  cv_aff3_current_account        CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_CURRENT_ACCOUNT';
  -- COK:�⏕�Ȗ�_���̋@�̔��萔��_���̃��x�[�g
  cv_aff4_vend_sales_rebate      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_VEND_SALES_REBATE';
  -- COK:�⏕�Ȗ�_���̋@�̔��萔��_���̓d�C��
  cv_aff4_vend_sales_elec_cost   CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_VEND_SALES_ELEC_COST';
  -- COK:�⏕�Ȗ�_�萔��_�U���萔��
  cv_aff4_transfer_fee           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_TRANSFER_FEE';
  -- COK:�⏕�Ȗ�_�_�~�[�l
  cv_aff4_subacct_dummy          CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';
  -- COK:�⏕�Ȗ�_�����a��_���Ќ���
  cv_aff4_current_account_our    CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_CURRENT_ACCOUNT_OUR';
  -- COK:��s�萔��_�U���z�
  cv_bank_fee_trans_criterion    CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';
  -- COK:��s�萔��_��z����
  cv_bank_fee_less_criterion     CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';
  -- COK:��s�萔��_��z�ȏ�
  cv_bank_fee_more_criterion     CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';
  -- COK:�̔��萔��_����ŗ�
  cv_bm_tax                      CONSTANT VARCHAR2(20)  := 'XXCOK1_BM_TAX';
  -- COK:FB�x������
  cv_fb_term_name                CONSTANT VARCHAR2(40)  := 'XXCOK1_FB_TERM_NAME';
  -- COK:�d��J�e�S��_�̔��萔��
  cv_gl_category_bm              CONSTANT VARCHAR2(40)  := 'XXCOK1_GL_CATEGORY_BM';
  -- COK:�d��\�[�X_�ʊJ��
  cv_gl_source_cok               CONSTANT VARCHAR2(40)  := 'XXCOK1_GL_SOURCE_COK';
  -- �A�g�X�e�[�^�X�i�{�U�pFB�j
  cv_interface_status_fb         CONSTANT VARCHAR2(1)   := '1';                     -- ������
  -- �A�g�X�e�[�^�X�iGL�j
  cv_if_status_gl_before         CONSTANT VARCHAR2(1)   := '0';                     -- ������
  cv_if_status_gl_after          CONSTANT VARCHAR2(1)   := '1';                     -- ������
  -- �S�x���ۗ̕��t���O
  cv_hold_pay_flag_n             CONSTANT VARCHAR2(1)   := 'N';                     -- �ۗ��Ȃ�
  -- BM�x���敪
  cv_bm_payment_type1            CONSTANT VARCHAR2(1)   := '1';                     -- �{�U�i�ē��L�j
  cv_bm_payment_type2            CONSTANT VARCHAR2(1)   := '2';                     -- �{�U�i�ē����j
  -- ��s�萔�����S��
  cv_chrg_flag_i                 CONSTANT VARCHAR2(1)   := 'I';                     -- �������S
  -- �{�@�\�̃v���O����ID
  cv_program_id                  CONSTANT VARCHAR2(15)  := 'XXCOK017A01C';          -- GL�C���^�t�F�[�X
  -- GL�C���^�t�F�[�X�e�[�u���o�^�t���O
  cv_vend_sales                  CONSTANT VARCHAR2(1)   := 'V';                     -- ���̋@�̔��萔���d��
  cv_backmargin                  CONSTANT VARCHAR2(1)   := 'B';                     -- �̔��萔���d��
  -- GL�C���^�t�F�[�X�e�[�u���o�^�f�[�^
  cv_gl_if_tab_status            CONSTANT VARCHAR2(3)   := 'NEW';                   -- �X�e�[�^�XNEW
  cv_balance_flag_a              CONSTANT VARCHAR2(1)   := 'A';                     -- �c���^�C�v
  -- GL�t�����t���O�i�`�[�P�ʁj
  cv_gl_add_info_y               CONSTANT VARCHAR2(1)   := 'Y';                     -- �擾����
  cv_gl_add_info_n               CONSTANT VARCHAR2(1)   := 'N';                     -- �擾���Ȃ�
  -- ��s�萔���ݒ�t���O�i�d����P�ʁj
  cv_bank_charge_y               CONSTANT VARCHAR2(1)   := 'Y';                     -- �ݒ肷��
  cv_bank_charge_n               CONSTANT VARCHAR2(1)   := 'N';                     -- �ݒ肵�Ȃ�
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target_cnt                   NUMBER                        DEFAULT 0;     -- �Ώی���
  gn_normal_cnt                   NUMBER                        DEFAULT 0;     -- ���팏��
  gn_error_cnt                    NUMBER                        DEFAULT 0;     -- �G���[����
  gn_warn_cnt                     NUMBER                        DEFAULT 0;     -- �X�L�b�v����
  -- �v���t�@�C���l
  gv_set_of_bks_name              VARCHAR2(20)                  DEFAULT NULL;  -- ��v���떼
  gv_set_of_bks_id                VARCHAR2(20)                  DEFAULT NULL;  -- ��v����ID
  gv_aff1_company_code            VARCHAR2(20)                  DEFAULT NULL;  -- ��ЃR�[�h
  gv_aff2_dept_fin                VARCHAR2(20)                  DEFAULT NULL;  -- ����R�[�h_�����o����
  gv_aff5_customer_dummy          VARCHAR2(20)                  DEFAULT NULL;  -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy           VARCHAR2(20)                  DEFAULT NULL;  -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy      VARCHAR2(20)                  DEFAULT NULL;  -- �\���R�[�h�P_�_�~�[�l
  gv_aff8_preliminary2_dummy      VARCHAR2(20)                  DEFAULT NULL;  -- �\���R�[�h�Q_�_�~�[�l
  gv_aff3_vend_sales_commission   VARCHAR2(20)                  DEFAULT NULL;  -- ����Ȗ�_���̋@�̔��萔��
  gv_aff3_fee                     VARCHAR2(20)                  DEFAULT NULL;  -- ����Ȗ�_�萔��
  gv_aff3_payment_excise_tax      VARCHAR2(20)                  DEFAULT NULL;  -- ����Ȗ�_��������œ�
  gv_aff3_current_account         VARCHAR2(20)                  DEFAULT NULL;  -- ����Ȗ�_�����a��
  gv_aff4_vend_sales_rebate       VARCHAR2(20)                  DEFAULT NULL;  -- �⏕�Ȗ�_���̋@�̔��萔��_���̃��x�[�g
  gv_aff4_vend_sales_elec_cost    VARCHAR2(20)                  DEFAULT NULL;  -- �⏕�Ȗ�_���̋@�̔��萔��_���̓d�C��
  gv_aff4_transfer_fee            VARCHAR2(20)                  DEFAULT NULL;  -- �⏕�Ȗ�_�萔��_�U���萔��
  gv_aff4_subacct_dummy           VARCHAR2(20)                  DEFAULT NULL;  -- �⏕�Ȗ�_�_�~�[�l
  gv_aff4_current_account_our     VARCHAR2(20)                  DEFAULT NULL;  -- �⏕�Ȗ�_�����a��_���Ќ���
  gv_bank_fee_trans_criterion     VARCHAR2(20)                  DEFAULT NULL;  -- ��s�萔��_�U���z�
  gv_bank_fee_less_criterion      VARCHAR2(20)                  DEFAULT NULL;  -- ��s�萔��_��z����
  gv_bank_fee_more_criterion      VARCHAR2(20)                  DEFAULT NULL;  -- ��s�萔��_��z�ȏ�
  gv_bm_tax                       VARCHAR2(30)                  DEFAULT NULL;  -- �̔��萔��_����ŗ�
  gv_fb_term_name                 VARCHAR2(10)                  DEFAULT NULL;  -- FB�x������
  gv_gl_category_bm               VARCHAR2(20)                  DEFAULT NULL;  -- �d��J�e�S��_�̔��萔��
  gv_gl_source_cok                VARCHAR2(20)                  DEFAULT NULL;  -- �d��\�[�X_�ʊJ��
  -- ���������擾�f�[�^
  gd_process_date                 DATE                          DEFAULT NULL;  -- �Ɩ��������t
  gd_close_date                   DATE                          DEFAULT NULL;  -- ���ߓ�
  gd_payment_date                 DATE                          DEFAULT NULL;  -- �����̎x����
  gv_batch_name                   VARCHAR2(50)                  DEFAULT NULL;  -- �o�b�`��
  gt_group_id                     gl_je_sources.attribute1%TYPE DEFAULT NULL;  -- �O���[�vID
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- GL�A�g�f�[�^
  CURSOR gl_interface_cur
  IS
    SELECT xbb.base_code                          AS base_code             -- ���_�R�[�h
          ,xbb.supplier_code                      AS supplier_code         -- �d����R�[�h
          ,xbb.supplier_site_code                 AS supplier_site_code    -- �d����T�C�g�R�[�h
          ,xbb.cust_code                          AS cust_code             -- �ڋq�R�[�h
          ,SUM( NVL( xbb.backmargin, 0 ) )        AS backmargin            -- �̔��萔��
          ,SUM( NVL( xbb.backmargin_tax, 0 ) )    AS backmargin_tax        -- �̔��萔������Ŋz
          ,SUM( NVL( xbb.electric_amt, 0 ) )      AS electric_amt          -- �d�C��
          ,SUM( NVL( xbb.electric_amt_tax, 0 ) )  AS electric_amt_tax      -- �d�C������Ŋz
          ,xbb.tax_code                           AS tax_code              -- �ŋ��R�[�h
          ,MAX( xbb.expect_payment_date )         AS expect_payment_date   -- �x���\���
          ,SUM( NVL( xbb.backmargin, 0 )
             +  NVL( xbb.backmargin_tax, 0 )
             +  NVL( xbb.electric_amt, 0 )
             +  NVL( xbb.electric_amt_tax, 0 ) )  AS amt_sum               -- �U���z
          ,pvsa.bank_charge_bearer                AS bank_charge_bearer    -- ��s�萔�����S��
          ,pvsa.payment_currency_code             AS payment_currency_code -- �x���ʉ�
    FROM xxcok_backmargin_balance xbb    -- �̎�c���e�[�u��
        ,hz_cust_accounts         hca    -- �ڋq�}�X�^
        ,po_vendors               pv     -- �d����}�X�^
        ,po_vendor_sites_all      pvsa   -- �d����T�C�g�}�X�^
    WHERE xbb.fb_interface_status     =  cv_interface_status_fb
    AND   xbb.gl_interface_status     =  cv_if_status_gl_before
    AND   xbb.supplier_code           =  pv.segment1
    AND   xbb.supplier_site_code      =  pvsa.vendor_site_code
    AND   pvsa.hold_all_payments_flag =  cv_hold_pay_flag_n
    AND   (   ( pvsa.inactive_date    IS NULL )
            OR( pvsa.inactive_date    >= gd_payment_date ) )
    AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
    AND   xbb.cust_code               =  hca.account_number
    GROUP BY xbb.base_code
            ,xbb.supplier_code
            ,xbb.supplier_site_code
            ,xbb.cust_code
            ,xbb.tax_code
            ,pvsa.bank_charge_bearer
            ,pvsa.payment_currency_code
    ORDER BY xbb.supplier_code
            ,xbb.base_code
  ;
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  -- GL�A�g�f�[�^
  g_gl_interface_rec   gl_interface_cur%ROWTYPE;
  -- ===============================
  -- ���[�U�[��`�O���[�o����O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  global_nodata_expt          EXCEPTION;      -- �f�[�^�擾��O
  global_lock_expt            EXCEPTION;      -- ���b�N������O
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name                    CONSTANT VARCHAR2(4)  := 'init';          -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                     VARCHAR2(2000) DEFAULT NULL;              -- �o�̓��b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_nodata_profile              VARCHAR2(40)   DEFAULT NULL;              -- ���擾�̃v���t�@�C����
    -- *** ���[�J����O ***
    nodata_profile_expt        EXCEPTION;    -- �v���t�@�C���l�擾��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- 1. ���b�Z�[�W�o��
    -- ====================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_no_parameter_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,lv_out_msg
                    ,2
                  );
--
    -- ====================================================
    -- 2. �Ɩ��������t�擾
    -- ====================================================
    gd_process_date := xxccp_common_pkg2.get_process_date();
    IF( gd_process_date IS NULL ) THEN
      RAISE global_nodata_expt;
    END IF;
--
    -- ====================================================
    -- 3. ��v���떼�擾
    -- ====================================================
    gv_set_of_bks_name := FND_PROFILE.VALUE( cv_set_of_bks_name );
    IF( gv_set_of_bks_name IS NULL ) THEN
      lv_nodata_profile := cv_set_of_bks_name;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 4. ��v����ID�擾
    -- ====================================================
    gv_set_of_bks_id   := FND_PROFILE.VALUE( cv_set_of_bks_id );
    IF( gv_set_of_bks_id IS NULL ) THEN
      lv_nodata_profile := cv_set_of_bks_id;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 5. ��ЃR�[�h�擾
    -- ====================================================
    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF( gv_aff1_company_code IS NULL ) THEN
      lv_nodata_profile := cv_aff1_company_code;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 6. �����o�����̕���R�[�h�擾
    -- ====================================================
    gv_aff2_dept_fin := FND_PROFILE.VALUE( cv_aff2_dept_fin );
    IF( gv_aff2_dept_fin IS NULL ) THEN
      lv_nodata_profile := cv_aff2_dept_fin;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 7. �ڋq�R�[�h�̃_�~�[�l�擾
    -- ====================================================
    gv_aff5_customer_dummy := FND_PROFILE.VALUE( cv_aff5_customer_dummy );
    IF( gv_aff5_customer_dummy IS NULL ) THEN
      lv_nodata_profile := cv_aff5_customer_dummy;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 8. ��ƃR�[�h�̃_�~�[�l�擾
    -- ====================================================
    gv_aff6_company_dummy  := FND_PROFILE.VALUE( cv_aff6_company_dummy );
    IF( gv_aff6_company_dummy IS NULL ) THEN
      lv_nodata_profile := cv_aff6_company_dummy;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 9. �\���R�[�h�P�̃_�~�[�l�擾
    -- ====================================================
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );
    IF( gv_aff7_preliminary1_dummy IS NULL ) THEN
      lv_nodata_profile := cv_aff7_preliminary1_dummy;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 10. �\���R�[�h�Q�̃_�~�[�l�擾
    -- ====================================================
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );
    IF( gv_aff8_preliminary2_dummy IS NULL ) THEN
      lv_nodata_profile := cv_aff8_preliminary2_dummy;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 11. ���̋@�̔��萔���̊���ȖڃR�[�h�擾
    -- ====================================================
    gv_aff3_vend_sales_commission := FND_PROFILE.VALUE( cv_aff3_vend_sales_commission );
    IF( gv_aff3_vend_sales_commission IS NULL ) THEN
      lv_nodata_profile := cv_aff3_vend_sales_commission;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 12. �萔���̊���ȖڃR�[�h�擾
    -- ====================================================
    gv_aff3_fee := FND_PROFILE.VALUE( cv_aff3_fee );
    IF( gv_aff3_fee IS NULL ) THEN
      lv_nodata_profile := cv_aff3_fee;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 13. ��������œ��̊���ȖڃR�[�h�擾
    -- ====================================================
    gv_aff3_payment_excise_tax := FND_PROFILE.VALUE( cv_aff3_payment_excise_tax );
    IF( gv_aff3_payment_excise_tax IS NULL ) THEN
      lv_nodata_profile := cv_aff3_payment_excise_tax;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 14. �����a���̊���ȖڃR�[�h�擾
    -- ====================================================
    gv_aff3_current_account := FND_PROFILE.VALUE( cv_aff3_current_account );
    IF( gv_aff3_current_account IS NULL ) THEN
      lv_nodata_profile := cv_aff3_current_account;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 15. ���̋@�̔��萔��_���̃��x�[�g�̕⏕�ȖڃR�[�h�擾
    -- ====================================================
    gv_aff4_vend_sales_rebate := FND_PROFILE.VALUE( cv_aff4_vend_sales_rebate );
    IF( gv_aff4_vend_sales_rebate IS NULL ) THEN
      lv_nodata_profile := cv_aff4_vend_sales_rebate;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 16. ���̋@�̔��萔��_���̓d�C���̕⏕�ȖڃR�[�h�擾
    -- ====================================================
    gv_aff4_vend_sales_elec_cost := FND_PROFILE.VALUE( cv_aff4_vend_sales_elec_cost );
    IF( gv_aff4_vend_sales_elec_cost IS NULL ) THEN
      lv_nodata_profile := cv_aff4_vend_sales_elec_cost;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 17. �萔��_�U���萔���̕⏕�ȖڃR�[�h�擾
    -- ====================================================
    gv_aff4_transfer_fee := FND_PROFILE.VALUE( cv_aff4_transfer_fee );
    IF( gv_aff4_transfer_fee IS NULL ) THEN
      lv_nodata_profile := cv_aff4_transfer_fee;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 18. �⏕�ȖڃR�[�h�̃_�~�[�l�擾
    -- ====================================================
    gv_aff4_subacct_dummy := FND_PROFILE.VALUE( cv_aff4_subacct_dummy );
    IF( gv_aff4_subacct_dummy IS NULL ) THEN
      lv_nodata_profile := cv_aff4_subacct_dummy;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 19. �����a��_���Ќ����̕⏕�ȖڃR�[�h�擾
    -- ====================================================
    gv_aff4_current_account_our :=FND_PROFILE.VALUE( cv_aff4_current_account_our );
    IF( gv_aff4_current_account_our IS NULL ) THEN
      lv_nodata_profile := cv_aff4_current_account_our;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 20. �U���z�̊���z�擾
    -- ====================================================
    gv_bank_fee_trans_criterion := FND_PROFILE.VALUE( cv_bank_fee_trans_criterion );
    IF( gv_bank_fee_trans_criterion IS NULL ) THEN
      lv_nodata_profile := cv_bank_fee_trans_criterion;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 21. �U���z����z�����̋�s�萔���擾
    -- ====================================================
    gv_bank_fee_less_criterion := FND_PROFILE.VALUE( cv_bank_fee_less_criterion );
    IF( gv_bank_fee_less_criterion IS NULL ) THEN
      lv_nodata_profile := cv_bank_fee_less_criterion;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 22. �U���z����z�ȏ�̋�s�萔���擾
    -- ====================================================
    gv_bank_fee_more_criterion := FND_PROFILE.VALUE( cv_bank_fee_more_criterion );
    IF( gv_bank_fee_more_criterion IS NULL ) THEN
      lv_nodata_profile := cv_bank_fee_more_criterion;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 23. ����ŗ��擾
    -- ====================================================
    gv_bm_tax := FND_PROFILE.VALUE( cv_bm_tax );
    IF( gv_bm_tax IS NULL ) THEN
      lv_nodata_profile := cv_bm_tax;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 24. FB�x���������擾
    -- ====================================================
    gv_fb_term_name := FND_PROFILE.VALUE( cv_fb_term_name );
    IF( gv_fb_term_name IS NULL ) THEN
      lv_nodata_profile := cv_fb_term_name;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 25. �̔��萔���̎d��J�e�S���擾
    -- ====================================================
    gv_gl_category_bm := FND_PROFILE.VALUE( cv_gl_category_bm );
    IF( gv_gl_category_bm IS NULL ) THEN
      lv_nodata_profile := cv_gl_category_bm;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 26. �̔��萔���̎d��\�[�X�擾
    -- ====================================================
    gv_gl_source_cok := FND_PROFILE.VALUE( cv_gl_source_cok );
    IF( gv_gl_source_cok IS NULL ) THEN
      lv_nodata_profile := cv_gl_source_cok;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ====================================================
    -- 27. �����̎x�����擾�i���ߓ��E�x�����j
    -- ====================================================
    xxcok_common_pkg.get_close_date_p(
       ov_errbuf     =>   lv_errbuf
      ,ov_retcode    =>   lv_retcode
      ,ov_errmsg     =>   lv_errmsg
      ,id_proc_date  =>   gd_process_date
      ,iv_pay_cond   =>   gv_fb_term_name
      ,od_close_date =>   gd_close_date
      ,od_pay_date   =>   gd_payment_date
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- 28. �O���[�vID�擾
    -- ====================================================
    BEGIN
--
      SELECT gjs.attribute1 AS group_id     -- �O���[�vID
      INTO gt_group_id
      FROM gl_je_sources gjs
      WHERE gjs.user_je_source_name = gv_gl_source_cok
      AND   gjs.language            = USERENV( 'LANG' )
      ;
      IF( gt_group_id IS NULL ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
--
    EXCEPTION
      -- *** �O���[�vID�擾��O ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_group_id_err_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
    -- ====================================================
    -- 29. �o�b�`���擾
    -- ====================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f( gv_gl_category_bm );
--
  EXCEPTION
    --*** �v���t�@�C���l�擾��O ***
    WHEN nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_profile_token
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    --*** �Ɩ��������t�擾��O ***
    WHEN global_nodata_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_process_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_acctg_period
   * Description      : �Ó����`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE check_acctg_period(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name          CONSTANT VARCHAR2(20) := 'check_acctg_period'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;                   -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;       -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg           VARCHAR2(2000) DEFAULT NULL;                   -- �o�̓��b�Z�[�W
    lb_retcode           BOOLEAN        DEFAULT TRUE;                   -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lb_acctb_period_chk  BOOLEAN        DEFAULT FALSE;                  -- ��v���ԃ`�F�b�N�F�L��/����(TRUE/FALSE)
    -- *** ���[�J����O ***
    acctg_chk_expt   EXCEPTION;        -- ��v���ԃ`�F�b�N��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- �Ó����`�F�b�N
    -- ====================================================
    lb_acctb_period_chk := xxcok_common_pkg.check_acctg_period_f(
                              TO_NUMBER( gv_set_of_bks_id )
                             ,gd_payment_date
                             ,cv_app_short_name
                           );
    IF( lb_acctb_period_chk = FALSE ) THEN
      RAISE acctg_chk_expt;
    END IF;
--
  EXCEPTION
    --*** ��v���ԃ`�F�b�N��O ***
    WHEN acctg_chk_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_acctg_chk_err_msg
                      ,iv_token_name1  => cv_proc_date_token
                      ,iv_token_value1 => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END check_acctg_period;
--
  /**********************************************************************************
   * Procedure Name   : get_interface_add_info
   * Description      : GL�A�g�f�[�^�t�����̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_interface_add_info(
     ov_errbuf                    OUT VARCHAR2                                         -- �G���[�E���b�Z�[�W
    ,ov_retcode                   OUT VARCHAR2                                         -- ���^�[���E�R�[�h
    ,ov_errmsg                    OUT VARCHAR2                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_gl_add_info_flag          IN  VARCHAR2                                         -- GL�t�����t���O
    ,iv_bank_charge_flag          IN  VARCHAR2                                         -- ��s�萔���t���O
    ,it_base_code_slip            IN  xxcok_backmargin_balance.base_code%TYPE          -- ���_�R�[�h(MAX)
    ,it_supplier_code_slip        IN  xxcok_backmargin_balance.supplier_code%TYPE      -- �d����R�[�h(MAX)
    ,it_supplier_site_code_slip   IN  xxcok_backmargin_balance.supplier_site_code%TYPE -- �d����T�C�g�R�[�h(MAX)
    ,in_bank_chrg_amt_slip        IN  NUMBER                                           -- �U���萔���z�i�d����j
    ,in_bank_sales_tax_slip       IN  NUMBER                                           -- �U���萔���Ŋz�i�d����j
    ,ov_sales_staff_code          OUT VARCHAR2                                         -- �c�ƒS���҃R�[�h
    ,ov_corp_code                 OUT VARCHAR2                                         -- ��ƃR�[�h
    ,ov_period_name               OUT VARCHAR2                                         -- ��v���Ԗ�
    ,ov_slip_number               OUT VARCHAR2                                         -- �`�[�ԍ�
    ,on_payment_chrg_amt          OUT NUMBER                                           -- �U���萔���z
    ,on_bank_sales_tax            OUT NUMBER                                           -- �U���萔���Ŋz
    ,ot_base_code_vendor          OUT xxcok_backmargin_balance.base_code%TYPE          -- ���_�R�[�h(MAX)
    ,ot_supplier_code_vendor      OUT xxcok_backmargin_balance.supplier_code%TYPE      -- �d����R�[�h(MAX)
    ,ot_supplier_site_code_vendor OUT xxcok_backmargin_balance.supplier_site_code%TYPE -- �d����T�C�g�R�[�h(MAX)
    ,on_bank_chrg_amt_vendor      OUT NUMBER                                           -- �U���萔���z�i�d����j
    ,on_bank_sales_tax_vendor     OUT NUMBER                                           -- �U���萔���Ŋz�i�d����j
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name                CONSTANT VARCHAR2(30) := 'get_interface_add_info';  -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E�o�b�t�@
    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;            -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- �o�̓��b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT TRUE;                        -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    ln_period_year             NUMBER         DEFAULT NULL;                        -- ��v�N�x
    lv_closing_status          VARCHAR2(1)    DEFAULT NULL;                        -- �X�e�[�^�X
    lv_sales_staff_code        VARCHAR2(20)   DEFAULT NULL;                        -- �c�ƒS���҃R�[�h
    lv_corp_code               VARCHAR2(20)   DEFAULT NULL;                        -- ��ƃR�[�h
    lv_period_name             VARCHAR2(20)   DEFAULT NULL;                        -- ��v���Ԗ�
    lv_slip_number             VARCHAR2(20)   DEFAULT NULL;                        -- �`�[�ԍ�
    -- �U���萔��
    ln_bank_chrg_amt           NUMBER         DEFAULT NULL;                        -- �U���萔���z
    ln_bank_sales_tax          NUMBER         DEFAULT NULL;                        -- �U���萔������Ŋz
    -- ��s�萔���Z�o���
    lt_supplier_code           xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- �d����R�[�h
    lt_supplier_site_code      xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- �d����T�C�g�R�[�h
    lt_payment_amt_tax         xxcok_backmargin_balance.payment_amt_tax%TYPE    DEFAULT NULL; -- �x���z
    -- ��s�萔���U�����_���
    lt_base_code_max           xxcok_backmargin_balance.base_code%TYPE          DEFAULT NULL; -- ���_�R�[�h(MAX)
    lt_supplier_code_max       xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- �d����R�[�h(MAX)
    lt_supplier_site_code_max  xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- �d����T�C�g�R�[�h(MAX)
    lt_payment_amt_max         xxcok_backmargin_balance.payment_amt_tax%TYPE    DEFAULT NULL; -- �x���z(MAX)
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- 1. �c�ƒS�����R�[�h���擾
    -- ====================================================
    lv_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
                              g_gl_interface_rec.cust_code
                             ,gd_process_date
                           );
    IF( lv_sales_staff_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_sales_staff_code_err_msg
                      ,iv_token_name1  => cv_cust_code_token
                      ,iv_token_value1 => g_gl_interface_rec.cust_code
                    );
      RAISE global_nodata_expt;
    END IF;
--
    -- ====================================================
    -- 2. ��ƃR�[�h���擾
    -- ====================================================
    lv_corp_code := xxcok_common_pkg.get_companies_code_f( g_gl_interface_rec.cust_code );
    IF( lv_corp_code IS NULL ) THEN
      lv_corp_code := gv_aff6_company_dummy;
    END IF;
--
    -- ====================================================
    -- 3. ��v���Ԗ����擾
    -- ====================================================
    xxcok_common_pkg.get_acctg_calendar_p(
       ov_errbuf                  =>   lv_errbuf
      ,ov_retcode                 =>   lv_retcode
      ,ov_errmsg                  =>   lv_errmsg
      ,in_set_of_books_id         =>   TO_NUMBER( gv_set_of_bks_id )          -- ��v����ID
      ,iv_application_short_name  =>   cv_app_short_name                      -- �A�v���P�[�V�����Z�k��
      ,id_object_date             =>   g_gl_interface_rec.expect_payment_date -- �x���\���
      ,on_period_year             =>   ln_period_year                         -- ��v�N�x
      ,ov_period_name             =>   lv_period_name                         -- ��v���Ԗ�
      ,ov_closing_status          =>   lv_closing_status                      -- �X�e�[�^�X
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_acctg_calendar_err_msg
                      ,iv_token_name1  => cv_proc_date_token
                      ,iv_token_value1 => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
                    );
      RAISE global_nodata_expt;
    END IF;
--
    -- ====================================================
    -- GL�t�����t���O��Y�̏ꍇ
    -- �i���_�R�[�h�܂��͎d����R�[�h���ς�����ꍇ�j
    -- ====================================================
    IF( iv_gl_add_info_flag = cv_gl_add_info_y ) THEN
      -- ====================================================
      -- 4. �`�[�ԍ����擾
      -- ====================================================
      lv_slip_number := xxcok_common_pkg.get_slip_number_f( cv_program_id );
      IF( lv_slip_number IS NULL ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_slip_number_err_msg
                      );
        RAISE global_nodata_expt;
      END IF;
      -- ====================================================
      -- OUT�p�����[�^�ݒ�
      -- ====================================================
      ov_slip_number := lv_slip_number;        -- �`�[�ԍ�
    END IF;
--
    -- ====================================================
    -- ��s�萔���ݒ�t���O��Y�̏ꍇ
    -- �i�d����R�[�h���ς�����ꍇ�j
    -- ====================================================
    IF( iv_bank_charge_flag = cv_bank_charge_y ) THEN
      -- ====================================================
      -- 5. ��s�萔���Z�o�����擾
      -- ====================================================
      SELECT xbb.supplier_code          AS supplier_code       -- �d����R�[�h
            ,xbb.supplier_site_code     AS supplier_site_code  -- �d����T�C�g�R�[�h
            ,SUM( xbb.payment_amt_tax ) AS payment_amt_tax     -- �x���z
      INTO lt_supplier_code
          ,lt_supplier_site_code
          ,lt_payment_amt_tax
      FROM xxcok_backmargin_balance  xbb
          ,po_vendors                pv
          ,po_vendor_sites_all       pvsa
      WHERE xbb.fb_interface_status         = cv_interface_status_fb
      AND   xbb.gl_interface_status         = cv_if_status_gl_before
      AND   xbb.supplier_code               = g_gl_interface_rec.supplier_code
      AND   xbb.supplier_site_code          = g_gl_interface_rec.supplier_site_code
      AND   xbb.supplier_code               = pv.segment1
      AND   xbb.supplier_site_code          = pvsa.vendor_site_code
      AND   pvsa.hold_all_payments_flag     = cv_hold_pay_flag_n
      AND   (   ( pvsa.inactive_date IS NULL )
              OR( pvsa.inactive_date >= gd_payment_date ) )
      AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
      GROUP BY xbb.supplier_code
              ,xbb.supplier_site_code
      ;
--
      -- ====================================================
      -- 6. �U���萔�����Z�o
      -- ====================================================
      -- ��s�萔��_�U���z�����
      IF( lt_payment_amt_tax < TO_NUMBER( gv_bank_fee_trans_criterion ) ) THEN
        ln_bank_chrg_amt := TO_NUMBER( gv_bank_fee_less_criterion );
      -- ��s�萔��_�U���z��ȏ�
      ELSIF( lt_payment_amt_tax >= TO_NUMBER( gv_bank_fee_trans_criterion ) ) THEN
        ln_bank_chrg_amt := TO_NUMBER( gv_bank_fee_more_criterion );
      END IF;
      -- ====================================================
      -- �U���萔������Ŋz�Z�o
      -- ====================================================
      ln_bank_sales_tax := ln_bank_chrg_amt * ( TO_NUMBER( gv_bm_tax ) / 100 );
--
      -- ====================================================
      -- 7. ��s�萔���U�����_�����擾
      -- ====================================================
      SELECT base.base_code           AS base_code          -- ���_�R�[�h
            ,base.supplier_code       AS supplier_code      -- �d����R�[�h
            ,base.supplier_site_code  AS supplier_site_code -- �d����T�C�g�R�[�h
            ,base.payment_amt         AS payment_amt_max    -- �x���z�iMAX�j
      INTO lt_base_code_max
          ,lt_supplier_code_max
          ,lt_supplier_site_code_max
          ,lt_payment_amt_max
      FROM ( SELECT ROW_NUMBER() over (
                      ORDER BY SUM( xbb.payment_amt_tax ) DESC
                              ,xbb.base_code              ASC
                    )                              AS row_num
                   ,xbb.base_code                  AS base_code
                   ,xbb.supplier_code              AS supplier_code
                   ,xbb.supplier_site_code         AS supplier_site_code
                   ,SUM( xbb.payment_amt_tax )     AS payment_amt
             FROM xxcok_backmargin_balance  xbb
                 ,po_vendors                pv
                 ,po_vendor_sites_all       pvsa
             WHERE xbb.fb_interface_status     =  cv_interface_status_fb
             AND   xbb.gl_interface_status     =  cv_if_status_gl_before
             AND   xbb.supplier_code           =  g_gl_interface_rec.supplier_code
             AND   xbb.supplier_site_code      =  g_gl_interface_rec.supplier_site_code
             AND   xbb.supplier_code           =  pv.segment1
             AND   xbb.supplier_site_code      =  pvsa.vendor_site_code
             AND   pvsa.hold_all_payments_flag =  cv_hold_pay_flag_n
             AND   (   ( pvsa.inactive_date      IS NULL )
                     OR( pvsa.inactive_date      >= gd_payment_date ) )
             AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
             GROUP BY xbb.base_code
                     ,xbb.supplier_code
                     ,xbb.supplier_site_code
             ) base
      WHERE base.row_num = 1
      ;
--
      -- ====================================================
      -- OUT�p�����[�^�ݒ�i�d����P�ʁj
      -- ====================================================
      ot_base_code_vendor           := lt_base_code_max;           -- ���_�R�[�h
      ot_supplier_code_vendor       := lt_supplier_code_max;       -- �d����R�[�h
      ot_supplier_site_code_vendor  := lt_supplier_site_code_max;  -- �d����T�C�g�R�[�h
      on_bank_chrg_amt_vendor       := ln_bank_chrg_amt;           -- �U���萔��
      on_bank_sales_tax_vendor      := ln_bank_sales_tax;          -- �U���萔������Ŋz
    END IF;
--
    -- ====================================================
    -- 8. �U���萔����ݒ�
    -- ====================================================
    -- ====================================================
    -- ��s�萔���ݒ�t���O��Y�̏ꍇ
    -- �i�d����R�[�h���ς�����ꍇ�j
    -- ====================================================
    IF( iv_bank_charge_flag = cv_bank_charge_y ) THEN
      IF(    g_gl_interface_rec.base_code          = lt_base_code_max )
        AND( g_gl_interface_rec.supplier_code      = lt_supplier_code_max )
        AND( g_gl_interface_rec.supplier_site_code = lt_supplier_site_code_max )
      THEN
        on_payment_chrg_amt := ln_bank_chrg_amt;
        on_bank_sales_tax   := ln_bank_sales_tax;
      ELSE
        on_payment_chrg_amt := 0;
        on_bank_sales_tax   := 0;
      END IF;
    -- ====================================================
    -- GL�t�����t���O��Y�̏ꍇ
    -- �i���_�R�[�h�܂��͎d����R�[�h���ς�����ꍇ�j
    -- ====================================================
    ELSIF( iv_gl_add_info_flag = cv_gl_add_info_y ) THEN
      IF(    g_gl_interface_rec.base_code          = it_base_code_slip )
        AND( g_gl_interface_rec.supplier_code      = it_supplier_code_slip )
        AND( g_gl_interface_rec.supplier_site_code = it_supplier_site_code_slip )
      THEN
        on_payment_chrg_amt := in_bank_chrg_amt_slip;
        on_bank_sales_tax   := in_bank_sales_tax_slip;
      ELSE
        on_payment_chrg_amt := 0;
        on_bank_sales_tax   := 0;
      END IF;
    END IF;
--
    -- ====================================================
    -- OUT�p�����[�^�ݒ�
    -- ====================================================
    ov_sales_staff_code := lv_sales_staff_code;   -- �c�ƒS���҃R�[�h
    ov_corp_code        := lv_corp_code;          -- ��ƃR�[�h
    ov_period_name      := lv_period_name;        -- ��v���Ԗ�
--
  EXCEPTION
    --*** �f�[�^�擾��O ***
    WHEN global_nodata_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_interface_add_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_interface_info
   * Description      : GL�A�g�f�[�^�̓o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_interface_info(
     ov_errbuf                    OUT VARCHAR2                                         -- �G���[�E���b�Z�[�W
    ,ov_retcode                   OUT VARCHAR2                                         -- ���^�[���E�R�[�h
    ,ov_errmsg                    OUT VARCHAR2                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_entered_dr                IN  gl_interface.entered_dr%TYPE                     -- �ؕ����z
    ,it_entered_cr                IN  gl_interface.entered_cr%TYPE                     -- �ݕ����z
    ,it_department                IN  gl_interface.segment2%TYPE                       -- ����
    ,it_account                   IN  gl_interface.segment3%TYPE                       -- ����Ȗ�
    ,it_sub_account               IN  gl_interface.segment4%TYPE                       -- �⏕�Ȗ�
    ,it_accounting_date           IN  gl_interface.accounting_date%TYPE                -- �d��L�����t
    ,it_currency_code             IN  gl_interface.currency_code%TYPE                  -- �ʉ݃R�[�h
    ,it_customer_code             IN  gl_interface.segment5%TYPE                       -- �ڋq�R�[�h
    ,it_corp_code                 IN  gl_interface.segment6%TYPE                       -- ��ƃR�[�h
    ,it_gl_name                   IN  gl_interface.reference4%TYPE                     -- �d��
    ,it_period_name               IN  gl_interface.period_name%TYPE                    -- ��v���Ԗ�
    ,it_tax_code                  IN  gl_interface.attribute1%TYPE                     -- �ŋ敪
    ,it_slip_number               IN  gl_interface.attribute3%TYPE                     -- �`�[�ԍ�
    ,it_dept_base                 IN  gl_interface.attribute4%TYPE                     -- �N�[����
    ,it_sales_staff_code          IN  gl_interface.attribute5%TYPE                     -- �`�[���͎�
    ,it_supplier_code_before      IN  xxcok_backmargin_balance.supplier_code%TYPE      -- �d����R�[�h
    ,it_supplier_site_code_before IN  xxcok_backmargin_balance.supplier_site_code%TYPE -- �d����T�C�g�R�[�h
    ,it_cust_code_before          IN  xxcok_backmargin_balance.cust_code%TYPE          -- �ڋq�R�[�h
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name        CONSTANT VARCHAR2(30) := 'insert_interface_info';      -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf          VARCHAR2(5000)               DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)                  DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)               DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(2000)               DEFAULT NULL;             -- �o�̓��b�Z�[�W
    lb_retcode         BOOLEAN                      DEFAULT TRUE;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- GL�C���^�t�F�[�X�o�^
    -- ====================================================
    BEGIN
      INSERT INTO gl_interface(
         status                         -- �X�e�[�^�X
        ,set_of_books_id                -- ��v����ID
        ,accounting_date                -- �d��L�����t
        ,currency_code                  -- �ʉ݃R�[�h
        ,date_created                   -- �V�K�쐬���t
        ,created_by                     -- �V�K�쐬��ID
        ,actual_flag                    -- �c���^�C�v
        ,user_je_category_name          -- �d��J�e�S����
        ,user_je_source_name            -- �d��\�[�X��
        ,segment1                       -- ���
        ,segment2                       -- ����
        ,segment3                       -- ����Ȗ�
        ,segment4                       -- �⏕�Ȗ�
        ,segment5                       -- �ڋq�R�[�h
        ,segment6                       -- ��ƃR�[�h
        ,segment7                       -- �\���P
        ,segment8                       -- �\���Q
        ,entered_dr                     -- �ؕ����z
        ,entered_cr                     -- �ݕ����z
        ,reference1                     -- �o�b�`��
        ,reference4                     -- �d��
        ,period_name                    -- ��v���Ԗ�
        ,group_id                       -- �O���[�vID
        ,attribute1                     -- �ŋ敪
        ,attribute3                     -- �`�[�ԍ�
        ,attribute4                     -- �N�[����
        ,attribute5                     -- �`�[���͎�
        ,context                        -- DFF�R���e�L�X�g
      ) VALUES (
         cv_gl_if_tab_status            -- �X�e�[�^�X
        ,TO_NUMBER( gv_set_of_bks_id )  -- ��v����ID
        ,it_accounting_date             -- �d��L�����t
        ,it_currency_code               -- �ʉ݃R�[�h
        ,SYSDATE                        -- �V�K�쐬���t
        ,fnd_global.user_id             -- �V�K�쐬��ID
        ,cv_balance_flag_a              -- �c���^�C�v
        ,gv_gl_category_bm              -- �d��J�e�S����
        ,gv_gl_source_cok               -- �d��\�[�X��
        ,gv_aff1_company_code           -- ���
        ,it_department                  -- ����
        ,it_account                     -- ����Ȗ�
        ,it_sub_account                 -- �⏕�Ȗ�
        ,it_customer_code               -- �ڋq�R�[�h
        ,it_corp_code                   -- ��ƃR�[�h
        ,gv_aff7_preliminary1_dummy     -- �\���P
        ,gv_aff8_preliminary2_dummy     -- �\���Q
        ,it_entered_dr                  -- �ؕ����z
        ,it_entered_cr                  -- �ݕ����z
        ,gv_batch_name                  -- �o�b�`��
        ,it_gl_name                     -- �d��
        ,it_period_name                 -- ��v���Ԗ�
        ,TO_NUMBER( gt_group_id )       -- �O���[�vID
        ,it_tax_code                    -- �ŋ敪
        ,it_slip_number                 -- �`�[�ԍ�
        ,it_dept_base                   -- �N�[����
        ,it_sales_staff_code            -- �`�[���͎�
        ,gv_set_of_bks_name             -- DFF�R���e�L�X�g
      );
--
    EXCEPTION
      --*** GL�A�g�f�[�^�o�^��O ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_gl_insert_err_msg
                        ,iv_token_name1  => cv_dept_code_token
                        ,iv_token_value1 => it_dept_base
                        ,iv_token_name2  => cv_vend_code_token
                        ,iv_token_value2 => it_supplier_code_before
                        ,iv_token_name3  => cv_vend_site_code_token
                        ,iv_token_value3 => it_supplier_site_code_before
                        ,iv_token_name4  => cv_cust_code_token
                        ,iv_token_value4 => it_cust_code_before
                        ,iv_token_name5  => cv_pay_date_token
                        ,iv_token_value5 => TO_CHAR( it_accounting_date, 'YYYY/MM/DD' )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_interface_info;
--
  /**********************************************************************************
   * Procedure Name   : set_insert_info
   * Description      : �d��쐬
   ***********************************************************************************/
  PROCEDURE set_insert_info(
     ov_errbuf                     OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode                    OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg                     OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_insert_flag                IN  VARCHAR2                                          -- GL�C���^�t�F�[�X�o�^�t���O
    ,it_base_code_before           IN  xxcok_backmargin_balance.base_code%TYPE           -- ���_�R�[�h
    ,it_tax_code_before            IN  xxcok_backmargin_balance.tax_code%TYPE            -- �ŋ��R�[�h
    ,it_expect_payment_date_before IN  xxcok_backmargin_balance.expect_payment_date%TYPE -- �x���\���
    ,it_bank_charge_bearer_before  IN  po_vendor_sites_all.bank_charge_bearer%TYPE       -- ��s�萔�����S��
    ,it_payment_currency_before    IN  po_vendor_sites_all.payment_currency_code%TYPE    -- �x���ʉ�
    ,it_supplier_code_before       IN  xxcok_backmargin_balance.supplier_code%TYPE       -- �d����R�[�h
    ,it_supplier_site_code_before  IN  xxcok_backmargin_balance.supplier_site_code%TYPE  -- �d����T�C�g�R�[�h
    ,it_cust_code_before           IN  xxcok_backmargin_balance.cust_code%TYPE           -- �ڋq�R�[�h
    ,iv_corp_code                  IN  VARCHAR2                                          -- ��ƃR�[�h
    ,in_bm_sum_amt_tax_before      IN  NUMBER                                            -- �̔��萔������Ŋz���v
    ,in_electric_sum_tax_before    IN  NUMBER                                            -- �d�C������Ŋz���v
    ,in_payment_sum_amt_before     IN  NUMBER                                            -- �U���z���v
    ,iv_sales_staff_code           IN  VARCHAR2                                          -- �c�ƒS���҃R�[�h
    ,iv_period_name                IN  VARCHAR2                                          -- ��v���Ԗ�
    ,iv_slip_number                IN  VARCHAR2                                          -- �`�[�ԍ�
    ,in_payment_chrg_amt           IN  NUMBER                                            -- �U���萔���z
    ,in_bank_sales_tax             IN  NUMBER                                            -- �U���萔������Ŋz
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name          CONSTANT VARCHAR2(30) := 'set_insert_info';      -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf            VARCHAR2(5000)               DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)                  DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000)               DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg           VARCHAR2(2000)               DEFAULT NULL;             -- �o�̓��b�Z�[�W
    lb_retcode           BOOLEAN                      DEFAULT TRUE;             -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    -- GL�C���^�t�F�[�X�o�^�f�[�^
    lt_entered_dr                 gl_interface.entered_dr%TYPE                     DEFAULT NULL; -- �ؕ����z
    lt_entered_cr                 gl_interface.entered_cr%TYPE                     DEFAULT NULL; -- �ݕ����z
    lt_department                 gl_interface.segment2%TYPE                       DEFAULT NULL; -- ����
    lt_account                    gl_interface.segment3%TYPE                       DEFAULT NULL; -- ����Ȗ�
    lt_sub_account                gl_interface.segment4%TYPE                       DEFAULT NULL; -- �⏕�Ȗ�
    lt_accounting_date            gl_interface.accounting_date%TYPE                DEFAULT NULL; -- �d��L�����t
    lt_currency_code              gl_interface.currency_code%TYPE                  DEFAULT NULL; -- �ʉ݃R�[�h
    lt_customer_code              gl_interface.segment5%TYPE                       DEFAULT NULL; -- �ڋq�R�[�h
    lt_corp_code                  gl_interface.segment6%TYPE                       DEFAULT NULL; -- ��ƃR�[�h
    lt_gl_name                    gl_interface.reference4%TYPE                     DEFAULT NULL; -- �d��
    lt_period_name                gl_interface.period_name%TYPE                    DEFAULT NULL; -- ��v���Ԗ�
    lt_tax_code                   gl_interface.attribute1%TYPE                     DEFAULT NULL; -- �ŋ敪
    lt_slip_number                gl_interface.attribute3%TYPE                     DEFAULT NULL; -- �`�[�ԍ�
    lt_dept_base                  gl_interface.attribute4%TYPE                     DEFAULT NULL; -- �N�[����
    lt_sales_staff_code           gl_interface.attribute5%TYPE                     DEFAULT NULL; -- �`�[���͎�
    lt_supplier_code_before       xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- �d����R�[�h
    lt_supplier_site_code_before  xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- �d����T�C�g�R�[�h
    lt_cust_code_before           xxcok_backmargin_balance.cust_code%TYPE          DEFAULT NULL; -- �ڋq�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- GL�C���^�t�F�[�X�o�^�t���O��'V'�̏ꍇ
    -- �ڋq���̎d��쐬
    -- ====================================================
    IF( iv_insert_flag = cv_vend_sales ) THEN
      -- �G���[���b�Z�[�W�p
      lt_supplier_code_before      := g_gl_interface_rec.supplier_code;         -- �d����R�[�h
      lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code;    -- �d����T�C�g�R�[�h
      lt_cust_code_before          := g_gl_interface_rec.cust_code;             -- �ڋq�R�[�h
      -- �o�^�f�[�^
      lt_accounting_date           := g_gl_interface_rec.expect_payment_date;   -- �d��L�����t
      lt_currency_code             := g_gl_interface_rec.payment_currency_code; -- �ʉ݃R�[�h
      lt_customer_code             := g_gl_interface_rec.cust_code;             -- �ڋq�R�[�h
      lt_corp_code                 := iv_corp_code;                             -- ��ƃR�[�h
      lt_gl_name                   := iv_slip_number;                           -- �d��
      lt_period_name               := iv_period_name;                           -- ��v���Ԗ�
      lt_tax_code                  := g_gl_interface_rec.tax_code;              -- �ŋ敪
      lt_slip_number               := iv_slip_number;                           -- �`�[�ԍ�
      lt_dept_base                 := g_gl_interface_rec.base_code;             -- �N�[����
      lt_sales_staff_code          := iv_sales_staff_code;                      -- �`�[���͎�
--
      -- ====================================================
      -- �̔��萔��
      -- ====================================================
      IF( g_gl_interface_rec.backmargin > 0 ) THEN
        lt_department  := g_gl_interface_rec.base_code;     -- ���_�R�[�h
        lt_account     := gv_aff3_vend_sales_commission;    -- ���̋@�̎�
        lt_sub_account := gv_aff4_vend_sales_rebate;        -- ���̋@���x�[�g
        lt_entered_dr  := g_gl_interface_rec.backmargin;    -- �̔��萔��
        lt_entered_cr  := NULL;                             -- �ݕ����z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ====================================================
      -- �d�C��
      -- ====================================================
      IF( g_gl_interface_rec.electric_amt > 0 ) THEN
        lt_department  := g_gl_interface_rec.base_code;     -- ���_�R�[�h
        lt_account     := gv_aff3_vend_sales_commission;    -- ���̋@�̎�
        lt_sub_account := gv_aff4_vend_sales_elec_cost;     -- ���̋@�d�C��
        lt_entered_dr  := g_gl_interface_rec.electric_amt;  -- �d�C��
        lt_entered_cr  := NULL;                             -- �ݕ����z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    -- ====================================================
    -- GL�C���^�t�F�[�X�o�^�t���O��'B'�̏ꍇ
    -- �`�[�P�ʂ̎d��쐬
    -- ====================================================
    ELSIF( iv_insert_flag = cv_backmargin ) THEN
      -- �G���[���b�Z�[�W�p
      lt_supplier_code_before      := it_supplier_code_before;         -- �d����R�[�h
      lt_supplier_site_code_before := it_supplier_site_code_before;    -- �d����T�C�g�R�[�h
      lt_cust_code_before          := it_cust_code_before;             -- �ڋq�R�[�h
      -- �o�^�f�[�^
      lt_accounting_date           := it_expect_payment_date_before;   -- �d��L�����t
      lt_currency_code             := it_payment_currency_before;      -- �ʉ݃R�[�h
      lt_customer_code             := gv_aff5_customer_dummy;          -- �ڋq�R�[�h
      lt_corp_code                 := gv_aff6_company_dummy;           -- ��ƃR�[�h
      lt_gl_name                   := iv_slip_number;                  -- �d��
      lt_period_name               := iv_period_name;                  -- ��v���Ԗ�
      lt_tax_code                  := it_tax_code_before;              -- �ŋ敪
      lt_slip_number               := iv_slip_number;                  -- �`�[�ԍ�
      lt_dept_base                 := it_base_code_before;             -- �N�[����
      lt_sales_staff_code          := iv_sales_staff_code;             -- �`�[���͎�
      -- ====================================================
      -- 1. ��s�萔�����S�҂������̏ꍇ
      -- ====================================================
      IF( it_bank_charge_bearer_before = cv_chrg_flag_i ) THEN
        IF( in_payment_chrg_amt > 0 ) THEN
          -- ====================================================
          -- �U���萔���i�ؕ��j
          -- ====================================================
          lt_department  := it_base_code_before;          -- ���_�R�[�h
          lt_account     := gv_aff3_fee;                  -- �萔��
          lt_sub_account := gv_aff4_transfer_fee;         -- �U���萔��
          lt_entered_dr  := in_payment_chrg_amt;          -- �U���萔���z
          lt_entered_cr  := NULL;                         -- �ݕ����z
          -- ====================================================
          -- GL�C���^�t�F�[�X�o�^
          -- ====================================================
          insert_interface_info(
             ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
            ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
            ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
            ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
            ,it_department                => lt_department                -- ����
            ,it_account                   => lt_account                   -- ����Ȗ�
            ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
            ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
            ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
            ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
            ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
            ,it_gl_name                   => lt_gl_name                   -- �d��
            ,it_period_name               => lt_period_name               -- ��v���Ԗ�
            ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
            ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
            ,it_dept_base                 => lt_dept_base                 -- �N�[����
            ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
            ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
            ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
            ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ====================================================
        -- ����Ŋz�i�ؕ��j
        -- ====================================================
        lt_department  := gv_aff2_dept_fin;               -- �����o����
        lt_account     := gv_aff3_payment_excise_tax;     -- ��������œ�
        lt_sub_account := gv_aff4_subacct_dummy;          -- �_�~�[�l
        lt_entered_dr  := ( in_bm_sum_amt_tax_before      -- �̎����Ŋz + �d�C������Ŋz + �U���萔������Ŋz
                          + in_electric_sum_tax_before
                          + in_bank_sales_tax          ); -- ����Ŋz
        lt_entered_cr  := NULL;                           -- �ݕ����z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- �U���z�i�ݕ��j
        -- ====================================================
        lt_department  := gv_aff2_dept_fin;               -- �����o����
        lt_account     := gv_aff3_current_account;        -- �����a��
        lt_sub_account := gv_aff4_current_account_our;    -- ���Ќ���
        lt_entered_dr  := NULL;                           -- �ؕ����z
        lt_entered_cr  := ( in_payment_sum_amt_before     -- �U���z + �U���萔�� + �U���萔������Ŋz
                          + in_payment_chrg_amt
                          + in_bank_sales_tax         );  -- �U���z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ====================================================
      -- 2. ��s�萔�����S�҂������̏ꍇ
      -- ====================================================
      ELSE
        -- ====================================================
        -- ����Ŋz�i�ؕ��j
        -- ====================================================
        lt_department  := gv_aff2_dept_fin;               -- �����o����
        lt_account     := gv_aff3_payment_excise_tax;     -- ��������œ�
        lt_sub_account := gv_aff4_subacct_dummy;          -- �_�~�[�l
        lt_entered_dr  := ( in_bm_sum_amt_tax_before      -- �̎����Ŋz + �d�C������Ŋz - �U���萔������Ŋz
                          + in_electric_sum_tax_before
                          - in_bank_sales_tax          ); -- ����Ŋz
        lt_entered_cr  := NULL;                           -- �ݕ����z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- �U���z�i�ݕ��j
        -- ====================================================
        lt_department  := gv_aff2_dept_fin;               -- �����o����
        lt_account     := gv_aff3_current_account;        -- �����a��
        lt_sub_account := gv_aff4_current_account_our;    -- ���Ќ���
        lt_entered_dr  := NULL;                           -- �ؕ����z
        lt_entered_cr  := ( in_payment_sum_amt_before     -- �U���z - �U���萔�� - �U���萔������Ŋz
                          - in_payment_chrg_amt
                          - in_bank_sales_tax         );  -- �U���z
        -- ====================================================
        -- GL�C���^�t�F�[�X�o�^
        -- ====================================================
        insert_interface_info(
           ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
          ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
          ,it_department                => lt_department                -- ����
          ,it_account                   => lt_account                   -- ����Ȗ�
          ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
          ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
          ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
          ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
          ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
          ,it_gl_name                   => lt_gl_name                   -- �d��
          ,it_period_name               => lt_period_name               -- ��v���Ԗ�
          ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
          ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
          ,it_dept_base                 => lt_dept_base                 -- �N�[����
          ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
          ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
          ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
          ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- �U���萔���i�ݕ��j
        -- ====================================================
        IF (in_payment_chrg_amt > 0) THEN
          lt_department  := gv_aff2_dept_fin;             -- �����o����
          lt_account     := gv_aff3_fee;                  -- �萔��
          lt_sub_account := gv_aff4_transfer_fee;         -- �U���萔��
          lt_entered_dr  := NULL;                         -- �ؕ����z
          lt_entered_cr  := in_payment_chrg_amt;          -- �U���萔���z
          -- ====================================================
          -- GL�C���^�t�F�[�X�o�^
          -- ====================================================
          insert_interface_info(
             ov_errbuf                    => lv_errbuf                    -- �G���[�E���b�Z�[�W
            ,ov_retcode                   => lv_retcode                   -- ���^�[���E�R�[�h
            ,ov_errmsg                    => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,it_entered_dr                => lt_entered_dr                -- �ؕ����z
            ,it_entered_cr                => lt_entered_cr                -- �ݕ����z
            ,it_department                => lt_department                -- ����
            ,it_account                   => lt_account                   -- ����Ȗ�
            ,it_sub_account               => lt_sub_account               -- �⏕�Ȗ�
            ,it_accounting_date           => lt_accounting_date           -- �d��L�����t
            ,it_currency_code             => lt_currency_code             -- �ʉ݃R�[�h
            ,it_customer_code             => lt_customer_code             -- �ڋq�R�[�h
            ,it_corp_code                 => lt_corp_code                 -- ��ƃR�[�h
            ,it_gl_name                   => lt_gl_name                   -- �d��
            ,it_period_name               => lt_period_name               -- ��v���Ԗ�
            ,it_tax_code                  => lt_tax_code                  -- �ŋ敪
            ,it_slip_number               => lt_slip_number               -- �`�[�ԍ�
            ,it_dept_base                 => lt_dept_base                 -- �N�[����
            ,it_sales_staff_code          => lt_sales_staff_code          -- �`�[���͎�
            ,it_supplier_code_before      => lt_supplier_code_before      -- �d����R�[�h
            ,it_supplier_site_code_before => lt_supplier_site_code_before -- �d����T�C�g�R�[�h
            ,it_cust_code_before          => lt_cust_code_before          -- �ڋq�R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END set_insert_info;
--
  /**********************************************************************************
   * Procedure Name   : update_interface_info
   * Description      : �A�g���ʂ̍X�V(A-6)
   ***********************************************************************************/
  PROCEDURE update_interface_info(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_interface_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode       BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    -- *** ���[�J���J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT 'X'
      FROM xxcok_backmargin_balance xbb
      WHERE xbb.base_code           = g_gl_interface_rec.base_code
      AND   xbb.supplier_code       = g_gl_interface_rec.supplier_code
      AND   xbb.supplier_site_code  = g_gl_interface_rec.supplier_site_code
      AND   xbb.cust_code           = g_gl_interface_rec.cust_code
      AND   xbb.fb_interface_status = cv_interface_status_fb
      AND   xbb.gl_interface_status = cv_if_status_gl_before
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- 1. �̎�c���e�[�u���̃��b�N���擾
    -- ====================================================
    OPEN  lock_cur;
    CLOSE lock_cur;
--
    -- ====================================================
    -- 2. �Ώۃf�[�^��A�g�ςɍX�V
    -- ====================================================
    BEGIN
      UPDATE xxcok_backmargin_balance
      SET gl_interface_status    = cv_if_status_gl_after -- �A�g�X�e�[�^�X�iGL�j
         ,gl_interface_date      = gd_process_date       -- �A�g���iGL�j
         ,last_updated_by        = cn_last_updated_by
         ,last_update_date       = SYSDATE
         ,last_update_login      = cn_last_update_login
         ,request_id             = cn_request_id
         ,program_application_id = cn_program_application_id
         ,program_id             = cn_program_id
         ,program_update_date    = SYSDATE
      WHERE base_code           = g_gl_interface_rec.base_code
      AND   supplier_code       = g_gl_interface_rec.supplier_code
      AND   supplier_site_code  = g_gl_interface_rec.supplier_site_code
      AND   cust_code           = g_gl_interface_rec.cust_code
      AND   fb_interface_status = cv_interface_status_fb
      AND   gl_interface_status = cv_if_status_gl_before
      ;
--
    EXCEPTION
      --*** GL�A�g���ʍX�V��O ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_gl_if_update_err_msg
                        ,iv_token_name1  => cv_dept_code_token
                        ,iv_token_value1 => g_gl_interface_rec.base_code
                        ,iv_token_name2  => cv_vend_code_token
                        ,iv_token_value2 => g_gl_interface_rec.supplier_code
                        ,iv_token_name3  => cv_vend_site_code_token
                        ,iv_token_value3 => g_gl_interface_rec.supplier_site_code
                        ,iv_token_name4  => cv_cust_code_token
                        ,iv_token_value4 => g_gl_interface_rec.cust_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    --*** GL�A�g���ʍX�V���b�N��O ***
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_bm_balance_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_interface_info;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_interface
   * Description      : GL�A�g�f�[�^�̎擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_gl_interface(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_gl_interface'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                     VARCHAR2(2000) DEFAULT NULL;              -- �o�̓��b�Z�[�W
    -- GL�t�����
    lb_retcode                     BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
    lv_sales_staff_code            VARCHAR2(10)   DEFAULT NULL;              -- �c�ƒS���҃R�[�h
    lv_corp_code                   VARCHAR2(10)   DEFAULT NULL;              -- ��ƃR�[�h
    lv_period_name                 VARCHAR2(15)   DEFAULT NULL;              -- ��v���Ԗ�
    lv_slip_number                 VARCHAR2(20)   DEFAULT NULL;              -- �`�[�ԍ�
    ln_payment_chrg_amt            NUMBER         DEFAULT NULL;              -- �U���萔���z
    ln_bank_sales_tax              NUMBER         DEFAULT NULL;              -- �U���萔���Ŋz
    -- �t���O
    lv_gl_add_info_flag            VARCHAR2(1)    DEFAULT NULL;              -- �t�����擾�t���O(�`�[�P��)
    lv_bank_charge_flag            VARCHAR2(1)    DEFAULT NULL;              -- ��s�萔���ݒ�t���O(�d����P��)
    lv_insert_flag                 VARCHAR2(1)    DEFAULT NULL;              -- GL�C���^�t�F�[�X�o�^�t���O
    -- �݌v�f�[�^
    ln_bm_sum_amt_tax_before       NUMBER         DEFAULT 0;                 -- �̔��萔������Ŋz���v
    ln_electric_sum_tax_before     NUMBER         DEFAULT 0;                 -- �d�C������Ŋz���v
    ln_payment_sum_amt_before      NUMBER         DEFAULT 0;                 -- �U���z
    -- �d����P�ʂŎ擾�����f�[�^
    lt_base_code_vendor            xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- ���_�R�[�h
    lt_supplier_code_vendor        xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- �d����R�[�h
    lt_supplier_site_code_vendor   xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- �d����T�C�g�R�[�h
    ln_bank_chrg_amt_vendor        NUMBER                                            DEFAULT NULL; -- �U���萔���z
    ln_bank_sales_tax_vendor       NUMBER                                            DEFAULT NULL; -- �U���萔���Ŋz
    -- �`�[�P�ʂŎ擾�����f�[�^
    lt_base_code_slip              xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- ���_�R�[�h
    lt_supplier_code_slip          xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- �d����R�[�h
    lt_supplier_site_code_slip     xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- �d����T�C�g�R�[�h
    ln_bank_chrg_amt_slip          NUMBER                                            DEFAULT NULL; -- �U���萔���z
    ln_bank_sales_tax_slip         NUMBER                                            DEFAULT NULL; -- �U���萔���Ŋz
    -- �̔��萔���f�[�^
    lv_slip_number_before          VARCHAR2(20)                                      DEFAULT NULL; -- �`�[�ԍ�
    ln_payment_chrg_amt_before     NUMBER                                            DEFAULT NULL; -- �U���萔���z
    ln_bank_sales_tax_before       NUMBER                                            DEFAULT NULL; -- �U���萔���Ŋz
    lt_base_code_before            xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- ���_�R�[�h
    lt_supplier_code_before        xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- �d����R�[�h
    lt_supplier_site_code_before   xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- �d����T�C�g�R�[�h
    lt_cust_code_before            xxcok_backmargin_balance.cust_code%TYPE           DEFAULT NULL; -- �ڋq�R�[�h
    lt_tax_code_before             xxcok_backmargin_balance.tax_code%TYPE            DEFAULT NULL; -- �ŋ��R�[�h
    lt_expect_payment_date_before  xxcok_backmargin_balance.expect_payment_date%TYPE DEFAULT NULL; -- �x���\���
    lt_bank_charge_bearer_before   po_vendor_sites_all.bank_charge_bearer%TYPE       DEFAULT NULL; -- ��s�萔�����S��
    lt_payment_currency_before     po_vendor_sites_all.payment_currency_code%TYPE    DEFAULT NULL; -- �x���ʉ�
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- 1���ڂ�GL�A�g�f�[�^�擾
    -- ====================================================
    OPEN  gl_interface_cur;
    FETCH gl_interface_cur INTO g_gl_interface_rec;
--
    -- ====================================================
    -- �U���萔���d��쐬�p�̃f�[�^��ێ�����
    -- ====================================================
    lt_base_code_before          := g_gl_interface_rec.base_code;          -- ���_�R�[�h
    lt_supplier_code_before      := g_gl_interface_rec.supplier_code;      -- �d����R�[�h
    lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code; -- �d����T�C�g�R�[�h
--
    -- ====================================================
    -- �t�����擾�t���O�ݒ�i�`�[�P�ʎ擾����j
    -- ��s�萔���ݒ�t���O�ݒ�i�d����P�ʎ擾����j
    -- GL�C���^�t�F�[�X�o�^�t���O�ݒ�i���̋@�̔��萔���d��j
    -- ====================================================
    lv_gl_add_info_flag        := cv_gl_add_info_y;
    lv_bank_charge_flag        := cv_bank_charge_y;
    lv_insert_flag             := cv_vend_sales;
--
    <<g_gl_interface_loop>>
    LOOP
      EXIT WHEN gl_interface_cur%NOTFOUND;
      -- ====================================================
      -- ���_�R�[�h�܂��͎d����R�[�h����v�����ꍇ
      -- ====================================================
      IF(  ( lt_base_code_before     = g_gl_interface_rec.base_code )
        AND( lt_supplier_code_before = g_gl_interface_rec.supplier_code ) )
      THEN
        -- �Ώی���
        gn_target_cnt := gn_target_cnt + 1;
        -- ====================================================
        -- A-4. GL�A�g�f�[�^�t�����̎擾
        -- ====================================================
        get_interface_add_info(
           ov_errbuf                    =>   lv_errbuf                    -- �G���[�E���b�Z�[�W
          ,ov_retcode                   =>   lv_retcode                   -- ���^�[���E�R�[�h
          ,ov_errmsg                    =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,iv_gl_add_info_flag          =>   lv_gl_add_info_flag          -- GL�t�����t���O
          ,iv_bank_charge_flag          =>   lv_bank_charge_flag          -- ��s�萔���ݒ�t���O
          ,it_base_code_slip            =>   lt_base_code_slip            -- ���_�R�[�h
          ,it_supplier_code_slip        =>   lt_supplier_code_slip        -- �d����R�[�h
          ,it_supplier_site_code_slip   =>   lt_supplier_site_code_slip   -- �d����T�C�g�R�[�h
          ,in_bank_chrg_amt_slip        =>   ln_bank_chrg_amt_slip        -- �U���萔���z
          ,in_bank_sales_tax_slip       =>   ln_bank_sales_tax_slip       -- �U���萔���Ŋz
          ,ov_sales_staff_code          =>   lv_sales_staff_code          -- �c�ƒS���҃R�[�h
          ,ov_corp_code                 =>   lv_corp_code                 -- ��ƃR�[�h
          ,ov_period_name               =>   lv_period_name               -- ��v���Ԗ�
          ,ov_slip_number               =>   lv_slip_number               -- �`�[�ԍ�
          ,on_payment_chrg_amt          =>   ln_payment_chrg_amt          -- �U���萔���z
          ,on_bank_sales_tax            =>   ln_bank_sales_tax            -- �U���萔���Ŋz
          ,ot_base_code_vendor          =>   lt_base_code_vendor          -- ���_�R�[�h
          ,ot_supplier_code_vendor      =>   lt_supplier_code_vendor      -- �d����R�[�h
          ,ot_supplier_site_code_vendor =>   lt_supplier_site_code_vendor -- �d����T�C�g�R�[�h
          ,on_bank_chrg_amt_vendor      =>   ln_bank_chrg_amt_vendor      -- �U���萔���z
          ,on_bank_sales_tax_vendor     =>   ln_bank_sales_tax_vendor     -- �U���萔���Ŋz
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- �擾�����t������ޔ�
        -- ====================================================
        -- ====================================================
        -- GL�t�����t���O��Y�̏ꍇ
        -- �i���_�R�[�h�܂��͎d����R�[�h���ς�����ꍇ�j
        -- ====================================================
        IF( lv_gl_add_info_flag = cv_gl_add_info_y ) THEN
          lv_slip_number_before       := lv_slip_number;               -- �`�[�ԍ�
          ln_payment_chrg_amt_before  := ln_payment_chrg_amt;          -- �U���萔���z
          ln_bank_sales_tax_before    := ln_bank_sales_tax;            -- �U���萔���Ŋz
        END IF;
--
        -- ====================================================
        -- ��s�萔���ݒ�t���O��Y�̏ꍇ
        -- �i�d����R�[�h���ς�����ꍇ�j
        -- ====================================================
        IF( lv_bank_charge_flag = cv_bank_charge_y ) THEN
          lt_base_code_slip           := lt_base_code_vendor;          -- ���_�R�[�h
          lt_supplier_code_slip       := lt_supplier_code_vendor;      -- �d����R�[�h
          lt_supplier_site_code_slip  := lt_supplier_site_code_vendor; -- �d����T�C�g�R�[�h
          ln_bank_chrg_amt_slip       := ln_bank_chrg_amt_vendor;      -- �U���萔���z
          ln_bank_sales_tax_slip      := ln_bank_sales_tax_vendor;     -- �U���萔���Ŋz
        END IF;
--
        -- ====================================================
        -- A-5. GL�A�g�f�[�^�̓o�^�i�ڋq���j
        -- ====================================================
        lv_insert_flag := cv_vend_sales;
--
        set_insert_info(
           ov_errbuf                     =>  lv_errbuf                      -- �G���[�E���b�Z�[�W
          ,ov_retcode                    =>  lv_retcode                     -- ���^�[���E�R�[�h
          ,ov_errmsg                     =>  lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,iv_insert_flag                =>  lv_insert_flag                 -- GL�C���^�t�F�[�X�o�^�t���O
          ,it_base_code_before           =>  lt_base_code_before            -- ���_�R�[�h
          ,it_tax_code_before            =>  lt_tax_code_before             -- �ŋ��R�[�h
          ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- �x����
          ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- ��s�萔�����S��
          ,it_payment_currency_before    =>  lt_payment_currency_before     -- �x���ʉ�
          ,it_supplier_code_before       =>  lt_supplier_code_before        -- �d����R�[�h
          ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- �d����T�C�g�R�[�h
          ,it_cust_code_before           =>  lt_cust_code_before            -- �ڋq�R�[�h
          ,iv_corp_code                  =>  lv_corp_code                   -- ��ƃR�[�h
          ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- �̔��萔������Ŋz���v
          ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- �d�C������Ŋz���v
          ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- �U���z���v
          ,iv_sales_staff_code           =>  lv_sales_staff_code            -- �c�ƒS���҃R�[�h
          ,iv_period_name                =>  lv_period_name                 -- ��v���Ԗ�
          ,iv_slip_number                =>  lv_slip_number_before          -- �`�[�ԍ�
          ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- �U���萔���z
          ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- �U���萔���Ŋz
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- A-6. �A�g���ʂ̍X�V
        -- ====================================================
        update_interface_info(
           ov_errbuf     =>   lv_errbuf    -- �G���[�E���b�Z�[�W
          ,ov_retcode    =>   lv_retcode   -- ���^�[���E�R�[�h
          ,ov_errmsg     =>   lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���팏��
        gn_normal_cnt := gn_normal_cnt + 1;
--
        -- ====================================================
        -- �U���萔���d��쐬�p�̃f�[�^��ێ�����
        -- ====================================================
        ln_bm_sum_amt_tax_before        := ln_bm_sum_amt_tax_before   + g_gl_interface_rec.backmargin_tax;
        ln_electric_sum_tax_before      := ln_electric_sum_tax_before + g_gl_interface_rec.electric_amt_tax;
        ln_payment_sum_amt_before       := ln_payment_sum_amt_before  + g_gl_interface_rec.amt_sum;
        lt_tax_code_before              := g_gl_interface_rec.tax_code;
        lt_expect_payment_date_before   := g_gl_interface_rec.expect_payment_date;
        lt_bank_charge_bearer_before    := g_gl_interface_rec.bank_charge_bearer;
        lt_payment_currency_before      := g_gl_interface_rec.payment_currency_code;
        lt_cust_code_before             := g_gl_interface_rec.cust_code;
--
        -- ====================================================
        -- �t�����t���O�ݒ�i�`�[�P�ʎ擾���Ȃ��j
        -- ��s�萔���t���O�ݒ�i�d����P�ʎ擾���Ȃ��j
        -- ====================================================
        lv_gl_add_info_flag             := cv_gl_add_info_n;
        lv_bank_charge_flag             := cv_bank_charge_n;
--
        -- ====================================================
        -- �����R�[�h
        -- ====================================================
        FETCH gl_interface_cur INTO g_gl_interface_rec;
--
      -- ====================================================
      -- ���_�R�[�h�܂��͎d����R�[�h���ς�����ꍇ
      -- ====================================================
      ELSE
        -- ====================================================
        -- �d����R�[�h���ς�����ꍇ
        -- ��s�萔���t���O�ݒ�i�d����P�ʃf�[�^�擾����j
        -- ====================================================
        IF( lt_supplier_code_before <> g_gl_interface_rec.supplier_code ) THEN
          lv_bank_charge_flag    := cv_bank_charge_y;
        END IF;
--
        -- ====================================================
        -- A-5. GL�A�g�f�[�^�̓o�^�i�萔���j
        -- ====================================================
        lv_insert_flag := cv_backmargin;
--
        set_insert_info(
           ov_errbuf                     =>  lv_errbuf                      -- �G���[�E���b�Z�[�W
          ,ov_retcode                    =>  lv_retcode                     -- ���^�[���E�R�[�h
          ,ov_errmsg                     =>  lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,iv_insert_flag                =>  lv_insert_flag                 -- GL�C���^�t�F�[�X�o�^�t���O
          ,it_base_code_before           =>  lt_base_code_before            -- ���_�R�[�h
          ,it_tax_code_before            =>  lt_tax_code_before             -- �ŋ��R�[�h
          ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- �x����
          ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- ��s�萔�����S��
          ,it_payment_currency_before    =>  lt_payment_currency_before     -- �x���ʉ�
          ,it_supplier_code_before       =>  lt_supplier_code_before        -- �d����R�[�h
          ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- �d����T�C�g�R�[�h
          ,it_cust_code_before           =>  lt_cust_code_before            -- �ڋq�R�[�h
          ,iv_corp_code                  =>  lv_corp_code                   -- ��ƃR�[�h
          ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- �̔��萔������Ŋz���v
          ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- �d�C������Ŋz���v
          ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- �U���z���v
          ,iv_sales_staff_code           =>  lv_sales_staff_code            -- �c�ƒS���҃R�[�h
          ,iv_period_name                =>  lv_period_name                 -- ��v���Ԗ�
          ,iv_slip_number                =>  lv_slip_number_before          -- �`�[�ԍ�
          ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- �U���萔���z
          ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- �U���萔���Ŋz
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ====================================================
        -- �U���萔���d��쐬�p�̃f�[�^��ێ�����
        -- ====================================================
        lt_base_code_before          := g_gl_interface_rec.base_code;          -- ���_�R�[�h
        lt_supplier_code_before      := g_gl_interface_rec.supplier_code;      -- �d����R�[�h
        lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code; -- �d����T�C�g�R�[�h
--
        -- ====================================================
        -- �݌v�f�[�^���Z�b�g
        -- ====================================================
        ln_bm_sum_amt_tax_before   := 0;    -- �̔��萔������Ŋz���v
        ln_electric_sum_tax_before := 0;    -- �d�C������Ŋz���v
        ln_payment_sum_amt_before  := 0;    -- �U���z
--
        -- ====================================================
        -- �t�����擾�t���O�i�`�[�P�ʃf�[�^�擾����j
        -- ====================================================
        lv_gl_add_info_flag      := cv_gl_add_info_y;
--
      END IF;
--
    END LOOP g_gl_interface_loop;
    -- ====================================================
    -- GL�A�g���1�����擾�ł��Ȃ������ꍇ
    -- ====================================================
    IF( gn_target_cnt = 0 ) THEN
      RAISE global_nodata_expt;
    END IF;
--
    CLOSE gl_interface_cur;
    -- ====================================================
    -- A-5. GL�A�g�f�[�^�̓o�^
    -- ====================================================
    lv_insert_flag := cv_backmargin;
--
    set_insert_info(
       ov_errbuf                     =>  lv_errbuf                      -- �G���[�E���b�Z�[�W
      ,ov_retcode                    =>  lv_retcode                     -- ���^�[���E�R�[�h
      ,ov_errmsg                     =>  lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_insert_flag                =>  lv_insert_flag                 -- GL�C���^�t�F�[�X�o�^�t���O
      ,it_base_code_before           =>  lt_base_code_before            -- ���_�R�[�h
      ,it_tax_code_before            =>  lt_tax_code_before             -- �ŋ��R�[�h
      ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- �x����
      ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- ��s�萔�����S��
      ,it_payment_currency_before    =>  lt_payment_currency_before     -- �x���ʉ�
      ,it_supplier_code_before       =>  lt_supplier_code_before        -- �d����R�[�h
      ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- �d����T�C�g�R�[�h
      ,it_cust_code_before           =>  lt_cust_code_before            -- �ڋq�R�[�h
      ,iv_corp_code                  =>  lv_corp_code                   -- ��ƃR�[�h
      ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- �̔��萔������Ŋz���v
      ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- �d�C������Ŋz���v
      ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- �U���z���v
      ,iv_sales_staff_code           =>  lv_sales_staff_code            -- �c�ƒS���҃R�[�h
      ,iv_period_name                =>  lv_period_name                 -- ��v���Ԗ�
      ,iv_slip_number                =>  lv_slip_number_before          -- �`�[�ԍ�
      ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- �U���萔���z
      ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- �U���萔���Ŋz
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    --*** GL�A�g�f�[�^�擾��O ***
    WHEN global_nodata_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_gl_info_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
      CLOSE gl_interface_cur;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
      CLOSE gl_interface_cur;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      CLOSE gl_interface_cur;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      CLOSE gl_interface_cur;
--
  END get_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name   CONSTANT VARCHAR2(20) := 'submain';          -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)     DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(2000)  DEFAULT NULL;                -- �o�̓��b�Z�[�W
    lb_retcode    BOOLEAN         DEFAULT TRUE;                -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ====================================================
    -- �O���[�o���ϐ��̏�����
    -- ====================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ====================================================
    -- A-1. ��������
    -- ====================================================
    init(
       ov_errbuf    =>   lv_errbuf        -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>   lv_retcode       -- ���^�[���E�R�[�h
      ,ov_errmsg    =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- A-2. �Ó����`�F�b�N����
    -- ====================================================
    check_acctg_period(
       ov_errbuf    =>   lv_errbuf        -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>   lv_retcode       -- ���^�[���E�R�[�h
      ,ov_errmsg    =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- A-3. GL�A�g�f�[�^�̎擾
    -- ====================================================
    get_gl_interface(
       ov_errbuf    =>   lv_errbuf        -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>   lv_retcode       -- ���^�[���E�R�[�h
      ,ov_errmsg    =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT VARCHAR2       --   �G���[�E���b�Z�[�W
    ,retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h
  )
  IS
--
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name       CONSTANT VARCHAR2(5) := 'main';            -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf         VARCHAR2(5000)  DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)     DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000)  DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg        VARCHAR2(2000)  DEFAULT NULL;              -- �o�̓��b�Z�[�W
    lv_message_code   VARCHAR2(20)    DEFAULT NULL;              -- �I�����b�Z�[�W
    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- ���b�Z�[�W�o�͂̃��^�[���E�R�[�h
--
  BEGIN
--
    -- ====================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ====================================================
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ====================================================
    submain(
       ov_errbuf    =>  lv_errbuf   -- �G���[�E���b�Z�[�W
      ,ov_retcode   =>  lv_retcode  -- ���^�[���E�R�[�h
      ,ov_errmsg    =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ====================================================
    -- �G���[�o��
    -- ====================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_errmsg
                      ,1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.LOG
                      ,lv_errbuf
                      ,1
                    );
    END IF;
--
    -- ====================================================
    -- �ُ�I���̏ꍇ�̌����Z�b�g
    -- ====================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    -- ====================================================
    -- �Ώی����o��
    -- ====================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    -- ====================================================
    -- ���������o��
    -- ====================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    -- ====================================================
    -- �G���[�����o��
    -- ====================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
--
    -- ====================================================
    -- �I�����b�Z�[�W
    -- ====================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ====================================================
    -- �X�e�[�^�X�Z�b�g
    -- ====================================================
    retcode := lv_retcode;
    -- ====================================================
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    -- ====================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
  END main;
--
END XXCOK017A01C;
/
