CREATE OR REPLACE PACKAGE BODY XXCFO021A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO021A03C(body)
 * Description      : �d�q����d�����ю���̏��n�V�X�e���A�g
 * MD.050           : �d�q����d�����ю���̏��n�V�X�e���A�g<MD050_CFO_021_A03>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_wait_coop          ���A�g�f�[�^�擾����(A-2)
 *  get_mfg_txn_control    �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  chk_gl_period_status   ��v���ԃ`�F�b�N����(A-4)
 *  chk_item               ���ڃ`�F�b�N����(A-6)
 *  out_csv                CSV�o�͏���(A-7)
 *  ins_wait_coop          ���A�g�e�[�u���o�^����(A-8)
 *  get_data               �Ώۃf�[�^�擾����(A-5)
 *  del_wait_coop          ���A�g�f�[�^�폜����(A-9)
 *  upd_mfg_txn_control    �Ǘ��e�[�u���X�V����(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-08    1.0   A.Uchida         �V�K�쐬
 *  2015-02-24    1.1   A.Uchida         �ڍs��Q#7�Ή�
 *                                       �E�d����o�א��ʂ̌����ӂ�Ή�
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
  gv_exec_user       VARCHAR2(100);
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO021A03C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[
  cv_msg_cfo_00027            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00031            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --�N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[���b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_00029            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_10005            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10005';   --�d�󖢓]�L���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --���A�g�f�[�^�`�F�b�N
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --�t�@�C�������݃G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_10001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10053            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10053';   --�J��z���f�[�^���b�Z�[�W
--
  -- ���b�Z�[�W(�g�[�N��)
  cv_msg_cfo_11134            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11134';   -- ���{�ꕶ����(�u�d�����ю�����A�g�e�[�u���v)
  cv_msg_cfo_11124            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11124';   -- ���{�ꕶ����(�u���Y����A�g�Ǘ��e�[�u���v)
  cv_msg_cfo_11125            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11125';   -- ���{�ꕶ����(�u��v���ԁv)
  cv_msg_cfo_11135            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11135';   -- ���{�ꕶ����(�u���ID�v)
  cv_msg_cfo_11138            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11138';   -- ���{�ꕶ����(�u���הԍ��v)
  cv_msg_cfo_11136            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11136';   -- ���{�ꕶ����(�u�d�����ю�����v)
  cv_msg_cfo_11137            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11137';   -- ���{�ꕶ����(�u�d���v)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';   -- ���{�ꕶ����(�u�A�v)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   -- ���{�ꕶ����(�u���ڂ��s���v)
  cv_msg_cfo_11132            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11132';   -- ���{�ꕶ����(�u���Y�V�X�e���v�j
--
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
  cv_lookup_book_date         CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';           --�d�q���돈�����s��
  cv_lookup_item_chk_po       CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_PO';         --�d�q���덀�ڃ`�F�b�N�i�d�����ю���j
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                                  -- �t���O�lY
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                                  -- �t���O�lN
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                                  -- �X���b�V��
--
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- �d�q����d�����ю���f�[�^�t�@�C���i�[�p�X
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- ��v����ID
  cv_mfg_org_id               CONSTANT VARCHAR2(100) := 'XXCFO1_MFG_ORG_ID';                  -- ���Y�V�X�e��ORG_ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_PO_DATA_FILENAME'; -- �d�q����d�����ю���f�[�^�t�@�C����
--
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- �蓮���s
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- ����A�g��(���)
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- ���A�g��
--
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';                  -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';                  -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';                  -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';                  -- CHAR2   �i�`�F�b�N�j
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- ��������
--
  --�����t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
  cv_date_format_ym           CONSTANT VARCHAR2(7)   := 'YYYY-MM';
  cv_date_format_ymd_slash    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- �N���[�Y�X�e�[�^�X
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                   -- ���уt���O
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                   -- �X�e�[�^�X�F'P'(���]�L)
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
  gn_mfg_org_id               NUMBER;
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --�x���t���O
  gv_skip_flg                 VARCHAR2(1) DEFAULT 'N'; --�X�L�b�v�t���O
--
  -- CSV�t�@�C���o�͗p
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_file_data                VARCHAR2(32767);
--
  -- ���Y����A�g�Ǘ��e�[�u���̉�v����
  gt_period_name              xxcfo_mfg_txn_if_control.period_name%TYPE;
  -- ���Y����A�g�Ǘ��e�[�u���̗���v����
  gt_next_period_name         xxcfo_mfg_txn_if_control.period_name%TYPE;
  -- ���C���J�[�\���̉�v���ԕێ��p
  gt_period_name_cur          xxcfo_mfg_txn_if_control.period_name%TYPE;
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
  gv_punctuation_mark         VARCHAR2(50);    -- ���{�ꕶ����(�u�A�v)
  gv_illegal_item             VARCHAR2(50);    -- ���{�ꕶ����(�u���ڂ��s���v)
  gv_tbl_nm_wait_coop         VARCHAR2(50);    -- ���{�ꕶ����(�u�d�����ю�����A�g�e�[�u���v)
  gv_tbl_nm_mfg_txn_ctl       VARCHAR2(50);    -- ���{�ꕶ����(�u���Y����A�g�Ǘ��e�[�u���v)
  gv_col_nm_period_name       VARCHAR2(50);    -- ���{�ꕶ����(�u��v���ԁv)
  gv_msg_po_info              VARCHAR2(50);    -- ���{�ꕶ����(�u�d�����ю�����v)
  gv_je_source_mfg            VARCHAR2(50);    -- ���{�ꕶ����(�u���Y�V�X�e���v)
  gv_je_category_po           VARCHAR2(50);    -- ���{�ꕶ����(�u�d���v)
  gv_col_nm_txns_id           VARCHAR2(50);    -- ���{�ꕶ����(�u���ID�v)
  gv_col_nm_line_num          VARCHAR2(50);    -- ���{�ꕶ����(�u���הԍ��v)
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
    -- �d�����ю�����A�g�f�[�^(�����)
    CURSOR get_wait_coop_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_po_wait_coop xpwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    --�d�����ю�����A�g�f�[�^(�蓮��)
    CURSOR get_wait_coop_m_cur
    IS
      SELECT period_name       AS period_name
            ,txns_id           AS txns_id
      FROM   xxcfo_po_wait_coop  xpwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <�d�����ю�����A�g�e�[�u��>�e�[�u���^
    TYPE get_wait_coop_m_type IS TABLE OF get_wait_coop_m_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    g_wait_coop_m_rec        get_wait_coop_m_type;
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
    iv_file_name             IN  VARCHAR2,     -- 1.�t�@�C����
    iv_period_name           IN  VARCHAR2,     -- 2.��v����
    iv_exec_kbn              IN  VARCHAR2,     -- 3.����蓮�敪
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_po
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
      , iv_conc_param1                  =>        iv_file_name              -- 1.�t�@�C����
      , iv_conc_param2                  =>        iv_period_name            -- 2.��v����
      , iv_conc_param3                  =>        iv_exec_kbn               -- 3.����蓮�敪
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
      , iv_conc_param1                  =>        iv_file_name              -- 1.�t�@�C����
      , iv_conc_param2                  =>        iv_period_name            -- 2.��v����
      , iv_conc_param3                  =>        iv_exec_kbn               -- 3.����蓮�敪
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
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
--
    IF ( ln_target_cnt = 0 ) THEN
      lt_lookup_type    :=  cv_lookup_item_chk_po;
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
--
    --==============================================================
    -- 1.(6) �v���t�@�C���擾
    --==============================================================
    --�t�@�C���p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
--
    IF ( gt_file_path IS NULL ) THEN
      lt_token_prof_name := cv_data_filepath;
      RAISE get_profile_expt;
--
    END IF;
--
    -- ��v����ID
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_gl_set_of_bks_id ) );
--
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lt_token_prof_name := cv_gl_set_of_bks_id;
      RAISE get_profile_expt;
--
    END IF;
--
    -- ���Y�V�X�e��ORG_ID
    gn_mfg_org_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_mfg_org_id ) );
--
    IF ( gn_mfg_org_id IS NULL ) THEN
      lt_token_prof_name := cv_mfg_org_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
      -- �d�q����d�����ю���f�[�^�t�@�C����
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      lt_token_prof_name := cv_add_filename;
--
      IF ( gv_file_name IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
    ELSE
      -- �p�����[�^���O���[�o���ϐ��Ɋi�[
      gv_file_name := iv_file_name;    -- 1.�t�@�C����
    END IF;
--
    --==============================================================
    -- 1.(7) �f�B���N�g���p�X�擾
    --==============================================================
    BEGIN
      SELECT    ad.directory_path AS directory_path
      INTO      gt_directory_path
      FROM      all_directories  ad
      WHERE     ad.directory_name  =  gt_file_path
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE  get_dir_path_expt;
    END;
--
    --==================================
    -- 1.(8) IF�t�@�C�����o��
    --==================================
    -- �p�X�̃��X�g�ɃX���b�V�����܂܂�Ă���ꍇ
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
      -- �f�B���N�g���ƃt�@�C�������̂܂ܘA��
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
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
    gv_tbl_nm_wait_coop := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11134     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_tbl_nm_mfg_txn_ctl := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11124     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_period_name := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11125     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_txns_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11135     -- ���b�Z�[�W�R�[�h
                                      )
                               , 1
                               , 5000
                               );
--
    gv_illegal_item := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11008     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_punctuation_mark := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11088     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_msg_po_info := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11136     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_je_source_mfg := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11132     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_je_category_po := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11137     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_line_num := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11138     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    --==================================
    -- �p�����[�^���O���[�o���ϐ��Ɋi�[
    --==================================
    gv_period_name           := iv_period_name;                       -- 3.��v����
    gv_exec_kbn              := iv_exec_kbn;                          -- 4.����蓮�敪
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN get_process_date_expt  THEN
      -- �Ɩ��������t�̎擾�Ɏ��s���܂����B
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00015
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Q�ƃ^�C�v�E�R�[�h�擾��O�n���h�� ***
    WHEN get_quickcode_expt  THEN
      -- �N�C�b�N�R�[�h����̎擾�Ɏ��s���܂����B
      -- ���b�N�A�b�v�^�C�v�F ��LOOKUP_TYPE
      -- ���b�N�A�b�v�R�[�h�F ��LOOKUP_CODE
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
    -- *** �Q�ƃ^�C�v�擾��O�n���h�� ***
    -- �Q�ƃ^�C�v�u ��LOOKUP_TYPE �v�̎擾�Ɏ��s���܂����B
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
    -- �v���t�@�C���u ��PROF_NAME �v�̎擾�Ɏ��s���܂����B
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
    -- ���̃f�B���N�g�����ł̓f�B���N�g���p�X�͎擾�ł��܂���B
    -- �i�f�B���N�g���� =  ��DIR_TOK�@�j
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
    -- �O��쐬�����t�@�C�������݂��Ă��܂��B
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
   * Procedure Name   : get_wait_coop
   * Description      : A-2�D���A�g�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wait_coop'; -- �v���O������
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
    -- ����̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --�J�[�\���I�[�v��
      OPEN get_wait_coop_f_cur;
      FETCH get_wait_coop_f_cur BULK COLLECT INTO g_row_id_tab;
      --�J�[�\���N���[�Y
      CLOSE get_wait_coop_f_cur;
--
    -- �蓮�̏ꍇ�̓L�[���ڎ擾
    ELSE
      --�J�[�\���I�[�v��
      OPEN get_wait_coop_m_cur;
      FETCH get_wait_coop_m_cur BULK COLLECT INTO g_wait_coop_m_rec;
      --�J�[�\���N���[�Y
      CLOSE get_wait_coop_m_cur;
--
    END IF;
--
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      -- ��TABLE �̃��b�N�Ɏ��s���܂����B���Ԃ������Ă���A�ēx�����������{���ĉ������B
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => gv_tbl_nm_wait_coop    -- �d�����ю�����A�g�e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
      IF ( get_wait_coop_m_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_wait_coop_m_cur;
      END IF;
      IF ( get_wait_coop_f_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_wait_coop_f_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_mfg_txn_control
   * Description      : A-3�D�Ǘ��e�[�u���f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_mfg_txn_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_mfg_txn_control'; -- �v���O������
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
    ln_cnt        NUMBER DEFAULT 0;
--
    -- ===============================
    -- �J�[�\��
    -- ===============================
    -- ���Y����A�g�Ǘ��e�[�u��(���b�N����)
    CURSOR get_mfg_txn_control_lock_cur
    IS
      SELECT xmtic.period_name  AS period_name,        -- ��v����
             TO_CHAR(ADD_MONTHS( TO_DATE( xmtic.period_name,cv_date_format_ym ) , 1 ) , cv_date_format_ym)
                              AS next_period_name    -- ����v����
      FROM   xxcfo_mfg_txn_if_control xmtic          -- ���Y����A�g�Ǘ�
      WHERE  xmtic.set_of_books_id  =  gn_set_of_bks_id    -- ��v����ID
      AND    xmtic.PROGRAM_NAME     =  cv_pkg_name         -- �@�\��
      FOR UPDATE NOWAIT
      ;
--
    get_mfg_txn_control_lock_rec     get_mfg_txn_control_lock_cur%ROWTYPE;
--
    -- ���Y����A�g�Ǘ��e�[�u��
    CURSOR get_mfg_txt_control_cnt_cur
    IS
      SELECT COUNT(1)
      FROM   xxcfo_mfg_txn_if_control xmtic          -- ���Y����A�g�Ǘ�
      WHERE  set_of_books_id  =  gn_set_of_bks_id    -- ��v����ID
      AND    PROGRAM_NAME     =  cv_pkg_name         -- �@�\��
      ;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_mfg_txn_control_expt       EXCEPTION;
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
      OPEN  get_mfg_txn_control_lock_cur;
      FETCH get_mfg_txn_control_lock_cur INTO get_mfg_txn_control_lock_rec;
      CLOSE get_mfg_txn_control_lock_cur;
--
      IF ( get_mfg_txn_control_lock_rec.period_name IS NULL ) THEN
        RAISE get_mfg_txn_control_expt;
--
      ELSE
        -- ���O���[�o���l�Ɋi�[
        -- �Ǘ��e�[�u���̉�v����
        gt_period_name       := get_mfg_txn_control_lock_rec.period_name;
        -- �Ǘ��e�[�u���̉�v���Ԃ̗���
        gt_next_period_name  := get_mfg_txn_control_lock_rec.next_period_name;
--
      END IF;
    -- �蓮���s�̏ꍇ
    -- �Ǘ��e�[�u���Ƀf�[�^���Ȃ��ꍇ�͌x��(�����Z�b�g�A�b�v�R��)
    ELSE
      OPEN  get_mfg_txt_control_cnt_cur;
      FETCH get_mfg_txt_control_cnt_cur INTO ln_cnt;
      CLOSE get_mfg_txt_control_cnt_cur;
--
      IF ( ln_cnt = 0 ) THEN
        -- [ ��GET_DATA ] �Ώۃf�[�^������܂���ł����B
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => gv_tbl_nm_mfg_txn_ctl       -- ���Y����A�g�Ǘ��e�[�u��
        );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --�t�@�C���I�[�v��
    --==============================================================
    BEGIN
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
        -- �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂���B
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
    -- *** ���b�N�G���[��O�n���h�� ***
    -- ��TABLE �̃��b�N�Ɏ��s���܂����B���Ԃ������Ă���A�ēx�����������{���ĉ������B
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => gv_tbl_nm_mfg_txn_ctl     -- ���Y����A�g�Ǘ��e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���Y����A�g�Ǘ��e�[�u���擾��O�n���h�� ***
    -- [ ��GET_DATA ] �Ώۃf�[�^������܂���ł����B
    WHEN get_mfg_txn_control_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => gv_tbl_nm_mfg_txn_ctl     -- ���Y����A�g�Ǘ��e�[�u��
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
      IF ( get_mfg_txn_control_lock_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_mfg_txn_control_lock_cur;
      END IF;
      IF ( get_mfg_txt_control_cnt_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_mfg_txt_control_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_mfg_txn_control;
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
      BEGIN
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
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
          lv_errbuf := SQLERRM;
--
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --�㑱��������
    --==============================================================
    -- 1.����̏ꍇ ���A2.���A�g�e�[�u���Ƀf�[�^�Ȃ� ���A3.��v���Ԃ��N���[�Y���Ă��Ȃ�
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT = 0 ) AND ( ln_count = 0 ) ) THEN
      -- �㑱�����͍s�킸�A�I������(A-11)
      gv_skip_flg := cv_flag_y;
--
    -- 1.����̏ꍇ ���A2.���A�g�e�[�u���Ƀf�[�^���� ���A3.��v���Ԃ��N���[�Y���Ă��Ȃ�
    ELSIF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT > 0 ) AND ( ln_count = 0 ) ) THEN
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
      --==============================================================
      -- [�蓮���s]�̏ꍇ�A���A�g�f�[�^�Ƃ��đ��݂��Ă��邩���`�F�b�N
      --==============================================================
--
      -- ����̃L�[���ڂ̃f�[�^�����A�g�e�[�u���ɒl���������ꍇ�́u�x���˃X�L�b�v�v
      <<g_wait_coop_m_loop>>
      FOR i IN 1 .. g_wait_coop_m_rec.COUNT LOOP
        -- �L�[���ڂ���v
        IF ( g_data_tab(81) = g_wait_coop_m_rec(i).txns_id            ) THEN   -- ���ID
          -- �X�L�b�v�t���O��ON(�@A-7�FCSV�o�́A�AA-8�F���A�g�e�[�u���o�^���X�L�b�v)
          ov_skipflg := cv_flag_y;
--
          -- �����M�̃f�[�^�ł��B( ��DOC_DATA = ��DOC_DIST_ID )
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10010                                  -- ���A�g�f�[�^�`�F�b�NID�G���[
                                 ,cv_tkn_doc_data                                   -- �g�[�N��'DOC_DATA'
                                 ,gv_col_nm_period_name || gv_punctuation_mark ||
                                  gv_col_nm_txns_id     || gv_punctuation_mark ||
                                  gv_col_nm_line_num                                -- �L�[���ږ�
                                 ,cv_tkn_doc_dist_id                                -- �g�[�N��'DOC_DIST_ID'
                                 ,g_data_tab(83) || gv_punctuation_mark ||
                                  g_data_tab(81)           )                        -- �L�[���ڒl
                               ,1
                               ,5000);
          RAISE warn_expt;
--
        END IF;
      END LOOP g_wait_coop_m_loop;
    END IF;
--
    --==============================================================
    -- �]�L�σ`�F�b�N
    --==============================================================
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --�ŏ���1���ځA�܂��͉�v���Ԃ��؂�ւ�����ꍇ(���A�g�f�[�^���������ꍇ��z��)�̂݃`�F�b�N
      --(1���ł�NG�������炷�ׂẴ��R�[�h���x��)
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(83) ) ) THEN
        -- ���]�L�t���O��OFF
        gb_gl_je_flg := FALSE;
--
        -- ���ݍs�̉�v���Ԃ�ێ�
        gt_period_name_cur := g_data_tab(83);
--
        -- �]�L��
        BEGIN
          SELECT COUNT(1)
          INTO   ln_count
          FROM   gl_je_headers       gjh,  -- �d��w�b�_
                 gl_je_sources_vl    gjsv, -- GL�d��\�[�X
                 gl_je_categories_vl gjcv  -- GL�d��J�e�S��
          WHERE   gjcv.je_category_name = gjh.je_category
          AND     gjsv.je_source_name   = gjh.je_source
          AND     gjcv.user_je_category_name = gv_je_category_po     -- �d��J�e�S�� '�d��'
          AND     gjsv.user_je_source_name   = gv_je_source_mfg      -- �d��\�[�X��(�e���Y�V�X�e���f)
          AND     gjh.actual_flag            = cv_result_flag        -- �eA�f�i���сj
          AND     gjh.status                 = cv_status_p           -- �eP�f�i�]�L�ρj
          AND     gjh.period_name            = g_data_tab(83)        -- A-5�Ŏ擾������v����
          AND     gjh.set_of_books_id        = gn_set_of_bks_id
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SQLERRM;
            lv_errbuf := SQLERRM;
--
            RAISE global_process_expt;
        END;
--
        IF ( ln_count = 0 ) THEN
          -- �d�󂪖��]�L�̂��߁A����A�g���s���܂���B�i ��KEY_ITEM �F ��KEY_VALUE �j
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10005                                  -- �d�󖢓]�L���b�Z�[�W
                                 ,cv_tkn_key_item                                   -- �g�[�N��'KEY_ITEM'
                                 ,gv_col_nm_period_name || gv_punctuation_mark ||
                                  gv_col_nm_txns_id     || gv_punctuation_mark ||
                                  gv_col_nm_line_num                                -- �L�[���ږ�
                                 ,cv_tkn_key_value                                  -- �g�[�N��'KEY_VALUE'
                                 ,g_data_tab(83) || gv_punctuation_mark ||
                                  g_data_tab(81)           )                        -- �L�[���ڒl
                               ,1
                               ,5000);
--
          -- ���]�L�t���O��ON
          gb_gl_je_flg := TRUE;
--
          -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
          RAISE warn_expt;
        END IF;
      -- �O���R�[�h�Ɠ�����v���ԁA���A���]�L�t���O��ON�̏ꍇ�͂��ׂČx��
      ELSIF ( ( gt_period_name_cur = g_data_tab(83) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- �d�󖢓]�L���b�Z�[�W
                               ,cv_tkn_key_item           -- �g�[�N��'KEY_ITEM'
                               ,gv_col_nm_period_name || gv_punctuation_mark ||
                                gv_col_nm_txns_id     || gv_punctuation_mark ||
                                gv_col_nm_line_num                                -- �L�[���ږ�
                               ,cv_tkn_key_value                           -- �g�[�N��'KEY_VALUE'
                               ,g_data_tab(83) || gv_punctuation_mark ||
                                g_data_tab(81)           )                        -- �L�[���ڒl
                             ,1
                             ,5000);
--
        -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
        RAISE warn_expt;
      END IF;
    END IF;
--
    -- �������ԍ��`�F�b�N
    -- �������ԍ���-1�ł���f�[�^�͌J��z���f�[�^�̂��ߏ������Ȃ�
    IF ( g_data_tab(78) = '-1' ) THEN
      -- �G���[���b�Z�[�W�ҏW
      -- �J��z���f�[�^�̂��߁A�X�L�b�v���܂��B�i ��KEY_DATA �j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcfo_appl_name,
                     iv_name               => cv_msg_cfo_10053,
                     iv_token_name1        => cv_tkn_key_data ,
                     iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                              g_data_tab(81)         ) ;
--
      -- �x���˖��A�g�e�[�u���֓o�^
      -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �^�^���^�K�{�̃`�F�b�N
    --==============================================================
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
      -- �A�g�����ȊO�̓`�F�b�N����
      IF   (( ln_cnt <> 82 )
        AND ( ln_cnt <> 15 )
        AND ( ln_cnt <> 17 )) THEN
--
        -- 2015-02-24 Ver1.1 Add Start
        -- �d����o�א��ʂ������_��3�ʂŎl�̌ܓ�
        IF ln_cnt = 39 THEN
          g_data_tab(ln_cnt) := TO_CHAR(ROUND(TO_NUMBER(g_data_tab(ln_cnt)),2));
        END IF;
        -- 2015-02-24 Ver1.1 Add End
--
        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name     => g_item_name_tab(ln_cnt)     --���ږ���
          , iv_item_value    => g_data_tab(ln_cnt)          --���ڂ̒l
          , in_item_len      => g_item_len_tab(ln_cnt)      --���ڂ̒���
          , in_item_decimal  => g_item_decimal_tab(ln_cnt)  --���ڂ̒���(�����_�ȉ�)
          , iv_item_nullflg  => g_item_nullflg_tab(ln_cnt)  --�K�{�t���O
          , iv_item_attr     => g_item_attr_tab(ln_cnt)     --���ڑ���
          , iv_item_cutflg   => g_item_cutflg(ln_cnt)       --�؎̂ăt���O
          , ov_item_value    => g_data_tab(ln_cnt)          --���ڂ̒l
          , ov_errbuf        => lv_errbuf                   --�G���[���b�Z�[�W
          , ov_retcode       => lv_retcode                  --���^�[���R�[�h
          , ov_errmsg        => lv_errmsg                   --���[�U�[�E�G���[���b�Z�[�W
          );
--
        -- ������ȊO�̏ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ���x���̏ꍇ
          IF ( lv_retcode = cv_status_warn ) THEN
            -- ���
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
              -- �����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
                -- �X�L�b�v�t���O��ON(�@A-7�FCSV�o�́A�AA-8�F���A�g�e�[�u���o�^���X�L�b�v)
                ov_skipflg := cv_flag_y;
--
                -- �G���[���b�Z�[�W�ҏW
                -- �����𒴉߂��Ă��鍀�ڂ̂��߁A�X�L�b�v���܂��B�i ��KEY_DATA �j
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application        => cv_xxcfo_appl_name,
                               iv_name               => cv_msg_cfo_10011,
                               iv_token_name1        => cv_tkn_key_data ,
                               iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                                        g_data_tab(81)        );     -- �L�[���ڒl
--
              -- �����`�F�b�N�ȊO
              ELSE
                -- ���ʊ֐��̃G���[���b�Z�[�W���o��
                -- ��CAUSE �ׁ̈A���A�g�f�[�^�ƂȂ�܂��B�i �ΏہF ��TARGET �j ���e�F ��MEANING
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => gv_illegal_item
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => g_data_tab(83) || gv_punctuation_mark ||
                                                   g_data_tab(81)               -- �L�[���ڒl
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
              -- �����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
                -- �G���[���b�Z�[�W�ҏW
                -- �����𒴉߂��Ă��鍀�ڂ̂��߁A�X�L�b�v���܂��B�i ��KEY_DATA �j
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                iv_application        => cv_xxcfo_appl_name,
                                iv_name               => cv_msg_cfo_10011,
                                iv_token_name1        => cv_tkn_key_data ,
                                iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                                         g_data_tab(81)           );   -- �L�[���ڒl
--
              -- �����`�F�b�N�ȊO
              ELSE
                -- ���ʊ֐��̃G���[���b�Z�[�W���o��
                -- ��CAUSE �ׁ̈A���A�g�f�[�^�ƂȂ�܂��B�i �ΏہF ��TARGET �j ���e�F ��MEANING
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => gv_illegal_item
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => g_data_tab(83) || gv_punctuation_mark ||
                                                   g_data_tab(81)               -- �L�[���ڒl
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
              END IF;
--
              RAISE warn_expt;
            END IF;
          -- ���x���ȊO
          ELSE
            lv_errmsg := lv_errbuf;
            lv_errbuf := lv_errbuf;
--
            -- �G���[(�������f)
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    END LOOP g_item_name_loop;
--
  EXCEPTION
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
      --���ڑ�����VARCHAR2,CHAR
      IF ( g_item_attr_tab(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
        -- ���s�R�[�h�A�J���}�A�_�u���R�[�e�[�V�����𔼊p�X�y�[�X�ɒu��������B
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        -- �_�u���N�H�[�g�ň͂�
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
      --���ڑ�����NUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
        -- ���̂܂ܓn��
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      --���ڑ�����DATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
        -- ���̂܂ܓn��
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      END IF;
      lv_delimit  :=  cv_delimit;
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
        -- �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂����B
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
   * Procedure Name   : ins_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_wait_coop(
    iv_errmsg     IN  VARCHAR2,     -- 1.�G���[���e
    iv_skipflg    IN  VARCHAR2,     -- 2.�X�L�b�v�t���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_wait_coop'; -- �v���O������
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
      -- �d�����ю�����A�g�e�[�u��
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_po_wait_coop(
           set_of_books_id        -- ��v����ID
          ,period_name            -- ��v����
          ,txns_id                -- ���ID
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
          ,g_data_tab(83)         -- ��v����
          ,g_data_tab(81)         -- ���ID
          ,SYSDATE
          ,cn_last_updated_by
          ,SYSDATE
          ,cn_created_by
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,SYSDATE
        );
--
        --���A�g�o�^�����J�E���g
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ��TABLE �̃f�[�^�}���Ɏ��s���܂����B
          -- �G���[���e�F ��ERRMSG
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name    -- XXCFO
                                                         ,cv_msg_cfo_00024      -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                         ,gv_tbl_nm_wait_coop   -- �d�����ю�����A�g�e�[�u��
                                                         ,cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM               -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
    END IF;
--
    --==============================================================
    -- �x���I�����̃��b�Z�[�W�o��
    --==============================================================
    IF iv_errmsg IS NOT NULL THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iv_errmsg
      );
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
  END ins_wait_coop;
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
    cv_txns_type_1            CONSTANT VARCHAR2(1)  := '1';            -- ���ы敪:1�i����j
    cv_txns_type_2            CONSTANT VARCHAR2(1)  := '2';            -- ���ы敪:2�i�ԕi�j
    cv_txns_type_3            CONSTANT VARCHAR2(1)  := '3';            -- ���ы敪:3�i�����Ȃ��ԕi�j
    cv_doc_type_porc          CONSTANT VARCHAR2(10) := 'PORC';         -- �h�L�������g�^�C�v
    cv_drop_ship_code_2       CONSTANT VARCHAR2(1)  := '2';            -- �����敪:2�i�o�ׁj
    cv_drop_ship_code_3       CONSTANT VARCHAR2(1)  := '3';            -- �����敪:2�i�x���j
    cv_default_lot_no         CONSTANT VARCHAR2(10) := 'DEFAULTLOT';   -- �f�t�H���g���b�gNo
    cv_completed_ind_1        CONSTANT NUMBER       := 1;              -- 
    cv_party_site_sts_a       CONSTANT VARCHAR2(1)  := 'A';            -- �p�[�e�B�T�C�g�X�e�[�^�X�FA
--
    -- ���b�N�A�b�v�^�C�v
    cv_lookup_po_type         CONSTANT VARCHAR2(30) := 'XXPO_PO_TYPE';
    cv_lookup_po_status       CONSTANT VARCHAR2(30) := 'XXPO_PO_ADD_STATUS';
    cv_lookup_drop_ship_type  CONSTANT VARCHAR2(30) := 'XXPO_DROP_SHIP_TYPE';
    cv_lookup_l05             CONSTANT VARCHAR2(30) := 'XXCMN_L05';
    cv_lookup_l06             CONSTANT VARCHAR2(30) := 'XXCMN_L06';
    cv_lookup_l07             CONSTANT VARCHAR2(30) := 'XXCMN_L07';
    cv_lookup_l08             CONSTANT VARCHAR2(30) := 'XXCMN_L08';
    cv_lookup_kousen_type     CONSTANT VARCHAR2(30) := 'XXPO_KOUSEN_TYPE';
    cv_lookup_fukakin_type    CONSTANT VARCHAR2(30) := 'XXPO_FUKAKIN_TYPE';
--
    -- *** ���[�J���ϐ� ***
    lv_skipflg                VARCHAR2(1) DEFAULT 'N';
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s)
    CURSOR get_manual_cur
    IS
      -- �蓮���s�F���
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- �݌ɓ���
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���艿
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,pla.attribute15                      AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- ������
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- ������P��
            ,plla.attribute3                      AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,plla.attribute6                      AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- ���ۋ�
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- ���ۋ��z
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gv_period_name                       AS period_name            -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION
      -- �蓮���s�F�ԕi
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,xrart.quantity * -1                  AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���P��
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,xrart.line_description               AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gv_period_name                       AS period_name            -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION
      -- �蓮���s�F�����Ȃ��ԕi
      SELECT NULL                                 AS status_code            -- �X�e�[�^�X�R�[�h
            ,NULL                                 AS status_name            -- �X�e�[�^�X
            ,NULL                                 AS order_type_code        -- �����敪�R�[�h
            ,NULL                                 AS order_type_name        -- �����敪��
            ,NULL                                 AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,xrart.location_code                  AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,xrart.drop_ship_type                 AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,NULL                                 AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,NULL                                 AS order_approved_flg     -- ���������t���O
            ,NULL                                 AS order_approved_date    -- �����������t
            ,NULL                                 AS purchase_approved_flg  -- �d�������t���O
            ,NULL                                 AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,NULL                                 AS order_dept_code        -- ��������
            ,NULL                                 AS order_dept_name        -- ����������
            ,NULL                                 AS req_dept_code          -- �˗�����
            ,NULL                                 AS req_dept_code          -- �˗�������
            ,xrart.delivery_code                  AS deliver_to             -- �z����
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- �z���於
            ,xrart.header_description             AS header_description     -- �E�v
            ,xrart.rcv_rtn_line_number            AS line_num               -- ���הԍ�
            ,xrart.item_code                      AS item_no                -- �i��
            ,xim2v.item_short_name                AS item_name              -- �i�ږ���
            ,xrart.futai_code                     AS incidental_code        -- �t�уR�[�h
            ,xrart.factory_code                   AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,NULL                                 AS order_quantity         -- ��������
            ,NULL                                 AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,xrart.rcv_rtn_uom                    AS order_uom              -- �����P��
            ,xrart.unit_price                     AS purchase_price         -- �d���P��
            ,NULL                                 AS quantity_fix_flag      -- ���ʊm��t���O
            ,NULL                                 AS amount_fix_flag        -- ���z�m��t���O
            ,NULL                                 AS cancel_flag            -- ����t���O
            ,NULL                                 AS fix_date               -- ���t�w��
            ,line_description                     AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,NULL                                 AS moto_item_code         -- ���i��
            ,NULL                                 AS moto_item_name         -- ���i�ږ���
            ,NULL                                 AS moto_lot_name          -- �����b�gNo
            ,NULL                                 AS purchace_type_code     -- �d���`�ԃR�[�h
            ,NULL                                 AS purchace_type_name     -- �d���`��
            ,NULL                                 AS tea_kbn_code           -- �����敪�R�[�h
            ,NULL                                 AS tea_kbn_name           -- �����敪
            ,NULL                                 AS type_code              -- �^�C�v�R�[�h
            ,NULL                                 AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,xrart.kousen_price                   AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gv_period_name                       AS period_name            -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi����
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,po_vendor_sites_all      pvsa_deliver      -- �d����T�C�g�i�z����j
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- �d����T�C�g�A�h�I���i�z����j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,xxcmn_item_mst2_v        xim2v             -- OPM�i�ڏ��VIEW
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      ORDER BY 81
      ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(������s)
    CURSOR get_fixed_period_cur
    IS
      -- ������s�F����i�ʏ�A�g���j
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- �݌ɓ���
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���艿
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,pla.attribute15                      AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- ������
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- ������P��
            ,plla.attribute3                      AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,plla.attribute6                      AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- ���ۋ�
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- ���ۋ��z
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gt_next_period_name                  AS period_name            -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- ������s�F�ԕi�i�ʏ�A�g���j
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,xrart.quantity * -1                  AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���P��
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,xrart.line_description               AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gt_next_period_name                  AS period_name            -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- ������s�F�����Ȃ��ԕi�i�ʏ�A�g���j
      SELECT NULL                                 AS status_code            -- �X�e�[�^�X�R�[�h
            ,NULL                                 AS status_name            -- �X�e�[�^�X
            ,NULL                                 AS order_type_code        -- �����敪�R�[�h
            ,NULL                                 AS order_type_name        -- �����敪��
            ,NULL                                 AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,xrart.location_code                  AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,xrart.drop_ship_type                 AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,NULL                                 AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,NULL                                 AS order_approved_flg     -- ���������t���O
            ,NULL                                 AS order_approved_date    -- �����������t
            ,NULL                                 AS purchase_approved_flg  -- �d�������t���O
            ,NULL                                 AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,NULL                                 AS order_dept_code        -- ��������
            ,NULL                                 AS order_dept_name        -- ����������
            ,NULL                                 AS req_dept_code          -- �˗�����
            ,NULL                                 AS req_dept_code          -- �˗�������
            ,xrart.delivery_code                  AS deliver_to             -- �z����
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- �z���於
            ,xrart.header_description             AS header_description     -- �E�v
            ,xrart.rcv_rtn_line_number            AS line_num               -- ���הԍ�
            ,xrart.item_code                      AS item_no                -- �i��
            ,xim2v.item_short_name                AS item_name              -- �i�ږ���
            ,xrart.futai_code                     AS incidental_code        -- �t�уR�[�h
            ,xrart.factory_code                   AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,NULL                                 AS order_quantity         -- ��������
            ,NULL                                 AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,xrart.rcv_rtn_uom                    AS order_uom              -- �����P��
            ,xrart.unit_price                     AS purchase_price         -- �d���P��
            ,NULL                                 AS quantity_fix_flag      -- ���ʊm��t���O
            ,NULL                                 AS amount_fix_flag        -- ���z�m��t���O
            ,NULL                                 AS cancel_flag            -- ����t���O
            ,NULL                                 AS fix_date               -- ���t�w��
            ,line_description                     AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,NULL                                 AS moto_item_code         -- ���i��
            ,NULL                                 AS moto_item_name         -- ���i�ږ���
            ,NULL                                 AS moto_lot_name          -- �����b�gNo
            ,NULL                                 AS purchace_type_code     -- �d���`�ԃR�[�h
            ,NULL                                 AS purchace_type_name     -- �d���`��
            ,NULL                                 AS tea_kbn_code           -- �����敪�R�[�h
            ,NULL                                 AS tea_kbn_name           -- �����敪
            ,NULL                                 AS type_code              -- �^�C�v�R�[�h
            ,NULL                                 AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,xrart.kousen_price                   AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,gt_next_period_name                  AS gt_next_period_name    -- ��v����
            ,cv_data_type_0                       AS data_type              -- �f�[�^�^�C�v('0':����A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi����
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,po_vendor_sites_all      pvsa_deliver      -- �d����T�C�g�i�z����j
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- �d����T�C�g�A�h�I���i�z����j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,xxcmn_item_mst2_v        xim2v             -- OPM�i�ڏ��VIEW
            ,ap_invoices_all          aia               -- AP�������w�b�_
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- ������s�F����i���A�g���j
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- �݌ɓ���
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���艿
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,pla.attribute15                      AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- ������
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- ������P��
            ,plla.attribute3                      AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,plla.attribute6                      AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- ���ۋ�
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- ���ۋ��z
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,xpwc.period_name                     AS period_name            -- ��v����
            ,cv_data_type_1                       AS data_type              -- �f�[�^�^�C�v('1':���A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
            ,xxcfo_po_wait_coop       xpwc              -- �d�����ю�����A�g�e�[�u��
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      UNION
      -- ������s�F�ԕi�i���A�g���j
      SELECT pha.attribute1                       AS status_code            -- �X�e�[�^�X�R�[�h
            ,flv_po_sts.meaning                   AS status_name            -- �X�e�[�^�X
            ,pha.attribute11                      AS order_type_code        -- �����敪�R�[�h
            ,flv_po_type.meaning                  AS order_type_name        -- �����敪��
            ,pha.segment1                         AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,pha.attribute5                       AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,pha.attribute6                       AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,pha.attribute2                       AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,xha.order_approved_flg               AS order_approved_flg     -- ���������t���O
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- �����������t
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- �d�������t���O
            ,TO_CHAR(xha.purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,pha.attribute10                      AS order_dept_code        -- ��������
            ,xl2v_order.location_short_name       AS order_dept_name        -- ����������
            ,xha.Requested_department_code        AS req_dept_code          -- �˗�����
            ,xl2v_request.location_short_name     AS req_dept_code          -- �˗�������
            ,pha.attribute7                       AS deliver_to             -- �z����
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- �z���於
            ,pha.attribute15                      AS header_description     -- �E�v
            ,pla.line_num                         AS line_num               -- ���הԍ�
            ,xim2v_po.item_no                     AS item_no                -- �i��
            ,xim2v_po.item_short_name             AS item_name              -- �i�ږ���
            ,pla.attribute3                       AS incidental_code        -- �t�уR�[�h
            ,pla.attribute2                       AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,xrart.quantity * -1                  AS order_quantity         -- ��������
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,pla.attribute10                      AS order_uom              -- �����P��
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- �d���艿
            ,pla.attribute13                      AS quantity_fix_flag      -- ���ʊm��t���O
            ,pla.attribute14                      AS amount_fix_flag        -- ���z�m��t���O
            ,pla.cancel_flag                      AS cancel_flag            -- ����t���O
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- ���t�w��
            ,xrart.line_description               AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,plla.attribute10                     AS moto_item_code         -- ���i��
            ,xim2v_moto.item_short_name           AS moto_item_name         -- ���i�ږ���
            ,plla.attribute11                     AS moto_lot_name          -- �����b�gNo
            ,ilm.attribute9                       AS purchace_type_code     -- �d���`�ԃR�[�h
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- �d���`��
            ,ilm.attribute10                      AS tea_kbn_code           -- �����敪�R�[�h
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- �����敪
            ,ilm.attribute13                      AS type_code              -- �^�C�v�R�[�h
            ,flv_type.meaning                     AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,xpwc.period_name                     AS period_name            -- ��v����
            ,cv_data_type_1                       AS data_type              -- �f�[�^�^�C�v('1':���A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi���уA�h�I��
            ,po_headers_all           pha               -- �����w�b�_
            ,xxpo_headers_all         xha               -- �����w�b�_�A�h�I��
            ,po_lines_all             pla               -- ��������
            ,po_line_locations_all    plla              -- �����[������
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM�i�ڏ��VIEW�i�����i�ځj
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM�i�ڏ��VIEW�i���i�ځj
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,xxcmn_locations2_v       xl2v_order        -- ���Ə����VIEW�i���������j
            ,xxcmn_locations2_v       xl2v_request      -- ���Ə����VIEW�i�˗������j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_po_type       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_po_sts        -- �N�C�b�N�R�[�h�i�X�e�[�^�X�j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_purchase_kbn  -- �N�C�b�N�R�[�h�i�d���`�ԁj
            ,fnd_lookup_values        flv_tea_kbn       -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_type          -- �N�C�b�N�R�[�h�i�^�C�v�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,ap_invoices_all          aia               -- AP�������w�b�_
            ,xxcfo_po_wait_coop       xpwc              -- �d�����ю�����A�g�e�[�u��
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      UNION
      -- ������s�F�����Ȃ��ԕi�i���A�g���j
      SELECT NULL                                 AS status_code            -- �X�e�[�^�X�R�[�h
            ,NULL                                 AS status_name            -- �X�e�[�^�X
            ,NULL                                 AS order_type_code        -- �����敪�R�[�h
            ,NULL                                 AS order_type_name        -- �����敪��
            ,NULL                                 AS po_header_number       -- ����No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- �����
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- ����於
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- �[����
            ,xrart.location_code                  AS supply_to              -- �[����
            ,mil.description                      AS supply_to_name         -- �[���於
            ,xrart.drop_ship_type                 AS drop_ship_code         -- �����敪�R�[�h
            ,flv_drop_ship.meaning                AS drop_ship_name         -- �����敪��
            ,NULL                                 AS vend_approved_req_flg  -- �d���揳���v���t���O
            ,NULL                                 AS order_approved_flg     -- ���������t���O
            ,NULL                                 AS order_approved_date    -- �����������t
            ,NULL                                 AS purchase_approved_flg  -- �d�������t���O
            ,NULL                                 AS purchase_approved_date -- �d���������t
            ,xv2v_mediator.segment1               AS mediator_code          -- ������
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- �����Җ�
            ,NULL                                 AS order_dept_code        -- ��������
            ,NULL                                 AS order_dept_name        -- ����������
            ,NULL                                 AS req_dept_code          -- �˗�����
            ,NULL                                 AS req_dept_code          -- �˗�������
            ,xrart.delivery_code                  AS deliver_to             -- �z����
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- �z���於
            ,xrart.header_description             AS header_description     -- �E�v
            ,xrart.rcv_rtn_line_number            AS line_num               -- ���הԍ�
            ,xrart.item_code                      AS item_no                -- �i��
            ,xim2v.item_short_name                AS item_name              -- �i�ږ���
            ,xrart.futai_code                     AS incidental_code        -- �t�уR�[�h
            ,xrart.factory_code                   AS factory_code           -- �H��R�[�h
            ,xvsa_factory.vendor_site_short_name  AS factory_name           -- �H�ꖼ
            ,ilm.lot_no                           AS lot_no                 -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- �ܖ�����
            ,ilm.attribute2                       AS unique_symbol          -- �ŗL�L��
            ,xrart.conversion_factor              AS package_quantity       -- �݌ɓ���
            ,NULL                                 AS order_quantity         -- ��������
            ,NULL                                 AS shipment_quntity       -- �d����o�א���
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- �������
            ,xrart.rcv_rtn_uom                    AS order_uom              -- �����P��
            ,xrart.unit_price                     AS purchase_price         -- �d���P��
            ,NULL                                 AS quantity_fix_flag      -- ���ʊm��t���O
            ,NULL                                 AS amount_fix_flag        -- ���z�m��t���O
            ,NULL                                 AS cancel_flag            -- ����t���O
            ,NULL                                 AS fix_date               -- ���t�w��
            ,xrart.line_description               AS line_description       -- ���דE�v
            ,ilm.attribute11                      AS financial_year         -- �N�x
            ,ilm.attribute12                      AS habitat_code           -- �Y�n�R�[�h
            ,flv_habitat.meaning                  AS habitat_name           -- �Y�n
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- �����H��
            ,ilm.attribute21                      AS product_lot_no         -- �������b�gNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- �݌ɒP��
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- �W������
            ,NULL                                 AS moto_item_code         -- ���i��
            ,NULL                                 AS moto_item_name         -- ���i�ږ���
            ,NULL                                 AS moto_lot_name          -- �����b�gNo
            ,NULL                                 AS purchace_type_code     -- �d���`�ԃR�[�h
            ,NULL                                 AS purchace_type_name     -- �d���`��
            ,NULL                                 AS tea_kbn_code           -- �����敪�R�[�h
            ,NULL                                 AS tea_kbn_name           -- �����敪
            ,NULL                                 AS type_code              -- �^�C�v�R�[�h
            ,NULL                                 AS type_name              -- �^�C�v
            ,xrart.kobiki_rate                    AS kobiki_rate            -- ������
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- ������P��
            ,xrart.kousen_type                    AS kousen_code            -- ���K�敪�R�[�h
            ,flv_kousen.meaning                   AS kousen_name            -- ���K�敪
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- ���K
            ,xrart.kousen_price                   AS receipt_kousen         -- �a����K�z
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- ���ۋ��敪�R�[�h
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- ���ۋ��敪
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- ���ۋ�
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- ���ۋ��z
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- ��������z
            ,xrart.invoice_num                    AS invoice_number         -- �������ԍ�
            ,aia.doc_sequence_value               AS invoice_doc_number     -- ���������ԍ�
            ,xrart.journal_key                    AS je_key                 -- �d��L�[
            ,xrart.txns_id                        AS txns_id                -- ���ID
            ,gv_transfer_date                     AS interface_datetime     -- �A�g����
            ,xpwc.period_name                     AS period_name            -- ��v����
            ,cv_data_type_1                       AS data_type              -- �f�[�^�^�C�v('1':���A�g��)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- ����ԕi����
            ,ic_lots_mst              ilm               -- OPM���b�g�}�X�^
            ,xxcmn_vendors2_v         xv2v_vendor       -- �d������VIEW�i�����j
            ,xxcmn_vendors2_v         xv2v_mediator     -- �d������VIEW�i�����ҁj
            ,mtl_item_locations       mil               -- OPM�ۊǏꏊ�}�X�^
            ,po_vendor_sites_all      pvsa_deliver      -- �d����T�C�g�i�z����j
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- �d����T�C�g�A�h�I���i�z����j
            ,po_vendor_sites_all      pvsa_factory      -- �d����T�C�g�i�H��j
            ,xxcmn_vendor_sites_all   xvsa_factory      -- �d����T�C�g�A�h�I���i�H��j
            ,fnd_lookup_values        flv_drop_ship     -- �N�C�b�N�R�[�h�i�����敪�j
            ,fnd_lookup_values        flv_habitat       -- �N�C�b�N�R�[�h�i�Y�n�j
            ,fnd_lookup_values        flv_kousen        -- �N�C�b�N�R�[�h�i���K�敪�j
            ,fnd_lookup_values        flv_fukakin       -- �N�C�b�N�R�[�h�i���ۋ��敪�j
            ,xxcmn_item_mst2_v        xim2v             -- OPM�i�ڏ��VIEW
            ,ap_invoices_all          aia               -- AP�������w�b�_
            ,xxcfo_po_wait_coop       xpwc              -- �d�����ю�����A�g�e�[�u��
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      ORDER BY 81
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
      --�J�[�\���I�[�v��
      OPEN get_manual_cur;
      <<get_manual_loop>>
      LOOP
        FETCH get_manual_cur INTO g_data_tab(1)  -- �X�e�[�^�X�R�[�h
                                 ,g_data_tab(2)  -- �X�e�[�^�X��
                                 ,g_data_tab(3)  -- �����敪�R�[�h
                                 ,g_data_tab(4)  -- �����敪��
                                 ,g_data_tab(5)  -- ����No.
                                 ,g_data_tab(6)  -- �����R�[�h
                                 ,g_data_tab(7)  -- ����於
                                 ,g_data_tab(8)  -- �[����
                                 ,g_data_tab(9)  -- �[����R�[�h
                                 ,g_data_tab(10) -- �[���於
                                 ,g_data_tab(11) -- �����敪�R�[�h
                                 ,g_data_tab(12) -- �����敪��
                                 ,g_data_tab(13) -- �d���揳���v���t���O
                                 ,g_data_tab(14) -- ���������t���O
                                 ,g_data_tab(15) -- �����������t
                                 ,g_data_tab(16) -- �d�������t���O
                                 ,g_data_tab(17) -- �d���������t
                                 ,g_data_tab(18) -- �����҃R�[�h
                                 ,g_data_tab(19) -- �����Җ�
                                 ,g_data_tab(20) -- ���������R�[�h
                                 ,g_data_tab(21) -- ����������
                                 ,g_data_tab(22) -- �˗������R�[�h
                                 ,g_data_tab(23) -- �˗�������
                                 ,g_data_tab(24) -- �z����R�[�h
                                 ,g_data_tab(25) -- �z���於
                                 ,g_data_tab(26) -- �E�v
                                 ,g_data_tab(27) -- ���הԍ�
                                 ,g_data_tab(28) -- �i�ڃR�[�h
                                 ,g_data_tab(29) -- �i�ږ���
                                 ,g_data_tab(30) -- �t�уR�[�h
                                 ,g_data_tab(31) -- �H��R�[�h
                                 ,g_data_tab(32) -- �H�ꖼ
                                 ,g_data_tab(33) -- ���b�gNo
                                 ,g_data_tab(34) -- �����N����
                                 ,g_data_tab(35) -- �ܖ�����
                                 ,g_data_tab(36) -- �ŗL�L��
                                 ,g_data_tab(37) -- �݌ɓ���
                                 ,g_data_tab(38) -- ��������
                                 ,g_data_tab(39) -- �d����o�א���
                                 ,g_data_tab(40) -- �������
                                 ,g_data_tab(41) -- �����P��
                                 ,g_data_tab(42) -- �d���艿
                                 ,g_data_tab(43) -- ���ʊm��t���O
                                 ,g_data_tab(44) -- ���z�m��t���O
                                 ,g_data_tab(45) -- ����t���O
                                 ,g_data_tab(46) -- ���t�w��
                                 ,g_data_tab(47) -- ���דE�v
                                 ,g_data_tab(48) -- �N�x
                                 ,g_data_tab(49) -- �Y�n�R�[�h
                                 ,g_data_tab(50) -- �Y�n
                                 ,g_data_tab(51) -- �����N1
                                 ,g_data_tab(52) -- �����N2
                                 ,g_data_tab(53) -- �����N3
                                 ,g_data_tab(54) -- �����H�ꖼ
                                 ,g_data_tab(55) -- �������b�gNo.
                                 ,g_data_tab(56) -- �݌ɒP��
                                 ,g_data_tab(57) -- �W���P��
                                 ,g_data_tab(58) -- ���i�ڃR�[�h
                                 ,g_data_tab(59) -- ���i�ږ���
                                 ,g_data_tab(60) -- �����b�gNo
                                 ,g_data_tab(61) -- �d���`�ԃR�[�h
                                 ,g_data_tab(62) -- �d���`�Ԗ�
                                 ,g_data_tab(63) -- �����敪�R�[�h
                                 ,g_data_tab(64) -- �����敪��
                                 ,g_data_tab(65) -- �^�C�v�R�[�h
                                 ,g_data_tab(66) -- �^�C�v��
                                 ,g_data_tab(67) -- ������
                                 ,g_data_tab(68) -- ������P��
                                 ,g_data_tab(69) -- ���K�敪�R�[�h
                                 ,g_data_tab(70) -- ���K�敪��
                                 ,g_data_tab(71) -- ���K
                                 ,g_data_tab(72) -- �a����K�z
                                 ,g_data_tab(73) -- ���ۋ��敪�R�[�h
                                 ,g_data_tab(74) -- ���ۋ��敪��
                                 ,g_data_tab(75) -- ���ۋ�
                                 ,g_data_tab(76) -- ���ۋ��z
                                 ,g_data_tab(77) -- ��������z
                                 ,g_data_tab(78) -- �������ԍ�
                                 ,g_data_tab(79) -- ���������ԍ�
                                 ,g_data_tab(80) -- �d��L�[
                                 ,g_data_tab(81) -- ���ID
                                 ,g_data_tab(82) -- �A�g����
                                 ,g_data_tab(83) -- ��v����
                                 ,g_data_tab(84) -- �f�[�^�^�C�v
                                 ;
        EXIT WHEN get_manual_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
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
          --���A�g�e�[�u���o�^����(A-8)
          --==============================================================
          -- �蓮�Ȃ̂œo�^�͂��Ȃ��BA-6�Ŏ擾�����G���[���O�o�͏����̂݁B
          ins_wait_coop(
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
          RAISE global_process_expt;
--
        END IF;
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
      --�J�[�\���I�[�v��
      OPEN get_fixed_period_cur;
      <<get_fixed_period_loop>>
      LOOP
        FETCH get_fixed_period_cur INTO g_data_tab(1)  -- �X�e�[�^�X�R�[�h
                                       ,g_data_tab(2)  -- �X�e�[�^�X��
                                       ,g_data_tab(3)  -- �����敪�R�[�h
                                       ,g_data_tab(4)  -- �����敪��
                                       ,g_data_tab(5)  -- ����No.
                                       ,g_data_tab(6)  -- �����R�[�h
                                       ,g_data_tab(7)  -- ����於
                                       ,g_data_tab(8)  -- �[����
                                       ,g_data_tab(9)  -- �[����R�[�h
                                       ,g_data_tab(10) -- �[���於
                                       ,g_data_tab(11) -- �����敪�R�[�h
                                       ,g_data_tab(12) -- �����敪��
                                       ,g_data_tab(13) -- �d���揳���v���t���O
                                       ,g_data_tab(14) -- ���������t���O
                                       ,g_data_tab(15) -- �����������t
                                       ,g_data_tab(16) -- �d�������t���O
                                       ,g_data_tab(17) -- �d���������t
                                       ,g_data_tab(18) -- �����҃R�[�h
                                       ,g_data_tab(19) -- �����Җ�
                                       ,g_data_tab(20) -- ���������R�[�h
                                       ,g_data_tab(21) -- ����������
                                       ,g_data_tab(22) -- �˗������R�[�h
                                       ,g_data_tab(23) -- �˗�������
                                       ,g_data_tab(24) -- �z����R�[�h
                                       ,g_data_tab(25) -- �z���於
                                       ,g_data_tab(26) -- �E�v
                                       ,g_data_tab(27) -- ���הԍ�
                                       ,g_data_tab(28) -- �i�ڃR�[�h
                                       ,g_data_tab(29) -- �i�ږ���
                                       ,g_data_tab(30) -- �t�уR�[�h
                                       ,g_data_tab(31) -- �H��R�[�h
                                       ,g_data_tab(32) -- �H�ꖼ
                                       ,g_data_tab(33) -- ���b�gNo
                                       ,g_data_tab(34) -- �����N����
                                       ,g_data_tab(35) -- �ܖ�����
                                       ,g_data_tab(36) -- �ŗL�L��
                                       ,g_data_tab(37) -- �݌ɓ���
                                       ,g_data_tab(38) -- ��������
                                       ,g_data_tab(39) -- �d����o�א���
                                       ,g_data_tab(40) -- �������
                                       ,g_data_tab(41) -- �����P��
                                       ,g_data_tab(42) -- �d���艿
                                       ,g_data_tab(43) -- ���ʊm��t���O
                                       ,g_data_tab(44) -- ���z�m��t���O
                                       ,g_data_tab(45) -- ����t���O
                                       ,g_data_tab(46) -- ���t�w��
                                       ,g_data_tab(47) -- ���דE�v
                                       ,g_data_tab(48) -- �N�x
                                       ,g_data_tab(49) -- �Y�n�R�[�h
                                       ,g_data_tab(50) -- �Y�n
                                       ,g_data_tab(51) -- �����N1
                                       ,g_data_tab(52) -- �����N2
                                       ,g_data_tab(53) -- �����N3
                                       ,g_data_tab(54) -- �����H�ꖼ
                                       ,g_data_tab(55) -- �������b�gNo.
                                       ,g_data_tab(56) -- �݌ɒP��
                                       ,g_data_tab(57) -- �W���P��
                                       ,g_data_tab(58) -- ���i�ڃR�[�h
                                       ,g_data_tab(59) -- ���i�ږ���
                                       ,g_data_tab(60) -- �����b�gNo
                                       ,g_data_tab(61) -- �d���`�ԃR�[�h
                                       ,g_data_tab(62) -- �d���`�Ԗ�
                                       ,g_data_tab(63) -- �����敪�R�[�h
                                       ,g_data_tab(64) -- �����敪��
                                       ,g_data_tab(65) -- �^�C�v�R�[�h
                                       ,g_data_tab(66) -- �^�C�v��
                                       ,g_data_tab(67) -- ������
                                       ,g_data_tab(68) -- ������P��
                                       ,g_data_tab(69) -- ���K�敪�R�[�h
                                       ,g_data_tab(70) -- ���K�敪��
                                       ,g_data_tab(71) -- ���K
                                       ,g_data_tab(72) -- �a����K�z
                                       ,g_data_tab(73) -- ���ۋ��敪�R�[�h
                                       ,g_data_tab(74) -- ���ۋ��敪��
                                       ,g_data_tab(75) -- ���ۋ�
                                       ,g_data_tab(76) -- ���ۋ��z
                                       ,g_data_tab(77) -- ��������z
                                       ,g_data_tab(78) -- �������ԍ�
                                       ,g_data_tab(79) -- ���������ԍ�
                                       ,g_data_tab(80) -- �d��L�[
                                       ,g_data_tab(81) -- ���ID
                                       ,g_data_tab(82) -- �A�g����
                                       ,g_data_tab(83) -- ��v����
                                       ,g_data_tab(84) -- �f�[�^�^�C�v
                                       ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
--
        -- ������������
        IF ( g_data_tab(84) = cv_data_type_0 ) THEN
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
          --==============================================================
          --���A�g�e�[�u���o�^����(A-8)
          --==============================================================
          -- ���A�g�e�[�u���o�^����(A-8)�A�A���A�X�L�b�v�t���O��ON(��1)�̏ꍇ��
          -- ���A�g�e�[�u���ɂ͓o�^���Ȃ�(���O�̏o�͂���)�B
          -- (��1)�@���A�g�e�[�u���Ƀf�[�^������ꍇ�A�A�����G���[�����������ꍇ
          ins_wait_coop(
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
          RAISE global_process_expt;
--
        END IF;
      END LOOP get_fixed_period_loop;
--
      CLOSE get_fixed_period_cur;
--
      -- �����Ώۃf�[�^�����݂��Ȃ��ꍇ
      IF ( ( gn_target_cnt = 0 ) AND ( gn_target_wait_cnt = 0 ) ) THEN
        RAISE get_data_expt;
--
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�擾��O�n���h�� ***
    WHEN get_data_expt THEN
      -- [ ��GET_DATA ] �Ώۃf�[�^������܂���ł����B
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => gv_msg_po_info  -- �d�����ю�����
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
   * Procedure Name   : del_wait_coop
   * Description      : ���A�g�f�[�^�폜����(A-9)
   ***********************************************************************************/
  PROCEDURE del_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_wait_coop'; -- �v���O������
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
          DELETE FROM xxcfo_po_wait_coop xpwc -- �d�����ю�����A�g�e�[�u��
          WHERE xpwc.rowid = g_row_id_tab( i )
          AND   xpwc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- ��TABLE �̃f�[�^�폜�Ɏ��s���܂����B
            -- �G���[���e�F ��ERRMSG
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name    -- XXCFO
                                     ,cv_msg_cfo_00025      -- �f�[�^�폜�G���[
                                     ,cv_tkn_table          -- �g�[�N��'TABLE'
                                     ,gv_tbl_nm_wait_coop   -- �d�����ю�����A�g�e�[�u��
                                     ,cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                                     ,SQLERRM               -- SQL�G���[���b�Z�[�W
                                    )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP delete_loop;
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
  END del_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_mfg_txn_control
   * Description      : �Ǘ��e�[�u���X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE upd_mfg_txn_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_txn_control'; -- �v���O������
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
      -- ���Y����A�g�Ǘ��e�[�u��
      --==============================================================
--
    -- ������s�A���A����v���Ԃ̃f�[�^�����������ꍇ�̂ݍX�V
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( gn_target_cnt > 0 ) ) THEN
--
      BEGIN
--
        UPDATE xxcfo_mfg_txn_if_control  xmtic                       -- ���Y����A�g�Ǘ��e�[�u��
        SET xmtic.period_name            = gt_next_period_name       -- ��v����
           ,xmtic.last_update_date       = SYSDATE                   -- �ŏI�X�V��
           ,xmtic.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,xmtic.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,xmtic.request_id             = cn_request_id             -- �v��ID
           ,xmtic.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,xmtic.program_id             = cn_program_id             -- �v���O����ID
           ,xmtic.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE xmtic.set_of_books_id      = gn_set_of_bks_id
        AND   xmtic.program_name         = cv_pkg_name
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ��TABLE �̃f�[�^�X�V�Ɏ��s���܂����B
          -- �G���[���e�F ��ERRMSG
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name       -- XXCFO
                                                         ,cv_msg_cfo_00020         -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table             -- �g�[�N��'TABLE'
                                                         ,gv_tbl_nm_mfg_txn_ctl    -- ���Y����A�g�Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg            -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM                  -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
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
  END upd_mfg_txn_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name             IN  VARCHAR2,  -- 1.�t�@�C����
    iv_period_name           IN  VARCHAR2,  -- 2.��v����
    iv_exec_kbn              IN  VARCHAR2,  -- 3.����蓮�敪
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
      iv_file_name             => iv_file_name,    -- 1.�t�@�C����
      iv_period_name           => iv_period_name,  -- 2.��v����
      iv_exec_kbn              => iv_exec_kbn,     -- 3.����蓮�敪
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
    get_wait_coop(
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
    get_mfg_txn_control(
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
      NULL;
--
    ELSE
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
      --================================
      --���A�g�e�[�u���폜����(A-9)
      --================================
      del_wait_coop(
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
      upd_mfg_txn_control(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
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
    iv_file_name             IN  VARCHAR2,    -- 1.�t�@�C����
    iv_period_name           IN  VARCHAR2,    -- 2.��v����
    iv_exec_kbn              IN  VARCHAR2     -- 3.����蓮�敪
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
       iv_file_name       -- 1.�t�@�C����
      ,iv_period_name     -- 2.��v����
      ,iv_exec_kbn        -- 3.����蓮�敪
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCFO021A03C;
/
