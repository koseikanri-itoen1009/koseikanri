CREATE OR REPLACE PACKAGE BODY XXCFR003A12C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A12C
 * Description     : �ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A12_�ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A12_�ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
 * Version         : 1.2
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P         ��������                    (A-1)
 *  get_invoice     P         �������擾����            (A-3)
 *  get_bm_rate     P         BM���E�z�擾����            (A-5)
 *  get_bm          P         BM���z�擾����              (A-6)
 *  ins             P         ���[�N�e�[�u���ǉ�����      (A-7)
 *  put             P         �t�@�C���o�͏���            (A-8)
 *  end_proc        P         �I������                    (A-10)
 *  submain         P         �ėp���i�i�X�P�����W�v�j�����f�[�^�쐬�������s��
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2009-01-30    1.0   SCS ��� �b   ����쐬
 *  2009-02-20    1.1   SCS ��� �b   [��QCFR_009] VD�����z�X�V�s��Ή�
 *  2009-02-20    1.2   SCS ��� �b   [��QCFR_014] VD�ڋq�敪�ɂ��BM���z�o�͐���Ή�
 ************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- ����I��
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --�x��
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --�G���[
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';
  --
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A12C';  -- �p�b�P�[�W��
--
--##############################  �Œ蕔 END   ####################################
--
  --===============================================================
  -- �O���[�o���萔
  --===============================================================
  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- �A�h�I����v AR �̃A�v���P�[�V�����Z�k��
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  ct_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[
  ct_msg_cfr_00010  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00010'; -- ���ʊ֐��G���[���b�Z�[�W
  ct_msg_cfr_00015  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00015'; -- �l�擾�G���[���b�Z�[�W
  ct_msg_cfr_00016  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00016'; -- �e�[�u���}���G���[
  ct_msg_cfr_00024  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00024'; -- �O�����b�Z�[�W
  ct_msg_cfr_00042  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00042'; -- �����P���擾���b�Z�[�W
  ct_msg_cfr_00056  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00056'; -- �V�X�e���G���[���b�Z�[�W
--
  ct_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
  ct_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
  ct_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
  ct_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  ct_msg_ccp_90005  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  ct_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_prof       CONSTANT VARCHAR2(30) := 'PROF_NAME';            -- �v���t�@�C��
  cv_tkn_get_data   CONSTANT VARCHAR2(30) := 'DATA';                 -- �擾�Ώۃf�[�^
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';                -- ��������
  cv_tkn_tab_name   CONSTANT VARCHAR2(30) := 'TABLE';                -- �e�[�u����
  cv_func_name      CONSTANT VARCHAR2(30) := 'FUNC_NAME';            -- ���ʊ֐���
  cv_account_num    CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';       -- �ڋq�R�[�h
  cv_account_name   CONSTANT VARCHAR2(30) := 'ACCOUNT_NAME';         -- �ڋq����
--
  -- �v���t�@�C���I�v�V����
  ct_prof_name_set_of_bks_id  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
                                                                                                    -- ��v����ID
  ct_prof_name_org_id         CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'ORG_ID'; -- �g�DID
--
  -- �Q�ƃ^�C�v
  ct_lookup_type_out          CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET';
                                                                             -- �ėp�����o�͗p�Q�ƃ^�C�v��
  ct_lookup_type_func_name    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_ERR_MSG_TOKEN';
                                                                             -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v��
--
  -- �Q�ƃR�[�h
  ct_lookup_code_func_name    CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFR000A00006';
                                                                             -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v�R�[�h
--
  -- �g�pDB��
  cv_table                    CONSTANT VARCHAR2(50) := 'XXCFR_CSV_OUTS_TEMP'; -- CSV�o�̓��[�N�e�[�u��
--
  -- �������S�Џo�͌�������֐�IN�p���[���[�^�l
  cv_invoice_type             CONSTANT VARCHAR2(1) := 'G';  -- �������^�C�v(G:�ėp������)
--
  -- �������S�Џo�͌�������֐��߂�l
  cv_yes  CONSTANT VARCHAR2(1) := 'Y';  -- �S�Џo�͌�������
  cv_no   CONSTANT VARCHAR2(1) := 'N';  -- �S�Џo�͌����Ȃ�
--
  -- �������S�Џo�͌����ݒ�l
  cv_enable_all   CONSTANT VARCHAR2(1) := '1';  -- �S�Џo�͌�������
  cv_disable_all  CONSTANT VARCHAR2(1) := '0';  -- �S�Џo�͌����Ȃ�
--
  -- ���t�t�H�[�}�b�g
  cv_format_date  CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; 
--
  -- �d����R�[�h�E�_�~�[�l
  ct_sc_bm1       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY1' ; -- BM1�p
  ct_sc_bm2       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY2' ; -- BM2�p
  ct_sc_bm3       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY3' ; -- BM3�p
--
  -- �v�Z����
  ct_calc_type_10 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '10' ; -- 10.�����ʏ���
--
  -- VD�ڋq�敪�l
  cv_is_vd        CONSTANT VARCHAR2(1) := '1';  -- VD�ڋq
  cv_is_not_vd    CONSTANT VARCHAR2(1) := '0';  -- VD�ڋq�ȊO
--
  -- �������o�͌`��
  cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- �ėp������
--
  -- �ꊇ���������s�t���O
  cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y'; -- �L��
--
  -- �\�[�g�L�[����NULL���̒l
  cv_sort_null_value CONSTANT VARCHAR2(1) := '0';
--
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gt_gl_set_of_bks_id       gl_sets_of_books.set_of_books_id%TYPE;     -- �v���t�@�C����v����ID
  gt_org_id                 xxcfr_bill_customers_v.org_id%TYPE;        -- �v���t�@�C���g�DID
  gn_conc_request_id        NUMBER := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
  gt_user_dept_code         per_all_people_f.attribute28%TYPE;         -- ���O�C�����[�U��������R�[�h
  gv_enable_all             VARCHAR2(1) := '0';                        -- �S�ЎQ�ƌ���
  gn_rec_count              PLS_INTEGER := 0;                          -- ���������擾����
  gn_loop_count             PLS_INTEGER := 0;                          -- ��������񃋁[�v��������
--
  gv_upd_bm_flag            VARCHAR2(1) := 'N';                        -- VD�����z�X�V����
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  -- ���������擾�J�[�\��
  CURSOR get_invoice_cur(
    id_target_date DATE,
    iv_ar_code1    VARCHAR2)
  IS
    SELECT ''                                               conc_request_id,          -- �v��ID
           ''                                               sort_num,                 -- �o�͏�
           xih.invoice_id                                   invoice_id,               -- �ꊇ������ID
           xih.itoen_name                                   itoen_name,               -- ����於
           TO_CHAR(xih.inv_creation_date,cv_format_date)    inv_creation_date,        -- �쐬��
           xih.object_month                                 object_month,             -- �Ώ۔N��
           TO_CHAR(xih.object_date_from,cv_format_date)     object_date_from,         -- �Ώۊ���(��)
           TO_CHAR(xih.object_date_to,cv_format_date)       object_date_to,           -- �Ώۊ���(��)
           xih.vender_code                                  vender_code,              -- �����R�[�h
           xih.bill_location_code                           bill_location_code,       -- �����S�����_�R�[�h
           xih.bill_location_name                           bill_location_name,       -- �����S�����_��
           xih.agent_tel_num                                agent_tel_num,            -- �����S�����_�d�b�ԍ�
           xih.credit_cust_code                             credit_cust_code,         -- �^�M��ڋq�R�[�h
           xih.credit_cust_name                             credit_cust_name,         -- �^�M��ڋq��
           xih.receipt_cust_code                            receipt_cust_code,        -- ������ڋq�R�[�h
           xih.receipt_cust_name                            receipt_cust_name,        -- ������ڋq��
           xih.payment_cust_code                            payment_cust_code,        -- ���|�R�[�h�P�i�������j
           xih.payment_cust_name                            payment_cust_name,        -- ���|�R�[�h�P�i�������j����
           xih.bill_cust_code                               bill_cust_code,           -- ������ڋq�R�[�h
           xih.bill_cust_name                               bill_cust_name,           -- ������ڋq��
           xih.credit_receiv_code2                          credit_receiv_code2,      -- ���|�R�[�h�Q�i���Ə��j
           xih.credit_receiv_name2                          credit_receiv_name2,      -- ���|�R�[�h�Q�i���Ə��j����
           xih.credit_receiv_code3                          credit_receiv_code3,      -- ���|�R�[�h�R�i���̑��j
           xih.credit_receiv_name3                          credit_receiv_name3,      -- ���|�R�[�h�R�i���̑��j����
           xil.sold_location_code                           sold_location_code,       -- ���㋒�_�R�[�h
           xil.sold_location_name                           sold_location_name,       -- ���㋒�_��
           xil.ship_cust_code                               ship_cust_code,           -- �[�i��ڋq�R�[�h
           xil.ship_cust_name                               ship_cust_name,           -- �[�i��ڋq��
           xih.bill_shop_code                               bill_shop_code,           -- ������ڋq�XNO
           xih.bill_shop_name                               bill_shop_name,           -- ������ڋq�X��
           xil.ship_shop_code                               ship_shop_code,           -- �[�i��ڋq�XNO
           xil.ship_shop_name                               ship_shop_name,           -- �[�i��ڋq�X��
           DECODE(xil.vd_cust_type,cv_is_vd,xil.vd_num
                 ,NULL)                                     vd_num,                   -- �����̔��@�ԍ�
           NULL                                             delivery_date,            -- �[�i��
           NULL                                             slip_num,                 -- �`�[NO
           NULL                                             order_num,                -- �I�[�_�[NO
           NULL                                             column_num,               -- �R����
           NULL                                             item_code,                -- ���i�R�[�h
           NULL                                             jan_code,                 -- JAN�R�[�h
           NULL                                             item_name,                -- ���i��
           NULL                                             vessel,                   -- �e��
           SUM(xil.quantity)                                quantity,                 -- ����
           xil.unit_price                                   unit_price,               -- ���P��
           DECODE(xil.vd_cust_type,cv_is_vd,xil.unit_price
                 ,NULL)                                     ship_amount,              -- ����
           SUM(xil.sold_amount)                             sold_amount,              -- ���z
           NULL                                             sold_amount_plus,         -- ���z�i���j
           NULL                                             sold_amount_minus,        -- ���z�i�ԁj
           NULL                                             sold_amount_total,        -- ���z�i�v�j
           AVG(xih.inv_amount_includ_tax)                   inv_amount_includ_tax,    -- �ō��������z
           AVG(xih.tax_amount_sum)                          tax_amount_sum,           -- ��������ŋ��z
           NULL                                             bm_unit_price1,           -- BM1�P��
           NULL                                             bm_rate1,                 -- BM1��
           NULL                                             bm_price1,                -- BM1���z
           NULL                                             bm_unit_price2,           -- BM2�P��
           NULL                                             bm_rate2,                 -- BM2��
           NULL                                             bm_price2,                -- BM2���z
           NULL                                             bm_unit_price3,           -- BM3�P��
           NULL                                             bm_rate3,                 -- BM3��
           NULL                                             bm_price3,                -- BM3���z
           NULL                                             vd_amount_claimed,        -- VD�����z
           NULL                                             electric_charges,         -- �d�C��
           NULL                                             slip_type,                -- �`�[�敪
           NULL                                             classify_type,            -- ���ދ敪
           xil.vd_cust_type                                 vd_cust_type              -- VD�ڋq�敪
    FROM xxcfr_invoice_headers xih,
         xxcfr_invoice_lines   xil
    WHERE xih.invoice_id = xil.invoice_id
      AND EXISTS (SELECT 'X'
                  FROM xxcfr_bill_customers_v xbcv
                  WHERE xih.bill_cust_code = xbcv.bill_customer_code
                    AND ((cv_enable_all = gv_enable_all AND
                          xbcv.bill_base_code = xbcv.bill_base_code)
                         OR
                         (cv_disable_all = gv_enable_all AND
                          xbcv.bill_base_code = gt_user_dept_code))
                    AND xbcv.receiv_code1  = iv_ar_code1
                    AND xbcv.inv_prt_type  = cv_inv_prt_type
                    AND xbcv.cons_inv_flag = cv_cons_inv_flag
                    AND xbcv.org_id = gt_org_id
                 )
      AND xih.cutoff_date =id_target_date
      AND xih.set_of_books_id = gt_gl_set_of_bks_id
      AND xih.org_id = gt_org_id
    GROUP BY xih.invoice_id,                                -- �ꊇ������ID
             xih.itoen_name,                                -- ����於
             TO_CHAR(xih.inv_creation_date,cv_format_date), -- �쐬��
             xih.object_month,                              -- �Ώ۔N��
             TO_CHAR(xih.object_date_from,cv_format_date),  -- �Ώۊ���(��)
             TO_CHAR(xih.object_date_to,cv_format_date),    -- �Ώۊ���(��)
             xih.vender_code,                               -- �����R�[�h
             xih.bill_location_code,                        -- �����S�����_�R�[�h
             xih.bill_location_name,                        -- �����S�����_��
             xih.agent_tel_num,                             -- �����S�����_�d�b�ԍ�
             xih.credit_cust_code,                          -- �^�M��ڋq�R�[�h
             xih.credit_cust_name,                          -- �^�M��ڋq��
             xih.receipt_cust_code,                         -- ������ڋq�R�[�h
             xih.receipt_cust_name,                         -- ������ڋq��
             xih.payment_cust_code,                         -- ���|�R�[�h�P�i�������j
             xih.payment_cust_name,                         -- ���|�R�[�h�P�i�������j����
             xih.bill_cust_code,                            -- ������ڋq�R�[�h
             xih.bill_cust_name,                            -- ������ڋq��
             xih.credit_receiv_code2,                       -- ���|�R�[�h�Q�i���Ə��j
             xih.credit_receiv_name2,                       -- ���|�R�[�h�Q�i���Ə��j����
             xih.credit_receiv_code3,                       -- ���|�R�[�h�R�i���̑��j
             xih.credit_receiv_name3,                       -- ���|�R�[�h�R�i���̑��j����
             xil.sold_location_code,                        -- ���㋒�_�R�[�h
             xil.sold_location_name,                        -- ���㋒�_��
             xil.ship_cust_code,                            -- �[�i��ڋq�R�[�h
             xil.ship_cust_name,                            -- �[�i��ڋq��
             xih.bill_shop_code,                            -- ������ڋq�XNO
             xih.bill_shop_name,                            -- ������ڋq�X��
             xil.ship_shop_code,                            -- �[�i��ڋq�XNO
             xil.ship_shop_name,                            -- �[�i��ڋq�X��
             DECODE(xil.vd_cust_type,cv_is_vd,xil.vd_num
                   ,NULL),                                  -- �����̔��@�ԍ�
             xil.unit_price,                                -- ���P��
             DECODE(xil.vd_cust_type,cv_is_vd,xil.unit_price
                   ,NULL),                                  -- ����
             xil.vd_cust_type                               -- VD�ڋq�敪
    ORDER BY NVL(xih.bill_shop_code,cv_sort_null_value),    -- ������ڋq�XNO
             xih.bill_cust_code,                            -- ������ڋq�R�[�h
             NVL(xil.ship_shop_code,cv_sort_null_value),    -- �[�i��ڋq�XNO
             xil.ship_cust_code,                            -- �[�i��ڋq�R�[�h
             xil.unit_price                                 -- �P��
    ;
--
  --===============================================================
  -- �O���[�o���^�C�v
  --===============================================================
  TYPE inv_tab_ttype      IS TABLE OF get_invoice_cur%ROWTYPE INDEX BY PLS_INTEGER;       -- �������擾
  TYPE csv_outs_tab_ttype IS TABLE OF xxcfr_csv_outs_temp%ROWTYPE INDEX BY PLS_INTEGER;   -- ���[�N�e�[�u�����i�[
--
  gt_inv_tab              inv_tab_ttype;                              -- �P�����������
  gt_csv_outs_tab         csv_outs_tab_ttype;                         -- ���[�N�e�[�u���������
--
  --===============================================================
  -- �O���[�o����O
  --===============================================================
  global_process_expt       EXCEPTION; -- �֐���O
  global_api_expt           EXCEPTION; -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION; -- ���ʊ֐�OTHERS��O
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);  -- ���ʊ֐���O(ORA-20000)��global_api_others_expt���}�b�s���O
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';          -- �p�����[�^�o�͊֐� ���O�o�͎���iv_which�l
    cv_output          CONSTANT VARCHAR2(10)  := 'OUTPUT';       -- �p�����[�^�o�͊֐� ���|�[�g�o�͎���iv_which�l
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- �]�ƈ��}�X�^DFF��
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- �]�ƈ��}�X�^DFF28(��������)�J������
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
    lv_enabled_flag VARCHAR2(1); 
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; --��������擾�G���[���̃��b�Z�[�W�g�[�N���l
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
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
    -- �R���J�����g�p�����[�^���O�o��
    xxcfr_common_pkg.put_log_param(iv_which       => cv_log,         -- ���O�o��
                                   iv_conc_param1 => iv_target_date, -- �R���J�����g�p�����[�^�P
                                   iv_conc_param2 => iv_ar_code1,    -- �R���J�����g�p�����[�^�Q
                                   ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W
                                   ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h
                                   ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- �v���t�@�C����v����擾
    gt_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(ct_prof_name_set_of_bks_id));
    --
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF (gt_gl_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
                                                    ,ct_msg_cfr_00004  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(ct_prof_name_set_of_bks_id))
                                                       -- ��v����ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
    --
    -- �v���t�@�C���c�ƒP�ʎ擾
    gt_org_id := TO_NUMBER(FND_PROFILE.VALUE(ct_prof_name_org_id));
    --
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF (gt_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
                                                    ,ct_msg_cfr_00004  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(ct_prof_name_org_id))
                                                       -- �g�DID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
    --
    -- ��������R�[�h�擾
    gt_user_dept_code := xxcfr_common_pkg.get_user_dept(in_user_id  => FND_GLOBAL.USER_ID,
                                                        id_get_date => SYSDATE
                                                       );
    IF (gt_user_dept_code IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
    --
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �������傪�擾�ł��Ȃ��ꍇ ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
          AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00015,
                                            iv_token_name1  => cv_tkn_get_data,
                                            iv_token_value1 => lv_token_value);
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_rate
   * Description      : BM���E�z�擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm_rate(
    id_target_date        IN  DATE,     -- ����
    iv_delivery_cust_code IN  VARCHAR2, -- �[�i��ڋq�R�[�h
    iv_delivery_cust_name IN  VARCHAR2, -- �[�i��ڋq��
    in_unit_price         IN  NUMBER,   -- ���P��
    ov_get_bm_flag        OUT VARCHAR2, -- BM���z�擾�t���O
    ov_get_bm_price       OUT VARCHAR2, -- ���E�z�擾�t���O
    ov_errbuf             OUT VARCHAR2,
    ov_retcode            OUT VARCHAR2,
    ov_errmsg             OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_rate';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    --
    --===============================================================
    -- ���[�J���J�[�\��
    --===============================================================
    -- ���E�z�擾�J�[�\��
    CURSOR get_bm_rate_cur
    IS
      SELECT xcbs1.rebate_rate    bm1_rate,    -- BM1��
             xcbs1.rebate_amt     bm1_amt,     -- BM1�P��
             xcbs2.rebate_rate    bm2_rate,    -- BM2��
             xcbs2.rebate_amt     bm2_amt,     -- BM2�P��
             xcbs3.rebate_rate    bm3_rate,    -- BM3��
             xcbs3.rebate_amt     bm3_amt      -- BM3�P��
      FROM   (SELECT DISTINCT
                      x1.selling_amt_tax, -- ���ߗ�
                      x1.rebate_rate,     -- ���ߊz
                      x1.rebate_amt       -- ������z(�ō�)
              FROM    xxcok_cond_bm_support x1 -- �����ʔ̎�̋��e�[�u��1
              WHERE   x1.delivery_cust_code = iv_delivery_cust_code  -- �[�i��ڋq�R�[�h
                AND   x1.closing_date       = id_target_date         -- ����
                AND   x1.calc_type          = ct_calc_type_10        -- �v�Z����
                AND   x1.supplier_code      = ct_sc_bm1              -- �d����R�[�h
                AND   x1.selling_amt_tax    = in_unit_price) xcbs1,  -- �P��
              (SELECT DISTINCT
                      x2.selling_amt_tax,  -- ���ߗ�
                      x2.rebate_rate,      -- ���ߊz
                      x2.rebate_amt        -- ������z(�ō�)
              FROM    xxcok_cond_bm_support x2 -- �����ʔ̎�̋��e�[�u��2
              WHERE   x2.delivery_cust_code = iv_delivery_cust_code  -- �[�i��ڋq�R�[�h
                AND   x2.closing_date       = id_target_date         -- ����
                AND   x2.calc_type          = ct_calc_type_10        -- �v�Z����
                AND   x2.supplier_code      = ct_sc_bm2              -- �d����R�[�h
                AND   x2.selling_amt_tax    = in_unit_price) xcbs2,  -- �P��
              (SELECT DISTINCT
                      x3.selling_amt_tax,  -- ���ߗ�
                      x3.rebate_rate,      -- ���ߊz
                      x3.rebate_amt        -- ������z(�ō�)
              FROM    xxcok_cond_bm_support x3 -- �����ʔ̎�̋��e�[�u��3
              WHERE   x3.delivery_cust_code = iv_delivery_cust_code  -- �[�i��ڋq�R�[�h
                AND   x3.closing_date       = id_target_date         -- ����
                AND   x3.calc_type          = ct_calc_type_10        -- �v�Z����
                AND   x3.supplier_code      = ct_sc_bm3              -- �d����R�[�h
                AND   x3.selling_amt_tax    = in_unit_price) xcbs3   -- �P��
      WHERE   xcbs1.selling_amt_tax   = xcbs2.selling_amt_tax(+)
        AND   xcbs1.selling_amt_tax   = xcbs3.selling_amt_tax(+);
      --
     get_bm_rate_rec   get_bm_rate_cur%ROWTYPE;
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_cnt      NUMBER := 0 ;        -- ���R�[�h�����J�E���g
    lv_msg_out  VARCHAR2(1) := 'N';  -- �����P���擾���b�Z�[�W�o�͔���
    --
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode      := cv_status_normal;
    ov_get_bm_flag  := 'N';
    ov_get_bm_price := 'Y';
--
--###########################  �Œ蕔 END   ############################
--
    --
    <<get_bm_loop>>
    FOR get_bm_rate_rec IN get_bm_rate_cur
      LOOP
        ov_get_bm_flag := 'Y';    -- BM���z�擾�t���O��'Y'
        ln_cnt := ln_cnt + 1;     -- �J�E���g���C���N�������g
--
        ov_get_bm_price := 'Y';   -- ����z�擾�t���O��'Y'�ɐݒ�
--
        -- ���E�z�Ƃ��ɒl������ꍇ�͗���z�擾�t���O��'N'�ɐݒ�
        IF (get_bm_rate_rec.bm1_rate IS NOT NULL AND get_bm_rate_rec.bm1_amt IS NOT NULL) THEN
          ov_get_bm_price := 'N';
        END IF;
        -- 2���ڈȍ~�̏ꍇ�A����z�擾�t���O��'N'�ɐݒ�
        IF (ln_cnt > 1)  THEN
          ov_get_bm_price := 'N';
        END IF;
--
        IF (ov_get_bm_price = 'N')  THEN
          -- �����P���擾���b�Z�[�W�̏o��
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                                     iv_name         => ct_msg_cfr_00042,
                                                     iv_token_name1  => cv_account_num,
                                                     iv_token_value1 => iv_delivery_cust_code, -- �[�i��ڋq�R�[�h
                                                     iv_token_name2  => cv_account_name,
                                                     iv_token_value2 => iv_delivery_cust_name) -- �[�i��ڋq��
                           );
          --
          -- LOOP���I��
          EXIT;
          --
        END IF;
        --
      --
      END LOOP get_bm_loop;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END get_bm_rate;
  --
  /**********************************************************************************
   * Procedure Name   : get_bm
   * Description      : BM���z�擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_bm(
    id_target_date        IN  DATE,     -- ����
    in_num                IN  NUMBER,   -- ���R�[�h����
    iv_delivery_cust_code IN  VARCHAR2, -- �[�i��ڋq�R�[�h
    in_unit_price         IN  NUMBER,   -- ���P��
    iv_get_bm_price       IN  VARCHAR2, -- ���z�擾����
    ov_errbuf             OUT VARCHAR2,
    ov_retcode            OUT VARCHAR2,
    ov_errmsg             OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    --
    --===============================================================
    -- ���[�J���J�[�\��
    --===============================================================
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_cnt   NUMBER := 0 ; -- ���R�[�h�����J�E���g
    --
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode      := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- BM�z�̎擾
    SELECT AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_rate
                    ,NULL)
           ) bm1_rate,                                                 -- BM1��
           AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_amt
                    ,NULL)
           ) bm1_amt,                                                  -- BM1�z
           SUM(DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.cond_bm_amt_tax
                    ,NULL)
            ) bm1_all,                                                 -- BM1���z
           AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_rate
                    ,NULL)
           ) bm2_rate,                                                 -- BM2��
           AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_amt
                    ,NULL)
           ) bm2_amt,                                                  -- BM2�z
           SUM(DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.cond_bm_amt_tax
                   ,NULL)
            ) bm2_all,                                                 -- BM2���z
           AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_rate
                    ,NULL)
           ) bm3_rate,                                                 -- BM3��
           AVG(
             DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_amt
                    ,NULL)
           ) bm3_amt,                                                  -- BM3�z
           SUM(DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.cond_bm_amt_tax
                     ,NULL)
           ) bm3_all                                                   -- BM3���z
    INTO   gt_inv_tab(in_num).bm_rate1,
           gt_inv_tab(in_num).bm_unit_price1,
           gt_inv_tab(in_num).bm_price1,
           gt_inv_tab(in_num).bm_rate2,
           gt_inv_tab(in_num).bm_unit_price2,
           gt_inv_tab(in_num).bm_price2,
           gt_inv_tab(in_num).bm_rate3,
           gt_inv_tab(in_num).bm_unit_price3,
           gt_inv_tab(in_num).bm_price3
    FROM   xxcok_cond_bm_support xcbs                        -- �����ʔ̎�̋��e�[�u��
    WHERE   xcbs.delivery_cust_code = iv_delivery_cust_code  -- �[�i��ڋq�R�[�h
      AND xcbs.closing_date     = id_target_date             -- ����
      AND xcbs.calc_type        = ct_calc_type_10            -- �v�Z����
      AND xcbs.selling_amt_tax  = in_unit_price              -- ������z(�ō�)
    ;
    -- BM�o�͂��s��Ȃ��ꍇ�ABM���EBM�P����NULL��ݒ�
    IF (iv_get_bm_price = 'N') THEN
      gt_inv_tab(in_num).bm_rate1       := NULL;
      gt_inv_tab(in_num).bm_unit_price1 := NULL;
      gt_inv_tab(in_num).bm_rate2       := NULL;
      gt_inv_tab(in_num).bm_unit_price2 := NULL;
      gt_inv_tab(in_num).bm_rate3       := NULL;
      gt_inv_tab(in_num).bm_unit_price3 := NULL;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table)
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END get_bm;
  --
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : �������擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_invoice(
    id_target_date   IN  DATE,        -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    --===============================================================
    -- ���[�J���萔
    --===============================================================
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
    lv_bill_customer_code_1   VARCHAR2(20);   -- �ڋq�u���C�N���ʁE�J�����g���R�[�h�p
    lv_bill_customer_code_2   VARCHAR2(20);   -- �ڋq�u���C�N���ʁE��r�p
    ln_bill_cust_start        NUMBER := 1;    -- �u���C�N�J�n���R�[�h
    ln_bm_price               NUMBER := 0;    -- BM���z
    lv_get_bm_flag            VARCHAR2(1);    -- BM�擾����
    lv_get_bm_price           VARCHAR2(1);    -- ���E�z�擾����
    ln_i                      NUMBER := 0;    -- ���[�v�J�E���^
    --
    --===============================================================
    -- ���[�J���J�[�\��
    --===============================================================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ��������������
    gn_rec_count := 0;
    --
    OPEN get_invoice_cur(id_target_date,iv_ar_code1);
    --
      -- �R���N�V�����ϐ��ɑ��
      FETCH get_invoice_cur BULK COLLECT INTO gt_inv_tab;
      --
      -- �f�[�^�����擾
      --
      gn_rec_count  := gt_inv_tab.COUNT;
      gn_loop_count := gn_rec_count + 1;
      --
    CLOSE get_invoice_cur;
    --
    --
    IF gn_rec_count > 0 THEN
      <<invoice_loop>>
      FOR i IN 1..gn_loop_count LOOP
      --
        -- �O���R�[�h�Ɛ�����ڋq���قȂ�ꍇ
      --===============================================================
      -- A-4�DVD�����z�Z�o�X�V����
      --===============================================================
        IF (i > 1) THEN
        --
          -- �Ō�̍s�̓_�~�[�l����
          --
          IF (i = gn_loop_count) THEN
            lv_bill_customer_code_1 := 'ZZZ' ;
          ELSE
            lv_bill_customer_code_1 := gt_inv_tab(i).bill_cust_code;
          END IF;
          --
          -- ������ڋq���قȂ�ꍇ
          --
          IF (lv_bill_customer_code_1 != lv_bill_customer_code_2) THEN
          --
            -- VD�����z�X�V���ʃt���O��'Y'�ł���ꍇ
            IF (gv_upd_bm_flag = 'Y') THEN
              -- ���[�v�ő�l���擾
              ln_i := i - 1;
              --
              -- VD�����z���Y���̐�����ڋq�ɑ΂��čX�V
              FOR i2 IN ln_bill_cust_start..ln_i LOOP
              --
                gt_inv_tab(i2).vd_amount_claimed := gt_inv_tab(i2).inv_amount_includ_tax - ln_bm_price;
                --
                -- �o�͕ϐ��֑��
                gt_csv_outs_tab(i2).col57         := gt_inv_tab(i2).vd_amount_claimed;
                --
              END LOOP;
            END IF;
            --
            -- �ŏI�����̏ꍇ�̓��[�v(invoice_loop)�𔲂���
            IF (i = gn_loop_count) THEN
              EXIT;
            END IF;
            --
            -- BM���v���z�̏�����
            ln_bm_price := 0;
            ln_bill_cust_start := i ;
            -- VD�����z�X�V���ʃt���O�̏�����
            gv_upd_bm_flag := 'N';
            --
          END IF;
        END IF;
        --
      --===============================================================
      -- A-8�D�u���C�N�ϐ��̐ݒ�
      --===============================================================
        -- ������ڋq�R�[�h�̎擾�E�u���C�N���ʗp
        lv_bill_customer_code_2 := gt_inv_tab(i).bill_cust_code ;
        --
        -- �l���
        gt_inv_tab(i).conc_request_id := gn_conc_request_id;    -- �v��ID
        gt_inv_tab(i).sort_num        := i;                     -- �\�[�g��
        --
        -- VD�ڋq�敪���u1:VD�ڋq�v�ł���ꍇ
        IF gt_inv_tab(i).vd_cust_type = cv_is_vd THEN
        --===============================================================
        -- A-5�DBM���E�z�擾����
        --===============================================================
          get_bm_rate(id_target_date        => id_target_date,               -- ����
                      iv_delivery_cust_code => gt_inv_tab(i).ship_cust_code, -- �[�i��ڋq�R�[�h
                      iv_delivery_cust_name => gt_inv_tab(i).ship_cust_name, -- �[�i��ڋq��
                      in_unit_price         => gt_inv_tab(i).unit_price,     -- ���P��
                      ov_get_bm_flag        => lv_get_bm_flag,               -- BM�擾�t���O
                      ov_get_bm_price       => lv_get_bm_price,              -- ���E�z�擾�t���O
                      ov_errbuf             => lv_errbuf,
                      ov_retcode            => lv_retcode,
                      ov_errmsg             => lv_errmsg);
          --
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          IF gv_upd_bm_flag = 'N' THEN
            -- VD�����z�X�V���ʃt���O�ɒl��ݒ�
            gv_upd_bm_flag := lv_get_bm_flag;
          END IF;
--
          -- BM�擾�t���O��'Y' 
          IF (lv_get_bm_flag = 'Y') THEN  
          --
          --===============================================================
          -- A-6�DBM���z�擾����
          --===============================================================
            get_bm(id_target_date        => id_target_date,               -- ����
                   in_num                => i,                            -- ���R�[�h����
                   iv_delivery_cust_code => gt_inv_tab(i).ship_cust_code, -- �[�i��ڋq�R�[�h
                   in_unit_price         => gt_inv_tab(i).unit_price,     -- ���P��
                   iv_get_bm_price       => lv_get_bm_price,              -- ���z�擾����
                   ov_errbuf             => lv_errbuf,
                   ov_retcode            => lv_retcode,
                   ov_errmsg             => lv_errmsg
                  );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
            --
          END IF;
--
        END IF;
        --
        -- ���[�N�e�[�u�������ϐ��֑��
        --
        gt_csv_outs_tab(i).request_id  := gt_inv_tab(i).conc_request_id;       -- �v��ID
        gt_csv_outs_tab(i).seq         := gt_inv_tab(i).sort_num;              -- �o�͏�
        gt_csv_outs_tab(i).col1        := gt_inv_tab(i).itoen_name;            -- ����於
        gt_csv_outs_tab(i).col2        := gt_inv_tab(i).inv_creation_date;     -- �쐬��
        gt_csv_outs_tab(i).col3        := gt_inv_tab(i).object_month;          -- �Ώ۔N��
        gt_csv_outs_tab(i).col4        := gt_inv_tab(i).object_date_from;      -- �Ώۊ���(��)
        gt_csv_outs_tab(i).col5        := gt_inv_tab(i).object_date_to;        -- �Ώۊ���(��)
        gt_csv_outs_tab(i).col6        := gt_inv_tab(i).vender_code;           -- �����R�[�h
        gt_csv_outs_tab(i).col7        := gt_inv_tab(i).bill_location_code;    -- �����S�����_�R�[�h
        gt_csv_outs_tab(i).col8        := gt_inv_tab(i).bill_location_name;    -- �����S�����_��
        gt_csv_outs_tab(i).col9        := gt_inv_tab(i).agent_tel_num;         -- �����S�����_�d�b�ԍ�
        gt_csv_outs_tab(i).col10       := gt_inv_tab(i).credit_cust_code;      -- �^�M��ڋq�R�[�h
        gt_csv_outs_tab(i).col11       := gt_inv_tab(i).credit_cust_name;      -- �^�M��ڋq��
        gt_csv_outs_tab(i).col12       := gt_inv_tab(i).receipt_cust_code;     -- ������ڋq�R�[�h
        gt_csv_outs_tab(i).col13       := gt_inv_tab(i).receipt_cust_name;     -- ������ڋq��
        gt_csv_outs_tab(i).col14       := gt_inv_tab(i).payment_cust_code;     -- ���|�R�[�h�P�i�������j
        gt_csv_outs_tab(i).col15       := gt_inv_tab(i).payment_cust_name;     -- ���|�R�[�h�P�i�������j����
        gt_csv_outs_tab(i).col16       := gt_inv_tab(i).bill_cust_code;        -- ������ڋq�R�[�h
        gt_csv_outs_tab(i).col17       := gt_inv_tab(i).bill_cust_name;        -- ������ڋq��
        gt_csv_outs_tab(i).col18       := gt_inv_tab(i).credit_receiv_code2;   -- ���|�R�[�h�Q�i���Ə��j
        gt_csv_outs_tab(i).col19       := gt_inv_tab(i).credit_receiv_name2;   -- ���|�R�[�h�Q�i���Ə��j����
        gt_csv_outs_tab(i).col20       := gt_inv_tab(i).credit_receiv_code3;   -- ���|�R�[�h�R�i���̑��j
        gt_csv_outs_tab(i).col21       := gt_inv_tab(i).credit_receiv_name3;   -- ���|�R�[�h�R�i���̑��j����
        gt_csv_outs_tab(i).col22       := gt_inv_tab(i).sold_location_code;    -- ���㋒�_�R�[�h
        gt_csv_outs_tab(i).col23       := gt_inv_tab(i).sold_location_name;    -- ���㋒�_��
        gt_csv_outs_tab(i).col24       := gt_inv_tab(i).ship_cust_code;        -- �[�i��ڋq�R�[�h
        gt_csv_outs_tab(i).col25       := gt_inv_tab(i).ship_cust_name;        -- �[�i��ڋq��
        gt_csv_outs_tab(i).col26       := gt_inv_tab(i).bill_shop_code;        -- ������ڋq�XNO
        gt_csv_outs_tab(i).col27       := gt_inv_tab(i).bill_shop_name;        -- ������ڋq�X��
        gt_csv_outs_tab(i).col28       := gt_inv_tab(i).ship_shop_code;        -- �[�i��ڋq�XNO
        gt_csv_outs_tab(i).col29       := gt_inv_tab(i).ship_shop_name;        -- �[�i��ڋq�X��
        gt_csv_outs_tab(i).col30       := gt_inv_tab(i).vd_num;                -- �����̔��@�ԍ�
        gt_csv_outs_tab(i).col31       := gt_inv_tab(i).delivery_date;         -- �[�i��
        gt_csv_outs_tab(i).col32       := gt_inv_tab(i).slip_num;              -- �`�[NO
        gt_csv_outs_tab(i).col33       := gt_inv_tab(i).order_num;             -- �I�[�_�[NO
        gt_csv_outs_tab(i).col34       := gt_inv_tab(i).column_num;            -- �R����
        gt_csv_outs_tab(i).col35       := gt_inv_tab(i).item_code;             -- ���i�R�[�h
        gt_csv_outs_tab(i).col36       := gt_inv_tab(i).jan_code;              -- JAN�R�[�h
        gt_csv_outs_tab(i).col37       := gt_inv_tab(i).item_name;             -- ���i��
        gt_csv_outs_tab(i).col38       := gt_inv_tab(i).vessel;                -- �e��
        gt_csv_outs_tab(i).col39       := gt_inv_tab(i).quantity;              -- ����
        gt_csv_outs_tab(i).col40       := gt_inv_tab(i).unit_price;            -- ���P��
        gt_csv_outs_tab(i).col41       := gt_inv_tab(i).ship_amount;           -- ����
        gt_csv_outs_tab(i).col42       := gt_inv_tab(i).sold_amount;           -- ���z
        gt_csv_outs_tab(i).col43       := gt_inv_tab(i).sold_amount_plus;      -- ���z�i���j
        gt_csv_outs_tab(i).col44       := gt_inv_tab(i).sold_amount_minus;     -- ���z�i�ԁj
        gt_csv_outs_tab(i).col45       := gt_inv_tab(i).sold_amount_total;     -- ���z�i�v�j
        gt_csv_outs_tab(i).col46       := gt_inv_tab(i).inv_amount_includ_tax; -- �ō��������z
        gt_csv_outs_tab(i).col47       := gt_inv_tab(i).tax_amount_sum;        -- ��������ŋ��z
        gt_csv_outs_tab(i).col48       := gt_inv_tab(i).bm_unit_price1;        -- BM1�P��
        gt_csv_outs_tab(i).col49       := gt_inv_tab(i).bm_rate1;              -- BM1��
        gt_csv_outs_tab(i).col50       := gt_inv_tab(i).bm_price1;             -- BM1���z
        gt_csv_outs_tab(i).col51       := gt_inv_tab(i).bm_unit_price2;        -- BM2�P��
        gt_csv_outs_tab(i).col52       := gt_inv_tab(i).bm_rate2;              -- BM2��
        gt_csv_outs_tab(i).col53       := gt_inv_tab(i).bm_price2;             -- BM2���z
        gt_csv_outs_tab(i).col54       := gt_inv_tab(i).bm_unit_price3;        -- BM3�P��
        gt_csv_outs_tab(i).col55       := gt_inv_tab(i).bm_rate3;              -- BM3��
        gt_csv_outs_tab(i).col56       := gt_inv_tab(i).bm_price3;             -- BM3���z
        gt_csv_outs_tab(i).col57       := gt_inv_tab(i).vd_amount_claimed;     -- VD�����z
        gt_csv_outs_tab(i).col58       := gt_inv_tab(i).electric_charges;      -- �d�C��
        gt_csv_outs_tab(i).col59       := gt_inv_tab(i).slip_type;             -- �`�[�敪
        gt_csv_outs_tab(i).col60       := gt_inv_tab(i).classify_type;         -- ���ދ敪
        --
        -- BM���z�����Z
        ln_bm_price := ln_bm_price + NVL(gt_inv_tab(i).bm_price1,0) ;
        --
      END LOOP invoice_loop;
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
  END get_invoice;
  /**********************************************************************************
   * Procedure Name   : ins
   * Description      : ���[�N�e�[�u���ǉ�����(A-7)
   ***********************************************************************************/
  PROCEDURE ins(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
  --
    FORALL i IN 1..gn_rec_count
    --
      INSERT INTO xxcfr_csv_outs_temp VALUES gt_csv_outs_tab(i);
      --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table)
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
      --
  END ins;
  --
  /**********************************************************************************
   * Procedure Name   : put
   * Description      : �t�@�C���o�͏���(A-8)
   ***********************************************************************************/
  PROCEDURE put(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
    --===============================================================
    -- ���[�J���萔
    --===============================================================
    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
    lv_func_name fnd_lookup_values.description%TYPE;  -- �ėp�����o�͏������ʊ֐���
    
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�t�@�C���o�͏������s
    xxcfr_common_pkg.csv_out(in_request_id  => FND_GLOBAL.CONC_REQUEST_ID,
                             iv_lookup_type => ct_lookup_type_out,
                             in_rec_cnt     => gn_rec_count,
                             ov_retcode     => lv_retcode,
                             ov_errbuf      => lv_errbuf,
                             ov_errmsg      => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      BEGIN
        SELECT flvv.description description
        INTO lv_func_name
        FROM fnd_lookup_values_vl flvv
        WHERE flvv.lookup_type = ct_lookup_type_func_name
          AND flvv.lookup_code = ct_lookup_code_func_name
          AND flvv.enabled_flag = cv_yes
          AND SYSDATE BETWEEN flvv.start_date_active AND flvv.end_date_active;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00010, -- ���ʊ֐��G���[���b�Z�[�W
                                            iv_token_name1  => cv_func_name,
                                            iv_token_value1 => lv_func_name);
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END put;
  
  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : �I������(A-10)
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,  -- �����X�e�[�^�X
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    -- �Ώۃf�[�^0���x�����b�Z�[�W�o��
    IF (iv_retcode = cv_status_warn) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                     iv_name        => ct_msg_cfr_00024
                                                    )
                           );
    END IF;
    -- �����o��
    -- ����܂��͌x���I���̏ꍇ
    IF ((iv_retcode = cv_status_normal) OR (iv_retcode = cv_status_warn)) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90000,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90001,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90002,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
    -- �G���[�I���̏ꍇ
    ELSIF (iv_retcode = cv_status_error) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90000,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90001,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application  => cv_xxccp_app_name,
                                                 iv_name         => ct_msg_ccp_90002,
                                                 iv_token_name1  => cv_tkn_count,
                                                 iv_token_value1 => 1
                                                )
                       );
      -- �G���[�����݂��Ȃ��ꍇ
    END IF;
    -- �I�����b�Z�[�W�o��
    -- �G���[�����݂���ꍇ
    IF (iv_retcode = cv_status_error) THEN
      -- �G���[�I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name        => ct_msg_ccp_90006
                                                )
                       );
    -- �Ώۃf�[�^0���̏ꍇ(�x���I��)
    ELSIF (iv_retcode = cv_status_warn) THEN
      -- �x���I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name        => ct_msg_ccp_90005
                                                )
                       );
    -- ����I���̏ꍇ
    ELSE
      -- ����I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name        => ct_msg_ccp_90004
                                                )
                       );
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;
  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �ėp���i�i�X�P�����W�v�j�����f�[�^�쐬�������s��
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --===============================================================
    -- A-1�D��������
    --===============================================================
    init(iv_target_date,  -- ����
         iv_ar_code1,     -- ���|�R�[�h�P(������)
         lv_errbuf,
         lv_retcode,
         lv_errmsg
        );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-2�D�o�̓Z�L�����e�B����
    --===============================================================
    gv_enable_all := xxcfr_common_pkg.chk_invoice_all_dept(iv_user_dept_code => gt_user_dept_code,
                                                           iv_invoice_type   => cv_invoice_type
                                                          );
    IF (gv_enable_all = cv_yes) THEN
      gv_enable_all := cv_enable_all;
    ELSE
      gv_enable_all := cv_disable_all;
    END IF;
    --
    --===============================================================
    -- A-3�D�������擾����
    --===============================================================
    get_invoice(xxcfr_common_pkg.get_date_param_trans(iv_target_date),  -- ����
                iv_ar_code1,                                            -- ���|�R�[�h�P(������)
                lv_errbuf,
                lv_retcode,
                lv_errmsg
               );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-7�D���[�N�e�[�u���ǉ�����
    --===============================================================
    ins(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --===============================================================
    -- A-8�D�t�@�C���o�͏���
    --===============================================================
    put(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    -- ��������0�̏ꍇ�x���I��
    IF (gn_rec_count = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
    
  EXCEPTION
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;
  
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
  ) IS
    
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_put_log_which CONSTANT VARCHAR2(10) := 'LOG';  -- ���O�w�b�_�o�͊֐�iv_which�p�����[�^
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
    
  BEGIN
    
    xxccp_common_pkg.put_log_header(iv_which   => cv_put_log_which,
                                    ov_retcode => lv_retcode,
                                    ov_errbuf  => lv_errbuf,
                                    ov_errmsg  => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    submain(iv_target_date,
            iv_ar_code1,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfr_app_name
                     ,iv_name         => ct_msg_cfr_00056
                   )
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    -- �X�e�[�^�X���Z�b�g
    retcode := lv_retcode;
    --===============================================================
    -- A-10�D�I������
    --===============================================================
    end_proc(retcode,
             lv_errbuf,
             lv_retcode,
             lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** �T�u�v���O�����G���[������ ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
END  XXCFR003A12C;
/
