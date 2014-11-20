CREATE OR REPLACE PACKAGE BODY XXCOP002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP002A01C(body)
 * Description      : �A�b�v���[�h�t�@�C������̎捞�i�����\���\�j
 * MD.050           : �A�b�v���[�h�t�@�C������̎捞�i�����\���\�j MD050_COP_002_A01
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            ���b�Z�[�W�o��
 *  check_validate_item    ���ڑ����`�F�b�N
 *  delete_upload_file     �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-8)
 *  exec_api_sourcing_rule �\�[�X���[��BOD API���s(A-7)
 *  set_shipping_org       �o�בg�D�ݒ�(A-6)
 *  set_receiving_org      ����g�D�ݒ�(A-5)
 *  set_sourcing_rule      �\�[�X���[���ݒ�(A-4)
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
 *  2008/11/21    1.0   Y.Goto           �V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOP002A01C';          -- �p�b�P�[�W��
  --���b�Z�[�W����
  gv_msg_appl_cont CONSTANT VARCHAR2(100) := 'XXCOP';                 -- �A�v���P�[�V�����Z�k��
  --����
  gv_lang          CONSTANT VARCHAR2(100) := USERENV('LANG');
  --�v���O�������s�N����
  gd_sysdate       CONSTANT DATE := TRUNC(SYSDATE);                   -- �V�X�e�����t�i�N�����j
  gd_maxdate       CONSTANT DATE := TO_DATE('99991231','YYYYMMDD');   -- ���t�ő�l�i�N�����j
  --���b�Z�[�W��
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
  gv_msg_00037     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00037';      -- �d���G���[
  gv_msg_00038     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00038';      -- �ߋ����t���̓G���[
  gv_msg_00039     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00039';      -- �L�����t�]�G���[
  gv_msg_00040     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';      -- ��Ӑ��`�F�b�N�G���[
  --���b�Z�[�W�g�[�N��
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
  gv_msg_00037_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00037_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00037_token_3      CONSTANT VARCHAR2(100) := 'REASON';
  gv_msg_00037_token_4      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00038_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00038_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00038_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00039_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00039_token_2      CONSTANT VARCHAR2(100) := 'COLUMN_FROM';
  gv_msg_00039_token_3      CONSTANT VARCHAR2(100) := 'COLUMN_TO';
  gv_msg_00039_token_4      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00040_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00040_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00040_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  --���b�Z�[�W�g�[�N���l
  gv_msg_00016_value_1      CONSTANT VARCHAR2(100) := '�\�[�X���[��BOD API';    -- API��
  gv_msg_00024_value_2      CONSTANT VARCHAR2(100) := 'CSV�t�@�C��';            -- �t�@�C����
  gv_msg_00037_reason_1     CONSTANT VARCHAR2(100) := '�q�ɃR�[�h';             -- �d������
  gv_msg_00037_reason_2     CONSTANT VARCHAR2(100) := '���t�͈�';               -- �d������
  gv_msg_table_iwm          CONSTANT VARCHAR2(100) := 'OPM�q�Ƀ}�X�^';          -- IC_WHSE_MST
  gv_msg_table_mism         CONSTANT VARCHAR2(100) := '�g�D�ԏo�ו��@';         -- MTL_INTERORG_SHIP_METHODS
  gv_msg_table_msnv         CONSTANT VARCHAR2(100) := '�o�׃l�b�g���[�N�r���['; -- MTL_SHIPPING_NETWORK_VIEW
  gv_msg_param_file_id      CONSTANT VARCHAR2(100) := 'FILE_ID';                -- ���̓p�����[�^.�t�@�C��ID
  gv_msg_param_format       CONSTANT VARCHAR2(100) := '�t�H�[�}�b�g�p�^�[��';   -- ���̓p�����[�^.�t�H�[�}�b�g�p�^�[��
  gv_msg_comma              CONSTANT VARCHAR2(100) := ',';                      -- ���ڋ�؂�
---------------------------------------------------------
  --�t�@�C���A�b�v���[�hI/F�e�[�u��
  gv_format_pattern         CONSTANT VARCHAR2(3)   := '210';                    -- �t�H�[�}�b�g�p�^�[��
  gv_delim                  CONSTANT VARCHAR2(1)   := ',';                      -- �f���~�^����
  gn_column_num             CONSTANT NUMBER        := 13;                       -- ���ڐ�
  gn_header_row_num         CONSTANT NUMBER        := 1;                        -- �w�b�_�[�s��
  --���ڂ̓��{�ꖼ��
  gv_column_name_01         CONSTANT VARCHAR2(100) := '�����\���\';
  gv_column_name_02         CONSTANT VARCHAR2(100) := '�����\���\��';
  gv_column_name_03         CONSTANT VARCHAR2(100) := '����q��';
  gv_column_name_04         CONSTANT VARCHAR2(100) := '�L���J�n';
  gv_column_name_05         CONSTANT VARCHAR2(100) := '�L���I��';
  gv_column_name_06         CONSTANT VARCHAR2(100) := '���H��Ώۃt���O';
  gv_column_name_07         CONSTANT VARCHAR2(100) := '�q��';
  gv_column_name_08         CONSTANT VARCHAR2(100) := '�d����';
  gv_column_name_09         CONSTANT VARCHAR2(100) := '�d����T�C�g';
  gv_column_name_10         CONSTANT VARCHAR2(100) := '����';
  gv_column_name_11         CONSTANT VARCHAR2(100) := '�����N';
  gv_column_name_12         CONSTANT VARCHAR2(100) := '�o�ו��@';
  gv_column_name_13         CONSTANT VARCHAR2(100) := '�^�C�v';
  --���ڂ̃T�C�Y
  gv_column_len_01          CONSTANT NUMBER := 30;                              -- �����\���\
  gv_column_len_02          CONSTANT NUMBER := 80;                              -- �����\���\��
  gv_column_len_03          CONSTANT NUMBER := 3;                               -- ����q��
  gv_column_len_06          CONSTANT NUMBER := 1;                               -- ���H��Ώۃt���O
  gv_column_len_07          CONSTANT NUMBER := 3;                               -- �q��
  gv_column_len_08          CONSTANT NUMBER := 9;                               -- �d����
  gv_column_len_09          CONSTANT NUMBER := 9;                               -- �d����T�C�g
  gv_column_len_12          CONSTANT NUMBER := 30;                              -- �o�ו��@
  gv_column_len_13          CONSTANT NUMBER := 1;                               -- �^�C�v
  --�K�{����
  gv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- �K�{����
  gv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL����
  gv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- �C�Ӎ���
  --���t�^�t�H�[�}�b�g
  gv_ymd_format             CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                -- �N����
  gv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';   -- �N���������b(24���ԕ\�L)
  --���H��Ώۃt���O
  gv_own_factory_flag       CONSTANT NUMBER        := 1;                        -- YES
  --�^�C�v
  gv_transfer               CONSTANT NUMBER        := 1;                        -- �ړ���
  gv_make                   CONSTANT NUMBER        := 2;                        -- �����ꏊ
  gv_buy                    CONSTANT NUMBER        := 3;                        -- �w����
  --�\�[�X���[���^�C�v
  gv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- �����\���\
  --����
  gv_allocation_100         CONSTANT NUMBER        := 100;                      -- 100%
  --�����N
  gv_rank_first             CONSTANT NUMBER        := 1;                        -- 1
  --�X�e�[�^�X
  gn_unprocessed            CONSTANT NUMBER        := 1;                        -- ������
  --�A�N�e�B�u�敪
  gn_active                 CONSTANT NUMBER        := 1;                        -- �L��
  --API�萔
  gv_operation_create       CONSTANT VARCHAR2(6)   := 'CREATE';                 -- �o�^
  gv_operation_update       CONSTANT VARCHAR2(6)   := 'UPDATE';                 -- �X�V
  gv_api_version            CONSTANT VARCHAR2(4)   := '1.0';                    -- �o�[�W����
  gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';                      -- �G���[���b�Z�[�W�G���R�[�h
  --���b�Z�[�W�o��
  gv_blank                  CONSTANT VARCHAR2(5)   := 'BLANK';                   -- �󔒍s
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�����\���\���R�[�h�^
  TYPE g_sourcing_rule_data_rtype IS RECORD (
  --CSV����
    sourcing_rule_name      mrp_sourcing_rules.sourcing_rule_name%TYPE
  , sourcing_rule_desc      mrp_sourcing_rules.description%TYPE
  , receipt_org_code        ic_whse_mst.whse_code%TYPE
  , effective_date          mrp_sr_receipt_org.effective_date%TYPE
  , disable_date            mrp_sr_receipt_org.disable_date%TYPE
  , own_factory_flag        NUMBER(1)
  , source_org_code         ic_whse_mst.whse_code%TYPE
  , vendor_code             po_vendors.segment1%TYPE
  , vendor_site_code        po_vendor_sites_all.vendor_site_code%TYPE
  , allocation_percent      mrp_sr_source_org.allocation_percent%TYPE
  , rank                    mrp_sr_source_org.rank%TYPE
  , ship_method             mrp_sr_source_org.ship_method%TYPE
  , source_type             mrp_sr_source_org.source_type%TYPE
  --�擾����
  , sourcing_rule_id        mrp_sourcing_rules.sourcing_rule_id%TYPE
  , sr_receipt_id           mrp_sr_receipt_org.sr_receipt_id%TYPE
  , receipt_org_id          mrp_sr_receipt_org.receipt_organization_id%TYPE
  , source_org_id           mrp_sr_source_org.source_organization_id%TYPE
  );
  --�����\���\�R���N�V�����^
  TYPE g_sourcing_rule_data_ttype IS TABLE OF g_sourcing_rule_data_rtype
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
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-8)
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
   * Procedure Name   : exec_api_sourcing_rule
   * Description      : �\�[�X���[��BOD API���s(A-7)
   ***********************************************************************************/
  PROCEDURE exec_api_sourcing_rule(
    i_mar_rec     IN  MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type,   -- 1.�\�[�X���[���\
    i_msro_tab    IN  MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type,   -- 2.����g�D�\
    i_msso_tab    IN  MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type,    -- 2.�o�בg�D�\
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_sourcing_rule'; -- �v���O������
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
    l_mar_val_rec                     MRP_Sourcing_Rule_PUB.Sourcing_Rule_Val_Rec_Type;
    l_msro_val_tab                    MRP_Sourcing_Rule_PUB.Receiving_Org_Val_Tbl_Type;
    l_msso_val_tab                    MRP_Sourcing_Rule_PUB.Shipping_Org_Val_Tbl_Type;
    l_out_mar_rec                     MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type;
    l_out_mar_val_rec                 MRP_Sourcing_Rule_PUB.Sourcing_Rule_Val_Rec_Type;
    l_out_msro_tab                    MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type;
    l_out_msro_val_tab                MRP_Sourcing_Rule_PUB.Receiving_Org_Val_Tbl_Type;
    l_out_msso_tab                    MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type;
    l_out_msso_val_tab                MRP_Sourcing_Rule_PUB.Shipping_Org_Val_Tbl_Type;
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
    --�f�o�b�N���b�Z�[�W�i�����\���\���R�[�h�^�j
    xxcop_common_pkg.put_debug_message('sourcing_rule:-',gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation         :'||i_mar_rec.operation                       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_name:'||i_mar_rec.sourcing_rule_name              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>description       :'||i_mar_rec.description                     ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>organization_id   :'||i_mar_rec.organization_id                 ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_id  :'||i_mar_rec.sourcing_rule_id                ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_type:'||i_mar_rec.sourcing_rule_type              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>status            :'||i_mar_rec.status                          ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>planning_active   :'||i_mar_rec.planning_active                 ,gv_debug_mode);
    --�f�o�b�N���b�Z�[�W�i�\�[�X���[������g�D�\�R���N�V�����^�j
    xxcop_common_pkg.put_debug_message('receipt_org  :'||i_msro_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation              :'||i_msro_tab(1).operation              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_id       :'||i_msro_tab(1).sourcing_rule_id       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>receipt_organization_id:'||i_msro_tab(1).receipt_organization_id,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>effective_date         :'||i_msro_tab(1).effective_date         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>disable_date           :'||i_msro_tab(1).disable_date           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1             :'||i_msro_tab(1).attribute1             ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_receipt_id          :'||i_msro_tab(1).sr_receipt_id          ,gv_debug_mode);
    --�f�o�b�N���b�Z�[�W�i�\�[�X���[���o�בg�D�\�R���N�V�����^�j
    xxcop_common_pkg.put_debug_message('source_org    :'|| i_msso_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation              :'|| i_msso_tab(1).operation             ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_receipt_id          :'|| i_msso_tab(1).sr_receipt_id         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>source_organization_id :'|| i_msso_tab(1).source_organization_id,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>allocation_percent     :'|| i_msso_tab(1).allocation_percent    ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>rank                   :'|| i_msso_tab(1).rank                  ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>ship_method            :'|| i_msso_tab(1).ship_method           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>source_type            :'|| i_msso_tab(1).source_type           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>receiving_org_index    :'|| i_msso_tab(1).receiving_org_index   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_source_id           :'|| i_msso_tab(1).sr_source_id          ,gv_debug_mode);
    --�\�[�X���[��BOD API���s
    mrp_sourcing_rule_pub.process_sourcing_rule(
       p_api_version_number          => gv_api_version
      ,p_init_msg_list               => FND_API.G_TRUE
      ,p_return_values               => FND_API.G_TRUE
      ,p_commit                      => FND_API.G_FALSE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_Sourcing_Rule_rec           => i_mar_rec
      ,p_Sourcing_Rule_val_rec       => l_mar_val_rec
      ,p_Receiving_Org_tbl           => i_msro_tab
      ,p_Receiving_Org_val_tbl       => l_msro_val_tab
      ,p_Shipping_Org_tbl            => i_msso_tab
      ,p_Shipping_Org_val_tbl        => l_msso_val_tab
      ,x_Sourcing_Rule_rec           => l_out_mar_rec
      ,x_Sourcing_Rule_val_rec       => l_out_mar_val_rec
      ,x_Receiving_Org_tbl           => l_out_msro_tab
      ,x_Receiving_Org_val_tbl       => l_out_msro_val_tab
      ,x_Shipping_Org_tbl            => l_out_msso_tab
      ,x_Shipping_Org_val_tbl        => l_out_msso_val_tab
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
  END exec_api_sourcing_rule;
--
  /**********************************************************************************
   * Procedure Name   : set_shipping_org
   * Description      : �o�בg�D�ݒ�(A-6)
   ***********************************************************************************/
  PROCEDURE set_shipping_org(
    i_srd_rec     IN  g_sourcing_rule_data_rtype,                     -- 1.�����\���\�f�[�^
    o_msso_tab    OUT MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type,    -- 2.�o�בg�D�\
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_shipping_org'; -- �v���O������
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
    --�\�[�X���[���o�בg�D�\�̊����f�[�^�`�F�b�N
    BEGIN
      SELECT msso.sr_source_id   sr_source_id
      INTO   o_msso_tab(1).sr_source_id
      FROM   mrp_sr_source_org msso
      WHERE  msso.source_organization_id   = i_srd_rec.source_org_id
        AND  msso.sr_receipt_id            = i_srd_rec.sr_receipt_id;
      --�����f�[�^������ꍇ
      o_msso_tab(1).operation             := gv_operation_update;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_source_org_s.NEXTVAL
        INTO   o_msso_tab(1).sr_source_id
        FROM   DUAL;
        o_msso_tab(1).operation             := gv_operation_create;
        o_msso_tab(1).created_by            := gn_created_by;
        o_msso_tab(1).creation_date         := gd_creation_date;
    END;
--
    --�\�[�X���[��BOD API�W���R���N�V�����^�ɒl���Z�b�g
    o_msso_tab(1).sr_receipt_id           := i_srd_rec.sr_receipt_id;
    o_msso_tab(1).source_organization_id  := i_srd_rec.source_org_id;
    o_msso_tab(1).vendor_id               := NULL;
    o_msso_tab(1).vendor_site_id          := NULL;
    o_msso_tab(1).allocation_percent      := i_srd_rec.allocation_percent;
    o_msso_tab(1).rank                    := i_srd_rec.rank;
    o_msso_tab(1).ship_method             := i_srd_rec.ship_method;
    o_msso_tab(1).source_type             := i_srd_rec.source_type;
    o_msso_tab(1).receiving_org_index     := 1;
    o_msso_tab(1).last_updated_by         := gn_last_updated_by;
    o_msso_tab(1).last_update_date        := gd_last_update_date;
    o_msso_tab(1).last_update_login       := gn_last_update_login;
    o_msso_tab(1).program_application_id  := gn_program_application_id;
    o_msso_tab(1).program_id              := gn_program_id;
    o_msso_tab(1).program_update_date     := gd_program_update_date;
    o_msso_tab(1).request_id              := gn_request_id;
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
  END set_shipping_org;
--
  /**********************************************************************************
   * Procedure Name   : set_receiving_org
   * Description      : ����g�D�ݒ�(A-5)
   ***********************************************************************************/
  PROCEDURE set_receiving_org(
    io_srd_rec    IN OUT g_sourcing_rule_data_rtype,                     -- 1.�����\���\�f�[�^
    o_msro_tab    OUT    MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type,   -- 2.����g�D�\
    ov_errbuf     OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_receiving_org'; -- �v���O������
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
    --�\�[�X���[������g�D�\�̊����f�[�^�`�F�b�N
    BEGIN
      SELECT msro.sr_receipt_id   sr_receipt_id
      INTO   o_msro_tab(1).sr_receipt_id
      FROM   mrp_sr_receipt_org msro
      WHERE  msro.receipt_organization_id   = io_srd_rec.receipt_org_id
        AND  msro.sourcing_rule_id          = io_srd_rec.sourcing_rule_id
        AND  msro.effective_date            = io_srd_rec.effective_date;
      --�����f�[�^������ꍇ
      o_msro_tab(1).operation              := gv_operation_update;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_receipt_org_s.NEXTVAL
        INTO   o_msro_tab(1).sr_receipt_id
        FROM   DUAL;
        o_msro_tab(1).operation              := gv_operation_create;
        o_msro_tab(1).created_by             := gn_created_by;
        o_msro_tab(1).creation_date          := gd_creation_date;
    END;
--
    --�\�[�X���[��BOD API�W���R���N�V�����^�ɒl���Z�b�g
    o_msro_tab(1).sourcing_rule_id         := io_srd_rec.sourcing_rule_id;
    o_msro_tab(1).receipt_organization_id  := io_srd_rec.receipt_org_id;
    o_msro_tab(1).effective_date           := io_srd_rec.effective_date;
    o_msro_tab(1).disable_date             := io_srd_rec.disable_date;
    o_msro_tab(1).attribute1               := TO_CHAR(io_srd_rec.own_factory_flag);
    o_msro_tab(1).last_updated_by          := gn_last_updated_by;
    o_msro_tab(1).last_update_date         := gd_last_update_date;
    o_msro_tab(1).last_update_login        := gn_last_update_login;
    o_msro_tab(1).program_application_id   := gn_program_application_id;
    o_msro_tab(1).program_id               := gn_program_id;
    o_msro_tab(1).program_update_date      := gd_program_update_date;
    o_msro_tab(1).request_id               := gn_request_id;
--
    --�\�[�X���[������g�D�\ID�𕨗��\���\�f�[�^�ɃZ�b�g
    io_srd_rec.sr_receipt_id               := o_msro_tab(1).sr_receipt_id;
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
  END set_receiving_org;
--
  /**********************************************************************************
   * Procedure Name   : set_sourcing_rule
   * Description      : �\�[�X���[���ݒ�(A-4)
   ***********************************************************************************/
  PROCEDURE set_sourcing_rule(
    io_srd_rec    IN OUT g_sourcing_rule_data_rtype,                     -- 1.�����\���\�f�[�^
    o_mar_rec     OUT    MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type,   -- 2.�\�[�X���[���\
    ov_errbuf     OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sourcing_rule'; -- �v���O������
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
    --�\�[�X���[�������\���\�̊����f�[�^�`�F�b�N
    BEGIN
      SELECT msr.sourcing_rule_id   sourcing_rule_id
            ,msr.sourcing_rule_type sourcing_rule_type
            ,msr.status             status
            ,msr.planning_active    planning_active
      INTO   o_mar_rec.sourcing_rule_id
            ,o_mar_rec.sourcing_rule_type
            ,o_mar_rec.status
            ,o_mar_rec.planning_active
      FROM   mrp_sourcing_rules msr
      WHERE  msr.sourcing_rule_name    = io_srd_rec.sourcing_rule_name
        AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule;
      --�����f�[�^������ꍇ
      o_mar_rec.operation             := gv_operation_update;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sourcing_rules_s.NEXTVAL
        INTO   o_mar_rec.sourcing_rule_id
        FROM   DUAL;
      o_mar_rec.sourcing_rule_type    := gv_mrp_sourcing_rule;
      o_mar_rec.status                := gn_unprocessed;
      o_mar_rec.planning_active       := gn_active;
      o_mar_rec.operation             := gv_operation_create;
      o_mar_rec.created_by            := gn_created_by;
      o_mar_rec.creation_date         := gd_creation_date;
    END;
--
    --�\�[�X���[��BOD API�W�����R�[�h�^�ɒl���Z�b�g
    o_mar_rec.sourcing_rule_name      := io_srd_rec.sourcing_rule_name;
    o_mar_rec.description             := io_srd_rec.sourcing_rule_desc;
    o_mar_rec.organization_id         := NULL;
    o_mar_rec.last_updated_by         := gn_last_updated_by;
    o_mar_rec.last_update_date        := gd_last_update_date;
    o_mar_rec.last_update_login       := gn_last_update_login;
    o_mar_rec.program_application_id  := gn_program_application_id;
    o_mar_rec.program_id              := gn_program_id;
    o_mar_rec.program_update_date     := gd_program_update_date;
    o_mar_rec.request_id              := gn_request_id;
--
    --�\�[�X���[�������\���\ID�𕨗��\���\�f�[�^�ɃZ�b�g
    io_srd_rec.sourcing_rule_id       := o_mar_rec.sourcing_rule_id;
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
  END set_sourcing_rule;
--
  /**********************************************************************************
   * Procedure Name   : check_upload_file_data
   * Description      : �Ó����`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE check_upload_file_data(
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- 1.�t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
    o_srd_tab     OUT g_sourcing_rule_data_ttype,         -- 2.�����\���\�f�[�^
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
    ln_srd_idx                NUMBER;
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
      ln_srd_idx      := ln_row_idx - gn_header_row_num;
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
        --���ږ��̑Ó����`�F�b�N
        --�����\���\
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).sourcing_rule_name := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�����\���\��
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).sourcing_rule_desc := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --����q��
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).receipt_org_code := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
          --�q�ɃR�[�h�`�F�b�N
          BEGIN
            SELECT iwm.mtl_organization_id   mtl_organization_id
            INTO   o_srd_tab(ln_srd_idx).receipt_org_id
            FROM   ic_whse_mst iwm
            WHERE  iwm.whse_code = o_srd_tab(ln_srd_idx).receipt_org_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_03
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(3)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_iwm
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
        --�L���J�n
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).effective_date := TO_DATE(l_csv_tab(4),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�L���I��
        check_validate_item(
           iv_item_name   => gv_column_name_05
          ,iv_item_value  => l_csv_tab(5)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).disable_date := TO_DATE(l_csv_tab(5),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --�L���J�n���A�L���I�����`�F�b�N
        IF ( o_srd_tab(ln_srd_idx).effective_date > NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => gv_msg_appl_cont
                         ,iv_name         => gv_msg_00039
                         ,iv_token_name1  => gv_msg_00039_token_1
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_msg_00039_token_2
                         ,iv_token_value2 => gv_column_name_04
                         ,iv_token_name3  => gv_msg_00039_token_3
                         ,iv_token_value3 => gv_column_name_05
                         ,iv_token_name4  => gv_msg_00039_token_4
                         ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          ln_invalid_flag := gv_status_error;
        END IF;
        --���БΏۃt���O
        check_validate_item(
           iv_item_name   => gv_column_name_06
          ,iv_item_value  => l_csv_tab(6)
          ,iv_null        => gv_any_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_06
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).own_factory_flag := TO_NUMBER(l_csv_tab(6));
          IF ( NVL(o_srd_tab(ln_srd_idx).own_factory_flag,gv_own_factory_flag) NOT IN ( gv_own_factory_flag ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_06
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --�q��
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).source_org_code := SUBSTRB(l_csv_tab(7),1,gv_column_len_07);
          --�q�ɃR�[�h�`�F�b�N
          BEGIN
            SELECT iwm.mtl_organization_id   mtl_organization_id
            INTO   o_srd_tab(ln_srd_idx).source_org_id
            FROM   ic_whse_mst iwm
            WHERE  iwm.whse_code = o_srd_tab(ln_srd_idx).source_org_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_07
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(7)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_iwm
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
        IF (  o_srd_tab(ln_srd_idx).receipt_org_code IS NOT NULL
          AND o_srd_tab(ln_srd_idx).source_org_code  IS NOT NULL )
        THEN
          --�q�ɃR�[�h�`�F�b�N
          IF ( o_srd_tab(ln_srd_idx).receipt_org_code = o_srd_tab(ln_srd_idx).source_org_code ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00037
                           ,iv_token_name1  => gv_msg_00037_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00037_token_2
                           ,iv_token_value2 => gv_column_name_03 || gv_msg_comma
                                               || gv_column_name_07
                           ,iv_token_name3  => gv_msg_00037_token_3
                           ,iv_token_value3 => gv_msg_00037_reason_1
                           ,iv_token_name4  => gv_msg_00037_token_4
                           ,iv_token_value4 => i_fuid_tab(ln_row_idx)

                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          --�o�׃l�b�g���[�N�r���[���݃`�F�b�N
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   mtl_shipping_network_view msnv
          WHERE ( msnv.from_organization_code = o_srd_tab(ln_srd_idx).source_org_code
              AND msnv.to_organization_code   = o_srd_tab(ln_srd_idx).receipt_org_code )
             OR ( msnv.from_organization_code = o_srd_tab(ln_srd_idx).receipt_org_code
              AND msnv.to_organization_code   = o_srd_tab(ln_srd_idx).source_org_code );
          IF ( ln_exists = 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_07
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_srd_tab(ln_srd_idx).receipt_org_code || gv_msg_comma
                                            || o_srd_tab(ln_srd_idx).source_org_code
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_msnv
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
        --�d����i���g�p���ڂ̂��߃`�F�b�N�Ȃ��j
        --�d����T�C�g�i���g�p���ڂ̂��߃`�F�b�N�Ȃ��j
        --����
        check_validate_item(
           iv_item_name   => gv_column_name_10
          ,iv_item_value  => l_csv_tab(10)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).allocation_percent := TO_NUMBER(l_csv_tab(10));
          --�����`�F�b�N
          IF ( o_srd_tab(ln_srd_idx).allocation_percent NOT IN ( gv_allocation_100 ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_10
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --�����N
        check_validate_item(
           iv_item_name   => gv_column_name_11
          ,iv_item_value  => l_csv_tab(11)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).rank := TO_NUMBER(l_csv_tab(11));
          --�����N�`�F�b�N
          IF ( o_srd_tab(ln_srd_idx).rank NOT IN ( gv_rank_first ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_11
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --�o�ו��@
        check_validate_item(
           iv_item_name   => gv_column_name_12
          ,iv_item_value  => l_csv_tab(12)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_12
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).ship_method := SUBSTRB(l_csv_tab(12),1,gv_column_len_12);
          --�o�ו��@�`�F�b�N
          IF ( o_srd_tab(ln_srd_idx).ship_method IS NOT NULL ) THEN
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mtl_interorg_ship_methods mism
            WHERE  mism.from_organization_id = o_srd_tab(ln_srd_idx).source_org_id
              AND  mism.to_organization_id   = o_srd_tab(ln_srd_idx).receipt_org_id
              AND  mism.ship_method          = o_srd_tab(ln_srd_idx).ship_method;
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_12
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(12)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_mism
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
        --�^�C�v
        check_validate_item(
           iv_item_name   => gv_column_name_13
          ,iv_item_value  => l_csv_tab(13)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_13
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).source_type := TO_NUMBER(l_csv_tab(13));
          --�^�C�v�`�F�b�N
          IF ( o_srd_tab(ln_srd_idx).source_type NOT IN ( gv_transfer ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_13
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --�\�[�X���[������g�D�\�`�F�b�N
        IF ( o_srd_tab(ln_srd_idx).effective_date IS NOT NULL ) THEN
          IF ( o_srd_tab(ln_srd_idx).effective_date > gd_sysdate ) THEN
            --�������̏ꍇ
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM (
              WITH msro_vw AS (
                SELECT msro.effective_date           effective_date
                      ,msro.disable_date             disable_date
                      ,LEAD ( msro.effective_date ) OVER ( ORDER BY msro.effective_date ) next_effective_date
                FROM   mrp_sr_receipt_org msro
                WHERE  msro.receipt_organization_id = o_srd_tab(ln_srd_idx).receipt_org_id
                  AND  EXISTS (
                  SELECT 'x'
                  FROM   mrp_sourcing_rules msr
                  WHERE  msr.sourcing_rule_name    = o_srd_tab(ln_srd_idx).sourcing_rule_name
                    AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule
                    AND  msr.sourcing_rule_id      = msro.sourcing_rule_id
                  )
              )
              SELECT msro_vw1.effective_date         effective_date
                    ,msro_vw1.disable_date           disable_date
                    ,msro_vw1.next_effective_date    next_effective_date
              FROM   msro_vw msro_vw1
              WHERE ( (     msro_vw1.effective_date           <=     o_srd_tab(ln_srd_idx).effective_date
                    AND NVL(msro_vw1.disable_date,gd_maxdate) >=     o_srd_tab(ln_srd_idx).effective_date )
                  OR  (     msro_vw1.effective_date           <= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate)
                    AND NVL(msro_vw1.disable_date,gd_maxdate) >= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) )
                  OR  (     msro_vw1.effective_date           >=     o_srd_tab(ln_srd_idx).effective_date
                    AND NVL(msro_vw1.disable_date,gd_maxdate) <= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) )
                )
                AND NOT EXISTS (
                  SELECT 'x'
                  FROM   msro_vw msro_vw2
                  WHERE  msro_vw2.effective_date        = o_srd_tab(ln_srd_idx).effective_date
                    AND  ( msro_vw2.next_effective_date > o_srd_tab(ln_srd_idx).disable_date
                      OR   msro_vw2.next_effective_date IS NULL
                    )
                    AND  msro_vw2.rowid = msro_vw1.rowid
                  )
            );
            IF ( ln_exists > 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00037
                             ,iv_token_name1  => gv_msg_00037_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00037_token_2
                             ,iv_token_value2 => gv_column_name_04 || gv_msg_comma
                                              || gv_column_name_05
                             ,iv_token_name3  => gv_msg_00037_token_3
                             ,iv_token_value3 => gv_msg_00037_reason_2
                             ,iv_token_name4  => gv_msg_00037_token_4
                             ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          ELSE
            --�ߋ����̏ꍇ
            SELECT COUNT ('x')   row_count
            INTO   ln_exists
            FROM (
              SELECT msro.effective_date effective_date
                    ,msro.disable_date disable_date
                    ,LEAD ( msro.effective_date ) OVER ( ORDER BY msro.effective_date ) next_effective_date
              FROM   mrp_sr_receipt_org msro
              WHERE msro.receipt_organization_id = o_srd_tab(ln_srd_idx).receipt_org_id
                AND EXISTS (
                SELECT 'x'
                FROM   mrp_sourcing_rules msr
                WHERE  msr.sourcing_rule_name    = o_srd_tab(ln_srd_idx).sourcing_rule_name
                  AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule
                  AND  msr.sourcing_rule_id      = msro.sourcing_rule_id
                )
            ) msro_vw
            WHERE  msro_vw.effective_date        = o_srd_tab(ln_srd_idx).effective_date
              AND  ( msro_vw.next_effective_date > o_srd_tab(ln_srd_idx).disable_date
                OR   msro_vw.next_effective_date IS NULL
              );
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00038
                             ,iv_token_name1  => gv_msg_00038_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00038_token_2
                             ,iv_token_value2 => gv_column_name_04
                             ,iv_token_name3  => gv_msg_00038_token_3
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        END IF;
        --��ӃL�[�`�F�b�N
        <<key_loop>>
        FOR ln_key_idx IN o_srd_tab.first .. ( ln_srd_idx - 1 ) LOOP
          IF (  o_srd_tab(ln_srd_idx).sourcing_rule_name           = o_srd_tab(ln_key_idx).sourcing_rule_name
            AND o_srd_tab(ln_srd_idx).receipt_org_code             = o_srd_tab(ln_key_idx).receipt_org_code
            AND o_srd_tab(ln_srd_idx).effective_date               = o_srd_tab(ln_key_idx).effective_date
            AND NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) = NVL(o_srd_tab(ln_key_idx).disable_date,gd_maxdate)
            AND o_srd_tab(ln_srd_idx).source_org_code              = o_srd_tab(ln_key_idx).source_org_code )
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00040
                           ,iv_token_name1  => gv_msg_00040_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00040_token_2
                           ,iv_token_value2 => gv_column_name_01 || gv_msg_comma
                                            || gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_04 || gv_msg_comma
                                            || gv_column_name_05 || gv_msg_comma
                                            || gv_column_name_07 || gv_msg_comma
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
                       ,iv_token_value1 => ln_srd_idx
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
    l_srd_tab                           g_sourcing_rule_data_ttype;        -- �����\���\�f�[�^
    l_mar_rec                           MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type;        -- �\�[�X���[���\
    l_msro_tab                          MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type;        -- ����g�D�\
    l_msso_tab                          MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type;         -- �o�בg�D�\
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
        ,l_srd_tab                      -- �����\���\�f�[�^
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
        ,iv_value       => '�f�[�^�����F' || l_srd_tab.COUNT
      );
      <<row_loop>>
      FOR ln_row_idx IN l_srd_tab.FIRST .. l_srd_tab.LAST LOOP
        -- ===============================
        -- A-4�D�\�[�X���[���ݒ�
        -- ===============================
        set_sourcing_rule(
           l_srd_tab(ln_row_idx)        -- �����\���\�f�[�^
          ,l_mar_rec                    -- �\�[�X���[���\
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-5�D����g�D�ݒ�
        -- ===============================
        set_receiving_org(
           l_srd_tab(ln_row_idx)        -- �����\���\�f�[�^
          ,l_msro_tab                   -- ����g�D�\
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-6�D�o�בg�D�ݒ�
        -- ===============================
        set_shipping_org(
           l_srd_tab(ln_row_idx)        -- �����\���\�f�[�^
          ,l_msso_tab                   -- �o�בg�D�\
          ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-7�D�\�[�X���[��BOD API���s
        -- ===============================
        exec_api_sourcing_rule(
           l_mar_rec                    -- �\�[�X���[���\
          ,l_msro_tab                   -- ����g�D�\
          ,l_msso_tab                   -- �o�בg�D�\
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
    -- A-8�D�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜
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
END XXCOP002A01C;
/
