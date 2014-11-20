CREATE OR REPLACE PACKAGE BODY XXCFO019A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A07C(body)
 * Description      : �d�q����AR�����̏��n�V�X�e���A�g
 * MD.050           : �d�q����AR�����̏��n�V�X�e���A�g <MD050_CFO_019_A07>
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_cash_wait          ���A�g�f�[�^�擾����(A-2)
 *  get_cash_control       �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  chk_item               ���ڃ`�F�b�N����(A-5)
 *  out_csv                CSV�o�͏���(A-6)
 *  ins_ar_cash_wait       ���A�g�e�[�u���o�^����(A-7)
 *  get_ar_cash_recon      �Ώۃf�[�^�擾����(A-4)
 *  upd_ar_cash_control    �Ǘ��e�[�u���o�^�E�X�V����(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-06    1.0   N.Sugiura      �V�K�쐬
 *  2012-10-05    1.1   N.Sugiura      �����e�X�g��Q�Ή�[��QNo24:��������GL�]���Ǘ�ID�擾���ύX]
 *  2012-10-16    1.2   N.Sugiura      �����e�X�g��Q�Ή�[��QNo30:���������e�[�u���̌����������]
 *  2012-10-17    1.3   N.Sugiura      �����e�X�g��Q�Ή�[��QNo31:�����e�[�u���̏����s��]
 *  2012-11-13    1.4   N.Sugiura      �����e�X�g��Q�Ή�[��QNo40:�蓮���s���̓����f�[�^�A�����f�[�^�擾���@�ύX]
 *  2012-12-18    1.5   T.Ishiwata     ���\���P
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO019A07C'; -- �p�b�P�[�W��
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
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --���A�g�f�[�^�`�F�b�N
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10019';   --���������σf�[�^�`�F�b�N���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_10026            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10026';   --�d�q����d��p�����[�^���͕s�����b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[���b�Z�[�W
-- ���b�Z�[�W(�g�[�N��)
  cv_msg_cfo_11000            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11000';  -- ���{�ꕶ����(�u��������ID�v)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';  -- ���{�ꕶ����(�u���ڂ��s���v)
  cv_msg_cfo_11009            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11009';  -- ���{�ꕶ����(�u�������A�g�e�[�u���v)
  cv_msg_cfo_11010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11010';  -- ���{�ꕶ����(�u�����Ǘ��e�[�u���v)
  cv_msg_cfo_11011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11011';  -- ���{�ꕶ����(�u�����e�[�u���v)
  cv_msg_cfo_11040            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11040';  -- ���{�ꕶ����(�uAR�������v)
  cv_msg_cfo_11044            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11044';  -- ���{�ꕶ����(�u���]���G���[�v)
  cv_msg_cfo_11052            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11052';  -- ���{�ꕶ����(�u����ID�v)
-- �g�[�N��
  cv_token_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';        --�g�[�N����(LOOKUP_TYPE)
  cv_token_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';        --�g�[�N����(LOOKUP_CODE)
  cv_token_prof_name          CONSTANT VARCHAR2(30)  := 'PROF_NAME';          --�g�[�N����(PROF_NAME)
  cv_token_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';            --�g�[�N����(DIR_TOK)
  cv_tkn_file_name            CONSTANT VARCHAR2(30)  := 'FILE_NAME';          --�g�[�N����(FILE_NAME)
  cv_tkn_get_data             CONSTANT VARCHAR2(30)  := 'GET_DATA';           --�g�[�N����(GET_DATA)
  cv_tkn_table                CONSTANT VARCHAR2(30)  := 'TABLE';              --�g�[�N����(TABLE)
  cv_tkn_receipt_h_id         CONSTANT VARCHAR2(30)  := 'RECEIPT_H_ID';       --�g�[�N����(RECEIPT_H_ID)
  cv_tkn_doc_seq_val          CONSTANT VARCHAR2(30)  := 'DOC_SEQ_VAL';        --�g�[�N����(DOC_SEQ_VAL)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(30)  := 'DOC_DIST_ID';        --�g�[�N����(DOC_DIST_ID)
  cv_tkn_doc_data             CONSTANT VARCHAR2(30)  := 'DOC_DATA';           --�g�[�N����(DOC_DATA)
  cv_tkn_key_date             CONSTANT VARCHAR2(30)  := 'KEY_DATA';           --�g�[�N����(KEY_DATA)
  cv_token_cause              CONSTANT VARCHAR2(30)  := 'CAUSE';              --�g�[�N����(CAUSE)
  cv_token_target             CONSTANT VARCHAR2(30)  := 'TARGET';             --�g�[�N����(TARGET)
  cv_token_key_data           CONSTANT VARCHAR2(30)  := 'MEANING';            --�g�[�N����(MEANING)
  cv_tkn_errmsg               CONSTANT VARCHAR2(30)  := 'ERRMSG';             --�g�[�N����(ERRMSG)
--
  --�A�v���P�[�V��������
  cv_xxcok_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOK';
  cv_xxcfo_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFO';
  cv_xxcff_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFF';
  cv_xxcoi_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOI';
  cv_xxcfr_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFR';
--
  --�e�[�u����
  cv_tbl_xxcfo_ar_cash_control CONSTANT VARCHAR2(30)   := 'XXCFO_AR_CASH_CONTROL';   --�����Ǘ��Ǘ�
  cv_tbl_xxcfo_ar_csh_wt_cp    CONSTANT VARCHAR2(30)   := 'XXCFO_AR_CASH_WAIT_COOP'; --�������A�g
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
--
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';       --�d�q���돈�����s��
  cv_lookup_item_chk_rept      CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_REPT';   --�d�q���덀�ڃ`�F�b�N�i�����j
  cv_lookup_cash_receipt_type CONSTANT VARCHAR2(30)  := 'XXCFO1_AR_CASH_RECEIPT_TYPE';     --�d�q����AR�����^�C�v
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                  -- �t���O�lY
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                  -- �t���O�lN
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
--
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- �d�q����AR�����f�[�^�t�@�C���i�[�p�X
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- ��v����ID
  cv_org_id                   CONSTANT VARCHAR2(100) := 'ORG_ID';                             -- �c�ƒP��ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AR_CASH_DATA_I_FILENAME'; -- �d�q����AR�����f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AR_CASH_DATA_U_FILENAME'; -- �d�q����AR�����f�[�^�X�V�t�@�C����
  cv_system_start_ymd         CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SYSTEM_START_YMD';        -- �d�q����c�ƃV�X�e���ғ��J�n�N����
--
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- �蓮���s
--
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- �ǉ�
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- �X�V
--
  cv_csh_rec_01               CONSTANT VARCHAR2(2)   := '01';                 -- ����
  cv_csh_rec_02               CONSTANT VARCHAR2(2)   := '02';                 -- ����
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- ����A�g��
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- ���A�g��
  cv_reversed                 CONSTANT VARCHAR2(10)  := 'REVERSED';
--
  cv_app                      CONSTANT VARCHAR2(3)  := 'APP';
--
  cv_cash                     CONSTANT VARCHAR2(4)  := 'CASH';
--2012/10/17 ADD Start
  cv_activity                 CONSTANT VARCHAR2(8)  := 'ACTIVITY';
--2012/10/17 ADD End
--
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   �i�`�F�b�N�j
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- ��������
--
  --CSV�o�̓t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
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
  gn_electric_exec_days       NUMBER;        -- �d�q���돈�����s����
  gn_proc_target_time         NUMBER;        -- �����Ώێ���
--
  gt_file_path                all_directories.directory_name%TYPE   DEFAULT NULL; --�f�B���N�g����
  gt_directory_path           all_directories.directory_path%TYPE   DEFAULT NULL; --�f�B���N�g��
  gn_set_of_bks_id            NUMBER;
  gn_org_id                   NUMBER;
  gt_cash_receipt_meaning     fnd_lookup_values_vl.meaning%TYPE;
  gt_recon_meaning            fnd_lookup_values_vl.meaning%TYPE;
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --�x���t���O
--
  gn_cash_id_from             NUMBER;
  gn_cash_id_to               NUMBER;
  gn_recon_id_from            NUMBER;
  gn_recon_id_to              NUMBER;
--
  -- ����ID
  gn_cash_receipt_id          NUMBER;
  -- ��������ID
  gn_csh_rcpt_hist_id         NUMBER;
  -- CSV�t�@�C���o�͗p
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_file_data                VARCHAR2(32767);
--
  gb_reopen_flag              BOOLEAN DEFAULT FALSE;
--
  -- �p�����[�^�p
  gv_ins_upd_kbn              VARCHAR2(1);     -- 1.�ǉ��X�V�敪
  gv_file_name                VARCHAR2(100);   -- 2.�t�@�C����
  gn_csh_rcpt_hist_id_from    NUMBER;          -- 3.��������ID�iFrom�j
  gn_csh_rcpt_hist_id_to      NUMBER;          -- 4.��������ID�iTo�j
  gv_doc_seq_value            VARCHAR2(100);   -- 5.���������ԍ�
  gv_exec_kbn                 VARCHAR2(1);     -- 6.����蓮�敪
--2012/11/13 ADD Start
  gv_data_type                VARCHAR2(4);     -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
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
    -- �������A�g�e�[�u��
    CURSOR get_cash_wait_cur
    IS
      SELECT xacwc.control_id AS control_id   -- ���A�gID
            ,xacwc.trx_type   AS trx_type     -- �^�C�v
            ,xacwc.rowid      AS row_id       -- ROWID
      FROM   xxcfo_ar_cash_wait_coop xacwc
      FOR UPDATE NOWAIT
      ;
    -- <�������A�g�e�[�u��>�e�[�u���^
    TYPE get_cash_wait_ttype IS TABLE OF get_cash_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    g_get_cash_wait_tab get_cash_wait_ttype;
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
    iv_id_from               IN  VARCHAR2,     -- 3.��������ID�iFrom�j
    iv_id_to                 IN  VARCHAR2,     -- 4.��������ID�iTo�j
    iv_doc_seq_value         IN  VARCHAR2,     -- 5.���������ԍ�
    iv_exec_kbn              IN  VARCHAR2,     -- 6.����蓮�敪
--2012/11/13 ADD Start
    iv_data_type             IN  VARCHAR2,     -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
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
    lt_cash_receipt_code      fnd_lookup_values.lookup_code%TYPE;
    lt_recon_code             fnd_lookup_values.lookup_code%TYPE;
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_rept
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ORDER BY  flv.lookup_code
      ;
--
    -- �N�C�b�N�R�[�h�擾(�^�C�v�������)
    CURSOR  get_type_cur
    IS
      SELECT    flv.lookup_code    AS lookup_code,
                flv.meaning        AS meaning
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_cash_receipt_type
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    chk_param_expt             EXCEPTION;
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
      , iv_conc_param3                  =>        iv_id_from                -- 3.��������ID�iFrom�j
      , iv_conc_param4                  =>        iv_id_to                  -- 4.��������ID�iTo�j
      , iv_conc_param5                  =>        iv_doc_seq_value          -- 5.���������ԍ�
      , iv_conc_param6                  =>        iv_exec_kbn               -- 6.����蓮�敪
--2012/11/13 ADD Start
      , iv_conc_param7                  =>        iv_data_type              -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
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
      , iv_conc_param3                  =>        iv_id_from                -- 3.��������ID�iFrom�j
      , iv_conc_param4                  =>        iv_id_to                  -- 4.��������ID�iTo�j
      , iv_conc_param5                  =>        iv_doc_seq_value          -- 5.���������ԍ�
      , iv_conc_param6                  =>        iv_exec_kbn               -- 6.����蓮�敪
--2012/11/13 ADD Start
      , iv_conc_param7                  =>        iv_data_type              -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
      , ov_errbuf                       =>        lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>        lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>        lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    --==============================================================
    -- 1.(2)  ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
--
      -- �����ԍ��A��������ID(From��To)��������
      IF ( ( ( iv_doc_seq_value IS NULL ) AND ( iv_id_from IS NULL ) AND ( iv_id_to IS NULL ) )
        -- ��������ID(From��To)�̕Е��̂ݓ���
        OR ( ( iv_id_from IS NOT NULL ) AND ( iv_id_to IS NULL ) )
          OR ( ( iv_id_from IS NULL ) AND ( iv_id_to IS NOT NULL ) ) )
      THEN
        RAISE chk_param_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- 1.(3)  �Ɩ��������t�擾
    --==============================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF  ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
    --==============================================================
    -- 1.(4) �N�C�b�N�R�[�h�擾
    --==============================================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)  AS attribute1, -- �d�q���돈�����s����
                TO_NUMBER(flv.attribute2)  AS attribute2  -- �����Ώێ���
      INTO      gn_electric_exec_days,
                gn_proc_target_time
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_book_date
      AND       flv.lookup_code         =       cv_pkg_name
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
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
    --==================================
    -- 1.(5) �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p)���̎擾
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
      lt_lookup_type    :=  cv_lookup_item_chk_rept;
      RAISE get_quicktype_expt;
    END IF;
--
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
    -- �c�ƒP��ID
    gn_org_id        := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ) );
--
    IF ( gn_org_id IS NULL ) THEN
--
      lt_token_prof_name := cv_org_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
--
      -- �d�q��������f�[�^�ǉ��t�@�C����
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        lt_token_prof_name := cv_add_filename;
--
      -- �d�q��������f�[�^�X�V�t�@�C����
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
    --==================================
    -- 1.(7) �N�C�b�N�R�[�h(�^�C�v����)���̎擾
    --==================================
--
    <<get_type_loop>>
    FOR get_type_rec IN get_type_cur LOOP
      -- �����̏ꍇ
      IF ( get_type_rec.lookup_code = cv_csh_rec_01  ) THEN
        lt_cash_receipt_code    := get_type_rec.lookup_code;
        -- ������u�����v���擾(�O���[�o���ϐ��Ɋi�[)
        gt_cash_receipt_meaning := get_type_rec.meaning;
      -- �����̔{
      ELSIF ( get_type_rec.lookup_code = cv_csh_rec_02 ) THEN
        lt_recon_code           := get_type_rec.lookup_code;
        -- ������u�����v���擾(�O���[�o���ϐ��Ɋi�[)
        gt_recon_meaning        := get_type_rec.meaning;
      END IF;
--
    END LOOP get_type_loop;
--
    -- �����擾�ł��Ȃ������ꍇ
    IF ( ( lt_recon_code IS NULL ) AND ( lt_cash_receipt_code IS NULL ) ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- �g�[�N���ҏW
      lt_lookup_code    :=  cv_csh_rec_01 || cv_delimit || cv_csh_rec_02;
      RAISE get_quickcode_expt;
    -- ������u�����v���擾�ł��Ȃ������ꍇ
    ELSIF ( lt_cash_receipt_code IS NULL ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- �g�[�N���ҏW
      lt_lookup_code    :=  cv_csh_rec_01;
      RAISE  get_quickcode_expt;
    -- ������u�����v���擾�ł��Ȃ������ꍇ
    ELSIF ( lt_recon_code IS NULL ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- �g�[�N���ҏW
      lt_lookup_code    :=  cv_csh_rec_02;
      RAISE  get_quickcode_expt;
    END IF;
--
    --==============================================================
    -- 1.(8) �f�B���N�g���p�X�擾
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
    -- 1.(9) IF�t�@�C�����o��
    --==================================
--
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
--
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
--
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
    -- 2. ����t�@�C�����݃`�F�b�N
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
    -- �p�����[�^���O���[�o���ϐ��Ɋi�[
    --==================================
-- 
    gv_ins_upd_kbn           := iv_ins_upd_kbn;                       -- 1.�ǉ��X�V�敪
    gn_csh_rcpt_hist_id_from := TO_NUMBER(iv_id_from);                -- 3.��������ID�iFrom�j
    gn_csh_rcpt_hist_id_to   := TO_NUMBER(iv_id_to);                  -- 4.��������ID�iTo�j
    gv_doc_seq_value         := iv_doc_seq_value;                     -- 5.���������ԍ�
    gv_exec_kbn              := iv_exec_kbn;                          -- 6.����蓮�敪
--2012/11/13 ADD Start
    gv_data_type             := iv_data_type;                         -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN chk_param_expt THEN                           --*** <��O�R�����g> ***
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10026
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : get_cash_wait
   * Description      : A-2�D���A�g�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_cash_wait(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_wait'; -- �v���O������
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
    --�J�[�\���I�[�v��
    OPEN get_cash_wait_cur;
    FETCH get_cash_wait_cur BULK COLLECT INTO g_get_cash_wait_tab;
    --�J�[�\���N���[�Y
    CLOSE get_cash_wait_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11009 -- �������A�g�e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( get_cash_wait_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_cash_wait_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cash_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_cash_control
   * Description      : A-3�D�Ǘ��e�[�u���f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_cash_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_cash_control'; -- �v���O������
--
    cv_cash_id_from     CONSTANT VARCHAR2(100) := 'gn_cash_id_from : ';    -- 1.��������ID(From)
    cv_cash_id_to       CONSTANT VARCHAR2(100) := 'gn_cash_id_to : ';      -- 2.��������ID(To)
    cv_recon_id_from    CONSTANT VARCHAR2(100) := 'gn_recon_id_from : ';   -- 3.����ID(From)
    cv_recon_id_to      CONSTANT VARCHAR2(100) := 'gn_recon_id_to : ';     -- 4.����ID(To)
    cv_cash_receipt_id  CONSTANT VARCHAR2(100) := 'gn_cash_receipt_id : '; -- 5.����ID
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
    lv_val1       VARCHAR2(100);
    lv_val2       VARCHAR2(100);
    lv_val3       VARCHAR2(100);
    lv_val4       VARCHAR2(100);
    lv_val5       VARCHAR2(100);
--
    -- ===============================
    -- �J�[�\��
    -- ===============================
--
    -- �@�����Ǘ��e�[�u��(�������̓����F������s(���b�N����)�FTo�擾�p)
    CURSOR get_n_ar_cash_ctl_lock_cur
    IS
      SELECT control_id  AS control_id                   -- �Ǘ�ID
      FROM   xxcfo_ar_cash_control xacc                  -- �����Ǘ�
      WHERE  xacc.process_flag = cv_flag_n               -- ������
      AND    xacc.trx_type     = gt_cash_receipt_meaning -- ����
      ORDER BY xacc.control_id    DESC,
               xacc.creation_date DESC
      FOR UPDATE NOWAIT
      ;
--
    -- �A�����Ǘ��e�[�u��(�����ς̓����F������s�FFrom�擾�p)
    CURSOR get_y_ar_cash_ctl_cur
    IS
      SELECT MAX(xacc.control_id) AS control_id           -- �Ǘ�ID
      FROM   xxcfo_ar_cash_control xacc                   -- �����Ǘ�
      WHERE  xacc.process_flag = cv_flag_y                -- �����ς�
      AND    xacc.trx_type     =  gt_cash_receipt_meaning -- ����
      ;
--
    -- �B�����Ǘ��e�[�u��(�������̏����F������s(���b�N����)�FTo�擾�p)
    CURSOR get_n_ar_recon_ctl_lock_cur
    IS
      SELECT control_id AS control_id                     -- �Ǘ�ID
      FROM   xxcfo_ar_cash_control xacc                   -- �����Ǘ�
      WHERE  xacc.process_flag = cv_flag_n                -- ������
      AND    xacc.trx_type     =  gt_recon_meaning        -- ����
      ORDER BY xacc.control_id DESC,
               xacc.creation_date DESC
      FOR UPDATE NOWAIT
      ;
--
    -- �C�����Ǘ��e�[�u��(�����ς̏����F������s�FFrom�擾�p)
    CURSOR get_y_ar_recon_ctl_cur
    IS
      SELECT MAX(xacc.control_id) AS control_id           -- �Ǘ�ID
      FROM   xxcfo_ar_cash_control xacc                   -- �����Ǘ�
      WHERE  xacc.process_flag = cv_flag_y                -- �����ς�
      AND    xacc.trx_type     =  gt_recon_meaning        -- ����
      ;
--
   -- �D�����e�[�u��(�蓮���s�F���������ԍ����͎�)
   CURSOR get_ar_cash_receipts_cur( iv_doc_seq_value IN VARCHAR2 )
   IS
     SELECT cash_receipt_id  AS cash_receipt_id
     FROM   ar_cash_receipts_all acra
     WHERE  doc_sequence_value   = TO_NUMBER(iv_doc_seq_value)
     AND    acra.set_of_books_id = gn_set_of_bks_id
     AND    acra.org_id          = gn_org_id
     ;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_id_from_expt          EXCEPTION;
    get_ar_cash_receipts_expt EXCEPTION;
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
    -- 1.�����f�[�^�擾
--
    -- 1-1.WHERE���To���擾(����������)
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      -- �@�����Ǘ��e�[�u��(�������̓����F������s(���b�N����)�FTo�擾�p)
      <<get_n_ar_cash_ctl_lock_loop>>
      FOR get_n_ar_cash_ctl_lock_rec IN get_n_ar_cash_ctl_lock_cur LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- WHERE���TO���擾
        -- (�Ȃ��A�d�q���돈�����s����������e�[�u�����擾�����f�[�^�������傫���ꍇ��NULL�̂܂�)
        IF ( ln_cnt = gn_electric_exec_days ) THEN
          gn_cash_id_to := get_n_ar_cash_ctl_lock_rec.control_id;
--
          -- �擾�ł�����LOOP�𔲂���
          EXIT;
--
        END IF;
--
      END LOOP get_n_ar_cash_ctl_lock_loop;
--
    END IF;
--
    -- 1-2.WHERE���From���擾(�����ϓ���)
    -- �A�����Ǘ��e�[�u��(�����ς̓����F������s�FFrom�擾�p)
    OPEN get_y_ar_cash_ctl_cur;
    FETCH get_y_ar_cash_ctl_cur INTO gn_cash_id_from;
    CLOSE get_y_ar_cash_ctl_cur;
--
    -- FROM���擾�ł��Ȃ������ꍇ�̓G���[
    IF ( gn_cash_id_from IS NULL ) THEN
      RAISE get_id_from_expt;
    ELSE
      -- Max�l + 1��From�ɐݒ�
      gn_cash_id_from := gn_cash_id_from + 1;
    END IF;
--
    -- ������
    ln_cnt := 0;
--
    -- 2.�����f�[�^�擾
--
    -- 2-1.WHERE���To���擾(����������)
    -- ������s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      -- �B�����Ǘ��e�[�u��(�������̏����F������s(���b�N����)�FTo�擾�p)
      <<get_n_ar_recon_ctl_lock_loop>>
      FOR get_n_ar_recon_ctl_lock_rec IN get_n_ar_recon_ctl_lock_cur LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- WHERE���TO���擾
        -- (�Ȃ��A�d�q���돈�����s����������e�[�u�����擾�����f�[�^�������傫���ꍇ��NULL�̂܂�)
        IF ( ln_cnt = gn_electric_exec_days ) THEN
          gn_recon_id_to := get_n_ar_recon_ctl_lock_rec.control_id;
        END IF;
--
      END LOOP get_n_ar_recon_ctl_lock_loop;
--
    END IF;
--
    -- 2-2.WHERE���FROM���擾
    -- �C�����Ǘ��e�[�u��(�����ς̏����F������s�FFrom�擾�p)
    OPEN get_y_ar_recon_ctl_cur;
    FETCH get_y_ar_recon_ctl_cur INTO gn_recon_id_from;
    CLOSE get_y_ar_recon_ctl_cur;
--
    -- FROM���擾�ł��Ȃ������ꍇ�̓G���[
    IF ( gn_recon_id_from IS NULL ) THEN
      RAISE get_id_from_expt;
    ELSE
      -- Max�l + 1��From�ɐݒ�
      gn_recon_id_from := gn_recon_id_from + 1;
    END IF;
--
    -- TO���擾�ł��Ȃ������ꍇ
    IF ( gv_exec_kbn  = cv_exec_fixed_period ) THEN
--
      IF (  ( gn_cash_id_to IS NULL ) AND ( gn_recon_id_to IS NULL ) ) THEN
--
        -- �擾�Ώۃf�[�^����
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => cv_msg_cfo_11010 -- �����Ǘ��e�[�u��
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
--
    END IF;
--
    -- �蓮���s
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      -- �����ԍ������͂��ꂽ�Ƃ��̂ݓ���ID���擾
      IF ( gv_doc_seq_value IS NOT NULL ) THEN 
--
        -- �D�����e�[�u��(�蓮���s�F���������ԍ����͎�)
        OPEN get_ar_cash_receipts_cur(gv_doc_seq_value);
        FETCH get_ar_cash_receipts_cur INTO gn_cash_receipt_id;
        CLOSE get_ar_cash_receipts_cur;
--
        IF ( gn_cash_receipt_id IS NULL ) THEN
          RAISE get_ar_cash_receipts_expt;
        END IF;
      END IF;
--
    END IF;
--
    lv_val1 := cv_cash_id_from || gn_cash_id_from;
    lv_val2 := cv_cash_id_to || gn_cash_id_to;
    lv_val3 := cv_recon_id_from || gn_recon_id_from;
    lv_val4 := cv_recon_id_to || gn_recon_id_to;
    lv_val5 := cv_cash_receipt_id || gn_cash_receipt_id;
--
    -- ���o���������O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val1
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val2
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val3
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val4
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val5
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
        iv_token_value1       => cv_msg_cfo_11010 -- �����Ǘ��e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �����ϓ����擾��O�n���h�� ***
    WHEN get_id_from_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11010 -- �����Ǘ��e�[�u��
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �����e�[�u���擾��O�n���h�� ***
    WHEN get_ar_cash_receipts_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11011 -- �����e�[�u��
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
--
      IF ( get_n_ar_cash_ctl_lock_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_n_ar_cash_ctl_lock_cur;
      END IF;
      IF ( get_y_ar_cash_ctl_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_y_ar_cash_ctl_cur;
      END IF;
      IF ( get_n_ar_recon_ctl_lock_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_n_ar_recon_ctl_lock_cur;
      END IF;
      IF ( get_y_ar_recon_ctl_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_y_ar_recon_ctl_cur;
      END IF;
      IF ( get_ar_cash_receipts_cur%ISOPEN ) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE get_ar_cash_receipts_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cash_control;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-5)
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
    lb_error_flag   BOOLEAN;
    lb_skip_flag    BOOLEAN;
--
    ln_cnt          NUMBER DEFAULT 0;
    lv_target_value VARCHAR2(100);
    lv_name         VARCHAR2(100)   DEFAULT NULL; -- �L�[���ږ�
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
    get_unproc_expt      EXCEPTION;
    warn_expt            EXCEPTION;
    unposting_expt       EXCEPTION;
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
    -- ���[�J���ϐ�������
    lb_error_flag := FALSE;
    
--
    -- �蓮���s�̏ꍇ
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      -- �X�V�̏ꍇ
      IF ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
--
        --==============================================================
        -- [�蓮���s]����[�X�V]�̏ꍇ�A���o�����f�[�^�������ς݂����`�F�b�N
        --==============================================================
--
        -- �^�C�v���u�����v
        IF ( g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
          -- From+ 1�ȏ�̏ꍇ�͖������Ȃ̂ŃG���[
          IF ( gn_cash_id_from <= g_data_tab(21) ) THEN
            lb_error_flag := TRUE;
          END IF;
--
        -- �^�C�v���u�����v
        ELSIF ( g_data_tab(1) = gt_recon_meaning ) THEN
--
          -- From+ 1�ȏ�̏ꍇ�͖������Ȃ̂ŃG���[
          IF ( gn_recon_id_from <= g_data_tab(44) ) THEN
            lb_error_flag := TRUE;
          END IF;
--
        END IF;
--
        -- �������f
        IF ( lb_error_flag = TRUE ) THEN
          RAISE get_unproc_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      -- [�蓮���s]�̏ꍇ�A���A�g�f�[�^�Ƃ��đ��݂��Ă��邩���`�F�b�N
      --==============================================================
--
      -- ���C���J�[�\���̃^�C�v���u�����v
      IF ( g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
        -- ��������ID�����A�g�e�[�u���ɒl���������ꍇ�́u�x���˃X�L�b�v�v
        <<g_get_cash_wait_loop>>
        FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
--
          -- ���A�g�e�[�u���̃^�C�v���u�����v
          IF ( g_get_cash_wait_tab(i).trx_type = gt_cash_receipt_meaning ) THEN
--
            -- ���C���J�[�\���̓�������ID�����A�g�e�[�u���̓�������ID�Ɠ�����
            IF ( g_data_tab(21) = g_get_cash_wait_tab(i).control_id) THEN
              -- �����X�L�b�v�t���O��ON
              lb_skip_flag    := TRUE;
            END IF;
--
          END IF;
--
        END LOOP g_get_cash_wait_loop;
--
      -- ���C���J�[�\���̃^�C�v���u�����v
      ELSIF ( g_data_tab(1) = gt_recon_meaning ) THEN
--
        -- ����ID�����A�g�e�[�u���ɒl���������ꍇ�́u�x���˃X�L�b�v�v
        <<g_get_cash_wait_loop>>
        FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
--
          -- ���A�g�e�[�u���̃^�C�v���u�����v
          IF ( g_get_cash_wait_tab(i).trx_type = gt_recon_meaning ) THEN
--
            -- ���C���J�[�\���̏���ID�����A�g�e�[�u���̏���ID�Ɠ�����
            IF ( g_data_tab(44) = g_get_cash_wait_tab(i).control_id) THEN
              -- �����X�L�b�v�t���O��ON
              lb_skip_flag    := TRUE;
            END IF;
--
          END IF;
--
        END LOOP g_get_cash_wait_loop;
--
      END IF;
--
    END IF;
--
    -- �������f
    IF ( lb_skip_flag = TRUE ) THEN
      -- �X�L�b�v�t���O��ON(�@A-6�FCSV�o�́A�AA-7�F���A�g�e�[�u���o�^���X�L�b�v)
      ov_skipflg := cv_flag_y;
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- GL�]���Ǘ�ID�`�F�b�N
    --==============================================================
--
    -- �g�[�N���ݒ�
    -- �^�C�v�������̏ꍇ
    IF (  g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
      lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                 , iv_name         => cv_msg_cfo_11000 -- ���b�Z�[�W�R�[�h
                                                 )
                        , 1
                        , 5000
                        );
--
      -- ��������ID
      lv_target_value := lv_name || cv_msg_part || TO_CHAR(g_data_tab(21));
--
    ELSE
--
      lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- �A�v���P�[�V�����Z�k��
                                                 , iv_name         => cv_msg_cfo_11052 -- ���b�Z�[�W�R�[�h
                                                 )
                        , 1
                        , 5000
                        );
--
      -- ����ID
      lv_target_value := lv_name || cv_msg_part || TO_CHAR(g_data_tab(44));
--
    END IF;
--
    -- GL�]���Ǘ�ID��0�ȉ�
    IF ( g_data_tab(43) <= 0 ) THEN
--
      RAISE unposting_expt;
--
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
--
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
            -- 1.���
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
              -- 1-1.�����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- �X�L�b�v�t���O��ON(�@A-6�FCSV�o�́A�AA-7�F���A�g�e�[�u���o�^���X�L�b�v)
                ov_skipflg := cv_flag_y;
--
                -- �G���[���b�Z�[�W�ҏW
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_date ,
                  iv_token_value1       => g_data_tab(21)
                );
--
              -- 1-2.�����`�F�b�N�ȊO
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
              ov_errmsg  := lv_errmsg;
              ov_errbuf  := lv_errmsg;
--
            -- 2.�蓮
            ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN
--
              -- 2-1.�����`�F�b�N�G���[(�G���[���b�Z�[�W���uAPP-XXCFO1-10011�v�̏ꍇ)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- �G���[���b�Z�[�W�ҏW
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_date ,
                  iv_token_value1       => g_data_tab(21)
                );
--
                -- �G���[(�������f)
                RAISE chk_item_expt;
--
              -- 2-2.�����`�F�b�N�ȊO
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
                -- �G���[(�������f)
                RAISE chk_item_expt;
--
              END IF;
--
            END IF;
--
            -- ���^�[���R�[�h�u�x���v
            ov_retcode := cv_status_warn;
--
            --1���ł��x������������EXIT
            EXIT;
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
    -- *** �������G���[�n���h�� ***
    WHEN get_unproc_expt THEN                           --*** <��O�R�����g> ***
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10019,
        iv_token_name1        => cv_tkn_receipt_h_id,
        iv_token_value1       => g_data_tab(21),  -- ��������ID
        iv_token_name2        => cv_tkn_doc_seq_val,
        iv_token_value2       => g_data_tab(5)    -- ���������ԍ�
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���A�g�f�[�^���݌x���n���h�� ***
    WHEN warn_expt THEN
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10010,
        iv_token_name1        => cv_tkn_doc_data,
        iv_token_value1       => cv_msg_cfo_11000,
        iv_token_name2        => cv_tkn_doc_dist_id,
        iv_token_value2       => g_data_tab(21)      -- ��������ID
      );
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** ���A�g�f�[�^����(GL�]���Ǘ�ID��0�ȉ�)�x���n���h�� ***
    WHEN unposting_expt THEN
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10007,
        iv_token_name1        => cv_token_cause,
        iv_token_value1       => cv_msg_cfo_11044,
        iv_token_name2        => cv_token_target,
        iv_token_value2       => lv_target_value,
        iv_token_name3        => cv_token_key_data,
        iv_token_value3       => lv_errmsg
      );
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
   * Description      : CSV�o�͏���(A-6)
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
        -- ���s�R�[�h�A�J���}�A�_�u���R�[�e�[�V�������폜����B
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- �_�u���N�H�[�g�ň͂�
          gv_file_data  :=  cv_quot || g_data_tab(ln_cnt) || cv_quot;
        ELSE
--
          -- �_�u���N�H�[�g�ň͂�
          gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
        END IF;
--
      --���ڑ�����NUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- ���̂܂ܓn��
          gv_file_data  :=  g_data_tab(ln_cnt) ;
--
        ELSE
--
          -- ���̂܂ܓn��
          gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
        END IF;
--
      --���ڑ�����DATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- ���̂܂ܓn��
          gv_file_data  :=  g_data_tab(ln_cnt);
--
        ELSE
--
          -- ���̂܂ܓn��
          gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
        END IF;
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
    --CSV���쐬���ꂽ��������ID��ێ�
    gn_csh_rcpt_hist_id := TO_NUMBER(g_data_tab(21));
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
   * Procedure Name   : ins_ar_cash_wait
   * Description      : ���A�g�e�[�u���o�^����(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ar_cash_wait(
    iv_errmsg     IN  VARCHAR2,     -- 1.�G���[���e
    iv_skipflg    IN  VARCHAR2,     -- 2.�X�L�b�v�t���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ar_cash_wait'; -- �v���O������
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
      --�������A�g�e�[�u���o�^
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_ar_cash_wait_coop(
           control_id             -- ���A�gID
          ,trx_type               -- �^�C�v
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
        VALUES (
           -- �^�C�v���u�����v�̏ꍇ�́u��������ID�v�A�u�����v�̏ꍇ�́u����ID�v
           DECODE( g_data_tab(1), gt_cash_receipt_meaning, TO_NUMBER(g_data_tab(21))
                                , gt_recon_meaning       , TO_NUMBER(g_data_tab(44)))
          ,g_data_tab(1)        -- �^�C�v
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
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
                                                         ,cv_msg_cfo_11009   -- �������A�g
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
  END ins_ar_cash_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_recon
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_ar_cash_recon(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_recon'; -- �v���O������
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
    ln_cnt                    NUMBER DEFAULT 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- �Ώۃf�[�^�擾�J�[�\��(������s)
    CURSOR get_fixed_period_cur
    IS
      -- �Ǘ��e�[�u���f�[�^�F����
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd )       AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- �������z_�v��z                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,NULL                                AS apply_date                    -- ������
            ,NULL                                AS amount_applied                -- �������z
            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,NULL                                AS amount_applied_from           -- �z���������z
            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,NULL                                AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr          -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
--2012/10/16 MOD Start
--        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
--2012/10/16 MOD End
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_cash_id_from AND gn_cash_id_to
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      -- �Ǘ��e�[�u���f�[�^�F����
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr araa abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT /*+ LEADING(araa acrh acr)
                 USE_NL(acrh acr araa abaa abb arm)
                 INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2)
                 INDEX(abaa ap_bank_accounts_u1)
                 INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod End
             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,NULL                                AS real_amount                   -- �������z_�v��z
            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- ������
            ,araa.amount_applied                 AS amount_applied                -- �������z
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
--2012/10/05 MOD Start
--            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--2012/10/05 MOD End
            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr             -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
            ,ar_receivable_applications_all araa  -- ���������e�[�u��
            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
--2012/10/17 MOD Start
--        AND araa.status                    = cv_app
        AND araa.status                    IN ( cv_app , cv_activity )
--2012/10/17 MOD End
        AND araa.set_of_books_id           = gn_set_of_bks_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_recon_id_from AND gn_recon_id_to
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      -- ���A�g�e�[�u���f�[�^�F����
--      SELECT  /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT  /*+ LEADING(xacwc acrh acrh2 acr) 
                  USE_NL(acrh acr acrh2 abaa abb arm) 
                  INDEX(acrh ar_cash_receipt_history_u1)
                  INDEX(acrh ar_cash_receipt_history_u2)
                  INDEX(abaa ap_bank_accounts_u1)
                  INDEX(abb ap_bank_branches_u1)
                  INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod End
             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- �������z_�v��z                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,NULL                                AS apply_date                    -- ������
            ,NULL                                AS amount_applied                -- �������z
            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,NULL                                AS amount_applied_from           -- �z���������z
            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z�@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,NULL                                AS receivable_application_id     -- ����ID
            ,cv_data_type_1                      AS data_type                     -- �f�[�^�^�C�v('1':���A�g)
        FROM ar_cash_receipts_all acr          -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
            ,xxcfo_ar_cash_wait_coop   xacwc   -- �������A�g�e�[�u��
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acr.receipt_method_id              = arm.receipt_method_id
--2012/10/16 MOD Start
--        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
--2012/10/16 MOD End
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND xacwc.trx_type                     = gt_cash_receipt_meaning          --�u�����v
        AND xacwc.control_id                   = acrh.cash_receipt_history_id
        AND acrh.org_id                        = gn_org_id
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      --���A�g�e�[�u���f�[�^�F����
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr araa abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT /*+ LEADING(xacwc araa)
                 USE_NL(acrh acr araa abaa abb arm)
                 INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2)
                 INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod ENd
             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,NULL                                AS real_amount                   -- �������z_�v��z
            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- ������
            ,araa.amount_applied                 AS amount_applied                -- �������z
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
--2012/10/05 MOD Start
--            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--2012/10/05 MOD End
            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
            ,cv_data_type_1                      AS data_type                     -- �f�[�^�^�C�v('1':���A�g)
        FROM ar_cash_receipts_all acr             -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
            ,ar_receivable_applications_all araa  -- ���������e�[�u��
            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
            ,xxcfo_ar_cash_wait_coop xacwc        -- �������A�g�e�[�u��
        WHERE xacwc.control_id             = araa.receivable_application_id
        AND acr.cash_receipt_id            = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
--2012/10/17 MOD Start
--        AND araa.status                    = cv_app
        AND araa.status                    IN ( cv_app , cv_activity )
--2012/10/17 MOD End
        AND araa.set_of_books_id           = gn_set_of_bks_id
        AND araa.application_type          = cv_cash
        AND xacwc.trx_type                 = gt_recon_meaning          -- �u�����v
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
--2012/11/13 DEL Start
--    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s1�F��������ID(FROM)�A��������ID(TO)�����)
--    CURSOR get_manual_cur1
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- �������z_�v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,NULL                                AS apply_date                    -- ������
--            ,NULL                                AS amount_applied                -- �������z
--            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,NULL                                AS amount_applied_from           -- �z���������z
--            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
--            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,NULL                                AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr          -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
--            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
--            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
--            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,NULL                                AS real_amount                   -- �������z_�v��z
--            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- ������
--            ,araa.amount_applied                 AS amount_applied                -- �������z
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
--            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr             -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
--            ,ar_receivable_applications_all araa  -- ���������e�[�u��
--            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
--            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
--            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
----
--    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s2�F�����ԍ������)
--    CURSOR get_manual_cur2
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- �������z_�v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,NULL                                AS apply_date                    -- ������
--            ,NULL                                AS amount_applied                -- �������z
--            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,NULL                                AS amount_applied_from           -- �z���������z
--            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
--            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,NULL                                AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr          -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
--            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
--            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
--            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND  acr.cash_receipt_id               = gn_cash_receipt_id
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,NULL                                AS real_amount                   -- �������z_�v��z
--            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- ������
--            ,araa.amount_applied                 AS amount_applied                -- �������z
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
--            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr             -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
--            ,ar_receivable_applications_all araa  -- ���������e�[�u��
--            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
--            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
--            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acr.cash_receipt_id            = gn_cash_receipt_id
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
----
--    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s3�F��������ID(FROM)�A��������ID(TO)�A�����ԍ������)
--    CURSOR get_manual_cur3
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- �������z_�v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,NULL                                AS apply_date                    -- ������
--            ,NULL                                AS amount_applied                -- �������z
--            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,NULL                                AS amount_applied_from           -- �z���������z
--            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
--            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,NULL                                AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr          -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
--            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
--            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
--            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        AND acr.cash_receipt_id                = gn_cash_receipt_id
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
--            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
--            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
--            ,arm.name                            AS name                          -- �x�����@
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- �����ڋq�R�[�h
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- �����ڋq��
--            ,acr.amount                          AS amount                        -- �����z
--            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
--            ,abb.bank_name                       AS bank_name                     -- ��s��
--            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
--            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
--            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
--            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
--            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
--            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
--            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
--            ,acrh.status                         AS status                        -- �X�e�[�^�X
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- �����
--            ,acrh.amount                         AS amount_hist                   -- �������z_����
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
--            ,NULL                                AS real_amount                   -- �������z_�v��z
--            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- ������
--            ,araa.amount_applied                 AS amount_applied                -- �������z
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
--            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
--            ,acr.currency_code                   AS currency_code                 -- �ʉ�
--            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
--            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
--            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
--            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
--            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
--            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
--        FROM ar_cash_receipts_all acr             -- �����e�[�u��
--            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
--            ,ar_receivable_applications_all araa  -- ���������e�[�u��
--            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
--            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
--            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
--            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
--            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        AND acr.cash_receipt_id                = gn_cash_receipt_id
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
--2012/11/13 DEL End
--2012/11/13 ADD Start
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s1�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����)
    CURSOR get_manual_c_cur1
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX( ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- �������z_�v��z                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,NULL                                AS apply_date                    -- ������
            ,NULL                                AS amount_applied                -- �������z
            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,NULL                                AS amount_applied_from           -- �z���������z
            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,NULL                                AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr          -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- ��������ID
        ;
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s2�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����)
    CURSOR get_manual_r_cur2
    IS
      SELECT /*+ LEADING(araa acr acrh) USE_NL(araa acr acrh abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,NULL                                AS real_amount                   -- �������z_�v��z
            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- ������
            ,araa.amount_applied                 AS amount_applied                -- �������z
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr             -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
            ,ar_receivable_applications_all araa  -- ���������e�[�u��
            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- ����ID
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s3�F�^�C�v���u�����v�A���A�����ԍ������)
    CURSOR get_manual_c_cur3
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- �������z_�v��z                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,NULL                                AS apply_date                    -- ������
            ,NULL                                AS amount_applied                -- �������z
            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,NULL                                AS amount_applied_from           -- �z���������z
            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,NULL                                AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr          -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND  acr.cash_receipt_id               = gn_cash_receipt_id
    ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s4�F�^�C�v���u�����v�A���A�����ԍ������)
    CURSOR get_manual_r_cur4
    IS
      SELECT /*+ LEADING(araa acrh acr) USE_NL(araa acrh acr abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,NULL                                AS real_amount                   -- �������z_�v��z
            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- ������
            ,araa.amount_applied                 AS amount_applied                -- �������z
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr             -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
            ,ar_receivable_applications_all araa  -- ���������e�[�u��
            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND acr.cash_receipt_id            = gn_cash_receipt_id
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s5�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������)
    CURSOR get_manual_c_cur5
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- �������z_�v��z                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,NULL                                AS apply_date                    -- ������
            ,NULL                                AS amount_applied                -- �������z
            ,NULL                                AS applied_customer_trx_id       -- �����Ώێ��ID
            ,NULL                                AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �����ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,NULL                                AS amount_applied_from           -- �z���������z
            ,NULL                                AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,NULL                                AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,NULL                                AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,acrh.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,NULL                                AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr          -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh  -- ���������e�[�u��
            ,ar_cash_receipt_history_all acrh2 -- ���������e�[�u��(�O��)
            ,ar_receipt_methods arm            -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa         -- ��s�����}�X�^
            ,ap_bank_branches abb              -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct    -- GL���[�g�}�X�^
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- ��������ID
        AND acr.cash_receipt_id                = gn_cash_receipt_id
    ;
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s6�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������)
    CURSOR get_manual_r_cur6
    IS
      SELECT /*+ LEADING(araa acrh acr) USE_NL(araa acrh acr abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- �^�C�v(�Œ�l�F����)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- ����ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- �v���
            ,acr.receipt_number                  AS receipt_number                -- �����ԍ�
            ,acr.doc_sequence_value              AS doc_sequence_value            -- ���������ԍ�
            ,acr.receipt_method_id               AS receipt_method_id             -- �x�����@ID
            ,arm.name                            AS name                          -- �x�����@
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- ������
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- �����ڋq�R�[�h
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- �����ڋq��
            ,acr.amount                          AS amount                        -- �����z
            ,abb.bank_number                     AS bank_number                   -- ��s�ԍ�
            ,abb.bank_name                       AS bank_name                     -- ��s��
            ,abb.bank_num                        AS bank_num                      -- �x�X�ԍ�
            ,abb.bank_branch_name                AS bank_branch_name              -- �x�X��
            ,abaa.bank_account_num               AS bank_account_num              -- ������s�����ԍ�
            ,abaa.bank_account_name              AS bank_account_name             -- ������s������
            ,acr.attribute1                      AS attribute1                    -- �U���˗��l���J�i
            ,acr.attribute2                      AS attribute2                    -- ���_�R�[�h
            ,acr.attribute3                      AS attribute3                    -- �[�i��ڋq�R�[�h
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- ��������ID
            ,acrh.status                         AS status                        -- �X�e�[�^�X
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- �����
            ,acrh.amount                         AS amount_hist                   -- �������z_����
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- ��s�萔��_����
            ,NULL                                AS real_amount                   -- �������z_�v��z
            ,NULL                                AS real_factor_discount_amount   -- ��s�萔��_�v��z
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- ������
            ,araa.amount_applied                 AS amount_applied                -- �������z
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- �����Ώێ��ID
            ,rct.trx_number                      AS trx_number                    -- �����Ώێ���ԍ�
            ,acr.currency_code                   AS currency_code                 -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type          -- ���[�g�^�C�v
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- ���Z��
            ,acrh.exchange_rate                  AS exchange_rate                 -- ���Z���[�g
            ,NULL                                AS acctd_amount                  -- �������z_�@�\�ʉ݌v��z
            ,NULL                                AS acctd_factor_discount_amount  -- ��s�萔��_�@�\�ʉ݌v��z
            ,araa.amount_applied_from            AS amount_applied_from           -- �z���������z
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- �@�\�ʉݔz���������z
            ,rct.invoice_currency_code           AS invoice_currency_code         -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- �@�\�ʉݏ������z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- �A�g����
            ,araa.posting_control_id             AS posting_control_id            -- GL�]���Ǘ�ID
            ,araa.receivable_application_id      AS receivable_application_id     -- ����ID
            ,cv_data_type_0                      AS data_type                     -- �f�[�^�^�C�v('0':����A�g��)
        FROM ar_cash_receipts_all acr             -- �����e�[�u��
            ,ar_cash_receipt_history_all acrh     -- ���������e�[�u��
            ,ar_receivable_applications_all araa  -- ���������e�[�u��
            ,ar_receipt_methods arm               -- �x�����@�e�[�u��
            ,ap_bank_accounts_all abaa            -- ��s�����}�X�^
            ,ap_bank_branches abb                 -- ��s�x�X�}�X�^
            ,gl_daily_conversion_types gdct       -- GL���[�g�}�X�^
            ,ra_customer_trx_all rct              -- ����w�b�_�e�[�u��
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- ����ID
        AND acr.cash_receipt_id                = gn_cash_receipt_id
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--2012/11/13 ADD End
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
      -- �蓮���s1,2�F��������ID(FROM)�A��������ID(TO)�����
      IF ( ( gn_csh_rcpt_hist_id_from IS NOT NULL ) AND ( gn_csh_rcpt_hist_id_to IS NOT NULL)
        AND ( gn_cash_receipt_id IS NULL ) )
      THEN
--2012/11/13 DEL Start
--        --�J�[�\���I�[�v��
--        OPEN get_manual_cur1;
--        <<get_manual_loop1>>
--        LOOP
--        FETCH get_manual_cur1 INTO
--              g_data_tab(1)  -- �^�C�v
--            , g_data_tab(2)  -- ����ID
--            , g_data_tab(3)  -- �v���
--            , g_data_tab(4)  -- �����ԍ�
--            , g_data_tab(5)  -- ���������ԍ�
--            , g_data_tab(6)  -- �x�����@ID
--            , g_data_tab(7)  -- �x�����@
--            , g_data_tab(8)  -- ������
--            , g_data_tab(9)  -- �����ڋq�R�[�h
--            , g_data_tab(10) -- �����ڋq��
--            , g_data_tab(11) -- �����z
--            , g_data_tab(12) -- ��s�ԍ�
--            , g_data_tab(13) -- ��s��
--            , g_data_tab(14) -- �x�X�ԍ�
--            , g_data_tab(15) -- �x�X��
--            , g_data_tab(16) -- ������s�����ԍ�
--            , g_data_tab(17) -- ������s������
--            , g_data_tab(18) -- �U���˗��l���J�i
--            , g_data_tab(19) -- ���_�R�[�h
--            , g_data_tab(20) -- �[�i��ڋq�R�[�h
--            , g_data_tab(21) -- ��������ID
--            , g_data_tab(22) -- �X�e�[�^�X
--            , g_data_tab(23) -- �����
--            , g_data_tab(24) -- �������z_����
--            , g_data_tab(25) -- ��s�萔��_����
--            , g_data_tab(26) -- �������z_�v��z
--            , g_data_tab(27) -- ��s�萔��_�v��z
--            , g_data_tab(28) -- ������
--            , g_data_tab(29) -- �������z
--            , g_data_tab(30) -- �����Ώێ��ID
--            , g_data_tab(31) -- �����Ώێ���ԍ�
--            , g_data_tab(32) -- �����ʉ�
--            , g_data_tab(33) -- ���[�g�^�C�v
--            , g_data_tab(34) -- ���Z��
--            , g_data_tab(35) -- ���Z���[�g
--            , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
--            , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
--            , g_data_tab(38) -- �z���������z
--            , g_data_tab(39) -- �@�\�ʉݔz���������z
--            , g_data_tab(40) -- �����Ώێ���ʉ�
--            , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
--            , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
--            , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            ;
--          EXIT WHEN get_manual_cur1%NOTFOUND;
--
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- �蓮���s1�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����)
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
          --�J�[�\���I�[�v��
          OPEN get_manual_c_cur1;
        -- �蓮���s2�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur2;
        END IF;
--
        <<get_manual_loop1>>
        LOOP
          -- �蓮���s1�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����)
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
            FETCH get_manual_c_cur1 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_c_cur1%NOTFOUND;
          -- �蓮���s2�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�����
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur2 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_r_cur2%NOTFOUND;
--
          END IF;
--
--2012/11/13 ADD End
          --==============================================================
          -- �ȉ��A�����Ώ�
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-5)
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
            -- CSV�o�͏���(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --���A�g�e�[�u���o�^����(A-7)
            --==============================================================
            -- �蓮�Ȃ̂œo�^�͂��Ȃ��B�o�͏����̂݁B
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7�̃��[�U�[�G���[���b�Z�[�W
            , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
            , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
            , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
            , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ���G���[�I��
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop1;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur1;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur1;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur2;
        END IF;
--2012/11/13 MOD End
--
      -- �蓮���s3,4�F��������ԍ������
      ELSIF ( ( gn_csh_rcpt_hist_id_from IS NULL ) AND ( gn_csh_rcpt_hist_id_to IS NULL)
        AND ( gn_cash_receipt_id IS NOT NULL ) )
      THEN
--2012/11/13 DEL Start
--        --�J�[�\���I�[�v��
--        OPEN get_manual_cur2;
--        <<get_manual_loop2>>
--        LOOP
--        FETCH get_manual_cur2 INTO
--              g_data_tab(1)  -- �^�C�v
--            , g_data_tab(2)  -- ����ID
--            , g_data_tab(3)  -- �v���
--            , g_data_tab(4)  -- �����ԍ�
--            , g_data_tab(5)  -- ���������ԍ�
--            , g_data_tab(6)  -- �x�����@ID
--            , g_data_tab(7)  -- �x�����@
--            , g_data_tab(8)  -- ������
--            , g_data_tab(9)  -- �����ڋq�R�[�h
--            , g_data_tab(10) -- �����ڋq��
--            , g_data_tab(11) -- �����z
--            , g_data_tab(12) -- ��s�ԍ�
--            , g_data_tab(13) -- ��s��
--            , g_data_tab(14) -- �x�X�ԍ�
--            , g_data_tab(15) -- �x�X��
--            , g_data_tab(16) -- ������s�����ԍ�
--            , g_data_tab(17) -- ������s������
--            , g_data_tab(18) -- �U���˗��l���J�i
--            , g_data_tab(19) -- ���_�R�[�h
--            , g_data_tab(20) -- �[�i��ڋq�R�[�h
--            , g_data_tab(21) -- ��������ID
--            , g_data_tab(22) -- �X�e�[�^�X
--            , g_data_tab(23) -- �����
--            , g_data_tab(24) -- �������z_����
--            , g_data_tab(25) -- ��s�萔��_����
--            , g_data_tab(26) -- �������z_�v��z
--            , g_data_tab(27) -- ��s�萔��_�v��z
--            , g_data_tab(28) -- ������
--            , g_data_tab(29) -- �������z
--            , g_data_tab(30) -- �����Ώێ��ID
--            , g_data_tab(31) -- �����Ώێ���ԍ�
--            , g_data_tab(32) -- �����ʉ�
--            , g_data_tab(33) -- ���[�g�^�C�v
--            , g_data_tab(34) -- ���Z��
--            , g_data_tab(35) -- ���Z���[�g
--            , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
--            , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
--            , g_data_tab(38) -- �z���������z
--            , g_data_tab(39) -- �@�\�ʉݔz���������z
--            , g_data_tab(40) -- �����Ώێ���ʉ�
--            , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
--            , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
--            , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            ;
--          EXIT WHEN get_manual_cur2%NOTFOUND;
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- �蓮���s3�F�^�C�v���u�����v�A���A�����ԍ������)
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
          --�J�[�\���I�[�v��
          OPEN get_manual_c_cur3;
        -- �蓮���s4�F�^�C�v���u�����v�A���A�����ԍ������
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur4;
        END IF;
--
        <<get_manual_loop2>>
        LOOP
          -- �蓮���s3�F�^�C�v���u�����v�A���A�����ԍ������)
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
            FETCH get_manual_c_cur3 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_c_cur3%NOTFOUND;
          -- �蓮���s4�F�^�C�v���u�����v�A���A�����ԍ������
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur4 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_r_cur4%NOTFOUND;
--
          END IF;
--2012/11/13 ADD End
--
          --==============================================================
          -- �ȉ��A�����Ώ�
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-5)
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
            -- CSV�o�͏���(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --���A�g�e�[�u���o�^����(A-7)
            --==============================================================
            -- �蓮�Ȃ̂œo�^�͂��Ȃ��B�o�͏����̂݁B
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7�̃��[�U�[�G���[���b�Z�[�W
            , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
            , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
            , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
            , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ���G���[�I��
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop2;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur2;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur3;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur4;
        END IF;
--2012/11/13 MOD End
--
      ELSIF ( ( gn_csh_rcpt_hist_id_from IS NOT NULL ) AND ( gn_csh_rcpt_hist_id_to IS NOT NULL)
        AND ( gn_cash_receipt_id IS NOT NULL ) )
      THEN
--
--2012/11/13 DEL Start
--        --�J�[�\���I�[�v��
--        OPEN get_manual_cur3;
--        <<get_manual_loop3>>
--        LOOP
--        FETCH get_manual_cur3 INTO
--              g_data_tab(1)  -- �^�C�v
--            , g_data_tab(2)  -- ����ID
--            , g_data_tab(3)  -- �v���
--            , g_data_tab(4)  -- �����ԍ�
--            , g_data_tab(5)  -- ���������ԍ�
--            , g_data_tab(6)  -- �x�����@ID
--            , g_data_tab(7)  -- �x�����@
--            , g_data_tab(8)  -- ������
--            , g_data_tab(9)  -- �����ڋq�R�[�h
--            , g_data_tab(10) -- �����ڋq��
--            , g_data_tab(11) -- �����z
--            , g_data_tab(12) -- ��s�ԍ�
--            , g_data_tab(13) -- ��s��
--            , g_data_tab(14) -- �x�X�ԍ�
--            , g_data_tab(15) -- �x�X��
--            , g_data_tab(16) -- ������s�����ԍ�
--            , g_data_tab(17) -- ������s������
--            , g_data_tab(18) -- �U���˗��l���J�i
--            , g_data_tab(19) -- ���_�R�[�h
--            , g_data_tab(20) -- �[�i��ڋq�R�[�h
--            , g_data_tab(21) -- ��������ID
--            , g_data_tab(22) -- �X�e�[�^�X
--            , g_data_tab(23) -- �����
--            , g_data_tab(24) -- �������z_����
--            , g_data_tab(25) -- ��s�萔��_����
--            , g_data_tab(26) -- �������z_�v��z
--            , g_data_tab(27) -- ��s�萔��_�v��z
--            , g_data_tab(28) -- ������
--            , g_data_tab(29) -- �������z
--            , g_data_tab(30) -- �����Ώێ��ID
--            , g_data_tab(31) -- �����Ώێ���ԍ�
--            , g_data_tab(32) -- �����ʉ�
--            , g_data_tab(33) -- ���[�g�^�C�v
--            , g_data_tab(34) -- ���Z��
--            , g_data_tab(35) -- ���Z���[�g
--            , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
--            , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
--            , g_data_tab(38) -- �z���������z
--            , g_data_tab(39) -- �@�\�ʉݔz���������z
--            , g_data_tab(40) -- �����Ώێ���ʉ�
--            , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
--            , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
--            , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
--            ;
--          EXIT WHEN get_manual_cur3%NOTFOUND;
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- �蓮���s5�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
          --�J�[�\���I�[�v��
          OPEN get_manual_c_cur5;
        -- �蓮���s6�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur6;
        END IF;
--
        <<get_manual_loop3>>
        LOOP
          -- �蓮���s5�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- �^�C�v�u�����v
            FETCH get_manual_c_cur5 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_c_cur5%NOTFOUND;
          -- �蓮���s6�F�^�C�v���u�����v�A���A��������ID(FROM)�A��������ID(TO)�A�����ԍ������
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur6 INTO
                  g_data_tab(1)  -- �^�C�v
                , g_data_tab(2)  -- ����ID
                , g_data_tab(3)  -- �v���
                , g_data_tab(4)  -- �����ԍ�
                , g_data_tab(5)  -- ���������ԍ�
                , g_data_tab(6)  -- �x�����@ID
                , g_data_tab(7)  -- �x�����@
                , g_data_tab(8)  -- ������
                , g_data_tab(9)  -- �����ڋq�R�[�h
                , g_data_tab(10) -- �����ڋq��
                , g_data_tab(11) -- �����z
                , g_data_tab(12) -- ��s�ԍ�
                , g_data_tab(13) -- ��s��
                , g_data_tab(14) -- �x�X�ԍ�
                , g_data_tab(15) -- �x�X��
                , g_data_tab(16) -- ������s�����ԍ�
                , g_data_tab(17) -- ������s������
                , g_data_tab(18) -- �U���˗��l���J�i
                , g_data_tab(19) -- ���_�R�[�h
                , g_data_tab(20) -- �[�i��ڋq�R�[�h
                , g_data_tab(21) -- ��������ID
                , g_data_tab(22) -- �X�e�[�^�X
                , g_data_tab(23) -- �����
                , g_data_tab(24) -- �������z_����
                , g_data_tab(25) -- ��s�萔��_����
                , g_data_tab(26) -- �������z_�v��z
                , g_data_tab(27) -- ��s�萔��_�v��z
                , g_data_tab(28) -- ������
                , g_data_tab(29) -- �������z
                , g_data_tab(30) -- �����Ώێ��ID
                , g_data_tab(31) -- �����Ώێ���ԍ�
                , g_data_tab(32) -- �����ʉ�
                , g_data_tab(33) -- ���[�g�^�C�v
                , g_data_tab(34) -- ���Z��
                , g_data_tab(35) -- ���Z���[�g
                , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
                , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
                , g_data_tab(38) -- �z���������z
                , g_data_tab(39) -- �@�\�ʉݔz���������z
                , g_data_tab(40) -- �����Ώێ���ʉ�
                , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
                , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
                , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
                ;
            EXIT WHEN get_manual_r_cur6%NOTFOUND;
--
          END IF;
--2012/11/13 ADD End
--
          --==============================================================
          -- �ȉ��A�����Ώ�
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-5)
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
            -- CSV�o�͏���(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --���A�g�e�[�u���o�^����(A-7)
            --==============================================================
            -- �蓮�Ȃ̂œo�^�͂��Ȃ��B�o�͏����̂݁B
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7�̃��[�U�[�G���[���b�Z�[�W
            , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
            , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
            , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
            , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ���G���[�I��
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop3;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur3;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur5;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur6;
        END IF;
--2012/11/13 MOD End
--
      END IF;
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
            g_data_tab(1)  -- �^�C�v
          , g_data_tab(2)  -- ����ID
          , g_data_tab(3)  -- �v���
          , g_data_tab(4)  -- �����ԍ�
          , g_data_tab(5)  -- ���������ԍ�
          , g_data_tab(6)  -- �x�����@ID
          , g_data_tab(7)  -- �x�����@
          , g_data_tab(8)  -- ������
          , g_data_tab(9)  -- �����ڋq�R�[�h
          , g_data_tab(10) -- �����ڋq��
          , g_data_tab(11) -- �����z
          , g_data_tab(12) -- ��s�ԍ�
          , g_data_tab(13) -- ��s��
          , g_data_tab(14) -- �x�X�ԍ�
          , g_data_tab(15) -- �x�X��
          , g_data_tab(16) -- ������s�����ԍ�
          , g_data_tab(17) -- ������s������
          , g_data_tab(18) -- �U���˗��l���J�i
          , g_data_tab(19) -- ���_�R�[�h
          , g_data_tab(20) -- �[�i��ڋq�R�[�h
          , g_data_tab(21) -- ��������ID
          , g_data_tab(22) -- �X�e�[�^�X
          , g_data_tab(23) -- �����
          , g_data_tab(24) -- �������z_����
          , g_data_tab(25) -- ��s�萔��_����
          , g_data_tab(26) -- �������z_�v��z
          , g_data_tab(27) -- ��s�萔��_�v��z
          , g_data_tab(28) -- ������
          , g_data_tab(29) -- �������z
          , g_data_tab(30) -- �����Ώێ��ID
          , g_data_tab(31) -- �����Ώێ���ԍ�
          , g_data_tab(32) -- �����ʉ�
          , g_data_tab(33) -- ���[�g�^�C�v
          , g_data_tab(34) -- ���Z��
          , g_data_tab(35) -- ���Z���[�g
          , g_data_tab(36) -- �������z_�@�\�ʉ݌v��z
          , g_data_tab(37) -- ��s�萔��_�@�\�ʉ݌v��z
          , g_data_tab(38) -- �z���������z
          , g_data_tab(39) -- �@�\�ʉݔz���������z
          , g_data_tab(40) -- �����Ώێ���ʉ�
          , g_data_tab(41) -- �@�\�ʉݏ������z�@�\�ʉݏ������z
          , g_data_tab(42) -- �A�g����                                -- �����܂ł��`�F�b�N��CSV�o�͑Ώ�(DFF�ɓo�^����)
          , g_data_tab(43) -- GL�]���Ǘ�ID                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
          , g_data_tab(44) -- ����ID                                  -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
          , g_data_tab(45) -- �f�[�^�^�C�v                            -- �`�F�b�N�ACSV�t�@�C���o�͑ΏۊO
          ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- �ȉ��A�����Ώ�
        --==============================================================
--
        -- ������������
        IF ( g_data_tab(45) = cv_data_type_0 ) THEN
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-5)
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
          -- CSV�o�͏���(A-6)
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
          gv_warning_flg := cv_flag_y;
--
          --==============================================================
          --���A�g�e�[�u���o�^����(A-7)
          --==============================================================
          -- ���A�g�e�[�u���o�^����(A-7)�A�A���A�X�L�b�v�t���O��ON(��1)�̏ꍇ
          -- �͖��A�g�e�[�u���ɂ͓o�^���Ȃ�(���O�̏o�͂���)�B
          -- (��1)�@���A�g�e�[�u���Ƀf�[�^������ꍇ�A�A�����G���[�����������ꍇ
          ins_ar_cash_wait(
            iv_errmsg     =>    lv_errmsg     -- A-5�̃��[�U�[�G���[���b�Z�[�W
          , iv_skipflg    =>    lv_skipflg    -- �X�L�b�v�t���O
          , ov_errbuf     =>    lv_errbuf     -- �G���[���b�Z�[�W
          , ov_retcode    =>    lv_retcode    -- ���^�[���R�[�h
          , ov_errmsg     =>    lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
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
        iv_token_value1       => cv_msg_cfo_11040  -- AR�������
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
--2012/11/13 MOD Start
--      IF ( get_manual_cur1%ISOPEN ) THEN
--        CLOSE get_manual_cur1;
--      END IF;
--      IF ( get_manual_cur2%ISOPEN ) THEN
--        CLOSE get_manual_cur2;
--      END IF;
--      IF ( get_manual_cur3%ISOPEN ) THEN
--        CLOSE get_manual_cur3;
--      END IF;
      IF ( get_manual_c_cur1%ISOPEN ) THEN
        CLOSE get_manual_c_cur1;
      END IF;
      IF ( get_manual_r_cur2%ISOPEN ) THEN
        CLOSE get_manual_r_cur2;
      END IF;
      IF ( get_manual_c_cur3%ISOPEN ) THEN
        CLOSE get_manual_c_cur3;
      END IF;
      IF ( get_manual_r_cur4%ISOPEN ) THEN
        CLOSE get_manual_r_cur4;
      END IF;
      IF ( get_manual_c_cur5%ISOPEN ) THEN
        CLOSE get_manual_c_cur5;
      END IF;
      IF ( get_manual_r_cur6%ISOPEN ) THEN
        CLOSE get_manual_r_cur6;
      END IF;
--2012/11/13 MOD End
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_cash_recon;
--
  /**********************************************************************************
   * Procedure Name   : upd_ar_cash_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-8)
   ***********************************************************************************/
  PROCEDURE upd_ar_cash_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ar_cash_control'; -- �v���O������
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
    ln_cash_rcpt_hst_ctl_id      NUMBER; --�ő��������ID(�����Ǘ��e�[�u��)
    ln_cash_receipt_history_id   NUMBER; --�ő��������ID(���������e�[�u��)
    ln_recon_ctl_id              NUMBER; --�ő����ID(�����Ǘ��e�[�u��)
    ln_receivable_application_id NUMBER; --�ő����ID(�����e�[�u��)
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
    --������s�̏ꍇ�̂݁A�ȉ��̏������s��
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --==============================================================
      --���A�g�f�[�^�폜
      --==============================================================
--
      --A-2�Ŏ擾�������A�g�f�[�^�������ɁA�폜���s��
      <<delete_loop>>
      FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_ar_cash_wait_coop xacwc -- �������A�g
          WHERE xacwc.rowid = g_get_cash_wait_tab( i ).row_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name   -- XXCFO
                                      ,cv_msg_cfo_00025    -- �f�[�^�폜�G���[
                                      ,cv_tkn_table        -- �g�[�N��'TABLE'
                                      ,cv_msg_cfo_11009    -- �������A�g�e�[�u��
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
      --==============================================================
      --�����Ǘ��e�[�u���X�V(�����f�[�^�X�V)
      --==============================================================
--
      BEGIN
--
        UPDATE xxcfo_ar_cash_control xacc --�����Ǘ�
        SET xacc.process_flag           = cv_flag_y                 -- �����σt���O
           ,xacc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,xacc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           ,xacc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,xacc.request_id             = cn_request_id             -- �v��ID
           ,xacc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,xacc.program_id             = cn_program_id             -- �v���O����ID
           ,xacc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE xacc.process_flag         = cv_flag_n                 -- �����σt���O'N'
          AND xacc.trx_type             = gt_cash_receipt_meaning   -- �^�C�v�u�����v
          AND xacc.control_id           <= gn_cash_id_to            -- A-3�Ŏ擾������������ID(To)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table        -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11010    -- �����Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg       -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM             -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      --�����Ǘ��e�[�u���X�V(�����f�[�^�X�V)
      --==============================================================
--
      BEGIN
--
        UPDATE xxcfo_ar_cash_control xacc --�����Ǘ�
        SET xacc.process_flag           = cv_flag_y                 -- �����σt���O
           ,xacc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,xacc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           ,xacc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,xacc.request_id             = cn_request_id             -- �v��ID
           ,xacc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,xacc.program_id             = cn_program_id             -- �v���O����ID
           ,xacc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE xacc.process_flag         = cv_flag_n                 -- �����σt���O'N'
          AND xacc.trx_type             = gt_recon_meaning          -- �^�C�v�u�����v
          AND xacc.control_id          <= gn_recon_id_to            -- A-3�Ŏ擾��������ID(To)
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table        -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11010    -- �����Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg       -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM             -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      --�����Ǘ��e�[�u���o�^(�����f�[�^�o�^)
      --==============================================================
--
      IF ( gn_proc_target_time IS NULL ) THEN
        gn_proc_target_time := 0;
      ELSE
        gn_proc_target_time := gn_proc_target_time / 24;
      END IF;
--
      --�����Ǘ��f�[�^����ő�̓�������ID���擾
      SELECT MAX(xacc.control_id) AS control_id
        INTO ln_cash_rcpt_hst_ctl_id
        FROM xxcfo_ar_cash_control xacc
      WHERE  xacc.trx_type = gt_cash_receipt_meaning
      ;
--
      --�����쐬���ꂽ��������ID�̍ő�l���擾
      SELECT NVL(MAX(archa.cash_receipt_history_id), ln_cash_rcpt_hst_ctl_id) AS cash_receipt_history_id
        INTO ln_cash_receipt_history_id
        FROM ar_cash_receipt_history_all archa
       WHERE archa.cash_receipt_history_id > ln_cash_rcpt_hst_ctl_id
         AND archa.org_id        = gn_org_id
         AND archa.creation_date < ( gd_process_date + 1 + gn_proc_target_time )
      ;
--
      --�����Ǘ��e�[�u���o�^
      BEGIN
        INSERT INTO xxcfo_ar_cash_control(
           business_date          -- �Ɩ����t
          ,control_id             -- �Ǘ�ID
          ,trx_type               -- �^�C�v
          ,process_flag           -- �����σt���O
          ,created_by             -- �쐬��
          ,creation_date          -- �쐬��
          ,last_updated_by        -- �ŏI�X�V��
          ,last_update_date       -- �ŏI�X�V��
          ,last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             -- �v��ID
          ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             -- �R���J�����g�E�v���O����ID
          ,program_update_date    -- �v���O�����X�V��
        ) VALUES (
           gd_process_date
          ,ln_cash_receipt_history_id
          ,gt_cash_receipt_meaning
          ,cv_flag_n
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00024    -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table        -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11010    -- �����Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg       -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM             -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
--
      --==============================================================
      --�����Ǘ��e�[�u���o�^(�����f�[�^�o�^)
      --==============================================================
      --�����Ǘ��f�[�^����ő�̏���ID���擾
      SELECT MAX(xacc.control_id) AS control_id
        INTO ln_recon_ctl_id
        FROM xxcfo_ar_cash_control xacc
      WHERE  xacc.trx_type = gt_recon_meaning
      ;
--
      --�����쐬���ꂽ����ID�̍ő�l���擾
--2012/12/18 Ver.1.5 Mod Start
--      SELECT NVL(MAX(araa.receivable_application_id), ln_recon_ctl_id) AS receivable_application_id
      SELECT /*+ INDEX(araa AR_RECEIVABLE_APPLICATIONS_U1) */
             NVL(MAX(araa.receivable_application_id), ln_recon_ctl_id) AS receivable_application_id
--2012/12/18 Ver.1.5 Mod End
        INTO ln_receivable_application_id
        FROM ar_receivable_applications_all araa
       WHERE araa.receivable_application_id > ln_recon_ctl_id
         AND araa.creation_date < ( gd_process_date + 1 + gn_proc_target_time )
      ;
--
      --�����Ǘ��e�[�u���o�^
      BEGIN
        INSERT INTO xxcfo_ar_cash_control(
           business_date          -- �Ɩ����t
          ,control_id             -- �Ǘ�ID
          ,trx_type               -- �^�C�v
          ,process_flag           -- �����σt���O
          ,created_by             -- �쐬��
          ,creation_date          -- �쐬��
          ,last_updated_by        -- �ŏI�X�V��
          ,last_update_date       -- �ŏI�X�V��
          ,last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             -- �v��ID
          ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             -- �R���J�����g�E�v���O����ID
          ,program_update_date    -- �v���O�����X�V��
        ) VALUES (
           gd_process_date
          ,ln_receivable_application_id
          ,gt_recon_meaning
          ,cv_flag_n
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00024    -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table        -- �g�[�N��'TABLE'
                                                         ,cv_msg_cfo_11010    -- �����Ǘ��e�[�u��
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
  END upd_ar_cash_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn           IN  VARCHAR2,  -- 1.�ǉ��X�V�敪
    iv_file_name             IN  VARCHAR2,  -- 2.�t�@�C����
    iv_id_from               IN  VARCHAR2,  -- 3.��������ID�iFrom�j
    iv_id_to                 IN  VARCHAR2,  -- 4.��������ID�iTo�j
    iv_doc_seq_value         IN  VARCHAR2,  -- 5.���������ԍ�
    iv_exec_kbn              IN  VARCHAR2,  -- 6.����蓮�敪
--2012/11/13 ADD Start
    iv_data_type             IN  VARCHAR2,  -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
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
      iv_ins_upd_kbn           => iv_ins_upd_kbn,           -- 1.�ǉ��X�V�敪
      iv_file_name             => iv_file_name,             -- 2.�t�@�C����
      iv_id_from               => iv_id_from,               -- 3.��������ID�iFrom�j
      iv_id_to                 => iv_id_to,                 -- 4.��������ID�iTo�j
      iv_doc_seq_value         => iv_doc_seq_value,         -- 5.���������ԍ�
      iv_exec_kbn              => iv_exec_kbn,              -- 6.����蓮�敪
--2012/11/13 ADD Start
      iv_data_type             => iv_data_type,             -- 7.�f�[�^�^�C�v
--2012/11/13 ADD End
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
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_cash_wait(
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
    get_cash_control(
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
    -- �Ώۃf�[�^�擾����(A-4)
    -- ===============================
    get_ar_cash_recon(
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
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-8)
    -- ===============================
    upd_ar_cash_control(
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
    iv_id_from               IN  VARCHAR2,    -- 3.��������ID�iFrom�j
    iv_id_to                 IN  VARCHAR2,    -- 4.��������ID�iTo�j
    iv_doc_seq_value         IN  VARCHAR2,    -- 5.���������ԍ�
--2012/11/13 MOD Start
--    iv_exec_kbn              IN  VARCHAR2     -- 6.����蓮�敪
    iv_exec_kbn              IN  VARCHAR2,             -- 6.����蓮�敪
    iv_data_type             IN  VARCHAR2 DEFAULT NULL -- 7.�f�[�^�^�C�v
--2012/11/13 MOD End
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
       iv_ins_upd_kbn                              -- 1.�ǉ��X�V�敪
      ,iv_file_name                                -- 2.�t�@�C����
      ,iv_id_from                                  -- 3.��������ID�iFrom�j
      ,iv_id_to                                    -- 4.��������ID�iTo�j
      ,iv_doc_seq_value                            -- 5.���������ԍ�
      ,iv_exec_kbn                                 -- 6.����蓮�敪
--2012/11/13 MOD Start
      ,iv_data_type                                -- 7.�f�[�^�^�C�v
--2012/11/13 MOD End
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
END XXCFO019A07C;
/
