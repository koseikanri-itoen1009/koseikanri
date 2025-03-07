CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A45C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCOK024A45C (body)
 * Description      : �T���z�̎x����ʂ����͂��ꂽ�\�����̍T���x������AP�֘A�g���܂��B
 * MD.050           : �T���x��AP�A�g MD050_COK_024_A45
 * Version          : 1.0
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
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2024/12/16    1.0   Y.Koh            �V�K�쐬
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
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A45C';                     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_msg_xxcok_00003     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_msg_xxcok_00028     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok_00034     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034';                 -- ����Ȗڏ��擾�G���[
  cv_msg_xxcok_10632     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10632';                 -- ���b�N�G���[���b�Z�[�W
  cv_msg_xxccp_90000     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- �Ώی������b�Z�[�W
  cv_msg_xxccp_90001     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- �����������b�Z�[�W
  cv_msg_xxccp_90002     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- �G���[�������b�Z�[�W
  cv_msg_xxccp_90004     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_msg_xxccp_90006     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- �G���[�I���S���[���o�b�N
  cv_msg_xxcok_00032     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032';                 -- �x�������擾�G���[
  cv_data_get_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_po_vendor_site      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10689';                 -- �d����T�C�g�}�X�^�ݒ�s��
  -- �g�[�N��
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- �v���t�@�C����
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- �������b�Z�[�W�p�g�[�N����
  cv_tkn_vendor          CONSTANT VARCHAR2(20) := 'VENDOR_CODE';                      -- �x����R�[�h
  -- �v���t�@�C��
  cv_prof_set_of_bks_id  CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_prof_org_id         CONSTANT VARCHAR2(6)  := 'ORG_ID';                           -- �c�ƒP��
  cv_prof_payable        CONSTANT VARCHAR2(19) := 'XXCOK1_AFF3_PAYABLE';              -- ����Ȗ�_������
  cv_prof_sub_acct_dummy CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- �⏕�Ȗ�_�_�~�[�l
  cv_prof_cust_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- �ڋq�R�[�h_�_�~�[�l
  cv_prof_comp_dummy     CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- ��ƃR�[�h_�_�~�[�l
  cv_prof_pre1_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- �\���P_�_�~�[�l
  cv_prof_pre2_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- �\���Q_�_�~�[�l
  cv_prof_source_dedu_ap CONSTANT VARCHAR2(30) := 'XXCOK1_INVOICE_SOURCE_DEDU_AP';    -- �������\�[�X�iAP�T���x���j
  cv_prof_tax_remark     CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_DEDU';-- ������񖾍�_�E�v_�T���Ŋz
  -- �N�C�b�N�R�[�h
  cv_lkup_dedu_type      CONSTANT VARCHAR2(26) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- �T���f�[�^���
  cv_lkup_tax_conv       CONSTANT VARCHAR2(28) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- ����ŃR�[�h�ϊ��}�X�^
  -- ����
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- ����
  -- ���׃^�C�v
  cv_item                CONSTANT VARCHAR2(4)  := 'ITEM';                             -- ���׃^�C�v�i���ׁj
  -- �ŃR�[�h
  cv_0000                CONSTANT VARCHAR2(4)  := '0000';                             -- �ŃR�[�h�i�_�~�[�j
  -- ����^�C�v
  cv_standard            CONSTANT VARCHAR2(8)  := 'STANDARD';                         -- ���z�i���j
  cv_credit              CONSTANT VARCHAR2(6)  := 'CREDIT';                           -- ���z�i���j
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
      ,invoice_number           xxcok_deduction_recon_head.invoice_number%TYPE            -- ��̐������ԍ�
      ,drafting_company         fnd_lookup_values_vl.lookup_code%TYPE                     -- �`�[�쐬���
      ,fin_dept_code            fnd_lookup_values_vl.attribute1%TYPE                      -- �Ǘ�����R�[�h
      ,terms_name               xxcok_deduction_recon_head.terms_name%TYPE                -- �x������
      ,invoice_ele_data         xxcok_deduction_recon_head.invoice_ele_data%TYPE          -- �d�q�f�[�^���
      ,invoice_t_num            xxcok_deduction_recon_head.invoice_t_num%TYPE             -- �K�i������
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
      ,acct_code                VARCHAR2(150)         -- ����Ȗ�
      ,sub_acct_code            VARCHAR2(150)         -- �⏕�Ȗ�
  );
  -- �������׏�񃏁[�N�e�[�u���^��`
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- �������׏��e�[�u���^�ϐ�
  g_recon_line_tbl        g_recon_line_ttype;         -- �������׏��擾
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gd_process_date             DATE;                                                   -- �Ɩ��������t
  gn_set_bks_id               NUMBER;                                                 -- ��v����ID
  gn_org_id                   NUMBER;                                                 -- �c�ƒP��
  gv_payable                  VARCHAR2(40);                                           -- ����Ȗ�_������
  gv_asst_dummy               VARCHAR2(40);                                           -- �⏕�Ȗ�_�_�~�[�l
  gv_cust_dummy               VARCHAR2(40);                                           -- �ڋq�R�[�h_�_�~�[�l
  gv_comp_dummy               VARCHAR2(40);                                           -- ��ƃR�[�h_�_�~�[�l
  gv_pre1_dummy               VARCHAR2(40);                                           -- �\���P_�_�~�[�l
  gv_pre2_dummy               VARCHAR2(40);                                           -- �\���Q_�_�~�[�l
  gv_source_dedu_ap           VARCHAR2(40);                                           -- �������\�[�X�iAP�T���x���j
  gv_tax_remark               VARCHAR2(40);                                           -- ��������_�E�v_�T���Ŋz
  gn_invoice_id               NUMBER;                                                 -- ������ID
  gn_debt_acct_ccid           NUMBER;                                                 -- CCID�i�w�b�_�j
  gn_detail_ccid              NUMBER;                                                 -- CCID�i���ׁj
  --
  gn_head_cnt                 NUMBER  DEFAULT 1;                                      -- �����w�b�_�[�p�J�E���^
  gn_line_cnt                 NUMBER  DEFAULT 1;                                      -- �������חp�J�E���^
  --
  gn_invoice_amount           NUMBER DEFAULT 0;                                       -- ���׋��z�W�v�p
  gn_detail_num               NUMBER DEFAULT 1;                                       -- �A�ԁi���ׁj
  gn_recon_head_id            NUMBER;                                                 -- ���̓p�����[�^.�T�������w�b�_ID
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
    -- �������\�[�X�iAP�T���x���j
    gv_source_dedu_ap := FND_PROFILE.VALUE( cv_prof_source_dedu_ap );
--
    IF ( gv_source_dedu_ap IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_source_dedu_ap
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ������񖾍�_�E�v_�T���Ŋz
    gv_tax_remark := FND_PROFILE.VALUE( cv_prof_tax_remark );
--
    IF ( gv_tax_remark IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_tax_remark
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
             xdrh.recon_slip_num          AS recon_slip_num       -- �x���`�[�ԍ�
            ,xdrh.recon_base_code         AS recon_base_code      -- �x���������_
            ,xdrh.applicant               AS applicant            -- �\����
            ,xdrh.deduction_chain_code    AS deduction_chain_code -- �T���p�`�F�[���R�[�h
            ,xdrh.recon_due_date          AS recon_due_date       -- �x���\���
            ,xdrh.gl_date                 AS gl_date              -- GL�L����
            ,xdrh.invoice_date            AS invoice_date         -- ���������t
            ,pv.segment1                  AS vendor_code          -- �d����
            ,pvsa.vendor_site_code        AS vendor_site_code     -- �d����T�C�g
            ,xdrh.deduction_recon_head_id AS header_id            -- �T�������w�b�_�[ID
            ,xdrh.invoice_number          AS invoice_number       -- ��̐������ԍ�
            ,flvv_comp.lookup_code        AS drafting_company     -- �`�[�쐬���
            ,flvv_comp.attribute1         AS fin_dept_code        -- �Ǘ�����R�[�h
            ,xdrh.terms_name              AS terms_name           -- �x������
            ,xdrh.invoice_ele_data        AS invoice_ele_data     -- �d�q�f�[�^���
            ,xdrh.invoice_t_num           AS invoice_t_num        -- �K�i������
      FROM   xxcok_deduction_recon_head   xdrh                    -- �T�������w�b�_�[���
            ,po_vendor_sites_all          pvsa                    -- �d����T�C�g
            ,po_vendors                   pv                      -- �d����
            ,fnd_lookup_values_vl         flvv_conv               -- �Q�ƕ\�r���[(XXCMM_CONV_COMPANY_CODE)
            ,fnd_lookup_values_vl         flvv_comp               -- �Q�ƕ\�r���[(XXCFO1_DRAFTING_COMPANY)
      WHERE  xdrh.deduction_recon_head_id =       gn_recon_head_id
      AND    pv.segment1(+)               =       xdrh.payee_code
      AND    pvsa.vendor_id(+)            =       pv.vendor_id
      AND    pvsa.org_id(+)               =       gn_org_id
      AND    flvv_conv.lookup_type        =       'XXCMM_CONV_COMPANY_CODE'
      AND    flvv_conv.attribute1         =       NVL(pvsa.attribute11, '001')
      AND    xdrh.gl_date                 BETWEEN flvv_conv.start_date_active
                                          AND     NVL(flvv_conv.end_date_active, xdrh.gl_date)
      AND    flvv_comp.lookup_type        =       'XXCFO1_DRAFTING_COMPANY'
      AND    flvv_comp.lookup_code        =       flvv_conv.attribute2
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
    -- �擾������0���������ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      -- �ΏۂȂ����b�Z�[�W�ŃG���[�I��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    -- �擾������2���ȏゾ�����ꍇ
    ELSIF ( gn_target_cnt >= 2 ) THEN
      -- �d����T�C�g�}�X�^�ݒ�s���ŃG���[�I��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_po_vendor_site
                     ,cv_tkn_vendor
                     ,g_recon_head_tbl(1).vendor_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
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
              xdnr.payment_amt  AS  payment_amt       -- �x���z
             ,SUBSTRB(xdnr.condition_no || cv_msg_part || flv.meaning || cv_msg_part || xch.content || cv_msg_part || xdnr.remarks, 1, 240)
                                    AS  remarks       -- �E�v
             ,flv.attribute6        AS  acct_code     -- ����Ȗ�
             ,flv.attribute7        AS  sub_acct_code -- �⏕�Ȗ�
      FROM    xxcok_deduction_num_recon xdnr          -- �T��No�ʏ������
             ,fnd_lookup_values         flv           -- �f�[�^���
             ,xxcok_condition_header    xch           -- �T�������e�[�u��
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_dedu_type
      AND     flv.lookup_code       = xdnr.data_type
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     xch.condition_no(+)   = xdnr.condition_no
      UNION ALL
      -- �T��No�ʏ������_��
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              SUM(xdnr.payment_tax) AS  payment_amt   -- �x���z
             ,gv_tax_remark || xdnr.payment_tax_code
                                    AS  remarks       -- �E�v
             ,atca.attribute5       AS  acct_code     -- ����Ȗ�
             ,atca.attribute6       AS  sub_acct_code -- �⏕�Ȗ�
      FROM    xxcok_deduction_num_recon xdnr          -- �T��No�ʏ������
             ,ap_tax_codes_all          atca          -- AP�ŃR�[�h�}�X�^
             ,fnd_lookup_values         flv           -- �ŃR�[�h�ϊ��}�X�^
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xdnr.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      GROUP BY gv_tax_remark || xdnr.payment_tax_code
              ,atca.attribute5
              ,atca.attribute6
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
    -- ���׍쐬�̏���
    IF ( gn_invoice_id IS NULL ) THEN
      -- �V�[�P���X���琿����ID���擾
      SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    END IF;
    -- ============================================================
    -- 4-2.CCID�擾
    -- ============================================================
    gn_detail_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                                 -- ������
                      , iv_segment1  => g_recon_head_tbl(gn_head_cnt).drafting_company  -- ��ЃR�[�h(�`�[�쐬���)
                      , iv_segment2  => g_recon_head_tbl(gn_head_cnt).fin_dept_code     -- ����R�[�h(�`�[�쐬��Ђ̊Ǘ�����)
                      , iv_segment3  => g_recon_line_tbl(gn_line_cnt).acct_code         -- ����ȖڃR�[�h
                      , iv_segment4  => g_recon_line_tbl(gn_line_cnt).sub_acct_code     -- �⏕�ȖڃR�[�h
                      , iv_segment5  => gv_cust_dummy                                   -- �ڋq�R�[�h
                      , iv_segment6  => gv_comp_dummy                                   -- ��ƃR�[�h
                      , iv_segment7  => gv_pre1_dummy                                   -- �\���P�R�[�h
                      , iv_segment8  => gv_pre2_dummy                                   -- �\���Q�R�[�h
                      );
    IF ( gn_detail_ccid IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00034
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 4-3.����������OIF�o�^
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
    , attribute10                                       -- DFF10(�d�q�f�[�^���)
    , attribute13                                       -- DFF13(�K�i������)
    , attribute15                                       -- DFF15(�`�[�쐬���)
    , org_id                                            -- �g�DID
    )
    VALUES (
      gn_invoice_id                                     -- ������ID
    , ap_invoice_lines_interface_s.NEXTVAL              -- ����������ID
    , gn_detail_num                                     -- ���׍s�ԍ�
    , cv_item                                           -- ���׃^�C�v
    , g_recon_line_tbl(gn_line_cnt).payment_amt         -- ���׋��z
    , g_recon_line_tbl(gn_line_cnt).remarks             -- �E�v
    , cv_0000                                           -- �ŋ敪
    , gn_detail_ccid                                    -- CCID
    , cn_last_updated_by                                -- �ŏI�X�V��
    , SYSDATE                                           -- �ŏI�X�V��
    , cn_last_update_login                              -- �ŏI���O�C��ID
    , cn_created_by                                     -- �쐬��
    , SYSDATE                                           -- �쐬��
    , gn_org_id                                         -- DFF�R���e�L�X�g
    , g_recon_head_tbl(gn_head_cnt).invoice_ele_data    -- DFF10(�d�q�f�[�^���)
    , g_recon_head_tbl(gn_head_cnt).invoice_t_num       -- DFF13(�K�i������)
    , g_recon_head_tbl(gn_head_cnt).drafting_company    -- DFF15(�`�[�쐬���)
    , gn_org_id                                         -- �g�DID
    );
    -- �w�b�_�[�p�ɋ��z���W�v����
    gn_invoice_amount := gn_invoice_amount + NVL(g_recon_line_tbl(gn_line_cnt).payment_amt,0);
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
    lt_term_id      ap_terms_v.term_id%TYPE;
    ln_debt_acct_ccid         NUMBER;             -- ������CCID
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
    -- 5-1.������CCID�擾
    -- ============================================================
    ln_debt_acct_ccid := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date   -- ������
                         , iv_segment1  => g_recon_head_tbl(gn_head_cnt).drafting_company  -- ��ЃR�[�h(�`�[�쐬���)
                         , iv_segment2  => g_recon_head_tbl(gn_head_cnt).fin_dept_code     -- ����R�[�h(�`�[�쐬��Ђ̊Ǘ�����)
                         , iv_segment3  => gv_payable        -- ����ȖڃR�[�h(������)
                         , iv_segment4  => gv_asst_dummy     -- �⏕�ȖڃR�[�h(�_�~�[�l)
                         , iv_segment5  => gv_cust_dummy     -- �ڋq�R�[�h(�_�~�[�l)
                         , iv_segment6  => gv_comp_dummy     -- ��ƃR�[�h(�_�~�[�l)
                         , iv_segment7  => gv_pre1_dummy     -- �\���P�R�[�h(�_�~�[�l)
                         , iv_segment8  => gv_pre2_dummy     -- �\���Q�R�[�h(�_�~�[�l)
                       );
    -- 5-2
    IF ( ln_debt_acct_ccid IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00034
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 5-3.�x���������擾
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
    -- 5-5.�������w�b�_�[�o�^
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
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- �������ԍ�
    , CASE
        WHEN gn_invoice_amount >= 0 THEN
          cv_standard
        WHEN gn_invoice_amount < 0 THEN
          cv_credit
      END                                               -- ����^�C�v
    , g_recon_head_tbl(gn_head_cnt).invoice_date        -- ���������t
    , g_recon_head_tbl(gn_head_cnt).vendor_code         -- �d����R�[�h
    , g_recon_head_tbl(gn_head_cnt).vendor_site_code    -- �d����T�C�g�R�[�h
    , gn_invoice_amount                                 -- �������z
    , lt_term_id                                        -- �x������ID
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- �E�v
    , SYSDATE                                           -- �ŏI�X�V��
    , cn_last_updated_by                                -- �ŏI�X�V��
    , cn_last_update_login                              -- �ŏI���O�C��ID
    , SYSDATE                                           -- �쐬��
    , cn_created_by                                     -- �쐬��
    , gn_org_id                                         -- �g�DID
    , g_recon_head_tbl(gn_head_cnt).invoice_number      -- ��̐������ԍ�
    , g_recon_head_tbl(gn_head_cnt).recon_base_code     -- �N�[����
    , g_recon_head_tbl(gn_head_cnt).applicant           -- �`�[���͎�
    , gv_source_dedu_ap                                 -- �������\�[�X
    , g_recon_head_tbl(gn_head_cnt).gl_date             -- �d��v���
    , ln_debt_acct_ccid                                 -- ������CCID
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
                 ,retcode          OUT VARCHAR2               -- ���^�[���E�R�[�h    --# �Œ� #
                 ,in_recon_head_id IN  NUMBER    )            -- �T�������w�b�_�[ID
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
    -- ���̓p�����[�^��ϐ��Ɋi�[
    gn_recon_head_id              := in_recon_head_id;     -- ���̓p�����[�^.�T�������w�b�_ID
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
END XXCOK024A45C;
/
