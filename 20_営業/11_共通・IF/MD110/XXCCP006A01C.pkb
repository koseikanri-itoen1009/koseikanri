CREATE OR REPLACE PACKAGE BODY APPS.XXCCP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A01C(body)
 * Description      : �e�q�R���J�����g�I���X�e�[�^�X�Ď�
 * MD.050           : MD050_CCP_006_A01_�e�q�R���J�����g�I���X�e�[�^�X�Ď�
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_conc_status        �R���J�����g�X�e�[�^�X�`�F�b�N����(���ʏ���)
 *  init                   ��������(A-1)
 *  get_parent_conc_info   �e�R���J�����g���擾����(A-2)
 *  exe_parent_conc        �e�R���J�����g�N������(A-3)
 *  wait_for_child_conc    �q�R���J�����g�I���҂�����(A-4)
 *  end_conc               �I������(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/15    1.0   Yohei Takayama   �V�K�쐬
 *  2009/03/11    1.1   Masayuki Sano    ���b�Z�[�W�\���s���Ή�
 *  2009/04/20    1.2   Masayuki Sano    ��Q�Ή�T1_0443
 *                                       �E2�K�w�ځ�3�K�w�ڂ܂ŎQ�Ɖ\�ƂȂ�悤�ɏC���B
 *  2009/05/01    1.3   Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
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
  --<exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP006A01C'; -- �p�b�P�[�W��
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';            -- �t���O���f�p'Y'
  cn_param_max_cnt CONSTANT NUMBER        := 97;             -- �e�R���J�����g�p�����[�^�̍ő吔
  cv_conc_p_flg    CONSTANT VARCHAR2(1)   := '1';            -- �e�R���J�����g
  cv_conc_c_flg    CONSTANT VARCHAR2(1)   := '2';            -- �q�R���J�����g
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �R���J�����g�������i�[�p
  TYPE g_arg_info_ttype IS TABLE OF FND_CONCURRENT_REQUESTS.ARGUMENT1%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_err_msg_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_errmsg_tab          g_err_msg_ttype;        -- �G���[���b�Z�[�W�i�[�p
  gn_errmsg_cnt         NUMBER;                 -- �G���[�o�b�t�@����
  g_errbuf_tab          g_err_msg_ttype;        -- �G���[�o�b�t�@�i�[�p
  gn_errbuf_cnt         NUMBER;                 -- �G���[���b�Z�[�W����
  g_in_arg_info_tab     g_arg_info_ttype;       -- ���͍��ځF�����i�[�p
  gv_exe_request_id     VARCHAR2(5000);         -- �N���Ώۗv��ID�i�[�p
  gv_normal_request_id  VARCHAR2(5000);         -- ����I���v��ID�i�[�p
  gv_warning_request_id VARCHAR2(5000);         -- �x���I���v��ID�i�[�p
  gv_error_request_id   VARCHAR2(5000);         -- �G���[�I���v��ID�i�[�p
--
  /**********************************************************************************
   * Procedure Name   : chk_conc_status
   * Description      : �R���J�����g�X�e�[�^�X�`�F�b�N����(���ʏ���)
   ***********************************************************************************/
  PROCEDURE chk_conc_status(
    iv_conc_flg   IN  VARCHAR2,     -- 1.�`�F�b�N�Ώۂ��e���q���̔��f�t���O
    in_request_id IN  NUMBER,       -- 2.�`�F�b�N�Ώۗv��ID
    in_interval   IN  NUMBER,       -- 3.�X�e�[�^�X�Ď��Ԋu
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_conc_status'; -- �v���O������
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
    cv_appl_short_name    CONSTANT  VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_get_sts_err1_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10023';  -- �X�e�[�^�X�擾���s�G���[1
    cv_expt_sts_err1_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10026';  -- �X�e�[�^�X�ُ�I���G���[1
    cv_err_sts_err1_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10028';  -- �G���[�I�����b�Z�[�W1
    cv_warn_sts_err1_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10030';  -- �x���I�����b�Z�[�W1
    cv_get_sts_err2_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10024';  -- �X�e�[�^�X�擾���s�G���[2
    cv_expt_sts_err2_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10027';  -- �X�e�[�^�X�ُ�I���G���[2
    cv_err_sts_err2_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10029';  -- �G���[�I�����b�Z�[�W2
    cv_warn_sts_err2_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10031';  -- �x���I�����b�Z�[�W2
    cv_req_id_tkn         CONSTANT  VARCHAR2(10)  := 'REQ_ID';            -- �g�[�N��
    cv_phase_tkn          CONSTANT  VARCHAR2(10)  := 'PHASE';             -- �g�[�N��
    cv_status_tkn         CONSTANT  VARCHAR2(10)  := 'STATUS';            -- �g�[�N��
    cv_dev_pahse_complete CONSTANT  VARCHAR2(10)  := 'COMPLETE';          -- �������ʃt�F�[�Y
    cv_dev_status_err     CONSTANT  VARCHAR2(10)  := 'ERROR';             -- �������ʃX�e�[�^�X
    cv_dev_status_warn    CONSTANT  VARCHAR2(10)  := 'WARNING';           -- �������ʃX�e�[�^�X
    cv_dev_status_norm    CONSTANT  VARCHAR2(10)  := 'NORMAL';            -- �������ʃX�e�[�^�X
--
    -- *** ���[�J���ϐ� ***
    lv_get_sts_err_msg     VARCHAR2(100);   -- �X�e�[�^�X�擾���s�G���[
    lv_expt_sts_err_msg    VARCHAR2(100);   -- �X�e�[�^�X�ُ�I���G���[
    lv_err_sts_err_msg    VARCHAR2(100);   -- �G���[�I�����b�Z�[�W
    lv_warn_sts_err_msg   VARCHAR2(100);   -- �x���I�����b�Z�[�W
    lv_phase               VARCHAR2(100);   -- �v���t�F�[�Y
    lv_status              VARCHAR2(100);   -- �v���X�e�[�^�X
    lv_dev_phase           VARCHAR2(100);   -- �������ʃt�F�[�Y
    lv_dev_status          VARCHAR2(100);   -- �������ʃX�e�[�^�X
    lv_message             VARCHAR2(5000);  -- �������ʃ��b�Z�[�W
    lb_result              BOOLEAN;         -- �ҋ@��������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    get_sts_err_expt       EXCEPTION;       -- �X�e�[�^�X�擾���s�G���[
    sts_err_expt           EXCEPTION;       -- �G���[�I����O(�p��)
    sts_warn_expt          EXCEPTION;       -- �x���I����O(�p��)
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
    -- *****************************************************
    -- �`�F�b�N�Ώ۔��f�t���O�ɂ�胁�b�Z�[�W�R�[�h�̐ݒ�
    -- *****************************************************
    -- �e�R���J�����g�̃`�F�b�N�̏ꍇ
    IF ( iv_conc_flg = cv_conc_p_flg ) THEN
      lv_get_sts_err_msg   := cv_get_sts_err1_msg;   -- �X�e�[�^�X�擾���s�G���[
      lv_expt_sts_err_msg  := cv_expt_sts_err1_msg;  -- �X�e�[�^�X�ُ�I���G���[
      lv_err_sts_err_msg  := cv_err_sts_err1_msg;    -- �G���[�I�����b�Z�[�W
      lv_warn_sts_err_msg := cv_warn_sts_err1_msg;   -- �x���I�����b�Z�[�W
    -- �q�R���J�����g�̃`�F�b�N�̏ꍇ
    ELSE
      lv_get_sts_err_msg   := cv_get_sts_err2_msg;   -- �X�e�[�^�X�擾���s�G���[
      lv_expt_sts_err_msg  := cv_expt_sts_err2_msg;  -- �X�e�[�^�X�ُ�I���G���[
      lv_err_sts_err_msg  := cv_err_sts_err2_msg;    -- �G���[�I�����b�Z�[�W
      lv_warn_sts_err_msg := cv_warn_sts_err2_msg;   -- �x���I�����b�Z�[�W
    END IF;
--
    -- �R���J�����g�̏I���X�e�[�^�X�擾
    lb_result :=  FND_CONCURRENT.WAIT_FOR_REQUEST(
                    request_id   => in_request_id
                    ,interval    => in_interval
                    ,max_wait    => NULL
                    ,phase       => lv_phase
                    ,status      => lv_status
                    ,dev_phase   => lv_dev_phase
                    ,dev_status  => lv_dev_status
                    ,message     => lv_message
                  );
--
    -- �X�e�[�^�X�擾�Ɏ��s�����ꍇ(�X�e�[�^�X�擾�̐���/���s���f)
    IF ( NOT lb_result ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => lv_get_sts_err_msg
                      ,iv_token_name1  => cv_req_id_tkn
                      ,iv_token_value1 => TO_CHAR(in_request_id)
                    );
      lv_errbuf := lv_errmsg;
--
      -- �e�R���J�����g�̃`�F�b�N�̏ꍇ
      IF ( iv_conc_flg = cv_conc_p_flg ) THEN
        -- �����I��
        RAISE get_sts_err_expt;
      -- �q�R���J�����g�̃`�F�b�N�̏ꍇ
      ELSE
        -- �����p��
        RAISE sts_err_expt;
      END IF;
--
    -- �X�e�[�^�X�擾�ɐ��������ꍇ(�X�e�[�^�X�擾�̐���/���s���f)
    ELSE
      -- �������ʃt�F�[�Y�������ȊO�̏ꍇ(�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
      IF (lv_dev_phase <> cv_dev_pahse_complete ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_expt_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      -- �������ʃt�F�[�Y������ ���� �������ʃX�e�[�^�X���G���[�̏ꍇ(�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
      ELSIF ( lv_dev_status = cv_dev_status_err ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_err_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      -- �������ʃt�F�[�Y������ ���� �������ʃX�e�[�^�X���x���̏ꍇ(�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
      ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_warn_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_warn_expt;
--
      -- �������ʃt�F�[�Y������ ���� �������ʃX�e�[�^�X������̏ꍇ(�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
      ELSIF ( lv_dev_status = cv_dev_status_norm ) THEN
        -- ���팏���̃J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
        -- ����I���v��ID�̐ݒ�
        IF ( gv_normal_request_id IS NULL ) THEN
          gv_normal_request_id := TO_CHAR(in_request_id);
        ELSE
          gv_normal_request_id := gv_normal_request_id || ' , ' || TO_CHAR(in_request_id);
        END IF;
--
      -- �������ʃt�F�[�Y������ ���� �������ʃX�e�[�^�X����L�ȊO�̏ꍇ(�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
      ELSE
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_expt_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      END IF;    -- (�������ʃt�F�[�Y�E�������ʃX�e�[�^�X�̔��f)
--
    END IF;  -- (�X�e�[�^�X�擾�̐���/���s���f)
--
  EXCEPTION
    WHEN get_sts_err_expt THEN                           --*** �X�e�[�^�X�擾���s�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    WHEN sts_err_expt THEN                               --*** �G���[�I����O(�p��) ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- **************************************************
      -- �������p�����邽�߁A�������𐳏�I��������
      -- **************************************************
      -- �G���[�����̃J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      -- �G���[�I���v��ID�̐ݒ�
      IF ( gv_error_request_id IS NULL ) THEN
        gv_error_request_id := TO_CHAR(in_request_id);
      ELSE
        gv_error_request_id := gv_error_request_id || ' , ' || TO_CHAR(in_request_id);
      END IF;
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--
    WHEN sts_warn_expt THEN                              --*** �x���I����O(�p��) ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- **************************************************
      -- �������p�����邽�߁A�������𐳏�I��������
      -- **************************************************
      -- �x�������̃J�E���g
      gn_warn_cnt := gn_warn_cnt + 1;
      -- �x���I���v��ID�̐ݒ�
      IF ( gv_warning_request_id IS NULL ) THEN
        gv_warning_request_id := TO_CHAR(in_request_id);
      ELSE
        gv_warning_request_id := gv_warning_request_id || ' , ' || TO_CHAR(in_request_id);
      END IF;
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_conc_status;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_exe_appl_short_name IN VARCHAR2,  -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name IN VARCHAR2,  -- 2.�N���ΏۃR���J�����g�Z�k��
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
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_appl_short_name_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10020'; -- �A�v���P�[�V���������̓G���[
    cv_conc_short_name_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10021'; -- �R���J�����g�����̓G���[
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    required_err_expt     EXCEPTION;
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
    -- �N���ΏۃA�v���P�[�V�����Z�k���̕K�{�`�F�b�N
    IF ( iv_exe_appl_short_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_appl_short_name_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE required_err_expt;
    END IF;
--
    -- �N���ΏۃR���J�����g�Z�k���̕K�{�`�F�b�N
    IF ( iv_exe_conc_short_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_conc_short_name_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE required_err_expt;
    END IF;
--
  EXCEPTION
    WHEN required_err_expt THEN                           --*** �K�{�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : get_parent_conc_info
   * Description      : �e�R���J�����g���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_parent_conc_info(
    iv_exe_appl_short_name   IN  VARCHAR2,           --1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name   IN  VARCHAR2,           --2.�N���ΏۃR���J�����g�Z�k��
    on_parent_param_cnt      OUT NUMBER,             --3.�e�R���J�����g�p�����[�^��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parent_conc_info'; -- �v���O������
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
    cv_conc_param_field_nm   CONSTANT VARCHAR2(100) := '$SRS$.';  -- �R���J�����g�p�����[�^�̃t�B�[���h��
    cv_appl_short_name       CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_max_para_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10059'; -- �R���J�����g�p�����[�^�ő匏�����߃��[�j���O
--
    -- *** ���[�J���ϐ� ***
    ln_param_cnt        NUMBER;    -- �e�R���J�����g�p�����[�^��
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
    -- �e�R���J�����g�̃p�����[�^�����擾
    BEGIN
      SELECT   COUNT(fdfcuv.descriptive_flexfield_name) param_cnt
      INTO     ln_param_cnt
      FROM     fnd_concurrent_programs_vl  fcpv                              -- �R���J�����g�}�X�^
              ,fnd_descr_flex_col_usage_vl fdfcuv                            -- �R���J�����g�p�����[�^�}�X�^
              ,fnd_application_vl          fav                               -- �A�v���P�[�V�����}�X�^
      WHERE   fav.application_short_name        = iv_exe_appl_short_name     -- �A�v���P�[�V�����Z�k��
      AND     fav.application_id                = fcpv.application_id        -- �A�v���P�[�V����ID
      AND     fcpv.concurrent_program_name      = iv_exe_conc_short_name     -- �R���J�����g�v���O������
      AND     fcpv.application_id               = fdfcuv.application_id      -- �A�v���P�[�V����ID
      AND     fdfcuv.descriptive_flexfield_name = cv_conc_param_field_nm || fcpv.concurrent_program_name -- �t�B�[���h��
      AND     fdfcuv.enabled_flag               = cv_flg_y               -- �L���t���O
      GROUP BY fdfcuv.application_id, fdfcuv.descriptive_flexfield_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_param_cnt := 0;
    END;
--
-- 2009/03/11 UPDATE START
--    on_parent_param_cnt := ln_param_cnt;
    IF ( ln_param_cnt > cn_param_max_cnt ) THEN
      -- �������ő匏���֏C��
      on_parent_param_cnt := cn_param_max_cnt;
-- 2009/04/20 Ver.1.2 DELETE By Masayuki.Sano Start
--      -- ��O����
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application => cv_appl_short_name
--                     ,iv_name        => cv_max_para_err_msg
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
-- 2009/04/20 Ver.1.2 DELETE By Masayuki.Sano End
    ELSE
      on_parent_param_cnt := ln_param_cnt;
    END IF;
-- 2009/03/11 UPDATE END
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
  END get_parent_conc_info;
--
  /**********************************************************************************
   * Procedure Name   : exe_parent_conc
   * Description      : �e�R���J�����g�N������(A-3)
   ***********************************************************************************/
  PROCEDURE exe_parent_conc(
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.�N���ΏۃA�v���P�[�V�����Z�k��
    in_parent_param_cnt     IN   NUMBER,              -- 3.�e�R���J�����g�p�����[�^��
    on_request_id           OUT  NUMBER,              -- 4.�e�R���J�����g�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_parent_conc'; -- �v���O������
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
    -- �v���t�@�C���uXXCCP:�e�R���J�����g�X�e�[�^�X�Ď��Ԋu�v
    cv_parent_conc_time_pf_nm  CONSTANT VARCHAR2(100) := 'XXCCP1_CONC_WATCH_TIME';
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_profile_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10032'; -- �v���t�@�C���擾�G���[
    cv_exe_conc_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10022'; -- �R���J�����g�̋N�����s�G���[
    cv_profile_name_tkn        CONSTANT VARCHAR2(100) := 'PROFILE_NAME';     -- �g�[�N��
--
    -- *** ���[�J���ϐ� ***
    lv_parent_conc_time  VARCHAR2(5000);               -- �v���t�@�C���uXXCCP:�e�R���J�����g�X�e�[�^�X�Ď��Ԋu�v�i�[�p
    lt_request_id        fnd_concurrent_requests.request_id%TYPE;  -- �v��ID
    l_ed_arg_info_tab    g_arg_info_ttype;             -- �e�R���J�����g���s�p����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    sub_process_expt       EXCEPTION;         -- ���������ʗ�O
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
    -- �v���t�@�C���uXXCCP:�e�R���J�����g�X�e�[�^�X�Ď��Ԋu�v�̎擾
    lv_parent_conc_time :=  FND_PROFILE.VALUE(
                              name => cv_parent_conc_time_pf_nm
                            );
    -- �擾�����v���t�@�C���̕K�{�`�F�b�N
    IF ( lv_parent_conc_time IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_profile_name_tkn
                      ,iv_token_value1 => cv_parent_conc_time_pf_nm
                    );
      lv_errbuf := lv_errmsg;
      RAISE sub_process_expt;
    END IF;
--
    -- �e�R���J�����g���s�p�ϐ��̏�����(CHR(0)���i�[)
    <<ed_arg_init_loop>>
    FOR i IN 1..cn_param_max_cnt LOOP
      l_ed_arg_info_tab(i) := CHR(0);
    END LOOP ed_arg_init_loop;
--
    -- �e�R���J�����g���s�p�ϐ��ɍ�Ɨp�ϐ����i�[
    IF ( in_parent_param_cnt > 0 ) THEN
      <<ed_arg_set_loop>>
      FOR i IN 1..in_parent_param_cnt LOOP
        l_ed_arg_info_tab(i) := g_in_arg_info_tab(i);
      END LOOP ed_arg_set_loop;
    END IF;
--
    -- �e�R���J�����g�̎��s
    lt_request_id :=  FND_REQUEST.SUBMIT_REQUEST(
                        application  => iv_exe_appl_short_name,
                        program      => iv_exe_conc_short_name,
                        description  => NULL,
                        start_time   => NULL,
                        sub_request  => NULL,
                        argument1    => l_ed_arg_info_tab(1),
                        argument2    => l_ed_arg_info_tab(2),
                        argument3    => l_ed_arg_info_tab(3),
                        argument4    => l_ed_arg_info_tab(4),
                        argument5    => l_ed_arg_info_tab(5),
                        argument6    => l_ed_arg_info_tab(6),
                        argument7    => l_ed_arg_info_tab(7),
                        argument8    => l_ed_arg_info_tab(8),
                        argument9    => l_ed_arg_info_tab(9),
                        argument10   => l_ed_arg_info_tab(10),
                        argument11   => l_ed_arg_info_tab(11),
                        argument12   => l_ed_arg_info_tab(12),
                        argument13   => l_ed_arg_info_tab(13),
                        argument14   => l_ed_arg_info_tab(14),
                        argument15   => l_ed_arg_info_tab(15),
                        argument16   => l_ed_arg_info_tab(16),
                        argument17   => l_ed_arg_info_tab(17),
                        argument18   => l_ed_arg_info_tab(18),
                        argument19   => l_ed_arg_info_tab(19),
                        argument20   => l_ed_arg_info_tab(20),
                        argument21   => l_ed_arg_info_tab(21),
                        argument22   => l_ed_arg_info_tab(22),
                        argument23   => l_ed_arg_info_tab(23),
                        argument24   => l_ed_arg_info_tab(24),
                        argument25   => l_ed_arg_info_tab(25),
                        argument26   => l_ed_arg_info_tab(26),
                        argument27   => l_ed_arg_info_tab(27),
                        argument28   => l_ed_arg_info_tab(28),
                        argument29   => l_ed_arg_info_tab(29),
                        argument30   => l_ed_arg_info_tab(30),
                        argument31   => l_ed_arg_info_tab(31),
                        argument32   => l_ed_arg_info_tab(32),
                        argument33   => l_ed_arg_info_tab(33),
                        argument34   => l_ed_arg_info_tab(34),
                        argument35   => l_ed_arg_info_tab(35),
                        argument36   => l_ed_arg_info_tab(36),
                        argument37   => l_ed_arg_info_tab(37),
                        argument38   => l_ed_arg_info_tab(38),
                        argument39   => l_ed_arg_info_tab(39),
                        argument40   => l_ed_arg_info_tab(40),
                        argument41   => l_ed_arg_info_tab(41),
                        argument42   => l_ed_arg_info_tab(42),
                        argument43   => l_ed_arg_info_tab(43),
                        argument44   => l_ed_arg_info_tab(44),
                        argument45   => l_ed_arg_info_tab(45),
                        argument46   => l_ed_arg_info_tab(46),
                        argument47   => l_ed_arg_info_tab(47),
                        argument48   => l_ed_arg_info_tab(48),
                        argument49   => l_ed_arg_info_tab(49),
                        argument50   => l_ed_arg_info_tab(50),
                        argument51   => l_ed_arg_info_tab(51),
                        argument52   => l_ed_arg_info_tab(52),
                        argument53   => l_ed_arg_info_tab(53),
                        argument54   => l_ed_arg_info_tab(54),
                        argument55   => l_ed_arg_info_tab(55),
                        argument56   => l_ed_arg_info_tab(56),
                        argument57   => l_ed_arg_info_tab(57),
                        argument58   => l_ed_arg_info_tab(58),
                        argument59   => l_ed_arg_info_tab(59),
                        argument60   => l_ed_arg_info_tab(60),
                        argument61   => l_ed_arg_info_tab(61),
                        argument62   => l_ed_arg_info_tab(62),
                        argument63   => l_ed_arg_info_tab(63),
                        argument64   => l_ed_arg_info_tab(64),
                        argument65   => l_ed_arg_info_tab(65),
                        argument66   => l_ed_arg_info_tab(66),
                        argument67   => l_ed_arg_info_tab(67),
                        argument68   => l_ed_arg_info_tab(68),
                        argument69   => l_ed_arg_info_tab(69),
                        argument70   => l_ed_arg_info_tab(70),
                        argument71   => l_ed_arg_info_tab(71),
                        argument72   => l_ed_arg_info_tab(72),
                        argument73   => l_ed_arg_info_tab(73),
                        argument74   => l_ed_arg_info_tab(74),
                        argument75   => l_ed_arg_info_tab(75),
                        argument76   => l_ed_arg_info_tab(76),
                        argument77   => l_ed_arg_info_tab(77),
                        argument78   => l_ed_arg_info_tab(78),
                        argument79   => l_ed_arg_info_tab(79),
                        argument80   => l_ed_arg_info_tab(80),
                        argument81   => l_ed_arg_info_tab(81),
                        argument82   => l_ed_arg_info_tab(82),
                        argument83   => l_ed_arg_info_tab(83),
                        argument84   => l_ed_arg_info_tab(84),
                        argument85   => l_ed_arg_info_tab(85),
                        argument86   => l_ed_arg_info_tab(86),
                        argument87   => l_ed_arg_info_tab(87),
                        argument88   => l_ed_arg_info_tab(88),
                        argument89   => l_ed_arg_info_tab(89),
                        argument90   => l_ed_arg_info_tab(90),
                        argument91   => l_ed_arg_info_tab(91),
                        argument92   => l_ed_arg_info_tab(92),
                        argument93   => l_ed_arg_info_tab(93),
                        argument94   => l_ed_arg_info_tab(94),
                        argument95   => l_ed_arg_info_tab(95),
                        argument96   => l_ed_arg_info_tab(96),
                        argument97   => l_ed_arg_info_tab(97)
                      );
    -- �e�R���J�����g�̔��s�Ɏ��s�����ꍇ
    IF ( lt_request_id <= 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => cv_exe_conc_err_msg
                    );
      lv_errbuf := lv_errmsg;
      RAISE sub_process_expt;
    END IF;
--
    -- �R�~�b�g
    COMMIT;
    -- �Ώی����̃J�E���g�A�b�v
    gn_target_cnt := gn_target_cnt + 1;
    -- �N���Ώۗv��ID�̊i�[
    gv_exe_request_id := TO_CHAR(lt_request_id);
    on_request_id     := lt_request_id;
--
    -- �R���J�����g�X�e�[�^�X�`�F�b�N����(���ʏ���)�̌Ăяo��
    chk_conc_status(
      iv_conc_flg      =>  cv_conc_p_flg
      ,in_request_id   =>  lt_request_id
      ,in_interval     =>  TO_NUMBER(lv_parent_conc_time)
      ,ov_errbuf       =>  lv_errbuf
      ,ov_retcode      =>  lv_retcode
      ,ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE sub_process_expt;
    END IF;
--
  EXCEPTION
    WHEN sub_process_expt THEN                           --*** ���������ʗ�O���� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END exe_parent_conc;
--
  /**********************************************************************************
   * Procedure Name   : wait_for_child_conc
   * Description      : �q�R���J�����g�I���҂�����(A-4)
   ***********************************************************************************/
  PROCEDURE wait_for_child_conc(
    in_request_id       IN NUMBER,     -- 1.�e�R���J�����g�v��ID
    iv_child_conc_time  IN VARCHAR2,   -- 2.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_for_child_conc'; -- �v���O������
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
    cv_appl_short_name         CONSTANT VARCHAR2(10)   := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_child_conc_err_msg      CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-10025';  --�q�R���J�����g���N���G���[
--
    -- *** ���[�J���ϐ� ***
    ln_conc_time       NUMBER;           -- �q�R���J�����g�X�e�[�^�X�Ď��Ԋu�i�[�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �q�R���J�����g�v��ID�擾�J�[�\��
    CURSOR get_child_conc_cur
    IS
      SELECT  request_id  request_id                 -- �v��ID(2�K�w��)
      FROM    fnd_concurrent_requests  fcq           -- �v���Ǘ��}�X�^
      WHERE   fcq.parent_request_id = in_request_id  -- �e�v��ID
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano Start
      UNION ALL
      SELECT  fcq3.request_id                        -- �v��ID(3�K�w��)
      FROM    fnd_concurrent_requests  fcq2          -- �v���Ǘ��}�X�^(2�K�w��)
             ,fnd_concurrent_requests  fcq3          -- �v���Ǘ��}�X�^(3�K�w��)
      WHERE   fcq2.parent_request_id = in_request_id -- �e�v��ID
      AND     fcq3.parent_request_id = fcq2.request_id
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano End
      ORDER BY request_id
      ;
    -- �q�R���J�����g�v��ID���R�[�h�^
    get_child_conc_rec  get_child_conc_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
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
    -- �q�R���J�����g�v��ID�̎擾
    OPEN  get_child_conc_cur;
    FETCH get_child_conc_cur INTO get_child_conc_rec;
--
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano Start
--    -- �q�R���J�����g�v��ID��0���̏ꍇ
--    IF ( get_child_conc_cur%NOTFOUND ) THEN
--      -- �J�[�\���̃N���[�Y
--      CLOSE get_child_conc_cur;
--      -- ���b�Z�[�W�擾
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_child_conc_err_msg
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_process_expt;
--    END IF;
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano End
--
    -- ******************************************************
    -- �q�R���J�����g�ɂ��āA�X�e�[�^�X�`�F�b�N���s���B
    -- ******************************************************
    -- �q�R���J�����g�X�e�[�^�X�Ď��Ԋu�̐ݒ�
    IF ( iv_child_conc_time IS NULL ) THEN
      ln_conc_time := 3;
    ELSE
      ln_conc_time := TO_NUMBER(iv_child_conc_time);
    END IF;
--
    <<get_child_conc_loop>>
    WHILE get_child_conc_cur%FOUND LOOP
      -- �Ώی����̃J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �R���J�����g�X�e�[�^�X�`�F�b�N����(���ʋ@�\)�̌Ăяo��
      chk_conc_status(
        iv_conc_flg      =>  cv_conc_c_flg
        ,in_request_id   =>  get_child_conc_rec.request_id
        ,in_interval     =>  ln_conc_time
        ,ov_errbuf       =>  lv_errbuf
        ,ov_retcode      =>  lv_retcode
        ,ov_errmsg       =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE  get_child_conc_cur;
        RAISE global_process_expt;
      END IF;
--
      -- �����R�[�h�̎擾
      FETCH get_child_conc_cur INTO get_child_conc_rec;
--
    END LOOP get_child_conc_loop;
--
    -- �J�[�\���̃N���[�Y
    CLOSE  get_child_conc_cur;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END wait_for_child_conc;
--
  /**********************************************************************************
   * Procedure Name   : end_conc
   * Description      : �I������(A-5)
   ***********************************************************************************/
  PROCEDURE end_conc(
    iv_retcode              IN  VARCHAR2,                     -- 1.�����X�e�[�^�X
    iv_exe_appl_short_name  IN  VARCHAR2,                     -- 2.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name  IN  VARCHAR2,                     -- 3.�N���ΏۃR���J�����g�Z�k��
    iv_child_conc_time      IN  VARCHAR2,                     -- 4.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    in_parent_param_cnt     IN  NUMBER,                       -- 5.�e�R���J�����g�p�����[�^��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_conc'; -- �v���O������
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
    cv_appl_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';
-- 2009/03/11 UPDATE START
--    cv_appl_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10002';  -- �A�v���P�[�V�����Z�k�����b�Z�[�W
--    cv_conc_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10003';  -- �R���J�����g�Z�k�����b�Z�[�W
--    cv_child_conc_tm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10004';  -- �q�R���J�����g�Ď��Ԋu���b�Z�[�W
--    cv_in_arg_msg            CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10005';  -- �������b�Z�[�W
--    cv_exe_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10006';  -- �N���Ώۗv��ID���b�Z�[�W
--    cv_norm_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10007';  -- ����I���v��ID���b�Z�[�W
--    cv_warn_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00008';  -- �x���I���v��ID���b�Z�[�W
--    cv_err_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10009';  -- �G���[�I���v��ID���b�Z�[�W
    cv_appl_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00002';  -- �A�v���P�[�V�����Z�k�����b�Z�[�W
    cv_conc_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00003';  -- �R���J�����g�Z�k�����b�Z�[�W
    cv_child_conc_tm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00004';  -- �q�R���J�����g�Ď��Ԋu���b�Z�[�W
    cv_in_arg_msg            CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00005';  -- �������b�Z�[�W
    cv_exe_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00006';  -- �N���Ώۗv��ID���b�Z�[�W
    cv_norm_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00007';  -- ����I���v��ID���b�Z�[�W
    cv_warn_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00008';  -- �x���I���v��ID���b�Z�[�W
    cv_err_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00009';  -- �G���[�I���v��ID���b�Z�[�W
-- 2009/03/11 UPDATE END
    cv_target_rec_msg        CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg       CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token             CONSTANT VARCHAR2(10)   := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg            CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg              CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_warn_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-00001';  -- �x���������b�Z�[�W
    cv_err_msg               CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-10008';  -- �G���[�I�����b�Z�[�W
--
    cv_ap_short_name_tkn     CONSTANT  VARCHAR2(100) := 'AP_SHORT_NAME';     -- �g�[�N��
    cv_conc_short_name_tkn   CONSTANT  VARCHAR2(100) := 'CONC_SHORT_NAME';   -- �g�[�N��
    cv_time_tkn              CONSTANT  VARCHAR2(100) := 'TIME';              -- �g�[�N��
    cv_number_tkn            CONSTANT  VARCHAR2(100) := 'NUMBER';            -- �g�[�N��
    cv_param_value_tkn       CONSTANT  VARCHAR2(100) := 'PARAM_VALUE';       -- �g�[�N��
    cv_req_id_tkn            CONSTANT  VARCHAR2(100) := 'REQ_ID';            -- �g�[�N��
--
    -- *** ���[�J���ϐ� ***
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    -- **********************************************
    -- ���͍��ڂ̃��|�[�g�o��
    -- **********************************************
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �N���ΏۃA�v���P�[�V�����Z�k��
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_appl_short_nm_msg
                    ,iv_token_name1  => cv_ap_short_name_tkn
                    ,iv_token_value1 => iv_exe_appl_short_name
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- �N���ΏۃR���J�����g�Z�k��
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_conc_short_nm_msg
                    ,iv_token_name1  => cv_conc_short_name_tkn
                    ,iv_token_value1 => iv_exe_conc_short_name
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- �q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_child_conc_tm_msg
                    ,iv_token_name1  => cv_time_tkn
                    ,iv_token_value1 => iv_child_conc_time
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- ����
    IF (in_parent_param_cnt > 0 ) THEN
      <<output_in_info_loop>>
      FOR i IN 1..in_parent_param_cnt LOOP
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => cv_in_arg_msg
                        ,iv_token_name1  => cv_number_tkn
                        ,iv_token_value1 => TO_CHAR(i)
                        ,iv_token_name2  => cv_param_value_tkn
                        ,iv_token_value2 => g_in_arg_info_tab(i)
                      );
        FND_FILE.PUT_LINE(
            which   => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
            which   => FND_FILE.LOG
            ,buff   => lv_errmsg
        );
      END LOOP output_in_info_loop;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => ''
    );
--
    -- *************************************************
    -- �I���X�e�[�^�X�̐ݒ�(�X�e�[�^�X�`�F�b�N�Ŕ��������x����G���[�̔��f)
    -- �G���[���~�ȊO�̏ꍇ�̂݃X�e�[�^�X��ݒ�
    -- *************************************************
    IF ( iv_retcode = cv_status_normal ) THEN
      -- �G���[������1���ȏ�̏ꍇ
      IF ( gn_error_cnt >= 1 ) THEN
        lv_retcode := cv_status_error;
      -- �G���[������0�� ���� �x��������1���ȏ�̏ꍇ
      ELSIF ( gn_warn_cnt >= 1 ) THEN
        lv_retcode := cv_status_warn;
      ELSE
        lv_retcode := iv_retcode;
      END IF;
    ELSE
      lv_retcode := iv_retcode;
    END IF;
--
    -- **********************************************
    -- �v��ID���ڂ̃��|�[�g�o��
    -- **********************************************
    -- �N���Ώۗv��ID���b�Z�[�W
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_exe_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_exe_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- ����I���v��ID���b�Z�[�W
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_norm_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_normal_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- �x���I���v��ID���b�Z�[�W
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_warn_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_warning_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- �G���[�I���v��ID���b�Z�[�W
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_err_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_error_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- **********************************************
    -- �G���[���b�Z�[�W�o��
    -- **********************************************
    --�G���[�o��
    IF ( gn_errmsg_cnt > 0 ) THEN
      <<output_err_msg_loop>>
      FOR i IN 1..gn_errmsg_cnt LOOP
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
          ,buff   => g_errmsg_tab(i) --���[�U�[�E�G���[���b�Z�[�W
        );
      END LOOP output_err_msg_loop;
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    IF ( gn_errbuf_cnt > 0 ) THEN
      <<output_err_buf_loop>>
      FOR i IN 1..gn_errbuf_cnt LOOP
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => g_errbuf_tab(i) --�G���[���b�Z�[�W
        );
      END LOOP output_err_buf_loop;
    END IF;
--
    -- **********************************************
    -- �����̃��|�[�g�o��
    -- **********************************************
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_err_msg;
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
--
    ov_retcode := lv_retcode;
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
  END end_conc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.�N���ΏۃR���J�����g�Z�k��
    iv_child_conc_time      IN   VARCHAR2,            -- 3.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    iv_param1               IN   VARCHAR2,            -- 4.����1
    iv_param2               IN   VARCHAR2,            -- 5.����2
    iv_param3               IN   VARCHAR2,            -- 6.����3
    iv_param4               IN   VARCHAR2,            -- 7.����4
    iv_param5               IN   VARCHAR2,            -- 8.����5
    iv_param6               IN   VARCHAR2,            -- 9.����6
    iv_param7               IN   VARCHAR2,            -- 10.����7
    iv_param8               IN   VARCHAR2,            -- 11.����8
    iv_param9               IN   VARCHAR2,            -- 12.����9
    iv_param10              IN   VARCHAR2,            -- 13.����10
    iv_param11              IN   VARCHAR2,            -- 14.����11
    iv_param12              IN   VARCHAR2,            -- 15.����12
    iv_param13              IN   VARCHAR2,            -- 16.����13
    iv_param14              IN   VARCHAR2,            -- 17.����14
    iv_param15              IN   VARCHAR2,            -- 18.����15
    iv_param16              IN   VARCHAR2,            -- 19.����16
    iv_param17              IN   VARCHAR2,            -- 20.����17
    iv_param18              IN   VARCHAR2,            -- 21.����18
    iv_param19              IN   VARCHAR2,            -- 22.����19
    iv_param20              IN   VARCHAR2,            -- 23.����20
    iv_param21              IN   VARCHAR2,            -- 24.����21
    iv_param22              IN   VARCHAR2,            -- 25.����22
    iv_param23              IN   VARCHAR2,            -- 26.����23
    iv_param24              IN   VARCHAR2,            -- 27.����24
    iv_param25              IN   VARCHAR2,            -- 28.����25
    iv_param26              IN   VARCHAR2,            -- 29.����26
    iv_param27              IN   VARCHAR2,            -- 30.����27
    iv_param28              IN   VARCHAR2,            -- 31.����28
    iv_param29              IN   VARCHAR2,            -- 32.����29
    iv_param30              IN   VARCHAR2,            -- 33.����30
    iv_param31              IN   VARCHAR2,            -- 34.����31
    iv_param32              IN   VARCHAR2,            -- 35.����32
    iv_param33              IN   VARCHAR2,            -- 36.����33
    iv_param34              IN   VARCHAR2,            -- 37.����34
    iv_param35              IN   VARCHAR2,            -- 38.����35
    iv_param36              IN   VARCHAR2,            -- 39.����36
    iv_param37              IN   VARCHAR2,            -- 40.����37
    iv_param38              IN   VARCHAR2,            -- 41.����38
    iv_param39              IN   VARCHAR2,            -- 42.����39
    iv_param40              IN   VARCHAR2,            -- 43.����40
    iv_param41              IN   VARCHAR2,            -- 44.����41
    iv_param42              IN   VARCHAR2,            -- 45.����42
    iv_param43              IN   VARCHAR2,            -- 46.����43
    iv_param44              IN   VARCHAR2,            -- 47.����44
    iv_param45              IN   VARCHAR2,            -- 48.����45
    iv_param46              IN   VARCHAR2,            -- 49.����46
    iv_param47              IN   VARCHAR2,            -- 50.����47
    iv_param48              IN   VARCHAR2,            -- 51.����48
    iv_param49              IN   VARCHAR2,            -- 52.����49
    iv_param50              IN   VARCHAR2,            -- 53.����50
    iv_param51              IN   VARCHAR2,            -- 54.����51
    iv_param52              IN   VARCHAR2,            -- 55.����52
    iv_param53              IN   VARCHAR2,            -- 56.����53
    iv_param54              IN   VARCHAR2,            -- 57.����54
    iv_param55              IN   VARCHAR2,            -- 58.����55
    iv_param56              IN   VARCHAR2,            -- 59.����56
    iv_param57              IN   VARCHAR2,            -- 60.����57
    iv_param58              IN   VARCHAR2,            -- 61.����58
    iv_param59              IN   VARCHAR2,            -- 62.����59
    iv_param60              IN   VARCHAR2,            -- 63.����60
    iv_param61              IN   VARCHAR2,            -- 64.����61
    iv_param62              IN   VARCHAR2,            -- 65.����62
    iv_param63              IN   VARCHAR2,            -- 66.����63
    iv_param64              IN   VARCHAR2,            -- 67.����64
    iv_param65              IN   VARCHAR2,            -- 68.����65
    iv_param66              IN   VARCHAR2,            -- 69.����66
    iv_param67              IN   VARCHAR2,            -- 70.����67
    iv_param68              IN   VARCHAR2,            -- 71.����68
    iv_param69              IN   VARCHAR2,            -- 72.����69
    iv_param70              IN   VARCHAR2,            -- 73.����70
    iv_param71              IN   VARCHAR2,            -- 74.����71
    iv_param72              IN   VARCHAR2,            -- 75.����72
    iv_param73              IN   VARCHAR2,            -- 76.����73
    iv_param74              IN   VARCHAR2,            -- 77.����74
    iv_param75              IN   VARCHAR2,            -- 78.����75
    iv_param76              IN   VARCHAR2,            -- 79.����76
    iv_param77              IN   VARCHAR2,            -- 80.����77
    iv_param78              IN   VARCHAR2,            -- 81.����78
    iv_param79              IN   VARCHAR2,            -- 82.����79
    iv_param80              IN   VARCHAR2,            -- 83.����80
    iv_param81              IN   VARCHAR2,            -- 84.����81
    iv_param82              IN   VARCHAR2,            -- 85.����82
    iv_param83              IN   VARCHAR2,            -- 86.����83
    iv_param84              IN   VARCHAR2,            -- 87.����84
    iv_param85              IN   VARCHAR2,            -- 88.����85
    iv_param86              IN   VARCHAR2,            -- 89.����86
    iv_param87              IN   VARCHAR2,            -- 90.����87
    iv_param88              IN   VARCHAR2,            -- 91.����88
    iv_param89              IN   VARCHAR2,            -- 92.����89
    iv_param90              IN   VARCHAR2,            -- 93.����90
    iv_param91              IN   VARCHAR2,            -- 94.����91
    iv_param92              IN   VARCHAR2,            -- 95.����92
    iv_param93              IN   VARCHAR2,            -- 96.����93
    iv_param94              IN   VARCHAR2,            -- 97.����94
    iv_param95              IN   VARCHAR2,            -- 98.����95
    iv_param96              IN   VARCHAR2,            -- 99.����96
    iv_param97              IN   VARCHAR2,            -- 100.����97
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
    ln_parent_param_cnt        NUMBER;                                   -- �e�R���J�����g�p�����[�^��
    lt_parent_request_id       fnd_concurrent_requests.request_id%TYPE;  -- �e�R���J�����g�v��ID
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
    -- �O���[�o���ϐ��̏�����
    gv_exe_request_id     := NULL;         -- �N���Ώۗv��ID�i�[�p
    gv_normal_request_id  := NULL;         -- ����I���v��ID�i�[�p
    gv_warning_request_id := NULL;         -- �x���I���v��ID�i�[�p
    gv_error_request_id   := NULL;         -- �G���[�I���v��ID�i�[�p
    gn_errmsg_cnt         := 0;            -- �G���[���b�Z�[�W����
    gn_errbuf_cnt         := 0;            -- �G���[�o�b�t�@����
--
    -- ���͍��ځF��������Ɨp�ϐ��Ɋi�[
    g_in_arg_info_tab(1)   := iv_param1;
    g_in_arg_info_tab(2)   := iv_param2;
    g_in_arg_info_tab(3)   := iv_param3;
    g_in_arg_info_tab(4)   := iv_param4;
    g_in_arg_info_tab(5)   := iv_param5;
    g_in_arg_info_tab(6)   := iv_param6;
    g_in_arg_info_tab(7)   := iv_param7;
    g_in_arg_info_tab(8)   := iv_param8;
    g_in_arg_info_tab(9)   := iv_param9;
    g_in_arg_info_tab(10)  := iv_param10;
    g_in_arg_info_tab(11)  := iv_param11;
    g_in_arg_info_tab(12)  := iv_param12;
    g_in_arg_info_tab(13)  := iv_param13;
    g_in_arg_info_tab(14)  := iv_param14;
    g_in_arg_info_tab(15)  := iv_param15;
    g_in_arg_info_tab(16)  := iv_param16;
    g_in_arg_info_tab(17)  := iv_param17;
    g_in_arg_info_tab(18)  := iv_param18;
    g_in_arg_info_tab(19)  := iv_param19;
    g_in_arg_info_tab(20)  := iv_param20;
    g_in_arg_info_tab(21)  := iv_param21;
    g_in_arg_info_tab(22)  := iv_param22;
    g_in_arg_info_tab(23)  := iv_param23;
    g_in_arg_info_tab(24)  := iv_param24;
    g_in_arg_info_tab(25)  := iv_param25;
    g_in_arg_info_tab(26)  := iv_param26;
    g_in_arg_info_tab(27)  := iv_param27;
    g_in_arg_info_tab(28)  := iv_param28;
    g_in_arg_info_tab(29)  := iv_param29;
    g_in_arg_info_tab(30)  := iv_param30;
    g_in_arg_info_tab(31)  := iv_param31;
    g_in_arg_info_tab(32)  := iv_param32;
    g_in_arg_info_tab(33)  := iv_param33;
    g_in_arg_info_tab(34)  := iv_param34;
    g_in_arg_info_tab(35)  := iv_param35;
    g_in_arg_info_tab(36)  := iv_param36;
    g_in_arg_info_tab(37)  := iv_param37;
    g_in_arg_info_tab(38)  := iv_param38;
    g_in_arg_info_tab(39)  := iv_param39;
    g_in_arg_info_tab(40)  := iv_param40;
    g_in_arg_info_tab(41)  := iv_param41;
    g_in_arg_info_tab(42)  := iv_param42;
    g_in_arg_info_tab(43)  := iv_param43;
    g_in_arg_info_tab(44)  := iv_param44;
    g_in_arg_info_tab(45)  := iv_param45;
    g_in_arg_info_tab(46)  := iv_param46;
    g_in_arg_info_tab(47)  := iv_param47;
    g_in_arg_info_tab(48)  := iv_param48;
    g_in_arg_info_tab(49)  := iv_param49;
    g_in_arg_info_tab(50)  := iv_param50;
    g_in_arg_info_tab(51)  := iv_param51;
    g_in_arg_info_tab(52)  := iv_param52;
    g_in_arg_info_tab(53)  := iv_param53;
    g_in_arg_info_tab(54)  := iv_param54;
    g_in_arg_info_tab(55)  := iv_param55;
    g_in_arg_info_tab(56)  := iv_param56;
    g_in_arg_info_tab(57)  := iv_param57;
    g_in_arg_info_tab(58)  := iv_param58;
    g_in_arg_info_tab(59)  := iv_param59;
    g_in_arg_info_tab(60)  := iv_param60;
    g_in_arg_info_tab(61)  := iv_param61;
    g_in_arg_info_tab(62)  := iv_param62;
    g_in_arg_info_tab(63)  := iv_param63;
    g_in_arg_info_tab(64)  := iv_param64;
    g_in_arg_info_tab(65)  := iv_param65;
    g_in_arg_info_tab(66)  := iv_param66;
    g_in_arg_info_tab(67)  := iv_param67;
    g_in_arg_info_tab(68)  := iv_param68;
    g_in_arg_info_tab(69)  := iv_param69;
    g_in_arg_info_tab(70)  := iv_param70;
    g_in_arg_info_tab(71)  := iv_param71;
    g_in_arg_info_tab(72)  := iv_param72;
    g_in_arg_info_tab(73)  := iv_param73;
    g_in_arg_info_tab(74)  := iv_param74;
    g_in_arg_info_tab(75)  := iv_param75;
    g_in_arg_info_tab(76)  := iv_param76;
    g_in_arg_info_tab(77)  := iv_param77;
    g_in_arg_info_tab(78)  := iv_param78;
    g_in_arg_info_tab(79)  := iv_param79;
    g_in_arg_info_tab(80)  := iv_param80;
    g_in_arg_info_tab(81)  := iv_param81;
    g_in_arg_info_tab(82)  := iv_param82;
    g_in_arg_info_tab(83)  := iv_param83;
    g_in_arg_info_tab(84)  := iv_param84;
    g_in_arg_info_tab(85)  := iv_param85;
    g_in_arg_info_tab(86)  := iv_param86;
    g_in_arg_info_tab(87)  := iv_param87;
    g_in_arg_info_tab(88)  := iv_param88;
    g_in_arg_info_tab(89)  := iv_param89;
    g_in_arg_info_tab(90)  := iv_param90;
    g_in_arg_info_tab(91)  := iv_param91;
    g_in_arg_info_tab(92)  := iv_param92;
    g_in_arg_info_tab(93)  := iv_param93;
    g_in_arg_info_tab(94)  := iv_param94;
    g_in_arg_info_tab(95)  := iv_param95;
    g_in_arg_info_tab(96)  := iv_param96;
    g_in_arg_info_tab(97)  := iv_param97;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_exe_appl_short_name   =>  iv_exe_appl_short_name    -- �N���ΏۃA�v���P�[�V�����Z�k��
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name    -- �N���ΏۃR���J�����g�Z�k��
      ,ov_errbuf               =>  lv_errbuf
      ,ov_retcode              =>  lv_retcode
      ,ov_errmsg               =>  lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    END IF;
--
    -- ===============================
    -- �e�R���J�����g���擾����(A-2)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      get_parent_conc_info(
        iv_exe_appl_short_name   =>  iv_exe_appl_short_name    -- �N���ΏۃA�v���P�[�V�����Z�k��
        ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name    -- �N���ΏۃR���J�����g�Z�k��
        ,on_parent_param_cnt     =>  ln_parent_param_cnt       -- �e�R���J�����g�p�����[�^��
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(�G���[����)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- �e�R���J�����g�N������(A-3)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      exe_parent_conc(
        iv_exe_appl_short_name  =>  iv_exe_appl_short_name           -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
        ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name          -- 2.�N���ΏۃA�v���P�[�V�����Z�k��
        ,in_parent_param_cnt     =>  ln_parent_param_cnt             -- 3.�e�R���J�����g�p�����[�^��
        ,on_request_id           =>  lt_parent_request_id            -- 4.�e�R���J�����g�v��ID
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(�G���[����)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000); 
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- �q�R���J�����g�I���҂�����(A-4)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      wait_for_child_conc(
        in_request_id            =>  lt_parent_request_id  -- �e�R���J�����g�v��ID
        ,iv_child_conc_time      =>  iv_child_conc_time    -- �q�R���J�����g�X�e�[�^�X�Ď��Ԋu
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(�G���[����)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    end_conc(
      iv_retcode               =>  lv_retcode
      ,iv_exe_appl_short_name  =>  iv_exe_appl_short_name
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name
      ,iv_child_conc_time      =>  iv_child_conc_time
      ,in_parent_param_cnt     =>  ln_parent_param_cnt
      ,ov_errbuf               =>  lv_errbuf
      ,ov_retcode              =>  lv_retcode
      ,ov_errmsg               =>  lv_errmsg
    );
--
    ov_retcode := lv_retcode;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.�N���ΏۃR���J�����g�Z�k��
    iv_child_conc_time      IN   VARCHAR2,            -- 3.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
    iv_param1               IN   VARCHAR2  DEFAULT NULL,            -- 4.����1
    iv_param2               IN   VARCHAR2  DEFAULT NULL,            -- 5.����2
    iv_param3               IN   VARCHAR2  DEFAULT NULL,            -- 6.����3
    iv_param4               IN   VARCHAR2  DEFAULT NULL,            -- 7.����4
    iv_param5               IN   VARCHAR2  DEFAULT NULL,            -- 8.����5
    iv_param6               IN   VARCHAR2  DEFAULT NULL,            -- 9.����6
    iv_param7               IN   VARCHAR2  DEFAULT NULL,            -- 10.����7
    iv_param8               IN   VARCHAR2  DEFAULT NULL,            -- 11.����8
    iv_param9               IN   VARCHAR2  DEFAULT NULL,            -- 12.����9
    iv_param10              IN   VARCHAR2  DEFAULT NULL,            -- 13.����10
    iv_param11              IN   VARCHAR2  DEFAULT NULL,            -- 14.����11
    iv_param12              IN   VARCHAR2  DEFAULT NULL,            -- 15.����12
    iv_param13              IN   VARCHAR2  DEFAULT NULL,            -- 16.����13
    iv_param14              IN   VARCHAR2  DEFAULT NULL,            -- 17.����14
    iv_param15              IN   VARCHAR2  DEFAULT NULL,            -- 18.����15
    iv_param16              IN   VARCHAR2  DEFAULT NULL,            -- 19.����16
    iv_param17              IN   VARCHAR2  DEFAULT NULL,            -- 20.����17
    iv_param18              IN   VARCHAR2  DEFAULT NULL,            -- 21.����18
    iv_param19              IN   VARCHAR2  DEFAULT NULL,            -- 22.����19
    iv_param20              IN   VARCHAR2  DEFAULT NULL,            -- 23.����20
    iv_param21              IN   VARCHAR2  DEFAULT NULL,            -- 24.����21
    iv_param22              IN   VARCHAR2  DEFAULT NULL,            -- 25.����22
    iv_param23              IN   VARCHAR2  DEFAULT NULL,            -- 26.����23
    iv_param24              IN   VARCHAR2  DEFAULT NULL,            -- 27.����24
    iv_param25              IN   VARCHAR2  DEFAULT NULL,            -- 28.����25
    iv_param26              IN   VARCHAR2  DEFAULT NULL,            -- 29.����26
    iv_param27              IN   VARCHAR2  DEFAULT NULL,            -- 30.����27
    iv_param28              IN   VARCHAR2  DEFAULT NULL,            -- 31.����28
    iv_param29              IN   VARCHAR2  DEFAULT NULL,            -- 32.����29
    iv_param30              IN   VARCHAR2  DEFAULT NULL,            -- 33.����30
    iv_param31              IN   VARCHAR2  DEFAULT NULL,            -- 34.����31
    iv_param32              IN   VARCHAR2  DEFAULT NULL,            -- 35.����32
    iv_param33              IN   VARCHAR2  DEFAULT NULL,            -- 36.����33
    iv_param34              IN   VARCHAR2  DEFAULT NULL,            -- 37.����34
    iv_param35              IN   VARCHAR2  DEFAULT NULL,            -- 38.����35
    iv_param36              IN   VARCHAR2  DEFAULT NULL,            -- 39.����36
    iv_param37              IN   VARCHAR2  DEFAULT NULL,            -- 40.����37
    iv_param38              IN   VARCHAR2  DEFAULT NULL,            -- 41.����38
    iv_param39              IN   VARCHAR2  DEFAULT NULL,            -- 42.����39
    iv_param40              IN   VARCHAR2  DEFAULT NULL,            -- 43.����40
    iv_param41              IN   VARCHAR2  DEFAULT NULL,            -- 44.����41
    iv_param42              IN   VARCHAR2  DEFAULT NULL,            -- 45.����42
    iv_param43              IN   VARCHAR2  DEFAULT NULL,            -- 46.����43
    iv_param44              IN   VARCHAR2  DEFAULT NULL,            -- 47.����44
    iv_param45              IN   VARCHAR2  DEFAULT NULL,            -- 48.����45
    iv_param46              IN   VARCHAR2  DEFAULT NULL,            -- 49.����46
    iv_param47              IN   VARCHAR2  DEFAULT NULL,            -- 50.����47
    iv_param48              IN   VARCHAR2  DEFAULT NULL,            -- 51.����48
    iv_param49              IN   VARCHAR2  DEFAULT NULL,            -- 52.����49
    iv_param50              IN   VARCHAR2  DEFAULT NULL,            -- 53.����50
    iv_param51              IN   VARCHAR2  DEFAULT NULL,            -- 54.����51
    iv_param52              IN   VARCHAR2  DEFAULT NULL,            -- 55.����52
    iv_param53              IN   VARCHAR2  DEFAULT NULL,            -- 56.����53
    iv_param54              IN   VARCHAR2  DEFAULT NULL,            -- 57.����54
    iv_param55              IN   VARCHAR2  DEFAULT NULL,            -- 58.����55
    iv_param56              IN   VARCHAR2  DEFAULT NULL,            -- 59.����56
    iv_param57              IN   VARCHAR2  DEFAULT NULL,            -- 60.����57
    iv_param58              IN   VARCHAR2  DEFAULT NULL,            -- 61.����58
    iv_param59              IN   VARCHAR2  DEFAULT NULL,            -- 62.����59
    iv_param60              IN   VARCHAR2  DEFAULT NULL,            -- 63.����60
    iv_param61              IN   VARCHAR2  DEFAULT NULL,            -- 64.����61
    iv_param62              IN   VARCHAR2  DEFAULT NULL,            -- 65.����62
    iv_param63              IN   VARCHAR2  DEFAULT NULL,            -- 66.����63
    iv_param64              IN   VARCHAR2  DEFAULT NULL,            -- 67.����64
    iv_param65              IN   VARCHAR2  DEFAULT NULL,            -- 68.����65
    iv_param66              IN   VARCHAR2  DEFAULT NULL,            -- 69.����66
    iv_param67              IN   VARCHAR2  DEFAULT NULL,            -- 70.����67
    iv_param68              IN   VARCHAR2  DEFAULT NULL,            -- 71.����68
    iv_param69              IN   VARCHAR2  DEFAULT NULL,            -- 72.����69
    iv_param70              IN   VARCHAR2  DEFAULT NULL,            -- 73.����70
    iv_param71              IN   VARCHAR2  DEFAULT NULL,            -- 74.����71
    iv_param72              IN   VARCHAR2  DEFAULT NULL,            -- 75.����72
    iv_param73              IN   VARCHAR2  DEFAULT NULL,            -- 76.����73
    iv_param74              IN   VARCHAR2  DEFAULT NULL,            -- 77.����74
    iv_param75              IN   VARCHAR2  DEFAULT NULL,            -- 78.����75
    iv_param76              IN   VARCHAR2  DEFAULT NULL,            -- 79.����76
    iv_param77              IN   VARCHAR2  DEFAULT NULL,            -- 80.����77
    iv_param78              IN   VARCHAR2  DEFAULT NULL,            -- 81.����78
    iv_param79              IN   VARCHAR2  DEFAULT NULL,            -- 82.����79
    iv_param80              IN   VARCHAR2  DEFAULT NULL,            -- 83.����80
    iv_param81              IN   VARCHAR2  DEFAULT NULL,            -- 84.����81
    iv_param82              IN   VARCHAR2  DEFAULT NULL,            -- 85.����82
    iv_param83              IN   VARCHAR2  DEFAULT NULL,            -- 86.����83
    iv_param84              IN   VARCHAR2  DEFAULT NULL,            -- 87.����84
    iv_param85              IN   VARCHAR2  DEFAULT NULL,            -- 88.����85
    iv_param86              IN   VARCHAR2  DEFAULT NULL,            -- 89.����86
    iv_param87              IN   VARCHAR2  DEFAULT NULL,            -- 90.����87
    iv_param88              IN   VARCHAR2  DEFAULT NULL,            -- 91.����88
    iv_param89              IN   VARCHAR2  DEFAULT NULL,            -- 92.����89
    iv_param90              IN   VARCHAR2  DEFAULT NULL,            -- 93.����90
    iv_param91              IN   VARCHAR2  DEFAULT NULL,            -- 94.����91
    iv_param92              IN   VARCHAR2  DEFAULT NULL,            -- 95.����92
    iv_param93              IN   VARCHAR2  DEFAULT NULL,            -- 96.����93
    iv_param94              IN   VARCHAR2  DEFAULT NULL,            -- 97.����94
    iv_param95              IN   VARCHAR2  DEFAULT NULL,            -- 98.����95
    iv_param96              IN   VARCHAR2  DEFAULT NULL,            -- 99.����96
    iv_param97              IN   VARCHAR2  DEFAULT NULL             -- 100.����97
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
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- �G���[�I�����b�Z�[�W
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
      iv_exe_appl_short_name   =>  iv_exe_appl_short_name          -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name          -- 2.�N���ΏۃA�v���P�[�V�����Z�k��
      ,iv_child_conc_time      =>  iv_child_conc_time              -- 3.�q�R���J�����g�X�e�[�^�X�Ď��Ԋu
      ,iv_param1               =>  iv_param1                       -- 4.����1
      ,iv_param2               =>  iv_param2                       -- 5.����2
      ,iv_param3               =>  iv_param3                       -- 6.����3
      ,iv_param4               =>  iv_param4                       -- 7.����4
      ,iv_param5               =>  iv_param5                       -- 8.����5
      ,iv_param6               =>  iv_param6                       -- 9.����6
      ,iv_param7               =>  iv_param7                       -- 10.����7
      ,iv_param8               =>  iv_param8                       -- 11.����8
      ,iv_param9               =>  iv_param9                       -- 12.����9
      ,iv_param10              =>  iv_param10                      -- 13.����10
      ,iv_param11              =>  iv_param11                      -- 14.����11
      ,iv_param12              =>  iv_param12                      -- 15.����12
      ,iv_param13              =>  iv_param13                      -- 16.����13
      ,iv_param14              =>  iv_param14                      -- 17.����14
      ,iv_param15              =>  iv_param15                      -- 18.����15
      ,iv_param16              =>  iv_param16                      -- 19.����16
      ,iv_param17              =>  iv_param17                      -- 20.����17
      ,iv_param18              =>  iv_param18                      -- 21.����18
      ,iv_param19              =>  iv_param19                      -- 22.����19
      ,iv_param20              =>  iv_param20                      -- 23.����20
      ,iv_param21              =>  iv_param21                      -- 24.����21
      ,iv_param22              =>  iv_param22                      -- 25.����22
      ,iv_param23              =>  iv_param23                      -- 26.����23
      ,iv_param24              =>  iv_param24                      -- 27.����24
      ,iv_param25              =>  iv_param25                      -- 28.����25
      ,iv_param26              =>  iv_param26                      -- 29.����26
      ,iv_param27              =>  iv_param27                      -- 30.����27
      ,iv_param28              =>  iv_param28                      -- 31.����28
      ,iv_param29              =>  iv_param29                      -- 32.����29
      ,iv_param30              =>  iv_param30                      -- 33.����30
      ,iv_param31              =>  iv_param31                      -- 34.����31
      ,iv_param32              =>  iv_param32                      -- 35.����32
      ,iv_param33              =>  iv_param33                      -- 36.����33
      ,iv_param34              =>  iv_param34                      -- 37.����34
      ,iv_param35              =>  iv_param35                      -- 38.����35
      ,iv_param36              =>  iv_param36                      -- 39.����36
      ,iv_param37              =>  iv_param37                      -- 40.����37
      ,iv_param38              =>  iv_param38                      -- 41.����38
      ,iv_param39              =>  iv_param39                      -- 42.����39
      ,iv_param40              =>  iv_param40                      -- 43.����40
      ,iv_param41              =>  iv_param41                      -- 44.����41
      ,iv_param42              =>  iv_param42                      -- 45.����42
      ,iv_param43              =>  iv_param43                      -- 46.����43
      ,iv_param44              =>  iv_param44                      -- 47.����44
      ,iv_param45              =>  iv_param45                      -- 48.����45
      ,iv_param46              =>  iv_param46                      -- 49.����46
      ,iv_param47              =>  iv_param47                      -- 50.����47
      ,iv_param48              =>  iv_param48                      -- 51.����48
      ,iv_param49              =>  iv_param49                      -- 52.����49
      ,iv_param50              =>  iv_param50                      -- 53.����50
      ,iv_param51              =>  iv_param51                      -- 54.����51
      ,iv_param52              =>  iv_param52                      -- 55.����52
      ,iv_param53              =>  iv_param53                      -- 56.����53
      ,iv_param54              =>  iv_param54                      -- 57.����54
      ,iv_param55              =>  iv_param55                      -- 58.����55
      ,iv_param56              =>  iv_param56                      -- 59.����56
      ,iv_param57              =>  iv_param57                      -- 60.����57
      ,iv_param58              =>  iv_param58                      -- 61.����58
      ,iv_param59              =>  iv_param59                      -- 62.����59
      ,iv_param60              =>  iv_param60                      -- 63.����60
      ,iv_param61              =>  iv_param61                      -- 64.����61
      ,iv_param62              =>  iv_param62                      -- 65.����62
      ,iv_param63              =>  iv_param63                      -- 66.����63
      ,iv_param64              =>  iv_param64                      -- 67.����64
      ,iv_param65              =>  iv_param65                      -- 68.����65
      ,iv_param66              =>  iv_param66                      -- 69.����66
      ,iv_param67              =>  iv_param67                      -- 70.����67
      ,iv_param68              =>  iv_param68                      -- 71.����68
      ,iv_param69              =>  iv_param69                      -- 72.����69
      ,iv_param70              =>  iv_param70                      -- 73.����70
      ,iv_param71              =>  iv_param71                      -- 74.����71
      ,iv_param72              =>  iv_param72                      -- 75.����72
      ,iv_param73              =>  iv_param73                      -- 76.����73
      ,iv_param74              =>  iv_param74                      -- 77.����74
      ,iv_param75              =>  iv_param75                      -- 78.����75
      ,iv_param76              =>  iv_param76                      -- 79.����76
      ,iv_param77              =>  iv_param77                      -- 80.����77
      ,iv_param78              =>  iv_param78                      -- 81.����78
      ,iv_param79              =>  iv_param79                      -- 82.����79
      ,iv_param80              =>  iv_param80                      -- 83.����80
      ,iv_param81              =>  iv_param81                      -- 84.����81
      ,iv_param82              =>  iv_param82                      -- 85.����82
      ,iv_param83              =>  iv_param83                      -- 86.����83
      ,iv_param84              =>  iv_param84                      -- 87.����84
      ,iv_param85              =>  iv_param85                      -- 88.����85
      ,iv_param86              =>  iv_param86                      -- 89.����86
      ,iv_param87              =>  iv_param87                      -- 90.����87
      ,iv_param88              =>  iv_param88                      -- 91.����88
      ,iv_param89              =>  iv_param89                      -- 92.����89
      ,iv_param90              =>  iv_param90                      -- 93.����90
      ,iv_param91              =>  iv_param91                      -- 94.����91
      ,iv_param92              =>  iv_param92                      -- 95.����92
      ,iv_param93              =>  iv_param93                      -- 96.����93
      ,iv_param94              =>  iv_param94                      -- 97.����94
      ,iv_param95              =>  iv_param95                      -- 98.����95
      ,iv_param96              =>  iv_param96                      -- 99.����96
      ,iv_param97              =>  iv_param97                      -- 100.����97
      ,ov_errbuf               =>  lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode              =>  lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg               =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCCP006A01C;
/
