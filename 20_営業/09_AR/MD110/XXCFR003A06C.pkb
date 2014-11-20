create or replace PACKAGE BODY XXCFR003A06C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A06C
 * Description     : �ėp�X�ʐ����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * Version         : 1.1
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P         ��������
 *  get_invoice     P         �������擾����
 *  chk_bm          P         �̎�����̎擾
 *  get_bm          P         �̔��萔���E�d�C��̎擾
 *  ins             P         �t�@�C���o�͏���
 *  put             P         �t�@�C���o�͏���
 *  end_proc        P         �I������
 *  submain         P         �ėp�X�ʐ����f�[�^�쐬�������s��
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-19    1.0  SCS �g�� ���i  ����쐬
 *  2009-02-20    1.1  SCS ��� �b    [��QCFR_009] VD�����z�X�V�s��Ή�
 *  2009-04-13    1.2  SCS ���� �L��  T1_0129 BM���z�擾�s�Ή�
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A06C';  -- �p�b�P�[�W��
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
  ct_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004';
  ct_msg_cfr_00010  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00010';
  ct_msg_cfr_00015  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00015';
  ct_msg_cfr_00016  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00016';
  ct_msg_cfr_00024  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00024';
  ct_msg_cfr_00037  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00037';
  ct_msg_cfr_00056  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00056';
  --
  ct_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  ct_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  ct_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  ct_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  ct_msg_ccp_90005  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90005';
  ct_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  --
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_prof       CONSTANT VARCHAR2(30) := 'PROF_NAME';            -- �v���t�@�C��
  cv_tkn_get_data   CONSTANT VARCHAR2(30) := 'DATA';                 -- �擾�Ώۃf�[�^
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';                -- ��������
  cv_tkn_tab_name   CONSTANT VARCHAR2(30) := 'TABLE';                -- �e�[�u����
  cv_func_name      CONSTANT VARCHAR2(30) := 'FUNC_NAME';            -- ���ʊ֐���
  --
  -- �v���t�@�C���I�v�V����
  ct_prof_name_set_of_bks_id  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
  ct_prof_name_org_id         CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'ORG_ID';
  --
  -- �Q�ƃ^�C�v
  ct_lookup_type_out          CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET';  -- �ėp�����o�͗p�Q�ƃ^�C�v��
  ct_lookup_type_func_name    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_ERR_MSG_TOKEN';         -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v��
  --
  -- �Q�ƃR�[�h
  ct_lookup_code_func_name    CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFR000A00006';                 -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v�R�[�h
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
  -- VD�ڋq�敪
  cv_vd_cust_type CONSTANT VARCHAR2(1) := '1'; -- VD
  --
  -- �d����R�[�h�E�_�~�[�l
  ct_sc_bm1       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY1' ; -- BM1�p
  ct_sc_bm2       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY2' ; -- BM2�p
  ct_sc_bm3       CONSTANT xxcok_cond_bm_support.supplier_code%TYPE := 'FLVDDMY3' ; -- BM3�p
  --
  -- �v�Z����
  ct_calc_type_10 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '10' ; -- 10.�����ʏ���
  ct_calc_type_20 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '20' ; -- 20.�e��敪�ʏ���
  ct_calc_type_30 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '30' ; -- 30.�藦����
  ct_calc_type_40 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '40' ; -- 40.��z����
  ct_calc_type_50 CONSTANT xxcok_cond_bm_support.calc_type%TYPE := '50' ; -- 50.�d�C��
  --
  -- VD�ڋq�敪�l
  cv_is_vd        CONSTANT VARCHAR2(1) := '1';  -- VD�ڋq
  cv_is_not_vd    CONSTANT VARCHAR2(1) := '0';  -- VD�ڋq�ȊO
  --
  -- �������o�͌`��
  cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- �ėp������
  --
  -- �ꊇ���������s�t���O
  cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y';  -- �L��
  --
  -- �\�[�g�L�[����NULL���̒l
  cv_sort_null_value CONSTANT VARCHAR2(1) := '0';
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gt_gl_set_of_bks_id       gl_sets_of_books.set_of_books_id%TYPE;     -- �v���t�@�C����v����ID
  gt_org_id                 xxcfr_bill_customers_v.org_id%TYPE;        -- �v���t�@�C���g�DID
  gn_conc_request_id        NUMBER 
                              := FND_GLOBAL.CONC_REQUEST_ID;           -- �v��ID
  gt_user_dept_code         per_all_people_f.attribute28%TYPE;         -- ���O�C�����[�U��������R�[�h
  gv_enable_all             VARCHAR2(1) := '0';                        -- �S�ЎQ�ƌ���
  gn_rec_count              PLS_INTEGER := 0;                          -- ���������擾����
  --
  gn_vd_billed              NUMBER;                                    -- VD�����z
  gn_bm1_rate               NUMBER;                                    -- BM1��
  gn_bm1_amt                NUMBER;                                    -- BM1�z
  gn_bm1_all                NUMBER;                                    -- BM1�萔���z
  gn_bm2_rate               NUMBER;                                    -- BM2��
  gn_bm2_amt                NUMBER;                                    -- BM2�z
  gn_bm2_all                NUMBER;                                    -- BM2�萔���z
  gn_bm3_rate               NUMBER;                                    -- BM3��
  gn_bm3_amt                NUMBER;                                    -- BM3�z
  gn_bm3_all                NUMBER;                                    -- BM3�萔���z
  gn_electric_amt           NUMBER;                                    -- �d�C��
  --
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  -- ���������擾�J�[�\��
  CURSOR get_invoice_cur(id_target_date DATE,
                         iv_ar_code1    VARCHAR2)
  IS
    SELECT ''                                               conc_request_id,          -- �v��ID
           ''                                               sort_num,                 -- �o�͏�
           xih.invoice_id                                   invoice_id,               -- �ꊇ������ID
           xih.itoen_name                                   itoen_name,               -- ����於
           TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD')      inv_creation_date,        -- �쐬��
           xih.object_month                                 object_month,             -- �Ώ۔N��
           TO_CHAR(xih.object_date_from,'YYYY/MM/DD')       object_date_from,         -- �Ώۊ���(��)
           TO_CHAR(xih.object_date_to,'YYYY/MM/DD')         object_date_to,           -- �Ώۊ���(��)
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
           NULL                                             sold_location_code,       -- ���_�R�[�h
           NULL                                             sold_location_name,       -- ���_��
           NULL                                             ship_cust_code,           -- �ڋq�R�[�h
           NULL                                             ship_cust_name,           -- �ڋq��
           xih.bill_shop_code                               bill_shop_code,           -- ������ڋq�XNO
           xih.bill_shop_name                               bill_shop_name,           -- ������ڋq�X��
           NULL                                             ship_shop_code,           -- �[�i��ڋq�XNO
           NULL                                             ship_shop_name,           -- �[�i��ڋq�X��
           NULL                                             vd_num,                   -- �����̔��@�ԍ�
           NULL                                             delivery_date,            -- �[�i��
           NULL                                             slip_num,                 -- �`�[NO
           NULL                                             order_num,                -- �I�[�_�[NO
           NULL                                             column_num,               -- �R����
           NULL                                             item_code,                -- ���i�R�[�h
           NULL                                             jan_code,                 -- JAN�R�[�h
           NULL                                             item_name,                -- ���i��
           NULL                                             vessel,                   -- �e��
           NULL                                             quantity,                 -- ����
           NULL                                             unit_price,               -- ���P��
           NULL                                             ship_amount,              -- ����
           SUM(xil.sold_amount)                             sold_amount,              -- ���z
           SUM(CASE WHEN xil.sold_amount >= 0 THEN
                 xil.sold_amount
               ELSE
                 0
               END)                                         sold_amount_plus,         -- ���z�i���j
           SUM(CASE WHEN xil.sold_amount < 0 THEN
                 xil.sold_amount
               ELSE
                 0
               END)                                         sold_amount_minus,        -- ���z�i�ԁj
           SUM((CASE WHEN xil.sold_amount >= 0 THEN
                  xil.sold_amount
                ELSE
                  0
                END)
               +
               (CASE WHEN xil.sold_amount < 0 THEN
                  xil.sold_amount
                ELSE
                  0
                END)
              )                                             sold_amount_total,        -- ���z�i�v�j
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
           NULL                                             classify_type             -- ���ދ敪
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
      AND xih.cutoff_date = id_target_date
      AND xih.set_of_books_id = gt_gl_set_of_bks_id
      AND xih.org_id = gt_org_id
      GROUP BY xih.invoice_id,
               xih.itoen_name,
               TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD'),
               xih.object_month,
               TO_CHAR(xih.object_date_from,'YYYY/MM/DD'),
               TO_CHAR(xih.object_date_to,'YYYY/MM/DD'),
               xih.vender_code,
               xih.bill_location_code,
               xih.bill_location_name,
               xih.agent_tel_num,
               xih.credit_cust_code,
               xih.credit_cust_name,
               xih.receipt_cust_code,
               xih.receipt_cust_name,
               xih.payment_cust_code,
               xih.payment_cust_name,
               xih.bill_cust_code,
               xih.bill_cust_name,
               xih.credit_receiv_code2,
               xih.credit_receiv_name2,
               xih.credit_receiv_code3,
               xih.credit_receiv_name3,
               xih.bill_shop_code,
               xih.bill_shop_name
      ORDER BY NVL(xih.bill_shop_code,cv_sort_null_value),  -- ������ڋq�XNO
               xih.bill_cust_code;                          -- ������ڋq�R�[�h
    --
  --===============================================================
  -- �O���[�o���^�C�v
  --===============================================================
  TYPE inv_tab_ttype      IS TABLE OF get_invoice_cur%ROWTYPE INDEX BY PLS_INTEGER;       -- �������擾
  TYPE csv_outs_tab_ttype IS TABLE OF xxcfr_csv_outs_temp%ROWTYPE INDEX BY PLS_INTEGER;   -- ���[�N�e�[�u�����i�[
  --
  g_inv_tab                inv_tab_ttype;                              -- �X�ʐ������
  g_csv_outs_tab           csv_outs_tab_ttype;                         -- ���[�N�e�[�u���������
  --
  --===============================================================
  -- �O���[�o����O
  --===============================================================
  global_process_expt       EXCEPTION; -- �֐���O
  global_api_expt           EXCEPTION; -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION; -- ���ʊ֐�OTHERS��O
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);  -- ���ʊ֐���O(ORA-20000)��global_api_others_expt���}�b�s���O
  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
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
    
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
    
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
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
                                   iv_conc_param2 => iv_ar_code1,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
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
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
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
   * Procedure Name   : chk_bm
   * Description      : �̎�����̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE chk_bm(
    id_target_date    IN  DATE,        -- ����
    in_invoice_id     IN  NUMBER,
    iv_account_number IN VARCHAR2,
    iv_account_name   IN VARCHAR2,
    ov_get_bm_flag    OUT VARCHAR2,    -- BM���z�擾�t���O
    ov_get_bm_price   OUT VARCHAR2,    -- ���z�擾�t���O
    ov_errbuf         OUT VARCHAR2,
    ov_retcode        OUT VARCHAR2,
    ov_errmsg         OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_bm';  -- �v���O������
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
    -- �̎�����擾�J�[�\��
    CURSOR chk_bm_cur
    IS
      SELECT DISTINCT
             xmbc.calc_type             calc_type,                -- �v�Z����
             xmbc.bm1_pct               bm1_pct,                  -- BM1��
             xmbc.bm1_amt               bm1_amt                   -- BM1�P��
      FROM   xxcok_mst_bm_contract xmbc
      WHERE  EXISTS(SELECT  'X'
                    FROM    xxcfr_invoice_lines xil
                    WHERE   xil.invoice_id     = in_invoice_id
                    AND     xil.vd_cust_type   = cv_vd_cust_type
                    AND     xil.ship_cust_code = xmbc.cust_code)
      AND    NVL(xmbc.start_date_active,TO_DATE('19000101','YYYYMMDD')) <= id_target_date
      AND    NVL(xmbc.end_date_active,TO_DATE('22001231','YYYYMMDD'))   >= id_target_date
      AND    calc_type  NOT IN (ct_calc_type_20,ct_calc_type_50) ;
    --
    chk_bm_rec   chk_bm_cur%ROWTYPE;
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
    <<chk_bm_loop>>
    FOR chk_bm_rec IN chk_bm_cur
      LOOP
        ov_get_bm_price := 'Y';   -- ���z�擾�t���O��'Y'
        ln_cnt := ln_cnt + 1;     -- �J�E���g���C���N�������g
        --
        -- 1���ł��f�[�^���擾�ł����ꍇ��BM���z�擾�t���O��'Y'�ɂ���
        IF (ov_get_bm_flag = 'N') THEN
          ov_get_bm_flag := 'Y';
        END IF ;
        --
        -- 2���ڈȍ~�ŗ��z�擾�t���O��'Y'�̏ꍇ�A���z�擾�t���O��'N'�ɐݒ�
        IF ((ln_cnt > 1) AND (ov_get_bm_price = 'Y')) THEN
          ov_get_bm_price := 'N';
          --
          -- �����P���擾���b�Z�[�W�����o�͂̏ꍇ�́A�o��
          IF ( lv_msg_out = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,
                              xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                                       iv_name         => ct_msg_cfr_00037,
                                                       iv_token_name1  => 'ACCOUNT_NUMBER',
                                                       iv_token_value1 => iv_account_number,
                                                       iv_token_name2  => 'ACCOUNT_NAME',
                                                       iv_token_value2 => iv_account_name
                                                      ));
            lv_msg_out := 'Y';      -- ���b�Z�[�W���o�͍ς݂ɕύX
          END IF;
        END IF;
        --
      --
      END LOOP chk_bm_loop;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END chk_bm;
  --
  /**********************************************************************************
   * Procedure Name   : get_bm
   * Description      : �̔��萔���E�d�C��̎擾(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm(
    id_target_date   IN  DATE,        -- ����
    in_num           IN  NUMBER,      -- ���R�[�h����
    in_invoice_id    IN  NUMBER,      -- �ꊇ������ID
    iv_get_bm_price  IN  VARCHAR2,    -- ���z�擾����
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
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
    -- BM���E�z�E���z�E�d�C��̎擾
    --
    SELECT   AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_rate
                      ,NULL)
             ) bm1_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.rebate_amt
                      ,NULL)
             ) bm1_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm1,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End               
                      ,NULL)
             ) bm1_all,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_rate
                      ,NULL)
             ) bm2_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.rebate_amt
                      ,NULL)
             ) bm2_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm2,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End
                      ,NULL)
             ) bm2_all,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_rate
                      ,NULL)
             ) bm3_rate,
             AVG(
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.rebate_amt
                      ,NULL)
             ) bm3_amt,
             SUM(
-- Modify 2009.04.12 Ver1.2 Start
--               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.cond_bm_amt_tax
               DECODE(xcbs.supplier_code,ct_sc_bm3,xcbs.csh_rcpt_discount_amt
-- Modify 2009.04.12 Ver1.2 End
                      ,NULL)
             ) bm3_all,
             SUM(electric_amt_tax)        electric_amt
    INTO     g_inv_tab(in_num).bm_rate1,
             g_inv_tab(in_num).bm_unit_price1,
             g_inv_tab(in_num).bm_price1,
             g_inv_tab(in_num).bm_rate2,
             g_inv_tab(in_num).bm_unit_price2,
             g_inv_tab(in_num).bm_price2,
             g_inv_tab(in_num).bm_rate3,
             g_inv_tab(in_num).bm_unit_price3,
             g_inv_tab(in_num).bm_price3,
             g_inv_tab(in_num).electric_charges
    FROM     xxcok_cond_bm_support xcbs
    WHERE EXISTS(SELECT  'X'
                 FROM    xxcfr_invoice_lines xil
                 WHERE   xil.invoice_id     = in_invoice_id
                 AND     xil.vd_cust_type   = cv_vd_cust_type
                 AND     xil.ship_cust_code = xcbs.delivery_cust_code
                 )
    AND   closing_date = id_target_date
    AND   calc_type    IN (ct_calc_type_10,
                           ct_calc_type_30,
                           ct_calc_type_40,
                           ct_calc_type_50);
    --
    IF (iv_get_bm_price = 'N') THEN
      g_inv_tab(in_num).bm_rate1       := NULL;
      g_inv_tab(in_num).bm_unit_price1 := NULL;
      g_inv_tab(in_num).bm_rate2       := NULL;
      g_inv_tab(in_num).bm_unit_price2 := NULL;
      g_inv_tab(in_num).bm_rate3       := NULL;
      g_inv_tab(in_num).bm_unit_price3 := NULL;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
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
    lv_get_bm_flag     VARCHAR2(1);   -- BM�擾����
    lv_get_bm_price    VARCHAR2(1);   -- ���z�擾����
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
      FETCH get_invoice_cur BULK COLLECT INTO g_inv_tab;
      --
      -- �f�[�^�����擾
      --
      gn_rec_count := g_inv_tab.COUNT;
      --
    CLOSE get_invoice_cur;
    --
    -- 
    <<invoice_loop>>
    FOR i IN 1..gn_rec_count LOOP
    --
      -- �l���
      g_inv_tab(i).conc_request_id := gn_conc_request_id;    -- �v��ID
      g_inv_tab(i).sort_num        := i;                     -- �\�[�g��
      --
      --
    --===============================================================
    -- A-4�D�̎�����̎擾
    --===============================================================
        chk_bm(id_target_date    => id_target_date,              -- ����
               in_invoice_id     => g_inv_tab(i).invoice_id,     -- �ꊇ������ID
               iv_account_number => g_inv_tab(i).bill_cust_code, -- ������ڋq�R�[�h
               iv_account_name   => g_inv_tab(i).bill_cust_name, -- ������ڋq��
               ov_get_bm_flag    => lv_get_bm_flag,              -- BM�擾�t���O
               ov_get_bm_price   => lv_get_bm_price,             -- ���z�擾�t���O
               ov_errbuf         => lv_errbuf,
               ov_retcode        => lv_retcode,
               ov_errmsg         => lv_errmsg);
      --
      IF (lv_get_bm_flag = 'Y') THEN  -- BM�擾�t���O��'Y'
      --
    --===============================================================
    -- A-5�D�̔��萔���E�d�C��̎擾
    --===============================================================
        get_bm(id_target_date   => id_target_date,            -- ����
               in_num           => i,                         -- ���R�[�h����
               in_invoice_id    => g_inv_tab(i).invoice_id,   -- �ꊇ������ID
               iv_get_bm_price  => lv_get_bm_price,           -- ���z�擾����
               ov_errbuf        => lv_errbuf,
               ov_retcode       => lv_retcode,
               ov_errmsg        => lv_errmsg
              );
        --
    --===============================================================
    -- A-6�DVD�������z�̎Z�o 
    --===============================================================
      g_inv_tab(i).vd_amount_claimed :=
        g_inv_tab(i).inv_amount_includ_tax - NVL(g_inv_tab(i).bm_price1,0);
--
      END IF;
      --
      --
      -- ���[�N�e�[�u�������ϐ��֑��
      --
      g_csv_outs_tab(i).request_id  := g_inv_tab(i).conc_request_id;
      g_csv_outs_tab(i).seq         := g_inv_tab(i).sort_num;
      g_csv_outs_tab(i).col1        := g_inv_tab(i).itoen_name;
      g_csv_outs_tab(i).col2        := g_inv_tab(i).inv_creation_date;
      g_csv_outs_tab(i).col3        := g_inv_tab(i).object_month;
      g_csv_outs_tab(i).col4        := g_inv_tab(i).object_date_from;
      g_csv_outs_tab(i).col5        := g_inv_tab(i).object_date_to;
      g_csv_outs_tab(i).col6        := g_inv_tab(i).vender_code;
      g_csv_outs_tab(i).col7        := g_inv_tab(i).bill_location_code;
      g_csv_outs_tab(i).col8        := g_inv_tab(i).bill_location_name;
      g_csv_outs_tab(i).col9        := g_inv_tab(i).agent_tel_num;
      g_csv_outs_tab(i).col10       := g_inv_tab(i).credit_cust_code;
      g_csv_outs_tab(i).col11       := g_inv_tab(i).credit_cust_name;
      g_csv_outs_tab(i).col12       := g_inv_tab(i).receipt_cust_code;
      g_csv_outs_tab(i).col13       := g_inv_tab(i).receipt_cust_name;
      g_csv_outs_tab(i).col14       := g_inv_tab(i).payment_cust_code;
      g_csv_outs_tab(i).col15       := g_inv_tab(i).payment_cust_name;
      g_csv_outs_tab(i).col16       := g_inv_tab(i).bill_cust_code;
      g_csv_outs_tab(i).col17       := g_inv_tab(i).bill_cust_name;
      g_csv_outs_tab(i).col18       := g_inv_tab(i).credit_receiv_code2;
      g_csv_outs_tab(i).col19       := g_inv_tab(i).credit_receiv_name2;
      g_csv_outs_tab(i).col20       := g_inv_tab(i).credit_receiv_code3;
      g_csv_outs_tab(i).col21       := g_inv_tab(i).credit_receiv_name3;
      g_csv_outs_tab(i).col22       := g_inv_tab(i).sold_location_code;
      g_csv_outs_tab(i).col23       := g_inv_tab(i).sold_location_name;
      g_csv_outs_tab(i).col24       := g_inv_tab(i).ship_cust_code;
      g_csv_outs_tab(i).col25       := g_inv_tab(i).ship_cust_name;
      g_csv_outs_tab(i).col26       := g_inv_tab(i).bill_shop_code;
      g_csv_outs_tab(i).col27       := g_inv_tab(i).bill_shop_name;
      g_csv_outs_tab(i).col28       := g_inv_tab(i).ship_shop_code;
      g_csv_outs_tab(i).col29       := g_inv_tab(i).ship_shop_name;
      g_csv_outs_tab(i).col30       := g_inv_tab(i).vd_num;
      g_csv_outs_tab(i).col31       := g_inv_tab(i).delivery_date;
      g_csv_outs_tab(i).col32       := g_inv_tab(i).slip_num;
      g_csv_outs_tab(i).col33       := g_inv_tab(i).order_num;
      g_csv_outs_tab(i).col34       := g_inv_tab(i).column_num;
      g_csv_outs_tab(i).col35       := g_inv_tab(i).item_code;
      g_csv_outs_tab(i).col36       := g_inv_tab(i).jan_code;
      g_csv_outs_tab(i).col37       := g_inv_tab(i).item_name;
      g_csv_outs_tab(i).col38       := g_inv_tab(i).vessel;
      g_csv_outs_tab(i).col39       := g_inv_tab(i).quantity;
      g_csv_outs_tab(i).col40       := g_inv_tab(i).unit_price;
      g_csv_outs_tab(i).col41       := g_inv_tab(i).ship_amount;
      g_csv_outs_tab(i).col42       := g_inv_tab(i).sold_amount;
      g_csv_outs_tab(i).col43       := g_inv_tab(i).sold_amount_plus;
      g_csv_outs_tab(i).col44       := g_inv_tab(i).sold_amount_minus;
      g_csv_outs_tab(i).col45       := g_inv_tab(i).sold_amount_total;
      g_csv_outs_tab(i).col46       := g_inv_tab(i).inv_amount_includ_tax;
      g_csv_outs_tab(i).col47       := g_inv_tab(i).tax_amount_sum;
      g_csv_outs_tab(i).col48       := g_inv_tab(i).bm_unit_price1;
      g_csv_outs_tab(i).col49       := g_inv_tab(i).bm_rate1;
      g_csv_outs_tab(i).col50       := g_inv_tab(i).bm_price1;
      g_csv_outs_tab(i).col51       := g_inv_tab(i).bm_unit_price2;
      g_csv_outs_tab(i).col52       := g_inv_tab(i).bm_rate2;
      g_csv_outs_tab(i).col53       := g_inv_tab(i).bm_price2;
      g_csv_outs_tab(i).col54       := g_inv_tab(i).bm_unit_price3;
      g_csv_outs_tab(i).col55       := g_inv_tab(i).bm_rate3;
      g_csv_outs_tab(i).col56       := g_inv_tab(i).bm_price3;
      g_csv_outs_tab(i).col57       := g_inv_tab(i).vd_amount_claimed;
      g_csv_outs_tab(i).col58       := g_inv_tab(i).electric_charges;
      g_csv_outs_tab(i).col59       := g_inv_tab(i).slip_type;
      g_csv_outs_tab(i).col60       := g_inv_tab(i).classify_type;
      --
    END LOOP invoice_loop;
    --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00016,
                                            iv_token_name1 => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
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
      INSERT INTO xxcfr_csv_outs_temp VALUES g_csv_outs_tab(i);
      --
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name,
                                            iv_name         => ct_msg_cfr_00016,
                                            iv_token_name1  => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
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
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => ct_msg_cfr_00010,
                                            iv_token_name1 => cv_func_name,
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
   * Description      : �I�������v���V�[�W��(A-9)
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
                                                     iv_name => ct_msg_cfr_00024
                                                    )
                           );
    END IF;
    
    -- �����o��
    -- ����܂��͌x���I���̏ꍇ
    IF ((iv_retcode = cv_status_normal) OR (iv_retcode = cv_status_warn)) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
    -- �G���[�I���̏ꍇ
    ELSIF (iv_retcode = cv_status_error) THEN
      -- �Ώی����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- ���������o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- �G���[�����o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
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
                                                 iv_name => ct_msg_ccp_90006
                                                )
                       );
    -- �Ώۃf�[�^0���̏ꍇ(�x���I��)
    ELSIF (iv_retcode = cv_status_warn) THEN
      -- �x���I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90005
                                                )
                       );
    -- ����I���̏ꍇ
    ELSE
      -- ����I�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => ct_msg_ccp_90004
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
   * Description      : �ėp�X�ʐ����f�[�^�쐬�������s��
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
    init(iv_target_date,
         iv_ar_code1,
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
                                                           iv_invoice_type => cv_invoice_type
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
    get_invoice(xxcfr_common_pkg.get_date_param_trans(iv_target_date),
                iv_ar_code1,
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
    
    xxccp_common_pkg.put_log_header(iv_which => cv_put_log_which,
                                    ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
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
      );      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    
    -- �X�e�[�^�X���Z�b�g
    retcode := lv_retcode;
    
    --===============================================================
    -- A-9�D�I������
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
  
END  XXCFR003A06C;
/
