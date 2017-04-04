CREATE OR REPLACE PACKAGE BODY APPS.XXCMM003A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM003A43C(body)
 * Description      : �X�܏��}�X�^�A�g�ieSM�j
 * MD.050           : �X�܏��}�X�^�A�g�ieSM�j MD050_CMM_003_A43
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  open_csv_file          �t�@�C���I�[�v������(A-2)
 *  get_cust_data          �X�܃}�X�^���擾����(A-3)
 *                         CSV�o�͏���(A-4)
 *  upd_vdms_if_control    �X�V����(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/03/24    1.0   S.Yamashita      �V�K�쐬
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
  no_output_data_expt       EXCEPTION;                                         -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM003A43C';               -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';                      -- �}�X�^�̈�
  cv_app_name_xxccp    CONSTANT VARCHAR2(5)   := 'XXCCP';                      -- ���ʁEIF�̈�
  -- �v���t�@�C��
  cv_pro_out_file_dir  CONSTANT VARCHAR2(22)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- ���̋@CSV�t�@�C���o�͐�
  cv_pro_out_file_name CONSTANT VARCHAR2(22)  := 'XXCMM1_003A43_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  -- �g�[�N��
  cv_tkn_date_from     CONSTANT VARCHAR2(10)  := 'DATE_FROM';                  -- ���tFROM
  cv_tkn_date_to       CONSTANT VARCHAR2(8)   := 'DATE_TO';                    -- ���tTO
  cv_tkn_from_value    CONSTANT VARCHAR2(10)  := 'FROM_VALUE';                 -- FROM
  cv_tkn_to_value      CONSTANT VARCHAR2(8)   := 'TO_VALUE';                   -- TO
  cv_tkn_cust_cd       CONSTANT VARCHAR2(8)   := 'CUST_CD';                    -- �ڋq�R�[�h
  cv_tok_ng_profile    CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C��
  cv_tok_filename      CONSTANT VARCHAR2(9)   := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_table         CONSTANT VARCHAR2(5)   := 'TABLE';                      -- �e�[�u����
  cv_tkn_ng_err        CONSTANT VARCHAR2(7)   := 'ERR_MSG';                    -- SQLERRM
  -- ���b�Z�[�W
  cv_msg_00001         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- �Ώۃf�[�^����
  cv_msg_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_00010         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00018         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00052         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00052';           -- ���o�G���[
  cv_msg_00054         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00054';           -- �}���G���[
  cv_msg_00055         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00055';           -- �X�V�G���[
  cv_msg_00056         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00056';           -- �p�����[�^�w��G���[
  cv_msg_00399         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00399';           -- ���̓p�����[�^������
  cv_msg_00392         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00392';           -- �d�b�ԍ�20�����G���[
  cv_msg_00393         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00393';           -- �S���c�ƈ��ݒ�G���[
  cv_msg_00394         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00394';           -- CSV�w�b�_������i�X�܏��}�X�^�A�g�j
  cv_msg_05132         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  --
  cv_msg_00395         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00395';           -- �����F�ŏI�X�V�����i�J�n�j
  cv_msg_00396         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00396';           -- �����F�ŏI�X�V�����i�I���j
  cv_msg_00397         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00397';           -- �����F�X��
  cv_msg_00398         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00398';           -- �����F�C�i�S�p�J���}�j
  cv_msg_00386         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00386';           -- �����F���̋@S�A�g����e�[�u��
  -- �Q�ƃ^�C�v
  cv_xxcmm_chain_code  CONSTANT VARCHAR2(20)  := 'XXCMM_CHAIN_CODE';           -- �Q�ƃ^�C�v(�`�F�[���X�R�[�h)
  -- ���s�t���O
  cv_flg_t             CONSTANT VARCHAR2(1)   := 'T';                          -- ���s�t���O(T:���)
  cv_flg_r             CONSTANT VARCHAR2(1)   := 'R';                          -- ���s�t���O(R:����(���J�o��))
  -- �ėp
  cv_date_time         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';      -- �����t�H�[�}�b�g
  cn_2                 CONSTANT NUMBER(1)     := 2;                            -- �ėp NUMBER:2
  cv_y                 CONSTANT VARCHAR(1)    := 'Y';                          -- �ėp 'Y'
  cv_n                 CONSTANT VARCHAR(1)    := 'N';                          -- �ėp 'N'
  cv_1                 CONSTANT VARCHAR(1)    := '1';                          -- �ėp '1'
  -- ����
  ct_lang              CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���o�����p
  gd_process_date       DATE;                                                  -- �Ɩ����t
  gd_from_date          DATE;                                                  -- �ŏI�X�V�����i�J�n�j
  gd_to_date            DATE;                                                  -- �ŏI�X�V�����i�I���j
  gv_run_flg            VARCHAR2(1);                                           -- ���s�t���O(T:����AR:����(���J�o��))
  -- �t�@�C���o�͊֘A
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;   -- CSV�t�@�C���o�͐�
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;   -- CSV�t�@�C����
  gf_file_handler       utl_file.file_type;                                    -- CSV�t�@�C���o�͗p�n���h��
--
  -- �S���c�ƈ��擾�p���R�[�h�ϐ�
  TYPE gr_employee_num_rec IS RECORD
    (
      employee_num      hz_org_profiles_ext_b.c_ext_attr1%TYPE      -- �S���c�ƈ��R�[�h
     ,hopeb_start_date  hz_org_profiles_ext_b.d_ext_attr1%TYPE      -- �K�p�J�n��
     ,hopeb_update_date hz_org_profiles_ext_b.last_update_date%TYPE -- �ŏI�X�V��
    );
--
  --  ���_���i�[�p�e�[�u��
  TYPE gt_employee_num_ttype IS TABLE OF gr_employee_num_rec INDEX BY BINARY_INTEGER;
  gt_employee_tab  gt_employee_num_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from   IN  VARCHAR2     -- 1.�ŏI�X�V�����i�J�n�j
   ,iv_update_to     IN  VARCHAR2     -- 2.�ŏI�X�V�����i�I���j
   ,ov_errbuf        OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    ld_last_process_date      DATE;            -- �O����s����
    lb_file_exists            BOOLEAN;         -- �t�@�C�����ݔ��f
    ln_file_length            NUMBER(30);      -- �t�@�C���̕�����
    lbi_block_size            BINARY_INTEGER;  -- �u���b�N�T�C�Y
    lv_out_msg                VARCHAR2(5000);  -- �o�͗p
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
    ----------------------------------------------------------------
    -- �Ɩ����t�̎擾
    ----------------------------------------------------------------
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name_xxcmm  -- �A�v���P�[�V�����Z�k��
                   , iv_name        => cv_msg_00018       -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- ����E���������̔���
    ----------------------------------------------------------------
    -- ���s�t���O�̎擾
    IF ( iv_update_from IS NULL ) THEN
      -- ������s��
      gv_run_flg := cv_flg_t;
    ELSE
      -- ����(���J�o��)��
      gv_run_flg := cv_flg_r;
    END IF;
--
    ----------------------------------------------------------------
    -- ���o�J�n�A�I�����Ԃ�ݒ�
    ----------------------------------------------------------------
    -- ���o�����ݒ�
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- ����������̏ꍇ
      BEGIN
        -- ���̋@S�A�g����(�O����s����)���擾
        SELECT xvic.vdms_interface_date vdms_interface_date
        INTO   ld_last_process_date
        FROM   xxcmm_vdms_if_control xvic  -- ���̋@S�A�g����e�[�u��
        WHERE  control_id = cn_2  --����ID�i�X�܏��}�X�^�A�g)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        --�G���[���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm  -- �}�X�^�̈�
                      ,iv_name         => cv_msg_00052       -- ���b�Z�[�W:���o�G���[
                      ,iv_token_name1  => cv_tkn_table       -- �g�[�N��  :TABLE
                      ,iv_token_value1 => cv_msg_00386       -- �l        :���̋@S�A�g����e�[�u��
                      ,iv_token_name2  => cv_tkn_ng_err      -- �g�[�N��  :VALUE
                      ,iv_token_value2 => SQLERRM            -- �l        :SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      gd_from_date := ld_last_process_date; -- �O��A�g��������
      gd_to_date   := cd_last_update_date;  -- ���s����SYSTEM���t�܂�
    ELSE
      -- ����(���J�o��)��
      gd_from_date := TO_DATE( iv_update_from, cv_date_time);  --�p�����[�^�w��i�J�n�j����
      gd_to_date   := TO_DATE( iv_update_to,   cv_date_time);  --�p�����[�^�w��i�I���j�܂�
    END IF;
--
    ----------------------------------------------------------------
    -- ���������̏ꍇ�A�p�����[�^�̎w��`�F�b�N
    ----------------------------------------------------------------
    -- ����(���J�o��)��
    IF ( gv_run_flg = cv_flg_r ) THEN
      -- �p�����[�^�w������̃`�F�b�N
      IF ( gd_from_date >= gd_to_date ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- �}�X�^�̈�
                      ,iv_name         => cv_msg_00056        -- ���b�Z�[�W:�p�����[�^�w��G���[
                      ,iv_token_name1  => cv_tkn_from_value   -- �g�[�N��  :FROM_VALUE
                      ,iv_token_value1 => cv_msg_00395        -- �l        :�ŏI�X�V����(�J�n)
                      ,iv_token_name2  => cv_tkn_to_value     -- �g�[�N��  :TO_VALUE
                      ,iv_token_value2 => cv_msg_00396        -- �l        :�ŏI�X�V����(�I��)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    ----------------------------------------------------------------
    -- ���o�J�n�����A���o�I�������o��
    ----------------------------------------------------------------
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm                    -- �}�X�^�̈�
                  ,iv_name         => cv_msg_00399                         -- ���b�Z�[�W:���̓p�����[�^������
                  ,iv_token_name1  => cv_tkn_date_from                     -- �g�[�N��  :DATE_FROM
                  ,iv_token_value1 => TO_CHAR(gd_from_date, cv_date_time)  -- �l        :�ŏI�X�V����(�J�n)
                  ,iv_token_name2  => cv_tkn_date_to                       -- �g�[�N��  :DATE_TO
                  ,iv_token_value2 => TO_CHAR(gd_to_date, cv_date_time)    -- �l        :�ŏI�X�V����(�I��)
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    ----------------------------------------------------------------
    -- �v���t�@�C���̎擾
    ----------------------------------------------------------------
    -- �t�@�C���p�X�擾
    gv_csv_file_dir := fnd_profile.value( cv_pro_out_file_dir );
    -- �擾�Ɏ��s�����ꍇ
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00002         -- ���b�Z�[�W:�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��  :NG_PROFILE
                    ,iv_token_value1 => cv_pro_out_file_dir  -- �l        :CSV�t�@�C���o�͐�
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C�����擾
    gv_csv_file_name := fnd_profile.value( cv_pro_out_file_name );
    -- �擾�Ɏ��s�����ꍇ
    IF ( gv_csv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00002         -- ���b�Z�[�W:�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��  :NG_PROFILE
                    ,iv_token_value1 => cv_pro_out_file_name -- �l        :CSV�t�@�C����
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- CSV�t�@�C�����݃`�F�b�N
    ----------------------------------------------------------------
    -- �t�@�C�������擾
    utl_file.fgetattr(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- �t�@�C���d���`�F�b�N(�t�@�C�����݂̗L��)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00010         -- ���b�Z�[�W:CSV�t�@�C�����݃`�F�b�N
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- �t�@�C�����o��
    ----------------------------------------------------------------
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxccp     -- �}�X�^�̈�
                   ,iv_name         => cv_msg_05132          -- ���b�Z�[�W:�t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  => cv_tok_filename       -- �g�[�N��  :FILE_NAME
                   ,iv_token_value1 => gv_csv_file_name      -- �l        :�擾�����t�@�C����
                  );
    -- �t�@�C�������R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN
     -- *** ���������ʗ�O�n���h�� ***
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
   * Procedure Name   : open_csv_file
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- �v���O������
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- �t�@�C���I�[�v�����[�h(�������݃��[�h)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------------------------------------------------
    -- CSV�t�@�C����'W'(��������)�ŃI�[�v��
    ----------------------------------------------------------------
    -- �t�@�C�����J��
    gf_file_handler := utl_file.fopen(
                          location   => gv_csv_file_dir     -- �o�͐�
                         ,filename   => gv_csv_file_name    -- �t�@�C����
                         ,open_mode  => cv_csv_mode_w       -- �t�@�C���I�[�v�����[�h
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
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : �X�܏��}�X�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_data'; -- �v���O������
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
    cv_com           CONSTANT VARCHAR2(1)   := ',';    -- �J���}(��؂蕶��)
    cv_hyphen        CONSTANT VARCHAR2(1)   := '-';    -- �n�C�t��
    
--
    -- *** ���[�J���ϐ� ***
    lv_warning_flag      VARCHAR2(1);          -- �x������p
    lv_store_type        VARCHAR2(10);         -- ������F�X��
    lv_em_com            VARCHAR2(10);         -- ������F�C�i�S�p�J���}�j
    lv_hdr_text          VARCHAR2(2000);       -- �w�b�_������i�[�p�ϐ�
    lv_csv_text          VARCHAR2(5000);       -- �o�͂P�s��������ϐ�
    lv_sales_chain_name  VARCHAR2(200);        -- �̔���`�F�[������
    
--
    -- *** ���[�J����O ***
    output_skip_expt EXCEPTION;                        -- CSV�t�@�C���o�̓X�L�b�v��O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �X�܏��}�X�^�擾�J�[�\��
    CURSOR get_cust_cur
    IS
      SELECT  hp.party_name             AS  party_name                      -- �ڋq��
             ,hca.account_number        AS  account_number                  -- �ڋq�R�[�h
             ,xca.sales_chain_code      AS  sales_chain_code                -- �̔���`�F�[���R�[�h
             ,flv.meaning               AS  sales_chain_name                -- �̔���`�F�[���R�[�h����
             ,hl.postal_code            AS  postal_code                     -- �X�֔ԍ�
             ,hl.state || hl.city || hl.address1 || hl.address2 AS address  -- �Z��
             ,hl.address_lines_phonetic AS  address_lines_phonetic          -- �d�b�ԍ�
             ,xca.sale_base_code        AS  sale_base_code                  -- ���㋒�_
             ,hp.last_update_date       AS  hp_update_date                  -- �ŏI�X�V��(�p�[�e�B)
             ,hca.last_update_date      AS  hca_update_date                 -- �ŏI�X�V��(�ڋq�}�X�^)
             ,xca.last_update_date      AS  xca_update_date                 -- �ŏI�X�V��(�ڋq�ǉ����)
             ,hl.last_update_date       AS  hl_update_date                  -- �ŏI�X�V��(�ڋq���Ə�)
             ,flv.last_update_date      AS  flv_update_date                 -- �ŏI�X�V��(�Q�ƃ^�C�v)
      FROM    hz_parties                 hp     -- �p�[�e�B
             ,hz_cust_accounts           hca    -- �ڋq�}�X�^
             ,xxcmm_cust_accounts        xca    -- �ڋq�ǉ����
             ,hz_cust_acct_sites         hcas   -- �ڋq�T�C�g
             ,hz_party_sites             hps    -- �p�[�e�B�T�C�g
             ,hz_locations               hl     -- �ڋq���Ə�
             ,fnd_lookup_values          flv    -- �Q�ƃ^�C�v
      WHERE   hca.party_id                         = hp.party_id
      AND     hca.cust_account_id                  = xca.customer_id
      AND     hca.cust_account_id                  = hcas.cust_account_id
      AND     hcas.party_site_id                   = hps.party_site_id
      AND     hps.location_id                      = hl.location_id
      AND     flv.lookup_type                      = cv_xxcmm_chain_code      -- �^�C�v
      AND     flv.language                         = ct_lang                  -- ����
      AND     flv.enabled_flag                     = cv_y                     -- �L���t���O
      AND     NVL(flv.start_date_active, gd_process_date) <= gd_process_date  -- �L���J�n��
      AND     NVL(flv.end_date_active  , gd_process_date) >= gd_process_date  -- �L���I����
      AND     flv.lookup_code                      = xca.sales_chain_code     -- �R�[�h
      AND     xca.esm_target_div                   = cv_1                     -- �X�g���|&���k����A�g�Ώۃt���O
      ;
    -- �o�͑Ώیڋq���擾���R�[�h�^
    get_cust_rec get_cust_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Œ蕶����擾
    -- ������F�X��
    lv_store_type := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_00397        -- ���b�Z�[�W�R�[�h
                     );
    -- ������F�C�i�S�p�J���}�j
    lv_em_com     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_00398        -- ���b�Z�[�W�R�[�h
                     );
--
    -- ===============================
    -- CSV�o�͏���(A-4)
    -- ===============================
    ----------------------------------------------------------------
    -- CSV�w�b�_�擾
    ----------------------------------------------------------------
    lv_hdr_text := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm   -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_msg_00394        -- ���b�Z�[�W�R�[�h
                   );
--
    ----------------------------------------------------------------
    -- CSV�t�@�C���w�b�_�o��
    ----------------------------------------------------------------
    -- �t�@�C����������
    UTL_FILE.PUT_LINE( gf_file_handler, lv_hdr_text );
--
    <<get_cust_loop>>
    FOR get_cust_rec IN get_cust_cur LOOP
--
      -- ������
      lv_warning_flag := cv_n;  -- �x���t���O
--
      ----------------------------------------------------------------
      -- �S���c�ƈ��`�F�b�N
      ----------------------------------------------------------------
      SELECT  hopeb.c_ext_attr1          AS  employee_number   -- �S���c�ƈ��R�[�h
             ,hopeb.d_ext_attr1          AS  hopeb_start_date  -- �K�p�J�n��(�g�D�v���t�@�C���g��)
             ,hopeb.last_update_date     AS  hopeb_update_date -- �ŏI�X�V��(�g�D�v���t�@�C���g��)
      BULK COLLECT INTO gt_employee_tab
      FROM    hz_parties                 hp     -- �p�[�e�B
             ,hz_cust_accounts           hca    -- �ڋq�}�X�^
             ,hz_organization_profiles   hop    -- �g�D�v���t�@�C��
             ,fnd_application            fa     -- �A�v���P�[�V�����}�X�^
             ,ego_fnd_dsc_flx_ctx_ext    efdfce -- �E�v�t���b�N�X�R���e�L�X�g�g��
             ,hz_org_profiles_ext_b      hopeb  -- �g�D�v���t�@�C���g��
      WHERE   hca.party_id                         = hp.party_id
      AND     hop.party_id                         = hp.party_id
      AND     hop.effective_end_date               IS NULL
      AND     fa.application_short_name            = 'AR'
      AND     efdfce.application_id                = fa.application_id
      AND     efdfce.descriptive_flexfield_name    = 'HZ_ORG_PROFILES_GROUP'
      AND     efdfce.descriptive_flex_context_code = 'RESOURCE'
      AND     hopeb.attr_group_id                  = efdfce.attr_group_id
      AND     hopeb.organization_profile_id        = hop.organization_profile_id
      AND (
             (    gv_run_flg                       = cv_flg_t                -- ������s�̏ꍇ
              AND hopeb.d_ext_attr1                <= TRUNC(gd_process_date + 1)
              AND NVL(hopeb.d_ext_attr2, TRUNC(gd_process_date + 1)) >= TRUNC(gd_process_date + 1)
             )
        OR   (    gv_run_flg                       = cv_flg_r                -- �������s�̏ꍇ
              AND hopeb.d_ext_attr1                <= TRUNC(gd_process_date)
              AND NVL(hopeb.d_ext_attr2, TRUNC(gd_process_date)) >= TRUNC(gd_process_date)
             )
          )
      AND     hca.account_number                   = get_cust_rec.account_number  -- �ڋq�R�[�h
      ;
--
      -- �S���c�ƈ����擾�ł��Ȃ��A�܂��͕����擾�ł���ꍇ
      IF ( gt_employee_tab.COUNT <> 1 ) THEN
      -- �S���c�ƈ��ݒ�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm           -- �}�X�^�̈�
                      ,iv_name         => cv_msg_00393                -- ���b�Z�[�W:�S���c�ƈ��ݒ�G���[
                      ,iv_token_name1  => cv_tkn_cust_cd              -- �g�[�N��  :CUST_CD
                      ,iv_token_value1 => get_cust_rec.account_number -- �l        :�ڋq�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
        );
--
        -- �Ώی����J�E���g
        gn_target_cnt   := gn_target_cnt + 1;
        -- �x�������J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- �S���c�ƈ�������Ɏ擾�ł���ꍇ
      ELSE
--
        -- �Ώۃ��R�[�h���A�g�Ώۂ̏ꍇ(�ŏI�X�V���̏����ɍ��v����ꍇ)
        IF (  (get_cust_rec.hp_update_date          >= gd_from_date AND get_cust_rec.hp_update_date          < gd_to_date)  -- �p�[�e�B
           OR (get_cust_rec.hca_update_date         >= gd_from_date AND get_cust_rec.hca_update_date         < gd_to_date)  -- �ڋq�}�X�^
           OR (get_cust_rec.xca_update_date         >= gd_from_date AND get_cust_rec.xca_update_date         < gd_to_date)  -- �ڋq�ǉ����
           OR (get_cust_rec.hl_update_date          >= gd_from_date AND get_cust_rec.hl_update_date          < gd_to_date)  -- �ڋq���Ə�
           OR (get_cust_rec.flv_update_date         >= gd_from_date AND get_cust_rec.flv_update_date         < gd_to_date)  -- �Q�ƃ^�C�v
           OR (gt_employee_tab(1).hopeb_update_date >= gd_from_date AND gt_employee_tab(1).hopeb_update_date < gd_to_date)  -- �g�D�v���t�@�C���g��
           OR (gv_run_flg = cv_flg_t AND gt_employee_tab(1).hopeb_start_date = TRUNC(gd_process_date + 1)) -- ������s�F�K�p�J�n��(�g�D�v���t�@�C���g��)
           OR (gv_run_flg = cv_flg_r AND gt_employee_tab(1).hopeb_start_date = TRUNC(gd_process_date))     -- �������s�F�K�p�J�n��(�g�D�v���t�@�C���g��)
           )
        THEN
--
          -- �Ώی����J�E���g
          gn_target_cnt   := gn_target_cnt + 1;
--
          ----------------------------------------------------------------
          -- ���p������S�p�����ɕϊ�
          ----------------------------------------------------------------
          lv_sales_chain_name := TO_MULTI_BYTE( get_cust_rec.sales_chain_name );
          ----------------------------------------------------------------
          -- �J���}������
          ----------------------------------------------------------------
          get_cust_rec.party_name := REPLACE( get_cust_rec.party_name, lv_em_com, '' );  -- �ڋq��
          get_cust_rec.address    := REPLACE( get_cust_rec.address   , lv_em_com, '' );  -- �Z��
          lv_sales_chain_name     := REPLACE( lv_sales_chain_name    , lv_em_com, '' );  -- �̔���`�F�[���R�[�h����
--
          ----------------------------------------------------------------
          -- �d�b�ԍ��`���`�F�b�N
          ----------------------------------------------------------------
          IF ( LENGTHB(get_cust_rec.address_lines_phonetic) > 20 ) THEN
            -- �d�b�ԍ�20�����G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name_xxcmm           -- �}�X�^�̈�
                          ,iv_name         => cv_msg_00392                -- ���b�Z�[�W:�d�b�ԍ�20�����G���[
                          ,iv_token_name1  => cv_tkn_cust_cd              -- �g�[�N��  :CUST_CD
                          ,iv_token_value1 => get_cust_rec.account_number -- �l        :�ڋq�R�[�h
                         );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- �x���t���O��ݒ�
            lv_warning_flag := cv_y;
          END IF;
--
          -- �x���G���[���������Ă��Ȃ��ꍇ
          IF ( lv_warning_flag = cv_n ) THEN
            ----------------------------------------------------------------
            -- �o�͍��ڕҏW
            ----------------------------------------------------------------
            lv_csv_text :=
                           ''                                             -- �`�F�[�����R�[�h�i�`�F�[�����j
              || cv_com || ''                                             -- �ڋq���i�`�F�[�����j�i���K�{���ڂł��j
              || cv_com || get_cust_rec.sales_chain_code                  -- �`�F�[���X�R�[�h�i�`�F�[�����j
              || cv_com || SUBSTR( get_cust_rec.party_name, 1, 100 )      -- �X��/���k���i�X�܁j�i���K�{���ڂł��j
              || cv_com || lv_store_type                                  -- �X��/���k�^�C�v�i�X�܁j�i���K�{���ڂł��j
              || cv_com || get_cust_rec.sales_chain_code                  -- �`�F�[���X�R�[�h�i�X�܁j
              || cv_com || SUBSTR( lv_sales_chain_name, 1, 40 )           -- �`�F�[���X�R�[�h���́i�X�܁j
              || cv_com || get_cust_rec.account_number                    -- �ڋq�R�[�h�i9���j�i�X�܁j
              || cv_com || gt_employee_tab(1).employee_num                -- ���ВS���ҁi�X�܁j�i���K�{���ڂł��j
              || cv_com || gt_employee_tab(1).employee_num                -- ��S���ҁi�X�܁j
              || cv_com || SUBSTR( get_cust_rec.postal_code, 1, 3 )
                        || cv_hyphen
                        || SUBSTR( get_cust_rec.postal_code, 4, 7 )       -- �X�֔ԍ��i�X�܁j
              || cv_com || SUBSTR( get_cust_rec.address, 1, 450 )         -- �Z���i�X�܁j
              || cv_com || get_cust_rec.address_lines_phonetic            -- �d�b�ԍ��i�X�܁j
              || cv_com || get_cust_rec.sale_base_code                    -- ���ВS�������i�X�܁j
              || cv_com || get_cust_rec.sale_base_code                    -- ��S��(���ВS������)�i�X�܁j
            ;
--
            ----------------------------------------------------------------
            -- 2.�t�@�C���ւ̏o��
            ----------------------------------------------------------------
            -- �t�@�C����������
            utl_file.put_line( gf_file_handler, lv_csv_text );
--
            -- ���팏���J�E���g
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            -- �x�������J�E���g
            gn_warn_cnt   := gn_warn_cnt + 1;
          END IF;
        END IF;
      END IF;
--
    END LOOP get_cust_loop;
--
    -- �t�@�C���N���[�Y
    utl_file.fclose( gf_file_handler );
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
      -- �J�[�\���N���[�Y
      IF ( get_cust_cur%ISOPEN ) THEN
        CLOSE get_cust_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( get_cust_cur%ISOPEN ) THEN
        CLOSE get_cust_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cust_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vdms_if_control
   * Description      : �X�V����(A-5)
   ***********************************************************************************/
  PROCEDURE upd_vdms_if_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vdms_if_control';   -- �v���O������
    --
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
    BEGIN
      ----------------------------------------------------------------
      -- ���̋@S�A�g����̍X�V
      ----------------------------------------------------------------
      UPDATE  xxcmm_vdms_if_control xvif  -- ���̋@S�A�g����e�[�u��
      SET     xvif.vdms_interface_date    = gd_to_date                 -- ���o�I������
             ,xvif.last_updated_by        = cn_last_updated_by
             ,xvif.last_update_date       = cd_last_update_date
             ,xvif.last_update_login      = cn_last_update_login
             ,xvif.request_id             = cn_request_id
             ,xvif.program_application_id = cn_program_application_id
             ,xvif.program_id             = cn_program_id
             ,xvif.program_update_date    = cd_program_update_date
      WHERE  xvif.control_id = cn_2  --����ID�i�X�܏��}�X�^�A�g)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �X�V�G���[���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm  -- �}�X�^�̈�
                        ,iv_name         => cv_msg_00055       -- ���b�Z�[�W:�X�V�G���[
                        ,iv_token_name1  => cv_tkn_table       -- �g�[�N��  :TALBE
                        ,iv_token_value1 => cv_msg_00386       -- �l        :���̋@S�A�g����e�[�u��
                        ,iv_token_name2  => cv_tkn_ng_err      -- �g�[�N��  :ERR_MSG
                        ,iv_token_value2 => SQLERRM            -- �l        :SQLERRM
                       );
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
  END upd_vdms_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_update_from  IN  VARCHAR2,     -- 1.�ŏI�X�V�����i�J�n�j
    iv_update_to    IN  VARCHAR2,     -- 2.�ŏI�X�V�����i�I���j
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --  ���������v���V�[�W��(A-1)
    -- ===============================
    init(
       iv_update_from  => iv_update_from  -- �ŏI�X�V�����i�J�n�j
      ,iv_update_to    => iv_update_to    -- �ŏI�X�V�����i�I���j
      ,ov_errbuf       => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    --  �t�@�C���I�[�v������(A-2)
    -- ===============================================
    open_csv_file(
       ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �X�܃}�X�^���擾����(A-3)�ACSV�o�͏���(A-4)
    -- ===============================
    get_cust_data(
       ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 0���̏ꍇ�A���b�Z�[�W�o�͌�A�����I��
    IF ( gn_target_cnt = 0 ) THEN
      -- �R���J�����g�E�o�͂ƃ��O�փ��b�Z�[�W�o��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00001         -- �G���[  :�Ώۃf�[�^�Ȃ�
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- �Ώۃf�[�^������O���X���[
      RAISE no_output_data_expt;
    END IF;
--
    -- ����������̂ݍX�V
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- ===============================
      -- �X�V����(A-5)
      -- ===============================
      upd_vdms_if_control(
         ov_errbuf       => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �x��������0�łȂ��ꍇ�͌x���Ƃ���
    IF ( gn_warn_cnt <> 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^������O�n���h��(����I��) ***
    WHEN no_output_data_expt THEN
      ov_retcode := cv_status_normal;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �t�@�C���N���[�Y
      IF ( utl_file.is_open(gf_file_handler) ) THEN
        utl_file.fclose(gf_file_handler);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y
      IF ( utl_file.is_open(gf_file_handler) ) THEN
        utl_file.fclose(gf_file_handler);
      END IF;
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
    errbuf          OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode         OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_update_from  IN  VARCHAR2      --   1.�ŏI�X�V�����i�J�n�j
   ,iv_update_to    IN  VARCHAR2      --   2.�ŏI�X�V�����i�I���j
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
       iv_update_from  -- �ŏI�X�V�����i�J�n�j
      ,iv_update_to    -- �ŏI�X�V�����i�I���j
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      -- ����
      gn_target_cnt := 0; -- �Ώی���
      gn_normal_cnt := 0; -- ���팏��
      gn_warn_cnt   := 0; -- �X�L�b�v����
      gn_error_cnt  := 1;
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
END XXCMM003A43C;
/
