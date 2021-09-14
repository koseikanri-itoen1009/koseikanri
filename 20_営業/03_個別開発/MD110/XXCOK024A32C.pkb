CREATE OR REPLACE PACKAGE BODY XXCOK024A32C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A32C_pkg(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�������l������ MD050_COK_024_A32
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_deduction_p        �̔��T����񒊏o(A-2)
 *  ins_cust_inf_p         �������l���Ώیڋq���ǉ�(A-3)
 *  get_cust_inf_p         �������l���Ώیڋq��񒊏o(A-4)
 *  upd_cust_inf_p         �������l���Ώیڋq���X�V(A-5)
 *  get_target_cust_p      AR�A�W�Ώیڋq���o(A-6)
 *  transfer_to_ar_p       AR�A�W����(A-7)
 *  upd_control_p          �̔��T���Ǘ����X�V(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/22    1.0   Y.Koh            �V�K�쐬
 *  2021/06/03    1.1   SCSK Y.Koh       [E_�{�ғ�_16026] ����Ŗ��בΉ�
 *  2021/06/21    1.2   SCSK T.Nishikawa [E_�{�ғ�_17278] �����Ώۂ��甄����ѐU�֕�������
 *  2021/09/10    1.3   SCSK K.Yoshikawa [E_�{�ғ�_17505] �������l�������̎��s���̕ύX
 *
 *****************************************************************************************/
--
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A32C';                      -- �p�b�P�[�W��
--
  -- �v���t�@�C��
  cv_gl_category_bm           CONSTANT VARCHAR2(30)         := 'XXCOK1_GL_CATEGORY_BM';             -- �d��J�e�S��_�̔��萔��
  cv_gl_category_condition1   CONSTANT VARCHAR2(30)         := 'XXCOK1_GL_CATEGORY_CONDITION1';     -- �d��J�e�S��_�̔��T��
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(30)         := 'GL_SET_OF_BKS_ID';                  -- GL��v����ID
  cv_ra_trx_type_general      CONSTANT VARCHAR2(30)         := 'XXCOK1_RA_TRX_TYPE_GENERAL';        -- ����^�C�v_�����l��_��ʓX
  cv_other_tax_code           CONSTANT VARCHAR2(30)         := 'XXCOK1_OTHER_TAX_CODE';             -- �ΏۊO����ŃR�[�h
  cv_org_id                   CONSTANT VARCHAR2(30)         := 'ORG_ID';                            -- �c�ƒP��
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF1_COMPANY_CODE';          -- ��ЃR�[�h
  cv_aff2_dept_fin            CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF2_DEPT_FIN';              -- ����R�[�h_�����o����
  cv_aff3_account_receivable  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF3_ACCOUNT_RECEIVABLE';    -- ����Ȗ�_���|��
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- �⏕�Ȗ�_�_�~�[�l
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF5_CUSTOMER_DUMMY';        -- �ڋq�R�[�h_�_�~�[�l
  cv_aff6_company_dummy       CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- ��ƃR�[�h_�_�~�[�l
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- �\���P_�_�~�[�l
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- �\���Q_�_�~�[�l
  cv_instantly_term_name      CONSTANT VARCHAR2(30)         := 'XXCOK1_INSTANTLY_TERM_NAME';        -- �x������_��������
--
  -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- �����������b�Z�[�W
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- �v���t�@�C���擾�G���[
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- �Ɩ��������t�擾�G���[
  cv_msg_cok_10592            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10592';                  -- �O�񏈗�ID�擾�G���[
  cv_msg_cok_10790            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10790';                  -- ������ڋq���ݒ�G���[
  cv_msg_cok_10791            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10791';                  -- �x���������ݒ�G���[
  cv_msg_cok_10792            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10792';                  -- ���������s�T�C�N�����ݒ�G���[
--
  -- �g�[�N����
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- �����̃g�[�N����
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- �v���t�@�C�����̃g�[�N����
  cv_tkn_customer             CONSTANT VARCHAR2(15)         := 'CUSTOMER_CODE';                     -- �ڋq�R�[�h�̃g�[�N����
  -- �t���O
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- �쐬���敪 N
  -- �L��
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  -- ==============================
  -- �O���[�o���ϐ�
  -- ==============================
  gn_target_cnt               NUMBER                        := 0;                                   -- �Ώی���
  gn_normal_cnt               NUMBER                        := 0;                                   -- ���팏��
  gn_skip_cnt                 NUMBER                        := 0;                                   -- �X�L�b�v����
  gn_error_cnt                NUMBER                        := 0;                                   -- �G���[����
--
  gd_process_date             DATE;                                                                 -- �Ɩ��������t
  gv_gl_category_bm           VARCHAR2(30);                                                         -- �d��J�e�S��_�̔��萔��
  gv_gl_category_condition1   VARCHAR2(30);                                                         -- �d��J�e�S��_�̔��T��
  gn_gl_set_of_bks_id         NUMBER;                                                               -- GL��v����ID
  gv_ra_trx_type_general      VARCHAR2(30);                                                         -- ����^�C�v_�����l��_��ʓX
  gv_other_tax_code           VARCHAR2(30);                                                         -- �ΏۊO����ŃR�[�h
  gn_org_id                   NUMBER;                                                               -- �c�ƒP��
  gv_aff1_company_code        VARCHAR2(30);                                                         -- ��ЃR�[�h
  gv_aff2_dept_fin            VARCHAR2(30);                                                         -- ����R�[�h_�����o����
  gv_aff3_account_receivable  VARCHAR2(30);                                                         -- ����Ȗ�_���|��
  gv_aff4_subacct_dummy       VARCHAR2(30);                                                         -- �⏕�Ȗ�_�_�~�[�l
  gv_aff5_customer_dummy      VARCHAR2(30);                                                         -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy       VARCHAR2(30);                                                         -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(30);                                                         -- �\���P_�_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(30);                                                         -- �\���Q_�_�~�[�l
  gv_instantly_term_name      VARCHAR2(30);                                                         -- �x������_��������
  gv_currency_code            VARCHAR2(30);                                                         -- �ʉ݃R�[�h
  gv_invoice_hold_status      VARCHAR2(30);                                                         -- �������ۗ��X�e�[�^�X
--
  gn_target_deduction_id_st   NUMBER;                                                               -- �̔����і���ID (��)
  gn_target_deduction_id_ed   NUMBER;                                                               -- �̔����і���ID (��)
--
  -- ==============================
  -- �O���[�o����O
  -- ==============================
  -- *** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �Ɩ��������t�̎擾
    -- ============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_appli_xxcok_name
                                             ,cv_msg_cok_00028
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ============================================================
    -- �v���t�@�C���l�̎擾
    -- ============================================================
--
    -- �d��J�e�S��_�̔��萔��
    gv_gl_category_bm := FND_PROFILE.VALUE( cv_gl_category_bm );
    IF gv_gl_category_bm IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_category_bm
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �d��J�e�S��_�̔��T��
    gv_gl_category_condition1 := FND_PROFILE.VALUE( cv_gl_category_condition1 );
    IF gv_gl_category_condition1 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_category_condition1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- GL��v����ID
    gn_gl_set_of_bks_id := FND_PROFILE.VALUE( cv_gl_set_of_bks_id );
    IF gn_gl_set_of_bks_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����^�C�v_�����l��_��ʓX
    gv_ra_trx_type_general := FND_PROFILE.VALUE( cv_ra_trx_type_general );
    IF gv_ra_trx_type_general IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ΏۊO����ŃR�[�h
    gv_other_tax_code := FND_PROFILE.VALUE( cv_other_tax_code );
    IF gv_other_tax_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_other_tax_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �c�ƒP��
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ЃR�[�h
    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF gv_aff1_company_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff1_company_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����R�[�h_�����o����
    gv_aff2_dept_fin := FND_PROFILE.VALUE( cv_aff2_dept_fin );
    IF gv_aff2_dept_fin IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff2_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_���|��
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );
    IF gv_aff3_account_receivable IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff3_account_receivable
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�_�~�[�l
    gv_aff4_subacct_dummy := FND_PROFILE.VALUE( cv_aff4_subacct_dummy );
    IF gv_aff4_subacct_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff4_subacct_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ڋq�R�[�h_�_�~�[�l
    gv_aff5_customer_dummy := FND_PROFILE.VALUE( cv_aff5_customer_dummy );
    IF gv_aff5_customer_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff5_customer_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ƃR�[�h_�_�~�[�l
    gv_aff6_company_dummy := FND_PROFILE.VALUE( cv_aff6_company_dummy );
    IF gv_aff6_company_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff6_company_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���P_�_�~�[�l
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );
    IF gv_aff7_preliminary1_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff7_preliminary1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���Q_�_�~�[�l
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );
    IF gv_aff8_preliminary2_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff8_preliminary2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �x������_��������
    gv_instantly_term_name := FND_PROFILE.VALUE( cv_instantly_term_name );
    IF gv_instantly_term_name IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_instantly_term_name
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �ʉ݃R�[�h�̎擾
    -- ============================================================
    SELECT  currency_code
    INTO    gv_currency_code
    FROM    gl_sets_of_books gsob
    WHERE   gsob.set_of_books_id = gn_gl_set_of_bks_id;
--
    -- ============================================================
    -- �������ۗ��X�e�[�^�X�̎擾
    -- ============================================================
    SELECT  DECODE(rctt.attribute1,'Y','OPEN','HOLD')
    INTO    gv_invoice_hold_status
    FROM    ra_cust_trx_types_all rctt
    WHERE   rctt.name   = gv_ra_trx_type_general
    AND     rctt.org_id = gn_org_id;
--
    -- ============================================================
    -- �����Ώ۔͈͂̔̔����уw�b�_�[ID�̎擾
    -- ============================================================
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_deduction_id_st
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_n;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xsd.sales_deduction_id)
    INTO    gn_target_deduction_id_ed
    FROM    xxcok_sales_deduction xsd
    WHERE   xsd.sales_deduction_id  >=  gn_target_deduction_id_st;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_inf_p
   * Description      : �������l���Ώیڋq���ǉ�(A-3)
   ***********************************************************************************/
  PROCEDURE ins_cust_inf_p(
    ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_customer_code_to IN  VARCHAR2  -- �U�֐�ڋq�R�[�h
  , id_max_record_date  IN  DATE      -- �ŏI�v���
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_cust_inf_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf                 VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ld_last_record_date       DATE;                                   -- �ŏI�v���
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    BEGIN
--
      SELECT  xdci.last_record_date as  last_record_date
      INTO    ld_last_record_date
      FROM    xxcok_discounted_cust_inf xdci
      WHERE   xdci.ship_to_customer_code  = iv_customer_code_to;
--
    EXCEPTION
      WHEN  OTHERS THEN
        ld_last_record_date :=  NULL;
    END;
--
    IF  ld_last_record_date IS  NULL  THEN
--
      -- ============================================================
      -- �������l���Ώیڋq���o�^
      -- ============================================================
      INSERT  INTO  xxcok_discounted_cust_inf(
        ship_to_customer_code , -- �[�i��ڋq
        last_record_date      , -- �ŏI�v���
        last_closing_date     , -- �O�����
        created_by            , -- �쐬��
        creation_date         , -- �쐬��
        last_updated_by       , -- �ŏI�X�V��
        last_update_date      , -- �ŏI�X�V��
        last_update_login     , -- �ŏI�X�V���O�C��
        request_id            , -- �v��ID
        program_application_id, -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        program_id            , -- �R���J�����g�E�v���O����ID
        program_update_date   ) -- �v���O�����X�V��
      VALUES(
        iv_customer_code_to   , -- �[�i��ڋq
        id_max_record_date    , -- �ŏI�v���
        gd_process_date - 1   , -- �O�����
        cn_user_id            , -- �쐬��
        SYSDATE               , -- �쐬��
        cn_user_id            , -- �ŏI�X�V��
        SYSDATE               , -- �ŏI�X�V��
        cn_login_id           , -- �ŏI�X�V���O�C��
        cn_conc_request_id    , -- �v��ID
        cn_prog_appl_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        cn_conc_program_id    , -- �R���J�����g�E�v���O����ID
        SYSDATE               );-- �v���O�����X�V��
--
    ELSIF ld_last_record_date < id_max_record_date  THEN
--
      UPDATE  xxcok_discounted_cust_inf xdci
      SET     xdci.last_record_date       = id_max_record_date, -- �ŏI�v���
              xdci.last_updated_by        = cn_user_id        , -- �ŏI�X�V��
              xdci.last_update_date       = SYSDATE           , -- �ŏI�X�V��
              xdci.last_update_login      = cn_login_id       , -- �ŏI�X�V���O�C��
              xdci.request_id             = cn_conc_request_id, -- �v��ID
              xdci.program_application_id = cn_prog_appl_id   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              xdci.program_id             = cn_conc_program_id, -- �R���J�����g�E�v���O����ID
              xdci.program_update_date    = SYSDATE             -- �v���O�����X�V��
      WHERE   xdci.ship_to_customer_code  = iv_customer_code_to;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END ins_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : get_deduction_p
   * Description      : �̔��T����񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_deduction_p(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_deduction_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- �̔��T�����
    CURSOR l_deduction_cur
    IS
      WITH
        flvc1 AS
        ( SELECT  /*+ MATERIALIZED */ lookup_code
          FROM    fnd_lookup_values flvc
          WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
          AND     flvc.language     = 'JA'
          AND     flvc.enabled_flag = 'Y'
          AND     flvc.attribute10  = 'Y'
        )
      SELECT  xsd.customer_code_to  AS  customer_code_to,
              MAX(xsd.record_date)  AS  max_record_date
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.sales_deduction_id  BETWEEN gn_target_deduction_id_st AND gn_target_deduction_id_ed
      AND     xsd.data_type           =   flv.lookup_code
      AND     xsd.status              =   'N'
      AND     xsd.recon_slip_num      IS  NULL
      AND     xsd.customer_code_to    IS NOT NULL
-- 2021/06/21 Ver1.2 ADD Start
      AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
      GROUP BY xsd.customer_code_to;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T����񒊏o
    -- ============================================================
    FOR l_deduction_rec IN  l_deduction_cur LOOP
--
      -- ============================================================
      -- �������l���Ώیڋq���ǉ�(A-3)�̌Ăяo��
      -- ============================================================
      ins_cust_inf_p(
        ov_errbuf             =>  lv_errbuf                         -- �G���[�E���b�Z�[�W
      , ov_retcode            =>  lv_retcode                        -- ���^�[���E�R�[�h
      , ov_errmsg             =>  lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_customer_code_to   =>  l_deduction_rec.customer_code_to  -- �U�֐�ڋq�R�[�h
      , id_max_record_date    =>  l_deduction_rec.max_record_date   -- �ŏI�v���
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_cust_inf_p
   * Description      : �������l���Ώیڋq���X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_cust_inf_p(
    ov_errbuf                 OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_ship_to_customer_code  IN  VARCHAR2  -- �[�i��ڋq
  , id_last_record_date       IN  DATE      -- �ŏI�v���
  , last_closing_date         IN  DATE      -- �O�����
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_cust_inf_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_ship_to_customer_id              NUMBER;                                 -- �[�i��ڋqID
    ln_ship_to_customer_site_id         NUMBER;                                 -- �[�i��ڋq�T�C�gID
    lv_billing_customer_code            VARCHAR2(09);                           -- ������ڋq
    ln_billing_customer_id              NUMBER;                                 -- ������ڋqID
    ln_billing_customer_site_id         NUMBER;                                 -- ������ڋq�T�C�gID
    lv_payment_terms_1                  VARCHAR2(15);                           -- �x������1
    lv_payment_terms_2                  VARCHAR2(15);                           -- �x������2
    lv_payment_terms_3                  VARCHAR2(15);                           -- �x������3
    ln_invoice_issue_cycle              NUMBER;                                 -- ���������s�T�C�N��
    ld_next_closing_date                DATE;                                   -- �������
    lv_next_payment_term                VARCHAR2(15);                           -- ����x������
--
    ld_close_date                       DATE;                                   -- ���ߓ�
    ld_pay_date                         DATE;                                   -- �x����
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    IF  id_last_record_date < gd_process_date - 365 THEN
      DELETE
      FROM    xxcok_discounted_cust_inf xdci
      WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
    ELSE
--
      -- ============================================================
      -- �ڋq���擾
      -- ============================================================
      BEGIN
--
        SELECT  ship_hca.cust_account_id    AS  ship_to_customer_id     , -- �[�i��ڋqID
                ship_hcas.cust_acct_site_id AS  ship_to_customer_site_id, -- �[�i��ڋq�T�C�gID
                bill_hca.account_number     AS  billing_customer_code   , -- ������ڋq
                bill_hca.cust_account_id    AS  billing_customer_id     , -- ������ڋqID
                bill_hcas.cust_acct_site_id AS  billing_customer_site_id, -- ������ڋq�T�C�gID
                rtt1.name                   AS  payment_terms_1         , -- �x������1
                rtt2.name                   AS  payment_terms_2         , -- �x������2
                rtt3.name                   AS  payment_terms_3         , -- �x������3
                bill_hcsa.attribute8        AS  invoice_issue_cycle       -- ���������s�T�C�N��
        INTO    ln_ship_to_customer_id      , -- �[�i��ڋqID
                ln_ship_to_customer_site_id , -- �[�i��ڋq�T�C�gID
                lv_billing_customer_code    , -- ������ڋq
                ln_billing_customer_id      , -- ������ڋqID
                ln_billing_customer_site_id , -- ������ڋq�T�C�gID
                lv_payment_terms_1          , -- �x������1
                lv_payment_terms_2          , -- �x������2
                lv_payment_terms_3          , -- �x������3
                ln_invoice_issue_cycle        -- ���������s�T�C�N��
        FROM    hz_cust_accounts        ship_hca  , -- �[�i��_�ڋq�}�X�^
                hz_cust_acct_sites_all  ship_hcas , -- �[�i��_�ڋq�T�C�g�}�X�^
                hz_cust_site_uses_all   ship_hcsa , -- �[�i��_�ڋq�g�p�ړI
                hz_cust_accounts        bill_hca  , -- ������_�ڋq�}�X�^
                hz_cust_acct_sites_all  bill_hcas , -- ������_�ڋq�T�C�g�}�X�^
                hz_cust_site_uses_all   bill_hcsa , -- ������_�ڋq�g�p�ړI
                ra_terms_tl             rtt1      , -- �x������1
                ra_terms_tl             rtt2      , -- �x������2
                ra_terms_tl             rtt3        -- �x������3
        WHERE   ship_hca.account_number     = iv_ship_to_customer_code
        AND     ship_hcas.cust_account_id   = ship_hca.cust_account_id
        AND     ship_hcas.org_id            = gn_org_id
        AND     ship_hcsa.cust_acct_site_id = ship_hcas.cust_acct_site_id
        AND     ship_hcsa.site_use_code     = 'SHIP_TO'
        AND     ship_hcsa.status            = 'A'
        AND     bill_hcsa.site_use_id       = ship_hcsa.bill_to_site_use_id
        AND     bill_hcsa.site_use_code     = 'BILL_TO'
        AND     bill_hcsa.status            = 'A'
        AND     bill_hcas.cust_acct_site_id = bill_hcsa.cust_acct_site_id
        AND     bill_hca.cust_account_id    = bill_hcas.cust_account_id
        AND     rtt1.term_id(+)             = bill_hcsa.payment_term_id
        AND     rtt1.language(+)            = 'JA'
        AND     rtt2.term_id(+)             = bill_hcsa.attribute2
        AND     rtt2.language(+)            = 'JA'
        AND     rtt3.term_id(+)             = bill_hcsa.attribute3
        AND     rtt3.language(+)            = 'JA';
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_billing_customer_code  :=  NULL;
      END;
--
      IF  lv_billing_customer_code  IS  NULL  THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                       ,cv_msg_cok_10790
                       ,cv_tkn_customer
                       ,iv_ship_to_customer_code
                      );
        ov_errmsg :=  lv_errmsg;
        gn_skip_cnt :=  gn_skip_cnt + 1;
        ov_retcode  :=  cv_status_warn;
      ELSE
        IF  lv_payment_terms_1  IS  NULL  AND
            lv_payment_terms_2  IS  NULL  AND
            lv_payment_terms_3  IS  NULL  THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                         ,cv_msg_cok_10791
                         ,cv_tkn_customer
                         ,iv_ship_to_customer_code
                        );
          ov_errmsg :=  lv_errmsg;
          gn_skip_cnt :=  gn_skip_cnt + 1;
          ov_retcode  :=  cv_status_warn;
        END IF;
--
        IF  ln_invoice_issue_cycle  IS  NULL  THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                         ,cv_msg_cok_10792
                         ,cv_tkn_customer
                         ,iv_ship_to_customer_code
                        );
          ov_errmsg :=  lv_errmsg;
          gn_skip_cnt :=  gn_skip_cnt + 1;
          ov_retcode  :=  cv_status_warn;
        END IF;
      END IF;
--
      IF  ov_retcode  = cv_status_normal  THEN
--
        -- ============================================================
        -- ��������擾
        -- ============================================================
        IF  lv_payment_terms_1  = gv_instantly_term_name  OR
            lv_payment_terms_2  = gv_instantly_term_name  OR
            lv_payment_terms_3  = gv_instantly_term_name  THEN
          ld_next_closing_date  :=  gd_process_date;
          lv_next_payment_term  :=  gv_instantly_term_name;
          ln_invoice_issue_cycle := 0;
        ELSE
--
          IF  lv_payment_terms_1  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- �G���[�E���b�Z�[�W
              ov_retcode    =>  lv_retcode          , -- ���^�[���E�R�[�h
              ov_errmsg     =>  lv_errmsg           , -- ���[�U�[�E�G���[�E���b�Z�[�W
              id_proc_date  =>  last_closing_date   , -- ������
              iv_pay_cond   =>  lv_payment_terms_1  , -- �x������
              od_close_date =>  ld_close_date       , -- ���ߓ�
              od_pay_date   =>  ld_pay_date           -- �x����
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- �G���[�E���b�Z�[�W
                ov_retcode    =>  lv_retcode                      , -- ���^�[���E�R�[�h
                ov_errmsg     =>  lv_errmsg                       , -- ���[�U�[�E�G���[�E���b�Z�[�W
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- ������
                iv_pay_cond   =>  lv_payment_terms_1              , -- �x������
                od_close_date =>  ld_close_date                   , -- ���ߓ�
                od_pay_date   =>  ld_pay_date                       -- �x����
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_1;
            END IF;
--
          END IF;
--
          IF  lv_payment_terms_2  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- �G���[�E���b�Z�[�W
              ov_retcode    =>  lv_retcode          , -- ���^�[���E�R�[�h
              ov_errmsg     =>  lv_errmsg           , -- ���[�U�[�E�G���[�E���b�Z�[�W
              id_proc_date  =>  last_closing_date   , -- ������
              iv_pay_cond   =>  lv_payment_terms_2  , -- �x������
              od_close_date =>  ld_close_date       , -- ���ߓ�
              od_pay_date   =>  ld_pay_date           -- �x����
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- �G���[�E���b�Z�[�W
                ov_retcode    =>  lv_retcode                      , -- ���^�[���E�R�[�h
                ov_errmsg     =>  lv_errmsg                       , -- ���[�U�[�E�G���[�E���b�Z�[�W
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- ������
                iv_pay_cond   =>  lv_payment_terms_2              , -- �x������
                od_close_date =>  ld_close_date                   , -- ���ߓ�
                od_pay_date   =>  ld_pay_date                       -- �x����
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_2;
            END IF;
--
          END IF;
--
          IF  lv_payment_terms_3  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- �G���[�E���b�Z�[�W
              ov_retcode    =>  lv_retcode          , -- ���^�[���E�R�[�h
              ov_errmsg     =>  lv_errmsg           , -- ���[�U�[�E�G���[�E���b�Z�[�W
              id_proc_date  =>  last_closing_date   , -- ������
              iv_pay_cond   =>  lv_payment_terms_3  , -- �x������
              od_close_date =>  ld_close_date       , -- ���ߓ�
              od_pay_date   =>  ld_pay_date           -- �x����
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- �G���[�E���b�Z�[�W
                ov_retcode    =>  lv_retcode                      , -- ���^�[���E�R�[�h
                ov_errmsg     =>  lv_errmsg                       , -- ���[�U�[�E�G���[�E���b�Z�[�W
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- ������
                iv_pay_cond   =>  lv_payment_terms_3              , -- �x������
                od_close_date =>  ld_close_date                   , -- ���ߓ�
                od_pay_date   =>  ld_pay_date                       -- �x����
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_3;
            END IF;
--
          END IF;
--
        END IF;
--
        -- ============================================================
        -- �������l���Ώیڋq���X�V
        -- ============================================================
        UPDATE  xxcok_discounted_cust_inf xdci
        SET     xdci.ship_to_customer_id      = ln_ship_to_customer_id      , -- �[�i��ڋqID
                xdci.ship_to_customer_site_id = ln_ship_to_customer_site_id , -- �[�i��ڋq�T�C�gID
                xdci.billing_customer_code    = lv_billing_customer_code    , -- ������ڋq
                xdci.billing_customer_id      = ln_billing_customer_id      , -- ������ڋqID
                xdci.billing_customer_site_id = ln_billing_customer_site_id , -- ������ڋq�T�C�gID
                xdci.payment_terms_1          = lv_payment_terms_1          , -- �x������1
                xdci.payment_terms_2          = lv_payment_terms_2          , -- �x������2
                xdci.payment_terms_3          = lv_payment_terms_3          , -- �x������3
                xdci.invoice_issue_cycle      = ln_invoice_issue_cycle      , -- ���������s�T�C�N��
                xdci.next_closing_date        = ld_next_closing_date        , -- �������
                xdci.next_payment_term        = lv_next_payment_term        , -- ����x������
                xdci.last_updated_by          = cn_user_id                  , -- �ŏI�X�V��
                xdci.last_update_date         = SYSDATE                     , -- �ŏI�X�V��
                xdci.last_update_login        = cn_login_id                 , -- �ŏI�X�V���O�C��
                xdci.request_id               = cn_conc_request_id          , -- �v��ID
                xdci.program_application_id   = cn_prog_appl_id             , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdci.program_id               = cn_conc_program_id          , -- �R���J�����g�E�v���O����ID
                xdci.program_update_date      = SYSDATE                       -- �v���O�����X�V��
        WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_inf_p
   * Description      : �������l���Ώیڋq��񒊏o(A-4)
   ***********************************************************************************/
  PROCEDURE get_cust_inf_p(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_cust_inf_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- �������l���Ώیڋq���
    CURSOR l_cust_inf_cur
    IS
      SELECT  xdci.ship_to_customer_code  AS  ship_to_customer_code ,
              xdci.last_record_date       AS  last_record_date      ,
              xdci.last_closing_date      AS  last_closing_date
      FROM    xxcok_discounted_cust_inf   xdci;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �������l���Ώیڋq��񒊏o
    -- ============================================================
    FOR l_cust_inf_rec  IN  l_cust_inf_cur  LOOP
--
      -- ============================================================
      -- �������l���Ώیڋq���X�V(A-5)�̌Ăяo��
      -- ============================================================
      upd_cust_inf_p(
        ov_errbuf                 =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
      , ov_retcode                =>  lv_retcode                            -- ���^�[���E�R�[�h
      , ov_errmsg                 =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_ship_to_customer_code  =>  l_cust_inf_rec.ship_to_customer_code  -- �[�i��ڋq
      , id_last_record_date       =>  l_cust_inf_rec.last_record_date       -- �ŏI�v���
      , last_closing_date         =>  l_cust_inf_rec.last_closing_date      -- �O�����
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
--
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_errmsg          -- ���b�Z�[�W
                      , 1                  -- ���s
                      );
--
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : transfer_to_ar_p
   * Description      : AR�A�W����(A-7)
   ***********************************************************************************/
  PROCEDURE transfer_to_ar_p(
    ov_errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_ship_to_customer_code    IN  VARCHAR2  -- �[�i��ڋq
  , in_ship_to_customer_id      IN  NUMBER    -- �[�i��ڋqID
  , in_ship_to_customer_site_id IN  NUMBER    -- �[�i��ڋq�T�C�gID
  , iv_billing_customer_code    IN  VARCHAR2  -- ������ڋq
  , in_billing_customer_id      IN  NUMBER    -- ������ڋqID
  , in_billing_customer_site_id IN  NUMBER    -- ������ڋq�T�C�gID
  , id_next_closing_date        IN  DATE      -- �������
  , iv_next_payment_term        IN  VARCHAR2  -- ����x������
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'transfer_to_ar_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_count                            NUMBER;                                 -- ����
    lv_interface_line_attribute1        VARCHAR2(30);                           -- �`�[�ԍ�
    ln_interface_line_attribute2        NUMBER              :=  0;              -- ���׍s�ԍ�
    lv_header_attribute5                VARCHAR2(150);                          -- �N�[����
    lv_header_attribute6                VARCHAR2(150);                          -- �`�[���͎�
    lv_header_attribute11               VARCHAR2(150);                          -- �������_
    lv_header_attribute13               VARCHAR2(150);                          -- �[�i��ڋq��
--
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- �̔��T�����y�{�̍s�p�z
    CURSOR l_sales_deduction_d_cur
    IS
      SELECT  SUM(xsd.deduction_amount) AS  deduction_amount,
              flv.meaning               AS  meaning         ,
              flv.attribute6            AS  attribute6      ,
              flv.attribute7            AS  attribute7
      FROM    fnd_lookup_values     flv ,
              xxcok_sales_deduction xsd
      WHERE   xsd.recon_slip_num  = lv_interface_line_attribute1
      AND     flv.lookup_type     = 'XXCOK1_DEDUCTION_DATA_TYPE'
      AND     flv.lookup_code     = xsd.data_type
      AND     flv.language        = 'JA'
      AND     flv.enabled_flag    = 'Y'
      GROUP BY  flv.meaning   ,
                flv.attribute6,
                flv.attribute7
      ORDER BY  flv.meaning;
--
    -- �̔��T�����y�ŋ��s�p�z
    CURSOR l_sales_deduction_t_cur
    IS
      SELECT  SUM(xsd.deduction_tax_amount) AS  deduction_tax_amount,
              atca.name                     AS  name        ,
              atca.description              AS  description ,
              atca.attribute5               AS  attribute5  ,
              atca.attribute6               AS  attribute6
      FROM    ap_tax_codes_all      atca,
              xxcok_sales_deduction xsd
      WHERE   xsd.recon_slip_num    = lv_interface_line_attribute1
      AND     atca.name             = xsd.tax_code
      AND     atca.set_of_books_id  = gn_gl_set_of_bks_id
      GROUP BY  atca.name       ,
                atca.description,
                atca.attribute5 ,
                atca.attribute6
      ORDER BY  atca.name;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T�����̗L���m�F
    -- ============================================================
    WITH
      flvc1 AS
      ( SELECT  /*+ MATERIALIZED */ lookup_code
        FROM    fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
        AND     flvc.language     = 'JA'
        AND     flvc.enabled_flag = 'Y'
        AND     flvc.attribute10  = 'Y'
      )
    SELECT  COUNT(*)
    INTO    ln_count
    FROM    xxcok_sales_deduction   xsd
    WHERE   xsd.customer_code_to    =   iv_ship_to_customer_code
    AND     xsd.record_date         <=  id_next_closing_date
    AND     xsd.data_type           IN  ( SELECT  lookup_code FROM  flvc1 )
    AND     xsd.status              =   'N'
    AND     xsd.recon_slip_num      IS  NULL
-- 2021/06/21 Ver1.2 ADD Start
    AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
    ;
--
    IF  ln_count  > 0 THEN
--
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ============================================================
      -- �`�[�ԍ��̔�
      -- ============================================================
      lv_interface_line_attribute1  :=  xxcok_common_pkg.get_slip_number_f(
                                          iv_package_name =>  cv_pkg_name
                                        );
--
      -- ============================================================
      -- �̔��T�����X�V
      -- ============================================================
      UPDATE  xxcok_sales_deduction xsd
      SET     xsd.recon_slip_num          = lv_interface_line_attribute1, -- �x���`�[�ԍ�
              xsd.carry_payment_slip_num  = lv_interface_line_attribute1, -- �J�z���x���`�[�ԍ�
              xsd.last_updated_by         = cn_user_id                  , -- �ŏI�X�V��
              xsd.last_update_date        = SYSDATE                     , -- �ŏI�X�V��
              xsd.last_update_login       = cn_login_id                 , -- �ŏI�X�V���O�C��
              xsd.request_id              = cn_conc_request_id          , -- �v��ID
              xsd.program_application_id  = cn_prog_appl_id             , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              xsd.program_id              = cn_conc_program_id          , -- �R���J�����g�E�v���O����ID
              xsd.program_update_date     = SYSDATE                       -- �v���O�����X�V��
      WHERE   xsd.customer_code_to    =   iv_ship_to_customer_code
      AND     xsd.record_date         <=  id_next_closing_date
      AND     xsd.data_type           IN  (
                                            SELECT  lookup_code
                                            FROM    fnd_lookup_values flvc
                                            WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
                                            AND     flvc.language     = 'JA'
                                            AND     flvc.enabled_flag = 'Y'
                                            AND     flvc.attribute10  = 'Y'
                                          )
      AND     xsd.status              =   'N'
      AND     xsd.recon_slip_num      IS  NULL
-- 2021/06/21 Ver1.2 ADD Start
      AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
      ;
--
      -- ============================================================
      -- �ڋq���擾
      -- ============================================================
--
      -- �N�[����
      BEGIN
--
        SELECT  CASE
                  WHEN  TRUNC(id_next_closing_date,'MM')  = TRUNC(gd_process_date,'MM')
                  THEN
                    xca.sale_base_code
                  ELSE
                    xca.past_sale_base_code
                END as  sale_base_code
        INTO    lv_header_attribute5
        FROM    xxcmm_cust_accounts xca
        WHERE   xca.customer_code = iv_ship_to_customer_code;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_header_attribute5  :=  NULL;
      END;
--
      -- �`�[���͎�
      lv_header_attribute6  :=  xxcok_common_pkg.get_sales_staff_code_f(
                                  iv_customer_code  =>  iv_ship_to_customer_code,
                                  id_proc_date      =>  id_next_closing_date
                                );
--
      -- �������_
      BEGIN
--
        SELECT  xchv.cash_receiv_base_code  as  cash_receiv_base_code
        INTO    lv_header_attribute11
        FROM    xxcfr_cust_hierarchy_v  xchv
        WHERE   xchv.bill_account_number  = iv_billing_customer_code
        AND     xchv.ship_account_number  = iv_ship_to_customer_code;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_header_attribute11 :=  NULL;
      END;
--
      -- �[�i��ڋq��
      lv_header_attribute13 :=  xxcfr_common_pkg.get_cust_account_name(
                                  iv_account_number   =>  iv_ship_to_customer_code,
                                  iv_kana_judge_type  =>  '0'
                                );
--
      -- ============================================================
      -- �̔��T����񒊏o�y�{�̍s�z
      -- ============================================================
      FOR l_sales_deduction_d_rec in  l_sales_deduction_d_cur LOOP
--
        ln_interface_line_attribute2  :=  ln_interface_line_attribute2  + 1;
--
        -- ============================================================
        -- AR�������OIF�o�^�y�{�̍s�z
        -- ============================================================
        INSERT  INTO  ra_interface_lines_all(
          interface_line_context      , -- ������׃R���e�L�X�g
          interface_line_attribute1   , -- �������DFF1(�`�[�ԍ�)
          interface_line_attribute2   , -- �������DFF2(���׍s�ԍ�)
          batch_source_name           , -- ����\�[�X
          set_of_books_id             , -- ��v����ID
          line_type                   , -- ���׃^�C�v
          description                 , -- �i�ږ��דE�v
          currency_code               , -- �ʉ݃R�[�h
          amount                      , -- ���׋��z
          cust_trx_type_name          , -- ����^�C�v
          term_name                   , -- �x������
          orig_system_bill_customer_id, -- ������ڋqID
          orig_system_bill_address_id , -- ������ڋq���ݒn�Q��ID
          orig_system_ship_customer_id, -- �o�א�ڋqID
          orig_system_ship_address_id , -- �o�א�ڋq���ݒn�Q��ID
          conversion_type             , -- ���Z�^�C�v
          conversion_rate             , -- ���Z���[�g
          trx_date                    , -- �����
          gl_date                     , -- GL�L����
          trx_number                  , -- �`�[�ԍ�
          quantity                    , -- ����
          unit_selling_price          , -- �̔��P��
          tax_code                    , -- �ŋ��R�[�h
          header_attribute_category   , -- �w�b�_�[DFF�J�e�S��
          header_attribute5           , -- �w�b�_�[DFF5(�N�[����)
          header_attribute6           , -- �w�b�_�[DFF6(�`�[���͎�)
          header_attribute7           , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
          header_attribute8           , -- �w�b�_�[DFF8(�ʐ��������)
          header_attribute9           , -- �w�b�_�[DFF9(�ꊇ���������)
          header_attribute11          , -- �w�b�_�[DFF11(�������_)
          header_attribute12          , -- �w�b�_�[DFF12(�[�i��ڋq�R�[�h)
          header_attribute13          , -- �w�b�_�[DFF13(�[�i��ڋq��)
          header_attribute14          , -- �w�b�_�[DFF14(�`�[�ԍ�)
          header_attribute15          , -- �w�b�_�[DFF15(GL�L����)
          creation_date               , -- �쐬��
          org_id                      , -- �c�ƒP��ID
          amount_includes_tax_flag    ) -- ���Ńt���O
        VALUES(
          gv_gl_category_bm                         , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1              , -- �������DFF1(�`�[�ԍ�)
          ln_interface_line_attribute2              , -- �������DFF2(���׍s�ԍ�)
          gv_gl_category_condition1                 , -- ����\�[�X
          gn_gl_set_of_bks_id                       , -- ��v����ID
          'LINE'                                    , -- ���׃^�C�v
          l_sales_deduction_d_rec.meaning           , -- �i�ږ��דE�v
          gv_currency_code                          , -- �ʉ݃R�[�h
          - l_sales_deduction_d_rec.deduction_amount, -- ���׋��z
          gv_ra_trx_type_general                    , -- ����^�C�v
          iv_next_payment_term                      , -- �x������
          in_billing_customer_id                    , -- ������ڋqID
          in_billing_customer_site_id               , -- ������ڋq���ݒn�Q��ID
          in_ship_to_customer_id                    , -- �o�א�ڋqID
          in_ship_to_customer_site_id               , -- �o�א�ڋq���ݒn�Q��ID
          'User'                                    , -- ���Z�^�C�v
          1                                         , -- ���Z���[�g
          id_next_closing_date                      , -- �����
          id_next_closing_date                      , -- GL�L����
          lv_interface_line_attribute1              , -- �`�[�ԍ�
          1                                         , -- ����
          - l_sales_deduction_d_rec.deduction_amount, -- �̔��P��
          gv_other_tax_code                         , -- �ŋ��R�[�h
          gn_org_id                                 , -- �w�b�_�[DFF�J�e�S��
          lv_header_attribute5                      , -- �w�b�_�[DFF5(�N�[����)
          lv_header_attribute6                      , -- �w�b�_�[DFF6(�`�[���͎�)
          gv_invoice_hold_status                    , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
          'WAITING'                                 , -- �w�b�_�[DFF8(�ʐ��������)
          'WAITING'                                 , -- �w�b�_�[DFF9(�ꊇ���������)
          lv_header_attribute11                     , -- �w�b�_�[DFF11(�������_)
          iv_ship_to_customer_code                  , -- �w�b�_�[DFF12(�[�i��ڋq�R�[�h)
          lv_header_attribute13                     , -- �w�b�_�[DFF13(�[�i��ڋq��)
          lv_interface_line_attribute1              , -- �w�b�_�[DFF14(�`�[�ԍ�)
          TO_CHAR(id_next_closing_date,'YYYY/MM/DD'), -- �w�b�_�[DFF15(GL�L����)
          SYSDATE                                   , -- �쐬��
          gn_org_id                                 , -- �c�ƒP��ID
          'N'                                       );-- ���Ńt���O
--
        -- ============================================================
        -- AR��v�z��OIF�o�^�y�{�̍s�z
        -- ============================================================
        INSERT  INTO  ra_interface_distributions_all(
          interface_line_context    , -- ������׃R���e�L�X�g
          interface_line_attribute1 , -- �������DFF1
          interface_line_attribute2 , -- �������DFF2
          account_class             , -- ����Ȗڋ敪(�z���^�C�v)
          amount                    , -- ���z(���׋��z)
          percent                   , -- �p�[�Z���g(����)
          segment1                  , -- ��ЃZ�O�����g
          segment2                  , -- ����Z�O�����g
          segment3                  , -- ����ȖڃZ�O�����g
          segment4                  , -- �⏕�ȖڃZ�O�����g
          segment5                  , -- �ڋq�Z�O�����g
          segment6                  , -- ��ƃZ�O�����g
          segment7                  , -- �\���P�Z�O�����g
          segment8                  , -- �\���Q�Z�O�����g
          attribute_category        , -- �d�󖾍׃J�e�S��
          creation_date             , -- �쐬��
          org_id                    ) -- �c�ƒP��ID
        VALUES(
          gv_gl_category_bm                         , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1              , -- �������DFF1(�`�[�ԍ�)
          ln_interface_line_attribute2              , -- �������DFF2(���׍s�ԍ�)
          'REV'                                     , -- ����Ȗڋ敪(�z���^�C�v)
          - l_sales_deduction_d_rec.deduction_amount, -- ���z(���׋��z)
          100                                       , -- �p�[�Z���g(����)
          gv_aff1_company_code                      , -- ��ЃZ�O�����g
          gv_aff2_dept_fin                          , -- ����Z�O�����g
          l_sales_deduction_d_rec.attribute6        , -- ����ȖڃZ�O�����g
          l_sales_deduction_d_rec.attribute7        , -- �⏕�ȖڃZ�O�����g
          gv_aff5_customer_dummy                    , -- �ڋq�Z�O�����g
          gv_aff6_company_dummy                     , -- ��ƃZ�O�����g
          gv_aff7_preliminary1_dummy                , -- �\���P�Z�O�����g
          gv_aff8_preliminary2_dummy                , -- �\���Q�Z�O�����g
          gn_org_id                                 , -- ����DFF�J�e�S��
          SYSDATE                                   , -- �쐬��
          gn_org_id                                 );-- �c�ƒP��ID
--
      END LOOP;
--
      -- ============================================================
      -- �̔��T����񒊏o�y�ŋ��s�z
      -- ============================================================
      FOR l_sales_deduction_t_rec in  l_sales_deduction_t_cur LOOP
--
        ln_interface_line_attribute2  :=  ln_interface_line_attribute2  + 1;
--
        -- ============================================================
        -- AR�������OIF�o�^�y�ŋ��s�z
        -- ============================================================
        INSERT  INTO  ra_interface_lines_all(
          interface_line_context      , -- ������׃R���e�L�X�g
          interface_line_attribute1   , -- �������DFF1(�`�[�ԍ�)
          interface_line_attribute2   , -- �������DFF2(���׍s�ԍ�)
          batch_source_name           , -- ����\�[�X
          set_of_books_id             , -- ��v����ID
          line_type                   , -- ���׃^�C�v
          description                 , -- �i�ږ��דE�v
          currency_code               , -- �ʉ݃R�[�h
          amount                      , -- ���׋��z
          cust_trx_type_name          , -- ����^�C�v
          term_name                   , -- �x������
          orig_system_bill_customer_id, -- ������ڋqID
          orig_system_bill_address_id , -- ������ڋq���ݒn�Q��ID
          orig_system_ship_customer_id, -- �o�א�ڋqID
          orig_system_ship_address_id , -- �o�א�ڋq���ݒn�Q��ID
-- 2021/06/03 Ver1.1 ADD Start
          link_to_line_context        , -- �����N���׃R���e�L�X�g
          link_to_line_attribute1     , -- �����N����DFF1
          link_to_line_attribute2     , -- �����N����DFF2
-- 2021/06/03 Ver1.1 ADD End
          conversion_type             , -- ���Z�^�C�v
          conversion_rate             , -- ���Z���[�g
          trx_date                    , -- �����
          gl_date                     , -- GL�L����
          trx_number                  , -- �`�[�ԍ�
          quantity                    , -- ����
          unit_selling_price          , -- �̔��P��
          tax_code                    , -- �ŋ��R�[�h
          header_attribute_category   , -- �w�b�_�[DFF�J�e�S��
          header_attribute5           , -- �w�b�_�[DFF5(�N�[����)
          header_attribute6           , -- �w�b�_�[DFF6(�`�[���͎�)
          header_attribute7           , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
          header_attribute8           , -- �w�b�_�[DFF8(�ʐ��������)
          header_attribute9           , -- �w�b�_�[DFF9(�ꊇ���������)
          header_attribute11          , -- �w�b�_�[DFF11(�������_)
          header_attribute12          , -- �w�b�_�[DFF12(�[�i��ڋq�R�[�h)
          header_attribute13          , -- �w�b�_�[DFF13(�[�i��ڋq��)
          header_attribute14          , -- �w�b�_�[DFF14(�`�[�ԍ�)
          header_attribute15          , -- �w�b�_�[DFF15(GL�L����)
          creation_date               , -- �쐬��
          org_id                      , -- �c�ƒP��ID
          amount_includes_tax_flag    ) -- ���Ńt���O
        VALUES(
          gv_gl_category_bm                             , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1                  , -- �������DFF1(�`�[�ԍ�)
          ln_interface_line_attribute2                  , -- �������DFF2(���׍s�ԍ�)
          gv_gl_category_condition1                     , -- ����\�[�X
          gn_gl_set_of_bks_id                           , -- ��v����ID
-- 2021/06/03 Ver1.1 MOD Start
          'TAX'                                         , -- ���׃^�C�v
--          'LINE'                                        , -- ���׃^�C�v
-- 2021/06/03 Ver1.1 MOD End
          l_sales_deduction_t_rec.description           , -- �i�ږ��דE�v
          gv_currency_code                              , -- �ʉ݃R�[�h
          - l_sales_deduction_t_rec.deduction_tax_amount, -- ���׋��z
          gv_ra_trx_type_general                        , -- ����^�C�v
          iv_next_payment_term                          , -- �x������
          in_billing_customer_id                        , -- ������ڋqID
          in_billing_customer_site_id                   , -- ������ڋq���ݒn�Q��ID
          in_ship_to_customer_id                        , -- �o�א�ڋqID
          in_ship_to_customer_site_id                   , -- �o�א�ڋq���ݒn�Q��ID
-- 2021/06/03 Ver1.1 ADD Start
          gv_gl_category_bm                             , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1                  , -- �������DFF1(�`�[�ԍ�)
          1                                             , -- �������DFF2(���׍s�ԍ�)
-- 2021/06/03 Ver1.1 ADD End
          'User'                                        , -- ���Z�^�C�v
          1                                             , -- ���Z���[�g
          id_next_closing_date                          , -- �����
          id_next_closing_date                          , -- GL�L����
          lv_interface_line_attribute1                  , -- �`�[�ԍ�
          1                                             , -- ����
          - l_sales_deduction_t_rec.deduction_tax_amount, -- �̔��P��
          gv_other_tax_code                             , -- �ŋ��R�[�h
          gn_org_id                                     , -- �w�b�_�[DFF�J�e�S��
          lv_header_attribute5                          , -- �w�b�_�[DFF5(�N�[����)
          lv_header_attribute6                          , -- �w�b�_�[DFF6(�`�[���͎�)
          gv_invoice_hold_status                        , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
          'WAITING'                                     , -- �w�b�_�[DFF8(�ʐ��������)
          'WAITING'                                     , -- �w�b�_�[DFF9(�ꊇ���������)
          lv_header_attribute11                         , -- �w�b�_�[DFF11(�������_)
          iv_ship_to_customer_code                      , -- �w�b�_�[DFF12(�[�i��ڋq�R�[�h)
          lv_header_attribute13                         , -- �w�b�_�[DFF13(�[�i��ڋq��)
          lv_interface_line_attribute1                  , -- �w�b�_�[DFF14(�`�[�ԍ�)
          TO_CHAR(id_next_closing_date,'YYYY/MM/DD')    , -- �w�b�_�[DFF15(GL�L����)
          SYSDATE                                       , -- �쐬��
          gn_org_id                                     , -- �c�ƒP��ID
          'N'                                           );-- ���Ńt���O
--
        -- ============================================================
        -- AR��v�z��OIF�o�^�y�ŋ��s�z
        -- ============================================================
        INSERT  INTO  ra_interface_distributions_all(
          interface_line_context    , -- ������׃R���e�L�X�g
          interface_line_attribute1 , -- �������DFF1
          interface_line_attribute2 , -- �������DFF2
          account_class             , -- ����Ȗڋ敪(�z���^�C�v)
          amount                    , -- ���z(���׋��z)
          percent                   , -- �p�[�Z���g(����)
          segment1                  , -- ��ЃZ�O�����g
          segment2                  , -- ����Z�O�����g
          segment3                  , -- ����ȖڃZ�O�����g
          segment4                  , -- �⏕�ȖڃZ�O�����g
          segment5                  , -- �ڋq�Z�O�����g
          segment6                  , -- ��ƃZ�O�����g
          segment7                  , -- �\���P�Z�O�����g
          segment8                  , -- �\���Q�Z�O�����g
          attribute_category        , -- �d�󖾍׃J�e�S��
          creation_date             , -- �쐬��
          org_id                    ) -- �c�ƒP��ID
        VALUES(
          gv_gl_category_bm                             , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1                  , -- �������DFF1(�`�[�ԍ�)
          ln_interface_line_attribute2                  , -- �������DFF2(���׍s�ԍ�)
-- 2021/06/03 Ver1.1 MOD Start
          'TAX'                                         , -- ����Ȗڋ敪(�z���^�C�v)
--          'REV'                                         , -- ����Ȗڋ敪(�z���^�C�v)
-- 2021/06/03 Ver1.1 MOD End
          - l_sales_deduction_t_rec.deduction_tax_amount, -- ���z(���׋��z)
          100                                           , -- �p�[�Z���g(����)
          gv_aff1_company_code                          , -- ��ЃZ�O�����g
          gv_aff2_dept_fin                              , -- ����Z�O�����g
          l_sales_deduction_t_rec.attribute5            , -- ����ȖڃZ�O�����g
          l_sales_deduction_t_rec.attribute6            , -- �⏕�ȖڃZ�O�����g
          gv_aff5_customer_dummy                        , -- �ڋq�Z�O�����g
          gv_aff6_company_dummy                         , -- ��ƃZ�O�����g
          gv_aff7_preliminary1_dummy                    , -- �\���P�Z�O�����g
          gv_aff8_preliminary2_dummy                    , -- �\���Q�Z�O�����g
          gn_org_id                                     , -- ����DFF�J�e�S��
          SYSDATE                                       , -- �쐬��
          gn_org_id                                     );-- �c�ƒP��ID
--
      END LOOP;
--
      -- ============================================================
      -- AR��v�z��OIF�o�^�y���s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context    , -- ������׃R���e�L�X�g
        interface_line_attribute1 , -- �������DFF1
        interface_line_attribute2 , -- �������DFF2
        account_class             , -- ����Ȗڋ敪(�z���^�C�v)
        percent                   , -- �p�[�Z���g(����)
        segment1                  , -- ��ЃZ�O�����g
        segment2                  , -- ����Z�O�����g
        segment3                  , -- ����ȖڃZ�O�����g
        segment4                  , -- �⏕�ȖڃZ�O�����g
        segment5                  , -- �ڋq�Z�O�����g
        segment6                  , -- ��ƃZ�O�����g
        segment7                  , -- �\���P�Z�O�����g
        segment8                  , -- �\���Q�Z�O�����g
        attribute_category        , -- �d�󖾍׃J�e�S��
        creation_date             , -- �쐬��
        org_id                    ) -- �c�ƒP��ID
      VALUES(
        gv_gl_category_bm           , -- ������׃R���e�L�X�g
        lv_interface_line_attribute1, -- �������DFF1(�`�[�ԍ�)
        1                           , -- �������DFF2(���׍s�ԍ�)
        'REC'                       , -- ����Ȗڋ敪(�z���^�C�v)
        100                         , -- �p�[�Z���g(����)
        gv_aff1_company_code        , -- ��ЃZ�O�����g
        gv_aff2_dept_fin            , -- ����Z�O�����g
        gv_aff3_account_receivable  , -- ����ȖڃZ�O�����g
        gv_aff4_subacct_dummy       , -- �⏕�ȖڃZ�O�����g
        gv_aff5_customer_dummy      , -- �ڋq�Z�O�����g
        gv_aff6_company_dummy       , -- ��ƃZ�O�����g
        gv_aff7_preliminary1_dummy  , -- �\���P�Z�O�����g
        gv_aff8_preliminary2_dummy  , -- �\���Q�Z�O�����g
        gn_org_id                   , -- ����DFF�J�e�S��
        SYSDATE                     , -- �쐬��
        gn_org_id                   );-- �c�ƒP��ID
--
      gn_normal_cnt :=  gn_normal_cnt + 1;
--
    END IF;
--
    -- ============================================================
    -- �������l���Ώیڋq���X�V
    -- ============================================================
    UPDATE  xxcok_discounted_cust_inf xdci
    SET     xdci.last_closing_date  = xdci.next_closing_date
    WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END transfer_to_ar_p;
--
  /**********************************************************************************
   * Procedure Name   : get_target_cust_p
   * Description      : AR�A�W�Ώیڋq���o(A-6)
   ***********************************************************************************/
  PROCEDURE get_target_cust_p(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_target_cust_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- AR�A�W�Ώیڋq
    CURSOR l_target_cust_cur
    IS
      SELECT  xdci.ship_to_customer_code    ,
              xdci.ship_to_customer_id      ,
              xdci.ship_to_customer_site_id ,
              xdci.billing_customer_code    ,
              xdci.billing_customer_id      ,
              xdci.billing_customer_site_id ,
              xdci.next_closing_date        ,
              xdci.next_payment_term        
-- 2021/09/10 Ver1.3 MOD Start
--      FROM    xxcok_discounted_cust_inf   xdci
      FROM    xxcok_discounted_cust_inf   xdci,
              bom_calendar_dates          bcd2,
              bom_calendar_dates          bcd1
-- 2021/09/10 Ver1.3 MOD End
-- 2021/09/10 Ver1.3 MOD Start
--      WHERE   xdci.next_closing_date  + xdci.invoice_issue_cycle  <=  gd_process_date;
      WHERE   bcd1.calendar_code  =   'SALES_CAL'
      AND     bcd1.calendar_date  =   xdci.next_closing_date
      AND     bcd2.calendar_code  =   'SALES_CAL'
      AND     bcd2.seq_num        =   NVL(bcd1.seq_num,bcd1.prior_seq_num)  + xdci.invoice_issue_cycle
      AND     bcd2.calendar_date  <=  gd_process_date;
-- 2021/09/10 Ver1.3 MOD End
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- AR�A�W�Ώیڋq���o
    -- ============================================================
    FOR l_target_cust_rec IN  l_target_cust_cur LOOP
--
      -- ============================================================
      -- AR�A�W����(A-7)�̌Ăяo��
      -- ============================================================
      transfer_to_ar_p(
        ov_errbuf                   =>  lv_errbuf                                   -- �G���[�E���b�Z�[�W
      , ov_retcode                  =>  lv_retcode                                  -- ���^�[���E�R�[�h
      , ov_errmsg                   =>  lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_ship_to_customer_code    =>  l_target_cust_rec.ship_to_customer_code     -- �[�i��ڋq
      , in_ship_to_customer_id      =>  l_target_cust_rec.ship_to_customer_id       -- �[�i��ڋqID
      , in_ship_to_customer_site_id =>  l_target_cust_rec.ship_to_customer_site_id  -- �[�i��ڋq�T�C�gID
      , iv_billing_customer_code    =>  l_target_cust_rec.billing_customer_code     -- ������ڋq
      , in_billing_customer_id      =>  l_target_cust_rec.billing_customer_id       -- ������ڋqID
      , in_billing_customer_site_id =>  l_target_cust_rec.billing_customer_site_id  -- ������ڋq�T�C�gID
      , id_next_closing_date        =>  l_target_cust_rec.next_closing_date         -- �������
      , iv_next_payment_term        =>  l_target_cust_rec.next_payment_term         -- ����x������
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_target_cust_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : �̔��T���Ǘ����X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T���Ǘ����X�V
    -- ============================================================
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_deduction_id_ed, last_processing_id),
            last_updated_by         = cn_user_id                                        ,
            last_update_date        = SYSDATE                                           ,
            last_update_login       = cn_login_id                                       ,
            request_id              = cn_conc_request_id                                ,
            program_application_id  = cn_prog_appl_id                                   ,
            program_id              = cn_conc_program_id                                ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_n;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �O���[�o���ϐ��̏�����
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- ��������(A-1)�̌Ăяo��
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �̔��T����񒊏o(A-2)�̌Ăяo��
    -- ============================================================
    get_deduction_p(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �������l���Ώیڋq��񒊏o(A-4)�̌Ăяo��
    -- ============================================================
    get_cust_inf_p(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_warn  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- AR�A�W�Ώیڋq���o(A-6)�̌Ăяo��
    -- ============================================================
    get_target_cust_p(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �̔��T���Ǘ����X�V�̌Ăяo��
    -- ============================================================
    upd_control_p(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                    -- ���^�[���E�R�[�h
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�ϐ�
--
  BEGIN
--
    -- ============================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
--
    -- ============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ============================================================
    -- �G���[�o��
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- �o�͋敪
                      , lv_errmsg       -- ���b�Z�[�W
                      , 1               -- ���s
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- �o�͋敪
                      , lv_errbuf       -- ���b�Z�[�W
                      , 0               -- ���s
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- �Ώی����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- ���������o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �X�L�b�v�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �G���[�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 1                 -- ���s
                    );
--
    -- ============================================================
    -- �I�����b�Z�[�W
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A32C;
/
