CREATE OR REPLACE PACKAGE BODY XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(body)
 * Description      : �H�꒼���o�׈˗�IF�쐬���s��
 * MD.050           : �H�꒼���o�׈˗�IF�쐬 MD050_COS_008_A01
 * Version          : 1.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  get_order_data              �󒍃f�[�^�擾(A-2)
 *  get_ship_subinventory       �o�׌��ۊǏꏊ�擾(A-3)
 *  get_ship_schedule_date      �o�ח\����擾(A-4)
 *  data_check                  �f�[�^�`�F�b�N(A-5)
 *  make_normal_order_data      PL/SQL�\�ݒ�(A-6)
 *  make_request_line_bulk_data �o�׈˗�I/F���׃o���N�o�C���h�f�[�^�쐬(A-7)
 *  make_request_head_bulk_data �o�׈˗�I/F�w�b�_�o���N�o�C���h�f�[�^�쐬(A-8)
 *  insert_ship_line_data       �o�׈˗�I/F���׃f�[�^�쐬(A-9)
 *  insert_ship_header_data     �o�׈˗�I/F�w�b�_�f�[�^�쐬(A-10)
 *  update_order_line           �󒍖��׍X�V(A-11)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   K.Atsushiba      �V�K�쐬
 *  2009/02/05    1.1   K.Atsushiba      COS_035�Ή�  �o�׈˗�I/F�w�b�_�[�̈˗��敪�Ɂu4�v��ݒ�B
 *  2009/02/18    1.2   K.Atsushiba      get_msg�̃p�b�P�[�W���C��
 *  2009/02/23    1.3   K.Atsushiba      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *
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
  gv_out_msg            VARCHAR2(2000);
  gv_sep_msg            VARCHAR2(2000);
  gv_exec_user          VARCHAR2(100);
  gv_conc_name          VARCHAR2(30);
  gv_conc_status        VARCHAR2(30);
  gn_target_cnt         NUMBER;                    -- �Ώی���
  gn_header_normal_cnt  NUMBER;                    -- ���팏��(�w�b�_�[)
  gn_line_normal_cnt    NUMBER;                    -- ���팏��(����)
  gn_error_cnt          NUMBER;                    -- �G���[����
  gn_warn_cnt           NUMBER;                    -- �X�L�b�v����
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
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS008A01C'; -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxcos_short_name           CONSTANT VARCHAR2(10) := 'XXCOS';
  -- ���b�Z�[�W
  cv_msg_lock_error             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ���b�N�G���[
  cv_msg_notfound_profile       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[
  cv_msg_notfound_db_data       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    -- �Ώۃf�[�^�����G���[
  cv_msg_update_error           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- �f�[�^�X�V�G���[
  cv_msg_data_extra_error       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[
  cv_msg_org_id                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- �c�ƒP��
  cv_msg_non_business_date      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11601';    -- �Ɩ����t�擾�G���[
  cv_msg_lead_time_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11602';    -- ���[�h�^�C���Z�o�G���[
  cv_msg_non_operation_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11603';    -- �ғ����擾�G���[
  cv_msg_non_input_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11604';    -- �K�{���̓G���[
  cv_msg_class_val_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11605';    -- �敪�l�G���[
  cv_msg_operation_date_error   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11606';    -- �ғ����G���[
  cv_msg_ship_schedule_validite CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11607';    -- �o�ח\����Ó����G���[
  cv_msg_ship_schedule_calc     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11608';    -- �o�ח\������o�G���[
  cv_msg_order_date_validite    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11609';    -- �󒍓��Ó����G���[
  cv_msg_conc_parame            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11610';    -- ���̓p�����[�^�o��
  cv_msg_order_number           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11611';    -- �󒍔ԍ�
  cv_msg_line_number            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11612';    -- ���הԍ�
  cv_msg_item_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11613';    -- �i�ڃR�[�h
  cv_msg_send_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11614';    -- �z����R�[�h
  cv_msg_deli_expect_date       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11615';    -- �[�i�\���
  cv_msg_order_table_name       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11616';    -- �󒍃e�[�u��
  cv_msg_order_date             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11617';    -- �󒍓�
  cv_msg_cust_account_id        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11618';    -- �ڋqID
  cv_msg_cust_po_number         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11619';    -- �ڋq����
  cv_msg_ship_schedule_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11620';    -- �o�ח\���
  cv_msg_request_date           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11621';    -- �v����
  cv_msg_ship_subinv            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11622';    -- �o�׌��ۊǏꏊ
  cv_msg_base_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11623';    -- �[�i���_�R�[�h
  cv_msg_order_table            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11624';    -- �󒍃e�[�u��
  cv_msg_order_header_line      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11625';    -- �󒍃w�b�_/����
  cv_msg_ou_mfg                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11626';    -- ���Y�c�ƒP��
  cv_msg_ship_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11627';    -- �o�׋敪
  cv_msg_sales_div              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11628';    -- ����Ώۋ敪
  cv_msg_customer_order_flag    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11629';    -- �ڋq�󒍉\�t���O
  cv_msg_rate_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11630';    -- ���敪
  cv_msg_header_nomal_count     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11631';    -- �w�b�_��������
  cv_msg_line_nomal_count       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11632';    -- ���א�������
  cv_msg_order_line             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11633';    -- �󒍖���
  cv_msg_hokan_direct_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11634';    -- �ۊǏꏊ���ގ擾�G���[
  cv_msg_delivery_base_code     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11635';    -- ���_�R�[�h
  cv_msg_col_name               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11636';    -- ����
  cv_msg_ou_org_name            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11637';    -- ���Y�c�ƒP��
  cv_msg_shipping_class         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11324';    -- �˗��敪�擾�G���[
  -- �v���t�@�C��
  cv_pf_org_id                  CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO:�c�ƒP��
  cv_pf_ou_mfg                  CONSTANT VARCHAR2(30) := 'XXCOS1_ITOE_OU_MFG';  -- ���Y�c�ƒP��
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_profile                CONSTANT VARCHAR2(20) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_param1                 CONSTANT VARCHAR2(20) := 'PARAM1';              -- �p�����[�^1(���_�R�[�h)
  cv_tkn_param2                 CONSTANT VARCHAR2(20) := 'PARAM2';              -- �p�����[�^2(�󒍔ԍ�)
  cv_tkn_table_name             CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- �e�[�u����
  cv_tkn_key_data               CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- �L�[���
  cv_tkn_order_no               CONSTANT VARCHAR2(20) := 'ORDER_NO';            -- �󒍔ԍ�
  cv_tkn_line_no                CONSTANT VARCHAR2(20) := 'LINE_NO';             -- ���הԍ�
  cv_tkn_field_name             CONSTANT VARCHAR2(20) := 'FIELD_NAME';          -- ���ږ�
  cv_tkn_table                  CONSTANT VARCHAR2(20) := 'TABLE';               -- �e�[�u��
  cv_tkn_divide_value           CONSTANT VARCHAR2(20) := 'DIVIDE_VALUE';        -- �敪�l
  cv_tkn_val                    CONSTANT VARCHAR2(20) := 'VAL';                 -- �l
  cv_tkn_order_date             CONSTANT VARCHAR2(20) := 'ORDER_DATE';          -- �󒍓�
  cv_tkn_operation_date         CONSTANT VARCHAR2(20) := 'OPERATION_DATE';      -- �Z�o�󒍓�
  cv_tkn_code_from              CONSTANT VARCHAR2(20) := 'CODE_FROM';           -- �R�[�h�敪From
  cv_tkn_stock_from             CONSTANT VARCHAR2(20) := 'STOCK_FROM';          -- ���o�ɋ敪From
  cv_tkn_code_to                CONSTANT VARCHAR2(20) := 'CODE_TO';             -- �R�[�h�敪To
  cv_tkn_stock_to               CONSTANT VARCHAR2(20) := 'STOCK_TO';            -- ���o�ɋ敪To
  cv_tkn_stock_form_id          CONSTANT VARCHAR2(20) := 'STOCK_FORM_ID';       -- �o�Ɍ`��ID
  cv_tkn_base_date              CONSTANT VARCHAR2(20) := 'BASE_DATE';           -- ���
  cv_tkn_operate_date           CONSTANT VARCHAR2(20) := 'OPERATE_DATE';        -- �o�ח\���
  cv_tkn_whse_locat             CONSTANT VARCHAR2(20) := 'WHSE_LOCAT';          -- �ۊǑq�ɃR�[�h
  cv_tkn_delivery_code          CONSTANT VARCHAR2(20) := 'DELIVERY_CODE';       -- �z����R�[�h
  cv_tkn_lead_time              CONSTANT VARCHAR2(20) := 'LEAD_TIME';           -- ���[�h�^�C��
  cv_tkn_commodity_class        CONSTANT VARCHAR2(20) := 'COMMODITY_CLASS';     -- ���i�敪
  cv_tkn_type                   CONSTANT VARCHAR2(20) := 'TYPE';                -- �Q�ƃ^�C�v
  cv_tkn_code                   CONSTANT VARCHAR2(20) := 'CODE';                -- �Q�ƃR�[�h
  -- �Q�ƃ^�C�v
  cv_hokan_type_mst_t           CONSTANT VARCHAR2(50) := 'XXCOS1_HOKAN_DIRECT_TYPE_MST';        -- �ۊǏꏊ����
  cv_hokan_type_mst_c           CONSTANT VARCHAR2(50) := 'XXCOS_DIRECT_11';                     -- �ۊǏꏊ����
  cv_tran_type_mst_t            CONSTANT VARCHAR2(50) := 'XXCOS1_TRAN_TYPE_MST_008_A01';        -- �󒍃^�C�v
  cv_non_inv_item_mst_t         CONSTANT VARCHAR2(50) := 'XXCOS1_NO_INV_ITEM_CODE';             -- ��݌ɕi��
  cv_shipping_class_t           CONSTANT VARCHAR2(50) := 'XXWSH_SHIPPING_CLASS';                -- �o�׋敪(�^�C�v)
  cv_shipping_class_c           CONSTANT VARCHAR2(50) := '02';                                  -- �o�׋敪(�R�[�h)
  -- �����t�H�[�}�b�g
  cv_date_fmt_date_time         CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt_no_sep            CONSTANT VARCHAR2(25) := 'YYYYMMDD';
  --�f�[�^�`�F�b�N�X�e�[�^�X�l
  cn_check_status_normal        CONSTANT  NUMBER := 0;                    -- ����
  cn_check_status_error         CONSTANT  NUMBER := -1;                   -- �G���[
  -- �L���t���O
  cv_booked_flag_end            CONSTANT VARCHAR2(1) := 'Y';              -- �ς�
  -- �L���t���O
  cv_enabled_flag               CONSTANT VARCHAR2(1) := 'Y';              -- �L��
  --
  cn_customer_div_cust          CONSTANT  VARCHAR2(4)   := '10';          --�ڋq
  cv_cust_site_use_code         CONSTANT  VARCHAR2(10)  := 'SHIP_TO';     --�ڋq�g�p�ړI�F�o�א�
  -- ���׃X�e�[�^�X
  cv_flow_status_cancelled      CONSTANT VARCHAR2(10) := 'CANCELLED';     -- ���
  cv_flow_status_closed         CONSTANT VARCHAR2(10) := 'CLOSED';        -- �N���[�Y
  -- �����萔
  cv_blank                      CONSTANT VARCHAR2(1) := '';               -- �󕶎�
  -- ���[�h�^�C��
  cn_lead_time_non              CONSTANT NUMBER := 0;                     -- ���[�h�^�C���Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                     fnd_profile_option_values.profile_option_value%TYPE;      -- MO:�c�ƒP��
  gt_ou_mfg                     fnd_profile_option_values.profile_option_value%TYPE;      -- ���Y�c�ƒP��
  gd_business_date              DATE;                                                     -- �Ɩ����t
  gn_prod_ou_id                 NUMBER;                                                   -- ���Y�c�ƒP��ID
  gv_hokan_direct_class         VARCHAR2(10);                                             -- �ۊǏꏊ����(�����q��)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR order_data_cur(
    iv_base_code    IN  VARCHAR2,     -- ���_�R�[�h
    iv_order_number IN  VARCHAR2)     -- �󒍔ԍ�
  IS
    SELECT ooha.context                              context                 -- �󒍃^�C�v
          ,TRUNC(ooha.ordered_date)                  ordered_date            -- �󒍓�
          ,ooha.sold_to_org_id                       sold_to_org_id          -- �ڋq�R�[�h
          ,ooha.shipping_instructions                shipping_instructions   -- �o�׎w��
          ,ooha.cust_po_number                       cust_po_number          -- �ڋq����
          ,TRUNC(oola.request_date)                  request_date            -- �v����
          ,NVL(oola.attribute6, oola.ordered_item)   child_code              -- �󒍕i��
          ,TRUNC(oola.schedule_ship_date)            schedule_ship_date      -- �\��o�ד�
          ,oola.ordered_quantity                     ordered_quantity        -- �󒍐���
          ,xca.delivery_base_code                    delivery_base_code      -- �[�i���_�R�[�h
          ,hl.province                               province                -- �z����R�[�h
          ,msib.segment1                             item_code               -- �i�ڃR�[�h
          ,xicv.prod_class_name                      item_div_name           -- ���i�敪��
          ,xicv.prod_class_code                      prod_class_code         -- ���i�敪�R�[�h
          ,ooha.order_number                         order_number            -- �󒍔ԍ�
          ,oola.line_number                          line_number             -- ���הԍ�
          ,oola.rowid                                row_id                  -- �sID
          ,oola.attribute5                           sales_class             -- ����敪
          ,msib.customer_order_enabled_flag          customer_order_flag     -- �ڋq�󒍉\
          ,msib.inventory_item_id                    inventory_item_id       -- �i��ID
          ,oola.order_quantity_uom                   order_quantity_uom      -- �󒍒P��
          ,ooha.attribute19                          cust_po_number_att19    -- �ڋq����
          ,oola.line_id                              line_id                 -- ����ID
          ,oola.ship_from_org_id                     ship_from_org_id        -- �g�DID
          ,NVL(oola.attribute8,ooha.attribute13)     time_from               -- ���Ԏw��FROM
          ,NVL(oola.attribute9,ooha.attribute14)     time_to                 -- ���Ԏw��TO
          ,ooha.header_id                            header_id               -- �w�b�_ID
          ,NULL                                      ship_to_subinv          -- �o�׌��ۊǏꏊ(A-3�Őݒ�)
          ,NULL                                      lead_time               -- ���[�h�^�C��(���Y����)
          ,NULL                                      delivery_lt             -- ���[�h�^�C��(�z��)
          ,NULL                                      req_header_id           -- �o�׈˗��p�w�b�_�[ID
          ,NULL                                      conv_ordered_quantity   -- ���Z��󒍐���
          ,NULL                                      conv_order_quantity_uom -- ���Z��󒍒P��
          ,NULL                                      sort_key                -- �\�[�g�L�[
          ,cn_check_status_normal                    check_status            -- �`�F�b�N�X�e�[�^�X
    FROM   oe_order_headers_all                   ooha             -- �󒍃w�b�_
          ,oe_order_lines_all                     oola             -- �󒍖���
          ,hz_cust_accounts                       hca              -- �ڋq�}�X�^
          ,mtl_system_items_b                     msib             -- �i�ڃ}�X�^
          ,oe_transaction_types_tl                ottah            -- �󒍎���^�C�v�i�󒍃w�b�_�p�j
          ,oe_transaction_types_tl                ottal            -- �󒍎���^�C�v�i�󒍖��חp�j
          ,mtl_secondary_inventories              msi              -- �ۊǏꏊ�}�X�^
          ,xxcmn_item_categories5_v               xicv             -- ���i�敪View
          ,xxcmm_cust_accounts                    xca              -- �ڋq�ǉ����
          ,hz_cust_acct_sites_all                 sites            -- �ڋq���ݒn
          ,hz_cust_site_uses_all                  uses             -- �ڋq�g�p�ړI
          ,hz_party_sites                         hps              -- �p�[�e�B�T�C�g�}�X�^
          ,hz_locations                           hl               -- �ڋq���Ə��}�X�^
          ,fnd_lookup_values                      flv_tran         -- LookUp�Q�ƃe�[�u��(����.�󒍃^�C�v)
    WHERE ooha.header_id                          = oola.header_id                            -- �w�b�_�[ID
    AND   ooha.booked_flag                        = cv_booked_flag_end                        -- �X�e�[�^�X
    AND   oola.flow_status_code                   NOT IN (cv_flow_status_cancelled
                                                         ,cv_flow_status_closed)              -- �X�e�[�^�X(����)
    AND   ooha.sold_to_org_id                     = hca.cust_account_id                       -- �ڋqID
    AND   ooha.order_type_id                      = ottah.transaction_type_id                 -- ����^�C�vID
    AND   ottah.language                          = USERENV('LANG')
    AND   ottah.name                              = flv_tran.attribute1                       -- �������
    AND   oola.line_type_id                       = ottal.transaction_type_id
    AND   ottal.language                          = USERENV('LANG')
    AND   ottal.name                              = flv_tran.attribute2                       -- �������
    AND   oola.subinventory                       = msi.secondary_inventory_name              -- �ۊǏꏊ
    AND   msi.attribute13                         = gv_hokan_direct_class                     -- �ۊǏꏊ�敪
    AND   xca.delivery_base_code                  = NVL(iv_base_code, xca.delivery_base_code)  -- �[�i���_�R�[�h
    AND   ooha.order_number                       = NVL(iv_order_number, ooha.order_number)    -- �󒍃w�b�_�ԍ�
    AND   oola.packing_instructions               IS NULL                                     -- �o�׈˗�
    AND   xca.customer_id                         = hca.cust_account_id                       -- �ڋqID
    AND   oola.org_id                             = gt_org_id                                 -- �c�ƒP��
    AND   oola.ordered_item                       = msib.segment1                             -- �i�ڃR�[�h
    AND   xicv.item_no                            = msib.segment1                             -- �i�ڃR�[�h
    AND   msib.organization_id                    = oola.ship_from_org_id                     -- �g�DID
    AND   hca.cust_account_id                     = sites.cust_account_id                     -- �ڋqID
    AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- �ڋq�T�C�gID
    AND   hca.customer_class_code                 = cn_customer_div_cust                      -- �ڋq�敪(�ڋq)
    AND   uses.site_use_code                      = cv_cust_site_use_code                     -- �ڋq�g�p�ړI(�o�א�)
    AND   sites.org_id                            = gn_prod_ou_id                             -- ���Y�c�ƒP��
    AND   uses.org_id                             = gn_prod_ou_id                             -- ���Y�c�ƒP��
    AND   sites.party_site_id                     = hps.party_site_id                         -- �p�[�e�B�T�C�gID
    AND   hps.location_id                         = hl.location_id                            -- ���Ə�ID
    AND   hca.account_number                      IS NOT NULL                                 -- �ڋq�ԍ�
    AND   hl.province                             IS NOT NULL                                 -- �z����R�[�h
    AND   NVL(oola.attribute6,oola.ordered_item) 
              NOT IN ( SELECT flv_non_inv.lookup_code
                       FROM   fnd_lookup_values             flv_non_inv
                       WHERE  flv_non_inv.lookup_type       = cv_non_inv_item_mst_t
                       AND    flv_non_inv.language          = USERENV('LANG')
                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
    AND   flv_tran.lookup_type                    = cv_tran_type_mst_t
    AND   flv_tran.language                       = USERENV('LANG')
    AND   flv_tran.enabled_flag                   = cv_enabled_flag
    FOR UPDATE OF  oola.line_id
                  ,ooha.header_id
    NOWAIT
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o��
  -- ===============================
  -- �󒍏��e�[�u��
  TYPE g_n_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY VARCHAR(1000);
--
  -- �o�׈˗��w�b�_���e�[�u��
  -- �w�b�_ID
  TYPE g_tab_h_header_id
         IS TABLE OF xxwsh_shipping_headers_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍓�
  TYPE g_tab_h_ordered_date
         IS TABLE OF xxwsh_shipping_headers_if.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�
  TYPE g_tab_h_party_site_code
         IS TABLE OF xxwsh_shipping_headers_if.party_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎w��
  TYPE g_tab_h_shipping_instructions
         IS TABLE OF xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq����
  TYPE g_tab_h_cust_po_number
         IS TABLE OF xxwsh_shipping_headers_if.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃\�[�X�Q��
  TYPE g_tab_h_order_source_ref
         IS TABLE OF xxwsh_shipping_headers_if.order_source_ref%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ח\���
  TYPE g_tab_h_schedule_ship_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ח\���
  TYPE g_tab_h_schedule_arrival_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌�
  TYPE g_tab_h_location_code
         IS TABLE OF xxwsh_shipping_headers_if.location_code%TYPE INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE g_tab_h_head_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���͋��_
  TYPE g_tab_h_input_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���From
  TYPE g_tab_h_arrival_time_from
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���To
  TYPE g_tab_h_arrival_time_to
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- �f�[�^�^�C�v
  TYPE g_tab_h_data_type
         IS TABLE OF xxwsh_shipping_headers_if.data_type%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍔ԍ�
  TYPE g_tab_h_order_number
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  -- �˗��敪
  TYPE g_tab_h_order_class
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  -- �o�׈˗����׏��e�[�u��
  -- �w�b�_ID
  TYPE g_tab_l_header_id
         IS TABLE OF xxwsh_shipping_lines_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE g_tab_l_line_number
         IS TABLE OF xxwsh_shipping_lines_if.line_number%TYPE INDEX BY BINARY_INTEGER;
  -- ����ID
  TYPE g_tab_l_line_id
         IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍕i��
  TYPE g_tab_l_orderd_item_code
         IS TABLE OF xxwsh_shipping_lines_if.orderd_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE g_tab_l_orderd_quantity
         IS TABLE OF xxwsh_shipping_lines_if.orderd_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �g�D
  TYPE g_tab_l_ship_from_org_id
         IS TABLE OF oe_order_lines_all.ship_from_org_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- �󒍖��׏��e�[�u��
  -- �w�b�_ID
  TYPE g_tab_l_upd_header_id
         IS TABLE OF oe_order_lines_all.header_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- �󒍖��׍X�V�p���R�[�h�ϐ�
  TYPE gr_upd_order_line_rec IS RECORD(
     header_id                NUMBER                                              -- �w�b�_�[ID(��)
    ,order_source_ref         xxwsh_shipping_headers_if.order_source_ref%TYPE     -- �󒍃\�[�X�Q��(����w��)
    ,order_number             oe_order_headers_all.order_number%TYPE              -- �󒍔ԍ�
    ,line_id                  oe_order_lines_all.line_id%TYPE                     -- ����ID
    ,line_number              oe_order_lines_all.line_number%TYPE                 -- ���הԍ�
    ,ship_from_org_id         oe_order_lines_all.ship_from_org_id%TYPE            -- �g�DID
    ,req_header_id            NUMBER                                              -- �w�b�_�[ID(�o�׈˗�)
  );
  -- �󒍖��׍X�V�p�e�[�u��
  TYPE gt_upd_order_line_ttype IS TABLE OF gr_upd_order_line_rec INDEX BY BINARY_INTEGER;
  --
  -- (�i��)�敪�l�`�F�b�N���ʗp���R�[�h�ϐ�
  TYPE gr_item_info_rtype IS RECORD(
     ship_class_flag       NUMBER DEFAULT cn_check_status_normal     -- �o�׋敪
    ,sales_div_flag        NUMBER DEFAULT cn_check_status_normal     -- ����Ώۋ敪
    ,rate_class_flag       NUMBER DEFAULT cn_check_status_normal     -- ���敪
    ,cust_order_flag       NUMBER DEFAULT cn_check_status_normal     -- �ڋq�󒍉\�t���O
  );
  -- (�i��)�敪�l�`�F�b�N���ʗp�e�[�u��
  TYPE gt_item_info_ttype IS TABLE OF gr_item_info_rtype INDEX BY VARCHAR(50);
--
  -- �o�׈˗��w�b�_�̃C���T�[�g�p�ϐ���`
  gt_ins_h_header_id                   g_tab_h_header_id;                 -- �w�b�_ID
  gt_ins_h_ordered_date                g_tab_h_ordered_date;              -- �󒍓�
  gt_ins_h_party_site_code             g_tab_h_party_site_code;           -- �o�א�
  gt_ins_h_shipping_instructions       g_tab_h_shipping_instructions;     -- �o�׎w��
  gt_ins_h_cust_po_number              g_tab_h_cust_po_number;            -- �ڋq����
  gt_ins_h_order_source_ref            g_tab_h_order_source_ref;          -- �󒍃\�[�X�Q��
  gt_ins_h_schedule_ship_date          g_tab_h_schedule_ship_date;        -- �o�ח\���
  gt_ins_h_schedule_arrival_date       g_tab_h_schedule_arrival_date;     -- ���ח\���
  gt_ins_h_location_code               g_tab_h_location_code;             -- �o�׌�
  gt_ins_h_head_sales_branch           g_tab_h_head_sales_branch;         -- �Ǌ����_
  gt_ins_h_input_sales_branch          g_tab_h_input_sales_branch;        -- ���͋��_
  gt_ins_h_arrival_time_from           g_tab_h_arrival_time_from;         -- ���׎���From
  gt_ins_h_arrival_time_to             g_tab_h_arrival_time_to;           -- ���׎���To
  gt_ins_h_data_type                   g_tab_h_data_type;                 -- �f�[�^�^�C�v
  gt_ins_h_order_number                g_tab_h_order_number;              -- �󒍔ԍ�
  gt_ins_h_order_class                 g_tab_h_order_class;               -- �˗��敪
--
  -- �o�׈˗����ׂ̃C���T�[�g�p�ϐ���`
  gt_ins_l_header_id                   g_tab_l_header_id;                 -- �w�b�_ID
  gt_ins_l_line_number                 g_tab_l_line_number;               -- ���הԍ�
  gt_ins_l_line_id                     g_tab_l_line_id;                   -- ����ID
  gt_ins_l_orderd_item_code            g_tab_l_orderd_item_code;          -- �󒍕i��
  gt_ins_l_orderd_quantity             g_tab_l_orderd_quantity;           -- ����
  gt_ins_l_ship_from_org_id            g_tab_l_ship_from_org_id;          -- �g�D
--
  -- �󒍗p�ϐ���`
  gt_order_extra_tbl                   g_n_order_data_ttype;              -- �󒍗p���o�f�[�^�i�[
  gt_order_sort_tbl                    g_v_order_data_ttype;              -- �󒍗p�\�[�g�f�[�^�i�[
  gt_upd_order_line_tbl                gt_upd_order_line_ttype;           -- ���׍X�V�p
  gt_upd_header_id                     g_tab_l_upd_header_id;             -- ���׍X�V�p
--
  -- (�i��)�敪�l�`�F�b�N���ʗp�ϐ���`
  gt_item_info_tbl                     gt_item_info_ttype;
  gt_item_info_rec                     gr_item_info_rtype;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���R�[�h���b�N�G���[
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code     IN  VARCHAR2,            -- 1.���_�R�[�h
    iv_order_number  IN  VARCHAR2,            -- 2.�󒍔ԍ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_ou_org_name               VARCHAR2(50);   -- ���Y�c�ƒP�ʖ�
    lv_out_msg                   VARCHAR2(100);  -- �o�͗p
    lv_key_info                  VARCHAR2(1000); -- �L�[���
    lv_col_name                  VARCHAR2(50);   -- �J��������
--
    -- *** ���[�J����O ***
    notfound_hokan_direct_expt   EXCEPTION;      -- �����q�ɕۊǏꏊ�敪�擾�G���[
    notfound_ou_org_id_expt      EXCEPTION;      -- ���Y�c�ƒP�ʎ擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --===================================================
    --�R���J�����g�v���O�������͍��ڂ����b�Z�[�W�쐬
    --===================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
       iv_application  => cv_xxcos_short_name
      ,iv_name         => cv_msg_conc_parame      -- �R���J�����g�p�����[�^
      ,iv_token_name1  => cv_tkn_param1           -- ���_�R�[�h
      ,iv_token_value1 => iv_base_code
      ,iv_token_name2  => cv_tkn_param2         -- �󒍔ԍ�
      ,iv_token_value2 => iv_order_number
    );
    --
    -- ===============================
    --  �R���J�����g�E���b�Z�[�W�o��
    -- ===============================
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    -- ===============================
    --  �R���J�����g�E���O�o��
    -- ===============================
    -- ��s�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => NULL 
    ); 
-- 
    -- ���b�Z�[�W�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => lv_out_msg 
    ); 
-- 
    -- ��s�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => NULL 
    ); 
    --
    -- ===============================
    --  MO:�c�ƒP�ʎ擾
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE(
      name => cv_pf_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�c�ƒP��)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_org_id                   -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  �Ɩ����t�擾
    -- ===============================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_business_date IS NULL ) THEN
      -- �Ɩ����t���擾�ł��Ȃ��ꍇ
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_non_business_date    -- ���b�Z�[�W
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    --  ���Y�c�ƒP�ʎ擾����
    -- ===============================
    gt_ou_mfg := FND_PROFILE.VALUE(
      name => cv_pf_ou_mfg);
    --
    IF ( gt_ou_mfg IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(���Y�c�ƒP�ʎ擾����)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_ou_mfg                   -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  ���Y�c�ƒP��ID�擾
    -- ===============================
    BEGIN
      SELECT hou.organization_id    organization_id
      INTO   gn_prod_ou_id
      FROM   hr_operating_units hou
      WHERE  hou.name  = gt_ou_mfg;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���Y�c�ƒP�ʎ擾�G���[
        -- ���b�Z�[�W�p������擾
        lv_col_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_col_name                 -- ���b�Z�[�WID
        );
        --�L�[���̕ҏW����
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_col_name                     -- ����
         ,iv_data_value1    => gt_ou_mfg
         ,ov_key_info       => lv_key_info                      -- �ҏW��L�[���
         ,ov_errbuf         => lv_errbuf                        -- �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       -- ���^�[���R�[�h
         ,ov_errmsg         => lv_errmsg                        -- ���[�U�E�G���[�E���b�Z�[�W
        );
        RAISE notfound_ou_org_id_expt;
    END;
    --
    -- ===============================
    --  �ۊǏꏊ���ގ擾(�����q��)
    -- ===============================
    BEGIN
      SELECT flv.meaning
      INTO   gv_hokan_direct_class
      FROM   fnd_lookup_values     flv
      WHERE  flv.lookup_type     = cv_hokan_type_mst_t
      AND    flv.lookup_code     = cv_hokan_type_mst_c
      AND    flv.language        = USERENV('LANG')
      AND    flv.enabled_flag    = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �����q�ɕۊǏꏊ���ގ擾�G���[
        RAISE notfound_hokan_direct_expt;
    END;
    --
  EXCEPTION
    WHEN notfound_ou_org_id_expt THEN
      -- ���Y�c�ƒP�ʎ擾�G���[
      lv_ou_org_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_ou_org_name              -- ���b�Z�[�WID
      );
       -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_ou_org_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => lv_key_info
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #

    WHEN notfound_hokan_direct_expt THEN
      --*** �����q�ɕۊǏꏊ���ގ擾�G���[ ***
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_hokan_direct_err
       ,iv_token_name1  => cv_tkn_type
       ,iv_token_value1 => cv_hokan_type_mst_t
       ,iv_token_name2  => cv_tkn_code
       ,iv_token_value2 => cv_hokan_type_mst_c
      );
      --
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_data
   * Description      : �󒍃f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_data(
    iv_base_code      IN  VARCHAR2,            -- 1.���_�R�[�h
    iv_order_number   IN  VARCHAR2,            -- 2.�󒍔ԍ�
    ov_errbuf         OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_data'; -- �v���O������
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
    lv_table_name               VARCHAR2(50);    -- �e�[�u����
--
    -- *** ���[�J����O ***
    order_data_extra_expt       EXCEPTION;   -- �f�[�^���o�G���[
    notfound_order_data_expt    EXCEPTION;   -- �Ώۃf�[�^�Ȃ�
    lock_expt                   EXCEPTION;   -- ���b�N�G���[
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
      -- �J�[�\���I�[�v��
      OPEN order_data_cur(
         iv_base_code     => iv_base_code      -- ���_�R�[�h
        ,iv_order_number  => iv_order_number   -- �󒍔ԍ�
      );
      --
      -- ���R�[�h�Ǎ���
      FETCH order_data_cur BULK COLLECT INTO gt_order_extra_tbl;
      --
      -- ���o�����ݒ�
      gn_target_cnt := gt_order_extra_tbl.COUNT;
      --
      -- �J�[�\���E�N���[�Y
      CLOSE order_data_cur;
    EXCEPTION
      -- ���b�N�G���[
      WHEN record_lock_expt THEN
        RAISE lock_expt;
      WHEN OTHERS THEN
        -- ���o�Ɏ��s�����ꍇ
        RAISE order_data_extra_expt;
    END;
    --
    -- ���o�����`�F�b�N
    IF ( gt_order_extra_tbl.COUNT = 0 ) THEN
      -- ���o�f�[�^�������ꍇ
      RAISE notfound_order_data_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN
      --*** ���b�N�G���[ ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- ���b�Z�[�W������擾
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_header_line
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_lock_error
       ,iv_token_name1  => cv_tkn_table
       ,iv_token_value1 => lv_table_name
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
    WHEN order_data_extra_expt THEN
      --*** �f�[�^���o�G���[ ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- ���b�Z�[�W������擾
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_table
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_table_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => cv_blank
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
    WHEN notfound_order_data_expt THEN
      --*** ���o�f�[�^�Ȃ� ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_notfound_db_data
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_data;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_subinventory
   * Description      : �o�׌��ۊǏꏊ�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_ship_subinventory(
    it_order_rec          IN  order_data_cur%ROWTYPE,         -- 1.�󒍃f�[�^
    ov_ship_subinventory  OUT NOCOPY VARCHAR2,                -- 2.�o�וۊǏꏊ
    ov_errbuf             OUT NOCOPY VARCHAR2,                --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,                --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)                --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_subinventory'; -- �v���O������
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
    cv_item_code            CONSTANT VARCHAR2(7) := 'ZZZZZZZ';       -- �i�ڃR�[�h
--
    -- *** ���[�J���ϐ� ***
    lv_ship_subinventory    VARCHAR2(50);             -- �o�׌��ۊǏꏊ
    lv_key_info             VARCHAR2(1000);           -- �L�[���
    lv_table_name           VARCHAR2(50);             -- �e�[�u����
    lv_order_number         VARCHAR2(50);             -- �󒍔ԍ�
    lv_line_number          VARCHAR2(50);             -- ���הԍ�
    lv_item_code            VARCHAR2(50);             -- �i�ڃR�[�h
    lv_send_code            VARCHAR2(50);             -- �z����R�[�h
    lv_deli_expect_date     VARCHAR2(50);             -- �[�i�\���
    lv_base_code            VARCHAR2(50);             -- ���_�R�[�h
    lv_message              VARCHAR2(500);            -- �o�̓��b�Z�[�W
--
    -- *** ���[�J����O ***
    ship_subinventory_expt  EXCEPTION;                -- �o�׌��ۊǏꏊ�擾�G���[
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
      -- ===============================
      -- �o�׌��ۊǏꏊ�擾�@
      -- ===============================
      BEGIN
        SELECT xsr.delivery_whse_code           -- �o�וۊǑq�ɃR�[�h
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- �����\���A�h�I���}�X�^
        WHERE  xsr.item_code               = it_order_rec.item_code            -- �i�ڃR�[�h
        AND    xsr.ship_to_code            = it_order_rec.province             -- �z����R�[�h
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- �L����From
                                           AND     xsr.end_date_active;        -- �L����To
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���R�[�h���Ȃ��ꍇ
          lv_ship_subinventory := NULL;
      END;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- �o�׌��ۊǏꏊ���擾�ł��ĂȂ��ꍇ
        -- ===============================
        -- �o�׌��ۊǏꏊ�擾�A
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code           -- �o�וۊǑq�ɃR�[�h
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr        -- �����\���A�h�I���}�X�^
          WHERE  xsr.item_code               = it_order_rec.item_code            -- �i�ڃR�[�h
          AND    xsr.base_code               = it_order_rec.delivery_base_code   -- ���_�R�[�h
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- �L����From
                                             AND     xsr.end_date_active;        -- �L����To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���R�[�h���Ȃ��ꍇ
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- �o�׌��ۊǏꏊ���擾�ł��ĂȂ��ꍇ
        -- ===============================
        -- �o�׌��ۊǏꏊ�擾�B
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code            -- �o�וۊǑq�ɃR�[�h
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr         -- �����\���A�h�I���}�X�^
          WHERE  xsr.item_code               = cv_item_code                      -- �i�ڃR�[�h
          AND    xsr.ship_to_code            = it_order_rec.province             -- �z����R�[�h
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- �L����From
                                             AND     xsr.end_date_active;        -- �L����To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���R�[�h���Ȃ��ꍇ
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- �o�׌��ۊǏꏊ���擾�ł��ĂȂ��ꍇ
        -- ===============================
        -- �o�׌��ۊǏꏊ�擾�C
        -- ===============================
        SELECT xsr.delivery_whse_code           -- �o�וۊǑq�ɃR�[�h
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- �����\���A�h�I���}�X�^
        WHERE  xsr.item_code               = cv_item_code                      -- �i�ڃR�[�h
        AND    xsr.base_code               = it_order_rec.delivery_base_code   -- ���_�R�[�h
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- �L����From
                                           AND     xsr.end_date_active;        -- �L����To
      END IF;
      --
      -- OUT�p�����[�^�ݒ�
      ov_ship_subinventory := lv_ship_subinventory;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- �o�׌��ۊǏꏊ�擾�C��SQL�Œ��o�f�[�^�Ȃ��A�܂��́A�\�����ʃG���[�����������ꍇ
        lv_ship_subinventory := NULL;
        --
        -- ���b�Z�[�W������擾(�o�׌��ۊǏꏊ)
        lv_table_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_ship_subinv              -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(�󒍔ԍ�)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_order_number             -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(���הԍ�)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_line_number              -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(�i�ڃR�[�h)
        lv_item_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_item_code                -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(�z����R�[�h)
        lv_send_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_send_code                -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(�[�i�\���)
        lv_deli_expect_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_deli_expect_date         -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(���_�R�[�h)
        lv_base_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_delivery_base_code      -- ���b�Z�[�WID
        );
        --
        --�L�[���̕ҏW����
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- �󒍔ԍ�
         ,iv_data_value1    => it_order_rec.order_number
         ,iv_item_name2     => lv_line_number                   -- ���הԍ�
         ,iv_data_value2    => it_order_rec.line_number
         ,iv_item_name3     => lv_item_code                     -- �i�ڃR�[�h
         ,iv_data_value3    => it_order_rec.item_code
         ,iv_item_name4     => lv_send_code                     -- �z����R�[�h
         ,iv_data_value4    => it_order_rec.province
         ,iv_item_name5     => lv_base_code                     -- ���_�R�[�h
         ,iv_data_value5    => it_order_rec.delivery_base_code
         ,iv_item_name6     => lv_deli_expect_date              -- �[�i�\���
         ,iv_data_value6    => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
         ,ov_key_info       => lv_key_info                      -- �ҏW��L�[���
         ,ov_errbuf         => lv_errbuf                        -- �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       -- ���^�[���R�[�h
         ,ov_errmsg         => lv_errmsg                        -- ���[�U�E�G���[�E���b�Z�[�W
        );
        RAISE ship_subinventory_expt;
    END;
--
  EXCEPTION
    WHEN ship_subinventory_expt THEN
      --***  �o�׌��ۊǏꏊ�擾�G���[ ***
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_data_extra_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      ov_retcode := cv_status_warn;                                            --# �C�� #
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
  END get_ship_subinventory;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_schedule_date
   * Description      : �o�ח\����擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_ship_schedule_date(
    it_order_rec     IN  order_data_cur%ROWTYPE,          -- 1.�󒍃f�[�^
    od_oprtn_day     OUT DATE,                            -- 2.�o�ח\���
    on_lead_time     OUT NUMBER,                          -- 3,���[�h�^�C��(���Y����)
    on_delivery_lt   OUT NUMBER,                          -- 4.���[�h�^�C��(�z��)
    ov_errbuf        OUT NOCOPY VARCHAR2,                 --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,                 --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_schedule_date'; -- �v���O������
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
    cv_code_from            CONSTANT VARCHAR2(1) := '4';   -- �R�[�h�敪From(�q��)
    cv_code_to              CONSTANT VARCHAR2(1) := '9';   -- �R�[�h�敪To(�z����)
--
    -- *** ���[�J���ϐ� ***
    ln_lead_time             NUMBER;            -- ���[�h�^�C��
    ln_delivery_lt           NUMBER;            -- �z��LT
    ld_oprtn_day             DATE;              -- �ғ������t
    lv_msg_operate_date      VARCHAR2(30);      -- �o�ח\���
--
    -- *** ���[�J���ϐ� ***
    common_api_expt          EXCEPTION;      -- ����API�G���[
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
    -- ���[�h�^�C���Z�o
    -- ===============================
    xxwsh_common910_pkg.calc_lead_time(
       iv_code_class1                => cv_code_from                     -- �R�[�h�敪FROM
      ,iv_entering_despatching_code1 => it_order_rec.ship_to_subinv      -- ���o�ɏꏊ�R�[�hFROM
      ,iv_code_class2                => cv_code_to                       -- �R�[�h�敪TO
      ,iv_entering_despatching_code2 => it_order_rec.province            -- ���o�ɏꏊ�R�[�hTO
      ,iv_prod_class                 => it_order_rec.prod_class_code     -- ���i�敪
      ,in_transaction_type_id        => NULL                             -- �o�Ɍ`��ID
      ,id_standard_date              => it_order_rec.request_date        -- ���(�K�p�����)
      ,ov_retcode                    => lv_retcode                       -- ���^�[���R�[�h
      ,ov_errmsg_code                => lv_errbuf                        -- �G���[���b�Z�[�W�R�[�h
      ,ov_errmsg                     => lv_errmsg                        -- �G���[���b�Z�[�W
      ,on_lead_time                  => ln_lead_time                     -- ���Y����LT�^����ύXLT
      ,on_delivery_lt                => ln_delivery_lt                   -- �z��LT
    );
    --
    -- API���s���ʊm�F
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���[�h�^�C���擾�G���[�̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_lead_time_error
        ,iv_token_name1  => cv_tkn_order_no                     -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_code_from                    -- �R�[�h�敪From
        ,iv_token_value3 => cv_code_from
        ,iv_token_name4  => cv_tkn_stock_from                   -- ���o�ɋ敪From
        ,iv_token_value4 => it_order_rec.ship_to_subinv
        ,iv_token_name5  => cv_tkn_code_to                      -- �R�[�h�敪To
        ,iv_token_value5 => cv_code_to
        ,iv_token_name6  => cv_tkn_stock_to                     -- ���o�ɋ敪To
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_commodity_class              -- ���i�敪
        ,iv_token_value7 => it_order_rec.item_div_name
        ,iv_token_name8  => cv_tkn_stock_form_id                -- �o�Ɍ`��ID
        ,iv_token_value8 => cv_blank
        ,iv_token_name9  => cv_tkn_base_date                    -- ���
        ,iv_token_value9 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
      );
      RAISE common_api_expt;
    END IF;
    --
    -- �A�E�g�p�����[�^�ݒ�
    on_lead_time := ln_lead_time;
    on_delivery_lt := ln_delivery_lt;
    --
    IF ( it_order_rec.schedule_ship_date IS NULL ) THEN
      -- �o�ח\�����NULL�̏ꍇ
      -- �v����(�[�i�\���)�ƃ��[�h�^�C��(�z��)����o�ח\������擾����
      -- ===============================
      -- �o�ח\����擾
      -- ===============================
      lv_retcode := xxwsh_common_pkg.get_oprtn_day(
         id_date            => it_order_rec.request_date           -- �[�i�\���
        ,iv_whse_code       => NULL                                -- �ۊǑq�ɃR�[�h
        ,iv_deliver_to_code => it_order_rec.province               -- �z����R�[�h
        ,in_lead_time       => ln_lead_time                        -- ���[�h�^�C��
        ,iv_prod_class      => it_order_rec.prod_class_code        -- ���i�敪
        ,od_oprtn_day       => ld_oprtn_day                        -- �ғ������t(�o�ח\���)
      );
      --
      -- API���s���ʊm�F
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �ғ����擾�G���[�̏ꍇ
        -- ���b�Z�[�W������擾(�o�ח\���)
        lv_msg_operate_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_ship_schedule_date       -- ���b�Z�[�WID
        );
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_non_operation_date
          ,iv_token_name1  => cv_tkn_operate_date                          -- �o�ח\���
          ,iv_token_value1 => lv_msg_operate_date
          ,iv_token_name2  => cv_tkn_order_no                              -- �󒍔ԍ�
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                               -- ���הԍ�
          ,iv_token_value3 => it_order_rec.line_number
          ,iv_token_name4  => cv_tkn_base_date                             -- �[�i�\���
          ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
          ,iv_token_name5  => cv_tkn_whse_locat                            -- �o�׌��ۊǏꏊ
          ,iv_token_value5 => it_order_rec.ship_to_subinv
          ,iv_token_name6  => cv_tkn_delivery_code                         -- �z����R�[�h
          ,iv_token_value6 => it_order_rec.province
          ,iv_token_name7  => cv_tkn_lead_time                             -- ���[�h�^�C��
          ,iv_token_value7 => TO_CHAR(ln_lead_time)
          ,iv_token_name8  => cv_tkn_commodity_class                       -- ���i�敪
          ,iv_token_value8 => it_order_rec.item_div_name
        );
        RAISE common_api_expt;
      END IF;
      -- �A�E�g�p�����[�^�ݒ�
      od_oprtn_day := ld_oprtn_day;
    ELSE
      -- �A�E�g�p�����[�^�ݒ�
      od_oprtn_day := it_order_rec.schedule_ship_date;
    END IF;
--
  EXCEPTION
    WHEN common_api_expt THEN
      -- ����API�G���[
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- �X�e�[�^�X�ݒ�(�x��)
      ov_retcode := cv_status_warn;
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
  END get_ship_schedule_date;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : �f�[�^�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE data_check(
    it_order_rec   IN  order_data_cur%ROWTYPE,         -- 1.�󒍃f�[�^
    ov_errbuf      OUT NOCOPY VARCHAR2,                --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,                --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)                --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- �v���O������
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
    cv_normal_ship_class        CONSTANT VARCHAR2(1) := '1';      -- �o�׋敪(����l)
    cv_normal_sales_div         CONSTANT VARCHAR2(1) := '1';      -- ����Ώۋ敪(����l)
    cv_normal_rate_class        CONSTANT VARCHAR2(1) := '0';      -- ���敪(����l)
    cv_normal_cust_order_flag   CONSTANT VARCHAR2(1) := 'Y';      -- �ڋq�󒍉\�t���O(����l)
    cn_api_normal               CONSTANT NUMBER := 0;             -- ����
--
    -- *** ���[�J���ϐ� ***
    lv_message                  VARCHAR2(1000);       -- �o�̓��b�Z�[�W�ݒ�
    lv_item_name                VARCHAR2(50);         -- ���ږ�
    lv_ship_class               VARCHAR2(10);         -- �o�׋敪
    lv_sales_div                VARCHAR2(10);         -- ����Ώۋ敪
    lv_rate_class               VARCHAR2(10);         -- ���敪
    lv_cust_order_flag          VARCHAR2(10);         -- �ڋq�󒍉\�t���O
    ln_result                   NUMBER;               -- API�֐��p�߂�l
    ld_ope_delivery_day         DATE;                 -- �ғ������t�[�i�\���
    ld_ope_request_day          DATE;                 -- �ғ������t�󒍓�
    lv_tmp   varchar2(10);
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
    -- �K�{���̓`�F�b�N
    -- ===============================
    ----------------------------------
    -- �ڋq����
    ----------------------------------
    IF ( it_order_rec.cust_po_number IS NULL ) THEN
      -- ���ږ��擾
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_cust_po_number
      );
      -- �o�̓��b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                    -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                     -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                  -- ���ږ�
        ,iv_token_value3 => lv_item_name
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
/*
    ----------------------------------
    -- �v����
    ----------------------------------
    IF ( it_order_rec.request_date IS NULL ) THEN
      -- ���ږ��擾
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_request_date
      );
      -- �o�̓��b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                     -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                   -- ���ږ�
        ,iv_token_value3 => lv_item_name
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
*/
    ----------------------------------
    -- �[�i���_�R�[�h
    ----------------------------------
    IF ( it_order_rec.delivery_base_code IS NULL ) THEN
      -- ���ږ��擾
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_base_code
      );
      -- �o�̓��b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                    -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                     -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                  -- ���ږ�
        ,iv_token_value3 => lv_item_name
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ===============================
    -- �敪�l�`�F�b�N
    -- ===============================
    -- �i�ڃf�[�^���擾�ς݂��`�F�b�N
    IF ( gt_item_info_tbl.EXISTS(it_order_rec.item_code) = TRUE ) THEN
      -- �擾�ς݂̏ꍇ�A�ė��p����
      gt_item_info_rec := gt_item_info_tbl(it_order_rec.item_code);
    ELSE
      -- ���擾�̏ꍇ
      -- �o�׋敪�A����Ώۋ敪�A���敪�f�[�^�擾
      SELECT  ximv.ship_class                -- �o�׋敪
             ,ximv.sales_div                 -- ����Ώۋ敪
             ,ximv.rate_class                -- ���敪
      INTO    lv_ship_class
             ,lv_sales_div
             ,lv_rate_class
      FROM   xxcmn_item_mst2_v   ximv        -- OPM�i�ڏ��VIEW2
      WHERE  ximv.item_no       = it_order_rec.item_code             -- �i�ڃR�[�h
      AND    gd_business_date   BETWEEN ximv.start_date_active       -- �L����From
                                AND     ximv.end_date_active;        -- �L����To
      --
      -- �ڋq�󒍉\�t���O�擾
      SELECT msib.customer_order_enabled_flag         -- �ڋq�󒍉\�t���O
      INTO   lv_cust_order_flag
      FROM   mtl_system_items_b       msib            -- �i�ڃ}�X�^
      WHERE  msib.inventory_item_id = it_order_rec.inventory_item_id       -- �i��ID
      AND    msib.organization_id   = it_order_rec.ship_from_org_id;       -- �g�DID
      --
      -- �o�׋敪�`�F�b�N
      IF ( ( lv_ship_class IS NULL )
             OR ( lv_ship_class <> cv_normal_ship_class ) )
      THEN
        gt_item_info_rec.ship_class_flag := cn_check_status_error;
      END IF;
      --
      -- ����Ώۋ敪�`�F�b�N
      IF ( ( lv_sales_div IS NULL )
             OR ( lv_sales_div <> cv_normal_sales_div ) )
      THEN
        gt_item_info_rec.sales_div_flag := cn_check_status_error;
      END IF;
      --
      -- ���敪�`�F�b�N
      IF ( ( lv_rate_class IS NULL )
            OR ( lv_rate_class <> cv_normal_rate_class ) )
      THEN
        gt_item_info_rec.rate_class_flag := cn_check_status_error;
      END IF;
      --
      -- �ڋq�󒍉\�t���O�`�F�b�N
      IF ( ( lv_cust_order_flag IS NULL )
            OR ( lv_cust_order_flag <> cv_normal_cust_order_flag ) )
      THEN
        gt_item_info_rec.cust_order_flag := cn_check_status_error;
      END IF;
      --
      -- �e�[�u���ɐݒ�
      gt_item_info_tbl(it_order_rec.item_code) := gt_item_info_rec;
    END IF;
    --
    ----------------------------------
    -- �o�׋敪
    ----------------------------------
    IF (  gt_item_info_rec.ship_class_flag = cn_check_status_error ) THEN
      -- ���ږ��擾(�o�׋敪)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_ship_class
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                 -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name              -- ���ږ�
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value            -- ���ڒl
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- ����Ώۋ敪
    ----------------------------------
    IF ( gt_item_info_rec.sales_div_flag = cn_check_status_error ) THEN
      -- ���ږ��擾(����Ώۋ敪)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_sales_div
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                 -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                  -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name               -- ���ږ�
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value             -- ���ڒl
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- ���敪
    ----------------------------------
    IF ( gt_item_info_rec.rate_class_flag = cn_check_status_error ) THEN
      -- ���ږ��擾(���敪)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_rate_class
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no               -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name             -- ���ږ�
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value           -- ���ڒl
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- �ڋq�󒍉\�t���O
    ----------------------------------
    IF ( gt_item_info_rec.cust_order_flag = cn_check_status_error ) THEN
      -- ���ږ��擾(�ڋq�󒍉\�t���O)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_customer_order_flag
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                   -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                    -- ���הԍ�
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                 -- ���ږ�
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value               -- ���ڒl
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ==========================================
    -- �v����(�[�i�\���)���ғ������`�F�b�N
    -- ==========================================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.request_date         -- ���t
      ,iv_whse_code        => NULL                              -- �ۊǑq�ɃR�[�h
      ,iv_deliver_to_code  => it_order_rec.province             -- �z����R�[�h
      ,in_lead_time        => cn_lead_time_non                  -- ���[�h�^�C��
      ,iv_prod_class       => it_order_rec.prod_class_code      -- ���i�敪
      ,od_oprtn_day        => ld_ope_delivery_day               -- �ғ������t�[�i�\���
    );
    --
    IF ( ld_ope_delivery_day IS NULL ) THEN
      -- �ғ����擾�G���[
      -- ���ږ��擾(�[�i�\���)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_deli_expect_date
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_operation_date
        ,iv_token_name1  => cv_tkn_operate_date                          -- �[�i�\���
        ,iv_token_value1 => lv_item_name
        ,iv_token_name2  => cv_tkn_order_no                              -- �󒍔ԍ�
        ,iv_token_value2 => it_order_rec.order_number
        ,iv_token_name3  => cv_tkn_line_no                               -- ���הԍ�
        ,iv_token_value3 => it_order_rec.line_number
        ,iv_token_name4  => cv_tkn_base_date                             -- �[�i�\���
        ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_whse_locat                            -- �o�׌��ۊǏꏊ
        ,iv_token_value5 => it_order_rec.ship_to_subinv
        ,iv_token_name6  => cv_tkn_delivery_code                         -- �z����R�[�h
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_lead_time                             -- ���[�h�^�C��
        ,iv_token_value7 => TO_CHAR(cn_lead_time_non)
        ,iv_token_name8  => cv_tkn_commodity_class                       -- ���i�敪
        ,iv_token_value8 => it_order_rec.item_div_name
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
    ELSE
      -- =====================================
      -- �v����(�o�ח\���)�̑Ó����`�F�b�N
      -- =====================================
      IF ( TRUNC(it_order_rec.schedule_ship_date) < TRUNC(gd_business_date) ) THEN
        -- ���[�h�^�C���𖞂����Ă��Ȃ��ꍇ(�o�ח\������Ɩ����t���ߋ��̏ꍇ)
        -- ���b�Z�[�W�쐬
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_ship_schedule_validite
          ,iv_token_name1  => cv_tkn_val                        -- �o�ח\���
          ,iv_token_value1 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
          ,iv_token_name2  => cv_tkn_order_no                   -- �󒍔ԍ�
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                    -- ���הԍ�
          ,iv_token_value3 => it_order_rec.line_number
        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- ��s�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- ���^�[���R�[�h�ݒ�(�x��)
        ov_retcode := cv_status_warn;
        --
      END IF;
    END IF;
    --
    -- ===============================
    -- �󒍓��`�F�b�N���ғ������`�F�b�N
    -- ===============================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.schedule_ship_date      -- ���t
      ,iv_whse_code        => NULL                                 -- �ۊǑq�ɃR�[�h
      ,iv_deliver_to_code  => it_order_rec.province                -- �z����R�[�h
      ,in_lead_time        => it_order_rec.delivery_lt             -- ���[�h�^�C��(���Y����)
      ,iv_prod_class       => it_order_rec.prod_class_code         -- ���i�敪
      ,od_oprtn_day        => ld_ope_request_day                   -- �ғ������t
    );
    --
    IF ( ld_ope_request_day IS NULL ) THEN
      -- �ғ����擾�G���[�̏ꍇ
      -- ���b�Z�[�W������擾(�󒍓�)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_order_date               -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_operation_date
        ,iv_token_name1  => cv_tkn_operate_date                          -- �o�ח\���
        ,iv_token_value1 => lv_item_name
        ,iv_token_name2  => cv_tkn_order_no                              -- �󒍔ԍ�
        ,iv_token_value2 => it_order_rec.order_number
        ,iv_token_name3  => cv_tkn_line_no                               -- ���הԍ�
        ,iv_token_value3 => it_order_rec.line_number
        ,iv_token_name4  => cv_tkn_base_date                             -- �[�i�\���
        ,iv_token_value4 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_whse_locat                            -- �o�׌��ۊǏꏊ
        ,iv_token_value5 => it_order_rec.ship_to_subinv
        ,iv_token_name6  => cv_tkn_delivery_code                         -- �z����R�[�h
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_lead_time                             -- ���[�h�^�C��
        ,iv_token_value7 => it_order_rec.delivery_lt
        ,iv_token_name8  => cv_tkn_commodity_class                       -- ���i�敪
        ,iv_token_value8 => it_order_rec.item_div_name
      );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ���^�[���R�[�h�ݒ�(�x��)
      ov_retcode := cv_status_warn;
      --
    ELSE
      -- ===============================
      -- �󒍓��̑Ó����`�F�b�N
      -- ===============================
      IF ( TRUNC(it_order_rec.ordered_date) > TRUNC(ld_ope_request_day) ) THEN
        -- ���[�h�^�C���𖞂����Ă��Ȃ��ꍇ(�󒍓�����L�Ŏ擾�����ғ������ߋ��̏ꍇ)
        -- ���b�Z�[�W�쐬
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_order_date_validite
          ,iv_token_name1  => cv_tkn_order_no                                  -- �󒍔ԍ�
          ,iv_token_value1 => it_order_rec.order_number
          ,iv_token_name2  => cv_tkn_line_no                                   -- ���הԍ�
          ,iv_token_value2 => it_order_rec.line_number
          ,iv_token_name3  => cv_tkn_order_date                                -- ���o�󒍓�
          ,iv_token_value3 => TO_CHAR(it_order_rec.ordered_date,cv_date_fmt_date_time)
          ,iv_token_name4  => cv_tkn_operation_date                            -- �Z�o�󒍓�
          ,iv_token_value4 => TO_CHAR(ld_ope_request_day,cv_date_fmt_date_time)
        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- ��s�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- ���^�[���R�[�h�ݒ�(�x��)
        ov_retcode := cv_status_warn;
      END IF;
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
  END data_check;
--
  /**********************************************************************************
   * Procedure Name   : make_normal_order_data
   * Description      : PL/SQL�\�ݒ�(A-6)
   ***********************************************************************************/
  PROCEDURE make_normal_order_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_normal_order_data'; -- �v���O������
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
    cv_first_num           CONSTANT VARCHAR2(1) := '0';
--
    -- *** ���[�J���ϐ� ***
    lv_idx_key                VARCHAR2(1000);    -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
    lv_idx_sort               VARCHAR2(1000);    -- PL/SQL�\�\�[�g�p�\�[�g������
    ln_val                    NUMBER;            -- �ԍ������p
    lv_sort_key               VARCHAR2(1000);    -- �\�[�g�L�[
    lv_item_code              VARCHAR2(50);      -- �i�ڃR�[�h
    ln_header_id              NUMBER;            -- �w�b�_�[ID�V�[�P���X�p
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
    -- ����f�[�^�݂̂�PL/SQL�\�쐬
    -- ===============================
    <<loop_make_sort_data>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
        -- �\�[�g�L�[
        lv_idx_sort := TO_CHAR(gt_order_extra_tbl(ln_idx).header_id)                                -- �󒍃w�b�_ID
                      || gt_order_extra_tbl(ln_idx).ship_to_subinv                                  -- �o�׌��ۊǏꏊ
                      || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date,cv_date_fmt_no_sep)  -- �o�ח\���
                      || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date,cv_date_fmt_no_sep)        -- �[�i�\���
                      || gt_order_extra_tbl(ln_idx).time_from                                       -- ���Ԏw��From
                      || gt_order_extra_tbl(ln_idx).time_to                                         -- ���Ԏw��To
                      || gt_order_extra_tbl(ln_idx).item_div_name;                                  -- ���i�敪
        -- �C���f�b�N�X
        lv_idx_key := lv_idx_sort
                      || gt_order_extra_tbl(ln_idx).item_code                                       -- �i�ڃR�[�h
                      || cv_first_num;
        --
        -- �C���f�b�N�X(���꒍���i)�̃f�[�^�����݂��Ă��邩�`�F�b�N
        IF ( gt_order_sort_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
          -- ���݂���ꍇ
          ln_val := 1;
          <<loop_make_next_val>>
          LOOP
            lv_idx_key := lv_idx_sort
                      || gt_order_extra_tbl(ln_idx).item_code                                       -- �i�ڃR�[�h
                      || TO_CHAR(ln_val);
            -- ���݂��Ȃ��ꍇ�A���[�v�𔲂���
            EXIT WHEN gt_order_sort_tbl.EXISTS(lv_idx_key) = FALSE;
            -- �J�E���g�A�b�v
            ln_val := ln_val + 1;
          END LOOP loop_make_next_val;
        END IF;
        -- �\�[�g�L�[�ݒ�
        gt_order_extra_tbl(ln_idx).sort_key := lv_idx_sort;
        gt_order_sort_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
      END IF;
    END LOOP loop_make_sort_data;
    --
    -- ===============================
    -- �o�׈˗��p�w�b�_�[ID�̔�
    -- ===============================
    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
      lv_idx_key := gt_order_sort_tbl.FIRST;
      --
      -- �w�b�_�[ID�p�V�[�P���X�̔�
      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
      INTO   ln_header_id
      FROM   dual;
      --
      <<loop_make_header_id>>
      WHILE lv_idx_key IS NOT NULL LOOP
        -- �o�׈˗��p�w�b�_�[ID���̔Ԃ��邩�`�F�b�N
        IF ( ( lv_sort_key <> gt_order_sort_tbl(lv_idx_key).sort_key )
             OR ( ( lv_sort_key = gt_order_sort_tbl(lv_idx_key).sort_key )
                AND ( lv_item_code = gt_order_sort_tbl(lv_idx_key).item_code ) ) )
        THEN
          -- �\�[�g�L�[���u���C�N�A�܂��́A�\�[�g�L�[�ƕi�ڂ�����̏ꍇ
          -- �w�b�_�[ID�p�V�[�P���X�̔�
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
          INTO   ln_header_id
          FROM   dual;
          --
        END IF;
        --
        -- �w�b�_�[ID��ݒ�
        gt_order_sort_tbl(lv_idx_key).req_header_id := ln_header_id;
        --
        -- �\�[�g�L�[�ƕi�ڃR�[�h���擾
        lv_sort_key :=  gt_order_sort_tbl(lv_idx_key).sort_key;
        lv_item_code := gt_order_sort_tbl(lv_idx_key).item_code;
        --
        -- ���̃C���f�b�N�X���擾
        lv_idx_key := gt_order_sort_tbl.NEXT(lv_idx_key);
        --
      END LOOP loop_make_header_id;
    END IF;
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
  END make_normal_order_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_line_bulk_data
   * Description      : �o�׈˗�I/F���׃o���N�o�C���h�f�[�^�쐬(A-7)
   ***********************************************************************************/
  PROCEDURE make_request_line_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_line_bulk_data'; -- �v���O������
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
    lv_index                  VARCHAR2(1000);               -- PL/SQL�\�p�C���f�b�N�X������
    lv_organization_code      VARCHAR(100);                 --  �݌ɑg�D�R�[�h
    lt_item_id                ic_item_mst_b.item_id%TYPE;   --  �i��ID
    ln_organization_id        NUMBER;                       --  �݌ɑg�DID
    ln_content                NUMBER;                       --  ����
    ln_count                  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_line_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
      --==================================
      -- ����ʎZ�o
      --==================================
      xxcos_common_pkg.get_uom_cnv(
         iv_before_uom_code    => gt_order_sort_tbl(lv_index).order_quantity_uom       -- ���Z�O�P�ʃR�[�h = �󒍒P��
        ,in_before_quantity    => gt_order_sort_tbl(lv_index).ordered_quantity         -- ���Z�O����       = �󒍐���
        ,iov_item_code         => gt_order_sort_tbl(lv_index).item_code                -- �i�ڃR�[�h
        ,iov_organization_code => lv_organization_code                                 -- �݌ɑg�D�R�[�h   =NULL
        ,ion_inventory_item_id => lt_item_id                                           -- �i�ڂh�c         =NULL
        ,ion_organization_id   => ln_organization_id                                   -- �݌ɑg�D�h�c     =NULL
        ,iov_after_uom_code    => gt_order_sort_tbl(lv_index).conv_order_quantity_uom  --���Z��P�ʃR�[�h =>��P��
        ,on_after_quantity     => gt_order_sort_tbl(lv_index).conv_ordered_quantity    --���Z�㐔��       =>�����
        ,on_content            => ln_content                                           --����
        ,ov_errbuf             => lv_errbuf                         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
        ,ov_retcode            => lv_retcode                        --���^�[���E�R�[�h               #�Œ�#
        ,ov_errmsg             => lv_errmsg                         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
      );
      -- API���s���ʃ`�F�b�N
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      gt_ins_l_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;                -- �w�b�_�[ID
      gt_ins_l_line_number(ln_count) := gt_order_sort_tbl(lv_index).line_number;                -- ���הԍ�
      gt_ins_l_orderd_item_code(ln_count) := gt_order_sort_tbl(lv_index).child_code;            -- �󒍕i��
      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).conv_ordered_quantity;  -- ����
      gt_ins_l_line_id(ln_count) := gt_order_sort_tbl(lv_index).line_id;                        -- ����ID
      gt_ins_l_ship_from_org_id(ln_count) := gt_order_sort_tbl(lv_index).ship_from_org_id;      -- �g�DID
      --
      gt_upd_header_id(ln_count) := gt_order_sort_tbl(lv_index).header_id;                      -- �w�b�_�[ID
      --
      -- �J�E���g�A�b�v
      ln_count := ln_count + 1;
      --
      -- ���̃C���f�b�N�X���擾����
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_line_bulk_data;
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
  END make_request_line_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_head_bulk_data
   * Description      : �o�׈˗�I/F�w�b�_�o���N�o�C���h�f�[�^�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE make_request_head_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_head_bulk_data'; -- �v���O������
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
    cv_data_type                CONSTANT VARCHAR2(2) := '10';    -- �f�[�^�^�C�v
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- �ڋq�����̐擪����
    cv_order_source             CONSTANT VARCHAR2(1) := '9';     -- �󒍃\�[�X�Q�Ƃ̐擪����
    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
    cn_pad_num_char             CONSTANT NUMBER := 11;           -- PAD�֐��Ŗ��ߍ��ޕ�����
--
    -- *** ���[�J���ϐ� ***
    lv_index                    VARCHAR2(1000);                        -- PL/SQL�\�p�C���f�b�N�X������
    lt_cust_po_number           VARCHAR2(100);                         -- �ڋq����
    lv_order_source             VARCHAR2(12);                          -- �󒍃\�[�X
    ln_req_header_id            NUMBER;                                -- �w�b�_�[ID
    ln_count                    NUMBER;                                -- �J�E���^
    ln_order_source_ref         NUMBER;                                -- �V�[�P���X�ݒ�p
    lt_shipping_class           fnd_lookup_values.attribute2%TYPE;     -- �o�׈˗��敪
--
    -- *** ���[�J����O ***
    non_lookup_value_expt       EXCEPTION;                             -- �N�C�b�N�R�[�h�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------
    -- �o�׈˗��敪�̎擾
    -----------------------------
    BEGIN
      SELECT flv.attribute2     flv_attribute2
      INTO   lt_shipping_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_shipping_class_t
      AND    flv.lookup_code   = cv_shipping_class_c
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE non_lookup_value_expt;
    END;
    --
    IF ( lt_shipping_class IS NULL ) THEN
       RAISE non_lookup_value_expt;
    END IF;
    --
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_header_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
      -- �ŏ���1���A�܂��́A�w�b�_�[ID���u���C�N������f�[�^���쐬����
      IF ( ( lv_index = gt_order_sort_tbl.FIRST )
         OR( ln_req_header_id <> gt_order_sort_tbl(lv_index).req_header_id ) ) THEN
        -----------------------------
        -- �ڋq�����̐ݒ�
        -----------------------------
        IF ( ( gt_order_sort_tbl(lv_index).cust_po_number_att19 IS NOT NULL ) 
           AND ( SUBSTR(gt_order_sort_tbl(lv_index).cust_po_number,1,1) = cv_cust_po_number_first ) )
        THEN
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number_att19;
        ELSE
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number;
        END IF;
        --
        -----------------------------
        -- �󒍃\�[�X�Q�Ɛݒ�
        -----------------------------
        -- �V�[�P���X�̔�
        SELECT xxcos_order_source_ref_s01.NEXTVAL
        INTO   ln_order_source_ref
        FROM   dual;
        --
        lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                   ,cn_pad_num_char
                                                   ,cv_pad_char);
        --
        -- �w�b�_ID
        gt_ins_h_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;
        -- �󒍓�
        gt_ins_h_ordered_date(ln_count) := gt_order_sort_tbl(lv_index).ordered_date;
        -- �o�א�
        gt_ins_h_party_site_code(ln_count) := gt_order_sort_tbl(lv_index).province;
        -- �o�׎w��
        gt_ins_h_shipping_instructions(ln_count) := gt_order_sort_tbl(lv_index).shipping_instructions;
        -- �ڋq����
        gt_ins_h_cust_po_number(ln_count) := lt_cust_po_number;
        -- �󒍃\�[�X�Q��
        gt_ins_h_order_source_ref(ln_count) := lv_order_source;
        -- �o�ח\���
        gt_ins_h_schedule_ship_date(ln_count) := gt_order_sort_tbl(lv_index).schedule_ship_date;
        -- ���ח\���
        gt_ins_h_schedule_arrival_date(ln_count) := gt_order_sort_tbl(lv_index).request_date;
        -- �o�׌�
        gt_ins_h_location_code(ln_count) := gt_order_sort_tbl(lv_index).ship_to_subinv;
        -- �Ǌ����_
        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
        -- ���͋��_
        gt_ins_h_input_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
        -- ���׎���From
        gt_ins_h_arrival_time_from(ln_count) := gt_order_sort_tbl(lv_index).time_from;
        -- ���׎���To
        gt_ins_h_arrival_time_to(ln_count) := gt_order_sort_tbl(lv_index).time_to;
        -- �f�[�^�^�C�v
        gt_ins_h_data_type(ln_count) := cv_data_type;
        -- �󒍔ԍ�
        gt_ins_h_order_number(ln_count) := gt_order_sort_tbl(lv_index).order_number;
        -- �˗��敪
        gt_ins_h_order_number(ln_count) := lt_shipping_class;
        --
        -- �J�E���g�A�b�v
        ln_count := ln_count + 1;
        --
      END IF;
      --
      -- �w�b�_�[ID�ݒ�
      ln_req_header_id := gt_order_sort_tbl(lv_index).req_header_id;
      --
      -- ���̃C���f�b�N�X���擾����
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_header_bulk_data;
--
  EXCEPTION
    WHEN non_lookup_value_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_shipping_class
                       ,iv_token_name1  => cv_tkn_type
                       ,iv_token_value1 => cv_shipping_class_t
                       ,iv_token_name2  => cv_tkn_code
                       ,iv_token_value2 => cv_shipping_class_c);
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
  END make_request_head_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_line_data
   * Description      : �o�׈˗�I/F���׃f�[�^�쐬(A-9)
   ***********************************************************************************/
  PROCEDURE insert_ship_line_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_line_data'; -- �v���O������
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
    FORALL ln_idx IN 0..gt_ins_l_header_id.LAST
      INSERT INTO xxwsh_shipping_lines_if(
         line_id                        -- ����ID
        ,header_id                      -- �w�b�_ID
        ,line_number                    -- ���הԍ�
        ,orderd_item_code               -- �󒍕i��
        ,case_quantity                  -- �P�[�X��
        ,orderd_quantity                -- ����
        ,shiped_quantity                -- �o�׎��ѐ���
        ,designated_production_date     -- ������(�C���^�t�F�[�X�p)
        ,original_character             -- �ŗL�L��(�C���^�t�F�[�X�p)
        ,use_by_date                    -- �ܖ�����(�C���^�t�F�[�X�p)
        ,detailed_quantity              -- ���󐔗�(�C���^�t�F�[�X�p)
        ,ship_to_quantity               -- ���Ɏ��ѐ���
        ,reserved_status                -- �ۗ��X�e�[�^�X
        ,lot_no                         -- ���b�gNo
        ,filler01                       -- �\��01
        ,filler02                       -- �\��02
        ,filler03                       -- �\��03
        ,filler04                       -- �\��04
        ,filler05                       -- �\��05
        ,filler06                       -- �\��06
        ,filler07                       -- �\��07
        ,filler08                       -- �\��08
        ,filler09                       -- �\��09
        ,filler10                       -- �\��10
        ,created_by                     -- �쐬��
        ,creation_date                  -- �쐬��
        ,last_updated_by                -- �ŏI�X�V��
        ,last_update_date               -- �ŏI�X�V��
        ,last_update_login              -- �ŏI�X�V���O�C��
        ,request_id                     -- �v��ID
        ,program_application_id         -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,program_id                     -- �ݶ��ĥ��۸���ID
        ,program_update_date            -- �v���O�����X�V��
      ) VALUES (
         xxwsh_shipping_lines_if_s1.NEXTVAL      -- ����ID
        ,gt_ins_l_header_id(ln_idx)              -- �w�b�_ID
        ,gt_ins_l_line_number(ln_idx)            -- ���הԍ�
        ,gt_ins_l_orderd_item_code(ln_idx)       -- �󒍕i��
        ,NULL                                    -- �P�[�X��
        ,gt_ins_l_orderd_quantity(ln_idx)        -- ����
        ,NULL                                    -- �o�׎��ѐ���
        ,NULL                                    -- ������(�C���^�t�F�[�X�p)
        ,NULL                                    -- �ŗL�L��(�C���^�t�F�[�X�p)
        ,NULL                                    -- �ܖ�����(�C���^�t�F�[�X�p)
        ,NULL                                    -- ���󐔗�(�C���^�t�F�[�X�p)
        ,NULL                                    -- ���Ɏ��ѐ���
        ,NULL                                    -- �ۗ��X�e�[�^�X
        ,NULL                                    -- ���b�gNo
        ,NULL                                    -- �\��01
        ,NULL                                    -- �\��02
        ,NULL                                    -- �\��03
        ,NULL                                    -- �\��04
        ,NULL                                    -- �\��05
        ,NULL                                    -- �\��06
        ,NULL                                    -- �\��07
        ,NULL                                    -- �\��08
        ,NULL                                    -- �\��09
        ,NULL                                    -- �\��10
        ,cn_created_by                           -- �쐬��
        ,cd_creation_date                        -- �쐬��
        ,cn_last_updated_by                      -- �ŏI�X�V��
        ,cd_last_update_date                     -- �ŏI�X�V��
        ,cn_last_update_login                    -- �ŏI�X�V���O�C��
        ,cn_request_id                           -- �v��ID
        ,cn_program_application_id               -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,cn_program_id                           -- �ݶ��ĥ��۸���ID
        ,cd_program_update_date                  -- �v���O�����X�V��
      );
      --
      -- �o�^����
      gn_line_normal_cnt := gt_ins_l_header_id.COUNT;
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
  END insert_ship_line_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_header_data
   * Description      : �o�׈˗�I/F�w�b�_�f�[�^�쐬(A-10)
   ***********************************************************************************/
  PROCEDURE insert_ship_header_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_header_data'; -- �v���O������
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
    FORALL ln_idx IN 0..gt_ins_h_header_id.LAST
      INSERT INTO xxwsh_shipping_headers_if(
         header_id                -- �w�b�_ID
        ,ordered_date             -- �󒍓�
        ,party_site_code          -- �o�א�
        ,shipping_instructions    -- �o�׎w��
        ,cust_po_number           -- �ڋq����
        ,order_source_ref         -- �󒍃\�[�X�Q��
        ,schedule_ship_date       -- �o�ח\���
        ,schedule_arrival_date    -- ���ח\���
        ,used_pallet_qty          -- �p���b�g�g�p����
        ,collected_pallet_qty     -- �p���b�g�������
        ,location_code            -- �o�׌�
        ,head_sales_branch        -- �Ǌ����_
        ,input_sales_branch       -- ���͋��_
        ,arrival_time_from        -- ���׎���From
        ,arrival_time_to          -- ���׎���To
        ,data_type                -- �f�[�^�^�C�v
        ,freight_carrier_code     -- �^���Ǝ�
        ,shipping_method_code     -- �z���敪
        ,delivery_no              -- �z��No
        ,shipped_date             -- �o�ד�
        ,arrival_date             -- ���ד�
        ,eos_data_type            -- EOS�f�[�^���
        ,tranceration_number      -- �`���p�}��
        ,ship_to_location         -- ���ɑq��
        ,rm_class                 -- �q�֕ԕi�敪
        ,ordered_class            -- �˗��敪
        ,report_post_code         -- �񍐕���
        ,line_number              -- ����ԍ�
        ,filler01                 -- �\��01
        ,filler02                 -- �\��02
        ,filler03                 -- �\��03
        ,filler04                 -- �\��04
        ,filler05                 -- �\��05
        ,filler06                 -- �\��06
        ,filler07                 -- �\��07 
        ,filler08                 -- �\��08
        ,filler09                 -- �\��09
        ,filler10                 -- �\��10
        ,filler11                 -- �\��11
        ,filler12                 -- �\��12
        ,filler13                 -- �\��13
        ,filler14                 -- �\��14
        ,filler15                 -- �\��15
        ,filler16                 -- �\��16
        ,filler17                 -- �\��17
        ,filler18                 -- �\��18
        ,created_by               -- �쐬��
        ,creation_date            -- �쐬��
        ,last_updated_by          -- �ŏI�X�V��
        ,last_update_date         -- �ŏI�X�V��
        ,last_update_login        -- �ŏI�X�V���O�C��
        ,request_id               -- �v��ID
        ,program_application_id   -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,program_id               -- �ݶ��ĥ��۸���ID
        ,program_update_date      -- �v���O�����X�V��
      ) VALUES (
         gt_ins_h_header_id(ln_idx)                -- �w�b�_ID
        ,gt_ins_h_ordered_date(ln_idx)             -- �󒍓�
        ,gt_ins_h_party_site_code(ln_idx)          -- �o�א�
        ,gt_ins_h_shipping_instructions(ln_idx)    -- �o�׎w��
        ,gt_ins_h_cust_po_number(ln_idx)           -- �ڋq����
        ,gt_ins_h_order_source_ref(ln_idx)         -- �󒍃\�[�X�Q��
        ,gt_ins_h_schedule_ship_date(ln_idx)       -- �o�ח\���
        ,gt_ins_h_schedule_arrival_date(ln_idx)    -- ���ח\���
        ,NULL                                      -- �p���b�g�g�p����
        ,NULL                                      -- �p���b�g�������
        ,gt_ins_h_location_code(ln_idx)            -- �o�׌�
        ,gt_ins_h_head_sales_branch(ln_idx)        -- �Ǌ����_
        ,gt_ins_h_input_sales_branch(ln_idx)       -- ���͋��_
        ,gt_ins_h_arrival_time_from(ln_idx)        -- ���׎���From
        ,gt_ins_h_arrival_time_to(ln_idx)          -- ���׎���To
        ,gt_ins_h_data_type(ln_idx)                -- �f�[�^�^�C�v
        ,NULL                                      -- �^���Ǝ�
        ,NULL                                      -- �z���敪
        ,NULL                                      -- �z��No
        ,NULL                                      -- �o�ד�
        ,NULL                                      -- ���ד�
        ,NULL                                      -- EOS�f�[�^���
        ,NULL                                      -- �`���p�}��
        ,NULL                                      -- ���ɑq��
        ,NULL                                      -- �q�֕ԕi�敪
        ,gt_ins_h_order_number(ln_idx)             -- �˗��敪
        ,NULL                                      -- �񍐕���
        ,NULL                                      -- ����ԍ�
        ,NULL                                      -- �\��01
        ,NULL                                      -- �\��02
        ,NULL                                      -- �\��03
        ,NULL                                      -- �\��04
        ,NULL                                      -- �\��05
        ,NULL                                      -- �\��06
        ,NULL                                      -- �\��07
        ,NULL                                      -- �\��08
        ,NULL                                      -- �\��09
        ,NULL                                      -- �\��10
        ,NULL                                      -- �\��11
        ,NULL                                      -- �\��12
        ,NULL                                      -- �\��13
        ,NULL                                      -- �\��14
        ,NULL                                      -- �\��15
        ,NULL                                      -- �\��16
        ,NULL                                      -- �\��17
        ,NULL                                      -- �\��18
        ,cn_created_by                             -- �쐬��
        ,cd_creation_date                          -- �쐬��
        ,cn_last_updated_by                        -- �ŏI�X�V��
        ,cd_last_update_date                       -- �ŏI�X�V��
        ,cn_last_update_login                      -- �ŏI�X�V���O�C��
        ,cn_request_id                             -- �v��ID
        ,cn_program_application_id                 -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,cn_program_id                             -- �ݶ��ĥ��۸���ID
        ,cd_program_update_date                    -- �v���O�����X�V��
      );
      --
      -- �o�^����
      gn_header_normal_cnt := gt_ins_h_header_id.COUNT;
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
  END insert_ship_header_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line
   * Description      : �󒍖��׍X�V(A-11)
   ***********************************************************************************/
  PROCEDURE update_order_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line'; -- �v���O������
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
    cn_index                   CONSTANT NUMBER := 1;    -- �C���f�b�N�X
    cn_version                 CONSTANT NUMBER := 1.0;  -- API�̃o�[�W����
    --
    -- *** ���[�J���ϐ� ***
    ln_cnt                     NUMBER;                  -- �J�E���^
    lv_key_info                VARCHAR2(1000);          -- �L�[���
    lv_order_number            VARCHAR2(100);           -- �󒍔ԍ�
    lv_line_number             VARCHAR2(100);           -- ���הԍ�
    lv_table_name              VARCHAR2(100);           -- �e�[�u����
    ln_header_key              NUMBER;                  -- PL/SQL�\�̃L�[
    -- �󒍖��׍X�VAPI�p
    lt_header_rec              OE_ORDER_PUB.Header_Rec_Type;
    lt_header_val_rec          OE_ORDER_PUB.Header_Val_Rec_Type;
    lt_header_adj_tbl          OE_ORDER_PUB.Header_Adj_Tbl_Type;
    lt_header_adj_val_tbl      OE_ORDER_PUB.Header_Adj_Val_Tbl_Type;
    lt_header_price_att_tbl    OE_ORDER_PUB.Header_Price_Att_Tbl_Type;
    lt_header_adj_att_tbl      OE_ORDER_PUB.Header_Adj_Att_Tbl_Type;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.Header_Adj_Assoc_Tbl_Type;
    lt_header_scredit_tbl      OE_ORDER_PUB.Header_Scredit_Tbl_Type;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.Header_Scredit_Val_Tbl_Type;
    lt_line_tbl                OE_ORDER_PUB.Line_Tbl_Type;
    lt_line_val_tbl            OE_ORDER_PUB.Line_Val_Tbl_Type;
    lt_line_adj_tbl            OE_ORDER_PUB.Line_Adj_Tbl_Type;
    lt_line_adj_val_tbl        OE_ORDER_PUB.Line_Adj_Val_Tbl_Type;
    lt_line_price_att_tbl      OE_ORDER_PUB.Line_Price_Att_Tbl_Type;
    lt_line_adj_att_tbl        OE_ORDER_PUB.Line_Adj_Att_Tbl_Type;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.Line_Adj_Assoc_Tbl_Type;
    lt_line_scredit_tbl        OE_ORDER_PUB.Line_Scredit_Tbl_Type;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.Line_Scredit_Val_Tbl_Type;
    lt_lot_serial_tbl          OE_ORDER_PUB.Lot_Serial_Tbl_Type;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.Lot_Serial_Val_Tbl_Type;
    lt_action_request_tbl      OE_ORDER_PUB.Request_Tbl_Type;
    lv_return_status           VARCHAR2(2);
    ln_msg_count               NUMBER := 0;
    lv_msg_data                VARCHAR2(2000);
    ln_count                   NUMBER;
    --
    l_count  number;
    -- *** ���[�J����O ***
    order_line_update_expt      EXCEPTION;    -- �󒍖��׍X�V�G���[
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
    -- ���׍X�V�f�[�^�쐬
    -- ===============================
    ------------------------------
    -- ���׃f�[�^�ݒ�
    ------------------------------
    <<make_line_data>>
    FOR ln_idx IN 0..gt_ins_l_header_id.LAST LOOP
      gt_upd_order_line_tbl(ln_idx).header_id := gt_upd_header_id(ln_idx);                   -- �w�b�_ID(��)
      gt_upd_order_line_tbl(ln_idx).line_id := gt_ins_l_line_id(ln_idx);                     -- ����ID
      gt_upd_order_line_tbl(ln_idx).line_number := gt_ins_l_line_number(ln_idx);             -- ���הԍ�
      gt_upd_order_line_tbl(ln_idx).ship_from_org_id := gt_ins_l_ship_from_org_id(ln_idx);   -- �g�D
      gt_upd_order_line_tbl(ln_idx).req_header_id := gt_ins_l_header_id(ln_idx);              -- �w�b�_ID(�˗�)
    END LOOP make_line_data;
    --
    ------------------------------
    -- ����w���ݒ�
    ------------------------------
    <<loop_line_data>>
    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
      <<set_packing_inst>>
      FOR ln_cnt IN 0..gt_ins_h_header_id.LAST LOOP
        ln_header_key := ln_cnt;
        EXIT WHEN gt_upd_order_line_tbl(ln_idx).req_header_id = gt_ins_h_header_id(ln_cnt);
      END LOOP set_packing_inst;
      --
      -- ����w���ɏo�׈˗��ԍ���ݒ�
      gt_upd_order_line_tbl(ln_idx).order_source_ref := gt_ins_h_order_source_ref(ln_header_key);
      gt_upd_order_line_tbl(ln_idx).order_number := gt_ins_h_order_number(ln_header_key);
    END LOOP loop_line_data;
    --
    -- OM���b�Z�[�W���X�g�̏�����
    OE_MSG_PUB.INITIALIZE;
    --
    -- ===============================
    -- ���׍X�V
    -- ===============================
    <<update_line_data>>
    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
      lt_line_tbl(cn_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation := OE_GLOBALS.G_OPR_UPDATE;                                     -- �������[�h
      lt_line_tbl(cn_index).line_id := gt_upd_order_line_tbl(ln_idx).line_id;                         -- ����ID
      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- �g�DID
      lt_line_tbl(cn_index).packing_instructions := gt_upd_order_line_tbl(ln_idx).order_source_ref;   -- ����w��
      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- �g�DID
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
      lt_line_tbl(cn_index).program_id := cn_program_id;
      lt_line_tbl(cn_index).program_update_date := cd_program_update_date;
      lt_line_tbl(cn_index).request_id := cn_request_id;
      --
      --================================================================--
      -- Process Order API
      --================================================================--
      OE_ORDER_PUB.PROCESS_ORDER(
         -- IN Variables
         p_api_version_number      => cn_version
        ,p_line_tbl                => lt_line_tbl
         -- OUT Variables
        ,x_header_rec              => lt_header_rec
        ,x_header_val_rec          => lt_header_val_rec
        ,x_header_adj_tbl          => lt_header_adj_tbl
        ,x_header_adj_val_tbl      => lt_header_adj_val_tbl
        ,x_header_price_att_tbl    => lt_header_price_att_tbl
        ,x_header_adj_att_tbl      => lt_header_adj_att_tbl
        ,x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
        ,x_header_scredit_tbl      => lt_header_scredit_tbl
        ,x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
        ,x_line_tbl                => lt_line_tbl
        ,x_line_val_tbl            => lt_line_val_tbl
        ,x_line_adj_tbl            => lt_line_adj_tbl
        ,x_line_adj_val_tbl        => lt_line_adj_val_tbl
        ,x_line_price_att_tbl      => lt_line_price_att_tbl
        ,x_line_adj_att_tbl        => lt_line_adj_att_tbl
        ,x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
        ,x_line_scredit_tbl        => lt_line_scredit_tbl
        ,x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
        ,x_lot_serial_tbl          => lt_lot_serial_tbl
        ,x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
        ,x_action_request_tbl      => lt_action_request_tbl
        ,x_return_status           => lv_return_status
        ,x_msg_count               => ln_msg_count
        ,x_msg_data                => lv_msg_data
      );
      --
      -- API���s���ʊm�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        -- ���׍X�V�G���[
        -- ���b�Z�[�W������擾(�󒍔ԍ�)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_order_number             -- ���b�Z�[�WID
        );
        --
        -- ���b�Z�[�W������擾(���הԍ�)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_line_number              -- ���b�Z�[�WID
        );
        --�L�[���̕ҏW����
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- �󒍔ԍ�
         ,iv_data_value1    => gt_upd_order_line_tbl(ln_idx).order_number
         ,iv_item_name2     => lv_line_number                   -- ���הԍ�
         ,iv_data_value2    => gt_upd_order_line_tbl(ln_idx).line_number
         ,ov_key_info       => lv_key_info                      -- �ҏW��L�[���
         ,ov_errbuf         => lv_errbuf                        -- �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       -- ���^�[���R�[�h
         ,ov_errmsg         => lv_errmsg                        -- ���[�U�E�G���[�E���b�Z�[�W
        );
        RAISE order_line_update_expt;
      END IF;
    END LOOP update_line_data;
--
  EXCEPTION
    WHEN order_line_update_expt THEN
      --*** �󒍖��׍X�V�G���[ ***
      -- ���b�Z�[�W������擾(�󒍖���)
      lv_table_name := xxccp_common_pkg.get_msg(
             iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
            ,iv_name        => cv_msg_line_number              -- ���b�Z�[�WID
          );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_update_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_order_line;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code     IN  VARCHAR2,     -- 1.���_�R�[�h
    iv_order_number  IN  VARCHAR2,     -- 2.�󒍔ԍ�
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_retcode_a3           VARCHAR2(1);    -- A-3�̃��^�[���R�[�h�i�[
    lv_retcode_a5           VARCHAR2(1);    -- A-5�̃��^�[���R�[�h�i�[
--
    -- *** ���[�J����O ***
    no_data_found_expt      EXCEPTION;      -- ���o�f�[�^����
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
    gn_target_cnt        := 0;
    gn_header_normal_cnt := 0;
    gn_line_normal_cnt   := 0;
    gn_error_cnt         := 0;
    gn_warn_cnt          := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_base_code     => iv_base_code        -- ���_�R�[�h
      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �󒍃f�[�^�擾(A-2)
    -- ===============================
    get_order_data(
       iv_base_code     => iv_base_code        -- ���_�R�[�h
      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE no_data_found_expt;
    END IF;
--
    lv_retcode_a3 := cv_status_normal;
    lv_retcode_a5 := cv_status_normal;
    --
    <<make_ship_data>>
    FOR ln_idx IN gt_order_extra_tbl.FIRST..gt_order_extra_tbl.LAST LOOP
      -- ===============================
      -- �o�׌��ۊǏꏊ�擾(A-3)
      -- ===============================
      get_ship_subinventory(
         it_order_rec          => gt_order_extra_tbl(ln_idx)                 -- �󒍃f�[�^
        ,ov_ship_subinventory  => gt_order_extra_tbl(ln_idx).ship_to_subinv  -- �o�׌��ۊǏꏊ
        ,ov_errbuf             => lv_errbuf                                  -- �G���[�E���b�Z�[�W
        ,ov_retcode            => lv_retcode                                 -- ���^�[���E�R�[�h
        ,ov_errmsg             => lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a3 := cv_status_warn;
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �o�ח\����擾(A-4)
      -- ===============================
      IF ( lv_retcode = cv_status_normal ) THEN
        get_ship_schedule_date(
           it_order_rec   => gt_order_extra_tbl(ln_idx)                       -- �󒍃f�[�^
          ,od_oprtn_day   => gt_order_extra_tbl(ln_idx).schedule_ship_date    -- �o�ח\���
          ,on_lead_time   => gt_order_extra_tbl(ln_idx).lead_time             -- ���[�h�^�C��(���Y����)
          ,on_delivery_lt => gt_order_extra_tbl(ln_idx).delivery_lt           -- ���[�h�^�C��(�z��)
          ,ov_errbuf      => lv_errbuf                                        -- �G���[�E���b�Z�[�W
          ,ov_retcode     => lv_retcode                                       -- ���^�[���E�R�[�h
          ,ov_errmsg      => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      -- ===============================
      -- �f�[�^�`�F�b�N(A-5)
      -- ===============================
      data_check(
         it_order_rec  => gt_order_extra_tbl(ln_idx)                 -- �󒍃f�[�^
        ,ov_errbuf     => lv_errbuf                                  -- �G���[�E���b�Z�[�W
        ,ov_retcode    => lv_retcode                                 -- ���^�[���E�R�[�h
        ,ov_errmsg     => lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a5 := cv_status_warn;
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      IF ( ( lv_retcode <> cv_status_normal ) 
           OR ( lv_retcode_a3 = cv_status_warn ) )
      THEN
        -- ����łȂ��ꍇ�A�G���[�t���O��ݒ�
        gt_order_extra_tbl(ln_idx).check_status := cn_check_status_error;
        --
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END LOOP make_ship_data;
    --
    -- ===============================
    -- PL/SQL�\�ݒ�(A-6)
    -- ===============================
    make_normal_order_data(
       ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
      -- ����f�[�^������ꍇ
      -- ====================================================
      -- �o�׈˗�I/F���׃o���N�o�C���h�f�[�^�쐬(A-7)
      -- ====================================================
      make_request_line_bulk_data(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- �o�׈˗�I/F�w�b�_�o���N�o�C���h�f�[�^�쐬(A-8)
      -- ====================================================
      make_request_head_bulk_data(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- �o�׈˗�I/F���׃f�[�^�쐬(A-9)
      -- ====================================================
      insert_ship_line_data(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- �o�׈˗�I/F�w�b�_�f�[�^�쐬(A-10)
      -- ====================================================
      insert_ship_header_data(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- �󒍖��׍X�V(A-11)
      -- ====================================================
      update_order_line(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- submain�̃��^�[���R�[�h����
    IF ( cv_status_warn IN ( lv_retcode_a3
                            ,lv_retcode_a5 ) )
    THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN no_data_found_expt THEN
      -- ���o�f�[�^�Ȃ�
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
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
    errbuf           OUT VARCHAR2,         --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode          OUT VARCHAR2,         --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code     IN  VARCHAR2,         -- 1.���_�R�[�h
    iv_order_number  IN  VARCHAR2          -- 2.�󒍔ԍ�
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
       iv_base_code       -- ���_�R�[�h
      ,iv_order_number    -- �󒍔ԍ�
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
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
    --���������o��(�w�b�_�[)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_header_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_header_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��(����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_line_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_line_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCOS008A01C;
/
