CREATE OR REPLACE PACKAGE BODY XXCOS016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A01C (body)
 * Description      : �l���V�X�e�������A�̔����ь����f�[�^(I/F)�쐬����
 * MD.050           : �l���V�X�e�������̔����уf�[�^�̍쐬�i�����j COS_016_A01
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  get_common             ���ʒl�擾����(A-1)
 *  file_open              �t�@�C���쐬(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   T.kitajima       �V�K�쐬
 *  2009/02/17    1.1   T.kitajima       get_msg�̃p�b�P�[�W���C��
 *  2009/02/24    1.2   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
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
  -- ���[�U�[��`��O
  -- ===============================
--
  global_get_profile_expt   EXCEPTION;  --�v���t�@�C���擾��O
  global_make_file_expt     EXCEPTION;  --�t�@�C���I�[�v����O
  global_no_data_expt       EXCEPTION;  --�Ώۃf�[�^�O���G���[
  global_common_expt        EXCEPTION;  --���ʗ�O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS016A01C';        -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  cv_current_appl_short_nm            fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';             --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  cv_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00004';  --�v���t�@�C���擾�G���[
  cv_msg_file_open_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00009';   --�t�@�C���I�[�v���G���[
  cv_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';   --�f�[�^�擾�G���[���b�Z�[�W
  cv_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';   --API�ďo�G���[���b�Z�[�W
  cv_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';   --����0���p���b�Z�[�W
  cv_msg_file_nm            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13351';   --�t�@�C�������b�Z�[�W
  cv_msg_mem1_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13352';   --���b�Z�[�W�p������
  cv_msg_mem2_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13353';   --���b�Z�[�W�p������
  cv_msg_mem3_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13354';   --���b�Z�[�W�p������
  --�g�[�N��
  cv_tkn_profile            CONSTANT  VARCHAR2(10)  := 'PROFILE';           --�v���t�@�C��
  cv_tkn_date_to            CONSTANT  VARCHAR2(10)  := 'TABLE_NAME';        --�e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(10)  := 'KEY_DATA';          --�L�[�f�[�^
  cv_tkn_api_name           CONSTANT  VARCHAR2(10)  := 'API_NAME';          --�`�o�h����
  cv_tkn_file_name          CONSTANT  VARCHAR2(10)  := 'FILE_NAME';         --�t�@�C���p�X
  --���b�Z�[�W�p������
  cv_str_profile_nm         CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem1_date
                                                      );
  cv_str_request_id_nm      CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem2_date
                                                      );
  cv_str_file_name          CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem3_date
                                                      );
  cv_csv                    CONSTANT  VARCHAR2(1)   := ','; -- �J���}
  cv_sla                    CONSTANT  VARCHAR2(1)   := '/'; -- �X���b�V��
  cv_dub                    CONSTANT  VARCHAR2(1)   := '"'; -- �_�u���N�H�[�g
  --�v���t�@�C������
  cv_Profile_dir            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_OUTBOUND_PERSONNEL_DIR';  -- I/F�o�͐�f�B���N�g��
  cv_Profile_file           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_PERSONNEL_MONTHS_FILE';   -- I/F�t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_output_dir             VARCHAR2(255);                                 --  �l�������A�E�g�o�E���h�p�f�B���N�g���p�X
  gv_output_file            VARCHAR2(255);                                 --  �l�������A�E�g�o�E���h�p�t�@�C����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_nothing_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�
    --
    -- *** ���[�J���ϐ� ***
--
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_nothing_msg
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
  EXCEPTION
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
   * Procedure Name   : get_common
   * Description      : ���ʃf�[�^�擾(A-1)
   ***********************************************************************************/
  PROCEDURE get_common(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    lv_key_info VARCHAR2(5000);  --key���
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
    --==============================================
    -- 1.�l�������A�E�g�o�E���h�p�f�B���N�g���p�X
    --==============================================
    gv_output_dir := FND_PROFILE.VALUE(cv_Profile_dir);
    --�f�B���N�g���擾
    IF ( gv_output_dir IS NULL ) THEN
      --�L�[���ҏW
      XXCOS_COMMON_PKG.makeup_key_info(
                                     ov_errbuf      =>  lv_errbuf          --�G���[�E���b�Z�[�W
                                    ,ov_retcode     =>  lv_retcode         --���^�[���R�[�h
                                    ,ov_errmsg      =>  lv_errmsg          --���[�U�E�G���[�E���b�Z�[�W
                                    ,ov_key_info    =>  lv_key_info        --�ҏW���ꂽ�L�[���
                                    ,iv_item_name1  =>  cv_str_profile_nm
                                    ,iv_data_value1 =>  cv_Profile_dir
                                    );
      --���b�Z�[�W
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --==============================================
    -- 2.�l���V�X�e�����������t�@�C����
    --==============================================
    --
    gv_output_file := FND_PROFILE.VALUE(cv_Profile_file);
    --�t�@�C�������擾
    IF ( gv_output_file IS NULL ) THEN
      --�L�[���ҏW
      XXCOS_COMMON_PKG.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf          --�G���[�E���b�Z�[�W
                                       ,ov_retcode     =>  lv_retcode         --���^�[���R�[�h
                                       ,ov_errmsg      =>  lv_errmsg          --���[�U�E�G���[�E���b�Z�[�W
                                       ,ov_key_info    =>  lv_key_info        --�ҏW���ꂽ�L�[���
                                       ,iv_item_name1  =>  cv_str_profile_nm
                                       ,iv_data_value1 =>  cv_Profile_file
                                      );
      --���b�Z�[�W
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_current_appl_short_nm
                    ,iv_name         => cv_msg_file_nm
                    ,iv_token_name1  => cv_tkn_file_name
                    ,iv_token_value1 => gv_output_file
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
  EXCEPTION
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_common;
--
  /**********************************************************************************
   * Procedure Name   : <file_open>
   * Description      : �t�@�C���쐬(A-3)
   ***********************************************************************************/
  PROCEDURE file_open(
    ot_handle     OUT UTL_FILE.FILE_TYPE,   --   �t�@�C���n���h��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
--
  BEGIN
----
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
    ot_handle := UTL_FILE.FOPEN(gv_output_dir, gv_output_file, 'W');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END file_open;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_output   VARCHAR2(5000);      -- �t�@�C���o�͗p
    lt_handle   UTL_FILE.FILE_TYPE;  -- �t�@�C���n���h��
    ln_count    NUMBER;              -- ��������
    lv_key_info VARCHAR2(5000);      -- key���
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --�l�������e�[�u���f�[�^�擾�p(A-2)
    CURSOR data_cur
    IS
      SELECT employee_code                    as employee_code,              --�]�ƈ��R�[�h
             results_date                     as results_date,               --�N��
             base_code                        as base_code,                  --���_�R�[�h
             division_code                    as division_code,              --�{���R�[�h
             NULL                             as NULL1,                      --�\��1
             NULL                             as NULL2,                      --�\��2
             NULL                             as NULL3,                      --�\��3
             NULL                             as NULL4,                      --�\��4
             p_sale_norma                     as p_sale_norma,               --����m���}
             p_sale_amount                    as p_sale_amount,              --������z
             p_sale_achievement_rate          as p_sale_achievement_rate,    --����B����
             p_new_contribution_sale          as p_new_contribution_sale,    --�V�K�v������
             p_new_norma                      as p_new_norma,                --�V�K�m���}
             p_new_achievement_rate           as p_new_achievement_rate,     --�V�K�B����
             p_new_count_sum                  as p_new_count_sum,            --�V�K�������v
             p_new_count_vd                   as p_new_count_vd,             --�V�K�����x���_�[
             p_position_point                 as p_position_point,           --���iPOINT
             p_new_point                      as p_new_point,                --�V�KPOINT
             g_sale_norma                     as g_sale_norma,               --������m���}
             g_sale_amount                    as g_sale_amount,              --��������z
             g_sale_achievement_rate          as g_sale_achievement_rate,    --������B����
             g_new_contribution_sale          as g_new_contribution_sale,    --���V�K�v������
             g_new_norma                      as g_new_norma,                --���V�K�m���}
             g_new_achievement_rate           as g_new_achievement_rate,     --���V�K�B����
             g_new_count_sum                  as g_new_count_sum,            --���V�K�������v
             g_new_count_vd                   as g_new_count_vd,             --���V�K�����x���_�[
             g_position_point                 as g_position_point,           --�����iPOINT
             g_new_point                      as g_new_point,                --���V�KPOINT
             b_sale_norma                     as b_sale_norma,               --������m���}
             b_sale_amount                    as b_sale_amount,              --��������z
             b_sale_achievement_rate          as b_sale_achievement_rate,    --������B����
             b_new_contribution_sale          as b_new_contribution_sale,    --���V�K�v������
             b_new_norma                      as b_new_norma,                --���V�K�m���}
             b_new_count_sum                  as b_new_count_sum,            --���V�K�������v
             b_new_count_vd                   as b_new_count_vd,             --���V�K�����x���_�[
             b_position_point                 as b_position_point,           --�����iPOINT
             b_new_point                      as b_new_point,                --���V�KPOINT
             a_sale_norma                     as a_sale_norma,               --�n����m���}
             a_sale_amount                    as a_sale_amount,              --�n������z
             a_sale_achievement_rate          as a_sale_achievement_rate,    --�n����B����
             a_new_contribution_sale          as a_new_contribution_sale,    --�n�V�K�v������
             a_new_norma                      as a_new_norma,                --�n�V�K�m���}
             a_new_count_sum                  as a_new_count_sum,            --�n�V�K�������v
             a_new_count_vd                   as a_new_count_vd,             --�n�V�K�����x���_�[
             a_position_point                 as a_position_point,           --�n���iPOINT
             a_new_point                      as a_new_point,                --�n�V�KPOINT
             d_sale_norma                     as d_sale_norma,               --�{����m���}
             d_sale_amount                    as d_sale_amount,              --�{������z
             d_sale_achievement_rate          as d_sale_achievement_rate,    --�{����B����
             d_new_contribution_sale          as d_new_contribution_sale,    --�{�V�K�v������
             d_new_norma                      as d_new_norma,                --�{�V�K�m���}
             d_new_count_sum                  as d_new_count_sum,            --�{�V�K�������v
             d_new_count_vd                   as d_new_count_vd,             --�{�V�K�����x���_�[
             d_position_point                 as d_position_point,           --�{���iPOINT
             d_new_point                      as d_new_point,                --�{�V�KPOINT
             s_sale_norma                     as s_sale_norma,               --�S����m���}
             s_sale_amount                    as s_sale_amount,              --�S������z
             s_sale_achievement_rate          as s_sale_achievement_rate,    --�S����B����
             s_new_contribution_sale          as s_new_contribution_sale,    --�S�V�K�v������
             s_new_norma                      as s_new_norma,                --�S�V�K�m���}
             s_new_count_sum                  as s_new_count_sum,            --�S�V�K�������v
             s_new_count_vd                   as s_new_count_vd,             --�S�V�K�����x���_�[
             s_position_point                 as s_position_point,           --�S���iPOINT
             s_new_point                      as s_new_point                 --�S�V�KPOINT
      FROM xxcos_for_adps_monthly_if
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec               data_cur%ROWTYPE;
--
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
    -- ===============================
    -- A-0.��������
    -- ===============================
    init(
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_api_others_expt;
    END IF;
    -- ===============================
    -- A-1.���ʃf�[�^�擾
    -- ===============================
    get_common(
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
--
    --==============================================
    -- A-3. �t�@�C���쐬����
    --==============================================
    file_open(
      ot_handle               =>  lt_handle,                  -- �t�@�C���n���h��
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      XXCOS_COMMON_PKG.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf          --�G���[�E���b�Z�[�W
                                       ,ov_retcode     =>  lv_retcode         --���^�[���R�[�h
                                       ,ov_errmsg      =>  lv_errmsg          --���[�U�E�G���[�E���b�Z�[�W
                                       ,ov_key_info    =>  lv_key_info        --�ҏW���ꂽ�L�[���
                                       ,iv_item_name1  =>  cv_str_file_name
                                       ,iv_data_value1 =>  gv_output_dir || cv_sla || gv_output_file
                                      );
        RAISE global_make_file_expt;
    END IF;
    --==============================================
    -- A-4. �f�[�^�o�͏���
    --==============================================
    ln_count := 0;
    <<for_loop>>
    FOR l_data_rec IN data_cur LOOP
      --������
      lv_output := NULL;
      ln_count  := ln_count + 1;
      --�ϐ��ɐݒ�(�J���}��؂�)
      lv_output := lv_output || cv_dub || l_data_rec.employee_code           || cv_dub || cv_csv;  --�]�ƈ��R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.results_date            || cv_dub || cv_csv;  --�N��
      lv_output := lv_output || cv_dub || l_data_rec.base_code               || cv_dub || cv_csv;  --���_�R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.division_code           || cv_dub || cv_csv;  --�{���R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.NULL1                   || cv_dub || cv_csv;  --�\��1
      lv_output := lv_output || cv_dub || l_data_rec.NULL2                   || cv_dub || cv_csv;  --�\��2
      lv_output := lv_output || cv_dub || l_data_rec.NULL3                   || cv_dub || cv_csv;  --�\��3
      lv_output := lv_output || cv_dub || l_data_rec.NULL4                   || cv_dub || cv_csv;  --�\��4
      lv_output := lv_output ||           l_data_rec.p_sale_norma                      || cv_csv;  --����m���}
      lv_output := lv_output ||           l_data_rec.p_sale_amount                     || cv_csv;  --������z
      lv_output := lv_output ||           l_data_rec.p_sale_achievement_rate           || cv_csv;  --����B����
      lv_output := lv_output ||           l_data_rec.p_new_contribution_sale           || cv_csv;  --�V�K�v������
      lv_output := lv_output ||           l_data_rec.p_new_norma                       || cv_csv;  --�V�K�m���}
      lv_output := lv_output ||           l_data_rec.p_new_achievement_rate            || cv_csv;  --�V�K�B����
      lv_output := lv_output ||           l_data_rec.p_new_count_sum                   || cv_csv;  --�V�K�������v
      lv_output := lv_output ||           l_data_rec.p_new_count_vd                    || cv_csv;  --�V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.p_position_point                  || cv_csv;  --���iPOINT
      lv_output := lv_output ||           l_data_rec.p_new_point                       || cv_csv;  --�V�KPOINT
      lv_output := lv_output ||           l_data_rec.g_sale_norma                      || cv_csv;  --������m���}
      lv_output := lv_output ||           l_data_rec.g_sale_amount                     || cv_csv;  --��������z
      lv_output := lv_output ||           l_data_rec.g_sale_achievement_rate           || cv_csv;  --������B����
      lv_output := lv_output ||           l_data_rec.g_new_contribution_sale           || cv_csv;  --���V�K�v������
      lv_output := lv_output ||           l_data_rec.g_new_norma                       || cv_csv;  --���V�K�m���}
      lv_output := lv_output ||           l_data_rec.g_new_achievement_rate            || cv_csv;  --���V�K�B����
      lv_output := lv_output ||           l_data_rec.g_new_count_sum                   || cv_csv;  --���V�K�������v
      lv_output := lv_output ||           l_data_rec.g_new_count_vd                    || cv_csv;  --���V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.g_position_point                  || cv_csv;  --�����iPOINT
      lv_output := lv_output ||           l_data_rec.g_new_point                       || cv_csv;  --���V�KPOINT
      lv_output := lv_output ||           l_data_rec.b_sale_norma                      || cv_csv;  --������m���}
      lv_output := lv_output ||           l_data_rec.b_sale_amount                     || cv_csv;  --��������z
      lv_output := lv_output ||           l_data_rec.b_sale_achievement_rate           || cv_csv;  --������B����
      lv_output := lv_output ||           l_data_rec.b_new_contribution_sale           || cv_csv;  --���V�K�v������
      lv_output := lv_output ||           l_data_rec.b_new_norma                       || cv_csv;  --���V�K�m���}
      lv_output := lv_output ||           l_data_rec.b_new_count_sum                   || cv_csv;  --���V�K�������v
      lv_output := lv_output ||           l_data_rec.b_new_count_vd                    || cv_csv;  --���V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.b_position_point                  || cv_csv;  --�����iPOINT
      lv_output := lv_output ||           l_data_rec.b_new_point                       || cv_csv;  --���V�KPOINT
      lv_output := lv_output ||           l_data_rec.a_sale_norma                      || cv_csv;  --�n����m���}
      lv_output := lv_output ||           l_data_rec.a_sale_amount                     || cv_csv;  --�n������z
      lv_output := lv_output ||           l_data_rec.a_sale_achievement_rate           || cv_csv;  --�n����B����
      lv_output := lv_output ||           l_data_rec.a_new_contribution_sale           || cv_csv;  --�n�V�K�v������
      lv_output := lv_output ||           l_data_rec.a_new_norma                       || cv_csv;  --�n�V�K�m���}
      lv_output := lv_output ||           l_data_rec.a_new_count_sum                   || cv_csv;  --�n�V�K�������v
      lv_output := lv_output ||           l_data_rec.a_new_count_vd                    || cv_csv;  --�n�V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.a_position_point                  || cv_csv;  --�n���iPOINT
      lv_output := lv_output ||           l_data_rec.a_new_point                       || cv_csv;  --�n�V�KPOINT
      lv_output := lv_output ||           l_data_rec.d_sale_norma                      || cv_csv;  --�{����m���}
      lv_output := lv_output ||           l_data_rec.d_sale_amount                     || cv_csv;  --�{������z
      lv_output := lv_output ||           l_data_rec.d_sale_achievement_rate           || cv_csv;  --�{����B����
      lv_output := lv_output ||           l_data_rec.d_new_contribution_sale           || cv_csv;  --�{�V�K�v������
      lv_output := lv_output ||           l_data_rec.d_new_norma                       || cv_csv;  --�{�V�K�m���}
      lv_output := lv_output ||           l_data_rec.d_new_count_sum                   || cv_csv;  --�{�V�K�������v
      lv_output := lv_output ||           l_data_rec.d_new_count_vd                    || cv_csv;  --�{�V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.d_position_point                  || cv_csv;  --�{���iPOINT
      lv_output := lv_output ||           l_data_rec.d_new_point                       || cv_csv;  --�{�V�KPOINT
      lv_output := lv_output ||           l_data_rec.s_sale_norma                      || cv_csv;  --�S����m���}
      lv_output := lv_output ||           l_data_rec.s_sale_amount                     || cv_csv;  --�S������z
      lv_output := lv_output ||           l_data_rec.s_sale_achievement_rate           || cv_csv;  --�S����B����
      lv_output := lv_output ||           l_data_rec.s_new_contribution_sale           || cv_csv;  --�S�V�K�v������
      lv_output := lv_output ||           l_data_rec.s_new_norma                       || cv_csv;  --�S�V�K�m���}
      lv_output := lv_output ||           l_data_rec.s_new_count_sum                   || cv_csv;  --�S�V�K�������v
      lv_output := lv_output ||           l_data_rec.s_new_count_vd                    || cv_csv;  --�S�V�K�����x���_�[
      lv_output := lv_output ||           l_data_rec.s_position_point                  || cv_csv;  --�S���iPOINT
      lv_output := lv_output ||           l_data_rec.s_new_point;                                  --�S�V�KPOINT
--
      UTL_FILE.PUT_LINE(lt_handle,lv_output);
--
    END LOOP for_loop;
--
    --==============================================
    -- A-5.�t�@�C���I������
    --==============================================
    UTL_FILE.FFLUSH(lt_handle);
    UTL_FILE.FCLOSE(lt_handle);
    --���������m�F
    IF ( ln_count = 0 ) THEN
      --����0���x��
      RAISE global_no_data_expt;
    ELSE
      --���탁�b�Z�[�W�p
      gn_normal_cnt := ln_count; -- ���팏��
      gn_target_cnt := ln_count; -- �Ώی���
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�O���G���[ ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �t�@�C���I�[�v����O ***
    WHEN global_make_file_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_file_open_err,
        iv_token_name1        =>  cv_tkn_file_name,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
  )
--
--
--###########################  �Œ蕔 START   #####################################################
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    errbuf := lv_errbuf;
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
END XXCOS016A01C;
/
