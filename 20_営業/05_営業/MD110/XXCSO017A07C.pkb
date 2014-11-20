CREATE OR REPLACE PACKAGE BODY XXCSO017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO017A07C(body)
 * Description      : ���Ϗ��A�b�v���[�h
 * MD.050           : ���Ϗ��A�b�v���[�h MD050_CSO_017_A07
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  get_upload_data           �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
 *  get_check_spec            ���̓f�[�^�`�F�b�N�d�l�擾(A-3)
 *  fnc_check_data            ���̓f�[�^�`�F�b�N����(A-3)
 *  check_input_data          ���̓f�[�^�`�F�b�N(A-3)
 *  insert_quote_upload_work  ���Ϗ��A�b�v���[�h���ԃe�[�u���o�^(A-4)
 *  get_business_check_spec   �Ɩ��`�F�b�N�d�l�擾(A-6)
 *  calc_below_cost           ��������v�Z(A-6)
 *  calc_margin               �}�[�W���v�Z(A-6)
 *  business_data_check       �Ɩ��G���[�`�F�b�N(A-6)
 *  insert_quote_header       ���σw�b�_�o�^(A-7)
 *  insert_quote_line         ���ϖ��דo�^(A-7)
 *  create_quote_data         ���σf�[�^�쐬(A-7)
 *  delete_file_ul_if         �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-8)
 *  delete_quote_upload_work  ���Ϗ��A�b�v���[�h���ԃe�[�u���f�[�^�폜(A-9)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/01/26    1.0   Y.Horikawa       �V�K�쐬
 *  2012/06/20    1.1   K.Kiriu          [T4��Q]���ϋ敪�̃`�F�b�N�C��
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  global_lock_expt                EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSO017A07C'; -- �p�b�P�[�W��
--
  cv_app_name                         CONSTANT VARCHAR2(30) := 'XXCSO';  --�A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_msg_err_get_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00554';  -- �f�[�^���o�G���[
  cv_msg_file_id                      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00271';  -- �t�@�C��ID
  cv_msg_fmt_ptn                      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[��
  cv_msg_file_ul_name                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_msg_file_name                    CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00152';  -- CSV�t�@�C����
  cv_msg_param_required               CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00325';  -- �p�����[�^�K�{�G���[
  cv_msg_err_get_proc_date            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_err_get_data_ul              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00274';  -- �t�@�C���A�b�v���[�h���̒��o�G���[
  cv_msg_err_get_lock                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00278';  -- ���b�N�G���[
  cv_msg_err_get_profile              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_msg_err_no_data                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00399';  -- �Ώی���0�����b�Z�[�W
  cv_msg_err_file_fmt                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00620';  -- ����CSV�t�H�[�}�b�g�G���[
  cv_msg_err_required                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00403';  -- �K�{���ڃG���[�i�����s�j
  cv_msg_err_invalid                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00622';  -- �^�E�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_err_below_cost               CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00626';  -- ��������`�F�b�N�G���[�i�ʏ�j
  cv_msg_err_below_cost_sp            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00627';  -- ��������`�F�b�N�G���[�i�����j
  cv_msg_err_data_div_check           CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00621';  -- �f�[�^�敪�`�F�b�N�G���[
  cv_msg_err_del_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  cv_msg_err_inc_num                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00625';  -- �����G���[
  cv_msg_err_input_check              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00623';  -- ���̓`�F�b�N�G���[
  cv_msg_err_ins_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00471';  -- �f�[�^�o�^�G���[
  cv_msg_err_margin_rate              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00633';  -- �}�[�W�����`�F�b�N�G���[
  cv_msg_err_param_valuel             CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00252';  -- �p�����[�^�Ó����`�F�b�N�G���[
  cv_msg_err_quote_enable_start       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00630';  -- ���ϊ��ԁi�J�n���j�L���`�F�b�N�G���[
  cv_msg_err_quote_enable_end         CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00631';  -- ���ϊ��ԁi�I�����j�L���`�F�b�N�G���[�i�ʏ�j
  cv_msg_err_quote_enable_end_sp      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00632';  -- ���ϊ��ԁi�I�����j�L���`�F�b�N�G���[�i�����j
  cv_msg_err_this_time_price_no       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00628';  -- ���񉿊i���͕s�G���[
  cv_msg_err_this_time_price_req      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00629';  -- ���񉿊i���͗v�G���[
  cv_msg_create_quote_sale            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00634';  -- ���ύ쐬���b�Z�[�W�i�̔���j
  cv_msg_create_quote_sale_wh         CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00635';  -- ���ύ쐬���b�Z�[�W�i�̔���{�����≮�j
  cv_msg_err_unavailable_cust_cd      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00624';  -- �ڋq�R�[�h���p�s�G���[
  cv_msg_err_invld_negative_num       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00410';  -- �}�C�i�X�`�F�b�N�G���[
  cv_msg_err_qt_ul_not_allowed        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00637';  -- ����CSV�A�b�v���[�h�s�G���[���b�Z�[�W
  cv_msg_err_too_many_data_div        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00636';  -- �f�[�^�敪������ގw��G���[���b�Z�[�W
  cv_msg_err_profile_data_type        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00121';  -- �v���t�@�C���f�[�^�^�G���[���b�Z�[�W
--
  --���b�Z�[�W�g�[�N��
  cv_tkn_param_name         CONSTANT VARCHAR2(30) := 'PARAM_NAME';
  cv_tkn_file_id            CONSTANT VARCHAR2(30) := 'FILE_ID';
  cv_tkn_table              CONSTANT VARCHAR2(30) := 'TABLE';
  cv_tkn_err_msg            CONSTANT VARCHAR2(30) := 'ERR_MSG';
  cv_tkn_index              CONSTANT VARCHAR2(30) := 'INDEX';
  cv_tkn_column             CONSTANT VARCHAR2(30) := 'COLUMN';
  cv_tkn_fmt_ptn            CONSTANT VARCHAR2(30) := 'FORMAT_PATTERN';
  cv_tkn_file_ul_name       CONSTANT VARCHAR2(30) := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name          CONSTANT VARCHAR2(30) := 'CSV_FILE_NAME';
  cv_tkn_action             CONSTANT VARCHAR2(30) := 'ACTION';
  cv_tkn_col_val1           CONSTANT VARCHAR2(30) := 'COL_VAL1';
  cv_tkn_col_val2           CONSTANT VARCHAR2(30) := 'COL_VAL2';
  cv_tkn_col_val3           CONSTANT VARCHAR2(30) := 'COL_VAL3';
  cv_tkn_col1               CONSTANT VARCHAR2(30) := 'COL1';
  cv_tkn_col2               CONSTANT VARCHAR2(30) := 'COL2';
  cv_tkn_col3               CONSTANT VARCHAR2(30) := 'COL3';
  cv_tkn_data_div_val       CONSTANT VARCHAR2(30) := 'DATA_DIV_VAL';
  cv_tkn_day                CONSTANT VARCHAR2(30) := 'DAY';
  cv_tkn_emp_num            CONSTANT VARCHAR2(30) := 'EMP_NUM';
  cv_tkn_error_message      CONSTANT VARCHAR2(30) := 'ERROR_MESSAGE';
  cv_tkn_item               CONSTANT VARCHAR2(30) := 'ITEM';
  cv_tkn_margin_rate        CONSTANT VARCHAR2(30) := 'MARGIN_RATE';
  cv_tkn_num                CONSTANT VARCHAR2(30) := 'NUM';
  cv_tkn_profile_name       CONSTANT VARCHAR2(30) := 'PROF_NAME';
  cv_tkn_profile_value      CONSTANT VARCHAR2(30) := 'PROF_VALUE';
  cv_tkn_quote_div          CONSTANT VARCHAR2(30) := 'QUOTE_DIV';
  cv_tkn_quote_num          CONSTANT VARCHAR2(30) := 'QUOTE_NUM';
  cv_tkn_quote_num1         CONSTANT VARCHAR2(30) := 'QUOTE_NUM1';
  cv_tkn_quote_num2         CONSTANT VARCHAR2(30) := 'QUOTE_NUM2';
--
  -- �g�[�N���l
  cv_tbl_nm_file_ul_if      CONSTANT VARCHAR2(50) := '�t�@�C���A�b�v���[�hIF';
  cv_tbl_nm_emp_v           CONSTANT VARCHAR2(50) := '�]�ƈ��}�X�^�i�ŐV�j�r���[';
  cv_tbl_nm_quote_ul_work   CONSTANT VARCHAR2(50) := '���Ϗ��A�b�v���[�h����';
  cv_tbl_nm_tax_rate        CONSTANT VARCHAR2(50) := '���ϗp�����ŗ��擾�r���[';
  cv_tbl_nm_quote_header    CONSTANT VARCHAR2(50) := '���σw�b�_';
  cv_tbl_nm_quote_line      CONSTANT VARCHAR2(50) := '���ϖ���';
  cv_prof_nm_period_day     CONSTANT VARCHAR2(50) := 'XXCSO:���ϊ���(�J�n��)�̗L���͈�';
  cv_prof_nm_margin_rate    CONSTANT VARCHAR2(50) := 'XXCSO:�ُ�}�[�W����';
  cv_input_param_nm_file_id CONSTANT VARCHAR2(50) := '�t�@�C��ID';
  cv_input_param_nm_fmt_ptn CONSTANT VARCHAR2(50) := '�t�H�[�}�b�g�p�^�[��';
--
  cv_profile_period_day     CONSTANT VARCHAR2(50) := 'XXCSO1_PERIOD_DAY_017_A01';  -- XXCSO:���ϊ���(�J�n��)�̗L���͈�
  cv_profile_margin_rate    CONSTANT VARCHAR2(50) := 'XXCSO1_ERR_MARGIN_RATE';     -- XXCSO:�ُ�}�[�W����
  cv_lkup_file_ul_obj       CONSTANT VARCHAR2(50) := 'XXCCP1_FILE_UPLOAD_OBJ';     -- �Q�ƃ^�C�v�F�t�@�C���A�b�v���[�hOBJ
  cv_lkup_tax_type          CONSTANT VARCHAR2(50) := 'XXCSO1_TAX_DIVISION';        -- �Q�ƃ^�C�v�F�ŋ敪�i�c�Ɓj
  cv_lkup_unit_price_div    CONSTANT VARCHAR2(50) := 'XXCSO1_UNIT_PRICE_DIVISION'; -- �Q�ƃ^�C�v�F�P���敪
  cv_lkup_quote_div         CONSTANT VARCHAR2(50) := 'XXCSO1_QUOTE_DIVISION';      -- �Q�ƃ^�C�v�F���ϋ敪
--
  cv_fmt_ptn_ul_sale_only     CONSTANT VARCHAR2(10):= '660';  -- �t�H�[�}�b�g�p�^�[���F���Ϗ��A�b�v���[�h�i�̔���p�j
  cv_data_div_sale_warehouse  CONSTANT VARCHAR2(1) := '0';  -- �f�[�^�敪�F�̔���{�����≮
  cv_data_div_sale_only       CONSTANT VARCHAR2(1) := '1';  -- �f�[�^�敪�F�̔���
--
  cv_torihiki_form_tonya      CONSTANT VARCHAR2(1) := '2';  -- ����`�ԁi�����≮�j
--
  cv_price_inc_tax            CONSTANT VARCHAR2(1) := '2';  -- �ō����i
--
  cv_cust_class_cust          CONSTANT VARCHAR2(2) := '10'; -- �ڋq�^�C�v�F�ڋq
  cv_cust_class_tonya         CONSTANT VARCHAR2(2) := '16'; -- �ڋq�^�C�v�F�����≮
--
  cv_cust_stat_mc             CONSTANT VARCHAR2(2) := '20'; -- �ڋq�X�e�[�^�X�FMC
  cv_cust_stat_sp             CONSTANT VARCHAR2(2) := '25'; -- �ڋq�X�e�[�^�X�FSP
  cv_cust_stat_approved       CONSTANT VARCHAR2(2) := '30'; -- �ڋq�X�e�[�^�X�F���F�ς�
  cv_cust_stat_cust           CONSTANT VARCHAR2(2) := '40'; -- �ڋq�X�e�[�^�X�F�ڋq
  cv_cust_stat_pause          CONSTANT VARCHAR2(2) := '50'; -- �ڋq�X�e�[�^�X�F�x�~
  cv_cust_stat_stop           CONSTANT VARCHAR2(2) := '90'; -- �ڋq�X�e�[�^�X�F���~
  cv_cust_stat_other          CONSTANT VARCHAR2(2) := '99'; -- �ڋq�X�e�[�^�X�F�ΏۊO
--
  cv_item_stat_pre_input      CONSTANT VARCHAR2(2) := '20'; -- �i�ڃX�e�[�^�X�F���o�^
  cv_item_stat_reg            CONSTANT VARCHAR2(2) := '30'; -- �i�ڃX�e�[�^�X�F�{�o�^
  cv_item_stat_no_plan        CONSTANT VARCHAR2(2) := '40'; -- �i�ڃX�e�[�^�X�F�p
  cv_item_stat_no_rma         CONSTANT VARCHAR2(2) := '50'; -- �i�ڃX�e�[�^�X�FD'
--
  cv_unit_type_case           CONSTANT VARCHAR2(8) := 'C/S';    -- �P�ʋ敪�F�P�[�X
  cv_unit_type_bowl           CONSTANT VARCHAR2(8) := '�{�[��'; -- �P�ʋ敪�F�{�[��
--
  cv_quote_div_normal         CONSTANT VARCHAR2(10) := '�ʏ�';  -- ���ϋ敪�F�ʏ�
  cv_quote_div_special_sale   CONSTANT VARCHAR2(10) := '����';  -- ���ϋ敪�F����
--
  cv_quote_type_sale          CONSTANT VARCHAR2(1) := '1';  -- ���σ^�C�v�F�̔���
  cv_quote_type_warehouse     CONSTANT VARCHAR2(1) := '2';  -- ���σ^�C�v�F�����≮
  cv_enabled                  CONSTANT VARCHAR2(1) := 'Y';            -- �L��
  cv_date_fmt                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- ���t�t�H�[�}�b�g
--
  cn_date_range_normal        CONSTANT NUMBER := 12;  -- �ʏ팩�ϗL���͈́i���j
  cn_date_range_special       CONSTANT NUMBER := 3;   -- �������ϗL���͈́i���j
  cn_after_year               CONSTANT NUMBER := 12;  -- ���σw�b�_�L���͈́i���j
--
  cn_header_rec               CONSTANT NUMBER := 1;  -- CSV�t�@�C���w�b�_�s
--
  cv_get_num_type_quote       CONSTANT VARCHAR2(1) := '1';  -- �̔ԃ^�C�v�F����
--
  --CSV�t�@�C���̍��ڈʒu
  cn_col_pos_data_div                    CONSTANT NUMBER := 1;   -- �f�[�^�敪
  cn_col_pos_cust_code_warehouse         CONSTANT NUMBER := 2;   -- �ڋq�i�����≮�j�R�[�h
  cn_col_pos_deliv_place                 CONSTANT NUMBER := 3;   -- �[���ꏊ
  cn_col_pos_payment_condition           CONSTANT NUMBER := 4;   -- �x������
  cn_col_pos_store_price_tax             CONSTANT NUMBER := 5;   -- �������i�ŋ敪
  cn_col_pos_deliv_price_tax             CONSTANT NUMBER := 6;   -- �X�[���i�ŋ敪
  cn_col_pos_special_note                CONSTANT NUMBER := 7;   -- ���L����
  cn_col_pos_quote_submit_name           CONSTANT NUMBER := 8;   -- ���Ϗ���o�於
  cn_col_pos_unit_type                   CONSTANT NUMBER := 9;   -- �P���敪
  cn_col_pos_cust_code_sale              CONSTANT NUMBER := 10;  -- �ڋq�i�̔���j�R�[�h
  cn_col_pos_item_code                   CONSTANT NUMBER := 11;  -- ���i�R�[�h
  cn_col_pos_quote_div                   CONSTANT NUMBER := 12;  -- ���ϋ敪
  cn_col_pos_quotation_price             CONSTANT NUMBER := 13;  -- ���l
  cn_col_pos_sales_discount              CONSTANT NUMBER := 14;  -- ����l��
  cn_col_pos_usually_deliv_price         CONSTANT NUMBER := 15;  -- �ʏ�X�[���i
  cn_col_pos_this_time_dlv_price         CONSTANT NUMBER := 16;  -- ����X�[���i
  cn_col_pos_usuall_net_price            CONSTANT NUMBER := 17;  -- �ʏ�NET���i
  cn_col_pos_this_time_net_price         CONSTANT NUMBER := 18;  -- ����NET���i
  cn_col_pos_quote_start_date            CONSTANT NUMBER := 19;  -- ���ԁi�J�n�j
  cn_col_pos_quote_end_date              CONSTANT NUMBER := 20;  -- ���ԁi�I���j
  cn_col_pos_remarks                     CONSTANT NUMBER := 21;  -- ���l
  cn_col_pos_usually_store_sale          CONSTANT NUMBER := 22;  -- �ʏ�X������
  cn_col_pos_this_time_str_sale          CONSTANT NUMBER := 23;  -- ����X������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �A�b�v���[�h�f�[�^�����擾�p
  TYPE gt_col_data_ttype    IS TABLE OF VARCHAR(5000) INDEX BY BINARY_INTEGER;      --1�����z��i���ځj
  TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;  --2�����z��i���R�[�h�j�i���ځj
--
  -- ���ύ쐬�p�f�[�^�ێ�
  TYPE gt_ins_quote_rtype IS RECORD(
    line_no                     xxcso_quote_upload_work.line_no%TYPE,                     -- �s�ԍ�
    data_div                    xxcso_quote_upload_work.data_div%TYPE,                    -- �f�[�^�敪
    cust_code_warehouse         xxcso_quote_upload_work.cust_code_warehouse%TYPE,         -- �ڋq�i�����≮�j�R�[�h
    deliv_place                 xxcso_quote_upload_work.deliv_place%TYPE,                 -- �[���ꏊ
    payment_condition           xxcso_quote_upload_work.payment_condition%TYPE,           -- �x������
    store_price_tax_type        xxcso_quote_upload_work.store_price_tax_type%TYPE,        -- �������i�ŋ敪
    deliv_price_tax_type        xxcso_quote_upload_work.deliv_price_tax_type%TYPE,        -- �X�[���i�ŋ敪
    special_note                xxcso_quote_upload_work.special_note%TYPE,                -- ���L����
    quote_submit_name           xxcso_quote_upload_work.quote_submit_name%TYPE,           -- ���Ϗ���o�於
    unit_type                   xxcso_quote_upload_work.unit_type%TYPE,                   -- �P���敪
    cust_code_sale              xxcso_quote_upload_work.cust_code_sale%TYPE,              -- �ڋq�i�̔���j�R�[�h
    item_code                   xxcso_quote_upload_work.item_code%TYPE,                   -- ���i�R�[�h
    quote_div                   xxcso_quote_upload_work.quote_div%TYPE,                   -- ���ϋ敪
    quotation_price             xxcso_quote_upload_work.quotation_price%TYPE,             -- ���l
    sales_discount_price        xxcso_quote_upload_work.sales_discount_price%TYPE,        -- ����l��
    usually_deliv_price         xxcso_quote_upload_work.usually_deliv_price%TYPE,         -- �ʏ�X�[���i
    this_time_deliv_price       xxcso_quote_upload_work.this_time_deliv_price%TYPE,       -- ����X�[���i
    usuall_net_price            xxcso_quote_upload_work.usuall_net_price%TYPE,            -- �ʏ�NET���i
    this_time_net_price         xxcso_quote_upload_work.this_time_net_price%TYPE,         -- ����NET���i
    quote_start_date            xxcso_quote_upload_work.quote_start_date%TYPE,            -- ���ԁi�J�n�j
    quote_end_date              xxcso_quote_upload_work.quote_end_date%TYPE,              -- ���ԁi�I���j
    remarks                     xxcso_quote_upload_work.remarks%TYPE,                     -- ���l
    usually_store_sale_price    xxcso_quote_upload_work.usually_store_sale_price%TYPE,    -- �ʏ�X������
    this_time_store_sale_price  xxcso_quote_upload_work.this_time_store_sale_price%TYPE,  -- ����X������
    store_price_tax_type_code   xxcso_quote_headers.store_price_tax_type%TYPE,            -- �������i�ŋ敪�R�[�h
    deliv_price_tax_type_code   xxcso_quote_headers.deliv_price_tax_type%TYPE,            -- �X�[���i�ŋ敪�R�[�h
    unit_type_code              xxcso_quote_headers.unit_type%TYPE,                       -- �P���敪�R�[�h
    inventory_item_id           xxcso_quote_lines.inventory_item_id%TYPE,                 -- �i��ID
    quote_div_code              xxcso_quote_lines.quote_div%TYPE,                         -- ���ϋ敪�R�[�h
    margin_amt                  xxcso_quote_lines.amount_of_margin%TYPE,                  -- �}�[�W���z
    margin_rate                 xxcso_quote_lines.margin_rate%TYPE,                       -- �}�[�W����
    business_price              xxcso_quote_lines.business_price%TYPE                     -- �c�ƌ���
  );
  TYPE gt_ins_quote_data_ttype IS TABLE OF gt_ins_quote_rtype INDEX BY BINARY_INTEGER;
--
  -- �Ɩ��`�F�b�N���s�v��
  TYPE gt_business_check_spec_rtype IS RECORD(
    cust_code_warehouse    BOOLEAN,  -- �ڋq�i�����≮�j�R�[�h
    store_price_tax_type   BOOLEAN,  -- �������i�ŋ敪
    deliv_price_tax_type   BOOLEAN,  -- �X�[���i�ŋ敪
    unit_type              BOOLEAN,  -- �P���敪
    cust_code_sale         BOOLEAN,  -- �ڋq�i�̔���j�R�[�h
    item_code              BOOLEAN,  -- ���i�R�[�h
    quote_div              BOOLEAN,  -- ���ϋ敪
    usually_deliv_price    BOOLEAN,  -- �ʏ�X�[���i
    this_time_deliv_price  BOOLEAN,  -- ����X�[���i
    usuall_net_price       BOOLEAN,  -- �ʏ�NET���i
    this_time_net_price    BOOLEAN,  -- ����NET���i
    quote_start_date       BOOLEAN,  -- ���ԁi�J�n�j
    quote_end_date         BOOLEAN,  -- ���ԁi�I���j
    margin_rate            BOOLEAN   -- �}�[�W����
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date  DATE;    -- �Ɩ��������t
  gn_period_day    NUMBER;  -- ���ϊ��ԁi�J�n�j�̗L���͈�
  gn_margin_rate   NUMBER;  -- �ُ�}�[�W����
  gv_emp_number    xxcso_employees_v2.employee_number%TYPE;     -- ���O�C���҂̏]�ƈ��ԍ�
  gv_base_code     xxcso_employees_v2.work_base_code_new%TYPE;  -- ���O�C���҂̏������_�R�[�h
  gn_tax_rate      xxcso_qt_ap_tax_rate_v.ap_tax_rate%TYPE;     -- �����ŗ�
  gv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- �t�@�C���A�b�v���[�h����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2,  -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.�t�H�[�}�b�g�p�^�[��
    on_file_id    OUT NUMBER,    -- 3.�t�@�C��ID�i�^�ϊ���j
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
--
    -- *** ���[�J���ϐ� ***
    lv_msg           VARCHAR2(5000);  --���b�Z�[�W
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    ln_file_id       NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �t�@�C��ID���b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_id
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                 );
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_fmt_ptn
                   ,iv_token_name1  => cv_tkn_fmt_ptn
                   ,iv_token_value1 => iv_fmt_ptn
                 );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- �p�����[�^�D�t�@�C��ID�̕K�{���̓`�F�b�N
    IF (iv_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �p�����[�^�D�t�@�C��ID�̌^�`�F�b�N(���l�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    ln_file_id := TO_NUMBER(iv_file_id);
--
    -- �p�����[�^�D�t�H�[�}�b�g�p�^�[���̕K�{���̓`�F�b�N
    IF (iv_fmt_ptn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_fmt_ptn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�Ɩ��������t
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�Ɩ��������t�擾�`�F�b�N
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      -- �t�@�C���A�b�v���[�h����
      SELECT flv.meaning meaning
      INTO   gv_file_ul_name
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type = cv_lkup_file_ul_obj
      AND   flv.lookup_code = iv_fmt_ptn
      AND   flv.language = USERENV('LANG')
      AND   flv.enabled_flag = cv_enabled
      AND   gd_process_date BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_ul_name
                   ,iv_token_name1  => cv_tkn_file_ul_name
                   ,iv_token_value1 => TO_CHAR(gv_file_ul_name)
                 );
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --CSV�t�@�C����
      SELECT xmfui.file_name file_name
      INTO   lv_file_name
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSV�t�@�C�������b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_file_name
                     ,iv_token_name1  => cv_tkn_file_name
                     ,iv_token_value1 => TO_CHAR(lv_file_name)
                   );
      -- CSV�t�@�C�������b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN -- ���b�N�擾���s
        --���b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --�f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --�v���t�@�C���I�v�V�����擾
--
    IF (NOT xxcop_common_pkg.chk_number_format(FND_PROFILE.VALUE(cv_profile_period_day))) THEN
      --���ϊ��ԁi�J�n�j�̗L���͈� ���l�`�F�b�N
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_profile_data_type
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_period_day
                     ,iv_token_name2  => cv_tkn_profile_value
                     ,iv_token_value2 => FND_PROFILE.VALUE(cv_profile_period_day)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --���ϊ��ԁi�J�n�j�̗L���͈�
    gn_period_day := TO_NUMBER(FND_PROFILE.VALUE(cv_profile_period_day));
    --���ϊ��ԁi�J�n�j�̗L���͈̓f�[�^�`�F�b�N
    IF (gn_period_day IS NULL) THEN
      --�v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_period_day
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (NOT xxcop_common_pkg.chk_number_format(FND_PROFILE.VALUE(cv_profile_margin_rate))) THEN
      --�ُ�}�[�W���� ���l�`�F�b�N
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_profile_data_type
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_margin_rate
                     ,iv_token_name2  => cv_tkn_profile_value
                     ,iv_token_value2 => FND_PROFILE.VALUE(cv_profile_margin_rate)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --�ُ�}�[�W����
    gn_margin_rate := TO_NUMBER(FND_PROFILE.VALUE(cv_profile_margin_rate));
    --�ُ�}�[�W�����f�[�^�`�F�b�N
    IF (gn_margin_rate IS NULL) THEN
      --�v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_margin_rate
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      --���O�C���ҏ��擾
      SELECT xev.employee_number employee_number
            ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_code_new
               ,xev.work_base_code_old
               ,xev.issue_date
               ,gd_process_date
             ) base_code
      INTO gv_emp_number
          ,gv_base_code
      FROM xxcso_employees_v2 xev
      WHERE xev.user_id = fnd_global.user_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_emp_v
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      --�����ŗ�
      SELECT xqatrv.ap_tax_rate ap_tax_rate
      INTO gn_tax_rate
      FROM xxcso_qt_ap_tax_rate_v xqatrv
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_tax_rate
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    on_file_id := ln_file_id;
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id         IN  NUMBER,             -- 1.�t�@�C��ID
    ot_quote_data_tab  OUT gt_rec_data_ttype,  -- ���σf�[�^�z��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    cv_col_separator     CONSTANT VARCHAR2(10) := ',';  -- ���ڋ�ؕ���
    cn_csv_file_col_num  CONSTANT NUMBER := 23;         -- CSV�t�@�C�����ڐ�
--
     -- *** ���[�J���ϐ� ***
    ln_col_num     NUMBER;
    ln_line_cnt    NUMBER;
    ln_column_cnt  NUMBER;
--
    -- *** ���[�J���E���R�[�h ***
    l_file_data_tab         xxccp_common_pkg2.g_file_data_tbl;  -- �s�P�ʃf�[�^�i�[�p�z��
    l_quote_data_tab        gt_rec_data_ttype;                  -- ���σf�[�^�z��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --�f�[�^���o�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => cv_tbl_nm_file_ul_if
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      --�w�b�_�s���������f�[�^��0�s�̏ꍇ
      --�Ώی���0�����b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      --�Ώی���0�����b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode := cv_status_warn;
      --�f�[�^�����̂��߈ȉ��̏����͍s��Ȃ��B
      RETURN;
    END IF;
--
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        --����CSV�t�H�[�}�b�g�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        --����CSV�t�H�[�}�b�g�G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode := cv_status_warn;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          l_quote_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                             iv_char     => l_file_data_tab(ln_line_cnt)
                                                            ,iv_delim    => cv_col_separator
                                                            ,in_part_num => ln_column_cnt
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    ot_quote_data_tab := l_quote_data_tab;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : get_check_spec
   * Description      : ���̓f�[�^�`�F�b�N�d�l�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_check_spec(
    in_col_pos         IN  NUMBER,    -- ���ڈʒu
    iv_data_div_val    IN  VARCHAR2,  -- �f�[�^�敪
    ov_allow_null      OUT VARCHAR2,  -- NULL����
    ov_data_type       OUT VARCHAR2,  -- �f�[�^�^
    on_length          OUT NUMBER,    -- ���ڒ�
    on_length_decimal  OUT NUMBER,    -- ���ڒ��i�����_�ȉ��j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_check_spec'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    CASE in_col_pos
    WHEN cn_col_pos_data_div THEN
      -- �f�[�^�敪�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 1;
      on_length_decimal := NULL;
    WHEN cn_col_pos_cust_code_warehouse THEN
       -- �ڋq�i�����≮�j�R�[�h�`�F�b�N�d�l
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 9;
      on_length_decimal := NULL;
    WHEN cn_col_pos_deliv_place THEN
       -- �[���ꏊ�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_payment_condition THEN
       -- �x�������`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_store_price_tax THEN
       -- �������i�ŋ敪�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_deliv_price_tax THEN
       -- �X�[���i�ŋ敪�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_special_note THEN
       -- ���L�����`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 100;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_submit_name THEN
       -- ���Ϗ���o�於�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 40;
      on_length_decimal := NULL;
    WHEN cn_col_pos_unit_type THEN
       -- �P���敪�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 6;
      on_length_decimal := NULL;
    WHEN cn_col_pos_cust_code_sale THEN
       -- �ڋq�i�̔���j�R�[�h�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 9;
      on_length_decimal := NULL;
    WHEN cn_col_pos_item_code THEN
       -- ���i�R�[�h�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 7;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_div THEN
       -- ���ϋ敪�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quotation_price THEN
       -- ���l�`�F�b�N�d�l
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_sales_discount THEN
       -- ����l���`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_usually_deliv_price THEN
       -- �ʏ�X�[���i�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_dlv_price THEN
       -- ����X�[���i�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_usuall_net_price THEN
       -- �ʏ�NET���i�`�F�b�N�d�l
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_net_price THEN
       -- ����NET���i�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_quote_start_date THEN
       -- ���ԁi�J�n�j�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_dat;
      on_length         := 10;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_end_date THEN
       -- ���ԁi�I���j�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_dat;
      on_length         := 10;
      on_length_decimal := NULL;
    WHEN cn_col_pos_remarks THEN
       -- ���l�`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_usually_store_sale THEN
       -- �ʏ�X�������`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 8;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_str_sale THEN
       -- ����X�������`�F�b�N�d�l
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 8;
      on_length_decimal := 2;
    END CASE;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : fnc_check_data
   * Description      : ���̓f�[�^�`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE fnc_check_data(
    in_line_cnt        IN  NUMBER,    -- �s�ԍ�
    iv_column          IN  VARCHAR2,  -- ���ږ�
    iv_col_val         IN  VARCHAR2,  -- ���ڒl
    iv_allow_null      IN  VARCHAR2,  -- �K�{�`�F�b�N
    iv_data_type       IN  VARCHAR2,  -- �f�[�^�^
    in_length          IN  NUMBER,    -- ���ڒ�
    in_length_decimal  IN  NUMBER,    -- ���ڒ��i�����_�ȉ��j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fnc_check_data'; -- �v���O������
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
    lb_invalid_err_flag  BOOLEAN;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lb_invalid_err_flag := FALSE;
--
    IF (iv_allow_null = xxccp_common_pkg2.gv_null_ng) THEN
      -- �K�{���̓`�F�b�N
      IF (iv_col_val IS NULL) THEN
        -- �K�{���ڃG���[�i�����s�j
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_required
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- �K�{���ڃG���[�i�����s�j�G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END IF;
--
    IF (iv_col_val IS NOT NULL) THEN
      --�����`�F�b�N
      CASE iv_data_type
      WHEN xxccp_common_pkg2.gv_attr_num THEN
        -- ���l�^�`�F�b�N
        IF (NOT xxcop_common_pkg.chk_number_format(iv_col_val)) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      WHEN xxccp_common_pkg2.gv_attr_dat THEN
        -- ���t�^�`�F�b�N
        IF (NOT xxcop_common_pkg.chk_date_format(iv_col_val, cv_date_fmt)) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      ELSE
        NULL;
      END CASE;
--
      --�����`�F�b�N
      IF (NOT lb_invalid_err_flag) THEN
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => iv_column,                     -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => iv_col_val,                    -- 2.���ڂ̒l                   -- �C��
          in_item_len     => in_length,                     -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => in_length_decimal,             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,  -- 5.�K�{�t���O                 -- �K�{
          iv_item_attr    => iv_data_type,                  -- 6.���ڑ���                   -- �K�{
          ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      END IF;
--
      IF (lb_invalid_err_flag) THEN
        -- �^�E�����`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invalid
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- �^�E�����`�F�b�N�G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      IF (NOT lb_invalid_err_flag
        AND iv_data_type = xxccp_common_pkg2.gv_attr_num
        AND TO_NUMBER(iv_col_val) < 0)
      THEN
        -- ���l�̏ꍇ�A�����̓G���[
        -- ���l�̓��͒l�`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invld_negative_num
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END IF;
--
  EXCEPTION
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
  END fnc_check_data;
--
  /**********************************************************************************
   * Procedure Name   : check_input_data
   * Description      : ���̓f�[�^�`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE check_input_data(
    iv_fmt_ptn         IN  VARCHAR2,           -- �t�H�[�}�b�g�p�^�[��
    it_quote_data_tab  IN  gt_rec_data_ttype,  -- ���σf�[�^�z��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_input_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_line_cnt               NUMBER;
    ln_col_cnt                NUMBER;
    lv_allow_null             VARCHAR2(30);
    lv_data_type              VARCHAR2(30);
    ln_length                 NUMBER;
    ln_length_decimal         NUMBER;
    lv_frst_rec_data_div_val  VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<chk_line_loop>>
    FOR ln_line_cnt IN 2 .. it_quote_data_tab.COUNT LOOP
      <<chk_col_loop>>
      FOR ln_col_cnt IN 1 .. it_quote_data_tab(ln_line_cnt).COUNT LOOP
        -- ���ڃ`�F�b�N�d�l�i�K�{�E�^�E�����j�擾
        get_check_spec(
          ln_col_cnt,
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_data_div),
          lv_allow_null,
          lv_data_type,
          ln_length,
          ln_length_decimal,
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �`�F�b�N����
        fnc_check_data(
          ln_line_cnt - 1,
          it_quote_data_tab(cn_header_rec)(ln_col_cnt),
          it_quote_data_tab(ln_line_cnt)(ln_col_cnt),
          lv_allow_null,
          lv_data_type,
          ln_length,
          ln_length_decimal,
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
        IF (lv_retcode = cv_status_warn) THEN
          ov_retcode := lv_retcode;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        IF (ln_col_cnt = cn_col_pos_data_div) THEN
          -- �f�[�^�敪�́A�l�̓��e���`�F�b�N
          IF (it_quote_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_data_div_sale_only
            AND  it_quote_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_data_div_sale_warehouse)
          THEN
            -- �f�[�^�敪�`�F�b�N�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_data_div_check
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt - 1
                          );
            -- �f�[�^�敪�`�F�b�N�G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := lv_retcode;
          END IF;
--
          IF (iv_fmt_ptn = cv_fmt_ptn_ul_sale_only
            AND it_quote_data_tab(ln_line_cnt)(ln_col_cnt) = cv_data_div_sale_warehouse)
          THEN
            -- ���Ϗ��A�b�v���[�h�i�̔���j������s�����ꍇ�A�f�[�^�敪0�i�̔���{�����≮�j�̓G���[
            -- ����CSV�A�b�v���[�h�s�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_qt_ul_not_allowed
                            ,iv_token_name1  => cv_tkn_file_ul_name
                            ,iv_token_value1 => gv_file_ul_name
                            ,iv_token_name2  => cv_tkn_data_div_val
                            ,iv_token_value2 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => ln_line_cnt - 1
                          );
            -- ����CSV�A�b�v���[�h�s�G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
          IF (ln_line_cnt = 2) THEN
            -- �f�[�^�敪�l�̍��݃`�F�b�N�p�ɍŏ��̒l��ێ�
            lv_frst_rec_data_div_val := it_quote_data_tab(ln_line_cnt)(ln_col_cnt);
          END IF;
          IF (lv_frst_rec_data_div_val <> it_quote_data_tab(ln_line_cnt)(ln_col_cnt)) THEN
            -- �A�b�v���[�h���ꂽ�t�@�C�����Ƀf�[�^�敪�l���������݂���ꍇ�̓G���[
            -- �f�[�^�敪������ގw��G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_too_many_data_div
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt -1
                          );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END LOOP chk_col_loop;
    END LOOP chk_line_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_input_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_upload_work
   * Description      : ���Ϗ��A�b�v���[�h���ԃe�[�u���o�^(A-4)
   ***********************************************************************************/
  PROCEDURE insert_quote_upload_work(
    in_file_id         IN  NUMBER,             -- �t�@�C��ID
    it_quote_data_tab  IN  gt_rec_data_ttype,  -- ���σf�[�^�z��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_upload_work'; -- �v���O������
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
    ln_line_cnt  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. it_quote_data_tab.COUNT LOOP
      BEGIN
        INSERT INTO xxcso_quote_upload_work(
          file_id,
          line_no,
          data_div,
          cust_code_warehouse,
          deliv_place,
          payment_condition,
          store_price_tax_type,
          deliv_price_tax_type,
          special_note,
          quote_submit_name,
          unit_type,
          cust_code_sale,
          item_code,
          quote_div,
          quotation_price,
          sales_discount_price,
          usually_deliv_price,
          this_time_deliv_price,
          usuall_net_price,
          this_time_net_price,
          quote_start_date,
          quote_end_date,
          remarks,
          usually_store_sale_price,
          this_time_store_sale_price,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        ) VALUES (
          in_file_id,
          ln_line_cnt - 1,
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_data_div),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_cust_code_warehouse),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_deliv_place),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_payment_condition),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_store_price_tax),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_deliv_price_tax),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_special_note),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_submit_name),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_unit_type),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_cust_code_sale),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_item_code),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_div),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quotation_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_sales_discount)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usually_deliv_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_dlv_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usuall_net_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_net_price)),
          TO_DATE(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_start_date), cv_date_fmt),
          TO_DATE(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_end_date), cv_date_fmt),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_remarks),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usually_store_sale)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_str_sale)),
          cn_created_by,
          cd_creation_date,
          cn_last_updated_by,
          cd_last_update_date,
          cn_last_update_login,
          cn_request_id,
          cn_program_application_id,
          cn_program_id,
          cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�o�^�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_ins_data
                         ,iv_token_name1  => cv_tkn_action
                         ,iv_token_value1 => cv_tbl_nm_quote_ul_work
                         ,iv_token_name2  => cv_tkn_error_message
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP ins_line_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_quote_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : get_business_check_spec
   * Description      : �Ɩ��`�F�b�N�d�l�擾(A-6)
   ***********************************************************************************/
  PROCEDURE get_business_check_spec(
    iv_data_div             IN  NUMBER,                        -- �f�[�^�敪
    ot_business_check_spec  OUT gt_business_check_spec_rtype,  -- �Ɩ��`�F�b�N�d�l
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_business_check_spec'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    -- ���ڃ`�F�b�N�v�ۂ̐ݒ�
    -- �ڋq�i�����≮�j�R�[�h
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.cust_code_warehouse   := FALSE;
    ELSE
      ot_business_check_spec.cust_code_warehouse   := TRUE;
    END IF;
    -- �������i�ŋ敪
    ot_business_check_spec.store_price_tax_type  := TRUE;
    -- �X�[���i�ŋ敪
    ot_business_check_spec.deliv_price_tax_type  := TRUE;
    -- �P���敪
    ot_business_check_spec.unit_type             := TRUE;
    -- �ڋq�i�̔���j�R�[�h
    ot_business_check_spec.cust_code_sale        := TRUE;
    -- ���i�R�[�h
    ot_business_check_spec.item_code             := TRUE;
    -- ���ϋ敪
    ot_business_check_spec.quote_div             := TRUE;
    -- �ʏ�X�[���i
    ot_business_check_spec.usually_deliv_price   := TRUE;
    -- ����X�[���i
    ot_business_check_spec.this_time_deliv_price := TRUE;
    -- �ʏ�NET���i
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.usuall_net_price      := FALSE;
    ELSE
      ot_business_check_spec.usuall_net_price      := TRUE;
    END IF;
    -- ����NET���i
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.this_time_net_price   := FALSE;
    ELSE
      ot_business_check_spec.this_time_net_price   := TRUE;
    END IF;
    -- ���ԁi�J�n�j
    ot_business_check_spec.quote_start_date      := TRUE;
    -- ���ԁi�I���j
    ot_business_check_spec.quote_end_date        := TRUE;
    -- �}�[�W����
    IF (iv_data_div =cv_data_div_sale_only) THEN
      ot_business_check_spec.margin_rate           := FALSE;
    ELSE
      ot_business_check_spec.margin_rate           := TRUE;
    END IF;
--
  EXCEPTION
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
  END get_business_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : calc_below_cost
   * Description      : ��������v�Z(A-6)
   ***********************************************************************************/
  PROCEDURE calc_below_cost(
    in_price      IN  NUMBER,  -- ���i
    in_inc_num    IN  NUMBER,  -- ����
    in_cost       IN  NUMBER,  -- �c�ƌ���
    in_tax_rate   IN  NUMBER,  -- �����ŗ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_below_cost'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    IF (in_cost IS NOT NULL) THEN
      IF (in_price / NVL(in_inc_num, 1) <= in_cost * in_tax_rate) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
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
  END calc_below_cost;
--
  /**********************************************************************************
   * Procedure Name   : calc_margin
   * Description      : �}�[�W���v�Z(A-6)
   ***********************************************************************************/
  PROCEDURE calc_margin(
    in_deliv_price  IN  NUMBER,  -- �X�[���i
    in_net_price    IN  NUMBER,  -- NET���i
    in_inc_num      IN  NUMBER,  -- ����
    on_margin_amt   OUT NUMBER,  -- �}�[�W���z
    on_margin_rate  OUT NUMBER,  -- �}�[�W����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_margin'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
    cn_max_margin_rate         CONSTANT NUMBER := 100;
    cn_min_margin_rate         CONSTANT NUMBER := -100;
    cn_replace_max_margin_rate CONSTANT NUMBER := 99.99;
    cn_replace_min_margin_rate CONSTANT NUMBER := -99.99;
    -- *** ���[�J���ϐ� ***
    ln_margin_amt  NUMBER;
    ln_margin_rate NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �}�[�W�z
    ln_margin_amt := ROUND(in_deliv_price / in_inc_num, 2) - ROUND(in_net_price / in_inc_num, 2);
    -- �}�[�W����
    ln_margin_rate := ROUND(ROUND(ln_margin_amt / ROUND(in_deliv_price / in_inc_num, 2), 6) * 100, 2);
--
    IF (ln_margin_rate > cn_max_margin_rate) THEN
      -- �}�[�W�����i�ő�l�֒u�������j
      ln_margin_rate := cn_replace_max_margin_rate;
    END IF;
    IF (ln_margin_rate < cn_min_margin_rate) THEN
      -- �}�[�W�����i�ŏ��l�֒u�������j
      ln_margin_rate := cn_replace_min_margin_rate;
    END IF;
--
    on_margin_amt := ln_margin_amt;
    on_margin_rate := ln_margin_rate;
--
  EXCEPTION
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
  END calc_margin;
--
  /**********************************************************************************
   * Procedure Name   : business_data_check
   * Description      : �Ɩ��G���[�`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE business_data_check(
    in_file_id                 IN  NUMBER,                   -- �t�@�C��ID
    it_quote_header_data       IN  gt_col_data_ttype,        -- ���σt�@�C���w�b�_���
    ot_for_ins_quote_data_tab  OUT gt_ins_quote_data_ttype,  --���ύ쐬�p�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'business_data_check'; -- �v���O������
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
    cn_default_tax_rate        CONSTANT NUMBER := 1;
--
    -- *** ���[�J���ϐ� ***
    lt_account_number          xxcso_cust_accounts_v.account_number%TYPE;
    lt_for_ins_quote_data_tab  gt_ins_quote_data_ttype;
    lt_store_price_tax_type    xxcso_quote_headers.store_price_tax_type%TYPE;
    lt_deliv_price_tax_type    xxcso_quote_headers.deliv_price_tax_type%TYPE;
    lt_unit_type               xxcso_quote_headers.unit_type%TYPE;
    lt_quote_div               xxcso_quote_lines.quote_div%TYPE;
    lt_tax_rate                xxcso_qt_ap_tax_rate_v.ap_tax_rate%TYPE;
    ln_inc_num                 NUMBER;
    lt_case_inc_num            xxcso_inventory_items_v2.case_inc_num%TYPE;
    lt_bowl_inc_num            xxcso_inventory_items_v2.bowl_inc_num%TYPE;
    lt_inventory_item_id       xxcso_inventory_items_v2.inventory_item_id%TYPE;
    lt_business_price          xxcso_inventory_items_v2.business_price%TYPE;
    ln_margin_amt              NUMBER;
    ln_margin_rate             NUMBER;
--
    CURSOR get_quote_upload_work_cur
    IS
      SELECT xquw.line_no                     line_no
            ,xquw.data_div                    data_div
            ,xquw.cust_code_warehouse         cust_code_warehouse
            ,xquw.deliv_place                 deliv_place
            ,xquw.payment_condition           payment_condition
            ,xquw.store_price_tax_type        store_price_tax_type
            ,xquw.deliv_price_tax_type        deliv_price_tax_type
            ,xquw.special_note                special_note
            ,xquw.quote_submit_name           quote_submit_name
            ,xquw.unit_type                   unit_type
            ,xquw.cust_code_sale              cust_code_sale
            ,xquw.item_code                   item_code
            ,xquw.quote_div                   quote_div
            ,xquw.quotation_price             quotation_price
            ,xquw.sales_discount_price        sales_discount_price
            ,xquw.usually_deliv_price         usually_deliv_price
            ,xquw.this_time_deliv_price       this_time_deliv_price
            ,xquw.usuall_net_price            usuall_net_price
            ,xquw.this_time_net_price         this_time_net_price
            ,xquw.quote_start_date            quote_start_date
            ,xquw.quote_end_date              quote_end_date
            ,xquw.remarks                     remarks
            ,xquw.usually_store_sale_price    usually_store_sale_price
            ,xquw.this_time_store_sale_price  this_time_store_sale_price
      FROM xxcso_quote_upload_work xquw
      WHERE xquw.file_id = in_file_id
      ORDER BY xquw.cust_code_sale
              ,xquw.cust_code_warehouse
              ,xquw.line_no
      ;
--
    CURSOR get_lookup_code_cur (
      iv_lookup_type  VARCHAR2,
      iv_meaning      VARCHAR2)
    IS
      SELECT flv.lookup_code lookup_code
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type = iv_lookup_type
      AND   flv.meaning = iv_meaning
      AND   flv.language = USERENV('LANG')
      AND   flv.enabled_flag = cv_enabled
      AND   gd_process_date BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active, gd_process_date)
      ;
--
    -- *** ���[�J���E���R�[�h ***
    get_quote_upload_work_rec  get_quote_upload_work_cur%ROWTYPE;
    pre_quote_upload_work_rec  get_quote_upload_work_cur%ROWTYPE;
    lt_business_check_spec     gt_business_check_spec_rtype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<business_data_check_loop>>
    FOR get_quote_upload_work_rec IN get_quote_upload_work_cur LOOP
--
      -- �Ɩ��`�F�b�N�̗v�ێ擾
      get_business_check_spec(
         get_quote_upload_work_rec.data_div
        ,lt_business_check_spec
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF (lt_business_check_spec.cust_code_warehouse) THEN
        IF (get_quote_upload_work_rec.cust_code_warehouse <> pre_quote_upload_work_rec.cust_code_warehouse
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.cust_code_warehouse IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          --�ڋq�i�����≮�j�R�[�h
          BEGIN
            SELECT xcav.account_number account_number
            INTO   lt_account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_warehouse
            AND   xcav.torihiki_form = cv_torihiki_form_tonya
            AND   xrcv.employee_number = gv_emp_number
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.cust_code_warehouse := get_quote_upload_work_rec.cust_code_warehouse;
/* 2012/06/20 Ver1.1 Add End   */
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �ڋq�R�[�h���p�s�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_unavailable_cust_cd
                              ,iv_token_name1  => cv_tkn_emp_num
                              ,iv_token_value1 => gv_emp_number
                              ,iv_token_name2  => cv_tkn_col1
                              ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                              ,iv_token_name3  => cv_tkn_col_val1
                              ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => get_quote_upload_work_rec.line_no
                            );
              -- ���b�Z�[�W�o��
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.store_price_tax_type) THEN
        IF (get_quote_upload_work_rec.store_price_tax_type <> pre_quote_upload_work_rec.store_price_tax_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.store_price_tax_type IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- ������
          lt_store_price_tax_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- �������i�ŋ敪
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_tax_type,
                                       get_quote_upload_work_rec.store_price_tax_type)
          LOOP
            lt_store_price_tax_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_store_price_tax_type IS NULL) THEN
            --���̓`�F�b�N�G���[���b�Z�[�W�i�������i�ŋ敪�j
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_store_price_tax)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_store_price_tax)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.store_price_tax_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.store_price_tax_type := get_quote_upload_work_rec.store_price_tax_type ;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.deliv_price_tax_type) THEN
        IF (get_quote_upload_work_rec.deliv_price_tax_type <> pre_quote_upload_work_rec.deliv_price_tax_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.deliv_price_tax_type IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- ������
          lt_deliv_price_tax_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- �X�[���i�ŋ敪
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_tax_type,
                                       get_quote_upload_work_rec.deliv_price_tax_type)
          LOOP
            lt_deliv_price_tax_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_deliv_price_tax_type IS NULL) THEN
            --���̓`�F�b�N�G���[���b�Z�[�W�i�X�[���i�ŋ敪�j
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_deliv_price_tax)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_deliv_price_tax)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.deliv_price_tax_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.deliv_price_tax_type := get_quote_upload_work_rec.deliv_price_tax_type;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
          -- �����ŗ��̌���
          IF (lt_deliv_price_tax_type = cv_price_inc_tax) THEN
            lt_tax_rate := gn_tax_rate;
          ELSE
            lt_tax_rate := cn_default_tax_rate;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.unit_type) THEN
        IF (get_quote_upload_work_rec.unit_type <> pre_quote_upload_work_rec.unit_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.unit_type IS NULL )
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- ������
          lt_unit_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- �P���敪
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_unit_price_div,
                                       get_quote_upload_work_rec.unit_type)
          LOOP
            lt_unit_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_unit_type IS NULL) THEN
            --���̓`�F�b�N�G���[���b�Z�[�W�i�P���敪�j
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_unit_type)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_unit_type)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.unit_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.unit_type := get_quote_upload_work_rec.unit_type;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.cust_code_sale) THEN
        IF (get_quote_upload_work_rec.cust_code_sale <> pre_quote_upload_work_rec.cust_code_sale
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.cust_code_sale IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          -- �ڋq�i�̔���j�R�[�h
          BEGIN
            SELECT xcav.account_number account_number
            INTO lt_account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_sale
            AND   (xcav.customer_class_code = cv_cust_class_cust
              OR   xcav.customer_class_code IS NULL)
            AND   xcav.customer_status IN (cv_cust_stat_mc, cv_cust_stat_sp, cv_cust_stat_approved, cv_cust_stat_cust, cv_cust_stat_pause)
            UNION
            SELECT xcav.account_number account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_sale
            AND   xcav.customer_class_code = cv_cust_class_tonya
            AND   xcav.customer_status IN (cv_cust_stat_stop, cv_cust_stat_other)
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.cust_code_sale := get_quote_upload_work_rec.cust_code_sale;
/* 2012/06/20 Ver1.1 Add End   */
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �ڋq�R�[�h���p�s�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_unavailable_cust_cd
                              ,iv_token_name1  => cv_tkn_emp_num
                              ,iv_token_value1 => gv_emp_number
                              ,iv_token_name2  => cv_tkn_col1
                              ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                              ,iv_token_name3  => cv_tkn_col_val1
                              ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => get_quote_upload_work_rec.line_no
                            );
              -- ���b�Z�[�W�o��
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.item_code) THEN
        IF (get_quote_upload_work_rec.item_code <> pre_quote_upload_work_rec.item_code
          OR get_quote_upload_work_rec.unit_type <> pre_quote_upload_work_rec.unit_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.item_code IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          -- ���i�R�[�h
          BEGIN
            SELECT xiiv.inventory_item_id inventory_item_id,
                   xiiv.case_inc_num case_inc_num,
                   xiiv.bowl_inc_num bowl_inc_num,
                   xiiv.business_price business_price
            INTO lt_inventory_item_id,
                 lt_case_inc_num,
                 lt_bowl_inc_num,
                 lt_business_price
            FROM xxcso_inventory_items_v2 xiiv
            WHERE xiiv.inventory_item_code = get_quote_upload_work_rec.item_code
            AND   xiiv.item_status IN (cv_item_stat_pre_input, cv_item_stat_reg, cv_item_stat_no_plan, cv_item_stat_no_rma)
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.item_code := get_quote_upload_work_rec.item_code;
/* 2012/06/20 Ver1.1 Add End   */
  --
            -- �����`�F�b�N
            IF (get_quote_upload_work_rec.unit_type = cv_unit_type_case) THEN
              ln_inc_num := lt_case_inc_num;
            ELSIF (get_quote_upload_work_rec.unit_type = cv_unit_type_bowl) THEN
              ln_inc_num := lt_bowl_inc_num;
            ELSE
              ln_inc_num := 1;
            END IF;
  --
            IF (NVL(ln_inc_num, 0) = 0 ) THEN
              -- �����`�F�b�N�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name
                             ,iv_name         => cv_msg_err_inc_num
                             ,iv_token_name1  => cv_tkn_col1
                             ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                             ,iv_token_name2  => cv_tkn_col_val1
                             ,iv_token_value2 => get_quote_upload_work_rec.cust_code_sale
                             ,iv_token_name3  => cv_tkn_col2
                             ,iv_token_value3 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name4  => cv_tkn_col_val2
                             ,iv_token_value4 => get_quote_upload_work_rec.item_code
                             ,iv_token_name5  => cv_tkn_col3
                             ,iv_token_value5 => it_quote_header_data(cn_col_pos_unit_type)
                             ,iv_token_name6  => cv_tkn_col_val3
                             ,iv_token_value6 => get_quote_upload_work_rec.unit_type
                             ,iv_token_name7  => cv_tkn_index
                             ,iv_token_value7 => get_quote_upload_work_rec.line_no
                           );
                -- ���b�Z�[�W�o��
                fnd_file.put_line(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���̓`�F�b�N�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name
                             ,iv_name         => cv_msg_err_input_check
                             ,iv_token_name1  => cv_tkn_column
                             ,iv_token_value1 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name2  => cv_tkn_col1
                             ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                             ,iv_token_name3  => cv_tkn_col_val1
                             ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                             ,iv_token_name4  => cv_tkn_col2
                             ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name5  => cv_tkn_col_val2
                             ,iv_token_value5 => get_quote_upload_work_rec.item_code
                             ,iv_token_name6  => cv_tkn_index
                             ,iv_token_value6 => get_quote_upload_work_rec.line_no
                           );
              -- ���b�Z�[�W�o��
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_div) THEN
        IF (get_quote_upload_work_rec.quote_div <> pre_quote_upload_work_rec.quote_div
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.quote_div IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- ������
          lt_quote_div := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- ���ϋ敪
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_quote_div,
                                       get_quote_upload_work_rec.quote_div)
          LOOP
            lt_quote_div := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_quote_div IS NULL) THEN
            --���̓`�F�b�N�G���[���b�Z�[�W�i���ϋ敪�j
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_quote_div)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --�`�F�b�NOK�ƂȂ����f�[�^��ێ�
            pre_quote_upload_work_rec.quote_div := get_quote_upload_work_rec.quote_div;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.usually_deliv_price) THEN
        -- �ʏ�X�[���i
        IF (get_quote_upload_work_rec.quote_div IN(cv_quote_div_normal, cv_quote_div_special_sale)) THEN
          -- ��������`�F�b�N
          calc_below_cost(
             get_quote_upload_work_rec.usually_deliv_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usually_deliv_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.this_time_deliv_price) THEN
        -- ����X�[���i
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_deliv_price IS NOT NULL)
        THEN
          -- ���񉿊i���͕s���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_no
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
--
        IF (get_quote_upload_work_rec.quote_div <> cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_deliv_price IS NULL)
        THEN
          -- ���񉿊i���͕K�v���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_req
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
--
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_special_sale) THEN
          -- ��������`�F�b�N
          calc_below_cost(
             get_quote_upload_work_rec.this_time_deliv_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost_sp
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_deliv_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.usuall_net_price) THEN
        -- �ʏ�NET���i
        IF (get_quote_upload_work_rec.quote_div IN(cv_quote_div_normal, cv_quote_div_special_sale)) THEN
            -- ��������`�F�b�N
          calc_below_cost(
             get_quote_upload_work_rec.usuall_net_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usuall_net_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.this_time_net_price) THEN
        -- ����NET���i
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_net_price IS NOT NULL)
        THEN
          -- ���񉿊i���͕s���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_no
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
  --
        IF (get_quote_upload_work_rec.quote_div <> cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_net_price IS NULL)
        THEN
          -- ���񉿊i���͗v���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_req
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
  --
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_special_sale) THEN
          -- ��������`�F�b�N
          calc_below_cost(
             get_quote_upload_work_rec.this_time_net_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost_sp
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_net_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_start_date) THEN
        -- ���ԁi�J�n�j
        IF (get_quote_upload_work_rec.quote_start_date < gd_process_date - gn_period_day) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_quote_enable_start
                         ,iv_token_name1  => cv_tkn_day
                         ,iv_token_value1 => gn_period_day
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.item_code
                         ,iv_token_name6  => cv_tkn_col3
                         ,iv_token_value6 => it_quote_header_data(cn_col_pos_quote_start_date)
                         ,iv_token_name7  => cv_tkn_col_val3
                         ,iv_token_value7 => get_quote_upload_work_rec.quote_start_date
                         ,iv_token_name8  => cv_tkn_index
                         ,iv_token_value8 => get_quote_upload_work_rec.line_no
                       );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_end_date) THEN
        -- ���ԁi�I���j
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal) THEN
          IF (get_quote_upload_work_rec.quote_end_date > ADD_MONTHS(get_quote_upload_work_rec.quote_start_date, cn_date_range_normal)
            OR get_quote_upload_work_rec.quote_end_date < get_quote_upload_work_rec.quote_start_date)
          THEN
            -- ���ԁi�J�n�j <= ���ԁi�I���j <= ���ԁi�J�n�j��1�N�� �ƂȂ�Ȃ��ꍇ�̓G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_quote_enable_end
                           ,iv_token_name1  => cv_tkn_quote_div
                           ,iv_token_value1 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        ELSE
          IF (get_quote_upload_work_rec.quote_end_date > ADD_MONTHS(get_quote_upload_work_rec.quote_start_date, cn_date_range_special)
            OR get_quote_upload_work_rec.quote_end_date < get_quote_upload_work_rec.quote_start_date)
          THEN
            -- ���ԁi�J�n�j <= ���ԁi�I���j <= ���ԁi�J�n�j��3������ �ƂȂ�Ȃ��ꍇ�̓G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_quote_enable_end_sp
                           ,iv_token_name1  => cv_tkn_quote_div
                           ,iv_token_value1 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.margin_rate) THEN
        -- �}�[�W����
        IF (get_quote_upload_work_rec.this_time_deliv_price IS NULL) THEN
          -- �}�[�W���v�Z
          calc_margin(
             get_quote_upload_work_rec.usually_deliv_price
            ,get_quote_upload_work_rec.usuall_net_price
            ,ln_inc_num
            ,ln_margin_amt
            ,ln_margin_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          IF (ln_margin_rate >= gn_margin_rate) THEN
            -- �ُ�}�[�W�������b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_margin_rate
                           ,iv_token_name1  => cv_tkn_margin_rate
                           ,iv_token_value1 => gn_margin_rate
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.usually_deliv_price
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usuall_net_price
                           ,iv_token_name8  => cv_tkn_num
                           ,iv_token_value8 => ln_inc_num
                           ,iv_token_name9  => cv_tkn_index
                           ,iv_token_value9 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        ELSE
          -- �}�[�W���v�Z
          calc_margin(
             get_quote_upload_work_rec.this_time_deliv_price
            ,get_quote_upload_work_rec.this_time_net_price
            ,ln_inc_num
            ,ln_margin_amt
            ,ln_margin_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          IF (ln_margin_rate >= gn_margin_rate) THEN
            -- �ُ�}�[�W�������b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_margin_rate
                           ,iv_token_name1  => cv_tkn_margin_rate
                           ,iv_token_value1 => gn_margin_rate
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.this_time_deliv_price
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_net_price
                           ,iv_token_name8  => cv_tkn_num
                           ,iv_token_value8 => ln_inc_num
                           ,iv_token_name9  => cv_tkn_index
                           ,iv_token_value9 => get_quote_upload_work_rec.line_no
                         );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
/* 2012/06/20 Ver1.1 Del Start */
--      pre_quote_upload_work_rec := get_quote_upload_work_rec;
/* 2012/06/20 Ver1.1 Del End   */
--
      -- ���ύ쐬�p�f�[�^�z��ێ�
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).line_no                    := get_quote_upload_work_rec.line_no;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).data_div                   := get_quote_upload_work_rec.data_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).cust_code_warehouse        := get_quote_upload_work_rec.cust_code_warehouse;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_place                := get_quote_upload_work_rec.deliv_place;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).payment_condition          := get_quote_upload_work_rec.payment_condition;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).store_price_tax_type       := get_quote_upload_work_rec.store_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_price_tax_type       := get_quote_upload_work_rec.deliv_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).special_note               := get_quote_upload_work_rec.special_note;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_submit_name          := get_quote_upload_work_rec.quote_submit_name;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).unit_type                  := get_quote_upload_work_rec.unit_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).cust_code_sale             := get_quote_upload_work_rec.cust_code_sale;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).item_code                  := get_quote_upload_work_rec.item_code;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_div                  := get_quote_upload_work_rec.quote_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quotation_price            := get_quote_upload_work_rec.quotation_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).sales_discount_price       := get_quote_upload_work_rec.sales_discount_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usually_deliv_price        := get_quote_upload_work_rec.usually_deliv_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_deliv_price      := get_quote_upload_work_rec.this_time_deliv_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usuall_net_price           := get_quote_upload_work_rec.usuall_net_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_net_price        := get_quote_upload_work_rec.this_time_net_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_start_date           := get_quote_upload_work_rec.quote_start_date;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_end_date             := get_quote_upload_work_rec.quote_end_date;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).remarks                    := get_quote_upload_work_rec.remarks;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usually_store_sale_price   := get_quote_upload_work_rec.usually_store_sale_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_store_sale_price := get_quote_upload_work_rec.this_time_store_sale_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).store_price_tax_type_code  := lt_store_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_price_tax_type_code  := lt_deliv_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).unit_type_code             := lt_unit_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).inventory_item_id          := lt_inventory_item_id;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_div_code             := lt_quote_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).margin_amt                 := ln_margin_amt;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).margin_rate                := ln_margin_rate;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).business_price             := lt_business_price;
    END LOOP;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END business_data_check;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_header
   * Description      : ���σw�b�_�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE insert_quote_header(
    iv_quote_type                 IN  VARCHAR2,            -- ���σ^�C�v
    iv_quote_number               IN  VARCHAR2,            -- ���ϔԍ�
    iv_ref_quote_number           IN  VARCHAR2,            -- �Q�ƌ��ϔԍ�
    in_ref_quote_header_id        IN  NUMBER,              -- �Q�ƌ��σw�b�_ID
    it_for_insert_quote_data_rec  IN  gt_ins_quote_rtype,  -- ���σf�[�^�쐬�p�z��
    on_quote_header_id            OUT NUMBER,              -- �쐬�������σw�b�_ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_header'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
    cv_status_input          CONSTANT VARCHAR2(10) := '1';  -- ���σX�e�[�^�X�F���͍ς�
    cn_quote_revision_number CONSTANT NUMBER := 1;          -- ��
    -- *** ���[�J���ϐ� ***
    lt_account_number        xxcso_quote_headers.account_number%TYPE;
    lt_store_price_tax_type  xxcso_quote_headers.store_price_tax_type%TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF (iv_quote_type = cv_quote_type_sale) THEN
      lt_account_number := it_for_insert_quote_data_rec.cust_code_sale;
      lt_store_price_tax_type := it_for_insert_quote_data_rec.store_price_tax_type_code;
    ELSIF (iv_quote_type = cv_quote_type_warehouse) THEN
      lt_account_number := it_for_insert_quote_data_rec.cust_code_warehouse;
      lt_store_price_tax_type := NULL;
    END IF;
--
    BEGIN
      INSERT INTO xxcso_quote_headers(
         quote_header_id
        ,quote_type
        ,quote_number
        ,quote_revision_number
        ,reference_quote_number
        ,reference_quote_header_id
        ,publish_date
        ,account_number
        ,employee_number
        ,base_code
        ,deliv_place
        ,payment_condition
        ,quote_submit_name
        ,status
        ,deliv_price_tax_type
        ,store_price_tax_type
        ,unit_type
        ,special_note
        ,quote_info_start_date
        ,quote_info_end_date
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcso_quote_headers_s01.NEXTVAL
        ,iv_quote_type
        ,iv_quote_number
        ,cn_quote_revision_number
        ,iv_ref_quote_number
        ,in_ref_quote_header_id
        ,gd_process_date
        ,lt_account_number
        ,gv_emp_number
        ,gv_base_code
        ,it_for_insert_quote_data_rec.deliv_place
        ,it_for_insert_quote_data_rec.payment_condition
        ,it_for_insert_quote_data_rec.quote_submit_name
        ,cv_status_input
        ,it_for_insert_quote_data_rec.deliv_price_tax_type_code
        ,lt_store_price_tax_type
        ,it_for_insert_quote_data_rec.unit_type_code
        ,it_for_insert_quote_data_rec.special_note
        ,gd_process_date
        ,ADD_MONTHS(gd_process_date, cn_after_year)
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      ) RETURNING quote_header_id INTO on_quote_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_ins_data
                       ,iv_token_name1  => cv_tkn_action
                       ,iv_token_value1 => cv_tbl_nm_quote_header
                       ,iv_token_name2  => cv_tkn_error_message
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_quote_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_line
   * Description      : ���ϖ��דo�^(A-7)
   ***********************************************************************************/
  PROCEDURE insert_quote_line(
    iv_quote_type                 IN  VARCHAR2,            -- ���σ^�C�v
    in_quote_header_id            IN  NUMBER,              -- ���σw�b�_ID
    in_ref_quote_line_id          IN  NUMBER,              -- �Q�ƌ��ϖ���ID
    it_for_insert_quote_data_rec  IN  gt_ins_quote_rtype,  -- ���ύ쐬�p�z��
    on_quote_line_id              OUT NUMBER,              -- �쐬�������ϖ���ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_line'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lt_usually_store_sale_price   xxcso_quote_lines.usually_store_sale_price%TYPE;
    lt_this_time_store_sale_price xxcso_quote_lines.this_time_store_sale_price%TYPE;
    lt_quotation_price            xxcso_quote_lines.quotation_price%TYPE;
    lt_sales_discount_price       xxcso_quote_lines.sales_discount_price%TYPE;
    lt_usuall_net_price           xxcso_quote_lines.usuall_net_price%TYPE;
    lt_this_time_net_price        xxcso_quote_lines.this_time_net_price%TYPE;
    lt_amount_of_margin           xxcso_quote_lines.amount_of_margin%TYPE;
    lt_margin_rate                xxcso_quote_lines.margin_rate%TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF (iv_quote_type = cv_quote_type_sale) THEN
      lt_usually_store_sale_price := it_for_insert_quote_data_rec.usually_store_sale_price;
      lt_this_time_store_sale_price := it_for_insert_quote_data_rec.this_time_store_sale_price;
      lt_quotation_price := NULL;
      lt_sales_discount_price := NULL;
      lt_usuall_net_price := NULL;
      lt_this_time_net_price := NULL;
      lt_amount_of_margin := NULL;
      lt_margin_rate := NULL;
    ELSIF (iv_quote_type = cv_quote_type_warehouse) THEN
      lt_usually_store_sale_price := NULL;
      lt_this_time_store_sale_price := NULL;
      lt_quotation_price := it_for_insert_quote_data_rec.quotation_price;
      lt_sales_discount_price := it_for_insert_quote_data_rec.sales_discount_price;
      lt_usuall_net_price := it_for_insert_quote_data_rec.usuall_net_price;
      lt_this_time_net_price := it_for_insert_quote_data_rec.this_time_net_price;
      lt_amount_of_margin := it_for_insert_quote_data_rec.margin_amt;
      lt_margin_rate := it_for_insert_quote_data_rec.margin_rate;
    END IF;
--
    BEGIN
      INSERT INTO xxcso_quote_lines(
         quote_line_id
        ,quote_header_id
        ,reference_quote_line_id
        ,inventory_item_id
        ,quote_div
        ,usually_deliv_price
        ,usually_store_sale_price
        ,this_time_deliv_price
        ,this_time_store_sale_price
        ,quotation_price
        ,sales_discount_price
        ,usuall_net_price
        ,this_time_net_price
        ,amount_of_margin
        ,margin_rate
        ,quote_start_date
        ,quote_end_date
        ,remarks
        ,line_order
        ,business_price
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcso_quote_lines_s01.NEXTVAL
        ,in_quote_header_id
        ,in_ref_quote_line_id
        ,it_for_insert_quote_data_rec.inventory_item_id
        ,it_for_insert_quote_data_rec.quote_div_code
        ,it_for_insert_quote_data_rec.usually_deliv_price
        ,lt_usually_store_sale_price
        ,it_for_insert_quote_data_rec.this_time_deliv_price
        ,lt_this_time_store_sale_price
        ,lt_quotation_price
        ,lt_sales_discount_price
        ,lt_usuall_net_price
        ,lt_this_time_net_price
        ,lt_amount_of_margin
        ,lt_margin_rate
        ,it_for_insert_quote_data_rec.quote_start_date
        ,it_for_insert_quote_data_rec.quote_end_date
        ,it_for_insert_quote_data_rec.remarks
        ,NULL
        ,it_for_insert_quote_data_rec.business_price
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      ) RETURNING quote_line_id INTO on_quote_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_ins_data
                       ,iv_token_name1  => cv_tkn_action
                       ,iv_token_value1 => cv_tbl_nm_quote_line
                       ,iv_token_name2  => cv_tkn_error_message
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_quote_line;
--
  /**********************************************************************************
   * Procedure Name   : create_quote_data
   * Description      : ���σf�[�^�쐬(A-7)
   ***********************************************************************************/
  PROCEDURE create_quote_data(
    it_quote_header_data          IN  gt_col_data_ttype,        -- ���σt�@�C���w�b�_���
    it_for_insert_quote_data_tab  IN  gt_ins_quote_data_ttype,  -- ���ύ쐬�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_quote_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lv_msg                          VARCHAR2(5000);
    lt_pre_data_rec                 gt_ins_quote_rtype;
    lt_sale_quote_number            xxcso_quote_headers.quote_number%TYPE;
    lt_sale_quote_header_id         xxcso_quote_headers.quote_header_id%TYPE;
    lt_sale_quote_line_id           xxcso_quote_lines.quote_line_id%TYPE;
    lt_warehouse_quote_number       xxcso_quote_headers.quote_number%TYPE;
    lt_warehouse_quote_header_id    xxcso_quote_headers.quote_header_id%TYPE;
    lt_warehouse_quote_line_id      xxcso_quote_lines.quote_line_id%TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<create_quote_loop>>
    FOR ln_line_cnt IN 1 .. it_for_insert_quote_data_tab.COUNT LOOP
      IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div IN (cv_data_div_sale_warehouse, cv_data_div_sale_only)) THEN
        IF (ln_line_cnt = 1
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale <> lt_pre_data_rec.cust_code_sale
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse <> lt_pre_data_rec.cust_code_warehouse)
        THEN
          -- ���ϔԍ��̔ԁi�̔��敪�j
          lt_sale_quote_number := xxcso_auto_code_assign_pkg.auto_code_assign(
                                     cv_get_num_type_quote
                                    ,gv_base_code
                                    ,gd_process_date
                                  );
          -- ���σw�b�_�o�^�i�̔��敪�j
          insert_quote_header(
             cv_quote_type_sale
            ,lt_sale_quote_number
            ,NULL
            ,NULL
            ,it_for_insert_quote_data_tab(ln_line_cnt)
            ,lt_sale_quote_header_id
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_only) THEN
            -- ���ύ쐬���b�Z�[�W
            lv_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_create_quote_sale
                        ,iv_token_name1  => cv_tkn_col1
                        ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                        ,iv_token_name2  => cv_tkn_col_val1
                        ,iv_token_value2 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale
                        ,iv_token_name3  => cv_tkn_quote_num
                        ,iv_token_value3 => lt_sale_quote_number
                      );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
          END IF;
        END IF;
--
        -- ���ϖ��דo�^�i�̔��敪�j
        insert_quote_line(
           cv_quote_type_sale
          ,lt_sale_quote_header_id
          ,NULL
          ,it_for_insert_quote_data_tab(ln_line_cnt)
          ,lt_sale_quote_line_id
          ,lv_errbuf
          ,lv_retcode
          ,lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_warehouse) THEN
        IF (ln_line_cnt = 1
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale <> lt_pre_data_rec.cust_code_sale
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse <> lt_pre_data_rec.cust_code_warehouse)
        THEN
          -- ���ϔԍ��̔ԁi�����≮���j
          lt_warehouse_quote_number := xxcso_auto_code_assign_pkg.auto_code_assign(
                                          cv_get_num_type_quote
                                         ,gv_base_code
                                         ,gd_process_date
                                       );
          -- ���σw�b�_�o�^�i�����≮���j
          insert_quote_header(
             cv_quote_type_warehouse
            ,lt_warehouse_quote_number
            ,lt_sale_quote_number
            ,lt_sale_quote_header_id
            ,it_for_insert_quote_data_tab(ln_line_cnt)
            ,lt_warehouse_quote_header_id
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_warehouse) THEN
            -- ���ύ쐬���b�Z�[�W
            lv_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_create_quote_sale_wh
                        ,iv_token_name1  => cv_tkn_col1
                        ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                        ,iv_token_name2  => cv_tkn_col_val1
                        ,iv_token_value2 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale
                        ,iv_token_name3  => cv_tkn_col2
                        ,iv_token_value3 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                        ,iv_token_name4  => cv_tkn_col_val2
                        ,iv_token_value4 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse
                        ,iv_token_name5  => cv_tkn_quote_num1
                        ,iv_token_value5 => lt_sale_quote_number
                        ,iv_token_name6  => cv_tkn_quote_num2
                        ,iv_token_value6 => lt_warehouse_quote_number
                      );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
          END IF;
        END IF;
--
        -- ���ϖ��דo�^�i�����≮���j
        insert_quote_line(
           cv_quote_type_warehouse
          ,lt_warehouse_quote_header_id
          ,lt_sale_quote_line_id
          ,it_for_insert_quote_data_tab(ln_line_cnt)
          ,lt_warehouse_quote_line_id
          ,lv_errbuf
          ,lv_retcode
          ,lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      lt_pre_data_rec := it_for_insert_quote_data_tab(ln_line_cnt);
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP create_quote_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_quote_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�폜�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => in_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : delete_quote_upload_work
   * Description      : ���Ϗ��A�b�v���[�h���ԃe�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE delete_quote_upload_work(
    in_file_id    IN  NUMBER,    -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_quote_upload_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    BEGIN
      DELETE FROM xxcso_quote_upload_work xquw
      WHERE xquw.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�폜�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_quote_ul_work
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => in_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_quote_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,  -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lt_quote_data_tab             gt_rec_data_ttype;
    lt_for_insert_quote_data_tab  gt_ins_quote_data_ttype;
    ln_file_id                    NUMBER;
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ��������
    init(
       iv_file_id
      ,iv_fmt_ptn
      ,ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^���o
    get_upload_data(
       ln_file_id
      ,lt_quote_data_tab
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ���̓f�[�^�`�F�b�N
      check_input_data(
         iv_fmt_ptn
        ,lt_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ���Ϗ��A�b�v���[�h���ԃe�[�u���o�^
      insert_quote_upload_work(
         ln_file_id
        ,lt_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �Ɩ��G���[�`�F�b�N
      business_data_check(
         ln_file_id
        ,lt_quote_data_tab(cn_header_rec)
        ,lt_for_insert_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ���σf�[�^�쐬
      create_quote_data(
         lt_quote_data_tab(cn_header_rec)
        ,lt_for_insert_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜
    delete_file_ul_if(
       ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���Ϗ��A�b�v���[�h���ԃe�[�u���f�[�^�폜
    delete_quote_upload_work(
       ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id    IN  VARCHAR2,      -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
    -- ���[�J���萔
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
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
       iv_file_id
      ,iv_fmt_ptn
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := gn_error_cnt + 1;
      gn_normal_cnt := 0;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCSO017A07C;
/
