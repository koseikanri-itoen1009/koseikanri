CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A24C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A24C (body)
 * Description      : �T���z�̎x����ʂ̐\���{�^���������ɁA
 *                  : �쐬���ꂽ�T����������AP������͂֘A�g���܂�
 * MD.050           : AP������͘A�g MD050_COK_024_A24
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.��������
 *  get_recon_header       A-2.�����w�b�_��񒊏o
 *  get_recon_line         A-3.�������׏�񒊏o
 *  ins_pay_slip_header    A-4.�x���`�[�w�b�_�o�^
 *  ins_pay_slip_line      A-5.�x���`�[���דo�^
 *  import_ap_depart       A-6.AP������̓C���|�[�g
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/05/07    1.0   M.Sato           �V�K�쐬
 *  2022/08/24    1.1   SCSK Y.Koh       E_�{�ғ�_18528 �؜ߑ䎆�ɍT���}�X�^���e�̏o��
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
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A24C';                     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_data_get_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_profile_get_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_ap_terms_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00032';                 -- �x�������擾�G���[���b�Z�[�W
  cv_table_lock_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                 -- ���b�N�G���[���b�Z�[�W
  cv_ap_imp_billing_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10683';                 -- ������́iAP�j�f�[�^�C���|�[�g���s�G���[
  cv_ap_imp_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10684';                 -- ������́iAP�j�f�[�^�C���|�[�g�G���[
  cv_slip_type_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10686';                 -- �`�[��ʖ��擾�G���[
  cv_slip_num_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10688';                 -- �A�g�x���`�[�ԍ�
  cv_po_vendor_site      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10689';                 -- �d����T�C�g�}�X�^�ݒ�s��
  cv_target_rec_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';                 -- �Ώی������b�Z�[�W
  cv_success_rec_msg     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';                 -- �����������b�Z�[�W
  cv_error_rec_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                 -- �G���[�������b�Z�[�W
  cv_normal_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_error_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                 -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- �v���t�@�C����
  cv_tkn_vendor          CONSTANT VARCHAR2(20) := 'VENDOR_CODE';                      -- �x����R�[�h
  cv_tkn_request_id      CONSTANT VARCHAR2(20) := 'REQUEST_ID';                       -- �v��ID
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';                           -- �X�e�[�^�X
  cv_tkn_slip_num        CONSTANT VARCHAR2(20) := 'SLIP_NUM';                         -- �x���`�[�ԍ�
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- �������b�Z�[�W�p�g�[�N����
  -- �v���t�@�C��
  cv_recon_line_summ_ded CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_DEDU';
                                                                                      -- ��������_�E�v_�T���Ŋz
  cv_recon_line_summ_acc CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_ACCOUNT';
                                                                                      -- ��������_�E�v_�Ȗڎx��
  cv_set_of_bks_id       CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_org_id              CONSTANT VARCHAR2(15) := 'ORG_ID';                           -- �c�ƒP��
  cv_other_tax           CONSTANT VARCHAR2(50) := 'XXCOK1_OTHER_TAX_CODE';            -- �ΏۊO����ŃR�[�h
  cv_com_code            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF1_COMPANY_CODE';         -- ��ЃR�[�h
  cv_dept_fin            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF2_DEPT_FIN';             -- ����R�[�h_�����o����
  cv_cus_dummy           CONSTANT VARCHAR2(50) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- �ڋq�R�[�h_�_�~�[�l
  cv_com_dummy           CONSTANT VARCHAR2(50) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- ��ƃR�[�h_�_�~�[�l
  cv_pre1_dummy          CONSTANT VARCHAR2(50) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- �\���P_�_�~�[�l
  cv_pre2_dummy          CONSTANT VARCHAR2(50) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- �\���Q_�_�~�[�l
  -- �N�C�b�N�R�[�h
  cv_lookup_slip_type    CONSTANT VARCHAR2(30) := 'XX03_SLIP_TYPES';                  -- �`�[���
  cv_lookup_sls_dedu     CONSTANT VARCHAR2(10) := '30000';                            -- �̔��T��
  cv_lookup_dedu_type    CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- �T���f�[�^���
  cv_lookup_tax_conv     CONSTANT VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- ����ŃR�[�h�ϊ��}�X�^
  -- �t���O�E�敪�萔
  cv_y_flag              CONSTANT VARCHAR2(1) := 'Y';                                 -- �t���O�l:Y
  cv_n_flag              CONSTANT VARCHAR2(1) := 'N';                                 -- �t���O�l:N
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- ����
  -- ��������_�E�v�R�[�h
  cv_dedu_pay            CONSTANT VARCHAR2(5) := '30001';                             -- �T���x��
  cv_account_pay         CONSTANT VARCHAR2(5) := '30002';                             -- �Ȗڎx��
  -- AP������͈ꎞ�\�֓o�^����Œ�l
  cv_wf_status           CONSTANT VARCHAR2(2) := '00';                                -- �X�e�[�^�X
  cv_currency_jpy        CONSTANT VARCHAR2(3) := 'JPY';                               -- �ʉ�
  -- �R���J�����g���s
  cv_conc_appl           CONSTANT VARCHAR2(4):=  'XX03';                              -- �Z�k�A�v����
  cv_conc_prog           CONSTANT VARCHAR2(20):= 'XX034DD001C';                       -- ������́iAP�j�f�[�^�C���|�[�g
  -- �T�������w�b�_�[�X�e�[�^�X
  cv_recon_status_eg     CONSTANT VARCHAR2(2):=  'EG';                                -- ���͒�
  cv_recon_status_sg     CONSTANT VARCHAR2(2):=  'SG';                                -- ���M��
  cv_recon_status_sd     CONSTANT VARCHAR2(2):=  'SD';                                -- ���M��
  -- ���b�N�X�e�[�^�X
  cv_lock_status_normal  CONSTANT VARCHAR2(1):=  '0';                                -- ���b�N�X�e�[�^�X:����
  cv_lock_status_error   CONSTANT VARCHAR2(1):=  '1';                                -- ���b�N�X�e�[�^�X:�G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �T�������w�b�_���R�[�h�^��`
  TYPE g_recon_header_rtype IS RECORD(
       recon_base_code              xxcok_deduction_recon_head.recon_base_code%TYPE   -- �x���������_
      ,recon_slip_num               xxcok_deduction_recon_head.recon_slip_num%TYPE    -- �x���`�[�ԍ�
      ,recon_due_date               xxcok_deduction_recon_head.recon_due_date%TYPE    -- �x���\���
      ,gl_date                      xxcok_deduction_recon_head.gl_date%TYPE           -- GL�L����
      ,payee_code                   xxcok_deduction_recon_head.payee_code%TYPE        -- �x����R�[�h
      ,applicant                    xxcok_deduction_recon_head.applicant%TYPE         -- �\����
      ,approver                     xxcok_deduction_recon_head.approver%TYPE          -- ���F��
      ,invoice_date                 xxcok_deduction_recon_head.invoice_date%TYPE      -- ���������t
      ,terms_name                   xxcok_deduction_recon_head.terms_name%TYPE        -- �x������
      ,invoice_number               xxcok_deduction_recon_head.invoice_number%TYPE    -- ��̐������ԍ�
      ,vendor_site_code             po_vendor_sites_all.vendor_site_code%TYPE         -- �d����T�C�g�R�[�h
      ,pay_group_lookup_code        po_vendor_sites_all.pay_group_lookup_code%TYPE    -- �x���O���[�v
  );
  -- �T�������w�b�_���[�N�e�[�u���^��`
  TYPE g_recon_head_ttype    IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- �T�������w�b�_�e�[�u���^�ϐ�
  g_recon_head_tbl        g_recon_head_ttype;                                         -- �T�������w�b�_���o
--
  -- �T���������׃��[�N�e�[�u����`
  TYPE g_recon_line_rtype IS RECORD(
       sort_key                     VARCHAR2(50)                                      -- �\�[�g�L�[
      ,summary_code                 VARCHAR2(5)                                       -- �E�v�R�[�h
      ,body_amount                  NUMBER                                            -- �{�̋��z
      ,tax_amount                   NUMBER                                            -- ����Ŋz
      ,summary                      VARCHAR2(300)                                     -- �E�v
      ,tax_class_code               VARCHAR2(40)                                      -- �ŋ敪�R�[�h
      ,dept                         VARCHAR2(40)                                      -- ����
      ,account                      VARCHAR2(150)                                     -- ����Ȗ�
      ,sub_account                  VARCHAR2(150)                                     -- �⏕�Ȗ�
  );
  -- �T���������׃��[�N�e�[�u���^��`
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- �T���������׃e�[�u���^�ϐ�
  g_recon_line_tbl        g_recon_line_ttype;                                         -- �T���������ג��o
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gv_recon_line_summ_ded      VARCHAR2(40);                                           -- ��������_�E�v_�T���Ŋz
  gv_recon_line_summ_acc      VARCHAR2(40);                                           -- ��������_�E�v_�Ȗڎx��
  gn_set_of_bks_id            NUMBER;                                                 -- ��v����ID
  gn_org_id                   NUMBER;                                                 -- �c�ƒP��
  gv_other_tax                VARCHAR2(40);                                           -- �ΏۊO����ŃR�[�h
  gv_com_code                 VARCHAR2(40);                                           -- ��ЃR�[�h
  gv_dept_fin                 VARCHAR2(40);                                           -- ����R�[�h_�����o����
  gv_cus_dummy                VARCHAR2(40);                                           -- �ڋq�R�[�h_�_�~�[�l
  gv_com_dummy                VARCHAR2(40);                                           -- ��ƃR�[�h_�_�~�[�l
  gv_pre1_dummy               VARCHAR2(40);                                           -- �\���P_�_�~�[�l
  gv_pre2_dummy               VARCHAR2(40);                                           -- �\���Q_�_�~�[�l
  gv_slip_type                VARCHAR2(240);                                          -- �`�[��ʖ�
  --
  gn_recon_head_id            NUMBER;                                                 -- ���̓p�����[�^.�T�������w�b�_ID
  gv_lock_status              VARCHAR2(1);                                            -- ���b�N�X�e�[�^�X
  gd_recon_due_date           xxcok_deduction_recon_head.recon_due_date%TYPE;         -- �x���\���
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
    -- ��������_�E�v_�T���Ŋz�̃v���t�@�C���l���擾
    -- ============================================================
    gv_recon_line_summ_ded := FND_PROFILE.VALUE( cv_recon_line_summ_ded ); -- ��������_�E�v_�T���Ŋz
    -- ��������_�E�v_�T���Ŋz��NULL�Ȃ�G���[�I��
    IF gv_recon_line_summ_ded IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_recon_line_summ_ded
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- ��������_�E�v_�Ȗڎx���̃v���t�@�C���l���擾
    -- ============================================================
    gv_recon_line_summ_acc := FND_PROFILE.VALUE( cv_recon_line_summ_acc ); -- ��������_�E�v_�Ȗڎx��
    -- ��������_�E�v_�Ȗڎx����NULL�Ȃ�G���[�I��
    IF gv_recon_line_summ_acc IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_recon_line_summ_acc
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- ��v����ID�̃v���t�@�C���l���擾
    -- ============================================================
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id )); -- ��v����ID
    -- ��v����ID��NULL�Ȃ�G���[�I��
    IF gn_set_of_bks_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �c�ƒP�ʂ̃v���t�@�C���l���擾
    -- ============================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ));               -- �c�ƒP��
    -- �c�ƒP�ʂ�NULL�Ȃ�G���[�I��
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �ΏۊO����ŃR�[�h�̃v���t�@�C���l���擾
    -- ============================================================
    gv_other_tax := FND_PROFILE.VALUE( cv_other_tax );                     -- �ΏۊO����ŃR�[�h
    -- �ΏۊO����ŃR�[�h��NULL�Ȃ�G���[�I��
    IF gv_other_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_other_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- ��ЃR�[�h�̃v���t�@�C���l���擾
    -- ============================================================
    gv_com_code := FND_PROFILE.VALUE( cv_com_code );                       -- ��ЃR�[�h
    -- ��ЃR�[�h��NULL�Ȃ�G���[�I��
    IF gv_com_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_com_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- ����R�[�h_�����o�����̃v���t�@�C���l���擾
    -- ============================================================
    gv_dept_fin := FND_PROFILE.VALUE( cv_dept_fin );                       -- ����R�[�h_�����o����
    -- ����R�[�h_�����o������NULL�Ȃ�G���[�I��
    IF gv_dept_fin IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �ڋq�R�[�h_�_�~�[�l�̃v���t�@�C���l���擾
    -- ============================================================
    gv_cus_dummy := FND_PROFILE.VALUE( cv_cus_dummy );                     -- �ڋq�R�[�h_�_�~�[�l
    -- �ڋq�R�[�h_�_�~�[�l��NULL�Ȃ�G���[�I��
    IF gv_cus_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_cus_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- ��ƃR�[�h_�_�~�[�l�̃v���t�@�C���l���擾
    -- ============================================================
    gv_com_dummy := FND_PROFILE.VALUE( cv_com_dummy );                     -- ��ƃR�[�h_�_�~�[�l
    -- ��ƃR�[�h_�_�~�[�l��NULL�Ȃ�G���[�I��
    IF gv_com_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_com_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �\���P_�_�~�[�l�̃v���t�@�C���l���擾
    -- ============================================================
    gv_pre1_dummy := FND_PROFILE.VALUE( cv_pre1_dummy );                   -- �\���P_�_�~�[�l
    -- �\���P_�_�~�[�l��NULL�Ȃ�G���[�I��
    IF gv_pre1_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_pre1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �\���Q_�_�~�[�l�̃v���t�@�C���l���擾
    -- ============================================================
    gv_pre2_dummy := FND_PROFILE.VALUE( cv_pre2_dummy );                   -- �\���Q_�_�~�[�l
    -- �\���Q_�_�~�[�l��NULL�Ȃ�G���[�I��
    IF gv_pre2_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_pre2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- �`�[��ʖ��̎擾
    -- ============================================================
    BEGIN
    --
      SELECT  flv.description    AS description      -- �E�v
      INTO    gv_slip_type                           -- �`�[��ʖ�
      FROM    fnd_lookup_values  flv                 -- �`�[���
      WHERE   flv.lookup_type  = cv_lookup_slip_type
      AND     flv.lookup_code  = cv_lookup_sls_dedu
      AND     flv.language     = cv_lang
      AND     flv.enabled_flag = cv_y_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- �`�[��ʖ��擾�G���[���b�Z�[�W
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_slip_type_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
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
   * Description      : A-2.�����w�b�_��񒊏o
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
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lv_ap_terms     xx03_ap_terms_v.attribute1%TYPE;        -- �x���\����ύX�t���O
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
    -- *** ���[�J���E�J�[�\�� ***
    -- �T�������w�b�_���o�J�[�\��
    CURSOR recon_head_cur
    IS
      SELECT xdrh.recon_base_code          AS recon_base_code        -- �x���������_
            ,xdrh.recon_slip_num           AS recon_slip_num         -- �x���`�[�ԍ�
            ,xdrh.recon_due_date           AS recon_due_date         -- �x���\���
            ,xdrh.gl_date                  AS gl_date                -- GL�L����
            ,xdrh.payee_code               AS payee_code             -- �x����R�[�h
            ,xdrh.applicant                AS applicant              -- �\����
            ,xdrh.approver                 AS approver               -- ���F��
            ,xdrh.invoice_date             AS invoice_date           -- ���������t
            ,xdrh.terms_name               AS terms_name             -- �x������
            ,xdrh.invoice_number           AS invoice_number         -- ��̐������ԍ�
            ,pvsa.vendor_site_code         AS vendor_site_code       -- �d����T�C�g
            ,pvsa.pay_group_lookup_code    AS pay_group_lookup_code  -- �x���O���[�v
      FROM   xxcok_deduction_recon_head    xdrh                      -- �T�������w�b�_�[���
            ,po_vendor_sites_all           pvsa                      -- �d����T�C�g
            ,po_vendors                    pv                        -- �d����
      WHERE  xdrh.deduction_recon_head_id  = gn_recon_head_id
      AND    xdrh.recon_status             = cv_recon_status_sg
      AND    pv.segment1(+)                = xdrh.payee_code
      AND    pvsa.vendor_id(+)             = pv.vendor_id
      AND    pvsa.org_id(+)                = gn_org_id
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
    -- �ϐ��̏�����
    lv_ap_terms := NULL;
    -- ============================================================
    -- 1.�����Ώۏ����w�b�_���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  recon_head_cur;
    -- �f�[�^�擾
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_head_cur;
    -- �擾������0���������ꍇ
    IF ( g_recon_head_tbl.COUNT = 0 ) THEN
      -- �ΏۂȂ����b�Z�[�W�ŃG���[�I��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    -- �擾������2���ȏ�������͎x�����O���[�v��NULL�������ꍇ
    ELSIF ( g_recon_head_tbl.COUNT >= 2 OR
            g_recon_head_tbl(1).pay_group_lookup_code IS NULL )
    THEN
      -- �d����T�C�g�}�X�^�ݒ�s���ŃG���[�I��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_po_vendor_site
                     ,cv_tkn_vendor
                     ,g_recon_head_tbl(1).payee_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 2.�x�������̎x���\����ύX�t���O���擾
    -- ============================================================
    BEGIN
    --
      SELECT xatv.attribute1            AS recon_due_date_flag        -- �x���\����ύX�t���O
      INTO   lv_ap_terms
      FROM   xx03_ap_terms_v            xatv                          -- �x�������r���[
      WHERE  xatv.name                  = g_recon_head_tbl(1).terms_name
      AND    xatv.enabled_flag          = cv_y_flag
      AND    NVL( xatv.start_date_active, TO_DATE( '1000/01/01' , 'YYYY/MM/DD' ))
                                       <= TRUNC( SYSDATE )
      AND    NVL( xatv.end_date_active, TO_DATE( '4712/12/31' , 'YYYY/MM/DD' ))
                                        > TRUNC( SYSDATE )
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- �x�������擾�G���[���b�Z�[�W
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_ap_terms_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ============================================================
    -- 3.�x���\����ύX�t���O��N�̏ꍇ�A�x���\�����NULL�Ƃ���
    -- ============================================================
    IF ( lv_ap_terms = cv_n_flag ) THEN
      gd_recon_due_date := NULL;                                      -- �x���\���
    ELSE
      -- Y�̏ꍇ�͎擾�����x���\������i�[
      gd_recon_due_date := g_recon_head_tbl(1).recon_due_date;        -- �x���\���
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
                                                 ,cv_table_lock_msg
                                                 );
      -- ���b�N�X�e�[�^�X�ɃG���[���i�[
      gv_lock_status := cv_lock_status_error;
      --
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
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
   * Description      : A-3.�������׏�񒊏o
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
    -- �������׏�񒊏o�J�[�\��
    CURSOR recon_line_cur
    IS
      -- �T���x��_�{��
      SELECT '1' || xdnr.condition_no || xdnr.data_type     AS sort_key          -- �\�[�g�L�[
             ,cv_dedu_pay                                   AS summary_code      -- �E�v�R�[�h
             ,xdnr.payment_amt                              AS body_amount       -- �{�̋��z
             ,0                                             AS tax_amount        -- ����Ŋz
-- 2022/08/24 Ver1.1 MOD Start
             ,SUBSTRB(xdnr.condition_no || cv_msg_part || flv.meaning || cv_msg_part || xch.content || cv_msg_part || xdnr.remarks, 1, 240)
--             ,xdnr.condition_no || cv_msg_part || flv.meaning || cv_msg_part || xdnr.remarks
-- 2022/08/24 Ver1.1 MOD End
                                                            AS summary           -- �E�v
             ,gv_other_tax                                  AS tax_class_code    -- �ŋ敪�R�[�h
             ,gv_dept_fin                                   AS dept              -- ����
             ,flv.attribute6                                AS account           -- ����Ȗ�
             ,flv.attribute7                                AS sub_account       -- �⏕�Ȗ�
      FROM    xxcok_deduction_num_recon     xdnr                                 -- �T��No�ʏ������
             ,fnd_lookup_values             flv                                  -- �f�[�^���
-- 2022/08/24 Ver1.1 ADD Start
             ,xxcok_condition_header        xch
-- 2022/08/24 Ver1.1 ADD End
      WHERE   xdnr.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND     xdnr.target_flag              = cv_y_flag
      AND     xdnr.payment_amt             != 0
      AND     flv.lookup_type               = cv_lookup_dedu_type
      AND     flv.lookup_code               = xdnr.data_type
      AND     flv.language                  = cv_lang
      AND     flv.enabled_flag              = cv_y_flag
-- 2022/08/24 Ver1.1 ADD Start
      AND     xch.condition_no(+)           = xdnr.condition_no
-- 2022/08/24 Ver1.1 ADD End
      -- �T���x��_��
      UNION ALL
      SELECT '2' || xdnr.payment_tax_code                   AS sort_key          -- �\�[�g�L�[
             ,cv_dedu_pay                                   AS summary_code      -- �E�v�R�[�h
             ,SUM( payment_tax )                            AS body_amount       -- �{�̋��z
             ,0                                             AS tax_amount        -- ����Ŋz
             ,gv_recon_line_summ_ded || xdnr.payment_tax_code
                                                            AS summary           -- �E�v
             ,gv_other_tax                                  AS tax_class_code    -- �ŋ敪�R�[�h
             ,gv_dept_fin                                   AS dept              -- ����
             ,atca.attribute5                               AS account           -- ����Ȗ�
             ,atca.attribute6                               AS sub_account       -- �⏕�Ȗ�
      FROM    xxcok_deduction_num_recon     xdnr                                 -- �T��No�ʏ������
             ,ap_tax_codes_all              atca                                 -- AP�Ń}�X�^
      WHERE   xdnr.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND     xdnr.target_flag              = cv_y_flag
      AND     atca.name                     = xdnr.payment_tax_code
      AND     atca.set_of_books_id          = gn_set_of_bks_id
      AND     atca.org_id                   = gn_org_id
      GROUP BY
              xdnr.payment_tax_code                                              -- ����ŃR�[�h
             ,atca.attribute5                                                    -- ����Ȗ�(����)
             ,atca.attribute6                                                    -- �⏕�Ȗ�(����)
      HAVING
              SUM( payment_tax )           != 0                                  -- ��������Ŋz
      -- �Ȗڎx��
      UNION ALL
      SELECT '3' || TO_CHAR( xapi.account_payment_num,'0999999999' )
                                                            AS sort_key          -- �\�[�g�L�[
             ,cv_account_pay                                AS summary_code      -- �E�v�R�[�h
             ,xapi.payment_amt                              AS body_amount       -- �{�̋��z
             ,xapi.payment_tax                              AS tax_amount        -- ����Ŋz
             ,gv_recon_line_summ_acc || flv.meaning || cv_msg_part || xapi.remarks
                                                            AS summary           -- �E�v
             ,flv2.attribute1                               AS tax_class_code    -- �ŋ敪�R�[�h
             ,g_recon_head_tbl(1).recon_base_code           AS dept              -- ����
             ,flv.attribute4                                AS account           -- ����Ȗ�
             ,flv.attribute5                                AS sub_account       -- �⏕�Ȗ�
      FROM    xxcok_account_payment_info    xapi                                 -- �Ȗڎx�����
             ,fnd_lookup_values             flv                                  -- �f�[�^���
             ,fnd_lookup_values             flv2                                 -- ����ŃR�[�h�ϊ��}�X�^
      WHERE   xapi.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND   ( xapi.payment_amt             != 0 OR
              xapi.payment_tax             != 0   )
      AND     flv.lookup_type               = cv_lookup_dedu_type
      AND     flv.lookup_code               = xapi.data_type
      AND     flv.language                  = cv_lang
      AND     flv.enabled_flag              = cv_y_flag
      AND     flv2.lookup_type              = cv_lookup_tax_conv
      AND     flv2.lookup_code              = xapi.payment_tax_code
      AND     flv2.language                 = cv_lang
      AND     flv2.enabled_flag             = cv_y_flag
      ORDER BY
              sort_key ASC
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
    -- �擾�����`�[���א���Ώی����Ɋi�[
    gn_target_cnt := g_recon_line_tbl.COUNT;        -- �Ώی���
    -- �Ώی�����0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      -- �ΏۂȂ����b�Z�[�W�ŃG���[�I��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
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
   * Procedure Name   : ins_pay_slip_header
   * Description      : A-4.�x���`�[�w�b�_�o�^
   ***********************************************************************************/
  PROCEDURE ins_pay_slip_header(
                      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pay_slip_header';              -- �v���O������
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
    -- AP������͈ꎞ�\�֓o�^����
    -- ============================================================
    INSERT INTO xx03_payment_slips_if(
         interface_id                                        -- �C���^�[�t�F�C�XID
        ,source                                              -- �쐬��
        ,invoice_id                                          -- ������ID
        ,wf_status                                           -- �X�e�[�^�X
        ,slip_type_name                                      -- �`�[���
        ,entry_date                                          -- ���͓�
        ,requestor_person_number                             -- �o�^��(�]�ƈ��ԍ�)
        ,approver_person_number                              -- ���F��(�]�ƈ��ԍ�)
        ,invoice_date                                        -- ���������t
        ,vendor_code                                         -- �d����R�[�h
        ,vendor_site_code                                    -- �d����T�C�g
        ,invoice_currency_code                               -- �ʉ�
        ,exchange_rate                                       -- ���[�g
        ,exchange_rate_type_name                             -- ���[�g�^�C�v
        ,terms_name                                          -- �x������
        ,description                                         -- �E�v
        ,vendor_invoice_num                                  -- �d���搿�����ԍ�
        ,entry_person_number                                 -- ���͎�(�]�ƈ��ԍ�)
        ,pay_group_lookup_name                               -- �x���O���[�v
        ,gl_date                                             -- �v���
        ,prepay_num                                          -- �O���`�[�ԍ�
        ,terms_date                                          -- �x���\���
        ,org_id                                              -- �c�ƒP��
        ,created_by                                          -- �쐬��
        ,creation_date                                       -- �쐬��
        ,last_updated_by                                     -- �ŏI�X�V��
        ,last_update_date                                    -- �ŏI�X�V��
        ,last_update_login                                   -- �ŏI�X�V���O�C��
        ,request_id                                          -- �v��ID
        ,program_application_id                              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                                          -- �R���J�����g�E�v���O����ID
        ,program_update_date                                 -- �v���O�����X�V��
        )VALUES(
         gn_recon_head_id                                    -- �C���^�[�t�F�C�XID
        ,gv_slip_type                                        -- �쐬��
        ,NULL                                                -- ������ID
        ,cv_wf_status                                        -- �X�e�[�^�X
        ,gv_slip_type                                        -- �`�[���
        ,SYSDATE                                             -- ���͓�
        ,g_recon_head_tbl(1).applicant                       -- �o�^��(�]�ƈ��ԍ�)
        ,g_recon_head_tbl(1).approver                        -- ���F��(�]�ƈ��ԍ�)
        ,g_recon_head_tbl(1).invoice_date                    -- ���������t
        ,g_recon_head_tbl(1).payee_code                      -- �d����R�[�h
        ,g_recon_head_tbl(1).vendor_site_code                -- �d����T�C�g
        ,cv_currency_jpy                                     -- �ʉ�
        ,NULL                                                -- ���[�g
        ,NULL                                                -- ���[�g�^�C�v
        ,g_recon_head_tbl(1).terms_name                      -- �x������
        ,g_recon_head_tbl(1).recon_slip_num                  -- �E�v
        ,g_recon_head_tbl(1).invoice_number                  -- �d���搿�����ԍ�
        ,g_recon_head_tbl(1).applicant                       -- ���͎�(�]�ƈ��ԍ�)
        ,g_recon_head_tbl(1).pay_group_lookup_code           -- �x���O���[�v
        ,g_recon_head_tbl(1).gl_date                         -- �v���
        ,NULL                                                -- �O���`�[�ԍ�
        ,gd_recon_due_date                                   -- �x���\���
        ,gn_org_id                                           -- �c�ƒP��
        ,cn_created_by                                       -- �쐬��
        ,cd_creation_date                                    -- �쐬��
        ,cn_last_updated_by                                  -- �ŏI�X�V��
        ,cd_last_update_date                                 -- �ŏI�X�V��
        ,cn_last_update_login                                -- �ŏI�X�V���O�C��
        ,cn_request_id                                       -- �v��ID
        ,cn_program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                                       -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date                              -- �v���O�����X�V��
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
  END ins_pay_slip_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_pay_slip_line
   * Description      : A-5.�x���`�[���דo�^
   ***********************************************************************************/
  PROCEDURE ins_pay_slip_line(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pay_slip_line';      -- �v���O������
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
    -- AP������͖��׈ꎞ�\�o�^���[�v
    -- ============================================================
    <<ins_line_loop>>
    FOR ln_ins_line IN 1..g_recon_line_tbl.COUNT LOOP
      -- AP������͖��׈ꎞ�\�ւ̓o�^
      INSERT INTO xx03_payment_slip_lines_if(
           interface_id                                        -- �C���^�[�t�F�C�XID
          ,source                                              -- �쐬��
          ,line_number                                         -- ���הԍ�
          ,slip_line_type                                      -- �E�v�R�[�h
          ,entered_item_amount                                 -- �{�̋��z
          ,entered_tax_amount                                  -- ����Ŋz
          ,description                                         -- �E�v
          ,amount_includes_tax_flag                            -- ����(Y/N)
          ,tax_code                                            -- �ŋ敪�R�[�h
          ,segment1                                            -- ���
          ,segment2                                            -- ����
          ,segment3                                            -- ����Ȗ�
          ,segment4                                            -- �⏕�Ȗ�
          ,segment5                                            -- �ڋq�R�[�h
          ,segment6                                            -- ��ƃR�[�h
          ,segment7                                            -- �\���P
          ,segment8                                            -- �\���Q
          ,incr_decr_reason_code                               -- �������R
          ,recon_reference                                     -- �������ݎQ��
          ,org_id                                              -- �c�ƒP��
          ,created_by                                          -- �쐬��
          ,creation_date                                       -- �쐬��
          ,last_updated_by                                     -- �ŏI�X�V��
          ,last_update_date                                    -- �ŏI�X�V��
          ,last_update_login                                   -- �ŏI�X�V���O�C��
          ,request_id                                          -- �v��ID
          ,program_application_id                              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                                          -- �R���J�����g�E�v���O����ID
          ,program_update_date                                 -- �v���O�����X�V��
          )VALUES(
           gn_recon_head_id                                    -- �C���^�[�t�F�C�XID
          ,gv_slip_type                                        -- �쐬��
          ,ln_ins_line                                         -- ���הԍ�
          ,g_recon_line_tbl(ln_ins_line).summary_code          -- �E�v�R�[�h
          ,g_recon_line_tbl(ln_ins_line).body_amount           -- �{�̋��z
          ,g_recon_line_tbl(ln_ins_line).tax_amount            -- ����Ŋz
          ,g_recon_line_tbl(ln_ins_line).summary               -- �E�v
          ,cv_y_flag                                           -- ����(Y/N)
          ,g_recon_line_tbl(ln_ins_line).tax_class_code        -- �ŋ敪�R�[�h
          ,gv_com_code                                         -- ���
          ,g_recon_line_tbl(ln_ins_line).dept                  -- ����
          ,g_recon_line_tbl(ln_ins_line).account               -- ����Ȗ�
          ,g_recon_line_tbl(ln_ins_line).sub_account           -- �⏕�Ȗ�
          ,gv_cus_dummy                                        -- �ڋq�R�[�h
          ,gv_com_dummy                                        -- ��ƃR�[�h
          ,gv_pre1_dummy                                       -- �\���P
          ,gv_pre2_dummy                                       -- �\���Q
          ,NULL                                                -- �������R
          ,NULL                                                -- �������ݎQ��
          ,gn_org_id                                           -- �c�ƒP��
          ,cn_created_by                                       -- �쐬��
          ,cd_creation_date                                    -- �쐬��
          ,cn_last_updated_by                                  -- �ŏI�X�V��
          ,cd_last_update_date                                 -- �ŏI�X�V��
          ,cn_last_update_login                                -- �ŏI�X�V���O�C��
          ,cn_request_id                                       -- �v��ID
          ,cn_program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                       -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                              -- �v���O�����X�V��
      );
      -- ���팏���Ƀ��[�v�J�E���^���i�[
      gn_normal_cnt := ln_ins_line;       -- ���팏��
    END LOOP ins_line_loop;
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
  END ins_pay_slip_line;
--
  /**********************************************************************************
   * Procedure Name   : import_ap_depart
   * Description      : A-6.AP������̓C���|�[�g
   ***********************************************************************************/
  PROCEDURE import_ap_depart(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'import_ap_depart';      -- �v���O������
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
    ln_request_id     NUMBER;               -- �߂�l�F�v��ID
    lb_result         BOOLEAN;              -- �߂�l�F�ҋ@����
    lv_phase          VARCHAR2(5000);       -- �t�F�[�Y�i���[�U�j
    lv_status         VARCHAR2(5000);       -- �X�e�[�^�X�i���[�U�j
    lv_dev_phase      VARCHAR2(5000);       -- �t�F�[�Y
    lv_dev_status     VARCHAR2(5000);       -- �X�e�[�^�X
    lv_message        VARCHAR2(5000);       -- ���b�Z�[�W
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
    -- 1.�R���J�����g�u������́iAP�j�f�[�^�C���|�[�g�v�𔭍s
    -- ============================================================
    ln_request_id := fnd_request.submit_request( cv_conc_appl
                                                ,cv_conc_prog
                                                ,NULL
                                                ,NULL
                                                ,FALSE
                                                ,gv_slip_type
                                                ,cn_request_id
                                                );
    -- �v��ID��0�ȊO�̏ꍇ�R�~�b�g�𔭍s
    IF ln_request_id != 0 THEN
      COMMIT;
    -- 0�ł���΃G���[���b�Z�[�W
    ELSE
      -- ������́iAP�j�f�[�^�C���|�[�g���s�G���[���b�Z�[�W
      lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                             ,cv_ap_imp_billing_msg
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 2.���s�R���J�����g�̏I����ҋ@
    -- ============================================================
    lb_result := fnd_concurrent.wait_for_request( ln_request_id
                                                 ,5
                                                 ,0
                                                 ,lv_phase
                                                 ,lv_status
                                                 ,lv_dev_phase
                                                 ,lv_dev_status
                                                 ,lv_message
                                                 );
    -- ============================================================
    -- 3.�ꎞ�\�쐬�f�[�^�̍폜
    -- ============================================================
    -- AP������͈ꎞ�\�̍쐬�f�[�^�폜
    DELETE
    FROM    xx03_payment_slips_if       xpsi              -- AP������͈ꎞ�\
    WHERE   xpsi.interface_id    = gn_recon_head_id
    ;
    -- AP������͖��׈ꎞ�\�̍쐬�f�[�^�폜
    DELETE
    FROM    xx03_payment_slip_lines_if  xpsli             -- AP������͖��׈ꎞ�\
    WHERE   xpsli.interface_id   = gn_recon_head_id
    ;
    -- ============================================================
    -- 4.������́iAP�j�f�[�^�C���|�[�g���ʂ̊m�F
    -- ============================================================
    -- �C���|�[�g���ʂ̃X�e�[�^�X���G���[�ł���΃��b�Z�[�W�o��
    IF lv_dev_status = 'ERROR' THEN
      -- ������́iAP�j�f�[�^�C���|�[�g�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            ,cv_ap_imp_msg
                                            ,cv_tkn_request_id
                                            ,ln_request_id
                                            ,cv_tkn_status
                                            ,lv_status
                                            );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 5.�T�������w�b�_�[�X�e�[�^�X�X�V
    -- ============================================================
    UPDATE  xxcok_deduction_recon_head   xdrh                             -- �T�������w�b�_�[���
    SET     xdrh.recon_status            = cv_recon_status_sd             -- �����X�^�[�^�X(���M��)
           ,xdrh.application_date        = TRUNC( SYSDATE )               -- �\����
           ,xdrh.last_updated_by         = cn_last_updated_by             -- �ŏI�X�V��
           ,xdrh.last_update_date        = cd_last_update_date            -- �ŏI�X�V��
           ,xdrh.last_update_login       = cn_last_update_login           -- �ŏI�X�V���O�C��
           ,xdrh.request_id              = cn_request_id                  -- �v��ID
           ,xdrh.program_application_id  = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,xdrh.program_id              = cn_program_id                  -- �R���J�����g�E�v���O����ID
           ,xdrh.program_update_date     = cd_program_update_date         -- �v���O�����X�V��
    WHERE   xdrh.deduction_recon_head_id = gn_recon_head_id
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
  END import_ap_depart;
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
    gv_lock_status                := cv_lock_status_normal; -- ���b�N�X�e�[�^�X
    gd_recon_due_date             := NULL;                  -- �x���\���
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
    -- A-2.�����w�b�_��񒊏o
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
    -- A-3.�������׏�񒊏o
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
    -- ===============================
    -- A-4.�x���`�[�w�b�_�o�^
    -- ===============================
    ins_pay_slip_header(
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
    -- A-5.�x���`�[���דo�^
    -- ===============================
    ins_pay_slip_line(
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
    -- A-6.AP������̓C���|�[�g
    -- ===============================
    import_ap_depart(
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
    -- A-7.�I������
    -- ===============================
    -- �I���X�e�[�^�X���G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      -- ���������̐ݒ�
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
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
    -- �I���X�e�[�^�X���G���[�����b�N�X�e�[�^�X������̏ꍇ
    IF ( lv_retcode = cv_status_error AND
         gv_lock_status = cv_lock_status_normal )
    THEN
      -- �T�������w�b�_�[�X�e�[�^�X����͒��ɍX�V
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- �T�������w�b�_�[���
      SET     xdrh.recon_status            = cv_recon_status_eg             -- �����X�^�[�^�X(���͒�)
             ,xdrh.last_updated_by         = cn_last_updated_by             -- �ŏI�X�V��
             ,xdrh.last_update_date        = cd_last_update_date            -- �ŏI�X�V��
             ,xdrh.last_update_login       = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xdrh.request_id              = cn_request_id                  -- �v��ID
             ,xdrh.program_application_id  = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xdrh.program_id              = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xdrh.program_update_date     = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xdrh.deduction_recon_head_id = gn_recon_head_id
      AND     xdrh.recon_status            = cv_recon_status_sg
      ;
      -- �X�V���R�~�b�g
      COMMIT;
    END IF;
--
    -- ===============================
    -- 1.�����������b�Z�[�W�o��
    -- ===============================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
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
                                           ,iv_name         => cv_success_rec_msg
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
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.�x���`�[�ԍ��o��
    -- ===============================
    -- �x���`�[�ԍ����擾����(�����w�b�_���1�����o�ł��Ă����ꍇ)�A�X�e�[�^�X������̏ꍇ
    IF ( g_recon_head_tbl.COUNT = 1 AND
         lv_retcode = cv_status_normal )
    THEN
      -- �x���`�[�ԍ����o�͂���
      gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                             ,iv_name         => cv_slip_num_msg
                                             ,iv_token_name1  => cv_tkn_slip_num
                                             ,iv_token_value1 => g_recon_head_tbl(1).recon_slip_num
                                             );
      FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => gv_out_msg
      );
    END IF;
    -- ===============================
    -- 3.�����I�����b�Z�[�W
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
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
END XXCOK024A24C;
/
