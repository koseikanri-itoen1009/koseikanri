CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A04C(body)
 * Description      : �T���p���ѐU�փf�[�^�̍쐬�i�U�֊����j
 * MD.050           : �T���p���ѐU�փf�[�^�̍쐬�i�U�֊����j MD050_COK_024_A04
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  data_delite            �T���p���ѐU�փf�[�^�폜����(A-2)
 *  selling_from_loop      ����U�֌����̒��o(A-3)
 *  selling_to_loop        ����U�֐���̒��o(A-4)
 *  insert_xsti            ������ѐU�֐���̓o�^(A-6)
 *  update_xsti            �`�[�ԍ��X�V(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/04/08    1.0   Y.Nakajima       �V�K�쐬
 *  2020/06/15    1.1   K.Kanada         �㑱�@�\��PT�Ή��ŏ��i�敪�̕ҏW��ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK024A04C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_coi           CONSTANT VARCHAR2(10)    := 'XXCOI';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';
  cv_msg_cok_00045                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00045';
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';
  cv_msg_cok_10452                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10452';
  cv_msg_cok_10463                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10463';
--
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
--
  cv_msg_coi_00006                 CONSTANT VARCHAR2(50)    := 'APP-XXCOI1-00006';
  -- �g�[�N��
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_customer_code             CONSTANT VARCHAR2(30)    := 'CUSTOMER_CODE';
  cv_tkn_customer_name             CONSTANT VARCHAR2(30)    := 'CUSTOMER_NAME';
  cv_tkn_dlv_uom_code              CONSTANT VARCHAR2(30)    := 'DLV_UOM_CODE';
  cv_tkn_from_customer_code        CONSTANT VARCHAR2(30)    := 'FROM_CUSTOMER_CODE';
  cv_tkn_from_location_code        CONSTANT VARCHAR2(30)    := 'FROM_LOCATION_CODE';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_tanto_code                CONSTANT VARCHAR2(30)    := 'TANTO_CODE';
  cv_tkn_tanto_loc_code            CONSTANT VARCHAR2(30)    := 'TANTO_LOC_CODE';
  cv_tkn_org_code                  CONSTANT VARCHAR2(30)    := 'ORG_CODE_TOK';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- ��v����ID
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOS1_PAYMENT_DISCOUNTS_CODE';     -- �����l��
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOI1_ORGANIZATION_CODE';          -- �݌ɑg�D�R�[�h
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_VENDOR_DUMMY_CODE';          -- �d����_�~�[�R�[�h
  -- ���̓p�����[�^�E�����
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- ����
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- �m��
  -- �ڋq�敪
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- �ڋq
  -- �ڋq�ǉ����E������ѐU��
  cv_xca_transfer_div_on           CONSTANT VARCHAR2(1)     := '1';  -- ���ѐU�ւ���
  -- �ڋq�X�e�[�^�X
  cv_customer_status_30            CONSTANT VARCHAR2(2)     := '30'; -- ���F��
  cv_customer_status_40            CONSTANT VARCHAR2(2)     := '40'; -- �ڋq
  cv_customer_status_50            CONSTANT VARCHAR2(2)     := '50'; -- �x�~
  -- �ڋq�g�p�ړI
  cv_site_use_code_ship            CONSTANT VARCHAR2(10)    := 'SHIP_TO'; -- �o�א�
  cv_site_use_code_bill            CONSTANT VARCHAR2(10)    := 'BILL_TO'; -- ������
  -- �̔����сE�[�i�`�[�敪
  cv_invoice_class_01              CONSTANT VARCHAR2(1)     := '1';  -- �[�i
  cv_invoice_class_02              CONSTANT VARCHAR2(1)     := '2';  -- �ԕi
  cv_invoice_class_03              CONSTANT VARCHAR2(1)     := '3';  -- �[�i����
  cv_invoice_class_04              CONSTANT VARCHAR2(1)     := '4';  -- �ԕi����
  -- ������ѐU�֏��e�[�u���E�U��߂��t���O
  cv_xsti_correction_flag_off      CONSTANT VARCHAR2(1)     := '0';  -- �I�t
  -- ������ѐU�֏��e�[�u���E����m��t���O
  cv_xsti_decision_flag_news       CONSTANT VARCHAR2(1)     := '0';  -- ����
  -- ������ѐU�֏��e�[�u���E���nIF�t���O
  cv_xsti_info_if_flag_no          CONSTANT VARCHAR2(1)     := '0';  -- IF����
  -- ������ѐU�֏��e�[�u���E�d��쐬�t���O
  cv_xsti_gl_if_flag_no            CONSTANT VARCHAR2(1)     := '0';  -- �d��쐬����
  -- �����t���O
  cv_invalid_flag_valid            CONSTANT VARCHAR2(1)     := '0';  -- �L��
  -- �����U�֋敪
  cv_selling_trns_type_trns        CONSTANT VARCHAR2(1)     := '0';  -- �U�֊���
  -- ����敪
  cv_selling_type_normal           CONSTANT VARCHAR2(1)     := '1';  -- �ʏ�
  -- ����ԕi�敪
  cv_selling_return_type_dlv       CONSTANT VARCHAR2(1)     := '1';  -- �[�i
  -- �[�i�`�[�敪
  cv_delivery_slip_type_dlv        CONSTANT VARCHAR2(1)     := '1';  -- �[�i
  -- �[�i�g�ы敪
  cv_delivery_form_type_trns       CONSTANT VARCHAR2(1)     := '6';  -- ���ѐU��
  -- �����R�[�h
  cv_article_code_dummy            CONSTANT VARCHAR2(10)    := '0000000000'; -- �_�~�[�����R�[�h
  -- �J�[�h����敪
  cv_card_selling_type_cash        CONSTANT VARCHAR2(1)     := '0';  -- ����
  -- �g���b
  cv_hc_cold                       CONSTANT VARCHAR2(1)     := '1';  -- COLD
  -- �J����No
  cv_column_no                     CONSTANT VARCHAR2(2)     := '00'; -- �_�~�[�J����NO
  -- �ڋq�}�X�^�L���X�e�[�^�X
  cv_cust_status_available         CONSTANT VARCHAR2(1)     := 'A';  -- �L��
  cv_get_period_inv                CONSTANT VARCHAR2(2)     := '01';   --INV��v���Ԏ擾
  cv_period_status                 CONSTANT VARCHAR2(4)     := 'OPEN'; -- ��v���ԃX�e�[�^�X(�I�[�v��)
  cn_dlv_qty                       CONSTANT NUMBER(1)       := 0;      -- �����l���̐���
  cn_business_cost                 CONSTANT NUMBER(1)       := 0;      -- �����l���̉c�ƌ���
  cn_dlv_unit_price                CONSTANT NUMBER(1)       := 0;      -- �����l���̔[�i�P��
  --�����l���擾����
  cv_amt_fix_status                CONSTANT VARCHAR2(1)     := '1';         -- ���z�m���
  cv_ar_interface_status           CONSTANT VARCHAR2(1)     := '1';         -- AR�A�g��
  --�f�[�^����p
  cn_sales_exp                     CONSTANT NUMBER(1)       := 1;           -- �̔�����
  cn_payment_discounts             CONSTANT NUMBER(1)       := 2;           -- �����l��
  cv_payment_discounts_code_type   CONSTANT VARCHAR2(50)    := 'XXCMM1_PAYMENT_DISCOUNTS_CODE';     -- �����l��
  --�Q�ƃ^�C�v�E�L���t���O
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';         -- �L��
-- 2020/06/15 Add S
  cv_cate_set_name                 CONSTANT VARCHAR2(20)    := '�{�Џ��i�敪';            -- �i�ڃJ�e�S���Z�b�g��
-- 2020/06/15 Add E
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���������擾�l
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- ��v����ID
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gd_target_date_from              DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiFrom�j
  gd_target_date_to                DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiTo�j
  gt_item_code                     mtl_system_items_b.segment1%TYPE DEFAULT NULL;                  -- �����l���R�[�h
  gt_supplier_dummy                xxcok_cond_bm_support.supplier_code%TYPE DEFAULT NULL;          -- �d����_�~�[�R�[�h
  gn_organization_id               NUMBER        DEFAULT NULL;   -- �݌ɑg�DID
  -- ���̓p�����[�^
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- �����
  --
  gt_selling_trns_info_id_min      xxcok_dedu_sell_trns_info.selling_trns_info_id%TYPE DEFAULT NULL; -- ����U�֏��o�^�ŏ�ID
-- 2020/06/15 Add S
  gt_product_class                 xxcok_dedu_sell_trns_info.product_class%TYPE;     -- ���i�敪
-- 2020/06/15 Add E
  --==================================================
  -- �O���[�o����O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
  --*** �x���X�L�b�v ***
  warning_skip_expt                EXCEPTION;
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  --
  -- ����U�֌����擾
  CURSOR get_selling_from_cur
  IS
    SELECT /*+
               LEADING(xsfi, ship_hca, ship_hcas)
               INDEX(ship_hca hz_cust_accounts_u2)
            */
           xseh.delivery_date                                           AS selling_date             -- ����v���
         , xseh.sales_base_code                                         AS sales_base_code          -- ����U�֌����_�R�[�h
         , xseh.ship_to_customer_code                                   AS ship_cust_code           -- ����U�֌��ڋq�R�[�h
         , ship_hp.party_name                                           AS ship_party_name          -- ����U�֌��ڋq��
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , xseh.delivery_date
           )                                                            AS sales_staff_code         -- ����U�֌��S���c�ƃR�[�h
         , xseh.cust_gyotai_sho                                         AS ship_cust_gyotai_sho     -- �Ƒԁi�����ށj
         , bill_hca.account_number                                      AS bill_cust_code           -- ������ڋq�R�[�h
         , xsel.item_code                                               AS item_code                -- �i�ڃR�[�h
         , ROUND( SUM( xsel.dlv_qty ), 0 )                              AS dlv_qty_sum              -- �[�i����
         , xsel.dlv_uom_code                                            AS dlv_uom_code             -- �[�i�P��
         , ROUND( SUM( xsel.sale_amount ), 0 )                          AS sales_amount_sum         -- ������z
         , ROUND( SUM( xsel.pure_amount ), 0 )                          AS pure_amount_sum          -- �{�̋��z
         , xsel.business_cost                                           AS business_cost            -- �c�ƌ���
         , DECODE(xsel.tax_code, NULL, xseh.tax_code, xsel.tax_code )   AS tax_code                 -- �ŋ��R�[�h
         , DECODE(xsel.tax_rate, NULL, xseh.tax_rate, xsel.tax_rate )   AS tax_rate                 -- ����ŗ�
         , xsel.dlv_unit_price                                          AS dlv_unit_price           -- �[�i�P��
         , cn_sales_exp                                                 AS data_type                -- �f�[�^���(����)
    FROM xxcok_selling_from_info   xsfi             -- ����U�֌����
       , hz_cust_accounts          ship_hca         -- �y�o�א�z�ڋq�}�X�^
       , xxcmm_cust_accounts       ship_xca         -- �y�o�א�z�ڋq�ǉ����
       , hz_cust_acct_sites        ship_hcas        -- �y�o�א�z�ڋq���ݒn
       , hz_parties                ship_hp          -- �y�o�א�z�ڋq�p�[�e�B
       , hz_party_sites            ship_hps         -- �y�o�א�z�ڋq�p�[�e�B�T�C�g
       , hz_cust_site_uses         ship_hcsu        -- �y�o�א�z�ڋq�g�p�ړI
       , hz_cust_site_uses         bill_hcsu        -- �y������z�ڋq�g�p�ړI
       , hz_cust_acct_sites        bill_hcas        -- �y������z�ڋq���ݒn
       , hz_cust_accounts          bill_hca         -- �y������z�ڋq�}�X�^
       , xxcos_sales_exp_headers   xseh             -- �̔����уw�b�_�[
       , xxcos_sales_exp_lines     xsel             -- �̔����і���
    WHERE xsfi.selling_from_cust_code       = ship_hca.account_number
      AND ship_hca.customer_class_code      = cv_customer_class_customer
      AND ship_hca.cust_account_id          = ship_xca.customer_id
      AND ship_xca.selling_transfer_div     = cv_xca_transfer_div_on
      AND ship_hca.cust_account_id          = ship_hcas.cust_account_id
      AND ship_hca.party_id                 = ship_hp.party_id
      AND ship_hp.duns_number_c            IN (   cv_customer_status_30
                                                , cv_customer_status_40
                                                , cv_customer_status_50
                                              )
      AND ship_hp.party_id                  = ship_hps.party_id
      AND ship_hcas.party_site_id           = ship_hps.party_site_id
      AND ship_hcas.cust_acct_site_id       = ship_hcsu.cust_acct_site_id
      AND ship_hcsu.site_use_code           = cv_site_use_code_ship
      AND ship_hcsu.bill_to_site_use_id     = bill_hcsu.site_use_id
      AND bill_hcsu.site_use_code           = cv_site_use_code_bill
      AND ship_hcsu.status                  = cv_cust_status_available
      AND bill_hcsu.status                  = cv_cust_status_available
      AND bill_hcsu.cust_acct_site_id       = bill_hcas.cust_acct_site_id
      AND bill_hcas.cust_account_id         = bill_hca.cust_account_id
      AND xsfi.selling_from_base_code       = xseh.sales_base_code
      AND xsfi.selling_from_cust_code       = xseh.ship_to_customer_code
      AND xseh.delivery_date          BETWEEN gd_target_date_from
                                          AND gd_target_date_to
      AND xseh.dlv_invoice_class           IN (   cv_invoice_class_01
                                                , cv_invoice_class_02
                                                , cv_invoice_class_03
                                                , cv_invoice_class_04
                                              )
      AND xseh.sales_exp_header_id          = xsel.sales_exp_header_id
      AND xsel.business_cost               IS NOT NULL
      AND EXISTS ( SELECT 'X'
                   FROM xxcok_selling_to_info        xsti
                      , xxcok_selling_rate_info      xsri
                      , hz_cust_accounts             hca
                      , xxcmm_cust_accounts          xca
                      , hz_parties                   hp
                   WHERE xsti.selling_from_info_id       = xsfi.selling_from_info_id
                     AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                     AND xsti.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti.invalid_flag               = cv_invalid_flag_valid
                     AND xsri.selling_from_base_code     = xsfi.selling_from_base_code
                     AND xsri.selling_from_cust_code     = ship_hca.account_number
                     AND xsri.invalid_flag               = cv_invalid_flag_valid
                     AND xsti.selling_to_cust_code       = hca.account_number
                     AND hca.customer_class_code         = cv_customer_class_customer
                     AND hca.cust_account_id             = xca.customer_id
                     AND xca.selling_transfer_div        = cv_xca_transfer_div_on
                     AND hca.party_id                    = hp.party_id
                     AND hp.duns_number_c               IN (   cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                           )
                     AND ROWNUM                          = 1
          )
  GROUP BY xseh.delivery_date
         , xseh.sales_base_code
         , xseh.ship_to_customer_code
         , ship_hp.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , xseh.delivery_date
           )
         , xseh.cust_gyotai_sho
         , bill_hca.account_number
         , xsel.item_code
         , xsel.dlv_uom_code
         , xsel.business_cost
         , DECODE(xsel.tax_code, NULL, xseh.tax_code, xsel.tax_code )
         , DECODE(xsel.tax_rate, NULL, xseh.tax_rate, xsel.tax_rate )
         , xsel.dlv_unit_price
    UNION ALL
    --�����l�����
    SELECT /*+
               LEADING( xsfi2 )
               USE_NL( xsfi2 xcbs )
           */
           xcbs.closing_date                                            AS selling_date             -- ����v���
         , xsfi2.selling_from_base_code                                 AS sales_base_code          -- ����U�֌����_�R�[�h
         , xsfi2.selling_from_cust_code                                 AS ship_cust_code           -- ����U�֌��ڋq�R�[�h
         , ship_hp2.party_name                                          AS ship_party_name          -- ����U�֌��ڋq��
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsfi2.selling_from_cust_code
           , xcbs.closing_date
           )                                                            AS sales_staff_code         -- ����U�֌��S���c�ƃR�[�h
         , ship_xca2.business_low_type                                  AS ship_cust_gyotai_sho     -- �Ƒԁi�����ށj
         , xcbs.demand_to_cust_code                                     AS bill_cust_code           -- ������ڋq�R�[�h
         , msib.segment1                                                AS item_code                -- �i�ڃR�[�h
         , cn_dlv_qty                                                   AS dlv_qty_sum              -- �[�i����
         , msib.primary_uom_code                                        AS dlv_uom_code             -- �[�i�P��
         , SUM( xcbs.csh_rcpt_discount_amt )                            AS sales_amount_sum         -- ������z
         , SUM( xcbs.csh_rcpt_discount_amt
                     - xcbs.csh_rcpt_discount_amt_tax )                 AS pure_amount_sum          -- �{�̋��z
         , cn_business_cost                                             AS business_cost            -- �c�ƌ���
         , xcbs.tax_code                                                AS tax_code                 -- �ŋ��R�[�h
         , xcbs.tax_rate                                                AS tax_rate                 -- ����ŗ�
         , cn_dlv_unit_price                                            AS dlv_unit_price           -- �[�i�P��
         , cn_payment_discounts                                         AS data_type                -- �f�[�^���(����)
    FROM xxcok_selling_from_info   xsfi2            -- ����U�֌����
       , xxcok_cond_bm_support     xcbs             -- �����ʔ̎�̋��e�[�u��
       , hz_cust_accounts          ship_hca2        -- �y�o�א�z�ڋq�}�X�^
       , hz_parties                ship_hp2         -- �y�o�א�z�ڋq�p�[�e�B
       , xxcmm_cust_accounts       ship_xca2        -- �y�o�א�z�ڋq�ǉ����
       , xxcmm_system_items_b      xsib             -- DISC�i�ڃ}�X�^�A�h�I��
       , mtl_system_items_b        msib             -- DISC�i�ڃ}�X�^
       , xxcos_reduced_tax_rate_v  xrtrv            -- �i�ڕʏ���ŗ�VIEW
       , fnd_lookup_values_vl      flvv             -- �N�C�b�N�R�[�h
       , ar_vat_tax_all_b          avtab            -- �ŗ��}�X�^
    WHERE gv_param_info_class           = cv_info_class_decision --����ʂ�1(�m��)
      AND xsfi2.selling_from_base_code  = xcbs.base_code
      AND xsfi2.selling_from_cust_code  = xcbs.delivery_cust_code
      AND xcbs.closing_date       BETWEEN gd_target_date_from
                                      AND LAST_DAY( gd_target_date_from )
      AND xcbs.supplier_code            = gt_supplier_dummy      -- �d����CD(�_�~�[)
      AND xcbs.amt_fix_status           = cv_amt_fix_status      -- ���z�m��X�e�[�^�X�F1 �m��
      AND xcbs.ar_interface_status      = cv_ar_interface_status -- AR�A�g�X�e�[�^�X  �F1 �A�g��
      AND xsfi2.selling_from_cust_code  = ship_hca2.account_number
      AND ship_hca2.customer_class_code = cv_customer_class_customer
      AND ship_hca2.party_id            = ship_hp2.party_id
      AND ship_hp2.duns_number_c       IN (  cv_customer_status_30
                                           , cv_customer_status_40
                                           , cv_customer_status_50
                                         )
      AND ship_hca2.cust_account_id      = ship_xca2.customer_id
      AND ship_xca2.selling_transfer_div = cv_xca_transfer_div_on
      AND msib.organization_id           = gn_organization_id     -- �݌ɑg�DID
      AND msib.segment1                  = xsib.item_code
      AND xsib.item_code                 = xrtrv.item_code
      AND avtab.tax_code                 = xcbs.tax_code
      AND avtab.enabled_flag             = cv_enable
      AND avtab.set_of_books_id          = gn_set_of_books_id
      AND flvv.lookup_type               = cv_payment_discounts_code_type
      AND flvv.meaning                   = xsib.item_code
      AND flvv.enabled_flag              = cv_enable
      AND xcbs.tax_code                  IN ( xrtrv.tax_class_sales_outside
                                           ,  xrtrv.tax_class_sales_inside
                                         )
      --�ŗ��}�X�^��DFF3��NULL(���ŗ�)�̏ꍇ�͒l���i�ڃR�[�h���v���t�@�C���Ŏ擾�����l�ɌŒ肷��
      AND ( ( avtab.attribute3 IS NULL
          AND msib.segment1    = gt_item_code 
            )
      --�ŗ��}�X�^��DFF3�ɒl������(�V�ŗ�)�̏ꍇ�͐ŃR�[�h����t���������l���i�ڃR�[�h���g�p
        OR  ( avtab.attribute3 IS NOT NULL
            )
          )
      AND EXISTS ( SELECT 'X'
                   FROM hz_cust_acct_sites   ship_hcas2   -- �y�o�א�z�ڋq���ݒn
                      , hz_party_sites       ship_hps2    -- �y�o�א�z�ڋq�p�[�e�B�T�C�g
                      , hz_cust_site_uses    ship_hcsu2   -- �y�o�א�z�ڋq�g�p�ړI
                      , hz_cust_site_uses    bill_hcsu2   -- �y������z�ڋq�g�p�ړI
                      , hz_cust_acct_sites   bill_hcas2   -- �y������z�ڋq���ݒn
                      , hz_cust_accounts     bill_hca2    -- �y������z�ڋq�}�X�^
                   WHERE ship_hcas2.cust_account_id         = ship_hca2.cust_account_id
                     AND ship_hps2.party_id                 = ship_hp2.party_id
                     AND ship_hcas2.party_site_id           = ship_hps2.party_site_id
                     AND ship_hcas2.cust_acct_site_id       = ship_hcsu2.cust_acct_site_id
                     AND ship_hcsu2.site_use_code           = cv_site_use_code_ship
                     AND ship_hcsu2.bill_to_site_use_id     = bill_hcsu2.site_use_id
                     AND bill_hcsu2.site_use_code           = cv_site_use_code_bill
                     AND ship_hcsu2.status                  = cv_cust_status_available
                     AND bill_hcsu2.status                  = cv_cust_status_available
                     AND bill_hcsu2.cust_acct_site_id       = bill_hcas2.cust_acct_site_id
                     AND bill_hcas2.cust_account_id         = bill_hca2.cust_account_id
                     AND ROWNUM                             = 1
                 )
      AND EXISTS ( SELECT 'X'
                   FROM xxcos_sales_exp_headers   xseh2            -- �̔����уw�b�_�[
                      , xxcos_sales_exp_lines     xsel2            -- �̔����і���
                   WHERE 
                         xseh2.sales_base_code              = xsfi2.selling_from_base_code
                     AND xseh2.ship_to_customer_code        = xsfi2.selling_from_cust_code
                     AND xseh2.delivery_date          BETWEEN gd_target_date_from
                                                          AND LAST_DAY( gd_target_date_from )
                     AND xseh2.dlv_invoice_class           IN (  cv_invoice_class_01
                                                               , cv_invoice_class_02
                                                               , cv_invoice_class_03
                                                               , cv_invoice_class_04
                                                              )
                     AND xseh2.sales_exp_header_id          = xsel2.sales_exp_header_id
                     AND xsel2.business_cost               IS NOT NULL
                     AND ROWNUM                             = 1
                 )
      AND EXISTS ( SELECT 'X'
                   FROM xxcok_selling_to_info        xsti2
                      , xxcok_selling_rate_info      xsri2
                      , hz_cust_accounts             hca2
                      , xxcmm_cust_accounts          xca2
                      , hz_parties                   hp2
                   WHERE xsti2.selling_from_info_id       = xsfi2.selling_from_info_id
                     AND xsti2.selling_to_cust_code       = xsri2.selling_to_cust_code
                     AND xsti2.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti2.invalid_flag               = cv_invalid_flag_valid
                     AND xsri2.selling_from_base_code     = xsfi2.selling_from_base_code
                     AND xsri2.selling_from_cust_code     = ship_hca2.account_number
                     AND xsri2.invalid_flag               = cv_invalid_flag_valid
                     AND xsti2.selling_to_cust_code       = hca2.account_number
                     AND hca2.customer_class_code         = cv_customer_class_customer
                     AND hca2.cust_account_id             = xca2.customer_id
                     AND xca2.selling_transfer_div        = cv_xca_transfer_div_on
                     AND hca2.party_id                    = hp2.party_id
                     AND hp2.duns_number_c               IN (  cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                            )
                     AND ROWNUM                           = 1
          )
  GROUP BY
           xcbs.closing_date
         , xsfi2.selling_from_base_code
         , xsfi2.selling_from_cust_code
         , ship_hp2.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsfi2.selling_from_cust_code
           , xcbs.closing_date
           )
         , ship_xca2.business_low_type
         , xcbs.demand_to_cust_code
         , msib.segment1
         , msib.primary_uom_code
         , xcbs.tax_code
         , xcbs.tax_rate
  ;
--
  -- ����U�֐���擾
  CURSOR get_selling_to_cur(
    it_base_code              IN  xxcok_selling_rate_info.selling_from_base_code%TYPE
  , it_cust_code              IN  xxcok_selling_rate_info.selling_from_cust_code%TYPE
  , id_selling_date           IN  DATE
  )
  IS
    SELECT CASE
             WHEN   TRUNC( id_selling_date, 'MM' )
                  = TRUNC( gd_process_date, 'MM' )
             THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS selling_to_base_code       -- ����U�֐攄�㋒�_�R�[�h
         , xsri.selling_to_cust_code              AS selling_to_cust_code       -- ����U�֐�ڋq�R�[�h
         , hp.party_name                          AS party_name                 -- ����U�֐�ڋq��
         , xsri.selling_trns_rate                 AS selling_trns_rate          -- ����U�֊���
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsri.selling_to_cust_code
           , id_selling_date
           )                                      AS sales_staff_code           -- ����U�֐�S���c�ƃR�[�h
    FROM xxcok_selling_rate_info        xsri
       , hz_cust_accounts               hca
       , xxcmm_cust_accounts            xca
       , hz_parties                     hp
    WHERE xsri.selling_from_base_code   = it_base_code
      AND xsri.selling_from_cust_code   = it_cust_code
      AND xsri.invalid_flag             = cv_invalid_flag_valid
      AND EXISTS ( SELECT /*+ LEADING( xsfi,xsti ) */
                          'X'
                   FROM xxcok_selling_from_info    xsfi
                      , xxcok_selling_to_info      xsti
                   WHERE xsfi.selling_from_base_code     = xsri.selling_from_base_code
                     AND xsfi.selling_from_cust_code     = xsri.selling_from_cust_code
                     AND xsfi.selling_from_info_id       = xsti.selling_from_info_id
                     AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                     AND xsti.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti.invalid_flag               = cv_invalid_flag_valid
                     AND ROWNUM                          = 1
          )
      AND hca.account_number            = xsri.selling_to_cust_code
      AND hca.customer_class_code       = cv_customer_class_customer
      AND xca.customer_id               = hca.cust_account_id
      AND xca.selling_transfer_div      = cv_xca_transfer_div_on
      AND hp.party_id                   = hca.party_id
      AND hp.duns_number_c             IN (   cv_customer_status_30
                                            , cv_customer_status_40
                                            , cv_customer_status_50
                                          )
    ORDER BY xsri.selling_trns_rate       ASC
           , xsri.selling_to_cust_code    DESC
  ;
--
  --==================================================
  -- �O���[�o���^�C�v
  --==================================================
--
  TYPE get_selling_to_ttype        IS TABLE OF get_selling_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : update_xsti
   * Description      : �`�[�ԍ��X�V(A-9)
   ***********************************************************************************/
  PROCEDURE update_xsti(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xsti';             -- �v���O������
    cv_slip_no_prefix              CONSTANT VARCHAR2(1)  := 'K';                       -- �`�[�ԍ��ړ���
    cv_slip_no_format              CONSTANT VARCHAR2(13) := 'FM00000000000';           -- �`�[�ԍ��ړ���ȉ�����
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    -- �u���C�N����p�ϐ�
    lt_break_selling_date          xxcok_dedu_sell_trns_info.selling_date%TYPE DEFAULT NULL;        -- 
    lt_break_demand_to_cust_code   xxcok_dedu_sell_trns_info.demand_to_cust_code%TYPE DEFAULT NULL; -- �U�֌��ڋq�R�[�h
    lt_break_base_code             xxcok_dedu_sell_trns_info.base_code%TYPE DEFAULT NULL;           -- ���_�R�[�h
    lt_break_cust_code             xxcok_dedu_sell_trns_info.cust_code%TYPE DEFAULT NULL;           -- �ڋq�R�[�h
    lt_break_item_code             xxcok_dedu_sell_trns_info.item_code%TYPE DEFAULT NULL;           -- �i�ڃR�[�h
    -- �X�V�l�p�ϐ�
    lt_slip_no                     xxcok_dedu_sell_trns_info.slip_no  %TYPE DEFAULT NULL; -- �`�[�ԍ�
    lt_detail_no                   xxcok_dedu_sell_trns_info.detail_no%TYPE DEFAULT NULL; -- ���הԍ�
    --==================================================
    -- ���b�N�擾�J�[�\��
    --==================================================
    CURSOR update_xsti_cur
    IS
      SELECT xdsti.selling_trns_info_id       AS selling_trns_info_id      -- ������ѐU�֏��ID
           , xdsti.selling_date               AS selling_date              -- ����v���
           , xdsti.demand_to_cust_code        AS demand_to_cust_code       -- �U�֌��ڋq�R�[�h
           , xdsti.base_code                  AS base_code                 -- ���_�R�[�h
           , xdsti.cust_code                  AS cust_code                 -- �ڋq�R�[�h
           , xdsti.item_code                  AS item_code                 -- �i�ڃR�[�h
           , xdsti.delivery_unit_price        AS delivery_unit_price       -- �[�i�P��
      FROM xxcok_dedu_sell_trns_info      xdsti
      WHERE xdsti.selling_trns_info_id >= gt_selling_trns_info_id_min
        AND xdsti.request_id            = cn_request_id
        AND xdsti.slip_no              IS NULL
        AND xdsti.detail_no            IS NULL
      ORDER BY xdsti.selling_date
             , xdsti.demand_to_cust_code
             , xdsti.base_code
             , xdsti.cust_code
             , xdsti.item_code
             , xdsti.delivery_unit_price
      FOR UPDATE OF xdsti.selling_trns_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ����U�֏��̓o�^
    --==================================================
    << update_xsti_loop >>
    FOR update_xsti_rec IN update_xsti_cur LOOP
      --==================================================
      -- �u���C�N����
      --==================================================
      IF(    ( lt_slip_no IS NULL )
          OR ( update_xsti_rec.selling_date        <> lt_break_selling_date        )
          OR ( update_xsti_rec.demand_to_cust_code <> lt_break_demand_to_cust_code )
          OR ( update_xsti_rec.base_code           <> lt_break_base_code           )
          OR ( update_xsti_rec.cust_code           <> lt_break_cust_code           )
          OR ( update_xsti_rec.item_code           <> lt_break_item_code           )
      ) THEN
        --==================================================
        -- �`�[�ԍ��擾
        --==================================================
        SELECT cv_slip_no_prefix || TO_CHAR( xxcok_dedu_sell_trns_info_s02.NEXTVAL, cv_slip_no_format )
        INTO lt_slip_no
        FROM DUAL
        ;
        --==================================================
        -- ���הԍ�������
        --==================================================
        lt_detail_no := 0;
        --==================================================
        -- �u���C�N����p���ڑޔ�
        --==================================================
        lt_break_selling_date        := update_xsti_rec.selling_date;
        lt_break_demand_to_cust_code := update_xsti_rec.demand_to_cust_code;
        lt_break_base_code           := update_xsti_rec.base_code;
        lt_break_cust_code           := update_xsti_rec.cust_code;
        lt_break_item_code           := update_xsti_rec.item_code;
      END IF;
      --==================================================
      -- ���הԍ��C���N�������g
      --==================================================
      lt_detail_no := lt_detail_no + 1;
      --==================================================
      -- ������ѐU�֏��e�[�u���X�V
      --==================================================
      UPDATE xxcok_dedu_sell_trns_info    xdsti
      SET xdsti.slip_no                  = lt_slip_no
        , xdsti.detail_no                = lt_detail_no
        , xdsti.last_updated_by          = cn_last_updated_by
        , xdsti.last_update_date         = SYSDATE
        , xdsti.last_update_login        = cn_last_update_login
        , xdsti.request_id               = cn_request_id
        , xdsti.program_application_id   = cn_program_application_id
        , xdsti.program_id               = cn_program_id
        , xdsti.program_update_date      = SYSDATE
      WHERE xdsti.selling_trns_info_id   = update_xsti_rec.selling_trns_info_id
      ;
    END LOOP update_xsti_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xsti;
--
  /**********************************************************************************
   * Procedure Name   : insert_xsti
   * Description      : ����U�֏��̓o�^(A-6)(A-8)
   ***********************************************************************************/
  PROCEDURE insert_xsti(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_selling_from_rec             IN  get_selling_from_cur%ROWTYPE -- ����U�֌����
  , iv_base_code                   IN  VARCHAR2        -- ���_�R�[�h
  , iv_cust_code                   IN  VARCHAR2        -- �ڋq�R�[�h
  , iv_selling_emp_code            IN  VARCHAR2        -- �S���҉c�ƃR�[�h
  , in_dlv_qty                     IN  NUMBER          -- �[�i����
  , in_sales_amount                IN  NUMBER          -- ������z
  , in_pure_amount                 IN  NUMBER          -- �{�̋��z
  , in_sales_cost                  IN  NUMBER          -- ���㌴��
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xsti';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lt_sales_amount                xxcok_selling_trns_info.selling_amt%TYPE;
    lt_pure_amount                 xxcok_selling_trns_info.selling_amt_no_tax%TYPE;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
--
    --�����l���f�[�^�͕������t�]����
    IF ( i_selling_from_rec.data_type = cn_payment_discounts ) THEN
      -- ������z
      lt_sales_amount := in_sales_amount * -1;
      -- �{�̋��z
      lt_pure_amount  := in_pure_amount * -1;
    ELSE
      -- ������z
      lt_sales_amount := in_sales_amount;
      -- �{�̋��z
      lt_pure_amount  := in_pure_amount;
    END IF;
    --==================================================
    -- ����U�֏��̓o�^
    --==================================================
    INSERT INTO xxcok_dedu_sell_trns_info(
      selling_trns_info_id                        -- ������ѐU�֏��ID
    , selling_trns_type                           -- ���ѐU�֋敪
    , slip_no                                     -- �`�[�ԍ�
    , detail_no                                   -- ���הԍ�
    , selling_date                                -- ����v���
    , selling_type                                -- ����敪
    , selling_return_type                         -- ����ԕi�敪
    , delivery_slip_type                          -- �[�i�`�[�敪
    , base_code                                   -- ���_�R�[�h
    , cust_code                                   -- �ڋq�R�[�h
    , selling_emp_code                            -- �S���҉c�ƃR�[�h
    , cust_state_type                             -- �ڋq�Ƒԋ敪
    , delivery_form_type                          -- �[�i�`�ԋ敪
    , article_code                                -- �����R�[�h
    , card_selling_type                           -- �J�[�h����敪
    , checking_date                               -- ������
    , demand_to_cust_code                         -- ������ڋq�R�[�h
    , h_c                                         -- �g���b
    , column_no                                   -- �R����NO
    , item_code                                   -- �i�ڃR�[�h
    , qty                                         -- ����
    , unit_type                                   -- �P��
    , delivery_unit_price                         -- �[�i�P��
    , selling_amt                                 -- ������z
    , selling_amt_no_tax                          -- ������z(�Ŕ���)
    , trading_cost                                -- �c�ƌ���
    , selling_cost_amt                            -- ���㌴�����z
    , tax_code                                    -- ����ŃR�[�h
    , tax_rate                                    -- ����ŗ�
    , delivery_base_code                          -- �[�i���_�R�[�h
    , registration_date                           -- �Ɩ��o�^���t
    , correction_flag                             -- �U�߃t���O
    , report_decision_flag                        -- ����m��t���O
    , info_interface_flag                         -- ���nI/F�t���O
    , gl_interface_flag                           -- �d��쐬�t���O
    , org_slip_number                             -- ���`�[�ԍ�
    , selling_from_cust_code                      -- ����U�֌��ڋq�R�[�h
    , created_by                                  -- �쐬��
    , creation_date                               -- �쐬��
    , last_updated_by                             -- �ŏI�X�V��
    , last_update_date                            -- �ŏI�X�V��
    , last_update_login                           -- �ŏI�X�V���O�C��
    , request_id                                  -- �v��ID
    , program_application_id                      -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , program_id                                  -- �R���J�����g��v���O����ID
    , program_update_date                         -- �v���O�����X�V��
-- 2020/06/15 Add S
    , product_class                               -- ���i�敪
-- 2020/06/15 Add E
    )
    VALUES(
      xxcok_dedu_sell_trns_info_s01.NEXTVAL       -- selling_trns_info_id
    , cv_selling_trns_type_trns                   -- selling_trns_type
    , NULL                                        -- slip_no
    , NULL                                        -- detail_no
    , i_selling_from_rec.selling_date             -- selling_date
    , cv_selling_type_normal                      -- selling_type
    , cv_selling_return_type_dlv                  -- selling_return_type
    , cv_delivery_slip_type_dlv                   -- delivery_slip_type
    , iv_base_code                                -- base_code
    , iv_cust_code                                -- cust_code
    , iv_selling_emp_code                         -- selling_emp_code
    , i_selling_from_rec.ship_cust_gyotai_sho     -- cust_state_type
    , cv_delivery_form_type_trns                  -- delivery_form_type
    , cv_article_code_dummy                       -- article_code
    , cv_card_selling_type_cash                   -- card_selling_type
    , NULL                                        -- checking_date
    , i_selling_from_rec.bill_cust_code           -- demand_to_cust_code
    , cv_hc_cold                                  -- h_c
    , cv_column_no                                -- column_no
    , i_selling_from_rec.item_code                -- item_code
    , in_dlv_qty                                  -- qty
    , i_selling_from_rec.dlv_uom_code             -- unit_type
    , i_selling_from_rec.dlv_unit_price           -- delivery_unit_price
    , lt_sales_amount                             -- selling_amt
    , lt_pure_amount                              -- selling_amt_no_tax
    , in_sales_cost                               -- trading_cost
    , NULL                                        -- selling_cost_amt
    , i_selling_from_rec.tax_code                 -- tax_code
    , i_selling_from_rec.tax_rate                 -- tax_rate
    , i_selling_from_rec.sales_base_code          -- delivery_base_code
    , gd_process_date                             -- registration_date
    , cv_xsti_correction_flag_off                 -- correction_flag
    , CASE
        WHEN   TRUNC( i_selling_from_rec.selling_date, 'MM' )
             = TRUNC( gd_process_date                , 'MM' )
        THEN
          cv_xsti_decision_flag_news
        ELSE
          gv_param_info_class
      END                                         -- report_decision_flag
    , cv_xsti_info_if_flag_no                     -- info_interface_flag
    , cv_xsti_gl_if_flag_no                       -- gl_interface_flag
    , NULL                                        -- org_slip_number
    , i_selling_from_rec.ship_cust_code           -- selling_from_cust_code
    , cn_created_by                               -- created_by
    , SYSDATE                                     -- creation_date
    , cn_last_updated_by                          -- last_updated_by
    , SYSDATE                                     -- last_update_date
    , cn_last_update_login                        -- last_update_login
    , cn_request_id                               -- request_id
    , cn_program_application_id                   -- program_application_id
    , cn_program_id                               -- program_id
    , SYSDATE                                     -- program_update_date
-- 2020/06/15 Add S
    , gt_product_class                            -- product_class
-- 2020/06/15 Add E
    );
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �x���I�� ***
    WHEN warning_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xsti;
--
  /**********************************************************************************
   * Procedure Name   : selling_to_loop
   * Description      : ����U�֐��񃋁[�v(A-4)
   ***********************************************************************************/
  PROCEDURE selling_to_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_selling_from_rec             IN  get_selling_from_cur%ROWTYPE -- ����U�֌����
  , on_dlv_qty                     OUT NUMBER          -- ����U�֌��[�i����
  , on_sales_amount                OUT NUMBER          -- ����U�֌�������z
  , on_pure_amount                 OUT NUMBER          -- ����U�֌��{�̋��z
  , on_sales_cost                  OUT NUMBER          -- ����U�֌����㌴��
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'selling_to_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- OUT�p�����[�^�p�ϐ�
    ln_dlv_qty_out                 NUMBER         DEFAULT 0;                    -- �[�i����
    ln_sales_amount_out            NUMBER         DEFAULT 0;                    -- ������z
    ln_pure_amount_out             NUMBER         DEFAULT 0;                    -- �{�̋��z
    ln_sales_cost_out              NUMBER         DEFAULT 0;                    -- ���㌴��
    -- �v�Z���ʊi�[�p�ϐ�
    ln_dlv_qty                     NUMBER         DEFAULT 0;                    -- �[�i����
    ln_sales_amount                NUMBER         DEFAULT 0;                    -- ������z
    ln_pure_amount                 NUMBER         DEFAULT 0;                    -- �{�̋��z
    ln_sales_cost                  NUMBER         DEFAULT 0;                    -- ���㌴��
    -- �[���v�Z�p�W�v�ϐ�
    ln_dlv_qty_sum                 NUMBER         DEFAULT 0;                    -- �[�i����
    ln_sales_amount_sum            NUMBER         DEFAULT 0;                    -- ������z
    ln_pure_amount_sum             NUMBER         DEFAULT 0;                    -- �{�̋��z
    -- �U�֊����`�F�b�N
    ln_selling_trns_rate_total     NUMBER         DEFAULT 0;                    -- �U�֊����̍��v��100�ƂȂ�Ȃ��ꍇ�̓G���[
    --==================================================
    -- ���[�J���R���N�V�����ϐ�
    --==================================================
    l_get_selling_to_tab           get_selling_to_ttype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ����U�֐���̒��o
    --==================================================
    OPEN  get_selling_to_cur(
            i_selling_from_rec.sales_base_code
          , i_selling_from_rec.ship_cust_code
          , i_selling_from_rec.selling_date
          );
    FETCH get_selling_to_cur BULK COLLECT INTO l_get_selling_to_tab;
    CLOSE get_selling_to_cur;
    << sub_loop >>
    FOR i IN 1 .. l_get_selling_to_tab.COUNT LOOP
      --==================================================
      -- NULL�`�F�b�N
      --==================================================
      IF(    ( l_get_selling_to_tab(i).selling_to_base_code IS NULL )
          OR ( l_get_selling_to_tab(i).sales_staff_code     IS NULL )
      ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00045
                      , iv_token_name1          => cv_tkn_customer_code
                      , iv_token_value1         => l_get_selling_to_tab(i).selling_to_cust_code
                      , iv_token_name2          => cv_tkn_customer_name
                      , iv_token_value2         => l_get_selling_to_tab(i).party_name
                      , iv_token_name3          => cv_tkn_tanto_loc_code
                      , iv_token_value3         => l_get_selling_to_tab(i).selling_to_base_code
                      , iv_token_name4          => cv_tkn_tanto_code
                      , iv_token_value4         => l_get_selling_to_tab(i).sales_staff_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE warning_skip_expt;
      END IF;
      --==================================================
      -- ���v�Z(A-5)
      --==================================================
      -- �[�i����
      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- ������z
      ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- �{�̋��z
      ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- ���㌴��
      ln_sales_cost    := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                      i_selling_from_rec.item_code
                                                                    , i_selling_from_rec.dlv_uom_code
                                                                    , ln_dlv_qty
                                                                    )
                                 , 0
                          )
      ;
      --==================================================
      -- ���㌴���`�F�b�N
      --==================================================
      IF( ln_sales_cost IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_10452
                      , iv_token_name1          => cv_tkn_item_code
                      , iv_token_value1         => i_selling_from_rec.item_code
                      , iv_token_name2          => cv_tkn_dlv_uom_code
                      , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- �[���v�Z�p�W�v
      ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
      ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
      ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
      -- �[������
      IF( i = l_get_selling_to_tab.LAST ) THEN
        -- �[�i����
        ln_dlv_qty      := ln_dlv_qty      + i_selling_from_rec.dlv_qty_sum       - ln_dlv_qty_sum;
        -- ������z
        ln_sales_amount := ln_sales_amount + i_selling_from_rec.sales_amount_sum  - ln_sales_amount_sum;
        -- �{�̋��z
        ln_pure_amount  := ln_pure_amount  + i_selling_from_rec.pure_amount_sum   - ln_pure_amount_sum;
        -- ���㌴��
        ln_sales_cost   := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                       i_selling_from_rec.item_code
                                                                     , i_selling_from_rec.dlv_uom_code
                                                                     , ln_dlv_qty
                                                                     )
                                , 0
                           )
        ;
        --==================================================
        -- ���㌴���`�F�b�N
        --==================================================
        IF( ln_sales_cost_out IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => i_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
      END IF;
      --==================================================
      -- ����U�֐���̓o�^(A-6)
      --==================================================
      IF( l_get_selling_to_tab(i).selling_to_cust_code = i_selling_from_rec.ship_cust_code ) THEN
        --==================================================
        -- OUT�p�����[�^�ݒ�
        --==================================================
        -- �[�i����
        ln_dlv_qty_out      := ln_dlv_qty;
        -- ������z
        ln_sales_amount_out := ln_sales_amount;
        -- �{�̋��z
        ln_pure_amount_out  := ln_pure_amount;
        -- ���㌴��
        ln_sales_cost_out   := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                           i_selling_from_rec.item_code
                                                                         , i_selling_from_rec.dlv_uom_code
                                                                         , ln_dlv_qty_out
                                                                         )
                                    , 0
                               )
        ;
        --==================================================
        -- ���㌴���`�F�b�N
        --==================================================
        IF( ln_sales_cost_out IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => i_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
      ELSE
        -- ����U�֏��̓o�^�v���V�[�W���Ăяo��
        insert_xsti(
          ov_errbuf               => lv_errbuf                                     -- �G���[�E���b�Z�[�W
        , ov_retcode              => lv_retcode                                    -- ���^�[���E�R�[�h
        , ov_errmsg               => lv_errmsg                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_selling_from_rec      => i_selling_from_rec                            -- ����U�֌����
        , iv_base_code            => l_get_selling_to_tab(i).selling_to_base_code  -- ����U�֐拒�_�R�[�h
        , iv_cust_code            => l_get_selling_to_tab(i).selling_to_cust_code  -- ����U�֐�ڋq�R�[�h
        , iv_selling_emp_code     => l_get_selling_to_tab(i).sales_staff_code      -- ����U�֐�c�ƒS���R�[�h
        , in_dlv_qty              => ln_dlv_qty                                    -- ����U�֐�[�i����
        , in_sales_amount         => ln_sales_amount                               -- ����U�֐攄����z
        , in_pure_amount          => ln_pure_amount                                -- ����U�֐�{�̋��z
        , in_sales_cost           => ln_sales_cost                                 -- ����U�֐攄�㌴��
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
      END IF;
      --==================================================
      -- �U�֊����`�F�b�N�p�W�v
      --==================================================
      ln_selling_trns_rate_total := ln_selling_trns_rate_total + l_get_selling_to_tab(i).selling_trns_rate;
    END LOOP sub_loop;
    --==================================================
    -- �U�֊����`�F�b�N(A-7)
    --==================================================
    IF( ln_selling_trns_rate_total <> 100 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10463
                    , iv_token_name1          => cv_tkn_from_location_code
                    , iv_token_value1         => i_selling_from_rec.sales_base_code
                    , iv_token_name2          => cv_tkn_from_customer_code
                    , iv_token_value2         => i_selling_from_rec.ship_cust_code
                    , iv_token_name3          => cv_tkn_item_code
                    , iv_token_value3         => i_selling_from_rec.item_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE warning_skip_expt;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    on_dlv_qty           := ln_dlv_qty_out;
    on_sales_amount      := ln_sales_amount_out;
    on_pure_amount       := ln_pure_amount_out;
    on_sales_cost        := ln_sales_cost_out;
    ov_errbuf            := NULL;
    ov_errmsg            := NULL;
    ov_retcode           := lv_end_retcode;
--
  EXCEPTION
    -- *** �x���I�� ***
    WHEN warning_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END selling_to_loop;
--
  /**********************************************************************************
   * Procedure Name   : selling_from_loop
   * Description      : ����U�֌���񃋁[�v(A-3)
   ***********************************************************************************/
    PROCEDURE selling_from_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'selling_from_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- ����U�֌��U�ֈ��v�Z���ʊi�[�p
    ln_dlv_qty                     NUMBER         DEFAULT 0;                    -- �[�i����
    ln_sales_amount                NUMBER         DEFAULT 0;                    -- ������z
    ln_pure_amount                 NUMBER         DEFAULT 0;                    -- �{�̋��z
    ln_sales_cost                  NUMBER         DEFAULT 0;                    -- ���㌴��
    -- ����U�֑��E���R�[�h�쐬�p�ϐ�
    ln_dlv_qty_counter             NUMBER         DEFAULT 0;                    -- �[�i���ʁi���E�j
    ln_sales_amount_counter        NUMBER         DEFAULT 0;                    -- ������z�i���E�j
    ln_pure_amount_counter         NUMBER         DEFAULT 0;                    -- �{�̋��z�i���E�j
    ln_sales_cost_counter          NUMBER         DEFAULT 0;                    -- ���㌴���i���E�j
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ����U�֌����̒��o
    --==================================================
    << main_loop >>
    FOR get_selling_from_rec IN get_selling_from_cur LOOP
      --==================================================
      -- �Ώی����J�E���g
      --==================================================
      gn_target_cnt := gn_target_cnt + 1;
      BEGIN
        --==================================================
        -- �Z�[�u�|�C���g�ݒ�
        --==================================================
        SAVEPOINT loop_start_save;
        --==================================================
        -- ����U�֌��S���c�ƃR�[�h�`�F�b�N
        --==================================================
        IF( get_selling_from_rec.sales_staff_code IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_00045
                        , iv_token_name1          => cv_tkn_customer_code
                        , iv_token_value1         => get_selling_from_rec.ship_cust_code
                        , iv_token_name2          => cv_tkn_customer_name
                        , iv_token_value2         => get_selling_from_rec.ship_party_name
                        , iv_token_name3          => cv_tkn_tanto_loc_code
                        , iv_token_value3         => get_selling_from_rec.sales_base_code
                        , iv_token_name4          => cv_tkn_tanto_code
                        , iv_token_value4         => get_selling_from_rec.sales_staff_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE warning_skip_expt;
        END IF;
-- 2020/06/15 Add S
        --==================================================
        -- ���i�敪�̎擾
        --==================================================
        BEGIN
          SELECT SUBSTRB(mcv.segment1,1,1)      segment1             -- ���i�敪
          INTO   gt_product_class
          FROM   mtl_categories_vl        mcv
                ,gmi_item_categories      gic
                ,mtl_category_sets_vl     mcsv
                ,xxcmm_system_items_b     xsib
          WHERE  mcsv.category_set_name   = cv_cate_set_name
          AND    gic.item_id              = xsib.item_id
          AND    gic.category_set_id      = mcsv.category_set_id
          AND    gic.category_id          = mcv.category_id
          AND    xsib.item_code           = get_selling_from_rec.item_code
          ;
        EXCEPTION
          WHEN OTHERS THEN
            gt_product_class := NULL ;
        END ;
-- 2020/06/15 Add E
        --==================================================
        -- ����U�֐��񃋁[�v(A-4)
        --==================================================
        selling_to_loop(
          ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W
        , ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h
        , ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_selling_from_rec      => get_selling_from_rec        -- ����U�֌����
        , on_dlv_qty              => ln_dlv_qty                  -- ����U�֌��[�i����
        , on_sales_amount         => ln_sales_amount             -- ����U�֌�������z
        , on_pure_amount          => ln_pure_amount              -- ����U�֌��{�̋��z
        , on_sales_cost           => ln_sales_cost               -- ����U�֌����㌴��
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- ����U�֌����̓o�^(A-8)
        --==================================================
        -- �[�i���ʁi���E�j
        ln_dlv_qty_counter         := get_selling_from_rec.dlv_qty_sum      * -1 + ln_dlv_qty;
        -- ������z�i���E�j
        ln_sales_amount_counter    := get_selling_from_rec.sales_amount_sum * -1 + ln_sales_amount;
        -- �{�̋��z�i���E�j
        ln_pure_amount_counter     := get_selling_from_rec.pure_amount_sum  * -1 + ln_pure_amount;
        -- ���㌴���i���E�j
        ln_sales_cost_counter      := ROUND( get_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                                  get_selling_from_rec.item_code
                                                                                , get_selling_from_rec.dlv_uom_code
                                                                                , ln_dlv_qty_counter
                                                                                )
                                           , 0
                                      )
        ;
        --==================================================
        -- ����ʎ擾�G���[�`�F�b�N
        --==================================================
        IF( ln_sales_cost_counter IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => get_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => get_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
        insert_xsti(
          ov_errbuf               => lv_errbuf                                  -- �G���[�E���b�Z�[�W
        , ov_retcode              => lv_retcode                                 -- ���^�[���E�R�[�h
        , ov_errmsg               => lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_selling_from_rec      => get_selling_from_rec                       -- ����U�֌����
        , iv_base_code            => get_selling_from_rec.sales_base_code       -- ����U�֌����_�R�[�h
        , iv_cust_code            => get_selling_from_rec.ship_cust_code        -- ����U�֌��ڋq�R�[�h
        , iv_selling_emp_code     => get_selling_from_rec.sales_staff_code      -- ����U�֌��c�ƒS���R�[�h
        , in_dlv_qty              => ln_dlv_qty_counter                         -- �[�i���ʁi���E�j
        , in_sales_amount         => ln_sales_amount_counter                    -- ������z�i���E�j
        , in_pure_amount          => ln_pure_amount_counter                     -- �{�̋��z�i���E�j
        , in_sales_cost           => ln_sales_cost_counter                      -- ���㌴���i���E�j
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- ���팏���J�E���g
        --==================================================
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        --==================================================
        -- �x���X�L�b�v
        --==================================================
        WHEN warning_skip_expt THEN
          ROLLBACK TO SAVEPOINT loop_start_save;
          lv_end_retcode := cv_status_warn;
          gn_skip_cnt := gn_skip_cnt + 1;
      END;
    END LOOP main_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END selling_from_loop;
--
  /**********************************************************************************
   * Procedure Name   : data_delite
   * Description      : �T���p���ѐU�փf�[�^�폜����(A-2)
   ***********************************************************************************/
  PROCEDURE data_delite(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_delite';                         -- �v���O������
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
  BEGIN
--
    -- �폜����
    DELETE
    FROM  xxcok_dedu_sell_trns_info    xdsi
    WHERE xdsi.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xdsi.report_decision_flag �j
    AND   xdsi.selling_date            >= gd_target_date_from
    AND   xdsi.selling_date            <= gd_target_date_to
    ;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_delite;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_period_status               VARCHAR2(10)   DEFAULT NULL;                 -- ��v���ԃX�e�[�^�X�`�F�b�N�p�߂�l
    ld_target_date_from            DATE           DEFAULT NULL;                 -- ��v���Ԋ֐�OUT�擾�p(�_�~�[)
    ld_target_date_to              DATE           DEFAULT NULL;                 -- ��v���Ԋ֐�OUT�擾�p(�_�~�[)
    lv_organization_code           VARCHAR2(50)   DEFAULT NULL;                 -- �݌ɑg�D�R�[�h
    ln_organization_id             NUMBER         DEFAULT NULL;                 -- �݌ɑg�DID
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
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00023
                  , iv_token_name1          => cv_tkn_info_class
                  , iv_token_value1         => iv_info_class
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg         -- ���b�Z�[�W
                  , in_new_line             => 0                  -- ���s
                  );
    --==============================================================
    -- 1.����ʃ`�F�b�N
    --==============================================================
    IF( iv_info_class NOT IN ( cv_info_class_news, cv_info_class_decision ) ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10036
                    , iv_token_name1          => cv_tkn_info_class
                    , iv_token_value1         => iv_info_class
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���O�������͍��ڂ��O���[�o���ϐ��֊i�[
    --==================================================
    gv_param_info_class := iv_info_class;
--
    --==================================================
    -- �v���t�@�C���擾(��v����ID)
    --==================================================
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==============================================================
    -- 2.�Ɩ����t�擾
    --==============================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==============================================================
    -- 3.��v���ԏ�ԃ`�F�b�N
    --==============================================================
    -- ������v���ԃ`�F�b�N
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv       -- IN  VARCHAR2 '01'(��v����INV)
    , id_base_date        => gd_process_date         -- IN  DATE     ������(�Ώۓ�)
    , ov_status           => lv_period_status        -- OUT VARCHAR2 �X�e�[�^�X
    , od_start_date       => ld_target_date_from     -- OUT DATE     ��v����(FROM)
    , od_end_date         => ld_target_date_to       -- OUT DATE     ��v����(TO)
    , ov_errbuf           => lv_errbuf               -- OUT VARCHAR2 �G���[�E���b�Z�[�W�G���[
    , ov_retcode          => lv_retcode              -- OUT VARCHAR2 ���^�[���E�R�[�h
    , ov_errmsg           => lv_errmsg               -- OUT VARCHAR2 ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( gd_process_date, 'MM' );
      gd_target_date_to   := gd_process_date;
    ELSE
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_process_date, 'RRRR/MM' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    -- �O����v���ԃ`�F�b�N
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv                  -- IN  VARCHAR2 '01'(��v����INV)
    , id_base_date        => ADD_MONTHS( gd_process_date, - 1 ) -- IN  DATE     ������(�Ώۓ�)
    , ov_status           => lv_period_status                   -- OUT VARCHAR2 �X�e�[�^�X
    , od_start_date       => ld_target_date_from                -- OUT DATE     ��v����(FROM)
    , od_end_date         => ld_target_date_to                  -- OUT DATE     ��v����(TO)
    , ov_errbuf           => lv_errbuf                          -- OUT VARCHAR2 �G���[�E���b�Z�[�W�G���[
    , ov_retcode          => lv_retcode                         -- OUT VARCHAR2 ���^�[���E�R�[�h
    , ov_errmsg           => lv_errmsg                          -- OUT VARCHAR2 ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
--
    --==================================================
    -- ����U�֏��o�^�ŏ�ID�擾
    --==================================================
    SELECT xxcok_dedu_sell_trns_info_s01.NEXTVAL
    INTO gt_selling_trns_info_id_min
    FROM DUAL
    ;
--
    --==============================================================
    -- 4.����ʂ��m�莞����
    --==============================================================
    -- ����ʂ�"1"(�m��j�̏ꍇ
    IF ( gv_param_info_class = cv_info_class_decision ) THEN
      -- �v���t�@�C��(�����l���擾)
      gt_item_code := FND_PROFILE.VALUE( cv_profile_name_02 );
      IF( gt_item_code IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_02
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- �v���t�@�C��(�݌ɑg�D�R�[�h)
      lv_organization_code := FND_PROFILE.VALUE( cv_profile_name_03 );
      IF( lv_organization_code IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_03
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- �݌ɑg�DID
      ln_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_code );
      IF ( ln_organization_id IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_coi
                      , iv_name                 => cv_msg_coi_00006
                      , iv_token_name1          => cv_tkn_org_code
                      , iv_token_value1         => lv_organization_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      --
      gn_organization_id := ln_organization_id;
      --
      -- �v���t�@�C��(�d����_�~�[�R�[�h)
      gt_supplier_dummy := FND_PROFILE.VALUE( cv_profile_name_04 );
      IF( gt_supplier_dummy IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_04
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �T���p���ѐU�փf�[�^�폜����(A-2)
    --==================================================  
    data_delite(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ����U�֌���񃋁[�v(A-3)
    --==================================================
    selling_from_loop(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- �`�[�ԍ��X�V(A-9)
    --==================================================
    update_xsti(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
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
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message               => NULL               -- ���b�Z�[�W
                  , in_new_line              => 1                  -- ���s
                  );
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- �o�͋敪
                    , iv_message               => lv_errmsg           -- ���b�Z�[�W
                    , in_new_line              => 1                   -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�L�b�v�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
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
--
END XXCOK024A04C;
/
