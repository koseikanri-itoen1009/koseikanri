CREATE OR REPLACE PACKAGE BODY XXCFO019A08C  
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A08C(body)
 * Description      : �d�q���뎩�̋@�̔��萔���̏��n�V�X�e���A�g
 * MD.050           : �d�q���뎩�̋@�̔��萔���̏��n�V�X�e���A�g <MD050_CFO_019_A08>
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  init                         ��������(A-1)
 *  get_bm_balance_control       �Ǘ��e�[�u���f�[�^�擾����(A-2)
 *  get_bm_rtn_info              �g�ݖ߂��Ǘ��f�[�^���A�g�e�[�u���ǉ�(A-3)
 *  get_bm_balance_wait          ���A�g�f�[�^�擾����(A-4)
 *  get_bm_balance_rtn_info      �g�ݖ߂����擾����(A-6)
 *  chk_item                     ���ڃ`�F�b�N����(A-7)
 *  out_csv                      �b�r�u�o�͏���(A-8)
 *  ins_bm_balance_wait_coop     ���A�g�e�[�u���o�^����(A-9)
 *  get_bm_balance               �Ώۃf�[�^���o(A-5)
 *  upd_bm_balance_control       �Ǘ��e�[�u���o�^�E�X�V����(A-10)
 *  del_bm_balance_wait          ���A�g�e�[�u���폜����(A-11)
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                               �I������(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/24    1.0   T.Osawa          �V�K�쐬
 *  2012/11/28    1.1   T.Osawa          �Ǘ��e�[�u���X�V�Ή��A�蓮���s���i�f�k���A�g�Ή��j
 *  2012/12/18    1.2   T.Ishiwata       ���\���P�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �X�L�b�v����
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
  -- *** ���b�N�G���[�n���h�� ***
  global_lock_fail          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                           CONSTANT VARCHAR2(100) := 'XXCFO019A08C';         -- �p�b�P�[�W��
  --�v���t�@�C��
  cv_data_filepath                      CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_add_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_BM_BALANCE_I_FILENAME'; -- �d�q���뎩�̋@�̔��萔���ǉ��t�@�C����
  cv_upd_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_BM_BALANCE_U_FILENAME'; -- �d�q���뎩�̋@�̔��萔���X�V�t�@�C����
  cv_org_id                             CONSTANT VARCHAR2(100) := 'ORG_ID';                                     -- �c�ƒP��
  -- ���b�Z�[�W
  cv_msg_cff_00101                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00101';   --�擾�Ɏ��s
  cv_msg_cff_00165                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00165';   --�擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_cfo_00001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[
  cv_msg_cfo_00019                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00025                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --�t�@�C���������݃G���[���b�Z�[�W
  cv_msg_cfo_00031                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --�N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10006                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10006';   --�͈͎w��G���[���b�Z�[�W
  cv_msg_cfo_10007                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10008';   --�p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10010                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_11008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   --
  cv_msg_cfo_11105                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11105';   --�̎�c��ID
  cv_msg_cfo_11106                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11106';   --���̋@�̔��萔���Ǘ��e�[�u��
  cv_msg_cfo_11107                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11107';   --���̋@�̔��萔�����A�g�e�[�u��
  cv_msg_cfo_11108                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11108';   --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u��
  cv_msg_cfo_11109                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11109';   --GL���A�g
  cv_msg_cfo_11110                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11110';   --�������S
  cv_msg_cfo_11111                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11111';   --����敉�S
  cv_msg_cfo_11112                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11112';   --�̎�c���e�[�u��
  cv_msg_cfo_11121                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11121';   --���A�g�����i�g�ݖ߂��f�[�^�ǉ����j
  cv_msg_coi_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  --  
  --�g�[�N��
  cv_token_info                         CONSTANT VARCHAR2(10)  := 'INFO';               --�g�[�N����(INFO)
  cv_token_param_name                   CONSTANT VARCHAR2(10)  := 'PARAM_NAME';         --�g�[�N����(PARAM_NAME)
  cv_token_param_val                    CONSTANT VARCHAR2(10)  := 'PARAM_VAL';          --�g�[�N����(PARAM_VAL)
  cv_token_lookup_type                  CONSTANT VARCHAR2(15)  := 'LOOKUP_TYPE';        --�g�[�N����(LOOKUP_TYPE)
  cv_token_lookup_code                  CONSTANT VARCHAR2(15)  := 'LOOKUP_CODE';        --�g�[�N����(LOOKUP_CODE)
  cv_token_prof_name                    CONSTANT VARCHAR2(10)  := 'PROF_NAME';          --�g�[�N����(PROF_NAME)
  cv_token_dir_tok                      CONSTANT VARCHAR2(10)  := 'DIR_TOK';            --�g�[�N����(DIR_TOK)
  cv_token_file_name                    CONSTANT VARCHAR2(10)  := 'FILE_NAME';          --�g�[�N����(FILE_NAME)
  cv_token_errmsg                       CONSTANT VARCHAR2(10)  := 'ERRMSG';             --�g�[�N����(ERRMSG)
  cv_token_max_id                       CONSTANT VARCHAR2(10)  := 'MAX_ID';             --�g�[�N����(MAX_ID)
  cv_token_param1                       CONSTANT VARCHAR2(10)  := 'PARAM1';             --�g�[�N����(PARAM1)
  cv_token_param2                       CONSTANT VARCHAR2(10)  := 'PARAM2';             --�g�[�N����(PARAM2)
  cv_token_doc_data                     CONSTANT VARCHAR2(10)  := 'DOC_DATA';           --�g�[�N����(DOC_DATA)
  cv_token_doc_dist_id                  CONSTANT VARCHAR2(15)  := 'DOC_DIST_ID';        --�g�[�N����(DOC_DIST_ID)
  cv_token_get_data                     CONSTANT VARCHAR2(10)  := 'GET_DATA';           --�g�[�N����(GET_DATA)
  cv_token_table                        CONSTANT VARCHAR2(10)  := 'TABLE';              --�g�[�N����(TABLE)
  cv_token_cause                        CONSTANT VARCHAR2(10)  := 'CAUSE';              --�g�[�N����(CAUSE)
  cv_token_target                       CONSTANT VARCHAR2(10)  := 'TARGET';             --�g�[�N����(TARGET)
  cv_token_meaning                      CONSTANT VARCHAR2(10)  := 'MEANING';            --�g�[�N����(MEANING)
  cv_token_key_data                     CONSTANT VARCHAR2(10)  := 'KEY_DATA';           --�g�[�N����(KEY_DATA)
  cv_token_table_name                   CONSTANT VARCHAR2(10)  := 'TABLE_NAME';         --�g�[�N����(TABLE_NAME)
  cv_token_count                        CONSTANT VARCHAR2(10)  := 'COUNT';              --�g�[�N����(COUNT)
  cv_token_org_code                     CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';       --�g�[�N����(ORG_CODE)
  --�Q�ƃ^�C�v
  cv_lookup_book_date                   CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --�d�q���돈�����s��
  cv_lookup_item_bm                     CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_BM';    --�d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j
  --�A�v���P�[�V��������
  cv_xxcff_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFF';                --����
  cv_xxcfo_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFO';                --��v
  cv_xxcoi_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOI';                --�݌�
  --
  cn_zero                               CONSTANT NUMBER        := 0;
  --���b�Z�[�W�o�͐�
  cv_file_output                        CONSTANT VARCHAR2(30)  := 'OUTPUT';               --���b�Z�[�W�o�͐�i�t�@�C���j
  cv_file_log                           CONSTANT VARCHAR2(30)  := 'LOG';                  --���b�Z�[�W�o�͐�i���O�j
  cv_file_type_out                      CONSTANT NUMBER        := FND_FILE.OUTPUT;        --���b�Z�[�W�o�͐�
  cv_file_type_log                      CONSTANT NUMBER        := FND_FILE.LOG;           --���b�Z�[�W�o�͐�
  cv_file_mode                          CONSTANT VARCHAR2(30)  := 'w';
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format1                       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           --���t����1
  cv_date_format2                       CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';--���t����2
  cv_date_format3                       CONSTANT VARCHAR2(30)  := 'YYYYMMDD';             --���t����3
  cv_date_format4                       CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';     --���t����4
  --CSV
  cv_delimit                            CONSTANT VARCHAR2(1)   := ',';                    --�J���}
  cv_quot                               CONSTANT VARCHAR2(1)   := '"';                    --��������
  cv_comma                              CONSTANT VARCHAR2(1)   := ',';                    --�J���}
  cv_dbl_quot                           CONSTANT VARCHAR2(1)   := '"';                    --�_�u���N�I�[�e�[�V����
  cv_space                              CONSTANT VARCHAR2(1)   := ' ';                    --�X�y�[�X
  cv_cr                                 CONSTANT VARCHAR2(1)   := CHR(10);                --���s
  --�f�[�^�^�C�v
  cv_data_type_bm_balance               CONSTANT VARCHAR2(1)   := '1';                    --�̎�c���e�[�u��
  cv_data_type_coop                     CONSTANT VARCHAR2(1)   := '2';                    --���̋@�̔��萔�����A�g�e�[�u��
  --�ǉ��X�V�敪
  cv_ins_upd_0                          CONSTANT VARCHAR2(1)   := '0';                    --�ǉ�
  cv_ins_upd_1                          CONSTANT VARCHAR2(1)   := '1';                    --�X�V
  --���s���[�h
  cv_exec_fixed_period                  CONSTANT VARCHAR2(1)   := '0';                    --������s
  cv_exec_manual                        CONSTANT VARCHAR2(1)   := '1';                    --�蓮���s
  --�t���O
  cv_flag_y                             CONSTANT VARCHAR2(01)  := 'Y';                    --�t���O('Y')
  cv_flag_n                             CONSTANT VARCHAR2(01)  := 'N';                    --�t���O('N')
  cv_lang                               CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cn_max_linesize                       CONSTANT BINARY_INTEGER := 32767;
  --�C���^�[�t�F�[�X�t���O
  cv_gl_interface_status_y              CONSTANT VARCHAR2(1)   := '1';                    --�C���^�[�t�F�[�X�ς�('1')
  cv_status_y                           CONSTANT VARCHAR2(1)   := '1';                    --�C���^�[�t�F�[�X�ς�('1')
--
  -- ���ڑ���
  cv_attr_vc2                           CONSTANT VARCHAR2(1)   := '0';                    --VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                           CONSTANT VARCHAR2(1)   := '1';                    --NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                           CONSTANT VARCHAR2(1)   := '2';                    --DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                           CONSTANT VARCHAR2(1)   := '3';                    --CHAR2   �i�`�F�b�N�j
  --
  cv_slash                              CONSTANT VARCHAR2(1)   := '/';                    --�X���b�V��
  --�U���萔�����S
  cv_bank_charge_bearer_i               CONSTANT po_vendor_sites_all.bank_charge_bearer%TYPE
                                                               := 'I';                    --�������S
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̋@�̔��萔��
  TYPE g_layout_ttype                   IS TABLE OF VARCHAR2(400)             
                                        INDEX BY PLS_INTEGER;
  --
  gt_data_tab                           g_layout_ttype;              --�o�̓f�[�^���
  -- ���ڃ`�F�b�N
  TYPE g_item_name_ttype                IS TABLE OF fnd_lookup_values.attribute1%TYPE  
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype                 IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype             IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype             IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype                IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype              IS TABLE OF fnd_lookup_values.attribute6%TYPE
                                        INDEX BY PLS_INTEGER;
  --�X�V�p
  TYPE g_bm_balance_id_ttype            IS TABLE OF xxcfo_bm_balance_wait_coop.bm_balance_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_bm_balance_rowid_ttype         IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_bm_balance_id_ttype    IS TABLE OF xxcfo_bm_balance_control.bm_balance_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_rowid_ttype            IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  --���ʊ֐��`�F�b�N�p
  gt_item_name                          g_item_name_ttype;                                --���ږ���
  gt_item_len                           g_item_len_ttype;                                 --���ڂ̒���
  gt_item_decimal                       g_item_decimal_ttype;                             --���ځi�����_�ȉ��̒����j
  gt_item_nullflg                       g_item_nullflg_ttype;                             --�K�{���ڃt���O
  gt_item_attr                          g_item_attr_ttype;                                --���ڑ���
  gt_item_cutflg                        g_item_cutflg_ttype;                              --�؎̂ăt���O
  --���̋@�̔��萔�����A�g�e�[�u��
  gt_bm_balance_rowid_tbl               g_bm_balance_rowid_ttype;                         --���A�g�e�[�u��ROWID 
  gt_bm_balance_id_tbl                  g_bm_balance_id_ttype;                            --�̎�c��ID 
  --���̋@�̔��萔���Ǘ��e�[�u��
  gt_control_rowid_tbl                  g_control_rowid_ttype;                            --�Ǘ��e�[�u��ROWID 
  gt_control_header_id_tbl              g_control_bm_balance_id_ttype;                    --�Ǘ��e�[�u��ID
  --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u��
  gt_rtn_info_rowid_tbl                 g_bm_balance_rowid_ttype;                         --�g�ݖ߂��Ǘ��e�[�u��ROWID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  gv_file_path                          all_directories.directory_name%TYPE   DEFAULT NULL; --�f�B���N�g����
  gv_directory_path                     all_directories.directory_path%TYPE   DEFAULT NULL; --�f�B���N�g��
  gv_full_name                          VARCHAR2(200) DEFAULT NULL;                       --�d�q���뎩�̋@�̔��萔���f�[�^�ǉ��t�@�C��
  gv_file_name                          VARCHAR2(100) DEFAULT NULL;                       --�d�q���뎩�̋@�̔��萔���f�[�^�ǉ��t�@�C��
  gn_electric_exec_days                 NUMBER;                                           --����
-- 2012/11/28 Ver.1.1 T.Osawa Add Start
  gn_electric_exec_time                 NUMBER;                                           --����
-- 2012/11/28 Ver.1.1 T.Osawa Add End
  gd_prdate                             DATE;                                             --�Ɩ����t
  gv_coop_date                          VARCHAR2(14);                                     --�A�g���t
  --�t�@�C���o�͗p
  gv_activ_file_h                       UTL_FILE.FILE_TYPE;                               -- �t�@�C���n���h���擾�p
  --�Ώۃf�[�^
  gt_data_type                          VARCHAR2(1);                                      --�f�[�^����
  --�t�@�C��
  gv_file_data                          VARCHAR2(30000);                                  --�t�@�C���T�C�Y
  gb_fileopen                           BOOLEAN;
  --  
  gt_org_id                             mtl_parameters.organization_id%TYPE;              --�g�DID
  --�p�����[�^
  gv_ins_upd_kbn                        VARCHAR2(1);                                      --�ǉ��X�V�敪
  gv_exec_kbn                           VARCHAR2(1);                                      --�������s���[�h
  gt_id_from                            xxcok_backmargin_balance.bm_balance_id%TYPE;      --�̎�c��ID(From)
  gt_id_to                              xxcok_backmargin_balance.bm_balance_id%TYPE;      --�̎�c��ID(To)
  gt_date_from                          xxcfo_bm_balance_control.business_date%TYPE;      --�Ɩ����t�iTo�j
  gt_date_to                            xxcfo_bm_balance_control.business_date%TYPE;      --�Ɩ����t�iTo�j
  gt_row_id_to                          UROWID;                                           --�Ǘ��e�[�u���X�VROWID
  gb_get_bm_balance                     BOOLEAN;
  --
  gb_coop_out                           BOOLEAN := FALSE;                                 --���A�g�e�[�u���o�͑Ώ�
  gn_target_coop_cnt                    NUMBER;                                           --���A�g�e�[�u���Ώی���
  gn_out_coop_cnt                       NUMBER;                                           --���A�g�e�[�u���o�͌���
  gn_out_rtn_coop_cnt                   NUMBER;                                           --���A�g�e�[�u���o�͌����i�g�ݖ߂��j
  --
  gd_business_date                      DATE;                                             --�Ɩ����t
  gb_status_warn                        BOOLEAN := FALSE;                                 --�x������
  --���ږ�
  gv_bank_charge_bearer_toho            fnd_new_messages.message_text%TYPE;               --�������S
  gv_bank_charge_bearer_aite            fnd_new_messages.message_text%TYPE;               --����敉�S
  gv_bm_balance_id_name                 fnd_new_messages.message_text%TYPE;               --�̎�c��ID
  gv_bm_balance_coop_wait               fnd_new_messages.message_text%TYPE;               --���̋@�̔��萔�����A�g�e�[�u��
  gv_bm_balance_control                 fnd_new_messages.message_text%TYPE;               --���̋@�̔��萔���Ǘ��e�[�u��
  gv_bm_balance_rtn_info                fnd_new_messages.message_text%TYPE;               --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u��
  gv_gl_coop                            fnd_new_messages.message_text%TYPE;               --GL���A�g
  gv_backmargin_balance                 fnd_new_messages.message_text%TYPE;               --�̎�c���e�[�u��
  --����
  gn_item_cnt                           NUMBER;                                           --�`�F�b�N���ڌ���
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̎�c��ID(From)
    iv_id_to            IN  VARCHAR2,             --�̎�c��ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --����蓮�敪
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lb_retcode                BOOLEAN;
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists                 BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length            NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size             BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg                    VARCHAR2(3000);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j�p�J�[�\��
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             AS  item_name                           --���ږ���
              , flv.attribute1          AS  item_len                            --���ڂ̒���
              , NVL(flv.attribute2, cn_zero)
                                        AS  item_decimal                        --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          AS  item_nullflag                       --�K�{�t���O
              , flv.attribute4          AS  item_attr                           --����
              , flv.attribute5          AS  item_cutflag                        --�؎̂ăt���O
      FROM      fnd_lookup_values       flv                                     --�N�C�b�N�R�[�h
      WHERE     flv.lookup_type         =         cv_lookup_item_bm             --�d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j
      AND       gd_prdate               BETWEEN   NVL(flv.start_date_active, gd_prdate)
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang
      ORDER BY  flv.lookup_type 
              , flv.lookup_code;
--
  BEGIN
--
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
    -- 1.1  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_output            -- ���b�Z�[�W�o��
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- �ǉ��X�V�敪
      , iv_conc_param2                  =>  iv_file_name              -- �t�@�C����
      , iv_conc_param3                  =>  iv_id_from                -- �̎�c��ID�iFrom�j
      , iv_conc_param4                  =>  iv_id_to                  -- �̎�c��ID�iTo�j
      , iv_conc_param5                  =>  iv_exec_kbn               -- ����蓮�敪
      , ov_errbuf                       =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN 
      RAISE global_api_expt; 
    END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_log               -- ���O�o��
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- �ǉ��X�V�敪
      , iv_conc_param2                  =>  iv_file_name              -- �t�@�C����
      , iv_conc_param3                  =>  iv_id_from                -- �̎�c��ID�iFrom�j
      , iv_conc_param4                  =>  iv_id_to                  -- �̎�c��ID�iTo�j
      , iv_conc_param5                  =>  iv_exec_kbn               -- ����蓮�敪
      , ov_errbuf                       =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     --
    IF ( lv_retcode <> cv_status_normal ) THEN 
      RAISE global_api_expt; 
    END IF; 
    --
    gv_ins_upd_kbn  :=    iv_ins_upd_kbn;
    gv_exec_kbn     :=    iv_exec_kbn;
--
    --==============================================================
    -- 1.2  ���ږ��̎擾
    --==============================================================
    --�X�V�敪
    gv_ins_upd_kbn  :=  iv_ins_upd_kbn;
    --�̎�c��ID
    gv_bm_balance_id_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11105
                  );
    --���̋@�̔��萔���Ǘ��e�[�u��
    gv_bm_balance_control :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11106
                  );
    --���̋@�̔��萔�����A�g�e�[�u��
    gv_bm_balance_coop_wait :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11107
                  );
    --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u��
    gv_bm_balance_rtn_info :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11108
                  );
    --GL���A�g
    gv_gl_coop :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11109
                  );
    --�������S
    gv_bank_charge_bearer_toho :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11110
                  );
    --����敉�S
    gv_bank_charge_bearer_aite :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11111
                  );
    --�̎�c���e�[�u��
    gv_backmargin_balance :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11112
                  );
    --==============================================================
    -- 1.3  �̎�c��ID�t�]�`�F�b�N�i����蓮�敪�j
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      IF ( TO_NUMBER(iv_id_from) > TO_NUMBER(iv_id_to)) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10008
                      , iv_token_name1  => cv_token_param1
                      , iv_token_name2  => cv_token_param2
                      , iv_token_value1 => gv_bm_balance_id_name || '(From)'
                      , iv_token_value2 => gv_bm_balance_id_name || '(To)'
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 1.4  �Ɩ��������t�擾
    --==============================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_prdate IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00015
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
--
    --==============================================================
    -- 1.5  �A�g�����p���t�擾
    --==============================================================
    gv_coop_date  :=  TO_CHAR(SYSDATE, cv_date_format4);
--
    --
    --==============================================================
    -- 1.6  �N�C�b�N�R�[�h�擾
    --==============================================================
    -- �d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j�p�J�[�\���I�[�v��
    OPEN get_chk_item_cur;
    -- �d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j�p�z��ɑޔ�
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name                                  --���ږ�
            , gt_item_len                                   --���ڂ̒���
            , gt_item_decimal                               --���ڂ̒����i�����_�ȉ��j
            , gt_item_nullflg                               --�K�{�t���O
            , gt_item_attr                                  --���ڑ���
            , gt_item_cutflg;                               --�؎̃t���O
    -- �Ώی����̃Z�b�g
    gn_item_cnt   := gt_item_name.COUNT;
    -- �d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j�p�J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
    -- �d�q���덀�ڃ`�F�b�N�i���̋@�̔��萔���j�̃��R�[�h���擾�ł��Ȃ������ꍇ�A�G���[�I��
    IF ( gn_item_cnt = 0 )   THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00031
                    , iv_token_name1    =>  cv_token_lookup_type
                    , iv_token_name2    =>  cv_token_lookup_code
                    , iv_token_value1   =>  cv_lookup_item_bm
                    , iv_token_value2   =>  NULL
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END IF;
    --
    --==============================================================
    -- 1.7  �N�C�b�N�R�[�h�擾
    --==============================================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)         AS      electric_exec_date_cnt          --�d�q���돈�����s����
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
              , TO_NUMBER(flv.attribute2)         AS      electric_exec_time              --����
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      INTO      gn_electric_exec_days
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
              , gn_electric_exec_time                                                     
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      FROM      fnd_lookup_values       flv                                               --�N�C�b�N�R�[�h
      WHERE     flv.lookup_type         =         cv_lookup_book_date                     --�d�q���돈�����s����
      AND       flv.lookup_code         =         cv_pkg_name                             --�d�q���뎩�̋@�̔��萔��
      AND       gd_prdate               BETWEEN   NVL(flv.start_date_active, gd_prdate)
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    => cv_xxcfo_appl_name
                    , iv_name           => cv_msg_cfo_00031
                    , iv_token_name1    => cv_token_lookup_type
                    , iv_token_name2    => cv_token_lookup_code
                    , iv_token_value1   => cv_lookup_book_date
                    , iv_token_value2   => cv_pkg_name
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.8  �v���t�@�C���擾
    --==============================================================
    --�d�q����f�[�^�i�[�t�@�C���p�X
    gv_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gv_file_path IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_data_filepath
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.9  �v���t�@�C���擾
    --==============================================================
    -- �c�ƒP�ʂ̎擾
    gt_org_id   :=  TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    --
    IF ( gt_org_id IS NULL ) THEN
       lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_org_id
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    ELSE
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        --�ǉ��t�@�C�������v���t�@�C������擾
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_xxcfo_appl_name
                        , iv_name           =>  cv_msg_cfo_00001
                        , iv_token_name1    =>  cv_token_prof_name
                        , iv_token_value1   =>  cv_add_filename
                        );
          --
          lv_errmsg :=  lv_errbuf ;
          RAISE global_process_expt;
        END IF;
      ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        --�X�V�t�@�C�������v���t�@�C������擾
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_xxcfo_appl_name
                        , iv_name         =>  cv_msg_cfo_00001
                        , iv_token_name1  =>  cv_token_prof_name
                        , iv_token_value1 =>  cv_upd_filename
                        );
          --
          lv_errmsg :=  lv_errbuf ;
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;    
    --
    --==============================================================
    -- 1.10 �f�B���N�g���p�X�擾
    --==============================================================
    BEGIN
      SELECT    ad.directory_path       AS  directory_path                      --�f�B���N�g���p�X
      INTO      gv_directory_path
      FROM      all_directories         ad                                      --�f�B���N�g���e�[�u��
      WHERE     ad.directory_name       =         gv_file_path
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcoi_appl_name
                    , iv_name           =>  cv_msg_coi_00029
                    , iv_token_name1    =>  cv_token_dir_tok
                    , iv_token_value1   =>  gv_file_path
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.11 �t�@�C�����o��
    --==============================================================
    --�t�@�C�����ҏW���A�f�B���N�g���̍Ō�ɃX���b�V�������Ă��邩�����ăt�@�C������ҏW
    IF ( SUBSTRB(gv_directory_path, -1, 1) = cv_slash )  THEN   
      --�I���ɃX���b�V�������Ă����ꍇ�A�X���b�V����t�����Ȃ�
      gv_full_name    :=  gv_directory_path || gv_file_name;
    ELSE
      --�I���ɃX���b�V�������Ă����ꍇ�A�X���b�V����t������
      gv_full_name    :=  gv_directory_path || cv_slash || gv_file_name;
    END IF;
    --�t�@�C���������O�ɏo��
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application          =>  cv_xxcfo_appl_name
              , iv_name                 =>  cv_msg_cfo_00002
              , iv_token_name1          =>  cv_token_file_name
              , iv_token_value1         =>  gv_full_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_out         --�o�͋敪
                  , iv_message          =>  lv_msg                   --���b�Z�[�W
                  , in_new_line         =>  0                        --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_log         --�o�͋敪
                  , iv_message          =>  lv_msg                   --���b�Z�[�W
                  , in_new_line         =>  0                        --���s
                  );
    --==============================================================
    -- 2 ����t�@�C�����݃`�F�b�N
    --==============================================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location              =>  gv_file_path
      , filename              =>  gv_file_name
      , fexists               =>  lb_exists
      , file_length           =>  ln_file_length
      , block_size            =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00027
                    );
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
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
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( get_chk_item_cur%ISOPEN )  THEN
        CLOSE   get_chk_item_cur;
      END IF;
      --
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_bm_balance_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_bm_balance_wait_coop(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bm_balance_wait_coop'; -- �v���O������
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
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    lv_record_flag                      VARCHAR2(1);
-- 2012/11/28 Ver.1.2 T.Osawa Add End
--
    -- *** ���[�J���ϐ� ***
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
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    --==============================================================
    --�蓮���s���A���A�g�e�[�u���ɑ��݂��邩�`�F�b�N���s��
    --==============================================================
    lv_record_flag  :=  cv_flag_n ;
    --
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --
      BEGIN
        SELECT    cv_flag_y
        INTO      lv_record_flag
        FROM      xxcfo_bm_balance_wait_coop                xbbwc
        WHERE     xbbwc.bm_balance_id             =         gt_data_tab(1)  
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_record_flag  :=  cv_flag_n ;
      END ;
      --
    END IF;
    --
    --==============================================================
    --������s�܂��́A�蓮���s�����A�g�e�[�u���Ƀ��R�[�h�����݂��Ȃ��ꍇ�A���A�g�e�[�u���Ƀ��R�[�h��ǉ�
    --==============================================================
    IF  ( ( gv_exec_kbn     = cv_exec_fixed_period )
    OR  ( ( gv_exec_kbn     = cv_exec_manual       )
    AND   ( lv_record_flag  = cv_flag_n            ) ) )
    THEN
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      --==============================================================
      --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
      --==============================================================
      INSERT INTO xxcfo_bm_balance_wait_coop (
          bm_balance_id                       --�̎�c��ID
        , created_by                          --�쐬��
        , creation_date                       --�쐬��
        , last_updated_by                     --�ŏI�X�V��
        , last_update_date                    --�ŏI�X�V��
        , last_update_login                   --�ŏI�X�V���O�C��
        , request_id                          --�v��ID
        , program_application_id              --�v���O�����A�v���P�[�V����ID
        , program_id                          --�v���O����ID
        , program_update_date                 --�v���O�����X�V��
      ) VALUES ( 
          gt_data_tab(1)                      --�̎�c��ID
        , cn_created_by                       --�쐬��
        , cd_creation_date                    --�쐬��
        , cn_last_updated_by                  --�ŏI�X�V��
        , cd_last_update_date                 --�ŏI�X�V��
        , cn_last_update_login                --�ŏI�X�V���O�C��
        , cn_request_id                       --�v��ID
        , cn_program_application_id           --�v���O�����A�v���P�[�V����ID
        , cn_program_id                       --�v���O����ID
        , cd_program_update_date              --�v���O�����X�V��
      );
      --���A�g�o�͌������J�E���g�A�b�v
      gn_out_coop_cnt   :=  gn_out_coop_cnt   +   1;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    END IF;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
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
  END ins_bm_balance_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_control(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̎�c��ID(From)
    iv_id_to            IN  VARCHAR2,             --�̎�c��ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --�̎�c��ID(To)
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_control'; -- �v���O������
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
    ln_idx          NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�̔��萔���Ǘ��e�[�u���擾�P�iFrom�擾�p�j
    CURSOR bm_balance_control1_cur
    IS                                                                          
      SELECT    xbbc.bm_balance_id                AS  bm_balance_id             --�̎�c��ID
              , xbbc.business_date                AS  business_date             --�Ɩ����t
      FROM      xxcfo_bm_balance_control          xbbc                          --���̋@�̔��萔���Ǘ��e�[�u��
      WHERE     xbbc.process_flag                 =         cv_flag_y
      ORDER BY  xbbc.business_date                DESC
              , xbbc.creation_date                DESC
      ;
    --
    -- �e�[�u���^
    TYPE bm_balance_control1_ttype      IS TABLE OF bm_balance_control1_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_control1_tab             bm_balance_control1_ttype;
    --
    -- ���̋@�̔��萔���Ǘ��e�[�u���擾�Q�iTo�擾�p�j
    CURSOR bm_balance_control2_cur
    IS
      SELECT    xbbc.rowid                        AS  row_id                    --ROWID
              , xbbc.bm_balance_id                AS  bm_balance_id             --�̎�c��ID
              , xbbc.business_date                AS  business_date             --�Ɩ����t
      FROM      xxcfo_bm_balance_control          xbbc                          --���̋@�̔��萔���Ǘ��e�[�u��
      WHERE     xbbc.process_flag                 =         cv_flag_n
      ORDER BY  xbbc.business_date                DESC
              , xbbc.creation_date                DESC
      ;
    -- ���̋@�̔��萔���Ǘ��e�[�u���擾3(���b�N�擾�p)
    CURSOR bm_balance_control3_cur
    IS
      SELECT    xbbc.rowid                        AS  row_id                    --ROWID
      FROM      xxcfo_bm_balance_control          xbbc                          --���̋@�̔��萔���Ǘ��e�[�u��
      WHERE     xbbc.rowid                        =         gt_row_id_to        --���̋@�̔��萔���Ǘ��e�[�u���擾�Q�iTo�擾�p�j��ROWID
      FOR UPDATE NOWAIT
      ;
    -- �e�[�u���^
    TYPE bm_balance_control_ttype       IS TABLE OF bm_balance_control2_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_control_tab              bm_balance_control_ttype;
    --
    -- ���̋@�̔��萔�����A�g�e�[�u���`�F�b�N
    CURSOR bm_balance_wait_coop_cur
    IS
      SELECT    xbbwc.rowid                       AS  row_id                    --ROWID
              , xbbwc.bm_balance_id               AS  bm_balance_id             --�̎�c��ID
      FROM      xxcfo_bm_balance_wait_coop        xbbwc                         --���̋@�̔��萔���Ǘ��e�[�u��
      WHERE     xbbwc.bm_balance_id               >=        gt_id_from
      AND       xbbwc.bm_balance_id               <=        gt_id_to
    ;
    --
    -- �e�[�u���^
    TYPE bm_balance_wait_coop_ttype     IS TABLE OF bm_balance_wait_coop_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_wait_coop_tab            bm_balance_wait_coop_ttype;
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
    -- 1.1  ���̋@�̔��萔���Ǘ��e�[�u���̃f�[�^�擾
    --==============================================================
    --���̋@�̔��萔���Ǘ��e�[�u���擾�P�iFrom�擾�p�j�I�[�v��
    OPEN    bm_balance_control1_cur;
    --���̋@�̔��萔���Ǘ��e�[�u���擾�P�iFrom�擾�p�j�f�[�^�擾
    FETCH   bm_balance_control1_cur     BULK COLLECT INTO bm_balance_control1_tab;
    --���̋@�̔��萔���Ǘ��e�[�u���擾�P�iFrom�擾�p�j�N���[�Y
    CLOSE   bm_balance_control1_cur;
    --
    --���̋@�̔��萔���Ǘ��e�[�u���擾�P�iFrom�擾�p�j���R�[�h���擾�ł��Ȃ��ꍇ�A�G���[
    IF ( bm_balance_control1_tab.COUNT = 0 ) THEN    
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00165
                    , iv_token_name1  => cv_token_get_data
                    , iv_token_value1 => gv_bm_balance_control
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE   global_process_expt;
    ELSE
      --1���ڂ̃��R�[�h���擾
      gt_id_from        :=  bm_balance_control1_tab(1).bm_balance_id;
      gt_date_from      :=  bm_balance_control1_tab(1).business_date;
    END IF;
    --
    --==============================================================
    -- 1.2  ���̋@�̔��萔���Ǘ��e�[�u���̃f�[�^�擾(������s�̏ꍇ)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --���̋@�̔��萔���Ǘ��e�[�u���擾�Q�iTo�擾�p�j�I�[�v��
      OPEN  bm_balance_control2_cur;
      --���̋@�̔��萔���Ǘ��e�[�u���擾�Q�iTo�擾�p�j�f�[�^�擾
      FETCH bm_balance_control2_cur BULK COLLECT INTO bm_balance_control_tab;
      --���̋@�̔��萔���Ǘ��e�[�u���擾�Q�iTo�擾�p�j�N���[�Y
      CLOSE bm_balance_control2_cur;
      --
      --���o�������d�q���돈�����s������菬�����ꍇ�A�̎�c��ID(To)��NULL��ݒ�
      IF  ( bm_balance_control_tab.COUNT < gn_electric_exec_days ) THEN
        gt_id_to        :=  NULL;
        --
      ELSE
        --�擾�����z��́A�d�q���돈�����s�����ɊY������̎�c��ID��̎�c��ID(To)�Ƃ��đޔ�
        gt_row_id_to  :=  bm_balance_control_tab( gn_electric_exec_days ).row_id;
        gt_id_to      :=  bm_balance_control_tab( gn_electric_exec_days ).bm_balance_id;
        gt_date_to    :=  bm_balance_control_tab( gn_electric_exec_days ).business_date;
      END IF;
      --==============================================================
      -- 1.3  �擾�����̎�c��ID(To)�̃��R�[�h�����b�N
      --==============================================================
      IF ( gt_id_to IS NOT NULL ) THEN
        --�̎�c��ID(To)���擾�ł����ꍇ�A���b�N���擾����
        OPEN  bm_balance_control3_cur;
        CLOSE bm_balance_control3_cur;
      END IF;
    --
    END IF;
    --
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --==============================================================
      -- 1.4.1  ���M�ς݃f�[�^�`�F�b�N
      --==============================================================
      gb_get_bm_balance :=  TRUE;
      --
      --�p�����[�^�Ŏw�肳�ꂽ�͈͂̃f�[�^�����M�ς݂ł��邩�`�F�b�N���܂��B
      IF ( TO_NUMBER(iv_id_to) > gt_id_from ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10006
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
      --
      --�p�����^���O���[�o���ϐ��ɑޔ�
      gt_id_from        :=  TO_NUMBER(iv_id_from);
      gt_id_to          :=  TO_NUMBER(iv_id_to);
      --==============================================================
      -- 1.4.2  ���A�g�`�F�b�N
      --==============================================================
      OPEN bm_balance_wait_coop_cur;
      FETCH bm_balance_wait_coop_cur BULK COLLECT INTO bm_balance_wait_coop_tab LIMIT 1;
      CLOSE bm_balance_wait_coop_cur;
      --
      IF ( bm_balance_wait_coop_tab.COUNT > 0 ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10010
                      , iv_token_name1  => cv_token_doc_data
                      , iv_token_name2  => cv_token_doc_dist_id
                      , iv_token_value1 => gv_bm_balance_id_name
                      , iv_token_value2 => bm_balance_wait_coop_tab(1).bm_balance_id
                      );
        --
        lv_errmsg   :=    lv_errbuf;
        --
        RAISE global_process_expt;
        --
      END IF;
      --
    END IF;
    --
    --==============================================================
    -- 2 �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_file_path        -- �f�B���N�g���p�X
                          , filename     => gv_file_name        -- �t�@�C����
                          , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                         );
      --
      gb_fileopen   :=  TRUE;
      --
    EXCEPTION    --
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00029
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        ov_errmsg :=  lv_errbuf;
        RAISE global_api_others_expt;    
    END;
    --
--
  EXCEPTION
    -- *** ���b�N�̎擾�G���[ ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_control
                    );
      ov_errmsg  := lv_errbuf;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( bm_balance_control1_cur%ISOPEN )  THEN
        CLOSE   bm_balance_control1_cur;
      END IF;
      IF ( bm_balance_control2_cur%ISOPEN )  THEN
        CLOSE   bm_balance_control2_cur;
      END IF;
      --
  END get_bm_balance_control;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_rtn_info
   * Description      : �g�ݖ߂��Ǘ��f�[�^���A�g�e�[�u���ǉ�(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_rtn_info (
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_rtn_info'; -- �v���O������
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
    lt_bm_balance_id                    xxcfo_bm_balance_wait_coop.bm_balance_id%TYPE;
    ln_upd_idx                          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u���擾�p�J�[�\��
    CURSOR  bm_balance_rtn_info_cur  
    IS
      SELECT    xbbri.bm_balance_id               AS        bm_balance_id       --�̎�c��ID
      FROM      xxcok_bm_balance_rtn_info         xbbri                         
      WHERE     xbbri.bm_balance_id               <=        gt_id_from
      AND       xbbri.eb_status                   IS        NULL
      GROUP BY  xbbri.bm_balance_id
      ORDER BY  xbbri.bm_balance_id
      ;
    --
    bm_balance_rtn_info_rec             bm_balance_rtn_info_cur%ROWTYPE;
    --
    --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u�����b�N�p�J�[�\��
    CURSOR  bm_balance_rtn_info_lock_cur  
    IS
      SELECT    xbbri.ROWID                       AS        row_id              --ROWID
      FROM      xxcok_bm_balance_rtn_info         xbbri                         
      WHERE     xbbri.eb_status                   IS        NULL
      ORDER BY  xbbri.bm_balance_id
      FOR UPDATE NOWAIT
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --������s�̏ꍇ
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period )  THEN
      --==============================================================
      -- 1.1  ���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u���̃f�[�^�擾
      --==============================================================
      FOR bm_balance_rtn_info_rec IN bm_balance_rtn_info_cur LOOP
        --���̋@�̔��萔�����A�g�e�[�u���ɔ̎�c��ID�����݂��Ȃ��ꍇ�A���R�[�h��ǉ�����B
        BEGIN
          SELECT    xbbwc.bm_balance_id
          INTO      lt_bm_balance_id
          FROM      xxcfo_bm_balance_wait_coop    xbbwc
          WHERE     xbbwc.bm_balance_id           =         bm_balance_rtn_info_rec.bm_balance_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --���̋@�̔��萔�����A�g�e�[�u���Ƀ��R�[�h�����݂��Ȃ��ꍇ�A�̎�c��ID��ǉ�
            gt_data_tab(1)    :=    bm_balance_rtn_info_rec.bm_balance_id;
            --
            ins_bm_balance_wait_coop (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
        END;
      END LOOP;
      --
      gn_out_rtn_coop_cnt   :=  gn_out_coop_cnt ;
      gn_out_coop_cnt       :=  0 ;
      --
      --==============================================================
      -- 1.2  ���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u���̍X�V
      --==============================================================
      OPEN bm_balance_rtn_info_lock_cur;
      FETCH bm_balance_rtn_info_lock_cur BULK COLLECT INTO gt_rtn_info_rowid_tbl;
      CLOSE bm_balance_rtn_info_lock_cur;
      --�X�V
      FORALL ln_upd_idx IN 1..gt_rtn_info_rowid_tbl.COUNT  
        UPDATE    xxcok_bm_balance_rtn_info         xbbri
        SET       xbbri.eb_status                   =     cv_status_y
                , xbbri.last_updated_by             =     cn_last_updated_by                --�ŏI�X�V��
                , xbbri.last_update_date            =     cd_last_update_date               --�ŏI�X�V��
                , xbbri.last_update_login           =     cn_last_update_login              --�ŏI�X�V���O�C��
                , xbbri.request_id                  =     cn_request_id                     --�v��ID
                , xbbri.program_application_id      =     cn_program_application_id         --�v���O�����A�v���P�[�V����ID
                , xbbri.program_id                  =     cn_program_id                     --�v���O����ID
                , xbbri.program_update_date         =     cd_program_update_date            --�v���O�����X�V��
        WHERE     xbbri.ROWID                       =     gt_rtn_info_rowid_tbl(ln_upd_idx)
        ;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�̎擾�G���[ ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_rtn_info
                    );
      ov_errmsg  := lv_errbuf;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( bm_balance_rtn_info_lock_cur%ISOPEN ) THEN
        CLOSE   bm_balance_rtn_info_lock_cur;
      END IF;
      --
  END get_bm_rtn_info;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_wait
   * Description      : ���A�g�f�[�^�擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_wait(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̎�c��ID(From)
    iv_id_to            IN  VARCHAR2,             --�̎�c��ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --����蓮�敪
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_wait'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    --���̋@�̔��萔�����A�g�e�[�u���擾�p�J�[�\���i������s�p�j���b�N�擾�t��
    CURSOR  bm_balance_wait_coop_cur  
    IS
      SELECT    xbbwc.rowid                       AS  row_id                    --ROWID
              , xbbwc.bm_balance_id               AS  bm_balance_id             --�̎�c���w�b�_ID
      FROM      xxcfo_bm_balance_wait_coop        xbbwc
      ORDER BY  xbbwc.bm_balance_id
      FOR UPDATE NOWAIT
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --������s�̏ꍇ
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period )  THEN
      --���̋@�̔��萔�����A�g�e�[�u���J�[�\���I�[�v��
      OPEN  bm_balance_wait_coop_cur;
      --���̋@�̔��萔�����A�g�e�[�u���f�[�^�擾
      FETCH bm_balance_wait_coop_cur BULK COLLECT INTO 
          gt_bm_balance_rowid_tbl
        , gt_bm_balance_id_tbl;
      --���̋@�̔��萔�����A�g�e�[�u���J�[�\���N���[�Y
      CLOSE bm_balance_wait_coop_cur;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�̎擾�G���[ ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_coop_wait
                    );
      ov_errmsg  := lv_errbuf;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( bm_balance_wait_coop_cur%ISOPEN ) THEN
        CLOSE   bm_balance_wait_coop_cur;
      END IF;
      --
  END get_bm_balance_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_rtn_info
   * Description      : �g�ݖ߂����擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_rtn_info(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_rtn_info'; -- �v���O������
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
    ln_rtn_info_cnt           NUMBER    :=  0;
--
    -- *** �J�[�\�� ***
    CURSOR bm_balance_rtn_info_cur 
    IS
      SELECT    TO_CHAR(xbbri.expect_payment_amt_tax)      
                                                  AS  expect_payment_amt_tax    --�x���\��z�i�ō��j
              , TO_CHAR(xbbri.payment_amt_tax)    AS  payment_amt_tax           --�x���z�i�ō��j
              , TO_CHAR(xbbri.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date       --�c�������
              , xbbri.return_flag                 AS  return_flag               --�g�ݖ߂��t���O
              , TO_CHAR(xbbri.publication_date, cv_date_format1)
                                                  AS  publication_date          --�ē������s��
              , xbbri.org_slip_number             AS  org_slip_number           --���`�[�ԍ�
      FROM      xxcok_bm_balance_rtn_info         xbbri                         --���̋@�̔��萔���g�ݖ߂��Ǘ��e�[�u��
      WHERE     xbbri.bm_balance_id               =         gt_data_tab(1)
      ORDER BY  xbbri.publication_date            DESC                          --�ē������s��
      ;
    --
    bm_balance_rtn_info_rec             bm_balance_rtn_info_cur%ROWTYPE;
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
    -- 1  �g�ݖ߂����擾
    --==============================================================
    <<bm_balance_rtn_info_loop>>
    FOR bm_balance_rtn_info_rec IN bm_balance_rtn_info_cur LOOP
      --
      ln_rtn_info_cnt   :=  ln_rtn_info_cnt   +   1;
      --
      gt_data_tab(21)   :=  bm_balance_rtn_info_rec.expect_payment_amt_tax;
      gt_data_tab(22)   :=  bm_balance_rtn_info_rec.payment_amt_tax;
      gt_data_tab(23)   :=  bm_balance_rtn_info_rec.balance_cancel_date;
      gt_data_tab(25)   :=  bm_balance_rtn_info_rec.return_flag;
      gt_data_tab(26)   :=  bm_balance_rtn_info_rec.publication_date;
      gt_data_tab(27)   :=  bm_balance_rtn_info_rec.org_slip_number;
      --
      EXIT bm_balance_rtn_info_loop;
      --
    END LOOP bm_balance_rtn_info_loop;
    --
    IF ( ln_rtn_info_cnt = 0 ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00101
                    , iv_token_name1  => cv_token_table_name
                    , iv_token_name2  => cv_token_info
                    , iv_token_value1 => gv_bm_balance_rtn_info
                    , iv_token_value2 => gv_bm_balance_id_name || cv_msg_part ||gt_data_tab(1)
                    );
      --
      lv_errmsg  := lv_errbuf;
      --
      gb_status_warn        :=  TRUE;           --�x���I����
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_log
        ,buff   => lv_errbuf
        );
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_out
        ,buff   => lv_errbuf
        );
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
  END get_bm_balance_rtn_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
    it_gl_interface_status    IN  xxcok_backmargin_balance.gl_interface_status%TYPE,          --GL�C���^�[�t�F�[�X�X�e�[�^�X  
    ov_errbuf                 OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode                OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    lv_err_flag               VARCHAR2(1);
    ln_coop_cnt               NUMBER;
    ln_coop_start             NUMBER;
    lv_item_value             VARCHAR2(200);
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    interface_data_skip_expt  EXCEPTION;
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
    -- 1 �A�g�X�e�[�^�X�iGL�j�̃`�F�b�N
    --==============================================================
    IF ( NVL(it_gl_interface_status, cn_zero) <> cv_gl_interface_status_y )  THEN
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      IF  ( gv_exec_kbn     = cv_exec_manual ) 
      AND ( gv_ins_upd_kbn  = cv_ins_upd_0 ) 
      THEN
        ins_bm_balance_wait_coop (
            ov_errbuf                   =>        lv_errbuf           --�G���[�E���b�Z�[�W                  --# �Œ� #
          , ov_retcode                  =>        lv_retcode          --���^�[���E�R�[�h                    --# �Œ� #
          , ov_errmsg                   =>        lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
          ) ;
        --
      END IF;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_10007
                    , iv_token_name1  => cv_token_cause 
                    , iv_token_name2  => cv_token_target
                    , iv_token_name3  => cv_token_meaning
                    , iv_token_value1 => gv_gl_coop
                    , iv_token_value2 => gv_bm_balance_id_name || cv_msg_part || gt_data_tab(1)
                    , iv_token_value3 => it_gl_interface_status
                    );
      --
      lv_errmsg   :=  lv_errbuf;
      --
      RAISE interface_data_skip_expt;
    END IF;
    --==============================================================
    -- ���ڌ��`�F�b�N
    --==============================================================
    <<item_check_loop>>
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      --���ڌ��`�F�b�N�֐��ďo
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --���ږ���
        , iv_item_value                 =>        gt_data_tab(ln_cnt)               --�ύX�O�̒l
        , in_item_len                   =>        gt_item_len(ln_cnt)               --���ڂ̒���
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --�K�{�t���O
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --���ڑ���
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --�؎̂ăt���O
        , ov_item_value                 =>        gt_data_tab(ln_cnt)               --���ڂ̒l
        , ov_errbuf                     =>        lv_errbuf                         --�G���[���b�Z�[�W
        , ov_retcode                    =>        lv_retcode                        --���^�[���R�[�h
        , ov_errmsg                     =>        lv_errmsg                         --���[�U�[�E�G���[���b�Z�[�W
        );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        IF ( lv_errbuf                  =     cv_msg_cfo_10011 )    THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10011
                        , iv_token_name1  => cv_token_key_data
                        , iv_token_value1 => gt_item_name(1) || cv_msg_part || gt_data_tab(1) 
                        );
          gb_coop_out   :=  FALSE;
        ELSE
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause   
                        , iv_token_name2  => cv_token_target  
                        , iv_token_name3  => cv_token_meaning 
                        , iv_token_value1 => cv_msg_cfo_11008
                        , iv_token_value2 => gt_item_name(1) || cv_msg_part || gt_data_tab(1)
                        , iv_token_value3 => lv_errmsg
                        );
        END IF;
        --
        lv_errmsg   :=  lv_errbuf;
        --�蓮���s�̏ꍇ�A�������I��������
        IF ( gv_exec_kbn = cv_exec_manual ) THEN
          RAISE   global_process_expt;
        ELSE 
          --�蓮���s�ȊO�͏����X�L�b�v
          RAISE   interface_data_skip_expt;
        END IF;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE  global_api_others_expt;
      END IF;
      --
    END LOOP item_check_loop;
--  
  EXCEPTION
--  --�f�[�^�X�L�b�v
    WHEN interface_data_skip_expt THEN
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errbuf --�G���[���b�Z�[�W
      );
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errbuf --�G���[���b�Z�[�W
      );
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    lv_delimit                VARCHAR2(1);
    ln_line_cnt               NUMBER;
    ln_item_cnt               NUMBER;
--
    -- *** ���[�J���ϐ� ***
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
    -- ���ڂ̃��[�v
    --==============================================================
    --�f�[�^�ҏW�G���A������
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    --�f�[�^�A�����[�v
    <<bm_balance_item_loop>>
    FOR ln_item_cnt  IN 1..gt_item_name.COUNT LOOP
      --�������Ƃɏ������s��
      IF ( gt_item_attr(ln_item_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
        --VARCHAR2,CHAR2
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || 
                            REPLACE(
                              REPLACE(
                                REPLACE(gt_data_tab(ln_item_cnt), cv_cr, cv_space)
                                  , cv_dbl_quot, cv_space)
                                    , cv_comma, cv_space) || cv_quot;
      ELSIF ( gt_item_attr(ln_item_cnt) = cv_attr_num ) THEN
        --NUMBER
        gv_file_data  :=  gv_file_data || lv_delimit  || gt_data_tab(ln_item_cnt);
      ELSIF ( gt_item_attr(ln_item_cnt) = cv_attr_dat ) THEN
        --DATE
        gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_data_tab(ln_item_cnt), cv_date_format1), cv_date_format3);
      END IF;
      --�f���~�^�ɃJ���}���Z�b�g
      lv_delimit  :=  cv_delimit;               
      --
    END LOOP bm_balance_item_loop;
    --�A�g����������
    gv_file_data  :=  gv_file_data || lv_delimit  || gv_coop_date;
    --
    --==============================================================
    -- �t�@�C���o��
    --==============================================================
    BEGIN
      UTL_FILE.PUT_LINE(gv_activ_file_h
                       ,gv_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00030
                      );
        --
        ov_errmsg :=  lv_errbuf;
        RAISE  global_api_others_expt;
    END;
    --�b�r�u�o�͌����J�E���g�A�b�v
    gn_normal_cnt   :=  gn_normal_cnt   +   1;
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
   * Procedure Name   : get_bm_balance
   * Description      : �Ώۃf�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm_balance (
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance'; -- �v���O������
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
    lv_errlevel               VARCHAR2(10);
    lv_data_type              VARCHAR2(1);        -- �f�[�^�^�C�v
    lt_gl_interface_status    xxcok_backmargin_balance.gl_interface_status%TYPE;          --�A�g�X�e�[�^�X�iGL�j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�̔��萔���i������s�j
    CURSOR get_bm_balance_fixed_cur
    IS
--2012/12/18 Ver.1.2 Mod Start
--      SELECT    cv_data_type_bm_balance           AS  data_type                           --�f�[�^�^�C�v
      SELECT  /*+ LEADING(xbb) 
                  USE_NL(hca1 hp1 xca hca2 hp2 pva)
               */
                cv_data_type_bm_balance           AS  data_type                           --�f�[�^�^�C�v
--2012/12/18 Ver.1.2 Mod End
              , xbb.bm_balance_id                 AS  bm_balance_id                       --�̎�c��ID
              , xbb.base_code                     AS  base_code                           --���_�R�[�h
              , hp2.party_name                    AS  base_name                           --���_��
              , xbb.supplier_code                 AS  supplier_code                       --�d����R�[�h
              , pva.vendor_name                   AS  vendor_name                         --�d���於��
              , xbb.supplier_site_code            AS  supplier_site_code                  --�d����T�C�g�R�[�h
              , pva.attribute4                    AS  bm_payment_type                     --BM�x���敪
              , pva.attribute5                    AS  request_charge_base                 --�⍇���S�����_�R�[�h
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --�U���萔�����S
              , xbb.cust_code                     AS  cust_code                           --�ڋq�R�[�h
              , hp1.party_name                    AS  cust_name                           --�ڋq��
              , xca.business_low_type             AS  business_low_type                   --�Ƒԁi�����ށj
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --���ߓ�
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --�̔����z�i�ō��j
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --�̔��萔��
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --�̔��萔���i����Ŋz�j
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --�d�C��
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --�d�C���i����Ŋz�j
              , xbb.tax_code                      AS  tax_code                            --�ŋ��R�[�h
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --�x���\���
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --�x���\��z�i�ō��j
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --�x���z�i�ō��j
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --�c�������
              , xbb.resv_flag                     AS  resv_flag                           --�ۗ��t���O
              , xbb.return_flag                   AS  return_flag                         --�g�ݖ߂��t���O
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --�ē���������
              , xbb.org_slip_number               AS  org_slip_number                     --���`�[�ԍ�
              , xbb.proc_type                     AS  proc_type                           --�����敪
              , xbb.gl_interface_status           AS  gl_interface_status                 --�A�g�X�e�[�^�X�iGL�j
      FROM      xxcok_backmargin_balance          xbb                                     --�̎�c���e�[�u��
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --�d����ID
                        , pv.vendor_name          AS  vendor_name                         --�d���於��
                        , pv.segment1             AS  segment1                            --�d����R�[�h
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --�d����T�C�g�R�[�h
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --�U���萔�����S
                        , pvsa.attribute4         AS  attribute4                          --BM�x���敪
                        , pvsa.attribute5         AS  attribute5                          --�⍇���S�����_�R�[�h
                FROM      po_vendors              pv                                      --�d����}�X�^
                        , po_vendor_sites_all     pvsa                                    --�d����T�C�g�}�X�^
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --�d����
              , hz_cust_accounts                  hca1                                    --�ڋq�}�X�^�i�ڋq�j
              , hz_parties                        hp1                                     --�p�[�e�B�}�X�^�i�ڋq�j
              , xxcmm_cust_accounts               xca                                     --�ڋq�ǉ����
              , hz_cust_accounts                  hca2                                    --�ڋq�}�X�^�i���_�j
              , hz_parties                        hp2                                     --�p�[�e�B�}�X�^�i���_�j
      --�d����}�X�^
      WHERE     xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --�ڋq�}�X�^�i�ڋq�j
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --�ڋq�}�X�^�i���_�j
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      AND       xbb.bm_balance_id                 >=        gt_id_from + 1
      AND       xbb.bm_balance_id                 <=        gt_id_to
      UNION ALL
--2012/12/18 Ver.1.2 Mod Start
--      SELECT    cv_data_type_coop                 AS  data_type                           --�f�[�^�^�C�v
      SELECT /*+ LEADING(xbbwc) 
                 USE_NL(xbb hca1 hp1 xca hca2 hp2 pva)
              */
--2012/12/18 Ver.1.2 Mod End
                cv_data_type_coop                 AS  data_type                           --�f�[�^�^�C�v
              , xbb.bm_balance_id                 AS  bm_balance_id                       --�̎�c��ID
              , xbb.base_code                     AS  base_code                           --���_�R�[�h
              , hp2.party_name                    AS  base_name                           --���_��
              , xbb.supplier_code                 AS  supplier_code                       --�d����R�[�h
              , pva.vendor_name                   AS  vendor_name                         --�d���於��
              , xbb.supplier_site_code            AS  supplier_site_code                  --�d����T�C�g�R�[�h
              , pva.attribute4                    AS  bm_payment_type                     --BM�x���敪
              , pva.attribute5                    AS  request_charge_base                 --�⍇���S�����_�R�[�h
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --�U���萔�����S
              , xbb.cust_code                     AS  cust_code                           --�ڋq�R�[�h
              , hp1.party_name                    AS  cust_name                           --�ڋq��
              , xca.business_low_type             AS  business_low_type                   --�Ƒԁi�����ށj
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --���ߓ�
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --�̔����z�i�ō��j
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --�̔��萔��
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --�̔��萔���i����Ŋz�j
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --�d�C��
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --�d�C���i����Ŋz�j
              , xbb.tax_code                      AS  tax_code                            --�ŋ��R�[�h
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --�x���\���
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --�x���\��z�i�ō��j
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --�x���z�i�ō��j
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --�c�������
              , xbb.resv_flag                     AS  resv_flag                           --�ۗ��t���O
              , xbb.return_flag                   AS  return_flag                         --�g�ݖ߂��t���O
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --�ē���������
              , xbb.org_slip_number               AS  org_slip_number                     --���`�[�ԍ�
              , xbb.proc_type                     AS  proc_type                           --�����敪
              , xbb.gl_interface_status           AS  gl_interface_status                 --�A�g�X�e�[�^�X�iGL�j
      FROM      xxcok_backmargin_balance          xbb                                     --�̎�c���e�[�u��
              , xxcfo_bm_balance_wait_coop        xbbwc                                   --���̋@�̔��萔�����A�g�e�[�u��
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --�d����ID
                        , pv.vendor_name          AS  vendor_name                         --�d���於��
                        , pv.segment1             AS  segment1                            --�d����R�[�h
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --�d����T�C�g�R�[�h
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --�U���萔�����S
                        , pvsa.attribute4         AS  attribute4                          --BM�x���敪
                        , pvsa.attribute5         AS  attribute5                          --�⍇���S�����_�R�[�h
                FROM      po_vendors              pv                                      --�d����}�X�^
                        , po_vendor_sites_all     pvsa                                    --�d����T�C�g�}�X�^
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --�d����
              , hz_cust_accounts                  hca1                                    --�ڋq�}�X�^�i�ڋq�j
              , hz_parties                        hp1                                     --�p�[�e�B�}�X�^�i�ڋq�j
              , xxcmm_cust_accounts               xca                                     --�ڋq�ǉ����
              , hz_cust_accounts                  hca2                                    --�ڋq�}�X�^�i���_�j
              , hz_parties                        hp2                                     --�p�[�e�B�}�X�^�i���_�j
      WHERE     xbb.bm_balance_id                 =         xbbwc.bm_balance_id
      --�d����}�X�^
      AND       xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --�ڋq�}�X�^�i�ڋq�j
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --�ڋq�}�X�^�i���_�j
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      ORDER BY  bm_balance_id
    ;
    -- ���̋@�̔��萔���i�蓮���s�j
    CURSOR get_bm_balance_manual_cur
    IS
      SELECT    cv_data_type_bm_balance           AS  data_type                           --�f�[�^�^�C�v
              , xbb.bm_balance_id                 AS  bm_balance_id                       --�̎�c��ID
              , xbb.base_code                     AS  base_code                           --���_�R�[�h
              , hp2.party_name                    AS  base_name                           --���_��
              , xbb.supplier_code                 AS  supplier_code                       --�d����R�[�h
              , pva.vendor_name                   AS  vendor_name                         --�d���於��
              , xbb.supplier_site_code            AS  supplier_site_code                  --�d����T�C�g�R�[�h
              , pva.attribute4                    AS  bm_payment_type                     --BM�x���敪
              , pva.attribute5                    AS  request_charge_base                 --�⍇���S�����_�R�[�h
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --�U���萔�����S
              , xbb.cust_code                     AS  cust_code                           --�ڋq�R�[�h
              , hp1.party_name                    AS  cust_name                           --�ڋq��
              , xca.business_low_type             AS  business_low_type                   --�Ƒԁi�����ށj
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --���ߓ�
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --�̔����z�i�ō��j
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --�̔��萔��
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --�̔��萔���i����Ŋz�j
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --�d�C��
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --�d�C���i����Ŋz�j
              , xbb.tax_code                      AS  tax_code                            --�ŋ��R�[�h
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --�x���\���
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --�x���\��z�i�ō��j
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --�x���z�i�ō��j
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --�c�������
              , xbb.resv_flag                     AS  resv_flag                           --�ۗ��t���O
              , xbb.return_flag                   AS  return_flag                         --�g�ݖ߂��t���O
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --�ē���������
              , xbb.org_slip_number               AS  org_slip_number                     --���`�[�ԍ�
              , xbb.proc_type                     AS  proc_type                           --�����敪
              , xbb.gl_interface_status           AS  gl_interface_status                 --�A�g�X�e�[�^�X�iGL�j
      FROM      xxcok_backmargin_balance          xbb                                     --�̎�c���e�[�u��
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --�d����ID
                        , pv.vendor_name          AS  vendor_name                         --�d���於��
                        , pv.segment1             AS  segment1                            --�d����R�[�h
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --�d����T�C�g�R�[�h
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --�U���萔�����S
                        , pvsa.attribute4         AS  attribute4                          --BM�x���敪
                        , pvsa.attribute5         AS  attribute5                          --�⍇���S�����_�R�[�h
                FROM      po_vendors              pv                                      --�d����}�X�^
                        , po_vendor_sites_all     pvsa                                    --�d����T�C�g�}�X�^
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --�d����
              , hz_cust_accounts                  hca1                                    --�ڋq�}�X�^�i�ڋq�j
              , hz_parties                        hp1                                     --�p�[�e�B�}�X�^�i�ڋq�j
              , xxcmm_cust_accounts               xca                                     --�ڋq�ǉ����
              , hz_cust_accounts                  hca2                                    --�ڋq�}�X�^�i���_�j
              , hz_parties                        hp2                                     --�p�[�e�B�}�X�^�i���_�j
      --�d����}�X�^
      WHERE     xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --�ڋq�}�X�^�i�ڋq�j
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --�ڋq�}�X�^�i���_�j
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      AND       xbb.bm_balance_id                 >=        gt_id_from
      AND       xbb.bm_balance_id                 <=        gt_id_to
      --
      ORDER BY  bm_balance_id
    ;
    --
    skip_record_manual_expt   EXCEPTION;
    skip_record_fixed_expt    EXCEPTION;
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
    -- 1 ������s�̏ꍇ�̏ꍇ
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      OPEN  get_bm_balance_fixed_cur;   
      <<get_bm_balance_fixed_loop>>   
      LOOP
        FETCH   get_bm_balance_fixed_cur           INTO      
            lv_data_type                          --�f�[�^�^�C�v
          , gt_data_tab(1)                        --�̎�c��ID
          , gt_data_tab(2)                        --���_�R�[�h
          , gt_data_tab(3)                        --���_��
          , gt_data_tab(4)                        --�d����R�[�h
          , gt_data_tab(5)                        --�d���於��
          , gt_data_tab(6)                        --�d����T�C�g�R�[�h
          , gt_data_tab(7)                        --BM�x���敪
          , gt_data_tab(8)                        --�⍇���S�����_�R�[�h
          , gt_data_tab(9)                        --�U���萔�����S
          , gt_data_tab(10)                       --�ڋq�R�[�h
          , gt_data_tab(11)                       --�ڋq��
          , gt_data_tab(12)                       --�Ƒԁi�����ށj
          , gt_data_tab(13)                       --���ߓ�
          , gt_data_tab(14)                       --�̔����z�i�ō��j
          , gt_data_tab(15)                       --�̔��萔��
          , gt_data_tab(16)                       --�̔��萔���i����Ŋz�j
          , gt_data_tab(17)                       --�d�C��
          , gt_data_tab(18)                       --�d�C���i����Ŋz�j
          , gt_data_tab(19)                       --�ŋ��R�[�h
          , gt_data_tab(20)                       --�x���\���
          , gt_data_tab(21)                       --�x���\��z�i�ō��j
          , gt_data_tab(22)                       --�x���z�i�ō��j
          , gt_data_tab(23)                       --�c�������
          , gt_data_tab(24)                       --�ۗ��t���O
          , gt_data_tab(25)                       --�g�ݖ߂��t���O
          , gt_data_tab(26)                       --�ē���������
          , gt_data_tab(27)                       --���`�[�ԍ�
          , gt_data_tab(28)                       --�����敪
          , lt_gl_interface_status                --�A�g�X�e�[�^�X�iGL�j
          ;
        EXIT WHEN get_bm_balance_fixed_cur%NOTFOUND;        
        --���A�g�e�[�u���o�͑Ώ�
        gb_coop_out   :=  TRUE;
        --
        IF ( lv_data_type = cv_data_type_bm_balance ) THEN
          gn_target_cnt       :=  gn_target_cnt       +   1;
        ELSE
          gn_target_coop_cnt  :=  gn_target_coop_cnt  +   1;
        END IF;
        --
        BEGIN
          --�g�ݖ߂��t���O��'Y'�̏ꍇ�A�g�ݖ߂����̎擾���s���B
          IF ( gt_data_tab(25) = cv_flag_y ) THEN
            --==============================================================
            -- �g�ݖ߂����擾����(A-5)
            --==============================================================
            get_bm_balance_rtn_info (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE   global_process_expt;
            END IF;          
          END IF;
          --==============================================================
          -- ���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item (
              it_gl_interface_status  =>        lt_gl_interface_status
            , ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE   skip_record_fixed_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE   global_process_expt;
          END IF;          
          --==============================================================
          -- CSV�o�͏���(A-7)  
          --==============================================================
          out_csv (
              ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE   global_process_expt;
          END IF;
        EXCEPTION
          WHEN skip_record_fixed_expt THEN
            --==============================================================
            -- ���A�g�e�[�u���o�^����(A-8)
            --==============================================================
            IF ( gb_coop_out = TRUE ) THEN
              ins_bm_balance_wait_coop (
                  ov_errbuf               =>        lv_errbuf
                , ov_retcode              =>        lv_retcode
                , ov_errmsg               =>        lv_errmsg
                );
              --
            END IF;
            --
            gb_status_warn  :=  TRUE;           --�x���I����
            --
        END;
        --
      END LOOP get_bm_balance_fixed_loop;
      --
      IF ( gn_target_cnt = 0 ) AND ( gn_target_coop_cnt = 0 ) THEN
        --
        ov_retcode  :=  cv_status_warn ;
        --
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcff_appl_name
                        , iv_name         => cv_msg_cff_00165
                        , iv_token_name1  => cv_token_get_data
                        , iv_token_value1 => gv_backmargin_balance
                        );
        --
        FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errmsg --�G���[���b�Z�[�W
        );
        --
        FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errmsg --�G���[���b�Z�[�W
        );
        --
        gb_status_warn  :=  TRUE;           --�x���I����
        --
      END IF;
      --
      CLOSE get_bm_balance_fixed_cur;
    --==============================================================
    -- 2 �蓮���s�̏ꍇ
    --==============================================================
    ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN  
      OPEN  get_bm_balance_manual_cur;   
      <<get_bm_balance_manual_loop>>   
      LOOP
        FETCH   get_bm_balance_manual_cur      INTO      
            lv_data_type                          --�f�[�^�^�C�v
          , gt_data_tab(1)                        --�̎�c��ID
          , gt_data_tab(2)                        --���_�R�[�h
          , gt_data_tab(3)                        --���_��
          , gt_data_tab(4)                        --�d����R�[�h
          , gt_data_tab(5)                        --�d���於��
          , gt_data_tab(6)                        --�d����T�C�g�R�[�h
          , gt_data_tab(7)                        --BM�x���敪
          , gt_data_tab(8)                        --�⍇���S�����_�R�[�h
          , gt_data_tab(9)                        --�U���萔�����S
          , gt_data_tab(10)                       --�ڋq�R�[�h
          , gt_data_tab(11)                       --�ڋq��
          , gt_data_tab(12)                       --�Ƒԁi�����ށj
          , gt_data_tab(13)                       --���ߓ�
          , gt_data_tab(14)                       --�̔����z�i�ō��j
          , gt_data_tab(15)                       --�̔��萔��
          , gt_data_tab(16)                       --�̔��萔���i����Ŋz�j
          , gt_data_tab(17)                       --�d�C��
          , gt_data_tab(18)                       --�d�C���i����Ŋz�j
          , gt_data_tab(19)                       --�ŋ��R�[�h
          , gt_data_tab(20)                       --�x���\���
          , gt_data_tab(21)                       --�x���\��z�i�ō��j
          , gt_data_tab(22)                       --�x���z�i�ō��j
          , gt_data_tab(23)                       --�c�������
          , gt_data_tab(24)                       --�ۗ��t���O
          , gt_data_tab(25)                       --�g�ݖ߂��t���O
          , gt_data_tab(26)                       --�ē���������
          , gt_data_tab(27)                       --���`�[�ԍ�
          , gt_data_tab(28)                       --�����敪
          , lt_gl_interface_status                --GL�C���^�[�t�F�[�X�t���O
          ;
        EXIT WHEN get_bm_balance_manual_cur%NOTFOUND;        
        --
        gn_target_cnt   :=  gn_target_cnt   +   1;
        --
        BEGIN
          IF ( gt_data_tab(25) = cv_flag_y ) THEN
            --==============================================================
            -- �g�ݖ߂����擾����(A-5)
            --==============================================================
            get_bm_balance_rtn_info (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE   global_process_expt;
            END IF;          
          END IF;
          --==============================================================
          -- ���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item (
              it_gl_interface_status    =>        lt_gl_interface_status
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE   skip_record_manual_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE   global_process_expt;
          END IF;          
          --==============================================================
          -- CSV�o�͏���(A-7)
          --==============================================================
          out_csv (
              ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE   global_process_expt;
          END IF;
        EXCEPTION
          WHEN skip_record_manual_expt THEN
            gb_status_warn  :=  TRUE;
        END;
      END LOOP get_bm_balance_manual_loop;
      --
      IF ( gn_target_cnt = 0 ) THEN
        --
        ov_retcode  :=  cv_status_warn ;
        --
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcff_appl_name
                        , iv_name         => cv_msg_cff_00165
                        , iv_token_name1  => cv_token_get_data
                        , iv_token_value1 => gv_backmargin_balance
                        );
        --
        FND_FILE.PUT_LINE(
            which               =>  cv_file_type_log
          , buff                =>  lv_errmsg --�G���[���b�Z�[�W
        );
        --
        FND_FILE.PUT_LINE(
            which               =>  cv_file_type_out
          , buff                =>  lv_errmsg --�G���[���b�Z�[�W
        );
        --
        gb_status_warn  :=  TRUE;           --�x���I����
        --
      END IF;
      --
      CLOSE get_bm_balance_manual_cur;   
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
  END get_bm_balance;
--
  /**********************************************************************************
   * Procedure Name   : upd_bm_balance_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE upd_bm_balance_control(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bm_balance_control'; -- �v���O������
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
    lt_bm_balance_id_max                xxcok_backmargin_balance.bm_balance_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    ln_ctl_max_bm_balance_id            xxcfo_bm_balance_control.bm_balance_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
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
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        UPDATE    xxcfo_bm_balance_control        xbbc
        SET       xbbc.process_flag               =     cv_flag_y                         --�����σt���O
                , xbbc.last_updated_by            =     cn_last_updated_by                --�ŏI�X�V��
                , xbbc.last_update_date           =     cd_last_update_date               --�ŏI�X�V��
                , xbbc.last_update_login          =     cn_last_update_login              --�ŏI�X�V���O�C��
                , xbbc.request_id                 =     cn_request_id                     --�v��ID
                , xbbc.program_application_id     =     cn_program_application_id         --�v���O�����A�v���P�[�V����ID
                , xbbc.program_id                 =     cn_program_id                     --�v���O����ID
                , xbbc.program_update_date        =     cd_program_update_date            --�v���O�����X�V��
        WHERE     xbbc.rowid                      =     gt_row_id_to
        ;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      BEGIN
        SELECT    MAX(xbbc.bm_balance_id)               ctl_max_bm_balance_id
        INTO      ln_ctl_max_bm_balance_id
        FROM      xxcfo_bm_balance_control        xbbc
        ;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      BEGIN
-- 2012/11/28 Ver.1.2 T.Osawa Modify Start
--      SELECT    MAX(xbb.bm_balance_id)          AS    bm_balance_id_max
--      INTO      lt_bm_balance_id_max
--      FROM      xxcok_backmargin_balance        xbb
--      WHERE     xbb.creation_date               <=      gd_prdate
        SELECT    NVL(MAX(xbb.bm_balance_id), ln_ctl_max_bm_balance_id)
                                                  AS    bm_balance_id_max
        INTO      lt_bm_balance_id_max
        FROM      xxcok_backmargin_balance        xbb
        WHERE     xbb.bm_balance_id               >     ln_ctl_max_bm_balance_id
        AND       xbb.creation_date               <     ( gd_prdate + 1 + ( gn_electric_exec_time / 24 ) )
-- 2012/11/28 Ver.1.2 T.Osawa Modify End
        ;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
      END;
      --
      BEGIN
        INSERT INTO xxcfo_bm_balance_control (
            business_date                         --�Ɩ����t
          , bm_balance_id                         --�̎�c��ID
          , process_flag                          --�����t���O
          , created_by                            --�쐬��
          , creation_date                         --�쐬��
          , last_updated_by                       --�ŏI�X�V��
          , last_update_date                      --�ŏI�X�V��
          , last_update_login                     --�ŏI�X�V���O�C��
          , request_id                            --�v��ID
          , program_application_id                --�v���O�����A�v���P�[�V����ID
          , program_id                            --�v���O�����X�V��
          , program_update_date                   --�v���O�����X�V��
        ) VALUES ( 
            gd_prdate                             --�Ɩ����t
          , lt_bm_balance_id_max                  --�̎�c��ID
          , cv_flag_n                             --�����t���O
          , cn_created_by                         --�쐬��
          , cd_creation_date                      --�쐬��
          , cn_last_updated_by                    --�ŏI�X�V��
          , cd_last_update_date                   --�ŏI�X�V��
          , cn_last_update_login                  --�ŏI�X�V���O�C��
          , cn_request_id                         --�v��ID
          , cn_program_application_id             --�v���O�����A�v���P�[�V����ID
          , cn_program_id                         --�v���O����ID
          , cd_program_update_date                --�v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
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
  END upd_bm_balance_control;
--
  /**********************************************************************************
   * Procedure Name   : del_bm_balance_wait
   * Description      : ���A�g�e�[�u���폜����(A-11)
   ***********************************************************************************/
  PROCEDURE del_bm_balance_wait (
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_bm_balance_wait'; -- �v���O������
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
    ln_del_cnt                NUMBER;   
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
    BEGIN
      FORALL ln_del_cnt IN 1..gt_bm_balance_rowid_tbl.COUNT  
        DELETE 
        FROM      xxcfo_bm_balance_wait_coop        xbbwc
        WHERE     xbbwc.rowid                       =         gt_bm_balance_rowid_tbl(ln_del_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00025
                      , iv_token_name1  => cv_token_table
                      , iv_token_name2  => cv_token_errmsg
                      , iv_token_value1 => gv_bm_balance_coop_wait
                      , iv_token_value2 => NULL
                      );
        --
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
  END del_bm_balance_wait;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̎�c��ID(From)
    iv_id_to            IN  VARCHAR2,             --�̎�c��ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --����蓮�敪
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
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
    -- *** ���[�J���ϐ� ***
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt       :=  0;          --�Ώی���
    gn_normal_cnt       :=  0;          --�o�͌���
    gn_error_cnt        :=  0;          --�G���[����
    gn_warn_cnt         :=  0;          --�x������
    gn_target_coop_cnt  :=  0;          --���A�g�f�[�^�Ώی���
    gn_out_rtn_coop_cnt :=  0;          --���A�W�o�͌����i�g�ݖ߂��ǉ����j
    gn_out_coop_cnt     :=  0;          --���A�g�o�͌���
    gb_fileopen         :=  FALSE;      --�t�@�C���I�[�v���t���O
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
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̎�c��ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̎�c��ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- ����蓮�敪
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-2)
    -- ===============================
    get_bm_balance_control(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̎�c��ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̎�c��ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- ����蓮�敪
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �g�ݖ߂��Ǘ��f�[�^�擾����(A-3)
    -- ===============================
    get_bm_rtn_info(
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-4)
    -- ===============================
    get_bm_balance_wait(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̎�c��ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̎�c��ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- ����蓮�敪
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^���o(A-5)
    -- ===============================
    get_bm_balance(
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-10)
    --==============================================================
    upd_bm_balance_control (
        ov_errbuf             =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode            =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg             =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    --==============================================================
    -- ���A�g�e�[�u���폜����(A-11)
    --==============================================================
    --������s�̏ꍇ�A���̋@�̔��萔�����A�g�e�[�u���̍폜���s��
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      del_bm_balance_wait (
          ov_errbuf           =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode          =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg           =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      --
      IF ( lv_retcode = cv_status_error ) THEN
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
    errbuf              OUT VARCHAR2              --�G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode             OUT VARCHAR2              --���^�[���E�R�[�h    --# �Œ� #
   ,iv_ins_upd_kbn      IN  VARCHAR2              --�ǉ��X�V�敪
   ,iv_file_name        IN  VARCHAR2              --�t�@�C����
   ,iv_id_from          IN  VARCHAR2              --�̎�c��ID�iFrom�j
   ,iv_id_to            IN  VARCHAR2              --�̎�c��ID�iTo�j
   ,iv_exec_kbn         IN  VARCHAR2              --����蓮�敪
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
        ov_retcode            =>  lv_retcode
      , ov_errbuf             =>  lv_errbuf
      , ov_errmsg             =>  lv_errmsg
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
      iv_ins_upd_kbn          =>        iv_ins_upd_kbn      -- �ǉ��X�V�敪
      ,iv_file_name           =>        iv_file_name        -- �t�@�C����
      ,iv_id_from             =>        iv_id_from          -- �̎�c��ID(From)
      ,iv_id_to               =>        iv_id_to            -- �̎�c��ID(To)
      ,iv_exec_kbn            =>        iv_exec_kbn        -- ����蓮�敪
      ,ov_errbuf              =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --==============================================================
    -- �t�@�C���N���[�Y
    --==============================================================
    --�t�@�C�����I�[�v������Ă���ꍇ�A�t�@�C�����N���[�Y����
    IF ( gb_fileopen = TRUE ) THEN
      BEGIN
        UTL_FILE.FCLOSE (
          file                =>        gv_activ_file_h);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_00029
                        , iv_token_name1  => cv_token_max_id
                        , iv_token_value1 => gt_id_from
                        );
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
          RAISE global_api_others_expt;      
      END;
    END IF;
    --�蓮���s���ɁA�G���[���������Ă����ꍇ�A�t�@�C����0�o�C�g�ɂ���
    IF ( gv_exec_kbn = cv_exec_manual )   THEN
      IF  ( lv_retcode = cv_status_error ) 
      AND ( gb_get_bm_balance = TRUE )             
      THEN
        --�I�[�v��
        gv_activ_file_h := UTL_FILE.FOPEN(
                              location     => gv_file_path        -- �f�B���N�g���p�X
                            , filename     => gv_file_name        -- �t�@�C����
                            , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                            , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                           );
        --�N���[�Y
        UTL_FILE.FCLOSE (
          file                    =>    gv_activ_file_h);
        --
      END IF;
    END IF;
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_normal_cnt       :=  0;    --�o�͌�����0���ɂ���
      gn_target_cnt       :=  0;    --���o������0���ɂ���
      gn_target_coop_cnt  :=  0;    --���̋@�̔��萔�����A�g������0����
      gn_out_coop_cnt     :=  0;    --CSV�o�͌���
      gn_out_rtn_coop_cnt :=  0;    --���̋@�̔��萔�����A�g�����i�g�ݖ߂����j��0����
      --
      gn_error_cnt  :=  gn_error_cnt    +   1;
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_out
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_log
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => ''
    );
    --�Ώی����o�́i�̎�c���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o�́i���̋@�̔��萔�����A�g�e�[�u���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --���A�g�e�[�u���o�͌����i�g�ݖ߂����j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_11121
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_out_rtn_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --���A�g�e�[�u���o�͌���
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_out_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code   := cv_normal_msg;
      IF ( gb_status_warn = TRUE )  THEN
        lv_retcode            :=  cv_status_warn;
        lv_message_code :=  cv_warn_msg;
      END IF;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code   := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code   := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
END XXCFO019A08C;
/
