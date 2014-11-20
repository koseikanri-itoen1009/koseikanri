CREATE OR REPLACE PACKAGE BODY XXCFO011A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO011A01C
 * Description     : �l���V�X�e���f�[�^�A�g
 * MD.050          : MD050_CFO_011_A01_�l���V�X�e���f�[�^�A�g
 * MD.070          : MD050_CFO_011_A01_�l���V�X�e���f�[�^�A�g
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        ���̓p�����[�^�l���O�o�͏���                  (A-1)
 *  get_system_value  P        �e��V�X�e���l�擾����                        (A-2)
 *  submit_request_sql_loader P �l���V�X�e���f�[�^�A�g(SQL*Loader)�N������   (A-3)
 *  wait_request      P        �l���V�X�e���f�[�^�A�g(SQL*Loader)�Ď�����    (A-4)
 *  error_request_sql_loader P  �l���V�X�e���f�[�^�A�g(SQL*Loader)�G���[���� (A-5)
 *  insert_xx03_gl_interface P �O�����JGL�A�h�I��OIF�}������                 (A-6)
 *  truncate_adps_gl_interface P �l���V�X�e���pGL�A�h�I��OIF�@TRUNCATE����   (A-7)
 *  submit_request_err_check P BFA:GLI/F�G���[�`�F�b�N�N������               (A-8)
 *  wait_request      P        BFA:GLI/F�G���[�`�F�b�N�Ď�����               (A-9)
 *  error_request_err_check P  BFA:GLI/F�G���[�`�F�b�N�G���[����             (A-10)
 *  del_xx03_gl_interface P    �O�����JGL�A�h�I��OIF�폜����                 (A-10-1)
 *  submit_request_transfer P  BFA:GLI/F�]���N������                         (A-11)
 *  wait_request      P        BFA:GLI/F�]���Ď�����                         (A-12)
 *  error_request_transfer P   BFA:GLI/F�]���G���[����                       (A-13)
 *  submit_request_import P    �d��C���|�[�g�N������                        (A-14)
 *  wait_request      P        �d��C���|�[�g�Ď�����                        (A-15)
 *  error_request_import P     �d��C���|�[�g�G���[����                      (A-16)
 *  submain           P        ���C�������v���V�[�W��
 *  main              P        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-25    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
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
  -- ���[�U�[��`��O
  -- ===============================
--
  lock_expt                 EXCEPTION;      -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO011A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_03      CONSTANT VARCHAR2(5)   := 'XX03';         -- �A�h�I���FBFA�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_011a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_011a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00021'; --�R���J�����g�N���G���[���b�Z�[�W
  cv_msg_011a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00022'; --�R���J�����g�Ď��G���[���b�Z�[�W
  cv_msg_011a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00023'; --�Ď��v���O�����G���[�I�����b�Z�[�W
  cv_msg_011a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024'; --�f�[�^�}���G���[���b�Z�[�W
  cv_msg_011a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; --���b�N�G���[���b�Z�[�W
  cv_msg_011a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_011a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00026'; --�d��\�[�X�擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_program     CONSTANT VARCHAR2(20) := 'PROGRAM_NAME';     -- ���s�R���J�����g�v���O������
  cv_tkn_request     CONSTANT VARCHAR2(20) := 'REQUEST_ID';       -- ���s�R���J�����g�v���O�����v��ID
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';            -- �e�[�u����
  cv_tkn_errmsg      CONSTANT VARCHAR2(20) := 'ERRMSG';           -- ORACLE�G���[�̓��e
  cv_tkn_je_source   CONSTANT VARCHAR2(20) := 'JE_SOURCE_NAME';   -- �d��C���|�[�g�Ώۂ̎d��\�[�X�R�[�h
--
  -- ���{�ꎫ��
  cv_dict_sql_loader CONSTANT VARCHAR2(100) := 'CFO011A01001';    -- �R���J�����g�v���O�������F�l���V�X�e���f�[�^�A�g(SQL*Loader)
  cv_dict_err_check  CONSTANT VARCHAR2(100) := 'CFO011A01002';    -- �R���J�����g�v���O�������FGLI/F�G���[�`�F�b�N
  cv_dict_transfer   CONSTANT VARCHAR2(100) := 'CFO011A01003';    -- �R���J�����g�v���O�������FGLI/F�]��
  cv_dict_import     CONSTANT VARCHAR2(100) := 'CFO011A01004';    -- �R���J�����g�v���O�������FGL�d��C���|�[�g�̋N��
  cv_dict_tab_03glif CONSTANT VARCHAR2(100) := 'CFO011A01005';    -- �O�����JGL�A�h�I��OIF�e�[�u����
--
  -- �v���t�@�C��
  cv_adps_interval   CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_INTERVAL';  -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������`�F�b�N�ҋ@�b��
  cv_adps_max_wait   CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_MAX_WAIT';  -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������ҋ@�ő�b��
  cv_adps_je_source  CONSTANT VARCHAR2(30) := 'XXCFO1_ADPS_JE_SOURCE'; -- XXCFO:�l���V�X�e���f�[�^�A�g�����Ώێd��\�[�X
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';      -- ��v����ID
--
  -- �R���J�����g�v���O�����Z�k��
  cv_sql_loader_name CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFO011A11D';  -- �l���V�X�e���f�[�^�A�g(SQL*Loader)
  cv_err_check_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031EC001C';   -- GLI/F�G���[�`�F�b�N
  cv_transfer_name   CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031GT001C';   -- GLI/F�]��
  cv_import_name     CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XX031JI001C';   -- GL�d��C���|�[�g�̋N��
  -- �R���J�����g�p�����[�^�l'Y/N'
  cv_conc_param_y    CONSTANT VARCHAR2(1) := 'Y';
  cv_conc_param_n    CONSTANT VARCHAR2(1) := 'N';
  -- �R���J�����g�p�����[�^�l'O'
  cv_conc_param_o    CONSTANT VARCHAR2(1) := 'O';
  -- �R���J�����gdev�t�F�[�Y
  cv_dev_phase_complete   CONSTANT VARCHAR2(30) := 'COMPLETE';    -- '����'
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal    CONSTANT VARCHAR2(30) := 'NORMAL';      -- '����'
  cv_dev_status_warn      CONSTANT VARCHAR2(30) := 'WARNING';     -- '�x��'
  cv_dev_status_err       CONSTANT VARCHAR2(30) := 'ERROR';       -- '�G���[';
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_adps_interval        NUMBER;                                 -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������`�F�b�N�ҋ@�b��
  gn_adps_max_wait        NUMBER;                                 -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������ҋ@�ő�b��
  gv_adps_je_source       gl_je_sources.je_source_name%TYPE;      -- XXCFO:�l���V�X�e���f�[�^�A�g�����Ώێd��\�[�X
  gv_user_je_source_name  gl_je_sources.user_je_source_name%TYPE; -- �����Ώێd��\�[�X��
  gn_set_of_bks_id        NUMBER;                                 -- ��v����ID
--
  -- FND_CONCURRENT.SUBMIT_REQUEST�̖߂�
  gn_submit_req_id        NUMBER;         -- �v��ID
  gn_submit_req_id_err_check  NUMBER;     -- �v��ID�FGLI/F�G���[�`�F�b�N
  -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�
  gb_wait_request         BOOLEAN;        -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l
  gv_wait_phase           VARCHAR2(100);  -- �v���t�F�[�Y
  gv_wait_status          VARCHAR2(100);  -- �v���X�e�[�^�X
  gv_wait_dev_phase       VARCHAR2(100);  -- �v���t�F�[�Y�R�[�h
  gv_wait_dev_status      VARCHAR2(100);  -- �v���X�e�[�^�X�R�[�h
  gv_wait_message         VARCHAR2(5000); -- �������b�Z�[�W
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_file_name IN  VARCHAR2,     --   �A�g�t�@�C����
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out     -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_target_file_name  -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ���O�o��
      ,iv_conc_param1  => iv_target_file_name  -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
  EXCEPTION
--
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
   * Procedure Name   : get_system_value
   * Description      : �e��V�X�e���l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- �v���O������
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
    -- �v���t�@�C������XXCFO:�l���V�X�e���f�[�^�A�g�v�������`�F�b�N�ҋ@�b��
    gn_adps_interval := FND_PROFILE.VALUE( cv_adps_interval );
    -- �擾�G���[��
    IF ( gn_adps_interval IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_interval ))
                                                                       -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������`�F�b�N�ҋ@�b��
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFO:�l���V�X�e���f�[�^�A�g�v�������ҋ@�ő�b��
    gn_adps_max_wait := FND_PROFILE.VALUE( cv_adps_max_wait );
    -- �擾�G���[��
    IF ( gn_adps_max_wait IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_max_wait ))
                                                                       -- XXCFO:�l���V�X�e���f�[�^�A�g�v�������ҋ@�ő�b��
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFO:�l���V�X�e���f�[�^�A�g�����Ώێd��\�[�X
    gv_adps_je_source := FND_PROFILE.VALUE( cv_adps_je_source );
    -- �擾�G���[��
    IF ( gv_adps_je_source IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_adps_je_source ))
                                                                       -- XXCFO:�l���V�X�e���f�[�^�A�g�����Ώێd��\�[�X
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������GL��v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:�l���V�X�e���f�[�^�A�g�����Ώێd��\�[�X�̎d��\�[�X�����擾����
    BEGIN
      SELECT gljs.user_je_source_name user_je_source_name
      INTO gv_user_je_source_name
      FROM gl_je_sources gljs
      WHERE gljs.je_source_name = gv_adps_je_source
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_011a01_008  -- �d��\�[�X�擾�G���[
                                                      ,cv_tkn_je_source   -- �g�[�N��'JE_SOURCE_NAME'
                                                      ,gv_adps_je_source) -- �d��\�[�X�R�[�h
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
  EXCEPTION
--
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
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_sql_loader
   * Description      : �l���V�X�e���f�[�^�A�g(SQL*Loader)�N������(A-3)
   ***********************************************************************************/
  PROCEDURE submit_request_sql_loader(
    iv_target_file_name IN  VARCHAR2,     --   �A�g�t�@�C����
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_sql_loader'; -- �v���O������
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
    -- �l���V�X�e���f�[�^�A�g(SQL*Loader)�R���J�����g���s
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_cfo,          -- �A�v���P�[�V�����Z�k��
                               program     => cv_sql_loader_name,      -- �R���J�����g�v���O�����Z�k��
                               argument1   => iv_target_file_name      -- �R���J�����g�p�����[�^(�t�@�C����)
                              );
    -- �R���J�����g�N���Ɏ��s�����ꍇ���b�Z�[�W���o��
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- �R���J�����g�N���G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
--
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
  END submit_request_sql_loader;
--
  /**********************************************************************************
   * Procedure Name   : wait_request
   * Description      : �l���V�X�e���f�[�^�A�g(SQL*Loader)�Ď�����(A-4)
   *                    BFA:GLI/F�G���[�`�F�b�N�Ď�����(A-9)
   *                    BFA:GLI/F�]���Ď�����(A-12)
   *                    �d��C���|�[�g�Ď�����(A-15)
   ***********************************************************************************/
  PROCEDURE wait_request(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_request'; -- �v���O������
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
    -- �l���V�X�e���f�[�^�A�g(SQL*Loader)�R���J�����g�v���Ď�
    gb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => gn_submit_req_id,
                                                       interval   => gn_adps_interval,
                                                       max_wait   => gn_adps_max_wait,
                                                       phase      => gv_wait_phase,
                                                       status     => gv_wait_status,
                                                       dev_phase  => gv_wait_dev_phase,
                                                       dev_status => gv_wait_dev_status,
                                                       message    => gv_wait_message
                                                      );
--
  EXCEPTION
--
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
  END wait_request;
--
  /**********************************************************************************
   * Procedure Name   : error_request_sql_loader
   * Description      : �l���V�X�e���f�[�^�A�g(SQL*Loader)�G���[����(A-5)
   ***********************************************************************************/
  PROCEDURE error_request_sql_loader(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_sql_loader'; -- �v���O������
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
    -- �l���V�X�e���f�[�^�A�g(SQL*Loader)�Ď��������G���[�̏ꍇ
    IF ( gb_wait_request = FALSE ) THEN
      -- �l���V�X�e���pGL�A�h�I��OIF�e�[�u����TRUNCATE����
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- �R���J�����g�Ď��G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- ����I���̏ꍇ�A�������s����
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      -- �l���V�X�e���pGL�A�h�I��OIF�e�[�u����TRUNCATE����
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- �Ď��v���O�����G���[�I��
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_sql_loader
                                                     )
                                                    ,cv_tkn_request    -- �g�[�N��'REQUEST_ID'
                                                    ,gn_submit_req_id) -- �l���V�X�e���f�[�^�A�g(SQL*Loader)������REQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
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
  END error_request_sql_loader;
--
  /**********************************************************************************
   * Procedure Name   : insert_xx03_gl_interface
   * Description      : �O�����JGL�A�h�I��OIF�}������(A-6)
   ***********************************************************************************/
  PROCEDURE insert_xx03_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xx03_gl_interface'; -- �v���O������
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
    -- �O�����JGL�A�h�I��OIF�ւ�INSERT����
    BEGIN
      INSERT INTO xx03_gl_interface (
        status,                                     -- �X�e�[�^�X
        set_of_books_id,                            -- ��v����ID
        accounting_date,                            -- �d��v���
        currency_code,                              -- �ʉ݃R�[�h
        date_created,                               -- �쐬��
        created_by,                                 -- �쐬�҃��[�U�[ID
        actual_flag,                                -- ���уt���O
        user_je_category_name,                      -- �d��J�e�S��
        user_je_source_name,                        -- �d��\�[�X��
        currency_conversion_date,                   -- �ʉ݊��Z��
        encumbrance_type_id,                        -- �\�Z�����^�C�vID
        budget_version_id,                          -- �\�Z�o�[�W����ID
        user_currency_conversion_type,              -- �ʉ݊��Z�^�C�v
        currency_conversion_rate,                   -- �ʉ݊��Z���[�g
        average_journal_flag,                       -- ���ώd��t���O
        originating_bal_seg_value,                  -- �o�����X�Z�O�����g�l
        segment1,                                   -- �Z�O�����g1�i��Ёj
        segment2,                                   -- �Z�O�����g2�i����j
        segment3,                                   -- �Z�O�����g3�i����Ȗځj
        segment4,                                   -- �Z�O�����g4�i�⏕�Ȗځj
        segment5,                                   -- �Z�O�����g5�i�ڋq�j
        segment6,                                   -- �Z�O�����g6�i��Ɓj
        segment7,                                   -- �Z�O�����g7(���Ƌ敪)
        segment8,                                   -- �Z�O�����g8(�\��)
        segment9,                                   -- �Z�O�����g9
        segment10,                                  -- �Z�O�����g10
        segment11,                                  -- �Z�O�����g11
        segment12,                                  -- �Z�O�����g12
        segment13,                                  -- �Z�O�����g13
        segment14,                                  -- �Z�O�����g14
        segment15,                                  -- �Z�O�����g15
        segment16,                                  -- �Z�O�����g16
        segment17,                                  -- �Z�O�����g17
        segment18,                                  -- �Z�O�����g18
        segment19,                                  -- �Z�O�����g19
        segment20,                                  -- �Z�O�����g20
        segment21,                                  -- �Z�O�����g21
        segment22,                                  -- �Z�O�����g22
        segment23,                                  -- �Z�O�����g23
        segment24,                                  -- �Z�O�����g24
        segment25,                                  -- �Z�O�����g25
        segment26,                                  -- �Z�O�����g26
        segment27,                                  -- �Z�O�����g27
        segment28,                                  -- �Z�O�����g28
        segment29,                                  -- �Z�O�����g29
        segment30,                                  -- �Z�O�����g30
        entered_dr,                                 -- �ؕ����z
        entered_cr,                                 -- �ݕ����z
        accounted_dr,                               -- �@�\�ʉݎؕ����z
        accounted_cr,                               -- �@�\�ʉݑݕ����z
        transaction_date,                           -- �g�����U�N�V������
        reference1,                                 -- ���t�@�����X�P(�o�b�`��)
        reference2,                                 -- ���t�@�����X�Q(�o�b�`�E�v)
        reference3,                                 -- ���t�@�����X�R
        reference4,                                 -- ���t�@�����X�S(�d��)
        reference5,                                 -- ���t�@�����X�T(�d��E�v)
        reference6,                                 -- ���t�@�����X�U(�d��Q��)
        reference7,                                 -- ���t�@�����X�V(�t�d��t���O)
        reference8,                                 -- ���t�@�����X�W
        reference9,                                 -- ���t�@�����X�X(�t�d�����)
        reference10,                                -- ���t�@�����X�P�O(�d�󖾍דE�v)
        reference11,                                -- ���t�@�����X�P�P
        reference12,                                -- ���t�@�����X�P�Q
        reference13,                                -- ���t�@�����X�P�R
        reference14,                                -- ���t�@�����X�P�S
        reference15,                                -- ���t�@�����X�P�T
        reference16,                                -- ���t�@�����X�P�U
        reference17,                                -- ���t�@�����X�P�V
        reference18,                                -- ���t�@�����X�P�W
        reference19,                                -- ���t�@�����X�P�X
        reference20,                                -- ���t�@�����X�Q�O
        reference21,                                -- ���t�@�����X�Q�P
        reference22,                                -- ���t�@�����X�Q�Q
        reference23,                                -- ���t�@�����X�Q�R
        reference24,                                -- ���t�@�����X�Q�S
        reference25,                                -- ���t�@�����X�Q�T
        reference26,                                -- ���t�@�����X�Q�U
        reference27,                                -- ���t�@�����X�Q�V
        reference28,                                -- ���t�@�����X�Q�W
        reference29,                                -- ���t�@�����X�Q�X
        reference30,                                -- ���t�@�����X�R�O
        je_batch_id,                                -- �d��o�b�`ID
        period_name,                                -- ��v����
        je_header_id,                               -- �d��w�b�_ID
        je_line_num,                                -- ���הԍ�
        chart_of_accounts_id,                       -- ����̌nID
        functional_currency_code,                   -- �@�\�ʉ݃R�[�h
        code_combination_id,                        -- CCID
        date_created_in_gl,                         -- GL�쐬��
        warning_code,                               -- �x���R�[�h
        status_description,                         -- �X�e�[�^�X���e
        stat_amount,                                -- ���v���l
        group_id,                                   -- �O���[�vID
        request_id,                                 -- �v��ID
        subledger_doc_sequence_id,                  -- ����v���땶���A��ID
        subledger_doc_sequence_value,               -- ����v���땶���A��
        attribute1,                                 -- DFF1(�ŋ敪)
        attribute2,                                 -- DFF2(�������R)
        gl_sl_link_id,                              -- GL_SL�����NID
        gl_sl_link_table,                           -- GL_SL�����N�e�[�u��
        attribute3,                                 -- DFF3(�`�[�ԍ�)
        attribute4,                                 -- DFF4(�N�[����)
        attribute5,                                 -- DFF5(�`�[���͎�)
        attribute6,                                 -- DFF6(�C�����`�[�ԍ�)
        attribute7,                                 -- DFF7(�\���P)
        attribute8,                                 -- DFF8(�\���Q)
        attribute9,                                 -- DFF9(�\���R)
        attribute10,                                -- DFF10(�\���S)
        attribute11,                                -- DFF11
        attribute12,                                -- DFF12
        attribute13,                                -- DFF13
        attribute14,                                -- DFF14
        attribute15,                                -- DFF15
        attribute16,                                -- DFF16
        attribute17,                                -- DFF17
        attribute18,                                -- DFF18
        attribute19,                                -- DFF19
        attribute20,                                -- DFF20
        context,                                    -- �R���e�L�X�g
        context2,                                   -- �R���e�L�X�g�Q
        invoice_date,                               -- ��������
        tax_code,                                   -- �ŋ��R�[�h
        invoice_identifier,                         -- ���������ʎq
        invoice_amount,                             -- ���������z
        context3,                                   -- �R���e�L�X�g�R
        ussgl_transaction_code,                     -- USSGL����R�[�h
        descr_flex_error_message,                   -- DFF�G���[���b�Z�[�W
        jgzz_recon_ref,                             -- �����Q��
        reference_date                              -- �Q�Ɠ�
      )
      SELECT xxagi.status,                          -- �X�e�[�^�X
             xxagi.set_of_books_id,                 -- ��v����ID
             xxagi.accounting_date,                 -- �d��v���
             xxagi.currency_code,                   -- �ʉ݃R�[�h
             xxagi.date_created,                    -- �쐬��
             xxagi.created_by,                      -- �쐬�҃��[�U�[ID
             xxagi.actual_flag,                     -- ���уt���O
             xxagi.user_je_category_name,           -- �d��J�e�S��
             xxagi.user_je_source_name,             -- �d��\�[�X��
             xxagi.currency_conversion_date,        -- �ʉ݊��Z��
             xxagi.encumbrance_type_id,             -- �\�Z�����^�C�vID
             xxagi.budget_version_id,               -- �\�Z�o�[�W����ID
             xxagi.user_currency_conversion_type,   -- �ʉ݊��Z�^�C�v
             xxagi.currency_conversion_rate,        -- �ʉ݊��Z���[�g
             xxagi.average_journal_flag,            -- ���ώd��t���O
             xxagi.originating_bal_seg_value,       -- �o�����X�Z�O�����g�l
             xxagi.segment1,                        -- �Z�O�����g1�i��Ёj
             xxagi.segment2,                        -- �Z�O�����g2�i����j
             xxagi.segment3,                        -- �Z�O�����g3�i����Ȗځj
             xxagi.segment4,                        -- �Z�O�����g4�i�⏕�Ȗځj
             xxagi.segment5,                        -- �Z�O�����g5�i�ڋq�j
             xxagi.segment6,                        -- �Z�O�����g6�i��Ɓj
             xxagi.segment7,                        -- �Z�O�����g7(���Ƌ敪)
             xxagi.segment8,                        -- �Z�O�����g8(�\��)
             xxagi.segment9,                        -- �Z�O�����g9
             xxagi.segment10,                       -- �Z�O�����g10
             xxagi.segment11,                       -- �Z�O�����g11
             xxagi.segment12,                       -- �Z�O�����g12
             xxagi.segment13,                       -- �Z�O�����g13
             xxagi.segment14,                       -- �Z�O�����g14
             xxagi.segment15,                       -- �Z�O�����g15
             xxagi.segment16,                       -- �Z�O�����g16
             xxagi.segment17,                       -- �Z�O�����g17
             xxagi.segment18,                       -- �Z�O�����g18
             xxagi.segment19,                       -- �Z�O�����g19
             xxagi.segment20,                       -- �Z�O�����g20
             xxagi.segment21,                       -- �Z�O�����g21
             xxagi.segment22,                       -- �Z�O�����g22
             xxagi.segment23,                       -- �Z�O�����g23
             xxagi.segment24,                       -- �Z�O�����g24
             xxagi.segment25,                       -- �Z�O�����g25
             xxagi.segment26,                       -- �Z�O�����g26
             xxagi.segment27,                       -- �Z�O�����g27
             xxagi.segment28,                       -- �Z�O�����g28
             xxagi.segment29,                       -- �Z�O�����g29
             xxagi.segment30,                       -- �Z�O�����g30
             xxagi.entered_dr,                      -- �ؕ����z
             xxagi.entered_cr,                      -- �ݕ����z
             xxagi.accounted_dr,                    -- �@�\�ʉݎؕ����z
             xxagi.accounted_cr,                    -- �@�\�ʉݑݕ����z
             xxagi.transaction_date,                -- �g�����U�N�V������
             xxagi.reference1,                      -- ���t�@�����X�P(�o�b�`��)
             xxagi.reference2,                      -- ���t�@�����X�Q(�o�b�`�E�v)
             xxagi.reference3,                      -- ���t�@�����X�R
             xxagi.reference4,                      -- ���t�@�����X�S(�d��)
             xxagi.reference5,                      -- ���t�@�����X�T(�d��E�v)
             xxagi.reference6,                      -- ���t�@�����X�U(�d��Q��)
             xxagi.reference7,                      -- ���t�@�����X�V(�t�d��t���O)
             xxagi.reference8,                      -- ���t�@�����X�W
             xxagi.reference9,                      -- ���t�@�����X�X(�t�d�����)
             xxagi.reference10,                     -- ���t�@�����X�P�O(�d�󖾍דE�v)
             xxagi.reference11,                     -- ���t�@�����X�P�P
             xxagi.reference12,                     -- ���t�@�����X�P�Q
             xxagi.reference13,                     -- ���t�@�����X�P�R
             xxagi.reference14,                     -- ���t�@�����X�P�S
             xxagi.reference15,                     -- ���t�@�����X�P�T
             xxagi.reference16,                     -- ���t�@�����X�P�U
             xxagi.reference17,                     -- ���t�@�����X�P�V
             xxagi.reference18,                     -- ���t�@�����X�P�W
             xxagi.reference19,                     -- ���t�@�����X�P�X
             xxagi.reference20,                     -- ���t�@�����X�Q�O
             xxagi.reference21,                     -- ���t�@�����X�Q�P
             xxagi.reference22,                     -- ���t�@�����X�Q�Q
             xxagi.reference23,                     -- ���t�@�����X�Q�R
             xxagi.reference24,                     -- ���t�@�����X�Q�S
             xxagi.reference25,                     -- ���t�@�����X�Q�T
             xxagi.reference26,                     -- ���t�@�����X�Q�U
             xxagi.reference27,                     -- ���t�@�����X�Q�V
             xxagi.reference28,                     -- ���t�@�����X�Q�W
             xxagi.reference29,                     -- ���t�@�����X�Q�X
             xxagi.reference30,                     -- ���t�@�����X�R�O
             xxagi.je_batch_id,                     -- �d��o�b�`ID
             xxagi.period_name,                     -- ��v����
             xxagi.je_header_id,                    -- �d��w�b�_ID
             xxagi.je_line_num,                     -- ���הԍ�
             xxagi.chart_of_accounts_id,            -- ����̌nID
             xxagi.functional_currency_code,        -- �@�\�ʉ݃R�[�h
             xxagi.code_combination_id,             -- CCID
             xxagi.date_created_in_gl,              -- GL�쐬��
             xxagi.warning_code,                    -- �x���R�[�h
             xxagi.status_description,              -- �X�e�[�^�X���e
             xxagi.stat_amount,                     -- ���v���l
             xxagi.group_id,                        -- �O���[�vID
             cn_request_id,                         -- �{�R���J�����g�v���O�����̗v��ID
             xxagi.subledger_doc_sequence_id,       -- ����v���땶���A��ID
             xxagi.subledger_doc_sequence_value,    -- ����v���땶���A��
             xxagi.attribute1,                      -- DFF1(�ŋ敪)
             xxagi.attribute2,                      -- DFF2(�������R)
             xxagi.gl_sl_link_id,                   -- GL_SL�����NID
             xxagi.gl_sl_link_table,                -- GL_SL�����N�e�[�u��
             xxagi.attribute3,                      -- DFF3(�`�[�ԍ�)
             xxagi.attribute4,                      -- DFF4(�N�[����)
             xxagi.attribute5,                      -- DFF5(�`�[���͎�)
             xxagi.attribute6,                      -- DFF6(�C�����`�[�ԍ�)
             xxagi.attribute7,                      -- DFF7(�\���P)
             xxagi.attribute8,                      -- DFF8(�\���Q)
             xxagi.attribute9,                      -- DFF9(�\���R)
             xxagi.attribute10,                     -- DFF10(�\���S)
             xxagi.attribute11,                     -- DFF11
             xxagi.attribute12,                     -- DFF12
             xxagi.attribute13,                     -- DFF13
             xxagi.attribute14,                     -- DFF14
             xxagi.attribute15,                     -- DFF15
             xxagi.attribute16,                     -- DFF16
             xxagi.attribute17,                     -- DFF17
             xxagi.attribute18,                     -- DFF18
             xxagi.attribute19,                     -- DFF19
             xxagi.attribute20,                     -- DFF20
             xxagi.context,                         -- �R���e�L�X�g
             xxagi.context2,                        -- �R���e�L�X�g�Q
             xxagi.invoice_date,                    -- ��������
             xxagi.tax_code,                        -- �ŋ��R�[�h
             xxagi.invoice_identifier,              -- ���������ʎq
             xxagi.invoice_amount,                  -- ���������z
             xxagi.context3,                        -- �R���e�L�X�g�R
             xxagi.ussgl_transaction_code,          -- USSGL����R�[�h
             xxagi.descr_flex_error_message,        -- DFF�G���[���b�Z�[�W
             xxagi.jgzz_recon_ref,                  -- �����Q��
             xxagi.reference_date                   -- �Q�Ɠ�
      FROM xxcfo_adps_gl_interface xxagi
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_011a01_005 -- �f�[�^�}���G���[
                                                      ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                      ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfo
                                                        ,cv_dict_tab_03glif
                                                       ) -- �O�����JGL�A�h�I��OIF�e�[�u��
                                                      ,cv_tkn_errmsg     -- �g�[�N��'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
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
  END insert_xx03_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : truncate_adps_gl_interface
   * Description      : �l���V�X�e���pGL�A�h�I��OIF�@TRUNCATE����(A-7)
   ***********************************************************************************/
  PROCEDURE truncate_adps_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'truncate_adps_gl_interface'; -- �v���O������
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
    -- �l���V�X�e���pGL�A�h�I��OIF�e�[�u����TRUNCATE����
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcfo.xxcfo_adps_gl_interface';
--
  EXCEPTION
--
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
  END truncate_adps_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_err_check
   * Description      : BFA:GLI/F�G���[�`�F�b�N�N������(A-8)
   ***********************************************************************************/
  PROCEDURE submit_request_err_check(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_err_check'; -- �v���O������
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
    -- BFA:GLI/F�G���[�`�F�b�N�R���J�����g���s
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- �A�v���P�[�V�����Z�k��
                               program     => cv_err_check_name,       -- �R���J�����g�v���O�����Z�k��
                               argument1   => gn_set_of_bks_id,        -- �R���J�����g�p�����[�^(��v����ID)
                               argument2   => cv_conc_param_n,         -- �R���J�����g�p�����[�^(GL I/F�e�[�u���W���敪)
                               argument3   => gv_user_je_source_name,  -- �R���J�����g�p�����[�^(�d��\�[�X��)
                               argument4   => cn_request_id,           -- �R���J�����g�p�����[�^(�v��ID)
                               argument5   => NULL                     -- �R���J�����g�p�����[�^(�O���[�vID)
                              );
    -- �R���J�����g�N���Ɏ��s�����ꍇ���b�Z�[�W���o��
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- �R���J�����g�N���G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- �㑱�R���J�����g�Ŏg�p����ׁABFA:GLI/F�G���[�`�F�b�N�̗v��ID��ۑ����Ă���
    gn_submit_req_id_err_check := gn_submit_req_id;
--
  EXCEPTION
--
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
  END submit_request_err_check;
--
  /**********************************************************************************
   * Procedure Name   : del_xx03_gl_interface
   * Description      : �O�����JGL�A�h�I��OIF�폜����(A-10-1)
   ***********************************************************************************/
  PROCEDURE del_xx03_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xx03_gl_interface'; -- �v���O������
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
    -- �e�[�u�����b�N�J�[�\��
    CURSOR del_table_lock_cur
    IS
      SELECT xxgi.ROWID      xxgi_rowid
      FROM xx03_gl_interface xxgi
      WHERE xxgi.request_id = gn_submit_req_id
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    del_table_lock_rec    del_table_lock_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O�����JGL�A�h�I��OIF���b�N���s��
    OPEN del_table_lock_cur;
--
    BEGIN
      <<delete_lines_loop>>
      LOOP
        FETCH del_table_lock_cur INTO del_table_lock_rec;
        EXIT delete_lines_loop WHEN del_table_lock_cur%NOTFOUND;
        --�Ώۃf�[�^���폜
        DELETE FROM xx03_gl_interface xxgi
        WHERE CURRENT OF del_table_lock_cur;
      END LOOP delete_lines_loop;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_011a01_007 -- �f�[�^�폜�G���[
                                                      ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                      ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfo
                                                        ,cv_dict_tab_03glif
                                                       ) -- �O�����JGL�A�h�I��OIF�e�[�u��
                                                      ,cv_tkn_errmsg     -- �g�[�N��'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        -- �J�[�\���N���[�Y
        CLOSE del_table_lock_cur;
        RAISE global_api_expt;
    END;
--
    -- �J�[�\���N���[�Y
    CLOSE del_table_lock_cur;
    COMMIT;
--
  EXCEPTION
--
    -- �e�[�u�����b�N�G���[
    WHEN lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_006 -- ���b�N�G���[
                                                    ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_tab_03glif
                                                     )) -- �O�����JGL�A�h�I��OIF�e�[�u��
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
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
  END del_xx03_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : error_request_err_check
   * Description      : BFA:GLI/F�G���[�`�F�b�N�G���[����(A-10)
   ***********************************************************************************/
  PROCEDURE error_request_err_check(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_err_check'; -- �v���O������
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
    lv_errbuf2 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg2 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- BFA:GLI/F�G���[�`�F�b�N�Ď��������G���[�̏ꍇ
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- �R���J�����g�Ď��G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
--
      -- =====================================================
      --  �O�����JGL�A�h�I��OIF�폜���� (A-10-1)
      -- =====================================================
      del_xx03_gl_interface(
         lv_errbuf2            -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg2);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �O�����JGL�A�h�I��OIF�폜�������ُ�I�����́A�O�����JGL�A�h�I��OIF�폜�����ُ̈���o�͂���
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := lv_errmsg2;
        lv_errbuf := lv_errbuf2;
      END IF;
--
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- ����I���̏ꍇ�A�������s����
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- �Ď��v���O�����G���[�I��
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_err_check
                                                     )
                                                    ,cv_tkn_request    -- �g�[�N��'REQUEST_ID'
                                                    ,gn_submit_req_id) -- BFA:GLI/F�G���[�`�F�b�N������REQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
--
      -- =====================================================
      --  �O�����JGL�A�h�I��OIF�폜���� (A-10-1)
      -- =====================================================
      del_xx03_gl_interface(
         lv_errbuf2            -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg2);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �O�����JGL�A�h�I��OIF�폜�������ُ�I�����́A�O�����JGL�A�h�I��OIF�폜�����ُ̈���o�͂���
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := lv_errmsg2;
        lv_errbuf := lv_errbuf2;
      END IF;
--
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
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
  END error_request_err_check;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_transfer
   * Description      : BFA:GLI/F�]���N������(A-11)
   ***********************************************************************************/
  PROCEDURE submit_request_transfer(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_transfer'; -- �v���O������
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
    -- BFA:GLI/F�]���R���J�����g���s
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- �A�v���P�[�V�����Z�k��
                               program     => cv_transfer_name,        -- �R���J�����g�v���O�����Z�k��
                               argument1   => gn_set_of_bks_id,        -- �R���J�����g�p�����[�^(��v����ID)
                               argument2   => gv_user_je_source_name,  -- �R���J�����g�p�����[�^(�d��\�[�X��)
                               argument3   => gn_submit_req_id_err_check, -- �R���J�����g�p�����[�^(�v��ID)
                               argument4   => cv_conc_param_n          -- �R���J�����g�p�����[�^(�x���f�[�^�̓]��)
                              );
    -- �R���J�����g�N���Ɏ��s�����ꍇ���b�Z�[�W���o��
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- �R���J�����g�N���G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
--
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
  END submit_request_transfer;
--
  /**********************************************************************************
   * Procedure Name   : error_request_transfer
   * Description      : BFA:GLI/F�]���G���[����(A-13)
   ***********************************************************************************/
  PROCEDURE error_request_transfer(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_transfer'; -- �v���O������
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
    -- BFA:GLI/F�]���Ď��������G���[�̏ꍇ
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- �R���J�����g�Ď��G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- ����I���̏ꍇ�A�������s����
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- �Ď��v���O�����G���[�I��
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_transfer
                                                     )
                                                    ,cv_tkn_request    -- �g�[�N��'REQUEST_ID'
                                                    ,gn_submit_req_id) -- BFA:GLI/F�]��������REQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
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
  END error_request_transfer;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_import
   * Description      : �d��C���|�[�g�N������(A-14)
   ***********************************************************************************/
  PROCEDURE submit_request_import(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_import'; -- �v���O������
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
    -- �d��C���|�[�g�R���J�����g���s
    gn_submit_req_id := 
    FND_REQUEST.SUBMIT_REQUEST(application => cv_msg_kbn_03,           -- �A�v���P�[�V�����Z�k��
                               program     => cv_import_name,          -- �R���J�����g�v���O�����Z�k��
                               argument1   => gn_set_of_bks_id,        -- �R���J�����g�p�����[�^(��v����ID)
                               argument2   => gv_adps_je_source,       -- �R���J�����g�p�����[�^(�d��\�[�X��)
                               argument3   => NULL,                    -- �R���J�����g�p�����[�^(�O���[�vID)
                               argument4   => cv_conc_param_n,         -- �R���J�����g�p�����[�^(�G���[��������ɓ]�L)
                               argument5   => cv_conc_param_n,         -- �R���J�����g�p�����[�^(�v��d��̍쐬)
                               argument6   => NULL,                    -- �R���J�����g�p�����[�^(���t�͈�(��))
                               argument7   => NULL,                    -- �R���J�����g�p�����[�^(���t�͈�(��))
                               argument8   => cv_conc_param_o          -- �R���J�����g�p�����[�^(DFF�C���|�[�g)
                              );
    -- �R���J�����g�N���Ɏ��s�����ꍇ���b�Z�[�W���o��
    IF ( gn_submit_req_id = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_002 -- �R���J�����g�N���G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
--
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
  END submit_request_import;
--
  /**********************************************************************************
   * Procedure Name   : error_request_import
   * Description      : �d��C���|�[�g�G���[����(A-16)
   ***********************************************************************************/
  PROCEDURE error_request_import(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_request_import'; -- �v���O������
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
    -- �d��C���|�[�g�Ď��������G���[�̏ꍇ
    IF ( gb_wait_request = FALSE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_003 -- �R���J�����g�Ď��G���[
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( gv_wait_dev_phase = cv_dev_phase_complete )
      AND ( gv_wait_dev_status = cv_dev_status_normal ) THEN
      -- ����I���̏ꍇ�A�������s����
      gn_normal_cnt := gn_normal_cnt + 1;
--
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_011a01_004 -- �Ď��v���O�����G���[�I��
                                                    ,cv_tkn_program    -- �g�[�N��'PROGRAM_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_import
                                                     )
                                                    ,cv_tkn_request    -- �g�[�N��'REQUEST_ID'
                                                    ,gn_submit_req_id) -- �d��C���|�[�g�N��������REQUEST_ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
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
  END error_request_import;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_file_name IN  VARCHAR2,     --   �A�g�t�@�C����
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 4;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       iv_target_file_name   -- �A�g�t�@�C����
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �e��V�X�e���l�擾����(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �l���V�X�e���f�[�^�A�g(SQL*Loader)�N������(A-3)
    -- =====================================================
    submit_request_sql_loader(
       iv_target_file_name   -- �A�g�t�@�C����
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �l���V�X�e���f�[�^�A�g(SQL*Loader)�Ď�����(A-4)
    -- =====================================================
    wait_request(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �l���V�X�e���f�[�^�A�g(SQL*Loader)�G���[����(A-5)
    -- =====================================================
    error_request_sql_loader(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �O�����JGL�A�h�I��OIF�}������(A-6)
    -- =====================================================
    insert_xx03_gl_interface(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �l���V�X�e���pGL�A�h�I��OIF�@TRUNCATE����(A-7)
    -- =====================================================
    truncate_adps_gl_interface(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�G���[�`�F�b�N�N������(A-8)
    -- =====================================================
    submit_request_err_check(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�G���[�`�F�b�N�Ď�����(A-9)
    -- =====================================================
    wait_request(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�G���[�`�F�b�N�G���[����(A-10)
    -- =====================================================
    error_request_err_check(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�]���N������(A-11)
    -- =====================================================
    submit_request_transfer(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�]���Ď�����(A-12)
    -- =====================================================
    wait_request(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  BFA:GLI/F�]���G���[����(A-13)
    -- =====================================================
    error_request_transfer(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �d��C���|�[�g�N������(A-14)
    -- =====================================================
    submit_request_import(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �d��C���|�[�g�Ď�����(A-15)
    -- =====================================================
    wait_request(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �d��C���|�[�g�G���[����(A-16)
    -- =====================================================
    error_request_import(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_target_file_name IN  VARCHAR2       --   �A�g�t�@�C����
  )
--
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       iv_target_file_name -- �A�g�t�@�C����
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt  := 1;
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
END XXCFO011A01C;
/
