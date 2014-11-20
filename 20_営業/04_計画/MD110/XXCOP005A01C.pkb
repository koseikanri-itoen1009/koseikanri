create or replace PACKAGE BODY      XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(body)
 * Description      : �H��o�׌v��
 * MD.050           : �H��o�׌v�� MD050_COP_005_A01
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_table           �e�[�u���f�[�^�폜(A-11)
 *  init                   ��������(A-1)
 *  get_plant_mark         �H��ŗL�L���擾�����iA-21�j
 *  insert_wk_tbl          ���[�N�e�[�u���f�[�^�o�^(A-22)
 *  get_schedule_date      ����Y�v��擾�iA-2�j
 *  get_cnt_from_org       �e�q�Ɍ����擾����(A-31)
 *  get_plant_shipping     �H��o�׌v�搧��}�X�^�擾�iA-3�j
 *  get_base_yokomst       ��{����������}�X�^�擾�iA-4�j
 *  get_under_lvl_pace     ���ʑq�ɏo�׃y�[�X�擾�����iA-5�j
 *  get_stock_qty          �݌ɐ��擾�����iA-6�j
 *  get_move_qty           �ړ����擾�����iA-7�j
 *  insert_wk_output       �H��o�׌v��o�̓��[�N�e�[�u���쐬�iA-8�j
 *  csv_output             �H��o�׌v��CSV�o��(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS Uda          �V�K�쐬
 *  2009/02/25    1.1   SCS Uda          �����e�X�g�d�l�ύX�i������QNo.014�j
 *  2009/04/07    1.2   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0277�AT1_0278�AT1_0280�AT1_0281�AT1_0368�j
 *  2009/04/14    1.3   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0542�j
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  --
  param_invalid_expt        EXCEPTION;     -- ���̓p�����[�^�`�F�b�N�G���[
  internal_process_expt     EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
  date_invalid_expt         EXCEPTION;     -- ���t�`�F�b�N�G���[
  past_date_invalid_expt    EXCEPTION;     -- �ߋ����`�F�b�N�G���[
  expt_next_record          EXCEPTION;     -- ���R�[�h�X�L�b�v�p
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
  reverse_invalid_expt      EXCEPTION;     -- ���t�t�]�G���[
  profile_validate_expt     EXCEPTION;     -- �v���t�@�C���擾�G���[
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  item_status_expt          EXCEPTION;     -- �i�ڃX�e�[�^�X�s���x�����b�Z�[�W
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END

  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP005A01C';
  --�v���O�������s����
  cd_sys_date                   CONSTANT DATE        := TRUNC(SYSDATE);                    --�v���O�������s����
  -- ���̓p�����[�^���O�o�͗p
  cv_plan_type_tl               CONSTANT VARCHAR2(100) := '�v��敪';
  cv_pace_from_tl               CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����FROM';
  cv_pace_to_tl                 CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����TO';
  cv_forcast_type_tl            CONSTANT VARCHAR2(100) := '�o�ח\���敪';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := ' : ';
  --���b�Z�[�W����
  cv_msg_appl_cont              CONSTANT VARCHAR2(100) := 'XXCOP';                 -- �A�v���P�[�V�����Z�k��
  --���b�Z�[�W��
  cv_msg_00002     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';      -- �v���t�@�C���l�擾���s
  cv_msg_00055     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';      -- �p�����[�^�G���[���b�Z�[�W
  cv_msg_00011     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';      -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_00025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';      -- �l�t�]�G���[���b�Z�[�W
  cv_msg_00047     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';      -- ���������b�Z�[�W
  cv_msg_00053     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';      -- �z�����[�h�^�C���擾�G���[
  cv_msg_00056     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';      -- �ݒ���Ԓ��ғ����`�F�b�N�G���[���b�Z�[�W
  cv_msg_00057     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';      -- �z���P�ʎ擾�G���[���b�Z�[�W
  cv_msg_00049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';      -- �i�ڏ��擾�G���[
  cv_msg_00050     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';      -- �g�D���擾�G���[
  cv_msg_00058     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00058';      -- ���[���v�Z�s���G���[���b�Z�[�W
  cv_msg_00059     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00059';      -- �z���P�ʃ[���G���[
  cv_msg_00042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';      -- �폜�����G���[
  cv_msg_10025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10025';      -- �H��ŗL�L���擾�G���[
  cv_msg_00060     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';      -- �o�H��񃋁[�v�G���[���b�Z�[�W
  cv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- �Ώۃf�[�^�Ȃ�
  cv_msg_00027     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';      -- �o�^�����G���[���b�Z�[�W
  cv_msg_00061     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';      -- �P�[�X�����s�����b�Z�[�W
  cv_msg_00028     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';      -- �X�V�����G���[���b�Z�[�W
  cv_msg_00062     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00062';      -- �o�H�G���[���b�Z�[�W
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  cv_msg_10042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10042';      -- �o�H�G���[���b�Z�[�W
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
  -- ���b�Z�[�W�֘A
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  --���b�Z�[�W�g�[�N��
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00049_token_1      CONSTANT VARCHAR2(100) := 'ITEMID';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00057_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00058_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME1';
  cv_msg_00058_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME2';
  cv_msg_00059_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_START
--  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
--  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_END
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_NAME';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00062_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
  cv_msg_10042_token_1      CONSTANT VARCHAR2(100) := 'ORG_CODE';
  cv_msg_10042_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10042_token_3      CONSTANT VARCHAR2(100) := 'DATE';
  cv_msg_10042_token_4      CONSTANT VARCHAR2(100) := 'STATUS';
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--
  --���b�Z�[�W�g�[�N���l
  cv_msg_unit_delivery      CONSTANT VARCHAR2(100) := '�z���P��';
  cv_msg_wk_tbl             CONSTANT VARCHAR2(100) := '�����v�惏�[�N�e�[�u��';
  cv_msg_wk_tbl_output      CONSTANT VARCHAR2(100) := '�H��o�׌v��o�̓��[�N�e�[�u��';
  cv_msg_stock_dates        CONSTANT VARCHAR2(100) := '�݌ɓ���';
  cv_msg_item               CONSTANT VARCHAR2(100) := '�i��';
  cv_msg_item_name          CONSTANT VARCHAR2(100) := '�@�i�ږ�';
  cv_msg_org_name           CONSTANT VARCHAR2(100) := '�@�q�ɖ�';
  cv_msg_stock_days         CONSTANT VARCHAR2(100) := '�݌ɓ���';
  cv_msg_sum_pace           CONSTANT VARCHAR2(100) := '���o�׃y�[�X';
  cv_msg_palette            CONSTANT VARCHAR2(100) := '�z��';
  cv_msg_move_qty           CONSTANT VARCHAR2(100) := '�ړ���';
  cv_msg_wk_output          CONSTANT VARCHAR2(100) := '�o�̓��[�N�e�[�u��';
--
  --���ڂ̃T�C�Y
  cv_column_len_01          CONSTANT NUMBER := 30;                              -- �����Z�b�g��
  cv_column_len_02          CONSTANT NUMBER := 80;                              -- �����Z�b�g�E�v
  cv_column_len_03          CONSTANT NUMBER := 1;                               -- �����Z�b�g�敪
  cv_column_len_04          CONSTANT NUMBER := 1;                               -- ������^�C�v
  cv_column_len_05          CONSTANT NUMBER := 3;                               -- �g�D�R�[�h
  cv_column_len_06          CONSTANT NUMBER := 7;                               -- �i�ڃR�[�h
  cv_column_len_07          CONSTANT NUMBER := 1;                               -- �����\���\/�\�[�X���[���^�C�v
  cv_column_len_08          CONSTANT NUMBER := 30;                              -- �����\���\/�\�[�X���[���^�C�v��
  cv_column_len_09          CONSTANT NUMBER := 1;                               -- �폜�t���O
  cv_column_len_10          CONSTANT NUMBER := 1;                               -- �o�׋敪
  cv_column_len_11          CONSTANT NUMBER := 2;                               -- �N�x����
  --�K�{����
  cv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- �K�{����
  cv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL����
  cv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- �C�Ӎ���
  --���t�^�t�H�[�}�b�g
  cv_date_format            CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- �N����
  cv_date_format_slash      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- �N/��/��
  cv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- �N���������b(24���ԕ\�L)
  cv_month_format           CONSTANT VARCHAR2(8)   := 'MM';                     -- ���x�w��q(��)
  --�����Z�b�g�敪
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- ��{�����v��
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- ���ʉ����v��
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- �H��o�׌v��
  --������^�C�v
  cv_global                 CONSTANT NUMBER        := 1;                        -- �O���[�o��
  cv_item                   CONSTANT NUMBER        := 3;                        -- �i��
  cv_organization           CONSTANT NUMBER        := 4;                        -- �g�D
  cv_item_organization      CONSTANT NUMBER        := 6;                        -- �i��-�g�D
  --�\�[�X���[���^�C�v
  cv_source_rule            CONSTANT NUMBER        := 1;                        -- �\�[�X���[��
  cv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- �����\���\
  --���T�擾�p�R���X�^���g
  cv_sunday                 CONSTANT VARCHAR2(100)        := '��';              -- ���T�J�n���擾�p
  cv_saturday               CONSTANT VARCHAR2(100)        := '�y';              -- ���T�I�����擾�p
  --�v���t�@�C���擾
  cv_master_org_id          CONSTANT VARCHAR2(20)  := 'XXCMN_MASTER_ORG_ID';           -- �v���t�@�C���擾�p �}�X�^�g�D
  cv_profile_name_mo_id     CONSTANT VARCHAR2(20)  := '�}�X�^�g�D';                    -- �v���t�@�C���� �}�X�^�g�D
  --�N�C�b�N�R�[�h�^�C�v
  cv_assign_type_priority   CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';   -- ������^�C�v�D��x
  cv_assign_name            CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';        -- �����Z�b�g��
  cv_flv_language           CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- ����
  cv_flv_enabled_flg_y      CONSTANT VARCHAR2(100) := 'Y';
--
  --���̓p�����[�^
  cv_buy_type               CONSTANT VARCHAR2(1)   := '3';                      -- ��v�敪�ށi�w���v��j
  cv_plan_type_pace         CONSTANT VARCHAR2(100) := '1';                      -- �o�׃y�[�X
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- �o�ח\��
  cv_forcast_type_this      CONSTANT VARCHAR2(100) := '1';                      -- ������
  cv_forcast_type_next      CONSTANT VARCHAR2(100) := '2';                      -- ������
  cv_forcast_type_2month    CONSTANT VARCHAR2(100) := '3';                      -- �����{������
--
--
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- ��v�惌�x���i���x���Q�j
  cv_own_flg_on             CONSTANT VARCHAR2(1)   := '1';                      -- ���H��Ώۃt���OYes
  cn_inactive_ind           CONSTANT NUMBER        := 1;                        -- �����`�F�b�N����
  cv_inv_status_code_inactive CONSTANT VARCHAR2(100) := 'Inactive';             -- ����
  cv_obsolete_class         CONSTANT VARCHAR2(1)   := '1';                      -- �p�~�`�F�b�N����
  cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- �L��
  cn_active_ind_y           CONSTANT NUMBER        := 1;                        -- �L��
  cn_active_ind_n           CONSTANT NUMBER        := 0;                        -- ����
  cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1';                      -- ��v�敪�ށi�o�ח\���j
  cv_plant_ship_type        CONSTANT VARCHAR2(1)   := '2';                      -- ��v�敪�ށi�H��o�׌v��j
  cv_code_class             CONSTANT VARCHAR2(1)   := '4';                      -- �z�����[�h�^�C���R�[�h�N���X�i�q�Ɂj
  cv_plan_typep             CONSTANT VARCHAR2(1)   := '1';                      -- �v��敪�i�o�׃y�[�X�j
  cv_plan_typef             CONSTANT VARCHAR2(1)   := '2';                      -- �v��敪�i�o�ח\���j
  cn_data_lvl_plant         CONSTANT NUMBER        := 0;                        -- �g�D�f�[�^���x��(�H�ꃌ�x��)
  cn_data_lvl_output        CONSTANT NUMBER        := 1;                        -- �g�D�f�[�^���x��(�H��o�׃��x��)
--20090407_Ver1.2_T1_0368_SCS.Uda_ADD_START
  --DISC�i�ڃA�h�I���}�X�^
  cn_xsib_status_temporary  CONSTANT NUMBER := 20;                              -- ���o�^
  cn_xsib_status_registered CONSTANT NUMBER := 30;                              -- �{�o�^
  cn_xsib_status_obsolete   CONSTANT NUMBER := 40;                              -- �p
--20090407_Ver1.2_T1_0368_SCS.Uda_ADD_END
  -- CSV�o�͗p
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
  cv_csv_header1                CONSTANT VARCHAR2(100) := '�o�ד�';
  cv_csv_header2                CONSTANT VARCHAR2(100) := '����';
  cv_csv_header3                CONSTANT VARCHAR2(100) := '�ړ����q�ɂb�c';
  cv_csv_header4                CONSTANT VARCHAR2(100) := '�ړ����q�ɖ�';
  cv_csv_header5                CONSTANT VARCHAR2(100) := '�ړ���q�ɂb�c';
  cv_csv_header6                CONSTANT VARCHAR2(100) := '�ړ���q�ɖ�';
  cv_csv_header7                CONSTANT VARCHAR2(100) := '�i�ڂb�c';
  cv_csv_header8                CONSTANT VARCHAR2(100) := '�i�ږ�';
  cv_csv_header9                CONSTANT VARCHAR2(100) := '�v�搔';
  cv_csv_header10               CONSTANT VARCHAR2(100) := '�O�݌�';
  cv_csv_header11               CONSTANT VARCHAR2(100) := '��݌�';
  cv_csv_header12               CONSTANT VARCHAR2(100) := '�݌ɓ���';
  cv_csv_header13               CONSTANT VARCHAR2(100) := '�o�׃y�[�X';
  cv_csv_header14               CONSTANT VARCHAR2(100) := '�H��ŗL�L��';
  cv_csv_header15               CONSTANT VARCHAR2(100) := '���Y�\���';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p�ϐ�
  gv_plan_type                   VARCHAR2(1);              -- 1.�v��敪
  gd_pace_from                   DATE;                     -- 2.�o�׃y�[�X(����)����FROM
  gd_pace_to                     DATE;                     -- 3.�o�׃y�[�X�i���сj����TO
  gv_forcast_type                VARCHAR2(1);              -- 4.�o�ח\������
  gd_forcast_from                DATE;                     -- �o�ח\������FROM
  gd_forcast_to                  DATE;                     -- �o�ח\������TO
  gn_pace_days                   NUMBER;                   -- �o�׎��щғ�����
  gn_forcast_days                NUMBER;                   -- �o�ח\���ғ�����
--
  gn_under_lvl_pace              NUMBER := 0;              -- ���ʑq�ɏo�׃y�[�X
--
  gv_debug_mode                  VARCHAR2(2) := '';     -- debug�p
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : �e�[�u���f�[�^�폜(A-11)
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf        OUT VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table'; -- �v���O������
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
    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    lr_rowid         rowid_ttype;
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    -- ===============================
    -- �H��o�׌v�惏�[�N�e�[�u��
    -- ===============================
    BEGIN
      --���b�N�̎擾
      SELECT xwsp.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_ship_planning xwsp
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      DELETE FROM xxcop_wk_ship_planning;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
    END;
--
    -- ===============================
    -- �H��o�׌v��o�̓��[�N�e�[�u��
    -- ===============================
    BEGIN
      --���b�N�̎擾
      SELECT xwspo.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_ship_planning_output xwspo
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      DELETE FROM xxcop_wk_ship_planning_output;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
    END;
--
  EXCEPTION
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_table;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_plan_type     IN     VARCHAR2,   -- 1.�v��敪
    iv_shipment_from IN     VARCHAR2,   -- 2.�o�׃y�[�X�v�����(FROM)
    iv_shipment_to   IN     VARCHAR2,   -- 3.�o�׃y�[�X�v�����(TO)
    iv_forcast_type  IN     VARCHAR2,   -- 4.�o�ח\���敪
    ov_errbuf        OUT   VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT   VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT   VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lb_chk_value         BOOLEAN;         -- ���t�^�t�H�[�}�b�g�`�F�b�N����
    lv_invalid_value     VARCHAR2(100);   -- �G���[���b�Z�[�W�l
    lv_profile_name      VARCHAR2(100);   -- �v���t�@�C����
    lv_value             VARCHAR2(100);   -- �v���t�@�C���l
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
    ov_retcode := cv_status_normal;
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
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --���̓p�����[�^�̏o��
    --�v��敪
    lv_errmsg := cv_plan_type_tl || cv_msg_part || iv_plan_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --�o�׃y�[�X�v�����(FROM)
    lv_errmsg := cv_pace_from_tl || cv_msg_part || iv_shipment_from;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --�o�׃y�[�X�v�����(TO)
    lv_errmsg := cv_pace_to_tl || cv_msg_part || iv_shipment_to;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --�o�ח\���敪
    lv_errmsg := cv_forcast_type_tl || cv_msg_part || iv_forcast_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    lv_value := fnd_profile.value( cv_master_org_id );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := cv_profile_name_mo_id;
      RAISE profile_validate_expt;
    END IF;
    --���̓p�����[�^�`�F�b�N
    --�v��敪
    IF ( iv_plan_type = cv_plan_type_pace ) THEN
      IF ( iv_shipment_from IS NULL OR iv_shipment_to IS NULL ) THEN
        RAISE param_invalid_expt;
      END IF;
    ELSIF ( iv_plan_type = cv_plan_type_fgorcate ) THEN
      IF ( iv_forcast_type IS NULL ) THEN
        RAISE param_invalid_expt;
      END IF;
    ELSE
      IF ( iv_shipment_from IS NULL OR iv_shipment_to IS NULL OR iv_forcast_type IS NULL ) THEN
        RAISE param_invalid_expt;
      END IF;
    END IF;
    --�o�׃y�[�X�v�����(FROM)
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_shipment_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := iv_shipment_from;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_from := TO_DATE( iv_shipment_from, cv_date_format_slash );
    --�o�׃y�[�X�v�����(TO)
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_shipment_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := iv_shipment_to;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_to := TO_DATE( iv_shipment_to, cv_date_format_slash );
    --�o�׃y�[�X�v�����(FROM)-�o�׃y�[�X�v�����(TO)�t�]�`�F�b�N
    IF ( gd_pace_from >= gd_pace_to ) THEN
      RAISE reverse_invalid_expt;
    END IF;
    --�o�׃y�[�X�v�����(FROM)�ߋ����`�F�b�N
    IF ( gd_pace_from > cd_sys_date ) THEN
      lv_invalid_value := cv_pace_from_tl;
      RAISE past_date_invalid_expt;
    END IF;
    --�o�׃y�[�X�v�����(TO)�ߋ����`�F�b�N
    IF ( gd_pace_to > cd_sys_date ) THEN
      lv_invalid_value := cv_pace_to_tl;
      RAISE past_date_invalid_expt;
    END IF;
    --�o�ח\�����Ԃ̎擾
    IF ( iv_forcast_type = cv_forcast_type_this ) THEN
      --����
      gd_forcast_from := TRUNC( cd_sys_date, cv_month_format );
      gd_forcast_to   := LAST_DAY( cd_sys_date );
    ELSIF ( iv_forcast_type = cv_forcast_type_next ) THEN
      --����
      gd_forcast_from := ADD_MONTHS( TRUNC( cd_sys_date, cv_month_format ), 1 );
      gd_forcast_to   := LAST_DAY( ADD_MONTHS( cd_sys_date, 1 ) );
    ELSIF ( iv_forcast_type = cv_forcast_type_2month ) THEN
      --����+����
      gd_forcast_from := TRUNC( cd_sys_date, cv_month_format );
      gd_forcast_to   := LAST_DAY( ADD_MONTHS( cd_sys_date, 1 ) );
    ELSE
      --NULL
      gd_forcast_from := NULL;
      gd_forcast_to   := NULL;
    END IF;
    --
  -- ���[�N�e�[�u���f�[�^�폜
    delete_table(
            ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
    );
    IF lv_retcode = cv_status_error THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00042
                     ,iv_token_name1  => cv_msg_00042_token_1
                     ,iv_token_value1 =>cv_msg_wk_tbl || '�A' || cv_msg_wk_tbl_output
                   );
      lv_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00002
                     ,iv_token_name1  => cv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
      ov_retcode := cv_status_error;
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    WHEN param_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00055
                   );
      ov_retcode := cv_status_error;
    WHEN date_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00011
                     ,iv_token_name1  => cv_msg_00011_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      ov_retcode := cv_status_error;
    WHEN reverse_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00025
                     ,iv_token_name1  => cv_msg_00025_token_1
                     ,iv_token_value1 => cv_pace_from_tl
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => cv_pace_to_tl
                   );
      ov_retcode := cv_status_error;
    WHEN past_date_invalid_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_plant_mark
   * Description      : �H��ŗL�L���擾�����iA-21�j
   ***********************************************************************************/
  PROCEDURE get_plant_mark(
    io_xwsp_rec            IN OUT XXCOP_WK_SHIP_PLANNING%ROWTYPE,    --   �H��o�׃��[�N���R�[�h�^�C�v
    ov_errbuf                OUT VARCHAR2,                                  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_plant_mark'; -- �v���O������
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
    ov_retcode := cv_status_normal;
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
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    --�H��ŗL�L���擾�����擾
    BEGIN
      SELECT ffmb.attribute6
      INTO   io_xwsp_rec.plant_mark
      FROM   fm_matl_dtl      fmd
         ,   fm_form_mst_b  ffmb
      WHERE  fmd.formula_id = ffmb.formula_id
      AND    fmd.item_id = io_xwsp_rec.item_id
      AND    ffmb.attribute6 is not null
      AND    ROWNUM = 1
      ;
    EXCEPTION
      --�����f�[�^���Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        ov_retcode := cv_status_warn;
    END;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_plant_mark;
--
  /**********************************************************************************
   * Procedure Name   : insert_wk_tbl
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-22)
   ***********************************************************************************/
  PROCEDURE insert_wk_tbl(
    ir_xwsp_rec         IN  xxcop_wk_ship_planning%ROWTYPE,    --   �H��o�׃��[�N���R�[�h�^�C�v
    ov_errbuf           OUT VARCHAR2,                           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,                           --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_wk_tbl'; -- �v���O������
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
    ov_retcode := cv_status_normal;
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
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    BEGIN
    --�t�@�C���A�b�v���[�h�e�[�u���f�[�^�o�^����
      INSERT INTO xxcop_wk_ship_planning(
         transaction_id
        ,org_data_lvl
        ,plant_org_id
        ,plant_org_code
        ,plant_org_name
        ,plant_mark
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,prod_class_code
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_org_forcast_stock
        ,ship_org_onhand_qty
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_org_forcast_stock
        ,receipt_org_onhand_qty
        ,cnt_ship_org
        ,shipping_date
        ,receipt_date
        ,delivery_lead_time
        ,shipping_pace
        ,under_lvl_pace
        ,schedule_qty
        ,before_stock
        ,after_stock
        ,stock_days
        ,assignment_set_type
        ,assignment_type
        ,sourcing_rule_type
        ,sourcing_rule_name
        ,shipping_type
        ,set_qty
        ,movement_qty
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      VALUES(
         ir_xwsp_rec.transaction_id
        ,ir_xwsp_rec.org_data_lvl
        ,ir_xwsp_rec.plant_org_id
        ,ir_xwsp_rec.plant_org_code
        ,ir_xwsp_rec.plant_org_name
        ,ir_xwsp_rec.plant_mark
        ,ir_xwsp_rec.own_flg
        ,ir_xwsp_rec.inventory_item_id
        ,ir_xwsp_rec.item_id
        ,ir_xwsp_rec.item_no
        ,ir_xwsp_rec.item_name
        ,ir_xwsp_rec.prod_class_code
        ,ir_xwsp_rec.num_of_case
        ,ir_xwsp_rec.palette_max_cs_qty
        ,ir_xwsp_rec.palette_max_step_qty
        ,ir_xwsp_rec.product_schedule_date
        ,ir_xwsp_rec.product_schedule_qty
        ,ir_xwsp_rec.ship_org_id
        ,ir_xwsp_rec.ship_org_code
        ,ir_xwsp_rec.ship_org_name
        ,ir_xwsp_rec.ship_org_forcast_stock
        ,ir_xwsp_rec.ship_org_onhand_qty
        ,ir_xwsp_rec.receipt_org_id
        ,ir_xwsp_rec.receipt_org_code
        ,ir_xwsp_rec.receipt_org_name
        ,ir_xwsp_rec.receipt_org_forcast_stock
        ,ir_xwsp_rec.receipt_org_onhand_qty
        ,ir_xwsp_rec.cnt_ship_org
        ,ir_xwsp_rec.shipping_date
        ,ir_xwsp_rec.receipt_date
        ,ir_xwsp_rec.delivery_lead_time
        ,ir_xwsp_rec.shipping_pace
        ,ir_xwsp_rec.under_lvl_pace
        ,ir_xwsp_rec.schedule_qty
        ,ir_xwsp_rec.before_stock
        ,ir_xwsp_rec.after_stock
        ,ir_xwsp_rec.stock_days
        ,ir_xwsp_rec.assignment_set_type
        ,ir_xwsp_rec.assignment_type
        ,ir_xwsp_rec.sourcing_rule_type
        ,ir_xwsp_rec.sourcing_rule_name
        ,ir_xwsp_rec.shipping_type
        ,ir_xwsp_rec.set_qty
        ,ir_xwsp_rec.movement_qty
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
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_msg_wk_tbl
                     );
        RAISE internal_process_expt;
    END;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_wk_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_schedule_date
   * Description      : ����Y�v��擾�iA-2�j
   ***********************************************************************************/
  PROCEDURE get_schedule_date(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE       --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf           OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_schedule_date'; -- �v���O������
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
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_product_schedule_qty  xxcop_wk_ship_planning.product_schedule_qty%TYPE;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
    ln_item_status        xxcmm_system_items_b.item_status%TYPE;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_START
    ln_item_code          xxcmm_system_items_b.item_code%TYPE;
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_END
--
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec     xxcop_wk_ship_planning%ROWTYPE := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_START
    --�g�D���擾����
    xxcop_common_pkg2.get_org_info(
      in_organization_id     =>   io_xwsp_rec.plant_org_id,  --   �g�DID
      ov_organization_code   =>   lv_organization_code,      --   �g�D�R�[�h
      ov_whse_name           =>   lv_organization_name,      --   �q�ɖ�
      ov_errmsg              =>   lv_errmsg,                 --   �G���[�E���b�Z�[�W
      ov_errbuf              =>   lv_errbuf,                 --   ���^�[���E�R�[�h
      ov_retcode             =>   lv_retcode                 --   ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
                    );
      RAISE internal_process_expt;
    END IF;
    --
    -- �H��o�׃��[�N�g�D���Z�b�g
    io_xwsp_rec.ship_org_id         := io_xwsp_rec.plant_org_id;  -- �o�בg�DID
    io_xwsp_rec.plant_org_code      := lv_organization_code;      -- �H��g�D�R�[�h
    io_xwsp_rec.ship_org_code       := lv_organization_code;      -- �o�בg�D�R�[�h
    io_xwsp_rec.plant_org_name      := lv_organization_name;      -- �H��g�D����
    io_xwsp_rec.ship_org_name       := lv_organization_name;      -- �o�בg�D����
    --
    --�i�ڃX�e�[�^�X�擾����
    SELECT xsib.item_status,msib.segment1
    INTO   ln_item_status,ln_item_code
    FROM  xxcmm_system_items_b  xsib
         ,mtl_system_items_b    msib
    WHERE xsib.item_status_apply_date     <= cd_sys_date
    AND   xsib.item_code                   = msib.segment1
    AND   msib.inventory_item_id           = io_xwsp_rec.inventory_item_id
    AND   msib.organization_id             = to_number(fnd_profile.value(cv_master_org_id));
    IF ln_item_status NOT IN (cn_xsib_status_temporary,cn_xsib_status_registered,cn_xsib_status_obsolete) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10042
                      ,iv_token_name1  => cv_msg_10042_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_code
                      ,iv_token_name2  => cv_msg_10042_token_2
                      ,iv_token_value2 => ln_item_code
                      ,iv_token_name3  => cv_msg_10042_token_3
                      ,iv_token_value3 => TO_CHAR(io_xwsp_rec.product_schedule_date,cv_date_format_slash)
                      ,iv_token_name4  => cv_msg_10042_token_4
                      ,iv_token_value4 => TO_CHAR(ln_item_status)
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      RAISE item_status_expt;
    END IF;
--20090414_Ver1.2_T1_0542_SCS_Uda_ADD_END
    --�i�ڏ��擾����
    xxcop_common_pkg2.get_item_info(
       in_inventory_item_id  =>   io_xwsp_rec.inventory_item_id  --   �݌ɕi��ID
      ,on_item_id            =>   io_xwsp_rec.item_id            --   OPM�i��ID
      ,ov_item_no            =>   io_xwsp_rec.item_no            --   OPM�i�ڃR�[�h
      ,ov_item_name          =>   io_xwsp_rec.item_name          --   OPM�i�ږ�
      ,ov_prod_class_code    =>   io_xwsp_rec.prod_class_code    --   ���i�敪
      ,on_num_of_case        =>   io_xwsp_rec.num_of_case        --   �P�[�X����
      ,ov_errbuf             =>   lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            =>   lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             =>   lv_errmsg                      --   ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.inventory_item_id
                    );
      RAISE internal_process_expt;
    END IF;
    --
    IF NVL(io_xwsp_rec.num_of_case,0) = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00061
                      ,iv_token_name1  => cv_msg_00061_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part || io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    ln_product_schedule_qty := io_xwsp_rec.product_schedule_qty ;
    --
--20090414_Ver1.2_T1_0542_SCS_Uda_DEL_START
--    --�g�D���擾����
--    xxcop_common_pkg2.get_org_info(
--      in_organization_id     =>   io_xwsp_rec.plant_org_id,  --   �g�DID
--      ov_organization_code   =>   lv_organization_code,      --   �g�D�R�[�h
--      ov_whse_name           =>   lv_organization_name,      --   �q�ɖ�
--      ov_errmsg              =>   lv_errmsg,                 --   �G���[�E���b�Z�[�W
--      ov_errbuf              =>   lv_errbuf,                 --   ���^�[���E�R�[�h
--      ov_retcode             =>   lv_retcode                 --   ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--    IF lv_retcode = cv_status_error THEN
--      RAISE global_api_expt;
--    ELSIF lv_retcode = cv_status_warn THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_00050
--                      ,iv_token_name1  => cv_msg_00050_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
--                    );
--      RAISE internal_process_expt;
--    END IF;
--    --
--    -- �H��o�׃��[�N�g�D���Z�b�g
--    io_xwsp_rec.ship_org_id         := io_xwsp_rec.plant_org_id;  -- �o�בg�DID
--    io_xwsp_rec.plant_org_code      := lv_organization_code;      -- �H��g�D�R�[�h
--    io_xwsp_rec.ship_org_code       := lv_organization_code;      -- �o�בg�D�R�[�h
--    io_xwsp_rec.plant_org_name      := lv_organization_name;      -- �H��g�D����
--    io_xwsp_rec.ship_org_name       := lv_organization_name;      -- �o�בg�D����
--    --
----20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
--    SELECT item_status
--    INTO   ln_item_status
--    FROM  xxcmm_system_items_b
--    WHERE item_status_apply_date     <= cd_sys_date
--    AND   item_id                     = io_xwsp_rec.item_id;
--    IF ln_item_status NOT IN (cn_xsib_status_temporary,cn_xsib_status_registered,cn_xsib_status_obsolete) THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_10042
--                      ,iv_token_name1  => cv_msg_10042_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_code
--                      ,iv_token_name2  => cv_msg_10042_token_2
--                      ,iv_token_value2 => io_xwsp_rec.item_no
--                      ,iv_token_name3  => cv_msg_10042_token_3
--                      ,iv_token_value3 => TO_CHAR(io_xwsp_rec.product_schedule_date,cv_date_format_slash)
--                      ,iv_token_name4  => cv_msg_10042_token_4
--                      ,iv_token_value4 => TO_CHAR(ln_item_status)
--                    );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
--      RAISE item_status_expt;
--    END IF;
----20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
--20090414_Ver1.2_T1_0542_SCS_Uda_DEL_END
    -- �g�D�i�ڃ`�F�b�N����
    xxcop_common_pkg2.chk_item_exists(
       in_inventory_item_id => io_xwsp_rec.inventory_item_id
      ,in_organization_id   => io_xwsp_rec.ship_org_id
      ,ov_errbuf            => lv_errbuf
      ,ov_retcode           => lv_retcode
      ,ov_errmsg            => lv_errmsg
    );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.plant_org_id
                    );
      RAISE internal_process_expt;
    END IF;
    -- �H��ŗL�L���擾
    get_plant_mark(
      io_xwsp_rec          =>   io_xwsp_rec,  --   �H��o�׃��[�N���R�[�h�^�C�v
      ov_errmsg            =>   lv_errmsg,    --   �G���[�E���b�Z�[�W
      ov_errbuf            =>   lv_errbuf,    --   ���^�[���E�R�[�h
      ov_retcode           =>   lv_retcode    --   ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10025
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_START
--                      ,iv_token_name1  => cv_msg_10025_token_1
--                      ,iv_token_value1 => io_xwsp_rec.plant_org_code || cv_msg_org_name || cv_pm_part || io_xwsp_rec.plant_org_name
                      ,iv_token_name1  => cv_msg_10025_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no
                      ,iv_token_name2  => cv_msg_10025_token_2
                      ,iv_token_value2 => io_xwsp_rec.item_name
--20090407_Ver1.2_T1_0281_SCS_Uda_MOD_END
                    );
      RAISE internal_process_expt;
    END IF;
    -- �z���P�ʎ擾����
    xxcop_common_pkg2.get_unit_delivery(
       in_item_id               =>   io_xwsp_rec.item_id                --   OPM�i��ID
      ,id_ship_date             =>   io_xwsp_rec.product_schedule_date  --   ���Y�\���
      ,on_palette_max_cs_qty    =>   io_xwsp_rec.palette_max_cs_qty     --   �z��
      ,on_palette_max_step_qty  =>   io_xwsp_rec.palette_max_step_qty   --   �i��
      ,ov_errmsg                =>   lv_errmsg                          --   �G���[�E���b�Z�[�W
      ,ov_errbuf                =>   lv_errbuf                          --   ���^�[���E�R�[�h
      ,ov_retcode               =>   lv_retcode                         --   ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF lv_retcode = cv_status_error THEN
      RAISE global_api_expt;
    ELSIF lv_retcode = cv_status_warn THEN
      --�G���[���b�Z�[�W�o��
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00057
                      ,iv_token_name1  => cv_msg_00057_token_1
                      ,iv_token_value1 => cv_msg_item || cv_pm_part || io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part ||io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    --�z���P�ʃ[���G���[
    IF io_xwsp_rec.palette_max_cs_qty = 0 OR io_xwsp_rec.palette_max_step_qty = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00059
                      ,iv_token_name1  => cv_msg_00059_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no || cv_msg_item_name || cv_pm_part ||io_xwsp_rec.item_name
                    );
      RAISE internal_process_expt;
    END IF;
    --
    -- �H��o�׌v�惏�[�N�e�[�u���o�^����
    insert_wk_tbl(
      ir_xwsp_rec          =>   io_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
      ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
      ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
      ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF lv_retcode = cv_status_error THEN
      RAISE internal_process_expt;
    END IF;
    --
  EXCEPTION
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
    WHEN item_status_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
  END get_schedule_date;
--
--
  /**********************************************************************************
   * Function Name    : get_cnt_from_org
   * Description      : �e�q�Ɍ����擾����(A-31)
   ***********************************************************************************/
  FUNCTION get_cnt_from_org(
    in_inventory_item_id     IN NUMBER,
    in_organization_id       IN NUMBER,
--    id_product_schedule_date IN DATE,
    ov_errbuf                OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    RETURN NUMBER IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cnt_from_org'; -- �v���O������
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
    ln_cnt_factory_plan NUMBER := 0;
    ln_cnt_base_plan    NUMBER := 0;
    on_count_from_org   NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    --�o�H���擾�J�[�\��(������o��)
    --�H��o�א���}�X�^�e�����擾
    SELECT COUNT(source_organization_id)
    INTO ln_cnt_factory_plan
    FROM(
      SELECT
        inventory_item_id                                                   --�݌ɕi��ID
       ,organization_id                                                     --�g�DID
       ,source_organization_id                                              --�o�בg�D
       ,receipt_organization_id                                             --����g�D
       ,own_flg                                                             --���q�Ƀt���O
       ,ship_plan_type                                                      --�o�׌v��敪
       ,yusen                                                               --������D��x
       ,row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --�݌ɕi��ID
          ,organization_id         organization_id                          --�g�DID
          ,source_organization_id  source_organization_id                   --�o�בg�D
          ,receipt_organization_id receipt_organization_id                  --����g�D
          ,own_flg                 own_flg                                  --���q�Ƀt���O
          ,ship_plan_type                                                   --�o�׌v��敪
          ,yusen                                                            --������D��x
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_factory_ship_plan   --�H��o�׌v��
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = in_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR     msa.inventory_item_id        IS NULL)
              AND    msro.receipt_organization_id  = in_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language)
        )
      )
      WHERE row_number <= 1
    );
    --��{����������}�X�^�e�����擾
    SELECT COUNT(source_organization_id)
    INTO ln_cnt_base_plan
    FROM(
      SELECT
        inventory_item_id                                                   --�݌ɕi��ID
       ,organization_id                                                     --�g�DID
       ,source_organization_id                                              --�o�בg�D
       ,receipt_organization_id                                             --����g�D
       ,own_flg                                                             --���q�Ƀt���O
       ,ship_plan_type                                                      --�o�׌v��敪
       ,yusen                                                               --������D��x
       ,row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --�݌ɕi��ID
          ,organization_id         organization_id                          --�g�DID
          ,source_organization_id  source_organization_id                   --�o�בg�D
          ,receipt_organization_id receipt_organization_id                  --����g�D
          ,own_flg                 own_flg                                  --���q�Ƀt���O
          ,ship_plan_type                                                   --�o�׌v��敪
          ,yusen                                                            --������D��x
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_base_plan           --��{�������v��
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = in_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR     msa.inventory_item_id        IS NULL)
              AND    msro.receipt_organization_id  = in_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language)
        )
      )
      WHERE row_number <= 1
    );
    on_count_from_org := ln_cnt_base_plan + ln_cnt_factory_plan;
    RETURN on_count_from_org;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      RETURN 0;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      RETURN 0;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      RETURN 0;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cnt_from_org;
--
  /**********************************************************************************
   * Procedure Name   : get_plant_shipping
   * Description      : �H��o�׌v�搧��}�X�^�擾�iA-3�j
   ***********************************************************************************/
  PROCEDURE get_plant_shipping(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE  --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf           OUT VARCHAR2                           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2                           --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)                          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_plant_shipping'; -- �v���O������
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
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_after_stock        xxcop_wk_ship_planning.after_stock%TYPE;
    ln_sum_of_pace        NUMBER := 0;
    ln_cnt_from_org       NUMBER := 0;
    ln_own_flg_cnt        NUMBER := 0;
    ld_product_schedule_date        DATE := NULL;
    ln_pace_days          NUMBER := 0;
    ln_forcast_days       NUMBER := 0;
    ln_loop_cnt           NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�H��q�Ƀf�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
        transaction_id
       ,org_data_lvl
       ,plant_org_id
       ,plant_org_code
       ,plant_org_name
       ,plant_mark
       ,inventory_item_id
       ,item_id
       ,item_no
       ,item_name
       ,prod_class_code
       ,num_of_case
       ,palette_max_cs_qty
       ,palette_max_step_qty
       ,product_schedule_date
       ,product_schedule_qty
       ,ship_org_id
       ,ship_org_code
       ,ship_org_name
       ,shipping_date
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_plant
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code
      ;
    --�o�H���擾�J�[�\��(�o�ׁ����)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id                                                   --�݌ɕi��ID
       ,organization_id                                                     --�g�DID
       ,source_organization_id                                              --�o�בg�D
       ,receipt_organization_id                                             --����g�D
       ,own_flg                                                             --���q�Ƀt���O
       ,ship_plan_type                                                      --�o�׌v��敪
       ,yusen                                                               --������D��x
       ,row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --�݌ɕi��ID
          ,organization_id         organization_id                          --�g�DID
          ,source_organization_id  source_organization_id                   --�o�בg�D
          ,receipt_organization_id receipt_organization_id                  --����g�D
          ,own_flg                 own_flg                                  --���q�Ƀt���O
          ,ship_plan_type                                                   --�o�׌v��敪
          ,yusen                                                            --������D��x
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
          SELECT
            keiro.inventory_item_id       inventory_item_id                 --�݌ɕi��ID
           ,keiro.organization_id         organization_id                   --�g�DID
           ,keiro.sourcing_rule_type      sourcing_rule_type                --�\�[�X���[���^�C�v
           ,keiro.source_organization_id  source_organization_id            --�o�בg�D
           ,keiro.receipt_organization_id receipt_organization_id           --����g�D
           ,keiro.own_flg                 own_flg                           --���q�Ƀt���O
           ,CASE WHEN dummy.yusen IS NOT NULL THEN dummy.ship_plan_type
                 ELSE keiro.ship_plan_type
            END                           ship_plan_type                    --�o�׌v��敪
           ,keiro.yusen                   yusen                             --������D��x
          FROM(
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_factory_ship_plan   --�H��o�׌v��
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_factory_ship_plan
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = to_number(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)         >= cd_sys_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
              ORDER BY yusen
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
            )
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
            WHERE ROWNUM = 1
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
    ;
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�N�e�[�u�����f�[�^���o
    <<get_wk_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --
      --�ϐ�������
      lr_xwsp_rec := NULL;
      ln_loop_cnt := 0;
      ln_own_flg_cnt := 0;
      --
      --�H��o�׃��[�N���R�[�h�Z�b�g
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --�H��o�׌v��Work�e�[�u��ID
      lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                              --�g�D�f�[�^���x��
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --�H��g�D
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --�H��q�ɃR�[�h
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --�H��q�ɖ�
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --�H��ŗL�L��
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --�݌ɕi��ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM�i��ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --�i�ڃR�[�h
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --�i�ږ���
      lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --���i�敪
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --�P�[�X����
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --�z��
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --�i��
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --���Y�\���
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --���Y�v�搔
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --�ړ����g�D
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --�ړ����q�ɃR�[�h
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --�ړ����q�ɖ�
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --�o�ד�
      --
      --�J�[�\���ϐ����
      ln_organization_id   := lr_xwsp_rec.ship_org_id;
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
      --
      --�H��o�׌v�搧��}�X�^������g�D�f�[�^���o�i�o�ׁ�����j
      <<get_plant_ship_loop>>
      FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
        ln_loop_cnt := ln_loop_cnt + 1;
        --���[�v�ϐ��Z�b�g
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
        lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
        --===================================
        --����g�D���擾����
        --===================================
        xxcop_common_pkg2.get_org_info(
          in_organization_id     =>   get_plant_ship_rec.receipt_organization_id,  --   �g�DID
          ov_organization_code   =>   lv_organization_code,                        --   �g�D�R�[�h
          ov_whse_name           =>   lv_organization_name,                        --   �q�ɖ�
          ov_errmsg              =>   lv_errmsg,                                   --   �G���[�E���b�Z�[�W
          ov_errbuf              =>   lv_errbuf,                                   --   ���^�[���E�R�[�h
          ov_retcode             =>   lv_retcode                                   --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        ELSIF lv_retcode = cv_status_warn THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => get_plant_ship_rec.receipt_organization_id
                        );
          RAISE internal_process_expt;
        END IF;
        --
        -- �H��o�׃��[�N����g�D���Z�b�g
        lr_xwsp_rec.receipt_org_id      := get_plant_ship_rec.receipt_organization_id;  -- ����g�DID
        lr_xwsp_rec.receipt_org_code    := lv_organization_code;                        -- ����g�D�R�[�h
        lr_xwsp_rec.receipt_org_name    := lv_organization_name;                        -- ����g�D����
        --
        --===================================
        -- �z�����[�h�^�C���擾����
        --===================================
        xxcop_common_pkg2.get_deliv_lead_time(
           iv_from_org_code     =>   lr_xwsp_rec.ship_org_code          --   �o�בg�D�R�[�h
          ,iv_to_org_code       =>   lr_xwsp_rec.receipt_org_code       --   ����g�D�R�[�h
          ,id_product_date      =>   lr_xwsp_rec.product_schedule_date  --   ���Y�\���
          ,on_delivery_lt       =>   lr_xwsp_rec.delivery_lead_time     --   �z�����[�h�^�C��
          ,ov_errmsg            =>   lv_errmsg                          --   �G���[�E���b�Z�[�W
          ,ov_errbuf            =>   lv_errbuf                          --   ���^�[���E�R�[�h
          ,ov_retcode           =>   lv_retcode                         --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        ELSIF lv_retcode = cv_status_warn THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_org_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        --
        --�����v�Z
        IF NVL(lr_xwsp_rec.delivery_lead_time,0) <> 0 THEN
          lr_xwsp_rec.receipt_date := lr_xwsp_rec.shipping_date + lr_xwsp_rec.delivery_lead_time;
        ELSE
          lr_xwsp_rec.receipt_date := lr_xwsp_rec.shipping_date;
          lr_xwsp_rec.delivery_lead_time := 0;
        END IF;
        --===================================
        -- ���q�ɏo�׃y�[�X�擾����
        --===================================
        IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
          OR
           ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
          --�o�׎��ю擾����
          xxcop_common_pkg2.get_num_of_shipped(
              iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   ����g�D�R�[�h
             ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM�i�ڃR�[�h
             ,id_plan_date_from    =>   gd_pace_from                  --   �o�׃y�[�X(����)����FROM
             ,id_plan_date_to      =>   gd_pace_to                    --   �o�׃y�[�X�i���сj����TO
             ,on_quantity          =>   ln_sum_of_pace                --   ���o�׎��ѐ�
             ,ov_errmsg            =>   lv_errmsg                     --   �G���[�E���b�Z�[�W
             ,ov_errbuf            =>   lv_errbuf                     --   ���^�[���E�R�[�h
             ,ov_retcode           =>   lv_retcode                    --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          --  �o�׎��щғ������擾
          xxcop_common_pkg2.get_working_days(
              in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   ����g�DID
             ,id_from_date       =>   gd_pace_from
             ,id_to_date         =>   gd_pace_to
             ,on_working_days    =>   ln_pace_days
             ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
             ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
             ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          IF ln_pace_days = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00056
                           ,iv_token_name1  => cv_msg_00056_token_1
                           ,iv_token_value1 => gd_pace_from
                           ,iv_token_name2  => cv_msg_00056_token_2
                           ,iv_token_value2 => gd_pace_to
                         );
            RAISE internal_process_expt;
          END IF;
          IF ln_sum_of_pace <> 0 AND ln_pace_days <> 0 THEN
            lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --���q�ɏo�׃y�[�X�Z�o
          ELSE
            lr_xwsp_rec.shipping_pace := 0;
          END IF;
          --
        ELSIF
          ( gv_plan_type IS NULL
            AND
            NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
          )
          OR
          ( gv_plan_type = cv_plan_typef
            AND
            NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
          ) THEN
          --�o�ח\���擾����
          xxcop_common_pkg2.get_num_of_forcast(
              in_organization_id   =>   lr_xwsp_rec.receipt_org_id,    --   ����g�D�R�[�h
              in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id, --   OPM�i�ڃR�[�h
              id_plan_date_from    =>   gd_forcast_from,               --   �o�׃y�[�X(����)����FROM
              id_plan_date_to      =>   gd_forcast_to,                 --   �o�׃y�[�X�i���сj����TO
              on_quantity          =>   ln_sum_of_pace,                --   ���o�׎��ѐ�
              ov_errmsg            =>   lv_errmsg,                     --   �G���[�E���b�Z�[�W
              ov_errbuf            =>   lv_errbuf,                     --   ���^�[���E�R�[�h
              ov_retcode           =>   lv_retcode                     --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          --  �o�ח\���ғ������擾
          xxcop_common_pkg2.get_working_days(
              in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   ����g�DID
             ,id_from_date       =>   gd_forcast_from
             ,id_to_date         =>   gd_forcast_to
             ,on_working_days    =>   ln_forcast_days
             ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
             ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
             ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
          IF ln_forcast_days = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00056
                           ,iv_token_name1  => cv_msg_00056_token_1
                           ,iv_token_value1 => gd_pace_from
                           ,iv_token_name2  => cv_msg_00056_token_2
                           ,iv_token_value2 => gd_pace_to
                         );
            RAISE internal_process_expt;
          END IF;
          IF ln_sum_of_pace <> 0 AND ln_forcast_days <> 0 THEN
            lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_forcast_days);         --���q�ɏo�׃y�[�X�Z�o
          ELSE
            lr_xwsp_rec.shipping_pace := 0;
          END IF;
        ELSE
          --���̓p�����[�^�̐ݒ�ƈقȂ�̂�0���Z�b�g
          lr_xwsp_rec.shipping_pace := 0;
        END IF;
        --===================================
        --�e�g�D�����擾����
        --===================================
        ln_cnt_from_org := get_cnt_from_org(
                              in_inventory_item_id     => lr_xwsp_rec.inventory_item_id
                             ,in_organization_id       => lr_xwsp_rec.receipt_org_id
                             ,ov_errbuf                => lv_errmsg
                             ,ov_retcode               => lv_errbuf
                             ,ov_errmsg                => lv_retcode
                           );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        lr_xwsp_rec.cnt_ship_org := ln_cnt_from_org;
        --
        --�H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF lv_retcode = cv_status_error THEN
          RAISE internal_process_expt;
        END IF;
        --���q�ɑΏۃt���OYes�̏ꍇ
        IF lr_xwsp_rec.own_flg = cv_own_flg_on
        AND ln_own_flg_cnt = 0 THEN
          ln_own_flg_cnt                       := ln_own_flg_cnt + 1;
          lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --�H��o�׌v��Work�e�[�u��ID
          lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                              --�g�D�f�[�^���x��
          lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --�H��g�D
          lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --�H��q�ɃR�[�h
          lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --�H��q�ɖ�
          lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --�݌ɕi��ID
          lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM�i��ID
          lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --�i�ڃR�[�h
          lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --�i�ږ���
          lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --���i�敪
          lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --�P�[�X����
          lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --���Y�\���
          lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --�z��
          lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --�i��
          lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --���Y�v�搔
          lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --�ړ����g�D
          lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --�ړ����q�ɃR�[�h
          lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --�ړ����q�ɖ�
          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --�o�ד�
          lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.ship_org_id;            --�ړ����g�D
          lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.ship_org_code;          --�ړ����q�ɃR�[�h
          lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.ship_org_name;          --�ړ����q�ɖ�
          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.shipping_date;          --�o�ד�
          lr_xwsp_rec.shipping_type            := gv_plan_type;                                    --�o�׌v��敪
          lr_xwsp_rec.delivery_lead_time       := 0;                                               --�z�����[�h�^�C��
          --
          --===================================
          -- ���q�ɏo�׃y�[�X�擾����
          --===================================
          IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
            OR
             ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
            --�o�׎��ю擾����
            xxcop_common_pkg2.get_num_of_shipped(
                iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   ����g�D�R�[�h
               ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM�i�ڃR�[�h
               ,id_plan_date_from    =>   gd_pace_from                  --   �o�׃y�[�X(����)����FROM
               ,id_plan_date_to      =>   gd_pace_to                    --   �o�׃y�[�X�i���сj����TO
               ,on_quantity          =>   ln_sum_of_pace                --   ���o�׎��ѐ�
               ,ov_errmsg            =>   lv_errmsg                     --   �G���[�E���b�Z�[�W
               ,ov_errbuf            =>   lv_errbuf                     --   ���^�[���E�R�[�h
               ,ov_retcode           =>   lv_retcode                     --   ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            --  �o�׎��щғ������擾
            xxcop_common_pkg2.get_working_days(
                in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   ����g�DID
               ,id_from_date       =>   gd_pace_from
               ,id_to_date         =>   gd_pace_to
               ,on_working_days    =>   ln_pace_days
               ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
               ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
               ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            IF ln_pace_days = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00056
                             ,iv_token_name1  => cv_msg_00056_token_1
                             ,iv_token_value1 => gd_pace_from
                             ,iv_token_name2  => cv_msg_00056_token_2
                             ,iv_token_value2 => gd_pace_to
                           );
              RAISE internal_process_expt;
            END IF;
            --
            IF ln_sum_of_pace <> 0 and ln_pace_days <> 0 THEN
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --���q�ɏo�׃y�[�X�Z�o
            ELSE
              lr_xwsp_rec.shipping_pace := 0;
            END IF;
          ELSIF
            ( gv_plan_type IS NULL AND lr_xwsp_rec.shipping_type = cv_plan_typef)
            OR
            ( gv_plan_type = cv_plan_typef AND lr_xwsp_rec.shipping_type = cv_plan_typef) THEN
            --�o�ח\���擾����
            xxcop_common_pkg2.get_num_of_forcast(
                in_organization_id   =>   lr_xwsp_rec.receipt_org_id    --   ����g�D�R�[�h
               ,in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id --   OPM�i�ڃR�[�h
               ,id_plan_date_from    =>   gd_forcast_from               --   �o�׃y�[�X(����)����FROM
               ,id_plan_date_to      =>   gd_forcast_to                 --   �o�׃y�[�X�i���сj����TO
               ,on_quantity          =>   ln_sum_of_pace                --   ���o�׎��ѐ�
               ,ov_errmsg            =>   lv_errmsg                     --   �G���[�E���b�Z�[�W
               ,ov_errbuf            =>   lv_errbuf                     --   ���^�[���E�R�[�h
               ,ov_retcode           =>   lv_retcode                     --   ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            --  �o�ח\���ғ������擾
            xxcop_common_pkg2.get_working_days(
                in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   ����g�DID
               ,id_from_date       =>   gd_forcast_from
               ,id_to_date         =>   gd_forcast_to
               ,on_working_days    =>   ln_forcast_days
               ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
               ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
               ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
            );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            IF ln_forcast_days = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00056
                             ,iv_token_name1  => cv_msg_00056_token_1
                             ,iv_token_value1 => gd_pace_from
                             ,iv_token_name2  => cv_msg_00056_token_2
                             ,iv_token_value2 => gd_pace_to
                           );
              RAISE internal_process_expt;
            END IF;
            --
            IF ln_sum_of_pace <> 0 and ln_forcast_days <> 0 THEN
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_forcast_days);         --���q�ɏo�׃y�[�X�Z�o
            ELSE
              lr_xwsp_rec.shipping_pace := 0;
            END IF;
          ELSE
            ln_sum_of_pace := 0;   --���̓p�����[�^�̐ݒ�ƈقȂ�̂�0���Z�b�g
            lr_xwsp_rec.shipping_pace   := 0;
          END IF;
          --�H��o�׌v�惏�[�N�e�[�u���o�^����
          insert_wk_tbl(
            ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
            ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
            ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
            ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF lv_retcode = cv_status_error THEN
            RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP get_plant_ship_cur;
      IF ln_loop_cnt = 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00062
                       ,iv_token_name1  => cv_msg_00062_token_1
                       ,iv_token_value1 => lr_xwsp_rec.plant_org_code || cv_msg_org_name ||cv_pm_part || lr_xwsp_rec.plant_org_name
                     );
        RAISE internal_process_expt;
      END IF;
    END LOOP get_wk_ship_planning_cur;
    --
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_plant_shipping;
--
--
  /**********************************************************************************
   * Procedure Name   : get_base_yokomst
   * Description      : ��{����������}�X�^�擾�iA-4�j
   ***********************************************************************************/
  PROCEDURE get_base_yokomst(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE  --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf           OUT VARCHAR2                           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2                           --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)                          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_base_yokomst'; -- �v���O������
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
    ln_org_data_lvl       NUMBER := 1;   --���񃋁[�v�̓f�[�^�o�̓��x��
    ln_loop_cnt           NUMBER := 0;   --���[�v�J�E���g
    ln_organization_id    hr_all_organization_units.organization_id%TYPE;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE;
    lv_organization_code  mtl_parameters.organization_code%TYPE;
    lv_organization_name  ic_whse_mst.whse_name%TYPE;
    lv_whse_code          ic_whse_mst.whse_code%TYPE;
    ln_after_stock        xxcop_wk_ship_planning.after_stock%TYPE;
    ln_sum_of_pace        NUMBER := 0;
    ln_cnt_from_org       NUMBER := 0;
    ln_own_flg_cnt        NUMBER := 0;
    ld_product_schedule_date        DATE := NULL;
    ln_pace_days          NUMBER := 0;
    ln_forcast_days       NUMBER := 0;
    ln_loop_chk           NUMBER := 0;
    ln_dual_chk           NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\��
    CURSOR get_wk_ship_planning_cur IS
      SELECT
        transaction_id
       ,org_data_lvl
       ,plant_org_id
       ,plant_org_code
       ,plant_org_name
       ,inventory_item_id
       ,item_id
       ,item_no
       ,item_name
       ,prod_class_code
       ,num_of_case
       ,product_schedule_date
       ,product_schedule_qty
       ,receipt_org_id
       ,receipt_org_code
       ,receipt_org_name
       ,receipt_date
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = ln_org_data_lvl
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code
      ;
    --�o�H���擾�J�[�\��(�o�ׁ����)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id                                                   --�݌ɕi��ID
       ,organization_id                                                     --�g�DID
       ,source_organization_id                                              --�o�בg�D
       ,receipt_organization_id                                             --����g�D
       ,own_flg                                                             --���q�Ƀt���O
       ,ship_plan_type                                                      --�o�׌v��敪
       ,yusen                                                               --������D��x
       ,row_number
      FROM(
        SELECT
           inventory_item_id       inventory_item_id                        --�݌ɕi��ID
          ,organization_id         organization_id                          --�g�DID
          ,source_organization_id  source_organization_id                   --�o�בg�D
          ,receipt_organization_id receipt_organization_id                  --����g�D
          ,own_flg                 own_flg                                  --���q�Ƀt���O
          ,ship_plan_type                                                   --�o�׌v��敪
          ,yusen                                                            --������D��x
          ,row_number()
          OVER(
           PARTITION BY  source_organization_id
                        ,receipt_organization_id
           ORDER BY yusen,sourcing_rule_type DESC
          ) AS  row_number
        FROM(
          SELECT
            keiro.inventory_item_id       inventory_item_id                 --�݌ɕi��ID
           ,keiro.organization_id         organization_id                   --�g�DID
           ,keiro.sourcing_rule_type      sourcing_rule_type                --�\�[�X���[���^�C�v
           ,keiro.source_organization_id  source_organization_id            --�o�בg�D
           ,keiro.receipt_organization_id receipt_organization_id           --����g�D
           ,keiro.own_flg                 own_flg                           --���q�Ƀt���O
           ,CASE WHEN dummy.yusen IS NOT NULL THEN dummy.ship_plan_type
                 ELSE keiro.ship_plan_type
            END                           ship_plan_type                    --�o�׌v��敪
           ,keiro.yusen                   yusen                             --������D��x
          FROM(
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_base_plan   --��{����������}�X�^
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)  >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id                                             --�݌ɕi��ID
             ,organization_id                                               --�g�DID
             ,sourcing_rule_type                                            --�\�[�X���[���^�C�v
             ,source_organization_id                                        --�o�בg�D
             ,receipt_organization_id                                       --����g�D
             ,own_flg                                                       --���q�Ƀt���O
             ,ship_plan_type                                                --�o�׌v��敪
             ,yusen                                                         --������D��x
            FROM(
              SELECT
                msso.source_organization_id   source_organization_id        --�o�בg�DID
               ,msro.receipt_organization_id  receipt_organization_id       --����g�DID
               ,msa.organization_id           organization_id               --�g�DID
               ,msr.sourcing_rule_type        sourcing_rule_type            --�\�[�X���[���^�C�v
               ,msa.inventory_item_id         inventory_item_id             --�݌ɕi��ID
               ,msro.attribute1               own_flg                       --���H��Ώۃt���O
               ,msa.attribute1                ship_plan_type                --�o�׌v��敪
               ,flv.description               yusen                         --������D��x
              FROM
                mrp_assignment_sets    mas                                  --�����Z�b�g�w�b�_�\
               ,mrp_sr_assignments     msa                                  --�����Z�b�g���ו\
               ,mrp_sourcing_rules     msr                                  --�\�[�X���[��/�����\���\
               ,mrp_sr_source_org      msso                                 --�\�[�X���[���o�בg�D�\
               ,mrp_sr_receipt_org     msro                                 --�\�[�X���[������g�D�\
               ,fnd_lookup_values      flv                                  --�N�C�b�N�R�[�h
              WHERE  msa.sourcing_rule_id         = msr.sourcing_rule_id
              AND    msr.sourcing_rule_id         = msro.sourcing_rule_id
              AND    mas.attribute1               = cv_base_plan    --��{����������}�X�^
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= cd_sys_date
                                                      AND NVL(end_date_active,cd_sys_date) >= cd_sys_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = to_number(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= cd_sys_date
              AND    NVL(msro.disable_date,cd_sys_date)           >= cd_sys_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= cd_sys_date
              AND    NVL(flv.end_date_active,cd_sys_date)         >= cd_sys_date
              AND    flv.lookup_code              = to_char(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
              ORDER BY yusen
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
            )
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_START
            WHERE ROWNUM = 1
--20090407_Ver1.2_T1_0277_SCS_Uda_ADD_END
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
    ;
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  --===================================
  --���[�N�e�[�u�����f�[�^���o
  --===================================
    <<lvl_countup_loop>>
    LOOP
      --�ϐ�������
      ln_loop_cnt := 0;
      <<get_wk_loop>>
      FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
        --���[�v�J�E���g�J�E���g�A�b�v
        ln_loop_cnt := ln_loop_cnt + 1;
        --�ϐ�������
        lr_xwsp_rec := NULL;
        --
        --�H��o�׃��[�N���R�[�h�Z�b�g
        lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;         --�H��o�׌v��Work�e�[�u��ID
        lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl + 1;     --�g�D�f�[�^���x��
        lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --�H��g�D
        lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --�H��q�ɃR�[�h
        lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --�H��q�ɖ�
        lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --�݌ɕi��ID
        lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM�i��ID
        lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --�i�ڃR�[�h
        lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --�i�ږ���
        lr_xwsp_rec.prod_class_code          := get_wk_ship_planning_rec.prod_class_code;        --���i�敪
        lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --�P�[�X����
        lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --���Y�\���
        lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --���Y�v�搔
        lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.receipt_org_id;         --�ړ����g�D
        lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.receipt_org_code;       --�ړ����q�ɃR�[�h
        lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.receipt_org_name;       --�ړ����q�ɖ�
        lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.receipt_date;           --�o�ד�
        --
        --�J�[�\���ϐ����
        ln_organization_id   := lr_xwsp_rec.ship_org_id;
        ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
        --
        --�H��o�׌v�搧��}�X�^������g�D�f�[�^���o�i�o�ׁ�����j
        <<get_plant_ship_loop>>
        FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
          --���[�v�ϐ��Z�b�g
          lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;
          lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
          lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
          --
          --===================================
          --����g�D���擾����
          --===================================
          xxcop_common_pkg2.get_org_info(
            in_organization_id     =>   get_plant_ship_rec.receipt_organization_id,  --   �g�DID
            ov_organization_code   =>   lv_organization_code,                        --   �g�D�R�[�h
            ov_whse_name           =>   lv_organization_name,                        --   �q�ɖ�
            ov_errmsg              =>   lv_errmsg,                                   --   �G���[�E���b�Z�[�W
            ov_errbuf              =>   lv_errbuf,                                   --   ���^�[���E�R�[�h
            ov_retcode             =>   lv_retcode                                   --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          ELSIF lv_retcode = cv_status_warn THEN
            lv_errmsg :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_appl_cont
                            ,iv_name         => cv_msg_00050
                            ,iv_token_name1  => cv_msg_00050_token_1
                            ,iv_token_value1 => io_xwsp_rec.plant_org_id
                          );
            RAISE internal_process_expt;
          END IF;
          --
          -- �H��o�׃��[�N����g�D���Z�b�g
          lr_xwsp_rec.receipt_org_id      := get_plant_ship_rec.receipt_organization_id;     -- ����g�DID
          lr_xwsp_rec.receipt_org_code    := lv_organization_code;                 -- ����g�D�R�[�h
          lr_xwsp_rec.receipt_org_name    := lv_organization_name;                 -- ����g�D����
          --
          --===================================
          --����g�D���[�v�`�F�b�N����
          --===================================
          BEGIN
            SELECT COUNT(transaction_id)
            INTO ln_loop_chk
            FROM xxcop_wk_ship_planning
            WHERE transaction_id = lr_xwsp_rec.transaction_id
            AND plant_org_id   = lr_xwsp_rec.plant_org_id
            AND inventory_item_id = lr_xwsp_rec.inventory_item_id
            AND product_schedule_date = lr_xwsp_rec.product_schedule_date
            AND ship_org_id = lr_xwsp_rec.receipt_org_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            NULL;
          END;
          IF ln_loop_chk > 0 THEN
            lv_errmsg :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_appl_cont
                            ,iv_name         => cv_msg_00060
                            ,iv_token_name1  => cv_msg_00060_token_1
                            ,iv_token_value1 => lr_xwsp_rec.receipt_org_code || cv_pm_part || lr_xwsp_rec.receipt_org_name
                          );
            RAISE internal_process_expt;
          END IF;
          --===================================
          --�d�����R�[�h�`�F�b�N����
          --===================================
          BEGIN
            SELECT COUNT(transaction_id)
            INTO ln_dual_chk
            FROM xxcop_wk_ship_planning
            WHERE transaction_id = lr_xwsp_rec.transaction_id
            AND plant_org_id   = lr_xwsp_rec.plant_org_id
            AND inventory_item_id = lr_xwsp_rec.inventory_item_id
            AND product_schedule_date = lr_xwsp_rec.product_schedule_date
            AND receipt_org_id = lr_xwsp_rec.receipt_org_id
            AND ship_org_id = lr_xwsp_rec.ship_org_id;
            IF ln_dual_chk > 0 THEN
              RAISE expt_next_record;
            END IF;
            --
            --===================================
            -- ���q�ɏo�׃y�[�X�擾����
            --===================================
            IF ( gv_plan_type IS NULL AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep)
              OR
               ( gv_plan_type = cv_plan_typep AND NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typep) THEN
              --===================================
              --�o�׎��ю擾����
              --===================================
              xxcop_common_pkg2.get_num_of_shipped(
                  iv_organization_code =>   lr_xwsp_rec.receipt_org_code  --   ����g�D�R�[�h
                 ,iv_item_no           =>   lr_xwsp_rec.item_no           --   OPM�i�ڃR�[�h
                 ,id_plan_date_from    =>   gd_pace_from                  --   �o�׃y�[�X(����)����FROM
                 ,id_plan_date_to      =>   gd_pace_to                    --   �o�׃y�[�X�i���сj����TO
                 ,on_quantity          =>   ln_sum_of_pace                --   ���o�׎��ѐ�
                 ,ov_errmsg            =>   lv_errmsg                     --   �G���[�E���b�Z�[�W
                 ,ov_errbuf            =>   lv_errbuf                     --   ���^�[���E�R�[�h
                 ,ov_retcode           =>   lv_retcode                    --   ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              --===================================
              --  �o�׎��щғ������擾
              --===================================
              xxcop_common_pkg2.get_working_days(
                  in_organization_id =>   lr_xwsp_rec.receipt_org_id  --   ����g�DID
                 ,id_from_date       =>   gd_pace_from
                 ,id_to_date         =>   gd_pace_to
                 ,on_working_days    =>   ln_pace_days
                 ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
                 ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
                 ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              IF ln_pace_days = 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_appl_cont
                               ,iv_name         => cv_msg_00056
                               ,iv_token_name1  => cv_msg_00056_token_1
                               ,iv_token_value1 => gd_pace_from
                               ,iv_token_name2  => cv_msg_00056_token_2
                               ,iv_token_value2 => gd_pace_to
                             );
                RAISE internal_process_expt;
              END IF;
              IF ln_sum_of_pace <> 0 AND ln_pace_days <> 0 THEN
                lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace / ln_pace_days);         --���q�ɏo�׃y�[�X�Z�o
              ELSE
                lr_xwsp_rec.shipping_pace := 0;
              END IF;
              --
            ELSIF
              ( gv_plan_type IS NULL
                AND
                NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
              )
              OR
              ( gv_plan_type = cv_plan_typef
                AND
                NVL(lr_xwsp_rec.shipping_type,cv_plan_typep) = cv_plan_typef
              ) THEN
              --===================================
              --�o�ח\���擾����
              --===================================
              xxcop_common_pkg2.get_num_of_forcast(
                  in_organization_id   =>   lr_xwsp_rec.receipt_org_id,    --   ����g�DID
                  in_inventory_item_id =>   lr_xwsp_rec.inventory_item_id, --   �݌ɕi��ID
                  id_plan_date_from    =>   gd_forcast_from,               --   �o�׃y�[�X(�\��)����FROM
                  id_plan_date_to      =>   gd_forcast_to,                 --   �o�׃y�[�X�i�\���j����TO
                  on_quantity          =>   ln_sum_of_pace,                --   ���o�ח\����
                  ov_errmsg            =>   lv_errmsg,                     --   �G���[�E���b�Z�[�W
                  ov_errbuf            =>   lv_errbuf,                     --   ���^�[���E�R�[�h
                  ov_retcode           =>   lv_retcode                     --   ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              --===================================
              --  �o�ח\���ғ������擾
              --===================================
              xxcop_common_pkg2.get_working_days(
                  in_organization_id =>   lr_xwsp_rec.receipt_org_id   --   ����g�DID
                 ,id_from_date       =>   gd_forcast_from
                 ,id_to_date         =>   gd_forcast_to
                 ,on_working_days    =>   ln_forcast_days
                 ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
                 ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
                 ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
              );
              IF lv_retcode = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
              IF ln_forcast_days = 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_appl_cont
                               ,iv_name         => cv_msg_00056
                               ,iv_token_name1  => cv_msg_00056_token_1
                               ,iv_token_value1 => gd_pace_from
                               ,iv_token_name2  => cv_msg_00056_token_2
                               ,iv_token_value2 => gd_pace_to
                             );
                RAISE internal_process_expt;
              END IF;
              IF ln_sum_of_pace <> 0 AND ln_forcast_days <> 0 THEN
                lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace  / ln_forcast_days); --���q�ɏo�׃y�[�X�Z�o
              ELSE
                lr_xwsp_rec.shipping_pace := 0;
              END IF;
            ELSE
              ln_sum_of_pace := 0;   --���̓p�����[�^�̐ݒ�ƈقȂ�̂�0���Z�b�g
              lr_xwsp_rec.shipping_pace := ROUND(ln_sum_of_pace);
            END IF;
            --
            --===================================
            --�e�g�D�����擾����
            --===================================
            ln_cnt_from_org := get_cnt_from_org(
                                  in_inventory_item_id     => lr_xwsp_rec.inventory_item_id
                                 ,in_organization_id       => lr_xwsp_rec.receipt_org_id
                                 ,ov_errbuf                => lv_errmsg
                                 ,ov_retcode               => lv_errbuf
                                 ,ov_errmsg                => lv_retcode
                               );
            IF lv_retcode = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
            lr_xwsp_rec.cnt_ship_org := ln_cnt_from_org;
            --
            --===================================
            --�H��o�׌v�惏�[�N�e�[�u���o�^����
            --===================================
            insert_wk_tbl(
              ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
              ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
              ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
              ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
              );
            IF lv_retcode = cv_status_error THEN
              RAISE internal_process_expt;
            END IF;
          EXCEPTION
            WHEN expt_next_record THEN
              NULL;
          END;
        END LOOP get_plant_ship_cur;
      END LOOP get_wk_ship_planning_cur;
      IF ln_loop_cnt = 0 THEN
        EXIT;
      ELSE
        ln_org_data_lvl := ln_org_data_lvl + 1;
      END IF;
    END LOOP;
    --
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_yokomst;
--
  /**********************************************************************************
   * Procedure Name   : get_pace_sum
   * Description      : �o�׃y�[�X�擾�����iA-51�j
   ***********************************************************************************/
  PROCEDURE get_pace_sum(
    in_receipt_org_id         IN  xxcop_wk_ship_planning.receipt_org_id%TYPE,
    in_plant_org_id           IN  xxcop_wk_ship_planning.plant_org_id%TYPE,
    in_inventory_item_id      IN  xxcop_wk_ship_planning.inventory_item_id%TYPE,
    id_product_schedule_date  IN  xxcop_wk_ship_planning.product_schedule_date%TYPE,
    in_transaction_id         IN  xxcop_wk_ship_planning.transaction_id%TYPE,
    on_undr_lvl_pace          OUT xxcop_wk_ship_planning.under_lvl_pace%TYPE,
    ov_errbuf                 OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pace_sum'; -- �v���O������
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
    ln_loop_cnt    NUMBER := 0;
    ln_undr_lvl_pace NUMBER := 0;
    ln_bro_lvl_pace  NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --
    CURSOR get_wk_cur IS
      SELECT ship_org_id
        ,receipt_org_id
        ,shipping_pace
        ,cnt_ship_org
      FROM   xxcop_wk_ship_planning
      WHERE  ship_org_id            = in_receipt_org_id
        AND  plant_org_id           = in_plant_org_id
        AND  inventory_item_id      = in_inventory_item_id
        AND  product_schedule_date  = id_product_schedule_date
        AND  org_data_lvl           > cn_data_lvl_output
        AND  transaction_id         = in_transaction_id;
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    ln_loop_cnt := 0;
    FOR get_wk_rec IN get_wk_cur LOOP
      ln_loop_cnt := ln_loop_cnt + 1;
      get_pace_sum( in_receipt_org_id         => get_wk_rec.receipt_org_id
                   ,in_plant_org_id           => in_plant_org_id
                   ,in_inventory_item_id      => in_inventory_item_id
                   ,id_product_schedule_date  => id_product_schedule_date
                   ,in_transaction_id         => in_transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_expt;
      END IF;
      ln_bro_lvl_pace := ln_bro_lvl_pace + ROUND((ln_undr_lvl_pace + get_wk_rec.shipping_pace) / get_wk_rec.cnt_ship_org);
    END LOOP;
    IF ln_loop_cnt = 0 THEN
      on_undr_lvl_pace  := 0;
    ELSE
      on_undr_lvl_pace := ln_bro_lvl_pace;
    END IF;
  EXCEPTION
--
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_pace_sum;
--
  /**********************************************************************************
   * Procedure Name   : get_under_lvl_pace
   * Description      : ���ʑq�ɏo�׃y�[�X�擾�����iA-5�j
   ***********************************************************************************/
  PROCEDURE get_under_lvl_pace(
    io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   �H��o�׃��[�N���R�[�h�^�C�v
    ov_errbuf                OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_under_lvl_pace'; -- �v���O������
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
    ln_undr_lvl_pace      NUMBER := 0;        -- ���ʑq�ɏo�׃y�[�X
    ln_undr_lvl_pace_out  NUMBER := 0;        -- ���ʑq�ɏo�׃y�[�X�H��q�Ƀ��x��
    ln_shipping_pace      NUMBER := 0;        -- �o�׃y�[�X
    ln_own_pace           NUMBER := 0;        -- ���q�ɏo�׃y�[�X
    ln_receipt_org_id     NUMBER := NULL;     -- �ړ���g�DID
    ln_plant_org_id       NUMBER := NULL;
    ln_inventory_item_id  NUMBER := NULL;
    ld_schedule_date      DATE;
    ln_lvl                NUMBER := 0;
    ln_indx               NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�o�̓f�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,plant_org_id
        ,inventory_item_id
        ,product_schedule_date
        ,receipt_org_id
        ,shipping_pace
        ,cnt_ship_org
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code;
    --
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --�ϐ�������
      ln_undr_lvl_pace := 0;
      ln_receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
      --���ʑg�D���擾
      get_pace_sum( in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_planning_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_planning_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_planning_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_planning_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      --���q�ɏo�׃y�[�X�{���ʑq�ɏo�׃y�[�X
      ln_undr_lvl_pace := ROUND((get_wk_ship_planning_rec.shipping_pace + ln_undr_lvl_pace) /get_wk_ship_planning_rec.cnt_ship_org);
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = ln_undr_lvl_pace
        WHERE plant_org_id = io_xwsp_rec.plant_org_id
        AND   inventory_item_id = io_xwsp_rec.inventory_item_id
        AND   product_schedule_date = io_xwsp_rec.product_schedule_date
        AND   org_data_lvl = cn_data_lvl_output
        AND   transaction_id = io_xwsp_rec.transaction_id
        AND   receipt_org_id = ln_receipt_org_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
    END LOOP get_wk_ship_planning_cur;
    --���ʑq�ɏo�׃y�[�X
    io_xwsp_rec.under_lvl_pace := ln_shipping_pace;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_under_lvl_pace;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_qty
   * Description      : �݌ɐ��擾�����iA-6�j
   ***********************************************************************************/
  PROCEDURE get_stock_qty(
    io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   �H��o�׃��[�N���R�[�h�^�C�v
    ov_errbuf                OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; -- �v���O������
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
    lv_plant_org_code          xxcop_wk_ship_planning.plant_org_code%TYPE := NULL;
    ld_product_schedule_date   xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
    ln_before_stock            xxcop_wk_ship_planning.before_stock%TYPE := NULL;
    ln_num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE := NULL;
    ln_working_days            NUMBER := 0;
    ln_receipt_plan_qty        NUMBER := 0;
    ln_onhand_qty              NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�o�̓f�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,inventory_item_id
        ,item_no
        ,item_id
        ,product_schedule_date
        ,receipt_org_id
        ,receipt_org_code
        ,under_lvl_pace
        ,plant_org_id
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code;
    --
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --�ϐ�������
      ln_before_stock := NULL;
      BEGIN
--20090407_Ver1.2_T1_0278_SCS_Uda_ADD_START
        SELECT
             plant_org_code
          ,  product_schedule_date
          ,  after_stock
          ,  num_of_case
        INTO
             lv_plant_org_code
          ,  ld_product_schedule_date
          ,  ln_before_stock
          ,  ln_num_of_case
        FROM(
--20090407_Ver1.2_T1_0278_SCS_Uda_ADD_END
          SELECT
               plant_org_code
            ,  product_schedule_date
            ,  after_stock
            ,  num_of_case
--20090407_Ver1.2_T1_0278_SCS_Uda_DEL_START
--        INTO
--             lv_plant_org_code
--          ,  ld_product_schedule_date
--          ,  ln_before_stock
--          ,  ln_num_of_case
--20090407_Ver1.2_T1_0278_SCS_Uda_DEL_END
          FROM  xxcop_wk_ship_planning
          WHERE transaction_id = get_wk_ship_planning_rec.transaction_id
            AND org_data_lvl = cn_data_lvl_output
            AND inventory_item_id = get_wk_ship_planning_rec.inventory_item_id
            AND receipt_org_id = get_wk_ship_planning_rec.receipt_org_id
            AND after_stock IS NOT NULL
--20090407_Ver1.2_T1_0278_SCS_Uda_MOD_START
--            AND product_schedule_date < get_wk_ship_planning_rec.product_schedule_date
--            AND ROWNUM = 1
--          ORDER BY product_schedule_date DESC;
          ORDER BY product_schedule_date DESC,plant_org_code DESC
          )
        WHERE ROWNUM = 1;
--20090407_Ver1.2_T1_0278_SCS_Uda_MOD_END
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_before_stock := NULL;
      END;
      --��݌ɂ����q�ɂɑ��݂���Ƃ�
      IF ln_before_stock IS NOT NULL THEN
        --�ғ������擾����
        xxcop_common_pkg2.get_working_days(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   ����g�DID
           ,id_from_date       =>   ld_product_schedule_date
           ,id_to_date         =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_working_days    =>   ln_working_days
           ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --���ɗ\��擾����
        xxcop_common_pkg2.get_stock_plan(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   ����g�DID
           ,iv_item_no         =>   get_wk_ship_planning_rec.item_no
           ,id_plan_date_from  =>   ld_product_schedule_date
           ,id_plan_date_to    =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_quantity        =>   ln_receipt_plan_qty
           ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --�O�݌ɐ��i��݌�(����q�ɂ̓��i�ڂŐ��Y�\������ő�̂��̂̌�݌�) + ���ɗ\�萔 - �o�׃y�[�X * �ғ����j
        ln_before_stock := ln_before_stock + ln_receipt_plan_qty - get_wk_ship_planning_rec.under_lvl_pace * ln_working_days;
      --
      --��݌ɂ����݂��Ȃ��Ƃ�
      ELSE
        --
        --�莝�݌Ɏ擾����
        xxcop_common_pkg2.get_onhand_qty(
            iv_organization_code =>   get_wk_ship_planning_rec.receipt_org_code  --   ����g�DID
           ,in_item_id           =>   get_wk_ship_planning_rec.item_id           --   OPM�i��ID
           ,on_quantity          =>   ln_onhand_qty                              --   �莝�݌ɐ�
           ,ov_errmsg            =>   lv_errmsg                                  --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf            =>   lv_errbuf                                  --   �G���[�E���b�Z�[�W
           ,ov_retcode           =>   lv_retcode                                 --   ���^�[���E�R�[�h
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --�ғ������擾����
        xxcop_common_pkg2.get_working_days(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id           --   ����g�DID
           ,id_from_date       =>   cd_sys_date                                       --   �V�X�e�����t
           ,id_to_date         =>   get_wk_ship_planning_rec.product_schedule_date    --   ���Y�\���
           ,on_working_days    =>   ln_working_days                                   --   �ғ�����
           ,ov_errmsg          =>   lv_errmsg                                         --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf                                         --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode                                        --   ���^�[���E�R�[�h
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --���ɗ\��擾����
        xxcop_common_pkg2.get_stock_plan(
            in_organization_id =>   get_wk_ship_planning_rec.receipt_org_id  --   ����g�DID
           ,iv_item_no         =>   get_wk_ship_planning_rec.item_no
           ,id_plan_date_from  =>   cd_sys_date
           ,id_plan_date_to    =>   get_wk_ship_planning_rec.product_schedule_date
           ,on_quantity        =>   ln_receipt_plan_qty
           ,ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
        );
        IF lv_retcode = cv_status_error THEN
          RAISE global_api_expt;
        END IF;
        --
        --�O�݌ɐ��i��݌�(����q�ɂ̓��i�ڂŐ��Y�\������ő�̂��̂̌�݌�) + ���ɗ\�萔 - �o�׃y�[�X * �ғ����j
        ln_before_stock := ln_onhand_qty + ln_receipt_plan_qty - get_wk_ship_planning_rec.under_lvl_pace * ln_working_days;
      END IF;
      -- �O�݌ɍX�V
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET   before_stock = ln_before_stock
        WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
        AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
        AND   org_data_lvl              = cn_data_lvl_output
        AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
        AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
        AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
        AND   before_stock              IS NULL;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
    END LOOP get_wk_ship_planning_cur;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_stock_qty;
--
--
  /**********************************************************************************
   * Procedure Name   : get_move_qty
   * Description      : �ړ����擾�����iA-7�j
   ***********************************************************************************/
  PROCEDURE get_move_qty(
    io_xwsp_rec              IN OUT xxcop_wk_ship_planning%ROWTYPE,   --   �H��o�׃��[�N���R�[�h�^�C�v
    ov_errbuf                OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_qty'; -- �v���O������
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
    ln_sum_pace NUMBER := 0;
    ln_sum_before_stock NUMBER := 0;
    ln_stock_days NUMBER := 0;
    ln_stock NUMBER := 0;
    ln_product_schedule_qty NUMBER := 0;
    ln_move_qty NUMBER := 0;
    ln_after_stock NUMBER := 0;
    ln_palette_qty NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�o�̓f�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id
        ,plant_org_id
        ,inventory_item_id
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,item_no
        ,item_id
        ,product_schedule_date
        ,receipt_org_id
        ,receipt_org_code
        ,under_lvl_pace
        ,before_stock
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_code;
    --
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    --���o�׃y�[�X�擾
    SELECT
       product_schedule_qty
      ,SUM(NVL(under_lvl_pace,0))
      ,SUM(NVL(before_stock,0))
    INTO
       ln_product_schedule_qty
      ,ln_sum_pace
      ,ln_sum_before_stock
    FROM
      xxcop_wk_ship_planning
    WHERE org_data_lvl          = cn_data_lvl_output
    AND   transaction_id        = io_xwsp_rec.transaction_id
    AND   plant_org_id          = io_xwsp_rec.plant_org_id
    AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
    AND   product_schedule_date = io_xwsp_rec.product_schedule_date
    GROUP BY transaction_id,plant_org_id,plant_org_code
            ,inventory_item_id,item_no,product_schedule_date,product_schedule_qty;
    -- ���v�Z�[���`�F�b�N
    IF NVL(ln_sum_pace,0) = 0 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00058
                     ,iv_token_name1  => cv_msg_00058_token_1
                     ,iv_token_value1 => cv_msg_stock_days
                     ,iv_token_name2  => cv_msg_00058_token_2
                     ,iv_token_value2 => cv_msg_sum_pace
                   );
      RAISE internal_process_expt;
    END IF;
    --
    --�݌ɓ����Z�o
    IF NVL(ln_sum_pace,0) <> 0 THEN
      ln_stock_days := ROUND((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace);
    ELSE
      ln_stock_days := 0;
    END IF;
--
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --�݌ɐ�
      ln_stock := ln_stock_days * get_wk_ship_planning_rec.under_lvl_pace;
      --�ړ���
      IF ln_stock <> 0 THEN
        ln_move_qty :=ln_stock - get_wk_ship_planning_rec.before_stock;
      ELSE
        ln_move_qty := 0;
      END IF;
      --�ړ��p���b�g�ϊ�
      ln_palette_qty := get_wk_ship_planning_rec.num_of_case * get_wk_ship_planning_rec.palette_max_cs_qty * get_wk_ship_planning_rec.palette_max_step_qty;
      --
      IF NVL(ln_palette_qty,0) = 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00058
                       ,iv_token_name1  => cv_msg_00058_token_1
                       ,iv_token_value1 => cv_msg_palette
                       ,iv_token_name2  => cv_msg_00058_token_2
                       ,iv_token_value2 => cv_msg_move_qty
                     );
        RAISE internal_process_expt;
      END IF;
      --�ړ����p���b�g���Z��
      ln_move_qty :=ln_palette_qty * ROUND(ln_move_qty / ln_palette_qty);
      --��݌�
      ln_after_stock := ln_move_qty + get_wk_ship_planning_rec.before_stock;
      --
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET   schedule_qty = ln_move_qty
             ,after_stock = ln_after_stock
             ,stock_days = ln_stock_days
        WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
        AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
        AND   org_data_lvl              = cn_data_lvl_output
        AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
        AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
        AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00028
                          ,iv_token_name1  => cv_msg_00028_token_1
                          ,iv_token_value1 => cv_msg_wk_tbl
                        );
          RAISE internal_process_expt;
      END;
    END LOOP get_wk_ship_planning_cur;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_move_qty;
--
  /**********************************************************************************
   * Procedure Name   : insert_wk_output
   * Description      : �H��o�׌v��o�̓��[�N�e�[�u���쐬�iA-8�j
   ***********************************************************************************/
  PROCEDURE insert_wk_output(
     in_transaction_id   IN NUMBER
    ,ov_errbuf           OUT VARCHAR2                                      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2                                      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)                                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'insert_wk_output'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�N�e�[�u�����f�[�^���o
    INSERT INTO xxcop_wk_ship_planning_output(
      transaction_id
     ,shipping_date
     ,receipt_date
     ,ship_org_code
     ,ship_org_name
     ,receipt_org_code
     ,receipt_org_name
     ,item_no
     ,item_name
     ,schedule_qty
     ,before_stock
     ,after_stock
     ,stock_days
     ,shipping_pace
     ,plant_mark
     ,schedule_date
     ,created_by
     ,creation_date
     ,last_updated_by
     ,last_update_date
     ,last_update_login
     ,request_id
     ,program_application_id
     ,program_id
     ,program_update_date
    )
    SELECT
      transaction_id
     ,shipping_date
     ,receipt_date
     ,ship_org_code
     ,ship_org_name
     ,receipt_org_code
     ,receipt_org_name
     ,item_no
     ,item_name
     ,ROUND(schedule_qty / num_of_case)
     ,ROUND(before_stock / num_of_case)
     ,ROUND(after_stock / num_of_case)
     ,stock_days
     ,ROUND(under_lvl_pace/ num_of_case)
     ,plant_mark
     ,product_schedule_date
     ,created_by
     ,creation_date
     ,last_updated_by
     ,last_update_date
     ,last_update_login
     ,request_id
     ,program_application_id
     ,program_id
     ,program_update_date
    FROM
      xxcop_wk_ship_planning
    WHERE org_data_lvl = cn_data_lvl_output
      AND transaction_id = in_transaction_id
    ORDER BY plant_org_code,item_no,product_schedule_date,receipt_org_code
    ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
  END insert_wk_output;
--
  /**********************************************************************************
   * Procedure Name   : csv_output
   * Description      : �H��o�׌v��CSV�o��(A-9)
   ***********************************************************************************/
  PROCEDURE csv_output(
     in_transaction_id    IN  NUMBER
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_output'; -- �v���O������
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
    -- �G���[���b�Z�[�W
--
    -- *** ���[�J���ϐ� ***
    -- �������ʃ��|�[�g�o�͕�����o�b�t�@
    lv_buff VARCHAR2(500);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_csv_output_cur IS
      SELECT
        transaction_id
       ,shipping_date
       ,receipt_date
       ,ship_org_code
       ,ship_org_name
       ,receipt_org_code
       ,receipt_org_name
       ,item_no
       ,item_name
       ,schedule_qty
       ,before_stock
       ,after_stock
       ,stock_days
       ,shipping_pace
       ,plant_mark
       ,schedule_date
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      FROM
        xxcop_wk_ship_planning_output
      WHERE transaction_id = in_transaction_id
      ORDER BY ship_org_code,item_no,schedule_date,receipt_org_code;
--
    -- *** ���[�J���E���R�[�h ***
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
    -------------------------------------------------------------
    --                      CSV�o��
    -------------------------------------------------------------
    -- �^�C�g���s�ݒ�
    lv_buff :=            cv_csv_part || cv_csv_header1  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header2  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header3  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header4  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header5  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header6  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header7  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header8  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header9  || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header10 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header11 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header12 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header13 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header14 || cv_csv_part
        || cv_csv_cont || cv_csv_part || cv_csv_header15 || cv_csv_part
        ;
    --
    -- �^�C�g���s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buff
    );
    --
    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP
      --
      -- �f�[�^�s
      lv_buff :=          cv_csv_part || TO_CHAR(get_csv_output_rec.shipping_date,cv_date_format)      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.receipt_date,cv_date_format)       || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.ship_org_code                              || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.ship_org_name                              || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.receipt_org_code                           || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.receipt_org_name                           || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.item_no                                    || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.item_name                                  || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.schedule_qty)                      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.before_stock)                      || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.after_stock)                       || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.stock_days)                        || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.shipping_pace)                     || cv_csv_part
        || cv_csv_cont || cv_csv_part || get_csv_output_rec.plant_mark                                 || cv_csv_part
        || cv_csv_cont || cv_csv_part || TO_CHAR(get_csv_output_rec.schedule_date,cv_date_format)      || cv_csv_part
        ;
      -- �f�[�^�s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_buff
      );
      --
      -- ���팏�����Z
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP csv_output_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
  END csv_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_plan_type                  IN  VARCHAR2         --  1.�v��敪
    ,iv_pace_from                  IN  VARCHAR2         --  2.�o�׃y�[�X(����)����FROM
    ,iv_pace_to                    IN  VARCHAR2         --  3.�o�׃y�[�X�i���сj����TO
    ,iv_forcast_type               IN  VARCHAR2         --  4.�o�ח\������
    ,ov_errbuf                     OUT VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                    OUT VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                     OUT VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt   NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR get_schedule_cur IS
    SELECT
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_START
--       msdate.schedule_designator    schedule_designator      --��v�於
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_END
       msdate.organization_id        plant_org_id             --�H��q��
      ,msdate.inventory_item_id      inventory_item_id        --�݌ɕi��ID
      ,msdate.schedule_date          product_schedule_date    --�v����t
      ,SUM(msdate.schedule_quantity)      product_schedule_qty     --�v�搔��
    FROM
       mrp_schedule_designators  msdesi        --��v�於�e�[�u��
      ,mrp_schedule_dates        msdate        --��v����t�e�[�u��
    WHERE  msdate.schedule_designator =  msdesi.schedule_designator
      AND  msdate.organization_id     =  msdesi.organization_id
      AND  msdate.schedule_date      >=  NEXT_DAY(cd_sys_date,cv_sunday)
      AND  msdate.schedule_date      <   NEXT_DAY(NEXT_DAY(cd_sys_date,cv_sunday),cv_saturday)
      AND  msdesi.attribute1          =  cv_buy_type       --��v�敪�ށu3�F�w���v��v
      AND  msdate.schedule_level      =  cn_schedule_level --���x���Q
    GROUP BY
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_START
--       msdate.schedule_designator
--20090407_Ver1.2_T1_0280_SCS_Uda_DEL_END
       msdate.organization_id
      ,msdate.inventory_item_id
      ,msdate.schedule_date
    ORDER BY msdate.schedule_date,msdate.inventory_item_id , msdate.organization_id
    ;
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec     xxcop_wk_ship_planning%ROWTYPE := NULL;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �O���[�o���ϐ��ɓ��̓p�����[�^��ݒ�
    gv_plan_type       := iv_plan_type;
    gd_pace_from       := TO_DATE(iv_pace_from,cv_date_format_slash);
    gd_pace_to         := TO_DATE(iv_pace_to  ,cv_date_format_slash);
    gv_forcast_type    := iv_forcast_type;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --      A-1 ��������
    -- ===============================
    init(
      iv_plan_type      -- �v��敪
     ,iv_pace_from      -- �o�׃y�[�X�v�����(FROM)
     ,iv_pace_to        -- �o�׃y�[�X�v�����(TO)
     ,iv_forcast_type   -- �o�ח\���敪
     ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    <<Base_loop>>
    FOR get_schedule_rec IN get_schedule_cur LOOP
      --�ϐ�������
      lr_xwsp_rec := NULL;
      --�����s���J�E���g
      ln_loop_cnt := ln_loop_cnt + 1;
      --�H��o�׃��[�N���R�[�h�Z�b�g
      lr_xwsp_rec.transaction_id          := cn_request_id;                               -- �v��ID
      lr_xwsp_rec.org_data_lvl            := cn_data_lvl_plant;                           -- �g�D�f�[�^���x��(�o�̓f�[�^���x��)
      lr_xwsp_rec.inventory_item_id       := get_schedule_rec.inventory_item_id;          -- �݌ɕi��ID
      lr_xwsp_rec.plant_org_id            := get_schedule_rec.plant_org_id;               -- �H��g�DID
      lr_xwsp_rec.ship_org_id             := get_schedule_rec.plant_org_id;               -- �ړ����g�DID
      lr_xwsp_rec.product_schedule_date   := get_schedule_rec.product_schedule_date;      -- ���Y�\���
      lr_xwsp_rec.product_schedule_qty    := get_schedule_rec.product_schedule_qty;       -- ���Y�v�搔
      lr_xwsp_rec.shipping_date           := get_schedule_rec.product_schedule_date;      -- �o�ד�
      --
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
      BEGIN
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
        -- =============================================
        --      A-2 ����Y�v��擾
        -- =============================================
        get_schedule_date(
          io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
        END IF;
        -- =============================================
        --      A-3 �H��o�׌v�搧��}�X�^�擾
        -- =============================================
        get_plant_shipping(
          io_xwsp_rec          =>   lr_xwsp_rec     --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-4 ��{��������}�X�^�擾
        -- =============================================
        --��{��������}�X�^�擾����
        get_base_yokomst(
          io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-5 ���ʑq�ɏo�׃y�[�X�擾
        -- =============================================
        --���ʑq�ɏo�׃y�[�X�擾����
        get_under_lvl_pace(
          io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF lv_retcode = cv_status_error THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-6 �݌ɐ��擾
        -- =============================================
        --�݌ɐ��擾����
        get_stock_qty(
          io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF lv_retcode = cv_status_error THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
        -- =============================================
        --      A-7 �ړ����擾
        -- =============================================
        --�ړ����擾����
        get_move_qty(
          io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
         ,ov_errmsg            =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,ov_errbuf            =>   lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           =>   lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        );
        IF lv_retcode = cv_status_error THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_START
      EXCEPTION
        WHEN expt_next_record THEN
          NULL;
      END;
--20090407_Ver1.2_T1_0368_SCS_Uda_ADD_END
    END LOOP get_schedule_cur;
    --
    IF ln_loop_cnt = 0 THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00003      --�Ώۃf�[�^�Ȃ�
                   );
      RAISE internal_process_expt;
    END IF;
    --
    -- =============================================
    --     A-8 �H��o�׌v��o�̓��[�N�e�[�u���쐬
    -- =============================================
    insert_wk_output(
      cn_request_id
     ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00027
                     ,iv_token_name1  => cv_msg_00027_token_1
                     ,iv_token_value1 => cv_msg_wk_tbl_output
                   );
      RAISE internal_process_expt;
    END IF;
    -- =============================================
    --     A-9 �H��o�׌v��CSV�o��
    -- =============================================
    csv_output(
      cn_request_id
     ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    -- �Ώی����Z�o
    gn_target_cnt := gn_normal_cnt + gn_warn_cnt;

    -- �x�����b�Z�[�W���o�͂����ꍇ�A�x���I���Ŗ߂�
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN internal_process_expt THEN
      --�J�[�\���N���[�Y
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      --�J�[�\���N���[�Y
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --�J�[�\���N���[�Y
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�J�[�\���N���[�Y
      IF get_schedule_cur%ISOPEN = TRUE THEN
        CLOSE get_schedule_cur;
      END IF;
      -- �G���[�J�E���g�A�b�v
      gn_error_cnt := gn_error_cnt + 1;
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
     errbuf                        OUT VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                       OUT VARCHAR2         --   �G���[�R�[�h     #�Œ�#
    ,iv_plan_type                  IN  VARCHAR2         -- 1.�v��敪
    ,iv_pace_from                  IN  VARCHAR2         -- 2.�o�׃y�[�X(����)����FROM
    ,iv_pace_to                    IN  VARCHAR2         -- 3.�o�׃y�[�X�i���сj����TO
    ,iv_forcast_type               IN  VARCHAR2         -- 4.�o�ח\������
  )
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I�� �ꕔ�������b�Z�[�W
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
       iv_plan_type                      -- 1.�v��敪
      ,iv_pace_from                      -- 2.�o�׃y�[�X(����)����FROM
      ,iv_pace_to                        -- 3.�o�׃y�[�X�i���сj����TO
      ,iv_forcast_type                   -- 4.�o�ח\������
      ,lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN

      -- ���[�U�G���[���b�Z�[�W�����O�o��
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   lv_errmsg
        );
      END IF;

      -- �V�X�e���G���[���b�Z�[�W�����O�o��
      IF (lv_errbuf IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_others_err_msg
                    ,iv_token_name1  => cv_others_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                    )
        );
      END IF;
    END IF;

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      COMMIT;
  END main;
END XXCOP005A01C;
