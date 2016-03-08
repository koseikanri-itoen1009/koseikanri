CREATE OR REPLACE PACKAGE BODY APPS.XXCSO015A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCSO015A07C(body)
 * Description      : �_��ɂăI�[�i�[�ύX�������������A���̋@�Ǘ��V�X�e����
 *                    �ڋq�ƕ�����A�g���邽�߂ɁACSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_���̋@-EBS�C���^�t�F�[�X�F�iOUT�j�jEBS���̋@�ύX
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                       (A-1)
 *  open_csv_file               CSV�t�@�C���I�[�v��            (A-2)
 *  upd_cont_manage             �_��Ǘ��e�[�u���X�V����       (A-5)
 *  create_csv_rec              EBS���̋@�ύX�f�[�^CSV�o��     (A-6)
 *  close_csv_file              CSV�t�@�C���N���[�Y����        (A-7)
 *  submain                     ���C�������v���V�[�W��
 *                                EBS���̋@�ύX�f�[�^���o����  (A-3)
 *                                �Z�[�u�|�C���g���s           (A-4)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                �I������                     (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016-02-22    1.0   Y.Shoji          �V�K�쐬
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO015A07C';      -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_xxcso00496       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- �p�����[�^�o��
  cv_msg_xxcso00796       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00796';  -- �Ώۓ�
  cv_msg_xxcso00797       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00797';  -- �Ώێ���
  cv_msg_xxcso00012       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- ���t�����G���[���b�Z�[�W
  cv_msg_xxcso00014       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_xxcso00152       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_msg_xxcso00123       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_msg_xxcso00015       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_xxcso00224       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0�����b�Z�[�W
  cv_msg_xxcso00024       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_xxcso00075       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00075';  -- �����G���[2
  cv_msg_xxcso00696       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- �����R�[�h
  cv_msg_xxcso00159       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00159';  -- �֑������`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcso00798       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00798';  -- �ݒu�於�i�Ж��j
  cv_msg_xxcso00799       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00799';  -- �ݒu���
  cv_msg_xxcso00800       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00800';  -- �_��Ǘ��e�[�u��
  cv_msg_xxcso00801       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00801';  -- �_�񏑔ԍ�
  cv_msg_xxcso00241       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00241';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_xxcso00782       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00782';  -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_xxcso00793       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00793';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W�iEBS���̋@�ύX�j
  cv_msg_xxcso00794       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00794';  -- ����A�g���b�Z�[�W�iEBS���̋@�ύX�j
  cv_msg_xxcso00018       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[���b�Z�[�W
--
  -- �g�[�N���R�[�h
  cv_tkn_param_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_message          CONSTANT VARCHAR2(20) := 'MESSAGE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_file_name    CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_csv_location     CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_column           CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_digit            CONSTANT VARCHAR2(20) := 'DIGIT';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_item_value       CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
  cv_tkn_check_range      CONSTANT VARCHAR2(20) := 'CHECK_RANGE';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_install_code     CONSTANT VARCHAR2(20) := 'INSTALL_CODE';
  cv_tkn_cont_num         CONSTANT VARCHAR2(20) := 'CONT_NUM';
--;
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< SYSTEM DATE >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< PROFILE VALUE >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< CSV FILE OPEN >>' ;
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< CSV FILE CLOSE >>' ;
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< ROLLBACK >>' ;
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'GET DATA�@';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'contract_number = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'install_code = ';
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< EXCEPTION : CSV FILE CLOSE >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< CURSOR OPEN >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< CURSOR CLOSE >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< EXCEPTION : CURSOR CLOSE >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others exception';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'global_process_expt';
--
  cv_yes                  CONSTANT VARCHAR2(1)  := 'Y';                      -- �ėp�Œ�l�uY�v
  cv_no                   CONSTANT VARCHAR2(1)  := 'N';                      -- �ėp�Œ�l�uN�v
  cb_true                 CONSTANT BOOLEAN      := TRUE;
  cv_half_space           CONSTANT VARCHAR2(1)  := ' ';
  cv_format_date_time     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';  -- ���t�t�H�[�}�b�g(YYYY/MD/DD HH24:MI:SS)
  cv_format_date          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';               -- ���t�t�H�[�}�b�g(YYYYMDDD)
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_proc_date        VARCHAR2(100);                                     -- �Ώۓ�
  gv_proc_time        VARCHAR2(100);                                     -- �Ώێ���
  gv_proc_date_time   VARCHAR2(100);                                     -- �Ώۓ���
  gd_proc_date_time   DATE;                                              -- �Ώۓ���
--
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ���[���o�b�N�t���O
  gb_rollback_upd_flg           BOOLEAN := FALSE;                        -- TRUE : ���[���o�b�N
--
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
     contract_number             xxcso_contract_managements.contract_number%TYPE         -- �_�񏑔ԍ�
    ,install_code                csi_item_instances.external_reference%TYPE              -- �����R�[�h
    ,install_account_number      xxcso_contract_managements.install_account_number%TYPE  -- �ڋq�R�[�h
    ,install_date                VARCHAR2(8)                                             -- �ݒu���i����J�n���j
    ,party_name                  hz_parties.party_name%TYPE                              -- �ݒu�於�i�Ж��j
    ,organization_name_phonetic  hz_parties.organization_name_phonetic%TYPE              -- �ݒu���
    ,address_lines_phonetic      hz_locations.address_lines_phonetic%TYPE                -- �ݒu��TEL
  );
--
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_expt           EXCEPTION;
  global_lock_expt           EXCEPTION;                                  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate           OUT DATE                 -- �V�X�e�����t
    ,ov_csv_dir           OUT NOCOPY VARCHAR2      -- CSV�t�@�C���o�͐�
    ,ov_csv_nm            OUT NOCOPY VARCHAR2      -- CSV�t�@�C����
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_false           CONSTANT VARCHAR2(100)   := 'FALSE';
    cb_false           CONSTANT BOOLEAN         := FALSE;
--
    -- �v���t�@�C����
    cv_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_DIR';     -- XXCSO:���̋@�Ǘ��V�X�e���A�g�pCSV�t�@�C���o�͐�
    cv_csv_nm          CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_VD_MOD';  -- XXCSO:���̋@�Ǘ��V�X�e���A�g�pCSV�t�@�C�����iEBS���̋@�ύX���j
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l
    lb_check_date_value       BOOLEAN;                    -- ���t�̏������f
    lv_csv_dir                VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_csv_nm                 VARCHAR2(2000);             -- CSV�t�@�C����
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value              VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                    VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- 1.�V�X�e�����t�擾����
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate, cv_format_date_time) || CHR(10) ||
                 ''
    );
--
    -- =================================
    -- 2.���̓p�����[�^���o��
    -- =================================
    -- �p�����[�^�Ώۓ�
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_xxcso00496
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_xxcso00796
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => gv_proc_date
              );
    -- �o�̓t�@�C���ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                  lv_msg
    );
    -- �p�����[�^�Ώێ���
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_xxcso00496
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_xxcso00797
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => gv_proc_time
              );
    -- �o�̓t�@�C���ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''
    );
--
    -- =================================
    -- 3.�������t�����`�F�b�N
    -- =================================
    -- �p�����[�^���uNULL�v�ł��邩�̃`�F�b�N
    IF (gv_proc_date_time IS NOT NULL) THEN
      --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYY/MM/DD HH24:MI:SS�j�ł��邩���m�F
      lb_check_date_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_proc_date || cv_half_space || gv_proc_time
                                   ,iv_date_format  => cv_format_date_time
      );
      --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
      IF (lb_check_date_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcso00012                              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value                                   -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_proc_date || cv_half_space || gv_proc_time  -- �g�[�N���l1�p�����[�^
                        ,iv_token_name2  => cv_tkn_status                                  -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_false                                       -- �g�[�N���l2���^�[���X�e�[�^�X
                        ,iv_token_name3  => cv_tkn_message                                 -- �g�[�N���R�[�h3
                        ,iv_token_value3 => NULL                                           -- �g�[�N���l3���^�[�����b�Z�[�W
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        gd_proc_date_time := TO_DATE(gv_proc_date || cv_half_space || gv_proc_time, cv_format_date_time);
      END IF;
    END IF;
--
    -- �ϐ�����������
    lv_tkn_value := NULL;
--
    -- =======================
    -- 4.�v���t�@�C���l�擾����
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    cv_csv_nm
                   ,lv_csv_nm
                   ); -- CSV�t�@�C����
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10)           ||
                 cv_debug_msg4  || lv_csv_dir        || CHR(10) ||
                 cv_debug_msg5  || lv_csv_nm         || CHR(10) ||
                 ''
    );
--
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_msg_xxcso00152     --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_csv_file_name  --�g�[�N���R�[�h1
                ,iv_token_value1 => lv_csv_nm             --�g�[�N���l1
              );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- ��s�̑}��
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- CSV�t�@�C���o�͐�擾���s��
    IF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_csv_nm;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcso00014            --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name             --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_csv_dir          :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm           :=  lv_csv_nm;           -- CSV�t�@�C����
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
   * Procedure Name   : open_csv_file
   * Description      : CSV�t�@�C���I�[�v��(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- �v���O������
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
    cv_w            CONSTANT VARCHAR2(1) := 'w';
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcso00123            --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h2
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v��
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6    || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcso00015     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_location   --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_file_name  --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm             --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage
   * Description      : �_��Ǘ��e�[�u���X�V����(A-5)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage(
     i_get_data_rec     IN     g_get_data_rtype        -- �o�͗pEBS���̋@�ύX���
    ,ib_break_flag      IN     BOOLEAN                 -- �u���[�N�t���O
    ,iv_error_flag      IN     VARCHAR2                -- �������ԍ��P�ʃG���[�t���O
    ,id_sysdate         IN     DATE                    -- �V�X�e�����t
    ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cont_manage';  -- �v���O������
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
    cn_install_code_max_legth     CONSTANT  NUMBER         := 9;                        -- �����R�[�h�ő包��
    cv_check_range                CONSTANT  VARCHAR2(30)   := 'VENDING_MACHINE_SYSTEM';
    cv_vdms_interface_flag_2      CONSTANT  VARCHAR2(1)    := '2';
--
    -- *** ���[�J���ϐ� ***
    lb_str_check_flg         BOOLEAN;                                              -- �֑������`�F�b�N�t���O
    lt_contract_number       xxcso_contract_managements.contract_number%TYPE;      -- �_�񏑔ԍ�
    lv_cont_num              VARCHAR2(12);                                         -- �_�񏑔ԍ��i���b�N�擾�p�j
--
    -- *** ���[�J���E��O ***
    update_error_expt       EXCEPTION;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �_�񏑔ԍ�
    lt_contract_number     := i_get_data_rec.contract_number;
--
    -- ============================
    -- �����R�[�h�̌����`�F�b�N
    -- ============================
    IF (LENGTHB(i_get_data_rec.install_code) > cn_install_code_max_legth) THEN
      -- �����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcso00075          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_column              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_xxcso00696          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_digit               -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cn_install_code_max_legth  -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE update_error_expt;
    END IF;
--
    -- ============================
    -- �֑������`�F�b�N����
    -- ============================
    -- �ݒu�於�i�Ж��j
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.party_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcso00159                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_xxcso00798                      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_value                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => i_get_data_rec.party_name              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_check_range                     -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_check_range                         -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- �ݒu���
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.organization_name_phonetic, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcso00159                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_xxcso00799                          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_value                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => i_get_data_rec.organization_name_phonetic  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_check_range                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_check_range                             -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- IN�p�����[�^��NULL�i������s�j�̎�
    IF ( gv_proc_date_time IS NULL ) THEN
      -- ����_�񏑔ԍ��̍Ō�̍s�ŃG���[���Ȃ��ꍇ�A���b�N�E�X�V���s��
      IF ( ( ib_break_flag = TRUE ) AND ( iv_error_flag = cv_no ) ) THEN
        -- ============================
        -- �X�V�O�̃��b�N����
        -- ============================
        BEGIN
          SELECT  xcm.contract_number cont_num
          INTO    lv_cont_num
          FROM    xxcso_contract_managements xcm
          WHERE   xcm.contract_number = lt_contract_number
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          -- ���b�N�Ɏ��s�����ꍇ�̗�O
          WHEN global_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_xxcso00241            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_msg_xxcso00801            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                           ,iv_token_value3 => lt_contract_number           -- �g�[�N���l3
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ�̗�O
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_xxcso00024            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                          );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- ==========================================
          -- �_��Ǘ��e�[�u���X�V����
          -- ==========================================
          UPDATE xxcso_contract_managements xcm
          SET    xcm.vdms_interface_flag    = cv_vdms_interface_flag_2  -- ���̋@S�A�g�t���O
                ,xcm.vdms_interface_date    = id_sysdate                -- ���̋@S�A�g��
                ,xcm.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
                ,xcm.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
                ,xcm.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xcm.request_id             = cn_request_id             -- �v��ID
                ,xcm.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xcm.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xcm.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE  xcm.contract_number = lt_contract_number
          ;
        EXCEPTION
          -- *** OTHERS��O�n���h�� ***
          WHEN OTHERS THEN
            -- �X�V���s���[���o�b�N�t���O�̐ݒ�
            gb_rollback_upd_flg := TRUE;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_xxcso00782            -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_msg_xxcso00800            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_msg_xxcso00801            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                           ,iv_token_value3 => lt_contract_number           -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_err_msg               -- �g�[�N���R�[�h4
                           ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
      END IF;
    END IF;
--
  EXCEPTION
--
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN update_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ������O�n���h�� ***
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
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_cont_manage;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : EBS���̋@�ύX�f�[�^CSV�o��(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_get_data_rec      IN  g_get_data_rtype    -- �o�͗pEBS���̋@�ύX���
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- �v���O������
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
    cv_sep_wquot      CONSTANT VARCHAR2(1)  := '"';
    cv_sep_com        CONSTANT VARCHAR2(1)  := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_data                    VARCHAR2(5000);                                   -- �ҏW�f�[�^�i�[
    lv_info                    VARCHAR2(5000);                                   -- ���탁�b�Z�[�W�i�[
    lt_log_contract_number     xxcso_contract_managements.contract_number%TYPE;  -- �_�񏑔ԍ�
    lt_log_install_code        csi_item_instances.external_reference%TYPE;       -- �����R�[�h
    -- *** ���[�J���E���R�[�h ***
    l_get_data_rec  g_get_data_rtype;        -- EBS���̋@�ύX���
    -- *** ���[�J����O ***
    file_put_line_expt     EXCEPTION;        -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_get_data_rec         := i_get_data_rec;
    -- �_�񏑔ԍ�
    lt_log_contract_number := l_get_data_rec.contract_number;
    -- �����R�[�h
    lt_log_install_code    := l_get_data_rec.install_code;
--
    -- ======================
    -- CSV�o�͏���
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data :=         cv_sep_wquot || l_get_data_rec.install_code               || cv_sep_wquot -- �����R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_account_number     || cv_sep_wquot -- �ڋq�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_date               || cv_sep_wquot -- �ݒu���i����J�n���j
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.party_name                 || cv_sep_wquot -- �ݒu�於�i�Ж��j
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.organization_name_phonetic || cv_sep_wquot -- �ݒu���
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.address_lines_phonetic     || cv_sep_wquot -- �ݒu��TEL
      ;
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
     lv_info := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_msg_xxcso00794            -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_cont_num              -- �g�[�N���R�[�h1
                  ,iv_token_value1 => lt_log_contract_number       -- �g�[�N���l1
                  ,iv_token_name2  => cv_tkn_install_code          -- �g�[�N���R�[�h2
                  ,iv_token_value2 => lt_log_install_code          -- �g�[�N���l2
     );
      -- ���ʂ����O�ɏo��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_info
      );
      -- ���ʂ��o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_info
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        -- �X�V���s���[���o�b�N�t���O�̐ݒ�
        gb_rollback_upd_flg := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcso00793            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_cont_num              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lt_log_contract_number       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
        );
        lv_errbuf := lv_errmsg;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y����(A-7)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7    || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- CSV�t�@�C���N���[�Y���s
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcso00018            --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_length_start           CONSTANT NUMBER       := 1;                  -- �J�n�ʒu�F1
    cn_length_100             CONSTANT NUMBER       := 100;                -- �����񒷁F100
    cn_length_50              CONSTANT NUMBER       := 50;                 -- �����񒷁F50
    cn_length_20              CONSTANT NUMBER       := 20;                 -- �����񒷁F20
    cv_hyphen                 CONSTANT VARCHAR2(1)  := '-';
    cv_vdms_interface_flag_1  CONSTANT VARCHAR2(1)  := '1';                -- ���̋@S�A�g�t���O�F1�i���A�g�j
    cv_vdms_interface_flag_2  CONSTANT VARCHAR2(1)  := '2';                -- ���̋@S�A�g�t���O�F2�i�A�g�ρj
    cv_comma                  CONSTANT VARCHAR2(1)  := ',';                -- ��؂蕶��
--
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    ld_sysdate                DATE;                                            -- �V�X�e�����t
    lv_csv_dir                VARCHAR2(2000);                                  -- CSV�t�@�C���o�͐�
    lv_csv_nm                 VARCHAR2(2000);                                  -- CSV�t�@�C����
    lb_fopn_retcd             BOOLEAN;                                         -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_break_flag             BOOLEAN;                                         -- �u���[�N����p
    lt_contract_number        xxcso_contract_managements.contract_number%TYPE; -- �u���[�N����p
    lv_error_flag             VARCHAR2(1);                                     -- �_�񏑔ԍ��P�ʃG���[����p�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_cont_manage_data_cur
    IS
      SELECT /*+
               LEADING( xcm )
               INDEX( xcm xxcso_contract_managements_n07 )
               USE_NL(xcm hca hcas hps hl hp cii)
               USE_CONCAT
             */
             xcm.contract_number                                                                    contract_number             -- �_�񏑔ԍ�
            ,REPLACE(cii.external_reference, cv_hyphen)                                             install_code                -- �����R�[�h�E�n�C�t������
            ,xcm.install_account_number                                                             install_account_number      -- �ڋq�R�[�h
            ,TO_CHAR(xcm.install_date, cv_format_date)                                              install_date                -- �ݒu���i����J�n���j
            ,SUBSTRB(hp.party_name, cn_length_start, cn_length_100)                                 party_name                  -- �ݒu�於�i�Ж��j�E100BYTE
            ,SUBSTRB(hp.organization_name_phonetic, cn_length_start, cn_length_50)                  organization_name_phonetic  -- �ݒu��ŁE50BYTE
            ,SUBSTRB(REPLACE(hl.address_lines_phonetic, cv_hyphen), cn_length_start, cn_length_20)  address_lines_phonetic      -- �ݒu��TEL�E�n�C�t�������E20BYTE
      FROM   xxcso_contract_managements  xcm        -- �_��Ǘ��e�[�u��
            ,apps.hz_cust_accounts       hca        -- �ڋq�}�X�^
            ,apps.hz_parties             hp         -- �p�[�e�B�}�X�^
            ,apps.hz_cust_acct_sites     hcas       -- �ڋq�T�C�g
            ,apps.hz_party_sites         hps        -- �p�[�e�B�T�C�g
            ,apps.hz_locations           hl         -- �ڋq���Ə�
            ,apps.csi_item_instances     cii        -- �����}�X�^�i�t�ѕ��j
      WHERE  (
               (
                     gv_proc_date_time       IS NULL                       -- IN�p�����[�^��NULL(������s�j
                 AND xcm.vdms_interface_flag  = cv_vdms_interface_flag_1   -- ���̋@S�A�g�t���O�F���A�g
               )
               OR
               (
                     gv_proc_date_time       IS NOT NULL                    -- IN�p�����[�^��NULL�ł͂Ȃ�(�蓮���s�j
                 AND xcm.vdms_interface_flag  = cv_vdms_interface_flag_2    -- ���̋@S�A�g�t���O�F�A�g��
                 AND xcm.vdms_interface_date  = gd_proc_date_time           -- ���̋@S�A�g��
               )
             )
      AND    xcm.install_account_id      = hca.cust_account_id
      AND    hca.party_id                = hp.party_id
      AND    hca.cust_account_id         = hcas.cust_account_id
      AND    hcas.party_site_id          = hps.party_site_id
      AND    hps.location_id             = hl.location_id
      AND    xcm.install_account_id      = cii.owner_party_account_id  --�w�肳�ꂽ�����i���̋@�{�́j�Ɠ����ڋq�̕����i�t�ѕ��j
      ORDER BY xcm.contract_number    -- �_�񏑔ԍ���
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_cont_manage_data_rec      get_cont_manage_data_cur%ROWTYPE;
    l_get_data_rec                  g_get_data_rtype;
    -- *** ���[�J���E�e�[�u���^ ***
    TYPE l_get_cont_manage_data_ttype IS TABLE OF get_cont_manage_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE g_get_data_ttype             IS TABLE OF g_get_data_rtype INDEX BY BINARY_INTEGER;
    l_get_cont_manage_data_tab  l_get_cont_manage_data_ttype; -- �J�[�\���f�[�^�ꊇ�擾�p
    l_get_data_tbl              g_get_data_ttype;             -- �_�񏑔ԍ��P�ʂ̕ێ��p
    -- *** ���[�J����O ***
    no_data_expt       EXCEPTION;
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
    -- ================================
    -- A-1.��������
    -- ================================
    init(
       od_sysdate            => ld_sysdate          -- �V�X�e�����t
      ,ov_csv_dir            => lv_csv_dir          -- CSV�t�@�C���o�͐�
      ,ov_csv_nm             => lv_csv_nm           -- CSV�t�@�C����
      ,ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.CSV�t�@�C���I�[�v��
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3. EBS���̋@�ύX�f�[�^���o����
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_cont_manage_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    -- �ϐ�������
    lb_break_flag  := FALSE;
    lv_error_flag  := cv_no;
--
    BEGIN
      FETCH get_cont_manage_data_cur BULK COLLECT INTO l_get_cont_manage_data_tab;
      CLOSE get_cont_manage_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || cv_half_space || TO_CHAR(SYSDATE, cv_format_date_time) ||
                 ''
      );
      -- �����Ώی����i�[
      gn_target_cnt := l_get_cont_manage_data_tab.COUNT;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcso00024            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_xxcso00800            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                      );
        lv_errbuf  := lv_errmsg;
     RAISE global_process_expt;
    END;
--
    <<get_data_loop>>
    FOR i IN 1..l_get_cont_manage_data_tab.COUNT LOOP
      BEGIN
        -- ������
        l_get_cont_manage_data_rec := NULL;
        l_get_data_rec             := NULL;
        lt_contract_number         := NULL;
--
        -- �J�[�\���s�̃f�[�^�擾
        l_get_cont_manage_data_rec   := l_get_cont_manage_data_tab(i);
--
        -----------------------
        -- �u���[�N����̏���
        -----------------------
        -- �ŏI�s�łȂ��ꍇ
        IF ( gn_target_cnt <> i ) THEN
          -- ���̍s����_�񏑔ԍ����擾
          lt_contract_number := l_get_cont_manage_data_tab(i+1).contract_number;
        ELSE
          -- �ŏI�s�̏ꍇNULL��ݒ�
          lt_contract_number := NULL;
        END IF;
        -- �����R�[�h�Ǝ��̃��R�[�h�̌_�񏑔ԍ����r���u���[�N���������
        IF (
             ( l_get_cont_manage_data_rec.contract_number <> lt_contract_number )
             OR
             ( lt_contract_number IS NULL )
           ) THEN
          -- ���̃��R�[�h�Ńu���[�N�������́A�ŏI�s
          lb_break_flag:= TRUE;
        END IF;
--
        -- �擾�����f�[�^�L�[�����O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => CHR(10) || cv_debug_msg9 ||
                     cv_debug_msg10 || l_get_cont_manage_data_rec.contract_number || cv_half_space || cv_comma || -- �_�񏑔ԍ�
                     cv_debug_msg11 || l_get_cont_manage_data_rec.install_code    || cv_half_space ||             -- �����R�[�h
                     ''
        );
--
        -- *** �擾�f�[�^�i�[ ***
        l_get_data_rec.contract_number            := l_get_cont_manage_data_rec.contract_number;            -- �_�񏑔ԍ�
        l_get_data_rec.install_code               := l_get_cont_manage_data_rec.install_code;               -- �����R�[�h
        l_get_data_rec.install_account_number     := l_get_cont_manage_data_rec.install_account_number;     -- �ڋq�R�[�h
        l_get_data_rec.install_date               := l_get_cont_manage_data_rec.install_date;               -- �ݒu���i����J�n���j
        l_get_data_rec.party_name                 := l_get_cont_manage_data_rec.party_name;                 -- �ݒu�於�i�Ж��j
        l_get_data_rec.organization_name_phonetic := l_get_cont_manage_data_rec.organization_name_phonetic; -- �ݒu���
        l_get_data_rec.address_lines_phonetic     := l_get_cont_manage_data_rec.address_lines_phonetic;     -- �ݒu��TEL
--
        -- ========================================
        -- A-4.�Z�[�u�|�C���g�ݒ�
        -- ========================================
        SAVEPOINT reqst_proc_up;
--
        -- ==================================================
        -- A-5.�_��Ǘ��e�[�u���X�V����
        -- ==================================================
        upd_cont_manage(
           i_get_data_rec             => l_get_data_rec          -- �o�͗pEBS���̋@�ύX���
          ,ib_break_flag              => lb_break_flag           -- �u���[�N�t���O
          ,iv_error_flag              => lv_error_flag           -- �������ԍ��P�ʃG���[�t���O
          ,id_sysdate                 => ld_sysdate              -- �V�X�e�����t
          ,ov_errbuf                  => lv_errbuf               -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode                 => lv_sub_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg                  => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_expt;
        END IF;
--
        -- �`�F�b�N�E�X�V�ŃG���[�������ꍇ�A�_�񏑔ԍ��P�ʂŃf�[�^�ێ�
        l_get_data_tbl(i) := l_get_data_rec;
--
        -- �_�񏑔ԍ��P�ʂŃG���[���Ȃ��ꍇ�ACSV���o�͂���
        IF ( ( lb_break_flag = TRUE ) AND ( lv_error_flag = cv_no ) ) THEN
          << output_loop >>
          FOR j IN l_get_data_tbl.FIRST..l_get_data_tbl.LAST LOOP
            -- ������
            l_get_data_rec := NULL;
            -- �l��ݒ�
            l_get_data_rec := l_get_data_tbl(j);
--
            -- ========================================
            -- A-6.EBS���̋@�ύX�f�[�^CSV�o��
            -- ========================================
            create_csv_rec(
              i_get_data_rec     =>  l_get_data_rec   -- �o�͗pEBS���̋@�ύX���
             ,ov_errbuf          =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
             ,ov_retcode         =>  lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
             ,ov_errmsg          =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
            --
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END LOOP output_loop;
--
          -- ���팏���J�E���g�A�b�v
          gn_normal_cnt := gn_normal_cnt + l_get_data_tbl.COUNT;
        END IF;
--
        -- �_�񏑔ԍ��P�ʂ̏�����
        IF ( lb_break_flag = TRUE ) THEN
          l_get_data_tbl.DELETE;    -- �_�񏑔ԍ��P�ʂ̃e�[�u���N���A
          lb_break_flag := FALSE;   -- �u���[�N�p�t���O������
          lv_error_flag := cv_no;   -- �_�񏑔ԍ��P�ʃG���[�t���O������
        END IF;
--
      EXCEPTION
        -- *** �X�L�b�v��O�n���h�� ***
        WHEN global_skip_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
--
          -- 1�_�񏑔ԍ��ōŌ�̍s���G���[�̏ꍇ�A�_�񏑔ԍ��P�ʂ̏�����
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- �_�񏑔ԍ��P�ʂ̃e�[�u���N���A
            lb_break_flag := FALSE;   -- �u���[�N�p�t���O������
            lv_error_flag := cv_no;   -- �_�񏑔ԍ��P�ʃG���[�t���O������
          -- 1�_�񏑔ԍ��ōŌ�ȊO�̍s�ŃG���[�̏ꍇ�A�G���[�t���OON
          ELSE
            lv_error_flag := cv_yes;
          END IF;
--
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          END IF;
--
        -- *** �X�L�b�v��OOTHERS�n���h�� ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
--
          -- 1�_�񏑔ԍ��ōŌ�̍s���G���[�̏ꍇ�A�_�񏑔ԍ��P�ʂ̏�����
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- �_�񏑔ԍ��P�ʂ̃e�[�u���N���A
            lb_break_flag := FALSE;   -- �u���[�N�p�t���O������
            lv_error_flag := cv_no;   -- �_�񏑔ԍ��P�ʃG���[�t���O������
          -- 1�_�񏑔ԍ��ōŌ�ȊO�̍s�ŃG���[�̏ꍇ�A�G���[�t���OON
          ELSE
            lv_error_flag := cv_yes;
          END IF;
--
          -- ���O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf  ||SQLERRM              -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          END IF;
      END;
--
    END LOOP get_data_loop;
--
    ov_retcode   := lv_retcode;
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcso00224            --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- �G���[���b�Z�[�W
          );
    END IF;
    -- ========================================
    -- A-7.CSV�t�@�C���N���[�Y
    -- ========================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cont_manage_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cont_manage_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_cont_manage_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cont_manage_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT  NOCOPY  VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date  IN VARCHAR2,                -- �Ώۓ�
    iv_proc_time  IN VARCHAR2                 -- �Ώێ���
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
    -- IN�p�����[�^����
    gv_proc_date      := iv_proc_date;                  -- �Ώۓ�
    gv_proc_time      := iv_proc_time;                  -- �Ώێ���
    gv_proc_date_time := gv_proc_date || gv_proc_time;  -- �Ώۓ���
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf   => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode  => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
 --
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
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
    -- =======================
    -- A-10.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO015A07C;
/
