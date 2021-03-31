CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A16C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A16C (body)
 * Description      : �T���z�̎x����ʂ����͂��ꂽ���F�ς̖≮�ւ̎x������
 *                  : AP�֘A�g���܂��B�܂��A���F��AP�ɘA�g�ς̎x���`�[��������ꂽ�ꍇ�A
 *                  : �ԓ`�[��AP�֘A�g���܂��B
 * MD.050           : �≮�T���x��AP�A�g MD050_COK_024_A16
 * Version          : 1.00
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.��������
 *  get_recon_header       A-2.�����w�b�_�[���擾
 *  get_recon_line         A-3.�������׏��擾
 *  ins_detail_data        A-4.���������דo�^����
 *  ins_header_data        A-5.�������w�b�_�[�o�^����
 *  update_recon_data      A-6.�����w�b�_�[�X�V����
 *  get_cancel_header      A-7.����w�b�_�[���擾
 *  get_cancel_line        A-8.������׏��擾
 *  ins_cancel_header      A-9.����w�b�_�[�o�^����
 *  ins_cancel_line        A-10.������דo�^����
 *  update_cabcel_data     A-11.����f�[�^�X�V
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/08/25    1.0   N.Abe            �V�K�쐬
 *
 *****************************************************************************************/
--
--###########################  �Œ�O���[�o���萔�錾�� START  ###########################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  �Œ�O���[�o���萔�錾�� END  ############################
--
--###########################  �Œ�O���[�o���ϐ��錾�� START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_c_target_cnt  NUMBER;                    -- �Ώی����i����j
  gn_c_normal_cnt  NUMBER;                    -- ���팏���i����j
--
--############################  �Œ�O���[�o���ϐ��錾�� END  ############################
--
--##############################  �Œ苤�ʗ�O�錾�� START  ##############################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A16C';                     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_msg_xxcok_00003     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_msg_xxcok_00028     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok_00034     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034';                 -- ����Ȗڏ��擾�G���[
  cv_msg_xxcok_00059     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00059';                 -- ��v���Ԏ擾�G���[
  cv_msg_xxcok_10632     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10632';                 -- ���b�N�G���[���b�Z�[�W
  cv_msg_xxccp_90000     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- �Ώی������b�Z�[�W
  cv_msg_xxccp_90001     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- �����������b�Z�[�W
  cv_msg_xxccp_90002     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- �G���[�������b�Z�[�W
  cv_msg_xxccp_90004     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_msg_xxccp_90006     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- �G���[�I���S���[���o�b�N
  cv_msg_xxcok_10714     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10714';                 -- ����Ώی���
  cv_msg_xxcok_10717     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10717';                 -- �����������
  cv_msg_xxcok_00032     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032';                 -- �x�������擾�G���[
  -- �g�[�N��
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- �v���t�@�C����
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- �������b�Z�[�W�p�g�[�N����
  -- �v���t�@�C��
  cv_prof_set_of_bks_id  CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_prof_org_id         CONSTANT VARCHAR2(6)  := 'ORG_ID';                           -- �c�ƒP��
  cv_prof_comp_code      CONSTANT VARCHAR2(24) := 'XXCOK1_AFF1_COMPANY_CODE';         -- ��ЃR�[�h
  cv_prof_dept_fin       CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_FIN';             -- ����R�[�h_�����o����
  cv_prof_payable        CONSTANT VARCHAR2(19) := 'XXCOK1_AFF3_PAYABLE';              -- ����Ȗ�_������
  cv_prof_sub_acct_dummy CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- �⏕�Ȗ�_�_�~�[�l
  cv_prof_cust_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- �ڋq�R�[�h_�_�~�[�l
  cv_prof_comp_dummy     CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- ��ƃR�[�h_�_�~�[�l
  cv_prof_pre1_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- �\���P_�_�~�[�l
  cv_prof_pre2_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- �\���Q_�_�~�[�l
  cv_prof_souce_dedu     CONSTANT VARCHAR2(26) := 'XXCOK1_INVOICE_SOURCE_DEDU';       -- �������\�[�X�i�̔��T���j
  -- �N�C�b�N�R�[�h
  cv_lkup_dedu_type      CONSTANT VARCHAR2(26) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- �T���f�[�^���
  cv_lkup_tax_conv       CONSTANT VARCHAR2(28) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- ����ŃR�[�h�ϊ��}�X�^
  cv_lkup_chain_code     CONSTANT VARCHAR2(16) := 'XXCMM_CHAIN_CODE';                 -- �`�F�[���X���
  -- ����
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- ����
  -- �����X�e�[�^�X
  cv_ad                  CONSTANT VARCHAR2(2)  := 'AD';                               -- ���F��
  cv_cd                  CONSTANT VARCHAR2(2)  := 'CD';                               -- �����
  -- �A�g��
  cv_wp                  CONSTANT VARCHAR2(2)  := 'WP';                               -- AP�≮
  -- ���׃^�C�v
  cv_item                CONSTANT VARCHAR2(4)  := 'ITEM';                             -- ���׃^�C�v�i���ׁj
  cv_tax                 CONSTANT VARCHAR2(3)  := 'TAX';                              -- ���׃^�C�v�i�Łj
  -- �ŃR�[�h
  cv_0000                CONSTANT VARCHAR2(4)  := '0000';                             -- �ŃR�[�h�i�_�~�[�j
  -- ����^�C�v
  cv_standard            CONSTANT VARCHAR2(8)  := 'STANDARD';                         -- ���z�i���j
  cv_credit              CONSTANT VARCHAR2(6)  := 'CREDIT';                           -- ���z�i���j
  -- �x������
  cv_99_99_99            CONSTANT VARCHAR2(9)  := '99_99_99';                         -- �x������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �T�������w�b�_���R�[�h�^��`
  TYPE g_recon_header_rtype IS RECORD(
       recon_slip_num           xxcok_deduction_recon_head.recon_slip_num%TYPE            -- �x���`�[�ԍ�
      ,recon_base_code          xxcok_deduction_recon_head.recon_base_code%TYPE           -- �x���������_
      ,applicant                xxcok_deduction_recon_head.applicant%TYPE                 -- �\����
      ,deduction_chain_code     xxcok_deduction_recon_head.deduction_chain_code%TYPE      -- �T���p�`�F�[���R�[�h
      ,recon_due_date           xxcok_deduction_recon_head.recon_due_date%TYPE            -- �x���\���
      ,gl_date                  xxcok_deduction_recon_head.gl_date%TYPE                   -- GL�L����
      ,invoice_date             xxcok_deduction_recon_head.invoice_date%TYPE              -- ���������t
      ,vendor_code              xxcok_deduction_recon_head.payee_code%TYPE                -- �d����R�[�h
      ,vendor_site_code         po_vendor_sites_all.vendor_site_code%TYPE                 -- �d����T�C�g�R�[�h
      ,header_id                xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- �T�������w�b�_�[ID
      ,terms_name               xxcok_deduction_recon_head.terms_name%TYPE                -- �x������
  );
  -- �T�������w�b�_���[�N�e�[�u���^��`
  TYPE g_recon_head_ttype    IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- �T�������w�b�_�e�[�u���^�ϐ�
  g_recon_head_tbl        g_recon_head_ttype;         -- �T�������w�b�_�擾
--
  -- �T���������׃��[�N�e�[�u����`
  TYPE g_recon_line_rtype IS RECORD(
       payment_amt              NUMBER                -- �x�����z
      ,remarks                  VARCHAR2(240)         -- �E�v
      ,tax_code                 VARCHAR2(150)         -- �ŃR�[�h
      ,line_type                VARCHAR2(4)           -- ���׃^�C�v
      ,dept_code                VARCHAR2(4)           -- ����R�[�h
      ,acct_code                VARCHAR2(150)         -- ����Ȗ�
      ,sub_acct_code            VARCHAR2(150)         -- �⏕�Ȗ�
      ,comp_code                VARCHAR2(150)         -- ��ƃR�[�h
      ,cust_code                VARCHAR2(150)         -- �ڋq�R�[�h
      ,ccid                     NUMBER                -- CCID
  );
  -- �������׏�񃏁[�N�e�[�u���^��`
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- �������׏��e�[�u���^�ϐ�
  g_recon_line_tbl        g_recon_line_ttype;         -- �������׏��擾
--
  -- ����w�b�_���R�[�h�^��`
  TYPE g_cancel_header_rtype IS RECORD(
       invoice_id               ap_invoices_all.invoice_id%TYPE                           -- ������ID
      ,type_code                ap_invoices_all.invoice_type_lookup_code%TYPE             -- ����^�C�v
      ,invoice_date             ap_invoices_all.invoice_date%TYPE                         -- ���������t
      ,vendor_id                ap_invoices_all.vendor_id%TYPE                            -- �d����ID
      ,vendor_site_id           ap_invoices_all.vendor_site_id%TYPE                       -- �d����T�C�gID
      ,invoice_amount           ap_invoices_all.invoice_amount%TYPE                       -- �������z
      ,terms_id                 ap_invoices_all.terms_id%TYPE                             -- �x������ID
      ,description              ap_invoices_all.description%TYPE                          -- �E�v
      ,attribute_category       ap_invoices_all.attribute_category%TYPE                   -- DFF�R���e�L�X�g
      ,attribute2               ap_invoices_all.attribute2%TYPE                           -- �������ԍ�
      ,attribute3               ap_invoices_all.attribute3%TYPE                           -- �N�[����
      ,attribute4               ap_invoices_all.attribute4%TYPE                           -- �`�[���͎�
      ,source                   ap_invoices_all.source%TYPE                               -- �������\�[�X
      ,gl_date                  ap_invoices_all.gl_date%TYPE                              -- �d��v���
      ,ccid                     ap_invoices_all.accts_pay_code_combination_id%TYPE        -- ������CCID
      ,org_id                   ap_invoices_all.org_id%TYPE                               -- �g�DID
      ,terms_date               ap_invoices_all.terms_date%TYPE                           -- �x���N�Z��
      ,header_id                xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- �T�������w�b�_�[ID
  );
  -- ����w�b�_���[�N�e�[�u���^��`
  TYPE g_cancel_head_ttype    IS TABLE OF g_cancel_header_rtype INDEX BY BINARY_INTEGER;
  -- ����w�b�_�e�[�u���^�ϐ�
  g_cancel_head_tbl        g_cancel_head_ttype;         -- ����w�b�_�擾
--
  -- ������׃��[�N�e�[�u����`
  TYPE g_cancel_line_rtype IS RECORD(
       line_num                 ap_invoice_distributions_all.distribution_line_number%TYPE  -- ���הԍ�
      ,line_type                ap_invoice_distributions_all.line_type_lookup_code%TYPE     -- ���׃^�C�v
      ,amount                   ap_invoice_distributions_all.amount%TYPE                    -- ���׋��z
      ,description              ap_invoice_distributions_all.description%TYPE               -- �E�v
      ,tax_code                 ap_tax_codes_all.name%TYPE                                  -- �ŋ敪
      ,ccid                     ap_invoice_distributions_all.dist_code_combination_id%TYPE  -- CCID
  );
  -- ������׏�񃏁[�N�e�[�u���^��`
  TYPE g_cancel_line_ttype    IS TABLE OF g_cancel_line_rtype INDEX BY BINARY_INTEGER;
  -- ������׏��e�[�u���^�ϐ�
  g_cancel_line_tbl        g_cancel_line_ttype;         -- ������׏��擾

  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gd_process_date             DATE;                                                   -- �Ɩ��������
  gn_set_bks_id               NUMBER;                                                 -- ��v����ID
  gn_org_id                   NUMBER;                                                 -- �c�ƒP��
  gv_comp_code                VARCHAR2(40);                                           -- ��ЃR�[�h
  gv_dept_fin                 VARCHAR2(40);                                           -- ����R�[�h_�����o����
  gv_payable                  VARCHAR2(40);                                           -- ����Ȗ�_������
  gv_asst_dummy               VARCHAR2(40);                                           -- �⏕�Ȗ�_�_�~�[�l
  gv_cust_dummy               VARCHAR2(40);                                           -- �ڋq�R�[�h_�_�~�[�l
  gv_comp_dummy               VARCHAR2(40);                                           -- ��ƃR�[�h_�_�~�[�l
  gv_pre1_dummy               VARCHAR2(40);                                           -- �\���P_�_�~�[�l
  gv_pre2_dummy               VARCHAR2(40);                                           -- �\���Q_�_�~�[�l
  gv_source_dedu              VARCHAR2(40);                                           -- �������\�[�X�i�̔��T���j
  gn_invoice_id               NUMBER;                                                 -- ������ID
  gn_debt_acct_ccid           NUMBER;                                                 -- CCID�i�w�b�_�j
  gn_detail_ccid              NUMBER;                                                 -- CCID�i���ׁj
  --
  gn_head_cnt                 NUMBER  DEFAULT 1;                                      -- �����w�b�_�[�p�J�E���^
  gn_line_cnt                 NUMBER  DEFAULT 1;                                      -- �������חp�J�E���^
  gn_c_head_cnt               NUMBER  DEFAULT 1;                                      -- ����w�b�_�[�p�J�E���^
  gn_c_line_cnt               NUMBER  DEFAULT 1;                                      -- �������חp�J�E���^
  --
  gn_invoice_amount           NUMBER  DEFAULT 0;                                      -- ���׋��z�W�v�p
  gn_detail_num               NUMBER  DEFAULT 1;                                      -- �A�ԁi���ׁj
  gv_bk_slip_num              xxcok_deduction_recon_head.recon_slip_num%TYPE;         -- �`�[�ԍ���r�p
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W            --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h              --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    gd_acct_period    DATE;   -- ��v����
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ==============================================================
    -- 1.�Ɩ��������t�擾
    -- ==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00028
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 2.�v���t�@�C���̎擾
    -- ==============================================================
    -- ��v����ID
    gn_set_bks_id := FND_PROFILE.VALUE( cv_prof_set_of_bks_id );
--
    IF ( gn_set_bks_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �c�ƒP��
    gn_org_id := FND_PROFILE.VALUE( cv_prof_org_id );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ЃR�[�h
    gv_comp_code := FND_PROFILE.VALUE( cv_prof_comp_code );
--
    IF ( gv_comp_code IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_comp_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����R�[�h_�����o����
    gv_dept_fin := FND_PROFILE.VALUE( cv_prof_dept_fin );
--
    IF ( gv_dept_fin IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_������
    gv_payable := FND_PROFILE.VALUE( cv_prof_payable );
--
    IF ( gv_payable IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_payable
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�_�~�[�l
    gv_asst_dummy := FND_PROFILE.VALUE( cv_prof_sub_acct_dummy );
--
    IF ( gv_asst_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_sub_acct_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ڋq�R�[�h_�_�~�[�l
    gv_cust_dummy := FND_PROFILE.VALUE( cv_prof_cust_dummy );
--
    IF ( gv_cust_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_cust_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ƃR�[�h_�_�~�[�l
    gv_comp_dummy := FND_PROFILE.VALUE( cv_prof_comp_dummy );
--
    IF ( gv_comp_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_comp_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���P_�_�~�[�l
    gv_pre1_dummy := FND_PROFILE.VALUE( cv_prof_pre1_dummy );
--
    IF ( gv_pre1_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_pre1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���Q_�_�~�[�l
    gv_pre2_dummy := FND_PROFILE.VALUE( cv_prof_pre2_dummy );
--
    IF ( gv_pre2_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_pre2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �������\�[�X�i�̔��T���j
    gv_source_dedu := FND_PROFILE.VALUE( cv_prof_souce_dedu );
--
    IF ( gv_source_dedu IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_souce_dedu
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 3.�I�[�v��GL��v���Ԃ̎擾
    -- ==============================================================
    BEGIN
      SELECT MIN( gps.end_date ) AS acct_period
      INTO   gd_acct_period
      FROM   gl_period_statuses   gps
            ,fnd_application      fa
      WHERE  fa.application_short_name  = 'SQLGL'
      AND    gps.application_id         = fa.application_id
      AND    gps.adjustment_period_flag = 'N'
      AND    gps.closing_status         = 'O'
      AND    gps.set_of_books_id        = gn_set_bks_id
      ;
--
      IF ( gd_acct_period IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00059
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00059
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ==============================================================
    -- 4.������Ȗ�CCID�擾
    -- ==============================================================
    gn_debt_acct_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date   -- ������
                       ,iv_segment1  => gv_comp_code      -- ��ЃR�[�h
                       ,iv_segment2  => gv_dept_fin       -- ����R�[�h
                       ,iv_segment3  => gv_payable        -- ����ȖڃR�[�h
                       ,iv_segment4  => gv_asst_dummy     -- �⏕�ȖڃR�[�h
                       ,iv_segment5  => gv_cust_dummy     -- �ڋq�R�[�h
                       ,iv_segment6  => gv_comp_dummy     -- ��ƃR�[�h
                       ,iv_segment7  => gv_pre1_dummy     -- �\���P�R�[�h
                       ,iv_segment8  => gv_pre2_dummy     -- �\���Q�R�[�h
                      );
--
    IF ( gn_debt_acct_ccid IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00034
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_header
   * Description      : A-2.�����w�b�_�[���擾
   ***********************************************************************************/
  PROCEDURE get_recon_header(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_header';                                 -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
    -- *** ���[�J���E�J�[�\�� ***
    -- �T�������w�b�_���o�J�[�\��
    CURSOR recon_head_cur
    IS
      SELECT /*+ index(xdrh xxcok_deduction_recon_head_n01) */
             xdrh.recon_slip_num           AS recon_slip_num          -- �x���`�[�ԍ�
            ,xdrh.recon_base_code          AS recon_base_code         -- �x���������_
            ,fu.user_name                  AS applicant               -- �\����
            ,xdrh.deduction_chain_code     AS deduction_chain_code    -- �T���p�`�F�[���R�[�h
            ,xdrh.recon_due_date           AS recon_due_date          -- �x���\���
            ,xdrh.gl_date                  AS gl_date                 -- GL�L����
            ,xdrh.invoice_date             AS invoice_date            -- ���������t
            ,pv.segment1                   AS vendor_code             -- �d����
            ,pvsa.vendor_site_code         AS vendor_site_code        -- �d����T�C�g
            ,xdrh.deduction_recon_head_id  AS header_id               -- �T�������w�b�_�[ID
            ,xdrh.terms_name               AS terms_name              -- �x������
      FROM   xxcok_deduction_recon_head    xdrh                       -- �T�������w�b�_�[���
            ,po_vendor_sites_all           pvsa                       -- �d����T�C�g
            ,po_vendors                    pv                         -- �d����
            ,fnd_user                      fu                         -- ���[�U�[�}�X�^
            ,per_all_people_f              papf                       -- �]�ƈ��}�X�^
      WHERE  xdrh.recon_status             =        cv_ad             -- ���F��
      AND    xdrh.interface_div            =        cv_wp             -- AP�≮
      AND    xdrh.ap_ar_if_flag            =        'N'               -- ���A�g
      AND    pv.segment1(+)                =        xdrh.payee_code
      AND    pvsa.vendor_id(+)             =        pv.vendor_id
      AND    pvsa.org_id(+)                =        gn_org_id
      AND    xdrh.applicant                =        papf.employee_number(+)
      AND    papf.person_id                =        fu.employee_id(+)
      AND    TRUNC(gd_process_date)        BETWEEN  TRUNC(papf.effective_start_date(+))
                                           AND      TRUNC(NVL(papf.effective_end_date(+), gd_process_date))
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
      ;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 1.�����Ώۏ����w�b�_���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  recon_head_cur;
    -- �f�[�^�擾
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_head_cur;
    -- �擾�����`�[����Ώی����Ɋi�[
    gn_target_cnt := g_recon_head_tbl.COUNT;        -- �Ώی���
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                 ,cv_msg_xxcok_10632
                                                 );
      --
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ END  #################################
--
  END get_recon_header;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_line
   * Description      : A-3.�������׏��擾
   ***********************************************************************************/
  PROCEDURE get_recon_line(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_line';          -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �������׏��擾�J�[�\��
    CURSOR recon_line_cur
    IS
      -- �T��No�ʏ������_�{��
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              xdnr.payment_amt  AS  payment_amt     -- �x���z
             ,xdnr.remarks      AS  remarks         -- �E�v
             ,cv_0000           AS  tax_code        -- �ŃR�[�h
             ,cv_item           AS  line_type       -- ���׃^�C�v 
             ,gv_dept_fin       AS  dept_code       -- ����R�[�h
             ,flv.attribute6    AS  acct_code       -- ����Ȗ�
             ,flv.attribute7    AS  sub_acct_code   -- �⏕�Ȗ�
             ,gv_comp_dummy     AS  comp_code       -- ��ƃR�[�h
             ,gv_cust_dummy     AS  cust_code       -- �ڋq�R�[�h
             ,NULL              AS  ccid            -- ccid
      FROM    xxcok_deduction_num_recon   xdnr  -- �T��No�ʏ������
             ,fnd_lookup_values           flv   -- �f�[�^���
      WHERE   xdnr.recon_slip_num = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag    = 'Y'
      AND     flv.lookup_type     = cv_lkup_dedu_type
      AND     flv.lookup_code     = xdnr.data_type
      AND     flv.language        = cv_lang
      AND     flv.enabled_flag    = 'Y'
      UNION ALL
      -- �T��No�ʏ������_��
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              SUM(xdnr.payment_tax) AS  payment_amt     -- �x���z
             ,atca.name             AS  remarks         -- �E�v
             ,cv_0000               AS  tax_code        -- �ŃR�[�h
             ,cv_item               AS  line_type       -- ���׃^�C�v 
             ,gv_dept_fin           AS  dept_code       -- ����R�[�h
             ,atca.attribute5       AS  acct_code       -- ����Ȗ�
             ,atca.attribute6       AS  sub_acct_code   -- �⏕�Ȗ�
             ,gv_comp_dummy         AS  comp_code       -- ��ƃR�[�h
             ,gv_cust_dummy         AS  cust_code       -- �ڋq�R�[�h
             ,NULL                  AS  ccid            -- ccid
      FROM    xxcok_deduction_num_recon   xdnr  -- �T��No�ʏ������
             ,ap_tax_codes_all            atca  -- AP�ŃR�[�h�}�X�^
             ,fnd_lookup_values           flv   -- �ŃR�[�h�ϊ��}�X�^
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xdnr.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      GROUP BY atca.name
              ,atca.attribute5
              ,atca.attribute6
      UNION ALL
      -- �̔��T�����_�{��
      SELECT  /*+ index(xsd xxcok_sales_deduction_n05) */
              SUM(xsd.deduction_amount) AS  payment_amt     -- �x���z
             ,flv.meaning               AS  remarks         -- �E�v
             ,cv_0000                   AS  tax_code        -- �ŃR�[�h
             ,cv_item                   AS  line_type       -- ���׃^�C�v 
             ,gv_dept_fin               AS  dept_code       -- ����R�[�h
             ,flv.attribute6            AS  acct_code       -- ����Ȗ�
             ,flv.attribute7            AS  sub_acct_code   -- �⏕�Ȗ�
             ,gv_comp_dummy             AS  comp_code       -- ��ƃR�[�h
             ,gv_cust_dummy             AS  cust_code       -- �ڋq�R�[�h
             ,NULL                      AS  ccid            -- ccid
      FROM    xxcok_sales_deduction       xsd   -- �̔��T�����
             ,fnd_lookup_values           flv   -- �f�[�^���
      WHERE   xsd.recon_slip_num    = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_dedu_type
      AND     flv.lookup_code       = xsd.data_type
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     flv.attribute2       IN ('030', '040')
      GROUP BY xsd.data_type
              ,flv.meaning
              ,flv.attribute6
              ,flv.attribute7
      UNION ALL
      -- �̔��T�����_��
      SELECT  /*+ index(xsd xxcok_sales_deduction_n05) */
              SUM(xsd.deduction_tax_amount) AS  payment_amt     -- �x���z
             ,atca.name                     AS  remarks         -- �E�v
             ,cv_0000                       AS  tax_code        -- �ŃR�[�h
             ,cv_item                       AS  line_type       -- ���׃^�C�v 
             ,gv_dept_fin                   AS  dept_code       -- ����R�[�h
             ,atca.attribute5               AS  acct_code       -- ����Ȗ�
             ,atca.attribute6               AS  sub_acct_code   -- �⏕�Ȗ�
             ,gv_comp_dummy                 AS  comp_code       -- ��ƃR�[�h
             ,gv_cust_dummy                 AS  cust_code       -- �ڋq�R�[�h
             ,NULL                          AS  ccid            -- ccid
      FROM    xxcok_sales_deduction       xsd   -- �̔��T�����
             ,ap_tax_codes_all            atca  -- AP�ŃR�[�h�}�X�^
             ,fnd_lookup_values           flv   -- �ŃR�[�h�ϊ��}�X�^
             ,fnd_lookup_values           flv2  -- �f�[�^���
      WHERE   xsd.recon_slip_num    = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xsd.recon_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      AND     flv2.lookup_type      = cv_lkup_dedu_type
      AND     flv2.lookup_code      = xsd.data_type
      AND     flv2.language         = cv_lang
      AND     flv2.enabled_flag     = 'Y'
      AND     flv2.attribute2      IN ('030', '040')
      GROUP BY atca.name
              ,atca.attribute5
              ,atca.attribute6
      UNION ALL
      -- �Ȗڎx�����_�{��
      SELECT  /*+ index(xapi xxcok_account_payment_info_n01) */
              xapi.payment_amt                    AS  payment_amt     -- �x���z
             ,xapi.remarks                        AS  remarks         -- �E�v
             ,flv.attribute1                      AS  tax_code        -- �ŃR�[�h
             ,cv_item                             AS  line_type       -- ���׃^�C�v 
             ,xapi.base_code                      AS  dept_code       -- ����R�[�h
             ,xapi.acct_code                      AS  acct_code       -- ����Ȗ�
             ,xapi.sub_acct_code                  AS  sub_acct_code   -- �⏕�Ȗ�
             ,NVL(flv2.attribute1, gv_comp_dummy) AS  comp_code       -- ��ƃR�[�h
             ,NVL(flv2.attribute4, gv_cust_dummy) AS  cust_code       -- �ڋq�R�[�h
             ,NULL                                AS  ccid            -- ccid
      FROM    xxcok_account_payment_info  xapi  -- �Ȗڎx�����
             ,fnd_lookup_values           flv   -- �ŃR�[�h�ϊ��}�X�^
             ,fnd_lookup_values           flv2  -- �`�F�[���X���
      WHERE   xapi.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xapi.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     flv2.lookup_type(+)   = cv_lkup_chain_code
      AND     flv2.lookup_code(+)   = xapi.deduction_chain_code
      AND     flv2.language(+)      = cv_lang
      AND     flv2.enabled_flag(+)  = 'Y'
      UNION ALL
      -- �Ȗڎx�����_��
      SELECT  /*+ index(xapi xxcok_account_payment_info_n01) */
              xapi.payment_tax              AS  payment_amt     -- �x���z
             ,xapi.remarks                  AS  remarks         -- �E�v
             ,flv.attribute1                AS  tax_code        -- �ŃR�[�h
             ,cv_tax                        AS  line_type       -- ���׃^�C�v 
             ,xapi.base_code                AS  dept_code       -- ����R�[�h
             ,NULL                          AS  acct_code       -- ����Ȗ�
             ,NULL                          AS  sub_acct_code   -- �⏕�Ȗ�
             ,NULL                          AS  comp_code       -- ��ƃR�[�h
             ,NULL                          AS  cust_code       -- �ڋq�R�[�h
             ,atca.tax_code_combination_id  AS  ccid            -- ccid
      FROM    xxcok_account_payment_info  xapi  -- �Ȗڎx�����
             ,ap_tax_codes_all            atca  -- AP�ŃR�[�h�}�X�^
             ,fnd_lookup_values           flv   -- �ŃR�[�h�ϊ��}�X�^
      WHERE   xapi.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xapi.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
    ;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- �������׏��̎擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  recon_line_cur;
    -- �f�[�^�擾
    FETCH recon_line_cur BULK COLLECT INTO g_recon_line_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_line_cur;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
--
  END get_recon_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_data
   * Description      : A-4.���������דo�^����
   ***********************************************************************************/
  PROCEDURE ins_detail_data(
                      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_data';              -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\��***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 4-1.������ID�擾
    -- ============================================================
    -- �O��`�[�ԍ���NULL���́A�O��ƈႤ�ꍇ�擾
    IF    ( gv_bk_slip_num IS NULL )
      OR  ( g_recon_head_tbl(gn_head_cnt).recon_slip_num <> gv_bk_slip_num ) 
    THEN
      -- ��r�p�ϐ��Ɋi�[
      gv_bk_slip_num := g_recon_head_tbl(gn_head_cnt).recon_slip_num;
--
      -- �V�[�P���X���琿����ID���擾
      SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    END IF;
--
    -- ============================================================
    -- 4-2.CCID�擾
    -- ============================================================
    -- ���ׂ���擾����CCID���ݒ肳��Ă���ꍇ�́A�擾���Ȃ�
    IF ( g_recon_line_tbl(gn_line_cnt).ccid IS NULL ) THEN
      gn_detail_ccid := xxcok_common_pkg.get_code_combination_id_f(
                          id_proc_date => gd_process_date                             -- ������
                        , iv_segment1  => gv_comp_code                                -- ��ЃR�[�h
                        , iv_segment2  => g_recon_line_tbl(gn_line_cnt).dept_code     -- ����R�[�h
                        , iv_segment3  => g_recon_line_tbl(gn_line_cnt).acct_code     -- ����ȖڃR�[�h
                        , iv_segment4  => g_recon_line_tbl(gn_line_cnt).sub_acct_code -- �⏕�ȖڃR�[�h
                        , iv_segment5  => g_recon_line_tbl(gn_line_cnt).cust_code     -- �ڋq�R�[�h
                        , iv_segment6  => g_recon_line_tbl(gn_line_cnt).comp_code     -- ��ƃR�[�h
                        , iv_segment7  => gv_pre1_dummy                               -- �\���P�R�[�h
                        , iv_segment8  => gv_pre2_dummy                            -- �\���Q�R�[�h
                        );
      IF ( gn_detail_ccid IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00034
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================================
    -- 4-4.����������OIF�o�^
    -- ============================================================
    INSERT INTO ap_invoice_lines_interface(
      invoice_id                                        -- ������ID
    , invoice_line_id                                   -- ����������ID
    , line_number                                       -- ���׍s�ԍ�
    , line_type_lookup_code                             -- ���׃^�C�v
    , amount                                            -- ���׋��z
    , description                                       -- �E�v
    , tax_code                                          -- �ŋ敪
    , dist_code_combination_id                          -- CCID
    , last_updated_by                                   -- �ŏI�X�V��
    , last_update_date                                  -- �ŏI�X�V��
    , last_update_login                                 -- �ŏI���O�C��ID
    , created_by                                        -- �쐬��
    , creation_date                                     -- �쐬��
    , attribute_category                                -- DFF�R���e�L�X�g
    , org_id                                            -- �g�DID
    )
    VALUES (
      gn_invoice_id                                             -- ������ID
    , ap_invoice_lines_interface_s.NEXTVAL                      -- ����������ID
    , gn_detail_num                                             -- ���׍s�ԍ�
    , g_recon_line_tbl(gn_line_cnt).line_type                   -- ���׃^�C�v
    , g_recon_line_tbl(gn_line_cnt).payment_amt                 -- ���׋��z
    , g_recon_line_tbl(gn_line_cnt).remarks                     -- �E�v
    , g_recon_line_tbl(gn_line_cnt).tax_code                    -- �ŋ敪
    , NVL( g_recon_line_tbl(gn_line_cnt).ccid, gn_detail_ccid ) -- CCID
    , cn_last_updated_by                                        -- �ŏI�X�V��
    , SYSDATE                                                   -- �ŏI�X�V��
    , cn_last_update_login                                      -- �ŏI���O�C��ID
    , cn_created_by                                             -- �쐬��
    , SYSDATE                                                   -- �쐬��
    , gn_org_id                                                 -- DFF�R���e�L�X�g
    , gn_org_id                                                 -- �g�DID
    );
    -- �w�b�_�[�p�ɋ��z���W�v����
    gn_invoice_amount := gn_invoice_amount + g_recon_line_tbl(gn_line_cnt).payment_amt;
    -- �A�Ԃ��J�E���g�A�b�v
    gn_detail_num := gn_detail_num + 1;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_header_data
   * Description      : A-5.�������w�b�_�[�o�^����
   ***********************************************************************************/
  PROCEDURE ins_header_data(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_header_data';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_attribute1   ap_terms_v.attribute1%TYPE;
    lt_term_id     ap_terms_v.term_id%TYPE;
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 5-1.�x���������擾
    -- ============================================================
    BEGIN
      SELECT atv.attribute1   AS  attribute1
            ,atv.term_id      AS  term_id
      INTO   lt_attribute1
            ,lt_term_id
      FROM   ap_terms_v   atv
      WHERE  atv.name = g_recon_head_tbl(gn_head_cnt).terms_name
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00032
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF    ( lt_attribute1 IS NULL )
      OR  ( lt_term_id  IS NULL )
    THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00032
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 5-2.�������w�b�_�[�o�^
    -- ============================================================
--
    INSERT INTO ap_invoices_interface (
      invoice_id                              -- ������ID
    , invoice_num                             -- �������ԍ�
    , invoice_type_lookup_code                -- ����^�C�v
    , invoice_date                            -- �������t
    , vendor_num                              -- �d����R�[�h
    , vendor_site_code                        -- �d����T�C�g�R�[�h
    , invoice_amount                          -- �������z
    , terms_id                                -- �x������ID
    , description                             -- �E�v
    , last_update_date                        -- �ŏI�X�V��
    , last_updated_by                         -- �ŏI�X�V��
    , last_update_login                       -- �ŏI���O�C��ID
    , creation_date                           -- �쐬��
    , created_by                              -- �쐬��
    , attribute_category                      -- DFF�R���e�L�X�g
    , attribute2                              -- �������ԍ�
    , attribute3                              -- �N�[����
    , attribute4                              -- �`�[���͎�
    , source                                  -- �\�[�X
    , gl_date                                 -- �d��v���
    , accts_pay_code_combination_id           -- ������CCID
    , org_id                                  -- �g�DID
    , terms_date                              -- �x���N�Z��
    )
    VALUES (
      gn_invoice_id                                     -- ������ID
    , xxcok_common_pkg.get_slip_number_f( cv_pkg_name ) -- �������ԍ�
    , CASE
        WHEN gn_invoice_amount >= 0 THEN
          cv_standard
        WHEN gn_invoice_amount < 0 THEN
          cv_credit
      END                                               -- ����^�C�v
    , g_recon_head_tbl(gn_head_cnt).invoice_date        -- �Ɩ��������t
    , g_recon_head_tbl(gn_head_cnt).vendor_code         -- �d����R�[�h()
    , g_recon_head_tbl(gn_head_cnt).vendor_site_code    -- �d����T�C�g�R�[�h
    , gn_invoice_amount                                 -- �������z
    , lt_term_id                                        -- �x������ID
    , gv_source_dedu                                    -- �E�v
    , SYSDATE                                           -- �ŏI�X�V��
    , cn_last_updated_by                                -- �ŏI�X�V��
    , cn_last_update_login                              -- �ŏI���O�C��ID
    , SYSDATE                                           -- �쐬��
    , cn_created_by                                     -- �쐬��
    , gn_org_id                                         -- �g�DID
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- �������ԍ�
    , g_recon_head_tbl(gn_head_cnt).recon_base_code     -- �N�[����
    , g_recon_head_tbl(gn_head_cnt).applicant           -- �`�[���͎�
    , gv_source_dedu                                    -- �������\�[�X
    , g_recon_head_tbl(gn_head_cnt).gl_date             -- �d��v���
    , gn_debt_acct_ccid                                 -- ������Ȗ�CCID
    , gn_org_id                                         -- �g�DID
    , CASE
        WHEN lt_attribute1 = 'Y' THEN
          g_recon_head_tbl(gn_head_cnt).recon_due_date
        WHEN lt_attribute1 = 'N' THEN
          g_recon_head_tbl(gn_head_cnt).invoice_date
      END                                               -- �x���N�Z��
    );
--
    --���팏�����J�E���g�A�b�v
    gn_normal_cnt := gn_normal_cnt + 1;
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END ins_header_data;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_data
   * Description      : A-6.�����f�[�^�X�V
   ***********************************************************************************/
  PROCEDURE update_recon_data(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_data';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 6-1.�����w�b�_�[�X�V
    -- ============================================================
    UPDATE xxcok_deduction_recon_head
    SET    ap_ar_if_flag            = 'Y'
          ,last_updated_by          = cn_last_updated_by
          ,last_update_date         = SYSDATE
          ,last_update_login        = cn_last_update_login
          ,request_id               = cn_request_id
          ,program_application_id   = cn_program_application_id
          ,program_id               = cn_program_id
          ,program_update_date      = SYSDATE
    WHERE  deduction_recon_head_id  = g_recon_head_tbl(gn_head_cnt).header_id
    ;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END update_recon_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cancel_header
   * Description      : A-7.����w�b�_�[���擾
   ***********************************************************************************/
  PROCEDURE get_cancel_header(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_header';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �T�������w�b�_���o�J�[�\��
    CURSOR cancel_head_cur
    IS
      SELECT /*+ index(xdrh xxcok_deduction_recon_head_n02) */
             aia.invoice_id                     AS invoice_id         -- ������ID
            ,aia.invoice_type_lookup_code       AS type_code          -- ����^�C�v
            ,aia.invoice_date                   AS invoice_date       -- ���������t
            ,aia.vendor_id                      AS vendor_id          -- �d����ID
            ,aia.vendor_site_id                 AS vendor_site_id     -- �d����T�C�gID
            ,aia.invoice_amount * -1            AS invoice_amount     -- �������z
            ,aia.terms_id                       AS terms_id           -- �x������ID
            ,aia.description                    AS description        -- �E�v
            ,aia.attribute_category             AS attribute_category -- DFF�R���e�L�X�g
            ,aia.attribute2                     AS attribute2         -- �������ԍ�
            ,aia.attribute3                     AS attribute3         -- �N�[����
            ,aia.attribute4                     AS attribute4         -- �`�[���͎�
            ,aia.source                         AS source             -- �������\�[�X
            ,aia.gl_date                        AS gl_date            -- �d��v���
            ,aia.accts_pay_code_combination_id  AS ccid               -- ������CCID
            ,aia.org_id                         AS org_id             -- �g�DID
            ,aia.terms_date                     AS terms_date         -- �x���N�Z��
            ,xdrh.deduction_recon_head_id       AS header_id          -- �T�������w�b�_�[ID
      FROM   xxcok_deduction_recon_head    xdrh                       -- �T�������w�b�_�[���
            ,ap_invoices_all               aia                        -- �������w�b�_�[
      WHERE  xdrh.recon_status             = cv_cd                    -- �����
      AND    xdrh.interface_div            = cv_wp                    -- AP�≮
      AND    xdrh.ap_ar_if_flag            = 'Y'                      -- �A�g��
      AND    aia.gl_date                   = xdrh.gl_date             -- �d��v���
      AND    aia.set_of_books_id           = gn_set_bks_id            -- ��v����ID
      AND    aia.attribute2                = xdrh.recon_slip_num      -- �`�[�ԍ�
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 1.����w�b�_���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  cancel_head_cur;
    -- �f�[�^�擾
    FETCH cancel_head_cur BULK COLLECT INTO g_cancel_head_tbl;
    -- �J�[�\���N���[�Y
    CLOSE cancel_head_cur;
--
    -- �擾�����������Ώی���(����j�Ɋi�[
    gn_c_target_cnt := g_cancel_head_tbl.COUNT;        -- �Ώی����i����j
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                 ,cv_msg_xxcok_10632
                                                 );
      --
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END get_cancel_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cancel_line
   * Description      : A-8.������׏��擾
   ***********************************************************************************/
  PROCEDURE get_cancel_line(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_line';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ������ג��o�J�[�\��
    CURSOR cancel_line_cur
    IS
      SELECT apda.distribution_line_number      AS line_num           -- ���הԍ�
            ,apda.line_type_lookup_code         AS line_type          -- ���׃^�C�v
            ,apda.amount * -1                   AS amount             -- ���׋��z
            ,apda.description                   AS description        -- �E�v
            ,atca.name                          AS tax_code           -- �ŋ敪
            ,apda.dist_code_combination_id      AS ccid               -- CCID
      FROM   ap_invoice_distributions_all   apda                      -- �������z�z
            ,ap_tax_codes_all               atca                      -- AP�ŃR�[�h�}�X�^
      WHERE  apda.invoice_id            = g_cancel_head_tbl(gn_c_head_cnt).invoice_id
      AND    apda.tax_code_id           = atca.tax_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 1.������׏��擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  cancel_line_cur;
    -- �f�[�^�擾
    FETCH cancel_line_cur BULK COLLECT INTO g_cancel_line_tbl;
    -- �J�[�\���N���[�Y
    CLOSE cancel_line_cur;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END get_cancel_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_cancel_header
   * Description      : A-9.����w�b�_�[�o�^����
   ***********************************************************************************/
  PROCEDURE ins_cancel_header(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cancel_header';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 9-1.������ID�擾�i����j
    -- ============================================================
    SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    -- ============================================================
    -- 9-1.����w�b�_�[�o�^
    -- ============================================================
--
    INSERT INTO ap_invoices_interface (
      invoice_id                              -- ������ID
    , invoice_num                             -- �������ԍ�
    , invoice_type_lookup_code                -- ����^�C�v
    , invoice_date                            -- �������t
    , vendor_id                               -- �d����ID
    , vendor_site_id                          -- �d����T�C�gID
    , invoice_amount                          -- �������z
    , terms_id                                -- �x������ID
    , description                             -- �E�v
    , last_update_date                        -- �ŏI�X�V��
    , last_updated_by                         -- �ŏI�X�V��
    , last_update_login                       -- �ŏI���O�C��ID
    , creation_date                           -- �쐬��
    , created_by                              -- �쐬��
    , attribute_category                      -- DFF�R���e�L�X�g
    , attribute2                              -- �������ԍ�
    , attribute3                              -- �N�[����
    , attribute4                              -- �`�[���͎�
    , source                                  -- �\�[�X
    , gl_date                                 -- �d��v���
    , accts_pay_code_combination_id           -- ������CCID
    , org_id                                  -- �g�DID
    , terms_date                              -- �x���N�Z��
    )
    VALUES (
      gn_invoice_id                                                       -- ������ID
    , xxcok_common_pkg.get_slip_number_f( cv_pkg_name )                   -- �������ԍ�
    , CASE
        WHEN g_cancel_head_tbl(gn_c_head_cnt).invoice_amount >= 0 THEN
          cv_standard
        WHEN g_cancel_head_tbl(gn_c_head_cnt).invoice_amount  < 0 THEN
          cv_credit
      END                                                                 -- ����^�C�v
    , g_cancel_head_tbl(gn_c_head_cnt).invoice_date                       -- �Ɩ��������t
    , g_cancel_head_tbl(gn_c_head_cnt).vendor_id                          -- �d����ID
    , g_cancel_head_tbl(gn_c_head_cnt).vendor_site_ID                     -- �d����T�C�gID
    , g_cancel_head_tbl(gn_c_head_cnt).invoice_amount                     -- �������z
      , g_cancel_head_tbl(gn_c_head_cnt).terms_id                           -- �x������ID
    , g_cancel_head_tbl(gn_c_head_cnt).description                        -- �E�v
    , SYSDATE                                                             -- �ŏI�X�V��
    , cn_last_updated_by                                                  -- �ŏI�X�V��
    , cn_last_update_login                                                -- �ŏI���O�C��ID
    , SYSDATE                                                             -- �쐬��
    , cn_created_by                                                       -- �쐬��
    , g_cancel_head_tbl(gn_c_head_cnt).attribute_category                 -- DFF�R���e�L�X�g
    , g_cancel_head_tbl(gn_c_head_cnt).attribute2                         -- �������ԍ�
    , g_cancel_head_tbl(gn_c_head_cnt).attribute3                         -- �N�[����
    , g_cancel_head_tbl(gn_c_head_cnt).attribute4                         -- �`�[���͎�
    , g_cancel_head_tbl(gn_c_head_cnt).source                             -- �������\�[�X
    , g_cancel_head_tbl(gn_c_head_cnt).gl_date                            -- �d��v���
    , g_cancel_head_tbl(gn_c_head_cnt).ccid                               -- ������Ȗ�CCID
    , g_cancel_head_tbl(gn_c_head_cnt).org_id                             -- �g�DID
    , g_cancel_head_tbl(gn_c_head_cnt).terms_date                         -- �x���N�Z��
    );
--
    --���팏���i����j���J�E���g�A�b�v
    gn_c_normal_cnt := gn_c_normal_cnt + 1;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END ins_cancel_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_cancel_line
   * Description      : A-10.������דo�^����
   ***********************************************************************************/
  PROCEDURE ins_cancel_line(
                      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cancel_line';              -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\��***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 10-1.������דo�^
    -- ============================================================
    INSERT INTO ap_invoice_lines_interface(
      invoice_id                                        -- ������ID
    , invoice_line_id                                   -- ����������ID
    , line_number                                       -- ���׍s�ԍ�
    , line_type_lookup_code                             -- ���׃^�C�v
    , amount                                            -- ���׋��z
    , description                                       -- �E�v
    , tax_code                                          -- �ŋ敪
    , dist_code_combination_id                          -- CCID
    , last_updated_by                                   -- �ŏI�X�V��
    , last_update_date                                  -- �ŏI�X�V��
    , last_update_login                                 -- �ŏI���O�C��ID
    , created_by                                        -- �쐬��
    , creation_date                                     -- �쐬��
    , attribute_category                                -- DFF�R���e�L�X�g
    , org_id                                            -- �g�DID
    )
    VALUES (
      gn_invoice_id                                     -- ������ID
    , ap_invoice_lines_interface_s.NEXTVAL              -- ����������ID
    , g_cancel_line_tbl(gn_c_line_cnt).line_num         -- ���׍s�ԍ�
    , g_cancel_line_tbl(gn_c_line_cnt).line_type        -- ���׃^�C�v
    , g_cancel_line_tbl(gn_c_line_cnt).amount           -- ���׋��z
    , g_cancel_line_tbl(gn_c_line_cnt).description      -- �E�v
    , g_cancel_line_tbl(gn_c_line_cnt).tax_code         -- �ŋ敪
    , g_cancel_line_tbl(gn_c_line_cnt).ccid             -- CCID
    , cn_last_updated_by                                -- �ŏI�X�V��
    , SYSDATE                                           -- �ŏI�X�V��
    , cn_last_update_login                              -- �ŏI���O�C��ID
    , cn_created_by                                     -- �쐬��
    , SYSDATE                                           -- �쐬��
    , gn_org_id                                         -- DFF�R���e�L�X�g
    , gn_org_id                                         -- �g�DID
    );
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
  END ins_cancel_line;
--
  /**********************************************************************************
   * Procedure Name   : update_cabcel_data
   * Description      : A-11.����f�[�^�X�V
   ***********************************************************************************/
  PROCEDURE update_cabcel_data(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cabcel_data';      -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 6-1.�����w�b�_�[�X�V
    -- ============================================================
    UPDATE xxcok_deduction_recon_head
    SET    ap_ar_if_flag            = 'C'
          ,last_updated_by          = cn_last_updated_by
          ,last_update_date         = SYSDATE
          ,last_update_login        = cn_last_update_login
          ,request_id               = cn_request_id
          ,program_application_id   = cn_program_application_id
          ,program_id               = cn_program_id
          ,program_update_date      = SYSDATE
    WHERE  deduction_recon_head_id  = g_cancel_head_tbl(gn_c_head_cnt).header_id
    ;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END update_cabcel_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg       OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt                 := 0;                     -- �Ώی���
    gn_normal_cnt                 := 0;                     -- ���팏��
    gn_error_cnt                  := 0;                     -- �G���[����
    gn_c_target_cnt               := 0;                     -- �Ώی����i����j
    gn_c_normal_cnt               := 0;                     -- ���팏���i����j
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�����w�b�_�[���擾
    -- ===============================
    get_recon_header(
        ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����w�b�_�[���[�v
    <<recon_head_loop>>
    FOR rh IN 1..g_recon_head_tbl.COUNT LOOP
      -- ===============================
      -- A-3.�������׏��擾
      -- ===============================
      get_recon_line(
          ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      <<recon_line_loop>>
      FOR rl IN 1..g_recon_line_tbl.COUNT LOOP
        -- ===============================
        -- A-4.���������דo�^����
        -- ===============================
        ins_detail_data(
            ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
           ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
           ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_line_cnt := gn_line_cnt + 1;
--
      END LOOP recon_line_loop;
      -- ===============================
      -- A-5.�������w�b�_�[�o�^����
      -- ===============================
      ins_header_data(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �ϐ����N���A
      gn_invoice_amount := 0; -- ���׏W�v���z
      gn_detail_num := 1;     -- ���טA��
--
      -- ===============================
      -- A-6.�����w�b�_�[�X�V����
      -- ===============================
      update_recon_data(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      gn_head_cnt := gn_head_cnt + 1;
      gn_line_cnt := 1;
--
    END LOOP recon_head_loop;
--
    -- ===============================
    -- A-7.����w�b�_�[���擾
    -- ===============================
    get_cancel_header(
        ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<cancel_head_loop>>
    FOR ch IN 1..g_cancel_head_tbl.COUNT LOOP
      -- ===============================
      -- A-8.������׏��擾
      -- ===============================
      get_cancel_line(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.����w�b�_�[�o�^����
      -- ===============================
      ins_cancel_header(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      <<cancel_line_loop>>
      FOR cl IN 1..g_cancel_line_tbl.COUNT LOOP
--
        -- ===============================
        -- A-10.������דo�^����
        -- ===============================
        ins_cancel_line(
            ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
           ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
           ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_c_line_cnt := gn_c_line_cnt + 1;
--
      END LOOP cancel_line_loop;
--
      -- ===============================
      -- A-11.����f�[�^�X�V
      -- ===============================
      update_cabcel_data(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      gn_c_head_cnt := gn_c_head_cnt + 1;
      gn_c_line_cnt := 1;
--
    END LOOP cancel_head_loop;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main( errbuf           OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                 ,retcode          OUT VARCHAR2  )            -- ���^�[���E�R�[�h    --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--####################################  �Œ蕔 START  ####################################--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
       ,ov_errbuf  => lv_errbuf
       ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf        => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode       => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg        => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
    -- ===============================
    -- A-12.�I������
    -- ===============================
    -- �I���X�e�[�^�X���G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      -- ���������̐ݒ�
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
      gn_c_target_cnt := 0;
      gn_c_normal_cnt := 0;
--
      -- �G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- 1.�����������b�Z�[�W�o��
    -- ===============================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90000
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^���������o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90001
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�Ώی����i����j�o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_xxcok_10714
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_c_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^���������i����j�o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_xxcok_10717
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_c_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90002
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.�����I�����b�Z�[�W
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--
--#####################################  �Œ蕔 END  #####################################
--
  END main;
--
END XXCOK024A16C;
/
