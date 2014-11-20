CREATE OR REPLACE PACKAGE BODY XXCOK008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A06C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : ������ѐU�֏��̍쐬�i�U�֊����j MD050_COK_008_A06
 * Version          : 2.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 * update_xsti                  �`�[�ԍ��X�V(A-8)
 * insert_xsti                  ����U�֏��̓o�^(A-6)(A-7)
 * selling_to_loop              ����U�֐��񃋁[�v(A-4)
 * selling_from_loop            ����U�֌���񃋁[�v(A-3)
 * make_correction              �U��߂��f�[�^�쐬(A-2)
 * init                         ��������(A-1)
 * submain                      ���C�������v���V�[�W��
 * main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   M.Hiruta         �V�K�쐬
 *  2009/02/18    1.1   T.OSADA          [��QCOK_042]�U�߃f�[�^�쐬���̏��nI/F�t���O�A�d��쐬�t���O�C��
 *  2009/04/02    1.2   M.Hiruta         [��QT1_0089]�U�֌��Ɛ悪�����ڋq�ł���ꍇ���A�W�v�������s���悤�C��
 *                                       [��QT1_0103]�S�����_�A�S���c�ƈ����ύX���ꂽ�ꍇ�̏��
 *                                                    ���m�Ɏ擾�ł���悤�C��
 *                                       [��QT1_0115]�̔����уe�[�u�����o���̍i���ݏ����ɂ����āA
 *                                                    �u�������v���u�[�i���v�ɏC��
 *                                       [��QT1_0190]��P�ʊ��Z���s���ɃG���[�I������悤�C��
 *                                       [��QT1_0196]�̔����уe�[�u�����o���̍i���ݏ����ɂ����āA
 *                                                    1.A-5�W�v�����u�[�i���v�̐��x��"�N��"�܂łɏC��
 *                                                    2.A-6�AA-11�W�v�����u����v����v��A-5�Ŏ擾�����u�[�i���v��
 *                                                      �̔N�����Q�Ƃ���悤�C��
 *  2009/04/27    1.3   M.Hiruta         [��QT1_0715]�U�֌��ƂȂ�f�[�^�̂������ʂ�1�̃f�[�^�ɂ����āA
 *                                                    1.�U�֊������΂��Ă���ꍇ�A�U�֊����̑傫���f�[�^��
 *                                                      ���z���񂹂�悤�C��
 *                                                    2.�U�֊������ϓ��ł���ꍇ�A�ڋq�R�[�h�̎Ⴂ���R�[�h��
 *                                                      ���z���񂹂�悤�C��
 *  2009/06/04    1.4   M.Hiruta         [��QT1_1325]�U�߃f�[�^�쐬�����ō쐬�����f�[�^�̓��t���A
 *                                                    �U�ߑΏۃf�[�^�̓��t�Ɋ�Â��Ď擾����悤�ύX
 *                                                    1.�U�߃f�[�^���挎�f�[�^�ł���ꍇ�ː挎�����t
 *                                                    2.�U�߃f�[�^�������f�[�^�ł���ꍇ�ˋƖ��������t
 *  2009/07/03    1.5   M.Hiruta         [��Q0000422]�U�߃f�[�^�쐬�����ō쐬�����Ɩ��o�^���t���A
 *                                                    �Ɩ��������t�֕ύX
 *  2009/07/13    1.6   M.Hiruta         [��Q0000514]�����ΏۂɌڋq�X�e�[�^�X�u30:���F�ρv�u50:�x�~�v�̃f�[�^��ǉ�
 *  2009/08/24    1.7   M.Hiruta         [��Q0001152]�ڋq�����i�[����ϐ��̐錾��TYPE�^�֕ύX
 *  2009/08/13    2.0   K.Yamaguchi      [��Q0000952]�p�t�H�[�}���X���P�i�č쐬�j
 *  2009/09/28    2.1   K.Yamaguchi      [E_T3_00590]�U�֊�����100���łȂ��ꍇ�̑Ή�
 *                                                   �[�i���ʂ��[���̏ꍇ�̑Ή�
 *  2009/10/15    2.2   S.Moriyama       [E_T3_00632]������ѐU�֏��o�^���ɔ���U�֌��ڋq�R�[�h��ݒ肷��悤�ɕύX
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK008A06C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
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
  -- ����
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';
  cv_msg_cok_00045                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00045';
  cv_msg_cok_10012                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10012';
  cv_msg_cok_10033                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10033';
  cv_msg_cok_10034                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10034';
  cv_msg_cok_10035                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10035';
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';
  cv_msg_cok_10452                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10452';
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
  cv_msg_cok_10463                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10463';
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
  -- �g�[�N��
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_customer_code             CONSTANT VARCHAR2(30)    := 'CUSTOMER_CODE';
  cv_tkn_customer_name             CONSTANT VARCHAR2(30)    := 'CUSTOMER_NAME';
  cv_tkn_dlv_uom_code              CONSTANT VARCHAR2(30)    := 'DLV_UOM_CODE';
  cv_tkn_from_customer_code        CONSTANT VARCHAR2(30)    := 'FROM_CUSTOMER_CODE';
  cv_tkn_from_location_code        CONSTANT VARCHAR2(30)    := 'FROM_LOCATION_CODE';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_location_code             CONSTANT VARCHAR2(30)    := 'LOCATION_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_rate                      CONSTANT VARCHAR2(30)    := 'RATE';
  cv_tkn_rate_total                CONSTANT VARCHAR2(30)    := 'RATE_TOTAL';
  cv_tkn_sales_date                CONSTANT VARCHAR2(30)    := 'SALES_DATE';
  cv_tkn_tanto_code                CONSTANT VARCHAR2(30)    := 'TANTO_CODE';
  cv_tkn_tanto_loc_code            CONSTANT VARCHAR2(30)    := 'TANTO_LOC_CODE';
  cv_tkn_to_customer_code          CONSTANT VARCHAR2(30)    := 'TO_CUSTOMER_CODE';
  cv_tkn_to_location_code          CONSTANT VARCHAR2(30)    := 'TO_LOCATION_CODE';
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- ��v����ID
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- ���̓p�����[�^�E�����
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- ����
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- �m��
  -- �ڋq�敪
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- �ڋq
  -- �ڋq�X�e�[�^�X
  cv_customer_status_30            CONSTANT VARCHAR2(2)     := '30'; -- ���F��
  cv_customer_status_40            CONSTANT VARCHAR2(2)     := '40'; -- �ڋq
  cv_customer_status_50            CONSTANT VARCHAR2(2)     := '50'; -- �x�~
  -- �ڋq�ǉ����E������ѐU��
  cv_xca_transfer_div_on           CONSTANT VARCHAR2(1)     := '1';  -- ���ѐU�ւ���
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
  cv_xsti_correction_flag_on       CONSTANT VARCHAR2(1)     := '1';  -- �I��
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
  -- �R����No
  cv_column_no                     CONSTANT VARCHAR2(2)     := '00'; -- �_�~�[�R����NO
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- �X�L�b�v����
  -- ���̓p�����[�^
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- �����
  -- ���������擾�l
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- ��v����ID
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gd_target_date_from              DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiFrom�j
  gd_target_date_to                DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiTo�j
  gt_selling_trns_info_id_min      xxcok_selling_trns_info.selling_trns_info_id%TYPE DEFAULT NULL; -- ����U�֏��o�^�ŏ�ID
  --==================================================
  -- ���ʗ�O
  --==================================================
  --*** ���������ʗ�O ***
  global_process_expt              EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                  EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�擾�G���[ ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
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
  -- ����U�֌����擾
  CURSOR get_selling_from_cur
  IS
    SELECT /*+
               LEADING(xsfi, ship_hca, ship_hcas)
               INDEX(ship_hca hz_cust_accounts_u2)
            */
           CASE
             WHEN   TRUNC( xseh.delivery_date, 'MM' )
                  = TRUNC( gd_process_date   , 'MM' )
             THEN
               gd_target_date_to
             ELSE
               LAST_DAY( gd_target_date_from )
           END                                                          AS selling_date             -- ����v���
         , xseh.sales_base_code                                         AS sales_base_code          -- ����U�֌����_�R�[�h
         , xseh.ship_to_customer_code                                   AS ship_cust_code           -- ����U�֌��ڋq�R�[�h
         , ship_hp.party_name                                           AS ship_party_name          -- ����U�֌��ڋq��
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , CASE
               WHEN   TRUNC( xseh.delivery_date, 'MM' )
                    = TRUNC( gd_process_date   , 'MM' )
               THEN
                 gd_target_date_to
               ELSE
                 LAST_DAY( gd_target_date_from )
             END
           )                                                            AS sales_staff_code         -- ����U�֌��S���c�ƃR�[�h
         , xseh.cust_gyotai_sho                                         AS ship_cust_gyotai_sho     -- �Ƒԁi�����ށj
         , bill_hca.account_number                                      AS bill_cust_code           -- ������ڋq�R�[�h
         , xsel.item_code                                               AS item_code                -- �i�ڃR�[�h
         , ROUND( SUM( xsel.dlv_qty ), 0 )                              AS dlv_qty_sum              -- �[�i����
         , xsel.dlv_uom_code                                            AS dlv_uom_code             -- �[�i�P��
         , ROUND( SUM( xsel.sale_amount ), 0 )                          AS sales_amount_sum         -- ������z
         , ROUND( SUM( xsel.pure_amount ), 0 )                          AS pure_amount_sum          -- �{�̋��z
         , ROUND( SUM(   xsel.business_cost
                       * xxcok_common_pkg.get_uom_conversion_qty_f(
                           xsel.item_code
                         , xsel.dlv_uom_code
                         , xsel.dlv_qty
                         )
                  )
                , 0
           )                                                            AS sales_cost_sum           -- ���㌴��
         , xseh.tax_code                                                AS tax_code                 -- �ŋ��R�[�h
         , xseh.tax_rate                                                AS tax_rate                 -- ����ŗ�
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
         , xsel.dlv_unit_price                                          AS dlv_unit_price           -- �[�i�P��
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
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
      AND ship_xca.chain_store_code        IS NULL
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
                     AND xca.chain_store_code           IS NULL
                     AND hca.party_id                    = hp.party_id
                     AND hp.duns_number_c               IN (   cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                           )
                     AND ROWNUM                          = 1
          )
  GROUP BY CASE
             WHEN   TRUNC( xseh.delivery_date, 'MM' )
                  = TRUNC( gd_process_date   , 'MM' )
             THEN
               gd_target_date_to
             ELSE
               LAST_DAY( gd_target_date_from )
           END
         , xseh.sales_base_code
         , xseh.ship_to_customer_code
         , ship_hp.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , CASE
               WHEN   TRUNC( xseh.delivery_date, 'MM' )
                    = TRUNC( gd_process_date   , 'MM' )
               THEN
                 gd_target_date_to
               ELSE
                 LAST_DAY( gd_target_date_from )
             END
           )
         , xseh.cust_gyotai_sho
         , bill_hca.account_number
         , xsel.item_code
         , xsel.dlv_uom_code
         , xseh.tax_code
         , xseh.tax_rate
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--         -- �̔����і��ׂ̔�����z���̔����ʁi�P���j���Ⴄ�ꍇ�͕ʃ��R�[�h�Ƃ���
--         , ( xsel.sale_amount / xsel.dlv_qty )
         , xsel.dlv_unit_price
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--  HAVING ROUND( SUM( xsel.dlv_qty ), 0 ) <> 0
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
  ;
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
      AND xca.chain_store_code         IS NULL
      AND xca.selling_transfer_div      = cv_xca_transfer_div_on
      AND hp.party_id                   = hca.party_id
      AND hp.duns_number_c             IN (   cv_customer_status_30
                                            , cv_customer_status_40
                                            , cv_customer_status_50
                                          )
  ORDER BY xsri.selling_trns_rate       ASC
         , xsri.selling_to_cust_code    DESC
  ;
  TYPE get_selling_to_ttype        IS TABLE OF get_selling_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : update_xsti
   * Description      : �`�[�ԍ��X�V(A-8)
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
    cv_slip_no_prefix              CONSTANT VARCHAR2(1)  := 'J';                       -- �`�[�ԍ��ړ���
    cv_slip_no_format              CONSTANT VARCHAR2(10) := 'FM00000000';              -- �`�[�ԍ��ړ���ȉ�����
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- �u���C�N����p�ϐ�
    lt_break_selling_date          xxcok_selling_trns_info.selling_date%TYPE DEFAULT NULL;        -- 
    lt_break_demand_to_cust_code   xxcok_selling_trns_info.demand_to_cust_code%TYPE DEFAULT NULL; -- �U�֌��ڋq�R�[�h
    lt_break_base_code             xxcok_selling_trns_info.base_code%TYPE DEFAULT NULL;           -- ���_�R�[�h
    lt_break_cust_code             xxcok_selling_trns_info.cust_code%TYPE DEFAULT NULL;           -- �ڋq�R�[�h
    lt_break_item_code             xxcok_selling_trns_info.item_code%TYPE DEFAULT NULL;           -- �i�ڃR�[�h
    -- �X�V�l�p�ϐ�
    lt_slip_no                     xxcok_selling_trns_info.slip_no  %TYPE DEFAULT NULL; -- �`�[�ԍ�
    lt_detail_no                   xxcok_selling_trns_info.detail_no%TYPE DEFAULT NULL; -- ���הԍ�
    --==================================================
    -- ���b�N�擾�J�[�\��
    --==================================================
    CURSOR update_xsti_cur
    IS
      SELECT xsti.selling_trns_info_id       AS selling_trns_info_id
           , xsti.selling_date               AS selling_date
           , xsti.demand_to_cust_code        AS demand_to_cust_code
           , xsti.base_code                  AS base_code
           , xsti.cust_code                  AS cust_code
           , xsti.item_code                  AS item_code
           , xsti.delivery_unit_price        AS delivery_unit_price
      FROM xxcok_selling_trns_info      xsti
      WHERE xsti.selling_trns_info_id >= gt_selling_trns_info_id_min
        AND xsti.request_id            = cn_request_id
        AND xsti.slip_no              IS NULL
        AND xsti.detail_no            IS NULL
      ORDER BY xsti.selling_date
             , xsti.demand_to_cust_code
             , xsti.base_code
             , xsti.cust_code
             , xsti.item_code
             , xsti.delivery_unit_price
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT
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
        SELECT cv_slip_no_prefix || TO_CHAR( xxcok_selling_trns_info_s02.NEXTVAL, cv_slip_no_format )
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
      UPDATE xxcok_selling_trns_info    xsti
      SET xsti.slip_no                  = lt_slip_no
        , xsti.detail_no                = lt_detail_no
        , xsti.last_updated_by          = cn_last_updated_by
        , xsti.last_update_date         = SYSDATE
        , xsti.last_update_login        = cn_last_update_login
        , xsti.request_id               = cn_request_id
        , xsti.program_application_id   = cn_program_application_id
        , xsti.program_id               = cn_program_id
        , xsti.program_update_date      = SYSDATE
      WHERE xsti.selling_trns_info_id   = update_xsti_rec.selling_trns_info_id
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
   * Description      : ����U�֏��̓o�^(A-6)(A-7)
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--  , in_dlv_unit_price              IN  NUMBER          -- �[�i�P��
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
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
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ����U�֏��̓o�^
    --==================================================
    INSERT INTO xxcok_selling_trns_info(
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
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD START
    , selling_from_cust_code                      -- ����U�֌��ڋq�R�[�h
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD END
    , created_by                                  -- �쐬��
    , creation_date                               -- �쐬��
    , last_updated_by                             -- �ŏI�X�V��
    , last_update_date                            -- �ŏI�X�V��
    , last_update_login                           -- �ŏI�X�V���O�C��
    , request_id                                  -- �v��ID
    , program_application_id                      -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , program_id                                  -- �R���J�����g��v���O����ID
    , program_update_date                         -- �v���O�����X�V��
    )
    VALUES(
      xxcok_selling_trns_info_s01.NEXTVAL         -- selling_trns_info_id
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--    , in_dlv_unit_price                           -- delivery_unit_price
    , i_selling_from_rec.dlv_unit_price           -- delivery_unit_price
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
    , in_sales_amount                             -- selling_amt
    , in_pure_amount                              -- selling_amt_no_tax
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
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD START
    , i_selling_from_rec.ship_cust_code           -- selling_from_cust_code
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD END
    , cn_created_by                               -- created_by
    , SYSDATE                                     -- creation_date
    , cn_last_updated_by                          -- last_updated_by
    , SYSDATE                                     -- last_update_date
    , cn_last_update_login                        -- last_update_login
    , cn_request_id                               -- request_id
    , cn_program_application_id                   -- program_application_id
    , cn_program_id                               -- program_id
    , SYSDATE                                     -- program_update_date
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--    ln_dlv_unit_price              NUMBER         DEFAULT 0;                    -- �[�i�P��
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
    -- �[���v�Z�p�W�v�ϐ�
    ln_dlv_qty_sum                 NUMBER         DEFAULT 0;                    -- �[�i����
    ln_sales_amount_sum            NUMBER         DEFAULT 0;                    -- ������z
    ln_pure_amount_sum             NUMBER         DEFAULT 0;                    -- �{�̋��z
    ln_sales_cost_sum              NUMBER         DEFAULT 0;                    -- ���㌴��
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
    -- �U�֊����`�F�b�N
    ln_selling_trns_rate_total     NUMBER         DEFAULT 0;                    -- �U�֊����̍��v��100�ƂȂ�Ȃ��ꍇ�̓G���[
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--      -- �[�i����
--      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );"
--      IF( ln_dlv_qty = 0 ) THEN"
--        -- ������z"
--        ln_sales_amount  := 0;"
--        -- �{�̋��z"
--        ln_pure_amount   := 0;"
--        -- ���㌴��"
--        ln_sales_cost    := 0;"
--      ELSE
--        -- ������z
--        ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--        -- �{�̋��z
--        ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--        -- ���㌴��
--        ln_sales_cost    := ROUND( i_selling_from_rec.sales_cost_sum   * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--      END IF;
--      -- �[���v�Z�p�W�v
--      IF( ln_dlv_qty <> 0 ) THEN
--        ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
--        ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
--        ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
--        ln_sales_cost_sum   := ln_sales_cost_sum   + ln_sales_cost;
--      END IF;
      -- �[�i����
      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- ������z
      ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- �{�̋��z
      ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- ���㌴��
      ln_sales_cost    := ROUND( i_selling_from_rec.sales_cost_sum   * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- �[���v�Z�p�W�v
      ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
      ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
      ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
      ln_sales_cost_sum   := ln_sales_cost_sum   + ln_sales_cost;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
      -- �[������
      IF( i = l_get_selling_to_tab.LAST ) THEN
        -- �[�i����
        ln_dlv_qty      := ln_dlv_qty      + i_selling_from_rec.dlv_qty_sum       - ln_dlv_qty_sum;
        -- ������z
        ln_sales_amount := ln_sales_amount + i_selling_from_rec.sales_amount_sum  - ln_sales_amount_sum;
        -- �{�̋��z
        ln_pure_amount  := ln_pure_amount  + i_selling_from_rec.pure_amount_sum   - ln_pure_amount_sum;
        -- ���㌴��
        ln_sales_cost   := ln_sales_cost   + i_selling_from_rec.sales_cost_sum    - ln_sales_cost_sum;
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
        ln_sales_cost_out   := ln_sales_cost;
      ELSE
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--        IF( ln_dlv_qty <> 0 ) THEN
--          -- �[�i�P��
--          ln_dlv_unit_price := ROUND( ln_sales_amount / ln_dlv_qty, 1 );
--          insert_xsti(
--            ov_errbuf               => lv_errbuf                                     -- �G���[�E���b�Z�[�W
--          , ov_retcode              => lv_retcode                                    -- ���^�[���E�R�[�h
--          , ov_errmsg               => lv_errmsg                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--          , i_selling_from_rec      => i_selling_from_rec                            -- ����U�֌����
--          , iv_base_code            => l_get_selling_to_tab(i).selling_to_base_code  -- ����U�֐拒�_�R�[�h
--          , iv_cust_code            => l_get_selling_to_tab(i).selling_to_cust_code  -- ����U�֐�ڋq�R�[�h
--          , iv_selling_emp_code     => l_get_selling_to_tab(i).sales_staff_code      -- ����U�֐�c�ƒS���R�[�h
--          , in_dlv_qty              => ln_dlv_qty                                    -- ����U�֐�[�i����
--          , in_sales_amount         => ln_sales_amount                               -- ����U�֐攄����z
--          , in_pure_amount          => ln_pure_amount                                -- ����U�֐�{�̋��z
--          , in_sales_cost           => ln_sales_cost                                 -- ����U�֐攄�㌴��
--          , in_dlv_unit_price       => ln_dlv_unit_price                             -- ����U�֐�[�i�P��
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            lv_end_retcode := cv_status_error;
--            RAISE global_process_expt;
--          ELSIF( lv_retcode = cv_status_warn ) THEN
--            RAISE warning_skip_expt;
--          END IF;
--        END IF;
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
      END IF;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
      --==================================================
      -- �U�֊����`�F�b�N�p�W�v
      --==================================================
      ln_selling_trns_rate_total := ln_selling_trns_rate_total + l_get_selling_to_tab(i).selling_trns_rate;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
    END LOOP sub_loop;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
    --==================================================
    -- �U�֊����`�F�b�N
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
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
    ln_dlv_qty_sum                 NUMBER         DEFAULT NULL;                 -- �[�i����
    ln_sales_amount_sum            NUMBER         DEFAULT NULL;                 -- ������z
    ln_pure_amount_sum             NUMBER         DEFAULT NULL;                 -- �{�̋��z
    ln_sales_cost_sum              NUMBER         DEFAULT NULL;                 -- ���㌴��
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--    ln_dlv_unit_price_counter      NUMBER         DEFAULT 0;                    -- �[�i�P���i���E�j
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
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
        -- ���㌴���`�F�b�N
        --==================================================
        IF( get_selling_from_rec.sales_cost_sum IS NULL ) THEN
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
        -- ����U�֌����̓o�^(A-7)
        --==================================================
        -- �[�i���ʁi���E�j
        ln_dlv_qty_counter         := get_selling_from_rec.dlv_qty_sum      * -1 + ln_dlv_qty;
        -- ������z�i���E�j
        ln_sales_amount_counter    := get_selling_from_rec.sales_amount_sum * -1 + ln_sales_amount;
        -- �{�̋��z�i���E�j
        ln_pure_amount_counter     := get_selling_from_rec.pure_amount_sum  * -1 + ln_pure_amount;
        -- ���㌴���i���E�j
        ln_sales_cost_counter      := get_selling_from_rec.sales_cost_sum   * -1 + ln_sales_cost;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--        IF( ln_dlv_qty_counter <> 0 ) THEN
--          -- �[�i�P���i���E�j
--          ln_dlv_unit_price_counter  := ROUND( ln_sales_amount_counter / ln_dlv_qty_counter, 1 );
--          insert_xsti(
--            ov_errbuf               => lv_errbuf                                  -- �G���[�E���b�Z�[�W
--          , ov_retcode              => lv_retcode                                 -- ���^�[���E�R�[�h
--          , ov_errmsg               => lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--          , i_selling_from_rec      => get_selling_from_rec                       -- ����U�֌����
--          , iv_base_code            => get_selling_from_rec.sales_base_code       -- ����U�֌����_�R�[�h
--          , iv_cust_code            => get_selling_from_rec.ship_cust_code        -- ����U�֌��ڋq�R�[�h
--          , iv_selling_emp_code     => get_selling_from_rec.sales_staff_code      -- ����U�֌��c�ƒS���R�[�h
--          , in_dlv_qty              => ln_dlv_qty_counter                         -- �[�i���ʁi���E�j
--          , in_sales_amount         => ln_sales_amount_counter                    -- ������z�i���E�j
--          , in_pure_amount          => ln_pure_amount_counter                     -- �{�̋��z�i���E�j
--          , in_sales_cost           => ln_sales_cost_counter                      -- ���㌴���i���E�j
--          , in_dlv_unit_price       => ln_dlv_unit_price_counter                  -- �[�i�P���i���E�j
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            lv_end_retcode := cv_status_error;
--            RAISE global_process_expt;
--          ELSIF( lv_retcode = cv_status_warn ) THEN
--            RAISE warning_skip_expt;
--          END IF;
--        END IF;
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
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
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
          gn_error_cnt := gn_error_cnt + 1;
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
   * Procedure Name   : make_correction
   * Description      : �U��߂��f�[�^�쐬(A-2)
   ***********************************************************************************/
  PROCEDURE make_correction(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'make_correction';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���b�N�擾�J�[�\��
    --==================================================
    CURSOR get_xsti_lock_cur
    IS
      SELECT xsti.selling_trns_info_id       AS selling_trns_info_id       -- ������ѐU�֏��ID
           , xsti.selling_trns_type          AS selling_trns_type          -- ���ѐU�֋敪
           , xsti.slip_no                    AS slip_no                    -- �`�[�ԍ�
           , xsti.detail_no                  AS detail_no                  -- ���הԍ�
           , xsti.selling_date               AS selling_date               -- ����v���
           , xsti.selling_type               AS selling_type               -- ����敪
           , xsti.selling_return_type        AS selling_return_type        -- ����ԕi�敪
           , xsti.delivery_slip_type         AS delivery_slip_type         -- �[�i�`�[�敪
           , xsti.base_code                  AS base_code                  -- ���_�R�[�h
           , xsti.cust_code                  AS cust_code                  -- �ڋq�R�[�h
           , xsti.selling_emp_code           AS selling_emp_code           -- �S���҉c�ƃR�[�h
           , xsti.cust_state_type            AS cust_state_type            -- �ڋq�Ƒԋ敪
           , xsti.delivery_form_type         AS delivery_form_type         -- �[�i�`�ԋ敪
           , xsti.article_code               AS article_code               -- �����R�[�h
           , xsti.card_selling_type          AS card_selling_type          -- �J�[�h����敪
           , xsti.checking_date              AS checking_date              -- ������
           , xsti.demand_to_cust_code        AS demand_to_cust_code        -- ������ڋq�R�[�h
           , xsti.h_c                        AS h_c                        -- �g���b
           , xsti.column_no                  AS column_no                  -- �R����NO
           , xsti.item_code                  AS item_code                  -- �i�ڃR�[�h
           , xsti.qty                        AS qty                        -- ����
           , xsti.unit_type                  AS unit_type                  -- �P��
           , xsti.delivery_unit_price        AS delivery_unit_price        -- �[�i�P��
           , xsti.selling_amt                AS selling_amt                -- ������z
           , xsti.selling_amt_no_tax         AS selling_amt_no_tax         -- ������z(�Ŕ���)
           , xsti.trading_cost               AS trading_cost               -- �c�ƌ���
           , xsti.selling_cost_amt           AS selling_cost_amt           -- ���㌴�����z
           , xsti.tax_code                   AS tax_code                   -- ����ŃR�[�h
           , xsti.tax_rate                   AS tax_rate                   -- ����ŗ�
           , xsti.delivery_base_code         AS delivery_base_code         -- �[�i���_�R�[�h
           , xsti.report_decision_flag       AS report_decision_flag       -- ����m��t���O
           , xsti.org_slip_number            AS org_slip_number            -- ���`�[�ԍ�
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD START
           , xsti.selling_from_cust_code     AS selling_from_cust_code     -- ����U�֌��ڋq�R�[�h
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD END
      FROM xxcok_selling_trns_info      xsti
      WHERE xsti.selling_date     BETWEEN gd_target_date_from
                                      AND gd_target_date_to
        AND xsti.report_decision_flag   = cv_xsti_decision_flag_news
        AND xsti.correction_flag        = cv_xsti_correction_flag_off
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ������ѐU�֏��e�[�u�����b�N�擾
    --==================================================
    << xsti_lock_loop >>
    FOR get_xsti_lock_rec IN get_xsti_lock_cur LOOP
      --==================================================
      -- ������ѐU�֏��e�[�u���o�^
      --==================================================
      INSERT INTO xxcok_selling_trns_info(
        selling_trns_info_id                           -- ������ѐU�֏��ID
      , selling_trns_type                              -- ���ѐU�֋敪
      , slip_no                                        -- �`�[�ԍ�
      , detail_no                                      -- ���הԍ�
      , selling_date                                   -- ����v���
      , selling_type                                   -- ����敪
      , selling_return_type                            -- ����ԕi�敪
      , delivery_slip_type                             -- �[�i�`�[�敪
      , base_code                                      -- ���_�R�[�h
      , cust_code                                      -- �ڋq�R�[�h
      , selling_emp_code                               -- �S���҉c�ƃR�[�h
      , cust_state_type                                -- �ڋq�Ƒԋ敪
      , delivery_form_type                             -- �[�i�`�ԋ敪
      , article_code                                   -- �����R�[�h
      , card_selling_type                              -- �J�[�h����敪
      , checking_date                                  -- ������
      , demand_to_cust_code                            -- ������ڋq�R�[�h
      , h_c                                            -- �g���b
      , column_no                                      -- �R����NO
      , item_code                                      -- �i�ڃR�[�h
      , qty                                            -- ����
      , unit_type                                      -- �P��
      , delivery_unit_price                            -- �[�i�P��
      , selling_amt                                    -- ������z
      , selling_amt_no_tax                             -- ������z(�Ŕ���)
      , trading_cost                                   -- �c�ƌ���
      , selling_cost_amt                               -- ���㌴�����z
      , tax_code                                       -- ����ŃR�[�h
      , tax_rate                                       -- ����ŗ�
      , delivery_base_code                             -- �[�i���_�R�[�h
      , registration_date                              -- �Ɩ��o�^���t
      , correction_flag                                -- �U�߃t���O
      , report_decision_flag                           -- ����m��t���O
      , info_interface_flag                            -- ���nIF�t���O
      , gl_interface_flag                              -- �d��쐬�t���O
      , org_slip_number                                -- ���`�[�ԍ�
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD START
      , selling_from_cust_code                         -- ����U�֌��ڋq�R�[�h
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD END
      , created_by                                     -- �쐬��
      , creation_date                                  -- �쐬��
      , last_updated_by                                -- �ŏI�X�V��
      , last_update_date                               -- �ŏI�X�V��
      , last_update_login                              -- �ŏI�X�V���O�C��
      , request_id                                     -- �v��ID
      , program_application_id                         -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , program_id                                     -- �R���J�����g��v���O����ID
      , program_update_date                            -- �v���O�����X�V��
      )
      VALUES(
        xxcok_selling_trns_info_s01.NEXTVAL            -- selling_trns_info_id
      , get_xsti_lock_rec.selling_trns_type            -- selling_trns_type
      , get_xsti_lock_rec.slip_no                      -- slip_no
      , get_xsti_lock_rec.detail_no                    -- detail_no
      , CASE
          WHEN   TRUNC( gd_process_date               , 'MM' )
               = TRUNC( get_xsti_lock_rec.selling_date, 'MM' )
          THEN
            gd_target_date_to
          ELSE
            LAST_DAY( gd_target_date_from )
        END                                            -- selling_date
      , get_xsti_lock_rec.selling_type                 -- selling_type
      , get_xsti_lock_rec.selling_return_type          -- selling_return_type
      , get_xsti_lock_rec.delivery_slip_type           -- delivery_slip_type
      , get_xsti_lock_rec.base_code                    -- base_code
      , get_xsti_lock_rec.cust_code                    -- cust_code
      , get_xsti_lock_rec.selling_emp_code             -- selling_emp_code
      , get_xsti_lock_rec.cust_state_type              -- cust_state_type
      , get_xsti_lock_rec.delivery_form_type           -- delivery_form_type
      , get_xsti_lock_rec.article_code                 -- article_code
      , get_xsti_lock_rec.card_selling_type            -- card_selling_type
      , get_xsti_lock_rec.checking_date                -- checking_date
      , get_xsti_lock_rec.demand_to_cust_code          -- demand_to_cust_code
      , get_xsti_lock_rec.h_c                          -- h_c
      , get_xsti_lock_rec.column_no                    -- column_no
      , get_xsti_lock_rec.item_code                    -- item_code
      , get_xsti_lock_rec.qty                          -- qty
      , get_xsti_lock_rec.unit_type                    -- unit_type
      , get_xsti_lock_rec.delivery_unit_price          -- delivery_unit_price
      , -1 * get_xsti_lock_rec.selling_amt             -- selling_amt
      , -1 * get_xsti_lock_rec.selling_amt_no_tax      -- selling_amt_no_tax
      , -1 * get_xsti_lock_rec.trading_cost            -- trading_cost
      , get_xsti_lock_rec.selling_cost_amt             -- selling_cost_amt
      , get_xsti_lock_rec.tax_code                     -- tax_code
      , get_xsti_lock_rec.tax_rate                     -- tax_rate
      , get_xsti_lock_rec.delivery_base_code           -- delivery_base_code
      , gd_process_date                                -- registration_date
      , cv_xsti_correction_flag_on                     -- correction_flag
      , get_xsti_lock_rec.report_decision_flag         -- report_decision_flag
      , cv_xsti_info_if_flag_no                        -- info_interface_flag
      , cv_xsti_gl_if_flag_no                          -- gl_interface_flag
      , get_xsti_lock_rec.org_slip_number              -- org_slip_number
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD START
      , get_xsti_lock_rec.selling_from_cust_code       -- selling_from_cust_code
-- 2009/10/15 Ver.2.2 [��QE_T3_00632] SCS S.Moriyama ADD END
      , cn_created_by                                  -- created_by
      , SYSDATE                                        -- creation_date
      , cn_last_updated_by                             -- last_updated_by
      , SYSDATE                                        -- last_update_date
      , cn_last_update_login                           -- last_update_login
      , cn_request_id                                  -- request_id
      , cn_program_application_id                      -- program_application_id
      , cn_program_id                                  -- program_id
      , SYSDATE                                        -- program_update_date
      );
      --==================================================
      -- ������ѐU�֏��e�[�u���X�V
      --==================================================
      UPDATE xxcok_selling_trns_info    xsti
      SET xsti.correction_flag        = cv_xsti_correction_flag_on
        , xsti.last_updated_by        = cn_last_updated_by
        , xsti.last_update_date       = SYSDATE
        , xsti.last_update_login      = cn_last_update_login
        , xsti.request_id             = cn_request_id
        , xsti.program_application_id = cn_program_application_id
        , xsti.program_id             = cn_program_id
        , xsti.program_update_date    = SYSDATE
      WHERE xsti.selling_trns_info_id = get_xsti_lock_rec.selling_trns_info_id
      ;
    END LOOP xsti_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10012
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END make_correction;
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
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lb_period_status               BOOLEAN        DEFAULT TRUE;                 -- ��v���ԃX�e�[�^�X�`�F�b�N�p�߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
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
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    --==================================================
    -- �v���O�������͍��ڃ`�F�b�N
    --==================================================
    -- �����
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
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
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
    --==================================================
    -- ������v���ԃX�e�[�^�X�`�F�b�N
    --==================================================
    lb_period_status := xxcok_common_pkg.check_acctg_period_f(
                          in_set_of_books_id           => gn_set_of_books_id         -- IN NUMBER   ��v����ID
                        , id_proc_date                 => gd_process_date            -- IN DATE     ������(�Ώۓ�)
                        , iv_application_short_name    => cv_appl_short_name_ar      -- IN VARCHAR2 �A�v���P�[�V�����Z�k��
                        );
    IF( lb_period_status = TRUE ) THEN
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
    --==================================================
    -- �O����v���ԃX�e�[�^�X�`�F�b�N
    --==================================================
    lb_period_status := xxcok_common_pkg.check_acctg_period_f(
                          in_set_of_books_id           => gn_set_of_books_id                 -- IN NUMBER   ��v����ID
                        , id_proc_date                 => ADD_MONTHS( gd_process_date, - 1 ) -- IN DATE     ������(�Ώۓ�)
                        , iv_application_short_name    => cv_appl_short_name_ar              -- IN VARCHAR2 �A�v���P�[�V�����Z�k��
                        );
    IF( lb_period_status = TRUE ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
    --==================================================
    -- ����U�֏��o�^�ŏ�ID�擾
    --==================================================
    SELECT xxcok_selling_trns_info_s01.NEXTVAL
    INTO gt_selling_trns_info_id_min
    FROM DUAL
    ;
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
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
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
    -- �U��߂��f�[�^�쐬(A-2)
    --==================================================
    make_correction(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �`�[�ԍ��X�V(A-8)
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
END XXCOK008A06C;
/
