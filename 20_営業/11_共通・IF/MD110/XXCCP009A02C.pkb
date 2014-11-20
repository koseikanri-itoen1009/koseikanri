CREATE OR REPLACE PACKAGE BODY XXCCP009A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP009A02C(body)
 * Description      : �Ό��V�X�e���W���u�󋵃e�[�u��(�A�h�I��)�̍X�V���s���܂��B
 * MD.050           : MD050_CCP_009_A02_�Ό��V�X�e���W���u�󋵍X�V����
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  update_status          �X�e�[�^�X�X�V����(A-2)
 *  submain                ���C�������v���V�[�W��(A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-3)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Koji.Oomata      main�V�K�쐬
 *  2009-04-01    1.1   Masayuki.Sano    [��Q�ԍ��FT1-0521]
 *                                       �E�X�V�����̌��������̕ύX(�񖼕ύX)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  --WHO�J����
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  init_err_expt             EXCEPTION;     -- ���������G���[
  fopen_err_expt            EXCEPTION;     -- �t�@�C���I�[�v���G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCCP009A02C';      -- �p�b�P�[�W��
--
  cv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCCP';             -- ���b�Z�[�W�敪
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_pk_request_id_val IN  VARCHAR2     -- �������t�v��ID
    ,iv_status_code       IN  VARCHAR2     -- �X�e�[�^�X�R�[�h
    ,ov_errbuf            OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_required_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10004';  --�K�{���ږ��ݒ�G���[
    cv_required_token     CONSTANT VARCHAR2(10)  := 'ITEM';              --�K�{���ږ��ݒ�G���[�p�g�[�N��
    cv_required_token_v1  CONSTANT VARCHAR2(10)  := 'REQUEST_ID';        --�K�{���ږ��ݒ�G���[�p�g�[�N���l1
    cv_required_token_v2  CONSTANT VARCHAR2(10)  := 'STATUS';            --�K�{���ږ��ݒ�G���[�p�g�[�N���l2
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
-- 
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�p�����[�^�K�{�`�F�b�N
    --�������t�v��ID
    IF (iv_pk_request_id_val IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name
                     ,cv_required_msg
                     ,cv_required_token
                     ,cv_required_token_v1
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --
    --�X�e�[�^�X�R�[�h
    IF (iv_status_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name
                     ,cv_required_msg
                     ,cv_required_token
                     ,cv_required_token_v2
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --
--
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : update_status
   * Description      : �X�e�[�^�X�X�V����(A-2)
   ***********************************************************************************/
  PROCEDURE update_status(
     iv_pk_request_id_val IN  VARCHAR2     -- �������t�v��ID
    ,iv_status_code       IN  VARCHAR2     -- �X�e�[�^�X�R�[�h
    ,ov_errbuf            OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_status'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�Ώی���+1
    gn_target_cnt := gn_target_cnt + 1;
    --
    --�X�e�[�^�X�X�V����
    UPDATE xxccp_if_job_status xijs
    SET    xijs.status_code            = iv_status_code             --�X�e�[�^�X
          ,xijs.last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
          ,xijs.last_update_date       = cd_last_update_date        --�ŏI�X�V��
          ,xijs.last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��ID
          ,xijs.request_id             = cn_request_id              --�v��ID
          ,xijs.program_application_id = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xijs.program_id             = cn_program_id              --�R���J�����g�E�v���O����ID
          ,xijs.program_update_date    = cd_program_update_date     --�v���O�����X�V��
--    WHERE  xijs.pk_request_id_val = iv_pk_request_id_val  --�������t�v��ID
    WHERE  xijs.request_id_val = iv_pk_request_id_val  --�������t�v��ID
    ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_pk_request_id_val IN  VARCHAR2     -- �������t�v��ID
    ,iv_status_code       IN  VARCHAR2     -- �X�e�[�^�X�R�[�h
    ,ov_errbuf            OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <��������>
    -- ===============================
    init(
       iv_pk_request_id_val  -- �������t�v��ID
      ,iv_status_code        -- �X�e�[�^�X�R�[�h
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�X�e�[�^�X�X�V����>
    -- ===============================
    update_status(
       iv_pk_request_id_val  -- �������t�v��ID
      ,iv_status_code        -- �X�e�[�^�X�R�[�h
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����+1
      gn_error_cnt := gn_error_cnt + 1;
      --(�G���[����)
      RAISE global_process_expt;
    ELSE
      --��������+1
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
--
  EXCEPTION
--
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
    errbuf                  OUT    VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT    VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_pk_request_id_val    IN     VARCHAR2,         -- �������t�v��ID
    iv_status_code          IN     VARCHAR2          -- �X�e�[�^�X�R�[�h
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_request_id_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00021'; -- �v��ID���b�Z�[�W
    cv_request_id_token CONSTANT VARCHAR2(10)  := 'REQ_ID';           -- �v��ID���b�Z�[�W�p�g�[�N��
    cv_status_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00022'; -- �X�e�[�^�X���b�Z�[�W
    cv_status_token     CONSTANT VARCHAR2(10)  := 'STATUS';           -- �X�e�[�^�X���b�Z�[�W�p�g�[�N��
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
       iv_pk_request_id_val  -- �������t�v��ID
      ,iv_status_code        -- �X�e�[�^�X�R�[�h
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̓p�����[�^�o��
    --�v��ID
    --���|�[�g�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_request_id_msg
                   ,cv_request_id_token
                   ,iv_pk_request_id_val
                 )
    );
    --���O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_request_id_msg
                   ,cv_request_id_token
                   ,iv_pk_request_id_val
                 )
    );
    --�X�e�[�^�X
    --���|�[�g�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_status_msg
                   ,cv_status_token
                   ,iv_status_code
                 )
    );
    --���O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_status_msg
                   ,cv_status_token
                   ,iv_status_code
                 )
    );
    --��s�}��
    --���|�[�g�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
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
    --��s�}��
    --���|�[�g�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP009A02C;
/
