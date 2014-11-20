CREATE OR REPLACE PACKAGE BODY XXCOK021A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A06R(body)
 * Description      : �����≮�Ɋւ��鐿�����ƌ��Ϗ���˂����킹�A�i�ڕʂɐ������ƌ��Ϗ��̓��e��\��
 * MD.050           : �≮�̔������x���`�F�b�N�\ MD050_COK_021_A06
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_wholesale_pay      ���[�N�e�[�u���f�[�^�폜(A-6)
 *  start_svf              SVF�N��(A-5)
 *  ins_wholesale_pay      ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  get_target_data        �Ώۃf�[�^�擾(A-2)�E���Ϗ����擾(A-3)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Iwabuchi       �V�K�쐬
 *  2009/02/05    1.1   K.Iwabuchi       [��QCOK_011] �p�����[�^�s��Ή�
 *  2009/02/06    1.2   K.Iwabuchi       [��QCOK_015] �N�C�b�N�R�[�h�r���[�L�����t����ǉ��Ή�
 *  2009/02/17    1.3   K.Iwabuchi       [��QCOK_036] �o�^���ڎZ�o�C���A���Ϗ����擾�C���A�c�ƒP��ID�����ǉ��A���������f�ǉ�
 *  2009/04/17    1.4   M.Hiruta         [��QT1_0414] �������z��0�ł���ꍇ�A��U�E�≮�}�[�W���E�g�����3����
 *                                                     �l���o�͂���Ȃ��悤�ύX
 *                                                     ��U�̒l���}�C�i�X�ł����Ă��A���v�̒��낪�����悤�ύX
 *  2009/09/01    1.5   S.Moriyama       [��Q0001230] OPM�i�ڃ}�X�^�擾�����ǉ�
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK021A06R';
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
  cv_msg_code_00018          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00018';          -- ���_�R�[�h(���̓p�����[�^)
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- �Ɩ��������t�擾�G���[
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF�N��API�G���[
  cv_msg_code_00068          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00068';          -- �≮�Ǘ��R�[�h(���̓p�����[�^)
  cv_msg_code_00069          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00069';          -- �ڋq�R�[�h(���̓p�����[�^)
  cv_msg_code_00070          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00070';          -- �≮������R�[�h(���̓p�����[�^)
  cv_msg_code_00071          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00071';          -- �x���N����(���̓p�����[�^)
  cv_msg_code_00072          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00072';          -- ����Ώ۔N��(���̓p�����[�^)
  cv_msg_code_10043          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10043';          -- �f�[�^�폜�G���[
  cv_msg_code_10044          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10044';          -- �f�[�^�^�`�F�b�N�G���[(�x���N����)
  cv_msg_code_10045          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10045';          -- �f�[�^�^�`�F�b�N�G���[(����Ώ۔N��)
  cv_msg_code_10047          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10047';          -- ���Ϗ����擾�G���[
  cv_msg_code_10392          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10392';          -- ���b�N�擾�G���[
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی���
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- ��������
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[����
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I��
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_token_location_code     CONSTANT VARCHAR2(15)  := 'LOCATION_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(15)  := 'CUST_CODE';
  cv_token_pay_date          CONSTANT VARCHAR2(15)  := 'PAY_DATE';
  cv_token_target_period     CONSTANT VARCHAR2(15)  := 'TARGET_PERIOD';
  cv_token_profile           CONSTANT VARCHAR2(15)  := 'PROFILE';
  cv_token_org_code          CONSTANT VARCHAR2(15)  := 'ORG_CODE';
  cv_token_ctrl_code         CONSTANT VARCHAR2(15)  := 'CONTROL_CODE';
  cv_token_balance_code      CONSTANT VARCHAR2(15)  := 'BALANCE_CODE';
  cv_token_item_code         CONSTANT VARCHAR2(15)  := 'ITEM_CODE';
  cv_token_demand_price      CONSTANT VARCHAR2(15)  := 'DEMAND_PRICE';
  cv_token_demand_unit       CONSTANT VARCHAR2(15)  := 'DEMAND_UNIT';
  cv_token_request_id        CONSTANT VARCHAR2(15)  := 'REQUEST_ID';
  cv_token_count             CONSTANT VARCHAR2(15)  := 'COUNT';
  -- �v���t�@�C��
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- �݌ɑg�D�R�[�h_�c�Ƒg�D
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';                    -- �c�ƒP��ID
  -- �t�H�[�}�b�g
  cv_format_fxyyyy_mm_dd     CONSTANT VARCHAR2(12)  := 'FXYYYY/MM/DD';
  cv_format_fxyyyy_mm        CONSTANT VARCHAR2(9)   := 'FXYYYY/MM';
  cv_format_yyyy_mm_dd       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_format_yyyy_mm          CONSTANT VARCHAR2(7)   := 'YYYY/MM';
  cv_format_yyyymm           CONSTANT VARCHAR2(6)   := 'YYYYMM';
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- �L��
  cv_hyphen                  CONSTANT VARCHAR2(1)   := '-';
  -- ���l
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  cn_number_100              CONSTANT NUMBER        := 100;
  -- �o�͋敪
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG'; -- �o�͋敪
  -- ���s�t���O
  cv_primary_flag            CONSTANT VARCHAR2(1)   := 'Y';   -- ���s
  -- �^�C�v
  cv_lookup_type_tonya       CONSTANT VARCHAR2(20)  := 'XXCMM_TONYA_CODE';
  cv_lookup_type_bank        CONSTANT VARCHAR2(20)  := 'JP_BANK_ACCOUNT_TYPE';
  -- �����P��
  cv_unit_type_cs            CONSTANT VARCHAR2(1)   := '2';   -- C/S
  -- SVF�N���p�����[�^
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK021A06R';       -- ���[ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- �o�͋敪(PDF�o��)
  cv_extension               CONSTANT VARCHAR2(10)  := '.pdf';               -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK021A06S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK021A06S.vrq';   -- �N�G���[�l���t�@�C����
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt                NUMBER        DEFAULT 0;     -- �Ώی���
  gn_normal_cnt                NUMBER        DEFAULT 0;     -- ���팏��
  gn_error_cnt                 NUMBER        DEFAULT 0;     -- �G���[����
  gv_org_code_sales            VARCHAR2(50)  DEFAULT NULL;  -- �v���t�@�C���l(�݌ɑg�D�R�[�h_�c�Ƒg�D)
  gn_org_id_sales              NUMBER        DEFAULT NULL;  -- �݌ɑg�DID
  gn_org_id                    NUMBER        DEFAULT NULL;  -- �c�ƒP��ID
  gd_process_date              DATE          DEFAULT NULL;  -- �Ɩ��������t
  gv_no_data_msg               VARCHAR2(30)  DEFAULT NULL;  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  gn_market_amt                NUMBER        DEFAULT NULL;  -- ���l
  gn_allowance_amt             NUMBER        DEFAULT NULL;  -- �l��(���߂�)
  gn_normal_store_deliver_amt  NUMBER        DEFAULT NULL;  -- �ʏ�X�[
  gn_once_store_deliver_amt    NUMBER        DEFAULT NULL;  -- ����X�[
  gn_net_selling_price         NUMBER        DEFAULT NULL;  -- NET���i
  gv_estimated_type            VARCHAR2(1)   DEFAULT NULL;  -- ���ϋ敪
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  CURSOR g_target_cur(
    iv_base_code             IN VARCHAR2  -- ���_�R�[�h
  , iv_payment_date          IN VARCHAR2  -- �x���N����
  , lv_selling_month         IN VARCHAR2  -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN VARCHAR2  -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN VARCHAR2  -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN VARCHAR2  -- �≮������R�[�h
  )
  IS
    SELECT xwbl.wholesale_bill_detail_id  AS wholesale_bill_detail_id       -- �≮����������ID
         , xwbl.bill_no                   AS bill_no                        -- ������No
         , xwbh.base_code                 AS base_code                      -- ���_�R�[�h
         , xwbh.cust_code                 AS cust_code                      -- �ڋq�R�[�h
         , xwbl.sales_outlets_code        AS sales_outlets_code             -- �≮������R�[�h
         , xwbl.selling_month             AS selling_month                  -- ����Ώ۔N��
         , NVL( xwbl.item_code, xwbl.acct_code || cv_hyphen || xwbl.sub_acct_code )
                                          AS item_code                      -- �i�ڃR�[�h(NULL�F����ȖڃR�[�h-�⏕�ȖڃR�[�h)
         , xwbl.demand_qty                AS demand_qty                     -- ��������
         , xwbl.demand_unit_price         AS demand_unit_price              -- �����P��
         , xwbl.demand_amt                AS demand_amt                     -- �������z
         , xwbl.demand_unit_type          AS demand_unit_type               -- �����P��
         , xwbl.payment_qty               AS payment_qty                    -- �x������
         , xwbl.payment_unit_price        AS payment_unit_price             -- �x���P��
         , xwbl.payment_amt               AS payment_amt                    -- �x�����z
         , xwbh.supplier_code             AS supplier_code                  -- �d����R�[�h
         , xwbl.acct_code                 AS acct_code                      -- ����ȖڃR�[�h
         , xwbl.sub_acct_code             AS sub_acct_code                  -- �⏕�ȖڃR�[�h
         , xca.wholesale_ctrl_code        AS wholesale_ctrl_code            -- �≮�Ǘ��R�[�h
         , hp.party_name                  AS cust_name                      -- �ڋq����
         , hp2.party_name                 AS sales_outlets_name             -- �≮�����於
         , NVL( item.item_short_name, xav.description || cv_hyphen || xsav.description )
                                          AS item_short_name                -- �i���E����(NULL�F����Ȗږ���-�⏕�Ȗږ���)
         , item.inc_num                   AS inc_num                        -- ����
         , CASE WHEN NVL( TO_DATE( item.fixed_price_start_date, cv_format_yyyy_mm_dd ) , gd_process_date ) > gd_process_date
           THEN item.old_fixed_price                                        -- ���艿
           ELSE item.new_fixed_price                                        -- �艿(�V)
           END                            AS fixed_price                    -- �艿
         , pv.vendor_name                 AS vendor_name                    -- �d���於
         , bank.bank_name                 AS bank_name                      -- ��s��
         , bank.bank_branch_name          AS bank_branch_name               -- ��s�x�X��
         , bank.bank_account_type         AS bank_account_type              -- �������
         , bank.bank_account_num          AS bank_account_num               -- �����ԍ�
         , xlv.meaning                    AS wholesale_ctrl_name            -- �≮�Ǘ���
    FROM   xxcok_wholesale_bill_head      xwbh                              -- �≮�������w�b�_�[�e�[�u��
         , xxcok_wholesale_bill_line      xwbl                              -- �≮���������׃e�[�u��
         , hz_cust_accounts               hca                               -- �ڋq�}�X�^
         , hz_cust_accounts               hca2                              -- �ڋq�}�X�^(�≮������p)
         , hz_parties                     hp                                -- �p�[�e�B�}�X�^
         , hz_parties                     hp2                               -- �p�[�e�B�}�X�^(�≮������)
         , xxcmm_cust_accounts            xca                               -- �ڋq�ǉ����
         , xx03_accounts_v                xav                               -- ����Ȗڃr���[
         , xx03_sub_accounts_v            xsav                              -- �⏕�Ȗڃr���[
         , po_vendors                     pv                                -- �d����}�X�^
         , po_vendor_sites_all            pvsa                              -- �d����T�C�g�}�X�^
         , xxcok_lookups_v                xlv                               -- �N�C�b�N�R�[�h�r���[
         ,( SELECT msib.segment1                 AS item_code               -- �i�ڃR�[�h
                 , TO_NUMBER( iimb.attribute4 )  AS old_fixed_price         -- ���艿
                 , TO_NUMBER( iimb.attribute5 )  AS new_fixed_price         -- �艿(�V)
                 , iimb.attribute6               AS fixed_price_start_date  -- �艿�K�p�J�n��
                 , TO_NUMBER( iimb.attribute11 ) AS inc_num                 -- ����
                 , ximb.item_short_name          AS item_short_name         -- �i���E����
            FROM   mtl_system_items_b  msib                                 -- �i�ڃ}�X�^
                 , ic_item_mst_b       iimb                                 -- OPM�i�ڃ}�X�^
                 , xxcmn_item_mst_b    ximb                                 -- OPM�i�ڃA�h�I���}�X�^
            WHERE  msib.organization_id  = gn_org_id_sales
            AND    msib.segment1         = iimb.item_no
            AND    iimb.item_id          = ximb.item_id
-- 2009/09/01 Ver.1.5 [��Q0001230] SCS S.Moriyama ADD START
            AND    gd_process_date BETWEEN ximb.start_date_active
                                       AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/01 Ver.1.5 [��Q0001230] SCS S.Moriyama ADD END
          ) item
         ,( SELECT abau.vendor_id        AS vendor_id                       -- �����d����ID
                 , abau.vendor_site_id   AS vendor_site_id                  -- �����d����T�C�gID
                 , abb.bank_name         AS bank_name                       -- ��s��
                 , abb.bank_branch_name  AS bank_branch_name                -- ��s�x�X��
                 , hl.meaning            AS bank_account_type               -- �������
                 , abaa.bank_account_num AS bank_account_num                -- �����ԍ�
            FROM   ap_bank_branches              abb                        -- ��s�x�X���
                 , ap_bank_accounts_all          abaa                       -- ��s�������
                 , ap_bank_account_uses_all      abau                       -- ��s�����g�p���
                 , hr_lookups                    hl                         -- �N�C�b�N�R�[�h
            WHERE  abau.external_bank_account_id = abaa.bank_account_id
            AND    abaa.bank_branch_id           = abb.bank_branch_id
            AND    abaa.org_id                   = gn_org_id
            AND    abaa.bank_account_type        = hl.lookup_code(+)
            AND    hl.lookup_type(+)             = cv_lookup_type_bank
            AND    abau.primary_flag             = cv_primary_flag
            AND    abau.org_id                   = gn_org_id
            AND    ( abau.start_date            <= gd_process_date OR abau.start_date IS NULL )
            AND    ( abau.end_date              >= gd_process_date OR abau.end_date   IS NULL )
          ) bank
    WHERE  xwbh.expect_payment_date      = TO_DATE( iv_payment_date, cv_format_fxyyyy_mm_dd )
    AND    xwbh.base_code                = NVL( iv_base_code, xwbh.base_code )
    AND    xwbh.cust_code                = NVL( iv_cust_code, xwbh.cust_code )
    AND    xwbl.sales_outlets_code       = NVL( iv_sales_outlets_code, xwbl.sales_outlets_code )
    AND    xwbl.selling_month            = NVL( lv_selling_month, xwbl.selling_month )
    AND    xca.wholesale_ctrl_code       = NVL( iv_wholesale_code_admin, xca.wholesale_ctrl_code )
    AND    xca.customer_id               = hca.cust_account_id
    AND    hca.account_number            = xwbh.cust_code
    AND    hca2.account_number           = xwbl.sales_outlets_code
    AND    hca.party_id                  = hp.party_id
    AND    hca2.party_id                 = hp2.party_id
    AND    xca.wholesale_ctrl_code       = xlv.lookup_code
    AND    xlv.lookup_type               = cv_lookup_type_tonya
    AND    gd_process_date               BETWEEN NVL( xlv.start_date_active, gd_process_date )
                                             AND NVL( xlv.end_date_active,   gd_process_date )
    AND    xwbl.acct_code                = xav.flex_value(+)
    AND    xwbl.sub_acct_code            = xsav.flex_value(+)
    AND    xwbl.acct_code                = xsav.parent_flex_value_low(+)
    AND    xwbl.item_code                = item.item_code(+)
    AND    xwbh.supplier_code            = pv.segment1
    AND    pv.vendor_id                  = pvsa.vendor_id
    AND    pvsa.vendor_id                = bank.vendor_id(+)
    AND    pvsa.vendor_site_id           = bank.vendor_site_id(+)
    AND    pvsa.org_id                   = gn_org_id
    AND    ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )
    AND    xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
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
      FROM   xxcok_rep_wholesale_pay  xrwp
      WHERE  xrwp.request_id = cn_request_id
      FOR UPDATE OF xrwp.wholesale_bill_detail_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �≮�̔������x���`�F�b�N���[���[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  wholesale_pay_cur;
    CLOSE wholesale_pay_cur;
    -- ===============================================
    -- �≮�̔������x���`�F�b�N���[���[�N�e�[�u���f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_wholesale_pay  xrwp
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
                    , iv_name         => cv_msg_code_10392
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
  , iv_base_code                 IN VARCHAR2   -- ���_�R�[�h
  , iv_payment_date              IN VARCHAR2   -- �x���N����
  , iv_selling_month             IN VARCHAR2   -- ����Ώ۔N��
  , iv_wholesale_code_admin      IN VARCHAR2   -- �≮�Ǘ��R�[�h
  , iv_cust_code                 IN VARCHAR2   -- �ڋq�R�[�h
  , iv_sales_outlets_code        IN VARCHAR2   -- �≮������R�[�h
  , in_i                         IN NUMBER     -- LOOP�J�E���^
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
  , in_backmargin_amt            IN NUMBER DEFAULT NULL -- �̔��萔��
  , in_sales_support_amt         IN NUMBER DEFAULT NULL -- �̔����^��
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
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
    ln_payment_qty           NUMBER         DEFAULT NULL;              -- �x������
    ln_payment_unit_price    NUMBER         DEFAULT NULL;              -- �x���P��
    ln_payment_amt           NUMBER         DEFAULT NULL;              -- �x�����z
    ln_market_amt            NUMBER         DEFAULT NULL;              -- ���l
    ln_net_pct               NUMBER         DEFAULT NULL;              -- NET�|��
    ln_margin_pct            NUMBER         DEFAULT NULL;              -- �}�[�W����
    ln_coverage_amt          NUMBER         DEFAULT NULL;              -- ��U
    ln_wholesale_margin_sum  NUMBER         DEFAULT NULL;              -- �≮�}�[�W��
    ln_cs_margin_amt         NUMBER         DEFAULT NULL;              -- C/S�}�[�W���z
    ln_expansion_sales_amt   NUMBER         DEFAULT NULL;              -- �g����
    ln_misc_acct_amt         NUMBER         DEFAULT NULL;              -- ���̑��Ȗ�
    lv_selling_month         VARCHAR2(7)    DEFAULT NULL;              -- ����Ώ۔N��
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
      -- �x�����ʁE�x���P���E�x�����z(�������ʁE�����P���E�������z�Ƃ��ׂĈ�v����ꍇ�ANULL)
      -- ===============================================
      ln_payment_qty        := g_target_tab( in_i ).payment_qty;         -- �x������
      ln_payment_unit_price := g_target_tab( in_i ).payment_unit_price;  -- �x���P��
      ln_payment_amt        := g_target_tab( in_i ).payment_amt;         -- �x�����z
      IF (    ln_payment_qty        = g_target_tab( in_i ).demand_qty )
        AND ( ln_payment_unit_price = g_target_tab( in_i ).demand_unit_price )
        AND ( ln_payment_amt        = g_target_tab( in_i ).demand_amt )
      THEN
        ln_payment_qty        := NULL;
        ln_payment_unit_price := NULL;
        ln_payment_amt        := NULL;
      END IF;
      -- ===============================================
      -- (��)���l(���l-�l��)
      -- ===============================================
      ln_market_amt := NVL( gn_market_amt, 0 ) - NVL( gn_allowance_amt, 0 );
      -- ===============================================
      -- NET�|��(NET���i/�艿*100)  �����P�ʂ�2(C/S)�̏ꍇ�ANET���i/����/�艿*100
      -- ===============================================
      -- �艿��NULL�܂���0�̏ꍇ�ANET�|����0
      IF (   g_target_tab( in_i ).fixed_price IS NULL )
        OR ( g_target_tab( in_i ).fixed_price = cn_number_0 )
      THEN
        ln_net_pct := cn_number_0;
      ELSE
        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          -- ������NULL�܂���0�̏ꍇ�ANET�|����0
          IF (   g_target_tab( in_i ).inc_num IS NULL )
            OR ( g_target_tab( in_i ).inc_num = cn_number_0 )
          THEN
            ln_net_pct := cn_number_0;
          ELSE
            ln_net_pct := NVL( gn_net_selling_price, 0 ) / g_target_tab( in_i ).inc_num / g_target_tab( in_i ).fixed_price * cn_number_100;
          END IF;
        ELSE
          ln_net_pct := NVL( gn_net_selling_price, 0 ) / g_target_tab( in_i ).fixed_price * cn_number_100;
        END IF;
      END IF;
      -- ===============================================
      -- �}�[�W����((����X�[-NET���i)/����X�[*100)  ����X�[��NULL�E0�ȊO�̏ꍇ����X�[�ANULL�܂���0�̏ꍇ�ʏ�X�[
      -- ===============================================
      IF (    gn_once_store_deliver_amt IS NOT NULL )
        AND ( gn_once_store_deliver_amt <> cn_number_0 )
      THEN
        ln_margin_pct := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) / gn_once_store_deliver_amt * cn_number_100;
      ELSE
        IF (    gn_normal_store_deliver_amt IS NOT NULL )
          AND ( gn_normal_store_deliver_amt <> cn_number_0 )
        THEN
          ln_margin_pct := ( gn_normal_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) / gn_normal_store_deliver_amt * cn_number_100;
        ELSE
          ln_margin_pct := cn_number_0;
        END IF;
      END IF;
      -- ===============================================
      -- C/S�}�[�W���z((����X�[-NET���i)*����  ����X�[��NULL�E0�ȊO�̏ꍇ����X�[�ANULL�܂���0�̏ꍇ�ʏ�X�[  �����P�ʂ�2(C/S)�̏ꍇ�A�������|���Ȃ�
      -- ===============================================
      IF (    gn_once_store_deliver_amt IS NOT NULL )
        AND ( gn_once_store_deliver_amt <> cn_number_0 )
      THEN
        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          ln_cs_margin_amt := gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 );
        ELSE
          ln_cs_margin_amt := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).inc_num, 0 );
        END IF;
      ELSE
        IF ( g_target_tab( in_i ).demand_unit_type = cv_unit_type_cs ) THEN
          ln_cs_margin_amt := NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 );
        ELSE
          ln_cs_margin_amt := ( NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).inc_num, 0 );
        END IF;
      END IF;
      -- ===============================================
      -- ��U(((��)���l-�ʏ�X�[)*�x������)
      -- �ȉ��̏ꍇ��U��0
      -- (��)���l-�ʏ�X�[��0��菬�����ꍇ
      -- A-3.�̔��萔����NULL�̏ꍇ
      -- A-3.�̔��萔����0�ȉ��̏ꍇ
      -- ===============================================
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
--      IF ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 ) THEN
      IF ( ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) < cn_number_0 )
        OR ( ( in_backmargin_amt IS NULL ) OR ( in_backmargin_amt <= cn_number_0 ) ) )
      THEN
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
        ln_coverage_amt := cn_number_0;
      ELSE
        ln_coverage_amt := ( ln_market_amt - NVL( gn_normal_store_deliver_amt, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
      END IF;
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
      -- ===============================================
      -- �≮�}�[�W��
      -- T1_0414�C���O ((����X�[-NET���i)*�x������  ����X�[��NULL�E0�ȊO�̏ꍇ����X�[�ANULL�܂���0�̏ꍇ�ʏ�X�[
      -- T1_0414�C���� A-3.�̔��萔����0���傫���ꍇ A-3.�̔��萔�� �~ �x������ �| ��U
      --               ��L�ȊO                        A-3.�̔��萔�� �~ �x������
      -- ===============================================
--      IF (    gn_once_store_deliver_amt IS NOT NULL )
--        AND ( gn_once_store_deliver_amt <> cn_number_0 )
--      THEN
--        ln_wholesale_margin_sum := ( gn_once_store_deliver_amt - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
--      ELSE
--        ln_wholesale_margin_sum := ( NVL( gn_normal_store_deliver_amt, 0 ) - NVL( gn_net_selling_price, 0 ) ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
--      END IF;
      IF ( in_backmargin_amt > cn_number_0 ) THEN
        ln_wholesale_margin_sum := NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 ) - ln_coverage_amt;
      ELSE
        ln_wholesale_margin_sum := NVL( in_backmargin_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
      END IF;
      -- ===============================================
      -- �g����
      -- T1_0414�C���O ((�ʏ�X�[-����X�[)*�x������)  ����X�[��NULL�܂���0�̏ꍇ�A�g�����0
      -- T1_0414�C���� A-3.�̔����^�� �~ �x������
      -- ===============================================
--      IF (   gn_once_store_deliver_amt IS NULL )
--        OR ( gn_once_store_deliver_amt = cn_number_0 )
--      THEN
--        ln_expansion_sales_amt := cn_number_0;
--      ELSE
--        ln_expansion_sales_amt := ( gn_normal_store_deliver_amt - gn_once_store_deliver_amt ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
--      END IF;
      ln_expansion_sales_amt := NVL( in_sales_support_amt, cn_number_0 ) * NVL( g_target_tab( in_i ).payment_qty, 0 );
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
      -- ===============================================
      -- ���̑��Ȗ�(�x�����z) ����Ȗڂɒl������ꍇ�̂�
      -- ===============================================
      IF ( g_target_tab( in_i ).acct_code IS NOT NULL ) THEN
        ln_misc_acct_amt := NVL( g_target_tab( in_i ).payment_amt, 0 );
      END IF;
      -- ===============================================
      -- ����Ώ۔N��(YYYY/MM)�f�[�^�ϊ�
      -- ===============================================
      lv_selling_month := TO_CHAR( TO_DATE( g_target_tab( in_i ).selling_month, cv_format_yyyymm ), cv_format_yyyy_mm );
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�o�^
      -- ===============================================
      INSERT INTO xxcok_rep_wholesale_pay(
        wholesale_bill_detail_id                       -- �≮����������ID
      , p_base_code                                    -- ���_�R�[�h(���̓p�����[�^)
      , p_wholesale_code_admin                         -- �≮�Ǘ��R�[�h(���̓p�����[�^)
      , p_cust_code                                    -- �ڋq�R�[�h(���̓p�����[�^)
      , p_sales_outlets_code                           -- �≮������R�[�h(���̓p�����[�^)
      , p_payment_date                                 -- �x���N����(���̓p�����[�^)
      , p_selling_month                                -- ����Ώ۔N��(���̓p�����[�^)
      , payment_date                                   -- �x���N����
      , selling_month                                  -- ����N��
      , bill_no                                        -- ������No.
      , cust_code                                      -- �ڋq�R�[�h
      , cust_name                                      -- �ڋq��
      , sales_outlets_code                             -- �≮������R�[�h
      , sales_outlets_name                             -- �≮�����於
      , wholesale_code_admin                           -- �≮�Ǘ��R�[�h
      , wholesale_name_admin                           -- �≮�Ǘ���
      , supplier_code                                  -- �d����R�[�h
      , supplier_name                                  -- �d���於
      , bank_name                                      -- ��s��
      , bank_branch_name                               -- �x�X��
      , bank_acct_type                                 -- �������
      , bank_acct_no                                   -- �����ԍ�
      , item_code                                      -- �i���R�[�h
      , item_name                                      -- �i��
      , unit_type                                      -- �P��
      , demand_qty                                     -- ��������
      , demand_unit_price                              -- �����P��
      , demand_amt                                     -- �������z
      , payment_qty                                    -- �x������
      , payment_unit_price                             -- �x���P��
      , payment_amt_disp                               -- �x�����z(�\���p)
      , payment_amt_calc                               -- �x�����z(�v�Z�p)
      , normal_special_type                            -- �ʓ��敪
      , market_amt                                     -- (��)���l
      , normal_store_deliver_amt                       -- �ʏ�X�[
      , once_store_deliver_amt                         -- ����X�[
      , net_selling_price                              -- NET���i
      , net_pct                                        -- NET�|��
      , margin_pct                                     -- �}�[�W����
      , cs_margin_amt                                  -- C/S�}�[�W���z
      , coverage_amt                                   -- ��U
      , wholesale_margin_sum                           -- �≮�}�[�W��
      , expansion_sales_amt                            -- �g����
      , misc_acct_amt                                  -- ���̑��Ȗ�
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
        g_target_tab( in_i ).wholesale_bill_detail_id  -- wholesale_bill_detail_id
      , iv_base_code                                   -- p_base_code
      , iv_wholesale_code_admin                        -- p_wholesale_code_admin
      , iv_cust_code                                   -- p_cust_code
      , iv_sales_outlets_code                          -- p_sales_outlets_code
      , iv_payment_date                                -- p_payment_date
      , iv_selling_month                               -- p_selling_month
      , iv_payment_date                                -- payment_date
      , lv_selling_month                               -- selling_month
      , g_target_tab( in_i ).bill_no                   -- bill_no
      , g_target_tab( in_i ).cust_code                 -- cust_code
      , g_target_tab( in_i ).cust_name                 -- cust_name
      , g_target_tab( in_i ).sales_outlets_code        -- sales_outlets_code
      , g_target_tab( in_i ).sales_outlets_name        -- sales_outlets_name
      , g_target_tab( in_i ).wholesale_ctrl_code       -- wholesale_code_admin
      , g_target_tab( in_i ).wholesale_ctrl_name       -- wholesale_name_admin
      , g_target_tab( in_i ).supplier_code             -- supplier_code
      , g_target_tab( in_i ).vendor_name               -- supplier_name
      , g_target_tab( in_i ).bank_name                 -- bank_name
      , g_target_tab( in_i ).bank_branch_name          -- bank_branch_name
      , g_target_tab( in_i ).bank_account_type         -- bank_acct_type
      , g_target_tab( in_i ).bank_account_num          -- bank_acct_no
      , g_target_tab( in_i ).item_code                 -- item_code
      , g_target_tab( in_i ).item_short_name           -- item_name
      , g_target_tab( in_i ).demand_unit_type          -- unit_type
      , g_target_tab( in_i ).demand_qty                -- demand_qty
      , g_target_tab( in_i ).demand_unit_price         -- demand_unit_price
      , g_target_tab( in_i ).demand_amt                -- demand_amt
      , ln_payment_qty                                 -- payment_qty
      , ln_payment_unit_price                          -- payment_unit_price
      , ln_payment_amt                                 -- payment_amt_disp
      , g_target_tab( in_i ).payment_amt               -- payment_amt_calc
      , gv_estimated_type                              -- normal_special_type
      , ln_market_amt                                  -- market_amt
      , gn_normal_store_deliver_amt                    -- normal_store_deliver_amt
      , gn_once_store_deliver_amt                      -- once_store_deliver_amt
      , gn_net_selling_price                           -- net_selling_price
      , ln_net_pct                                     -- net_pct
      , ln_margin_pct                                  -- margin_pct
      , ln_cs_margin_amt                               -- cs_margin_amt
      , ln_coverage_amt                                -- coverage_amt
      , ln_wholesale_margin_sum                        -- wholesale_margin_sum
      , ln_expansion_sales_amt                         -- expansion_sales_amt
      , ln_misc_acct_amt                               -- misc_acct_amt
      , NULL                                           -- no_data_message
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
    ELSE
      -- ===============================================
      -- �Ώی���0�������[�N�e�[�u���f�[�^�o�^
      -- ===============================================
      INSERT INTO xxcok_rep_wholesale_pay(
        p_base_code                -- ���_�R�[�h(���̓p�����[�^)
      , p_wholesale_code_admin     -- �≮�Ǘ��R�[�h(���̓p�����[�^)
      , p_cust_code                -- �ڋq�R�[�h(���̓p�����[�^)
      , p_sales_outlets_code       -- �≮������R�[�h(���̓p�����[�^)
      , p_payment_date             -- �x���N����(���̓p�����[�^)
      , p_selling_month            -- ����Ώ۔N��(���̓p�����[�^)
      , no_data_message            -- 0�����b�Z�[�W
      , created_by                 -- �쐬��
      , creation_date              -- �쐬��
      , last_updated_by            -- �ŏI�X�V��
      , last_update_date           -- �ŏI�X�V��
      , last_update_login          -- �ŏI�X�V���O�C��
      , request_id                 -- �v��ID
      , program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                 -- �R���J�����g�E�v���O����ID
      , program_update_date        -- �v���O�����X�V��
      ) VALUES (
        iv_base_code               -- p_base_code
      , iv_wholesale_code_admin    -- p_wholesale_code_admin
      , iv_cust_code               -- p_cust_code
      , iv_sales_outlets_code      -- p_sales_outlets_code
      , iv_payment_date            -- p_payment_date
      , iv_selling_month           -- p_selling_month
      , gv_no_data_msg             -- no_data_message
      , cn_created_by              -- created_by
      , SYSDATE                    -- creation_date
      , cn_last_updated_by         -- last_updated_by
      , SYSDATE                    -- last_update_date
      , cn_last_update_login       -- last_update_login
      , cn_request_id              -- request_id
      , cn_program_application_id  -- program_application_id
      , cn_program_id              -- program_id
      , SYSDATE                    -- program_update_date
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
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_month         IN  VARCHAR2  -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN  VARCHAR2  -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN  VARCHAR2  -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN  VARCHAR2  -- �≮������R�[�h
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
    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lv_selling_month  VARCHAR2(6)     DEFAULT NULL;              -- ����Ώ۔N��(YYYYMM)
    lv_dummy          VARCHAR2(20)    DEFAULT NULL;              -- �֐����g�p����
    ln_dummy          NUMBER          DEFAULT NULL;              -- �֐����g�p����
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
    ln_backmargin_amt    NUMBER       DEFAULT NULL;              -- �̔��萔��
    ln_sales_support_amt NUMBER       DEFAULT NULL;              -- �̔����^��
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ����Ώ۔N���`���ϊ�
    -- ===============================================
    IF ( iv_selling_month IS NOT NULL ) THEN
      lv_selling_month := TO_CHAR( TO_DATE( iv_selling_month, cv_format_yyyy_mm ), cv_format_yyyymm );
    END IF;
    -- ===============================================
    -- �J�[�\��
    -- ===============================================
    OPEN  g_target_cur(
      iv_base_code             -- ���_�R�[�h
    , iv_payment_date          -- �x���N����
    , lv_selling_month         -- ����Ώ۔N��
    , iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
    , iv_cust_code             -- �ڋq�R�[�h
    , iv_sales_outlets_code    -- �≮������R�[�h
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
        , iv_base_code             =>  iv_base_code             -- ���_�R�[�h
        , iv_payment_date          =>  iv_payment_date          -- �x���N����
        , iv_selling_month         =>  iv_selling_month         -- ����Ώ۔N��
        , iv_wholesale_code_admin  =>  iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
        , iv_cust_code             =>  iv_cust_code             -- �ڋq�R�[�h
        , iv_sales_outlets_code    =>  iv_sales_outlets_code    -- �≮������R�[�h
        , in_i                     =>  cn_number_0              -- LOOP�J�E���^
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<main_loop>>
      FOR i IN g_target_tab.FIRST .. g_target_tab.LAST LOOP
        -- ===============================================
        -- ���Ϗ����擾(A-3)
        -- ===============================================
        xxcok_common_pkg.get_wholesale_req_est_p(
          ov_errbuf                    => lv_errbuf                              -- �G���[�o�b�t�@
        , ov_retcode                   => lv_retcode                             -- ���^�[���R�[�h
        , ov_errmsg                    => lv_errmsg                              -- �G���[���b�Z�[�W
        , iv_wholesale_code            => g_target_tab( i ).wholesale_ctrl_code  -- �≮�Ǘ��R�[�h
        , iv_sales_outlets_code        => g_target_tab( i ).sales_outlets_code   -- �≮������R�[�h
        , iv_item_code                 => g_target_tab( i ).item_code            -- �i�ڃR�[�h
        , in_demand_unit_price         => g_target_tab( i ).payment_unit_price   -- �x���P��
        , iv_demand_unit_type          => g_target_tab( i ).demand_unit_type     -- �����P��
        , iv_selling_month             => g_target_tab( i ).selling_month        -- ����Ώ۔N��
        , ov_estimated_no              => lv_dummy                               -- ���Ϗ�No.(���g�p)
        , on_quote_line_id             => ln_dummy                               -- ����ID(���g�p)
        , ov_emp_code                  => lv_dummy                               -- �S���҃R�[�h(���g�p)
        , on_market_amt                => gn_market_amt                          -- ���l
        , on_allowance_amt             => gn_allowance_amt                       -- �l��(���߂�)
        , on_normal_store_deliver_amt  => gn_normal_store_deliver_amt            -- �ʏ�X�[
        , on_once_store_deliver_amt    => gn_once_store_deliver_amt              -- ����X�[
        , on_net_selling_price         => gn_net_selling_price                   -- NET���i
        , ov_estimated_type            => gv_estimated_type                      -- ���ϋ敪
-- Start 2009/04/16 Ver_ T1_ M.Hiruta
--        , on_backmargin_amt            => ln_dummy                               -- �̔��萔��(���g�p)
--        , on_sales_support_amt         => ln_dummy                               -- �̔����^��(���g�p)
        , on_backmargin_amt            => ln_backmargin_amt                      -- �̔��萔��
        , on_sales_support_amt         => ln_sales_support_amt                   -- �̔����^��
-- End   2009/04/16 Ver_ T1_ M.Hiruta
        );
        IF ( lv_retcode = cv_status_error ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10047
                        , iv_token_name1  => cv_token_ctrl_code                     -- CONTROL_CODE(�≮�Ǘ��R�[�h)
                        , iv_token_value1 => g_target_tab( i ).wholesale_ctrl_code
                        , iv_token_name2  => cv_token_balance_code                  -- BALANCE_CODE(�≮������R�[�h)
                        , iv_token_value2 => g_target_tab( i ).sales_outlets_code
                        , iv_token_name3  => cv_token_item_code                     -- ITEM_CODE(�i�ڃR�[�h)
                        , iv_token_value3 => g_target_tab( i ).item_code
                        , iv_token_name4  => cv_token_demand_price                  -- DEMAND_PRICE(�����P��)
                        , iv_token_value4 => g_target_tab( i ).demand_unit_price
                        , iv_token_name5  => cv_token_demand_unit                   -- DEMAND_UNIT(�����P��)
                        , iv_token_value5 => g_target_tab( i ).demand_unit_type
                        , iv_token_name6  => cv_token_target_period                 -- TARGET_PERIOD(����Ώ۔N��)
                        , iv_token_value6 => g_target_tab( i ).selling_month
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_outmsg
                        , in_new_line => cn_number_0
                        );
          RAISE global_api_expt;
        END IF;
        -- ===============================================
        -- ���[�N�e�[�u���f�[�^�o�^(A-4)
        -- ===============================================
        ins_wholesale_pay(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
        , iv_base_code             =>  iv_base_code             -- ���_�R�[�h
        , iv_payment_date          =>  iv_payment_date          -- �x���N����
        , iv_selling_month         =>  iv_selling_month         -- ����Ώ۔N��
        , iv_wholesale_code_admin  =>  iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
        , iv_cust_code             =>  iv_cust_code             -- �ڋq�R�[�h
        , iv_sales_outlets_code    =>  iv_sales_outlets_code    -- �≮������R�[�h
        , in_i                     =>  i                        -- LOOP�J�E���^
-- Start 2009/04/16 Ver_1.4 T1_0414 M.Hiruta
        , in_backmargin_amt        =>  ln_backmargin_amt        -- �̔��萔��
        , in_sales_support_amt     =>  ln_sales_support_amt     -- �̔����^��
-- End   2009/04/16 Ver_1.4 T1_0414 M.Hiruta
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
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_month         IN  VARCHAR2  -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN  VARCHAR2  -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN  VARCHAR2  -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN  VARCHAR2  -- �≮������R�[�h
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
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt             EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �v���O�������͍��ڂ��o��
    -- ===============================================
    -- ���_�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00018
                  , iv_token_name1  => cv_token_location_code
                  , iv_token_value1 => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �x���N����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00071
                  , iv_token_name1  => cv_token_pay_date
                  , iv_token_value1 => iv_payment_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- ����Ώ۔N��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00072
                  , iv_token_name1  => cv_token_target_period
                  , iv_token_value1 => iv_selling_month
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �≮�Ǘ��R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00068
                  , iv_token_name1  => cv_token_ctrl_code
                  , iv_token_value1 => iv_wholesale_code_admin
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �ڋq�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00069
                  , iv_token_name1  => cv_token_cust_code
                  , iv_token_value1 => iv_cust_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_0
                  );
    -- �≮������R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_short_name
                  , iv_name         => cv_msg_code_00070
                  , iv_token_name1  => cv_token_balance_code
                  , iv_token_value1 => iv_sales_outlets_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                  , iv_message  => lv_outmsg
                  , in_new_line => cn_number_1
                  );
    -- ===============================================
    -- �x���N�����^�`�F�b�N
    -- ===============================================
    BEGIN
      ld_chk_date := TO_DATE( iv_payment_date, cv_format_fxyyyy_mm_dd );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10044
                      , iv_token_name1  => cv_token_pay_date
                      , iv_token_value1 => iv_payment_date
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END;
    -- ===============================================
    -- ����Ώ۔N���^�`�F�b�N(NULL�̏ꍇ�A�ΏۊO)
    -- ===============================================
    IF ( iv_selling_month IS NOT NULL ) THEN
      BEGIN
        ld_chk_date := TO_DATE( iv_selling_month, cv_format_fxyyyy_mm );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10045
                        , iv_token_name1  => cv_token_target_period
                        , iv_token_value1 => iv_selling_month
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE init_fail_expt;
      END;
    END IF;
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
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
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
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_month         IN  VARCHAR2  -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN  VARCHAR2  -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN  VARCHAR2  -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN  VARCHAR2  -- �≮������R�[�h
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
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_month         => iv_selling_month         -- ����Ώ۔N��
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
    , iv_cust_code             => iv_cust_code             -- �ڋq�R�[�h
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- �≮������R�[�h
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �Ώۃf�[�^�擾(A-2)�E���Ϗ����擾(A-3)�E���[�N�e�[�u���f�[�^�o�^(A-4)
    -- ===============================================
    get_target_data(
      ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_month         => iv_selling_month         -- ����Ώ۔N��
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
    , iv_cust_code             => iv_cust_code             -- �ڋq�R�[�h
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- �≮������R�[�h
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
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_month         IN  VARCHAR2  -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN  VARCHAR2  -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN  VARCHAR2  -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN  VARCHAR2  -- �≮������R�[�h
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
    , iv_base_code             => iv_base_code             -- ���_�R�[�h
    , iv_payment_date          => iv_payment_date          -- �x���N����
    , iv_selling_month         => iv_selling_month         -- ����Ώ۔N��
    , iv_wholesale_code_admin  => iv_wholesale_code_admin  -- �≮�Ǘ��R�[�h
    , iv_cust_code             => iv_cust_code             -- �ڋq�R�[�h
    , iv_sales_outlets_code    => iv_sales_outlets_code    -- �≮������R�[�h
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
END XXCOK021A06R;
/
