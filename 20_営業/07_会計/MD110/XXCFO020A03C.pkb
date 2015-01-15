CREATE OR REPLACE PACKAGE BODY XXCFO020A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A03C(body)
 * Description      : �d�����юd��IF�쐬
 * MD.050           : �d�����юd��IF�쐬<MD050_CFO_020_A03>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_period_name      ��v���ԃ`�F�b�N(A-2)
 *  get_gl_interface_data  �d��OIF��񒊏o(A-3,4)
 *  ins_gl_interface       �d��OIF�o�^_�ؕ��E�ݕ�(A-5,6)
 *  upd_inv_trn_data       ���Y����f�[�^�X�V(A-7)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-17    1.0   T.Kobori        �V�K�쐬
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
  gn_target_cnt    NUMBER DEFAULT 0;       -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;       -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;       -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;       -- �X�L�b�v����
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A03C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  -- ����
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_10035            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10035';        -- �f�[�^�擾�G���[���b�Z�[�W
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- �f�[�^�X�V�G���[
  cv_msg_cfo_10043            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10043';        -- �Ώۃf�[�^�����G���[
  cv_msg_cfo_10047            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10047';        -- ���ʊ֐��G���[
  cv_msg_cfo_10052            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10052';        -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';        -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';        -- �����������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';        -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';        -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';        -- ����I�����b�Z�[�W
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';        -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
--
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';              -- �g�[�N���F�p�����[�^��
  cv_tkn_param_val            CONSTANT VARCHAR2(20)  := 'PARAM_VAL';               -- �g�[�N���F�p�����[�^�l
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';               -- �g�[�N���F�v���t�@�C����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- �g�[�N���FSQL�G���[���b�Z�[�W
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                   -- �g�[�N���F�e�[�u����
  cv_tkn_data                 CONSTANT VARCHAR2(20)  := 'DATA';                    -- �g�[�N���F�f�[�^
  cv_tkn_item                 CONSTANT VARCHAR2(20)  := 'ITEM';                    -- �g�[�N���F�A�C�e��
  cv_tkn_key                  CONSTANT VARCHAR2(20)  := 'KEY';                     -- �g�[�N���F�L�[
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                   -- �g�[�N���F����
  -- CCID
  cv_tkn_process_date         CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';            -- �g�[�N���F������
  cv_tkn_com_code             CONSTANT VARCHAR2(20)  := 'COM_CODE';                -- �g�[�N���F��ЃR�[�h
  cv_tkn_dept_code            CONSTANT VARCHAR2(20)  := 'DEPT_CODE';               -- �g�[�N���F����R�[�h
  cv_tkn_acc_code             CONSTANT VARCHAR2(20)  := 'ACC_CODE';                -- �g�[�N���F����ȖڃR�[�h
  cv_tkn_ass_code             CONSTANT VARCHAR2(20)  := 'ASS_CODE';                -- �g�[�N���F�⏕�ȖڃR�[�h
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';               -- �g�[�N���F�ڋq�R�[�h
  cv_tkn_ent_code             CONSTANT VARCHAR2(20)  := 'ENT_CODE';                -- �g�[�N���F��ƃR�[�h
  cv_tkn_res1_code            CONSTANT VARCHAR2(20)  := 'RES1_CODE';               -- �g�[�N���F�\���P�R�[�h
  cv_tkn_res2_code            CONSTANT VARCHAR2(20)  := 'RES2_CODE';               -- �g�[�N���F�\���Q�R�[�h
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';      -- �d��p�^�[���F�d�����ѕ\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_PO';     -- XXCFO: �d��J�e�S��_�d��
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
--
  -- ���b�Z�[�W�o�͒l
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '�d��OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '����ԕi����';
  cv_msg_out_data_03         CONSTANT VARCHAR2(30)  := '�A�g�Ǘ��e�[�u��';
  cv_msg_out_data_04         CONSTANT VARCHAR2(30)  := '�d������view2';
  --
  cv_msg_out_item_01         CONSTANT VARCHAR2(30)  := '���ID';
  cv_msg_out_item_02         CONSTANT VARCHAR2(30)  := '�d����ID';
--
  -- �d��p�^�[���m�F�p
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
--
  -- �i�ڋ敪
  cv_item_class_2             CONSTANT VARCHAR2(1)   := '2';           -- ����
  cv_item_class_5             CONSTANT VARCHAR2(1)   := '5';           -- ���i
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --�������t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�v���t�@�C���擾
  gn_org_id_sales             NUMBER        DEFAULT NULL;    -- �g�DID (�c��)
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- ��ЃR�[�h�i�H��j
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��1_�_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��2_�_�~�[�l
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- �d��\�[�X_���Y�V�X�e��
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- �g�DID (���Y)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- �c�ƃV�X�e����v����ID
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e����v���떼
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
  gv_je_ptn_purchasing        VARCHAR2(100) DEFAULT NULL;    -- �d��p�^�[���F�d�����ѕ\
  gv_je_category_mfg_po       VARCHAR2(100) DEFAULT NULL;    -- XXCFO: �d��J�e�S��_�d��
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
  gd_target_date_last         DATE          DEFAULT NULL;    -- ��v����_�ŏI��
  gv_period_name              VARCHAR2(7);                   -- IN�p����v����
--
  gt_attribute8               gl_interface.attribute8%TYPE;  -- �d��P�ʁF�Q�ƍ���1(�d��L�[)
  gv_description_dr           VARCHAR2(100) DEFAULT NULL;    -- �d��P�ʁF�E�v�i�ؕ��j
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�^
  -- ===============================
--
  -- ���Y����f�[�^�X�V�L�[�i�[�p
  TYPE g_xxpo_rcv_and_rtn_txns_rec IS RECORD
    (
     txns_id                 NUMBER    -- ���ID
    );
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�ϐ�
  -- ===============================
--
  -- ���Y����f�[�^�X�V�L�[�i�[�pPL/SQL�\
  TYPE g_xxpo_rcv_and_rtn_txns_ttype IS TABLE OF g_xxpo_rcv_and_rtn_txns_rec INDEX BY PLS_INTEGER;
  g_xxpo_rcv_and_rtn_txns_tab                    g_xxpo_rcv_and_rtn_txns_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
--
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- 1.(1)  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_out    -- ���b�Z�[�W�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_log    -- ���O�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(1)  �Ɩ��������t�A�v���t�@�C���l�̎擾
    --==============================================================
    xxcfo_common_pkg3.init_proc(
        ov_company_code_mfg         =>  gv_company_code_mfg         -- ��ЃR�[�h�i�H��j
      , ov_aff5_customer_dummy      =>  gv_aff5_customer_dummy      -- �ڋq�R�[�h_�_�~�[�l
      , ov_aff6_company_dummy       =>  gv_aff6_company_dummy       -- ��ƃR�[�h_�_�~�[�l
      , ov_aff7_preliminary1_dummy  =>  gv_aff7_preliminary1_dummy  -- �\��1_�_�~�[�l
      , ov_aff8_preliminary2_dummy  =>  gv_aff8_preliminary2_dummy  -- �\��2_�_�~�[�l
      , ov_je_invoice_source_mfg    =>  gv_je_invoice_source_mfg    -- �d��\�[�X_���Y�V�X�e��
      , on_org_id_mfg               =>  gn_org_id_mfg               -- ���YORG_ID
      , on_sales_set_of_bks_id      =>  gn_sales_set_of_bks_id      -- �c�ƃV�X�e����v����ID
      , ov_sales_set_of_bks_name    =>  gv_sales_set_of_bks_name    -- �c�ƃV�X�e����v���떼
      , ov_currency_code            =>  gv_currency_code            -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
      , od_process_date             =>  gd_process_date             -- �Ɩ����t
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(2)  �v���t�@�C���l�̎擾
    --==============================================================
    -- �d��p�^�[���F�d�����ѕ\
    gv_je_ptn_purchasing  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_purchasing IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: �d��J�e�S��_�d��
    gv_je_category_mfg_po  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_po IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- ���̓p�����[�^�̉�v���Ԃ���A�d��OIF�o�^�p�Ɋi�[
    gv_period_name       := iv_period_name;
    gd_target_date_last  := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format));
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_period_name
   * Description      : ��v���ԃ`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_period_name(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_period_name'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- 1.  �d��쐬�p��v���ԃ`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_period_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.  �d��쐬�pGL�A�g�`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_gl_if_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , iv_func_name                    => cv_pkg_name                 -- �@�\���i�R���J�����g�Z�k���j
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
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
  END check_period_name;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      :�d��OIF�o�^_�ؕ��E�ݕ�(A-5,6)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    in_prc_mode         IN  NUMBER,                                     --   1.�������[�h
    it_genka_sagaku     IN  gl_interface.entered_dr%TYPE,               --   2.�������z
    it_department_code  IN  xxpo_rcv_and_rtn_txns.department_code%TYPE, --   3.����R�[�h
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE,             --   4.�i�ڋ敪
    it_vendor_code      IN  po_vendors.segment1%TYPE,                   --   5.�d����R�[�h
    it_vendor_name      IN  xxcmn_vendors.vendor_short_name%TYPE,       --   6.�d���於
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- �v���O������
    cv_status_new        CONSTANT VARCHAR2(3)   := 'NEW';              -- �X�e�[�^�X
    cv_actual_flag       CONSTANT VARCHAR2(1)   := 'A';                -- �c���^�C�v
    cv_attribute1        CONSTANT VARCHAR2(4)   := '0000';             -- �ŋ敪
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
    cn_group_id_1        CONSTANT NUMBER        := 1;
--
    -- *** ���[�J���ϐ� ***
    lv_company_code          VARCHAR2(100) DEFAULT NULL;                 -- ���
    lv_department_code       VARCHAR2(100) DEFAULT NULL;                 -- ����
    lv_account_title         VARCHAR2(100) DEFAULT NULL;                 -- ����Ȗ�
    lv_account_subsidiary    VARCHAR2(100) DEFAULT NULL;                 -- �⏕�Ȗ�
    lv_description           VARCHAR2(100) DEFAULT NULL;                 -- �E�v
    ln_ccid                  NUMBER        DEFAULT NULL;                 -- CCID
    lt_entered_dr            gl_interface.entered_dr%TYPE DEFAULT 0;     -- �ؕ����z
    lt_entered_cr            gl_interface.entered_cr%TYPE DEFAULT 0;     -- �ݕ����z
    lv_line_no               VARCHAR2(100) DEFAULT NULL;                 -- �s�ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�������[�h���u�ؕ��v�̏ꍇ
    IF in_prc_mode = 1 THEN 
      -- �d��OIF�̃V�[�P���X���̔�
      SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL)
      INTO   gt_attribute8
      FROM   DUAL;
--
      -- �s�ԍ���ݒ�
      lv_line_no := cv_line_no_01;
--
      --�������z���}�C�i�X�̏ꍇ�A�ݕ����z�́u�������z�v��ݒ�
      IF it_genka_sagaku < 0 THEN
        lt_entered_cr   := ABS(it_genka_sagaku);
      ELSE
        lt_entered_dr   := it_genka_sagaku;
      END IF;
    --�������[�h���u�ݕ��v�̏ꍇ
    ELSIF in_prc_mode = 2 THEN
      -- �s�ԍ���ݒ�
      lv_line_no := cv_line_no_02;
--
      --�������z���}�C�i�X�̏ꍇ�A�ؕ����z�́u�������z�v��ݒ�
      IF it_genka_sagaku < 0 THEN
        lt_entered_dr   := ABS(it_genka_sagaku);
      ELSE
        lt_entered_cr   := it_genka_sagaku;
      END IF;
--
    END IF;
--
    -- �������z�d��̉Ȗڏ������ʊ֐��Ŏ擾
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing             -- (IN)���[
      , iv_class_code               =>  it_item_class_code               -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                             -- (IN)���i�敪
      , iv_reason_code              =>  NULL                             -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_02                 -- (IN)�d��p�^�[�� �F2
      , iv_line_no                  =>  lv_line_no                       -- (IN)�s�ԍ� �F1�E2
      , iv_gloif_dr_cr              =>  NULL                             -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  NULL                             -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code                  -- (OUT)���
      , ov_department_code          =>  lv_department_code               -- (OUT)����
      , ov_account_title            =>  lv_account_title                 -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary            -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description                   -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                       -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                        -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                        -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �������z�d���CCID���擾
    ln_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_target_date_last              -- ������
                      , iv_segment1  => lv_company_code                  -- ��ЃR�[�h
                      , iv_segment2  => lv_department_code               -- ����R�[�h
                      , iv_segment3  => lv_account_title                 -- ����ȖڃR�[�h
                      , iv_segment4  => lv_account_subsidiary            -- �⏕�ȖڃR�[�h
                      , iv_segment5  => gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                      , iv_segment6  => gv_aff6_company_dummy            -- ��ƃR�[�h�_�~�[�l
                      , iv_segment7  => gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                      , iv_segment8  => gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                      );
    IF ( ln_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcfo
                      , iv_name         => cv_msg_cfo_10052            -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_last         -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => lv_company_code             -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => lv_department_code          -- ����R�[�h
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => lv_account_title            -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => lv_account_subsidiary       -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy      -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy       -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy  -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy  -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�������[�h���u�ؕ��v�̏ꍇ
    IF in_prc_mode = 1 THEN     
        --�ؕ��̓K�p��ێ�����
        gv_description_dr := lv_description;
    END IF;
--
    --==============================================================
    -- �d��OIF�o�^_�ؕ��E�ݕ�(A-5,6)
    --==============================================================
--
    BEGIN
      INSERT INTO gl_interface(
          status
         ,set_of_books_id
         ,accounting_date
         ,currency_code
         ,date_created
         ,created_by
         ,actual_flag
         ,user_je_category_name
         ,user_je_source_name
         ,code_combination_id
         ,entered_dr
         ,entered_cr
         ,reference1
         ,reference2
         ,reference4
         ,reference5
         ,reference10
         ,period_name
         ,request_id
         ,attribute1
         ,attribute3
         ,attribute4
         ,attribute5
         ,attribute8
         ,context
         ,group_id
      )VALUES (
        cv_status_new                   -- �X�e�[�^�X
       ,gn_sales_set_of_bks_id          -- ��v����ID
       ,gd_target_date_last             -- �L����
       ,gv_currency_code                -- �ʉ݃R�[�h
       ,SYSDATE                         -- �V�K�쐬��
       ,cn_created_by                   -- �V�K�쐬��
       ,cv_actual_flag                  -- �c���^�C�v
       ,gv_je_category_mfg_po           -- �d��J�e�S����
       ,gv_je_invoice_source_mfg        -- �d��\�[�X��
       ,ln_ccid                         -- CCID
       ,lt_entered_dr                   -- �ؕ����z
       ,lt_entered_cr                   -- �ݕ����z
       ,gv_je_category_mfg_po || '_' || gv_period_name
                                        -- �o�b�`��
       ,gv_je_category_mfg_po || '_' || gv_period_name
                                        -- �o�b�`�E�v
       ,gt_attribute8                   -- �d��
       ,gv_description_dr || '_' || it_department_code || '_' || it_vendor_code || ' ' || it_vendor_name
                                        -- ���t�@�����X5�i�d�󖼓E�v�j
       ,lv_description  || it_vendor_code || it_vendor_name
                                        -- ���t�@�����X10�i�d�󖾍דE�v�j
       ,gv_period_name                  -- ��v���Ԗ�
       ,cn_request_id                   -- �v��ID
       ,cv_attribute1                   -- ����1�i����ŃR�[�h�j
       ,NULL                            -- ����3�i�`�[�ԍ��j
       ,it_department_code              -- ����4�i�N�[����j
       ,NULL                            -- ����5�i���[�UID�j
       ,gt_attribute8                   -- �Q�ƍ���1(�d��L�[)
       ,gv_sales_set_of_bks_name        -- �R���e�L�X�g
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_00024              -- �o�^�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_01            -- �d��OIF
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQL�G���[
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : ���Y����f�[�^�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_trn_data'; -- �v���O������
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
    ln_upd_cnt      NUMBER;
    lt_txns_id      xxpo_rcv_and_rtn_txns.txns_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- =========================================================
    -- ����ԕi���уA�h�I���ɕR�t���L�[�̒l��ݒ�i�d��L�[�j
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_xxpo_rcv_and_rtn_txns_tab.COUNT LOOP
      BEGIN
        -- ����ԕi���уA�h�I���ɑ΂��čs���b�N���擾
        SELECT xrrt.txns_id
        INTO   lt_txns_id
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.txns_id      = g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ���b�N�G���[
                    , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                    , iv_token_value1 => cv_msg_out_data_02                  -- ����ԕi����
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_xxpo_rcv_and_rtn_txns_tab.COUNT
        -- ����f�[�^�����ʂ����ӂȒl������ԕi���тɍX�V
        UPDATE xxpo_rcv_and_rtn_txns xrrt
        SET    xrrt.journal_key  = gt_attribute8                  -- �u�d��OIF�o�^�v�ō̔Ԃ����Q�ƍ���1 (�d��L�[)
        WHERE  xrrt.txns_id      = g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                  , iv_token_value1 => cv_msg_out_data_02                  -- ����ԕi����
                  , iv_token_name2  => cv_tkn_item                         -- �A�C�e��
                  , iv_token_value2 => cv_msg_out_item_01                  -- ���ID
                  , iv_token_name3  => cv_tkn_key                          -- �L�[
                  , iv_token_value3 => g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ���팏���J�E���g
    gn_normal_cnt := gn_normal_cnt + g_xxpo_rcv_and_rtn_txns_tab.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_inv_trn_data;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_interface_data
   * Description      : �d��OIF��񒊏o(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_gl_interface_data(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_interface_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cv_doc_type_porc         CONSTANT VARCHAR2(30)  := 'PORC';           -- �w���֘A
    cv_doc_type_adji         CONSTANT VARCHAR2(30)  := 'ADJI';           -- �݌ɒ���
    cv_reason_cd_x201        CONSTANT VARCHAR2(30)  := 'X201';           -- �d����ԕi
    cv_txns_type_2           CONSTANT VARCHAR2(1)   := '2';              -- ����敪�i2:�d����ԕi�j
    cv_txns_type_3           CONSTANT VARCHAR2(1)   := '3';              -- ����敪�i3:�����Ȃ��ԕi�j
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- �����t���O
    cn_prc_mode1             CONSTANT NUMBER        := 1;                -- �������[�h�i�ؕ��j
    cn_prc_mode2             CONSTANT NUMBER        := 2;                -- �������[�h�i�ݕ��j
--
    -- *** ���[�J���ϐ� ***
    ln_count                 NUMBER        DEFAULT 0;                    -- ���o�����̃J�E���g
    ln_out_count             NUMBER        DEFAULT 0;                    -- ����u���[�N�L�[�����̃J�E���g
    ld_opminv_date           DATE          DEFAULT NULL;                 -- OPM�݌ɉ�v���Ԃ̏I����
    lt_genka_sagaku          gl_interface.entered_dr%TYPE DEFAULT 0;     -- �d��P�ʁF�������z
    lt_department_code       xxpo_rcv_and_rtn_txns.department_code%TYPE; -- �d��P�ʁF����R�[�h
    lt_item_class_code       mtl_categories_b.segment1%TYPE;             -- �d��P�ʁF�i�ڋ敪
    lt_vendor_code           po_vendors.segment1%TYPE;                   -- �d��P�ʁF�d����R�[�h
    lt_vendor_name           xxcmn_vendors.vendor_short_name%TYPE;       -- �d��P�ʁF�d���於
    lt_vendor_id             xxpo_rcv_and_rtn_txns.vendor_id%TYPE;       -- �d��P�ʁF�d����ID
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\���iSELECT���@�A�A��UNION ALL�j
    CURSOR get_gl_interface_cur
    IS
      SELECT
             trn.department_code                                    AS department_code    -- ����
            ,trn.vendor_id                                          AS vendor_id          -- �d����ID
            ,trn.item_class_code                                    AS item_class_code    -- �i�ڋ敪
            ,trn.txns_id                                            AS txns_id            -- ���ID
            ,ROUND((trn.stnd_unit_price * (SUM(trn.trans_qty) * trn.rcv_pay_div))
             - (trn.unit_price * (SUM(trn.trans_qty) * trn.rcv_pay_div))) AS genka_sagaku -- �������z
      FROM(
           -- ���o�@�i������сj
           SELECT
                  NVL(xsup.stnd_unit_price, 0)            AS stnd_unit_price    -- �W������
                 ,NVL(itp.trans_qty, 0)                   AS trans_qty          -- �������
                 ,TO_NUMBER(xrpm.rcv_pay_div)             AS rcv_pay_div        -- �󕥋敪
                 ,pla.unit_price                          AS unit_price         -- �P��
                 ,pha.attribute10                         AS department_code    -- ����
                 ,pha.vendor_id                           AS vendor_id          -- �d����ID
                 ,xicv.item_class_code                    AS item_class_code    -- �i�ڋ敪
                 ,TO_NUMBER(rsl.attribute1)               AS txns_id            -- ���ID
           FROM   ic_tran_pnd               itp                -- �ۗ��݌Ƀg�����U�N�V����
                 ,rcv_shipment_lines        rsl                -- �������
                 ,rcv_transactions          rt                 -- ������
                 ,xxcmn_rcv_pay_mst         xrpm               -- �󕥋敪�A�h�I���}�X�^
                 ,po_headers_all            pha                -- �����w�b�_
                 ,po_lines_all              pla                -- ��������
                 ,xxcmn_item_categories5_v  xicv               -- opm�i�ڃJ�e�S���������view5
                 ,xxcmn_stnd_unit_price_v   xsup               -- �W���������view
                 ,po_line_locations_all     plla               -- �����[������
           WHERE  itp.doc_type                    = cv_doc_type_porc
           AND    itp.completed_ind               = cn_completed_ind
           AND    itp.trans_date                  BETWEEN gd_target_date_from
                                                  AND     gd_target_date_to
           AND    rsl.shipment_header_id          = itp.doc_id
           AND    rsl.line_num                    = itp.doc_line
           AND    rt.transaction_id               = itp.line_id
           AND    rt.shipment_line_id             = rsl.shipment_line_id
           AND    itp.doc_type                    = xrpm.doc_type
           AND    rsl.source_document_code        = xrpm.source_document_code
           AND    rt.transaction_type             = xrpm.transaction_type
           AND    pha.po_header_id                = rsl.po_header_id
           AND    pla.po_line_id                  = rsl.po_line_id
           AND    rsl.po_line_location_id         = plla.line_location_id 
           AND    pha.org_id                      = gn_org_id_mfg
           AND    xicv.item_id                    = itp.item_id
           AND    xicv.item_class_code            IN (cv_item_class_2,cv_item_class_5)
           AND    itp.item_id                     = xsup.item_id(+)
           AND    itp.trans_date                  BETWEEN NVL(xsup.start_date_active(+), itp.trans_date)
                                                  AND     NVL(xsup.end_date_active(+), itp.trans_date)
           AND    xrpm.break_col_05               IS NOT NULL
--
           UNION ALL
--
           -- ���o�A�i�d����ԕi�E�����Ȃ��ԕi�j
           SELECT
                  NVL(xsup.stnd_unit_price, 0)            AS stnd_unit_price    -- �W������
                 ,NVL(itc.trans_qty, 0)                   AS trans_qty          -- �������
                 ,ABS(TO_NUMBER(xrpm.rcv_pay_div))        AS rcv_pay_div        -- �󕥋敪
                 ,xrrt.kobki_converted_unit_price         AS unit_price         -- �P��
                 ,xrrt.department_code                    AS department_code    -- ����
                 ,xrrt.vendor_id                          AS vendor_id          -- �d����ID
                 ,xicv.item_class_code                    AS item_class_code    -- �i�ڋ敪
                 ,xrrt.txns_id                            AS txns_id            -- ���ID
           FROM   ic_tran_cmp               itc                -- �����݌Ƀg�����U�N�V����
                 ,ic_adjs_jnl               iaj                -- opm�݌ɒ����W���[�i��
                 ,ic_jrnl_mst               ijm                -- opm�W���[�i���}�X�^
                 ,xxpo_rcv_and_rtn_txns     xrrt               -- ����ԕi���уA�h�I��
                 ,xxcmn_rcv_pay_mst         xrpm               -- �󕥋敪�A�h�I���}�X�^
                 ,po_vendor_sites_all       pvsa               -- �d����T�C�g�A�h�I���}�X�^
                 ,xxcmn_item_categories5_v  xicv               -- opm�i�ڃJ�e�S���������view5
                 ,xxcmn_stnd_unit_price_v   xsup               -- �W���������view
           WHERE  itc.doc_type                    = cv_doc_type_adji
           AND    itc.reason_code                 = cv_reason_cd_x201
           AND    itc.trans_date                  BETWEEN gd_target_date_from
                                                  AND     gd_target_date_to
           AND    iaj.trans_type                  = itc.doc_type
           AND    iaj.doc_id                      = itc.doc_id
           AND    iaj.doc_line                    = itc.doc_line
           AND    ijm.journal_id                  = iaj.journal_id
           AND    TO_CHAR(xrrt.txns_id)           = ijm.attribute1
           AND    xrrt.txns_type                  IN (cv_txns_type_2,cv_txns_type_3)
           AND    xrpm.doc_type                   = itc.doc_type
           AND    xrpm.reason_code                = itc.reason_code
           AND    pvsa.vendor_site_id             = xrrt.factory_id
           AND    pvsa.org_id                     = gn_org_id_mfg
           AND    xicv.item_id                    = itc.item_id
           AND    xicv.item_class_code            IN (cv_item_class_2,cv_item_class_5)
           AND    itc.item_id                     = xsup.item_id(+)
           AND    itc.trans_date                  BETWEEN NVL(xsup.start_date_active(+), itc.trans_date)
                                                  AND     NVL(xsup.end_date_active(+), itc.trans_date)
           AND    xrpm.break_col_05               IS NOT NULL
          ) trn
      GROUP BY
                trn.stnd_unit_price
               ,trn.rcv_pay_div
               ,trn.unit_price
               ,trn.department_code
               ,trn.vendor_id
               ,trn.item_class_code
               ,trn.txns_id
      ORDER BY
                department_code                 -- ����
               ,vendor_id                       -- �d����
               ,item_class_code                 -- �i�ڋ敪
               ,txns_id                         -- �����ID
    ;
    -- GL�d��OIF���i�[�pPL/SQL�\
    TYPE gl_interface_ttype IS TABLE OF get_gl_interface_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gl_interface_tab                    gl_interface_ttype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ���ʊ֐�����OPM�݌ɉ�v����CLOSE�N�����擾���A�I������ݒ�
    ld_opminv_date := LAST_DAY(TO_DATE(xxcmn_common_pkg.get_opminv_close_period ||
                            cv_fdy || cv_e_time,cv_dt_format));
--
    -- ===============================
    -- 1.���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_gl_interface_cur;
    -- �o���N�t�F�b�`
    FETCH get_gl_interface_cur BULK COLLECT INTO gl_interface_tab;
    -- �J�[�\���N���[�Y
    IF ( get_gl_interface_cur%ISOPEN ) THEN
      CLOSE get_gl_interface_cur;
    END IF;
--
    <<main_loop>>
    FOR ln_count in 1..gl_interface_tab.COUNT LOOP
--
      -- �u���C�N�L�[���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( ( NVL(lt_department_code,gl_interface_tab(ln_count).department_code)  <> gl_interface_tab(ln_count).department_code )
        OR ( NVL(lt_vendor_id,gl_interface_tab(ln_count).vendor_id)              <> gl_interface_tab(ln_count).vendor_id )
        OR ( NVL(lt_item_class_code,gl_interface_tab(ln_count).item_class_code)  <> gl_interface_tab(ln_count).item_class_code ) )
        AND lt_genka_sagaku <> 0
      THEN
--
        -- ===============================
        -- �d��������擾
        -- ===============================
        BEGIN
          SELECT xv2v.segment1                      -- �d����R�[�h
                ,xv2v.vendor_short_name             -- �d���旪��
          INTO   lt_vendor_code
                ,lt_vendor_name
          FROM   xxcmn_vendors2_v xv2v              -- �d������view2
          WHERE  xv2v.vendor_id = lt_vendor_id      -- �d����ID
          AND    NVL(xv2v.START_DATE_ACTIVE,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xv2v.END_DATE_ACTIVE,ld_opminv_date)   >= ld_opminv_date
          AND    NVL(xv2v.INACTIVE_DATE,ld_opminv_date)     >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- �f�[�^�擾�G���[
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- �d������view2
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- �d����ID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- �d��OIF�o�^_�ؕ�(A-5)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.�������[�h�i�ؕ��j
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.�������z
          it_department_code       => lt_department_code,  -- 3.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 4.�i�ڋ敪
          it_vendor_code           => lt_vendor_code,      -- 5.�d����R�[�h
          it_vendor_name           => lt_vendor_name,      -- 6.�d���於
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �d��OIF�o�^_�ݕ�(A-6)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.�������[�h�i�ݕ��j
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.�������z
          it_department_code       => lt_department_code,  -- 3.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 4.�i�ڋ敪
          it_vendor_code           => lt_vendor_code,      -- 5.�d����R�[�h
          it_vendor_name           => lt_vendor_name,      -- 6.�d���於
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ���Y����f�[�^�X�V(A-7)
        -- ===============================
        upd_inv_trn_data(
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �d��P�ʂ̏������ϐ��̏����������{
        lt_genka_sagaku            := 0;                   -- �d��P�ʁF�������z
        lt_department_code         := NULL;                -- �d��P�ʁF����
        lt_item_class_code         := NULL;                -- �d��P�ʁF�i�ڋ敪
        lt_vendor_id               := NULL;                -- �d��P�ʁF�d����ID
        lt_vendor_code             := NULL;                -- �d��P�ʁF�d����R�[�h
        lt_vendor_name             := NULL;                -- �d��P�ʁF�d���旪��
        gt_attribute8              := NULL;                -- �d��P�ʁF�Q�ƍ��ڂP(�d��L�[)
        gv_description_dr          := NULL;                -- �d��P�ʁF�E�v�i�ؕ��j
--
        ln_out_count               := 0;
        g_xxpo_rcv_and_rtn_txns_tab.DELETE;                -- �d��OIF���i�[�pPL/SQL�\
      END IF;
--
      -- �u�������z�v�̋��z��0�ȊO�̏ꍇ
      IF (gl_interface_tab(ln_count).genka_sagaku <> 0 ) THEN
        -- �����Ώی����J�E���g
        gn_target_cnt := gn_target_cnt +1;
        -- �������z�̐ςݏグ���s��
        lt_genka_sagaku              := lt_genka_sagaku + gl_interface_tab(ln_count).genka_sagaku;  -- �d��P�ʁF�������z
--
        -- �u���ID�v��z��ɕێ�
        ln_out_count :=  ln_out_count + 1;
        g_xxpo_rcv_and_rtn_txns_tab(ln_out_count).txns_id := gl_interface_tab(ln_count).txns_id;    -- �d��P�ʁF���ID
--
        -- �d��P�ʂ̏���ێ�
        lt_department_code           := gl_interface_tab(ln_count).department_code;                 -- �d��P�ʁF����
        lt_vendor_id                 := gl_interface_tab(ln_count).vendor_id;                       -- �d��P�ʁF�d����ID
        lt_item_class_code           := gl_interface_tab(ln_count).item_class_code;                 -- �d��P�ʁF�i�ڋ敪
--
      ELSE
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt := gn_warn_cnt +1;
      END IF;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ln_count = gl_interface_tab.COUNT AND lt_genka_sagaku <> 0 THEN
--
        -- ===============================
        -- �d��������擾
        -- ===============================
        BEGIN
          SELECT xv2v.segment1                      -- �d����R�[�h
                ,xv2v.vendor_short_name             -- �d���旪��
          INTO   lt_vendor_code
                ,lt_vendor_name
          FROM   xxcmn_vendors2_v xv2v              -- �d������view2
          WHERE  xv2v.vendor_id = lt_vendor_id      -- �d����ID
          AND    NVL(xv2v.START_DATE_ACTIVE,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xv2v.END_DATE_ACTIVE,ld_opminv_date)   >= ld_opminv_date
          AND    NVL(xv2v.INACTIVE_DATE,ld_opminv_date)     >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- �f�[�^�擾�G���[
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- �d������view2
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- �d����ID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- �d��OIF�o�^_�ؕ�(A-5)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.�������[�h�i�ؕ��j
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.�������z
          it_department_code       => lt_department_code,  -- 3.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 4.�i�ڋ敪
          it_vendor_code           => lt_vendor_code,      -- 5.�d����R�[�h
          it_vendor_name           => lt_vendor_name,      -- 6.�d���於
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �d��OIF�o�^_�ݕ�(A-6)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.�������[�h�i�ݕ��j
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.�������z
          it_department_code       => lt_department_code,  -- 3.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 4.�i�ڋ敪
          it_vendor_code           => lt_vendor_code,      -- 5.�d����R�[�h
          it_vendor_name           => lt_vendor_name,      -- 6.�d���於
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ���Y����f�[�^�X�V(A-7)
        -- ===============================
        upd_inv_trn_data(
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP main_loop;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�G���[
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcfo              -- 'XXCFO'
                , iv_name         => cv_msg_cfo_10043
                );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
      END IF;
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
      -- �J�[�\���N���[�Y
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_interface_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : �A�g�Ǘ��e�[�u���o�^(A-8)
   ***********************************************************************************/
  PROCEDURE ins_mfg_if_control(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mfg_if_control'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- =====================================
    -- �A�g�Ǘ��e�[�u���ɓo�^
    -- =====================================
    BEGIN
      INSERT INTO xxcfo_mfg_if_control(
         program_name                        -- �@�\��
        ,set_of_books_id                     -- ��v����ID
        ,period_name                         -- ��v����
        ,gl_process_flag                     -- GL�]���t���O
        --WHO�J����
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )VALUES(
         cv_pkg_name                         -- �@�\�� 'XXCFO020A03C'
        ,gn_sales_set_of_bks_id              -- ��v����ID
        ,iv_period_name                      -- ��v����
        ,cv_flag_y                           -- GL�]���t���O
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_00024              -- �o�^�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_03            -- �A�g�Ǘ��e�[�u��
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQL�G���[
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_mfg_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N(A-2)
    -- ===============================
    check_period_name(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �d��OIF��񒊏o(A-3,4)
    -- ===============================
    get_gl_interface_data(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �A�g�Ǘ��e�[�u���o�^(A-8)
    -- ===============================
    ins_mfg_if_control(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name      IN  VARCHAR2       -- 1.��v����
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
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
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name                              -- 1.��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
      gn_warn_cnt     := 0;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_ccp_90006;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
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
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFO020A03C;
/
