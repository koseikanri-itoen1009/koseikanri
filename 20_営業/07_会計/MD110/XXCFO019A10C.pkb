CREATE OR REPLACE PACKAGE BODY XXCFO019A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A10C(body)
 * Description      : �d�q���냊�[�X����̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A10_�d�q���냊�[�X����̏��n�V�X�e���A�g
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_lease_wait_coop    ���A�g�f�[�^�擾����(A-2)
 *  get_lease_control      �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  chk_periods            ��v���ԃ`�F�b�N����(A-4)
 *  get_add_info           �t�����擾����(A-6)
 *  chk_item               ���ڃ`�F�b�N����(A-7)
 *  out_csv                CSV�o�͏���(A-8)
 *  ins_lease_wait_coop    ���A�g�e�[�u���o�^����(A-9)
 *  get_lease              �Ώۃf�[�^�擾(A-5)
 *  del_lease_wait_coop    ���A�g�e�[�u���폜����(A-10)
 *  upd_lease_control      �Ǘ��e�[�u���X�V����(A-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-20    1.0   K.Nakamura       �V�K�쐬
 *  2012-11-26    1.1   K.Nakamura       [E_�{�ғ�_10112�Ή�]T4���؃p�t�H�[�}���X��Q�Ή�
 *  2012-12-19    1.2   T.Osawa          [E_�{�ғ�_10112�Ή�]���o�����ύX
 *  2016-08-25    1.3   SCSK�s           [E_�{�ғ�_13658�Ή�]���̋@�ϗp�N���ύX
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
  gn_target_cnt    NUMBER;                    -- �Ώی����i�A�g���j
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v�����i���A�g�����j
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
  global_lock_expt          EXCEPTION; -- ���b�N��O
  global_warn_expt          EXCEPTION; -- �x����
  global_gl_je_expt         EXCEPTION; -- �d�󖢓]�L��
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A10C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)  := 'XXCFF';        -- �A�h�I���F���[�X�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)  := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�h�I���F�݌ɁE�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  --�v���t�@�C��
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                           -- GL��v����ID
  cv_data_filepath            CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_lease_add_data_status    CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_ADD_DATA_STATUS'; -- �d�q���냊�[�X����t�����p�X�e�[�^�X
  cv_ins_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_DATA_I_FILENAME'; -- �d�q���냊�[�X����f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_DATA_U_FILENAME'; -- �d�q���냊�[�X����f�[�^�X�V�t�@�C����
  -- �Q�ƃ^�C�v
  cv_lookup_item_chk_lease    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_LEASE';             -- �d�q���덀�ڃ`�F�b�N�i���[�X����j
  cv_lookup_elec_book_date    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';                  -- �d�q���돈�����s��
  -- ���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- ���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020'; -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024'; -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- �폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027'; -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029'; -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030'; -- �t�@�C�������݃G���[���b�Z�[�W
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00031'; -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10001'; -- �Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10002'; -- �Ώی����i���A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10003'; -- ���A�g�������b�Z�[�W
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10005'; -- �d�󖢓]�L���b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007'; -- ���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010'; -- ���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011'; -- �������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025'; -- �擾�Ώۃf�[�^�����G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_cause                CONSTANT VARCHAR2(20) := 'CAUSE';                -- ���A�g�f�[�^�o�^���R
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20) := 'DIR_TOK';              -- �f�B���N�g����
  cv_tkn_doc_data             CONSTANT VARCHAR2(20) := 'DOC_DATA';             -- �L�[��
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20) := 'DOC_DIST_ID';          -- �L�[�l
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';               -- SQL�G���[���b�Z�[�W
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';            -- �t�@�C����
  cv_tkn_get_data             CONSTANT VARCHAR2(20) := 'GET_DATA';             -- �e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';             -- �G���[���
  cv_tkn_key_item             CONSTANT VARCHAR2(20) := 'KEY_ITEM';             -- �G���[���
  cv_tkn_key_value            CONSTANT VARCHAR2(20) := 'KEY_VALUE';            -- �G���[���
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';          -- ���b�N�A�b�v�R�[�h��
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';          -- ���b�N�A�b�v�^�C�v��
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';              -- ���A�g�G���[���e
  cv_tkn_org_code_tok         CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_prof_name            CONSTANT VARCHAR2(20) := 'PROF_NAME';            -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                -- �e�[�u����
  cv_tkn_target               CONSTANT VARCHAR2(20) := 'TARGET';               -- ���A�g�f�[�^����L�[
  -- �g�[�N���l
  cv_msg_cfo_11008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11008'; -- ���ڂ��s��
  cv_msg_cfo_11069            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11069'; -- ���[�X������
  cv_msg_cfo_11070            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11070'; -- ���[�X������A�g�e�[�u��
  cv_msg_cfo_11071            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11071'; -- ���[�X����Ǘ��e�[�u��
  cv_msg_cfo_11072            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11072'; -- �����R�[�h
  cv_msg_cfo_11073            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11073'; -- ��v����
  cv_msg_cfo_11074            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11074'; -- ���_��
  cv_msg_cfo_11075            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11075'; -- �ă��[�X
  cv_msg_cfo_11076            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11076'; -- FIN
  cv_msg_cfo_11077            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11077'; -- OP
  cv_msg_cfo_11078            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11078'; -- ��FIN
  cv_msg_cfo_11086            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11086'; -- �d��
  cv_msg_cfo_11088            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11088'; -- �_(�A)
  cv_msg_cfo_11091            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11091'; -- ���[�X
  cv_msg_cfo_11092            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11092'; -- ���[�X���
  cv_msg_cfo_11093            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11093'; -- ���[�X���v��Ŋz
  cv_msg_cfo_11094            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11094'; -- ���[�X���U��
  cv_msg_cfo_11095            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11095'; -- ���[�X���U��
  cv_msg_cfo_11096            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11096'; -- ���[�X�����啊��
  -- ���t�t�H�[�}�b�g
  cv_format_yyyymm            CONSTANT VARCHAR2(7)  := 'YYYY-MM';          -- YYYY-MM�t�H�[�}�b�g
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- YYYYMMDD�t�H�[�}�b�g
  cv_format_yyyymmddhhmiss    CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS'; -- YYYYMMDDHH24MISS�t�H�[�}�b�g
  -- ���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)  := '0';                -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)  := '1';                -- �蓮���s
  -- �ǉ��X�V�敪
  cv_ins_upd_ins              CONSTANT VARCHAR2(1)  := '0';                -- �ǉ�
  cv_ins_upd_upd              CONSTANT VARCHAR2(1)  := '1';                -- �X�V
  -- �A�g���A�g����p
  cv_coop                     CONSTANT VARCHAR2(1)  := '0';                -- �A�g
  cv_wait_coop                CONSTANT VARCHAR2(1)  := '1';                -- ���A�g
  -- �f�[�^�ύX�t���O
  cv_upd_off                  CONSTANT VARCHAR2(1)  := '0';                -- �ύX�Ȃ�
  cv_upd_on                   CONSTANT VARCHAR2(1)  := '1';                -- �ύX����
  -- ���[�X�敪
  cv_lease_type_1             CONSTANT VARCHAR2(1)  := '1';                -- ���_��
  cv_lease_type_2             CONSTANT VARCHAR2(1)  := '2';                -- �ă��[�X
  -- ���[�X���
  cv_lease_kind_0             CONSTANT VARCHAR2(1)  := '0';                -- FIN
  cv_lease_kind_1             CONSTANT VARCHAR2(1)  := '1';                -- OP
  cv_lease_kind_2             CONSTANT VARCHAR2(1)  := '2';                -- ��FIN
  -- ����^�C�v
  cv_transaction_type_1       CONSTANT VARCHAR2(1)  := '1';                -- �V�K
  cv_transaction_type_3       CONSTANT VARCHAR2(1)  := '3';                -- ���
  -- GL�A�g�t���O
  cv_gl_if_flag_2             CONSTANT VARCHAR2(1)  := '2';                -- �A�g��
  -- ��vIF�t���O
  cv_accounting_if_flag_0     CONSTANT VARCHAR2(1)  := '0';                -- �ΏۊO
  -- �X�e�[�^�X
  cv_application_short_name   CONSTANT VARCHAR2(5)  := 'SQLGL';            -- GL
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';                -- �N���[�Y
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                -- �����d��Ȃ�
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                -- ����
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                -- �]�L��
  -- ��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  -- �o��
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';           -- ���b�Z�[�W�o��
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';              -- ���O�o��
  cv_open_mode_w              CONSTANT VARCHAR2(1)  := 'W';                -- �������݃��[�h
  cv_slash                    CONSTANT VARCHAR2(1)  := '/';                -- �X���b�V��
  cv_delimit                  CONSTANT VARCHAR2(1)  := ',';                -- �J���}
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- ��������
  cv_colon                    CONSTANT VARCHAR2(1)  := ':';                -- �R�����i���p�j
  -- ���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)  := '0';                -- VARCHAR2
  cv_attr_num                 CONSTANT VARCHAR2(1)  := '1';                -- NUMBER
  cv_attr_dat                 CONSTANT VARCHAR2(1)  := '2';                -- DATE
  cv_attr_cha                 CONSTANT VARCHAR2(1)  := '3';                -- CHAR
  -- ����
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڃ`�F�b�N�i�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1              fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2              fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3              fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4              fnd_lookup_values.attribute4%TYPE -- ����
    , attribute5              fnd_lookup_values.attribute5%TYPE -- �؎̂ăt���O
  );
  -- ���ڃ`�F�b�N�i�[�e�[�u���^�C�v
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  --
  -- ���[�X������A�g�f�[�^���R�[�h
  TYPE g_lease_wait_coop_rtype IS RECORD(
      period_name             xxcfo_lease_wait_coop.period_name%TYPE -- ��v����
    , object_code             xxcfo_lease_wait_coop.object_code%TYPE -- �����R�[�h
    , xlwc_rowid              ROWID                                  -- ROWID
  );
  -- ���[�X������A�g�f�[�^�e�[�u���^�C�v
  TYPE g_lease_wait_coop_ttype IS TABLE OF g_lease_wait_coop_rtype INDEX BY PLS_INTEGER;
  --
  -- �f�[�^�ύX���e�[�u���^�C�v
  TYPE g_data_update_ttype     IS TABLE OF xxcff_contract_histories.update_reason%TYPE INDEX BY PLS_INTEGER;
  --
  -- ���[�X������e�[�u���^�C�v
  TYPE g_data_ttype            IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_lease_add_data_status    VARCHAR2(3)   DEFAULT NULL; -- �d�q���냊�[�X����t�����p�X�e�[�^�X
  gv_file_name                VARCHAR2(100) DEFAULT NULL; -- �d�q���냊�[�X����t�@�C����
  gv_coop_date                VARCHAR2(15)  DEFAULT NULL; -- �A�g�����p�V�X�e�����t
  gv_file_open_flg            VARCHAR2(1)   DEFAULT NULL; -- �t�@�C���I�[�v���t���O
  gv_warn_flg                 VARCHAR2(1)   DEFAULT NULL; -- �x���t���O
  gv_skip_flg                 VARCHAR2(1)   DEFAULT NULL; -- �X�L�b�v�t���O
  gv_gl_je_flg                VARCHAR2(1)   DEFAULT NULL; -- �d�󖢓]�L�t���O
  gv_msg_cfo_11072            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F�����R�[�h
  gv_msg_cfo_11073            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F��v����
  gv_msg_cfo_11074            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F���_��
  gv_msg_cfo_11075            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F�ă��[�X
  gv_msg_cfo_11076            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���FFIN
  gv_msg_cfo_11077            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���FOP
  gv_msg_cfo_11078            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F��FIN
  gv_msg_cfo_11086            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F�d��
  gv_msg_cfo_11088            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F�_(�A)
  gv_msg_cfo_11091            VARCHAR2(10)  DEFAULT NULL; -- �Œ蕶���F���[�X
  gv_msg_cfo_11092            VARCHAR2(20)  DEFAULT NULL; -- �Œ蕶���F���[�X���
  gv_msg_cfo_11093            VARCHAR2(20)  DEFAULT NULL; -- �Œ蕶���F���[�X���v��Ŋz
  gv_msg_cfo_11094            VARCHAR2(20)  DEFAULT NULL; -- �Œ蕶���F���[�X���U��
  gv_msg_cfo_11095            VARCHAR2(20)  DEFAULT NULL; -- �Œ蕶���F���[�X���U��
  gv_msg_cfo_11096            VARCHAR2(20)  DEFAULT NULL; -- �Œ蕶���F���[�X�����啊��
  gn_target2_cnt              NUMBER;                     -- �Ώی����i���A�g���j
  gn_set_of_books_id          NUMBER        DEFAULT NULL; -- GL��v����ID
  gn_electric_exec_days       NUMBER        DEFAULT NULL; -- �d�q���돈�����s����
  gn_period_chk               NUMBER        DEFAULT NULL; -- ��v���ԃ`�F�b�N
-- 2012/11/26 1.1 K.Nakamura ADD START
  gn_contract_header_id       NUMBER        DEFAULT NULL; -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
  gd_process_date             DATE          DEFAULT NULL; -- �Ɩ����t
  gt_next_period_name         xxcfo_lease_control.period_name%TYPE DEFAULT NULL; -- ����v����
  gt_period_name              xxcfo_lease_control.period_name%TYPE DEFAULT NULL; -- ��v���ԁi�`�F�b�N�p�j
  gt_xlc_rowid                ROWID;                                             -- ROWID
  gt_directory_name           all_directories.directory_name%TYPE  DEFAULT NULL; -- �f�B���N�g����
  gt_directory_path           all_directories.directory_path%TYPE  DEFAULT NULL; -- �f�B���N�g���p�X
  gv_file_handle              UTL_FILE.FILE_TYPE;                                -- �t�@�C���n���h��
  -- �e�[�u���ϐ�
  g_chk_item_tab              g_chk_item_ttype;        -- ���ڃ`�F�b�N
  g_lease_wait_coop_tab       g_lease_wait_coop_ttype; -- ���[�X������A�g�e�[�u��
  g_data_update_tab           g_data_update_ttype;     -- �f�[�^�ύX���e���
  g_data_tab                  g_data_ttype;            -- �o�̓f�[�^���
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn   IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_file_name     IN  VARCHAR2, -- �t�@�C����
    iv_period_name   IN  VARCHAR2, -- ��v����
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_file_name              VARCHAR2(1000)  DEFAULT NULL;  -- IF�t�@�C�����i�쐬�j
    lv_if_file_name           VARCHAR2(1000)  DEFAULT NULL;  -- IF�t�@�C����
    lb_exists                 BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���
    ln_file_length            NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size             BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
--
    -- *** ���[�J���J�[�\�� ***
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning        AS meaning     -- ���ږ���
           , flv.attribute1     AS attribute1  -- ���ڂ̒���
           , flv.attribute2     AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3     AS attribute3  -- �K�{�t���O
           , flv.attribute4     AS attribute4  -- ����
           , flv.attribute5     AS attribute5  -- �؎̂ăt���O
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type  = cv_lookup_item_chk_lease
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which       => cv_file_type_out -- ���b�Z�[�W�o��
      , iv_conc_param1 => iv_ins_upd_kbn   -- �ǉ��X�V�敪
      , iv_conc_param2 => iv_file_name     -- �t�@�C����
      , iv_conc_param3 => iv_period_name   -- ��v����
      , iv_conc_param4 => iv_exec_kbn      -- ����蓮�敪
      , ov_errbuf      => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
    --
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which       => cv_file_type_log -- ���b�Z�[�W�o��
      , iv_conc_param1 => iv_ins_upd_kbn   -- �ǉ��X�V�敪
      , iv_conc_param2 => iv_file_name     -- �t�@�C����
      , iv_conc_param3 => iv_period_name   -- ��v����
      , iv_conc_param4 => iv_exec_kbn      -- ����蓮�敪
      , ov_errbuf      => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00015 -- ���b�Z�[�W�R�[�h
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �A�g�����p�V�X�e�����t�擾
    --==================================
    gv_coop_date := TO_CHAR( SYSDATE, cv_format_yyyymmddhhmiss );
--
    --==================================
    -- �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p���)�擾
    --==================================
    -- �J�[�\���I�[�v��
    OPEN chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE chk_item_cur;
    --
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cff         -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cff_00189       -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_lookup_type     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_lookup_item_chk_lease -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �N�C�b�N�R�[�h(�d�q���돈�����s����)�擾
    --==================================
    BEGIN
      SELECT TO_NUMBER(flv.attribute1) AS attribute1 -- �d�q���돈�����s����
      INTO   gn_electric_exec_days
      FROM   fnd_lookup_values         flv
      WHERE  flv.lookup_type  = cv_lookup_elec_book_date
      AND    flv.lookup_code  = cv_pkg_name
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
      --
      IF ( gn_electric_exec_days IS NULL ) THEN
        -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_00031         -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_lookup_type       -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_lookup_elec_book_date -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_lookup_code       -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => cv_pkg_name              -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_00031         -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_lookup_type       -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_lookup_elec_book_date -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_lookup_code       -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => cv_pkg_name              -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    -- �d�q����f�[�^�t�@�C���i�[�p�X
    gt_directory_name := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_directory_name IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_data_filepath -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �d�q���냊�[�X����t�����p�X�e�[�^�X
    gv_lease_add_data_status  := FND_PROFILE.VALUE( cv_lease_add_data_status );
    --
    IF ( gv_lease_add_data_status IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001         -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_lease_add_data_status -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- GL��v����ID
    gn_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_books_id );
    --
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001   -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name   -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_set_of_books_id -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �t�@�C�������ݒ肳��Ă���ꍇ
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    -- �t�@�C���������ݒ�̏ꍇ
    ELSIF ( iv_file_name IS NULL ) THEN
      -- �ǉ��X�V�敪��'0'�i�ǉ��j�̏ꍇ
      IF ( iv_ins_upd_kbn = cv_ins_upd_ins ) THEN
        -- �d�q���냊�[�X����f�[�^�ǉ��t�@�C����
        gv_file_name := FND_PROFILE.VALUE( cv_ins_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          -- �v���t�@�C���擾�G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_00001 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_prof_name -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_ins_filename  -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      -- �ǉ��X�V�敪��'1'�i�X�V�j�̏ꍇ
      ELSIF( iv_ins_upd_kbn = cv_ins_upd_upd ) THEN
        -- �d�q���냊�[�X����f�[�^�X�V�t�@�C����
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          -- �v���t�@�C���擾�G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_00001 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_prof_name -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_upd_filename  -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT ad.directory_path AS directory_path
      INTO   gt_directory_path
      FROM   all_directories ad
      WHERE  ad.directory_name = gt_directory_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi    -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_coi_00029  -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_dir_tok    -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => gt_directory_name -- �g�[�N���l1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- IF�t�@�C�����o��
    --==================================
    -- �f�B���N�g���̍Ō�ɃX���b�V��������ꍇ
    IF SUBSTRB(gt_directory_path, -1, 1) = cv_slash THEN
      --
      lv_file_name := gt_directory_path || gv_file_name;
    -- �f�B���N�g���̍Ō�ɃX���b�V�����Ȃ��ꍇ
    ELSE
      --
      lv_file_name := gt_directory_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_if_file_name := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo    -- �A�v���P�[�V�����Z�k��
                                               , iv_name         => cv_msg_cfo_00002  -- ���b�Z�[�W�R�[�h
                                               , iv_token_name1  => cv_tkn_file_name  -- �g�[�N���R�[�h1
                                               , iv_token_value1 => lv_file_name      -- �g�[�N���l1
                                               );
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_if_file_name
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==================================
    -- ����t�@�C�����݃`�F�b�N
    --==================================
    UTL_FILE.FGETATTR(
        location    => gt_directory_name
      , filename    => gv_file_name
      , fexists     => lb_exists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo    -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00027  -- ���b�Z�[�W�R�[�h
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==================================
    -- �Œ蕶���擾
    --==================================
    -- �o�͗p����
    gv_msg_cfo_11072 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11072 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11073 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11073 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11074 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11074 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11075 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11075 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11076 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11076 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11077 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11077 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11078 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11078 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11086 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11086 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11088 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11088 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11091 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11091 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11092 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11092 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11093 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11093 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11094 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11094 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11095 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11095 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11096 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11096 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
      -- �J�[�\���N���[�Y
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_wait_coop
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_lease_wait_coop(
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_wait_coop'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- ���[�X������A�g�f�[�^�擾�J�[�\���i������s�j
    CURSOR lease_wait_coop_0_cur
    IS
      SELECT xlwc.period_name      AS period_name -- ��v����
           , xlwc.object_code      AS object_code -- �����R�[�h
           , xlwc.rowid            AS xlwc_rowid  -- ROWID
      FROM   xxcfo_lease_wait_coop xlwc
      WHERE  xlwc.set_of_books_id = gn_set_of_books_id
      FOR UPDATE NOWAIT
    ;
    -- ���[�X������A�g�f�[�^�擾�J�[�\���i�蓮���s�j
    CURSOR lease_wait_coop_1_cur
    IS
      SELECT xlwc.period_name      AS period_name -- ��v����
           , xlwc.object_code      AS object_code -- �����R�[�h
           , xlwc.rowid            AS xlwc_rowid  -- ROWID
      FROM   xxcfo_lease_wait_coop xlwc
      WHERE  xlwc.set_of_books_id = gn_set_of_books_id
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- ���[�X������A�g�f�[�^�擾
    --==============================================================
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- �J�[�\���I�[�v��
      OPEN lease_wait_coop_0_cur;
      --
      FETCH lease_wait_coop_0_cur BULK COLLECT INTO g_lease_wait_coop_tab;
      -- �J�[�\���N���[�Y
      CLOSE lease_wait_coop_0_cur;
      --
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- �J�[�\���I�[�v��
      OPEN lease_wait_coop_1_cur;
      --
      FETCH lease_wait_coop_1_cur BULK COLLECT INTO g_lease_wait_coop_tab;
      -- �J�[�\���N���[�Y
      CLOSE lease_wait_coop_1_cur;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00019 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11070 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( lease_wait_coop_0_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_0_cur;
      END IF;
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
      -- �J�[�\�����I�[�v�����Ă���ꍇ
      IF ( lease_wait_coop_0_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_0_cur;
      ELSIF ( lease_wait_coop_1_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_1_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_lease_control(
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_control'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- ���[�X����Ǘ��f�[�^�擾
    --==============================================================
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        SELECT TO_CHAR(ADD_MONTHS(TO_DATE(xlc.period_name, cv_format_yyyymm), 1), cv_format_yyyymm) AS next_period_name -- ����v����
             , xlc.rowid                                                                            AS xlc_rowid        -- ROWID
        INTO   gt_next_period_name
             , gt_xlc_rowid
        FROM   xxcfo_lease_control   xlc
        WHERE  xlc.set_of_books_id = gn_set_of_books_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �擾�Ώۃf�[�^�Ȃ����b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10025 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_get_data  -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11071 -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
      BEGIN
        SELECT xlc.period_name     AS period_name -- ����v����
        INTO   gt_next_period_name
        FROM   xxcfo_lease_control xlc
        WHERE  xlc.set_of_books_id = gn_set_of_books_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �擾�Ώۃf�[�^�Ȃ����b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10025 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_get_data  -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11071 -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf  := lv_errmsg;
          -- �x���t���O
          gv_warn_flg := cv_flag_y;
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_warn;
      END;
      --
    END IF;
--
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_file_handle := UTL_FILE.FOPEN(
                           location  => gt_directory_name
                         , filename  => gv_file_name
                         , open_mode => cv_open_mode_w
                        );
      -- �t�@�C���I�[�v���t���O
      gv_file_open_flg := cv_flag_y;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_00029 -- ���b�Z�[�W�R�[�h
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00019 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11071 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_periods
   * Description      : ��v���ԃ`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE chk_periods(
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_periods'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- ��v���ԃ`�F�b�N
    --==============================================================
    SELECT COUNT(1)           AS cnt
    INTO   gn_period_chk
    FROM   gl_period_statuses gps -- ��v�J�����_�X�e�[�^�X
         , fnd_application    fa  -- �A�v���P�[�V����
    WHERE  gps.application_id         = fa.application_id
    AND    fa.application_short_name  = cv_application_short_name
    AND    gps.adjustment_period_flag = cv_adjustment_period_flag
    AND    gps.closing_status         = cv_closing_status
    AND    gps.set_of_books_id        = gn_set_of_books_id
    AND    TRUNC(gps.last_update_date) + gn_electric_exec_days <= gd_process_date
    AND    gps.period_name            = gt_next_period_name
    ;
    --
    -- ��v���Ԃ��N���[�Y����Ă��Ȃ��ꍇ
    IF ( gn_period_chk = 0 ) THEN
      -- �����̉�v���Ԃ�NULL�ɂ���
      gt_next_period_name := NULL;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_periods;
--
  /**********************************************************************************
   * Procedure Name   : get_add_info
   * Description      : �t�����擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_add_info(
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_info'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- �t�����擾�J�[�\��
    CURSOR get_add_info_cur
    IS
-- 2012/11/26 1.1 K.Nakamura MOD START
--      SELECT xch.update_reason         AS update_reason -- �X�V���R
      SELECT /* INDEX(xch XXCFF_CONTRACT_HISTORIES_PK) */
             xch.update_reason         AS update_reason -- �X�V���R
-- 2012/11/26 1.1 K.Nakamura MOD END
      FROM   xxcff_contract_histories  xch
      WHERE  xch.contract_line_id = g_data_tab(19)
      AND    xch.period_name      = g_data_tab(44)
      AND    xch.contract_status  = gv_lease_add_data_status
-- 2012/11/26 1.1 K.Nakamura ADD START
      AND    xch.contract_header_id = gn_contract_header_id
-- 2012/11/26 1.1 K.Nakamura ADD END
      ORDER BY xch.history_num DESC
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �t�����擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_add_info_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_add_info_cur BULK COLLECT INTO g_data_update_tab;
    -- �J�[�\���N���[�Y
    CLOSE get_add_info_cur;
    --
    -- �擾�f�[�^�����݂���ꍇ
    IF ( g_data_update_tab.COUNT > 0 ) THEN
      -- �f�[�^�ύX�t���O
      g_data_tab(60) := cv_upd_on;
      -- �f�[�^�ύX���e
      g_data_tab(61) := g_data_update_tab(1);
    ELSE
      -- �f�[�^�ύX�t���O
      g_data_tab(60) := cv_upd_off;
      -- �f�[�^�ύX���e
      g_data_tab(61) := NULL;
    END IF;
    --
-- 2012/11/26 1.1 K.Nakamura ADD START
    -- ������
    g_data_update_tab.DELETE;
    gn_contract_header_id := NULL;
-- 2012/11/26 1.1 K.Nakamura ADD END
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
  END get_add_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn   IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- �v���O������
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
    ln_chk_cnt                NUMBER       DEFAULT NULL; -- �`�F�b�N�p����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �]�L�σ`�F�b�N
    --==============================================================
    -- ����蓮�敪��'0'�i����j���A����܂��͉�v���Ԃ��ύX���ꂽ�ꍇ
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( ( gt_period_name IS NULL )
       OR   ( gt_period_name <> g_data_tab(44) ) ) )
    THEN
      -- �d�󖢓]�L�t���O������
      gv_gl_je_flg := NULL;
      --
      BEGIN
        SELECT COUNT(1)
        INTO   ln_chk_cnt
        FROM   gl_je_headers    gjh -- �d��w�b�_
             , gl_je_sources    gjs -- GL�d��\�[�X
             , gl_je_categories gjc -- GL�d��J�e�S��
        WHERE  gjh.je_category           = gjc.je_category_name
        AND    gjh.je_source             = gjs.je_source_name
        AND    gjc.user_je_category_name IN ( gv_msg_cfo_11092   -- ���[�X���
                                            , gv_msg_cfo_11093   -- ���[�X���v��Ŋz
                                            , gv_msg_cfo_11094   -- ���[�X���U��
                                            , gv_msg_cfo_11095   -- ���[�X���U��
                                            , gv_msg_cfo_11096 ) -- ���[�X�����啊��
        AND    gjs.user_je_source_name   =  gv_msg_cfo_11091     -- ���[�X
        AND    gjh.actual_flag           =  cv_result_flag       -- �eA�f�i���сj
        AND    gjh.status                =  cv_status_p          -- �eP�f�i�]�L�ρj
        AND    gjh.period_name           =  g_data_tab(44)
        AND    gjh.set_of_books_id       =  gn_set_of_books_id
        ;
        -- ��v���ԕێ�
        gt_period_name := g_data_tab(44);
        --
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_process_expt;
      END;
      -- �擾0���̏ꍇ
      IF ( ln_chk_cnt = 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10005 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_key_item  -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => gv_msg_cfo_11073 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_key_value -- �g�[�N���R�[�h1
                                                     , iv_token_value2 => g_data_tab(44)   -- �g�[�N���l1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- �d�󖢓]�L�t���O
        gv_gl_je_flg := cv_flag_y;
        RAISE global_warn_expt;
        --
      END IF;
      --
    -- ����蓮�敪��'0'�i����j���A�O��Ɠ���̎d�󖢓]�L�̉�v���Ԃ̏ꍇ
    ELSIF ( ( iv_exec_kbn = cv_exec_fixed_period )
      AND   ( gv_gl_je_flg IS NOT NULL )
      AND   ( gt_period_name = g_data_tab(44) ) )
    THEN
      RAISE global_gl_je_expt;
    END IF;
--
    --==============================================================
    -- ���A�g�f�[�^�`�F�b�N
    --==============================================================
    -- ����蓮�敪��'1'�i�蓮�j���A���A�g�f�[�^�����݂���ꍇ
    IF (  ( iv_exec_kbn = cv_exec_manual )
      AND ( g_lease_wait_coop_tab.COUNT > 0 ) )
    THEN
      --
      <<chk_wait_coop_loop>>
      FOR i IN g_lease_wait_coop_tab.FIRST .. g_lease_wait_coop_tab.COUNT LOOP
        IF (  ( g_lease_wait_coop_tab( i ).period_name = g_data_tab(44) )
          AND ( g_lease_wait_coop_tab( i ).object_code = g_data_tab(37) ) )
        THEN
          -- �G���[���b�Z�[�W�ҏW
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10010   -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_doc_data    -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073   -- �g�[�N���l1
                                                       , iv_token_name2  => cv_tkn_doc_dist_id -- �g�[�N���R�[�h2
                                                       , iv_token_value2 => g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)      -- �g�[�N���l2
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- �X�L�b�v�t���O
          gv_skip_flg := cv_flag_y;
          -- 1���ł��x�����������甲����
          RAISE global_warn_expt;
          --
        END IF;
        --
      END LOOP chk_wait_coop_loop;
      --
    END IF;
    --
    --==============================================================
    -- ���ڃ`�F�b�N
    --==============================================================
    <<chk_item_loop>>
    FOR ln_cnt IN g_data_tab.FIRST .. g_data_tab.COUNT LOOP
      -- YYYYMMDDHH24MISS�t�H�[�}�b�g�i�A�g�����j�̓G���[�ɂȂ邽�߁A�`�F�b�N���Ȃ�
      IF ( ln_cnt <> 62 ) THEN
        -- ���ڃ`�F�b�N���ʊ֐�
        xxcfo_common_pkg2.chk_electric_book_item(
            iv_item_name    => g_chk_item_tab(ln_cnt).meaning    -- ���ږ���
          , iv_item_value   => g_data_tab(ln_cnt)                -- �ύX�O�̒l
          , in_item_len     => g_chk_item_tab(ln_cnt).attribute1 -- ���ڂ̒���
          , in_item_decimal => g_chk_item_tab(ln_cnt).attribute2 -- ���ڂ̒���(�����_�ȉ�)
          , iv_item_nullflg => g_chk_item_tab(ln_cnt).attribute3 -- �K�{�t���O
          , iv_item_attr    => g_chk_item_tab(ln_cnt).attribute4 -- ���ڑ���
          , iv_item_cutflg  => g_chk_item_tab(ln_cnt).attribute5 -- �؎̂ăt���O
          , ov_item_value   => g_data_tab(ln_cnt)                -- ���ڂ̒l
          , ov_errbuf       => lv_errbuf                         -- �G���[���b�Z�[�W
          , ov_retcode      => lv_retcode                        -- ���^�[���R�[�h
          , ov_errmsg       => lv_errmsg                         -- ���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      -- �x���̏ꍇ
      IF ( lv_retcode = cv_status_warn ) THEN
        -- �����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
        IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
          --
          -- �G���[���b�Z�[�W�ҏW
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10011   -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_key_data    -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073 ||
                                                                            cv_msg_part      ||
                                                                            g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)     -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- ����̏ꍇ
          -- �蓮���A'0'�i�ǉ��j�̏ꍇ
          IF ( ( iv_exec_kbn = cv_exec_fixed_period )
          OR   ( ( iv_exec_kbn = cv_exec_manual )
            AND  ( iv_ins_upd_kbn = cv_ins_upd_ins ) ) )
          THEN
            -- �X�L�b�v�t���O
            gv_skip_flg := cv_flag_y;
            -- 1���ł��x�����������甲����
            RAISE global_warn_expt;
          -- �蓮���A'1'�i�X�V�j�̏ꍇ
          ELSIF ( ( iv_exec_kbn = cv_exec_manual )
            AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
          THEN
            RAISE global_process_expt;
          END IF;
          --
        -- �����`�F�b�N�ȊO
        ELSE
          -- ���ʊ֐��̃G���[���b�Z�[�W���o��
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10007   -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_cause       -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11008   -- �g�[�N���l1
                                                       , iv_token_name2  => cv_tkn_target      -- �g�[�N���R�[�h2
                                                       , iv_token_value2 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073 ||
                                                                            cv_msg_part      ||
                                                                            g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)     -- �g�[�N���l2
                                                       , iv_token_name3  => cv_tkn_meaning     -- �g�[�N���R�[�h3
                                                       , iv_token_value3 => lv_errmsg          -- �g�[�N���l3
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- ����̏ꍇ
          -- �蓮���A'0'�i�ǉ��j�̏ꍇ
          IF ( ( iv_exec_kbn = cv_exec_fixed_period )
          OR   ( ( iv_exec_kbn = cv_exec_manual )
            AND  ( iv_ins_upd_kbn = cv_ins_upd_ins ) ) )
          THEN
            -- 1���ł��x�����������甲����
            RAISE global_warn_expt;
          -- �蓮���A'1'�i�X�V�j�̏ꍇ
          ELSIF ( ( iv_exec_kbn = cv_exec_manual )
            AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
          THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
      -- �G���[�̏ꍇ
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP chk_item_loop;
--
  EXCEPTION
    -- �x���̏ꍇ
    WHEN global_warn_expt THEN
      -- �x���t���O
      gv_warn_flg := cv_flag_y;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    -- �d�󖢓]�L�ŏo�͍ς̏ꍇ
    WHEN global_gl_je_expt THEN
      -- �������Ȃ�
      ov_retcode := cv_status_warn;
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : �b�r�u�o�͏���(A-8)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- �v���O������
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
    lv_file_data              VARCHAR2(32767) DEFAULT NULL; -- �o�͓��e
    lv_delimit                VARCHAR2(1);                  -- �J���}
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    -- ������
    lv_file_data := NULL;
    -- �f�[�^�ҏW
    <<out_csv_loop>>
    FOR ln_cnt IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      -- �J���}�̕t�^
      IF ( ln_cnt = g_chk_item_tab.FIRST ) THEN
        -- ���߂̍��ڂ̓J���}��
        lv_delimit := NULL;
      ELSE
        -- 2��ڈȍ~�̓J���}
        lv_delimit := cv_delimit;
      END IF;
      --
      -- VARCHAR2,CHAR2�i��������L�j
      IF ( g_chk_item_tab(ln_cnt).attribute4 IN ( cv_attr_vc2, cv_attr_cha ) ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_dobule_quote || REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt), CHR(10), ' '), '"', ' '), ',', ' ')
                                                      || cv_dobule_quote;
      -- NUMBER�i�������薳�j
      ELSIF ( g_chk_item_tab(ln_cnt).attribute4 = cv_attr_num ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || g_data_tab(ln_cnt);
      -- DATE�i�������薳�i������ϊ���̒l�j�j
      ELSIF ( g_chk_item_tab(ln_cnt).attribute4 = cv_attr_dat ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || g_data_tab(ln_cnt);
      END IF;
    END LOOP out_csv_loop;
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
      UTL_FILE.PUT_LINE( gv_file_handle
                       , lv_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cfo
                      , iv_name         => cv_msg_cfo_00030
                      );
      RAISE global_api_others_expt;
    END;
    --
    -- ���������J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : ins_lease_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_lease_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_wait_coop'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- ���A�g�f�[�^�o�^
    --==============================================================
    BEGIN
      INSERT INTO xxcfo_lease_wait_coop(
          set_of_books_id           -- ��v����ID
        , period_name               -- ��v����
        , object_code               -- �����R�[�h
        , created_by                -- �쐬��
        , creation_date             -- �쐬��
        , last_updated_by           -- �ŏI�X�V��
        , last_update_date          -- �ŏI�X�V��
        , last_update_login         -- �ŏI�X�V���O�C��
        , request_id                -- �v��ID
        , program_application_id    -- �v���O�����A�v���P�[�V����ID
        , program_id                -- �v���O����ID
        , program_update_date       -- �v���O�����X�V��
      ) VALUES (
          gn_set_of_books_id        -- ��v����ID
        , g_data_tab(44)            -- ��v����
        , g_data_tab(37)            -- �����R�[�h
        , cn_created_by             -- �쐬��
        , cd_creation_date          -- �쐬��
        , cn_last_updated_by        -- �ŏI�X�V��
        , cd_last_update_date       -- �ŏI�X�V��
        , cn_last_update_login      -- �ŏI�X�V���O�C��
        , cn_request_id             -- �v��ID
        , cn_program_application_id -- �v���O�����A�v���P�[�V����ID
        , cn_program_id             -- �v���O����ID
        , cd_program_update_date    -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_00024 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11070 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => SQLERRM          -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
    --
    -- ���A�g�����J�E���g
    gn_warn_cnt := gn_warn_cnt + 1;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_lease
   * Description      : �Ώۃf�[�^�擾(A-5)
   ***********************************************************************************/
  PROCEDURE get_lease(
    iv_ins_upd_kbn   IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_period_name   IN  VARCHAR2, -- ��v����
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease'; -- �v���O������
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
    lv_chk_coop               VARCHAR2(1);  -- �A�g���A�g����p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �Ώۃf�[�^�擾�J�[�\���i�蓮���s�j
    CURSOR get_manual_cur( lv_period_name  IN xxcff_pay_planning.period_name%TYPE
                         )
    IS
      SELECT /*+ LEADING(xpp xcl xch xoh fab xft1)
                 USE_NL(xch xcl xoh xpp fab xft1)
              */
             fab.asset_id                                               AS asset_id                    -- ���YID
           , fab.asset_number                                           AS asset_number                -- ���Y�ԍ�
           , fab.attribute_category_code                                AS attribute_category_code     -- ���Y�J�e�S��
           , xch.contract_number                                        AS contract_number             -- �_��ԍ�
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon              ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- ���[�X��ʃr���[
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- ���[�X���
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- ���[�X�敪
           , xch.lease_company                                          AS lease_company               -- ���[�X��ЃR�[�h
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- ���[�X��Ѓr���[
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- ���[�X��Ж�
           , xch.re_lease_times                                         AS re_lease_times              -- �ă��[�X��
           , xch.comments                                               AS comments                    -- ����
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- ���[�X�_���
           , xch.payment_frequency                                      AS payment_frequency           -- �x����
           , xch.payment_type                                           AS payment_type                -- �p�x
           , xch.payment_years                                          AS payment_years               -- �N��
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- ���[�X�J�n��
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- ���[�X�I����
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- ����x����
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2��ڎx����
           , xcl.contract_line_id                                       AS contract_line_id            -- �_�񖾍ד���ID
           , xcl.contract_line_num                                      AS contract_line_num           -- �_��}��
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon                  ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- �_��X�e�[�^�X�r���[
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- �_��X�e�[�^�X
           , xcl.gross_charge                                           AS gross_charge                -- ���z���[�X��_���[�X��
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- ���z�����_���[�X��
           , xcl.gross_total_charge                                     AS gross_total_charge          -- ���z�v_���[�X��
           , xcl.gross_deduction                                        AS gross_deduction             -- ���z���[�X��_�T���z
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- ���z�����_�T���z
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- ���z�v_�T���z
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- ���[�X���
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- ���ό����w�����z
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- ���݉��l������
           , xcl.present_value                                          AS present_value               -- ���݉��l
           , xcl.life_in_months                                         AS life_in_months              -- �@��ϗp�N��
           , xcl.original_cost                                          AS original_cost               -- �擾���z
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- �v�Z���q��
           , xcl.asset_category                                         AS asset_category              -- ���Y���
           , xoh.object_header_id                                       AS object_header_id            -- ��������ID
           , xoh.object_code                                            AS object_code                 -- �����R�[�h
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- �����X�e�[�^�X�r���[
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- �����X�e�[�^�X
           , xoh.department_code                                        AS department_code             -- �Ǘ�����R�[�h
           , xoh.owner_company                                          AS owner_company               -- �{��_�H��
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- ���r����
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- ������
           , xpp.payment_frequency                                      AS payment_frequency           -- �x����
           , xpp.period_name                                            AS period_name                 -- ��v����
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- �x����
           , xpp.lease_charge                                           AS lease_charge                -- ���[�X��
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- ���[�X��_�����
           , xpp.lease_deduction                                        AS lease_deduction             -- ���[�X�T���z
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- ���[�X�T���z_�����
           , xpp.op_charge                                              AS op_charge                   -- �n�o���[�X��
           , xpp.op_tax_charge                                          AS op_tax_charge               -- �n�o���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_debt                                               AS fin_debt                    -- �e�h�m���[�X���z
           , NVL(xpp.fin_debt,0)         + NVL(xpp.debt_re,0)           AS fin_debt                    -- �e�h�m���[�X���z
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- �e�h�m���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_interest_due                                       AS fin_interest_due            -- �e�h�m���[�X�x������
           , NVL(xpp.fin_interest_due,0) + NVL(xpp.interest_due_re,0)   AS fin_interest_due            -- �e�h�m���[�X�x������
--           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- �e�h�m���[�X���c
           , NVL(xpp.fin_debt_rem,0)     + NVL(xpp.debt_rem_re,0)       AS fin_debt_rem                -- �e�h�m���[�X���c
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- �e�h�m���[�X���c_�����
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- ����^�C�v
           , xft1.period_name                                           AS period_name                 -- ���GL�]����v����
           , xpp.payment_match_flag                                     AS payment_match_flag          -- �ƍ��σt���O
           , NULL                                                       AS data_update_flag            -- �f�[�^�ύX�t���O
           , NULL                                                       AS data_update_info            -- �f�[�^�ύX���e
           , gv_coop_date                                               AS gv_coop_date                -- �A�g����
-- 2012/11/26 1.1 K.Nakamura ADD START
           , xch.contract_header_id                                     AS contract_header_id          -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
      FROM   xxcff_contract_headers xch -- ���[�X�_��
           , xxcff_contract_lines   xcl -- ���[�X�_�񖾍�
           , xxcff_object_headers   xoh -- ���[�X����
           , xxcff_pay_planning     xpp -- ���[�X�x���v��
           , fa_additions_b         fab -- ���Y�ڍ׏��
           , ( SELECT xft.transaction_type  AS transaction_type -- ����^�C�v
                    , xft.contract_line_id  AS contract_line_id -- �_�񖾍�ID
                    , xft.period_name       AS period_name      -- ��v����
               FROM   xxcff_fa_transactions xft -- ���[�X���
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- �C�����C���r���[
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
-- 2012-12-19 1.2 T.Osawa MOD START
--    AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND (( xpp.accounting_if_flag <> cv_accounting_if_flag_0 )
      OR   ( xpp.accounting_if_flag = cv_accounting_if_flag_0 
      AND    xft1.transaction_type  = cv_transaction_type_3 ))
-- 2012-12-19 1.2 T.Osawa MOD END
      AND    xpp.period_name         = lv_period_name
    ;
    --
    -- �Ώۃf�[�^�擾�J�[�\���i������s�j
    CURSOR get_fixed_period_cur( lv_period_name  IN xxcff_pay_planning.period_name%TYPE
                               )
    IS
-- 2012/11/26 1.1 K.Nakamura MOD START
--      SELECT cv_wait_coop                                               AS chk_coop                    -- ����
      SELECT /*+ LEADING(xlwc xoh xcl xpp xch fab xft1)
                 USE_NL(xch xcl xoh xpp fab xft1)
              */
             cv_wait_coop                                               AS chk_coop                    -- ����
-- 2012/11/26 1.1 K.Nakamura MOD END
           , fab.asset_id                                               AS asset_id                    -- ���YID
           , fab.asset_number                                           AS asset_number                -- ���Y�ԍ�
           , fab.attribute_category_code                                AS attribute_category_code     -- ���Y�J�e�S��
           , xch.contract_number                                        AS contract_number             -- �_��ԍ�
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- ���[�X��ʃr���[
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- ���[�X���
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- ���[�X�敪
           , xch.lease_company                                          AS lease_company               -- ���[�X��ЃR�[�h
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- ���[�X��Ѓr���[
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- ���[�X��Ж�
           , xch.re_lease_times                                         AS re_lease_times              -- �ă��[�X��
           , xch.comments                                               AS comments                    -- ����
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- ���[�X�_���
           , xch.payment_frequency                                      AS payment_frequency           -- �x����
           , xch.payment_type                                           AS payment_type                -- �p�x
           , xch.payment_years                                          AS payment_years               -- �N��
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- ���[�X�J�n��
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- ���[�X�I����
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- ����x����
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2��ڎx����
           , xcl.contract_line_id                                       AS contract_line_id            -- �_�񖾍ד���ID
           , xcl.contract_line_num                                      AS contract_line_num           -- �_��}��
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- �_��X�e�[�^�X�r���[
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- �_��X�e�[�^�X
           , xcl.gross_charge                                           AS gross_charge                -- ���z���[�X��_���[�X��
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- ���z�����_���[�X��
           , xcl.gross_total_charge                                     AS gross_total_charge          -- ���z�v_���[�X��
           , xcl.gross_deduction                                        AS gross_deduction             -- ���z���[�X��_�T���z
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- ���z�����_�T���z
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- ���z�v_�T���z
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- ���[�X���
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- ���ό����w�����z
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- ���݉��l������
           , xcl.present_value                                          AS present_value               -- ���݉��l
           , xcl.life_in_months                                         AS life_in_months              -- �@��ϗp�N��
           , xcl.original_cost                                          AS original_cost               -- �擾���z
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- �v�Z���q��
           , xcl.asset_category                                         AS asset_category              -- ���Y���
           , xoh.object_header_id                                       AS object_header_id            -- ��������ID
           , xoh.object_code                                            AS object_code                 -- �����R�[�h
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- �����X�e�[�^�X�r���[
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- �����X�e�[�^�X
           , xoh.department_code                                        AS department_code             -- �Ǘ�����R�[�h
           , xoh.owner_company                                          AS owner_company               -- �{��_�H��
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- ���r����
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- ������
           , xpp.payment_frequency                                      AS payment_frequency           -- �x����
           , xpp.period_name                                            AS period_name                 -- ��v����
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- �x����
           , xpp.lease_charge                                           AS lease_charge                -- ���[�X��
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- ���[�X��_�����
           , xpp.lease_deduction                                        AS lease_deduction             -- ���[�X�T���z
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- ���[�X�T���z_�����
           , xpp.op_charge                                              AS op_charge                   -- �n�o���[�X��
           , xpp.op_tax_charge                                          AS op_tax_charge               -- �n�o���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_debt                                               AS fin_debt                    -- �e�h�m���[�X���z
           , NVL(xpp.fin_debt,0)         + NVL(xpp.debt_re,0)           AS fin_debt                    -- �e�h�m���[�X���z
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- �e�h�m���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_interest_due                                       AS fin_interest_due            -- �e�h�m���[�X�x������
           , NVL(xpp.fin_interest_due,0) + NVL(xpp.interest_due_re,0)   AS fin_interest_due            -- �e�h�m���[�X�x������
--           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- �e�h�m���[�X���c
           , NVL(xpp.fin_debt_rem,0)     + NVL(xpp.debt_rem_re,0)       AS fin_debt_rem                -- �e�h�m���[�X���c
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- �e�h�m���[�X���c_�����
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- ����^�C�v
           , xft1.period_name                                           AS period_name                 -- ���GL�]����v����
           , xpp.payment_match_flag                                     AS payment_match_flag          -- �ƍ��σt���O
           , NULL                                                       AS data_update_flag            -- �f�[�^�ύX�t���O
           , NULL                                                       AS data_update_info            -- �f�[�^�ύX���e
           , gv_coop_date                                               AS gv_coop_date                -- �A�g����
-- 2012/11/26 1.1 K.Nakamura ADD START
           , xch.contract_header_id                                     AS contract_header_id          -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
      FROM   xxcff_contract_headers xch -- ���[�X�_��
           , xxcff_contract_lines   xcl -- ���[�X�_�񖾍�
           , xxcff_object_headers   xoh -- ���[�X����
           , xxcff_pay_planning     xpp -- ���[�X�x���v��
           , fa_additions_b         fab -- ���Y�ڍ׏��
           , ( SELECT xft.transaction_type  AS transaction_type -- ����^�C�v
                    , xft.contract_line_id  AS contract_line_id -- �_�񖾍�ID
                    , xft.period_name       AS period_name      -- ��v����
               FROM   xxcff_fa_transactions xft -- ���[�X���
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- �C�����C���r���[
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
-- 2012-12-19 1.2 T.Osawa MOD START
--      AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND (( xpp.accounting_if_flag <> cv_accounting_if_flag_0 )
      OR   ( xpp.accounting_if_flag = cv_accounting_if_flag_0 
      AND    xft1.transaction_type  = cv_transaction_type_3 ))
-- 2012-12-19 1.2 T.Osawa MOD END
      AND    EXISTS ( SELECT 'X'
                      FROM   xxcfo_lease_wait_coop xlwc -- ���[�X������A�g�e�[�u��
                      WHERE  xlwc.period_name = xpp.period_name
                      AND    xlwc.object_code = xoh.object_code )
      UNION ALL
      SELECT /*+ LEADING(xpp xcl xch xoh fab xft1) 
                 USE_NL(xch xcl xoh xpp fab xft1) 
              */
             cv_coop                                                    AS chk_coop                    -- ����
           , fab.asset_id                                               AS asset_id                    -- ���YID
           , fab.asset_number                                           AS asset_number                -- ���Y�ԍ�
           , fab.attribute_category_code                                AS attribute_category_code     -- ���Y�J�e�S��
           , xch.contract_number                                        AS contract_number             -- �_��ԍ�
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- ���[�X��ʃr���[
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- ���[�X���
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- ���[�X�敪
           , xch.lease_company                                          AS lease_company               -- ���[�X��ЃR�[�h
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- ���[�X��Ѓr���[
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- ���[�X��Ж�
           , xch.re_lease_times                                         AS re_lease_times              -- �ă��[�X��
           , xch.comments                                               AS comments                    -- ����
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- ���[�X�_���
           , xch.payment_frequency                                      AS payment_frequency           -- �x����
           , xch.payment_type                                           AS payment_type                -- �p�x
           , xch.payment_years                                          AS payment_years               -- �N��
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- ���[�X�J�n��
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- ���[�X�I����
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- ����x����
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2��ڎx����
           , xcl.contract_line_id                                       AS contract_line_id            -- �_�񖾍ד���ID
           , xcl.contract_line_num                                      AS contract_line_num           -- �_��}��
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- �_��X�e�[�^�X�r���[
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- �_��X�e�[�^�X
           , xcl.gross_charge                                           AS gross_charge                -- ���z���[�X��_���[�X��
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- ���z�����_���[�X��
           , xcl.gross_total_charge                                     AS gross_total_charge          -- ���z�v_���[�X��
           , xcl.gross_deduction                                        AS gross_deduction             -- ���z���[�X��_�T���z
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- ���z�����_�T���z
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- ���z�v_�T���z
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- ���[�X���
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- ���ό����w�����z
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- ���݉��l������
           , xcl.present_value                                          AS present_value               -- ���݉��l
           , xcl.life_in_months                                         AS life_in_months              -- �@��ϗp�N��
           , xcl.original_cost                                          AS original_cost               -- �擾���z
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- �v�Z���q��
           , xcl.asset_category                                         AS asset_category              -- ���Y���
           , xoh.object_header_id                                       AS object_header_id            -- ��������ID
           , xoh.object_code                                            AS object_code                 -- �����R�[�h
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- �����X�e�[�^�X�r���[
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- �����X�e�[�^�X
           , xoh.department_code                                        AS department_code             -- �Ǘ�����R�[�h
           , xoh.owner_company                                          AS owner_company               -- �{��_�H��
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- ���r����
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- ������
           , xpp.payment_frequency                                      AS payment_frequency           -- �x����
           , xpp.period_name                                            AS period_name                 -- ��v����
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- �x����
           , xpp.lease_charge                                           AS lease_charge                -- ���[�X��
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- ���[�X��_�����
           , xpp.lease_deduction                                        AS lease_deduction             -- ���[�X�T���z
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- ���[�X�T���z_�����
           , xpp.op_charge                                              AS op_charge                   -- �n�o���[�X��
           , xpp.op_tax_charge                                          AS op_tax_charge               -- �n�o���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_debt                                               AS fin_debt                    -- �e�h�m���[�X���z
           , NVL(xpp.fin_debt,0)         + NVL(xpp.debt_re,0)           AS fin_debt                    -- �e�h�m���[�X���z
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- �e�h�m���[�X���z_�����
-- 2016/08/25 Ver.1.3 Y.Koh MOD Start
--           , xpp.fin_interest_due                                       AS fin_interest_due            -- �e�h�m���[�X�x������
           , NVL(xpp.fin_interest_due,0) + NVL(xpp.interest_due_re,0)   AS fin_interest_due            -- �e�h�m���[�X�x������
--           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- �e�h�m���[�X���c
           , NVL(xpp.fin_debt_rem,0)     + NVL(xpp.debt_rem_re,0)       AS fin_debt_rem                -- �e�h�m���[�X���c
-- 2016/08/25 Ver.1.3 Y.Koh MOD End
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- �e�h�m���[�X���c_�����
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- ����^�C�v
           , xft1.period_name                                           AS period_name                 -- ���GL�]����v����
           , xpp.payment_match_flag                                     AS payment_match_flag          -- �ƍ��σt���O
           , NULL                                                       AS data_update_flag            -- �f�[�^�ύX�t���O
           , NULL                                                       AS data_update_info            -- �f�[�^�ύX���e
           , gv_coop_date                                               AS gv_coop_date                -- �A�g����
-- 2012/11/26 1.1 K.Nakamura ADD START
           , xch.contract_header_id                                     AS contract_header_id          -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
      FROM   xxcff_contract_headers xch -- ���[�X�_��
           , xxcff_contract_lines   xcl -- ���[�X�_�񖾍�
           , xxcff_object_headers   xoh -- ���[�X����
           , xxcff_pay_planning     xpp -- ���[�X�x���v��
           , fa_additions_b         fab -- ���Y�ڍ׏��
           , ( SELECT xft.transaction_type  AS transaction_type -- ����^�C�v
                    , xft.contract_line_id  AS contract_line_id -- �_�񖾍�ID
                    , xft.period_name       AS period_name      -- ��v����
               FROM   xxcff_fa_transactions xft -- ���[�X���
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- �C�����C���r���[
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
-- 2012-12-19 1.2 T.Osawa MOD START
--    AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND (( xpp.accounting_if_flag <> cv_accounting_if_flag_0 )
      OR   ( xpp.accounting_if_flag = cv_accounting_if_flag_0 
      AND    xft1.transaction_type  = cv_transaction_type_3 ))
-- 2012-12-19 1.2 T.Osawa MOD END
      AND    xpp.period_name         = lv_period_name
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�Ώۃf�[�^�擾
    --==============================================================
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- �J�[�\���I�[�v��
      OPEN get_manual_cur( iv_period_name
                         );
      --
      <<manual_loop>>
      LOOP
      FETCH get_manual_cur INTO
          g_data_tab(1)          -- ���YID
        , g_data_tab(2)          -- ���Y�ԍ�
        , g_data_tab(3)          -- ���Y�J�e�S��
        , g_data_tab(4)          -- �_��ԍ�
        , g_data_tab(5)          -- ���[�X���
        , g_data_tab(6)          -- ���[�X�敪
        , g_data_tab(7)          -- ���[�X��ЃR�[�h
        , g_data_tab(8)          -- ���[�X��Ж�
        , g_data_tab(9)          -- �ă��[�X��
        , g_data_tab(10)         -- ����
        , g_data_tab(11)         -- ���[�X�_���
        , g_data_tab(12)         -- �x����
        , g_data_tab(13)         -- �p�x
        , g_data_tab(14)         -- �N��
        , g_data_tab(15)         -- ���[�X�J�n��
        , g_data_tab(16)         -- ���[�X�I����
        , g_data_tab(17)         -- ����x����
        , g_data_tab(18)         -- 2��ڎx����
        , g_data_tab(19)         -- �_�񖾍ד���ID
        , g_data_tab(20)         -- �_��}��
        , g_data_tab(21)         -- �_��X�e�[�^�X
        , g_data_tab(22)         -- ���z���[�X��_���[�X��
        , g_data_tab(23)         -- ���z�����_���[�X��
        , g_data_tab(24)         -- ���z�v_���[�X��
        , g_data_tab(25)         -- ���z���[�X��_�T���z
        , g_data_tab(26)         -- ���z�����_�T���z
        , g_data_tab(27)         -- ���z�v_�T���z
        , g_data_tab(28)         -- ���[�X���
        , g_data_tab(29)         -- ���ό����w�����z
        , g_data_tab(30)         -- ���݉��l������
        , g_data_tab(31)         -- ���݉��l
        , g_data_tab(32)         -- �@��ϗp�N��
        , g_data_tab(33)         -- �擾���z
        , g_data_tab(34)         -- �v�Z���q��
        , g_data_tab(35)         -- ���Y���
        , g_data_tab(36)         -- ��������ID
        , g_data_tab(37)         -- �����R�[�h
        , g_data_tab(38)         -- �����X�e�[�^�X
        , g_data_tab(39)         -- �Ǘ�����R�[�h
        , g_data_tab(40)         -- �{�Ё^�H��
        , g_data_tab(41)         -- ���r����
        , g_data_tab(42)         -- ������
        , g_data_tab(43)         -- �x����
        , g_data_tab(44)         -- ��v����
        , g_data_tab(45)         -- �x����
        , g_data_tab(46)         -- ���[�X��
        , g_data_tab(47)         -- ���[�X��_�����
        , g_data_tab(48)         -- ���[�X�T���z
        , g_data_tab(49)         -- ���[�X�T���z_�����
        , g_data_tab(50)         -- �n�o���[�X��
        , g_data_tab(51)         -- �n�o���[�X���z_�����
        , g_data_tab(52)         -- �e�h�m���[�X���z
        , g_data_tab(53)         -- �e�h�m���[�X���z_�����
        , g_data_tab(54)         -- �e�h�m���[�X�x������
        , g_data_tab(55)         -- �e�h�m���[�X���c
        , g_data_tab(56)         -- �e�h�m���[�X���c_�����
        , g_data_tab(57)         -- ����^�C�v
        , g_data_tab(58)         -- ���GL�]����v����
        , g_data_tab(59)         -- �ƍ��σt���O
        , g_data_tab(60)         -- �f�[�^�ύX�t���O
        , g_data_tab(61)         -- �f�[�^�ύX���e
        , g_data_tab(62)         -- �A�g����
-- 2012/11/26 1.1 K.Nakamura ADD START
        , gn_contract_header_id  -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
        ;
        --
        -- �������i���[�v���̔���p���^�[���R�[�h�j
        lv_retcode := cv_status_normal;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_manual_cur%NOTFOUND;
        --
        -- �Ώی����i�A�g���j�J�E���g
        -- �蓮�̏ꍇ�͑Ώی����i���A�g���j�Ȃ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================
        -- �t�����擾����(A-6)
        -- ===============================
        get_add_info(
            lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- ���ڃ`�F�b�N����(A-7)
        -- ===============================
        chk_item(
            iv_ins_upd_kbn      -- �ǉ��X�V�敪
          , iv_exec_kbn         -- ����蓮�敪
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ����̏ꍇ
        IF (lv_retcode = cv_status_normal) THEN
          -- ===============================
          -- CSV�o�͏���(A-8)
          -- ===============================
          out_csv(
              lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END LOOP manual_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_manual_cur;
--
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- �J�[�\���I�[�v��
      OPEN get_fixed_period_cur( gt_next_period_name
                               );
      --
      <<fixed_period_main_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
          lv_chk_coop            -- �A�g���A�g����p
        , g_data_tab(1)          -- ���YID
        , g_data_tab(2)          -- ���Y�ԍ�
        , g_data_tab(3)          -- ���Y�J�e�S��
        , g_data_tab(4)          -- �_��ԍ�
        , g_data_tab(5)          -- ���[�X���
        , g_data_tab(6)          -- ���[�X�敪
        , g_data_tab(7)          -- ���[�X��ЃR�[�h
        , g_data_tab(8)          -- ���[�X��Ж�
        , g_data_tab(9)          -- �ă��[�X��
        , g_data_tab(10)         -- ����
        , g_data_tab(11)         -- ���[�X�_���
        , g_data_tab(12)         -- �x����
        , g_data_tab(13)         -- �p�x
        , g_data_tab(14)         -- �N��
        , g_data_tab(15)         -- ���[�X�J�n��
        , g_data_tab(16)         -- ���[�X�I����
        , g_data_tab(17)         -- ����x����
        , g_data_tab(18)         -- 2��ڎx����
        , g_data_tab(19)         -- �_�񖾍ד���ID
        , g_data_tab(20)         -- �_��}��
        , g_data_tab(21)         -- �_��X�e�[�^�X
        , g_data_tab(22)         -- ���z���[�X��_���[�X��
        , g_data_tab(23)         -- ���z�����_���[�X��
        , g_data_tab(24)         -- ���z�v_���[�X��
        , g_data_tab(25)         -- ���z���[�X��_�T���z
        , g_data_tab(26)         -- ���z�����_�T���z
        , g_data_tab(27)         -- ���z�v_�T���z
        , g_data_tab(28)         -- ���[�X���
        , g_data_tab(29)         -- ���ό����w�����z
        , g_data_tab(30)         -- ���݉��l������
        , g_data_tab(31)         -- ���݉��l
        , g_data_tab(32)         -- �@��ϗp�N��
        , g_data_tab(33)         -- �擾���z
        , g_data_tab(34)         -- �v�Z���q��
        , g_data_tab(35)         -- ���Y���
        , g_data_tab(36)         -- ��������ID
        , g_data_tab(37)         -- �����R�[�h
        , g_data_tab(38)         -- �����X�e�[�^�X
        , g_data_tab(39)         -- �Ǘ�����R�[�h
        , g_data_tab(40)         -- �{�Ё^�H��
        , g_data_tab(41)         -- ���r����
        , g_data_tab(42)         -- ������
        , g_data_tab(43)         -- �x����
        , g_data_tab(44)         -- ��v����
        , g_data_tab(45)         -- �x����
        , g_data_tab(46)         -- ���[�X��
        , g_data_tab(47)         -- ���[�X��_�����
        , g_data_tab(48)         -- ���[�X�T���z
        , g_data_tab(49)         -- ���[�X�T���z_�����
        , g_data_tab(50)         -- �n�o���[�X��
        , g_data_tab(51)         -- �n�o���[�X���z_�����
        , g_data_tab(52)         -- �e�h�m���[�X���z
        , g_data_tab(53)         -- �e�h�m���[�X���z_�����
        , g_data_tab(54)         -- �e�h�m���[�X�x������
        , g_data_tab(55)         -- �e�h�m���[�X���c
        , g_data_tab(56)         -- �e�h�m���[�X���c_�����
        , g_data_tab(57)         -- ����^�C�v
        , g_data_tab(58)         -- ���GL�]����v����
        , g_data_tab(59)         -- �ƍ��σt���O
        , g_data_tab(60)         -- �f�[�^�ύX�t���O
        , g_data_tab(61)         -- �f�[�^�ύX���e
        , g_data_tab(62)         -- �A�g����
-- 2012/11/26 1.1 K.Nakamura ADD START
        , gn_contract_header_id  -- �_�����ID
-- 2012/11/26 1.1 K.Nakamura ADD END
        ;
        --
        -- �������i���[�v���̔���p���^�[���R�[�h�j
        lv_retcode  := cv_status_normal;
        gv_skip_flg := NULL;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
        --
        -- �Ώی����i�A�g���j�J�E���g
        IF ( lv_chk_coop = cv_coop ) THEN
          gn_target_cnt := gn_target_cnt + 1;
        -- �Ώی����i���A�g���j�J�E���g
        ELSIF ( lv_chk_coop = cv_wait_coop ) THEN
          gn_target2_cnt := gn_target2_cnt + 1;
        END IF;
        --
        -- ===============================
        -- �t�����擾����(A-6)
        -- ===============================
        get_add_info(
            lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- ���ڃ`�F�b�N����(A-7)
        -- ===============================
        chk_item(
            iv_ins_upd_kbn      -- �ǉ��X�V�敪
          , iv_exec_kbn         -- ����蓮�敪
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ����̏ꍇ
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ===============================
          -- CSV�o�͏���(A-8)
          -- ===============================
          out_csv(
              lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        -- �x���̏ꍇ
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- �X�L�b�v�t���O���ݒ肳��Ă��Ȃ��ꍇ
          IF ( gv_skip_flg IS NULL ) THEN
            -- ===============================
            -- ���A�g�e�[�u���o�^����(A-9)
            -- ===============================
            ins_lease_wait_coop(
                lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          --
          END IF;
          --
        END IF;
        --
      END LOOP fixed_period_main_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_fixed_period_cur;
      --
    END IF;
--
    -- �Ώ�0���̏ꍇ
    IF (  ( gn_target_cnt = 0 )
      AND ( gn_target2_cnt = 0 ) )
    THEN
      -- �擾�Ώۃf�[�^�������b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_10025 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_get_data  -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11069 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      -- �x���t���O
      gv_warn_flg := cv_flag_y;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
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
      IF ( get_manual_cur%ISOPEN ) THEN
        CLOSE get_manual_cur;
      ELSIF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease;
--
  /**********************************************************************************
   * Procedure Name   : del_lease_wait_coop
   * Description      : ���A�g�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_lease_wait_coop(
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_wait_coop'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- ���A�g�f�[�^�폜
    --==============================================================
    <<delete_loop>>
    FOR i IN g_lease_wait_coop_tab.FIRST .. g_lease_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_lease_wait_coop xlwc
        WHERE       xlwc.rowid = g_lease_wait_coop_tab( i ).xlwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_00025 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11070 -- �g�[�N���l1
                                                       , iv_token_name2  => cv_tkn_errmsg    -- �g�[�N���R�[�h2
                                                       , iv_token_value2 => SQLERRM          -- �g�[�N���l2
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END;
    END LOOP delete_loop;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_lease_control
   * Description      : �Ǘ��e�[�u���X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE upd_lease_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lease_control'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- ���[�X����Ǘ��e�[�u���X�V
    --==============================================================
    BEGIN
      UPDATE xxcfo_lease_control xlc
      SET    xlc.period_name            = gt_next_period_name       -- ��v����
           , xlc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           , xlc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           , xlc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           , xlc.request_id             = cn_request_id             -- �v��ID
           , xlc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           , xlc.program_id             = cn_program_id             -- �v���O����ID
           , xlc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xlc.rowid                  = gt_xlc_rowid              -- ROWID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_00020 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11071 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => SQLERRM          -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_lease_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn   IN  VARCHAR2,      --   �ǉ��X�V�敪
    iv_file_name     IN  VARCHAR2,      --   �t�@�C����
    iv_period_name   IN  VARCHAR2,      --   ��v����
    iv_exec_kbn      IN  VARCHAR2,      --   ����蓮�敪
    ov_errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_target2_cnt := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
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
        iv_ins_upd_kbn      -- �ǉ��X�V�敪
      , iv_file_name        -- �t�@�C����
      , iv_period_name      -- ��v����
      , iv_exec_kbn         -- ����蓮�敪
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_lease_wait_coop(
        iv_exec_kbn         -- ����蓮�敪
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_lease_control(
        iv_exec_kbn         -- ����蓮�敪
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- ===============================
      -- ��v���ԃ`�F�b�N����(A-4)
      -- ===============================
      chk_periods(
          lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    -- ������s���A���A�g�f�[�^�����݂���ꍇ
    -- ������s���A��v���ԃ`�F�b�N������0���傫���ꍇ�i�����Ώۓ��̏ꍇ�j
    -- ��L�ł͖����ꍇ�A�������ł͖������߁A�I��
    IF ( ( iv_exec_kbn = cv_exec_manual )
      OR ( ( iv_exec_kbn = cv_exec_fixed_period ) AND ( g_lease_wait_coop_tab.COUNT > 0 ) )
      OR ( ( iv_exec_kbn = cv_exec_fixed_period ) AND ( gn_period_chk > 0 ) ) )
    THEN
      -- ===============================
      -- �Ώۃf�[�^�擾(A-4)
      -- ===============================
      get_lease(
          iv_ins_upd_kbn      -- �ǉ��X�V�敪
        , iv_period_name      -- ��v����
        , iv_exec_kbn         -- ����蓮�敪
        , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ����蓮�敪��'0'�i����j�̏ꍇ
      -- �蓮�͓o�^�E�X�V�E�폜�Ȃ�
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
--
        -- A-2�Ŗ��A�g�f�[�^�����݂����ꍇ
        IF ( g_lease_wait_coop_tab.COUNT > 0 ) THEN
          -- ===============================
          -- ���A�g�e�[�u���폜����(A-10)
          -- ===============================
          del_lease_wait_coop(
              lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
--
        -- �����Ώۓ��̏ꍇ
        IF ( gn_period_chk > 0 ) THEN
          -- ===============================
          -- �Ǘ��e�[�u���X�V����(A-11)
          -- ===============================
          upd_lease_control(
              lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END IF;
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
    errbuf           OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode          OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_ins_upd_kbn   IN  VARCHAR2,      --   �ǉ��X�V�敪
    iv_file_name     IN  VARCHAR2,      --   �t�@�C����
    iv_period_name   IN  VARCHAR2,      --   ��v����
    iv_exec_kbn      IN  VARCHAR2       --   ����蓮�敪
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
        iv_ins_upd_kbn    -- �ǉ��X�V�敪
      , iv_file_name      -- �t�@�C����
      , iv_period_name    -- ��v����
      , iv_exec_kbn       -- ����蓮�敪
      , lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt  := 0;
      gn_target2_cnt := 0;
      gn_normal_cnt  := 0;
      gn_error_cnt   := 1;
      gn_warn_cnt    := 0;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================================
    -- �t�@�C���N���[�Y
    -- ===============================================
    -- �t�@�C�����I�[�v������Ă���ꍇ
    IF ( gv_file_open_flg IS NOT NULL ) THEN
      IF ( UTL_FILE.IS_OPEN( gv_file_handle ) ) THEN
        -- �N���[�Y
        UTL_FILE.FCLOSE( gv_file_handle );
      END IF;
      --
      --�蓮���s���A�G���[���������Ă����ꍇ�A�t�@�C���̃I�[�v���E�N���[�Y��0�o�C�g�ɂ���
      IF (  ( iv_exec_kbn = cv_exec_manual )
        AND ( lv_retcode = cv_status_error ) )
      THEN
        BEGIN
          -- �I�[�v��
          gv_file_handle := UTL_FILE.FOPEN( 
                               location  => gt_directory_name
                             , filename  => gv_file_name
                             , open_mode => cv_open_mode_w
                            );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        -- �N���[�Y
        UTL_FILE.FCLOSE( gv_file_handle );
        --
      END IF;
    --
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����i�A�g���j�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����i���A�g���j�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target2_cnt)
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
    --���A�g�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    -- �I���X�e�[�^�X���G���[�ȊO���A�x���t���O��ON�̏ꍇ
    IF (  ( lv_retcode <> cv_status_error )
      AND ( gv_warn_flg IS NOT NULL ) ) THEN
      -- �x���i���b�Z�[�W�͏o�͍ρj
      lv_retcode := cv_status_warn;
    END IF;
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
END XXCFO019A10C;
/
