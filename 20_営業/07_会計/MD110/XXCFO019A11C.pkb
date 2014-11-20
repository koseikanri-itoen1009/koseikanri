CREATE OR REPLACE PACKAGE BODY XXCFO019A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A11C(body)
 * Description      : �d�q���뎑�Y�Ǘ��̏��n�V�X�e���A�g�d�q����
 * MD.050           : �d�q���뎑�Y�Ǘ��̏��n�V�X�e���A�g�d�q���� <MD050_CFO_019_A11>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_fa_wait            ���A�g�f�[�^�擾����(A-2)
 *  get_fa_control         �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  chk_gl_period_status   ��v���ԃ`�F�b�N����(A-4)
 *  chk_item               ���ڃ`�F�b�N����(A-6)
 *  out_csv                CSV�o�͏���(A-7)
 *  ins_fa_wait_coop       ���A�g�e�[�u���o�^����(A-8)
 *  get_data               �Ώۃf�[�^�擾����(A-5)
 *  del_fa_wait_coop       ���A�g�f�[�^�폜����(A-9)
 *  upd_fa_control         �Ǘ��e�[�u���X�V����(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-24    1.0   N.Sugiura      �V�K�쐬
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
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- �Ώی���
  gn_normal_cnt      NUMBER;                    -- ���팏��
  gn_error_cnt       NUMBER;                    -- �G���[����
  gn_warn_cnt        NUMBER;                    -- �X�L�b�v����
  gn_target_wait_cnt NUMBER;                    -- �Ώی����i���A�g���j
  gn_wait_data_cnt   NUMBER;                    -- ���A�g�f�[�^����
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO019A11C'; -- �p�b�P�[�W��
-- ���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[
  cv_msg_cfo_00019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --�t�@�C�������݃G���[���b�Z�[�W
  cv_msg_cfo_00031            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --�N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10005            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10005';   --�d�󖢓]�L���b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --���A�g�f�[�^�`�F�b�N
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_10026            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10026';   --�d�q����p�����[�^���͕s�����b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[���b�Z�[�W
-- ���b�Z�[�W(�g�[�N��)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';  -- ���{�ꕶ����(�u���ڂ��s���v)
  cv_msg_cfo_11065            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11065';  -- ���{�ꕶ����(�u���Y�Ǘ��Ǘ��e�[�u���v)
  cv_msg_cfo_11066            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11066';  -- ���{�ꕶ����(�u���p�v)
  cv_msg_cfo_11067            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11067';  -- ���{�ꕶ����(�u�Œ莑�Y�䒠�v)
  cv_msg_cfo_11068            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11068';  -- ���{�ꕶ����(�uFIN���[�X�䒠�v)
  cv_msg_cfo_11079            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11079';  -- ���{�ꕶ����(�u���Y�ǉ��v)
  cv_msg_cfo_11080            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11080';  -- ���{�ꕶ����(�u�����p�v)
  cv_msg_cfo_11081            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11081';  -- ���{�ꕶ����(�u���Y�C���v)
  cv_msg_cfo_11082            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11082';  -- ���{�ꕶ����(�u�ĕ]���v)
  cv_msg_cfo_11083            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11083';  -- ���{�ꕶ����(�u���Y�g�ցv)
  cv_msg_cfo_11084            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11084';  -- ���{�ꕶ����(�u���Y�U�ցv)
  cv_msg_cfo_11085            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11085';  -- ���{�ꕶ����(�u���Y�Ǘ��v)
  cv_msg_cfo_11086            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11086';  -- ���{�ꕶ����(�u�d��v)
  cv_msg_cfo_11087            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11087';  -- ���{�ꕶ����(�u���Y�ԍ��A��v���ԁv)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';  -- ���{�ꕶ����(�u�A�v)
  cv_msg_cfo_11089            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11089';  -- ���{�ꕶ����(�u���Y�Ǘ����v)
  cv_msg_cfo_11090            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11090';  -- ���{�ꕶ����(�u���Y�Ǘ����A�g�e�[�u���v)
-- �g�[�N��
  cv_token_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';        --�g�[�N����(LOOKUP_TYPE)
  cv_token_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';        --�g�[�N����(LOOKUP_CODE)
  cv_token_prof_name          CONSTANT VARCHAR2(30)  := 'PROF_NAME';          --�g�[�N����(PROF_NAME)
  cv_token_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';            --�g�[�N����(DIR_TOK)
  cv_tkn_file_name            CONSTANT VARCHAR2(30)  := 'FILE_NAME';          --�g�[�N����(FILE_NAME)
  cv_tkn_get_data             CONSTANT VARCHAR2(30)  := 'GET_DATA';           --�g�[�N����(GET_DATA)
  cv_tkn_table                CONSTANT VARCHAR2(30)  := 'TABLE';              --�g�[�N����(TABLE)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(30)  := 'DOC_DIST_ID';        --�g�[�N����(DOC_DIST_ID)
  cv_tkn_doc_data             CONSTANT VARCHAR2(30)  := 'DOC_DATA';           --�g�[�N����(DOC_DATA)
  cv_tkn_key_data             CONSTANT VARCHAR2(30)  := 'KEY_DATA';           --�g�[�N����(KEY_DATA)
  cv_token_cause              CONSTANT VARCHAR2(30)  := 'CAUSE';              --�g�[�N����(CAUSE)
  cv_token_target             CONSTANT VARCHAR2(30)  := 'TARGET';             --�g�[�N����(TARGET)
  cv_token_key_data           CONSTANT VARCHAR2(30)  := 'MEANING';            --�g�[�N����(MEANING)
  cv_tkn_errmsg               CONSTANT VARCHAR2(30)  := 'ERRMSG';             --�g�[�N����(ERRMSG)
  cv_tkn_item                 CONSTANT VARCHAR2(30)  := 'ITEM';               --�g�[�N����(ITEM)
  cv_tkn_key_item             CONSTANT VARCHAR2(30)  := 'KEY_ITEM';           --�g�[�N����(KEY_ITEM)
  cv_tkn_key_value            CONSTANT VARCHAR2(30)  := 'KEY_VALUE';          --�g�[�N����(KEY_VALUE)
--
  --�A�v���P�[�V��������
  cv_xxcfo_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFO';
  cv_xxcff_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFF';
  cv_xxcoi_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOI';
  cv_sqlgl_appl_name          CONSTANT VARCHAR2(30)  := 'SQLGL';
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
--
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';       --�d�q���돈�����s��
  cv_lookup_item_chk_fa       CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_FA';   --�d�q���덀�ڃ`�F�b�N�i���Y�Ǘ��j
  cv_lookup_type_faxoltrx     CONSTANT VARCHAR2(30) := 'FAXOLTRX';
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                  -- �t���O�lY
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                  -- �t���O�lN
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
  cv_expense                  CONSTANT VARCHAR2(10)  := 'EXPENSE';
  cv_sale                     CONSTANT VARCHAR2(10)  := 'SALE';
--
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- �d�q���뎑�Y�Ǘ��f�[�^�t�@�C���i�[�p�X
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- ��v����ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_FA_DATA_I_FILENAME'; -- �d�q���뎑�Y�Ǘ��f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_FA_DATA_U_FILENAME'; -- �d�q���뎑�Y�Ǘ��f�[�^�X�V�t�@�C����
--
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';   -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';   -- �蓮���s
--
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';   -- �ǉ�
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';   -- �X�V
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';   -- ����A�g��
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';   -- ���A�g��
--
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   �i�`�F�b�N�j
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';   -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';   -- ��������
--
  --�����t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
  cv_date_format_ym           CONSTANT VARCHAR2(7)   := 'YYYY-MM';
--
  -- �N���[�Y�X�e�[�^�X
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';    -- ���уt���O
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';    -- �X�e�[�^�X�F'P'(���]�L)

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���ڃ`�F�b�N
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.meaning%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute1%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_item_cutflg_ttype IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                            INDEX BY PLS_INTEGER;
--
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32767)   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_process_date             DATE;          -- �Ɩ����t
  gv_transfer_date            VARCHAR2(50);  -- �A�g���t
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;        -- �d�q���돈�����s����
--
  gt_file_path                all_directories.directory_name%TYPE   DEFAULT NULL; --�f�B���N�g����
  gt_directory_path           all_directories.directory_path%TYPE   DEFAULT NULL; --�f�B���N�g��
  gn_set_of_bks_id            NUMBER;
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --�x���t���O
  gv_skip_flg                 VARCHAR2(1) DEFAULT 'N'; --�X�L�b�v�t���O
--
  -- CSV�t�@�C���o�͗p
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_file_data                VARCHAR2(32767);
--
  -- ���Y�Ǘ��Ǘ��e�[�u���̉�v����
  gt_period_name              xxcfo_fa_control.period_name%TYPE;
  -- ���Y�Ǘ��Ǘ��e�[�u���̗���v����
  gt_next_period_name         xxcfo_fa_control.period_name%TYPE;
  -- ���C���J�[�\���̉�v���ԕێ��p
  gt_period_name_cur          xxcfo_fa_control.period_name%TYPE;
--
  -- �e�퐧��p�t���O
  gb_reopen_flag              BOOLEAN DEFAULT FALSE; -- CSV�t�@�C���㏑���t���O
  gb_gl_je_flg                BOOLEAN DEFAULT FALSE; -- �d�󖢓]�L�t���O
--
  -- �p�����[�^�p
  gv_ins_upd_kbn              VARCHAR2(1);     -- 1.�ǉ��X�V�敪
  gv_file_name                VARCHAR2(100);   -- 2.�t�@�C����
  gv_period_name              VARCHAR2(100);   -- 3.��v����
  gv_exec_kbn                 VARCHAR2(1);     -- 4.����蓮�敪
--
  -- �g�[�N��
  gv_msg_cfo_11066            VARCHAR2(50);  -- ���{�ꕶ����(�u���p�v)
  gv_msg_cfo_11067            VARCHAR2(50);  -- ���{�ꕶ����(�u�Œ莑�Y�䒠�v)
  gv_msg_cfo_11068            VARCHAR2(50);  -- ���{�ꕶ����(�uFIN���[�X�䒠�v)
  gv_msg_cfo_11079            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�ǉ��v)
  gv_msg_cfo_11080            VARCHAR2(50);  -- ���{�ꕶ����(�u�����p�v)
  gv_msg_cfo_11081            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�C���v)
  gv_msg_cfo_11082            VARCHAR2(50);  -- ���{�ꕶ����(�u�ĕ]���v)
  gv_msg_cfo_11083            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�g�ցv)
  gv_msg_cfo_11084            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�U�ցv)
  gv_msg_cfo_11085            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�Ǘ��v)
  gv_msg_cfo_11087            VARCHAR2(50);  -- ���{�ꕶ����(�u���Y�ԍ��A��v���ԁv)
  gv_msg_cfo_11088            VARCHAR2(50);  -- ���{�ꕶ����(�u�A�v)
--
  -- �e�[�u���^
  g_item_name_tab             g_item_name_ttype;          -- ���ږ���
  g_item_len_tab              g_item_len_ttype;           -- ���ڂ̒���
  g_item_decimal_tab          g_item_decimal_ttype;       -- ���ځi�����_�ȉ��̒����j
  g_item_nullflg_tab          g_item_nullflg_ttype;       -- �K�{���ڃt���O
  g_item_attr_tab             g_item_attr_ttype;          -- ���ڑ���
  g_item_cutflg               g_item_item_cutflg_ttype;   -- �؎̂ăt���O
--
  g_data_tab                  g_layout_ttype;             --�o�̓f�[�^���
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
--
    -- ���Y�Ǘ����A�g�f�[�^(�����)
    CURSOR get_fa_wait_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_fa_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    -- ���Y�Ǘ����A�g�f�[�^(�蓮��)
    CURSOR get_fa_wait_m_cur
    IS
      SELECT transaction_header_id AS transaction_header_id   -- ���A�gID
      FROM   xxcfo_fa_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <���Y�Ǘ����A�g�e�[�u��>�e�[�u���^
    TYPE get_fa_wait_m_ttype IS TABLE OF xxcfo_fa_wait_coop.transaction_header_id%TYPE INDEX BY BINARY_INTEGER;
    g_get_fa_wait_m_tab get_fa_wait_m_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
--
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn           IN  VARCHAR2,     -- 1.�ǉ��X�V�敪
    iv_file_name             IN  VARCHAR2,     -- 2.�t�@�C����
    iv_period_name           IN  VARCHAR2,     -- 3.��v����
    iv_exec_kbn              IN  VARCHAR2,     -- 4.����蓮�敪
    ov_errbuf                OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lt_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lt_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    lt_token_prof_name        fnd_profile_options_vl.profile_option_name%TYPE;
    lv_msg                    VARCHAR2(3000);
    ln_target_cnt             NUMBER;
    lv_all                    VARCHAR2(1000);
--
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �N�C�b�N�R�[�h�擾(���ڃ`�F�b�N�p���)
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning       AS  meaning    --���ږ���
              , flv.attribute1    AS  attribute1 --���ڂ̒���
              , flv.attribute2    AS  attribute2 --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3    AS  attribute3 --�K�{�t���O
              , flv.attribute4    AS  attribute4 --����
              , flv.attribute5    AS  attribute5 --�؎̂ăt���O
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_fa
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ORDER BY  flv.lookup_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_process_date_expt      EXCEPTION;
    get_quicktype_expt         EXCEPTION;
    get_quickcode_expt         EXCEPTION;
    get_profile_expt           EXCEPTION;
    get_dir_path_expt          EXCEPTION;
    get_same_file_expt         EXCEPTION;
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
    --==============================================================
    -- 1.(1)  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>        cv_file_type_out          -- ���b�Z�[�W�o��
      , iv_conc_param1                  =>        iv_ins_upd_kbn            -- 1.�ǉ��X�V�敪
      , iv_conc_param2                  =>        iv_file_name              -- 2.�t�@�C����
      , iv_conc_param3                  =>        iv_period_name            -- 3.��v����
      , iv_conc_param4                  =>        iv_exec_kbn               -- 4.����蓮�敪
      , ov_errbuf                       =>        lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>        lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>        lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>        cv_file_type_log          -- ���O�o��
      , iv_conc_param1                  =>        iv_ins_upd_kbn            -- 1.�ǉ��X�V�敪
      , iv_conc_param2                  =>        iv_file_name              -- 2.�t�@�C����
      , iv_conc_param3                  =>        iv_period_name            -- 3.��v����
      , iv_conc_param4                  =>        iv_exec_kbn               -- 4.����蓮�敪
      , ov_errbuf                       =>        lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>        lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>        lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    --==============================================================
    -- 1.(2)  �Ɩ��������t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
    --==============================================================
    -- 1.(3)  �A�g�����擾
    --==============================================================
--
    gv_transfer_date := TO_CHAR(SYSDATE,cv_date_format_ymdhms);
--
    --==================================
    -- 1.(4) �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p)���̎擾
    --==================================
    -- �J�[�\���I�[�v��
    OPEN get_chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_chk_item_cur BULK COLLECT INTO
              g_item_name_tab
            , g_item_len_tab
            , g_item_decimal_tab
            , g_item_nullflg_tab
            , g_item_attr_tab
            , g_item_cutflg;
    -- �Ώی����̃Z�b�g
    ln_target_cnt := g_item_name_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
--
    IF ( ln_target_cnt = 0 ) THEN
      lt_lookup_type    :=  cv_lookup_item_chk_fa;
      RAISE get_quicktype_expt;
    END IF;
--
    --==============================================================
    -- 1.(5) �N�C�b�N�R�[�h(�d�q���돈�����s����)���̎擾
    --==============================================================
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)  AS attribute1 -- �d�q���돈�����s����
      INTO      gt_electric_exec_days
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_book_date
      AND       flv.lookup_code         =       cv_pkg_name
      AND       gd_process_date         BETWEEN flv.start_date_active
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_lookup_type    :=  cv_lookup_book_date;
        lt_lookup_code    :=  cv_pkg_name;
        RAISE  get_quickcode_expt;
    END;
    --==============================================================
    -- 1.(6) �v���t�@�C���擾
    --==============================================================
--
    --�t�@�C���p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
--
    IF ( gt_file_path IS NULL ) THEN
--
      lt_token_prof_name := cv_data_filepath;
      RAISE get_profile_expt;
--
    END IF;
--
    -- ��v����ID
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_gl_set_of_bks_id ) );
--
    IF ( gn_set_of_bks_id IS NULL ) THEN
--
      lt_token_prof_name := cv_gl_set_of_bks_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
--
      -- �d�q���뎑�Y�Ǘ��f�[�^�ǉ��t�@�C����
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        lt_token_prof_name := cv_add_filename;
--
      -- �d�q���뎑�Y�Ǘ��f�[�^�X�V�t�@�C����
      ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        lt_token_prof_name := cv_upd_filename;
      END IF;
--
      IF ( gv_file_name IS NULL ) THEN
--
        RAISE get_profile_expt;
--
      END IF;
--
    ELSE
--
      -- �p�����[�^���O���[�o���ϐ��Ɋi�[
      gv_file_name := iv_file_name;    -- 2.�t�@�C����
--
    END IF;
--
    --==============================================================
    -- 1.(7) �f�B���N�g���p�X�擾
    --==============================================================
    BEGIN
--
      SELECT    ad.directory_path AS directory_path
      INTO      gt_directory_path
      FROM      all_directories  ad
      WHERE     ad.directory_name  =  gt_file_path
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
        RAISE  get_dir_path_expt;
--
    END;
--
    --==================================
    -- 1.(8) IF�t�@�C�����o��
    --==================================
--
    -- �p�X�̃��X�g�ɃX���b�V�����܂܂�Ă���ꍇ
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
--
      -- �f�B���N�g���ƃt�@�C�������̂܂ܘA��
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
--
      -- �f�B���N�g���ƃt�@�C���̊ԂɃX���b�V����ݒ�
      lv_all := gt_directory_path || cv_slash || gv_file_name;
--
    END IF;
-- 
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcfo_appl_name
              , iv_name         => cv_msg_cfo_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_all
              );
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================
    -- 2. �t�@�C�����݃`�F�b�N
    --==================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      RAISE get_same_file_expt;
    END IF;
--
    --==================================
    -- �Œ蕶���擾
    --==================================
    -- �o�͗p����
    gv_msg_cfo_11066 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11066 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11067 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11067 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11068 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11068 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11079 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11079 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11080 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11080 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11081 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11081 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11082 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11082 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11083 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11083 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11084 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11084 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11085 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11085 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11087 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11087 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11088 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                        , iv_name         => cv_msg_cfo_11088 -- ���b�Z�[�W�R�[�h
                                                        )
                               , 1
                               , 5000
                               );
--
    --==================================
    -- �p�����[�^���O���[�o���ϐ��Ɋi�[
    --==================================
--
    gv_ins_upd_kbn           := iv_ins_upd_kbn;                       -- 1.�ǉ��X�V�敪
    gv_period_name           := iv_period_name;                       -- 3.��v����
    gv_exec_kbn              := iv_exec_kbn;                          -- 4.����蓮�敪
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN get_process_date_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00015
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�擾��O�n���h�� ***
    WHEN get_quickcode_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00031,
        iv_token_name1        => cv_token_lookup_type,
        iv_token_value1       => lt_lookup_type,
        iv_token_name2        => cv_token_lookup_code,
        iv_token_value2       => lt_lookup_code
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�^�C�v�擾��O�n���h�� ***
    WHEN get_quicktype_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcff_appl_name,
        iv_name               => cv_msg_cff_00189,
        iv_token_name1        => cv_token_lookup_type,
        iv_token_value1       => lt_lookup_type
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_profile_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00001,
        iv_token_name1        => cv_token_prof_name,
        iv_token_value1       => lt_token_prof_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�B���N�g���擾��O�n���h�� ***
    WHEN get_dir_path_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcoi_appl_name,
        iv_name               => cv_msg_coi_00029,
        iv_token_name1        => cv_token_dir_tok,
        iv_token_value1       => gt_file_path
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �t�@�C���擾��O�n���h�� ***
    WHEN get_same_file_expt  THEN
      ov_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00027
                    );
      ov_errbuf  := ov_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă�����N���[�Y����
      IF ( get_chk_item_cur%ISOPEN ) THEN
        CLOSE get_chk_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_fa_wait
   * Description      : A-2�D���A�g�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_fa_wait(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fa_wait'; -- �v���O������
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    --==================================
    -- A-2�D���A�g�f�[�^�擾����
    --==================================
--
    -- ����̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --�J�[�\���I�[�v��
      OPEN get_fa_wait_f_cur;
      FETCH get_fa_wait_f_cur BULK COLLECT INTO g_row_id_tab;
      --�J�[�\���N���[�Y
      CLOSE get_fa_wait_f_cur;
--
    -- �蓮�̏ꍇ�͎Q�Ɣԍ��擾
    ELSE
--
      --�J�[�\���I�[�v��
      OPEN get_fa_wait_m_cur;
      FETCH get_fa_wait_m_cur BULK COLLECT INTO g_get_fa_wait_m_tab;
      --�J�[�\���N���[�Y
      CLOSE get_fa_wait_m_cur;
--
    END IF;
--
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11090 -- ���Y�Ǘ����A�g�e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_fa_wait_m_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_fa_wait_m_cur;
      END IF;
      IF ( get_fa_wait_f_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_fa_wait_f_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_fa_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_fa_control
   * Description      : A-3�D�Ǘ��e�[�u���f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_fa_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_fa_control'; -- �v���O������
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
--
    ln_cnt        NUMBER DEFAULT 0;
--
    -- ===============================
    -- �J�[�\��
    -- ===============================
--
    -- ���Y�Ǘ��Ǘ��e�[�u��(���b�N����)
    CURSOR get_fa_control_lock_cur
    IS
      SELECT xfc.period_name  AS period_name,            -- ��v����
             TO_CHAR(ADD_MONTHS( TO_DATE( xfc.period_name,cv_date_format_ym ) , 1 ) , cv_date_format_ym)
                              AS next_period_name        -- ����v����
      FROM   xxcfo_fa_control xfc                        -- ���Y�Ǘ��Ǘ�
      WHERE  set_of_books_id  =  gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    get_fa_control_lock_rec get_fa_control_lock_cur%ROWTYPE;
--
    -- ���Y�Ǘ��Ǘ��e�[�u��
    CURSOR get_fa_control_cnt_cur
    IS
      SELECT COUNT(1)
      FROM   xxcfo_fa_control xfc                        -- ���Y�Ǘ��Ǘ�
      WHERE  set_of_books_id  =  gn_set_of_bks_id
      ;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
    get_fa_control_expt       EXCEPTION;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    --==================================
    -- A-3�D�Ǘ��e�[�u���f�[�^�擾����
    --==================================
--
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      OPEN get_fa_control_lock_cur;
      FETCH get_fa_control_lock_cur INTO get_fa_control_lock_rec;
      CLOSE get_fa_control_lock_cur;
--
      IF ( get_fa_control_lock_rec.period_name IS NULL ) THEN
--
       RAISE get_fa_control_expt;
--
      ELSE
--
        -- ���O���[�o���l�Ɋi�[
        -- �Ǘ��e�[�u���̉�v����
        gt_period_name      := get_fa_control_lock_rec.period_name;
        -- �Ǘ��e�[�u���̉�v���Ԃ̗���
        gt_next_period_name     := get_fa_control_lock_rec.next_period_name;
--
      END IF;
--
    -- �蓮���s�̏ꍇ
    -- �Ǘ��e�[�u���Ƀf�[�^���Ȃ��ꍇ�͌x��(�����Z�b�g�A�b�v�R��)
    ELSE
--
      OPEN get_fa_control_cnt_cur;
      FETCH get_fa_control_cnt_cur INTO ln_cnt;
      CLOSE get_fa_control_cnt_cur;
--
      IF ( ln_cnt = 0 ) THEN
--
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => cv_msg_cfo_11065-- ���Y�Ǘ��Ǘ��e�[�u��
        );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
--
      END IF;

    END IF;
--
    --==============================================================
    --�t�@�C���I�[�v��
    --==============================================================
    BEGIN
--
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gt_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                                   );
--
      -- �ȍ~�̏����ŃG���[�I�������ꍇ�͍ēxFOPEN���ċ�t�@�C�����쐬����
      gb_reopen_flag := TRUE;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029     -- �t�@�C���I�[�v���G���[
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11065-- ���Y�Ǘ��Ǘ��e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���Y�Ǘ��Ǘ��e�[�u���擾��O�n���h�� ***
    WHEN get_fa_control_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11065-- ���Y�Ǘ��Ǘ��e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
--
      IF ( get_fa_control_lock_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_fa_control_lock_cur;
      END IF;
      IF ( get_fa_control_cnt_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_fa_control_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_fa_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_gl_period_status
   * Description      : A-4�D��v���ԃ`�F�b�N����
   ***********************************************************************************/
  PROCEDURE chk_gl_period_status(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_gl_period_status'; -- �v���O������
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
--
    ln_count        NUMBER DEFAULT 0;
--
    -- ===============================
    -- �J�[�\��
    -- ===============================
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      BEGIN
--
        SELECT COUNT(1) AS cnt
        INTO   ln_count
        FROM   gl_period_statuses gps
             , fnd_application    fa
        WHERE  gps.application_id         = fa.application_id
        AND    fa.application_short_name  = cv_sqlgl_appl_name
        AND    gps.adjustment_period_flag = cv_flag_n
        AND    gps.closing_status         = cv_closing_status
        AND    gps.set_of_books_id        = gn_set_of_bks_id
        AND    ( TRUNC(gps.last_update_date) + NVL( gt_electric_exec_days , 0 ) )
                 <=  gd_process_date
        AND    gps.period_name            = gt_next_period_name
        ;
--
      EXCEPTION
--
        WHEN OTHERS THEN
--
          lv_errmsg := SQLERRM;
          lv_errbuf := SQLERRM;
--
          RAISE global_process_expt;
--
      END;
--
    END IF;
--
    --==============================================================
    --�㑱��������
    --==============================================================
--
    -- 1.����̏ꍇ ���A2.���A�g�e�[�u���Ƀf�[�^�Ȃ� ���A3.��v���Ԃ��N���[�Y���Ă��Ȃ�
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT = 0 ) AND ( ln_count = 0 ) ) THEN
--
      -- �㑱�����͍s�킸�A�I������(A-11)
      gv_skip_flg := cv_flag_y;
--
    -- 1.����̏ꍇ ���A2.���A�g�e�[�u���Ƀf�[�^���� ���A3.��v���Ԃ��N���[�Y���Ă��Ȃ�
    ELSIF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT > 0 ) AND ( ln_count = 0 ) ) THEN
--
      -- get_data�ō���A�g���̃f�[�^���擾���Ȃ��悤����v���Ԃ�NULL��ݒ�
      gt_next_period_name := NULL;
--
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
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_gl_period_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT VARCHAR2,   --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
    ov_skipflg            OUT VARCHAR2)   --   �X�L�b�v�쐬�t���O
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_count        NUMBER DEFAULT 0;
    lv_target_value VARCHAR2(100);
    lv_name         VARCHAR2(100)   DEFAULT NULL; -- �L�[���ږ�
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
    warn_expt            EXCEPTION;
    chk_item_expt        EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode   := cv_status_normal;
    ov_skipflg   := cv_flag_n;
--
--###########################  �Œ蕔 END   ############################
--
    -- �蓮���s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      --==============================================================
      -- [�蓮���s]�̏ꍇ�A���A�g�f�[�^�Ƃ��đ��݂��Ă��邩���`�F�b�N
      --==============================================================
--
      -- �Q�Ɣԍ������A�g�e�[�u���ɒl���������ꍇ�́u�x���˃X�L�b�v�v
      <<g_get_fa_wait_m_loop>>
      FOR i IN 1 .. g_get_fa_wait_m_tab.COUNT LOOP
--
        -- ���C���J�[�\���̎Q�Ɣԍ������A�g�e�[�u���̎Q�Ɣԍ��Ɠ�����
        IF ( g_data_tab(17) = g_get_fa_wait_m_tab(i) ) THEN
---
          -- �X�L�b�v�t���O��ON(�@A-7�FCSV�o�́A�AA-8�F���A�g�e�[�u���o�^���X�L�b�v)
          ov_skipflg := cv_flag_y;
--
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name        -- XXCFO
                                 ,cv_msg_cfo_10010          -- ���A�g�f�[�^�`�F�b�NID�G���[
                                 ,cv_tkn_doc_data           -- �g�[�N��'DOC_DATA'
                                 ,cv_msg_cfo_11087          -- �u���Y�ԍ��A��v���ԁv
                                 ,cv_tkn_doc_dist_id        -- �g�[�N��'DOC_DIST_ID'
                                 ,g_data_tab(2) || gv_msg_cfo_11088 || gv_period_name --�u���Y�ԍ��A��v���ԁv
                                 )
                               ,1
                               ,5000);
--
          RAISE warn_expt;
--
        END IF;
--
      END LOOP g_get_fa_wait_m_loop;
--
    END IF;
--
    --==============================================================
    -- �]�L�σ`�F�b�N
    --==============================================================
--
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --�ŏ���1���ځA�܂��͉�v���Ԃ��؂�ւ�����ꍇ(���A�g�f�[�^���������ꍇ��z��)�̂݃`�F�b�N
      --(1���ł�NG�������炷�ׂẴ��R�[�h���x��)
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(21) ) ) THEN
--
        -- ���]�L�t���O��OFF
        gb_gl_je_flg := FALSE;
--
        -- ���ݍs�̉�v���Ԃ�ێ�
        gt_period_name_cur := g_data_tab(21);
--
        -- �]�L��
        BEGIN
--
          SELECT COUNT(1)
          INTO   ln_count
          FROM   gl_je_headers       gjh,  -- �d��w�b�_
                 gl_je_sources_vl    gjsv, -- GL�d��\�[�X
                 gl_je_categories_vl gjcv  -- GL�d��J�e�S��
          WHERE   gjcv.je_category_name = gjh.je_category
          AND     gjsv.je_source_name   = gjh.je_source
          AND     gjcv.user_je_category_name IN (gv_msg_cfo_11079,gv_msg_cfo_11080,gv_msg_cfo_11081,gv_msg_cfo_11082,
                                                 gv_msg_cfo_11083,gv_msg_cfo_11084)
                                                 --  '���Y�ǉ�', '�����p', '���Y�C��', '�ĕ]��', '���Y�g��', '���Y�U��'
          AND     gjsv.user_je_source_name    =  gv_msg_cfo_11085      -- �d��\�[�X��
          AND     gjh.actual_flag             =  cv_result_flag        -- �eA�f�i���сj
          AND     gjh.status                  =  cv_status_p           -- �eP�f�i�]�L�ρj
          AND     gjh.period_name             =  g_data_tab(21)        -- A-5�Ŏ擾������v����
          AND     gjh.set_of_books_id         =  gn_set_of_bks_id
          ;
--
        EXCEPTION
--
          WHEN OTHERS THEN
--
            lv_errmsg := SQLERRM;
            lv_errbuf := SQLERRM;
--
            RAISE global_process_expt;
--
        END;
--
        IF ( ln_count = 0 ) THEN
--
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name        -- XXCFO
                                 ,cv_msg_cfo_10005          -- �d�󖢓]�L���b�Z�[�W
                                 ,cv_tkn_item               -- �g�[�N��'ITEM'
                                 ,cv_msg_cfo_11086          -- �u�d��v
                                 ,cv_tkn_key_item           -- �g�[�N��'KEY_ITEM'
                                 ,cv_msg_cfo_11087          -- �u���Y�ԍ��A��v���ԁv
                                 ,cv_tkn_key_value          -- �g�[�N��'KEY_VALUE'
                                 ,g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21) --�u���Y�ԍ��A��v���ԁv
                                 )
                               ,1
                               ,5000);
--
          -- ���]�L�t���O��ON
          gb_gl_je_flg := TRUE;
--
          -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
          RAISE warn_expt;
--
        END IF;
--
      -- �O���R�[�h�Ɠ�����v���ԁA���A���]�L�t���O��ON�̏ꍇ�͂��ׂČx��
      ELSIF ( ( gt_period_name_cur = g_data_tab(21) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- �d�󖢓]�L���b�Z�[�W
                               ,cv_tkn_item               -- �g�[�N��'ITEM'
                               ,cv_msg_cfo_11086          -- �u�d��v
                               ,cv_tkn_key_item           -- �g�[�N��'KEY_ITEM'
                               ,cv_msg_cfo_11087          -- �u���Y�ԍ��A��v���ԁv
                               ,cv_tkn_key_value          -- �g�[�N��'KEY_VALUE'
                               ,g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21) --�u���Y�ԍ��A��v���ԁv
                               )
                             ,1
                             ,5000);
--
        -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
        RAISE warn_expt;
--
      END IF;
--
    END IF;
--
    -- ���b�Z�[�W�g�[�N���ҏW(�G���[���L�[���)
    -- �蓮���s
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      -- �u���Y�ԍ��A��v���� : XXXXX�AYYYY(�p�����[�^.��v����)�v
      lv_target_value := gv_msg_cfo_11087  || cv_msg_part || g_data_tab(2) || gv_msg_cfo_11088 || gv_period_name;
    ELSE
      -- �u���Y�ԍ��A��v���� : XXXXX�AYYYY(A-5�Ŏ擾������v����)�v
      lv_target_value := gv_msg_cfo_11087  || cv_msg_part || g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21);
    END IF;
--
    --==============================================================
    -- �^�^���^�K�{�̃`�F�b�N
    --==============================================================
--
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
--
      -- �A�g�����ȊO�̓`�F�b�N����
      IF ( ln_cnt <> 42 ) THEN

        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name                  =>        g_item_name_tab(ln_cnt)              --���ږ���
          , iv_item_value                 =>        g_data_tab(ln_cnt)                   --���ڂ̒l
          , in_item_len                   =>        g_item_len_tab(ln_cnt)               --���ڂ̒���
          , in_item_decimal               =>        g_item_decimal_tab(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
          , iv_item_nullflg               =>        g_item_nullflg_tab(ln_cnt)           --�K�{�t���O
          , iv_item_attr                  =>        g_item_attr_tab(ln_cnt)              --���ڑ���
          , iv_item_cutflg                =>        g_item_cutflg(ln_cnt)                --�؎̂ăt���O
          , ov_item_value                 =>        g_data_tab(ln_cnt)                   --���ڂ̒l
          , ov_errbuf                     =>        lv_errbuf                            --�G���[���b�Z�[�W
          , ov_retcode                    =>        lv_retcode                           --���^�[���R�[�h
          , ov_errmsg                     =>        lv_errmsg                            --���[�U�[�E�G���[���b�Z�[�W
          );
--
        -- ������ȊO�̏ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
--
          -- ���x���̏ꍇ
          IF ( lv_retcode = cv_status_warn ) THEN
--
            -- ���
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
              -- �����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- �X�L�b�v�t���O��ON(�@A-7�FCSV�o�́A�AA-8�F���A�g�e�[�u���o�^���X�L�b�v)
                ov_skipflg := cv_flag_y;
--
                -- �G���[���b�Z�[�W�ҏW
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_data ,
                  iv_token_value1       => lv_target_value
                );
--
              -- �����`�F�b�N�ȊO
              ELSE
--
                -- ���ʊ֐��̃G���[���b�Z�[�W���o��
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => cv_msg_cfo_11008
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => lv_target_value
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
--
              END IF;
--
              ov_retcode := cv_status_warn;
              ov_errmsg  := lv_errmsg;
              ov_errbuf  := lv_errmsg;
--
              --1���ł��x������������EXIT
              EXIT;
--
            -- �蓮
            ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN
--
              -- �����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- �G���[���b�Z�[�W�ҏW
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_data ,
                  iv_token_value1       => lv_target_value
                );
--
              -- �����`�F�b�N�ȊO
              ELSE
--
                -- ���ʊ֐��̃G���[���b�Z�[�W���o��
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => cv_msg_cfo_11008
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => lv_target_value
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
--
              END IF;
--
              -- �ǉ��̏ꍇ�͌x��
              IF ( gv_ins_upd_kbn = cv_ins_upd_0 ) THEN
--
                RAISE warn_expt;
--
              -- �X�V�̏ꍇ�̓G���[
              ELSIF  ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
--
                RAISE chk_item_expt;
--
              END IF;
--
            END IF;
--
          -- ���x���ȊO
          ELSE
--
            lv_errmsg := lv_errbuf;
            lv_errbuf := lv_errbuf;
--
            -- �G���[(�������f)
            RAISE global_api_expt;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP g_item_name_loop;
--
  EXCEPTION
--
    -- *** ���A�g�f�[�^���݌x���n���h�� ***
    WHEN warn_expt THEN
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** �`�F�b�N�G���[�G���[�n���h�� ***
    WHEN chk_item_expt THEN                           --*** <��O�R�����g> ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : CSV�o�͏���(A-7)
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_delimit                VARCHAR2(1);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
--
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
--
    <<g_item_name_loop2>>
    FOR ln_cnt  IN g_item_name_tab.FIRST .. g_item_name_tab.LAST  LOOP 
--
      --���ڑ�����VARCHAR2,CHAR
      IF ( g_item_attr_tab(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
--
        -- ���s�R�[�h�A�J���}�A�_�u���R�[�e�[�V�����𔼊p�X�y�[�X�ɒu��������B
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        -- �_�u���N�H�[�g�ň͂�
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
      --���ڑ�����NUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
--
        -- ���̂܂ܓn��
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      --���ڑ�����DATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
--
        -- ���̂܂ܓn��
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      END IF;
--
      lv_delimit  :=  cv_delimit;
--
    END LOOP g_item_name_loop2;
--
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
--
      UTL_FILE.PUT_LINE(gv_file_hand
                       ,gv_file_data
                       );
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    EXCEPTION
      WHEN OTHERS THEN
        --���t�@�C���N���[�Y�֐���ǉ�
        IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
          UTL_FILE.FCLOSE( gv_file_hand );
        END IF;
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name    -- 'XXCFO'
                                                      ,cv_msg_cfo_00030      -- �t�@�C���ɏ����݂ł��Ȃ�
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : ins_fa_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_fa_wait_coop(
    iv_errmsg     IN  VARCHAR2,     -- 1.�G���[���e
    iv_skipflg    IN  VARCHAR2,     -- 2.�X�L�b�v�t���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_fa_wait_coop'; -- �v���O������
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
    -- ������s�̂Ƃ��A���A�X�L�b�v�t���O��OFF�̏ꍇ
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( iv_skipflg = cv_flag_n ) ) THEN
--
      --==============================================================
      --���Y�Ǘ����A�g�e�[�u���o�^
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_fa_wait_coop(
           set_of_books_id        -- ��v����ID
          ,period_name            -- ��v����
          ,asset_number           -- ���Y�ԍ�
          ,transaction_header_id  -- �Q�Ɣԍ�
          ,last_update_date       -- �ŏI�X�V��
          ,last_updated_by        -- �ŏI�X�V��
          ,creation_date          -- �쐬��
          ,created_by             -- �쐬��
          ,last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             -- �v��ID
          ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             -- �R���J�����g�E�v���O����ID
          ,program_update_date    -- �v���O�����X�V��
          )
        VALUES (
           gn_set_of_bks_id       -- ��v����ID
          ,g_data_tab(21)         -- ��v����
          ,g_data_tab(2)          -- ���Y�ԍ�
          ,g_data_tab(17)         -- �Q�Ɣԍ�
          ,cd_last_update_date
          ,cn_last_updated_by
          ,cd_creation_date
          ,cn_created_by
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
--
        --���A�g�o�^�����J�E���g
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name     -- XXCFO
                                                         ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11090   -- ���Y�Ǘ����A�g�e�[�u��
                                                         ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
--
    END IF;
--
    --==============================================================
    -- �x���I�����̃��b�Z�[�W�o��
    --==============================================================
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => iv_errmsg
    );

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
  END ins_fa_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �Ώۃf�[�^�擾(A-5)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    lv_skipflg                VARCHAR2(1) DEFAULT 'N';
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s)
    CURSOR get_manual_cur
    IS
      SELECT 
            fab.asset_id                   AS asset_id                      -- ���YID
           ,fab.asset_number               AS asset_number                  -- ���Y�ԍ�
           ,fab.attribute_category_code    AS attribute_category_code       -- ���Y�J�e�S��
           ,fab.current_units              AS current_units                 -- �P��
           ,fat.description                AS description                   -- �E�v
           ,fb.book_type_code              AS book_type_code                -- ���Y�䒠��
           ,fb.cost                        AS cost                          -- �擾���i
           ,fb.original_cost               AS original_cost                 -- �����擾���i
           ,fb.salvage_value               AS salvage_value                 -- �c�����z
           ,fb.percent_salvage_value       AS percent_salvage_value         -- �c�����z�p�[�Z���g
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- ���x�z
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- ���p�Ώۊz
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd )   AS date_placed_in_service        -- ���Ƌ��p��
           ,fb.deprn_method_code           AS deprn_method_code             -- ���p���@
           ,fb.life_in_months/12           AS life_in_months                -- �ϗp�N��
           ,fb.prior_deprn_method          AS prior_deprn_method            -- �����p���@
           ,fth.transaction_header_id      AS transaction_header_id         -- �Q�Ɣԍ�
           ,lotl.meaning                   AS meaning                       -- ����^�C�v
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd )   AS transaction_date_entered      -- �����
           ,fth.transaction_name           AS transaction_name              -- ����
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND adj.period_counter_created  = per.period_counter
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL�]����v����
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND adj.period_counter_created  = per.period_counter
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense)  -- EXPENSE�ȊO
                                           AS je_header_id                  -- �d��w�b�_�[id
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE�F���p�A�ȊO�F�����p�^�C�v
                                           AS retirement_type_code          -- �����p�^�C�v
           ,fr.units                       AS units                         -- �����p�P��
           ,fr.cost_retired                AS cost_retired                  -- �����p�擾���i
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- ���p���z
           ,fr.cost_of_removal             AS cost_of_removal               -- �P����p
           ,fr.gain_loss_amount            AS gain_loss_amount              -- ���p���v
           ,fr.nbv_retired                 AS nbv_retired                   -- �����p�����뉿�z
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- �擾���i�C���z
           ,xch.contract_number            AS contract_number               -- �_��ԍ�
           ,xch.lease_company              AS lease_company                 -- ���[�X���
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- ���[�X��Ж�
           ,fab.attribute10                AS attribute10                   -- �_�񖾍ד���ID
           ,xcl.contract_line_num          AS contract_line_num             -- �_��}��
           ,oh.object_code                 AS object_code                   -- �����R�[�h
           ,fai.invoice_number             AS invoice_number                -- AP�������ԍ�
           ,fai.description                AS description                   -- �\�[�X���דE�v
           ,pv.segment1                    AS segment1                      -- �d����R�[�h
           ,pv.vendor_name                 AS vendor_name                   -- �d���於
           ,fai.payables_cost              AS payables_cost                 -- �\�[�X���׎x�����z
           ,gv_transfer_date               AS transfer_date                 -- �A�g����
           ,cv_data_type_0                 AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
      FROM  fa_additions_b fab            -- ���Y�ڍ׏��
           ,fa_additions_tl fat           -- ���Y�E�v���
           ,fa_books fb                   -- ���Y�䒠���
           ,fa_books fb2                  -- ���Y�䒠���2
           ,fa_transaction_headers fth    -- ���Y����w�b�_
           ,xxcff_contract_headers xch    -- ���[�X�_��
           ,xxcff_contract_lines xcl      -- ���[�X�_�񖾍�
           ,xxcff_object_headers oh       -- ���[�X����
           ,fa_asset_invoices fai         -- ���Y�\�[�X���׏��
           ,po_vendors pv                 -- �d����
           ,fa_lookups_tl lotl            -- FA�N�C�b�N�R�[�h
           ,fa_retirements fr             -- �����p���
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- �u�Œ莑�Y�䒠�v�uFIN���[�X�䒠�v
      AND   fat.language                = cv_lang                    -- �uJA�v
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- �uFAXOLTRX�v
      AND   lotl.language               = cv_lang                    -- �uJA�v
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 1
               FROM fa_adjustments adj
                   ,fa_deprn_periods per
               WHERE 1=1
                AND adj.period_counter_created  = per.period_counter
                AND adj.transaction_header_id   = fb.transaction_header_id_in
                AND per.book_type_code          = fb.book_type_code
                AND per.period_name             = gv_period_name     -- �p�����[�^.��v����
                AND adj.asset_id                = fb.asset_id
                )
      ORDER BY asset_number,transaction_header_id
      ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(������s)
    CURSOR get_fixed_period_cur
    IS
      SELECT 
            fab.asset_id                   AS asset_id                      -- ���YID
           ,fab.asset_number               AS asset_number                  -- ���Y�ԍ�
           ,fab.attribute_category_code    AS attribute_category_code       -- ���Y�J�e�S��
           ,fab.current_units              AS current_units                 -- �P��
           ,fat.description                AS description                   -- �E�v
           ,fb.book_type_code              AS book_type_code                -- ���Y�䒠��
           ,fb.cost                        AS cost                          -- �擾���i
           ,fb.original_cost               AS original_cost                 -- �����擾���i
           ,fb.salvage_value               AS salvage_value                 -- �c�����z
           ,fb.percent_salvage_value       AS percent_salvage_value         -- �c�����z�p�[�Z���g
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- ���x�z
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- ���p�Ώۊz
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd)    AS date_placed_in_service        -- ���Ƌ��p��
           ,fb.deprn_method_code           AS deprn_method_code             -- ���p���@
           ,fb.life_in_months/12           AS life_in_months                -- �ϗp�N��
           ,fb.prior_deprn_method          AS prior_deprn_method            -- �����p���@
           ,fth.transaction_header_id      AS transaction_header_id         -- �Q�Ɣԍ�
           ,lotl.meaning                   AS meaning                       -- ����^�C�v
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd)    AS transaction_date_entered      -- �����
           ,fth.transaction_name           AS transaction_name              -- ����
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL�]����v����
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense) --EXPENSE
                                           AS je_header_id                  -- �d��w�b�_�[ID
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE�F���p�A�ȊO�F�����p�^�C�v
                                           AS retirement_type_code          -- �����p�^�C�v
           ,fr.units                       AS units                         -- �����p�P��
           ,fr.cost_retired                AS cost_retired                  -- �����p�擾���i
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- ���p���z
           ,fr.cost_of_removal             AS cost_of_removal               -- �P����p
           ,fr.gain_loss_amount            AS gain_loss_amount              -- ���p���v
           ,fr.nbv_retired                 AS nbv_retired                   -- �����p�����뉿�z
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- �擾���i�C���z
           ,xch.contract_number            AS contract_number               -- �_��ԍ�
           ,xch.lease_company              AS lease_company                 -- ���[�X���
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- ���[�X��Ж�
           ,fab.attribute10                AS attribute10                   -- �_�񖾍ד���ID
           ,xcl.contract_line_num          AS contract_line_num             -- �_��}��
           ,oh.object_code                 AS object_code                   -- �����R�[�h
           ,fai.invoice_number             AS invoice_number                -- AP�������ԍ�
           ,fai.description                AS description                   -- �\�[�X���דE�v
           ,pv.segment1                    AS segment1                      -- �d����R�[�h
           ,pv.vendor_name                 AS vendor_name                   -- �d���於
           ,fai.payables_cost              AS payables_cost                 -- �\�[�X���׎x�����z
           ,gv_transfer_date               AS transfer_date                 -- �A�g����
           ,cv_data_type_0                 AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
      FROM  fa_additions_b fab            -- ���Y�ڍ׏��
           ,fa_additions_tl fat           -- ���Y�E�v���
           ,fa_books fb                   -- ���Y�䒠���
           ,fa_books fb2                  -- ���Y�䒠���2
           ,fa_transaction_headers fth    -- ���Y����w�b�_
           ,xxcff_contract_headers xch    -- ���[�X�_��
           ,xxcff_contract_lines xcl      -- ���[�X�_�񖾍�
           ,xxcff_object_headers oh       -- ���[�X����
           ,fa_asset_invoices fai         -- ���Y�\�[�X���׏��
           ,po_vendors pv                 -- �d����
           ,fa_lookups_tl lotl            -- FA�N�C�b�N�R�[�h
           ,fa_retirements fr             -- �����p���
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- �u�Œ莑�Y�䒠�v�uFIN���[�X�䒠�v
      AND   fat.language                = cv_lang                    -- �uJA�v
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- �uFAXOLTRX�v
      AND   lotl.language               = cv_lang                    -- �uJA�v
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 1
               FROM fa_adjustments adj
                   ,fa_deprn_periods per
               WHERE 1=1
                AND adj.period_counter_created  = per.period_counter
                AND adj.transaction_header_id   = fb.transaction_header_id_in
                AND per.book_type_code          = fb.book_type_code
                AND per.period_name             = gt_next_period_name -- ���Y�Ǘ��Ǘ��e�[�u��.��v���Ԃ̗���
                AND adj.asset_id                = fb.asset_id
                )
      UNION ALL
      SELECT
            fab.asset_id                   AS asset_id                      -- ���YID
           ,fab.asset_number               AS asset_number                  -- ���Y�ԍ�
           ,fab.attribute_category_code    AS attribute_category_code       -- ���Y�J�e�S��
           ,fab.current_units              AS current_units                 -- �P��
           ,fat.description                AS description                   -- �E�v
           ,fb.book_type_code              AS book_type_code                -- ���Y�䒠��
           ,fb.cost                        AS cost                          -- �擾���i
           ,fb.original_cost               AS original_cost                 -- �����擾���i
           ,fb.salvage_value               AS salvage_value                 -- �c�����z
           ,fb.percent_salvage_value       AS percent_salvage_value         -- �c�����z�p�[�Z���g
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- ���x�z
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- ���p�Ώۊz
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd)    AS date_placed_in_service        -- ���Ƌ��p��
           ,fb.deprn_method_code           AS deprn_method_code             -- ���p���@
           ,fb.life_in_months/12           AS life_in_months                -- �ϗp�N��
           ,fb.prior_deprn_method          AS prior_deprn_method            -- �����p���@
           ,fth.transaction_header_id      AS transaction_header_id         -- �Q�Ɣԍ�
           ,lotl.meaning                   AS meaning                       -- ����^�C�v
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd)    AS transaction_date_entered      -- �����
           ,fth.transaction_name           AS transaction_name              -- ����
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL�]����v����
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense)  -- EXPENSE
                                           AS je_header_id                  -- �d��w�b�_�[ID
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE�F���p�A�ȊO�F�����p�^�C�v
                                           AS retirement_type_code          -- �����p�^�C�v
           ,fr.units                       AS units                         -- �����p�P��
           ,fr.cost_retired                AS cost_retired                  -- �����p�擾���i
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- ���p���z
           ,fr.cost_of_removal             AS cost_of_removal               -- �P����p
           ,fr.gain_loss_amount            AS gain_loss_amount              -- ���p���v
           ,fr.nbv_retired                 AS nbv_retired                   -- �����p�����뉿�z
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- �擾���i�C���z
           ,xch.contract_number            AS contract_number               -- �_��ԍ�
           ,xch.lease_company              AS lease_company                 -- ���[�X���
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- ���[�X��Ж�
           ,fab.attribute10                AS attribute10                   -- �_�񖾍ד���ID
           ,xcl.contract_line_num          AS contract_line_num             -- �_��}��
           ,oh.object_code                 AS object_code                   -- �����R�[�h
           ,fai.invoice_number             AS invoice_number                -- AP�������ԍ�
           ,fai.description                AS description                   -- �\�[�X���דE�v
           ,pv.segment1                    AS segment1                      -- �d����R�[�h
           ,pv.vendor_name                 AS vendor_name                   -- �d���於
           ,fai.payables_cost              AS payables_cost                 -- �\�[�X���׎x�����z
           ,gv_transfer_date               AS transfer_date                 -- �A�g����
           ,cv_data_type_1                 AS data_type                     -- �f�[�^�^�C�v('1':���A�g)
      FROM  fa_additions_b fab             -- ���Y�ڍ׏��
           ,fa_additions_tl fat            -- ���Y�E�v���
           ,fa_books fb                    -- ���Y�䒠���
           ,fa_books fb2                   -- ���Y�䒠���2
           ,fa_transaction_headers fth     -- ���Y����w�b�_
           ,xxcff_contract_headers xch     -- ���[�X�_��
           ,xxcff_contract_lines xcl       -- ���[�X�_�񖾍�
           ,xxcff_object_headers oh        -- ���[�X����
           ,fa_asset_invoices fai          -- ���Y�\�[�X���׏��
           ,po_vendors pv                  -- �d����
           ,fa_lookups_tl lotl             -- FA�N�C�b�N�R�[�h
           ,fa_retirements fr              -- �����p���
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- �u�Œ莑�Y�䒠�v�uFIN���[�X�䒠�v
      AND   fat.language                = cv_lang                    -- �uJA�v
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- �uFAXOLTRX�v
      AND   lotl.language               = cv_lang                    -- �uJA�v
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 'X'
             FROM   xxcfo_fa_wait_coop xfwc       -- ���A�g�e�[�u��
             WHERE  xfwc.transaction_header_id  = fth.transaction_header_id
                )
      ORDER BY asset_number,transaction_header_id
      ;
--
    get_data_expt             EXCEPTION;
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
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      --�J�[�\���I�[�v��
      OPEN get_manual_cur;
      <<get_manual_loop>>
      LOOP
      FETCH get_manual_cur INTO
            g_data_tab(1)  -- ���YID
          , g_data_tab(2)  -- ���Y�ԍ�
          , g_data_tab(3)  -- ���Y�J�e�S��
          , g_data_tab(4)  -- �P��
          , g_data_tab(5)  -- �E�v
          , g_data_tab(6)  -- ���Y�䒠��
          , g_data_tab(7)  -- �擾���i
          , g_data_tab(8)  -- �����擾���i
          , g_data_tab(9)  -- �c�����z
          , g_data_tab(10) -- �c�����z�p�[�Z���g
          , g_data_tab(11) -- ���x�z
          , g_data_tab(12) -- ���p�Ώۊz
          , g_data_tab(13) -- ���Ƌ��p��
          , g_data_tab(14) -- ���p���@
          , g_data_tab(15) -- �ϗp�N��
          , g_data_tab(16) -- �����p���@
          , g_data_tab(17) -- �Q�Ɣԍ�
          , g_data_tab(18) -- ����^�C�v
          , g_data_tab(19) -- �����
          , g_data_tab(20) -- ����
          , g_data_tab(21) -- GL�]����v����
          , g_data_tab(22) -- �d��w�b�_�[ID
          , g_data_tab(23) -- �����p�^�C�v
          , g_data_tab(24) -- �����p�P��
          , g_data_tab(25) -- �����p�擾���i
          , g_data_tab(26) -- ���p���z
          , g_data_tab(27) -- �P����p
          , g_data_tab(28) -- ���p���v
          , g_data_tab(29) -- �����p�����뉿�z
          , g_data_tab(30) -- �擾���i�C���z
          , g_data_tab(31) -- �_��ԍ�
          , g_data_tab(32) -- ���[�X���
          , g_data_tab(33) -- ���[�X��Ж�
          , g_data_tab(34) -- �_�񖾍ד���ID
          , g_data_tab(35) -- �_��}��
          , g_data_tab(36) -- �����R�[�h
          , g_data_tab(37) -- AP�������ԍ�
          , g_data_tab(38) -- �\�[�X���דE�v
          , g_data_tab(39) -- �d����R�[�h
          , g_data_tab(40) -- �d���於
          , g_data_tab(41) -- �\�[�X���׎x�����z
          , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
          , g_data_tab(43) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
          ;
        EXIT WHEN get_manual_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
--
        gn_target_cnt      := gn_target_cnt + 1;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-6)
        --==============================================================
        chk_item(
          ov_errbuf     =>    lv_errbuf    -- �G���[�E���b�Z�[�W
         ,ov_retcode    =>    lv_retcode   -- ���^�[���E�R�[�h
         ,ov_errmsg     =>    lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,ov_skipflg    =>    lv_skipflg   -- �X�L�b�v�t���O
        );
--
        -- ������I��
        IF ( lv_retcode = cv_status_normal ) THEN
--
          --==============================================================
          -- CSV�o�͏���(A-7)
          --==============================================================
          out_csv (
            ov_errbuf     =>    lv_errbuf
           ,ov_retcode    =>    lv_retcode
           ,ov_errmsg     =>    lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- ���x���I��
        ELSIF ( lv_retcode = cv_status_warn ) THEN
--
          --==============================================================
          --���A�g�e�[�u���o�^����(A-8)
          --==============================================================
          -- �蓮�Ȃ̂œo�^�͂��Ȃ��BA-6�Ŏ擾�����G���[���O�o�͏����̂݁B
          ins_fa_wait_coop(
            iv_errmsg     =>    lv_errmsg     -- A-6�̃��[�U�[�G���[���b�Z�[�W
          , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
          , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
          , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
          , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          ov_retcode := cv_status_warn;
--
        -- ���G���[�I��
        ELSIF ( lv_retcode = cv_status_error ) THEN
--
          RAISE global_process_expt;
--
        END IF;
--
      END LOOP get_manual_loop;
--
      CLOSE get_manual_cur;
--
      -- �����Ώۃf�[�^�����݂��Ȃ��ꍇ
      IF ( gn_target_cnt = 0 ) THEN
--
        RAISE get_data_expt;
--
      END IF;
--
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    ELSIF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --�J�[�\���I�[�v��
      OPEN get_fixed_period_cur;
      <<get_fixed_period_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
            g_data_tab(1)  -- ���YID
          , g_data_tab(2)  -- ���Y�ԍ�
          , g_data_tab(3)  -- ���Y�J�e�S��
          , g_data_tab(4)  -- �P��
          , g_data_tab(5)  -- �E�v
          , g_data_tab(6)  -- ���Y�䒠��
          , g_data_tab(7)  -- �擾���i
          , g_data_tab(8)  -- �����擾���i
          , g_data_tab(9)  -- �c�����z
          , g_data_tab(10) -- �c�����z�p�[�Z���g
          , g_data_tab(11) -- ���x�z
          , g_data_tab(12) -- ���p�Ώۊz
          , g_data_tab(13) -- ���Ƌ��p��
          , g_data_tab(14) -- ���p���@
          , g_data_tab(15) -- �ϗp�N��
          , g_data_tab(16) -- �����p���@
          , g_data_tab(17) -- �Q�Ɣԍ�
          , g_data_tab(18) -- ����^�C�v
          , g_data_tab(19) -- �����
          , g_data_tab(20) -- ����
          , g_data_tab(21) -- GL�]����v����
          , g_data_tab(22) -- �d��w�b�_�[ID
          , g_data_tab(23) -- �����p�^�C�v
          , g_data_tab(24) -- �����p�P��
          , g_data_tab(25) -- �����p�擾���i
          , g_data_tab(26) -- ���p���z
          , g_data_tab(27) -- �P����p
          , g_data_tab(28) -- ���p���v
          , g_data_tab(29) -- �����p�����뉿�z
          , g_data_tab(30) -- �擾���i�C���z
          , g_data_tab(31) -- �_��ԍ�
          , g_data_tab(32) -- ���[�X���
          , g_data_tab(33) -- ���[�X��Ж�
          , g_data_tab(34) -- �_�񖾍ד���ID
          , g_data_tab(35) -- �_��}��
          , g_data_tab(36) -- �����R�[�h
          , g_data_tab(37) -- AP�������ԍ�
          , g_data_tab(38) -- �\�[�X���דE�v
          , g_data_tab(39) -- �d����R�[�h
          , g_data_tab(40) -- �d���於
          , g_data_tab(41) -- �\�[�X���׎x�����z
          , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
          , g_data_tab(43) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
          ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
--
        -- ������������
        IF ( g_data_tab(43) = cv_data_type_0 ) THEN
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-6)
        --==============================================================
        chk_item(
          ov_errbuf     =>    lv_errbuf    -- �G���[�E���b�Z�[�W
         ,ov_retcode    =>    lv_retcode   -- ���^�[���E�R�[�h
         ,ov_errmsg     =>    lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,ov_skipflg    =>    lv_skipflg   -- �X�L�b�v�t���O
        );
--
        -- ������I��
        IF ( lv_retcode = cv_status_normal ) THEN
--
          --==============================================================
          -- CSV�o�͏���(A-7)
          --==============================================================
          out_csv (
            ov_errbuf     =>    lv_errbuf
           ,ov_retcode    =>    lv_retcode
           ,ov_errmsg     =>    lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- ���x���I��
        ELSIF ( lv_retcode = cv_status_warn ) THEN
--
          --==============================================================
          --���A�g�e�[�u���o�^����(A-8)
          --==============================================================
          -- ���A�g�e�[�u���o�^����(A-8)�A�A���A�X�L�b�v�t���O��ON(��1)�̏ꍇ��
          -- ���A�g�e�[�u���ɂ͓o�^���Ȃ�(���O�̏o�͂���)�B
          -- (��1)�@���A�g�e�[�u���Ƀf�[�^������ꍇ�A�A�����G���[�����������ꍇ
          ins_fa_wait_coop(
            iv_errmsg     =>    lv_errmsg     -- A-6�̃��[�U�[�G���[���b�Z�[�W
          , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
          , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
          , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
          , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          ov_retcode := cv_status_warn;
--
        -- ���G���[�I��
        ELSIF ( lv_retcode = cv_status_error ) THEN
--
          RAISE global_process_expt;
--
        END IF;
--
      END LOOP get_fixed_period_loop;
--
      CLOSE get_fixed_period_cur;
--
      -- �����Ώۃf�[�^�����݂��Ȃ��ꍇ
      IF ( ( gn_target_cnt = 0 ) AND ( gn_target_wait_cnt = 0 ) ) THEN
--
        RAISE get_data_expt;
--
      END IF;
--
    END IF;
--
  EXCEPTION
--
    -- *** �f�[�^�擾��O�n���h�� ***
    WHEN get_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11089  -- ���Y�Ǘ����
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
      IF ( get_manual_cur%ISOPEN ) THEN
        CLOSE get_manual_cur;
      END IF;
      IF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : del_fa_wait_coop
   * Description      : ���A�g�f�[�^�폜����(A-9)
   ***********************************************************************************/
  PROCEDURE del_fa_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_fa_wait_coop'; -- �v���O������
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
    --==============================================================
    --���A�g�f�[�^�폜
    --==============================================================
--
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --A-2�Ŏ擾�������A�g�f�[�^�������ɁA�폜���s��
      <<delete_loop>>
      FOR i IN 1 .. g_row_id_tab.COUNT LOOP
        BEGIN
--
          DELETE FROM xxcfo_fa_wait_coop xfwc -- ���Y�Ǘ����A�g
          WHERE xfwc.rowid = g_row_id_tab( i )
          AND   xfwc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name   -- XXCFO
                                      ,cv_msg_cfo_00025    -- �f�[�^�폜�G���[
                                      ,cv_tkn_table        -- �g�[�N��'TABLE'
                                      ,cv_msg_cfo_11090    -- ���Y�Ǘ����A�g�e�[�u��
                                      ,cv_tkn_errmsg       -- �g�[�N��'ERRMSG'
                                      ,SQLERRM             -- SQL�G���[���b�Z�[�W
                                     )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
          END;
      END LOOP delete_loop;
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_fa_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_fa_control
   * Description      : �Ǘ��e�[�u���X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE upd_fa_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_fa_control'; -- �v���O������
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
      --==============================================================
      --���Y�Ǘ��Ǘ��e�[�u���X�V
      --==============================================================
--
    -- ������s�A���A����v���Ԃ̃f�[�^�����������ꍇ�̂ݍX�V
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( gn_target_cnt > 0 ) ) THEN
--
      BEGIN
--
        UPDATE xxcfo_fa_control xfc --���Y�Ǘ��Ǘ�
        SET xfc.period_name            = gt_next_period_name       -- ��v����
           ,xfc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           ,xfc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,xfc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,xfc.request_id             = cn_request_id             -- �v��ID
           ,xfc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,xfc.program_id             = cn_program_id             -- �v���O����ID
           ,xfc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE xfc.set_of_books_id      = gn_set_of_bks_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table        -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11065    -- ���Y�Ǘ��Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg       -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM             -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_fa_control;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn           IN  VARCHAR2,  -- 1.�ǉ��X�V�敪
    iv_file_name             IN  VARCHAR2,  -- 2.�t�@�C����
    iv_period_name           IN  VARCHAR2,  -- 3.��v����
    iv_exec_kbn              IN  VARCHAR2,  -- 4.����蓮�敪
    ov_errbuf                OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
    gn_wait_data_cnt   := 0;
    gn_target_wait_cnt := 0;
    
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
      iv_ins_upd_kbn           => iv_ins_upd_kbn,  -- 1.�ǉ��X�V�敪
      iv_file_name             => iv_file_name,    -- 2.�t�@�C����
      iv_period_name           => iv_period_name,  -- 3.��v����
      iv_exec_kbn              => iv_exec_kbn,     -- 4.����蓮�敪
      ov_errbuf                => lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_fa_wait(
      ov_errbuf                => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_fa_control(
      ov_errbuf                => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N����(A-4)
    -- ===============================
    chk_gl_period_status(
      ov_errbuf                => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ��v���ԃ`�F�b�N����(A-4)�̌㑱��������ŃX�L�b�v����Ɣ��肵���ꍇ�A���������ɏI������
    -- A-1����A-3�Ōx�������������ꍇ�������Đ���I��
    IF ( gv_skip_flg = cv_flag_y ) THEN
--
      NULL;
--
    ELSE
--
      -- ===============================
      -- �Ώۃf�[�^�擾����(A-5)
      -- ===============================
      get_data(
        ov_errbuf                => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
--
      --==============================================================
      --���A�g�e�[�u���폜����(A-9)
      --==============================================================
      del_fa_wait_coop(
        ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
      , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
      , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �Ǘ��e�[�u���X�V����(A-10)
      -- ===============================
      upd_fa_control(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
--
    END IF;
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
    errbuf                   OUT VARCHAR2,    -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT VARCHAR2,    -- �G���[�R�[�h     #�Œ�#
    iv_ins_upd_kbn           IN  VARCHAR2,    -- 1.�ǉ��X�V�敪
    iv_file_name             IN  VARCHAR2,    -- 2.�t�@�C����
    iv_period_name           IN  VARCHAR2,    -- 3.��v����
    iv_exec_kbn              IN  VARCHAR2     -- 4.����蓮�敪
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
       iv_ins_upd_kbn           -- 1.�ǉ��X�V�敪
      ,iv_file_name             -- 2.�t�@�C����
      ,iv_period_name           -- 3.��v����
      ,iv_exec_kbn              -- 4.����蓮�敪
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_target_wait_cnt := 0;
      gn_wait_data_cnt   := 0;
    END IF;
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
--
    -- �x�����̃��^�[���R�[�h�ݒ�
    IF ( ( gv_warning_flg = cv_flag_y ) AND ( lv_retcode <> cv_status_error ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    -- ====================================================
    -- �t�@�C���N���[�Y
    -- ====================================================
    -- �t�@�C�����I�[�v������Ă���ꍇ�̓N���[�Y����
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- �t�@�C���N���A(�G���[�I�������ꍇ�͋�t�@�C���쐬)
    -- ====================================================
--
    IF ( ( iv_exec_kbn = cv_exec_manual ) AND ( lv_retcode = cv_status_error )
      -- �t�@�C����FOPEN������ɃG���[�I�������ꍇ
      AND ( gb_reopen_flag = TRUE ) )
    THEN
--
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
--
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029     -- �t�@�C���I�[�v���G���[
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
--
      END;
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gv_file_hand );
--
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o�́i�A�g���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o�́i���A�g�������j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_wait_data_cnt)
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
END XXCFO019A11C;
/
