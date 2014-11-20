CREATE OR REPLACE PACKAGE BODY XXCOS016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A02C (body)
 * Description      : �l���V�X�e�������A�̔����уf�[�^�쐬����
 * MD.050           : �l���V�X�e�������̔����уf�[�^�̍쐬�i�����E�ܗ^�j COS_016_A03
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
 *  2008/11/17    1.0   T.kitajima       �V�K�쐬
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
  
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS016A02C';                  -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_current_appl_short_nm            fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';                    --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  cv_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00004';   --�v���t�@�C���擾�G���[
  cv_msg_file_open_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00009';   --�t�@�C���I�[�v���G���[
  cv_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00013';   --�f�[�^�擾�G���[���b�Z�[�W
  cv_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00017';   --API�ďo�G���[���b�Z�[�W
  cv_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00018';   --����0���p���b�Z�[�W
  cv_msg_file_nm            CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13401';   --�t�@�C�������b�Z�[�W
  cv_msg_mem1_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13402';   --���b�Z�[�W�p������
  cv_msg_mem2_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13403';   --���b�Z�[�W�p������
  cv_msg_mem3_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13404';   --���b�Z�[�W�p������
  --�g�[�N��
  cv_tkn_profile            CONSTANT  VARCHAR2(100) :=  'PROFILE';          --�v���t�@�C��
  cv_tkn_date_to            CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';       --�e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(100) :=  'KEY_DATA';         --�L�[�f�[�^
  cv_tkn_api_name           CONSTANT  VARCHAR2(100) :=  'API_NAME';         --�`�o�h����
  cv_tkn_file_name          CONSTANT  VARCHAR2(100) :=  'FILE_NAME';        --�t�@�C���p�X
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
  --�v���t�@�C������
  cv_Profile_dir            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_OUTBOUND_PERSONNEL_DIR';       -- I/F�o�͐�f�B���N�g��
  cv_Profile_file           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_PERSONNEL_BONUS_FILE';         -- I/F�t�@�C����
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_nothing_msg
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
--
    --==============================================
    -- 2.�l���V�X�e�������ܗ^�t�@�C����
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
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
  END get_common;
--
  /**********************************************************************************
   * Procedure Name   : <file_open>
   * Description      : �t�@�C���쐬(A-3)
   ***********************************************************************************/
  PROCEDURE file_open(
    ot_handle     OUT UTL_FILE.FILE_TYPE,   --   �t�@�C���n���h��
    ov_errbuf     OUT VARCHAR2,             --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,             --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_csv   CONSTANT VARCHAR2(1) := ','; -- �J���}
    cv_sla   CONSTANT VARCHAR2(1) := '/'; -- �X���b�V��
    cv_dub   CONSTANT VARCHAR2(1) := '"'; -- �_�u���N�H�[�g
    -- *** ���[�J���ϐ� ***
--
    lv_key_info VARCHAR2(5000);      --key���
    lv_output   VARCHAR2(5000);      -- �t�@�C���o�͗p
    lt_handle UTL_FILE.FILE_TYPE;    -- �t�@�C���n���h��
    ln_count    NUMBER;              -- ��������
    -- *** ���[�J���E�J�[�\�� ***
    --�l���ܗ^�e�[�u���f�[�^�擾�p
    CURSOR data_cur
    IS
      SELECT employee_code                    as employee_code,      --�]�ƈ��R�[�h
             results_date                     as results_date,       --�N��
             base_code                        as base_code,          --���_�R�[�h
             division_code                    as division_code,      --�{���R�[�h
             NULL                             as NULL1,              --�\��1
             NULL                             as NULL2,              --�\��2
             NULL                             as NULL3,              --�\��3
             NULL                             as NULL4,              --�\��4
             p_sale_gross                     as p_sale_gross,       --����e��
             p_current_profit                 as p_current_profit,   --�o�험�v
             NULL                             as NULL5,              --��1
             NULL                             as NULL6,              --��2
             NULL                             as NULL7,              --��3
             NULL                             as NULL8,              --��4
             p_visit_count                    as p_visit_count,      --�K�⌏��
             NULL                             as NULL9,              --��5
             NULL                             as NULL10,             --��6
             NULL                             as NULL11,             --��7
             g_sale_gross                     as g_sale_gross,       --������e��
             g_current_profit                 as g_current_profit,   --���o�험�v
             NULL                             as NULL12,             --��8
             NULL                             as NULL13,             --��9
             NULL                             as NULL14,             --��10
             NULL                             as NULL15,             --��11
             g_visit_count                    as g_visit_count,      --���K�⌏��
             NULL                             as NULL16,             --��12
             NULL                             as NULL17,             --��13
             NULL                             as NULL18,             --��14
             b_sale_gross                     as b_sale_gross,       --������e��
             b_current_profit                 as b_current_profit,   --���o�험�v
             NULL                             as NULL19,             --��15
             NULL                             as NULL20,             --��16
             NULL                             as NULL21,             --��17
             b_visit_count                    as b_visit_count,      --���K�⌏��
             NULL                             as NULL22,             --��18
             NULL                             as NULL23,             --��19
             NULL                             as NULL24,             --��20
             a_sale_gross                     as a_sale_gross,       --�n����e��
             a_current_profit                 as a_current_profit,   --�n�o�험�v
             NULL                             as NULL25,             --��21
             NULL                             as NULL26,             --��22
             NULL                             as NULL27,             --��23
             a_visit_count                    as a_visit_count,      --�n�K�⌏��
             NULL                             as NULL28,             --��24
             NULL                             as NULL29,             --��25
             NULL                             as NULL30,             --��26
             d_sale_gross                     as d_sale_gross,       --�{����e��
             d_current_profit                 as d_current_profit,   --�{�o�험�v
             NULL                             as NULL31,             --��27
             NULL                             as NULL32,             --��28
             NULL                             as NULL33,             --��29
             d_visit_count                    as d_visit_count,      --�{�K�⌏��
             NULL                             as NULL34,             --��30
             NULL                             as NULL35,             --��31
             NULL                             as NULL36,             --��32
             s_sale_gross                     as s_sale_gross,       --�S����e��
             s_current_profit                 as s_current_profit,   --�S�o�험�v
             NULL                             as NULL37,             --��33
             NULL                             as NULL38,             --��34
             NULL                             as NULL39,             --��35
             s_visit_count                    as s_visit_count,      --�S�K�⌏��
             NULL                             as NULL40,             --��36
             NULL                             as NULL41,             --��37
             NULL                             as NULL42              --��38
      FROM xxcos_for_adps_bonus_if
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
    --==============================================
    -- A-3. �t�@�C���쐬����
    --==============================================
    file_open(
      ot_handle               =>  lt_handle,                  --�t�@�C���n���h��
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
      lv_output := lv_output || cv_dub || l_data_rec.employee_code      || cv_dub || cv_csv;  --�]�ƈ��R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.results_date       || cv_dub || cv_csv;  --�N��
      lv_output := lv_output || cv_dub || l_data_rec.base_code          || cv_dub || cv_csv;  --���_�R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.division_code      || cv_dub || cv_csv;  --�{���R�[�h
      lv_output := lv_output || cv_dub || l_data_rec.NULL1              || cv_dub || cv_csv;  --�\��1
      lv_output := lv_output || cv_dub || l_data_rec.NULL2              || cv_dub || cv_csv;  --�\��2
      lv_output := lv_output || cv_dub || l_data_rec.NULL3              || cv_dub || cv_csv;  --�\��3
      lv_output := lv_output || cv_dub || l_data_rec.NULL4              || cv_dub || cv_csv;  --�\��4
      lv_output := lv_output ||           l_data_rec.p_sale_gross                 || cv_csv;  --����e��
      lv_output := lv_output ||           l_data_rec.p_current_profit             || cv_csv;  --�o�험�v
      lv_output := lv_output ||           l_data_rec.NULL5                        || cv_csv;  --��1
      lv_output := lv_output ||           l_data_rec.NULL6                        || cv_csv;  --��2
      lv_output := lv_output ||           l_data_rec.NULL7                        || cv_csv;  --��3
      lv_output := lv_output ||           l_data_rec.NULL8                        || cv_csv;  --��4
      lv_output := lv_output ||           l_data_rec.p_visit_count                || cv_csv;  --�K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL9                        || cv_csv;  --��5
      lv_output := lv_output ||           l_data_rec.NULL10                       || cv_csv;  --��6
      lv_output := lv_output ||           l_data_rec.NULL11                       || cv_csv;  --��7
      lv_output := lv_output ||           l_data_rec.g_sale_gross                 || cv_csv;  --������e��
      lv_output := lv_output ||           l_data_rec.g_current_profit             || cv_csv;  --���o�험�v
      lv_output := lv_output ||           l_data_rec.NULL12                       || cv_csv;  --��8
      lv_output := lv_output ||           l_data_rec.NULL13                       || cv_csv;  --��9
      lv_output := lv_output ||           l_data_rec.NULL14                       || cv_csv;  --��10
      lv_output := lv_output ||           l_data_rec.NULL15                       || cv_csv;  --��11
      lv_output := lv_output ||           l_data_rec.g_visit_count                || cv_csv;  --���K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL16                       || cv_csv;  --��12
      lv_output := lv_output ||           l_data_rec.NULL17                       || cv_csv;  --��13
      lv_output := lv_output ||           l_data_rec.NULL18                       || cv_csv;  --��14
      lv_output := lv_output ||           l_data_rec.b_sale_gross                 || cv_csv;  --������e��
      lv_output := lv_output ||           l_data_rec.b_current_profit             || cv_csv;  --���o�험�v
      lv_output := lv_output ||           l_data_rec.NULL19                       || cv_csv;  --��15
      lv_output := lv_output ||           l_data_rec.NULL20                       || cv_csv;  --��16
      lv_output := lv_output ||           l_data_rec.NULL21                       || cv_csv;  --��17
      lv_output := lv_output ||           l_data_rec.b_visit_count                || cv_csv;  --���K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL22                       || cv_csv;  --��18
      lv_output := lv_output ||           l_data_rec.NULL23                       || cv_csv;  --��19
      lv_output := lv_output ||           l_data_rec.NULL24                       || cv_csv;  --��20
      lv_output := lv_output ||           l_data_rec.a_sale_gross                 || cv_csv;  --�n����e��
      lv_output := lv_output ||           l_data_rec.a_current_profit             || cv_csv;  --�n�o�험�v
      lv_output := lv_output ||           l_data_rec.NULL25                       || cv_csv;  --��21
      lv_output := lv_output ||           l_data_rec.NULL26                       || cv_csv;  --��22
      lv_output := lv_output ||           l_data_rec.NULL27                       || cv_csv;  --��23
      lv_output := lv_output ||           l_data_rec.a_visit_count                || cv_csv;  --�n�K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL28                       || cv_csv;  --��24
      lv_output := lv_output ||           l_data_rec.NULL29                       || cv_csv;  --��25
      lv_output := lv_output ||           l_data_rec.NULL30                       || cv_csv;  --��26
      lv_output := lv_output ||           l_data_rec.d_sale_gross                 || cv_csv;  --�{����e��
      lv_output := lv_output ||           l_data_rec.d_current_profit             || cv_csv;  --�{�o�험�v
      lv_output := lv_output ||           l_data_rec.NULL31                       || cv_csv;  --��27
      lv_output := lv_output ||           l_data_rec.NULL32                       || cv_csv;  --��28
      lv_output := lv_output ||           l_data_rec.NULL33                       || cv_csv;  --��29
      lv_output := lv_output ||           l_data_rec.d_visit_count                || cv_csv;  --�{�K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL34                       || cv_csv;  --��30
      lv_output := lv_output ||           l_data_rec.NULL35                       || cv_csv;  --��31
      lv_output := lv_output ||           l_data_rec.NULL36                       || cv_csv;  --��32
      lv_output := lv_output ||           l_data_rec.s_sale_gross                 || cv_csv;  --�S����e��
      lv_output := lv_output ||           l_data_rec.s_current_profit             || cv_csv;  --�S�o�험�v
      lv_output := lv_output ||           l_data_rec.NULL37                       || cv_csv;  --��33
      lv_output := lv_output ||           l_data_rec.NULL38                       || cv_csv;  --��34
      lv_output := lv_output ||           l_data_rec.NULL39                       || cv_csv;  --��35
      lv_output := lv_output ||           l_data_rec.s_visit_count                || cv_csv;  --�S�K�⌏��
      lv_output := lv_output ||           l_data_rec.NULL40                       || cv_csv;  --��36
      lv_output := lv_output ||           l_data_rec.NULL41                       || cv_csv;  --��37
      lv_output := lv_output ||           l_data_rec.NULL42;                                  --��38
--
      UTL_FILE.PUT_LINE(lt_handle,lv_output);
--
    END LOOP for_loop;
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
      gn_normal_cnt := ln_count;
      gn_target_cnt := ln_count;
    END IF;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
--
    -- *** �Ώۃf�[�^�O���G���[ ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
--
--###########################  �Œ蕔 END   #######################################################
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
END XXCOS016A02C;
/
