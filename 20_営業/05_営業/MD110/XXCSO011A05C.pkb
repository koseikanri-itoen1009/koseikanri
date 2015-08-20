CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A05C (body)
 * Description      : �ʐM���f���ݒu�^�s�ύX����
 * MD.050           : �ʐM���f���ݒu�^�s�ύX���� (MD050_CSO_011A05)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  data_validation        �Ó����`�F�b�N(A-2)
 *  upd_install_base       �����}�X�^�X�V(A-3)
 *  upd_hht_tran           HHT�W�z�M�A�g�g�����U�N�V�����X�V(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/06/25    1.0   S.Yamashita      main�V�K�쐬
 *  2015/08/19    1.1   S.Yamashita      [E_�{�ғ�_12984]T4��Q�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  init_err_expt               EXCEPTION;  -- ���������G���[
  g_lock_expt                 EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT( g_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO011A05C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- ����
  cv_format_ymd               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00014            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00014';          -- �v���t�@�C���擾�G���[
  cv_msg_cso_00072            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00072';          -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cso_00278            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00278';          -- ���b�N�G���[���b�Z�[�W
  cv_msg_cso_00329            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00329';          -- �f�[�^�擾�G���[
  cv_msg_cso_00330            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00330';          -- �f�[�^�o�^�G���[
  cv_msg_cso_00337            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00337';          -- �f�[�^�X�V�G���[
  cv_msg_cso_00343            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00343';          -- ����^�C�vID���o�G���[���b�Z�[�W
  cv_msg_cso_00504            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00504';          -- �����}�X�^�X�V���G���[
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- ���̓p�����[�^�p������
  cv_msg_cso_00696            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00696';          -- ���b�Z�[�W�p������(�����R�[�h)
  cv_msg_cso_00707            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00707';          -- ���b�Z�[�W�p������(�ڋq�R�[�h)
  cv_msg_cso_00711            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00711';          -- ���b�Z�[�W�p������(����^�C�v�̎���^�C�vID)
  cv_msg_cso_00714            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00714';          -- ���b�Z�[�W�p������(�����}�X�^)
  cv_msg_cso_00729            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00729';          -- ���b�Z�[�W�p������(����敪)
  cv_msg_cso_00757            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00757';          -- ���b�Z�[�W�p������(HHT�W�z�M�A�g�g�����U�N�V����)
  cv_msg_cso_00762            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00762';          -- ���b�Z�[�W�p������(���g�����R�[�h)
  cv_msg_cso_00763            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00763';          -- ���b�Z�[�W�p������(�ڋq�}�X�^)
  cv_msg_cso_00764            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00764';          -- ���b�Z�[�W�p������(�C���X�^���X�p�[�e�B�}�X�^)
  cv_msg_cso_00765            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00765';          -- ���b�Z�[�W�p������(�C���X�^���X�A�J�E���g�}�X�^)
  cv_msg_cso_00766            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00766';          -- ���b�Z�[�W�p������(�����}�X�^�X�V)
  cv_msg_cso_00761            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00761';          -- �Ώە����擾�G���[
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���̓p�����[�^��
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���̓p�����[�^�l
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- �v���t�@�C����
  cv_tkn_task_name            CONSTANT VARCHAR2(20)  := 'TASK_NAME';                 -- ���ږ�
  cv_tkn_action               CONSTANT VARCHAR2(20)  := 'ACTION';                    -- ���s���Ă��鏈��
  cv_tkn_key_name             CONSTANT VARCHAR2(20)  := 'KEY_NAME';                  -- ���ږ�
  cv_tkn_key_id               CONSTANT VARCHAR2(20)  := 'KEY_ID';                    -- ���ڒl
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';                 -- �ڋq�R�[�h
  cv_tkn_install_code         CONSTANT VARCHAR2(20)  := 'INSTALL_CODE';              -- �����R�[�h
  cv_tkn_src_tran_type        CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';             -- �\�[�X�g�����U�N�V�����^�C�v
  cv_tkn_err_msg              CONSTANT VARCHAR2(20)  := 'ERR_MSG';                   -- SQL�G���[
  cv_tkn_api_name             CONSTANT VARCHAR2(20)  := 'API_NAME';                  -- API��
  cv_tkn_api_msg              CONSTANT VARCHAR2(20)  := 'API_MSG';                   -- API�G���[���b�Z�[�W
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                     -- �e�[�u����
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
  cv_tkn_error_message        CONSTANT VARCHAR2(20)  := 'ERROR_MESSAGE';             -- �G���[���b�Z�[�W
  cv_tkn_err_message          CONSTANT VARCHAR2(20)  := 'ERR_MESSAGE';               -- �G���[���b�Z�[�W
  -- �v���t�@�C����
  cv_prof_modem_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_MODEM_BASE_CODE';    -- XXCSO: �ʐM���f�����_�R�[�h
  -- �t���O
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- 'N'
  -- ����敪
  cv_kbn_1                    CONSTANT VARCHAR2(1)   := '1';                         -- '1'�i�ݒu�\���s�\�j
  cv_kbn_2                    CONSTANT VARCHAR2(1)   := '2';                         -- '2'�i�ݒu�s�\���\�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;              -- �Ɩ����t
  gv_modem_base_code          VARCHAR2(4);       -- �ʐM���f�����_�R�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cust_code      IN  VARCHAR2      --   �ڋq�R�[�h
   ,iv_install_code   IN  VARCHAR2      --   ���g�����R�[�h
   ,iv_kbn            IN  VARCHAR2      --   ����敪
   ,ov_errbuf         OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_cust_code       VARCHAR2(1000);  -- �ڋq�R�[�h�i���b�Z�[�W�o�͗p�j
    lv_install_code    VARCHAR2(1000);  -- ���g�����R�[�h�i���b�Z�[�W�o�͗p�j
    lv_kbn             VARCHAR2(1000);  -- ����敪�i���b�Z�[�W�o�͗p�j
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
    -- ���[�J���ϐ�������
    lv_cust_code    := NULL; -- �ڋq�R�[�h
    lv_install_code := NULL; -- ���g�����R�[�h
    lv_kbn          := NULL; -- ����敪
--
    --==============================================================
    -- 1.���̓p�����[�^�o��
    --==============================================================
    -- �ڋq�R�[�h
    lv_cust_code   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00707              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_cust_code                  -- �g�[�N���l2
                      );
    -- ����敪��1�i�ݒu�\���s�\�j�̏ꍇ
    IF ( iv_kbn = cv_kbn_1 ) THEN
      -- ���g�����R�[�h
      lv_install_code := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_msg_cso_00762              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_install_code               -- �g�[�N���l2
                        );
    END IF;
    -- ����敪
    lv_kbn            := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00729              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_kbn                        -- �g�[�N���l2
                      );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''              || CHR(10) ||
                 lv_cust_code    || CHR(10) ||      -- �ڋq�R�[�h
                 lv_install_code || CHR(10) ||      -- ���g�����R�[�h
                 lv_kbn                             -- ����敪
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''              || CHR(10) ||
                 lv_cust_code    || CHR(10) ||      -- �ڋq�R�[�h
                 lv_install_code || CHR(10) ||      -- ���g�����R�[�h
                 lv_kbn                             -- ����敪
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================================
    -- 2.�v���t�@�C���l�擾
    --==================================================
    gv_modem_base_code := FND_PROFILE.VALUE( cv_prof_modem_base_code );
    -- �v���t�@�C���̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gv_modem_base_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00014         -- ���b�Z�[�W�R�[�h
         ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
         ,iv_token_value1 => cv_prof_modem_base_code  -- �g�[�N���l1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.�Ɩ����t�擾
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t�̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gd_process_date IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00011     -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : �Ó����`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE data_validation(
    iv_cust_code       IN  VARCHAR2      --   �ڋq�R�[�h
   ,iv_install_code    IN  VARCHAR2      --   ���g�����R�[�h
   ,iv_kbn             IN  VARCHAR2      --   ����敪
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lt_cust_account_id hz_cust_accounts.cust_account_id%TYPE;  -- �ڋqID
    ln_count   NUMBER;   -- �����J�E���g�p
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ���[�J���ϐ�������
    lt_cust_account_id := NULL;
    ln_count := 0;
--
    --==============================================================
    -- 1.�ڋqID�擾
    --==============================================================
    BEGIN
      SELECT hca.cust_account_id AS cust_account_id -- �ڋqID
      INTO   lt_cust_account_id
      FROM   hz_cust_accounts hca  -- �ڋq�}�X�^
      WHERE  hca.account_number = iv_cust_code -- �ڋq�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
           ,iv_name         => cv_msg_cso_00329     -- ���b�Z�[�W�R�[�h
           ,iv_token_name1  => cv_tkn_action        -- �g�[�N���R�[�h1
           ,iv_token_value1 => cv_msg_cso_00763     -- �g�[�N���l1
           ,iv_token_name2  => cv_tkn_key_name      -- �g�[�N���R�[�h2
           ,iv_token_value2 => cv_msg_cso_00707     -- �g�[�N���l2
           ,iv_token_name3  => cv_tkn_key_id        -- �g�[�N���R�[�h3
           ,iv_token_value3 => iv_cust_code         -- �g�[�N���l3
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ����敪��1�i�ݒu�\���s�\�j�̏ꍇ
    IF ( iv_kbn = cv_kbn_1 ) THEN
    --==============================================================
    -- 2.�����}�X�^�擾
    --==============================================================
      SELECT COUNT(*) AS cnt -- ����
      INTO   ln_count
      FROM   csi_item_instances cii -- �����}�X�^
      WHERE  cii.owner_party_account_id = lt_cust_account_id  -- �ڋqID
      AND    cii.external_reference     = iv_install_code     -- �����R�[�h
      ;
--
      -- �擾�ł��Ȃ��ꍇ
      IF ( ln_count = 0 ) THEN
        -- �Ώە����擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
           ,iv_name         => cv_msg_cso_00761     -- ���b�Z�[�W�R�[�h
           ,iv_token_name1  => cv_tkn_action        -- �g�[�N���R�[�h1
           ,iv_token_value1 => cv_msg_cso_00714     -- �g�[�N���l1
           ,iv_token_name2  => cv_tkn_cust_code     -- �g�[�N���R�[�h2
           ,iv_token_value2 => iv_cust_code         -- �g�[�N���l2
           ,iv_token_name3  => cv_tkn_install_code  -- �g�[�N���R�[�h3
           ,iv_token_value3 => iv_install_code      -- �g�[�N���l3
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ����������
    ln_count := 0;
--
    --==============================================================
    -- 2.HHT�W�z�M�A�g�g�����U�N�V�����擾
    --==============================================================
    -- ����敪��1�i�ݒu�\���s�\�j�̏ꍇ
    IF ( iv_kbn = cv_kbn_1 ) THEN
      SELECT COUNT(*) AS cnt -- ����
      INTO   ln_count
      FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT�W�z�M�A�g�g�����U�N�V����
      WHERE  xhcdct.account_number = iv_cust_code    -- �ڋq�R�[�h
      AND    xhcdct.install_code   = iv_install_code -- �����R�[�h
      AND    xhcdct.cooperate_flag = cv_flag_y       -- �A�g�t���O
      AND    xhcdct.install_psid   IS NOT NULL       -- �ݒuPSID
      ;
    -- ����敪��2�i�ݒu�s�\���\�j�̏ꍇ
    ELSIF ( iv_kbn = cv_kbn_2 ) THEN
      SELECT COUNT(*) AS cnt -- ����
      INTO   ln_count
      FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT�W�z�M�A�g�g�����U�N�V����
      WHERE  xhcdct.account_number       = iv_cust_code  -- �ڋq�R�[�h
      AND    xhcdct.creating_source_code = cv_pkg_name   -- �������\�[�X�R�[�h
      AND    xhcdct.cooperate_flag       = cv_flag_y     -- �A�g�t���O
      AND    xhcdct.withdraw_psid        IS NOT NULL     -- ���gPSID
      ;
    END IF;
--
    -- �擾�ł��Ȃ��ꍇ
    IF ( ln_count = 0 ) THEN
      -- �Ώە����擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00761     -- ���b�Z�[�W�R�[�h
         ,iv_token_name1  => cv_tkn_action        -- �g�[�N���R�[�h1
         ,iv_token_value1 => cv_msg_cso_00757     -- �g�[�N���l1
         ,iv_token_name2  => cv_tkn_cust_code     -- �g�[�N���R�[�h2
         ,iv_token_value2 => iv_cust_code         -- �g�[�N���l2
         ,iv_token_name3  => cv_tkn_install_code  -- �g�[�N���R�[�h3
         ,iv_token_value3 => iv_install_code      -- �g�[�N���l3
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی����ݒ�
    gn_target_cnt := ln_count;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : upd_install_base
   * Description      : �����}�X�^�X�V(A-3)
   ***********************************************************************************/
  PROCEDURE upd_install_base(
    iv_cust_code       IN  VARCHAR2      --   �ڋq�R�[�h
   ,iv_install_code    IN  VARCHAR2      --   ���g�����R�[�h
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_install_base'; -- �v���O������
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
    cv_relationship_type_code CONSTANT VARCHAR2(100) := 'OWNER';          -- �����[�V�����^�C�v�R�[�h
    cv_src_tran_type          CONSTANT VARCHAR2(5)   := 'IB_UI';          -- ����^�C�v
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';     -- �p�[�e�B�\�[�X�e�[�u��
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES'; -- ���P�[�V�����^�C�v�R�[�h
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';       -- �ǉ�����(�n��R�[�h)
    cn_one                    CONSTANT NUMBER        := 1;
    cn_api_version            CONSTANT NUMBER        := 1.0;
--
    -- *** ���[�J���ϐ� ***
    ln_count                      NUMBER;                                         -- �����J�E���g�p
    lt_instance_id                csi_item_instances.instance_id%TYPE;            -- �C���X�^���XID
    lt_instance_object_vnum       csi_item_instances.object_version_number%TYPE;  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_instance_party_id          csi_i_parties.instance_party_id%TYPE;           -- �C���X�^���X�p�[�e�BID
    lt_instance_party_object_vnum csi_i_parties.object_version_number%TYPE;       -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_ip_account_id              csi_ip_accounts.ip_account_id%TYPE;             -- �C���X�^���X�A�J�E���gID
    lt_instance_acct_object_vnum  csi_ip_accounts.object_version_number%TYPE;     -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_transaction_type_id        csi_txn_types.transaction_type_id%TYPE;         -- ����^�C�vID
    lt_withdraw_account_id        hz_cust_accounts.cust_account_id%TYPE;          -- ���g��ڋqID
    lt_party_id                   hz_party_sites.party_id%TYPE;                   -- �p�[�e�BID
    lt_party_site_id              hz_party_sites.party_site_id%TYPE;              -- �p�[�e�B�T�C�gID
    lt_area_code                  hz_locations.address3%TYPE;                     -- �n��R�[�h
    -- �������X�V�p�`�o�h 
    lt_instance_rec          csi_datastructures_pub.instance_rec;
    lt_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    lt_party_tbl             csi_datastructures_pub.party_tbl;
    lt_account_tbl           csi_datastructures_pub.party_account_tbl;
    lt_pricing_attrib_tbl    csi_datastructures_pub.pricing_attribs_tbl;
    lt_org_assignments_tbl   csi_datastructures_pub.organization_units_tbl;
    lt_asset_assignment_tbl  csi_datastructures_pub.instance_asset_tbl;
    lt_txn_rec               csi_datastructures_pub.transaction_rec;
    lt_instance_id_lst       csi_datastructures_pub.id_tbl;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    -- �ǉ������X�V�p
    l_ext_attrib_rec         csi_iea_values%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ���[�J���ϐ�������
    ln_count := 0; -- �����J�E���g�p
    lt_instance_id                := NULL; -- �C���X�^���XID
    lt_instance_object_vnum       := NULL; -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_instance_party_id          := NULL; -- �C���X�^���X�p�[�e�BID
    lt_instance_party_object_vnum := NULL; -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_ip_account_id              := NULL; -- �C���X�^���X�A�J�E���gID
    lt_instance_acct_object_vnum  := NULL; -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_transaction_type_id        := NULL; -- ����^�C�vID
    lt_withdraw_account_id        := NULL; -- ���g��ڋqID
    lt_party_id                   := NULL; -- �p�[�e�BID
    lt_party_site_id              := NULL; -- �p�[�e�B�T�C�gID
    lt_area_code                  := NULL; -- �n��R�[�h
--
    --==============================================================
    -- 1.�C���X�^���XID�E�I�u�W�F�N�g�o�[�W�����ԍ��擾
    --==============================================================
    BEGIN
      SELECT cii.instance_id           AS instance_id           -- �C���X�^���X�h�c
            ,cii.object_version_number AS object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_instance_id
            ,lt_instance_object_vnum
      FROM   csi_item_instances cii -- �����}�X�^
      WHERE  cii.external_reference = iv_install_code -- ���g�����R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00329         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00714         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00696         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_install_code          -- �g�[�N���l3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 2.�C���X�^���X�p�[�e�B���擾
    --==============================================================
    BEGIN
      SELECT cip.instance_party_id     AS instance_party_id     -- �C���X�^���X�p�[�e�B�h�c
            ,cip.object_version_number AS object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_instance_party_id
            ,lt_instance_party_object_vnum
      FROM   csi_i_parties cip -- �C���X�^���X�p�[�e�B�}�X�^
      WHERE  cip.instance_id = lt_instance_id -- �C���X�^���XID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00329         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00764         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00696         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_install_code          -- �g�[�N���l3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 3.�C���X�^���X�A�J�E���g���擾
    --==============================================================
    BEGIN
      SELECT cia.ip_account_id         AS ip_account_id         -- �C���X�^���X�A�J�E���g�h�c
            ,cia.object_version_number AS object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_ip_account_id
            ,lt_instance_acct_object_vnum
      FROM   csi_ip_accounts cia -- �C���X�^���X�A�J�E���g�}�X�^
      WHERE  cia.instance_party_id = lt_instance_party_id -- �C���X�^���X�p�[�e�BID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00329         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00765         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00696         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_install_code          -- �g�[�N���l3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 4.���g��ڋq���擾
    --==============================================================
    BEGIN
      SELECT hca.cust_account_id AS cust_account_id -- ���g��ڋqID
            ,hps.party_id        AS party_id        -- �p�[�e�B�h�c
            ,hps.party_site_id   AS party_site_id   -- �p�[�e�B�T�C�gID
            ,hl.address3         AS address3        -- �n��R�[�h
      INTO   lt_withdraw_account_id
            ,lt_party_id
            ,lt_party_site_id
            ,lt_area_code
      FROM   hz_cust_accounts hca -- �ڋq�}�X�^
            ,hz_party_sites   hps -- �p�[�e�B�T�C�g�}�X�^
            ,hz_locations     hl  -- �ڋq���Ə��}�X�^
            ,hz_cust_acct_sites hcas  --�ڋq���ݒn
      WHERE  hca.account_number  = gv_modem_base_code    -- �ڋq�R�[�h
      AND    hca.party_id        = hps.party_id          -- �p�[�e�BID
      AND    hps.location_id     = hl.location_id        -- ���P�[�V����ID
      AND    hca.cust_account_id = hcas.cust_account_id  -- �ڋqID
      AND    hps.party_site_id   = hcas.party_site_id    -- �p�[�e�B�T�C�gID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00329         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00763         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00707         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gv_modem_base_code       -- �g�[�N���l3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 5.����^�C�vID�擾
    --==============================================================
    BEGIN
      SELECT ctt.transaction_type_id AS transaction_type_id -- ����^�C�vID
      INTO   lt_transaction_type_id
      FROM   csi_txn_types ctt -- ����^�C�v�e�[�u��
      WHERE  ctt.source_transaction_type = cv_src_tran_type -- ����^�C�v:'IB_UI'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ����^�C�vID���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00343         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00711         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_tran_type         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 6.�X�V�p���R�[�h�ҏW
    --==============================================================
    -- �C���X�^���X���R�[�h�ݒ�
    lt_instance_rec.instance_id                      := lt_instance_id;                -- �C���X�^���XID
    lt_instance_rec.attribute4                       := cv_flag_n;                     -- ��ƈ˗����t���O
    lt_instance_rec.attribute8                       := NULL;                          -- ��ƈ˗����w���˗�No/�ڋqCD
    lt_instance_rec.location_type_code               := cv_location_type_code;         -- ���P�[�V�����^�C�v�R�[�h
    lt_instance_rec.location_id                      := lt_party_site_id;              -- ���P�[�V����ID
    lt_instance_rec.object_version_number            := lt_instance_object_vnum;       -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_instance_rec.request_id                       := cn_request_id;                 -- �v��ID
    lt_instance_rec.program_application_id           := cn_program_application_id;     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    lt_instance_rec.program_id                       := cn_program_id;                 -- �R���J�����g�E�v���O����ID
    lt_instance_rec.program_update_date              := cd_program_update_date;        -- �v���O�����X�V��
    -- �p�[�e�B���R�[�h�ݒ�
    lt_party_tbl(cn_one).instance_party_id           := lt_instance_party_id;          -- �C���X�^���X�p�[�e�BID
    lt_party_tbl(cn_one).party_source_table          := cv_party_source_table;         -- �p�[�e�B�\�[�X�e�[�u��
    lt_party_tbl(cn_one).party_id                    := lt_party_id;                   -- �p�[�e�BID
    lt_party_tbl(cn_one).relationship_type_code      := cv_relationship_type_code;     -- �����[�V�����^�C�v�R�[�h
    lt_party_tbl(cn_one).contact_flag                := cv_flag_n;                     -- �R���^�N�g�t���O
    lt_party_tbl(cn_one).object_version_number       := lt_instance_party_object_vnum; -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- �A�J�E���g���R�[�h�ݒ�
    lt_account_tbl(cn_one).ip_account_id             := lt_ip_account_id;              -- �C���X�^���X�A�J�E���gID
    lt_account_tbl(cn_one).instance_party_id         := lt_instance_party_id;          -- �C���X�^���X�p�[�e�BID
    lt_account_tbl(cn_one).parent_tbl_index          := cn_one;                        -- PARENT_TBL_INDEX
    lt_account_tbl(cn_one).party_account_id          := lt_withdraw_account_id;        -- �p�[�e�B�A�J�E���gID
    lt_account_tbl(cn_one).relationship_type_code    := cv_relationship_type_code;     -- �����[�V�����^�C�v�R�[�h
    lt_account_tbl(cn_one).object_version_number     := lt_instance_acct_object_vnum;  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- ������R�[�h�ݒ�
    lt_txn_rec.transaction_date                      := cd_creation_date;              -- �����
    lt_txn_rec.source_transaction_date               := cd_creation_date;              -- �\�[�X�����
    lt_txn_rec.transaction_type_id                   := lt_transaction_type_id;        -- �g�����U�N�V�����^�C�vID
--
    --==============================================================
    -- 7.�ǉ�����ID�擾
    --==============================================================
    -- �ǉ�����ID(�n��R�[�h)�擾
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                           lt_instance_id
                          ,cv_chiku_cd
                        );
--
    -- �ǉ��������R�[�h�ݒ�
    IF ( l_ext_attrib_rec.attribute_value_id IS NOT NULL ) THEN 
      lt_ext_attrib_values_tbl(cn_one).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      lt_ext_attrib_values_tbl(cn_one).attribute_value       := lt_area_code;
      lt_ext_attrib_values_tbl(cn_one).attribute_id          := l_ext_attrib_rec.attribute_id;
      lt_ext_attrib_values_tbl(cn_one).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    --==============================================================
    -- 8.�C���X�^���X���X�V�`�o�h�ďo��
    --==============================================================
    ------------------------------
    -- IB�X�V�p�W��API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => fnd_api.g_false
      , p_init_msg_list         => fnd_api.g_true
      , p_validation_level      => fnd_api.g_valid_level_full
      , p_instance_rec          => lt_instance_rec
      , p_ext_attrib_values_tbl => lt_ext_attrib_values_tbl
      , p_party_tbl             => lt_party_tbl
      , p_account_tbl           => lt_account_tbl
      , p_pricing_attrib_tbl    => lt_pricing_attrib_tbl
      , p_org_assignments_tbl   => lt_org_assignments_tbl
      , p_asset_assignment_tbl  => lt_asset_assignment_tbl
      , p_txn_rec               => lt_txn_rec
      , x_instance_id_lst       => lt_instance_id_lst
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
--
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                         p_msg_index => cn_one
                        ,p_encoded   => fnd_api.g_true
                       );
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00504         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name          -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cso_00766         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg           -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg_data              -- �g�[�N���l2
                  );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_install_base;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_tran
   * Description      : HHT�W�z�M�A�g�g�����U�N�V�����X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_hht_tran(
    iv_cust_code       IN  VARCHAR2      --   �ڋq�R�[�h
   ,iv_install_code    IN  VARCHAR2      --   ���g�����R�[�h
   ,iv_kbn             IN  VARCHAR2      --   ����敪
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_tran'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lr_row_id  ROWID;   -- �X�V�p
    lt_install_psid          xxcso_hht_col_dlv_coop_trn.install_psid%TYPE;    -- �ݒuPSID
    lt_line_number           xxcso_hht_col_dlv_coop_trn.line_number%TYPE;     -- ����ԍ�
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ����敪��1�i�ݒu�\���s�\�j�̏ꍇ
    IF ( iv_kbn = cv_kbn_1 ) THEN
      --==============================================================
      -- 1.�O��f�[�^�擾
      --==============================================================
      BEGIN
-- 2015/08/19 S.Yamashita Mod Start
--        SELECT xhcdct.rowid         AS rowid        -- ROWID
        SELECT xhcdct.rowid         AS row_id        -- ROWID
-- 2015/08/19 S.Yamashita Mod End
              ,xhcdct.install_psid  AS install_psid    -- �ݒuPSID
              ,xhcdct.line_number   AS line_number     -- ����ԍ�
        INTO   lr_row_id
              ,lt_install_psid
              ,lt_line_number
        FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT�W�z�M�A�g�g�����U�N�V����
        WHERE  xhcdct.account_number = iv_cust_code    -- �ڋq�R�[�h
        AND    xhcdct.install_code   = iv_install_code -- �����R�[�h
        AND    xhcdct.cooperate_flag = cv_flag_y       -- �A�g�t���O
        AND    xhcdct.install_psid   IS NOT NULL       -- �ݒuPSID
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN g_lock_expt THEN
          -- ���b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00278         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00757         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                     );
          lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --==============================================================
      -- 2.�O��f�[�^�X�V
      --==============================================================
      BEGIN
        UPDATE xxcso_hht_col_dlv_coop_trn xhcdct -- HHT�W�z�M�A�g�g�����U�N�V����
        SET    xhcdct.cooperate_flag         = cv_flag_n                 -- �A�g�t���O
              ,xhcdct.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
              ,xhcdct.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
              ,xhcdct.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,xhcdct.request_id             = cn_request_id             -- �v��ID
              ,xhcdct.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xhcdct.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
              ,xhcdct.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE  xhcdct.rowid   = lr_row_id -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�X�V�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00337         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00757         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      -- 3.����f�[�^�i���g�f�[�^�j�o�^
      --==============================================================
      BEGIN
        INSERT INTO xxcso_hht_col_dlv_coop_trn(
          account_number         -- �ڋq�R�[�h
         ,install_code           -- �����R�[�h
         ,creating_source_code   -- �������\�[�X�R�[�h
         ,install_psid           -- �ݒuPSID
         ,withdraw_psid          -- ���gPSID
         ,line_number            -- ����ԍ�
         ,cooperate_flag         -- �A�g�t���O
         ,approval_date          -- ���F��
         ,cooperate_date         -- �A�g��
         ,created_by             -- �쐬��
         ,creation_date          -- �쐬��
         ,last_updated_by        -- �ŏI�X�V��
         ,last_update_date       -- �ŏI�X�V��
         ,last_update_login      -- �ŏI�X�V���O�C��
         ,request_id             -- �v��ID
         ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id             -- �R���J�����g�E�v���O����ID
         ,program_update_date    -- �v���O�����X�V��
         )
         VALUES(
          iv_cust_code                 -- �ڋq�R�[�h
         ,iv_install_code              -- �����R�[�h
         ,cv_pkg_name                  -- �������\�[�X�R�[�h
         ,NULL                         -- �ݒuPSID
         ,lt_install_psid              -- ���gPSID
         ,lt_line_number               -- ����ԍ�
         ,cv_flag_y                    -- �A�g�t���O
         ,TRUNC(cd_creation_date)      -- ���F��
         ,gd_process_date              -- �A�g��
         ,cn_created_by                -- �쐬��
         ,cd_creation_date             -- �쐬��
         ,cn_last_updated_by           -- �ŏI�X�V��
         ,cd_last_update_date          -- �ŏI�X�V��
         ,cn_last_update_login         -- �ŏI�X�V���O�C��
         ,cn_request_id                -- �v��ID
         ,cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date       -- �v���O�����X�V��
         );
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�o�^�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00330     -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_msg_cso_00757     -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                      );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- ����敪��2�i�ݒu�s�\���\�j�̏ꍇ
    ELSIF ( iv_kbn = cv_kbn_2 ) THEN
      BEGIN
        DELETE FROM xxcso_hht_col_dlv_coop_trn xhcdct
        WHERE  xhcdct.account_number       = iv_cust_code  -- �ڋq�R�[�h
        AND    xhcdct.creating_source_code = cv_pkg_name   -- �������\�[�X�R�[�h
        AND    xhcdct.cooperate_flag       = cv_flag_y     -- �A�g�t���O
        AND    xhcdct.withdraw_psid        IS NOT NULL     -- ���gPSID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�폜�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00072     -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table         -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_msg_cso_00757     -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_message   -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM              -- �g�[�N���l2
                      );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_hht_tran;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_cust_code       IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_install_code    IN  VARCHAR2     -- ���g�����R�[�h
   ,iv_kbn             IN  VARCHAR2     -- ����敪
   ,ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ��������(A-1)
    -- ===============================
    init(
      iv_cust_code       => iv_cust_code     -- �ڋq�R�[�h
     ,iv_install_code    => iv_install_code  -- ���g�����R�[�h
     ,iv_kbn             => iv_kbn           -- ����敪
     ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ó����`�F�b�N(A-2)
    -- ===============================
    data_validation(
      iv_cust_code       => iv_cust_code     -- �ڋq�R�[�h
     ,iv_install_code    => iv_install_code  -- ���g�����R�[�h
     ,iv_kbn             => iv_kbn           -- ����敪
     ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����敪��1�i�ݒu�\���s�\�j�̏ꍇ
    IF ( iv_kbn = cv_kbn_1 ) THEN
      -- ===============================
      -- �����}�X�^�X�V(A-3)
      -- ===============================
      upd_install_base(
        iv_cust_code       => iv_cust_code     -- �ڋq�R�[�h
       ,iv_install_code    => iv_install_code  -- ���g�����R�[�h
       ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- HHT�W�z�M�A�g�g�����U�N�V�����X�V(A-4)
    -- ===============================
    upd_hht_tran(
      iv_cust_code       => iv_cust_code     -- �ڋq�R�[�h
     ,iv_install_code    => iv_install_code  -- ���g�����R�[�h
     ,iv_kbn             => iv_kbn           -- ����敪
     ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���������ݒ�
    gn_normal_cnt := gn_normal_cnt + 1;
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
    errbuf             OUT VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode            OUT VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_cust_code       IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_install_code    IN  VARCHAR2     -- ���g�����R�[�h
   ,iv_kbn             IN  VARCHAR2     -- ����敪
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
       iv_cust_code    => iv_cust_code     -- �ڋq�R�[�h
      ,iv_install_code => iv_install_code  -- ���g�����R�[�h
      ,iv_kbn          => iv_kbn           -- ����敪
      ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ������ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errbuf                  --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCSO011A05C;
/
