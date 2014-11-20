CREATE OR REPLACE PACKAGE BODY XXCFR004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A01C(body)
 * Description      : �x���ʒm�f�[�^���o
 * MD.050           : MD050_CFR_004_A01_�x���ʒm�f�[�^���o
 * MD.070           : MD050_CFR_004_A01_�x���ʒm�f�[�^���o
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  get_process_date       p �Ɩ��������t�擾����                    (A-4)
 *  delete_payment_notes   p �x���ʒm�e�[�u���f�[�^�폜����          (A-5)
 *  get_payment_notes      p �x���ʒm�f�[�^�擾����                  (A-6)
 *  convert_cust_code      p �ڋq�R�[�h�Ǒ֏���                      (A-7)
 *  insert_payment_notes   p �x���ʒm�f�[�^�e�[�u���o�^����          (A-8)
 *  put_log_error          p �ǑփG���[���O�o�͏���                  (A-9)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/24    1.00 SCS ���� ��      ����쐬
 *  2009/02/24    1.1  SCS T.KANEDA     [��QCOK_016] �ڋq�R�[�h�Ǒ֕s��Ή�
 *  2009/04/10    1.2  SCS S.KAYAHARA   T1_0129�Ή�
 *  2009/04/24    1.3  SCS S.KAYAHARA   T1_0128�Ή�
 *  2009/05/14    1.4  SCS S.KAYAHARA   T1_0955�Ή�
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  file_not_exists_expt  EXCEPTION;      -- �t�@�C�����݃G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR004A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_004a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_004a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_004a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_004a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --���b�N�G���[���b�Z�[�W
  cv_msg_004a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_004a01_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00005'; --�X�R�[�h�ϊ��G���[
  cv_msg_004a01_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; --�t�@�C���Ȃ��G���[
  cv_msg_004a01_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00040'; --�e�L�X�g�o�b�t�@�G���[
  cv_msg_004a01_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00041'; --���l�^�ϊ��G���[
  cv_msg_004a01_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --�e�[�u���}���G���[
  cv_msg_004a01_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --�t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_004a01_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- �t�@�C���p�X
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
-- Modify 2009.04.10 Ver1.2 Start
  cv_tkn_chcd        CONSTANT VARCHAR2(15) := 'CH_TEN_CODE';      -- �`�F�[���X�R�[�h
-- Modify 2009.04.10 Ver1.2 End
  cv_tkn_tencd       CONSTANT VARCHAR2(15) := 'TEN_CODE';         -- �X�R�[�h
  cv_tkn_tennm       CONSTANT VARCHAR2(15) := 'TEN_NAME';         -- �X�ܖ���
  cv_tkn_col_num     CONSTANT VARCHAR2(15) := 'COL_NUM';          -- ���ڂm��
  cv_tkn_col_val     CONSTANT VARCHAR2(15) := 'COL_VALUE';        -- ���ڒl
--
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
  cv_reserve_day     CONSTANT VARCHAR2(35) := 'XXCFR1_PAYMENT_NOTE_RESERVE_DAY';
                                                                  -- XXCFR:�x���ʒm�f�[�^�ۑ�����
  cv_payment_note_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_PAYMENT_NOTE_FILEPATH';
                                                                  -- XXCFR:�x���ʒm�f�[�^�t�@�C���i�[�p�X
--
  cv_error_string    CONSTANT VARCHAR2(30) := 'Error';            -- �G���[�p�X�R�[�h������
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_PAYMENT_NOTES';
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE g_cust_account_number_ttype       IS TABLE OF xxcfr_payment_notes.ebs_cust_account_number%type INDEX BY PLS_INTEGER;
  TYPE g_record_type_ttype               IS TABLE OF xxcfr_payment_notes.record_type%type INDEX BY PLS_INTEGER;
  TYPE g_record_number_ttype             IS TABLE OF xxcfr_payment_notes.record_number%type INDEX BY PLS_INTEGER;
  TYPE g_chain_shop_code_ttype           IS TABLE OF xxcfr_payment_notes.chain_shop_code%type INDEX BY PLS_INTEGER;
  TYPE g_process_date_ttype              IS TABLE OF xxcfr_payment_notes.process_date%type INDEX BY PLS_INTEGER;
  TYPE g_process_time_ttype              IS TABLE OF xxcfr_payment_notes.process_time%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_code_ttype               IS TABLE OF xxcfr_payment_notes.vendor_code%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_name_ttype               IS TABLE OF xxcfr_payment_notes.vendor_name%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_name_alt_ttype           IS TABLE OF xxcfr_payment_notes.vendor_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_company_code_ttype              IS TABLE OF xxcfr_payment_notes.company_code%type INDEX BY PLS_INTEGER;
  TYPE g_period_from_ttype               IS TABLE OF xxcfr_payment_notes.period_from%type INDEX BY PLS_INTEGER;
  TYPE g_period_to_ttype                 IS TABLE OF xxcfr_payment_notes.period_to%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_close_date_ttype        IS TABLE OF xxcfr_payment_notes.invoice_close_date%type INDEX BY PLS_INTEGER;
  TYPE g_payment_date_ttype              IS TABLE OF xxcfr_payment_notes.payment_date%type INDEX BY PLS_INTEGER;
  TYPE g_site_month_ttype                IS TABLE OF xxcfr_payment_notes.site_month%type INDEX BY PLS_INTEGER;
  TYPE g_note_count_ttype                IS TABLE OF xxcfr_payment_notes.note_count%type INDEX BY PLS_INTEGER;
  TYPE g_credit_note_count_ttype         IS TABLE OF xxcfr_payment_notes.credit_note_count%type INDEX BY PLS_INTEGER;
  TYPE g_rem_acceptance_count_ttype      IS TABLE OF xxcfr_payment_notes.rem_acceptance_count%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_record_count_ttype       IS TABLE OF xxcfr_payment_notes.vendor_record_count%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_number_ttype            IS TABLE OF xxcfr_payment_notes.invoice_number%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_type_ttype              IS TABLE OF xxcfr_payment_notes.invoice_type%type INDEX BY PLS_INTEGER;
  TYPE g_payment_type_ttype              IS TABLE OF xxcfr_payment_notes.payment_type%type INDEX BY PLS_INTEGER;
  TYPE g_payment_method_type_ttype       IS TABLE OF xxcfr_payment_notes.payment_method_type%type INDEX BY PLS_INTEGER;
  TYPE g_due_type_ttype                  IS TABLE OF xxcfr_payment_notes.due_type%type INDEX BY PLS_INTEGER;
  TYPE g_shop_code_ttype                 IS TABLE OF xxcfr_payment_notes.shop_code%type INDEX BY PLS_INTEGER;
  TYPE g_shop_name_ttype                 IS TABLE OF xxcfr_payment_notes.shop_name%type INDEX BY PLS_INTEGER;
  TYPE g_shop_name_alt_ttype             IS TABLE OF xxcfr_payment_notes.shop_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_amount_sign_ttype               IS TABLE OF xxcfr_payment_notes.amount_sign%type INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype                    IS TABLE OF xxcfr_payment_notes.amount%type INDEX BY PLS_INTEGER;
  TYPE g_tax_type_ttype                  IS TABLE OF xxcfr_payment_notes.tax_type%type INDEX BY PLS_INTEGER;
  TYPE g_tax_rate_ttype                  IS TABLE OF xxcfr_payment_notes.tax_rate%type INDEX BY PLS_INTEGER;
  TYPE g_tax_amount_ttype                IS TABLE OF xxcfr_payment_notes.tax_amount%type INDEX BY PLS_INTEGER;
  TYPE g_tax_diff_flag_ttype             IS TABLE OF xxcfr_payment_notes.tax_diff_flag%type INDEX BY PLS_INTEGER;
  TYPE g_diff_calc_flag_ttype            IS TABLE OF xxcfr_payment_notes.diff_calc_flag%type INDEX BY PLS_INTEGER;
  TYPE g_match_type_ttype                IS TABLE OF xxcfr_payment_notes.match_type%type INDEX BY PLS_INTEGER;
  TYPE g_unmatch_accoumt_amount_ttype    IS TABLE OF xxcfr_payment_notes.unmatch_accoumt_amount%type INDEX BY PLS_INTEGER;
  TYPE g_double_type_ttype               IS TABLE OF xxcfr_payment_notes.double_type%type INDEX BY PLS_INTEGER;
  TYPE g_acceptance_date_ttype           IS TABLE OF xxcfr_payment_notes.acceptance_date%type INDEX BY PLS_INTEGER;
  TYPE g_max_month_ttype                 IS TABLE OF xxcfr_payment_notes.max_month%type INDEX BY PLS_INTEGER;
  TYPE g_note_number_ttype               IS TABLE OF xxcfr_payment_notes.note_number%type INDEX BY PLS_INTEGER;
  TYPE g_line_number_ttype               IS TABLE OF xxcfr_payment_notes.line_number%type INDEX BY PLS_INTEGER;
  TYPE g_note_type_ttype                 IS TABLE OF xxcfr_payment_notes.note_type%type INDEX BY PLS_INTEGER;
  TYPE g_class_code_ttype                IS TABLE OF xxcfr_payment_notes.class_code%type INDEX BY PLS_INTEGER;
  TYPE g_div_code_ttype                  IS TABLE OF xxcfr_payment_notes.div_code%type INDEX BY PLS_INTEGER;
  TYPE g_sec_code_ttype                  IS TABLE OF xxcfr_payment_notes.sec_code%type INDEX BY PLS_INTEGER;
  TYPE g_return_type_ttype               IS TABLE OF xxcfr_payment_notes.return_type%type INDEX BY PLS_INTEGER;
  TYPE g_nitiriu_type_ttype              IS TABLE OF xxcfr_payment_notes.nitiriu_type%type INDEX BY PLS_INTEGER;
  TYPE g_sp_sale_type_ttype              IS TABLE OF xxcfr_payment_notes.sp_sale_type%type INDEX BY PLS_INTEGER;
  TYPE g_shipment_ttype                  IS TABLE OF xxcfr_payment_notes.shipment%type INDEX BY PLS_INTEGER;
  TYPE g_order_date_ttype                IS TABLE OF xxcfr_payment_notes.order_date%type INDEX BY PLS_INTEGER;
  TYPE g_delivery_date_ttype             IS TABLE OF xxcfr_payment_notes.delivery_date%type INDEX BY PLS_INTEGER;
  TYPE g_product_code_ttype              IS TABLE OF xxcfr_payment_notes.product_code%type INDEX BY PLS_INTEGER;
  TYPE g_product_name_ttype              IS TABLE OF xxcfr_payment_notes.product_name%type INDEX BY PLS_INTEGER;
  TYPE g_product_name_alt_ttype          IS TABLE OF xxcfr_payment_notes.product_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_delivery_quantity_ttype         IS TABLE OF xxcfr_payment_notes.delivery_quantity%type INDEX BY PLS_INTEGER;
  TYPE g_cost_unit_price_ttype           IS TABLE OF xxcfr_payment_notes.cost_unit_price%type INDEX BY PLS_INTEGER;
  TYPE g_cost_price_ttype                IS TABLE OF xxcfr_payment_notes.cost_price%type INDEX BY PLS_INTEGER;
  TYPE g_desc_code_ttype                 IS TABLE OF xxcfr_payment_notes.desc_code%type INDEX BY PLS_INTEGER;
  TYPE g_chain_orig_desc_ttype           IS TABLE OF xxcfr_payment_notes.chain_orig_desc%type INDEX BY PLS_INTEGER;
  TYPE g_sum_amount_ttype                IS TABLE OF xxcfr_payment_notes.sum_amount%type INDEX BY PLS_INTEGER;
  TYPE g_discount_sum_amount_ttype       IS TABLE OF xxcfr_payment_notes.discount_sum_amount%type INDEX BY PLS_INTEGER;
  TYPE g_return_sum_amount_ttype         IS TABLE OF xxcfr_payment_notes.return_sum_amount%type INDEX BY PLS_INTEGER;
  gt_pn_ebs_cust_account_number         g_cust_account_number_ttype;
  gt_pn_record_type                     g_record_type_ttype;
  gt_pn_record_number                   g_record_number_ttype;
  gt_pn_chain_shop_code                 g_chain_shop_code_ttype;
  gt_pn_process_date                    g_process_date_ttype;
  gt_pn_process_time                    g_process_time_ttype;
  gt_pn_vendor_code                     g_vendor_code_ttype;
  gt_pn_vendor_name                     g_vendor_name_ttype;
  gt_pn_vendor_name_alt                 g_vendor_name_alt_ttype;
  gt_pn_company_code                    g_company_code_ttype;
  gt_pn_period_from                     g_period_from_ttype;
  gt_pn_period_to                       g_period_to_ttype;
  gt_pn_invoice_close_date              g_invoice_close_date_ttype;
  gt_pn_payment_date                    g_payment_date_ttype;
  gt_pn_site_month                      g_site_month_ttype;
  gt_pn_note_count                      g_note_count_ttype;
  gt_pn_credit_note_count               g_credit_note_count_ttype;
  gt_pn_rem_acceptance_count            g_rem_acceptance_count_ttype;
  gt_pn_vendor_record_count             g_vendor_record_count_ttype;
  gt_pn_invoice_number                  g_invoice_number_ttype;
  gt_pn_invoice_type                    g_invoice_type_ttype;
  gt_pn_payment_type                    g_payment_type_ttype;
  gt_pn_payment_method_type             g_payment_method_type_ttype;
  gt_pn_due_type                        g_due_type_ttype;
  gt_pn_shop_code                       g_shop_code_ttype;
  gt_pn_shop_name                       g_shop_name_ttype;
  gt_pn_shop_name_alt                   g_shop_name_alt_ttype;
  gt_pn_amount_sign                     g_amount_sign_ttype;
  gt_pn_amount                          g_amount_ttype;
  gt_pn_tax_type                        g_tax_type_ttype;
  gt_pn_tax_rate                        g_tax_rate_ttype;
  gt_pn_tax_amount                      g_tax_amount_ttype;
  gt_pn_tax_diff_flag                   g_tax_diff_flag_ttype;
  gt_pn_diff_calc_flag                  g_diff_calc_flag_ttype;
  gt_pn_match_type                      g_match_type_ttype;
  gt_pn_unmatch_accoumt_amount          g_unmatch_accoumt_amount_ttype;
  gt_pn_double_type                     g_double_type_ttype;
  gt_pn_acceptance_date                 g_acceptance_date_ttype;
  gt_pn_max_month                       g_max_month_ttype;
  gt_pn_note_number                     g_note_number_ttype;
  gt_pn_line_number                     g_line_number_ttype;
  gt_pn_note_type                       g_note_type_ttype;
  gt_pn_class_code                      g_class_code_ttype;
  gt_pn_div_code                        g_div_code_ttype;
  gt_pn_sec_code                        g_sec_code_ttype;
  gt_pn_return_type                     g_return_type_ttype;
  gt_pn_nitiriu_type                    g_nitiriu_type_ttype;
  gt_pn_sp_sale_type                    g_sp_sale_type_ttype;
  gt_pn_shipment                        g_shipment_ttype;
  gt_pn_order_date                      g_order_date_ttype;
  gt_pn_delivery_date                   g_delivery_date_ttype;
  gt_pn_product_code                    g_product_code_ttype;
  gt_pn_product_name                    g_product_name_ttype;
  gt_pn_product_name_alt                g_product_name_alt_ttype;
  gt_pn_delivery_quantity               g_delivery_quantity_ttype;
  gt_pn_cost_unit_price                 g_cost_unit_price_ttype;
  gt_pn_cost_price                      g_cost_price_ttype;
  gt_pn_desc_code                       g_desc_code_ttype;
  gt_pn_chain_orig_desc                 g_chain_orig_desc_ttype;
  gt_pn_sum_amount                      g_sum_amount_ttype;
  gt_pn_discount_sum_amount             g_discount_sum_amount_ttype;
  gt_pn_return_sum_amount               g_return_sum_amount_ttype;
--
  TYPE c_payment_note_len_ttype IS TABLE OF NUMBER;
  gt_payment_note_len_data  c_payment_note_len_ttype := c_payment_note_len_ttype ( 
-- Modify 2009.04.22 Ver1.3 Start
--    1,    -- ���R�[�h�敪
-- Modify 2009.04.22 Ver1.3 End
    7,    -- ���R�[�h�ʔ�
    4,    -- �`�F�[���X�R�[�h
    8,    -- �f�[�^�쐬���^�f�[�^�������t�^�f�[�^���t�^�`�����t
    6,    -- �f�[�^�쐬�����^�f�[�^��������
    8,    -- �d����R�[�h/�����R�[�h
    30,   -- �d���於��/����於�́i�����j
    30,   -- �d���於��/����於�́i�J�i�j
    6,    -- �ЃR�[�h
    8,    -- �Ώۊ��ԁE��
    8,    -- �Ώۊ��ԁE��
    8,    -- �������N����
    8,    -- �x���N����
    2,    -- �T�C�g����
    6,    -- �`�[����
    6,    -- �����`�[����
    6,    -- �������`�[����
    7,    -- ���������R�[�h�ʔ�
    11,   -- ���������^�����ԍ�
    2,    -- �����敪
    2,    -- �x���敪
    2,    -- �x�����@�敪
    2,    -- ���s�敪
-- Modify 2009.04.22 Ver1.3 Start
--    8,    -- �X�R�[�h
--    80,   -- �X�ܖ��́i�����j
--    80,   -- �X�ܖ��́i�J�i�j
    10,   -- �X�R�[�h
    100,  -- �X�ܖ��́i�����j
    50,   -- �X�ܖ��́i�J�i�j
-- Modify 2009.04.22 Ver1.3 End
    1,    -- �������z�����^��������Ŋz����
    15,   -- �������z�^�x�����z
    1,    -- ����ŋ敪
-- Modify 2009.04.22 Ver1.3 Start
--    2,    -- ����ŗ�
    4,    --����ŗ�
-- Modify 2009.04.22 Ver1.3 End
    15,   -- ��������Ŋz�^�x������Ŋz
    1,    -- ����ō��z�t���O
    2,    -- ��Z�敪
    2,    -- �}�b�`�敪
    15,   -- �A���}�b�`���|�v����z
    2,    -- �_�u���敪
    8,    -- ������
    8,    -- ����
-- Modify 2009.04.22 Ver1.3 Start
--    20,   -- �`�[�ԍ�
--    15,   -- �s��
    12,   -- �`�[�ԍ�
    3,    -- �sNo.
-- Modify 2009.04.22 Ver1.3 End
    2,    -- �`�[�敪�^�`�[���
    4,    -- ���ރR�[�h
    6,    -- ����R�[�h
    4,    -- �ۃR�[�h
    2,    -- ����ԕi�敪
    2,    -- �j�`���E�o�R�敪
    2,    -- �����敪
-- Modify 2009.04.22 Ver1.3 Start
--    6,    -- ��
    3,    -- ��
-- Modify 2009.04.22 Ver1.3 End
    8,    -- ������
    8,    -- �[�i��/�ԕi��
    7,    -- ���i�R�[�h
    60,   -- ���i���i�����j
    30,   -- ���i���i�J�i�j
    15,   -- �[�i����
-- Modify 2009.04.22 Ver1.3 Start
--    15,   -- �����P��
--    15,   -- �������z
    12,   -- �����P��
    10,   -- �������z
-- Modify 2009.04.22 Ver1.3 End
    4,    -- ���l�R�[�h
    300,  -- �`�F�[���ŗL�G���A
    15,   -- �������v���z/�x�����v���z
    15,   -- �l�����v���z
    15    -- �ԕi���v���z
  )
  ;

  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_reserve_day        NUMBER;             -- �x���ʒm�f�[�^�ۑ�����
  gn_org_id             NUMBER;             -- �g�DID
  gd_process_date       DATE;               -- �Ɩ��������t
  gv_payment_note_filepath VARCHAR2(500);   -- �x���ʒm�f�[�^�t�@�C���i�[�p�X
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_filename             IN  VARCHAR2,     --    �x���ʒm�f�[�^�t�@�C����
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_filename        -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,iv_conc_param1  => iv_filename        -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C������XXCFR:�x���ʒm�f�[�^�ۑ����Ԏ擾
    gn_reserve_day := TO_NUMBER(FND_PROFILE.VALUE(cv_reserve_day));
    -- �擾�G���[��
    IF (gn_reserve_day IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_reserve_day))
                                                       -- XXCFR:�x���ʒm�f�[�^�ۑ�����
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR: �x���ʒm�f�[�^�t�@�C���i�[�p�X�擾
    gv_payment_note_filepath := FND_PROFILE.VALUE(cv_payment_note_filepath);
    -- �擾�G���[��
    IF (gv_payment_note_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_payment_note_filepath))
                                                       -- XXCFR:�x���ʒm�f�[�^�t�@�C���i�[�p�X
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_012 -- �Ɩ��������t�擾�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : delete_payment_notes
   * Description      : �x���ʒm�e�[�u���f�[�^�폜���� (A-5)
   ***********************************************************************************/
  PROCEDURE delete_payment_notes(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_payment_notes'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR del_payment_note_cur
    IS
      SELECT xpn.ROWID        ln_rowid
      FROM xxcfr_payment_notes  xpn
      WHERE xpn.org_id                         = gn_org_id  -- �g�DID
        AND xpn.ebs_posted_date                < gd_process_date - gn_reserve_day
                                                 -- �Ɩ����t - �x���ʒm�f�[�^�ۑ�����
      FOR UPDATE NOWAIT
    ;
--
    TYPE g_del_payment_note_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_payment_note_data    g_del_payment_note_ttype;
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
    -- �J�[�\���I�[�v��
    OPEN del_payment_note_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH del_payment_note_cur BULK COLLECT INTO lt_del_payment_note_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_del_payment_note_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE del_payment_note_cur;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<null_data_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_payment_notes
          WHERE ROWID = lt_del_payment_note_data(ln_loop_cnt);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_004a01_014 -- �f�[�^�폜�G���[
                                                        ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                       -- �x���ʒm���e�[�u��
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_004a01_013    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- �x���ʒm���e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END delete_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : get_payment_notes
   * Description      : �x���ʒm�f�[�^�擾���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_payment_notes(
    iv_filename             IN  VARCHAR2,            -- �x���ʒm�f�[�^�t�@�C����
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_notes'; -- �v���O������
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
    cv_open_mode_r    CONSTANT VARCHAR2(10) := 'r';     -- �t�@�C���I�[�v�����[�h�i�ǂݍ��݁j
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;       -- 
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
    -- 
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
    ln_text_pos     NUMBER;         -- �t�@�C�������ʒu
    lv_col_value    VARCHAR2(1000) ;-- ���ڒl 
    ln_col_num      NUMBER;         -- �J�����m�n
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
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_payment_note_filepath,
                      iv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C�����݂Ȃ�
    IF not(lb_fexists) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_016 -- �t�@�C���Ȃ�
                                                    ,cv_tkn_file
                                                    ,iv_filename
                                                    ,cv_tkn_path
                                                    ,gv_payment_note_filepath)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE file_not_exists_expt;
    END IF;
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_payment_note_filepath
                       ,iv_filename
                       ,cv_open_mode_r
                      ) ;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    gt_pn_record_type(1)             := 'B';
    <<out_loop>>
    LOOP
      BEGIN
        -- ====================================================
        -- �t�@�C����荞��
        -- ====================================================
        UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- ���������J�E���g�A�b�v
        -- ====================================================
        ln_target_cnt := ln_target_cnt + 1 ;
--
        -- ====================================================
        -- �Œ蒷�t�@�C�����ڕʋ�؂�
        -- ====================================================
        ln_text_pos := 1;
        <<col_div_loop>>
        FOR ln_loop_cnt IN gt_payment_note_len_data.FIRST..gt_payment_note_len_data.LAST LOOP
          -- ���ڒl�̎擾
          lv_col_value := substrb( lv_csv_text, ln_text_pos, gt_payment_note_len_data(ln_loop_cnt));
          ln_col_num := ln_loop_cnt;
--
--    FND_FILE.PUT_LINE(
--       FND_FILE.LOG
--      ,'���ڃ��[�v�F' || to_char ( ln_target_cnt ) || ':' || to_char ( ln_loop_cnt )  || ':' || lv_col_value
--    );
--
          -- �e�[�u���^�ϐ��ւ̊i�[
          CASE ln_loop_cnt
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 1 THEN
--            gt_pn_record_type(ln_target_cnt)             := lv_col_value;
--          WHEN 2 THEN
          WHEN 1 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_record_number(ln_target_cnt)           := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 3 THEN
          WHEN 2 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_chain_shop_code(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 4 THEN
          WHEN 3 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_process_date(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 5 THEN
          WHEN 4 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_process_time(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 6 THEN
          WHEN 5 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_code(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 7 THEN
          WHEN 6 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_name(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 8 THEN
          WHEN 7 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_name_alt(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 9 THEN
          WHEN 8 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_company_code(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 10 THEN
          WHEN 9 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_period_from(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 11 THEN
          WHEN 10 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_period_to(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 12 THEN
          WHEN 11 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_close_date(ln_target_cnt)      := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 13 THEN
          WHEN 12 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_date(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 14 THEN
          WHEN 13 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.05.14 Ver1.4 Start
--            gt_pn_site_month(ln_target_cnt)              := TO_NUMBER(lv_col_value);
            gt_pn_site_month(ln_target_cnt)              := TO_NUMBER(RTRIM(lv_col_value));
-- Modify 2009.05.14 Ver1.4 End            
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 15 THEN
          WHEN 14 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_count(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 16 THEN
          WHEN 15 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_credit_note_count(ln_target_cnt)       := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 17 THEN
          WHEN 16 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_rem_acceptance_count(ln_target_cnt)    := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 18 THEN
          WHEN 17 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_record_count(ln_target_cnt)     := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 19 THEN
          WHEN 18 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_number(ln_target_cnt)          := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 20 THEN
          WHEN 19 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 21 THEN
          WHEN 20 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 22 THEN
          WHEN 21 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_method_type(ln_target_cnt)     := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 23 THEN
          WHEN 22 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_due_type(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 24 THEN
          WHEN 23 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shop_code(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 25 THEN
          WHEN 24 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shop_name(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 26 THEN
          WHEN 25 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shop_name_alt(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 27 THEN
          WHEN 26 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_amount_sign(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 28 THEN
          WHEN 27 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_amount(ln_target_cnt)                  := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 29 THEN
          WHEN 28 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_type(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 30 THEN
          WHEN 29 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_rate(ln_target_cnt)                := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 31 THEN
          WHEN 30 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_amount(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 32 THEN
          WHEN 31 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_diff_flag(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 33 THEN
          WHEN 32 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_diff_calc_flag(ln_target_cnt)          := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 34 THEN
          WHEN 33 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_match_type(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 35 THEN
          WHEN 34 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_unmatch_accoumt_amount(ln_target_cnt)  := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 36 THEN
          WHEN 35 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_double_type(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 37 THEN
          WHEN 36 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_acceptance_date(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 38 THEN
          WHEN 37 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_max_month(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 39 THEN
          WHEN 38 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_number(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 40 THEN
          WHEN 39 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_line_number(ln_target_cnt)             := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 41 THEN
          WHEN 40 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_type(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 42 THEN
          WHEN 41 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_class_code(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 43 THEN
          WHEN 42 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_div_code(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 44 THEN
          WHEN 43 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sec_code(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 45 THEN
          WHEN 44 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.05.14 Ver1.4 Start
--            gt_pn_return_type(ln_target_cnt)             := TO_NUMBER(lv_col_value);
          gt_pn_return_type(ln_target_cnt)             := TO_NUMBER(RTRIM(lv_col_value));
-- Modify 2009.05.14 Ver1.4 End
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 46 THEN
          WHEN 45 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_nitiriu_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 47 THEN
          WHEN 46 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sp_sale_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 48 THEN
          WHEN 47 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shipment(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 49 THEN
          WHEN 48 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_order_date(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 50 THEN
          WHEN 49 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_delivery_date(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 51 THEN
          WHEN 50 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_code(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 52 THEN
          WHEN 51 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_name(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 53 THEN
          WHEN 52 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_name_alt(ln_target_cnt)        := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 54 THEN
          WHEN 53 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_delivery_quantity(ln_target_cnt)       := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 55 THEN
          WHEN 54 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_cost_unit_price(ln_target_cnt)         := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 56 THEN
          WHEN 55 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_cost_price(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 57 THEN
          WHEN 56 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_desc_code(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 58 THEN
          WHEN 57 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_chain_orig_desc(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 59 THEN
          WHEN 58 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sum_amount(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 60 THEN
          WHEN 59 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_discount_sum_amount(ln_target_cnt)     := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 61 THEN
          WHEN 60 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_return_sum_amount(ln_target_cnt)       := TO_NUMBER(lv_col_value);
          ELSE NULL;
          END CASE;
--
          -- �t�@�C�������ʒu�ړ�
          ln_text_pos := ln_text_pos + gt_payment_note_len_data(ln_loop_cnt);
--
        END LOOP col_div_loop;
--
      EXCEPTION
        -- *** �s���o�b�t�@�Ɏ��܂�Ȃ��ꍇ ***
        WHEN value_error THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_004a01_018
                                                        ,cv_tkn_col_num    -- �g�[�N��'COL_NUM'
                                                        ,TO_CHAR(ln_col_num)
                                                        ,cv_tkn_col_val    -- �g�[�N��'COL_VALUE'
                                                        ,lv_col_value
                                                        ) -- �e�L�X�g�o�b�t�@�G���[
                                                       ,1
                                                       ,5000);
          gn_target_cnt := ln_target_cnt;
          gn_error_cnt := ln_target_cnt;
          RAISE global_api_expt;
        -- *** �t�@�C���̏I���ɒB�������߁A�e�L�X�g���ǂݍ��܂�Ȃ������ꍇ ***
        WHEN NO_DATA_FOUND THEN
          EXIT;
      END;
--
    END LOOP out_loop ;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_target_cnt := ln_target_cnt;
--
  EXCEPTION
--
    WHEN file_not_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �t�@�C���̏ꏊ�������ł� ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_020 -- �t�@�C���̏ꏊ������
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_021 -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : convert_cust_code
   * Description      : �ڋq�R�[�h�Ǒ֏��� (A-7)
   ***********************************************************************************/
  PROCEDURE convert_cust_code(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_cust_code'; -- �v���O������
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
    ln_loop_cnt     NUMBER; -- ���[�v�J�E���^
    ln_error_cnt    NUMBER := 0; -- �G���[�J�E���^
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
    -- =====================================================
    --  �ڋq�R�[�h�Ǒ֏��� (A-7)
    -- =====================================================
    <<cust_data_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      -- �ڋq�R�[�h��ǂݑւ���
      BEGIN
        SELECT hca.account_number           account_number
        INTO gt_pn_ebs_cust_account_number(ln_loop_cnt)
        FROM hz_cust_accounts       hca,    -- �ڋq�}�X�^
             xxcmm_cust_accounts    xca     -- �ڋq�ǉ����e�[�u��
        WHERE hca.cust_account_id        = xca.customer_id
-- Modify 2009.02.24 Ver1.1 Start
--          AND xca.store_code             = gt_pn_shop_code(ln_loop_cnt) -- �X�܃R�[�h
          AND xca.store_code             = RTRIM(gt_pn_shop_code(ln_loop_cnt)) -- �X�܃R�[�h
-- Modify 2009.04.10 Ver1.2 Start
          AND xca.chain_store_code       = RTRIM(gt_pn_chain_shop_code(ln_loop_cnt)) -- �`�F�[���X�R�[�h
-- Modify 2009.04.10 ver1.2 End
-- Modify 2009.02.24 Ver1.1 End	
        ;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
       which  => FND_FILE.log
      ,buff   => SQLERRM
    );
          gt_pn_ebs_cust_account_number(ln_loop_cnt) := cv_error_string;
          ln_error_cnt := ln_error_cnt + 1;
      END;
    END LOOP cust_data_loop;
--
    gn_error_cnt := ln_error_cnt;
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
  END convert_cust_code;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_payment_notes
   * Description      : �x���ʒm�f�[�^�e�[�u���o�^���� (A-8)
   ***********************************************************************************/
  PROCEDURE insert_payment_notes(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_payment_notes'; -- �v���O������
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
    ln_loop_cnt     NUMBER;        -- ���[�v�J�E���^
    ln_normal_cnt   NUMBER := 0;   -- ���팏��
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
    -- =====================================================
    --  �x���ʒm�f�[�^�e�[�u���o�^���� (A-8)
    -- =====================================================
    BEGIN
      <<inert_loop>>
      FORALL ln_loop_cnt IN 1..gn_target_cnt
        INSERT INTO xxcfr_payment_notes ( 
           payment_note_id
          ,ebs_posted_date
          ,ebs_cust_account_number
          ,record_type
          ,record_number
          ,chain_shop_code
          ,process_date
          ,process_time
          ,vendor_code
          ,vendor_name
          ,vendor_name_alt
          ,company_code
          ,period_from
          ,period_to
          ,invoice_close_date
          ,payment_date
          ,site_month
          ,note_count
          ,credit_note_count
          ,rem_acceptance_count
          ,vendor_record_count
          ,invoice_number
          ,invoice_type
          ,payment_type
          ,payment_method_type
          ,due_type
          ,shop_code
          ,shop_name
          ,shop_name_alt
          ,amount_sign
          ,amount
          ,tax_type
          ,tax_rate
          ,tax_amount
          ,tax_diff_flag
          ,diff_calc_flag
          ,match_type
          ,unmatch_accoumt_amount
          ,double_type
          ,acceptance_date
          ,max_month
          ,note_number
          ,line_number
          ,note_type
          ,class_code
          ,div_code
          ,sec_code
          ,return_type
          ,nitiriu_type
          ,sp_sale_type
          ,shipment
          ,order_date
          ,delivery_date
          ,product_code
          ,product_name
          ,product_name_alt
          ,delivery_quantity
          ,cost_unit_price
          ,cost_price
          ,desc_code
          ,chain_orig_desc
          ,sum_amount
          ,discount_sum_amount
          ,return_sum_amount
          ,org_id
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
        VALUES ( 
           xxcfr_payment_notes_s1.NEXTVAL
          ,gd_process_date
          ,gt_pn_ebs_cust_account_number(ln_loop_cnt)
-- Modify 2009.04.22 Ver1.3 Start
--          ,gt_pn_record_type(ln_loop_cnt)
          ,NULL
-- Modify 2009.04.22 Ver1.3 End
          ,gt_pn_record_number(ln_loop_cnt)
          ,gt_pn_chain_shop_code(ln_loop_cnt)
          ,gt_pn_process_date(ln_loop_cnt)
          ,gt_pn_process_time(ln_loop_cnt)
          ,gt_pn_vendor_code(ln_loop_cnt)
          ,gt_pn_vendor_name(ln_loop_cnt)
          ,gt_pn_vendor_name_alt(ln_loop_cnt)
          ,gt_pn_company_code(ln_loop_cnt)
          ,gt_pn_period_from(ln_loop_cnt)
          ,gt_pn_period_to(ln_loop_cnt)
          ,gt_pn_invoice_close_date(ln_loop_cnt)
          ,gt_pn_payment_date(ln_loop_cnt)
          ,gt_pn_site_month(ln_loop_cnt)
          ,gt_pn_note_count(ln_loop_cnt)
          ,gt_pn_credit_note_count(ln_loop_cnt)
          ,gt_pn_rem_acceptance_count(ln_loop_cnt)
          ,gt_pn_vendor_record_count(ln_loop_cnt)
          ,gt_pn_invoice_number(ln_loop_cnt)
          ,gt_pn_invoice_type(ln_loop_cnt)
          ,gt_pn_payment_type(ln_loop_cnt)
          ,gt_pn_payment_method_type(ln_loop_cnt)
          ,gt_pn_due_type(ln_loop_cnt)
          ,gt_pn_shop_code(ln_loop_cnt)
          ,gt_pn_shop_name(ln_loop_cnt)
          ,gt_pn_shop_name_alt(ln_loop_cnt)
          ,gt_pn_amount_sign(ln_loop_cnt)
          ,gt_pn_amount(ln_loop_cnt)
          ,gt_pn_tax_type(ln_loop_cnt)
-- Modify 2009.04.22 Ver1.3 Start          
--          ,gt_pn_tax_rate(ln_loop_cnt)
          ,gt_pn_tax_rate(ln_loop_cnt) / 100 -- ����ŗ��͏����_�Q������
-- Modify 2009.04.22 Ver1.3 End
          ,gt_pn_tax_amount(ln_loop_cnt)
          ,gt_pn_tax_diff_flag(ln_loop_cnt)
          ,gt_pn_diff_calc_flag(ln_loop_cnt)
          ,gt_pn_match_type(ln_loop_cnt)
          ,gt_pn_unmatch_accoumt_amount(ln_loop_cnt)
          ,gt_pn_double_type(ln_loop_cnt)
          ,gt_pn_acceptance_date(ln_loop_cnt)
          ,gt_pn_max_month(ln_loop_cnt)
          ,gt_pn_note_number(ln_loop_cnt)
          ,gt_pn_line_number(ln_loop_cnt)
          ,gt_pn_note_type(ln_loop_cnt)
          ,gt_pn_class_code(ln_loop_cnt)
          ,gt_pn_div_code(ln_loop_cnt)
          ,gt_pn_sec_code(ln_loop_cnt)
          ,gt_pn_return_type(ln_loop_cnt)
          ,gt_pn_nitiriu_type(ln_loop_cnt)
          ,gt_pn_sp_sale_type(ln_loop_cnt)
          ,gt_pn_shipment(ln_loop_cnt)
          ,gt_pn_order_date(ln_loop_cnt)
          ,gt_pn_delivery_date(ln_loop_cnt)
          ,gt_pn_product_code(ln_loop_cnt)
          ,gt_pn_product_name(ln_loop_cnt)
          ,gt_pn_product_name_alt(ln_loop_cnt)
          ,gt_pn_delivery_quantity(ln_loop_cnt)
          ,gt_pn_cost_unit_price(ln_loop_cnt) / 100  -- �����P���͏����_�Q������
          ,gt_pn_cost_price(ln_loop_cnt)
          ,gt_pn_desc_code(ln_loop_cnt)
          ,gt_pn_chain_orig_desc(ln_loop_cnt)
          ,gt_pn_sum_amount(ln_loop_cnt)
          ,gt_pn_discount_sum_amount(ln_loop_cnt)
          ,gt_pn_return_sum_amount(ln_loop_cnt)
          ,gn_org_id
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
      WHEN OTHERS THEN  -- �X�V���G���[
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a01_019    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �x���ʒm���e�[�u��
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    gn_normal_cnt := SQL%ROWCOUNT;
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
  END insert_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : put_log_error
   * Description      : �ǑփG���[���O�o�͏��� (A-9)
   ***********************************************************************************/
  PROCEDURE put_log_error(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_error'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    --�ǑփG���[���o
    CURSOR payment_note_err_cur
    IS
      SELECT distinct
-- Modify 2009.04.10 Ver1.2 Start
             xpn.chain_shop_code    chain_shop_code,
-- Modify 2009.04.10 Ver1.2 End
             xpn.shop_code          shop_code,
             xpn.shop_name          shop_name
      FROM xxcfr_payment_notes  xpn
      WHERE xpn.request_id                     = cn_request_id  -- �R���J�����g�E�v���O�����̗v��ID
        AND xpn.ebs_cust_account_number        = cv_error_string
-- Modify 2009.04.10 Ver1.2 Start
--      ORDER BY xpn.shop_code
      ORDER BY xpn.chain_shop_code
              ,xpn.shop_code
-- Modify 2009.04.10 Ver1.2 End
    ;
--
    TYPE g_payment_note_err_ttype IS TABLE OF payment_note_err_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_payment_note_err_data    g_payment_note_err_ttype;
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
    -- �J�[�\���I�[�v��
    OPEN payment_note_err_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH payment_note_err_cur BULK COLLECT INTO lt_payment_note_err_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_payment_note_err_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE payment_note_err_cur;
--
    -- �ڋq�R�[�h�ǑփG���[�f�[�^�����O�ɏo�͂���
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(cv_msg_kbn_cfr     -- 'XXCFR'
                                                      ,cv_msg_004a01_015
-- Modify 2009.04.10 Ver1.2 Start
                                                      ,cv_tkn_chcd -- �g�[�N��'CH_TEN_CODE'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).chain_shop_code
                                                        -- �`�F�[���X�R�[�h
-- Modify 2009.04.10 Ver1.2 End                                                      
                                                      ,cv_tkn_tencd -- �g�[�N��'TEN_CODE'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).shop_code
                                                        -- �X�R�[�h
                                                      ,cv_tkn_tennm -- �g�[�N��'TEN_NAME'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).shop_name)
                                                        -- �X�ܖ���
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END LOOP null_data_loop1;
--
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
  END put_log_error;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_filename   IN  VARCHAR2,     --    �x���ʒm�f�[�^�t�@�C����
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_filename           -- �x���ʒm�f�[�^�t�@�C����
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �x���ʒm�f�[�^�t�@�C����񃍃O����(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_004a01_011 -- �t�@�C�����o�̓��b�Z�[�W
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                 ,iv_filename)      -- �t�@�C����
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- =====================================================
    --  �Ɩ��������t�擾���� (A-4)
    -- =====================================================
    get_process_date(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �x���ʒm�e�[�u���f�[�^�폜���� (A-5)
    -- =====================================================
    delete_payment_notes(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �x���ʒm�f�[�^�擾���� (A-6)
    -- =====================================================
    get_payment_notes(
       iv_filename           -- �x���ʒm�f�[�^�t�@�C����
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �ڋq�R�[�h�Ǒ֏��� (A-7)
    -- =====================================================
    convert_cust_code(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �x���ʒm�f�[�^�e�[�u���o�^���� (A-8)
    -- =====================================================
    insert_payment_notes(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �ǑփG���[���O�o�͏��� (A-9)
    -- =====================================================
    put_log_error(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
--
    -- �ǑփG���[������ꍇ�A�x���I��
    IF gn_error_cnt > 0 THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf        OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_filename   IN      VARCHAR2          --    �x���ʒm�f�[�^�t�@�C����
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       iv_filename   -- �x���ʒm�f�[�^�t�@�C����
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --�P�s���s
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
    fnd_file.put_line(
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
END XXCFR004A01C;
/
