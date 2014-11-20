CREATE OR REPLACE PACKAGE BODY XXCOP003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP003A01C(body)
 * Description      : �A�b�v���[�h�t�@�C������̎捞�i�����Z�b�g�j
 * MD.050           : �A�b�v���[�h�t�@�C������̎捞�i�����Z�b�g�j MD050_COP_003_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            ���b�Z�[�W�o��
 *  check_validate_item    ���ڑ����`�F�b�N
 *  delete_upload_file     �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-7)
 *  exec_api_assignment    �����Z�b�gAPI���s(A-6)
 *  set_assignment_lines   �����Z�b�g���אݒ�(A-5)
 *  set_assignment_header  �����Z�b�g�w�b�_�[�ݒ�(A-4)
 *  check_upload_file_data �Ó����`�F�b�N����(A-3)
 *  get_upload_file_data   �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.0   Y.Goto           �V�K�쐬
 *  2009/02/25    1.1   SCS.Uda          �����e�X�g�d�l�ύX�i������QNo.016,017�j
 *  2009/09/04    1.2   K.Kayahara       �����e�X�g��Q0001297�Ή�
 *  
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ���[�U�[��`��O
  -- ===============================
  lower_rows_expt           EXCEPTION;     -- �f�[�^�Ȃ���O
  failed_api_expt           EXCEPTION;     -- �����Z�b�gAPI���s
  invalid_param_expt        EXCEPTION;     -- ���̓p�����[�^�`�F�b�N��O
--��
  profile_validate_expt     EXCEPTION;     -- �v���t�@�C���Ó����G���[
--��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOP003A01C';          -- �p�b�P�[�W��
  --���b�Z�[�W����
  gv_msg_appl_cont CONSTANT VARCHAR2(100) := 'XXCOP';                 -- �A�v���P�[�V�����Z�k��
  --����
  gv_lang          CONSTANT VARCHAR2(100) := USERENV('LANG');
  --�v���O�������s�N����
  gd_sysdate       CONSTANT DATE := TRUNC(SYSDATE);                   -- �V�X�e�����t�i�N�����j
  --���b�Z�[�W��
--��
  gv_msg_00002     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- �v���t�@�C���l�擾���s
--��
  gv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- �Ώۃf�[�^����
  gv_msg_00005     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';      -- �p�����[�^�G���[���b�Z�[�W
  gv_msg_00016     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016';      -- API�N���G���[
  gv_msg_00017     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00017';      -- �}�X�^���o�^�G���[
  gv_msg_00018     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00018';      -- �s���`�F�b�N�G���[
  gv_msg_00019     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00019';      -- �֎~���ڐݒ�G���[
  gv_msg_00020     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00020';      -- NUMBER�^�`�F�b�N�G���[
  gv_msg_00021     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00021';      -- DATE�^�`�F�b�N�G���[
  gv_msg_00022     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00022';      -- �T�C�Y�`�F�b�N�G���[
  gv_msg_00023     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00023';      -- �K�{���̓G���[
  gv_msg_00024     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00024';      -- �t�H�[�}�b�g�`�F�b�N�G���[
  gv_msg_00032     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00032';      -- �A�b�v���[�hIF���擾�G���[���b�Z�[�W
  gv_msg_00033     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';      -- �t�@�C�����o�̓��b�Z�[�W
  gv_msg_00036     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';      -- �A�b�v���[�h�t�@�C���o�̓��b�Z�[�W
  gv_msg_00040     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';      -- ��Ӑ��`�F�b�N�G���[
  gv_msg_10029     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10029';      -- �폜�f�[�^���݂Ȃ��G���[���b�Z�[�W
  
  --���b�Z�[�W�g�[�N��
--��
  gv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
--��
  gv_msg_00005_token_1      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_msg_00005_token_2      CONSTANT VARCHAR2(100) := 'VALUE';
  gv_msg_00016_token_1      CONSTANT VARCHAR2(100) := 'PRG_NAME';
  gv_msg_00016_token_2      CONSTANT VARCHAR2(100) := 'ERR_MSG';
  gv_msg_00017_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00017_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00017_token_3      CONSTANT VARCHAR2(100) := 'VALUE1';
  gv_msg_00017_token_4      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00017_token_5      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00018_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00018_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00018_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00019_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00019_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00019_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00020_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00020_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00020_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00021_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00021_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00021_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00022_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00022_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00022_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00023_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00023_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00023_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00024_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00024_token_2      CONSTANT VARCHAR2(100) := 'FILE';
  gv_msg_00024_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00032_token_1      CONSTANT VARCHAR2(100) := 'FILEID';
  gv_msg_00032_token_2      CONSTANT VARCHAR2(100) := 'FORMAT';
  gv_msg_00033_token_1      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00036_token_1      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_2      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_msg_00036_token_3      CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_msg_00036_token_4      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00040_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00040_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00040_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_10029_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_10029_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  --���b�Z�[�W�g�[�N���l
  gv_msg_00016_value_1      CONSTANT VARCHAR2(100) := '�����Z�b�gAPI';          -- API��
  gv_msg_00024_value_2      CONSTANT VARCHAR2(100) := 'CSV�t�@�C��';            -- �t�@�C����
  gv_msg_table_flv          CONSTANT VARCHAR2(100) := '�N�C�b�N�R�[�h';         -- FND_LOOKUP_VALEUS
  gv_msg_table_mp           CONSTANT VARCHAR2(100) := '�g�D�p�����[�^';         -- MTL_PARAMETERS
  gv_msg_table_msib         CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^';             -- MTL_SYSTEM_ITEMS_B
  gv_msg_table_msr          CONSTANT VARCHAR2(100) := '�����\���\';             -- MRP_SOURCING_RULES
  gv_msg_param_file_id      CONSTANT VARCHAR2(100) := 'FILE_ID';                -- ���̓p�����[�^.�t�@�C��ID
  gv_msg_param_format       CONSTANT VARCHAR2(100) := '�t�H�[�}�b�g�p�^�[��';   -- ���̓p�����[�^.�t�H�[�}�b�g�p�^�[��
  gv_msg_comma              CONSTANT VARCHAR2(100) := ',';                      -- ���ڋ�؂�
---------------------------------------------------------
  --�t�@�C���A�b�v���[�hI/F�e�[�u��
  gv_format_pattern         CONSTANT VARCHAR2(3)   := '220';                    -- �t�H�[�}�b�g�p�^�[��
  gv_delim                  CONSTANT VARCHAR2(1)   := ',';                      -- �f���~�^����
-- 0001297 2009/09/04 MOD START
  --gn_column_num             CONSTANT NUMBER        := 27;                       -- ���ڐ�
  gn_column_num             CONSTANT NUMBER        := 28;                       -- ���ڐ�
-- 0001297 2009/09/04 MOD END 
  gn_header_row_num         CONSTANT NUMBER        := 1;                        -- �w�b�_�[�s��
  --���ڂ̓��{�ꖼ��
  gv_column_name_01         CONSTANT VARCHAR2(100) := '�����Z�b�g��';
  gv_column_name_02         CONSTANT VARCHAR2(100) := '�����Z�b�g�E�v';
  gv_column_name_03         CONSTANT VARCHAR2(100) := '�����Z�b�g�敪';
  gv_column_name_04         CONSTANT VARCHAR2(100) := '������^�C�v';
  gv_column_name_05         CONSTANT VARCHAR2(100) := '�g�D�R�[�h';
  gv_column_name_06         CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
  gv_column_name_07         CONSTANT VARCHAR2(100) := '�����\���\/�\�[�X���[���^�C�v';
  gv_column_name_08         CONSTANT VARCHAR2(100) := '�����\���\/�\�[�X���[���^�C�v��';
  gv_column_name_09         CONSTANT VARCHAR2(100) := '�폜�t���O';
  gv_column_name_10         CONSTANT VARCHAR2(100) := '�o�׋敪';
  gv_column_name_11         CONSTANT VARCHAR2(100) := '�N�x����';
  gv_column_name_12         CONSTANT VARCHAR2(100) := '�݌Ɉێ�����';
  gv_column_name_13         CONSTANT VARCHAR2(100) := '�ő�݌ɓ���';
  gv_column_name_23         CONSTANT VARCHAR2(100) := '�J�n�����N����';
  gv_column_name_24         CONSTANT VARCHAR2(100) := '�L���J�n��';
  gv_column_name_25         CONSTANT VARCHAR2(100) := '�L���I����';
  gv_column_name_26         CONSTANT VARCHAR2(100) := '�ݒ萔��';
  gv_column_name_27         CONSTANT VARCHAR2(100) := '�ړ���';
  --���ڂ̃T�C�Y
  gv_column_len_01          CONSTANT NUMBER := 30;                              -- �����Z�b�g��
  gv_column_len_02          CONSTANT NUMBER := 80;                              -- �����Z�b�g�E�v
  gv_column_len_03          CONSTANT NUMBER := 1;                               -- �����Z�b�g�敪
  gv_column_len_04          CONSTANT NUMBER := 1;                               -- ������^�C�v
  gv_column_len_05          CONSTANT NUMBER := 3;                               -- �g�D�R�[�h
  gv_column_len_06          CONSTANT NUMBER := 7;                               -- �i�ڃR�[�h
  gv_column_len_07          CONSTANT NUMBER := 1;                               -- �����\���\/�\�[�X���[���^�C�v
  gv_column_len_08          CONSTANT NUMBER := 30;                              -- �����\���\/�\�[�X���[���^�C�v��
  gv_column_len_09          CONSTANT NUMBER := 1;                               -- �폜�t���O
  gv_column_len_10          CONSTANT NUMBER := 1;                               -- �o�׋敪
  gv_column_len_11          CONSTANT NUMBER := 2;                               -- �N�x����
  --�K�{����
  gv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- �K�{����
  gv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL����
  gv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- �C�Ӎ���
  --���t�^�t�H�[�}�b�g
  gv_ymd_format             CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- �N����
  gv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- �N����
  gv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- �N���������b(24���ԕ\�L)
  --�����Z�b�g�敪
  gv_base_plan              CONSTANT VARCHAR2(1)   := 1;                        -- ��{�����v��
  gv_custom_plan            CONSTANT VARCHAR2(1)   := 2;                        -- ���ʉ����v��
  gv_factory_ship_plan      CONSTANT VARCHAR2(1)   := 3;                        -- �H��o�׌v��
  --������^�C�v
  gv_global                 CONSTANT NUMBER        := 1;                        -- �O���[�o��
  gv_item                   CONSTANT NUMBER        := 3;                        -- �i��
  gv_organization           CONSTANT NUMBER        := 4;                        -- �g�D
  gv_item_organization      CONSTANT NUMBER        := 6;                        -- �i��-�g�D
  --�\�[�X���[���^�C�v
  gv_source_rule            CONSTANT NUMBER        := 1;                        -- �\�[�X���[��
  gv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- �����\���\
  --�폜�t���O
  gv_db_flag                CONSTANT NUMBER        := '1';                      -- ON
  --�N�C�b�N�R�[�h�^�C�v
  gv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';                 -- �����Z�b�g��
  gv_flv_assignment_type    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_TYPE';                 -- �����Z�b�g�敪
  gv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';            -- ������^�C�v
  gv_flv_ship_type          CONSTANT VARCHAR2(100) := 'XXCOP1_SHIP_TYPE';                       -- �o�׋敪
  gv_flv_sendo              CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';              -- �N�x����
  gv_enable                 CONSTANT VARCHAR2(100) := 'Y';                                      -- �L��
  --�i�ڃ}�X�^
  gv_item_status            CONSTANT VARCHAR2(100) := 'Inactive';                               -- ����
--��
--  gn_master_org_id          CONSTANT NUMBER        := fnd_profile.value('XXCMN_MASTER_ORG_ID'); -- �}�X�^�[�݌ɑg�D
  gn_master_org_id          NUMBER;                                              -- �}�X�^�[�݌ɑg�D
  gv_profile_master_org_id  CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';     -- �}�X�^�g�DID
  gv_profile_name_m_org_id  CONSTANT VARCHAR2(100) := 'XXCMN:�}�X�^�g�D';        -- �}�X�^�g�DID
--��
  --API�萔
  gv_operation_create       CONSTANT VARCHAR2(6)   := 'CREATE';                 -- �o�^
  gv_operation_update       CONSTANT VARCHAR2(6)   := 'UPDATE';                 -- �X�V
  gv_operation_delete       CONSTANT VARCHAR2(6)   := 'DELETE';                 -- �폜
  gv_api_version            CONSTANT VARCHAR2(4)   := '1.0';                    -- �o�[�W����
  gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';                      -- �G���[���b�Z�[�W�G���R�[�h
  --���b�Z�[�W�o��
  gv_blank                  CONSTANT VARCHAR2(5)   := 'BLANK';                   -- �󔒍s
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�N�x�������R�[�h�^
  TYPE g_freshness_condition_rtype IS RECORD (
    freshness_condition     VARCHAR2(2)
  , stock_hold_days         NUMBER
  , max_stock_days          NUMBER
  );
  --�N�x�����R���N�V�����^
  TYPE g_fc_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
  --�����Z�b�g���R�[�h�^
  TYPE g_assignment_set_data_rtype IS RECORD (
  --CSV����
    assignment_set_name     mrp_assignment_sets.assignment_set_name%TYPE
  , assignment_set_desc     mrp_assignment_sets.description%TYPE
  , assignment_set_class    VARCHAR2(1)
  , assignment_type         mrp_sr_assignments.assignment_type%TYPE
  , organization_code       mtl_parameters.organization_code%TYPE
  , inventory_item_code     mtl_system_items_b.segment1%TYPE
  , sourcing_rule_type      mrp_sr_assignments.sourcing_rule_type%TYPE
  , sourcing_rule_name      mrp_sourcing_rules.sourcing_rule_name%TYPE
  , db_flag                 VARCHAR2(1)
  , ship_type               NUMBER(1)
  , fc_tab                  g_fc_ttype
  , start_manufacture_date  DATE
  , start_date_active       DATE
  , end_date_active         DATE
  , setting_quantity        NUMBER
  , move_quantity           NUMBER
  --�擾����
  , assignment_set_id       mrp_assignment_sets.assignment_set_id%TYPE
  , organization_id         mrp_sr_assignments.organization_id%TYPE
  , inventory_item_id       mrp_sr_assignments.inventory_item_id%TYPE
  );
  --�����Z�b�g�R���N�V�����^
  TYPE g_assignment_set_data_ttype IS TABLE OF g_assignment_set_data_rtype
    INDEX BY BINARY_INTEGER;
  TYPE g_file_data_ttype  IS TABLE OF VARCHAR2(32767)
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_debug_mode             VARCHAR2(256);
--
  /**********************************************************************************
   * Procedure Name   : output_disp
   * Description      : ���b�Z�[�W�o��
   ***********************************************************************************/
  PROCEDURE output_disp(
    iv_errmsg     IN OUT VARCHAR2,     -- 1.���|�[�g�o�̓��b�Z�[�W
    iv_errbuf     IN OUT VARCHAR2      -- 2.���O�o�̓��b�Z�[�W
  )
  IS
  BEGIN
      --���|�[�g�o��
      IF ( iv_errmsg IS NOT NULL ) THEN
        IF ( iv_errmsg = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => iv_errmsg
          );
        END IF;
      END IF;
      --���O�o��
      IF ( iv_errbuf IS NOT NULL ) THEN
        IF ( iv_errbuf = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => iv_errbuf
          );
        END IF;
      END IF;
      --�o�̓��b�Z�[�W�̃N���A
      iv_errmsg := NULL;
      iv_errbuf := NULL;
  END output_disp;
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : ���ڑ����`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    iv_item_name  IN  VARCHAR2,     -- 1.���ږ��i���{��j
    iv_item_value IN  VARCHAR2,     -- 2.���ڒl
    iv_null       IN  VARCHAR2,     -- 3.�K�{�`�F�b�N
    iv_number     IN  VARCHAR2,     -- 4.NUMBER�^�`�F�b�N
    iv_date       IN  VARCHAR2,     -- 5.DATE�^�`�F�b�N
    in_item_size  IN  NUMBER,       -- 6.���ڃT�C�Y�iBYTE�j
    in_row_num    IN  NUMBER,       -- 7.�s
    iv_file_data  IN  VARCHAR2,     -- 8.�擾���R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_validate_item'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�K�{�`�F�b�N
    IF ( iv_null = gv_must_item ) THEN
      IF( iv_item_value IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00023
                       ,iv_token_name1  => gv_msg_00023_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00023_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00023_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSIF ( iv_null = gv_null_item ) THEN
      IF ( iv_item_value IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00019
                       ,iv_token_name1  => gv_msg_00019_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00019_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00019_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSE
      NULL;
    END IF;
    --NUMBER�^�`�F�b�N
    IF ( ( iv_number IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_number_format( iv_item_value ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00020
                       ,iv_token_name1  => gv_msg_00020_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00020_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00020_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --DATE�^�`�F�b�N
    IF ( ( iv_date IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_date_format( iv_item_value,iv_date ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00021
                       ,iv_token_name1  => gv_msg_00021_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00021_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00021_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --�T�C�Y�`�F�b�N
    IF ( ( in_item_size IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( LENGTHB(iv_item_value) > in_item_size ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00022
                       ,iv_token_name1  => gv_msg_00022_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00022_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00022_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : delete_upload_file
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_upload_file(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_file'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
    xxcop_common_pkg.delete_upload_table(
       ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,in_file_id   => in_file_id         -- �t�@�C��ID
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_upload_file;
--
  /**********************************************************************************
   * Procedure Name   : exec_api_assignment
   * Description      : �����Z�b�gAPI���s(A-6)
   ***********************************************************************************/
  PROCEDURE exec_api_assignment(
    i_mas_rec     IN  MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type, -- 1.�����Z�b�g�w�b�_�[
    i_msa_tab     IN  MRP_Src_Assignment_PUB.Assignment_Tbl_Type,     -- 2.�����Z�b�g����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_assignment'; -- �v���O������
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
    lv_return_status     VARCHAR2(1);
    ln_msg_count         NUMBER;
    lv_msg_data          VARCHAR2(3000);
    ln_msg_index_out     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_mas_val_rec                     MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
    l_msa_val_tab                     MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
    l_out_mas_rec                     MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;
    l_out_msa_tab                     MRP_Src_Assignment_PUB.Assignment_Tbl_Type;
    l_out_mas_val_rec                 MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
    l_out_msa_val_tab                 MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�f�o�b�N���b�Z�[�W�i�����Z�b�g�w�b�_�[���R�[�h�^�j
    xxcop_common_pkg.put_debug_message('assignment_set:-',gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation          :'||i_mas_rec.operation            ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_name:'||i_mas_rec.assignment_set_name  ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>description        :'||i_mas_rec.description          ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1         :'||i_mas_rec.attribute1           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_id  :'||i_mas_rec.assignment_set_id    ,gv_debug_mode);
    --�f�o�b�N���b�Z�[�W�i�����Z�b�g���׃R���N�V�����^�j
    xxcop_common_pkg.put_debug_message('sr_assignment:'||i_msa_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation          :'||i_msa_tab(1).operation         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_id  :'||i_msa_tab(1).assignment_set_id ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_id      :'||i_msa_tab(1).assignment_id     ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_type    :'||i_msa_tab(1).assignment_type   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>inventory_item_id  :'||i_msa_tab(1).inventory_item_id ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>organization_id    :'||i_msa_tab(1).organization_id   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_type :'||i_msa_tab(1).sourcing_rule_type,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute_category :'||i_msa_tab(1).attribute_category,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1         :'||i_msa_tab(1).attribute1        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute2         :'||i_msa_tab(1).attribute2        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute3         :'||i_msa_tab(1).attribute3        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute4         :'||i_msa_tab(1).attribute4        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute5         :'||i_msa_tab(1).attribute5        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute6         :'||i_msa_tab(1).attribute6        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute7         :'||i_msa_tab(1).attribute7        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute8         :'||i_msa_tab(1).attribute8        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute9         :'||i_msa_tab(1).attribute9        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute10        :'||i_msa_tab(1).attribute10       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute11        :'||i_msa_tab(1).attribute11       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute12        :'||i_msa_tab(1).attribute12       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute13        :'||i_msa_tab(1).attribute13       ,gv_debug_mode);
    --�����Z�b�gAPI���s
    mrp_src_assignment_pub.process_assignment(
       p_api_version_number          => gv_api_version
      ,p_init_msg_list               => FND_API.G_TRUE
      ,p_return_values               => FND_API.G_TRUE
      ,p_commit                      => FND_API.G_FALSE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_Assignment_Set_rec          => i_mas_rec
      ,p_Assignment_Set_val_rec      => l_mas_val_rec
      ,p_Assignment_tbl              => i_msa_tab
      ,p_Assignment_val_tbl          => l_msa_val_tab
      ,x_Assignment_Set_rec          => l_out_mas_rec
      ,x_Assignment_Set_val_rec      => l_out_mas_val_rec
      ,x_Assignment_tbl              => l_out_msa_tab
      ,x_Assignment_val_tbl          => l_out_msa_val_tab
    );
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      --API�G���[���b�Z�[�W�̃Z�b�g
      IF ( ln_msg_count = 1 ) THEN
        lv_errmsg := lv_msg_data;
      ELSE
        <<errmsg_loop>>
        FOR ln_err_idx IN 1 .. ln_msg_count LOOP
          fnd_msg_pub.get(
             p_msg_index     => ln_err_idx
            ,p_encoded       => gv_msg_encoded
            ,p_data          => lv_msg_data
            ,p_msg_index_out => ln_msg_index_out
          );
          lv_errmsg := lv_errmsg || lv_msg_data || CHR(10) ;
        END LOOP errmsg_loop;
      END IF;
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_return_status:' || lv_return_status,gv_debug_mode);
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_msg_count    :' || ln_msg_count    ,gv_debug_mode);
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_msg_data     :' || lv_errmsg       ,gv_debug_mode);
      RAISE failed_api_expt;
    END IF;
--
  EXCEPTION
    WHEN failed_api_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00016
                     ,iv_token_name1  => gv_msg_00016_token_1
                     ,iv_token_value1 => gv_msg_00016_value_1
                     ,iv_token_name2  => gv_msg_00016_token_2
                     ,iv_token_value2 => lv_errmsg
                   );
      ov_retcode := gv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exec_api_assignment;
--
  /**********************************************************************************
   * Procedure Name   : set_assignment_lines
   * Description      : �����Z�b�g���אݒ�(A-5)
   ***********************************************************************************/
  PROCEDURE set_assignment_lines(
    i_asd_rec     IN  g_assignment_set_data_rtype,                    -- 1.�����Z�b�g�f�[�^
    o_msa_tab     OUT MRP_Src_Assignment_PUB.Assignment_Tbl_Type,     -- 2.�����Z�b�g����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment_lines'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�����\���\����\�[�X���[��ID�̎擾
    SELECT msr.sourcing_rule_id   sourcing_rule_id
    INTO   o_msa_tab(1).sourcing_rule_id
    FROM   mrp_sourcing_rules msr
    WHERE  msr.sourcing_rule_name         = i_asd_rec.sourcing_rule_name
      AND  msr.sourcing_rule_type         = i_asd_rec.sourcing_rule_type
      AND  ( msr.organization_id          = i_asd_rec.organization_id
        OR   i_asd_rec.organization_id IS NULL
        OR   msr.organization_id IS NULL );
    --�����Z�b�g���ׂ̊����f�[�^�`�F�b�N
    BEGIN
      SELECT msa.assignment_id   assignment_id
      INTO   o_msa_tab(1).assignment_id
      FROM   mrp_sr_assignments msa
      WHERE  msa.assignment_type          = i_asd_rec.assignment_type
        AND  msa.sourcing_rule_type       = i_asd_rec.sourcing_rule_type
        AND  msa.assignment_set_id        = i_asd_rec.assignment_set_id
        AND  msa.sourcing_rule_id         = o_msa_tab(1).sourcing_rule_id
        AND  ( msa.organization_id        = i_asd_rec.organization_id
          OR   i_asd_rec.organization_id IS NULL )
        AND  ( msa.inventory_item_id      = i_asd_rec.inventory_item_id
          OR   i_asd_rec.inventory_item_id IS NULL );
      --�����f�[�^������ꍇ
      IF ( i_asd_rec.db_flag = gv_db_flag ) THEN
        --�폜�t���O��ON�̏ꍇ�͍폜
        o_msa_tab(1).operation           := gv_operation_delete;
      ELSE
        --�폜�t���O��OFF�̏ꍇ�͍X�V
        o_msa_tab(1).operation           := gv_operation_update;
      END IF;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_assignments_s.NEXTVAL
        INTO   o_msa_tab(1).assignment_id
        FROM   DUAL;
        o_msa_tab(1).operation           := gv_operation_create;
        o_msa_tab(1).created_by          := gn_created_by;
        o_msa_tab(1).creation_date       := gd_creation_date;
    END;
--
    --�����Z�b�gAPI�W���R���N�V�����^�ɒl���Z�b�g
    o_msa_tab(1).assignment_set_id       := i_asd_rec.assignment_set_id;
    o_msa_tab(1).assignment_type         := i_asd_rec.assignment_type;
    o_msa_tab(1).inventory_item_id       := i_asd_rec.inventory_item_id;
    o_msa_tab(1).organization_id         := i_asd_rec.organization_id;
    o_msa_tab(1).sourcing_rule_type      := i_asd_rec.sourcing_rule_type;
    o_msa_tab(1).last_updated_by         := gn_last_updated_by;
    o_msa_tab(1).last_update_date        := gd_last_update_date;
    o_msa_tab(1).last_update_login       := gn_last_update_login;
    o_msa_tab(1).program_application_id  := gn_program_application_id;
    o_msa_tab(1).program_id              := gn_program_id;
    o_msa_tab(1).program_update_date     := gd_program_update_date;
    o_msa_tab(1).request_id              := gn_request_id;
    o_msa_tab(1).attribute_category      := i_asd_rec.assignment_set_class;
    --�����Z�b�g�敪�ɂ��Z�b�g����l��؂�ւ���B
    IF ( i_asd_rec.assignment_set_class IN ( gv_base_plan
                                            ,gv_factory_ship_plan ) )
    THEN
      o_msa_tab(1).attribute1   := TO_CHAR(i_asd_rec.ship_type);
      o_msa_tab(1).attribute2   := i_asd_rec.fc_tab(0).freshness_condition;
      o_msa_tab(1).attribute3   := TO_CHAR(i_asd_rec.fc_tab(0).stock_hold_days);
      o_msa_tab(1).attribute4   := TO_CHAR(i_asd_rec.fc_tab(0).max_stock_days);
      o_msa_tab(1).attribute5   := i_asd_rec.fc_tab(1).freshness_condition;
      o_msa_tab(1).attribute6   := TO_CHAR(i_asd_rec.fc_tab(1).stock_hold_days);
      o_msa_tab(1).attribute7   := TO_CHAR(i_asd_rec.fc_tab(1).max_stock_days);
      o_msa_tab(1).attribute8   := i_asd_rec.fc_tab(2).freshness_condition;
      o_msa_tab(1).attribute9   := TO_CHAR(i_asd_rec.fc_tab(2).stock_hold_days);
      o_msa_tab(1).attribute10  := TO_CHAR(i_asd_rec.fc_tab(2).max_stock_days);
      o_msa_tab(1).attribute11  := i_asd_rec.fc_tab(3).freshness_condition;
      o_msa_tab(1).attribute12  := TO_CHAR(i_asd_rec.fc_tab(3).stock_hold_days);
      o_msa_tab(1).attribute13  := TO_CHAR(i_asd_rec.fc_tab(3).max_stock_days);
      o_msa_tab(1).attribute14  := NULL;
      o_msa_tab(1).attribute15  := NULL;
    ELSE
      o_msa_tab(1).attribute1   := TO_CHAR(i_asd_rec.start_manufacture_date,gv_date_format);
      o_msa_tab(1).attribute2   := TO_CHAR(i_asd_rec.start_date_active,gv_date_format);
      o_msa_tab(1).attribute3   := TO_CHAR(i_asd_rec.end_date_active,gv_date_format);
      o_msa_tab(1).attribute4   := TO_CHAR(i_asd_rec.setting_quantity);
      o_msa_tab(1).attribute5   := TO_CHAR(i_asd_rec.move_quantity);
      o_msa_tab(1).attribute6   := NULL;
      o_msa_tab(1).attribute7   := NULL;
      o_msa_tab(1).attribute8   := NULL;
      o_msa_tab(1).attribute9   := NULL;
      o_msa_tab(1).attribute10  := NULL;
      o_msa_tab(1).attribute11  := NULL;
      o_msa_tab(1).attribute12  := NULL;
      o_msa_tab(1).attribute13  := NULL;
      o_msa_tab(1).attribute14  := NULL;
      o_msa_tab(1).attribute15  := NULL;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_assignment_lines;
--
  /**********************************************************************************
   * Procedure Name   : set_assignment_header
   * Description      : �����Z�b�g�w�b�_�[�ݒ�(A-4)
   ***********************************************************************************/
  PROCEDURE set_assignment_header(
    io_asd_rec    IN OUT g_assignment_set_data_rtype,                    -- 1.�����Z�b�g�f�[�^
    o_mas_rec     OUT    MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type, -- 2.�����Z�b�g�w�b�_�[
    ov_errbuf     OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment_header'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�����Z�b�g�w�b�_�[�̊����f�[�^�`�F�b�N
    BEGIN
      SELECT mas.assignment_set_id   assignment_set_id
      INTO   o_mas_rec.assignment_set_id
      FROM   mrp_assignment_sets mas
      WHERE  mas.assignment_set_name   = io_asd_rec.assignment_set_name;
      --�����f�[�^������ꍇ
      o_mas_rec.operation             := gv_operation_update;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_assignment_sets_s.NEXTVAL
        INTO   o_mas_rec.assignment_set_id
        FROM   DUAL;
        o_mas_rec.operation               := gv_operation_create;
        o_mas_rec.created_by              := gn_created_by;
        o_mas_rec.creation_date           := gd_creation_date;
    END;
--
    --�����Z�b�gAPI�W�����R�[�h�^�ɒl���Z�b�g
    o_mas_rec.assignment_set_name     := io_asd_rec.assignment_set_name;
    o_mas_rec.description             := io_asd_rec.assignment_set_desc;
    o_mas_rec.attribute1              := io_asd_rec.assignment_set_class;
    o_mas_rec.last_updated_by         := gn_last_updated_by;
    o_mas_rec.last_update_date        := gd_last_update_date;
    o_mas_rec.last_update_login       := gn_last_update_login;
    o_mas_rec.program_application_id  := gn_program_application_id;
    o_mas_rec.program_id              := gn_program_id;
    o_mas_rec.program_update_date     := gd_program_update_date;
    o_mas_rec.request_id              := gn_request_id;
--
    --�����Z�b�g�w�b�_�[ID�������Z�b�g�f�[�^�ɃZ�b�g
    io_asd_rec.assignment_set_id      := o_mas_rec.assignment_set_id;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_assignment_header;
--
  /**********************************************************************************
   * Procedure Name   : check_upload_file_data
   * Description      : �Ó����`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE check_upload_file_data(
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- 1.�t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
    o_asd_tab     OUT g_assignment_set_data_ttype,        -- 2.�����Z�b�g�f�[�^
    ov_errbuf     OUT VARCHAR2,                        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_upload_file_data'; -- �v���O������
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
    l_csv_tab                 xxcop_common_pkg.g_char_ttype;
    ln_invalid_flag           VARCHAR2(1);
    ln_exists                 NUMBER;
    ln_asd_idx                NUMBER;
    lv_column_name            VARCHAR2(50);
    lv_column_length          NUMBER;
    lv_column_value           VARCHAR2(256);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    <<row_loop>>
    FOR ln_row_idx IN ( i_fuid_tab.FIRST + gn_header_row_num ) .. i_fuid_tab.COUNT LOOP
      --���[�v���Ŏg�p����ϐ��̏�����
      ln_invalid_flag := gv_status_normal;
      ln_asd_idx      := ln_row_idx - gn_header_row_num;
      --CSV��������
      xxcop_common_pkg.char_delim_partition(
         ov_retcode   => lv_retcode              -- ���^�[���R�[�h
        ,ov_errbuf    => lv_errbuf               -- �G���[�E���b�Z�[�W
        ,ov_errmsg    => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,iv_char      => i_fuid_tab(ln_row_idx)  -- �Ώە�����
        ,iv_delim     => gv_delim                -- �f���~�^
        ,o_char_tab   => l_csv_tab               -- ��������
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --���R�[�h�̑Ó����`�F�b�N
      IF ( l_csv_tab.COUNT = gn_column_num ) THEN
      --�����f�o�b�Ostart
    fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => l_csv_tab.COUNT
      );
--�����f�o�b�Oend
        --���ږ��̑Ó����`�F�b�N
        --�����Z�b�g��
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_name := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
          --�����Z�b�g���`�F�b�N
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assignment_name
            AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).assignment_set_name
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_01
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_set_name
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�����Z�b�g�E�v
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_desc := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�����Z�b�g�敪
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_class := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
          --�����Z�b�g�敪�`�F�b�N
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assignment_type
            AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).assignment_set_class
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_03
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_set_class
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --������^�C�v
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_04
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_type := TO_NUMBER(l_csv_tab(4));
          --������^�C�v�s���`�F�b�N
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assign_priority
            AND  flv.lookup_code  = TO_CHAR(o_asd_tab(ln_asd_idx).assignment_type)
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_04
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_type
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          IF ( o_asd_tab(ln_asd_idx).assignment_set_class = gv_custom_plan ) THEN
            IF ( o_asd_tab(ln_asd_idx).assignment_type <> gv_item_organization ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00018
                             ,iv_token_name1  => gv_msg_00018_token_1
                             ,iv_token_value1 => ln_asd_idx
                             ,iv_token_name2  => gv_msg_00018_token_2
                             ,iv_token_value2 => gv_column_name_04
                             ,iv_token_name3  => gv_msg_00018_token_3
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�g�D�R�[�h
        IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_organization
                                                       ,gv_item_organization ) )
        THEN
          check_validate_item(
             iv_item_name   => gv_column_name_05
            ,iv_item_value  => l_csv_tab(5)
            ,iv_null        => gv_must_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_05
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).organization_code := SUBSTRB(l_csv_tab(5),1,gv_column_len_05);
            --�g�D�}�X�^�`�F�b�N
            BEGIN
              SELECT mp.organization_id   organization_id
              INTO   o_asd_tab(ln_asd_idx).organization_id
              FROM   mtl_parameters mp
              WHERE  mp.organization_code = o_asd_tab(ln_asd_idx).organization_code;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_05
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).organization_code
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_mp
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
            END;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        ELSE
          check_validate_item(
             iv_item_name   => gv_column_name_05
            ,iv_item_value  => l_csv_tab(5)
            ,iv_null        => gv_null_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).organization_code := NULL;
            o_asd_tab(ln_asd_idx).organization_id   := NULL;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --�i�ڃR�[�h
        IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_item
                                                       ,gv_item_organization) )
        THEN
          check_validate_item(
             iv_item_name   => gv_column_name_06
            ,iv_item_value  => l_csv_tab(6)
            ,iv_null        => gv_must_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_06
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).inventory_item_code := SUBSTRB(l_csv_tab(6),1,gv_column_len_06);
            BEGIN
              --�i�ڃ}�X�^�`�F�b�N
              SELECT msib.inventory_item_id   inventory_item_id
              INTO   o_asd_tab(ln_asd_idx).inventory_item_id
              FROM   mtl_system_items_b msib
              WHERE  msib.segment1                    = o_asd_tab(ln_asd_idx).inventory_item_code
                AND  msib.organization_id             = gn_master_org_id
                AND  msib.inventory_item_status_code <> gv_item_status;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_06
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).inventory_item_code
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_msib
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
            END;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        ELSE
          check_validate_item(
             iv_item_name   => gv_column_name_06
            ,iv_item_value  => l_csv_tab(6)
            ,iv_null        => gv_null_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).inventory_item_code := NULL;
            o_asd_tab(ln_asd_idx).inventory_item_id   := NULL;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --�����\���\/�\�[�X���[���^�C�v
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).sourcing_rule_type := TO_NUMBER(l_csv_tab(7));
          --�\�[�X���[���^�C�v�s���`�F�b�N
          IF ( o_asd_tab(ln_asd_idx).sourcing_rule_type NOT IN ( gv_source_rule
                                                                ,gv_mrp_sourcing_rule) )
--ver1.1 TE030 ��QNo.017 Del Start SCS.Uda
--          THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => gv_msg_appl_cont
--                           ,iv_name         => gv_msg_00018
--                           ,iv_token_name1  => gv_msg_00018_token_1
--                           ,iv_token_value1 => ln_asd_idx
--                           ,iv_token_name2  => gv_msg_00018_token_2
--                           ,iv_token_value2 => gv_column_name_07
--                           ,iv_token_name3  => gv_msg_00018_token_3
--                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
--                         );
--            output_disp(
--               iv_errmsg  => lv_errmsg
--              ,iv_errbuf  => lv_errbuf
--            );
--            ln_invalid_flag := gv_status_error;
--          ELSE
--            --������^�C�v/�\�[�X���[���^�C�v�s���`�F�b�N
--            IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_global
--                                                           ,gv_item )
--              AND o_asd_tab(ln_asd_idx).sourcing_rule_type <> gv_mrp_sourcing_rule )
--ver1.1 TE030 ��QNo.017 Del End SCS.Uda
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_07
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
--ver1.1 TE030 ��QNo.017 Del Start SCS.Uda
--            END IF;
--            IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_organization
--                                                           ,gv_item_organization )
--              AND o_asd_tab(ln_asd_idx).sourcing_rule_type <> gv_source_rule )
--            THEN
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                              iv_application  => gv_msg_appl_cont
--                             ,iv_name         => gv_msg_00018
--                             ,iv_token_name1  => gv_msg_00018_token_1
--                             ,iv_token_value1 => ln_asd_idx
--                             ,iv_token_name2  => gv_msg_00018_token_2
--                             ,iv_token_value2 => gv_column_name_07
--                             ,iv_token_name3  => gv_msg_00018_token_3
--                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
--                           );
--              output_disp(
--                 iv_errmsg  => lv_errmsg
--                ,iv_errbuf  => lv_errbuf
--              );
--              ln_invalid_flag := gv_status_error;
--            END IF;
--ver1.1 TE030 ��QNo.017 Del End SCS.Uda
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�����\���\/�\�[�X���[���^�C�v��
        check_validate_item(
           iv_item_name   => gv_column_name_08
          ,iv_item_value  => l_csv_tab(8)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_08
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).sourcing_rule_name := SUBSTRB(l_csv_tab(8),1,gv_column_len_08);
          IF ( o_asd_tab(ln_asd_idx).sourcing_rule_type IS NOT NULL ) THEN
            --�����\���\�`�F�b�N
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mrp_sourcing_rules msr
            WHERE  msr.sourcing_rule_name     = o_asd_tab(ln_asd_idx).sourcing_rule_name
              AND  ( ( msr.organization_id    = o_asd_tab(ln_asd_idx).organization_id )
                OR   ( o_asd_tab(ln_asd_idx).organization_id IS NULL ) 
--ver1.1 TE030 ��QNo.016 Add Start SCS.Uda
                OR   (msr.organization_id IS NULL) )
--ver1.1 TE030 ��QNo.016 Add Start SCS.Uda
              AND  msr.sourcing_rule_type     = o_asd_tab(ln_asd_idx).sourcing_rule_type;
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_asd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => o_asd_tab(ln_asd_idx).sourcing_rule_name
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_msr
                             ,iv_token_name5  => gv_msg_00017_token_5
                             ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�폜�t���O
        check_validate_item(
           iv_item_name   => gv_column_name_09
          ,iv_item_value  => l_csv_tab(9)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_09
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).db_flag := SUBSTRB(l_csv_tab(9),1,gv_column_len_09);
          --�폜�t���O�`�F�b�N
          IF ( NVL(o_asd_tab(ln_asd_idx).db_flag,gv_db_flag) NOT IN ( gv_db_flag ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_09
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          --�폜�Ώۃ��R�[�h�̑��݃`�F�b�N
          IF ( o_asd_tab(ln_asd_idx).db_flag IN ( gv_db_flag ) ) THEN
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mrp_sr_assignments  msa
            WHERE  msa.assignment_type          = o_asd_tab(ln_asd_idx).assignment_type
              AND  msa.sourcing_rule_type       = o_asd_tab(ln_asd_idx).sourcing_rule_type
              AND  ( msa.organization_id        = o_asd_tab(ln_asd_idx).organization_id
                OR   o_asd_tab(ln_asd_idx).organization_id    IS NULL )
              AND  ( msa.inventory_item_id      = o_asd_tab(ln_asd_idx).inventory_item_id
                OR   o_asd_tab(ln_asd_idx).inventory_item_id  IS NULL )
              AND EXISTS(
                SELECT 'x'
                FROM  mrp_assignment_sets mas
                WHERE mas.assignment_set_name   = o_asd_tab(ln_asd_idx).assignment_set_name
                  AND mas.assignment_set_id     = msa.assignment_set_id
              )
              AND EXISTS(
                SELECT 'x'
                FROM  mrp_sourcing_rules msr
                WHERE msr.sourcing_rule_name    = o_asd_tab(ln_asd_idx).sourcing_rule_name
                  AND msr.sourcing_rule_type    = o_asd_tab(ln_asd_idx).sourcing_rule_type
                  AND ( msr.organization_id     = o_asd_tab(ln_asd_idx).organization_id
                    OR  o_asd_tab(ln_asd_idx).organization_id IS NULL 
--ver1.1 TE030 ��QNo.016 Add Start SCS.Uda
                    OR   msr.organization_id IS NULL)
--ver1.1 TE030 ��QNo.016 Add End SCS.Uda
                  AND msa.sourcing_rule_id      = msa.sourcing_rule_id
              );
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10029
                              ,iv_token_name1  => gv_msg_10029_token_1
                              ,iv_token_value1 => ln_asd_idx
                              ,iv_token_name2  => gv_msg_10029_token_2
                              ,iv_token_value2 => i_fuid_tab(ln_row_idx)
                            );
              output_disp(
                  iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        IF ( o_asd_tab(ln_asd_idx).assignment_set_class IN ( gv_base_plan
                                                            ,gv_factory_ship_plan ) )
        THEN
          --�o�׋敪
          check_validate_item(
             iv_item_name   => gv_column_name_10
            ,iv_item_value  => l_csv_tab(10)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_10
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).ship_type := TO_NUMBER(l_csv_tab(10));
            IF ( o_asd_tab(ln_asd_idx).ship_type IS NOT NULL ) THEN
              --�敪�`�F�b�N
              SELECT COUNT('x')   row_count
              INTO   ln_exists
              FROM   fnd_lookup_values flv
              WHERE  flv.lookup_type  = gv_flv_ship_type
                AND  flv.lookup_code  = TO_CHAR(o_asd_tab(ln_asd_idx).ship_type)
                AND  flv.language     = gv_lang
                AND  flv.source_lang  = gv_lang
                AND  flv.enabled_flag = gv_enable
                AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                    AND NVL(flv.end_date_active,gd_sysdate);
              IF ( ln_exists = 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_10
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).ship_type
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_flv
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
              END IF;
            END IF;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          <<condition_loop>>
          FOR fc_idx IN 0 .. 3 LOOP
            --�N�x����
            lv_column_name   := gv_column_name_11 || TO_CHAR(fc_idx + 1);
            lv_column_length := gv_column_len_11;
            lv_column_value  := l_csv_tab( 11 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => NULL
              ,iv_date        => NULL
              ,in_item_size   => lv_column_length
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition := SUBSTRB(lv_column_value,1,lv_column_length);
              IF ( o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition IS NOT NULL ) THEN
                --�敪�`�F�b�N
                SELECT COUNT('x')   row_count
                INTO   ln_exists
                FROM   fnd_lookup_values flv
                WHERE  flv.lookup_type  = gv_flv_sendo
                  AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition
                  AND  flv.language     = gv_lang
                  AND  flv.source_lang  = gv_lang
                  AND  flv.enabled_flag = gv_enable
                  AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                      AND NVL(flv.end_date_active,gd_sysdate);
                IF ( ln_exists = 0 ) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => gv_msg_appl_cont
                                 ,iv_name         => gv_msg_00017
                                 ,iv_token_name1  => gv_msg_00017_token_1
                                 ,iv_token_value1 => ln_asd_idx
                                 ,iv_token_name2  => gv_msg_00017_token_2
                                 ,iv_token_value2 => lv_column_name
                                 ,iv_token_name3  => gv_msg_00017_token_3
                                 ,iv_token_value3 => lv_column_value
                                 ,iv_token_name4  => gv_msg_00017_token_4
                                 ,iv_token_value4 => gv_msg_table_flv
                                 ,iv_token_name5  => gv_msg_00017_token_5
                                 ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                               );
                  output_disp(
                     iv_errmsg  => lv_errmsg
                    ,iv_errbuf  => lv_errbuf
                  );
                  ln_invalid_flag := gv_status_error;
                END IF;
              END IF;
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
            --�݌Ɉێ�����
            lv_column_name   := gv_column_name_12 || TO_CHAR(fc_idx + 1);
            lv_column_value  := l_csv_tab( 12 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => gv_any_item
              ,iv_date        => NULL
              ,in_item_size   => NULL
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).stock_hold_days := TO_NUMBER(lv_column_value);
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
            --�ő�݌ɓ���
            lv_column_name   := gv_column_name_13 || TO_CHAR(fc_idx + 1);
            lv_column_value  := l_csv_tab( 13 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => gv_any_item
              ,iv_date        => NULL
              ,in_item_size   => NULL
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).max_stock_days := TO_NUMBER(lv_column_value);
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
          END LOOP condition_loop;
        ELSE
          --�J�n�����N����
          check_validate_item(
             iv_item_name   => gv_column_name_23
            ,iv_item_value  => l_csv_tab(23)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).start_manufacture_date := TO_DATE(l_csv_tab(23),gv_ymd_format);
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --�L���J�n��
          check_validate_item(
             iv_item_name   => gv_column_name_24
            ,iv_item_value  => l_csv_tab(24)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).start_date_active := TO_DATE(l_csv_tab(24),gv_ymd_format);
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --�L���I����
          check_validate_item(
             iv_item_name   => gv_column_name_25
            ,iv_item_value  => l_csv_tab(25)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).end_date_active := TO_DATE(l_csv_tab(25),gv_ymd_format);
          ELSIF (lv_retcode = gv_status_warn) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --�ݒ萔��
          check_validate_item(
             iv_item_name   => gv_column_name_26
            ,iv_item_value  => l_csv_tab(26)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).setting_quantity := TO_NUMBER(l_csv_tab(26));
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --�ړ���
          check_validate_item(
             iv_item_name   => gv_column_name_27
            ,iv_item_value  => l_csv_tab(27)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).move_quantity := TO_NUMBER(l_csv_tab(27));
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --��ӃL�[�`�F�b�N
        <<key_loop>>
        FOR ln_key_idx IN o_asd_tab.first .. ( ln_asd_idx - 1 ) LOOP
          IF (  o_asd_tab(ln_asd_idx).assignment_set_name   = o_asd_tab(ln_key_idx).assignment_set_name
            AND o_asd_tab(ln_asd_idx).assignment_set_class  = o_asd_tab(ln_key_idx).assignment_set_class
            AND o_asd_tab(ln_asd_idx).assignment_type       = o_asd_tab(ln_key_idx).assignment_type
            AND ( o_asd_tab(ln_asd_idx).organization_code   = o_asd_tab(ln_key_idx).organization_code
              OR ( o_asd_tab(ln_asd_idx).organization_code   IS NULL
              AND  o_asd_tab(ln_key_idx).organization_code   IS NULL ) )
            AND ( o_asd_tab(ln_asd_idx).inventory_item_code = o_asd_tab(ln_key_idx).inventory_item_code
              OR ( o_asd_tab(ln_asd_idx).inventory_item_code IS NULL
              AND  o_asd_tab(ln_key_idx).inventory_item_code IS NULL ) )
            AND o_asd_tab(ln_asd_idx).sourcing_rule_type    = o_asd_tab(ln_key_idx).sourcing_rule_type
            AND o_asd_tab(ln_asd_idx).sourcing_rule_name    = o_asd_tab(ln_key_idx).sourcing_rule_name )
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00040
                           ,iv_token_name1  => gv_msg_00040_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00040_token_2
                           ,iv_token_value2 => gv_column_name_01 || gv_msg_comma
                                            || gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_04 || gv_msg_comma
                                            || gv_column_name_05 || gv_msg_comma
                                            || gv_column_name_06 || gv_msg_comma
                                            || gv_column_name_07 || gv_msg_comma
                                            || gv_column_name_08 || gv_msg_comma
                           ,iv_token_name3  => gv_msg_00040_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        END LOOP key_loop;
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00024
                       ,iv_token_name1  => gv_msg_00024_token_1
                       ,iv_token_value1 => ln_asd_idx
                       ,iv_token_name2  => gv_msg_00024_token_2
                       ,iv_token_value2 => gv_msg_00024_value_2
                       ,iv_token_name3  => gv_msg_00024_token_3
                       ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ln_invalid_flag := gv_status_error;
      END IF;
      IF ( ln_invalid_flag = gv_status_error ) THEN
        --�Ó����`�F�b�N�ŃG���[�ƂȂ����ꍇ�A�G���[�������J�E���g�i���R�[�h�P�ʂ�1���J�E���g����j
        gn_error_cnt := gn_error_cnt + 1;
        ov_retcode := gv_status_error;
      END IF;
    END LOOP row_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
    in_file_id    IN  NUMBER,                              -- 1.�t�@�C��ID
    o_fuid_tab    OUT xxccp_common_pkg2.g_file_data_tbl,   -- 2.�t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
    ov_errbuf     OUT VARCHAR2,                 --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                 --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_file_data'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --BLOB�f�[�^�ϊ�
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id         -- �t�@�C��ID
      ,ov_file_data => o_fuid_tab         -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --�f�[�^�����̊m�F
    IF ( o_fuid_tab.COUNT <= gn_header_row_num ) THEN
      RAISE lower_rows_expt;
    END IF;
    --�Ώی�����CSV���R�[�h���|�w�b�_�[�s���ŃZ�b�g
    gn_target_cnt := o_fuid_tab.COUNT - gn_header_row_num;
--
  EXCEPTION
    WHEN lower_rows_expt THEN                                 --*** <��O�R�����g> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00003
                   );
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- �t�@�C���A�b�v���[�h����
    lv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;      -- �t�@�C����
    ld_upload_date       xxccp_mrp_file_ul_interface.creation_date%TYPE;  -- �A�b�v���[�h����
    lv_param_name        VARCHAR2(100);   -- �p�����[�^��
    lv_param_value       VARCHAR2(100);   -- �p�����[�^�l
--��
    lv_profile_name      VARCHAR2(100);   -- �v���t�@�C����
--��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--��
    ---------------------------------------------------
    --  �}�X�^�i�ڑg�D�̎擾
    ---------------------------------------------------
    BEGIN
      gn_master_org_id  :=  TO_NUMBER(fnd_profile.value(gv_profile_master_org_id));
    EXCEPTION
      WHEN OTHERS THEN
        gn_master_org_id  :=  NULL;
    END;
    -- �v���t�@�C���F�}�X�^�i�ڑg�D���擾�o���Ȃ����G���[�ƂȂ�ꍇ
    IF ( gn_master_org_id IS NULL ) THEN
      --�󔒍s��}��
      lv_errmsg := gv_blank;
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
      lv_profile_name := gv_profile_name_m_org_id;
      RAISE profile_validate_expt;
    END IF;
--��

    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾
    xxcop_common_pkg.get_upload_table_info(
       ov_retcode      => lv_retcode      -- ���^�[���R�[�h
      ,ov_errbuf       => lv_errbuf       -- �G���[�o�b�t�@
      ,ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,in_file_id      => in_file_id      -- �t�@�C��ID
      ,iv_format       => iv_format       -- �t�H�[�}�b�g�p�^�[��
      ,ov_upload_name  => lv_upload_name  -- �t�@�C���A�b�v���[�h����
      ,ov_file_name    => lv_file_name    -- �t�@�C����
      ,od_upload_date  => ld_upload_date  -- �A�b�v���[�h����
    );
--
    --�󔒍s��}��
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errbuf
    );
    --�A�b�v���[�h���o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_appl_cont
                   ,iv_name         => gv_msg_00036
                   ,iv_token_name1  => gv_msg_00036_token_1
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_msg_00036_token_2
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_msg_00036_token_3
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_msg_00036_token_4
                   ,iv_token_value4 => lv_file_name
                 );
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --�󔒍s��}��
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾�Ɏ��s�����ꍇ
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
    --���̓p�����[�^.�t�H�[�}�b�g�p�^�[���̑Ó����`�F�b�N
    IF ( iv_format <> gv_format_pattern ) THEN
      lv_param_name := gv_msg_param_format;
      lv_param_value := iv_format;
      RAISE invalid_param_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--��
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00002
                     ,iv_token_name1  => gv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
      ov_retcode := gv_status_error;
--��
    WHEN invalid_param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00005
                     ,iv_token_name1  => gv_msg_00005_token_1
                     ,iv_token_value1 => lv_param_name
                     ,iv_token_name2  => gv_msg_00005_token_2
                     ,iv_token_value2 => lv_param_value
                   );
      ov_retcode := gv_status_error;
    WHEN NO_DATA_FOUND THEN                           --*** <��O�R�����g> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00032
                     ,iv_token_name1  => gv_msg_00032_token_1
                     ,iv_token_value1 => TO_CHAR(in_file_id)
                     ,iv_token_name2  => gv_msg_00032_token_2
                     ,iv_token_value2 => iv_format
                   );
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    l_fuid_tab                          xxccp_common_pkg2.g_file_data_tbl; -- �t�@�C���A�b�v���[�h�f�[�^(VARCHAR2)
    l_asd_tab                           g_assignment_set_data_ttype;       -- �����Z�b�g�f�[�^
    l_mas_rec                           MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;      -- �����Z�b�g�w�b�_�[
    l_msa_tab                           MRP_Src_Assignment_PUB.Assignment_Tbl_Type;          -- �����Z�b�g����
    ln_normal_cnt                       NUMBER;                                              -- ���팏��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
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
    BEGIN
--
      -- ���������̏�����
      ln_normal_cnt := 0;
--
      -- ===============================
      -- A-1�D��������
      -- ===============================
      init(
         in_file_id                     -- �t�@�C��ID
        ,iv_format                      -- �t�H�[�}�b�g�p�^�[��
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-2�D�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o
      -- ===============================
      get_upload_file_data(
         in_file_id                     -- �t�@�C��ID
        ,l_fuid_tab                     -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-3�D�Ó����`�F�b�N����
      -- ===============================
      check_upload_file_data(
         l_fuid_tab                     -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
        ,l_asd_tab                      -- �����Z�b�g�f�[�^
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '�f�[�^�����F' || l_asd_tab.COUNT
      );
      <<row_loop>>
      FOR ln_row_idx IN l_asd_tab.FIRST .. l_asd_tab.LAST LOOP
        -- ===============================
        -- A-4�D�����Z�b�g�w�b�_�[�ݒ�
        -- ===============================
        set_assignment_header(
           l_asd_tab(ln_row_idx)        -- �����Z�b�g�f�[�^
          ,l_mas_rec                    -- �����Z�b�g�w�b�_�[
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-5�D�����Z�b�g���אݒ�
        -- ===============================
        set_assignment_lines(
           l_asd_tab(ln_row_idx)        -- �����Z�b�g�f�[�^
          ,l_msa_tab                    -- �����Z�b�g����
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-6�D�����Z�b�gAPI���s
        -- ===============================
        exec_api_assignment(
           l_mas_rec                    -- �����Z�b�g�w�b�_�[
          ,l_msa_tab                    -- �����Z�b�g����
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --���폈�������J�E���g
        ln_normal_cnt := ln_normal_cnt + 1;
      END LOOP row_loop;
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        --�G���[���b�Z�[�W���o��
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ�A���[���o�b�N����B
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      --�G���[���b�Z�[�W���o��
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
    END IF;
    -- ===============================
    -- A-7�D�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜
    -- ===============================
    delete_upload_file(
       in_file_id                       -- �t�@�C��ID
      ,lv_errbuf                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = gv_status_normal ) THEN
      IF ( ov_retcode <> gv_status_normal ) THEN
        --�G���[�̏ꍇ�ł��A�t�@�C���A�b�v���[�hI/F�e�[�u���̍폜�����������ꍇ�̓R�~�b�g����B
        COMMIT;
      END IF;
    ELSE
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    END IF;
    --
    IF ( ov_retcode = gv_status_normal ) THEN
      --�I���X�e�[�^�X������̏ꍇ�A�����������Z�b�g����B
      gn_normal_cnt := ln_normal_cnt;
    ELSE
      --�I���X�e�[�^�X���G���[�̏ꍇ�A�G���[�������Z�b�g����B
      IF ( gn_error_cnt = 0 ) THEN
        gn_error_cnt := 1;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id    IN  NUMBER,        -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --�ُ�I�����b�Z�[�W
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_file_id  -- �t�@�C��ID
      ,iv_format   -- �t�H�[�}�b�g�p�^�[��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => lv_errbuf --�G���[���b�Z�[�W
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOP003A01C;
/
