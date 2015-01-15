CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG3
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg3(body)
 * Description      : ���ʊ֐��i��v�j
 * MD.070           : MD070_IPO_CFO_001_���ʊ֐���`��
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  init_proc                 P           ���ʏ�������
 *  chk_period_status         P           �d��쐬�p��v���ԃ`�F�b�N
 *  chk_gl_if_status          P           �d��쐬�pGL�A�g�`�F�b�N
 *  chk_ap_period_status      P           AP�������쐬�p��v���ԃ`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCFO_COMMON_PKG3';  -- �p�b�P�[�W��
--
  cv_msg_kbn_ccp         CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfo         CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- ���b�Z�[�W
  cv_msg_cfo_00001       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cfo_00015       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';  -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00032       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00032';  -- �f�[�^�擾�G���[���b�Z�[�W
  cv_msg_cfo_10038       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10038';  -- �݌ɉ�v���ԃ`�F�b�N�G���[���b�Z�[�W
  cv_msg_cfo_10039       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10039';  -- AP��v���ԃ`�F�b�N�G���[���b�Z�[�W
  cv_msg_cfo_10044       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10044';  -- GL��v���ԃ`�F�b�N�G���[���b�Z�[�W
  cv_msg_cfo_10045       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10045';  -- GL�A�g�`�F�b�N�G���[���b�Z�[�W
  --�g�[�N��
  cv_tkn_prof            CONSTANT VARCHAR2(10)  := 'PROF_NAME';         -- �v���t�@�C���`�F�b�N
  cv_tkn_data            CONSTANT VARCHAR2(10)  := 'DATA';              -- �G���[�f�[�^�̐���
  cv_tkn_param           CONSTANT VARCHAR2(10)  := 'PARAM';             -- ���̓p�����[�^
  --
  cv_set_of_bks_name     CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11156';  -- ��v���떼
  --
  ct_sqlgl               CONSTANT fnd_application.application_short_name%TYPE    := 'SQLGL'; --GL�A�v���Z�k��
  ct_sqlap               CONSTANT fnd_application.application_short_name%TYPE    := 'SQLAP'; --AP�A�v���Z�k��
  ct_closing_status_o    CONSTANT gl_period_statuses.closing_status%TYPE         := 'O';     --O:�I�[�v��
  ct_adjust_flag_n       CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N';     --N:�������ԈȊO
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ���ʏ�������
   ***********************************************************************************/
  PROCEDURE init_proc(
      ov_company_code_mfg         OUT VARCHAR2  -- ��ЃR�[�h�i�H��j
    , ov_aff5_customer_dummy      OUT VARCHAR2  -- �ڋq�R�[�h_�_�~�[�l
    , ov_aff6_company_dummy       OUT VARCHAR2  -- ��ƃR�[�h_�_�~�[�l
    , ov_aff7_preliminary1_dummy  OUT VARCHAR2  -- �\��1_�_�~�[�l
    , ov_aff8_preliminary2_dummy  OUT VARCHAR2  -- �\��2_�_�~�[�l
    , ov_je_invoice_source_mfg    OUT VARCHAR2  -- �d��\�[�X_���Y�V�X�e��
    , on_org_id_mfg               OUT NUMBER    -- ���YORG_ID
    , on_sales_set_of_bks_id      OUT NUMBER    -- �c�ƃV�X�e����v����ID
    , ov_sales_set_of_bks_name    OUT VARCHAR2  -- �c�ƃV�X�e����v���떼
    , ov_currency_code            OUT VARCHAR2  -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
    , od_process_date             OUT DATE      -- �Ɩ����t
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF1_COMPANY_CODE_MFG';    -- ��ЃR�[�h�i�H��j
    cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF5_CUSTOMER_DUMMY';      -- �ڋq�R�[�h_�_�~�[�l
    cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF6_COMPANY_DUMMY';       -- ��ƃR�[�h_�_�~�[�l
    cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF7_PRELIMINARY1_DUMMY';  -- �\��1_�_�~�[�l
    cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF8_PRELIMINARY2_DUMMY';  -- �\��2_�_�~�[�l
    cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_INVOICE_SOURCE_MFG';    -- �d��\�[�X_���Y�V�X�e��
    cv_profile_name_07          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';               -- ���YORG_ID
    cv_profile_name_08          CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                -- �c�ƃV�X�e����v����ID
--
    -- *** ���[�J���ϐ� ***
    ln_sales_set_of_bks_id            NUMBER(15);
    lv_name                           VARCHAR2(30);
    lv_currency_code                  VARCHAR2(15);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- 2-1.  �v���t�@�C���l�̎擾�i�J�X�^���E�v���t�@�C���j
    --==============================================================
    -- ��ЃR�[�h�i�H��j
    ov_company_code_mfg          := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF ( ov_company_code_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_01 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �ڋq�R�[�h_�_�~�[�l
    ov_aff5_customer_dummy       := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF ( ov_aff5_customer_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_02 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ��ƃR�[�h_�_�~�[�l
    ov_aff6_company_dummy        := FND_PROFILE.VALUE( cv_profile_name_03 );
    IF ( ov_aff6_company_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_03 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �\��1_�_�~�[�l
    ov_aff7_preliminary1_dummy   := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF ( ov_aff7_preliminary1_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_04 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �\��2_�_�~�[�l
    ov_aff8_preliminary2_dummy   := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF ( ov_aff8_preliminary2_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_05 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �d��\�[�X_���Y�V�X�e��
    ov_je_invoice_source_mfg     := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF ( ov_je_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_06 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-2.  �v���t�@�C���l�̎擾�i���ʁj
    --==============================================================
    -- ���YORG_ID
    on_org_id_mfg                := TO_NUMBER(FND_PROFILE.VALUE( cv_profile_name_07 ));
    IF ( on_org_id_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_07 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �c�ƃV�X�e����v����ID
    ln_sales_set_of_bks_id       := TO_NUMBER(FND_PROFILE.VALUE( cv_profile_name_08 ));
    on_sales_set_of_bks_id       := ln_sales_set_of_bks_id;
    IF ( on_sales_set_of_bks_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_profile_name_08 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-4.  ��v���떼�A�@�\�ʉ݃R�[�h�̎擾
    --==============================================================
    BEGIN
      SELECT name                              --��v���떼
            ,currency_code                     --�@�\�ʉ݃R�[�h
        INTO lv_name
            ,lv_currency_code
        FROM gl_sets_of_books
       WHERE set_of_books_id = ln_sales_set_of_bks_id;
--
      -- �c�ƃV�X�e����v���떼
      ov_sales_set_of_bks_name   := lv_name;
      -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
      ov_currency_code           := lv_currency_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                            ,cv_msg_cfo_00032  -- �f�[�^�擾�G���[
                                            ,cv_tkn_data       -- �g�[�N��'DATA'
                                            ,cv_set_of_bks_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 2-5.  �Ɩ����t�̎擾
    --==============================================================
    -- �Ɩ����t
    od_process_date              := xxccp_common_pkg2.get_process_date;
--
    IF ( od_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- �A�v���P�[�V�����Z�k��
                                            ,cv_msg_cfo_00015);    -- ���b�Z�[�W�FAPP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_status
   * Description      : �d��쐬�p��v���ԃ`�F�b�N
   ***********************************************************************************/
  -- �d��쐬�p��v���ԃ`�F�b�N
  PROCEDURE chk_period_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_status'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_close_date                     VARCHAR2(6);  -- OPM�݌ɉ�v����CLOSE�N��(yyyymm)
    lv_in_period_name                 VARCHAR2(6);  -- ��v���ԔN��(yyyymm)
    lv_status_code                    VARCHAR2(1);  -- GL��v���Ԃ̃X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- 2.  ���ʊ֐��iOPM�݌ɉ�v����CLOSE�N���擾�֐��j
    --==============================================================
    -- ���ʊ֐�����OPM�݌ɉ�v����CLOSE�N�����擾
    lv_close_date          := xxcmn_common_pkg.get_opminv_close_period;
--
    -- IN�p�����[�^�̉�v���ԁiYYYY-MM)��"YYYYMM"�`���ɕύX
    lv_in_period_name      := REPLACE(iv_period_name,'-');
--
    -- ��v���Ԃ���v���Ȃ��ꍇ�A�G���[���b�Z�[�W���o��
    IF ( lv_close_date <> lv_in_period_name ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_10038     -- ���b�Z�[�W�FAPP-XXCFO1-10038
                                           ,iv_token_name1  => cv_tkn_param         -- �g�[�N���R�[�h
                                           ,iv_token_value1 => iv_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.  ��v���ԃX�e�[�^�X���m�F
    --==============================================================
    BEGIN
      SELECT gps.closing_status         AS status  -- �X�e�[�^�X
      INTO   lv_status_code
      FROM   gl_period_statuses gps                -- ��v���ԃX�e�[�^�X
            ,fnd_application    fa                 -- �A�v���P�[�V����
      WHERE  gps.application_id         = fa.application_id
      AND    fa.application_short_name  = ct_sqlgl                -- �A�v���P�[�V�����Z�k���uSQLGL�v
      AND    gps.adjustment_period_flag = ct_adjust_flag_n        -- �����t���O��'N'
      AND    gps.set_of_books_id        = in_sales_set_of_bks_id  -- IN�p����v����ID
      AND    gps.period_name            = iv_period_name          -- ��v����
      ;
--
      -- �X�e�[�^�X���u�I�[�v���v�łȂ��ꍇ�A�G���[���b�Z�[�W���o��
      IF ( lv_status_code <> ct_closing_status_o ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_cfo_10044     -- ���b�Z�[�W�FAPP-XXCFO1-10044
                                             ,iv_token_name1  => cv_tkn_param         -- �g�[�N���R�[�h
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_period_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_gl_if_status
   * Description      : �d��쐬�pGL�A�g�`�F�b�N
   ***********************************************************************************/
  -- �d��쐬�pGL�A�g�`�F�b�N
  PROCEDURE chk_gl_if_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , iv_func_name                IN  VARCHAR2  -- �@�\���i�R���J�����g�Z�k���j
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gl_if_status'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_y                    CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ���[�J���ϐ� ***
    ln_count                     NUMBER DEFAULT 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- 2.  �d��A�g�����m�F
    --==============================================================
    BEGIN
      SELECT COUNT(1)
      INTO   ln_count
      FROM   xxcfo_mfg_if_control xmic             -- �A�g�Ǘ��e�[�u��
      WHERE  xmic.program_name           = iv_func_name            -- IN�p���@�\��
      AND    xmic.set_of_books_id        = in_sales_set_of_bks_id  -- IN�p����v����ID
      AND    xmic.period_name            = iv_period_name          -- IN�p����v����
      AND    xmic.gl_process_flag        = cv_flag_y               -- ������
      ;
--
      -- �Y���f�[�^���擾�o�����ꍇ�A�G���[���b�Z�[�W���o��
      IF ( ln_count <> 0 ) THEN 
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_cfo_10045     -- ���b�Z�[�W�FAPP-XXCFO1-10045
                                             ,iv_token_name1  => cv_tkn_param         -- �g�[�N���R�[�h
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_gl_if_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_ap_period_status
   * Description      : AP�������쐬�p��v���ԃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_ap_period_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ap_period_status'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_close_date                     VARCHAR2(6);  -- OPM�݌ɉ�v����CLOSE�N��(yyyymm)
    lv_in_period_name                 VARCHAR2(6);  -- ��v���ԔN��(yyyymm)
    lv_status_code                    VARCHAR2(1);  -- AP��v���Ԃ̃X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- 2.  ���ʊ֐��iOPM�݌ɉ�v����CLOSE�N���擾�֐��j
    --==============================================================
    -- ���ʊ֐�����OPM�݌ɉ�v����CLOSE�N�����擾
    lv_close_date          := xxcmn_common_pkg.get_opminv_close_period;
--
    -- IN�p�����[�^�̉�v���ԁiYYYY-MM)��"YYYYMM"�`���ɕύX
    lv_in_period_name      := REPLACE(iv_period_name,'-');
--
    -- ��v���Ԃ���v���Ȃ��ꍇ�A�G���[���b�Z�[�W���o��
    IF ( lv_close_date <> lv_in_period_name ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_cfo_10038     -- ���b�Z�[�W�FAPP-XXCFO1-10038
                                           ,iv_token_name1  => cv_tkn_param         -- �g�[�N���R�[�h
                                           ,iv_token_value1 => iv_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.  ��v���ԃX�e�[�^�X���m�F
    --==============================================================
    BEGIN
      SELECT gps.closing_status         AS status  -- �X�e�[�^�X
      INTO   lv_status_code
      FROM   gl_period_statuses gps                -- ��v���ԃX�e�[�^�X
            ,fnd_application    fa                 -- �A�v���P�[�V����
      WHERE  gps.application_id         = fa.application_id
      AND    fa.application_short_name  = ct_sqlap                -- �A�v���P�[�V�����Z�k���uSQLAP�v
      AND    gps.adjustment_period_flag = ct_adjust_flag_n        -- �����t���O��'N'
      AND    gps.set_of_books_id        = in_sales_set_of_bks_id  -- IN�p����v����ID
      AND    gps.period_name            = iv_period_name          -- ��v����
      ;
--
      -- �X�e�[�^�X���u�I�[�v���v�łȂ��ꍇ�A�G���[���b�Z�[�W���o��
      IF ( lv_status_code <> ct_closing_status_o ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_cfo_10039     -- ���b�Z�[�W�FAPP-XXCFO1-10039
                                             ,iv_token_name1  => cv_tkn_param         -- �g�[�N���R�[�h
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_ap_period_status;
--
END XXCFO_COMMON_PKG3;
/
