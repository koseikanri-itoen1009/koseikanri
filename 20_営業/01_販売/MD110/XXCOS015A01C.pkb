CREATE OR REPLACE PACKAGE BODY XXCOS015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS015A01C(body)
 * Description      : ���n�V�X�e�������̔����уf�[�^�̍쐬���s��
 * MD.050           : ���n�V�X�e�������̔����уf�[�^�̍쐬 MD050_COS_015_A01
 * Version          : 2.4
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  get_external_code           �ڋq�ɕR�t�������R�[�h�擾
 *  edit_sales_amount           ������z�̕ҏW
 *  init                        ��������(A-1)
 *  file_open                   �t�@�C���I�[�v��(A-2)
 *  get_sales_actual_data       �̔����уf�[�^���o(A-3)
 *  output_for_seles_actual     �������CSV�쐬(A-4)
 *  get_ar_deal_info            AR������f�[�^���o(A-5)
 *  output_for_ar_deal          �������CSV�쐬(AR������)(A-6)
 *  update_sales_header_status  ������уw�b�_�X�e�[�^�X�X�V(A-7)
 *  file_colse                  �t�@�C���N���[�Y(A-8)
 *  expt_proc                   ��O����(A-9)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.0   K.Atsushiba      �V�K�쐬
 *  2009/02/09    1.1   K.Atsushiba      ��݌ɕi�ڂ̐��ʑΉ�
 *                1.2   K.Atsushiba      ���|�������Ή��iAR����j
 *                                          �E����������Q�Ƃ��āu���̔���v�A�u�C���V���b�v����v�ł���ΑΏ�
 *                                          �E�������񂪎Q�Ƃł��Ȃ��ꍇ�A�o�א�ڋq(�����v�Z�Ώیڋq)�̋Ƒԏ�����
 *                                            ���A�u�C���V���b�v�v�A�u���В��c�X�v�ł���ΑΏ�
 *  2009/02/13    1.3   K.Atsushiba      CSV�̏o�͐���f�B���N�g���E�I�u�W�F�N�g�ɕύX
 *  2009/02/16    1.4   K.Atsushiba      SCS_075 �Ή�
 *                1.5   K.Atsushiba      SCS_077 �Ή�
 *  2009/02/17    1.6   K.Atsushiba      SCS_086 �Ή�
 *                1.7   K.Atsushiba      get_msg�̃p�b�P�[�W���C��
 *                1.8   K.Atsushiba      SCS_093 �Ή�
 *  2009/02/19    1.9   K.Atsushiba      SCS_104 �Ή� �����v�Z�̍��`�A�g
 *  2009/02/20    2.0   K.Atsushiba      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/25    2.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/03/30    2.2   N.Maeda          �yST��QT1-0035�Ή��Ή��z
 *                                       �̔����уf�[�^���o���A���L���e�f�[�^�����̍폜
 *                                       �E����f�[�^(����^�C�v�u���|�������v(����񂠂�)) 
 *                                       �E����f�[�^(����^�C�v�u���|�������v(�����Ȃ�)) 
 *                                       �yST��QT1-0187�Ή��Ή��z
 *                                       �E�����\����̃t�H�[�}�b�g���uYYYY/MM/DD�v����uYYYYMMDD�v�ɕύX����B
 *                                       �E�ȉ��̍��ڂ��_�u���N�H�[�e�[�V�����ň͂�
 *                                         ��ЃR�[�h,�`�[�ԍ�,�ڋq�R�[�h,���i�R�[�h,�����R�[�h,
 *                                         �g�^�b,���㋒�_�R�[�h,���ю҃R�[�h,�J�[�h����敪,
 *                                         �[�i���_�R�[�h,����ԕi�敪,����敪,�[�i�`�ԋ敪,
 *                                         �R����No,����ŋ敪(�ŃR�[�h?),������ڋq�R�[�h,
 *  2009/04/23    2.3   T.Kitajima       [T1_0727]1.H/C��NULL��[1]�̕ϊ��Ή�
 *                                                2.������z�A����ŋ��z�[������
 *                                                3.�R����No��NULL��[00]�̕ϊ�
 *                                                4.�[�i�P���ϊ�
 *                                                5.������ڋq�R�[�h��["]�Ŋ���(�J�[�h)�B
 *                                                6.�R���J�����g�o�͂̌���
 *  2009/05/21    2.4   S.Kayahara       [T1_1060]�������CSV�쐬(A-4)�ɎQ�ƃ^�C�v�i�[�i�`�[�敪����}�X�^�j�擾�����ǉ�
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOS015A01C';       -- �p�b�P�[�W��
  cv_xxcos_short_name         CONSTANT VARCHAR2(10)  := 'XXCOS';              -- �A�v���P�[�V�����Z�k��:XXCOS
  cv_xxccp_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';              -- �A�v���P�[�V�����Z�k��:XXCCP
  cv_xxcoi_short_name         CONSTANT VARCHAR2(10)  := 'XXCOI';              -- �A�v���P�[�V�����Z�k��:XXCOI
  -- ���b�Z�[�W
  cv_msg_non_parameter        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- ���͍��ڂȂ�
  cv_msg_lock_error           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ���b�N�G���[
  cv_msg_notfound_data        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    -- �����Ώۃf�[�^�Ȃ�
  cv_msg_notfound_profile     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[
  cv_msg_file_open_error      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    -- �t�@�C���I�[�v���G���[
  cv_msg_update_error         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- �f�[�^�X�V�G���[
  cv_msg_data_extra_error     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[
  cv_msg_non_business_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[
  cv_msg_file_name            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    -- �t�@�C����
  cv_msg_org_id               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- �c�ƒP��
  cv_msg_sales_header         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13302';    -- �̔����уw�b�_
  cv_msg_sales_line           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13303';    -- �̔�����
  cv_msg_ar_deal              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13304';    -- AR������
  cv_msg_mk_org_cls           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13305';    -- �쐬���敪����}�X�^�擾�G���[
  cv_msg_card_sale_class      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13306';    -- �J�[�h���敪�擾�G���[
  cv_msg_hc_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13307';    -- H/C�敪�擾�G���[
  cv_msg_dlv_slp_cls          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13308';    -- �[�i�`�[�敪����}�X�^�擾�G���[
  cv_msg_zyoho_file_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13309';    -- ���n������уt�@�C����
  cv_msg_outbound_dir         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13310';    -- ���n�f�B���N�g���p�X
  cv_msg_elec_fee_item_code   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13311';    -- �ϓ��d�C���i�ڃR�[�h
  cv_msg_company_code         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13312';    -- ��ЃR�[�h
  cv_msg_mk_org_cls_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13313';    -- �쐬������敪
  cv_msg_card_sales_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13314';    -- �J�[�h���敪
  cv_msg_hc_class_name        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13315';    -- H/C�敪
  cv_msg_ar_txn_name          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13316';    -- ����^�C�v����}�X�^
  cv_msg_notfound_ar_deal     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13317';    -- AR����f�[�^�Ȃ�
  cv_msg_non_item             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13318';    -- ��݌ɕi��
  cv_msg_book_id              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13319';    -- ��v����ID
  cv_msg_dlv_ptn_cls          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13320';    -- �[�i�`�ԋ敪
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  cv_msg_count                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13321';    -- �������b�Z�[�W
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';               -- �e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- �L�[����
  cv_tkn_table_name           CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- �e�[�u����
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- �t�@�C����
  cv_tkn_count                CONSTANT VARCHAR2(20) := 'COUNT';               -- ����
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';         -- �Q�ƃ^�C�v
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';             -- �Ӗ�
  cv_tkn_attribute1           CONSTANT VARCHAR2(20) := 'ATTRIBUTE1';          -- ����
  cv_tkn_attribute2           CONSTANT VARCHAR2(20) := 'ATTRIBUTE2';          -- ����2
  cv_tkn_attribute3           CONSTANT VARCHAR2(20) := 'ATTRIBUTE3';          -- ����3
  cv_tkn_account_name         CONSTANT VARCHAR2(20) := 'ACCOUNT_NAME';        -- �ڋq��
  cv_tkn_account_id           CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';          -- �ڋqID
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  cv_tkn_count_1              CONSTANT VARCHAR2(20) := 'COUNT1';              -- ����1
  cv_tkn_count_2              CONSTANT VARCHAR2(20) := 'COUNT2';              -- ����2
  cv_tkn_count_3              CONSTANT VARCHAR2(20) := 'COUNT3';              -- ����3
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
  -- �v���t�@�C��
  cv_pf_output_directory      CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_ZYOHO_DIR';        -- �f�B���N�g���p�X
  cv_pf_company_code          CONSTANT VARCHAR2(50) := 'XXCOI1_COMPANY_CODE';              -- ��ЃR�[�h
  cv_pf_csv_file_name         CONSTANT VARCHAR2(50) := 'XXCOS1_ZYOHO_FILE_NAME';           -- ������уt�@�C����
  cv_pf_org_id                CONSTANT VARCHAR2(50) := 'ORG_ID';                           -- MO:�c�ƒP��
  cv_pf_var_elec_item_cd      CONSTANT VARCHAR2(50) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';    -- �ϓ��d�C�i�ڃR�[�h
  cv_pro_bks_id               CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_pf_sls_calc_dlv_ptn_cls  CONSTANT VARCHAR2(40) := 'XXCOS1_PROD_SLS_CALC_DLV_PTN_CLS'; -- �[�i�`�ԋ敪
  -- �Q�ƃ^�C�v
  cv_ref_t_mk_org_cls_mst     CONSTANT VARCHAR2(50) := 'XXCOS1_MK_ORG_CLS_MST_015_A01';   -- �쐬������敪�}�X�^
  cv_ref_t_dlv_slp_cls_mst    CONSTANT VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_015_A01';  -- �[�i�`�[�敪����}�X�^
  cv_ref_t_card_sale_class    CONSTANT VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';          -- �J�[�h���敪
  cv_ref_t_hc_class           CONSTANT VARCHAR2(50) := 'XXCOS1_HC_CLASS';                 -- H/C�敪
  cv_ref_t_txn_type_mst       CONSTANT VARCHAR2(50) := 'XXCOS1_AR_TXN_TYPE_MST_015_A01';  -- ����^�C�v����}�X�^
  cv_non_inv_item_mst_t       CONSTANT VARCHAR2(50) := 'XXCOS1_NO_INV_ITEM_CODE';         -- ��݌ɕi��
  cv_gyotai_sho_mst_t         CONSTANT VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_004_A01';   -- �Ƒԋ敪
  cv_gyotai_sho_mst_c         CONSTANT VARCHAR2(50) := 'XXCOS_004_A01%';                  -- �Ƒԋ敪
  cv_txn_type_01              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_01';                -- ���̔���
--  cv_txn_type_02              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_02';                -- �ݼ���ߔ���
--  cv_txn_type_03              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_03';                -- ���|������*/
  cv_txn_sales_type           CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_%';                 -- ����^�C�v
  -- ���t�t�H�[�}�b�g
--  cv_date_format              CONSTANT VARCHAR2(20) := 'YYYY/MM/DD';
  cv_date_format_non_sep      CONSTANT VARCHAR2(20) := 'YYYYMMDD';
  cv_datetime_format          CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';
  -- �؎̂Ď��ԗv�f
  cv_trunc_fmt                CONSTANT VARCHAR2(2) := 'MM';
  -- �L�������t���O
  cv_enabled_flag             CONSTANT VARCHAR2(1) := 'Y';             -- �L��
  -- NULL���̑�֒l
  cv_def_article_code         CONSTANT VARCHAR2(10) := '0000000000';   -- �����R�[�h
  cv_def_results_employee_cd  CONSTANT VARCHAR2(10) := '00000';        -- ���ю҃R�[�h
  cv_def_card_sale_class      CONSTANT VARCHAR2(1)  := '0';            -- �J�[�h����敪
  cv_def_column_no            CONSTANT VARCHAR2(2)  := '00';           -- �R����No
  cv_def_delivery_base_code   CONSTANT VARCHAR2(4)  := '0000';         -- �[�i���_�R�[�h
  cn_non_sales_quantity       CONSTANT NUMBER  := 0;                   -- ���㐔��
  cn_non_std_unit_price       CONSTANT NUMBER  := 0;                   -- �[�i�P��
  cn_non_cash_and_card        CONSTANT NUMBER  := 0;                   -- �����E�J�[�h���p�z
  -- ���׃^�C�v
  cv_line_type_line           CONSTANT VARCHAR2(5) := 'LINE';          -- ����
  cv_line_type_tax            CONSTANT VARCHAR2(5) := 'TAX';           -- �ŋ�
  -- ����敪
  cv_account_class_profit     CONSTANT VARCHAR2(3) := 'REV';           -- ���v
  -- ����
  cv_blank                    CONSTANT VARCHAR2(1)  := '';             -- �u�����N
  cv_flag_no                  CONSTANT VARCHAR2(1)  := 'N';            -- �t���O:No
  cv_delimiter                CONSTANT VARCHAR2(1)  := ',';            -- �f���~�^
  cv_val_y                    CONSTANT VARCHAR2(1)  := 'Y';            -- �l�FY
  cv_d_cot                    CONSTANT VARCHAR2(1)  := '"';            -- �_�u���N�H�[�e�[�V����
  -- �g�p�ړI
  cv_site_ship_to             CONSTANT VARCHAR2(10) := 'SHIP_TO';      -- �o�א�
  cv_site_bill_to             CONSTANT VARCHAR2(10) := 'BILL_TO';      -- ������
--****************************** 2009/04/23 2.3 1 T.Kitajima ADD START ******************************--
  -- H/C
  cv_h_c_cold                 CONSTANT VARCHAR2(1) := '1';             -- COLD
  cv_h_c_hot                  CONSTANT VARCHAR2(1) := '3';             -- HOT
--****************************** 2009/04/23 2.3 1 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/23 2.3 4 T.Kitajima ADD START ******************************--
  cn_sub_1                    CONSTANT NUMBER      := 1;               -- 
  cv_zero                     CONSTANT VARCHAR2(1) := '0';             -- 
--****************************** 2009/04/23 2.3 4 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_system_date        DATE;                                                     -- �V�X�e�����t
  gd_business_date      DATE;                                                     -- �Ɩ����t
  gt_output_directory   fnd_profile_option_values.profile_option_value%TYPE;      -- �f�B���N�g���p�X
  gt_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;      -- ������уt�@�C����
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:�c�ƒP��
  gt_company_code       fnd_profile_option_values.profile_option_value%TYPE;      -- ��ЃR�[�h
  gt_var_elec_amount    fnd_profile_option_values.profile_option_value%TYPE;      -- �ϓ��d�C��
  gt_book_id            fnd_profile_option_values.profile_option_value%TYPE;      -- ��v����ID
  gt_dlv_ptn_cls        fnd_profile_option_values.profile_option_value%TYPE;      -- �[�i�`�ԋ敪
  gt_mk_org_cls         fnd_lookup_values.meaning%TYPE;                           -- �쐬������敪
  gt_file_handle        UTL_FILE.FILE_TYPE;                                       -- �t�@�C���n���h��
  gn_sales_h_count      NUMBER DEFAULT 0;                                         -- ����TBL�p�J�E���^(�������)
  gt_card_sale_class    fnd_lookup_values.lookup_code%TYPE;                       -- �J�[�h���敪
  gt_hc_class           fnd_lookup_values.meaning%TYPE;                           -- H/C�敪
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  gn_card_count         NUMBER;                                                   -- �J�[�h���J�E���g
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �̔����уf�[�^���o
  CURSOR get_sales_actual_cur
  IS
    SELECT  xseh.inspect_date                   xseh_inspect_date              -- ������
           ,xseh.dlv_invoice_number             xseh_dlv_invoice_number        -- �[�i�`�[�ԍ�
           ,xsel.dlv_invoice_line_number        xsel_dlv_invoice_line_number   -- �[�i���הԍ�
           ,xseh.ship_to_customer_code          xseh_ship_to_customer_code     -- �ڋq�y�[�i��z
           ,xsel.item_code                      xsel_item_code                 -- �i�ڃR�[�h
           ,xsel.hot_cold_class                 xsel_hot_cold_class            -- �g/�b
           ,xseh.sales_base_code                xseh_sales_base_code           -- ���㋒�_�R�[�h
           ,xseh.results_employee_code          xseh_results_employee_code     -- ���ьv��҃R�[�h
           ,NVL(xseh.card_sale_class
                ,cv_def_card_sale_class)        xseh_card_sale_class           -- �J�[�h����敪
           ,xsel.delivery_base_code             xsel_delivery_base_code        -- �[�i���_�R�[�h
           ,xsel.pure_amount                    xsel_pure_amount               -- �{�̋��z
           ,xsel.standard_qty                   xsel_standard_qty              -- �����
           ,xsel.tax_amount                     xsel_tax_amount                -- ����ŋ��z
           ,xseh.dlv_invoice_class              xseh_dlv_invoice_class         -- �[�i�`�[�敪
           ,xsel.sales_class                    xsel_sales_class               -- ����敪
           ,xsel.delivery_pattern_class         xsel_delivery_pattern_class    -- �[�i�`��
           ,xsel.column_no                      xsel_column_no                 -- �R����NO
           ,xseh.delivery_date                  xseh_delivery_date             -- �[�i��
           ,xsel.standard_unit_price            xsel_standard_unit_price       -- �Ŕ���P��
           ,xsel.standard_uom_code              xsel_standard_uom_code         -- ��P��
           ,xseh.tax_rate                       xseh_tax_rate                  -- ����ŗ�
           ,xseh.tax_code                       xseh_tax_code                  -- �ŃR�[�h
--****************************** 2009/04/23 2.3 4 T.Kitajima MOD START ******************************--
--           ,xsel.standard_unit_price_excluded   xsel_std_unit_price_excluded   -- �Ŕ���P��
           ,DECODE(
                       SUBSTR(   TO_CHAR( xsel.standard_unit_price_excluded )
                              , cn_sub_1
                              , cn_sub_1
                             )
                      ,cv_msg_cont
                      ,cv_zero || TO_CHAR( xsel.standard_unit_price_excluded )
                      ,TO_CHAR( xsel.standard_unit_price_excluded )
                   )                            xsel_std_unit_price_excluded   -- �Ŕ���P��
--****************************** 2009/04/23 2.3 4 T.Kitajima MOD  END  ******************************--
           ,xchv.bill_account_number            xchv_bill_account_number       -- ������ڋq�R�[�h
           ,xchv.cash_account_number            xchv_cash_account_number       -- ������ڋq�R�[�h
           ,NVL(xsel.cash_and_card,
                cn_non_cash_and_card)           xsel_cash_and_card             -- �����E�J�[�h���p�z
           ,xchv.bill_tax_round_rule            xchv_bill_tax_round_rule       -- �ŋ��|�[������
           ,xseh.create_class                   xseh_create_class              -- �쐬���敪
           ,xchv.ship_account_id                xchv_ship_account_id           -- �o�א�ڋqID
           ,hca.cust_account_id                 hca_cust_account_id            -- �ڋq�A�J�E���gID
           ,xchv.ship_account_name              xchv_ship_account_name         -- �o�א�ڋq��
           ,xseh.rowid                          xseh_rowid
    FROM    xxcos_sales_exp_headers             xseh                           -- �̔����уw�b�_
           ,xxcos_sales_exp_lines               xsel                           -- �̔����і���
           ,xxcos_cust_hierarchy_v              xchv                           -- �ڋq�K�w�r���[
           ,hz_cust_accounts                    hca                            -- �ڋq�A�J�E���g�}�X�^
    WHERE  xseh.sales_exp_header_id     = xsel.sales_exp_header_id             -- �w�b�_ID
    AND    xseh.dlv_invoice_number      = xsel.dlv_invoice_number              -- �[�i�`�[�ԍ�
    AND    xseh.dwh_interface_flag      = cv_flag_no                           -- �C���^�t�F�[�X�t���O
    AND    xseh.inspect_date           <= gd_business_date                     -- �[�i��
    AND    xsel.item_code              <> gt_var_elec_amount                   -- �i�ڃR�[�h
    AND    xchv.ship_account_number     = xseh.ship_to_customer_code           -- �o�א�ڋq�R�[�h
    AND    xchv.ship_account_id         = hca.cust_account_id                  -- �o�א�ڋqID
    AND    hca.account_number           = xseh.ship_to_customer_code           -- �ڋq�R�[�h
    ORDER BY  xseh.dlv_invoice_number                                          -- �[�i�`�[�ԍ�
             ,xsel.dlv_invoice_line_number                                     -- �[�i���הԍ�
    FOR UPDATE OF  xseh.sales_exp_header_id
                  ,xsel.sales_exp_line_id
    NOWAIT;
    --
    -- AR����f�[�^���o
    CURSOR get_ar_deal_info_cur(
       id_delivery_date     DATE          -- �[�i��
      ,in_ship_account_id   NUMBER)        -- �o�א�ڋqID
    IS
      SELECT  cust.trx_date                 rcta_trx_date                -- �����
             ,cust.trx_number               rcta_trx_number              -- ����ԍ�
             ,cust.puroduct_code            puroduct_code                -- ���i�R�[�h
             ,cust.line_number              rctla_line_number            -- ������הԍ�
             ,line.delivery_base_code       delivery_base_code           -- �Z�O�����g2(���_�R�[�h)
             ,line.revenue_amount           rctla_revenue_amount         -- ���v���z
             ,tax.extended_amount           rctla_t_revenue_amount       -- ���v���z
             ,cust.cust_trx_type_id         deal_cust_trx_type_id        -- ����^�C�v
             ,cust.tax_code                 avtab_tax_code               -- �ŋ��R�[�h
             ,cust.customer_id              rcta_bill_to_customer_id     -- ������ڋqID
             ,line.gl_date                  rctlgda_gl_date              -- GL�L����
      FROM
      -- �ŋ��f�[�^
      (  SELECT rctla.customer_trx_id                customer_trx_id
                ,rctla.link_to_cust_trx_line_id      link_to_cust_trx_line_id
                ,SUM(rctla.extended_amount)          extended_amount               -- ���v���z
         FROM   ra_customer_trx_lines_all     rctla                       -- AR�����񖾍�
         WHERE  rctla.line_type             = cv_line_type_tax             -- ���׃^�C�v
         GROUP BY rctla.customer_trx_id
                  ,rctla.link_to_cust_trx_line_id
      ) tax,
      -- ���׃f�[�^
      (
         SELECT rctlgda.gl_date                gl_date                      -- GL�L����
                ,gcc.segment2                  delivery_base_code           -- �Z�O�����g2(���_�R�[�h)
                ,rctla.revenue_amount          revenue_amount               -- ���v���z
                ,rctla.customer_trx_id         customer_trx_id              -- ���ID
                ,rctla.customer_trx_line_id    customer_trx_line_id          -- �������ID
         FROM   ra_cust_trx_line_gl_dist_all   rctlgda                      -- AR����z��(��v���)
                ,ra_customer_trx_lines_all     rctla                        -- AR�����񖾍�
                ,gl_code_combinations          gcc                          -- AFF�g�����}�X�^
                ,gl_sets_of_books              gsob                         -- GL��v����
         WHERE rctla.customer_trx_id         = rctlgda.customer_trx_id       -- ����f�[�^ID
         AND    rctlgda.account_class        = cv_account_class_profit       -- ����敪
         AND    rctlgda.code_combination_id  = gcc.code_combination_id       -- CCID
         AND    rctlgda.set_of_books_id      = TO_NUMBER(gt_book_id)
         AND    rctla.line_type              = cv_line_type_line             -- ���׃^�C�v
         AND    gcc.chart_of_accounts_id     = gsob.chart_of_accounts_id     -- �A�J�E���gID
         AND    rctlgda.customer_trx_line_id = rctla.customer_trx_line_id
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL�L����
      ) line,
      (
         -- ����f�[�^(����^�C�v�u�������v)
         SELECT rcta.trx_date                  trx_date                -- �����
                ,rcta.trx_number               trx_number              -- ����ԍ�
                ,rctta.attribute3              puroduct_code           -- ���i�R�[�h
                ,rctla.line_number             line_number             -- ������הԍ�
                ,rcta.cust_trx_type_id         cust_trx_type_id        -- ����^�C�v
                ,avtab.tax_code                tax_code                 -- �ŋ��R�[�h
                ,rcta.bill_to_customer_id      customer_id             -- ������ڋqID
                ,rctla.customer_trx_id         customer_trx_id              -- ���ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- �������ID
         FROM    ra_customer_trx_all           rcta                         -- AR������w�b�_
                ,ra_customer_trx_lines_all     rctla                        -- AR�����񖾍�
                ,ar_vat_tax_all_b              avtab                        -- �ŋ��}�X�^
                ,ra_cust_trx_types_all         rctta                        -- ����^�C�v
                ,fnd_lookup_values             flv                          -- �Q�ƃ^�C�v
                ,hz_cust_accounts              hca                            -- �ڋq�A�J�E���g�}�X�^
                ,hz_cust_acct_sites_all        hcasa                          -- �ڋq���ݒn�i������j
                ,hz_cust_site_uses_all         hcsua                        -- �ڋq�g�p�ړI
                ,ra_cust_trx_line_gl_dist_all   rctlgda                     -- AR����z��(��v���)
         WHERE  rcta.org_id                 = gt_org_id                     -- �c�ƒP��ID
         AND    rcta.customer_trx_id        = rctla.customer_trx_id         -- ����f�[�^ID
         AND    rctla.vat_tax_id            = avtab.vat_tax_id(+)           -- �ŋ�ID
         AND    avtab.set_of_books_id       = TO_NUMBER(gt_book_id)         -- ��v����ID
         AND    rctta.cust_trx_type_id      = rcta.cust_trx_type_id         -- ����^�C�vID
         AND    rctta.org_id                = gt_org_id                     -- �c�ƒP��
         AND    rctta.name                  = flv.meaning                   -- ���O
         AND    flv.lookup_type             = cv_ref_t_txn_type_mst         -- �^�C�v
         /*AND    flv.lookup_code             IN  (cv_txn_type_01
                                                ,cv_txn_type_02)            -- �R�[�h*/
         AND    flv.lookup_code             LIKE ( cv_txn_sales_type )      -- �R�[�h
         AND    flv.attribute1              = cv_val_y                      -- ����1
         AND    flv.language                = USERENV('LANG')               -- ����
         AND    rcta.cust_trx_type_id       = rctta.cust_trx_type_id        -- ����^�C�vID
         AND    hca.cust_account_id         = in_ship_account_id
         AND    hca.cust_account_id         = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id     = hcsua.cust_acct_site_id
         AND    hcsua.site_use_id           = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code         = cv_site_ship_to
         AND    rctla.customer_trx_id       = rctlgda.customer_trx_id       -- ����f�[�^ID
         AND    rctla.customer_trx_line_id  = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id     = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag          = cv_val_y
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL�L����
         /*UNION ALL 
         -- ����f�[�^(����^�C�v�u���|�������v(����񂠂�))
         SELECT  rcta.trx_date                 trx_date                     -- �����
                ,rcta.trx_number               trx_number                   -- ����ԍ�
                ,rctta.attribute3              puroduct_code                -- ���i�R�[�h
                ,rctla.line_number             line_number                  -- ������הԍ�
                ,rcta.cust_trx_type_id         cust_trx_type_id             -- ����^�C�v
                ,avtab.tax_code                tax_code                     -- �ŋ��R�[�h
                ,rcta.bill_to_customer_id      customer_id                  -- ������ڋqID
                ,rctla.customer_trx_id         customer_trx_id              -- ���ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- �������ID
         FROM    ra_customer_trx_all           rcta                         -- AR������w�b�_
                ,ra_customer_trx_lines_all     rctla                        -- AR�����񖾍�
                ,ar_vat_tax_all_b              avtab                        -- �ŋ��}�X�^
                ,ra_cust_trx_types_all         rctta                        -- ����^�C�v
                ,fnd_lookup_values             flv                          -- �Q�ƃ^�C�v
                ,fnd_lookup_values             flv_src                      -- �Q�ƃ^�C�v
                ,ra_customer_trx_all           rcta_src                     --����������e�[�u��(��)
                ,ra_cust_trx_types_all         rctta_src                    --��������^�C�v�}�X�^(��)
                ,hz_cust_accounts              hca                          -- �ڋq�A�J�E���g�}�X�^
                ,hz_cust_acct_sites_all        hcasa                        -- �ڋq���ݒn�i������j
                ,hz_cust_site_uses_all         hcsua                        -- �ڋq�g�p�ړI
                ,ra_cust_trx_line_gl_dist_all   rctlgda                     -- AR����z��(��v���)
         WHERE  rcta.org_id                    = gt_org_id                  -- �c�ƒP��ID
         AND    rcta_src.org_id                = gt_org_id                  -- �c�ƒP��ID
         AND    rcta.customer_trx_id           = rctla.customer_trx_id      -- ����f�[�^ID
         AND    rctla.vat_tax_id               = avtab.vat_tax_id(+)        -- �ŋ�ID
         AND    avtab.set_of_books_id          = TO_NUMBER(gt_book_id)      -- ��v����ID
         AND    rctta.cust_trx_type_id         = rcta.cust_trx_type_id      -- ����^�C�vID
         AND    rctta.org_id                   = gt_org_id                  -- �c�ƒP��
         AND    rctta_src.name                 = flv_src.meaning            -- ���O
         AND    flv.lookup_type                = cv_ref_t_txn_type_mst      -- �^�C�v
         AND    flv.lookup_code                = cv_txn_type_03
         AND    flv.attribute1                 = cv_val_y                         -- ����1
         AND    flv.language                   = USERENV('LANG')                  -- ����
         AND    flv_src.lookup_type                = cv_ref_t_txn_type_mst        -- �^�C�v
         AND    flv_src.lookup_code             IN  (cv_txn_type_01
                                                ,cv_txn_type_02)                  -- �R�[�h
--         AND    flv.lookup_code             LIKE ( cv_txn_sales_type )            -- �R�[�h
         AND    flv_src.attribute1                 = cv_val_y                     -- ����1
         AND    flv_src.language                   = USERENV('LANG')              -- ����
         AND    rcta.previous_customer_trx_id  = rcta_src.customer_trx_id         -- ���ID
         AND    rcta_src.cust_trx_type_id      = rctta_src.cust_trx_type_id       -- ����^�C�vID
         AND    hca.cust_account_id            = in_ship_account_id
         AND    hca.cust_account_id            = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id        = hcsua.cust_acct_site_id
         AND    hcsua.site_use_id              = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code            = cv_site_ship_to
         AND    rctla.customer_trx_id          = rctlgda.customer_trx_id       -- ����f�[�^ID
         AND    rctla.customer_trx_line_id     = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id        = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag             = cv_val_y
         AND    rcta_src.complete_flag         = cv_val_y
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL�L����
         UNION ALL
         -- ����f�[�^(����^�C�v�u���|�������v(�����Ȃ�))
         SELECT rcta.trx_date                  trx_date                     -- �����
                ,rcta.trx_number               trx_number                   -- ����ԍ�
                ,rctta.attribute3              puroduct_code                -- ���i�R�[�h
                ,rctla.line_number             line_number                  -- ������הԍ�
                ,rcta.cust_trx_type_id         cust_trx_type_id             -- ����^�C�v
                ,avtab.tax_code                tax_code                     -- �ŋ��R�[�h
                ,rcta.ship_to_customer_id      customer_id                  -- ������ڋqID
                ,rctla.customer_trx_id         customer_trx_id              -- ���ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- �������ID
         FROM    ra_customer_trx_all           rcta                            -- AR������w�b�_
                ,ra_customer_trx_lines_all     rctla                           -- AR�����񖾍�
                ,ar_vat_tax_all_b              avtab                           -- �ŋ��}�X�^
                ,ra_cust_trx_types_all         rctta                           -- ����^�C�v
                ,fnd_lookup_values             flv_gyotai                      -- �Q�ƃ^�C�v
                ,fnd_lookup_values             flv_trx                         -- �Q�ƃ^�C�v
                ,hz_cust_accounts              hca                             -- �ڋq�A�J�E���g�}�X�^
                ,hz_cust_acct_sites_all        hcasa                           -- �ڋq���ݒn�i������j
                ,hz_cust_site_uses_all         hcsua                           -- �ڋq�g�p�ړI
                ,xxcmm_cust_accounts           xca
                ,ra_cust_trx_line_gl_dist_all   rctlgda                        -- AR����z��(��v���)
         WHERE  rcta.org_id                    = gt_org_id                          -- �c�ƒP��ID
         AND    rcta.customer_trx_id           = rctla.customer_trx_id              -- ����f�[�^ID
         AND    rctla.vat_tax_id               = avtab.vat_tax_id(+)           -- �ŋ�ID
         AND    avtab.set_of_books_id          = TO_NUMBER(gt_book_id)         -- ��v����ID
         AND    rctta.cust_trx_type_id         = rcta.cust_trx_type_id              -- ����^�C�vID
         AND    rctta.org_id                   = gt_org_id                          -- �c�ƒP��
         AND    xca.customer_id                = hca.cust_account_id
         AND    xca.business_low_type          = flv_gyotai.meaning
         AND    flv_gyotai.lookup_type         = cv_gyotai_sho_mst_t
         AND    flv_gyotai.lookup_code         like cv_gyotai_sho_mst_c             -- �R�[�h
         AND    flv_gyotai.language            = USERENV('LANG')                    -- ���� 
         AND    rctta.name                     = flv_trx.meaning                    -- ���e
         AND    flv_trx.lookup_type            = cv_ref_t_txn_type_mst              -- �^�C�v
         AND    flv_trx.lookup_code            = cv_txn_type_03                     -- �Ɩ��`��
         AND    flv_trx.language               = USERENV('LANG')                    -- ���� 
         AND    rcta.previous_customer_trx_id  IS NULL                              -- �����ID
         AND    rcta.cust_trx_type_id          = rctta.cust_trx_type_id             -- ����^�C�vID
         AND    hca.cust_account_id            = in_ship_account_id
         AND    hca.cust_account_id            = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id        = hcsua.cust_acct_site_id
         AND    hcsua.site_use_id              = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code            = cv_site_ship_to
         AND    rctla.customer_trx_id          = rctlgda.customer_trx_id       -- ����f�[�^ID
         AND    rctla.customer_trx_line_id     = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id        = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag             = cv_val_y
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL�L����*/
      ) cust 
      WHERE  cust.customer_trx_id      = tax.customer_trx_id(+)
      AND    cust.customer_trx_line_id = tax.link_to_cust_trx_line_id(+)
      AND    cust.customer_trx_id      = line.customer_trx_id
      AND    cust.customer_trx_line_id = line.customer_trx_line_id 
      ORDER BY  cust.customer_trx_id                                           -- ������f�[�^ID
               ,cust.customer_trx_line_id;                                     -- �������ID

--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �̔����уw�b�_��ROWID
  TYPE g_sales_h_ttype IS TABLE OF ROWID  INDEX BY BINARY_INTEGER;
  g_sales_h_tbl     g_sales_h_ttype;
  --
  -- �o�͍ς݌ڋq���
  TYPE g_ar_output_settled_ttype IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  g_ar_output_settled_tbl    g_ar_output_settled_ttype;
--
  -- ��݌ɕi�ڗp���R�[�h�ϐ�
  TYPE g_non_item_rtype IS RECORD(
     amount        NUMBER DEFAULT 0           -- ����
  );
  -- ��݌ɕi�ڗp�e�[�u��
  TYPE g_non_item_ttype IS TABLE OF g_non_item_rtype INDEX BY VARCHAR2(50);
  -- ��݌ɕi�ڕϐ���`
  gt_non_item_tbl                   g_non_item_ttype;
  --
  -- AR���e�[�u��
  TYPE g_ar_deal_ttype IS TABLE OF get_ar_deal_info_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- AR���ϐ���`
  gt_ar_deal_tbl               g_ar_deal_ttype;


  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  g_sales_actual_rec    get_sales_actual_cur%ROWTYPE;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���R�[�h���b�N�G���[
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
/************************************************************************
 * Function Name   : get_external_code
 * Description     : �ڋq�ɕR�t�������R�[�h�擾
 ************************************************************************/
  FUNCTION get_external_code
  ( in_cust_account_id      IN NUMBER     -- �ڋq�R�[�h
  )
  RETURN VARCHAR2                         -- �����R�[�h
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_external_code';       -- �v���O������
--
    -- *** ���[�J���ϐ� ***
    lt_external_code       csi_item_instances.external_reference%TYPE;

  BEGIN
    --==================================
    -- �����R�[�h�擾
    --==================================
    SELECT csi.external_reference                                    -- �����R�[�h
    INTO   lt_external_code
    FROM   csi_item_instances         csi                            -- �����}�X�^
    WHERE  csi.owner_party_account_id  =in_cust_account_id          -- �A�J�E���gID
    AND    rownum                      = 1
    ORDER BY csi.external_reference ASC;                               -- �����R�[�h
--
    RETURN lt_external_code;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN cv_def_article_code;
  END;
--
/************************************************************************
 * Function Name   : edit_sales_amount
 * Description     : ������z�̕ҏW(�����̏ꍇ�A�����_�ȉ���؂�̂Ă�)
 ************************************************************************/
  FUNCTION edit_sales_amount
  ( in_amount      IN NUMBER           -- ������z
  )
  RETURN VARCHAR2                      -- ������z
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'edit_sales_amount'; -- �v���O������
--
    -- *** ���[�J���ϐ� ***
    ln_amount          NUMBER;    -- ������z
  BEGIN
--
    ln_amount := in_amount - ROUND(in_amount);
--
    -- �����_����
    IF ( ln_amount = 0 ) THEN
      -- �����_���Ȃ��ꍇ
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
--      RETURN TO_CHAR(ROUND(in_amount));
      RETURN TO_CHAR( in_amount );
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
    ELSE
      -- �����_������ꍇ
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
--      RETURN TO_CHAR(in_amount);
      RETURN TO_CHAR( ROUND( in_amount ) );
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TO_CHAR(in_amount);
  END;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_profile_name              VARCHAR2(50);   -- �v���t�@�C����
    lv_directory_path            VARCHAR2(100);  -- �f�B���N�g���E�p�X
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ��݌ɕi�ڎ擾
    CURSOR non_item_cur
    IS
      SELECT flv.lookup_code    lookup_code
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_non_inv_item_mst_t
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    --
    non_item_rec         non_item_cur%ROWTYPE;
    --
    -- *** ���[�J����O ***
    non_business_date_expt       EXCEPTION;     -- �Ɩ����t�擾�G���[
    non_item_extra_expt          EXCEPTION;     -- ��݌ɕi�ڒ��o�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- ���͍��ڂȂ��̃��b�Z�[�W�쐬
    --==================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_non_parameter);
    --
    --==================================
    -- �R���J�����g�E���b�Z�[�W�o��
    --==================================
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
    --==================================
    -- �R���J�����g�E���O�o��
    --==================================
    -- ��s�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
-- 
    -- ���b�Z�[�W���O 
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
    -- �V�X�e�����t�擾
    --==================================
    gd_system_date := SYSDATE;
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_business_date :=  xxccp_common_pkg2.get_process_date;
--
    IF ( gd_business_date IS NULL ) THEN
      -- �Ɩ����t���擾�ł��Ȃ��ꍇ
      RAISE non_business_date_expt;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    gt_output_directory := FND_PROFILE.VALUE(
                             name => cv_pf_output_directory);
--
    IF ( gt_output_directory IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_outbound_dir             -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ������уt�@�C�����擾
    --==================================
    gt_csv_file_name := FND_PROFILE.VALUE(
                             name => cv_pf_csv_file_name);
--
    IF ( gt_csv_file_name IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_zyoho_file_name          -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- MO:�c�ƒP�ʎ擾
    --==================================
    gt_org_id := FND_PROFILE.VALUE(
                             name => cv_pf_org_id);
--
    IF ( gt_org_id IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_org_id                   -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ��ЃR�[�h�擾
    --==================================
    gt_company_code := FND_PROFILE.VALUE(
                             name => cv_pf_company_code);
--
    IF ( gt_company_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_company_code             -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �ϓ��d�C��(�i�ڃR�[�h)�擾
    --==================================
    gt_var_elec_amount := FND_PROFILE.VALUE(
                             name => cv_pf_var_elec_item_cd);
--
    IF ( gt_var_elec_amount IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_elec_fee_item_code       -- ���b�Z�[�WID
      );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ��v����ID�擾
    --==================================
    gt_book_id := FND_PROFILE.VALUE(
                             name => cv_pro_bks_id);
--
    IF ( gt_book_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_book_id                  -- ���b�Z�[�WID
      );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==================================
    -- �[�i�`�ԋ敪�擾
    --==================================
    gt_dlv_ptn_cls := FND_PROFILE.VALUE(
                             name => cv_pf_sls_calc_dlv_ptn_cls);
--
    IF ( gt_dlv_ptn_cls IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_dlv_ptn_cls              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
                    ,iv_token_value1 => lv_profile_name);        -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �t�@�C�����o��
    --==================================
    SELECT ad.directory_path
    INTO   lv_directory_path
    FROM   all_directories  ad
    WHERE  ad.directory_name = gt_output_directory;
    --
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_file_name
                    ,iv_token_name1  => cv_tkn_file_name                -- �g�[�N��1��
                    ,iv_token_value1 => lv_directory_path 
                                        || '/' 
                                        || gt_csv_file_name);           -- �g�[�N��1�l
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --==================================
    -- �N�C�b�N�E�R�[�h�擾(��݌ɕi��)
    --==================================
    BEGIN
      OPEN non_item_cur;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^���o�G���[
        RAISE non_item_extra_expt;
    END;
    --
    <<non_item_loop>>
    LOOP
      FETCH non_item_cur INTO non_item_rec;
      EXIT WHEN non_item_cur%NOTFOUND;
      --
      gt_non_item_tbl(non_item_rec.lookup_code).amount := 0;
    END LOOP non_item_loop;
    --
    -- �擾�����`�F�b�N
    IF ( non_item_cur%ROWCOUNT = 0 ) THEN
      RAISE non_item_extra_expt;
    END IF;
    --
    CLOSE non_item_cur;
--
  EXCEPTION
    --*** �Ɩ����t�擾�G���[ ***
    WHEN non_business_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_non_business_date    -- ���b�Z�[�W
      );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --*** ��݌ɕi�ڎ擾�G���[ ***
    WHEN non_item_extra_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_short_name
                   ,iv_name         => cv_msg_non_item
      );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v��(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf      OUT NOCOPY VARCHAR2,             --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,             --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
    cv_file_mode_overwrite      CONSTANT VARCHAR2(1) := 'W';     -- �㏑
--
    -- *** ���[�J����O ***
    file_open_expt              EXCEPTION;      -- �t�@�C���I�[�v���G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    BEGIN
      gt_file_handle := UTL_FILE.FOPEN(
                          location  => gt_output_directory           -- �f�B���N�g��
                         ,filename  => gt_csv_file_name              -- �t�@�C����
                         ,open_mode => cv_file_mode_overwrite);      -- �t�@�C�����[�h
    EXCEPTION
      WHEN OTHERS THEN
        RAISE file_open_expt;
    END;
    --
    --==================================
    -- �t�@�C���ԍ��̃`�F�b�N
    --==================================
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = FALSE ) THEN
      RAISE file_open_expt;
    END IF;
--
  EXCEPTION
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_file_open_error      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_file_name            -- �g�[�N��1��
                     ,iv_token_value1 => gt_csv_file_name);          -- �g�[�N��1�l
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_actual_data
   * Description      : ���уf�[�^���o(A-3)
   ***********************************************************************************/
  PROCEDURE get_sales_actual_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_actual_data'; -- �v���O������
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
    lv_table_name      VARCHAR2(50);
    lv_type_name       VARCHAR2(50);
--
    -- *** ���[�J���E���R�[�h ***
    lt_ar_deal_rec     get_ar_deal_info_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
    sales_actual_extra_expt       EXCEPTION;    -- ���㖾�׃f�[�^���o�G���[
    non_lookup_value_expt         EXCEPTION;    -- LOOKUP�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=========================================
    -- �Q�ƃ^�C�v�i�쐬���敪����}�X�^�j�擾
    --=========================================
    BEGIN
      SELECT flv.meaning         flv_meaning
      INTO   gt_mk_org_cls
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_mk_org_cls_mst
      AND    flv.lookup_code   = cv_txn_type_01
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute1    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_mk_org_cls_name          -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_mk_org_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_attribute1
                     ,iv_token_value2 => cv_val_y);
      RAISE non_lookup_value_expt;  
    END;
--
    --=========================================
    -- �Q�ƃ^�C�v�i�J�[�h���敪�j�擾
    --=========================================
    BEGIN
      SELECT flv.lookup_code         flv_lookup_code
      INTO   gt_card_sale_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_card_sale_class
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute3    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_card_sales_name          -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_card_sale_class
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_attribute3
                     ,iv_token_value2 => cv_val_y);
        RAISE non_lookup_value_expt;
    END;
--
    --=========================================
    -- �Q�ƃ^�C�v�iH/C�敪�j�擾
    --=========================================
    BEGIN
      SELECT flv.lookup_code         flv_lookup_code
      INTO   gt_hc_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_hc_class
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute2    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_hc_class_name            -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_hc_class
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_attribute2
                     ,iv_token_value2 => cv_val_y);
      RAISE non_lookup_value_expt;
    END;
--
    --==================================
    -- ���㖾�׃f�[�^�擾
    --==================================
    BEGIN
      OPEN get_sales_actual_cur;
    EXCEPTION
      -- ���b�N�G���[
      WHEN record_lock_expt THEN
        RAISE record_lock_expt;
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        RAISE sales_actual_extra_expt;
    END;
--
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN record_lock_expt THEN
 --     IF ( get_sales_actual_cur%ISOPEN ) THEN
 --       CLOSE get_sales_actual_cur;
 --     END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
         ,iv_name        => cv_msg_sales_line               -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_lock_error
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => lv_table_name);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;   
    --
    --*** ���㖾�׃f�[�^���o�G���[ ***
    WHEN sales_actual_extra_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
         ,iv_name        => cv_msg_sales_line               -- ���b�Z�[�WID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** LOOKUP�G���[ ***
    WHEN non_lookup_value_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sales_actual_data;
--
  /**********************************************************************************
   * Procedure Name   : output_for_seles_actual
   * Description      : �������CSV�쐬(A-4)
   ***********************************************************************************/
  PROCEDURE output_for_seles_actual(
    it_sales_actual  IN  get_sales_actual_cur%ROWTYPE,  -- �������
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_seles_actual'; -- �v���O������
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
    ln_sales_quantity_card   CONSTANT NUMBER := 0;                 -- �J�[�h�F���㐔��
    cn_output_flag_off       CONSTANT NUMBER := 1;                 -- �I�t�F�o�͂��Ȃ�
    cn_output_flag_on        CONSTANT NUMBER := 0;                 -- �I���F�o�͂���
    cv_round_rule_up         CONSTANT VARCHAR2(10) := 'UP';        -- �؂�グ
    cv_round_rule_down       CONSTANT VARCHAR2(10) := 'DOWN';      -- �؂艺��
    cv_round_rule_nearest    CONSTANT VARCHAR2(10) := 'NEAREST';   -- �l�̌ܓ�
--
    -- *** ���[�J���ϐ� ***
    ln_sales_amount_cash    NUMBER;                     -- �����F������z
    ln_tax_cash             NUMBER;                     -- �����F���㐔��
    ln_sales_quantity_cash  NUMBER;                     -- �����F���㐔��
    ln_sales_amount_card    NUMBER;                     -- �J�[�h�F������z
    ln_tax_card             NUMBER;                     -- �J�[�h�F���㐔��
    ln_card_rec_flag        NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�o�̓t���O(�f�t�H���g�̓I�t)
    lv_buffer               VARCHAR2(2000);             -- �o�̓f�[�^
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
    lt_dlv_invoice_class    fnd_lookup_values.attribute1%TYPE;   -- �[�i�`�[�敪
    lv_type_name            VARCHAR2(50);
    -- *** ���[�J����O ***
    non_lookup_value_expt   EXCEPTION;
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF ( ( it_sales_actual.xseh_card_sale_class = gt_card_sale_class )
        AND ( it_sales_actual.xsel_cash_and_card > 0 ) )
    THEN
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
--      -- *** ���p�̏ꍇ  ***
--      -- ===============================
--      -- ������z�̕ҏW
--      -- ===============================
--      -- �J�[�h���R�[�h�̌v�Z
--      ln_sales_amount_card := it_sales_actual.xsel_cash_and_card / (1 + (it_sales_actual.xseh_tax_rate / 100));
----
--      -- �[������
--      IF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_up ) THEN
--        -- �؂�グ�̏ꍇ
--        ln_sales_amount_card := CEIL(ln_sales_amount_card);
----
--      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_down ) THEN
--        -- �؂艺���̏ꍇ
--        ln_sales_amount_card := FLOOR(ln_sales_amount_card);
----
--      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_nearest ) THEN
--        -- �l�̌ܓ��̏ꍇ
--        ln_sales_amount_card := ROUND(ln_sales_amount_card);
--      END IF;
----
--      -- �������R�[�h�̌v�Z
--      ln_sales_amount_cash := it_sales_actual.xsel_pure_amount - ln_sales_amount_card;
--
--      -- ===============================
--      -- ���㐔�ʂ̕ҏW
--      -- ===============================
--      -- �������R�[�h�̌v�Z
--      ln_sales_quantity_cash := it_sales_actual.xsel_standard_qty;
----
--      -- ===============================
--      -- ����Ŋz�̕ҏW
--      -- ===============================
--      -- �J�[�h���R�[�h�̌v�Z
--      ln_tax_card := it_sales_actual.xsel_cash_and_card - ln_sales_amount_card;
----
--      -- �������R�[�h�̌v�Z
--      ln_tax_cash := it_sales_actual.xsel_tax_amount - ln_tax_card;
----
--
      -- *** ���p�̏ꍇ  ***
      -- ===============================
      -- ������z�̕ҏW
      -- ===============================
      --�J�[�h����Ōv�Z(�����E�J�[�h���p�z*����ŗ�)
      ln_tax_card             := it_sales_actual.xsel_cash_and_card * (it_sales_actual.xseh_tax_rate / 100);
      --����Ŋz�̒[������
      IF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_up ) THEN
        -- �؂�グ�̏ꍇ
        ln_tax_card           := CEIL(ln_tax_card);
--
      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_down ) THEN
        -- �؂艺���̏ꍇ
        ln_tax_card           := FLOOR(ln_tax_card);
--
      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_nearest ) THEN
        -- �l�̌ܓ��̏ꍇ
        ln_tax_card           := ROUND(ln_tax_card);
      END IF;
      --�J�[�h������z�v�Z(�����E�J�[�h���p�z-�[�������̃J�[�h�����)
      ln_sales_amount_card    := it_sales_actual.xsel_cash_and_card - ln_tax_card;
      --����������z�v�Z(�{�̋��z-�J�[�h������z)
      ln_sales_amount_cash    := it_sales_actual.xsel_pure_amount   - ln_sales_amount_card;
      --��������Ŋz�v�Z(�����-�[�������̃J�[�h�����)
      ln_tax_cash             := it_sales_actual.xsel_tax_amount    - ln_tax_card;
      --���㐔��
      ln_sales_quantity_cash  := it_sales_actual.xsel_standard_qty;
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
      -- �J�[�h���R�[�h��CSV�ɏo��
      ln_card_rec_flag := cn_output_flag_on;
    ELSE
      -- *** ���p�łȂ��ꍇ  ***
      -- �������R�[�h�p�ϐ��ɐݒ�
      ln_sales_amount_cash   := it_sales_actual.xsel_pure_amount;                -- ������z
      ln_sales_quantity_cash := NVL(it_sales_actual.xsel_standard_qty,0);        -- ���㐔��
      ln_tax_cash            := it_sales_actual.xsel_tax_amount;                 -- �����
--
      -- �J�[�h���R�[�h��CSV�ɏo�͂��Ȃ�
      ln_card_rec_flag := cn_output_flag_off;
    END IF;
    --
    -- ��݌ɕi�ڂ̏ꍇ�A���ʂ��[���ɐݒ�
    IF ( gt_non_item_tbl.EXISTS(it_sales_actual.xsel_item_code) ) THEN
      -- ��݌ɕi�ڂ̏ꍇ
      ln_sales_quantity_cash := cn_non_sales_quantity;        -- ���㐔��
    END IF;
--
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
    --=========================================
    -- �Q�ƃ^�C�v�i�[�i�`�[�敪����}�X�^�j�擾
    --=========================================
    BEGIN
      SELECT flv.attribute1     flv_attribute1
      INTO   lt_dlv_invoice_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.meaning       = it_sales_actual.xseh_dlv_invoice_class
      AND    flv.lookup_type   = cv_ref_t_dlv_slp_cls_mst
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_ar_txn_name              -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_dlv_slp_cls
                       ,iv_token_name1  => cv_tkn_lookup_type
                       ,iv_token_value1 => lv_type_name
                       ,iv_token_name2  => cv_tkn_meaning
                       ,iv_token_value2 => it_sales_actual.xseh_dlv_invoice_class);
        RAISE non_lookup_value_expt;
    END;
--
    IF ( lt_dlv_invoice_class IS NULL ) THEN
      lv_type_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_ar_txn_name              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_dlv_slp_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_meaning
                     ,iv_token_value2 => it_sales_actual.xseh_dlv_invoice_class);
      RAISE non_lookup_value_expt;
    END IF;
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--
    -- ===============================
    -- CSV�t�@�C���o��
    -- ===============================
    -- ���p�i�������R�[�h�j�A���p�ȊO�f�[�^�̏o��
    lv_buffer :=
      cv_d_cot || gt_company_code || cv_d_cot                                        || cv_delimiter
      -- ��ЃR�[�h
      || TO_CHAR(it_sales_actual.xseh_delivery_date,cv_date_format_non_sep)          || cv_delimiter
      -- �[�i��
      || cv_d_cot || TO_CHAR(it_sales_actual.xseh_dlv_invoice_number) || cv_d_cot    || cv_delimiter
      -- �`�[�ԍ�
      || TO_CHAR(it_sales_actual.xsel_dlv_invoice_line_number)                       || cv_delimiter
      -- �sNo
      || cv_d_cot || it_sales_actual.xseh_ship_to_customer_code       || cv_d_cot    || cv_delimiter 
      -- �ڋq�R�[�h
      || cv_d_cot || it_sales_actual.xsel_item_code                   || cv_d_cot    || cv_delimiter 
      -- ���i�R�[�h
      || cv_d_cot || get_external_code(it_sales_actual.hca_cust_account_id) || cv_d_cot || cv_delimiter 
      -- �����R�[�h
      || cv_d_cot || NVL(it_sales_actual.xsel_hot_cold_class,gt_hc_class)   || cv_d_cot || cv_delimiter 
      -- H/C
      || cv_d_cot || it_sales_actual.xseh_sales_base_code || cv_d_cot                || cv_delimiter 
      -- ���㋒�_�R�[�h
      || cv_d_cot || NVL(it_sales_actual.xseh_results_employee_code,cv_def_results_employee_cd) || cv_d_cot || cv_delimiter 
      -- ���ю҃R�[�h
      || cv_d_cot || NVL(it_sales_actual.xseh_card_sale_class,cv_def_card_sale_class) || cv_d_cot || cv_delimiter 
      -- �J�[�h����敪
      || cv_d_cot || it_sales_actual.xsel_delivery_base_code || cv_d_cot             || cv_delimiter 
      -- �[�i���_�R�[�h
      || edit_sales_amount(ln_sales_amount_cash)                                     || cv_delimiter 
      -- ������z
      || ln_sales_quantity_cash                                                      || cv_delimiter 
      -- ���㐔��
      || ln_tax_cash                                                                 || cv_delimiter 
      -- ����Ŋz
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
--      || cv_d_cot || it_sales_actual.xseh_dlv_invoice_class || cv_d_cot              || cv_delimiter 
      || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                                || cv_delimiter              
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--      
      -- ����ԕi�敪
      || cv_d_cot || it_sales_actual.xsel_sales_class || cv_d_cot                    || cv_delimiter 
      -- ����敪
      || cv_d_cot || it_sales_actual.xsel_delivery_pattern_class || cv_d_cot         || cv_delimiter 
      -- �[�i�`�ԋ敪
      || cv_d_cot || NVL(it_sales_actual.xsel_column_no,cv_def_column_no) || cv_d_cot || cv_delimiter 
      -- �R����No
--      || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format)                  || cv_delimiter -- �����\���
      || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format_non_sep)                  || cv_delimiter 
      -- �����\���
      || it_sales_actual.xsel_std_unit_price_excluded                                || cv_delimiter 
      -- �[�i�P��
      || cv_d_cot || it_sales_actual.xseh_tax_code || cv_d_cot                       || cv_delimiter 
      -- �ŃR�[�h
      || cv_d_cot || it_sales_actual.xchv_bill_account_number || cv_d_cot            || cv_delimiter 
      -- ������ڋq�R�[�h
      || TO_CHAR(gd_system_date,cv_datetime_format);
      -- �A�g����
--
    -- CSV�t�@�C���o��
    UTL_FILE.PUT_LINE(
       file   => gt_file_handle
      ,buffer => lv_buffer
    );
    -- �o�͌����J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
    --
    IF ( ln_card_rec_flag = cn_output_flag_on) THEN
      -- ���p�i�J�[�h�j�f�[�^�̏o��
      lv_buffer :=
        cv_d_cot || gt_company_code || cv_d_cot                                       || cv_delimiter 
        -- ��ЃR�[�h
        || TO_CHAR(it_sales_actual.xseh_delivery_date,cv_date_format_non_sep)         || cv_delimiter 
        -- �[�i��
        || cv_d_cot || TO_CHAR(it_sales_actual.xseh_dlv_invoice_number) || cv_d_cot   || cv_delimiter 
        -- �`�[�ԍ�
        || TO_CHAR(it_sales_actual.xsel_dlv_invoice_line_number)                      || cv_delimiter 
        -- �sNo
        || cv_d_cot || it_sales_actual.xseh_ship_to_customer_code || cv_d_cot         || cv_delimiter 
        -- �ڋq�R�[�h
        || cv_d_cot || it_sales_actual.xsel_item_code || cv_d_cot                     || cv_delimiter 
        -- ���i�R�[�h
        || cv_d_cot || get_external_code(it_sales_actual.hca_cust_account_id) || cv_d_cot || cv_delimiter 
        -- �����R�[�h
        || cv_d_cot || NVL(it_sales_actual.xsel_hot_cold_class,gt_hc_class) || cv_d_cot || cv_delimiter 
        -- H/C
        || cv_d_cot || it_sales_actual.xseh_sales_base_code || cv_d_cot               || cv_delimiter 
        -- ���㋒�_�R�[�h
        || cv_d_cot || NVL(it_sales_actual.xseh_results_employee_code,cv_def_results_employee_cd) || cv_d_cot || cv_delimiter 
        -- ���ю҃R�[�h
        || cv_d_cot || NVL(it_sales_actual.xseh_card_sale_class,cv_def_card_sale_class) || cv_d_cot || cv_delimiter 
        -- �J�[�h����敪
        || cv_d_cot || it_sales_actual.xsel_delivery_base_code || cv_d_cot            || cv_delimiter 
        -- �[�i���_�R�[�h
        || edit_sales_amount(ln_sales_amount_card)                                    || cv_delimiter 
        -- ������z
        || ln_sales_quantity_card                                                     || cv_delimiter 
        -- ���㐔��
        || ln_tax_card                                                                || cv_delimiter 
        -- ����Ŋz
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
--      || cv_d_cot || it_sales_actual.xseh_dlv_invoice_class || cv_d_cot              || cv_delimiter 
      || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                                || cv_delimiter              
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--      
        -- ����ԕi�敪
        || cv_d_cot || it_sales_actual.xsel_sales_class || cv_d_cot                   || cv_delimiter 
        -- ����敪
        || cv_d_cot || it_sales_actual.xsel_delivery_pattern_class || cv_d_cot        || cv_delimiter 
        -- �[�i�`�ԋ敪
        || cv_d_cot || NVL(it_sales_actual.xsel_column_no,cv_def_column_no) || cv_d_cot || cv_delimiter 
        -- �R����No
--        || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format)                  || cv_delimiter -- �����\���
        || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format_non_sep)          || cv_delimiter 
        -- �����\���
        || it_sales_actual.xsel_std_unit_price_excluded                               || cv_delimiter 
        -- �[�i�P��
        || cv_d_cot || it_sales_actual.xseh_tax_code || cv_d_cot                      || cv_delimiter 
        -- �ŃR�[�h
--****************************** 2009/04/23 2.3 5 T.Kitajima MOD START ******************************--
--        || it_sales_actual.xchv_cash_account_number                                   || cv_delimiter 
        || cv_d_cot || it_sales_actual.xchv_cash_account_number || cv_d_cot           || cv_delimiter 
--****************************** 2009/04/23 2.3 5 T.Kitajima MOD  END  ******************************--
        -- ������ڋq�R�[�h
        || TO_CHAR(gd_system_date,cv_datetime_format);
        -- �A�g����
--
      -- CSV�t�@�C���o��
      UTL_FILE.PUT_LINE(
         file    => gt_file_handle
        ,buffer  => lv_buffer
      );
      -- �o�͌����J�E���g
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD START ******************************--
--      gn_normal_cnt := gn_normal_cnt + 1;
      gn_card_count := gn_card_count + 1;
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD  END  ******************************--

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
  END output_for_seles_actual;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_deal_info
   * Description      : AR������f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_ar_deal_info(
    id_delivery_date      IN  DATE,             --   �[�i��
    in_ship_account_id    IN  NUMBER,           --   �o�א�ڋqID
    iv_ship_account_name  IN  VARCHAR2,         --   �o�א�ڋq��
    ov_errbuf             OUT NOCOPY VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_deal_info'; -- �v���O������
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
    lv_table_name         VARCHAR2(100);            -- �e�[�u�����i�[
--
    -- *** ���[�J����O ***
    dealing_info_extra_expt     EXCEPTION;   -- AR�����񒊏o�f�[�^�Ȃ�
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
    BEGIN
      OPEN get_ar_deal_info_cur(
              id_delivery_date    => id_delivery_date       -- �[�i��
             ,in_ship_account_id  => in_ship_account_id     -- �o�א�ڋqID
           );
      --
      -- ���R�[�h�Ǎ���
      FETCH get_ar_deal_info_cur BULK COLLECT INTO gt_ar_deal_tbl;
      --
      -- ���o�����ݒ�
      gn_target_cnt := gn_target_cnt + gt_ar_deal_tbl.COUNT;
      --
      -- �N���[�Y
      CLOSE get_ar_deal_info_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE dealing_info_extra_expt;
    END;
--
    IF ( gt_ar_deal_tbl.COUNT = 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_notfound_ar_deal
                     ,iv_token_name1  => cv_tkn_account_name
                     ,iv_token_value1 => iv_ship_account_name
                     ,iv_token_name2  => cv_tkn_account_id
                     ,iv_token_value2 => TO_CHAR(in_ship_account_id));
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�x��
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    --*** AR�����񒊏o�f�[�^�Ȃ� ***
    WHEN dealing_info_extra_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
         ,iv_name        => cv_msg_ar_deal                  -- ���b�Z�[�WID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_deal_info;
  --
  /**********************************************************************************
   * Procedure Name   : output_for_ar_deal
   * Description      : �������CSV�쐬(AR������)(A-6)
   ***********************************************************************************/
  PROCEDURE output_for_ar_deal(
    it_sales_rec   IN  get_sales_actual_cur%ROWTYPE,         --   �������(���R�[�h�^)
    ov_errbuf      OUT NOCOPY VARCHAR2,                      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,                      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_ar_deal'; -- �v���O������
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
    lv_buffer               VARCHAR2(2000);                      -- �o�̓f�[�^
    lt_dlv_invoice_class    fnd_lookup_values.attribute1%TYPE;   -- �[�i�`�[�敪
    lv_type_name            VARCHAR2(50);
    --
    -- *** ���[�J���E���R�[�h�^ ***
    it_ar_deal_rec          get_ar_deal_info_cur%ROWTYPE;
    --
    -- *** ���[�J����O ***
    non_lookup_value_expt   EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=========================================
    -- �Q�ƃ^�C�v�i�[�i�`�[�敪����}�X�^�j�擾
    --=========================================
    BEGIN
      SELECT flv.attribute1     flv_attribute1
      INTO   lt_dlv_invoice_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.meaning       = it_sales_rec.xseh_dlv_invoice_class
      AND    flv.lookup_type   = cv_ref_t_dlv_slp_cls_mst
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_ar_txn_name              -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_dlv_slp_cls
                       ,iv_token_name1  => cv_tkn_lookup_type
                       ,iv_token_value1 => lv_type_name
                       ,iv_token_name2  => cv_tkn_meaning
                       ,iv_token_value2 => it_sales_rec.xseh_dlv_invoice_class);
        RAISE non_lookup_value_expt;
    END;
--
    IF ( lt_dlv_invoice_class IS NULL ) THEN
      lv_type_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_ar_txn_name              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_dlv_slp_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_meaning
                     ,iv_token_value2 => it_sales_rec.xseh_dlv_invoice_class);
      RAISE non_lookup_value_expt;
    END IF;
--
    <<ar_output_loop>>
    FOR ln_idx IN gt_ar_deal_tbl.FIRST..gt_ar_deal_tbl.LAST LOOP
      --
      lv_buffer :=
        cv_d_cot || gt_company_code || cv_d_cot                                  || cv_delimiter    -- ��ЃR�[�h
        || TO_CHAR(gt_ar_deal_tbl(ln_idx).rcta_trx_date,cv_date_format_non_sep)  || cv_delimiter    -- �[�i��
        || cv_d_cot || TO_CHAR(gt_ar_deal_tbl(ln_idx).rcta_trx_number) || cv_d_cot || cv_delimiter    -- �`�[�ԍ�
        || TO_CHAR(gt_ar_deal_tbl(ln_idx).rctla_line_number)                     || cv_delimiter    -- �sNo
        || cv_d_cot || it_sales_rec.xseh_ship_to_customer_code || cv_d_cot       || cv_delimiter    -- �ڋq�R�[�h
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).puroduct_code || cv_d_cot          || cv_delimiter    -- ���i�R�[�h
        || cv_d_cot || get_external_code(it_sales_rec.hca_cust_account_id) || cv_d_cot || cv_delimiter -- �����R�[�h
--****************************** 2009/04/23 2.3 1 T.Kitajima MOD START ******************************--
--        || cv_d_cot || gt_hc_class || cv_d_cot                                   || cv_delimiter    -- H/C
        || cv_d_cot || NVL( gt_hc_class, cv_h_c_cold ) || cv_d_cot               || cv_delimiter    -- H/C
--****************************** 2009/04/23 2.3 1 T.Kitajima MOD  END  ******************************--
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).delivery_base_code || cv_d_cot     || cv_delimiter    -- ���㋒�_�R�[�h
        || cv_d_cot || cv_def_results_employee_cd || cv_d_cot                    || cv_delimiter    -- ���ю҃R�[�h
        || cv_d_cot || cv_def_card_sale_class || cv_d_cot                        || cv_delimiter    -- �J�[�h����敪
        || cv_d_cot || cv_def_delivery_base_code || cv_d_cot                     || cv_delimiter    -- �[�i���_�R�[�h
        || (-1) * edit_sales_amount(gt_ar_deal_tbl(ln_idx).rctla_revenue_amount) || cv_delimiter    -- ������z
        || cn_non_sales_quantity                                                 || cv_delimiter    -- ���㐔��
        || (-1) * gt_ar_deal_tbl(ln_idx).rctla_t_revenue_amount                  || cv_delimiter    -- ����Ŋz
        || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                          || cv_delimiter    -- ����ԕi�敪
        || cv_d_cot || it_sales_rec.xsel_sales_class || cv_d_cot                 || cv_delimiter    -- ����敪
        || cv_d_cot || gt_dlv_ptn_cls || cv_d_cot                                || cv_delimiter    -- �[�i�`�ԋ敪
--****************************** 2009/04/23 2.3 3 T.Kitajima MOD START ******************************--
--        || cv_def_column_no                                                      || cv_delimiter    -- �R����No
        || cv_d_cot || cv_def_column_no || cv_d_cot                              || cv_delimiter    -- �R����No
--****************************** 2009/04/23 2.3 3 T.Kitajima MOD  END  ******************************--
        || cv_blank                                                              || cv_delimiter    -- �����\���
        || cn_non_std_unit_price                                                 || cv_delimiter    -- �[�i�P��
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).avtab_tax_code || cv_d_cot         || cv_delimiter    -- �ŃR�[�h
        || cv_d_cot || it_sales_rec.xchv_bill_account_number || cv_d_cot         || cv_delimiter    -- ������ڋq�R�[�h
        || TO_CHAR(gd_system_date,cv_datetime_format);                                              -- �A�g����
  --
      -- CSV�t�@�C���o��
      UTL_FILE.PUT_LINE(
         file     => gt_file_handle
        ,buffer   => lv_buffer
      );
      -- �o�͌����J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP ar_output_loop;
--
  EXCEPTION
    WHEN non_lookup_value_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END output_for_ar_deal;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_header_status
   * Description      : ������уw�b�_�X�e�[�^�X�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE update_sales_header_status(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_header_status'; -- �v���O������
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
    cv_interface_flag_comp    CONSTANT VARCHAR2(1) := 'Y';   -- �C���^�[�t�F�[�X�ς�
--
    -- *** ���[�J���ϐ� ***
    lv_item_name              VARCHAR2(255);      -- ���ږ�
    lv_table_name             VARCHAR2(255);      -- �e�[�u����
    ln_dlv_invoice_number     NUMBER;
--
    -- *** ���[�J����O ***
    update_expt               EXCEPTION;          -- �X�V�G���[
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
      FORALL ln_idx IN g_sales_h_tbl.FIRST..g_sales_h_tbl.LAST
        UPDATE xxcos_sales_exp_headers  xseh                                  -- �̔����уw�b�_
        SET     xseh.dwh_interface_flag     = cv_interface_flag_comp          -- ���V�X�e���C���^�t�F�[�X�t���O
               ,xseh.last_updated_by        = cn_last_updated_by              -- �ŏI�X�V��
               ,xseh.last_update_date       = cd_last_update_date             -- �ŏI�X�V��
               ,xseh.last_update_login      = cn_last_update_login            -- �ŏI�X�V���O�C��
               ,xseh.request_id             = cn_request_id                   -- �v��ID
               ,xseh.program_application_id = cn_program_application_id       -- �ݶ��ĥ��۸��ѥ���ع����ID
               ,xseh.program_id             = cn_program_id                   -- �ݶ��ĥ��۸���ID
               ,xseh.program_update_date    = cd_program_update_date          -- �v���O�����X�V��
        WHERE  xseh.rowid                   = g_sales_h_tbl(ln_idx);          -- ROWID
    EXCEPTION
      WHEN OTHERS THEN
        -- �X�V�Ɏ��s�����ꍇ
        RAISE update_expt;
    END;
--
  EXCEPTION
    --*** �X�V�G���[ ***
    WHEN update_expt THEN
     lv_table_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_sales_header             -- ���b�Z�[�WID
     );
     lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcos_short_name
        ,iv_name          => cv_msg_update_error
        ,iv_token_name1   => cv_tkn_table_name
        ,iv_token_value1  => lv_table_name
        ,iv_token_name2   => cv_tkn_key_data
        ,iv_token_value2  => cv_blank
      );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END update_sales_header_status;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y(A-8)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- �v���O������
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
    -- ===============================
    -- �t�@�C���N���[�Y
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gt_file_handle
    );
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
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : expt_proc
   * Description      : ��O����(A-9)
   ***********************************************************************************/
  PROCEDURE expt_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'expt_proc'; -- �v���O������
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
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
      -- �t�@�C�����I�[�v������Ă���ꍇ
      UTL_FILE.FCLOSE(
        file => gt_file_handle
      );
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
  END expt_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    -- *** ���[�J���ϐ� ***
    lv_errbuf_wk  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_wk VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_wk  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_index      VARCHAR2(30);    -- �C���f�b�N�X�E�L�[
--
    -- *** ���[�J����O ***
    sub_program_expt      EXCEPTION;
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
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
    gn_card_count := 0;
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
--
    BEGIN
      -- ===============================
      -- A-1.��������
      -- ===============================
      init(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-2.�t�@�C���I�[�v��
      -- ===============================
      file_open(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-3.�̔����уf�[�^���o
      -- ===============================
      get_sales_actual_data(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      <<sales_actual_loop>>
      LOOP
        FETCH get_sales_actual_cur INTO g_sales_actual_rec;
        EXIT WHEN get_sales_actual_cur%NOTFOUND;
        gn_target_cnt := gn_target_cnt + 1;
  --
        --==================================
        -- �������CSV�쐬(A-4)
        --==================================
        output_for_seles_actual(
           it_sales_actual => g_sales_actual_rec     -- ������у��R�[�h�^
          ,ov_errbuf       => lv_errbuf              -- �G���[�E���b�Z�[�W
          ,ov_retcode      => lv_retcode             -- ���^�[���E�R�[�h
          ,ov_errmsg       => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_program_expt;
        END IF;
        --
        IF ( g_sales_actual_rec.xseh_create_class = gt_mk_org_cls ) THEN
          -- �����v�Z�̏ꍇ�A������сiAR������)CSV�t�@�C���쐬
          lv_index := TO_CHAR(g_sales_actual_rec.xchv_ship_account_id)
                     || TO_CHAR(TRUNC(g_sales_actual_rec.xseh_delivery_date,cv_trunc_fmt),cv_date_format_non_sep);
          IF (g_ar_output_settled_tbl.EXISTS(lv_index) = FALSE ) THEN
            -- ���o�͂̏ꍇ
            --==================================
            -- AR������f�[�^���o(A-5)
            --==================================
            get_ar_deal_info(
               id_delivery_date     => g_sales_actual_rec.xseh_delivery_date       -- �[�i��
              ,in_ship_account_id   => g_sales_actual_rec.xchv_ship_account_id     -- �o�א�ڋqID
              ,iv_ship_account_name => g_sales_actual_rec.xchv_ship_account_name   -- ������ڋq��
              ,ov_errbuf            => lv_errbuf                                   -- �G���[�E���b�Z�[�W
              ,ov_retcode           => lv_retcode                                  -- ���^�[���E�R�[�h
              ,ov_errmsg            => lv_errmsg);                                 -- ���[�U�E�G���[�E���b�Z�[�W
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE sub_program_expt;
            END IF;
--
            IF ( lv_retcode = cv_status_normal) THEN
              --==================================
              --  �������CSV�쐬(AR������)(A-6)
              --==================================
              output_for_ar_deal(
                 it_sales_rec    => g_sales_actual_rec    -- �������(���R�[�h�^)
                ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W
                ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h
                ,ov_errmsg       => lv_errmsg);           -- ���[�U�E�G���[�E���b�Z�[�W
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE sub_program_expt;
              END IF;
            ELSE
              -- �Ώۃf�[�^�Ȃ�
              -- �G���[�����J�E���g
              gn_error_cnt := gn_error_cnt + 1;
            END IF;
            -- AR�o�͍ς݌ڋq���ɐݒ�
            g_ar_output_settled_tbl(lv_index) := NULL;
          END IF;
        END IF;
  --
        -- ROWID�Ɣ[�i�`�[�ԍ�������e�[�u���ɐݒ�
        g_sales_h_tbl(gn_sales_h_count) := g_sales_actual_rec.xseh_rowid;
        gn_sales_h_count := gn_sales_h_count + 1;
  --
      END LOOP sales_actual_loop;
      --
      -- �����f�[�^�����`�F�b�N
      IF ( get_sales_actual_cur%ROWCOUNT = 0 ) THEN
        -- �����Ώۃf�[�^�Ȃ�
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_notfound_data);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
      --
      CLOSE get_sales_actual_cur;
--
      -- ===============================
      -- A-7.������уw�b�_�X�e�[�^�X�X�V
      -- ===============================
      update_sales_header_status(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-8.�t�@�C���N���[�Y
      -- ===============================
      file_close(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    EXCEPTION
      WHEN sub_program_expt THEN
        -- �v���V�[�W�����ُ�I��
        -- ���b�Z�[�W��ޔ�
        lv_errbuf_wk := lv_errbuf;
        lv_retcode_wk := lv_retcode;
        lv_errmsg_wk := lv_errmsg;
--
        -- ===============================
        -- A-9.��O����
        -- ===============================
        expt_proc(
           ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
          ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
          ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
        IF ( lv_retcode = cv_status_error ) THEN
          IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
            -- �t�@�C�����I�[�v������Ă���ꍇ
            UTL_FILE.FCLOSE(
              file => gt_file_handle
            );
          END IF;
        END IF;
--
        -- ���b�Z�[�W��߂�
        lv_errbuf  := lv_errbuf_wk;
        lv_retcode := lv_retcode_wk;
        lv_errmsg  := lv_errmsg_wk;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
          IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
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
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD START ******************************--
--    --�Ώی����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_target_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --���������o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count_1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count_2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count_3
                    ,iv_token_value3 => TO_CHAR(gn_card_count)
                   );
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD  END  ******************************--
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
END XXCOS015A01C;
/
