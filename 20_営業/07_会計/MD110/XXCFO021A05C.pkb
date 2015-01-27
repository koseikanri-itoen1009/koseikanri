CREATE OR REPLACE PACKAGE BODY XXCFO021A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO021A05C(body)
 * Description      : �d�q����󕥎��(�o��)�̏��n�V�X�e���A�g
 * MD.050           : �d�q����󕥎��(�o��)�̏��n�V�X�e���A�g <MD050_CFO_021_A05>
 * Version          : 1.0
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
 *  upd_fa_control         �Ǘ��e�[�u���X�V����(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-24    1.0   A.Uchida         �V�K�쐬
 *  2015-01-16    1.1   A.Uchida         �V�X�e���e�X�g��Q�Ή�
 *                                       �p�[�e�B�T�C�g�r���[�̌��������ɃX�e�[�^�X��ǉ�
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO021A05C'; -- �p�b�P�[�W��
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
--
  -- ���b�Z�[�W(�g�[�N��)
  cv_msg_cfo_11123            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11123';   -- ���{�ꕶ����(�u�󕥎���i�o�ׁj���A�g�e�[�u���v)
  cv_msg_cfo_11124            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11124';   -- ���{�ꕶ����(�u���Y����A�g�Ǘ��e�[�u���v)
  cv_msg_cfo_11125            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11125';   -- ���{�ꕶ����(�u��v���ԁv)
  cv_msg_cfo_11126            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11126';   -- ���{�ꕶ����(�u�󒍃w�b�_�A�h�I��ID�v)
  cv_msg_cfo_11127            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11127';   -- ���{�ꕶ����(�u�󒍖��׃A�h�I��ID�v)
  cv_msg_cfo_11128            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11128';   -- ���{�ꕶ����(�u�i�ڃR�[�h�v)
  cv_msg_cfo_11129            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11129';   -- ���{�ꕶ����(�u�w���^���ы敪�v)
  cv_msg_cfo_11130            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11130';   -- ���{�ꕶ����(�u���b�gNo�v)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';   -- ���{�ꕶ����(�u�A�v)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   -- ���{�ꕶ����(�u���ڂ��s���v)
  cv_msg_cfo_11131            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11131';   -- ���{�ꕶ����(�u�󕥎���i�o�ׁj���v)
  cv_msg_cfo_11132            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11132';   -- ���{�ꕶ����(�u���Y�V�X�e���v�j
  cv_msg_cfo_11133            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11133';   -- ���{�ꕶ����(�u�󕥁i�o�ׁj�v�j
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
  cv_lookup_item_chk_ship    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_SHIP';       --�d�q���덀�ڃ`�F�b�N�i�󕥎���i�o�ׁj�j
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                                  -- �t���O�lY
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                                  -- �t���O�lN
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                                  -- �X���b�V��
--
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- �d�q����󕥎���i�o�ׁj�f�[�^�t�@�C���i�[�p�X
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- ��v����ID
  cv_mfg_org_id               CONSTANT VARCHAR2(100) := 'XXCFO1_MFG_ORG_ID';                  -- ���Y�V�X�e��ORG_ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SHIP_DATA_FILENAME'; -- �d�q����󕥎���i�o�ׁj�f�[�^�t�@�C����
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
  gv_tbl_nm_wait_coop         VARCHAR2(50);    -- ���{�ꕶ����(�u�󕥎���i�o�ׁj���A�g�e�[�u���v)
  gv_tbl_nm_mfg_txn_ctl       VARCHAR2(50);    -- ���{�ꕶ����(�u���Y����A�g�Ǘ��e�[�u���v)
  gv_col_nm_period_name       VARCHAR2(50);    -- ���{�ꕶ����(�u��v���ԁv)
  gv_col_nm_order_header_id   VARCHAR2(50);    -- ���{�ꕶ����(�u�󒍃w�b�_�A�h�I��ID�v)
  gv_col_nm_order_line_id     VARCHAR2(50);    -- ���{�ꕶ����(�u�󒍖��׃A�h�I��ID�v)
  gv_col_nm_item_code         VARCHAR2(50);    -- ���{�ꕶ����(�u�i�ڃR�[�h�v)
  gv_col_nm_rec_type          VARCHAR2(50);    -- ���{�ꕶ����(�u�w���^���ы敪�v)
  gv_col_nm_lot_num           VARCHAR2(50);    -- ���{�ꕶ����(�u���b�gNo�v)
  gv_msg_shipment_info        VARCHAR2(50);    -- ���{�ꕶ����(�u�󕥎���i�o�ׁj���v)
  gv_je_source_mfg            VARCHAR2(50);    -- ���{�ꕶ����(�u���Y�V�X�e���v)
  gv_je_category_shipment     VARCHAR2(50);    -- ���{�ꕶ����(�u�󕥁i�o�ׁj�v)
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
    -- �󕥎��(�o��)���A�g�f�[�^(�����)
    CURSOR get_wait_coop_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_shipment_wait_coop xswc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    -- �󕥎��(�o��)���A�g�f�[�^(�蓮��)
    CURSOR get_wait_coop_m_cur
    IS
      SELECT period_name       AS period_name
            ,order_header_id   AS order_header_id
            ,order_line_id     AS order_line_id
            ,item_code         AS item_code
            ,record_type_code  AS record_type_code
            ,lot_no            AS lot_no
      FROM   xxcfo_shipment_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <�󕥎��(�o��)���A�g�e�[�u��>�e�[�u���^
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_ship
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
      lt_lookup_type    :=  cv_lookup_item_chk_ship;
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
      -- �d�q����󕥎���i�o�ׁj�f�[�^�ǉ��t�@�C����
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
    gv_tbl_nm_wait_coop := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11123     -- ���b�Z�[�W�R�[�h
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
    gv_col_nm_order_header_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11126     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_order_line_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11127     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_item_code := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11128     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_rec_type := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11129     -- ���b�Z�[�W�R�[�h
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_lot_num := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11130     -- ���b�Z�[�W�R�[�h
                                      )
                               , 1
                               , 5000
                               );
--
    gv_msg_shipment_info := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11131     -- ���b�Z�[�W�R�[�h
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
    gv_je_category_shipment := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                      ,iv_name        => cv_msg_cfo_11133     -- ���b�Z�[�W�R�[�h
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
        iv_token_value1       => gv_tbl_nm_wait_coop    -- �󕥎���i�o�ׁj���A�g�e�[�u��
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
    -- �󕥎���i�o�ׁj�Ǘ��Ǘ��e�[�u��(���b�N����)
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
    cv_max_mixed_ratio        CONSTANT VARCHAR2(6) := '999.99';
    cv_max_small_quantity     CONSTANT VARCHAR2(6) := '999999';
    cv_max_label_quantity     CONSTANT VARCHAR2(6) := '999999';
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
        IF ( g_data_tab(2)  = g_wait_coop_m_rec(i).order_header_id   -- �󒍃w�b�_�A�h�I��ID
         AND g_data_tab(3)  = g_wait_coop_m_rec(i).order_line_id     -- �󒍖��׃A�h�I��ID
         AND g_data_tab(43) = g_wait_coop_m_rec(i).item_code         -- �i�ڃR�[�h
         AND g_data_tab(80) = g_wait_coop_m_rec(i).record_type_code  -- �w���^���ы敪
         AND g_data_tab(81) = g_wait_coop_m_rec(i).lot_no              ) THEN
          -- �X�L�b�v�t���O��ON(�@A-7�FCSV�o�́A�AA-8�F���A�g�e�[�u���o�^���X�L�b�v)
          ov_skipflg := cv_flag_y;
--
          -- �����M�̃f�[�^�ł��B( ��DOC_DATA = ��DOC_DIST_ID )
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10010                                  -- ���A�g�f�[�^�`�F�b�NID�G���[
                                 ,cv_tkn_doc_data                                   -- �g�[�N��'DOC_DATA'
                                 ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                  gv_col_nm_order_header_id || gv_punctuation_mark ||
                                  gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                  gv_col_nm_item_code       || gv_punctuation_mark ||
                                  gv_col_nm_rec_type        || gv_punctuation_mark ||
                                  gv_col_nm_lot_num                                 -- �L�[���ږ�
                                 ,cv_tkn_doc_dist_id                                -- �g�[�N��'DOC_DIST_ID'
                                 ,g_data_tab(91) || gv_punctuation_mark ||
                                  g_data_tab(2)  || gv_punctuation_mark ||
                                  g_data_tab(3)  || gv_punctuation_mark ||
                                  g_data_tab(43) || gv_punctuation_mark ||
                                  g_data_tab(80) || gv_punctuation_mark ||
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
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(91) ) ) THEN
        -- ���]�L�t���O��OFF
        gb_gl_je_flg := FALSE;
--
        -- ���ݍs�̉�v���Ԃ�ێ�
        gt_period_name_cur := g_data_tab(91);
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
          AND     gjcv.user_je_category_name = gv_je_category_shipment
                                               --  '�󕥁i�o�ׁj'
          AND     gjsv.user_je_source_name   = gv_je_source_mfg      -- �d��\�[�X��(�e���Y�V�X�e���f)
          AND     gjh.actual_flag            = cv_result_flag        -- �eA�f�i���сj
          AND     gjh.status                 = cv_status_p           -- �eP�f�i�]�L�ρj
          AND     gjh.period_name            = g_data_tab(91)        -- A-5�Ŏ擾������v����
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
                                 ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                  gv_col_nm_order_header_id || gv_punctuation_mark ||
                                  gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                  gv_col_nm_item_code       || gv_punctuation_mark ||
                                  gv_col_nm_rec_type        || gv_punctuation_mark ||
                                  gv_col_nm_lot_num                                 -- �L�[���ږ�
                                 ,cv_tkn_key_value                                  -- �g�[�N��'KEY_VALUE'
                                 ,g_data_tab(91) || gv_punctuation_mark ||
                                  g_data_tab(2)  || gv_punctuation_mark ||
                                  g_data_tab(3)  || gv_punctuation_mark ||
                                  g_data_tab(43) || gv_punctuation_mark ||
                                  g_data_tab(80) || gv_punctuation_mark ||
                                  g_data_tab(81)            )                       -- �L�[���ڒl
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
      ELSIF ( ( gt_period_name_cur = g_data_tab(91) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- �d�󖢓]�L���b�Z�[�W
                               ,cv_tkn_key_item           -- �g�[�N��'KEY_ITEM'
                               ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                gv_col_nm_order_header_id || gv_punctuation_mark ||
                                gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                gv_col_nm_item_code       || gv_punctuation_mark ||
                                gv_col_nm_rec_type        || gv_punctuation_mark ||
                                gv_col_nm_lot_num                                 -- �L�[���ږ�
                               ,cv_tkn_key_value          -- �g�[�N��'KEY_VALUE'
                               ,g_data_tab(91) || gv_punctuation_mark ||
                                g_data_tab(2)  || gv_punctuation_mark ||
                                g_data_tab(3)  || gv_punctuation_mark ||
                                g_data_tab(43) || gv_punctuation_mark ||
                                g_data_tab(80) || gv_punctuation_mark ||
                                g_data_tab(81)           )                     -- �L�[���ڒl
                             ,1
                             ,5000);
--
        -- �ȍ~�̌^�^���^�K�{�̃`�F�b�N�͂��Ȃ�
        RAISE warn_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- �^�^���^�K�{�̃`�F�b�N
    --==============================================================
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
      -- �A�g�����ȊO�̓`�F�b�N����
      IF ( ln_cnt <> 90 ) THEN
        -- ���ڗ��A�������A���x�������͌����ӂꎞ�ő�l���Z�b�g
        IF ln_cnt = 75 THEN
          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_mixed_ratio) THEN
            g_data_tab(ln_cnt) := cv_max_mixed_ratio;
          END IF;
--
        ELSIF ln_cnt = 77 THEN
          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_small_quantity) THEN
            g_data_tab(ln_cnt) := cv_max_small_quantity;
          END IF;
--
        ELSIF ln_cnt = 78 THEN
          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_label_quantity) THEN
            g_data_tab(ln_cnt) := cv_max_label_quantity;
          END IF;
--
        END IF;
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
                lv_errmsg               := xxccp_common_pkg.get_msg(
                                             iv_application        => cv_xxcfo_appl_name,
                                             iv_name               => cv_msg_cfo_10011,
                                             iv_token_name1        => cv_tkn_key_data ,
                                             iv_token_value1       => g_data_tab(91) || gv_punctuation_mark ||
                                                                      g_data_tab(2)  || gv_punctuation_mark ||
                                                                      g_data_tab(3)  || gv_punctuation_mark ||
                                                                      g_data_tab(43) || gv_punctuation_mark ||
                                                                      g_data_tab(80) || gv_punctuation_mark ||
                                                                      g_data_tab(81)         ) ;
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
                              , iv_token_value2 => g_data_tab(91) || gv_punctuation_mark ||
                                                   g_data_tab(2)  || gv_punctuation_mark ||
                                                   g_data_tab(3)  || gv_punctuation_mark ||
                                                   g_data_tab(43) || gv_punctuation_mark ||
                                                   g_data_tab(80) || gv_punctuation_mark ||
                                                   g_data_tab(81)  
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
                lv_errmsg               := xxccp_common_pkg.get_msg(
                                             iv_application        => cv_xxcfo_appl_name,
                                             iv_name               => cv_msg_cfo_10011,
                                             iv_token_name1        => cv_tkn_key_data ,
                                             iv_token_value1       => g_data_tab(91) || gv_punctuation_mark ||
                                                                      g_data_tab(2)  || gv_punctuation_mark ||
                                                                      g_data_tab(3)  || gv_punctuation_mark ||
                                                                      g_data_tab(43) || gv_punctuation_mark ||
                                                                      g_data_tab(80) || gv_punctuation_mark ||
                                                                      g_data_tab(81)        ) ;
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
                              , iv_token_value2 => g_data_tab(91) || gv_punctuation_mark ||
                                                   g_data_tab(2)  || gv_punctuation_mark ||
                                                   g_data_tab(3)  || gv_punctuation_mark ||
                                                   g_data_tab(43) || gv_punctuation_mark ||
                                                   g_data_tab(80) || gv_punctuation_mark ||
                                                   g_data_tab(81) 
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
      -- �󕥎���i�o�ׁj���A�g�e�[�u��
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_shipment_wait_coop(
           set_of_books_id        -- ��v����id
          ,period_name            -- ��v����
          ,order_header_id        -- �󒍃w�b�_�A�h�I��ID
          ,order_line_id          -- �󒍖��׃A�h�I��ID
          ,item_code              -- �i�ڃR�[�h
          ,record_type_code       -- �w���^���ы敪
          ,lot_no                 -- ���b�gNo
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
           gn_set_of_bks_id       -- ��v����id
          ,g_data_tab(91)         -- ��v����
          ,g_data_tab(2)          -- �󒍃w�b�_�A�h�I��ID
          ,g_data_tab(3)          -- �󒍖��׃A�h�I��ID
          ,g_data_tab(43)         -- �i�ڃR�[�h
          ,g_data_tab(80)         -- �w���^���ы敪
          ,g_data_tab(81)         -- ���b�gNo
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
                                                         ,gv_tbl_nm_wait_coop   -- �󕥎���i�o�ׁj���A�g�e�[�u��
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
    cv_req_status             CONSTANT VARCHAR2(2)  := '04';       -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_shipping_sikyu_class_1 CONSTANT VARCHAR2(1)  := '1';        -- �o�׎x���敪�F1�i�o�׈˗��j
    cv_shipping_sikyu_class_3 CONSTANT VARCHAR2(1)  := '3';        -- �o�׎x���敪�F3�i�q�֕ԕi�j
    cv_adjs_class_1           CONSTANT VARCHAR2(1)  := '1';        -- �݌ɒ����敪�F1�i�݌ɒ����ȊO�j
    cv_document_type_10       CONSTANT VARCHAR2(2)  := '10';       -- �����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
    cv_order_retrun           CONSTANT VARCHAR2(10) := 'RETURN';   -- �ԕi
    cv_rec_type_cd_10         CONSTANT VARCHAR2(2)  := '10';       -- ���R�[�h�^�C�v�F10�i�w���j
    cv_rec_type_cd_20         CONSTANT VARCHAR2(2)  := '20';       -- ���R�[�h�^�C�v�F20�i�o�׎��сj
    ct_doc_type_omso          CONSTANT ic_tran_pnd.doc_type%TYPE      := 'OMSO';
    ct_doc_type_porc          CONSTANT ic_tran_pnd.doc_type%TYPE      := 'PORC';
    ct_completed_ind_1        CONSTANT ic_tran_pnd.completed_ind%TYPE := 1;
    cv_adjs_class_2           CONSTANT VARCHAR2(1)  := '2';        -- �݌ɒ����敪�F2
    cv_req_status_08          CONSTANT VARCHAR2(2)  := '08';       -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_document_type_30       CONSTANT VARCHAR2(2)  := '30';       -- �����^�C�v(�A�h�I��)�F30�i�x���w���j
    cv_party_site_status_a    CONSTANT VARCHAR2(1)  := 'A';        -- �p�[�e�B�T�C�g�X�e�[�^�X�FA        -- 2015/01/16 Ver1.1 Add
--
    -- ���b�N�A�b�v�^�C�v
    cv_lookup_arrival_time    CONSTANT VARCHAR2(30) := 'XXWSH_ARRIVAL_TIME';
    cv_lookup_ship_method     CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD';
    cv_lookup_wgt_capa_cls    CONSTANT VARCHAR2(30) := 'XXCMN_WEIGHT_CAPACITY_CLASS';
    cv_lookup_trnsfr_fare_std CONSTANT VARCHAR2(30) := 'XXCMN_TRNSFR_FARE_STD';
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
      SELECT /*+ LEADING(xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     otta ooha xola oola wdd itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gv_period_name                               AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id
      AND    itp.doc_type                      = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind                 = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION ALL
      -- �q�֕ԕi
      SELECT /*+ LEADING(xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     otta ooha xola oola rsl itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gv_period_name                               AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute1                   = cv_shipping_sikyu_class_3 --�o�׎x���敪�F3�i�q�֕ԕi�j
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION ALL
      -- ������U�ցi�U�֏o�Ɂj�o��
      SELECT /*+ LEADING(xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     otta ooha xola oola wdd itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gv_period_name                               AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    xoha.req_status                   = cv_req_status_08          --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F30�i�x���w���j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id
      AND    itp.doc_type                      = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind                 = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION ALL
      --������U�ցi�U�֏o�Ɂj�ԕi�󒍁i�����j
      SELECT /*+ LEADING(xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     otta ooha xola oola rsl itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gv_period_name                               AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status_08          --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2           --�݌ɒ����敪�F2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F10�i�x���˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      ORDER BY order_header_id
              ,order_line_id
              ,request_item_code
              ,record_type_code
              ,lot_no
      ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(������s)
    CURSOR get_fixed_period_cur
    IS
      SELECT /*+ LEADING(xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     otta ooha xola oola wdd itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gt_next_period_name                          AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id(+)
      AND    itp.doc_type(+)                   = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind(+)              = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      SELECT /*+ LEADING(xswc xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     xoha otta ooha xola oola wdd itp xmld)   */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,xswc.period_name                             AS period_name              -- ��v����
            ,cv_data_type_1                               AS data_type                -- �f�[�^�^�C�v('1':���A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
            ,xxcfo_shipment_wait_coop    xswc                     --�󕥎���i�o�ׁj���A�g
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status (+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id(+)
      AND    itp.doc_type(+)                   = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind(+)              = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xswc.order_header_id              = xoha.order_header_id   
      AND    xswc.order_line_id                = xola.order_line_id     
      AND    xswc.item_code                    = xola.request_item_code
      AND    xswc.record_type_code             = xmld.record_type_code
      AND    xswc.lot_no                       = ilm.lot_no
      AND    xswc.set_of_books_id              = gn_set_of_bks_id
      UNION ALL
      -- �q�֕ԕi
      SELECT /*+ LEADING(xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     otta ooha xola oola rsl itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gt_next_period_name                          AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute1                   = cv_shipping_sikyu_class_3 --�o�׎x���敪�F3�i�q�֕ԕi�j
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      SELECT /*+ LEADING(xswc xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     xoha otta ooha xola oola rsl itp xmld)  */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,xoha.result_deliver_to                       AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,xswc.period_name                             AS period_name              -- ��v����
            ,cv_data_type_1                               AS data_type                -- �f�[�^�^�C�v('1':���A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
            ,xxcfo_shipment_wait_coop    xswc                     --�󕥎���i�o�ׁj���A�g
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute1                   = cv_shipping_sikyu_class_3 --�o�׎x���敪�F3�i�q�֕ԕi�j
      AND    otta.attribute4                   = cv_adjs_class_1           --�݌ɒ����敪�F1�i�݌ɒ����ȊO�j
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_10  --�����^�C�v(�A�h�I��)�F10�i�o�׈˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xswc.order_header_id              = xoha.order_header_id   
      AND    xswc.order_line_id                = xola.order_line_id     
      AND    xswc.item_code                    = xola.request_item_code
      AND    xswc.record_type_code             = xmld.record_type_code
      AND    xswc.lot_no                       = ilm.lot_no
      AND    xswc.set_of_books_id              = gn_set_of_bks_id
      UNION ALL
      -- ������U�ցi�U�֏o�Ɂj�o��
      SELECT /*+ LEADING(xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     otta ooha xola oola wdd itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gt_next_period_name                          AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status_08          --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2           --�݌ɒ����敪�F2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F30�i�x���˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id(+)
      AND    itp.doc_type(+)                   = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind(+)              = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      -- ������U�ցi�U�֏o�Ɂj�o�ׁ@���A�g��
      SELECT /*+ LEADING(xswc xoha otta ooha xola oola wdd itp xmld) 
                 USE_NL (     xoha otta ooha xola oola wdd itp xmld)  */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,xswc.period_name                             AS period_name              -- ��v����
            ,cv_data_type_1                               AS data_type                -- �f�[�^�^�C�v('1':���A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,wsh_delivery_details        wdd                      -- �o�ה�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
            ,xxcfo_shipment_wait_coop    xswc                     --�󕥎���i�o�ׁj���A�g
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status_08          --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2           --�݌ɒ����敪�F2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)      = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F30�i�x���˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id(+)
      AND    itp.doc_type(+)                   = ct_doc_type_omso               -- �����^�C�v�FOMSO
      AND    itp.completed_ind(+)              = ct_completed_ind_1             -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xswc.order_header_id              = xoha.order_header_id   
      AND    xswc.order_line_id                = xola.order_line_id     
      AND    xswc.item_code                    = xola.request_item_code
      AND    xswc.record_type_code             = xmld.record_type_code
      AND    xswc.lot_no                       = ilm.lot_no
      AND    xswc.set_of_books_id              = gn_set_of_bks_id
      UNION ALL
      --������U�ցi�U�֏o�Ɂj�ԕi�󒍁i�����j�@�A�g��
      SELECT /*+ LEADING(xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     otta ooha xola oola rsl itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,gt_next_period_name                          AS period_name              -- ��v����
            ,cv_data_type_0                               AS data_type                -- �f�[�^�^�C�v('0':����A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status_08             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2           --�݌ɒ����敪�F2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)      = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F30�i�x���˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      --������U�ցi�U�֏o�Ɂj�ԕi�󒍁i�����j�@���A�g��
      SELECT /*+ LEADING(xswc xoha otta ooha xola oola rsl itp xmld) 
                 USE_NL (     xoha otta ooha xola oola rsl itp xmld)
                 INDEX  (xoha XXWSH_OH_N32)             */
             oola.attribute4                              AS je_key                   -- �d��L�[
            ,xoha.order_header_id                         AS order_header_id          -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id                           AS order_line_id            -- �󒍖��׃A�h�I��ID
            ,ottt.name                                    AS ship_tran_type_name      -- �o�Ɍ`�Ԗ�_�o��
            ,xoha.request_no                              AS request_no               -- �˗�No
            ,xoha.req_status                              AS req_status               -- �X�e�[�^�X�R�[�h
            ,xoha.notif_status                            AS notif_status             -- �ʒm�X�e�[�^�X�R�[�h
            ,xoha.head_sales_branch                       AS head_sales_branch_code   -- �Ǌ����_�R�[�h
            ,xca2v_branch.party_name                      AS head_sales_branch_name   -- �Ǌ����_��
            ,xoha.deliver_to                              AS deliver_to               -- �z����R�[�h
            ,NVL(xoha.result_deliver_to,'0')              AS result_deliver_to        -- �z����R�[�h_����
            ,xps2v_deli.party_site_name                   AS deliver_to_name          -- �z���於
            ,xps2v_res_deli.party_site_name               AS result_deliver_to_name   -- �z���於_����
            ,xoha.customer_code                           AS customer_code            -- �ڋq�R�[�h
            ,xca2v_cust.party_short_name                  AS customer_name            -- �ڋq��
            ,xoha.deliver_from                            AS deliver_from             -- �o�Ɍ��R�[�h
            ,mil.description                              AS deliver_from_name        -- �o�Ɍ���
            ,TO_CHAR(xoha.schedule_ship_date
                    ,cv_date_format_ymd)                  AS schedule_ship_date       -- �o�ɗ\���
            ,TO_CHAR(xoha.shipped_date
                    ,cv_date_format_ymd)                  AS shipped_date             -- �o�ɓ�
            ,TO_CHAR(xoha.schedule_arrival_date
                    ,cv_date_format_ymd)                  AS schedule_arrival_date    -- ���ח\���
            ,TO_CHAR(xoha.arrival_date
                    ,cv_date_format_ymd)                  AS arrival_date             -- ����
            ,flv_time_from.meaning                        AS time_from                -- ���Ԏw��FROM
            ,flv_time_to.meaning                          AS time_to                  -- ���Ԏw��TO
            ,xoha.delivery_no                             AS delivery_no              -- �z��No
            ,xoha.freight_charge_class                    AS freight_charge_class     -- �^���敪
            ,xoha.freight_carrier_code                    AS freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xoha.result_freight_carrier_code             AS res_freight_carrier_code -- �^���Ǝ҃R�[�h_����
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- �^���ƎҖ�
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- �^���ƎҖ�_����
            ,xoha.cust_po_number                          AS cust_po_number           -- �ڋq�����ԍ�
            ,xoha.collected_pallet_qty                    AS collected_pallet_qty     -- �p���b�g�������
            ,xoha.shipping_method_code                    AS shipping_method_code     -- �z���敪�R�[�h
            ,xoha.result_shipping_method_code             AS res_shipping_method_code -- �z���敪�R�[�h_����
            ,flv_ship_methd.meaning                       AS shipping_method_name     -- �z���敪��
            ,flv_res_ship_methd.meaning                   AS res_shipping_method_name -- �z���敪��_����
            ,xoha.mixed_no                                AS mixed_no                 -- ���ڌ�No
            ,xoha.no_cont_freight_class                   AS no_cont_freight_class    -- �_��O�^���敪
            ,xoha.transfer_location_code                  AS transfer_location_code   -- �U�֐�R�[�h
            ,xl2v.location_name                           AS transfer_location_name   -- �U�֐於
            ,xoha.shipping_instructions                   AS description              -- �E�v
            ,xoha.confirm_request_class                   AS confirm_request_class    -- �����S���m�F�˗���
            ,xoha.weight_capacity_class                   AS wt_capa_class            -- �d�ʗe�ϋ敪
            ,xola.request_item_code                       AS request_item_code        -- �i�ڃR�[�h
            ,xim2v_req.item_short_name                    AS request_item_name        -- �i�ږ���
            ,NVL(xola.uom_code
                ,xim2v_req.item_um)                       AS uom_code                 -- �P��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                     AS pallet_quantity          -- �p���b�g��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                     AS layer_quantity           -- �i��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                     AS case_quantity            -- �P�[�X��
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                     AS quantity                 -- ����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                     AS based_request_quantity   -- ���_�˗�����
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                     AS shipped_quantity         -- �o�׎��ѐ���
            ,TO_CHAR(xola.designated_production_date
                    ,cv_date_format_ymd)                  AS designated_product_date  -- �w�萻����
            ,ROUND(xola.weight  ,3)                       AS weight                   -- ���v�d��
            ,ROUND(xola.capacity,0)                       AS capacity                 -- ���v�e��
            ,xola.shipping_item_code                      AS shipping_item_code       -- �U�֕i�ڃR�[�h
            ,xim2v_ship.item_short_name                   AS shipping_item_name       -- �U�֕i�ږ���
            ,NVL(xoha.pallet_sum_quantity
                ,xoha.real_pallet_quantity)               AS real_pallet_quantity     -- �p���b�g���v����
            ,xoha.based_weight                            AS based_weight             -- ��{�d��
            ,xoha.based_capacity                          AS based_capacity           -- ��{�e��
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- ���v�d�ʁi�����v�j
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- ���v�e�ρi�����v�j
            ,xoha.loading_efficiency_weight               AS loading_efficiency_wgt   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity             AS loading_efficiency_capa  -- �e�ϐύڌ���
            ,itp.reason_code                              AS reason_code              -- ���R�R�[�h
            ,srct.reason_desc1                            AS reason_name              -- ���R��
            ,xcs.transaction_type                         AS carriers_scd_tran_type   -- �������
            ,xcs.freight_charge_type                      AS freight_charge_type_code -- �^���`�ԃR�[�h
            ,flv_freight_charge.meaning                   AS freight_charge_type_name -- �^���`�Ԗ�
            ,xcs.auto_process_type                        AS auto_process_type        -- �����z�ԑΏۋ敪
            ,ottt_carr.name                               AS carr_tran_type_name      -- �o�Ɍ`�Ԗ�_�z��
            ,ROUND(xcs.sum_loading_weight  ,0)            AS sum_loading_weight       -- �ύڏd�ʍ��v
            ,ROUND(xcs.sum_loading_capacity,0)            AS sum_loading_capacity     -- �ύڗe�ύ��v
            ,ROUND(xoha.sum_weight  ,3)                   AS sum_weight               -- �ύڏd��
            ,ROUND(xoha.sum_capacity,0)                   AS sum_capacity             -- �ύڗe��
            ,xoha.mixed_ratio                             AS mixed_ratio              -- ���ڗ�
            ,xoha.slip_number                             AS slip_number              -- �����No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                     AS small_quantity           -- ������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                     AS label_quantity           -- ���x������
            ,xoha.mixed_sign                              AS mixed_sign               -- ���ڋL��
            ,xmld.record_type_code                        AS record_type_code         -- �w���^���ы敪
            ,ilm.lot_no                                   AS lot_no                   -- ���b�gNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS product_date             -- �����N����
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd)                  AS expiration_date          -- �ܖ�����
            ,ilm.attribute2                               AS unique_symbol            -- �ŗL�L��
            ,ilm.attribute6                               AS package_quantity         -- �݌ɓ���
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_10
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS indication_quantity      -- �w������
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code
                                  ,cv_rec_type_cd_20
                                  ,xmld.actual_quantity
                                  ,NULL)
                  END                                     AS actual_quantity          -- ���ѐ���
            ,ilm.lot_id                                   AS lot_id                   -- ���b�gID
            ,ilm.attribute7                               AS stock_price              -- �݌ɒP��
            ,gv_transfer_date                             AS interface_datetime       -- �A�g����
            ,xswc.period_name                             AS period_name              -- ��v����
            ,cv_data_type_1                               AS data_type                -- �f�[�^�^�C�v('1':���A�g��)
      FROM   oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     --�󒍖���(�W��)
            ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
            ,oe_transaction_types_all    otta                     --�󒍃^�C�v
            ,oe_transaction_types_tl     ottt                     --�󒍃^�C�v(�����)
            ,xxcmn_cust_accounts2_v      xca2v_branch             --�ڋq�r���[�i�Ǌ����_�j
            ,xxcmn_party_sites2_v        xps2v_deli               --�p�[�e�B�T�C�g�r���[�i�o�א�j
            ,xxcmn_party_sites2_v        xps2v_res_deli           --�p�[�e�B�T�C�g�r���[�i�o�א�_���сj
            ,xxcmn_cust_accounts2_v      xca2v_cust               --�ڋq�r���[�i�ڋq�j
            ,mtl_item_locations          mil                      --OPM�ۊǏꏊ�}�X�^
            ,fnd_lookup_values           flv_time_from            --�N�C�b�N�R�[�h�i���׎���FROM�j
            ,fnd_lookup_values           flv_time_to              --�N�C�b�N�R�[�h�i���׎���TO�j
            ,xxcmn_parties2_v            xp2v_freight             --�p�[�e�B�r���[�i�^���Ǝҁj
            ,xxcmn_parties2_v            xp2v_res_frigt           --�p�[�e�B�r���[�i�^���Ǝҁj
            ,fnd_lookup_values           flv_ship_methd           --�N�C�b�N�R�[�h�i�z���敪�j
            ,fnd_lookup_values           flv_res_ship_methd       --�N�C�b�N�R�[�h�i�z���敪�Q���сj
            ,xxcmn_locations2_v          xl2v                     --���Ə��r���[
            ,fnd_lookup_values           flv_wt_capa_class        --�N�C�b�N�R�[�h�i�d�ʗe�ϋ敪�j
            ,xxcmn_item_mst2_v           xim2v_req                --OPM�i�ڏ��VIEW2�i�˗��i�ځj
            ,xxcmn_item_mst2_v           xim2v_ship               --OPM�i�ڏ��VIEW2�i�U�֕i�ځj
            ,xxwsh_carriers_schedule     xcs                      --�z�Ԕz���v��i�A�h�I���j
            ,fnd_lookup_values           flv_freight_charge       --�N�C�b�N�R�[�h(�^���`��)
            ,oe_transaction_types_all    otta_carr                --�󒍃^�C�v�i�z�ԁj
            ,oe_transaction_types_tl     ottt_carr                --�󒍃^�C�v(�����) �i�z�ԁj
            ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
            ,rcv_shipment_lines          rsl                      --�������
            ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
            ,sy_reas_cds_tl              srct                     --���R�R�[�h�\(����ʁj
            ,xxcfo_shipment_wait_coop    xswc                     --�󕥎���i�o�ׁj���A�g
      WHERE  ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = oola.header_id
      AND    ooha.header_id                    = xoha.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                 --�ŐV�t���O�FY
      AND    xoha.req_status                   = cv_req_status_08             --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    xoha.order_header_id              = xola.order_header_id      --@@@
      AND    oola.line_id                      = xola.line_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                 --���׍폜�t���O�FN
      AND    xoha.order_type_id                = otta.transaction_type_id
      AND    otta.attribute4                  <> cv_adjs_class_2           --�݌ɒ����敪�F2
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v_branch.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_branch.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_branch.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_to                   = xps2v_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_deli.party_site_status(+)   = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_deli.end_date_active, xoha.arrival_date)
      AND    xoha.result_deliver_to            = xps2v_res_deli.PARTY_SITE_NUMBER(+)
      AND    xps2v_res_deli.party_site_status(+)  = cv_party_site_status_a                       -- 2015/01/16 Ver1.1 Add
      AND    xoha.arrival_date                 BETWEEN NVL(xps2v_res_deli.start_date_active, xoha.arrival_date)
                                               AND     NVL(xps2v_res_deli.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = xca2v_cust.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v_cust.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v_cust.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = xl2v.location_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xl2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xl2v.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = xim2v_req.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = xim2v_ship.item_no(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xim2v_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(xim2v_ship.end_date_active, xoha.arrival_date)
      AND    xoha.request_no                   = xcs.default_line_number(+)
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30  --�����^�C�v(�A�h�I��)�F30�i�x���˗��j
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = ct_doc_type_porc                       -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = ct_completed_ind_1                     -- �����t���O�F1
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    xswc.order_header_id              = xoha.order_header_id   
      AND    xswc.order_line_id                = xola.order_line_id     
      AND    xswc.item_code                    = xola.request_item_code
      AND    xswc.record_type_code             = xmld.record_type_code
      AND    xswc.lot_no                       = ilm.lot_no
      AND    xswc.set_of_books_id              = gn_set_of_bks_id
      ORDER BY order_header_id
              ,order_line_id
              ,request_item_code
              ,record_type_code
              ,lot_no
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
        FETCH get_manual_cur INTO g_data_tab(1)  -- �d��L�[
                                 ,g_data_tab(2)  -- �󒍃w�b�_�A�h�I��ID
                                 ,g_data_tab(3)  -- �󒍖��׃A�h�I��ID
                                 ,g_data_tab(4)  -- �o�Ɍ`�Ԗ�_�o��
                                 ,g_data_tab(5)  -- �˗�No
                                 ,g_data_tab(6)  -- �X�e�[�^�X�R�[�h
                                 ,g_data_tab(7)  -- �ʒm�X�e�[�^�X�R�[�h
                                 ,g_data_tab(8)  -- �Ǌ����_�R�[�h
                                 ,g_data_tab(9)  -- �Ǌ����_��
                                 ,g_data_tab(10) -- �z����R�[�h
                                 ,g_data_tab(11) -- �z����R�[�h_����
                                 ,g_data_tab(12) -- �z���於
                                 ,g_data_tab(13) -- �z���於_����
                                 ,g_data_tab(14) -- �ڋq�R�[�h
                                 ,g_data_tab(15) -- �ڋq��
                                 ,g_data_tab(16) -- �o�Ɍ��R�[�h
                                 ,g_data_tab(17) -- �o�Ɍ���
                                 ,g_data_tab(18) -- �o�ɗ\���
                                 ,g_data_tab(19) -- �o�ɓ�
                                 ,g_data_tab(20) -- ���ח\���
                                 ,g_data_tab(21) -- ����
                                 ,g_data_tab(22) -- ���Ԏw��FROM
                                 ,g_data_tab(23) -- ���Ԏw��TO
                                 ,g_data_tab(24) -- �z��No
                                 ,g_data_tab(25) -- �^���敪
                                 ,g_data_tab(26) -- �^���Ǝ҃R�[�h
                                 ,g_data_tab(27) -- �^���Ǝ҃R�[�h_����
                                 ,g_data_tab(28) -- �^���ƎҖ�
                                 ,g_data_tab(29) -- �^���ƎҖ�_����
                                 ,g_data_tab(30) -- �ڋq�����ԍ�
                                 ,g_data_tab(31) -- �p���b�g�������
                                 ,g_data_tab(32) -- �z���敪�R�[�h
                                 ,g_data_tab(33) -- �z���敪�R�[�h_����
                                 ,g_data_tab(34) -- �z���敪��
                                 ,g_data_tab(35) -- �z���敪��_����
                                 ,g_data_tab(36) -- ���ڌ�No
                                 ,g_data_tab(37) -- �_��O�^���敪
                                 ,g_data_tab(38) -- �U�֐�R�[�h
                                 ,g_data_tab(39) -- �U�֐於
                                 ,g_data_tab(40) -- �E�v
                                 ,g_data_tab(41) -- �����S���m�F�˗��敪
                                 ,g_data_tab(42) -- �d�ʗe�ϋ敪
                                 ,g_data_tab(43) -- �i�ڃR�[�h
                                 ,g_data_tab(44) -- �i�ږ���
                                 ,g_data_tab(45) -- �P��
                                 ,g_data_tab(46) -- �p���b�g��
                                 ,g_data_tab(47) -- �i��
                                 ,g_data_tab(48) -- �P�[�X��
                                 ,g_data_tab(49) -- ����
                                 ,g_data_tab(50) -- ���_�˗�����
                                 ,g_data_tab(51) -- �o�׎��ѐ���
                                 ,g_data_tab(52) -- �w�萻����
                                 ,g_data_tab(53) -- ���v�d��
                                 ,g_data_tab(54) -- ���v�e��
                                 ,g_data_tab(55) -- �U�֕i�ڃR�[�h
                                 ,g_data_tab(56) -- �U�֕i�ږ���
                                 ,g_data_tab(57) -- �p���b�g���v����
                                 ,g_data_tab(58) -- ��{�d��
                                 ,g_data_tab(59) -- ��{�e��
                                 ,g_data_tab(60) -- ���v�d�ʁi�����v�j
                                 ,g_data_tab(61) -- ���v�e�ρi�����v�j
                                 ,g_data_tab(62) -- �d�ʐύڌ���
                                 ,g_data_tab(63) -- �e�ϐύڌ���
                                 ,g_data_tab(64) -- ���R�R�[�h
                                 ,g_data_tab(65) -- ���R��
                                 ,g_data_tab(66) -- �������
                                 ,g_data_tab(67) -- �^���`�ԃR�[�h
                                 ,g_data_tab(68) -- �^���`�Ԗ�
                                 ,g_data_tab(69) -- �����z�ԑΏۋ敪
                                 ,g_data_tab(70) -- �o�Ɍ`�Ԗ�_�z��
                                 ,g_data_tab(71) -- �ύڏd�ʍ��v
                                 ,g_data_tab(72) -- �ύڗe�ύ��v
                                 ,g_data_tab(73) -- �ύڏd��
                                 ,g_data_tab(74) -- �ύڗe��
                                 ,g_data_tab(75) -- ���ڗ�
                                 ,g_data_tab(76) -- �����No
                                 ,g_data_tab(77) -- ������
                                 ,g_data_tab(78) -- ���x������
                                 ,g_data_tab(79) -- ���ڋL��
                                 ,g_data_tab(80) -- �w���^���ы敪
                                 ,g_data_tab(81) -- ���b�gNo
                                 ,g_data_tab(82) -- �����N����
                                 ,g_data_tab(83) -- �ܖ�����
                                 ,g_data_tab(84) -- �ŗL�L��
                                 ,g_data_tab(85) -- �݌ɓ���
                                 ,g_data_tab(86) -- �w������
                                 ,g_data_tab(87) -- ���ѐ���
                                 ,g_data_tab(88) -- ���b�gID
                                 ,g_data_tab(89) -- �݌ɒP��
                                 ,g_data_tab(90) -- �A�g����
                                 ,g_data_tab(91) -- ��v����
                                 ,g_data_tab(92) -- �f�[�^�^�C�v
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
          --==============================================================
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
        FETCH get_fixed_period_cur INTO g_data_tab(1)  -- �d��L�[
                                       ,g_data_tab(2)  -- �󒍃w�b�_�A�h�I��ID
                                       ,g_data_tab(3)  -- �󒍖��׃A�h�I��ID
                                       ,g_data_tab(4)  -- �o�Ɍ`�Ԗ�_�o��
                                       ,g_data_tab(5)  -- �˗�No
                                       ,g_data_tab(6)  -- �X�e�[�^�X�R�[�h
                                       ,g_data_tab(7)  -- �ʒm�X�e�[�^�X�R�[�h
                                       ,g_data_tab(8)  -- �Ǌ����_�R�[�h
                                       ,g_data_tab(9)  -- �Ǌ����_��
                                       ,g_data_tab(10) -- �z����R�[�h
                                       ,g_data_tab(11) -- �z����R�[�h_����
                                       ,g_data_tab(12) -- �z���於
                                       ,g_data_tab(13) -- �z���於_����
                                       ,g_data_tab(14) -- �ڋq�R�[�h
                                       ,g_data_tab(15) -- �ڋq��
                                       ,g_data_tab(16) -- �o�Ɍ��R�[�h
                                       ,g_data_tab(17) -- �o�Ɍ���
                                       ,g_data_tab(18) -- �o�ɗ\���
                                       ,g_data_tab(19) -- �o�ɓ�
                                       ,g_data_tab(20) -- ���ח\���
                                       ,g_data_tab(21) -- ����
                                       ,g_data_tab(22) -- ���Ԏw��FROM
                                       ,g_data_tab(23) -- ���Ԏw��TO
                                       ,g_data_tab(24) -- �z��No
                                       ,g_data_tab(25) -- �^���敪
                                       ,g_data_tab(26) -- �^���Ǝ҃R�[�h
                                       ,g_data_tab(27) -- �^���Ǝ҃R�[�h_����
                                       ,g_data_tab(28) -- �^���ƎҖ�
                                       ,g_data_tab(29) -- �^���ƎҖ�_����
                                       ,g_data_tab(30) -- �ڋq�����ԍ�
                                       ,g_data_tab(31) -- �p���b�g�������
                                       ,g_data_tab(32) -- �z���敪�R�[�h
                                       ,g_data_tab(33) -- �z���敪�R�[�h_����
                                       ,g_data_tab(34) -- �z���敪��
                                       ,g_data_tab(35) -- �z���敪��_����
                                       ,g_data_tab(36) -- ���ڌ�No
                                       ,g_data_tab(37) -- �_��O�^���敪
                                       ,g_data_tab(38) -- �U�֐�R�[�h
                                       ,g_data_tab(39) -- �U�֐於
                                       ,g_data_tab(40) -- �E�v
                                       ,g_data_tab(41) -- �����S���m�F�˗��敪
                                       ,g_data_tab(42) -- �d�ʗe�ϋ敪
                                       ,g_data_tab(43) -- �i�ڃR�[�h
                                       ,g_data_tab(44) -- �i�ږ���
                                       ,g_data_tab(45) -- �P��
                                       ,g_data_tab(46) -- �p���b�g��
                                       ,g_data_tab(47) -- �i��
                                       ,g_data_tab(48) -- �P�[�X��
                                       ,g_data_tab(49) -- ����
                                       ,g_data_tab(50) -- ���_�˗�����
                                       ,g_data_tab(51) -- �o�׎��ѐ���
                                       ,g_data_tab(52) -- �w�萻����
                                       ,g_data_tab(53) -- ���v�d��
                                       ,g_data_tab(54) -- ���v�e��
                                       ,g_data_tab(55) -- �U�֕i�ڃR�[�h
                                       ,g_data_tab(56) -- �U�֕i�ږ���
                                       ,g_data_tab(57) -- �p���b�g���v����
                                       ,g_data_tab(58) -- ��{�d��
                                       ,g_data_tab(59) -- ��{�e��
                                       ,g_data_tab(60) -- ���v�d�ʁi�����v�j
                                       ,g_data_tab(61) -- ���v�e�ρi�����v�j
                                       ,g_data_tab(62) -- �d�ʐύڌ���
                                       ,g_data_tab(63) -- �e�ϐύڌ���
                                       ,g_data_tab(64) -- ���R�R�[�h
                                       ,g_data_tab(65) -- ���R��
                                       ,g_data_tab(66) -- �������
                                       ,g_data_tab(67) -- �^���`�ԃR�[�h
                                       ,g_data_tab(68) -- �^���`�Ԗ�
                                       ,g_data_tab(69) -- �����z�ԑΏۋ敪
                                       ,g_data_tab(70) -- �o�Ɍ`�Ԗ�_�z��
                                       ,g_data_tab(71) -- �ύڏd�ʍ��v
                                       ,g_data_tab(72) -- �ύڗe�ύ��v
                                       ,g_data_tab(73) -- �ύڏd��
                                       ,g_data_tab(74) -- �ύڗe��
                                       ,g_data_tab(75) -- ���ڗ�
                                       ,g_data_tab(76) -- �����No
                                       ,g_data_tab(77) -- ������
                                       ,g_data_tab(78) -- ���x������
                                       ,g_data_tab(79) -- ���ڋL��
                                       ,g_data_tab(80) -- �w���^���ы敪
                                       ,g_data_tab(81) -- ���b�gNo
                                       ,g_data_tab(82) -- �����N����
                                       ,g_data_tab(83) -- �ܖ�����
                                       ,g_data_tab(84) -- �ŗL�L��
                                       ,g_data_tab(85) -- �݌ɓ���
                                       ,g_data_tab(86) -- �w������
                                       ,g_data_tab(87) -- ���ѐ���
                                       ,g_data_tab(88) -- ���b�gID
                                       ,g_data_tab(89) -- �݌ɒP��
                                       ,g_data_tab(90) -- �A�g����
                                       ,g_data_tab(91) -- ��v����
                                       ,g_data_tab(92) -- �f�[�^�^�C�v
                                       ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
--
        -- ������������
        IF ( g_data_tab(92) = cv_data_type_0 ) THEN
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
        iv_token_value1       => gv_msg_shipment_info  -- �󕥎���i�o�ׁj���
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
          DELETE FROM xxcfo_shipment_wait_coop xswc -- �󕥎���i�o�ׁj���A�g�e�[�u��
          WHERE xswc.rowid = g_row_id_tab( i )
          AND   xswc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- ��TABLE �̃f�[�^�폜�Ɏ��s���܂����B
            -- �G���[���e�F ��ERRMSG
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name    -- XXCFO
                                     ,cv_msg_cfo_00025      -- �f�[�^�폜�G���[
                                     ,cv_tkn_table          -- �g�[�N��'TABLE'
                                     ,gv_tbl_nm_wait_coop   -- �󕥎���i�o�ׁj���A�g�e�[�u��
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
END XXCFO021A05C;
/
