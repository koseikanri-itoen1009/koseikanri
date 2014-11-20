create or replace PACKAGE BODY      XXCOP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP005A01C(body)
 * Description      : �H��o�׌v��
 * MD.050           : �H��o�׌v�� MD050_COP_005_A01
 * Version          : 2.5
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
 *  get_shipping_pace      �o�׃y�[�X�擾����(A-52)
 *  get_plant_shipping     �H��o�׌v�搧��}�X�^�擾�iA-3�j
 *  get_base_yokomst       ��{����������}�X�^�擾�iA-4�j
 *  get_pace_sum           ���ʑq�ɏo�׃y�[�X�擾�iA-51�j
 *  get_under_lvl_pace     �o�׃y�[�X�擾�����iA-5�j
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
 *  2009/04/21    1.4   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0722�j
 *  2009/04/28    1.5   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_0845�AT1_0847�j
 *  2009/05/20    1.6   SCS Uda          �V�X�e���e�X�g��Q�Ή��iT1_1096�j
 *  2009/06/04    1.7   SCS Fukada       �V�X�e���e�X�g��Q�Ή��iT1_1328�j�v���O�����̍Ō�Ɂu/�v��ǉ�
 *  2009/06/16    1.8   SCS Kikuchi      �V�X�e���e�X�g��Q�Ή��iT1_1463�AT1_1464�j
 *  2009/09/01    2.0   T.Tsukino        �V�K�쐬
 *  2009/10/29    2.1   Y.Goto           I_E_479_007
 *  2009/11/04    2.2   Y.Goto           I_E_479_010
 *  2009/11/20    2.3   Y.Goto           I_E_479_018
 *  2009/11/19    2.4   T.Tsukino        delete�G���[�̏C��
 *  2009/12/03    2.5   Y.Goto           I_E_479_021(�A�v��PT�Ή�)
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
  internal_api_expt         EXCEPTION;     -- �R���J�����g�������ʗ�O
  param_invalid_expt        EXCEPTION;     -- ���̓p�����[�^�`�F�b�N�G���[
  internal_process_expt     EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
  date_invalid_expt         EXCEPTION;     -- ���t�`�F�b�N�G���[
  past_date_invalid_expt    EXCEPTION;     -- �ߋ����`�F�b�N�G���[
  expt_next_record          EXCEPTION;     -- ���R�[�h�X�L�b�v�p
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
  reverse_invalid_expt      EXCEPTION;     -- ���t�t�]�G���[
  no_data_skip_expt         EXCEPTION;
  nested_loop_expt          EXCEPTION;     -- �K�w���[�v�G���[
  no_action_expt            EXCEPTION;
  
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);

  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP005A01C';
  --�v���O�������s����
  cd_sys_date                   CONSTANT DATE        := TRUNC(SYSDATE);                    --�v���O�������s����
--  -- ���̓p�����[�^���O�o�͗p
  cv_plan_from                  CONSTANT VARCHAR2(100) :=  '�v�旧�Ċ��ԁiFROM�j';
  cv_plan_to                    CONSTANT VARCHAR2(100) :=  '�v�旧�Ċ��ԁiTO�j';
  cv_pace_type                  CONSTANT VARCHAR2(100) :=  '�Ώۏo�׋敪';
  cv_pace_from                  CONSTANT VARCHAR2(100) :=  '�o�׃y�[�X�v����ԁiFROM�j';
  cv_pace_to                    CONSTANT VARCHAR2(100) :=  '�o�׃y�[�X�v����ԁiTO�j';
  cv_forcast_from               CONSTANT VARCHAR2(100) :=  '�o�ח\�����ԁiFROM)';
  cv_forcast_to                 CONSTANT VARCHAR2(100) :=  '�o�ח\�����ԁiTO�j';
  cv_schedule_date              CONSTANT VARCHAR2(100) :=  '�o�׈����ϓ�';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := ' : ';
--
--
  --���b�Z�[�W����
  cv_msg_appl_cont              CONSTANT VARCHAR2(100) := 'XXCOP';                 -- �A�v���P�[�V�����Z�k��
--  --���b�Z�[�W��
  cv_msg_00065     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';      -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_00055     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';      -- �p�����[�^�G���[���b�Z�[�W
  cv_msg_00011     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';      -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_00025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';      -- �l�t�]�G���[���b�Z�[�W
  cv_msg_00047     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';      -- ���������b�Z�[�W
  cv_msg_00053     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';      -- �z�����[�h�^�C���擾�G���[
  cv_msg_00056     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';      -- �ݒ���Ԓ��ғ����`�F�b�N�G���[���b�Z�[�W
  cv_msg_00049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';      -- �i�ڏ��擾�G���[
  cv_msg_00050     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';      -- �q�ɏ��擾�G���[
  cv_msg_00042     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';      -- �폜�����G���[
  cv_msg_10025     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10025';      -- �H��ŗL�L���擾�G���[
  cv_msg_00060     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';      -- �o�H��񃋁[�v�G���[���b�Z�[�W
  cv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- �Ώۃf�[�^�Ȃ�
  cv_msg_00027     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';      -- �o�^�����G���[���b�Z�[�W
  cv_msg_00028     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';      -- �X�V�����G���[���b�Z�[�W
  cv_msg_00062     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00062';      -- �o�H�G���[���b�Z�[�W
  cv_msg_00063     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00063';      -- ���[���v�Z�s���x��
  cv_msg_00066     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00066';      -- �����擾�G���[
  cv_msg_10009     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';      -- �ߋ����t���̓��b�Z�[�W
  cv_msg_10048     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10048';      -- �H��o�׌v��p�����[�^�o�̓��b�Z�[�W
  cv_msg_10049     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10049';      -- �H��o�׌v��CSV�t�@�C���o�̓w�b�_�[
  -- ���b�Z�[�W�֘A
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  --���b�Z�[�W�g�[�N��
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
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_10025_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10025_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00060_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00062_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00062_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00063_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00066_token_3      CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10048_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10048_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10048_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10048_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10048_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10048_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10048_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10048_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
--
  --���b�Z�[�W�g�[�N���l
  cv_msg_wk_tbl             CONSTANT VARCHAR2(100) := '�����v�惏�[�N�e�[�u��';
  cv_msg_wk_tbl_output      CONSTANT VARCHAR2(100) := '�H��o�׌v��o�̓��[�N�e�[�u��';
--
  cv_date_format            CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- �N����
  cv_date_format_slash      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- �N/��/��
--  cv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- �N���������b(24���ԕ\�L)
--  cv_month_format           CONSTANT VARCHAR2(8)   := 'MM';                     -- ���x�w��q(��)
--  --�����Z�b�g�敪
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- ��{�����v��
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- �H��o�׌v��
--  --�v���t�@�C���擾
  cv_master_org_id          CONSTANT VARCHAR2(20)  := 'XXCMN_MASTER_ORG_ID';           -- �v���t�@�C���擾�p �}�X�^�g�D
--  --�N�C�b�N�R�[�h�^�C�v
  cv_assign_type_priority   CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';   -- ������^�C�v�D��x
  cv_assign_name            CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';        -- �����Z�b�g��
  cv_flv_language           CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- ����
  cv_flv_enabled_flg_y      CONSTANT VARCHAR2(100) := 'Y';
--  --�ړ����}�C�i�X�t���O
  cn_cnt_from               CONSTANT NUMBER        := 1;                        --�e����
--
--  --���̓p�����[�^
  cv_buy_type               CONSTANT VARCHAR2(1)   := '3';                      -- ��v�敪�ށi�w���v��j
  cv_plan_type_pace         CONSTANT VARCHAR2(100) := '1';                      -- �o�׃y�[�X
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- �o�ח\��
--
  cv_own_flg_on             CONSTANT VARCHAR2(1)   := '1';                      -- ���H��Ώۃt���OYes
  cv_plan_typep             CONSTANT VARCHAR2(1)   := '1';                      -- �v��敪�i�o�׃y�[�X�j
  cv_plan_typef             CONSTANT VARCHAR2(1)   := '2';                      -- �v��敪�i�o�ח\���j
  cn_data_lvl_plant         CONSTANT NUMBER        := 0;                        -- �g�D�f�[�^���x��(�H�ꃌ�x��)
  cn_data_lvl_output        CONSTANT NUMBER        := 1;                        -- �g�D�f�[�^���x��(�H��o�׃��x��)
  cn_data_lvl_yokomt        CONSTANT NUMBER        := 2;                        -- �g�D�f�[�^���x��(��{�������x��)
  cn_delivery_lead_time     CONSTANT NUMBER        := 0;
  cn_frq_on                 CONSTANT NUMBER        := 1;                        -- ��\�q�Ɂi���݁j
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- �X�P�W���[�����x��
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
  --�ړ����}�C�i�X�t���O
  cv_move_minus_flg_on      CONSTANT VARCHAR2(2)   := '1';                      -- �ړ����}�C�i�X
  -- CSV�o�͗p
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
--20091203_Ver2.5_I_E_479_021_SCS.Goto_MOD_START
--  cv_csv_point                  CONSTANT VARCHAR2(1)   := '''';
  cv_csv_point                  CONSTANT VARCHAR2(1)   := '';
--20091203_Ver2.5_I_E_479_021_SCS.Goto_MOD_END
  -- ��\�q�ɃR�[�h
  cv_org_code                   CONSTANT VARCHAR2(10)  := 'ZZZZ';
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================

  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p�ϐ�
  gd_plan_from                  DATE;                     -- �v�旧�Ċ��ԁiFROM�j
  gd_plan_to                    DATE;                     -- �v�旧�Ċ��ԁiTO�j
  gv_pace_type                  VARCHAR2(1);              -- �Ώۏo�׋敪
  gd_pace_from                  DATE;                     -- �o�׃y�[�X���ԁiFROM�j
  gd_pace_to                    DATE;                     -- �o�׃y�[�X���ԁiTO)
  gd_forcast_from               DATE;                     -- �o�ח\�����ԁiFROM�j
  gd_forcast_to                 DATE;                     -- �o�ח\�����ԁiTO�j
  gd_schedule_date              DATE;                     -- �o�׈����ϓ�
  gd_process_date               DATE;                     -- �Ɩ����t
--
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
--20091119_�C��_SCS.Tsukino_ADD_START
  CURSOR delete_xwsp_cur
  IS
    SELECT xwsp.rowid
    FROM   xxcop_wk_ship_planning xwsp
    FOR UPDATE NOWAIT;
  CURSOR delete_xwspo_cur
  IS
    SELECT xwspo.rowid
    FROM   xxcop_wk_ship_planning_output xwspo
    FOR UPDATE NOWAIT;
--20091119_�C��_SCS.Tsukino_ADD_END
--20091119_�C��_SCS.Tsukino_DEL_START
--
--    -- *** ���[�J���E���R�[�h ***
--    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
--    lr_ttype         rowid_ttype;
----
--20091119_�C��_SCS.Tsukino_DEL_END
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
--20091119_�C��_SCS.Tsukino_ADD_START
  -- �����v�惏�[�N�e�[�u���폜����
    BEGIN
      OPEN delete_xwsp_cur;
      CLOSE delete_xwsp_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE resource_busy_expt;
    END;
    BEGIN
      OPEN delete_xwspo_cur;
      CLOSE delete_xwspo_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE resource_busy_expt;
    END;
      DELETE FROM xxcop_wk_ship_planning;
      DELETE FROM xxcop_wk_ship_planning_output;
  EXCEPTION
    -- *** �f�[�^�폜��O�n���h�� ***
    WHEN resource_busy_expt THEN
      ov_retcode := cv_status_error;
--20091119_�C��_SCS.Tsukino_ADD_END
--20091119_�C��_SCS.Tsukino_DEL_START
--    -- ===============================
--    -- �����v�惏�[�N�e�[�u��
--    -- ===============================
--    BEGIN
--      --���b�N�̎擾
--      SELECT xwsp.ROWID
--      BULK COLLECT INTO lr_ttype
--      FROM xxcop_wk_ship_planning xwsp
--      FOR UPDATE NOWAIT;
--      --�f�[�^�폜
--      DELETE FROM xxcop_wk_ship_planning;
----
--    EXCEPTION
--      WHEN resource_busy_expt THEN
--        NULL;
--    END;
----
--    -- ===============================
--    -- �H��o�׌v��o�̓��[�N�e�[�u��
--    -- ===============================
--   BEGIN
--      --���b�N�̎擾
--      SELECT xwspo.ROWID
--      BULK COLLECT INTO lr_ttype
--      FROM xxcop_wk_ship_planning_output xwspo
--      FOR UPDATE NOWAIT;
--      --�f�[�^�폜
--      DELETE FROM xxcop_wk_ship_planning_output;
--
--    EXCEPTION
--      WHEN resource_busy_expt THEN
--        NULL;
--    END;
--
--  EXCEPTION
--20091119_�C��_SCS.Tsukino_DEL_END
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_plan_from     IN    VARCHAR2    --   1.�v�旧�Ċ��ԁiFROM�j
    ,iv_plan_to       IN    VARCHAR2    --   2.�v�旧�Ċ��ԁiTO�j
    ,iv_pace_type     IN    VARCHAR2    --   3.�Ώۏo�׋敪
    ,iv_pace_from     IN    VARCHAR2    --   4.�o�׃y�[�X�v����ԁiFROM�j
    ,iv_pace_to       IN    VARCHAR2    --   5.�o�׃y�[�X�v����ԁiTO�j
    ,iv_forcast_from  IN    VARCHAR2    --   6.�o�ח\�����ԁiFROM)
    ,iv_forcast_to    IN    VARCHAR2    --   7.�o�ח\�����ԁiTO�j
    ,iv_schedule_date IN    VARCHAR2    --   8.�o�׈����ϓ�
    ,ov_errbuf        OUT   VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode       OUT   VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg        OUT   VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--    -- *** ���[�J���ϐ� ***
    lb_chk_value         BOOLEAN;         -- ���t�^�t�H�[�}�b�g�`�F�b�N����
    lv_invalid_value     VARCHAR2(100);   -- �G���[���b�Z�[�W�l
    lv_plan_from         VARCHAR2(100);
    lv_plan_to           VARCHAR2(100);
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
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- =======================
    -- ���̓p�����[�^�̏o��
    -- =======================
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- �w�b�_���̒��o
    lv_errmsg := xxccp_common_pkg.get_msg(          
             iv_application  => cv_msg_appl_cont    
            ,iv_name         => cv_msg_10048        
            ,iv_token_name1  => cv_msg_10048_token_1
            ,iv_token_value1 => iv_plan_from        
            ,iv_token_name2  => cv_msg_10048_token_2
            ,iv_token_value2 => iv_plan_to          
            ,iv_token_name3  => cv_msg_10048_token_3
            ,iv_token_value3 => iv_pace_type        
            ,iv_token_name4  => cv_msg_10048_token_4
            ,iv_token_value4 => iv_pace_from        
            ,iv_token_name5  => cv_msg_10048_token_5
            ,iv_token_value5 => iv_pace_to          
            ,iv_token_name6  => cv_msg_10048_token_6
            ,iv_token_value6 => iv_forcast_from     
            ,iv_token_name7  => cv_msg_10048_token_7
            ,iv_token_value7 => iv_forcast_to       
            ,iv_token_name8  => cv_msg_10048_token_8
            ,iv_token_value8 => iv_schedule_date    
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_errmsg
                     );
    -- ==================
    -- �Ɩ����t�̎擾
    -- ==================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => TO_CHAR(gd_process_date,cv_date_format_slash)
    );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00065
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- =================================================
    -- �o�׃y�[�X�E�v����ԁA�o�ח\���敪���̓`�F�b�N
    -- =================================================
    -- �Ώۏo�׋敪���O���[�o���ϐ��֊i�[
    gv_pace_type                  := iv_pace_type;              -- �Ώۏo�׋敪
    -- �Ώۏo�׋敪��NULL�l�̏ꍇ�A�o�׃y�[�X�v����ԁA�o�ח\���v����Ԃ͕K�{
    IF (gv_pace_type IS NULL) THEN
      IF (iv_pace_from IS NULL) OR (iv_pace_to IS NULL) OR (iv_forcast_from IS NULL) OR (iv_forcast_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    -- �Ώۏo�׋敪���o�׃y�[�X�Ŏw�肳��Ă���ꍇ�A�o�׃y�[�X�v����Ԃ͕K�{
    ELSIF (gv_pace_type = cv_plan_type_pace) THEN
      IF (iv_pace_from IS NULL) OR (iv_pace_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    -- �Ώۏo�׋敪���o�ח\���Ŏw�肳��Ă���ꍇ�A�o�ח\���v����Ԃ͕K�{
    ELSIF (gv_pace_type = cv_plan_type_fgorcate) THEN
      IF (iv_forcast_from IS NULL) OR (iv_forcast_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
    END IF;
    -- ==============================
    -- �o�׈����ϓ��̓��t�^�`�F�b�N
    -- ==============================
    -- �o�׈�����
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_schedule_date
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_schedule_date;
      RAISE date_invalid_expt;
    END IF;
    -- �O���[�o���ϐ��ɓ��̓p�����[�^��ݒ�(�o�׈����ϓ��ȊO��init�Őݒ�j
    gd_schedule_date              := TO_DATE(iv_schedule_date, cv_date_format_slash);-- �o�׈����ϓ�
    -- ================================
    -- �v�旧�Ċ���FROM,TO���t�`�F�b�N
    -- ================================
    --���ʊ֐�:chk_date_format�œ��t�̃`�F�b�N���s���A
    --�O���[�o���ϐ��֊i�[
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_from;
      RAISE date_invalid_expt;
    END IF;
    --from-to�̋t�]�`�F�b�N�ƁAfrom-to�̖������`�F�b�N���s���܂�
    --
    -- �v�旧�Ċ���from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_from;
      RAISE date_invalid_expt;
    END IF;
    gd_plan_from := TO_DATE( iv_plan_from, cv_date_format_slash );
    -- �v�旧�Ċ���to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_plan_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_plan_to;
      RAISE date_invalid_expt;
    END IF;
    gd_plan_to   := TO_DATE( iv_plan_to, cv_date_format_slash );
    --�v�旧�Ċ���(FROM)-�v�旧�Ċ���(TO)�t�]�`�F�b�N
    IF ( gd_plan_from > gd_plan_to ) THEN
      lv_plan_from := cv_plan_from;
      lv_plan_to   := cv_plan_to;
      RAISE reverse_invalid_expt;
    END IF;
    --�v�旧�Ċ���(FROM)�ߋ����`�F�b�N
    IF ( gd_plan_from < gd_process_date ) THEN
      lv_invalid_value := cv_plan_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --�v�旧�Ċ���(TO)�ߋ����`�F�b�N
    IF ( gd_plan_to < gd_process_date ) THEN
      lv_invalid_value := cv_plan_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- =======================================
    -- �o�׃y�[�X�v�����FROM,TO���t�`�F�b�N
    -- =======================================
    -- �o�׃y�[�X�v�����from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_pace_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_pace_from;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_from := TO_DATE( iv_pace_from, cv_date_format_slash );
    -- �o�׃y�[�X�v�����to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_pace_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_pace_to;
      RAISE date_invalid_expt;
    END IF;
    gd_pace_to   := TO_DATE( iv_pace_to, cv_date_format_slash );
    --�o�׃y�[�X�v�����(FROM)-�o�׃y�[�X�v�����(TO)�t�]�`�F�b�N
    IF ( gd_pace_from > gd_pace_to ) THEN
      lv_plan_from := cv_pace_from;
      lv_plan_to   := cv_pace_to;
      RAISE reverse_invalid_expt;
    END IF;
    --�o�׃y�[�X�v�����(FROM)�ߋ����`�F�b�N
    IF ( gd_pace_from > gd_process_date ) THEN
      lv_invalid_value := cv_pace_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --�o�׃y�[�X�v�����(TO)�ߋ����`�F�b�N
    IF ( gd_pace_to > gd_process_date ) THEN
      lv_invalid_value := cv_pace_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00047
                     ,iv_token_name1  => cv_msg_00047_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- ===========================================
    -- �o�ח\������FROM,TO���t�`�F�b�N
    -- ===========================================
    -- �o�ח\������from
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_forcast_from
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_forcast_from;
      RAISE date_invalid_expt;
    END IF;
    gd_forcast_from := TO_DATE( iv_forcast_from, cv_date_format_slash );
    -- �o�ח\������to
    lb_chk_value := xxcop_common_pkg.chk_date_format(
                       iv_value       => iv_forcast_to
                      ,iv_format      => cv_date_format_slash
                    );
    IF ( NOT lb_chk_value ) THEN
      lv_invalid_value := cv_forcast_to;
      RAISE date_invalid_expt;
    END IF;
    gd_forcast_to   := TO_DATE( iv_forcast_to, cv_date_format_slash );
    --�o�ח\������(FROM)-�o�ח\������(TO)�t�]�`�F�b�N
    IF ( gd_forcast_from > gd_forcast_to ) THEN
      lv_plan_from := cv_forcast_from;
      lv_plan_to   := cv_forcast_to;
      RAISE reverse_invalid_expt;
    END IF;
    --�o�ח\������(FROM)�ߋ����`�F�b�N
    IF ( gd_forcast_from < gd_process_date ) THEN
      lv_invalid_value := cv_forcast_from;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    --�o�ח\������(TO)�ߋ����`�F�b�N
    IF ( gd_forcast_to < gd_process_date ) THEN
      lv_invalid_value := cv_forcast_to;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10009
                     ,iv_token_name1  => cv_msg_10009_token_1
                     ,iv_token_value1 => lv_invalid_value
                   );
      lv_retcode := cv_status_error;
      RAISE past_date_invalid_expt;
    END IF;
    -- =====================================
    -- �֘A�e�[�u���폜����
    -- =====================================
  -- ���[�N�e�[�u���f�[�^�폜
    delete_table(
            ov_errmsg          =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
           ,ov_errbuf          =>   lv_errbuf        --   �G���[�E���b�Z�[�W
           ,ov_retcode         =>   lv_retcode       --   ���^�[���E�R�[�h
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00042
                     ,iv_token_name1  => cv_msg_00042_token_1
                     ,iv_token_value1 => cv_msg_wk_tbl || '�A' || cv_msg_wk_tbl_output
                   );
      lv_retcode := cv_status_error;
--20091119_�C��_SCS.Tsukino_ADD_START
      RAISE internal_api_expt;
--20091119_�C��_SCS.Tsukino_ADD_END
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
                     ,iv_token_value1 => lv_plan_from
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => lv_plan_to
                   );
      ov_retcode := cv_status_error;
    WHEN past_date_invalid_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 START   ########################################
--
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
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_START
--  /**********************************************************************************
--   * Procedure Name   : get_plant_mark
--   * Description      : �H��ŗL�L���擾�����iA-21�j
--   ***********************************************************************************/
--  PROCEDURE get_plant_mark(
--     io_xwsp_rec              IN OUT XXCOP_WK_SHIP_PLANNING%ROWTYPE    --   �H��o�׃��[�N���R�[�h�^�C�v
--    ,ov_errbuf                OUT VARCHAR2                             --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ,ov_retcode               OUT VARCHAR2                             --   ���^�[���E�R�[�h             --# �Œ� #
--    ,ov_errmsg                OUT VARCHAR2                             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_plant_mark'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--    );
--    --�H��ŗL�L���擾����
--    BEGIN
--      SELECT ffmb.attribute6 attribut6
--      INTO   io_xwsp_rec.plant_mark
--      FROM   fm_matl_dtl      fmd
--            ,fm_form_mst_b    ffmb
--      WHERE  fmd.formula_id = ffmb.formula_id
--      AND    fmd.item_id = io_xwsp_rec.item_id
--          AND    ffmb.attribute6 is not null
--      AND    ROWNUM = 1
--      ;
--    EXCEPTION
--      --�����f�[�^���Ȃ��ꍇ
--      WHEN NO_DATA_FOUND THEN
--        ov_retcode := cv_status_warn;
--    END;
----
--  EXCEPTION
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END get_plant_mark;
----
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_END
  /**********************************************************************************
   * Procedure Name   : insert_wk_tbl
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-22)
   ***********************************************************************************/
  PROCEDURE insert_wk_tbl(
     ir_xwsp_rec         IN  xxcop_wk_ship_planning%ROWTYPE    --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf           OUT VARCHAR2                          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2                          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)                         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
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
        ,minus_flg
        ,frq_location_id
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
        ,ir_xwsp_rec.num_of_case
        ,ir_xwsp_rec.palette_max_cs_qty
        ,ir_xwsp_rec.palette_max_step_qty
        ,ir_xwsp_rec.product_schedule_date
        ,ir_xwsp_rec.product_schedule_qty
        ,ir_xwsp_rec.ship_org_id
        ,ir_xwsp_rec.ship_org_code
        ,ir_xwsp_rec.ship_org_name
        ,ir_xwsp_rec.ship_lct_id
        ,ir_xwsp_rec.ship_lct_code
        ,ir_xwsp_rec.ship_lct_name
        ,ir_xwsp_rec.ship_calendar_code
        ,ir_xwsp_rec.receipt_org_id
        ,ir_xwsp_rec.receipt_org_code
        ,ir_xwsp_rec.receipt_org_name
        ,ir_xwsp_rec.receipt_lct_id
        ,ir_xwsp_rec.receipt_lct_code
        ,ir_xwsp_rec.receipt_lct_name
        ,ir_xwsp_rec.receipt_calendar_code
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
        ,ir_xwsp_rec.minus_flg
        ,ir_xwsp_rec.frq_location_id
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
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
  --�q�ɏ��擾����
    xxcop_common_pkg2.get_loct_info(
       id_target_date       =>    io_xwsp_rec.product_schedule_date            -- �Ώۓ��t
      ,in_organization_id   =>    io_xwsp_rec.plant_org_id                     -- �g�DID(�H��q��ID�j
      ,ov_organization_code =>    io_xwsp_rec.ship_org_code                    -- �g�D�R�[�h
      ,ov_organization_name =>    io_xwsp_rec.ship_org_name                    -- �g�D����
      ,on_loct_id           =>    io_xwsp_rec.ship_lct_id                      -- �ۊǑq��ID
      ,ov_loct_code         =>    io_xwsp_rec.ship_lct_code                    -- �ۊǑq�ɃR�[�h
      ,ov_loct_name         =>    io_xwsp_rec.ship_lct_name                    -- �ۊǑq�ɖ���
      ,ov_calendar_code     =>    io_xwsp_rec.ship_calendar_code               -- �J�����_�R�[�h
      ,ov_errbuf            =>    lv_errbuf               --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           =>    lv_retcode              --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            =>    lv_errmsg               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => TO_CHAR(io_xwsp_rec.plant_org_id)
                    );
      RAISE global_api_expt;
    --�f�[�^��1�����擾�ł��Ȃ������ꍇ�A�q�ɏ��擾�G���[���o�͂��A�㏈�����~
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00050
                      ,iv_token_name1  => cv_msg_00050_token_1
                      ,iv_token_value1 => io_xwsp_rec.ship_org_code
                    );
      RAISE internal_process_expt;
    END IF;
  --�i�ڏ��擾����
    xxcop_common_pkg2.get_item_info(
       id_target_date          =>      io_xwsp_rec.product_schedule_date       -- �v����t
      ,in_organization_id      =>      io_xwsp_rec.plant_org_id                -- �H��q��ID
      ,in_inventory_item_id    =>      io_xwsp_rec.inventory_item_id           -- �݌ɕi��ID
      ,on_item_id              =>      io_xwsp_rec.item_id                     -- OPM�i��ID
      ,ov_item_no              =>      io_xwsp_rec.item_no                     -- �i�ڃR�[�h
      ,ov_item_name            =>      io_xwsp_rec.item_name                   -- �i�ږ���
      ,on_num_of_case          =>      io_xwsp_rec.num_of_case                 -- �P�[�X����
      ,on_palette_max_cs_qty   =>      io_xwsp_rec.palette_max_cs_qty          -- �z��
      ,on_palette_max_step_qty =>      io_xwsp_rec.palette_max_step_qty        -- �i��
      ,ov_errbuf               =>      lv_errbuf               --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode              =>      lv_retcode              --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg               =>      lv_errmsg               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.inventory_item_id
                   );
      RAISE global_api_expt;
    --�f�[�^��1�����擾�ł��Ȃ������ꍇ�A�i�ڏ��擾�G���[���o�͂��A�������X�L�b�v
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00049
                      ,iv_token_name1  => cv_msg_00049_token_1
                      ,iv_token_value1 => io_xwsp_rec.item_no
                    );
      RAISE expt_next_record;
    END IF;
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_START
--  -- �H��ŗL�L���擾
--    get_plant_mark(
--       io_xwsp_rec          =>   io_xwsp_rec  --   �H��o�׃��[�N���R�[�h�^�C�v
--      ,ov_errmsg            =>   lv_errmsg    --   �G���[�E���b�Z�[�W
--      ,ov_errbuf            =>   lv_errbuf    --   ���^�[���E�R�[�h
--      ,ov_retcode           =>   lv_retcode    --   ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_api_expt;
--    --�H��ŗL�L�����擾�ł��Ȃ������ꍇ�A�H��ŗL�L���擾�G���[���o�͂��A�㏈�����~
--    ELSIF (lv_retcode = cv_status_warn) THEN
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_appl_cont
--                      ,iv_name         => cv_msg_10025
--                      ,iv_token_name1  => cv_msg_10025_token_1
--                      ,iv_token_value1 => io_xwsp_rec.item_no
--                      ,iv_token_name2  => cv_msg_10025_token_2
--                      ,iv_token_value2 => io_xwsp_rec.item_name
--                    );
--      RAISE internal_process_expt;
--    END IF;
--20091104_Ver2.2_I_E_479_010_SCS.Goto_DEL_END
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name ||'�H��o�׌v�惏�[�N�e�[�u���o�^�������{�O'
    );
    -- �H��o�׌v�惏�[�N�e�[�u���o�^����
    insert_wk_tbl(
       ir_xwsp_rec          =>   io_xwsp_rec           --   �H��o�׃��[�N���R�[�h�^�C�v
      ,ov_errmsg            =>   lv_errmsg             --   �G���[�E���b�Z�[�W
      ,ov_errbuf            =>   lv_errbuf             --   ���^�[���E�R�[�h
      ,ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE internal_process_expt;
    END IF;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name ||'�H��o�׌v�惏�[�N�e�[�u���o�^�������{��'
    );
--
  EXCEPTION
    WHEN expt_next_record THEN
      fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_errmsg
                     );
      ov_retcode := cv_status_warn;
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  /**********************************************************************************
   * Procedure Name   : get_shipping_pace
   * Description      : �o�׃y�[�X�擾�����iA-52�j
   ***********************************************************************************/
  PROCEDURE get_shipping_pace(
     io_xwsp_rec         IN OUT xxcop_wk_ship_planning%ROWTYPE       --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf           OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_shipping_pace'; -- �v���O������

--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################

    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W

--###########################  �Œ蕔 END   ####################################

    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***

    -- *** ���[�J���ϐ� ***
    ln_quantity     NUMBER;
    ln_working_days NUMBER;
    ln_shipped_quantity  NUMBER;
    
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE;
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################

    ov_retcode := cv_status_normal;

--###########################  �Œ蕔 END   ############################

    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
  -- ====================================
  -- �o�׃y�[�X�擾����
  -- ====================================
  --����2�Ŏ擾�����A�o�׌v��敪���\���̏ꍇ�i���̓p�����[�^�̏o�׌v��敪���\���j
  IF (io_xwsp_rec.shipping_type = cv_plan_typef) THEN    --�o�ח\��'2'
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '�\��' 
          );  
    --���ʊ֐�:�o�ח\���擾����
    xxcop_common_pkg2.get_num_of_forecast(
       in_organization_id          =>         io_xwsp_rec.receipt_org_id  --(����1�Ŏ擾)�݌ɑg�DID
      ,in_inventory_item_id        =>         io_xwsp_rec.inventory_item_id  --(����4�Ŏ擾)�݌ɕi��ID
      ,id_plan_date_from           =>         gd_forcast_from             --(���̓p�����[�^)�o�ח\������(FROM)
      ,id_plan_date_to             =>         gd_forcast_to               --(���̓p�����[�^)�o�ח\������(TO)
      ,in_loct_id                  =>         io_xwsp_rec.receipt_lct_id  --OPM�ۊǏꏊID
      ,on_quantity                 =>         ln_quantity                 --�o�ח\����
      ,ov_errbuf                   =>         lv_errbuf
      ,ov_retcode                  =>         lv_retcode
      ,ov_errmsg                   =>         lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
     --  �o�׎��щғ������擾
    xxcop_common_pkg2.get_working_days(
       iv_calendar_code            =>           io_xwsp_rec.receipt_calendar_code
      ,in_organization_id          =>           NULL
      ,in_loct_id                  =>           NULL
      ,id_from_date                =>           gd_forcast_from
      ,id_to_date                  =>           gd_forcast_to
      ,on_working_days             =>           ln_working_days           -- �ғ���
      ,ov_errbuf                   =>           lv_errbuf
      ,ov_retcode                  =>           lv_retcode
      ,ov_errmsg                   =>           lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    ELSIF (ln_working_days = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00056
                     ,iv_token_name1  => cv_msg_00056_token_1
                     ,iv_token_value1 => TO_CHAR(gd_forcast_from,cv_date_format_slash)
                     ,iv_token_name2  => cv_msg_00056_token_2
                     ,iv_token_value2 => TO_CHAR(gd_forcast_to,cv_date_format_slash)
                   );
      RAISE internal_process_expt;
    END IF;
    --1�ғ���������̏o�׃y�[�X���擾
  io_xwsp_rec.shipping_pace  :=   ROUND(ln_quantity/ln_working_days,0);
  --�f�o�b�N���b�Z�[�W�o��
  xxcop_common_pkg.put_debug_message(
     iov_debug_mode => gv_debug_mode
    ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||','||'�\��'||','||TO_CHAR(io_xwsp_rec.receipt_org_id)||','||TO_CHAR(io_xwsp_rec.shipping_pace)||'='||TO_CHAR(ln_quantity)||'/'||TO_CHAR(ln_working_days)
  );  
    --
  --����2�Ŏ擾�����A�o�׌v��敪�����т̏ꍇ�i���̓p�����[�^�̏o�׌v��敪���y�[�X�j
  ELSIF (io_xwsp_rec.shipping_type = cv_plan_typep) THEN
  --�f�o�b�N���b�Z�[�W�o��
  xxcop_common_pkg.put_debug_message(
     iov_debug_mode => gv_debug_mode
    ,iv_value       => '����' 
        );  
    xxcop_common_pkg2.get_num_of_shipped(
         in_deliver_from_id          =>         io_xwsp_rec.receipt_lct_id --(����4�Ŏ擾)�ۊǐ�q��ID
        ,in_item_id                  =>         io_xwsp_rec.item_id        --(����1�Ŏ擾)�i��ID
        ,id_shipment_date_from       =>         gd_pace_from               --(���̓p�����[�^�j�o�׎��ю擾����(FROM)
        ,id_shipment_date_to         =>         gd_pace_to                 --(���̓p�����[�^�j�o�׎��ю擾����(TO)
        ,iv_freshness_condition      =>         NULL                       --�N�x����
--20091203_Ver2.5_I_E_479_021_SCS.Goto_ADD_START
        ,in_inventory_item_id        =>         io_xwsp_rec.inventory_item_id
--20091203_Ver2.5_I_E_479_021_SCS.Goto_ADD_END
        ,on_shipped_quantity         =>         ln_shipped_quantity        --�o�׎��ѐ�
        ,ov_errbuf                   =>         lv_errbuf
        ,ov_retcode                  =>         lv_retcode
        ,ov_errmsg                   =>         lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
    END IF;
    --  �o�׎��щғ������擾
    xxcop_common_pkg2.get_working_days(
         iv_calendar_code            =>           io_xwsp_rec.receipt_calendar_code
        ,in_organization_id          =>           NULL
        ,in_loct_id                  =>           NULL
        ,id_from_date                =>           gd_pace_from
        ,id_to_date                  =>           gd_pace_to
        ,on_working_days             =>           ln_working_days
        ,ov_errbuf                   =>           lv_errbuf
        ,ov_retcode                  =>           lv_retcode
        ,ov_errmsg                   =>           lv_errmsg
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    ELSIF (ln_working_days = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_appl_cont
                    ,iv_name         => cv_msg_00056
                    ,iv_token_name1  => cv_msg_00056_token_1
                    ,iv_token_value1 => TO_CHAR(gd_pace_from,cv_date_format_slash)
                    ,iv_token_name2  => cv_msg_00056_token_2
                    ,iv_token_value2 => TO_CHAR(gd_pace_to,cv_date_format_slash)
      );
      RAISE internal_process_expt;
    END IF;
    --1�ғ���������̏o�׃y�[�X���擾
    io_xwsp_rec.shipping_pace  :=   ROUND(ln_shipped_quantity/ln_working_days,0);
    --  io_xwsp_rec := lr_xwsp_rec;
  END IF;
--  
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;

--#####################################  �Œ蕔 END   ##########################################
  END get_shipping_pace;
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
    --�q�ɏ��擾�����ɂĎg�p
    ln_quantity           mrp_schedule_dates.schedule_quantity%TYPE := NULL;
    ln_shipped_quantity   xxinv_mov_lot_details.actual_quantity%TYPE := NULL;
    ln_working_days       NUMBER := 0;
--
    ln_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE := NULL;
    ln_own_flg_cnt        NUMBER := 0;
    ln_loop_cnt           NUMBER := 0;
    ln_receipt_code       NUMBER := NULL;
    lv_receipt_code       VARCHAR2(4) := NULL;
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
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
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
     --   ,shipping_type
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_plant             --0 �g�D�f�[�^���x��(�H�ꃌ�x��)
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_id
      ;
    --�o�H���擾�J�[�\��(�o�ׁ����)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id        inventory_item_id                     --�݌ɕi��ID
       ,organization_id          organization_id                       --�g�DID
       ,source_organization_id   source_organization_id                --�o�בg�D
       ,receipt_organization_id  receipt_organization_id               --����g�D
       ,own_flg                  own_flg                               --���q�Ƀt���O
       ,ship_plan_type           ship_plan_type                        --�o�׌v��敪
       ,yusen                    yusen                                 --������D��x
       ,row_number               row_number
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
              AND    mas.attribute1               = cv_factory_ship_plan    -- '3' �H��o�׌v��
              AND    mas.assignment_set_name      IN (SELECT lookup_code
                                                      FROM fnd_lookup_values
                                                      WHERE lookup_type  = cv_assign_name
                                                      AND enabled_flag = cv_flv_enabled_flg_y
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)           >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)  >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id           inventory_item_id                                         --�݌ɕi��ID
             ,organization_id             organization_id                                           --�g�DID
             ,sourcing_rule_type          sourcing_rule_type                                        --�\�[�X���[���^�C�v
             ,source_organization_id      source_organization_id                                    --�o�בg�D
             ,receipt_organization_id     receipt_organization_id                                   --����g�D
             ,own_flg                     own_flg                                                   --���q�Ƀt���O
             ,ship_plan_type              ship_plan_type                                            --�o�׌v��敪
             ,yusen                       yusen                                                     --������D��x
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
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR     msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = TO_NUMBER(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)         >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
              ORDER BY yusen
            )
            WHERE ROWNUM = 1
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
      AND   ship_plan_type = NVL(gv_pace_type, ship_plan_type)
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
    BEGIN
      --
      --�ϐ�������
      lr_xwsp_rec := NULL;
      ln_loop_cnt := 0;
      ln_own_flg_cnt := 0;
      --
      --�H��o�׃��[�N���R�[�h�Z�b�g
      --���S����
      --�H��o�׌v��Work�e�[�u��ID
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;
      --1:�g�D�f�[�^���x��(�H��o�׃��x��)
      lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --�H��q��ID
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --�H��q�ɃR�[�h
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --�H��q�ɖ�
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --�H��ŗL�L��
      lr_xwsp_rec.own_flg                  := get_wk_ship_planning_rec.own_flg;                --���H��Ώۃt���O
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --�݌ɕi��ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM�i��ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --�i�ڃR�[�h
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --�i�ږ���
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --�P�[�X����
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --�z��
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --�i��
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --���Y�\���
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --���Y�v�搔
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;            --�ړ����g�DID
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;          --�ړ����g�D�R�[�h
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;          --�ړ����g�D��
      lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.ship_lct_id;            --�ړ����ۊǏꏊID
      lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.ship_lct_code;          --�ړ����ۊǏꏊ�R�[�h
      lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.ship_lct_name;          --�ړ����ۊǏꏊ��
      lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.ship_calendar_code;     --�ړ����J�����_�R�[�h
      lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.receipt_org_id;         --�ړ���g�DID
      lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.receipt_org_code;       --�ړ���g�D�R�[�h
      lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.receipt_org_name;       --�ړ���g�D��
      lr_xwsp_rec.receipt_lct_id           := get_wk_ship_planning_rec.receipt_lct_id;         --�ړ���ۊǏꏊID
      lr_xwsp_rec.receipt_lct_code         := get_wk_ship_planning_rec.receipt_lct_code;       --�ړ���ۊǏꏊ�R�[�h
      lr_xwsp_rec.receipt_lct_name         := get_wk_ship_planning_rec.receipt_lct_name;       --�ړ���ۊǏꏊ��
      lr_xwsp_rec.receipt_calendar_code    := get_wk_ship_planning_rec.receipt_calendar_code;  --�ړ���J�����_�R�[�h
      lr_xwsp_rec.cnt_ship_org             := get_wk_ship_planning_rec.cnt_ship_org;           --�e�q�Ɍ���
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --�o�ד�
      lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.receipt_date;           --���ד�
      lr_xwsp_rec.delivery_lead_time       := get_wk_ship_planning_rec.delivery_lead_time;     --�z�����[�h�^�C��
      lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;          --�o�׎��уy�[�X
      lr_xwsp_rec.under_lvl_pace           := get_wk_ship_planning_rec.under_lvl_pace;         --���ʑq�ɏo�׃y�[�X
      lr_xwsp_rec.schedule_qty             := get_wk_ship_planning_rec.schedule_qty;           --�v�搔
      lr_xwsp_rec.before_stock             := get_wk_ship_planning_rec.before_stock;           --�O�݌�
      lr_xwsp_rec.after_stock              := get_wk_ship_planning_rec.after_stock;            --��݌�
      lr_xwsp_rec.stock_days               := get_wk_ship_planning_rec.stock_days;             --�݌ɓ���
      lr_xwsp_rec.assignment_set_type      := get_wk_ship_planning_rec.assignment_set_type;    --�����Z�b�g�敪
      lr_xwsp_rec.assignment_type          := get_wk_ship_planning_rec.assignment_type;        --������^�C�v
      lr_xwsp_rec.sourcing_rule_type       := get_wk_ship_planning_rec.sourcing_rule_type;     --�\�[�X���[���^�C�v
      lr_xwsp_rec.sourcing_rule_name       := get_wk_ship_planning_rec.sourcing_rule_name;     --�\�[�X���[����
  --    lr_xwsp_rec.shipping_type            := gv_pace_type;          --�o�׌v��敪
      --���S����
      --�J�[�\���ϐ����
      ln_organization_id   := lr_xwsp_rec.ship_org_id;
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
      --
      --�H��o�׌v�搧��}�X�^������g�D�f�[�^���o�i�o�ׁ�����j
      <<get_plant_ship_loop>>
      FOR get_plant_ship_rec IN get_plant_ship_cur LOOP
        ln_loop_cnt := ln_loop_cnt + 1;
        --���[�v�ϐ��Z�b�g
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id; --����g�D�i�ړ���q��ID�j
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;                 --���q�Ƀt���O
        lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;          --�o�׌v��敪
        -- ===================================
        -- �q�ɏ��擾����
        -- ===================================
        xxcop_common_pkg2.get_loct_info(
           id_target_date         =>       lr_xwsp_rec.product_schedule_date    --�i����1�Ŏ擾�j�v����t
          ,in_organization_id     =>       lr_xwsp_rec.receipt_org_id           --�i����2�Ŏ擾�j�ړ���q��ID
          ,ov_organization_code   =>       lr_xwsp_rec.receipt_org_code           -- �ړ���g�DID
          ,ov_organization_name   =>       lr_xwsp_rec.receipt_org_name         -- �ړ���g�D�R�[�h
          ,on_loct_id             =>       lr_xwsp_rec.receipt_lct_id           -- �ۊǑq��ID
          ,ov_loct_code           =>       lr_xwsp_rec.receipt_lct_code         -- �ۊǑq�ɃR�[�h
          ,ov_loct_name           =>       lr_xwsp_rec.receipt_lct_name         -- �ۊǑq�ɖ���
          ,ov_calendar_code       =>       lr_xwsp_rec.receipt_calendar_code    -- �J�����_�R�[�h
          ,ov_errbuf              =>       lv_errbuf               --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             =>       lv_retcode              --   ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              =>       lv_errmsg               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_id
                        );
          RAISE global_api_expt;
        --�f�[�^��1�����擾�ł��Ȃ������ꍇ�A�q�ɏ��擾�G���[���o�͂��A�㏈�����~
        ELSIF (lv_retcode = cv_status_warn) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        -- ===================================
        -- �z�����[�h�^�C���擾����
        -- ===================================
        xxcop_common_pkg2.get_deliv_lead_time(
           id_target_date       =>      lr_xwsp_rec.product_schedule_date  --   (����1�Ŏ擾�j�v����t
          ,iv_from_loct_code    =>      lr_xwsp_rec.ship_lct_code         --   (����1�Ŏ擾�j�o�וۊǑq�ɃR�[�h
          ,iv_to_loct_code      =>      lr_xwsp_rec.receipt_lct_code      --   (����4�Ŏ擾�j����ۊǑq�ɃR�[�h
          ,on_delivery_lt       =>      lr_xwsp_rec.delivery_lead_time     --   ���[�h�^�C��(��)
          ,ov_errbuf            =>      lv_errbuf                          --   �G���[�E���b�Z�[�W
          ,ov_retcode           =>      lv_retcode                          --   ���^�[���E�R�[�h
          ,ov_errmsg            =>      lv_errmsg                         --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_lct_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_lct_code
                        );
          RAISE internal_process_expt;
        END IF;
        --
        -- ===============================
        -- �o�׃y�[�X�擾����
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- ���ד��擾����
        xxcop_common_pkg2.get_receipt_date(
           iv_calendar_code         =>      lr_xwsp_rec.receipt_calendar_code
          ,in_organization_id       =>      lr_xwsp_rec.receipt_org_id
          ,in_loct_id               =>      lr_xwsp_rec.receipt_lct_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_shipment_date         =>      lr_xwsp_rec.product_schedule_date
          ,id_shipment_date         =>      lr_xwsp_rec.shipping_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,in_lead_time             =>      lr_xwsp_rec.delivery_lead_time
          ,od_receipt_date          =>      lr_xwsp_rec.receipt_date
          ,ov_errbuf                =>      lv_errbuf
          ,ov_retcode               =>      lv_retcode
          ,ov_errmsg                =>      lv_errmsg
        );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lr_xwsp_rec.receipt_date IS NULL) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00066
                           ,iv_token_name1  => cv_msg_00066_token_1
                           ,iv_token_value1 => lr_xwsp_rec.receipt_lct_code
                           ,iv_token_name2  => cv_msg_00066_token_2
                           ,iv_token_value2 => lr_xwsp_rec.receipt_calendar_code
                           ,iv_token_name3  => cv_msg_00066_token_3
                           ,iv_token_value3 => TO_CHAR(lr_xwsp_rec.product_schedule_date,cv_date_format_slash)
                          );
            RAISE internal_process_expt;
          END IF;
        -- �H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '��\�q�ɑ��݃`�F�b�N�O' 
          );  
-------------------------------------------------------
        --��\�q�ɑ��݃`�F�b�N
        BEGIN
          BEGIN
            SELECT  mil2.organization_id
                   ,mil.attribute5
            INTO   ln_receipt_code
                  ,lv_receipt_code
            FROM    mtl_item_locations mil
                   ,(SELECT  mil3.organization_id  organization_id
                            , mil3.segment1        segment1
                     FROM   mtl_item_locations mil3
                     WHERE  mil3.segment1 =  mil3.attribute5
                     AND    mil3.attribute5 IS NOT NULL) mil2
            WHERE    mil.attribute5 IS NOT NULL
            AND      mil.segment1 = lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 <> lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 = mil2.segment1(+)
            ; 
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'when_no_data_found'
          );  
              RAISE no_action_expt;
          END;
          IF (ln_receipt_code IS NULL and lv_receipt_code = cv_org_code) THEN
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'zzzz'
          );  
            ln_receipt_code := NULL;
            lv_receipt_code := NULL;
            BEGIN
              SELECT  xxwfil.frq_item_location_id
                     ,xxwfil.frq_item_location_code
              INTO    ln_receipt_code
                     ,lv_receipt_code
              FROM   xxwsh_frq_item_locations xxwfil
              WHERE  xxwfil.item_location_id         =  lr_xwsp_rec.receipt_lct_id
              AND    xxwfil.item_id                  =  lr_xwsp_rec.item_id
              AND    xxwfil.frq_item_location_code   IS NOT NULL
              AND    xxwfil.frq_item_location_id     IS NOT NULL
              AND    xxwfil.frq_item_location_code   <> lr_xwsp_rec.receipt_lct_code
              ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE no_action_expt;
            END;
--              IF (ln_receipt_code IS NULL) THEN
--                RAISE no_action_expt;
          END IF;
--            END;
--          ELSIF (ln_receipt_code IS NULL) THEN
--            RAISE no_action_expt;  
--          END IF;
--          END;
          lr_xwsp_rec.frq_location_id       := lr_xwsp_rec.receipt_lct_code;
          lr_xwsp_rec.receipt_org_id           := ln_receipt_code;
          lr_xwsp_rec.receipt_lct_code         := lv_receipt_code;
       -- �H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          lr_xwsp_rec.receipt_org_id      := NULL;
          lr_xwsp_rec.receipt_lct_code     := NULL;
          lr_xwsp_rec.frq_location_id     := NULL;
          IF (lv_retcode = cv_status_error) THEN
            RAISE internal_process_expt;
          END IF;
        EXCEPTION
          WHEN no_action_expt THEN
          NULL;
        END;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '��\�q�ɑ��݃`�F�b�N��' 
          );  
-------------------------------------------------------
        --���q�ɑΏۃt���OYes�̏ꍇ
        IF (lr_xwsp_rec.own_flg = cv_own_flg_on) AND (ln_own_flg_cnt = 0) THEN
          ln_own_flg_cnt                       := ln_own_flg_cnt + 1;
      --���S����
          lr_xwsp_rec.org_data_lvl             := cn_data_lvl_output;                          --�g�D�f�[�^���x��
          lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.ship_org_id;        --�ړ����g�DID
          lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.ship_org_code;      --�ړ����g�D�R�[�h
          lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.ship_org_name;      --�ړ����g�D��
          lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.ship_lct_id;        --�ړ����ۊǏꏊID
          lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.ship_lct_code;      --�ړ����ۊǏꏊ�R�[�h
          lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.ship_lct_name;      --�ړ����ۊǏꏊ��
          lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.ship_calendar_code; --�ړ����J�����_�R�[�h
          lr_xwsp_rec.receipt_org_id           := get_wk_ship_planning_rec.ship_org_id;        --�ړ����g�DID
          lr_xwsp_rec.receipt_org_code         := get_wk_ship_planning_rec.ship_org_code;      --�ړ����g�D�R�[�h
          lr_xwsp_rec.receipt_org_name         := get_wk_ship_planning_rec.ship_org_name;      --�ړ����g�D��
          lr_xwsp_rec.receipt_lct_id           := get_wk_ship_planning_rec.ship_lct_id;        --�ړ����ۊǏꏊID
          lr_xwsp_rec.receipt_lct_code         := get_wk_ship_planning_rec.ship_lct_code;      --�ړ����ۊǏꏊ�R�[�h
          lr_xwsp_rec.receipt_lct_name         := get_wk_ship_planning_rec.ship_lct_name;      --�ړ����ۊǏꏊ��
          lr_xwsp_rec.receipt_calendar_code    := get_wk_ship_planning_rec.ship_calendar_code; --�ړ����J�����_�R�[�h
          lr_xwsp_rec.cnt_ship_org             := cn_cnt_from;                                 --�e���� �Œ�l1���Z�b�g
--20091120_Ver2.3_I_E_479_018_SCS.Goto_MOD_START
--          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.product_schedule_date;  --�o�ד�
--          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.product_schedule_date;  --���ד�
          lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;      --�o�ד�
          lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.shipping_date;      --���ד�
--20091120_Ver2.3_I_E_479_018_SCS.Goto_MOD_END
          lr_xwsp_rec.delivery_lead_time       := cn_delivery_lead_time;                           --�z�����[�h�^�C��
          lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;         --�o�׎��уy�[�X
         -- lr_xwsp_rec.shipping_type            := get_plant_ship_rec.ship_plan_type;               --�o�׌v��敪
          --���S����
          --
        -- ===============================
        -- �o�׃y�[�X�擾����
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- �H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP get_plant_ship_loop;
      IF (ln_loop_cnt = 0) THEN
        RAISE no_data_skip_expt;
      END IF;
      EXCEPTION
      WHEN no_data_skip_expt THEN
        EXIT;
      END;
    END LOOP get_wk_loop;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
--    -- *** ���[�J���萔 ***
--
--    -- *** ���[�J���ϐ� ***
    ln_org_data_lvl       NUMBER := 1;   --���񃋁[�v�̓f�[�^�o�̓��x��
    ln_loop_cnt           NUMBER := 0;   --���[�v�J�E���g
    ln_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
    ln_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE := NULL;
    ln_dual_chk           NUMBER := 0;
    ln_quantity           NUMBER := 0;
    ln_working_days       NUMBER := 0;
    ln_shipped_quantity  NUMBER := 0;
    ln_count_check        NUMBER;        --�d�����R�[�h�`�F�b�N�p
    ln_item_flg           NUMBER;
    ln_count_label        NUMBER;
    ln_receipt_code       NUMBER := NULL;
    lv_receipt_code       VARCHAR2(4) := NULL;
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
        ,plant_mark
        ,own_flg
        ,inventory_item_id
        ,item_id
        ,item_no
        ,item_name
        ,num_of_case
        ,palette_max_cs_qty
        ,palette_max_step_qty
        ,product_schedule_date
        ,product_schedule_qty
        ,ship_org_id
        ,ship_org_code
        ,ship_org_name
        ,ship_lct_id
        ,ship_lct_code
        ,ship_lct_name
        ,ship_calendar_code
        ,receipt_org_id
        ,receipt_org_code
        ,receipt_org_name
        ,receipt_lct_id
        ,receipt_lct_code
        ,receipt_lct_name
        ,receipt_calendar_code
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
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = ln_org_data_lvl
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      ORDER BY product_schedule_date,item_no,plant_org_id
      ;
    --�o�H���擾�J�[�\��(�o�ׁ����)
    CURSOR get_plant_ship_cur IS
      SELECT
        inventory_item_id            inventory_item_id                                              --�݌ɕi��ID
       ,organization_id              organization_id                                                --�g�DID
       ,source_organization_id       source_organization_id                                         --�o�בg�D
       ,receipt_organization_id      receipt_organization_id                                        --����g�D
       ,own_flg                      own_flg                                                        --���q�Ƀt���O
   --    ,ship_plan_type               ship_plan_type                                                 --�o�׌v��敪
       ,yusen                        yusen                                                          --������D��x
       ,row_number                   row_number
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
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id     --���͍��ڂ̑g�D�i��id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = ln_organization_id
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag              = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)  >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
            )
          ) keiro,
          (
            SELECT
              inventory_item_id          inventory_item_id                                           --�݌ɕi��ID
             ,organization_id            organization_id                                             --�g�DID
             ,sourcing_rule_type         sourcing_rule_type                                          --�\�[�X���[���^�C�v
             ,source_organization_id     source_organization_id                                      --�o�בg�D
             ,receipt_organization_id    receipt_organization_id                                     --����g�D
             ,own_flg                    own_flg                                                     --���q�Ƀt���O
             ,ship_plan_type             ship_plan_type                                              --�o�׌v��敪
             ,yusen                      yusen                                                       --������D��x
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
                                                      AND start_date_active <= gd_process_date
                                                      AND NVL(end_date_active,gd_process_date) >= gd_process_date
                                                      AND language = cv_flv_language)
              AND    mas.assignment_set_id        = msa.assignment_set_id
              AND   (msa.inventory_item_id        = ln_inventory_item_id
              OR    msa.inventory_item_id        IS NULL)
              AND    msso.source_organization_id  = TO_NUMBER(fnd_profile.value(cv_master_org_id))
              AND    msso.sr_receipt_id           = msro.sr_receipt_id
              AND    msro.effective_date         <= io_xwsp_rec.product_schedule_date
              AND    NVL(msro.disable_date,io_xwsp_rec.product_schedule_date)  >= io_xwsp_rec.product_schedule_date
              AND    flv.lookup_type              = cv_assign_type_priority
              AND    flv.enabled_flag             = cv_flv_enabled_flg_y
              AND    flv.start_date_active       <= gd_process_date
              AND    NVL(flv.end_date_active,gd_process_date)         >= gd_process_date
              AND    flv.lookup_code              = TO_CHAR(msa.assignment_type)
              AND    flv.language                 = cv_flv_language
              ORDER BY yusen
            )
            WHERE ROWNUM = 1
          ) dummy
          WHERE keiro.receipt_organization_id = NVL(dummy.organization_id(+),keiro.receipt_organization_id)
        )
      )
      WHERE row_number <= 1
    ;
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec   xxcop_wk_ship_planning%ROWTYPE := NULL;
    get_wk_ship_planning_rec get_wk_ship_planning_cur%ROWTYPE;
    get_plant_ship_rec get_plant_ship_cur%ROWTYPE;
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
    );
    <<lvl_countup_loop>>
    LOOP
    OPEN get_wk_ship_planning_cur;
    <<get_wk_loop>>
    LOOP
    FETCH get_wk_ship_planning_cur INTO  get_wk_ship_planning_rec;
      IF (get_wk_ship_planning_cur%NOTFOUND)
         OR  (get_wk_ship_planning_cur%ROWCOUNT = 0) THEN
          --ln_item_flg := 1;
          EXIT;
      END IF;
      ln_count_label  := ln_org_data_lvl + 1;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||'1'
    );
      --�ϐ�������
      ln_item_flg := 1;
      lr_xwsp_rec := NULL;
      --
      --�H��o�׃��[�N���R�[�h�Z�b�g
      --���S����
      --�H��o�׌v��Work�e�[�u��ID
      lr_xwsp_rec.transaction_id           := get_wk_ship_planning_rec.transaction_id;
--      IF (ln_org_data_lvl = 1) THEN
      lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl + 1;                                 --�g�D�f�[�^���x��
--      ELSE
--      lr_xwsp_rec.org_data_lvl             := ln_org_data_lvl;
--      END IF;
      lr_xwsp_rec.plant_org_id             := get_wk_ship_planning_rec.plant_org_id;           --�H��q��ID
      lr_xwsp_rec.plant_org_code           := get_wk_ship_planning_rec.plant_org_code;         --�H��q�ɃR�[�h
      lr_xwsp_rec.plant_org_name           := get_wk_ship_planning_rec.plant_org_name;         --�H��q�ɖ�
      lr_xwsp_rec.plant_mark               := get_wk_ship_planning_rec.plant_mark;             --�H��ŗL�L��
      lr_xwsp_rec.own_flg                  := get_wk_ship_planning_rec.own_flg;                --���H��Ώۃt���O
      lr_xwsp_rec.inventory_item_id        := get_wk_ship_planning_rec.inventory_item_id;      --�݌ɕi��ID
      lr_xwsp_rec.item_id                  := get_wk_ship_planning_rec.item_id;                --OPM�i��ID
      lr_xwsp_rec.item_no                  := get_wk_ship_planning_rec.item_no;                --�i�ڃR�[�h
      lr_xwsp_rec.item_name                := get_wk_ship_planning_rec.item_name;              --�i�ږ���
      lr_xwsp_rec.num_of_case              := get_wk_ship_planning_rec.num_of_case;            --�P�[�X����
      lr_xwsp_rec.palette_max_cs_qty       := get_wk_ship_planning_rec.palette_max_cs_qty;     --�z��
      lr_xwsp_rec.palette_max_step_qty     := get_wk_ship_planning_rec.palette_max_step_qty;   --�i��
      lr_xwsp_rec.product_schedule_date    := get_wk_ship_planning_rec.product_schedule_date;  --���Y�\���
      lr_xwsp_rec.product_schedule_qty     := get_wk_ship_planning_rec.product_schedule_qty;   --���Y�v�搔
      lr_xwsp_rec.ship_org_id              := get_wk_ship_planning_rec.receipt_org_id;         --�ړ����g�DID
      lr_xwsp_rec.ship_org_code            := get_wk_ship_planning_rec.receipt_org_code;       --�ړ����g�D�R�[�h
      lr_xwsp_rec.ship_org_name            := get_wk_ship_planning_rec.receipt_org_name;       --�ړ����g�D��
      lr_xwsp_rec.ship_lct_id              := get_wk_ship_planning_rec.receipt_lct_id;         --�ړ����ۊǏꏊID
      lr_xwsp_rec.ship_lct_code            := get_wk_ship_planning_rec.receipt_lct_code;       --�ړ����ۊǏꏊ�R�[�h
      lr_xwsp_rec.ship_lct_name            := get_wk_ship_planning_rec.receipt_lct_name;       --�ړ����ۊǏꏊ��
      lr_xwsp_rec.ship_calendar_code       := get_wk_ship_planning_rec.receipt_calendar_code;  --�ړ����J�����_�R�[�h
      lr_xwsp_rec.cnt_ship_org             := get_wk_ship_planning_rec.cnt_ship_org;           --�e�q�Ɍ���
      lr_xwsp_rec.shipping_date            := get_wk_ship_planning_rec.shipping_date;          --�o�ד�
      lr_xwsp_rec.receipt_date             := get_wk_ship_planning_rec.receipt_date;           --���ד�
      lr_xwsp_rec.delivery_lead_time       := get_wk_ship_planning_rec.delivery_lead_time;     --�z�����[�h�^�C��
      lr_xwsp_rec.shipping_pace            := get_wk_ship_planning_rec.shipping_pace;          --�o�׎��уy�[�X
      lr_xwsp_rec.under_lvl_pace           := get_wk_ship_planning_rec.under_lvl_pace;         --���ʑq�ɏo�׃y�[�X
      lr_xwsp_rec.schedule_qty             := get_wk_ship_planning_rec.schedule_qty;           --�v�搔
      lr_xwsp_rec.before_stock             := get_wk_ship_planning_rec.before_stock;           --�O�݌�
      lr_xwsp_rec.after_stock              := get_wk_ship_planning_rec.after_stock;            --��݌�
      lr_xwsp_rec.stock_days               := get_wk_ship_planning_rec.stock_days;             --�݌ɓ���
      lr_xwsp_rec.assignment_set_type      := get_wk_ship_planning_rec.assignment_set_type;    --�����Z�b�g�敪
      lr_xwsp_rec.assignment_type          := get_wk_ship_planning_rec.assignment_type;        --������^�C�v
      lr_xwsp_rec.sourcing_rule_type       := get_wk_ship_planning_rec.sourcing_rule_type;     --�\�[�X���[���^�C�v
      lr_xwsp_rec.sourcing_rule_name       := get_wk_ship_planning_rec.sourcing_rule_name;     --�\�[�X���[����
      lr_xwsp_rec.shipping_type            := get_wk_ship_planning_rec.shipping_type;          --�o�׌v��敪
    --  lr_xwsp_rec.shipping_type            := NULL;          --�o�׌v��敪

      --
      --�J�[�\���ϐ����
      ln_organization_id   := lr_xwsp_rec.ship_org_id;--�����
      ln_inventory_item_id := lr_xwsp_rec.inventory_item_id;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '�J�[�\���ϐ�'||TO_CHAR(ln_organization_id)
    );
      --
      --�H��o�׌v�搧��}�X�^������g�D�f�[�^���o�i�o�ׁ�����j
      <<get_plant_ship_loop>>
      OPEN get_plant_ship_cur;
      LOOP
      FETCH get_plant_ship_cur INTO get_plant_ship_rec;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name||'2'
    );
        IF (get_plant_ship_cur%NOTFOUND)
            OR  (get_plant_ship_cur%ROWCOUNT = 0) THEN
          --UPDATE �����v�惏�[�N�e�[�u������WK2���R�[�h�̃��x��
            UPDATE xxcop_wk_ship_planning xxwsp
            SET xxwsp.org_data_lvl = ln_count_label
            WHERE xxwsp.transaction_id         = lr_xwsp_rec.transaction_id
            AND   xxwsp.plant_org_id           = lr_xwsp_rec.plant_org_id
            AND   xxwsp.inventory_item_id      = lr_xwsp_rec.inventory_item_id
            AND   xxwsp.product_schedule_date  = lr_xwsp_rec.product_schedule_date
            AND   xxwsp.org_data_lvl >= ln_count_label   --���x���ȏ�ln_count_label
            AND   xxwsp.org_data_lvl <= ln_org_data_lvl  --���x���ȉ�ln_org_data_lvl
            ;
            EXIT;
        END IF;
        --���[�v�ϐ��Z�b�g
        lr_xwsp_rec.receipt_org_id          := get_plant_ship_rec.receipt_organization_id;--�����
        lr_xwsp_rec.own_flg                 := get_plant_ship_rec.own_flg;
   --     lr_xwsp_rec.shipping_type           := get_plant_ship_rec.ship_plan_type;
        -- ===================================
        -- �q�ɏ��擾����
        -- ===================================
        xxcop_common_pkg2.get_loct_info(
           id_target_date         =>       lr_xwsp_rec.product_schedule_date  --�i����1�Ŏ擾�j�v����t
          ,in_organization_id     =>       lr_xwsp_rec.receipt_org_id         --�i����1�Ŏ擾�j�ړ���q��ID
          ,ov_organization_code   =>       lr_xwsp_rec.receipt_org_code       -- �g�D�R�[�h
          ,ov_organization_name   =>       lr_xwsp_rec.receipt_org_name       -- �g�D����
          ,on_loct_id             =>       lr_xwsp_rec.receipt_lct_id         -- �ۊǑq��ID
          ,ov_loct_code           =>       lr_xwsp_rec.receipt_lct_code       -- �ۊǑq�ɃR�[�h
          ,ov_loct_name           =>       lr_xwsp_rec.receipt_lct_name       -- �ۊǑq�ɖ���
          ,ov_calendar_code       =>       lr_xwsp_rec.receipt_calendar_code  -- �J�����_�R�[�h
          ,ov_errbuf              =>       lv_errbuf               --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             =>       lv_retcode              --   ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              =>       lv_errmsg               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_id
                        );
          RAISE global_api_expt;
        --�f�[�^��1�����擾�ł��Ȃ������ꍇ�A�q�ɏ��擾�G���[���o�͂��A�㏈�����~
        ELSIF (lv_retcode = cv_status_warn) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00050
                          ,iv_token_name1  => cv_msg_00050_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_org_code
                        );
          RAISE internal_process_expt;
        END IF;
        -- ===============================
        -- �o�׃y�[�X�擾����
        -- ===============================
        get_shipping_pace(
          io_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF; 
        -- ===================================
        -- �z�����[�h�^�C���擾����
        -- ===================================
        xxcop_common_pkg2.get_deliv_lead_time   (
           id_target_date       =>      lr_xwsp_rec.product_schedule_date  --   (����1�Ŏ擾�j�v����t
          ,iv_from_loct_code    =>      lr_xwsp_rec.ship_lct_code         --   (����1�Ŏ擾�j�ړ����ۊǏꏊ�R�[�h
          ,iv_to_loct_code      =>      lr_xwsp_rec.receipt_lct_code      --   (����4�Ŏ擾�j�ړ���ۊǏꏊ�R�[�h
          ,on_delivery_lt       =>      lr_xwsp_rec.delivery_lead_time     --   ���[�h�^�C��(��)
          ,ov_errbuf            =>      lv_errbuf                          --   ���[�U�[�E�G���[�E���b�Z�[�W
          ,ov_retcode           =>      lv_retcode                          -- ���^�[���E�R�[�h
          ,ov_errmsg            =>      lv_errmsg                         --   �G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00053
                          ,iv_token_name1  => cv_msg_00053_token_1
                          ,iv_token_value1 => lr_xwsp_rec.ship_lct_code
                          ,iv_token_name2  => cv_msg_00053_token_2
                          ,iv_token_value2 => lr_xwsp_rec.receipt_lct_code
                        );
          RAISE internal_process_expt;
        END IF;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name || 'lv_retcode' || lv_retcode 
    );
        -- ���ד��擾����
        xxcop_common_pkg2.get_receipt_date(
           iv_calendar_code         =>      lr_xwsp_rec.ship_calendar_code
          ,in_organization_id       =>      lr_xwsp_rec.receipt_org_id
          ,in_loct_id               =>      lr_xwsp_rec.receipt_lct_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_shipment_date         =>      lr_xwsp_rec.product_schedule_date
          ,id_shipment_date         =>      lr_xwsp_rec.shipping_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,in_lead_time             =>      lr_xwsp_rec.delivery_lead_time
          ,od_receipt_date          =>      lr_xwsp_rec.receipt_date
          ,ov_errbuf                =>      lv_errbuf
          ,ov_retcode               =>      lv_retcode
          ,ov_errmsg                =>      lv_errmsg
        );
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name || '���ד�' || TO_CHAR(lr_xwsp_rec.receipt_date,'YYYY/MM/DD')
    );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        ELSIF (lr_xwsp_rec.receipt_date IS NULL) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00066
                       ,iv_token_name1  => cv_msg_00066_token_1
                       ,iv_token_value1 => lr_xwsp_rec.receipt_lct_code
                       ,iv_token_name2  => cv_msg_00066_token_2
                       ,iv_token_value2 => lr_xwsp_rec.ship_calendar_code
                       ,iv_token_name3  => cv_msg_00066_token_3
                       ,iv_token_value3 => TO_CHAR(lr_xwsp_rec.product_schedule_date,cv_date_format_slash)
                      );
          RAISE internal_process_expt;
        END IF;
        -- �H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
        IF (lv_retcode = cv_status_error) THEN
          RAISE internal_process_expt;
        END IF;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '��\�q�ɑ��݃`�F�b�N�O' 
          );  
-------------------------------------------------------
        --��\�q�ɑ��݃`�F�b�N
        BEGIN
          BEGIN
            SELECT  mil2.organization_id
                   ,mil.attribute5
            INTO   ln_receipt_code
                  ,lv_receipt_code
            FROM    mtl_item_locations mil
                   ,(SELECT  mil3.organization_id  organization_id
                            , mil3.segment1        segment1
                     FROM   mtl_item_locations mil3
                     WHERE  mil3.segment1 =  mil3.attribute5
                     AND    mil3.attribute5 IS NOT NULL) mil2
            WHERE    mil.attribute5 IS NOT NULL
            AND      mil.segment1 = lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 <> lr_xwsp_rec.receipt_lct_code
            AND      mil.attribute5 = mil2.segment1(+)
            ; 
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'when_no_data_found'
          );  
              RAISE no_action_expt;
          END;
          IF (ln_receipt_code IS NULL and lv_receipt_code = cv_org_code) THEN
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'zzzz'
          );  
            ln_receipt_code := NULL;
            lv_receipt_code := NULL;
            BEGIN
              SELECT  xxwfil.frq_item_location_id
                     ,xxwfil.frq_item_location_code
              INTO    ln_receipt_code
                     ,lv_receipt_code
              FROM   xxwsh_frq_item_locations xxwfil
              WHERE  xxwfil.item_location_id         =  lr_xwsp_rec.receipt_lct_id
              AND    xxwfil.item_id                  =  lr_xwsp_rec.item_id
              AND    xxwfil.frq_item_location_code   IS NOT NULL
              AND    xxwfil.frq_item_location_id     IS NOT NULL
              AND    xxwfil.frq_item_location_code   <> lr_xwsp_rec.receipt_lct_code
              ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RAISE no_action_expt;
            END;
--              IF (ln_receipt_code IS NULL) THEN
--                RAISE no_action_expt;
          END IF;
--            END;
--          ELSIF (ln_receipt_code IS NULL) THEN
--            RAISE no_action_expt;  
--          END IF;
--          END;
          lr_xwsp_rec.frq_location_id       := lr_xwsp_rec.receipt_lct_code;
          lr_xwsp_rec.receipt_org_id           := ln_receipt_code;
          lr_xwsp_rec.receipt_lct_code         := lv_receipt_code;
       -- �H��o�׌v�惏�[�N�e�[�u���o�^����
        insert_wk_tbl(
          ir_xwsp_rec          =>   lr_xwsp_rec,           --   �H��o�׃��[�N���R�[�h�^�C�v
          ov_errmsg            =>   lv_errmsg,             --   �G���[�E���b�Z�[�W
          ov_errbuf            =>   lv_errbuf,             --   ���^�[���E�R�[�h
          ov_retcode           =>   lv_retcode             --   ���[�U�[�E�G���[�E���b�Z�[�W
          );
          lr_xwsp_rec.receipt_org_id      := NULL;
          lr_xwsp_rec.receipt_lct_code     := NULL;
          lr_xwsp_rec.frq_location_id     := NULL;
          IF (lv_retcode = cv_status_error) THEN
            RAISE internal_process_expt;
          END IF;
        EXCEPTION
          WHEN no_action_expt THEN
          NULL;
        END;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '��\�q�ɑ��݃`�F�b�N��' 
          );  
-------------------------------------------------------
        --==============================
        --�d�����R�[�h�`�F�b�N
        --==============================
        BEGIN
        SELECT COUNT(1)
        INTO ln_count_check
        FROM   xxcop_wk_ship_planning  xxwsp
        WHERE xxwsp.transaction_id         = lr_xwsp_rec.transaction_id
        AND   xxwsp.plant_org_id           = lr_xwsp_rec.plant_org_id
        AND   xxwsp.inventory_item_id      = lr_xwsp_rec.inventory_item_id
        AND   xxwsp.product_schedule_date  = lr_xwsp_rec.product_schedule_date
        AND   xxwsp.cnt_ship_org           <> 1
        START WITH
              xxwsp.receipt_org_id = lr_xwsp_rec.receipt_org_id
        CONNECT BY PRIOR
                  xxwsp.ship_org_id = xxwsp.receipt_org_id
        AND PRIOR  xxwsp.cnt_ship_org           <> 1 
         ;
        EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_00060
                          ,iv_token_name1  => cv_msg_00060_token_1
                          ,iv_token_value1 => lr_xwsp_rec.receipt_lct_name
                          ,iv_token_name2  => cv_msg_00060_token_2
                          ,iv_token_value2 => lr_xwsp_rec.item_no
                          );
          RAISE internal_process_expt;
        END;
        END LOOP get_plant_ship_loop;
      CLOSE get_plant_ship_cur;
        --ln_org_data_lvl := ln_org_data_lvl + 1;
      END LOOP get_wk_loop;
    CLOSE get_wk_ship_planning_cur;
      IF ln_item_flg = 1 THEN
        ln_org_data_lvl := ln_count_label;
        ln_item_flg := 0;
      ELSE
        EXIT;
      END IF;
    END LOOP lvl_countup_loop;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  /**********************************************************************************
   * Procedure Name   : get_pace_sum
   * Description      : ���ʑq�ɏo�׃y�[�X�擾�iA-51�j
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
    ln_undr_lvl_pace  NUMBER := 0;
    ln_undr_lvl_count NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    --
    CURSOR get_wk_cur IS
      SELECT NVL(xxwsp.shipping_pace,0)  under_lvl_pace
            ,xxwsp.receipt_org_id        receipt_org_id
      FROM   xxcop_wk_ship_planning  xxwsp
        WHERE  xxwsp.ship_org_id        =     in_receipt_org_id
        AND  xxwsp.plant_org_id         =     in_plant_org_id
        AND  xxwsp.inventory_item_id    =     in_inventory_item_id
        AND  xxwsp.product_schedule_date    = id_product_schedule_date
        AND  xxwsp.transaction_id           = in_transaction_id
        AND  xxwsp.org_data_lvl             >= cn_data_lvl_yokomt
        ;
    -- *** ���[�J���E���R�[�h ***
    get_wk_rec   get_wk_cur%ROWTYPE := NULL;

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
    OPEN get_wk_cur;
    <<get_wk_loop>>
    LOOP
      FETCH get_wk_cur INTO get_wk_rec;
        EXIT WHEN get_wk_cur%NOTFOUND;
      --
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
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      ln_undr_lvl_count := ln_undr_lvl_count + ln_undr_lvl_pace + get_wk_rec.under_lvl_pace;
    END LOOP get_wk_loop;
    CLOSE get_wk_cur;
      on_undr_lvl_pace := ln_undr_lvl_count;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Description      : �o�׃y�[�X�擾�����iA-5�j
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
    ln_under_lvl_count    NUMBER := 0;        -- �v�o�׃y�[�X
    ln_receipt_org_id     NUMBER := NULL;     -- �ړ���g�DID
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�o�̓f�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id             transaction_id
        ,plant_org_id               plant_org_id
        ,product_schedule_date      product_schedule_date
        ,receipt_org_id             receipt_org_id
        ,inventory_item_id          inventory_item_id
        ,shipping_pace              shipping_pace
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id       IS NULL
      ;
    --
    --���[�N�e�[�u���擾�J�[�\��(��\�q�Ɂj
    CURSOR get_wk_ship_organization_cur IS
      SELECT 
         transaction_id             transaction_id
        ,plant_org_id               plant_org_id
        ,product_schedule_date      product_schedule_date
        ,receipt_org_id             receipt_org_id
        ,inventory_item_id          inventory_item_id
        ,frq_location_id            frq_location_id
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id       IS NOT NULL
      ;
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
    <<get_wk_ship_planning_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      ln_receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
      --���ʑg�D���擾
      get_pace_sum(
                    in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_planning_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_planning_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_planning_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_planning_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --�v�o�׃y�[�X �� �i���q�ɏo�׃y�[�X �{ ���ʑg�D���擾���ʑq�ɏo�׃y�[�X�j
      ln_under_lvl_count := (get_wk_ship_planning_rec.shipping_pace + ln_undr_lvl_pace) ;
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = ln_under_lvl_count
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
    END LOOP get_wk_ship_planning_loop;
    ln_under_lvl_count := NULL;
    <<get_wk_ship_organization_loop>>
    FOR get_wk_ship_organization_rec IN get_wk_ship_organization_cur LOOP
          ln_receipt_org_id := get_wk_ship_organization_rec.receipt_org_id;
      --���ʑg�D���擾
      get_pace_sum(
                    in_receipt_org_id         => ln_receipt_org_id
                   ,in_plant_org_id           => get_wk_ship_organization_rec.plant_org_id
                   ,in_inventory_item_id      => get_wk_ship_organization_rec.inventory_item_id
                   ,id_product_schedule_date  => get_wk_ship_organization_rec.product_schedule_date
                   ,in_transaction_id         => get_wk_ship_organization_rec.transaction_id
                   ,on_undr_lvl_pace          => ln_undr_lvl_pace
                   ,ov_errbuf                 => lv_errbuf
                   ,ov_retcode                => lv_retcode
                   ,ov_errmsg                 => lv_errmsg
                   );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      --�v�o�׃y�[�X �� ���ʑg�D���擾���ʑq�ɏo�׃y�[�X
      ln_under_lvl_count := ln_undr_lvl_pace;
      BEGIN
        UPDATE xxcop_wk_ship_planning
        SET under_lvl_pace = under_lvl_pace + ln_under_lvl_count
        WHERE plant_org_id = io_xwsp_rec.plant_org_id
        AND   inventory_item_id = io_xwsp_rec.inventory_item_id
        AND   product_schedule_date = io_xwsp_rec.product_schedule_date
        AND   org_data_lvl = cn_data_lvl_output
        AND   transaction_id = io_xwsp_rec.transaction_id
        AND   receipt_lct_code = get_wk_ship_organization_rec.frq_location_id
        ;
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
    END LOOP get_wk_ship_organization_loop;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
     io_xwsp_rec            IN OUT xxcop_wk_ship_planning%ROWTYPE   --   �H��o�׃��[�N���R�[�h�^�C�v
    ,ov_errbuf                OUT VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode               OUT VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                OUT VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_plant_org_id          xxcop_wk_ship_planning.plant_org_id%TYPE := NULL;
    ld_product_schedule_date   xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
    ld_receipt_date            xxcop_wk_ship_planning.receipt_date%TYPE := NULL;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
    ln_before_stock            xxcop_wk_ship_planning.before_stock%TYPE := NULL;
    ln_after_stock             xxcop_wk_ship_planning.after_stock%TYPE := NULL;
    ln_num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE := NULL;
    ln_working_days            NUMBER := 0;
    ln_receipt_plan_qty        NUMBER := 0;
    ln_onhand_qty              NUMBER := 0;
    ld_from_date               xxcop_wk_ship_planning.product_schedule_date%TYPE := NULL;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[�N�e�[�u���擾�J�[�\���i�o�̓f�[�^���x���j
    CURSOR get_wk_ship_planning_cur IS
      SELECT
         transaction_id           transaction_id
        ,inventory_item_id        inventory_item_id
        ,item_no                  item_no
        ,item_id                  item_id
        ,product_schedule_date    product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,receipt_date             receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,receipt_org_id           receipt_org_id
        ,receipt_org_code         receipt_org_code
        ,receipt_lct_id           receipt_lct_id
        ,under_lvl_pace           under_lvl_pace
        ,plant_org_id             plant_org_id
        ,cnt_ship_org             cnt_ship_org
      FROM
        xxcop_wk_ship_planning
      WHERE org_data_lvl          = cn_data_lvl_output
      AND   transaction_id        = io_xwsp_rec.transaction_id
      AND   plant_org_id          = io_xwsp_rec.plant_org_id
      AND   inventory_item_id     = io_xwsp_rec.inventory_item_id
      AND   product_schedule_date = io_xwsp_rec.product_schedule_date
      AND   frq_location_id         IS NULL
      ORDER BY product_schedule_date,item_no,plant_org_id;
    --
    -- *** ���[�J���E���R�[�h ***
    get_wk_ship_planning_rec     get_wk_ship_planning_cur%ROWTYPE := NULL;
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
    <<get_wk_ship_planning_loop>>
    FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
      --�ϐ�������
      ln_before_stock := NULL;
      --
--      lr_xwsp_rec.transaction_id := get_wk_ship_planning_rec.transaction_id;
--      lr_xwsp_rec.inventory_item_id := get_wk_ship_planning_rec.inventory_item_id;
--      lr_xwsp_rec.receipt_org_id := get_wk_ship_planning_rec.receipt_org_id
--      lr_xwsp_rec.product_schedule_date := get_wk_ship_planning_rec.product_schedule_date
--      lr_xwsp_rec.receipt_org_id := get_wk_ship_planning_rec.receipt_org_id;
--      lr_xwsp_rec.
      -- ===============
      -- ��݌Ɏ擾����
      -- ===============
      BEGIN
        SELECT
           inn_xxwsp.plant_org_id            plant_org_id
          ,inn_xxwsp.product_schedule_date   product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
          ,inn_xxwsp.receipt_date            receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
          ,inn_xxwsp.after_stock             after_stock
          ,inn_xxwsp.num_of_case             num_of_case
        INTO
           lv_plant_org_id
          ,ld_product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
          ,ld_receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
          ,ln_after_stock
          ,ln_num_of_case
        FROM(
             SELECT
                plant_org_id
               ,product_schedule_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
               ,receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
               ,after_stock
               ,num_of_case
             FROM  xxcop_wk_ship_planning
             WHERE transaction_id = get_wk_ship_planning_rec.transaction_id
               AND org_data_lvl = cn_data_lvl_output
               AND inventory_item_id = get_wk_ship_planning_rec.inventory_item_id
               AND receipt_org_id = get_wk_ship_planning_rec.receipt_org_id
               AND after_stock IS NOT NULL
             ORDER BY product_schedule_date DESC,plant_org_id DESC
             )  inn_xxwsp
        WHERE ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_after_stock := NULL;
      END;
      --��݌ɂ����q�ɂɑ��݂���Ƃ�
      IF (ln_after_stock IS NOT NULL) THEN
          --1�Ŏ擾�������Y�\������o�׈����ϓ��̏ꍇ�A
          --���ʊ֐��u�ғ������擾�����v���ړ���q�ɂ̉ғ��������擾���܂��B
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          IF (get_wk_ship_planning_rec.product_schedule_date >  gd_schedule_date) THEN
--            IF (ld_product_schedule_date > gd_schedule_date) THEN
--              ld_from_date := ld_product_schedule_date;
--            ELSIF (ld_product_schedule_date <= gd_schedule_date) THEN
--              ld_from_date := gd_schedule_date;
--            END IF;
          IF (get_wk_ship_planning_rec.receipt_date >  gd_schedule_date) THEN
            IF (ld_receipt_date > gd_schedule_date) THEN
              ld_from_date := ld_receipt_date + 1;
            ELSIF (ld_receipt_date <= gd_schedule_date) THEN
              ld_from_date := gd_schedule_date + 1;
            END IF;
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
            xxcop_common_pkg2.get_working_days(
               iv_calendar_code       =>    io_xwsp_rec.receipt_calendar_code
              ,in_organization_id     =>    NULL
              ,in_loct_id             =>    NULL
              ,id_from_date           =>    ld_from_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--              ,id_to_date             =>    get_wk_ship_planning_rec.product_schedule_date
              ,id_to_date             =>    get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
              ,on_working_days        =>    ln_working_days                                   --   �ғ�����
              ,ov_errbuf              =>    lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
              ,ov_retcode             =>    lv_errbuf        --   �G���[�E���b�Z�[�W
              ,ov_errmsg              =>    lv_retcode       --   ���^�[���E�R�[�h
              );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
          --���ɗ\��擾���� -- 2009/10/05 ���ɗ\�菈���Ȃ��i���ɗ\�萔���j
          xxcop_common_pkg2.get_stock_plan(
              in_loct_id        =>   get_wk_ship_planning_rec.receipt_lct_id  --   ����g�DID
             ,in_item_id        =>   get_wk_ship_planning_rec.item_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--             ,id_plan_date_from =>   ld_product_schedule_date
--             ,id_plan_date_to   =>   get_wk_ship_planning_rec.product_schedule_date
             ,id_plan_date_from =>   ld_receipt_date + 1
             ,id_plan_date_to   =>   get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
             ,on_quantity       =>   ln_receipt_plan_qty
             ,ov_errbuf         =>   lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
             ,ov_retcode        =>   lv_errbuf        --   �G���[�E���b�Z�[�W
             ,ov_errmsg         =>   lv_retcode       --   ���^�[���E�R�[�h
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --�擾�����ғ���������ѓ��ɗ\�萔���O�݌ɐ����擾���܂��B
          --�O�݌ɐ� �� 2.�Ŏ擾�̌�݌ɐ� �{ ���ɗ\�萔 �|�i1.�Ŏ擾�̉��ʑq�ɏo�׃y�[�X���ғ������j
          ln_before_stock := ln_after_stock + ln_receipt_plan_qty -
                             (get_wk_ship_planning_rec.under_lvl_pace * ln_working_days);
      --
      --��݌ɂ����݂��Ȃ��Ƃ�
      ELSIF (ln_after_stock IS NULL) THEN
        --
        --�莝�݌Ɏ擾����
        xxcop_common_pkg2.get_onhand_qty(
           in_loct_id         =>   get_wk_ship_planning_rec.receipt_lct_id          --   ����g�DID
          ,in_item_id         =>   get_wk_ship_planning_rec.item_id                 --   OPM�i��ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ,id_target_date     =>   get_wk_ship_planning_rec.product_schedule_date   --   �Ώۓ��t
          ,id_target_date     =>   get_wk_ship_planning_rec.receipt_date   --   �Ώۓ��t
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          ,id_allocated_date  =>   gd_schedule_date                                 --   �����ϓ�
          ,on_quantity        =>   ln_onhand_qty                                    -- �莝�݌ɐ���
          ,ov_errbuf          =>   lv_errmsg                                  --   ���[�U�[�E�G���[�E���b�Z�[�W
          ,ov_retcode         =>   lv_errbuf                                  --   �G���[�E���b�Z�[�W
          ,ov_errmsg          =>   lv_retcode                                 --   ���^�[���E�R�[�h
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --���Y�\������o�׈����ϓ��̏ꍇ�A���ʊ֐��u�ғ������擾�����v���ړ���q�ɂ̉ғ��������擾���܂��B
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--        IF (get_wk_ship_planning_rec.product_schedule_date > gd_schedule_date) THEN
        IF (get_wk_ship_planning_rec.receipt_date > gd_schedule_date) THEN
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
          xxcop_common_pkg2.get_working_days(
               iv_calendar_code       =>    io_xwsp_rec.receipt_calendar_code
              ,in_organization_id     =>    NULL
              ,in_loct_id             =>    NULL
              ,id_from_date           =>    gd_schedule_date + 1
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--              ,id_to_date             =>    get_wk_ship_planning_rec.product_schedule_date
              ,id_to_date             =>    get_wk_ship_planning_rec.receipt_date
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
              ,on_working_days        =>    ln_working_days                                   --   �ғ�����
              ,ov_errbuf              =>    lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W
              ,ov_retcode             =>    lv_errbuf        --   �G���[�E���b�Z�[�W
              ,ov_errmsg              =>    lv_retcode       --   ���^�[���E�R�[�h
              );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        ELSE
        --�o�׈����ϓ������Y�\�����薢���̏ꍇ�莝���݌ɐ��ʂ����̂܂ܑO�݌ɐ��Ƃ���i�ʏ�Ȃ��j
          ln_working_days := 0;  
        END IF;
        --
        --�擾�����ғ���������ѓ��ɗ\�萔���O�݌ɐ����擾���܂��B
        --�O�݌ɐ� �� �莝�݌ɐ��� �|�i1.�Ŏ擾�̉��ʑq�ɏo�׃y�[�X���ғ������j
        ln_before_stock := ln_onhand_qty - (get_wk_ship_planning_rec.under_lvl_pace * ln_working_days);
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '��݌ɂ����q�ɂɑ��݂��Ȃ��E�q��ID'||TO_CHAR(get_wk_ship_planning_rec.receipt_org_id)||
                          '�Ώۓ��t(���Y�\����j,'||TO_CHAR(get_wk_ship_planning_rec.product_schedule_date,cv_date_format_slash)||
                          '�����ϓ�,'||TO_CHAR(gd_schedule_date,cv_date_format_slash)||
                          '�ғ���'||TO_CHAR(ln_working_days)||
                          '�O�݌ɐ�'||TO_CHAR(ln_before_stock)||
                          '�莝�݌ɐ�'||TO_CHAR(ln_onhand_qty)||'-(���ʏo�׃y�[�X'||TO_CHAR(get_wk_ship_planning_rec.under_lvl_pace)||'*�ғ���'||TO_CHAR(ln_working_days)
    );
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
      io_xwsp_rec.receipt_org_id:= get_wk_ship_planning_rec.receipt_org_id;
    END LOOP get_wk_ship_planning_loop;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    ln_sum_pace             NUMBER := 0;
    ln_sum_before_stock     NUMBER := 0;
    ln_stock_days           NUMBER := 0;
    ln_stock                NUMBER := 0;
    ln_product_schedule_qty NUMBER := 0;
    ln_move_qty             NUMBER := 0;
    ln_after_stock          NUMBER := 0;
    ln_palette_qty          NUMBER := 0;
    lb_minus_flg            BOOLEAN := TRUE;
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
      AND   minus_flg             IS NULL
      AND   frq_location_id       IS NULL
      ORDER BY product_schedule_date,item_no,plant_org_code;
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
    LOOP
      BEGIN
        lb_minus_flg := TRUE;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '�o�בq��:'||io_xwsp_rec.plant_org_id
    );
        --���o�׃y�[�X�擾
        --�g�D�f�[�^���x��0�i�H��q�Ɂj���̑g�D�f�[�^���x��1�̕����q�ɂ̏o�׃y�[�X��
        --�O�݌ɐ������v���܂�
        SELECT
           product_schedule_qty        --�v�搔
          ,SUM(NVL(under_lvl_pace,0))  --���o�׃y�[�X
          ,SUM(NVL(before_stock,0))    --���O�݌ɐ�
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
        AND   minus_flg             IS NULL
        AND   frq_location_id       IS NULL
        GROUP BY transaction_id,plant_org_id,plant_org_code
                ,inventory_item_id,item_no,product_schedule_date,product_schedule_qty;
        -- ���v�Z�[���`�F�b�N
        --�g�D�f�[�^���x��0�i�H��q�Ɂj�̑��o�׃y�[�X�l���O��NULL�l�̏ꍇ�A
        --�Ώۑq�ɂ��X�L�b�v
        IF NVL(ln_sum_pace,0) = 0 THEN
        -- ���o�׃y�[�X�[���x�����b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00063
                         ,iv_token_name1  => cv_msg_00063_token_1
                         ,iv_token_value1 => io_xwsp_rec.plant_org_id
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          RAISE nested_loop_expt;
        END IF;
        --�݌ɓ����̎Z�o
        IF (ln_sum_pace <> 0) THEN
           --�݌ɓ���(�����_��2��)��(�v�搔 + �O�݌ɐ�)/���ʑq�ɏo�׃x�[�X
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--          ln_stock_days :=  ROUND(((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace));
          ln_stock_days :=  ROUND(((ln_product_schedule_qty + ln_sum_before_stock) / ln_sum_pace), 2);
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
        ELSE
          ln_stock_days :=  0;  --�ʏ�Ȃ�
        END IF;
        FOR get_wk_ship_planning_rec IN get_wk_ship_planning_cur LOOP
          --�݌ɐ����o�׃y�[�X�~�݌ɓ���
          ln_stock := get_wk_ship_planning_rec.under_lvl_pace * ln_stock_days;  --�o�׃y�[�X��0�̏ꍇ�A�݌ɐ���0�ɂȂ肤��
          --�ړ������݌ɐ��|���q�ɂ̑O�݌ɐ�
          IF (ln_stock <> 0) THEN
            ln_move_qty := ln_stock - get_wk_ship_planning_rec.before_stock;
          ELSE 
            ln_move_qty := 0;
           END IF;
  --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '�v�搔='||ln_move_qty
    );
  --
          -- �ړ�����0�ȏ�i�H��q�ɂ����q�ɂւ̌v�搔��0�ȏ�ňړ������݂���j
          IF (ln_move_qty >= 0) THEN 
          --�ړ��p���b�g�ϊ����P�[�X�����~�z���~�i��
          ln_palette_qty := get_wk_ship_planning_rec.num_of_case * get_wk_ship_planning_rec.palette_max_cs_qty * get_wk_ship_planning_rec.palette_max_step_qty;
          --�ړ��p���b�g���Z��̌v�搔
          ln_move_qty :=ln_palette_qty * ROUND(ln_move_qty / ln_palette_qty);
          --��݌ɐ�
          ln_after_stock := ln_move_qty + get_wk_ship_planning_rec.before_stock;
  --
  --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '�v�搔='||ln_move_qty || ',' || '��݌�='||ln_after_stock || ',' || '�݌ɓ���='||ln_stock_days
    );
  --
            BEGIN
              UPDATE xxcop_wk_ship_planning
              SET   schedule_qty = ln_move_qty
                   ,after_stock = ln_after_stock
                   ,stock_days =  ln_stock_days
              WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
              AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
              AND   org_data_lvl              = cn_data_lvl_output
              AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
              AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
              AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
              AND   frq_location_id         IS NULL 
              ;
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
          --�ړ������}�C�i�X�l�i��q�ɂ̑O�݌ɐ����H��q�ɂ̌v�搔���傫���ꍇ�j�̏ꍇ
          ELSE
            lb_minus_flg := FALSE;
            --�ړ���
            ln_move_qty   := 0;
            --�݌ɓ���
            ln_stock_days := 0;
            --��݌�
            ln_after_stock := get_wk_ship_planning_rec.before_stock;
            BEGIN
              UPDATE xxcop_wk_ship_planning
              SET   minus_flg    = cv_move_minus_flg_on
                   ,schedule_qty = ln_move_qty
                   ,after_stock  = ln_after_stock
                   ,stock_days   = ln_stock_days
              WHERE inventory_item_id         = get_wk_ship_planning_rec.inventory_item_id
              AND   transaction_id            = get_wk_ship_planning_rec.transaction_id
              AND   org_data_lvl              = cn_data_lvl_output
              AND   plant_org_id              = get_wk_ship_planning_rec.plant_org_id
              AND   product_schedule_date     = get_wk_ship_planning_rec.product_schedule_date
              AND   receipt_org_id            = get_wk_ship_planning_rec.receipt_org_id
              AND   frq_location_id         IS NULL
              ;
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
          END IF;
        END LOOP get_wk_ship_planning_cur;
      EXCEPTION
        WHEN nested_loop_expt THEN  
        NULL;
        WHEN NO_DATA_FOUND THEN  --�H��o�א���}�X�^�Ɋ�v��ɕR�t���q�ɂ��Ȃ��ꍇ
        NULL;
      END;
      EXIT WHEN lb_minus_flg;
    END LOOP;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    ,ov_errbuf           OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      ,ship_lct_code
      ,ship_org_name
      ,receipt_org_code
      ,receipt_lct_code
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
      ,ship_lct_code
      ,ship_org_name
      ,receipt_org_code
      ,receipt_lct_code
      ,receipt_org_name
      ,item_no
      ,item_name
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--      ,product_schedule_qty
--      ,before_stock
--      ,after_stock
--      ,stock_days
--      ,shipping_pace
      ,TRUNC(schedule_qty / num_of_case)
      ,TRUNC(before_stock / num_of_case)
      ,TRUNC(after_stock / num_of_case)
      ,ROUND(stock_days, 2)
      ,ROUND(under_lvl_pace / num_of_case)
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
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
      AND frq_location_id         IS NULL 
    ORDER BY ship_org_code,receipt_org_code,item_no,product_schedule_date
    ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    ,ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_buff  VARCHAR2(5000) := NULL;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_csv_output_cur IS
      SELECT
         shipping_date
        ,receipt_date
        ,ship_org_code
        ,ship_lct_code
        ,ship_org_name
        ,receipt_org_code
        ,receipt_lct_code
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
      FROM
        xxcop_wk_ship_planning_output
      WHERE transaction_id = in_transaction_id
      ORDER BY ship_lct_code,receipt_lct_code,item_no,schedule_date;
--
    -- *** ���[�J���E���R�[�h ***
    get_csv_output_rec get_csv_output_cur%ROWTYPE;
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
--  �w�b�_���̒��o
    lv_buff := xxccp_common_pkg.get_msg(                                                            
             iv_application  => cv_msg_appl_cont                                                    -- �A�v���P�[�V�����Z�k��
            ,iv_name         => cv_msg_10049                                                        -- ���b�Z�[�W�R�[�h
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
    -- �^�C�g���s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buff
    );
    --
    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP
      -- �f�[�^�s
      lv_buff :=          cv_csv_point || TO_CHAR(get_csv_output_rec.shipping_date,cv_date_format)
        || cv_csv_cont || cv_csv_point || TO_CHAR(get_csv_output_rec.receipt_date,cv_date_format)
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_org_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_lct_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.ship_org_name
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_org_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_lct_code
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.receipt_org_name
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.item_no
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.item_name
        || cv_csv_cont || get_csv_output_rec.schedule_qty
        || cv_csv_cont || get_csv_output_rec.before_stock
        || cv_csv_cont || get_csv_output_rec.after_stock
        || cv_csv_cont || get_csv_output_rec.stock_days
        || cv_csv_cont || get_csv_output_rec.shipping_pace
        || cv_csv_cont || cv_csv_point || get_csv_output_rec.plant_mark
        || cv_csv_cont || cv_csv_point || TO_CHAR(get_csv_output_rec.schedule_date,cv_date_format)
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
     iv_plan_from     IN    VARCHAR2    --   1.�v�旧�Ċ��ԁiFROM�j
    ,iv_plan_to       IN    VARCHAR2    --   2.�v�旧�Ċ��ԁiTO�j
    ,iv_pace_type     IN    VARCHAR2    --   3.�Ώۏo�׋敪
    ,iv_pace_from     IN    VARCHAR2    --   4.�o�׃y�[�X�v����ԁiFROM�j
    ,iv_pace_to       IN    VARCHAR2    --   5.�o�׃y�[�X�v����ԁiTO�j
    ,iv_forcast_from  IN    VARCHAR2    --   6.�o�ח\�����ԁiFROM)
    ,iv_forcast_to    IN    VARCHAR2    --   7.�o�ח\�����ԁiTO�j
    ,iv_schedule_date IN    VARCHAR2    --   8.�o�׈����ϓ�
    ,ov_errbuf        OUT   VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode       OUT   VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg        OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
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
    --�v�旧�Ċ���FROM�ATO�ɑ΂��āA��v�於�A��v����t���f�[�^���擾���܂��B
    CURSOR get_schedule_cur IS
      SELECT
         msdate.organization_id        plant_org_id                   --�H��q��
        ,msdate.inventory_item_id      inventory_item_id              --�݌ɕi��ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,msdate.schedule_date          schedule_date                  --�v����t
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,NVL(TO_DATE(msdate.attribute5,cv_date_format_slash), msdate.schedule_date)  product_schedule_date  --���Y�\���
        ,mp.organization_code          plant_org_code                 --�H��q�ɃR�[�h
        ,SUM(msdate.schedule_quantity) product_schedule_qty           --�v�搔��
      FROM
         mrp_schedule_designators  msdesi                             --��v�於�e�[�u��
        ,mrp_schedule_dates        msdate                             --��v����t�e�[�u��
        ,mtl_parameters            mp                                 --�g�D�p�����[�^
      WHERE  msdate.schedule_designator =  msdesi.schedule_designator
        AND  msdate.organization_id     =  msdesi.organization_id
        AND  msdate.schedule_date      >=  gd_plan_from
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--        AND  msdate.schedule_date      <   gd_plan_to
        AND  msdate.schedule_date      <=  gd_plan_to
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
        AND  msdesi.attribute1          =  cv_buy_type
        AND  msdate.organization_id     =  mp.organization_id
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        AND  msdate.schedule_level      =  cn_schedule_level
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
      GROUP BY
         msdate.organization_id                                                     --�H��q��ID
        ,msdate.inventory_item_id                                                   --�݌ɕi��ID
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_START
        ,msdate.schedule_date                                                       --�v����t
--20091029_Ver2.1_I_E_479_007_SCS.Goto_ADD_END
        ,NVL(TO_DATE(msdate.attribute5,cv_date_format_slash), msdate.schedule_date) --�v����t
        ,mp.organization_code                                                       --�g�D�R�[�h
      ORDER BY product_schedule_date, inventory_item_id, plant_org_id
      ;
    -- *** ���[�J���E���R�[�h ***
    lr_xwsp_rec          xxcop_wk_ship_planning%ROWTYPE := NULL;
    -- *** ���[�J����O ***
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    --      A-1 ��������
    -- ===============================
    init(
       iv_plan_from     =>      iv_plan_from        --   1.�v�旧�Ċ��ԁiFROM�j
      ,iv_plan_to       =>      iv_plan_to          --   2.�v�旧�Ċ��ԁiTO�j
      ,iv_pace_type     =>      iv_pace_type        --   3.�Ώۏo�׋敪
      ,iv_pace_from     =>      iv_pace_from        --   4.�o�׃y�[�X�v����ԁiFROM�j
      ,iv_pace_to       =>      iv_pace_to          --   5.�o�׃y�[�X�v����ԁiTO�j
      ,iv_forcast_from  =>      iv_forcast_from     --   6.�o�ח\�����ԁiFROM)
      ,iv_forcast_to    =>      iv_forcast_to       --   7.�o�ח\�����ԁiTO�j
      ,iv_schedule_date =>      iv_schedule_date    --   8.�o�׈����ϓ�
      ,ov_errbuf        =>      lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       =>      lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        =>      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
    <<Base_loop>>
    FOR get_schedule_rec IN get_schedule_cur LOOP
      --�Ώی���
      gn_target_cnt := gn_target_cnt + 1;
      --�ϐ�������
      lr_xwsp_rec := NULL;
      --�����s���J�E���g
      ln_loop_cnt := ln_loop_cnt + 1;
      --�H��o�׃��[�N���R�[�h�Z�b�g
      lr_xwsp_rec.transaction_id          := cn_request_id;                         -- �v��ID
      lr_xwsp_rec.org_data_lvl            := cn_data_lvl_plant;                     -- �g�D�f�[�^���x��
      lr_xwsp_rec.inventory_item_id       := get_schedule_rec.inventory_item_id;    -- �݌ɕi��ID
      lr_xwsp_rec.plant_org_id            := get_schedule_rec.plant_org_id;         -- �H��g�DID
      lr_xwsp_rec.ship_org_id             := get_schedule_rec.plant_org_id;         -- �ړ����g�DID
      lr_xwsp_rec.product_schedule_date   := get_schedule_rec.product_schedule_date;-- ���Y�\���
      lr_xwsp_rec.product_schedule_qty    := get_schedule_rec.product_schedule_qty; -- ���Y�v�搔
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_START
--      lr_xwsp_rec.shipping_date           := get_schedule_rec.product_schedule_date;-- �o�ד�
      lr_xwsp_rec.shipping_date           := get_schedule_rec.schedule_date;        -- �o�ד�
--20091029_Ver2.1_I_E_479_007_SCS.Goto_MOD_END
      --
      BEGIN
  --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
      iov_debug_mode => gv_debug_mode
     ,iv_value       => '�Ώۑg�D'||lr_xwsp_rec.plant_org_id
    );
  --
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
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
        END IF;
        -- =============================================
        --      A-3 �H��o�׌v�搧��}�X�^���擾
        -- =============================================
        get_plant_shipping(
           io_xwsp_rec          =>   lr_xwsp_rec      --   �H��o�׃��[�N���R�[�h�^�C�v
          ,ov_errbuf            =>   lv_errbuf        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ,ov_retcode           =>   lv_retcode        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_errmsg            =>   lv_errmsg       -- ���^�[���E�R�[�h             --# �Œ� #
          );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
          RAISE expt_next_record;
        END IF;
        -- ===============================================
        --      A-4 ��{��������}�X�^�[���擾����
        -- ===============================================
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
        IF (lv_retcode = cv_status_error) THEN
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
        IF (lv_retcode = cv_status_error) THEN
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
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;
      EXCEPTION
        WHEN expt_next_record THEN
          NULL;
      END;
    END LOOP Base_loop;
    --
    IF (ln_loop_cnt = 0) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00003      --�Ώۃf�[�^�Ȃ�
                   );
      RAISE internal_process_expt;
    END IF;
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
    -- �x�����b�Z�[�W���o�͂����ꍇ�A�x���I���Ŗ߂�
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN internal_process_expt THEN
      --�J�[�\���N���[�Y
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
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
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --�J�[�\���N���[�Y
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
        CLOSE get_schedule_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�J�[�\���N���[�Y
      IF (get_schedule_cur%ISOPEN = TRUE) THEN
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
    ,iv_plan_from                  IN  VARCHAR2         --   1.�v�旧�Ċ��ԁiFROM�j
    ,iv_plan_to                    IN  VARCHAR2         --   2.�v�旧�Ċ��ԁiTO�j
    ,iv_pace_type                  IN  VARCHAR2         --   3.�Ώۏo�׋敪
    ,iv_pace_from                  IN  VARCHAR2         --   4.�o�׃y�[�X�v����ԁiFROM�j
    ,iv_pace_to                    IN  VARCHAR2         --   5.�o�׃y�[�X�v����ԁiTO�j
    ,iv_forcast_from               IN  VARCHAR2         --   6.�o�ח\�����ԁiFROM)
    ,iv_forcast_to                 IN  VARCHAR2         --   7.�o�ח\�����ԁiTO�j
    ,iv_schedule_date              IN  VARCHAR2         --   8.�o�׈����ϓ�
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
       iv_plan_from     =>       iv_plan_from     --   1.�v�旧�Ċ��ԁiFROM�j
      ,iv_plan_to       =>       iv_plan_to       --   2.�v�旧�Ċ��ԁiTO�j
      ,iv_pace_type     =>       iv_pace_type     --   3.�Ώۏo�׋敪
      ,iv_pace_from     =>       iv_pace_from     --   4.�o�׃y�[�X�v����ԁiFROM�j
      ,iv_pace_to       =>       iv_pace_to       --   5.�o�׃y�[�X�v����ԁiTO�j
      ,iv_forcast_from  =>       iv_forcast_from  --   6.�o�ח\�����ԁiFROM)
      ,iv_forcast_to    =>       iv_forcast_to    --   7.�o�ח\�����ԁiTO�j
      ,iv_schedule_date =>       iv_schedule_date --   8.�o�׈����ϓ�
      ,ov_errbuf        =>       lv_errbuf        --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       =>       lv_retcode       --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        =>       lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

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
    --�I���X�e�[�^�X���G���[�̏ꍇ��COMMIT����
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
/
