CREATE OR REPLACE PACKAGE BODY XXCFO019A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A09C(body)
 * Description      : �d�q����݌ɊǗ��̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A09_�d�q����݌ɊǗ��̏��n�V�X�e���A�g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_inv_wait_coop      ���A�g�f�[�^�擾����(A-2)
 *  get_inv_control        �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  get_cost               �������擾����(A-5)
 *  chk_item               ���ڃ`�F�b�N����(A-6)
 *  out_csv                CSV�o�͏���(A-7)
 *  ins_inv_wait_coop      ���A�g�e�[�u���o�^����(A-8)
 *  get_inv                �Ώۃf�[�^�擾(A-4)
 *  ins_upd_inv_control    �Ǘ��e�[�u���o�^�E�X�V����(A-9)
 *  del_inv_wait_coop      ���A�g�e�[�u���폜����(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-11)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-03    1.0   K.Nakamura       �V�K�쐬
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
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A09C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)  := 'XXCFF';        -- �A�h�I���F���[�X�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)  := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�h�I���F�݌ɁE�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';       -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_organization_code        CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';                 -- �݌ɑg�D�R�[�h
  cv_trans_type_std_cost_upd  CONSTANT VARCHAR2(50) := 'XXCOI1_TRANS_TYPE_STD_COST_UPD';           -- ����^�C�v���F�W�������X�V
  cv_aff3_shizuoka_factory    CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHIZUOKA_FACTORY';             -- ����ȖځF�É��H�ꊨ��
  cv_aff3_shouhin             CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHOUHIN';                      -- ����ȖځF���i
  cv_aff3_seihin              CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SEIHIN';                       -- ����ȖځF���i
  cv_aff2_adj_dept_code       CONSTANT VARCHAR2(50) := 'XXCOI1_AFF2_ADJUSTMENT_DEPT_CODE';         -- ��������R�[�h
  cv_ins_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_I_FILENAME'; -- �d�q����݌ɊǗ��f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_U_FILENAME'; -- �d�q����݌ɊǗ��f�[�^�X�V�t�@�C����
  -- �Q�ƃ^�C�v
  cv_lookup_item_chk_inv      CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_INV';             -- �d�q���덀�ڃ`�F�b�N�i�݌ɊǗ��j
  cv_lookup_elec_book_date    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';                -- �d�q���돈�����s��
  -- ���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
  cv_msg_coi_00006            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_coi_10256            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10256'; -- ����^�C�vID�擾�G���[���b�Z�[�W
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
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10004'; -- �p�����[�^���͕s�����b�Z�[�W
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10006'; -- �͈͎w��G���[���b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007'; -- ���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10008'; -- �p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010'; -- ���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011'; -- �������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10023            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10023'; -- �c�ƌ����擾�G���[���b�Z�[�W
  cv_msg_cfo_10024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10024'; -- �W�������擾�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025'; -- �擾�Ώۃf�[�^�����G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_cause                CONSTANT VARCHAR2(20) := 'CAUSE';                -- ���A�g�f�[�^�o�^���R
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20) := 'DIR_TOK';              -- �f�B���N�g����
  cv_tkn_doc_data             CONSTANT VARCHAR2(20) := 'DOC_DATA';             -- �f�[�^���e
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20) := 'DOC_DIST_ID';          -- �f�[�^�l
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';               -- SQL�G���[���b�Z�[�W
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';            -- �t�@�C����
  cv_tkn_get_data             CONSTANT VARCHAR2(20) := 'GET_DATA';             -- �e�[�u����
  cv_tkn_item_code            CONSTANT VARCHAR2(20) := 'ITEM_CODE';            -- �i�ڃR�[�h
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';             -- �G���[���
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';          -- ���b�N�A�b�v�^�C�v��
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';          -- ���b�N�A�b�v�R�[�h��
  cv_tkn_max_id               CONSTANT VARCHAR2(20) := 'MAX_ID';               -- �ő�l
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';              -- ���A�g�G���[���e
  cv_tkn_org_code_tok         CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';         -- �݌ɑg�D�R�[�h
  cv_tkn_param                CONSTANT VARCHAR2(20) := 'PARAM';                -- �p�����[�^��
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';               -- �p�����[�^��
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';               -- �p�����[�^��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20) := 'PROF_NAME';            -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                -- �e�[�u����
  cv_tkn_target               CONSTANT VARCHAR2(20) := 'TARGET';               -- ���A�g�f�[�^����L�[
  cv_tkn_trn_type_tok         CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK'; -- ����^�C�v
  cv_tkn_trn_date             CONSTANT VARCHAR2(20) := 'TRN_DATE';             -- �����
  cv_tkn_trn_id               CONSTANT VARCHAR2(20) := 'TRN_ID';               -- ���ID
  -- �g�[�N���l
  cv_msg_cfo_11008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11008'; -- ���ڂ��s��
  cv_msg_cfo_11017            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11017'; -- ���ގ��ID
  cv_msg_cfo_11018            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11018'; -- ���ގ��ID(From)
  cv_msg_cfo_11019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11019'; -- ���ގ��ID(To)
  cv_msg_cfo_11020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11020'; -- GL�o�b�`ID
  cv_msg_cfo_11021            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11021'; -- GL�o�b�`ID(From)
  cv_msg_cfo_11022            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11022'; -- GL�o�b�`ID(To)
  cv_msg_cfo_11023            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11023'; -- ���ގ��ID�AGL�o�b�`ID
  cv_msg_cfo_11024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11024'; -- �݌ɊǗ����
  cv_msg_cfo_11025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11025'; -- �݌ɊǗ����A�g�e�[�u��
  cv_msg_cfo_11026            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11026'; -- �݌ɊǗ��Ǘ��e�[�u��
  -- ���t�t�H�[�}�b�g
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- YYYYMMDD�t�H�[�}�b�g
  cv_format_yyyymmdd2         CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';       -- YYYY/MM/DD�t�H�[�}�b�g
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
  -- �\�[�X�^�C�v
  cv_source_tyep_3            CONSTANT VARCHAR2(1)  := '3';                -- ����Ȗڎ��
  -- ��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)  := 'N';                -- 'N'
  -- �o��
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';           -- ���b�Z�[�W�o��
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';              -- ���O�o��
  cv_open_mode_w              CONSTANT VARCHAR2(1)  := 'W';                -- �������݃��[�h
  cv_slash                    CONSTANT VARCHAR2(1)  := '/';                -- �X���b�V��
  cv_delimit                  CONSTANT VARCHAR2(1)  := ',';                -- �J���}
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- ��������
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
  -- �݌ɊǗ����A�g�f�[�^���R�[�h
  TYPE g_inv_wait_coop_rtype IS RECORD(
      transaction_id          xxcfo_inventory_wait_coop.transaction_id%TYPE -- ���ގ��ID
    , gl_batch_id             xxcfo_inventory_wait_coop.gl_batch_id%TYPE    -- GL�o�b�`ID
    , xiwc_rowid              ROWID                                         -- ROWID
  );
  -- �݌ɊǗ����A�g�f�[�^�e�[�u���^�C�v
  TYPE g_inv_wait_coop_ttype  IS TABLE OF g_inv_wait_coop_rtype INDEX BY PLS_INTEGER;
  --
  -- �݌ɊǗ��Ǘ��f�[�^���R�[�h
  TYPE g_inv_control_rtype IS RECORD(
      gl_batch_id             xxcfo_inventory_control.gl_batch_id%TYPE      -- GL�o�b�`ID
    , inv_creation_date       xxcfo_inventory_control.creation_date%TYPE    -- �쐬��
    , xic_rowid               ROWID                                         -- ROWID
  );
  -- �݌ɊǗ��Ǘ��f�[�^�e�[�u���^�C�v
  TYPE g_inv_control_ttype    IS TABLE OF g_inv_control_rtype INDEX BY PLS_INTEGER;
  --
  -- �W���������e�[�u���^�C�v
  TYPE g_cmpnt_cost_ttype     IS TABLE OF cm_cmpt_dtl.cmpnt_cost%TYPE INDEX BY VARCHAR2(32767);
  --
  -- �݌ɏ��e�[�u���^�C�v
  TYPE g_data_ttype           IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_trans_type_std_cost_upd  VARCHAR2(30)  DEFAULT NULL; -- ����^�C�v���F�W�������X�V
  gv_aff3_shizuoka_factory    VARCHAR2(10)  DEFAULT NULL; -- ����ȖځF�É��H�ꊨ��
  gv_aff3_shouhin             VARCHAR2(10)  DEFAULT NULL; -- ����ȖځF���i
  gv_aff3_seihin              VARCHAR2(10)  DEFAULT NULL; -- ����ȖځF���i
  gv_aff2_adj_dept_code       VARCHAR2(10)  DEFAULT NULL; -- ��������R�[�h
  gv_file_name                VARCHAR2(100) DEFAULT NULL; -- �d�q����݌ɊǗ��t�@�C����
  gv_coop_date                VARCHAR2(15)  DEFAULT NULL; -- �A�g�����p�V�X�e�����t
  gv_file_open_flg            VARCHAR2(1)   DEFAULT NULL; -- �t�@�C���I�[�v���t���O
  gv_warn_flg                 VARCHAR2(1)   DEFAULT NULL; -- �x���t���O
  gv_err_flg                  VARCHAR2(1)   DEFAULT NULL; -- �G���[�t���O
  gv_skip_flg                 VARCHAR2(1)   DEFAULT NULL; -- �X�L�b�v�t���O
  gn_target2_cnt              NUMBER;                     -- �Ώی����i���A�g���j
  gn_electric_exec_days       NUMBER        DEFAULT NULL; -- �d�q���돈�����s����
  gn_process_target_time      NUMBER        DEFAULT NULL; -- �����Ώێ���
  gd_process_date             DATE          DEFAULT NULL; -- �Ɩ����t
  gt_organization_code        mtl_parameters.organization_code%TYPE              DEFAULT NULL; -- �݌ɑg�D�R�[�h
  gt_organization_id          mtl_parameters.organization_id%TYPE                DEFAULT NULL; -- �݌ɑg�DID
  gt_item_id                  mtl_material_transactions.inventory_item_id%TYPE   DEFAULT NULL; -- �i��ID
  gt_transaction_type_id      mtl_transaction_types.transaction_type_id%TYPE     DEFAULT NULL; -- ����^�C�vID
  gt_trans_type_std_cost_upd  mtl_transaction_types.transaction_type_id%TYPE     DEFAULT NULL; -- ����^�C�vID�F�W�������X�V
  gt_gl_batch_id_from         xxcfo_inventory_control.gl_batch_id%TYPE           DEFAULT NULL; -- GL�o�b�`ID(�擾�pFrom)
  gt_gl_batch_id_to           xxcfo_inventory_control.gl_batch_id%TYPE           DEFAULT NULL; -- GL�o�b�`ID(�擾�pTo)
  gt_directory_name           all_directories.directory_name%TYPE                DEFAULT NULL; -- �f�B���N�g����
  gt_directory_path           all_directories.directory_path%TYPE                DEFAULT NULL; -- �f�B���N�g���p�X
  gv_file_handle              UTL_FILE.FILE_TYPE;                                              -- �t�@�C���n���h��
  -- �e�[�u���ϐ�
  g_chk_item_tab              g_chk_item_ttype;      -- ���ڃ`�F�b�N
  g_inv_wait_coop_tab         g_inv_wait_coop_ttype; -- �݌ɊǗ����A�g�e�[�u��
  g_inv_control_tab           g_inv_control_ttype;   -- �݌ɊǗ��Ǘ��e�[�u��
  g_inv_control_upd_tab       g_inv_control_ttype;   -- �݌ɊǗ��Ǘ��e�[�u���i�X�V�p�j
  g_cmpnt_cost_tab            g_cmpnt_cost_ttype;    -- �W���������
  g_data_tab                  g_data_ttype;          -- �o�̓f�[�^���
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
    iv_tran_id_from  IN  VARCHAR2, -- ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2, -- ���ގ��ID�iTo�j
    iv_batch_id_from IN  VARCHAR2, -- GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2, -- GL�o�b�`ID�iTo�j
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
      WHERE  flv.lookup_type  = cv_lookup_item_chk_inv
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
      , iv_conc_param3 => iv_tran_id_from  -- ���ގ��ID�iFrom�j
      , iv_conc_param4 => iv_tran_id_to    -- ���ގ��ID�iTo�j
      , iv_conc_param5 => iv_batch_id_from -- GL�o�b�`ID�iFrom�j
      , iv_conc_param6 => iv_batch_id_to   -- GL�o�b�`ID�iTo�j
      , iv_conc_param7 => iv_exec_kbn      -- ����蓮�敪
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
      , iv_conc_param3 => iv_tran_id_from  -- ���ގ��ID�iFrom�j
      , iv_conc_param4 => iv_tran_id_to    -- ���ގ��ID�iTo�j
      , iv_conc_param5 => iv_batch_id_from -- GL�o�b�`ID�iFrom�j
      , iv_conc_param6 => iv_batch_id_to   -- GL�o�b�`ID�iTo�j
      , iv_conc_param7 => iv_exec_kbn      -- ����蓮�敪
      , ov_errbuf      => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode     => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg      => lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- �p�����[�^���͕s��
      IF ( ( ( iv_tran_id_from  IS NOT NULL )
        AND  ( iv_tran_id_to    IS NOT NULL )
        AND  ( iv_batch_id_from IS NOT NULL )
        AND  ( iv_batch_id_to   IS NOT NULL ) )
      OR (   ( iv_tran_id_from  IS NULL )
        AND  ( iv_tran_id_to    IS NULL )
        AND  ( iv_batch_id_from IS NULL )
        AND  ( iv_batch_id_to   IS NULL ) ) )
      THEN
        -- �p�����[�^���͕s�����b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10004 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_param     -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11023 -- �g�[�N���l1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- �p�����[�^ID���͕s��
      IF ( ( ( iv_tran_id_from IS NOT NULL )
        AND  ( iv_tran_id_to   IS NULL ) )
      OR   ( ( iv_tran_id_from IS NULL )
        AND  ( iv_tran_id_to   IS NOT NULL ) )
      OR   ( TO_NUMBER(iv_tran_id_from) > TO_NUMBER(iv_tran_id_to) ) )
      THEN
        -- �p�����[�^ID���͕s�����b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10008 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_param1    -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11018 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_param2    -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => cv_msg_cfo_11019 -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- �p�����[�^ID���͕s��
      IF ( ( ( iv_batch_id_from IS NOT NULL )
        AND  ( iv_batch_id_to   IS NULL ) )
      OR   ( ( iv_batch_id_from IS NULL )
        AND  ( iv_batch_id_to   IS NOT NULL ) )
      OR   ( TO_NUMBER(iv_batch_id_from) <= -1 )
      OR   ( TO_NUMBER(iv_batch_id_to)   <= -1 )
      OR   ( TO_NUMBER(iv_batch_id_from) > TO_NUMBER(iv_batch_id_to) ) )
      THEN
        -- �p�����[�^ID���͕s�����b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10008 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_param1    -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11021 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_param2    -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => cv_msg_cfo_11022 -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
                                                   , iv_token_value1 => cv_lookup_item_chk_inv -- �g�[�N���l1
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
           , TO_NUMBER(flv.attribute2) AS attribute2 -- �����Ώێ���
      INTO   gn_electric_exec_days
           , gn_process_target_time
      FROM   fnd_lookup_values         flv
      WHERE  flv.lookup_type  = cv_lookup_elec_book_date
      AND    flv.lookup_code  = cv_pkg_name
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
      --
      IF ( ( gn_electric_exec_days IS NULL )
      OR   ( gn_process_target_time IS NULL ) )
      THEN
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
    -- �݌ɑg�D�R�[�h
    gt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
    --
    IF ( gt_organization_code IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001     -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_organization_code -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ����^�C�v���F�W�������X�V
    gv_trans_type_std_cost_upd  := FND_PROFILE.VALUE( cv_trans_type_std_cost_upd );
    --
    IF ( gv_trans_type_std_cost_upd IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo             -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001           -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name           -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_trans_type_std_cost_upd -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ����ȖځF�É��H�ꊨ��
    gv_aff3_shizuoka_factory  := FND_PROFILE.VALUE( cv_aff3_shizuoka_factory );
    --
    IF ( gv_aff3_shizuoka_factory IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001         -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_aff3_shizuoka_factory -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ����ȖځF���i
    gv_aff3_shouhin := FND_PROFILE.VALUE( cv_aff3_shouhin );
    --
    IF ( gv_aff3_shouhin IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_aff3_shouhin  -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ����ȖځF���i
    gv_aff3_seihin := FND_PROFILE.VALUE( cv_aff3_seihin );
    --
    IF ( gv_aff3_seihin IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_aff3_seihin   -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ��������R�[�h
    gv_aff2_adj_dept_code  := FND_PROFILE.VALUE( cv_aff2_adj_dept_code );
    --
    IF ( gv_aff2_adj_dept_code IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo        -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00001      -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_prof_name      -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_aff2_adj_dept_code -- �g�[�N���l1
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
        -- �d�q����݌ɊǗ��ǉ��t�@�C����
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
        -- �d�q����݌ɊǗ��X�V�t�@�C����
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
    -- ����^�C�vID�擾
    --==================================
    BEGIN
      SELECT mtt.transaction_type_id AS transaction_type_id
      INTO   gt_trans_type_std_cost_upd
      FROM   mtl_transaction_types   mtt
      WHERE  mtt.transaction_type_name = gv_trans_type_std_cost_upd
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi             -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_coi_10256           -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_trn_type_tok        -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => gv_trans_type_std_cost_upd -- �g�[�N���l1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- �݌ɑg�DID�擾
    --==================================
    gt_organization_id := xxcoi_common_pkg.get_organization_id( iv_organization_code => gt_organization_code );
    --
    IF ( gt_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi       -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_coi_00006     -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_org_code_tok  -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => gt_organization_code -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
   * Procedure Name   : get_inv_wait_coop
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_inv_wait_coop(
    iv_ins_upd_kbn   IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_tran_id_from  IN  VARCHAR2, -- ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2, -- ���ގ��ID�iTo�j
    iv_batch_id_from IN  VARCHAR2, -- GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2, -- GL�o�b�`ID�iTo�j
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_wait_coop'; -- �v���O������
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
    -- �݌ɊǗ����A�g�f�[�^�擾�J�[�\���i���b�N�j
    CURSOR inv_wait_coop_cur
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- ���ގ��ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GL�o�b�`ID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      FOR UPDATE NOWAIT
    ;
    -- �݌ɊǗ����A�g�f�[�^�擾�J�[�\���i���ގ��ID�w��j
    CURSOR inv_wait_coop_trn_cur( iv_tran_id_from  IN mtl_material_transactions.transaction_id%TYPE
                                , iv_tran_id_to    IN mtl_material_transactions.transaction_id%TYPE
                                )
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- ���ގ��ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GL�o�b�`ID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      WHERE  xiwc.transaction_id BETWEEN iv_tran_id_from
                                 AND     iv_tran_id_to
    ;
    -- �݌ɊǗ����A�g�f�[�^�擾�J�[�\���iGL�o�b�`ID�w��j
    CURSOR inv_wait_coop_batch_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  )
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- ���ގ��ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GL�o�b�`ID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      WHERE  xiwc.gl_batch_id BETWEEN iv_batch_id_from
                              AND     iv_batch_id_to
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
    -- �݌ɊǗ����A�g�f�[�^�擾
    --==============================================================
    -- ����蓮�敪��'0'�i����j���A'0'�i�ǉ��j�̏ꍇ
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( iv_ins_upd_kbn = cv_ins_upd_ins ) )
    THEN
      -- �J�[�\���I�[�v��
      OPEN inv_wait_coop_cur;
      --
      FETCH inv_wait_coop_cur BULK COLLECT INTO g_inv_wait_coop_tab;
      -- �J�[�\���N���[�Y
      CLOSE inv_wait_coop_cur;
      --
    -- ����蓮�敪��'1'�i�蓮�j���A'1'�i�X�V�j�̏ꍇ
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
    THEN
      -- ���ގ��(From-To)���w�肳��Ă���ꍇ
      IF ( iv_tran_id_from IS NOT NULL ) THEN
        -- �J�[�\���I�[�v��
        OPEN inv_wait_coop_trn_cur( TO_NUMBER( iv_tran_id_from )
                                  , TO_NUMBER( iv_tran_id_to )
                                  );
        --
        FETCH inv_wait_coop_trn_cur BULK COLLECT INTO g_inv_wait_coop_tab;
        -- �J�[�\���N���[�Y
        CLOSE inv_wait_coop_trn_cur;
        -- ���A�g�f�[�^���ΏۂɊ܂܂��ꍇ
        IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
          <<inv_wait_coop_trn_loop>>
          FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
            lv_errmsg := NULL;
            lv_errbuf := NULL;
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo                        -- �A�v���P�[�V�����Z�k��
                                                         , iv_name         => cv_msg_cfo_10010                      -- ���b�Z�[�W�R�[�h
                                                         , iv_token_name1  => cv_tkn_doc_data                       -- �g�[�N���R�[�h1
                                                         , iv_token_value1 => cv_msg_cfo_11017                      -- �g�[�N���l1
                                                         , iv_token_name2  => cv_tkn_doc_dist_id                    -- �g�[�N���R�[�h2
                                                         , iv_token_value2 => g_inv_wait_coop_tab(i).transaction_id -- �g�[�N���l2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --�G���[���b�Z�[�W
            );
          END LOOP inv_wait_coop_trn_loop;
          -- �G���[�t���O
          gv_err_flg := cv_flag_y;
          ov_retcode := cv_status_error;
          --
        END IF;
      -- GL�o�b�`ID(From-To)���w�肳��Ă���ꍇ
      ELSIF ( iv_batch_id_from IS NOT NULL ) THEN
        -- �J�[�\���I�[�v��
        OPEN inv_wait_coop_batch_cur( TO_NUMBER( iv_batch_id_from )
                                    , TO_NUMBER( iv_batch_id_to )
                                    );
        --
        FETCH inv_wait_coop_batch_cur BULK COLLECT INTO g_inv_wait_coop_tab;
        -- �J�[�\���N���[�Y
        CLOSE inv_wait_coop_batch_cur;
        --
        -- ���A�g�f�[�^���ΏۂɊ܂܂��ꍇ
        IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
          <<inv_wait_coop_batch_loop>>
          FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
            lv_errmsg := NULL;
            lv_errbuf := NULL;
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo                       -- �A�v���P�[�V�����Z�k��
                                                         , iv_name         => cv_msg_cfo_10010                     -- ���b�Z�[�W�R�[�h
                                                         , iv_token_name1  => cv_tkn_doc_data                      -- �g�[�N���R�[�h1
                                                         , iv_token_value1 => cv_msg_cfo_11020                     -- �g�[�N���l1
                                                         , iv_token_name2  => cv_tkn_doc_dist_id                   -- �g�[�N���R�[�h2
                                                         , iv_token_value2 => g_inv_wait_coop_tab( i ).gl_batch_id -- �g�[�N���l2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --�G���[���b�Z�[�W
            );
          END LOOP inv_wait_coop_batch_loop;
          -- �G���[�t���O
          gv_err_flg := cv_flag_y;
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00019 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11025 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( inv_wait_coop_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_cur;
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
      IF ( inv_wait_coop_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_cur;
      ELSIF ( inv_wait_coop_trn_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_trn_cur;
      ELSIF ( inv_wait_coop_batch_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_batch_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_inv_control(
    iv_ins_upd_kbn   IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_tran_id_from  IN  VARCHAR2, -- ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2, -- ���ގ��ID�iTo�j
    iv_batch_id_from IN  VARCHAR2, -- GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2, -- GL�o�b�`ID�iTo�j
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_control'; -- �v���O������
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
    lv_key_name               VARCHAR2(100) DEFAULT NULL;                 -- �L�[���ږ�
    lt_batch_id_max           xxcfo_inventory_control.gl_batch_id%TYPE;   -- �ő�GL�o�b�`ID�i�`�F�b�N�p�j
    lt_batch_id_min           xxcfo_inventory_control.gl_batch_id%TYPE;   -- �ŏ�GL�o�b�`ID�i�`�F�b�N�p�j
    lt_creation_date          xxcfo_inventory_control.creation_date%TYPE; -- �쐬���i�ꎞ�擾�p�j
    lt_gl_batch_id_from       xxcfo_inventory_control.gl_batch_id%TYPE;   -- �ő�GL�o�b�`ID�i�ێ��p�j
--
    -- *** ���[�J���J�[�\�� ***
    -- �݌ɊǗ��Ǘ��f�[�^�J�[�\��(To�擾)
    CURSOR inv_control_to_cur
    IS
      SELECT xic.gl_batch_id         AS gl_batch_id       -- GL�o�b�`ID
           , xic.creation_date       AS inv_creation_date -- �쐬��
           , xic.rowid               AS xic_rowid         -- ROWID
      FROM   xxcfo_inventory_control xic
      WHERE  xic.process_flag = cv_flag_n
      ORDER BY xic.gl_batch_id   DESC
             , xic.creation_date DESC
    ;
    -- �݌ɊǗ��Ǘ��f�[�^�J�[�\��
    CURSOR inv_control_cur( in_gl_batch_id_from IN xxcfo_inventory_control.gl_batch_id%TYPE
                          , in_gl_batch_id_to   IN xxcfo_inventory_control.gl_batch_id%TYPE
                          , id_creation_date    IN xxcfo_inventory_control.creation_date%TYPE
                          )
    IS
      SELECT xic.gl_batch_id         AS gl_batch_id       -- GL�o�b�`ID
           , xic.creation_date       AS inv_creation_date -- �쐬��
           , xic.rowid               AS xic_rowid         -- ROWID
      FROM   xxcfo_inventory_control xic
      WHERE  xic.process_flag   = cv_flag_n
      AND    xic.creation_date <= id_creation_date
      AND    xic.gl_batch_id BETWEEN in_gl_batch_id_from
                             AND     in_gl_batch_id_to
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
    --==============================================================
    -- GL�o�b�`ID(From)�擾
    --==============================================================
    -- �����ς�MAX�l��From�Ƃ��Ď擾
    SELECT MAX(xic.gl_batch_id) + 1 AS gl_batch_id
    INTO   gt_gl_batch_id_from                     -- GL�o�b�`ID�iFrom�j
    FROM   xxcfo_inventory_control xic
    WHERE  xic.process_flag = cv_flag_y
    ;
    -- �擾�ł��Ȃ��ꍇ
    IF ( gt_gl_batch_id_from IS NULL ) THEN
      -- �擾�Ώۃf�[�^�Ȃ����b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_10025 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_get_data  -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- GL�o�b�`ID(To)�擾
    --==============================================================
    -- ����蓮�敪��'0'�i����j���A'0'�i�ǉ��j�̏ꍇ
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( iv_ins_upd_kbn = cv_ins_upd_ins ) )
    THEN
      -- �J�[�\���I�[�v��
      OPEN inv_control_to_cur;
      --
      FETCH inv_control_to_cur BULK COLLECT INTO g_inv_control_tab;
      -- �J�[�\���N���[�Y
      CLOSE inv_control_to_cur;
      -- �Ώ�0���܂��͓d�q���돈�����s�����������Ȃ��ꍇ
      IF ( ( g_inv_control_tab.COUNT = 0 )
        OR ( g_inv_control_tab.COUNT < gn_electric_exec_days ) )
      THEN
        -- GL�o�b�`ID(To)�̒l��NULL�Ƃ��Ď擾
        gt_gl_batch_id_to := NULL;
        -- �擾�Ώۃf�[�^�������b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10025 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_get_data  -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => cv_msg_cfo_11026 -- �g�[�N���l1
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
        --
      ELSE
        -- �d�q���돈�����s�����̉񐔕��̒l��GL�o�b�`ID(To)�Ƃ��Ď擾
        <<inv_control_to_loop>>
        FOR i IN 1 .. gn_electric_exec_days LOOP
          IF ( i = gn_electric_exec_days ) THEN
            gt_gl_batch_id_to := g_inv_control_tab( i ).gl_batch_id;
            lt_creation_date  := g_inv_control_tab( i ).inv_creation_date;
          END IF;
        END LOOP inv_control_to_loop;
        --
        -- From>To�ɂȂ�ꍇ�i�Ώ�0���������񑱂����ꍇ�j
        IF ( gt_gl_batch_id_from > gt_gl_batch_id_to ) THEN
          -- �ێ����ē���l�ɒu������
          lt_gl_batch_id_from := gt_gl_batch_id_from;
          gt_gl_batch_id_from := gt_gl_batch_id_to;
        END IF;
        --
        -- �X�V�p�f�[�^�擾�iFrom-To�̃��R�[�h�擾�j
        OPEN inv_control_cur( gt_gl_batch_id_from
                            , gt_gl_batch_id_to
                            , lt_creation_date
                            );
        --
        FETCH inv_control_cur BULK COLLECT INTO g_inv_control_upd_tab;
        -- �J�[�\���N���[�Y
        CLOSE inv_control_cur;
        -- �ێ����Ă���ꍇ��
        IF ( lt_gl_batch_id_from IS NOT NULL ) THEN
          -- ���̒l�ɖ߂�
          gt_gl_batch_id_from := lt_gl_batch_id_from;
          --
        END IF;
      --
      END IF;
    -- ����蓮�敪��'1'�i�蓮�j���A'1'�i�X�V�j�̏ꍇ
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
    THEN
      -- ���ގ��(From-To)���w�肳��Ă���ꍇ
      IF ( iv_tran_id_from IS NOT NULL ) THEN
        -- ���ޔz���f�[�^
        SELECT MAX(mta.gl_batch_id)     AS lt_batch_id_max -- �ő�GL�o�b�`ID
             , MIN(mta.gl_batch_id)     AS lt_batch_id_min -- �ŏ�GL�o�b�`ID
        INTO   lt_batch_id_max
             , lt_batch_id_min
        FROM   mtl_transaction_accounts mta
        WHERE  mta.organization_id = gt_organization_id
        AND    mta.transaction_id BETWEEN TO_NUMBER(iv_tran_id_from)
                                  AND     TO_NUMBER(iv_tran_id_to)
        ;
        --
        -- �ő�GL�o�b�`ID��GL�o�b�`ID�iFrom�j�̏ꍇ�A�܂��͍ŏ�GL�o�b�`ID��-1�̏ꍇ
        IF ( ( lt_batch_id_max >= gt_gl_batch_id_from )
          OR ( lt_batch_id_min = -1 ) )
        THEN
          lv_key_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                         , iv_name         => cv_msg_cfo_11020 -- ���b�Z�[�W�R�[�h
                                                         )
                                , 1
                                , 5000
                                );
          -- �͈͎w��G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo      -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10006    -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_max_id       -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => lv_key_name ||
                                                                            cv_msg_part ||
                                                                            gt_gl_batch_id_from -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
        --
      -- GL�o�b�`ID(From-To)���w�肳��Ă���ꍇ
      ELSIF ( iv_batch_id_from IS NOT NULL ) THEN
        -- �擾����GL�o�b�`ID(From)�ȏ�̏ꍇ�i�������f�[�^���w�肵���ꍇ�j
        IF ( TO_NUMBER(iv_batch_id_to) >= gt_gl_batch_id_from ) THEN
          lv_key_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                         , iv_name         => cv_msg_cfo_11020 -- ���b�Z�[�W�R�[�h
                                                         )
                                , 1
                                , 5000
                                );
          -- �͈͎w��G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo      -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10006    -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_max_id       -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => lv_key_name ||
                                                                            cv_msg_part ||
                                                                            gt_gl_batch_id_from -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
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
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- �g�[�N���l1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( inv_control_cur%ISOPEN ) THEN
        CLOSE inv_control_cur;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\�����I�[�v�����Ă���ꍇ
      IF ( inv_control_to_cur%ISOPEN ) THEN
        CLOSE inv_control_to_cur;
      ELSIF ( inv_control_cur%ISOPEN ) THEN
        CLOSE inv_control_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : get_cost
   * Description      : �������擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_cost(
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cost'; -- �v���O������
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
    lv_key_code               VARCHAR2(32767); -- �L�[����
    lv_period_date            VARCHAR2(8);     -- �����
    ld_period_date            DATE;            -- �����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_key_code    := NULL;
    lv_period_date := NULL;
    ld_period_date := NULL;
    --
    --==============================================================
    -- �c�ƌ����`�F�b�N
    --==============================================================
    -- �c�ƌ�����NULL�̏ꍇ
    IF ( g_data_tab(26) IS NULL ) THEN
      -- �c�ƌ����擾�G���[���b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_10023 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_trn_id    -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => g_data_tab(1)    -- �g�[�N���l1
                                                   , iv_token_name2  => cv_tkn_item_code -- �g�[�N���R�[�h2
                                                   , iv_token_value2 => g_data_tab(5)    -- �g�[�N���l2
                                                   , iv_token_name3  => cv_tkn_trn_date  -- �g�[�N���R�[�h3
                                                   , iv_token_value3 => g_data_tab(3)    -- �g�[�N���l3
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      -- ����蓮�敪��'0'�i����j�̏ꍇ
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        RAISE global_warn_expt;
      -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
      ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- �Y�����̃L�[���ڍ쐬�i�i��ID || ������j
    lv_key_code := gt_item_id || g_data_tab(3);
    --
    -- ����L�[���擾���Ă���ꍇ
    IF ( g_cmpnt_cost_tab.EXISTS( lv_key_code ) ) THEN
      -- �擾�ς̕W��������ݒ�
      g_data_tab(25) := g_cmpnt_cost_tab( lv_key_code );
      -- �擾�ς̕W��������NULL�̏ꍇ
      IF ( g_data_tab(25) IS NULL ) THEN
        -- �W�������G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10024 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_trn_id    -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => g_data_tab(1)    -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_item_code -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => g_data_tab(5)    -- �g�[�N���l2
                                                     , iv_token_name3  => cv_tkn_trn_date  -- �g�[�N���R�[�h3
                                                     , iv_token_value3 => g_data_tab(3)    -- �g�[�N���l3
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- ����蓮�敪��'0'�i����j�̏ꍇ
        IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
          RAISE global_warn_expt;
        -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
        ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    -- ���擾�̏ꍇ
    ELSE
      --==============================================================
      -- �W�������`�F�b�N
      --==============================================================
      -- �������ϊ�
      lv_period_date := g_data_tab(3);
      ld_period_date := TO_DATE( lv_period_date, cv_format_yyyymmdd );
      -- ���b�Z�[�W�o��
      xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id     => gt_item_id         -- �i��ID
        , in_org_id      => gt_organization_id -- �݌ɑg�DID
        , id_period_date => ld_period_date     -- �����
        , ov_cmpnt_cost  => g_data_tab(25)     -- �W������
        , ov_errbuf      => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode     => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg      => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      -- �W��������ێ�
      g_cmpnt_cost_tab( lv_key_code ) := g_data_tab(25);
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �W�������G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_10024 -- ���b�Z�[�W�R�[�h
                                                     , iv_token_name1  => cv_tkn_trn_id    -- �g�[�N���R�[�h1
                                                     , iv_token_value1 => g_data_tab(1)    -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_item_code -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => g_data_tab(5)    -- �g�[�N���l2
                                                     , iv_token_name3  => cv_tkn_trn_date  -- �g�[�N���R�[�h3
                                                     , iv_token_value3 => g_data_tab(3)    -- �g�[�N���l3
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- ����蓮�敪��'0'�i����j�̏ꍇ
        IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
          RAISE global_warn_expt;
        -- ����蓮�敪��'1'�i�蓮�j�̏ꍇ
        ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;
    --==============================================================
    -- �����d����z�Z�o
    --==============================================================
    IF ( ov_retcode = cv_status_normal ) THEN
      -- ����^�C�v���W�������X�V�̏ꍇ
      IF ( gt_trans_type_std_cost_upd = gt_transaction_type_id ) THEN
        g_data_tab(24) := ROUND(g_data_tab(15) * -1);
      ELSE
        g_data_tab(24) := ROUND(g_data_tab(13) * ( g_data_tab(25) - g_data_tab(26) ));
      END IF;
    END IF;
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
  END get_cost;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
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
    lv_name                   VARCHAR2(20)   DEFAULT NULL; -- �L�[���ږ�
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
    -- ���ڃ`�F�b�N
    --==============================================================
    <<chk_item_loop>>
    FOR ln_cnt IN g_data_tab.FIRST .. g_data_tab.COUNT LOOP
      -- YYYYMMDDHH24MISS�t�H�[�}�b�g�i�A�g�����j�̓G���[�ɂȂ邽�߁A�`�F�b�N���Ȃ�
      IF ( ln_cnt <> 27 ) THEN
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
          lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_11017 -- ���b�Z�[�W�R�[�h
                                                     )
                            , 1
                            , 5000
                            );
          -- �G���[���b�Z�[�W�ҏW
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10011 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => lv_name     ||
                                                                            cv_msg_part ||
                                                                            g_data_tab(1)    -- �g�[�N���l1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- ����̏ꍇ
          IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
            -- �X�L�b�v�t���O
            gv_skip_flg := cv_flag_y;
            -- 1���ł��x�����������甲����
            RAISE global_warn_expt;
          -- �蓮�̏ꍇ
          ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
            RAISE global_process_expt;
          END IF;
        -- �����`�F�b�N�ȊO
        ELSE
          lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                     , iv_name         => cv_msg_cfo_11017 -- ���b�Z�[�W�R�[�h
                                                     )
                            , 1
                            , 5000
                            );
          -- ���ʊ֐��̃G���[���b�Z�[�W���o��
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_10007   -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_cause       -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11008   -- �g�[�N���l1
                                                       , iv_token_name2  => cv_tkn_target      -- �g�[�N���R�[�h2
                                                       , iv_token_value2 => lv_name     ||
                                                                            cv_msg_part ||
                                                                            g_data_tab(1)      -- �g�[�N���l2
                                                       , iv_token_name3  => cv_tkn_meaning     -- �g�[�N���R�[�h3
                                                       , iv_token_value3 => lv_errmsg          -- �g�[�N���l3
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- ����̏ꍇ
          IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
            -- 1���ł��x�����������甲����
            RAISE global_warn_expt;
          -- �蓮�̏ꍇ
          ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
            RAISE global_process_expt;
          END IF;
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
   * Procedure Name   : ins_inv_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_inv_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_wait_coop'; -- �v���O������
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
      INSERT INTO xxcfo_inventory_wait_coop(
          transaction_id            -- ���ID
        , organization_id           -- �݌ɑg�DID
        , primary_quantity          -- �������
        , amount                    -- �P��
        , transaction_amount        -- ����z
        , reference_account         -- ����Ȗڑg����ID
        , gl_batch_id               -- GL�o�b�`ID
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
          g_data_tab(1)             -- ���ID
        , gt_organization_id        -- �݌ɑg�DID
        , g_data_tab(13)            -- �������
        , g_data_tab(14)            -- �P��
        , g_data_tab(15)            -- ����z
        , g_data_tab(16)            -- ����Ȗڑg����ID
        , g_data_tab(17)            -- GL�o�b�`ID
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
                                                     , iv_token_value1 => cv_msg_cfo_11025 -- �g�[�N���l1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- �g�[�N���R�[�h2
                                                     , iv_token_value2 => SQLERRM          -- �g�[�N���l2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
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
  END ins_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_inv
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_inv(
    iv_tran_id_from  IN  VARCHAR2, -- ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2, -- ���ގ��ID�iTo�j
    iv_batch_id_from IN  VARCHAR2, -- GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2, -- GL�o�b�`ID�iTo�j
    iv_exec_kbn      IN  VARCHAR2, -- ����蓮�敪
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv'; -- �v���O������
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
    lv_chk_coop               VARCHAR2(1); -- �A�g���A�g����p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �Ώۃf�[�^�擾�J�[�\���i�蓮���s�����ގ��ID�w��j
    CURSOR get_manual_trn_id_cur( iv_tran_id_from  IN mtl_material_transactions.transaction_id%TYPE
                                , iv_tran_id_to    IN mtl_material_transactions.transaction_id%TYPE
                                )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N1) */
             mmt.transaction_id                                           AS transaction_id             -- ���ID
           , mmt.attribute1                                               AS attribute1                 -- �`�[�ԍ�
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- �����
           , mmt.transaction_type_id                                      AS transaction_type_id        -- ����^�C�vID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- ����^�C�v
           , mmt.inventory_item_id                                        AS item_id                    -- �i��ID
           , iimb.item_no                                                 AS item_code                  -- �i�ڃR�[�h
           , ximb.item_name                                               AS item_name                  -- �i�ږ�
           , mmt.subinventory_code                                        AS subinventory_code          -- �ۊǏꏊ�R�[�h
           , msi1.description                                             AS subinventory_name          -- �ۊǏꏊ��
           , msi1.attribute7                                              AS attribute7                 -- ���_�R�[�h
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- �����ۊǏꏊ
           , msi2.description                                             AS transfer_subinventory_name -- �����ۊǏꏊ��
           , msi2.attribute7                                              AS transfer_attribute7        -- ����拒�_�R�[�h
           , mta.primary_quantity                                         AS primary_quantity           -- �������
           , mta.rate_or_amount                                           AS rate_or_amount             -- �P��
           , mta.base_transaction_value                                   AS base_transaction_value     -- ������z
           , mta.reference_account                                        AS reference_account          -- ����Ȗڑg����ID
           , mta.gl_batch_id                                              AS gl_batch_id                -- �݌Ɏd��L�[�l
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- ���㋒�_
           , mmt.attribute6                                               AS attribute6                 -- �Ǌ����_
           , gcc1.segment2                                                AS dept_code                  -- ����R�[�h
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- ����ȖڃR�[�h���É��H�ꊨ��
                                        , gv_aff3_shouhin                                               -- ����ȖڃR�[�h�����i
                                        , gv_aff3_seihin )                                              -- ����ȖڃR�[�h�����i
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- ����ȖڃR�[�h����L�ȊO
                  END                                                     AS adj_dept_code              -- ��������R�[�h
           , gcc1.segment3                                                AS segment3                   -- ����ȖڃR�[�h
           , gcc1.segment4                                                AS segment4                   -- �⏕�ȖڃR�[�h
           , NULL                                                         AS adj_gl_amount              -- �����d����z
           , NULL                                                         AS cost                       -- �W������
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- �c�ƌ����K�p�J�n��
                  THEN iimb.attribute8                                                                  -- �c�ƌ���_�V
                  ELSE iimb.attribute7                                                                  -- �c�ƌ���_��
                  END                                                     AS discrete_cost              -- �c�ƌ���
           , gv_coop_date                                                 AS coop_date                  -- �A�g����
      FROM   mtl_material_transactions    mmt  -- ���ގ��
           , mtl_transaction_accounts     mta  -- ���ޔz��
           , mtl_system_items_b           msib -- Disc�i��
           , ic_item_mst_b                iimb -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b             ximb -- OPM�i�ڃA�h�I��
           , mtl_secondary_inventories    msi1 -- �ۊǏꏊ
           , mtl_secondary_inventories    msi2 -- �ۊǏꏊ�i�����j
           , gl_code_combinations         gcc1 -- ����Ȗڑg����
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.transaction_id BETWEEN iv_tran_id_from
                                AND     iv_tran_id_to
    ;
    --
    -- �Ώۃf�[�^�擾�J�[�\���i�蓮���s����GL�o�b�`ID�w��j
    CURSOR get_manual_batch_id_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N4) */
             mmt.transaction_id                                           AS transaction_id             -- ���ID
           , mmt.attribute1                                               AS attribute1                 -- �`�[�ԍ�
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- �����
           , mmt.transaction_type_id                                      AS transaction_type_id        -- ����^�C�vID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- ����^�C�v
           , mmt.inventory_item_id                                        AS item_id                    -- �i��ID
           , iimb.item_no                                                 AS item_code                  -- �i�ڃR�[�h
           , ximb.item_name                                               AS item_name                  -- �i�ږ�
           , mmt.subinventory_code                                        AS subinventory_code          -- �ۊǏꏊ�R�[�h
           , msi1.description                                             AS subinventory_name          -- �ۊǏꏊ��
           , msi1.attribute7                                              AS attribute7                 -- ���_�R�[�h
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- �����ۊǏꏊ
           , msi2.description                                             AS transfer_subinventory_name -- �����ۊǏꏊ��
           , msi2.attribute7                                              AS transfer_attribute7        -- ����拒�_�R�[�h
           , mta.primary_quantity                                         AS primary_quantity           -- �������
           , mta.rate_or_amount                                           AS rate_or_amount             -- �P��
           , mta.base_transaction_value                                   AS base_transaction_value     -- ������z
           , mta.reference_account                                        AS reference_account          -- ����Ȗڑg����ID
           , mta.gl_batch_id                                              AS gl_batch_id                -- �݌Ɏd��L�[�l
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- ���㋒�_
           , mmt.attribute6                                               AS attribute6                 -- �Ǌ����_
           , gcc1.segment2                                                AS dept_code                  -- ����R�[�h
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- ����ȖڃR�[�h���É��H�ꊨ��
                                        , gv_aff3_shouhin                                               -- ����ȖڃR�[�h�����i
                                        , gv_aff3_seihin )                                              -- ����ȖڃR�[�h�����i
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- ����ȖڃR�[�h����L�ȊO
                  END                                                     AS adj_dept_code              -- ��������R�[�h
           , gcc1.segment3                                                AS segment3                   -- ����ȖڃR�[�h
           , gcc1.segment4                                                AS segment4                   -- �⏕�ȖڃR�[�h
           , NULL                                                         AS adj_gl_amount              -- �����d����z
           , NULL                                                         AS cost                       -- �W������
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- �c�ƌ����K�p�J�n��
                  THEN iimb.attribute8                                                                  -- �c�ƌ���_�V
                  ELSE iimb.attribute7                                                                  -- �c�ƌ���_��
                  END                                                     AS discrete_cost              -- �c�ƌ���
           , gv_coop_date                                                 AS coop_date                  -- �A�g����
      FROM   mtl_material_transactions    mmt  -- ���ގ��
           , mtl_transaction_accounts     mta  -- ���ޔz��
           , mtl_system_items_b           msib -- Disc�i��
           , ic_item_mst_b                iimb -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b             ximb -- OPM�i�ڃA�h�I��
           , mtl_secondary_inventories    msi1 -- �ۊǏꏊ
           , mtl_secondary_inventories    msi2 -- �ۊǏꏊ�i�����j
           , gl_code_combinations         gcc1 -- ����Ȗڑg����
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.gl_batch_id BETWEEN iv_batch_id_from
                             AND     iv_batch_id_to
    ;
    --
    -- �Ώۃf�[�^�擾�J�[�\���i������s�j
    CURSOR get_fixed_period_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                               , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                               )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N4) */
             cv_coop                                                      AS chk_coop                   -- ����
           , mmt.transaction_id                                           AS transaction_id             -- ���ID
           , mmt.attribute1                                               AS attribute1                 -- �`�[�ԍ�
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- �����
           , mmt.transaction_type_id                                      AS transaction_type_id        -- ����^�C�vID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- ����^�C�v
           , mmt.inventory_item_id                                        AS item_id                    -- �i��ID
           , iimb.item_no                                                 AS item_code                  -- �i�ڃR�[�h
           , ximb.item_name                                               AS item_name                  -- �i�ږ�
           , mmt.subinventory_code                                        AS subinventory_code          -- �ۊǏꏊ�R�[�h
           , msi1.description                                             AS subinventory_name          -- �ۊǏꏊ��
           , msi1.attribute7                                              AS attribute7                 -- ���_�R�[�h
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- �����ۊǏꏊ
           , msi2.description                                             AS transfer_subinventory_name -- �����ۊǏꏊ��
           , msi2.attribute7                                              AS transfer_attribute7        -- ����拒�_�R�[�h
           , mta.primary_quantity                                         AS primary_quantity           -- �������
           , mta.rate_or_amount                                           AS rate_or_amount             -- �P��
           , mta.base_transaction_value                                   AS base_transaction_value     -- ������z
           , mta.reference_account                                        AS reference_account          -- ����Ȗڑg����ID
           , mta.gl_batch_id                                              AS gl_batch_id                -- �݌Ɏd��L�[�l
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- ���㋒�_
           , mmt.attribute6                                               AS attribute6                 -- �Ǌ����_
           , gcc1.segment2                                                AS dept_code                  -- ����R�[�h
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- ����ȖڃR�[�h���É��H�ꊨ��
                                        , gv_aff3_shouhin                                               -- ����ȖڃR�[�h�����i
                                        , gv_aff3_seihin )                                              -- ����ȖڃR�[�h�����i
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- ����ȖڃR�[�h����L�ȊO
                  END                                                     AS adj_dept_code              -- ��������R�[�h
           , gcc1.segment3                                                AS segment3                   -- ����ȖڃR�[�h
           , gcc1.segment4                                                AS segment4                   -- �⏕�ȖڃR�[�h
           , NULL                                                         AS adj_gl_amount              -- �����d����z
           , NULL                                                         AS cost                       -- �W������
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- �c�ƌ����K�p�J�n��
                  THEN iimb.attribute8                                                                  -- �c�ƌ���_�V
                  ELSE iimb.attribute7                                                                  -- �c�ƌ���_��
                  END                                                     AS discrete_cost              -- �c�ƌ���
           , gv_coop_date                                                 AS coop_date                  -- �A�g����
      FROM   mtl_material_transactions    mmt  -- ���ގ��
           , mtl_transaction_accounts     mta  -- ���ޔz��
           , mtl_system_items_b           msib -- Disc�i��
           , ic_item_mst_b                iimb -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b             ximb -- OPM�i�ڃA�h�I��
           , mtl_secondary_inventories    msi1 -- �ۊǏꏊ
           , mtl_secondary_inventories    msi2 -- �ۊǏꏊ�i�����j
           , gl_code_combinations         gcc1 -- ����Ȗڑg����
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.gl_batch_id BETWEEN iv_batch_id_from
                             AND     iv_batch_id_to
      UNION ALL
      SELECT /*+ LEADING(xiwc mmt msib iimb ximb)
                 USE_NL(xiwc mmt msib iimb ximb) */
             cv_wait_coop                                                 AS chk_coop                   -- ����
           , mmt.transaction_id                                           AS transaction_id             -- ���ID
           , mmt.attribute1                                               AS attribute1                 -- �`�[�ԍ�
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- �����
           , mmt.transaction_type_id                                      AS transaction_type_id        -- ����^�C�vID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- ����^�C�v
           , mmt.inventory_item_id                                        AS item_id                    -- �i��ID
           , iimb.item_no                                                 AS item_code                  -- �i�ڃR�[�h
           , ximb.item_name                                               AS item_name                  -- �i�ږ�
           , mmt.subinventory_code                                        AS subinventory_code          -- �ۊǏꏊ�R�[�h
           , msi1.description                                             AS subinventory_name          -- �ۊǏꏊ��
           , msi1.attribute7                                              AS attribute7                 -- ���_�R�[�h
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- �����ۊǏꏊ
           , msi2.description                                             AS transfer_subinventory_name -- �����ۊǏꏊ��
           , msi2.attribute7                                              AS transfer_attribute7        -- ����拒�_�R�[�h
           , xiwc.primary_quantity                                        AS primary_quantity           -- �������
           , xiwc.amount                                                  AS rate_or_amount             -- �P��
           , xiwc.transaction_amount                                      AS base_transaction_value     -- ������z
           , xiwc.reference_account                                       AS reference_account          -- ����Ȗڑg����ID
           , xiwc.gl_batch_id                                             AS gl_batch_id                -- �݌Ɏd��L�[�l
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- ���㋒�_
           , mmt.attribute6                                               AS attribute6                 -- �Ǌ����_
           , gcc1.segment2                                                AS dept_code                  -- ����R�[�h
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- ����ȖڃR�[�h���É��H�ꊨ��
                                        , gv_aff3_shouhin                                               -- ����ȖڃR�[�h�����i
                                        , gv_aff3_seihin )                                              -- ����ȖڃR�[�h�����i
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- ����ȖڃR�[�h����L�ȊO
                  END                                                     AS adj_dept_code              -- ��������R�[�h
           , gcc1.segment3                                                AS segment3                   -- ����ȖڃR�[�h
           , gcc1.segment4                                                AS segment4                   -- �⏕�ȖڃR�[�h
           , NULL                                                         AS adj_gl_amount              -- �����d����z
           , NULL                                                         AS cost                       -- �W������
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- �c�ƌ����K�p�J�n��
                  THEN iimb.attribute8                                                                  -- �c�ƌ���_�V
                  ELSE iimb.attribute7                                                                  -- �c�ƌ���_��
                  END                                                     AS discrete_cost              -- �c�ƌ���
           , gv_coop_date                                                 AS coop_date                  -- �A�g����
      FROM   mtl_material_transactions    mmt  -- ���ގ��
           , mtl_system_items_b           msib -- Disc�i��
           , ic_item_mst_b                iimb -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b             ximb -- OPM�i�ڃA�h�I��
           , mtl_secondary_inventories    msi1 -- �ۊǏꏊ
           , mtl_secondary_inventories    msi2 -- �ۊǏꏊ�i�����j
           , gl_code_combinations         gcc1 -- ����Ȗڑg����
           , xxcfo_inventory_wait_coop    xiwc -- �݌ɊǗ����A�g�e�[�u��
      WHERE  mmt.transaction_id           = xiwc.transaction_id
      AND    mmt.organization_id          = xiwc.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    xiwc.reference_account       = gcc1.code_combination_id
      AND    xiwc.organization_id         = gt_organization_id
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
    -- ����蓮�敪��'1'�i�蓮�j���A�u���ގ��ID�v�w��̏ꍇ
    IF (  ( iv_exec_kbn = cv_exec_manual )
      AND ( iv_tran_id_from IS NOT NULL ) )
    THEN
      -- �J�[�\���I�[�v��
      OPEN get_manual_trn_id_cur( TO_NUMBER( iv_tran_id_from )
                                , TO_NUMBER( iv_tran_id_to )
                                );
      --
      <<manual_trn_id_loop>>
      LOOP
      FETCH get_manual_trn_id_cur INTO
          g_data_tab(1)          -- ���ID
        , g_data_tab(2)          -- �`�[�ԍ�
        , g_data_tab(3)          -- �����
        , gt_transaction_type_id -- ����^�C�vID
        , g_data_tab(4)          -- ����^�C�v
        , gt_item_id             -- �i��ID
        , g_data_tab(5)          -- �i�ڃR�[�h
        , g_data_tab(6)          -- �i�ږ�
        , g_data_tab(7)          -- �ۊǏꏊ�R�[�h
        , g_data_tab(8)          -- �ۊǏꏊ��
        , g_data_tab(9)          -- ���_�R�[�h
        , g_data_tab(10)         -- �����ۊǏꏊ
        , g_data_tab(11)         -- �����ۊǏꏊ��
        , g_data_tab(12)         -- ����拒�_�R�[�h
        , g_data_tab(13)         -- �������
        , g_data_tab(14)         -- �P��
        , g_data_tab(15)         -- ����z
        , g_data_tab(16)         -- ����Ȗڑg����ID
        , g_data_tab(17)         -- �݌Ɏd��L�[�l
        , g_data_tab(18)         -- ���㋒�_
        , g_data_tab(19)         -- �Ǌ����_�R�[�h
        , g_data_tab(20)         -- ����R�[�h
        , g_data_tab(21)         -- ��������R�[�h
        , g_data_tab(22)         -- ����ȖڃR�[�h
        , g_data_tab(23)         -- �⏕�ȖڃR�[�h
        , g_data_tab(24)         -- �����d����z
        , g_data_tab(25)         -- �W������
        , g_data_tab(26)         -- �c�ƌ���
        , g_data_tab(27)         -- �A�g����
        ;
        --
        -- �������i���[�v���̔���p���^�[���R�[�h�j
        lv_retcode := cv_status_normal;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_manual_trn_id_cur%NOTFOUND;
        --
        -- �Ώی����i�A�g���j�J�E���g
        -- �蓮�̏ꍇ�͑Ώی����i���A�g���j�Ȃ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ���蓮�͌x���E���A�g�f�[�^�o�^�͂Ȃ�
        -- ===============================
        -- �������擾����(A-5)
        -- ===============================
        get_cost(
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
        -- ���ڃ`�F�b�N����(A-6)
        -- ===============================
        chk_item(
            iv_exec_kbn         -- ����蓮�敪
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- CSV�o�͏���(A-7)
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
      END LOOP manual_trn_id_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_manual_trn_id_cur;
--
    -- ����蓮�敪��'1'�i�蓮�j���A�uGL�o�b�`ID�v�w��̏ꍇ
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_batch_id_from IS NOT NULL ) )
    THEN
      -- �J�[�\���I�[�v��
      OPEN get_manual_batch_id_cur( TO_NUMBER( iv_batch_id_from )
                                  , TO_NUMBER( iv_batch_id_to )
                                  );
      --
      <<manual_batch_id_loop>>
      LOOP
      FETCH get_manual_batch_id_cur INTO
          g_data_tab(1)          -- ���ID
        , g_data_tab(2)          -- �`�[�ԍ�
        , g_data_tab(3)          -- �����
        , gt_transaction_type_id -- ����^�C�vID
        , g_data_tab(4)          -- ����^�C�v
        , gt_item_id             -- �i��ID
        , g_data_tab(5)          -- �i�ڃR�[�h
        , g_data_tab(6)          -- �i�ږ�
        , g_data_tab(7)          -- �ۊǏꏊ�R�[�h
        , g_data_tab(8)          -- �ۊǏꏊ��
        , g_data_tab(9)          -- ���_�R�[�h
        , g_data_tab(10)         -- �����ۊǏꏊ
        , g_data_tab(11)         -- �����ۊǏꏊ��
        , g_data_tab(12)         -- ����拒�_�R�[�h
        , g_data_tab(13)         -- �������
        , g_data_tab(14)         -- �P��
        , g_data_tab(15)         -- ����z
        , g_data_tab(16)         -- ����Ȗڑg����ID
        , g_data_tab(17)         -- �݌Ɏd��L�[�l
        , g_data_tab(18)         -- ���㋒�_
        , g_data_tab(19)         -- �Ǌ����_�R�[�h
        , g_data_tab(20)         -- ����R�[�h
        , g_data_tab(21)         -- ��������R�[�h
        , g_data_tab(22)         -- ����ȖڃR�[�h
        , g_data_tab(23)         -- �⏕�ȖڃR�[�h
        , g_data_tab(24)         -- �����d����z
        , g_data_tab(25)         -- �W������
        , g_data_tab(26)         -- �c�ƌ���
        , g_data_tab(27)         -- �A�g����
        ;
        --
        -- �������i���[�v���̔���p���^�[���R�[�h�j
        lv_retcode := cv_status_normal;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_manual_batch_id_cur%NOTFOUND;
        --
        -- �Ώی����i�A�g���j�J�E���g
        -- �蓮�̏ꍇ�͑Ώی����i���A�g���j�Ȃ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ���蓮�͌x���E���A�g�f�[�^�o�^�͂Ȃ�
        -- ===============================
        -- �������擾����(A-5)
        -- ===============================
        get_cost(
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
        -- ���ڃ`�F�b�N����(A-6)
        -- ===============================
        chk_item(
            iv_exec_kbn         -- ����蓮�敪
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- CSV�o�͏���(A-7)
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
      END LOOP manual_batch_id_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_manual_batch_id_cur;
--
    -- ����蓮�敪��'0'�i����j�̏ꍇ
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- �J�[�\���I�[�v��
      OPEN get_fixed_period_cur( gt_gl_batch_id_from
                               , gt_gl_batch_id_to
                               );
      --
      <<fixed_period_main_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
          lv_chk_coop            -- �A�g���A�g����p
        , g_data_tab(1)          -- ���ID
        , g_data_tab(2)          -- �`�[�ԍ�
        , g_data_tab(3)          -- �����
        , gt_transaction_type_id -- ����^�C�vID
        , g_data_tab(4)          -- ����^�C�v
        , gt_item_id             -- �i��ID
        , g_data_tab(5)          -- �i�ڃR�[�h
        , g_data_tab(6)          -- �i�ږ�
        , g_data_tab(7)          -- �ۊǏꏊ�R�[�h
        , g_data_tab(8)          -- �ۊǏꏊ��
        , g_data_tab(9)          -- ���_�R�[�h
        , g_data_tab(10)         -- �����ۊǏꏊ
        , g_data_tab(11)         -- �����ۊǏꏊ��
        , g_data_tab(12)         -- ����拒�_�R�[�h
        , g_data_tab(13)         -- �������
        , g_data_tab(14)         -- �P��
        , g_data_tab(15)         -- ����z
        , g_data_tab(16)         -- ����Ȗڑg����ID
        , g_data_tab(17)         -- �݌Ɏd��L�[�l
        , g_data_tab(18)         -- ���㋒�_
        , g_data_tab(19)         -- �Ǌ����_�R�[�h
        , g_data_tab(20)         -- ����R�[�h
        , g_data_tab(21)         -- ��������R�[�h
        , g_data_tab(22)         -- ����ȖڃR�[�h
        , g_data_tab(23)         -- �⏕�ȖڃR�[�h
        , g_data_tab(24)         -- �����d����z
        , g_data_tab(25)         -- �W������
        , g_data_tab(26)         -- �c�ƌ���
        , g_data_tab(27)         -- �A�g����
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
        -- �������擾����(A-5)
        -- ===============================
        get_cost(
            iv_exec_kbn         -- ����蓮�敪
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
          -- ���ڃ`�F�b�N����(A-6)
          -- ===============================
          chk_item(
              iv_exec_kbn         -- ����蓮�敪
            , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
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
        -- ����̏ꍇ
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ===============================
          -- CSV�o�͏���(A-7)
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
            -- ���A�g�e�[�u���o�^����(A-8)
            -- ===============================
            ins_inv_wait_coop(
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
                                                   , iv_token_value1 => cv_msg_cfo_11024 -- �g�[�N���l1
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
      IF ( get_manual_trn_id_cur%ISOPEN ) THEN
        CLOSE get_manual_trn_id_cur;
      ELSIF ( get_manual_batch_id_cur%ISOPEN ) THEN
        CLOSE get_manual_batch_id_cur;
      ELSIF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_inv_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_upd_inv_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_inv_control'; -- �v���O������
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
    lt_gl_batch_id_mic         xxcfo_inventory_control.gl_batch_id%TYPE; -- GL�o�b�`ID�i�݌ɊǗ��Ǘ��e�[�u���j
    lt_gl_batch_id_mta         xxcfo_inventory_control.gl_batch_id%TYPE; -- GL�o�b�`ID�i���ޔz���j
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώی��������݂��A�d�q���돈�����s�����ȏ�̏ꍇ
    IF (  ( g_inv_control_tab.COUNT > 0 )
      AND ( g_inv_control_tab.COUNT >= gn_electric_exec_days ) )
    THEN
      --==============================================================
      -- �݌ɊǗ��Ǘ��e�[�u���X�V
      --==============================================================
      <<update_loop>>
      FOR i IN g_inv_control_upd_tab.FIRST .. g_inv_control_upd_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_inventory_control xic
          SET    xic.process_flag           = cv_flag_y                        -- �����σt���O
               , xic.last_updated_by        = cn_last_updated_by               -- �ŏI�X�V��
               , xic.last_update_date       = cd_last_update_date              -- �ŏI�X�V��
               , xic.last_update_login      = cn_last_update_login             -- �ŏI�X�V���O�C��
               , xic.request_id             = cn_request_id                    -- �v��ID
               , xic.program_application_id = cn_program_application_id        -- �v���O�����A�v���P�[�V����ID
               , xic.program_id             = cn_program_id                    -- �v���O����ID
               , xic.program_update_date    = cd_program_update_date           -- �v���O�����X�V��
          WHERE  xic.rowid                  = g_inv_control_upd_tab( i ).xic_rowid -- ROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                         , iv_name         => cv_msg_cfo_00020 -- ���b�Z�[�W�R�[�h
                                                         , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                         , iv_token_value1 => cv_msg_cfo_11026 -- �g�[�N���l1
                                                         , iv_token_name2  => cv_tkn_errmsg    -- �g�[�N���R�[�h2
                                                         , iv_token_value2 => SQLERRM          -- �g�[�N���l2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            RAISE global_api_others_expt;
        END;
      END LOOP update_loop;
      --
    END IF;
--
    --==============================================================
    -- �݌ɊǗ��Ǘ��e�[�u���o�^
    --==============================================================
    -- MAX�l�擾�i�݌ɊǗ��Ǘ��e�[�u���j
    SELECT MAX(xic.gl_batch_id)    AS gl_batch_id
    INTO   lt_gl_batch_id_mic
    FROM   xxcfo_inventory_control xic
    ;
--
    -- MAX�l�擾�i���ޔz���j
    SELECT NVL(MAX(mta.gl_batch_id), lt_gl_batch_id_mic) AS gl_batch_id
    INTO   lt_gl_batch_id_mta
    FROM   mtl_transaction_accounts                      mta
    WHERE  mta.gl_batch_id > lt_gl_batch_id_mic
    AND    mta.creation_date < ( gd_process_date + 1 + ( gn_process_target_time / 24 ) )
    ;
--
    -- �݌ɊǗ��Ǘ��e�[�u���o�^
    BEGIN
      INSERT INTO xxcfo_inventory_control(
          business_date             -- �Ɩ����t
        , gl_batch_id               -- GL�o�b�`ID
        , process_flag              -- �����σt���O
        , created_by                -- �쐬��
        , creation_date             -- �쐬��
        , last_updated_by           -- �ŏI�X�V��
        , last_update_date          -- �ŏI�X�V��
        , last_update_login         -- �ŏI�X�V���O�C��
        , request_id                -- �v��ID
        , program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                -- �R���J�����g�E�v���O����ID
        , program_update_date       -- �v���O�����X�V��
      ) VALUES (
          gd_process_date           -- �Ɩ����t
        , lt_gl_batch_id_mta        -- GL�o�b�`ID
        , cv_flag_n                 -- �����σt���O
        , cn_created_by             -- �쐬��
        , cd_creation_date          -- �쐬��
        , cn_last_updated_by        -- �ŏI�X�V��
        , cd_last_update_date       -- �ŏI�X�V��
        , cn_last_update_login      -- �ŏI�X�V���O�C��
        , cn_request_id             -- �v��ID
        , cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id             -- �R���J�����g�E�v���O����ID
        , cd_program_update_date    -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                   , iv_name         => cv_msg_cfo_00024 -- ���b�Z�[�W�R�[�h
                                                   , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- �g�[�N���l1
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
  END ins_upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_wait_coop
   * Description      : ���A�g�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_inv_wait_coop(
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_wait_coop'; -- �v���O������
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
    FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_inventory_wait_coop xiwc
        WHERE       xiwc.rowid = g_inv_wait_coop_tab( i ).xiwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- �A�v���P�[�V�����Z�k��
                                                       , iv_name         => cv_msg_cfo_00025 -- ���b�Z�[�W�R�[�h
                                                       , iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                                                       , iv_token_value1 => cv_msg_cfo_11025 -- �g�[�N���l1
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
  END del_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn   IN  VARCHAR2,      --   �ǉ��X�V�敪
    iv_file_name     IN  VARCHAR2,      --   �t�@�C����
    iv_tran_id_from  IN  VARCHAR2,      --   ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2,      --   ���ގ��TO�iTo�j
    iv_batch_id_from IN  VARCHAR2,      --   GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2,      --   GL�o�b�`ID�iTo�j
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
      , iv_tran_id_from     -- ���ގ��ID�iFrom�j
      , iv_tran_id_to       -- ���ގ��ID�iTo�j
      , iv_batch_id_from    -- GL�o�b�`ID�iFrom�j
      , iv_batch_id_to      -- GL�o�b�`ID�iTo�j
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
    get_inv_wait_coop(
        iv_ins_upd_kbn      -- �ǉ��X�V�敪
      , iv_tran_id_from     -- ���ގ��ID�iFrom�j
      , iv_tran_id_to       -- ���ގ��ID�iTo�j
      , iv_batch_id_from    -- GL�o�b�`ID�iFrom�j
      , iv_batch_id_to      -- GL�o�b�`ID�iTo�j
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
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_inv_control(
        iv_ins_upd_kbn      -- �ǉ��X�V�敪
      , iv_tran_id_from     -- ���ގ��ID�iFrom�j
      , iv_tran_id_to       -- ���ގ��ID�iTo�j
      , iv_batch_id_from    -- GL�o�b�`ID�iFrom�j
      , iv_batch_id_to      -- GL�o�b�`ID�iTo�j
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
    -- �Ώۃf�[�^�擾(A-4)
    -- ===============================
    get_inv(
        iv_tran_id_from     -- ���ގ��ID�iFrom�j
      , iv_tran_id_to       -- ���ގ��ID�iTo�j
      , iv_batch_id_from    -- GL�o�b�`ID�iFrom�j
      , iv_batch_id_to      -- GL�o�b�`ID�iTo�j
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
      -- ===============================
      -- �Ǘ��e�[�u���o�^�E�X�V����(A-9)
      -- ===============================
      ins_upd_inv_control(
          lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- A-2�Ŗ��A�g�f�[�^�����݂����ꍇ
      IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
        -- ===============================
        -- ���A�g�e�[�u���폜����(A-10)
        -- ===============================
        del_inv_wait_coop(
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
  EXCEPTION
    -- �x���̏ꍇ
    WHEN global_warn_expt THEN
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      -- ���[�v���Ń��b�Z�[�W���o�͂��Ă���ꍇ
      IF ( gv_err_flg IS NOT NULL ) THEN
        ov_errbuf  := NULL;
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
    iv_tran_id_from  IN  VARCHAR2,      --   ���ގ��ID�iFrom�j
    iv_tran_id_to    IN  VARCHAR2,      --   ���ގ��TO�iTo�j
    iv_batch_id_from IN  VARCHAR2,      --   GL�o�b�`ID�iFrom�j
    iv_batch_id_to   IN  VARCHAR2,      --   GL�o�b�`ID�iTo�j
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
      , iv_tran_id_from   -- ���ގ��ID�iFrom�j
      , iv_tran_id_to     -- ���ގ��TO�iTo�j
      , iv_batch_id_from  -- GL�o�b�`ID�iFrom�j
      , iv_batch_id_to    -- GL�o�b�`ID�iTo�j
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
END XXCFO019A09C;
/
