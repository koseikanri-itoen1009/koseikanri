CREATE OR REPLACE PACKAGE BODY XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(body)
 * Description      : �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 * MD.050           : �����ʔ̎�̋��v�Z���� MD050_COK_014_A01
 * Version          : 2.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  update_xsel          �̔����јA�g���ʂ̍X�V                       (A-12)
 *  insert_xbce          �̎�����G���[�e�[�u���ւ̓o�^               (A-11)
 *  insert_xcbs          �����ʔ̎�̋��e�[�u���ւ̓o�^               (A-10)
 *  set_xcbs_data        �����ʔ̎�̋����̐ݒ�                     (A-9)
 *  sales_result_loop1   �̔����т̎擾�E�����ʏ���                   (A-8)
 *  sales_result_loop2   �̔����т̎擾�E�e��敪�ʏ���               (A-8)
 *  sales_result_loop3   �̔����т̎擾�E�ꗥ����                     (A-8)
 *  sales_result_loop4   �̔����т̎擾�E��z����                     (A-8)
 *  sales_result_loop5   �̔����т̎擾�E�d�C���i�Œ�^�ϓ��j         (A-8)
 *  sales_result_loop6   �̔����т̎擾�E�����l����                   (A-8)
 *  delete_xbce          �̎�����G���[�̍폜����                     (A-7)
 *  delete_xcbs          �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j     (A-3)
 *  insert_xt0c          �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^     (A-6)
 *  get_cust_subdata     �����ʔ̎�̋��v�Z���t���̓��o             (A-5)
 *  cust_loop            �ڋq��񃋁[�v                               (A-4)
 *  purge_xcbs           �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j     (A-2)
 *  init                 ��������                                     (A-1)
 *  submain              ���C�������v���V�[�W��
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          �V�K�쐬
 *  2009/02/13    1.1   K.Ezaki          ��QCOK_039 �x���������ݒ�ڋq�X�L�b�v
 *  2009/02/17    1.2   K.Ezaki          ��QCOK_040 �t���x���_�[�T�C�g�Œ�C��
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_060 �ꗥ�����v�Z���ʗݐ�
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_061 �ꗥ������z�v�Z
 *  2009/02/25    1.3   K.Ezaki          ��QCOK_062 ��z�������ߗ��E���ߊz���ݒ�
 *  2009/03/13    1.4   T.Taniguchi      ��QT1_0036 �̔����я��J�[�\����`�̏����ǉ�
 *  2009/03/25    1.5   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/04/14    1.6   K.Yamaguchi      [��QT1_0523] �̔����т̔�����z�i�ō��j�擾���@�s���Ή�
 *  2009/04/20    1.7   K.Yamaguchi      [��QT1_0688] �̎�����}�X�^�̗L�����𔻒肵�Ȃ��悤�ɏC��
 *  2009/05/20    1.8   K.Yamaguchi      [��QT1_0686] ���b�Z�[�W�C��
 *  2009/06/01    2.0   K.Yamaguchi      [��QT1_0620][��QT1_0823][��QT1_1124][��QT1_1303]
 *                                       [��QT1_1400][��QT1_1402][��QT1_1422]
 *                                       �C������ɂ��č쐬
 *  2009/06/26    2.1   M.Hiruta         [��Q0000269] �p�t�H�[�}���X�����コ���邽��SQL���C��
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK014A01C';
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
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00022                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00022';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00044                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00044';
  cv_msg_cok_00051                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00051';
  cv_msg_cok_00080                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00080';
  cv_msg_cok_00081                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00081';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00086';
  cv_msg_cok_10398                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10398';
  cv_msg_cok_10401                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10401';
  cv_msg_cok_10402                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10402';
  cv_msg_cok_10404                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10404';
  cv_msg_cok_10405                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10405';
  cv_msg_cok_10426                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10426';
  cv_msg_cok_10427                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10427';
  cv_msg_cok_10454                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10454';
  cv_msg_cok_10455                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10455';
  cv_msg_cok_10456                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10456';
  -- �g�[�N��
  cv_tkn_close_date                CONSTANT VARCHAR2(30)    := 'CLOSE_DATE';
  cv_tkn_container_type            CONSTANT VARCHAR2(30)    := 'CONTAINER_TYPE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';
  cv_tkn_dept_code                 CONSTANT VARCHAR2(30)    := 'DEPT_CODE';
  cv_tkn_pay_date                  CONSTANT VARCHAR2(30)    := 'PAY_DATE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_proc_type                 CONSTANT VARCHAR2(30)    := 'PROC_TYPE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_sales_amt                 CONSTANT VARCHAR2(30)    := 'SALES_AMT';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  cv_tkn_business_date             CONSTANT VARCHAR2(30)    := 'BUSINESS_DATE';
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'ORG_ID';                            -- MO: �c�ƒP��
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- ��v����ID
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';     -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';       -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_SALES_RETENTION_PERIOD';     -- XXCOK:�̎�̋����ێ�����
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';      -- �d�C���i�ϓ��j�i�ڃR�[�h
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_VENDOR_DUMMY_CODE';          -- �d����_�~�[�R�[�h
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_INSTANTLY_TERM_NAME';        -- �x������_��������
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'XXCOK1_DEFAULT_TERM_NAME';          -- �x������_�f�t�H���g
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_DISTRICT_PARA_MST';       -- �̎�̋��v�Z���s�敪
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_CONSUMPTION_TAX_CLASS';      -- ����ŋ敪
  cv_lookup_type_03                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_SHO';             -- �Ƒԁi�����ށj
  cv_lookup_type_04                CONSTANT VARCHAR2(30)    := 'XXCMM_ITM_YOKIGUN';                 -- �e��Q
  cv_lookup_type_05                CONSTANT VARCHAR2(30)    := 'XXCOS1_NO_INV_ITEM_CODE';           -- ��݌ɕi��
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
  cv_lookup_type_06                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_CHU';             -- �Ƒԁi�����ށj
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
  -- �L���t���O
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRR/MM/DD';
  -- �����ʔ̎�̋��e�[�u���A�g�X�e�[�^�X
  cv_xcbs_if_status_no             CONSTANT VARCHAR2(1)     := '0'; -- ������
  cv_xcbs_if_status_yes            CONSTANT VARCHAR2(1)     := '1'; -- ������
  cv_xcbs_if_status_off            CONSTANT VARCHAR2(1)     := '2'; -- �s�v
  -- �ڋq�g�p�ړI
  cv_site_use_code_ship            CONSTANT VARCHAR2(10)    := 'SHIP_TO'; -- �o�א�
  cv_site_use_code_bill            CONSTANT VARCHAR2(10)    := 'BILL_TO'; -- ������
  -- �x����
  cv_month_type1                   CONSTANT VARCHAR2(2)     := '40'; -- ����
  cv_month_type2                   CONSTANT VARCHAR2(2)     := '50'; -- ����
  -- �T�C�g
  cv_site_type1                    CONSTANT VARCHAR2(2)     := '00'; -- ����
  cv_site_type2                    CONSTANT VARCHAR2(2)     := '01'; -- ����
  -- �_��Ǘ��X�e�[�^�X
  cv_xcm_status_result             CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �����ʔ̎�̋��e�[�u�����z�m��X�e�[�^�X
  cv_xcbs_temp                     CONSTANT VARCHAR2(1)     := '0'; -- ���m��
  cv_xcbs_fix                      CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �萔���v�Z�C���^�[�t�F�[�X�σt���O
  cv_xsel_if_flag_yes              CONSTANT VARCHAR2(1)     := 'Y'; -- ������
  cv_xsel_if_flag_no               CONSTANT VARCHAR2(1)     := 'N'; -- ������
  -- �ڋq�敪
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- �ڋq
  -- �Ƒԁi�����ށj
  cv_gyotai_sho_24                 CONSTANT VARCHAR2(2)     := '24'; -- �t���T�[�r�XVD�i�����j
  cv_gyotai_sho_25                 CONSTANT VARCHAR2(2)     := '25'; -- �t���T�[�r�XVD
  -- �Ƒԁi�����ށj
  cv_gyotai_tyu_vd                 CONSTANT VARCHAR2(2)     := '11'; -- VD
  -- �c�Ɠ��擾�֐��E�����敪
  cn_proc_type_before              CONSTANT NUMBER          := 1;  -- �O
  cn_proc_type_after               CONSTANT NUMBER          := 2;  -- ��
  -- �e��敪�R�[�h
  cv_container_code_others         CONSTANT VARCHAR2(4)     := '9999';   -- ���̑�
  -- �v�Z����
  cv_calc_type_sales_price         CONSTANT VARCHAR2(2)     := '10';  -- �����ʏ���
  cv_calc_type_container           CONSTANT VARCHAR2(2)     := '20';  -- �e��敪�ʏ���
  cv_calc_type_uniform_rate        CONSTANT VARCHAR2(2)     := '30';  -- �ꗥ����
  cv_calc_type_flat_rate           CONSTANT VARCHAR2(2)     := '40';  -- ��z
  cv_calc_type_electricity_cost    CONSTANT VARCHAR2(2)     := '50';  -- �d�C���i�Œ�^�ϓ��j
  -- �[�������敪
  cv_tax_rounding_rule_nearest     CONSTANT VARCHAR2(10)    :=  'NEAREST'; -- �l�̌ܓ�
  cv_tax_rounding_rule_up          CONSTANT VARCHAR2(10)    :=  'UP';      -- �؂�グ
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- �؂�̂�
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- �X�L�b�v����
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- �̎�����G���[����
  -- ���̓p�����[�^
  gv_param_proc_date               VARCHAR2(10)  DEFAULT NULL;   -- �Ɩ����t
  gv_param_proc_type               VARCHAR2(10)  DEFAULT NULL;   -- �����敪
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_org_id                        NUMBER        DEFAULT NULL;   -- �c�ƒP��ID
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- ��v����ID
  gn_bm_support_period_from        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  gn_bm_support_period_to          NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  gn_sales_retention_period        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋����ێ�����
  gv_elec_change_item_code         VARCHAR2(7)   DEFAULT NULL;   -- �d�C���i�ϓ��j�i�ڃR�[�h
  gv_vendor_dummy_code             VARCHAR2(9)   DEFAULT NULL;   -- �d����_�~�[�R�[�h
  gv_instantly_term_name           VARCHAR2(8)   DEFAULT NULL;   -- �x������_��������
  gv_default_term_name             VARCHAR2(8)   DEFAULT NULL;   -- �x������_�f�t�H���g
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
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  -- �ڋq���
  CURSOR get_cust_data_cur IS
    SELECT ship_hca.account_number               AS ship_cust_code             -- �y�o�א�z�ڋq�R�[�h
         , ship_flv1.attribute1                  AS ship_gyotai_tyu            -- �y�o�א�z�Ƒԁi�����ށj
         , ship_xca.business_low_type            AS ship_gyotai_sho            -- �y�o�א�z�Ƒԁi�����ށj
         , ship_xca.delivery_chain_code          AS ship_delivery_chain_code   -- �y�o�א�z�[�i��`�F�[���R�[�h
         , bill_hca.account_number               AS bill_cust_code             -- �y������z�ڋq�R�[�h
         , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--             WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
               ship_xcm.term_name
             ELSE
               bill_rtt1.name
           END                                   AS term_name1                 -- �x������
         , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--             WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
               NULL
             ELSE
               bill_rtt2.name
           END                                   AS term_name2                 -- ��2�x������
         , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--             WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
               NULL
             ELSE
               bill_rtt3.name
           END                                   AS term_name3                 -- ��3�x������
         , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--             WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
               gn_bm_support_period_to
             ELSE
               TO_NUMBER( bill_hcsua.attribute8 )
           END                                   AS settle_amount_cycle        -- ���z�m��T�C�N��
         , bill_xca.tax_div                      AS tax_div                    -- ����ŋ敪
         , bill_avtab.tax_code                   AS tax_code                   -- �ŋ��R�[�h
         , bill_avtab.tax_rate                   AS tax_rate                   -- �ŗ�
         , bill_hcsua.tax_rounding_rule          AS tax_rounding_rule          -- �[�������敪
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , CASE
--             WHEN (     ( ship_flv1.attribute1          <> cv_gyotai_tyu_vd )
--                    AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
--                  )
--             THEN
--               gv_vendor_dummy_code
--             ELSE
--               ship_xca.contractor_supplier_code
--           END                                   AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.contractor_supplier_code
             WHEN (     ( ship_flv1.attribute1          <> cv_gyotai_tyu_vd )
                    AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
                  )
             THEN
               gv_vendor_dummy_code
             ELSE
               NULL
           END                                   AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , bm1_pvsa.vendor_site_code             AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm1_pvsa.vendor_site_code
             ELSE
               NULL
           END                                   AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , bm1_pvsa.attribute4                   AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm1_pvsa.attribute4
             ELSE
               NULL
           END                                   AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , ship_xca.bm_pay_supplier_code1        AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.bm_pay_supplier_code1
             ELSE
               NULL
           END                                   AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , bm2_pvsa.vendor_site_code             AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm2_pvsa.vendor_site_code
             ELSE
               NULL
           END                                   AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm2_pvsa.attribute4
             ELSE
               NULL
           END                                   AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , ship_xca.bm_pay_supplier_code2        AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.bm_pay_supplier_code2
             ELSE
               NULL
           END                                   AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , bm3_pvsa.vendor_site_code             AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm3_pvsa.vendor_site_code
             ELSE
               NULL
           END                                   AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--         , bm3_pvsa.attribute4                   AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm3_pvsa.attribute4
             ELSE
               NULL
           END                                   AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
         , ship_xca.receiv_discount_rate         AS receiv_discount_rate       -- �����l����
         , NVL2( MAX( ship_xcbs.calc_target_period_to )
               , MAX( ship_xcbs.calc_target_period_to ) + 1
               , MIN( xseh.delivery_date )
           )                                     AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
    FROM xxcos_sales_exp_headers       xseh                -- �̔����уw�b�_
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--       , xxcos_sales_exp_lines         xsel                -- �̔����і���
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
       , hz_cust_accounts              ship_hca            -- �y�o�א�z�ڋq�}�X�^
       , xxcmm_cust_accounts           ship_xca            -- �y�o�א�z�ڋq�ǉ����
       , hz_parties                    ship_hp             -- �y�o�א�z�ڋq�p�[�e�B
       , hz_party_sites                ship_hps            -- �y�o�א�z�ڋq�p�[�e�B�T�C�g
       , hz_locations                  ship_hl             -- �y�o�א�z�ڋq���Ə�
       , hz_cust_acct_sites_all        ship_hcasa          -- �y�o�א�z�ڋq���ݒn
       , hz_cust_site_uses_all         ship_hcsua          -- �y�o�א�z�ڋq�g�p�ړI
       , hz_cust_accounts              bill_hca            -- �y������z�ڋq�}�X�^
       , xxcmm_cust_accounts           bill_xca            -- �y������z�ڋq�ǉ����
       , hz_parties                    bill_hp             -- �y������z�ڋq�p�[�e�B
       , hz_party_sites                bill_hps            -- �y������z�ڋq�p�[�e�B�T�C�g
       , hz_cust_acct_sites_all        bill_hcasa          -- �y������z�ڋq���ݒn
       , hz_cust_site_uses_all         bill_hcsua          -- �y������z�ڋq�g�p�ړI
       , po_vendors                    bm1_pv              -- �y�a�l�P�z�d����}�X�^
       , po_vendor_sites_all           bm1_pvsa            -- �y�a�l�P�z�d����T�C�g�}�X�^
       , po_vendors                    bm2_pv              -- �y�a�l�Q�z�d����}�X�^
       , po_vendor_sites_all           bm2_pvsa            -- �y�a�l�Q�z�d����T�C�g�}�X�^
       , po_vendors                    bm3_pv              -- �y�a�l�R�z�d����}�X�^
       , po_vendor_sites_all           bm3_pvsa            -- �y�a�l�R�z�d����T�C�g�}�X�^
       , xxcok_cond_bm_support         ship_xcbs           -- �����ʔ̎�̋�
       , ra_terms_tl                   bill_rtt1           -- �x�������}�X�^
       , ra_terms_tl                   bill_rtt2           -- ��2�x�������}�X�^
       , ra_terms_tl                   bill_rtt3           -- ��3�x�������}�X�^
       , fnd_lookup_values             bill_flv1           -- ����ŋ敪
       , ar_vat_tax_all_b              bill_avtab          -- �ŋ��}�X�^
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--       , fnd_lookup_values             ship_flv1           -- �Ƒԁi�����ށj
       , ( SELECT flv_sho.lookup_code AS lookup_code -- �Ƒԁi�����ށj
                , flv_sho.attribute1  AS attribute1  -- �Ƒԁi�����ށj
           FROM fnd_lookup_values    flv_chu    -- �Ƒԁi�����ށj
              , fnd_lookup_values    flv_sho    -- �Ƒԁi�����ށj
           WHERE flv_chu.lookup_type = cv_lookup_type_06   -- �Ƒԁi�����ށj
             AND flv_sho.lookup_type = cv_lookup_type_03   -- �Ƒԁi�����ށj
             AND gd_process_date BETWEEN NVL( flv_chu.start_date_active, gd_process_date )
                                     AND NVL( flv_chu.end_date_active,   gd_process_date )
             AND flv_chu.language            = USERENV( 'LANG' )
             AND (    ( flv_sho.lookup_code IN( cv_gyotai_sho_24, cv_gyotai_sho_25 )  )
                   OR ( flv_chu.lookup_code <>  cv_gyotai_tyu_vd                      )
                 )
             AND flv_chu.enabled_flag        = cv_enable
             AND flv_sho.enabled_flag        = cv_enable
             AND gd_process_date BETWEEN NVL( flv_sho.start_date_active, gd_process_date )
                                     AND NVL( flv_sho.end_date_active,   gd_process_date )
             AND flv_sho.language            = USERENV( 'LANG' )
             AND flv_sho.attribute1          = flv_chu.lookup_code
         )                             ship_flv1           -- �Ƒԁi�����ށj
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
       , fnd_lookup_values             ship_flv2           -- ���s�敪
       , ( SELECT xcm.install_account_id  AS install_account_id -- �ݒu��ڋqID
                , CASE
                    WHEN (    ( xcm.close_day_code      IS NULL )
                           OR ( xcm.transfer_day_code   IS NULL )
                           OR ( xcm.transfer_month_code IS NULL )
                         )
                    THEN
                      gv_default_term_name
                    ELSE
                         xcm.close_day_code
                      || '_'
                      || xcm.transfer_day_code
                      || '_'
                      || CASE
                           WHEN xcm.transfer_month_code = cv_month_type1 THEN
                             cv_site_type1
                           ELSE
                             cv_site_type2
                         END
                  END                     AS term_name          -- �x������
           FROM xxcso_contract_managements  xcm -- �_��Ǘ�
           WHERE xcm.status =  cv_xcm_status_result
             AND EXISTS ( SELECT    'X'
                          FROM xxcso_contract_managements  xcm2  -- �_��Ǘ�
                          WHERE xcm2.status                    =  '1'                -- �X�e�[�^�X�F�m���
                            AND xcm2.install_account_id        = xcm.install_account_id
                          GROUP BY  xcm2.install_account_id
                          HAVING MAX( xcm2.contract_number )   = xcm.contract_number
                 )
          )                            ship_xcm            -- �_��Ǘ����
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--    WHERE xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
--      AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
    WHERE EXISTS ( SELECT 'X'
                   FROM xxcos_sales_exp_lines xsel  -- �̔����і���
                   WHERE xseh.sales_exp_header_id     = xsel.sales_exp_header_id
                     AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
                     AND ROWNUM = 1
          )
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
      AND xseh.delivery_date          <= gd_process_date - gn_bm_support_period_from
      AND ship_hca.account_number      = xseh.ship_to_customer_code
      AND ship_hca.customer_class_code = cv_customer_class_customer
      AND ship_hca.cust_account_id     = ship_xca.customer_id
      AND ship_hp.party_id             = ship_hca.party_id
      AND ship_hp.party_id             = ship_hps.party_id
      AND ship_hl.location_id          = ship_hps.location_id
      AND ship_hca.cust_account_id     = ship_hcasa.cust_account_id
      AND ship_hps.party_site_id       = ship_hcasa.party_site_id
      AND ship_hcasa.org_id            = gn_org_id
      AND ship_hcasa.cust_acct_site_id = ship_hcsua.cust_acct_site_id
      AND ship_hcsua.org_id            = gn_org_id
      AND ship_hcsua.site_use_code     = cv_site_use_code_ship
      AND bill_hcsua.site_use_id       = ship_hcsua.bill_to_site_use_id
      AND bill_hcsua.org_id            = gn_org_id
      AND bill_hcsua.site_use_code     = cv_site_use_code_bill
      AND bill_hcasa.cust_acct_site_id = bill_hcsua.cust_acct_site_id
      AND bill_hcasa.org_id            = gn_org_id
      AND bill_hps.party_site_id       = bill_hcasa.party_site_id
      AND bill_hca.cust_account_id     = bill_hcasa.cust_account_id
      AND bill_hp.party_id             = bill_hps.party_id
      AND bill_hp.party_id             = bill_hca.party_id
      AND bill_hca.cust_account_id     = bill_xca.customer_id
      AND bm1_pv.segment1(+)           = ship_xca.contractor_supplier_code
      AND bm1_pv.vendor_id             = bm1_pvsa.vendor_id(+)
      AND bm1_pvsa.org_id(+)           = gn_org_id
      AND bm2_pv.segment1(+)           = ship_xca.bm_pay_supplier_code1
      AND bm2_pv.vendor_id             = bm2_pvsa.vendor_id(+)
      AND bm2_pvsa.org_id(+)           = gn_org_id
      AND bm3_pv.segment1(+)           = ship_xca.bm_pay_supplier_code2
      AND bm3_pv.vendor_id             = bm3_pvsa.vendor_id(+)
      AND bm3_pvsa.org_id(+)           = gn_org_id
      AND ship_hca.cust_account_id     = ship_xcm.install_account_id(+)
      AND ship_hca.account_number      = ship_xcbs.delivery_cust_code(+)
      AND ship_xcbs.closing_date(+)   <= gd_process_date
      AND bill_rtt1.term_id(+)         = bill_hcsua.payment_term_id
      AND bill_rtt1.language(+)        = USERENV( 'LANG' )
      AND bill_rtt2.term_id(+)         = bill_hcsua.attribute2
      AND bill_rtt2.language(+)        = USERENV( 'LANG' )
      AND bill_rtt3.term_id(+)         = bill_hcsua.attribute3
      AND bill_rtt3.language(+)        = USERENV( 'LANG' )
      AND bill_flv1.lookup_code        = bill_xca.tax_div
      AND bill_flv1.lookup_type        = cv_lookup_type_02      -- �Q�ƃ^�C�v�F����ŋ敪
      AND bill_flv1.language           = USERENV( 'LANG' )
      AND bill_flv1.enabled_flag       = cv_enable
      AND gd_process_date        BETWEEN NVL( bill_flv1.start_date_active, gd_process_date )
                                     AND NVL( bill_flv1.end_date_active,   gd_process_date )
      AND bill_avtab.tax_code          = bill_flv1.attribute1
      AND bill_avtab.set_of_books_id   = gn_set_of_books_id
      AND bill_avtab.org_id            = gn_org_id
      AND bill_avtab.validate_flag     = cv_enable
      AND gd_process_date        BETWEEN NVL( bill_avtab.start_date, gd_process_date )
                                     AND NVL( bill_avtab.end_date,   gd_process_date )
      AND ship_flv1.lookup_code        = ship_xca.business_low_type
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--      AND ship_flv1.lookup_type        = cv_lookup_type_03      -- �Q�ƃ^�C�v�F�Ƒ�(������)
--      AND ship_flv1.language           = USERENV( 'LANG' )
--      AND ship_flv1.enabled_flag       = cv_enable
--      AND gd_process_date        BETWEEN NVL( ship_flv1.start_date_active, gd_process_date )
--                                     AND NVL( ship_flv1.end_date_active,   gd_process_date )
--      AND (    ( ship_flv1.lookup_code IN( cv_gyotai_sho_24, cv_gyotai_sho_25 )  )
--            OR ( ship_flv1.attribute1  <> cv_gyotai_tyu_vd                       )
--          )
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
      AND ship_flv2.lookup_code        = gv_param_proc_type
      AND ship_flv2.lookup_type        = cv_lookup_type_01      -- �Q�ƃ^�C�v�F�̎�̋��v�Z���s�敪
      AND ship_flv2.language           = USERENV( 'LANG' )
      AND ship_flv2.enabled_flag       = cv_enable
      AND gd_process_date        BETWEEN NVL( ship_flv2.start_date_active, gd_process_date )
                                     AND NVL( ship_flv2.end_date_active,   gd_process_date )
      AND (    ( ship_flv2.attribute1  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute1  || '%' )
            OR ( ship_flv2.attribute2  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute2  || '%' )
            OR ( ship_flv2.attribute3  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute3  || '%' )
            OR ( ship_flv2.attribute4  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute4  || '%' )
            OR ( ship_flv2.attribute5  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute5  || '%' )
            OR ( ship_flv2.attribute6  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute6  || '%' )
            OR ( ship_flv2.attribute7  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute7  || '%' )
            OR ( ship_flv2.attribute8  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute8  || '%' )
            OR ( ship_flv2.attribute9  IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute9  || '%' )
            OR ( ship_flv2.attribute10 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute10 || '%' )
            OR ( ship_flv2.attribute11 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute11 || '%' )
            OR ( ship_flv2.attribute12 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute12 || '%' )
            OR ( ship_flv2.attribute13 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute13 || '%' )
            OR ( ship_flv2.attribute14 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute14 || '%' )
            OR ( ship_flv2.attribute15 IS NOT NULL AND ship_hl.address3 LIKE ship_flv2.attribute15 || '%' )
          )
    GROUP BY ship_hca.account_number
           , ship_flv1.attribute1
           , ship_xca.business_low_type
           , ship_xca.delivery_chain_code           , bill_hca.account_number
           , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--               WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End 2009/06/26 Ver_2.1 0000269 M.Hiruta
                 ship_xcm.term_name
               ELSE
                 bill_rtt1.name
             END
           , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--               WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End 2009/06/26 Ver_2.1 0000269 M.Hiruta
                 NULL
               ELSE
                 bill_rtt2.name
             END
           , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--               WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End 2009/06/26 Ver_2.1 0000269 M.Hiruta
                 NULL
               ELSE
                 bill_rtt3.name
             END
           , CASE
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
--               WHEN bill_xca.business_low_type = cv_gyotai_sho_25 THEN
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
                 gn_bm_support_period_to
               ELSE
                 TO_NUMBER( bill_hcsua.attribute8 )
             END
           , bill_xca.tax_div
           , bill_avtab.tax_code
           , bill_avtab.tax_rate
           , bill_hcsua.tax_rounding_rule
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--           , CASE
--               WHEN (     ( ship_flv1.attribute1          <> cv_gyotai_tyu_vd )
--                      AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
--                    )
--               THEN
--                 gv_vendor_dummy_code
--               ELSE
--                 ship_xca.contractor_supplier_code
--             END
--           , bm1_pvsa.vendor_site_code
--           , bm1_pvsa.attribute4
--           , ship_xca.bm_pay_supplier_code1
--           , bm2_pvsa.vendor_site_code
--           , bm2_pvsa.attribute4
--           , ship_xca.bm_pay_supplier_code2
--           , bm3_pvsa.vendor_site_code
--           , bm3_pvsa.attribute4
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.contractor_supplier_code
             WHEN (     ( ship_flv1.attribute1          <> cv_gyotai_tyu_vd )
                    AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
                  )
             THEN
               gv_vendor_dummy_code
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm1_pvsa.vendor_site_code
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm1_pvsa.attribute4
             ELSE
               NULL
           END
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.bm_pay_supplier_code1
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm2_pvsa.vendor_site_code
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm2_pvsa.attribute4
             ELSE
               NULL
           END
         , CASE
             WHEN ship_flv1.attribute1 = cv_gyotai_tyu_vd THEN
               ship_xca.bm_pay_supplier_code2
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm3_pvsa.vendor_site_code
             ELSE
               NULL
           END
         , CASE
             WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
               bm3_pvsa.attribute4
             ELSE
               NULL
           END
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
           , ship_xca.receiv_discount_rate
    ORDER BY bill_hca.account_number
           , ship_flv1.attribute1
           , ship_xca.business_low_type
           , ship_hca.account_number
  ;
  -- �̔����я��E�����ʏ���
  CURSOR get_sales_data_cur1 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , SUM( xbc.dlv_qty )                                             AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , SUM( xbc.amount_inc_tax )                                      AS amount_inc_tax             -- ������z�i�ō��j
         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm1_pct ) / 100 )         AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm1_amt ) )                      AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm2_pct ) / 100 )         AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm2_amt ) )                      AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm3_pct ) / 100 )         AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm3_amt ) )                      AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( SELECT xse.sales_base_code                                             AS base_code                  -- ���_�R�[�h
                , NVL2( xmbc.calc_type, xse.results_employee_code       , NULL )  AS emp_code                   -- �S���҃R�[�h
                , xse.ship_to_customer_code                                       AS ship_cust_code             -- �ڋq�y�[�i��z
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho             , NULL )  AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu             , NULL )  AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.bill_cust_code              , NULL )  AS bill_cust_code             -- �ڋq�y������z
                , NVL2( xmbc.calc_type, xse.period_year                 , NULL )  AS period_year                -- ��v�N�x
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code    , NULL )  AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , NVL2( xmbc.calc_type, xse.delivery_ym                 , NULL )  AS delivery_ym                -- �[�i���N��
                , NVL2( xmbc.calc_type, xse.dlv_qty                     , NULL )  AS dlv_qty                    -- �[�i����
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                , NULL )  AS dlv_uom_code               -- �[�i�P��
                , xse.amount_inc_tax                                              AS amount_inc_tax             -- ������z(�ō�)
                , NVL2( xmbc.calc_type, NULL, xse.container_code )                AS container_code             -- �e��敪�R�[�h
                , xse.dlv_unit_price                                              AS dlv_unit_price             -- �������z
                , NVL2( xmbc.calc_type, xse.tax_div                     , NULL )  AS tax_div                    -- ����ŋ敪
                , NVL2( xmbc.calc_type, xse.tax_code                    , NULL )  AS tax_code                   -- �ŋ��R�[�h
                , NVL2( xmbc.calc_type, xse.tax_rate                    , NULL )  AS tax_rate                   -- ����ŗ�
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule           , NULL )  AS tax_rounding_rule          -- �[�������敪
                , NVL2( xmbc.calc_type, xse.term_name                   , NULL )  AS term_name                  -- �x������
                , xse.closing_date                                                AS closing_date               -- ���ߓ�
                , NVL2( xmbc.calc_type, xse.expect_payment_date         , NULL )  AS expect_payment_date        -- �x���\���
                , NVL2( xmbc.calc_type, xse.calc_target_period_from     , NULL )  AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to       , NULL )  AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                  AS calc_type                  -- �v�Z����
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code             , NULL )  AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code        , NULL )  AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type         , NULL )  AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                    , NULL )  AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                    , NULL )  AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code             , NULL )  AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code        , NULL )  AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type         , NULL )  AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                    , NULL )  AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                    , NULL )  AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code             , NULL )  AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code        , NULL )  AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type         , NULL )  AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                    , NULL )  AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                    , NULL )  AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                     AS item_code                  -- �G���[�i�ڃR�[�h
                , xse.amount_fix_date                                             AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , xsel.dlv_qty                               AS dlv_qty                       -- �[�i����
                       , xsel.dlv_uom_code                          AS dlv_uom_code                  -- �[�i�P��
                       , xsel.pure_amount + xsel.tax_amount         AS amount_inc_tax                -- ������z�i�ō��j
                       , NVL( flv1.attribute1
                            , cv_container_code_others )            AS container_code                -- �e��敪�R�[�h
                       , xsel.dlv_unit_price                        AS dlv_unit_price                -- �������z
                       , NVL2( flv2.lookup_code
                             , NULL
                             , xsel.item_code )                     AS item_code                     -- �݌ɕi�ڃR�[�h
                       , flv2.lookup_code                           AS item_code_no_inv              -- ��݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                     , fnd_lookup_values             flv1       -- �e��Q
                     , fnd_lookup_values             flv2       -- ��݌ɕi��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND flv1.lookup_code(+)         = xsim.vessel_group
                    AND flv1.lookup_type(+)         = cv_lookup_type_04
                    AND flv1.language(+)            = USERENV( 'LANG' )
                    AND flv1.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                                  AND NVL( flv1.end_date_active,   gd_process_date )
                    AND flv2.lookup_code(+)         = xsel.item_code
                    AND flv2.lookup_type(+)         = cv_lookup_type_05
                    AND flv2.language(+)            = USERENV( 'LANG' )
                    AND flv2.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                  AND NVL( flv2.end_date_active,   gd_process_date )
                )                           xse       -- �C�����C���r���[�E�̔����я��
              , xxcok_mst_bm_contract       xmbc      -- �̎�����}�X�^
           WHERE xse.ship_gyotai_tyu               = cv_gyotai_tyu_vd
             AND xse.item_code_no_inv             IS NULL
             AND xmbc.calc_type(+)                 = cv_calc_type_sales_price
             AND xmbc.cust_code(+)                 = xse.ship_to_customer_code
             AND xmbc.selling_price(+)             = xse.dlv_unit_price
             AND xmbc.calc_target_flag(+)          = cv_enable
             AND EXISTS ( SELECT 'X'
                          FROM xxcok_mst_bm_contract xmbc2 -- �̎�����}�X�^
                          WHERE xmbc2.calc_type        = cv_calc_type_sales_price
                            AND xmbc2.cust_code        = xse.ship_to_customer_code
                            AND xmbc2.calc_target_flag = cv_enable
                 )
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_uom_code
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- �̔����я��E�e��敪�ʏ���
  CURSOR get_sales_data_cur2 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , SUM( xbc.dlv_qty )                                             AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , SUM( xbc.amount_inc_tax )                                      AS amount_inc_tax             -- ������z�i�ō��j
         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm1_pct ) / 100 )         AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm1_amt ) )                      AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm2_pct ) / 100 )         AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm2_amt ) )                      AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , ROUND( SUM( xbc.amount_inc_tax * xbc.bm3_pct ) / 100 )         AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , ROUND( SUM( xbc.dlv_qty * xbc.bm3_amt ) )                      AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( SELECT xse.sales_base_code                                             AS base_code                  -- ���_�R�[�h
                , NVL2( xmbc.calc_type, xse.results_employee_code       , NULL )  AS emp_code                   -- �S���҃R�[�h
                , xse.ship_to_customer_code                                       AS ship_cust_code             -- �ڋq�y�[�i��z
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho             , NULL )  AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu             , NULL )  AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.bill_cust_code              , NULL )  AS bill_cust_code             -- �ڋq�y������z
                , NVL2( xmbc.calc_type, xse.period_year                 , NULL )  AS period_year                -- ��v�N�x
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code    , NULL )  AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , NVL2( xmbc.calc_type, xse.delivery_ym                 , NULL )  AS delivery_ym                -- �[�i���N��
                , NVL2( xmbc.calc_type, xse.dlv_qty                     , NULL )  AS dlv_qty                    -- �[�i����
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                , NULL )  AS dlv_uom_code               -- �[�i�P��
                , xse.amount_inc_tax                                              AS amount_inc_tax             -- ������z(�ō�)
                , xse.container_code                                              AS container_code             -- �e��敪�R�[�h
                , NVL2( xmbc.calc_type, NULL, xse.dlv_unit_price )                AS dlv_unit_price             -- �������z
                , NVL2( xmbc.calc_type, xse.tax_div                     , NULL )  AS tax_div                    -- ����ŋ敪
                , NVL2( xmbc.calc_type, xse.tax_code                    , NULL )  AS tax_code                   -- �ŋ��R�[�h
                , NVL2( xmbc.calc_type, xse.tax_rate                    , NULL )  AS tax_rate                   -- ����ŗ�
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule           , NULL )  AS tax_rounding_rule          -- �[�������敪
                , NVL2( xmbc.calc_type, xse.term_name                   , NULL )  AS term_name                  -- �x������
                , xse.closing_date                                                AS closing_date               -- ���ߓ�
                , NVL2( xmbc.calc_type, xse.expect_payment_date         , NULL )  AS expect_payment_date        -- �x���\���
                , NVL2( xmbc.calc_type, xse.calc_target_period_from     , NULL )  AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to       , NULL )  AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                  AS calc_type                  -- �v�Z����
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code             , NULL )  AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code        , NULL )  AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type         , NULL )  AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                    , NULL )  AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                    , NULL )  AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code             , NULL )  AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code        , NULL )  AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type         , NULL )  AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                    , NULL )  AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                    , NULL )  AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code             , NULL )  AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code        , NULL )  AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type         , NULL )  AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                    , NULL )  AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                    , NULL )  AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                     AS item_code                  -- �G���[�i�ڃR�[�h
                , xse.amount_fix_date                                             AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , xsel.dlv_qty                               AS dlv_qty                       -- �[�i����
                       , xsel.dlv_uom_code                          AS dlv_uom_code                  -- �[�i�P��
                       , xsel.pure_amount + xsel.tax_amount         AS amount_inc_tax                -- ������z�i�ō��j
                       , NVL( flv1.attribute1
                            , cv_container_code_others )            AS container_code                -- �e��敪�R�[�h
                       , xsel.dlv_unit_price                        AS dlv_unit_price                -- �������z
                       , NVL2( flv2.lookup_code
                             , NULL
                             , xsel.item_code )                     AS item_code                     -- �݌ɕi�ڃR�[�h
                       , flv2.lookup_code                           AS item_code_no_inv              -- ��݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                     , fnd_lookup_values             flv1       -- �e��Q
                     , fnd_lookup_values             flv2       -- ��݌ɕi��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND flv1.lookup_code(+)         = xsim.vessel_group
                    AND flv1.lookup_type(+)         = cv_lookup_type_04
                    AND flv1.language(+)            = USERENV( 'LANG' )
                    AND flv1.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                                  AND NVL( flv1.end_date_active,   gd_process_date )
                    AND flv2.lookup_code(+)         = xsel.item_code
                    AND flv2.lookup_type(+)         = cv_lookup_type_05
                    AND flv2.language(+)            = USERENV( 'LANG' )
                    AND flv2.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                  AND NVL( flv2.end_date_active,   gd_process_date )
                )                           xse       -- �C�����C���r���[�E�̔����я��
              , xxcok_mst_bm_contract       xmbc      -- �̎�����}�X�^
           WHERE xse.ship_gyotai_tyu               = cv_gyotai_tyu_vd
             AND xse.item_code_no_inv             IS NULL
             AND xmbc.calc_type(+)                 = cv_calc_type_container
             AND xmbc.cust_code(+)                 = xse.ship_to_customer_code
             AND xmbc.container_type_code(+)       = xse.container_code
             AND xmbc.calc_target_flag(+)          = cv_enable
             AND EXISTS ( SELECT 'X'
                          FROM xxcok_mst_bm_contract xmbc2 -- �̎�����}�X�^
                          WHERE xmbc2.calc_type        = cv_calc_type_container
                            AND xmbc2.cust_code        = xse.ship_to_customer_code
                            AND xmbc2.calc_target_flag = cv_enable
                 )
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_uom_code
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- �̔����я��E�ꗥ����
  CURSOR get_sales_data_cur3 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , SUM( xbc.dlv_qty )                                             AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , SUM( xbc.amount_inc_tax )                                      AS amount_inc_tax             -- ������z�i�ō��j
         , NULL                                                           AS container_code             -- �e��敪�R�[�h
         , NULL                                                           AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm1_pct ) / 100 )         AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm1_amt ) )                      AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm2_pct ) / 100 )         AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm2_amt ) )                      AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm3_pct ) / 100 )         AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm3_amt ) )                      AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( SELECT xse.sales_base_code                                             AS base_code                  -- ���_�R�[�h
                , NVL2( xmbc.calc_type, xse.results_employee_code       , NULL )  AS emp_code                   -- �S���҃R�[�h
                , xse.ship_to_customer_code                                       AS ship_cust_code             -- �ڋq�y�[�i��z
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho             , NULL )  AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu             , NULL )  AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.bill_cust_code              , NULL )  AS bill_cust_code             -- �ڋq�y������z
                , NVL2( xmbc.calc_type, xse.period_year                 , NULL )  AS period_year                -- ��v�N�x
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code    , NULL )  AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , NVL2( xmbc.calc_type, xse.delivery_ym                 , NULL )  AS delivery_ym                -- �[�i���N��
                , NVL2( xmbc.calc_type, xse.dlv_qty                     , NULL )  AS dlv_qty                    -- �[�i����
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                , NULL )  AS dlv_uom_code               -- �[�i�P��
                , xse.amount_inc_tax                                              AS amount_inc_tax             -- ������z(�ō�)
                , NULL                                                            AS container_code             -- �e��敪�R�[�h
                , NULL                                                            AS dlv_unit_price             -- �������z
                , NVL2( xmbc.calc_type, xse.tax_div                     , NULL )  AS tax_div                    -- ����ŋ敪
                , NVL2( xmbc.calc_type, xse.tax_code                    , NULL )  AS tax_code                   -- �ŋ��R�[�h
                , NVL2( xmbc.calc_type, xse.tax_rate                    , NULL )  AS tax_rate                   -- ����ŗ�
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule           , NULL )  AS tax_rounding_rule          -- �[�������敪
                , NVL2( xmbc.calc_type, xse.term_name                   , NULL )  AS term_name                  -- �x������
                , xse.closing_date                                                AS closing_date               -- ���ߓ�
                , NVL2( xmbc.calc_type, xse.expect_payment_date         , NULL )  AS expect_payment_date        -- �x���\���
                , NVL2( xmbc.calc_type, xse.calc_target_period_from     , NULL )  AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to       , NULL )  AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                  AS calc_type                  -- �v�Z����
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code             , NULL )  AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code        , NULL )  AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type         , NULL )  AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                    , NULL )  AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                    , NULL )  AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code             , NULL )  AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code        , NULL )  AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type         , NULL )  AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                    , NULL )  AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                    , NULL )  AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code             , NULL )  AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code        , NULL )  AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type         , NULL )  AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                    , NULL )  AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                    , NULL )  AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                     AS item_code                  -- �G���[�i�ڃR�[�h
                , xse.amount_fix_date                                             AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , xsel.dlv_qty                               AS dlv_qty                       -- �[�i����
                       , xsel.dlv_uom_code                          AS dlv_uom_code                  -- �[�i�P��
                       , xsel.pure_amount + xsel.tax_amount         AS amount_inc_tax                -- ������z�i�ō��j
                       , NVL( flv1.attribute1
                            , cv_container_code_others )            AS container_code                -- �e��敪�R�[�h
                       , xsel.dlv_unit_price                        AS dlv_unit_price                -- �������z
                       , NVL2( flv2.lookup_code
                             , NULL
                             , xsel.item_code )                     AS item_code                     -- �݌ɕi�ڃR�[�h
                       , flv2.lookup_code                           AS item_code_no_inv              -- ��݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                     , fnd_lookup_values             flv1       -- �e��Q
                     , fnd_lookup_values             flv2       -- ��݌ɕi��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND flv1.lookup_code(+)         = xsim.vessel_group
                    AND flv1.lookup_type(+)         = cv_lookup_type_04
                    AND flv1.language(+)            = USERENV( 'LANG' )
                    AND flv1.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                                  AND NVL( flv1.end_date_active,   gd_process_date )
                    AND flv2.lookup_code(+)         = xsel.item_code
                    AND flv2.lookup_type(+)         = cv_lookup_type_05
                    AND flv2.language(+)            = USERENV( 'LANG' )
                    AND flv2.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                  AND NVL( flv2.end_date_active,   gd_process_date )
                )                           xse       -- �C�����C���r���[�E�̔����я��
              , xxcok_mst_bm_contract       xmbc      -- �̎�����}�X�^
           WHERE xse.ship_gyotai_tyu               = cv_gyotai_tyu_vd
             AND xse.item_code_no_inv             IS NULL
             AND xmbc.calc_type                    = cv_calc_type_uniform_rate
             AND xmbc.cust_code                    = xse.ship_to_customer_code
             AND xmbc.calc_target_flag             = cv_enable
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_uom_code
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- �̔����я��E��z����
  CURSOR get_sales_data_cur4 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , xbc.dlv_qty                                                    AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , xbc.amount_inc_tax                                             AS amount_inc_tax             -- ������z�i�ō��j
         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , NULL                                                           AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.bm1_amt ) )                                    AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , NULL                                                           AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.bm2_amt ) )                                    AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , NULL                                                           AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.bm3_amt ) )                                    AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( SELECT xses.sales_base_code                                            AS base_code                  -- ���_�R�[�h
                , xses.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
                , xses.period_year                                                AS period_year                -- ��v�N�x
                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
                , xses.dlv_qty                                                    AS dlv_qty                    -- �[�i����
                , xses.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
                , xses.amount_inc_tax                                             AS amount_inc_tax             -- ������z(�ō�)
                , NULL                                                            AS container_code             -- �e��敪�R�[�h
                , NULL                                                            AS dlv_unit_price             -- �������z
                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
                , xses.term_name                                                  AS term_name                  -- �x������
                , xses.closing_date                                               AS closing_date               -- ���ߓ�
                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                  AS calc_type                  -- �v�Z����
                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , xmbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , xmbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
                , xses.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , xses.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , xses.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , xmbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , xmbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , xses.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , xses.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , xses.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , xmbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , xmbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , NULL                                       AS dlv_qty                       -- �[�i����
                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
                       , NULL                                       AS container_code                -- �e��敪�R�[�h
                       , NULL                                       AS dlv_unit_price                -- �������z
                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values             flv2       -- ��݌ɕi��
                                     WHERE flv2.lookup_code         = xsel.item_code
                                       AND flv2.lookup_type         = cv_lookup_type_05
                                       AND flv2.language            = USERENV( 'LANG' )
                                       AND flv2.enabled_flag        = cv_enable
                                       AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                                     AND NVL( flv2.end_date_active,   gd_process_date )
                        )
                  GROUP BY xseh.ship_to_customer_code
                         , xt0c.ship_gyotai_tyu
                         , xt0c.ship_gyotai_sho
                         , xt0c.ship_delivery_chain_code
                         , xt0c.bill_cust_code
                         , xt0c.bm1_vendor_code
                         , xt0c.bm1_vendor_site_code
                         , xt0c.bm1_bm_payment_type
                         , xt0c.bm2_vendor_code
                         , xt0c.bm2_vendor_site_code
                         , xt0c.bm2_bm_payment_type
                         , xt0c.bm3_vendor_code
                         , xt0c.bm3_vendor_site_code
                         , xt0c.bm3_bm_payment_type
                         , xt0c.tax_div
                         , xt0c.tax_code
                         , xt0c.tax_rate
                         , xt0c.tax_rounding_rule
                         , xt0c.receiv_discount_rate
                         , xt0c.term_name
                         , xt0c.closing_date
                         , xt0c.expect_payment_date
                         , xt0c.period_year
                         , xt0c.calc_target_period_from
                         , xt0c.calc_target_period_to
                         , xseh.sales_base_code
                         , xseh.results_employee_code
                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
                         , xt0c.amount_fix_date
                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
              , xxcok_mst_bm_contract       xmbc      -- �̎�����}�X�^
           WHERE xses.ship_gyotai_tyu              = cv_gyotai_tyu_vd
             AND xmbc.calc_type                    = cv_calc_type_flat_rate
             AND xmbc.cust_code                    = xses.ship_to_customer_code
             AND xmbc.calc_target_flag             = cv_enable
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_qty
           , xbc.dlv_uom_code
           , xbc.amount_inc_tax
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- �̔����я��E�d�C���i�Œ�^�ϓ��j
  CURSOR get_sales_data_cur5 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , xbc.dlv_qty                                                    AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , xbc.amount_inc_tax                                             AS amount_inc_tax             -- ������z�i�ō��j
         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , NULL                                                           AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , NULL                                                           AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , TRUNC( SUM( xbc.bm1_amt ) )                                    AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , NULL                                                           AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , NULL                                                           AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , NULL                                                           AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , NULL                                                           AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( -- �d�C���i�Œ�j
           SELECT xses.sales_base_code                                            AS base_code                  -- ���_�R�[�h
                , xses.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
                , xses.period_year                                                AS period_year                -- ��v�N�x
                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
                , NULL                                                            AS dlv_qty                    -- �[�i����
                , NULL                                                            AS dlv_uom_code               -- �[�i�P��
                , 0                                                               AS amount_inc_tax             -- ������z(�ō�)
                , NULL                                                            AS container_code             -- �e��敪�R�[�h
                , NULL                                                            AS dlv_unit_price             -- �������z
                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
                , xses.term_name                                                  AS term_name                  -- �x������
                , xses.closing_date                                               AS closing_date               -- ���ߓ�
                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                  AS calc_type                  -- �v�Z����
                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , NULL                                                            AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , xmbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NULL                                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NULL                                                            AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NULL                                                            AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NULL                                                            AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NULL                                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NULL                                                            AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NULL                                                            AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NULL                                                            AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , NULL                                       AS dlv_qty                       -- �[�i����
                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
                       , NULL                                       AS container_code                -- �e��敪�R�[�h
                       , NULL                                       AS dlv_unit_price                -- �������z
                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values             flv2       -- ��݌ɕi��
                                     WHERE flv2.lookup_code         = xsel.item_code
                                       AND flv2.lookup_type         = cv_lookup_type_05
                                       AND flv2.language            = USERENV( 'LANG' )
                                       AND flv2.enabled_flag        = cv_enable
                                       AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                                     AND NVL( flv2.end_date_active,   gd_process_date )                    )
                  GROUP BY xseh.ship_to_customer_code
                         , xt0c.ship_gyotai_tyu
                         , xt0c.ship_gyotai_sho
                         , xt0c.ship_delivery_chain_code
                         , xt0c.bill_cust_code
                         , xt0c.bm1_vendor_code
                         , xt0c.bm1_vendor_site_code
                         , xt0c.bm1_bm_payment_type
                         , xt0c.bm2_vendor_code
                         , xt0c.bm2_vendor_site_code
                         , xt0c.bm2_bm_payment_type
                         , xt0c.bm3_vendor_code
                         , xt0c.bm3_vendor_site_code
                         , xt0c.bm3_bm_payment_type
                         , xt0c.tax_div
                         , xt0c.tax_code
                         , xt0c.tax_rate
                         , xt0c.tax_rounding_rule
                         , xt0c.receiv_discount_rate
                         , xt0c.term_name
                         , xt0c.closing_date
                         , xt0c.expect_payment_date
                         , xt0c.period_year
                         , xt0c.calc_target_period_from
                         , xt0c.calc_target_period_to
                         , xseh.sales_base_code
                         , xseh.results_employee_code
                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
                         , xt0c.amount_fix_date
                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
              , xxcok_mst_bm_contract       xmbc      -- �̎�����}�X�^
           WHERE xses.ship_gyotai_tyu              = cv_gyotai_tyu_vd
             AND xmbc.calc_type                    = cv_calc_type_electricity_cost
             AND xmbc.cust_code                    = xses.ship_to_customer_code
             AND xmbc.calc_target_flag             = cv_enable
           UNION ALL
           -- �d�C���i�ϓ��j
           SELECT xses.sales_base_code                                            AS base_code                  -- ���_�R�[�h
                , xses.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
                , xses.period_year                                                AS period_year                -- ��v�N�x
                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
                , NULL                                                            AS dlv_qty                    -- �[�i����
                , NULL                                                            AS dlv_uom_code               -- �[�i�P��
                , 0                                                               AS amount_inc_tax             -- ������z(�ō�)
                , NULL                                                            AS container_code             -- �e��敪�R�[�h
                , NULL                                                            AS dlv_unit_price             -- �������z
                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
                , xses.term_name                                                  AS term_name                  -- �x������
                , xses.closing_date                                               AS closing_date               -- ���ߓ�
                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , cv_calc_type_electricity_cost                                   AS calc_type                  -- �v�Z����
                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , NULL                                                            AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , xses.amount_inc_tax                                             AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NULL                                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NULL                                                            AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NULL                                                            AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NULL                                                            AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NULL                                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NULL                                                            AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NULL                                                            AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NULL                                                            AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , NULL                                       AS dlv_qty                       -- �[�i����
                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
                       , NULL                                       AS container_code                -- �e��敪�R�[�h
                       , NULL                                       AS dlv_unit_price                -- �������z
                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
                    AND xsel.item_code              = gv_elec_change_item_code
                  GROUP BY xseh.ship_to_customer_code
                         , xt0c.ship_gyotai_tyu
                         , xt0c.ship_gyotai_sho
                         , xt0c.ship_delivery_chain_code
                         , xt0c.bill_cust_code
                         , xt0c.bm1_vendor_code
                         , xt0c.bm1_vendor_site_code
                         , xt0c.bm1_bm_payment_type
                         , xt0c.bm2_vendor_code
                         , xt0c.bm2_vendor_site_code
                         , xt0c.bm2_bm_payment_type
                         , xt0c.bm3_vendor_code
                         , xt0c.bm3_vendor_site_code
                         , xt0c.bm3_bm_payment_type
                         , xt0c.tax_div
                         , xt0c.tax_code
                         , xt0c.tax_rate
                         , xt0c.tax_rounding_rule
                         , xt0c.receiv_discount_rate
                         , xt0c.term_name
                         , xt0c.closing_date
                         , xt0c.expect_payment_date
                         , xt0c.period_year
                         , xt0c.calc_target_period_from
                         , xt0c.calc_target_period_to
                         , xseh.sales_base_code
                         , xseh.results_employee_code
                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
                         , xt0c.amount_fix_date
                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_qty
           , xbc.dlv_uom_code
           , xbc.amount_inc_tax
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  -- �̔����я��E�����l����
  CURSOR get_sales_data_cur6 IS
    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
         , xbc.period_year                                                AS period_year                -- ��v�N�x
         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
         , xbc.dlv_qty                                                    AS dlv_qty                    -- �[�i����
         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
         , xbc.amount_inc_tax                                             AS amount_inc_tax             -- ������z�i�ō��j
         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
         , xbc.term_name                                                  AS term_name                  -- �x������
         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                                    AS bm1_pct                    -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm1_pct ) / 100 )         AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm1_amt ) )                      AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                                    AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                                    AS bm2_amt                    -- �y�a�l�Q�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm2_pct ) / 100 )         AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm2_amt ) )                      AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                                    AS bm3_pct                    -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                                    AS bm3_amt                    -- �y�a�l�R�zBM���z
         , TRUNC( SUM( xbc.amount_inc_tax * xbc.bm3_pct ) / 100 )         AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , TRUNC( SUM( xbc.dlv_qty * xbc.bm3_amt ) )                      AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
    FROM ( SELECT xses.sales_base_code                                            AS base_code                  -- ���_�R�[�h
                , xses.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
                , xses.period_year                                                AS period_year                -- ��v�N�x
                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
                , NULL                                                            AS dlv_qty                    -- �[�i����
                , NULL                                                            AS dlv_uom_code               -- �[�i�P��
                , amount_inc_tax                                                  AS amount_inc_tax             -- ������z(�ō�)
                , NULL                                                            AS container_code             -- �e��敪�R�[�h
                , NULL                                                            AS dlv_unit_price             -- �������z
                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
                , xses.term_name                                                  AS term_name                  -- �x������
                , xses.closing_date                                               AS closing_date               -- ���ߓ�
                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
                , cv_calc_type_uniform_rate                                       AS calc_type                  -- �v�Z����
                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
                , receiv_discount_rate                                            AS bm1_pct                    -- �y�a�l�P�zBM��(%)
                , NULL                                                            AS bm1_amt                    -- �y�a�l�P�zBM���z
                , NULL                                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
                , NULL                                                            AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
                , NULL                                                            AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
                , NULL                                                            AS bm2_amt                    -- �y�a�l�Q�zBM���z
                , NULL                                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
                , NULL                                                            AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NULL                                                            AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
                , NULL                                                            AS bm3_pct                    -- �y�a�l�R�zBM��(%)
                , NULL                                                            AS bm3_amt                    -- �y�a�l�R�zBM���z
                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
                       , xt0c.term_name                             AS term_name                     -- �x������
                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
                       , NULL                                       AS dlv_qty                       -- �[�i����
                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
                       , NULL                                       AS container_code                -- �e��敪�R�[�h
                       , NULL                                       AS dlv_unit_price                -- �������z
                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND xsim.item_code              = xsel.item_code
-- Start 2009/06/26 Ver_2.1 0000269 M.Hiruta
                    AND xt0c.receiv_discount_rate  IS NOT NULL -- �����l�������ݒ肳��Ă���ڋq�̂�
-- End   2009/06/26 Ver_2.1 0000269 M.Hiruta
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values             flv2       -- ��݌ɕi��
                                     WHERE flv2.lookup_code         = xsel.item_code
                                       AND flv2.lookup_type         = cv_lookup_type_05
                                       AND flv2.language            = USERENV( 'LANG' )
                                       AND flv2.enabled_flag        = cv_enable
                                       AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
                                                                     AND NVL( flv2.end_date_active,   gd_process_date )
                        )
                  GROUP BY xseh.ship_to_customer_code
                         , xt0c.ship_gyotai_tyu
                         , xt0c.ship_gyotai_sho
                         , xt0c.ship_delivery_chain_code
                         , xt0c.bill_cust_code
                         , xt0c.bm1_vendor_code
                         , xt0c.bm1_vendor_site_code
                         , xt0c.bm1_bm_payment_type
                         , xt0c.bm2_vendor_code
                         , xt0c.bm2_vendor_site_code
                         , xt0c.bm2_bm_payment_type
                         , xt0c.bm3_vendor_code
                         , xt0c.bm3_vendor_site_code
                         , xt0c.bm3_bm_payment_type
                         , xt0c.tax_div
                         , xt0c.tax_code
                         , xt0c.tax_rate
                         , xt0c.tax_rounding_rule
                         , xt0c.receiv_discount_rate
                         , xt0c.term_name
                         , xt0c.closing_date
                         , xt0c.expect_payment_date
                         , xt0c.period_year
                         , xt0c.calc_target_period_from
                         , xt0c.calc_target_period_to
                         , xseh.sales_base_code
                         , xseh.results_employee_code
                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
                         , xt0c.amount_fix_date
                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
           WHERE xses.ship_gyotai_tyu             <> cv_gyotai_tyu_vd
         )                        xbc
    GROUP BY xbc.base_code
           , xbc.emp_code
           , xbc.ship_cust_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_qty
           , xbc.dlv_uom_code
           , xbc.amount_inc_tax
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
  ;
  --==================================================
  -- �O���[�o���^�C�v
  --==================================================
  TYPE get_sales_data_rtype        IS RECORD (
    base_code                      VARCHAR2(4)
  , emp_code                       VARCHAR2(5)
  , ship_cust_code                 VARCHAR2(9)
  , ship_gyotai_sho                VARCHAR2(2)
  , ship_gyotai_tyu                VARCHAR2(2)
  , bill_cust_code                 VARCHAR2(9)
  , period_year                    NUMBER
  , ship_delivery_chain_code       VARCHAR2(9)
  , delivery_ym                    VARCHAR2(6)
  , dlv_qty                        NUMBER
  , dlv_uom_code                   VARCHAR2(3)
  , amount_inc_tax                 NUMBER
  , container_code                 VARCHAR2(4)
  , dlv_unit_price                 NUMBER
  , tax_div                        VARCHAR2(1)
  , tax_code                       VARCHAR2(50)
  , tax_rate                       NUMBER
  , tax_rounding_rule              VARCHAR2(30)
  , term_name                      VARCHAR2(8)
  , closing_date                   DATE
  , expect_payment_date            DATE
  , calc_target_period_from        DATE
  , calc_target_period_to          DATE
  , calc_type                      VARCHAR2(2)
  , bm1_vendor_code                VARCHAR2(9)
  , bm1_vendor_site_code           VARCHAR2(10)
  , bm1_bm_payment_type            VARCHAR2(1)
  , bm1_pct                        NUMBER
  , bm1_amt                        NUMBER
  , bm1_cond_bm_tax_pct            NUMBER
  , bm1_cond_bm_amt_tax            NUMBER
  , bm1_electric_amt_tax           NUMBER
  , bm2_vendor_code                VARCHAR2(9)
  , bm2_vendor_site_code           VARCHAR2(10)
  , bm2_bm_payment_type            VARCHAR2(1)
  , bm2_pct                        NUMBER
  , bm2_amt                        NUMBER
  , bm2_cond_bm_tax_pct            NUMBER
  , bm2_cond_bm_amt_tax            NUMBER
  , bm2_electric_amt_tax           NUMBER
  , bm3_vendor_code                VARCHAR2(9)
  , bm3_vendor_site_code           VARCHAR2(10)
  , bm3_bm_payment_type            VARCHAR2(1)
  , bm3_pct                        NUMBER
  , bm3_amt                        NUMBER
  , bm3_cond_bm_tax_pct            NUMBER
  , bm3_cond_bm_amt_tax            NUMBER
  , bm3_electric_amt_tax           NUMBER
  , item_code                      VARCHAR2(7)
  , amount_fix_date                DATE
  );
  TYPE xcbs_data_ttype             IS TABLE OF xxcok_cond_bm_support%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : update_xsel
   * Description      : �̔����јA�g���ʂ̍X�V(A-12)
   ***********************************************************************************/
  PROCEDURE update_xsel(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xsel';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- �G���[�����O�o�͗p�ޔ�ϐ�
    lt_sales_exp_line_id           xxcos_sales_exp_lines.sales_exp_line_id%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xsel_update_lock_cur
    IS
      SELECT xsel.sales_exp_line_id    AS sales_exp_line_id    -- �̔����і���ID
           , xsel.sales_exp_header_id  AS sales_exp_header_id  -- �̔����уw�b�_ID
           , xsel.item_code            AS item_code            -- �i�ڃR�[�h
           , xsel.dlv_unit_price       AS dlv_unit_price       -- �[�i�P��
      FROM xxcok_tmp_014a01c_custdata xt0c            -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
         , xxcos_sales_exp_headers    xseh            -- �̔����уw�b�_�[�e�[�u��
         , xxcos_sales_exp_lines      xsel            -- �̔����і��׃e�[�u��
         , xxcmm_system_items_b       xsib            -- disc�i�ڃ}�X�^�A�h�I��
         , fnd_lookup_values          flv             -- �N�C�b�N�R�[�h�i�e��Q�j
      WHERE xseh.ship_to_customer_code   = xt0c.ship_cust_code
        AND xseh.delivery_date          <= xt0c.closing_date
        AND xt0c.amount_fix_date         = gd_process_date
        AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
        AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
        AND xsib.item_code               = xsel.item_code
        AND flv.lookup_code (+)          = xsib.vessel_group
        AND flv.lookup_type (+)          = cv_lookup_type_04
        AND flv.language    (+)          = USERENV( 'LANG' )
        AND flv.enabled_flag (+)         = cv_enable
        AND gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                                AND NVL( flv.end_date_active  , gd_process_date )
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_bm_contract_err xbce
                         WHERE xbce.cust_code           = xseh.ship_to_customer_code
                           AND xbce.item_code           = xsel.item_code
                           AND xbce.container_type_code = NVL( flv.attribute1, cv_container_code_others )
                           AND xbce.selling_price       = xsel.dlv_unit_price
            )
      FOR UPDATE OF xsel.sales_exp_line_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̔����јA�g���ʍX�V���[�v
    --==================================================
    << xsel_update_lock_loop >>
    FOR xsel_update_lock_rec IN xsel_update_lock_cur LOOP
      lt_sales_exp_line_id := xsel_update_lock_rec.sales_exp_line_id;
      --==================================================
      -- �̔����јA�g���ʃf�[�^�X�V
      --==================================================
      UPDATE xxcos_sales_exp_lines      xsel
      SET xsel.to_calculate_fees_flag = cv_xsel_if_flag_yes   -- �萔���v�Z�C���^�[�t�F�[�X�σt���O
        , xsel.last_updated_by        = cn_last_updated_by
        , xsel.last_update_date       = SYSDATE
        , xsel.last_update_login      = cn_last_update_login
        , xsel.request_id             = cn_request_id
        , xsel.program_application_id = cn_program_application_id
        , xsel.program_id             = cn_program_id
        , xsel.program_update_date    = SYSDATE
      WHERE xsel.sales_exp_header_id    = xsel_update_lock_rec.sales_exp_header_id
        AND xsel.item_code              = xsel_update_lock_rec.item_code
        AND xsel.dlv_unit_price         = xsel_update_lock_rec.dlv_unit_price
        AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      ;
    END LOOP xsel_update_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00081
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'sales_exp_line_id' || '�y' || lt_sales_exp_line_id || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xsel;
--
  /**********************************************************************************
   * Procedure Name   : insert_xbce
   * Description      : �̎�����G���[�e�[�u���ւ̓o�^(A-11)
   ***********************************************************************************/
  PROCEDURE insert_xbce(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- �̔����я�񃌃R�[�h
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbce';      -- �v���O������
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
    -- �̎�����G���[�e�[�u���ւ̓o�^
    --==================================================
    IF( i_get_sales_data_rec.calc_type IS NULL ) THEN
      INSERT INTO xxcok_bm_contract_err (
        base_code              -- ���_�R�[�h
      , cust_code              -- �ڋq�R�[�h
      , item_code              -- �i�ڃR�[�h
      , container_type_code    -- �e��敪�R�[�h
      , selling_price          -- ����
      , selling_amt_tax        -- ������z(�ō�)
      , closing_date           -- ���ߓ�
      , created_by             -- �쐬��
      , creation_date          -- �쐬��
      , last_updated_by        -- �ŏI�X�V��
      , last_update_date       -- �ŏI�X�V��
      , last_update_login      -- �ŏI�X�V���O�C��
      , request_id             -- �v��ID
      , program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id             -- �R���J�����g�E�v���O����ID
      , program_update_date    -- �v���O�����X�V��
      )
      VALUES (
        i_get_sales_data_rec.base_code           -- ���_�R�[�h
      , i_get_sales_data_rec.ship_cust_code      -- �ڋq�R�[�h
      , i_get_sales_data_rec.item_code           -- �i�ڃR�[�h
      , i_get_sales_data_rec.container_code      -- �e��敪�R�[�h
      , i_get_sales_data_rec.dlv_unit_price      -- ����
      , i_get_sales_data_rec.amount_inc_tax      -- ������z(�ō�)
      , i_get_sales_data_rec.closing_date        -- ���ߓ�
      , cn_created_by                            -- �쐬��
      , SYSDATE                                  -- �쐬��
      , cn_last_updated_by                       -- �ŏI�X�V��
      , SYSDATE                                  -- �ŏI�X�V��
      , cn_last_update_login                     -- �ŏI�X�V���O�C��
      , cn_request_id                            -- �v��ID
      , cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                            -- �R���J�����g�E�v���O����ID
      , SYSDATE                                  -- �v���O�����X�V��
      );
      gn_contract_err_cnt := gn_contract_err_cnt + 1;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbce;
--
  /**********************************************************************************
   * Procedure Name   : insert_xcbs
   * Description      : �����ʔ̎�̋��e�[�u���ւ̓o�^(A-10)
   ***********************************************************************************/
  PROCEDURE insert_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype      -- �̔����я�񃌃R�[�h
  , i_xcbs_data_tab                IN  xcbs_data_ttype           -- �����ʔ̎�̋����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xcbs';      -- �v���O������
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_����
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_����
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_����
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_fix_status                  xxcok_cond_bm_support.amt_fix_status%TYPE;   -- ���z�m��X�e�[�^�X
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���z�m��X�e�[�^�X����
    --==================================================
    IF( i_get_sales_data_rec.amount_fix_date = gd_process_date ) THEN
      lv_fix_status := cv_xcbs_fix;
    ELSE
      lv_fix_status := cv_xcbs_temp;
    END IF;
    --==================================================
    -- ���[�v������BM1����BM3�܂ł�3���R�[�h��o�^
    --==================================================
    << insert_xcbs_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      --==================================================
      -- �o�^�����m�F
      --==================================================
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR START
--      IF( i_xcbs_data_tab( i ).supplier_code IS NOT NULL ) THEN
      IF(     ( i_xcbs_data_tab( i ).supplier_code IS NOT NULL )
          AND (    ( i_xcbs_data_tab( i ).cond_bm_amt_tax       IS NOT NULL ) -- VDBM(�ō�) 
                OR ( i_xcbs_data_tab( i ).electric_amt_tax      IS NOT NULL ) -- �d�C��(�ō�)
                OR ( i_xcbs_data_tab( i ).csh_rcpt_discount_amt IS NOT NULL ) -- �����l���z
              )
      ) THEN
-- 2009/07/07 Ver.2.1 [��Q0000269] SCS K.Yamaguchi REPAIR END
        --==================================================
        -- �����ʔ̎�̋��v�Z���ʂ������ʔ̎�̋��e�[�u���ɓo�^
        --==================================================
        INSERT INTO xxcok_cond_bm_support (
          cond_bm_support_id        -- �����ʔ̎�̋�ID
        , base_code                 -- ���_�R�[�h
        , emp_code                  -- �S���҃R�[�h
        , delivery_cust_code        -- �ڋq�y�[�i��z
        , demand_to_cust_code       -- �ڋq�y������z
        , acctg_year                -- ��v�N�x
        , chain_store_code          -- �`�F�[���X�R�[�h
        , supplier_code             -- �d����R�[�h
        , supplier_site_code        -- �d����T�C�g�R�[�h
        , calc_type                 -- �v�Z����
        , delivery_date             -- �[�i���N��
        , delivery_qty              -- �[�i����
        , delivery_unit_type        -- �[�i�P��
        , selling_amt_tax           -- ������z(�ō�)
        , rebate_rate               -- ���ߗ�
        , rebate_amt                -- ���ߊz
        , container_type_code       -- �e��敪�R�[�h
        , selling_price             -- �������z
        , cond_bm_amt_tax           -- �����ʎ萔���z(�ō�)
        , cond_bm_amt_no_tax        -- �����ʎ萔���z(�Ŕ�)
        , cond_tax_amt              -- �����ʏ���Ŋz
        , electric_amt_tax          -- �d�C��(�ō�)
        , electric_amt_no_tax       -- �d�C��(�Ŕ�)
        , electric_tax_amt          -- �d�C������Ŋz
        , csh_rcpt_discount_amt     -- �����l���z
        , csh_rcpt_discount_amt_tax -- �����l������Ŋz
        , consumption_tax_class     -- ����ŋ敪
        , tax_code                  -- �ŋ��R�[�h
        , tax_rate                  -- ����ŗ�
        , term_code                 -- �x������
        , closing_date              -- ���ߓ�
        , expect_payment_date       -- �x���\���
        , calc_target_period_from   -- �v�Z�Ώۊ���(FROM)
        , calc_target_period_to     -- �v�Z�Ώۊ���(TO)
        , cond_bm_interface_status  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
        , cond_bm_interface_date    -- �A�g��(�����ʔ̎�̋�)
        , bm_interface_status       -- �A�g�X�e�[�^�X(�̎�c��)
        , bm_interface_date         -- �A�g��(�̎�c��)
        , ar_interface_status       -- �A�g�X�e�[�^�X(AR)
        , ar_interface_date         -- �A�g��(AR)
        , amt_fix_status            -- ���z�m��X�e�[�^�X
        , created_by                -- �쐬��
        , creation_date             -- �쐬��
        , last_updated_by           -- �ŏI�X�V��
        , last_update_date          -- �ŏI�X�V��
        , last_update_login         -- �ŏI�X�V���O�C��
        , request_id                -- �v��ID
        , program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                -- �R���J�����g�E�v���O����ID
        , program_update_date       -- �v���O�����X�V��
        )
        VALUES (
          xxcok_cond_bm_support_s01.NEXTVAL                   -- �����ʔ̎�̋�ID
        , i_xcbs_data_tab( i ).base_code                 -- ���_�R�[�h
        , i_xcbs_data_tab( i ).emp_code                  -- �S���҃R�[�h
        , i_xcbs_data_tab( i ).delivery_cust_code        -- �ڋq�y�[�i��z
        , i_xcbs_data_tab( i ).demand_to_cust_code       -- �ڋq�y������z
        , i_xcbs_data_tab( i ).acctg_year                -- ��v�N�x
        , i_xcbs_data_tab( i ).chain_store_code          -- �`�F�[���X�R�[�h
        , i_xcbs_data_tab( i ).supplier_code             -- �d����R�[�h
        , i_xcbs_data_tab( i ).supplier_site_code        -- �d����T�C�g�R�[�h
        , i_xcbs_data_tab( i ).calc_type                 -- �v�Z����
        , i_xcbs_data_tab( i ).delivery_date             -- �[�i���N��
        , i_xcbs_data_tab( i ).delivery_qty              -- �[�i����
        , i_xcbs_data_tab( i ).delivery_unit_type        -- �[�i�P��
        , i_xcbs_data_tab( i ).selling_amt_tax           -- ������z(�ō�)
        , i_xcbs_data_tab( i ).rebate_rate               -- ���ߗ�
        , i_xcbs_data_tab( i ).rebate_amt                -- ���ߊz
        , i_xcbs_data_tab( i ).container_type_code       -- �e��敪�R�[�h
        , i_xcbs_data_tab( i ).selling_price             -- �������z
        , i_xcbs_data_tab( i ).cond_bm_amt_tax           -- �����ʎ萔���z(�ō�)
        , i_xcbs_data_tab( i ).cond_bm_amt_no_tax        -- �����ʎ萔���z(�Ŕ�)
        , i_xcbs_data_tab( i ).cond_tax_amt              -- �����ʏ���Ŋz
        , i_xcbs_data_tab( i ).electric_amt_tax          -- �d�C��(�ō�)
        , i_xcbs_data_tab( i ).electric_amt_no_tax       -- �d�C��(�Ŕ�)
        , i_xcbs_data_tab( i ).electric_tax_amt          -- �d�C������Ŋz
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt     -- �����l���z
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt_tax -- �����l������Ŋz
        , i_xcbs_data_tab( i ).consumption_tax_class     -- ����ŋ敪
        , i_xcbs_data_tab( i ).tax_code                  -- �ŋ��R�[�h
        , i_xcbs_data_tab( i ).tax_rate                  -- ����ŗ�
        , i_xcbs_data_tab( i ).term_code                 -- �x������
        , i_xcbs_data_tab( i ).closing_date              -- ���ߓ�
        , i_xcbs_data_tab( i ).expect_payment_date       -- �x���\���
        , i_xcbs_data_tab( i ).calc_target_period_from   -- �v�Z�Ώۊ���(FROM)
        , i_xcbs_data_tab( i ).calc_target_period_to     -- �v�Z�Ώۊ���(TO)
        , i_xcbs_data_tab( i ).cond_bm_interface_status  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
        , i_xcbs_data_tab( i ).cond_bm_interface_date    -- �A�g��(�����ʔ̎�̋�)
        , i_xcbs_data_tab( i ).bm_interface_status       -- �A�g�X�e�[�^�X(�̎�c��)
        , i_xcbs_data_tab( i ).bm_interface_date         -- �A�g��(�̎�c��)
        , i_xcbs_data_tab( i ).ar_interface_status       -- �A�g�X�e�[�^�X(AR)
        , i_xcbs_data_tab( i ).ar_interface_date         -- �A�g��(AR)
        , lv_fix_status                                  -- ���z�m��X�e�[�^�X
        , cn_created_by                                       -- �쐬��
        , SYSDATE                                             -- �쐬��
        , cn_last_updated_by                                  -- �ŏI�X�V��
        , SYSDATE                                             -- �ŏI�X�V��
        , cn_last_update_login                                -- �ŏI�X�V���O�C��
        , cn_request_id                                       -- �v��ID
        , cn_program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                                       -- �R���J�����g�E�v���O����ID
        , SYSDATE                                             -- �v���O�����X�V��
        );
      END IF;
    END LOOP insert_xcbs_loop;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'delivery_cust_code' || '�y' || i_xcbs_data_tab( 1 ).delivery_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : set_xcbs_data
   * Description      : �����ʔ̎�̋����̐ݒ�(A-9)
   ***********************************************************************************/
  PROCEDURE set_xcbs_data(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- �̔����я�񃌃R�[�h
  , o_xcbs_data_tab                OUT xcbs_data_ttype       -- �����ʔ̎�̋����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'set_xcbs_data';    -- �v���O������
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_����
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_����
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_����
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
    ln_bm1_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM1_�����l���z(�Ŕ�)_�ꎞ�i�[
    ln_bm2_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM2_�����l���z(�Ŕ�)_�ꎞ�i�[
    ln_bm3_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM3_�����l���z(�Ŕ�)_�ꎞ�i�[
--
    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)_�ꎞ�i�[
    lv_cond_bm_interface_status    xxcok_cond_bm_support.cond_bm_interface_status%TYPE DEFAULT NULL;
    -- �A�g�X�e�[�^�X(�̎�c��)_�ꎞ�i�[
    lv_bm_interface_status         xxcok_cond_bm_support.bm_interface_status%TYPE      DEFAULT NULL;
    -- �A�g�X�e�[�^�X(AR)_�ꎞ�i�[
    lv_ar_interface_status         xxcok_cond_bm_support.ar_interface_status%TYPE      DEFAULT NULL;
--
    l_xcbs_data_tab                     xcbs_data_ttype;                             -- �����ʔ̎�̋��e�[�u���^�C�v
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ������
    --==================================================
    l_xcbs_data_tab( cn_index_1 ) := NULL;
    l_xcbs_data_tab( cn_index_2 ) := NULL;
    l_xcbs_data_tab( cn_index_3 ) := NULL;
    --==================================================
    -- 1.�̔����я��̋Ƒ�(������)�� '25':�t���T�[�r�XVD�̏ꍇ�AVDBM(�ō�)��ݒ肵�܂��B
    --==================================================
    IF( i_get_sales_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      END IF;
    --==================================================
    -- 2.�̔����я��̋Ƒ�(������)�� '25':�t���T�[�r�XVD�ȊO�̏ꍇ�A�����l���z(�ō�)��ݒ肵�܂��B
    --==================================================
    ELSIF( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 ) THEN
      -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
      -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
      END IF;
--
      -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
      -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
      END IF;
--
      -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
      -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
      END IF;
    END IF;
    --==================================================
    -- 3.�eVDBM(�ō�)�A�����l���z(�ō�)�A�d�C��(�ō�)�� NULL �ȊO�̏ꍇ�A�Ŕ����z����я���Ŋz���Z�o���܂��B
    --==================================================
    -- BM1 VDBM(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM1 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm1_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 )  );
    END IF;
    -- BM1 �d�C��(�Ŕ�)�̐ݒ�
    IF( i_get_sales_data_rec.bm1_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm1_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 VDBM(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm2_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 �d�C��(�Ŕ�)�̐ݒ�
    IF( i_get_sales_data_rec.bm2_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm2_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM3 VDBM(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax
        := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate/ 100 ) );
    END IF;
    -- BM3 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm3_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM3 �d�C��(�Ŕ�)�̐ݒ�
    IF( i_get_sales_data_rec.bm3_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm3_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    --==================================================
    -- �[�������敪�ɂ��擾�l�̒[������
    --==================================================
    -- �̔����я��̒[�������敪�� 'NEAREST':�l�̌ܓ��̏ꍇ�A�����_�ȉ��̒[�����l�̌ܓ����܂��B
    IF( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_nearest ) THEN
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ln_bm1_rcpt_discount_amt_notax                    := ROUND( ln_bm1_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ln_bm2_rcpt_discount_amt_notax                    := ROUND( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ln_bm3_rcpt_discount_amt_notax                    := ROUND( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
    -- �̔����я��̒[�������敪�� 'UP':�؂�グ�̏ꍇ�A�����_�ȉ��̒[����؂�グ���܂��B
    ELSIF ( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_up ) THEN
      IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ELSIF ( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm1_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm1_rcpt_discount_amt_notax  := CEIL( ln_bm1_rcpt_discount_amt_notax );
      ELSIF( ln_bm1_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm1_rcpt_discount_amt_notax  := FLOOR( ln_bm1_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm2_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm2_rcpt_discount_amt_notax  := CEIL( ln_bm2_rcpt_discount_amt_notax );
      ELSIF ( ln_bm2_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm2_rcpt_discount_amt_notax  := FLOOR( ln_bm2_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      END IF;
      IF( ln_bm3_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm3_rcpt_discount_amt_notax  := CEIL( ln_bm3_rcpt_discount_amt_notax );
      ELSIF( ln_bm3_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm3_rcpt_discount_amt_notax  := FLOOR( ln_bm3_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      ELSIF ( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      END IF;
    -- ��L�ȊO�̏ꍇ�A'DOWN':�؂�̂Ă��ݒ肳��Ă��邱�ƂƂ��A�����_�ȉ��̒[����؂�̂Ă��܂��B
    ELSE
      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
      ln_bm1_rcpt_discount_amt_notax                    := TRUNC( ln_bm1_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
      ln_bm2_rcpt_discount_amt_notax                    := TRUNC( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
      ln_bm3_rcpt_discount_amt_notax                    := TRUNC( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
    END IF;
    --==================================================
    -- ����Ŋz�Z�o
    --==================================================
    -- ����Ŋz
    l_xcbs_data_tab( cn_index_1 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax;
    -- �����l������Ŋz
    l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt - ln_bm1_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt - ln_bm2_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt - ln_bm3_rcpt_discount_amt_notax;
    -- �d�C������Ŋz
    l_xcbs_data_tab( cn_index_1 ).electric_tax_amt
      := i_get_sales_data_rec.bm1_electric_amt_tax - l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).electric_tax_amt
      := i_get_sales_data_rec.bm2_electric_amt_tax - l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_tax_amt
      := i_get_sales_data_rec.bm3_electric_amt_tax - l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax;
    --==================================================
    -- 4.�e�A�g�X�e�[�^�X
    --==================================================
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v���Ȃ�
    IF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
        AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- �̎�c��       ������
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v����
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date  = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_no;     -- �����ʔ̎�̋� ������
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- �̎�c��       ������
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�ȊO�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v���Ȃ�
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- �̎�c��       �s�v
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v����
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date   = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- �̎�c��       �s�v
      lv_ar_interface_status      := cv_xcbs_if_status_no;     -- AR             ������
    END IF;
    --==================================================
    -- ���̑��l�ݒ�
    --==================================================
    -- �d����R�[�h
    l_xcbs_data_tab( cn_index_1 ).supplier_code := i_get_sales_data_rec.bm1_vendor_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_code := i_get_sales_data_rec.bm2_vendor_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_code := i_get_sales_data_rec.bm3_vendor_code;
    -- �d����T�C�g�R�[�h
    l_xcbs_data_tab( cn_index_1 ).supplier_site_code := i_get_sales_data_rec.bm1_vendor_site_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_site_code := i_get_sales_data_rec.bm2_vendor_site_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_site_code := i_get_sales_data_rec.bm3_vendor_site_code;
    -- BM��(%)
    l_xcbs_data_tab( cn_index_1 ).rebate_rate := i_get_sales_data_rec.bm1_pct;
    l_xcbs_data_tab( cn_index_2 ).rebate_rate := i_get_sales_data_rec.bm2_pct;
    l_xcbs_data_tab( cn_index_3 ).rebate_rate := i_get_sales_data_rec.bm3_pct;
    -- BM���z
    l_xcbs_data_tab( cn_index_1 ).rebate_amt := i_get_sales_data_rec.bm1_amt;
    l_xcbs_data_tab( cn_index_2 ).rebate_amt := i_get_sales_data_rec.bm2_amt;
    l_xcbs_data_tab( cn_index_3 ).rebate_amt := i_get_sales_data_rec.bm3_amt;
    -- �d�C��(�ō�)
    l_xcbs_data_tab( cn_index_1 ).electric_amt_tax := i_get_sales_data_rec.bm1_electric_amt_tax;
    l_xcbs_data_tab( cn_index_2 ).electric_amt_tax := i_get_sales_data_rec.bm2_electric_amt_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_amt_tax := i_get_sales_data_rec.bm3_electric_amt_tax;
    --==================================================
    -- 5.�擾�������e�������ʔ̎�̋����ɐݒ肵�܂��B
    --==================================================
    << set_xcbs_data_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      -- ���ʍ��ڂ����[�v�Őݒ�
      l_xcbs_data_tab( i ).base_code                 := i_get_sales_data_rec.base_code;                 -- ���_�R�[�h
      l_xcbs_data_tab( i ).emp_code                  := i_get_sales_data_rec.emp_code;                  -- �S���҃R�[�h
      l_xcbs_data_tab( i ).delivery_cust_code        := i_get_sales_data_rec.ship_cust_code;            -- �ڋq�y�[�i��z
      l_xcbs_data_tab( i ).demand_to_cust_code       := i_get_sales_data_rec.bill_cust_code;            -- �ڋq�y������z
      l_xcbs_data_tab( i ).acctg_year                := i_get_sales_data_rec.period_year;               -- ��v�N�x
      l_xcbs_data_tab( i ).chain_store_code          := i_get_sales_data_rec.ship_delivery_chain_code;  -- �`�F�[���X�R�[�h
      l_xcbs_data_tab( i ).calc_type                 := i_get_sales_data_rec.calc_type;                 -- �v�Z����
      l_xcbs_data_tab( i ).delivery_date             := i_get_sales_data_rec.delivery_ym;               -- �[�i���N��
      l_xcbs_data_tab( i ).delivery_qty              := i_get_sales_data_rec.dlv_qty;                   -- �[�i����
      l_xcbs_data_tab( i ).delivery_unit_type        := i_get_sales_data_rec.dlv_uom_code;              -- �[�i�P��
      l_xcbs_data_tab( i ).selling_amt_tax           := i_get_sales_data_rec.amount_inc_tax;            -- ������z(�ō�)
      l_xcbs_data_tab( i ).container_type_code       := i_get_sales_data_rec.container_code;            -- �e��敪�R�[�h
      l_xcbs_data_tab( i ).selling_price             := i_get_sales_data_rec.dlv_unit_price;            -- �������z
      l_xcbs_data_tab( i ).consumption_tax_class     := i_get_sales_data_rec.tax_div;                   -- ����ŋ敪
      l_xcbs_data_tab( i ).tax_code                  := i_get_sales_data_rec.tax_code;                  -- �ŋ��R�[�h
      l_xcbs_data_tab( i ).tax_rate                  := i_get_sales_data_rec.tax_rate;                  -- ����ŗ�
      l_xcbs_data_tab( i ).term_code                 := i_get_sales_data_rec.term_name;                 -- �x������
      l_xcbs_data_tab( i ).closing_date              := i_get_sales_data_rec.closing_date;              -- ���ߓ�
      l_xcbs_data_tab( i ).expect_payment_date       := i_get_sales_data_rec.expect_payment_date;       -- �x���\���
      l_xcbs_data_tab( i ).calc_target_period_from   := i_get_sales_data_rec.calc_target_period_from;   -- �v�Z�Ώۊ���(FROM)
      l_xcbs_data_tab( i ).calc_target_period_to     := i_get_sales_data_rec.calc_target_period_to;     -- �v�Z�Ώۊ���(TO)
      l_xcbs_data_tab( i ).cond_bm_interface_status  := lv_cond_bm_interface_status;                    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
      l_xcbs_data_tab( i ).cond_bm_interface_date    := NULL;                                           -- �A�g��(�����ʔ̎�̋�)
      l_xcbs_data_tab( i ).bm_interface_status       := lv_bm_interface_status;                         -- �A�g�X�e�[�^�X(�̎�c��)
      l_xcbs_data_tab( i ).bm_interface_date         := NULL;                                           -- �A�g��(�̎�c��)
      l_xcbs_data_tab( i ).ar_interface_status       := lv_ar_interface_status;                         -- �A�g�X�e�[�^�X(AR)
      l_xcbs_data_tab( i ).ar_interface_date         := NULL;                                           -- �A�g��(AR)
    END LOOP set_xcbs_data_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    o_xcbs_data_tab := l_xcbs_data_tab;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END set_xcbs_data;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop1
   * Description      : �̔����т̎擾�E�����ʏ���(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop1(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop1';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur1;
    << get_sales_data_loop1 >>
    LOOP
      FETCH get_sales_data_cur1 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur1%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop1;
    CLOSE get_sales_data_cur1;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop1;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop2
   * Description      : �̔����т̎擾�E�e��敪�ʏ���(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop2(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop2';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur2;
    << get_sales_data_loop2 >>
    LOOP
      FETCH get_sales_data_cur2 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur2%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop2;
    CLOSE get_sales_data_cur2;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop2;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop3
   * Description      : �̔����т̎擾�E�ꗥ����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop3(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop3';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur3;
    << get_sales_data_loop3 >>
    LOOP
      FETCH get_sales_data_cur3 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur3%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop3;
    CLOSE get_sales_data_cur3;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop3;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop4
   * Description      : �̔����т̎擾�E��z����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop4(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop4';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur4;
    << get_sales_data_loop4 >>
    LOOP
      FETCH get_sales_data_cur4 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur4%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop4;
    CLOSE get_sales_data_cur4;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop4;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop5
   * Description      : �̔����т̎擾�E�d�C���i�Œ�^�ϓ��j(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop5(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop5';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur5;
    << get_sales_data_loop5 >>
    LOOP
      FETCH get_sales_data_cur5 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur5%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop5;
    CLOSE get_sales_data_cur5;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop5;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop6
   * Description      : �̔����т̎擾�E�����l����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop6(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop6';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur6;
    << get_sales_data_loop6 >>
    LOOP
      FETCH get_sales_data_cur6 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur6%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop6;
    CLOSE get_sales_data_cur6;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || l_get_sales_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop6;
--
  /**********************************************************************************
   * Procedure Name   : delete_xbce
   * Description      : �̎�����G���[�̍폜����(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xbce(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbce';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- ���O�o�͗p�ޔ�����
    lt_cust_code                   xxcok_bm_contract_err.cust_code%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xbce_delete_lock_cur
    IS
      SELECT xbce.cust_code                AS cust_code  -- �ڋq�R�[�h
      FROM xxcok_bm_contract_err      xbce               -- �̎�����G���[�e�[�u��
         , xxcok_tmp_014a01c_custdata xt0c               -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
      WHERE xbce.cust_code  = xt0c.ship_cust_code
      FOR UPDATE OF xbce.cust_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�����G���[�폜���[�v
    --==================================================
    << xbce_delete_lock_loop >>
    FOR xbce_delete_lock_rec IN xbce_delete_lock_cur LOOP
      --==================================================
      -- �̎�����G���[�f�[�^�폜
      --==================================================
      lt_cust_code := xbce_delete_lock_rec.cust_code;
      DELETE
      FROM xxcok_bm_contract_err   xbce
      WHERE xbce.cust_code = xbce_delete_lock_rec.cust_code
      ;
    END LOOP xbce_delete_lock_loop;
    --==================================================
    -- �폜�����̊m��
    --==================================================
    COMMIT;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00080
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'cust_code' || '�y' || lt_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xbce;
--
  /**********************************************************************************
   * Procedure Name   : delete_xcbs
   * Description      : �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j(A-3)
   ***********************************************************************************/
  PROCEDURE delete_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xcbs';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- ���O�o�͗p�ޔ�����
    lt_cond_bm_support_id          xxcok_cond_bm_support.cond_bm_support_id%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbs_delete_lock_cur
    IS
      SELECT xcbs.cond_bm_support_id    AS cond_bm_support_id  -- �����ʔ̎�̋�ID
           , xcbs.delivery_cust_code    AS delivery_cust_code  -- �ڋq�y�[�i��z
           , xcbs.closing_date          AS closing_date        -- ���ߓ�
      FROM xxcok_cond_bm_support      xcbs               -- �����ʔ̎�̋��e�[�u��
         , hz_cust_accounts        hca                -- �ڋq�}�X�^
         , hz_cust_acct_sites_all  hcas               -- �ڋq�T�C�g�}�X�^
         , hz_parties              hp                 -- �p�[�e�B�}�X�^
         , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations            hl                 -- �ڋq���ݒn�}�X�^
         , fnd_lookup_values       flv                -- �̎�̋��v�Z���s�敪
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.lookup_code                  = gv_param_proc_type
        AND flv.language                     = USERENV( 'LANG' )
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND (    ( hl.address3              LIKE flv.attribute1  || '%' AND flv.attribute1  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute2  || '%' AND flv.attribute2  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute3  || '%' AND flv.attribute3  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute4  || '%' AND flv.attribute4  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute5  || '%' AND flv.attribute5  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute6  || '%' AND flv.attribute6  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute7  || '%' AND flv.attribute7  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute8  || '%' AND flv.attribute8  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute9  || '%' AND flv.attribute9  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute10 || '%' AND flv.attribute10 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute11 || '%' AND flv.attribute11 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute12 || '%' AND flv.attribute12 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute13 || '%' AND flv.attribute13 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute14 || '%' AND flv.attribute14 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute15 || '%' AND flv.attribute15 IS NOT NULL )
            )
        AND xcbs.amt_fix_status    = cv_xcbs_temp -- ���m��
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �����ʔ̎�̋��폜���[�v
    --==================================================
    << xcbs_delete_lock_loop >>
    FOR xcbs_delete_lock_rec IN xcbs_delete_lock_cur LOOP
      --==================================================
      -- �����ʔ̎�̋��f�[�^�폜
      --==================================================
      DELETE
      FROM xxcok_cond_bm_support   xcbs
      WHERE xcbs.cond_bm_support_id = xcbs_delete_lock_rec.cond_bm_support_id
      ;
    END LOOP xcbs_delete_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'cond_bm_support_id' || '�y' || lt_cond_bm_support_id || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : insert_xt0c
   * Description      : �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^(A-6)
   ***********************************************************************************/
  PROCEDURE insert_xt0c(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- �ڋq��񃌃R�[�h
  , iv_term_name                   IN  VARCHAR2                   -- �x������
  , id_close_date                  IN  DATE                       -- ���ߓ�
  , id_expect_payment_date         IN  DATE                       -- �x���\���
  , in_period_year                 IN  NUMBER                     -- ��v�N�x
  , id_amount_fix_date             IN  DATE                       -- ���z�m���
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xt0c';      -- �v���O������
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
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- �x���\���
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���\���
    --==================================================
    IF ( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      ld_expect_payment_date := id_expect_payment_date;
    ELSE
      ld_expect_payment_date := id_close_date;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^
    --==================================================
    INSERT INTO xxcok_tmp_014a01c_custdata (
      ship_cust_code              -- �y�o�א�z�ڋq�R�[�h
    , ship_gyotai_tyu             -- �y�o�א�z�Ƒԁi�����ށj
    , ship_gyotai_sho             -- �y�o�א�z�Ƒԁi�����ށj
    , ship_delivery_chain_code    -- �y�o�א�z�[�i��`�F�[���R�[�h
    , bill_cust_code              -- �y������z�ڋq�R�[�h
    , bm1_vendor_code             -- �y�a�l�P�z�d����R�[�h
    , bm1_vendor_site_code        -- �y�a�l�P�z�d����T�C�g�R�[�h
    , bm1_bm_payment_type         -- �y�a�l�P�zBM�x���敪
    , bm2_vendor_code             -- �y�a�l�Q�z�d����R�[�h
    , bm2_vendor_site_code        -- �y�a�l�Q�z�d����T�C�g�R�[�h
    , bm2_bm_payment_type         -- �y�a�l�Q�zBM�x���敪
    , bm3_vendor_code             -- �y�a�l�R�z�d����R�[�h
    , bm3_vendor_site_code        -- �y�a�l�R�z�d����T�C�g�R�[�h
    , bm3_bm_payment_type         -- �y�a�l�R�zBM�x���敪
    , tax_div                     -- ����ŋ敪
    , tax_code                    -- �ŋ��R�[�h
    , tax_rate                    -- �ŗ�
    , tax_rounding_rule           -- �[�������敪
    , receiv_discount_rate        -- �����l����
    , term_name                   -- �x������
    , closing_date                -- ���ߓ�
    , expect_payment_date         -- �x���\���
    , period_year                 -- ��v�N�x
    , calc_target_period_from     -- �v�Z�Ώۊ���(FROM)
    , calc_target_period_to       -- �v�Z�Ώۊ���(TO)
    , amount_fix_date             -- ���z�m���
    )
    VALUES (
      i_get_cust_data_rec.ship_cust_code             -- �y�o�א�z�ڋq�R�[�h
    , i_get_cust_data_rec.ship_gyotai_tyu            -- �y�o�א�z�Ƒԁi�����ށj
    , i_get_cust_data_rec.ship_gyotai_sho            -- �y�o�א�z�Ƒԁi�����ށj
    , i_get_cust_data_rec.ship_delivery_chain_code   -- �y�o�א�z�[�i��`�F�[���R�[�h
    , i_get_cust_data_rec.bill_cust_code             -- �y������z�ڋq�R�[�h
    , i_get_cust_data_rec.bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
    , i_get_cust_data_rec.bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
    , i_get_cust_data_rec.bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
    , i_get_cust_data_rec.bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
    , i_get_cust_data_rec.bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
    , i_get_cust_data_rec.bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
    , i_get_cust_data_rec.tax_div                    -- ����ŋ敪
    , i_get_cust_data_rec.tax_code                   -- �ŋ��R�[�h
    , i_get_cust_data_rec.tax_rate                   -- �ŗ�
    , i_get_cust_data_rec.tax_rounding_rule          -- �[�������敪
    , i_get_cust_data_rec.receiv_discount_rate       -- �����l����
    , iv_term_name                                   -- �x������
    , id_close_date                                  -- ���ߓ�
    , ld_expect_payment_date                         -- �x���\���
    , in_period_year                                 -- ��v�N�x
    , i_get_cust_data_rec.calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
    , id_close_date                                  -- �v�Z�Ώۊ���(TO)
    , id_amount_fix_date                             -- ���z�m���
    );
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xt0c;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_subdata
   * Description      : �����ʔ̎�̋��v�Z���t���̓��o(A-5)
   ***********************************************************************************/
  PROCEDURE get_cust_subdata(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- �ڋq��񃌃R�[�h
  , ov_term_name                   OUT VARCHAR2                   -- �x������
  , od_close_date                  OUT DATE                       -- ���ߓ�
  , od_expect_payment_date         OUT DATE                       -- �x���\���
  , od_bm_support_period_from      OUT DATE                       -- �����ʔ̎�̋��v�Z�J�n��
  , od_bm_support_period_to        OUT DATE                       -- �����ʔ̎�̋��v�Z�I����
  , on_period_year                 OUT NUMBER                     -- ��v�N�x
  , od_amount_fix_date             OUT DATE                       -- ���z�m���
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_cust_subdata';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_tmp_bm_support_period_from  DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��(��)
    ld_tmp_bm_support_period_to    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����(��)
    ld_close_date1                 DATE           DEFAULT NULL;                 -- ���ߓ��i�x�������j
    ld_pay_date1                   DATE           DEFAULT NULL;                 -- �x�����i�x�������j
    ld_expect_payment_date1        DATE           DEFAULT NULL;                 -- �x���\����i�x�������j
    ld_close_date2                 DATE           DEFAULT NULL;                 -- ���ߓ��i��2�x�������j
    ld_pay_date2                   DATE           DEFAULT NULL;                 -- �x�����i��2�x�������j
    ld_expect_payment_date2        DATE           DEFAULT NULL;                 -- �x���\����i��2�x�������j
    ld_close_date3                 DATE           DEFAULT NULL;                 -- ���ߓ��i��3�x�������j
    ld_pay_date3                   DATE           DEFAULT NULL;                 -- �x�����i��3�x�������j
    ld_expect_payment_date3        DATE           DEFAULT NULL;                 -- �x���\����i��3�x�������j
    ld_bm_support_period_from_1    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i�x�������j
    ld_bm_support_period_to_1      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i�x�������j
    ld_bm_support_period_from_2    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i��2�x�������j
    ld_bm_support_period_to_2      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i��2�x�������j
    ld_bm_support_period_from_3    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i��3�x�������j
    ld_bm_support_period_to_3      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i��3�x�������j
    lv_fix_term_name               VARCHAR2(10)   DEFAULT NULL;                 -- �x������
    ld_fix_close_date              DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_fix_expect_payment_date     DATE           DEFAULT NULL;                 -- �x���\���
    ld_fix_bm_support_period_from  DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��
    ld_fix_bm_support_period_to    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- ��v�N�x
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- ���z�m���
    lv_period_name                 gl_periods.period_name%TYPE DEFAULT NULL;    -- ��v���Ԗ�
    lv_closing_status              gl_period_statuses.closing_status%TYPE DEFAULT NULL;                 -- �X�e�[�^�X
    --==================================================
    -- ���[�J����O
    --==================================================
    skip_proc_expt                 EXCEPTION; -- �v�Z�ΏۊO�X�L�b�v
    get_close_date_expt            EXCEPTION; -- ���߁E�x�����擾�֐��G���[
    get_operating_day_expt         EXCEPTION; -- �c�Ɠ��擾�֐��G���[
    get_acctg_calendar_expt        EXCEPTION; -- ��v�J�����_�擾�֐��G���[
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �����ʔ̎�̋��v�Z�J�n��(��)�擾
    --==================================================
    IF( i_get_cust_data_rec.settle_amount_cycle IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    ld_tmp_bm_support_period_from :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => gd_process_date                               -- IN DATE   ������
      , in_days                  => -1 * i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
      , in_proc_type             => cn_proc_type_before                           -- IN NUMBER �����敪
      );
    IF( ld_tmp_bm_support_period_from IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- �x������
    --==================================================
    IF( i_get_cust_data_rec.term_name1 IS NOT NULL ) THEN
      --==================================================
      -- ���ߎx�����擾�i�x�������j
      --==================================================
      xxcok_common_pkg.get_close_date_p(
        ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
      , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
      , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
      , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
      , iv_pay_cond                => i_get_cust_data_rec.term_name1    -- IN  VARCHAR2          �x������(IN)
      , od_close_date              => ld_close_date1                    -- OUT DATE              ���ߓ�(OUT)
      , od_pay_date                => ld_pay_date1                      -- OUT DATE              �x����(OUT)
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_close_date_expt;
      END IF;
      --==================================================
      -- �x���\����擾�i�x�������j
      --==================================================
      ld_expect_payment_date1 :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_pay_date1                             -- IN DATE   ������
        , in_days                  => 0                                        -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_expect_payment_date1 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    END IF;
    --==================================================
    -- ��2�x������
    --==================================================
    IF( i_get_cust_data_rec.term_name2 IS NOT NULL ) THEN
      --==================================================
      -- ���ߎx�����擾�i��2�x�������j
      --==================================================
      xxcok_common_pkg.get_close_date_p(
        ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
      , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
      , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
      , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
      , iv_pay_cond                => i_get_cust_data_rec.term_name2    -- IN  VARCHAR2          �x������(IN)
      , od_close_date              => ld_close_date2                    -- OUT DATE              ���ߓ�(OUT)
      , od_pay_date                => ld_pay_date2                      -- OUT DATE              �x����(OUT)
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_close_date_expt;
      END IF;
      --==================================================
      -- �x���\����擾�i��2�x�������j
      --==================================================
      ld_expect_payment_date2 :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_pay_date2                             -- IN DATE   ������
        , in_days                  => 0                                        -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_expect_payment_date2 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    END IF;
    --==================================================
    -- ��3�x������
    --==================================================
    IF( i_get_cust_data_rec.term_name3 IS NOT NULL ) THEN
      --==================================================
      -- ���ߎx�����擾�i��3�x�������j
      --==================================================
      xxcok_common_pkg.get_close_date_p(
        ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
      , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
      , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
      , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
      , iv_pay_cond                => i_get_cust_data_rec.term_name3    -- IN  VARCHAR2          �x������(IN)
      , od_close_date              => ld_close_date3                    -- OUT DATE              ���ߓ�(OUT)
      , od_pay_date                => ld_pay_date3                      -- OUT DATE              �x����(OUT)
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_close_date_expt;
      END IF;
      --==================================================
      -- �x���\����擾�i��3�x�������j
      --==================================================
      ld_expect_payment_date3 :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_pay_date3                             -- IN DATE   ������
        , in_days                  => 0                                        -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_expect_payment_date3 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��v�Z�J�n�E�I��������i�x�������j
    --==================================================
    IF( i_get_cust_data_rec.term_name1 = gv_instantly_term_name ) THEN
      ld_bm_support_period_from_1 := gd_process_date;
      ld_bm_support_period_to_1   := gd_process_date;
      ld_close_date1              := gd_process_date;
    ELSIF( i_get_cust_data_rec.term_name1 IS NOT NULL ) THEN
      ld_bm_support_period_from_1 :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date1                           -- IN DATE   ������
        , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_from_1 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      ld_bm_support_period_to_1   :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date1                           -- IN DATE   ������
        , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_to_1 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    ELSE
      ld_bm_support_period_from_1 := NULL;
      ld_bm_support_period_to_1   := NULL;
    END IF;
    IF(     ( i_get_cust_data_rec.term_name1      <> gv_instantly_term_name )
        AND ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd       )
    ) THEN
      ld_bm_support_period_from_1 := ld_bm_support_period_to_1;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��v�Z�J�n�E�I��������i��2�x�������j
    --==================================================
    IF( i_get_cust_data_rec.term_name2 = gv_instantly_term_name ) THEN
      ld_bm_support_period_from_2 := gd_process_date;
      ld_bm_support_period_to_2   := gd_process_date;
      ld_close_date2              := gd_process_date;
    ELSIF( i_get_cust_data_rec.term_name2 IS NOT NULL ) THEN
      ld_bm_support_period_from_2 := 
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date2                           -- IN DATE   ������
        , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_from_2 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      ld_bm_support_period_to_2   :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date2                           -- IN DATE   ������
        , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_to_2 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    ELSE
      ld_bm_support_period_from_2 := NULL;
      ld_bm_support_period_to_2   := NULL;
    END IF;
    IF(     ( i_get_cust_data_rec.term_name2      <> gv_instantly_term_name )
        AND ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd       )
    ) THEN
      ld_bm_support_period_from_2 := ld_bm_support_period_to_2;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��v�Z�J�n�E�I��������i��3�x�������j
    --==================================================
    IF( i_get_cust_data_rec.term_name3 = gv_instantly_term_name ) THEN
      ld_bm_support_period_from_3 := gd_process_date;
      ld_bm_support_period_to_3   := gd_process_date;
      ld_close_date3              := gd_process_date;
    ELSIF( i_get_cust_data_rec.term_name3 IS NOT NULL ) THEN
      ld_bm_support_period_from_3 := 
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date3                           -- IN DATE   ������
        , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_from_3 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      ld_bm_support_period_to_3   :=
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_close_date3                           -- IN DATE   ������
        , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_bm_support_period_to_3 IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    ELSE
      ld_bm_support_period_from_3 := NULL;
      ld_bm_support_period_to_3   := NULL;
    END IF;
    IF(     ( i_get_cust_data_rec.term_name3      <> gv_instantly_term_name )
        AND ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd       )
    ) THEN
      ld_bm_support_period_from_3 := ld_bm_support_period_to_3;
    END IF;
    --==================================================
    -- �x����������
    --==================================================
fnd_file.put_line( FND_FILE.LOG,'' || '===============================================' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'ship_cust_code            ' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'term_name1                ' || '�y' || i_get_cust_data_rec.term_name1     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'term_name2                ' || '�y' || i_get_cust_data_rec.term_name2     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'term_name3                ' || '�y' || i_get_cust_data_rec.term_name3     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'close_date1               ' || '�y' || ld_close_date1                     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'close_date2               ' || '�y' || ld_close_date2                     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'close_date3               ' || '�y' || ld_close_date3                     || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_from_1  ' || '�y' || ld_bm_support_period_from_1        || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_to_1    ' || '�y' || ld_bm_support_period_to_1          || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_from_2  ' || '�y' || ld_bm_support_period_from_2        || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_to_2    ' || '�y' || ld_bm_support_period_to_2          || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_from_3  ' || '�y' || ld_bm_support_period_from_3        || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'bm_support_period_to_3    ' || '�y' || ld_bm_support_period_to_3          || '�z' ); -- debug
fnd_file.put_line( FND_FILE.LOG,'' || '===============================================' ); -- debug
    IF( i_get_cust_data_rec.term_name1 = gv_instantly_term_name ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name1;
      ld_fix_close_date             := gd_process_date;
      ld_fix_expect_payment_date    := gd_process_date;
      ld_fix_bm_support_period_from := gd_process_date;
      ld_fix_bm_support_period_to   := gd_process_date;
    ELSIF( i_get_cust_data_rec.term_name2 = gv_instantly_term_name ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name2;
      ld_fix_close_date             := gd_process_date;
      ld_fix_expect_payment_date    := gd_process_date;
      ld_fix_bm_support_period_from := gd_process_date;
      ld_fix_bm_support_period_to   := gd_process_date;
    ELSIF( i_get_cust_data_rec.term_name3 = gv_instantly_term_name ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name3;
      ld_fix_close_date             := gd_process_date;
      ld_fix_expect_payment_date    := gd_process_date;
      ld_fix_bm_support_period_from := gd_process_date;
      ld_fix_bm_support_period_to   := gd_process_date;
    ELSIF( gd_process_date BETWEEN ld_bm_support_period_from_1
                               AND ld_bm_support_period_to_1  ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name1;
      ld_fix_close_date             := ld_close_date1;
      ld_fix_expect_payment_date    := ld_pay_date1;
      ld_fix_bm_support_period_from := ld_bm_support_period_from_1;
      ld_fix_bm_support_period_to   := ld_bm_support_period_to_1;
    ELSIF( gd_process_date BETWEEN ld_bm_support_period_from_2
                               AND ld_bm_support_period_to_2  ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name2;
      ld_fix_close_date             := ld_close_date2;
      ld_fix_expect_payment_date    := ld_pay_date2;
      ld_fix_bm_support_period_from := ld_bm_support_period_from_2;
      ld_fix_bm_support_period_to   := ld_bm_support_period_to_2;
    ELSIF( gd_process_date BETWEEN ld_bm_support_period_from_3
                               AND ld_bm_support_period_to_3  ) THEN
      lv_fix_term_name              := i_get_cust_data_rec.term_name3;
      ld_fix_close_date             := ld_close_date3;
      ld_fix_expect_payment_date    := ld_pay_date3;
      ld_fix_bm_support_period_from := ld_bm_support_period_from_3;
      ld_fix_bm_support_period_to   := ld_bm_support_period_to_3;
    ELSE
      lv_fix_term_name              := NULL;
      ld_fix_close_date             := NULL;
      ld_fix_expect_payment_date    := NULL;
      ld_fix_bm_support_period_from := NULL;
      ld_fix_bm_support_period_to   := NULL;
      RAISE skip_proc_expt;
    END IF;
    --==================================================
    -- ���z�m����擾
    --==================================================
    IF( lv_fix_term_name = gv_instantly_term_name ) THEN
      ld_amount_fix_date := ld_fix_close_date;
    ELSIF( lv_fix_term_name <> gv_instantly_term_name ) THEN
      ld_amount_fix_date := 
        xxcok_common_pkg.get_operating_day_f(
          id_proc_date             => ld_fix_close_date                        -- IN DATE   ������
        , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
        );
      IF( ld_amount_fix_date IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
    ELSE
      ld_amount_fix_date := NULL;
    END IF;
    --==================================================
    -- ��v���Ԏ擾
    --==================================================
    IF( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     �G���[�o�b�t�@
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     ���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     �G���[���b�Z�[�W
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       ��v����ID
      , iv_application_short_name => cv_appl_short_name_gl            -- IN  VARCHAR2     �A�v���P�[�V�����Z�k��
      , id_object_date            => ld_fix_expect_payment_date       -- IN  DATE         �Ώۓ�
      , on_period_year            => ln_period_year                   -- OUT NUMBER       ��v�N�x
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     ��v���Ԗ�
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     �X�e�[�^�X
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    ELSE
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     �G���[�o�b�t�@
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     ���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     �G���[���b�Z�[�W
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       ��v����ID
      , iv_application_short_name => cv_appl_short_name_ar            -- IN  VARCHAR2     �A�v���P�[�V�����Z�k��
      , id_object_date            => ld_fix_close_date                -- IN  DATE         �Ώۓ�
      , on_period_year            => ln_period_year                   -- OUT NUMBER       ��v�N�x
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     ��v���Ԗ�
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     �X�e�[�^�X
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_term_name              := lv_fix_term_name;
    od_close_date             := ld_fix_close_date;
    od_expect_payment_date    := ld_fix_expect_payment_date;
    od_bm_support_period_from := ld_fix_bm_support_period_from;
    od_bm_support_period_to   := ld_fix_bm_support_period_to;
    on_period_year            := ln_period_year;
    od_amount_fix_date        := ld_amount_fix_date;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �v�Z�ΏۊO�X�L�b�v ***
    WHEN skip_proc_expt THEN
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
      ov_retcode := cv_status_normal;
    -- *** ���߁E�x�����擾�֐��G���[ ***
    WHEN get_close_date_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10454
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** �c�Ɠ��擾�֐��G���[ ***
    WHEN get_operating_day_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10455
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** ��v�J�����_�擾�֐��G���[ ***
    WHEN get_acctg_calendar_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10456
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    , iv_token_name2          => cv_tkn_proc_date
                    , iv_token_value2         => ld_fix_expect_payment_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** ���������ʗ�O ***
    WHEN global_process_expt THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || i_get_cust_data_rec.ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_subdata;
--
  /**********************************************************************************
   * Procedure Name   : cust_loop
   * Description      : �ڋq��񃋁[�v(A-4)
   ***********************************************************************************/
  PROCEDURE cust_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'cust_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_term_name                   VARCHAR2(5000) DEFAULT NULL;                 -- �x������
    ld_close_date                  DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- �x���\���
    ld_bm_support_period_from      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��
    ld_bm_support_period_to        DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- ��v�N�x
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- ���z�m���
    -- �u���C�N����
    lv_pre_bill_cust_code          hz_cust_accounts.account_number      %TYPE DEFAULT NULL; -- �O���R�[�h�y������z�ڋq�R�[�h�ޔ�
    lv_pre_ship_gyotai_sho         xxcmm_cust_accounts.business_low_type%TYPE DEFAULT NULL; -- �O���R�[�h�y�o�א�z�Ƒԁi�����ށj�ޔ�
    -- ���O�o�͗p�ޔ�����
    lt_ship_cust_code              hz_cust_accounts.account_number      %TYPE DEFAULT NULL;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    << cust_data_loop >>
    FOR get_cust_data_rec IN get_cust_data_cur LOOP
      lt_ship_cust_code := get_cust_data_rec.ship_cust_code;
      gn_target_cnt := gn_target_cnt + 1;
      DECLARE
        normal_skip_expt           EXCEPTION; -- �����X�L�b�v
      BEGIN
        --==================================================
        -- �����ʔ̎�̋��v�Z���t���̓��o
        --==================================================
        IF(    ( lv_pre_bill_cust_code  IS NULL                              )
            OR ( lv_pre_ship_gyotai_sho IS NULL                              )
            OR ( lv_pre_bill_cust_code  <> get_cust_data_rec.bill_cust_code  )
            OR ( lv_pre_ship_gyotai_sho <> get_cust_data_rec.ship_gyotai_sho )
        ) THEN
          get_cust_subdata(
            ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_get_cust_data_rec         => get_cust_data_rec          -- �ڋq��񃌃R�[�h
          , ov_term_name                => lv_term_name               -- �x������
          , od_close_date               => ld_close_date              -- ���ߓ�
          , od_expect_payment_date      => ld_expect_payment_date     -- �x���\���
          , od_bm_support_period_from   => ld_bm_support_period_from  -- �����ʔ̎�̋��v�Z�J�n��
          , od_bm_support_period_to     => ld_bm_support_period_to    -- �����ʔ̎�̋��v�Z�I����
          , on_period_year              => ln_period_year             -- ��v�N�x
          , od_amount_fix_date          => ld_amount_fix_date         -- ���z�m���
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            --==================================================
            -- �u���C�N������NULL��ݒ�
            -- �i�G���[�����������ꍇ�͎��̃��R�[�h�ŕK�����s����j
            --==================================================
            lv_pre_bill_cust_code  := NULL;
            lv_pre_ship_gyotai_sho := NULL;
            RAISE warning_skip_expt;
          ELSE
            --==================================================
            -- �u���C�N�����ޔ�
            --==================================================
            lv_pre_bill_cust_code  := get_cust_data_rec.bill_cust_code;
            lv_pre_ship_gyotai_sho := get_cust_data_rec.ship_gyotai_sho;
          END IF;
        END IF;
        --==================================================
        -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^
        --==================================================
        IF( gd_process_date BETWEEN ld_bm_support_period_from AND ld_bm_support_period_to ) THEN
          insert_xt0c(
            ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_get_cust_data_rec         => get_cust_data_rec          -- �ڋq��񃌃R�[�h
          , iv_term_name                => lv_term_name               -- �x������
          , id_close_date               => ld_close_date              -- ���ߓ�
          , id_expect_payment_date      => ld_expect_payment_date     -- �x���\���
          , in_period_year              => ln_period_year             -- ��v�N�x
          , id_amount_fix_date          => ld_amount_fix_date         -- ���z�m���
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE warning_skip_expt;
          END IF;
        ELSE
          RAISE normal_skip_expt;
        END IF;
        --==================================================
        -- ���팏���J�E���g
        --==================================================
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN normal_skip_expt THEN
          --==================================================
          -- �X�L�b�v�����J�E���g
          --==================================================
          gn_skip_cnt := gn_skip_cnt + 1;
        WHEN warning_skip_expt THEN
          --==================================================
          -- �ُ팏���J�E���g
          --==================================================
          gn_error_cnt := gn_error_cnt + 1;
          --==================================================
          -- �X�e�[�^�X�ݒ�
          --==================================================
          lv_end_retcode := cv_status_warn;
      END;
    END LOOP cust_data_loop;
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
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'ship_cust_code' || '�y' || lt_ship_cust_code || '�z' ); -- debug
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END cust_loop;
--
  /**********************************************************************************
   * Procedure Name   : purge_xcbs
   * Description      : �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j(A-2)
   ***********************************************************************************/
  PROCEDURE purge_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xcbs';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_start_date                  DATE           DEFAULT NULL;                 -- �Ɩ���������
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbs_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT xcbs.cond_bm_support_id    AS cond_bm_support_id
      FROM xxcok_cond_bm_support   xcbs               -- �����ʔ̎�̋��e�[�u��
         , hz_cust_accounts        hca                -- �ڋq�}�X�^
         , hz_cust_acct_sites_all  hcas               -- �ڋq�T�C�g�}�X�^
         , hz_parties              hp                 -- �p�[�e�B�}�X�^
         , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations            hl                 -- �ڋq���ݒn�}�X�^
         , fnd_lookup_values       flv                -- �̎�̋��v�Z���s�敪
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.lookup_code                  = gv_param_proc_type
        AND flv.language                     = USERENV( 'LANG' )
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND (    ( hl.address3              LIKE flv.attribute1  || '%' AND flv.attribute1  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute2  || '%' AND flv.attribute2  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute3  || '%' AND flv.attribute3  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute4  || '%' AND flv.attribute4  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute5  || '%' AND flv.attribute5  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute6  || '%' AND flv.attribute6  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute7  || '%' AND flv.attribute7  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute8  || '%' AND flv.attribute8  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute9  || '%' AND flv.attribute9  IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute10 || '%' AND flv.attribute10 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute11 || '%' AND flv.attribute11 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute12 || '%' AND flv.attribute12 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute13 || '%' AND flv.attribute13 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute14 || '%' AND flv.attribute14 IS NOT NULL )
              OR ( hl.address3              LIKE flv.attribute15 || '%' AND flv.attribute15 IS NOT NULL )
            )
        AND xcbs.closing_date                < id_target_date
        AND xcbs.cond_bm_interface_status   <> cv_xcbs_if_status_no
        AND xcbs.bm_interface_status        <> cv_xcbs_if_status_no
        AND xcbs.ar_interface_status        <> cv_xcbs_if_status_no
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_backmargin_balance      xbb
                         WHERE xbb.base_code                = xcbs.base_code
                           AND xbb.cust_code                = xcbs.delivery_cust_code
                           AND xbb.supplier_code            = xcbs.supplier_code
                           AND xbb.supplier_site_code       = xcbs.supplier_site_code
                           AND xbb.closing_date             = xcbs.closing_date
                           AND xbb.expect_payment_date      = xcbs.expect_payment_date
            )
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �������擾
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- �����ʔ̎�̋��폜���[�v
    --==================================================
    << xcbs_parge_lock_loop >>
    FOR xcbs_parge_lock_rec IN xcbs_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- �����ʔ̎�̋��f�[�^�폜
      --==================================================
      BEGIN
        DELETE
        FROM xxcok_cond_bm_support   xcbs
        WHERE xcbs.cond_bm_support_id = xcbs_parge_lock_rec.cond_bm_support_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10398
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
      END;
    END LOOP xcbs_parge_lock_loop;
    --==================================================
    -- �p�[�W�����̊m��
    --==================================================
    COMMIT;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
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
  END purge_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
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
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �Ɩ����t
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00022
                  , iv_token_name1          => cv_tkn_business_date
                  , iv_token_value1         => iv_proc_date
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
    -- �����敪
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00044
                  , iv_token_name1          => cv_tkn_proc_type
                  , iv_token_value1         => iv_proc_type
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg          -- ���b�Z�[�W
                  , in_new_line             => 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
    --==================================================
    -- �v���O�������͍��ڂ��O���[�o���ϐ��֊i�[
    --==================================================
    gv_param_proc_date := iv_proc_date;
    gv_param_proc_type := iv_proc_type;
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    IF( gv_param_proc_date IS NOT NULL ) THEN
      gd_process_date := TO_DATE( gv_param_proc_date, cv_format_fxrrrrmmdd );
    ELSE
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
    END IF;
    --==================================================
    -- �v���t�@�C���擾(MO: �c�ƒP��)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_org_id IS NULL ) THEN
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
    -- �v���t�@�C���擾(��v����ID)
    --==================================================
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_set_of_books_id IS NULL ) THEN
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
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiFrom�j)
    --==================================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
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
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiTo�j)
    --==================================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_04 ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
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
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋����ێ�����)
    --==================================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_05 ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d�C���i�ϓ��j�i�ڃR�[�h)
    --==================================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gv_elec_change_item_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d����_�~�[�R�[�h)
    --==================================================
    gv_vendor_dummy_code := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gv_vendor_dummy_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x������_��������)
    --==================================================
    gv_instantly_term_name := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gv_instantly_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x������_�f�t�H���g)
    --==================================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gv_default_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
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
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
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
    , iv_proc_date            => iv_proc_date          -- �Ɩ����t
    , iv_proc_type            => iv_proc_type          -- �����敪
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j(A-2)
    --==================================================
    purge_xcbs(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j(A-3)
    --==================================================
    delete_xcbs(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �ڋq��񃋁[�v(A-4)
    --==================================================
    cust_loop(
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
    -- �̎�����G���[�̍폜����(A-7)
    --==================================================
    delete_xbce(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop1(
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
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop2(
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
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop3(
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
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop4(
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
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop5(
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
    -- �̔����у��[�v(A-8)
    --==================================================
    sales_result_loop6(
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
    -- �̔����јA�g���ʂ̍X�V(A-12)
    --==================================================
    update_xsel(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
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
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
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
    , iv_proc_date            => iv_proc_date          -- �Ɩ����t
    , iv_proc_type            => iv_proc_type          -- ���s�敪
    );
    --==================================================
    -- �̎�����G���[���b�Z�[�W�o��
    --==================================================
    IF( gn_contract_err_cnt > 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application           => cv_appl_short_name_cok
                    , iv_name                  => cv_msg_cok_10401
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT
                    , iv_message               => lv_outmsg
                    , in_new_line              => 1
                    );
    END IF;
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
END XXCOK014A01C;
/
