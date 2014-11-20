CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A05C(body)
 * Description      : CSV�t�@�C������擾�����m�[�g����EBS��
 *                    �m�[�g�֓o�^���܂��B
 * MD.050           : MD050_CSO_014_A05_HHT-EBS�C���^�[�t�F�[�X�F
 *                    (IN)�m�[�g
 * Version          : 1.0
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ----------------------------------------------------------
 *  init                            ��������(A-1)
 *  master_exist_check              �ڋq�R�[�h�A�c�ƈ��R�[�h�}�X�^���݃`�F�b�N(A-3)
 *  insert_notes                    �m�[�g���o�^(A-4)
 *  del_notes_data                  �m�[�g���[�N�e�[�u���f�[�^�폜(A-6)
 *  submain                         ���C�������v���V�[�W��
 *                                    �m�[�g��񒊏o(A-2)
 *                                    savepoint�ݒ�(A-5)
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                    �I������(A-7)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-12    1.0   shun.sou         �V�K�쐬
 *  2009-01-27    1.1   Kenji.Sai        (A-3)��select_data_expt��O��ǉ�
 *  2009-03-16    1.1   K.Boku           �y��Q�ԍ�064�z���\�[�X�}�X�^�`�F�b�N�̗L�����ԏC��
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  #######################
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
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSO014A05C';     -- �p�b�P�[�W��
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCSO';            -- �A�v���P�[�V�����Z�k��
  cv_active_status     CONSTANT VARCHAR2(1)   := 'A';                -- �A�N�e�B�u
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00085';  -- �f�[�^���o�G���[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00086';  -- �ڋq�R�[�h�Ȃ��G���[
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00087';  -- �c�ƈ��R�[�h�Ȃ��G���[
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00088';  -- �f�[�^�ǉ��G���[
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- �f�[�^�폜�G���[
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�

  cv_tgt_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �����Ώی���
  cv_nml_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- ���폈������
  cv_err_cnt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[��������
--
  -- �g�[�N���R�[�h
  cv_tkn_errmsg              CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_sequence            CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_account_cd          CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_account_nm          CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_tkn_sales_cd            CONSTANT VARCHAR2(20) := 'SALESCODE';
  cv_tkn_sales_nm            CONSTANT VARCHAR2(20) := 'SALESNAME';
  cv_tkn_date                CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_tbl                 CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_cnt                 CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_process             CONSTANT VARCHAR2(20) := 'PROCESS'; 
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1              CONSTANT VARCHAR2(200) := '�m�[�g�o�^���������������܂����B';
  cv_debug_msg2              CONSTANT VARCHAR2(200) := '���[�N�e�[�u���̃f�[�^���폜���܂����B';
  cv_debug_msg3              CONSTANT VARCHAR2(200) := '�Z�[�u�|�C���g��ݒ肵�܂����B';
  cv_debug_msg4              CONSTANT VARCHAR2(200) := '���팏�����Ȃ����璼�ڃ��[���o�b�N���܂��B';
  cv_debug_msg5              CONSTANT VARCHAR2(200) := '�Z�[�u�|�C���g�ɖ߂�܂��B';
  cv_debug_msg6              CONSTANT VARCHAR2(200) := '���o���ꂽ�f�[�^�����́�';
  cv_debug_msg7              CONSTANT VARCHAR2(200) := '���ł��B';
  cv_debug_msg8              CONSTANT VARCHAR2(200) := ' �m�[�g���[�N�e�[�u�����o�f�[�^�F';
  cv_debug_msg9              CONSTANT VARCHAR2(200) := ' �J�[�\�����N���[�Y����܂����B';
  cv_debug_msg10             CONSTANT VARCHAR2(200) := '�ڋq�}�X�^�r���[�Ŏ擾���ꂽ�f�[�^:';
  cv_debug_msg11             CONSTANT VARCHAR2(200) := '�ڋq�}�X�^�r���[�Ŏ擾���ꂽ�f�[�^:';
  cv_account_number          CONSTANT VARCHAR2(200) := '�ڋq�R�[�h';
  cv_party_id                CONSTANT VARCHAR2(200) := '�p�[�e�BID�F';
  cv_account_name            CONSTANT VARCHAR2(200) := '�ڋq���́F';
  cv_resource_id             CONSTANT VARCHAR2(200) := '���\�[�XID�F';
  cv_full_name               CONSTANT VARCHAR2(200) := '�����F';
  cv_user_id                 CONSTANT VARCHAR2(200) := '���[�U�[ID�F';
  cv_notetype                CONSTANT VARCHAR2(200) := 'A-1:�m�[�g�^�C�v�F';
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �擾���i�[���R�[�h�^��`
--
  -- �m�[�g��񒊏o�f�[�^
  TYPE g_get_notes_data_rtype IS RECORD(
    no_seq                   xxcso_in_notes.no_seq%TYPE,                    -- �V�[�P���X�ԍ�
    account_number           xxcso_in_notes.account_number%TYPE,            -- �ڋq�R�[�h
    account_name             xxcso_cust_accounts_v.account_name%TYPE,       -- �ڋq����
    notes                    xxcso_in_notes.notes%TYPE,                     -- �m�[�g
    employee_number          xxcso_in_notes.employee_number%TYPE,           -- �c�ƈ��R�[�h
    full_name                xxcso_resources_v.full_name%TYPE,              -- �c�ƈ�����
    input_date               xxcso_in_notes.input_date%TYPE,                -- ���͓��t
    input_time               xxcso_in_notes.input_time%TYPE,                -- ���͎���
    coalition_trance_date    xxcso_in_notes.coalition_trance_date%TYPE,     -- �A�g������
    party_id                 xxcso_cust_accounts_v.party_id%TYPE,           -- �p�[�e�BID
    user_id                  xxcso_resources_v.user_id%TYPE,                -- ���[�U�[ID
    resource_id              xxcso_resources_v.resource_id%TYPE,            -- ���\�[�XID
    note_type                VARCHAR2(20)                                   -- �m�[�g�^�C�v
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_note_type        VARCHAR2(20);                -- �m�[�g�^�C�v���i�[����
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_note_type        OUT NOCOPY VARCHAR2,     -- �m�[�g�^�C�v
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';   -- �A�v���P�[�V�����Z�k��
    cv_prfnm_note_type   CONSTANT VARCHAR2(50)  := 'XXCSO1_HHT_NOTE_TYPE';   -- �v���t�@�C����
--
    -- *** ���[�J���ϐ� ***
    lv_note_type         VARCHAR2(20);       -- �v���t�@�C���l�擾�߂�l
    lv_tkn_value         VARCHAR2(1000);     -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_msg               VARCHAR2(5000);     -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_noprm_msg         VARCHAR2(5000);     -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ================
    -- �ϐ����������� 
    -- ================
    lv_tkn_value := NULL;
--
    -- ==================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- ==================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07         -- ���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- ========================
    -- �v���t�@�C���l�擾����
    -- ========================
    FND_PROFILE.GET(
                    name => cv_prfnm_note_type
                   ,val  => lv_note_type
                   ); -- �m�[�g�^�C�v�i�m�[�g�o�^���̐ݒ�l�j
--
   -- DEBUG�p
   fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => cv_notetype || lv_note_type);
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- �m�[�g�^�C�v�擾���s��
    IF (lv_note_type IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
--
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    gv_note_type   :=  lv_note_type;       -- �m�[�g�^�C�v�i�m�[�g�o�^���̐ݒ�l�j
--
  EXCEPTION
--
--#################################  �Œ��O������  ####################################
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
   * Procedure Name   : master_exist_check
   * Description      : �ڋq�R�[�h�A�c�ƈ��R�[�h�}�X�^���݃`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE master_exist_check(
    io_notes_data_rec   IN OUT NOCOPY g_get_notes_data_rtype,    -- �m�[�g���[�N�e�[�u���f�[�^
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_exist_check'; -- �v���O������
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
    cv_table_name1           CONSTANT VARCHAR2(21)   := '�ڋq�}�X�^�r���[';         -- �ڋq�}�X�^�r���[��
    cv_table_name2           CONSTANT VARCHAR2(20)   := '���\�[�X�}�X�^�r���[';     -- ���\�[�X�}�X�^�r���[��
--
    -- *** ���[�J���ϐ� ***
    lt_account_number        xxcso_in_notes.account_number%TYPE;          -- �ڋq�R�[�h
    lt_party_id              xxcso_cust_accounts_v.party_id%TYPE;         -- �p�[�e�BID
    lt_account_name          xxcso_cust_accounts_v.account_name%TYPE;     -- �ڋq����
    lt_resource_id           xxcso_resources_v.resource_id%TYPE;          -- ���\�[�XID
    lt_full_name             xxcso_resources_v.full_name%TYPE;            -- �c�ƈ�����
    lt_user_id               xxcso_resources_v.user_id%TYPE;              -- ���[�U�[ID
--
    -- *** ���[�J���E���R�[�h ***
    lr_notes_data_rec    g_get_notes_data_rtype;    -- IN�p�����[�^.�m�[�g���[�N�e�[�u���f�[�^�i�[
    -- *** ���[�J����O ***
    warning_expt       EXCEPTION;     -- �}�X�^���݃`�F�b�N��O
    select_data_expt   EXCEPTION;     -- �f�[�^���o�G���[��O
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  
  -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    lr_notes_data_rec := io_notes_data_rec;
--
    BEGIN
    -- =========================
    -- �ڋq�}�X�^���݃`�F�b�N
    -- =========================
      -- �ڋq�}�X�^�r���[����ڋq�R�[�h�A�p�[�e�BID�A�ڋq���̒��o����
      -- �Y���f�[�^�����݂��Ȃ��ꍇ�͌x���Ƃ���
      SELECT xcav.account_number account_number,    -- �ڋq�R�[�h
             xcav.party_id party_id,                -- �p�[�e�BID
             xcav.account_name account_name         -- �ڋq����
      INTO   lt_account_number,                     -- �ڋq�R�[�h
             lt_party_id,                           -- �p�[�e�BID
             lt_account_name                        -- �ڋq����
      FROM   xxcso_cust_accounts_v  xcav
      WHERE  xcav.account_number = lr_notes_data_rec.account_number
        AND  xcav.account_status = cv_active_status 
        AND  xcav.party_status   = cv_active_status;
--
      -- �擾�����ڋq�}�X�^�f�[�^��OUT�p�����[�^�ɐݒ�
      io_notes_data_rec.account_number   := lt_account_number;            -- �ڋq�R�[�h
      io_notes_data_rec.party_id         := lt_party_id;                  -- �p�[�e�BID
      io_notes_data_rec.account_name     := lt_account_name;              -- �ڋq����
      -- ���O�ɏo��
      fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10  || CHR(10) ||
                 cv_account_number || lt_account_number || CHR(10) ||
                 cv_party_id || lt_party_id  || CHR(10) ||
                 cv_account_name || lt_account_name || CHR(10) ||
                 ''
      );
    EXCEPTION
    -- �ڋq�R�[�h�����݂��Ȃ��ꍇ�̌㏈��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name1           -- �g�[�N���l1�ڋq�}�X�^�r���[��
                      ,iv_token_name2  => cv_tkn_sequence          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => io_notes_data_rec.no_seq -- �g�[�N���l2�V�[�P���X�ԍ�
                      ,iv_token_name3  => cv_tkn_account_cd                 -- �g�[�N���R�[�h3
                      ,iv_token_value3 => io_notes_data_rec.account_number  -- �g�[�N���l3�ڋq�R�[�h
                      ,iv_token_name4  => cv_tkn_account_nm                 -- �g�[�N���R�[�h4
                      ,iv_token_value4 => io_notes_data_rec.account_name    -- �g�[�N���l4�ڋq����
                      ,iv_token_name5  => cv_tkn_sales_cd                   -- �g�[�N���R�[�h5
                      ,iv_token_value5 => io_notes_data_rec.employee_number -- �g�[�N���l5�c�ƈ��R�[�h
                      ,iv_token_name6  => cv_tkn_sales_nm                   -- �g�[�N���R�[�h6
                      ,iv_token_value6 => io_notes_data_rec.full_name       -- �g�[�N���l6�c�ƈ�����
                      ,iv_token_name7  => cv_tkn_date                       -- �g�[�N���R�[�h7
                      ,iv_token_value7 => io_notes_data_rec.input_date      -- �g�[�N���l7���͓��t
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  warning_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name1           -- �g�[�N���l1�ڋq�}�X�^�r���[��
                      ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => io_notes_data_rec.no_seq -- �g�[�N���l3�V�[�P���X�ԍ�
                      ,iv_token_name4  => cv_tkn_account_cd                 -- �g�[�N���R�[�h4
                      ,iv_token_value4 => io_notes_data_rec.account_number  -- �g�[�N���l4�ڋq�R�[�h
                      ,iv_token_name5  => cv_tkn_account_nm                 -- �g�[�N���R�[�h5
                      ,iv_token_value5 => io_notes_data_rec.account_name    -- �g�[�N���l5�ڋq����
                      ,iv_token_name6  => cv_tkn_sales_cd                   -- �g�[�N���R�[�h6
                      ,iv_token_value6 => io_notes_data_rec.employee_number -- �g�[�N���l6�c�ƈ��R�[�h
                      ,iv_token_name7  => cv_tkn_sales_nm                   -- �g�[�N���R�[�h7
                      ,iv_token_value7 => io_notes_data_rec.full_name       -- �g�[�N���l7�c�ƈ�����
                      ,iv_token_name8  => cv_tkn_date                       -- �g�[�N���R�[�h8
                      ,iv_token_value8 => io_notes_data_rec.input_date      -- �g�[�N���l8���͓��t
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  select_data_expt;  
--
    END;
--
    -- =================================
    -- �c�ƈ��R�[�h�}�X�^���݃`�F�b�N
    -- =================================
--
    BEGIN
      -- ���\�[�X�}�X�^�r���[���烊�\�[�XID�A�c�ƈ����́A���[�U�[ID���o����
      -- �Y���f�[�^�����݂��Ȃ��ꍇ�͌x���Ƃ���
      SELECT xrv.resource_id resource_id         -- ���\�[�XID
            ,xrv.full_name full_name             -- �c�ƈ�����
            ,xrv.user_id user_id                 -- ���[�U�[ID
      INTO   lt_resource_id,                     -- ���\�[�XID
             lt_full_name,                       -- �c�ƈ�����
             lt_user_id                          -- ���[�U�[ID
      FROM   xxcso_resources_v  xrv
      WHERE  xrv.employee_number = lr_notes_data_rec.employee_number
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.start_date) AND 
             TRUNC(NVL(xrv.end_date,lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.employee_start_date) AND 
             TRUNC(NVL(xrv.employee_end_date, lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.assign_start_date) AND 
             TRUNC(NVL(xrv.assign_end_date, lr_notes_data_rec.input_date))
        AND  lr_notes_data_rec.input_date 
             BETWEEN TRUNC(xrv.resource_start_date) AND 
-- ��Q�Ή�064
--             TRUNC(NVL(xrv.resource_start_date, lr_notes_data_rec.input_date));
             TRUNC(NVL(xrv.resource_end_date, lr_notes_data_rec.input_date));
--
      -- �擾�������\�[�X�}�X�^�f�[�^��OUT�p�����[�^�ɐݒ�
      io_notes_data_rec.resource_id    := lt_resource_id;               -- ���\�[�XID
      io_notes_data_rec.full_name      := lt_full_name;                 -- �c�ƈ�����
      io_notes_data_rec.user_id        := lt_user_id;                   -- ���[�U�[ID
      -- ���O�ɏo��
      fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11  || CHR(10) ||
                 cv_resource_id  || lt_resource_id || CHR(10) ||
                 cv_full_name    || lt_full_name   || CHR(10) ||
                 cv_user_id      || lt_user_id     || CHR(10) ||
                 ''
      );
--
    EXCEPTION
    -- �c�ƈ��R�[�h�����݂��Ȃ��ꍇ�̌㏈��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name2           -- �g�[�N���l1���\�[�X�}�X�^�r���[��
                      ,iv_token_name2  => cv_tkn_sequence          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => io_notes_data_rec.no_seq -- �g�[�N���l2�V�[�P���X�ԍ�
                      ,iv_token_name3  => cv_tkn_account_cd                 -- �g�[�N���R�[�h3
                      ,iv_token_value3 => io_notes_data_rec.account_number  -- �g�[�N���l3�ڋq�R�[�h
                      ,iv_token_name4  => cv_tkn_account_nm                 -- �g�[�N���R�[�h4
                      ,iv_token_value4 => io_notes_data_rec.account_name    -- �g�[�N���l4�ڋq����
                      ,iv_token_name5  => cv_tkn_sales_cd                   -- �g�[�N���R�[�h5
                      ,iv_token_value5 => io_notes_data_rec.employee_number -- �g�[�N���l5�c�ƈ��R�[�h
                      ,iv_token_name6  => cv_tkn_sales_nm                   -- �g�[�N���R�[�h6
                      ,iv_token_value6 => io_notes_data_rec.full_name       -- �g�[�N���l6�c�ƈ�����
                      ,iv_token_name7  => cv_tkn_date                       -- �g�[�N���R�[�h7
                      ,iv_token_value7 => io_notes_data_rec.input_date      -- �g�[�N���l7���͓��t
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name2           -- �g�[�N���l1���\�[�X�}�X�^�r���[��
                      ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => io_notes_data_rec.no_seq -- �g�[�N���l3�V�[�P���X�ԍ�
                      ,iv_token_name4  => cv_tkn_account_cd                 -- �g�[�N���R�[�h4
                      ,iv_token_value4 => io_notes_data_rec.account_number  -- �g�[�N���l4�ڋq�R�[�h
                      ,iv_token_name5  => cv_tkn_account_nm                 -- �g�[�N���R�[�h5
                      ,iv_token_value5 => io_notes_data_rec.account_name    -- �g�[�N���l5�ڋq����
                      ,iv_token_name6  => cv_tkn_sales_cd                   -- �g�[�N���R�[�h6
                      ,iv_token_value6 => io_notes_data_rec.employee_number -- �g�[�N���l6�c�ƈ��R�[�h
                      ,iv_token_name7  => cv_tkn_sales_nm                   -- �g�[�N���R�[�h7
                      ,iv_token_value7 => io_notes_data_rec.full_name       -- �g�[�N���l7�c�ƈ�����
                      ,iv_token_name8  => cv_tkn_date                       -- �g�[�N���R�[�h8
                      ,iv_token_value8 => io_notes_data_rec.input_date      -- �g�[�N���l8���͓��t
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE  select_data_expt;  
--
    END;
--
  EXCEPTION
    -- �f�[�^�����݂��Ȃ���O
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- �f�[�^���o�G���[��O
    WHEN select_data_expt THEN
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
  END master_exist_check;
--
  /**********************************************************************************
   * Procedure Name   : insert_notes
   * Description      : �m�[�g���o�^(A-4)
   **********************************************************************************/
  PROCEDURE insert_notes(
    io_notes_data_rec  IN OUT  NOCOPY  g_get_notes_data_rtype,  -- �m�[�g���[�N�e�[�u���f�[�^
    ov_errbuf             OUT  NOCOPY  VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT  NOCOPY  VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT  NOCOPY  VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT  VARCHAR2(100) := 'insert_notes'; -- �v���O������
    cv_source_object_cd  CONSTANT  VARCHAR2(5)   := 'PARTY';        -- API�֐��p
    cv_note_status       CONSTANT  VARCHAR2(1)   := 'I';            -- API�֐��p
    cv_p_commit          CONSTANT  VARCHAR2(1)   := 'F';            -- API�֐��p
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
    cv_table_name           CONSTANT VARCHAR2(20)   := '�m�[�g���';     -- �m�[�g���e�[�u����
    cv_process_name         CONSTANT VARCHAR2(20)   := '�o�^';           -- �v���Z�X��
--
    -- *** ���[�J���ϐ� ***
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
    ln_note_id          NUMBER;
--
    lt_no_seq                xxcso_in_notes.no_seq%TYPE;                 -- �V�[�P���X�ԍ�
    lt_account_number        xxcso_in_notes.account_number%TYPE;         -- �ڋq�R�[�h
    lt_employee_number       xxcso_in_notes.employee_number%TYPE;        -- �c�ƈ��R�[�h
    lt_account_name          xxcso_cust_accounts_v.account_name%TYPE;    -- �ڋq����
    lt_full_name             xxcso_resources_v.full_name%TYPE;           -- �c�ƈ�����
    lt_input_date            xxcso_in_notes.input_date%TYPE;             -- ���͓��t
    lt_party_id              xxcso_cust_accounts_v.party_id%TYPE;        -- �p�[�e�BID
    lt_resource_id           xxcso_resources_v.resource_id%TYPE;         -- ���\�[�XID
    lt_user_id               xxcso_resources_v.user_id%TYPE;             -- ���[�U�[ID
    lt_notes                 xxcso_in_notes.notes%TYPE;                  -- �m�[�g���e
    lv_note_type             VARCHAR2(2000);                             -- �m�[�g�^�C�v

    ln_dummy_cnt             NUMBER(10);         -- API�֐�LOG�o�͗p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_notes_data_rec   g_get_notes_data_rtype;   -- IN�p�����[�^.�m�[�g���[�N�e�[�u���f�[�^�i�[
--
    -- *** ���[�J����O ***
    warning_expt   EXCEPTION;            -- �f�[�^�o�^��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
  -- IN�p�����[�^�����[�J�����R�[�h�A�ϐ��ɑ��
    lr_notes_data_rec     := io_notes_data_rec;
  -- �m�[�g���[�N�e�[�u�����o�f�[�^�����[�J���ϐ��ɑ��
    lt_no_seq             := lr_notes_data_rec.no_seq;             -- �V�[�P���X�ԍ�
    lt_account_number     := lr_notes_data_rec.account_number;     -- �ڋq�R�[�h
    lt_employee_number    := lr_notes_data_rec.employee_number;    -- �c�ƈ��R�[�h
    lt_account_name       := lr_notes_data_rec.account_name;       -- �ڋq����
    lt_full_name          := lr_notes_data_rec.full_name;          -- �c�ƈ�����
    lt_input_date         := lr_notes_data_rec.input_date;         -- ���͓��t
    lt_party_id           := lr_notes_data_rec.party_id;           -- �p�[�e�BID
    lt_resource_id        := lr_notes_data_rec.resource_id;        -- ���\�[�XID
    lt_user_id            := lr_notes_data_rec.user_id;            -- ���[�U�[ID
    lt_notes              := lr_notes_data_rec.notes;              -- �m�[�g���e
    lv_note_type          := lr_notes_data_rec.note_type;          -- �m�[�g�^�C�v
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ******************
    -- * �m�[�g���o�^ *
    -- ******************
--
    -- �m�[�g�f�[�^�o�^����
    -- �m�[�g�o�^�g�����U�N�V�����̍쐬
    JTF_NOTES_PUB.CREATE_NOTE(
       p_api_version         => 1.0                       -- �o�[�W�����i���o�[
      ,p_init_msg_list       => FND_API.G_TRUE            -- p_init_msg_list
      ,p_commit              => cv_p_commit               -- �R�~�b�g
      ,x_return_status       => lv_return_status          -- ���^�[���X�e�[�^�X
      ,x_msg_count           => ln_msg_count              -- x_msg_count
      ,x_msg_data            => lv_msg_data               -- x_msg_data
      ,p_source_object_id    => lt_party_id               -- �\�[�X�I�u�W�F�N�gID
      ,p_source_object_code  => cv_source_object_cd       -- �\�[�X�I�u�W�F�N�g�R�[�h
      ,p_notes               => lt_notes                  -- �m�[�g�L�q
      ,p_note_status         => cv_note_status            -- �m�[�g�X�e�[�^�X
      ,p_note_type           => lv_note_type              -- �m�[�g�^�C�v
      ,p_entered_by          => lt_user_id                -- �m�[�g�o�^��
      ,p_entered_date        => lt_input_date             -- �m�[�g�o�^��
      ,x_jtf_note_id         => ln_note_id                -- �m�[�gID
      ,p_last_update_date    => cd_last_update_date       -- �m�[�g�ŏI�X�V��
      ,p_last_updated_by     => cn_last_updated_by        -- �m�[�g�ŏI�X�V��
      ,p_creation_date       => cd_creation_date          -- �m�[�g�쐬��
      ,p_created_by          => cn_last_updated_by        -- �m�[�g�쐬��
      ,p_last_update_login   => cn_last_update_login      -- �m�[�g�ŏI�X�V���O�C��ID
      );
--
-- *** �m�[�g���o�^��O ***
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name            -- �g�[�N���l1�m�[�g���e�[�u����
                      ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2SQLERRM 
                      ,iv_token_name3  => cv_tkn_sequence          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => lt_no_seq                -- �g�[�N���l3�V�[�P���X�ԍ�
                      ,iv_token_name4  => cv_tkn_account_cd        -- �g�[�N���R�[�h4
                      ,iv_token_value4 => lt_account_number        -- �g�[�N���l4�ڋq�R�[�h
                      ,iv_token_name5  => cv_tkn_account_nm        -- �g�[�N���R�[�h5
                      ,iv_token_value5 => lt_account_name          -- �g�[�N���l5�ڋq����
                      ,iv_token_name6  => cv_tkn_sales_cd          -- �g�[�N���R�[�h6
                      ,iv_token_value6 => lt_employee_number       -- �g�[�N���l6�c�ƈ��R�[�h
                      ,iv_token_name7  => cv_tkn_sales_nm          -- �g�[�N���R�[�h7
                      ,iv_token_value7 => lt_full_name             -- �g�[�N���l7�c�ƈ�����
                      ,iv_token_name8  => cv_tkn_date              -- �g�[�N���R�[�h8
                      ,iv_token_value8 => lt_input_date            -- �g�[�N���l8���͓��t
                  );
      lv_errbuf := lv_errmsg;
      -- API�G���[���b�Z�[�W�̃��O�o��
      <<count_msg_loop>>
      FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
        -- ���b�Z�[�W�擾
        FND_MSG_PUB.GET(
           p_msg_index      => i
          ,p_encoded        => FND_API.G_FALSE
          ,p_data           => lv_msg_data
          ,p_msg_index_out  => ln_dummy_cnt
        );
        -- ���O�o��
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg_data);
        lv_errbuf := SUBSTRB(lv_errbuf||lv_msg_data,5000);
      END LOOP count_msg_loop;
--
      RAISE warning_expt;
    END IF;
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => cv_debug_msg1
    );    
--
  EXCEPTION
--
    -- �x��������O
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_notes;
--
 /**********************************************************************************
   * Procedure Name   : del_notes_data
   * Description      : �m�[�g���[�N�e�[�u���f�[�^�폜(A-6)
-- **********************************************************************************/
  PROCEDURE del_notes_data(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_notes_data';       -- �v���O������
    cv_table_name_note_wrk  CONSTANT VARCHAR2(20)   := '�m�[�g���[�N�e�[�u��'; -- �m�[�g���[�N�e�[�u����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O ***
    del_tbl_data_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************************
    -- ***       �m�[�g���[�N�e�[�u���f�[�^�폜        ***
    -- ***************************************************
    BEGIN
      DELETE
      FROM  xxcso_in_notes xin;
--
      fnd_file.put_line(
        which  => FND_FILE.LOG,
        buff   => cv_debug_msg2
      );
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h �f�[�^�폜�G���[
                       ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_note_wrk   -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- ORACLE�G���[
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE del_tbl_data_expt;
    END;
--    
  EXCEPTION
    -- *** �f�[�^�폜���̗�O�n���h�� ***
    WHEN del_tbl_data_expt THEN
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
  END del_notes_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    cv_table_name  CONSTANT VARCHAR2(100) := '�m�[�g���[�N�e�[�u��';   -- �m�[�g���[�N�e�[�u����
--
    -- *** ���[�J���ϐ� ***
    lv_note_type            VARCHAR2(2000);                            -- �m�[�g�^�C�v
    lv_err_rec_info         VARCHAR2(5000);                            --�@�f�[�^���ڑS���̓��e
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �m�[�g���[�N�e�[�u���f�[�^���擾����J�[�\��
    CURSOR xin_data_cur
    IS
      SELECT xin.no_seq                no_seq                          -- �V�[�P���X�ԍ�
            ,xin.account_number        account_number                  -- �ڋq�R�[�h
            ,xin.notes                 notes                           -- �m�[�g
            ,xin.employee_number       employee_number                 -- �c�ƈ��R�[�h
            ,xin.input_date            input_date                      -- ���͓��t
            ,xin.input_time            input_time                      -- ���͎���
            ,xin.coalition_trance_date coalition_trance_date           -- �A�g������
      FROM  xxcso_in_notes   xin
      ORDER BY xin.no_seq  ASC;
    -- *** ���[�J���E���R�[�h ***
    lr_xin_data_rec       xin_data_cur%ROWTYPE;
    lr_get_data_rec       g_get_notes_data_rtype;   -- IN�p�����[�^.�m�[�g���[�N�e�[�u���f�[�^�i�[
    -- *** ���[�J����O ***
    error_skip_data_expt       EXCEPTION;             -- �f�[�^�X�L�b�v��O
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
    -- ===============
    -- A-1.��������
    -- ===============
    init(
       ov_note_type      => gv_note_type        -- �m�[�g�^�C�v
      ,ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
   -- DEBUG�p
   fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => ' A-2.�m�[�g���[�N�e�[�u���f�[�^���o�J�n�F');
--
    -- ====================================
    -- A-2.�m�[�g���[�N�e�[�u���f�[�^���o
    -- ====================================
    -- �J�[�\���I�[�v��
    OPEN xin_data_cur;
--
    <<get_data_loop>>
    LOOP
      
      BEGIN
        FETCH xin_data_cur INTO lr_xin_data_rec;
--
        -- �����Ώی����i�[
        gn_target_cnt := xin_data_cur%ROWCOUNT;
--
        -- DEBUG�p
        fnd_file.put_line(
          which => FND_FILE.LOG
          ,buff  => ' A-2.�����Ώی����F'|| gn_target_cnt);
--
        EXIT WHEN xin_data_cur%NOTFOUND
        OR  xin_data_cur%ROWCOUNT = 0;
--
        -- ���R�[�h�ϐ�������
        lr_get_data_rec := NULL;
--
        lr_get_data_rec.no_seq                 := lr_xin_data_rec.no_seq;                -- �V�[�P���X�ԍ�
        lr_get_data_rec.account_number         := lr_xin_data_rec.account_number;        -- �ڋq�R�[�h
        lr_get_data_rec.notes                  := lr_xin_data_rec.notes;                 -- �m�[�g
        lr_get_data_rec.employee_number        := lr_xin_data_rec.employee_number;       -- �c�ƈ��R�[�h
        lr_get_data_rec.input_date             := lr_xin_data_rec.input_date;            -- ���͓��t
        lr_get_data_rec.input_time             := lr_xin_data_rec.input_time;            -- ���͎���
        lr_get_data_rec.coalition_trance_date  := lr_xin_data_rec.coalition_trance_date; -- �A�g������
        lr_get_data_rec.note_type              := gv_note_type;                          -- �m�[�g�^�C�v
--
        -- INPUT�f�[�^�̍��ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
        lv_err_rec_info := lr_get_data_rec.no_seq||','
                        || lr_get_data_rec.notes ||','
                        || lr_get_data_rec.account_number||','
                        || lr_get_data_rec.employee_number||','
                        || lr_get_data_rec.input_date||','
                        || lr_get_data_rec.input_time||','
                        || lr_get_data_rec.coalition_trance_date||','
                        || lr_get_data_rec.note_type;
        fnd_file.put_line(
          which => FND_FILE.LOG
          ,buff  => cv_debug_msg8 || lv_err_rec_info);
--
        -- ================================================
        -- A-3.�ڋq�R�[�h�A�c�ƈ��R�[�h�}�X�^���݃`�F�b�N
        -- ================================================
--
        master_exist_check(
          io_notes_data_rec =>lr_get_data_rec,   -- �m�[�g���[�N�e�[�u���f�[�^
          ov_errbuf         =>lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode        =>lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg         =>lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;  
        END IF;
--
        -- ========================
        -- A-4.�m�[�g���o�^����
        -- ========================
--
        insert_notes(
          io_notes_data_rec  =>lr_get_data_rec,     -- �m�[�g���f�[�^
          ov_errbuf          =>lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode         =>lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg          =>lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE error_skip_data_expt;
        END IF;
        -- ========================
        -- A-5.�Z�[�u�|�C���g�ݒ�
        -- ========================
        SAVEPOINT a;
        fnd_file.put_line(
            which  => FND_FILE.LOG,
            buff   => cv_debug_msg3
          );
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- �f�[�^�`�F�b�N�A�o�^�G���[�ɂăX�L�b�v
        WHEN error_skip_data_expt THEN
          -- �G���[�����J�E���g
            gn_error_cnt := gn_error_cnt + 1;
          -- �G���[�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
            );
          -- �G���[���O�i�f�[�^���{�G���[���b�Z�[�W�j
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_err_rec_info || ' ' || lv_errbuf || CHR(10) ||
                         ''
            );
          -- ���[���o�b�N
          IF (gn_normal_cnt = 0) THEN
            ROLLBACK;
            fnd_file.put_line(
                  which  => FND_FILE.LOG,
                  buff   => cv_debug_msg4
                );
          ELSE
            ROLLBACK TO SAVEPOINT a;
            fnd_file.put_line(
                  which  => FND_FILE.LOG,
                  buff   => cv_debug_msg5
                );
          END IF;
          -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
          ov_retcode := cv_status_warn;
      END;
--
    END LOOP get_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE xin_data_cur;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
    );
--
    -- ========================================
    -- A-6.�m�[�g���[�N�e�[�u���f�[�^�폜����
    -- ========================================
    del_notes_data(
      ov_errbuf           =>lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode          =>lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg           =>lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
-- 
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN error_skip_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xin_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xin_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tbl               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_name            -- �g�[�N���l1�m�[�g���[�N�e�[�u����
                      ,iv_token_name2  => cv_tkn_errmsg            -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2SQLERRM                      
                      ,iv_token_name3  => cv_tkn_sequence          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => lr_get_data_rec.no_seq   -- �g�[�N���l3�V�[�P���X�ԍ�
                      ,iv_token_name4  => cv_tkn_account_cd               -- �g�[�N���R�[�h4
                      ,iv_token_value4 => lr_get_data_rec.account_number  -- �g�[�N���l4�ڋq�R�[�h
                      ,iv_token_name5  => cv_tkn_account_nm               -- �g�[�N���R�[�h5
                      ,iv_token_value5 => lr_get_data_rec.account_name    -- �g�[�N���l5�ڋq����
                      ,iv_token_name6  => cv_tkn_sales_cd                 -- �g�[�N���R�[�h6
                      ,iv_token_value6 => lr_get_data_rec.employee_number -- �g�[�N���l6�c�ƈ��R�[�h
                      ,iv_token_name7  => cv_tkn_sales_nm                 -- �g�[�N���R�[�h7
                      ,iv_token_value7 => lr_get_data_rec.full_name       -- �g�[�N���l7�c�ƈ�����
                      ,iv_token_name8  => cv_tkn_date                     -- �g�[�N���R�[�h8
                      ,iv_token_value8 => lr_get_data_rec.input_date      -- �g�[�N���l8���͓��t
                     );
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xin_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xin_data_cur;
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''  || CHR(10) ||
                 cv_debug_msg9 ||
                 ''
        );
      END IF;
--
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    
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
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_message_code  VARCHAR2(100);  -- �I�����b�Z�[�W���i�[
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
       ov_errbuf   =>lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  =>lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   =>lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
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
    -- ===============
    -- A-7.�I������
    -- ===============
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--    
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
END XXCSO014A05C;
/
