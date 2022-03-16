CREATE OR REPLACE PACKAGE BODY XXCOK024A40R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK024A40R(body)
 * Description      : �≮�����P���`�F�b�N���X�g
 * MD.050           : MD050_COK_024_A40_�≮�����P���`�F�b�N���X�g.doc
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_wholesale_pay      ���[�N�e�[�u���f�[�^�폜(A-6)
 *  start_svf              SVF�N��(A-5)
 *  ins_wholesale_pay      ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  get_target_data        �Ώۃf�[�^�擾(A-2)�E�T���}�X�^���擾(A-3)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/01/28    1.0   K.Yoshikawa     �V�K�쐬
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK024A40R';
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_code_00001          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';          -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';          -- �v���t�@�C���擾�G���[
  cv_msg_code_00013          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';          -- �݌ɑg�DID�擾�G���[
  cv_msg_code_00015          CONSTANT VARCHAR2(25)  := 'APP-XXCOK1-00015';          -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- �Ɩ��������t�擾�G���[
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF�N��API�G���[
  cv_msg_code_10829          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10829';          -- �x���N����(���̓p�����[�^)
  cv_msg_code_10830          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10830';          -- �v��N����(���̓p�����[�^)
  cv_msg_code_10831          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10831';          -- ���_�R�[�h(���̓p�����[�^)
  cv_msg_code_10832          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10832';          -- �d����R�[�h(���̓p�����[�^)
  cv_msg_code_10833          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10833';          -- �������ԍ�(���̓p�����[�^)
  cv_msg_code_10834          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10834';          -- �T���p�`�F�[���R�[�h(���̓p�����[�^)
  cv_msg_code_10043          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10043';          -- �f�[�^�폜�G���[
  cv_msg_code_10827          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10827';          -- ���b�N�擾�G���[
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی���
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- ��������
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[����
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I��
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N
  cv_msg_code_10566          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10566';          -- ����ŗ����d���G���[
  -- �g�[�N��
  cv_token_pay_date          CONSTANT VARCHAR2(15)  := 'PAY_DATE';
  cv_token_target_date       CONSTANT VARCHAR2(15)  := 'TARGET_DATE';
  cv_token_base_code         CONSTANT VARCHAR2(15)  := 'BASE_CODE';
  cv_token_supplier_code     CONSTANT VARCHAR2(15)  := 'SUPPLIER_CODE';
  cv_token_bill_no           CONSTANT VARCHAR2(15)  := 'BILL_NO';
  cv_token_chain_code        CONSTANT VARCHAR2(15)  := 'CHAIN_CODE';
  cv_token_profile           CONSTANT VARCHAR2(15)  := 'PROFILE';
  cv_token_org_code          CONSTANT VARCHAR2(15)  := 'ORG_CODE';
  cv_token_request_id        CONSTANT VARCHAR2(15)  := 'REQUEST_ID';
  cv_token_count             CONSTANT VARCHAR2(15)  := 'COUNT';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(25)  := 'LOOKUP_VALUE_SET';
  -- �v���t�@�C��
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- �݌ɑg�D�R�[�h_�c�Ƒg�D
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';                    -- �c�ƒP��ID
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- ���l
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- �o�͋敪
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                       -- �o�͋敪
  -- �^�C�v
  cv_lookup_tax_code_his     CONSTANT VARCHAR2(25)  := 'XXCFO1_TAX_CODE_HISTORIES';
  cv_lookup_tax_pay_check    CONSTANT VARCHAR2(30)  := 'XXCOK1_WHOLESALE_PAY_CHECK';
  -- SVF�N���p�����[�^
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK024A40R';              -- ���[ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                         -- �o�͋敪(PDF�o��)
  cv_extension               CONSTANT VARCHAR2(10)  := '.pdf';                      -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK024A40S.xml';          -- �t�H�[���l���t�@�C����
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK024A40S.vrq';          -- �N�G���[�l���t�@�C����
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt                NUMBER        DEFAULT 0;                             -- �Ώی���
  gn_normal_cnt                NUMBER        DEFAULT 0;                             -- ���팏��
  gn_error_cnt                 NUMBER        DEFAULT 0;                             -- �G���[����
  gv_org_code_sales            VARCHAR2(50)  DEFAULT NULL;                          -- �v���t�@�C���l(�݌ɑg�D�R�[�h_�c�Ƒg�D)
  gn_org_id_sales              NUMBER        DEFAULT NULL;                          -- �݌ɑg�DID
  gn_org_id                    NUMBER        DEFAULT NULL;                          -- �c�ƒP��ID
  gd_process_date              DATE          DEFAULT NULL;                          -- �Ɩ��������t
  gv_no_data_msg               VARCHAR2(30)  DEFAULT NULL;                          -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  gn_demand_en_3               NUMBER        DEFAULT NULL;                          -- ����(�~)
  gn_shop_pay_en_3             NUMBER        DEFAULT NULL;                          -- �X�[(�~)
  gn_accrued_en_3              NUMBER        DEFAULT NULL;                          -- �����v�R(�~)
  gn_normal_shop_pay_en_4_1    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_1
  gn_normal_shop_pay_en_4_2    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_2
  gn_normal_shop_pay_en_4_3    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_3
  gn_normal_shop_pay_en_4_4    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_4
  gn_normal_shop_pay_en_4_5    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_5
  gn_normal_shop_pay_en_4_6    NUMBER        DEFAULT NULL;                          -- �ʏ�X�[(�~)_6
  gn_just_shop_pay_en_4_1      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_1
  gn_just_shop_pay_en_4_2      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_2
  gn_just_shop_pay_en_4_3      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_3
  gn_just_shop_pay_en_4_4      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_4
  gn_just_shop_pay_en_4_5      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_5
  gn_just_shop_pay_en_4_6      NUMBER        DEFAULT NULL;                          -- ����X�[(�~)_6
  gn_just_condition_en_4_1     NUMBER        DEFAULT NULL;                          -- �������(�~)_1
  gn_just_condition_en_4_2     NUMBER        DEFAULT NULL;                          -- �������(�~)_2
  gn_just_condition_en_4_3     NUMBER        DEFAULT NULL;                          -- �������(�~)_3
  gn_just_condition_en_4_4     NUMBER        DEFAULT NULL;                          -- �������(�~)_4
  gn_just_condition_en_4_5     NUMBER        DEFAULT NULL;                          -- �������(�~)_5
  gn_just_condition_en_4_6     NUMBER        DEFAULT NULL;                          -- �������(�~)_6
  gn_accrued_en_4_1            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_1
  gn_dedu_est_kbn_1            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_1_�T�����ϋ敪
  gn_accrued_en_4_2            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_2
  gn_dedu_est_kbn_2            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_2_�T�����ϋ敪
  gn_accrued_en_4_3            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_3
  gn_dedu_est_kbn_3            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_3_�T�����ϋ敪
  gn_accrued_en_4_4            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_4
  gn_dedu_est_kbn_4            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_4_�T�����ϋ敪
  gn_accrued_en_4_5            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_5
  gn_dedu_est_kbn_5            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_5_�T�����ϋ敪
  gn_accrued_en_4_6            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_6
  gn_dedu_est_kbn_6            NUMBER        DEFAULT NULL;                          -- �����v�S(�~)_6_�T�����ϋ敪
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  CURSOR g_target_cur(
    iv_payment_date          IN VARCHAR2  -- �x���N����
  , iv_selling_date          IN VARCHAR2  -- ����Ώ۔N����
  , iv_base_code             IN VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN VARCHAR2  -- �T���p�`�F�[���R�[�h
  )
  IS
    SELECT  /*+ INDEX(pvsa PO_VENDOR_SITES_U2)*/
            xwbl.wholesale_bill_detail_id                        wholesale_bill_detail_id    --�≮����������ID
           ,xwbh.expect_payment_date                             payment_date                --�x���N����
           ,xwbl.bill_no                                         bill_no                     --������no.
           ,xwbh.base_code                                       base_code                   --���_�R�[�h
           ,( SELECT SUBSTRB(xbav.base_name,1,20)                             -- ���_����
              FROM   apps.xxcok_base_all_v xbav                               -- ���_�r���[
              WHERE  xbav.base_code = xwbh.base_code                          -- ���_�R�[�h
             )                                                   base_name                   --���_����
           ,xwbh.cust_code                                       cust_code                   --�ڋq�R�[�h
           ,SUBSTRB(hp.party_name,1,100)                         cust_name                   --�ڋq����
           ,xwbl.sales_outlets_code                              deduction_chain_code        --�T���p�`�F�[���R�[�h
           ,SUBSTRB(flv.meaning,1,80)                            deduction_chain_name        --�T���p�`�F�[����
           ,xwbl.selling_date                                    selling_date                --����N����
           ,xwbl.item_code                                       item_code                   --�i�ڃR�[�h
           ,SUBSTRB(item.item_short_name,1,100)                  item_name                   --�i�ږ���
           ,xwbl.demand_qty                                      demand_qty                  --��������
           ,xwbl.demand_unit_price                               demand_unit_price           --�����P��
           ,xwbl.difference_amt                                  difference_amt              --�[������
           ,xwbl.demand_amt                                      demand_amt                  --�������z
           ,xwbl.demand_unit_type                                demand_unit_type            --�P��
           ,xwbl.expansion_sales_type                            expansion_sales_type        --�g���敪
           ,xwbh.supplier_code                                   supplier_code               --�d����R�[�h
           ,SUBSTRB(pv.vendor_name,1,100)                        supplier_name               --�d���於��
           ,SUBSTRB(bank.bank_name,1,60)                         bank_name                   --��s��
           ,SUBSTRB(bank.bank_branch_name,1,60)                  bank_branch_name            --�x�X��
           ,bank.bank_account_type                               bank_account_type           --�������
           ,bank.bank_account_num                                bank_account_num            --�����ԍ�
           ,(SELECT xrtrv.tax_rate
             FROM   apps.xxcos_reduced_tax_rate_v xrtrv
             WHERE  xrtrv.item_code(+)     = xwbl.item_code
             AND    xwbl.selling_date     >= xrtrv.start_date(+)
             AND    xwbl.selling_date     <= NVL(xrtrv.end_date(+), xwbl.selling_date)
             AND    xwbl.selling_date     >= xrtrv.start_date_histories(+)
             AND    xwbl.selling_date     <= NVL(xrtrv.end_date_histories(+), xwbl.selling_date)
            )                                                    tax_rate                    --�ŗ�
    FROM    apps.xxcok_wholesale_bill_head xwbh
           ,apps.xxcok_wholesale_bill_line xwbl
           ,apps.hz_cust_accounts          hca
           ,apps.hz_parties                hp
           ,apps.xxcmm_cust_accounts       xca
           ,( SELECT iimb.item_no                  AS item_code               -- �i�ڃR�[�h
                   , ximb.item_short_name          AS item_short_name         -- �i���E����
              FROM   apps.ic_item_mst_b         iimb                          -- OPM�i�ڃ}�X�^
                   , apps.xxcmn_item_mst_b      ximb                          -- OPM�i�ڃA�h�I���}�X�^
              WHERE  iimb.item_id          = ximb.item_id
              AND    gd_process_date BETWEEN ximb.start_date_active
                                         AND NVL ( ximb.end_date_active , gd_process_date )               --A-1�Ŏ擾�����Ɩ����t
            ) item
           ,( SELECT abau.vendor_id        AS vendor_id                       -- �����d����ID
                   , abau.vendor_site_id   AS vendor_site_id                  -- �����d����T�C�gID
                   , abb.bank_name         AS bank_name                       -- ��s��
                   , abb.bank_branch_name  AS bank_branch_name                -- ��s�x�X��
                   , hl.meaning            AS bank_account_type               -- �������
                   , abaa.bank_account_num AS bank_account_num                -- �����ԍ�
              FROM   apps.ap_bank_branches              abb                   -- ��s�x�X���
                   , apps.ap_bank_accounts_all          abaa                  -- ��s�������
                   , apps.ap_bank_account_uses_all      abau                  -- ��s�����g�p���
                   , apps.hr_lookups                    hl                    -- �N�C�b�N�R�[�h
              WHERE  abau.external_bank_account_id = abaa.bank_account_id
              AND    abaa.bank_branch_id           = abb.bank_branch_id
              AND    abaa.org_id                   = gn_org_id 
              AND    abaa.bank_account_type        = hl.lookup_code(+)
              AND    hl.lookup_type(+)             = 'XXCSO1_KOZA_TYPE'
              AND    abau.primary_flag             = 'Y'
              AND    abau.org_id                   = gn_org_id 
              AND    ( abau.start_date            <= gd_process_date OR abau.start_date IS NULL )         --A-1�Ŏ擾�����Ɩ����t
              AND    ( abau.end_date              >= gd_process_date OR abau.end_date   IS NULL )
             ) bank
           ,apps.fnd_lookup_values              flv
           ,apps.po_vendors                     pv
           ,apps.po_vendor_sites_all            pvsa
    WHERE   xwbh.wholesale_bill_header_id  = xwbl.wholesale_bill_header_id
    AND     (   xwbl.status               is NULL
             OR xwbl.status               <> 'D' )
    AND     xwbh.expect_payment_date       = to_date(iv_payment_date,'yyyy/mm/dd')                        --�p�����[�^�K�{
    AND     xwbl.selling_date              = nvl(to_date(iv_selling_date,'yyyy/mm/dd'),xwbl.selling_date) --�p�����[�^�C��
    AND     xwbh.base_code                 = nvl(iv_base_code,xwbh.base_code)                             --�p�����[�^�C��
    AND     xwbh.supplier_code             = nvl(iv_wholesale_vendor_code,xwbh.supplier_code)             --�p�����[�^�C��
    AND     xwbl.bill_no                   = nvl(iv_bill_no,xwbl.bill_no)                                 --�p�����[�^�C��
    AND     xwbl.sales_outlets_code        = nvl(iv_chain_code,xwbl.sales_outlets_code)                   --�p�����[�^�C��
    AND     hca.account_number             = xwbh.cust_code
    AND     hca.cust_account_id            = xca.customer_id
    AND     hca.party_id                   = hp.party_id
    AND     item.item_code(+)              = xwbl.item_code
    AND     pv.segment1                    = xwbh.supplier_code
    AND     pv.vendor_id                   = pvsa.vendor_id
    AND     pvsa.vendor_id                 = bank.vendor_id(+)
    AND     pvsa.vendor_site_id            = bank.vendor_site_id(+)
    AND     pvsa.org_id                    = gn_org_id 
    AND     ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )                        --A-1�Ŏ擾�����Ɩ����t
    AND     flv.LOOKUP_TYPE                = 'XXCMM_CHAIN_CODE' 
    AND     flv.LANGUAGE                   = 'JA' 
    AND     flv.lookup_code                = xwbl.sales_outlets_code
    AND     flv.enabled_flag               = 'Y'
    AND     gd_process_date BETWEEN nvl(flv.start_date_active, gd_process_date)                           --A-1�Ŏ擾�����Ɩ����t
                                  AND     nvl(flv.end_date_active, gd_process_date)
    ORDER BY
     xwbh.expect_payment_date
    ,xwbl.selling_date
    ,xwbh.cust_code
    ,xwbh.supplier_code
    ,xwbl.bill_no
    ,xwbl.sales_outlets_code
    ,xwbh.cust_code
    ,xwbl.wholesale_bill_detail_id;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
--
  CURSOR lookup_stamp_cur
  IS
    SELECT flv.lookup_code   AS lookup_code
         , flv.meaning       AS meaning
         , flv.description   AS description
         , flv.tag           AS tag
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_tax_pay_check
    AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND NVL( flv.end_date_active, gd_process_date )
    AND    flv.language     = USERENV('LANG')
    AND    flv.enabled_flag = 'Y'
    ORDER BY flv.lookup_code
  ;
  lookup_stamp_rec   lookup_stamp_cur%ROWTYPE;
  TYPE g_lookup_stamp_ttype IS TABLE OF lookup_stamp_cur%ROWTYPE INDEX BY VARCHAR2(1);
  g_lookup_stamp_tab g_lookup_stamp_ttype;
--
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���b�N�G���[ ***
  global_lock_fail          EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  /**********************************************************************************
   * Procedure Name   : del_wholesale_pay
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_wholesale_pay(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'del_wholesale_pay';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR wholesale_pay_cur
    IS
      SELECT 'X'
      FROM   xxcok_wholesale_pay_check_list  xrwp
      WHERE  xrwp.request_id = cn_request_id
      FOR UPDATE OF xrwp.wholesale_bill_detail_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �≮�����P���`�F�b�N���X�g���[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  wholesale_pay_cur;
    CLOSE wholesale_pay_cur;
    -- ===============================================
    -- �≮�����P���`�F�b�N���X�g���[�N�e�[�u���f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_wholesale_pay_check_list  xrwp
      WHERE  xrwp.request_id = cn_request_id;
      -- ===============================================
      -- ���������擾
      -- ===============================================
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** �폜�����G���[ ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10043
                      , iv_token_name1  => cv_token_request_id
                      , iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10827
                    , iv_token_name1  => cv_token_request_id
                    , iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_wholesale_pay;
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'start_svf'; -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg    VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lv_date      VARCHAR2(8)    DEFAULT NULL;              -- �o�̓t�@�C�����p���t
    lv_file_name VARCHAR2(100)  DEFAULT NULL;              -- �o�̓t�@�C����
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �V�X�e�����t�^�ϊ�
    -- ===============================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    -- ===============================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    -- ===============================================
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_extension;
    -- ===============================================
    -- SVF�R���J�����g�N��
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                  -- �G���[�o�b�t�@
      , ov_retcode       => lv_retcode                 -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                  -- �G���[���b�Z�[�W
      , iv_conc_name     => cv_pkg_name                -- �R���J�����g��
      , iv_file_name     => lv_file_name               -- �o�̓t�@�C����
      , iv_file_id       => cv_file_id                 -- ���[ID
      , iv_output_mode   => cv_output_mode             -- �o�͋敪
      , iv_frm_file      => cv_frm_file                -- �t�H�[���l���t�@�C����
      , iv_vrq_file      => cv_vrq_file                -- �N�G���[�l���t�@�C����
      , iv_org_id        => TO_CHAR( gn_org_id_sales ) -- ORG_ID
      , iv_user_name     => fnd_global.user_name       -- ���O�C���E���[�U��
      , iv_resp_name     => fnd_global.resp_name       -- ���O�C���E���[�U�E�Ӗ�
      , iv_doc_name      => NULL                       -- ������
      , iv_printer_name  => NULL                       -- �v�����^��
      , iv_request_id    => TO_CHAR( cn_request_id )   -- �v��ID
      , iv_nodata_msg    => NULL                       -- �f�[�^�Ȃ����b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
  /**********************************************************************************
   * Procedure Name   : ins_wholesale_pay
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_wholesale_pay(
    ov_errbuf                    OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode                   OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                    OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date              IN VARCHAR2   -- �x���N����
  , iv_selling_date              IN VARCHAR2   -- ����Ώ۔N����
  , iv_base_code                 IN VARCHAR2   -- ���_�R�[�h
  , iv_wholesale_vendor_code     IN VARCHAR2   -- �d����R�[�h
  , iv_bill_no                   IN VARCHAR2   -- �������ԍ�
  , iv_chain_code                IN VARCHAR2   -- �T���p�`�F�[���R�[�h
  , in_i                         IN NUMBER     -- LOOP�J�E���^
  , iv_no_condition              IN VARCHAR2   -- �T���}�X�^�Ȃ�
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'ins_wholesale_pay';     -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tax                   VARCHAR2(2)    DEFAULT NULL;              -- �ŋL��
    lv_stamp                 VARCHAR2(2)    DEFAULT NULL;              -- ��L��
    ln_normal_shop_pay_en_4  NUMBER         DEFAULT NULL;              -- �ʏ�X�[
    ln_just_shop_pay_en_4    NUMBER         DEFAULT NULL;              -- �����X�[
    ln_net_selling_price     NUMBER         DEFAULT NULL;              -- NET���i
    ln_accrued_en_3          NUMBER         DEFAULT NULL;              -- �ʏ�
    ln_accrued_en_3_c        VARCHAR2(2)    DEFAULT NULL;              -- �ʏ�_�`�F�b�N
    ln_accrued_en_4_1        NUMBER         DEFAULT NULL;              -- �g��1
    ln_accrued_en_4_1_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��1_�`�F�b�N
    ln_accrued_en_4_2        NUMBER         DEFAULT NULL;              -- �g��2
    ln_accrued_en_4_2_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��2_�`�F�b�N
    ln_accrued_en_4_3        NUMBER         DEFAULT NULL;              -- �g��3
    ln_accrued_en_4_3_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��3_�`�F�b�N
    ln_accrued_en_4_4        NUMBER         DEFAULT NULL;              -- �g��4
    ln_accrued_en_4_4_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��4_�`�F�b�N
    ln_accrued_en_4_5        NUMBER         DEFAULT NULL;              -- �g��5
    ln_accrued_en_4_5_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��5_�`�F�b�N
    ln_accrued_en_4_6        NUMBER         DEFAULT NULL;              -- �g��6
    ln_accrued_en_4_6_c      VARCHAR2(2)    DEFAULT NULL;              -- �g��6_�`�F�b�N
    ln_dedu_est_kbn_1        NUMBER         DEFAULT NULL;              -- �g��1_�T�����ϋ敪_
    ln_dedu_est_kbn_2        NUMBER         DEFAULT NULL;              -- �g��2_�T�����ϋ敪_
    ln_dedu_est_kbn_3        NUMBER         DEFAULT NULL;              -- �g��3_�T�����ϋ敪_
    ln_dedu_est_kbn_4        NUMBER         DEFAULT NULL;              -- �g��4_�T�����ϋ敪_
    ln_dedu_est_kbn_5        NUMBER         DEFAULT NULL;              -- �g��5_�T�����ϋ敪_
    ln_dedu_est_kbn_6        NUMBER         DEFAULT NULL;              -- �g��6_�T�����ϋ敪_
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �o�^�Ώۍ��ڌv�Z
    -- ===============================================
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================================
      -- ��(��)
      -- �ŗ�10%�̏ꍇ�A�łɈ��ݒ肷��B
      -- ===============================================
      IF ( g_target_tab( in_i ).tax_rate = g_lookup_stamp_tab( '2' ).tag  ) THEN
        lv_tax := g_lookup_stamp_tab( '2' ).meaning;
      END IF;
      -- ===============================================
      -- �P���`�F�b�N
      -- �����P���ƍT���}�X�^�P�����r
      -- ===============================================
      IF
      --�@�ʏ�P���ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_shop_pay_en_3;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�A�ʏ�P���Ɗg���P��1�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_1 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_1;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_1;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_1;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           IF gn_dedu_est_kbn_1 = 0 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_1 = 1 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�B�ʏ�P���Ɗg���P��2�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_2 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_2;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_2;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_2;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           IF gn_dedu_est_kbn_2 = 0 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_2 = 1 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�C�ʏ�P���Ɗg���P��3�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_3;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_3;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           IF gn_dedu_est_kbn_3 = 0 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_3 = 1 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�D�ʏ�P���Ɗg���P��4�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_4 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_4;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_4;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_4;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           IF gn_dedu_est_kbn_4 = 0 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_4 = 1 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�E�ʏ�P���Ɗg���P��5�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_5 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_5;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_5;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_5;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           IF gn_dedu_est_kbn_5 = 0 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_5 = 1 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�F�ʏ�P���Ɗg���P��6�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_3 - gn_accrued_en_4_6 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_6;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_6;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_6;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := g_lookup_stamp_tab( '3' ).meaning;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_C     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           IF gn_dedu_est_kbn_6 = 0 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_6 = 1 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
      ELSIF
      --�G�g���P��1�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_1 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_1;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_1;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_1;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           IF gn_dedu_est_kbn_1 = 0 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_1 = 1 THEN
              ln_accrued_en_4_1_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�H�g���P��2�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_2 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_2;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_2;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_2;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           IF gn_dedu_est_kbn_2 = 0 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_2 = 1 THEN
              ln_accrued_en_4_2_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�I�g���P��3�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_3 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_3;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_3;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           IF gn_dedu_est_kbn_3 = 0 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_3 = 1 THEN
              ln_accrued_en_4_3_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�J�g���P��4�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_4 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_4;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_4;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_4;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           IF gn_dedu_est_kbn_4 = 0 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_4 = 1 THEN
              ln_accrued_en_4_4_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�K�g���P��5�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_5 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_5;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_5;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_5;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           IF gn_dedu_est_kbn_5 = 0 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_5 = 1 THEN
              ln_accrued_en_4_5_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      ELSIF
      --�L�g���P��6�ƈ�v
         g_target_tab( in_i ).demand_unit_price - gn_accrued_en_4_6 = 0 THEN
           lv_stamp                := NULL;
           ln_normal_shop_pay_en_4 := gn_normal_shop_pay_en_4_6;
           ln_just_shop_pay_en_4   := gn_just_shop_pay_en_4_6;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3 - gn_accrued_en_4_6;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           IF gn_dedu_est_kbn_6 = 0 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '3' ).meaning;
           ELSIF gn_dedu_est_kbn_6 = 1 THEN
              ln_accrued_en_4_6_c     := g_lookup_stamp_tab( '4' ).meaning;
           ELSE NULL;
           END IF;
      ELSE
           lv_stamp                := g_lookup_stamp_tab( '1' ).meaning;
           ln_normal_shop_pay_en_4 := gn_shop_pay_en_3;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := gn_demand_en_3 - gn_accrued_en_3;
           ln_accrued_en_3         := gn_accrued_en_3;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := gn_accrued_en_4_1;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := gn_accrued_en_4_2;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := gn_accrued_en_4_3;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := gn_accrued_en_4_4;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := gn_accrued_en_4_5;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := gn_accrued_en_4_6;
           ln_accrued_en_4_6_c     := NULL;
      END IF;
      IF iv_no_condition = 'Y' THEN
           lv_stamp                := g_lookup_stamp_tab( '1' ).meaning;
           ln_normal_shop_pay_en_4 := NULL;
           ln_just_shop_pay_en_4   := NULL;
           ln_net_selling_price    := NULL;
           ln_accrued_en_3         := NULL;
           ln_accrued_en_3_c       := NULL;
           ln_accrued_en_4_1       := NULL;
           ln_accrued_en_4_1_c     := NULL;
           ln_accrued_en_4_2       := NULL;
           ln_accrued_en_4_2_c     := NULL;
           ln_accrued_en_4_3       := NULL;
           ln_accrued_en_4_3_c     := NULL;
           ln_accrued_en_4_4       := NULL;
           ln_accrued_en_4_4_c     := NULL;
           ln_accrued_en_4_5       := NULL;
           ln_accrued_en_4_5_c     := NULL;
           ln_accrued_en_4_6       := NULL;
           ln_accrued_en_4_6_c     := NULL;
      END IF;
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�o�^
      -- ===============================================
      INSERT INTO xxcok_wholesale_pay_check_list(
        wholesale_bill_detail_id                       -- �≮����������ID
      , p_payment_date                                 -- �x���N����(���̓p�����[�^)
      , p_selling_date                                 -- ����Ώ۔N����(���̓p�����[�^)
      , p_base_code                                    -- ���_�R�[�h(���̓p�����[�^)
      , p_vendor_code                                  -- �d����R�[�h(���̓p�����[�^)
      , p_bill_no                                      -- �������ԍ�(���̓p�����[�^)
      , p_deduction_chain_code                         -- �T���p�`�F�[��(���̓p�����[�^)
      , symbol1                                        -- �w�b�_�p�L���P
      , symbol1_description                            -- �w�b�_�p�L���P�E�v
      , symbol2                                        -- �w�b�_�p�L���Q
      , symbol2_description                            -- �w�b�_�p�L���Q�E�v
      , symbol2_tag                                    -- �w�b�_�p�L���Q�^�O
      , symbol3                                        -- �w�b�_�p�L���R
      , symbol3_description                            -- �w�b�_�p�L���R�E�v
      , symbol4                                        -- �w�b�_�p�L���S
      , symbol4_description                            -- �w�b�_�p�L���S�E�v
      , payment_date                                   -- �x���N����
      , bill_no                                        -- ������No.
      , base_code                                      -- ���_�R�[�h
      , base_name                                      -- ���_��
      , cust_code                                      -- �ڋq�R�[�h
      , cust_name                                      -- �ڋq����
      , deduction_chain_code                           -- �T���p�`�F�[���R�[�h
      , deduction_chain_name                           -- �T���p�`�F�[����
      , selling_date                                   -- ����Ώ۔N����
      , item_code                                      -- �i�ڃR�[�h
      , item_name                                      -- �i�ږ���
      , expansion_sales_type                           -- �g���敪
      , demand_qty                                     -- ��������
      , demand_unit_price                              -- �����P��
      , difference_amt                                 -- �[������
      , demand_amt                                     -- �������z
      , unit_type                                      -- �����P��
      , supplier_code                                  -- �d����R�[�h
      , supplier_name                                  -- �d���於
      , bank_name                                      -- ��s��
      , bank_branch_name                               -- �x�X��
      , bank_acct_type                                 -- �������
      , bank_acct_no                                   -- �����ԍ�
      , tax_rate                                       -- �ŗ�
      , tax                                            -- ��
      , stamp                                          -- ��
      , demand_en_3                                    -- ���l
      , shop_pay_en_3                                  -- �X�[(�~)
      , normal_shop_pay_en_4                           -- �ʏ�X�[
      , just_shop_pay_en_4                             -- �����X�[
      , net_selling_price                              -- NET���i
      , accrued_en_3                                   -- �ʏ�
      , accrued_en_3_c                                 -- �ʏ�_�`�F�b�N
      , accrued_en_4_1                                 -- �g��1
      , accrued_en_4_1_c                               -- �g��1_�`�F�b�N
      , accrued_en_4_2                                 -- �g��2
      , accrued_en_4_2_c                               -- �g��2_�`�F�b�N
      , accrued_en_4_3                                 -- �g��3
      , accrued_en_4_3_c                               -- �g��3_�`�F�b�N
      , accrued_en_4_4                                 -- �g��4
      , accrued_en_4_4_c                               -- �g��4_�`�F�b�N
      , accrued_en_4_5                                 -- �g��5
      , accrued_en_4_5_c                               -- �g��5_�`�F�b�N
      , accrued_en_4_6                                 -- �g��6
      , accrued_en_4_6_c                               -- �g��6_�`�F�b�N
      , no_data_message                                -- 0�����b�Z�[�W
      , created_by                                     -- �쐬��
      , creation_date                                  -- �쐬��
      , last_updated_by                                -- �ŏI�X�V��
      , last_update_date                               -- �ŏI�X�V��
      , last_update_login                              -- �ŏI�X�V���O�C��
      , request_id                                     -- �v��ID
      , program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                                     -- �R���J�����g�E�v���O����ID
      , program_update_date                            -- �v���O�����X�V��
      ) VALUES (
        g_target_tab( in_i ).wholesale_bill_detail_id  -- �≮����������ID
      , iv_payment_date                                -- �x���N����(���̓p�����[�^)
      , iv_selling_date                                -- ����Ώ۔N��(���̓p�����[�^)
      , iv_base_code                                   -- ���_�R�[�h(���̓p�����[�^)
      , iv_wholesale_vendor_code                       -- �d����R�[�h(���̓p�����[�^)
      , iv_bill_no                                     -- �������ԍ�(���̓p�����[�^)
      , iv_chain_code                                  -- �T���p�`�F�[��(���̓p�����[�^)
      , g_lookup_stamp_tab( '1' ).meaning              -- �w�b�_�p�L���P
      , g_lookup_stamp_tab( '1' ).description          -- �w�b�_�p�L���P�E�v
      , g_lookup_stamp_tab( '2' ).meaning              -- �w�b�_�p�L���Q
      , g_lookup_stamp_tab( '2' ).description          -- �w�b�_�p�L���Q�E�v
      , g_lookup_stamp_tab( '2' ).tag                  -- �w�b�_�p�L���Q�^�O
      , g_lookup_stamp_tab( '3' ).meaning              -- �w�b�_�p�L���R
      , g_lookup_stamp_tab( '3' ).description          -- �w�b�_�p�L���R�E�v
      , g_lookup_stamp_tab( '4' ).meaning              -- �w�b�_�p�L���S
      , g_lookup_stamp_tab( '4' ).description          -- �w�b�_�p�L���S�E�v
      , to_char(g_target_tab( in_i ).payment_date,'YYYY/MM/DD')
                                                       -- �x���N����
      , g_target_tab( in_i ).bill_no                   -- ������No.
      , g_target_tab( in_i ).base_code                 -- ���_�R�[�h
      , g_target_tab( in_i ).base_name                 -- ���_��
      , g_target_tab( in_i ).cust_code                 -- �ڋq�R�[�h
      , g_target_tab( in_i ).cust_name                 -- �ڋq����
      , g_target_tab( in_i ).deduction_chain_code      -- �T���p�`�F�[���R�[�h
      , g_target_tab( in_i ).deduction_chain_name      -- �T���p�`�F�[����
      , to_char(g_target_tab( in_i ).selling_date,'YYYY/MM/DD')
                                                       -- ����Ώ۔N��
      , g_target_tab( in_i ).item_code                 -- �i�ڃR�[�h
      , g_target_tab( in_i ).item_name                 -- �i�ږ���
      , g_target_tab( in_i ).expansion_sales_type      -- �g���敪
      , g_target_tab( in_i ).demand_qty                -- ��������
      , g_target_tab( in_i ).demand_unit_price         -- �����P��
      , g_target_tab( in_i ).difference_amt            -- �[������
      , g_target_tab( in_i ).demand_amt                -- �������z
      , g_target_tab( in_i ).demand_unit_type          -- �����P��
      , g_target_tab( in_i ).supplier_code             -- �d����R�[�h
      , g_target_tab( in_i ).supplier_name             -- �d���於
      , g_target_tab( in_i ).bank_name                 -- ��s��
      , g_target_tab( in_i ).bank_branch_name          -- �x�X��
      , g_target_tab( in_i ).bank_account_type         -- �������
      , g_target_tab( in_i ).bank_account_num          -- �����ԍ�
      , g_target_tab( in_i ).tax_rate                  -- �ŗ�
      , lv_tax                                         -- ��
      , lv_stamp                                       -- ��
      , gn_demand_en_3                                 -- ���l
      , gn_shop_pay_en_3                               -- �X�[(�~)
      , ln_normal_shop_pay_en_4                        -- �ʏ�X�[
      , ln_just_shop_pay_en_4                          -- �����X�[
      , ln_net_selling_price                           -- NET���i
      , ln_accrued_en_3                                -- �ʏ�
      , ln_accrued_en_3_c                              -- �ʏ�_�`�F�b�N
      , ln_accrued_en_4_1                              -- �g��1
      , ln_accrued_en_4_1_c                            -- �g��1_�`�F�b�N
      , ln_accrued_en_4_2                              -- �g��2
      , ln_accrued_en_4_2_c                            -- �g��2_�`�F�b�N
      , ln_accrued_en_4_3                              -- �g��3
      , ln_accrued_en_4_3_c                            -- �g��3_�`�F�b�N
      , ln_accrued_en_4_4                              -- �g��4
      , ln_accrued_en_4_4_c                            -- �g��4_�`�F�b�N
      , ln_accrued_en_4_5                              -- �g��5
      , ln_accrued_en_4_5_c                            -- �g��5_�`�F�b�N
      , ln_accrued_en_4_6                              -- �g��6
      , ln_accrued_en_4_6_c                           -- �g��6_�`�F�b�N
      , NULL                                           -- 0�����b�Z�[�W
      , cn_created_by                                  -- �쐬��
      , SYSDATE                                        -- �쐬��
      , cn_last_updated_by                             -- �ŏI�X�V��
      , SYSDATE                                        -- �ŏI�X�V��
      , cn_last_update_login                           -- �ŏI�X�V���O�C��
      , cn_request_id                                  -- �v��ID
      , cn_program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                                  -- �R���J�����g�E�v���O����ID
      , SYSDATE                                        -- �v���O�����X�V��
      );
    ELSE
      -- ===============================================
      -- �Ώی���0�������[�N�e�[�u���f�[�^�o�^
      -- ===============================================
      INSERT INTO xxcok_wholesale_pay_check_list(
        p_payment_date                                 -- �x���N����(���̓p�����[�^)
      , p_selling_date                                 -- ����Ώ۔N����(���̓p�����[�^)
      , p_base_code                                    -- ���_�R�[�h(���̓p�����[�^)
      , p_vendor_code                                  -- �d����R�[�h(���̓p�����[�^)
      , p_bill_no                                      -- �������ԍ�(���̓p�����[�^)
      , p_deduction_chain_code                         -- �T���p�`�F�[��(���̓p�����[�^)
       , no_data_message                               -- 0�����b�Z�[�W
      , created_by                                     -- �쐬��
      , creation_date                                  -- �쐬��
      , last_updated_by                                -- �ŏI�X�V��
      , last_update_date                               -- �ŏI�X�V��
      , last_update_login                              -- �ŏI�X�V���O�C��
      , request_id                                     -- �v��ID
      , program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                                     -- �R���J�����g�E�v���O����ID
      , program_update_date                            -- �v���O�����X�V��
      ) VALUES (
        iv_payment_date                                -- �x���N����(���̓p�����[�^)
      , iv_selling_date                                -- ����Ώ۔N��(���̓p�����[�^)
      , iv_base_code                                   -- ���_�R�[�h(���̓p�����[�^)
      , iv_wholesale_vendor_code                       -- �d����R�[�h(���̓p�����[�^)
      , iv_bill_no                                     -- �������ԍ�(���̓p�����[�^)
      , iv_chain_code                                  -- �T���p�`�F�[��(���̓p�����[�^)
      , gv_no_data_msg                                 -- 0�����b�Z�[�W
      , cn_created_by                                  -- �쐬��
      , SYSDATE                                        -- �쐬��
      , cn_last_updated_by                             -- �ŏI�X�V��
      , SYSDATE                                        -- �ŏI�X�V��
      , cn_last_update_login                           -- �ŏI�X�V���O�C��
      , cn_request_id                                  -- �v��ID
      , cn_program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                                  -- �R���J�����g�E�v���O����ID
      , SYSDATE                                        -- �v���O�����X�V��
      );
    END IF;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_wholesale_pay;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_date          IN  VARCHAR2  -- ����Ώ۔N����
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN  VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN  VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN  VARCHAR2  -- �T���p�`�F�[���R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'get_target_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf         VARCHAR2(5000)  DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)     DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000)  DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg         VARCHAR2(5000)  DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lv_no_condition   VARCHAR2(1)     DEFAULT NULL;              -- �T���}�X�^�Ȃ�
    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �J�[�\��
    -- ===============================================
    OPEN  g_target_cur(
      iv_payment_date          -- �x���N����
    , iv_selling_date          -- ����Ώ۔N����
    , iv_base_code             -- ���_�R�[�h
    , iv_wholesale_vendor_code -- �d����R�[�h
    , iv_bill_no               -- �������ԍ�
    , iv_chain_code            -- �T���p�`�F�[���R�[�h
    );
    FETCH g_target_cur BULK COLLECT INTO g_target_tab;
    CLOSE g_target_cur;
    -- ===============================================
    -- �Ώی����擾
    -- ===============================================
    gn_target_cnt := g_target_tab.COUNT;
    IF ( gn_target_cnt = 0 ) THEN
      -- ===============================================
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�o�^(A-4)
      -- ===============================================
      ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
        , iv_payment_date          =>  iv_payment_date          -- �x���N����
        , iv_selling_date          =>  iv_selling_date          -- ����Ώ۔N����
        , iv_base_code             =>  iv_base_code             -- ���_�R�[�h
        , iv_wholesale_vendor_code =>  iv_wholesale_vendor_code -- �d����R�[�h
        , iv_bill_no               =>  iv_bill_no               -- �������ԍ�
        , iv_chain_code            =>  iv_chain_code            -- �T���p�`�F�[���R�[�h
        , in_i                     =>  cn_number_0              -- LOOP�J�E���^
        , iv_no_condition          =>  lv_no_condition          -- �T���}�X�^�Ȃ�
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<main_loop>>
      FOR i IN g_target_tab.FIRST .. g_target_tab.LAST LOOP
        -- ===============================================
        -- �T���}�X�^���擾(A-3)
        -- ===============================================
        BEGIN
          SELECT   SUM(ch1.demand_en_3)                                                                                     demand_en_3                 --����(�~)
                  ,SUM(ch1.shop_pay_en_3)                                                                                   shop_pay_en_3               --�X�[(�~)
                  ,SUM(ch1.accrued_en_3)                                                                                    accrued_en_3                --�����v�R(�~)
                  ,SUM(ch1.normal_shop_pay_en_4_1)                                                                          normal_shop_pay_en_4_1      --�ʏ�X�[(�~)_1
                  ,SUM(ch1.normal_shop_pay_en_4_2)                                                                          normal_shop_pay_en_4_2      --�ʏ�X�[(�~)_2
                  ,SUM(ch1.normal_shop_pay_en_4_3)                                                                          normal_shop_pay_en_4_3      --�ʏ�X�[(�~)_3
                  ,SUM(ch1.normal_shop_pay_en_4_4)                                                                          normal_shop_pay_en_4_4      --�ʏ�X�[(�~)_4
                  ,SUM(ch1.normal_shop_pay_en_4_5)                                                                          normal_shop_pay_en_4_5      --�ʏ�X�[(�~)_5
                  ,SUM(ch1.normal_shop_pay_en_4_6)                                                                          normal_shop_pay_en_4_6      --�ʏ�X�[(�~)_6
                  ,SUM(ch1.just_shop_pay_en_4_1)                                                                            just_shop_pay_en_4_1        --����X�[(�~)_1
                  ,SUM(ch1.just_shop_pay_en_4_2)                                                                            just_shop_pay_en_4_2        --����X�[(�~)_2
                  ,SUM(ch1.just_shop_pay_en_4_3)                                                                            just_shop_pay_en_4_3        --����X�[(�~)_3
                  ,SUM(ch1.just_shop_pay_en_4_4)                                                                            just_shop_pay_en_4_4        --����X�[(�~)_4
                  ,SUM(ch1.just_shop_pay_en_4_5)                                                                            just_shop_pay_en_4_5        --����X�[(�~)_5
                  ,SUM(ch1.just_shop_pay_en_4_6)                                                                            just_shop_pay_en_4_6        --����X�[(�~)_6
                  ,SUM(ch1.just_condition_en_4_1)                                                                           just_condition_en_4_1       --�������(�~)_1
                  ,SUM(ch1.just_condition_en_4_2)                                                                           just_condition_en_4_2       --�������(�~)_2
                  ,SUM(ch1.just_condition_en_4_3)                                                                           just_condition_en_4_3       --�������(�~)_3
                  ,SUM(ch1.just_condition_en_4_4)                                                                           just_condition_en_4_4       --�������(�~)_4
                  ,SUM(ch1.just_condition_en_4_5)                                                                           just_condition_en_4_5       --�������(�~)_5
                  ,SUM(ch1.just_condition_en_4_6)                                                                           just_condition_en_4_6       --�������(�~)_6
                  ,SUM(ch1.accrued_en_4_1)                                                                                  accrued_en_4_1              --�����v�S(�~)_1
                  ,SUM(ch1.dedu_est_kbn_1)                                                                                  dedu_est_kbn_1              --�����v�S(�~)_1_�T�����ϋ敪
                  ,SUM(ch1.accrued_en_4_2)                                                                                  accrued_en_4_2              --�����v�S(�~)_2
                  ,SUM(ch1.dedu_est_kbn_2)                                                                                  dedu_est_kbn_2              --�����v�S(�~)_2_�T�����ϋ敪
                  ,SUM(ch1.accrued_en_4_3)                                                                                  accrued_en_4_3              --�����v�S(�~)_3
                  ,SUM(ch1.dedu_est_kbn_3)                                                                                  dedu_est_kbn_3              --�����v�S(�~)_3_�T�����ϋ敪
                  ,SUM(ch1.accrued_en_4_4)                                                                                  accrued_en_4_4              --�����v�S(�~)_4
                  ,SUM(ch1.dedu_est_kbn_4)                                                                                  dedu_est_kbn_4              --�����v�S(�~)_4_�T�����ϋ敪
                  ,SUM(ch1.accrued_en_4_5)                                                                                  accrued_en_4_5              --�����v�S(�~)_5
                  ,SUM(ch1.dedu_est_kbn_5)                                                                                  dedu_est_kbn_5              --�����v�S(�~)_5_�T�����ϋ敪
                  ,SUM(ch1.accrued_en_4_6)                                                                                  accrued_en_4_6              --�����v�S(�~)_6
                  ,SUM(ch1.dedu_est_kbn_6)                                                                                  dedu_est_kbn_6              --�����v�S(�~)_6_�T�����ϋ敪
          INTO
                   gn_demand_en_3
                  ,gn_shop_pay_en_3
                  ,gn_accrued_en_3
                  ,gn_normal_shop_pay_en_4_1
                  ,gn_normal_shop_pay_en_4_2
                  ,gn_normal_shop_pay_en_4_3
                  ,gn_normal_shop_pay_en_4_4
                  ,gn_normal_shop_pay_en_4_5
                  ,gn_normal_shop_pay_en_4_6
                  ,gn_just_shop_pay_en_4_1
                  ,gn_just_shop_pay_en_4_2
                  ,gn_just_shop_pay_en_4_3
                  ,gn_just_shop_pay_en_4_4
                  ,gn_just_shop_pay_en_4_5
                  ,gn_just_shop_pay_en_4_6
                  ,gn_just_condition_en_4_1
                  ,gn_just_condition_en_4_2
                  ,gn_just_condition_en_4_3
                  ,gn_just_condition_en_4_4
                  ,gn_just_condition_en_4_5
                  ,gn_just_condition_en_4_6
                  ,gn_accrued_en_4_1
                  ,gn_dedu_est_kbn_1
                  ,gn_accrued_en_4_2
                  ,gn_dedu_est_kbn_2
                  ,gn_accrued_en_4_3
                  ,gn_dedu_est_kbn_3
                  ,gn_accrued_en_4_4
                  ,gn_dedu_est_kbn_4
                  ,gn_accrued_en_4_5
                  ,gn_dedu_est_kbn_5
                  ,gn_accrued_en_4_6
                  ,gn_dedu_est_kbn_6
          FROM
                  (SELECT  ROW_NUMBER() OVER(PARTITION BY ch2.dedu_type ORDER BY ch2.accrued_en_4 desc)                     rownumber                   --�g���P������
                          ,ch2.dedu_type                                                                                    dedu_type                   --�T���^�C�v
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.demand_en_3
                             ELSE            NULL
                           END                                                                                              demand_en_3                 --����(�~)
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.shop_pay_en_3
                             ELSE            NULL
                           END                                                                                              shop_pay_en_3               --�X�[(�~)
                          ,CASE ch2.dedu_type
                             WHEN '030' THEN ch2.accrued_en_3
                             ELSE            NULL
                           END                                                                                              accrued_en_3                --�����v�R(�~)
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_1      --�ʏ�X�[(�~)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_2      --�ʏ�X�[(�~)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_3      --�ʏ�X�[(�~)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_4      --�ʏ�X�[(�~)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_5      --�ʏ�X�[(�~)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.normal_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              normal_shop_pay_en_4_6      --�ʏ�X�[(�~)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_1        --����X�[(�~)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_2        --����X�[(�~)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_3        --����X�[(�~)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_4        --����X�[(�~)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_5        --����X�[(�~)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.just_shop_pay_en_4
                            ELSE             NULL
                           END                                                                                              just_shop_pay_en_4_6        --����X�[(�~)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_1       --�������(�~)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_2       --�������(�~)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_3       --�������(�~)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_4       --�������(�~)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_5       --�������(�~)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.just_condition_en_4
                            ELSE             NULL
                           END                                                                                              just_condition_en_4_6       --�������(�~)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_1              --�����v�S(�~)_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0401' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_1              --�T�����ϋ敪_1
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_2              --�����v�S(�~)_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0402' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_2              --�T�����ϋ敪_2
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_3              --�����v�S(�~)_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0403' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_3              --�T�����ϋ敪_3
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_4              --�����v�S(�~)_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0404' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_4              --�T�����ϋ敪_4
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_5              --�����v�S(�~)_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0405' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_5              --�T�����ϋ敪_5
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.accrued_en_4
                            ELSE             NULL
                           END                                                                                              accrued_en_4_6              --�����v�S(�~)_6
                          ,CASE ch2.dedu_type || ROW_NUMBER() OVER(PARTITION BY dedu_type ORDER BY accrued_en_4 desc) 
                             WHEN '0406' THEN ch2.dedu_est_kbn
                            ELSE             NULL
                           END                                                                                              dedu_est_kbn_6              --�T�����ϋ敪_6
                   FROM 
                                  (SELECT /*+ INDEX(xch XXCOK_CONDITION_HEADER_N07)*/
                                          xch.condition_id                                                                  condition_id                --�T������ID
                                         ,xch.condition_no                                                                  condition_no                --�T���ԍ�
                                         ,xch.enabled_flag_h                                                                enabled_flag_h              --�w�b�_�L���t���O
                                         ,xch.corp_code                                                                     corp_code                   --��ƃR�[�h
                                         ,xch.deduction_chain_code                                                          deduction_chain_code        --�T���p�`�F�[���R�[�h
                                         ,xch.customer_code                                                                 customer_code               --�ڋq�R�[�h
                                         ,xch.data_type                                                                     data_type                   --�f�[�^���
                                         ,xch.start_date_active                                                             start_date_active           --�J�n��
                                         ,xch.end_date_active                                                               end_date_active             --�I����
                                         ,xcl.condition_line_id                                                             condition_line_id           --�T���ڍ�ID
                                         ,xcl.enabled_flag_l                                                                enabled_flag_l              --���חL���t���O
                                         ,xcl.item_code                                                                     item_code                   --�i�ڃR�[�h
                                         ,xcl.demand_en_3                                                                   demand_en_3                 --����(�~)
                                         ,xcl.shop_pay_en_3                                                                 shop_pay_en_3               --�X�[(�~)
                                         ,xcl.compensation_en_3                                                             compensation_en_3           --��U(�~)
                                         ,xcl.wholesale_margin_en_3                                                         wholesale_margin_en_3       --�≮�}�[�W��(�~)
                                         ,xcl.wholesale_margin_per_3                                                        wholesale_margin_per_3      --�≮�}�[�W��(��)
                                         ,xcl.accrued_en_3                                                                  accrued_en_3                --�����v�R(�~)
                                         ,xcl.normal_shop_pay_en_4                                                          normal_shop_pay_en_4        --�ʏ�X�[(�~)
                                         ,xcl.just_shop_pay_en_4                                                            just_shop_pay_en_4          --����X�[(�~)
                                         ,xcl.just_condition_en_4                                                           just_condition_en_4         --�������(�~)
                                         ,xcl.wholesale_adj_margin_en_4                                                     wholesale_adj_margin_en_4   --�≮�}�[�W���C��(�~)
                                         ,xcl.wholesale_adj_margin_per_4                                                    wholesale_adj_margin_per_4  --�≮�}�[�W���C��(��)
                                         ,xcl.accrued_en_4                                                                  accrued_en_4                --�����v�S(�~)
                                         ,flv.attribute2                                                                    dedu_type                   --�T���^�C�v
                                         ,xca.intro_chain_code2                                                             intro_chain_code2           --�T���p�`�F�[���R�[�h�i�ڋq�w��j
                                         ,0                                                                                 dedu_est_kbn                --�T�����ϋ敪
                                   FROM   apps.xxcok_condition_header xch
                                         ,apps.xxcok_condition_lines xcl
                                         ,apps.fnd_lookup_values flv
                                         ,apps.xxcmm_cust_accounts xca
                                   WHERE  xch.condition_id          = xcl.condition_id
                                   AND    xch.start_date_active     <= g_target_tab( i ).selling_date
                                   AND    xch.end_date_active       >= ADD_MONTHS(g_target_tab( i ).selling_date,-1) + 1
                                   AND    xch.enabled_flag_h        = 'Y'
                                   AND    xcl.item_code             = g_target_tab( i ).item_code                                                       --A-2�Ŏ擾�����u�i�ڃR�[�h�v
                                   AND    xcl.enabled_flag_l        = 'Y'
                                   AND    flv.lookup_type           = 'XXCOK1_DEDUCTION_DATA_TYPE'
                                   AND    flv.language              = 'JA'
                                   AND    flv.lookup_code           = xch.data_type
                                   AND    flv.enabled_flag          = 'Y'
                                   AND    gd_process_date BETWEEn nvl(flv.start_date_active, gd_process_date)
                                                                             AND     nvl(flv.end_date_active, gd_process_date)                          -- A-1�Ŏ擾�����Ɩ����t
                                   AND    flv.attribute2           IN ('030','040')
                                   AND    xca.customer_code(+)      = xch.customer_code
                                   AND    xch.deduction_chain_code || xca.intro_chain_code2 = g_target_tab( i ).deduction_chain_code                    --A-2�Ŏ擾�����T���p�`�F�[���R�[�h
                                   UNION ALL
                                   SELECT /*+ INDEX(xch XXCOK_CONDITION_HEADER_EST_N07)*/
                                          xch.condition_id                                                                  condition_id                --�T������ID
                                         ,xch.condition_no                                                                  condition_no                --�T���ԍ�
                                         ,xch.enabled_flag_h                                                                enabled_flag_h              --�w�b�_�L���t���O
                                         ,xch.corp_code                                                                     corp_code                   --��ƃR�[�h
                                         ,xch.deduction_chain_code                                                          deduction_chain_code        --�T���p�`�F�[���R�[�h
                                         ,xch.customer_code                                                                 customer_code               --�ڋq�R�[�h
                                         ,xch.data_type                                                                     data_type                   --�f�[�^���
                                         ,xch.start_date_active                                                             start_date_active           --�J�n��
                                         ,xch.end_date_active                                                               end_date_active             --�I����
                                         ,xcl.condition_line_id                                                             condition_line_id           --�T���ڍ�ID
                                         ,xcl.enabled_flag_l                                                                enabled_flag_l              --���חL���t���O
                                         ,xcl.item_code                                                                     item_code                   --�i�ڃR�[�h
                                         ,xcl.demand_en_3                                                                   demand_en_3                 --����(�~)
                                         ,xcl.shop_pay_en_3                                                                 shop_pay_en_3               --�X�[(�~)
                                         ,xcl.compensation_en_3                                                             compensation_en_3           --��U(�~)
                                         ,xcl.wholesale_margin_en_3                                                         wholesale_margin_en_3       --�≮�}�[�W��(�~)
                                         ,xcl.wholesale_margin_per_3                                                        wholesale_margin_per_3      --�≮�}�[�W��(��)
                                         ,xcl.accrued_en_3                                                                  accrued_en_3                --�����v�R(�~)
                                         ,xcl.normal_shop_pay_en_4                                                          normal_shop_pay_en_4        --�ʏ�X�[(�~)
                                         ,xcl.just_shop_pay_en_4                                                            just_shop_pay_en_4          --����X�[(�~)
                                         ,xcl.just_condition_en_4                                                           just_condition_en_4         --�������(�~)
                                         ,xcl.wholesale_adj_margin_en_4                                                     wholesale_adj_margin_en_4   --�≮�}�[�W���C��(�~)
                                         ,xcl.wholesale_adj_margin_per_4                                                    wholesale_adj_margin_per_4  --�≮�}�[�W���C��(��)
                                         ,xcl.accrued_en_4                                                                  accrued_en_4                --�����v�S(�~)
                                         ,flv.attribute2                                                                    dedu_type                   --�T���^�C�v
                                         ,xca.intro_chain_code2                                                             intro_chain_code2           --�T���p�`�F�[���R�[�h�i�ڋq�w��j
                                         ,1                                                                                 dedu_est_kbn                --�T�����ϋ敪
                                   FROM   apps.xxcok_condition_header_est xch
                                         ,apps.xxcok_condition_lines_est xcl
                                         ,apps.fnd_lookup_values flv
                                         ,apps.xxcmm_cust_accounts xca
                                   WHERE  xch.condition_id          = xcl.condition_id
                                   AND    xch.start_date_active     <= g_target_tab( i ).selling_date
                                   AND    xch.end_date_active       >= ADD_MONTHS(g_target_tab( i ).selling_date,-1) + 1
                                   AND    xch.enabled_flag_h        = 'Y'
                                   AND    xcl.item_code             = g_target_tab( i ).item_code                                                       --A-2�Ŏ擾�����u�i�ڃR�[�h�v
                                   AND    xcl.enabled_flag_l        = 'Y'
                                   AND    flv.lookup_type           = 'XXCOK1_DEDUCTION_DATA_TYPE_EST'
                                   AND    flv.language              = 'JA'
                                   AND    flv.lookup_code           = xch.data_type
                                   AND    flv.enabled_flag          = 'Y'
                                   AND    gd_process_date BETWEEN nvl(flv.start_date_active, gd_process_date)
                                                                             AND     nvl(flv.end_date_active, gd_process_date)                          -- A-1�Ŏ擾�����Ɩ����t
                                   AND    flv.attribute2           IN ('030','040')
                                   AND    xca.customer_code(+)      = xch.customer_code
                                   AND    xch.deduction_chain_code || xca.intro_chain_code2 = g_target_tab( i ).deduction_chain_code                    --A-2�Ŏ擾�����T���p�`�F�[���R�[�h
                                  )ch2
                  )ch1  ;
            lv_no_condition := 'N';
        EXCEPTION
          WHEN no_data_found THEN
            lv_no_condition := 'Y';
        END;
--
        -- ===============================================
        -- ���[�N�e�[�u���f�[�^�o�^(A-4)
        -- ===============================================
        ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
        , iv_payment_date          =>  iv_payment_date          -- �x���N����
        , iv_selling_date          =>  iv_selling_date          -- ����Ώ۔N����
        , iv_base_code             =>  iv_base_code             -- ���_�R�[�h
        , iv_wholesale_vendor_code =>  iv_wholesale_vendor_code -- �d����R�[�h
        , iv_bill_no               =>  iv_bill_no               -- �������ԍ�
        , iv_chain_code            =>  iv_chain_code            -- �T���p�`�F�[���R�[�h
        , in_i                     =>  i                        -- LOOP�J�E���^
        , iv_no_condition          =>  lv_no_condition          -- �T���}�X�^�Ȃ�
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP main_loop;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_date          IN  VARCHAR2  -- ����Ώ۔N����
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN  VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN  VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN  VARCHAR2  -- �T���p�`�F�[���R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(10) := 'init';     -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    ld_chk_date DATE           DEFAULT NULL;              -- �`�F�b�N�p�ϐ�
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    ln_cnt      NUMBER;                                   -- �d�������J�E���^
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt             EXCEPTION;
    dup_tax_rate_expt          EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �v���O�������͍��ڂ��o��
    -- ===============================================
    -- �x���N����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10829
                  , iv_token_name1  => cv_token_pay_date
                  , iv_token_value1 => iv_payment_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ����Ώ۔N����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10830
                  , iv_token_name1  => cv_token_target_date
                  , iv_token_value1 => iv_selling_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ���_�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10831
                  , iv_token_name1  => cv_token_base_code
                  , iv_token_value1 => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �d����R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10832
                  , iv_token_name1  => cv_token_supplier_code
                  , iv_token_value1 => iv_wholesale_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �������ԍ�
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10833
                  , iv_token_name1  => cv_token_bill_no
                  , iv_token_value1 => iv_bill_no
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �T���p�`�F�[���R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_10834
                  , iv_token_name1  => cv_token_chain_code
                  , iv_token_value1 => iv_chain_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- �v���t�@�C���擾(�݌ɑg�D�R�[�h_�c�Ƒg�D)
    -- ===============================================
    gv_org_code_sales := FND_PROFILE.VALUE( cv_prof_org_code_sales );
    IF ( gv_org_code_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�c�ƒP��ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �݌ɑg�DID�擾
    -- ===============================================
    gn_org_id_sales := xxcoi_common_pkg.get_organization_id( gv_org_code_sales );
    IF ( gn_org_id_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00013
                    , iv_token_name1  => cv_token_org_code
                    , iv_token_value1 => gv_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �Ɩ��������t�擾
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �N�C�b�N�R�[�h�擾(�≮�����P���`�F�b�N���X�g�L��)
    -- ===============================================
    <<lookup_stamp_loop>>
    FOR lookup_stamp_rec IN lookup_stamp_cur LOOP
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).meaning     := lookup_stamp_rec.meaning;
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).description := lookup_stamp_rec.description;
      g_lookup_stamp_tab( lookup_stamp_rec.lookup_code ).tag         := lookup_stamp_rec.tag;
    END LOOP lookup_stamp_loop;
    IF ( g_lookup_stamp_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_tax_pay_check
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �ŗ������̏d���`�F�b�N
    -- ===============================================
    SELECT COUNT(1) AS cnt
    INTO   ln_cnt
    FROM   fnd_lookup_values  v1
          ,fnd_lookup_values  v2
    WHERE  v1.lookup_type             = cv_lookup_tax_code_his
    AND    v2.lookup_type             = cv_lookup_tax_code_his
    AND    v1.enabled_flag            = 'Y'
    AND    v2.enabled_flag            = 'Y'
    AND    ( ( v1.start_date_active  >= v2.start_date_active
    AND        v1.start_date_active  <= v2.end_date_active )
      OR     ( v1.end_date_active    >= v2.start_date_active
    AND        v1.end_date_active    <= v2.end_date_active ) )
    AND    v1.tag                     = v2.tag
    AND    v1.lookup_code            <> v2.lookup_code
    ;
    -- �d���f�[�^��1���ł�����΃G���[
    IF ( ln_cnt > 0 ) THEN
      RAISE dup_tax_rate_expt;
    END IF;
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
    WHEN dup_tax_rate_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10566
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      IF ( lookup_stamp_cur%ISOPEN ) THEN
        CLOSE lookup_stamp_cur;
      END IF;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_date          IN  VARCHAR2  -- ����Ώ۔N����
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN  VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN  VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN  VARCHAR2  -- �T���p�`�F�[���R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'submain';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_date          => iv_selling_date          -- ����Ώ۔N����
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- �d����R�[�h
    , iv_bill_no               => iv_bill_no               -- �������ԍ�
    , iv_chain_code            => iv_chain_code            -- �T���p�`�F�[���R�[�h
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �Ώۃf�[�^�擾(A-2)�E�T���}�X�^���擾(A-3)�E���[�N�e�[�u���f�[�^�o�^(A-4)
    -- ===============================================
    get_target_data(
      ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_date          => iv_selling_date          -- ����Ώ۔N����
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- �d����R�[�h
    , iv_bill_no               => iv_bill_no               -- �������ԍ�
    , iv_chain_code            => iv_chain_code            -- �T���p�`�F�[���R�[�h
  );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�m��
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF�N��(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�폜(A-6)
    -- ===============================================
    del_wholesale_pay(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_date          IN  VARCHAR2  -- ����Ώ۔N��
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN  VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN  VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN  VARCHAR2  -- �T���p�`�F�[���R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(10) := 'main';        -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- �I�����b�Z�[�W�R�[�h
    lb_retcode       BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => cv_which
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_date          => iv_selling_date          -- ����Ώ۔N��
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_wholesale_vendor_code => iv_wholesale_vendor_code -- �d����R�[�h
    , iv_bill_no               => iv_bill_no               -- �������ԍ�
    , iv_chain_code            => iv_chain_code            -- �T���p�`�F�[���R�[�h
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line => cn_number_0    -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errbuf
                    , in_new_line => cn_number_1
                    );
    END IF;
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90000
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
    ELSE
      IF ( gn_target_cnt = cn_number_0 ) THEN
        gn_normal_cnt := cn_number_0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90001
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90002
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_1
                  );
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    ELSE
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK024A40R;
/
