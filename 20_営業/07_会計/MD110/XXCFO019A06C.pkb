CREATE OR REPLACE PACKAGE BODY XXCFO019A06C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A06C(body)
 * Description      : �d�q����AR����̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A06_�d�q����AR����̏��n�V�X�e���A�g
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������(A-1)
 *  get_ar_wait_coop        ���A�g�f�[�^�擾����(A-2)
 *  get_ar_trx_control      �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  get_ar_trx              �Ώۃf�[�^�擾(A-4)
 *  chk_item                ���ڃ`�F�b�N����(A-5)
 *  out_csv                 �b�r�u�o�͏���(A-6)
 *  ins_ar_wait_coop        ���A�g�e�[�u���o�^����(A-7)
 *  del_ar_wait_coop        ���A�g�e�[�u���폜����(A-8)
 *  upd_ar_trx_control      �Ǘ��e�[�u���o�^�E�X�V����(A-9)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W���E�I������(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-14    1.0   K.Onotsuka      �V�K�쐬
 *  2012-10-18    1.1   N.Sugiura       �����e�X�g��Q�Ή�[��QNo32:���ʊ֐��Ăяo�����̃G���[�n���h�����O�C��]
 *                                      �����e�X�g��Q�Ή�[��QNo33:���A�g�e�[�u���o�^���e�ǉ�]
 *                                      �����e�X�g��Q�Ή�[��QNo35:���C���J�[�\���̓��t���ڂ̎擾���ύX]
 *                                      �����e�X�g��Q�Ή�[��QNo36:������ׂ�LINE�s��TAX�s�̌��������ύX]
 *  2012-11-28    1.2   T.Osawa         0�����x���I���Ή�
 *  2012-12-18    1.3   T.Ishiwata      ���\���P�Ή�
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
  gn_target_cnt      NUMBER;                    -- �Ώی����i�A�g���j
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A06C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';          -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_add_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_I_FILENAME'; -- �d�q����AR����f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_U_FILENAME'; -- �d�q����AR����f�[�^�X�V�t�@�C����
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                            -- ��v����ID
  cv_org_id                   CONSTANT VARCHAR2(100) := 'ORG_ID';                                      -- �c�ƒP��
  --���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --�t�@�C�����݃G���[
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --�t�@�C���������݃G���[
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10004';   --�p�����[�^���͕s�����b�Z�[�W
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10005';   --�d�󖢓]�L���b�Z�[�W
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10006';   --�͈͎w��G���[���b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10008';   --�p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_param                CONSTANT VARCHAR2(20)  := 'PARAM';    -- �p�����[�^��
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';    -- �p�����[�^��
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';    -- �p�����[�^��
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ���b�N�A�b�v�^�C�v��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';          -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';         -- SQL�G���[���b�Z�[�W
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- �f�B���N�g����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- �t�@�C����
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- �e�[�u����
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';          -- ���A�g�f�[�^�o�^���R
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';         -- ���A�g�f�[�^����L�[
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';        -- ���A�g�G���[���e
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- �f�[�^���e(����w�b�_ID)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- ����w�b�_ID
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';     -- �G���[�e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- �G���[���
  cv_tkn_key_item             CONSTANT VARCHAR2(20)  := 'KEY_ITEM';       -- �G���[���
  cv_tkn_key_value            CONSTANT VARCHAR2(20)  := 'KEY_VALUE';      -- �G���[���
  cv_tkn_max_id               CONSTANT VARCHAR2(20)  := 'MAX_ID';         -- �ő�ID
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_11008         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11008'; -- ���ڂ��s��
  cv_msgtkn_cfo_11045         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11045'; -- AR����ԍ��AAR���ID(From�|To)
  cv_msgtkn_cfo_11046         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11046'; -- AR���ID(From)
  cv_msgtkn_cfo_11047         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11047'; -- AR���ID(To)
  cv_msgtkn_cfo_11048         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11048'; -- AR���ID
  cv_msgtkn_cfo_11050         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11050'; -- AR����Ǘ��e�[�u��
  cv_msgtkn_cfo_11051         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11051'; -- AR�C���Ǘ��e�[�u��
  cv_msgtkn_cfo_11053         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11053'; -- AR�C��ID
  cv_msgtkn_cfo_11054         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11054'; -- AR������
  cv_msgtkn_cfo_11055         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11055'; -- AR������A�g�e�[�u��
  cv_msgtkn_cfo_11056         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11056'; -- AR����Ǘ��e�[�u��
  cv_msgtkn_cfo_11058         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11058'; -- �C��
  cv_msgtkn_cfo_11059         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11059'; -- ���
  cv_msgtkn_cfo_11060         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11060'; -- �N������
  cv_msgtkn_cfo_11061         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11061'; -- �N����������
  cv_msgtkn_cfo_11062         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11062'; -- ���㐿����
  cv_msgtkn_cfo_11063         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11063'; -- �N���W�b�g�E����
  cv_msgtkn_cfo_11064         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11064'; -- �N���W�b�gMEMO����
  
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --�d�q���돈�����s��
  cv_lookup_item_chk_artrx    CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_ARTRX'; --�d�q���덀�ڃ`�F�b�N�iAR����j
  cv_lookup_adjust_reason     CONSTANT VARCHAR2(30)  := 'ADJUST_REASON';                  --�C�����R
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymd          CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                  --�b�r�u�o�̓t�H�[�}�b�g
  --�b�r�u
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- ��������
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- �蓮���s
  --�ǉ��X�V�敪
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- �ǉ�
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- �X�V
  --�f�[�^�^�C�v
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- �A�g��
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- ���A�g��
  --��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_x                        CONSTANT VARCHAR2(1)   := 'X';                  -- 'X'
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --����
  --�Œ�l
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
  cv_par_start                CONSTANT VARCHAR2(1)   := '(';                  -- ����(�n)
  cv_par_end                  CONSTANT VARCHAR2(1)   := ')';                  -- ����(�I)
  cv_status_p                 CONSTANT VARCHAR2(1)   := 'P';                  -- �X�e�[�^�X�F'P'(���]�L)
  --�t�@�C���o��
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   �i�`�F�b�N�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --�o�̓f�[�^���
  --���ڃ`�F�b�N
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- ���ږ���
  gt_item_len                   g_item_len_ttype;           -- ���ڂ̒���
  gt_item_decimal               g_item_decimal_ttype;       -- ���ځi�����_�ȉ��̒����j
  gt_item_nullflg               g_item_nullflg_ttype;       -- �K�{���ڃt���O
  gt_item_attr                  g_item_attr_ttype;          -- ���ڑ���
  gt_item_cutflg                g_item_cutflg_ttype;        -- �؎̂ăt���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                -- �Ɩ����t
  gv_coop_date                VARCHAR2(14);                        -- �A�g���t
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;   -- �d�q���돈�����s����
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;   -- �����Ώێ���
  gt_org_id                   mtl_parameters.organization_id%TYPE; -- �g�DID
  gn_set_of_bks_id            NUMBER;                              -- ��v����ID
  gt_ar_header_id_from        xxcfo_ar_trx_control.customer_trx_id%TYPE DEFAULT NULL; -- ����w�b�_ID(�o�͑Ώۃf�[�^���o����)
  gt_ar_header_id_to          xxcfo_ar_trx_control.customer_trx_id%TYPE;              -- ����w�b�_ID(�o�͑Ώۃf�[�^���o����)
  gt_ar_adj_id_from           xxcfo_ar_adj_control.adjustment_id%TYPE DEFAULT NULL;   -- �C��ID(�o�͑Ώۃf�[�^���o����)
  gt_ar_adj_id_to             xxcfo_ar_adj_control.adjustment_id%TYPE;                -- �C��ID(�o�͑Ώۃf�[�^���o����)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --�t�@�C���p�X
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --�d�q�������f�[�^�ǉ��t�@�C��
  gn_item_cnt                 NUMBER;             --�`�F�b�N���ڌ���
  gv_0file_flg                VARCHAR2(1) DEFAULT cv_flag_n; --0Byte�t�@�C���㏑���t���O
  gv_warning_flg              VARCHAR2(1) DEFAULT cv_flag_n; --�x���t���O
  gn_id_from                  NUMBER; --���̓p�����[�^�i�[�p(AR���ID(From))
  gn_id_to                    NUMBER; --���̓p�����[�^�i�[�p(AR���ID(To))
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  --������A�g�f�[�^�擾�J�[�\��
  ----�蓮�p(���b�N�Ȃ�)
  CURSOR  ar_trx_wait_coop_cur
  IS
    SELECT xawc.journal_type AS journal_type      -- �^�C�v
          ,xawc.trx_id       AS trx_id            -- AR���ID
          ,xawc.rowid        AS row_id            -- RowID
      FROM xxcfo_ar_wait_coop xawc -- ������A�g
    ;
  ----����p(���b�N����)
  CURSOR  ar_trx_wait_coop_lock_cur
  IS
    SELECT xawc.journal_type AS journal_type      -- �^�C�v
          ,xawc.trx_id       AS trx_id            -- AR���ID
          ,xawc.rowid        AS row_id            -- RowID
      FROM xxcfo_ar_wait_coop xawc -- ������A�g
    FOR UPDATE NOWAIT
    ;
    -- ���R�[�h�^
    TYPE ar_trx_wait_coop_rec IS RECORD(
       journal_type xxcfo_ar_wait_coop.journal_type%TYPE
      ,trx_id       xxcfo_ar_wait_coop.trx_id%TYPE
      ,row_id       UROWID
    );
    -- �e�[�u���^
    TYPE ar_trx_wait_coop_ttype IS TABLE OF ar_trx_wait_coop_rec INDEX BY BINARY_INTEGER;
    ar_trx_wait_coop_tab ar_trx_wait_coop_ttype;
--
  --�X�V�pRowID�擾�J�[�\��(AR���)
  CURSOR  upd_rowid_cur( it_ar_header_id_from IN xxcfo_ar_trx_control.customer_trx_id%TYPE)
  IS
    SELECT xatc.rowid                 -- RowID
      FROM xxcfo_ar_trx_control xatc  -- ����Ǘ�
    WHERE  xatc.customer_trx_id >= it_ar_header_id_from 
      AND  xatc.customer_trx_id <= gt_ar_header_id_to
    ;
    -- �e�[�u���^
    TYPE upd_rowid_ttype IS TABLE OF upd_rowid_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    upd_rowid_tab upd_rowid_ttype;
--
  --�X�V�pRowID�擾�J�[�\��(AR�C��)
  CURSOR  upd_rowid_adj_cur( it_ar_adj_id_from IN xxcfo_ar_adj_control.adjustment_id%TYPE)
  IS
    SELECT xaac.rowid                 -- RowID
      FROM xxcfo_ar_adj_control xaac --�C���Ǘ�
     WHERE xaac.adjustment_id >= it_ar_adj_id_from 
       AND xaac.adjustment_id <= gt_ar_adj_id_to
    ;
    -- �e�[�u���^
    TYPE upd_rowid_adj_ttype IS TABLE OF upd_rowid_adj_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    upd_rowid_adj_tab upd_rowid_adj_ttype;
--
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  global_lock_expt  EXCEPTION; -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name   IN  VARCHAR2, -- 2.�t�@�C����
    iv_trx_type    IN  VARCHAR2, -- 3.�^�C�v
    iv_trx_number  IN  VARCHAR2, -- 4.AR����ԍ�
    iv_id_from     IN  VARCHAR2, -- 5.AR���ID�iFrom�j
    iv_id_to       IN  VARCHAR2, -- 6.AR���ID�iTo�j
    iv_exec_kbn    IN  VARCHAR2, -- 7.����蓮�敪
    ov_errbuf      OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg          VARCHAR2(3000);
    lv_full_name    VARCHAR2(200) DEFAULT NULL;    --�f�B���N�g�����{�t�@�C�����A���l
    lt_dir_path     all_directories.directory_path%TYPE DEFAULT NULL; --�f�B���N�g���p�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --���ږ���
              , flv.attribute1          attribute1 --���ڂ̒���
              , flv.attribute2          attribute2 --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          attribute3 --�K�{�t���O
              , flv.attribute4          attribute4 --����
              , flv.attribute5          attribute5 --�؎̂ăt���O
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_artrx --�d�q���덀�ڃ`�F�b�N�iAR����j
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        = cv_flag_y
      AND       flv.language            = cv_lang
      ORDER BY  flv.lookup_code
      ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => iv_trx_type           -- �^�C�v
      ,iv_conc_param4  => iv_trx_number         -- AR����ԍ�
      ,iv_conc_param5  => iv_id_from            -- AR���ID�iFrom�j
      ,iv_conc_param6  => iv_id_to              -- AR���ID�iTo�j
      ,iv_conc_param7  => iv_exec_kbn           -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ���O�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => iv_trx_type           -- �^�C�v
      ,iv_conc_param4  => iv_trx_number         -- AR����ԍ�
      ,iv_conc_param5  => iv_id_from            -- AR���ID�iFrom�j
      ,iv_conc_param6  => iv_id_to              -- AR���ID�iTo�j
      ,iv_conc_param7  => iv_exec_kbn           -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==============================================================
    -- ���̓p�����[�^�ݒ�
    --==============================================================
    --AR���ID(From-To)�̒l�𐔒l�^�ϐ��Ɋi�[
    gn_id_from := TO_NUMBER(iv_id_from);
    gn_id_to   := TO_NUMBER(iv_id_to);
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- �蓮���s('1')�̏ꍇ�A�`�F�b�N���s��
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --�@AR����ԍ��AAR���ID(From-To)����
      IF ( ( iv_trx_number IS NULL ) AND ( gn_id_from IS NULL ) AND ( gn_id_to IS NULL ) )
      --�AAR����ԍ��AAR���ID(From-To)���S�Ēl����
      OR ( ( iv_trx_number IS NOT NULL ) AND ( gn_id_from IS NOT NULL ) AND ( gn_id_to IS NOT NULL ) )
      THEN
        --�`�F�b�N�@�A�A�̂ǂ��炩�ɍ��v�����ꍇ�A�G���[�Ƃ���
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_cfo_10004    -- �p�����[�^���͕s��
                                                      ,cv_tkn_param        -- 'PARAM'
                                                      ,cv_msgtkn_cfo_11045 -- AR����ԍ��AAR���ID(From�|To)
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
      --
      --AR���ID(From-To)�ǂ��炩���󔒂��AFrom>To�̏ꍇ�A�G���[�Ƃ���
      IF ( ( gn_id_from IS NOT NULL ) AND ( gn_id_to IS NULL ) )
      OR ( ( gn_id_from IS NULL ) AND ( gn_id_to IS NOT NULL ) )
      OR ( gn_id_from > gn_id_to )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_cfo_10008    -- �p�����[�^ID���͕s��
                                                      ,cv_tkn_param1       -- 'PARAM1'
                                                      ,cv_msgtkn_cfo_11046 -- AR���ID(From)
                                                      ,cv_tkn_param2       -- 'PARAM2'
                                                      ,cv_msgtkn_cfo_11047 -- AR���ID(To)
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- �Ɩ����t�擾�G���[
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �A�g�����p���t�擾
    --==============================================================
    gv_coop_date := TO_CHAR(SYSDATE, cv_date_format_ymdhms);
--
    --==================================
    -- �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p)���̎擾
    --==================================
    OPEN get_chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- �Ώی����̃Z�b�g
    gn_item_cnt := gt_item_name.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
    --
    IF ( gn_item_cnt = 0 ) THEN
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_artrx -- 'XXCFO1_ELECTRIC_ITEM_CHK_ARTRX'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- �N�C�b�N�R�[�h
    --==================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    flv.attribute1 -- �d�q���돈�����s����
              , flv.attribute2 -- �����Ώێ���
      INTO      gt_electric_exec_days
              , gt_proc_target_time
      FROM      fnd_lookup_values  flv
      WHERE     flv.lookup_type    = cv_lookup_book_date
      AND       flv.lookup_code    = cv_pkg_name
      AND       gd_process_date    BETWEEN NVL(flv.start_date_active, gd_process_date)
                                   AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag   = cv_flag_y
      AND       flv.language       = cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_book_date     -- 'XXCFO1_ELECTRIC_BOOK_DATE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    --�t�@�C���i�[�p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_data_filepath -- 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --��v����ID
    gn_set_of_bks_id  := FND_PROFILE.VALUE( cv_set_of_bks_id );
    --
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_set_of_bks_id -- 'GL_SET_OF_BKS_ID'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �c�ƒP��
    gt_org_id   :=  FND_PROFILE.VALUE(cv_org_id);
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_org_id        -- 'ORG_ID'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�t�@�C����
    IF ( iv_file_name IS NOT NULL ) THEN
      --�p�����[�^�u�t�@�C�����v�����͍ς̏ꍇ�́A���͒l���t�@�C�����Ƃ��Ďg�p
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
      --�p�����[�^�u�t�@�C�����v�������͂ŁA�ǉ��X�V�敪��'�ǉ�(0)'�̏ꍇ
      --�v���t�@�C������u�ǉ��t�@�C�����v���擾
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_add_filename  -- 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_I_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --�p�����[�^�u�t�@�C�����v�������͂ŁA�ǉ��X�V�敪��'�X�V(1)'�̏ꍇ
      --�v���t�@�C������u�X�V�t�@�C�����v���擾
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_upd_filename  -- 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_U_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- �f�B���N�g���p�X�擾�G���[
                                                    ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                    ,gt_file_path     -- �t�@�C���i�[�p�X
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IF�t�@�C�����o��
    --==================================
    --�擾�����f�B���N�g���p�X�̖�����'/'(�X���b�V��)�����݂���ꍇ�A
    --�f�B���N�g���ƃt�@�C�����̊Ԃ�'/'�A���͍s�킸�Ƀt�@�C�������o�͂���
    IF  SUBSTRB(lt_dir_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  lt_dir_path || gv_file_name;
    ELSE
      lv_full_name :=  lt_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                               ,cv_msg_cfo_00002 -- �t�@�C�����o�̓��b�Z�[�W
                                               ,cv_tkn_file_name -- 'FILE_NAME'
                                               ,lv_full_name     -- �i�[�p�X�ƃt�@�C�����̘A������
                                              )
                      ,1
                      ,5000);
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- ����t�@�C�����݃`�F�b�N
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
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- ����t�@�C������
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_wait_coop
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_ar_wait_coop(
    iv_exec_kbn   IN  VARCHAR2,     --   ����蓮�敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_wait_coop'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
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
    --==============================================================
    -- ������A�g�f�[�^�擾
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
    --������s�̏ꍇ�A���b�N�擾�p�J�[�\���I�[�v��
      --�J�[�\���I�[�v��
      OPEN ar_trx_wait_coop_lock_cur;
      FETCH ar_trx_wait_coop_lock_cur BULK COLLECT INTO ar_trx_wait_coop_tab;
      --�J�[�\���N���[�Y
      CLOSE ar_trx_wait_coop_lock_cur;
    ELSE
      --�J�[�\���I�[�v��
      OPEN ar_trx_wait_coop_cur;
      FETCH ar_trx_wait_coop_cur BULK COLLECT INTO ar_trx_wait_coop_tab;
      --�J�[�\���N���[�Y
      CLOSE ar_trx_wait_coop_cur;
    END IF;
    --
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                    ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                    ,cv_msgtkn_cfo_11055   -- AR������A�g�e�[�u��
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ar_trx_wait_coop_lock_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_lock_cur;
      END IF;
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
      -- �J�[�\���N���[�Y
      IF ar_trx_wait_coop_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ar_trx_wait_coop_lock_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_lock_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_trx_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_ar_trx_control(
    iv_exec_kbn   IN  VARCHAR2,     --   ����蓮�敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_trx_control'; -- �v���O������
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
    ln_dummy_adjustment_id NUMBER; --���b�N�pINTO��_�~�[�ϐ�
--
    -- *** ���[�J���ϐ� ***
    --�Ǘ��f�[�^����ID�A���o�^�����p
    lt_ar_header_id_from   xxcfo_ar_trx_control.customer_trx_id%TYPE;
    lt_ar_adj_id_from      xxcfo_ar_adj_control.adjustment_id%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ����Ǘ��f�[�^�J�[�\��(���������)
    CURSOR ar_trx_control_cur
    IS
      SELECT xatc.customer_trx_id       -- ����w�b�_ID
      FROM   xxcfo_ar_trx_control xatc  -- ����Ǘ�
      WHERE  xatc.process_flag = cv_flag_n
      ORDER BY xatc.customer_trx_id DESC
              ,xatc.creation_date   DESC
      ;
--
    -- ����Ǘ��f�[�^�J�[�\��(���������)_���b�N�p
    CURSOR ar_trx_control_lock_cur
    IS
      SELECT xatc.customer_trx_id       -- ����w�b�_ID
      FROM   xxcfo_ar_trx_control xatc  -- ����Ǘ�
      WHERE  xatc.process_flag = cv_flag_n
      ORDER BY xatc.customer_trx_id DESC
              ,xatc.creation_date   DESC
      FOR UPDATE NOWAIT
      ;
--
    -- ���R�[�h�^
    TYPE ar_trx_control_rec IS RECORD(
      customer_trx_id  xxcfo_ar_trx_control.customer_trx_id%TYPE
    );
    -- �e�[�u���^
    TYPE ar_trx_control_ttype IS TABLE OF ar_trx_control_rec INDEX BY BINARY_INTEGER;
    ar_trx_control_tab  ar_trx_control_ttype;
--
    -- �C���Ǘ��f�[�^�J�[�\��(���������)_���b�N�p
    CURSOR ar_adj_control_lock_cur
    IS
      SELECT cv_x
      FROM   xxcfo_ar_adj_control xaac  -- �C���Ǘ�
      WHERE  xaac.process_flag = cv_flag_n
      FOR UPDATE NOWAIT
      ;
    --���R�[�h�^
    TYPE ar_adj_control_lock_ttype IS TABLE OF ar_adj_control_lock_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    ar_adj_control_lock_tab ar_adj_control_lock_ttype;
--
    -- ===============================
    -- ���[�J����`��O
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
    --�����ύő����w�b�_ID�擾(From)
    --==============================================================
    -- ����Ǘ��f�[�^�J�[�\��(�ŐV�̏����ώ��)
    SELECT MAX(xatc.customer_trx_id) customer_trx_id -- ����w�b�_ID
    INTO   gt_ar_header_id_from
    FROM   xxcfo_ar_trx_control xatc  -- ����Ǘ�
    WHERE  xatc.process_flag = cv_flag_y
    ;
    IF ( gt_ar_header_id_from IS NULL ) THEN
    --���o���ʂ�0��(NULL)�̏ꍇ�A���b�Z�[�W���o�͂��A�G���[�I��
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11050 --AR����Ǘ��e�[�u��
                                                    )
                            ,1
                            ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --�擾����AR����w�b�_ID�Ɂ{�P���Z���A���o������AR����w�b�_ID(From)�Ƃ���
    gt_ar_header_id_from := gt_ar_header_id_from + 1;
--
    --==============================================================
    --����������w�b�_ID�擾(To)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        --������s�̏ꍇ�A���b�N�p�J�[�\���I�[�v��
        OPEN ar_trx_control_lock_cur;
        FETCH ar_trx_control_lock_cur BULK COLLECT INTO ar_trx_control_tab;
        --�J�[�\���N���[�Y
        CLOSE ar_trx_control_lock_cur;
      EXCEPTION
        -- *** ���b�N�G���[��O�n���h�� ***
        WHEN global_lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                        ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                        ,cv_msgtkn_cfo_11050   -- AR����Ǘ��e�[�u��
                                                       )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          -- �J�[�\���N���[�Y
          IF ar_trx_control_lock_cur%ISOPEN THEN
            CLOSE ar_trx_control_lock_cur;
          END IF;
          RAISE global_process_expt;
      END;
    ELSE
      --�蓮���s�̏ꍇ�A���b�N�����J�[�\���I�[�v��
      OPEN ar_trx_control_cur;
      FETCH ar_trx_control_cur BULK COLLECT INTO ar_trx_control_tab;
      --�J�[�\���N���[�Y
      CLOSE ar_trx_control_cur;
    END IF;
    --
    IF ( ar_trx_control_tab.COUNT = 0 ) THEN
      -- �擾�Ώۃf�[�^����
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11050 --AR����Ǘ��e�[�u��
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
    --
    IF ( ar_trx_control_tab.COUNT < gt_electric_exec_days ) THEN
      --�擾�����Ǘ��f�[�^�������A�d�q���돈�����s�����������ꍇ�A�w�b�_ID(To)��NULL��ݒ肷��
      gt_ar_header_id_to := NULL;
    ELSE
      --�d�q���돈�����s�������k�����Ǘ��f�[�^�̃w�b�_ID���擾
      gt_ar_header_id_to := ar_trx_control_tab( gt_electric_exec_days ).customer_trx_id;
    END IF;
    --
    --From��To��ID�l���召�t�ɂȂ��Ă���ꍇ(�Ǘ��e�[�u���ɁA����ID�Ő���o�^���ꂽ�ꍇ)�A
    --To�̒l��From�ɑ������
    IF ( gt_ar_header_id_from > gt_ar_header_id_to ) THEN
      lt_ar_header_id_from := gt_ar_header_id_to;
    ELSE
      lt_ar_header_id_from := gt_ar_header_id_from;
    END IF;
    --�擾����From-To��RowID���擾(A-9�Ŏg�p)
    OPEN upd_rowid_cur(lt_ar_header_id_from);
    FETCH upd_rowid_cur BULK COLLECT INTO upd_rowid_tab;
    CLOSE upd_rowid_cur;
--
    --==============================================================
    --�����ύő�C��ID�擾(From)
    --==============================================================
    SELECT MAX(xaac.adjustment_id) adjustment_id -- �C��ID
    INTO   gt_ar_adj_id_from
    FROM   xxcfo_ar_adj_control xaac  -- �C���Ǘ�
    WHERE  xaac.process_flag = cv_flag_y
    ;
--
    IF ( gt_ar_adj_id_from IS NULL ) THEN
    --���o���ʂ�0��(NULL)�̏ꍇ�A�x���o��
      ov_retcode := cv_status_warn;
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11051 --AR�C���Ǘ��e�[�u��
                                                    )
                            ,1
                            ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --�擾����AR�C��ID�Ɂ{�P���Z���A���o������AR�C��ID(From)�Ƃ���
    gt_ar_adj_id_from := gt_ar_adj_id_from + 1;
--
    --==============================================================
    --�������ő�C��ID�擾(To)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�A���b�N���擾
      --��MAX�֐����g�p���Ă���SQL�̓��b�N���o���Ȃ��ׁAMAX�l�擾��A�㑱SQL�ɂă��b�N�擾
      BEGIN
        SELECT MAX(xaac.adjustment_id) adjustment_id -- �C��ID
        INTO   gt_ar_adj_id_to
        FROM   xxcfo_ar_adj_control xaac  -- �C���Ǘ�
        WHERE  xaac.process_flag = cv_flag_n
        ;
        --���b�N�擾�p�J�[�\���I�[�v��
        OPEN ar_adj_control_lock_cur;
        FETCH ar_adj_control_lock_cur BULK COLLECT INTO ar_adj_control_lock_tab;
        --�J�[�\���N���[�Y
        CLOSE ar_adj_control_lock_cur;
      EXCEPTION
        -- *** ���b�N�G���[��O�n���h�� ***
        WHEN global_lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                        ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                        ,cv_msgtkn_cfo_11051   -- AR�C���Ǘ��e�[�u��
                                                       )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
    ELSE
      --�蓮���s�̏ꍇ�A���b�N����
      SELECT MAX(xaac.adjustment_id) adjustment_id -- �C��ID
      INTO   gt_ar_adj_id_to
      FROM   xxcfo_ar_adj_control xaac  -- �C���Ǘ�
      WHERE  xaac.process_flag = cv_flag_n
      ;
    END IF;
--
    IF ( gt_ar_adj_id_to IS NULL ) THEN
    --���o���ʂ�0��(NULL)�̏ꍇ
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11051 --AR�C���Ǘ��e�[�u��
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
    --
    --From��To��ID�l���召�t�ɂȂ��Ă���ꍇ(�Ǘ��e�[�u���ɁA����ID�Ő���o�^���ꂽ�ꍇ)�A
    --To�̒l��From�ɑ������
    IF ( gt_ar_adj_id_from > gt_ar_adj_id_to ) THEN
      lt_ar_adj_id_from := gt_ar_adj_id_to;
    ELSE
      lt_ar_adj_id_from := gt_ar_adj_id_from;
    END IF;
    --�擾����From-To��RowID���擾(A-9�Ŏg�p)
    OPEN upd_rowid_adj_cur( lt_ar_adj_id_from );
    FETCH upd_rowid_adj_cur BULK COLLECT INTO upd_rowid_adj_tab;
    CLOSE upd_rowid_adj_cur;
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
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
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
      -- �J�[�\���N���[�Y
      IF ar_trx_control_lock_cur%ISOPEN THEN
        CLOSE ar_trx_control_lock_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ar_trx_control_cur%ISOPEN THEN
        CLOSE ar_trx_control_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF upd_rowid_cur%ISOPEN THEN
        CLOSE upd_rowid_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ar_adj_control_lock_cur%ISOPEN THEN
        CLOSE ar_adj_control_lock_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF upd_rowid_adj_cur%ISOPEN THEN
        CLOSE upd_rowid_adj_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_trx_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_ar_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ar_wait_coop(
    iv_meaning      IN VARCHAR2,    -- 2.�G���[���e
    iv_exec_kbn     IN VARCHAR2,    -- 3.����蓮�敪
    iv_id_value     IN VARCHAR2,    --   ID�l(AR�C��ID/AR���ID)
    iv_tkn_id_name  IN VARCHAR2,    --   ID����(AR�C��ID/AR���ID)�����b�Z�[�W�o�͗p    
    ov_errbuf      OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode     OUT VARCHAR2,    --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg      OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ar_wait_coop'; -- �v���O������
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
    --���b�Z�[�W�o��(���A�g�f�[�^�o�^���b�Z�[�W)
    --==============================================================
    IF ( iv_meaning IS NOT NULL ) THEN
      --A-5�̍��ڃ`�F�b�N�֐��G���[�̏ꍇ�ɂ̂ݏo��
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10007 -- ���A�g�f�[�^�o�^
                                                     ,cv_tkn_cause     -- 'CAUSE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11008) -- '���ڂ��s��'
                                                     ,cv_tkn_target    -- 'TARGET'
                                                     ,iv_tkn_id_name || cv_par_start || iv_id_value || cv_par_end --ID
                                                     ,cv_tkn_meaning   -- 'MEANING'
                                                     ,iv_meaning       -- �`�F�b�N�G���[���b�Z�[�W
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�̂ݓo�^���s��
      --==============================================================
      --���A�g�e�[�u���o�^
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_ar_wait_coop(
           journal_type           -- �^�C�v
          ,trx_id                 -- AR���ID
--2012/10/18 ADD Start
          ,trx_line_number        -- AR������הԍ�
          ,applied_trx_id         -- �����Ώێ��ID
--2012/10/18 ADD End
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
           gt_data_tab(1)
          ,TO_NUMBER(iv_id_value)
--2012/10/18 ADD Start
          ,gt_data_tab(14)
          ,gt_data_tab(37)
--2012/10/18 ADD End
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
        --���A�g�o�^�����J�E���g
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
        --
        --�X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
        --�x���t���O��'Y'�ɐݒ肷��
        gv_warning_flg := cv_flag_y;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                       ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,cv_msgtkn_cfo_11055 -- AR������A�g�e�[�u��
                                                       ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                       ,SQLERRM            -- SQL�G���[���b�Z�[�W
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
  END ins_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn        IN  VARCHAR2,   --   �ǉ��X�V�敪
    iv_exec_kbn           IN  VARCHAR2,   --   ����蓮�敪
    iv_type               IN  VARCHAR2,   --   �^�C�v
    iv_id_value           IN  VARCHAR2,   --   ID�l(AR�C��ID/AR���ID)
    iv_tkn_id_name        IN  VARCHAR2,   --   ID����(AR�C��ID/AR���ID)�����b�Z�[�W�o�͗p    
    iv_ar_id_from         IN  VARCHAR2,   --   ID�l(A-3�ɂĎ擾����From�l)
    ov_msgcode            OUT VARCHAR2,   --   ���b�Z�[�W�R�[�h
    ov_item_chk           OUT VARCHAR2,   --   ���ڃ`�F�b�N�̎��{�L���t���O
    ov_errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_item'; -- �v���O������
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
    -- ���[�J����`��O
    -- ===============================
    warn_expt        EXCEPTION; --�����r��(�x��������)�Ń��W�b�N�𔲂���ׂɎg�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    --����Ǎ��܂��́A�O��Ǎ����̃w�b�_ID�ƌ��Ǎ��s�̃w�b�_ID���قȂ�ꍇ
    --�ȉ��̃w�b�_�P�ʂ̃`�F�b�N���s��
    IF ( iv_exec_kbn = cv_exec_manual ) THEN --�蓮���s�̏ꍇ
      --==============================================================
      -- ���A�g�f�[�^���݃`�F�b�N
      --==============================================================
      <<ar_trx_wait_chk_loop>>
      FOR i IN 1 .. ar_trx_wait_coop_tab.COUNT LOOP
        --���A�g�f�[�^��ID��A-4�Ŏ擾����ID(AR�C��ID/AR���ID)���r
        IF ( ar_trx_wait_coop_tab( i ).journal_type = iv_type )
        AND ( ar_trx_wait_coop_tab( i ).trx_id = iv_id_value ) THEN
          --�Ώێ�������A�g�̏ꍇ�A�x�����b�Z�[�W���o��
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10010      -- ���A�g�f�[�^�`�F�b�NID�G���[
                                 ,cv_tkn_doc_data       -- �g�[�N��'DOC_DATA'
                                 ,iv_tkn_id_name        -- ID����(AR�C��ID/AR���ID)
                                 ,cv_tkn_doc_dist_id    -- �g�[�N��'DOC_DIST_ID'
                                 ,iv_id_value           -- ID�l
                                 )
                               ,1
                               ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          RAISE warn_expt;
        END IF;
      END LOOP;
      --
      IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        --�蓮���s���A�X�V�̏ꍇ
        --==============================================================
        --�����σ`�F�b�N
        --==============================================================
        --�����������ΏۂƂ��Ă��邩����
        --�uA-3�ɂĎ擾����From�l <= ID�l(A-4�ɂĎ擾(AR�C��ID/AR���ID))�v
        IF ( iv_ar_id_from <= iv_id_value ) THEN
          --������������X�V�����̑ΏۂƂ��Ă���ׁA�G���[�Ƃ���
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10006      -- �͈͎w��G���[
                                 ,cv_tkn_max_id         -- �g�[�N��'MAX_ID'
                                 ,(iv_ar_id_from -1 )   -- �����ώ����MAXID
                                 )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- ���]�L�`�F�b�N
    --==============================================================
    IF ( gt_data_tab(50) IS NULL ) THEN
      --���]�L(�]�L�������ݒ�)�̏ꍇ�A�ȉ��̏������s��
      --==============================================================
      --���]�L���b�Z�[�W�o��
      --==============================================================
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                              cv_msg_kbn_cfo        -- XXCFO
                             ,cv_msg_cfo_10005      -- �d�󖢓]�L���b�Z�[�W
                             ,cv_tkn_key_item       -- �g�[�N��'KEY_ITEM'
                             ,iv_tkn_id_name        -- ID����(AR�C��ID/AR���ID)
                             ,cv_tkn_key_value      -- �g�[�N��'KEY_VALUE'
                             ,iv_id_value           -- ID�l(AR�C��ID/AR���ID)
                             )
                           ,1
                           ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        --������s�̏ꍇ�̂݁A���A�g�o�^���s��
        --==============================================================
        --���A�g�e�[�u���o�^����(A-7)
        --==============================================================
        ins_ar_wait_coop(
          iv_meaning                  =>        NULL                -- A-5�̃��[�U�[�G���[���b�Z�[�W
        , iv_exec_kbn                 =>        iv_exec_kbn         -- ����蓮�敪
        , iv_id_value                 =>        iv_id_value         -- ID�l(AR�C��ID/AR���ID)
        , iv_tkn_id_name              =>        iv_tkn_id_name      -- ID����(AR�C��ID/AR���ID)
        , ov_errbuf                   =>        lv_errbuf     -- �G���[���b�Z�[�W
        , ov_retcode                  =>        lv_retcode    -- ���^�[���R�[�h
        , ov_errmsg                   =>        lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      RAISE warn_expt; --�x���I��
    END IF;
--
    --==============================================================
    -- ���ڌ��`�F�b�N
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --���ږ���
        , iv_item_value                 =>        gt_data_tab(ln_cnt)                --�ύX�O�̒l
        , in_item_len                   =>        gt_item_len(ln_cnt)               --���ڂ̒���
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --�K�{�t���O
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --���ڑ���
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --�؎̂ăt���O
        , ov_item_value                 =>        gt_data_tab(ln_cnt)                --���ڂ̒l
        , ov_errbuf                     =>        lv_errbuf                         --�G���[���b�Z�[�W
        , ov_retcode                    =>        lv_retcode                        --���^�[���R�[�h
        , ov_errmsg                     =>        lv_errmsg                         --���[�U�[�E�G���[���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_item_chk         := cv_flag_y; --���ڃ`�F�b�N���{
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;        --�߂胁�b�Z�[�W�R�[�h
        ov_errmsg           := lv_errmsg;        --�߂胁�b�Z�[�W
        EXIT; --LOOP�𔲂���
      ELSIF ( lv_retcode = cv_status_error ) THEN
        ov_errmsg   := lv_errmsg;
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
--
    -- *** �x���n���h�� ***
    WHEN warn_expt THEN
      gv_warning_flg := cv_flag_y; --�x���t���O(Y)
      lv_errbuf   := lv_errmsg;
      ov_item_chk := cv_flag_n; --���ڃ`�F�b�N�����{
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn; --�x��
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
   * Description      : �b�r�u�o�͏���(A-6)
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
    lv_file_data              VARCHAR2(30000);
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
    --�f�[�^�ҏW
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP --�ŏI���ځu�`�F�b�N�pGL�]�L���v�͏o�͂��Ȃ�
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), cv_quot, ' '), cv_delimit, ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --�A�g����
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(49);
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,lv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END;
    --���������J�E���g
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
   * Procedure Name   : get_ar_trx
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_ar_trx(
    iv_ins_upd_kbn IN VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_trx_type    IN VARCHAR2, -- 2.�^�C�v
    iv_trx_number  IN VARCHAR2, -- 3.AR����ԍ�
    iv_exec_kbn    IN VARCHAR2, -- 4.����蓮�敪
    ov_errbuf     OUT VARCHAR2, --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2, --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_trx'; -- �v���O������
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
    cv_sarch_line             CONSTANT VARCHAR2(5) := 'LINE'; -- ���o����������'LINE'
    cv_sarch_tax              CONSTANT VARCHAR2(3) := 'TAX';  -- ���o����������'TAX'
    cv_sarch_rec              CONSTANT VARCHAR2(3) := 'REC';  -- ���o����������'REC'
    cv_sarch_app              CONSTANT VARCHAR2(3) := 'APP';  -- ���o����������'APP'
    cv_sarch_cm               CONSTANT VARCHAR2(2) := 'CM';   -- ���o����������'CM'
    cv_sarch_ja               CONSTANT VARCHAR2(2) := 'JA';   -- ���o����������'JA'
    cv_trx_type_inv           CONSTANT VARCHAR2(3) := 'INV';  -- �^�C�v�uINV�v
--
    -- *** ���[�J���ϐ� ***
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-6�̖߂胁�b�Z�[�W�R�[�h(�^���`�F�b�N)
    lv_item_chk               VARCHAR2(10) DEFAULT cv_flag_n;  --���ڃ`�F�b�N�t���O(Y�F���{ N:�����{)
    --�^�C�v�ʖ���/ID�l�i�[�p(�C��/�C���ȊO)
    lv_tkn_id_name            VARCHAR2(10) DEFAULT NULL; --ID����(AR�C��ID/AR���ID)���b�Z�[�W�o�͗p
    lv_id_value               VARCHAR2(15) DEFAULT NULL; --ID�l(AR�C��ID/AR���ID)��A-4�����̎擾�l���i�[
    lv_type                   VARCHAR2(30) DEFAULT NULL; --�^�C�v(AR�C��ID/AR���ID)��A-4�����̎擾�l���i�[
    --�f�[�^���o���������i�[�p
    lt_type_adj               fnd_lookup_values.description%TYPE; --�C��
    lt_type_trx               fnd_lookup_values.description%TYPE; --���
    lt_type_cm                fnd_lookup_values.description%TYPE; --�N������
    lt_type_cm_apply          fnd_lookup_values.description%TYPE; --�N����������
    lt_type_sales_doc         fnd_lookup_values.description%TYPE; --���㐿����
    lt_type_credit_memo       fnd_lookup_values.description%TYPE; --�N���W�b�g�E����
    lt_type_credit_memo_apply fnd_lookup_values.description%TYPE; --�N���W�b�gMEMO����
    --���ڃ`�F�b�N(A-5)�i�[�p
    lv_ar_id_from             VARCHAR2(15) DEFAULT NULL; --A-3�ɂĎ擾����ID�l(From)
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --�蓮���s�p�iAR����ԍ��w��j
    CURSOR get_ar_trx_manual_number_cur( iv_trx_type   IN VARCHAR2
                                        ,iv_trx_number IN VARCHAR2)
    IS
      SELECT /*+ LEADING(rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- �^�C�v('INV','���','�N������')
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- �����
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,ttype.name                                  AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,rctl.line_number                            AS line_number             -- ���הԍ�
            ,rctl.description                            AS description             -- �������דE�v
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- ����
            ,rctl.unit_selling_price                     AS unit_selling_price      -- �P��
            ,rctl.extended_amount                        AS extended_amount         -- ���z
            ,tax.tax_code                                AS tax_code                -- �ŃR�[�h
            ,rctl2.extended_amount                       AS tax_extended_amount     -- �Ŋz
            ,rctl.interface_line_attribute3              AS invoice_num             -- �[�i���ԍ�
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- �̔�����ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ra_customer_trx_lines_all         rctl   -- �������1(���׃f�[�^)
           ,ra_customer_trx_lines_all         rctl2  -- �������2(�Ŋz)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��(�@�\�ʉݐ������z)
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_vat_tax_all_vl                 tax    -- �ŃR�[�h
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
                   ,temp.name
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --����^�C�v
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND ( (lt_type_sales_doc         = iv_trx_type
             AND ttype.type            = cv_trx_type_inv)-- ����^�C�v�w��(���㐿����)
           OR (lt_type_credit_memo     = iv_trx_type
             AND ttype.type            = cv_sarch_cm)-- ����^�C�v�w��(�N���W�b�g�E����)
          )
      AND rct.trx_number = iv_trx_number        -- ����ԍ��w��
      --�^�C�v���u���㐿�����v�A�u�N�������v�̎�����ƁA�^�C�v���u�N�����������v�̎����UNION
      UNION ALL
      SELECT /*+ LEADING(rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
             lt_type_cm_apply                            AS type                    -- �^�C�v(�N����������)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- �����
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- ������
            ,hcab2.account_number                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,hpb2.party_name                             AS applied_party_name      -- �����Ώې�����ڋq��
            ,araa.amount_applied                         AS amount_applied          -- �������z
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- �����Ώێ��ID
            ,rct2.trx_number                             AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,NULL                                        AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all            rct    -- ����w�b�_(���)
           ,ra_customer_trx_all            rct2   -- ����w�b�_2(�����Ώێ��)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- ����z��
           ,ar_receivable_applications_all araa   -- ��������
           ,hz_cust_accounts               hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts               hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_cust_accounts               hcab2  -- �ڋq�}�X�^3(�����Ώې�����ڋq)
           ,hz_parties                     hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                     hps    -- �p�[�e�B2(�[�i��ڋq)
           ,hz_parties                     hpb2   -- �p�[�e�B3(�����Ώې�����ڋq)
           ,gl_daily_conversion_types      gdct   -- GL���[�g
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --��v����ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hpb2.party_id                = hcab2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   lt_type_credit_memo_apply    = iv_trx_type -- ����^�C�v�w��
      AND rct.trx_number = iv_trx_number        -- ����ԍ��w��
      --�^�C�v���u�N�����������v�̎�����ƁA�^�C�v���u�C���v�̎����UNION
      UNION ALL
      SELECT 
             lt_type_adj                                 AS type                    -- �^�C�v
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- �����
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,aj.adjustment_id                            AS adjustment_id           -- �C��ID
            ,aj.adjustment_number                        AS adjustment_number       -- �C���ԍ�
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �C�������ԍ�
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- �C����
            ,arta.name                                   AS act_name                -- ��������
            ,aj.type                                     AS adj_type                -- �C���^�C�v
            ,aj.amount                                   AS adj_amount              -- �C�����z
            ,ajr.meaning                                 AS meaning                 -- ���R
            ,aj.comments                                 AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,aj.acctd_amount                             AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,aj.acctd_amount                             AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ar_adjustments_all                aj     -- ����C��
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_payment_schedules_all          aps    -- AR�x���v��
           ,ar_receivables_trx_all            arta   -- ���|/����������
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                AJR 
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   lt_type_adj             = iv_trx_type -- ����^�C�v�w��
      AND   rct.trx_number = iv_trx_number        -- ����ԍ��w��
      ;
--
    --�蓮���s�p�iAR���ID�w��j
    CURSOR get_ar_trx_manual_id_cur( iv_trx_type   IN VARCHAR2
                                    ,gn_id_from    IN NUMBER
                                    ,gn_id_to      IN NUMBER)
    IS
      SELECT /*+ LEADING(rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- �^�C�v('INV','���','�N������')
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- �����
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,ttype.name                                  AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,rctl.line_number                            AS line_number             -- ���הԍ�
            ,rctl.description                            AS description             -- �������דE�v
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- ����
            ,rctl.unit_selling_price                     AS unit_selling_price      -- �P��
            ,rctl.extended_amount                        AS extended_amount         -- ���z
            ,tax.tax_code                                AS tax_code                -- �ŃR�[�h
            ,rctl2.extended_amount                       AS tax_extended_amount     -- �Ŋz
            ,rctl.interface_line_attribute3              AS invoice_num             -- �[�i���ԍ�
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- �̔�����ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ra_customer_trx_lines_all         rctl   -- �������1(���׃f�[�^)
           ,ra_customer_trx_lines_all         rctl2  -- �������2(�Ŋz)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��(�@�\�ʉݐ������z)
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_vat_tax_all_vl                 tax    -- �ŃR�[�h
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
                   ,temp.name
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --����^�C�v
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND ( (lt_type_sales_doc         = iv_trx_type
             AND ttype.type            = cv_trx_type_inv)-- ����^�C�v�w��(���㐿����)
           OR (lt_type_credit_memo     = iv_trx_type
             AND ttype.type            = cv_sarch_cm)-- ����^�C�v�w��(�N���W�b�g�E����)
          )
      AND   rct.customer_trx_id >= gn_id_from   -- AR���ID�iFrom-To)�w��
      AND   rct.customer_trx_id <= gn_id_to     -- AR���ID�iFrom-To)�w��
      --�^�C�v���u���㐿�����v�A�u�N�������v�̎�����ƁA�^�C�v���u�N�����������v�̎����UNION
      UNION ALL
      SELECT /*+ LEADING(rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
             lt_type_cm_apply                            AS type                    -- �^�C�v(�N����������)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- �����
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- ������
            ,hcab2.account_number                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,hpb2.party_name                             AS applied_party_name      -- �����Ώې�����ڋq��
            ,araa.amount_applied                         AS amount_applied          -- �������z
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- �����Ώێ��ID
            ,rct2.trx_number                             AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,NULL                                        AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all            rct    -- ����w�b�_(���)
           ,ra_customer_trx_all            rct2   -- ����w�b�_2(�����Ώێ��)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- ����z��
           ,ar_receivable_applications_all araa   -- ��������
           ,hz_cust_accounts               hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts               hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_cust_accounts               hcab2  -- �ڋq�}�X�^3(�����Ώې�����ڋq)
           ,hz_parties                     hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                     hps    -- �p�[�e�B2(�[�i��ڋq)
           ,hz_parties                     hpb2   -- �p�[�e�B3(�����Ώې�����ڋq)
           ,gl_daily_conversion_types      gdct   -- GL���[�g
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --��v����ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hpb2.party_id                = hcab2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   lt_type_credit_memo_apply    = iv_trx_type -- ����^�C�v�w��
      AND   rct.customer_trx_id >= gn_id_from   -- AR���ID�iFrom-To)�w��
      AND   rct.customer_trx_id <= gn_id_to     -- AR���ID�iFrom-To)�w��
      --�^�C�v���u�N�����������v�̎�����ƁA�^�C�v���u�C���v�̎����UNION
      UNION ALL
      SELECT 
             lt_type_adj                                 AS type                    -- �^�C�v
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- �����
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,aj.adjustment_id                            AS adjustment_id           -- �C��ID
            ,aj.adjustment_number                        AS adjustment_number       -- �C���ԍ�
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �C�������ԍ�
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- �C����
            ,arta.name                                   AS act_name                -- ��������
            ,aj.type                                     AS adj_type                -- �C���^�C�v
            ,aj.amount                                   AS adj_amount              -- �C�����z
            ,ajr.meaning                                 AS meaning                 -- ���R
            ,aj.comments                                 AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,aj.acctd_amount                             AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,aj.acctd_amount                             AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ar_adjustments_all                aj     -- ����C��
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_payment_schedules_all          aps    -- AR�x���v��
           ,ar_receivables_trx_all            arta   -- ���|/����������
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                AJR 
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   lt_type_adj             = iv_trx_type -- ����^�C�v�w��
      AND   aj.adjustment_id        >= gn_id_from   -- AR���ID�iFrom-To)�w��
      AND   aj.adjustment_id        <= gn_id_to     -- AR���ID�iFrom-To)�w��
      ;
--
    --������s�p
    CURSOR get_ar_trx_fixed_cur( it_ar_header_id_from IN xxcfo_ar_trx_control.customer_trx_id%TYPE
                                ,it_ar_header_id_to   IN xxcfo_ar_trx_control.customer_trx_id%TYPE
                                ,it_ar_adj_id_from    IN xxcfo_ar_adj_control.adjustment_id%TYPE
                                ,it_ar_adj_id_to      IN xxcfo_ar_adj_control.adjustment_id%TYPE)
    IS
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct)
--               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
--               INDEX(rct RA_CUSTOMER_TRX_U1)
--             */
      SELECT /*+ LEADING(xawc rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
--2012/12/18 Ver.1.3 Mod End
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- �^�C�v
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- �����
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,rctl.line_number                            AS line_number             -- ���הԍ�
            ,rctl.description                            AS description             -- �������דE�v
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- ����
            ,rctl.unit_selling_price                     AS unit_selling_price      -- �P��
            ,rctl.extended_amount                        AS extended_amount         -- ���z
            ,tax.tax_code                                AS tax_code                -- �ŃR�[�h
            ,rctl2.extended_amount                       AS tax_extended_amount     -- �Ŋz
            ,rctl.interface_line_attribute3              AS invoice_num             -- �[�i���ԍ�
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- �̔�����ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_1                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ra_customer_trx_lines_all         rctl   -- �������1(���׃f�[�^)
           ,ra_customer_trx_lines_all         rctl2  -- �������2(�Ŋz)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_vat_tax_all_vl                 tax    -- �ŃR�[�h
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --����^�C�v
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc --������A�g
                    WHERE  (xawc.journal_type = lt_type_sales_doc     --'���㐿����'
                      OR    xawc.journal_type = lt_type_credit_memo ) --'�N���W�b�g�E����'
--2012/10/18 MOD Start
--                    AND    xawc.trx_id = rct.customer_trx_id)
                    AND    xawc.trx_id          = rct.customer_trx_id
                    AND    xawc.trx_line_number = rctl.line_number)
--2012/10/18 MOD End
      --�^�C�v���u���㐿�����v�A�u�N�������v�̎�����A�g���ƁA�^�C�v���u�N�����������v�̎�����A�g����UNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct araa)
--                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
--                 INDEX(rct RA_CUSTOMER_TRX_U1)
--                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
--             */
      SELECT /*+ LEADING(xawc rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
--2012/12/18 Ver.1.3 Mod End
             lt_type_cm_apply                            AS type                    -- �^�C�v(�N����������)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- �����
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   apps.ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- ������
            ,hcab2.account_number                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,hpb2.party_name                             AS applied_party_name      -- �����Ώې�����ڋq��
            ,araa.amount_applied                         AS amount_applied          -- �������z
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- �����Ώێ��ID
            ,rct2.trx_number                             AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,NULL                                        AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_1                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all            rct    -- ����w�b�_(���)
           ,ra_customer_trx_all            rct2   -- ����w�b�_2(�����Ώێ��)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- ����z��
           ,ar_receivable_applications_all araa   -- ��������
           ,hz_cust_accounts               hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts               hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_cust_accounts               hcab2  -- �ڋq�}�X�^3(�����Ώې�����ڋq)
           ,hz_parties                     hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                     hps    -- �p�[�e�B2(�[�i��ڋq)
           ,hz_parties                     hpb2   -- �p�[�e�B3(�����Ώې�����ڋq)
           ,gl_daily_conversion_types      gdct   -- GL���[�g
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --��v����ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hcab2.party_id               = hpb2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc --������A�g
                    WHERE  xawc.journal_type = lt_type_credit_memo_apply --'�N���W�b�gMEMO����'
--2012/10/18 MOD Start
--                    AND    xawc.trx_id = rct.customer_trx_id)
                    AND    xawc.trx_id         = rct.customer_trx_id
                    AND    xawc.applied_trx_id = araa.applied_customer_trx_id)
--2012/10/18 MOD End
      --�^�C�v���u�N�����������v�̎�����A�g���ƁA�^�C�v���u�C���v�̎�����A�g����UNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT 
      SELECT /*+ LEADING(xawc) */
--2012/12/18 Ver.1.3 Mod End
             lt_type_adj                                 AS type                    -- �^�C�v(�C��)
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- �����
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,aj.adjustment_id                            AS adjustment_id           -- �C��ID
            ,aj.adjustment_number                        AS adjustment_number       -- �C���ԍ�
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �C�������ԍ�
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- �C����
            ,arta.name                                   AS act_name                -- ��������
            ,aj.type                                     AS adj_type                -- �C���^�C�v
            ,aj.amount                                   AS adj_amount              -- �C�����z
            ,ajr.meaning                                 AS meaning                 -- ���R
            ,aj.comments                                 AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,aj.acctd_amount                             AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,aj.acctd_amount                             AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_1                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ar_adjustments_all                aj     -- ����C��
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_payment_schedules_all          aps    -- AR�x���v��
           ,ar_receivables_trx_all            arta   -- ���|/����������
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv --�N�C�b�N�R�[�h
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                ajr
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc       --������A�g
                    WHERE  xawc.journal_type = lt_type_adj --'�C��'
                    AND    xawc.trx_id = aj.adjustment_id) --�C��ID
      --�^�C�v���u�C���v�̎�����A�g���ƁA�^�C�v���u���㐿�����v�A�u�N�������v�̎����UNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct)
--                 USE_NL(rct rctl rctl2 rctg_h hcab hpb hcas hps aps tax ttype)
--                 INDEX(rct RA_CUSTOMER_TRX_N5)
--              */
--2014/09/26 Ver.1.4 Mod Start
--      SELECT /*+ LEADING(rct)
      SELECT /*+ LEADING(rct rctl rctl2 rctg_h)
                 USE_NL(rct rctl rctl2 rctg_h hcab hpb hcas hps aps tax ttype)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
              */
--2012/12/18 Ver.1.3 Mod End
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- �^�C�v
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- �����
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,rctl.line_number                            AS line_number             -- ���הԍ�
            ,rctl.description                            AS description             -- �������דE�v
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- ����
            ,rctl.unit_selling_price                     AS unit_selling_price      -- �P��
            ,rctl.extended_amount                        AS extended_amount         -- ���z
            ,tax.tax_code                                AS tax_code                -- �ŃR�[�h
            ,rctl2.extended_amount                       AS tax_extended_amount     -- �Ŋz
            ,rctl.interface_line_attribute3              AS invoice_num             -- �[�i���ԍ�
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- �̔�����ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount      -- �@�\�ʉݖ��׋��z
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ra_customer_trx_lines_all         rctl   -- �������1(���׃f�[�^)
           ,ra_customer_trx_lines_all         rctl2  -- �������2(�Ŋz)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_vat_tax_all_vl                 tax    -- �ŃR�[�h
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --����^�C�v
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND   rct.customer_trx_id        >= it_ar_header_id_from --A-3.AR����w�b�_ID(From)
      AND   rct.customer_trx_id        <= it_ar_header_id_to   --A-3.AR����w�b�_ID(To)
      --�^�C�v���u���㐿�����v�A�u�N�������v�̎�����ƁA�^�C�v���u�N�����������v�̎����UNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ USE_NL(araa) INDEX(araa AR_RECEIVABLE_APPLICATIONS_N5)*/
      SELECT /*+ LEADING(rct)
                 USE_NL(araa)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
--2012/12/18 Ver.1.3 Mod End
             lt_type_cm_apply                            AS type                    -- �^�C�v(�N����������)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- �����
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,NULL                                        AS adjustment_id           -- �C��ID
            ,NULL                                        AS adjustment_number       -- �C���ԍ�
            ,NULL                                        AS doc_sequence_value      -- �C�������ԍ�
            ,NULL                                        AS apply_date              -- �C����
            ,NULL                                        AS act_name                -- ��������
            ,NULL                                        AS adj_type                -- �C���^�C�v
            ,NULL                                        AS adj_amount              -- �C�����z
            ,NULL                                        AS meaning                 -- ���R
            ,NULL                                        AS comments                -- ����
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- ������
            ,hcab2.account_number                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,hpb2.party_name                             AS applied_party_name      -- �����Ώې�����ڋq��
            ,araa.amount_applied                         AS amount_applied          -- �������z
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- �����Ώێ��ID
            ,rct2.trx_number                             AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,NULL                                        AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,NULL                                        AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all            rct    -- ����w�b�_
           ,ra_customer_trx_all            rct2   -- ����w�b�_2(�����Ώێ��)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- ����z��
           ,ar_receivable_applications_all araa   -- ��������
           ,hz_cust_accounts               hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts               hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_cust_accounts               hcab2  -- �ڋq�}�X�^3(�����Ώې�����ڋq)
           ,hz_parties                     hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                     hps    -- �p�[�e�B2(�[�i��ڋq)
           ,hz_parties                     hpb2   -- �p�[�e�B3(�����Ώې�����ڋq)
           ,gl_daily_conversion_types      gdct   -- GL���[�g
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --��v����ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hcab2.party_id               = hpb2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   rct.customer_trx_id          >= it_ar_header_id_from --A-3.AR����w�b�_ID(From)
      AND   rct.customer_trx_id          <= it_ar_header_id_to   --A-3.AR����w�b�_ID(To)
      --�^�C�v���u�N�����������v�̎�����ƁA�^�C�v���u�C���v�̎����UNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT 
      SELECT /*+ LEADING(aj)*/
--2012/12/18 Ver.1.3 Mod End
             lt_type_adj                                 AS type                    -- �^�C�v(�C��)
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �⏕�땶���ԍ�
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- �����
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL�L����
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR���ID
            ,rct.trx_number                              AS trx_number              -- AR����ԍ�
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR�����������
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- �����������ԍ�
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- ����^�C�v��
            ,hcab.account_number                         AS account_number_b        -- ������ڋq�R�[�h
            ,hpb.party_name                              AS party_name_b            -- ������ڋq��
            ,hcas.account_number                         AS account_number_s        -- �[�i��ڋq�R�[�h
            ,hps.party_name                              AS party_name_s            -- �[�i��ڋq��
            ,rctg_h.amount                               AS amount                  -- ���������z
            ,NULL                                        AS line_number             -- ���הԍ�
            ,NULL                                        AS description             -- �������דE�v
            ,NULL                                        AS quantity_invoiced       -- ����
            ,NULL                                        AS unit_selling_price      -- �P��
            ,NULL                                        AS extended_amount         -- ���z
            ,NULL                                        AS tax_code                -- �ŃR�[�h
            ,NULL                                        AS tax_extended_amount     -- �Ŋz
            ,NULL                                        AS invoice_num             -- �[�i���ԍ�
            ,NULL                                        AS sales_exp_id            -- �̔�����ID
            ,NULL                                        AS item_kbn                -- �i�ڋ敪
            ,aj.adjustment_id                            AS adjustment_id           -- �C��ID
            ,aj.adjustment_number                        AS adjustment_number       -- �C���ԍ�
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- �C�������ԍ�
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- �C����
            ,arta.name                                   AS act_name                -- ��������
            ,aj.type                                     AS adj_type                -- �C���^�C�v
            ,aj.amount                                   AS adj_amount              -- �C�����z
            ,ajr.meaning                                 AS meaning                 -- ���R
            ,aj.comments                                 AS comments                -- ����
            ,NULL                                        AS apply_date              -- ������
            ,NULL                                        AS applied_account_number  -- �����Ώې�����ڋq�R�[�h
            ,NULL                                        AS applied_party_name      -- �����Ώې�����ڋq��
            ,NULL                                        AS amount_applied          -- �������z
            ,NULL                                        AS applied_customer_trx_id -- �����Ώێ��ID
            ,NULL                                        AS applied_trx_number      -- �����Ώێ���ԍ�
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- ����ʉ�
            ,gdct.user_conversion_type                   AS user_conversion_type    -- ���[�g�^�C�v
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- ���Z��
            ,rct.exchange_rate                           AS exchange_rate           -- ���Z���[�g
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- �@�\�ʉݐ��������z
            ,aj.acctd_amount                             AS acctd_list_amount       -- �@�\�ʉݖ��׋��z
            ,NULL                                        AS acctd_tax_amount        -- �@�\�ʉݐŊz
            ,aj.acctd_amount                             AS acctd_adj_amount        -- �@�\�ʉݏC�����z
            ,NULL                                        AS invoice_currency_code   -- �����Ώێ���ʉ�
            ,NULL                                        AS acctd_amount_applied_to -- �@�\�ʉ݃N�������������z
            ,gv_coop_date                                AS cool_date               -- �A�g����
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL�]�L��_�`�F�b�N�p
            ,cv_data_type_0                              AS data_type               -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  ra_customer_trx_all               rct    -- ����w�b�_
           ,ar_adjustments_all                aj     -- ����C��
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- ����z��
           ,hz_cust_accounts                  hcab   -- �ڋq�}�X�^(������ڋq)
           ,hz_cust_accounts                  hcas   -- �ڋq�}�X�^2(�[�i��ڋq)
           ,hz_parties                        hpb    -- �p�[�e�B(������ڋq)
           ,hz_parties                        hps    -- �p�[�e�B2(�[�i��ڋq)
           ,ar_payment_schedules_all          aps    -- AR�x���v��
           ,ar_receivables_trx_all            arta   -- ���|/����������
           ,gl_daily_conversion_types         gdct   -- GL���[�g
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv --�N�C�b�N�R�[�h
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                ajr
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   aj.adjustment_id        >= it_ar_adj_id_from --A-3.AR�C��ID(From)
      AND   aj.adjustment_id        <= it_ar_adj_id_to   --A-3.AR�C��ID(To)
      ORDER BY TYPE            --�^�C�v
              ,customer_trx_id --AR���ID
              ,adjustment_id   --�C��ID
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
    -- �C��
    lt_type_adj := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11058
                    );
    -- ���
    lt_type_trx := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11059
                    );
    -- �N������
    lt_type_cm := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11060
                    );
    -- �N����������
    lt_type_cm_apply := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11061
                    );
    -- ���㐿����
    lt_type_sales_doc := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11062
                    );
    -- �N���W�b�g�E����
    lt_type_credit_memo := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11063
                    );
    -- �N���W�b�gMEMO����
    lt_type_credit_memo_apply := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11064
                    );
--
    --==============================================================
    -- 1 �蓮���s�̏ꍇ
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --���̓p�����[�^��AR����ԍ����ݒ肳��Ă���ꍇ
      IF ( iv_trx_number IS NOT NULL ) THEN
        --�J�[�\���I�[�v��
        OPEN get_ar_trx_manual_number_cur( iv_trx_type
                                          ,iv_trx_number
                                         );
        <<main_loop>>
        LOOP
        FETCH get_ar_trx_manual_number_cur INTO
              gt_data_tab(1)  -- �^�C�v
            , gt_data_tab(2)  -- �⏕�땶���ԍ�
            , gt_data_tab(3)  -- GL�L����
            , gt_data_tab(4)  -- AR���ID
            , gt_data_tab(5)  -- AR����ԍ�
            , gt_data_tab(6)  -- AR�����������
            , gt_data_tab(7)  -- �����������ԍ�
            , gt_data_tab(8)  -- ����^�C�v��
            , gt_data_tab(9)  -- ������ڋq�R�[�h
            , gt_data_tab(10) -- ������ڋq��
            , gt_data_tab(11) -- �[�i��ڋq�R�[�h
            , gt_data_tab(12) -- �[�i��ڋq��
            , gt_data_tab(13) -- ���������z
            , gt_data_tab(14) -- ���הԍ�
            , gt_data_tab(15) -- �������דE�v
            , gt_data_tab(16) -- ����
            , gt_data_tab(17) -- �P��
            , gt_data_tab(18) -- ���z
            , gt_data_tab(19) -- �ŃR�[�h
            , gt_data_tab(20) -- �Ŋz
            , gt_data_tab(21) -- �[�i���ԍ�
            , gt_data_tab(22) -- �̔�����ID
            , gt_data_tab(23) -- �i�ڋ敪
            , gt_data_tab(24) -- �C��ID
            , gt_data_tab(25) -- �C���ԍ�
            , gt_data_tab(26) -- �C�������ԍ�
            , gt_data_tab(27) -- �C����
            , gt_data_tab(28) -- ��������
            , gt_data_tab(29) -- �C���^�C�v
            , gt_data_tab(30) -- �C�����z
            , gt_data_tab(31) -- ���R
            , gt_data_tab(32) -- ����
            , gt_data_tab(33) -- ������
            , gt_data_tab(34) -- �����Ώې�����ڋq�R�[�h
            , gt_data_tab(35) -- �����Ώې�����ڋq��
            , gt_data_tab(36) -- �������z
            , gt_data_tab(37) -- �����Ώێ��ID
            , gt_data_tab(38) -- �����Ώێ���ԍ�
            , gt_data_tab(39) -- ����ʉ�
            , gt_data_tab(40) -- ���[�g�^�C�v
            , gt_data_tab(41) -- ���Z��
            , gt_data_tab(42) -- ���Z���[�g
            , gt_data_tab(43) -- �@�\�ʉݐ��������z
            , gt_data_tab(44) -- �@�\�ʉݖ��׋��z
            , gt_data_tab(45) -- �@�\�ʉݐŊz
            , gt_data_tab(46) -- �@�\�ʉݏC�����z
            , gt_data_tab(47) -- �����Ώێ���ʉ�
            , gt_data_tab(48) -- �@�\�ʉ݃N�������������z
            , gt_data_tab(49) -- �A�g����
            , gt_data_tab(50) -- GL�]�L��_�`�F�b�N�p
            , gt_data_tab(51) -- �f�[�^�^�C�v
            ;
          EXIT WHEN get_ar_trx_manual_number_cur%NOTFOUND;
--
          --==============================================================
          --�^�C�v��ID���́E�l�擾(�C��/�C���ȊO)
          --==============================================================
          lv_type := gt_data_tab(1); -- �^�C�v
          IF ( gt_data_tab(1) = lt_type_adj ) THEN
            --�^�C�v���u�C���v�̏ꍇ
            lv_id_value     := gt_data_tab(24);                               -- AR�C��ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11053); -- AR�C��ID
            lv_ar_id_from   := gt_ar_adj_id_from; --A-3�ɂĎ擾�����C��ID(From)���i�[
          ELSE
            --�^�C�v���u�C���v�ȊO�̏ꍇ
            lv_id_value     := gt_data_tab(4);                                -- AR���ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11048); -- AR���ID
            lv_ar_id_from   := gt_ar_header_id_from; --A-3�ɂĎ擾��������w�b�_ID(From)���i�[
          END IF;
          --
          --==============================================================
          --���ڃ`�F�b�N����(A-5)
          --==============================================================
          chk_item(
            iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- �ǉ��X�V�敪
           ,iv_exec_kbn                   =>        iv_exec_kbn    -- ����蓮�敪
           ,iv_type                       =>        lv_type        -- �^�C�v
           ,iv_id_value                   =>        lv_id_value    -- ID�l(AR�C��ID/AR���ID)
           ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID���́�(���b�Z�[�W�o�͗p)
           ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3�ɂĎ擾����From�l)
           ,ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
           ,ov_item_chk                   =>        lv_item_chk    -- ���ڃ`�F�b�N���{�t���O
           ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
           ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
           ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ���ڃ`�F�b�N�̖߂肪����̏ꍇ�ACSV�o�͂��s��
            --==============================================================
            -- CSV�o�͏���(A-6)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( lv_item_chk = cv_flag_y ) THEN
              --���ڃ`�F�b�N�����Ōx���ƂȂ����ꍇ(�^���`�F�b�N�̏ꍇ�̂�)
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --�^���`�F�b�N�������߂̏ꍇ
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                        )
                                      ,1
                                      ,5000);
--2012/10/18 MOD Start
--              ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
              ELSE
--2012/10/18 MOD End
                --�^���`�F�b�N�ɂāA�x�����e���������߈ȊO�̏ꍇ�A�߂胁�b�Z�[�W��ID��ǉ��o��
                lv_errmsg := lv_errmsg || ' ' || lv_tkn_id_name || cv_msg_part || lv_id_value; --ID
              END IF;
              --
              IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
                --�ǉ��X�V�敪���u�ǉ�(0)�v�̏ꍇ�A�x���Ƃ���(�����p��)
                --���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
                gv_warning_flg := cv_flag_y; --�x���t���O(Y)
              ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
                --�ǉ��X�V�敪���u�X�V(1)�v�̏ꍇ�A�G���[�I��
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
              END IF;
            END IF;
          ELSE
            --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
            gv_0file_flg := cv_flag_y;
            --�����𒆒f
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
--
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
--
        END LOOP main_loop;
        CLOSE get_ar_trx_manual_number_cur;
      ELSIF ( gn_id_from IS NOT NULL ) THEN
        --���̓p�����[�^��AR���ID���ݒ肳��Ă���ꍇ
        --�J�[�\���I�[�v��
        OPEN get_ar_trx_manual_id_cur( iv_trx_type
                                      ,gn_id_from
                                      ,gn_id_to
                                     );
        <<main_loop>>
        LOOP
        FETCH get_ar_trx_manual_id_cur INTO
              gt_data_tab(1)  -- �^�C�v
            , gt_data_tab(2)  -- �⏕�땶���ԍ�
            , gt_data_tab(3)  -- GL�L����
            , gt_data_tab(4)  -- AR���ID
            , gt_data_tab(5)  -- AR����ԍ�
            , gt_data_tab(6)  -- AR�����������
            , gt_data_tab(7)  -- �����������ԍ�
            , gt_data_tab(8)  -- ����^�C�v��
            , gt_data_tab(9)  -- ������ڋq�R�[�h
            , gt_data_tab(10) -- ������ڋq��
            , gt_data_tab(11) -- �[�i��ڋq�R�[�h
            , gt_data_tab(12) -- �[�i��ڋq��
            , gt_data_tab(13) -- ���������z
            , gt_data_tab(14) -- ���הԍ�
            , gt_data_tab(15) -- �������דE�v
            , gt_data_tab(16) -- ����
            , gt_data_tab(17) -- �P��
            , gt_data_tab(18) -- ���z
            , gt_data_tab(19) -- �ŃR�[�h
            , gt_data_tab(20) -- �Ŋz
            , gt_data_tab(21) -- �[�i���ԍ�
            , gt_data_tab(22) -- �̔�����ID
            , gt_data_tab(23) -- �i�ڋ敪
            , gt_data_tab(24) -- �C��ID
            , gt_data_tab(25) -- �C���ԍ�
            , gt_data_tab(26) -- �C�������ԍ�
            , gt_data_tab(27) -- �C����
            , gt_data_tab(28) -- ��������
            , gt_data_tab(29) -- �C���^�C�v
            , gt_data_tab(30) -- �C�����z
            , gt_data_tab(31) -- ���R
            , gt_data_tab(32) -- ����
            , gt_data_tab(33) -- ������
            , gt_data_tab(34) -- �����Ώې�����ڋq�R�[�h
            , gt_data_tab(35) -- �����Ώې�����ڋq��
            , gt_data_tab(36) -- �������z
            , gt_data_tab(37) -- �����Ώێ��ID
            , gt_data_tab(38) -- �����Ώێ���ԍ�
            , gt_data_tab(39) -- ����ʉ�
            , gt_data_tab(40) -- ���[�g�^�C�v
            , gt_data_tab(41) -- ���Z��
            , gt_data_tab(42) -- ���Z���[�g
            , gt_data_tab(43) -- �@�\�ʉݐ��������z
            , gt_data_tab(44) -- �@�\�ʉݖ��׋��z
            , gt_data_tab(45) -- �@�\�ʉݐŊz
            , gt_data_tab(46) -- �@�\�ʉݏC�����z
            , gt_data_tab(47) -- �����Ώێ���ʉ�
            , gt_data_tab(48) -- �@�\�ʉ݃N�������������z
            , gt_data_tab(49) -- �A�g����
            , gt_data_tab(50) -- GL�]�L��_�`�F�b�N�p
            , gt_data_tab(51) -- �f�[�^�^�C�v
            ;
          EXIT WHEN get_ar_trx_manual_id_cur%NOTFOUND;
--
          --==============================================================
          --�^�C�v��ID���́E�l�擾(�C��/�C���ȊO)
          --==============================================================
          lv_type := gt_data_tab(1); -- �^�C�v
          IF ( gt_data_tab(1) = lt_type_adj ) THEN
            --�^�C�v���u�C���v�̏ꍇ
            lv_id_value     := gt_data_tab(24);                               -- AR�C��ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11053); -- AR�C��ID
            lv_ar_id_from   := gt_ar_adj_id_from; --A-3�ɂĎ擾�����C��ID(From)���i�[
          ELSE
            --�^�C�v���u�C���v�ȊO�̏ꍇ
            lv_id_value     := gt_data_tab(4);                                -- AR���ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11048); -- AR���ID
            lv_ar_id_from   := gt_ar_header_id_from; --A-3�ɂĎ擾��������w�b�_ID(From)���i�[
          END IF;
          --
          --==============================================================
          --���ڃ`�F�b�N����(A-5)
          --==============================================================
          chk_item(
            iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- �ǉ��X�V�敪
           ,iv_exec_kbn                   =>        iv_exec_kbn    -- ����蓮�敪
           ,iv_type                       =>        lv_type        -- �^�C�v
           ,iv_id_value                   =>        lv_id_value    -- ID�l(AR�C��ID/AR���ID)
           ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID���́�(���b�Z�[�W�o�͗p)
           ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3�ɂĎ擾����From�l)
           ,ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
           ,ov_item_chk                   =>        lv_item_chk    -- ���ڃ`�F�b�N���{�t���O
           ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
           ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
           ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ���ڃ`�F�b�N�̖߂肪����̏ꍇ�ACSV�o�͂��s��
            --==============================================================
            -- CSV�o�͏���(A-6)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( lv_item_chk = cv_flag_y ) THEN
              --���ڃ`�F�b�N�����Ōx���ƂȂ����ꍇ(�^���`�F�b�N�̏ꍇ�̂�)
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --�^���`�F�b�N�������߂̏ꍇ
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                        )
                                      ,1
                                      ,5000);
--2012/10/18 MOD Start
--              ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
              ELSE
--2012/10/18 MOD End
                --�^���`�F�b�N�ɂāA�x�����e���������߈ȊO�̏ꍇ�A�߂胁�b�Z�[�W��ID��ǉ��o��
                lv_errmsg := lv_errmsg || ' ' || lv_tkn_id_name || cv_msg_part || lv_id_value; --ID
              END IF;
              --
              IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
                --�ǉ��X�V�敪���u�ǉ�(0)�v�̏ꍇ�A�x���Ƃ���(�����p��)
                --���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
                gv_warning_flg := cv_flag_y; --�x���t���O(Y)
              ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
                --�ǉ��X�V�敪���u�X�V(1)�v�̏ꍇ�A�G���[�I��
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
              END IF;
            END IF;
          ELSE
            --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
            gv_0file_flg := cv_flag_y;
            --�����𒆒f
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
--
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
--
        END LOOP main_loop;
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
    --==============================================================
    -- 2 �莞���s�̏ꍇ
    --==============================================================
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --�J�[�\���I�[�v��
      OPEN get_ar_trx_fixed_cur( gt_ar_header_id_from
                                ,gt_ar_header_id_to
                                ,gt_ar_adj_id_from
                                ,gt_ar_adj_id_to
                               );
      <<main_loop>>
      LOOP
      FETCH get_ar_trx_fixed_cur INTO
            gt_data_tab(1)  -- �^�C�v
          , gt_data_tab(2)  -- �⏕�땶���ԍ�
          , gt_data_tab(3)  -- GL�L����
          , gt_data_tab(4)  -- AR���ID
          , gt_data_tab(5)  -- AR����ԍ�
          , gt_data_tab(6)  -- AR�����������
          , gt_data_tab(7)  -- �����������ԍ�
          , gt_data_tab(8)  -- ����^�C�v��
          , gt_data_tab(9)  -- ������ڋq�R�[�h
          , gt_data_tab(10) -- ������ڋq��
          , gt_data_tab(11) -- �[�i��ڋq�R�[�h
          , gt_data_tab(12) -- �[�i��ڋq��
          , gt_data_tab(13) -- ���������z
          , gt_data_tab(14) -- ���הԍ�
          , gt_data_tab(15) -- �������דE�v
          , gt_data_tab(16) -- ����
          , gt_data_tab(17) -- �P��
          , gt_data_tab(18) -- ���z
          , gt_data_tab(19) -- �ŃR�[�h
          , gt_data_tab(20) -- �Ŋz
          , gt_data_tab(21) -- �[�i���ԍ�
          , gt_data_tab(22) -- �̔�����ID
          , gt_data_tab(23) -- �i�ڋ敪
          , gt_data_tab(24) -- �C��ID
          , gt_data_tab(25) -- �C���ԍ�
          , gt_data_tab(26) -- �C�������ԍ�
          , gt_data_tab(27) -- �C����
          , gt_data_tab(28) -- ��������
          , gt_data_tab(29) -- �C���^�C�v
          , gt_data_tab(30) -- �C�����z
          , gt_data_tab(31) -- ���R
          , gt_data_tab(32) -- ����
          , gt_data_tab(33) -- ������
          , gt_data_tab(34) -- �����Ώې�����ڋq�R�[�h
          , gt_data_tab(35) -- �����Ώې�����ڋq��
          , gt_data_tab(36) -- �������z
          , gt_data_tab(37) -- �����Ώێ��ID
          , gt_data_tab(38) -- �����Ώێ���ԍ�
          , gt_data_tab(39) -- ����ʉ�
          , gt_data_tab(40) -- ���[�g�^�C�v
          , gt_data_tab(41) -- ���Z��
          , gt_data_tab(42) -- ���Z���[�g
          , gt_data_tab(43) -- �@�\�ʉݐ��������z
          , gt_data_tab(44) -- �@�\�ʉݖ��׋��z
          , gt_data_tab(45) -- �@�\�ʉݐŊz
          , gt_data_tab(46) -- �@�\�ʉݏC�����z
          , gt_data_tab(47) -- �����Ώێ���ʉ�
          , gt_data_tab(48) -- �@�\�ʉ݃N�������������z
          , gt_data_tab(49) -- �A�g����
          , gt_data_tab(50) -- GL�]�L��_�`�F�b�N�p
          , gt_data_tab(51) -- �f�[�^�^�C�v
          ;
        EXIT WHEN get_ar_trx_fixed_cur%NOTFOUND;
--
        --==============================================================
        --�^�C�v��ID���̎擾(�C��/�C���ȊO)
        --==============================================================
        lv_type := gt_data_tab(1); -- �^�C�v
        IF ( gt_data_tab(1) = lt_type_adj ) THEN
          --�^�C�v���u�C���v�̏ꍇ
          lv_id_value     := gt_data_tab(24);                               -- AR�C��ID
          lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                     ,cv_msgtkn_cfo_11053); -- AR�C��ID
          lv_ar_id_from   := gt_ar_adj_id_from; --A-3�ɂĎ擾�����C��ID(From)���i�[
        ELSE
          --�^�C�v���u�C���v�ȊO�̏ꍇ
          lv_id_value     := gt_data_tab(4);                                -- AR���ID
          lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                     ,cv_msgtkn_cfo_11048); -- AR���ID
          lv_ar_id_from   := gt_ar_header_id_from; --A-3�ɂĎ擾��������w�b�_ID(From)���i�[
        END IF;
        --
        --==============================================================
        --���ڃ`�F�b�N����(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- �ǉ��X�V�敪
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- ����蓮�敪
         ,iv_type                       =>        lv_type        -- �^�C�v
         ,iv_id_value                   =>        lv_id_value    -- ID�l(AR�C��ID/AR���ID)
         ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID���́�(���b�Z�[�W�o�͗p)
         ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3�ɂĎ擾����From�l)
         ,ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
         ,ov_item_chk                   =>        lv_item_chk    -- ���ڃ`�F�b�N���{�t���O
         ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ���ڃ`�F�b�N�̖߂肪����̏ꍇ�ACSV�o�͂��s��
          --==============================================================
          -- CSV�o�͏���(A-6)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          IF ( lv_item_chk = cv_flag_y ) THEN
            IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
              --���ڃ`�F�b�N�����Ō������߃G���[�̏ꍇ�A���b�Z�[�W���o��
              lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo     -- 'XXCFO'
                                      ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                      ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                      ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                      )
                                    ,1
                                    ,5000);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--2012/10/18 MOD Start
--            ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
            ELSE
--2012/10/18 MOD End
              --���ڃ`�F�b�N�����Ō����ȊO�̌x���ƂȂ����ꍇ
              --==============================================================
              --���A�g�e�[�u���o�^����(A-7)
              --==============================================================
              ins_ar_wait_coop(
                iv_meaning                  =>        lv_errmsg      -- A-5�̃��[�U�[�G���[���b�Z�[�W
              , iv_exec_kbn                 =>        iv_exec_kbn    -- ����蓮�敪
              , iv_id_value                 =>        lv_id_value    -- ID�l(AR�C��ID/AR���ID)
              , iv_tkn_id_name              =>        lv_tkn_id_name -- ID���́�(���b�Z�[�W�o�͗p)
              , ov_errbuf                   =>        lv_errbuf      -- �G���[���b�Z�[�W
              , ov_retcode                  =>        lv_retcode     -- ���^�[���R�[�h
              , ov_errmsg                   =>        lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
            --
            IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
              --�ǉ��X�V�敪���u�ǉ�(0)�v�̏ꍇ�A�x���Ƃ���(�����p��)
              gv_warning_flg := cv_flag_y; --�x���t���O(Y)
            ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
              --�ǉ��X�V�敪���u�X�V(1)�v�̏ꍇ�A�G���[�I��
              RAISE global_process_expt;
            END IF;
          END IF;
        ELSE
          --�����𒆒f
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(51) = cv_data_type_0 ) THEN
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
        --
      END LOOP main_loop;
      CLOSE get_ar_trx_fixed_cur;
    END IF;
--
    --==================================================================
    -- 0���̏ꍇ�̓��b�Z�[�W�o��
    --==================================================================
    IF ( gn_target_cnt + gn_target_wait_cnt ) = 0 THEN
-- 2012-11-28 Ver.1.2 T.Osawa Add Start
      ov_retcode  :=  cv_status_warn ;
-- 2012-11-28 Ver.1.2 T.Osawa Add End
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_10025      -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data       -- �g�[�N��'GET_DATA' 
                                                     ,cv_msgtkn_cfo_11054   -- AR������
                                                    )
                            ,1
                            ,5000
                          );
      --���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_trx;
--
  /**********************************************************************************
   * Procedure Name   : del_ar_wait_coop
   * Description      : ���A�g�e�[�u���폜����(A-8)
   ***********************************************************************************/
  PROCEDURE del_ar_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ar_wait_coop'; -- �v���O������
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
    --���A�g�f�[�^�폜
    --==============================================================
    --A-2�Ŏ擾�������A�g�f�[�^�������ɁA�폜���s��
    <<delete_loop>>
    FOR i IN 1 .. ar_trx_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_ar_wait_coop xawc --������A�g
        WHERE xawc.rowid = ar_trx_wait_coop_tab( i ).row_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                ( cv_msg_kbn_cfo     -- XXCFO
                                  ,cv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                  ,cv_tkn_table       -- �g�[�N��'TABLE'
                                  ,cv_msgtkn_cfo_11055 -- AR������A�g�e�[�u��
                                  ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                  ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                 )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
    END LOOP;
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
  END del_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_ar_trx_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE upd_ar_trx_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ar_trx_control'; -- �v���O������
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
    ln_ctl_max_ar_trx_header_id NUMBER; --�ő����w�b�_ID(����Ǘ�)
    ln_hd_max_ar_trx_header_id  NUMBER; --�ő����w�b�_ID(����w�b�_)
    ln_ctl_max_adj_id           NUMBER; --�ő�C��ID(�C���Ǘ�)
    ln_hd_max_adj_id            NUMBER; --�ő�C��ID(����C��)
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
      --����Ǘ��e�[�u���X�V
      --==============================================================
      <<update_loop>>
      FOR i IN 1 .. upd_rowid_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_ar_trx_control xatc --����Ǘ�
          SET xatc.process_flag           = cv_flag_y                 -- �����σt���O
             ,xatc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
             ,xatc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
             ,xatc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
             ,xatc.request_id             = cn_request_id             -- �v��ID
             ,xatc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
             ,xatc.program_id             = cn_program_id             -- �v���O����ID
             ,xatc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE xatc.rowid                = upd_rowid_tab(i).rowid   -- A-3�Ŏ擾����ROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                         ,cv_msg_cfo_00020   -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                         ,cv_msgtkn_cfo_11056 -- AR����Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
      END LOOP;
--
      --==============================================================
      --����Ǘ��e�[�u���o�^
      --==============================================================
      --����Ǘ��f�[�^����ő�̎���w�b�_ID���擾
      BEGIN
        SELECT MAX(xatc.customer_trx_id)
          INTO ln_ctl_max_ar_trx_header_id
          FROM xxcfo_ar_trx_control xatc
        ;
      END;
--
      --�����쐬���ꂽ����w�b�_ID�̍ő�l���擾
      BEGIN
--2012/12/18 Ver.1.3 Mod Start
--        SELECT NVL(MAX(rcta.customer_trx_id),ln_ctl_max_ar_trx_header_id)
        SELECT /*+ INDEX(rcta RA_CUSTOMER_TRX_U1) */
               NVL(MAX(rcta.customer_trx_id),ln_ctl_max_ar_trx_header_id)
--2012/12/18 Ver.1.3 Mod End
          INTO ln_hd_max_ar_trx_header_id
          FROM ra_customer_trx_all rcta
         WHERE rcta.customer_trx_id > ln_ctl_max_ar_trx_header_id
           AND rcta.creation_date < ( gd_process_date + 1 + NVL(gt_proc_target_time, 0) / 24 )
        ;
      END;
--
      --����Ǘ��e�[�u���o�^
      BEGIN
        INSERT INTO xxcfo_ar_trx_control(
           business_date          -- �Ɩ����t
          ,customer_trx_id        -- ����w�b�_ID
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
          ,ln_hd_max_ar_trx_header_id
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
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                       ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,cv_msgtkn_cfo_11056 -- AR����Ǘ��e�[�u��
                                                       ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                       ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --==============================================================
      --�C���Ǘ��e�[�u���X�V
      --==============================================================
      <<update_loop>>
      FOR i IN 1 .. upd_rowid_adj_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_ar_adj_control xaac --�C���Ǘ�
          SET xaac.process_flag           = cv_flag_y                 -- �����σt���O
             ,xaac.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
             ,xaac.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
             ,xaac.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
             ,xaac.request_id             = cn_request_id             -- �v��ID
             ,xaac.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
             ,xaac.program_id             = cn_program_id             -- �v���O����ID
             ,xaac.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE xaac.rowid                = upd_rowid_adj_tab(i).rowid -- A-3�Ŏ擾����ROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                         ,cv_msg_cfo_00020   -- �f�[�^�X�V�G���[
                                                         ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                         ,cv_msgtkn_cfo_11051 -- AR�C���Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
      END LOOP;
--
      --==============================================================
      --�C���Ǘ��e�[�u���o�^
      --==============================================================
      --�C���Ǘ��f�[�^����ő��AR�C��ID���擾
      BEGIN
        SELECT MAX(xaac.adjustment_id)
          INTO ln_ctl_max_adj_id
          FROM xxcfo_ar_adj_control xaac --�C���Ǘ�
        ;
      END;
--
      --������s���ꂽ�������O�̏C��ID�̍ő�l���擾
      BEGIN
--2012/12/18 Ver.1.3 Mod Start
--        SELECT NVL(MAX(aaa.adjustment_id),ln_ctl_max_adj_id)
        SELECT /*+ INDEX(aaa AR_ADJUSTMENTS_U1) */
                NVL(MAX(aaa.adjustment_id),ln_ctl_max_adj_id)
--2012/12/18 Ver.1.3 Mod End
          INTO ln_hd_max_adj_id
          FROM ar_adjustments_all aaa
         WHERE aaa.adjustment_id > ln_ctl_max_adj_id
           AND aaa.creation_date < ( gd_process_date + 1 + NVL(gt_proc_target_time, 0) / 24 )
        ;
      END;
--
      --�C���Ǘ��e�[�u���o�^
      BEGIN
        INSERT INTO xxcfo_ar_adj_control(
           business_date          -- �Ɩ����t
          ,adjustment_id          -- �C��ID
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
          ,ln_hd_max_adj_id
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
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                       ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,cv_msgtkn_cfo_11051 -- AR�C���Ǘ��e�[�u��
                                                       ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                       ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_ar_trx_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2, -- 2.�t�@�C����
    iv_trx_type           IN  VARCHAR2, -- 3.�^�C�v
    iv_trx_number         IN  VARCHAR2, -- 4.AR����ԍ�
    iv_id_from            IN  VARCHAR2, -- 5.AR���ID�iFrom�j
    iv_id_to              IN  VARCHAR2, -- 6.AR���ID�iTo�j
    iv_exec_kbn           IN  VARCHAR2, -- 7.����蓮�敪
    ov_errbuf             OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_wait_cnt := 0;
    gn_wait_data_cnt   := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_ins_upd_kbn      -- 1.�ǉ��X�V�敪
      ,iv_file_name        -- 2.�t�@�C����
      ,iv_trx_type         -- 3.�^�C�v
      ,iv_trx_number       -- 4.AR����ԍ�
      ,iv_id_from          -- 5.AR���ID�iFrom�j
      ,iv_id_to            -- 6.AR���ID�iTo�j
      ,iv_exec_kbn         -- 7.����蓮�敪
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_ar_wait_coop(
      iv_exec_kbn,       -- 1.����蓮�敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_ar_trx_control(
      iv_exec_kbn,       -- 1.����蓮�敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^�擾(A-4)
    -- ===============================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --�蓮���s�̏ꍇ
      get_ar_trx(
        iv_ins_upd_kbn      -- 1.�ǉ��X�V�敪
       ,iv_trx_type         -- 2.�^�C�v
       ,iv_trx_number       -- 3.AR����ԍ�
       ,iv_exec_kbn         -- 4.����蓮�敪
       ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ
      get_ar_trx(
        iv_ins_upd_kbn      -- 1.�ǉ��X�V�敪
       ,iv_trx_type         -- 2.�^�C�v
       ,iv_trx_number       -- 3.AR����ԍ�
       ,iv_exec_kbn         -- 4.����蓮�敪
       ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
      gv_0file_flg := cv_flag_y;
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�̂݁A�ȉ��̏������s��
      -- ===============================
      -- ���A�g�e�[�u���폜����(A-8)
      -- ===============================
      del_ar_wait_coop(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �Ǘ��e�[�u���o�^�E�X�V����(A-9)
      -- ===============================
      upd_ar_trx_control(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_ins_upd_kbn        IN  VARCHAR2,      -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2,      -- 2.�t�@�C����
    iv_trx_type           IN  VARCHAR2,      -- 3.�^�C�v
    iv_trx_number         IN  VARCHAR2,      -- 4.AR����ԍ�
    iv_id_from            IN  VARCHAR2,      -- 5.AR���ID�iFrom�j
    iv_id_to              IN  VARCHAR2,      -- 6.AR���ID�iTo�j
    iv_exec_kbn           IN  VARCHAR2       -- 7.����蓮�敪
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
      ,iv_trx_type                                 -- 3.�^�C�v
      ,iv_trx_number                               -- 4.AR����ԍ�
      ,iv_id_from                                  -- 5.AR���ID�iFrom�j
      ,iv_id_to                                    -- 6.AR���ID�iTo�j
      ,iv_exec_kbn                                 -- 7.����蓮�敪
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_wait_data_cnt   := 0;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�����Ōx�����������A�G���[�I���łȂ��ꍇ�A�X�e�[�^�X���x���ɂ���
    IF ( lv_retcode <> cv_status_error )
    AND ( gv_warning_flg = cv_flag_y ) THEN
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
    -- �t�@�C��0Byte�X�V
    -- ====================================================
    -- �蓮���s���AA-5�ȍ~�̏����ŃG���[���������Ă����ꍇ�A
    -- �t�@�C�����ēx�I�[�v�����N���[�Y���A0Byte�ɍX�V����
    IF ( ( iv_exec_kbn = cv_exec_manual )
    AND ( lv_retcode = cv_status_error )
    AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o�́i�A�g���j
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
    --�Ώی����o�́i���A�g�������j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
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
END XXCFO019A06C;
/
