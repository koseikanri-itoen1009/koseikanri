CREATE OR REPLACE PACKAGE BODY XXCOP006A011C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A011C(body)
 * Description      : �����v��
 * MD.050           : �����v�� MD050_COP_006_A01
 * Version          : 3.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  put_log_level          ���O���x���o��                                       (B-26)
 *  entry_xwypo            �����v��o�̓��[�N�e�[�u���o�^                       (B-25)
 *  entry_xli_lot          �����v��莝�݌Ƀe�[�u���o�^(���b�g�v�搔)           (B-24)
 *  update_xwyl_schedule   �����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���X�V             (B-23)
 *  entry_xli_balance      �����v��莝�݌Ƀe�[�u���o�^(�o�����X�v�搔)         (B-22)
 *  entry_supply_failed    �����v��o�̓��[�N�e�[�u���o�^(�v��s��)             (B-21)
 *  proc_lot_quantity      �v�惍�b�g�̌���                                     (B-20)
 *  proc_balance_quantity  �o�����X�v�搔�̌v�Z                                 (B-19)
 *  proc_ship_loct         �ړ����q�ɂ̓���                                     (B-18)
 *  proc_safety_quantity   ���S�݌ɂ̌v�Z                                       (B-17)
 *  entry_xli_shipment     �����v��莝�݌Ƀe�[�u���o�^(�o�׃y�[�X)             (B-16)
 *  entry_xli_po           �����v��莝�݌Ƀe�[�u���o�^(�w���v��)               (B-15)
 *  entry_xli_fs           �����v��莝�݌Ƀe�[�u���o�^(�H��o�׌v��)           (B-14)
 *  entry_xwyp             �����v�敨�����[�N�e�[�u���o�^                       (B-13)
 *  chk_freshness_cond     �N�x�����`�F�b�N                                     (B-12)
 *  chk_effective_route    ���ʉ����v��L�����ԃ`�F�b�N                         (B-11)
 *  init                   ��������                                             (B-1)
 *  get_msr_route          �����v�搧��}�X�^�擾                               (B-2)
 *  entry_xwyl             �i�ڕʑ�\�q�Ɏ擾                                   (B-3)
 *  proc_shipping_pace     �o�׃y�[�X�̌v�Z                                     (B-4)
 *  proc_total_pace        ���o�׃y�[�X�̌v�Z                                   (B-5)
 *  create_xli             �莝�݌Ƀe�[�u���쐬                                 (B-6)
 *  get_msd_schedule       ��v��g�����U�N�V�����쐬                         (B-7)
 *  get_shipment_schedule  �o�׃g�����U�N�V�����쐬                             (B-8)
 *  create_yoko_plan       �����v��쐬                                         (B-9)
 *  output_xwypo           �����v��CSV���`                                      (B-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   Y.Goto           �V�K�쐬
 *  2009/04/07    1.1   Y.Goto           T1_0273,T1_0274,T1_0289,T1_0366,T1_0367�Ή�
 *  2009/04/14    1.2   Y.Goto           T1_0539,T1_0541�Ή�
 *  2009/04/28    1.3   Y.Goto           T1_0846,T1_0920�Ή�
 *  2009/06/12    1.4   Y.Goto           T1_1394�Ή�
 *  2009/07/13    2.0   Y.Goto           0000669�Ή�(���ʉۑ�IE479)
 *  2009/10/20    2.1   Y.Goto           I_E_479_001
 *  2009/10/20    2.2   Y.Goto           I_E_479_002
 *  2009/10/22    2.3   Y.Goto           I_E_479_003
 *  2009/10/26    2.4   Y.Goto           I_E_479_004
 *  2009/10/27    2.5   Y.Goto           I_E_479_005
 *  2009/10/28    2.6   Y.Goto           I_E_479_006
 *  2009/11/09    2.7   Y.Goto           I_E_479_011,I_E_479_012
 *  2009/11/11    2.8   Y.Goto           I_E_479_013
 *  2009/11/17    2.9   Y.Goto           I_E_479_015
 *  2009/11/19    2.10  Y.Goto           I_E_479_017
 *  2009/11/30    3.0   Y.Goto           I_E_479_019(�����v��p���������Ή��A�A�v��PT�Ή��A�v���O����ID�̕ύX)
 *  2009/12/17    3.1   Y.Goto           E_�{�ғ�_00519
 *  2010/01/07    3.2   Y.Goto           E_�{�ғ�_00936
 *  2010/01/25    3.3   Y.Goto           E_�{�ғ�_01250
 *  2010/02/03    3.4   Y.Goto           E_�{�ғ�_01222
 *  2010/02/10    3.5   Y.Goto           E_�{�ғ�_01560
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
  internal_api_expt         EXCEPTION;     -- �R���J�����g�������ʗ�O
  param_invalid_expt        EXCEPTION;     -- ���̓p�����[�^�`�F�b�N�G���[
  date_invalid_expt         EXCEPTION;     -- ���t�`�F�b�N�G���[
  date_reverse_expt         EXCEPTION;     -- FROM-TO�t�]�`�F�b�N�G���[
  past_date_invalid_expt    EXCEPTION;     -- �ߋ����`�F�b�N�G���[
  prior_date_invalid_expt   EXCEPTION;     -- �������`�F�b�N�G���[
  profile_invalid_expt      EXCEPTION;     -- �v���t�@�C���l�G���[
  stock_days_expt           EXCEPTION;     -- �݌ɓ����`�F�b�N�G���[
  no_condition_expt         EXCEPTION;     -- �N�x�������o�^�G���[
  obsolete_skip_expt        EXCEPTION;     -- �p�~�X�L�b�v��O
  short_supply_expt         EXCEPTION;     -- �݌ɕs����O
  nested_loop_expt          EXCEPTION;     -- �K�w���[�v�G���[
  not_need_expt             EXCEPTION;     -- �v��s�v��O
  outside_scope_expt        EXCEPTION;     -- �ΏۊO��O
  lot_skip_expt             EXCEPTION;     -- ���b�g�X�L�b�v��O
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
  manufacture_skip_expt     EXCEPTION;     -- �����N�����X�L�b�v��O
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
--
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A011C';          -- �p�b�P�[�W��
  --���b�Z�[�W����
  cv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- �A�v���P�[�V�����Z�k��
  --����
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');          -- ����
  --�v���O�������s�N����
  cd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- �V�X�e�����t�i�N�����j
  --���t�^�t�H�[�}�b�g
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- �N����
  cv_trunc_month            CONSTANT VARCHAR2(100) := 'MM';                     -- �N��
  --�^�C���X�^���v�^�t�H�[�}�b�g
  cv_timestamp_format       CONSTANT VARCHAR2(100) := 'HH24:MI:SS.FF3';         -- �N���������b
  --���l�^�t�H�[�}�b�g
  cv_num42_format           CONSTANT VARCHAR2(100) := '9999.99';                -- ���l4,2
  --���t
  cd_lower_limit_date       CONSTANT DATE := TO_DATE('1900/01/01', cv_date_format);-- �ŏ��N����
  cd_upper_limit_date       CONSTANT DATE := TO_DATE('9999/12/31', cv_date_format);-- �ő�N����
  --�f�o�b�N���b�Z�[�W�C���f���g
  cv_indent_2               CONSTANT CHAR(2) := '  ';                           -- 2������
  cv_indent_4               CONSTANT CHAR(4) := '    ';                         -- 4������
  --���b�Z�[�W��
  cv_msg_00065              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_msg_10009              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';
  cv_msg_00028              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00028';
  cv_msg_00061              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';
  cv_msg_00049              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00049';
  cv_msg_00050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';
  cv_msg_00053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';
  cv_msg_10039              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10039';
  cv_msg_00068              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00068';
  cv_msg_10040              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10040';
  cv_msg_10041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10041';
  cv_msg_10038              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10038';
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';
  cv_msg_00060              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_msg_00056              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';
  cv_msg_00057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';
  cv_msg_00066              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00066';
  cv_msg_00067              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00067';
  cv_msg_10045              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10045';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_msg_10057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10057';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
  cv_msg_10047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10047';
  cv_msg_10050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10050';
  cv_msg_10051              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10051';
  --���b�Z�[�W�g�[�N��
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00028_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_10039_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10039_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00068_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00068_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10040_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10040_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10040_token_3      CONSTANT VARCHAR2(100) := 'FRESHNESS_COND';
  cv_msg_10041_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10041_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10041_token_3      CONSTANT VARCHAR2(100) := 'FRESHNESS_COND';
  cv_msg_10041_token_4      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10038_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10038_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00060_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00049_token_1      CONSTANT VARCHAR2(100) := 'ITEMID';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00066_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00066_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00066_token_3      CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  cv_msg_00067_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_00067_token_2      CONSTANT VARCHAR2(100) := 'CALENDAR_CODE';
  cv_msg_00067_token_3      CONSTANT VARCHAR2(100) := 'RECEIPT_DATE';
  cv_msg_10045_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10045_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10045_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10045_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10045_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10045_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10045_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10045_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
  cv_msg_10045_token_9      CONSTANT VARCHAR2(100) := 'ITEM_NO';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_msg_10057_token_1      CONSTANT VARCHAR2(100) := 'WORKING_DAYS';
  cv_msg_10057_token_2      CONSTANT VARCHAR2(100) := 'STOCK_ADJUST_VALUE';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
  cv_msg_10051_token_1      CONSTANT VARCHAR2(100) := 'DEBUG_LEVEL';
  cv_msg_10051_token_2      CONSTANT VARCHAR2(100) := 'RECEIPT_DATE';
  cv_msg_10051_token_3      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10051_token_4      CONSTANT VARCHAR2(100) := 'LOCT_CODE';
  cv_msg_10051_token_5      CONSTANT VARCHAR2(100) := 'FRESHNESS_CONDITION';
  cv_msg_10051_token_6      CONSTANT VARCHAR2(100) := 'STOCK_QUANTITY';
  cv_msg_10051_token_7      CONSTANT VARCHAR2(100) := 'SHIPPING_PACE';
  cv_msg_10051_token_8      CONSTANT VARCHAR2(100) := 'STOCK_DAYS';
  cv_msg_10051_token_9      CONSTANT VARCHAR2(100) := 'SUPPLIES_QUANTITY';
  cv_msg_10051_token_10     CONSTANT VARCHAR2(100) := 'MANUFACTURE_DATE';
--
  --���b�Z�[�W�g�[�N���l
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '�����v��o�̓��[�N�e�[�u��';
  cv_table_xwyp             CONSTANT VARCHAR2(100) := '�����v�敨�����[�N�e�[�u��';
  cv_table_xli              CONSTANT VARCHAR2(100) := '�����v��莝�݌Ƀe�[�u��';
  cv_table_xwyl             CONSTANT VARCHAR2(100) := '�����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u��';
  cv_msg_10041_value_1      CONSTANT VARCHAR2(100) := '���S�݌ɓ���';
  cv_msg_10041_value_2      CONSTANT VARCHAR2(100) := '�ő�݌ɓ���';
  --���̓p�����[�^
  cv_plan_type_tl           CONSTANT VARCHAR2(100) := '�o�׌v��敪';
  cv_planning_date_from_tl  CONSTANT VARCHAR2(100) := '�v�旧�Ċ���(FROM)';
  cv_planning_date_to_tl    CONSTANT VARCHAR2(100) := '�v�旧�Ċ���(TO)';
  cv_shipment_date_from_tl  CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����(FROM)';
  cv_shipment_date_to_tl    CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����(TO)';
  cv_forecast_date_from_tl  CONSTANT VARCHAR2(100) := '�o�ח\������(FROM)';
  cv_forecast_date_to_tl    CONSTANT VARCHAR2(100) := '�o�ח\������(TO)';
  cv_allocated_date_tl      CONSTANT VARCHAR2(100) := '�o�׈����ϓ�';
  cv_item_code_tl           CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_working_days_tl        CONSTANT VARCHAR2(100) := '�ғ�����';
  cv_stock_adjust_value_tl  CONSTANT VARCHAR2(100) := '�݌ɓ��������l';
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
  --�v���t�@�C��
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_pf_source_org_id       CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_pf_frq_loct_code       CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
  cv_pf_partition_num       CONSTANT VARCHAR2(100) := 'XXCOP1_PARTITION_NUM';
  cv_pf_debug_mode          CONSTANT VARCHAR2(100) := 'XXCOP1_DEBUG_MODE';
  --�N�C�b�N�R�[�h�^�C�v
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --�o�׌v��敪
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- �o�׃y�[�X
  cv_plan_type_forecate     CONSTANT VARCHAR2(100) := '2';                      -- �o�ח\��
  --�����Z�b�g�敪
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- ��{�����v��
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- ���ʉ����v��
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- �H��o�׌v��
  --������敪
  cv_assign_type_global     CONSTANT NUMBER        := 1;                        -- �O���[�o��
  cv_assign_type_org        CONSTANT NUMBER        := 4;                        -- �g�D
  cv_assign_type_item       CONSTANT NUMBER        := 3;                        -- �i��
  cv_assign_type_item_org   CONSTANT NUMBER        := 6;                        -- �i��-�g�D
  --�o�׌��敪
  cn_location_source        CONSTANT NUMBER        := 1;                        -- �ړ���
  cn_location_manufacture   CONSTANT NUMBER        := 2;                        -- �����ꏊ
  cn_location_vendor        CONSTANT NUMBER        := 3;                        -- �w����
  --�N�x�����̕���
  cv_condition_general      CONSTANT VARCHAR2(1)   := '0';                      -- ���
  cv_condition_expiration   CONSTANT VARCHAR2(1)   := '1';                      -- �ܖ������
  cv_condition_manufacture  CONSTANT VARCHAR2(1)   := '2';                      -- �������
  --�v��^�C�v
  cv_plan_balance           CONSTANT VARCHAR2(1)   := '0';                      -- �o�����X
  cv_plan_minimum           CONSTANT VARCHAR2(1)   := '1';                      -- �ŏ�
  cv_plan_maximum           CONSTANT VARCHAR2(1)   := '2';                      -- �ő�
  --��v�敪��
  cv_msd_forecast           CONSTANT VARCHAR2(10)  := '1';                      -- �o�ח\��
  cv_msd_fs_sched           CONSTANT VARCHAR2(10)  := '2';                      -- �H��o�׌v��
  cv_msd_po_sched           CONSTANT VARCHAR2(10)  := '3';                      -- �w���v��
  --�����E�w���i�t���O
  cv_manufacture            CONSTANT VARCHAR2(10)  := '1';                      -- �����i
  cv_purchase               CONSTANT VARCHAR2(10)  := '2';                      -- �w���i
  --�X�P�W���[��LEVEL
  cn_schedule_level         CONSTANT NUMBER        := 2;                        -- 
  --�v�旧�ăt���O
  cv_planning_yes           CONSTANT VARCHAR2(10)  := 'Y';                      -- YES
  cv_planning_no            CONSTANT VARCHAR2(10)  := 'N';                      -- NO
  cv_planning_omit          CONSTANT VARCHAR2(10)  := 'O';                      -- ���O
  --�q�Ɏ���
  cv_inc_loct               CONSTANT VARCHAR2(10)  := '1';                      -- ��\�q�Ɂ{�H��q��
  cv_off_loct               CONSTANT VARCHAR2(10)  := '2';                      -- �H��q�ɂ̑�\�q��
  --�[���X�V�t���O
  cv_simulate_yes           CONSTANT VARCHAR2(10)  := 'Y';                      -- YES
  --���S�݌ɔ���X�e�[�^�X
  cv_enough                 CONSTANT VARCHAR2(10)  := '0';                      -- ���S�݌Ɉȏ�
  cv_shortage               CONSTANT VARCHAR2(10)  := '1';                      -- ���S�݌ɖ���
  --�v�旧�ăX�e�[�^�X
  cv_complete               CONSTANT VARCHAR2(10)  := '0';                      -- �v�抮��
  cv_incomplete             CONSTANT VARCHAR2(10)  := '1';                      -- �v��p��
  cv_failed                 CONSTANT VARCHAR2(10)  := '2';                      -- �v��s��
  --�i�ڃ}�X�^�X�e�[�^�X
  cn_iimb_status_active     CONSTANT NUMBER := 0;                               -- �X�e�[�^�X
  cn_ximb_status_active     CONSTANT NUMBER := 0;                               -- �X�e�[�^�X
  cv_shipping_enable        CONSTANT NUMBER := '1';                             -- �X�e�[�^�X
  --�����v��莝�݌Ƀe�[�u��
  cv_xli_type_inv           CONSTANT VARCHAR2(10)  := '00';                     -- �莝�݌�
  cv_xli_type_po            CONSTANT VARCHAR2(10)  := '10';                     -- ��v��(�w���v��)
  cv_xli_type_fs            CONSTANT VARCHAR2(10)  := '20';                     -- ��v��(�H��o�׌v��)
  cv_xli_type_sp            CONSTANT VARCHAR2(10)  := '30';                     -- �o�׃y�[�X
  cv_xli_type_bq            CONSTANT VARCHAR2(10)  := '40';                     -- �����v��(�o�����X�v�Z������)
  cv_xli_type_lq            CONSTANT VARCHAR2(10)  := '50';                     -- �����v��(���b�g�v�搔)
  --CSV�t�@�C���o�̓t�H�[�}�b�g
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- �A�X�^���X�N
  --���O�o�̓��x��
  cv_log_level1             CONSTANT VARCHAR2(1)   := '1';                      -- 
  cv_log_level2             CONSTANT VARCHAR2(1)   := '2';                      -- 
  cv_log_level3             CONSTANT VARCHAR2(1)   := '3';                      -- 
  --��[�X�e�[�^�X
  cv_supply_enough          CONSTANT VARCHAR2(1)   := '1';                      -- ��[����
  cv_supply_shortage        CONSTANT VARCHAR2(1)   := '0';                      -- ��[���s��
  --�o�͑Ώۃt���O
  cv_output_off             CONSTANT VARCHAR2(1)   := '0';                      -- �ΏۊO
  cv_output_on              CONSTANT VARCHAR2(1)   := '1';                      -- �Ώ�
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
  --�i�ڃJ�e�S��
  cv_category_crowd_class   CONSTANT VARCHAR2(8)   := '�Q�R�[�h';               -- �Q�R�[�h
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�����v�敨�����[�N�e�[�u���R���N�V�����^
  TYPE g_xwyp_ttype IS TABLE OF xxcop_wk_yoko_planning%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --�����v��o�̓��[�N�e�[�u���R���N�V�����^
  TYPE g_xwypo_ttype IS TABLE OF xxcop_wk_yoko_plan_output%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --�����v��莝�݌Ƀe�[�u���R���N�V�����^
  TYPE g_xli_ttype IS TABLE OF xxcop_loct_inv%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --�����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���R���N�V�����^
  TYPE g_xwyl_ttype IS TABLE OF xxcop_wk_yoko_locations%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --�C���f�b�N�X�R���N�V�����^
  TYPE g_idx_ttype IS TABLE OF NUMBER
    INDEX BY BINARY_INTEGER;
  --ROWID�R���N�V�����^
  TYPE g_rowid_ttype IS TABLE OF ROWID
    INDEX BY BINARY_INTEGER;
--
  --�N�x�������R�[�h�^
  TYPE g_freshness_condition_rtype IS RECORD (
     freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_condition      xxcop_wk_yoko_planning.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,safety_stock_days        xxcop_wk_yoko_planning.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
  );
  --�N�x�����R���N�V�����^
  TYPE g_fc_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
--
  --�o�׃y�[�X���R�[�h�^
  TYPE g_shipping_pace_rtype IS RECORD (
     shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,forecast_pace            xxcop_wk_yoko_planning.forecast_pace%TYPE
    ,shipping_quantity        NUMBER
    ,forecast_quantity        NUMBER
  );
  --�o�׃y�[�X�R���N�V�����^
  TYPE g_sp_ttype IS TABLE OF g_shipping_pace_rtype
    INDEX BY BINARY_INTEGER;
--
  --�o�׃y�[�X�݌Ɉ������R�[�h�^
  TYPE g_shipping_allocate_rtype IS RECORD (
     item_id                  xxcop_wk_yoko_planning.item_id%TYPE
    ,item_no                  xxcop_wk_yoko_planning.item_no%TYPE
    ,rcpt_organization_id     xxcop_wk_yoko_planning.rcpt_organization_id%TYPE
    ,rcpt_organization_code   xxcop_wk_yoko_planning.rcpt_organization_code%TYPE
    ,rcpt_loct_id             xxcop_wk_yoko_planning.rcpt_loct_id%TYPE
    ,rcpt_loct_code           xxcop_wk_yoko_planning.rcpt_loct_code%TYPE
    ,rcpt_calendar_code       xxcop_wk_yoko_planning.rcpt_calendar_code%TYPE
    ,shipping_type            xxcop_wk_yoko_planning.shipping_type%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
    ,allocate_quantity        NUMBER
  );
  --�o�׃y�[�X�݌Ɉ����R���N�V�����^
  TYPE g_sa_ttype IS TABLE OF g_shipping_allocate_rtype
    INDEX BY BINARY_INTEGER;
--
  --�q�ɏ�񃌃R�[�h�^
  TYPE g_loct_rtype IS RECORD (
     loct_id                  xxcop_wk_yoko_planning.rcpt_loct_id%TYPE
    ,loct_code                xxcop_wk_yoko_planning.rcpt_loct_code%TYPE
    ,delivery_lead_time       xxcop_wk_yoko_planning.delivery_lead_time%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,target_date              xxcop_wk_yoko_planning.receipt_date%TYPE
  );
  --�q�ɏ��R���N�V�����^
  TYPE g_loct_ttype IS TABLE OF g_loct_rtype
    INDEX BY BINARY_INTEGER;
--
  --�i�ڏ�񃌃R�[�h�^
  TYPE g_item_rtype IS RECORD (
     item_id                  xxcop_wk_yoko_planning.item_id%TYPE
    ,item_no                  xxcop_wk_yoko_planning.item_no%TYPE
  );
  --�i�ڏ��R���N�V�����^
  TYPE g_item_ttype IS TABLE OF g_item_rtype
    INDEX BY BINARY_INTEGER;
--
  --�N�x�����ʍ݌Ɉ������R�[�h�^
  TYPE g_freshness_quantity_rtype IS RECORD (
     freshness_priority       xxcop_wk_yoko_planning.freshness_priority%TYPE
    ,freshness_condition      xxcop_wk_yoko_planning.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_planning.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_planning.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_planning.freshness_adjust_value%TYPE
    ,safety_stock_days        xxcop_wk_yoko_planning.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_planning.max_stock_days%TYPE
    ,shipping_pace            xxcop_wk_yoko_planning.shipping_pace%TYPE
    ,safety_stock_quantity    NUMBER
    ,max_stock_quantity       NUMBER
    ,allocate_quantity        NUMBER
    ,sy_manufacture_date      xxcop_wk_yoko_planning.sy_manufacture_date%TYPE
    ,sy_maxmum_quantity       xxcop_wk_yoko_planning.sy_maxmum_quantity%TYPE
    ,sy_stocked_quantity      xxcop_wk_yoko_planning.sy_stocked_quantity%TYPE
  );
  --�N�x�����ʍ݌Ɉ����R���N�V�����^
  TYPE g_fq_ttype IS TABLE OF g_freshness_quantity_rtype
    INDEX BY BINARY_INTEGER;
--
  --�ړ����q�ɗD�揇�ʃ��R�[�h�^
  TYPE g_loct_priority_rtype IS RECORD (
     manufacture_date        DATE
    ,stock_days              NUMBER
    ,delivery_lead_time      NUMBER
    ,priority_idx            NUMBER
  );
  --�ړ����q�ɗD�揇�ʃR���N�V�����^
  TYPE g_lp_ttype IS TABLE OF g_loct_priority_rtype
    INDEX BY BINARY_INTEGER;
--
  --�o�����X�����v�惌�R�[�h�^
  TYPE g_balance_quantity_rtype IS RECORD (
     freshness_condition      xxcop_wk_yoko_plan_output.freshness_condition%TYPE
    ,freshness_class          xxcop_wk_yoko_plan_output.freshness_class%TYPE
    ,freshness_check_value    xxcop_wk_yoko_plan_output.freshness_check_value%TYPE
    ,freshness_adjust_value   xxcop_wk_yoko_plan_output.freshness_adjust_value%TYPE
    ,manufacture_date         xxcop_wk_yoko_plan_output.manufacture_date%TYPE
    ,plan_bal_quantity        xxcop_wk_yoko_plan_output.plan_bal_quantity%TYPE
    ,before_stock             xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock              xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_stock_days        xxcop_wk_yoko_plan_output.safety_stock_days%TYPE
    ,max_stock_days           xxcop_wk_yoko_plan_output.max_stock_days%TYPE
    ,shipping_type            xxcop_wk_yoko_plan_output.shipping_type%TYPE
    ,shipping_pace            xxcop_wk_yoko_plan_output.shipping_pace%TYPE

  );
  --�o�����X�����v��R���N�V�����^
  TYPE g_bq_ttype IS TABLE OF g_balance_quantity_rtype
    INDEX BY BINARY_INTEGER;
--
  --�v�惍�b�g���R�[�h�^
  TYPE g_lot_rtype IS RECORD (
     critical_date            xxcop_loct_inv.manufacture_date%TYPE              --�N�x�������
    ,lot_quantity             xxcop_loct_inv.loct_onhand%TYPE                   --���b�g������(���b�g)
    ,freshness_quantity       xxcop_loct_inv.loct_onhand%TYPE                   --�N�x�����ʍ݌ɐ�(���v)
    ,plan_bal_quantity        xxcop_loct_inv.loct_onhand%TYPE                   --�N�x�����ʃo�����X�v�搔(���v)
    ,adjust_quantity          xxcop_loct_inv.loct_onhand%TYPE                   --�ߕs����
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
    ,plan_lot_quantity        xxcop_loct_inv.loct_onhand%TYPE                   --���b�g�v�搔
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
    ,stock_proc_flag          VARCHAR2(1)                                       --�N�x�����ʍ݌Ɍv�Z�t���O
    ,adjust_proc_flag         VARCHAR2(1)                                       --�o�����X�v�Z�t���O
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--    ,proc_flag                VARCHAR2(1)                                       --�v��Ώۃt���O(Y/N)
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
  );
  --�v�惍�b�g�R���N�V�����^
  TYPE g_lot_ttype IS TABLE OF g_lot_rtype
    INDEX BY BINARY_INTEGER;
--
  --���b�g�݌Ƀ��R�[�h�^
  TYPE g_loct_inv_rtype IS RECORD (
     lot_id                   xxcop_loct_inv.lot_id%TYPE                        --���b�gID
    ,lot_no                   xxcop_loct_inv.lot_no%TYPE                        --���b�gNO
    ,manufacture_date         xxcop_loct_inv.manufacture_date%TYPE              --�����N����
    ,expiration_date          xxcop_loct_inv.expiration_date%TYPE               --�ܖ�����
    ,unique_sign              xxcop_loct_inv.unique_sign%TYPE                   --�ŗL�L��
    ,lot_status               xxcop_loct_inv.lot_status%TYPE                    --���b�g�X�e�[�^�X
    ,loct_onhand              xxcop_loct_inv.loct_onhand%TYPE                   --�݌ɐ�
    ,loct_id                  xxcop_loct_inv.loct_id%TYPE                       --�ۊǏꏊID
    ,record_class             NUMBER                                            --���R�[�h�敪
  );
  --���b�g�݌ɃR���N�V�����^
  TYPE g_li_ttype IS TABLE OF g_loct_inv_rtype
    INDEX BY BINARY_INTEGER;
--
  --ROWID�R���N�V�����^
  TYPE g_rowid_tab_ttype IS TABLE OF g_rowid_ttype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_planning_date          DATE;                                               --�v�旧�ē�
  gd_process_date           DATE;                                               --�Ɩ����t
  gn_transaction_id         NUMBER;                                             --�g�����U�N�V����ID
  gv_log_buffer             VARCHAR2(5000);                                     --���O�o�͗̈�
  --�N���p�����[�^
  gv_plan_type              VARCHAR2(1);                                        --�o�׌v��敪
  gd_planning_date_from     DATE;                                               --�v�旧�Ċ���(FROM)
  gd_planning_date_to       DATE;                                               --�v�旧�Ċ���(TO)
  gd_shipment_date_from     DATE;                                               --�o�׃y�[�X�v�����FROM
  gd_shipment_date_to       DATE;                                               --�o�׃y�[�X�v�����TO
  gd_forecast_date_from     DATE;                                               --�o�ח\������FROM
  gd_forecast_date_to       DATE;                                               --�o�ח\������TO
  gd_allocated_date         DATE;                                               --�o�׈����ϓ�
  gv_item_code              VARCHAR2(7);                                        --�i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
  gn_working_days           NUMBER;                                             --�ғ�����
  gn_stock_adjust_value     NUMBER;                                             --�݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
  --�v���t�@�C���l
  gv_debug_mode             VARCHAR2(256);                                      --�f�o�b�N���[�h
  gn_master_org_id          NUMBER;                                             --�������[��(�_�~�[)�g�DID
  gn_source_org_id          NUMBER;                                             --�p�b�J�[�q��(�_�~�[)�g�DID
  gn_freshness_buffer_days  NUMBER;                                             --�N�x�����o�b�t�@����
  gv_dummy_frequent_whse    VARCHAR2(4);                                        --�_�~�[��\�q��
  gn_partition_num          NUMBER;                                             --�p�[�e�B�V������
--
  --�i�ڕʑ�\�q�Ƀe�[�u��ROWID
  g_xwyl_tab                g_rowid_tab_ttype;
--
/************************************************************************
 * Procedure Name  : put_log_level
 * Description     : ���O���x���o��(B-26)
 ************************************************************************/
  PROCEDURE put_log_level(
    iv_log_level            IN     VARCHAR2,       -- ���b�Z�[�W���x��
    id_receipt_date         IN     DATE,           -- ����
    iv_item_no              IN     VARCHAR2,       -- �i��
    iv_loct_code            IN     VARCHAR2,       -- �q��
    iv_freshness_condition  IN     VARCHAR2,       -- �N�x����
    in_stock_quantity       IN     NUMBER,         -- �����\��
    in_shipping_pace        IN     NUMBER,         -- �o�׃y�[�X
    in_supplies_quantity    IN     NUMBER,         -- ��[�\��
    id_manufacture_date     IN     DATE,           -- �����N����
    ov_errbuf               OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_level'; -- �v���O������
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
    ln_stock_days             NUMBER;
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
    --������
    ln_stock_days := NULL;
--
    IF (gv_debug_mode <= iv_log_level) THEN
      --���O���b�Z�[�W�w�b�_�[�̏o��
      IF (gv_log_buffer IS NULL) THEN
        gv_log_buffer := xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_appl_cont
                           ,iv_name          => cv_msg_10050
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_log_buffer
        );
      END IF;
--
      --���O���b�Z�[�W�[�̏o��
      IF (in_shipping_pace <> 0) THEN
        ln_stock_days := in_stock_quantity / in_shipping_pace;
      END IF;
      gv_log_buffer := xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_appl_cont
                         ,iv_name          => cv_msg_10051
                         ,iv_token_name1   => cv_msg_10051_token_1
                         ,iv_token_value1  => iv_log_level
                         ,iv_token_name2   => cv_msg_10051_token_2
                         ,iv_token_value2  => TO_CHAR(id_receipt_date, cv_date_format)
                         ,iv_token_name3   => cv_msg_10051_token_3
                         ,iv_token_value3  => iv_item_no
                         ,iv_token_name4   => cv_msg_10051_token_4
                         ,iv_token_value4  => iv_loct_code
                         ,iv_token_name5   => cv_msg_10051_token_5
                         ,iv_token_value5  => iv_freshness_condition
                         ,iv_token_name6   => cv_msg_10051_token_6
                         ,iv_token_value6  => in_stock_quantity
                         ,iv_token_name7   => cv_msg_10051_token_7
                         ,iv_token_value7  => in_shipping_pace
                         ,iv_token_name8   => cv_msg_10051_token_8
                         ,iv_token_value8  => ROUND(ln_stock_days, 2)
                         ,iv_token_name9   => cv_msg_10051_token_9
                         ,iv_token_value9  => in_supplies_quantity
                         ,iv_token_name10  => cv_msg_10051_token_10
                         ,iv_token_value10 => TO_CHAR(id_manufacture_date, cv_date_format)
                       );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_log_buffer
      );
    END IF;
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
  END put_log_level;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwypo
   * Description      : �����v��o�̓��[�N�e�[�u���o�^(B-25)
   ***********************************************************************************/
  PROCEDURE entry_xwypo(
    iv_supply_status IN     VARCHAR2,       --   �X�e�[�^�X
    i_xwypo_rec      IN     xxcop_wk_yoko_plan_output%ROWTYPE,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwypo'; -- �v���O������
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
    l_xwypo_rec               xxcop_wk_yoko_plan_output%ROWTYPE;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    l_xwypo_rec := NULL;
--
    BEGIN
      IF (iv_supply_status = cv_complete) THEN
        --�ړ���q�ɂ̃��b�g�ʃo�����X�v�搔��1�ȏ゠��ꍇ
        IF (i_xwypo_rec.plan_lot_quantity > 0) THEN
          --�����v��莝�݌Ƀe�[�u���ɓo�^
          INSERT INTO xxcop_wk_yoko_plan_output VALUES i_xwypo_rec;
        END IF;
      ELSE
        --�����v��莝�݌Ƀe�[�u���ɓo�^
        INSERT INTO xxcop_wk_yoko_plan_output VALUES i_xwypo_rec;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwypo
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_lot
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(���b�g�v�搔)(B-24)
   ***********************************************************************************/
  PROCEDURE entry_xli_lot(
    i_xliv_rec       IN     g_loct_inv_rtype,
    i_xwypo_rec      IN     xxcop_wk_yoko_plan_output%ROWTYPE,
    it_rcpt_loct_id  IN     xxcop_wk_yoko_plan_output.rcpt_loct_id%TYPE,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_lot'; -- �v���O������
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
    ln_xli_idx                NUMBER;
    lv_simulate_flag          VARCHAR2(1);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_xli_tab                 g_xli_ttype;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    ln_xli_idx        := NULL;
    lv_simulate_flag  := NULL;
    l_xli_tab.DELETE;
--
    BEGIN
      --�ړ���q�ɂ̃��b�g�ʃo�����X�v�搔��1�ȏ゠��ꍇ�A���b�g�݌ɂ��擾
      IF (i_xwypo_rec.plan_lot_quantity > 0) THEN
        --�[���X�V�t���O�̐ݒ�
        IF (i_xwypo_rec.rcpt_loct_id = it_rcpt_loct_id) THEN
          lv_simulate_flag := NULL;
        ELSE
          lv_simulate_flag := cv_simulate_yes;
        END IF;
        --�ړ���q�ɂ̓��Ƀg�����U�N�V�����������v��莝�݌Ƀe�[�u���R���N�V�����^�Ɋi�[
        ln_xli_idx := 1;
        l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
        l_xli_tab(ln_xli_idx).loct_id                 := i_xwypo_rec.rcpt_loct_id;
        l_xli_tab(ln_xli_idx).loct_code               := i_xwypo_rec.rcpt_loct_code;
        l_xli_tab(ln_xli_idx).item_id                 := i_xwypo_rec.item_id;
        l_xli_tab(ln_xli_idx).item_no                 := i_xwypo_rec.item_no;
        l_xli_tab(ln_xli_idx).lot_id                  := i_xliv_rec.lot_id;
        l_xli_tab(ln_xli_idx).lot_no                  := i_xliv_rec.lot_no;
        l_xli_tab(ln_xli_idx).manufacture_date        := i_xliv_rec.manufacture_date;
        l_xli_tab(ln_xli_idx).expiration_date         := i_xliv_rec.expiration_date;
        l_xli_tab(ln_xli_idx).unique_sign             := i_xliv_rec.unique_sign;
        l_xli_tab(ln_xli_idx).lot_status              := i_xliv_rec.lot_status;
        l_xli_tab(ln_xli_idx).loct_onhand             := i_xwypo_rec.plan_lot_quantity;
        l_xli_tab(ln_xli_idx).schedule_date           := i_xwypo_rec.receipt_date;
        l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
        l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_lq;
        l_xli_tab(ln_xli_idx).simulate_flag           := lv_simulate_flag;
        l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
        l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
        l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
        l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
        l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
        l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
        l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
        l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
        l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
        --�ړ����q�ɂ̏o�Ƀg�����U�N�V�����������v��莝�݌Ƀe�[�u���R���N�V�����^�Ɋi�[
        ln_xli_idx := 2;
        l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
        l_xli_tab(ln_xli_idx).loct_id                 := i_xwypo_rec.ship_loct_id;
        l_xli_tab(ln_xli_idx).loct_code               := i_xwypo_rec.ship_loct_code;
        l_xli_tab(ln_xli_idx).item_id                 := i_xwypo_rec.item_id;
        l_xli_tab(ln_xli_idx).item_no                 := i_xwypo_rec.item_no;
        l_xli_tab(ln_xli_idx).lot_id                  := i_xliv_rec.lot_id;
        l_xli_tab(ln_xli_idx).lot_no                  := i_xliv_rec.lot_no;
        l_xli_tab(ln_xli_idx).manufacture_date        := i_xliv_rec.manufacture_date;
        l_xli_tab(ln_xli_idx).expiration_date         := i_xliv_rec.expiration_date;
        l_xli_tab(ln_xli_idx).unique_sign             := i_xliv_rec.unique_sign;
        l_xli_tab(ln_xli_idx).lot_status              := i_xliv_rec.lot_status;
        l_xli_tab(ln_xli_idx).loct_onhand             := i_xwypo_rec.plan_lot_quantity * -1;
        l_xli_tab(ln_xli_idx).schedule_date           := i_xwypo_rec.shipping_date;
        l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
        l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_lq;
        l_xli_tab(ln_xli_idx).simulate_flag           := lv_simulate_flag;
        l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
        l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
        l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
        l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
        l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
        l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
        l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
        l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
        l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
        --�����O�݌ɐ��������v��莝�݌Ƀe�[�u���ɓo�^
        FORALL ln_xli_idx in 1..l_xli_tab.COUNT
          INSERT INTO xxcop_loct_inv VALUES l_xli_tab(ln_xli_idx);
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xli_lot;
--
  /**********************************************************************************
   * Procedure Name   : update_xwyl_schedule
   * Description      : �����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���X�V(B-23)
   ***********************************************************************************/
  PROCEDURE update_xwyl_schedule(
    it_item_id       IN     xxcop_wk_yoko_planning.item_id%TYPE,
    i_ship_rec       IN     g_loct_rtype,   --   �ړ����q�Ƀ��R�[�h�^
    i_xwypo_tab      IN     g_xwypo_ttype,  --   �����v��o�̓��[�N�e�[�u���R���N�V�����^
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xwyl_schedule'; -- �v���O������
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
    ln_clear_count            NUMBER;
    ln_check_count            NUMBER;
    ln_xwyl_idx               NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_xwyl_rowid_tab          g_rowid_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_clear_count := 0;
    ln_check_count := 0;
    ln_xwyl_idx    := 1;
    l_xwyl_rowid_tab.DELETE;
--
    BEGIN
      --�v�旧�ăt���O��������
      <<xwyl_row_loop>>
      FOR ln_xwyl_row_idx IN 1 .. g_xwyl_tab.COUNT LOOP
        FOR ln_xwyl_col_idx IN 1 .. g_xwyl_tab(ln_xwyl_row_idx).COUNT LOOP
          UPDATE xxcop_wk_yoko_locations xwyl
          SET   xwyl.planning_flag        = NULL
          WHERE xwyl.rowid                = g_xwyl_tab(ln_xwyl_row_idx)(ln_xwyl_col_idx)
          ;
          ln_clear_count := ln_clear_count + SQL%ROWCOUNT;
--
        END LOOP xwyl_col_loop;
      END LOOP xwyl_row_loop;
      g_xwyl_tab.DELETE;
--
      --�ړ����q�Ɂ���\�q�ɂ̌v�旧�ăt���O�A�v������X�V
      UPDATE xxcop_wk_yoko_locations xwyl
      SET   xwyl.planning_flag        = cv_inc_loct
           ,xwyl.schedule_date        = i_ship_rec.target_date
      WHERE xwyl.transaction_id       = gn_transaction_id
        AND xwyl.request_id           = cn_request_id
        AND xwyl.frq_loct_id          = i_ship_rec.loct_id
        AND xwyl.item_id              = it_item_id
      RETURNING xwyl.ROWID
      BULK COLLECT INTO l_xwyl_rowid_tab
      ;
      ln_check_count := ln_check_count + SQL%ROWCOUNT;
      IF (l_xwyl_rowid_tab.COUNT > 0) THEN
        g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
        ln_xwyl_idx := ln_xwyl_idx + 1;
      END IF;
--
      --�ړ����q�Ɂ��H��q�ɂ̌v�旧�ăt���O�A�v������X�V
      UPDATE xxcop_wk_yoko_locations xwyl
      SET   xwyl.planning_flag        = cv_off_loct
           ,xwyl.schedule_date        = i_ship_rec.target_date
      WHERE xwyl.transaction_id       = gn_transaction_id
        AND xwyl.request_id           = cn_request_id
        AND xwyl.frq_loct_id         <> xwyl.loct_id
        AND xwyl.loct_id              = i_ship_rec.loct_id
        AND xwyl.item_id              = it_item_id
      RETURNING xwyl.ROWID
      BULK COLLECT INTO l_xwyl_rowid_tab
      ;
      ln_check_count := ln_check_count + SQL%ROWCOUNT;
      IF (l_xwyl_rowid_tab.COUNT > 0) THEN
        g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
        ln_xwyl_idx := ln_xwyl_idx + 1;
      END IF;
--
      <<rcpt_loop>>
      FOR ln_rcpt_idx IN i_xwypo_tab.FIRST .. i_xwypo_tab.LAST LOOP
        --�ړ���q�Ɂ���\�q�ɂ̌v�旧�ăt���O�A�v������X�V
        UPDATE xxcop_wk_yoko_locations xwyl
        SET   xwyl.planning_flag        = cv_inc_loct
             ,xwyl.schedule_date        = i_xwypo_tab(ln_rcpt_idx).receipt_date
        WHERE xwyl.transaction_id       = gn_transaction_id
          AND xwyl.request_id           = cn_request_id
          AND xwyl.frq_loct_id          = i_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          AND xwyl.item_id              = it_item_id
        RETURNING xwyl.ROWID
        BULK COLLECT INTO l_xwyl_rowid_tab
        ;
        ln_check_count := ln_check_count + SQL%ROWCOUNT;
        IF (l_xwyl_rowid_tab.COUNT > 0) THEN
          g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
          ln_xwyl_idx := ln_xwyl_idx + 1;
        END IF;
        --�ړ���q�Ɂ��H��q�ɂ̌v�旧�ăt���O�A�v������X�V
        UPDATE xxcop_wk_yoko_locations xwyl
        SET   xwyl.planning_flag        = cv_off_loct
             ,xwyl.schedule_date        = i_xwypo_tab(ln_rcpt_idx).receipt_date
        WHERE xwyl.transaction_id       = gn_transaction_id
          AND xwyl.request_id           = cn_request_id
          AND xwyl.frq_loct_id         <> xwyl.loct_id
          AND xwyl.loct_id              = i_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          AND xwyl.item_id              = it_item_id
        RETURNING xwyl.ROWID
        BULK COLLECT INTO l_xwyl_rowid_tab
        ;
        ln_check_count := ln_check_count + SQL%ROWCOUNT;
        IF (l_xwyl_rowid_tab.COUNT > 0) THEN
          g_xwyl_tab(ln_xwyl_idx) := l_xwyl_rowid_tab;
          ln_xwyl_idx := ln_xwyl_idx + 1;
        END IF;
      END LOOP rcpt_loop;
--
      --�f�o�b�N���b�Z�[�W�o��(�Ώۑq�Ɍ���)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                        || 'xwyl_update(COUNT):'
                        || ln_clear_count  || ','
                        || ln_check_count  || ','
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyl
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END update_xwyl_schedule;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_balance
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(�o�����X�v�搔)(B-22)
   ***********************************************************************************/
  PROCEDURE entry_xli_balance(
    it_loct_id                 IN     xxcop_loct_inv.loct_id%TYPE,
    it_loct_code               IN     xxcop_loct_inv.loct_code%TYPE,
    it_item_id                 IN     xxcop_loct_inv.item_id%TYPE,
    it_item_no                 IN     xxcop_loct_inv.item_no%TYPE,
    it_schedule_date           IN     xxcop_loct_inv.schedule_date%TYPE,
    it_schedule_quantity       IN     xxcop_loct_inv.loct_onhand%TYPE,
    it_freshness_class         IN     xxcop_wk_yoko_plan_output.freshness_class%TYPE,
    it_freshness_check_value   IN     xxcop_wk_yoko_plan_output.freshness_check_value%TYPE,
    it_freshness_adjust_value  IN     xxcop_wk_yoko_plan_output.freshness_adjust_value%TYPE,
    it_max_stock_days          IN     xxcop_wk_yoko_plan_output.max_stock_days%TYPE,
    it_sy_manufacture_date     IN     xxcop_wk_yoko_plan_output.sy_manufacture_date%TYPE,
    ov_errbuf                  OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_balance'; -- �v���O������
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
    ln_stock_quantity         NUMBER;
    ln_allocated_quantity     NUMBER;
    ln_xli_idx                NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɂ̎擾
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                lot_id
            ,xliv.lot_no                                lot_no
            ,xliv.manufacture_date                      manufacture_date
            ,xliv.expiration_date                       expiration_date
            ,xliv.unique_sign                           unique_sign
            ,xliv.lot_status                            lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                        loct_onhand
      FROM (
        SELECT xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,xli.loct_onhand                          unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_schedule_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                      limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, it_schedule_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_schedule_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                      limited_loct_onhand
        FROM (
          SELECT xli.lot_id                               lot_id
                ,xli.lot_no                               lot_no
                ,xli.manufacture_date                     manufacture_date
                ,xli.expiration_date                      expiration_date
                ,xli.unique_sign                          unique_sign
                ,xli.lot_status                           lot_status
                ,xli.schedule_date                        schedule_date
                ,SUM(xli.loct_onhand)                     loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, it_schedule_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      WHERE xxcop_common_pkg2.get_critical_date_f(
               it_freshness_class
              ,it_freshness_check_value
              ,it_freshness_adjust_value
              ,it_max_stock_days
              ,gn_freshness_buffer_days
              ,xliv.manufacture_date
              ,xliv.expiration_date
            ) >= it_schedule_date
        AND xliv.manufacture_date >= NVL(it_sy_manufacture_date, xliv.manufacture_date)
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.lot_status
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xli_tab                 g_xli_ttype;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    ln_stock_quantity     := 0;
    ln_allocated_quantity := 0;
    ln_xli_idx            := 0;
    l_xli_tab.DELETE;
--
    BEGIN
--
--      --�f�o�b�N���b�Z�[�W�o��(�ړ���)
--      xxcop_common_pkg.put_debug_message(
--         iov_debug_mode => gv_debug_mode
--        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
--                        || 'entry_loct:'
--                        || it_loct_code                               || ','
--                        || it_item_no                                 || ','
--                        || TO_CHAR(it_schedule_date, cv_date_format)  || ','
--                        || it_schedule_quantity                       || ','
--      );
--
      --�ړ���q�ɂ̑N�x�����ʉ����O�݌ɐ���0�ȊO�̏ꍇ�A���b�g�݌ɂ��擾
      IF (it_schedule_quantity <> 0) THEN
        --�N�x�����ɍ��v���郍�b�g�ʍ݌ɐ����擾
        <<xliv_loop>>
        FOR l_xliv_rec IN xliv_cur(it_item_id
                                 , it_loct_id
        ) LOOP
          BEGIN
            --���b�g�݌ɐ���0�̏ꍇ�A�X�L�b�v
            IF (l_xliv_rec.loct_onhand = 0) THEN
              RAISE lot_skip_expt;
            END IF;
--
            ln_xli_idx := ln_xli_idx + 1;
            --���b�g�݌ɂ̈��������v�Z
            ln_stock_quantity     := LEAST(it_schedule_quantity - ln_allocated_quantity, l_xliv_rec.loct_onhand);
            ln_allocated_quantity := ln_allocated_quantity + ln_stock_quantity;
--
            --�����v��莝�݌Ƀe�[�u���R���N�V�����^�Ɋi�[
            l_xli_tab(ln_xli_idx).transaction_id          := gn_transaction_id;
            l_xli_tab(ln_xli_idx).loct_id                 := it_loct_id;
            l_xli_tab(ln_xli_idx).loct_code               := it_loct_code;
            l_xli_tab(ln_xli_idx).item_id                 := it_item_id;
            l_xli_tab(ln_xli_idx).item_no                 := it_item_no;
            l_xli_tab(ln_xli_idx).lot_id                  := l_xliv_rec.lot_id;
            l_xli_tab(ln_xli_idx).lot_no                  := l_xliv_rec.lot_no;
            l_xli_tab(ln_xli_idx).manufacture_date        := l_xliv_rec.manufacture_date;
            l_xli_tab(ln_xli_idx).expiration_date         := l_xliv_rec.expiration_date;
            l_xli_tab(ln_xli_idx).unique_sign             := l_xliv_rec.unique_sign;
            l_xli_tab(ln_xli_idx).lot_status              := l_xliv_rec.lot_status;
            l_xli_tab(ln_xli_idx).loct_onhand             := ln_stock_quantity * -1;
            l_xli_tab(ln_xli_idx).schedule_date           := it_schedule_date;
            l_xli_tab(ln_xli_idx).shipment_date           := cd_lower_limit_date;
            l_xli_tab(ln_xli_idx).transaction_type        := cv_xli_type_bq;
            l_xli_tab(ln_xli_idx).simulate_flag           := cv_simulate_yes;
            l_xli_tab(ln_xli_idx).created_by              := cn_created_by;
            l_xli_tab(ln_xli_idx).creation_date           := cd_creation_date;
            l_xli_tab(ln_xli_idx).last_updated_by         := cn_last_updated_by;
            l_xli_tab(ln_xli_idx).last_update_date        := cd_last_update_date;
            l_xli_tab(ln_xli_idx).last_update_login       := cn_last_update_login;
            l_xli_tab(ln_xli_idx).request_id              := cn_request_id;
            l_xli_tab(ln_xli_idx).program_application_id  := cn_program_application_id;
            l_xli_tab(ln_xli_idx).program_id              := cn_program_id;
            l_xli_tab(ln_xli_idx).program_update_date     := cd_program_update_date;
--
            --�N�x�����ʍ݌ɐ��̍��v�������O�݌ɂ𒴂����ꍇ�A�I��
            IF (it_schedule_quantity <= ln_allocated_quantity) THEN
              EXIT xliv_loop;
            END IF;
          EXCEPTION
            WHEN lot_skip_expt THEN
              NULL;
          END;
        END LOOP xliv_loop;
        --�����O�݌ɐ��������v��莝�݌Ƀe�[�u���ɓo�^
        FORALL ln_xli_idx in 1..l_xli_tab.COUNT
          INSERT INTO xxcop_loct_inv VALUES l_xli_tab(ln_xli_idx);
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xli_balance;
--
  /**********************************************************************************
   * Procedure Name   : entry_supply_failed
   * Description      : �����v��o�̓��[�N�e�[�u���o�^(�v��s��)(B-21)
   ***********************************************************************************/
  PROCEDURE entry_supply_failed(
    i_rcpt_rec       IN     g_loct_rtype,   --   �ړ���q�Ƀ��R�[�h�^
    io_xwypo_tab     IN OUT g_xwypo_ttype,  --   �����v��o�̓��[�N�e�[�u���R���N�V�����^
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_supply_failed'; -- �v���O������
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    <<xwypo_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_xwypo_idx).rcpt_loct_id) THEN
        IF    (io_xwypo_tab(ln_xwypo_idx).plan_lot_quantity = 0)
          AND (io_xwypo_tab(ln_xwypo_idx).before_stock < io_xwypo_tab(ln_xwypo_idx).shipping_pace
                                                       * io_xwypo_tab(ln_xwypo_idx).max_stock_days)
        THEN
          --�o�����X�v�Z�ŕ�[�\�����s�����Ă��邽�߁A
          --�ړ����q�ɂ���ړ���q�ɂɈړ����s�\�ȏꍇ
          --�f�o�b�N���b�Z�[�W�o��
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                            || 'not_alloc_lot:'
                            || TO_CHAR(gd_planning_date, cv_date_format)                        || ','
                            || TO_CHAR(io_xwypo_tab(ln_xwypo_idx).receipt_date, cv_date_format) || ','
                            || io_xwypo_tab(ln_xwypo_idx).item_no                               || ','
                            || io_xwypo_tab(ln_xwypo_idx).rcpt_loct_code                        || ','
                            || io_xwypo_tab(ln_xwypo_idx).freshness_condition                   || ','
          );
          --���b�g���̃N���A
          io_xwypo_tab(ln_xwypo_idx).manufacture_date := NULL;
          io_xwypo_tab(ln_xwypo_idx).lot_status       := NULL;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
          io_xwypo_tab(ln_xwypo_idx).before_lot_stock := io_xwypo_tab(ln_xwypo_idx).before_stock;
          io_xwypo_tab(ln_xwypo_idx).after_lot_stock  := io_xwypo_tab(ln_xwypo_idx).after_stock;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
          -- ===============================
          -- B-25�D�����v��o�̓��[�N�e�[�u���o�^
          -- ===============================
          entry_xwypo(
             iv_supply_status           => cv_failed
            ,i_xwypo_rec                => io_xwypo_tab(ln_xwypo_idx)
            ,ov_errbuf                  => lv_errbuf
            ,ov_retcode                 => lv_retcode
            ,ov_errmsg                  => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    END LOOP xwypo_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_supply_failed;
--
  /**********************************************************************************
   * Procedure Name   : proc_lot_quantity
   * Description      : �v�惍�b�g�̌���(B-20)
   ***********************************************************************************/
  PROCEDURE proc_lot_quantity(
    i_item_rec              IN     g_item_rtype,   --   �i�ڏ�񃌃R�[�h�^
    i_ship_rec              IN     g_loct_rtype,   --   �ړ����q�Ƀ��R�[�h�^
    i_rcpt_rec              IN     g_loct_rtype,   --   �ړ���q�Ƀ��R�[�h�^
    it_sy_manufacture_date  IN     xxcop_wk_yoko_plan_output.sy_manufacture_date%TYPE,
    io_gbqt_tab             IN OUT g_bq_ttype,     --   �o�����X�����v��R���N�V�����^
    io_xwypo_tab            IN OUT g_xwypo_ttype,  --   �����v��o�̓��[�N�e�[�u���R���N�V�����^
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
    ov_stock_result            OUT VARCHAR2,       --   ���b�g�o�����X�̌v��X�e�[�^�X
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
    ov_errbuf               OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_lot_quantity'; -- �v���O������
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
    ln_lot_quantity           NUMBER;         --���b�g�݌ɐ�(�q�ɕ�)
    ln_lot_freshness_quantity NUMBER;         --�N�x�����ʃ��b�g�݌ɐ�(�o�׃y�[�X�ň���������)
    ln_shipping_pace          NUMBER;         --�o�׃y�[�X�̍��v(�q�ɕ�)
    ln_balance_quantity       NUMBER;         --���b�g�ʃo�����X�v�搔�̍��v(�q�ɕ�)
--
    ln_total_lot_quantity     NUMBER;         --���b�g�݌ɐ�(�����N�������v)
    ln_total_shipping_pace    NUMBER;         --�o�׃y�[�X�̍��v(�����N�������v)
    ln_surpluses_quantity     NUMBER;         --�ړ����q�ɂ̗]��݌ɐ�
    ln_lot_supplies_quantity  NUMBER;         --��[�\��(�����N�������v)
    ln_div_quantity           NUMBER;         --���݌ɐ�
    ln_adjust_quantity        NUMBER;         --���b�g�ߕs����
    ln_plan_lot_quantity      NUMBER;         --���b�g�v�搔���v
    ln_require_quantity       NUMBER;         --��[�v����
    ln_require_shipping_pace  NUMBER;         --�o�׃y�[�X�̍��v(��[�v����)
    ln_supplies_quantity      NUMBER;         --��[�\��(��[�v�������v�Z)
    ln_lot_count              NUMBER;         --���ꃍ�b�g�̌���
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
    ln_condition_count        NUMBER;         --���b�g���N�x�����ɍ��v��������
    ln_condition_idx          NUMBER;         --�N�x�����ɍ��v�����N�x������INDEX
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
    lv_stock_proc_flag        VARCHAR2(1);
    lv_stock_filled_flag      VARCHAR2(1);
    ln_filled_quantity        NUMBER;         --�N�x�����Ɉ������ꂽ���b�g�݌ɐ����v
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
    ln_max_filled_count       NUMBER;         --�v�搔(�ő�)�܂ŕ�[�����N�x�����̌���
    ln_bal_filled_count       NUMBER;         --�v�搔(�o�����X)�܂ŕ�[�����N�x�����̌���
    ln_sy_stocked_quantity    NUMBER;         --���ʉ����v��̈ړ������v(�X�V�l)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɂ̎擾
    CURSOR xliv_cur(
       in_item_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                lot_id
            ,xliv.lot_no                                lot_no
            ,xliv.manufacture_date                      manufacture_date
            ,xliv.expiration_date                       expiration_date
            ,xliv.unique_sign                           unique_sign
            ,xliv.lot_status                            lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                        loct_onhand
            ,xliv.loct_id                               loct_id
            ,GROUPING_ID(xliv.lot_id
                        ,xliv.lot_no
                        ,xliv.manufacture_date
                        ,xliv.expiration_date
                        ,xliv.unique_sign
                        ,xliv.lot_status
                        ,xliv.loct_id
             )                                          record_class
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xwyl.frq_loct_id                         loct_id
              ,xwyl.frq_loct_code                       loct_code
              ,xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,xli.loct_onhand                          unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= xwyl.schedule_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                      limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, xwyl.schedule_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.planning_flag      = cv_inc_loct
        UNION ALL
        SELECT xli.loct_id                              loct_id
              ,xli.loct_code                            loct_code
              ,xli.lot_id                               lot_id
              ,xli.lot_no                               lot_no
              ,xli.manufacture_date                     manufacture_date
              ,xli.expiration_date                      expiration_date
              ,xli.unique_sign                          unique_sign
              ,xli.lot_status                           lot_status
              ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= xli.target_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                      limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xwyl.loct_id                           loct_id
                ,xwyl.loct_code                         loct_code
                ,xli.lot_id                             lot_id
                ,xli.lot_no                             lot_no
                ,xli.manufacture_date                   manufacture_date
                ,xli.expiration_date                    expiration_date
                ,xli.unique_sign                        unique_sign
                ,xli.lot_status                         lot_status
                ,xli.schedule_date                      schedule_date
                ,xwyl.schedule_date                     target_date
                ,SUM(xli.loct_onhand)                   loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, xwyl.schedule_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.planning_flag      = cv_off_loct
          GROUP BY xwyl.loct_id
                  ,xwyl.loct_code
                  ,xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
                  ,xwyl.schedule_date
        ) xli
      ) xliv
      GROUP BY ROLLUP(
         xliv.lot_id
        ,xliv.lot_no
        ,xliv.manufacture_date
        ,xliv.expiration_date
        ,xliv.unique_sign
        ,xliv.lot_status
        ,xliv.loct_id
      )
      HAVING GROUPING_ID(
                xliv.lot_id
               ,xliv.lot_no
               ,xliv.manufacture_date
               ,xliv.expiration_date
               ,xliv.unique_sign
               ,xliv.lot_status
               ,xliv.loct_id
             ) < 2
      ORDER BY xliv.manufacture_date
              ,xliv.unique_sign
              ,xliv.expiration_date
              ,xliv.loct_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xliv_rec                g_loct_inv_rtype;
    l_ship_lot_tab            g_lot_ttype;
    l_rcpt_lot_tab            g_lot_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_lot_quantity           := NULL;
    ln_lot_freshness_quantity := NULL;
    ln_shipping_pace          := NULL;
    ln_balance_quantity       := NULL;
    ln_total_lot_quantity     := NULL;
    ln_total_shipping_pace    := NULL;
    ln_surpluses_quantity     := NULL;
    ln_lot_supplies_quantity  := NULL;
    ln_div_quantity           := NULL;
    ln_adjust_quantity        := NULL;
    ln_plan_lot_quantity      := NULL;
    ln_require_quantity       := NULL;
    ln_require_shipping_pace  := NULL;
    ln_supplies_quantity      := NULL;
    ln_lot_count              := NULL;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
    ln_condition_count        := NULL;
    ln_condition_idx          := NULL;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
    lv_stock_proc_flag        := NULL;
    lv_stock_filled_flag      := NULL;
    ln_filled_quantity        := NULL;
    l_xliv_rec                := NULL;
    l_ship_lot_tab.DELETE;
    l_rcpt_lot_tab.DELETE;
--
    --�ړ����A�ړ���q�ɂ̌v�旧��FLAG�A�v������X�V
    -- ===============================
    -- B-23�D�����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���X�V
    -- ===============================
    update_xwyl_schedule(
       it_item_id        => i_item_rec.item_id
      ,i_ship_rec        => i_ship_rec
      ,i_xwypo_tab       => io_xwypo_tab
      ,ov_errbuf         => lv_errbuf
      ,ov_retcode        => lv_retcode
      ,ov_errmsg         => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --������
    ln_lot_count := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
    ln_condition_count        := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
    ln_lot_supplies_quantity  := 0;
    ln_surpluses_quantity     := 0;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
    ln_max_filled_count       := 0;
    ln_bal_filled_count       := 0;
    ov_stock_result           := cv_failed;
    ln_sy_stocked_quantity    := NULL;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
--
    --�ړ����q�ɁA�ړ���q�ɂ̃��b�g�ʍ݌ɐ����擾
    OPEN xliv_cur(i_item_rec.item_id);
    <<xliv_loop>>
    LOOP
      FETCH xliv_cur INTO l_xliv_rec;
      EXIT WHEN xliv_cur%NOTFOUND;
      BEGIN
--
        --�f�o�b�N���b�Z�[�W�o��(���b�g)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'xliv_cur:'
                          || '(' || l_xliv_rec.record_class || ')'                || ','
                          || l_xliv_rec.loct_id                                   || ','
                          || l_xliv_rec.loct_onhand                               || ','
                          || l_xliv_rec.lot_status                                || ','
                          || TO_CHAR(l_xliv_rec.manufacture_date, cv_date_format) || ','
                          || TO_CHAR(l_xliv_rec.expiration_date , cv_date_format) || ','
                          || l_xliv_rec.lot_no                                    || ','
                          || ln_condition_count                                   || ','
        );
--
        IF (l_xliv_rec.record_class = 0) THEN
          --���׃��R�[�h
          --���b�g�݌ɐ���0�̏ꍇ�A�X�L�b�v
          IF (l_xliv_rec.loct_onhand = 0) THEN
            RAISE lot_skip_expt;
          END IF;
--
          --���b�g���N�x�����ɍ��v���邩�`�F�b�N
          IF (ln_lot_count = 0) THEN
            --������
            --���b�g���ړ����q�ɂ̑N�x�����ɍ��v���邩�`�F�b�N
            <<ship_critical_date_loop>>
            FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
              --�����N�����Ⴂ�̃��b�g�ŏ�����
              l_ship_lot_tab(ln_ship_idx).lot_quantity       := NULL;
              l_ship_lot_tab(ln_ship_idx).freshness_quantity := NVL(l_ship_lot_tab(ln_ship_idx).freshness_quantity, 0);
              l_ship_lot_tab(ln_ship_idx).plan_bal_quantity  := NVL(l_ship_lot_tab(ln_ship_idx).plan_bal_quantity, 0);
              l_ship_lot_tab(ln_ship_idx).adjust_quantity    := NVL(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0);
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              --�N�x�����ʍ݌ɂ�������݌ɂ܂ň�������Ă��Ȃ��ꍇ�A�t���O��YES�ɂ���
--              IF (io_gbqt_tab(ln_ship_idx).after_stock > l_ship_lot_tab(ln_ship_idx).freshness_quantity) THEN
--                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_yes;
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_yes;
--              ELSE
--                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_no;
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--                l_ship_lot_tab(ln_ship_idx).adjust_quantity  := 0;
--              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
              --�N�x��������擾�֐�
              l_ship_lot_tab(ln_ship_idx).critical_date := (
                xxcop_common_pkg2.get_critical_date_f(
                   iv_freshness_class        => io_gbqt_tab(ln_ship_idx).freshness_class
                  ,in_freshness_check_value  => io_gbqt_tab(ln_ship_idx).freshness_check_value
                  ,in_freshness_adjust_value => io_gbqt_tab(ln_ship_idx).freshness_adjust_value
                  ,in_max_stock_days         => io_gbqt_tab(ln_ship_idx).max_stock_days
                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                  ,id_expiration_date        => l_xliv_rec.expiration_date
                )
              );
              --�N�x��������v���Ȃ��ꍇ�͑ΏۊO
              IF (i_ship_rec.target_date > l_ship_lot_tab(ln_ship_idx).critical_date) THEN
                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_no;
                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
              ELSE
                l_ship_lot_tab(ln_ship_idx).stock_proc_flag  := cv_planning_yes;
                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_yes;
                ln_condition_count := ln_condition_count + 1;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
              END IF;
--
              --�f�o�b�N���b�Z�[�W�o��(������)
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                                || 'proc_lot_init(ship):'
                                || i_ship_rec.loct_code                                 || ','
                                || io_gbqt_tab(ln_ship_idx).freshness_condition         || ','
                                || NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, -999)  || ','
                                || l_ship_lot_tab(ln_ship_idx).freshness_quantity       || ','
                                || l_ship_lot_tab(ln_ship_idx).plan_bal_quantity        || ','
                                || l_ship_lot_tab(ln_ship_idx).adjust_quantity          || ','
                                || l_ship_lot_tab(ln_ship_idx).stock_proc_flag          || ','
                                || l_ship_lot_tab(ln_ship_idx).adjust_proc_flag         || ','
                                || TO_CHAR(l_ship_lot_tab(ln_ship_idx).critical_date, cv_date_format) || ','
              );
--
            END LOOP ship_critical_date_loop;
--
            --���b�g���ړ���q�ɂ̑N�x�����ɍ��v���邩�`�F�b�N
            <<rcpt_critical_date_loop>>
            FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�����N�����Ⴂ�̃��b�g�ŏ�����
              l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity       := NULL;
              l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity := NVL(l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity, 0);
              l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity  := NVL(l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity, 0);
              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity    := NVL(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity, 0);
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              --�N�x�����ʍ݌ɂ������O�݌ɂ܂ň�������Ă��Ȃ��ꍇ�A�t���O��YES�ɂ���
--              IF (io_xwypo_tab(ln_rcpt_idx).before_stock <> l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity) THEN
--                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_yes;
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
--              END IF;
--              --�N�x�����ʍ݌ɂ������O�݌ɂ܂ň�������Ă��Ȃ��ꍇ�A�܂���
--              --���b�g�ʌv�搔���o�����X�v�搔�܂ň�������Ă��Ȃ��ꍇ�A�t���O��YES�ɂ���
--              IF   (io_xwypo_tab(ln_rcpt_idx).before_stock     <> l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity)
--                OR (io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity) THEN
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_yes;
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity  := 0;
--              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
              io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity    := 0;
              --�N�x��������擾�֐�
              l_rcpt_lot_tab(ln_rcpt_idx).critical_date := (
                xxcop_common_pkg2.get_critical_date_f(
                   iv_freshness_class        => io_xwypo_tab(ln_rcpt_idx).freshness_class
                  ,in_freshness_check_value  => io_xwypo_tab(ln_rcpt_idx).freshness_check_value
                  ,in_freshness_adjust_value => io_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
                  ,in_max_stock_days         => io_xwypo_tab(ln_rcpt_idx).max_stock_days
                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                  ,id_expiration_date        => l_xliv_rec.expiration_date
                )
              );
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
              --�N�x��������v���Ȃ��ꍇ�͑ΏۊO
              IF (io_xwypo_tab(ln_rcpt_idx).receipt_date > l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
                l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
              ELSE
                --�N�x�����ʍ݌ɂ������O�݌ɂ܂ň�������Ă��Ȃ��ꍇ�A�t���O��YES�ɂ���
                --�����O�݌ɂ����l�̏ꍇ�A�����O�݌Ɂ��N�x�����ʍ݌ɂ܂�
                --�����O�݌ɂ����l�̏ꍇ�A�����O�݌Ɂ��N�x�����ʍ݌ɂ܂�
                IF ((io_xwypo_tab(ln_rcpt_idx).before_stock > 0)
                    AND (io_xwypo_tab(ln_rcpt_idx).before_stock > l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity))
                  OR ((io_xwypo_tab(ln_rcpt_idx).before_stock < 0)
                    AND (io_xwypo_tab(ln_rcpt_idx).before_stock < l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity))
                THEN
                  l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_yes;
                ELSE
                  l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag  := cv_planning_no;
                END IF;
                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_yes;
                ln_condition_count := ln_condition_count + 1;
              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
--
              --�f�o�b�N���b�Z�[�W�o��(������)
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                                || 'proc_lot_init(rcpt):'
                                || io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code             || ','
                                || io_xwypo_tab(ln_rcpt_idx).freshness_condition        || ','
                                || NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, -999)  || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity       || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity        || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity          || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag          || ','
                                || l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag         || ','
                                || TO_CHAR(l_rcpt_lot_tab(ln_rcpt_idx).critical_date, cv_date_format) || ','
              );
--
            END LOOP rcpt_critical_date_loop;
          END IF;
          ln_lot_count := ln_lot_count + 1;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
          --�N�x�����ɍ��v���Ȃ��ꍇ�A�X�L�b�v
          IF (ln_condition_count = 0) THEN
            RAISE lot_skip_expt;
          END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
--
          IF (i_ship_rec.loct_id = l_xliv_rec.loct_id) THEN
            -- ===============================
            -- �ړ����q�ɂ̃��b�g
            -- ===============================
            --���b�g�݌ɂ��o�׃y�[�X�̔䗦�őN�x�����ʍ݌ɂɈ�
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--            ln_lot_quantity := l_xliv_rec.loct_onhand;
--            lv_stock_filled_flag := cv_planning_no;
--            ln_filled_quantity   := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
            <<ship_div_lot_stock_loop>>
            LOOP
              --������
              lv_stock_proc_flag  := cv_planning_yes;
              ln_shipping_pace    := 0;
              ln_balance_quantity := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--              ln_lot_quantity     := l_xliv_rec.loct_onhand - ln_filled_quantity;
              ln_lot_quantity     := l_xliv_rec.loct_onhand;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
              --�N�x�����ɍ��v����o�׃y�[�X���W�v
              <<ship_div_lot_summary_loop>>
              FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                IF (lv_stock_filled_flag = cv_planning_yes)
--                  AND (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_omit)
--                THEN
--                  l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_yes;
--                END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                IF (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                  --�N�x�����ɍ��v�����ꍇ
--                  IF (i_ship_rec.target_date <= l_ship_lot_tab(ln_ship_idx).critical_date) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                  --�N�x�����ɍ��v�����o�׃y�[�X���v
                  ln_shipping_pace := ln_shipping_pace + io_gbqt_tab(ln_ship_idx).shipping_pace;
                  --���b�g�݌ɐ��{�ߕs�����̍��v
                  ln_lot_quantity := ln_lot_quantity + l_ship_lot_tab(ln_ship_idx).adjust_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                  ELSE
--                    l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_no;
--                  END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                END IF;
              END LOOP ship_div_lot_summary_loop;
              --���b�g���S�Ă̑N�x�����ɍ��v���Ȃ��ꍇ�A�v�Z���I��
              IF (ln_shipping_pace = 0) THEN
                EXIT ship_div_lot_stock_loop;
              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              lv_stock_filled_flag := cv_planning_no;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
              --�o�׃y�[�X�̔䗦�őN�x�����ʍ݌ɂɈ�
              <<ship_div_balance_loop>>
              FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
                IF (l_ship_lot_tab(ln_ship_idx).stock_proc_flag = cv_planning_yes) THEN
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
                  IF (io_gbqt_tab(ln_ship_idx).shipping_pace > 0) THEN
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
                    --���b�g�ʃo�����X�v�搔�̌v�Z
                    --�[���͗D�揇�ʂ̍����N�x�����Ɉ������Ă�
                    ln_lot_freshness_quantity := CEIL(ln_lot_quantity
                                                    * io_gbqt_tab(ln_ship_idx).shipping_pace
                                                    / ln_shipping_pace
                                                 );
                    l_ship_lot_tab(ln_ship_idx).lot_quantity := ln_lot_freshness_quantity
                                                              - l_ship_lot_tab(ln_ship_idx).adjust_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                  --������݌ɐ������
--                  l_ship_lot_tab(ln_ship_idx).lot_quantity := LEAST(l_ship_lot_tab(ln_ship_idx).lot_quantity
--                                                                  , io_gbqt_tab(ln_ship_idx).after_stock
--                                                                  - l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                              );
--                  --�N�x�����ʍ݌ɐ��������O�݌ɂ܂ň����ł����ꍇ�A�N�x����1����Čv�Z����B
--                  IF ( io_gbqt_tab(ln_ship_idx).after_stock = l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                            + l_ship_lot_tab(ln_ship_idx).lot_quantity)
--                  THEN
--                    lv_stock_proc_flag   := cv_planning_no;
--                    lv_stock_filled_flag := cv_planning_yes;
--                    ln_filled_quantity := ln_filled_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
--                    l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_no;
--                    EXIT ship_div_balance_loop;
--                  END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                    --���b�g�ʃo�����X�v�搔�̍��v
                    ln_balance_quantity := ln_balance_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
                    --�N�x�����ʍ݌ɂɈ����������b�g�݌ɐ������Z
                    ln_lot_quantity := ln_lot_quantity - ln_lot_freshness_quantity;
                    ln_shipping_pace := ln_shipping_pace - io_gbqt_tab(ln_ship_idx).shipping_pace;
                    --���b�g�݌ɐ��̕����ƑN�x�����ʃ��b�g�݌ɐ��̕������Ⴄ�ꍇ�A�����珜�O����
                    IF (SIGN(l_xliv_rec.loct_onhand) <> SIGN(l_ship_lot_tab(ln_ship_idx).lot_quantity)) THEN
                      lv_stock_proc_flag  := cv_planning_no;
                      --�N�x�����ʃ��b�g�݌ɐ��̏�����
                      l_ship_lot_tab(ln_ship_idx).lot_quantity := 0;
                      l_ship_lot_tab(ln_ship_idx).stock_proc_flag := cv_planning_omit;
                    END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
                  END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
                END IF;
              END LOOP ship_div_balance_loop;
              IF (lv_stock_proc_flag = cv_planning_yes) THEN
                EXIT ship_div_lot_stock_loop;
              END IF;
            END LOOP ship_div_lot_stock_loop;
            --��������Ă��Ȃ����b�g�݌ɕ␔
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--            ln_lot_supplies_quantity := l_xliv_rec.loct_onhand - ln_balance_quantity - ln_filled_quantity;
            ln_lot_supplies_quantity := l_xliv_rec.loct_onhand - ln_balance_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
--
          ELSE
            -- ===============================
            -- �ړ���q�ɂ̃��b�g
            -- ===============================
            --���b�g�݌ɂ��o�׃y�[�X�̔䗦�őN�x�����ʍ݌ɂɈ�
            ln_lot_quantity := l_xliv_rec.loct_onhand;
            lv_stock_filled_flag := cv_planning_no;
            ln_filled_quantity   := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
            ln_condition_idx     := NULL;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
            <<rcpt_div_lot_stock_loop>>
            LOOP
              --������
              lv_stock_proc_flag  := cv_planning_yes;
              ln_shipping_pace    := 0;
              ln_balance_quantity := 0;
              ln_lot_quantity     := l_xliv_rec.loct_onhand - ln_filled_quantity;
              --�N�x�����ɍ��v����o�׃y�[�X���W�v
              <<rcpt_div_proc_loop>>
              FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                --���q�ɂ̃��b�g�̏ꍇ
                IF (io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id  = l_xliv_rec.loct_id) THEN
                  IF (lv_stock_filled_flag = cv_planning_yes)
                    AND (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_omit)
                  THEN
                    l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_yes;
                  END IF;
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                    --�N�x�����ɍ��v�����ꍇ
--                    IF (io_xwypo_tab(ln_rcpt_idx).receipt_date <= l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                    --�N�x�����ɍ��v�����o�׃y�[�X���v
                    ln_shipping_pace := ln_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    --���b�g�݌ɐ��{�ߕs�����̍��v
                    ln_lot_quantity := ln_lot_quantity + l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                    ELSE
--                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_no;
--                    END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                  END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
                  --���v���Ă���N�x������INDEX��ێ�
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    ln_condition_idx := NVL( ln_condition_idx, ln_rcpt_idx);
                  END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
                END IF;
              END LOOP rcpt_div_proc_loop;
              --���b�g���N�x�����ɍ��v���Ȃ��ꍇ�A�v�Z���I��
              IF (ln_shipping_pace = 0) THEN
                EXIT rcpt_div_lot_stock_loop;
              END IF;
              lv_stock_filled_flag := cv_planning_no;
              --�o�׃y�[�X�̔䗦�őN�x�����ʍ݌ɂɈ�
              <<rcpt_div_balance_loop>>
              FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                --���q�ɂ̃��b�g�̏ꍇ
                IF (io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id  = l_xliv_rec.loct_id) THEN
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag = cv_planning_yes) THEN
                    --���b�g�ʃo�����X�v�搔�̌v�Z
                    --�[���͗D�揇�ʂ̍����N�x�����Ɉ������Ă�
                    ln_lot_freshness_quantity := CEIL(ln_lot_quantity
                                                    * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                    / ln_shipping_pace
                                                 );
                    l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := ln_lot_freshness_quantity
                                                              - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                    --�����O�݌ɐ������
                    l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := LEAST(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity
                                                                    , io_xwypo_tab(ln_rcpt_idx).before_stock
                                                                    - l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                                );
                    --�N�x�����ʍ݌ɐ��������O�݌ɂ܂ň����ł����ꍇ�A�N�x����1����Čv�Z����B
                    IF ( io_xwypo_tab(ln_rcpt_idx).before_stock = l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                                + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity)
                    THEN
                      lv_stock_proc_flag   := cv_planning_no;
                      lv_stock_filled_flag := cv_planning_yes;
                      ln_filled_quantity := ln_filled_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_no;
                      EXIT rcpt_div_balance_loop;
                    END IF;
                    --���b�g�ʃo�����X�v�搔�̍��v
                    ln_balance_quantity := ln_balance_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
                    --�N�x�����ʍ݌ɂɈ����������b�g�݌ɐ������Z
                    ln_lot_quantity := ln_lot_quantity - ln_lot_freshness_quantity;
                    ln_shipping_pace := ln_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    --���b�g�݌ɐ��̕����ƑN�x�����ʃ��b�g�݌ɐ��̕������Ⴄ�ꍇ�A�����珜�O����
                    IF (SIGN(l_xliv_rec.loct_onhand) <> SIGN(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity)) THEN
                      lv_stock_proc_flag  := cv_planning_no;
                      --�N�x�����ʃ��b�g�݌ɐ��̏�����
                      l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := 0;
                      l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag := cv_planning_omit;
                    END IF;
                  END IF;
                END IF;
              END LOOP rcpt_div_balance_loop;
              IF (lv_stock_proc_flag = cv_planning_yes) THEN
                EXIT rcpt_div_lot_stock_loop;
              END IF;
            END LOOP rcpt_div_lot_stock_loop;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
            --�N�x�����ʍ݌ɂɈĕ����Ȃ������݌ɐ������Z
            IF (ln_condition_idx IS NOT NULL) THEN
              l_rcpt_lot_tab(ln_condition_idx).lot_quantity := NVL(l_rcpt_lot_tab(ln_condition_idx).lot_quantity, 0)
                                                             + l_xliv_rec.loct_onhand
                                                             - ln_filled_quantity
                                                             - ln_balance_quantity;
            END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
          END IF;
        ELSE
          --���v���R�[�h
          --���b�g�݌ɐ����S��0�̏ꍇ�A�X�L�b�v
          IF (ln_lot_count = 0) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--            RAISE lot_skip_expt;
            RAISE manufacture_skip_expt;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
          END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
          --�N�x�����ɍ��v���Ȃ��ꍇ�A�X�L�b�v
          IF (ln_condition_count = 0) THEN
            RAISE manufacture_skip_expt;
          END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
          -- ===============================
          -- ���b�g�v�搔�̌v�Z
          -- ===============================
          --
          -- (1) �N�x�����ɍ��v����o�׃y�[�X���W�v
          --
          --������
          ln_total_lot_quantity     := 0;
          ln_total_shipping_pace    := 0;
          ln_require_shipping_pace  := 0;
          ln_require_quantity       := 0;
          ln_plan_lot_quantity      := 0;
--
          <<ship_proc_summary_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --�N�x�����ʃ��b�g�݌ɐ�����������Ă��Ȃ��ꍇ�A0���Z�b�g
            l_ship_lot_tab(ln_ship_idx).lot_quantity := NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, 0);
            IF (l_ship_lot_tab(ln_ship_idx).adjust_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              --�N�x�����ɍ��v�����ꍇ
--              IF (i_ship_rec.target_date <= l_ship_lot_tab(ln_ship_idx).critical_date) THEN
--                --������݌ɂ܂ň������ꂽ�ꍇ�A�ΏۊO�Ƃ���
--                IF (io_gbqt_tab(ln_ship_idx).after_stock > l_ship_lot_tab(ln_ship_idx).freshness_quantity
--                                                         + l_ship_lot_tab(ln_ship_idx).lot_quantity)
--                THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
              --�o�׃y�[�X�̍��v���W�v
              ln_total_shipping_pace := ln_total_shipping_pace + io_gbqt_tab(ln_ship_idx).shipping_pace;
              --���b�g�݌ɐ��̍��v���W�v
              ln_total_lot_quantity := ln_total_lot_quantity + l_ship_lot_tab(ln_ship_idx).lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                ELSE
--                  l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--                END IF;
--              ELSE
--                l_ship_lot_tab(ln_ship_idx).adjust_proc_flag := cv_planning_no;
--              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
            END IF;
          END LOOP ship_proc_summary_loop;
--
          <<rcpt_proc_summary_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�N�x�����ʃ��b�g�݌ɐ�����������Ă��Ȃ��ꍇ�A0���Z�b�g
            l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity := NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, 0);
            IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              --�N�x�����ɍ��v�����ꍇ
--              IF (io_xwypo_tab(ln_rcpt_idx).receipt_date <= l_rcpt_lot_tab(ln_rcpt_idx).critical_date) THEN
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
              --�o�׃y�[�X�̍��v���W�v
              ln_total_shipping_pace := ln_total_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
              --���b�g�݌ɐ��̍��v���W�v
              ln_total_lot_quantity := ln_total_lot_quantity + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--              ELSE
--                l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag := cv_planning_no;
--              END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
            END IF;
          END LOOP rcpt_proc_summary_loop;
--
          --�f�o�b�N���b�Z�[�W�o��(��[�\���A���o�׃y�[�X)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(1):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_total_lot_quantity      || ','
                            || ln_total_shipping_pace     || ','
          );
--
          --
          -- (2) �N�x�����ʃ��b�g�݌ɂ̉ߕs�������v�Z
          --
          <<ship_proc_adjust_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --�v��Ώۃt���O
            IF (l_ship_lot_tab(ln_ship_idx).adjust_proc_flag = cv_planning_yes) THEN
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_START
              IF (ln_total_shipping_pace > 0) THEN
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_END
              --���v�Z
              ln_div_quantity := CEIL(ln_total_lot_quantity
                                    * io_gbqt_tab(ln_ship_idx).shipping_pace
                                    / ln_total_shipping_pace
                                 );
              --�ߕs�����̌v�Z
              ln_adjust_quantity := l_ship_lot_tab(ln_ship_idx).lot_quantity - ln_div_quantity;
              --�Â����b�g�̉ߕs���������Z
              l_ship_lot_tab(ln_ship_idx).adjust_quantity := l_ship_lot_tab(ln_ship_idx).adjust_quantity
                                                           + ln_adjust_quantity;
              --�ĕ��݌ɐ������Z
              ln_total_lot_quantity := ln_total_lot_quantity - ln_div_quantity;
              ln_total_shipping_pace := ln_total_shipping_pace - io_gbqt_tab(ln_ship_idx).shipping_pace;
              ln_surpluses_quantity := ln_surpluses_quantity
                                     + LEAST(GREATEST(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0)
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--                                           , GREATEST(ln_adjust_quantity, 0)
                                           , GREATEST(l_ship_lot_tab(ln_ship_idx).lot_quantity, 0)
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
                                       );
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_START
              END IF;
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_END
            END IF;
          END LOOP ship_proc_adjust_loop;
--
          --�ړ���q�ɂ̉ߕs�����͈����݌ɐ��{��[�\��
          ln_total_lot_quantity := ln_total_lot_quantity + ln_lot_supplies_quantity;
          --��[�\���Ɉړ����q�ɂ̗]�萔�����Z
          ln_lot_supplies_quantity := ln_lot_supplies_quantity + ln_surpluses_quantity;
          <<rcpt_proc_adjust_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v��Ώۃt���O
            IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_START
              IF (ln_total_shipping_pace > 0) THEN
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_END
              --���v�Z
              ln_div_quantity := CEIL(ln_total_lot_quantity
                                    * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                    / ln_total_shipping_pace
                                 );
              --�ߕs�����̌v�Z
              ln_adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity - ln_div_quantity;
              --�Â����b�g�̉ߕs���������Z
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := GREATEST(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
--                                                                    + ln_adjust_quantity
--                                                                    , l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
--                                                                    - io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
--                                                             );
              l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                                                           + ln_adjust_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
              --�ĕ��݌ɐ������Z
              ln_total_lot_quantity := ln_total_lot_quantity - ln_div_quantity;
              ln_total_shipping_pace := ln_total_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
              IF (ln_lot_supplies_quantity > 0) THEN
                IF (l_xliv_rec.manufacture_date >= NVL(it_sy_manufacture_date, l_xliv_rec.manufacture_date)) THEN
                  --�ߕs�������}�C�i�X�̏ꍇ�A���b�g�o�����X�v�搔��ݒ�A��[�v�����ɉ��Z
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity < 0) THEN
--                    io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity * -1;
                  --�v�搔���v�Z
                  l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity :=
                    GREATEST(LEAST(l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity * -1
                                 , io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                 - l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
                             )
                           , 0
                    );
                  io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
                  ln_plan_lot_quantity := ln_plan_lot_quantity + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_START
--                  END IF;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_DEL_END
                END IF;
              END IF;
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_START
              END IF;
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_ADD_END
            END IF;
          END LOOP rcpt_proc_adjust_loop;
--
          --�f�o�b�N���b�Z�[�W�o��(��[�\���A�v�搔)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(2):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_plan_lot_quantity       || ','
          );
--
          --
          -- (3) �ߕs�������}�C�i�X�̑q�ɂŃ��b�g�v�搔���v�Z
          --
          IF (ln_lot_supplies_quantity > 0) THEN
            --�J�n�����N�����ȍ~�̃��b�g�Ōv�搔���v�Z
            IF (l_xliv_rec.manufacture_date >= NVL(it_sy_manufacture_date, l_xliv_rec.manufacture_date)) THEN
              --��[�\�������b�g�v�搔�̏ꍇ�A��[�\�����o�׃y�[�X�̔䗦�ň�
              <<rcpt_proc_division_loop>>
              WHILE (ln_lot_supplies_quantity < ln_plan_lot_quantity) LOOP
                ln_supplies_quantity := ln_lot_supplies_quantity;
                ln_plan_lot_quantity := 0;
                ln_require_quantity  := 0;
                ln_require_shipping_pace := 0;
                <<rcpt_proc_div_loop>>
                FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                  --�v��Ώۃt���O
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    --���b�g�v�搔��0���傫���ꍇ
                    IF (io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity > 0) THEN
                      --��[�v�������v
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--                      ln_require_quantity := ln_require_quantity + l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                      ln_require_quantity := ln_require_quantity - l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
                      --�o�׃y�[�X���v
                      ln_require_shipping_pace := ln_require_shipping_pace + io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                    END IF;
                  END IF;
                END LOOP rcpt_proc_div_loop;
                --�o�׃y�[�X�̔䗦�Ōv�惍�b�g�Ɉ�
                <<rcpt_proc_balance_loop>>
                FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
                  --�v��Ώۃt���O
                  IF (l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag = cv_planning_yes) THEN
                    --���b�g�v�搔��0���傫���ꍇ
                    IF (io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity > 0) THEN
                      --���b�g�v�搔�̌v�Z
                      io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity :=
                        GREATEST(CEIL((ln_supplies_quantity + ln_require_quantity)
                                     * io_xwypo_tab(ln_rcpt_idx).shipping_pace
                                     / ln_require_shipping_pace
                                 )
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--                               - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                               + l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
                               , 0
                        );
                      --�����������b�g�݌ɐ������Z
                      ln_supplies_quantity := ln_supplies_quantity - io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--                      ln_require_quantity  := ln_require_quantity  - l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity;
                      ln_require_quantity  := ln_require_quantity  + l_rcpt_lot_tab(ln_rcpt_idx).plan_lot_quantity;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
                      ln_require_shipping_pace := ln_require_shipping_pace - io_xwypo_tab(ln_rcpt_idx).shipping_pace;
                      ln_plan_lot_quantity := ln_plan_lot_quantity + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
                    END IF;
                  END IF;
                END LOOP rcpt_proc_balance_loop;
              END LOOP rcpt_proc_division_loop;
            END IF;
          END IF;
--
          --�f�o�b�N���b�Z�[�W�o��(��[�\���A�v�搔)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'proc_lot_balance(3):'
                            || ln_lot_supplies_quantity   || ','
                            || ln_plan_lot_quantity       || ','
                            || ln_supplies_quantity       || ','
          );
--
          --
          -- (4) ���b�g�v�搔�̊m��
          --
          <<ship_commit_loop>>
          FOR ln_ship_idx IN io_gbqt_tab.FIRST .. io_gbqt_tab.LAST LOOP
            --�N�x�����ʃ��b�g�݌ɐ��̌v�搔���v�Z
            ln_supplies_quantity := LEAST(GREATEST(l_ship_lot_tab(ln_ship_idx).lot_quantity   , 0)
                                        , GREATEST(l_ship_lot_tab(ln_ship_idx).adjust_quantity, 0)
                                        , GREATEST(ln_plan_lot_quantity                       , 0)
                                    );
            --�ړ����q�ɂ̉ߕs�������猸�Z�����݌ɐ����v�搔���v���猸�Z
            ln_plan_lot_quantity := ln_plan_lot_quantity - ln_supplies_quantity;
            --�ߕs���������Z
            l_ship_lot_tab(ln_ship_idx).adjust_quantity := l_ship_lot_tab(ln_ship_idx).adjust_quantity
                                                         - ln_supplies_quantity;
            --�N�x�����ʃ��b�g�݌ɐ���N�x�����ʍ݌ɐ��ɉ��Z
            l_ship_lot_tab(ln_ship_idx).freshness_quantity := l_ship_lot_tab(ln_ship_idx).freshness_quantity
                                                            + l_ship_lot_tab(ln_ship_idx).lot_quantity
                                                            - ln_supplies_quantity;
--
            --�f�o�b�N���b�Z�[�W�o��(�ړ������b�g�݌�)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                              || 'proc_lot_stock(ship):'
                              || i_ship_rec.loct_code                                 || ','
                              || io_gbqt_tab(ln_ship_idx).freshness_condition         || ','
                              || NVL(l_ship_lot_tab(ln_ship_idx).lot_quantity, -999)  || ','
                              || l_ship_lot_tab(ln_ship_idx).freshness_quantity       || ','
                              || l_ship_lot_tab(ln_ship_idx).plan_bal_quantity        || ','
                              || l_ship_lot_tab(ln_ship_idx).adjust_quantity          || ','
                              || l_ship_lot_tab(ln_ship_idx).stock_proc_flag          || ','
                              || l_ship_lot_tab(ln_ship_idx).adjust_proc_flag         || ','
                              || ln_lot_supplies_quantity                             || ','
                              || ln_supplies_quantity                                 || ','
            );
--
            -- ===============================
            -- B-26�D���O���x���o��
            -- ===============================
            put_log_level(
               iv_log_level           => cv_log_level3
              ,id_receipt_date        => gd_planning_date
              ,iv_item_no             => i_item_rec.item_no
              ,iv_loct_code           => i_ship_rec.loct_code
              ,iv_freshness_condition => io_gbqt_tab(ln_ship_idx).freshness_condition
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_START
--              ,in_stock_quantity      => l_ship_lot_tab(ln_ship_idx).freshness_quantity
              ,in_stock_quantity      => l_ship_lot_tab(ln_ship_idx).lot_quantity
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_END
              ,in_shipping_pace       => io_gbqt_tab(ln_ship_idx).shipping_pace
              ,in_supplies_quantity   => ln_lot_supplies_quantity
              ,id_manufacture_date    => l_xliv_rec.manufacture_date
              ,ov_errbuf              => lv_errbuf
              ,ov_retcode             => lv_retcode
              ,ov_errmsg              => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
--
          END LOOP ship_commit_loop;
--
          <<rcpt_commit_loop>>
          FOR ln_rcpt_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --���b�g����ݒ�
            io_xwypo_tab(ln_rcpt_idx).before_lot_stock := l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
            io_xwypo_tab(ln_rcpt_idx).after_lot_stock  := io_xwypo_tab(ln_rcpt_idx).before_lot_stock
                                                        + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            io_xwypo_tab(ln_rcpt_idx).manufacture_date := l_xliv_rec.manufacture_date;
            io_xwypo_tab(ln_rcpt_idx).lot_status       := l_xliv_rec.lot_status;
            --���b�g�t�]�t���O��ݒ�
            IF (io_xwypo_tab(ln_rcpt_idx).latest_manufacture_date > io_xwypo_tab(ln_rcpt_idx).manufacture_date) THEN
              io_xwypo_tab(ln_rcpt_idx).lot_reverse_flag := cv_csv_mark;
            ELSE
              io_xwypo_tab(ln_rcpt_idx).lot_reverse_flag := NULL;
            END IF;
            --CSV�o�͑Ώۃt���O��ݒ�
            io_xwypo_tab(ln_rcpt_idx).output_flag := cv_output_off;
--
            --�����v��莝�݌Ƀe�[�u���o�^
            -- ===============================
            -- B-24�D�����v��莝�݌Ƀe�[�u���o�^(���b�g�v�搔)
            -- ===============================
            entry_xli_lot(
               i_xliv_rec                 => l_xliv_rec
              ,i_xwypo_rec                => io_xwypo_tab(ln_rcpt_idx)
              ,it_rcpt_loct_id            => i_rcpt_rec.loct_id
              ,ov_errbuf                  => lv_errbuf
              ,ov_retcode                 => lv_retcode
              ,ov_errmsg                  => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            --�����v��o�̓��[�N�e�[�u���o�^
            IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
              -- ===============================
              -- B-25�D�����v��o�̓��[�N�e�[�u���o�^
              -- ===============================
              entry_xwypo(
                 iv_supply_status           => cv_complete
                ,i_xwypo_rec                => io_xwypo_tab(ln_rcpt_idx)
                ,ov_errbuf                  => lv_errbuf
                ,ov_retcode                 => lv_retcode
                ,ov_errmsg                  => lv_errmsg
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_api_expt;
              END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
              --���ʉ����v��̏ꍇ
              IF (io_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
                ln_sy_stocked_quantity := NVL(ln_sy_stocked_quantity, io_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                        + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
                --���ʉ�������}�X�^�̈ړ������X�V
                --�N�x�����͏����Ɋ܂߂Ȃ�
                UPDATE xxcop_wk_yoko_planning xwyp
                SET    xwyp.sy_stocked_quantity = ln_sy_stocked_quantity
                WHERE xwyp.transaction_id       = gn_transaction_id
                  AND xwyp.request_id           = cn_request_id
                  AND xwyp.assignment_set_type  = cv_custom_plan
                  AND xwyp.shipping_date        = io_xwypo_tab(ln_rcpt_idx).shipping_date
                  AND xwyp.receipt_date         = io_xwypo_tab(ln_rcpt_idx).receipt_date
                  AND xwyp.item_id              = io_xwypo_tab(ln_rcpt_idx).item_id
                  AND xwyp.ship_loct_id         = io_xwypo_tab(ln_rcpt_idx).ship_loct_id
                  AND xwyp.rcpt_loct_id         = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                ;
              END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
            END IF;
            --�o�����X�v�搔�Ƀ��b�g�v�搔�����Z
            l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity
                                                           + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            --�ߕs���������Z
            l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity := l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity
                                                         + io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity;
            --�N�x�����ʃ��b�g�݌ɐ���N�x�����ʍ݌ɐ��ɉ��Z
            l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity := l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
                                                            + l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity;
--
            --�f�o�b�N���b�Z�[�W�o��(�ړ��惍�b�g�݌�)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                              || 'proc_lot_stock(rcpt):'
                              || io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code             || ','
                              || io_xwypo_tab(ln_rcpt_idx).freshness_condition        || ','
                              || NVL(l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity, -999)  || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity       || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity        || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).adjust_quantity          || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).stock_proc_flag          || ','
                              || l_rcpt_lot_tab(ln_rcpt_idx).adjust_proc_flag         || ','
                              || io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity          || ','
            );
            --���b�g�v�搔�Ƀ��b�g�ʌv�搔�̍��v��ݒ�
            io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := l_rcpt_lot_tab(ln_rcpt_idx).plan_bal_quantity;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
            IF (i_rcpt_rec.loct_id = io_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
              --�v�搔(�ő�)�܂ŕ�[�����N�x�������J�E���g
              IF (io_xwypo_tab(ln_rcpt_idx).plan_max_quantity = io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity) THEN
                ln_max_filled_count := ln_max_filled_count + 1;
              END IF;
              --�v�搔(�o�����X)�܂ŕ�[�����N�x�������J�E���g
              IF (io_xwypo_tab(ln_rcpt_idx).plan_bal_quantity = io_xwypo_tab(ln_rcpt_idx).plan_lot_quantity) THEN
                ln_bal_filled_count := ln_bal_filled_count + 1;
              END IF;
            END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
            -- ===============================
            -- B-26�D���O���x���o��
            -- ===============================
            put_log_level(
               iv_log_level           => cv_log_level2
              ,id_receipt_date        => gd_planning_date
              ,iv_item_no             => io_xwypo_tab(ln_rcpt_idx).item_no
              ,iv_loct_code           => io_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
              ,iv_freshness_condition => io_xwypo_tab(ln_rcpt_idx).freshness_condition
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_START
--              ,in_stock_quantity      => l_rcpt_lot_tab(ln_rcpt_idx).freshness_quantity
              ,in_stock_quantity      => l_rcpt_lot_tab(ln_rcpt_idx).lot_quantity
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_END
              ,in_shipping_pace       => io_xwypo_tab(ln_rcpt_idx).shipping_pace
              ,in_supplies_quantity   => '0'
              ,id_manufacture_date    => l_xliv_rec.manufacture_date
              ,ov_errbuf              => lv_errbuf
              ,ov_retcode             => lv_retcode
              ,ov_errmsg              => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
--
          END LOOP rcpt_commit_loop;
          --
          -- (5) ������
          --
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
          --�v�搔(�o�����X)�܂ŕ�[�����ꍇ�A���b�g�o�����X�̌v�Z���I��
          IF (io_gbqt_tab.COUNT = ln_bal_filled_count) THEN
            --�v�搔(�ő�)�܂ŕ�[�ł����ꍇ�A��[�X�e�[�^�X���v�抮���ɂ���
            IF (io_gbqt_tab.COUNT = ln_max_filled_count) THEN
              ov_stock_result := cv_complete;
            END IF;
            EXIT xliv_loop;
          END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
          ln_lot_count              := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
          ln_condition_count        := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
          ln_total_lot_quantity     := 0;
          ln_lot_supplies_quantity  := 0;
          ln_surpluses_quantity     := 0;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
          ln_max_filled_count       := 0;
          ln_bal_filled_count       := 0;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
        END IF;
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
        WHEN manufacture_skip_expt THEN
          ln_lot_count              := 0;
          ln_condition_count        := 0;
          ln_total_lot_quantity     := 0;
          ln_lot_supplies_quantity  := 0;
          ln_surpluses_quantity     := 0;
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
          ln_max_filled_count       := 0;
          ln_bal_filled_count       := 0;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
      END;
    END LOOP xliv_loop;
    CLOSE xliv_cur;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xliv_cur%ISOPEN) THEN
        CLOSE xliv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_lot_quantity;
--
  /********************************************************************************** 
   * Procedure Name   : proc_balance_quantity
   * Description      : �o�����X�v�搔�̌v�Z(B-19)
   ***********************************************************************************/
  PROCEDURE proc_balance_quantity(
    iv_assign_type   IN     VARCHAR2,       --   �����Z�b�g�敪
    i_item_rec       IN     g_item_rtype,   --   �i�ڏ�񃌃R�[�h�^
    i_ship_rec       IN     g_loct_rtype,   --   �ړ����q�Ƀ��R�[�h�^
    i_rcpt_rec       IN     g_loct_rtype,   --   �ړ���q�Ƀ��R�[�h�^
    i_gfqt_tab       IN     g_fq_ttype,     --   �N�x�����ʍ݌Ɉ����R���N�V�����^
    o_gbqt_tab       OUT    g_bq_ttype,     --   �o�����X�����v��R���N�V�����^
    o_xwypo_tab      OUT    g_xwypo_ttype,  --   �����v��o�̓��[�N�e�[�u���R���N�V�����^
    ov_stock_result  OUT    VARCHAR2,       --   �o�����X�v�搔�̈����X�e�[�^�X
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_balance_quantity'; -- �v���O������
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
    ln_rcpt_stock_quantity    NUMBER;         --�ړ���q�ɂ̑N�x�����ʍ݌ɐ����v
    ln_rcpt_shipping_pace     NUMBER;         --�ړ���q�ɂ̑��o�׃y�[�X���v
    ln_supplies_quantity      NUMBER;         --��[�\��
    ln_balance_quantity       NUMBER;         --�ړ���q�ɂ̃o�����X�v�搔���v
    ln_balance_stock_days     NUMBER;         --�o�����X�݌ɓ���
    ln_rcpt_count             NUMBER;
    ln_rcpt_idx               NUMBER;
    ln_plan_bal_quantity      NUMBER;         --�v�搔�̍��v
    ln_max_fill               NUMBER;         --�ő�݌ɐ��𖞂������N�x�����̃J�E���g
    ln_ship_idx               NUMBER;         --�ړ����q�ɂ̑N�x����
--
    -- *** ���[�J���E�J�[�\�� ***
    --�N�x�����w��ňړ���q�ɏ����擾
    CURSOR rcpt_xwyp_cur(
       id_shipping_date       DATE
      ,in_ship_loct_id        NUMBER
      ,in_item_id             NUMBER
      ,iv_freshness_condition VARCHAR2
    ) IS
      SELECT xwyp.transaction_id                              transaction_id
            ,xwyp.shipping_date                               shipping_date
            ,xwyp.receipt_date                                receipt_date
            ,xwyp.ship_loct_id                                ship_loct_id
            ,xwyp.ship_loct_code                              ship_loct_code
            ,xwyp.ship_loct_name                              ship_loct_name
            ,xwyp.rcpt_loct_id                                rcpt_loct_id
            ,xwyp.rcpt_loct_code                              rcpt_loct_code
            ,xwyp.rcpt_loct_name                              rcpt_loct_name
            ,xwyp.item_id                                     item_id
            ,xwyp.item_no                                     item_no
            ,xwyp.item_name                                   item_name
            ,xwyp.freshness_priority                          freshness_priority
            ,xwyp.freshness_condition                         freshness_condition
            ,xwyp.freshness_class                             freshness_class
            ,xwyp.freshness_check_value                       freshness_check_value
            ,xwyp.freshness_adjust_value                      freshness_adjust_value
            ,xwyp.num_of_case                                 num_of_case
            ,xwyp.palette_max_cs_qty                          palette_max_cs_qty
            ,xwyp.palette_max_step_qty                        palette_max_step_qty
            ,xwyp.delivery_unit                               delivery_unit
            ,xwyp.safety_stock_days                           safety_stock_days
            ,xwyp.max_stock_days                              max_stock_days
            ,xwyp.shipping_type                               shipping_type
            ,CASE
               WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                 xwyp.total_shipping_pace
               WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                 xwyp.total_forecast_pace
               ELSE
                 0
             END                                              shipping_pace
            ,xwyp.assignment_set_type                         assignment_set_type
            ,xwyp.sy_manufacture_date                         sy_manufacture_date
            ,xwyp.sy_effective_date                           sy_effective_date
            ,xwyp.sy_disable_date                             sy_disable_date
            ,xwyp.sy_maxmum_quantity                          sy_maxmum_quantity
            ,xwyp.sy_stocked_quantity                         sy_stocked_quantity
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
            ,xwyp.crowd_class_code                            crowd_class_code
            ,xwyp.expiration_day                              expiration_day
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
            ,xwyp.created_by                                  created_by
            ,xwyp.creation_date                               creation_date
            ,xwyp.last_updated_by                             last_updated_by
            ,xwyp.last_update_date                            last_update_date
            ,xwyp.last_update_login                           last_update_login
            ,xwyp.request_id                                  request_id
            ,xwyp.program_application_id                      program_application_id
            ,xwyp.program_id                                  program_id
            ,xwyp.program_update_date                         program_update_date
            ,xwyp.rowid                                       xwyp_rowid
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id      = gn_transaction_id
        AND xwyp.request_id          = cn_request_id
        AND xwyp.shipping_date       = id_shipping_date
        AND xwyp.assignment_set_type = iv_assign_type
        AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
        AND xwyp.ship_loct_id        = in_ship_loct_id
        AND xwyp.item_id             = in_item_id
        AND xwyp.freshness_condition = iv_freshness_condition
        AND CASE
              WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                xwyp.total_shipping_pace
              WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                xwyp.total_forecast_pace
              ELSE
                0
            END > 0
    ORDER BY xwyp.rcpt_loct_code
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_rowid_tab               g_rowid_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_rcpt_stock_quantity    := 0;
    ln_rcpt_shipping_pace     := 0;
    ln_supplies_quantity      := 0;
    ln_balance_quantity       := 0;
    ln_balance_stock_days     := 0;
    ln_rcpt_count             := 0;
    ln_rcpt_idx               := 0;
    ln_plan_bal_quantity      := 0;
    ln_max_fill               := 0;
    ln_ship_idx               := 1;
    l_rowid_tab.DELETE;
--
    ov_stock_result           := cv_failed;
--
    --�N�x�����̗D�揇�Ƀo�����X�v�Z���s��
    <<gfqt_loop>>
    FOR ln_gfqt_idx IN REVERSE i_gfqt_tab.FIRST .. i_gfqt_tab.LAST LOOP
      BEGIN
        --�N�x�����Ⴂ�Ń��[�J���ϐ��̏�����
        ln_rcpt_stock_quantity  := 0;   --�ړ���q�ɂ̑N�x�����ʍ݌ɐ����v
        ln_rcpt_shipping_pace   := 0;   --�ړ���q�ɂ̑��o�׃y�[�X���v
        ln_supplies_quantity    := 0;   --��[�\��
        ln_balance_quantity     := 0;   --�ړ���q�ɂ̃o�����X�v�搔���v
        ln_balance_stock_days   := 0;   --�o�����X�݌ɓ���
        ln_rcpt_count           := NVL(o_xwypo_tab.LAST, 0);
--
        --�f�o�b�N���b�Z�[�W�o��(�N�x����)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'freshness_condition:'
                          || '(' || ln_gfqt_idx || ')'                    || ','
                          || i_gfqt_tab(ln_gfqt_idx).freshness_condition  || ','
        );
--
        --�N�x�����w��ňړ����q�ɏ����擾
        BEGIN
          SELECT xwyp.freshness_condition                         freshness_condition
                ,xwyp.freshness_class                             freshness_class
                ,xwyp.freshness_check_value                       freshness_check_value
                ,xwyp.freshness_adjust_value                      freshness_adjust_value
                ,NULL                                             manufacture_date
                ,0                                                plan_bal_quantity
                ,0                                                before_stock
                ,0                                                after_stock
                ,xwyp.safety_stock_days                           safety_stock_days
                ,xwyp.max_stock_days                              max_stock_days
                ,xwyp.shipping_type                               shipping_type
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.forecast_pace
                   ELSE
                     0
                 END                                              shipping_pace
          INTO   o_gbqt_tab(ln_ship_idx)
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id       = gn_transaction_id
            AND xwyp.request_id           = cn_request_id
            AND xwyp.shipping_date        = i_ship_rec.target_date
            AND xwyp.assignment_set_type  = cv_base_plan
            AND xwyp.shipping_type        = NVL(gv_plan_type, xwyp.shipping_type)
            AND xwyp.rcpt_loct_id         = i_ship_rec.loct_id
            AND xwyp.item_id              = i_item_rec.item_id
            AND xwyp.freshness_condition  = i_gfqt_tab(ln_gfqt_idx).freshness_condition
            AND CASE
                  WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                    xwyp.shipping_pace
                  WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                    xwyp.forecast_pace
                  ELSE
                    0
                END > 0
            AND ROWNUM                    = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            o_gbqt_tab(ln_ship_idx).freshness_condition     := i_gfqt_tab(ln_gfqt_idx).freshness_condition;
            o_gbqt_tab(ln_ship_idx).freshness_class         := i_gfqt_tab(ln_gfqt_idx).freshness_class;
            o_gbqt_tab(ln_ship_idx).freshness_check_value   := i_gfqt_tab(ln_gfqt_idx).freshness_check_value;
            o_gbqt_tab(ln_ship_idx).freshness_adjust_value  := i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value;
            o_gbqt_tab(ln_ship_idx).manufacture_date        := NULL;
            o_gbqt_tab(ln_ship_idx).plan_bal_quantity       := 0;
            o_gbqt_tab(ln_ship_idx).before_stock            := 0;
            o_gbqt_tab(ln_ship_idx).after_stock             := 0;
            o_gbqt_tab(ln_ship_idx).safety_stock_days       := 0;
            o_gbqt_tab(ln_ship_idx).max_stock_days          := 0;
            o_gbqt_tab(ln_ship_idx).shipping_type           := NULL;
            o_gbqt_tab(ln_ship_idx).shipping_pace           := 0;
        END;
        --�ړ����q�ɂ̑N�x�����ʍ݌ɐ�
        SELECT MIN(xliv.manufacture_date)                     manufacture_date
              ,NVL(SUM(xliv.loct_onhand), 0)                  loct_onhand
              ,NVL(SUM(CASE
                         WHEN (xliv.manufacture_date >= NVL(i_gfqt_tab(ln_gfqt_idx).sy_manufacture_date
                                                          , xliv.manufacture_date))
                         THEN xliv.loct_onhand
                         ELSE 0
                       END)
                 , 0)                                         supplies_quantity
        INTO o_gbqt_tab(ln_ship_idx).manufacture_date
            ,o_gbqt_tab(ln_ship_idx).before_stock
            ,ln_supplies_quantity
        FROM (
          SELECT xliv.lot_id                                  lot_id
                ,xliv.lot_no                                  lot_no
                ,xliv.manufacture_date                        manufacture_date
                ,xliv.expiration_date                         expiration_date
                ,xliv.unique_sign                             unique_sign
                ,xliv.lot_status                              lot_status
                ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                                          loct_onhand
          FROM (
            SELECT /*+ LEADING(xwyl) */
                   xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,xli.loct_onhand                            unlimited_loct_onhand
                  ,CASE WHEN xli.schedule_date <= i_ship_rec.target_date
                     THEN xli.loct_onhand
                     ELSE 0
                   END                                        limited_loct_onhand
            FROM xxcop_loct_inv          xli
                ,xxcop_wk_yoko_locations xwyl
            WHERE xli.transaction_id      = gn_transaction_id
              AND xli.request_id          = cn_request_id
              AND xli.item_id             = xwyl.item_id
              AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--              AND xli.shipment_date      <= gd_allocated_date
              AND xli.shipment_date      <= GREATEST(gd_allocated_date, i_ship_rec.target_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
              AND xwyl.transaction_id     = gn_transaction_id
              AND xwyl.request_id         = cn_request_id
              AND xwyl.item_id            = i_item_rec.item_id
              AND xwyl.frq_loct_id        = i_ship_rec.loct_id
            UNION ALL
            SELECT xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,LEAST(xli.loct_onhand, 0)                  unlimited_loct_onhand
                  ,CASE WHEN xli.schedule_date <= i_ship_rec.target_date
                     THEN LEAST(xli.loct_onhand, 0)
                     ELSE 0
                   END                                        limited_loct_onhand
            FROM (
              SELECT /*+ LEADING(xwyl) */
                     xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,xli.schedule_date                        schedule_date
                    ,SUM(xli.loct_onhand)                     loct_onhand
              FROM xxcop_loct_inv          xli
                  ,xxcop_wk_yoko_locations xwyl
              WHERE xli.transaction_id      = gn_transaction_id
                AND xli.request_id          = cn_request_id
                AND xli.item_id             = xwyl.item_id
                AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--                AND xli.shipment_date      <= gd_allocated_date
                AND xli.shipment_date      <= GREATEST(gd_allocated_date, i_ship_rec.target_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
                AND xwyl.transaction_id     = gn_transaction_id
                AND xwyl.request_id         = cn_request_id
                AND xwyl.frq_loct_id       <> xwyl.loct_id
                AND xwyl.item_id            = i_item_rec.item_id
                AND xwyl.loct_id            = i_ship_rec.loct_id
              GROUP BY xli.lot_id
                      ,xli.lot_no
                      ,xli.manufacture_date
                      ,xli.expiration_date
                      ,xli.unique_sign
                      ,xli.lot_status
                      ,xli.schedule_date
            ) xli
          ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
        ) xliv
        WHERE xxcop_common_pkg2.get_critical_date_f(
                 i_gfqt_tab(ln_gfqt_idx).freshness_class
                ,i_gfqt_tab(ln_gfqt_idx).freshness_check_value
                ,i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
                ,o_gbqt_tab(ln_ship_idx).max_stock_days
                ,gn_freshness_buffer_days
                ,xliv.manufacture_date
                ,xliv.expiration_date
              ) >= i_ship_rec.target_date
        ;
--
        --�f�o�b�N���b�Z�[�W�o��(�ړ����q�ɂ̍݌ɐ�)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                          || 'ship_loct_code:'
                          || '(' || ln_gfqt_idx || ')'                    || ','
                          || i_ship_rec.loct_code                         || ','
                          || o_gbqt_tab(ln_ship_idx).before_stock         || ','
                          || o_gbqt_tab(ln_ship_idx).shipping_pace        || ','
                          || TO_CHAR(o_gbqt_tab(ln_ship_idx).manufacture_date, cv_date_format) || ','
                          || ln_supplies_quantity                         || ','
        );
--
        ln_rcpt_idx := ln_rcpt_count + 1;
        OPEN rcpt_xwyp_cur(i_ship_rec.target_date
                          ,i_ship_rec.loct_id
                          ,i_item_rec.item_id
                          ,i_gfqt_tab(ln_gfqt_idx).freshness_condition
        );
        <<rcpt_xwyp_loop>>
        LOOP
          --�N�x�����w��ňړ���q�ɏ����擾
          FETCH rcpt_xwyp_cur INTO o_xwypo_tab(ln_rcpt_idx).transaction_id
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_date
                                  ,o_xwypo_tab(ln_rcpt_idx).receipt_date
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_id
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_code
                                  ,o_xwypo_tab(ln_rcpt_idx).ship_loct_name
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
                                  ,o_xwypo_tab(ln_rcpt_idx).rcpt_loct_name
                                  ,o_xwypo_tab(ln_rcpt_idx).item_id
                                  ,o_xwypo_tab(ln_rcpt_idx).item_no
                                  ,o_xwypo_tab(ln_rcpt_idx).item_name
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_priority
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_condition
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_class
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_check_value
                                  ,o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
                                  ,o_xwypo_tab(ln_rcpt_idx).num_of_case
                                  ,o_xwypo_tab(ln_rcpt_idx).palette_max_cs_qty
                                  ,o_xwypo_tab(ln_rcpt_idx).palette_max_step_qty
                                  ,o_xwypo_tab(ln_rcpt_idx).delivery_unit
                                  ,o_xwypo_tab(ln_rcpt_idx).safety_stock_days
                                  ,o_xwypo_tab(ln_rcpt_idx).max_stock_days
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_type
                                  ,o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                  ,o_xwypo_tab(ln_rcpt_idx).assignment_set_type
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_manufacture_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_effective_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_disable_date
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                  ,o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
                                  ,o_xwypo_tab(ln_rcpt_idx).crowd_class_code
                                  ,o_xwypo_tab(ln_rcpt_idx).expiration_day
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
                                  ,o_xwypo_tab(ln_rcpt_idx).created_by
                                  ,o_xwypo_tab(ln_rcpt_idx).creation_date
                                  ,o_xwypo_tab(ln_rcpt_idx).last_updated_by
                                  ,o_xwypo_tab(ln_rcpt_idx).last_update_date
                                  ,o_xwypo_tab(ln_rcpt_idx).last_update_login
                                  ,o_xwypo_tab(ln_rcpt_idx).request_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_application_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_id
                                  ,o_xwypo_tab(ln_rcpt_idx).program_update_date
                                  ,l_rowid_tab(ln_rcpt_idx)
          ;
          EXIT WHEN rcpt_xwyp_cur%NOTFOUND;
          --���S�݌ɐ��̐ݒ�
          o_xwypo_tab(ln_rcpt_idx).safety_stock_quantity := o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          * o_xwypo_tab(ln_rcpt_idx).safety_stock_days;
          --�ő�݌ɐ��̐ݒ�
          o_xwypo_tab(ln_rcpt_idx).max_stock_quantity    := o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          * o_xwypo_tab(ln_rcpt_idx).max_stock_days;
--
          --�ړ���q�ɂ̑N�x�����ʍ݌ɐ�
          SELECT MIN(xliv.manufacture_date)                   manufacture_date
                ,NVL(SUM(xliv.loct_onhand), 0)                loct_onhand
          INTO o_xwypo_tab(ln_rcpt_idx).manufacture_date
              ,o_xwypo_tab(ln_rcpt_idx).before_stock
          FROM (
            SELECT xliv.lot_id                                lot_id
                  ,xliv.lot_no                                lot_no
                  ,xliv.manufacture_date                      manufacture_date
                  ,xliv.expiration_date                       expiration_date
                  ,xliv.unique_sign                           unique_sign
                  ,xliv.lot_status                            lot_status
                  ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                     ELSE SUM(xliv.limited_loct_onhand)
                   END                                        loct_onhand
            FROM (
              SELECT /*+ LEADING(xwyl) */
                     xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,xli.loct_onhand                          unlimited_loct_onhand
                    ,CASE WHEN xli.schedule_date <= o_xwypo_tab(ln_rcpt_idx).receipt_date
                       THEN xli.loct_onhand
                       ELSE 0
                     END                                      limited_loct_onhand
              FROM xxcop_loct_inv          xli
                  ,xxcop_wk_yoko_locations xwyl
              WHERE xli.transaction_id      = gn_transaction_id
                AND xli.request_id          = cn_request_id
                AND xli.item_id             = xwyl.item_id
                AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--                AND xli.shipment_date      <= gd_allocated_date
                AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
                AND xwyl.transaction_id     = gn_transaction_id
                AND xwyl.request_id         = cn_request_id
                AND xwyl.item_id            = i_item_rec.item_id
                AND xwyl.frq_loct_id        = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
              UNION ALL
              SELECT xli.lot_id                               lot_id
                    ,xli.lot_no                               lot_no
                    ,xli.manufacture_date                     manufacture_date
                    ,xli.expiration_date                      expiration_date
                    ,xli.unique_sign                          unique_sign
                    ,xli.lot_status                           lot_status
                    ,LEAST(xli.loct_onhand, 0)                unlimited_loct_onhand
                    ,CASE WHEN xli.schedule_date <= o_xwypo_tab(ln_rcpt_idx).receipt_date
                       THEN LEAST(xli.loct_onhand, 0)
                       ELSE 0
                     END                                      limited_loct_onhand
              FROM (
                SELECT /*+ LEADING(xwyl) */
                       xli.lot_id                             lot_id
                      ,xli.lot_no                             lot_no
                      ,xli.manufacture_date                   manufacture_date
                      ,xli.expiration_date                    expiration_date
                      ,xli.unique_sign                        unique_sign
                      ,xli.lot_status                         lot_status
                      ,xli.schedule_date                      schedule_date
                      ,SUM(xli.loct_onhand)                   loct_onhand
                FROM xxcop_loct_inv          xli
                    ,xxcop_wk_yoko_locations xwyl
                WHERE xli.transaction_id      = gn_transaction_id
                  AND xli.request_id          = cn_request_id
                  AND xli.item_id             = xwyl.item_id
                  AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--                  AND xli.shipment_date      <= gd_allocated_date
                  AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
                  AND xwyl.transaction_id     = gn_transaction_id
                  AND xwyl.request_id         = cn_request_id
                  AND xwyl.frq_loct_id       <> xwyl.loct_id
                  AND xwyl.item_id            = i_item_rec.item_id
                  AND xwyl.loct_id            = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
                GROUP BY xli.lot_id
                        ,xli.lot_no
                        ,xli.manufacture_date
                        ,xli.expiration_date
                        ,xli.unique_sign
                        ,xli.lot_status
                        ,xli.schedule_date
              ) xli
            ) xliv
            GROUP BY xliv.lot_id
                    ,xliv.lot_no
                    ,xliv.manufacture_date
                    ,xliv.expiration_date
                    ,xliv.unique_sign
                    ,xliv.lot_status
          ) xliv
          WHERE xxcop_common_pkg2.get_critical_date_f(
                   i_gfqt_tab(ln_gfqt_idx).freshness_class
                  ,i_gfqt_tab(ln_gfqt_idx).freshness_check_value
                  ,i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
                  ,o_xwypo_tab(ln_rcpt_idx).max_stock_days
                  ,gn_freshness_buffer_days
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                ) >= o_xwypo_tab(ln_rcpt_idx).receipt_date
          ;
          --�����O�݌ɂ͍ő�݌ɐ������
          o_xwypo_tab(ln_rcpt_idx).before_stock := LEAST(o_xwypo_tab(ln_rcpt_idx).before_stock
                                                       , o_xwypo_tab(ln_rcpt_idx).max_stock_days
                                                       * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                   );
          --�ړ���q�ɂ̍ő吻���N�������擾
          SELECT MAX(xli.manufacture_date)                    manufacture_date
          INTO o_xwypo_tab(ln_rcpt_idx).latest_manufacture_date
          FROM xxcop_loct_inv          xli
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = i_item_rec.item_id
            AND xli.loct_id             = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, o_xwypo_tab(ln_rcpt_idx).receipt_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
            AND xli.schedule_date      <= o_xwypo_tab(ln_rcpt_idx).receipt_date
            AND xli.transaction_type   IN (cv_xli_type_inv)
          ;
--
          --���ʉ����v��̏ꍇ�A�ړ������擾
          IF (o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
            SELECT NVL(MAX(xwyp.sy_stocked_quantity), 0)      sy_allocated_quantity
            INTO o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
            FROM xxcop_wk_yoko_planning xwyp
            WHERE xwyp.transaction_id       = gn_transaction_id
              AND xwyp.request_id           = cn_request_id
              AND xwyp.planning_flag        = cv_planning_yes
              AND xwyp.assignment_set_type  = cv_custom_plan
              AND xwyp.rcpt_loct_id         = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
              AND xwyp.item_id              = i_item_rec.item_id
            ;
            --���ʉ����t���O��ݒ�
            o_xwypo_tab(ln_rcpt_idx).special_yoko_flag := cv_csv_mark;
          END IF;
--
          --�f�o�b�N���b�Z�[�W�o��(�ړ���q�ɂ̍݌ɐ�)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                            || 'rcpt_loct_code:'
                            || '(' || ln_gfqt_idx || '-' || ln_rcpt_idx || ')'  || ','
                            || o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code          || ','
                            || o_xwypo_tab(ln_rcpt_idx).before_stock            || ','
                            || o_xwypo_tab(ln_rcpt_idx).shipping_pace           || ','
                            || TO_CHAR(o_xwypo_tab(ln_rcpt_idx).manufacture_date, cv_date_format)  || ','
          );
--
          --�ړ���q�ɂ̑N�x�����ʍ݌ɐ����v
          ln_rcpt_stock_quantity := ln_rcpt_stock_quantity + o_xwypo_tab(ln_rcpt_idx).before_stock;
          --�ړ���q�ɂ̏o�׃y�[�X���v
          ln_rcpt_shipping_pace  := ln_rcpt_shipping_pace  + o_xwypo_tab(ln_rcpt_idx).shipping_pace;
          --�ړ���q�ɐ����J�E���g
          ln_rcpt_idx := ln_rcpt_idx + 1;
        END LOOP rcpt_xwyp_loop;
        CLOSE rcpt_xwyp_cur;
--
        --�o�����X�݌ɓ����̌v�Z(�N�x�����ʍ݌ɐ����v���o�׃y�[�X���v)
        ln_balance_stock_days := TRUNC((o_gbqt_tab(ln_ship_idx).before_stock  + ln_rcpt_stock_quantity)
                                     / (o_gbqt_tab(ln_ship_idx).shipping_pace + ln_rcpt_shipping_pace )
                                     , 2);
        --��[�\���̌v�Z
        ln_supplies_quantity := GREATEST(LEAST(FLOOR(o_gbqt_tab(ln_ship_idx).before_stock
                                                  - (ln_balance_stock_days * o_gbqt_tab(ln_ship_idx).shipping_pace)
                                               )
                                             , ln_supplies_quantity
                                         )
                                       , 0
                                );
--
        --�f�o�b�N���b�Z�[�W�o��(�o�����X�݌ɓ���)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'balance_proc:'
                          || ln_balance_stock_days    || ','
                          || ln_supplies_quantity     || ','
        );
--
        IF (ln_supplies_quantity <= 0) THEN
          --��[�\����0�ȉ��̂��߃o�����X�v�Z�͍s��Ȃ�
          RAISE short_supply_expt;
        END IF;
--
        <<balance_loop>>
        FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
          --�o�����X�v�搔�̌v�Z
          o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := GREATEST(
                                                          FLOOR(
                                                            LEAST(ln_balance_stock_days
                                                                , o_xwypo_tab(ln_rcpt_idx).max_stock_days)
                                                                * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                          ) - o_xwypo_tab(ln_rcpt_idx).before_stock
                                                        , 0
                                                        );
          --���ʉ����v��̏ꍇ�A�ݒ萔�����
          IF   ((o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan)
            AND (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity IS NOT NULL))
          THEN
            o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := LEAST(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                                             , (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                                              - o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                                          );
          END IF;
          --�o�����X�v�搔�̍��v
          ln_balance_quantity := ln_balance_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        END LOOP balance_loop;
--
        --��[�\�����o�����X�v�搔�ɖ����Ȃ��ꍇ�A�ړ���q�ɂ̏o�׃y�[�X�ň�
        IF ((ln_supplies_quantity < ln_balance_quantity ) AND ( ln_balance_quantity > 0)) THEN
          <<division_loop>>
          FOR ln_div_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
            --������
            ln_rcpt_stock_quantity := 0;
            ln_rcpt_shipping_pace  := 0;
            ln_balance_quantity    := 0;
            --���݌ɓ����̌v�Z
            <<div_proc_loop>>
            FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
              IF (o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > 0) THEN
                --�o�����X�v�搔��0�ȏ�̈ړ���q�ɂ̍݌ɐ����v
                ln_rcpt_stock_quantity := ln_rcpt_stock_quantity + o_xwypo_tab(ln_rcpt_idx).before_stock;
                --�o�����X�v�搔��0�ȏ�̏o�׃y�[�X���v
                ln_rcpt_shipping_pace := ln_rcpt_shipping_pace + o_xwypo_tab(ln_rcpt_idx).shipping_pace;
              END IF;
            END LOOP div_proc_loop;
            --���o�����X�݌ɓ����̌v�Z
            ln_balance_stock_days := TRUNC((ln_supplies_quantity + ln_rcpt_stock_quantity) / ln_rcpt_shipping_pace, 2);
            --���݌ɓ����Ńo�����X�v�搔���v�Z
            <<div_balance_loop>>
            FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
              IF (o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity > 0) THEN
                --�o�����X�v�搔�̌v�Z
                o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := GREATEST(
                                                                 FLOOR(ln_balance_stock_days
                                                                     * o_xwypo_tab(ln_rcpt_idx).shipping_pace
                                                                 )
                                                               - o_xwypo_tab(ln_rcpt_idx).before_stock
                                                               , 0
                                                              );
                --���ʉ����v��̏ꍇ�A�ݒ萔�����
                IF   ((o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan)
                  AND (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity IS NOT NULL))
                THEN
                  o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := LEAST(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
                                                                   , (o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity
                                                                    - o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity)
                                                                );
                END IF;
                --�o�����X�v�搔�̍��v
                ln_balance_quantity := ln_balance_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
              END IF;
            END LOOP div_balance_loop;
            IF (ln_supplies_quantity >= ln_balance_quantity) THEN
              EXIT division_loop;
            END IF;
          END LOOP division_loop;
        END IF;
--
      EXCEPTION
        WHEN short_supply_expt THEN
          NULL;
      END;
--
      <<entry_xli_loop>>
      FOR ln_rcpt_idx IN ln_rcpt_count + 1 .. o_xwypo_tab.LAST LOOP
        --��[�s�̏ꍇ�A�݌ɐ��A�v�搔��0���Z�b�g
        o_xwypo_tab(ln_rcpt_idx).manufacture_date  := NULL;
        o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity := NVL(o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity, 0);
        o_xwypo_tab(ln_rcpt_idx).plan_lot_quantity := NVL(o_xwypo_tab(ln_rcpt_idx).plan_lot_quantity, 0);
        o_xwypo_tab(ln_rcpt_idx).before_stock      := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_stock       := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).before_lot_stock  := NVL(o_xwypo_tab(ln_rcpt_idx).before_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_lot_stock   := NVL(o_xwypo_tab(ln_rcpt_idx).after_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).before_lot_stock  := NVL(o_xwypo_tab(ln_rcpt_idx).before_lot_stock, 0);
        o_xwypo_tab(ln_rcpt_idx).after_lot_stock   := NVL(o_xwypo_tab(ln_rcpt_idx).after_lot_stock, 0);
        --�o�����X�v�Z��̈ړ���q�ɂ̑N�x�����ʍ݌ɐ����v�Z
        o_xwypo_tab(ln_rcpt_idx).after_stock := o_xwypo_tab(ln_rcpt_idx).before_stock
                                              + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
--
        --�ړ���q�ɂőN�x�����Ɉ����Ă������O�݌ɐ��������v��莝�݌Ƀe�[�u���ɓo�^
        -- ===============================
        -- B-22�D�����v��莝�݌Ƀe�[�u���o�^(�o�����X�v�搔)
        -- ===============================
        entry_xli_balance(
           it_loct_id                 => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id
          ,it_loct_code               => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
          ,it_item_id                 => o_xwypo_tab(ln_rcpt_idx).item_id
          ,it_item_no                 => o_xwypo_tab(ln_rcpt_idx).item_no
          ,it_schedule_date           => o_xwypo_tab(ln_rcpt_idx).receipt_date
          ,it_schedule_quantity       => o_xwypo_tab(ln_rcpt_idx).before_stock
          ,it_freshness_class         => o_xwypo_tab(ln_rcpt_idx).freshness_class
          ,it_freshness_check_value   => o_xwypo_tab(ln_rcpt_idx).freshness_check_value
          ,it_freshness_adjust_value  => o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
          ,it_max_stock_days          => o_xwypo_tab(ln_rcpt_idx).max_stock_days
          ,it_sy_manufacture_date     => NULL
          ,ov_errbuf                  => lv_errbuf
          ,ov_retcode                 => lv_retcode
          ,ov_errmsg                  => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        --�ړ����q�ɂőN�x�����Ɉ����Ă��o�����X�v�搔�������v��莝�݌Ƀe�[�u���ɓo�^
        -- ===============================
        -- B-22�D�����v��莝�݌Ƀe�[�u���o�^(�o�����X�v�搔)
        -- ===============================
        entry_xli_balance(
           it_loct_id                 => o_xwypo_tab(ln_rcpt_idx).ship_loct_id
          ,it_loct_code               => o_xwypo_tab(ln_rcpt_idx).ship_loct_code
          ,it_item_id                 => o_xwypo_tab(ln_rcpt_idx).item_id
          ,it_item_no                 => o_xwypo_tab(ln_rcpt_idx).item_no
          ,it_schedule_date           => o_xwypo_tab(ln_rcpt_idx).shipping_date
          ,it_schedule_quantity       => o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
          ,it_freshness_class         => o_xwypo_tab(ln_rcpt_idx).freshness_class
          ,it_freshness_check_value   => o_xwypo_tab(ln_rcpt_idx).freshness_check_value
          ,it_freshness_adjust_value  => o_xwypo_tab(ln_rcpt_idx).freshness_adjust_value
          ,it_max_stock_days          => o_gbqt_tab(ln_ship_idx).max_stock_days
          ,it_sy_manufacture_date     => i_gfqt_tab(ln_gfqt_idx).sy_manufacture_date
          ,ov_errbuf                  => lv_errbuf
          ,ov_retcode                 => lv_retcode
          ,ov_errmsg                  => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --�v�搔�̍��v���W�v
        ln_plan_bal_quantity := ln_plan_bal_quantity + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        --�ړ����q�ɂ̌v�搔�Ɉړ���q�ɂ̌v�搔�����Z
        o_gbqt_tab(ln_ship_idx).plan_bal_quantity := o_gbqt_tab(ln_ship_idx).plan_bal_quantity
                                                   + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity;
        --�ő�݌ɐ��܂ň������ꂽ���m�F
        IF (i_rcpt_rec.loct_id = o_xwypo_tab(ln_rcpt_idx).rcpt_loct_id) THEN
          --�����O�݌Ɂ{�v�搔���ő�݌ɐ��̏ꍇ
          IF (o_xwypo_tab(ln_rcpt_idx).before_stock + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
            = o_xwypo_tab(ln_rcpt_idx).max_stock_days * o_xwypo_tab(ln_rcpt_idx).shipping_pace)
          THEN
            ln_max_fill := ln_max_fill + 1;
          END IF;
        END IF;
        --���ʉ����v��̏ꍇ�A�ړ������X�V
        IF (o_xwypo_tab(ln_rcpt_idx).assignment_set_type = cv_custom_plan) THEN
          UPDATE xxcop_wk_yoko_planning xwyp
          SET    xwyp.sy_stocked_quantity = o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity
                                          + o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
          WHERE xwyp.rowid                = l_rowid_tab(ln_rcpt_idx)
          ;
        END IF;
--
        --�f�o�b�N���b�Z�[�W�o��(������݌ɐ�)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                          || 'proc_balanced_stock(rcpt):'
                          || '(' || ln_gfqt_idx || '-' || ln_rcpt_idx || ')'  || ','
                          || o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code          || ','
                          || o_xwypo_tab(ln_rcpt_idx).before_stock            || ','
                          || o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity       || ','
                          || o_xwypo_tab(ln_rcpt_idx).after_stock             || ','
                          || o_xwypo_tab(ln_rcpt_idx).sy_stocked_quantity     || ','
                          || o_xwypo_tab(ln_rcpt_idx).sy_maxmum_quantity      || ','
        );
--
        -- ===============================
        -- B-26�D���O���x���o��
        -- ===============================
        put_log_level(
           iv_log_level           => cv_log_level1
          ,id_receipt_date        => gd_planning_date
          ,iv_item_no             => o_xwypo_tab(ln_rcpt_idx).item_no
          ,iv_loct_code           => o_xwypo_tab(ln_rcpt_idx).rcpt_loct_code
          ,iv_freshness_condition => o_xwypo_tab(ln_rcpt_idx).freshness_condition
          ,in_stock_quantity      => o_xwypo_tab(ln_rcpt_idx).before_stock
          ,in_shipping_pace       => o_xwypo_tab(ln_rcpt_idx).shipping_pace
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_START
--          ,in_supplies_quantity   => ln_supplies_quantity
          ,in_supplies_quantity   => o_xwypo_tab(ln_rcpt_idx).plan_bal_quantity
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_END
          ,id_manufacture_date    => NULL
          ,ov_errbuf              => lv_errbuf
          ,ov_retcode             => lv_retcode
          ,ov_errmsg              => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
      END LOOP entry_xli_loop;
      --�ړ����q�ɂ̉����O�݌ɁA������݌ɂ��v�Z
      o_gbqt_tab(ln_ship_idx).after_stock := LEAST(o_gbqt_tab(ln_ship_idx).before_stock
                                                 - o_gbqt_tab(ln_ship_idx).plan_bal_quantity
                                                 , o_gbqt_tab(ln_ship_idx).max_stock_days
                                                 * o_gbqt_tab(ln_ship_idx).shipping_pace
                                             );
      o_gbqt_tab(ln_ship_idx).before_stock := o_gbqt_tab(ln_ship_idx).after_stock
                                            + o_gbqt_tab(ln_ship_idx).plan_bal_quantity;
--
      --�ړ����q�ɂőN�x�����Ɉ����Ă��݌ɐ��������v��莝�݌Ƀe�[�u���ɓo�^
      -- ===============================
      -- B-22�D�����v��莝�݌Ƀe�[�u���o�^(�o�����X�v�搔)
      -- ===============================
      entry_xli_balance(
         it_loct_id                 => i_ship_rec.loct_id
        ,it_loct_code               => i_ship_rec.loct_code
        ,it_item_id                 => i_item_rec.item_id
        ,it_item_no                 => i_item_rec.item_no
        ,it_schedule_date           => i_ship_rec.target_date
        ,it_schedule_quantity       => o_gbqt_tab(ln_ship_idx).after_stock
        ,it_freshness_class         => i_gfqt_tab(ln_gfqt_idx).freshness_class
        ,it_freshness_check_value   => i_gfqt_tab(ln_gfqt_idx).freshness_check_value
        ,it_freshness_adjust_value  => i_gfqt_tab(ln_gfqt_idx).freshness_adjust_value
        ,it_max_stock_days          => o_gbqt_tab(ln_ship_idx).max_stock_days
        ,it_sy_manufacture_date     => NULL
        ,ov_errbuf                  => lv_errbuf
        ,ov_retcode                 => lv_retcode
        ,ov_errmsg                  => lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      --�f�o�b�N���b�Z�[�W�o��(������݌ɐ�)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_4 || cv_prg_name || ':'
                        || 'proc_balanced_stock(ship):'
                        || '(' || ln_gfqt_idx || ')'                    || ','
                        || i_ship_rec.loct_code                         || ','
                        || o_gbqt_tab(ln_ship_idx).before_stock         || ','
                        || o_gbqt_tab(ln_ship_idx).plan_bal_quantity    || ','
                        || o_gbqt_tab(ln_ship_idx).after_stock          || ','
      );
--
      -- ===============================
      -- B-26�D���O���x���o��
      -- ===============================
      put_log_level(
         iv_log_level           => cv_log_level1
        ,id_receipt_date        => gd_planning_date
        ,iv_item_no             => i_item_rec.item_no
        ,iv_loct_code           => i_ship_rec.loct_code
        ,iv_freshness_condition => i_gfqt_tab(ln_gfqt_idx).freshness_condition
        ,in_stock_quantity      => o_gbqt_tab(ln_ship_idx).before_stock
        ,in_shipping_pace       => o_gbqt_tab(ln_ship_idx).shipping_pace
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_START
--        ,in_supplies_quantity   => o_gbqt_tab(ln_ship_idx).plan_bal_quantity
        ,in_supplies_quantity   => ln_supplies_quantity
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_END
        ,id_manufacture_date    => NULL
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_others_expt;
      END IF;
--
      ln_ship_idx := ln_ship_idx + 1;
--
    END LOOP gfqt_loop;
    --�v�搔�̍��v��0�̏ꍇ�A�o�����X�v�搔�̈������ʂ��x���ɂ���
    IF (o_gbqt_tab.COUNT = ln_max_fill) THEN
      ov_stock_result := cv_complete;
    ELSIF (ln_plan_bal_quantity > 0) THEN
      ov_stock_result := cv_incomplete;
    ELSE
      ov_stock_result := cv_failed;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (rcpt_xwyp_cur%ISOPEN) THEN
        CLOSE rcpt_xwyp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_balance_quantity;
--
  /********************************************************************************** 
   * Procedure Name   : proc_ship_loct
   * Description      : �ړ����q�ɂ̓���(B-18)
   ***********************************************************************************/
  PROCEDURE proc_ship_loct(
    i_item_rec       IN     g_item_rtype,   --   �i�ڃ��R�[�h�^
    i_ship_tab       IN     g_loct_ttype,   --   �ړ����q�ɃR���N�V�����^
    i_gfqt_tab       IN     g_fq_ttype,     --   �N�x�����ʍ݌Ɉ����R���N�V�����^
    o_git_tab        OUT    g_idx_ttype,    --   �ړ����q�ɗD�揇�ʃR���N�V�����^
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ship_loct'; -- �v���O������
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
    ld_critical_date          DATE;         --�N�x�������
    ln_glpt_idx               NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɂ̎擾
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
      ,id_target_date         DATE
      ,id_manufacture_date    DATE
    ) IS
      SELECT xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,NVL(SUM(xliv.loct_onhand), 0)                    loct_onhand
      FROM (
        SELECT xliv.lot_id                                    lot_id
              ,xliv.lot_no                                    lot_no
              ,xliv.manufacture_date                          manufacture_date
              ,xliv.expiration_date                           expiration_date
              ,xliv.unique_sign                               unique_sign
              ,xliv.lot_status                                lot_status
              ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                 THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END                                            loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl)*/
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.loct_onhand                              unlimited_loct_onhand
                ,CASE WHEN xli.schedule_date <= id_target_date
                   THEN xli.loct_onhand
                   ELSE 0
                 END                                          limited_loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, id_target_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.frq_loct_id        = in_loct_id
          UNION ALL
          SELECT xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,LEAST(xli.loct_onhand, 0)                    unlimited_loct_onhand
                ,CASE WHEN xli.schedule_date <= id_target_date
                   THEN LEAST(xli.loct_onhand, 0)
                   ELSE 0
                 END                                          limited_loct_onhand
          FROM (
            SELECT /*+ LEADING(xwyl)*/
                   xli.lot_id                                 lot_id
                  ,xli.lot_no                                 lot_no
                  ,xli.manufacture_date                       manufacture_date
                  ,xli.expiration_date                        expiration_date
                  ,xli.unique_sign                            unique_sign
                  ,xli.lot_status                             lot_status
                  ,xli.schedule_date                          schedule_date
                  ,SUM(xli.loct_onhand)                       loct_onhand
            FROM xxcop_loct_inv          xli
                ,xxcop_wk_yoko_locations xwyl
            WHERE xli.transaction_id      = gn_transaction_id
              AND xli.request_id          = cn_request_id
              AND xli.item_id             = xwyl.item_id
              AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--              AND xli.shipment_date      <= gd_allocated_date
              AND xli.shipment_date      <= GREATEST(gd_allocated_date, id_target_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
              AND xli.transaction_type  NOT IN (cv_xli_type_bq)
              AND xwyl.transaction_id     = gn_transaction_id
              AND xwyl.request_id         = cn_request_id
              AND xwyl.frq_loct_id       <> xwyl.loct_id
              AND xwyl.item_id            = in_item_id
              AND xwyl.loct_id            = in_loct_id
            GROUP BY xli.lot_id
                    ,xli.lot_no
                    ,xli.manufacture_date
                    ,xli.expiration_date
                    ,xli.unique_sign
                    ,xli.lot_status
                    ,xli.schedule_date
          ) xli
        ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
      ) xliv
      WHERE xliv.manufacture_date >= NVL(id_manufacture_date, xliv.manufacture_date)
      GROUP BY xliv.manufacture_date
              ,xliv.expiration_date
      HAVING NVL(SUM(xliv.loct_onhand), 0) > 0
      ORDER BY xliv.manufacture_date
    ;
--
    -- *** ���[�J���E���R�[�h ***
    --�ړ����q�ɗD�揇��
    l_glpt_tab                g_lp_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ld_critical_date          := NULL;
    ln_glpt_idx               := 0;
    l_glpt_tab.DELETE;
--
    <<ship_loop>>
    FOR ln_ship_idx IN i_ship_tab.FIRST .. i_ship_tab.LAST LOOP
      --�ړ����q�ɂ̃��b�g�ʍ݌ɂ��擾
      <<xliv_loop>>
      FOR l_xliv_rec IN xliv_cur(i_item_rec.item_id
                               , i_ship_tab(ln_ship_idx).loct_id
                               , i_ship_tab(ln_ship_idx).target_date
                               , i_gfqt_tab(1).sy_manufacture_date
      ) LOOP
        --�ړ���q�ɂ̑N�x�����ɍ��v���邩����
        <<gsqt_loop>>
        FOR ln_gsqt_idx IN i_gfqt_tab.FIRST .. i_gfqt_tab.LAST LOOP
          --�N�x��������擾�֐�
          ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                 iv_freshness_class        => i_gfqt_tab(ln_gsqt_idx).freshness_class
                                ,in_freshness_check_value  => i_gfqt_tab(ln_gsqt_idx).freshness_check_value
                                ,in_freshness_adjust_value => i_gfqt_tab(ln_gsqt_idx).freshness_adjust_value
                                ,in_max_stock_days         => i_gfqt_tab(ln_gsqt_idx).max_stock_days
                                ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                ,id_expiration_date        => l_xliv_rec.expiration_date
                              );
          --�N�x�����ɍ��v�����ꍇ
          IF (i_ship_tab(ln_ship_idx).target_date <= ld_critical_date) THEN
            l_glpt_tab(ln_ship_idx).manufacture_date := l_xliv_rec.manufacture_date;
            IF (i_ship_tab(ln_ship_idx).shipping_pace = 0) THEN
              l_glpt_tab(ln_ship_idx).stock_days     := l_xliv_rec.loct_onhand;
            ELSE
              l_glpt_tab(ln_ship_idx).stock_days     := TRUNC(l_xliv_rec.loct_onhand
                                                            / i_ship_tab(ln_ship_idx).shipping_pace
                                                            , 2
                                                        );
            END IF;
            l_glpt_tab(ln_ship_idx).delivery_lead_time := i_ship_tab(ln_ship_idx).delivery_lead_time;
            EXIT xliv_loop;
          END IF;
        END LOOP gsqt_loop;
      END LOOP xliv_loop;
      IF (NOT l_glpt_tab.EXISTS(ln_ship_idx)) THEN
        l_glpt_tab(ln_ship_idx).manufacture_date   := cd_upper_limit_date;
        l_glpt_tab(ln_ship_idx).stock_days         := 0;
        l_glpt_tab(ln_ship_idx).delivery_lead_time := i_ship_tab(ln_ship_idx).delivery_lead_time;
      END IF;
    END LOOP ship_loop;
--
    --�ړ����q�ɂ̗D�揇�ʂ�����
    <<priority_loop>>
    FOR ln_priority_idx IN 1 .. l_glpt_tab.COUNT LOOP
      ln_glpt_idx                := l_glpt_tab.FIRST;
      o_git_tab(ln_priority_idx) := l_glpt_tab.FIRST;
      <<glpt_loop>>
      LOOP
        IF (ln_glpt_idx IS NULL) THEN
          EXIT glpt_loop;
        END IF;
        --���b�g�̐����N�����Ŕ���
        CASE
          WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).manufacture_date
              > l_glpt_tab(ln_glpt_idx).manufacture_date)
            THEN
              o_git_tab(ln_priority_idx)  := ln_glpt_idx;
          WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).manufacture_date
              = l_glpt_tab(ln_glpt_idx).manufacture_date)
            THEN
              --���b�g�̐����N�����������ꍇ�A�݌ɓ����Ŕ���
              CASE
                WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).stock_days
                    < l_glpt_tab(ln_glpt_idx).stock_days)
                  THEN
                    o_git_tab(ln_priority_idx)  := ln_glpt_idx;
                WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).stock_days
                    = l_glpt_tab(ln_glpt_idx).stock_days)
                  THEN
                    --�݌ɓ����������ꍇ�A�z�����[�h�^�C���Ŕ���
                    CASE
                      WHEN (l_glpt_tab(o_git_tab(ln_priority_idx)).delivery_lead_time
                          > l_glpt_tab(ln_glpt_idx).delivery_lead_time)
                        THEN
                          o_git_tab(ln_priority_idx)  := ln_glpt_idx;
                        ELSE
                          NULL;
                    END CASE;
                ELSE
                  NULL;
              END CASE;
          ELSE
            NULL;
        END CASE;
        ln_glpt_idx := l_glpt_tab.NEXT(ln_glpt_idx);
      END LOOP glpt_loop;
      l_glpt_tab.DELETE(o_git_tab(ln_priority_idx));
    END LOOP priority_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END proc_ship_loct;
--
  /**********************************************************************************
   * Procedure Name   : proc_safety_quantity
   * Description      : ���S�݌ɂ̌v�Z(B-17)
   ***********************************************************************************/
  PROCEDURE proc_safety_quantity(
    iv_assign_type   IN     VARCHAR2,       --   �����Z�b�g�敪
    it_loct_id       IN     xxcop_wk_yoko_planning.rcpt_loct_id%TYPE,
    i_item_rec       IN     g_item_rtype,   --   �i�ڃ��R�[�h�^
    io_gfqt_tab      IN OUT g_fq_ttype,     --   �N�x�����ʍ݌Ɉ����R���N�V�����^
    ov_stock_result  OUT    VARCHAR2,       --   ���S�݌ɂ̈����X�e�[�^�X
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_safety_quantity'; -- �v���O������
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
    ld_critical_date          DATE;         --�N�x�������
    ln_allocate_quantity      NUMBER;       --������
    ln_safety_fill            NUMBER;       --���S�݌ɐ��𖞂������N�x�����̃J�E���g
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--    ln_max_fill               NUMBER;       --�ő�݌ɐ��𖞂������N�x�����̃J�E���g
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
    ln_exists                 NUMBER;
    ln_stock_quantity         NUMBER;       --�����݌ɐ����v
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɂ̎擾
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                      lot_id
            ,xliv.lot_no                                      lot_no
            ,xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,xliv.unique_sign                                 unique_sign
            ,xliv.lot_status                                  lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                              loct_onhand
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,xli.loct_onhand                                unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= gd_planning_date
                 THEN xli.loct_onhand
                 ELSE 0
               END                                            limited_loct_onhand
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--          AND xli.shipment_date      <= gd_allocated_date
          AND xli.shipment_date      <= GREATEST(gd_allocated_date, gd_planning_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,LEAST(xli.loct_onhand, 0)                      unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= gd_planning_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                            limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.schedule_date                            schedule_date
                ,SUM(xli.loct_onhand)                         loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--            AND xli.shipment_date      <= gd_allocated_date
            AND xli.shipment_date      <= GREATEST(gd_allocated_date, gd_planning_date)
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
    ;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --���[�J���ϐ��̏�����
    ld_critical_date          := NULL;
    ln_allocate_quantity      := NULL;
    ln_safety_fill            := NULL;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--    ln_max_fill               := NULL;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
    ln_exists                 := NULL;
    ln_stock_quantity         := 0;
--
    ov_stock_result           := cv_shortage;
--
    --���ʉ����v�悩�ړ������ݒ萔�ȏ�̏ꍇ�A�v��𗧂ĂȂ�
    IF (iv_assign_type = cv_custom_plan) THEN
      SELECT COUNT(*)
      INTO ln_exists
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id       = gn_transaction_id
        AND xwyp.request_id           = cn_request_id
        AND xwyp.planning_flag        = cv_planning_yes
        AND xwyp.assignment_set_type  = cv_custom_plan
        AND xwyp.rcpt_loct_id         = it_loct_id
        AND xwyp.item_id              = i_item_rec.item_id
        AND xwyp.sy_maxmum_quantity  IS NOT NULL
        AND xwyp.sy_maxmum_quantity  <= xwyp.sy_stocked_quantity
      ;
      IF (ln_exists > 0) THEN
        ov_stock_result := cv_enough;
        RETURN;
      END IF;
    END IF;
--
    --�莝�݌ɂ̎擾
    <<xliv_loop>>
    FOR l_xliv_rec IN xliv_cur(i_item_rec.item_id
                             , it_loct_id
    ) LOOP
      BEGIN
        --���b�g�݌ɐ���0�̏ꍇ�A�X�L�b�v
        IF (l_xliv_rec.loct_onhand = 0) THEN
          RAISE lot_skip_expt;
        END IF;
--
        --�f�o�b�N���b�Z�[�W�o��(���S�݌Ƀ��b�g)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'safety_stock_quantity(lot):'
                          || xliv_cur%ROWCOUNT || ','
                          || TO_CHAR(l_xliv_rec.manufacture_date, cv_date_format) || ','
                          || l_xliv_rec.unique_sign                               || ','
                          || TO_CHAR(l_xliv_rec.expiration_date , cv_date_format) || ','
                          || l_xliv_rec.loct_onhand                               || ','
        );
        ln_safety_fill := 0;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--        ln_max_fill    := 0;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
        --�D�揇�ʂ̒Ⴂ���ɑN�x�����ɍ��v���邩�`�F�b�N
        <<gsqt_loop>>
        FOR ln_gsqt_idx IN io_gfqt_tab.FIRST .. io_gfqt_tab.LAST LOOP
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--          --���������ő�݌ɐ���菬�����ꍇ�A�N�x�����ɍ��v���邩�`�F�b�N
--          IF (io_gfqt_tab(ln_gsqt_idx).max_stock_quantity > io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
          --�����������S�݌ɐ���菬�����ꍇ�A�N�x�����ɍ��v���邩�`�F�b�N
          IF (io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity > io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
            --�N�x��������擾�֐�
            ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                   iv_freshness_class        => io_gfqt_tab(ln_gsqt_idx).freshness_class
                                  ,in_freshness_check_value  => io_gfqt_tab(ln_gsqt_idx).freshness_check_value
                                  ,in_freshness_adjust_value => io_gfqt_tab(ln_gsqt_idx).freshness_adjust_value
                                  ,in_max_stock_days         => io_gfqt_tab(ln_gsqt_idx).max_stock_days
                                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                  ,id_expiration_date        => l_xliv_rec.expiration_date
                                );
            --�N�x�����ɍ��v�����ꍇ�A�N�x�����Ɉ���
            IF (gd_planning_date <= ld_critical_date) THEN
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--              --���������v�Z
--              ln_allocate_quantity := LEAST((io_gfqt_tab(ln_gsqt_idx).max_stock_quantity
--                                           - io_gfqt_tab(ln_gsqt_idx).allocate_quantity)
--                                           , l_xliv_rec.loct_onhand
--                                      );
              --���S�݌ɐ��܂ň��������v�Z
              ln_allocate_quantity := LEAST((io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity
                                           - io_gfqt_tab(ln_gsqt_idx).allocate_quantity)
                                           , l_xliv_rec.loct_onhand
                                      );
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
              io_gfqt_tab(ln_gsqt_idx).allocate_quantity := io_gfqt_tab(ln_gsqt_idx).allocate_quantity
                                                          + ln_allocate_quantity;
              l_xliv_rec.loct_onhand := l_xliv_rec.loct_onhand - ln_allocate_quantity;
              ln_stock_quantity      := ln_stock_quantity + ln_allocate_quantity;
            END IF;
          END IF;
          --���S�݌ɐ��ȏ�������ꂽ�ꍇ
          IF (io_gfqt_tab(ln_gsqt_idx).safety_stock_quantity <= io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
            ln_safety_fill := ln_safety_fill + 1;
          END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--          --�ő�݌ɐ��ȏ�������ꂽ�ꍇ
--          IF (io_gfqt_tab(ln_gsqt_idx).max_stock_quantity    <= io_gfqt_tab(ln_gsqt_idx).allocate_quantity) THEN
--            ln_max_fill := ln_max_fill + 1;
--          END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
          --������̃��b�g�݌ɐ���0�̏ꍇ�͎��̃��b�g
          IF (l_xliv_rec.loct_onhand = 0) THEN
            EXIT gsqt_loop;
          END IF;
        END LOOP gsqt_loop;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--        --�S�Ă̑N�x�����ōő�݌ɐ��܂ň��������ꍇ�A�I��
--        IF (io_gfqt_tab.COUNT = ln_max_fill) THEN
--          ov_stock_result := cv_enough;
--          EXIT xliv_loop;
--        END IF;
        --�S�Ă̑N�x�����ň��S�݌ɐ��܂ň��������ꍇ�A�I��
        IF (io_gfqt_tab.COUNT = ln_safety_fill) THEN
          ov_stock_result := cv_enough;
          EXIT xliv_loop;
        END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
      END;
    END LOOP xliv_loop;
    --���S�݌ɂ𖞂����Ă���ꍇ�A�����v����쐬���Ȃ�
    IF (io_gfqt_tab.COUNT = ln_safety_fill) THEN
      ov_stock_result := cv_enough;
    END IF;
    --�f�o�b�N���b�Z�[�W�o��(���S�݌�)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'safety_stock_quantity:'
                      || ln_safety_fill             || ','
                      || ln_stock_quantity          || ','
    );
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END proc_safety_quantity;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_shipment
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(�o�׃y�[�X)(B-16)
   ***********************************************************************************/
  PROCEDURE entry_xli_shipment(
    it_shipment_date IN     xxcop_loct_inv.schedule_date%TYPE,
    io_gsat_tab      IN OUT g_sa_ttype,     --   �o�׃y�[�X�݌Ɉ����R���N�V�����^
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_shipment'; -- �v���O������
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
    ld_critical_date          DATE;         --�N�x�������
    ln_allocate_quantity      NUMBER;       --������
    ln_alloc_fill             NUMBER;       --�ő�݌ɐ��𖞂������N�x�����̃J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
    --�݌ɂ̎擾
    CURSOR xliv_cur(
       in_item_id             NUMBER
      ,in_loct_id             NUMBER
    ) IS
      SELECT xliv.lot_id                                      lot_id
            ,xliv.lot_no                                      lot_no
            ,xliv.manufacture_date                            manufacture_date
            ,xliv.expiration_date                             expiration_date
            ,xliv.unique_sign                                 unique_sign
            ,xliv.lot_status                                  lot_status
            ,CASE WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
               THEN SUM(xliv.unlimited_loct_onhand)
               ELSE SUM(xliv.limited_loct_onhand)
             END                                              loct_onhand
      FROM (
        SELECT /*+ LEADING(xwyl) */
               xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,xli.loct_onhand                                unlimited_loct_onhand
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_MOD_START
--              ,CASE WHEN xli.schedule_date <= it_shipment_date
--                 THEN xli.loct_onhand
--                 ELSE 0
--               END                                            limited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_shipment_date AND xli.transaction_type NOT IN (cv_xli_type_lq)
                      THEN xli.loct_onhand
                    WHEN xli.schedule_date <  it_shipment_date AND xli.transaction_type IN (cv_xli_type_lq)
                      THEN xli.loct_onhand
                    ELSE 0
               END                                            limited_loct_onhand
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_MOD_END
        FROM xxcop_loct_inv          xli
            ,xxcop_wk_yoko_locations xwyl
        WHERE xli.transaction_id      = gn_transaction_id
          AND xli.request_id          = cn_request_id
          AND xli.item_id             = xwyl.item_id
          AND xli.loct_id             = xwyl.loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_START
--          AND xli.shipment_date      <= gd_allocated_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_END
          AND xli.transaction_type  NOT IN (cv_xli_type_bq)
          AND xwyl.transaction_id     = gn_transaction_id
          AND xwyl.request_id         = cn_request_id
          AND xwyl.item_id            = in_item_id
          AND xwyl.frq_loct_id        = in_loct_id
        UNION ALL
        SELECT xli.lot_id                                     lot_id
              ,xli.lot_no                                     lot_no
              ,xli.manufacture_date                           manufacture_date
              ,xli.expiration_date                            expiration_date
              ,xli.unique_sign                                unique_sign
              ,xli.lot_status                                 lot_status
              ,LEAST(xli.loct_onhand, 0)                      unlimited_loct_onhand
              ,CASE WHEN xli.schedule_date <= it_shipment_date
                 THEN LEAST(xli.loct_onhand, 0)
                 ELSE 0
               END                                            limited_loct_onhand
        FROM (
          SELECT /*+ LEADING(xwyl) */
                 xli.lot_id                                   lot_id
                ,xli.lot_no                                   lot_no
                ,xli.manufacture_date                         manufacture_date
                ,xli.expiration_date                          expiration_date
                ,xli.unique_sign                              unique_sign
                ,xli.lot_status                               lot_status
                ,xli.schedule_date                            schedule_date
                ,SUM(xli.loct_onhand)                         loct_onhand
          FROM xxcop_loct_inv          xli
              ,xxcop_wk_yoko_locations xwyl
          WHERE xli.transaction_id      = gn_transaction_id
            AND xli.request_id          = cn_request_id
            AND xli.item_id             = xwyl.item_id
            AND xli.loct_id             = xwyl.frq_loct_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_START
--            AND xli.shipment_date      <= gd_allocated_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_END
            AND xli.transaction_type  NOT IN (cv_xli_type_bq)
            AND xwyl.transaction_id     = gn_transaction_id
            AND xwyl.request_id         = cn_request_id
            AND xwyl.frq_loct_id       <> xwyl.loct_id
            AND xwyl.item_id            = in_item_id
            AND xwyl.loct_id            = in_loct_id
          GROUP BY xli.lot_id
                  ,xli.lot_no
                  ,xli.manufacture_date
                  ,xli.expiration_date
                  ,xli.unique_sign
                  ,xli.lot_status
                  ,xli.schedule_date
        ) xli
      ) xliv
      GROUP BY xliv.lot_id
              ,xliv.lot_no
              ,xliv.manufacture_date
              ,xliv.expiration_date
              ,xliv.unique_sign
              ,xliv.lot_status
      ORDER BY xliv.manufacture_date
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xli_rec                 xxcop_loct_inv%ROWTYPE;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ld_critical_date          := NULL;
    ln_allocate_quantity      := 0;
    ln_alloc_fill             := 0;
    l_xli_rec                 := NULL;
--
    --�v���Œ�l���o�̓��R�[�h�^�ɃZ�b�g
    l_xli_rec.transaction_id               := gn_transaction_id;
    l_xli_rec.created_by                   := cn_created_by;
    l_xli_rec.creation_date                := cd_creation_date;
    l_xli_rec.last_updated_by              := cn_last_updated_by;
    l_xli_rec.last_update_date             := cd_last_update_date;
    l_xli_rec.last_update_login            := cn_last_update_login;
    l_xli_rec.request_id                   := cn_request_id;
    l_xli_rec.program_application_id       := cn_program_application_id;
    l_xli_rec.program_id                   := cn_program_id;
    l_xli_rec.program_update_date          := cd_program_update_date;
--
    --�q�ɁA�i�ڂ��o�̓��R�[�h�^�ɃZ�b�g
    l_xli_rec.loct_id                      := io_gsat_tab(1).rcpt_loct_id;
    l_xli_rec.loct_code                    := io_gsat_tab(1).rcpt_loct_code;
    l_xli_rec.organization_id              := io_gsat_tab(1).rcpt_organization_id;
    l_xli_rec.organization_code            := io_gsat_tab(1).rcpt_organization_code;
    l_xli_rec.item_id                      := io_gsat_tab(1).item_id;
    l_xli_rec.item_no                      := io_gsat_tab(1).item_no;
    --�������̏�����
    <<init_loop>>
    FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
      io_gsat_tab(ln_gsat_idx).allocate_quantity := 0;
    END LOOP init_loop;
--
    --�݌ɂ��擾
    <<xliv_loop>>
    FOR l_xliv_rec IN xliv_cur(io_gsat_tab(1).item_id
                             , io_gsat_tab(1).rcpt_loct_id
    ) LOOP
      BEGIN
        --���b�g�݌ɐ���0�ȉ��̏ꍇ�A�X�L�b�v
        IF (l_xliv_rec.loct_onhand <= 0) THEN
          RAISE lot_skip_expt;
        END IF;
--
        ln_alloc_fill  := 0;
        --�ړ���q�ɂ̑N�x�����ɍ��v���邩����
        <<gsat_loop>>
        FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
          --���������o�׃y�[�X��菬�����ꍇ�A�N�x�����ɍ��v���邩�`�F�b�N
          IF (io_gsat_tab(ln_gsat_idx).shipping_pace > io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
            --�N�x��������擾�֐�
            ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                   iv_freshness_class        => io_gsat_tab(ln_gsat_idx).freshness_class
                                  ,in_freshness_check_value  => io_gsat_tab(ln_gsat_idx).freshness_check_value
                                  ,in_freshness_adjust_value => io_gsat_tab(ln_gsat_idx).freshness_adjust_value
                                  ,in_max_stock_days         => io_gsat_tab(ln_gsat_idx).max_stock_days
                                  ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                  ,id_manufacture_date       => l_xliv_rec.manufacture_date
                                  ,id_expiration_date        => l_xliv_rec.expiration_date
                                );
            --�N�x�����ɍ��v�����ꍇ�A�N�x�����Ɉ���
            IF (it_shipment_date <= ld_critical_date) THEN
              --���������v�Z
              ln_allocate_quantity := LEAST((io_gsat_tab(ln_gsat_idx).shipping_pace
                                           - io_gsat_tab(ln_gsat_idx).allocate_quantity)
                                          , l_xliv_rec.loct_onhand
                                      );
              io_gsat_tab(ln_gsat_idx).allocate_quantity := io_gsat_tab(ln_gsat_idx).allocate_quantity
                                                          + ln_allocate_quantity;
              l_xliv_rec.loct_onhand := l_xliv_rec.loct_onhand - ln_allocate_quantity;
              BEGIN
                --���b�g�����o�̓��R�[�h�^�ɃZ�b�g
                l_xli_rec.lot_id             := l_xliv_rec.lot_id;
                l_xli_rec.lot_no             := l_xliv_rec.lot_no;
                l_xli_rec.manufacture_date   := l_xliv_rec.manufacture_date;
                l_xli_rec.expiration_date    := l_xliv_rec.expiration_date;
                l_xli_rec.unique_sign        := l_xliv_rec.unique_sign;
                l_xli_rec.lot_status         := l_xliv_rec.lot_status;
                l_xli_rec.loct_onhand        := ln_allocate_quantity * -1;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--                l_xli_rec.schedule_date      := it_shipment_date;
--                l_xli_rec.shipment_date      := cd_lower_limit_date;
                l_xli_rec.schedule_date      := cd_lower_limit_date;
                l_xli_rec.shipment_date      := it_shipment_date;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
                l_xli_rec.transaction_type   := cv_xli_type_sp;
                --�o�׃y�[�X�������v��莝�݌Ƀe�[�u���ɓo�^
                INSERT INTO xxcop_loct_inv VALUES l_xli_rec;
              EXCEPTION
                WHEN OTHERS THEN
                  lv_errbuf := SQLERRM;
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00027
                                 ,iv_token_name1  => cv_msg_00027_token_1
                                 ,iv_token_value1 => cv_table_xli
                               );
                  RAISE global_api_expt;
              END;
            END IF;
          END IF;
          --�o�׃y�[�X�ȏ�������ꂽ���m�F
          IF (io_gsat_tab(ln_gsat_idx).shipping_pace <= io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
            ln_alloc_fill := ln_alloc_fill + 1;
          END IF;
          --������̃��b�g�݌ɐ���0�̏ꍇ�͎��̃��b�g
          IF (l_xliv_rec.loct_onhand = 0) THEN
            EXIT gsat_loop;
          END IF;
        END LOOP gsat_loop;
        --�S�Ă̑N�x�����ŏo�׃y�[�X�܂ň��������ꍇ�A�I��
        IF (io_gsat_tab.COUNT = ln_alloc_fill) THEN
          EXIT xliv_loop;
        END IF;
      EXCEPTION
        WHEN lot_skip_expt THEN
          NULL;
      END;
    END LOOP xliv_loop;
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_DEL_START
--    --���b�g�Ɉ����o���Ȃ��N�x����������ꍇ�A���b�g���Ȃ��ŉ����v��莝�݌Ƀe�[�u���ɓo�^
--    IF (io_gsat_tab.COUNT > ln_alloc_fill) THEN
--      --���b�g�����N���A
--      l_xli_rec.lot_id             := NULL;
--      l_xli_rec.lot_no             := NULL;
--      l_xli_rec.manufacture_date   := cd_upper_limit_date;
--      l_xli_rec.expiration_date    := NULL;
--      l_xli_rec.unique_sign        := NULL;
--      l_xli_rec.lot_status         := NULL;
----20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
----      l_xli_rec.schedule_date      := it_shipment_date;
----      l_xli_rec.shipment_date      := cd_lower_limit_date;
--      l_xli_rec.schedule_date      := cd_lower_limit_date;
--      l_xli_rec.shipment_date      := it_shipment_date;
----20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
--      l_xli_rec.transaction_type   := cv_xli_type_sp;
--      <<no_lot_loop>>
--      FOR ln_gsat_idx IN io_gsat_tab.FIRST .. io_gsat_tab.LAST LOOP
--        BEGIN
--          IF (io_gsat_tab(ln_gsat_idx).shipping_pace > io_gsat_tab(ln_gsat_idx).allocate_quantity) THEN
--            l_xli_rec.loct_onhand  := (io_gsat_tab(ln_gsat_idx).shipping_pace
--                                     - io_gsat_tab(ln_gsat_idx).allocate_quantity)
--                                     * -1;
--            INSERT INTO xxcop_loct_inv VALUES l_xli_rec;
--          END IF;
--        EXCEPTION
--          WHEN OTHERS THEN
--            lv_errbuf := SQLERRM;
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_msg_appl_cont
--                           ,iv_name         => cv_msg_00027
--                           ,iv_token_name1  => cv_msg_00027_token_1
--                           ,iv_token_value1 => cv_table_xli
--                         );
--            RAISE global_api_expt;
--        END;
--      END LOOP no_lot_loop;
--    END IF;
--20100210_Ver3.5_E_�{�ғ�_01560_SCS.Goto_DEL_END
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xli_shipment;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_po
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(�w���v��)(B-15)
   ***********************************************************************************/
  PROCEDURE entry_xli_po(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_po'; -- �v���O������
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
    ln_entry_xli              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�w���v��̎擾
    CURSOR msd_po_sched_cur IS
      SELECT msi.organization_id                              organization_id
            ,msi.inventory_item_id                            inventory_item_id
      FROM mrp_schedule_designators ms
          ,mrp_schedule_items       msi
      WHERE ms.attribute1           = cv_msd_po_sched
        AND msi.schedule_designator = ms.schedule_designator
        AND msi.organization_id     = ms.organization_id
        AND EXISTS(
              SELECT 'X'
              FROM mrp_schedule_dates msd
              WHERE msd.schedule_designator = ms.schedule_designator
                AND msd.organization_id     = ms.organization_id
                AND msd.inventory_item_id   = msi.inventory_item_id
                AND msd.schedule_level      = cn_schedule_level
            )
        AND EXISTS(
              SELECT 'X'
              FROM xxcop_wk_yoko_planning xwyp
              WHERE xwyp.transaction_id     = gn_transaction_id
                AND xwyp.request_id         = cn_request_id
                AND xwyp.planning_flag      = cv_planning_yes
                AND xwyp.inventory_item_id  = msi.inventory_item_id
            )
      GROUP BY msi.organization_id
              ,msi.inventory_item_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_entry_xli              := 0;
    l_xwyp_rec                := NULL;
--
    OPEN msd_po_sched_cur;
    <<msd_po_sched_loop>>
    LOOP
      BEGIN
        --�w���v��̎擾
        FETCH msd_po_sched_cur INTO l_xwyp_rec.rcpt_organization_id
                                   ,l_xwyp_rec.inventory_item_id
        ;
        EXIT WHEN msd_po_sched_cur%NOTFOUND;
          --�i�ڏ����擾
          xxcop_common_pkg2.get_item_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,in_inventory_item_id     => l_xwyp_rec.inventory_item_id
            ,on_item_id               => l_xwyp_rec.item_id
            ,ov_item_no               => l_xwyp_rec.item_no
            ,ov_item_name             => l_xwyp_rec.item_name
            ,on_num_of_case           => l_xwyp_rec.num_of_case
            ,on_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
            ,on_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --�i�ڏ�񂪎擾�ł��Ȃ��i�ڂ͑ΏۊO
          IF (lv_retcode = cv_status_error) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.inventory_item_id
                         );
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.item_no
                         );
            --�x�����������Z
            gn_warn_cnt := gn_warn_cnt + 1;
            --���O�Ɍx�����b�Z�[�W���o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff => lv_errmsg
            );
            RAISE outside_scope_expt;
          END IF;
          --���ɑq�ɏ����擾
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,ov_organization_code     => l_xwyp_rec.rcpt_organization_code
            ,ov_organization_name     => l_xwyp_rec.rcpt_organization_name
            ,on_loct_id               => l_xwyp_rec.rcpt_loct_id
            ,ov_loct_code             => l_xwyp_rec.rcpt_loct_code
            ,ov_loct_name             => l_xwyp_rec.rcpt_loct_name
            ,ov_calendar_code         => l_xwyp_rec.rcpt_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --���ɑq�ɏ�񂪎擾�ł��Ȃ��q�ɂ͑ΏۊO
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
--
          --�ŏI�w�����ȍ~�̍w���v����擾���A�����v��莝�݌Ƀe�[�u���ɓo�^
          INSERT INTO xxcop_loct_inv (
             transaction_id
            ,loct_id
            ,loct_code
            ,organization_id
            ,organization_code
            ,item_id
            ,item_no
            ,lot_id
            ,lot_no
            ,manufacture_date
            ,expiration_date
            ,unique_sign
            ,lot_status
            ,loct_onhand
            ,schedule_date
            ,shipment_date
            ,voucher_no
            ,transaction_type
            ,simulate_flag
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
          SELECT gn_transaction_id                            transaction_id
                ,l_xwyp_rec.rcpt_loct_id                      loct_id
                ,l_xwyp_rec.rcpt_loct_code                    loct_code
                ,l_xwyp_rec.rcpt_organization_id              organization_id
                ,l_xwyp_rec.rcpt_organization_code            organization_code
                ,l_xwyp_rec.item_id                           item_id
                ,l_xwyp_rec.item_no                           item_no
                ,NULL                                         lot_id
                ,NULL                                         lot_no
                ,CASE
                   WHEN msd.attribute6 = cv_manufacture THEN
                     NVL(TO_DATE(msd.attribute5, cv_date_format), msd.schedule_date)
                   WHEN msd.attribute6 = cv_purchase    THEN
                     NVL(TO_DATE(msd.attribute5, cv_date_format), cd_upper_limit_date)
                 END                                          manufacture_date
                ,NULL                                         expiration_date
                ,NULL                                         unique_sign
                ,NULL                                         lot_status
                ,TRUNC(SUM(msd.schedule_quantity) / l_xwyp_rec.num_of_case)
                                                              loct_onhand
                ,msd.schedule_date                            schedule_date
                ,cd_lower_limit_date                          shipment_date
                ,NULL                                         voucher_no
                ,cv_xli_type_po                               transaction_type
                ,NULL                                         simulate_flag
                ,cn_created_by                                created_by
                ,cd_creation_date                             creation_date
                ,cn_last_updated_by                           last_updated_by
                ,cd_last_update_date                          last_update_date
                ,cn_last_update_login                         last_update_login
                ,cn_request_id                                request_id
                ,cn_program_application_id                    program_application_id
                ,cn_program_id                                program_id
                ,cd_program_update_date                       program_update_date
          FROM mrp_schedule_designators ms
              ,mrp_schedule_items       msi
              ,mrp_schedule_dates       msd
          WHERE ms.attribute1           = cv_msd_po_sched
            AND msi.schedule_designator = ms.schedule_designator
            AND msi.organization_id     = ms.organization_id
            AND msd.schedule_designator = msi.schedule_designator
            AND msd.organization_id     = msi.organization_id
            AND msd.inventory_item_id   = msi.inventory_item_id
            AND msd.schedule_level      = cn_schedule_level
            AND msd.schedule_quantity   > 0
            AND msd.attribute6         IS NOT NULL
            AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
            AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
            AND xxcop_common_pkg2.get_last_purchase_date_f(
                   l_xwyp_rec.rcpt_loct_id
                  ,l_xwyp_rec.item_id
                ) < msd.schedule_date
          GROUP BY msd.schedule_date
                  ,msd.attribute6
                  ,msd.attribute5
          ;
          --�o�^�����J�E���g
          ln_entry_xli := ln_entry_xli + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN outside_scope_expt THEN
          NULL;
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00027
                         ,iv_token_name1  => cv_msg_00027_token_1
                         ,iv_token_value1 => cv_table_xli
                       );
          RAISE global_api_expt;
      END;
    END LOOP msd_po_sched_loop;
    CLOSE msd_po_sched_cur;
--
    --�f�o�b�N���b�Z�[�W�o��(�w���v��)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'entry_xli_po(COUNT):'
                      || ln_entry_xli
    );
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (msd_po_sched_cur%ISOPEN) THEN
        CLOSE msd_po_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END entry_xli_po;
--
  /**********************************************************************************
   * Procedure Name   : entry_xli_fs
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(�H��o�׌v��)(B-14)
   ***********************************************************************************/
  PROCEDURE entry_xli_fs(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xli_fs'; -- �v���O������
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
    ln_entry_xli              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�H��o�׌v��
    CURSOR msd_fs_sched_cur IS
      SELECT msd.organization_id                              rcpt_organization_id
            ,mp.organization_id                               ship_organization_id
            ,msd.inventory_item_id                            inventory_item_id
      FROM mrp_schedule_designators ms
          ,mrp_schedule_items       msi
          ,mrp_schedule_dates       msd
          ,mtl_parameters           mp
      WHERE ms.attribute1           = cv_msd_fs_sched
        AND msi.schedule_designator = ms.schedule_designator
        AND msi.organization_id     = ms.organization_id
        AND msd.schedule_designator = msi.schedule_designator
        AND msd.organization_id     = msi.organization_id
        AND msd.inventory_item_id   = msi.inventory_item_id
        AND msd.schedule_level      = cn_schedule_level
        AND mp.organization_code    = msd.attribute2
        AND EXISTS(
              SELECT 'X'
              FROM xxcop_wk_yoko_planning xwyp
              WHERE xwyp.transaction_id     = gn_transaction_id
                AND xwyp.request_id         = cn_request_id
                AND xwyp.planning_flag      = cv_planning_yes
                AND xwyp.inventory_item_id  = msi.inventory_item_id
            )
      GROUP BY msd.organization_id
              ,mp.organization_id
              ,msd.inventory_item_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_entry_xli              := 0;
    l_xwyp_rec                := NULL;
--
    OPEN msd_fs_sched_cur;
    <<msd_fs_sched_loop>>
    LOOP
      BEGIN
        --�H��o�׌v��̎擾
        FETCH msd_fs_sched_cur INTO l_xwyp_rec.rcpt_organization_id
                                   ,l_xwyp_rec.ship_organization_id
                                   ,l_xwyp_rec.inventory_item_id
        ;
        EXIT WHEN msd_fs_sched_cur%NOTFOUND;
          --�i�ڏ����擾
          xxcop_common_pkg2.get_item_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,in_inventory_item_id     => l_xwyp_rec.inventory_item_id
            ,on_item_id               => l_xwyp_rec.item_id
            ,ov_item_no               => l_xwyp_rec.item_no
            ,ov_item_name             => l_xwyp_rec.item_name
            ,on_num_of_case           => l_xwyp_rec.num_of_case
            ,on_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
            ,on_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --�i�ڏ�񂪎擾�ł��Ȃ��i�ڂ͑ΏۊO
          IF (lv_retcode = cv_status_error) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.inventory_item_id
                         );
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00049
                           ,iv_token_name1  => cv_msg_00049_token_1
                           ,iv_token_value1 => l_xwyp_rec.item_no
                         );
            --�x�����������Z
            gn_warn_cnt := gn_warn_cnt + 1;
            --���O�Ɍx�����b�Z�[�W���o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff => lv_errmsg
            );
            RAISE outside_scope_expt;
          END IF;
          --�ړ���q�ɏ����擾
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.rcpt_organization_id
            ,ov_organization_code     => l_xwyp_rec.rcpt_organization_code
            ,ov_organization_name     => l_xwyp_rec.rcpt_organization_name
            ,on_loct_id               => l_xwyp_rec.rcpt_loct_id
            ,ov_loct_code             => l_xwyp_rec.rcpt_loct_code
            ,ov_loct_name             => l_xwyp_rec.rcpt_loct_name
            ,ov_calendar_code         => l_xwyp_rec.rcpt_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --�ړ���q�ɏ�񂪎擾�ł��Ȃ��q�ɂ͑ΏۊO
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
          --�ړ����q�ɏ����擾
          xxcop_common_pkg2.get_loct_info(
             id_target_date           => gd_process_date
            ,in_organization_id       => l_xwyp_rec.ship_organization_id
            ,ov_organization_code     => l_xwyp_rec.ship_organization_code
            ,ov_organization_name     => l_xwyp_rec.ship_organization_name
            ,on_loct_id               => l_xwyp_rec.ship_loct_id
            ,ov_loct_code             => l_xwyp_rec.ship_loct_code
            ,ov_loct_name             => l_xwyp_rec.ship_loct_name
            ,ov_calendar_code         => l_xwyp_rec.ship_calendar_code
            ,ov_errbuf                => lv_errbuf
            ,ov_retcode               => lv_retcode
            ,ov_errmsg                => lv_errmsg
          );
          --�ړ����q�ɏ�񂪎擾�ł��Ȃ��q�ɂ͑ΏۊO
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE outside_scope_expt;
          END IF;
--
          --�ŏI���ɓ��ȍ~�̍H��o�׌v����擾���A�����v��莝�݌Ƀe�[�u���ɓo�^
          INSERT INTO xxcop_loct_inv (
             transaction_id
            ,loct_id
            ,loct_code
            ,organization_id
            ,organization_code
            ,item_id
            ,item_no
            ,lot_id
            ,lot_no
            ,manufacture_date
            ,expiration_date
            ,unique_sign
            ,lot_status
            ,loct_onhand
            ,schedule_date
            ,shipment_date
            ,voucher_no
            ,transaction_type
            ,simulate_flag
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
          SELECT gn_transaction_id                            transaction_id
                ,msdvv.loct_id                                loct_id
                ,msdvv.loct_code                              loct_code
                ,msdvv.organization_id                        organization_id
                ,msdvv.organization_code                      organization_code
                ,l_xwyp_rec.item_id                           item_id
                ,l_xwyp_rec.item_no                           item_no
                ,NULL                                         lot_id
                ,NULL                                         lot_no
                ,msdvv.manufacture_date                       manufacture_date
                ,NULL                                         expiration_date
                ,NULL                                         unique_sign
                ,NULL                                         lot_status
                ,TRUNC(SUM(msdvv.schedule_quantity) / l_xwyp_rec.num_of_case)
                                                              loct_onhand
                ,msdvv.schedule_date                          schedule_date
                ,cd_lower_limit_date                          shipment_date
                ,NULL                                         voucher_no
                ,cv_xli_type_fs                               transaction_type
                ,NULL                                         simulate_flag
                ,cn_created_by                                created_by
                ,cd_creation_date                             creation_date
                ,cn_last_updated_by                           last_updated_by
                ,cd_last_update_date                          last_update_date
                ,cn_last_update_login                         last_update_login
                ,cn_request_id                                request_id
                ,cn_program_application_id                    program_application_id
                ,cn_program_id                                program_id
                ,cd_program_update_date                       program_update_date
          FROM (
            SELECT l_xwyp_rec.rcpt_loct_id                    loct_id
                  ,l_xwyp_rec.rcpt_loct_code                  loct_code
                  ,l_xwyp_rec.rcpt_organization_id            organization_id
                  ,l_xwyp_rec.rcpt_organization_code          organization_code
                  ,msd.schedule_date                          schedule_date
                  ,msd.schedule_quantity                      schedule_quantity
                  ,NVL(TO_DATE(msd.attribute5, cv_date_format)
                     , TO_DATE(msd.attribute3, cv_date_format))
                                                              manufacture_date
            FROM mrp_schedule_designators ms
                ,mrp_schedule_items       msi
                ,mrp_schedule_dates       msd
            WHERE ms.attribute1           = cv_msd_fs_sched
              AND msi.schedule_designator = ms.schedule_designator
              AND msi.organization_id     = ms.organization_id
              AND msd.schedule_designator = msi.schedule_designator
              AND msd.organization_id     = msi.organization_id
              AND msd.inventory_item_id   = msi.inventory_item_id
              AND msd.schedule_level      = cn_schedule_level
              AND msd.schedule_quantity   > 0
              AND msd.attribute3         IS NOT NULL
              AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
              AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
              AND msd.attribute2          = l_xwyp_rec.ship_organization_code
              AND xxcop_common_pkg2.get_last_arrival_date_f(
                     l_xwyp_rec.rcpt_loct_id
                    ,l_xwyp_rec.ship_loct_id
                    ,l_xwyp_rec.item_id
                  ) < msd.schedule_date
            UNION ALL
            SELECT l_xwyp_rec.ship_loct_id                    loct_id
                  ,l_xwyp_rec.ship_loct_code                  loct_code
                  ,l_xwyp_rec.ship_organization_id            organization_id
                  ,l_xwyp_rec.ship_organization_code          organization_code
                  ,TO_DATE(msd.attribute3, cv_date_format)    schedule_date
                  ,msd.schedule_quantity * -1                 schedule_quantity
                  ,NVL(TO_DATE(msd.attribute5, cv_date_format)
                     , TO_DATE(msd.attribute3, cv_date_format))
                                                              manufacture_date
            FROM mrp_schedule_designators ms
                ,mrp_schedule_items       msi
                ,mrp_schedule_dates       msd
            WHERE ms.attribute1           = cv_msd_fs_sched
              AND msi.schedule_designator = ms.schedule_designator
              AND msi.organization_id     = ms.organization_id
              AND msd.schedule_designator = msi.schedule_designator
              AND msd.organization_id     = msi.organization_id
              AND msd.inventory_item_id   = msi.inventory_item_id
              AND msd.schedule_level      = cn_schedule_level
              AND msd.schedule_quantity   > 0
              AND msd.attribute3         IS NOT NULL
              AND msd.organization_id     = l_xwyp_rec.rcpt_organization_id
              AND msd.inventory_item_id   = l_xwyp_rec.inventory_item_id
              AND msd.attribute2          = l_xwyp_rec.ship_organization_code
              AND xxcop_common_pkg2.get_last_arrival_date_f(
                     l_xwyp_rec.rcpt_loct_id
                    ,l_xwyp_rec.ship_loct_id
                    ,l_xwyp_rec.item_id
                  ) < msd.schedule_date
          ) msdvv
          GROUP BY msdvv.loct_id
                  ,msdvv.loct_code
                  ,msdvv.organization_id
                  ,msdvv.organization_code
                  ,msdvv.manufacture_date
                  ,msdvv.schedule_date
          ;
          --�o�^�����J�E���g
          ln_entry_xli := ln_entry_xli + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN outside_scope_expt THEN
          NULL;
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00027
                         ,iv_token_name1  => cv_msg_00027_token_1
                         ,iv_token_value1 => cv_table_xli
                       );
          RAISE global_api_expt;
      END;
    END LOOP msd_fs_sched_loop;
    CLOSE msd_fs_sched_cur;
--
    --�f�o�b�N���b�Z�[�W�o��(�H��o�׌v��)
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                      || 'entry_xli_fs(COUNT):'
                      || ln_entry_xli
    );
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (msd_fs_sched_cur%ISOPEN) THEN
        CLOSE msd_fs_sched_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END entry_xli_fs;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwyp
   * Description      : �����v�敨�����[�N�e�[�u���o�^(B-13)
   ***********************************************************************************/
  PROCEDURE entry_xwyp(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    i_gfct_tab       IN     g_fc_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwyp'; -- �v���O������
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
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    l_xwyp_rec        := NULL;
--
    BEGIN
      --�v���Œ�l�̐ݒ�
      l_xwyp_rec                            := i_xwyp_rec;
      l_xwyp_rec.transaction_id             := gn_transaction_id;
      l_xwyp_rec.created_by                 := cn_created_by;
      l_xwyp_rec.creation_date              := cd_creation_date;
      l_xwyp_rec.last_updated_by            := cn_last_updated_by;
      l_xwyp_rec.last_update_date           := cd_last_update_date;
      l_xwyp_rec.last_update_login          := cn_last_update_login;
      l_xwyp_rec.request_id                 := cn_request_id;
      l_xwyp_rec.program_application_id     := cn_program_application_id;
      l_xwyp_rec.program_id                 := cn_program_id;
      l_xwyp_rec.program_update_date        := cd_program_update_date;
      <<condition_loop>>
      FOR ln_priority_idx IN i_gfct_tab.FIRST .. i_gfct_tab.LAST LOOP
        IF (i_gfct_tab(ln_priority_idx).freshness_condition IS NOT NULL) THEN
          l_xwyp_rec.freshness_priority     := ln_priority_idx;
          l_xwyp_rec.freshness_condition    := i_gfct_tab(ln_priority_idx).freshness_condition;
          l_xwyp_rec.freshness_class        := i_gfct_tab(ln_priority_idx).freshness_class;
          l_xwyp_rec.freshness_check_value  := i_gfct_tab(ln_priority_idx).freshness_check_value;
          l_xwyp_rec.freshness_adjust_value := i_gfct_tab(ln_priority_idx).freshness_adjust_value;
          l_xwyp_rec.safety_stock_days      := i_gfct_tab(ln_priority_idx).safety_stock_days;
          l_xwyp_rec.max_stock_days         := i_gfct_tab(ln_priority_idx).max_stock_days;
          --�����v�敨�����[�N�e�[�u���o�^
          INSERT INTO xxcop_wk_yoko_planning VALUES l_xwyp_rec;
        END IF;
      END LOOP condition_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyp
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xwyp;
--
  /**********************************************************************************
   * Procedure Name   : chk_freshness_cond
   * Description      : �N�x�����`�F�b�N(B-12)
   ***********************************************************************************/
  PROCEDURE chk_freshness_cond(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    io_gfct_tab      IN OUT g_fc_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_freshness_cond'; -- �v���O������
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
    ln_priority_idx           NUMBER;
    ln_condition_cnt          NUMBER;
    lv_item_name              VARCHAR2(100);
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    ln_priority_idx           := NULL;
    ln_condition_cnt          := 0;
    lv_item_name              := NULL;
--
    --�o�׌v��敪
    IF  ((i_xwyp_rec.shipping_type NOT IN (cv_plan_type_shipped, cv_plan_type_forecate))
      OR (i_xwyp_rec.shipping_type IS NULL ))
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00068
                     ,iv_token_name1  => cv_msg_00068_token_1
                     ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                     ,iv_token_name2  => cv_msg_00068_token_2
                     ,iv_token_value2 => i_xwyp_rec.item_no
                   );
      RAISE internal_api_expt;
    END IF;
--
    <<priority_loop>>
    FOR ln_priority_idx IN 1 .. io_gfct_tab.COUNT LOOP
      BEGIN
        --�N�x����
        IF (io_gfct_tab(ln_priority_idx).freshness_condition IS NOT NULL) THEN
          --�N�x�����R�[�h�`�F�b�N
          SELECT flv.attribute1                               freshness_class
                ,TO_NUMBER(flv.attribute2)                    freshness_check_value
                ,TO_NUMBER(flv.attribute3)                    freshness_adjust_value
          INTO io_gfct_tab(ln_priority_idx).freshness_class
              ,io_gfct_tab(ln_priority_idx).freshness_check_value
              ,io_gfct_tab(ln_priority_idx).freshness_adjust_value
          FROM fnd_lookup_values flv
          WHERE flv.lookup_type          = cv_flv_freshness_cond
            AND flv.lookup_code          = io_gfct_tab(ln_priority_idx).freshness_condition
            AND flv.language             = cv_lang
            AND flv.source_lang          = cv_lang
            AND flv.enabled_flag         = cv_enable
            AND gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND NVL(flv.end_date_active,   gd_process_date)
          ;
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
          --�݌ɓ��������l�����Z
          io_gfct_tab(ln_priority_idx).safety_stock_days := io_gfct_tab(ln_priority_idx).safety_stock_days
                                                          + gn_stock_adjust_value;
          io_gfct_tab(ln_priority_idx).max_stock_days    := io_gfct_tab(ln_priority_idx).max_stock_days
                                                          + gn_stock_adjust_value;
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
          --���S�݌ɓ���
          IF (NVL(io_gfct_tab(ln_priority_idx).safety_stock_days, -1) < 0) THEN
            lv_item_name := cv_msg_10041_value_1;
            RAISE stock_days_expt;
          END IF;
          --�ő�݌ɓ���
          IF (NVL(io_gfct_tab(ln_priority_idx).max_stock_days, -1) < 0) THEN
            lv_item_name := cv_msg_10041_value_2;
            RAISE stock_days_expt;
          END IF;
          ln_condition_cnt := ln_condition_cnt + 1;
          --�D�揇��
          io_gfct_tab(ln_priority_idx).freshness_priority := ln_condition_cnt;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10040
                         ,iv_token_name1  => cv_msg_10040_token_1
                         ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                         ,iv_token_name2  => cv_msg_10040_token_2
                         ,iv_token_value2 => i_xwyp_rec.item_no
                         ,iv_token_name3  => cv_msg_10040_token_3
                         ,iv_token_value3 => io_gfct_tab(ln_priority_idx).freshness_condition
                       );
          RAISE internal_api_expt;
        WHEN stock_days_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10041
                         ,iv_token_name1  => cv_msg_10041_token_1
                         ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                         ,iv_token_name2  => cv_msg_10041_token_2
                         ,iv_token_value2 => i_xwyp_rec.item_no
                         ,iv_token_name3  => cv_msg_10041_token_3
                         ,iv_token_value3 => io_gfct_tab(ln_priority_idx).freshness_condition
                         ,iv_token_name4  => cv_msg_10041_token_4
                         ,iv_token_value4 => lv_item_name
                       );
          RAISE internal_api_expt;
      END;
    END LOOP priority_loop;
--
    --�N�x�������o�^����Ă��Ȃ��ꍇ
    IF (ln_condition_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_10038
                     ,iv_token_name1  => cv_msg_10038_token_1
                     ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                     ,iv_token_name2  => cv_msg_10038_token_2
                     ,iv_token_value2 => i_xwyp_rec.item_no
                   );
      RAISE internal_api_expt;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END chk_freshness_cond;
--
  /**********************************************************************************
   * Procedure Name   : chk_effective_route
   * Description      : ���ʉ����v��L�����ԃ`�F�b�N(B-11)
   ***********************************************************************************/
  PROCEDURE chk_effective_route(
    i_xwyp_rec       IN     xxcop_wk_yoko_planning%ROWTYPE,
    ov_effective     OUT    VARCHAR2,       --   �L�����茋��
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_effective_route'; -- �v���O������
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    --������
    ov_effective := cv_status_normal;
--
    --�L������
    BEGIN
      --�L���J�n������
      IF (i_xwyp_rec.sy_effective_date IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_effective_date > i_xwyp_rec.receipt_date) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --�L���I��������
      IF (i_xwyp_rec.sy_disable_date IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_disable_date < i_xwyp_rec.receipt_date) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --�ݒ萔����
      IF (i_xwyp_rec.sy_maxmum_quantity IS NOT NULL) THEN
        IF (i_xwyp_rec.sy_maxmum_quantity <= NVL(i_xwyp_rec.sy_stocked_quantity, 0)) THEN
          RAISE obsolete_skip_expt;
        END IF;
      END IF;
--
      --�J�n�����N�����܂��͗L���J�n�����ݒ肳��Ă���
      IF ((i_xwyp_rec.sy_manufacture_date IS NULL) AND (i_xwyp_rec.sy_effective_date IS NULL)) THEN
        RAISE no_condition_expt;
      END IF;
--
      --���ʂ܂��͗L���I�������ݒ肳��Ă��邱��
      IF ((i_xwyp_rec.sy_maxmum_quantity IS NULL) AND (i_xwyp_rec.sy_disable_date IS NULL)) THEN
        RAISE no_condition_expt;
      END IF;
--
    EXCEPTION
      WHEN obsolete_skip_expt THEN
        ov_effective := cv_status_warn;
      WHEN no_condition_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10039
                       ,iv_token_name1  => cv_msg_10039_token_1
                       ,iv_token_value1 => i_xwyp_rec.rcpt_organization_code
                       ,iv_token_name2  => cv_msg_10039_token_2
                       ,iv_token_value2 => i_xwyp_rec.item_no
                     );
        RAISE internal_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END chk_effective_route;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
    ,ov_errbuf              OUT    VARCHAR2                 --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT    VARCHAR2                 --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT    VARCHAR2                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lb_chk_value              BOOLEAN;         -- ���t�^�t�H�[�}�b�g�`�F�b�N����
    lv_chk_parameter          VARCHAR2(100);   -- �`�F�b�N���ږ�
    lv_chk_date_from          VARCHAR2(100);   -- �͈̓`�F�b�N���ږ�(FROM)
    lv_chk_date_to            VARCHAR2(100);   -- �͈̓`�F�b�N���ږ�(TO)
    lv_value                  VARCHAR2(100);   -- �v���t�@�C���l
    lv_profile_name           VARCHAR2(100);   -- ���[�U�v���t�@�C����
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    --������
    lb_chk_value              := NULL;
    lv_chk_parameter          := NULL;
    lv_chk_date_from          := NULL;
    lv_chk_date_to            := NULL;
    lv_value                  := NULL;
    lv_profile_name           := NULL;
--
    -- ===============================
    -- ���̓p�����[�^�̏o��
    -- ===============================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_appl_cont
                   ,iv_name         => cv_msg_10045
                   ,iv_token_name1  => cv_msg_10045_token_1
                   ,iv_token_value1 => iv_planning_date_from
                   ,iv_token_name2  => cv_msg_10045_token_2
                   ,iv_token_value2 => iv_planning_date_to
                   ,iv_token_name3  => cv_msg_10045_token_3
                   ,iv_token_value3 => iv_plan_type
                   ,iv_token_name4  => cv_msg_10045_token_4
                   ,iv_token_value4 => iv_shipment_date_from
                   ,iv_token_name5  => cv_msg_10045_token_5
                   ,iv_token_value5 => iv_shipment_date_to
                   ,iv_token_name6  => cv_msg_10045_token_6
                   ,iv_token_value6 => iv_forecast_date_from
                   ,iv_token_name7  => cv_msg_10045_token_7
                   ,iv_token_value7 => iv_forecast_date_to
                   ,iv_token_name8  => cv_msg_10045_token_8
                   ,iv_token_value8 => iv_allocated_date
                   ,iv_token_name9  => cv_msg_10045_token_9
                   ,iv_token_value9 => iv_item_code
                 );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_appl_cont
                   ,iv_name         => cv_msg_10057
                   ,iv_token_name1  => cv_msg_10057_token_1
                   ,iv_token_value1 => iv_working_days
                   ,iv_token_name2  => cv_msg_10057_token_2
                   ,iv_token_value2 => iv_stock_adjust_value
                 );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ===============================
    -- �Ɩ����t�̎擾
    -- ===============================
    gd_process_date  :=  xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00065
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- ===============================
    -- �N���p�����[�^�`�F�b�N
    -- ===============================
    BEGIN
      -- ===============================
      -- �v�旧�Ċ���(FROM)
      -- ===============================
      lv_chk_parameter := cv_planning_date_from_tl;
      --�l��NULL�`�F�b�N
      IF (iv_planning_date_from IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE�^�`�F�b�N
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_planning_date_from
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_planning_date_from := TO_DATE(iv_planning_date_from, cv_date_format);
      --�ߋ����̏ꍇ�A�G���[
      IF (gd_process_date > gd_planning_date_from) THEN
        RAISE prior_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- �v�旧�Ċ���(TO)
      -- ===============================
      lv_chk_parameter := cv_planning_date_to_tl;
      --�l��NULL�`�F�b�N
      IF (iv_planning_date_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE�^�`�F�b�N
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_planning_date_to
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_planning_date_to := TO_DATE(iv_planning_date_to, cv_date_format);
      --�ߋ����̏ꍇ�A�G���[
      IF (gd_process_date > gd_planning_date_to) THEN
        RAISE prior_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- �v�旧�Ċ���(FROM-TO)�t�]�`�F�b�N
      -- ===============================
      IF (gd_planning_date_from > gd_planning_date_to) THEN
        lv_chk_date_from := cv_planning_date_from_tl;
        lv_chk_date_to   := cv_planning_date_to_tl;
        RAISE date_reverse_expt;
      END IF;
--
      -- ===============================
      -- �o�׌v��敪
      -- ===============================
      lv_chk_parameter := cv_plan_type_tl;
      --�l�̑Ó����`�F�b�N
      IF (iv_plan_type NOT IN (cv_plan_type_shipped, cv_plan_type_forecate)) THEN
        RAISE param_invalid_expt;
      END IF;
      gv_plan_type := iv_plan_type;
--
      -- ===============================
      -- �o�׃y�[�X�v�����(FROM)
      -- ===============================
      lv_chk_parameter := cv_shipment_date_from_tl;
      --�l��NULL�`�F�b�N
      IF (iv_shipment_date_from IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE�^�`�F�b�N
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_date_from
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_date_from := TO_DATE(iv_shipment_date_from, cv_date_format);
      -- �������̏ꍇ�A�G���[
      IF (gd_shipment_date_from > gd_process_date) THEN
        RAISE past_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- �o�׃y�[�X�v�����(TO)
      -- ===============================
      lv_chk_parameter := cv_shipment_date_to_tl;
      --�l��NULL�`�F�b�N
      IF (iv_shipment_date_to IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE�^�`�F�b�N
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_date_to
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_date_to := TO_DATE(iv_shipment_date_to, cv_date_format);
      -- �������̏ꍇ�G���[
      IF (gd_shipment_date_to > gd_process_date) THEN
        RAISE past_date_invalid_expt;
      END IF;
--
      -- ===============================
      -- �o�׃y�[�X�v�����(FROM-TO)�t�]�`�F�b�N
      -- ===============================
      IF (gd_shipment_date_from > gd_shipment_date_to) THEN
        lv_chk_date_from := cv_shipment_date_from_tl;
        lv_chk_date_to   := cv_shipment_date_to_tl;
        RAISE date_reverse_expt;
      END IF;
--
      --�o�׌v��敪���o�ח\���̏ꍇ�A�`�F�b�N����
      IF (NVL(iv_plan_type, cv_plan_type_forecate) = cv_plan_type_forecate) THEN
        -- ===============================
        -- �o�ח\������(FROM)
        -- ===============================
        lv_chk_parameter := cv_forecast_date_from_tl;
        --�l��NULL�`�F�b�N
        IF (iv_forecast_date_from IS NULL) THEN
          RAISE param_invalid_expt;
        END IF;
        --DATE�^�`�F�b�N
        lb_chk_value := xxcop_common_pkg.chk_date_format(
                           iv_value       => iv_forecast_date_from
                          ,iv_format      => cv_date_format
                        );
        IF (NOT lb_chk_value) THEN
          RAISE date_invalid_expt;
        END IF;
        gd_forecast_date_from := TO_DATE(iv_forecast_date_from, cv_date_format);
--
        -- ===============================
        -- �o�ח\������(TO)
        -- ===============================
        lv_chk_parameter := cv_forecast_date_to_tl;
        --�l��NULL�`�F�b�N
        IF (iv_forecast_date_to IS NULL) THEN
          RAISE param_invalid_expt;
        END IF;
        --DATE�^�`�F�b�N
        lb_chk_value := xxcop_common_pkg.chk_date_format(
                           iv_value       => iv_forecast_date_to
                          ,iv_format      => cv_date_format
                        );
        IF (NOT lb_chk_value) THEN
          RAISE date_invalid_expt;
        END IF;
        gd_forecast_date_to := TO_DATE(iv_forecast_date_to, cv_date_format);
--
        -- ===============================
        -- �o�ח\������(FROM-TO)�t�]�`�F�b�N
        -- ===============================
        IF (gd_forecast_date_from > gd_forecast_date_to) THEN
          lv_chk_date_from := cv_forecast_date_from_tl;
          lv_chk_date_to   := cv_forecast_date_to_tl;
          RAISE date_reverse_expt;
        END IF;
      END IF;
--
      -- ===============================
      -- �o�׈����ϓ�
      -- ===============================
      lv_chk_parameter := cv_allocated_date_tl;
      --�l��NULL�`�F�b�N
      IF (iv_allocated_date IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --DATE�^�`�F�b�N
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_allocated_date
                        ,iv_format      => cv_date_format
                      );
      IF (NOT lb_chk_value) THEN
        RAISE date_invalid_expt;
      END IF;
      gd_allocated_date := TO_DATE(iv_allocated_date, cv_date_format);
--
      -- ===============================
      -- �i�ڃR�[�h
      -- ===============================
      lv_chk_parameter := cv_item_code_tl;
      --�l��NULL�`�F�b�N
      IF (iv_item_code IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      gv_item_code := iv_item_code;
--
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
      -- ===============================
      -- �ғ�����
      -- ===============================
      lv_chk_parameter := cv_working_days_tl;
      --�l��NULL�`�F�b�N
      IF (iv_working_days IS NULL) THEN
        RAISE param_invalid_expt;
      END IF;
      --���l�^�`�F�b�N
      BEGIN
        gn_working_days := TO_NUMBER(iv_working_days);
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
      IF (gn_working_days <= 0) THEN
        RAISE param_invalid_expt;
      END IF;
--
      -- ===============================
      -- �݌ɓ��������l
      -- ===============================
      lv_chk_parameter := cv_stock_adjust_value_tl;
      --���l�^�`�F�b�N
      BEGIN
        gn_stock_adjust_value := TO_NUMBER(NVL(iv_stock_adjust_value, 0));
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
--
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
    EXCEPTION
      WHEN param_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00055
                     );
        RAISE internal_api_expt;
      WHEN date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00011
                       ,iv_token_name1  => cv_msg_00011_token_1
                       ,iv_token_value1 => lv_chk_parameter
                     );
        RAISE internal_api_expt;
      WHEN past_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_00047
                        ,iv_token_name1  => cv_msg_00047_token_1
                        ,iv_token_value1 => lv_chk_parameter
                      );
        RAISE internal_api_expt;
      WHEN prior_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_10009
                        ,iv_token_name1  => cv_msg_10009_token_1
                        ,iv_token_value1 => lv_chk_parameter
                      );
        RAISE internal_api_expt;
      WHEN date_reverse_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00025
                       ,iv_token_name1  => cv_msg_00025_token_1
                       ,iv_token_value1 => lv_chk_date_from
                       ,iv_token_name2  => cv_msg_00025_token_2
                       ,iv_token_value2 => lv_chk_date_to
                     );
        RAISE internal_api_expt;
    END;
    -- ===============================
    -- �v���t�@�C���̎擾
    -- ===============================
    BEGIN
      --�}�X�^�g�D
      lv_profile_name := cv_pf_master_org_id;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_master_org_id := TO_NUMBER(lv_value);
--
      --�_�~�[�o�בg�D
      lv_profile_name := cv_pf_source_org_id;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      BEGIN
        SELECT mp.organization_id         organization_id
        INTO gn_source_org_id
        FROM mtl_parameters mp
        WHERE mp.organization_code = lv_value;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE profile_invalid_expt;
      END;
--
      --�N�x�����o�b�t�@����
      lv_profile_name := cv_pf_fresh_buffer_days;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_freshness_buffer_days := TO_NUMBER(lv_value);
--
      --�_�~�[��\�q��
      lv_profile_name := cv_pf_frq_loct_code;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gv_dummy_frequent_whse := lv_value;
--
      --�p�[�e�B�V������
      lv_profile_name := cv_pf_partition_num;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_partition_num := TO_NUMBER(lv_value);
--
      --�f�o�b�N���[�h
      lv_profile_name := cv_pf_debug_mode;
      gv_debug_mode := fnd_profile.value( lv_profile_name );
--
    EXCEPTION
      WHEN profile_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00002
                       ,iv_token_name1  => cv_msg_00002_token_1
                       ,iv_token_value1 => lv_profile_name
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- �g�����U�N�V����ID�̎擾
    -- ===============================
    gn_transaction_id := MOD(cn_request_id, gn_partition_num);
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_msr_route
   * Description      : �����v�搧��}�X�^�擾(B-2)
   ***********************************************************************************/
  PROCEDURE get_msr_route(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msr_route'; -- �v���O������
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
    ln_exists                 NUMBER;         --���݃`�F�b�N
    lv_effective              VARCHAR2(1);    --���ʉ����v��L������
    ln_work_day               NUMBER;         --�v�旧�ē��̉ғ����`�F�b�N
    ld_planning_date          DATE;           --�v�旧�ē�
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--    ln_planning_count         NUMBER;         --�v�旧�Čo�H�̃J�E���g
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
--
    -- *** ���[�J���E�J�[�\�� ***
--
    --�Ώەi�ڂ̎擾
    CURSOR item_cur(
       id_planning_date       DATE
    ) IS
      SELECT msib.inventory_item_id                           inventory_item_id           --�݌ɕi��ID
            ,iimb.item_id                                     item_id                     --OPM�i��ID
            ,iimb.item_no                                     item_no                     --�i�ڃR�[�h
            ,ximb.item_short_name                             item_name                   --�i�ږ���
            ,NVL(TO_NUMBER(iimb.attribute11), 1)              num_of_case                 --�P�[�X����
            ,NVL(DECODE(ximb.palette_max_cs_qty
                      , 0, 1
                      , ximb.palette_max_cs_qty
                 ), 1)                                        palette_max_cs_qty          --�z��
            ,NVL(DECODE(ximb.palette_max_step_qty
                      , 0, 1
                      , ximb.palette_max_step_qty
                 ), 1)                                        palette_max_step_qty        --�i��
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
            ,ximb.expiration_day                              expiration_day              --�ܖ�����
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
      FROM   ic_item_mst_b             iimb      --OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b          ximb      --OPM�i�ڃA�h�I���}�X�^
            ,mtl_system_items_b        msib      --DISC�i�ڃ}�X�^
      WHERE iimb.inactive_ind                = cn_iimb_status_active
        AND iimb.attribute18                 = cv_shipping_enable
        AND ximb.item_id                     = iimb.item_id
        AND ximb.obsolete_class              = cn_ximb_status_active
        AND id_planning_date           BETWEEN NVL(ximb.start_date_active, id_planning_date)
                                           AND NVL(ximb.end_date_active  , id_planning_date)
        AND msib.segment1                    = iimb.item_no
        AND msib.organization_id             = gn_master_org_id
        AND msib.segment1                    = gv_item_code
    ;
    --�o�H���̎擾
    CURSOR msr_cur(
       id_planning_date       DATE
      ,in_inventory_item_id   NUMBER
    ) IS
      WITH msr_vw AS (
        --�S�o�H(��{�����v��A���ʉ����v��A�������[���_�~�[�o�H�A�p�b�J�[�q�Ƀ_�~�[�o�H)
        SELECT mas.assignment_set_name                    assignment_set_name --�����Z�b�g��
              ,mas.attribute1                             assignment_set_type --�����Z�b�g�敪
              ,msa.assignment_type                            assignment_type --������^�C�v
              ,msa.organization_id                            organization_id --�g�D
              ,msa.inventory_item_id                        inventory_item_id --�i��
              ,msa.sourcing_rule_type                      sourcing_rule_type --�\�[�X���[���^�C�v
              ,msr.sourcing_rule_name                      sourcing_rule_name --�\�[�X���[����
              ,msso.source_organization_id             source_organization_id --�ړ����g�DID
              ,NVL(msro.receipt_organization_id, msa.organization_id)
                                                      receipt_organization_id --�ړ���g�DID
              ,msa.attribute1                                      attribute1 --
              ,msa.attribute2                                      attribute2 --
              ,msa.attribute3                                      attribute3 --
              ,msa.attribute4                                      attribute4 --
              ,msa.attribute5                                      attribute5 --
              ,msa.attribute6                                      attribute6 --
              ,msa.attribute7                                      attribute7 --
              ,msa.attribute8                                      attribute8 --
              ,msa.attribute9                                      attribute9 --
              ,msa.attribute10                                    attribute10 --
              ,msa.attribute11                                    attribute11 --
              ,msa.attribute12                                    attribute12 --
              ,msa.attribute13                                    attribute13 --
              ,flv2.description                          assign_type_priority --������^�C�v�D��x
              ,RANK () OVER (PARTITION BY NVL(msro.receipt_organization_id, msa.organization_id)
                                         ,msso.source_organization_id
                                         ,mas.attribute1
                             ORDER BY     flv2.description                    ASC
                                         ,msa.sourcing_rule_type              DESC
                                         ,mas.assignment_set_name             ASC
                       )                                       overlap_priority --�d���o�H�D�揇��
              ,RANK () OVER (PARTITION BY DECODE(msso.source_organization_id, gn_master_org_id, 1, 0)
                                         ,NVL(msro.receipt_organization_id, msa.organization_id)
                                         ,mas.attribute1
                             ORDER BY     flv2.description                    ASC
                                         ,msa.sourcing_rule_type              DESC
                                         ,mas.assignment_set_name             ASC
                                         ,msso.source_organization_id         DESC
                       )                               sourcing_rule_priority --�������[���D�揇��
        FROM mrp_assignment_sets    mas                 --�����Z�b�g
            ,mrp_sr_assignments     msa                 --�����Z�b�g����
            ,mrp_sourcing_rules     msr                 --�\�[�X���[��
            ,mrp_sr_receipt_org     msro                --�\�[�X���[������g�D
            ,mrp_sr_source_org      msso                --�\�[�X���[���o�בg�D
            ,fnd_lookup_values      flv1                --�Q�ƃ^�C�v(�����Z�b�g��)
            ,fnd_lookup_values      flv2                --�Q�ƃ^�C�v(������^�C�v�D��x)
        WHERE mas.attribute1             IN (cv_base_plan, cv_custom_plan)
          AND msa.assignment_set_id       = mas.assignment_set_id
          AND msr.sourcing_rule_id        = msa.sourcing_rule_id
          AND msro.sourcing_rule_id       = msr.sourcing_rule_id
          AND msso.sr_receipt_id          = msro.sr_receipt_id
          AND msso.source_type            = cn_location_source
          AND id_planning_date BETWEEN NVL(msro.effective_date, id_planning_date)
                                   AND NVL(msro.disable_date  , id_planning_date)
          AND flv1.lookup_type            = cv_flv_assignment_name
          AND flv1.lookup_code            = mas.assignment_set_name
          AND flv1.language               = cv_lang
          AND flv1.source_lang            = cv_lang
          AND flv1.enabled_flag           = cv_enable
          AND gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
          AND flv2.lookup_type            = cv_flv_assign_priority
          AND flv2.lookup_code            = msa.assignment_type
          AND flv2.language               = cv_lang
          AND flv2.source_lang            = cv_lang
          AND flv2.enabled_flag           = cv_enable
          AND gd_process_date BETWEEN NVL(flv2.start_date_active, gd_process_date)
                                  AND NVL(flv2.end_date_active  , gd_process_date)
          AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
      )
      , msr_base_vw AS (
        --��{�����v��
        SELECT msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
              ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
              ,msrv.assignment_type                           assignment_type --������^�C�v
              ,msrv.organization_id                           organization_id --�g�D
              ,msrv.inventory_item_id                       inventory_item_id --�i��
              ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
              ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
              ,msrv.source_organization_id             source_organization_id --�ړ����g�DID
              ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN '1'
                   ELSE NULL
               END                                   sourcing_rule_dummy_flag --�������[���_�~�[FLAG
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute1)
                   ELSE TO_NUMBER(msv.attribute1)
               END                                              shipping_type --�o�׌v��敪
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute2
                   ELSE msv.attribute2
               END                                       freshness_condition1 --�N�x����1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute3)
                   ELSE TO_NUMBER(msv.attribute3)
               END                                         safety_stock_days1 --���S�݌ɓ���1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute4)
                   ELSE TO_NUMBER(msv.attribute4)
               END                                            max_stock_days1 --�ő�݌ɓ���1
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute5
                   ELSE msv.attribute5
               END                                       freshness_condition2 --�N�x����2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute6)
                   ELSE TO_NUMBER(msv.attribute6)
               END                                         safety_stock_days2 --���S�݌ɓ���2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute7)
                   ELSE TO_NUMBER(msv.attribute7)
               END                                            max_stock_days2 --�ő�݌ɓ���2
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute8
                   ELSE msv.attribute8
               END                                       freshness_condition3 --�N�x����3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute9)
                   ELSE TO_NUMBER(msv.attribute9)
               END                                         safety_stock_days3 --���S�݌ɓ���3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute10)
                   ELSE TO_NUMBER(msv.attribute10)
               END                                            max_stock_days3 --�ő�݌ɓ���3
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN mdv.attribute11
                   ELSE msv.attribute11
               END                                       freshness_condition4 --�N�x����4
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute12)
                   ELSE TO_NUMBER(msv.attribute12)
               END                                         safety_stock_days4 --���S�݌ɓ���4
              ,CASE
                 WHEN mdv.source_organization_id IS NOT NULL
                   THEN TO_NUMBER(mdv.attribute13)
                   ELSE TO_NUMBER(msv.attribute13)
               END                                            max_stock_days4 --�ő�݌ɓ���4
              ,msrv.overlap_priority                         overlap_priority --�d���o�H�D�揇��
              ,msrv.sourcing_rule_priority             sourcing_rule_priority --�������[���D�揇��
        FROM msr_vw msrv            --��{�����v��o�H
            ,msr_vw msv             --��{�����v�拟�����[��
            ,msr_vw mdv             --�������[���_�~�[�o�H
        WHERE msrv.assignment_set_type        IN (cv_base_plan)
          AND msrv.source_organization_id NOT IN (gn_master_org_id)
          AND msrv.overlap_priority            = 1
          AND msv.assignment_set_type         IN (cv_base_plan)
          AND msv.source_organization_id  NOT IN (gn_master_org_id)
          AND msv.sourcing_rule_priority       = 1
          AND msrv.receipt_organization_id     = msv.receipt_organization_id
          AND mdv.assignment_set_type(+)      IN (cv_base_plan)
          AND mdv.source_organization_id(+)   IN (gn_master_org_id)
          AND msv.sourcing_rule_priority(+)    = 1
          AND mdv.receipt_organization_id(+)   = msrv.receipt_organization_id
      )
      , msr_custom_vw AS (
        --���ʉ����v��
        SELECT
               msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
              ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
              ,msrv.assignment_type                           assignment_type --������^�C�v
              ,msrv.organization_id                           organization_id --�g�D
              ,msrv.inventory_item_id                       inventory_item_id --�i��
              ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
              ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
              ,msrv.source_organization_id             source_organization_id --�ړ����g�DID
              ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
              ,mbv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --�������[���_�~�[FLAG
              ,mbv.shipping_type                                shipping_type --�o�׌v��敪
              ,mbv.freshness_condition1                  freshness_condition1 --�N�x����1
              ,mbv.safety_stock_days1                      safety_stock_days1 --���S�݌ɓ���1
              ,mbv.max_stock_days1                            max_stock_days1 --�ő�݌ɓ���1
              ,mbv.freshness_condition2                  freshness_condition2 --�N�x����2
              ,mbv.safety_stock_days2                      safety_stock_days2 --���S�݌ɓ���2
              ,mbv.max_stock_days2                            max_stock_days2 --�ő�݌ɓ���2
              ,mbv.freshness_condition3                  freshness_condition3 --�N�x����3
              ,mbv.safety_stock_days3                      safety_stock_days3 --���S�݌ɓ���3
              ,mbv.max_stock_days3                            max_stock_days3 --�ő�݌ɓ���3
              ,mbv.freshness_condition4                  freshness_condition4 --�N�x����4
              ,mbv.safety_stock_days4                      safety_stock_days4 --���S�݌ɓ���4
              ,mbv.max_stock_days4                            max_stock_days4 --�ő�݌ɓ���4
              ,TO_DATE(msrv.attribute1, cv_date_format)      manufacture_date --�J�n�����N����
              ,CASE
                 WHEN msrv.attribute1 IS NULL
                   THEN TO_DATE(msrv.attribute2, cv_date_format)
                   ELSE NULL
               END                                             effective_date --�L���J�n��
              ,TO_DATE(msrv.attribute3, cv_date_format)          disable_date --�L���I����
              ,TO_NUMBER(msrv.attribute4)                     maxmum_quantity --�ݒ萔��
              ,TO_NUMBER(msrv.attribute5)                    stocked_quantity --�ړ���
        FROM msr_vw      msrv       --���ʉ����v��o�H
            ,msr_base_vw mbv        --��{�����v��o�H
        WHERE msrv.assignment_set_type        IN (cv_custom_plan)
          AND msrv.source_organization_id NOT IN (gn_master_org_id, gn_source_org_id)
          AND msrv.assignment_type            IN (cv_assign_type_item_org)
          AND msrv.receipt_organization_id     = mbv.receipt_organization_id
          AND mbv.sourcing_rule_priority       = 1
      )
      SELECT
             mbv.assignment_set_name                    assignment_set_name --�����Z�b�g��
            ,mbv.assignment_set_type                    assignment_set_type --�����Z�b�g�敪
            ,mbv.assignment_type                            assignment_type --������^�C�v
            ,mbv.sourcing_rule_type                      sourcing_rule_type --�\�[�X���[���^�C�v
            ,mbv.sourcing_rule_name                      sourcing_rule_name --�\�[�X���[����
            ,mbv.source_organization_id              source_organization_id --�ړ����g�DID
            ,mbv.receipt_organization_id            receipt_organization_id --�ړ���g�DID
            ,mbv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --�������[���_�~�[FLAG
            ,mbv.shipping_type                                shipping_type --�o�׌v��敪
            ,mbv.freshness_condition1                  freshness_condition1 --�N�x����1
            ,mbv.safety_stock_days1                      safety_stock_days1 --���S�݌ɓ���1
            ,mbv.max_stock_days1                            max_stock_days1 --�ő�݌ɓ���1
            ,mbv.freshness_condition2                  freshness_condition2 --�N�x����2
            ,mbv.safety_stock_days2                      safety_stock_days2 --���S�݌ɓ���2
            ,mbv.max_stock_days2                            max_stock_days2 --�ő�݌ɓ���2
            ,mbv.freshness_condition3                  freshness_condition3 --�N�x����3
            ,mbv.safety_stock_days3                      safety_stock_days3 --���S�݌ɓ���3
            ,mbv.max_stock_days3                            max_stock_days3 --�ő�݌ɓ���3
            ,mbv.freshness_condition4                  freshness_condition4 --�N�x����4
            ,mbv.safety_stock_days4                      safety_stock_days4 --���S�݌ɓ���4
            ,mbv.max_stock_days4                            max_stock_days4 --�ő�݌ɓ���4
            ,NULL                                          manufacture_date --�J�n�����N����
            ,NULL                                            effective_date --�L���J�n��
            ,NULL                                              disable_date --�L���I����
            ,NULL                                           maxmum_quantity --�ݒ萔��
            ,NULL                                          stocked_quantity --�ړ���
      FROM msr_base_vw mbv
      UNION ALL
      SELECT
             mcv.assignment_set_name                    assignment_set_name --�����Z�b�g��
            ,mcv.assignment_set_type                    assignment_set_type --�����Z�b�g�敪
            ,mcv.assignment_type                            assignment_type --������^�C�v
            ,mcv.sourcing_rule_type                      sourcing_rule_type --�\�[�X���[���^�C�v
            ,mcv.sourcing_rule_name                      sourcing_rule_name --�\�[�X���[����
            ,mcv.source_organization_id              source_organization_id --�ړ����g�DID
            ,mcv.receipt_organization_id            receipt_organization_id --�ړ���g�DID
            ,mcv.sourcing_rule_dummy_flag          sourcing_rule_dummy_flag --�������[���_�~�[FLAG
            ,mcv.shipping_type                                shipping_type --�o�׌v��敪
            ,mcv.freshness_condition1                  freshness_condition1 --�N�x����1
            ,mcv.safety_stock_days1                      safety_stock_days1 --���S�݌ɓ���1
            ,mcv.max_stock_days1                            max_stock_days1 --�ő�݌ɓ���1
            ,mcv.freshness_condition2                  freshness_condition2 --�N�x����2
            ,mcv.safety_stock_days2                      safety_stock_days2 --���S�݌ɓ���2
            ,mcv.max_stock_days2                            max_stock_days2 --�ő�݌ɓ���2
            ,mcv.freshness_condition3                  freshness_condition3 --�N�x����3
            ,mcv.safety_stock_days3                      safety_stock_days3 --���S�݌ɓ���3
            ,mcv.max_stock_days3                            max_stock_days3 --�ő�݌ɓ���3
            ,mcv.freshness_condition4                  freshness_condition4 --�N�x����4
            ,mcv.safety_stock_days4                      safety_stock_days4 --���S�݌ɓ���4
            ,mcv.max_stock_days4                            max_stock_days4 --�ő�݌ɓ���4
            ,mcv.manufacture_date                          manufacture_date --�J�n�����N����
            ,mcv.effective_date                              effective_date --�L���J�n��
            ,mcv.disable_date                                  disable_date --�L���I����
            ,mcv.maxmum_quantity                            maxmum_quantity --�ݒ萔��
            ,mcv.stocked_quantity                          stocked_quantity --�ړ���
      FROM msr_custom_vw mcv
    ;
    -- *** ���[�J���E���R�[�h ***
    l_xwyp_rec                xxcop_wk_yoko_planning%ROWTYPE;
    l_gfct_tab                g_fc_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_exists                 := NULL;
    lv_effective              := NULL;
    ln_work_day               := NULL;
    ld_planning_date          := NULL;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--    ln_planning_count         := NULL;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
    l_xwyp_rec                := NULL;
    l_gfct_tab.DELETE;
--
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--    ld_planning_date := gd_planning_date_to;
    ld_planning_date := gd_planning_date_from;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
    <<planning_loop>>
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--    LOOP
    WHILE (ld_planning_date <= gd_planning_date_to) LOOP
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
      BEGIN
        --�v�旧�ē��ŏ�����
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--        ln_planning_count := 0;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
        OPEN item_cur( ld_planning_date );
        <<item_loop>>
        LOOP
          BEGIN
            --�i�ڏ��̎擾
            FETCH item_cur INTO l_xwyp_rec.inventory_item_id
                               ,l_xwyp_rec.item_id
                               ,l_xwyp_rec.item_no
                               ,l_xwyp_rec.item_name
                               ,l_xwyp_rec.num_of_case
                               ,l_xwyp_rec.palette_max_cs_qty
                               ,l_xwyp_rec.palette_max_step_qty
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
                               ,l_xwyp_rec.expiration_day
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
            ;
            EXIT WHEN item_cur%NOTFOUND;
            --�P�[�X�����`�F�b�N
            IF (l_xwyp_rec.num_of_case = 0) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00061
                             ,iv_token_name1  => cv_msg_00061_token_1
                             ,iv_token_value1 => l_xwyp_rec.item_no
                           );
              RAISE internal_api_expt;
            END IF;
--
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_START
            --�i�ڃJ�e�S���擾(�Q�R�[�h)
            l_xwyp_rec.crowd_class_code := xxcop_common_pkg2.get_item_category_f(
                                              iv_category_set => cv_category_crowd_class
                                             ,in_item_id      => l_xwyp_rec.item_id
                                           );
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_ADD_END
--
            OPEN msr_cur( ld_planning_date, l_xwyp_rec.inventory_item_id );
            <<msr_loop>>
            LOOP
              BEGIN
                --�o�H���̎擾
                FETCH msr_cur INTO l_xwyp_rec.assignment_set_name
                                  ,l_xwyp_rec.assignment_set_type
                                  ,l_xwyp_rec.assignment_type
                                  ,l_xwyp_rec.sourcing_rule_type
                                  ,l_xwyp_rec.sourcing_rule_name
                                  ,l_xwyp_rec.ship_organization_id
                                  ,l_xwyp_rec.rcpt_organization_id
                                  ,l_xwyp_rec.sourcing_rule_dummy_flag
                                  ,l_xwyp_rec.shipping_type
                                  ,l_gfct_tab(1).freshness_condition
                                  ,l_gfct_tab(1).safety_stock_days
                                  ,l_gfct_tab(1).max_stock_days
                                  ,l_gfct_tab(2).freshness_condition
                                  ,l_gfct_tab(2).safety_stock_days
                                  ,l_gfct_tab(2).max_stock_days
                                  ,l_gfct_tab(3).freshness_condition
                                  ,l_gfct_tab(3).safety_stock_days
                                  ,l_gfct_tab(3).max_stock_days
                                  ,l_gfct_tab(4).safety_stock_days
                                  ,l_gfct_tab(4).safety_stock_days
                                  ,l_gfct_tab(4).max_stock_days
                                  ,l_xwyp_rec.sy_manufacture_date
                                  ,l_xwyp_rec.sy_effective_date
                                  ,l_xwyp_rec.sy_disable_date
                                  ,l_xwyp_rec.sy_maxmum_quantity
                                  ,l_xwyp_rec.sy_stocked_quantity
                ;
                EXIT WHEN msr_cur%NOTFOUND;
                --�ړ����q�ɏ��̎擾
                xxcop_common_pkg2.get_loct_info(
                   id_target_date        => ld_planning_date
                  ,in_organization_id    => l_xwyp_rec.ship_organization_id
                  ,ov_organization_code  => l_xwyp_rec.ship_organization_code
                  ,ov_organization_name  => l_xwyp_rec.ship_organization_name
                  ,on_loct_id            => l_xwyp_rec.ship_loct_id
                  ,ov_loct_code          => l_xwyp_rec.ship_loct_code
                  ,ov_loct_name          => l_xwyp_rec.ship_loct_name
                  ,ov_calendar_code      => l_xwyp_rec.ship_calendar_code
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.ship_organization_id
                               );
                  RAISE global_api_expt;
                ELSIF (lv_retcode = cv_status_warn) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.ship_organization_code
                               );
                  RAISE internal_api_expt;
                END IF;
                --�ړ���q�ɏ��̎擾
                xxcop_common_pkg2.get_loct_info(
                   id_target_date        => ld_planning_date
                  ,in_organization_id    => l_xwyp_rec.rcpt_organization_id
                  ,ov_organization_code  => l_xwyp_rec.rcpt_organization_code
                  ,ov_organization_name  => l_xwyp_rec.rcpt_organization_name
                  ,on_loct_id            => l_xwyp_rec.rcpt_loct_id
                  ,ov_loct_code          => l_xwyp_rec.rcpt_loct_code
                  ,ov_loct_name          => l_xwyp_rec.rcpt_loct_name
                  ,ov_calendar_code      => l_xwyp_rec.rcpt_calendar_code
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_organization_id
                               );
                  RAISE global_api_expt;
                ELSIF (lv_retcode = cv_status_warn) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00050
                                 ,iv_token_name1  => cv_msg_00050_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_organization_code
                               );
                  RAISE internal_api_expt;
                END IF;
                --�ړ����q�ɂ̉ғ����`�F�b�N
                xxcop_common_pkg2.get_working_days(
                   iv_calendar_code   => l_xwyp_rec.ship_calendar_code
                  ,in_organization_id => l_xwyp_rec.ship_organization_id
                  ,in_loct_id         => l_xwyp_rec.ship_loct_id
                  ,id_from_date       => ld_planning_date
                  ,id_to_date         => ld_planning_date
                  ,on_working_days    => ln_work_day
                  ,ov_errbuf          => lv_errbuf
                  ,ov_retcode         => lv_retcode
                  ,ov_errmsg          => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
                IF (l_xwyp_rec.ship_organization_id = gn_source_org_id) THEN
                  --�ړ����q�ɂ��p�b�J�[�q�Ƀ_�~�[�̏ꍇ�A�z�����[�h�^�C����0��ݒ�
                  l_xwyp_rec.delivery_lead_time := 0;
                ELSE
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
                  --�z�����[�h�^�C���̎擾
                  xxcop_common_pkg2.get_deliv_lead_time(
                     id_target_date        => ld_planning_date
                    ,iv_from_loct_code     => l_xwyp_rec.ship_loct_code
                    ,iv_to_loct_code       => l_xwyp_rec.rcpt_loct_code
                    ,on_delivery_lt        => l_xwyp_rec.delivery_lead_time
                    ,ov_errbuf             => lv_errbuf
                    ,ov_retcode            => lv_retcode
                    ,ov_errmsg             => lv_errmsg
                  );
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_api_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_appl_cont
                                   ,iv_name         => cv_msg_00053
                                   ,iv_token_name1  => cv_msg_00053_token_1
                                   ,iv_token_value1 => l_xwyp_rec.ship_loct_code
                                   ,iv_token_name2  => cv_msg_00053_token_2
                                   ,iv_token_value2 => l_xwyp_rec.rcpt_loct_code
                                 );
                    RAISE internal_api_expt;
                  END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
                END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
                --�o�ד��̎擾
                l_xwyp_rec.shipping_date := ld_planning_date;
                --�����̎擾
                xxcop_common_pkg2.get_receipt_date(
                   iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
                  ,in_organization_id => NULL
                  ,in_loct_id         => NULL
                  ,id_shipment_date   => ld_planning_date
                  ,in_lead_time       => l_xwyp_rec.delivery_lead_time
                  ,od_receipt_date    => l_xwyp_rec.receipt_date
                  ,ov_errbuf          => lv_errbuf
                  ,ov_retcode         => lv_retcode
                  ,ov_errmsg          => lv_errmsg
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                IF (l_xwyp_rec.receipt_date IS NULL) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_appl_cont
                                 ,iv_name         => cv_msg_00066
                                 ,iv_token_name1  => cv_msg_00066_token_1
                                 ,iv_token_value1 => l_xwyp_rec.rcpt_loct_code
                                 ,iv_token_name2  => cv_msg_00066_token_2
                                 ,iv_token_value2 => l_xwyp_rec.rcpt_calendar_code
                                 ,iv_token_name3  => cv_msg_00066_token_3
                                 ,iv_token_value3 => TO_CHAR(ld_planning_date, cv_date_format)
                               );
                  RAISE internal_api_expt;
                END IF;
                --���ʉ����̏ꍇ
                IF (l_xwyp_rec.assignment_set_type = cv_custom_plan) THEN
                  -- ===============================
                  -- B-11�D���ʉ����v��L�����ԃ`�F�b�N
                  -- ===============================
                  chk_effective_route(
                     i_xwyp_rec            => l_xwyp_rec
                    ,ov_effective          => lv_effective
                    ,ov_errbuf             => lv_errbuf
                    ,ov_retcode            => lv_retcode
                    ,ov_errmsg             => lv_errmsg
                  );
                  IF (lv_retcode = cv_status_error) THEN
                    IF (lv_errbuf IS NULL) THEN
                      RAISE internal_api_expt;
                    ELSE
                      RAISE global_api_expt;
                    END IF;
                  END IF;
                  --�v�旧�ē����L���I�������߂��Ă���܂��͐ݒ萔�𒴂��Ă���ꍇ
                  IF (lv_effective <> cv_status_normal) THEN
                    RAISE obsolete_skip_expt;
                  END IF;
                END IF;
                -- ===============================
                -- B-12�D�N�x�����`�F�b�N
                -- ===============================
                chk_freshness_cond(
                   i_xwyp_rec            => l_xwyp_rec
                  ,io_gfct_tab           => l_gfct_tab
                  ,ov_errbuf             => lv_errbuf
                  ,ov_retcode            => lv_retcode
                  ,ov_errmsg             => lv_errmsg
                );
                IF (lv_retcode <> cv_status_normal) THEN
                  IF (lv_errbuf IS NULL) THEN
                    RAISE internal_api_expt;
                  ELSE
                    RAISE global_api_expt;
                  END IF;
                END IF;
                --�v�旧�ăt���O�̐ݒ�
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--                IF (l_xwyp_rec.receipt_date >= gd_planning_date_from) THEN
--                  IF (ln_work_day > 0) THEN
--                    l_xwyp_rec.planning_flag := cv_planning_yes;
--                  ELSE
--                    l_xwyp_rec.planning_flag := cv_planning_no;
--                  END IF;
--                  ln_planning_count := ln_planning_count + 1;
--                ELSE
--                  l_xwyp_rec.planning_flag := cv_planning_no;
--                END IF;
                  IF (ln_work_day > 0) THEN
                    l_xwyp_rec.planning_flag := cv_planning_yes;
                  ELSE
                    l_xwyp_rec.planning_flag := cv_planning_no;
                  END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
                -- ===============================
                -- B-13�D�����v�敨�����[�N�e�[�u���o�^
                -- ===============================
                entry_xwyp(
                   i_xwyp_rec   => l_xwyp_rec
                  ,i_gfct_tab   => l_gfct_tab
                  ,ov_retcode   => lv_retcode
                  ,ov_errbuf    => lv_errbuf
                  ,ov_errmsg    => lv_errmsg
                );
                IF (lv_retcode <> cv_status_normal) THEN
                  IF (lv_errbuf IS NULL) THEN
                    RAISE internal_api_expt;
                  ELSE
                    RAISE global_api_expt;
                  END IF;
                END IF;
              EXCEPTION
                WHEN obsolete_skip_expt THEN
                  NULL;
              END;
            END LOOP msr_loop;
            CLOSE msr_cur;
          EXCEPTION
            WHEN outside_scope_expt THEN
              NULL;
          END;
        END LOOP item_loop;
--
        --�f�o�b�N���b�Z�[�W�o��
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                          || 'item_cur(COUNT):'
                          || item_cur%ROWCOUNT                          || ','
                          || TO_CHAR(ld_planning_date, cv_date_format)  || ','
        );
--
        CLOSE item_cur;
      EXCEPTION
        WHEN obsolete_skip_expt THEN
          NULL;
      END;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_START
--      --�v�旧�ē��̏I������
--      IF (ln_planning_count = 0) THEN
--        EXIT planning_loop;
--      END IF;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_DEL_END
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_START
--      -- �v�旧�ē����f�N�������g
--      ld_planning_date := ld_planning_date - 1;
      -- �v�旧�ē����C���N�������g
      ld_planning_date := ld_planning_date + 1;
--20100107_Ver3.2_E_�{�ғ�_00936_SCS.Goto_MOD_END
    END LOOP planning_loop;
--
    --�Ώی����̊m�F
    SELECT COUNT(*)
    INTO   ln_exists
    FROM xxcop_wk_yoko_planning xwyp
    WHERE xwyp.transaction_id = gn_transaction_id
      AND xwyp.request_id     = cn_request_id
      AND xwyp.planning_flag  = cv_planning_yes
    ;
    --�Ώی�����0���̏ꍇ�A�I��
    IF (ln_exists = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (item_cur%ISOPEN) THEN
        CLOSE item_cur;
      END IF;
      IF (msr_cur%ISOPEN) THEN
        CLOSE msr_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_msr_route;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwyl
   * Description      : �i�ڕʑ�\�q�Ɏ擾(B-3)
   ***********************************************************************************/
  PROCEDURE entry_xwyl(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwyl'; -- �v���O������
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
    lt_loct_id                mtl_item_locations.inventory_location_id%TYPE;
    lt_loct_code              mtl_item_locations.segment1%TYPE;
    lt_frq_loct_id            mtl_item_locations.inventory_location_id%TYPE;
    lt_frq_loct_code          mtl_item_locations.segment1%TYPE;
    ln_entry_xwyl             NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�����q�ɂ̎擾
    CURSOR xwyp_cur IS
      SELECT xwyp.rcpt_loct_id            loct_id
            ,xwyp.rcpt_loct_code          loct_code
            ,xwyp.item_id                 item_id
            ,xwyp.item_no                 item_no
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id         = gn_transaction_id
        AND xwyp.request_id             = cn_request_id
      UNION
      SELECT xwyp.ship_loct_id            loct_id
            ,xwyp.ship_loct_code          loct_code
            ,xwyp.item_id                 item_id
            ,xwyp.item_no                 item_no
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id         = gn_transaction_id
        AND xwyp.request_id             = cn_request_id
        AND xwyp.ship_organization_id  <> gn_source_org_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xwyl_rec                xxcop_wk_yoko_locations%ROWTYPE;
    l_xwyl_tab                g_xwyl_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    lt_loct_id                := NULL;
    lt_loct_code              := NULL;
    lt_frq_loct_id            := NULL;
    lt_frq_loct_code          := NULL;
    ln_entry_xwyl             := 0;
    l_xwyl_rec                := NULL;
    l_xwyl_tab.DELETE;
--
    BEGIN
      --�����q�ɂ̎擾
      <<xwyl_loop>>
      FOR l_xwyp_rec IN xwyp_cur LOOP
        --��\�q�ɂ��擾
        SELECT mil.inventory_location_id    loct_id
              ,mil.segment1                 loct_code
              ,mil.attribute5               frq_loct_code
        INTO lt_loct_id
            ,lt_loct_code
            ,lt_frq_loct_code
        FROM mtl_item_locations             mil
        WHERE mil.inventory_location_id = l_xwyp_rec.loct_id
        ;
--
        l_xwyl_rec.transaction_id           := gn_transaction_id;
        l_xwyl_rec.planning_flag            := NULL;
        l_xwyl_rec.frq_loct_id              := lt_loct_id;
        l_xwyl_rec.frq_loct_code            := lt_loct_code;
        l_xwyl_rec.loct_id                  := lt_loct_id;
        l_xwyl_rec.loct_code                := lt_loct_code;
        l_xwyl_rec.item_id                  := l_xwyp_rec.item_id;
        l_xwyl_rec.item_no                  := l_xwyp_rec.item_no;
        l_xwyl_rec.schedule_date            := NULL;
        l_xwyl_rec.created_by               := cn_created_by;
        l_xwyl_rec.creation_date            := cd_creation_date;
        l_xwyl_rec.last_updated_by          := cn_last_updated_by;
        l_xwyl_rec.last_update_date         := cd_last_update_date;
        l_xwyl_rec.last_update_login        := cn_last_update_login;
        l_xwyl_rec.request_id               := cn_request_id;
        l_xwyl_rec.program_application_id   := cn_program_application_id;
        l_xwyl_rec.program_id               := cn_program_id;
        l_xwyl_rec.program_update_date      := cd_program_update_date;
--
        BEGIN
          --�����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���o�^
          INSERT INTO xxcop_wk_yoko_locations VALUES l_xwyl_rec;
          ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;
--
        IF (lt_frq_loct_code IS NULL) THEN
          --��\�q�ɂłȂ��ꍇ
          NULL;
        ELSIF (lt_frq_loct_code = lt_loct_code) THEN
          --��\�q��(�e)�̏ꍇ
          BEGIN
            --OPM�ۊǏꏊ�}�X�^�̑�\�q�ɂ������v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���ɓo�^
            INSERT INTO xxcop_wk_yoko_locations (
               transaction_id
              ,planning_flag
              ,frq_loct_id
              ,frq_loct_code
              ,loct_id
              ,loct_code
              ,item_id
              ,item_no
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
            SELECT gn_transaction_id            transaction_id
                  ,NULL                         planning_flag
                  ,lt_loct_id                   frq_loct_id
                  ,lt_loct_code                 frq_loct_code
                  ,mil.inventory_location_id    loct_id
                  ,mil.segment1                 loct_code
                  ,l_xwyp_rec.item_id           item_id
                  ,l_xwyp_rec.item_no           item_no
                  ,NULL                         schedule_date
                  ,cn_created_by                created_by
                  ,cd_creation_date             creation_date
                  ,cn_last_updated_by           last_updated_by
                  ,cd_last_update_date          last_update_date
                  ,cn_last_update_login         last_update_login
                  ,cn_request_id                request_id
                  ,cn_program_application_id    program_application_id
                  ,cn_program_id                program_id
                  ,cd_program_update_date       program_update_date
            FROM mtl_item_locations         mil
            WHERE mil.attribute5          = lt_frq_loct_code
              AND mil.segment1           <> mil.attribute5
            ;
            ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
--
          BEGIN
            --�q�ɕi�ڃA�h�I���}�X�^�̕i�ڕʑ�\�q�ɂ������v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���ɓo�^
            INSERT INTO xxcop_wk_yoko_locations (
               transaction_id
              ,planning_flag
              ,frq_loct_id
              ,frq_loct_code
              ,loct_id
              ,loct_code
              ,item_id
              ,item_no
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
            SELECT gn_transaction_id            transaction_id
                  ,NULL                         planning_flag
                  ,lt_loct_id                   frq_loct_id
                  ,lt_loct_code                 frq_loct_code
                  ,xfil.item_location_id        loct_id
                  ,xfil.item_location_code      loct_code
                  ,l_xwyp_rec.item_id           item_id
                  ,l_xwyp_rec.item_no           item_no
                  ,NULL                         schedule_date
                  ,cn_created_by                created_by
                  ,cd_creation_date             creation_date
                  ,cn_last_updated_by           last_updated_by
                  ,cd_last_update_date          last_update_date
                  ,cn_last_update_login         last_update_login
                  ,cn_request_id                request_id
                  ,cn_program_application_id    program_application_id
                  ,cn_program_id                program_id
                  ,cd_program_update_date       program_update_date
            FROM mtl_item_locations         mil
                ,xxwsh_frq_item_locations   xfil
            WHERE mil.inventory_location_id   = xfil.item_location_id
              AND xfil.frq_item_location_code = lt_frq_loct_code
              AND xfil.item_id                = l_xwyp_rec.item_id
            ;
            ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
        ELSE
          --��\�q��(�q)�̏ꍇ
          IF (gv_dummy_frequent_whse = lt_frq_loct_code) THEN
            BEGIN
              --�q�ɕi�ڃA�h�I���}�X�^�̕i�ڕʑ�\�q�ɂ������v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���ɓo�^
              INSERT INTO xxcop_wk_yoko_locations (
                 transaction_id
                ,planning_flag
                ,frq_loct_id
                ,frq_loct_code
                ,loct_id
                ,loct_code
                ,item_id
                ,item_no
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
              SELECT gn_transaction_id            transaction_id
                    ,NULL                         planning_flag
                    ,xfil.frq_item_location_id    frq_loct_id
                    ,xfil.frq_item_location_code  frq_loct_code
                    ,lt_loct_id                   loct_id
                    ,lt_loct_code                 loct_code
                    ,l_xwyp_rec.item_id           item_id
                    ,l_xwyp_rec.item_no           item_no
                    ,NULL                         schedule_date
                    ,cn_created_by                created_by
                    ,cd_creation_date             creation_date
                    ,cn_last_updated_by           last_updated_by
                    ,cd_last_update_date          last_update_date
                    ,cn_last_update_login         last_update_login
                    ,cn_request_id                request_id
                    ,cn_program_application_id    program_application_id
                    ,cn_program_id                program_id
                    ,cd_program_update_date       program_update_date
              FROM xxwsh_frq_item_locations   xfil
              WHERE xfil.item_location_code     = lt_loct_code
                AND xfil.item_id                = l_xwyp_rec.item_id
              ;
              ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
          ELSE
            BEGIN
              --OPM�ۊǏꏊ�}�X�^�̑�\�q�ɂ������v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u���ɓo�^
              INSERT INTO xxcop_wk_yoko_locations (
                 transaction_id
                ,planning_flag
                ,frq_loct_id
                ,frq_loct_code
                ,loct_id
                ,loct_code
                ,item_id
                ,item_no
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
              SELECT gn_transaction_id            transaction_id
                    ,NULL                         planning_flag
                    ,mil2.inventory_location_id   frq_loct_id
                    ,mil2.segment1                frq_loct_code
                    ,mil1.inventory_location_id   loct_id
                    ,mil1.segment1                loct_code
                    ,l_xwyp_rec.item_id           item_id
                    ,l_xwyp_rec.item_no           item_no
                    ,NULL                         schedule_date
                    ,cn_created_by                created_by
                    ,cd_creation_date             creation_date
                    ,cn_last_updated_by           last_updated_by
                    ,cd_last_update_date          last_update_date
                    ,cn_last_update_login         last_update_login
                    ,cn_request_id                request_id
                    ,cn_program_application_id    program_application_id
                    ,cn_program_id                program_id
                    ,cd_program_update_date       program_update_date
              FROM mtl_item_locations         mil1
                  ,mtl_item_locations         mil2
              WHERE mil1.attribute5         = lt_frq_loct_code
                AND mil1.segment1          <> mil1.attribute5
                AND mil2.segment1           = mil1.attribute5
              ;
              ln_entry_xwyl := ln_entry_xwyl + SQL%ROWCOUNT;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
          END IF;
        END IF;
      END LOOP xwyl_loop;
--
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                        || 'xwyl(COUNT):'
                        || ln_entry_xwyl
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwyl
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END entry_xwyl;
--
  /**********************************************************************************
   * Procedure Name   : proc_shipping_pace
   * Description      : �o�׃y�[�X�̌v�Z(B-4)
   ***********************************************************************************/
  PROCEDURE proc_shipping_pace(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_shipping_pace'; -- �v���O������
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
    ln_shipment_days          NUMBER;       --�o�׎��ъ��Ԃ̉ғ�����
    ln_forecast_days          NUMBER;       --�o�ח\�����Ԃ̉ғ�����
    ln_shipping_quantity      NUMBER;       --�o�׎��ѐ�
    ln_forecast_quantity      NUMBER;       --�o�ח\����
    ld_critical_date          DATE;         --�N�x�������
    ln_earliest_idx           NUMBER;       --�ő�N�x��������C���f�b�N�X
    ld_earliest_date          DATE;         --�ő�N�x�������
    ld_manufacture_date       DATE;         --���b�g�̐����N����
    ld_expiration_date        DATE;         --���b�g�̏ܖ�����
    ld_date_from              DATE;
    ld_date_to                DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�i�ځ|�ړ���q�ɂ̎擾
    CURSOR xwyp_cur IS
      SELECT xwyp.item_id                           item_id
            ,xwyp.inventory_item_id                 inventory_item_id
            ,xwyp.item_no                           item_no
            ,xwyp.num_of_case                       num_of_case
            ,xwyp.rcpt_organization_id              rcpt_organization_id
            ,xwyp.rcpt_organization_code            rcpt_organization_code
            ,xwyp.rcpt_loct_id                      rcpt_loct_id
            ,xwyp.rcpt_loct_code                    rcpt_loct_code
            ,xwyp.rcpt_calendar_code                rcpt_calendar_code
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
      GROUP BY xwyp.item_id
              ,xwyp.inventory_item_id
              ,xwyp.item_no
              ,xwyp.num_of_case
              ,xwyp.rcpt_organization_id
              ,xwyp.rcpt_organization_code
              ,xwyp.rcpt_loct_id
              ,xwyp.rcpt_loct_code
              ,xwyp.rcpt_calendar_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_gfct_tab                g_fc_ttype;                 --�N�x�����R���N�V�����^
    l_gspt_tab                g_sp_ttype;                 --�o�׃y�[�X�R���N�V�����^
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_shipment_days          := NULL;
    ln_forecast_days          := NULL;
    ln_shipping_quantity      := NULL;
    ln_forecast_quantity      := NULL;
    ld_critical_date          := NULL;
    ln_earliest_idx           := NULL;
    ld_earliest_date          := NULL;
    ld_manufacture_date       := NULL;
    ld_expiration_date        := NULL;
    ld_date_from              := NULL;
    ld_date_to                := NULL;
--
    --�i�ځ|�ړ���q�ɂ̎擾
    <<xwyp_loop>>
    FOR l_xwyp_rec IN xwyp_cur LOOP
      --������
      ln_shipping_quantity := 0;
      ln_forecast_quantity := 0;
      l_gspt_tab.DELETE;
--
      --�N�x�����擾
      SELECT xwyp.freshness_priority                freshness_priority
            ,xwyp.freshness_condition               freshness_condition
            ,xwyp.freshness_class                   freshness_class
            ,xwyp.freshness_check_value             freshness_check_value
            ,xwyp.freshness_adjust_value            freshness_adjust_value
            ,0                                      safety_stock_days
            ,xwyp.max_stock_days                    max_stock_days
      BULK COLLECT INTO l_gfct_tab
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
        AND xwyp.item_id        = l_xwyp_rec.item_id
        AND xwyp.rcpt_loct_id   = l_xwyp_rec.rcpt_loct_id
      GROUP BY xwyp.freshness_priority
              ,xwyp.freshness_condition
              ,xwyp.freshness_class
              ,xwyp.freshness_check_value
              ,xwyp.freshness_adjust_value
              ,xwyp.max_stock_days
      ORDER BY xwyp.freshness_priority
      ;
--
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_START
--      --�o�׎��ъ��Ԃ̉ғ������̎擾
--      xxcop_common_pkg2.get_working_days(
--         iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
--        ,in_organization_id => l_xwyp_rec.rcpt_organization_id
--        ,in_loct_id         => l_xwyp_rec.rcpt_loct_id
--        ,id_from_date       => gd_shipment_date_from
--        ,id_to_date         => gd_shipment_date_to
--        ,on_working_days    => ln_shipment_days
--        ,ov_errbuf          => lv_errbuf
--        ,ov_retcode         => lv_retcode
--        ,ov_errmsg          => lv_errmsg
--      );
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
--      IF (ln_shipment_days = 0) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_appl_cont
--                       ,iv_name         => cv_msg_00056
--                       ,iv_token_name1  => cv_msg_00056_token_1
--                       ,iv_token_value1 => TO_CHAR(gd_shipment_date_from, cv_date_format)
--                       ,iv_token_name2  => cv_msg_00056_token_2
--                       ,iv_token_value2 => TO_CHAR(gd_shipment_date_to  , cv_date_format)
--                     );
--        RAISE internal_api_expt;
--      END IF;
      --�o�׎��т̉ғ�����
      ln_shipment_days := gn_working_days;
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_MOD_END
--
      --�o�׎��т̏W�v
      <<shipping_loop>>
      FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
        --�o�׎��т̎擾
        xxcop_common_pkg2.get_num_of_shipped(
           in_deliver_from_id        => l_xwyp_rec.rcpt_loct_id
          ,in_item_id                => l_xwyp_rec.item_id
          ,id_shipment_date_from     => gd_shipment_date_from
          ,id_shipment_date_to       => gd_shipment_date_to
          ,iv_freshness_condition    => l_gfct_tab(ln_gfct_idx).freshness_condition
          ,in_inventory_item_id      => l_xwyp_rec.inventory_item_id
          ,on_shipped_quantity       => l_gspt_tab(ln_gfct_idx).shipping_quantity
          ,ov_errbuf                 => lv_errbuf
          ,ov_retcode                => lv_retcode
          ,ov_errmsg                 => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        --�o�׎��т̃P�[�X���Z
        l_gspt_tab(ln_gfct_idx).shipping_quantity := ROUND(l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                         / l_xwyp_rec.num_of_case
                                                     );
        --�o�׎��уy�[�X�̌v�Z
        l_gspt_tab(ln_gfct_idx).shipping_pace := ROUND(l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                     / ln_shipment_days
                                                 );
        --�o�׎��т̍��v
        ln_shipping_quantity := ln_shipping_quantity + l_gspt_tab(ln_gfct_idx).shipping_quantity;
      END LOOP shipping_loop;
--
      IF (cv_plan_type_forecate = NVL(gv_plan_type, cv_plan_type_forecate)) THEN
        --�o�ח\�����Ԃ̉ғ������̎擾
        xxcop_common_pkg2.get_working_days(
           iv_calendar_code   => l_xwyp_rec.rcpt_calendar_code
          ,in_organization_id => l_xwyp_rec.rcpt_organization_id
          ,in_loct_id         => l_xwyp_rec.rcpt_loct_id
          ,id_from_date       => gd_forecast_date_from
          ,id_to_date         => gd_forecast_date_to
          ,on_working_days    => ln_forecast_days
          ,ov_errbuf          => lv_errbuf
          ,ov_retcode         => lv_retcode
          ,ov_errmsg          => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        IF (ln_forecast_days = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00056
                         ,iv_token_name1  => cv_msg_00056_token_1
                         ,iv_token_value1 => TO_CHAR(gd_forecast_date_from, cv_date_format)
                         ,iv_token_name2  => cv_msg_00056_token_2
                         ,iv_token_value2 => TO_CHAR(gd_forecast_date_to  , cv_date_format)
                       );
          RAISE internal_api_expt;
        END IF;
--
        --�o�ח\���̎擾
        xxcop_common_pkg2.get_num_of_forecast(
           in_organization_id   => l_xwyp_rec.rcpt_organization_id
          ,in_inventory_item_id => l_xwyp_rec.inventory_item_id
          ,id_plan_date_from    => gd_forecast_date_from
          ,id_plan_date_to      => gd_forecast_date_to
          ,in_loct_id           => l_xwyp_rec.rcpt_loct_id
          ,on_quantity          => ln_forecast_quantity
          ,ov_errbuf            => lv_errbuf
          ,ov_retcode           => lv_retcode
          ,ov_errmsg            => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        IF (ln_forecast_quantity > 0) THEN
          --�o�ח\���̃P�[�X���Z
          ln_forecast_quantity := ROUND(ln_forecast_quantity / l_xwyp_rec.num_of_case);
--
          --�o�׎��т̍��v���𔻒�
          IF (ln_shipping_quantity > 0) THEN
            --�o�׎��т�����ꍇ�A�N�x�����ʂɏo�׎��тň�
            <<div_forecast_loop>>
            FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
              --�N�x�����ʂ̏o�ח\����
              l_gspt_tab(ln_gfct_idx).forecast_quantity := ROUND(ln_forecast_quantity
                                                               * l_gspt_tab(ln_gfct_idx).shipping_quantity
                                                               / ln_shipping_quantity
                                                           );
              --�o�ח\���y�[�X
              l_gspt_tab(ln_gfct_idx).forecast_pace := ROUND(l_gspt_tab(ln_gfct_idx).forecast_quantity
                                                           / ln_forecast_days
                                                       );
            END LOOP div_forecast_loop;
          ELSE
            BEGIN
              --�o�׎��т��Ȃ��ꍇ�A������Z���N�x�����Ɉꊇ
              --�i�ڂ̐����N�����A�ܖ��������擾
              SELECT TO_DATE(ilm.attribute1, cv_date_format)  manufacture_date
                    ,TO_DATE(ilm.attribute3, cv_date_format)  expiration_date
              INTO ld_manufacture_date
                  ,ld_expiration_date
              FROM ic_lots_mst ilm
              WHERE ilm.item_id       = l_xwyp_rec.item_id
                AND ilm.lot_id       <> 0
                AND ROWNUM = 1
              ;
              <<critical_loop>>
              FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
                --�N�x�����ʊ���̎擾
                ld_critical_date := xxcop_common_pkg2.get_critical_date_f(
                                       iv_freshness_class        => l_gfct_tab(ln_gfct_idx).freshness_class
                                      ,in_freshness_check_value  => l_gfct_tab(ln_gfct_idx).freshness_check_value
                                      ,in_freshness_adjust_value => l_gfct_tab(ln_gfct_idx).freshness_adjust_value
                                      ,in_max_stock_days         => l_gfct_tab(ln_gfct_idx).max_stock_days
                                      ,in_freshness_buffer_days  => gn_freshness_buffer_days
                                      ,id_manufacture_date       => ld_manufacture_date
                                      ,id_expiration_date        => ld_expiration_date
                                    );
                IF ((ld_earliest_date > ld_critical_date) OR (ld_earliest_date IS NULL)) THEN
                  ld_earliest_date := ld_critical_date;
                  ln_earliest_idx  := ln_gfct_idx;
                END IF;
              END LOOP critical_loop;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --�Ώەi�ڂ̃��b�g���Ȃ��ꍇ�A�N�x��������𔻒�ł��Ȃ����ߑN�x����1�Ɉꊇ�ݒ�
                ln_earliest_idx := 1;
            END;
            --�N�x�����ʂ̏o�ח\����
            l_gspt_tab(ln_earliest_idx).forecast_quantity := ln_forecast_quantity;
            --�o�ח\���y�[�X
            l_gspt_tab(ln_earliest_idx).forecast_pace     := ROUND(ln_forecast_quantity / ln_forecast_days);
          END IF;
        END IF;
      END IF;
--
      --�o�׃y�[�X�̍X�V
      <<xwyp_update_loop>>
      FOR ln_gfct_idx IN l_gfct_tab.FIRST .. l_gfct_tab.LAST LOOP
        BEGIN
          UPDATE xxcop_wk_yoko_planning xwyp
          SET    xwyp.shipping_pace     = NVL(l_gspt_tab(ln_gfct_idx).shipping_pace, 0)
                ,xwyp.forecast_pace     = NVL(l_gspt_tab(ln_gfct_idx).forecast_pace, 0)
          WHERE xwyp.transaction_id      = gn_transaction_id
            AND xwyp.request_id          = cn_request_id
            AND xwyp.item_id             = l_xwyp_rec.item_id
            AND xwyp.rcpt_loct_id        = l_xwyp_rec.rcpt_loct_id
            AND xwyp.freshness_condition = l_gfct_tab(ln_gfct_idx).freshness_condition
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := SQLERRM;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00028
                           ,iv_token_name1  => cv_msg_00028_token_1
                           ,iv_token_value1 => cv_table_xwyp
                         );
            RAISE global_api_expt;
        END;
      END LOOP xwyp_update_loop;
    END LOOP xwyp_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END proc_shipping_pace;
--
  /**********************************************************************************
   * Procedure Name   : proc_total_pace
   * Description      : ���o�׃y�[�X�̌v�Z(B-5)
   ***********************************************************************************/
  PROCEDURE proc_total_pace(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_total_pace'; -- �v���O������
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
    lt_total_shipping_pace    xxcop_wk_yoko_planning.total_shipping_pace%TYPE;  --���o�׎��уy�[�X
    lt_total_forecast_pace    xxcop_wk_yoko_planning.total_forecast_pace%TYPE;  --���o�ח\���y�[�X
    lt_shipping_unit          xxcop_wk_yoko_planning.delivery_unit%TYPE;        --�o�׎��єz���P��
    lt_forecast_unit          xxcop_wk_yoko_planning.delivery_unit%TYPE;        --�o�ח\���z���P��
--
    -- *** ���[�J���E�J�[�\�� ***
    --�i�ځ|�ړ���q�Ɂ|�N�x�����̎擾
    CURSOR xwyp_cur IS
      SELECT xwyp.shipping_date                     shipping_date
            ,xwyp.item_id                           item_id
            ,xwyp.item_no                           item_no
            ,xwyp.palette_max_cs_qty                palette_max_cs_qty
            ,xwyp.palette_max_step_qty              palette_max_step_qty
            ,xwyp.rcpt_loct_id                      rcpt_loct_id
            ,xwyp.rcpt_loct_code                    rcpt_loct_code
            ,xwyp.freshness_condition               freshness_condition
            ,MAX(xwyp.shipping_pace)                shipping_pace
            ,MAX(xwyp.forecast_pace)                forecast_pace
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
      GROUP BY xwyp.shipping_date
              ,xwyp.item_id
              ,xwyp.item_no
              ,xwyp.palette_max_cs_qty
              ,xwyp.palette_max_step_qty
              ,xwyp.rcpt_loct_id
              ,xwyp.rcpt_loct_code
              ,xwyp.freshness_condition
      ;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    lt_total_shipping_pace    := NULL;
    lt_total_forecast_pace    := NULL;
    lt_shipping_unit          := NULL;
    lt_forecast_unit          := NULL;
--
    --�i�ځ|�ړ���q�Ɂ|�N�x�����̎擾
    <<xwyp_loop>>
    FOR l_xwyp_rec IN xwyp_cur LOOP
      BEGIN
        --���o�׃y�[�X�̏W�v
        SELECT NVL(SUM(xwypv.shipping_pace), 0) + l_xwyp_rec.shipping_pace        total_shipping_pace
              ,NVL(SUM(xwypv.forecast_pace), 0) + l_xwyp_rec.forecast_pace        total_forecast_pace
        INTO lt_total_shipping_pace
            ,lt_total_forecast_pace
        FROM (
          SELECT xwyp.ship_loct_id                  ship_loct_id
                ,xwyp.rcpt_loct_id                  rcpt_loct_id
                ,SUM(CASE
                       WHEN xwyp.freshness_condition = l_xwyp_rec.freshness_condition THEN
                         xwyp.shipping_pace
                       ELSE
                         0
                     END)                           shipping_pace
                ,SUM(CASE
                       WHEN xwyp.freshness_condition = l_xwyp_rec.freshness_condition THEN
                         xwyp.forecast_pace
                       ELSE
                         0
                     END)                           forecast_pace
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id       = gn_transaction_id
            AND xwyp.request_id           = cn_request_id
            AND xwyp.shipping_date        = l_xwyp_rec.shipping_date
            AND xwyp.assignment_set_type  = cv_base_plan
            AND xwyp.item_id              = l_xwyp_rec.item_id
          GROUP BY xwyp.ship_loct_id
                  ,xwyp.rcpt_loct_id
          UNION ALL
          SELECT xwyl.loct_id                       ship_loct_id
                ,xwyl.frq_loct_id                   rcpt_loct_id
                ,0                                  shipping_pace
                ,0                                  forecast_pace
          FROM xxcop_wk_yoko_locations xwyl
          WHERE xwyl.transaction_id       = gn_transaction_id
            AND xwyl.request_id           = cn_request_id
            AND xwyl.item_id              = l_xwyp_rec.item_id
            AND xwyl.frq_loct_id <> xwyl.loct_id
        ) xwypv
        START WITH       xwypv.ship_loct_id  = l_xwyp_rec.rcpt_loct_id
        CONNECT BY PRIOR xwypv.rcpt_loct_id  = xwypv.ship_loct_id
        ;
      EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00060
                         ,iv_token_name1  => cv_msg_00060_token_1
                         ,iv_token_value1 => l_xwyp_rec.rcpt_loct_code
                         ,iv_token_name2  => cv_msg_00060_token_2
                         ,iv_token_value2 => l_xwyp_rec.item_no
                       );
          RAISE internal_api_expt;
      END;
--
      lt_shipping_unit := NULL;
      IF ((lt_total_shipping_pace > 0) AND (cv_plan_type_shipped = NVL(gv_plan_type, cv_plan_type_shipped))) THEN
        --�o�׎��т̔z���P�ʂ��擾
        xxcop_common_pkg2.get_delivery_unit(
           in_shipping_pace         => lt_total_shipping_pace
          ,in_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
          ,in_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
          ,ov_unit_delivery         => lt_shipping_unit
          ,ov_errbuf                => lv_errbuf
          ,ov_retcode               => lv_retcode
          ,ov_errmsg                => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      lt_forecast_unit := NULL;
      IF ((lt_total_forecast_pace > 0) AND (cv_plan_type_forecate = NVL(gv_plan_type, cv_plan_type_forecate))) THEN
        --�o�ח\���̔z���P�ʂ��擾
        xxcop_common_pkg2.get_delivery_unit(
           in_shipping_pace         => lt_total_forecast_pace
          ,in_palette_max_cs_qty    => l_xwyp_rec.palette_max_cs_qty
          ,in_palette_max_step_qty  => l_xwyp_rec.palette_max_step_qty
          ,ov_unit_delivery         => lt_forecast_unit
          ,ov_errbuf                => lv_errbuf
          ,ov_retcode               => lv_retcode
          ,ov_errmsg                => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      BEGIN
        --���o�׃y�[�X�̍X�V
        UPDATE xxcop_wk_yoko_planning xwyp
        SET    xwyp.total_shipping_pace = lt_total_shipping_pace
              ,xwyp.total_forecast_pace = lt_total_forecast_pace
              ,xwyp.delivery_unit       = CASE
                                            WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                                              lt_shipping_unit
                                            WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                                              lt_forecast_unit
                                            ELSE
                                              NULL
                                          END
        WHERE xwyp.transaction_id       = gn_transaction_id
          AND xwyp.request_id           = cn_request_id
          AND xwyp.shipping_date        = l_xwyp_rec.shipping_date
          AND xwyp.item_id              = l_xwyp_rec.item_id
          AND xwyp.rcpt_loct_id         = l_xwyp_rec.rcpt_loct_id
          AND xwyp.freshness_condition  = l_xwyp_rec.freshness_condition
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00028
                         ,iv_token_name1  => cv_msg_00028_token_1
                         ,iv_token_value1 => cv_table_xwyp
                       );
          RAISE global_api_expt;
      END;
    END LOOP xwyp_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END proc_total_pace;
--
  /**********************************************************************************
   * Procedure Name   : create_xli
   * Description      : �莝�݌Ƀe�[�u���쐬(B-6)
   ***********************************************************************************/
  PROCEDURE create_xli(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xli'; -- �v���O������
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
    CURSOR xwyp_cur IS
      SELECT xwyp.item_id                 item_id
            ,xwyp.num_of_case             num_of_case
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id = gn_transaction_id
        AND xwyp.request_id     = cn_request_id
        AND xwyp.planning_flag  = cv_planning_yes
      GROUP BY xwyp.item_id
              ,xwyp.num_of_case
    ;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    BEGIN
      <<xwyp_loop>>
      FOR l_xwyp_rec IN xwyp_cur LOOP
        INSERT INTO xxcop_loct_inv (
           transaction_id
          ,loct_id
          ,loct_code
          ,organization_id
          ,organization_code
          ,item_id
          ,item_no
          ,lot_id
          ,lot_no
          ,manufacture_date
          ,expiration_date
          ,unique_sign
          ,lot_status
          ,loct_onhand
          ,schedule_date
          ,shipment_date
          ,voucher_no
          ,transaction_type
          ,simulate_flag
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
        SELECT gn_transaction_id                                          transaction_id
              ,xliv.loct_id                                               loct_id
              ,xliv.loct_code                                             loct_code
              ,xliv.organization_id                                       organization_id
              ,xliv.organization_code                                     organization_code
              ,xliv.item_id                                               item_id
              ,xliv.item_no                                               item_no
              ,xliv.lot_id                                                lot_id
              ,xliv.lot_no                                                lot_no
              ,xliv.manufacture_date                                      manufacture_date
              ,xliv.expiration_date                                       expiration_date
              ,xliv.unique_sign                                           unique_sign
              ,xliv.lot_status                                            lot_status
              ,TRUNC(SUM(xliv.loct_onhand) / l_xwyp_rec.num_of_case)      loct_onhand
              ,xliv.schedule_date                                         schedule_date
              ,xliv.shipment_date                                         shipment_date
              ,NULL                                                       voucher_no
              ,cv_xli_type_inv                                            transaction_type
              ,NULL                                                       simulate_flag
              ,cn_created_by                                              created_by
              ,cd_creation_date                                           creation_date
              ,cn_last_updated_by                                         last_updated_by
              ,cd_last_update_date                                        last_update_date
              ,cn_last_update_login                                       last_update_login
              ,cn_request_id                                              request_id
              ,cn_program_application_id                                  program_application_id
              ,cn_program_id                                              program_id
              ,cd_program_update_date                                     program_update_date
        FROM xxcop_loct_inv_v           xliv
        WHERE xliv.item_id            = l_xwyp_rec.item_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
          AND xliv.shipment_date     <= gd_allocated_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
          AND EXISTS(
                SELECT 'X'
                FROM xxcop_wk_yoko_locations  xwyl
                WHERE xwyl.transaction_id = gn_transaction_id
                  AND xwyl.request_id     = cn_request_id
                  AND xwyl.item_id        = l_xwyp_rec.item_id
                  AND xwyl.loct_id        = xliv.loct_id
                UNION ALL
                SELECT 'X'
                FROM xxcop_wk_yoko_locations  xwyl
                WHERE xwyl.transaction_id = gn_transaction_id
                  AND xwyl.request_id     = cn_request_id
                  AND xwyl.item_id        = l_xwyp_rec.item_id
                  AND xwyl.frq_loct_id    = xliv.loct_id
              )
        GROUP BY xliv.loct_id
                ,xliv.loct_code
                ,xliv.organization_id
                ,xliv.organization_code
                ,xliv.item_id
                ,xliv.item_no
                ,xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
                ,xliv.schedule_date
                ,xliv.shipment_date
        ;
      END LOOP xwyp_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xli
                     );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END create_xli;
--
  /**********************************************************************************
   * Procedure Name   : get_msd_schedule
   * Description      : ��v��g�����U�N�V�����쐬(B-7)
   ***********************************************************************************/
  PROCEDURE get_msd_schedule(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msd_schedule'; -- �v���O������
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    -- ===============================
    -- B-14. �����v��莝�݌Ƀe�[�u���o�^(�H��o�׌v��)
    -- ===============================
    entry_xli_fs(
       ov_errbuf             => lv_errbuf
      ,ov_retcode            => lv_retcode
      ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- B-15. �����v��莝�݌Ƀe�[�u���o�^(�w���v��)
    -- ===============================
    entry_xli_po(
       ov_errbuf             => lv_errbuf
      ,ov_retcode            => lv_retcode
      ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END get_msd_schedule;
--
  /**********************************************************************************
   * Procedure Name   : get_shipment_schedule
   * Description      : �����v��莝�݌Ƀe�[�u���o�^(�o�׃y�[�X)(B-8)
   ***********************************************************************************/
  PROCEDURE get_shipment_schedule(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_schedule'; -- �v���O������
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
    lt_latest_shipment_date   xxcop_loct_inv.schedule_date%TYPE;
    ln_working_day            NUMBER;       --�ғ����`�F�b�N
--
    -- *** ���[�J���E�J�[�\�� ***
    --�ړ���q�ɂ̎擾
    CURSOR rcpt_loct_cur IS
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--      SELECT xwyp.rcpt_loct_id                      rcpt_loct_id
--            ,xwyp.item_id                           item_id
--            ,xwyp.shipping_type                     shipping_type
--      FROM xxcop_wk_yoko_planning xwyp
--      WHERE xwyp.transaction_id   = gn_transaction_id
--        AND xwyp.request_id       = cn_request_id
--        AND xwyp.receipt_date     = gd_planning_date
--        AND xwyp.shipping_type    = NVL(gv_plan_type, xwyp.shipping_type)
--        AND CASE
--              WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
--                xwyp.shipping_pace
--              WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
--                xwyp.forecast_pace
--              ELSE
--                0
--            END > 0
--      GROUP BY xwyp.rcpt_loct_id
--              ,xwyp.item_id
--              ,xwyp.shipping_type
      WITH ship_loct_vw AS (
        SELECT xwyp.shipping_date                     shipping_date
              ,xwyp.ship_loct_id                      ship_loct_id
              ,xwyp.item_id                           item_id
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           = gd_planning_date
          AND xwyp.ship_organization_id  <> gn_source_org_id
        GROUP BY xwyp.shipping_date
                ,xwyp.ship_loct_id
                ,xwyp.item_id
      )
      SELECT MAX(receipt_date)                        receipt_date
            ,rcpt_loct_id                             rcpt_loct_id
            ,item_id                                  item_id
            ,shipping_type                            shipping_type
      FROM (
        SELECT xwyp.receipt_date                      receipt_date
              ,xwyp.rcpt_loct_id                      rcpt_loct_id
              ,xwyp.item_id                           item_id
              ,xwyp.shipping_type                     shipping_type
        FROM xxcop_wk_yoko_planning xwyp
            ,ship_loct_vw           slv
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           > gd_allocated_date
          AND xwyp.shipping_date          = slv.shipping_date
          AND xwyp.ship_loct_id           = slv.ship_loct_id
          AND xwyp.item_id                = slv.item_id
          AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
        UNION ALL
        SELECT xwyp.receipt_date                      receipt_date
              ,xwyp.rcpt_loct_id                      rcpt_loct_id
              ,xwyp.item_id                           item_id
              ,xwyp.shipping_type                     shipping_type
        FROM xxcop_wk_yoko_planning xwyp
            ,ship_loct_vw           slv
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.receipt_date           > gd_allocated_date
          AND xwyp.shipping_date          = slv.shipping_date
          AND xwyp.rcpt_loct_id           = slv.ship_loct_id
          AND xwyp.item_id                = slv.item_id
          AND xwyp.ship_organization_id   = gn_source_org_id
          AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
      )
      GROUP BY rcpt_loct_id
              ,item_id
              ,shipping_type
    ;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
--
    -- *** ���[�J���E���R�[�h ***
    l_gsat_tab                      g_sa_ttype;     --�o�׃y�[�X�݌Ɉ����R���N�V�����^
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    lt_latest_shipment_date   := NULL;
    ln_working_day            := NULL;
    l_gsat_tab.DELETE;
--
    --�o�׈����ϓ��ȍ~�̏ꍇ�A�o�׃y�[�X�������v��莝�݌Ƀe�[�u���ɓo�^
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_START
--    IF (gd_planning_date > gd_allocated_date) THEN
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_END
    <<rcpt_loct_loop>>
    FOR l_rcpt_rec IN rcpt_loct_cur LOOP
      BEGIN
        --�o�׃y�[�X�g�����U�N�V�������쐬���ꂽ���t���擾
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--        SELECT NVL(MAX(xli.schedule_date), gd_allocated_date)    latest_shipment_date
        SELECT NVL(MAX(xli.shipment_date), gd_allocated_date)    latest_shipment_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
        INTO lt_latest_shipment_date
        FROM xxcop_loct_inv xli
        WHERE xli.transaction_id   = gn_transaction_id
          AND xli.request_id       = cn_request_id
          AND xli.loct_id          = l_rcpt_rec.rcpt_loct_id
          AND xli.item_id          = l_rcpt_rec.item_id
          AND xli.transaction_type = cv_xli_type_sp
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--          AND xli.schedule_date    > gd_allocated_date
          AND xli.shipment_date    > gd_allocated_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
        ;
        --�o�׃y�[�X�g�����U�N�V�����������܂ō쐬����Ă���ꍇ�A�ȍ~���X�L�b�v
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--        IF (lt_latest_shipment_date >= gd_planning_date) THEN
        IF (lt_latest_shipment_date >= l_rcpt_rec.receipt_date) THEN
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          RAISE not_need_expt;
        END IF;
        --�q��-�i�ڂ̑N�x�������擾
        SELECT xwyp.item_id                                       item_id
              ,xwyp.item_no                                       item_no
              ,xwyp.rcpt_organization_id                          rcpt_organization_id
              ,xwyp.rcpt_organization_code                        rcpt_organization_code
              ,xwyp.rcpt_loct_id                                  rcpt_loct_id
              ,xwyp.rcpt_loct_code                                rcpt_loct_code
              ,xwyp.rcpt_calendar_code                            rcpt_calendar_code
              ,xwyp.shipping_type                                 shipping_type
              ,CASE
                 WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                   xwyp.shipping_pace
                 WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                   xwyp.forecast_pace
                 ELSE
                   0
               END                                                shipping_pace
              ,xwyp.freshness_priority                            freshness_priority
              ,xwyp.freshness_class                               freshness_class
              ,xwyp.freshness_check_value                         freshness_check_value
              ,xwyp.freshness_adjust_value                        freshness_adjust_value
              ,xwyp.max_stock_days                                max_stock_days
              ,0                                                  allocate_quantity
        BULK COLLECT INTO l_gsat_tab
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id   = gn_transaction_id
          AND xwyp.request_id       = cn_request_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--          AND xwyp.receipt_date     = gd_planning_date
          AND xwyp.receipt_date     = l_rcpt_rec.receipt_date
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          AND xwyp.shipping_type    = l_rcpt_rec.shipping_type
          AND xwyp.rcpt_loct_id     = l_rcpt_rec.rcpt_loct_id
          AND xwyp.item_id          = l_rcpt_rec.item_id
          AND CASE
                WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                  xwyp.shipping_pace
                WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                  xwyp.forecast_pace
                ELSE
                  0
              END > 0
        GROUP BY xwyp.item_id
                ,xwyp.item_no
                ,xwyp.rcpt_organization_id
                ,xwyp.rcpt_organization_code
                ,xwyp.rcpt_loct_id
                ,xwyp.rcpt_loct_code
                ,xwyp.rcpt_calendar_code
                ,xwyp.shipping_type
                ,xwyp.freshness_priority
                ,xwyp.freshness_class
                ,xwyp.freshness_check_value
                ,xwyp.freshness_adjust_value
                ,xwyp.max_stock_days
                ,xwyp.shipping_pace
                ,xwyp.forecast_pace
        ORDER BY xwyp.freshness_priority
        ;
        --�i�ڂ̑S�Ă̑N�x�����ŏo�׃y�[�X��0�̏ꍇ�A�ȍ~���X�L�b�v
        IF (l_gsat_tab.COUNT = 0) THEN
          RAISE not_need_expt;
        END IF;
        --�o�׃y�[�X�g�����U�N�V�����𒅓��܂ō쐬
        lt_latest_shipment_date := lt_latest_shipment_date + 1;
        <<date_loop>>
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
--        WHILE (lt_latest_shipment_date <= gd_planning_date) LOOP
        WHILE (lt_latest_shipment_date <= l_rcpt_rec.receipt_date) LOOP
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
          --�ғ����`�F�b�N
          xxcop_common_pkg2.get_working_days(
             iv_calendar_code   => l_gsat_tab(1).rcpt_calendar_code
            ,in_organization_id => l_gsat_tab(1).rcpt_organization_id
            ,in_loct_id         => l_gsat_tab(1).rcpt_loct_id
            ,id_from_date       => lt_latest_shipment_date
            ,id_to_date         => lt_latest_shipment_date
            ,on_working_days    => ln_working_day
            ,ov_errbuf          => lv_errbuf
            ,ov_retcode         => lv_retcode
            ,ov_errmsg          => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --��ғ����̏ꍇ�A�X�L�b�v
          IF (ln_working_day > 0) THEN
            --�����v��莝�݌Ƀe�[�u���o�^�ɓo�^
            -- ===============================
            -- B-16�D�����v��莝�݌Ƀe�[�u���o�^(�o�׃y�[�X)
            -- ===============================
            entry_xli_shipment(
               it_shipment_date   => lt_latest_shipment_date
              ,io_gsat_tab        => l_gsat_tab
              ,ov_errbuf          => lv_errbuf
              ,ov_retcode         => lv_retcode
              ,ov_errmsg          => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
          --���t���C���N�������g
          lt_latest_shipment_date := lt_latest_shipment_date + 1;
        END LOOP date_loop;
      EXCEPTION
        WHEN not_need_expt THEN
          NULL;
      END;
    END LOOP rcpt_loct_loop;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_START
--    END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_END
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END get_shipment_schedule;
--
  /**********************************************************************************
   * Procedure Name   : create_yoko_plan
   * Description      : �����v��쐬(B-9)
   ***********************************************************************************/
  PROCEDURE create_yoko_plan(
    iv_assign_type   IN     VARCHAR2,       --   �����Z�b�g�敪
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_yoko_plan'; -- �v���O������
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
    lv_safety_result                VARCHAR2(1);    --���S�݌ɐ�����
    lv_stock_result                 VARCHAR2(1);    --�݌Ɉ�������
--
    l_item_tab                      g_item_ttype;   --�i�ڃR���N�V�����^
    l_ship_tab                      g_loct_ttype;   --�ړ����q�ɃR���N�V�����^
    l_rcpt_tab                      g_loct_ttype;   --�ړ���q�ɃR���N�V�����^
    l_gfqt_tab                      g_fq_ttype;     --�N�x�����ʍ݌Ɉ����R���N�V�����^
    l_gbqt_tab                      g_bq_ttype;     --�ړ����q�Ƀo�����X�����v��R���N�V�����^
    l_xwypo_tab                     g_xwypo_ttype;  --�����v��o�̓��[�N�e�[�u���R���N�V�����^
    l_git_tab                       g_idx_ttype;    --�C���f�b�N�X�R���N�V�����^
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    lv_safety_result                := NULL;
    lv_stock_result                 := NULL;
    l_item_tab.DELETE;
    l_ship_tab.DELETE;
    l_rcpt_tab.DELETE;
    l_gfqt_tab.DELETE;
    l_gbqt_tab.DELETE;
    l_xwypo_tab.DELETE;
    l_git_tab.DELETE;
--
    -- ===============================
    -- �ړ���q�ɂ̎擾
    -- ===============================
    SELECT xwyp.rcpt_loct_id              loct_id
          ,xwyp.rcpt_loct_code            loct_code
          ,NULL                           delivery_lead_time
          ,NULL                           shipping_pace
          ,NULL                           target_date
    BULK COLLECT INTO l_rcpt_tab
    FROM xxcop_wk_yoko_planning xwyp
    WHERE xwyp.transaction_id        = gn_transaction_id
      AND xwyp.request_id            = cn_request_id
      AND xwyp.planning_flag         = cv_planning_yes
      AND xwyp.receipt_date          = gd_planning_date
      AND xwyp.assignment_set_type   = iv_assign_type
      AND xwyp.shipping_type         = NVL(gv_plan_type, xwyp.shipping_type)
      AND CASE
            WHEN xwyp.shipping_type  = cv_plan_type_shipped  THEN
              xwyp.shipping_pace
            WHEN xwyp.shipping_type  = cv_plan_type_forecate THEN
              xwyp.forecast_pace
            ELSE
              0
          END > 0
      AND xwyp.ship_organization_id <> gn_source_org_id
    GROUP BY xwyp.rcpt_loct_id
            ,xwyp.rcpt_loct_code
            ,xwyp.sy_manufacture_date
    ORDER BY MIN(xwyp.shipping_date)
            ,xwyp.sy_manufacture_date
            ,xwyp.rcpt_loct_code
    ;
    <<rcpt_loop>>
    FOR ln_rcpt_idx IN 1 .. l_rcpt_tab.COUNT LOOP
      -- ===============================
      -- �i�ڂ̎擾
      -- ===============================
      SELECT xwyp.item_id               item_id
            ,xwyp.item_no               item_no
      BULK COLLECT INTO l_item_tab
      FROM xxcop_wk_yoko_planning xwyp
      WHERE xwyp.transaction_id        = gn_transaction_id
        AND xwyp.request_id            = cn_request_id
        AND xwyp.planning_flag         = cv_planning_yes
        AND xwyp.receipt_date          = gd_planning_date
        AND xwyp.assignment_set_type   = iv_assign_type
        AND xwyp.shipping_type         = NVL(gv_plan_type, xwyp.shipping_type)
        AND CASE
              WHEN xwyp.shipping_type  = cv_plan_type_shipped  THEN
                xwyp.shipping_pace
              WHEN xwyp.shipping_type  = cv_plan_type_forecate THEN
                xwyp.forecast_pace
              ELSE
                0
            END > 0
        AND xwyp.ship_organization_id <> gn_source_org_id
        AND xwyp.rcpt_loct_id          = l_rcpt_tab(ln_rcpt_idx).loct_id
      GROUP BY xwyp.item_id
              ,xwyp.item_no
      ORDER BY xwyp.item_no
      ;
      <<item_loop>>
      FOR ln_item_idx IN 1 .. l_item_tab.COUNT LOOP
        BEGIN
          -- ===============================
          -- �N�x�����擾
          -- ===============================
          SELECT xwyp.freshness_priority          freshness_priority
                ,xwyp.freshness_condition         freshness_condition
                ,xwyp.freshness_class             freshness_class
                ,xwyp.freshness_check_value       freshness_check_value
                ,xwyp.freshness_adjust_value      freshness_adjust_value
                ,xwyp.safety_stock_days           safety_stock_days
                ,xwyp.max_stock_days              max_stock_days
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              shipping_pace
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.safety_stock_days * xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.safety_stock_days * xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              safety_stock_quantity
                ,CASE
                   WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                     xwyp.max_stock_days * xwyp.total_shipping_pace
                   WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                     xwyp.max_stock_days * xwyp.total_forecast_pace
                   ELSE
                     0
                 END                              max_stock_quantity
                ,0                                allocate_quantity
                ,xwyp.sy_manufacture_date         sy_manufacture_date
                ,xwyp.sy_maxmum_quantity          sy_maxmum_quantity
                ,xwyp.sy_stocked_quantity         sy_stocked_quantity
          BULK COLLECT INTO l_gfqt_tab
          FROM xxcop_wk_yoko_planning xwyp
          WHERE xwyp.transaction_id      = gn_transaction_id
            AND xwyp.request_id          = cn_request_id
            AND xwyp.planning_flag       = cv_planning_yes
            AND xwyp.receipt_date        = gd_planning_date
            AND xwyp.assignment_set_type = iv_assign_type
            AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
            AND xwyp.rcpt_loct_id        = l_rcpt_tab(ln_rcpt_idx).loct_id
            AND xwyp.item_id             = l_item_tab(ln_item_idx).item_id
            AND CASE
                  WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                    xwyp.max_stock_days * xwyp.total_shipping_pace
                  WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                    xwyp.max_stock_days * xwyp.total_forecast_pace
                  ELSE
                    0
                END > 0
          GROUP BY xwyp.freshness_priority
                  ,xwyp.freshness_condition
                  ,xwyp.freshness_class
                  ,xwyp.freshness_check_value
                  ,xwyp.freshness_adjust_value
                  ,xwyp.safety_stock_days
                  ,xwyp.max_stock_days
                  ,xwyp.shipping_type
                  ,xwyp.total_shipping_pace
                  ,xwyp.total_forecast_pace
                  ,xwyp.sy_manufacture_date
                  ,xwyp.sy_maxmum_quantity
                  ,xwyp.sy_stocked_quantity
          ORDER BY xwyp.freshness_priority DESC
          ;
          --�i�ڂ̑S�Ă̑N�x�������ΏۊO�̏ꍇ�A�ȍ~���X�L�b�v
          IF (l_gfqt_tab.COUNT = 0) THEN
            RAISE not_need_expt;
          END IF;
          -- ===============================
          -- B-17�D���S�݌ɂ̌v�Z
          -- ===============================
          proc_safety_quantity(
             iv_assign_type   => iv_assign_type
            ,it_loct_id       => l_rcpt_tab(ln_rcpt_idx).loct_id
            ,i_item_rec       => l_item_tab(ln_item_idx)
            ,io_gfqt_tab      => l_gfqt_tab
            ,ov_stock_result  => lv_stock_result
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --���S�݌Ɉȏ�݌ɂ�����ꍇ�A�ȍ~���X�L�b�v
          IF (lv_stock_result = cv_enough) THEN
            --�f�o�b�N���b�Z�[�W�o��(���S�݌ɂ���)
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                              || 'rcpt_loct_check:'
                              || 'safe_balance_proc:'
                              || iv_assign_type                     || ','
                              || l_rcpt_tab(ln_rcpt_idx).loct_code  || ','
                              || l_item_tab(ln_item_idx).item_no    || ','
            );
            RAISE not_need_expt;
          END IF;
          --�f�o�b�N���b�Z�[�W�o��(���S�݌ɂȂ�)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                            || 'rcpt_loct_check:'
                            || 'need_balance_proc:'
                            || iv_assign_type                     || ','
                            || l_rcpt_tab(ln_rcpt_idx).loct_code  || ','
                            || l_item_tab(ln_item_idx).item_no    || ','
          );
          -- ===============================
          -- �ړ����q�Ɏ擾
          -- ===============================
          WITH xwyp_ship_vw AS (
            SELECT xwyp.ship_loct_id              ship_loct_id
                  ,xwyp.ship_loct_code            ship_loct_code
                  ,xwyp.delivery_lead_time        delivery_lead_time
                  ,xwyp.shipping_date             shipping_date
            FROM xxcop_wk_yoko_planning xwyp
            WHERE xwyp.transaction_id         = gn_transaction_id
              AND xwyp.request_id             = cn_request_id
              AND xwyp.planning_flag          = cv_planning_yes
              AND xwyp.receipt_date           = gd_planning_date
              AND xwyp.assignment_set_type    = iv_assign_type
              AND xwyp.ship_organization_id  <> gn_source_org_id
              AND xwyp.shipping_type          = NVL(gv_plan_type, xwyp.shipping_type)
              AND xwyp.rcpt_loct_id           = l_rcpt_tab(ln_rcpt_idx).loct_id
              AND xwyp.item_id                = l_item_tab(ln_item_idx).item_id
            GROUP BY xwyp.ship_loct_id
                    ,xwyp.ship_loct_code
                    ,xwyp.delivery_lead_time
                    ,xwyp.shipping_date
          )
          , xwyp_rcpt_vw AS (
            SELECT xrv.ship_loct_id               ship_loct_id
                  ,xrv.rcpt_loct_id               rcpt_loct_id
                  ,xrv.shipping_pace              shipping_pace
            FROM (
              SELECT xwyp.ship_loct_id            ship_loct_id
                    ,xwyp.rcpt_loct_id            rcpt_loct_id
                    ,SUM(CASE
                           WHEN xwyp.shipping_type = cv_plan_type_shipped  THEN
                             xwyp.shipping_pace
                           WHEN xwyp.shipping_type = cv_plan_type_forecate THEN
                             xwyp.forecast_pace
                           ELSE
                             0
                         END)                     shipping_pace
                    ,ROW_NUMBER() OVER (PARTITION BY xwyp.rcpt_loct_id
                                        ORDER BY     xwyp.ship_loct_id
                                  )               row_number
              FROM xxcop_wk_yoko_planning xwyp
                  ,xwyp_ship_vw           xsv
              WHERE xwyp.transaction_id      = gn_transaction_id
                AND xwyp.request_id          = cn_request_id
                AND xwyp.receipt_date        = gd_planning_date
                AND xwyp.assignment_set_type = iv_assign_type
                AND xwyp.shipping_type       = NVL(gv_plan_type, xwyp.shipping_type)
                AND xwyp.rcpt_loct_id        = xsv.ship_loct_id
                AND xwyp.item_id             = l_item_tab(ln_item_idx).item_id
              GROUP BY xwyp.rcpt_loct_id
                      ,xwyp.ship_loct_id
            ) xrv
            WHERE xrv.row_number = 1
          )
          SELECT xsv.ship_loct_id                 loct_id
                ,xsv.ship_loct_code               loct_code
                ,xsv.delivery_lead_time           delivery_lead_time
                ,NVL(xrv.shipping_pace, 0)        shipping_pace 
                ,xsv.shipping_date                target_date
          BULK COLLECT INTO l_ship_tab
          FROM xwyp_ship_vw xsv
              ,xwyp_rcpt_vw xrv
          WHERE xsv.ship_loct_id = xrv.rcpt_loct_id(+)
          ;
          -- ===============================
          -- B-18�D�ړ����q�ɂ̓���
          -- ===============================
          proc_ship_loct(
             i_item_rec       => l_item_tab(ln_item_idx)
            ,i_ship_tab       => l_ship_tab
            ,i_gfqt_tab       => l_gfqt_tab
            ,o_git_tab        => l_git_tab
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          --�f�o�b�N���b�Z�[�W�o��
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => '=============================================================='
          );
          <<balance_loop>>
          FOR ln_git_idx IN l_git_tab.FIRST .. l_git_tab.LAST LOOP
            --�f�o�b�N���b�Z�[�W�o��
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => cv_indent_2 || cv_prg_name || ':'
                              || 'ship_loct_code:'
                              || '(' || ln_git_idx || ')' || ','
                              || l_ship_tab(l_git_tab(ln_git_idx)).loct_code || ','
                              || l_item_tab(ln_item_idx).item_no             || ','
                              || TO_CHAR(l_ship_tab(l_git_tab(ln_git_idx)).target_date, cv_date_format) || ','
            );
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
            SAVEPOINT pre_balance_proc_svp;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
            -- ===============================
            -- B-19�D�o�����X�v�搔�̌v�Z
            -- ===============================
            proc_balance_quantity(
               iv_assign_type   => iv_assign_type
              ,i_item_rec       => l_item_tab(ln_item_idx)
              ,i_ship_rec       => l_ship_tab(l_git_tab(ln_git_idx))
              ,i_rcpt_rec       => l_rcpt_tab(ln_rcpt_idx)
              ,i_gfqt_tab       => l_gfqt_tab
              ,o_gbqt_tab       => l_gbqt_tab
              ,o_xwypo_tab      => l_xwypo_tab
              ,ov_stock_result  => lv_stock_result
              ,ov_errbuf        => lv_errbuf
              ,ov_retcode       => lv_retcode
              ,ov_errmsg        => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_START
----
--            BEGIN
--              --�o�����X�v�搔�̃g�����U�N�V�������폜
--              DELETE xxcop_loct_inv xli
--              WHERE xli.transaction_id    = gn_transaction_id
--                AND xli.request_id        = cn_request_id
--                AND xli.transaction_type  = cv_xli_type_bq
--                AND xli.simulate_flag     = cv_simulate_yes
--              ;
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                NULL;
--              WHEN OTHERS THEN
--                lv_errbuf := SQLERRM;
--                lv_errmsg := xxccp_common_pkg.get_msg(
--                                iv_application  => cv_msg_appl_cont
--                               ,iv_name         => cv_msg_00042
--                               ,iv_token_name1  => cv_msg_00042_token_1
--                               ,iv_token_value1 => cv_table_xli
--                             );
--                RAISE global_api_expt;
--            END;
            ROLLBACK TO SAVEPOINT pre_balance_proc_svp;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_MOD_END
--
            --�o�����X�v�Z���ʂ𔻒�
            IF (lv_stock_result IN (cv_complete, cv_incomplete)) THEN
              --�o�����X�v�Z�ňړ����q�ɂ���ړ���q�ɂɈړ����\�ȏꍇ
              -- ===============================
              -- B-20�D�v�惍�b�g�̌���
              -- ===============================
              proc_lot_quantity(
                 i_item_rec             => l_item_tab(ln_item_idx)
                ,i_ship_rec             => l_ship_tab(l_git_tab(ln_git_idx))
                ,i_rcpt_rec             => l_rcpt_tab(ln_rcpt_idx)
                ,it_sy_manufacture_date => l_gfqt_tab(1).sy_manufacture_date
                ,io_gbqt_tab            => l_gbqt_tab
                ,io_xwypo_tab           => l_xwypo_tab
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
                ,ov_stock_result        => lv_stock_result
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
                ,ov_errbuf              => lv_errbuf
                ,ov_retcode             => lv_retcode
                ,ov_errmsg              => lv_errmsg
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_api_expt;
              END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_START
--              --�S�Ă̑N�x�����ōő�݌ɂ܂ŉ����v�悪�ł����ꍇ�A�ȍ~���X�L�b�v
--              IF (lv_stock_result = cv_complete) THEN
--                EXIT balance_loop;
--              END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_DEL_END
            END IF;
            -- ===============================
            -- B-21�D�����v��莝�݌Ƀe�[�u���o�^(�v��s��)
            -- ===============================
            entry_supply_failed(
               i_rcpt_rec       => l_rcpt_tab(ln_rcpt_idx)
              ,io_xwypo_tab     => l_xwypo_tab
              ,ov_errbuf        => lv_errbuf
              ,ov_retcode       => lv_retcode
              ,ov_errmsg        => lv_errmsg
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
            --�S�Ă̑N�x�����ōő�݌ɂ܂ŉ����v�悪�ł����ꍇ�A�ȍ~���X�L�b�v
            IF (lv_stock_result = cv_complete) THEN
              EXIT balance_loop;
            END IF;
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
          END LOOP balance_loop;
--
          BEGIN
            --�Ώۑq�ɈȊO�̃g�����U�N�V�������폜
            DELETE xxcop_loct_inv xli
            WHERE xli.transaction_id    = gn_transaction_id
              AND xli.request_id        = cn_request_id
              AND xli.simulate_flag     = cv_simulate_yes
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            WHEN OTHERS THEN
              lv_errbuf := SQLERRM;
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_appl_cont
                             ,iv_name         => cv_msg_00042
                             ,iv_token_name1  => cv_msg_00042_token_1
                             ,iv_token_value1 => cv_table_xli
                           );
              RAISE global_api_expt;
          END;
--
        EXCEPTION
          WHEN not_need_expt THEN
            NULL;
        END;
      END LOOP item_loop;
    END LOOP rcpt_loop;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END create_yoko_plan;
--
  /**********************************************************************************
   * Procedure Name   : output_xwypo
   * Description      : �����v��CSV���`(B-10)
   ***********************************************************************************/
  PROCEDURE output_xwypo(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_xwypo'; -- �v���O������
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
    ln_plan_min_quantity      NUMBER;                     --�v�搔�i�ŏ��j
    ln_plan_max_quantity      NUMBER;                     --�v�搔�i�ő�j
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xwypo_cur IS
      WITH xwypo_supply_vw AS (
        SELECT xwypo.transaction_id                             transaction_id
              ,xwypo.request_id                                 request_id
              ,xwypo.shipping_date                              shipping_date
              ,xwypo.receipt_date                               receipt_date
              ,xwypo.ship_loct_id                               ship_loct_id
              ,xwypo.rcpt_loct_id                               rcpt_loct_id
              ,xwypo.item_id                                    item_id
              ,xwypo.freshness_condition                        freshness_condition
              ,xwypo.assignment_set_type                        assignment_set_type
              ,CASE WHEN SUM(xwypo.plan_lot_quantity) >= (xwypo.max_stock_quantity - MIN(xwypo.before_stock))
                 THEN cv_supply_enough
                 ELSE cv_supply_shortage
               END                                              supply_status
        FROM xxcop_wk_yoko_plan_output  xwypo
        WHERE xwypo.transaction_id      = gn_transaction_id
          AND xwypo.request_id          = cn_request_id
        GROUP BY xwypo.transaction_id
                ,xwypo.request_id
                ,xwypo.shipping_date
                ,xwypo.receipt_date
                ,xwypo.ship_loct_id
                ,xwypo.rcpt_loct_id
                ,xwypo.item_id
                ,xwypo.freshness_condition
                ,xwypo.assignment_set_type
                ,xwypo.max_stock_quantity
      )
      , xwypo_rcpt_supply_vw AS (
        SELECT xsv.transaction_id                               transaction_id
              ,xsv.request_id                                   request_id
              ,xsv.receipt_date                                 receipt_date
              ,xsv.rcpt_loct_id                                 rcpt_loct_id
              ,xsv.item_id                                      item_id
              ,xsv.freshness_condition                          freshness_condition
              ,MAX(xsv.supply_status)                           supply_status
        FROM xwypo_supply_vw            xsv
        GROUP BY xsv.transaction_id
                ,xsv.request_id
                ,xsv.receipt_date
                ,xsv.rcpt_loct_id
                ,xsv.item_id
                ,xsv.freshness_condition
      )
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
      , xwypo_rcpt_lot_vw AS (
        SELECT xwypov.transaction_id                              transaction_id
              ,xwypov.request_id                                  request_id
              ,xwypov.receipt_date                                receipt_date
              ,xwypov.rcpt_loct_id                                rcpt_loct_id
              ,xwypov.item_id                                     item_id
              ,xwypov.freshness_condition                         freshness_condition
              ,xwypov.manufacture_date                            manufacture_date
              ,MIN(xwypov.before_lot_stock)                       before_lot_stock
        FROM (
          SELECT xwypo.transaction_id                             transaction_id
                ,xwypo.request_id                                 request_id
                ,xwypo.shipping_date                              shipping_date
                ,xwypo.receipt_date                               receipt_date
                ,xwypo.ship_loct_id                               ship_loct_id
                ,xwypo.rcpt_loct_id                               rcpt_loct_id
                ,xwypo.item_id                                    item_id
                ,xwypo.freshness_condition                        freshness_condition
                ,xwypo.assignment_set_type                        assignment_set_type
                ,xwypo.manufacture_date                           manufacture_date
                ,SUM(xwypo.before_lot_stock)                      before_lot_stock
          FROM xxcop_wk_yoko_plan_output    xwypo
          WHERE xwypo.transaction_id      = gn_transaction_id
            AND xwypo.request_id          = cn_request_id
            AND xwypo.manufacture_date   IS NOT NULL
          GROUP BY xwypo.transaction_id
                  ,xwypo.request_id
                  ,xwypo.shipping_date
                  ,xwypo.receipt_date
                  ,xwypo.ship_loct_id
                  ,xwypo.rcpt_loct_id
                  ,xwypo.item_id
                  ,xwypo.freshness_condition
                  ,xwypo.assignment_set_type
                  ,xwypo.manufacture_date
        ) xwypov
        GROUP BY xwypov.transaction_id
                ,xwypov.request_id
                ,xwypov.receipt_date
                ,xwypov.rcpt_loct_id
                ,xwypov.item_id
                ,xwypov.freshness_condition
                ,xwypov.manufacture_date
      )
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
      SELECT xwypo.rowid                                        xwypo_rowid
            ,xwypo.transaction_id                               transaction_id
            ,xwypo.request_id                                   request_id
            ,xwypo.shipping_date                                shipping_date
            ,xwypo.receipt_date                                 receipt_date
            ,xwypo.ship_loct_id                                 ship_loct_id
            ,xwypo.rcpt_loct_id                                 rcpt_loct_id
            ,xwypo.item_id                                      item_id
            ,xwypo.freshness_condition                          freshness_condition
            ,xwypo.assignment_set_type                          assignment_set_type
            ,xwypo.manufacture_date                             manufacture_date
            ,xwypo.safety_stock_quantity                        safety_stock_quantity
            ,xwypo.max_stock_quantity                           max_stock_quantity
            ,xwypo.before_stock                                 before_stock
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_START
--            ,SUM(xwypo.before_lot_stock) OVER (PARTITION BY xwypo.transaction_id
--                                                           ,xwypo.request_id
--                                                           ,xwypo.shipping_date
--                                                           ,xwypo.receipt_date
--                                                           ,xwypo.ship_loct_id
--                                                           ,xwypo.rcpt_loct_id
--                                                           ,xwypo.item_id
--                                                           ,xwypo.freshness_condition
--                                                           ,xwypo.assignment_set_type
--                                                           ,xwypo.manufacture_date
--                                         )                      before_lot_stock
            ,NVL(xrlv.before_lot_stock, xwypo.before_lot_stock) before_lot_stock
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_MOD_END
            ,SUM(xwypo.plan_lot_quantity) OVER (PARTITION BY xwypo.transaction_id
                                                            ,xwypo.request_id
                                                            ,xwypo.shipping_date
                                                            ,xwypo.receipt_date
                                                            ,xwypo.ship_loct_id
                                                            ,xwypo.rcpt_loct_id
                                                            ,xwypo.item_id
                                                            ,xwypo.freshness_condition
                                                            ,xwypo.assignment_set_type
                                                            ,xwypo.manufacture_date
                                          )                     plan_lot_quantity
            ,DENSE_RANK() OVER (PARTITION BY xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                ORDER BY     xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                          )                                     output_num
            ,ROW_NUMBER() OVER (PARTITION BY xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                                ORDER BY     xwypo.transaction_id
                                            ,xwypo.request_id
                                            ,xwypo.shipping_date
                                            ,xwypo.receipt_date
                                            ,xwypo.ship_loct_code
                                            ,xwypo.rcpt_loct_code
                                            ,xwypo.item_no
                                            ,xwypo.freshness_condition
                                            ,xwypo.assignment_set_type
                                            ,xwypo.manufacture_date
                          )                                     duplex_num
            ,xrsv.supply_status                                 supply_status
      FROM xxcop_wk_yoko_plan_output    xwypo
          ,xwypo_rcpt_supply_vw         xrsv
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
          ,xwypo_rcpt_lot_vw            xrlv
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
      WHERE xwypo.transaction_id      = gn_transaction_id
        AND xwypo.request_id          = cn_request_id
        AND xwypo.transaction_id      = xrsv.transaction_id
        AND xwypo.request_id          = xrsv.request_id
        AND xwypo.receipt_date        = xrsv.receipt_date
        AND xwypo.rcpt_loct_id        = xrsv.rcpt_loct_id
        AND xwypo.item_id             = xrsv.item_id
        AND xwypo.freshness_condition = xrsv.freshness_condition
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_START
        AND xwypo.transaction_id      = xrlv.transaction_id(+)
        AND xwypo.request_id          = xrlv.request_id(+)
        AND xwypo.receipt_date        = xrlv.receipt_date(+)
        AND xwypo.rcpt_loct_id        = xrlv.rcpt_loct_id(+)
        AND xwypo.item_id             = xrlv.item_id(+)
        AND xwypo.freshness_condition = xrlv.freshness_condition(+)
        AND xwypo.manufacture_date    = xrlv.manufacture_date(+)
--20091217_Ver3.1_E_�{�ғ�_00519_SCS.Goto_ADD_END
    ;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    --������
    ln_plan_min_quantity      := NULL;
    ln_plan_max_quantity      := NULL;
--
    <<xwypo_loop>>
    FOR l_xwypo_rec IN xwypo_cur LOOP
      IF (l_xwypo_rec.duplex_num = 1) THEN
        --�v�搔�i�ŏ��j�̌v�Z
        ln_plan_min_quantity := l_xwypo_rec.safety_stock_quantity - l_xwypo_rec.before_stock
        ;
        --�v�搔�i�ő�j�̌v�Z
        ln_plan_max_quantity := l_xwypo_rec.max_stock_quantity    - l_xwypo_rec.before_stock
        ;
        --�o�͍��ڂ̍X�V
        UPDATE xxcop_wk_yoko_plan_output xwypo
        SET    xwypo.plan_min_quantity    = GREATEST(ln_plan_min_quantity, 0)
              ,xwypo.plan_max_quantity    = GREATEST(ln_plan_max_quantity, 0)
              ,xwypo.plan_lot_quantity    = l_xwypo_rec.plan_lot_quantity
              ,xwypo.before_lot_stock     = l_xwypo_rec.before_lot_stock
              ,xwypo.after_lot_stock      = l_xwypo_rec.before_lot_stock + l_xwypo_rec.plan_lot_quantity
              ,xwypo.special_yoko_flag    = CASE WHEN l_xwypo_rec.assignment_set_type = cv_base_plan
                                              THEN NULL
                                              ELSE cv_csv_mark
                                            END
              ,xwypo.short_supply_flag    = CASE WHEN l_xwypo_rec.supply_status = cv_supply_enough
                                              THEN NULL
                                              ELSE cv_csv_mark
                                            END
              ,xwypo.output_num           = l_xwypo_rec.output_num
        WHERE xwypo.rowid               = l_xwypo_rec.xwypo_rowid
        ;
      ELSE
        --�d�������N�����̍폜
        DELETE xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.rowid = l_xwypo_rec.xwypo_rowid
        ;
      END IF;
    END LOOP xwypo_loop;
--
    --�����v��o�̓��[�N�e�[�u���X�V
    UPDATE xxcop_wk_yoko_plan_output xwypo
    SET    xwypo.output_flag        = cv_output_on
    WHERE xwypo.transaction_id      = gn_transaction_id
      AND xwypo.request_id          = cn_request_id
    ;
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END output_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
    ,ov_errbuf              OUT    VARCHAR2                 --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT    VARCHAR2                 --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT    VARCHAR2                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_planning_date_from          DATE;    --
    ld_planning_date_to            DATE;    --
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
    --������
    ld_planning_date_from          := NULL;
    ld_planning_date_to            := NULL;
--
    BEGIN
      -- ===============================
      -- B-1�D��������
      -- ===============================
      init(
         iv_planning_date_from => iv_planning_date_from       -- �v�旧�Ċ���(FROM)
        ,iv_planning_date_to   => iv_planning_date_to         -- �v�旧�Ċ���(TO)
        ,iv_plan_type          => iv_plan_type                -- �o�׌v��敪
        ,iv_shipment_date_from => iv_shipment_date_from       -- �o�׃y�[�X�v�����(FROM)
        ,iv_shipment_date_to   => iv_shipment_date_to         -- �o�׃y�[�X�v�����(TO)
        ,iv_forecast_date_from => iv_forecast_date_from       -- �o�ח\������(FROM)
        ,iv_forecast_date_to   => iv_forecast_date_to         -- �o�ח\������(TO)
        ,iv_allocated_date     => iv_allocated_date           -- �o�׈����ϓ�
        ,iv_item_code          => iv_item_code                -- �i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
       ,iv_working_days        => iv_working_days             -- �ғ�����
       ,iv_stock_adjust_value  => iv_stock_adjust_value       -- �݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
        ,ov_errbuf             => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode            => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg             => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-2�D�����v�搧��}�X�^�擾
      -- ===============================
      get_msr_route(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE obsolete_skip_expt;
      ELSIF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-3�D��\�q�Ɏ擾
      -- ===============================
      entry_xwyl(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-4�D�o�׃y�[�X�̌v�Z
      -- ===============================
      proc_shipping_pace(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-5�D���o�׃y�[�X�̌v�Z
      -- ===============================
      proc_total_pace(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-6�D�莝�݌Ƀe�[�u���쐬
      -- ===============================
      create_xli(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- B-7. ��v��g�����U�N�V�����쐬
      -- ===============================
      get_msd_schedule(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- �v�旧�Ċ���(FROM-TO)
      -- ===============================
      <<planning_loop>>
      FOR l_planning_rec IN (
        SELECT xwyp.receipt_date    receipt_date
        FROM xxcop_wk_yoko_planning xwyp
        WHERE xwyp.transaction_id         = gn_transaction_id
          AND xwyp.request_id             = cn_request_id
          AND xwyp.planning_flag          = cv_planning_yes
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_START
          AND xwyp.ship_organization_id  <> gn_source_org_id
--20100125_Ver3.3_E_�{�ғ�_01250_SCS.Goto_ADD_END
        GROUP BY xwyp.receipt_date
        ORDER BY xwyp.receipt_date
      ) LOOP
        gd_planning_date := l_planning_rec.receipt_date;
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => '========================================' || ','
        );
        --�f�o�b�N���b�Z�[�W�o��(�v�旧�ē�)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => cv_prg_name || ':' || 'planning_date:'
                          || TO_CHAR(gd_planning_date, cv_date_format)  || ','
        );
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => '========================================' || ','
        );
        -- ===============================
        -- B-8�D�o�׃g�����U�N�V�����쐬
        -- ===============================
        get_shipment_schedule(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- B-9. �����v��쐬(���ʉ����v��)
        -- ===============================
        create_yoko_plan(
           iv_assign_type   => cv_custom_plan   -- �����Z�b�g�敪(���ʉ����v��)
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- B-9. �����v��쐬(��{�����v��)
        -- ===============================
        create_yoko_plan(
           iv_assign_type   => cv_base_plan     -- �����Z�b�g�敪(��{�����v��)
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        -- �v�旧�ē����C���N�������g
        gd_planning_date := gd_planning_date + 1;
      END LOOP planning_loop;
--
      -- ===============================
      -- B-10. �����v��CSV���`
      -- ===============================
      output_xwypo(
         ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
    EXCEPTION
      WHEN global_process_expt THEN
        --�Ώی����A�G���[�����̃J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        gn_error_cnt  := gn_error_cnt + 1;
        --SQLERRM���b�Z�[�W���ݒ肳��Ă���ꍇ�A���ʗ�O
        IF (lv_errbuf IS NOT NULL) THEN
          RAISE global_process_expt;
        ELSE
          RAISE internal_api_expt;
        END IF;
      WHEN obsolete_skip_expt THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN internal_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
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
     errbuf                 OUT    VARCHAR2                 --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                OUT    VARCHAR2                 --   �G���[�R�[�h     #�Œ�#
    ,iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
--    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --�ُ�I�����b�Z�[�W
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; --�ُ�I�����b�Z�[�W
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
       iv_planning_date_from => iv_planning_date_from       -- �v�旧�Ċ���(FROM)
      ,iv_planning_date_to   => iv_planning_date_to         -- �v�旧�Ċ���(TO)
      ,iv_plan_type          => iv_plan_type                -- �o�׌v��敪
      ,iv_shipment_date_from => iv_shipment_date_from       -- �o�׃y�[�X�v�����(FROM)
      ,iv_shipment_date_to   => iv_shipment_date_to         -- �o�׃y�[�X�v�����(TO)
      ,iv_forecast_date_from => iv_forecast_date_from       -- �o�ח\������(FROM)
      ,iv_forecast_date_to   => iv_forecast_date_to         -- �o�ח\������(TO)
      ,iv_allocated_date     => iv_allocated_date           -- �o�׈����ϓ�
      ,iv_item_code          => iv_item_code                -- �i�ڃR�[�h
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_START
      ,iv_working_days       => iv_working_days             -- �ғ�����
      ,iv_stock_adjust_value => iv_stock_adjust_value       -- �݌ɓ��������l
--20100203_Ver3.4_E_�{�ғ�_01222_SCS.Goto_ADD_END
      ,ov_errbuf             => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (gv_debug_mode IS NOT NULL) AND (gv_log_buffer IS NOT NULL) THEN
      --�󔒍s�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
    END IF;
    IF (lv_retcode <> cv_status_normal) THEN
      --�G���[�o��(CSV�o�͂̂��߃��O�ɏo��)
      IF (lv_errmsg IS NOT NULL) THEN
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF (lv_errbuf IS NOT NULL) THEN
        --�V�X�e���G���[�̕ҏW
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00041
                       ,iv_token_name1  => cv_msg_00041_token_1
                       ,iv_token_value1 => lv_errbuf
                     );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
      --��s�}��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff => gv_out_msg
--    );
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
    --���[�N�e�[�u���̓��e���c������COMMIT����
    COMMIT;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOP006A011C;
/
