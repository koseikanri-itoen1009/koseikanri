CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A06C (body)
 * Description      : �󒍃C���|�[�g�G���[���m
 * MD.050           : MD050_COS_010_A06_�󒍃C���|�[�g�G���[���m
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              ��������(A-1)
 *  reg_order_proc         �󒍃C���|�[�g(A-2)
 *  err_chk_proc           �G���[�`�F�b�N(A-3)
 *    err_msg_out_proc       �G���[���b�Z�[�W�o��(A-4)
 *  end_proc               �I������(A-5)
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/06    1.0   K.Satomura       �V�K�쐬
 *  2009/11/10    1.1   M.Sano           [E_T4_00173]�s�v�Ȍ����e�[�u���̍폜�E�q���g��ǉ�
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
  global_get_profile_expt EXCEPTION; --�v���t�@�C���擾��O�n���h��
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(128)                               := 'XXCOS010A06C'; -- �p�b�P�[�W��
  ct_xxcos_appl_short_name CONSTANT fnd_application.application_short_name%TYPE := 'XXCOS';        -- �A�v���P�[�V�����Z�k��(�̕�)
  ct_xxccp_appl_short_name CONSTANT fnd_application.application_short_name%TYPE := 'XXCCP';        -- �A�v���P�[�V�����Z�k��(����)
  cv_flag_yes              CONSTANT VARCHAR2(1)                                 := 'Y';            -- �t���O=Y
  cv_flag_no               CONSTANT VARCHAR2(1)                                 := 'N';            -- �t���O=N
  cn_number_zero           CONSTANT NUMBER                                      := 0;              -- ���l=0
  cn_number_one            CONSTANT NUMBER                                      := 1;              -- ���l=1
  --
  -- ���b�Z�[�W
  ct_msg_get_profile_err CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  ct_msg_get_data_err    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  ct_msg_param_output    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13801'; -- �p�����[�^�o�̓��b�Z�[�W
  ct_msg_err_chk_failed  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13802'; -- �G���[�`�F�b�N���s���b�Z�[�W
  ct_msg_err_info        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13803'; -- �G���[���
  ct_msg_err_cnt         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13804'; -- �G���[����
  ct_msg_order_inp_err   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13805'; -- �󒍃C���|�[�g�G���[���b�Z�[�W
  ct_msg_char1           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13806'; -- ���b�Z�[�W�p������
  ct_msg_char2           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13807'; -- ���b�Z�[�W�p������
  ct_msg_char3           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13808'; -- ���b�Z�[�W�p������
  ct_msg_char4           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13809'; -- ���b�Z�[�W�p������
  ct_msg_char5           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13810'; -- ���b�Z�[�W�p������
  ct_msg_char6           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13811'; -- ���b�Z�[�W�p������
  ct_msg_char7           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13812'; -- ���b�Z�[�W�p������
  ct_msg_char8           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13813'; -- ���b�Z�[�W�p������
  ct_msg_char9           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13814'; -- ���b�Z�[�W�p������
  ct_msg_char10          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13815'; -- ���b�Z�[�W�p������
  ct_msg_publish_request CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13816'; -- �v�����s���b�Z�[�W
  ct_msg_time_over       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13817'; -- �ҋ@���Ԍo�߃��b�Z�[�W
  ct_msg_imp_war_err     CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13818'; -- �󒍃C���|�[�g�x���E�G���[���b�Z�[�W
  --
  -- �g�[�N��
  cv_tkn_param      CONSTANT VARCHAR2(512) := 'PARAM';      -- �p�����[�^
  cv_tkn_profile    CONSTANT VARCHAR2(512) := 'PROFILE';    -- �v���t�@�C����
  cv_tkn_table_name CONSTANT VARCHAR2(512) := 'TABLE_NAME'; -- �e�[�u����
  cv_tkn_key_data   CONSTANT VARCHAR2(512) := 'KEY_DATA';   -- �f�[�^�L�[
  cv_tkn_count1     CONSTANT VARCHAR2(512) := 'COUNT1';     -- �J�E���g1
  cv_tkn_count2     CONSTANT VARCHAR2(512) := 'COUNT2';     -- �J�E���g2
  cv_tkn_request_id CONSTANT VARCHAR2(512) := 'REQUEST_ID'; -- �v���h�c
  cv_tkn_colmun1    CONSTANT VARCHAR2(512) := 'COLMUN1';    -- �J����1
  cv_tkn_colmun2    CONSTANT VARCHAR2(512) := 'COLMUN2';    -- �J����2
  cv_tkn_code       CONSTANT VARCHAR2(512) := 'CODE';       -- �R�[�h
  cv_tkn_name       CONSTANT VARCHAR2(512) := 'NAME';       -- ����
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_wait_interval    NUMBER;                                -- �ҋ@�Ԋu
  gn_max_wait_time    NUMBER;                                -- �ő�ҋ@����
  gt_order_source_id  oe_order_sources.order_source_id%TYPE; -- �󒍃\�[�X�h�c
  gn_request_id       NUMBER;                                -- �v���h�c
  gn_header_error_cnt NUMBER;                                -- �󒍃w�b�_OIF�G���[����
  gn_line_error_cnt   NUMBER;                                -- �󒍖���OIF�G���[����
  gv_imp_warm_flg     VARCHAR2(1);                           -- �󒍃C���|�[�g�����̌��ʁi�x�����F'Y'�j
  --
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     iv_order_source_name IN         VARCHAR2 -- �󒍃\�[�X����
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_wait_interval CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL_OEOIMP'; -- �ҋ@�Ԋu�v���t�@�C��
    cv_max_wait_time CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT_OEOIMP'; -- �ő�ҋ@�Ԋu�v���t�@�C��
    --
    -- *** ���[�J���ϐ� ***
    lv_key_info VARCHAR2(5000); -- �L�[���
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
    ------------------------------------
    -- �p�����[�^�o��
    ------------------------------------
    -- �󒍃\�[�X
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => ct_msg_param_output      -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param             -- �g�[�N���R�[�h1
                   ,iv_token_value1 => iv_order_source_name     -- �g�[�N���l1
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => NULL
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    ------------------------------------
    -- �v���t�@�C���l�擾
    ------------------------------------
    -- �ҋ@�Ԋu
    gn_wait_interval := TO_NUMBER(fnd_profile.value(cv_wait_interval));
    --
    IF (gn_wait_interval IS NULL) THEN
      -- �v���t�@�C���l��NULL�̏ꍇ�̓G���[
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W
        ,ov_retcode     => lv_retcode     -- ���^�[���R�[�h
        ,ov_errmsg      => lv_errmsg      -- ���[�U�E�G���[�E���b�Z�[�W
        ,ov_key_info    => lv_key_info    -- �ҏW���ꂽ�L�[���
        ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char1
                           )
        ,iv_data_value1 => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char2
                           )
      );
      --
      RAISE global_get_profile_expt;
      --
    END IF;
    --
    -- �ő�ҋ@�Ԋu
    gn_max_wait_time := TO_NUMBER(fnd_profile.value(cv_max_wait_time));
    --
    IF (gn_max_wait_time IS NULL) THEN
      -- �v���t�@�C���l��NULL�̏ꍇ�̓G���[
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W
        ,ov_retcode     => lv_retcode     -- ���^�[���R�[�h
        ,ov_errmsg      => lv_errmsg      -- ���[�U�E�G���[�E���b�Z�[�W
        ,ov_key_info    => lv_key_info    -- �ҏW���ꂽ�L�[���
        ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char1
                           )
        ,iv_data_value1 => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char3
                           )
      );
      --
      RAISE global_get_profile_expt;
      --
    END IF;
    --
    ------------------------------------
    -- �󒍃\�[�X���̕ϊ�
    ------------------------------------
    BEGIN
      SELECT oos.order_source_id -- �󒍃\�[�X�h�c
      INTO   gt_order_source_id
      FROM   oe_order_sources oos -- �󒍃\�[�X
      WHERE  oos.name         = iv_order_source_name
      AND    oos.enabled_flag = cv_flag_yes
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(
           ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W
          ,ov_retcode     => lv_retcode     -- ���^�[���R�[�h
          ,ov_errmsg      => lv_errmsg      -- ���[�U�E�G���[�E���b�Z�[�W
          ,ov_key_info    => lv_key_info    -- �ҏW���ꂽ�L�[���
          ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char4
                           )
          ,iv_data_value1 => iv_order_source_name
        );
        --
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_data_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char5
                                           )
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => lv_key_info
                     );
        --
        RAISE global_api_others_expt;
        --
    END;
    --
  EXCEPTION
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_get_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || ov_errmsg, 1, 5000);
      ov_retcode := cv_status_error;
      --
--#####################################  �Œ蕔 START ##########################################
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
   * Procedure Name   : <reg_order_proc>
   * Description      : <�󒍃C���|�[�g>(A-2)
   ***********************************************************************************/
  PROCEDURE reg_order_proc (
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reg_order_proc'; -- �v���O������
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
    cv_application        CONSTANT VARCHAR2(5)  := 'ONT';     -- Application
    cv_program            CONSTANT VARCHAR2(9)  := 'OEOIMP';  -- Program
    cb_sub_request        CONSTANT BOOLEAN      := FALSE;     -- Sub_request
    cv_debug_level        CONSTANT VARCHAR2(1)  := '1';       -- �f�o�b�O�E���x��
    cv_ord_inp_inst_cnt   CONSTANT VARCHAR2(1)  := '4';       -- �󒍃C���|�[�g�E�C���X�^���X��
    cv_con_status_normal  CONSTANT VARCHAR2(10) := 'NORMAL';  -- �X�e�[�^�X�i����j
    cv_con_status_warning CONSTANT VARCHAR2(10) := 'WARNING'; -- �X�e�[�^�X�i�x���j
    --
    -- *** ���[�J���ϐ� ***
    lb_wait_result BOOLEAN;
    lv_phase       VARCHAR2(50);
    lv_status      VARCHAR2(50);
    lv_dev_phase   VARCHAR2(50);
    lv_dev_status  VARCHAR2(50);
    lv_message     VARCHAR2(5000);
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
    -- �󒍃C���|�[�g�R���J�����g�N��
    gn_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => cb_sub_request
                       ,argument1   => gt_order_source_id  -- �󒍃\�[�X�h�c
                       ,argument2   => NULL                -- �����V�X�e�������Q��
                       ,argument3   => NULL                -- �H���R�[�h
                       ,argument4   => cv_flag_no          -- ���؂̂݁H
                       ,argument5   => cv_debug_level      -- �f�o�b�O���x��
                       ,argument6   => cv_ord_inp_inst_cnt -- �󒍃C���|�[�g�C���X�^���X��
                       ,argument7   => NULL                -- �̔���g�D�h�c
                       ,argument8   => NULL                -- �̔���g�D
                       ,argument9   => NULL                -- �ύX����
                       ,argument10  => cv_flag_yes         -- �C���X�^���X�̒P�ꖾ�׃L���[�g�p��
                       ,argument11  => cv_flag_no          -- �㑱�ɑ����u�����N�̃g����
                       ,argument12  => cv_flag_yes         -- �t���t���b�N�X�̃t�B�[���h
                     );
    --
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name
                   ,iv_name         => ct_msg_publish_request
                   ,iv_token_name1  => cv_tkn_request_id
                   ,iv_token_value1 => TO_CHAR(gn_request_id)
                 );
    --
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => lv_errmsg
    );
    --
    IF (gn_request_id = cn_number_zero) THEN
      -- �������v�������s�ł��Ȃ������ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => ct_xxcos_appl_short_name
                     ,iv_name        => ct_msg_order_inp_err
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- �R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    --
    -- �R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
                         request_id => gn_request_id
                        ,interval   => gn_wait_interval
                        ,max_wait   => gn_max_wait_time
                        ,phase      => lv_phase
                        ,status     => lv_status
                        ,dev_phase  => lv_dev_phase
                        ,dev_status => lv_dev_status
                        ,message    => lv_message
                      );
    --
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_time_over
                     ,iv_token_name1  => cv_tkn_request_id
                     ,iv_token_value1 => TO_CHAR(gn_request_id)
                   );
      --
      RAISE global_api_expt;
      --
    ELSIF (lv_dev_status <> cv_con_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_imp_war_err
                     ,iv_token_name1  => cv_tkn_request_id
                     ,iv_token_value1 => TO_CHAR(gn_request_id)
                   );
      --
      IF (lv_dev_status = cv_con_status_warning ) THEN
        gv_imp_warm_flg := cv_flag_yes;
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => NULL
        );
      ELSE
        RAISE global_api_expt;
        --
      END IF;
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
  END reg_order_proc;
--
  /**********************************************************************************
   * Procedure Name   : <err_msg_out_proc>
   * Description      : <�G���[���b�Z�[�W�o��>(A-4)
   ***********************************************************************************/
  PROCEDURE err_msg_out_proc(
     iv_order_source_name IN         VARCHAR2                                -- �󒍃\�[�X����
    ,it_account_number    IN         hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
    ,it_account_name      IN         hz_cust_accounts.account_name%TYPE      -- �ڋq����
    ,it_request_id        IN         fnd_concurrent_requests.request_id%TYPE -- �v���h�c
    ,ov_errbuf            OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_msg_out_proc'; -- �v���O������
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
    cv_order_source_name_edi CONSTANT VARCHAR2(100) := 'EDI��';
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_data VARCHAR2(5000);
    --
    -- *** ���[�J���E�J�[�\�� ***
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
    IF (iv_order_source_name = cv_order_source_name_edi) THEN
      -- �G���[���(EDI)
      lv_msg_data := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => ct_msg_err_info          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_request_id        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => it_request_id            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_colmun1           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char7
                                           )                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_account_number        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_colmun2           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char8
                                           )                        -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_name              -- �g�[�N���R�[�h5
                       ,iv_token_value5 => it_account_name          -- �g�[�N���l5
                     );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_msg_data
      );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => NULL
      );
      --
    ELSE
      -- �G���[���(�ڋq)
      lv_msg_data := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => ct_msg_err_info          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_request_id        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => it_request_id            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_colmun1           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char9
                                           )                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_account_number        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_colmun2           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char10
                                           )                        -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_name              -- �g�[�N���R�[�h5
                       ,iv_token_value5 => it_account_name          -- �g�[�N���l5
                     );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_msg_data
      );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => NULL
      );
      --
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
  END err_msg_out_proc;
--
  /**********************************************************************************
   * Procedure Name   : <err_chk_proc>
   * Description      : <�G���[�`�F�b�N>(A-3)
   ***********************************************************************************/
  PROCEDURE err_chk_proc(
     iv_order_source_name IN         VARCHAR2 -- �󒍃\�[�X����
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_proc'; -- �v���O������
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
    cv_order_source_name_edi CONSTANT VARCHAR2(100)                             := 'EDI��';
    cv_cust_code_cust        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10'; -- �ڋq�敪=�ڋq
    cv_cust_code_chain       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '18'; -- �ڋq�敪=�`�F�[���X
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_data VARCHAR2(3000);
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- EDI�p�J�[�\��
    CURSOR get_edi_err_info_cur
    IS
      SELECT xca2.edi_chain_code account_number -- �`�F�[���X�R�[�h(EDI)
            ,hca2.account_name   account_name   -- �`�F�[���X����
            ,fcr.request_id      request_id     -- �v���h�c
      FROM   fnd_concurrent_requests fcr  -- �R���J�����g�v���\
            ,oe_headers_iface_all    ohi  -- �󒍃w�b�_OIF
            ,oe_lines_iface_all      oli  -- �󒍖���OIF
            ,hz_cust_accounts        hca  -- �ڋq�}�X�^
            ,xxcmm_cust_accounts     xca  -- �ڋq�A�h�I���}�X�^
            ,hz_cust_accounts        hca2 -- �ڋq�}�X�^(EDI)
            ,xxcmm_cust_accounts     xca2 -- �ڋq�A�h�I���}�X�^(EDI)
      WHERE  fcr.parent_request_id     = gn_request_id
      AND    fcr.request_id            = ohi.request_id
      AND    fcr.request_id            = oli.request_id
      AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
      AND    (
                  ohi.error_flag = cv_flag_yes
               OR oli.error_flag = cv_flag_yes
             )
      AND    hca.account_number       = ohi.customer_number
      AND    hca.customer_class_code  = cv_cust_code_cust
      AND    hca.cust_account_id      = xca.customer_id
      AND    hca2.customer_class_code = cv_cust_code_chain
      AND    hca2.cust_account_id     = xca2.customer_id
      AND    xca.chain_store_code     = xca2.edi_chain_code
      GROUP BY xca2.edi_chain_code
              ,hca2.account_name
              ,fcr.request_id
      ORDER BY fcr.request_id ASC
      ;
      --
    -- CSV�p�J�[�\��
    CURSOR get_csv_err_info_cur
    IS
      SELECT 
/* 2009/11/10 Ver.1.1 Add Start */
             /*+ use_nl(fcr ohi oli) */
/* 2009/11/10 Ver.1.1 Add Start */
             hca.account_number account_number -- �ڋq�R�[�h
            ,hca.account_name   account_name   -- �ڋq����
            ,fcr.request_id     request_id     -- �v���h�c
      FROM   fnd_concurrent_requests fcr  -- �R���J�����g�v���\
            ,oe_headers_iface_all    ohi  -- �󒍃w�b�_OIF
            ,oe_lines_iface_all      oli  -- �󒍖���OIF
            ,hz_cust_accounts        hca  -- �ڋq�}�X�^
            ,xxcmm_cust_accounts     xca  -- �ڋq�A�h�I���}�X�^
/* 2009/11/10 Ver.1.1 Del Start */
--            ,hz_cust_accounts        hca2 -- �ڋq�}�X�^(EDI)
--            ,xxcmm_cust_accounts     xca2 -- �ڋq�A�h�I���}�X�^(EDI)
/* 2009/11/10 Ver.1.1 Del End   */
      WHERE  fcr.parent_request_id     = gn_request_id
      AND    fcr.request_id            = ohi.request_id
      AND    fcr.request_id            = oli.request_id
      AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
      AND    (
                  ohi.error_flag = cv_flag_yes
               OR oli.error_flag = cv_flag_yes
             )
      AND    hca.account_number       = ohi.customer_number
      AND    hca.customer_class_code  = cv_cust_code_cust
      AND    hca.cust_account_id      = xca.customer_id
      GROUP BY hca.account_number
              ,hca.account_name
              ,fcr.request_id
      ORDER BY fcr.request_id ASC
      ;
    --
    -- *** ���[�J���E���R�[�h ***
    lt_err_info_rec get_csv_err_info_cur%ROWTYPE;
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
    -- �w�b�_�G���[�����擾
    SELECT COUNT(1)
    INTO   gn_header_error_cnt
    FROM   fnd_concurrent_requests fcr -- �R���J�����g�v���\
          ,oe_headers_iface_all    ohi -- �󒍃w�b�_OIF
    WHERE  fcr.parent_request_id = gn_request_id
    AND    fcr.request_id        = ohi.request_id
    AND    ohi.error_flag        = cv_flag_yes
    ;
    --
    -- ���׃G���[�����擾
    SELECT COUNT(1)
    INTO   gn_line_error_cnt
    FROM   fnd_concurrent_requests fcr -- �R���J�����g�v���\
          ,oe_headers_iface_all    ohi -- �󒍃w�b�_OIF
          ,oe_lines_iface_all      oli -- �󒍖���OIF
    WHERE  fcr.parent_request_id     = gn_request_id
    AND    fcr.request_id            = ohi.request_id
    AND    fcr.request_id            = oli.request_id
    AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
    AND    oli.error_flag            = cv_flag_yes
    ;
    --
    IF (gn_header_error_cnt > cn_number_zero
      OR gn_line_error_cnt > cn_number_zero)
    THEN
      -- �G���[�f�[�^�擾
      IF (iv_order_source_name = cv_order_source_name_edi) THEN
        OPEN get_edi_err_info_cur;
        --
      ELSE
        OPEN get_csv_err_info_cur;
        --
      END IF;
      --
      <<get_err_info_loop>>
      LOOP
        BEGIN
          IF (iv_order_source_name = cv_order_source_name_edi) THEN
            FETCH get_edi_err_info_cur INTO lt_err_info_rec;
            --
          ELSE
            FETCH get_csv_err_info_cur INTO lt_err_info_rec;
            --
          END IF;
          --
        EXCEPTION
          WHEN OTHERS THEN
            -- �擾�Ɏ��s�����ꍇ
            IF (get_edi_err_info_cur%ISOPEN) THEN
              CLOSE get_edi_err_info_cur;
              --
            END IF;
            --
            IF (get_csv_err_info_cur%ISOPEN) THEN
              CLOSE get_csv_err_info_cur;
              --
            END IF;
            --
            lv_msg_data := xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name -- �A�v���P�[�V�����Z�k��
                             ,iv_name        => ct_msg_err_chk_failed    -- ���b�Z�[�W�R�[�h
                           );
            --
            RAISE global_api_expt;
            --
        END;
        --
        IF (iv_order_source_name = cv_order_source_name_edi) THEN
          EXIT WHEN get_edi_err_info_cur%NOTFOUND
            OR get_edi_err_info_cur%ROWCOUNT = 0;
          --
        ELSE
          EXIT WHEN get_csv_err_info_cur%NOTFOUND
            OR get_csv_err_info_cur%ROWCOUNT = 0;
          --
        END IF;
        --
        -- �G���[���b�Z�[�W�o��
        err_msg_out_proc(
           iv_order_source_name => iv_order_source_name
          ,it_account_number    => lt_err_info_rec.account_number
          ,it_account_name      => lt_err_info_rec.account_name
          ,it_request_id        => lt_err_info_rec.request_id
          ,ov_errbuf            => lv_errbuf
          ,ov_retcode           => lv_retcode
          ,ov_errmsg            => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
          --
        END IF;
        --
      END LOOP get_err_info_loop;
      --
      IF (iv_order_source_name = cv_order_source_name_edi) THEN
        CLOSE get_edi_err_info_cur;
        --
      ELSE
        CLOSE get_csv_err_info_cur;
        --
      END IF;
      --
    END IF;
    --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- �J�[�\�����I�[�v�����Ă���ꍇ�A�N���[�Y
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- �J�[�\�����I�[�v�����Ă���ꍇ�A�N���[�Y
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- �J�[�\�����I�[�v�����Ă���ꍇ�A�N���[�Y
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_chk_proc;
--
  /**********************************************************************************
   * Procedure Name   : <end_proc>
   * Description      : <�I������>(A-5)
   ***********************************************************************************/
  PROCEDURE end_proc(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_msg_data VARCHAR2(3000);
    --
    -- *** ���[�J���E�J�[�\�� ***
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
    lv_msg_data := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => ct_msg_err_cnt           -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_count1            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => gn_header_error_cnt      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_count2            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => gn_line_error_cnt        -- �g�[�N���l2
                   );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_msg_data
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
  END end_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_order_source_name IN         VARCHAR2 -- �󒍃\�[�X����
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_wait_interval    := 0;
    gn_max_wait_time    := 0;
    gt_order_source_id  := 0;
    gn_request_id       := 0;
    gn_header_error_cnt := 0;
    gn_line_error_cnt   := 0;
    gv_imp_warm_flg     := NULL;
    --
    -- --------------------------------------------------------------------
    -- * init_proc         ��������                                   (A-1)
    -- --------------------------------------------------------------------
    init_proc(
       iv_order_source_name => iv_order_source_name -- �󒍃\�[�X����
      ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * reg_order_proc   �󒍃C���|�[�g                              (A-2)
    -- --------------------------------------------------------------------
    reg_order_proc (
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * err_chk_proc       �G���[�`�F�b�N                            (A-3)
    -- --------------------------------------------------------------------
    err_chk_proc(
       iv_order_source_name => iv_order_source_name -- �󒍃\�[�X����
      ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * end_proc         �I������                                    (A-5)
    -- --------------------------------------------------------------------
    end_proc(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    IF ( gn_header_error_cnt > cn_number_zero
      OR gn_line_error_cnt > cn_number_zero
      OR gv_imp_warm_flg = cv_flag_yes )
    THEN
      -- �G���[���P���ł��������ꍇ�͌x���I��
      ov_retcode := cv_status_warn;
      --
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
     errbuf            OUT VARCHAR2 -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode           OUT VARCHAR2 -- ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    ,iv_order_source_name IN VARCHAR2 -- �󒍃\�[�X����
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       iv_order_source_name -- �󒍃\�[�X����
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
--    --�G���[�o��
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --�G���[���b�Z�[�W
--      );
--    END IF;
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
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
/*  �s�K�v
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
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_Suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_Suc_cnt)
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
*/
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
END XXCOS010A06C;
/
