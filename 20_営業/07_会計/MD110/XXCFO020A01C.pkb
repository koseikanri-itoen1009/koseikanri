CREATE OR REPLACE PACKAGE BODY XXCFO020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A01C(body)
 * Description      : �󕥂��̑����юd��IF�쐬
 * MD.050           : �󕥂��̑����юd��IF�쐬<MD050_CFO_020_A01>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_account_period   ��v���ԃ`�F�b�N(A-2)
 *  get_trans_data         �d��OIF�p��񒊏o(A-3)
 *  get_siwake_mst         ����Ȗڏ��擾(A-4)
 *  set_gl_interface       �d��OIF�o�^�f�[�^�ݒ�(A-4)
 *  ins_gl_interface       �d��OIF�o�^(A-4)
 *  upd_mfg_tran           ���Y����f�[�^�X�V(A-5)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-11-25    1.0   SCSK H.Itou      �V�K�쐬
 *  2015-01-09    1.1   SCSK A.Uchida    �I�����Ք�̃J�[�\���őΏۂ̑q�ɃR�[�h�̂�
 *                                       ���o���o����悤�C���B
 *  2015-01-29    1.2   SCSK A.Uchida    �V�X�e���e�X�g��Q�Ή�
 *                                       �E�u���o�J�[�\��_���̑��v�̒��o�����ύX
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
  gt_out_msg       fnd_new_messages.message_text%TYPE;
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
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A01C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  -- ���b�Z�[�W�R�[�h
  ct_msg_name_cfo_00001       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  ct_msg_name_cfo_00019       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  ct_msg_name_cfo_00020       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00020';        -- �X�V�G���[
  ct_msg_name_cfo_00024       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  ct_msg_name_cfo_10043       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-10043';        -- �Ώۃf�[�^�����G���[
  ct_msg_name_cfo_10052       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-10052';        -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
  ct_msg_name_ccp_90000       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90000';        -- �Ώی������b�Z�[�W
  ct_msg_name_ccp_90001       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90001';        -- �����������b�Z�[�W
  ct_msg_name_ccp_90002       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90002';        -- �G���[�������b�Z�[�W
  ct_msg_name_ccp_90004       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90004';        -- ����I�����b�Z�[�W
  ct_msg_name_ccp_90005       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90005';        -- �x���I�����b�Z�[�W
  ct_msg_name_ccp_90006       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
--
  -- �g�[�N��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';               -- �g�[�N���F�v���t�@�C����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- �g�[�N���FSQL�G���[���b�Z�[�W
  cv_tkn_err_msg              CONSTANT VARCHAR2(20)  := 'ERR_MSG';                 -- �g�[�N���FSQL�G���[���b�Z�[�W
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                   -- �g�[�N���F�e�[�u����
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
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY2';       -- XXCFO:�d��p�^�[��_�󕥎c���\2
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_ADJI';  -- XXCFO:�d��J�e�S��_�󕥁i���̑��j
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- �ؕ�
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- �ݕ�
--
  -- �e�[�u����
  cv_ic_jrnl_mst             CONSTANT VARCHAR2(30)  := '�W���[�i���}�X�^';
  cv_oe_order_lines_all      CONSTANT VARCHAR2(30)  := '�󒍖���';
  -- ���b�Z�[�W�o�͒l
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '�d��OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '�A�g�Ǘ��e�[�u��';
--
  -- ���ڕҏW�֘A
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --�������t
--
  -- �W�v���@
  cv_mode_1                   CONSTANT VARCHAR2(30) := '1'; -- �`�[��
  cv_mode_2                   CONSTANT VARCHAR2(30) := '2'; -- �q�ɕ�
  cv_mode_3                   CONSTANT VARCHAR2(30) := '3'; -- �����v
  cv_mode_4                   CONSTANT VARCHAR2(30) := '4'; -- �����E�d�����
  -- 2015.01.09 Ver1.1 Add Start 
  cv_item_class_code_4        CONSTANT VARCHAR2(1)  := '4'; -- �����i
  -- 2015.01.09 Ver1.1 Add End 
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE journal_id_ttype   IS TABLE OF ic_jrnl_mst.journal_id%TYPE INDEX BY PLS_INTEGER; -- ���Y����f�[�^�X�V�L�[�i�[�p
  TYPE gl_interface_ttype IS TABLE OF gl_interface%ROWTYPE        INDEX BY PLS_INTEGER; -- �d��OIF�o�^�f�[�^�i�[�p
  TYPE siwake_rec         IS RECORD (
       dr_company_code        fnd_lookup_values_vl.attribute8%TYPE    -- �ؕ�_���
      ,dr_department_code     fnd_lookup_values_vl.attribute9%TYPE    -- �ؕ�_����
      ,dr_account_title       fnd_lookup_values_vl.attribute10%TYPE   -- �ؕ�_����Ȗ�
      ,dr_account_subsidiary  fnd_lookup_values_vl.attribute11%TYPE   -- �ؕ�_�⏕�Ȗ�
      ,dr_description         fnd_lookup_values_vl.attribute12%TYPE   -- �ؕ�_�E�v
      ,dr_ccid                NUMBER                                  -- �ؕ�_CCID
      ,cr_company_code        fnd_lookup_values_vl.attribute8%TYPE    -- �ݕ�_���
      ,cr_department_code     fnd_lookup_values_vl.attribute9%TYPE    -- �ݕ�_����
      ,cr_account_title       fnd_lookup_values_vl.attribute10%TYPE   -- �ݕ�_����Ȗ�
      ,cr_account_subsidiary  fnd_lookup_values_vl.attribute11%TYPE   -- �ݕ�_�⏕�Ȗ�
      ,cr_description         fnd_lookup_values_vl.attribute12%TYPE   -- �ݕ�_�E�v
      ,cr_ccid                NUMBER                                  -- �ݕ�_CCID
      ,xxcfo_gl_je_key        gl_interface.attribute8%TYPE            -- �d��L�[
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�v���t�@�C���擾
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
  gv_je_ptn_rec_pay2          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��p�^�[��_�󕥎c���\2
  gv_je_category_mfg_adji     VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��J�e�S��_�d��
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
  gd_target_date_last         DATE          DEFAULT NULL;    -- ��v����_�ŏI��
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
    -- XXCFO:�d��p�^�[��_�󕥎c���\2
    gv_je_ptn_rec_pay2  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_rec_pay2 IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => ct_msg_name_cfo_00001   -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:�d��J�e�S��_�󕥁i���̑��j
    gv_je_category_mfg_adji  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_adji IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => ct_msg_name_cfo_00001   -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(3) ���o�Ώۓ�FROM�A���o�Ώۓ�TO���Z�o
    --==============================================================
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
--
    --==============================================================
    -- 2.(4) ��v����FROM�A��v����TO���Z�o
    --==============================================================
    -- ���̓p�����[�^�̉�v���Ԃ���A�d��OIF�o�^�p�Ɋi�[
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
   * Procedure Name   : check_account_period
   * Description      : ��v���ԃ`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_account_period(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_account_period'; -- �v���O������
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
  END check_account_period;
--
  /**********************************************************************************
   * Procedure Name   : get_siwake_mst
   * Description      : ����Ȗڏ��擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_siwake_mst(
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE             --   1.�i�ڋ敪
   ,it_prod_class_code  IN  mtl_categories_b.segment1%TYPE             --   2.���i�敪
   ,it_reason_code      IN  ic_tran_cmp.reason_code%TYPE               --   3.���R�R�[�h
   ,it_whse_code        IN  ic_whse_mst.whse_code%TYPE DEFAULT NULL    --   4.�q�ɃR�[�h
   ,ot_siwake_rec       OUT siwake_rec                                 --   1.�d����
   ,ov_errbuf           OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_siwake_mst'; -- �v���O������
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
    -- �d��p�^�[���m�F�p
    cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
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
    --==============================================================
    -- �ؕ�_����Ȗڎ擾
    --==============================================================
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay2                  -- (IN)���[
      , iv_class_code               =>  it_item_class_code                  -- (IN)�i�ڋ敪
      , iv_prod_class               =>  it_prod_class_code                  -- (IN)���i�敪
      , iv_reason_code              =>  it_reason_code                      -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                    -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  NULL                                -- (IN)�s�ԍ� �F1�E2
      , iv_gloif_dr_cr              =>  cv_gloif_dr                         -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  it_whse_code                        -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  ot_siwake_rec.dr_company_code       -- (OUT)���
      , ov_department_code          =>  ot_siwake_rec.dr_department_code    -- (OUT)����
      , ov_account_title            =>  ot_siwake_rec.dr_account_title      -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  ot_siwake_rec.dr_account_subsidiary -- (OUT)�⏕�Ȗ�
      , ov_description              =>  ot_siwake_rec.dr_description        -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                       -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                        -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                        -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �ؕ�_����Ȗ�ID���擾
    --==============================================================
    ot_siwake_rec.dr_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_target_date_last                    -- ������
                             , iv_segment1  => ot_siwake_rec.dr_company_code          -- ��ЃR�[�h
                             , iv_segment2  => ot_siwake_rec.dr_department_code       -- ����R�[�h
                             , iv_segment3  => ot_siwake_rec.dr_account_title         -- ����ȖڃR�[�h
                             , iv_segment4  => ot_siwake_rec.dr_account_subsidiary    -- �⏕�ȖڃR�[�h
                             , iv_segment5  => gv_aff5_customer_dummy                 -- �ڋq�R�[�h�_�~�[�l
                             , iv_segment6  => gv_aff6_company_dummy                  -- ��ƃR�[�h�_�~�[�l
                             , iv_segment7  => gv_aff7_preliminary1_dummy             -- �\��1�_�~�[�l
                             , iv_segment8  => gv_aff8_preliminary2_dummy             -- �\��2�_�~�[�l
                             );
--
    IF ( ot_siwake_rec.dr_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcfo
                      , iv_name         => ct_msg_name_cfo_10052               -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_last                 -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => ot_siwake_rec.dr_company_code       -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => ot_siwake_rec.dr_department_code    -- ����R�[�h
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => ot_siwake_rec.dr_account_title      -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => ot_siwake_rec.dr_account_subsidiary -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy              -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy               -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy          -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy          -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �ݕ�_����Ȗڎ擾
    --==============================================================
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay2                  -- (IN)���[
      , iv_class_code               =>  it_item_class_code                  -- (IN)�i�ڋ敪
      , iv_prod_class               =>  it_prod_class_code                  -- (IN)���i�敪
      , iv_reason_code              =>  it_reason_code                      -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                    -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  NULL                                -- (IN)�s�ԍ� �F1�E2
      , iv_gloif_dr_cr              =>  cv_gloif_cr                         -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  it_whse_code                        -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  ot_siwake_rec.cr_company_code       -- (OUT)���
      , ov_department_code          =>  ot_siwake_rec.cr_department_code    -- (OUT)����
      , ov_account_title            =>  ot_siwake_rec.cr_account_title      -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  ot_siwake_rec.cr_account_subsidiary -- (OUT)�⏕�Ȗ�
      , ov_description              =>  ot_siwake_rec.cr_description        -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                       -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                        -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                        -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �ݕ�_����Ȗ�ID���擾
    --==============================================================
    ot_siwake_rec.cr_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_target_date_last                    -- ������
                             , iv_segment1  => ot_siwake_rec.cr_company_code          -- ��ЃR�[�h
                             , iv_segment2  => ot_siwake_rec.cr_department_code       -- ����R�[�h
                             , iv_segment3  => ot_siwake_rec.cr_account_title         -- ����ȖڃR�[�h
                             , iv_segment4  => ot_siwake_rec.cr_account_subsidiary    -- �⏕�ȖڃR�[�h
                             , iv_segment5  => gv_aff5_customer_dummy                 -- �ڋq�R�[�h�_�~�[�l
                             , iv_segment6  => gv_aff6_company_dummy                  -- ��ƃR�[�h�_�~�[�l
                             , iv_segment7  => gv_aff7_preliminary1_dummy             -- �\��1�_�~�[�l
                             , iv_segment8  => gv_aff8_preliminary2_dummy             -- �\��2�_�~�[�l
                             );
--
    IF ( ot_siwake_rec.cr_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcfo
                      , iv_name         => ct_msg_name_cfo_10052               -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_last                 -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => ot_siwake_rec.cr_company_code       -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => ot_siwake_rec.cr_department_code    -- ����R�[�h
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => ot_siwake_rec.cr_account_title      -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => ot_siwake_rec.cr_account_subsidiary -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy              -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy               -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy          -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy          -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �d��OIF�̃V�[�P���X���̔�
    SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL) xxcfo_gl_je_key
    INTO   ot_siwake_rec.xxcfo_gl_je_key
    FROM   DUAL;
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
  END get_siwake_mst;
--
  /**********************************************************************************
   * Procedure Name   : set_gl_interface
   * Description      : �d��OIF�o�^�f�[�^�ݒ�(A-4)
   ***********************************************************************************/
  PROCEDURE set_gl_interface(
    iv_mode             IN  VARCHAR2                                   --   1.�������[�h 1:�`�[��,2:�q�ɕ�
   ,iv_period_name      IN  VARCHAR2                                   --   2.��v����
   ,it_item_class_code  IN  mtl_categories_b.segment1%TYPE             --   3.�i�ڋ敪
   ,it_prod_class_code  IN  mtl_categories_b.segment1%TYPE             --   4.���i�敪
   ,it_reason_code      IN  ic_tran_cmp.reason_code%TYPE               --   5.���R�R�[�h
   ,in_amt              IN  NUMBER                                     --   6.���z
   ,it_inv_adji_desc    IN  ic_jrnl_mst.attribute2%TYPE DEFAULT NULL   --   7.�݌ɒ����E�v
   ,it_whse_code        IN  ic_whse_mst.whse_code%TYPE  DEFAULT NULL   --   8.�q�ɃR�[�h
   ,it_whse_name        IN  ic_whse_mst.whse_name%TYPE  DEFAULT NULL   --   9.�q�ɖ�
   ,it_siwake_rec       IN  siwake_rec                                 --   10.�d����
   ,ot_gl_if_tab        OUT gl_interface_ttype                         --   1.�d��OIF�e�[�u���^
   ,ov_errbuf           OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'set_gl_interface'; -- �v���O������
    cv_status_new        CONSTANT VARCHAR2(3)   := 'NEW';              -- �X�e�[�^�X
    cv_actual_flag       CONSTANT VARCHAR2(1)   := 'A';                -- �c���^�C�v
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
    --==============================================================
    -- �ؕ�
    --==============================================================
    ot_gl_if_tab(1).status                 := cv_status_new;                      -- �X�e�[�^�X
    ot_gl_if_tab(1).set_of_books_id        := gn_sales_set_of_bks_id;             -- ��v����ID
    ot_gl_if_tab(1).accounting_date        := gd_target_date_last;                -- �L����
    ot_gl_if_tab(1).currency_code          := gv_currency_code;                   -- �ʉ݃R�[�h
    ot_gl_if_tab(1).date_created           := SYSDATE;                            -- �V�K�쐬��
    ot_gl_if_tab(1).created_by             := cn_created_by;                      -- �V�K�쐬��
    ot_gl_if_tab(1).actual_flag            := cv_actual_flag;                     -- �c���^�C�v
    ot_gl_if_tab(1).user_je_category_name  := gv_je_category_mfg_adji;            -- �d��J�e�S����
    ot_gl_if_tab(1).user_je_source_name    := gv_je_invoice_source_mfg;           -- �d��\�[�X��
    ot_gl_if_tab(1).code_combination_id    := it_siwake_rec.dr_ccid;              -- CCID
    -- ���z���v���X�̏ꍇ�A�ؕ��ɋ��z��ݒ�
    IF (in_amt >= 0) THEN
      ot_gl_if_tab(1).entered_dr             := in_amt;        -- �ؕ����z
      ot_gl_if_tab(1).entered_cr             := 0;             -- �ݕ����z
    -- ���z���}�C�i�X�̏ꍇ�A�ݕ��ɋ��z��ݒ�
    ELSIF (in_amt < 0) THEN
      ot_gl_if_tab(1).entered_dr             := 0;             -- �ؕ����z
      ot_gl_if_tab(1).entered_cr             := ABS(in_amt);   -- �ݕ����z
    END IF;
    ot_gl_if_tab(1).reference1             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- ���t�@�����X1�i�o�b�`���j
    ot_gl_if_tab(1).reference2             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- ���t�@�����X2�i�o�b�`�E�v�j
    ot_gl_if_tab(1).reference4             := it_siwake_rec.xxcfo_gl_je_key ;
                                                                                  -- ���t�@�����X4�i�d�󖼁j
    -- �`�[�ʂ̏ꍇ
    IF (iv_mode = cv_mode_1) THEN
      ot_gl_if_tab(1).reference5  := it_inv_adji_desc;                            -- ���t�@�����X5�i�d�󖼓E�v�j=�݌ɒ����E�v
      ot_gl_if_tab(1).reference10 := it_siwake_rec.dr_description  || ' ' || it_inv_adji_desc; 
                                                                                  -- ���t�@�����X10�i�d�󖾍דE�v�j=�ؕ��d��E�v�{�݌ɒ����E�v
--
    -- �q�ɕʂ̏ꍇ
    ELSIF (iv_mode = cv_mode_2) THEN
      ot_gl_if_tab(1).reference5  := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- ���t�@�����X5�i�d�󖼓E�v�j=�ؕ��d��E�v�{�q�ɃR�[�h�{�q�ɖ�
      ot_gl_if_tab(1).reference10 := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- ���t�@�����X10�i�d�󖾍דE�v�j=�ؕ��d��E�v�{�q�ɃR�[�h�{�q�ɖ�
    END IF;
                                                                                  -- ���t�@�����X10�i�d�󖾍דE�v�j
    ot_gl_if_tab(1).period_name            := iv_period_name;                     -- ��v���Ԗ�
    ot_gl_if_tab(1).attribute1             := NULL;                               -- ����1�i����ŃR�[�h�j
    ot_gl_if_tab(1).attribute3             := NULL;                               -- ����3�i�`�[�ԍ��j
    ot_gl_if_tab(1).attribute4             := it_siwake_rec.dr_department_code;   -- ����4�i�N�[����j
    ot_gl_if_tab(1).attribute5             := NULL;                               -- ����5�i���[�UID�j
    ot_gl_if_tab(1).context                := gv_sales_set_of_bks_name;           -- �R���e�L�X�g
    ot_gl_if_tab(1).attribute8             := it_siwake_rec.xxcfo_gl_je_key;      -- ����8�i�d��L�[�j
    ot_gl_if_tab(1).request_id             := cn_request_id;                      -- �v��ID
--
    --==============================================================
    -- �ݕ�
    --==============================================================
    ot_gl_if_tab(2).status                 := cv_status_new;                      -- �X�e�[�^�X
    ot_gl_if_tab(2).set_of_books_id        := gn_sales_set_of_bks_id;             -- ��v����ID
    ot_gl_if_tab(2).accounting_date        := gd_target_date_last;                -- �L����
    ot_gl_if_tab(2).currency_code          := gv_currency_code;                   -- �ʉ݃R�[�h
    ot_gl_if_tab(2).date_created           := SYSDATE;                            -- �V�K�쐬��
    ot_gl_if_tab(2).created_by             := cn_created_by;                      -- �V�K�쐬��
    ot_gl_if_tab(2).actual_flag            := cv_actual_flag;                     -- �c���^�C�v
    ot_gl_if_tab(2).user_je_category_name  := gv_je_category_mfg_adji;            -- �d��J�e�S����
    ot_gl_if_tab(2).user_je_source_name    := gv_je_invoice_source_mfg;           -- �d��\�[�X��
    ot_gl_if_tab(2).code_combination_id    := it_siwake_rec.cr_ccid;              -- CCID
    -- ���z���v���X�̏ꍇ�A�ؕ��ɋ��z��ݒ�
    IF (in_amt >= 0) THEN
      ot_gl_if_tab(2).entered_dr             := 0;             -- �ؕ����z
      ot_gl_if_tab(2).entered_cr             := in_amt;        -- �ݕ����z
    -- ���z���}�C�i�X�̏ꍇ�A�ݕ��ɋ��z��ݒ�
    ELSIF (in_amt < 0) THEN
      ot_gl_if_tab(2).entered_dr             := ABS(in_amt);   -- �ؕ����z
      ot_gl_if_tab(2).entered_cr             := 0;             -- �ݕ����z
    END IF;
    ot_gl_if_tab(2).reference1             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- ���t�@�����X1�i�o�b�`���j
    ot_gl_if_tab(2).reference2             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- ���t�@�����X2�i�o�b�`�E�v�j
    ot_gl_if_tab(2).reference4             := it_siwake_rec.xxcfo_gl_je_key ;
                                                                                  -- ���t�@�����X4�i�d�󖼁j
    -- �`�[�ʂ̏ꍇ
    IF (iv_mode = cv_mode_1) THEN
      ot_gl_if_tab(2).reference5  := it_inv_adji_desc;                            -- ���t�@�����X5�i�d�󖼓E�v�j=�݌ɒ����E�v
      ot_gl_if_tab(2).reference10 := it_siwake_rec.cr_description  || ' ' || it_inv_adji_desc; 
                                                                                  -- ���t�@�����X10�i�d�󖾍דE�v�j=�ݕ��d��E�v�{�݌ɒ����E�v
--
    -- �q�ɕʂ̏ꍇ
    ELSIF (iv_mode = cv_mode_2) THEN
      ot_gl_if_tab(2).reference5  := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- ���t�@�����X5�i�d�󖼓E�v�j=�ݕ��d��E�v�{�q�ɃR�[�h�{�q�ɖ�
      ot_gl_if_tab(2).reference10 := it_siwake_rec.cr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- ���t�@�����X10�i�d�󖾍דE�v�j=�ؕ��d��E�v�{�q�ɃR�[�h�{�q�ɖ�
    END IF;
    ot_gl_if_tab(2).period_name            := iv_period_name;                     -- ��v���Ԗ�
    ot_gl_if_tab(2).attribute1             := NULL;                               -- ����1�i����ŃR�[�h�j
    ot_gl_if_tab(2).attribute3             := NULL;                               -- ����3�i�`�[�ԍ��j
    ot_gl_if_tab(2).attribute4             := it_siwake_rec.cr_department_code;   -- ����4�i�N�[����j
    ot_gl_if_tab(2).attribute5             := NULL;                               -- ����5�i���[�UID�j
    ot_gl_if_tab(2).context                := gv_sales_set_of_bks_name;           -- �R���e�L�X�g
    ot_gl_if_tab(2).attribute8             := it_siwake_rec.xxcfo_gl_je_key;      -- ����8�i�d��L�[�j
    ot_gl_if_tab(2).request_id             := cn_request_id;                      -- �v��ID
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
  END set_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      : �d��OIF�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    it_gl_if_tab        IN  gl_interface_ttype     --   1.�d��OIF�e�[�u���^
   ,ov_errbuf           OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- �v���O������
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
    --==============================================================
    -- �d��OIF�o�^
    --==============================================================
--
    BEGIN
      FORALL ln_cnt IN 1..it_gl_if_tab.COUNT
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
       ,attribute1
       ,attribute3
       ,attribute4
       ,attribute5
       ,context
       ,attribute8
       ,request_id
       ,group_id
      )VALUES (
        it_gl_if_tab(ln_cnt).status                 -- �X�e�[�^�X
       ,it_gl_if_tab(ln_cnt).set_of_books_id        -- ��v����ID
       ,it_gl_if_tab(ln_cnt).accounting_date        -- �L����
       ,it_gl_if_tab(ln_cnt).currency_code          -- �ʉ݃R�[�h
       ,it_gl_if_tab(ln_cnt).date_created           -- �V�K�쐬��
       ,it_gl_if_tab(ln_cnt).created_by             -- �V�K�쐬��
       ,it_gl_if_tab(ln_cnt).actual_flag            -- �c���^�C�v
       ,it_gl_if_tab(ln_cnt).user_je_category_name  -- �d��J�e�S����
       ,it_gl_if_tab(ln_cnt).user_je_source_name    -- �d��\�[�X��
       ,it_gl_if_tab(ln_cnt).code_combination_id    -- CCID
       ,it_gl_if_tab(ln_cnt).entered_dr             -- �ؕ����z
       ,it_gl_if_tab(ln_cnt).entered_cr             -- �ݕ����z
       ,it_gl_if_tab(ln_cnt).reference1             -- ���t�@�����X1�i�o�b�`���j
       ,it_gl_if_tab(ln_cnt).reference2             -- ���t�@�����X2�i�o�b�`�E�v�j
       ,it_gl_if_tab(ln_cnt).reference4             -- ���t�@�����X4�i�d�󖼁j
       ,it_gl_if_tab(ln_cnt).reference5             -- ���t�@�����X5�i�d�󖼓E�v�j
       ,it_gl_if_tab(ln_cnt).reference10            -- ���t�@�����X10�i�d�󖾍דE�v�j
       ,it_gl_if_tab(ln_cnt).period_name            -- ��v���Ԗ�
       ,it_gl_if_tab(ln_cnt).attribute1             -- ����1�i����ŃR�[�h�j
       ,it_gl_if_tab(ln_cnt).attribute3             -- ����3�i�`�[�ԍ��j
       ,it_gl_if_tab(ln_cnt).attribute4             -- ����4�i�N�[����j
       ,it_gl_if_tab(ln_cnt).attribute5             -- ����5�i���[�UID�j
       ,it_gl_if_tab(ln_cnt).context                -- �R���e�L�X�g
       ,it_gl_if_tab(ln_cnt).attribute8             -- ����8�i�d��L�[�j
       ,it_gl_if_tab(ln_cnt).request_id             -- �v��ID
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := SUBSTRB(xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => ct_msg_name_cfo_00024         -- �o�^�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_01            -- �d��OIF
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQL�G���[
                          ),1,5000);
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
   * Procedure Name   : upd_mfg_tran
   * Description      : ���Y����f�[�^�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_mfg_tran(
    it_journal_id      IN  ic_jrnl_mst.journal_id%TYPE       -- 1. �W���[�i��ID
   ,iv_tran_name       IN  VARCHAR2                          -- 2. �g�����U�N�V������ �󒍖��� �W���[�i���}�X�^
   ,it_xxcfo_gl_je_key IN  gl_interface.attribute8%TYPE      -- 3. �d��P�ʁF����8(�d��L�[)
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_tran'; -- �v���O������
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
    ln_dummy      NUMBER;
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
    -- =========================================================
    -- ���b�N
    -- =========================================================
    BEGIN
      -- �g�����U�N�V���������W���[�i���}�X�^�̏ꍇ
      IF (iv_tran_name = cv_ic_jrnl_mst) THEN
        SELECT 1           dummy
        INTO   ln_dummy
        FROM   ic_jrnl_mst ijm -- �W���[�i���}�X�^
        WHERE  ijm.journal_id = it_journal_id
        FOR UPDATE NOWAIT
        ;
--
      -- �g�����U�N�V���������󒍖��ׂ̏ꍇ
      ELSIF (iv_tran_name = cv_oe_order_lines_all) THEN
        SELECT 1                  dummy
        INTO   ln_dummy
        FROM   oe_order_lines_all oola -- �󒍖���
        WHERE  oola.line_id = it_journal_id
        FOR UPDATE NOWAIT
        ;
      END IF;
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo      -- XXCFO
                  , iv_name         => ct_msg_name_cfo_00019   -- ���b�N�G���[
                  , iv_token_name1  => cv_tkn_table            -- �e�[�u��
                  , iv_token_value1 => iv_tran_name            -- �e�[�u����
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =========================================================
    -- �X�V
    -- =========================================================
    BEGIN
      -- �g�����U�N�V���������W���[�i���}�X�^�̏ꍇ
      IF (iv_tran_name = cv_ic_jrnl_mst) THEN
        UPDATE ic_jrnl_mst      ijm -- �W���[�i���}�X�^
        SET    ijm.attribute5 = it_xxcfo_gl_je_key -- �d��L�[
        WHERE  ijm.journal_id = it_journal_id
        ;
--
      -- �g�����U�N�V���������󒍖��ׂ̏ꍇ
      ELSIF (iv_tran_name = cv_oe_order_lines_all) THEN
        UPDATE oe_order_lines_all      oola -- �󒍖���
        SET    oola.attribute4 = it_xxcfo_gl_je_key -- �d��L�[
        WHERE  oola.line_id    = it_journal_id
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcfo                     -- XXCFO
                     , iv_name         => ct_msg_name_cfo_00020                  -- �X�V�G���[
                     , iv_token_name1  => cv_tkn_table                           -- �e�[�u��
                     , iv_token_value1 => iv_tran_name                           -- �e�[�u����
                     , iv_token_name2  => cv_tkn_errmsg                          -- �A�C�e��
                     , iv_token_value2 => SQLERRM                                -- �G���[���b�Z�[�W
                          ),1,5000);
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
  END upd_mfg_tran;
--
  /**********************************************************************************
   * Procedure Name   : upd_mfg_tran
   * Description      : ���Y����f�[�^�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_mfg_tran(
    it_journal_id_tab   IN  journal_id_ttype                  -- 1. �W���[�i��ID
   ,iv_tran_name        IN  VARCHAR2                          -- 2. �g�����U�N�V������ �󒍖��� �W���[�i���}�X�^
   ,it_xxcfo_gl_je_key  IN  gl_interface.attribute8%TYPE      -- 3. �d��P�ʁF����8(�d��L�[)
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_tran'; -- �v���O������
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
    <<main_loop>>
    FOR ln_cnt IN 1..it_journal_id_tab.COUNT LOOP
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => it_journal_id_tab(ln_cnt) -- 1. �W���[�i��ID
       ,iv_tran_name             => iv_tran_name              -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => it_xxcfo_gl_je_key        -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP main_loop;
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
  END upd_mfg_tran;
--
  /**********************************************************************************
   * Procedure Name   : get_trans_data
   * Description      : �d��OIF��񒊏o(A-3)
   ***********************************************************************************/
  PROCEDURE get_trans_data(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trans_data'; -- �v���O������
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
    cv_adji                  CONSTANT VARCHAR2(30)  := 'ADJI';           -- �݌ɒ���
    cv_omso                  CONSTANT VARCHAR2(30)  := 'OMSO';           -- �o��
    cv_porc                  CONSTANT VARCHAR2(30)  := 'PORC';           -- ���
    cv_reason_941            CONSTANT VARCHAR2(30)  := 'X941';           -- �]��(�d���Q�ۈȊO)
    cv_reason_942            CONSTANT VARCHAR2(30)  := 'X942';           -- �]��(�d���Q��)
    cv_reason_943            CONSTANT VARCHAR2(30)  := 'X943';           -- �j�����o
    cv_reason_932            CONSTANT VARCHAR2(30)  := 'X932';           -- ���{
    cv_reason_931            CONSTANT VARCHAR2(30)  := 'X931';           -- �p�p
    cv_reason_922            CONSTANT VARCHAR2(30)  := 'X922';           -- �������o
    cv_reason_951            CONSTANT VARCHAR2(30)  := 'X951';           -- ���̑����o
    cv_reason_911            CONSTANT VARCHAR2(30)  := 'X911';           -- �I����
    cv_reason_912            CONSTANT VARCHAR2(30)  := 'X912';           -- �I����
    cv_reason_921            CONSTANT VARCHAR2(30)  := 'X921';           -- �����g�p
    cv_cost_ac               CONSTANT VARCHAR2(1)   := '0';              -- ���ی���
    cv_cost_st               CONSTANT VARCHAR2(1)   := '1';              -- �W������
    cv_itoen_inv             CONSTANT VARCHAR2(1)   := '0';              -- �ɓ����݌ɊǗ��q��
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- �����t���O
    cv_status_04             CONSTANT VARCHAR2(2)   := '04';             -- �˗��X�e�[�^�X 04:�o�׎��ьv���
    cv_y                     CONSTANT VARCHAR2(1)   := 'Y';              -- Y
    cv_dealings_div_504      CONSTANT VARCHAR2(3)   := '504';            -- ����敪 504:���{
    cv_dealings_div_509      CONSTANT VARCHAR2(3)   := '509';            -- ����敪 509:�p�p
    cv_source_document_rma   CONSTANT VARCHAR2(3)   := 'RMA';            -- �\�[�X���� RMA
    rcv_pay_div_1            CONSTANT VARCHAR2(3)   := '1';              -- �󕥋敪 1
    -- 2015.01.09 Ver1.1 Add Start
    ct_lang                  CONSTANT fnd_lookup_values.language%TYPE    := USERENV('LANG');             -- ����
    ct_lookup_cost_whse      CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFO1_PACKAGE_COST_WHSE';  -- �Q�ƃ^�C�v�F�󕥐��Y�q�Ƀ��X�g
    cv_flag_1                VARCHAR2(1)                                 := '1';                         -- �I�����Ցq�Ƀt���O
    -- 2015.01.09 Ver1.1 Add End
    -- 2015-01.29 Ver1.2 Add Start
    ct_dealings_div_502      CONSTANT xxcmn_rcv_pay_mst.dealings_div%TYPE := '502';
    ct_dealings_div_511      CONSTANT xxcmn_rcv_pay_mst.dealings_div%TYPE := '511';
    ct_rcv_pay_div_minus1    CONSTANT xxcmn_rcv_pay_mst.rcv_pay_div%TYPE  := '-1';
    -- 2015-01.29 Ver1.2 Add End
--
    -- *** ���[�J���ϐ� ***
    lt_siwake_rec            siwake_rec;                                 -- �d����
    lt_gl_if_tab             gl_interface_ttype;                         -- �d��OIF�o�^�f�[�^�i�[�p
    ln_sum_amt               NUMBER DEFAULT 0;                           -- ���v���z
    lt_journal_id_tab        journal_id_ttype;                           -- ���Y����X�V�L�[ �W���[�i��ID TABLE�^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- *********************************************************
    -- ���o�J�[�\��_�]��
    -- *********************************************************
    CURSOR get_adji_cur_01
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code           IN (cv_reason_941   -- �]��(�d���Q�ۈȊO)
                                        ,cv_reason_942   -- �]��(�d���Q��)
                                        ,cv_reason_943)  -- �j�����o
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- ���i�敪
          ,xicv.item_class_code     -- �i�ڋ敪
          ,itc.reason_code          -- ���R�R�[�h
          ,iimb.item_no             -- �i�ڃR�[�h
          ,ilm.lot_no               -- ���b�gNo
          ,itc.trans_date           -- �����
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_���{
    -- *********************************************************
    CURSOR get_adji_cur_02
    IS
    -------------------------------------------------
    -- �݌ɒ���
    -------------------------------------------------
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
              TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,iimb.item_no               item_no         -- �i�ڃR�[�h
          ,ilm.lot_no                 lot_no          -- ���b�gNo
          ,itc.trans_date             trans_date      -- �����
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
          ,cv_ic_jrnl_mst             tran_name       -- �g�����U�N�V������
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_932   -- ���{
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    -------------------------------------------------
    -- �󒍏o�׏��i���{�j
    -------------------------------------------------
    UNION ALL
    SELECT ROUND(
             NVL(itp.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,iimb.item_no               item_no         -- �i�ڃR�[�h
          ,ilm.lot_no                 lot_no          -- ���b�gNo
          ,xoha.arrival_date          trans_date      -- �����
          ,cv_reason_932              reason_code     -- ���R�R�[�h
          ,xoha.shipping_instructions inv_adji_desc   -- �݌ɒ����E�v
          ,xola.line_id               journal_id      -- �W���[�i��ID
          ,cv_oe_order_lines_all      tran_name       -- �g�����U�N�V������
    FROM   ic_tran_pnd                itp             -- �ۗ��݌Ƀg�����U�N�V����
          ,xxwsh_order_headers_all    xoha            -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola            -- �󒍖��׃A�h�I��
          ,wsh_delivery_details       wdd             -- ��������
          ,oe_order_headers_all       ooha            -- �󒍃w�b�_
          ,oe_transaction_types_all   otta            -- �󒍃^�C�v
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itp.doc_type                    = cv_omso
    AND    itp.completed_ind               = cn_completed_ind
    AND    itp.trans_date                 >= gd_target_date_from
    AND    itp.trans_date                 <= gd_target_date_to
    AND    xoha.req_status                 = cv_status_04
    AND    xoha.latest_external_flag       = cv_y
    AND    xoha.order_header_id            = xola.order_header_id
    AND    ooha.header_id                  = xoha.header_id
    AND    otta.transaction_type_id        = ooha.order_type_id
    AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
    AND    xrpm.stock_adjustment_div       = otta.attribute4
    AND    xrpm.doc_type                   = itp.doc_type
    AND    xrpm.dealings_div               = cv_dealings_div_504 -- ���{
    AND    xrpm.break_col_03              IS NOT NULL
    AND    xicv.item_id                    = itp.item_id
    AND    wdd.delivery_detail_id          = itp.line_detail_id
    AND    wdd.source_header_id            = ooha.header_id
    AND    wdd.source_line_id              = xola.line_id
    AND    xlc.item_id(+)                  = itp.item_id
    AND    xlc.lot_id (+)                  = itp.lot_id
    AND    xsupv.item_id(+)                = itp.item_id
    AND    xsupv.start_date_active(+)     <= gd_target_date_from
    AND    xsupv.end_date_active(+)       >= gd_target_date_from
    AND    iimb.item_id                    = itp.item_id
    AND    iwm.whse_code                   = itp.whse_code
    AND    iwm.attribute1                  = cv_itoen_inv
    AND    ilm.item_id                     = itp.item_id
    AND    ilm.lot_id                      = itp.lot_id
    ORDER BY
           prod_class_code     -- ���i�敪
          ,item_class_code     -- �i�ڋ敪
          ,item_no             -- �i�ڃR�[�h
          ,lot_no              -- ���b�gNo
          ,trans_date          -- �����
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_�p�p
    -- *********************************************************
    CURSOR get_adji_cur_03
    IS
    -------------------------------------------------
    -- �݌ɒ���
    -------------------------------------------------
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
              TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,iimb.item_no               item_no         -- �i�ڃR�[�h
          ,ilm.lot_no                 lot_no          -- ���b�gNo
          ,itc.trans_date             trans_date      -- �����
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
          ,cv_ic_jrnl_mst             tran_name       -- �g�����U�N�V������
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_931   -- �p�p
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    -------------------------------------------------
    -- �󒍏o�׏��i�p�p�j
    -------------------------------------------------
    UNION ALL
    SELECT ROUND(
             NVL(itp.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,iimb.item_no               item_no         -- �i�ڃR�[�h
          ,ilm.lot_no                 lot_no          -- ���b�gNo
          ,xoha.arrival_date          trans_date      -- �����
          ,cv_reason_931              reason_code     -- ���R�R�[�h
          ,xoha.shipping_instructions inv_adji_desc   -- �݌ɒ����E�v
          ,xola.line_id               journal_id      -- �W���[�i��ID
          ,cv_oe_order_lines_all      tran_name       -- �g�����U�N�V������
    FROM   ic_tran_pnd                itp             -- �ۗ��݌Ƀg�����U�N�V����
          ,xxwsh_order_headers_all    xoha            -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola            -- �󒍖��׃A�h�I��
          ,wsh_delivery_details       wdd             -- ��������
          ,oe_order_headers_all       ooha            -- �󒍃w�b�_
          ,oe_transaction_types_all   otta            -- �󒍃^�C�v
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itp.doc_type                    = cv_omso
    AND    itp.completed_ind               = cn_completed_ind
    AND    itp.trans_date                 >= gd_target_date_from
    AND    itp.trans_date                 <= gd_target_date_to
    AND    xoha.req_status                 = cv_status_04
    AND    xoha.latest_external_flag       = cv_y
    AND    xoha.order_header_id            = xola.order_header_id
    AND    ooha.header_id                  = xoha.header_id
    AND    otta.transaction_type_id        = ooha.order_type_id
    AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
    AND    xrpm.stock_adjustment_div       = otta.attribute4
    AND    xrpm.doc_type                   = itp.doc_type
    AND    xrpm.dealings_div               = cv_dealings_div_509 -- �p�p
    AND    xrpm.break_col_03              IS NOT NULL
    AND    xicv.item_id                    = itp.item_id
    AND    wdd.delivery_detail_id          = itp.line_detail_id
    AND    wdd.source_header_id            = ooha.header_id
    AND    wdd.source_line_id              = xola.line_id
    AND    xlc.item_id(+)                  = itp.item_id
    AND    xlc.lot_id (+)                  = itp.lot_id
    AND    xsupv.item_id(+)                = itp.item_id
    AND    xsupv.start_date_active(+)     <= gd_target_date_from
    AND    xsupv.end_date_active(+)       >= gd_target_date_from
    AND    iimb.item_id                    = itp.item_id
    AND    iwm.whse_code                   = itp.whse_code
    AND    iwm.attribute1                  = cv_itoen_inv
    AND    ilm.item_id                     = itp.item_id
    AND    ilm.lot_id                      = itp.lot_id
    ORDER BY
           prod_class_code     -- ���i�敪
          ,item_class_code     -- �i�ڋ敪
          ,item_no             -- �i�ڃR�[�h
          ,lot_no              -- ���b�gNo
          ,trans_date          -- �����
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_�������o
    -- *********************************************************
    CURSOR get_adji_cur_04
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_922   -- �������o
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- ���i�敪
          ,xicv.item_class_code     -- �i�ڋ敪
          ,iimb.item_no             -- �i�ڃR�[�h
          ,ilm.lot_no               -- ���b�gNo
          ,itc.trans_date           -- �����
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_���̑�
    -- *********************************************************
    CURSOR get_adji_cur_05
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    -- 2015-01-29 Ver1.1 Mod Start
--    AND    itc.reason_code             = cv_reason_951   -- ���̑����o
    AND    xrpm.dealings_div          IN (ct_dealings_div_502
                                         ,ct_dealings_div_511)   -- ���̑����o
    AND    xrpm.rcv_pay_div            = ct_rcv_pay_div_minus1   -- �󕥋敪�F���o
    -- 2015-01-29 Ver1.1 Mod End
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- ���i�敪
          ,xicv.item_class_code     -- �i�ڋ敪
          ,iimb.item_no             -- �i�ڃR�[�h
          ,ilm.lot_no               -- ���b�gNo
          ,itc.trans_date           -- �����
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_�I�����Ք�
    -- *********************************************************
    CURSOR get_adji_cur_06
    IS
    SELECT ROUND(
             CASE
               -- 2015.01.09 Ver1.1 Mod Start
               -- �y�s�v�̂��ߍ폜�z�I�����́A���o����(�I������)�ɏo�͂���ׁA���ʂ̕�����ϊ�����
--               WHEN (xrpm.rcv_pay_div = rcv_pay_div_1)
--               AND  (itc.reason_code  = cv_reason_911) THEN 
--                 NVL(itc.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div) * -1
               WHEN (itc.reason_code  = cv_reason_911) THEN 
                 NVL(itc.trans_qty, 0)
               -- 2015.01.09 Ver1.1 Mod End
               ELSE
                 NVL(itc.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)
               END *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,iwm.whse_code              whse_code       -- �q�ɃR�[�h
          ,iwm.whse_name              whse_name       -- �q�ɖ���
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code           IN (cv_reason_911   -- �I����
                                        ,cv_reason_912)  -- �I����
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    -- 2015.01.09 Ver1.1 Add Start 
    AND  ((xicv.item_class_code = cv_item_class_code_4      -- �����i
      AND  EXISTS (SELECT 1
                   FROM   fnd_lookup_values   flv
                   WHERE  flv.lookup_type             = ct_lookup_cost_whse
                   AND    flv.language                = ct_lang
                   AND    flv.attribute3              = cv_flag_1           -- �I�����Ք����i�q�ɔ��f�p�t���O
                   AND    itc.trans_date              BETWEEN flv.start_date_active
                                                      AND     NVL(flv.end_date_active,itc.trans_date)
                   AND    flv.enabled_flag            = cv_y
                   AND    flv.lookup_code             = iwm.whse_code   ))
    OR    (xicv.item_class_code <> cv_item_class_code_4))   -- �����i�ȊO
    -- 2015.01.09 Ver1.1 Add End
    ORDER BY
           xicv.prod_class_code       -- ���i�敪
          ,xicv.item_class_code       -- �i�ڋ敪
          ,itc.reason_code            -- ���R�R�[�h
          ,iwm.whse_code              -- �q�ɃR�[�h
    ;
--
    -- *********************************************************
    -- ���o�J�[�\��_�����g�p
    -- *********************************************************
    CURSOR get_adji_cur_07
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- �����Ǘ��敪��0:���ی���
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- �����Ǘ��敪��1:�W������
             END
           )                          amt             -- ���z
          ,xicv.prod_class_code       prod_class_code -- ���i�敪
          ,xicv.item_class_code       item_class_code -- �i�ڋ敪
          ,itc.reason_code            reason_code     -- ���R�R�[�h
          ,ijm.attribute2             inv_adji_desc   -- �݌ɒ����E�v
          ,ijm.journal_id             journal_id      -- �W���[�i��ID
    FROM   ic_tran_cmp                itc             -- OPM�����݌Ƀg�����U�N�V����
          ,ic_adjs_jnl                iaj             -- OPM�݌ɒ����W���[�i��
          ,ic_jrnl_mst                ijm             -- OPM�W���[�i���}�X�^
          ,xxcmn_rcv_pay_mst          xrpm            -- �󕥋敪�A�h�I���}�X�^
          ,xxcmn_item_categories5_v   xicv            -- OPM�i�ڃJ�e�S���������VIEW5
          ,xxcmn_lot_cost             xlc             -- ���b�g�ʌ���
          ,xxcmn_stnd_unit_price_v    xsupv           -- �W������VIEW
          ,ic_item_mst_b              iimb            -- OPM�i�ڃ}�X�^
          ,ic_whse_mst                iwm             -- OPM�q�Ƀ}�X�^
          ,ic_lots_mst                ilm             -- OPM���b�g�}�X�^
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_921   -- �����g�p
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- ���i�敪
          ,xicv.item_class_code     -- �i�ڋ敪
          ,iimb.item_no             -- �i�ڃR�[�h
          ,ilm.lot_no               -- ���b�gNo
          ,itc.trans_date           -- �����
    ;
--
    -- PL/SQL�\ TABLE�^�錾
    TYPE cur_01_ttype IS TABLE OF get_adji_cur_01%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_02_ttype IS TABLE OF get_adji_cur_02%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_03_ttype IS TABLE OF get_adji_cur_03%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_04_ttype IS TABLE OF get_adji_cur_04%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_05_ttype IS TABLE OF get_adji_cur_05%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_06_ttype IS TABLE OF get_adji_cur_06%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_07_ttype IS TABLE OF get_adji_cur_07%ROWTYPE INDEX BY PLS_INTEGER;
--
    cur_01_tab                    cur_01_ttype; -- �]��
    cur_02_tab                    cur_02_ttype; -- ���{
    cur_03_tab                    cur_03_ttype; -- �p�p
    cur_04_tab                    cur_04_ttype; -- �������o
    cur_05_tab                    cur_05_ttype; -- ���̑�
    cur_06_tab                    cur_06_ttype; -- �I�����Ք�
    cur_07_tab                    cur_07_ttype; -- �����g�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    ln_sum_amt := 0;
    lt_journal_id_tab.DELETE;
    lt_siwake_rec := NULL;
    lt_gl_if_tab.DELETE;
--
    -- �d��OIF��񒊏o
    OPEN  get_adji_cur_01;
    FETCH get_adji_cur_01 BULK COLLECT INTO cur_01_tab;
    CLOSE get_adji_cur_01;
--
    OPEN  get_adji_cur_02;
    FETCH get_adji_cur_02 BULK COLLECT INTO cur_02_tab;
    CLOSE get_adji_cur_02;
--
    OPEN  get_adji_cur_03;
    FETCH get_adji_cur_03 BULK COLLECT INTO cur_03_tab;
    CLOSE get_adji_cur_03;
--
    OPEN  get_adji_cur_04;
    FETCH get_adji_cur_04 BULK COLLECT INTO cur_04_tab;
    CLOSE get_adji_cur_04;
--
    OPEN  get_adji_cur_05;
    FETCH get_adji_cur_05 BULK COLLECT INTO cur_05_tab;
    CLOSE get_adji_cur_05;
--
    OPEN  get_adji_cur_06;
    FETCH get_adji_cur_06 BULK COLLECT INTO cur_06_tab;
    CLOSE get_adji_cur_06;
--
    OPEN  get_adji_cur_07;
    FETCH get_adji_cur_07 BULK COLLECT INTO cur_07_tab;
    CLOSE get_adji_cur_07;
--
    -- �Ώی����J�E���g
    gn_target_cnt := cur_01_tab.COUNT +
                     cur_02_tab.COUNT +
                     cur_03_tab.COUNT +
                     cur_04_tab.COUNT +
                     cur_05_tab.COUNT +
                     cur_06_tab.COUNT +
                     cur_07_tab.COUNT;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�G���[
    IF ( gn_target_cnt = 0 ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcfo              -- XXCFO
                   , iv_name         => ct_msg_name_cfo_10043
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    -- *********************************************************
    -- �]��
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_01_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_01_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_01_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_01_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_01_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_01_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_01_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_01_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_01_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_01_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- ���{
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_02_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_02_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_02_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_02_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_02_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_02_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_02_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_02_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_02_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_02_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cur_02_tab(ln_cnt).tran_name  -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- �p�p
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_03_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_03_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_03_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_03_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_03_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_03_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_03_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_03_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_03_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_03_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cur_03_tab(ln_cnt).tran_name  -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- �������o
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_04_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_04_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_04_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_04_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_04_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_04_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_04_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_04_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_04_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_04_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- ���̑�
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_05_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_05_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_05_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_05_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_05_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_05_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_05_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_05_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_05_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_05_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- �I�����Ք�
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_06_tab.COUNT LOOP
--
      ln_sum_amt := ln_sum_amt + cur_06_tab(ln_cnt).amt; -- ���z���Z
      lt_journal_id_tab(lt_journal_id_tab.COUNT + 1) := cur_06_tab(ln_cnt).journal_id; -- ���Y����X�V�L�[�ݒ�
--
      IF ( (ln_cnt = cur_06_tab.COUNT) -- �ŏI���R�[�h
           -- �i�ڋ敪�A���i�敪�A���R�A�q�Ƀu���C�N��
        OR (cur_06_tab(ln_cnt).item_class_code <> cur_06_tab(ln_cnt + 1).item_class_code)
        OR (cur_06_tab(ln_cnt).prod_class_code <> cur_06_tab(ln_cnt + 1).prod_class_code)
        OR (cur_06_tab(ln_cnt).reason_code     <> cur_06_tab(ln_cnt + 1).reason_code)
        OR (cur_06_tab(ln_cnt).whse_code       <> cur_06_tab(ln_cnt + 1).whse_code)
      ) THEN
--
        -- ===============================
        -- �d��OIF�o�^(A-4)
        -- ===============================
        -- ����Ȗڏ��擾(A-4)
        get_siwake_mst(
          it_item_class_code       => cur_06_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
         ,it_prod_class_code       => cur_06_tab(ln_cnt).prod_class_code   --   2.���i�敪
         ,it_reason_code           => cur_06_tab(ln_cnt).reason_code       --   3.���R�R�[�h
         ,it_whse_code             => cur_06_tab(ln_cnt).whse_code         --   4.�q�ɃR�[�h
         ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
         ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
        set_gl_interface(
          iv_mode                  => cv_mode_2                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
         ,iv_period_name           => iv_period_name                       --   2.��v����
         ,it_item_class_code       => cur_06_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
         ,it_prod_class_code       => cur_06_tab(ln_cnt).prod_class_code   --   4.���i�敪
         ,it_reason_code           => cur_06_tab(ln_cnt).reason_code       --   5.���R�R�[�h
         ,in_amt                   => ln_sum_amt                           --   6.���z
         ,it_inv_adji_desc         => NULL                                 --   7.�݌ɒ����E�v
         ,it_whse_code             => cur_06_tab(ln_cnt).whse_code         --   8.�q�ɃR�[�h
         ,it_whse_name             => cur_06_tab(ln_cnt).whse_name         --   9.�q�ɖ�
         ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
         ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
         ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �d��OIF�o�^(A-4)
        ins_gl_interface(
          it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
         ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- ���Y����f�[�^�X�V(A-5)
        -- ===============================
        upd_mfg_tran(
          it_journal_id_tab        => lt_journal_id_tab             -- 1. �W���[�i��ID
         ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. �g�����U�N�V������
         ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
         ,ov_errbuf                => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ������
        ln_sum_amt := 0;
        lt_journal_id_tab.DELETE;
        lt_siwake_rec := NULL;
        lt_gl_if_tab.DELETE;
--
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- �����g�p
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_07_tab.COUNT LOOP
--
      -- ===============================
      -- �d��OIF�o�^(A-4)
      -- ===============================
      -- ����Ȗڏ��擾(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_07_tab(ln_cnt).item_class_code   --   1.�i�ڋ敪
       ,it_prod_class_code       => cur_07_tab(ln_cnt).prod_class_code   --   2.���i�敪
       ,it_reason_code           => cur_07_tab(ln_cnt).reason_code       --   3.���R�R�[�h
       ,it_whse_code             => NULL                                 --   4.�q�ɃR�[�h
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.�d����
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^�f�[�^�ݒ�(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.�������[�h 1:�`�[��,2:�q�ɕ�
       ,iv_period_name           => iv_period_name                       --   2.��v����
       ,it_item_class_code       => cur_07_tab(ln_cnt).item_class_code   --   3.�i�ڋ敪
       ,it_prod_class_code       => cur_07_tab(ln_cnt).prod_class_code   --   4.���i�敪
       ,it_reason_code           => cur_07_tab(ln_cnt).reason_code       --   5.���R�R�[�h
       ,in_amt                   => cur_07_tab(ln_cnt).amt               --   6.���z
       ,it_inv_adji_desc         => cur_07_tab(ln_cnt).inv_adji_desc     --   7.�݌ɒ����E�v
       ,it_whse_code             => NULL                                 --   8.�q�ɃR�[�h
       ,it_whse_name             => NULL                                 --   9.�q�ɖ�
       ,it_siwake_rec            => lt_siwake_rec                        --   10.�d����
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �d��OIF�o�^(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.�d��OIF�e�[�u���^
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_07_tab(ln_cnt).journal_id -- 1. �W���[�i��ID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. �g�����U�N�V������
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. �d��P�ʁF����8(�d��L�[)
       ,ov_errbuf                => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode               => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
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
      -- �J�[�\���N���[�Y
      IF ( get_adji_cur_01%ISOPEN ) THEN
        CLOSE get_adji_cur_01;
      END IF;
      IF ( get_adji_cur_02%ISOPEN ) THEN
        CLOSE get_adji_cur_02;
      END IF;
      IF ( get_adji_cur_03%ISOPEN ) THEN
        CLOSE get_adji_cur_03;
      END IF;
      IF ( get_adji_cur_04%ISOPEN ) THEN
        CLOSE get_adji_cur_04;
      END IF;
      IF ( get_adji_cur_05%ISOPEN ) THEN
        CLOSE get_adji_cur_05;
      END IF;
      IF ( get_adji_cur_06%ISOPEN ) THEN
        CLOSE get_adji_cur_06;
      END IF;
      IF ( get_adji_cur_07%ISOPEN ) THEN
        CLOSE get_adji_cur_07;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_trans_data;
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
    cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
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
         cv_pkg_name                         -- �@�\�� 'XXCFO020A01C'
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
        lv_errmsg    := SUBSTRB(xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => ct_msg_name_cfo_00024         -- �o�^�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_02            -- �A�g�Ǘ��e�[�u��
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQL�G���[
                          ),1,5000);
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
    check_account_period(
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
    -- �d��OIF��񒊏o(A-3)
    -- ===============================
    get_trans_data(
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
    -- �A�g�Ǘ��e�[�u���o�^(A-6)
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
    -- �����������Ώی���
    gn_target_cnt := gn_normal_cnt;
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
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --���������o��
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --�G���[�����o��
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := ct_msg_name_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := ct_msg_name_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := ct_msg_name_ccp_90006;
    END IF;
--
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
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
END XXCFO020A01C;
/
