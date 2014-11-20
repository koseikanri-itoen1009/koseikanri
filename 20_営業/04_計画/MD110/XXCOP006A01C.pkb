CREATE OR REPLACE PACKAGE BODY APPS.XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(body)
 * Description      : �����v��
 * MD.050           : �����v�� MD050_COP_006_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  entry_xwypo            �����v��o�̓��[�N�e�[�u���o�^
 *  fix_delivery_unit      �z���P�ʂ̌���
 *  fix_plan_lots          �v�惍�b�g�̌���
 *  proc_maximum_plan_qty  �v�搔(�ő�)�̌v�Z
 *  proc_minimum_plan_qty  �v�搔(�ŏ�)�̌v�Z
 *  proc_balance_plan_qty  �v�搔(�o�����X)�̌v�Z
 *  get_stock_quantity     �݌ɐ��̎擾
 *  entry_xwsp             �����v�惏�[�N�e�[�u���o�^
 *  proc_ship_pace         �o�׃y�[�X�̌v�Z
 *  chk_route_prereq       �o�H�̑O������`�F�b�N
 *  get_ship_route         �o�בq�Ɍo�H�擾
 *  delete_table           �e�[�u���f�[�^�폜
 *  init                   ��������(A-1)
 *  get_msr_route          �����v�搧��}�X�^�擾(A-2)
 *  get_xwsp               �����v�惏�[�N�e�[�u���擾(A-3)
 *  output_xwypo           �����v��CSV�o��(A-4)
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
  past_date_invalid_expt    EXCEPTION;     -- �ߋ����`�F�b�N�G���[
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
  profile_invalid_expt      EXCEPTION;     -- �v���t�@�C���l�G���[
  stock_days_expt           EXCEPTION;     -- �݌ɓ����`�F�b�N�G���[
  no_condition_expt         EXCEPTION;     -- �N�x�������o�^�G���[
  no_working_days_expt      EXCEPTION;     -- �ғ����G���[
  obsolete_skip_expt        EXCEPTION;     -- �p�~�X�L�b�v��O
  short_supply_expt         EXCEPTION;     -- �݌ɕs����O
  nested_loop_expt          EXCEPTION;     -- �K�w���[�v�G���[
  zero_divide_expt          EXCEPTION;     -- �[�����Z�G���[
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A01C';           -- �p�b�P�[�W��
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
  --���b�Z�[�W��
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- �v���t�@�C���l�擾���s
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';       -- �Ώۃf�[�^�Ȃ�
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';       -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';       -- �l�t�]���b�Z�[�W
  cv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';       -- �o�^�����G���[���b�Z�[�W
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';       -- CSV�A�E�g�v�b�g�@�\�V�X�e���G���[���b�Z�[�W
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';       -- �폜�����G���[���b�Z�[�W
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';       -- ���������̓��b�Z�[�W
  cv_msg_00050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00050';       -- �q�ɏ��擾�G���[
  cv_msg_00053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00053';       -- �z�����[�h�^�C���擾�G���[
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';       -- �p�����[�^�G���[
  cv_msg_00056              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00056';       -- �ݒ���Ԓ��ғ����`�F�b�N�G���[���b�Z�[�W
  cv_msg_00057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00057';       -- �z���P�ʎ擾�G���[
  cv_msg_00058              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00058';       -- ���[���v�Z�s���G���[���b�Z�[�W
  cv_msg_00059              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00059';       -- �z���P�ʃ[���G���[
  cv_msg_00060              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00060';       -- �o�H��񃋁[�v�G���[���b�Z�[�W
  cv_msg_00061              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00061';       -- �P�[�X�����s���G���[���b�Z�[�W
  cv_msg_10038              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10038';       -- �N�x�������o�^�G���[
  cv_msg_10039              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10039';       -- �J�n�����N�������o�^�G���[
  cv_msg_10040              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10040';       -- �o�בq�ɑN�x�������o�^�G���[
  cv_msg_10041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10041';       -- �N�x�����݌ɓ����`�F�b�N�G���[
  --���b�Z�[�W�g�[�N��
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_00050_token_1      CONSTANT VARCHAR2(100) := 'ORGID';
  cv_msg_00053_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE_FROM';
  cv_msg_00053_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE_TO';
  cv_msg_00056_token_1      CONSTANT VARCHAR2(100) := 'FROM_DATE';
  cv_msg_00056_token_2      CONSTANT VARCHAR2(100) := 'TO_DATE';
  cv_msg_00057_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00058_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME1';
  cv_msg_00058_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NAME2';
  cv_msg_00059_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00060_token_1      CONSTANT VARCHAR2(100) := 'WHSE_NAME';
  cv_msg_00061_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_10038_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10039_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10040_token_1      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  cv_msg_10041_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10041_token_2      CONSTANT VARCHAR2(100) := 'WHSE_CODE';
  --���b�Z�[�W�g�[�N���l
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '�����v��o�̓��[�N�e�[�u��';
  cv_table_xwsp             CONSTANT VARCHAR2(100) := '�����v�惏�[�N�e�[�u��';
  cv_msg_00058_value_1      CONSTANT VARCHAR2(100) := '�v�搔';
  cv_msg_00058_value_2      CONSTANT VARCHAR2(100) := '�o�׃y�[�X';
  cv_msg_10041_value_1      CONSTANT VARCHAR2(100) := '�݌Ɉێ�����';
  cv_msg_10041_value_2      CONSTANT VARCHAR2(100) := '�ő�݌ɓ���';
  --���̓p�����[�^
  cv_plan_type_tl           CONSTANT VARCHAR2(100) := '�v��敪';
  gv_shipment_from_tl       CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����(FROM)';
  gv_shipment_to_tl         CONSTANT VARCHAR2(100) := '�o�׃y�[�X�v�����(TO)';
  cv_forcast_type_tl        CONSTANT VARCHAR2(100) := '�o�ח\���敪';
  --�v���t�@�C��
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_upf_master_org_id      CONSTANT VARCHAR2(100) := 'XXCMN:�}�X�^�g�D';
  cv_pf_dummy_src_org_id    CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_upf_dummy_src_org_id   CONSTANT VARCHAR2(100) := 'XXCOP�F�_�~�[�o�בg�D';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_upf_fresh_buffer_days  CONSTANT VARCHAR2(100) := 'XXCOP�F�N�x�����o�b�t�@����';
  cv_pf_deadline_months     CONSTANT VARCHAR2(100) := 'XXCOP1_DEADLINE_MONTHS';
  cv_upf_deadline_months    CONSTANT VARCHAR2(100) := 'XXCOP�F�ŏI��������';
  cv_pf_deadline_days       CONSTANT VARCHAR2(100) := 'XXCOP1_DEADLINE_BUFFER_DAYS';
  cv_upf_deadline_days      CONSTANT VARCHAR2(100) := 'XXCOP�F�ŏI�����o�b�t�@����';
  --�N�C�b�N�R�[�h�^�C�v
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_lot_status         CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_flv_unit_delivery      CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --�v��敪
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- �o�׃y�[�X
  cv_plan_type_fgorcate     CONSTANT VARCHAR2(100) := '2';                      -- �o�ח\��
  --�o�ח\���敪
  cv_forcast_type_this      CONSTANT VARCHAR2(100) := '1';                      -- ������
  cv_forcast_type_next      CONSTANT VARCHAR2(100) := '2';                      -- ������
  cv_forcast_type_2month    CONSTANT VARCHAR2(100) := '3';                      -- �����{������
  --�����Z�b�g�敪
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- ��{�����v��
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- ���ʉ����v��
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- �H��o�׌v��
  --�N�x�����̕���
  cv_condition_general      CONSTANT VARCHAR2(1)   := '0';                      -- ���
  cv_condition_expiration   CONSTANT VARCHAR2(1)   := '1';                      -- �ܖ������
  cv_condition_manufacture  CONSTANT VARCHAR2(1)   := '2';                      -- �������
  --�v��^�C�v
  cv_plan_balance           CONSTANT VARCHAR2(1)   := '0';                      -- �o�����X
  cv_plan_minimum           CONSTANT VARCHAR2(1)   := '1';                      -- �ŏ�
  cv_plan_maximum           CONSTANT VARCHAR2(1)   := '2';                      -- �ő�
  --�z���P��
  cv_unit_palette           CONSTANT VARCHAR2(10)  := '1';                      -- �p���b�g
  cv_unit_step              CONSTANT VARCHAR2(10)  := '2';                      -- �i
  cv_unit_case              CONSTANT VARCHAR2(10)  := '3';                      -- �P�[�X
--
  --���i�敪
  cv_product_class_drink    CONSTANT VARCHAR2(1)   := '2';                      -- ���i�敪-�h�����N
  --�i�ڃJ�e�S���}�X�^
  cv_xicv_status            CONSTANT VARCHAR2(8)   := 'Inactive';               -- 
  cn_xicv_inactive          CONSTANT NUMBER := 1;                               -- 
  cn_xsr_plan_item          CONSTANT NUMBER := 1;                               -- �v�揤�i
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
  --DISC�i�ڃA�h�I���}�X�^
  cn_xsib_status_temporary  CONSTANT NUMBER := 20;                              -- ���o�^
  cn_xsib_status_registered CONSTANT NUMBER := 30;                              -- �{�o�^
  cn_xsib_status_obsolete   CONSTANT NUMBER := 40;                              -- �p
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
  --���o�ɗ\����r���[
  cv_xstv_status            CONSTANT VARCHAR2(1)   := '1';                      -- �\��
--
  --CSV�t�@�C���o�̓t�H�[�}�b�g
  cv_csv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';               -- �N����
  cv_csv_char_bracket       CONSTANT VARCHAR2(1)   := '"';                      -- �_�u���N�H�[�e�[�V����
  cv_csv_delimiter          CONSTANT VARCHAR2(1)   := ',';                      -- �J���}
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- �A�X�^���X�N
  --CSV�t�@�C���o�̓w�b�_�[
  cv_put_column_01          CONSTANT VARCHAR2(100) := '�o�ד�';                 -- 
  cv_put_column_02          CONSTANT VARCHAR2(100) := '����';                   -- 
  cv_put_column_03          CONSTANT VARCHAR2(100) := '�ړ����q�ɂb�c';         -- 
  cv_put_column_04          CONSTANT VARCHAR2(100) := '�ړ����q�ɖ�';           -- 
  cv_put_column_05          CONSTANT VARCHAR2(100) := '�ړ���q�ɂb�c';         -- 
  cv_put_column_06          CONSTANT VARCHAR2(100) := '�ړ���q�ɖ�';           -- 
  cv_put_column_07          CONSTANT VARCHAR2(100) := '�i�ڂb�c';               -- 
  cv_put_column_08          CONSTANT VARCHAR2(100) := '�i�ږ�';                 -- 
  cv_put_column_09          CONSTANT VARCHAR2(100) := '�N�x����';               -- 
  cv_put_column_10          CONSTANT VARCHAR2(100) := '�����N����';             -- 
  cv_put_column_11          CONSTANT VARCHAR2(100) := '�i��';                   -- 
  cv_put_column_12          CONSTANT VARCHAR2(100) := '�v�搔(�ŏ�)';           -- 
  cv_put_column_13          CONSTANT VARCHAR2(100) := '�v�搔(�ő�)';           -- 
  cv_put_column_14          CONSTANT VARCHAR2(100) := '�v�搔(�o�����X)';       -- 
  cv_put_column_15          CONSTANT VARCHAR2(100) := '�z���P��';               -- 
  cv_put_column_16          CONSTANT VARCHAR2(100) := '�����O�݌�';             -- 
  cv_put_column_17          CONSTANT VARCHAR2(100) := '������݌�';             -- 
  cv_put_column_18          CONSTANT VARCHAR2(100) := '���S�݌�';               -- 
  cv_put_column_19          CONSTANT VARCHAR2(100) := '�ő�݌�';               -- 
  cv_put_column_20          CONSTANT VARCHAR2(100) := '�o�׃y�[�X';             -- 
  cv_put_column_21          CONSTANT VARCHAR2(100) := '���ʉ�����';             -- 
  cv_put_column_22          CONSTANT VARCHAR2(100) := '��[�s��';               -- 
  cv_put_column_23          CONSTANT VARCHAR2(100) := '���b�g�t�]';             -- 
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�����v�惏�[�N�e�[�u���R���N�V�����^
  TYPE g_xwsp_ttype IS TABLE OF xxcop_wk_ship_planning%ROWTYPE
    INDEX BY BINARY_INTEGER;
  --�����v��o�̓��[�N�e�[�u���R���N�V�����^
  TYPE g_xwypo_ttype IS TABLE OF xxcop_wk_yoko_plan_output%ROWTYPE
    INDEX BY BINARY_INTEGER;
--
  --�����v�惏�[�N�e�[�u���q�ɏ��Q�ƃ��R�[�h�^
  TYPE g_xwsp_ref_rtype IS RECORD (
     item_id                 xxcop_wk_ship_planning.item_id%TYPE
    ,item_no                 xxcop_wk_ship_planning.item_no%TYPE
    ,ship_org_id             xxcop_wk_ship_planning.ship_org_id%TYPE
    ,ship_org_code           xxcop_wk_ship_planning.ship_org_code%TYPE
    ,shipping_date           xxcop_wk_ship_planning.shipping_date%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,manufacture_date        xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,shipping_pace           xxcop_wk_ship_planning.shipping_pace%TYPE
    ,stock_maintenance_days  xxcop_wk_ship_planning.stock_maintenance_days%TYPE
    ,max_stock_days          xxcop_wk_ship_planning.max_stock_days%TYPE
  );
  --�����v�惏�[�N�e�[�u���q�ɏ��Q�ƃR���N�V�����^
  TYPE g_xwsp_ref_ttype IS TABLE OF g_xwsp_ref_rtype
    INDEX BY BINARY_INTEGER;
  --�����v��o�̓��[�N�e�[�u���q�ɏ��Q�ƃ��R�[�h�^
  TYPE g_xwypo_ref_rtype IS RECORD (
     transaction_id          xxcop_wk_yoko_plan_output.transaction_id%TYPE
    ,shipping_date           xxcop_wk_yoko_plan_output.shipping_date%TYPE
    ,receipt_date            xxcop_wk_yoko_plan_output.receipt_date%TYPE
    ,ship_org_code           xxcop_wk_yoko_plan_output.ship_org_code%TYPE
    ,ship_org_name           xxcop_wk_yoko_plan_output.ship_org_name%TYPE
    ,receipt_org_code        xxcop_wk_yoko_plan_output.receipt_org_code%TYPE
    ,receipt_org_name        xxcop_wk_yoko_plan_output.receipt_org_name%TYPE
    ,item_id                 xxcop_wk_yoko_plan_output.item_id%TYPE
    ,item_no                 xxcop_wk_yoko_plan_output.item_no%TYPE
    ,item_name               xxcop_wk_yoko_plan_output.item_name%TYPE
    ,freshness_priority      xxcop_wk_yoko_plan_output.freshness_priority%TYPE
    ,freshness_condition     xxcop_wk_yoko_plan_output.freshness_condition%TYPE
    ,manu_date               xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,plan_min_qty            xxcop_wk_yoko_plan_output.plan_min_qty%TYPE
    ,plan_max_qty            xxcop_wk_yoko_plan_output.plan_max_qty%TYPE
    ,plan_bal_qty            xxcop_wk_yoko_plan_output.plan_bal_qty%TYPE
    ,plan_lot_qty            xxcop_wk_yoko_plan_output.plan_lot_qty%TYPE
    ,delivery_unit           xxcop_wk_yoko_plan_output.delivery_unit%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock             xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_days             xxcop_wk_yoko_plan_output.safety_days%TYPE
    ,max_days                xxcop_wk_yoko_plan_output.max_days%TYPE
    ,shipping_pace           xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,under_lvl_pace          xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,special_yoko_type       xxcop_wk_yoko_plan_output.special_yoko_type%TYPE
    ,supp_bad_type           xxcop_wk_yoko_plan_output.supp_bad_type%TYPE
    ,lot_revers_type         xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
    ,earliest_manu_date      xxcop_wk_yoko_plan_output.earliest_manu_date%TYPE
    ,start_manu_date         xxcop_wk_yoko_plan_output.start_manu_date%TYPE
    ,num_of_case             xxcop_wk_ship_planning.num_of_case%TYPE
    ,palette_max_cs_qty      xxcop_wk_ship_planning.palette_max_cs_qty%TYPE
    ,palette_max_step_qty    xxcop_wk_ship_planning.palette_max_step_qty%TYPE
  );
  --�����v��o�̓��[�N�e�[�u���q�ɏ��Q�ƃR���N�V�����^
  TYPE g_xwypo_ref_ttype IS TABLE OF g_xwypo_ref_rtype
    INDEX BY BINARY_INTEGER;
  --�N�x�������R�[�h�^
  TYPE g_freshness_condition_rtype IS RECORD (
     freshness_condition     xxcop_wk_ship_planning.freshness_condition%TYPE
    ,stock_maintenance_days  xxcop_wk_ship_planning.stock_maintenance_days%TYPE
    ,max_stock_days          xxcop_wk_ship_planning.max_stock_days%TYPE
  );
  --�N�x�����R���N�V�����^
  TYPE g_freshness_condition_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
  --�N�x�����D�揇�ʃ��R�[�h�^
  TYPE g_condition_priority_rtype IS RECORD (
     freshness_priority      xxcop_wk_ship_planning.freshness_priority%TYPE
    ,freshness_condition     xxcop_wk_ship_planning.freshness_condition%TYPE
    ,condition_type          fnd_lookup_values.attribute1%TYPE
    ,condition_value         NUMBER
  );
  --�N�x�����D�揇�ʃR���N�V�����^
  TYPE g_condition_priority_ttype IS TABLE OF g_condition_priority_rtype
    INDEX BY BINARY_INTEGER;
  --�v�搔�v�Z���R�[�h�^
  TYPE g_proc_plan_rtype IS RECORD (
     stock_quantity          NUMBER               -- �݌ɐ�
    ,stock_days              NUMBER               -- �݌ɓ���
    ,require_quantity        NUMBER               -- �v���݌ɐ�
    ,require_days            NUMBER               -- �v���݌ɓ���
    ,crunch_quantity         NUMBER               -- �s���݌ɐ�
    ,margin_quantity         NUMBER               -- �]�T�݌ɐ�
    ,margin_stock_days       NUMBER               -- �]�T�݌ɓ���
  );
  --�v�搔�v�Z�R���N�V�����^
  TYPE g_proc_plan_ttype IS TABLE OF g_proc_plan_rtype
    INDEX BY BINARY_INTEGER;
  --�������b�g���R�[�h�^
  TYPE g_manufacture_lot_rtype IS RECORD (
     lot_quantity            xxcop_wk_yoko_plan_output.plan_lot_qty%TYPE
    ,manufacture_date        xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,lot_revers              xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
  );
  --�������b�g�R���N�V�����^
  TYPE g_manufacture_lot_ttype IS TABLE OF g_manufacture_lot_rtype
    INDEX BY BINARY_INTEGER;
  --�����v��o�̓��[�N�e�[�u��CSV�o�̓��R�[�h�^
  TYPE g_xwypo_csv_rtype IS RECORD (
     shipping_date           xxcop_wk_yoko_plan_output.shipping_date%TYPE
    ,receipt_date            xxcop_wk_yoko_plan_output.receipt_date%TYPE
    ,ship_org_code           xxcop_wk_yoko_plan_output.ship_org_code%TYPE
    ,ship_org_name           xxcop_wk_yoko_plan_output.ship_org_name%TYPE
    ,receipt_org_code        xxcop_wk_yoko_plan_output.receipt_org_code%TYPE
    ,receipt_org_name        xxcop_wk_yoko_plan_output.receipt_org_name%TYPE
    ,item_no                 xxcop_wk_yoko_plan_output.item_no%TYPE
    ,item_name               xxcop_wk_yoko_plan_output.item_name%TYPE
    ,manu_date               xxcop_wk_yoko_plan_output.manu_date%TYPE
    ,lot_status              xxcop_wk_yoko_plan_output.lot_status%TYPE
    ,plan_min_qty            xxcop_wk_yoko_plan_output.plan_min_qty%TYPE
    ,plan_max_qty            xxcop_wk_yoko_plan_output.plan_max_qty%TYPE
    ,plan_bal_qty            xxcop_wk_yoko_plan_output.plan_bal_qty%TYPE
    ,delivery_unit           xxcop_wk_yoko_plan_output.delivery_unit%TYPE
    ,before_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,after_stock             xxcop_wk_yoko_plan_output.after_stock%TYPE
    ,safety_stock            xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,max_stock               xxcop_wk_yoko_plan_output.before_stock%TYPE
    ,shipping_pace           xxcop_wk_yoko_plan_output.shipping_pace%TYPE
    ,special_yoko_type       xxcop_wk_yoko_plan_output.special_yoko_type%TYPE
    ,supp_bad_type           xxcop_wk_yoko_plan_output.supp_bad_type%TYPE
    ,lot_revers_type         xxcop_wk_yoko_plan_output.lot_revers_type%TYPE
    ,freshness_condition     fnd_lookup_values.description%TYPE
    ,quality_type            fnd_lookup_values.meaning%TYPE
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
    ,num_of_case             NUMBER
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
  );
  --�����v��o�̓��[�N�e�[�u��CSV�o�̓R���N�V�����^
  TYPE g_xwypo_csv_ttype IS TABLE OF g_xwypo_csv_rtype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_debug_mode             VARCHAR2(256);                                      --�f�o�b�N���[�h
  gn_group_id               NUMBER;                                             --�����v��O���[�vID
  gd_plan_date              DATE;                                               --�����v��쐬��
  --�N���p�����[�^
  gv_plan_type              VARCHAR2(1);                                        --�v��敪
  gd_shipment_from          DATE;                                               --�o�׃y�[�X�v�����FROM
  gd_shipment_to            DATE;                                               --�o�׃y�[�X�v�����TO
  gd_forcast_from           DATE;                                               --�o�ח\������FROM
  gd_forcast_to             DATE;                                               --�o�ח\������TO
  --�v���t�@�C���l
  gn_master_org_id          NUMBER;                                             --�}�X�^�g�DID
  gn_dummy_src_org_id       NUMBER;                                             --�_�~�[�o�בg�DID
  gn_freshness_buffer_days  NUMBER;                                             --�N�x�����o�b�t�@����
  gn_deadline_months        NUMBER;                                             --�ŏI��������
  gn_deadline_buffer_days   NUMBER;                                             --�ŏI�����o�b�t�@����
--
  /**********************************************************************************
   * Procedure Name   : entry_xwypo
   * Description      : �����v��o�̓��[�N�e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE entry_xwypo(
    i_xwypo_rec      IN     g_xwypo_ref_rtype,
    io_ml_tab        IN OUT g_manufacture_lot_ttype,
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    BEGIN
      IF ( io_ml_tab.COUNT = 0 ) THEN 
        io_ml_tab(1).lot_quantity     := NULL;
        io_ml_tab(1).manufacture_date := NULL;
        io_ml_tab(1).lot_status       := NULL;
        io_ml_tab(1).lot_revers       := NULL;
      END IF;
      <<entry_xwypo_loop>>
      FOR ln_lot_idx IN io_ml_tab.FIRST .. io_ml_tab.LAST LOOP
        --�����v��o�̓��[�N�e�[�u���o�^
        INSERT INTO xxcop_wk_yoko_plan_output(
           transaction_id
          ,group_id
          ,shipping_date
          ,receipt_date
          ,ship_org_code
          ,ship_org_name
          ,receipt_org_code
          ,receipt_org_name
          ,item_id
          ,item_no
          ,item_name
          ,freshness_priority
          ,freshness_condition
          ,manu_date
          ,lot_status
          ,plan_min_qty
          ,plan_max_qty
          ,plan_bal_qty
          ,plan_lot_qty
          ,delivery_unit
          ,before_stock
          ,after_stock
          ,safety_days
          ,max_days
          ,shipping_pace
          ,special_yoko_type
          ,supp_bad_type
          ,lot_revers_type
          ,earliest_manu_date
          ,start_manu_date
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        ) VALUES(
           cn_request_id
          ,gn_group_id
          ,i_xwypo_rec.shipping_date
          ,i_xwypo_rec.receipt_date
          ,i_xwypo_rec.ship_org_code
          ,i_xwypo_rec.ship_org_name
          ,i_xwypo_rec.receipt_org_code
          ,i_xwypo_rec.receipt_org_name
          ,i_xwypo_rec.item_id
          ,i_xwypo_rec.item_no
          ,i_xwypo_rec.item_name
          ,i_xwypo_rec.freshness_priority
          ,i_xwypo_rec.freshness_condition
          ,io_ml_tab(ln_lot_idx).manufacture_date
          ,io_ml_tab(ln_lot_idx).lot_status
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_min_qty
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_max_qty
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.plan_bal_qty
               ELSE NULL
           END
          ,io_ml_tab(ln_lot_idx).lot_quantity
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.delivery_unit
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.before_stock
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.after_stock
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.safety_days
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.max_days
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.under_lvl_pace
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.special_yoko_type
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.supp_bad_type
               ELSE NULL
           END
          ,io_ml_tab(ln_lot_idx).lot_revers
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.earliest_manu_date
               ELSE NULL
           END
          ,CASE
             WHEN ln_lot_idx = 1
               THEN i_xwypo_rec.start_manu_date
               ELSE NULL
           END
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
      END LOOP entry_xwypo_loop;
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
   * Procedure Name   : fix_delivery_unit
   * Description      : �z���P�ʂ̌���
   ***********************************************************************************/
  PROCEDURE fix_delivery_unit(
    io_xwypo_rec     IN OUT g_xwypo_ref_rtype,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fix_delivery_unit'; -- �v���O������
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
    ln_unit_quantity          NUMBER;              --�z���P�ʐ���
--
    -- *** ���[�J���E�J�[�\�� ***
    --�z���P�ʂ̊��
    CURSOR flv_cur IS
      SELECT flv.lookup_code             lookup_code
            ,flv.meaning                 meaning
            ,flv.description             description
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type            = cv_flv_unit_delivery
        AND flv.language               = cv_lang
        AND flv.source_lang            = cv_lang
        AND flv.enabled_flag           = cv_enable
        AND cd_sysdate BETWEEN NVL(flv.start_date_active, cd_sysdate)
                           AND NVL(flv.end_date_active, cd_sysdate)
      ORDER BY flv.lookup_code ASC;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    <<flv_loop>>
    FOR flv_rec IN flv_cur LOOP
      CASE
        WHEN flv_rec.lookup_code = cv_unit_palette THEN
          --�p���b�g�̊���Ŕ���
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case
                                                        / io_xwypo_rec.palette_max_cs_qty
                                                        / io_xwypo_rec.palette_max_step_qty;
        WHEN flv_rec.lookup_code = cv_unit_step THEN
          --�i�̊���Ŕ���
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case
                                                        / io_xwypo_rec.palette_max_cs_qty;
        WHEN flv_rec.lookup_code = cv_unit_case THEN
          --�P�[�X�̊���Ŕ���
          ln_unit_quantity := io_xwypo_rec.plan_bal_qty / io_xwypo_rec.num_of_case;
      END CASE;
      IF ( ln_unit_quantity > TO_NUMBER(flv_rec.description) ) THEN
        io_xwypo_rec.delivery_unit := flv_rec.meaning;
        EXIT flv_loop;
      END IF;
    END LOOP flv_loop;
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
  END fix_delivery_unit;
--
  /**********************************************************************************
   * Procedure Name   : fix_plan_lots
   * Description      : �v�惍�b�g�̌���
   ***********************************************************************************/
  PROCEDURE fix_plan_lots(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.�o�בq�ɏ��
    i_cp_rec         IN     g_condition_priority_rtype,
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.����q�ɏ��
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fix_plan_lots'; -- �v���O������
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
    ln_plan_quantity          NUMBER;
    ln_lot_idx                NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�N�x�����i��ʁj�̃��b�g
    CURSOR general_qty_cur( 
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPM���b�g�}�X�^
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --���o�ɗ\����r���[
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --�����v��o�̓��[�N�e�[�u��
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    --�N�x�����i�ܖ�������j�̃��b�g
    CURSOR expiration_qty_cur(
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPM���b�g�}�X�^
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --�N�x����
          AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                           + CEIL(( TO_DATE(ilm.attribute3, cv_date_format)
                                  - TO_DATE(ilm.attribute1, cv_date_format)
                                  ) / i_cp_rec.condition_value
                             )
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --���o�ɗ\����r���[
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --�N�x����
          AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format )
                           + CEIL(( TO_DATE(xstv.expiration_date , cv_date_format)
                                  - TO_DATE(xstv.manufacture_date, cv_date_format)
                                  ) / i_cp_rec.condition_value
                             )
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --�����v��o�̓��[�N�e�[�u��
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    --�N�x�����i��������j�̃��b�g
    CURSOR manufacture_qty_cur(
              in_item_id          NUMBER
             ,iv_whse_code        VARCHAR2
             ,id_plan_date        DATE
             ,in_stock_days       NUMBER
             ,id_manufacture_date DATE
    ) IS
      SELECT NVL(SUM(ilmv.lot_quantity), 0) lot_quantity
            ,ilmv.manufacture_date          manufacture_date
            ,ilmv.lot_status                lot_status
      FROM (
        --OPM���b�g�}�X�^
        SELECT ili.loct_onhand                                             lot_quantity
              ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,ic_loct_inv ili
            ,fnd_lookup_values flv
        WHERE ilm.item_id          = ili.item_id
          AND ilm.lot_id           = ili.lot_id
          AND ili.item_id          = in_item_id
          AND ili.whse_code        = iv_whse_code
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --�N�x����
          AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                           + i_cp_rec.condition_value
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(ilm.attribute1, cv_date_format) >= NVL(id_manufacture_date
                                                            ,TO_DATE(ilm.attribute1, cv_date_format))
        UNION ALL
        --���o�ɗ\����r���[
        SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) lot_quantity
              ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
              ,ilm.attribute23                                             lot_status
        FROM ic_lots_mst ilm
            ,xxcop_stc_trans_v xstv
            ,fnd_lookup_values flv
        WHERE ilm.item_id          = xstv.item_id
          AND ilm.lot_id           = xstv.lot_id
          AND xstv.item_id         = in_item_id
          AND xstv.whse_code       = iv_whse_code
          AND xstv.status          = cv_xstv_status
          AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                    AND id_plan_date
                                    AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
          --�ŏI�������[��
          AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                           - gn_deadline_buffer_days
          --�N�x����
          AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                           + i_cp_rec.condition_value
                           - in_stock_days
                           - gn_freshness_buffer_days
          --�J�n�����N����(���ʉ����v��)
          AND TO_DATE(xstv.manufacture_date, cv_date_format) >= NVL(id_manufacture_date
                                                                   ,TO_DATE(xstv.manufacture_date, cv_date_format))
        UNION ALL
        --�����v��o�̓��[�N�e�[�u��
        SELECT xwypo.plan_lot_qty * -1                                     lot_quantity
              ,xwypo.manu_date                                             manufacture_date
              ,xwypo.lot_status                                            lot_status
        FROM xxcop_wk_yoko_plan_output xwypo
        WHERE xwypo.transaction_id = cn_request_id
          AND xwypo.group_id       = gn_group_id
          AND xwypo.ship_org_code  = iv_whse_code
          AND xwypo.item_id        = in_item_id
      ) ilmv
      GROUP BY ilmv.manufacture_date
              ,ilmv.lot_status
      HAVING   SUM(ilmv.lot_quantity) > 0
      ORDER BY ilmv.manufacture_date ASC
              ,ilmv.lot_status       ASC;
--
    -- *** ���[�J���E���R�[�h ***
    l_ml_tab                  g_manufacture_lot_ttype;
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
    <<xwypo_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --�z���P�ʂ�����
      fix_delivery_unit(
         io_xwypo_rec        => io_xwypo_tab(ln_xwypo_idx)
        ,ov_errbuf           => lv_errbuf
        ,ov_retcode          => lv_retcode
        ,ov_errmsg           => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        IF ( lv_errbuf IS NULL ) THEN
          RAISE internal_api_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
--
      --������݌ɂ̐ݒ�
      io_xwypo_tab(ln_xwypo_idx).after_stock := io_xwypo_tab(ln_xwypo_idx).before_stock
                                              + io_xwypo_tab(ln_xwypo_idx).plan_bal_qty;
      --��[�s�t���O�̐ݒ�
      IF ( io_xwypo_tab(ln_xwypo_idx).after_stock
         < io_xwypo_tab(ln_xwypo_idx).max_days * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
      THEN
        io_xwypo_tab(ln_xwypo_idx).supp_bad_type := cv_csv_mark;
      END IF;
--
      IF ( io_xwypo_tab(ln_xwypo_idx).plan_bal_qty > 0 ) THEN
        --���b�g����̏�����
        ln_plan_quantity := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty;
        ln_lot_idx := 1;
  --
        IF ( i_cp_rec.condition_type = cv_condition_general ) THEN
          --�N�x�����i��ʁj
          <<general_lot_loop>>
          FOR l_lot_rec IN general_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --���b�g������
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --���b�g�Ɉ����ł��Ȃ������Z�o
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --���b�g�t�]�𔻒�
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT general_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP general_lot_loop;
        END IF;
  --
        IF ( i_cp_rec.condition_type = cv_condition_expiration ) THEN
          --�N�x�����i�ܖ�������j
          <<expiration_lot_loop>>
          FOR l_lot_rec IN expiration_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --���b�g������
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --���b�g�Ɉ����ł��Ȃ������Z�o
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --���b�g�t�]�𔻒�
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT expiration_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP expiration_lot_loop;
        END IF;
  --
        IF ( i_cp_rec.condition_type = cv_condition_manufacture ) THEN
          --�N�x�����i��������j
          <<manufacture_lot_loop>>
          FOR l_lot_rec IN manufacture_qty_cur(
                              i_xwsp_rec.item_id
                             ,i_xwsp_rec.ship_org_code
                             ,i_xwsp_rec.shipping_date
                             ,io_xwypo_tab(ln_xwypo_idx).max_days
                             ,io_xwypo_tab(ln_xwypo_idx).start_manu_date
                           ) LOOP
            IF ( l_lot_rec.lot_quantity > 0 ) THEN
              --���b�g������
              l_ml_tab(ln_lot_idx).lot_quantity     := LEAST(ln_plan_quantity, l_lot_rec.lot_quantity);
              l_ml_tab(ln_lot_idx).manufacture_date := l_lot_rec.manufacture_date;
              l_ml_tab(ln_lot_idx).lot_status       := l_lot_rec.lot_status;
              --���b�g�Ɉ����ł��Ȃ������Z�o
              ln_plan_quantity := ln_plan_quantity - l_ml_tab(ln_lot_idx).lot_quantity;
              --���b�g�t�]�𔻒�
              IF ( l_lot_rec.manufacture_date < io_xwypo_tab(ln_xwypo_idx).earliest_manu_date ) THEN
                l_ml_tab(ln_lot_idx).lot_revers := cv_csv_mark;
              END IF;
              EXIT manufacture_lot_loop WHEN ( ln_plan_quantity <= 0 );
              ln_lot_idx := ln_lot_idx + 1;
            END IF;
          END LOOP manufacture_lot_loop;
        END IF;
      END IF;
--
      --�����v��o�̓��[�N�e�[�u���o�^
      entry_xwypo(
         i_xwypo_rec         => io_xwypo_tab(ln_xwypo_idx)
        ,io_ml_tab           => l_ml_tab
        ,ov_errbuf           => lv_errbuf
        ,ov_retcode          => lv_retcode
        ,ov_errmsg           => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        IF ( lv_errbuf IS NULL ) THEN
          RAISE internal_api_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
      l_ml_tab.DELETE;
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
  END fix_plan_lots;
--
  /**********************************************************************************
   * Procedure Name   : proc_maximum_plan_qty
   * Description      : �v�搔(�ő�)�̌v�Z
   ***********************************************************************************/
  PROCEDURE proc_maximum_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.�o�בq�ɏ��
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.����q�ɏ��
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_maximum_plan_qty'; -- �v���O������
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
    ln_supplies_quantity      NUMBER;              --��[�\�݌ɐ�
    ln_shipping_pace          NUMBER;              --���o�׃y�[�X
    ln_crunch_quantity        NUMBER;              --���s���݌ɐ�
    ln_greatest_require_days  NUMBER;              --�v���݌ɓ����̍ő�l
    ln_greatest_stock_days    NUMBER;              --�݌ɓ���/�v���݌ɓ����̍ő�l
    ln_less_stock_days        NUMBER;              --�v���݌ɓ����̍ŏ��̎��_
    ln_least_stock_days       NUMBER;              --�v���݌ɓ����̍ŏ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_pp_tab                g_proc_plan_ttype;
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
    --���[�J���ϐ�������
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.3.1 �ړ����q�ɂ̕�[�\�݌ɐ����Z�o
    ln_supplies_quantity := i_xwsp_rec.before_stock - ( i_xwsp_rec.max_stock_days * i_xwsp_rec.shipping_pace );
--
    --3.3.2 �ړ���q�ɂ̈��S�݌ɓ����܂ŕ�[
    --�ړ���q�ɂ̕s���݌ɐ����W�v
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --������
      io_xwypo_tab(ln_xwypo_idx).plan_max_qty := 0;
      --�v���݌ɐ�/�v���݌ɓ����̎Z�o(�v��=���S�݌�)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --�݌ɐ�/�݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�s���݌ɐ�/�s���݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --���s���݌ɐ�/���s���݌ɓ����̏W�v
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --���o�׃y�[�X�̏W�v
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�v���݌ɓ����̍ő�l���擾
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --�݌ɓ���/�v���݌ɓ����̍ő�l���擾
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP safety_require_quantity_loop;
    --��[�\����0�ȉ��̏ꍇ
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --�ړ���q�ɂŕs���݌ɐ�������ꍇ
    IF ( ln_crunch_quantity > 0 ) THEN
      --�s���݌ɂ̕�[
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --��[�\�݌ɐ����s���݌ɐ��𖞂����Ă���ꍇ
        --�v���݌ɐ����v�搔(�ő�)�ɐݒ�
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --��[�\�݌ɐ����s���݌ɐ��ɖ����Ȃ��ꍇ
        --��[�|�C���g���Ɍv�搔(�ő�)��ݒ�
        <<safety_division_loop>>
        LOOP
          --������
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --�݌ɓ����̍ŏ��A�ŏ��̎��_���擾
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v���݌ɓ����ɖ����Ȃ��ꍇ
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --�݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --�v���݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --�ŏ��݌ɓ����Ɨv���݌ɓ����̍ő�l�������ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --���̕�[�|�C���g�܂ł̕s���݌ɐ����W�v
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�݌ɐ�����[�|�C���g�̎��_��菬��������
            --�v���݌ɓ����𒴂��Ă��Ȃ��ꍇ
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --�s���݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --���s���݌ɐ��̏W�v
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --�v���݌ɐ��𖞂����Ă���̂ŁA�s���݌ɐ��͂Ȃ�
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --�s���݌ɐ����Ȃ��ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --��[�|�C���g�܂ŕ�[�ł��邩���f
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��𖞂����Ă���ꍇ
            --�v���݌ɐ����v�搔(�ő�)�ɉ��Z
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�v�搔(�ő�)�����Z
              io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ő�)�����Z��̍݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ő�)�����Z��̍݌ɓ����̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --��[�\������s���݌ɐ������Z
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��ɖ����Ȃ��ꍇ
            --��[�\�����o�׃y�[�X�ň����Čv�搔(�ő�)�ɉ��Z
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --��[�\�����s���������ߏI��
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
    --���[�J���ϐ�������
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.3.2 �ړ���q�ɂ̍ő�݌ɓ����܂ŕ�[
    --�ړ���q�ɂ̕s���݌ɐ����W�v
    <<max_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --�v���݌ɐ�/�v���݌ɓ����̎Z�o(�v��=�ő�݌�)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(( io_xwypo_tab(ln_xwypo_idx).max_days
                                                       - io_xwypo_tab(ln_xwypo_idx).safety_days )
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).max_days
                                               - io_xwypo_tab(ln_xwypo_idx).safety_days;
      --�݌ɐ�/�݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,( io_xwypo_tab(ln_xwypo_idx).before_stock
                                                       + io_xwypo_tab(ln_xwypo_idx).plan_max_qty )
                                                     - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�s���݌ɐ�/�s���݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --���s���݌ɐ�/���s���݌ɓ����̏W�v
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --���o�׃y�[�X�̏W�v
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�v���݌ɓ����̍ő�l���擾
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --�݌ɓ���/�v���݌ɓ����̍ő�l���擾
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP max_require_quantity_loop;
    --��[�\����0�ȉ��̏ꍇ
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --�ړ���q�ɂŕs���݌ɐ�������ꍇ
    IF ( ln_crunch_quantity > 0 ) THEN
      --�s���݌ɂ̕�[
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --��[�\�݌ɐ����s���݌ɐ��𖞂����Ă���ꍇ
        --�v���݌ɐ����v�搔(�ő�)�ɐݒ�
        <<max_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP max_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --��[�\�݌ɐ����s���݌ɐ��ɖ����Ȃ��ꍇ
        --��[�|�C���g���Ɍv�搔(�ő�)��ݒ�
        <<max_division_loop>>
        LOOP
          --������
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --�݌ɓ����̍ŏ��A�ŏ��̎��_���擾
          <<max_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v���݌ɓ����ɖ����Ȃ��ꍇ
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --�݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --�v���݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP max_least_stock_days_loop;
          --�ŏ��݌ɓ����Ɨv���݌ɓ����̍ő�l�������ꍇ
          --��[�����̂��ߏI��
          EXIT max_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --���̕�[�|�C���g�܂ł̕s���݌ɐ����W�v
          <<max_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�݌ɐ�����[�|�C���g�̎��_��菬��������
            --�v���݌ɓ����𒴂��Ă��Ȃ��ꍇ
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --�s���݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --���s���݌ɐ��̏W�v
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --�v���݌ɐ��𖞂����Ă���̂ŁA�s���݌ɐ��͂Ȃ�
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP max_point_req_qty_loop;
          --�s���݌ɐ����Ȃ��ꍇ
          --��[�����̂��ߏI��
          EXIT max_division_loop WHEN ( ln_crunch_quantity = 0 );
          --��[�|�C���g�܂ŕ�[�ł��邩���f
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��𖞂����Ă���ꍇ
            --�v���݌ɐ����v�搔(�ő�)�ɉ��Z
            <<max_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�v�搔(�ő�)�����Z
              io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ő�)�����Z��̍݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ő�)�����Z��̍݌ɓ����̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP max_point_supply_loop;
            --��[�\������s���݌ɐ������Z
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��ɖ����Ȃ��ꍇ
            --��[�\�����o�׃y�[�X�ň����Čv�搔(�ő�)�ɉ��Z
            <<max_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_max_qty := io_xwypo_tab(ln_xwypo_idx).plan_max_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP max_pace_supply_loop;
            --��[�\�����s���������ߏI��
            RAISE short_supply_expt;
          END IF;
        END LOOP max_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
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
  END proc_maximum_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_minimum_plan_qty
   * Description      : �v�搔(�ŏ�)�̌v�Z
   ***********************************************************************************/
  PROCEDURE proc_minimum_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.�o�בq�ɏ��
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.����q�ɏ��
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_minimum_plan_qty'; -- �v���O������
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
    ln_supplies_quantity      NUMBER;              --��[�\�݌ɐ�
    ln_shipping_pace          NUMBER;              --���o�׃y�[�X
    ln_crunch_quantity        NUMBER;              --���s���݌ɐ�
    ln_greatest_require_days  NUMBER;              --�v���݌ɓ����̍ő�l
    ln_greatest_stock_days    NUMBER;              --�݌ɓ���/�v���݌ɓ����̍ő�l
    ln_less_stock_days        NUMBER;              --�v���݌ɓ����̍ŏ��̎��_
    ln_least_stock_days       NUMBER;              --�v���݌ɓ����̍ŏ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_pp_tab                g_proc_plan_ttype;
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
    --���[�J���ϐ�������
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.2.1 �ړ����q�ɂ̕�[�\�݌ɐ����Z�o
    ln_supplies_quantity := i_xwsp_rec.before_stock - ( i_xwsp_rec.max_stock_days * i_xwsp_rec.shipping_pace );
--
    --3.2.2 �ړ���q�ɂ̈��S�݌ɓ����܂ŕ�[
    --�ړ���q�ɂ̕s���݌ɐ����W�v
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --������
      io_xwypo_tab(ln_xwypo_idx).plan_min_qty := 0;
      --�v���݌ɐ�/�v���݌ɓ����̎Z�o(�v��=���S�݌�)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --�݌ɐ�/�݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�s���݌ɐ�/�s���݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --���s���݌ɐ�/���s���݌ɓ����̏W�v
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --���o�׃y�[�X�̏W�v
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�v���݌ɓ����̍ő�l���擾
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --�݌ɓ���/�v���݌ɓ����̍ő�l���擾
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
    END LOOP safety_require_quantity_loop;
    --��[�\����0�ȉ��̏ꍇ
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --�ړ���q�ɂŕs���݌ɐ�������ꍇ
    IF ( ln_crunch_quantity > 0 ) THEN
      --�s���݌ɂ̕�[
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --��[�\�݌ɐ����s���݌ɐ��𖞂����Ă���ꍇ
        --�v���݌ɐ����v�搔(�ŏ�)�ɐݒ�
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --��[�\�݌ɐ����s���݌ɐ��ɖ����Ȃ��ꍇ
        --��[�|�C���g���Ɍv�搔(�ŏ�)��ݒ�
        <<safety_division_loop>>
        LOOP
          --������
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --�݌ɓ����̍ŏ��A�ŏ��̎��_���擾
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v���݌ɓ����ɖ����Ȃ��ꍇ
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --�݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --�v���݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --�ŏ��݌ɓ����Ɨv���݌ɓ����̍ő�l�������ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --���̕�[�|�C���g�܂ł̕s���݌ɐ����W�v
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�݌ɐ�����[�|�C���g�̎��_��菬��������
            --�v���݌ɓ����𒴂��Ă��Ȃ��ꍇ
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --�s���݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --���s���݌ɐ��̏W�v
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --�v���݌ɐ��𖞂����Ă���̂ŁA�s���݌ɐ��͂Ȃ�
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --�s���݌ɐ����Ȃ��ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --��[�|�C���g�܂ŕ�[�ł��邩���f
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��𖞂����Ă���ꍇ
            --�v���݌ɐ����v�搔(�ŏ�)�ɉ��Z
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�v�搔(�ŏ�)�����Z
              io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ŏ�)�����Z��̍݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�ŏ�)�����Z��̍݌ɓ����̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --��[�\������s���݌ɐ������Z
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��ɖ����Ȃ��ꍇ
            --��[�\�����o�׃y�[�X�ň����Čv�搔(�ŏ�)�ɉ��Z
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_min_qty := io_xwypo_tab(ln_xwypo_idx).plan_min_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --��[�\�����s���������ߏI��
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
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
  END proc_minimum_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_balance_plan_qty
   * Description      : �v�搔(�o�����X)�̌v�Z
   ***********************************************************************************/
  PROCEDURE proc_balance_plan_qty(
    i_xwsp_rec       IN     g_xwsp_ref_rtype,    -- 1.�o�בq�ɏ��
    io_xwypo_tab     IN OUT g_xwypo_ref_ttype,   -- 2.����q�ɏ��
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_balance_plan_qty'; -- �v���O������
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
    ln_supplies_quantity      NUMBER;              --��[�\�݌ɐ�
    ln_shipping_pace          NUMBER;              --���o�׃y�[�X
    ln_crunch_quantity        NUMBER;              --���s���݌ɐ�
    ln_greatest_require_days  NUMBER;              --�v���݌ɓ����̍ő�l
    ln_greatest_stock_days    NUMBER;              --�݌ɓ���/�v���݌ɓ����̍ő�l
    ln_less_stock_days        NUMBER;              --�v���݌ɓ����̍ŏ��̎��_
    ln_least_stock_days       NUMBER;              --�v���݌ɓ����̍ŏ�
    ln_so_margin_quantity     NUMBER;              --�ړ����q�ɗ]�T�݌ɐ�
    ln_ro_margin_quantity     NUMBER;              --�ړ���q�ɑ��]�T�ݐ�
    ln_so_margin_stock_days   NUMBER;              --�ړ����q�ɗ]�T�݌ɓ���
    ln_ro_margin_stock_days   NUMBER;              --�ړ���q�ɑ��]�T�݌ɓ���
    ln_ro_shipping_pace       NUMBER;              --�ړ���q�ɑ��o�׃y�[�X
    ln_balance_days           NUMBER;              --�o�����X�݌ɓ���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_pp_tab                g_proc_plan_ttype;
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
    --���[�J���ϐ�������
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
    ln_ro_margin_quantity    := 0;
    ln_ro_margin_stock_days  := 0;
    ln_ro_shipping_pace      := 0;
--
    --�ړ����q�ɂ̗]�T�݌ɐ�
    ln_so_margin_quantity   := i_xwsp_rec.before_stock - ( i_xwsp_rec.stock_maintenance_days
                                                         * i_xwsp_rec.shipping_pace );
    --�ړ����q�ɂ̗]�T�݌ɓ���
    ln_so_margin_stock_days := i_xwsp_rec.max_stock_days - i_xwsp_rec.stock_maintenance_days;
    <<balance_days_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --�ړ���q�ɂ̗]�T�݌ɐ�
      l_pp_tab(ln_xwypo_idx).margin_quantity   := io_xwypo_tab(ln_xwypo_idx).before_stock
                                                - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                  * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace );
      --�ړ���q�ɂ̗]�T�݌ɓ���
      l_pp_tab(ln_xwypo_idx).margin_stock_days := io_xwypo_tab(ln_xwypo_idx).max_days
                                                - io_xwypo_tab(ln_xwypo_idx).safety_days;
      --�]�T�݌ɐ��̏W�v
      ln_ro_margin_quantity   := ln_ro_margin_quantity   + l_pp_tab(ln_xwypo_idx).margin_quantity;
      --�]�T�݌ɓ����̏W�v
      ln_ro_margin_stock_days := ln_ro_margin_stock_days + l_pp_tab(ln_xwypo_idx).margin_stock_days;
      --���o�׃y�[�X�̏W�v
      ln_ro_shipping_pace     := ln_ro_shipping_pace     + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
    END LOOP balance_days_loop;
    --3.1.1 �o�����X�݌ɓ������Z�o
    ln_balance_days := ( ln_so_margin_quantity + ln_ro_margin_quantity )
                     / ( i_xwsp_rec.shipping_pace + ln_ro_shipping_pace );
    --3.1.2 �ړ����q�ɂ̕�[�\�݌ɐ����Z�o
    ln_supplies_quantity := ln_so_margin_quantity - GREATEST(ln_balance_days + i_xwsp_rec.stock_maintenance_days
                                                            ,i_xwsp_rec.max_stock_days )
                                                  * i_xwsp_rec.shipping_pace;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => 'balance_init'            || ','
                      || ln_supplies_quantity      || ','
                      || ROUND(ln_balance_days, 3) || ','
                      || ln_so_margin_quantity     || '/'
                      || i_xwsp_rec.shipping_pace  || ','
                      || ln_ro_margin_quantity     || '/'
                      || ln_ro_shipping_pace
    );
--
    --3.1.3 �ړ���q�ɂ̈��S�݌ɓ����܂ŕ�[
    --�ړ���q�ɂ̗v���݌ɐ����W�v
    <<safety_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --������
      io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := 0;
      --�v���݌ɐ�/�v���݌ɓ����̎Z�o(�v��=���S�݌�)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(io_xwypo_tab(ln_xwypo_idx).safety_days
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := io_xwypo_tab(ln_xwypo_idx).safety_days;
      --�݌ɐ�/�݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,io_xwypo_tab(ln_xwypo_idx).before_stock
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�s���݌ɐ�/�s���݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --���s���݌ɐ�/���s���݌ɓ����̏W�v
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --�v���݌ɓ����̍ő�l���擾
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --�݌ɓ���/�v���݌ɓ����̍ő�l���擾
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'balance_safety_qty'                          || ':'
                        || io_xwypo_tab(ln_xwypo_idx).receipt_org_code   || ','
                        || l_pp_tab(ln_xwypo_idx).require_quantity       || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).require_days, 2) || ','
                        || l_pp_tab(ln_xwypo_idx).stock_quantity         || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).stock_days, 2)   || '-'
                        || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace     || '-'
                        || ln_crunch_quantity                            || ','
                        || ROUND(ln_greatest_require_days, 2)            || ','
                        || ROUND(ln_greatest_stock_days, 2)
      );
    END LOOP safety_require_quantity_loop;
    --��[�\����0�ȉ��̏ꍇ
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --�ړ���q�ɂŕs���݌ɐ�������ꍇ
    IF ( ln_crunch_quantity > 0 ) THEN
      --�s���݌ɂ̕�[
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --��[�\�݌ɐ����s���݌ɐ��𖞂����Ă���ꍇ
        --�v���݌ɐ����v�搔(�o�����X)�ɐݒ�
        <<safety_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP safety_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --��[�\�݌ɐ����s���݌ɐ��ɖ����Ȃ��ꍇ
        --��[�|�C���g���Ɍv�搔(�o�����X)��ݒ�
        <<safety_division_loop>>
        LOOP
          --������
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --�݌ɓ����̍ŏ��A�ŏ��̎��_���擾
          <<safety_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v���݌ɓ����ɖ����Ȃ��ꍇ
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --�݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --�v���݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP safety_least_stock_days_loop;
          --�ŏ��݌ɓ����Ɨv���݌ɓ����̍ő�l�������ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --���̕�[�|�C���g�܂ł̕s���݌ɐ����W�v
          <<safety_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�݌ɐ�����[�|�C���g�̎��_��菬��������
            --�v���݌ɓ����𒴂��Ă��Ȃ��ꍇ
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --�s���݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --���s���݌ɐ��̏W�v
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --�v���݌ɐ��𖞂����Ă���̂ŁA�s���݌ɐ��͂Ȃ�
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP safety_point_req_qty_loop;
          --�s���݌ɐ����Ȃ��ꍇ
          --��[�����̂��ߏI��
          EXIT safety_division_loop WHEN ( ln_crunch_quantity = 0 );
          --��[�|�C���g�܂ŕ�[�ł��邩���f
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��𖞂����Ă���ꍇ
            --�v���݌ɐ����v�搔(�o�����X)�ɉ��Z
            <<safety_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�v�搔(�o�����X)�����Z
              io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�o�����X)�����Z��̍݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�o�����X)�����Z��̍݌ɓ����̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP safety_point_supply_loop;
            --��[�\������s���݌ɐ������Z
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��ɖ����Ȃ��ꍇ
            IF ( ln_balance_days <= ln_so_margin_stock_days ) THEN
              --3.1.4.1 �]�T�݌ɓ������ړ����q�ɂ̗]�T�݌ɓ����̏ꍇ
              --��[�\�����ړ���q�ɂ̏o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
              ln_shipping_pace := ln_ro_shipping_pace;
            ELSE
              --3.1.4.2 �]�T�݌ɓ������ړ����q�ɂ̗]�T�݌ɓ����̏ꍇ
              --��[�\�����ړ����q�ɁA�ړ���q�ɂ̏o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
              ln_shipping_pace := i_xwsp_rec.shipping_pace + ln_ro_shipping_pace;
            END IF;
            --��[�\�����o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
            <<safety_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP safety_pace_supply_loop;
            --��[�\�����s���������ߏI��
            RAISE short_supply_expt;
          END IF;
        END LOOP safety_division_loop;
      END IF;
    END IF;
--
    --���[�J���ϐ�������
    ln_shipping_pace         := 0;
    ln_crunch_quantity       := 0;
    ln_greatest_require_days := 0;
    ln_greatest_stock_days   := 0;
--
    --3.1.4 �ړ���q�ɂ̃o�����X�݌ɓ����܂ŕ�[
    --�ړ���q�ɂ̕s���݌ɐ����W�v
    <<max_require_quantity_loop>>
    FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
      --�v���݌ɐ�/�v���݌ɓ����̎Z�o(�v����=�o�����X�݌�)
      l_pp_tab(ln_xwypo_idx).require_quantity := FLOOR(LEAST(ln_balance_days, l_pp_tab(ln_xwypo_idx).margin_stock_days)
                                                     * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                 );
      l_pp_tab(ln_xwypo_idx).require_days     := LEAST(ln_balance_days, l_pp_tab(ln_xwypo_idx).margin_stock_days);
      --�݌ɐ�/�݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).stock_quantity   := LEAST(l_pp_tab(ln_xwypo_idx).require_quantity
                                                      ,( io_xwypo_tab(ln_xwypo_idx).before_stock
                                                       + io_xwypo_tab(ln_xwypo_idx).plan_bal_qty )
                                                     - ( io_xwypo_tab(ln_xwypo_idx).safety_days
                                                       * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace )
                                                 );
      l_pp_tab(ln_xwypo_idx).stock_days       := l_pp_tab(ln_xwypo_idx).stock_quantity
                                               / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�s���݌ɐ�/�s���݌ɓ����̎Z�o
      l_pp_tab(ln_xwypo_idx).crunch_quantity  := GREATEST(0, l_pp_tab(ln_xwypo_idx).require_quantity
                                                           - l_pp_tab(ln_xwypo_idx).stock_quantity
                                                 );
      --���s���݌ɐ�/���s���݌ɓ����̏W�v
      ln_crunch_quantity                      := ln_crunch_quantity + l_pp_tab(ln_xwypo_idx).crunch_quantity;
      --���o�׃y�[�X�̏W�v
      ln_shipping_pace                        := ln_shipping_pace + io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
      --�v���݌ɓ����̍ő�l���擾
      ln_greatest_require_days                := GREATEST(ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).require_days
                                                 );
      --�݌ɓ���/�v���݌ɓ����̍ő�l���擾
      ln_greatest_stock_days                  := GREATEST(ln_greatest_stock_days
                                                         ,ln_greatest_require_days
                                                         ,l_pp_tab(ln_xwypo_idx).stock_days
                                                 );
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'balance_max_qty   '                          || ':'
                        || io_xwypo_tab(ln_xwypo_idx).receipt_org_code   || ','
                        || l_pp_tab(ln_xwypo_idx).require_quantity       || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).require_days, 2) || ','
                        || l_pp_tab(ln_xwypo_idx).stock_quantity         || '/'
                        || ROUND(l_pp_tab(ln_xwypo_idx).stock_days, 2)   || '-'
                        || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace     || '-'
                        || ln_crunch_quantity                            || ','
                        || ROUND(ln_greatest_require_days, 2)            || ','
                        || ROUND(ln_greatest_stock_days, 2)
      );
    END LOOP max_require_quantity_loop;
    --��[�\����0�ȉ��̏ꍇ
    IF ( ln_supplies_quantity <= 0 ) THEN
      RAISE short_supply_expt;
    END IF;
    --�ړ���q�ɂŕs���݌ɐ�������ꍇ
    IF ( ln_crunch_quantity > 0 ) THEN
      --�s���݌ɂ̕�[
      IF ( ln_supplies_quantity >= ln_crunch_quantity ) THEN
        --��[�\�݌ɐ����s���݌ɐ��𖞂����Ă���ꍇ
        --�v���݌ɐ����v�搔(�o�����X)�ɐݒ�
        <<max_supply_loop>>
        FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
          io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                   + l_pp_tab(ln_xwypo_idx).crunch_quantity;
        END LOOP max_supply_loop;
        ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
      ELSE
        --��[�\�݌ɐ����s���݌ɐ��ɖ����Ȃ��ꍇ
        --��[�|�C���g���Ɍv�搔(�o�����X)��ݒ�
        <<max_division_loop>>
        LOOP
          --������
          ln_less_stock_days  := ln_greatest_stock_days;
          ln_least_stock_days := ln_greatest_stock_days;
          ln_crunch_quantity  := 0;
          --�݌ɓ����̍ŏ��A�ŏ��̎��_���擾
          <<max_least_stock_days_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�v���݌ɓ����ɖ����Ȃ��ꍇ
            IF ( l_pp_tab(ln_xwypo_idx).stock_days < l_pp_tab(ln_xwypo_idx).require_days ) THEN
              --�݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).stock_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).stock_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).stock_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).stock_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).stock_days;
              END IF;
              --�v���݌ɓ���
              IF ( ln_least_stock_days > l_pp_tab(ln_xwypo_idx).require_days ) THEN
                ln_less_stock_days  := ln_least_stock_days;
                ln_least_stock_days := l_pp_tab(ln_xwypo_idx).require_days;
              ELSIF( ln_less_stock_days  > l_pp_tab(ln_xwypo_idx).require_days
                AND  ln_least_stock_days < l_pp_tab(ln_xwypo_idx).require_days )
              THEN
                ln_less_stock_days  := l_pp_tab(ln_xwypo_idx).require_days;
              END IF;
            END IF;
          END LOOP max_least_stock_days_loop;
          --�ŏ��݌ɓ����Ɨv���݌ɓ����̍ő�l�������ꍇ
          --��[�����̂��ߏI��
          EXIT max_division_loop WHEN ( ln_least_stock_days = ln_greatest_require_days );
          --���̕�[�|�C���g�܂ł̕s���݌ɐ����W�v
          <<max_point_req_qty_loop>>
          FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
            --�݌ɐ�����[�|�C���g�̎��_��菬��������
            --�v���݌ɓ����𒴂��Ă��Ȃ��ꍇ
            IF (  ln_less_stock_days                  > l_pp_tab(ln_xwypo_idx).stock_days
              AND l_pp_tab(ln_xwypo_idx).require_days > l_pp_tab(ln_xwypo_idx).stock_days )
            THEN
              --�s���݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).crunch_quantity := CEIL(( ln_less_stock_days
                                                             - l_pp_tab(ln_xwypo_idx).stock_days )
                                                             * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        );
              --���s���݌ɐ��̏W�v
              ln_crunch_quantity                     := ln_crunch_quantity
                                                      + l_pp_tab(ln_xwypo_idx).crunch_quantity;
            ELSE
              --�v���݌ɐ��𖞂����Ă���̂ŁA�s���݌ɐ��͂Ȃ�
              l_pp_tab(ln_xwypo_idx).crunch_quantity := 0;
            END IF;
          END LOOP max_point_req_qty_loop;
          --�s���݌ɐ����Ȃ��ꍇ
          --��[�����̂��ߏI��
          EXIT max_division_loop WHEN ( ln_crunch_quantity = 0 );
          --��[�|�C���g�܂ŕ�[�ł��邩���f
          IF ( ln_supplies_quantity > ln_crunch_quantity ) THEN
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��𖞂����Ă���ꍇ
            --�v���݌ɐ����v�搔(�o�����X)�ɉ��Z
            <<max_point_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�v�搔(�o�����X)�����Z
              io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                       + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�o�����X)�����Z��̍݌ɐ��̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_quantity := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     + l_pp_tab(ln_xwypo_idx).crunch_quantity;
              --�v�搔(�o�����X)�����Z��̍݌ɓ����̎Z�o
              l_pp_tab(ln_xwypo_idx).stock_days     := l_pp_tab(ln_xwypo_idx).stock_quantity
                                                     / io_xwypo_tab(ln_xwypo_idx).under_lvl_pace;
            END LOOP max_point_supply_loop;
            --��[�\������s���݌ɐ������Z
            ln_supplies_quantity := ln_supplies_quantity - ln_crunch_quantity;
          ELSE
            --��[�\������[�|�C���g�܂ł̕s���݌ɐ��ɖ����Ȃ��ꍇ
            IF ( ln_balance_days <= ln_so_margin_stock_days ) THEN
              --3.1.4.1 �]�T�݌ɓ������ړ����q�ɂ̗]�T�݌ɓ����̏ꍇ
              --��[�\�����ړ���q�ɂ̏o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
              ln_shipping_pace := ln_ro_shipping_pace;
            ELSE
              --3.1.4.2 �]�T�݌ɓ������ړ����q�ɂ̗]�T�݌ɓ����̏ꍇ
              --��[�\�����ړ����q�ɁA�ړ���q�ɂ̏o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
              ln_shipping_pace := i_xwsp_rec.shipping_pace + ln_ro_shipping_pace;
            END IF;
            --��[�\�����o�׃y�[�X�ň����Čv�搔(�o�����X)�ɉ��Z
            <<max_pace_supply_loop>>
            FOR ln_xwypo_idx IN io_xwypo_tab.FIRST .. io_xwypo_tab.LAST LOOP
              --�f�o�b�N���b�Z�[�W�o��
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'div_qty'                                   || ':'
                                || io_xwypo_tab(ln_xwypo_idx).receipt_org_code || ','
                                || ln_supplies_quantity                        || ','
                                || io_xwypo_tab(ln_xwypo_idx).under_lvl_pace   || ','
                                || ln_shipping_pace                            || ','
                                || io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
              );
              IF ( l_pp_tab(ln_xwypo_idx).crunch_quantity > 0 ) THEN
                io_xwypo_tab(ln_xwypo_idx).plan_bal_qty := io_xwypo_tab(ln_xwypo_idx).plan_bal_qty
                                                         + FLOOR(ln_supplies_quantity
                                                               * io_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                               / ln_shipping_pace
                                                           );
              END IF;
            END LOOP max_pace_supply_loop;
            --��[�\�����s���������ߏI��
            RAISE short_supply_expt;
          END IF;
        END LOOP max_division_loop;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN short_supply_expt THEN
      NULL;
    WHEN ZERO_DIVIDE THEN
      RAISE zero_divide_expt;
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
  END proc_balance_plan_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_quantity
   * Description      : �݌ɐ��̎擾
   ***********************************************************************************/
  PROCEDURE get_stock_quantity(
    in_item_id       IN     ic_loct_inv.item_id%TYPE,
    iv_whse_code     IN     ic_loct_inv.whse_code%TYPE,
    id_plan_date     IN     xxcop_wk_yoko_plan_output.receipt_date%TYPE,
    in_stock_days    IN     xxcop_wk_yoko_plan_output.max_days%TYPE,
    i_cp_rec         IN     g_condition_priority_rtype,
    on_stock_quantity   OUT xxcop_wk_yoko_plan_output.before_stock%TYPE,
    od_manufacture_date OUT xxcop_wk_yoko_plan_output.manu_date%TYPE,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_quantity'; -- �v���O������
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
    --�N�x�����i��ʁj
    IF ( i_cp_rec.condition_type = cv_condition_general ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPM���b�g�}�X�^
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --���o�ɗ\����r���[
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id         = in_item_id
            AND xstv.whse_code       = iv_whse_code
            AND xstv.status          = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --�����v��o�̓��[�N�e�[�u��
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
    --�N�x�����i�ܖ�������j
    IF ( i_cp_rec.condition_type = cv_condition_expiration ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPM���b�g�}�X�^
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --�N�x����
            AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                             + CEIL(( TO_DATE(ilm.attribute3, cv_date_format)
                                    - TO_DATE(ilm.attribute1, cv_date_format)
                                    ) / i_cp_rec.condition_value
                               )
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --���o�ɗ\����r���[
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id         = in_item_id
            AND xstv.whse_code       = iv_whse_code
            AND xstv.status          = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --�N�x����
            AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                             + CEIL(( TO_DATE(xstv.expiration_date , cv_date_format)
                                    - TO_DATE(xstv.manufacture_date, cv_date_format)
                                    ) / i_cp_rec.condition_value
                               )
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --�����v��o�̓��[�N�e�[�u��
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
    --�N�x�����i��������j
    IF ( i_cp_rec.condition_type = cv_condition_manufacture ) THEN
      SELECT NVL(SUM(stock_quantity), 0)        stock_quantity
            ,MIN(manufacture_date)              manufacture_date
      INTO on_stock_quantity
          ,od_manufacture_date
      FROM (
        SELECT NVL(SUM(ilmv.stock_quantity), 0) stock_quantity
              ,ilmv.manufacture_date            manufacture_date
        FROM (
          --OPM���b�g�}�X�^
          SELECT ili.loct_onhand                                             stock_quantity
                ,TO_DATE(ilm.attribute1, cv_date_format)                     manufacture_date
          FROM ic_lots_mst ilm
              ,ic_loct_inv ili
          WHERE ilm.item_id          = ili.item_id
            AND ilm.lot_id           = ili.lot_id
            AND ili.item_id          = in_item_id
            AND ili.whse_code        = iv_whse_code
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(ilm.attribute3, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --�N�x����
            AND id_plan_date < TO_DATE(ilm.attribute1, cv_date_format)
                             + i_cp_rec.condition_value
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --���o�ɗ\����r���[
          SELECT NVL(xstv.stock_quantity, 0) - NVL(xstv.leaving_quantity, 0) stock_quantity
                ,TO_DATE(xstv.manufacture_date, cv_date_format)              manufacture_date
          FROM xxcop_stc_trans_v xstv
          WHERE xstv.item_id     = in_item_id
            AND xstv.whse_code   = iv_whse_code
            AND xstv.status      = cv_xstv_status
            AND xstv.arrival_date BETWEEN cd_sysdate
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_START
--                                      AND id_plan_date
                                      AND id_plan_date - 1
--20090407_Ver1.1_T1_0274_SCS.Goto_ADD_END
            --�ŏI�������[��
            AND id_plan_date < ADD_MONTHS(TO_DATE(xstv.expiration_date, cv_date_format), - gn_deadline_months)
                             - gn_deadline_buffer_days
            --�N�x����
            AND id_plan_date < TO_DATE(xstv.manufacture_date, cv_date_format)
                             + i_cp_rec.condition_value
                             - in_stock_days
                             - gn_freshness_buffer_days
          UNION ALL
          --�����v��o�̓��[�N�e�[�u��
          SELECT xwypo.plan_lot_qty * -1                                     stock_quantity
                ,xwypo.manu_date                                             manufacture_date
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id = cn_request_id
            AND xwypo.group_id       = gn_group_id
            AND xwypo.ship_org_code  = iv_whse_code
            AND xwypo.item_id        = in_item_id
        ) ilmv
        GROUP BY ilmv.manufacture_date
        HAVING   SUM(ilmv.stock_quantity) > 0
        ORDER BY ilmv.manufacture_date ASC
      );
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      on_stock_quantity   := 0;
      od_manufacture_date := NULL;
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
  END get_stock_quantity;
--
  /**********************************************************************************
   * Procedure Name   : entry_xwsp
   * Description      : �����v�惏�[�N�e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE entry_xwsp(
    i_xwsp_rec       IN     xxcop_wk_ship_planning%ROWTYPE,
    i_fc_tab         IN     g_freshness_condition_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_xwsp'; -- �v���O������
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
    ln_condition_idx          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
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
--    --�f�o�b�N���b�Z�[�W�o��
--    xxcop_common_pkg.put_debug_message(
--       iov_debug_mode => gv_debug_mode
--      ,iv_value       => cv_pkg_name || cv_msg_cont || cv_prg_name
--                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
--    );
--
    BEGIN
      --�v���Œ�l�̐ݒ�
      l_xwsp_rec                            := i_xwsp_rec;
      l_xwsp_rec.transaction_id             := cn_request_id;
      l_xwsp_rec.created_by                 := cn_created_by;
      l_xwsp_rec.creation_date              := cd_creation_date;
      l_xwsp_rec.last_updated_by            := cn_last_updated_by;
      l_xwsp_rec.last_update_date           := cd_last_update_date;
      l_xwsp_rec.last_update_login          := cn_last_update_login;
      l_xwsp_rec.request_id                 := cn_request_id;
      l_xwsp_rec.program_application_id     := cn_program_application_id;
      l_xwsp_rec.program_id                 := cn_program_id;
      l_xwsp_rec.program_update_date        := cd_program_update_date;
      <<condition_loop>>
      FOR ln_priority_idx IN i_fc_tab.FIRST .. i_fc_tab.LAST LOOP
        IF ( i_fc_tab(ln_priority_idx).freshness_condition IS NOT NULL ) THEN
          l_xwsp_rec.freshness_priority     := ln_priority_idx;
          l_xwsp_rec.freshness_condition    := i_fc_tab(ln_priority_idx).freshness_condition;
          l_xwsp_rec.stock_maintenance_days := i_fc_tab(ln_priority_idx).stock_maintenance_days;
          l_xwsp_rec.max_stock_days         := i_fc_tab(ln_priority_idx).max_stock_days;
          --�����v�惏�[�N�e�[�u���o�^
          INSERT INTO xxcop_wk_ship_planning VALUES l_xwsp_rec;
        END IF;
      END LOOP condition_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00027
                       ,iv_token_name1  => cv_msg_00027_token_1
                       ,iv_token_value1 => cv_table_xwsp
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
  END entry_xwsp;
--
  /**********************************************************************************
   * Procedure Name   : proc_ship_pace
   * Description      : �o�׃y�[�X�̌v�Z
   ***********************************************************************************/
  PROCEDURE proc_ship_pace(
    io_xwsp_rec      IN OUT xxcop_wk_ship_planning%ROWTYPE,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ship_pace'; -- �v���O������
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
    ld_calender_from                 DATE;
    ld_calender_to                   DATE;
    ln_shipped_qty                   NUMBER;     --�o�א�
    ln_working_days                  NUMBER;     --�ғ�����
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
    io_xwsp_rec.shipping_pace := 0;
--
    BEGIN
      IF   ( gv_plan_type = cv_plan_type_shipped AND io_xwsp_rec.shipping_type = cv_plan_type_shipped )
        OR ( gv_plan_type = cv_plan_type_shipped AND io_xwsp_rec.shipping_type IS NULL                )
        OR ( gv_plan_type IS NULL                AND io_xwsp_rec.shipping_type = cv_plan_type_shipped )
        OR ( gv_plan_type IS NULL                AND io_xwsp_rec.shipping_type IS NULL                )
      THEN
        ld_calender_from := gd_shipment_from;
        ld_calender_to   := gd_shipment_to;
        --�o�׎��т��擾
        xxcop_common_pkg2.get_num_of_shipped(
           iv_organization_code  => io_xwsp_rec.receipt_org_code
          ,iv_item_no            => io_xwsp_rec.item_no
          ,id_plan_date_from     => ld_calender_from
          ,id_plan_date_to       => ld_calender_to
          ,on_quantity           => ln_shipped_qty
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --�ړ���q�ɂ̉ғ��������擾
        xxcop_common_pkg2.get_working_days(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,id_from_date          => ld_calender_from
          ,id_to_date            => ld_calender_to
          ,on_working_days       => ln_working_days
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        IF ( ln_working_days = 0 ) THEN
          RAISE no_working_days_expt;
        END IF;
        --�o�׃y�[�X���Z�o
        io_xwsp_rec.shipping_pace := ROUND(ln_shipped_qty / ln_working_days);
      END IF;
      IF   ( gv_plan_type = cv_plan_type_fgorcate AND io_xwsp_rec.shipping_type = cv_plan_type_fgorcate )
        OR ( gv_plan_type = cv_plan_type_fgorcate AND io_xwsp_rec.shipping_type IS NULL                 )
        OR ( gv_plan_type IS NULL                 AND io_xwsp_rec.shipping_type = cv_plan_type_fgorcate )
      THEN
        ld_calender_from := gd_forcast_from;
        ld_calender_to   := gd_forcast_to;
        --�o�ח\�����擾
        xxcop_common_pkg2.get_num_of_forcast(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,in_inventory_item_id  => io_xwsp_rec.inventory_item_id
          ,id_plan_date_from     => ld_calender_from
          ,id_plan_date_to       => ld_calender_to
          ,on_quantity           => ln_shipped_qty
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --�ړ���q�ɂ̉ғ��������擾
        xxcop_common_pkg2.get_working_days(
           in_organization_id    => io_xwsp_rec.receipt_org_id
          ,id_from_date          => ld_calender_from
          ,id_to_date            => ld_calender_to
          ,on_working_days       => ln_working_days
          ,ov_errbuf             => lv_errbuf
          ,ov_retcode            => lv_retcode
          ,ov_errmsg             => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        IF ( ln_working_days = 0 ) THEN
          RAISE no_working_days_expt;
        END IF;
        --�o�׃y�[�X���Z�o
        io_xwsp_rec.shipping_pace := ROUND(ln_shipped_qty / ln_working_days);
      END IF;
    EXCEPTION
      WHEN no_working_days_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00056
                       ,iv_token_name1  => cv_msg_00056_token_1
                       ,iv_token_value1 => TO_CHAR(ld_calender_from, cv_date_format)
                       ,iv_token_name2  => cv_msg_00056_token_2
                       ,iv_token_value2 => TO_CHAR(ld_calender_to, cv_date_format)
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
  END proc_ship_pace;
--
  /**********************************************************************************
   * Procedure Name   : chk_route_prereq
   * Description      : �o�H�̑O������`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_route_prereq(
    i_xwsp_rec       IN     xxcop_wk_ship_planning%ROWTYPE,
    i_fc_tab         IN     g_freshness_condition_ttype,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_route_prereq'; -- �v���O������
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
    --��{�����v��܂��͓��ʉ����v��̏ꍇ
    IF i_xwsp_rec.assignment_set_type IN (cv_base_plan, cv_custom_plan) THEN
      BEGIN
        ln_condition_cnt := 0;
        <<priority_loop>>
        FOR ln_priority_idx IN i_fc_tab.FIRST .. i_fc_tab.LAST LOOP
          --�N�x����
          IF ( i_fc_tab(ln_priority_idx).freshness_condition IS NOT NULL ) THEN
            --�݌Ɉێ�����
            IF ( NVL(i_fc_tab(ln_priority_idx).stock_maintenance_days, 0) <= 0 ) THEN
              lv_item_name := cv_msg_10041_value_1;
              RAISE stock_days_expt;
            END IF;
            --�ő�݌ɓ���
            IF ( NVL(i_fc_tab(ln_priority_idx).max_stock_days, 0) <= 0 ) THEN
              lv_item_name := cv_msg_10041_value_2;
              RAISE stock_days_expt;
            END IF;
            ln_condition_cnt := ln_condition_cnt + 1;
          END IF;
        END LOOP priority_loop;
        --�N�x�������o�^����Ă��Ȃ��ꍇ
        IF ( ln_condition_cnt = 0 ) THEN
          RAISE no_condition_expt;
        END IF;
      EXCEPTION
        WHEN stock_days_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10041
                         ,iv_token_name1  => cv_msg_10041_token_1
                         ,iv_token_value1 => lv_item_name
                         ,iv_token_name2  => cv_msg_10041_token_1
                         ,iv_token_value2 => i_xwsp_rec.receipt_org_code
                       );
          RAISE internal_api_expt;
        WHEN no_condition_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_10038
                         ,iv_token_name1  => cv_msg_10038_token_1
                         ,iv_token_value1 => i_xwsp_rec.receipt_org_code
                       );
          RAISE internal_api_expt;
      END;
    END IF;
    --���ʉ����v��̏ꍇ
    IF i_xwsp_rec.assignment_set_type IN (cv_custom_plan) THEN
      --�J�n�����N����
      IF ( i_xwsp_rec.manufacture_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10039
                       ,iv_token_name1  => cv_msg_10039_token_1
                       ,iv_token_value1 => i_xwsp_rec.receipt_org_code
                     );
        RAISE internal_api_expt;
      END IF;
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
  END chk_route_prereq;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_route
   * Description      : �o�בq�Ɍo�H�擾
   ***********************************************************************************/
  PROCEDURE get_ship_route(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_route'; -- �v���O������
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
    ln_condition_idx          NUMBER;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
    ln_exists                 NUMBER;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
--
    -- *** ���[�J���E�J�[�\�� ***
    --�o�בq�ɂ��擾
    CURSOR xwsp_ship_cur IS
      SELECT xwsp.inventory_item_id
            ,xwsp.item_id
            ,xwsp.item_no
            ,xwsp.item_name
            ,xwsp.ship_org_id
            ,xwsp.ship_org_code
            ,xwsp.ship_org_name
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id = cn_request_id
      GROUP BY xwsp.inventory_item_id
              ,xwsp.item_id
              ,xwsp.item_no
              ,xwsp.item_name
              ,xwsp.ship_org_id
              ,xwsp.ship_org_code
              ,xwsp.ship_org_name;
--
    --�o�בq�Ɍo�H���擾
    CURSOR msr_ship_cur(
              in_inventory_item_id NUMBER
             ,in_organization_id   NUMBER
    ) IS
      SELECT source_organization_id
            ,assignment_set_type
            ,assignment_type
            ,sourcing_rule_type
            ,sourcing_rule_name
            ,shipping_type
            ,freshness_condition1
            ,stock_maintenance_days1
            ,max_stock_days1
            ,freshness_condition2
            ,stock_maintenance_days2
            ,max_stock_days2
            ,freshness_condition3
            ,stock_maintenance_days3
            ,max_stock_days3
            ,freshness_condition4
            ,stock_maintenance_days4
            ,max_stock_days4
      FROM (
        WITH msr_vw AS (
          --�S�o�H(��{�����v��A�o�׌v��敪�_�~�[�o�H)
          SELECT msso.source_organization_id             source_organization_id --�ړ����q��ID
                ,msro.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,mas.assignment_set_name                    assignment_set_name --�����Z�b�g��
                ,NVL(msa.organization_id, in_organization_id)   organization_id --�g�D
                ,mas.attribute1                             assignment_set_type --�����Z�b�g�敪
                ,msa.assignment_type                            assignment_type --������^�C�v
                ,msa.sourcing_rule_type                      sourcing_rule_type --�\�[�X���[���^�C�v
                ,msr.sourcing_rule_name                      sourcing_rule_name --�\�[�X���[����
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
          FROM mrp_assignment_sets mas
              ,mrp_sr_assignments  msa
              ,mrp_sourcing_rules  msr
              ,mrp_sr_receipt_org  msro
              ,mrp_sr_source_org   msso
              ,fnd_lookup_values   flv1
              ,fnd_lookup_values   flv2
          WHERE mas.assignment_set_id       = msa.assignment_set_id
            AND mas.attribute1             IN (cv_base_plan)
            AND msr.sourcing_rule_id        = msa.sourcing_rule_id
            AND msro.sourcing_rule_id       = msr.sourcing_rule_id
            AND msro.sr_receipt_id          = msso.sr_receipt_id
            AND cd_sysdate BETWEEN NVL(msro.effective_date, cd_sysdate)
                               AND NVL(msro.disable_date, cd_sysdate)
            AND flv1.lookup_type            = cv_flv_assignment_name
            AND flv1.lookup_code            = mas.assignment_set_name
            AND flv1.language               = cv_lang
            AND flv1.source_lang            = cv_lang
            AND flv1.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                               AND NVL(flv1.end_date_active, cd_sysdate)
            AND flv2.lookup_type            = cv_flv_assign_priority
            AND flv2.lookup_code            = msa.assignment_type
            AND flv2.language               = cv_lang
            AND flv2.source_lang            = cv_lang
            AND flv2.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv2.start_date_active, cd_sysdate)
                               AND NVL(flv2.end_date_active, cd_sysdate)
            AND msso.source_organization_id IN (gn_dummy_src_org_id, gn_master_org_id)
            AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
            AND NVL(msa.organization_id, in_organization_id)     = in_organization_id
        )
        , msr_dummy_vw AS (
          --�o�׌v��敪�_�~�[�o�H
          SELECT msrv.source_organization_id             source_organization_id --�ړ����q��ID
                ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
                ,msrv.organization_id                           organization_id --�g�D
                ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
                ,msrv.assignment_type                           assignment_type --������^�C�v
                ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
                ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
                ,msrv.attribute1                                     attribute1 --�o�׌v��敪
                ,msrv.attribute2                                     attribute2 --�N�x����1
                ,msrv.attribute3                                     attribute3 --�݌Ɉێ�����1
                ,msrv.attribute4                                     attribute4 --�ő�݌ɓ���1
                ,msrv.attribute5                                     attribute5 --�N�x����2
                ,msrv.attribute6                                     attribute6 --�݌Ɉێ�����2
                ,msrv.attribute7                                     attribute7 --�ő�݌ɓ���2
                ,msrv.attribute8                                     attribute8 --�N�x����3
                ,msrv.attribute9                                     attribute9 --�݌Ɉێ�����3
                ,msrv.attribute10                                   attribute10 --�ő�݌ɓ���3
                ,msrv.attribute11                                   attribute11 --�N�x����4
                ,msrv.attribute12                                   attribute12 --�݌Ɉێ�����4
                ,msrv.attribute13                                   attribute13 --�ő�݌ɓ���4
                ,msrv.assign_type_priority                 assign_type_priority --������^�C�v�D��x
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                   )                                   priority --�D�揇��
          FROM msr_vw msrv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_master_org_id)
        )
        , msr_base_vw AS (
          --��{�����v��
          SELECT msrv.source_organization_id             source_organization_id --�ړ����q��ID
                ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
                ,msrv.organization_id                           organization_id --�g�D
                ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
                ,msrv.assignment_type                           assignment_type --������^�C�v
                ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
                ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute1)
                     ELSE TO_NUMBER(msrv.attribute1)
                 END                                              shipping_type --�o�׌v��敪
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute2
                     ELSE msrv.attribute2
                 END                                       freshness_condition1 --�N�x����1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute3)
                     ELSE TO_NUMBER(msrv.attribute3)
                 END                                    stock_maintenance_days1 --�݌Ɉێ�����1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute4)
                     ELSE TO_NUMBER(msrv.attribute4)
                 END                                            max_stock_days1 --�ő�݌ɓ���1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute5
                     ELSE msrv.attribute5
                 END                                       freshness_condition2 --�N�x����2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute6)
                     ELSE TO_NUMBER(msrv.attribute6)
                 END                                    stock_maintenance_days2 --�݌Ɉێ�����2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute7)
                     ELSE TO_NUMBER(msrv.attribute7)
                 END                                            max_stock_days2 --�ő�݌ɓ���2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute8
                     ELSE msrv.attribute8
                 END                                       freshness_condition3 --�N�x����3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute9)
                     ELSE TO_NUMBER(msrv.attribute9)
                 END                                    stock_maintenance_days3 --�݌Ɉێ�����3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute10)
                     ELSE TO_NUMBER(msrv.attribute10)
                 END                                            max_stock_days3 --�ő�݌ɓ���3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute11
                     ELSE msrv.attribute11
                 END                                       freshness_condition4 --�N�x����4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute12)
                     ELSE TO_NUMBER(msrv.attribute12)
                 END                                    stock_maintenance_days4 --�݌Ɉێ�����4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute13)
                     ELSE TO_NUMBER(msrv.attribute13)
                 END                                            max_stock_days4 --�ő�݌ɓ���4
                ,msrv.assign_type_priority                 assign_type_priority --������^�C�v�D��x
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.receipt_organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                                 ,msrv.sourcing_rule_type   DESC
                                   )                                   priority --�D�揇��
          FROM msr_vw msrv
              ,msr_dummy_vw mdv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_dummy_src_org_id)
            AND msrv.organization_id = mdv.organization_id(+)
            AND mdv.priority(+) = 1
        )
        SELECT mbv.source_organization_id   source_organization_id
              ,mbv.receipt_organization_id  receipt_organization_id
              ,mbv.organization_id          organization_id
              ,mbv.assignment_set_type      assignment_set_type
              ,mbv.assignment_type          assignment_type
              ,mbv.sourcing_rule_type       sourcing_rule_type
              ,mbv.sourcing_rule_name       sourcing_rule_name
              ,mbv.shipping_type            shipping_type
              ,mbv.freshness_condition1     freshness_condition1
              ,mbv.stock_maintenance_days1  stock_maintenance_days1
              ,mbv.max_stock_days1          max_stock_days1
              ,mbv.freshness_condition2     freshness_condition2
              ,mbv.stock_maintenance_days2  stock_maintenance_days2
              ,mbv.max_stock_days2          max_stock_days2
              ,mbv.freshness_condition3     freshness_condition3
              ,mbv.stock_maintenance_days3  stock_maintenance_days3
              ,mbv.max_stock_days3          max_stock_days3
              ,mbv.freshness_condition4     freshness_condition4
              ,mbv.stock_maintenance_days4  stock_maintenance_days4
              ,mbv.max_stock_days4          max_stock_days4
        FROM msr_base_vw mbv
        WHERE mbv.priority = 1
      );
--
    -- *** ���[�J���E���R�[�h ***
    l_fc_tab                  g_freshness_condition_ttype;
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    OPEN xwsp_ship_cur;
    <<xwsp_ship_loop>>
    LOOP
      --�o�בq�ɂ��擾
      FETCH xwsp_ship_cur INTO l_xwsp_rec.inventory_item_id
                              ,l_xwsp_rec.item_id
                              ,l_xwsp_rec.item_no
                              ,l_xwsp_rec.item_name
                              ,l_xwsp_rec.receipt_org_id
                              ,l_xwsp_rec.receipt_org_code
                              ,l_xwsp_rec.receipt_org_name;
      EXIT WHEN xwsp_ship_cur%NOTFOUND;
      --�f�o�b�N���b�Z�[�W�o��(�o�בq��)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => l_xwsp_rec.item_no           || ','
                        || l_xwsp_rec.inventory_item_id || ','
                        || l_xwsp_rec.receipt_org_id    || ','
                        || l_xwsp_rec.receipt_org_code
      );
      OPEN msr_ship_cur(
              l_xwsp_rec.inventory_item_id
             ,l_xwsp_rec.receipt_org_id
           );
      <<msr_ship_loop>>
      LOOP
        --�o�H���̎擾
        FETCH msr_ship_cur INTO l_xwsp_rec.plant_org_id
                               ,l_xwsp_rec.assignment_set_type
                               ,l_xwsp_rec.assignment_type
                               ,l_xwsp_rec.sourcing_rule_type
                               ,l_xwsp_rec.sourcing_rule_name
                               ,l_xwsp_rec.shipping_type
                               ,l_fc_tab(1).freshness_condition
                               ,l_fc_tab(1).stock_maintenance_days
                               ,l_fc_tab(1).max_stock_days
                               ,l_fc_tab(2).freshness_condition
                               ,l_fc_tab(2).stock_maintenance_days
                               ,l_fc_tab(2).max_stock_days
                               ,l_fc_tab(3).freshness_condition
                               ,l_fc_tab(3).stock_maintenance_days
                               ,l_fc_tab(3).max_stock_days
                               ,l_fc_tab(4).freshness_condition
                               ,l_fc_tab(4).stock_maintenance_days
                               ,l_fc_tab(4).max_stock_days;
        EXIT WHEN msr_ship_cur%NOTFOUND;
        --�f�o�b�N���b�Z�[�W�o��(�o�H)
        xxcop_common_pkg.put_debug_message(
           iov_debug_mode => gv_debug_mode
          ,iv_value       => l_xwsp_rec.assignment_set_type || ','
                          || l_xwsp_rec.assignment_type     || ','
                          || l_xwsp_rec.sourcing_rule_name  || ','
                          || l_xwsp_rec.plant_org_id        || ','
                          || l_xwsp_rec.receipt_org_id
        );
        --�O������̃`�F�b�N
        chk_route_prereq(
           i_xwsp_rec   => l_xwsp_rec
          ,i_fc_tab     => l_fc_tab
          ,ov_errbuf    => lv_errbuf
          ,ov_retcode   => lv_retcode
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --�o�ד�
        l_xwsp_rec.shipping_date := gd_plan_date;
        --���ד�
        l_xwsp_rec.receipt_date  := gd_plan_date;
        --�o�׃y�[�X�̌v�Z
        proc_ship_pace(
           io_xwsp_rec  => l_xwsp_rec
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --�����v�惏�[�N�e�[�u���o�^
        entry_xwsp(
           i_xwsp_rec   => l_xwsp_rec
          ,i_fc_tab     => l_fc_tab
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_errbuf IS NULL ) THEN
            RAISE internal_api_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
        --�ړ���q�ɂ̑N�x�������S�ēo�^����Ă��邩�`�F�b�N
        SELECT COUNT(*)
        INTO ln_exists
        FROM xxcop_wk_ship_planning xwsp
        WHERE xwsp.transaction_id = cn_request_id
          AND xwsp.item_id        = l_xwsp_rec.item_id
          AND xwsp.ship_org_id    = l_xwsp_rec.receipt_org_id
          AND NOT EXISTS (
            SELECT 'x'
            FROM xxcop_wk_ship_planning xwspv
            WHERE xwspv.transaction_id      = cn_request_id
              AND xwspv.plant_org_id        = gn_dummy_src_org_id
              AND xwspv.item_id             = l_xwsp_rec.item_id
              AND xwspv.receipt_org_id      = l_xwsp_rec.receipt_org_id
              AND xwspv.freshness_condition = xwsp.freshness_condition
          );
          IF ( ln_exists <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_10040
                           ,iv_token_name1  => cv_msg_10040_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
      END LOOP msr_ship_loop;
      IF ( msr_ship_cur%ROWCOUNT = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10040
                       ,iv_token_name1  => cv_msg_10040_token_1
                       ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                     );
        RAISE internal_api_expt;
      END IF;
      CLOSE msr_ship_cur;
    END LOOP xwsp_ship_loop;
    CLOSE xwsp_ship_cur;
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
  END get_ship_route;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : �e�[�u���f�[�^�폜
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_table_name             VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    TYPE rowid_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    lr_rowid                  rowid_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    -- ===============================
    -- �����v�惏�[�N�e�[�u��
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwsp;
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
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �����v��o�̓��[�N�e�[�u��
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwypo;
      --���b�N�̎擾
      SELECT xwspo.ROWID
      BULK COLLECT INTO lr_rowid
      FROM xxcop_wk_yoko_plan_output xwspo
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      DELETE FROM xxcop_wk_yoko_plan_output;
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        NULL;
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00042
                       ,iv_token_name1  => cv_msg_00042_token_1
                       ,iv_token_value1 => lv_table_name
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
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_plan_type     IN     VARCHAR2,       -- 1.�v��敪
    iv_shipment_from IN     VARCHAR2,       -- 2.�o�׃y�[�X�v�����(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.�o�׃y�[�X�v�����(TO)
    iv_forcast_type  IN     VARCHAR2,       -- 4.�o�ח\���敪
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_param_msg         VARCHAR2(100);   -- �p�����[�^�o��
    lb_chk_value         BOOLEAN;         -- ���t�^�t�H�[�}�b�g�`�F�b�N����
    lv_invalid_value     VARCHAR2(100);   -- �G���[���b�Z�[�W�l
    lv_value             VARCHAR2(100);   -- �v���t�@�C���l
    lv_profile_name      VARCHAR2(100);   -- ���[�U�v���t�@�C����
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    --���̓p�����[�^�̏o��
    --�v��敪
    lv_param_msg := cv_plan_type_tl || cv_msg_part || iv_plan_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --�o�׃y�[�X�v�����(FROM)
    lv_param_msg := gv_shipment_from_tl || cv_msg_part || iv_shipment_from;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --�o�׃y�[�X�v�����(TO)
    lv_param_msg := gv_shipment_to_tl || cv_msg_part || iv_shipment_to;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --�o�ח\���敪
    lv_param_msg := cv_forcast_type_tl || cv_msg_part || iv_forcast_type;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ===============================
    -- 1.�v��敪
    -- ===============================
    BEGIN
      IF ( iv_plan_type = cv_plan_type_shipped ) THEN
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
      gv_plan_type := iv_plan_type;
    EXCEPTION
      WHEN param_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00055
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 2.�o�׃y�[�X�v�����(FROM-TO)
    -- ===============================
    BEGIN
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_from
                        ,iv_format      => cv_date_format
                      );
      IF ( NOT lb_chk_value ) THEN
        lv_invalid_value := iv_shipment_from;
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_from := TO_DATE(iv_shipment_from, cv_date_format);
--
      lb_chk_value := xxcop_common_pkg.chk_date_format(
                         iv_value       => iv_shipment_to
                        ,iv_format      => cv_date_format
                      );
      IF ( NOT lb_chk_value ) THEN
        lv_invalid_value := iv_shipment_to;
        RAISE date_invalid_expt;
      END IF;
      gd_shipment_to := TO_DATE(iv_shipment_to, cv_date_format);
--
    EXCEPTION
      WHEN date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00011
                       ,iv_token_name1  => cv_msg_00011_token_1
                       ,iv_token_value1 => lv_invalid_value
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 3.�o�׃y�[�X�v�����(FROM-TO)�t�]�`�F�b�N
    -- ===============================
    IF ( gd_shipment_from >= gd_shipment_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_appl_cont
                     ,iv_name         => cv_msg_00025
                     ,iv_token_name1  => cv_msg_00025_token_1
                     ,iv_token_value1 => gv_shipment_from_tl
                     ,iv_token_name2  => cv_msg_00025_token_2
                     ,iv_token_value2 => gv_shipment_to_tl
                   );
      RAISE internal_api_expt;
    END IF;
--
    -- ===============================
    -- 4.�o�׃y�[�X�v�����(FROM-TO)�ߋ����`�F�b�N
    -- ===============================
    BEGIN
      IF ( gd_shipment_from > cd_sysdate ) THEN
        lv_invalid_value := gv_shipment_from_tl;
        RAISE past_date_invalid_expt;
      END IF;
--
      IF ( gd_shipment_to > cd_sysdate ) THEN
        lv_invalid_value := gv_shipment_to_tl;
        RAISE past_date_invalid_expt;
      END IF;
--
    EXCEPTION
      WHEN past_date_invalid_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00047
                       ,iv_token_name1  => cv_msg_00047_token_1
                       ,iv_token_value1 => lv_invalid_value
                     );
        RAISE internal_api_expt;
    END;
--
    -- ===============================
    -- 5.�o�ח\�����Ԃ̎擾
    -- ===============================
    IF ( iv_forcast_type = cv_forcast_type_this ) THEN
      --����
      gd_forcast_from := TRUNC(cd_sysdate, cv_trunc_month);
      gd_forcast_to   := LAST_DAY(cd_sysdate);
    ELSIF ( iv_forcast_type = cv_forcast_type_next ) THEN
      --����
      gd_forcast_from := ADD_MONTHS(TRUNC(cd_sysdate, cv_trunc_month), 1);
      gd_forcast_to   := LAST_DAY(ADD_MONTHS(cd_sysdate, 1));
    ELSIF ( iv_forcast_type = cv_forcast_type_2month ) THEN
      --����+����
      gd_forcast_from := TRUNC(cd_sysdate, cv_trunc_month);
      gd_forcast_to   := LAST_DAY(ADD_MONTHS(cd_sysdate, 1));
    ELSE
      --NULL
      gd_forcast_from := NULL;
      gd_forcast_to   := NULL;
    END IF;
--
    -- ===============================
    -- 6.�v���t�@�C���̎擾
    -- ===============================
    BEGIN
      --�}�X�^�g�D
      lv_profile_name := cv_upf_master_org_id;
      lv_value := fnd_profile.value( cv_pf_master_org_id );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_master_org_id := TO_NUMBER(lv_value);
--
      --�_�~�[�o�בg�D
      lv_profile_name := cv_upf_dummy_src_org_id;
      lv_value := fnd_profile.value( cv_pf_dummy_src_org_id );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
--20090414_Ver1.2_T1_0541_SCS.Goto_MOD_START
--      gn_dummy_src_org_id := TO_NUMBER(lv_value);
      BEGIN
        SELECT mp.organization_id
        INTO gn_dummy_src_org_id
        FROM mtl_parameters mp
        WHERE mp.organization_code = lv_value;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE profile_invalid_expt;
      END;
--20090414_Ver1.2_T1_0541_SCS.Goto_MOD_END
--
      --�N�x�����o�b�t�@����
      lv_profile_name := cv_upf_fresh_buffer_days;
      lv_value := fnd_profile.value( cv_pf_fresh_buffer_days );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_freshness_buffer_days := TO_NUMBER(lv_value);
--
      --�ŏI��������
      lv_profile_name := cv_upf_deadline_months;
      lv_value := fnd_profile.value( cv_pf_deadline_months );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_deadline_months := TO_NUMBER(lv_value);
--
      --�ŏI�����o�b�t�@����
      lv_profile_name := cv_upf_deadline_days;
      lv_value := fnd_profile.value( cv_pf_deadline_days );
      IF ( lv_value IS NULL ) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_deadline_buffer_days := TO_NUMBER(lv_value);
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
    -- 7.�����v��쐬���̎擾
    -- ===============================
    gd_plan_date := cd_sysdate + 1;
--
    -- ===============================
    -- 8.�֘A�e�[�u���폜
    -- ===============================
    delete_table(
       ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      IF ( lv_errbuf IS NULL ) THEN
        RAISE internal_api_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
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
   * Description      : �����v�搧��}�X�^�擾(A-2)
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
    ln_ship_org_forcast_qty          NUMBER;     --�ړ����q�ɓ��ɗ\�萔
    ln_receipt_org_forcast_qty       NUMBER;     --�ړ���q�ɓ��ɗ\�萔
    ln_exists                        NUMBER;     --���݃`�F�b�N
--
    -- *** ���[�J���E�J�[�\�� ***
    --�i�ڏ��̎擾
    CURSOR xicv_cur IS
      SELECT xicv.inventory_item_id
            ,xicv.item_id
            ,xicv.item_no
            ,xicv.item_short_name
            ,xicv.prod_class_code
--20090407_Ver1.1_T1_0273_SCS.Goto_MOD_START
--            ,TO_NUMBER(xicv.num_of_cases)
            ,NVL(TO_NUMBER(xicv.num_of_cases), 1)
--20090407_Ver1.1_T1_0273_SCS.Goto_MOD_END
      FROM  xxcop_item_categories1_v xicv
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
           ,xxcmm_system_items_b     xsib
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
      WHERE xicv.inactive_ind               <> cn_xicv_inactive
        AND xicv.inventory_item_status_code <> cv_xicv_status
        AND xicv.prod_class_code             = cv_product_class_drink
        AND cd_sysdate BETWEEN NVL(xicv.start_date_active, cd_sysdate)
                           AND NVL(xicv.end_date_active, cd_sysdate)
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_START
        AND xsib.item_status                IN (cn_xsib_status_temporary
                                               ,cn_xsib_status_registered
                                               ,cn_xsib_status_obsolete)
        AND xsib.item_status_apply_date     <= cd_sysdate
        AND xicv.item_id                     = xsib.item_id
--20090407_Ver1.1_T1_0366_SCS.Goto_ADD_END
        AND NOT EXISTS (
          SELECT 'x'
          FROM xxcmn_sourcing_rules xsr
          WHERE xsr.plan_item_flag = cn_xsr_plan_item
            AND xsr.item_code      = xicv.item_no
            AND cd_sysdate BETWEEN NVL(xsr.start_date_active, cd_sysdate)
                               AND NVL(xsr.end_date_active, cd_sysdate)
        )
--20090414_Ver1.2_T1_0539_SCS.Goto_DEL_START
--        AND xicv.item_no IN ( '0006999', '0007000', '0007001' )
--20090414_Ver1.2_T1_0539_SCS.Goto_DEL_END
      ORDER BY xicv.item_no ASC;
--
    --�o�H���̎擾
    CURSOR msr_cur(
              in_inventory_item_id NUMBER
    ) IS
      SELECT source_organization_id
            ,receipt_organization_id
            ,assignment_set_type
            ,assignment_type
            ,sourcing_rule_type
            ,sourcing_rule_name
            ,shipping_type
            ,freshness_condition1
            ,stock_maintenance_days1
            ,max_stock_days1
            ,freshness_condition2
            ,stock_maintenance_days2
            ,max_stock_days2
            ,freshness_condition3
            ,stock_maintenance_days3
            ,max_stock_days3
            ,freshness_condition4
            ,stock_maintenance_days4
            ,max_stock_days4
            ,manufacture_date
            ,start_date_active
            ,end_date_active
            ,set_qty
            ,movement_qty
      FROM (
        WITH msr_vw AS (
          --�S�o�H(��{�����v��A���ʉ����v��A�o�׌v��敪�_�~�[�o�H)
          SELECT msso.source_organization_id             source_organization_id --�ړ����q��ID
                ,msro.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,mas.assignment_set_name                    assignment_set_name --�����Z�b�g��
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
--                ,NVL(msa.organization_id, msro.receipt_organization_id)
--                                                               organization_id --�g�D
                ,msa.organization_id                            organization_id --�g�D
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
                ,mas.attribute1                             assignment_set_type --�����Z�b�g�敪
                ,msa.assignment_type                            assignment_type --������^�C�v
                ,msa.sourcing_rule_type                      sourcing_rule_type --�\�[�X���[���^�C�v
                ,msr.sourcing_rule_name                      sourcing_rule_name --�\�[�X���[����
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
          FROM mrp_assignment_sets mas
              ,mrp_sr_assignments  msa
              ,mrp_sourcing_rules  msr
              ,mrp_sr_receipt_org  msro
              ,mrp_sr_source_org   msso
              ,fnd_lookup_values   flv1
              ,fnd_lookup_values   flv2
          WHERE mas.assignment_set_id       = msa.assignment_set_id
            AND mas.attribute1             IN (cv_base_plan
                                              ,cv_custom_plan)
            AND msr.sourcing_rule_id        = msa.sourcing_rule_id
            AND msro.sourcing_rule_id       = msr.sourcing_rule_id
            AND msro.sr_receipt_id          = msso.sr_receipt_id
            AND cd_sysdate BETWEEN NVL(msro.effective_date, cd_sysdate)
                               AND NVL(msro.disable_date, cd_sysdate)
            AND flv1.lookup_type            = cv_flv_assignment_name
            AND flv1.lookup_code            = mas.assignment_set_name
            AND flv1.language               = cv_lang
            AND flv1.source_lang            = cv_lang
            AND flv1.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                               AND NVL(flv1.end_date_active, cd_sysdate)
            AND flv2.lookup_type            = cv_flv_assign_priority
            AND flv2.lookup_code            = msa.assignment_type
            AND flv2.language               = cv_lang
            AND flv2.source_lang            = cv_lang
            AND flv2.enabled_flag           = cv_enable
            AND cd_sysdate BETWEEN NVL(flv2.start_date_active, cd_sysdate)
                               AND NVL(flv2.end_date_active, cd_sysdate)
            AND NVL(msa.inventory_item_id, in_inventory_item_id) = in_inventory_item_id
        )
        , msr_dummy_vw AS (
          --�o�׌v��敪�_�~�[�o�H
          SELECT msrv.source_organization_id             source_organization_id --�ړ����q��ID
                ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
                ,msrv.organization_id                           organization_id --�g�D
                ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
                ,msrv.assignment_type                           assignment_type --������^�C�v
                ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
                ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
                ,msrv.attribute1                                     attribute1 --�o�׌v��敪
                ,msrv.attribute2                                     attribute2 --�N�x����1
                ,msrv.attribute3                                     attribute3 --�݌Ɉێ�����1
                ,msrv.attribute4                                     attribute4 --�ő�݌ɓ���1
                ,msrv.attribute5                                     attribute5 --�N�x����2
                ,msrv.attribute6                                     attribute6 --�݌Ɉێ�����2
                ,msrv.attribute7                                     attribute7 --�ő�݌ɓ���2
                ,msrv.attribute8                                     attribute8 --�N�x����3
                ,msrv.attribute9                                     attribute9 --�݌Ɉێ�����3
                ,msrv.attribute10                                   attribute10 --�ő�݌ɓ���3
                ,msrv.attribute11                                   attribute11 --�N�x����4
                ,msrv.attribute12                                   attribute12 --�݌Ɉێ�����4
                ,msrv.attribute13                                   attribute13 --�ő�݌ɓ���4
                ,msrv.assign_type_priority                 assign_type_priority --������^�C�v�D��x
--20090407_Ver1.1_T1_0367_SCS.Goto_DEL_START
--                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
--                                                 ,msrv.organization_id
--                                     ORDER BY     msrv.assign_type_priority ASC
--                                   )                                   priority --�D�揇��
--20090407_Ver1.1_T1_0367_SCS.Goto_DEL_END
          FROM msr_vw msrv
          WHERE msrv.assignment_set_type    IN (cv_base_plan)
            AND msrv.source_organization_id IN (gn_master_org_id)
        )
        , msr_base_vw AS (
          --��{�����v��
          SELECT msrv.source_organization_id             source_organization_id --�ړ����q��ID
                ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
                ,msrv.organization_id                           organization_id --�g�D
                ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
                ,msrv.assignment_type                           assignment_type --������^�C�v
                ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
                ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute1)
                     ELSE TO_NUMBER(msrv.attribute1)
                 END                                              shipping_type --�o�׌v��敪
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute2
                     ELSE msrv.attribute2
                 END                                       freshness_condition1 --�N�x����1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute3)
                     ELSE TO_NUMBER(msrv.attribute3)
                 END                                    stock_maintenance_days1 --�݌Ɉێ�����1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute4)
                     ELSE TO_NUMBER(msrv.attribute4)
                 END                                            max_stock_days1 --�ő�݌ɓ���1
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute5
                     ELSE msrv.attribute5
                 END                                       freshness_condition2 --�N�x����2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute6)
                     ELSE TO_NUMBER(msrv.attribute6)
                 END                                    stock_maintenance_days2 --�݌Ɉێ�����2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute7)
                     ELSE TO_NUMBER(msrv.attribute7)
                 END                                            max_stock_days2 --�ő�݌ɓ���2
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute8
                     ELSE msrv.attribute8
                 END                                       freshness_condition3 --�N�x����3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute9)
                     ELSE TO_NUMBER(msrv.attribute9)
                 END                                    stock_maintenance_days3 --�݌Ɉێ�����3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute10)
                     ELSE TO_NUMBER(msrv.attribute10)
                 END                                            max_stock_days3 --�ő�݌ɓ���3
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN mdv.attribute11
                     ELSE msrv.attribute11
                 END                                       freshness_condition4 --�N�x����4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute12)
                     ELSE TO_NUMBER(msrv.attribute12)
                 END                                    stock_maintenance_days4 --�݌Ɉێ�����4
                ,CASE
                   WHEN mdv.source_organization_id IS NOT NULL
                     THEN TO_NUMBER(mdv.attribute13)
                     ELSE TO_NUMBER(msrv.attribute13)
                 END                                            max_stock_days4 --�ő�݌ɓ���4
                ,msrv.assign_type_priority                 assign_type_priority --������^�C�v�D��x
                ,ROW_NUMBER() OVER ( PARTITION BY msrv.source_organization_id
                                                 ,msrv.receipt_organization_id
                                     ORDER BY     msrv.assign_type_priority ASC
                                                 ,msrv.sourcing_rule_type   DESC
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_START
                                                 ,mdv.assign_type_priority  ASC
--20090407_Ver1.1_T1_0367_SCS.Goto_ADD_END
                                   )                                   priority --�D�揇��
                ,RANK () OVER ( PARTITION BY msrv.receipt_organization_id
                                ORDER BY     msrv.assign_type_priority    ASC
                                            ,msrv.sourcing_rule_type      DESC
                                            ,msrv.source_organization_id  DESC
                              )                            custom_plan_priority --���ʉ����v��D�揇��
          FROM msr_vw msrv
              ,msr_dummy_vw mdv
          WHERE msrv.assignment_set_type        IN (cv_base_plan)
            AND msrv.source_organization_id NOT IN (gn_master_org_id
                                                   ,gn_dummy_src_org_id)
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
--            AND msrv.receipt_organization_id = mdv.organization_id(+)
--            AND mdv.priority(+) = 1
            AND msrv.receipt_organization_id = NVL( mdv.organization_id(+), msrv.receipt_organization_id )
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
        )
        , msr_custom_vw AS (
          --���ʉ����v��
          SELECT msrv.source_organization_id             source_organization_id --�ړ����q��ID
                ,msrv.receipt_organization_id           receipt_organization_id --�ړ���g�DID
                ,msrv.assignment_set_name                   assignment_set_name --�����Z�b�g��
                ,msrv.organization_id                           organization_id --�g�D
                ,msrv.assignment_set_type                   assignment_set_type --�����Z�b�g�敪
                ,msrv.assignment_type                           assignment_type --������^�C�v
                ,msrv.sourcing_rule_type                     sourcing_rule_type --�\�[�X���[���^�C�v
                ,msrv.sourcing_rule_name                     sourcing_rule_name --�\�[�X���[����
                ,mbv.shipping_type                                shipping_type --�o�׌v��敪
                ,mbv.freshness_condition1                  freshness_condition1 --�N�x����1
                ,mbv.stock_maintenance_days1            stock_maintenance_days1 --�݌Ɉێ�����1
                ,mbv.max_stock_days1                            max_stock_days1 --�ő�݌ɓ���1
                ,mbv.freshness_condition2                  freshness_condition2 --�N�x����2
                ,mbv.stock_maintenance_days2            stock_maintenance_days2 --�݌Ɉێ�����2
                ,mbv.max_stock_days2                            max_stock_days2 --�ő�݌ɓ���2
                ,mbv.freshness_condition3                  freshness_condition3 --�N�x����3
                ,mbv.stock_maintenance_days3            stock_maintenance_days3 --�݌Ɉێ�����3
                ,mbv.max_stock_days3                            max_stock_days3 --�ő�݌ɓ���3
                ,mbv.freshness_condition4                  freshness_condition4 --�N�x����4
                ,mbv.stock_maintenance_days4            stock_maintenance_days4 --�݌Ɉێ�����4
                ,mbv.max_stock_days4                            max_stock_days4 --�ő�݌ɓ���4
                ,TO_DATE(msrv.attribute1, cv_date_format)      manufacture_date --�J�n�����N����
                ,TO_DATE(msrv.attribute2, cv_date_format)     start_date_active --�L���J�n��
                ,TO_DATE(msrv.attribute3, cv_date_format)       end_date_active --�L���I����
                ,TO_NUMBER(msrv.attribute4)                             set_qty --�ݒ萔��
                ,TO_NUMBER(msrv.attribute5)                        movement_qty --�ړ���
                ,msrv.assign_type_priority                 assign_type_priority --������^�C�v�D��x
          FROM msr_vw msrv
              ,msr_base_vw mbv
          WHERE msrv.assignment_set_type        IN (cv_custom_plan)
            AND msrv.source_organization_id NOT IN (gn_master_org_id
                                                   ,gn_dummy_src_org_id)
            AND msrv.receipt_organization_id = mbv.receipt_organization_id
            AND mbv.custom_plan_priority = 1
        )
        SELECT mbv.source_organization_id   source_organization_id
              ,mbv.receipt_organization_id  receipt_organization_id
              ,mbv.organization_id          organization_id
              ,mbv.assignment_set_type      assignment_set_type
              ,mbv.assignment_type          assignment_type
              ,mbv.sourcing_rule_type       sourcing_rule_type
              ,mbv.sourcing_rule_name       sourcing_rule_name
              ,mbv.shipping_type            shipping_type
              ,mbv.freshness_condition1     freshness_condition1
              ,mbv.stock_maintenance_days1  stock_maintenance_days1
              ,mbv.max_stock_days1          max_stock_days1
              ,mbv.freshness_condition2     freshness_condition2
              ,mbv.stock_maintenance_days2  stock_maintenance_days2
              ,mbv.max_stock_days2          max_stock_days2
              ,mbv.freshness_condition3     freshness_condition3
              ,mbv.stock_maintenance_days3  stock_maintenance_days3
              ,mbv.max_stock_days3          max_stock_days3
              ,mbv.freshness_condition4     freshness_condition4
              ,mbv.stock_maintenance_days4  stock_maintenance_days4
              ,mbv.max_stock_days4          max_stock_days4
              ,NULL                         manufacture_date
              ,NULL                         start_date_active
              ,NULL                         end_date_active
              ,NULL                         set_qty
              ,NULL                         movement_qty
        FROM msr_base_vw mbv
        WHERE mbv.priority = 1
        UNION ALL
        SELECT mcv.source_organization_id   source_organization_id
              ,mcv.receipt_organization_id  receipt_organization_id
              ,mcv.organization_id          organization_id
              ,mcv.assignment_set_type      assignment_set_type
              ,mcv.assignment_type          assignment_type
              ,mcv.sourcing_rule_type       sourcing_rule_type
              ,mcv.sourcing_rule_name       sourcing_rule_name
              ,mcv.shipping_type            shipping_type
              ,mcv.freshness_condition1     freshness_condition1
              ,mcv.stock_maintenance_days1  stock_maintenance_days1
              ,mcv.max_stock_days1          max_stock_days1
              ,mcv.freshness_condition2     freshness_condition2
              ,mcv.stock_maintenance_days2  stock_maintenance_days2
              ,mcv.max_stock_days2          max_stock_days2
              ,mcv.freshness_condition3     freshness_condition3
              ,mcv.stock_maintenance_days3  stock_maintenance_days3
              ,mcv.max_stock_days3          max_stock_days3
              ,mcv.freshness_condition4     freshness_condition4
              ,mcv.stock_maintenance_days4  stock_maintenance_days4
              ,mcv.max_stock_days4          max_stock_days4
              ,mcv.manufacture_date         manufacture_date
              ,mcv.start_date_active        start_date_active
              ,mcv.end_date_active          end_date_active
              ,mcv.set_qty                  set_qty
              ,mcv.movement_qty             movement_qty
        FROM msr_custom_vw mcv
      )
      ORDER BY assignment_set_type DESC;
    -- *** ���[�J���E���R�[�h ***
    l_xwsp_rec                xxcop_wk_ship_planning%ROWTYPE;
    l_fc_tab                  g_freshness_condition_ttype;
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
                      || '(' || TO_CHAR( SYSTIMESTAMP, cv_timestamp_format ) || ')'
    );
--
    OPEN xicv_cur;
    <<xicv_loop>>
    LOOP
      --�i�ڏ��̎擾
      FETCH xicv_cur INTO l_xwsp_rec.inventory_item_id
                         ,l_xwsp_rec.item_id
                         ,l_xwsp_rec.item_no
                         ,l_xwsp_rec.item_name
                         ,l_xwsp_rec.prod_class_code
                         ,l_xwsp_rec.num_of_case;
      EXIT WHEN xicv_cur%NOTFOUND;
      IF ( l_xwsp_rec.num_of_case = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00061
                       ,iv_token_name1  => cv_msg_00061_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      --�f�o�b�N���b�Z�[�W�o��(�i��)
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => l_xwsp_rec.item_no     || ','
                        || l_xwsp_rec.num_of_case
      );
      --�z���P�ʂ̎擾
      xxcop_common_pkg2.get_unit_delivery(
         in_item_id              => l_xwsp_rec.item_id
        ,id_ship_date            => gd_plan_date
        ,on_palette_max_cs_qty   => l_xwsp_rec.palette_max_cs_qty
        ,on_palette_max_step_qty => l_xwsp_rec.palette_max_step_qty
        ,ov_errbuf               => lv_errbuf
        ,ov_retcode              => lv_retcode
        ,ov_errmsg               => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00057
                       ,iv_token_name1  => cv_msg_00057_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      IF ( l_xwsp_rec.palette_max_cs_qty = 0
        OR l_xwsp_rec.palette_max_step_qty = 0 )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00059
                       ,iv_token_name1  => cv_msg_00059_token_1
                       ,iv_token_value1 => l_xwsp_rec.item_no
                     );
        RAISE internal_api_expt;
      END IF;
      OPEN msr_cur( l_xwsp_rec.inventory_item_id );
      <<msr_loop>>
      LOOP
        BEGIN
          --�o�H���̎擾
          FETCH msr_cur INTO l_xwsp_rec.ship_org_id
                            ,l_xwsp_rec.receipt_org_id
                            ,l_xwsp_rec.assignment_set_type
                            ,l_xwsp_rec.assignment_type
                            ,l_xwsp_rec.sourcing_rule_type
                            ,l_xwsp_rec.sourcing_rule_name
                            ,l_xwsp_rec.shipping_type
                            ,l_fc_tab(1).freshness_condition
                            ,l_fc_tab(1).stock_maintenance_days
                            ,l_fc_tab(1).max_stock_days
                            ,l_fc_tab(2).freshness_condition
                            ,l_fc_tab(2).stock_maintenance_days
                            ,l_fc_tab(2).max_stock_days
                            ,l_fc_tab(3).freshness_condition
                            ,l_fc_tab(3).stock_maintenance_days
                            ,l_fc_tab(3).max_stock_days
                            ,l_fc_tab(4).freshness_condition
                            ,l_fc_tab(4).stock_maintenance_days
                            ,l_fc_tab(4).max_stock_days
                            ,l_xwsp_rec.manufacture_date
                            ,l_xwsp_rec.start_date_active
                            ,l_xwsp_rec.end_date_active
                            ,l_xwsp_rec.set_qty
                            ,l_xwsp_rec.movement_qty;
          EXIT WHEN msr_cur%NOTFOUND;
          --�f�o�b�N���b�Z�[�W�o��(�o�H)
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => l_xwsp_rec.assignment_set_type || ','
                            || l_xwsp_rec.assignment_type     || ','
                            || l_xwsp_rec.sourcing_rule_name  || ','
                            || l_xwsp_rec.ship_org_id         || ','
                            || l_xwsp_rec.receipt_org_id
          );
          --��{�����v��̏ꍇ
          IF ( l_xwsp_rec.assignment_set_type = cv_base_plan ) THEN
            --���ʉ����v��œ����o�H���o�^����Ă���ꍇ�A�X�L�b�v
            SELECT COUNT(*)
            INTO   ln_exists
            FROM xxcop_wk_ship_planning xwsp
            WHERE xwsp.transaction_id = cn_request_id
              AND xwsp.item_id        = l_xwsp_rec.item_id
              AND xwsp.ship_org_id    = l_xwsp_rec.ship_org_id
              AND xwsp.receipt_org_id = l_xwsp_rec.receipt_org_id;
            IF ( ln_exists > 0 ) THEN
              RAISE obsolete_skip_expt;
            END IF;
          END IF;
          --�ړ����q�ɏ��̎擾
          xxcop_common_pkg2.get_org_info(
             in_organization_id    => l_xwsp_rec.ship_org_id
            ,ov_organization_code  => l_xwsp_rec.ship_org_code
            ,ov_whse_name          => l_xwsp_rec.ship_org_name
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_id
                         );
            RAISE internal_api_expt;
          END IF;
          --�ړ����q�ɂ̍݌ɕi�ڃ`�F�b�N
          xxcop_common_pkg2.chk_item_exists(
             in_inventory_item_id  => l_xwsp_rec.inventory_item_id
            ,in_organization_id    => l_xwsp_rec.ship_org_id
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --�ړ���q�ɏ��̎擾
          xxcop_common_pkg2.get_org_info(
             in_organization_id    => l_xwsp_rec.receipt_org_id
            ,ov_organization_code  => l_xwsp_rec.receipt_org_code
            ,ov_whse_name          => l_xwsp_rec.receipt_org_name
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_id
                         );
            RAISE internal_api_expt;
          END IF;
          --�ړ���q�ɂ̍݌ɕi�ڃ`�F�b�N
          xxcop_common_pkg2.chk_item_exists(
             in_inventory_item_id  => l_xwsp_rec.inventory_item_id
            ,in_organization_id    => l_xwsp_rec.receipt_org_id
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00050
                           ,iv_token_name1  => cv_msg_00050_token_1
                           ,iv_token_value1 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --�O������̃`�F�b�N
          chk_route_prereq(
             i_xwsp_rec            => l_xwsp_rec
            ,i_fc_tab              => l_fc_tab
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
              RAISE internal_api_expt;
            ELSE
              RAISE global_api_expt;
            END IF;
          END IF;
          --�z�����[�h�^�C���̎擾
          xxcop_common_pkg2.get_deliv_lead_time(
             iv_from_org_code      => l_xwsp_rec.ship_org_code
            ,iv_to_org_code        => l_xwsp_rec.receipt_org_code
            ,id_product_date       => gd_plan_date
            ,on_delivery_lt        => l_xwsp_rec.delivery_lead_time
            ,ov_errbuf             => lv_errbuf
            ,ov_retcode            => lv_retcode
            ,ov_errmsg             => lv_errmsg
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_appl_cont
                           ,iv_name         => cv_msg_00053
                           ,iv_token_name1  => cv_msg_00053_token_1
                           ,iv_token_value1 => l_xwsp_rec.ship_org_code
                           ,iv_token_name2  => cv_msg_00053_token_2
                           ,iv_token_value2 => l_xwsp_rec.receipt_org_code
                         );
            RAISE internal_api_expt;
          END IF;
          --�o�ד�
          l_xwsp_rec.shipping_date := gd_plan_date;
          --���ד�
          l_xwsp_rec.receipt_date  := gd_plan_date + l_xwsp_rec.delivery_lead_time;
          --���ʉ����v��̃`�F�b�N
          IF ( l_xwsp_rec.assignment_set_type = cv_custom_plan ) THEN
            --���ד����L���J�n���`�L���I�����̊��ԊO�̏ꍇ�A�X�L�b�v
            IF ( NOT ( l_xwsp_rec.start_date_active <= l_xwsp_rec.receipt_date
                   AND l_xwsp_rec.end_date_active   >= l_xwsp_rec.receipt_date ) )
            THEN
              RAISE obsolete_skip_expt;
            END IF;
          END IF;
          --�o�׃y�[�X�̌v�Z
          proc_ship_pace(
             io_xwsp_rec  => l_xwsp_rec
            ,ov_retcode   => lv_retcode
            ,ov_errbuf    => lv_errbuf
            ,ov_errmsg    => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
              RAISE internal_api_expt;
            ELSE
              RAISE global_api_expt;
            END IF;
          END IF;
          --�����v�惏�[�N�e�[�u���o�^
          entry_xwsp(
             i_xwsp_rec   => l_xwsp_rec
            ,i_fc_tab     => l_fc_tab
            ,ov_retcode   => lv_retcode
            ,ov_errbuf    => lv_errbuf
            ,ov_errmsg    => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            IF ( lv_errbuf IS NULL ) THEN
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
    END LOOP xicv_loop;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '�i�ڃ}�X�^�Ώی��� :' || xicv_cur%ROWCOUNT
    );
    CLOSE xicv_cur;
    --�Ώی����̊m�F
    SELECT COUNT(*)
    INTO   ln_exists
    FROM xxcop_wk_ship_planning xwsp
    WHERE transaction_id = cn_request_id;
    IF ( ln_exists = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_00003
                   );
      RAISE internal_api_expt;
    END IF;
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => '�o�H��񌏐� :' || ln_exists
    );
    --�o�בq�ɂ̉����v�搧��}�X�^���擾
    get_ship_route(
       ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      IF ( lv_errbuf IS NULL ) THEN
        RAISE internal_api_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
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
  END get_msr_route;
--
  /**********************************************************************************
   * Procedure Name   : get_xwsp
   * Description      : �����v�惏�[�N�e�[�u���擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_xwsp(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xwsp'; -- �v���O������
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
    lv_receipt_org_code       xxcop_wk_ship_planning.receipt_org_code%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    --�ړ���q�ɂ��擾
    CURSOR xwsp_cur IS
      SELECT xwsp.item_no                     item_no
            ,xwsp.receipt_org_code            receipt_org_code
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id = cn_request_id
        AND xwsp.plant_org_id  IS NULL
      GROUP BY xwsp.item_no
              ,xwsp.receipt_org_code
      ORDER BY xwsp.item_no                 ASC
              ,MIN(xwsp.delivery_lead_time) ASC
              ,xwsp.receipt_org_code        ASC;
--
    --�ړ����q�ɂ��擾
    CURSOR xwsp_so_cur(
              lv_item_no          VARCHAR2
             ,lv_receipt_org_code VARCHAR2
    ) IS
      SELECT xwsp.item_no                     item_no
            ,xwsp.ship_org_code               ship_org_code
            ,xwsp.assignment_set_type         assignment_set_type
      FROM xxcop_wk_ship_planning xwsp
      WHERE xwsp.transaction_id   = cn_request_id
        AND xwsp.item_no          = lv_item_no
        AND xwsp.receipt_org_code = lv_receipt_org_code
        AND xwsp.plant_org_id    IS NULL
        AND NOT EXISTS (
          SELECT 'x'
          FROM xxcop_wk_yoko_plan_output xwypo
          WHERE xwypo.transaction_id   = xwsp.transaction_id
            AND xwypo.ship_org_code    = xwsp.ship_org_code
            AND xwypo.item_no          = xwsp.item_no
        )
      GROUP BY xwsp.item_no
              ,xwsp.ship_org_code
              ,xwsp.assignment_set_type
      ORDER BY xwsp.assignment_set_type DESC
              ,xwsp.ship_org_code       ASC;
--
    -- *** ���[�J���E���R�[�h ***
    l_xwsp_rec                g_xwsp_ref_rtype;
    l_xwypo_tab               g_xwypo_ref_ttype;
    l_cp_tab                  g_condition_priority_ttype;
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
    gn_group_id := 0;
--
    --�ړ���q�ɂ��擾
    <<xwsp_ro_loop>>
    FOR l_xwsp_ro_rec IN xwsp_cur LOOP
      --�f�o�b�N���b�Z�[�W�o��
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'xwsp_ro_loop'                  || ','
                        || l_xwsp_ro_rec.item_no           || ','
                        || l_xwsp_ro_rec.receipt_org_code
      );
      BEGIN
        --�ړ����q�ɂ��擾
        <<xwsp_so_loop>>
        FOR l_xwsp_so_rec IN xwsp_so_cur(
                                l_xwsp_ro_rec.item_no
                               ,l_xwsp_ro_rec.receipt_org_code
                             ) LOOP
          --�f�o�b�N���b�Z�[�W�o��
          xxcop_common_pkg.put_debug_message(
             iov_debug_mode => gv_debug_mode
            ,iv_value       => 'xwsp_so_loop'              || ','
                            || l_xwsp_so_rec.item_no       || ','
                            || l_xwsp_so_rec.ship_org_code
          );
          gn_group_id := gn_group_id + 1;
          --�D�揇�ʂ̍����N�x�������牡���v��쐬
          SELECT MIN(xwsp.freshness_priority)   freshness_priority
                ,xwsp.freshness_condition       freshness_condition
                ,MIN(flv.attribute1)            condition_type
                ,TO_NUMBER(MIN(flv.attribute2)) condition_value
          BULK COLLECT INTO l_cp_tab
          FROM xxcop_wk_ship_planning xwsp
              ,fnd_lookup_values      flv
          WHERE xwsp.transaction_id      = cn_request_id
            AND xwsp.item_no             = l_xwsp_so_rec.item_no
            AND xwsp.ship_org_code       = l_xwsp_so_rec.ship_org_code
            AND flv.lookup_type          = cv_flv_freshness_cond
            AND flv.lookup_code          = xwsp.freshness_condition
            AND flv.language             = cv_lang
            AND flv.source_lang          = cv_lang
            AND flv.enabled_flag         = cv_enable
            AND cd_sysdate BETWEEN NVL(flv.start_date_active, cd_sysdate)
                               AND NVL(flv.end_date_active, cd_sysdate)
          GROUP BY xwsp.freshness_condition
          ORDER BY freshness_priority ASC
                  ,condition_type     DESC
                  ,condition_value    ASC;
          <<priority_loop>>
          FOR l_cp_idx IN l_cp_tab.FIRST .. l_cp_tab.LAST LOOP
            --�f�o�b�N���b�Z�[�W�o��
            xxcop_common_pkg.put_debug_message(
               iov_debug_mode => gv_debug_mode
              ,iv_value       => 'priority_loop'                        || ','
                              || l_cp_tab(l_cp_idx).freshness_condition
            );
            --�ړ����q�ɂ̑N�x�������擾
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_START
            SELECT xwspv.item_id
                  ,xwspv.item_no
                  ,xwspv.ship_org_id
                  ,xwspv.ship_org_code
                  ,xwspv.shipping_date
                  ,xwspv.before_stock
                  ,xwspv.manufacture_date
                  ,xwspv.shipping_pace
                  ,xwspv.stock_maintenance_days
                  ,xwspv.max_stock_days
            INTO l_xwsp_rec
            FROM (
              SELECT xwsp.item_id                     item_id
                    ,xwsp.item_no                     item_no
                    ,xwsp.receipt_org_id              ship_org_id
                    ,xwsp.receipt_org_code            ship_org_code
                    ,xwsp.shipping_date               shipping_date
                    ,NULL                             before_stock
                    ,NULL                             manufacture_date
                    ,xwsp.shipping_pace               shipping_pace
                    ,xwsp.stock_maintenance_days      stock_maintenance_days
                    ,xwsp.max_stock_days              max_stock_days
                    ,ROW_NUMBER() OVER ( ORDER BY xwsp.freshness_priority ASC )
                                                      freshness_priority
              FROM xxcop_wk_ship_planning xwsp
              WHERE xwsp.transaction_id      = cn_request_id
                AND xwsp.item_no             = l_xwsp_so_rec.item_no
                AND xwsp.plant_org_id        = gn_dummy_src_org_id
                AND xwsp.receipt_org_code    = l_xwsp_so_rec.ship_org_code
                AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition
            ) xwspv
            WHERE xwspv.freshness_priority = 1;
--            SELECT xwsp.item_id                     item_id
--                  ,xwsp.item_no                     item_no
--                  ,xwsp.receipt_org_id              ship_org_id
--                  ,xwsp.receipt_org_code            ship_org_code
--                  ,xwsp.shipping_date               shipping_date
--                  ,NULL                             before_stock
--                  ,NULL                             manufacture_date
--                  ,xwsp.shipping_pace               shipping_pace
--                  ,xwsp.stock_maintenance_days      stock_maintenance_days
--                  ,xwsp.max_stock_days              max_stock_days
--            INTO l_xwsp_rec
--            FROM xxcop_wk_ship_planning xwsp
--            WHERE xwsp.transaction_id      = cn_request_id
--              AND xwsp.item_no             = l_xwsp_so_rec.item_no
--              AND xwsp.plant_org_id        = gn_dummy_src_org_id
--              AND xwsp.receipt_org_code    = l_xwsp_so_rec.ship_org_code
--              AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition;
--20090407_Ver1.1_T1_0367_SCS.Goto_MOD_END
            --�ړ����q�ɂ̑N�x�����𖞂����݌ɐ��̎擾
            get_stock_quantity(
               in_item_id          => l_xwsp_rec.item_id
              ,iv_whse_code        => l_xwsp_rec.ship_org_code
              ,id_plan_date        => l_xwsp_rec.shipping_date
              ,in_stock_days       => l_xwsp_rec.max_stock_days
              ,i_cp_rec            => l_cp_tab(l_cp_idx)
              ,on_stock_quantity   => l_xwsp_rec.before_stock
              ,od_manufacture_date => l_xwsp_rec.manufacture_date
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --�N�x�����������ړ���q�ɂ��擾
            SELECT xwsp.transaction_id                                                 transaction_id
                  ,xwsp.shipping_date                                                  shipping_date
                  ,xwsp.receipt_date                                                   receipt_date
                  ,xwsp.ship_org_code                                                  ship_org_code
                  ,xwsp.ship_org_name                                                  ship_org_name
                  ,xwsp.receipt_org_code                                               receipt_org_code
                  ,xwsp.receipt_org_name                                               receipt_org_name
                  ,xwsp.item_id                                                        item_id
                  ,xwsp.item_no                                                        item_no
                  ,xwsp.item_name                                                      item_name
                  ,xwsp.freshness_priority                                             freshness_priority
                  ,xwsp.freshness_condition                                            freshness_condition
                  ,NULL                                                                manu_date
                  ,NULL                                                                lot_status
                  ,NULL                                                                plan_min_qty
                  ,NULL                                                                plan_max_qty
                  ,NULL                                                                plan_bal_qty
                  ,NULL                                                                plan_lot_qty
                  ,NULL                                                                delivery_unit
                  ,NULL                                                                before_stock
                  ,NULL                                                                after_stock
                  ,xwsp.stock_maintenance_days                                         safety_days
                  ,xwsp.max_stock_days                                                 max_days
                  ,xwsp.shipping_pace                                                  shipping_pace
                  ,NULL                                                                under_lvl_pace
                  ,DECODE(xwsp.assignment_set_type, cv_custom_plan, cv_csv_mark, NULL) special_yoko_type
                  ,NULL                                                                supp_bad_type
                  ,NULL                                                                lot_revers_type
                  ,NULL                                                                earliest_manu_date
                  ,xwsp.manufacture_date                                               start_manu_date
                  ,xwsp.num_of_case                                                    num_of_case
                  ,xwsp.palette_max_cs_qty                                             palette_max_cs_qty
                  ,xwsp.palette_max_step_qty                                           palette_max_step_qty
            BULK COLLECT INTO l_xwypo_tab
            FROM xxcop_wk_ship_planning xwsp
            WHERE xwsp.transaction_id      = cn_request_id
              AND xwsp.item_no             = l_xwsp_rec.item_no
              AND xwsp.ship_org_code       = l_xwsp_rec.ship_org_code
              AND xwsp.freshness_condition = l_cp_tab(l_cp_idx).freshness_condition
            ORDER BY xwsp.assignment_set_type DESC
                    ,xwsp.receipt_org_code    ASC;
            <<xwypo_loop>>
            FOR ln_xwypo_idx IN l_xwypo_tab.FIRST .. l_xwypo_tab.LAST LOOP
              --�f�o�b�N���b�Z�[�W�o��
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'xwypo_loop'                               || ','
                                || l_xwypo_tab(ln_xwypo_idx).receipt_org_code
              );
              --�ړ���q�ɂ̑N�x�����𖞂����݌ɐ��̎擾
              get_stock_quantity(
                 in_item_id          => l_xwypo_tab(ln_xwypo_idx).item_id
                ,iv_whse_code        => l_xwypo_tab(ln_xwypo_idx).receipt_org_code
                ,id_plan_date        => l_xwypo_tab(ln_xwypo_idx).receipt_date
                ,in_stock_days       => l_xwypo_tab(ln_xwypo_idx).max_days
                ,i_cp_rec            => l_cp_tab(l_cp_idx)
                ,on_stock_quantity   => l_xwypo_tab(ln_xwypo_idx).before_stock
                ,od_manufacture_date => l_xwypo_tab(ln_xwypo_idx).earliest_manu_date
                ,ov_errbuf           => lv_errbuf
                ,ov_retcode          => lv_retcode
                ,ov_errmsg           => lv_errmsg
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                IF ( lv_errbuf IS NULL ) THEN
                  RAISE internal_api_expt;
                ELSE
                  RAISE global_api_expt;
                END IF;
              END IF;
              lv_receipt_org_code := l_xwypo_tab(ln_xwypo_idx).receipt_org_code;
              --���o�׃y�[�X�̎擾
              SELECT NVL(SUM(xwspv.shipping_pace), 0)
              INTO   l_xwypo_tab(ln_xwypo_idx).under_lvl_pace
              FROM (
                SELECT xwsp.ship_org_code
                      ,xwsp.receipt_org_code
                      ,xwsp.item_id
                      ,xwsp.shipping_pace
                FROM xxcop_wk_ship_planning xwsp
                WHERE xwsp.transaction_id   = cn_request_id
                  AND xwsp.item_id          = l_xwypo_tab(ln_xwypo_idx).item_id
                  AND xwsp.plant_org_id    IS NULL
                GROUP BY xwsp.ship_org_code
                      ,xwsp.receipt_org_code
                      ,xwsp.item_id
                      ,xwsp.shipping_pace
              ) xwspv
              START WITH       xwspv.ship_org_code    = lv_receipt_org_code
              CONNECT BY PRIOR xwspv.receipt_org_code = xwspv.ship_org_code;
              --�f�o�b�N���b�Z�[�W�o��
              xxcop_common_pkg.put_debug_message(
                 iov_debug_mode => gv_debug_mode
                ,iv_value       => 'ship_pace'                             || ','
                               || l_xwypo_tab(ln_xwypo_idx).under_lvl_pace || ','
                               || l_xwypo_tab(ln_xwypo_idx).shipping_pace
              );
              l_xwypo_tab(ln_xwypo_idx).under_lvl_pace := l_xwypo_tab(ln_xwypo_idx).under_lvl_pace
                                                        + l_xwypo_tab(ln_xwypo_idx).shipping_pace;
            END LOOP xwypo_loop;
            --�v�搔(�o�����X)�̎Z�o
            proc_balance_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --�v�搔(�ŏ�)�̎Z�o
            proc_minimum_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --�v�搔(�ő�)�̎Z�o
            proc_maximum_plan_qty(
               i_xwsp_rec          => l_xwsp_rec
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
            --�v�惍�b�g�̌���
            fix_plan_lots(
               i_xwsp_rec          => l_xwsp_rec
              ,i_cp_rec            => l_cp_tab(l_cp_idx)
              ,io_xwypo_tab        => l_xwypo_tab
              ,ov_errbuf           => lv_errbuf
              ,ov_retcode          => lv_retcode
              ,ov_errmsg           => lv_errmsg
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_errbuf IS NULL ) THEN
                RAISE internal_api_expt;
              ELSE
                RAISE global_api_expt;
              END IF;
            END IF;
          END LOOP priority_loop;
        END LOOP xwsp_so_loop;
      EXCEPTION
        WHEN nested_loop_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00060
                         ,iv_token_name1  => cv_msg_00060_token_1
                         ,iv_token_value1 => lv_receipt_org_code
                       );
          RAISE internal_api_expt;
        WHEN zero_divide_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_appl_cont
                         ,iv_name         => cv_msg_00058
                         ,iv_token_name1  => cv_msg_00058_token_1
                         ,iv_token_value1 => cv_msg_00058_value_1
                         ,iv_token_name2  => cv_msg_00058_token_2
                         ,iv_token_value2 => cv_msg_00058_value_2
                       );
          RAISE internal_api_expt;
      END;
    END LOOP xwsp_ro_loop;
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
  END get_xwsp;
--
  /**********************************************************************************
   * Procedure Name   : output_xwypo
   * Description      : �����v��CSV�o��(A-4)
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
    lv_csvbuff                VARCHAR2(5000);             -- �����v��o�͗̈�
    lv_ship_loct_code         ic_loct_mst.location%TYPE;  -- �ړ����ۊǑq��
    lv_ship_loct_desc         ic_loct_mst.loct_desc%TYPE; -- �ړ����ۊǑq�ɖ���
    lv_receipt_loct_code      ic_loct_mst.location%TYPE;  -- �ړ���ۊǑq��
    lv_receipt_loct_desc      ic_loct_mst.loct_desc%TYPE; -- �ړ���ۊǑq�ɖ���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_xwypo_csv_tab           g_xwypo_csv_ttype;
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
    --�����v��o�̓��[�N�e�[�u���擾
    SELECT xwypo.shipping_date
          ,xwypo.receipt_date
          ,xwypo.ship_org_code
          ,xwypo.ship_org_name
          ,xwypo.receipt_org_code
          ,xwypo.receipt_org_name
          ,xwypo.item_no
          ,xwypo.item_name
          ,xwypo.manu_date
          ,xwypo.lot_status
          ,xwypo.plan_min_qty
          ,xwypo.plan_max_qty
          ,xwypo.plan_bal_qty
          ,xwypo.delivery_unit
          ,xwypo.before_stock
          ,xwypo.after_stock
          ,( xwypo.safety_days * xwypo.shipping_pace ) safety_stock
          ,( xwypo.max_days    * xwypo.shipping_pace ) max_stock
          ,xwypo.shipping_pace
          ,xwypo.special_yoko_type
          ,xwypo.supp_bad_type
          ,xwypo.lot_revers_type
          ,flv1.description                            freshness_condition
          ,flv2.meaning                                quality_type
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
          ,NVL(TO_NUMBER(iimb.attribute11), 1)         num_of_case
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    BULK COLLECT INTO l_xwypo_csv_tab
    FROM xxcop_wk_yoko_plan_output xwypo
        ,fnd_lookup_values         flv1
        ,fnd_lookup_values         flv2
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
        ,ic_item_mst_b             iimb
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    WHERE xwypo.transaction_id = cn_request_id
      AND flv1.lookup_type     = cv_flv_freshness_cond
      AND flv1.lookup_code     = xwypo.freshness_condition
      AND flv1.language        = cv_lang
      AND flv1.source_lang     = cv_lang
      AND flv1.enabled_flag    = cv_enable
      AND cd_sysdate BETWEEN NVL(flv1.start_date_active, cd_sysdate)
                         AND NVL(flv1.end_date_active, cd_sysdate)
      AND flv2.lookup_type(+)  = cv_flv_lot_status
      AND flv2.lookup_code(+)  = xwypo.lot_status
      AND flv2.language(+)     = cv_lang
      AND flv2.source_lang(+)  = cv_lang
      AND flv2.enabled_flag(+) = cv_enable
      AND cd_sysdate BETWEEN NVL(flv2.start_date_active(+), cd_sysdate)
                         AND NVL(flv2.end_date_active(+), cd_sysdate)
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
      AND xwypo.item_id        = iimb.item_id
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
    ORDER BY xwypo.shipping_date      ASC
            ,xwypo.ship_org_code      ASC
            ,xwypo.receipt_org_code   ASC
            ,xwypo.item_no            ASC
            ,xwypo.freshness_priority ASC
            ,xwypo.before_stock       ASC
            ,xwypo.manu_date          ASC
            ,xwypo.lot_status         ASC;
--
    --�Ώی������Z�b�g
    gn_target_cnt := l_xwypo_csv_tab.COUNT;
    --CSV�t�@�C���w�b�_�o��
    lv_csvbuff := cv_csv_char_bracket || cv_put_column_01 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_02 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_03 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_04 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_05 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_06 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_07 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_08 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_09 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_10 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_11 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_12 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_13 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_14 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_15 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_16 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_17 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_18 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_19 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_20 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_21 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_22 || cv_csv_char_bracket || cv_csv_delimiter
               || cv_csv_char_bracket || cv_put_column_23 || cv_csv_char_bracket;
    --�������ʃ��|�[�g�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csvbuff
    );
    --CSV�t�@�C�����׏o��
    <<xwypo_loop>>
    FOR l_xwypo_idx IN l_xwypo_csv_tab.FIRST .. l_xwypo_csv_tab.LAST LOOP
      --������
      lv_csvbuff := NULL;
      --�ړ����ۊǑq�ɂ̎擾
      xxcop_common_pkg2.get_loct_info(
         iv_organization_code => l_xwypo_csv_tab(l_xwypo_idx).ship_org_code
        ,ov_loct_code         => lv_ship_loct_code
        ,ov_loct_name         => lv_ship_loct_desc
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
      --�ړ���ۊǑq�ɂ̎擾
      xxcop_common_pkg2.get_loct_info(
         iv_organization_code => l_xwypo_csv_tab(l_xwypo_idx).receipt_org_code
        ,ov_loct_code         => lv_receipt_loct_code
        ,ov_loct_name         => lv_receipt_loct_desc
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
      --���ڂ̕ҏW
      lv_csvbuff := cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).shipping_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).receipt_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_ship_loct_code
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_ship_loct_desc
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_receipt_loct_code
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || lv_receipt_loct_desc
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).item_no
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).item_name
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).freshness_condition
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).manu_date, cv_csv_date_format)
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).quality_type
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_min_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_min_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_max_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_max_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).plan_bal_qty)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).plan_bal_qty
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).delivery_unit
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).before_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).before_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).after_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).after_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).safety_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).safety_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).max_stock)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).max_stock
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_START
--                 || cv_csv_char_bracket || TO_CHAR(l_xwypo_csv_tab(l_xwypo_idx).shipping_pace)
                 || cv_csv_char_bracket || TO_CHAR(TRUNC(l_xwypo_csv_tab(l_xwypo_idx).shipping_pace
                                                       / l_xwypo_csv_tab(l_xwypo_idx).num_of_case))
--20090407_Ver1.1_T1_0289_SCS.Goto_ADD_END
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).special_yoko_type
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).supp_bad_type
                 || cv_csv_char_bracket || cv_csv_delimiter
                 || cv_csv_char_bracket || l_xwypo_csv_tab(l_xwypo_idx).lot_revers_type
                 || cv_csv_char_bracket;
      --�������ʃ��|�[�g�ɏo��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csvbuff
      );
      gn_normal_cnt := gn_normal_cnt + 1;
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
  END output_xwypo;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_plan_type     IN     VARCHAR2,       -- 1.�v��敪
    iv_shipment_from IN     VARCHAR2,       -- 2.�o�׃y�[�X�v�����(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.�o�׃y�[�X�v�����(TO)
    iv_forcast_type  IN     VARCHAR2,       -- 4.�o�ח\���敪
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    BEGIN
      -- ===============================
      -- A-1�D��������
      -- ===============================
      init(
         iv_plan_type                   -- �v��敪
        ,iv_shipment_from               -- �o�׃y�[�X�v�����(FROM)
        ,iv_shipment_to                 -- �o�׃y�[�X�v�����(TO)
        ,iv_forcast_type                -- �o�ח\���敪
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-2�D�����v�搧��}�X�^�擾
      -- ===============================
      get_msr_route(
         lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-3�D�����v�惏�[�N�e�[�u���擾
      -- ===============================
      get_xwsp(
         lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-4�D�����v��CSV�o��
      -- ===============================
      output_xwypo(
         lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    EXCEPTION
      WHEN global_process_expt THEN
        --�Ώی����A�G���[�����̃J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        gn_error_cnt  := gn_error_cnt + 1;
    END;
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      --�I���X�e�[�^�X���G���[�̏ꍇ�A���[�N�e�[�u�����c�����߃R�~�b�g����B
      COMMIT;
      IF ( lv_errbuf IS NOT NULL ) THEN
        RAISE global_process_expt;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
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
    errbuf           OUT    VARCHAR2,       --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT    VARCHAR2,       --   �G���[�R�[�h     #�Œ�#
    iv_plan_type     IN     VARCHAR2,       -- 1.�v��敪
    iv_shipment_from IN     VARCHAR2,       -- 2.�o�׃y�[�X�v�����(FROM)
    iv_shipment_to   IN     VARCHAR2,       -- 3.�o�׃y�[�X�v�����(TO)
    iv_forcast_type  IN     VARCHAR2        -- 4.�o�ח\���敪
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_plan_type                     -- �v��敪
      ,iv_shipment_from                 -- �o�׃y�[�X�v�����(FROM)
      ,iv_shipment_to                   -- �o�׃y�[�X�v�����(TO)
      ,iv_forcast_type                  -- �o�ח\���敪
      ,lv_errbuf                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
--      --�G���[�o��
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
--
--      fnd_file.put_line(
--         which  => FND_FILE.LOG
--        ,buff => lv_errbuf --�G���[���b�Z�[�W
--      );
      --�G���[�o��(CSV�o�͂̂��߃��O�ɏo��)
      IF ( lv_errmsg IS NOT NULL ) THEN
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF ( lv_errbuf IS NOT NULL ) THEN
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
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
END XXCOP006A01C;
/
