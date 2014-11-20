CREATE OR REPLACE PACKAGE BODY XXCFR005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A01C(body)
 * Description      : ���b�N�{�b�N�X�C���|�[�g����������
 * MD.050           : MD050_CFR_005_A01_���b�N�{�b�N�X�C���|�[�g����������
 * MD.070           : MD050_CFR_005_A01_���b�N�{�b�N�X�C���|�[�g����������
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���  (A-1)
 *  get_profile_value      p �v���t�@�C���擾����          (A-2)
 *  conf_fb_file_date      p FB�t�@�C�����f�[�^�m�F����    (A-3)
 *  put_fb_file_info       p FB�t�@�C����񃍃O����        (A-4)
 *  gd_process_date        p �Ɩ��������t�擾������        (A-5)
 *  change_fb_file_name    p FB�t�@�C�����ύX����          (A-6)
 *  start_concurrent       p ���b�N�{�b�N�X�����N������    (A-7)
 *  conf_lockbox_data      p FB�t�@�C���f�[�^�捞�m�F����  (A-8)
 *  delete_fb_file         p FB�t�@�C���폜����            (A-9)
----------------------------------------------
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.00 SCS ���c ��N    ����쐬
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  file_not_exists_expt  EXCEPTION;      -- �t�@�C�����݃G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A01C';    -- �p�b�P�[�W��
  cv_pg_name         CONSTANT VARCHAR2(100) := 'ARLPLB';          -- �N������R���J�����g��
  cv_msg_kbn_ar      CONSTANT VARCHAR2(5)   := 'AR';              -- �A�v���P�[�V�����Z�k���FAR
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';           -- �A�v���P�[�V�����Z�k���FXXCFR
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_005a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_005a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_005a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012'; -- �R���J�����g�N���G���[���b�Z�[�W
  cv_msg_005a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00013'; -- �v���Ď��G���[���b�Z�[�W
  cv_msg_005a01_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00021'; -- �R���J�����g����I�����b�Z�[�W
  cv_msg_005a01_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00027'; -- ���b�N�{�b�N�X�x�����b�Z�[�W
  cv_msg_005a01_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00028'; -- ���b�N�{�b�N�X�G���[���b�Z�[�W
  cv_msg_005a01_032  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00032'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_005a01_039  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; -- �t�@�C���Ȃ��G���[
  cv_msg_005a01_061  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00061'; -- �t�@�C�������G���[���b�Z�[�W
  cv_msg_005a01_062  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00062'; -- �t�@�C���폜�G���[���b�Z�[�W
  cv_msg_005a01_063  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00063'; -- FB�f�[�^�捞�G���[
  cv_msg_005a01_064  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00064'; -- �t�@�C�����ύX�G���[���b�Z�[�W
  cv_msg_005a01_066  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00066'; -- �捞�G���[�ޔ�p�t�@�C�����o�̓��b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- �t�@�C���p�X
  cv_tkn_type        CONSTANT VARCHAR2(15) := 'FILE_TYPE';        -- �t�@�C���^�C�v
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_NUMBER';   -- �����ԍ�
  cv_tkn_prog_name   CONSTANT VARCHAR2(30) := 'PROGRAM_NAME';     -- �R���J�����g�v���O������
  cv_tkn_request     CONSTANT VARCHAR2(15) := 'REQUEST_ID';       -- �v��ID
  cv_tkn_file_name   CONSTANT VARCHAR2(15) := 'FB_FILE_NAME';     -- �Ώۂ̓`����
  cv_tkn_dev_phase   CONSTANT VARCHAR2(15) := 'DEV_PHASE';        -- DEV_PHASE
  cv_tkn_dev_status  CONSTANT VARCHAR2(15) := 'DEV_STATUS';       -- DEV_STATUS
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(15) := 'SQLERRM';          -- SQLERRM
--
  --�v���t�@�C��
  cv_org_id                   CONSTANT VARCHAR2(31) := 'ORG_ID';                           -- �g�DID
  cv_fb_file_path             CONSTANT VARCHAR2(31) := 'XXCFR1_FB_FILEPATH';               -- XXCFR:FB�t�@�C���i�[�p�X
  cv_prof_name_wait_interval  CONSTANT VARCHAR2(31) := 'XXCFR1_GENERAL_RECEIPT_INTERVAL';
                                                                       -- XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b��
  cv_prof_name_wait_max       CONSTANT VARCHAR2(31) := 'XXCFR1_GENERAL_RECEIPT_MAX_WAIT';
                                                                           -- XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b��
--
  -- �t�@�C���o��
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';            -- ���b�Z�[�W�o��
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';               -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';         -- ���t�t�H�[�}�b�g�i�N�����j
--
  -- �R���J�����gdev�t�F�[�Y
  cv_dev_phase_complete       CONSTANT VARCHAR2(30) := 'COMPLETE';          -- '����'
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal        CONSTANT VARCHAR2(30) := 'NORMAL';            -- '����'
  cv_dev_status_warn          CONSTANT VARCHAR2(30) := 'WARNING';           -- '�x��'
  cv_dev_status_err           CONSTANT VARCHAR2(30) := 'ERROR';             -- '�G���[';
--
  -- ���e�����l
  cv_flag_y                   CONSTANT VARCHAR2(10) := 'Y';                 -- �t���O�l�FY
  cv_flag_n                   CONSTANT VARCHAR2(10) := 'N';                 -- �t���O�l�FN
  cv_1                        CONSTANT VARCHAR2(10) := '1';                 -- '1'
  cv_slash                    CONSTANT VARCHAR2(10) := '/';                 -- '/'
  cv_arzeng                   CONSTANT VARCHAR2(10) := 'arzeng';            -- 'arzeng'
  cv_zengin                   CONSTANT VARCHAR2(10) := '102';               -- 'ZENGIN'
  cv_a                        CONSTANT VARCHAR2(10) := 'A';                 -- 'A'
  cv_period                   CONSTANT VARCHAR2(1)  := '.';                 -- �s���I�h
  cv_under_bar                CONSTANT VARCHAR2(1)  := '_';                 -- '_'
  cv_txt                      CONSTANT VARCHAR2(4)  := '.txt';              -- �t�@�C���̊g���q
  cn_1                        CONSTANT NUMBER       := 1;                   -- 1
--
  -- ���{�ꎫ��
  cv_dict_cfr005a01001        CONSTANT VARCHAR2(100) := 'CFR005A01001';     -- '�Ώۂ���'
  cv_dict_cfr005a01002        CONSTANT VARCHAR2(100) := 'CFR005A01002';     -- '�ΏۂȂ�'
  cv_dict_cfr005a01003        CONSTANT VARCHAR2(100) := 'CFR005A01003';     -- '���b�N�{�b�N�X����'
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_fb_filepath        fnd_profile_option_values.profile_option_value%TYPE;  -- FB�t�@�C���i�[�p�X
  gv_wait_interval      fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��Ԋu
  gv_wait_max           fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��ő厞��
  gn_org_id             NUMBER;                                               -- �g�DID
  gd_process_date       DATE;                                                 -- �Ɩ��������t
  gv_fb_file_copy       VARCHAR2(100);                                        -- ��������FB�t�@�C�������i�[����
  gv_transmission_name  ar_transmissions_all.transmission_name%TYPE;          -- �`����
  gn_request_id         fnd_concurrent_requests.request_id%TYPE;              -- ���b�N�{�b�N�X�����N�����̗v��ID
  gv_fb_file_err        VARCHAR2(100);                                        -- ��	�捞�G���[�ޔ�p��FB�t�@�C�������i�[����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_fb_file        IN      VARCHAR2,    -- FB�t�@�C����
    ov_errbuf         OUT     VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT     VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT     VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,iv_conc_param1  => iv_fb_file         -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUT�t�@�C���o��
      ,iv_conc_param1  => iv_fb_file         -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
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
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C������XXCFR:FB�t�@�C���i�[�p�X���擾
    gv_fb_filepath := FND_PROFILE.VALUE(cv_fb_file_path);
    -- �擾�G���[��
    IF (gv_fb_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_fb_file_path))
                                                       -- XXCFR:FB�t�@�C���i�[�p�X
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b�����擾
    gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
    -- �擾�G���[��
    IF (gv_wait_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval))
                                                       -- XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b��
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b�����擾
    gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
    -- �擾�G���[��
    IF (gv_wait_max IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max))
                                                       -- XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b��
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID���擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : conf_fb_file_date
   * Description      : FB�t�@�C�����f�[�^�m�F���� (A-3)
   ***********************************************************************************/
  PROCEDURE conf_fb_file_date(
    iv_fb_file              IN  VARCHAR2,           -- FB�t�@�C����
    ov_exist_file_data      OUT VARCHAR2,           -- �t�@�C�����Ƀf�[�^�����݂��邩����iY�F���݂���AN�F���݂��Ȃ��j
    ov_errbuf               OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conf_fb_file_date'; -- �v���O������
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
    cv_open_mode_r    CONSTANT VARCHAR2(10) := 'r';     -- �t�@�C���I�[�v�����[�h�i�ǂݍ��݁j
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;       -- �t�@�C�����f�[�^���p�ϐ�
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
    -- 
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �A�E�g�p�����[�^�̏�����
    ov_exist_file_data := 'N';
--
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_fb_filepath,
                      iv_fb_file,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C�����݂Ȃ�
    IF not(lb_fexists) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_039 -- �t�@�C���Ȃ�
                                                    ,cv_tkn_file
                                                    ,iv_fb_file
                                                    ,cv_tkn_path
                                                    ,gv_fb_filepath)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE file_not_exists_expt;
    END IF;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                    (
                      gv_fb_filepath
                     ,iv_fb_file
                     ,cv_open_mode_r
                    ) ;
--
    -- ====================================================
    -- �t�@�C����荞��
    -- ====================================================
    UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text );
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- FB�t�@�C���f�[�^�͑��݂���
    ov_exist_file_data := 'Y';
--
  EXCEPTION
--
    WHEN file_not_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN NO_DATA_FOUND THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END conf_fb_file_date;
--
  /**********************************************************************************
   * Procedure Name   : put_fb_file_info
   * Description      : FB�t�@�C����񃍃O���� (A-4)
   ***********************************************************************************/
  PROCEDURE put_fb_file_info(
    iv_fb_file              IN         VARCHAR2,            -- FB�t�@�C����
    iv_exist_file_data      IN         VARCHAR2,            -- �t�@�C�����Ƀf�[�^�����݂��邩����iY�F���݂���AN�F���݂��Ȃ��j
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_fb_file_info'; -- �v���O������
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
    lv_token  VARCHAR2(1000);  -- ���b�Z�[�W�g�[�N���̖߂�l���i�[����
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �t�@�C�����Ƀf�[�^������^�Ȃ��ɂ���āA�o�͂��郁�b�Z�[�W��ύX����
    IF (iv_exist_file_data = cv_flag_y) THEN -- �iY�F���݂���AN�F���݂��Ȃ��j
      lv_token := xxcfr_common_pkg.lookup_dictionary(
                                                     cv_msg_kbn_cfr
                                                    ,cv_dict_cfr005a01001 
                                                   );
    ELSE
      lv_token := xxcfr_common_pkg.lookup_dictionary(
                                                     cv_msg_kbn_cfr
                                                    ,cv_dict_cfr005a01002 
                                                   );
    END IF;
--
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_005a01_032 -- �t�@�C�����o�̓��b�Z�[�W
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                  ,iv_fb_file        -- �t�@�C����
                                                  ,cv_tkn_type       -- �g�[�N��'FILE_TYPE'
                                                  ,lv_token          -- �f�[�^����^�f�[�^�Ȃ�
                                                  )
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
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
  END put_fb_file_info;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_006 -- �Ɩ��������t�擾�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : change_fb_file_name
   * Description      : FB�t�@�C�����ύX���� (A-6)
   ***********************************************************************************/
  PROCEDURE change_fb_file_name(
    iv_fb_file              IN  VARCHAR2,                   -- FB�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_fb_file_name'; -- �v���O������
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
    -- ====================================================
    -- FB�t�@�C�����ύX
    -- ====================================================
    -- ��������t�@�C�����̕ҏW
    gv_fb_file_copy :=   substrb( iv_fb_file ,cn_1 ,instrb(iv_fb_file,cv_period) - cn_1 )
                       ||cv_under_bar
                       ||TO_CHAR( gd_process_date ,cv_format_date_ymd )
                       ||substrb( iv_fb_file ,instrb(iv_fb_file,cv_period) ,lengthb(iv_fb_file) - instrb(iv_fb_file ,cv_period) + cn_1 );
--
    -- �t�@�C���̕���
    UTL_FILE.FCOPY(gv_fb_filepath,
                   iv_fb_file,
                   gv_fb_filepath,
                   gv_fb_file_copy);
--
    -- �����t�@�C�������o��
    lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                          iv_name => cv_msg_005a01_064,
                                          iv_token_name1 => cv_tkn_file,
                                          iv_token_value1 => gv_fb_file_copy
                                         );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      lv_errmsg
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
      --��FB�t�@�C�����ύX�G���[����������ǉ�
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                     ,cv_msg_005a01_061    -- �t�@�C�����ύX�G���[���b�Z�[�W
                                                     ,cv_tkn_file          -- �g�[�N��'FILE_NAME'
                                                     ,iv_fb_file)
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END change_fb_file_name;
--
  /**********************************************************************************
   * Procedure Name   : start_concurrent
   * Description      : ���b�N�{�b�N�X�����N������ (A-7)
   ***********************************************************************************/
  PROCEDURE start_concurrent(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_concurrent'; -- �v���O������
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
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�B���N�g���p�X�擾
    CURSOR directoriey_cur
    IS
      SELECT directory_path   directoriey_path  -- �f�B���N�g���p�X
      FROM all_directories      ad              -- �f�B���N�g���I�u�W�F�N�g�i�[�e�[�u��
      WHERE ad.directory_name = gv_fb_filepath  -- �f�B���N�g���I�u�W�F�N�g��
    ;
    l_directoriey_rec   directoriey_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    submit_request_expt    EXCEPTION;  -- �R���J�����g���s�G���[��O
    wait_for_request_expt  EXCEPTION;  -- �R���J�����g�Ď��G���[��O
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
    -- �`�����ɍ���Ώۂ̃t�@�C�������Z�b�g����
    gv_transmission_name := gv_fb_file_copy;
--
    -- �����f�B���N�g���p�X���擾����
    OPEN directoriey_cur;
    FETCH directoriey_cur INTO l_directoriey_rec;
    CLOSE directoriey_cur;
--
    -- �R���J�����g���s
    gn_request_id := 
    FND_REQUEST.SUBMIT_REQUEST( application => cv_msg_kbn_ar                             -- �A�v���P�[�V�����Z�k��
                               ,program     => cv_pg_name                                -- �R���J�����g�v���O������
                               ,argument1   => cv_flag_y                                 -- �V�K�`��
                               ,argument2   => NULL                                      -- �`��ID
                               ,argument3   => NULL                                      -- �����v��ID
                               ,argument4   => gv_transmission_name                      -- �`����
                               ,argument5   => cv_flag_y                                 -- �C���|�[�g�̔��s
                               ,argument6   =>   l_directoriey_rec.directoriey_path
                                               ||cv_slash
                                               ||gv_fb_file_copy                         -- �f�[�^�E�t�@�C��
                               ,argument7   => cv_arzeng                                 -- �Ǘ��t�@�C��
                               ,argument8   => cv_zengin                                 -- �`���t�H�[�}�b�gID
                               ,argument9   => cv_flag_n                                 -- ���؂̔��s
                               ,argument10  => NULL                                      -- ���֘A�������x��
                               ,argument11  => NULL                                      -- ���b�N�{�b�N�XID
                               ,argument12  => NULL                                      -- GL�L����
                               ,argument13  => NULL                                      -- ���|�[�g�E�t�H�[�}�b�g
                               ,argument14  => NULL                                      -- �����p�b�`�̂�
                               ,argument15  => cv_flag_n                                 -- �p�b�`�]�L�̔��s
                               ,argument16  => cv_a                                      -- �J�i�����I�v�V����
                               ,argument17  => NULL                                      -- �ꕔ���z�̓]�L�܂��͑S�����̋���
                               ,argument18  => NULL                                      -- USSGL����R�[�h
                               ,argument19  => gn_org_id                                 -- �g�DID
                              );
--
    IF (gn_request_id = 0) THEN
      RAISE submit_request_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- �R���J�����g�v���Ď�
    lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => gn_request_id    -- �v��ID
                                                       ,interval   => gv_wait_interval -- �R���J�����g�Ď��Ԋu
                                                       ,max_wait   => gv_wait_max      -- �R���J�����g�Ď��ő厞��
                                                       ,phase      => lv_phase         -- �v���t�F�[�Y
                                                       ,status     => lv_status        -- �v���X�e�[�^�X
                                                       ,dev_phase  => lv_dev_phase     -- �v���t�F�[�Y�R�[�h
                                                       ,dev_status => lv_dev_status    -- �v���X�e�[�^�X�R�[�h
                                                       ,message    => lv_message       -- �������b�Z�[�W
                                                      );
    IF (lb_wait_request) THEN
      IF    (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_normal)
      THEN
        -- ����I���̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                              iv_name => cv_msg_005a01_021,
                                              iv_token_name1 => cv_tkn_prog_name,
                                              iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      )
                                             );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSIF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_warn)
      THEN
        -- �x���I���̏ꍇ
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr        -- 'XXCFR'
                              ,cv_msg_005a01_027
                              ,cv_tkn_request        -- �g�[�N��'REQUEST_ID'
                              ,gn_request_id         -- �v��ID
                              ,cv_tkn_file_name      -- �g�[�N��'FB_FILE_NAME'
                              ,gv_transmission_name  -- �Ώۂ̓`����
                              ,cv_tkn_dev_phase      -- �g�[�N��'DEV_PHASE'
                              ,lv_dev_phase          -- DEV_PHASE
                              ,cv_tkn_dev_status     -- �g�[�N��'DEV_STATUS'
                              ,lv_dev_status         -- DEV_STATUS
                            )
                           ,1
                           ,5000
                          );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSE
        -- �G���[�I���̏ꍇ
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr        -- 'XXCFR'
                              ,cv_msg_005a01_028
                              ,cv_tkn_request        -- �g�[�N��'REQUEST_ID'
                              ,gn_request_id         -- �v��ID
                              ,cv_tkn_file_name      -- �g�[�N��'FB_FILE_NAME'
                              ,gv_transmission_name  -- �Ώۂ̓`����
                              ,cv_tkn_dev_phase      -- �g�[�N��'DEV_PHASE'
                              ,lv_dev_phase          -- DEV_PHASE
                              ,cv_tkn_dev_status     -- �g�[�N��'DEV_STATUS'
                              ,lv_dev_status         -- DEV_STATUS
                            )
                           ,1
                           ,5000
                          );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      END IF;
    ELSE
      RAISE wait_for_request_expt;
    END IF;
--
  EXCEPTION
--
    -- *** �v�����s���s�� ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.SUBMIT_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W������Ύ擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a01_012,   -- �R���J�����g�N���G���[���b�Z�[�W
                                            iv_token_name1  => cv_tkn_prog_name,    -- �g�[�N��'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      )
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
--
    -- *** �v���Ď����s�� ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.WAIT_FOR_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W������Ύ擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a01_013,   -- �v���Ď��G���[���b�Z�[�W
                                            iv_token_name1  => cv_tkn_prog_name,    -- �g�[�N��'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      ),
                                            iv_token_name2  => cv_tkn_sqlerrm,      -- �g�[�N��'SQLERRM'
                                            iv_token_value2 => SQLERRM
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
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
  END start_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : conf_lockbox_data
   * Description      : FB�t�@�C���f�[�^�捞�m�F���� (A-8)
   ***********************************************************************************/
  PROCEDURE conf_lockbox_data(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conf_lockbox_data'; -- �v���O������
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
    cv_open_mode_r    CONSTANT VARCHAR2(10) := 'r';     -- �t�@�C���I�[�v�����[�h�i�ǂݍ��݁j
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾�i�Ǎ����p�j
    lf_err_file_hand    UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾�i�������p�j
    lv_csv_text         VARCHAR2(32000) ;       -- �t�@�C�����f�[�^���p�ϐ�
    -- 
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����ԍ����݃`�F�b�N
    CURSOR account_chk_cur(
      iv_origination IN VARCHAR2
    ) 
    IS
      SELECT 'EXISTS' account_chk
      FROM ar_payments_interface_all  apia -- ���b�N�{�b�N�XIF
          ,ar_transmissions_all       ata  -- ���b�N�{�b�N�X�f�[�^�`�������e�[�u��
          ,ar_lockboxes_all           al   -- ���b�N�{�b�N�X�e�[�u��
          ,ar_batch_sources           bs   -- �����\�[�X�e�[�u��
          ,ap_bank_accounts           ba   -- ��s�����e�[�u��
      WHERE ata.transmission_name            = gv_transmission_name         -- �`����
        AND ata.org_id                       = gn_org_id                    -- �g�DID
        AND ata.transmission_request_id      = apia.transmission_request_id -- �������N�G�X�gID
        AND apia.record_type                 = cv_1                         -- ���R�[�h���ʎq�i1�F�w�b�_�j
        AND apia.origination                 = al.bank_origination_number   -- ��s�̔Ԕԍ�
        AND al.batch_source_id               = bs.batch_source_id           -- �����\�[�XID
        AND bs.default_remit_bank_account_id = ba.bank_account_id           -- ��s����ID
        AND lpad(ba.bank_account_num,10,'0') = iv_origination               -- �����ԍ�
    ;
--
    l_account_chk_rec   account_chk_cur%ROWTYPE;
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
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v���i�Ǎ����p�j
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                    (
                      gv_fb_filepath
                     ,gv_fb_file_copy
                     ,cv_open_mode_r
                    ) ;
--
    -- ====================================================
    -- ��������FB�t�@�C�������ŏ��̍s����Ō�̍s�܂ŏ��ɓǍ���
    -- �t�@�C����̎�������ԍ����A���b�N�{�b�N�XIF��ɑ��݂��邩�m�F���܂�
    -- ====================================================
    <<account_loop>>
    LOOP
      BEGIN
        -- ====================================================
        -- �t�@�C���ǂݍ���
        -- ====================================================
        UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- �f�[�^�敪(1���ڂ�1byte)��'1'�i�w�b�_�j�̏ꍇ�`�F�b�N�Ώ�
        -- ====================================================
        IF (SUBSTRB(lv_csv_text,1,1) = cv_1) THEN -- ���R�[�h���ʎq�i1�F�w�b�_�j
--
          -- �Ώی������W�v����
          gn_target_cnt := gn_target_cnt + 1;
          -- ====================================================
          -- �����ԍ������b�N�{�b�N�XIF�ɑ��݂��邩�`�F�b�N
          -- ====================================================
          -- �ϐ�������
          l_account_chk_rec.account_chk := '';
          --
          OPEN account_chk_cur(SUBSTRB(lv_csv_text,64,10));
          FETCH account_chk_cur INTO l_account_chk_rec;
          IF (account_chk_cur%FOUND) THEN
            -- ====================================================
            -- ����Ɏ捞�܂�Ă���ꍇ
            -- ====================================================
            -- �����������W�v����
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            -- �G���[�������W�v����
            gn_error_cnt := gn_error_cnt + 1;
            -- ====================================================
            -- �t�s�k�t�@�C���I�[�v���i�����p�j
            -- ���̃��[�v�ɓ������P��ڂ̂݃t�@�C���I�[�v������
            -- �iov_retcode���x���X�e�[�^�X�ɂȂ��Ă��Ȃ����j
            -- ====================================================
            IF (ov_retcode <> cv_status_warn) THEN
              -- �捞�G���[�ޔ�p�t�@�C�����̕ҏW
              gv_fb_file_err :=   TO_CHAR(gn_request_id)
                                ||cv_under_bar
                                ||TO_CHAR( gd_process_date ,cv_format_date_ymd )
                                ||cv_txt
                                ;
--
              --�P�s���s
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
              );
              -- �捞�G���[�ޔ�p�t�@�C�������o��
              lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_005a01_066,
                                            iv_token_name1 => cv_tkn_file,
                                            iv_token_value1 => gv_fb_file_err
                                           );
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                lv_errmsg
                                );
--
              lf_err_file_hand := UTL_FILE.FOPEN
                                  (
                                    gv_fb_filepath
                                   ,gv_fb_file_err
                                   ,cv_open_mode_w
                                   );
            END IF;
--
            -- �x���I���X�e�[�^�X
            ov_retcode := cv_status_warn;
            -- FB�f�[�^�捞�G���[���b�Z�[�W
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfr      -- 'XXCFR'
                                    ,cv_msg_005a01_063
                                    ,cv_tkn_account   -- �g�[�N��'ACCOUNT_NUMBER'
                                    ,SUBSTRB(lv_csv_text,64,10)
                                  )
                                 ,1
                                 ,5000
                                );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
          END IF;
          CLOSE account_chk_cur;
--
        END IF;
--
        -- �����ԍ����擾�ł��Ă��Ȃ��ꍇ�i�����擾�p�̃J�[�\���Œl���擾�ł��Ă��Ȃ��ꍇ�j
        IF (l_account_chk_rec.account_chk <> 'EXISTS') THEN
          -- ====================================================
          -- �t�@�C����������
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_err_file_hand, lv_csv_text ) ;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          EXIT;
      END;
--
    END LOOP account_loop ;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y�i�Ǎ����p�j
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y�i�������p�j
    -- ====================================================
    UTL_FILE.FCLOSE( lf_err_file_hand );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      UTL_FILE.FCLOSE_ALL;
      --���J�[�\���N���[�Y�֐���ǉ�
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      UTL_FILE.FCLOSE_ALL;
      --���J�[�\���N���[�Y�֐���ǉ�
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      UTL_FILE.FCLOSE_ALL;
      --���J�[�\���N���[�Y�֐���ǉ�
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END conf_lockbox_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_fb_file
   * Description      : FB�t�@�C���폜���� (A-9)
   ***********************************************************************************/
  PROCEDURE delete_fb_file(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_fb_file'; -- �v���O������
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
    cv_open_mode_r    CONSTANT VARCHAR2(10) := 'r';     -- �t�@�C���I�[�v�����[�h�i�ǂݍ��݁j
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ====================================================
    -- ��������FB�t�@�C���̍폜
    -- ====================================================
    UTL_FILE.FREMOVE(gv_fb_filepath,
                     gv_fb_file_copy);
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
      --��FB�t�@�C���폜�G���[����������ǉ�
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                     ,cv_msg_005a01_062    -- �t�@�C���폜�G���[���b�Z�[�W
                                                     ,cv_tkn_file          -- �g�[�N��'FILE_NAME'
                                                     ,gv_fb_file_copy)
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_fb_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_fb_file             IN      VARCHAR2,         --   FB�t�@�C����
    ov_errbuf              OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_exist_file_data VARCHAR2(1);     -- �t�@�C�����Ƀf�[�^�����݂��邩����iY�F���݂���AN�F���݂��Ȃ��j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
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
       iv_fb_file             -- FB�t�@�C����
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  FB�t�@�C�����f�[�^�m�F���� (A-3)
    -- =====================================================
    conf_fb_file_date(
       iv_fb_file             -- FB�t�@�C����
      ,lv_exist_file_data     -- �t�@�C�����Ƀf�[�^�����݂��邩����iY�F���݂���AN�F���݂��Ȃ��j
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  FB�t�@�C����񃍃O����(A-4)
    -- =====================================================
    put_fb_file_info(
       iv_fb_file             -- FB�t�@�C����
      ,lv_exist_file_data     -- �t�@�C�����Ƀf�[�^�����݂��邩����iY�F���݂���AN�F���݂��Ȃ��j
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ώۃt�@�C���Ƀf�[�^�����݂��Ȃ��ꍇ�A�㑱�̏����͍s��Ȃ�
    -- =====================================================
    IF (lv_exist_file_data = cv_flag_y) THEN -- �iY�F���݂���AN�F���݂��Ȃ��j
--
      -- =====================================================
      --  �Ɩ��������t�擾���� (A-5)
      -- =====================================================
      get_process_date(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  FB�t�@�C�����ύX���� (A-6)
      -- =====================================================
      change_fb_file_name(
         iv_fb_file             -- FB�t�@�C����
        ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ���b�N�{�b�N�X�����N������ (A-7)
      -- =====================================================
      start_concurrent(
         lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  FB�t�@�C���f�[�^�捞�m�F���� (A-8)
      -- =====================================================
      conf_lockbox_data(
         lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        --(�x������)
        ov_retcode := cv_status_warn;
      END IF;
--
      -- =====================================================
      --  FB�t�@�C���폜���� (A-9)
      -- =====================================================
      delete_fb_file(
         lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                 OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_fb_file             IN      VARCHAR2          --    FB�t�@�C����
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
       iv_fb_file       -- FB�t�@�C����
      ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
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
END XXCFR005A01C;
/
