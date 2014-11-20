CREATE OR REPLACE PACKAGE BODY XXCFF003A33C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A33C(body)
 * Description      : ���[�X�����R�[�h����
 * MD.050           : MD050_CFF_003_A33_���[�X�����R�[�h����
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  init                       �������� (A-1)
 *  select_object_headers      ���[�X�����e�[�u���擾���� (A-2)
 *  check_contract_condition   �_��󋵃`�F�b�N (A-3)
 *  validate_record            �������`�F�b�N (A-4)
 *  update_contract_lines      ���[�X�_�񖾍׃e�[�u���X�V���� (A-5)
 *  update_object_headers      ���[�X�����e�[�u���X�V���� (A-6)
 *  insert_contract_histories  ���[�X�_�񖾍ח����e�[�u���o�^���� (A-7)
 *  insert_object_histories    ���[�X���������e�[�u���o�^���� (A-8)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-14    1.0   SCS ���q �G�K    �V�K�쐬
 *  2009-02-09    1.1   SCS ���q �G�K    [��QCFF_006] ���O�o�͐�s��Ή�
 *  2009-02-17    1.2   SCS ���q �G�K    [��QCFF_034] ����ݒ�l�s��Ή�
 *  2009-02-25    1.3   SCS ���q �G�K    [��QCFF_055] WHO�J�������ݒ�s��Ή�
 *  2013-07-17    1.4   SCSK ���� �O��   [E_�{�ғ�_10871] ����ő��őΉ�
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
  record_lock_expt    EXCEPTION;    -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(record_lock_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF003A33C';  -- �p�b�P�[�W��
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cff_00007    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';  -- ���b�N�G���[
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- ���ʊ֐����b�Z�[�W
  cv_msg_cff_00142    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00142';  -- �������`�F�b�N�G���[
  cv_msg_cff_00143    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00143';  -- �_��󋵃G���[
  cv_msg_cff_00182    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00182';  -- �����R�[�h�w��G���[
--
  -- �g�[�N��
  cv_tkn_cff_00007    CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- �e�[�u����
  cv_tkn_cff_00094    CONSTANT VARCHAR2(20) := 'FUNC_NAME';           -- �֐���
  cv_tkn_cff_00095    CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- �G���[���b�Z�[�W
  cv_tkn_cff_00142_01 CONSTANT VARCHAR2(20) := 'OBJECT_CODE';         -- �����R�[�h
  cv_tkn_cff_00142_02 CONSTANT VARCHAR2(20) := 'O_LEASE_CLASS';       -- ��_���[�X���
  cv_tkn_cff_00142_03 CONSTANT VARCHAR2(20) := 'O_RE_LEASE_TIMES';    -- ��_�ă��[�X��
  cv_tkn_cff_00142_04 CONSTANT VARCHAR2(20) := 'O_LEASE_TYPE';        -- ��_���[�X�敪
  cv_tkn_cff_00142_05 CONSTANT VARCHAR2(20) := 'CONTRACT_NUMBER';     -- �_��ԍ�
  cv_tkn_cff_00142_06 CONSTANT VARCHAR2(20) := 'CONTRACT_LINE_NUM ';  -- �_��}��
  cv_tkn_cff_00142_07 CONSTANT VARCHAR2(20) := 'C_LEASE_CLASS';       -- �__���[�X���
  cv_tkn_cff_00142_08 CONSTANT VARCHAR2(20) := 'C_RE_LEASE_TIMES';    -- �__�ă��[�X��
  cv_tkn_cff_00142_09 CONSTANT VARCHAR2(20) := 'C_LEASE_TYPE';        -- �__���[�X�敪
--
  -- �g�[�N���l
  cv_msg_cff_50014    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50014';  -- ���[�X�����e�[�u��
  cv_msg_cff_50030    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50030';  -- ���[�X�_�񖾍׃e�[�u��
  cv_msg_cff_50130    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- ��������
--
  -- ���[�X�敪
  cv_lease_type_orgn  CONSTANT VARCHAR2(1)  := '1';     -- ���_��
  cv_lease_type_re    CONSTANT VARCHAR2(1)  := '2';     -- �ă��[�X
--
  -- �����X�e�[�^�X
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';  -- ���_��
  cv_obj_status_102   CONSTANT VARCHAR2(3)   := '102';  -- �_���
  cv_obj_status_103   CONSTANT VARCHAR2(3)   := '103';  -- �ă��[�X��
  cv_obj_status_104   CONSTANT VARCHAR2(3)   := '104';  -- �ă��[�X�_���
--
  -- �����_��X�e�[�^�X
  cv_cont_status_209  CONSTANT VARCHAR2(3)   := '209';  -- ���ύX
--
  -- ��vIF�t���O
  cv_if_flag_one      CONSTANT VARCHAR2(1)   := '1';    -- �����M
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    -- ���[�X�����e�[�u���擾�Ώۃf�[�^���R�[�h�^
    TYPE g_object_headers_rtype IS RECORD(
      object_code        xxcff_object_headers.object_code%TYPE,        -- �����R�[�h
      object_header_id   xxcff_object_headers.object_header_id%TYPE,   -- ��������ID
      contract_number    xxcff_contract_headers.contract_number%TYPE,  -- �_��ԍ�
      contract_line_num  xxcff_contract_lines.contract_line_num%TYPE,  -- �_��}��
      contract_line_id   xxcff_contract_lines.contract_line_id%TYPE,   -- �_�񖾍ד���ID
      xch_lease_class    xxcff_contract_headers.lease_class%TYPE,      -- �__���[�X���
      xch_lease_type     xxcff_contract_headers.lease_type%TYPE,       -- �__���[�X�敪
      xch_re_lease_times xxcff_contract_headers.re_lease_times%TYPE,   -- �__�ă��[�X��
      xoh_lease_class    xxcff_object_headers.lease_class%TYPE,        -- ��_���[�X���
      xoh_lease_type     xxcff_object_headers.lease_type%TYPE,         -- ��_���[�X�敪
      xoh_re_lease_times xxcff_object_headers.re_lease_times%TYPE      -- ��_�ă��[�X��
    );
--
  -- ���[�X�����e�[�u���擾�Ώۃf�[�^���R�[�h�z��
  TYPE g_object_headers_ttype IS TABLE OF g_object_headers_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_init_rec           xxcff_common1_pkg.init_rtype;  -- �����������
  g_object_headers_tab  g_object_headers_ttype;        -- ���[�X�����e�[�u���擾�Ώۃf�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
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
    lv_which_out VARCHAR2(10) := 'OUTPUT';
    lv_which_log VARCHAR2(10) := 'LOG';
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
    -- �R���J�����g�p�����[�^�̒l��\�����郁�b�Z�[�W�̃��O�o��
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_out,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_log,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���ʊ֐�(��������)�Ăяo��
    xxcff_common1_pkg.init(
      or_init_rec => gr_init_rec,  -- �����������
      ov_retcode  => lv_retcode,   -- ���^�[���R�[�h
      ov_errbuf   => lv_errbuf,    -- �G���[���b�Z�[�W
      ov_errmsg   => lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00094,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00094,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50130   -- �g�[�N���l1
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00095,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00095,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg          -- �g�[�N���l1
                   );
      lv_errmsg := lv_errbuf || lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : select_object_headers
   * Description      : ���[�X�����e�[�u���擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE select_object_headers(
    iv_obj_code1  IN  VARCHAR2,     --   1.�����R�[�h1
    iv_obj_code2  IN  VARCHAR2,     --   2.�����R�[�h2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_object_headers'; -- �v���O������
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
    -- ���[�X�����e�[�u���擾�J�[�\��
    CURSOR get_object_headers_cur
    IS
      SELECT obj.object_code object_code,               -- �����R�[�h
             obj.object_header_id object_header_id,     -- ��������ID
             cont.contract_number contract_number,      -- �_��ԍ�
             cont.contract_line_num contract_line_num,  -- �_��}��
             cont.contract_line_id contract_line_id,    -- �_�񖾍ד���ID
             cont.lease_class xch_lease_class,          -- �__���[�X���
             cont.lease_type xch_lease_type,            -- �__���[�X�敪
             cont.re_lease_times xch_re_lease_times,    -- �__�ă��[�X��
             obj.lease_class xoh_lease_class,           -- ��_���[�X���
             obj.lease_type xoh_lease_type,             -- ��_���[�X�敪
             obj.re_lease_times xoh_re_lease_times      -- ��_�ă��[�X��
      FROM   (SELECT xoh.object_code object_code,              -- �����R�[�h
                     xoh.object_header_id object_header_id,    -- ��������ID
                     xoh.lease_class lease_class,              -- ��_���[�X���
                     xoh.lease_type lease_type,                -- ��_���[�X�敪
                     xoh.re_lease_times re_lease_times         -- ��_�ă��[�X��
              FROM   xxcff_object_headers   xoh   -- ���[�X����
              WHERE  xoh.object_code IN(iv_obj_code1, iv_obj_code2)) obj,
             (SELECT xch.contract_number contract_number,      -- �_��ԍ�
                     xcl.contract_line_num contract_line_num,  -- �_��}��
                     xcl.contract_line_id contract_line_id,    -- �_�񖾍ד���ID
                     xcl.object_header_id object_header_id,    -- ��������ID
                     xch.lease_class lease_class,              -- �__���[�X���
                     xch.lease_type lease_type,                -- �__���[�X�敪
                     xch.re_lease_times re_lease_times         -- �__�ă��[�X��
              FROM   xxcff_contract_headers xch,  -- ���[�X�_��
                     xxcff_contract_lines   xcl   -- ���[�X�_�񖾍�
              WHERE  xch.contract_header_id = xcl.contract_header_id) cont
      WHERE  obj.object_header_id = cont.object_header_id(+)
        AND  obj.re_lease_times   = cont.re_lease_times(+);
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
    -- ���[�X�����e�[�u���擾
    OPEN  get_object_headers_cur;
    FETCH get_object_headers_cur BULK COLLECT INTO g_object_headers_tab;
    CLOSE get_object_headers_cur;
--
    -- �����R�[�h�`�F�b�N
    -- �擾������2����菬����(���ꕨ���R�[�h���w�肳�ꂽ)�ꍇ�A�G���[
    IF (g_object_headers_tab.COUNT < 2) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_cff_00182  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
      IF (get_object_headers_cur%ISOPEN) THEN
        CLOSE get_object_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END select_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : check_contract_condition
   * Description      : �_��󋵃`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE check_contract_condition(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_contract_condition'; -- �v���O������
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
    -- �_��ԍ��������Ώۂ�2���Ƃ�NULL�̏ꍇ�A�G���[
    IF (  (g_object_headers_tab(1).contract_number IS NULL)
      AND (g_object_headers_tab(2).contract_number IS NULL)  )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_cff_00143  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END check_contract_condition;
--
  /**********************************************************************************
   * Procedure Name   : validate_record
   * Description      : �������`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE validate_record(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_record'; -- �v���O������
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
    ln_i2               INTEGER;        -- ��������R�[�h�̃C���f�b�N�X
    lv_object_code      VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�����R�[�h
    lv_o_lease_class    VARCHAR2(240);  -- ���b�Z�[�W�o�͗p��_���[�X���
    lv_o_re_lease_times VARCHAR2(240);  -- ���b�Z�[�W�o�͗p��_�ă��[�X��
    lv_o_lease_type     VARCHAR2(240);  -- ���b�Z�[�W�o�͗p��_���[�X�敪
    lv_cont_number      VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�_��ԍ�
    lv_cont_line_num    VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�_��}��
    lv_c_lease_class    VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�__���[�X���
    lv_c_re_lease_times VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�__�ă��[�X��
    lv_c_lease_type     VARCHAR2(240);  -- ���b�Z�[�W�o�͗p�__���[�X�敪
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�X��ʖ��̎擾�J�[�\��
    CURSOR get_lease_cls_name_cur(
      iv_lease_cls_code VARCHAR2)
    IS
      SELECT xlcv.lease_class_name lease_class_name  -- ���[�X�敪����
      FROM   xxcff_lease_class_v xlcv
      WHERE  xlcv.lease_class_code = iv_lease_cls_code;
--
    -- ���[�X�敪���̎擾�J�[�\��
    CURSOR get_lease_type_name_cur(
      iv_lease_type_code VARCHAR2)
    IS
      SELECT xltv.lease_type_name lease_type_name  -- ���[�X��ʖ���
      FROM   xxcff_lease_type_v xltv
      WHERE  xltv.lease_type_code = iv_lease_type_code;
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
    -- 2�̃��R�[�h�ɑ΂��鐮�����`�F�b�N
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- ��������R�[�h�̃C���f�b�N�X���Z�o
      ln_i2 := ABS(i-3);
--
      -- �_�񖾍ד���ID��NULL�łȂ��ꍇ�A���[�X�����ƃ��[�X�_��̐������`�F�b�N���s��
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        -- �_��̃��[�X��ʁE�ă��[�X�񐔁E���[�X�敪�ƁA
        -- ������̕����̃��[�X��ʁE�ă��[�X�񐔁E���[�X�敪���������Ȃ��ꍇ�A�G���[
        IF ( (g_object_headers_tab(i).xch_lease_class    != g_object_headers_tab(ln_i2).xoh_lease_class)
          OR (g_object_headers_tab(i).xch_re_lease_times != g_object_headers_tab(ln_i2).xoh_re_lease_times)
          OR (g_object_headers_tab(i).xch_lease_type     != g_object_headers_tab(ln_i2).xoh_lease_type) )
        THEN
          -- ���b�Z�[�W�o�͗p�p�����[�^�̐ݒ�
          -- �����R�[�h
          lv_object_code      := g_object_headers_tab(ln_i2).object_code;
          -- ��_�ă��[�X��
          lv_o_re_lease_times := TO_CHAR(g_object_headers_tab(ln_i2).xoh_re_lease_times);
          -- �_��ԍ�
          lv_cont_number      := g_object_headers_tab(i).contract_number;
          -- �_��}��
          lv_cont_line_num    := TO_CHAR(g_object_headers_tab(i).contract_line_num);
          -- �__�ă��[�X��
          lv_c_re_lease_times := TO_CHAR(g_object_headers_tab(i).xch_re_lease_times);
          -- ��_���[�X���
          OPEN  get_lease_cls_name_cur(g_object_headers_tab(ln_i2).xoh_lease_class);
          FETCH get_lease_cls_name_cur INTO lv_o_lease_class;
          CLOSE get_lease_cls_name_cur;
          -- ��_���[�X�敪
          OPEN  get_lease_type_name_cur(g_object_headers_tab(ln_i2).xoh_lease_type);
          FETCH get_lease_type_name_cur INTO lv_o_lease_type;
          CLOSE get_lease_type_name_cur;
          -- �__���[�X���
          OPEN  get_lease_cls_name_cur(g_object_headers_tab(i).xch_lease_class);
          FETCH get_lease_cls_name_cur INTO lv_c_lease_class;
          CLOSE get_lease_cls_name_cur;
          -- �__���[�X�敪
          OPEN  get_lease_type_name_cur(g_object_headers_tab(i).xch_lease_type);
          FETCH get_lease_type_name_cur INTO lv_c_lease_type;
          CLOSE get_lease_type_name_cur;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_kbn_cff,         -- �A�v���P�[�V�����Z�k��
                         iv_name         => cv_msg_cff_00142,       -- ���b�Z�[�W�R�[�h
                         iv_token_name1  => cv_tkn_cff_00142_01,    -- �g�[�N���R�[�h1
                         iv_token_value1 => lv_object_code,         -- �g�[�N���l1
                         iv_token_name2  => cv_tkn_cff_00142_02,    -- �g�[�N���R�[�h2
                         iv_token_value2 => lv_o_lease_class,       -- �g�[�N���l2
                         iv_token_name3  => cv_tkn_cff_00142_03,    -- �g�[�N���R�[�h3
                         iv_token_value3 => lv_o_re_lease_times,    -- �g�[�N���l3
                         iv_token_name4  => cv_tkn_cff_00142_04,    -- �g�[�N���R�[�h4
                         iv_token_value4 => lv_o_lease_type,        -- �g�[�N���l4
                         iv_token_name5  => cv_tkn_cff_00142_05,    -- �g�[�N���R�[�h5
                         iv_token_value5 => lv_cont_number,         -- �g�[�N���l5
                         iv_token_name6  => cv_tkn_cff_00142_06,    -- �g�[�N���R�[�h6
                         iv_token_value6 => lv_cont_line_num,       -- �g�[�N���l6
                         iv_token_name7  => cv_tkn_cff_00142_07,    -- �g�[�N���R�[�h7
                         iv_token_value7 => lv_c_lease_class,       -- �g�[�N���l7
                         iv_token_name8  => cv_tkn_cff_00142_08,    -- �g�[�N���R�[�h8
                         iv_token_value8 => lv_c_re_lease_times,    -- �g�[�N���l8
                         iv_token_name9  => cv_tkn_cff_00142_09,    -- �g�[�N���R�[�h9
                         iv_token_value9 => lv_c_lease_type         -- �g�[�N���l9
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END validate_record;
--
  /**********************************************************************************
   * Procedure Name   : update_contract_lines
   * Description      : ���[�X�_�񖾍׃e�[�u���X�V���� (A-5)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_contract_lines'; -- �v���O������
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
    ln_i2  INTEGER;  -- ��������R�[�h�̃C���f�b�N�X
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�X�_�񖾍׃��R�[�h���b�N�J�[�\��
    CURSOR lock_row_cur(
      in_contract_line_id NUMBER)
    IS
      SELECT xcl.contract_line_id contract_line_id
      FROM   xxcff_contract_lines xcl
      WHERE  xcl.contract_line_id = in_contract_line_id
      FOR UPDATE NOWAIT;
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
    -- 2�̃��R�[�h�ɑ΂��郊�[�X�_�񖾍׃e�[�u���X�V
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- ��������R�[�h�̃C���f�b�N�X���Z�o
      ln_i2 := ABS(i-3);
--
      -- �_�񖾍ד���ID��NULL�łȂ��ꍇ�A���[�X�_�񖾍ׂ̍X�V���s��
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        BEGIN
          -- �X�V�Ώۃ��R�[�h�̃��b�N
          OPEN  lock_row_cur(g_object_headers_tab(i).contract_line_id);
          CLOSE lock_row_cur;
--
          -- ���[�X�_�񖾍ׂ̍X�V
          UPDATE xxcff_contract_lines
          SET    object_header_id       = g_object_headers_tab(ln_i2).object_header_id,
                 last_updated_by        = cn_last_updated_by,
                 last_update_date       = cd_last_update_date,
                 last_update_login      = cn_last_update_login,
                 request_id             = cn_request_id,
                 program_application_id = cn_program_application_id,
                 program_id             = cn_program_id,
                 program_update_date    = cd_program_update_date
          WHERE  contract_line_id = g_object_headers_tab(i).contract_line_id;
--
        EXCEPTION
          -- �X�V�Ώۃf�[�^�����b�N���̏ꍇ�A�G���[
          WHEN record_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                           iv_name         => cv_msg_cff_00007,  -- ���b�Z�[�W�R�[�h
                           iv_token_name1  => cv_tkn_cff_00007,  -- �g�[�N���R�[�h1
                           iv_token_value1 => cv_msg_cff_50030   -- �g�[�N���l1
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : update_object_headers
   * Description      : ���[�X�����e�[�u���X�V���� (A-6)
   ***********************************************************************************/
  PROCEDURE update_object_headers(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_object_headers'; -- �v���O������
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
      lv_object_status VARCHAR2(3);  -- �X�V�p�����X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�X�������R�[�h���b�N�J�[�\��
    CURSOR lock_row_cur(
      in_object_header_id NUMBER)
    IS
      SELECT xoh.object_header_id object_header_id
      FROM   xxcff_object_headers xoh
      WHERE  xoh.object_header_id = in_object_header_id
      FOR UPDATE NOWAIT;
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
    -- 2�̃��R�[�h�ɑ΂��郊�[�X�����e�[�u���X�V
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- �����X�e�[�^�X�̎擾
      -- ���[�X�敪��'1'(���_��)�̏ꍇ
      IF (g_object_headers_tab(i).xoh_lease_type = cv_lease_type_orgn) THEN
        -- �_�񖾍ד���ID��NULL�̏ꍇ�A�����X�e�[�^�X��'102'(�_���)�Ƃ���
        IF (g_object_headers_tab(i).contract_line_id IS NULL) THEN
          lv_object_status := cv_obj_status_102;
        -- �_�񖾍ד���ID��NOT NULL�̏ꍇ�A�����X�e�[�^�X��'101'(���_��)�Ƃ���
        ELSE
          lv_object_status := cv_obj_status_101;
        END IF;
      -- ���[�X�敪��'2'(�ă��[�X)�̏ꍇ
      ELSE
        -- �_�񖾍ד���ID��NULL�̏ꍇ�A�����X�e�[�^�X��'104'(�ă��[�X�_���)�Ƃ���
        IF (g_object_headers_tab(i).contract_line_id IS NULL) THEN
          lv_object_status := cv_obj_status_104;
        -- �_�񖾍ד���ID��NOT NULL�̏ꍇ�A�����X�e�[�^�X��'103'(�ă��[�X��)�Ƃ���
        ELSE
          lv_object_status := cv_obj_status_103;
        END IF;
      END IF;
--
      BEGIN
        -- �X�V�Ώۃ��R�[�h�̃��b�N
        OPEN  lock_row_cur(g_object_headers_tab(i).object_header_id);
        CLOSE lock_row_cur;
--
        -- ���[�X�����̍X�V
        UPDATE xxcff_object_headers
        SET    object_status          = lv_object_status,
               last_updated_by        = cn_last_updated_by,
               last_update_date       = cd_last_update_date,
               last_update_login      = cn_last_update_login,
               request_id             = cn_request_id,
               program_application_id = cn_program_application_id,
               program_id             = cn_program_id,
               program_update_date    = cd_program_update_date
        WHERE  object_header_id = g_object_headers_tab(i).object_header_id;
--
      EXCEPTION
        -- �X�V�Ώۃf�[�^�����b�N���̏ꍇ�A�G���[
        WHEN record_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                         iv_name         => cv_msg_cff_00007,  -- ���b�Z�[�W�R�[�h
                         iv_token_name1  => cv_tkn_cff_00007,  -- �g�[�N���R�[�h1
                         iv_token_value1 => cv_msg_cff_50014   -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : ���[�X�_�񖾍ח����e�[�u���o�^���� (A-7)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_contract_histories'; -- �v���O������
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
    -- 2�̃��R�[�h�ɑ΂��郊�[�X�_�񖾍ח����e�[�u���o�^
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- �_�񖾍ד���ID��NULL�łȂ��ꍇ�A���[�X�_�񖾍ח����̓o�^���s��
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        INSERT INTO xxcff_contract_histories(
          contract_line_id,                          -- �_�񖾍ד���ID
          contract_header_id,                        -- �_�����ID
          history_num,                               -- �ύX����NO
          contract_status,                           -- �_��X�e�[�^�X
          first_charge,                              -- ���񌎊z���[�X��_���[�X��
          first_tax_charge,                          -- �������Ŋz_���[�X��
          first_total_charge,                        -- ����v_���[�X��
          second_charge,                             -- 2��ڈȍ~���z���[�X��_���[�X��
          second_tax_charge,                         -- 2��ڈȍ~����Ŋz_���[�X��
          second_total_charge,                       -- 2��ڈȍ~�v_���[�X��
          first_deduction,                           -- ���񌎊z���[�X��_�T���z
          first_tax_deduction,                       -- ���񌎊z����Ŋz_�T���z
          first_total_deduction,                     -- ����v_�T���z
          second_deduction,                          -- 2��ڈȍ~���z���[�X��_�T���z
          second_tax_deduction,                      -- 2��ڈȍ~����Ŋz_�T���z
          second_total_deduction,                    -- 2��ڈȍ~�v_�T���z
          gross_charge,                              -- ���z���[�X��_���[�X��
          gross_tax_charge,                          -- ���z�����_���[�X��
          gross_total_charge,                        -- ���z�v_���[�X��
          gross_deduction,                           -- ���z���[�X��_�T���z
          gross_tax_deduction,                       -- ���z�����_�T���z
          gross_total_deduction,                     -- ���z�v_�T���z
          lease_kind,                                -- ���[�X���
          estimated_cash_price,                      -- ���ό����w�����z
          present_value_discount_rate,               -- ���݉��l������
          present_value,                             -- ���݉��l
          life_in_months,                            -- �@��ϗp�N��
          original_cost,                             -- �擾���z
          calc_interested_rate,                      -- �v�Z���q��
          object_header_id,                          -- ��������ID
          asset_category,                            -- ���Y���
          expiration_date,                           -- ������
          cancellation_date,                         -- ���r����
          vd_if_date,                                -- ���[�X�_����A�g��
          info_sys_if_date,                          -- ���[�X�Ǘ����A�g��
          first_installation_address,                -- ����ݒu�ꏊ
          first_installation_place,                  -- ����ݒu��
-- 2013/07/17 Ver.1.4 T.Nakano ADD Start
          tax_code,                                  -- �ŋ��R�[�h
-- 2013/07/17 Ver.1.4 T.Nakano ADD END
          accounting_date,                           -- �v���
          accounting_if_flag,                        -- ��v�h�e�t���O
          description,                               -- �E�v
          created_by,                                -- �쐬��
          creation_date,                             -- �쐬��
          last_updated_by,                           -- �ŏI�X�V��
          last_update_date,                          -- �ŏI�X�V��
          last_update_login,                         -- �ŏI�X�V۸޲�
          request_id,                                -- �v��ID
          program_application_id,                    -- �ݶ��ĥ��۸��ѥ���ع����ID
          program_id,                                -- �ݶ��ĥ��۸���ID
          program_update_date)                       -- ��۸��эX�V��
        SELECT xcl.contract_line_id,                 -- �_�񖾍ד���ID
               xcl.contract_header_id,               -- �_�����ID
               xxcff_contract_histories_s1.NEXTVAL,  -- �_�񖾍ח����V�[�P���X
               cv_cont_status_209,                   -- �_��X�e�[�^�X('209'(���ύX))
               xcl.first_charge,                     -- ���񌎊z���[�X��_���[�X��
               xcl.first_tax_charge,                 -- �������Ŋz_���[�X��
               xcl.first_total_charge,               -- ����v_���[�X��
               xcl.second_charge,                    -- 2��ڈȍ~���z���[�X��_���[�X��
               xcl.second_tax_charge,                -- 2��ڈȍ~����Ŋz_���[�X��
               xcl.second_total_charge,              -- 2��ڈȍ~�v_���[�X��
               xcl.first_deduction,                  -- ���񌎊z���[�X��_�T���z
               xcl.first_tax_deduction,              -- ���񌎊z����Ŋz_�T���z
               xcl.first_total_deduction,            -- ����v_�T���z
               xcl.second_deduction,                 -- 2��ڈȍ~���z���[�X��_�T���z
               xcl.second_tax_deduction,             -- 2��ڈȍ~����Ŋz_�T���z
               xcl.second_total_deduction,           -- 2��ڈȍ~�v_�T���z
               xcl.gross_charge,                     -- ���z���[�X��_���[�X��
               xcl.gross_tax_charge,                 -- ���z�����_���[�X��
               xcl.gross_total_charge,               -- ���z�v_���[�X��
               xcl.gross_deduction,                  -- ���z���[�X��_�T���z
               xcl.gross_tax_deduction,              -- ���z�����_�T���z
               xcl.gross_total_deduction,            -- ���z�v_�T���z
               xcl.lease_kind,                       -- ���[�X���
               xcl.estimated_cash_price,             -- ���ό����w�����z
               xcl.present_value_discount_rate,      -- ���݉��l������
               xcl.present_value,                    -- ���݉��l
               xcl.life_in_months,                   -- �@��ϗp�N��
               xcl.original_cost,                    -- �擾���z
               xcl.calc_interested_rate,             -- �v�Z���q��
               xcl.object_header_id,                 -- ��������ID
               xcl.asset_category,                   -- ���Y���
               xcl.expiration_date,                  -- ������
               xcl.cancellation_date,                -- ���r����
               xcl.vd_if_date,                       -- ���[�X�_����A�g��
               xcl.info_sys_if_date,                 -- ���[�X�Ǘ����A�g��
               xcl.first_installation_address,       -- ����ݒu�ꏊ
               xcl.first_installation_place,         -- ����ݒu��
-- 2013/07/17 Ver.1.4 T.Nakano ADD Start
               xcl.tax_code,                         -- �ŋ��R�[�h
-- 2013/07/17 Ver.1.4 T.Nakano ADD END
               gr_init_rec.process_date,             -- �v���(�Ɩ����t)
               cv_if_flag_one,                       -- ��vIF�t���O('1'(�����M))
               NULL,                                 -- �E�v(NULL)
               cn_created_by,                        -- �쐬��
               cd_creation_date,                     -- �쐬��
               cn_last_updated_by,                   -- �ŏI�X�V��
               cd_last_update_date,                  -- �ŏI�X�V��
               cn_last_update_login,                 -- �ŏI�X�V۸޲�
               cn_request_id,                        -- �v��ID
               cn_program_application_id,            -- �ݶ��ĥ��۸��ѥ���ع����ID
               cn_program_id,                        -- �ݶ��ĥ��۸���ID
               cd_program_update_date                -- ��۸��эX�V��
        FROM   xxcff_contract_lines xcl  -- �w���[�X�_�񖾍ׁx�e�[�u��
        WHERE  xcl.contract_line_id = g_object_headers_tab(i).contract_line_id;
      END IF;
    END LOOP record_loop;
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
  END insert_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : insert_object_histories
   * Description      : ���[�X���������e�[�u���o�^���� (A-8)
   ***********************************************************************************/
  PROCEDURE insert_object_histories(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_histories'; -- �v���O������
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
    -- 2�̃��R�[�h�ɑ΂��郊�[�X���������e�[�u���o�^
    <<record_loop>>
    FOR i IN 1..2 LOOP
      INSERT INTO xxcff_object_histories(
        object_header_id,                        -- ��������ID
        history_num,                             -- �ύX����NO
        object_code,                             -- �����R�[�h
        lease_class,                             -- ���[�X���
        lease_type,                              -- ���[�X�敪
        re_lease_times,                          -- �ă��[�X��
        po_number,                               -- �����ԍ�
        registration_number,                     -- �o�^�ԍ�
        age_type,                                -- �N��
        model,                                   -- �@��
        serial_number,                           -- �@��
        quantity,                                -- ����
        manufacturer_name,                       -- ���[�J�[��
        department_code,                         -- �Ǘ�����R�[�h
        owner_company,                           -- �{�Ё^�H��
        installation_address,                    -- ���ݒu�ꏊ
        installation_place ,                     -- ���ݒu��
        chassis_number,                          -- �ԑ�ԍ�
        re_lease_flag,                           -- �ă��[�X�v�t���O
        cancellation_type,                       -- ���敪
        cancellation_date,                       -- ���r����
        dissolution_date,                        -- ���r���L�����Z����
        bond_acceptance_flag,                    -- �؏���̃t���O
        bond_acceptance_date,                    -- �؏���̓�
        expiration_date,                         -- ������
        object_status,                           -- �����X�e�[�^�X
        active_flag,                             -- �����L���t���O
        info_sys_if_date,                        -- ���[�X�Ǘ����A�g��
        generation_date,                         -- ������
        accounting_date,                         -- �v���
        accounting_if_flag,                      -- ��v�h�e�t���O
        m_owner_company,                         -- �ړ����{�Ё^�H��
        m_department_code,                       -- �ړ����Ǘ�����
        m_installation_address,                  -- �ړ������ݒu�ꏊ
        m_installation_place ,                   -- �ړ������ݒu��
        m_registration_number,                   -- �ړ����o�^�ԍ�
        description,                             -- �E�v
        created_by,                              -- �쐬��
        creation_date,                           -- �쐬��
        last_updated_by,                         -- �ŏI�X�V��
        last_update_date,                        -- �ŏI�X�V��
        last_update_login,                       -- �ŏI�X�V۸޲�
        request_id,                              -- �v��ID
        program_application_id,                  -- �ݶ��ĥ��۸��ѥ���ع����ID
        program_id,                              -- �ݶ��ĥ��۸���ID
        program_update_date)                     -- ��۸��эX�V��
      SELECT xoh.object_header_id,               -- ��������ID
             xxcff_object_histories_s1.NEXTVAL,  -- ���������V�[�P���X
             xoh.object_code,                    -- �����R�[�h
             xoh.lease_class,                    -- ���[�X���
             xoh.lease_type,                     -- ���[�X�敪
             xoh.re_lease_times,                 -- �ă��[�X��
             xoh.po_number,                      -- �����ԍ�
             xoh.registration_number,            -- �o�^�ԍ�
             xoh.age_type,                       -- �N��
             xoh.model,                          -- �@��
             xoh.serial_number,                  -- �@��
             xoh.quantity,                       -- ����
             xoh.manufacturer_name,              -- ���[�J�[��
             xoh.department_code,                -- �Ǘ�����R�[�h
             xoh.owner_company,                  -- �{�Ё^�H��
             xoh.installation_address,           -- ���ݒu�ꏊ
             xoh.installation_place ,            -- ���ݒu��
             xoh.chassis_number,                 -- �ԑ�ԍ�
             xoh.re_lease_flag,                  -- �ă��[�X�v�t���O
             xoh.cancellation_type,              -- ���敪
             xoh.cancellation_date,              -- ���r����
             xoh.dissolution_date,               -- ���r���L�����Z����
             xoh.bond_acceptance_flag,           -- �؏���̃t���O
             xoh.bond_acceptance_date,           -- �؏���̓�
             xoh.expiration_date,                -- ������
             xoh.object_status,                  -- �����X�e�[�^�X
             xoh.active_flag,                    -- �����L���t���O
             xoh.info_sys_if_date,               -- ���[�X�Ǘ����A�g��
             xoh.generation_date,                -- ������
             gr_init_rec.process_date,           -- �v���(�Ɩ����t)
             cv_if_flag_one,                     -- ��vIF�t���O('1'(�����M))
             NULL,                               -- �ړ����{�Ё^�H��(NULL)
             NULL,                               -- �ړ����Ǘ�����(NULL)
             NULL,                               -- �ړ������ݒu�ꏊ(NULL)
             NULL,                               -- �ړ������ݒu��(NULL)
             NULL,                               -- �ړ����o�^�ԍ�(NULL)
             NULL,                               -- �E�v(NULL)
             cn_created_by,                      -- �쐬��
             cd_creation_date,                   -- �쐬��
             cn_last_updated_by,                 -- �ŏI�X�V��
             cd_last_update_date,                -- �ŏI�X�V��
             cn_last_update_login,               -- �ŏI�X�V۸޲�
             cn_request_id,                      -- �v��ID
             cn_program_application_id,          -- �ݶ��ĥ��۸��ѥ���ع����ID
             cn_program_id,                      -- �ݶ��ĥ��۸���ID
             cd_program_update_date              -- ��۸��эX�V��
      FROM   xxcff_object_headers xoh  -- �w���[�X�����x�e�[�u��
      WHERE  xoh.object_header_id = g_object_headers_tab(i).object_header_id;
    END LOOP record_loop;
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
  END insert_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_obj_code1  IN  VARCHAR2,     --   1.�����R�[�h1
    iv_obj_code2  IN  VARCHAR2,     --   2.�����R�[�h2
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
    gn_target_cnt := 2;
    gn_normal_cnt := 0;
    gn_error_cnt  := gn_target_cnt;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���[�X�����e�[�u���擾���� (A-2)
    -- =====================================================
    select_object_headers(
      iv_obj_code1,      -- 1.�����R�[�h1
      iv_obj_code2,      -- 2.�����R�[�h2
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �_��󋵃`�F�b�N (A-3)
    -- =====================================================
    check_contract_condition(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������`�F�b�N (A-4)
    -- =====================================================
    validate_record(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����Ώۂ�2�����Ƃ��_��ς̏ꍇ
    IF (  (g_object_headers_tab(1).contract_line_id IS NOT NULL)
      AND (g_object_headers_tab(2).contract_line_id IS NOT NULL)  )
    THEN
      -- =====================================================
      --  ���[�X�_�񖾍׃e�[�u���X�V���� (A-5)
      -- =====================================================
      update_contract_lines(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ���[�X�_�񖾍ח����e�[�u���o�^���� (A-7)
      -- =====================================================
      insert_contract_histories(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- �����Ώۂ̂����ꂩ�̕����̂݌_��ς̏ꍇ
    ELSE
      -- =====================================================
      --  ���[�X�_�񖾍׃e�[�u���X�V���� (A-5)
      -- =====================================================
      update_contract_lines(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ���[�X�����e�[�u���X�V���� (A-6)
      -- =====================================================
      update_object_headers(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ���[�X�_�񖾍ח����e�[�u���o�^���� (A-7)
      -- =====================================================
      insert_contract_histories(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ���[�X���������e�[�u���o�^���� (A-8)
      -- =====================================================
      insert_object_histories(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ����I���̏ꍇ�̃O���[�o���ϐ��̐ݒ�
    gn_error_cnt  := 0;
    gn_normal_cnt := gn_target_cnt;
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
    iv_obj_code1  IN  VARCHAR2,      --   1.�����R�[�h1
    iv_obj_code2  IN  VARCHAR2       --   2.�����R�[�h2
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
       iv_obj_code1  -- �����R�[�h1
      ,iv_obj_code2  -- �����R�[�h2
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
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
END XXCFF003A33C;
/
