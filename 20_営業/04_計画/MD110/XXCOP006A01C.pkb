CREATE OR REPLACE PACKAGE BODY XXCOP006A01C
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
 *  init                   ��������                                             (A-1)
 *  delete_table           �e�[�u���f�[�^�폜����                               (A-2)
 *  request_conc           �q�R���J�����g���s����                               (A-3)
 *  output_xwypo           �����v��CSV�o��                                      (A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/11/13    1.0   M.Hokkanji       �V�K�쐬
 *  2010/01/07    1.1   Y.Goto           E_�{�ғ�_00936
 *  2010/02/03    1.2   Y.Goto           E_�{�ғ�_01222
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
  nested_loop_expt          EXCEPTION;     -- �K�w���[�v�G���[
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
  internal_api_expt         EXCEPTION;     -- �R���J�����g�������ʗ�O
  param_invalid_expt        EXCEPTION;     -- ���̓p�����[�^�`�F�b�N�G���[
  date_invalid_expt         EXCEPTION;     -- ���t�`�F�b�N�G���[
  prior_date_invalid_expt   EXCEPTION;     -- �������`�F�b�N�G���[
  past_date_invalid_expt    EXCEPTION;     -- �ߋ����`�F�b�N�G���[
  date_reverse_expt         EXCEPTION;     -- FROM-TO�t�]�`�F�b�N�G���[
  profile_invalid_expt      EXCEPTION;     -- �v���t�@�C���l�G���[

  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  PRAGMA EXCEPTION_INIT(nested_loop_expt, -01436);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP006A01C';           -- �p�b�P�[�W��
  cv_pkg_name_child         CONSTANT VARCHAR2(100) := 'XXCOP006A011C';           -- �p�b�P�[�W���i�q�R���J�����g���j
  --���b�Z�[�W����
  cv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- �A�v���P�[�V�����Z�k��
  --����
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');          -- ����
  --�v���O�������s�N����
  cd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- �V�X�e�����t�i�N�����j
  --���t�^�t�H�[�}�b�g
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- �N����
  --�^�C���X�^���v�^�t�H�[�}�b�g
  cv_timestamp_format       CONSTANT VARCHAR2(100) := 'HH24:MI:SS.FF3';         -- �N���������b
  --�f�o�b�N���b�Z�[�W�C���f���g
  cv_indent_2               CONSTANT CHAR(2) := '  ';                           -- 2������
  cv_indent_4               CONSTANT CHAR(4) := '    ';                         -- 4������
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_working_days_tl        CONSTANT VARCHAR2(100) := '�ғ�����';
  cv_stock_adjust_value_tl  CONSTANT VARCHAR2(100) := '�݌ɓ��������l';
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
  --�v���t�@�C��
  cv_pf_master_org_id       CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
  cv_pf_source_org_id       CONSTANT VARCHAR2(100) := 'XXCOP1_DUMMY_SOURCE_ORG_ID';
  cv_pf_fresh_buffer_days   CONSTANT VARCHAR2(100) := 'XXCOP1_FRESHNESS_BUFFER_DAYS';
  cv_pf_frq_loct_code       CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
  cv_pf_partition_num       CONSTANT VARCHAR2(100) := 'XXCOP1_PARTITION_NUM';
  cv_pf_debug_mode          CONSTANT VARCHAR2(100) := 'XXCOP1_DEBUG_MODE';
  cv_pf_interval            CONSTANT VARCHAR2(100) := 'XXCOP1_CONCURRENT_INTERVAL';
  cv_pf_max_wait            CONSTANT VARCHAR2(100) := 'XXCOP1_CONCURRENT_MAX_WAIT';
  
  --���b�Z�[�W�g�[�N���l
  cv_table_xwypo            CONSTANT VARCHAR2(100) := '�����v��o�̓��[�N�e�[�u��';
  cv_table_xwyp             CONSTANT VARCHAR2(100) := '�����v�敨�����[�N�e�[�u��';
  cv_table_xli              CONSTANT VARCHAR2(100) := '�����v��莝�݌Ƀe�[�u��';
  cv_table_xwyl             CONSTANT VARCHAR2(100) := '�����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u��';
--
  -- ���b�Z�[�W��
  cv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';
  cv_msg_00007              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';
  cv_msg_00011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00011';
  cv_msg_00025              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_msg_00041              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';
  cv_msg_00047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_msg_00055              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00055';
  cv_msg_00065              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00065';
  cv_msg_10009              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_msg_10045              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10045';
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_msg_10057              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10057';
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
  cv_msg_10046              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10046';
  cv_msg_10047              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10047';
  cv_msg_10050              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10050';
  cv_msg_10051              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10051';
  cv_msg_10052              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10052';
  cv_msg_10053              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10053';
  cv_msg_10054              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10054';
  -- ���b�Z�[�W�g�[�N��
  cv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_msg_00007_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00011_token_1      CONSTANT VARCHAR2(100) := 'ITEM';
  cv_msg_00025_token_1      CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_msg_00025_token_2      CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_msg_00041_token_1      CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  cv_msg_00047_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10009_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_msg_10045_token_1      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_FROM';
  cv_msg_10045_token_2      CONSTANT VARCHAR2(100) := 'PLANNING_DATE_TO';
  cv_msg_10045_token_3      CONSTANT VARCHAR2(100) := 'PLAN_TYPE';
  cv_msg_10045_token_4      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_FROM';
  cv_msg_10045_token_5      CONSTANT VARCHAR2(100) := 'SHIPMENT_DATE_TO';
  cv_msg_10045_token_6      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_FROM';
  cv_msg_10045_token_7      CONSTANT VARCHAR2(100) := 'FORECAST_DATE_TO';
  cv_msg_10045_token_8      CONSTANT VARCHAR2(100) := 'ALLOCATED_DATE';
  cv_msg_10045_token_9      CONSTANT VARCHAR2(100) := 'ITEM_NO';
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
  cv_msg_10057_token_1      CONSTANT VARCHAR2(100) := 'WORKING_DAYS';
  cv_msg_10057_token_2      CONSTANT VARCHAR2(100) := 'STOCK_ADJUST_VALUE';
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
  cv_msg_10046_token_1      CONSTANT VARCHAR2(100) := 'GATEGORY_NAME';
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
  cv_msg_10052_token_1      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10053_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  cv_msg_10053_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  cv_msg_10054_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  cv_msg_10054_token_2      CONSTANT VARCHAR2(100) := 'ITEM_NO';
  --�o�׌v��敪
  cv_plan_type_shipped      CONSTANT VARCHAR2(100) := '1';                      -- �o�׃y�[�X
  cv_plan_type_forecate     CONSTANT VARCHAR2(100) := '2';                      -- �o�ח\��
  --�����Z�b�g�敪
  cv_base_plan              CONSTANT VARCHAR2(1)   := '1';                      -- ��{�����v��
  cv_custom_plan            CONSTANT VARCHAR2(1)   := '2';                      -- ���ʉ����v��
  cv_factory_ship_plan      CONSTANT VARCHAR2(1)   := '3';                      -- �H��o�׌v��
  --�i�ڃJ�e�S��
  cv_category_prod_class    CONSTANT VARCHAR2(100) := '�{�Џ��i�敪';
  cv_category_article_class CONSTANT VARCHAR2(100) := '���i���i�敪';
  cv_category_item_class    CONSTANT VARCHAR2(100) := '�i�ڋ敪';
  --�i�ڃJ�e�S���l
  cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  --���[�t
  cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  --�h�����N
  cv_article_class_product  CONSTANT VARCHAR2(100) := '2';  --���i
  cv_item_class_product     CONSTANT VARCHAR2(100) := '5';  --���i
  --�N�C�b�N�R�[�h�^�C�v
  cv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';
  cv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';
  cv_flv_lot_status         CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS';
  cv_flv_freshness_cond     CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';
  cv_flv_unit_delivery      CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';
  cv_enable                 CONSTANT VARCHAR2(100) := 'Y';
  --CSV�t�@�C���o�̓t�H�[�}�b�g
  cv_csv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';               -- �N����
  cv_csv_char_bracket       CONSTANT VARCHAR2(1)   := '''';                     -- �V���O���N�H�[�e�[�V����
  cv_csv_delimiter          CONSTANT VARCHAR2(1)   := ',';                      -- �J���}
  cv_csv_mark               CONSTANT VARCHAR2(1)   := '*';                      -- �A�X�^���X�N
--
  --���O�o�̓��x��
  cv_log_level1             CONSTANT VARCHAR2(1)   := '1';                      -- 
  cv_log_level2             CONSTANT VARCHAR2(1)   := '2';                      -- 
  cv_log_level3             CONSTANT VARCHAR2(1)   := '3';                      -- 
--
  -- �R���J�����g�p�����[�^
  cv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  cv_conc_s_n               CONSTANT VARCHAR2(100) := 'NORMAL';
  cv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
--
  -- �i�ڃX�e�[�^�X
  cv_shipping_enable        CONSTANT NUMBER := '1';                             -- �X�e�[�^�X
  cn_iimb_status_active     CONSTANT NUMBER :=  0;                              -- �X�e�[�^�X
  -- �o�͑Ώۋ敪
  cv_output_flg_enable      CONSTANT VARCHAR2(1) := '1';                        -- �Ώ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --ROWID�R���N�V�����^
  TYPE g_rowid_ttype IS TABLE OF ROWID
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_planning_date          DATE;                                               --�v�旧�ē�
  gd_process_date           DATE;                                               --�Ɩ����t
  gn_transaction_id         NUMBER;                                             --�g�����U�N�V����ID
  gv_log_buffer             VARCHAR2(5000);                                     --���O�o�͗̈�
  --�v���t�@�C���l
  gv_debug_mode             VARCHAR2(256);                                      --�f�o�b�N���[�h
  gn_master_org_id          NUMBER;                                             --�������[��(�_�~�[)�g�DID
  gn_source_org_id          NUMBER;                                             --�p�b�J�[�q��(�_�~�[)�g�DID
  gn_freshness_buffer_days  NUMBER;                                             --�N�x�����o�b�t�@����
  gv_dummy_frequent_whse    VARCHAR2(4);                                        --�_�~�[��\�q��
  gn_partition_num          NUMBER;                                             --�p�[�e�B�V������
  gn_interval               NUMBER;                                             --�R���J�����g���s���̊m�F�Ԋu
  gn_max_wait               NUMBER;                                             --�R���J�����g���s���̍ő�ҋ@����
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
  gn_working_days           NUMBER;                                             --�ғ�����
  gn_stock_adjust_value     NUMBER;                                             --�݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
  --�i�ڃJ�e�S���Z�b�gID
  gn_prod_class_set_id      NUMBER;                                             --�i�ڃJ�e�S��:�{�Џ��i�敪
  gn_crowd_class_set_id     NUMBER;                                             --����Q�R�[�h
  gn_item_class_set_id      NUMBER;                                             --�i�ڋ敪
  gn_article_class_set_id   NUMBER;                                             --���i���i�敪
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : �e�[�u���f�[�^�폜(A-2)
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
    -- ===============================
    -- �����v�敨�����[�N�e�[�u��
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwyp;
      --���b�N�̎擾
      SELECT xwyp.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_planning xwyp
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_planning';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
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
    -- �����v��莝�݌Ƀe�[�u��
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xli;
      --���b�N�̎擾
      SELECT xli.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_loct_inv xli
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_loct_inv';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
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
    -- �����v��i�ڕʑ�\�q�Ƀ��[�N�e�[�u��
    -- ===============================
    BEGIN
      lv_table_name := cv_table_xwyl;
      --���b�N�̎擾
      SELECT xwyl.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_locations xwyl
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_locations';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
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
      SELECT xwypo.ROWID
      BULK COLLECT INTO l_rowid_tab
      FROM xxcop_wk_yoko_plan_output xwypo
      FOR UPDATE NOWAIT;
      --�f�[�^�폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcop.xxcop_wk_yoko_plan_output';
--
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_00007
                       ,iv_token_name1  => cv_msg_00007_token_1
                       ,iv_token_value1 => lv_table_name
                     );
        RAISE internal_api_expt;
      WHEN NO_DATA_FOUND THEN
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
     iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
    lv_param_msg              VARCHAR2(100);   -- �p�����[�^�o��
    lb_chk_value              BOOLEAN;         -- ���t�^�t�H�[�}�b�g�`�F�b�N����
    lv_chk_parameter          VARCHAR2(100);   -- �`�F�b�N���ږ�
    lv_chk_date_from          VARCHAR2(100);   -- �͈̓`�F�b�N���ږ�(FROM)
    lv_chk_date_to            VARCHAR2(100);   -- �͈̓`�F�b�N���ږ�(TO)
    lv_value                  VARCHAR2(100);   -- �v���t�@�C���l
    lv_profile_name           VARCHAR2(100);   -- ���[�U�v���t�@�C����
    lv_category_name          VARCHAR2(100);   -- �i�ڃJ�e�S����
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
      -- ===============================
      -- �i�ڃR�[�h
      -- ===============================
      lv_chk_parameter := cv_item_code_tl;
      gv_item_code := iv_item_code;
--
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
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
        gn_stock_adjust_value := TO_NUMBER(iv_stock_adjust_value);
      EXCEPTION
        WHEN OTHERS THEN
        RAISE param_invalid_expt;
      END;
--
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
      --�C���^�[�o��
      lv_profile_name :=  cv_pf_interval;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_interval     := TO_NUMBER(lv_value);
--
      --�ő�ҋ@����
      lv_profile_name :=  cv_pf_max_wait;
      lv_value := fnd_profile.value( lv_profile_name );
      IF (lv_value IS NULL) THEN
        RAISE profile_invalid_expt;
      END IF;
      gn_max_wait     := TO_NUMBER(lv_value);
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
    -- �i�ڃJ�e�S���Z�b�g�̎擾
    -- ===============================
    BEGIN
      --�{�Џ��i�敪
      lv_category_name :=cv_category_prod_class;
      SELECT mcst.category_set_id         category_set_id
      INTO   gn_prod_class_set_id
      FROM   mtl_category_sets_tl   mcst
      WHERE  mcst.category_set_name = lv_category_name
        AND  mcst.source_lang       = cv_lang
        AND  mcst.language          = cv_lang
      ;
      --���i���i�敪
      lv_category_name :=cv_category_article_class;
      SELECT mcst.category_set_id         category_set_id
      INTO   gn_article_class_set_id
      FROM   mtl_category_sets_tl   mcst
      WHERE  mcst.category_set_name = lv_category_name
        AND  mcst.source_lang       = cv_lang
        AND  mcst.language          = cv_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_appl_cont
                       ,iv_name         => cv_msg_10046
                       ,iv_token_name1  => cv_msg_10046_token_1
                       ,iv_token_value1 => lv_category_name
                     );
        RAISE internal_api_expt;
    END;
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
  END init;
  /**********************************************************************************
   * Procedure Name   : request_conc(A-3)
   * Description      : �q�R���J�����g���s����
   ***********************************************************************************/
  PROCEDURE request_conc(
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'request_conc'; -- �v���O������
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
    lv_item_category          VARCHAR2(100);  --�i�ڃJ�e�S��
    ln_target_cnt             NUMBER;         --�����f�[�^����
    lv_phase                  VARCHAR2(100);
    lv_status                 VARCHAR2(100);
    lv_dev_phase              VARCHAR2(100);
    lv_dev_status             VARCHAR2(100);
    -- �q�R���J�����g�Ώۃf�[�^���i�[���郌�R�[�h
    TYPE item_type IS RECORD(
       item_id            ic_item_mst_b.item_id%TYPE                    -- �݌ɕi��ID
     , item_no            ic_item_mst_b.item_no%TYPE                    -- �i�ڃR�[�h
    );
    TYPE item_tbl IS TABLE OF item_type INDEX BY PLS_INTEGER;
    item_rec  item_tbl;
--
    TYPE req_type IS RECORD(
       request_id         NUMBER
     , item_no            ic_item_mst_b.item_no%TYPE                    -- �i�ڃR�[�h
    );
    TYPE req_tbl IS TABLE OF req_type INDEX BY PLS_INTEGER;
    req_rec  req_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �i�ڂ��w�肳��Ă��Ȃ��ꍇ
    IF (gv_item_code IS NULL) THEN
      -- �ΏۂƂȂ�i�ڂ��ꊇ�擾
      SELECT  iimb.item_id
             ,iimb.item_no BULK COLLECT
        INTO  item_rec
        FROM  mrp_assignment_sets       mas    --�����Z�b�g
             ,mrp_sr_assignments        msa    --�����Z�b�g����
             ,fnd_lookup_values         flv1   --�Q�ƃ^�C�v(�����Z�b�g��)
             ,mtl_system_items_b        msib   --Disc�i�ڃ}�X�^
             ,ic_item_mst_b             iimb   --OPM�i�ڃ}�X�^
             ,gmi_item_categories       gic_p  --OPM�i�ڃJ�e�S��(�{�Џ��i�敪)
             ,mtl_categories_b          mcb_p  --�i�ڃJ�e�S���}�X�^(�{�Џ��i�敪)
             ,gmi_item_categories       gic_a  --OPM�i�ڃJ�e�S��(���i���i�敪)
             ,mtl_categories_b          mcb_a  --�i�ڃJ�e�S���}�X�^(���i���i�敪)
       WHERE  mas.attribute1            = cv_base_plan
         AND  msa.assignment_set_id     = mas.assignment_set_id
         AND  flv1.lookup_type          = cv_flv_assignment_name
         AND  flv1.lookup_code          = mas.assignment_set_name
         AND  flv1.language             = cv_lang
         AND  flv1.source_lang          = cv_lang
         AND  flv1.enabled_flag         = cv_enable
         AND  gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
         AND  msib.inventory_item_id    = msa.inventory_item_id
         AND  msib.organization_id      = gn_master_org_id
         AND  iimb.item_no              = msib.segment1
         AND  iimb.inactive_ind         = cn_iimb_status_active
         AND  iimb.attribute18          = cv_shipping_enable
         AND  iimb.item_id              = gic_p.item_id
         AND  gic_p.category_id         = mcb_p.category_id
         AND  gic_p.category_set_id     = gn_prod_class_set_id
         AND  mcb_p.segment1            = cv_prod_class_drink
         AND  iimb.item_id              = gic_a.item_id
         AND  gic_a.category_id         = mcb_a.category_id
         AND  gic_a.category_set_id     = gn_article_class_set_id
         AND  mcb_a.segment1            = cv_article_class_product
       GROUP BY iimb.item_id,
                iimb.item_no;
    ELSE
      SELECT  iimb.item_id
             ,iimb.item_no BULK COLLECT
        INTO  item_rec
        FROM  mrp_assignment_sets       mas    --�����Z�b�g
             ,mrp_sr_assignments        msa    --�����Z�b�g����
             ,fnd_lookup_values         flv1   --�Q�ƃ^�C�v(�����Z�b�g��)
             ,mtl_system_items_b        msib   --Disc�i�ڃ}�X�^
             ,ic_item_mst_b             iimb   --OPM�i�ڃ}�X�^
             ,gmi_item_categories       gic_p  --OPM�i�ڃJ�e�S��(�{�Џ��i�敪)
             ,mtl_categories_b          mcb_p  --�i�ڃJ�e�S���}�X�^(�{�Џ��i�敪)
             ,gmi_item_categories       gic_a  --OPM�i�ڃJ�e�S��(���i���i�敪)
             ,mtl_categories_b          mcb_a  --�i�ڃJ�e�S���}�X�^(���i���i�敪)
       WHERE  mas.attribute1            = cv_base_plan
         AND  msa.assignment_set_id     = mas.assignment_set_id
         AND  flv1.lookup_type          = cv_flv_assignment_name
         AND  flv1.lookup_code          = mas.assignment_set_name
         AND  flv1.language             = cv_lang
         AND  flv1.source_lang          = cv_lang
         AND  flv1.enabled_flag         = cv_enable
         AND  gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                  AND NVL(flv1.end_date_active  , gd_process_date)
         AND  msib.inventory_item_id    = msa.inventory_item_id
         AND  msib.organization_id      = gn_master_org_id
         AND  msib.segment1             = gv_item_code
         AND  iimb.item_no              = msib.segment1
         AND  iimb.inactive_ind         = cn_iimb_status_active
         AND  iimb.attribute18          = cv_shipping_enable
         AND  iimb.item_id              = gic_p.item_id
         AND  gic_p.category_id         = mcb_p.category_id
         AND  gic_p.category_set_id     = gn_prod_class_set_id
         AND  mcb_p.segment1            = cv_prod_class_drink
         AND  iimb.item_id              = gic_a.item_id
         AND  gic_a.category_id         = mcb_a.category_id
         AND  gic_a.category_set_id     = gn_article_class_set_id
         AND  mcb_a.segment1            = cv_article_class_product
       GROUP BY iimb.item_id,
                iimb.item_no;
    END IF;
--
    -- �����O�ɏ�����
    gn_target_cnt := item_rec.COUNT; -- �Ώی���
    ln_target_cnt := 0;
--
    -- �i�ڌ��������[�v
    <<item_rec_loop>>
    FOR i IN 1 .. item_rec.COUNT LOOP
      --�i�ڋ敪�`�F�b�N
      lv_item_category := NULL;
      lv_item_category := xxcop_common_pkg2.get_item_category_f(
                            iv_category_set => cv_category_item_class
                           ,in_item_id      => item_rec(i).item_id
                          );
      --�i�ڋ敪�����i��������NULL�̏ꍇ�Ɏq�R���J�����g�𔭍s
      IF (lv_item_category IS NULL OR
          lv_item_category = cv_item_class_product) THEN
        ln_target_cnt := ln_target_cnt + 1;
        req_rec(ln_target_cnt).request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               application       => cv_msg_appl_cont                                --�A�v���P�[�V�����Z�k��
                                             , program           => cv_pkg_name_child                               --�v���O������
                                             , argument1         => TO_CHAR(gd_planning_date_from,'YYYY/MM/DD')     --�v�旧�Ċ���(FROM)
                                             , argument2         => TO_CHAR(gd_planning_date_to,'YYYY/MM/DD')       --�v�旧�Ċ���(TO)
                                             , argument3         => gv_plan_type                                    --�o�׌v��敪
                                             , argument4         => TO_CHAR(gd_shipment_date_from,'YYYY/MM/DD')     --�o�׃y�[�X�v�����FROM
                                             , argument5         => TO_CHAR(gd_shipment_date_to,'YYYY/MM/DD')       --�o�׃y�[�X�v�����TO
                                             , argument6         => TO_CHAR(gd_forecast_date_from,'YYYY/MM/DD')     --�o�ח\������FROM
                                             , argument7         => TO_CHAR(gd_forecast_date_to,'YYYY/MM/DD')       --�o�ח\������TO
                                             , argument8         => TO_CHAR(gd_allocated_date,'YYYY/MM/DD')         --�o�׈����ϓ�
                                             , argument9         => item_rec(i).item_no                             --�i�ڃR�[�h
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
                                             , argument10        => TO_CHAR(gn_working_days)                        --�ғ�����
                                             , argument11        => TO_CHAR(gn_stock_adjust_value)                  --�݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
                                             );
        -- �G���[�̏ꍇ
        IF ( req_rec(ln_target_cnt).request_id = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_appl_cont
                        ,iv_name         => cv_msg_10052
                        ,iv_token_name1  => cv_msg_10052_token_1
                        ,iv_token_value1 => item_rec(i).item_no
                       );
          RAISE internal_api_expt;
        ELSE
          req_rec(ln_target_cnt).item_no := item_rec(i).item_no;
          --�R�~�b�g���Ȃ��Ɣ��s����Ȃ����ߔ��s���ƂɃR�~�b�g
          COMMIT;
        END IF;
      ELSE
        -- �����ΏۊO�̂��߃X�L�b�v�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END LOOP item_rec_loop;
--
    <<chk_status>>
    FOR j IN 1 .. req_rec.COUNT LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             request_id => req_rec(j).request_id
            ,interval   => gn_interval
            ,max_wait   => gn_max_wait
            ,phase      => lv_phase
            ,status     => lv_status
            ,dev_phase  => lv_dev_phase
            ,dev_status => lv_dev_status
            ,message    => lv_errmsg
           ) ) THEN
        -- �X�e�[�^�X���f
        -- �t�F�[�Y:����
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
          -- �X�e�[�^�X:����
          IF ( lv_dev_status = cv_conc_s_n ) THEN
            gn_normal_cnt := gn_normal_cnt + 1;
          -- �X�e�[�^�X:����ȊO(�G���[�A�x��)
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_appl_cont
                          ,iv_name         => cv_msg_10054
                          ,iv_token_name1  => cv_msg_10054_token_1
                          ,iv_token_value1 => TO_CHAR(req_rec(j).request_id)
                          ,iv_token_name2  => cv_msg_10054_token_2
                          ,iv_token_value2 => req_rec(j).item_no
                         );
            fnd_file.put_line(
              which  => FND_FILE.LOG
             ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            gn_error_cnt := gn_error_cnt + 1;
          END IF;
        END IF;
      ELSE
        -- �R���J�����g�⍇��������ɂł��Ȃ������ꍇ�i�G���[�����j
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_appl_cont
                      ,iv_name         => cv_msg_10053
                      ,iv_token_name1  => cv_msg_10053_token_1
                      ,iv_token_value1 => TO_CHAR(req_rec(j).request_id)
                      ,iv_token_name2  => cv_msg_10053_token_2
                      ,iv_token_value2 => req_rec(j).item_no
                     );
        RAISE internal_api_expt;
      END IF;
    END LOOP chk_status;
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
  END request_conc;
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xwypo_cur IS
      SELECT xwypo.shipping_date                              shipping_date
            ,xwypo.receipt_date                               receipt_date
            ,xwypo.ship_loct_code                             ship_loct_code
            ,xwypo.ship_loct_name                             ship_loct_name
            ,xwypo.rcpt_loct_code                             rcpt_loct_code
            ,xwypo.rcpt_loct_name                             rcpt_loct_name
            ,xwypo.item_no                                    item_no
            ,xwypo.item_name                                  item_name
            ,flv1.description                                 freshness_cond_desc
            ,xwypo.manufacture_date                           manufacture_date
            ,flv2.meaning                                     lot_meaning
            ,xwypo.plan_min_quantity                          plan_min_quantity
            ,xwypo.plan_max_quantity                          plan_max_quantity
            ,xwypo.plan_lot_quantity                          plan_lot_quantity
            ,xwypo.delivery_unit                              delivery_unit
            ,xwypo.palette_max_cs_qty                         palette_max_cs_qty
            ,xwypo.palette_max_step_qty                       palette_max_step_qty
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_START
            ,xwypo.crowd_class_code                           crowd_class_code
            ,xwypo.expiration_day                             expiration_day
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_END
            ,xwypo.before_lot_stock                           before_lot_stock
            ,xwypo.after_lot_stock                            after_lot_stock
            ,xwypo.safety_stock_quantity                      safety_stock_quantity
            ,xwypo.max_stock_quantity                         max_stock_quantity
            ,xwypo.shipping_pace                              shipping_pace
            ,xwypo.special_yoko_flag                          special_yoko_flag
            ,xwypo.short_supply_flag                          short_supply_flag
            ,xwypo.lot_reverse_flag                           lot_reverse_flag
            ,xwypo.output_num                                 output_num
      FROM xxcop_wk_yoko_plan_output xwypo
          ,fnd_lookup_values         flv1
          ,fnd_lookup_values         flv2
      WHERE xwypo.output_flag    = cv_output_flg_enable
        AND flv1.lookup_type     = cv_flv_freshness_cond
        AND flv1.lookup_code     = xwypo.freshness_condition
        AND flv1.language        = cv_lang
        AND flv1.source_lang     = cv_lang
        AND flv1.enabled_flag    = cv_enable
        AND gd_process_date BETWEEN NVL(flv1.start_date_active, gd_process_date)
                                AND NVL(flv1.end_date_active, gd_process_date)
        AND flv2.lookup_type(+)  = cv_flv_lot_status
        AND flv2.lookup_code(+)  = xwypo.lot_status
        AND flv2.language(+)     = cv_lang
        AND flv2.source_lang(+)  = cv_lang
        AND flv2.enabled_flag(+) = cv_enable
        AND gd_process_date BETWEEN NVL(flv2.start_date_active(+), gd_process_date)
                                AND NVL(flv2.end_date_active(+), gd_process_date)
      ORDER BY xwypo.shipping_date        ASC
              ,xwypo.receipt_date         ASC
              ,xwypo.ship_loct_code       ASC
              ,xwypo.rcpt_loct_code       ASC
              ,xwypo.item_no              ASC
              ,xwypo.freshness_condition  DESC
              ,xwypo.manufacture_date     ASC
              ,xwypo.output_num           ASC
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
    --CSV�t�@�C���w�b�_�o��
    lv_csvbuff := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_appl_cont
                    ,iv_name         => cv_msg_10047
                  );
    --�������ʃ��|�[�g�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csvbuff
    );
    --CSV�t�@�C�����׏o��
    <<xwypo_loop>>
    FOR l_xwypo_rec IN xwypo_cur LOOP
      --������
      lv_csvbuff := NULL;
      --���ڂ̕ҏW
      --�o�ד�
      lv_csvbuff := TO_CHAR(l_xwypo_rec.shipping_date, cv_csv_date_format)
                 || cv_csv_delimiter
      ;
      --����
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.receipt_date , cv_csv_date_format)
                 || cv_csv_delimiter
      ;
      --�ړ����q�ɃR�[�h
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.ship_loct_code
                 || cv_csv_delimiter
      ;
      --�ړ����q�ɖ�
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.ship_loct_name
                 || cv_csv_delimiter
      ;
      --�ړ���q�ɃR�[�h
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.rcpt_loct_code
                 || cv_csv_delimiter
      ;
      --�ړ���q�ɖ�
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.rcpt_loct_name
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_START
      --�Q�R�[�h
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.crowd_class_code
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_END
      --�i�ڃR�[�h
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.item_no
                 || cv_csv_delimiter
      ;
      --�i�ږ�
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.item_name
                 || cv_csv_delimiter
      ;
      --�N�x����
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.freshness_cond_desc
                 || cv_csv_delimiter
      ;
      --�����N����
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.manufacture_date, cv_csv_date_format)
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_START
      --�ܖ�����
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.expiration_day)
                 || cv_csv_delimiter
      ;
--20100107_Ver1.1_E_�{�ғ�_00936_SCS.Goto_ADD_END
      --�i��
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.lot_meaning
                 || cv_csv_delimiter
      ;
      --�v�搔(�ŏ�)
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.plan_min_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�v�搔(�ő�)
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.plan_max_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�v�搔(�o�����X)
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.plan_lot_quantity)
                 || cv_csv_delimiter
      ;
      --�z���P��
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || l_xwypo_rec.delivery_unit
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�z��
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.palette_max_cs_qty)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�i��
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.palette_max_step_qty)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�����O�݌�
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.before_lot_stock)
                 || cv_csv_delimiter
      ;
      --������݌�
      lv_csvbuff := lv_csvbuff
                 || TO_CHAR(l_xwypo_rec.after_lot_stock)
                 || cv_csv_delimiter
      ;
      --���S�݌ɐ�
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.safety_stock_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�ő�݌ɐ�
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.max_stock_quantity)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --�o�׃y�[�X
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || TO_CHAR(l_xwypo_rec.shipping_pace)
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --���ʉ���
      IF (l_xwypo_rec.output_num = 1) THEN
        lv_csvbuff := lv_csvbuff
                   || l_xwypo_rec.special_yoko_flag
                   || cv_csv_delimiter
        ;
      ELSE
        lv_csvbuff := lv_csvbuff
                   || cv_csv_delimiter
        ;
      END IF;
      --��[�s��
      lv_csvbuff := lv_csvbuff
                  || l_xwypo_rec.short_supply_flag
                  || cv_csv_delimiter
      ;
      --���b�g�t�]
      lv_csvbuff := lv_csvbuff
                 || l_xwypo_rec.lot_reverse_flag
      ;
      --�������ʃ��|�[�g�ɏo��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csvbuff
      );
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
     iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
    -- ===============================
    -- A-1�D��������
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
       ,iv_working_days       => iv_working_days             -- �ғ�����
       ,iv_stock_adjust_value => iv_stock_adjust_value       -- �݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
       ,ov_errbuf             => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-2. �֘A�e�[�u���폜
    -- ===============================
    delete_table(
       ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-3�D�q�R���J�����g���s����
    -- ===============================
    request_conc(
        ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4. �����v��CSV�o��
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
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NOT NULL) THEN
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_START
      ,iv_working_days       => iv_working_days             -- �ғ�����
      ,iv_stock_adjust_value => iv_stock_adjust_value       -- �݌ɓ��������l
--20100203_Ver1.2_E_�{�ғ�_01222_SCS.Goto_ADD_END
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
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[�̏ꍇ�A���������̏������ƃG���[�����̃Z�b�g
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
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
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
    );
--
    -- ����I���Ŏq�R���J�����g��1���ł��G���[������ꍇ�x���I��
    IF (lv_retcode = cv_status_normal AND gn_error_cnt > 0) THEN
      lv_retcode := cv_status_warn;
    END IF;
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
    --CSV�o�͂̂��߃��O�ɏo��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg
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
