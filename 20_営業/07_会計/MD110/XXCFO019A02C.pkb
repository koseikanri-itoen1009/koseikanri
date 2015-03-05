CREATE OR REPLACE PACKAGE BODY XXCFO019A02C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A02C(body)
 * Description      : �d�q����d��̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A02_�d�q����d��̏��n�V�X�e���A�g
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_gl_je_wait         ���A�g�f�[�^�擾����(A-2)
 *  get_gl_je_control      �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  get_gl_je              �Ώۃf�[�^�擾(A-4)
 *  get_flex_information   �t�����擾����(A-5)
 *  chk_item               ���ڃ`�F�b�N����(A-6)
 *  out_csv                �b�r�u�o�͏���(A-7)
 *  out_gl_je_wait         ���A�g�e�[�u���o�^����(A-8)
 *  upd_gl_je_control      �Ǘ��e�[�u���o�^�E�X�V����(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W���E�I������(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-08-29    1.0   K.Onotsuka      �V�K�쐬
 *  2012-10-03    1.1   K.Onotsuka      �����e�X�g��Q�Ή�[��QNo16:���ڌ��`�F�b�N�߂�l�i�[�ϐ��̌����ύX]
 *                                                        [��QNo19�A20:�Ǘ��e�[�u���o�^�����C��]
 *                                                        [��QNo22:���o���ځu���Y�Ǘ��L�[�݌ɊǗ��L�[�l�v�̕ҏW���e�ύX]
 *  2012-12-18    1.2   T.Ishiwata      ���\���P�Ή�
 *  2014-12-08    1.3   K.Oomata        �yE_�{�ғ�_12291�Ή��z
 *                                       �����Ώێd��f�[�^����d��J�e�S���uICS�c���ڍs�v�����O�B
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A02C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';    -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_GL_JOURNAL_I_FILENAME'; -- �d�q����d��ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_GL_JOURNAL_U_FILENAME'; -- �d�q����d��X�V�t�@�C����
  cv_p_accounts               CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_P_ACCOUNTS';       -- �d�q���땡������敡�����莞����
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                      -- ��v����ID
--2012/10/03 Add Start
  cv_gl_ctg_inv_cost          CONSTANT VARCHAR2(100) := 'XXCOI1_GL_CATEGORY_INV_COST';           -- �d��J�e�S��_�݌Ɍ����U��
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
  cv_not_proc_category        CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_NOT_PROC_CATEGORY';  -- XXCFO:�d�q����d�󒊏o�ΏۊO�d��J�e�S��
-- 2014/12/08 Ver.1.3 Add K.Oomata End
  --���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --�t�@�C�����݃G���[
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --�t�@�C����������
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00031';   --�N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10005';   --�d�󖢓]�L���b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_10017            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10017';   --�d�q����d��p�����[�^���͕s�����b�Z�[�W
  cv_msg_cfo_10014            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10014';   --�d�󏈗��σf�[�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cfo_10034            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10034';   --���芨����擾�Ȃ����b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_prm_name             CONSTANT VARCHAR2(20)  := 'PARAM_NAME';     -- �p�����[�^��
  cv_tkn_param_val            CONSTANT VARCHAR2(20)  := 'PARAM_VAL';      -- �p�����[�^�l
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ���b�N�A�b�v�^�C�v��
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';    -- ���b�N�A�b�v�R�[�h��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- �v���t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- �f�B���N�g����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- �t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';          -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';         -- SQL�G���[���b�Z�[�W
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- �e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- �G���[���
  cv_tkn_je_header_id         CONSTANT VARCHAR2(20)  := 'JE_HEADER_ID';   -- �d��w�b�_ID
  cv_tkn_je_doc_seq_val       CONSTANT VARCHAR2(20)  := 'JE_DOC_SEQ_VAL'; -- �d�󕶏��ԍ�
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- �f�[�^���e(�d��w�b�_ID)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- �d��w�b�_ID
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';          -- ���A�g�f�[�^�o�^���R
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';         -- ���A�g�f�[�^����L�[
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';        -- ���A�g�G���[���e
  cv_tkn_key_item             CONSTANT VARCHAR2(20)  := 'KEY_ITEM';       -- �G���[���
  cv_tkn_key_value            CONSTANT VARCHAR2(20)  := 'KEY_VALUE';      -- �G���[���  
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_11001         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11001'; -- '�d��Ǘ�
  cv_msgtkn_cfo_11002         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11002'; -- '�d�󖢘A�g
  cv_msgtkn_cfo_11003         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11003'; -- '�d��w�b�_ID
  cv_msgtkn_cfo_11004         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11004'; -- '�d�󖾍הԍ�
  cv_msgtkn_cfo_11005         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11005'; -- '���芨����擾�G���[
  cv_msgtkn_cfo_11006         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11006'; -- '���]�L�G���[
  cv_msgtkn_cfo_11007         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11007'; -- '���׃`�F�b�N�G���[
  cv_msgtkn_cfo_11039         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11039'; -- '�Ώێd����
  cv_msgtkn_cfo_11041         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11041'; -- '�d��f�[�^
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';     --�d�q���돈�����s��
  cv_lookup_item_chk_glje     CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_GLJE';  --�d�q���덀�ڃ`�F�b�N�i�d��j
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymdhms_deli  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';     --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymd_deli     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                --�b�r�u�o�̓t�H�[�}�b�g
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
  cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';                  -- ���уt���O�F'A'(����)
  cv_errlevel_header          CONSTANT VARCHAR2(10)  := 'HEAD';
  cv_errlevel_line            CONSTANT VARCHAR2(10)  := 'LINE';
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --����
  cv_ref1_mtl                 CONSTANT VARCHAR2(10)  := 'MTL';    --���Y�Ǘ��L�[�݌ɊǗ��L�[�l
  cv_ref1_assets              CONSTANT VARCHAR2(10)  := 'Assets'; --���Y�Ǘ��L�[�݌ɊǗ��L�[�l
--
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;
  --�Œ�l
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
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
  --�d��
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
  gv_exec_kbn                 VARCHAR2(1);   -- �������s�敪
  gd_process_date             DATE;          -- �Ɩ����t
  gn_set_of_bks_id            NUMBER;        -- ��v����ID
  gv_ins_upd_kbn              VARCHAR2(1);   -- �ǉ��X�V�敪
  gv_electric_exec_days       fnd_lookup_values.attribute1%TYPE; -- �d�q���돈�����s����
  gv_proc_target_time         fnd_lookup_values.attribute2%TYPE; -- �����Ώێ���
  gt_gl_je_header_id          xxcfo_gl_je_control.gl_je_header_id%TYPE DEFAULT NULL; -- �d��w�b�_ID(A-6���������f�p)
  gt_gl_je_header_id_to       xxcfo_gl_je_control.gl_je_header_id%TYPE;              -- �d��w�b�_ID(�o�͑Ώۃf�[�^���o����)
  gt_gl_je_header_id_from     xxcfo_gl_je_control.gl_je_header_id%TYPE DEFAULT NULL; -- �d��w�b�_ID(�o�͑Ώۃf�[�^���o����)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --�t�@�C���p�X
  gv_dir_path                 all_directories.directory_path%TYPE DEFAULT NULL; --�f�B���N�g���p�X
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --�d�q����d��f�[�^�ǉ��t�@�C��
  gv_full_name                VARCHAR2(200) DEFAULT NULL; --�d�q����̔����уf�[�^�ǉ��t�@�C��
  gv_electrinc_book_start_ymd VARCHAR2(100) DEFAULT NULL; --�d�q����c�ƃV�X�e���ғ��J�n�N����
  gv_electric_book_p_accounts VARCHAR2(100) DEFAULT NULL; --�d�q���땡������敡�����莞����
--2012/10/03 Add Start
  gv_gl_ctg_inv_cost          VARCHAR2(100);              --�d��J�e�S��_�݌Ɍ����U��
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
  gv_not_proc_category        VARCHAR2(100);              --XXCFO:�d�q����d�󒊏o�ΏۊO�d��J�e�S��
-- 2014/12/08 Ver.1.3 Add K.Oomata End
  gv_file_data                VARCHAR2(30000);
  gn_item_cnt                 NUMBER;             --�`�F�b�N���ڌ���
  gv_0file_flg                VARCHAR2(1) DEFAULT 'N'; --0Byte�t�@�C���㏑���t���O
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --�x���t���O
  gv_wait_ins_flg             VARCHAR2(1) DEFAULT 'N'; --���A�g�o�^�σt���O
  gv_line_skip_flg            VARCHAR2(1) DEFAULT 'N'; --���׃X�L�b�v�t���O
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
    -- �Ώۃf�[�^�擾�J�[�\��(������s)
    CURSOR get_gl_je_data_fixed_cur( it_gl_je_header_id_from IN xxcfo_gl_je_control.gl_je_header_id%TYPE
                                    ,it_gl_je_header_id_to   IN xxcfo_gl_je_control.gl_je_header_id%TYPE
                                   )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjh GL_JE_HEADERS_U1) 
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
            ,gjh.period_name                     AS period_name            -- ��v����
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- �L����
            ,gjh.je_source                       AS je_source              -- �d��\�[�X
            ,gjs.user_je_source_name             AS user_je_source_name    -- �d��\�[�X��
            ,gjh.je_category                     AS je_category            -- �d��J�e�S��
            ,gjc.user_je_category_name           AS user_je_category_name  -- �d��J�e�S����
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- �d�󕶏��ԍ�
            ,gjb.name                            AS bat_name               -- �d��o�b�`��
            ,gjh.name                            AS name                   -- �d��
            ,gjh.description                     AS description            -- �E�v
            ,gjl.je_line_num                     AS je_line_num            -- �d�󖾍הԍ�
            ,gjl.description                     AS je_line_description    -- �d�󖾍דE�v
            ,gcc.segment1                        AS aff_company_code       -- �`�e�e��ЃR�[�h
            ,gcc.segment2                        AS aff_department_code    -- �`�e�e����R�[�h
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- ���喼��
            ,gcc.segment3                        AS aff_account_code       -- �`�e�e����ȖڃR�[�h
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- ����Ȗږ���
            ,gcc.segment4                        AS aff_sub_account_code   -- �`�e�e�⏕�ȖڃR�[�h
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- �⏕�Ȗږ���
            ,gcc.segment5                        AS aff_partner_code       -- �`�e�e�ڋq�R�[�h
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq����
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ���
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- �\���P����
            ,gcc.segment8                        AS aff_future             -- �`�e�e�\���Q
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- �\���Q����
            ,gjl.code_combination_id             AS code_combination_id    -- ����Ȗڑg����id
            ,gjl.entered_dr                      AS entered_dr             -- �ؕ����z
            ,gjl.entered_cr                      AS entered_cr             -- �ݕ����z
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- �ŋ敪
            ,gjl.attribute2                      AS attribute2             -- �������R
            ,gjl.attribute3                      AS attribute3             -- �`�[�ԍ�
            ,gjl.attribute4                      AS attribute4             -- �N�[����
            ,gjl.attribute5                      AS attribute5             -- �`�[���͎�
            ,gjl.attribute6                      AS attribute6             -- �C�����`�[�ԍ�
            ,NULL                                AS account_code           -- ���芨�芨��ȖڃR�[�h
            ,NULL                                AS account_name           -- ���芨�芨��Ȗږ���
            ,NULL                                AS sub_account_code       -- ���芨��⏕�ȖڃR�[�h
            ,NULL                                AS sub_account_name       -- ���芨��⏕�Ȗږ���
            ,gjl.attribute8                      AS sales_exp_header_id    -- �̔����уw�b�_�[ID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --�݌Ɍ����U��
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- �⏕�땶���ԍ� 
            ,gjh.currency_code                   AS currency_code                -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type         -- ���[�g�^�C�v
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- ���Z��
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- ���Z���[�g
            ,gjl.accounted_dr                    AS accounted_dr                 -- �ؕ��@�\�ʉ݋��z
            ,gjl.accounted_cr                    AS accounted_cr                 -- �ݕ��@�\�ʉ݋��z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- �A�g����
            ,gjl.status                          AS status                       -- �X�e�[�^�X
            ,'0'                                 AS data_type                    -- �f�[�^�^�C�v('0':�A�g��)
      FROM   gl_je_headers        gjh  -- �d��w�b�_
            ,gl_je_lines          gjl  -- �d�󖾍�
            ,gl_je_sources_tl     gjs  -- �d��\�[�X
            ,gl_je_batches        gjb  -- �d��o�b�`
            ,gl_code_combinations gcc  -- ����Ȗڑg�����}�X�^
            ,gl_je_categories_tl  gjc  -- �d��J�e�S���e�[�u��
            ,gl_daily_conversion_types gdct -- GL���[�g�}�X�^
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.��v����ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.je_header_id BETWEEN it_gl_je_header_id_from
                                        AND it_gl_je_header_id_to
      UNION ALL
--2012/12/18 Ver.1.2 Mod Start
--      SELECT gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
      SELECT /*+ LEADING(xgjwc gjh) */
             gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
--2012/12/18 Ver.1.2 Mod End
            ,gjh.period_name                     AS period_name            -- ��v����
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- �L����
            ,gjh.je_source                       AS je_source              -- �d��\�[�X
            ,gjs.user_je_source_name             AS user_je_source_name    -- �d��\�[�X��
            ,gjh.je_category                     AS je_category            -- �d��J�e�S��
            ,gjc.user_je_category_name           AS user_je_category_name  -- �d��J�e�S����
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- �d�󕶏��ԍ�
            ,gjb.name                            AS bat_name               -- �d��o�b�`��
            ,gjh.name                            AS name                   -- �d��
            ,gjh.description                     AS description            -- �E�v
            ,gjl.je_line_num                     AS je_line_num            -- �d�󖾍הԍ�
            ,gjl.description                     AS je_line_description    -- �d�󖾍דE�v
            ,gcc.segment1                        AS aff_company_code       -- �`�e�e��ЃR�[�h
            ,gcc.segment2                        AS aff_department_code    -- �`�e�e����R�[�h
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- ���喼��
            ,gcc.segment3                        AS aff_account_code       -- �`�e�e����ȖڃR�[�h
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- ����Ȗږ���
            ,gcc.segment4                        AS aff_sub_account_code   -- �`�e�e�⏕�ȖڃR�[�h
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- �⏕�Ȗږ���
            ,gcc.segment5                        AS aff_partner_code       -- �`�e�e�ڋq�R�[�h
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq����
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ���
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- �\���P����
            ,gcc.segment8                        AS aff_future             -- �`�e�e�\���Q
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- �\���Q����
            ,gjl.code_combination_id             AS code_combination_id    -- ����Ȗڑg����id
            ,gjl.entered_dr                      AS entered_dr             -- �ؕ����z
            ,gjl.entered_cr                      AS entered_cr             -- �ݕ����z
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- �ŋ敪
            ,gjl.attribute2                      AS attribute2             -- �������R
            ,gjl.attribute3                      AS attribute3             -- �`�[�ԍ�
            ,gjl.attribute4                      AS attribute4             -- �N�[����
            ,gjl.attribute5                      AS attribute5             -- �`�[���͎�
            ,gjl.attribute6                      AS attribute6             -- �C�����`�[�ԍ�
            ,NULL                                AS account_code           -- ���芨�芨��ȖڃR�[�h
            ,NULL                                AS account_name           -- ���芨�芨��Ȗږ���
            ,NULL                                AS sub_account_code       -- ���芨��⏕�ȖڃR�[�h
            ,NULL                                AS sub_account_name       -- ���芨��⏕�Ȗږ���
            ,gjl.attribute8                      AS sales_exp_header_id    -- �̔����уw�b�_�[ID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --�݌Ɍ����U��
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- �⏕�땶���ԍ� 
            ,gjh.currency_code                   AS currency_code                -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type         -- ���[�g�^�C�v
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- ���Z��
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- ���Z���[�g
            ,gjl.accounted_dr                    AS accounted_dr                 -- �ؕ��@�\�ʉ݋��z
            ,gjl.accounted_cr                    AS accounted_cr                 -- �ݕ��@�\�ʉ݋��z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- �A�g����
            ,gjl.status                          AS status                       -- �X�e�[�^�X
            ,'1'                                 AS data_type                    -- �f�[�^�^�C�v('1':���A�g)
      FROM   gl_je_headers             gjh   -- �d��w�b�_
            ,gl_je_lines               gjl   -- �d�󖾍�
            ,gl_je_batches             gjb   -- �d��o�b�`
            ,gl_code_combinations      gcc   -- ����Ȗڑg�����}�X�^
            ,gl_je_categories_tl       gjc   -- �d��J�e�S���e�[�u��
            ,gl_je_sources_tl          gjs  -- �d��\�[�X
            ,gl_daily_conversion_types gdct  -- GL���[�g�}�X�^
            ,xxcfo_gl_je_wait_coop     xgjwc -- �d�󖢘A�g
      WHERE  gjh.je_header_id             = gjl.je_header_id
        AND  gjh.actual_flag              = cv_actual_flag_a
        AND  gjh.set_of_books_id          = gn_set_of_bks_id -- A-1.��v����ID
        AND  gjl.code_combination_id      = gcc.code_combination_id
        AND  gjh.je_category              = gjc.je_category_name
        AND  gjc.language                 = cv_lang
        AND  gjh.je_source                = gjs.je_source_name
        AND  gjs.language                 = cv_lang
        AND  gjh.je_batch_id              = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  xgjwc.gl_je_header_id        = gjh.je_header_id
      ORDER BY je_header_id
              ,je_line_num
      ;
    -- ���R�[�h�^
    get_gl_je_data_fixed_rec   get_gl_je_data_fixed_cur%ROWTYPE;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s1) ��v���Ԏw��̂�
    CURSOR get_gl_je_data_manual_cur1( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                    )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
            ,gjh.period_name                     AS period_name            -- ��v����
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- �L����
            ,gjh.je_source                       AS je_source              -- �d��\�[�X
            ,gjs.user_je_source_name             AS user_je_source_name    -- �d��\�[�X��
            ,gjh.je_category                     AS je_category            -- �d��J�e�S��
            ,gjc.user_je_category_name           AS user_je_category_name  -- �d��J�e�S����
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- �d�󕶏��ԍ�
            ,gjb.name                            AS bat_name               -- �d��o�b�`��
            ,gjh.name                            AS name                   -- �d��
            ,gjh.description                     AS description            -- �E�v
            ,gjl.je_line_num                     AS je_line_num            -- �d�󖾍הԍ�
            ,gjl.description                     AS je_line_description    -- �d�󖾍דE�v
            ,gcc.segment1                        AS aff_company_code       -- �`�e�e��ЃR�[�h
            ,gcc.segment2                        AS aff_department_code    -- �`�e�e����R�[�h
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- ���喼��
            ,gcc.segment3                        AS aff_account_code       -- �`�e�e����ȖڃR�[�h
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- ����Ȗږ���
            ,gcc.segment4                        AS aff_sub_account_code   -- �`�e�e�⏕�ȖڃR�[�h
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- �⏕�Ȗږ���
            ,gcc.segment5                        AS aff_partner_code       -- �`�e�e�ڋq�R�[�h
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq����
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ���
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- �\���P����
            ,gcc.segment8                        AS aff_future             -- �`�e�e�\���Q
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- �\���Q����
            ,gjl.code_combination_id             AS code_combination_id    -- ����Ȗڑg����id
            ,gjl.entered_dr                      AS entered_dr             -- �ؕ����z
            ,gjl.entered_cr                      AS entered_cr             -- �ݕ����z
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- �ŋ敪
            ,gjl.attribute2                      AS attribute2             -- �������R
            ,gjl.attribute3                      AS attribute3             -- �`�[�ԍ�
            ,gjl.attribute4                      AS attribute4             -- �N�[����
            ,gjl.attribute5                      AS attribute5             -- �`�[���͎�
            ,gjl.attribute6                      AS attribute6             -- �C�����`�[�ԍ�
            ,NULL                                AS account_code           -- ���芨�芨��ȖڃR�[�h
            ,NULL                                AS account_name           -- ���芨�芨��Ȗږ���
            ,NULL                                AS sub_account_code       -- ���芨��⏕�ȖڃR�[�h
            ,NULL                                AS sub_account_name       -- ���芨��⏕�Ȗږ���
            ,gjl.attribute8                      AS sales_exp_header_id    -- �̔����уw�b�_�[ID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --�݌Ɍ����U��
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- �⏕�땶���ԍ� 
            ,gjh.currency_code                   AS currency_code                -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type         -- ���[�g�^�C�v
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- ���Z��
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- ���Z���[�g
            ,gjl.accounted_dr                    AS accounted_dr                 -- �ؕ��@�\�ʉ݋��z
            ,gjl.accounted_cr                    AS accounted_cr                 -- �ݕ��@�\�ʉ݋��z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- �A�g����
            ,gjl.status                          AS status                       -- �X�e�[�^�X
            ,'0'                                 AS data_type                    -- �f�[�^�^�C�v('0':�A�g��)
      FROM   gl_je_headers        gjh  -- �d��w�b�_
            ,gl_je_lines          gjl  -- �d�󖾍�
            ,gl_je_sources_tl     gjs  -- �d��\�[�X
            ,gl_je_batches        gjb  -- �d��o�b�`
            ,gl_code_combinations gcc  -- ����Ȗڑg�����}�X�^
            ,gl_je_categories_tl  gjc  -- �d��J�e�S���e�[�u��
            ,gl_daily_conversion_types gdct -- GL���[�g�}�X�^
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.��v����ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.period_name = iv_period_name
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s2) �����ԍ��w��̂�
    CURSOR get_gl_je_data_manual_cur2( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                    )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
            ,gjh.period_name                     AS period_name            -- ��v����
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- �L����
            ,gjh.je_source                       AS je_source              -- �d��\�[�X
            ,gjs.user_je_source_name             AS user_je_source_name    -- �d��\�[�X��
            ,gjh.je_category                     AS je_category            -- �d��J�e�S��
            ,gjc.user_je_category_name           AS user_je_category_name  -- �d��J�e�S����
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- �d�󕶏��ԍ�
            ,gjb.name                            AS bat_name               -- �d��o�b�`��
            ,gjh.name                            AS name                   -- �d��
            ,gjh.description                     AS description            -- �E�v
            ,gjl.je_line_num                     AS je_line_num            -- �d�󖾍הԍ�
            ,gjl.description                     AS je_line_description    -- �d�󖾍דE�v
            ,gcc.segment1                        AS aff_company_code       -- �`�e�e��ЃR�[�h
            ,gcc.segment2                        AS aff_department_code    -- �`�e�e����R�[�h
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- ���喼��
            ,gcc.segment3                        AS aff_account_code       -- �`�e�e����ȖڃR�[�h
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- ����Ȗږ���
            ,gcc.segment4                        AS aff_sub_account_code   -- �`�e�e�⏕�ȖڃR�[�h
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- �⏕�Ȗږ���
            ,gcc.segment5                        AS aff_partner_code       -- �`�e�e�ڋq�R�[�h
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq����
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ���
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- �\���P����
            ,gcc.segment8                        AS aff_future             -- �`�e�e�\���Q
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- �\���Q����
            ,gjl.code_combination_id             AS code_combination_id    -- ����Ȗڑg����id
            ,gjl.entered_dr                      AS entered_dr             -- �ؕ����z
            ,gjl.entered_cr                      AS entered_cr             -- �ݕ����z
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- �ŋ敪
            ,gjl.attribute2                      AS attribute2             -- �������R
            ,gjl.attribute3                      AS attribute3             -- �`�[�ԍ�
            ,gjl.attribute4                      AS attribute4             -- �N�[����
            ,gjl.attribute5                      AS attribute5             -- �`�[���͎�
            ,gjl.attribute6                      AS attribute6             -- �C�����`�[�ԍ�
            ,NULL                                AS account_code           -- ���芨�芨��ȖڃR�[�h
            ,NULL                                AS account_name           -- ���芨�芨��Ȗږ���
            ,NULL                                AS sub_account_code       -- ���芨��⏕�ȖڃR�[�h
            ,NULL                                AS sub_account_name       -- ���芨��⏕�Ȗږ���
            ,gjl.attribute8                      AS sales_exp_header_id    -- �̔����уw�b�_�[ID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --�݌Ɍ����U��
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- �⏕�땶���ԍ� 
            ,gjh.currency_code                   AS currency_code                -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type         -- ���[�g�^�C�v
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- ���Z��
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- ���Z���[�g
            ,gjl.accounted_dr                    AS accounted_dr                 -- �ؕ��@�\�ʉ݋��z
            ,gjl.accounted_cr                    AS accounted_cr                 -- �ݕ��@�\�ʉ݋��z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- �A�g����
            ,gjl.status                          AS status                       -- �X�e�[�^�X
            ,'0'                                 AS data_type                    -- �f�[�^�^�C�v('0':�A�g��)
      FROM   gl_je_headers        gjh  -- �d��w�b�_
            ,gl_je_lines          gjl  -- �d�󖾍�
            ,gl_je_sources_tl     gjs  -- �d��\�[�X
            ,gl_je_batches        gjb  -- �d��o�b�`
            ,gl_code_combinations gcc  -- ����Ȗڑg�����}�X�^
            ,gl_je_categories_tl  gjc  -- �d��J�e�S���e�[�u��
            ,gl_daily_conversion_types gdct -- GL���[�g�}�X�^
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.��v����ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id           = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND gjh.doc_sequence_value     >= iv_doc_seq_value_from
        AND gjh.doc_sequence_value     <= iv_doc_seq_value_to
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
    -- �Ώۃf�[�^�擾�J�[�\��(�蓮���s3) ��v���ԁA�����ԍ������w��
    CURSOR get_gl_je_data_manual_cur3( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                     )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- �d��w�b�_�[�h�c
            ,gjh.period_name                     AS period_name            -- ��v����
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- �L����
            ,gjh.je_source                       AS je_source              -- �d��\�[�X
            ,gjs.user_je_source_name             AS user_je_source_name    -- �d��\�[�X��
            ,gjh.je_category                     AS je_category            -- �d��J�e�S��
            ,gjc.user_je_category_name           AS user_je_category_name  -- �d��J�e�S����
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- �d�󕶏��ԍ�
            ,gjb.name                            AS bat_name               -- �d��o�b�`��
            ,gjh.name                            AS name                   -- �d��
            ,gjh.description                     AS description            -- �E�v
            ,gjl.je_line_num                     AS je_line_num            -- �d�󖾍הԍ�
            ,gjl.description                     AS je_line_description    -- �d�󖾍דE�v
            ,gcc.segment1                        AS aff_company_code       -- �`�e�e��ЃR�[�h
            ,gcc.segment2                        AS aff_department_code    -- �`�e�e����R�[�h
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- ���喼��
            ,gcc.segment3                        AS aff_account_code       -- �`�e�e����ȖڃR�[�h
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- ����Ȗږ���
            ,gcc.segment4                        AS aff_sub_account_code   -- �`�e�e�⏕�ȖڃR�[�h
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- �⏕�Ȗږ���
            ,gcc.segment5                        AS aff_partner_code       -- �`�e�e�ڋq�R�[�h
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq����
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ���
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- �\���P����
            ,gcc.segment8                        AS aff_future             -- �`�e�e�\���Q
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- �\���Q����
            ,gjl.code_combination_id             AS code_combination_id    -- ����Ȗڑg����id
            ,gjl.entered_dr                      AS entered_dr             -- �ؕ����z
            ,gjl.entered_cr                      AS entered_cr             -- �ݕ����z
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- �ŋ敪
            ,gjl.attribute2                      AS attribute2             -- �������R
            ,gjl.attribute3                      AS attribute3             -- �`�[�ԍ�
            ,gjl.attribute4                      AS attribute4             -- �N�[����
            ,gjl.attribute5                      AS attribute5             -- �`�[���͎�
            ,gjl.attribute6                      AS attribute6             -- �C�����`�[�ԍ�
            ,NULL                                AS account_code           -- ���芨�芨��ȖڃR�[�h
            ,NULL                                AS account_name           -- ���芨�芨��Ȗږ���
            ,NULL                                AS sub_account_code       -- ���芨��⏕�ȖڃR�[�h
            ,NULL                                AS sub_account_name       -- ���芨��⏕�Ȗږ���
            ,gjl.attribute8                      AS sales_exp_header_id    -- �̔����уw�b�_�[ID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --�݌Ɍ����U��
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- �⏕�땶���ԍ� 
            ,gjh.currency_code                   AS currency_code                -- �ʉ�
            ,gdct.user_conversion_type           AS user_conversion_type         -- ���[�g�^�C�v
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- ���Z��
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- ���Z���[�g
            ,gjl.accounted_dr                    AS accounted_dr                 -- �ؕ��@�\�ʉ݋��z
            ,gjl.accounted_cr                    AS accounted_cr                 -- �ݕ��@�\�ʉ݋��z
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- �A�g����
            ,gjl.status                          AS status                       -- �X�e�[�^�X
            ,'0'                                 AS data_type                    -- �f�[�^�^�C�v('0':�A�g��)
      FROM   gl_je_headers        gjh  -- �d��w�b�_
            ,gl_je_lines          gjl  -- �d�󖾍�
            ,gl_je_sources_tl     gjs  -- �d��\�[�X
            ,gl_je_batches        gjb  -- �d��o�b�`
            ,gl_code_combinations gcc  -- ����Ȗڑg�����}�X�^
            ,gl_je_categories_tl  gjc  -- �d��J�e�S���e�[�u��
            ,gl_daily_conversion_types gdct -- GL���[�g�}�X�^
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.��v����ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.period_name = iv_period_name
        AND  gjh.doc_sequence_value       >= iv_doc_seq_value_from
        AND  gjh.doc_sequence_value       <= iv_doc_seq_value_to
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
  --�d�󖢘A�g�f�[�^�擾�J�[�\��
  CURSOR  gl_je_wait_cur
  IS
    SELECT xgjwc.gl_je_header_id       -- �d��w�b�_�[�h�c
          ,xgjwc.rowid                 -- ROWID
      FROM xxcfo_gl_je_wait_coop xgjwc -- �d�󖢘A�g
    ;
    -- �e�[�u���^
    TYPE gl_je_wait_ttype IS TABLE OF gl_je_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_je_wait_tab gl_je_wait_ttype;
--
  --�t�����擾�J�[�\��(�ؕ��p)
  CURSOR aff_data_dr_cur(
    in_je_header_id  IN NUMBER       -- A-4.�d��w�b�_ID
  )
  IS
    SELECT DECODE(sub_v.count
                 ,1
                 ,xav.flex_value
                 ,NULL)                        account_code     --����抨��ȖڃR�[�h
          ,DECODE(sub_v.count
                 ,1
                 ,xav.description
                 ,gv_electric_book_p_accounts) account_name     --����抨��Ȗږ�
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.flex_value
                 ,NULL)                        sub_account_code --�����⏕�ȖڃR�[�h
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.description
                 ,gv_electric_book_p_accounts) sub_account_name --�����⏕�Ȗږ�
      FROM xx03_accounts_v     xav                         --BFA ����Ȗڃr���[
          ,xx03_sub_accounts_v xsav                        --BFA �⏕�Ȗڃr���[
          ,(SELECT COUNT(1)           count
                  ,MAX(gccv.segment3) account_code     --����ȖڃR�[�h
                  ,MAX(gccv.segment4) sub_account_code --�⏕�ȖڃR�[�h
              FROM gl_je_lines          gjlv           --�d�󖾍�
                  ,gl_code_combinations gccv           --����Ȗڑg����
             WHERE gjlv.code_combination_id = gccv.code_combination_id
               AND gjlv.je_header_id        = in_je_header_id
               AND gjlv.accounted_cr IS NULL
           ) sub_v
     WHERE xav.flex_value(+)             = sub_v.account_code
       AND xsav.parent_flex_value_low(+) = sub_v.account_code
       AND xsav.flex_value(+)            = sub_v.sub_account_code
     ;
    -- �e�[�u���^(�ؕ��p)
    TYPE aff_data_dr_ttype IS TABLE OF aff_data_dr_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    aff_data_dr_tab aff_data_dr_ttype;
  --
  --�t�����擾�J�[�\��(�ݕ��p)
  CURSOR aff_data_cr_cur(
    in_je_header_id  IN NUMBER       -- A-4.�d��w�b�_ID
  )
  IS
    SELECT DECODE(sub_v.count
                 ,1
                 ,xav.flex_value
                 ,NULL)                        account_code     --����抨��ȖڃR�[�h
          ,DECODE(sub_v.count
                 ,1
                 ,xav.description
                 ,gv_electric_book_p_accounts) account_name     --����抨��Ȗږ�
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.flex_value
                 ,NULL)                        sub_account_code --�����⏕�ȖڃR�[�h
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.description
                 ,gv_electric_book_p_accounts) sub_account_name --�����⏕�Ȗږ�
      FROM xx03_accounts_v     xav                         --BFA ����Ȗڃr���[
          ,xx03_sub_accounts_v xsav                        --BFA �⏕�Ȗڃr���[
          ,(SELECT COUNT(1)           count
                  ,MAX(gccv.segment3) account_code     --����ȖڃR�[�h
                  ,MAX(gccv.segment4) sub_account_code --�⏕�ȖڃR�[�h
              FROM gl_je_lines          gjlv           --�d�󖾍�
                  ,gl_code_combinations gccv           --����Ȗڑg����
             WHERE gjlv.code_combination_id = gccv.code_combination_id
               AND gjlv.je_header_id        = in_je_header_id
               AND gjlv.accounted_dr IS NULL
           ) sub_v
     WHERE xav.flex_value(+)             = sub_v.account_code
       AND xsav.parent_flex_value_low(+) = sub_v.account_code
       AND xsav.flex_value(+)            = sub_v.sub_account_code
     ;
    -- �e�[�u���^(�ݕ��p)
    TYPE aff_data_cr_ttype IS TABLE OF aff_data_cr_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    aff_data_cr_tab aff_data_cr_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2, -- 2.�t�@�C����
    iv_period_name        IN  VARCHAR2, -- 3.��v����
    iv_doc_seq_value_from IN  VARCHAR2, -- 4.�d�󕶏��ԍ��iFrom�j
    iv_doc_seq_value_to   IN  VARCHAR2, -- 5.�d�󕶏��ԍ��iTo�j
    iv_exec_kbn           IN  VARCHAR2, -- 6.����蓮�敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      WHERE     flv.lookup_type         =       cv_lookup_item_chk_glje
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
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
      ,iv_conc_param3  => iv_period_name        -- ��v����
      ,iv_conc_param4  => iv_doc_seq_value_from -- �d�󕶏��ԍ��iFrom�j
      ,iv_conc_param5  => iv_doc_seq_value_to   -- �d�󕶏��ԍ��iTo�j
      ,iv_conc_param6  => iv_exec_kbn           -- ����蓮�敪
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
      ,iv_conc_param3  => iv_period_name        -- ��v����
      ,iv_conc_param4  => iv_doc_seq_value_from -- �d�󕶏��ԍ��iFrom�j
      ,iv_conc_param5  => iv_doc_seq_value_to   -- �d�󕶏��ԍ��iTo�j
      ,iv_conc_param6  => iv_exec_kbn           -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ�A�`�F�b�N���s��
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      IF ( ( iv_period_name IS NULL )
        AND ( iv_doc_seq_value_from IS NULL )
        AND ( iv_doc_seq_value_to IS NULL ) )
        --�@��v���ԁA	�d�󕶏��ԍ�(From-To)����
      OR ( ( iv_doc_seq_value_from IS NOT NULL )
        AND ( iv_doc_seq_value_to IS NULL ) )
      OR ( ( iv_doc_seq_value_from IS NULL )
        AND ( iv_doc_seq_value_to IS NOT NULL ) )
        --�A�d�󕶏��ԍ�(From-To)�ǂ��炩����
      THEN
        --�`�F�b�N�@�A�A�̂ǂ��炩�ɍ��v�����ꍇ�A�G���[�Ƃ���
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10017 -- �p�����[�^���͕s��
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==================================
    -- ���̓p�����[�^���O���[�o���ϐ��Ɋi�[
    --==================================
    gv_ins_upd_kbn := iv_ins_upd_kbn; --�ǉ��X�V�敪
    gv_exec_kbn    := iv_exec_kbn;    --����蓮�敪
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
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
    --==================================
    -- �N�C�b�N�R�[�h
    --==================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    flv.attribute1 -- �d�q���돈�����s����
              , flv.attribute2 -- �����Ώێ���
      INTO      gv_electric_exec_days
              , gv_proc_target_time
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
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00031 -- �N�C�b�N�R�[�h�擾�G���[
                                                    ,cv_tkn_lookup_type
                                                    ,cv_lookup_book_date
                                                    ,cv_tkn_lookup_code
                                                    ,cv_pkg_name
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
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
    IF ( gt_item_name.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff   -- 'XXCFF'
                                                    ,cv_msg_cff_00189 -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type
                                                    ,cv_lookup_item_chk_glje
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    --�t�@�C���i�[�p�X
    gv_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name
                                                    ,cv_data_filepath
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
                                                    ,cv_tkn_prof_name
                                                    ,cv_set_of_bks_id
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�d�q���땡������敡�����莞����
    gv_electric_book_p_accounts  := FND_PROFILE.VALUE( cv_p_accounts );
    --
    IF ( gv_electric_book_p_accounts IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name
                                                    ,cv_p_accounts
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�t�@�C����
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL )
    AND ( gv_ins_upd_kbn = cv_ins_upd_0 ) THEN
      --�ǉ��t�@�C����
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name
                                                      ,cv_add_filename
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_file_name IS NULL )
    AND ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --�X�V�t�@�C����
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name
                                                      ,cv_upd_filename
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--2012/10/03 Add Start
    --
    --�d��J�e�S��_�݌Ɍ����U��
    gv_gl_ctg_inv_cost  := FND_PROFILE.VALUE( cv_gl_ctg_inv_cost );
    --
    IF ( gv_gl_ctg_inv_cost IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name
                                                    ,cv_gl_ctg_inv_cost
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
    --
    --XXCFO:�d�q����d�󒊏o�ΏۊO�d��J�e�S��
    gv_not_proc_category  := FND_PROFILE.VALUE( cv_not_proc_category );
    --
    IF ( gv_not_proc_category IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name
                                                    ,cv_not_proc_category
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2014/12/08 Ver.1.3 Add K.Oomata End
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      gv_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gv_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- �f�B���N�g���p�X�擾�G���[
                                                    ,cv_tkn_dir_tok
                                                    ,gv_file_path
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
    IF  SUBSTRB(gv_dir_path, -1, 1) = cv_slash    THEN
      gv_full_name :=  gv_dir_path || gv_file_name;
    ELSE
      gv_full_name :=  gv_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_msg_kbn_cfo
              , iv_name         => cv_msg_cfo_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => gv_full_name
              );
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
        location     =>  gv_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- �t�@�C�������݂��Ă���
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
   * Procedure Name   : get_gl_je_wait
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_gl_je_wait(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je_wait'; -- �v���O������
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
    -- �d�󖢘A�g�f�[�^�擾
    --==============================================================
    --�J�[�\���I�[�v��
    OPEN gl_je_wait_cur;
    FETCH gl_je_wait_cur BULK COLLECT INTO gl_je_wait_tab;
    --�J�[�\���N���[�Y
    CLOSE gl_je_wait_cur;
    --
--
  EXCEPTION
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
      IF gl_je_wait_cur%ISOPEN THEN
        CLOSE gl_je_wait_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_je_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_je_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_gl_je_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je_control'; -- �v���O������
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
    -- �d��Ǘ��f�[�^�J�[�\��(�������d��)
    CURSOR gl_je_control_to_cur
    IS
      SELECT xgjc.gl_je_header_id     -- �d��w�b�_ID
      FROM   xxcfo_gl_je_control xgjc -- �d��Ǘ�
      WHERE  xgjc.process_flag = cv_flag_n
      ORDER BY xgjc.gl_je_header_id DESC
              ,xgjc.creation_date   DESC
      ;
--
    -- �d��Ǘ��f�[�^�J�[�\��(�������d��)_���b�N�p
    CURSOR gl_je_control_to_lock_cur
    IS
      SELECT xgjc.gl_je_header_id     -- �d��w�b�_ID
      FROM   xxcfo_gl_je_control xgjc -- �d��Ǘ�
      WHERE  xgjc.process_flag = cv_flag_n
      ORDER BY xgjc.gl_je_header_id DESC
              ,xgjc.creation_date   DESC
      FOR UPDATE NOWAIT
      ;
--
    -- ���R�[�h�^
    TYPE gl_je_control_rec IS RECORD(
      gl_je_header_id  xxcfo_gl_je_control.gl_je_header_id%TYPE
    );
    -- �e�[�u���^
    TYPE gl_je_control_ttype IS TABLE OF gl_je_control_rec INDEX BY BINARY_INTEGER;
    gl_je_control_tab  gl_je_control_ttype;
--
    -- �d��Ǘ��f�[�^�J�[�\��(�����ώd��)�p
    CURSOR gl_je_control_from_cur
    IS
      SELECT MAX(xgjc.gl_je_header_id) gl_je_header_id -- �d��w�b�_ID
      FROM   xxcfo_gl_je_control xgjc  -- �d��Ǘ�
      WHERE  xgjc.process_flag = cv_flag_y
      ;
    -- �e�[�u���^
    TYPE gl_je_control_from_ttype IS TABLE OF gl_je_control_from_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_je_control_from_tab gl_je_control_from_ttype;
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
    --�������d��w�b�_ID�擾
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�A���b�N�p�J�[�\���I�[�v��
      OPEN gl_je_control_to_lock_cur;
      FETCH gl_je_control_to_lock_cur BULK COLLECT INTO gl_je_control_tab;
      --�J�[�\���N���[�Y
      CLOSE gl_je_control_to_lock_cur;
    ELSE
      --�蓮���s�̏ꍇ�A���b�N�����J�[�\���I�[�v��
      OPEN gl_je_control_to_cur;
      FETCH gl_je_control_to_cur BULK COLLECT INTO gl_je_control_tab;
      --�J�[�\���N���[�Y
      CLOSE gl_je_control_to_cur;
    END IF;
    --
    IF ( gl_je_control_tab.COUNT = 0 ) THEN
      -- �擾�Ώۃf�[�^����
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11001 --�d��Ǘ�
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( gl_je_control_tab.COUNT < gv_electric_exec_days ) THEN
      --�擾�����Ǘ��f�[�^�������A�d�q���돈�����s�����������ꍇ�A�d��w�b�_ID(To)��NULL��ݒ肷��
      gt_gl_je_header_id_to := NULL;
    ELSE
      --�d�q���돈�����s�������k�����Ǘ��f�[�^�̃w�b�_ID���擾
      gt_gl_je_header_id_to := gl_je_control_tab( gv_electric_exec_days ).gl_je_header_id;
    END IF;
--
    --==============================================================
    --�����ύő�d��w�b�_ID�擾(From)
    --==============================================================
    -- �d��Ǘ��f�[�^�J�[�\��(�ŐV�̏����ώd��)
    OPEN gl_je_control_from_cur;
    FETCH gl_je_control_from_cur BULK COLLECT INTO gl_je_control_from_tab;
    --�J�[�\���N���[�Y
    CLOSE gl_je_control_from_cur;
    --
    IF ( gl_je_control_from_tab.COUNT = 0 )
    OR ( gl_je_control_from_tab(1).gl_je_header_id IS NULL ) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11001 --�d��Ǘ�
                                                    )
                            ,1
                            ,5000);
      RAISE global_process_expt;
    END IF;
    --
    gt_gl_je_header_id_from := gl_je_control_from_tab(1).gl_je_header_id + 1;
--
    --==============================================================
    --�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gv_file_path
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
        ov_errmsg  := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                    ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                    ,cv_msgtkn_cfo_11001  -- �d��Ǘ�
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF gl_je_control_to_lock_cur%ISOPEN THEN
        CLOSE gl_je_control_to_lock_cur;
      END IF;
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
      IF gl_je_control_to_lock_cur%ISOPEN THEN
        CLOSE gl_je_control_to_lock_cur;
      END IF;
      IF gl_je_control_to_cur%ISOPEN THEN
        CLOSE gl_je_control_to_cur;
      END IF;
      IF gl_je_control_from_cur%ISOPEN THEN
        CLOSE gl_je_control_from_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_je_control;
--
  /**********************************************************************************
   * Procedure Name   : out_gl_je_wait
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE out_gl_je_wait(
    iv_cause        IN VARCHAR2,    -- 1.���A�g�f�[�^�o�^���R
    iv_meaning      IN VARCHAR2,    -- 2.�G���[���e
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_gl_je_wait'; -- �v���O������
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
    ln_ctl_max_gl_je_header_id NUMBER; --�ő�d��w�b�_ID(�d��Ǘ�)
    ln_hd_max_gl_je_header_id  NUMBER; --�ő�d��w�b�_ID(�d��w�b�_)
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
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�̂݁A�ȉ��̏������s��
      --==============================================================
      --�d�󖢘A�g�e�[�u���o�^
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_gl_je_wait_coop(
           gl_je_header_id        -- �d��w�b�_ID
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
           TO_NUMBER(gt_data_tab(1))
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
        --==============================================================
        --���b�Z�[�W�o��
        --==============================================================
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10007 -- ���A�g�f�[�^�o�^
                                                       ,cv_tkn_cause     -- 'CAUSE'
                                                       ,iv_cause         -- �g�[�N���l
                                                       ,cv_tkn_target    -- 'TARGET'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003)
                                                         || cv_msg_part || gt_data_tab(1)  --�d��w�b�_ID
                                                       ,cv_tkn_meaning   -- 'MEANING'
                                                       ,iv_meaning       -- �g�[�N���l
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                       ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,cv_msgtkn_cfo_11002 -- �d�󖢘A�g
                                                       ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                       ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
    ELSE
      --�蓮���s�̏ꍇ�A���b�Z�[�W�̂ݏo��
      --==============================================================
      --���b�Z�[�W�o��
      --==============================================================
      IF ( iv_cause = cv_msgtkn_cfo_11005 ) THEN
        --���芨���񖢎擾�̏ꍇ
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10034 -- ���芨���񖢎擾
                                                       ,cv_tkn_key_item       -- �g�[�N��'KEY_ITEM'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003) --�d��w�b�_ID
                                                       ,cv_tkn_key_value      -- �g�[�N��'KEY_VALUE'
                                                       ,gt_data_tab(1)  --�d��w�b�_ID
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      ELSIF ( iv_cause = cv_msgtkn_cfo_11006 ) THEN
        --���]�L�G���[�̏ꍇ
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10005 -- �d�󖢓]�L
                                                       ,cv_tkn_key_item       -- �g�[�N��'KEY_ITEM'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003) --�d��w�b�_ID
                                                       ,cv_tkn_key_value      -- �g�[�N��'KEY_VALUE'
                                                       ,gt_data_tab(1)  --�d��w�b�_ID
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
    END IF;
--
    --�X�e�[�^�X���x���ɐݒ�
    ov_retcode := cv_status_warn;
    --�x���t���O��'Y'�ɐݒ肷��
    gv_warning_flg := cv_flag_y;
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
  END out_gl_je_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_flex_information
   * Description      : �t�����擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_flex_information(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_flex_information'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --���芨����̎擾
    --==============================================================
    --�J�[�\���I�[�v��(�ؕ��p)
    OPEN aff_data_dr_cur(
            gt_data_tab(1)  --�d��w�b�_ID
           );
    FETCH aff_data_dr_cur BULK COLLECT INTO aff_data_dr_tab;
    --�J�[�\���N���[�Y
    CLOSE aff_data_dr_cur;
    --
    --�J�[�\���I�[�v��(�ݕ��p)
    OPEN aff_data_cr_cur(
            gt_data_tab(1)  --�d��w�b�_ID
           );
    FETCH aff_data_cr_cur BULK COLLECT INTO aff_data_cr_tab;
    --�J�[�\���N���[�Y
    CLOSE aff_data_cr_cur;
--
    IF ( aff_data_dr_tab.COUNT = 0 )
    OR ( aff_data_cr_tab.COUNT = 0 ) THEN
      --0���̏ꍇ���A����s�Ǎ��܂��́A�w�b�_ID�ؑ֎��̂ݓo�^���s��
      --==============================================================
      --���A�g�e�[�u���o�^����(A-8)
      --==============================================================
      out_gl_je_wait(
        iv_cause                    =>        cv_msgtkn_cfo_11005  -- '���芨����擾�G���['
      , iv_meaning                  =>        NULL                 -- A-6�̃��[�U�[�G���[���b�Z�[�W
      , ov_errbuf                   =>        lv_errbuf     -- �G���[���b�Z�[�W
      , ov_retcode                  =>        lv_retcode    -- ���^�[���R�[�h
      , ov_errmsg                   =>        lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      ELSE
        --���A�g�o�^�ς݃t���O��Y�ɂ���
        gv_wait_ins_flg := cv_flag_y;
      END IF;
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
      --�J�[�\���N���[�Y
      IF aff_data_dr_cur%ISOPEN THEN
        CLOSE aff_data_dr_cur;
      END IF;
      --�J�[�\���N���[�Y
      IF aff_data_cr_cur%ISOPEN THEN
        CLOSE aff_data_cr_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_flex_information;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT VARCHAR2,   --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
    ov_errlevel           OUT VARCHAR2,   --   �G���[���x��
    ov_msgcode            OUT VARCHAR2)   --   ���b�Z�[�W�R�[�h
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
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
    warn_expt        EXCEPTION;
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
    IF ( gt_gl_je_header_id IS NULL )
    OR ( gt_gl_je_header_id <> gt_data_tab(1) ) THEN
      --����Ǎ��܂��́A�O��Ǎ����̃w�b�_ID�ƌ��Ǎ��s�̃w�b�_ID���قȂ�ꍇ
      --���A�g�o�^�σt���O��������
      gv_wait_ins_flg := cv_flag_n;
      --==============================================================
      --�t�����擾����(A-5)
      --==============================================================
      get_flex_information(
        ov_errbuf                     =>        lv_errbuf   -- �G���[�E���b�Z�[�W
       ,ov_retcode                    =>        lv_retcode  -- ���^�[���E�R�[�h
       ,ov_errmsg                     =>        lv_errmsg); -- ���[�U�[�E�G���[�E���b�Z�[�W
      IF ( lv_retcode <> cv_status_normal ) THEN
        --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
      --
      --�ȉ��̃w�b�_�P�ʂ̃`�F�b�N���s��
      IF ( gv_exec_kbn = cv_exec_manual ) THEN
        --���׃X�L�b�v�t���O��������
        gv_line_skip_flg := cv_flag_n;
        IF ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
          --�蓮���s���A�X�V�̏ꍇ
          --==============================================================
          --�����σ`�F�b�N
          --==============================================================
          IF ( gt_gl_je_header_id_from <= gt_data_tab(1) ) THEN
            --�������d����X�V�����̑ΏۂƂ��Ă���ׁA�G���[�Ƃ���
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfo        -- XXCFO
                                   ,cv_msg_cfo_10014      -- �d�󏈗��σf�[�^�`�F�b�N�G���[
                                   ,cv_tkn_je_header_id   -- �g�[�N��'JE_HEADER_ID'
                                   ,gt_data_tab(1)         -- �d��w�b�_ID
                                   ,cv_tkn_je_doc_seq_val -- �g�[�N��'JE_DOC_SEQ_VAL'
                                   ,gt_data_tab(8)         -- �d�󕶏��ԍ�
                                   )
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg;
            ov_errlevel := cv_errlevel_header;
            RAISE global_process_expt;
          END IF;
        END IF;
        --�蓮���s�̏ꍇ
        --==============================================================
        -- ���A�g�f�[�^���݃`�F�b�N(�w�b�_�P��)
        --==============================================================
        <<gl_je_wait_chk_loop>>
        FOR i IN 1 .. gl_je_wait_tab.COUNT LOOP
          IF gl_je_wait_tab( i ).gl_je_header_id = gt_data_tab(1) THEN  --�d��w�b�_ID
            --�Ώێd�󂪖��A�g�̏ꍇ�A�x�����b�Z�[�W���o��
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfo        -- XXCFO
                                   ,cv_msg_cfo_10010      -- ���A�g�f�[�^�`�F�b�NID�G���[
                                   ,cv_tkn_doc_data       -- �g�[�N��'DOC_DATA'
                                   ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                             ,cv_msgtkn_cfo_11003)   -- '�d��w�b�_ID'
                                   ,cv_tkn_doc_dist_id    -- �g�[�N��'DOC_DIST_ID'
                                   ,gt_data_tab(1)         -- �d��w�b�_ID
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
      END IF;
      --
      --==============================================================
      -- ���]�L�`�F�b�N
      --==============================================================
      IF ( gt_data_tab(52) <> cv_status_p ) THEN
      --���]�L(�X�e�[�^�X<>'P')�̏ꍇ�A�ȉ��̏������s��
        --==============================================================
        --���A�g�e�[�u���o�^����(A-8)
        --==============================================================
        out_gl_je_wait(
          iv_cause                    =>        cv_msgtkn_cfo_11006   -- '���]�L�G���['
        , iv_meaning                  =>        NULL                  -- A-6�̃��[�U�[�G���[���b�Z�[�W
        , ov_errbuf                   =>        lv_errbuf     -- �G���[���b�Z�[�W
        , ov_retcode                  =>        lv_retcode    -- ���^�[���R�[�h
        , ov_errmsg                   =>        lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        ELSE
          gv_wait_ins_flg := cv_flag_y; --���A�g�o�^��
        END IF;
      END IF;
      --
    END IF;
    --
    IF ( gv_wait_ins_flg = cv_flag_n ) THEN
      --���A�g�o�^������Ă��Ȃ�(���芨��擾��)�̏ꍇ�A�ȉ����s��
      --==============================================================
      -- �擾�������芨�����A-4�擾�f�[�^�̊Y�����ڂɐݒ肷��
      --==============================================================
      IF ( gt_data_tab(30) IS NULL ) THEN
        --�ؕ����z����(���g���ݕ�)�̏ꍇ�A���芨��̎ؕ���ݒ�
        gt_data_tab(38) := aff_data_dr_tab(1).account_code;     -- ���芨�芨��ȖڃR�[�h
        gt_data_tab(39) := aff_data_dr_tab(1).account_name;     -- ���芨�芨��Ȗږ���
        gt_data_tab(40) := aff_data_dr_tab(1).sub_account_code; -- ���芨��⏕�ȖڃR�[�h
        gt_data_tab(41) := aff_data_dr_tab(1).sub_account_name; -- ���芨��⏕�Ȗږ���
      ELSIF ( gt_data_tab(31) IS NULL ) THEN
        --�ݕ����z����(���g���ؕ�)�̏ꍇ�A���芨��̑ݕ���ݒ�
        gt_data_tab(38) := aff_data_cr_tab(1).account_code;     -- ���芨�芨��ȖڃR�[�h
        gt_data_tab(39) := aff_data_cr_tab(1).account_name;     -- ���芨�芨��Ȗږ���
        gt_data_tab(40) := aff_data_cr_tab(1).sub_account_code; -- ���芨��⏕�ȖڃR�[�h
        gt_data_tab(41) := aff_data_cr_tab(1).sub_account_name; -- ���芨��⏕�Ȗږ���
      END IF;
    END IF;
--
    IF ( gt_data_tab(52) = cv_status_p ) THEN
    --�]�L�ς݂̏ꍇ�A���`�F�b�N���s��
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
          ov_retcode          := lv_retcode;
          ov_errlevel         := cv_errlevel_line; --'LINE'
          ov_msgcode          := lv_errbuf;        --�߂胁�b�Z�[�W�R�[�h
          ov_errmsg           := lv_errmsg;        --�߂胁�b�Z�[�W
          EXIT; --LOOP�𔲂���
        ELSIF ( lv_retcode = cv_status_error ) THEN
          ov_errmsg   := lv_errmsg;
          ov_errlevel := cv_errlevel_line; --'LINE'
          RAISE global_api_others_expt;
        END IF;
        --
        IF ( ln_cnt = gt_item_name.COUNT ) THEN
          --�S���ڂ�����l�̏ꍇ
          ov_errlevel := cv_errlevel_line; --'LINE'
        END IF;
      END LOOP;
    END IF;
--
  EXCEPTION
--
    -- *** ���A�g�f�[�^���݌x���n���h�� ***
    WHEN warn_expt THEN
      gv_line_skip_flg := cv_flag_y;
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;      --�x��
      ov_errlevel := cv_errlevel_header;  --�G���[���x��
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
   * Description      : �b�r�u�o�͏���(A-7)
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
    --�f�[�^�ҏW
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP 
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        gv_file_data  :=  gv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        gv_file_data  :=  gv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --�A�g����
    gv_file_data  :=  gv_file_data || lv_delimit || gt_data_tab(51);
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,gv_file_data
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
        ov_errmsg  := lv_errmsg;
      RAISE  global_api_others_expt;
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
   * Procedure Name   : get_gl_je
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_gl_je(
    iv_period_name          IN VARCHAR2, -- 1.��v����
    iv_doc_seq_value_from   IN VARCHAR2, -- 2.�d�󕶏��ԍ��iFrom�j
    iv_doc_seq_value_to     IN VARCHAR2, -- 3.�d�󕶏��ԍ��iTo�j
    it_gl_je_header_id_from IN xxcfo_gl_je_control.gl_je_header_id%TYPE, -- 4.�d��w�b�_ID(From)
    it_gl_je_header_id_to   IN xxcfo_gl_je_control.gl_je_header_id%TYPE, -- 5.�d��w�b�_ID(To)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je'; -- �v���O������
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
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-6�̖߂胁�b�Z�[�W�R�[�h(�^���`�F�b�N)
    lv_tkn_name1              VARCHAR2(50);  -- �g�[�N�����P
    lv_tkn_val1               VARCHAR2(50);  -- �g�[�N���l�P
    lv_tkn_name2              VARCHAR2(50);  -- �g�[�N�����Q
    lv_tkn_val2               VARCHAR2(50);  -- �g�[�N���l�Q
    lv_tkn_name3              VARCHAR2(50);  -- �g�[�N�����R
    lv_tkn_val3               VARCHAR2(50);  -- �g�[�N���l�R
    lv_line_chk_skip_flg      VARCHAR2(1) DEFAULT 'N'; --���׃`�F�b�N�X�L�b�v�t���O
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
    --�Ώۃf�[�^�擾
    --==============================================================
    --==============================================================
    -- 1 �蓮���s�̏ꍇ
    --==============================================================
    IF  gv_exec_kbn          =   cv_exec_manual   THEN
      -- ��v���Ԏw��
      IF (  iv_period_name        IS NOT NULL 
        AND iv_doc_seq_value_from IS NULL     ) THEN
        --�J�[�\���I�[�v��
        OPEN get_gl_je_data_manual_cur1( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur1 INTO
              gt_data_tab(1)  -- �d��w�b�_�[�h�c
            , gt_data_tab(2)  -- ��v����
            , gt_data_tab(3)  -- �L����
            , gt_data_tab(4)  -- �d��\�[�X
            , gt_data_tab(5)  -- �d��\�[�X��
            , gt_data_tab(6)  -- �d��J�e�S��
            , gt_data_tab(7)  -- �d��J�e�S����
            , gt_data_tab(8)  -- �d�󕶏��ԍ�
            , gt_data_tab(9)  -- �d��o�b�`��
            , gt_data_tab(10) -- �d��
            , gt_data_tab(11) -- �E�v
            , gt_data_tab(12) -- �d�󖾍הԍ�
            , gt_data_tab(13) -- �d�󖾍דE�v
            , gt_data_tab(14) -- �`�e�e��ЃR�[�h
            , gt_data_tab(15) -- �`�e�e����R�[�h
            , gt_data_tab(16) -- ���喼�� 
            , gt_data_tab(17) -- �`�e�e����ȖڃR�[�h
            , gt_data_tab(18) -- ����Ȗږ��� 
            , gt_data_tab(19) -- �`�e�e�⏕�ȖڃR�[�h
            , gt_data_tab(20) -- �⏕�Ȗږ���
            , gt_data_tab(21) -- �`�e�e�ڋq�R�[�h
            , gt_data_tab(22) -- �ڋq����
            , gt_data_tab(23) -- �`�e�e��ƃR�[�h
            , gt_data_tab(24) -- ��Ɩ���
            , gt_data_tab(25) -- �`�e�e�\���P
            , gt_data_tab(26) -- �\���P����
            , gt_data_tab(27) -- �`�e�e�\���Q
            , gt_data_tab(28) -- �\���Q����
            , gt_data_tab(29) -- ����Ȗڑg����id
            , gt_data_tab(30) -- �ؕ����z
            , gt_data_tab(31) -- �ݕ����z
            , gt_data_tab(32) -- �ŋ敪
            , gt_data_tab(33) -- �������R
            , gt_data_tab(34) -- �`�[�ԍ�
            , gt_data_tab(35) -- �N�[����
            , gt_data_tab(36) -- �`�[���͎�
            , gt_data_tab(37) -- �C�����`�[�ԍ�
            , gt_data_tab(38) -- ���芨�芨��ȖڃR�[�h
            , gt_data_tab(39) -- ���芨�芨��Ȗږ���
            , gt_data_tab(40) -- ���芨��⏕�ȖڃR�[�h
            , gt_data_tab(41) -- ���芨��⏕�Ȗږ���
            , gt_data_tab(42) -- �̔����уw�b�_�[ID
            , gt_data_tab(43) -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l 
            , gt_data_tab(44) -- �⏕�땶���ԍ� 
            , gt_data_tab(45) -- �ʉ�
            , gt_data_tab(46) -- ���[�g�^�C�v
            , gt_data_tab(47) -- ���Z��
            , gt_data_tab(48) -- ���Z���[�g
            , gt_data_tab(49) -- �ؕ��@�\�ʉ݋��z
            , gt_data_tab(50) -- �ݕ��@�\�ʉ݋��z
            , gt_data_tab(51) -- �A�g����
            , gt_data_tab(52) -- �X�e�[�^�X
            , gt_data_tab(53) -- �f�[�^�^�C�v
            ;
          EXIT WHEN get_gl_je_data_manual_cur1%NOTFOUND;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- �G���[�E���b�Z�[�W
           ,ov_retcode                    =>        lv_retcode   -- ���^�[���E�R�[�h
           ,ov_errmsg                     =>        lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errlevel                   =>        lv_errlevel  -- �G���[���x��(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- ���b�Z�[�W�R�[�h
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- �w�b�_�P�ʁA���גP�ʂ̃`�F�b�N�Ƃ��ɐ���̏ꍇ�ACSV�o�͂��s��
              --==============================================================
              -- CSV�o�͏���(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --���גP�ʂ̃`�F�b�N���G���[�܂��͌x���̏ꍇ�G���[�I��
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- �d��w�b�_ID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- �d�󖾍הԍ�
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- �d��w�b�_ID
              END IF;
              lv_errbuf := lv_errmsg;
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              --�����𒆒f
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --�w�b�_�P�ʂŌx���̏ꍇ�A�x���t���O��'Y'�ɂ���
              gv_warning_flg := cv_flag_y;
              --���׃X�L�b�v�t���O��'Y'�ɂ���
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --�w�b�_�P�ʂŃG���[�̏ꍇ�A�������I������
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --�s�P�ʂ̏����I�����ɁA���Ǎ��s�̃w�b�_ID��ϐ��Ɋi�[����(�w�b�_�Ɩ��ׂ̔��f�p)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur1;
--
      -- �d�󕶏��ԍ��w��
      ELSIF (  iv_period_name     IS NULL 
        AND iv_doc_seq_value_from IS NOT NULL ) THEN
        OPEN get_gl_je_data_manual_cur2( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur2 INTO
              gt_data_tab(1)  -- �d��w�b�_�[�h�c
            , gt_data_tab(2)  -- ��v����
            , gt_data_tab(3)  -- �L����
            , gt_data_tab(4)  -- �d��\�[�X
            , gt_data_tab(5)  -- �d��\�[�X��
            , gt_data_tab(6)  -- �d��J�e�S��
            , gt_data_tab(7)  -- �d��J�e�S����
            , gt_data_tab(8)  -- �d�󕶏��ԍ�
            , gt_data_tab(9)  -- �d��o�b�`��
            , gt_data_tab(10) -- �d��
            , gt_data_tab(11) -- �E�v
            , gt_data_tab(12) -- �d�󖾍הԍ�
            , gt_data_tab(13) -- �d�󖾍דE�v
            , gt_data_tab(14) -- �`�e�e��ЃR�[�h
            , gt_data_tab(15) -- �`�e�e����R�[�h
            , gt_data_tab(16) -- ���喼�� 
            , gt_data_tab(17) -- �`�e�e����ȖڃR�[�h
            , gt_data_tab(18) -- ����Ȗږ��� 
            , gt_data_tab(19) -- �`�e�e�⏕�ȖڃR�[�h
            , gt_data_tab(20) -- �⏕�Ȗږ���
            , gt_data_tab(21) -- �`�e�e�ڋq�R�[�h
            , gt_data_tab(22) -- �ڋq����
            , gt_data_tab(23) -- �`�e�e��ƃR�[�h
            , gt_data_tab(24) -- ��Ɩ���
            , gt_data_tab(25) -- �`�e�e�\���P
            , gt_data_tab(26) -- �\���P����
            , gt_data_tab(27) -- �`�e�e�\���Q
            , gt_data_tab(28) -- �\���Q����
            , gt_data_tab(29) -- ����Ȗڑg����id
            , gt_data_tab(30) -- �ؕ����z
            , gt_data_tab(31) -- �ݕ����z
            , gt_data_tab(32) -- �ŋ敪
            , gt_data_tab(33) -- �������R
            , gt_data_tab(34) -- �`�[�ԍ�
            , gt_data_tab(35) -- �N�[����
            , gt_data_tab(36) -- �`�[���͎�
            , gt_data_tab(37) -- �C�����`�[�ԍ�
            , gt_data_tab(38) -- ���芨�芨��ȖڃR�[�h
            , gt_data_tab(39) -- ���芨�芨��Ȗږ���
            , gt_data_tab(40) -- ���芨��⏕�ȖڃR�[�h
            , gt_data_tab(41) -- ���芨��⏕�Ȗږ���
            , gt_data_tab(42) -- �̔����уw�b�_�[ID
            , gt_data_tab(43) -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l 
            , gt_data_tab(44) -- �⏕�땶���ԍ� 
            , gt_data_tab(45) -- �ʉ�
            , gt_data_tab(46) -- ���[�g�^�C�v
            , gt_data_tab(47) -- ���Z��
            , gt_data_tab(48) -- ���Z���[�g
            , gt_data_tab(49) -- �ؕ��@�\�ʉ݋��z
            , gt_data_tab(50) -- �ݕ��@�\�ʉ݋��z
            , gt_data_tab(51) -- �A�g����
            , gt_data_tab(52) -- �X�e�[�^�X
            , gt_data_tab(53) -- �f�[�^�^�C�v
            ;
          EXIT WHEN get_gl_je_data_manual_cur2%NOTFOUND;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- �G���[�E���b�Z�[�W
           ,ov_retcode                    =>        lv_retcode   -- ���^�[���E�R�[�h
           ,ov_errmsg                     =>        lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errlevel                   =>        lv_errlevel  -- �G���[���x��(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- ���b�Z�[�W�R�[�h
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- �w�b�_�P�ʁA���גP�ʂ̃`�F�b�N�Ƃ��ɐ���̏ꍇ�ACSV�o�͂��s��
              --==============================================================
              -- CSV�o�͏���(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --���גP�ʂ̃`�F�b�N���G���[�܂��͌x���̏ꍇ�G���[�I��
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- �d��w�b�_ID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- �d�󖾍הԍ�
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- �d��w�b�_ID
              END IF;
              lv_errbuf := lv_errmsg;
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              --�����𒆒f
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --�w�b�_�P�ʂŌx���̏ꍇ�A�x���t���O��'Y'�ɂ���
              gv_warning_flg := cv_flag_y;
              --���׃X�L�b�v�t���O��'Y'�ɂ���
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --�w�b�_�P�ʂŃG���[�̏ꍇ�A�������I������
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --�s�P�ʂ̏����I�����ɁA���Ǎ��s�̃w�b�_ID��ϐ��Ɋi�[����(�w�b�_�Ɩ��ׂ̔��f�p)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur2;
      ELSE
        --��v���ԁA�d�󕶏��ԍ������w�肳��Ă���ꍇ
        OPEN get_gl_je_data_manual_cur3( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur3 INTO
              gt_data_tab(1)  -- �d��w�b�_�[�h�c
            , gt_data_tab(2)  -- ��v����
            , gt_data_tab(3)  -- �L����
            , gt_data_tab(4)  -- �d��\�[�X
            , gt_data_tab(5)  -- �d��\�[�X��
            , gt_data_tab(6)  -- �d��J�e�S��
            , gt_data_tab(7)  -- �d��J�e�S����
            , gt_data_tab(8)  -- �d�󕶏��ԍ�
            , gt_data_tab(9)  -- �d��o�b�`��
            , gt_data_tab(10) -- �d��
            , gt_data_tab(11) -- �E�v
            , gt_data_tab(12) -- �d�󖾍הԍ�
            , gt_data_tab(13) -- �d�󖾍דE�v
            , gt_data_tab(14) -- �`�e�e��ЃR�[�h
            , gt_data_tab(15) -- �`�e�e����R�[�h
            , gt_data_tab(16) -- ���喼�� 
            , gt_data_tab(17) -- �`�e�e����ȖڃR�[�h
            , gt_data_tab(18) -- ����Ȗږ��� 
            , gt_data_tab(19) -- �`�e�e�⏕�ȖڃR�[�h
            , gt_data_tab(20) -- �⏕�Ȗږ���
            , gt_data_tab(21) -- �`�e�e�ڋq�R�[�h
            , gt_data_tab(22) -- �ڋq����
            , gt_data_tab(23) -- �`�e�e��ƃR�[�h
            , gt_data_tab(24) -- ��Ɩ���
            , gt_data_tab(25) -- �`�e�e�\���P
            , gt_data_tab(26) -- �\���P����
            , gt_data_tab(27) -- �`�e�e�\���Q
            , gt_data_tab(28) -- �\���Q����
            , gt_data_tab(29) -- ����Ȗڑg����id
            , gt_data_tab(30) -- �ؕ����z
            , gt_data_tab(31) -- �ݕ����z
            , gt_data_tab(32) -- �ŋ敪
            , gt_data_tab(33) -- �������R
            , gt_data_tab(34) -- �`�[�ԍ�
            , gt_data_tab(35) -- �N�[����
            , gt_data_tab(36) -- �`�[���͎�
            , gt_data_tab(37) -- �C�����`�[�ԍ�
            , gt_data_tab(38) -- ���芨�芨��ȖڃR�[�h
            , gt_data_tab(39) -- ���芨�芨��Ȗږ���
            , gt_data_tab(40) -- ���芨��⏕�ȖڃR�[�h
            , gt_data_tab(41) -- ���芨��⏕�Ȗږ���
            , gt_data_tab(42) -- �̔����уw�b�_�[ID
            , gt_data_tab(43) -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l 
            , gt_data_tab(44) -- �⏕�땶���ԍ� 
            , gt_data_tab(45) -- �ʉ�
            , gt_data_tab(46) -- ���[�g�^�C�v
            , gt_data_tab(47) -- ���Z��
            , gt_data_tab(48) -- ���Z���[�g
            , gt_data_tab(49) -- �ؕ��@�\�ʉ݋��z
            , gt_data_tab(50) -- �ݕ��@�\�ʉ݋��z
            , gt_data_tab(51) -- �A�g����
            , gt_data_tab(52) -- �X�e�[�^�X
            , gt_data_tab(53) -- �f�[�^�^�C�v
            ;
          EXIT WHEN get_gl_je_data_manual_cur3%NOTFOUND;
--
          --==============================================================
          --���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- �G���[�E���b�Z�[�W
           ,ov_retcode                    =>        lv_retcode   -- ���^�[���E�R�[�h
           ,ov_errmsg                     =>        lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errlevel                   =>        lv_errlevel  -- �G���[���x��(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- ���b�Z�[�W�R�[�h
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- �w�b�_�P�ʁA���גP�ʂ̃`�F�b�N�Ƃ��ɐ���̏ꍇ�ACSV�o�͂��s��
              --==============================================================
              -- CSV�o�͏���(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --���גP�ʂ̃`�F�b�N���G���[�܂��͌x���̏ꍇ�G���[�I��
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- �d��w�b�_ID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- �d�󖾍הԍ�
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- �d��w�b�_ID
              END IF;
              lv_errbuf := lv_errmsg;
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              --�����𒆒f
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --�w�b�_�P�ʂŌx���̏ꍇ�A�x���t���O��'Y'�ɂ���
              gv_warning_flg := cv_flag_y;
              --���׃X�L�b�v�t���O��'Y'�ɂ���
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --�w�b�_�P�ʂŃG���[�̏ꍇ�A�������I������
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --�s�P�ʂ̏����I�����ɁA���Ǎ��s�̃w�b�_ID��ϐ��Ɋi�[����(�w�b�_�Ɩ��ׂ̔��f�p)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
--
    --==============================================================
    -- 2 �莞���s�̏ꍇ
    --==============================================================
    ELSIF gv_exec_kbn        =   cv_exec_fixed_period   THEN
      --�J�[�\���I�[�v��
      OPEN get_gl_je_data_fixed_cur( it_gl_je_header_id_from
                                    ,it_gl_je_header_id_to
                                     );
      <<main_loop>>
      LOOP
      FETCH get_gl_je_data_fixed_cur INTO
            gt_data_tab(1)  -- �d��w�b�_�[�h�c
          , gt_data_tab(2)  -- ��v����
          , gt_data_tab(3)  -- �L����
          , gt_data_tab(4)  -- �d��\�[�X
          , gt_data_tab(5)  -- �d��\�[�X��
          , gt_data_tab(6)  -- �d��J�e�S��
          , gt_data_tab(7)  -- �d��J�e�S����
          , gt_data_tab(8)  -- �d�󕶏��ԍ�
          , gt_data_tab(9)  -- �d��o�b�`��
          , gt_data_tab(10) -- �d��
          , gt_data_tab(11) -- �E�v
          , gt_data_tab(12) -- �d�󖾍הԍ�
          , gt_data_tab(13) -- �d�󖾍דE�v
          , gt_data_tab(14) -- �`�e�e��ЃR�[�h
          , gt_data_tab(15) -- �`�e�e����R�[�h
          , gt_data_tab(16) -- ���喼�� 
          , gt_data_tab(17) -- �`�e�e����ȖڃR�[�h
          , gt_data_tab(18) -- ����Ȗږ��� 
          , gt_data_tab(19) -- �`�e�e�⏕�ȖڃR�[�h
          , gt_data_tab(20) -- �⏕�Ȗږ���
          , gt_data_tab(21) -- �`�e�e�ڋq�R�[�h
          , gt_data_tab(22) -- �ڋq����
          , gt_data_tab(23) -- �`�e�e��ƃR�[�h
          , gt_data_tab(24) -- ��Ɩ���
          , gt_data_tab(25) -- �`�e�e�\���P
          , gt_data_tab(26) -- �\���P����
          , gt_data_tab(27) -- �`�e�e�\���Q
          , gt_data_tab(28) -- �\���Q����
          , gt_data_tab(29) -- ����Ȗڑg����id
          , gt_data_tab(30) -- �ؕ����z
          , gt_data_tab(31) -- �ݕ����z
          , gt_data_tab(32) -- �ŋ敪
          , gt_data_tab(33) -- �������R
          , gt_data_tab(34) -- �`�[�ԍ�
          , gt_data_tab(35) -- �N�[����
          , gt_data_tab(36) -- �`�[���͎�
          , gt_data_tab(37) -- �C�����`�[�ԍ�
          , gt_data_tab(38) -- ���芨�芨��ȖڃR�[�h
          , gt_data_tab(39) -- ���芨�芨��Ȗږ���
          , gt_data_tab(40) -- ���芨��⏕�ȖڃR�[�h
          , gt_data_tab(41) -- ���芨��⏕�Ȗږ���
          , gt_data_tab(42) -- �̔����уw�b�_�[ID
          , gt_data_tab(43) -- ���Y�Ǘ��L�[�݌ɊǗ��L�[�l 
          , gt_data_tab(44) -- �⏕�땶���ԍ� 
          , gt_data_tab(45) -- �ʉ�
          , gt_data_tab(46) -- ���[�g�^�C�v
          , gt_data_tab(47) -- ���Z��
          , gt_data_tab(48) -- ���Z���[�g
          , gt_data_tab(49) -- �ؕ��@�\�ʉ݋��z
          , gt_data_tab(50) -- �ݕ��@�\�ʉ݋��z
          , gt_data_tab(51) -- �A�g����
          , gt_data_tab(52) -- �X�e�[�^�X
          , gt_data_tab(53) -- �f�[�^�^�C�v
          ;
        EXIT WHEN get_gl_je_data_fixed_cur%NOTFOUND;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-6)
        --==============================================================
        chk_item(
          ov_errbuf                     =>        lv_errbuf    -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>        lv_retcode   -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>        lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,ov_errlevel                   =>        lv_errlevel  -- �G���[���x��(HEAD,LINE,P)
         ,ov_msgcode                    =>        lv_msgcode); -- ���b�Z�[�W�R�[�h
        IF ( lv_errlevel = cv_errlevel_line ) THEN
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ���גP�ʂ̃`�F�b�N������̏ꍇ�ACSV�o�͂��s��
            --==============================================================
            -- CSV�o�͏���(A-7)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
              --���גP�ʂ̃`�F�b�N���x�����A������s�̏ꍇ
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --�����I�[�o�[�̏ꍇ�A�x�����b�Z�[�W���o�͂��A�㑱�����͍s��Ȃ�
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                        ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- �d��w�b�_ID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- �d�󖾍הԍ�
                                        )
                                      ,1
                                      ,5000);
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
              ELSIF ( gv_wait_ins_flg = cv_flag_n ) THEN
                --�܂����A�g�ɓo�^����Ă��Ȃ��ꍇ
                --==============================================================
                --���A�g�e�[�u���o�^����(A-8)
                --==============================================================
                out_gl_je_wait(
                  iv_cause                    =>        cv_msgtkn_cfo_11007 -- '���׃`�F�b�N�G���['
                , iv_meaning                  =>        lv_errmsg     -- A-6�̃��[�U�[�G���[���b�Z�[�W
                , ov_errbuf                   =>        lv_errbuf     -- �G���[���b�Z�[�W
                , ov_retcode                  =>        lv_retcode    -- ���^�[���R�[�h
                , ov_errmsg                   =>        lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
                );
                IF ( lv_retcode = cv_status_error ) THEN
                  --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
                  gv_0file_flg := cv_flag_y;
                  RAISE global_process_expt;
                ELSE
                  gv_wait_ins_flg := cv_flag_y; --�o�^��
                END IF;
              END IF;
            END IF;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            --���גP�ʂ̃`�F�b�N���G���[�̏ꍇ�A�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
            gv_0file_flg := cv_flag_y;
            --�����𒆒f
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_errlevel = cv_errlevel_header )
          AND ( lv_retcode = cv_status_error ) THEN
          --�w�b�_�P�ʂŃG���[�̏ꍇ�A�������I������
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          --�����̏����Ōx�������������ꍇ�A�x���t���O��Y��ݒ肷��
          gv_warning_flg := cv_flag_y;
        END IF;
        --�s�P�ʂ̏����I�����ɁA���Ǎ��s�̃w�b�_ID��ϐ��Ɋi�[����(�w�b�_�Ɩ��ׂ̔��f�p)
        gt_gl_je_header_id := gt_data_tab(1);
      END LOOP main_loop;
      CLOSE get_gl_je_data_fixed_cur;
    END IF;
--
    --==================================================================
    -- 0���̏ꍇ�̓��b�Z�[�W�o��
    --==================================================================
    IF ( gn_target_cnt + gn_target_wait_cnt ) = 0 THEN
      gv_warning_flg := cv_flag_y; --�x���t���O��Y�ɂ���
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                      ,cv_tkn_get_data       -- �g�[�N��'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11039   -- �Ώێd����
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
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_je;
--
  /**********************************************************************************
   * Procedure Name   : upd_gl_je_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE upd_gl_je_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gl_je_control'; -- �v���O������
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
    ln_ctl_max_gl_je_header_id NUMBER; --�ő�d��w�b�_ID(�d��Ǘ�)
    ln_hd_max_gl_je_header_id  NUMBER; --�ő�d��w�b�_ID(�d��w�b�_)
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
      FOR i IN 1 .. gl_je_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_gl_je_wait_coop xgjwc --�d�󖢘A�g
          WHERE xgjwc.rowid = gl_je_wait_tab( i ).rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                  ( cv_msg_kbn_cfo     -- XXCFO
                                    ,cv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                    ,cv_tkn_table       -- �g�[�N��'TABLE'
                                    ,cv_msgtkn_cfo_11002 -- �d�󖢘A�g
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
      --�d��Ǘ��e�[�u���X�V
      --==============================================================
      BEGIN
        UPDATE xxcfo_gl_je_control xgjc --�d��Ǘ�
        SET xgjc.process_flag           = cv_flag_y                 -- �����σt���O
           ,xgjc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,xgjc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           ,xgjc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,xgjc.request_id             = cn_request_id             -- �v��ID
           ,xgjc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,xgjc.program_id             = cn_program_id             -- �v���O����ID
           ,xgjc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE xgjc.process_flag         = cv_flag_n                 -- �����σt���O'N'
          AND xgjc.gl_je_header_id      <= gt_gl_je_header_id_to    -- A-3�Ŏ擾�����d��w�b�_ID(To)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00020   -- �f�[�^�X�V�G���[
                                                       ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,cv_msgtkn_cfo_11001 -- �d��Ǘ�
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
      --�d��Ǘ��e�[�u���o�^
      --==============================================================
      --�d��Ǘ��f�[�^����ő�̎d��w�b�_ID���擾
      BEGIN
        SELECT MAX(xgjc.gl_je_header_id)
          INTO ln_ctl_max_gl_je_header_id
          FROM xxcfo_gl_je_control xgjc
        ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                     ,cv_msgtkn_cfo_11041 --�d��f�[�^
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --�����쐬���ꂽ�d��w�b�_ID�̍ő�l���擾
      BEGIN
--2012/12/18 Ver.1.2 Mod Start
--        SELECT NVL(MAX(gjh.je_header_id),ln_ctl_max_gl_je_header_id)
        SELECT /*+ INDEX(gjh GL_JE_HEADERS_U1) */
               NVL(MAX(gjh.je_header_id),ln_ctl_max_gl_je_header_id)
--2012/12/18 Ver.1.2 Mod End
          INTO ln_hd_max_gl_je_header_id
          FROM gl_je_headers gjh
         WHERE gjh.je_header_id > ln_ctl_max_gl_je_header_id
           AND gjh.creation_date < ( gd_process_date + 1 + NVL(gv_proc_target_time,0) / 24 )
        ;
      END;
--
      --�d��Ǘ��e�[�u���o�^
      BEGIN
        INSERT INTO xxcfo_gl_je_control(
           business_date          -- �Ɩ����t
          ,gl_je_header_id        -- �d��w�b�_ID
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
          ,ln_hd_max_gl_je_header_id
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
                                                       ,cv_msgtkn_cfo_11001 -- �d��Ǘ�
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
  END upd_gl_je_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2, -- 2.�t�@�C����
    iv_period_name        IN  VARCHAR2, -- 3.��v����
    iv_doc_seq_value_from IN  VARCHAR2, -- 4.�d�󕶏��ԍ��iFrom�j
    iv_doc_seq_value_to   IN  VARCHAR2, -- 5.�d�󕶏��ԍ��iTo�j
    iv_exec_kbn           IN  VARCHAR2, -- 6.����蓮�敪
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
       iv_ins_upd_kbn        -- 1.�ǉ��X�V�敪
      ,iv_file_name          -- 2.�t�@�C����
      ,iv_period_name        -- 3.��v����
      ,iv_doc_seq_value_from -- 4.�d�󕶏��ԍ��iFrom�j
      ,iv_doc_seq_value_to   -- 5.�d�󕶏��ԍ��iTo�j
      ,iv_exec_kbn           -- 6.����蓮�敪
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
    get_gl_je_wait(
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
    get_gl_je_control(
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
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --�蓮���s�̏ꍇ
      get_gl_je(
        iv_period_name,        -- 1.��v����
        iv_doc_seq_value_from, -- 2.�d�󕶏��ԍ�(From)
        iv_doc_seq_value_to,   -- 3.�d�󕶏��ԍ�(To)
        NULL,                  -- 4.�d��w�b�_ID(From)
        NULL,                  -- 5.�d��w�b�_ID(To)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ELSIF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ
      get_gl_je(
        NULL,                   -- 1.��v����
        NULL,                   -- 2.�d�󕶏��ԍ��iFrom�j
        NULL,                   -- 3.�d�󕶏��ԍ��iTo�j
        gt_gl_je_header_id_from,-- 4.�d��w�b�_ID(From)
        gt_gl_je_header_id_to,  -- 5.�d��w�b�_ID(To)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-9)
    -- ===============================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s�̏ꍇ�̂݁A�ȉ��̏������s��
      upd_gl_je_control(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
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
    iv_period_name        IN  VARCHAR2,      -- 3.��v����
    iv_doc_seq_value_from IN  VARCHAR2,      -- 4.�d�󕶏��ԍ��iFrom�j
    iv_doc_seq_value_to   IN  VARCHAR2,      -- 5.�d�󕶏��ԍ��iTo�j
    iv_exec_kbn           IN  VARCHAR2       -- 6.����蓮�敪
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
      ,iv_period_name                              -- 3.��v����
      ,iv_doc_seq_value_from                       -- 4.�d�󕶏��ԍ��iFrom�j
      ,iv_doc_seq_value_to                         -- 5.�d�󕶏��ԍ��iTo�j
      ,iv_exec_kbn                                 -- 6.����蓮�敪
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
        gv_file_hand := UTL_FILE.FOPEN( gv_file_path
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
END XXCFO019A02C;
/