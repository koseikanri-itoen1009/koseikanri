CREATE OR REPLACE PACKAGE BODY APPS.XXCMM003A42C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMM003A42C(body)
 * Description      : ���P�[�V�����}�X�^IF�o�́i���̋@�Ǘ��j
 * MD.050           : ���P�[�V�����}�X�^IF�o�́i���̋@�Ǘ��j MD050_CMM_003_A42
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  open_csv_file          �t�@�C���I�[�v������(A-2)
 *  get_target_cust_data   �Ώیڋq�擾����(A-3)
 *  get_detail_cust_data   �ڋq�ڍ׏��擾(A-4)
 *                         �֑������`�F�b�N����(A-5)
 *                         CSV�o�͏���(A-6)
 *  upd_vdms_if_control    �X�V����(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/02/04    1.0   K.Kiriu          �V�K�쐬
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
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM003A04C';               -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm    CONSTANT VARCHAR2(5)   := 'XXCMM';                      -- �}�X�^�̈�
  cv_app_name_xxccp    CONSTANT VARCHAR2(5)   := 'XXCCP';                      -- ���ʁEIF�̈�
  -- �v���t�@�C��
  cv_pro_out_file_dir  CONSTANT VARCHAR2(22)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- ���̋@CSV�t�@�C���o�͐�
  cv_pro_out_file_file CONSTANT VARCHAR2(22)  := 'XXCMM1_003A42_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  -- �g�[�N��
  cv_tkn_param         CONSTANT VARCHAR2(5)   := 'PARAM';                      -- ���̓p�����[�^
  cv_tkn_value         CONSTANT VARCHAR2(5)   := 'VALUE';                      -- ���̓p�����[�^�l
  cv_tkn_from_value    CONSTANT VARCHAR2(10)  := 'FROM_VALUE';                 -- �p�����[�^FROM
  cv_tkn_to_value      CONSTANT VARCHAR2(8)   := 'TO_VALUE';                   -- �p�����[�^TO
  cv_tok_ng_profile    CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C��
  cv_tok_filename      CONSTANT VARCHAR2(9)   := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_table         CONSTANT VARCHAR2(5)   := 'TABLE';                      -- �e�[�u����
  cv_tkn_ng_err        CONSTANT VARCHAR2(7)   := 'ERR_MSG';                    -- SQLERRM
  cv_tok_rangefrom     CONSTANT VARCHAR2(10)  := 'RANGE_FROM';                 -- �͈́i�J�n�j
  cv_tok_rangeto       CONSTANT VARCHAR2(8)   := 'RANGE_TO';                   -- �͈́i�I���j
  cv_tkn_ng_value      CONSTANT VARCHAR2(8)   := 'NG_VALUE';                   -- ���ږ�
  cv_tkn_word          CONSTANT VARCHAR2(7)   := 'NG_WORD';                    -- ���ږ�
  cv_tkn_data          CONSTANT VARCHAR2(7)   := 'NG_DATA';                    -- �f�[�^
  -- ���b�Z�[�W
  cv_msg_00001         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- �Ώۃf�[�^����
  cv_msg_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_00010         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00037         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- ���̓p�����[�^
  cv_msg_00049         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00049';           -- �����i�ŏI�X�V�����iFROM�j�j
  cv_msg_00050         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00050';           -- �����i�ŏI�X�V�����iTO�j�j
  cv_msg_00051         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00051';           -- �����iXXCMM:���̋@(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�j
  cv_msg_00052         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00052';           -- ���o�G���[
  cv_msg_00053         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00053';           -- �擾�͈�
  cv_msg_00054         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00054';           -- �}���G���[
  cv_msg_00055         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00055';           -- �X�V�G���[
  cv_msg_00056         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00056';           -- �p�����[�^�w��G���[
  cv_msg_00216         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00216';           -- �֑��������݃`�F�b�N���b�Z�[�W
  cv_msg_00385         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00385';           -- �����iXXCMM:���P�[�V�����}�X�^IF�o�́i���̋@�Ǘ��j�A�g�pCSV�t�@�C�����j
  cv_msg_00386         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00386';           -- �����i���̋@S�A�g����e�[�u���j
  cv_msg_00387         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00387';           -- �����i���̋@S�A�g���P�[�V�����ꎞ�\�j
  cv_msg_00388         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00388';           -- �����i�ڋq�R�[�h�j
  cv_msg_00389         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00389';           -- �����i�ݒu�於�i�Ж��j�j
  cv_msg_00390         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00390';           -- �����i�ݒu��J�i�j
  cv_msg_00391         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00391';           -- �����i�ݒu��FAX�j
  cv_msg_05132         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  -- �Q�ƃ^�C�v
  cv_cust_class        CONSTANT VARCHAR2(22)  := 'XXCMM_VD_CUSTOMER_CODE';     -- ���̋@S�A�g�Ώیڋq�敪
  cv_cust_vd_place     CONSTANT VARCHAR2(26)  := 'XXCMM_CUST_VD_SECCHI_BASYO'; -- VD�ݒu�ꏊ
  -- ���s�t���O
  cv_flg_t             CONSTANT VARCHAR2(1)   := 'T';                          -- ���s�t���O(T:���)
  cv_flg_r             CONSTANT VARCHAR2(1)   := 'R';                          -- ���s�t���O(R:����(���J�o��))
  -- �֑������`�F�b�N�p
  cv_chk_cd            CONSTANT VARCHAR2(22)  := 'VENDING_MACHINE_SYSTEM';     -- ���̋@�V�X�e���`�F�b�N
  -- �ėp
  cv_date_time         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';      -- �����t�H�[�}�b�g
  cv_date              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                   -- ���t�t�H�[�}�b�g
  cn_one               CONSTANT NUMBER(1)     := 1;                            -- �ėp NUMBER1
  cv_one               CONSTANT NUMBER(1)     := '1';                          -- �ėp VARCHAR1
  cv_y                 CONSTANT VARCHAR(1)    := 'Y';                          -- �ėp 'Y'
  cv_n                 CONSTANT VARCHAR(1)    := 'N';                          -- �ėp 'N'
  -- ����
  cv_language_ja       CONSTANT VARCHAR2(2)   := 'JA';                         -- ����(JA)
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
  gd_from_date          DATE;                                                  -- �ŏI�X�V���i�J�n�j
  gd_to_date            DATE;                                                  -- �ŏI�X�V���i�I���j
  gv_run_flg            VARCHAR2(1);                                           -- ���s�t���O(T:����AR:����(���J�o��))
  -- �t�@�C���o�͊֘A
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;   -- CSV�t�@�C���o�͐�
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;   -- CSV�t�@�C����
  gf_file_handler       utl_file.file_type;                                    -- CSV�t�@�C���o�͗p�n���h��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from   IN  VARCHAR2,     -- 1.�ŏI�X�V���i�J�n�j
    iv_update_to     IN  VARCHAR2,     -- 1.�ŏI�X�V���i�I���j
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_process_date           DATE;            -- �O����s����
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
    -- ============================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- ============================================================
    -- ���̓p�����[�^
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm      -- �}�X�^�̈�
                  ,iv_name         => cv_msg_00037           -- ���b�Z�[�W:���̓p�����[�^�o�̓��b�Z�[�W
                  ,iv_token_name1  => cv_tkn_param           -- �g�[�N��  :PARAM
                  ,iv_token_value1 => cv_msg_00049           -- �l        :�ŏI�X�V����(FROM)
                  ,iv_token_name2  => cv_tkn_value           -- �g�[�N��  :VALUE
                  ,iv_token_value2 => iv_update_from         -- �l        :���̓p�����[�^�u�ŏI�X�V����(FROM)�v�̒l
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm      -- �}�X�^�̈�
                  ,iv_name         => cv_msg_00037           -- ���b�Z�[�W:���̓p�����[�^�o�̓��b�Z�[�W
                  ,iv_token_name1  => cv_tkn_param           -- �g�[�N��  :PARAM
                  ,iv_token_value1 => cv_msg_00050           -- �l        :�ŏI�X�V����(TO)
                  ,iv_token_name2  => cv_tkn_value           -- �g�[�N��  :VALUE
                  ,iv_token_value2 => iv_update_to           -- �l        :���̓p�����[�^�u�ŏI�X�V����(TO)�v�̒l
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
--
    ----------------------------------------------------------------
    -- 1.�Ɩ����t�擾���s���܂��B
    ----------------------------------------------------------------
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    ----------------------------------------------------------------
    -- 2�D����E���������̏���������s���܂��B
    ----------------------------------------------------------------
--
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
    -- 3�D����E���������̒��o�J�n�A�I�����Ԃ��擾���܂��B
    ----------------------------------------------------------------
--
    -- ���o�����ݒ�
    IF ( gv_run_flg = cv_flg_t ) THEN
      -- ���������
      BEGIN
        -- ���̋@S�A�g����e�[�u����莩�̋@S�A�g����(�O����s����)���擾
        SELECT xvic.vdms_interface_date vdms_interface_date
        INTO   ld_process_date
        FROM   xxcmm_vdms_if_control xvic
        WHERE  control_id = cn_one  --����ID�i���P�[�V�����}�X�^IF�o��)
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
      gd_from_date := ld_process_date;     -- �O��A�g��������
      gd_to_date   := cd_last_update_date; -- ���s����SYSTEM���t�܂�
    ELSE
      -- ����(�đ��M)��
      gd_from_date := TO_DATE( iv_update_from, cv_date_time);  --�p�����[�^�w��i�J�n�j����
      gd_to_date   := TO_DATE( iv_update_to,   cv_date_time);  --�p�����[�^�w��i�I���j�܂�
    END IF;
--
    ----------------------------------------------------------------
    -- 4�D���������̏ꍇ�A�p�����[�^�̎w��`�F�b�N���s���܂��B
    ----------------------------------------------------------------
--
    -- ����(�đ��M)��
    IF ( gv_run_flg = cv_flg_r ) THEN
      -- �p�����[�^�w��������b�̎w��`�F�b�N
      IF ( gd_from_date >= gd_to_date ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm   -- �}�X�^�̈�
                      ,iv_name         => cv_msg_00056        -- ���b�Z�[�W:�p�����[�^�w��G���[
                      ,iv_token_name1  => cv_tkn_from_value   -- �g�[�N��  :FROM_VALUE
                      ,iv_token_value1 => cv_msg_00049        -- �l        :�ŏI�X�V����(FROM)
                      ,iv_token_name2  => cv_tkn_to_value     -- �g�[�N��  :TO_VALUE
                      ,iv_token_value2 => cv_msg_00050        -- �l        :�ŏI�X�V����(TO)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    ----------------------------------------------------------------
    -- 5�D�v���t�@�C���̎擾���s���܂��B
    ----------------------------------------------------------------
--
    -- XXCMM:���̋@(OUTBOUND)�A�g�pCSV�t�@�C���o�͐���擾
    gv_csv_file_dir    := fnd_profile.value( cv_pro_out_file_dir );
    -- XXCMM:���̋@(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00002         -- ���b�Z�[�W:�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��  :NG_PROFILE
                    ,iv_token_value1 => cv_msg_00051         -- �l        :CSV�t�@�C���o�͐�
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXCMM:���P�[�V�����}�X�^�i���̋@�Ǘ��j�A�g�pCSV�t�@�C�������擾
    gv_csv_file_name    := fnd_profile.value( cv_pro_out_file_file );
    -- XXCMM:���P�[�V�����}�X�^�i���̋@�Ǘ��j�A�g�pCSV�t�@�C�����̎擾���e�`�F�b�N
    IF ( gv_csv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm    -- �}�X�^�̈�
                    ,iv_name         => cv_msg_00002         -- ���b�Z�[�W:�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��  :NG_PROFILE
                    ,iv_token_value1 => cv_msg_00385         -- �l        :CSV�t�@�C����
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    ----------------------------------------------------------------
    -- 6�DCSV�t�@�C�����݃`�F�b�N���s���܂��B
    ----------------------------------------------------------------
--
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
    -- �f�[�^�擾�J�n�E�I���̓������o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxcmm                      -- �}�X�^�̈�
                   ,iv_name         => cv_msg_00053                           -- ���b�Z�[�W:�f�[�^�擾�͈�
                   ,iv_token_name1  => cv_tok_rangefrom                       -- �g�[�N��  :RANGE_FROM
                   ,iv_token_value1 => TO_CHAR(gd_from_date,  cv_date_time)   -- �l        :���o�J�n�������b
                   ,iv_token_name2  => cv_tok_rangeto                         -- �g�[�N��  :RANGE_TO
                   ,iv_token_value2 => TO_CHAR(gd_to_date,    cv_date_time)   -- �l        :���o�I���������b
                  );
    -- �f�[�^�擾�͈͂��R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- �t�@�C�����̏o�̓��b�Z�[�W���擾
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
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    -- 1�DCSV�t�@�C����'W'(��������)�ŃI�[�v�����܂��B
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
   * Procedure Name   : get_target_cust_data
   * Description      : �Ώیڋq�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_cust_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_target_cust_data';   -- �v���O������
--
    cv_duns_number_c  CONSTANT VARCHAR2(2)   := '25';                     -- ���o�Ώۂ̌ڋq�X�e�[�^�X(SP���ٍ�)
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
      -- 1�D�p�[�e�B�̓o�^�E�ύX�f�[�^�}������
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( hp )
               INDEX( hp xxcmm_hz_parties_n14 )
               USE_NL( hp hca flv )
             */
             hca.cust_account_id      cust_account_id     -- �ڋqID
      FROM   hz_parties               hp                  -- �p�[�e�B
            ,hz_cust_accounts         hca                 -- �ڋq�}�X�^
            ,fnd_lookup_values        flv                 -- �Q�ƃ^�C�v
      WHERE  hp.last_update_date   >= gd_from_date        -- ���o�J�n����(�����b)
      AND    hp.last_update_date   <  gd_to_date          -- ���o�I������(�����b)
      AND    hp.duns_number_c      >= cv_duns_number_c    -- �Ώۂ̌ڋq�X�e�[�^�X(SP���ٍψȍ~)
      AND    hp.party_id           =  hca.party_id
      AND    flv.lookup_type       =  cv_cust_class       -- ���̋@S�A�g�Ώیڋq�敪
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      ;
--
      ----------------------------------------------------------------
      -- 2�D�ڋq�ǉ����̓o�^�E�ύX�f�[�^�}������
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( xca )
               INDEX( xca xxcmm_cust_accounts_n20 )
               USE_NL( xca hca hp flv )
            */
             hca.cust_account_id      cust_account_id     -- �ڋqID
      FROM   xxcmm_cust_accounts      xca                 -- �ڋq�ǉ����
            ,hz_cust_accounts         hca                 -- �ڋq�}�X�^
            ,hz_parties               hp                  -- �p�[�e�B
            ,fnd_lookup_values        flv                 -- �Q�ƃ^�C�v
      WHERE  xca.last_update_date  >= gd_from_date        -- ���o�J�n����(�����b)
      AND    xca.last_update_date  <  gd_to_date          -- ���o�I������(�����b)
      AND    xca.customer_id       =  hca.cust_account_id
      AND    hca.party_id          =  hp.party_id
      AND    hp.duns_number_c      >= cv_duns_number_c    -- �Ώۂ̌ڋq�X�e�[�^�X(SP���ٍψȍ~)
      AND    flv.lookup_type       =  cv_cust_class       -- ���̋@S�A�g�Ώیڋq�敪
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      AND    NOT EXISTS(
               SELECT /*+
                        USE_NL(xtvli)
                      */
                      1
               FROM   xxcmm_tmp_vdms_location_if xtvli
               WHERE  xtvli.cust_account_id = hca.cust_account_id
             )  --�p�[�e�B��INSERT�ő}�����ꂽ�ڋq�͑ΏۊO�Ƃ���B
      ;
--
      ----------------------------------------------------------------
      -- 3�D�ڋq���Ə��̓o�^�E�ύX�f�[�^�}������
      ----------------------------------------------------------------
      INSERT INTO xxcmm_tmp_vdms_location_if(
         cust_account_id
      )
      SELECT /*+
               LEADING( hl )
               INDEX( hl xxcmm_hz_locations_n13 )
               USE_NL( hl hps hcas hca hp flv )
             */
             hca.cust_account_id      cust_account_id     -- �ڋqID
      FROM   hz_locations             hl                  -- �ڋq���Ə�
            ,hz_party_sites           hps                 -- �p�[�e�B�T�C�g
            ,hz_cust_acct_sites       hcas                -- �ڋq�T�C�g
            ,hz_cust_accounts         hca                 -- �ڋq�}�X�^
            ,hz_parties               hp                  -- �p�[�e�B
            ,fnd_lookup_values        flv                 -- �Q�ƃ^�C�v
      WHERE  hl.last_update_date   >= gd_from_date
      AND    hl.last_update_date   <  gd_to_date
      AND    hl.location_id        =  hps.location_id
      AND    hps.party_site_id     =  hcas.party_site_id
      AND    hcas.cust_account_id  =  hca.cust_account_id
      AND    hca.party_id          =  hp.party_id
      AND    hp.duns_number_c      >= cv_duns_number_c    -- �Ώۂ̌ڋq�X�e�[�^�X(SP���ٍψȍ~)
      AND    flv.lookup_type       =  cv_cust_class       -- ���̋@S�A�g�Ώیڋq�敪
      AND    flv.lookup_code       =  hca.customer_class_code
      AND    flv.enabled_flag      =  cv_y
      AND    flv.language          =  cv_language_ja
      AND    gd_process_date       BETWEEN flv.start_date_active
                                   AND     NVL( flv.end_date_active, gd_process_date )
      AND    NOT EXISTS(
               SELECT /*+
                        USE_NL(xtvli)
                      */
                      1
               FROM   xxcmm_tmp_vdms_location_if xtvli
               WHERE  xtvli.cust_account_id = hca.cust_account_id
             )  --�p�[�e�B�E�ڋq�ǉ�����INSERT�ő}�����ꂽ�ڋq�͑ΏۊO�Ƃ���B
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �}���G���[���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm  -- �}�X�^�̈�
                        ,iv_name         => cv_msg_00054       -- ���b�Z�[�W:�}���G���[
                        ,iv_token_name1  => cv_tkn_table       -- �g�[�N��  :TABLE
                        ,iv_token_value1 => cv_msg_00387       -- �l        :���̋@S�A�g���P�[�V�����ꎞ�\
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
  END get_target_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_cust_data
   * Description      : �ڋq�ڍ׏��擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_detail_cust_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_cust_data'; -- �v���O������
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
    cv_dqu           CONSTANT VARCHAR2(1)   := '"';    -- �_�u���N�H�[�e�[�V����(���蕶��)
    cv_area_code_1   CONSTANT VARCHAR2(2)   := '00';   -- ���o����NULL���̒l(�ݒu��s���{��CD)
    cv_area_code_2   CONSTANT VARCHAR2(3)   := '000';  -- ���o����NULL���̒l(�ݒu��s��SCD)
    cv_in_out_kbn    CONSTANT VARCHAR2(1)   := '1';    -- ���o����NULL���̒l(�����O�敪)
    cv_hyphen        CONSTANT VARCHAR2(1)   := '-';    -- NULL�ɒu�����镶��
--
    -- *** ���[�J���ϐ� ***
    lv_warning_flag  VARCHAR2(1);                      -- �x������p
    lv_csv_text      VARCHAR2(2000);                   -- �o�͂P�s��������ϐ�
--
    -- *** ���[�J����O ***
    output_skip_expt EXCEPTION;                        -- CSV�t�@�C���o�̓X�L�b�v��O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �o�͑Ώیڋq���擾�J�[�\��
    CURSOR get_cust_cur
    IS
      SELECT /*+
               LEADING( xtvli )
               USE_NL( xtvli hca hp xca hcas hps hl )
             */
              hca.account_number                                         account_number              -- ���PCD
             ,NULL                                                       branch_base                 -- �x�ЃR�[�h
             ,( SELECT  SUBSTRB( hlb.address3, 1, 2 ) address3
                FROM    hz_cust_accounts    hcab                      -- �ڋq�}�X�^
                       ,hz_cust_acct_sites  hcasb                     -- �ڋq�T�C�g
                       ,hz_party_sites      hpsb                      -- �p�[�e�B�T�C�g
                       ,hz_locations        hlb                       -- �ڋq���Ə�
                WHERE  hcab.account_number      = xca.sale_base_code
                AND    hcab.customer_class_code = cv_one              -- ���_
                AND    hcab.cust_account_id     = hcasb.cust_account_id
                AND    hcasb.party_site_id      = hpsb.party_site_id
                AND    hpsb.location_id         = hlb.location_id
              )                                                          area_code                   -- �x�XCD
             ,xca.sale_base_code                                         sale_base_code              -- �c�Ə�CD
             ,NULL                                                       loot_man_code               -- ���[�g�}���R�[�h
             ,SUBSTRB( hp.party_name, 1, 100)                            party_name                  -- �ݒu�於�i�Ж��j
             ,NULL                                                       party_name_abbreviation     -- �ݒu�旪��
             ,SUBSTRB( hp.organization_name_phonetic, 1, 50 )            organization_name_phonetic  -- �ݒu���
             ,NULL                                                       party_name_header           -- �ݒu�於������
             ,hl.postal_code                                             postal_code                 -- �ݒu��X�֔ԍ�
             ,NVL( SUBSTRB( hl.address3, 1, 2 ), cv_area_code_1 )        area_code_1                 -- �ݒu��s���{��CD
             ,NVL( SUBSTRB( hl.address3, 3, 3 ), cv_area_code_2 )        area_code_2                 -- �ݒu��s��SCD
             ,hl.state||hl.city                                          state_city                  -- �ݒu��Z���P
             ,SUBSTRB( hl.address1, 1, 150)                              address1                    -- �ݒu��Z���Q
             ,SUBSTRB( hl.address2, 1, 150)                              address2                    -- �ݒu��Z���R
             ,SUBSTRB( REPLACE( hl.address_lines_phonetic, cv_hyphen ), 1, 20 )
                                                                         address_lines_phonetic      -- �ݒu��TEL
             ,SUBSTRB( REPLACE( hl.address4, cv_hyphen ), 1, 20 )        address4                    -- �ݒu��FAX
             ,NULL                                                       address_url                 -- �ݒu��t�q�k
             ,xca.business_low_type                                      business_low_type           -- ����`�ԋ敪
             ,NULL                                                       location_kbn                -- ���P�[�V�����敪
             ,NULL                                                       customers                   -- ���Ӑ�CD
             ,TO_CHAR( xca.start_tran_date,    cv_date )                 start_tran_date             -- ����J�n��
             ,TO_CHAR( xca.stop_approval_date, cv_date )                 stop_approval_date          -- ������~��
             ,NVL(
                   ( SELECT  flv.attribute1    attribute1
                      FROM   fnd_lookup_values flv
                      WHERE  flv.lookup_type     = cv_cust_vd_place
                      AND    flv.lookup_code     = xca.establishment_location
                      AND    flv.enabled_flag    = cv_y
                      AND    flv.language        = cv_language_ja
                      AND    gd_process_date     BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND     NVL( flv.end_date_active,   gd_process_date )
                   )
                  ,cv_in_out_kbn
              )                                                          in_and_out_kbn              -- �����O�敪
             ,NULL                                                       chain_store_code            -- �`�F�[��CD
             ,SUBSTRB(industry_div, 1, 1)                                industry_div_1              -- ��Ǝ�CD
             ,SUBSTRB(industry_div, 2, 1)                                industry_div_2              -- ���Ǝ�CD
             ,hp.duns_number_c                                           duns_number_c               -- �ڋq�X�e�[�^�X
             ,NULL                                                       creation_date               -- ں��ލ쐬��
             ,NULL                                                       creation_pg                 -- ں��ލ쐬PG
             ,NULL                                                       created_by                  -- ں��ލ쐬��
             ,NULL                                                       last_update_date            -- ں��ލX�V��
             ,NULL                                                       last_update_pg              -- ں��ލX�VPG
             ,NULL                                                       last_updated_by             -- ں��ލX�V��
             ,NULL                                                       delete_date                 -- ں��ލ폜��
             ,NULL                                                       delete_pg                   -- ں��ލ폜PG
             ,NULL                                                       deleted_by                  -- ں��ލ폜��
      FROM    xxcmm_tmp_vdms_location_if xtvli -- ���̋@S�A�g���P�[�V�����ꎞ�\
             ,hz_cust_accounts           hca   -- �ڋq�}�X�^
             ,hz_parties                 hp    -- �p�[�e�B
             ,xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
             ,hz_cust_acct_sites         hcas  -- �ڋq�T�C�g
             ,hz_party_sites             hps   -- �p�[�e�B�T�C�g
             ,hz_locations               hl    -- �ڋq���Ə�
      WHERE   xtvli.cust_account_id    = hca.cust_account_id
      AND     hca.party_id             = hp.party_id
      AND     hca.cust_account_id      = xca.customer_id
      AND     hca.cust_account_id      = hcas.cust_account_id
      AND     hcas.party_site_id       = hps.party_site_id
      AND     hps.location_id          = hl.location_id
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
    <<get_cust_loop>>
    FOR get_cust_rec IN get_cust_cur LOOP
--
      -- ������
      lv_warning_flag := cv_n;  -- �x���t���O
      -- �Ώی����J�E���g
      gn_target_cnt   := gn_target_cnt + 1;
--
      BEGIN
--
        -- ===============================
        -- �֑������`�F�b�N����(A-5)
        -- ===============================
--
        -- �ݒu�於�i�Ж��j
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.party_name, cv_chk_cd) = FALSE) THEN
          -- �֑��������݃`�F�b�N���b�Z�[�W����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- �}�X�^�̈�
                        ,iv_name         => cv_msg_00216                  -- ���b�Z�[�W:�֑��������݃`�F�b�N���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_ng_value               -- �g�[�N��  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00389                  -- �l        :�ݒu�於�i�Ж��j
                        ,iv_token_name2  => cv_tkn_word                   -- �g�[�N��  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- �l        :�ڋq�R�[�h
                        ,iv_token_name3  => cv_tkn_data                   -- �g�[�N��  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- �l        :�擾�����ڋq�R�[�h�̒l
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --�t���OON
          lv_warning_flag := cv_y;
        END IF;
        -- �ݒu���
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.organization_name_phonetic, cv_chk_cd) = FALSE) THEN
          -- �֑��������݃`�F�b�N���b�Z�[�W����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- �}�X�^�̈�
                        ,iv_name         => cv_msg_00216                  -- ���b�Z�[�W:�֑��������݃`�F�b�N���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_ng_value               -- �g�[�N��  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00390                  -- �l        :�ݒu��J�i
                        ,iv_token_name2  => cv_tkn_word                   -- �g�[�N��  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- �l        :�ڋq�R�[�h
                        ,iv_token_name3  => cv_tkn_data                   -- �g�[�N��  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- �l        :�擾�����ڋq�R�[�h�̒l
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- �t���OON
          lv_warning_flag := cv_y;
        END IF;
        -- �ݒu��FAX
        IF (xxccp_common_pkg2.chk_moji(get_cust_rec.address4, cv_chk_cd) = FALSE) THEN
          -- �֑��������݃`�F�b�N���b�Z�[�W����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_xxcmm             -- �}�X�^�̈�
                        ,iv_name         => cv_msg_00216                  -- ���b�Z�[�W:�֑��������݃`�F�b�N���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_ng_value               -- �g�[�N��  :NG_VALUE
                        ,iv_token_value1 => cv_msg_00391                  -- �l        :�ݒu��FAX
                        ,iv_token_name2  => cv_tkn_word                   -- �g�[�N��  :NG_WORD
                        ,iv_token_value2 => cv_msg_00388                  -- �l        :�ڋq�R�[�h
                        ,iv_token_name3  => cv_tkn_data                   -- �g�[�N��  :NG_DATA
                        ,iv_token_value3 => get_cust_rec.account_number   -- �l        :�擾�����ڋq�R�[�h�̒l
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- �t���OON
          lv_warning_flag := cv_y;
        END IF;
--
        -- �`�F�b�N�G���[��
        IF ( lv_warning_flag = cv_y ) THEN
          -- CSV�o�͏���(A-6)���X�L�b�v����
          RAISE output_skip_expt;
        END IF;
--
        -- ===============================
        -- CSV�o�͏���(A-6)
        -- ===============================
--
        ----------------------------------------------------------------
        -- 1.�o�͍��ڕҏW
        ----------------------------------------------------------------
        lv_csv_text :=
            cv_dqu || get_cust_rec.account_number             || cv_dqu || cv_com ||  -- ���PCD
            cv_dqu || get_cust_rec.branch_base                || cv_dqu || cv_com ||  -- �x�ЃR�[�h
            cv_dqu || get_cust_rec.area_code                  || cv_dqu || cv_com ||  -- �x�XCD
            cv_dqu || get_cust_rec.sale_base_code             || cv_dqu || cv_com ||  -- �c�Ə�CD
            cv_dqu || get_cust_rec.loot_man_code              || cv_dqu || cv_com ||  -- ���[�g�}���R�[�h
            cv_dqu || get_cust_rec.party_name                 || cv_dqu || cv_com ||  -- �ݒu�於�i�Ж��j
            cv_dqu || get_cust_rec.party_name_abbreviation    || cv_dqu || cv_com ||  -- �ݒu�旪��
            cv_dqu || get_cust_rec.organization_name_phonetic || cv_dqu || cv_com ||  -- �ݒu���
            cv_dqu || get_cust_rec.party_name_header          || cv_dqu || cv_com ||  -- �ݒu�於������
            cv_dqu || get_cust_rec.postal_code                || cv_dqu || cv_com ||  -- �ݒu��X�֔ԍ�
            cv_dqu || get_cust_rec.area_code_1                || cv_dqu || cv_com ||  -- �ݒu��s���{��CD
            cv_dqu || get_cust_rec.area_code_2                || cv_dqu || cv_com ||  -- �ݒu��s��SCD
            cv_dqu || get_cust_rec.state_city                 || cv_dqu || cv_com ||  -- �ݒu��Z���P
            cv_dqu || get_cust_rec.address1                   || cv_dqu || cv_com ||  -- �ݒu��Z���Q
            cv_dqu || get_cust_rec.address2                   || cv_dqu || cv_com ||  -- �ݒu��Z���R
            cv_dqu || get_cust_rec.address_lines_phonetic     || cv_dqu || cv_com ||  -- �ݒu��TEL
            cv_dqu || get_cust_rec.address4                   || cv_dqu || cv_com ||  -- �ݒu��FAX
            cv_dqu || get_cust_rec.address_url                || cv_dqu || cv_com ||  -- �ݒu��t�q�k
            cv_dqu || get_cust_rec.business_low_type          || cv_dqu || cv_com ||  -- ����`�ԋ敪
            cv_dqu || get_cust_rec.location_kbn               || cv_dqu || cv_com ||  -- ���P�[�V�����敪
            cv_dqu || get_cust_rec.customers                  || cv_dqu || cv_com ||  -- ���Ӑ�CD
            cv_dqu || get_cust_rec.start_tran_date            || cv_dqu || cv_com ||  -- ����J�n��
            cv_dqu || get_cust_rec.stop_approval_date         || cv_dqu || cv_com ||  -- ������~��
            cv_dqu || get_cust_rec.in_and_out_kbn             || cv_dqu || cv_com ||  -- �����O�敪
            cv_dqu || get_cust_rec.chain_store_code           || cv_dqu || cv_com ||  -- �`�F�[��CD
            cv_dqu || get_cust_rec.industry_div_1             || cv_dqu || cv_com ||  -- ��Ǝ�CD
            cv_dqu || get_cust_rec.industry_div_2             || cv_dqu || cv_com ||  -- ���Ǝ�CD
            cv_dqu || get_cust_rec.duns_number_c              || cv_dqu || cv_com ||  -- �ڋq�X�e�[�^�X
            cv_dqu || get_cust_rec.creation_date              || cv_dqu || cv_com ||  -- ں��ލ쐬��
            cv_dqu || get_cust_rec.creation_pg                || cv_dqu || cv_com ||  -- ں��ލ쐬PG
            cv_dqu || get_cust_rec.created_by                 || cv_dqu || cv_com ||  -- ں��ލ쐬��
            cv_dqu || get_cust_rec.last_update_date           || cv_dqu || cv_com ||  -- ں��ލX�V��
            cv_dqu || get_cust_rec.last_update_pg             || cv_dqu || cv_com ||  -- ں��ލX�VPG
            cv_dqu || get_cust_rec.last_updated_by            || cv_dqu || cv_com ||  -- ں��ލX�V��
            cv_dqu || get_cust_rec.delete_date                || cv_dqu || cv_com ||  -- ں��ލ폜��
            cv_dqu || get_cust_rec.delete_pg                  || cv_dqu || cv_com ||  -- ں��ލ폜PG
            cv_dqu || get_cust_rec.deleted_by                 || cv_dqu               -- ں��ލ폜��
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
      EXCEPTION
        -- �֑������G���[
        WHEN output_skip_expt THEN
          gn_warn_cnt := gn_warn_cnt + 1;  --�ڋq�P�ʂɌx���������J�E���g
      END;
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
  END get_detail_cust_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vdms_if_control
   * Description      : �X�V����(A-7)
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
      -- 1.���̋@S�A�g����̍X�V
      ----------------------------------------------------------------
      UPDATE  xxcmm_vdms_if_control xvif
      SET     xvif.vdms_interface_date    = gd_to_date                 -- ���o�I������
             ,xvif.last_updated_by        = cn_last_updated_by
             ,xvif.last_update_date       = cd_last_update_date
             ,xvif.last_update_login      = cn_last_update_login
             ,xvif.request_id             = cn_request_id
             ,xvif.program_application_id = cn_program_application_id
             ,xvif.program_id             = cn_program_id
             ,xvif.program_update_date    = cd_program_update_date
      WHERE  xvif.control_id = cn_one
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
    iv_update_from  IN  VARCHAR2,     -- 1.�ŏI�X�V���i�J�n�j
    iv_update_to    IN  VARCHAR2,     -- 2.�ŏI�X�V���i�I���j
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
       iv_update_from  => iv_update_from  -- �ŏI�X�V���i�J�n�j
      ,iv_update_to    => iv_update_to    -- �ŏI�X�V���i�I���j
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
    -- �Ώیڋq�擾����(A-3)
    -- ===============================
    get_target_cust_data(
       ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ڋq�ڍ׏��擾����(A-4)
    -- ===============================
    get_detail_cust_data(
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
      -- �X�V����(A-7)
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_update_from  IN  VARCHAR2,      --   1.�ŏI�X�V���i�J�n�j
    iv_update_to    IN  VARCHAR2       --   2.�ŏI�X�V���i�I���j
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
       iv_update_from  -- �ŏI�X�V���i�J�n�j
      ,iv_update_to    -- �ŏI�X�V���i�I���j
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
END XXCMM003A42C;
/
