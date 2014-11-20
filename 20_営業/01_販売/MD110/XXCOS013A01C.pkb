CREATE OR REPLACE PACKAGE BODY XXCOS013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A01C (body)
 * Description      : �̔����я����d������쐬���AAR��������ɘA�g���鏈��
 * MD.050           : AR�ւ̔̔����уf�[�^�A�g MD050_COS_013_A01
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �̔����уf�[�^�擾(A-2)
 *  edit_sum_data          ��������W�񏈗��i����ʔ̓X�j(A-3)
 *  edit_dis_data          AR��v�z���d��쐬�i����ʔ̓X�j(A-4)
 *  edit_sum_bulk_data     AR����������W�񏈗��i���ʔ̓X�j(A-5)
 *  edit_dis_bulk_data     AR��v�z���d��쐬�i���ʔ̓X�j(A-6)
 *  insert_aroif_data      AR�������OIF�o�^����(A-7)
 *  insert_ardis_data      AR��v�z��OIF�o�^����(A-8)
 *  upd_data               �̔����уw�b�_�X�V����(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-10���܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2009/01/14    1.0   R.HAN            �V�K�쐬
 *  2009/02/17    1.1   R.HAN            get_msg�̃p�b�P�[�W���C��
 *  2009/02/23    1.2   R.HAN            �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/23    1.3   R.HAN            �ŃR�[�h�̌���������ǉ�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  ###############################
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--#######################  �Œ�O���[�o���萔�錾�� END   ################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START ################################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--#######################  �Œ�O���[�o���ϐ��錾�� END   ###############################
--
--##########################  �Œ苤�ʗ�O�錾�� START  #################################
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
--##########################  �Œ苤�ʗ�O�錾�� END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);       -- ���b�N�G���[
  global_proc_date_err_expt EXCEPTION;         -- �Ɩ����t�擾��O
  global_select_data_expt   EXCEPTION;         -- �f�[�^�擾��O
  global_insert_data_expt   EXCEPTION;         -- �o�^������O
  global_update_data_expt   EXCEPTION;         -- �X�V������O
  global_get_profile_expt   EXCEPTION;         -- �v���t�@�C���擾��O
  global_no_data_expt       EXCEPTION;         -- �Ώۃf�[�^�O���G���[
  global_no_lookup_expt     EXCEPTION;         -- LOOKUP�擾�G���[
  global_term_id_expt       EXCEPTION;         -- �x������ID�擾�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- ���ʗ̈�Z�k�A�v����
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- �̕��A�v���P�[�V�����Z�k��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A01C';     -- �p�b�P�[�W��
  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ���b�N�G���[���b�Z�[�W�i�̔�����TB�j
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_pro_mo_org_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047'; -- �c�ƒP�ʎ擾�G���[
--
  cv_tkn_sales_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12751'; -- �̔����уw�b�_
  cv_tkn_aroif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12752'; -- AR�������OIF
  cv_tkn_ardis_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12753'; -- AR��v�z��OIF
  cv_sales_nm_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12754'; -- �̔�����
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12755'; -- ��v����ID
  cv_pro_org_cd             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12756'; -- �݌ɑg�D�R�[�h
  cv_org_id_get_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12757'; -- �݌ɑg�DID
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12758'; -- ��ЃR�[�h
  cv_var_elec_item_cd       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12759'; -- �ϓ��d�C��(�i�ڃR�[�h)
  cv_busi_dept_cd           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12760'; -- �Ɩ��Ǘ���
  cv_busi_emp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12761'; -- �Ɩ��Ǘ����S����
  cv_card_sale_cls_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12762'; -- �J�[�h����敪�擾�G���[
  cv_tax_cls_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12763'; -- ����ŋ敪�擾�G���[
  cv_cust_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12764'; -- �ڋq�敪�擾�G���[
  cv_gyotai_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12765'; -- �Ƒԏ����ގ擾�G���[
  cv_trxtype_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12766'; -- ����^�C�v�擾�G���[
  cv_itemdesp_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12767'; -- AR�i�ږ��דE�v�擾�G���[
  cv_tkn_ccid_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12768'; -- ����Ȗڑg�����}�X�^
  cv_ccid_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12769'; -- CCID�擾�o���Ȃ��G���[
  cv_dis_item_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12770'; -- ����l���i��
  cv_jour_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12771'; -- �d��p�^�[���擾�G���[
  cv_tax_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12772'; -- �������œ�(����Ȗڗp)
  cv_goods_msg              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12773'; -- ���i���㍂(����Ȗڗp)
  cv_prod_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12774'; -- ���i���㍂(����Ȗڗp)
  cv_disc_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12775'; -- ����l��(����Ȗڗp)
  cv_success_aroif_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12776'; -- AR�������OIF�����������b�Z�[�W
  cv_success_ardis_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12777'; -- AR��v�z��OIF�����������b�Z�[�W
  cv_term_id_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12778'; -- �x������ID�擾�G���[
  cv_tax_in_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12779'; -- ���ŃR�[�h�擾�G���[
  cv_tax_out_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12780'; -- �O�ŃR�[�h�擾�G���[
--
  -- �g�[�N��
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';         -- �v���t�@�C��
  cv_tkn_tbl                CONSTANT  VARCHAR2(20) := 'TABLE';           -- �e�[�u������
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';      -- �e�[�u������
  cv_tkn_lookup_type        CONSTANT  VARCHAR2(20) := 'LOOKUP_TYPE';     -- �Q�ƃ^�C�v
  cv_tkn_lookup_code        CONSTANT  VARCHAR2(20) := 'LOOKUP_CODE';     -- �N�C�b�N�R�[�h
  cv_tkn_lookup_dff2        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE2';      -- �Q�ƃ^�C�v��DFF2
  cv_tkn_lookup_dff3        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE3';      -- �Q�ƃ^�C�v��DFF3
  cv_tkn_lookup_dff4        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE4';      -- �Q�ƃ^�C�v��DFF4
  cv_tkn_lookup_dff5        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE5';      -- �Q�ƃ^�C�v��DFF5
  cv_tkn_segment1           CONSTANT  VARCHAR2(20) := 'SEGMENT1';        -- ��ЃR�[�h
  cv_tkn_segment2           CONSTANT  VARCHAR2(20) := 'SEGMENT2';        -- ����R�[�h
  cv_tkn_segment3           CONSTANT  VARCHAR2(20) := 'SEGMENT3';        -- ����ȖڃR�[�h
  cv_tkn_segment4           CONSTANT  VARCHAR2(20) := 'SEGMENT4';        -- �⏕�ȖڃR�[�h
  cv_tkn_segment5           CONSTANT  VARCHAR2(20) := 'SEGMENT5';        -- �ڋq�R�[�h
  cv_tkn_segment6           CONSTANT  VARCHAR2(20) := 'SEGMENT6';        -- ��ƃR�[�h
  cv_tkn_segment7           CONSTANT  VARCHAR2(20) := 'SEGMENT7';        -- ���Ƌ敪�R�[�h
  cv_tkn_segment8           CONSTANT  VARCHAR2(20) := 'SEGMENT8';        -- �\��
  cv_blank                  CONSTANT  VARCHAR2(1)  := '';                -- �u�����N
  cv_and                    CONSTANT  VARCHAR2(6)  := ' AND ';           -- �u�����N
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';        -- �L�[����
--
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- �t���O�l:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- �t���O�l:N
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- �J�[�h����敪�F�J�[�h= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- �J�[�h����敪�F����= 0
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qct_card_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';         -- �J�[�h���敪����}�X�^
  cv_qct_gyotai_sho         CONSTANT  VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_013_A01';  -- �Ƒԏ����ޓ���}�X�^
  cv_qct_sale_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_SALE_CLASS_MST_013_A01';  -- ����敪����}�X�^
  cv_qct_mkorg_cls          CONSTANT  VARCHAR2(50) := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  -- �쐬���敪����}�X�^
  cv_qct_dlv_slp_cls        CONSTANT  VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_013_A01'; -- �[�i�`�[�敪����}�X�^
  cv_qcv_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONSUMPTION_TAX_CLASS';   -- ����ŋ敪����}�X�^
  cv_qct_cust_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CUS_CLASS_MST_013_A01';   -- �ڋq�敪����}�X�^
  cv_qct_item_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_ITEM_DTL_MST_013_A01';    -- AR�i�ږ��דE�v����}�X�^
  cv_qct_jour_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_JOUR_CLS_MST_013_A01';    -- AR��v�z���d�����}�X�^
--
  -- �N�C�b�N�R�[�h
  cv_qcc_code               CONSTANT  VARCHAR2(50) := 'XXCOS_013_A01%';                 -- �N�C�b�N�R�[�h
  cv_attribute_y            CONSTANT  VARCHAR2(1)  := 'Y';                              -- DFF�l'Y'
  cv_attribute_n            CONSTANT  VARCHAR2(1)  := 'N';                              -- DFF�l'N'
  cv_attribute_a            CONSTANT  VARCHAR2(1)  := 'A';                              -- DFF�l'A'
  cv_attribute_b            CONSTANT  VARCHAR2(1)  := 'B';                              -- DFF�l'B'
  cv_enabled_yes            CONSTANT  VARCHAR2(1)  := 'Y';                              -- �g�p�\�t���O�萔:�L��
  cv_attribute_1            CONSTANT  VARCHAR2(1)  := '1';                              -- DFF�l'1'
  cv_attribute_2            CONSTANT  VARCHAR2(1)  := '2';                              -- DFF�l'2'
--
  -- �������OIF�e�[�u���ɐݒ肷��Œ�l
  cv_currency_code         CONSTANT  VARCHAR2(3)   := 'JPY';                            -- �ʉ݃R�[�h
  cv_line                  CONSTANT  VARCHAR2(4)   := 'LINE';                           -- ���v�s
  cv_tax                   CONSTANT  VARCHAR2(3)   := 'TAX';                            -- �ŋ��s
  cv_user                  CONSTANT  VARCHAR2(4)   := 'User';                           -- ���Z�^�C�v�p(User��ݒ�)
  cv_open                  CONSTANT  VARCHAR2(4)   := 'OPEN';                           -- �w�b�_�[DFF7(�\���P)
  cv_wait                  CONSTANT  VARCHAR2(7)   := 'WAITING';                        -- �w�b�_�[DFF(�\��)
  cv_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- �؂�グ
  cv_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- �؂艺��
  cv_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- �l�̌ܓ�
  cn_quantity              CONSTANT  NUMBER        := 1;                                -- ����=1
  cn_con_rate              CONSTANT  NUMBER        := 1;                                -- ���Z���[�g
  cn_percent               CONSTANT  NUMBER        := 100;                              -- 100
  cn_jour_cnt              CONSTANT  NUMBER        := 3;                                -- AR�z���d��J�E���g
--
  -- AR��v�z��OIF�e�[�u���ɐݒ肷��Œ�l
  cv_acct_rev              CONSTANT  VARCHAR2(4)   := 'REV';                            -- �z���^�C�v�F���v
  cv_acct_tax              CONSTANT  VARCHAR2(4)   := 'TAX';                            -- �z���^�C�v�FTAX
  cv_acct_rec              CONSTANT  VARCHAR2(4)   := 'REC';                            -- �z���^�C�v�F���Ȗ�
  cv_nvd                   CONSTANT  VARCHAR2(4)   := 'NV';                             -- VD�ȊO�̋ƑԂƔ[�iVD�ݒ�p
--
  -- ���t�t�H�[�}�b�g
  cv_date_format_non_sep      CONSTANT VARCHAR2(20) := 'YYYYMMDD';
  cv_substr_st                CONSTANT NUMBER       := 7;
  cv_substr_cnt               CONSTANT NUMBER       := 2;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔����у��[�N�e�[�u����`
  TYPE gr_sales_exp_rec IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- �[�i��
    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- ������
    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- �ڋq�y�[�i��z
    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- �ŋ��R�[�h
    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- ����ŗ�
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����ŋ敪
    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- ���ьv��҃R�[�h
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
    , receiv_base_code          xxcos_sales_exp_headers.receiv_base_code%TYPE       -- �������_�R�[�h
    , create_class              xxcos_sales_exp_headers.create_class%TYPE           -- �쐬���敪
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
    , dlv_inv_line_no           xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE  -- �[�i���הԍ�
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- �i�ڃR�[�h
    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- ����敪
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- �ԍ��t���O
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- �i�ڋ敪(���i�E���i)
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- �����E�J�[�h���p�z
    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- ���㊨��ȖڃR�[�h
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- �ŋ�����ȖڃR�[�h
    , rcrm_receipt_id           ra_cust_receipt_methods.receipt_method_id%TYPE      -- �ڋq�x�����@ID
    , xchv_cust_id_s            xxcos_cust_hierarchy_v.ship_account_id%TYPE         -- �o�א�ڋqID
    , xchv_cust_id_b            xxcos_cust_hierarchy_v.bill_account_id%TYPE         -- ������ڋqID
    , xchv_cust_id_c            xxcos_cust_hierarchy_v.cash_account_id%TYPE         -- ������ڋqID
    , hcss_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(�o�א�)
    , hcsb_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(������)
    , hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(������)
    , xchv_bill_pay_id          xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE    -- �x������ID
    , xchv_bill_pay_id2         xxcos_cust_hierarchy_v.bill_payment_term2%TYPE      -- �x������2
    , xchv_bill_pay_id3         xxcos_cust_hierarchy_v.bill_payment_term3%TYPE      -- �x������3
    , xchv_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- �ŋ��|�[������
    , rtt1_term_dd1             ra_terms_tl.name%TYPE                               -- �x������1
    , rtt2_term_dd2             ra_terms_tl.name%TYPE                               -- �x������2
    , rtt3_term_dd3             ra_terms_tl.name%TYPE                               -- �x������3
    , xseh_rowid                ROWID                                               -- ROWID
  );
--
  -- �d��p�^�[�����[�N�e�[�u����`
  TYPE gr_jour_cls_rec IS RECORD(
      segment3_nm               fnd_lookup_values.description%TYPE                  -- ����Ȗږ���
    , dlv_invoice_cls           fnd_lookup_values.attribute1%TYPE                   -- �[�i�`�[�敪
    , item_prod_cls             fnd_lookup_values.attribute2%TYPE                   -- �i�ڃR�[�hOR���i�E���i
    , cust_gyotai_sho           fnd_lookup_values.attribute3%TYPE                   -- �Ƒԏ�����
    , card_sale_cls             fnd_lookup_values.attribute4%TYPE                   -- �J�[�h����敪
    , red_black_flag            fnd_lookup_values.attribute5%TYPE                   -- �ԍ��t���O
    , acct_type                 fnd_lookup_values.attribute6%TYPE                   -- �z���^�C�v
    , segment2                  fnd_lookup_values.attribute7%TYPE                   -- ����R�[�h
    , segment3                  fnd_lookup_values.attribute8%TYPE                   -- ����ȖڃR�[�h
    , segment4                  fnd_lookup_values.attribute9%TYPE                   -- �⏕����ȖڃR�[�h
    , segment5                  fnd_lookup_values.attribute10%TYPE                  -- �ڋq�R�[�h
    , segment6                  fnd_lookup_values.attribute11%TYPE                  -- ��ƃR�[�h
    , segment7                  fnd_lookup_values.attribute12%TYPE                  -- ���Ƌ敪�R�[�h
    , segment8                  fnd_lookup_values.attribute13%TYPE                  -- �\���P
    , amount_sign               fnd_lookup_values.attribute14%TYPE                  -- ���z����
  );
--
  -- ���[�N�e�[�u����`
  TYPE gr_select_ccid IS RECORD(
      code_combination_id       gl_code_combinations.code_combination_id%TYPE       -- CCID
  );
  -- �i�ږ��׃��[�N�e�[�u����`
  TYPE gr_sel_item_desp IS RECORD(
      description               fnd_lookup_values.description%TYPE                  -- �i�ږ��דE�v
  );
  -- ����^�C�v���[�N�e�[�u����`
  TYPE gr_sel_trx_type IS RECORD(
      attribute1                fnd_lookup_values.attribute1%TYPE                   -- ����^�C�v
  );
  -- AR��v�z���W��p���[�N�e�[�u����`
  TYPE gr_dis_sum IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
    , interface_line_dff4       VARCHAR2(20)                                        -- �����̔�:LINE
    , interface_tax_dff4        VARCHAR2(20)                                        -- �����̔�:TAX
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- �i�ڃR�[�h
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- �i�ڋ敪�i���i�E���i�j
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- �ԍ��t���O
    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- ���㊨��ȖڃR�[�h
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- �ŋ�����ȖڃR�[�h
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����ŋ敪
  );
--
  -- �̔����у��[�N�e�[�u���^��`
  TYPE g_sales_exp_ttype IS TABLE OF gr_sales_exp_rec INDEX BY BINARY_INTEGER;
  gt_sales_exp_tbl              g_sales_exp_ttype;                                  -- �̔����уf�[�^
  gt_sales_norm_tbl             g_sales_exp_ttype;                                  -- �̔����є���ʔ̓X�f�[�^
  gt_sales_bulk_tbl             g_sales_exp_ttype;                                  -- �̔����ё��ʔ̓X�f�[�^
  gt_norm_card_tbl              g_sales_exp_ttype;                                  -- �̔����є���ʔ̓X�J�[�h�f�[�^
  gt_bulk_card_tbl              g_sales_exp_ttype;                                  -- �̔����ё��ʔ̓X�J�[�h�f�[�^
--
  TYPE g_sales_h_ttype   IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                     g_sales_h_ttype;                               -- �̔����уt���O�X�V�p
--
  TYPE g_jour_cls_ttype  IS TABLE OF gr_jour_cls_rec INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                    g_jour_cls_ttype;                              -- �d��p�^�[��
--
  TYPE g_ar_oif_ttype    IS TABLE OF ra_interface_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_interface_tbl                g_ar_oif_ttype;                                -- AR�������OIF
--
  TYPE g_ar_dis_ttype    IS TABLE OF ra_interface_distributions_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_dis_tbl                      g_ar_dis_ttype;                                -- AR��v�z��OIF
--
  TYPE g_dis_sum_ttype   IS TABLE OF gr_dis_sum INDEX BY BINARY_INTEGER;
  gt_ar_dis_sum_tbl                  g_dis_sum_ttype;                               -- AR��v�z���W��p
  gt_ar_dis_bul_tbl                  g_dis_sum_ttype;                               -- AR��v�z���W��p(BULK)
--
  TYPE g_sel_ccid_ttype  IS TABLE OF gr_select_ccid INDEX BY VARCHAR2( 200 );
  gt_sel_ccid_tbl                    g_sel_ccid_ttype;                              -- CCID
--
  TYPE g_sel_item_ttype  IS TABLE OF gr_sel_item_desp INDEX BY VARCHAR2( 200 );
  gt_sel_item_desp_tbl               g_sel_item_ttype;                              -- �i�ږ��דE�v
--
  TYPE g_sel_trx_ttype   IS TABLE OF gr_sel_trx_type INDEX BY VARCHAR2( 200 );
  gt_sel_trx_type_tbl                g_sel_trx_ttype;                               -- ����^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
  gd_process_date                     DATE;                                         -- �Ɩ����t
  gv_company_code                     VARCHAR2(30);                                 -- ��ЃR�[�h
  gv_set_bks_id                       VARCHAR2(30);                                 -- ��v����ID
  gv_org_cd                           VARCHAR2(30);                                 -- �݌ɑg�D�R�[�h
  gv_org_id                           VARCHAR2(30);                                 -- �݌ɑg�DID
  gv_mo_org_id                        VARCHAR2(30);                                 -- �c�ƒP��ID
  gv_var_elec_item_cd                 VARCHAR2(30);                                 -- �ϓ��d�C��(�i�ڃR�[�h)
  gv_busi_dept_cd                     VARCHAR2(30);                                 -- �Ɩ��Ǘ���
  gv_busi_emp_cd                      VARCHAR2(30);                                 -- �Ɩ��Ǘ����S����
  gv_sales_nm                         VARCHAR2(30);                                 -- ������:�̔�����
  gv_tax_msg                          VARCHAR2(20);                                 -- ������:�������œ�
  gv_goods_msg                        VARCHAR2(20);                                 -- ������:���i���㍂
  gv_prod_msg                         VARCHAR2(20);                                 -- ������:���i���㍂
  gv_disc_msg                         VARCHAR2(20);                                 -- ������:����l��
  gv_item_tax                         VARCHAR2(30);                                 -- �i�ږ��דE�v(TAX)
  gv_dis_item_cd                      VARCHAR2(30);                                 -- ����l���i�ڃR�[�h
--
  gt_cust_cls_cd                      hz_cust_accounts.customer_class_code%TYPE;    -- �ڋq�敪�i��l�j
  gt_cash_sale_cls                    fnd_lookup_values.lookup_code%TYPE;           -- �J�[�h����敪(����:0)
  gt_fvd_xiaoka                       fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-�t��VD�i�����j:'24'
  gt_gyotai_fvd                       fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-�t��VD:'25'
  gt_vd_xiaoka                        fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-����VD:'27'
  gt_no_tax_cls                       fnd_lookup_values.attribute3%TYPE;            -- ����敪-��ې�:4
  gt_in_tax_cls                       fnd_lookup_values.attribute2%TYPE;            -- ����敪-����:2205
  gt_out_tax_cls                      fnd_lookup_values.attribute2%TYPE;            -- ����敪-�O��:2105
  gn_aroif_cnt                        NUMBER;                                       -- ���팏���iAR�������OIF�j
  gn_ardis_cnt                        NUMBER;                                       -- ���팏���iAR��v�z��OIF�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �d��p�^�[���J�[�\��
  CURSOR jour_cls_cur
  IS
    SELECT
           flvl.description           segment3_nm     -- ����Ȗږ���
         , flvl.attribute1            dlv_invoice_cls -- �[�i�`�[�敪
         , flvl.attribute2            item_prod_cls   -- �i�ڃR�[�h OR �i�ڋ敪(���i�E���i)
         , flvl.attribute3            cust_gyotai_sho -- �Ƒԏ�����
         , flvl.attribute4            card_sale_cls   -- �J�[�h����敪
         , flvl.attribute5            red_black_flag  -- �ԍ��t���O
         , flvl.attribute6            acct_type       -- �z���^�C�v(REC�EREV�ETAX)
         , flvl.attribute7            segment2        -- ����R�[�h
         , flvl.attribute8            segment3        -- ����ȖڃR�[�h
         , flvl.attribute9            segment4        -- �⏕����ȖڃR�[�h
         , flvl.attribute10           segment5        -- �ڋq�R�[�h
         , flvl.attribute11           segment6        -- ��ƃR�[�h
         , flvl.attribute12           segment7        -- ���Ƌ敪�R�[�h
         , flvl.attribute13           segment8        -- �\���P
         , flvl.attribute14           amount_sign     -- ���z����
    FROM
            fnd_lookup_values         flvl
    WHERE
            flvl.lookup_type          = cv_qct_jour_cls
      AND   flvl.lookup_code          LIKE cv_qcc_code
      AND   flvl.enabled_flag         = cv_enabled_yes
      AND   flvl.language             = USERENV( 'LANG' )
      AND   gd_process_date BETWEEN   NVL( flvl.start_date_active, gd_process_date )
                            AND       NVL( flvl.end_date_active,   gd_process_date );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';             -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END     ########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_pro_bks_id            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';
                                                               -- ��v����ID
    ct_pro_org_cd            CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
                                                               -- XXCOI:�݌ɑg�D�R�[�h
    ct_pro_mo_org_cd         CONSTANT VARCHAR2(50) := 'ORG_ID';
                                                               -- MO:�c�ƒP��
    ct_pro_company_cd        CONSTANT VARCHAR2(30) := 'XXCOI1_COMPANY_CODE';
                                                               -- XXCOI:��ЃR�[�h
    ct_var_elec_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
                                                               -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)
    ct_busi_dept_cd          CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_DEPT_CODE';
                                                               -- XXCOS:�Ɩ��Ǘ���
    ct_busi_emp_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_EMP';
                                                               -- XXCOS:�Ɩ��Ǘ����S����
    ct_dis_item_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_DISCOUNT_ITEM_CODE';
                                                               -- XXCOS:����l���i��
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name          VARCHAR2(50);                     -- �v���t�@�C����
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--##################  �Œ�X�e�[�^�X�������� END     ###################
--
    --===================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
    --===================================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_nm
                    ,iv_name         => cv_no_para_msg
                    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
   );
--
    --===================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����O�o��
    --===================================================
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcos_short_nm, cv_process_date_msg );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F��v����ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( ct_pro_bks_id );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_bks_id                               -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
    -- ===============================
    gv_org_cd := FND_PROFILE.VALUE( ct_pro_org_cd );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_org_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_org_cd                               -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gv_org_id := xxcoi_common_pkg.get_organization_id( gv_org_cd );
    -- �݌ɑg�DID�擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_nm
                     , iv_name        => cv_org_id_get_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- MO:�c�ƒP�ʎ擾
    --==================================
    gv_mo_org_id := FND_PROFILE.VALUE( ct_pro_mo_org_cd );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_mo_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_mo_org_cd                            -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOI:��ЃR�[�h
    --==================================
    gv_company_code := FND_PROFILE.VALUE( ct_pro_company_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_company_cd                           -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)�擾
    --==================================
    gv_var_elec_item_cd := FND_PROFILE.VALUE( ct_var_elec_item_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_var_elec_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_nm                          -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_var_elec_item_cd                        -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�Ɩ��Ǘ���
    --==================================
    gv_busi_dept_cd := FND_PROFILE.VALUE( ct_busi_dept_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_busi_dept_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_busi_dept_cd                             -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�Ɩ��Ǘ����S����
    --==================================
    gv_busi_emp_cd := FND_PROFILE.VALUE( ct_busi_dept_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_busi_emp_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_busi_emp_cd                              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:����l���i��
    --==================================
    gv_dis_item_cd := FND_PROFILE.VALUE( ct_dis_item_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_dis_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_dis_item_cd                              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 5.�N�C�b�N�R�[�h�擾
    --==================================
    -- �J�[�h����敪=����:0
    BEGIN
      SELECT flvl.lookup_code
      INTO   gt_cash_sale_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_card_cls
        AND  flvl.attribute3             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_card_sale_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_card_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=��ې�:4
    BEGIN
      SELECT flvl.attribute3
      INTO   gt_no_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute4             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff4
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=����'2205'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_in_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_2
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_in_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=�O��'2105'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_out_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_1
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_out_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => cv_qcv_tax_cls
                        , iv_token_name2   => cv_tkn_lookup_dff3
                        , iv_token_value2  => cv_attribute_1
                      );
          lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �ڋq�敪=��l:12
    BEGIN
      SELECT flvl.meaning
      INTO   gt_cust_cls_cd
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_cust_cls
        AND  flvl.lookup_code            LIKE cv_qcc_code
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_cust_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_cust_cls
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ��t���T�[�r�X�i�����jVD :24
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_fvd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_a
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_a
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ��t���T�[�r�XVD :25
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_gyotai_fvd
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_b
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_b
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ�����VD :27
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_vd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_n
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_n
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
--##################################  �Œ��O������  END ####################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name VARCHAR2(255);                                       -- �e�[�u����
    ln_bulk_idx   NUMBER DEFAULT 0;                                    -- ����ʔ̓X�C���f�b�N�X
    ln_norm_idx   NUMBER DEFAULT 0;                                    -- ���ʔ̓X�C���f�b�N�X
--
    -- *** ���[�J���E�J�[�\�� (�̔����уf�[�^���o)***
    CURSOR sales_data_cur
    IS
      SELECT
             xseh.sales_exp_header_id          sales_exp_header_id     -- �̔����уw�b�_ID
           , xseh.dlv_invoice_number           dlv_invoice_number      -- �[�i�`�[�ԍ�
           , xseh.dlv_invoice_class            dlv_invoice_class       -- �[�i�`�[�敪
           , xseh.cust_gyotai_sho              cust_gyotai_sho         -- �Ƒԏ�����
           , xseh.delivery_date                delivery_date           -- �[�i��
           , xseh.inspect_date                 inspect_date            -- ������
           , xseh.ship_to_customer_code        ship_to_customer_code   -- �ڋq�y�[�i��z
           , xseh.tax_code                     tax_code                -- �ŋ��R�[�h
           , xseh.tax_rate                     tax_rate                -- ����ŗ�
           , xseh.consumption_tax_class        consumption_tax_class   -- ����ŋ敪
           , xseh.results_employee_code        results_employee_code   -- ���ьv��҃R�[�h
           , xseh.sales_base_code              sales_base_code         -- ���㋒�_�R�[�h
           , xseh.receiv_base_code             receiv_base_code        -- �������_�R�[�h
           , xseh.create_class                 create_class            -- �쐬���敪
           , NVL( xseh.card_sale_class, cv_cash_class )
                                               card_sale_class         -- �J�[�h����敪
           , xsel.dlv_invoice_line_number      dlv_inv_line_no         -- �[�i���הԍ�
           , xsel.item_code                    item_code               -- �i�ڃR�[�h
           , xsel.sales_class                  sales_class             -- ����敪
           , xsel.red_black_flag               red_black_flag          -- �ԍ��t���O
           , xgpc.goods_prod_class_code        goods_prod_cls          -- �i�ڋ敪�i���i�E���i�j
           , xsel.pure_amount                  pure_amount             -- �{�̋��z
           , xsel.tax_amount                   tax_amount              -- ����Ŋz
           , NVL( xsel.cash_and_card, 0 )      cash_and_card           -- �����E�J�[�h���p�z
           , gcc.segment3                      gccs_segment3           -- ���㊨��ȖڃR�[�h
           , gcct.segment3                     gcct_segment3           -- �ŋ�����ȖڃR�[�h
           , rcrm.receipt_method_id            rcrm_receipt_id         -- �ڋq�x�����@ID
           , xchv.ship_account_id              xchv_cust_id_s          -- �o�א�ڋqID
           , xchv.bill_account_id              xchv_cust_id_b          -- ������ڋqID
           , xchv.cash_account_id              xchv_cust_id_c          -- ������ڋqID
           , hcss.cust_acct_site_id            hcss_org_sys_id         -- �ڋq���ݒn�Q��ID�i�o�א�j
           , hcsb.cust_acct_site_id            hcsb_org_sys_id         -- �ڋq���ݒn�Q��ID�i������j
           , hcsc.cust_acct_site_id            hcsc_org_sys_id         -- �ڋq���ݒn�Q��ID�i������j
           , xchv.bill_payment_term_id         xchv_bill_pay_id        -- �x������ID
           , xchv.bill_payment_term2           xchv_bill_pay_id2       -- �x������2
           , xchv.bill_payment_term3           xchv_bill_pay_id3       -- �x������3
           , xchv.bill_tax_round_rule          xchv_tax_round          -- �ŋ��|�[������
           , SUBSTR(rtt1.name,1,2)             rtt1_term_dd1           -- �x������1�̐擪�Q�o�C�g
           , SUBSTR(rtt2.name,1,2)             rtt2_term_dd2           -- �x������2�̐擪�Q�o�C�g
           , SUBSTR(rtt3.name,1,2)             rtt3_term_dd3           -- �x������3�̐擪�Q�o�C�g
           , xseh.rowid                        xseh_rowid              -- ROWID
      FROM
             xxcos_sales_exp_headers           xseh                    -- �̔����уw�b�_�e�[�u��
           , xxcos_sales_exp_lines             xsel                    -- �̔����і��׃e�[�u��
           , mtl_system_items_b                msib                    -- �i�ڃ}�X�^
           , gl_code_combinations              gcc                     -- ����Ȗڑg�����}�X�^
           , gl_code_combinations              gcct                    -- ����Ȗڑg�����}�X�^�iTAX�p�j
           , ar_vat_tax_all_b                  avta                    -- �ŋ��}�X�^
           , hz_cust_accounts                  hcas                    -- �ڋq�}�X�^�i�o�א�j
           , hz_cust_accounts                  hcab                    -- �ڋq�}�X�^�i������j
           , hz_cust_accounts                  hcac                    -- �ڋq�}�X�^�i������j
           , hz_cust_acct_sites_all            hcss                    -- �ڋq���ݒn�i�o�א�j
           , hz_cust_acct_sites_all            hcsb                    -- �ڋq���ݒn�i������j
           , hz_cust_acct_sites_all            hcsc                    -- �ڋq���ݒn�i������j
           , ra_terms_tl                       rtt1                    -- AR�x������(1)
           , ra_terms_tl                       rtt2                    -- AR�x������(2)
           , ra_terms_tl                       rtt3                    -- AR�x������(3)
           , ra_cust_receipt_methods           rcrm                    -- �ڋq�x�����@
           , xxcos_good_prod_class_v           xgpc                    -- �i�ڋ敪View
           , xxcos_cust_hierarchy_v            xchv                    -- �ڋq�K�w�r���[
           , hz_cust_site_uses_all             scsua                   -- �ڋq�g�p�ړI
      WHERE
          xseh.sales_exp_header_id              = xsel.sales_exp_header_id
      AND xseh.dlv_invoice_number               = xsel.dlv_invoice_number
      AND xseh.ar_interface_flag                = cv_n_flag
      AND xseh.delivery_date                   <= gd_process_date
      AND xsel.item_code                       <> gv_var_elec_item_cd
      AND xchv.ship_account_number              = xseh.ship_to_customer_code
      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcas.account_number                   = xseh.ship_to_customer_code
      AND hcab.account_number                   = xchv.bill_account_number
      AND hcac.account_number                   = xchv.cash_account_number
      AND hcas.customer_class_code             <> gt_cust_cls_cd
      AND ( xseh.cust_gyotai_sho               <> gt_gyotai_fvd
         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
           AND NVL( xseh.card_sale_class, cv_cash_class )
                                               <> gt_cash_sale_cls )
         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
           AND NVL( xseh.card_sale_class, cv_cash_class )
                                                = gt_cash_sale_cls
           AND NVL( xsel.cash_and_card, 0 )     > 0 ) )
      AND avta.tax_code                         = xseh.tax_code
      AND avta.set_of_books_id                  = TO_NUMBER( gv_set_bks_id )
      AND avta.enabled_flag                     = cv_enabled_yes
      AND gd_process_date BETWEEN               NVL( avta.start_date, gd_process_date )
                          AND                   NVL( avta.end_date,   gd_process_date )
      AND gcct.code_combination_id              = avta.tax_account_id
          AND msib.organization_id              = TO_NUMBER( gv_org_id )
          AND xsel.item_code                    = msib.segment1
          AND gcc.code_combination_id           = msib.sales_account
          AND xgpc.segment1( + )                = xsel.item_code
      AND xseh.create_class                     NOT IN (
          SELECT
              flvl.meaning                      meaning
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_mkorg_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute2                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
          AND flvl.language                     = USERENV( 'LANG' )
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
          )
      AND xsel.sales_class                      NOT IN (
          SELECT
              flvl.meaning                      meaning
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_sale_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute1                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
          AND flvl.language                     = USERENV( 'LANG' )
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
          )
      AND hcss.cust_account_id                  = hcas.cust_account_id
      AND hcsb.cust_account_id                  = hcab.cust_account_id
      AND hcsc.cust_account_id                  = hcac.cust_account_id
      AND xchv.ship_account_id                  = hcas.cust_account_id
      AND rcrm.customer_id                      = hcab.cust_account_id
      AND rcrm.primary_flag                     = cv_y_flag
      AND rcrm.site_use_id                      = scsua.site_use_id
      AND gd_process_date BETWEEN               NVL( rcrm.start_date, gd_process_date )
                          AND                   NVL( rcrm.end_date,   gd_process_date )
      AND scsua.site_use_code                   = 'BILL_TO'
      AND rtt1.term_id                          = xchv.bill_payment_term_id
      AND rtt1.language                         = USERENV( 'LANG' )
      AND rtt2.term_id                          = xchv.bill_payment_term2
      AND rtt2.language                         = USERENV( 'LANG' )
      AND rtt3.term_id                          = xchv.bill_payment_term3
      AND rtt3.language                         = USERENV( 'LANG' )
      ORDER BY xseh.sales_exp_header_id
             , xseh.dlv_invoice_number
             , xseh.dlv_invoice_class
             , NVL( xseh.card_sale_class, cv_cash_class )
             , xseh.cust_gyotai_sho
             , xsel.item_code
             , xsel.red_black_flag
             , gcc.segment3
             , gcct.segment3
    FOR UPDATE OF  xseh.sales_exp_header_id
    NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN  sales_data_cur;
    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl;
--
    -- �J�[�\���N���[�Y
    CLOSE sales_data_cur;
--
    -- �Ώۏ�������
    gn_target_cnt   := gt_sales_exp_tbl.COUNT;
--
    IF ( gn_target_cnt > 0 ) THEN
      -- ����ʔ̓X�f�[�^�Ƒ��ʔ̓X�f�[�^�̕���
      -- ���o���ꂽ�̔����уf�[�^�̃��[�v
      <<gt_sales_exp_tbl_loop>>
      FOR sale_idx IN 1 .. gn_target_cnt LOOP
        IF ( gt_sales_exp_tbl( sale_idx ).receiv_base_code = gv_busi_dept_cd ) THEN
          -- ���ʔ̓X�f�[�^�𒊏o
          ln_bulk_idx := ln_bulk_idx + 1;
          gt_sales_bulk_tbl( ln_bulk_idx ) := gt_sales_exp_tbl( sale_idx );
        ELSE
          -- ����ʔ̓X�f�[�^�𒊏o
          ln_norm_idx := ln_norm_idx + 1;
          gt_sales_norm_tbl( ln_norm_idx ) := gt_sales_exp_tbl( sale_idx );
        END IF;
      END LOOP gt_sales_exp_tbl_loop;                                  -- �̔����уf�[�^���[�v�I��
    ELSIF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_no_data_msg
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_warn;
      RAISE global_no_data_expt;
    ELSE
      ov_retcode := cv_status_error;
      RAISE global_select_data_expt;
    END IF;
--
    --=====================================
    -- �S�p������擾
    --=====================================
    -- �P�D�̔�����
    gv_sales_nm := xxccp_common_pkg.get_msg(
                       iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                     , iv_name              => cv_sales_nm_msg         -- ���b�Z�[�WID
                     );
    -- �Q�D�������œ�
    gv_tax_msg   := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_short_nm              -- �A�v���P�[�V�����Z�k��
                    , iv_name        => cv_tax_msg                     -- ���b�Z�[�WID(�������œ�)
                    );
    -- �R�D���i���㍂
    gv_goods_msg := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_goods_msg                 -- ���b�Z�[�WID(���i���㍂)
                    );
    -- �S�D���i���㍂
    gv_prod_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_prod_msg                  -- ���b�Z�[�WID(���i���㍂)
                    );
    -- �T�D����l����
    gv_disc_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_disc_msg                  -- ���b�Z�[�WID(����l��)
                    );
--
    --=====================================================================
    -- �i�ږ��דE�v�̎擾(�u�������œ��v�̂�)(A-3 �� A-5�p)
    --=====================================================================
    BEGIN
      SELECT flvi.description
      INTO   gv_item_tax
      FROM   fnd_lookup_values              flvi                         -- AR�i�ږ��דE�v����}�X�^
      WHERE  flvi.lookup_type               = cv_qct_item_cls
        AND  flvi.lookup_code               LIKE cv_qcc_code
        AND  flvi.attribute1                = cv_tax
        AND  flvi.enabled_flag              = cv_enabled_yes
        AND  flvi.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                             AND            NVL( flvi.end_date_active,   gd_process_date );
--
      -- AR�i�ږ��דE�v(�������œ�)�擾�o���Ȃ��ꍇ
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_itemdesp_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_item_cls
                    );
        lv_errbuf  := lv_errmsg;
--
        RAISE global_no_lookup_expt;
    END;
--
      -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
      gt_sel_item_desp_tbl( cv_tax ).description := gv_item_tax;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_sales_msg         -- ���b�Z�[�WID
                       );
      lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_table_lock_msg
                         , iv_token_name1  => cv_tkn_tbl
                         , iv_token_value1 => lv_table_name
                       );
      lv_errbuf     := lv_errmsg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
--
    -- *** �Ώۃf�[�^�Ȃ� *** 
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �f�[�^�擾��O *** 
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN global_no_lookup_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_data_get_msg
                    );
      lv_errbuf  := lv_errmsg;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_data
   * Description      : ��������W�񏈗��i����ʔ̓X�j(A-3)
   ***********************************************************************************/
  PROCEDURE edit_sum_data(
      ov_errbuf         OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_data';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_card_idx             NUMBER DEFAULT 0;           -- ���������J�[�h���R�[�h�̃C���f�b�N�X
    ln_card_pt              NUMBER DEFAULT 1;           -- �J�[�h���R�[�h�̃C���f�b�N�X���s�ʒu
    ln_ar_idx               NUMBER DEFAULT 0;           -- �������OIF�C���f�b�N�X
    ln_ar_sum               NUMBER DEFAULT 0;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
    lv_trx_type_nm          VARCHAR2(30);               -- ����^�C�v����
    lv_trx_idx              VARCHAR2(30);               -- ����^�C�v(�C���f�b�N�X)
    lv_item_idx             VARCHAR2(30);               -- �i�ږ��דE�v(�C���f�b�N�X)
    lv_item_desp            VARCHAR2(30);               -- �i�ږ��דE�v(TAX�ȊO)
    ln_term_id              NUMBER;                     -- �x������ID
    lv_cust_gyotai_sho      VARCHAR2(30);               -- �Ƒԏ�����
    ln_pure_amount          NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̖{�̋��z
    ln_tax_amount           NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̏���ŋ��z
    ln_tax                  NUMBER DEFAULT 0;           -- �W������ŋ��z
    ln_amount               NUMBER DEFAULT 0;           -- �W�����z
    ln_tax_card             NUMBER DEFAULT 0;           -- �W������ŋ��z(�J�[�h���R�[�h)
    ln_amount_card          NUMBER DEFAULT 0;           -- �W�����z(�J�[�h���R�[�h)
    ln_trx_number_id        NUMBER;                     -- �������DFF3�p:�����̔Ԕԍ�
--
    -- �W��L�[(�̔�����)
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- �W��L�[�F�̔����уw�b�_ID
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�敪
    lt_goods_prod_cls       xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- �W��L�[�F�i�ڋ敪�i���i�E���i�j
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- �W��L�[�F�i�ڃR�[�h�i��݌Ɂj
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;
                                                        -- �W��L�[�F�J�[�h����敪
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;
                                                        -- �W��L�[�F�ԍ��t���O
--
    -- �W��L�[(���������J�[�h���R�[�h)
    lt_header_id_card       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- �W��L�[�F�̔����уw�b�_ID
    lt_invo_number_card     xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invo_class_card      xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�敪
    lt_goods_prod_card      xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- �W��L�[�F�i�ڋ敪�R�[�h�i���i�E���i�j
    lt_item_code_card       xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- �W��L�[�F�i�ڃR�[�h�i��݌Ɂj
--
    lv_sum_flag             VARCHAR2(1);                -- �W��t���O
    lv_sum_card_flag        VARCHAR2(1);                -- �J�[�h�W��t���O
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\ ***
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
    --=====================================================================
    -- �S�D�t���T�[�r�XVD�ƃt���T�[�r�X�i�����jVD�̃J�[�h�E�������p�f�[�^�̕ҏW
    --=====================================================================
    <<gt_sales_norm_tbl_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
      -- �����E�J�[�h���p�̏ꍇ-->�J�[�h����敪=����:0 ���� �����J�[�h���p�z>0
      IF ( (   gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND (  gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = gt_cash_sale_cls
          AND  gt_sales_norm_tbl( sale_norm_idx ).cash_and_card   > 0 ) ) THEN
--
        -- �J�[�h���R�[�h�̖{�̋��z
        ln_pure_amount := gt_sales_norm_tbl( sale_norm_idx ).cash_and_card
                        / ( 1 + gt_sales_norm_tbl( sale_norm_idx ).tax_rate/cn_percent );
--
        -- �[������
        IF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round    = cv_round_rule_up ) THEN
          -- �؂�グ�̏ꍇ
          ln_pure_amount := CEIL( ln_pure_amount );
--
        ELSIF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round = cv_round_rule_down ) THEN
          -- �؂艺���̏ꍇ
          ln_pure_amount := FLOOR( ln_pure_amount );
--
        ELSIF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round = cv_round_rule_nearest ) THEN
          -- �l�̌ܓ��̏ꍇ
          ln_pure_amount := ROUND( ln_pure_amount );
        END IF;
--
        -- �ېł̏ꍇ�A�J�[�h���R�[�h�̏���Ŋz���Z�o����
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax_amount := gt_sales_norm_tbl( sale_norm_idx ).cash_and_card - ln_pure_amount;
        ELSE
          ln_tax_amount := 0;
        END IF;
--
        --==============================================================
        --�̔����уJ�[�h���[�N�e�[�u���ւ̃J�[�h���R�[�h�o�^
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        -- �J�[�h���R�[�h�S�J�����̐ݒ�
        gt_norm_card_tbl( ln_card_idx ) := gt_sales_norm_tbl( sale_norm_idx );
--
        -- �J�[�h���R�[�h�J�[�h����敪�A�{�̋��z�A����ŋ��z�̐ݒ�
        gt_norm_card_tbl( ln_card_idx ).card_sale_class     := cv_card_class;
                                                            -- �J�[�h����敪�i�P�F�J�[�h�j
        gt_norm_card_tbl( ln_card_idx ).pure_amount         := ln_pure_amount;
                                                            -- �{�̋��z
        gt_norm_card_tbl( ln_card_idx ).tax_amount          := ln_tax_amount;
                                                            -- ����ŋ��z
      END IF;
    END LOOP gt_sales_norm_tbl_loop;                        -- ����ʔ̓X���p�f�[�^�ҏW�I��
--
      --=====================================================================
      -- ��������W�񏈗��i����ʔ̓X�j�J�n
      --=====================================================================
    -- �W��L�[�̒l�Z�b�g
    lt_header_id        := gt_sales_norm_tbl( 1 ).sales_exp_header_id;
    lt_invoice_number   := gt_sales_norm_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_sales_norm_tbl( 1 ).dlv_invoice_class;
    lt_goods_prod_cls   := gt_sales_norm_tbl( 1 ).goods_prod_cls;
    lt_item_code        := gt_sales_norm_tbl( 1 ).item_code;
    lt_card_sale_class  := gt_sales_norm_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_sales_norm_tbl( 1 ).red_black_flag;
--
    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g
    gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT ).sales_exp_header_id;
    IF ( gt_norm_card_tbl.COUNT > 0 ) THEN
      gt_norm_card_tbl( gt_norm_card_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_norm_card_tbl( gt_norm_card_tbl.COUNT ).sales_exp_header_id;
    END IF;
--
    <<gt_sales_norm_sum_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      --=====================================
      --5-1.�̔����ь��f�[�^�̏W��
      --=====================================
      IF (  lt_header_id        = gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id
        AND lt_invoice_number   = gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
        AND lt_invoice_class    = gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class
        AND ( lt_goods_prod_cls = gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls
          OR lt_item_code       = gt_sales_norm_tbl( sale_norm_idx ).item_code )
        AND lt_card_sale_class  = gt_sales_norm_tbl( sale_norm_idx ).card_sale_class
        AND lt_red_black_flag   = gt_sales_norm_tbl( sale_norm_idx ).red_black_flag
        ) THEN
--
        -- �W�񂷂�t���O�����ݒ�
        lv_sum_flag      := cv_y_flag;
        lv_sum_card_flag := cv_y_flag;
--
        -- �{�̋��z���W�񂷂�
        ln_amount := ln_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        END IF;
--
        --=====================================
        --5-2.��L4�Ő��������J�[�h���R�[�h�̏W��
        --=====================================
        IF ( gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = cv_card_class ) THEN
          <<gt_norm_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_norm_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_norm_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_norm_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_norm_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_norm_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_norm_card_tbl( i ).item_code )
              ) THEN
              -- �{�̋��z���W�񂷂�
              ln_amount   := ln_amount + gt_norm_card_tbl( i ).pure_amount;
              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
              IF ( gt_norm_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax := ln_tax + gt_norm_card_tbl( i ).tax_amount;
              END IF;
            END IF;
            -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
            ln_card_pt := i;
          END LOOP gt_norm_card_tbl_loop;
--
        -- ���������J�[�h���R�[�h�����̏W��
        ELSIF ( ( gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = gt_cash_sale_cls
          AND gt_sales_norm_tbl( sale_norm_idx ).cash_and_card > 0
          AND ln_card_pt < gt_norm_card_tbl.COUNT
          ) THEN
--
          ln_amount_card := 0;
          ln_tax_card  := 0;
--
          -- ���������J�[�h���R�[�h�����̏W��J�n
          <<gt_norm_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_norm_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_norm_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_norm_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_norm_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_norm_card_tbl( i ).goods_prod_cls
                OR lt_item_code       = gt_norm_card_tbl( i ).item_code )
            ) THEN
              -- �{�̋��z���W�񂷂�
              ln_amount_card := ln_amount_card + gt_norm_card_tbl( i ).pure_amount;
              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
              IF ( gt_norm_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax_card  := ln_tax_card + gt_norm_card_tbl( i ).tax_amount;
              END IF;
            ELSE
              -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
              ln_card_pt := i;
              -- �W��t���O�fN'��ݒ�
              lv_sum_card_flag := cv_n_flag;
--
            END IF;
--
          END LOOP gt_norm_card_tbl_loop;
--
        END IF; -- ���������J�[�h���R�[�h�����̏W��I��
      ELSE
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_norm_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
        --=====================================================================
        -- �P�D�x������ID�̎擾
        --=====================================================================
        IF ( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                   , cv_substr_st, cv_substr_cnt )
             <= gt_sales_norm_tbl( ln_trx_idx ).rtt1_term_dd1 ) THEN
          -- �x������ ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_norm_tbl( ln_trx_idx ).rtt1_term_dd1
           AND SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_norm_tbl( ln_trx_idx ).rtt2_term_dd2 ) THEN
          -- ��2�x������ ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id2;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_norm_tbl( ln_trx_idx ).rtt2_term_dd2
           AND SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_norm_tbl( ln_trx_idx ).rtt3_term_dd3 ) THEN
          -- ��3�x������ ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id3;
        ELSE
          -- �x������ID�̎擾���ł��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_term_id_msg
                      );
          lv_errbuf  := lv_errmsg;
--
          RAISE global_term_id_expt;
        END IF;
--
        --=====================================================================
        -- �Q�D����^�C�v�̎擾
        --=====================================================================
        lv_trx_idx := gt_sales_norm_tbl( ln_trx_idx ).create_class
                   || gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
        ELSE
          BEGIN
            SELECT flvm.attribute1 || flvd.attribute1
            INTO   lv_trx_type_nm
            FROM   fnd_lookup_values              flvm                     -- �쐬���敪����}�X�^
                 , fnd_lookup_values              flvd                     -- �[�i�`�[�敪����}�X�^
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_norm_tbl( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
              AND  flvm.language                  = USERENV( 'LANG' )
              AND  flvd.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          -- ����^�C�v�擾�o���Ȃ��ꍇ
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls 
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- �擾��������^�C�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
--
        END IF;
--
        --=====================================================================
        -- 3�D�i�ږ��דE�v�̎擾(�u�������œ��v�ȊO)
        --=====================================================================
--
        -- �i�ږ��דE�v�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
        IF ( gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls IS NULL ) THEN
          lv_item_idx := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_norm_tbl( ln_trx_idx ).item_code;
        ELSE
          lv_item_idx := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls;
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR�i�ږ��דE�v����}�X�^
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls,
                                                         gt_sales_norm_tbl( ln_trx_idx ).item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
              AND  flvi.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR�i�ږ��דE�v�擾�o���Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
        END IF;
--
      END IF;
--
      --==============================================================
      -- �U�DAR�������OIF�f�[�^�쐬
      --==============================================================
--
      -- -- �W��t���O�fN'�̏ꍇ�AAR�������OIF�f�[�^�쐬����
      IF ( lv_sum_flag = cv_n_flag ) THEN 
--
        -- AR�������OIF�̎��v�s
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_ar_sum   := ln_ar_sum  + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR��v�z���W��p�f�[�^�i�[
        gt_ar_dis_sum_tbl( ln_ar_sum ).sales_exp_header_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �̔����уw�b�_ID
        gt_ar_dis_sum_tbl( ln_ar_sum ).dlv_invoice_number
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �[�i�`�[�ԍ�
        gt_ar_dis_sum_tbl( ln_ar_sum ).interface_line_dff4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �[�i�`�[�ԍ�+�����̔�
        gt_ar_dis_sum_tbl( ln_ar_sum ).dlv_invoice_class
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class;
                                                        -- �[�i�`�[�敪
        gt_ar_dis_sum_tbl( ln_ar_sum ).item_code        := gt_sales_norm_tbl( ln_trx_idx ).item_code;
                                                        -- �i�ڃR�[�h
        gt_ar_dis_sum_tbl( ln_ar_sum ).goods_prod_cls   := gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls;
                                                        -- �i�ڋ敪�i���i�E���i�j
        -- �Ƒԏ����ނ̕ҏW
        IF ( gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
          OR gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_gyotai_fvd
          OR gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_vd_xiaoka ) THEN
          lv_cust_gyotai_sho := cv_nvd;                 -- VD�ȊO�̋ƑԁE�[�iVD
        ELSE
          lv_cust_gyotai_sho := gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho;
                                                        -- �t��(����)VD�E�t��VD�E����VD
        END IF;
        gt_ar_dis_sum_tbl( ln_ar_sum ).cust_gyotai_sho  := lv_cust_gyotai_sho;
                                                        -- �Ƒԏ�����
        gt_ar_dis_sum_tbl( ln_ar_sum ).sales_base_code  := gt_sales_norm_tbl( ln_trx_idx ).sales_base_code;
                                                        -- ���㋒�_�R�[�h
        gt_ar_dis_sum_tbl( ln_ar_sum ).card_sale_class  := gt_sales_norm_tbl( ln_trx_idx ).card_sale_class;
                                                        -- �J�[�h����敪
        gt_ar_dis_sum_tbl( ln_ar_sum ).red_black_flag   := gt_sales_norm_tbl( ln_trx_idx ).red_black_flag;
                                                        -- �ԍ��t���O
        gt_ar_dis_sum_tbl( ln_ar_sum ).pure_amount      := ln_amount;
                                                        -- �W���{�̋��z
        gt_ar_dis_sum_tbl( ln_ar_sum ).gccs_segment3    := gt_sales_norm_tbl( ln_trx_idx ).gccs_segment3;
                                                        -- ���㊨��ȖڃR�[�h
        gt_ar_dis_sum_tbl( ln_ar_sum ).tax_amount       := ln_tax;
                                                        -- �W������Ŋz
        gt_ar_dis_sum_tbl( ln_ar_sum ).gcct_segment3    := gt_sales_norm_tbl( ln_trx_idx ).gcct_segment3;
                                                        -- ����Ŋ���ȖڃR�[�h
--
        -- AR�������OIF�f�[�^�쐬(���v�s)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
                                                        -- ���v�s�F�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl( sale_norm_idx ).cash_and_card   = 0 ) THEN
        -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- ���v�s�̂݁FAR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_norm_tbl( ln_trx_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_base_code;
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gt_sales_norm_tbl( ln_trx_idx ).results_employee_code;
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_norm_tbl( ln_trx_idx ).receiv_base_code;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR��v�z���W��p�f�[�^�i�[
        gt_ar_dis_sum_tbl( ln_ar_sum ).interface_tax_dff4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �[�i�`�[�ԍ�+�����̔�
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_norm_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
      END IF;
--
      -- �J�[�h�W��t���O�fN'�̏ꍇ�A�J�[�h��AR�������OIF�f�[�^�쐬����
      IF ( lv_sum_card_flag = cv_n_flag AND ln_amount_card > 0 ) THEN   
--
        -- AR�������OIF�̎��v�s
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_card_idx := ln_card_pt - 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR�������OIF�f�[�^�쐬(���v�s)===>NO.3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount_card;
                                                        -- ���v�s�F�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_norm_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_norm_card_tbl( ln_card_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_norm_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- ���v�s�̂݁FAR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_norm_card_tbl( ln_card_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount_card;
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_norm_card_tbl( ln_card_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_base_code;
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gt_norm_card_tbl( ln_card_idx ).results_employee_code;
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_norm_card_tbl( ln_card_idx ).receiv_base_code;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.4
        ln_ar_idx := ln_ar_idx + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax_card;
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_norm_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_norm_card_tbl( ln_card_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_norm_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_norm_card_tbl( ln_card_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
        -- �W��t���O�̃��Z�b�g
        lv_sum_card_flag := cv_y_flag;
        ln_amount_card := 0;
--
      END IF;                                           -- �W��L�[����AR OIF�f�[�^�̏W��I��
--
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- �W��L�[�ƏW����z�̃��Z�b�g
        lt_header_id       := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;
        lt_invoice_number  := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number;
        lt_invoice_class   := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class;
        lt_goods_prod_cls  := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
        lt_item_code       := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        lt_card_sale_class := gt_sales_norm_tbl( sale_norm_idx ).card_sale_class;
        lt_red_black_flag  := gt_sales_norm_tbl( sale_norm_idx ).red_black_flag;
        lv_sum_card_flag := cv_y_flag;
--
        ln_amount := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
      -- �̔����уw�b�_�X�V�̂��߁FROWID�̐ݒ�
      gt_sales_h_tbl( sale_norm_idx ) := gt_sales_norm_tbl( sale_norm_idx ).xseh_rowid;
--
    END LOOP gt_sales_norm_sum_loop;                    -- �̔����уf�[�^���[�v�I��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_data
   * Description      : AR��v�z���d��쐬�i����ʔ̓X�j(A-4)
   ***********************************************************************************/
  PROCEDURE edit_dis_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_ccid_idx         VARCHAR2(225);                                   -- �Z�O�����g�P�`�W�̌����iCCID�C���f�b�N�X�p�j
    lv_tbl_nm           VARCHAR2(100);                                   -- ����Ȗڑg�����}�X�^�e�[�u��
    lv_sum_flag         VARCHAR2(1);                                     -- �W��t���O
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- ����Ȗ�CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- ����ȖڃR�[�h
--
    -- �W��L�[
    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- �W��L�[�F�[�i�`�[�敪
    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- �W��L�[�F�i�ڃR�[�h
    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                                         -- �i�ڋ敪�i���i�E���i�j
    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- �W��L�[�F�Ƒԏ�����
    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- �W��L�[�F�J�[�h����敪
    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- �W��L�[�F�ԍ��t���O
    lt_gccs_segment3    gl_code_combinations.segment3%TYPE;              -- �W��L�[�F���㊨��ȖڃR�[�h
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- �W��L�[�F�ŋ��R�[�h
    ln_amount           NUMBER DEFAULT 0;                                -- �W�����z
    ln_tax              NUMBER DEFAULT 0;                                -- �W������ŋ��z
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR��v�z���W��C���f�b�N�X
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR��v�z��OIF�C���f�b�N�X
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- �d�󐶐��J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    non_jour_cls_expt         EXCEPTION;                -- �d��p�^�[���Ȃ�
    non_ccid_expt             EXCEPTION;                -- CCID�擾�o���Ȃ��G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=====================================
    -- 1.AR��v�z���d��p�^�[���̎擾
    --=====================================
--
    -- �J�[�\���I�[�v��
    BEGIN
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
    EXCEPTION
    -- �d��p�^�[���擾���s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
    END;
    -- �d��p�^�[���擾���s�����ꍇ
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE non_jour_cls_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE jour_cls_cur;
--
    --=====================================
    -- 3.AR��v�z���f�[�^�쐬
    --=====================================
--
    -- �W��L�[�̒l�Z�b�g
    lt_invoice_number   := gt_ar_dis_sum_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_ar_dis_sum_tbl( 1 ).dlv_invoice_class;
    lt_item_code        := gt_ar_dis_sum_tbl( 1 ).item_code;
    lt_prod_cls         := gt_ar_dis_sum_tbl( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_ar_dis_sum_tbl( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_ar_dis_sum_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_ar_dis_sum_tbl( 1 ).red_black_flag;
    lt_gccs_segment3    := gt_ar_dis_sum_tbl( 1 ).gccs_segment3;
    lt_tax_code         := gt_ar_dis_sum_tbl( 1 ).gcct_segment3;
--
    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g����
    gt_ar_dis_sum_tbl( gt_ar_dis_sum_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_ar_dis_sum_tbl( gt_ar_dis_sum_tbl.COUNT ).sales_exp_header_id;
--
    <<gt_ar_dis_sum_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_ar_dis_sum_tbl.COUNT LOOP
--
      -- AR��v�z���f�[�^�W��J�n
      IF (  lt_invoice_number  = gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_number
        AND lt_invoice_class   = gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_class
        AND ( lt_item_code     = gt_ar_dis_sum_tbl( dis_sum_idx ).item_code
          OR lt_prod_cls       = gt_ar_dis_sum_tbl( dis_sum_idx ).goods_prod_cls )
        AND lt_gyotai_sho      = gt_ar_dis_sum_tbl( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_ar_dis_sum_tbl( dis_sum_idx ).card_sale_class
        AND lt_red_black_flag  = gt_ar_dis_sum_tbl( dis_sum_idx ).red_black_flag
        AND lt_gccs_segment3   = gt_ar_dis_sum_tbl( dis_sum_idx ).gccs_segment3
        AND lt_tax_code        = gt_ar_dis_sum_tbl( dis_sum_idx ).gcct_segment3
        ) THEN
--
        -- �W�񂷂�t���O�����ݒ�
        lv_sum_flag := cv_y_flag;
--
        -- �{�̋��z�Ə���Ŋz���W�񂷂�
        ln_amount := ln_amount + gt_ar_dis_sum_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_ar_dis_sum_tbl( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- -- �W��t���O�fN'�̏ꍇ�A���LAR��v�z��OIF�쐬�������s��
      IF ( lv_sum_flag = cv_n_flag ) THEN   
--
        -- �d�󐶐��J�E���g�����l
        ln_jour_cnt := 1;
--
        -- �d��p�^�[�����AR��v�z���̎d���ҏW����
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
            ) THEN
--
            -- ���̏W��ɂR���R�[�h���쐬����
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- ����Ȗڂ̕ҏW
            IF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_goods_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_prod_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_disc_msg ) THEN
              --���㊨��ȖڃR�[�h
              lt_segment3 := gt_ar_dis_sum_tbl( ln_dis_idx ).gccs_segment3;
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_tax_msg ) THEN
              --�ŋ�����ȖڃR�[�h
              lt_segment3 := gt_ar_dis_sum_tbl( ln_dis_idx ).gcct_segment3;
            ELSE
              --OTHER����ȖڃR�[�h
              lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
            END IF;
--
            --=====================================
            -- 2.����Ȗ�CCID�̎擾
            --=====================================
            -- ����ȖڃZ�O�����g�P�`�Z�O�����g�W���CCID�擾
            lv_ccid_idx := gv_company_code                                   -- �Z�O�����g�P(��ЃR�[�h)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- �Z�O�����g�Q�i����R�[�h�j
                                gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                                                                             -- �Z�O�����g�Q(�̔����т̔��㋒�_�R�[�h)
                        || lt_segment3                                       -- �Z�O�����g�R(����ȖڃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- �Z�O�����g�S(�⏕�ȖڃR�[�h:�����̂ݐݒ�)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- �Z�O�����g�T(�ڋq�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- �Z�O�����g�U(��ƃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- �Z�O�����g�V(���Ƌ敪�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- �Z�O�����g�W(�\��)
--
            -- CCID�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
                  -- CCID�擾���ʊ֐����CCID���擾����
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
                             gd_process_date
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              IF ( lt_ccid IS NULL ) THEN
                -- CCID���擾�ł��Ȃ��ꍇ
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                              );
                lv_errbuf  := lv_errmsg;
                RAISE non_ccid_expt;
              END IF;
--
              -- �擾����CCID�����[�N�e�[�u���ɐݒ肷��
              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
            END IF;                                       -- CCID�ҏW�I��
--
            --=====================================
            -- AR��v�z��OIF�f�[�^�ݒ�
            --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- ���v�s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              -- �t��VD�i�����j�ƃt��VD�ꍇ�̋��z�ҏW
              IF ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_fvd_xiaoka
                OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
                ln_amount := ln_amount + ln_tax;
              END IF;
--
              -- AR��v�z��OIF�̐ݒ荀��
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- �������DFF4:�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�F�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
                                                          -- ���z(���׋��z)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec ) THEN
              -- ���s(���z�ݒ�Ȃ�)
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- �������DFF4�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5	�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- �ŋ��s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_tax_dff4;
                                                          -- �������DFF4�F�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
                                                          -- ���z(���׋��z)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
            END IF;
--
            -- �d�󐶐��J�E���g�Z�b�g
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- �d��p�^�[������AR��v�z��OIF�f�[�^�̍쐬�����I��
--
        END LOOP gt_jour_cls_tbl_loop;                    -- �d��p�^�[�����f�[�^�쐬�����I��
--
      END IF;                                             -- �W��L�[����AR��v�z��OIF�f�[�^�̏W��I��
--
        -- �W��L�[�̃��Z�b�g
        lt_invoice_number   := gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_number;
        lt_invoice_class    := gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_class;
        lt_item_code        := gt_ar_dis_sum_tbl( dis_sum_idx ).item_code;
        lt_prod_cls         := gt_ar_dis_sum_tbl( dis_sum_idx ).goods_prod_cls;
        lt_gyotai_sho       := gt_ar_dis_sum_tbl( dis_sum_idx ).cust_gyotai_sho;
        lt_card_sale_class  := gt_ar_dis_sum_tbl( dis_sum_idx ).card_sale_class;
        lt_red_black_flag   := gt_ar_dis_sum_tbl( dis_sum_idx ).red_black_flag;
        lt_gccs_segment3    := gt_ar_dis_sum_tbl( dis_sum_idx ).gccs_segment3;
        lt_tax_code         := gt_ar_dis_sum_tbl( dis_sum_idx ).gcct_segment3;
--
        -- ���z�̐ݒ�
        ln_amount        := gt_ar_dis_sum_tbl( dis_sum_idx ).pure_amount;
        ln_tax           := gt_ar_dis_sum_tbl( dis_sum_idx ).tax_amount;
--
    END LOOP gt_ar_dis_sum_tbl_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
    WHEN non_jour_cls_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN non_ccid_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_dis_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_bulk_data
   * Description      : ��������W�񏈗��i���ʔ̓X�j(A-5)
   ***********************************************************************************/
  PROCEDURE edit_sum_bulk_data(
      ov_errbuf         OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_bulk_data';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_card_idx             NUMBER DEFAULT 0;           -- ���������J�[�h���R�[�h�̃C���f�b�N�X
    ln_card_pt              NUMBER DEFAULT 1;           -- �J�[�h���R�[�h�̃C���f�b�N�X���s�ʒu
    ln_ar_idx               NUMBER DEFAULT 0;           -- �������OIF�C���f�b�N�X
    ln_ar_bul               NUMBER DEFAULT 0;           -- AR��v�z���W��C���f�b�N�X
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
--
    lv_trx_type_nm          VARCHAR2(30);               -- ����^�C�v����
    lv_trx_idx              VARCHAR2(30);               -- ����^�C�v(�C���f�b�N�X)
    lv_item_idx             VARCHAR2(30);               -- �i�ږ��דE�v(�C���f�b�N�X)
    lv_item_desp            VARCHAR2(30);               -- �i�ږ��דE�v(TAX�ȊO)
    ln_term_id              VARCHAR2(30);               -- �x������ID
    lv_cust_gyotai_sho      VARCHAR2(30);               -- �Ƒԏ�����
    ln_pure_amount          NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̖{�̋��z
    ln_tax_amount           NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̏���ŋ��z
    ln_tax                  NUMBER DEFAULT 0;           -- �W������ŋ��z
    ln_amount               NUMBER DEFAULT 0;           -- �W�����z
    ln_tax_card             NUMBER DEFAULT 0;           -- �W������ŋ��z(�J�[�h���R�[�h)
    ln_amount_card          NUMBER DEFAULT 0;           -- �W�����z(�J�[�h���R�[�h)
    ln_sales_h_tbl_idx      NUMBER DEFAULT 0;           -- �̔����уw�b�_�X�V�p�C���f�b�N�X
    ln_trx_number_id        NUMBER;                     -- �������DFF4�p:�����̔Ԕԍ�
--
    -- �W��L�[(�̔�����)
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- �W��L�[�F�̔����уw�b�_ID
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�敪
    lt_goods_prod_cls       xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- �W��L�[�F�i�ڋ敪�i���i�E���i�j
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- �W��L�[�F�i�ڃR�[�h�i��݌Ɂj
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;
                                                        -- �W��L�[�F�J�[�h����敪
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;
                                                        -- �W��L�[�F�ԍ��t���O
--
    -- �W��L�[(���������J�[�h���R�[�h)
    lt_header_id_card       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- �W��L�[�F�̔����уw�b�_ID
    lt_invo_number_card     xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invo_class_card      xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- �W��L�[�F�[�i�`�[�敪
    lt_goods_prod_card      xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- �W��L�[�F�i�ڋ敪�R�[�h�i���i�E���i�j
    lt_item_code_card       xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- �W��L�[�F�i�ڃR�[�h�i��݌Ɂj
--
    lv_sum_flag             VARCHAR2(1);                -- �W��t���O
    lv_sum_card_flag        VARCHAR2(1);                -- �J�[�h�W��t���O
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\ ***
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
    -- ��������e�[�u���̔���ʔ̓X�f�[�^�J�E���g�Z�b�g
    ln_ar_idx := gt_ar_interface_tbl.COUNT;
--
    -- �̔����уw�b�_�X�V�p�C���f�b�N�X
    ln_sales_h_tbl_idx := gt_sales_h_tbl.COUNT;
--
    --=====================================================================
    -- �S�D�t���T�[�r�XVD�ƃt���T�[�r�X�i�����jVD�̃J�[�h�E�������p�f�[�^�̕ҏW
    --=====================================================================
    <<gt_sales_bulk_tbl_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
      -- �����E�J�[�h���p�̏ꍇ-->�J�[�h����敪=����:0 ���� �����J�[�h���p�z>0
      IF ( (   gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND (  gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = gt_cash_sale_cls
          AND  gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card   > 0 ) ) THEN
--
        -- �J�[�h���R�[�h�̖{�̋��z
        ln_pure_amount := gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card
                        / ( 1 + gt_sales_bulk_tbl( sale_bulk_idx ).tax_rate/cn_percent );
--
        -- �[������
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round    = cv_round_rule_up ) THEN
          -- �؂�グ�̏ꍇ
          ln_pure_amount := CEIL( ln_pure_amount );
--
        ELSIF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round = cv_round_rule_down ) THEN
          -- �؂艺���̏ꍇ
          ln_pure_amount := FLOOR( ln_pure_amount );
--
        ELSIF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round = cv_round_rule_nearest ) THEN
          -- �l�̌ܓ��̏ꍇ
          ln_pure_amount := ROUND( ln_pure_amount );
        END IF;
--
        -- �ېł̏ꍇ�A�J�[�h���R�[�h�̏���Ŋz���Z�o����
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax_amount := gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card - ln_pure_amount;
        ELSE
          ln_tax_amount := 0;
        END IF;
--
        --==============================================================
        --�̔����уJ�[�h���[�N�e�[�u���ւ̃J�[�h���R�[�h�o�^
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        -- �J�[�h���R�[�h�S�J�����̐ݒ�
        gt_bulk_card_tbl( ln_card_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
--
        -- �J�[�h���R�[�h�̔���敪�A�{�̋��z�A����ŋ��z�̐ݒ�
        gt_bulk_card_tbl( ln_card_idx ).card_sale_class  := cv_card_class;
                                                         -- �J�[�h����敪�i�P�F�J�[�h�j
        gt_bulk_card_tbl( ln_card_idx ).pure_amount      := ln_pure_amount;
                                                         -- �{�̋��z
        gt_bulk_card_tbl( ln_card_idx ).tax_amount       := ln_tax_amount;
                                                         -- ����ŋ��z
      END IF;
--
    END LOOP gt_sales_bulk_tbl_loop;                                   -- ���ʔ̓X���p�f�[�^�ҏW�I��
--
      --=====================================================================
      -- ��������W�񏈗��i���ʔ̓X�j�J�n
      --=====================================================================
    -- �W��L�[�̒l�Z�b�g
    lt_header_id        := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;
    lt_invoice_number   := gt_sales_bulk_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_sales_bulk_tbl( 1 ).dlv_invoice_class;
    lt_goods_prod_cls   := gt_sales_bulk_tbl( 1 ).goods_prod_cls;
    lt_item_code        := gt_sales_bulk_tbl( 1 ).item_code;
    lt_card_sale_class  := gt_sales_bulk_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_sales_bulk_tbl( 1 ).red_black_flag;
--
    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g
    gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT ).sales_exp_header_id;
    IF ( gt_bulk_card_tbl.COUNT > 0 ) THEN
      gt_bulk_card_tbl( gt_bulk_card_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_bulk_card_tbl( gt_bulk_card_tbl.COUNT ).sales_exp_header_id;
    END IF;
--
    <<gt_sales_bulk_sum_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      --=====================================
      --5-1.�̔����ь��f�[�^�̏W��
      --=====================================
      IF (  lt_header_id        = gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id
        AND lt_invoice_number   = gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
        AND lt_invoice_class    = gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class
        AND ( lt_goods_prod_cls = gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls
          OR  lt_item_code      = gt_sales_bulk_tbl( sale_bulk_idx ).item_code )
        AND lt_card_sale_class  = gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class
        AND lt_red_black_flag   = gt_sales_bulk_tbl( sale_bulk_idx ).red_black_flag
         ) THEN
--
        -- �W�񂷂�t���O�����ݒ�
        lv_sum_flag      := cv_y_flag;
        lv_sum_card_flag := cv_y_flag;
--
        -- �{�̋��z���W�񂷂�
        ln_amount := ln_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        END IF;
--
        --=====================================
        --5-2.��L4�Ő��������J�[�h���R�[�h�̏W��
        --=====================================
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = cv_card_class ) THEN
          <<gt_bulk_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_bulk_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_bulk_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_bulk_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_bulk_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_bulk_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_bulk_card_tbl( i ).item_code )
            ) THEN
              -- �{�̋��z���W�񂷂�
              ln_amount   := ln_amount + gt_bulk_card_tbl( i ).pure_amount;
              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
              IF ( gt_bulk_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax := ln_tax + gt_bulk_card_tbl( i ).tax_amount;
              END IF;
            END IF;
            -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
            ln_card_pt := i;
          END LOOP gt_bulk_card_tbl_loop;
--
        -- ���������J�[�h���R�[�h�����̏W��
        ELSIF ( ( gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = gt_cash_sale_cls
          AND gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card > 0
          AND ln_card_pt < gt_bulk_card_tbl.COUNT
          ) THEN
          ln_amount_card := 0;
          ln_tax_card  := 0;
--
          -- ���������J�[�h���R�[�h�����̏W��J�n
          FOR i IN ln_card_pt .. gt_bulk_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_bulk_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_bulk_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_bulk_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_bulk_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_bulk_card_tbl( i ).item_code )
            ) THEN
              -- �{�̋��z���W�񂷂�
              ln_amount_card := ln_amount_card + gt_bulk_card_tbl( i ).pure_amount;
              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
              IF ( gt_bulk_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax_card  := ln_tax_card + gt_bulk_card_tbl( i ).tax_amount;
              END IF;
            ELSE
              -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
              ln_card_pt := i;
              -- �W��t���O�fN'��ݒ�
              lv_sum_card_flag := cv_n_flag;
            END IF;
--
          END LOOP gt_bulk_card_tbl_loop;
--
        END IF; -- ���������J�[�h���R�[�h�����̏W��I��
      ELSE
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_bulk_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
      --=====================================================================
        -- �P�D�x������ID�̎擾
        --=====================================================================
        IF ( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                   , cv_substr_st, cv_substr_cnt )
             <= gt_sales_bulk_tbl( ln_trx_idx ).rtt1_term_dd1 ) THEN
          -- �x������ ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_bulk_tbl( ln_trx_idx ).rtt1_term_dd1
           AND SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_bulk_tbl( ln_trx_idx ).rtt2_term_dd2 ) THEN
          -- ��2�x������ ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id2;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_bulk_tbl( ln_trx_idx ).rtt2_term_dd2
           AND SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_bulk_tbl( ln_trx_idx ).rtt3_term_dd3 ) THEN
          -- ��3�x������ ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id3;
--
        ELSE
          -- �x������ID�̎擾���ł��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_term_id_msg
                      );
          lv_errbuf  := lv_errmsg;
--
          RAISE global_term_id_expt;
        END IF;
--
        --=====================================================================
        -- �Q�D����^�C�v�̎擾
        --=====================================================================
        lv_trx_idx := gt_sales_bulk_tbl( ln_trx_idx ).create_class
                   || gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
        ELSE
          BEGIN
            SELECT flvm.attribute1 || flvd.attribute1
            INTO   lv_trx_type_nm
            FROM   fnd_lookup_values              flvm                     -- �쐬���敪����}�X�^
                 , fnd_lookup_values              flvd                     -- �[�i�`�[�敪����}�X�^
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_bulk_tbl( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
              AND  flvm.language                  = USERENV( 'LANG' )
              AND  flvd.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ����^�C�v�擾�o���Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                         );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- �擾��������^�C�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
--
        END IF;
--
        --=====================================================================
        -- 3�D�i�ږ��דE�v�̎擾(�u�������œ��v�ȊO)
        --=====================================================================
--
        -- �i�ږ��דE�v�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls IS NULL ) THEN
          lv_item_idx := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_bulk_tbl( ln_trx_idx ).item_code;
        ELSE
          lv_item_idx := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls;
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR�i�ږ��דE�v����}�X�^
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls,
                                                         gt_sales_bulk_tbl( ln_trx_idx ).item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
              AND  flvi.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR�i�ږ��דE�v�擾�o���Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
--
        END IF;
      END IF;
--
      --==============================================================
      -- �U�DAR�������OIF�f�[�^�쐬
      --==============================================================
--
      -- �W��t���O�fN'�̏ꍇ�AAR�������OIF�f�[�^�쐬����
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- AR�������OIF�̎��v�s
        ln_ar_idx := ln_ar_idx + 1;
        ln_ar_bul := ln_ar_bul + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR��v�z���W��p�f�[�^�i�[(BULK)
        gt_ar_dis_bul_tbl( ln_ar_bul ).sales_exp_header_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �̔����уw�b�_ID
        gt_ar_dis_bul_tbl( ln_ar_bul ).dlv_invoice_number
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �[�i�`�[�ԍ�
        gt_ar_dis_bul_tbl( ln_ar_bul ).interface_line_dff4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �����̔�
        gt_ar_dis_bul_tbl( ln_ar_bul ).dlv_invoice_class
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class;
                                                        -- �[�i�`�[�敪
        gt_ar_dis_bul_tbl( ln_ar_bul ).item_code        := gt_sales_bulk_tbl( ln_trx_idx ).item_code;
                                                        -- �i�ڃR�[�h
        gt_ar_dis_bul_tbl( ln_ar_bul ).goods_prod_cls   := gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls;
                                                        -- �i�ڋ敪�i���i�E���i�j
        -- �Ƒԏ����ނ̕ҏW
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
          OR gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_gyotai_fvd
          OR gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_vd_xiaoka ) THEN
          lv_cust_gyotai_sho := cv_nvd;                 -- VD�ȊO�̋ƑԁE�[�iVD
        ELSE
          lv_cust_gyotai_sho := gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho;
                                                        -- �t��(����)VD�E�t��VD�E����VD
        END IF;
        gt_ar_dis_bul_tbl( ln_ar_bul ).cust_gyotai_sho  := lv_cust_gyotai_sho;
                                                        -- �Ƒԏ�����
        gt_ar_dis_bul_tbl( ln_ar_bul ).sales_base_code  := gt_sales_bulk_tbl( ln_trx_idx ).sales_base_code;
                                                        -- ���㋒�_�R�[�h
        gt_ar_dis_bul_tbl( ln_ar_bul ).card_sale_class  := gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class;
                                                        -- �J�[�h����敪
        gt_ar_dis_bul_tbl( ln_ar_bul ).red_black_flag   := gt_sales_bulk_tbl( ln_trx_idx ).red_black_flag;
                                                        -- �ԍ��t���O
        gt_ar_dis_bul_tbl( ln_ar_bul ).gccs_segment3    := gt_sales_bulk_tbl( ln_trx_idx ).gccs_segment3;
                                                        -- ���㊨��ȖڃR�[�h
        gt_ar_dis_bul_tbl( ln_ar_bul ).pure_amount      := ln_amount;
                                                        -- �W���{�̋��z
        gt_ar_dis_bul_tbl( ln_ar_bul ).gcct_segment3    := gt_sales_bulk_tbl( ln_trx_idx ).gcct_segment3;
                                                        -- �ŋ�����ȖڃR�[�h(�������œ�)
        gt_ar_dis_bul_tbl( ln_ar_bul ).tax_amount       := ln_tax;
                                                        -- �W���{�̋��z
--
        -- AR�������OIF�f�[�^�쐬(���v�s)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
                                                        -- ���v�s�F�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := TO_CHAR( ln_trx_number_id );
                                                        -- ���v�s�̂݁FAR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_bulk_tbl( ln_trx_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gv_busi_dept_cd;
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gv_busi_emp_cd;
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).receiv_base_code;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR��v�z���W��p�f�[�^�i�[(BULK)
        gt_ar_dis_bul_tbl( ln_ar_bul ).interface_tax_dff4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �����̔�
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��id
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
      END IF;
--
      -- -- �J�[�h�W��t���O�fN'�̏ꍇ�A�J�[�h��AR�������OIF�f�[�^�쐬����
      IF ( lv_sum_card_flag = cv_n_flag AND ln_amount_card > 0 ) THEN   
        -- AR�������OIF�̎��v�s
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_card_idx := ln_card_pt - 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        --  AR�������OIF�f�[�^�쐬(���v�s)===>NO.3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount_card;
                                                        -- ���v�s�F�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_bulk_card_tbl( ln_card_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_bulk_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := TO_CHAR( ln_trx_number_id );
                                                        -- AR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_bulk_card_tbl( ln_card_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount_card;
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_bulk_card_tbl( ln_card_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gv_busi_dept_cd;
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gv_busi_emp_cd;
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_bulk_card_tbl( ln_card_idx ).receiv_base_code;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.4
        ln_ar_idx := ln_ar_idx + 1;
--
        -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax_card;
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v�i�uUser�v��ݒ�j
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g�i1 ��ݒ�j
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_bulk_card_tbl( ln_card_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_bulk_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_bulk_card_tbl( ln_card_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
        -- �W��t���O�̃��Z�b�g
        lv_sum_card_flag := cv_y_flag;
        ln_amount_card := 0;
--
      END IF;                                           -- �W��L�[����AR OIF�f�[�^�̏W��I��
--
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- �W��L�[�ƏW����z�̃��Z�b�g
        lt_header_id       := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;
        lt_invoice_number  := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number;
        lt_invoice_class   := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class;
        lt_goods_prod_cls  := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
        lt_item_code       := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        lt_card_sale_class := gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class;
        lt_red_black_flag  := gt_sales_bulk_tbl( sale_bulk_idx ).red_black_flag;
        lv_sum_card_flag := cv_y_flag;
--
        ln_amount := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
      -- �̔����уw�b�_�X�V�̂��߁FROWID�̐ݒ�
      ln_sales_h_tbl_idx                   := ln_sales_h_tbl_idx + 1;
      gt_sales_h_tbl( ln_sales_h_tbl_idx ) := gt_sales_bulk_tbl( sale_bulk_idx ).xseh_rowid;
--
    END LOOP gt_sales_bulk_sum_loop;                    -- �̔����уf�[�^���[�v�I��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_bulk_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_bulk_data
   * Description      : AR��v�z���d��쐬�i���ʔ̓X�j(A-6)
   ***********************************************************************************/
  PROCEDURE edit_dis_bulk_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_bulk_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_ccid_idx         VARCHAR2(225);                                   -- �Z�O�����g�P0�W�̌����iCCID�C���f�b�N�X�p�j
    lv_tbl_nm           VARCHAR2(100);                                   -- ����Ȗڑg�����}�X�^�e�[�u��
    lv_sum_flag         VARCHAR2(1);                                     -- �W��t���O
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- ����Ȗ�CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- ����ȖڃR�[�h
--
    -- �W��L�[
    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- �W��L�[�F�[�i�`�[�ԍ�
    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- �W��L�[�F�[�i�`�[�敪
    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- �W��L�[�F�i�ڃR�[�h
    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                                         -- �i�ڋ敪�i���i�E���i�j
    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- �W��L�[�F�Ƒԏ�����
    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- �W��L�[�F�J�[�h����敪
    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- �W��L�[�F�ԍ��t���O
    lt_gccs_segment3    gl_code_combinations.segment3%TYPE;              -- �W��L�[�F���㊨��ȖڃR�[�h
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- �W��L�[�F�ŋ��R�[�h
    ln_amount           NUMBER DEFAULT 0;                                -- �W�����z
    ln_tax              NUMBER DEFAULT 0;                                -- �W������ŋ��z
    ln_ar_dis_bul       NUMBER DEFAULT 0;                                -- AR��v�z���W��C���f�b�N�X
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR��v�z��OIF�C���f�b�N�X
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- �d�󐶐��J�E���g
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    non_jour_cls_expt         EXCEPTION;                -- �d��p�^�[���Ȃ�
    non_ccid_expt             EXCEPTION;                -- CCID�擾�o���Ȃ��G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- AR��v�z���e�[�u���̔���ʔ̓X�f�[�^�J�E���g�Z�b�g
    ln_ar_dis_bul := gt_ar_dis_tbl.COUNT;
--
    --=====================================
    -- 1.AR��v�z���d��p�^�[���̎擾
    --=====================================
--
    -- �d��p�^�[���擾����ĂȂ��ꍇ
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
     -- �J�[�\���I�[�v��
      BEGIN
        OPEN  jour_cls_cur;
        FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
      EXCEPTION
      -- �d��p�^�[���擾���s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcos_short_nm
                           , iv_name         => cv_jour_nodata_msg
                           , iv_token_name1  => cv_tkn_lookup_type
                           , iv_token_value1 => cv_qct_jour_cls
                         );
          lv_errbuf := lv_errmsg;
          RAISE non_jour_cls_expt;
      END;
      -- �d��p�^�[���擾���s�����ꍇ
      IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
      END IF;
--
      -- �J�[�\���N���[�Y
      CLOSE jour_cls_cur;
    END IF;
--
    --=====================================
    -- 3.AR��v�z���f�[�^�쐬
    --=====================================
--
    -- �W��L�[�̒l�Z�b�g
    lt_invoice_number   := gt_ar_dis_bul_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_ar_dis_bul_tbl( 1 ).dlv_invoice_class;
    lt_item_code        := gt_ar_dis_bul_tbl( 1 ).item_code;
    lt_prod_cls         := gt_ar_dis_bul_tbl( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_ar_dis_bul_tbl( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_ar_dis_bul_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_ar_dis_bul_tbl( 1 ).red_black_flag;
    lt_gccs_segment3    := gt_ar_dis_bul_tbl( 1 ).gccs_segment3;
    lt_tax_code         := gt_ar_dis_bul_tbl( 1 ).gcct_segment3;
--
    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g����
    gt_ar_dis_bul_tbl( gt_ar_dis_bul_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_ar_dis_bul_tbl( gt_ar_dis_bul_tbl.COUNT ).sales_exp_header_id;
--
    <<gt_ar_dis_bul_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_ar_dis_bul_tbl.COUNT LOOP
--
      -- AR��v�z���f�[�^�W��J�n(����)
      IF (  lt_invoice_number  = gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_number
        AND lt_invoice_class   = gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_class
        AND ( lt_item_code     = gt_ar_dis_bul_tbl( dis_sum_idx ).item_code
          OR lt_prod_cls       = gt_ar_dis_bul_tbl( dis_sum_idx ).goods_prod_cls )
        AND lt_gyotai_sho      = gt_ar_dis_bul_tbl( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_ar_dis_bul_tbl( dis_sum_idx ).card_sale_class
        AND lt_red_black_flag  = gt_ar_dis_bul_tbl( dis_sum_idx ).red_black_flag
        AND lt_gccs_segment3   = gt_ar_dis_bul_tbl( dis_sum_idx ).gccs_segment3
        AND lt_tax_code        = gt_ar_dis_bul_tbl( dis_sum_idx ).gcct_segment3
        ) THEN
        -- �W�񂷂�t���O�����ݒ�
        lv_sum_flag := cv_y_flag;
--
        -- �{�̋��z�Ə���Ŋz���W�񂷂�
        ln_amount := ln_amount + gt_ar_dis_bul_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_ar_dis_bul_tbl( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- �W��t���O�fN'�̏ꍇ�A���LAR��v�z��OIF�쐬�������s��
      IF ( lv_sum_flag = cv_n_flag ) THEN   
--
        -- �d�󐶐��J�E���g�����l
        ln_jour_cnt := 1;
--
        -- �d��p�^�[�����AR��v�z���̎d���ҏW����
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
            ) THEN
--
            -- ���̏W��ɂR���R�[�h���쐬����
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- ����Ȗڂ̕ҏW
            IF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_goods_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_prod_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_disc_msg ) THEN
              --���㊨��ȖڃR�[�h
              lt_segment3 := gt_ar_dis_bul_tbl( ln_dis_idx ).gccs_segment3;
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_tax_msg ) THEN
              --�ŋ�����ȖڃR�[�h
              lt_segment3 := gt_ar_dis_bul_tbl( ln_dis_idx ).gcct_segment3;
            ELSE
              --OTHER����ȖڃR�[�h
              lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
            END IF;
--
            --=====================================
            -- 2.����Ȗ�CCID�̎擾
            --=====================================
            -- ����ȖڃZ�O�����g�P�`�Z�O�����g�W���CCID�擾
            lv_ccid_idx := gv_company_code                                   -- �Z�O�����g�P(��ЃR�[�h)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- �Z�O�����g�Q�i����R�[�h�j
                                gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                                                                             -- �Z�O�����g�Q(�̔����т̔��㋒�_�R�[�h)
                        || lt_segment3                                       -- �Z�O�����g�R(����ȖڃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- �Z�O�����g�S(�⏕�ȖڃR�[�h:�����̂ݐݒ�)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- �Z�O�����g�T(�ڋq�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- �Z�O�����g�U(��ƃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- �Z�O�����g�V(���Ƌ敪�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- �Z�O�����g�W(�\��)
--
            -- CCID�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
              -- CCID�擾���ʊ֐����CCID���擾����
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
                             gd_process_date
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
              IF ( lt_ccid IS NULL ) THEN
                -- CCID���擾�ł��Ȃ��ꍇ
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                              );
                lv_errbuf  := lv_errmsg;
                RAISE non_ccid_expt;
              END IF;
--
              -- �擾����CCID�����[�N�e�[�u���ɐݒ肷��
              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
            END IF;                                       -- CCID�ҏW�I��
--
          --=====================================
          -- AR��v�z��OIF�f�[�^�ݒ�
          --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- ���v�s
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
--
              -- �t��VD�i�����j�ƃt��VD�ꍇ�̋��z�ҏW
              IF ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_fvd_xiaoka
                OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
                ln_amount := ln_amount + ln_tax;
              END IF;
--
              -- AR��v�z��OIF�̐ݒ荀��
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l:�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- �������DFF4:�����̔�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7:�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_rev;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_bul ).amount       := ln_amount;
                                                          -- ���z(���׋��z)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����):100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec ) THEN
              -- ���s(���z�ݒ�Ȃ�)
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g:�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3:�[�i�`�[�ԍ����Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- �������DFF4:�����̔�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_rec;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- �ŋ��s
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l:�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_tax_dff4;
                                                          -- �������DFF4:�����̔�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5:�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_tax;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_bul ).amount       := ln_tax;
                                                          -- ���z(���׋��z)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����):100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
            END IF;
--
            -- �d�󐶐��J�E���g�Z�b�g
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- �d��p�^�[������AR��v�z��OIF�f�[�^�̍쐬�����I��
--
        END LOOP gt_jour_cls_tbl_loop;                    -- �d��p�^�[�����f�[�^�쐬�����I��
--
      END IF;                                             -- �W��L�[����AR��v�z��OIF�f�[�^�̏W��I��
        -- �W��L�[�̃��Z�b�g
        lt_invoice_number   := gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_number;
        lt_invoice_class    := gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_class;
        lt_item_code        := gt_ar_dis_bul_tbl( dis_sum_idx ).item_code;
        lt_prod_cls         := gt_ar_dis_bul_tbl( dis_sum_idx ).goods_prod_cls;
        lt_gyotai_sho       := gt_ar_dis_bul_tbl( dis_sum_idx ).cust_gyotai_sho;
        lt_card_sale_class  := gt_ar_dis_bul_tbl( dis_sum_idx ).card_sale_class;
        lt_red_black_flag   := gt_ar_dis_bul_tbl( dis_sum_idx ).red_black_flag;
        lt_gccs_segment3    := gt_ar_dis_bul_tbl( dis_sum_idx ).gccs_segment3;
        lt_tax_code         := gt_ar_dis_bul_tbl( dis_sum_idx ).gcct_segment3;
--
        -- ���z�̐ݒ�
        ln_amount := gt_ar_dis_bul_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := gt_ar_dis_bul_tbl( dis_sum_idx ).tax_amount;
--
    END LOOP gt_ar_dis_bul_tbl_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
    WHEN non_jour_cls_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN non_ccid_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_dis_bulk_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_aroif_data
   * Description      : AR�������OIF�o�^����(A-7)
   ***********************************************************************************/
  PROCEDURE insert_aroif_data(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_aroif_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
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
    --==============================================================
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_ar_interface_tbl.COUNT
        INSERT INTO
          ra_interface_lines_all
        VALUES
          gt_ar_interface_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- �A�v���Z�k��
                      , iv_name              => cv_tkn_aroif_msg       -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2       => cv_tkn_key_data
                      , iv_token_value2      => cv_blank
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_aroif_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_ardis_data
   * Description      : AR��v�z��OIF�o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE insert_ardis_data(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ardis_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
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
    --==============================================================
    -- AR��v�z��OIF�e�[�u���փf�[�^�o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_ar_dis_tbl.COUNT
        INSERT INTO
          ra_interface_distributions_all
        VALUES
          gt_ar_dis_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- �A�v���Z�k��
                      , iv_name              => cv_tkn_ardis_msg       -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => cv_blank
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_ardis_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_data
   * Description      : �̔����уw�b�_�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf         OUT VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'upd_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �̔����уw�b�_�X�V����
    --==============================================================
--
    -- �����Ώۃf�[�^�̃C���^�t�F�[�X�σt���O���ꊇ�X�V����
    BEGIN
      <<update_interface_flag>>
      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
        UPDATE
          xxcos_sales_exp_headers       xseh
        SET
          xseh.ar_interface_flag      = cv_y_flag,                     -- AR�C���^�t�F�[�X�σt���O
          xseh.last_updated_by        = cn_last_updated_by,            -- �ŏI�X�V��
          xseh.last_update_date       = cd_last_update_date,           -- �ŏI�X�V��
          xseh.last_update_login      = cn_last_update_login,          -- �ŏI�X�V���O�C��
          xseh.request_id             = cn_request_id,                 -- �v��ID
          xseh.program_application_id = cn_program_application_id,     -- �R���J�����g�E�v���O�����E�A�v��ID
          xseh.program_id             = cn_program_id,                 -- �R���J�����g�E�v���O����ID
          xseh.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
        WHERE
          xseh.rowid                  = gt_sales_h_tbl( i );           -- �̔�����ROWID
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_update_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_update_data_expt THEN
      -- �X�V�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      gn_error_cnt := gn_target_cnt;
      lv_tbl_nm    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_tkn_sales_msg
                     );
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
  (
      ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    gn_target_cnt    := 0;                  -- �Ώی���
    gn_normal_cnt    := 0;                  -- ���팏��
    gn_error_cnt     := 0;                  -- �G���[����
    gn_aroif_cnt     := 0;                  -- AR�������OIF�o�^����
    gn_ardis_cnt     := 0;                  -- AR��v�z��OIF�o�^����

--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�̔����уf�[�^�擾
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF (  lv_retcode = cv_status_warn ) THEN
      -- �̔����уf�[�^���o��0�����́A���o���R�[�h�Ȃ��x���ŏI��
      RAISE global_no_data_expt;
    END IF;
--
      -- ===============================
      -- A-3.��������W�񏈗��i����ʔ̓X�j
      -- ===============================
    IF ( gt_sales_norm_tbl.COUNT > 0 ) THEN
      edit_sum_data(
           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-4.AR��v�z���d��쐬�i����ʔ̓X�j
      -- ===============================
    IF ( gt_ar_dis_sum_tbl.COUNT > 0 ) THEN
      edit_dis_data(
           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-5.AR����������W�񏈗��i���ʔ̓X�j
      -- ===============================
    IF ( gt_sales_bulk_tbl.COUNT > 0 ) THEN
      edit_sum_bulk_data(
           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-6.AR��v�z���d��쐬�i���ʔ̓X�j
      -- ===============================
    IF ( gt_ar_dis_bul_tbl.COUNT > 0 ) THEN
      edit_dis_bulk_data(
           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-7.AR�������OIF�o�^����
    -- ===============================
    insert_aroif_data(
          ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
        , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_insert_data_expt;
    END IF;
--
    -- ===============================
    -- A-8.AR��v�z��OIF�o�^����
    -- ===============================
    insert_ardis_data(
          ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
        , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_insert_data_expt;
    END IF;
--
    -- ===============================
    -- A-9.�̔����уf�[�^�̍X�V����
    -- ===============================
    upd_data(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_update_data_expt;
    END IF;
--
    -- �����������Z�b�g
    gn_aroif_cnt  := gt_ar_interface_tbl.COUNT;                      -- AR�������OIF�o�^����
    gn_ardis_cnt  := gt_ar_dis_tbl.COUNT;                            -- AR��v�z��OIF�o�^����
    gn_normal_cnt := gn_aroif_cnt + gn_ardis_cnt;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�Ȃ� *** 
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �f�[�^�擾��O *** 
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �o�^������O ***
    WHEN global_insert_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �X�V������O ***
    WHEN global_update_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20) := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- A-7.�I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��:AR�������OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_aroif_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_aroif_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��:AR��v�z��OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_ardis_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_ardis_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS013A01C;
/
