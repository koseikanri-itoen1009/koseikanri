CREATE OR REPLACE PACKAGE BODY XXCFR003A14C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFR003A14C
 * Description     : �ėp�����N������
 * MD.050          : MD050_CFR_003_A14_�ėp�����N������
 * MD.070          : MD050_CFR_003_A14_�ėp�����N������
 * Version         : 1.1
 *
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  get_conc_name   P         ���s�ΏۃR���J�����g�v���O�������擾�v���V�[�W��
 *  submit_request  P         �R���J�����g���s�v���V�[�W��
 *  wait_request    P         �R���J�����g�Ď��v���V�[�W��
 *  end_proc        P         �I�������v���V�[�W��
 *  submain         P         �ėp�����N���������s��
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-04    1.0  SCS ���� �q�� ����쐬
 *  2009-09-18    1.1  SCS ���� �L�� AR�d�l�ύXIE535�Ή�
 ************************************************************************/

--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--

  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- ����I��
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --�x��
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --�G���[
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';

  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A14C';  -- �p�b�P�[�W��

--
--##############################  �Œ蕔 END   ####################################
--

  --===============================================================
  -- �O���[�o���萔
  --===============================================================

  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- �A�h�I����v AR �̃A�v���P�[�V�����Z�k��
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��

  -- ���b�Z�[�W�ԍ�
  cv_msg_cfr_00002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00002';
  cv_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004';
  cv_msg_cfr_00012  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00012';
  cv_msg_cfr_00013  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00013';
  cv_msg_cfr_00014  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00014';
  cv_msg_cfr_00020  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00020';
  cv_msg_cfr_00021  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00021';
  cv_msg_cfr_00022  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00022';
  cv_msg_cfr_00025  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00025';

  cv_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  cv_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  cv_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  cv_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  cv_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  cv_msg_ccp_90007  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90007';

  -- ���b�Z�[�W�g�[�N��
  cv_tkn_param_name CONSTANT VARCHAR2(30) := 'PARAM_NAME';   -- �R���J�����g�p�����[�^��
  cv_tkn_param_val  CONSTANT VARCHAR2(30) := 'PARAM_VAL';    -- �R���J�����g�p�����[�^�l
  cv_tkn_prof_name  CONSTANT VARCHAR2(30) := 'PROF_NAME';    -- �v���t�@�C���I�v�V������
  cv_tkn_prog_name  CONSTANT VARCHAR2(30) := 'PROGRAM_NAME'; -- �R���J�����g�v���O������
  cv_tkn_sqlerrm    CONSTANT VARCHAR2(30) := 'SQLERRM';      -- �G���[���b�Z�[�W
  cv_tkn_req_id     CONSTANT VARCHAR2(30) := 'REQ_ID';       -- �R���J�����g�v��ID
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';        -- ��������

  -- �v���t�@�C���I�v�V����
  cv_prof_name_wait_interval  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCFR1_GENERAL_INVOICE_INTERVAL';
  cv_prof_name_wait_max       CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCFR1_GENERAL_INVOICE_MAX_WAIT';

  -- ���s�ΏۃR���J�����g�v���O�����Z�k��
  cv_003A06C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A06C';  -- �ėp�X�ʐ���
  cv_003A07C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A07C';  -- �ėp�`�[�ʐ���
  cv_003A08C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A08C';  -- �ėp���i�i�S���ׁj
  cv_003A09C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A09C';  -- �ėp���i�i�P�i���W�v�j
  cv_003A10C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A10C';  -- �ėp���i�i�X�P�i���W�v�j
  cv_003A11C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A11C';  -- �ėp���i�i�P�����W�v�j
  cv_003A12C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A12C';  -- �ėp���i�i�X�P�����W�v�j
  cv_003A13C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A13C';  -- �ėp�i�X�R�������W�v�j

  -- �R���J�����g�p�����[�^�l'Y/N'
  cv_conc_param_y CONSTANT VARCHAR2(1) := 'Y';
  cv_conc_param_n CONSTANT VARCHAR2(1) := 'N';

  -- �R���J�����gdev�t�F�[�Y
  cv_dev_phase_complete CONSTANT VARCHAR2(30) := 'COMPLETE';  -- '����'

  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal  CONSTANT VARCHAR2(30) := 'NORMAL';   -- '����'
  cv_dev_status_warn    CONSTANT VARCHAR2(30) := 'WARNING';  -- '�x��'
  cv_dev_status_err     CONSTANT VARCHAR2(30) := 'ERROR';    -- '�G���[';

  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gv_wait_interval       fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��Ԋu
  gv_wait_max            fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��ő厞��

  gn_target_count        PLS_INTEGER := 0;  -- �����Ώی���
  gn_normal_count        PLS_INTEGER := 0;  -- ����I������
  gn_warn_count          PLS_INTEGER := 0;  -- �x���I������
  gn_err_count           PLS_INTEGER := 0;  -- �G���[�I������

  --===============================================================
  -- �O���[�o�����R�[�h�^�C�v
  --===============================================================
  -- ���s�R���J�����g�ꗗ�E���R�[�h�^�C�v
  TYPE g_conc_list_rtype IS RECORD(
    conc_prog_name      fnd_concurrent_programs.concurrent_program_name%TYPE,          -- �R���J�����g�v���O�����Z�k��
    user_conc_prog_name fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE,  -- ���[�U�E�R���J�����g�v���O������
    request_id          NUMBER,                                                        -- �R���J�����g�v��ID
    dev_phase           VARCHAR2(100),                                                 -- �R���J�����g�v���O�������s�t�F�[�Y
    dev_status          VARCHAR2(100)                                                  -- �R���J�����g�v���O�����I���X�e�[�^�X
  );

  --===============================================================
  -- �O���[�o���e�[�u���^�C�v
  --===============================================================
  -- ���s�R���J�����g�ꗗ�E�e�[�u���^�C�v
  TYPE g_conc_list_ttype IS TABLE OF g_conc_list_rtype INDEX BY PLS_INTEGER;

  --===============================================================
  -- �O���[�o���e�[�u��
  --===============================================================
  -- ���s�R���J�����g�ꗗ�e�[�u��
  g_conc_list_tab g_conc_list_ttype;

  --===============================================================
  -- �O���[�o����O
  --===============================================================
  global_process_expt       EXCEPTION; -- �֐���O
  global_api_expt           EXCEPTION; -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION; -- ���ʊ֐�OTHERS��O
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000); -- ���ʊ֐���O(ORA-20000)��global_api_others_expt���}�b�s���O

  /**********************************************************************************
   * Procedure Name   : get_conc_name
   * Description      : �R���J�����g�v���O�������擾����
   ***********************************************************************************/
  PROCEDURE get_conc_name(
    iv_exec_003A06C  IN  VARCHAR2,    -- �ėp�X�ʐ���
    iv_exec_003A07C  IN  VARCHAR2,    -- �ėp�`�[�ʐ���
    iv_exec_003A08C  IN  VARCHAR2,    -- �ėp���i�i�S���ׁj
    iv_exec_003A09C  IN  VARCHAR2,    -- �ėp���i�i�P�i���W�v�j
    iv_exec_003A10C  IN  VARCHAR2,    -- �ėp���i�i�X�P�i���W�v�j
    iv_exec_003A11C  IN  VARCHAR2,    -- �ėp���i�i�P�����W�v�j
    iv_exec_003A12C  IN  VARCHAR2,    -- �ėp���i�i�X�P�����W�v�j
    iv_exec_003A13C  IN  VARCHAR2,    -- �ėp�i�X�R�������W�v�j
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS

--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_conc_name';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--

    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
    ln_tab_count  PLS_INTEGER := 0;  -- ���s�R���J�����g�ꗗ�e�[�u������

    --===============================================================
    -- ���[�J���J�[�\��
    --===============================================================
    -- �R���J�����g���擾�J�[�\��
    CURSOR get_conc_prog_name_cur(
      iv_conc_prog_name IN VARCHAR2
    )
    IS
      SELECT fcpv.user_concurrent_program_name user_concurrent_program_name
      FROM fnd_application fa,
           fnd_concurrent_programs_vl fcpv
      WHERE fa.application_short_name = cv_xxcfr_app_name
        AND fcpv.concurrent_program_name = iv_conc_prog_name
        AND fcpv.application_id = fcpv.application_id;


  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    IF (iv_exec_003A06C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A06C_name;
      OPEN get_conc_prog_name_cur(cv_003A06C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A07C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A07C_name;
      OPEN get_conc_prog_name_cur(cv_003A07C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A08C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A08C_name;
      OPEN get_conc_prog_name_cur(cv_003A08C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A09C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A09C_name;
      OPEN get_conc_prog_name_cur(cv_003A09C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A10C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A10C_name;
      OPEN get_conc_prog_name_cur(cv_003A10C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A11C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A11C_name;
      OPEN get_conc_prog_name_cur(cv_003A11C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A12C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A12C_name;
      OPEN get_conc_prog_name_cur(cv_003A12C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A13C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A13C_name;
      OPEN get_conc_prog_name_cur(cv_003A13C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END get_conc_name;

  /**********************************************************************************
   * Procedure Name   : submit_request
   * Description      : �R���J�����g���s�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submit_request(
    iv_target_date      IN  VARCHAR2,
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1         IN  VARCHAR2,
    iv_cust_code        IN  VARCHAR2,
-- Modify 2009.09.18 Ver1.1 End
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--

--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_request_id  NUMBER;      -- �R���J�����g�v��ID
    ln_tab_ind     PLS_INTEGER := 0; -- ���s�R���J�����g�ꗗ�e�[�u������
-- Add 2009.09.18 Ver1.1 Start
    lv_cust_class  VARCHAR2(30); --�ڋq�敪�擾�p�ϐ�
-- Add 2009.09.18 Ver1.1 End

    -- ===============================
    -- ���[�J����O
    -- ===============================
    submit_request_expt  EXCEPTION;  -- �R���J�����g���s�G���[��O

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
-- Modify 2009.09.18 Ver1.1 Start
    --�ڋq�敪�擾
    SELECT hca.customer_class_code
    INTO lv_cust_class
    FROM hz_cust_accounts    hca
        ,xxcmm_cust_accounts  xxca
    WHERE hca.cust_account_id  = xxca.customer_id
      AND xxca.customer_code = iv_cust_code;

-- Modify 2009.09.18 Ver1.1 End
    <<submit_request_loop>>
    FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
      ln_tab_ind := ln_tab_ind + 1;

      -- �R���J�����g���s
      ln_request_id :=
      FND_REQUEST.SUBMIT_REQUEST(application => cv_xxcfr_app_name,                  -- �A�v���P�[�V�����Z�k��
                                 program     => g_conc_list_tab(i).conc_prog_name,  -- �R���J�����g�v���O������
                                 argument1   => iv_target_date,                     -- �R���J�����g�p�����[�^(����)
-- Modify 2009.09.18 Ver1.1 Start
--                                 argument2   => iv_ar_code1                         -- �R���J�����g�p�����[�^(���|�R�[�h�i�������j)
                                 argument2   => iv_cust_code,                       -- �R���J�����g�p�����[�^(�ڋq�R�[�h)
                                 argument3   => lv_cust_class                       -- �R���J�����g�p�����[�^(�ڋq�敪)
-- Modify 2009.09.18 Ver1.1 Start
                                );

      IF (ln_request_id = 0) THEN
        RAISE submit_request_expt;
      ELSE
        COMMIT;
        g_conc_list_tab(i).request_id := ln_request_id;

        -- �v�����s���b�Z�[�W�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                   iv_name => cv_msg_cfr_00020,
                                                   iv_token_name1 => cv_tkn_prog_name,
                                                   iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name,
                                                   iv_token_name2 => cv_tkn_req_id,
                                                   iv_token_value2 => g_conc_list_tab(i).request_id
                                                  )
                         );
      END IF;

    END LOOP submit_request_loop;

  EXCEPTION
    -- *** �v�����s���s�� ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.SUBMIT_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W���擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00012,
                                            iv_token_name1 => cv_tkn_prog_name,
                                            iv_token_value1 => g_conc_list_tab(ln_tab_ind).user_conc_prog_name
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submit_request;

  /**********************************************************************************
   * Procedure Name   : wait_request
   * Description      : �R���J�����g�Ď��v���V�[�W��
   ***********************************************************************************/
  PROCEDURE wait_request(
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_request';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--

--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_tab_ind      PLS_INTEGER := 0; -- ���s�R���J�����g�ꗗ�e�[�u������
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�

    -- ===============================
    -- ���[�J����O
    -- ===============================
    wait_for_request_expt  EXCEPTION;  -- �R���J�����g�Ď��G���[��O

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    <<wait_request_loop>>
    FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
      ln_tab_ind := ln_tab_ind + 1;

      -- �R���J�����g�v���Ď�
      lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => g_conc_list_tab(i).request_id,
                                                         interval => gv_wait_interval,
                                                         max_wait => gv_wait_max,
                                                         phase => lv_phase,
                                                         status => lv_status,
                                                         dev_phase => lv_dev_phase,
                                                         dev_status => lv_dev_status,
                                                         message => lv_message
                                                        );

      IF (lb_wait_request) THEN
        g_conc_list_tab(i).dev_phase := lv_dev_phase;
        g_conc_list_tab(i).dev_status := lv_dev_status;

        IF (lv_dev_phase = cv_dev_phase_complete)
          AND (lv_dev_status = cv_dev_status_normal)
        THEN
          -- ����I���̏ꍇ
          gn_normal_count := gn_normal_count + 1;
          -- ����I�����b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00021,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          lv_errmsg := '';
        ELSIF (lv_dev_phase = cv_dev_phase_complete)
          AND (lv_dev_status = cv_dev_status_warn)
        THEN
          -- �x���I���̏ꍇ
          gn_warn_count := gn_warn_count + 1;
          -- �x���I�����b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00022,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            lv_errmsg
                           );
          lv_errmsg := '';
        ELSE
          -- ���̑�(�G���[�I��)�̏ꍇ
          gn_err_count := gn_err_count + 1;
          -- �G���[�I�����b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00014,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            lv_errmsg
                           );
          lv_errmsg := '';
        END IF;
      ELSE
        RAISE wait_for_request_expt;
      END IF;
    END LOOP wait_request_loop;

  EXCEPTION
    -- *** �v���Ď����s�� ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.WAIT_FOR_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W������Ύ擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00013,
                                            iv_token_name1 => cv_tkn_prog_name,
                                            iv_token_value1 => g_conc_list_tab(ln_tab_ind).user_conc_prog_name
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END wait_request;

  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : �I�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--

--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lb_submited_request BOOLEAN := FALSE; -- ���s�ς݃R���J�����g���݃`�F�b�N

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    -- �Ώی����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90000,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => g_conc_list_tab.COUNT
                                              )
                     );

    -- ���������o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90001,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_normal_count
                                              )
                     );

    -- �x�������o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                     iv_name => cv_msg_cfr_00025,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_warn_count
                                              )
                     );

    -- �G���[�����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90002,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_err_count
                                              )
                     );

    -- �R���J�����g���s�m�F
    IF g_conc_list_tab.EXISTS(1) THEN
      <<submit_request_loop>>
      FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
        IF (g_conc_list_tab(i).request_id IS NOT NULL) THEN
          lb_submited_request := TRUE;
          EXIT;
        END IF;
      END LOOP submit_request_loop;
    END IF;

    IF  (gn_err_count > 0)
     OR ((iv_retcode = cv_status_error)
     AND (lb_submited_request))
    THEN
      -- �G���[�I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90007
                                                )
                       );
    ELSIF (iv_retcode = cv_status_error)
    AND (NOT lb_submited_request)
    THEN
      -- �G���[�I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90006
                                                )
                       );
    ELSE
      -- ����I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90004
                                                )
                       );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �ėp�����N���������s��
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
-- Modify 2009.09.18 Ver1.1 Start
    iv_exec_003A06C  IN  VARCHAR2,    -- �ėp�X�ʐ���
    iv_exec_003A07C  IN  VARCHAR2,    -- �ėp�`�[�ʐ���
    iv_exec_003A08C  IN  VARCHAR2,    -- �ėp���i�i�S���ׁj
    iv_exec_003A09C  IN  VARCHAR2,    -- �ėp���i�i�P�i���W�v�j
    iv_exec_003A10C  IN  VARCHAR2,    -- �ėp���i�i�X�P�i���W�v�j
    iv_exec_003A11C  IN  VARCHAR2,    -- �ėp���i�i�P�����W�v�j
    iv_exec_003A12C  IN  VARCHAR2,    -- �ėp���i�i�X�P�����W�v�j
    iv_exec_003A13C  IN  VARCHAR2,    -- �ėp�i�X�R�������W�v�j
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_log        CONSTANT VARCHAR2(10)  := 'LOG';      -- �p�����[�^�o�͊֐� ���O�o�͎���iv_which�l
    cv_output     CONSTANT VARCHAR2(10)  := 'OUTPUT';   -- �p�����[�^�o�͊֐� ���|�[�g�o�͎���iv_which�l

--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_pkg_name VARCHAR2(100); -- ���ʊ֐��p�b�P�[�W��
    lv_prg_name VARCHAR2(100); -- ���ʊ֐��v���V�[�W��/�t�@���N�V������

    -- ===============================
    -- ���[�J����O
    -- ===============================
    prof_wait_interval_expt  EXCEPTION; -- �v���t�@�C���I�v�V�����u�ėp�����v�������`�F�b�N�ҋ@�b���v�擾��O
    prof_wait_max_expt       EXCEPTION; -- �v���t�@�C���I�v�V�����u�ėp�����v�������ҋ@�ő�b���v�擾��O

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    -- �R���J�����g�p�����[�^���O�o��
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                                   iv_conc_param2 => iv_ar_code1,
                                   iv_conc_param2 => iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                                   iv_conc_param3 => iv_exec_003A06C,
                                   iv_conc_param4 => iv_exec_003A07C,
                                   iv_conc_param5 => iv_exec_003A08C,
                                   iv_conc_param6 => iv_exec_003A09C,
                                   iv_conc_param7 => iv_exec_003A10C,
                                   iv_conc_param8 => iv_exec_003A11C,
                                   iv_conc_param9 => iv_exec_003A12C,
                                   iv_conc_param10 => iv_exec_003A13C,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    -- �R���J�����g�p�����[�^OUT�t�@�C���o��
    xxcfr_common_pkg.put_log_param(iv_which => cv_output,
                                   iv_conc_param1 => iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                                   iv_conc_param2 => iv_ar_code1,
                                   iv_conc_param2 => iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                                   iv_conc_param3 => iv_exec_003A06C,
                                   iv_conc_param4 => iv_exec_003A07C,
                                   iv_conc_param5 => iv_exec_003A08C,
                                   iv_conc_param6 => iv_exec_003A09C,
                                   iv_conc_param7 => iv_exec_003A10C,
                                   iv_conc_param8 => iv_exec_003A11C,
                                   iv_conc_param9 => iv_exec_003A12C,
                                   iv_conc_param10 => iv_exec_003A13C,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    IF NOT (iv_exec_003A06C = cv_conc_param_n AND
            iv_exec_003A07C = cv_conc_param_n AND
            iv_exec_003A08C = cv_conc_param_n AND
            iv_exec_003A09C = cv_conc_param_n AND
            iv_exec_003A10C = cv_conc_param_n AND
            iv_exec_003A11C = cv_conc_param_n AND
            iv_exec_003A12C = cv_conc_param_n AND
            iv_exec_003A13C = cv_conc_param_n)
    THEN
      --===============================================================
      -- A-2�D�v���t�@�C���擾����
      --===============================================================
      gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
      IF (gv_wait_interval IS NULL) THEN
        RAISE prof_wait_interval_expt;
      END IF;

      gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
      IF (gv_wait_max IS NULL) THEN
        RAISE prof_wait_max_expt;
      END IF;

      --===============================================================
      -- A-3�D�R���J�����g�E�v���O�������擾����
      --===============================================================
      get_conc_name(iv_exec_003A06C,
                    iv_exec_003A07C,
                    iv_exec_003A08C,
                    iv_exec_003A09C,
                    iv_exec_003A10C,
                    iv_exec_003A11C,
                    iv_exec_003A12C,
                    iv_exec_003A13C,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg
                   );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

      --===============================================================
      -- A-4�D�R���J�����g�N������
      --===============================================================
      submit_request(iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                     iv_ar_code1,
                     iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg
                    );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

      --===============================================================
      -- A-5�D�R���J�����g�X�e�[�^�X�擾����
      --===============================================================
      wait_request(lv_errbuf,
                   lv_retcode,
                   lv_errmsg
                  );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

    END IF;

  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �v���t�@�C���u�ėp�����v�������`�F�b�N�ҋ@�b���v�擾�G���[������ ***
    WHEN prof_wait_interval_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00004,
                                            iv_token_name1 => cv_tkn_prof_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval));
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �v���t�@�C���u�ėp�����v�������ҋ@�ő�b���v�擾�G���[������ ***
    WHEN prof_wait_max_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00004,
                                            iv_token_name1 => cv_tkn_prof_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max));
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;

  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
-- Modify 2009.09.18 Ver1.1 End
    iv_exec_003A06C  IN  VARCHAR2,    -- �ėp�X�ʐ���
    iv_exec_003A07C  IN  VARCHAR2,    -- �ėp�`�[�ʐ���
    iv_exec_003A08C  IN  VARCHAR2,    -- �ėp���i�i�S���ׁj
    iv_exec_003A09C  IN  VARCHAR2,    -- �ėp���i�i�P�i���W�v�j
    iv_exec_003A10C  IN  VARCHAR2,    -- �ėp���i�i�X�P�i���W�v�j
    iv_exec_003A11C  IN  VARCHAR2,    -- �ėp���i�i�P�����W�v�j
    iv_exec_003A12C  IN  VARCHAR2,    -- �ėp���i�i�X�P�����W�v�j
    iv_exec_003A13C  IN  VARCHAR2     -- �ėp�i�X�R�������W�v�j
  )
  IS

--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--

--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(5000); -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--

  BEGIN

    --===============================================================
    -- A-1�D���̓p�����[�^�l���O�o�͏���
    --===============================================================
    xxccp_common_pkg.put_log_header(ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    submain(iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--            iv_ar_code1,
            iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
            iv_exec_003A06C,
            iv_exec_003A07C,
            iv_exec_003A08C,
            iv_exec_003A09C,
            iv_exec_003A10C,
            iv_exec_003A11C,
            iv_exec_003A12C,
            iv_exec_003A13C,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );

    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;

    -- �X�e�[�^�X���Z�b�g
    retcode := lv_retcode;

    --===============================================================
    -- A-6�D�I������
    --===============================================================
    end_proc(iv_retcode => retcode,
             ov_errbuf  => lv_errbuf,
             ov_retcode => lv_retcode,
             ov_errmsg  => lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;

    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;

    -- �G���[�I�������R���J�����g�����݂���ꍇ�A�G���[�I��������
    IF (gn_err_count > 0) THEN
      retcode := cv_status_error;
    END IF;

  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
END  XXCFR003A14C;
/
