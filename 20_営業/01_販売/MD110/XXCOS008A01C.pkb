CREATE OR REPLACE PACKAGE BODY      APPS.XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(body)
 * Description      : �H�꒼���o�׈˗�IF�쐬���s��
 * MD.050           : �H�꒼���o�׈˗�IF�쐬 MD050_COS_008_A01
 * Version          : 1.19
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
 *  start_production_system     ���Y�V�X�e���N��(A-12)
 *  weight_check                �ύڌ����œK���`�F�b�N(A-14)
 *  order_line_division         �󒍖��׃f�[�^��������(A-15)
 *  order_line_insert           �󒍖��דo�^(A-16)
 *  get_delivery                �z����擾(A-17)
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
 *  2009/04/06    1.4   T.Kitajima       [T1_0175]�o�׈˗�No�̔ԃ��[���ύX[9]��[97]
 *  2009/04/16    1.5   T.Kitajima       [T1_0609]�o�׈˗�No�̔ԃ��[���ύX[97]��[98]
 *  2009/05/15    1.6   S.Tomita         [T1_1004]���Y����S�ւ�UO�ؑ�/�߂��A[�ڋq��������̎����쐬]�@�\�ďo�Ή�
 *  2009/05/26    1.7   T.Kitajima       [T1_0457]�đ��Ή�
 *  2009/07/07    1.8   T.Miyata         [0000478]�ڋq���ݒn�̒��o�����ɗL���t���O��ǉ�
 *  2009/07/13    1.9   T.Miyata         [0000293]�o�ח\����^�󒍓��Z�o���̃��[�h�^�C���ύX
 *  2009/07/14    1.10  K.Kiriu          [0000063]���敪�̉ۑ�Ή�
 *  2009/07/28    1.11  M.Sano           [0000137]�ҋ@�Ԋu�ƍő�ҋ@���Ԃ��v���t�@�C���ɂĎ擾
 *  2009/09/16    1.12  K.Atsushiba      [0001232]�G���[�t���O�ێ��G���A�̏������Ή�
 *                                       [0000067]�ԍڏd�ʌv�Z���ʂ����������H��o�׃f�[�^�쐬�@�\�ǉ�
 *                                       [0001113]���[�h�^�C���Z�o�Ή�
 *                                       [0001389]PT�Ή�
 *  2009/10/19    1.13  K.Atsushiba      [0001544]�[�i���_�˔��㋒�_�ɕύX�A�[�i�\����ғ����`�F�b�N�̖������Ή�
 *  2009/11/04    1.14  K.Atsushiba      [0000067]�o�׌��ۊǏꏊ�擾�̏�����[�i���_���甄�㋒�_�ɕύX
 *                                                �o�׈˗��w�b�_.���͋��_�����O�C�����[�U�̎����_�R�[�h�ɕύX
 *                                                [A-12]�̃��O�C�����[�U�̎����_�擾���������������Ɉړ����A�O���[�o���ϐ���
 *  2009/11/22    1.15  S.Miyakoshi      [I_E_698](A-3)�����\���}�X�^����������ۂɎq�R�[�h�Ō�������悤�ύX
 *                                                (A-5)�o�׋敪�A���敪�A�ڋq�󒍉\�t���O�͎q�R�[�h�Ń`�F�b�N����悤�ύX
 *                                                (A-5)����Ώۋ敪�́A�q�R�[�h������΃`�F�b�N�����A�Ȃ���΃`�F�b�N����悤�ύX
 *  2009/11/24    1.16  N.Maeda          [E_�{�ғ�_00014] �o�׎w���̉��s�R�[�h�Ή�
 *  2009/11/25    1.17  K.Atsushiba      [E_�{�ғ�_00034]���[�t�̏o�׈˗������ז��ɍ쐬����Ȃ��悤�ɏC��
 *  2009/12/01    1.18  K.Atsushiba      [E_�{�ғ�_00206]�������[�v�Ή�
 *  2009/12/07    1.19  K.Atsushiba      [E_�{��_00247]�q�R�[�h���ݒ肳��Ă���ꍇ�͎q�R�[�h�ŏd�ʌv�Z����悤�ɏC��
 *                                       [E_�{�ғ�_00305]�q�R�[�h���ݒ肳��Ă���ꍇ�͎q�R�[�h�ŏo�׈˗����쐬����悤�ɏC��
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
/* 2009/09/16 Ver.1.12 Add Start */
  cv_xxcoi_short_name           CONSTANT VARCHAR2(10) := 'XXCOI';
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/07/28 Ver.1.11 Add Start */
  cv_msg_interval               CONSTANT VARCHAR2(30) := 'APP-XXCOS1-11645';    -- �ҋ@�Ԋu
  cv_msg_max_wait               CONSTANT VARCHAR2(30) := 'APP-XXCOS1-11646';    -- �ő�ҋ@�Ԋu
/* 2009/07/28 Ver.1.11 Add End   */
  -- �v���t�@�C��
  cv_pf_org_id                  CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO:�c�ƒP��
  cv_pf_ou_mfg                  CONSTANT VARCHAR2(30) := 'XXCOS1_ITOE_OU_MFG';  -- ���Y�c�ƒP��
/* 2009/07/28 Ver.1.11 Add Start */
  cv_pf_interval                CONSTANT VARCHAR2(30) := 'XXCOS1_INTERVAL';      -- �ҋ@�Ԋu
  cv_pf_max_wait                CONSTANT VARCHAR2(30) := 'XXCOS1_MAX_WAIT';      -- �ő�ҋ@�Ԋu
/* 2009/07/28 Ver.1.11 Add End   */
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_profile                CONSTANT VARCHAR2(20) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_param1                 CONSTANT VARCHAR2(20) := 'PARAM1';              -- �p�����[�^1
  cv_tkn_param2                 CONSTANT VARCHAR2(20) := 'PARAM2';              -- �p�����[�^2
--****************************** 2009/05/26 1.7 T.Kitajima ADD START ******************************--
  cv_tkn_param3                 CONSTANT VARCHAR2(20) := 'PARAM3';              -- �p�����[�^3
--****************************** 2009/05/26 1.7 T.Kitajima ADD  END  ******************************--
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
  cn_customer_div_cust          CONSTANT  VARCHAR2(4)   := '10';          -- �ڋq
  cv_cust_site_use_code         CONSTANT  VARCHAR2(10)  := 'SHIP_TO';     --�ڋq�g�p�ړI�F�o�א�
  -- ���׃X�e�[�^�X
  cv_flow_status_cancelled      CONSTANT VARCHAR2(10) := 'CANCELLED';     -- ���
  cv_flow_status_closed         CONSTANT VARCHAR2(10) := 'CLOSED';        -- �N���[�Y
  -- �����萔
  cv_blank                      CONSTANT VARCHAR2(1) := '';               -- �󕶎�
  -- ���[�h�^�C��
  cn_lead_time_non              CONSTANT NUMBER := 0;                     -- ���[�h�^�C���Ȃ�
--****************************** 2009/05/15 1.7 T.Kitajima ADD START ******************************--
  --���M�t���O
  cv_new_send                   CONSTANT VARCHAR2(1)  := '1';
  cv_re_send                    CONSTANT VARCHAR2(1)  := '2';
--****************************** 2009/05/15 1.7 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/07 1.8 T.Miyata ADD  START ******************************--
  --�ڋq�}�X�^�n�̗L���t���O
  cv_cust_status_active         CONSTANT VARCHAR2(1)  := 'A';             -- �L��
--****************************** 2009/07/07 1.8 T.Miyata ADD  END   ******************************--
/* 2009/07/14 Ver1.10 Add Start */
  --���敪
  cv_target_order_01            CONSTANT VARCHAR2(2)  := '01';            -- �󒍍쐬�Ώ�01
/* 2009/07/14 Ver1.10 Add End   */
/* 2009/09/16 Ver.1.12 Add Start */
  cv_lang                       CONSTANT VARCHAR2(5)  := USERENV('LANG');              -- ����
  cv_prod_class_drink           CONSTANT VARCHAR2(1)  := '2';                          -- ���i�敪:�h�����N
  cv_prod_class_leaf            CONSTANT VARCHAR2(1)  := '1';                          -- ���i�敪:���[�t
  cn_inactive_ind_on            CONSTANT NUMBER       := 1;                            -- �����敪�F����
  cv_obsolete_class_on          CONSTANT VARCHAR2(1)  := '1';                          -- �p�~�敪�F�p�~
  cv_weight_capacity_class      CONSTANT VARCHAR2(30) := 'XXCOS1_WEIGHT_CAPACITY_CLASS';  -- �d�ʗe�ϋ敪
  cv_pf_organization_cd         CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:�݌ɑg�D�R�[�h
  cv_resp_prod                  CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- �v���t�@�C���F���Y�ւ̐ؑ֗p�E��
  cv_weight_capacity_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13951';           -- �d�ʗe�ϋ敪�擾�G���[
  cv_msg_get_login              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11638';           -- ���O�C�����擾�G���[
  cv_msg_get_resp               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11639';           -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
  cv_msg_get_login_prod         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11640';           -- �ؑ֐惍�O�C�����擾�G���[
  cv_uom_cnv_err                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11648';           -- ��P�ʁE����ʎ擾�G���[
  cv_calc_total_value_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11649';           -- ���v�d�ʁE���v�e�ώ擾�G���[
  cv_base_code_err              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13952';           -- ���_�擾�G���[
  cv_delivery_code_err          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13953';           -- �z����擾�G���[
  cv_max_ship_method_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13954';           -- �ő�z���敪�擾�G���[
  cv_leaf_capacity_over_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13955';           -- ���[�t�ύڌ����I�[�o�[
  cv_msg_item_name              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13956';           -- ���b�Z�[�W������:�i��
  cv_msg_quantity               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13957';           -- ���b�Z�[�W������:����
  cv_calc_load_efficiency_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13958';           -- �ύڌ����Z�o�G���[
  cv_msg_max_ship_methods       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13959';           -- �����敪�擾�G���[
  cv_msg_quantity_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13960';           -- �󒍐��ʃG���[
  cv_msg_warn_end               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13961';           -- �x���I�����b�Z�[�W
  cv_msg_item_set_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13962';           -- �i�ڃ}�X�^�ݒ�G���[
  cv_msg_palette_qty            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13963';           -- ���b�Z�[�W����:�p���z��
  cv_msg_step_qty               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13964';           -- ���b�Z�[�W����:�p���i��
  cv_line_insert_err            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';           -- �f�[�^�o�^�G���[
  cv_msg_organization_id        CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';           -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_organization_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';           -- XXCOI:�݌ɑg�D�R�[�h
  cv_tkn_org_code_tok           CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';               -- �݌ɑg�D�R�[�h
  cv_tkn_order_source           CONSTANT VARCHAR2(30) := 'ORDER_SOURCE';               -- �o�׈˗�NO
  cv_tkn_ship_method            CONSTANT VARCHAR2(30) := 'SHIP_METHOD';                -- �o�ו��@
  cv_tkn_schedule_ship_date     CONSTANT VARCHAR2(30) := 'SCHEDULE_SHIP_DATE';         -- �o�ח\���
  cv_tkn_item_code              CONSTANT VARCHAR2(30) := 'ITEM_CODE';                  -- �i��
  cv_tkn_ordered_quantity       CONSTANT VARCHAR2(30) := 'ORDERED_QUANTITY';           -- �󒍐���
  cv_tkn_case_quantity          CONSTANT VARCHAR2(30) := 'CASE_QUANTITY';              -- �P�[�X����
  cv_tkn_MAX_SHIP_METHODS       CONSTANT VARCHAR2(30) := 'MAX_SHIP_METHODS';           -- �ő�z���敪
  cv_tkn_quantity               CONSTANT VARCHAR2(30) := 'ORDERED_QUANTITY';
  cv_tkn_schedule_date          CONSTANT VARCHAR2(30) := 'SCHEDULE_SHIP_DATE';
  cv_tkn_err_msg                CONSTANT VARCHAR2(30) := 'ERR_MSG';
  gn_deliv_cnt                  NUMBER DEFAULT 1;                                      -- �o�׈˗�IF�pPL/SQL�\�J�E���^
  gn_organization_id            NUMBER;                                                -- �݌ɑg�DID
  gv_weight_class_leaf          VARCHAR2(1);
  gv_weight_class_drink         VARCHAR2(1);
  gt_shipping_class             fnd_lookup_values.attribute2%TYPE;                     -- �o�׈˗��敪
  gn_check_flag_on              CONSTANT NUMBER := '1';
/* 2009/09/16 Ver.1.12 Add End */
/* 2009/11/04 Ver.1.14 Add Start */
  gt_input_base_code            xxcmn_cust_accounts_v.party_number%TYPE;                      -- ���͋��_
  cv_msg_get_input_base         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11642';                  -- ���͋��_�擾�G���[
/* 2009/11/04 Ver.1.14 Add End */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                     fnd_profile_option_values.profile_option_value%TYPE;      -- MO:�c�ƒP��
  gt_ou_mfg                     fnd_profile_option_values.profile_option_value%TYPE;      -- ���Y�c�ƒP��
  gd_business_date              DATE;                                                     -- �Ɩ����t
  gn_prod_ou_id                 NUMBER;                                                   -- ���Y�c�ƒP��ID
  gv_hokan_direct_class         VARCHAR2(10);                                             -- �ۊǏꏊ����(�����q��)
/* 2009/07/28 Ver.1.11 Add Start */
  gt_max_wait                   fnd_profile_option_values.profile_option_value%TYPE;      -- �ő�Ď�����
  gt_interval                   fnd_profile_option_values.profile_option_value%TYPE;      -- �Ď��Ԋu
/* 2009/07/28 Ver.1.11 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR order_data_cur(
--****************************** 2009/05/15 1.7 T.Kitajima ADD START ******************************--
    iv_send_flg     IN  VARCHAR2,     -- �V�K/�đ��敪
--****************************** 2009/05/15 1.7 T.Kitajima ADD  END  ******************************--
    iv_base_code    IN  VARCHAR2,     -- ���_�R�[�h
    iv_order_number IN  VARCHAR2)     -- �󒍔ԍ�
  IS
/* 2009/09/16 Ver.1.12 Mod Start */
    SELECT 
           /*+
                 LEADING(xca)
                 INDEX(xca xxcmm_cust_accounts_n21)
                 USE_NL(hca ooha ottah flv_tran)
                 USE_NL(ooha oola ottal msi)
           */
           ooha.context                              context                 -- �󒍃^�C�v
--    SELECT ooha.context                              context                 -- �󒍃^�C�v
/* 2009/09/16 Ver.1.12 Mod End */
          ,TRUNC(ooha.ordered_date)                  ordered_date            -- �󒍓�
          ,ooha.sold_to_org_id                       sold_to_org_id          -- �ڋq�R�[�h
          ,ooha.shipping_instructions                shipping_instructions   -- �o�׎w��
/* 2009/09/16 Ver.1.12 Mod Start */
          ,NVL(ooha.attribute19,
               DECODE(SUBSTR(ooha.cust_po_number, 1, 1),'I','', ooha.cust_po_number))
                                                      cust_po_number          -- �ڋq����
--          ,ooha.cust_po_number                       cust_po_number          -- �ڋq����
/* 2009/09/16 Ver.1.12 Mod End */
          ,TRUNC(oola.request_date)                  request_date            -- �v����
          ,NVL(oola.attribute6, oola.ordered_item)   child_code              -- �󒍕i��
          ,TRUNC(oola.schedule_ship_date)            schedule_ship_date      -- �\��o�ד�
          ,oola.ordered_quantity                     ordered_quantity        -- �󒍐���
          ,xca.delivery_base_code                    delivery_base_code      -- �[�i���_�R�[�h
/* 2009/09/16 Ver.1.12 Mod Start */
           ,NULL                                      province                -- �z����R�[�h      A-17�Őݒ�
--          ,hl.province                               province                -- �z����R�[�h
/* 2009/09/16 Ver.1.12 Mod End */
/* 2009/12/07 Ver1.19 Mod Start */
          ,NVL(oola.attribute6, oola.ordered_item)   item_code               -- �i�ڃR�[�h
          ,oola.ordered_item                          parent_item_code       -- �e�i�ڃR�[�h
          ,oola.context                               line_context           -- �R���e�L�X�g
--          ,msib.segment1                             item_code               -- �i�ڃR�[�h
/* 2009/12/07 Ver1.19 Mod End */
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
/* 2009/09/16 Ver.1.12 Mod Start */
          ,NULL                                      head_sort_key           -- �w�b�_�[�W��(�\�[�g)�L�[   A-5�Őݒ�
--          ,NULL                                      sort_key                -- �\�[�g�L�[
/* 2009/09/16 Ver.1.12 Mod End */
          ,cn_check_status_normal                    check_status            -- �`�F�b�N�X�e�[�^�X
/* 2009/09/16 Ver.1.12 Add Start */
          ,xca.rsv_sale_base_code                    rsv_sale_base_code      -- �\�񔄏㋒�_�R�[�h
          ,xca.rsv_sale_base_act_date                rsv_sale_base_act_date  -- �\�񔄏㋒�_�L���J�n��
          ,hca.account_number                        account_number          -- �ڋq�R�[�h
          ,oola.ship_to_org_id                       ship_to_org_id          -- �o�א�g�DID
          ,oola.order_source_id                      order_source_ref        -- �󒍃\�[�X�Q��
          ,oola.packing_instructions                 packing_instructions    -- �o�׈˗�NO
          ,oola.line_type_id                         line_type_id            -- ���׃^�C�v
          ,oola.attribute1                           attribute1
          ,oola.attribute2                           attribute2
          ,oola.attribute3                           attribute3
          ,oola.attribute4                           attribute4
          ,oola.attribute5                           attribute5
          ,oola.attribute6                           attribute6
          ,oola.attribute7                           attribute7
          ,oola.attribute8                           attribute8
          ,oola.attribute9                           attribute9
          ,oola.attribute10                          attribute10
          ,oola.attribute11                          attribute11
          ,oola.attribute12                          attribute12
          ,oola.attribute13                          attribute13
          ,oola.attribute14                          attribute14
          ,oola.attribute15                          attribute15
          ,oola.attribute16                          attribute16
          ,oola.attribute17                          attribute17
          ,oola.attribute18                          attribute18
          ,oola.attribute19                          attribute19
          ,oola.attribute20                          attribute20
          ,oola.global_attribute1                    global_attribute1
          ,oola.global_attribute2                    global_attribute2
          ,oola.global_attribute3                    global_attribute3
          ,oola.global_attribute4                    global_attribute4
          ,oola.global_attribute5                    global_attribute5
          ,oola.global_attribute6                    global_attribute6
          ,oola.global_attribute7                    global_attribute7
          ,oola.global_attribute8                    global_attribute8
          ,oola.global_attribute9                    global_attribute9
          ,oola.global_attribute10                   global_attribute10
          ,oola.global_attribute11                   global_attribute11
          ,oola.global_attribute12                   global_attribute12
          ,oola.global_attribute13                   global_attribute13
          ,oola.global_attribute14                   global_attribute14
          ,oola.global_attribute15                   global_attribute15
          ,oola.global_attribute16                   global_attribute16
          ,oola.global_attribute17                   global_attribute17
          ,oola.global_attribute18                   global_attribute18
          ,oola.global_attribute19                   global_attribute19
          ,oola.global_attribute20                   global_attribute20
          ,DECODE(xim.palette_max_step_qty, NULL, 1, 0, 1, xim.palette_max_step_qty)
                                                     palette_max_step_qty    -- �p���b�g����ő�i��
          ,DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1,xim.palette_max_cs_qty)  palette_max_cs_qty     -- �p���z��
          ,DECODE(xicv.prod_class_code, cv_prod_class_leaf,  gv_weight_class_leaf
                                      , cv_prod_class_drink, gv_weight_class_drink, NULL)    wc_class   -- �d�ʗe�ϋ敪
          ,DECODE(iim.attribute11, NULL, 1, '0', 1, TO_NUMBER(iim.attribute11))              qty_case   -- �{��/�P�[�X
          ,DECODE(iim.attribute11, NULL, 1, '0', 1, TO_NUMBER(iim.attribute11))
             *
             DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1, xim.palette_max_cs_qty)           qty_step   -- �{��/�i
          ,DECODE(xim.palette_max_step_qty, NULL, 1, 0, 1, xim.palette_max_step_qty)
             *
             DECODE(iim.attribute11, NULL, 1, 0, 1, TO_NUMBER(iim.attribute11))
             *
             DECODE(xim.palette_max_cs_qty, NULL, 1, 0, 1, xim.palette_max_cs_qty)           qty_palette   -- �{��/�p���b�g
          ,xim.palette_max_cs_qty                    original_palette_max_cs_qty                -- �p���z��
          ,xim.palette_max_step_qty                  original_palette_max_step_qty              -- �p���i��
          ,oola.schedule_ship_date                   original_schedule_ship_date                -- �\��o�ד�
          ,oola.request_date                         original_request_date                      -- �v����
          ,oola.subinventory                         subinventory                               -- �ۊǏꏊ
          ,oola.unit_selling_price                   unit_selling_price                         -- �̔��P��
          ,oola.orig_sys_line_ref                    orig_sys_line_ref                          -- ���הԍ�
          ,NULL                                      base_code               -- ���_(�[�i���_ or �\�񔄏㋒�_)  A-17�Őݒ�
          ,NULL                                      sum_pallet_weight       -- ���v�p���b�g�d��  A-5�Őݒ�
          ,NULL                                      base_quantity           -- ���Z�㐔��        A-6�Őݒ�
          ,NULL                                      add_base_quantity       -- ��{����          A-6�Őݒ�(���Z�l)
          ,NULL                                      add_sum_weight          -- ���v�d��          A-6�Őݒ�(���Z�l)
          ,NULL                                      add_sum_capacity        -- ���v�e��          A-6�Őݒ�(���Z�l)
          ,NULL                                      add_sum_pallet_weight   -- ���v�p���b�g�d��  A-6�Őݒ�(���Z�l)
          ,NULL                                      weight                  -- �d�ʗe��          A-6�Őݒ�
          ,0                                         checked_quantity        -- �`�F�b�N�ϐ���    A-15�Őݒ�
          ,NULL                                      delivery_unit           -- �o�׈˗��P��
          ,NULL                                      order_source            -- �o�׈˗�No        A-15�Őݒ�
          ,NULL                                      efficiency_over_flag    -- �ύڌ����I�[�o�t���O  A-15�Őݒ�
          ,NULL                                      max_ship_methods        -- �o�ו��@
          ,NULL                                      line_key                -- �o�׈˗����גP��  A-5�Őݒ�
          ,0                                         conv_palette            -- �p���b�g���Z��
          ,0                                         conv_step               -- �i��
          ,0                                         conv_case               -- �P�[�X
          ,0                                         total_conv_palette      -- �p���b�g
          ,0                                         total_conv_step         -- �i
          ,0                                         total_conv_case         -- �P�[�X
/* 2009/09/16 Ver.1.12 Add End */
/* 2009/09/19 Ver.1.13 Add Start */
          ,xca.sale_base_code                      sale_base_code      -- ���㋒�_�R�[�h
/* 2009/09/19 Ver.1.13 Add End */
    FROM   oe_order_headers_all                   ooha             -- �󒍃w�b�_
          ,oe_order_lines_all                     oola             -- �󒍖���
          ,hz_cust_accounts                       hca              -- �ڋq�}�X�^
          ,mtl_system_items_b                     msib             -- �i�ڃ}�X�^
          ,oe_transaction_types_tl                ottah            -- �󒍎���^�C�v�i�󒍃w�b�_�p�j
          ,oe_transaction_types_tl                ottal            -- �󒍎���^�C�v�i�󒍖��חp�j
          ,mtl_secondary_inventories              msi              -- �ۊǏꏊ�}�X�^
          ,xxcmn_item_categories5_v               xicv             -- ���i�敪View
          ,xxcmm_cust_accounts                    xca              -- �ڋq�ǉ����
/* 2009/09/16 Ver.1.12 Del Start */
--          ,hz_cust_acct_sites_all                 sites            -- �ڋq���ݒn
--          ,hz_cust_site_uses_all                  uses             -- �ڋq�g�p�ړI
--          ,hz_party_sites                         hps              -- �p�[�e�B�T�C�g�}�X�^
--          ,hz_locations                           hl               -- �ڋq���Ə��}�X�^
/* 2009/09/16 Ver.1.12 Del End */
          ,fnd_lookup_values                      flv_tran         -- LookUp�Q�ƃe�[�u��(����.�󒍃^�C�v)
/* 2009/09/16 Ver.1.12 Add Start */
          ,ic_item_mst_b                          iim              --OPM�i�ڃ}�X�^
          ,xxcmn_item_mst_b                       xim              --OPM�i�ڃA�h�I���}�X�^
/* 2009/09/16 Ver.1.12 Add End */
    WHERE ooha.header_id                          = oola.header_id                            -- �w�b�_�[ID
    AND   ooha.booked_flag                        = cv_booked_flag_end                        -- �X�e�[�^�X
/* 2009/07/14 Ver1.10 Add Start */
    AND   (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
/* 2009/07/14 Ver1.10 Add End   */
    AND   oola.flow_status_code                   NOT IN (cv_flow_status_cancelled
                                                         ,cv_flow_status_closed)              -- �X�e�[�^�X(����)
    AND   ooha.sold_to_org_id                     = hca.cust_account_id                       -- �ڋqID
    AND   ooha.order_type_id                      = ottah.transaction_type_id                 -- ����^�C�vID
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   ottah.language                          = cv_lang
--    AND   ottah.language                          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ottah.name                              = flv_tran.attribute1                       -- �������
    AND   oola.line_type_id                       = ottal.transaction_type_id
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   ottal.language                          = cv_lang
--    AND   ottal.language                          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ottal.name                              = flv_tran.attribute2                       -- �������
    AND   oola.subinventory                       = msi.secondary_inventory_name              -- �ۊǏꏊ
    AND   msi.attribute13                         = gv_hokan_direct_class                     -- �ۊǏꏊ�敪
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   xca.delivery_base_code                  = iv_base_code                                -- �[�i���_�R�[�h
--    AND   xca.delivery_base_code                  = NVL(iv_base_code, xca.delivery_base_code) -- �[�i���_�R�[�h
/* 2009/09/16 Ver.1.12 Mod End */
    AND   ooha.order_number                       = NVL(iv_order_number, ooha.order_number)   -- �󒍃w�b�_�ԍ�
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    AND   oola.packing_instructions               IS NULL                                     -- �o�׈˗�
    AND   ( 
            ( --�V�K
                  ( iv_send_flg               = cv_new_send )
              AND ( oola.packing_instructions IS NULL       )
            )
            OR
            ( --�đ�
                  ( iv_send_flg               = cv_re_send  )
              AND ( oola.packing_instructions IS NOT NULL   )
              AND NOT EXISTS (
                              SELECT xoha.request_no
                                FROM xxwsh_order_headers_all xoha                    -- �󒍃w�b�_�A�h�I��
                               WHERE xoha.request_no    = oola.packing_instructions  -- �˗�No = �󒍖���.�o�׈˗�No(����w��)
                             )
            )
          )
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
    AND   xca.customer_id                         = hca.cust_account_id                       -- �ڋqID
    AND   oola.org_id                             = gt_org_id                                 -- �c�ƒP��
/* 2009/12/07 Ver1.19 Mod Start */
    AND   NVL(oola.attribute6, oola.ordered_item) = msib.segment1                             -- �i�ڃR�[�h
--    AND   oola.ordered_item                       = msib.segment1                             -- �i�ڃR�[�h
/* 2009/12/07 Ver1.19 Mod End */
    AND   xicv.item_no                            = msib.segment1                             -- �i�ڃR�[�h
    AND   msib.organization_id                    = oola.ship_from_org_id                     -- �g�DID
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   hca.cust_account_id                     = sites.cust_account_id                     -- �ڋqID
--    AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- �ڋq�T�C�gID
/* 2009/09/16 Ver.1.12 Del End */
    AND   hca.customer_class_code                 = cn_customer_div_cust                      -- �ڋq�敪(�ڋq)
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   uses.site_use_code                      = cv_cust_site_use_code                     -- �ڋq�g�p�ړI(�o�א�)
--    AND   sites.org_id                            = gn_prod_ou_id                             -- ���Y�c�ƒP��
--    AND   uses.org_id                             = gn_prod_ou_id                             -- ���Y�c�ƒP��
----****************************** 2009/07/07 1.8 T.Miyata ADD  START ******************************--
--    AND   sites.status                            = cv_cust_status_active                     -- �ڋq���ݒn.�X�e�[�^�X
----****************************** 2009/07/07 1.8 T.Miyata ADD  END   ******************************--
--    AND   sites.party_site_id                     = hps.party_site_id                         -- �p�[�e�B�T�C�gID
--    AND   hps.location_id                         = hl.location_id                            -- ���Ə�ID
/* 2009/09/16 Ver.1.12 Del End */
    AND   hca.account_number                      IS NOT NULL                                 -- �ڋq�ԍ�
/* 2009/09/16 Ver.1.12 Del Start */
--    AND   hl.province                             IS NOT NULL                                 -- �z����R�[�h
/* 2009/09/16 Ver.1.12 Del End */
    AND   NVL(oola.attribute6,oola.ordered_item) 
              NOT IN ( SELECT flv_non_inv.lookup_code
                       FROM   fnd_lookup_values             flv_non_inv
                       WHERE  flv_non_inv.lookup_type       = cv_non_inv_item_mst_t
/* 2009/09/16 Ver.1.12 Mod Start */
                       AND    flv_non_inv.language          = cv_lang
--                       AND    flv_non_inv.language          = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
--                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
    AND   flv_tran.lookup_type                    = cv_tran_type_mst_t
/* 2009/09/16 Ver.1.12 Mod Start */
    AND   flv_tran.language                       = cv_lang
--    AND   flv_tran.language                       = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
    AND   flv_tran.enabled_flag                   = cv_enabled_flag
/* 2009/09/16 Ver.1.12 Add Start */
    AND   msi.organization_id                         = gn_organization_id
    AND   msib.organization_id                        = gn_organization_id
    AND   iim.item_no                                 = msib.segment1
    AND   iim.item_id                                 = xim.item_id
    AND   xim.start_date_active                      <= oola.request_date
    AND   NVL(xim.end_date_active,oola.request_date) >= oola.request_date
    AND   iim.inactive_ind                           <> cn_inactive_ind_on
    AND   xim.obsolete_class                         <> cv_obsolete_class_on
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    ,upd_status               VARCHAR2(1) DEFAULT NULL                            -- �X�V�X�e�C�^�X
/* 2009/09/16 Ver.1.12 Add End */
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
  gt_order_sort_wk_tbl                 g_v_order_data_ttype;              -- �󒍗p�\�[�g�f�[�^�i�[
  gt_upd_order_line_tbl                gt_upd_order_line_ttype;           -- ���׍X�V�p
  gt_upd_header_id                     g_tab_l_upd_header_id;             -- ���׍X�V�p
/* 2009/09/16 Ver.1.12 Add Start */
  gt_normal_order_tbl                   g_v_order_data_ttype;              -- ����󒍗p
  gt_delivery_if_wk_tbl                 g_n_order_data_ttype;              -- �o�׈˗��p(���[�N)
  gt_order_upd_tbl                      g_n_order_data_ttype;              -- �󒍖��׍X�V�p
  gt_order_ins_tbl                      g_n_order_data_ttype;              -- �󒍖��דo�^�p
  -- �󒍖��דo�^�p���R�[�h�ϐ�
  TYPE gr_order_line_rtype IS RECORD(
      line_rec              oe_order_lines_all%ROWTYPE
     ,order_number          NUMBER
  );
  -- �󒍖��דo�^�p�ϐ�
  TYPE gt_line_ins_ttype IS TABLE OF  oe_order_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_line_ins_tbl            gt_line_ins_ttype;
/* 2009/09/16 Ver.1.12 Add End */
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
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN  VARCHAR2,            -- 1.���_�R�[�h
--    iv_order_number  IN  VARCHAR2,            -- 2.�󒍔ԍ�
    iv_send_flg      IN  VARCHAR2,            -- 1.�V�K/�đ��敪
    iv_base_code     IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_order_number  IN  VARCHAR2,            -- 3.�󒍔ԍ�
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END  ******************************--
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
/* 2009/09/16 Ver.1.12 Add Start */
    lv_organization_cd   fnd_profile_option_values.profile_option_value%TYPE := NULL;     -- �݌ɑg�D�R�[�h
/* 2009/09/16 Ver.1.12 Add End */
--
    -- *** ���[�J����O ***
    notfound_hokan_direct_expt   EXCEPTION;      -- �����q�ɕۊǏꏊ�敪�擾�G���[
    notfound_ou_org_id_expt      EXCEPTION;      -- ���Y�c�ƒP�ʎ擾�G���[
/* 2009/09/16 Ver.1.12 Add Start */
    notfound_weight_capacity_expt EXCEPTION;     -- �d�ʋ敪�擾�G���[
/* 2009/09/16 Ver.1.12 Add End */
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
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--      ,iv_token_name1  => cv_tkn_param1           -- ���_�R�[�h
--      ,iv_token_value1 => iv_base_code
--      ,iv_token_name2  => cv_tkn_param2         -- �󒍔ԍ�
--      ,iv_token_value2 => iv_order_number
      ,iv_token_name1  => cv_tkn_param1           -- �V�K/�đ��敪
      ,iv_token_value1 => iv_send_flg
      ,iv_token_name2  => cv_tkn_param2           -- ���_�R�[�h
      ,iv_token_value2 => iv_base_code
      ,iv_token_name3  => cv_tkn_param3           -- �󒍔ԍ�
      ,iv_token_value3 => iv_order_number
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
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
/* 2009/09/16 Ver.1.12 Mod Start */
      AND    flv.language        = cv_lang
--      AND    flv.language        = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
      AND    flv.enabled_flag    = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �����q�ɕۊǏꏊ���ގ擾�G���[
        RAISE notfound_hokan_direct_expt;
    END;
/* 2009/07/28 Ver.1.11 Add Start */
--
    -- ===============================
    --  �ҋ@�Ԋu
    -- ===============================
    gt_interval := FND_PROFILE.VALUE( name => cv_pf_interval );
    --
    IF ( gt_interval IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�ҋ@�Ԋu)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_interval                 -- ���b�Z�[�WID
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
    --  �ő�ҋ@����
    -- ===============================
    gt_max_wait := FND_PROFILE.VALUE( name => cv_pf_max_wait );
    --
    IF ( gt_max_wait IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�ő�ҋ@����)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_max_wait                 -- ���b�Z�[�WID
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
/* 2009/07/28 Ver.1.11 Add End */
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    --  �d�ʗe�ϋ敪
    -- ===============================
    BEGIN
      SELECT flv_l.attribute1     -- ���[�t�d�ʗe�ϋ敪
             ,flv_d.attribute1    -- �h�����N�d�ʗe�ϋ敪
      INTO   gv_weight_class_leaf
             ,gv_weight_class_drink
      FROM  fnd_lookup_values  flv_l
            ,fnd_lookup_values  flv_d
      WHERE flv_l.lookup_type = cv_weight_capacity_class
      AND   flv_l.language    = cv_lang
      AND   flv_l.enabled_flag    = cv_enabled_flag
      AND   flv_l.lookup_code = cv_prod_class_leaf
      AND   flv_d.lookup_type = cv_weight_capacity_class
      AND   flv_d.language    = cv_lang
      AND   flv_d.enabled_flag    = cv_enabled_flag
      AND   flv_d.lookup_code = cv_prod_class_drink;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
          ,iv_name         => cv_weight_capacity_err      -- ���b�Z�[�W
          ,iv_token_name1  => cv_tkn_type                 -- �g�[�N��1��
          ,iv_token_value1 => cv_weight_capacity_class);  -- �g�[�N��1�l
        RAISE  notfound_weight_capacity_expt;
    END;
    --
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    lv_organization_cd := FND_PROFILE.VALUE( name => cv_pf_organization_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( lv_organization_cd IS NULL ) THEN
      -- �v���t�@�C���i�݌ɑg�D�R�[�h�j�擾�G���[���o��
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_organization_cd                   -- ���b�Z�[�WID
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
    --==============================================================
    -- �݌ɑg�DID�̎擾
    --==============================================================
    IF ( lv_organization_cd IS NOT NULL ) THEN
--
      -- �݌ɑg�DID�擾
      gn_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_cd );
--
      -- �݌ɑg�DID���擾�ł��Ȃ������ꍇ
      IF ( gn_organization_id IS NULL ) THEN
        -- �݌ɑg�DID�擾�G���[���o��
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcoi_short_name         -- �A�v���P�[�V�����Z�k��
          ,iv_name         => cv_msg_organization_id     -- ���b�Z�[�W
          ,iv_token_name1  => cv_tkn_org_code_tok              -- �g�[�N��1��
          ,iv_token_value1 => lv_organization_cd);           -- �g�[�N��1�l
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    --
/* 2009/11/04 Ver.1.14 Add Start */
    --==============================================================
    -- ���O�C�����[�U�̎����_�R�[�h�̎擾
    --==============================================================
    BEGIN
      SELECT xlobi.base_code             input_base_code
        INTO gt_input_base_code
        FROM xxcos_login_own_base_info_v xlobi
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_input_base   -- ���͋��_�擾�G���[
                     );
        RAISE global_api_expt;
    END;
/* 2009/11/04 Ver.1.14 Add End */
  --
  EXCEPTION
/* 2009/09/16 Ver.1.12 Add Start */
    WHEN notfound_weight_capacity_expt THEN
      -- �d�ʋ敪�擾�G���[
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2009/09/16 Ver.1.12 Add End */
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
--
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
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code      IN  VARCHAR2,            -- 1.���_�R�[�h
--    iv_order_number   IN  VARCHAR2,            -- 2.�󒍔ԍ�
    iv_send_flg       IN  VARCHAR2,            -- 1.�V�K/�đ��敪
    iv_base_code      IN  VARCHAR2,            -- 2.���_�R�[�h
    iv_order_number   IN  VARCHAR2,            -- 3.�󒍔ԍ�
 --****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
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
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--         iv_base_code     => iv_base_code      -- ���_�R�[�h
--        ,iv_order_number  => iv_order_number   -- �󒍔ԍ�
         iv_send_flg      => iv_send_flg       -- �V�K/�đ��敪
        ,iv_base_code     => iv_base_code      -- ���_�R�[�h
        ,iv_order_number  => iv_order_number   -- �󒍔ԍ�
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        WHERE  xsr.item_code               = it_order_rec.item_code            -- �i�ڃR�[�h
        WHERE  xsr.item_code               = it_order_rec.child_code           -- �i�ڃR�[�h
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--          WHERE  xsr.item_code               = it_order_rec.item_code            -- �i�ڃR�[�h
          WHERE  xsr.item_code               = it_order_rec.child_code           -- �i�ڃR�[�h
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
/* 2009/11/04 Ver.1.14 Mod Start */
          AND    xsr.base_code               = it_order_rec.base_code            -- ���_�R�[�h
--          AND    xsr.base_code               = it_order_rec.delivery_base_code   -- ���_�R�[�h
/* 2009/11/04 Ver.1.14 Mod End */
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
/* 2009/11/04 Ver.1.14 Mod Start */
        AND    xsr.base_code               = it_order_rec.base_code            -- ���_�R�[�h
--        AND    xsr.base_code               = it_order_rec.delivery_base_code   -- ���_�R�[�h
/* 2009/11/04 Ver.1.14 Mod End */
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
/* 2009/11/04 Ver.1.14 Mod Start */
         ,iv_data_value5    => it_order_rec.base_code
--         ,iv_data_value5    => it_order_rec.delivery_base_code
/* 2009/11/04 Ver.1.14 Mod End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    ln_prod_user_id          NUMBER;
    ln_user_id               NUMBER;  -- ���O�C�����[�UID
    ln_resp_id               NUMBER;  -- ���O�C���E��ID
    ln_resp_appl_id          NUMBER;  -- ���O�C���E�ӃA�v���P�[�V����ID
    lt_resp_prod             fnd_profile_option_values.profile_option_value%TYPE;
    ln_prod_resp_id          NUMBER;  -- �ؑ֐�E��ID
    ln_prod_resp_appl_id     NUMBER;  -- �ؑ֐�E�ӃA�v���P�[�V����ID
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- ���O�C�����[�U���擾
    -- ===============================
    BEGIN
      SELECT    fnd_global.user_id  -- ���O�C�����[�UID
              ,fnd_global.resp_id       -- ���O�C���E��ID
              ,fnd_global.resp_appl_id  -- ���O�C���E�ӃA�v���P�[�V����ID
      INTO     ln_user_id
              ,ln_resp_id
              ,ln_resp_appl_id
      FROM    dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login        -- ���O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
    --
    -- ===================================================
    --  �v���t�@�C���uXXCOS:���Y�ւ̐ؑ֗p�E�Ӗ��́v�擾
    -- ===================================================
    lt_resp_prod := FND_PROFILE.VALUE(
      name => cv_resp_prod);
    --
    IF ( lt_resp_prod IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  �ؑ֐惍�O�C�����擾
    -- ===============================
    BEGIN
      SELECT  frv.responsibility_id    -- �ؑ֐�E��ID
              ,frv.application_id      -- �ؑ֐�E�ӃA�v���P�[�V����ID
      INTO    ln_prod_resp_id
              ,ln_prod_resp_appl_id
      FROM    fnd_responsibility_vl  frv
      WHERE   responsibility_name = lt_resp_prod
      AND     ROWNUM              = 1;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- �ؑ֐惍�O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
    --
    ln_prod_user_id := ln_user_id;
    --
    -- ===============================
    --  ���YOU�ւ̃��O�C���ؑ�
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
       user_id         => ln_prod_user_id            -- ���[�UID
      ,resp_id         => ln_prod_resp_id            -- �E��ID
      ,resp_appl_id    => ln_prod_resp_appl_id       -- �A�v���P�[�V����ID
    );
/* 2009/09/16 Ver.1.12 Add End */
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
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--      ,in_lead_time       => ln_lead_time                        -- ���[�h�^�C��
        ,in_lead_time       => ln_delivery_lt                      -- �z�����[�h�^�C��
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
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
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--        ,iv_token_value7 => TO_CHAR(ln_lead_time)
          ,iv_token_value7 => TO_CHAR(ln_delivery_lt)
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
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
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    --  �c��OU�ւ̃��O�C���ؑ�
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
       user_id         => ln_user_id            -- ���[�UID
      ,resp_id         => ln_resp_id            -- �E��ID
      ,resp_appl_id    => ln_resp_appl_id       -- �A�v���P�[�V����ID
    );
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    in_index       IN  NUMBER,                         -- 2.�C���f�b�N�X
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    cv_tkn_order_no      CONSTANT VARCHAR2(30) := 'ORDER_NO';
    cv_tkn_item_code     CONSTANT VARCHAR2(30) := 'ITEM_CODE';
    cv_tkn_quantity_uom  CONSTANT VARCHAR2(30) := 'ORDER_QUANTITY_UOM';
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    lv_organization_code  VARCHAR2(100);     -- �݌ɑg�D�R�[�h
    lv_item_code          VARCHAR2(20);      -- �i�ڃR�[�h
    ln_item_id            NUMBER;            -- �i��ID
    ln_organization_id    NUMBER;            -- �݌ɑg�DID
    ln_content            NUMBER;            -- ���� 
    ln_sum_weight         NUMBER;            -- ���v�d��
    ln_sum_capacity       NUMBER;            -- ���v�e��
    ln_sum_pallet_weight  NUMBER;            -- ���v�p���b�g�d��
    ln_mod                NUMBER;
    lv_base_uom           xxcos_sales_exp_lines.standard_uom_code%TYPE;     -- ��P��
    ln_base_quantity      xxcos_sales_exp_lines.standard_qty%TYPE;          -- �����
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Del Start */
--    IF ( it_order_rec.cust_po_number IS NULL ) THEN
--      -- ���ږ��擾
--      lv_item_name := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_cust_po_number
--      );
--      -- �o�̓��b�Z�[�W�쐬
--      lv_message := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_non_input_error
--        ,iv_token_name1  => cv_tkn_order_no                    -- �󒍔ԍ�
--        ,iv_token_value1 => it_order_rec.order_number
--        ,iv_token_name2  => cv_tkn_line_no                     -- ���הԍ�
--        ,iv_token_value2 => it_order_rec.line_number
--        ,iv_token_name3  => cv_tkn_field_name                  -- ���ږ�
--        ,iv_token_value3 => lv_item_name
--      );
--      -- ���b�Z�[�W�o��
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_message
--      );
--      -- ���^�[���R�[�h�ݒ�(�x��)
--      ov_retcode := cv_status_warn;
--    END IF;
/* 2009/09/16 Ver.1.12 Del End */
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
/* 2009/10/19 Ver.1.13 Add Start */
    IF ( it_order_rec.prod_class_code = cv_prod_class_drink ) THEN
      ----------------------------------
      -- �p���z��
      ----------------------------------
      IF (( it_order_rec.original_palette_max_cs_qty IS NULL )
          OR ( it_order_rec.original_palette_max_cs_qty = '0' ))
      THEN
        -- ���ݒ�A�܂��́A�[���̏ꍇ
        -- ���ږ��擾
        lv_item_name := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_palette_qty
        );
        -- �o�̓��b�Z�[�W�쐬
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_item_set_err
          ,iv_token_name1  => cv_tkn_field_name                    -- ����
          ,iv_token_value1 => lv_item_name
          ,iv_token_name2  => cv_tkn_order_no                    -- �󒍔ԍ�
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_item_code                    -- �i�ڃR�[�h
          ,iv_token_value3 => it_order_rec.item_code
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
      -- �p���i��
      ----------------------------------
      IF (( it_order_rec.original_palette_max_step_qty IS NULL )
          OR ( it_order_rec.original_palette_max_step_qty = '0' ))
      THEN
        -- ���ݒ�A�܂��́A�[���̏ꍇ
        -- ���ږ��擾
        lv_item_name := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_step_qty
        );
        -- �o�̓��b�Z�[�W�쐬
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_item_set_err
          ,iv_token_name1  => cv_tkn_field_name                    -- ����
          ,iv_token_value1 => lv_item_name
          ,iv_token_name2  => cv_tkn_order_no                      -- �󒍔ԍ�
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_item_code                     -- �i�ڃR�[�h
          ,iv_token_value3 => it_order_rec.item_code
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
/* 2009/10/19 Ver.1.13 Add End */
    --
    -- ===============================
    -- �敪�l�`�F�b�N
    -- ===============================
    --
/* 2009/09/16 Ver.1.12 Add Start [0001232] */
    -- �G���[�t���O�ێ��G���A�̏�����
    gt_item_info_rec.ship_class_flag := cn_check_status_normal;      -- �o�׋敪
    gt_item_info_rec.sales_div_flag := cn_check_status_normal;       -- ����Ώۋ敪
    gt_item_info_rec.rate_class_flag := cn_check_status_normal;      -- ���敪
    gt_item_info_rec.cust_order_flag := cn_check_status_normal;      -- �ڋq�󒍉\�t���O
/* 2009/09/16 Ver.1.12 Add End [0001232] */
    --
    -- �i�ڃf�[�^���擾�ς݂��`�F�b�N
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--    IF ( gt_item_info_tbl.EXISTS(it_order_rec.item_code) = TRUE ) THEN
--      -- �擾�ς݂̏ꍇ�A�ė��p����
--      gt_item_info_rec := gt_item_info_tbl(it_order_rec.item_code);
    IF ( gt_item_info_tbl.EXISTS(it_order_rec.child_code) = TRUE ) THEN
      -- �擾�ς݂̏ꍇ�A�ė��p����
      gt_item_info_rec := gt_item_info_tbl(it_order_rec.child_code);
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--      WHERE  ximv.item_no       = it_order_rec.item_code             -- �i�ڃR�[�h
      WHERE  ximv.item_no       = it_order_rec.child_code            -- �i�ڃR�[�h
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
      AND    gd_business_date   BETWEEN ximv.start_date_active       -- �L����From
                                AND     ximv.end_date_active;        -- �L����To
      --
      -- �ڋq�󒍉\�t���O�擾
      SELECT msib.customer_order_enabled_flag         -- �ڋq�󒍉\�t���O
      INTO   lv_cust_order_flag
      FROM   mtl_system_items_b       msib            -- �i�ڃ}�X�^
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--      WHERE  msib.inventory_item_id = it_order_rec.inventory_item_id       -- �i��ID
      WHERE  msib.segment1          = it_order_rec.child_code              -- �i�ڃR�[�h
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
      IF ( it_order_rec.item_code = it_order_rec.child_code ) THEN
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
      IF ( ( lv_sales_div IS NULL )
             OR ( lv_sales_div <> cv_normal_sales_div ) )
      THEN
        gt_item_info_rec.sales_div_flag := cn_check_status_error;
      END IF;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
      END IF;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD START ******************************--
--      gt_item_info_tbl(it_order_rec.item_code) := gt_item_info_rec;
      gt_item_info_tbl(it_order_rec.child_code) := gt_item_info_rec;
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
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
/* 2009/09/16 Ver.1.12 Mod Start */
        ,iv_token_value4 => lv_sales_div
--        ,iv_token_value4 => it_order_rec.item_code
/* 2009/09/16 Ver.1.12 Mod End */
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
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
--****************************** 2009/11/22 1.15 S.Miyakoshi MOD START ******************************--
--        ,iv_token_value4 => it_order_rec.item_code
        ,iv_token_value4 => it_order_rec.child_code
--****************************** 2009/11/22 1.15 S.Miyakoshi ADD  END  ******************************--
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
/* 2009/10/19 Ver.1.13 Del Start */
--    ln_result := xxwsh_common_pkg.get_oprtn_day(
--       id_date             => it_order_rec.request_date         -- ���t
--      ,iv_whse_code        => NULL                              -- �ۊǑq�ɃR�[�h
--      ,iv_deliver_to_code  => it_order_rec.province             -- �z����R�[�h
--      ,in_lead_time        => cn_lead_time_non                  -- ���[�h�^�C��
--      ,iv_prod_class       => it_order_rec.prod_class_code      -- ���i�敪
--      ,od_oprtn_day        => ld_ope_delivery_day               -- �ғ������t�[�i�\���
--    );
--    --
--    IF ( ld_ope_delivery_day IS NULL ) THEN
--      -- �ғ����擾�G���[
--      -- ���ږ��擾(�[�i�\���)
--      lv_item_name := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_deli_expect_date
--      );
--      -- ���b�Z�[�W�쐬
--      lv_message := xxccp_common_pkg.get_msg(
--         iv_application  => cv_xxcos_short_name
--        ,iv_name         => cv_msg_non_operation_date
--        ,iv_token_name1  => cv_tkn_operate_date                          -- �[�i�\���
--        ,iv_token_value1 => lv_item_name
--        ,iv_token_name2  => cv_tkn_order_no                              -- �󒍔ԍ�
--        ,iv_token_value2 => it_order_rec.order_number
--        ,iv_token_name3  => cv_tkn_line_no                               -- ���הԍ�
--        ,iv_token_value3 => it_order_rec.line_number
--        ,iv_token_name4  => cv_tkn_base_date                             -- �[�i�\���
--        ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
--        ,iv_token_name5  => cv_tkn_whse_locat                            -- �o�׌��ۊǏꏊ
--        ,iv_token_value5 => it_order_rec.ship_to_subinv
--        ,iv_token_name6  => cv_tkn_delivery_code                         -- �z����R�[�h
--        ,iv_token_value6 => it_order_rec.province
--        ,iv_token_name7  => cv_tkn_lead_time                             -- ���[�h�^�C��
--        ,iv_token_value7 => TO_CHAR(cn_lead_time_non)
--        ,iv_token_name8  => cv_tkn_commodity_class                       -- ���i�敪
--        ,iv_token_value8 => it_order_rec.item_div_name
--      );
--      -- ���b�Z�[�W�o��
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_message
--      );
--      -- ��s�o��
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => NULL
--      );
--      -- ���^�[���R�[�h�ݒ�(�x��)
--      ov_retcode := cv_status_warn;
--    ELSE
/* 2009/10/19 Ver.1.13 Del End */
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
/* 2009/10/19 Ver.1.13 Del Start */
--    END IF;
/* 2009/10/19 Ver.1.13 Del End */
    --
    -- ===============================
    -- �󒍓��`�F�b�N���ғ������`�F�b�N
    -- ===============================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.schedule_ship_date      -- ���t
      ,iv_whse_code        => NULL                                 -- �ۊǑq�ɃR�[�h
      ,iv_deliver_to_code  => it_order_rec.province                -- �z����R�[�h
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--    ,in_lead_time        => it_order_rec.delivery_lt             -- ���[�h�^�C��(���Y����)
      ,in_lead_time        => it_order_rec.lead_time               -- ���[�h�^�C��(���Y����)
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
      ,iv_prod_class       => it_order_rec.prod_class_code         -- ���i�敪
      ,od_oprtn_day        => ld_ope_request_day                   -- �ғ������t
    );
    --
/* 2009/10/19 Ver.1.13 Mod Start */
    IF (( ld_ope_request_day IS NULL )
          OR ( ln_result = 1 )) THEN
--    IF ( ld_ope_request_day IS NULL ) THEN
/* 2009/10/19 Ver.1.13 Mod End */
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
--****************************** 2009/07/13 1.9 T.Miyata MODIFY START ******************************--
--      ,iv_token_value7 => it_order_rec.delivery_lt
        ,iv_token_value7 => it_order_rec.lead_time
--****************************** 2009/07/13 1.9 T.Miyata MODIFY END   ******************************--
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
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- �i�ڊ֘A���擾
    -- ===============================
    lv_item_code := it_order_rec.item_code;
    xxcos_common_pkg.get_uom_cnv(
       iv_before_uom_code      => it_order_rec.order_quantity_uom     -- ���Z�O�P�ʃR�[�h
      ,in_before_quantity      => it_order_rec.ordered_quantity       -- ���Z�O����
      ,iov_item_code           => lv_item_code                        -- �i�ڃR�[�h
      ,iov_organization_code   => lv_organization_code                -- �݌ɑg�D�R�[�h
      ,ion_inventory_item_id   => ln_item_id                          -- �i��ID
      ,ion_organization_id     => ln_organization_id                  -- �݌ɑg�DID
      ,iov_after_uom_code      => lv_base_uom                         -- ���Z��P�ʃR�[�h
      ,on_after_quantity       => ln_base_quantity                    -- ���Z�㐔��
      ,on_content              => ln_content                          -- ����
      ,ov_errbuf               => lv_errbuf                           -- �G���[�E���b�Z�[�W�G���[
      ,ov_retcode              => lv_retcode                          -- ���^�[���E�R�[�h
      ,ov_errmsg               => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- ���^�[���R�[�h�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      -- ��P�ʁE����ʎ擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name           -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_uom_cnv_err                -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_order_no               -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_item_code              -- �󒍕i��
        ,iv_token_value2 => it_order_rec.item_code
        ,iv_token_name3  => cv_tkn_quantity               -- �󒍐���
        ,iv_token_value3 => it_order_rec.ordered_quantity
        ,iv_token_name4  => cv_tkn_quantity_uom           -- �󒍒P��
        ,iv_token_value4 => it_order_rec.order_quantity_uom
        ,iv_token_name5  => cv_tkn_err_msg                -- �G���[���b�Z�[�W
        ,iv_token_value5 => lv_errmsg
       );
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
      --
      ov_retcode := cv_status_warn;
    ELSE
      -- �l�ݒ�
      gt_order_extra_tbl(in_index).base_quantity := ln_base_quantity;          -- ���Z�㐔��
      gt_order_extra_tbl(in_index).conv_order_quantity_uom := lv_base_uom;     -- ���Z��P��
      -- �p���b�g���A�i���A�P�[�X���̎Z�o
      gt_order_extra_tbl(in_index).conv_palette := TRUNC(ln_base_quantity / gt_order_extra_tbl(in_index).qty_palette);
      ln_mod := MOD(ln_base_quantity , gt_order_extra_tbl(in_index).qty_palette);
      gt_order_extra_tbl(in_index).conv_step := TRUNC(ln_mod /  gt_order_extra_tbl(in_index).qty_step);
      ln_mod := MOD(ln_mod , gt_order_extra_tbl(in_index).qty_step);
      gt_order_extra_tbl(in_index).conv_case := TRUNC(ln_mod /  gt_order_extra_tbl(in_index).qty_case);
    END IF;
    --
    -- ========================================================
    -- ���v�d�ʁE���v�e�ρE���v�p���b�g�d�ʎ擾
    -- ========================================================
    xxwsh_common910_pkg.calc_total_value(
       iv_item_no            => it_order_rec.item_code              -- �i�ڃR�[�h
      ,in_quantity           => ln_base_quantity                    -- ����
      ,ov_retcode            => lv_retcode                          -- ���^�[���R�[�h
      ,ov_errmsg_code        => lv_errbuf                           -- �G���[���b�Z�[�W�R�[�h
      ,ov_errmsg             => lv_errmsg                           -- �G���[���b�Z�[�W
      ,on_sum_weight         => ln_sum_weight                       -- ���v�d��
      ,on_sum_capacity       => ln_sum_capacity                     -- ���v�e��
      ,on_sum_pallet_weight  => ln_sum_pallet_weight                -- ���v�p���b�g�d��
      ,id_standard_date      =>  it_order_rec.schedule_ship_date     -- ���(�K�p�����)
    );
    --
    -- ���^�[���R�[�h�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      -- ���v�d�ʁE���v�e�ώ擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name              -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_calc_total_value_err          -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_order_no                  -- �󒍔ԍ�
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_item_code                 -- �󒍕i��
        ,iv_token_value2 => it_order_rec.item_code
        ,iv_token_name3  => cv_tkn_quantity                  -- �󒍐���
        ,iv_token_value3 => it_order_rec.ordered_quantity
        ,iv_token_name4  => cv_tkn_schedule_date             -- �o�ח\���
        ,iv_token_value4 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_err_msg                   -- �G���[���b�Z�[�W
        ,iv_token_value5 => lv_errmsg
      );
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
      ov_retcode := cv_status_warn;
    ELSE
      -- �A�E�g�p�����[�^�ݒ�
      gt_order_extra_tbl(in_index).weight      := ln_sum_weight;     -- �i�ڒP�ʂ̏d��
    END IF;
     --
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    ln_max_valt               NUMBER DEFAULT 0;  -- �ő�d�ʗe��
    lv_idx                    VARCHAR2(1000);
    lv_head_key               VARCHAR2(1000);
    lv_output_msg             VARCHAR2(1000);
    lv_line_key               VARCHAR2(1000);
    ln_sum_weight             NUMBER;            -- ���v�d��
    ln_sum_capacity           NUMBER;            -- ���v�e��
    ln_sum_pallet_weight      NUMBER;            -- ���v�p���b�g�d��
    --
    TYPE lr_head_sum_rec IS RECORD(
       base_quantity        NUMBER DEFAULT 0      -- �����
      ,palette_quantity     NUMBER DEFAULT 0      -- �p���b�g��
      ,step_quantity        NUMBER DEFAULT 0      -- �i��
      ,case_quantity        NUMBER DEFAULT 0      -- �P�[�X��
    );
    -- ���Z�f�[�^�i�[�p
    TYPE it_head_sum_ttype IS TABLE OF lr_head_sum_rec INDEX BY VARCHAR2(1000);
    -- ���Z�f�[�^�ϐ�
    lt_head_sum_tbl        it_head_sum_ttype;
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Mod Start */
    -- ===============================
    -- ����ʂ̏W��
    -- ===============================
    <<sum_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
        -- �W��L�[�쐬
        lv_idx_key := 
          TO_CHAR(gt_order_extra_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep)             -- �󒍓�
          || gt_order_extra_tbl(ln_idx).province                                            -- �z����R�[�h
          || NVL(gt_order_extra_tbl(ln_idx).shipping_instructions , cv_blank)               -- �o�׎w��
          || NVL(gt_order_extra_tbl(ln_idx).cust_po_number , cv_blank)                      -- �ڋq�����ԍ�
/* 2009/10/19 Ver.1.13 Add Start */
          || gt_order_extra_tbl(ln_idx).base_code                                           -- �Ǌ����_(���㋒�_)
/* 2009/10/19 Ver.1.13 Add End */
          || gt_order_extra_tbl(ln_idx).delivery_base_code                                  -- ���͋��_
          || gt_order_extra_tbl(ln_idx).ship_to_subinv                                      -- �o�׌��ۊǏꏊ
          || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep)    -- �o�ח\���
          || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date , cv_date_fmt_no_sep)          -- �󒍖��ׁD�[�i�\���
          || NVL(gt_order_extra_tbl(ln_idx).time_from , cv_blank)                           -- ���Ԏw��From
          || NVL(gt_order_extra_tbl(ln_idx).time_to , cv_blank)                             -- ���Ԏw��To
          || gt_order_extra_tbl(ln_idx).prod_class_code                                     -- ���i�敪View.���i�敪
          || gt_order_extra_tbl(ln_idx).item_code;                                          -- �i�ڃR�[�h
        --
        IF ( lt_head_sum_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
          -- ���݂��Ă���ꍇ�͍��Z
          -- �����
          lt_head_sum_tbl(lv_idx_key).base_quantity :=
              lt_head_sum_tbl(lv_idx_key).base_quantity + gt_order_extra_tbl(ln_idx).base_quantity;
          -- �p���b�g
          lt_head_sum_tbl(lv_idx_key).palette_quantity :=
              lt_head_sum_tbl(lv_idx_key).palette_quantity + gt_order_extra_tbl(ln_idx).conv_palette;
          -- �i��
          lt_head_sum_tbl(lv_idx_key).step_quantity :=
              lt_head_sum_tbl(lv_idx_key).step_quantity + gt_order_extra_tbl(ln_idx).conv_step;
          -- �P�[�X��
          lt_head_sum_tbl(lv_idx_key).case_quantity :=
              lt_head_sum_tbl(lv_idx_key).case_quantity + gt_order_extra_tbl(ln_idx).conv_case;
          --
        ELSE
          -- ���݂��Ă��Ȃ��ꍇ
          lt_head_sum_tbl(lv_idx_key).base_quantity    := gt_order_extra_tbl(ln_idx).base_quantity;
          lt_head_sum_tbl(lv_idx_key).palette_quantity := gt_order_extra_tbl(ln_idx).conv_palette;
          lt_head_sum_tbl(lv_idx_key).step_quantity    := gt_order_extra_tbl(ln_idx).conv_step;
          lt_head_sum_tbl(lv_idx_key).case_quantity    := gt_order_extra_tbl(ln_idx).conv_case;
          --
        END IF;
      END IF;
    END LOOP sum_loop;
    --
    -- ===============================
    -- �i�ڒP�ʂ̃\�[�g
    -- ===============================
    <<sort_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      -- �w�b�_�\�[�g
      lv_head_key := 
        TO_CHAR(gt_order_extra_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep)             -- �󒍓�
        || gt_order_extra_tbl(ln_idx).province                                            -- �z����R�[�h
        || NVL(gt_order_extra_tbl(ln_idx).shipping_instructions , cv_blank)               -- �o�׎w��
        || NVL(gt_order_extra_tbl(ln_idx).cust_po_number , cv_blank)                      -- �ڋq�����ԍ�
/* 2009/10/19 Ver.1.13 Add Start */
        || gt_order_extra_tbl(ln_idx).base_code                                           -- �Ǌ����_(���㋒�_)
/* 2009/10/19 Ver.1.13 Add End */
        || gt_order_extra_tbl(ln_idx).delivery_base_code                                  -- ���͋��_
        || gt_order_extra_tbl(ln_idx).ship_to_subinv                                      -- �o�׌��ۊǏꏊ
        || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep)    -- �o�ח\���
        || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date , cv_date_fmt_no_sep)          -- �󒍖��ׁD�[�i�\���
        || NVL(gt_order_extra_tbl(ln_idx).time_from , cv_blank)                           -- ���Ԏw��From
        || NVL(gt_order_extra_tbl(ln_idx).time_to , cv_blank)                             -- ���Ԏw��To
        || gt_order_extra_tbl(ln_idx).prod_class_code;                                    -- ���i�敪View.���i�敪
      -- ���׃L�[
      lv_line_key := lv_head_key
        || gt_order_extra_tbl(ln_idx).item_code;                                          -- �i�ڃR�[�h
      -- �C���f�b�N�X�쐬
      lv_idx_key :=lv_head_key
         || gt_order_extra_tbl(ln_idx).wc_class                                            -- �d�ʗe�ϋ敪
         || gt_order_extra_tbl(ln_idx).item_code                                           -- �i�ڃR�[�h
         || TO_CHAR(gt_order_extra_tbl(ln_idx).line_id);                                   -- ����ID
       -- �ݒ�
       gt_order_sort_wk_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
       gt_order_sort_wk_tbl(lv_idx_key).head_sort_key := lv_head_key;
       gt_order_sort_wk_tbl(lv_idx_key).line_key := lv_line_key;
       -- ���Z�f�[�^�ݒ�
       gt_order_sort_wk_tbl(lv_idx_key).add_base_quantity   := lt_head_sum_tbl(lv_line_key).base_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_palette  := lt_head_sum_tbl(lv_line_key).palette_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_step     := lt_head_sum_tbl(lv_line_key).step_quantity;
       gt_order_sort_wk_tbl(lv_idx_key).total_conv_case     := lt_head_sum_tbl(lv_line_key).case_quantity;
       --
       gt_normal_order_tbl(lv_idx_key) := gt_order_sort_wk_tbl(lv_idx_key);
    END LOOP sort_loop;
    --
    -- ====================================================================
    -- �����`�F�b�N�A�w�b�_�P�ʂ̍��v�d�ʁE���v�e�ρE���v�p���b�g�d�ʎ擾
    -- ====================================================================
    lv_idx := gt_order_sort_wk_tbl.FIRST;
    lv_line_key := '--';
    <<sum_loop>>
    WHILE lv_idx IS NOT NULL LOOP
      IF ( lv_line_key <> gt_order_sort_wk_tbl(lv_idx).line_key ) THEN
        -- �w�b�_�\�[�g�L�[���u���C�N�����ꍇ
        IF ( gt_order_sort_wk_tbl(lv_idx).prod_class_code = cv_prod_class_drink ) THEN
          -- �h�����N�̏ꍇ
          -- ==============================================
          -- �����̐����{�`�F�b�N
          -- ==============================================
          IF ( MOD(gt_order_sort_wk_tbl(lv_idx).add_base_quantity,gt_order_sort_wk_tbl(lv_idx).qty_case) <> 0 ) THEN
            -- �P�[�X�����̔{���łȂ��ꍇ
            -- ���b�Z�[�W�쐬
            lv_output_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_xxcos_short_name                  -- �A�v���P�[�V�����Z�k��
              ,iv_name         => cv_msg_quantity_err                     -- ���b�Z�[�W
              ,iv_token_name1  => cv_tkn_item_code                      -- �󒍕i��
              ,iv_token_value1 => gt_order_sort_wk_tbl(lv_idx).item_code
              ,iv_token_name2  => cv_tkn_ordered_quantity                -- �󒍐���
              ,iv_token_value2 => gt_order_sort_wk_tbl(lv_idx).add_base_quantity
              ,iv_token_name3  => cv_tkn_case_quantity            -- ����
              ,iv_token_value3 => gt_order_sort_wk_tbl(lv_idx).qty_case
            );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_output_msg
            );
            -- ��s�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => NULL
            );
            --
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
        --
        -- ========================================================
        -- �w�b�_�P�ʂ̍��v�d�ʁE���v�e�ρE���v�p���b�g�d�ʎ擾
        -- ========================================================
        xxwsh_common910_pkg.calc_total_value(
           iv_item_no            =>  gt_order_sort_wk_tbl(lv_idx).item_code              -- �i�ڃR�[�h
          ,in_quantity           =>  gt_order_sort_wk_tbl(lv_idx).add_base_quantity                    -- ����
          ,ov_retcode            => lv_retcode                          -- ���^�[���R�[�h
          ,ov_errmsg_code        => lv_errbuf                           -- �G���[���b�Z�[�W�R�[�h
          ,ov_errmsg             => lv_errmsg                           -- �G���[���b�Z�[�W
          ,on_sum_weight         => ln_sum_weight                       -- ���v�d��
          ,on_sum_capacity       => ln_sum_capacity                     -- ���v�e��
          ,on_sum_pallet_weight  => ln_sum_pallet_weight                -- ���v�p���b�g�d��
          ,id_standard_date      =>  gt_order_sort_wk_tbl(lv_idx).schedule_ship_date     -- ���(�K�p�����)
        );
        --
        -- ���^�[���R�[�h�`�F�b�N
        IF ( lv_retcode = cv_status_error ) THEN
          -- ���v�d�ʁE���v�e�ώ擾�G���[
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name              -- �A�v���P�[�V�����Z�k��
            ,iv_name         => cv_calc_total_value_err          -- ���b�Z�[�W
            ,iv_token_name1  => cv_tkn_order_no                  -- �󒍔ԍ�
            ,iv_token_value1 => gt_order_sort_wk_tbl(lv_idx).order_number
            ,iv_token_name2  => cv_tkn_item_code                 -- �󒍕i��
            ,iv_token_value2 => gt_order_sort_wk_tbl(lv_idx).item_code
            ,iv_token_name3  => cv_tkn_quantity                  -- �󒍐���
            ,iv_token_value3 => gt_order_sort_wk_tbl(lv_idx).ordered_quantity
            ,iv_token_name4  => cv_tkn_schedule_date             -- �o�ח\���
            ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_idx).schedule_ship_date,cv_date_fmt_date_time)
            ,iv_token_name5  => cv_tkn_err_msg                   -- �G���[���b�Z�[�W
            ,iv_token_value5 => lv_errmsg
          );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- ��s�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
          --
          gn_warn_cnt := gn_warn_cnt + 1;
          --
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
      --
      gt_order_sort_wk_tbl(lv_idx).add_sum_weight        := ln_sum_weight;
      gt_order_sort_wk_tbl(lv_idx).add_sum_capacity      := ln_sum_capacity;
      gt_order_sort_wk_tbl(lv_idx).add_sum_pallet_weight := ln_sum_pallet_weight;
      --
      lv_line_key := gt_order_sort_wk_tbl(lv_idx).line_key;
      -- ���̃C���f�b�N�X�擾
      lv_idx := gt_order_sort_wk_tbl.NEXT(lv_idx);
    END LOOP sum_loop;
    --
    gt_normal_order_tbl := gt_order_sort_wk_tbl;
    gt_order_sort_wk_tbl.DELETE;
    --
    -- ==========================================
    -- �w�b�_�\�[�g�L�[�A�i�ڒP�ʂ̍ő�d�ʎ擾
    -- ==========================================
    lv_idx := gt_normal_order_tbl.FIRST;
    <<max_weight_loop>>
    WHILE lv_idx IS NOT NULL LOOP
      IF ( ln_max_valt < TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight) ) THEN
        ln_max_valt := TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight);
      END IF;
      lv_idx := gt_normal_order_tbl.NEXT(lv_idx);
    END LOOP max_weight_loop;
    --
    -- ===============================
    -- �d�ʏ��Ƀ\�[�g
    -- ===============================
    lv_idx := gt_normal_order_tbl.FIRST;
    WHILE lv_idx IS NOT NULL LOOP
    <<weight_sort_loop>>
      -- �C���f�b�N�X�쐬
      lv_idx_key :=gt_normal_order_tbl(lv_idx).head_sort_key
         || gt_normal_order_tbl(lv_idx).wc_class                                            -- �d�ʗe�ϋ敪
         || LPAD(TO_CHAR(ln_max_valt - TRUNC(gt_normal_order_tbl(lv_idx).add_sum_weight)), LENGTH(TO_CHAR(ln_max_valt)) + 1, '0')  -- �d�ʗe��(�~��)
         || gt_normal_order_tbl(lv_idx).item_code                                           -- �i�ڃR�[�h
         || TO_CHAR(gt_normal_order_tbl(lv_idx).line_id);                                   -- ����ID
       gt_order_sort_wk_tbl(lv_idx_key) := gt_normal_order_tbl(lv_idx);
      lv_idx := gt_normal_order_tbl.NEXT(lv_idx);
    END LOOP weight_sort_loop;
    --
--    <<loop_make_sort_data>>
--    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
--      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
--        -- �\�[�g�L�[
--        lv_idx_sort := TO_CHAR(gt_order_extra_tbl(ln_idx).header_id)                                -- �󒍃w�b�_ID
--                      || gt_order_extra_tbl(ln_idx).ship_to_subinv                                  -- �o�׌��ۊǏꏊ
--                      || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date,cv_date_fmt_no_sep)  -- �o�ח\���
--                      || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date,cv_date_fmt_no_sep)        -- �[�i�\���
--                      || gt_order_extra_tbl(ln_idx).time_from                                       -- ���Ԏw��From
--                      || gt_order_extra_tbl(ln_idx).time_to                                         -- ���Ԏw��To
--                      || gt_order_extra_tbl(ln_idx).item_div_name;                                  -- ���i�敪
--        -- �C���f�b�N�X
--        lv_idx_key := lv_idx_sort
--                      || gt_order_extra_tbl(ln_idx).item_code                                       -- �i�ڃR�[�h
--                      || cv_first_num;
--        --
--        -- �C���f�b�N�X(���꒍���i)�̃f�[�^�����݂��Ă��邩�`�F�b�N
--        IF ( gt_order_sort_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
--          -- ���݂���ꍇ
--          ln_val := 1;
--          <<loop_make_next_val>>
--          LOOP
--            lv_idx_key := lv_idx_sort
--                      || gt_order_extra_tbl(ln_idx).item_code                                       -- �i�ڃR�[�h
--                      || TO_CHAR(ln_val);
--            -- ���݂��Ȃ��ꍇ�A���[�v�𔲂���
--            EXIT WHEN gt_order_sort_tbl.EXISTS(lv_idx_key) = FALSE;
--            -- �J�E���g�A�b�v
--            ln_val := ln_val + 1;
--          END LOOP loop_make_next_val;
--        END IF;
--        -- �\�[�g�L�[�ݒ�
--        gt_order_extra_tbl(ln_idx).sort_key := lv_idx_sort;
--        gt_order_sort_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
--      END IF;
--    END LOOP loop_make_sort_data;
--    --
--    -- ===============================
--    -- �o�׈˗��p�w�b�_�[ID�̔�
--    -- ===============================
--    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
--      lv_idx_key := gt_order_sort_tbl.FIRST;
--      --
--      -- �w�b�_�[ID�p�V�[�P���X�̔�
--      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
--      INTO   ln_header_id
--      FROM   dual;
--      --
--      <<loop_make_header_id>>
--      WHILE lv_idx_key IS NOT NULL LOOP
--        -- �o�׈˗��p�w�b�_�[ID���̔Ԃ��邩�`�F�b�N
--        IF ( ( lv_sort_key <> gt_order_sort_tbl(lv_idx_key).sort_key )
--             OR ( ( lv_sort_key = gt_order_sort_tbl(lv_idx_key).sort_key )
--                AND ( lv_item_code = gt_order_sort_tbl(lv_idx_key).item_code ) ) )
--        THEN
--          -- �\�[�g�L�[���u���C�N�A�܂��́A�\�[�g�L�[�ƕi�ڂ�����̏ꍇ
--          -- �w�b�_�[ID�p�V�[�P���X�̔�
--          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
--          INTO   ln_header_id
--          FROM   dual;
--          --
--        END IF;
--        --
--        -- �w�b�_�[ID��ݒ�
--        gt_order_sort_tbl(lv_idx_key).req_header_id := ln_header_id;
--        --
--        -- �\�[�g�L�[�ƕi�ڃR�[�h���擾
--        lv_sort_key :=  gt_order_sort_tbl(lv_idx_key).sort_key;
--        lv_item_code := gt_order_sort_tbl(lv_idx_key).item_code;
--        --
--        -- ���̃C���f�b�N�X���擾
--        lv_idx_key := gt_order_sort_tbl.NEXT(lv_idx_key);
--        --
--      END LOOP loop_make_header_id;
--    END IF;
/* 2009/09/16 Ver.1.12 Mod End */
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
/* 2009/09/16 Ver.1.12 Del Start */
--      --==================================
--      -- ����ʎZ�o
--      --==================================
--      xxcos_common_pkg.get_uom_cnv(
--         iv_before_uom_code    => gt_order_sort_tbl(lv_index).order_quantity_uom       -- ���Z�O�P�ʃR�[�h = �󒍒P��
--        ,in_before_quantity    => gt_order_sort_tbl(lv_index).ordered_quantity         -- ���Z�O����       = �󒍐���
--        ,iov_item_code         => gt_order_sort_tbl(lv_index).item_code                -- �i�ڃR�[�h
--        ,iov_organization_code => lv_organization_code                                 -- �݌ɑg�D�R�[�h   =NULL
--        ,ion_inventory_item_id => lt_item_id                                           -- �i�ڂh�c         =NULL
--        ,ion_organization_id   => ln_organization_id                                   -- �݌ɑg�D�h�c     =NULL
--        ,iov_after_uom_code    => gt_order_sort_tbl(lv_index).conv_order_quantity_uom  --���Z��P�ʃR�[�h =>��P��
--        ,on_after_quantity     => gt_order_sort_tbl(lv_index).conv_ordered_quantity    --���Z�㐔��       =>�����
--        ,on_content            => ln_content                                           --����
--        ,ov_errbuf             => lv_errbuf                         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
--        ,ov_retcode            => lv_retcode                        --���^�[���E�R�[�h               #�Œ�#
--        ,ov_errmsg             => lv_errmsg                         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
--      );
--      -- API���s���ʃ`�F�b�N
--      IF ( lv_retcode != cv_status_normal ) THEN
--        RAISE global_api_expt;
--      END IF;
/* 2009/09/16 Ver.1.12 Del End */
      --
      gt_ins_l_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;                -- �w�b�_�[ID
      gt_ins_l_line_number(ln_count) := gt_order_sort_tbl(lv_index).line_number;                -- ���הԍ�
      gt_ins_l_orderd_item_code(ln_count) := gt_order_sort_tbl(lv_index).child_code;            -- �󒍕i��
/* 2009/09/16 Ver.1.12 Del End */
      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).checked_quantity;      -- ����
--      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).conv_ordered_quantity;  -- ����
/* 2009/09/16 Ver.1.12 Del End */
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
--****************************** 2009/04/16 1.5 T.kitajima MOD START ******************************--
----****************************** 2009/04/06 1.4 T.kitajima MOD START ******************************--
----    cv_order_source             CONSTANT VARCHAR2(1) := '9';     -- �󒍃\�[�X�Q�Ƃ̐擪����
--    cv_order_source             CONSTANT VARCHAR2(2) := '97';    -- �󒍃\�[�X�Q�Ƃ̐擪����
----****************************** 2009/04/06 1.4 T.kitajima MOD  END  ******************************--
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_order_source             CONSTANT VARCHAR2(2) := '98';    -- �󒍃\�[�X�Q�Ƃ̐擪����
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/16 1.5 T.kitajima MOD  END  ******************************--
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/06 1.4 T.kitajima MOD START ******************************--
--    cn_pad_num_char             CONSTANT NUMBER := 11;           -- PAD�֐��Ŗ��ߍ��ޕ�����
/* 2009/09/16 Ver.1.12 Del Start */
--    cn_pad_num_char             CONSTANT NUMBER := 10;           -- PAD�֐��Ŗ��ߍ��ޕ�����
/* 2009/09/16 Ver.1.12 Del End */
--****************************** 2009/04/06 1.4 T.kitajima MOD  END  ******************************--
--
    -- *** ���[�J���ϐ� ***
    lv_index                    VARCHAR2(1000);                        -- PL/SQL�\�p�C���f�b�N�X������
    lt_cust_po_number           VARCHAR2(100);                         -- �ڋq����
    lv_order_source             VARCHAR2(12);                          -- �󒍃\�[�X
    ln_req_header_id            NUMBER;                                -- �w�b�_�[ID
    ln_count                    NUMBER;                                -- �J�E���^
    ln_order_source_ref         NUMBER;                                -- �V�[�P���X�ݒ�p
/* 2009/09/16 Ver.1.12 Del Start */
--    lt_shipping_class           fnd_lookup_values.attribute2%TYPE;     -- �o�׈˗��敪
/* 2009/09/16 Ver.1.12 Del End */
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
/* 2009/09/16 Ver.1.12 Mod Start */
      INTO   gt_shipping_class
--      INTO   lt_shipping_class
/* 2009/09/16 Ver.1.12 Mod End */
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_shipping_class_t
      AND    flv.lookup_code   = cv_shipping_class_c
/* 2009/09/16 Ver.1.12 Mod Start */
      AND    flv.language      = cv_lang
--      AND    flv.language      = USERENV('LANG')
/* 2009/09/16 Ver.1.12 Mod End */
      AND    flv.enabled_flag  = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE non_lookup_value_expt;
    END;
    --
/* 2009/09/16 Ver.1.12 Mod Start */
    IF ( gt_shipping_class IS NULL ) THEN
--    IF ( lt_shipping_class IS NULL ) THEN
/* 2009/09/16 Ver.1.12 Mod End */
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
/* 2009/09/16 Ver.1.12 Mod Start */
          lv_order_source := gt_order_sort_tbl(lv_index).order_source;
--        -- �V�[�P���X�̔�
--        SELECT xxcos_order_source_ref_s01.NEXTVAL
--        INTO   ln_order_source_ref
--        FROM   dual;
--        --
--        lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
--                                                   ,cn_pad_num_char
--                                                   ,cv_pad_char);
/* 2009/09/16 Ver.1.12 Mod End */
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
/* 2009/09/19 Ver.1.13 Mod Start */
        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).base_code;
--        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
/* 2009/09/19 Ver.1.13 Mod End */
        -- ���͋��_
/* 2009/11/04 Ver.1.14 Mod Start */
        gt_ins_h_input_sales_branch(ln_count) := gt_input_base_code;
--        gt_ins_h_input_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
/* 2009/11/04 Ver.1.14 Mod End */
        -- ���׎���From
        gt_ins_h_arrival_time_from(ln_count) := gt_order_sort_tbl(lv_index).time_from;
        -- ���׎���To
        gt_ins_h_arrival_time_to(ln_count) := gt_order_sort_tbl(lv_index).time_to;
        -- �f�[�^�^�C�v
        gt_ins_h_data_type(ln_count) := cv_data_type;
        -- �󒍔ԍ�
        gt_ins_h_order_number(ln_count) := gt_order_sort_tbl(lv_index).order_number;
        -- �˗��敪
/* 2009/09/16 Ver.1.12 Mod Start */
        gt_ins_h_order_number(ln_count) := gt_shipping_class;
--        gt_ins_h_order_number(ln_count) := lt_shipping_class;
/* 2009/09/16 Ver.1.12 Mod End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    ln_header_id       NUMBER;               -- �w�b�_ID�p
    lv_item_code       VARCHAR2(30);         -- �i��ID
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- �ڋq�����̐擪����
    cv_order_source             CONSTANT VARCHAR2(2) := '98';    -- �󒍃\�[�X�Q�Ƃ̐擪����
    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
    cn_pad_num_char             CONSTANT NUMBER := 10;           -- PAD�֐��Ŗ��ߍ��ޕ�����
    cv_data_type                CONSTANT VARCHAR2(2) := '10';    -- �f�[�^�^�C�v
    ln_header_id           NUMBER;     -- �w�b�_ID
    ln_order_source_ref    NUMBER;
    lv_order_source        VARCHAR2(50);   -- �󒍃\�[�X�Q��
    lt_cust_po_number      VARCHAR2(50);   -- �ڋq�����ԍ�
/* 2009/09/16 Ver.1.12 Add End */
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
    l_msg_count                NUMBER;
    l_index                    NUMBER := 1; 
/* 2009/09/16 Ver.1.12 Add Start */
    lv_dummy                  VARCHAR2(100);
    ln_update_err_flag        NUMBER DEFAULT 0;
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Del Start */
--    <<make_line_data>>
--    FOR ln_idx IN 0..gt_ins_l_header_id.LAST LOOP
--      gt_upd_order_line_tbl(ln_idx).header_id := gt_upd_header_id(ln_idx);                   -- �w�b�_ID(��)
--      gt_upd_order_line_tbl(ln_idx).line_id := gt_ins_l_line_id(ln_idx);                     -- ����ID
--      gt_upd_order_line_tbl(ln_idx).line_number := gt_ins_l_line_number(ln_idx);             -- ���הԍ�
--      gt_upd_order_line_tbl(ln_idx).ship_from_org_id := gt_ins_l_ship_from_org_id(ln_idx);   -- �g�D
--      gt_upd_order_line_tbl(ln_idx).req_header_id := gt_ins_l_header_id(ln_idx);              -- �w�b�_ID(�˗�)
--    END LOOP make_line_data;
--    --
--    ------------------------------
--    -- ����w���ݒ�
--    ------------------------------
--    <<loop_line_data>>
--    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
--      <<set_packing_inst>>
--      FOR ln_cnt IN 0..gt_ins_h_header_id.LAST LOOP
--        ln_header_key := ln_cnt;
--        EXIT WHEN gt_upd_order_line_tbl(ln_idx).req_header_id = gt_ins_h_header_id(ln_cnt);
--      END LOOP set_packing_inst;
--      --
--      -- ����w���ɏo�׈˗��ԍ���ݒ�
--      gt_upd_order_line_tbl(ln_idx).order_source_ref := gt_ins_h_order_source_ref(ln_header_key);
--      gt_upd_order_line_tbl(ln_idx).order_number := gt_ins_h_order_number(ln_header_key);
--    END LOOP loop_line_data;
/* 2009/09/16 Ver.1.12 Del End */
    --
/* 2009/12/07 Ver1.19 Del Start */
--    -- OM���b�Z�[�W���X�g�̏�����
--    OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Del End */
    --
    -- ===============================
    -- ���׍X�V
    -- ===============================
    <<update_line_data>>
/* 2009/09/16 Ver.1.12 Mod Start */
    FOR ln_idx IN 1..gt_order_upd_tbl.COUNT LOOP
/* 2009/12/07 Ver1.19 Add Start */
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Add End */
      lt_line_tbl(cn_index)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation              := OE_GLOBALS.G_OPR_UPDATE;                         -- �������[�h
      lt_line_tbl(cn_index).line_id                := gt_order_upd_tbl(ln_idx).line_id;                -- ����ID
      lt_line_tbl(cn_index).ship_from_org_id       := gt_order_upd_tbl(ln_idx).ship_from_org_id;       -- �g�DID
      lt_line_tbl(cn_index).packing_instructions   := gt_order_upd_tbl(ln_idx).order_source;           -- ����w��
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
      lt_line_tbl(cn_index).program_id             := cn_program_id;
      lt_line_tbl(cn_index).program_update_date    := cd_program_update_date;
      lt_line_tbl(cn_index).request_id             := cn_request_id;
      --
      IF gt_order_ins_tbl.COUNT > 0 THEN
        <<ins_loop>>
        FOR ln_ins_idx IN 1..gt_order_ins_tbl.COUNT LOOP
          IF ( gt_order_ins_tbl(ln_ins_idx).line_id = gt_order_upd_tbl(ln_idx).line_id ) THEN
            IF ( gt_order_upd_tbl(ln_idx).order_quantity_uom = gt_order_upd_tbl(ln_idx).conv_order_quantity_uom ) THEN
              -- �󒍉�ʂ̓��͒P�ʂ���P�ʂ̏ꍇ
              lt_line_tbl(cn_index).ordered_quantity := gt_order_upd_tbl(ln_idx).checked_quantity;
            ELSE
              -- �󒍉�ʂ̓��͒P�ʂ�CS�̏ꍇ
              lt_line_tbl(cn_index).ordered_quantity := gt_order_upd_tbl(ln_idx).checked_quantity / gt_order_upd_tbl(ln_idx).qty_case;
            END IF;
            lt_line_tbl(cn_index).change_reason  := '00';
          END IF;
        END LOOP ins_loop;
      END IF;
--    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
--      lt_line_tbl(cn_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
--      lt_line_tbl(cn_index).operation := OE_GLOBALS.G_OPR_UPDATE;                                     -- �������[�h
--      lt_line_tbl(cn_index).line_id := gt_upd_order_line_tbl(ln_idx).line_id;                         -- ����ID
--      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- �g�DID
--      lt_line_tbl(cn_index).packing_instructions := gt_upd_order_line_tbl(ln_idx).order_source_ref;   -- ����w��
--      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- �g�DID
--      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
--      lt_line_tbl(cn_index).program_id := cn_program_id;
--      lt_line_tbl(cn_index).program_update_date := cd_program_update_date;
--      lt_line_tbl(cn_index).request_id := cn_request_id;
/* 2009/09/16 Ver.1.12 Mod End */
      --
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
/* 2009/09/16 Ver.1.12 Add Start */
      BEGIN
        SELECT  '1'
        INTO    lv_dummy
        FROM    oe_order_lines_all   oola
        WHERE   oola.line_id              = gt_order_upd_tbl(ln_idx).line_id
        AND     oola.packing_instructions = gt_order_upd_tbl(ln_idx).order_source;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_update_err_flag := 1;
      END;
/* 2009/09/16 Ver.1.12 Add End */
      -- API���s���ʊm�F
/* 2009/09/16 Ver.1.12 Mod Start */
      IF (( lv_return_status <> FND_API.G_RET_STS_SUCCESS )
          OR ( ln_update_err_flag = 1 )) THEN
        --
        IF ln_msg_count > 0 THEN
          FOR l_index IN 1..ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(p_msg_index => l_index, p_encoded =>'F');
          END LOOP;
          lv_errbuf := substrb( lv_msg_data,1,250);
        END IF;
--      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
/* 2009/09/16 Ver.1.12 Mod End */
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
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
  /**********************************************************************************
   * Procedure Name   : start_production_system
   * Description      : ���Y�V�X�e���N��
   ***********************************************************************************/
  PROCEDURE start_production_system(
    iv_base_code  IN         VARCHAR2,     --   ���_�R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_production_system'; -- �v���O������
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
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_resp_prod          CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- �v���t�@�C���F���Y�ւ̐ؑ֗p�E��
/* 2009/09/16 Ver.1.12 Del End */
    cv_xxwsh_short_name   CONSTANT VARCHAR2(10) := 'XXWSH';                             -- ���Y�V�X�e���Z�k��
    cv_xxcos_short_name   CONSTANT VARCHAR2(10) := 'XXCOS';                             -- �̔��`�[���Z�k��
    cv_cus_order_pkg      CONSTANT VARCHAR2(50) := 'XXWSH400002C';                      -- �ڋq��������̏o�׈˗������쐬
/* 2009/09/16 Ver.1.12 Del Start */
--    cv_msg_get_login      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11638';                  -- ���O�C�����擾�G���[
--    cv_msg_get_resp       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11639';                  -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
--    cv_msg_get_login_prod CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11640';                  -- �ؑ֐惍�O�C�����擾�G���[
/* 2009/09/16 Ver.1.12 Del End */
    cv_msg_start_err_cus  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11641';                  -- �R���J�����g�N��(�ڋq����)�G���[
/* 2009/11/04 Ver.1.14 Del Start */
--    cv_msg_get_input_base CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11642';                  -- ���͋��_�擾�G���[
/* 2009/11/04 Ver.1.14 Del End */
    cv_msg_standby_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11643';                  -- �R���J�����g�I���ҋ@�G���[
    cv_msg_request_id     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11644';                  -- �R���J�����g�v��ID
    cv_con_status_normal  CONSTANT VARCHAR2(10) := 'NORMAL';                            -- �X�e�[�^�X�i����j
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    cv_con_status_warning CONSTANT VARCHAR2(10) := 'WARNING';                           -- �X�e�[�^�X�i�x���j
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
    cv_user_id            CONSTANT VARCHAR2(10) := 'USER_ID';                           -- ���[�UID
    cv_tkn_code           CONSTANT VARCHAR2(10) := 'CODE';                              -- ���b�Z�[�W�p�g�[�N��
    cb_sub_request        CONSTANT BOOLEAN      := FALSE;                               -- Sub_request
    cn_interval           CONSTANT NUMBER       := 15;                                  -- Interval
    cn_max_wait           CONSTANT NUMBER       := 0;                                   -- Max_wait
--
    -- *** ���[�J���ϐ� ***
    ln_login_user_id      NUMBER;                -- ���O�C�����[�UID
    ln_login_resp_id      NUMBER;                -- ���O�C���E��ID
    ln_login_resp_appl_id NUMBER;                -- ���O�C���E�ӃA�v���P�[�V����ID
    lv_resp_prod          VARCHAR2(100);         -- ���Y�ւ̐ؑ֗p�E�Ӗ�
    ln_prod_user_id       NUMBER;                -- �ؑ֗p���[�UID
    ln_prod_resp_id       NUMBER;                -- �ؑ֗p�E��ID
    ln_prod_resp_appl_id  NUMBER;                -- �ؑ֗p�E�ӃA�v���P�[�V����ID
    ln_request_id         NUMBER DEFAULT 0;      -- �v��ID
    lb_wait_result        BOOLEAN;               -- �R���J�����g�ҋ@����
    lv_phase              VARCHAR2(50);
    lv_status             VARCHAR2(50);
    lv_dev_phase          VARCHAR2(50);
    lv_dev_status         VARCHAR2(50);
    lv_message            VARCHAR2(5000);
    lv_request_id_message VARCHAR2(5000);
/* 2009/11/04 Ver.1.14 Del End */
--    lt_input_base_code    xxcmn_cust_accounts_v.party_number%TYPE;                      -- ���͋��_
/* 2009/11/04 Ver.1.14 Del End */
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
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
    -- ��������
    -- ===============================
    -- *** ���O�C�����̎擾 ***
    BEGIN
--
      SELECT
         fnd_global.user_id      AS USER_ID        -- ���O�C�����[�UID
        ,fnd_global.resp_id      AS RESP_ID        -- ���O�C���E��ID
        ,fnd_global.resp_appl_id AS RESP_APPL_ID   -- ���O�C���E�ӃA�v���P�[�V����ID
      INTO
         ln_login_user_id
        ,ln_login_resp_id
        ,ln_login_resp_appl_id
      FROM
         DUAL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login        -- ���O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
--
    -- *** �v���t�@�C���F���Y�ւ̐ؑ֗p�E�Ӗ��̂̎擾 ***
    lv_resp_prod := FND_PROFILE.VALUE( cv_resp_prod );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_resp_prod IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
                   );
      RAISE global_api_expt;
    END IF;
--
    -- *** �ؑ֐惍�O�C�����̎擾 ***
    BEGIN
--
      SELECT
          responsibility_id AS RESPONSIBILITY_ID   -- �ؑ֗p�E��ID
         ,application_id    AS APPLICATION_ID      -- �ؑ֗p�E�ӃA�v���P�[�V����ID
      INTO
          ln_prod_resp_id
         ,ln_prod_resp_appl_id
      FROM
          fnd_responsibility_vl
      WHERE
          responsibility_name = lv_resp_prod       -- �ؑ֗p�E�Ӗ���
      AND ROWNUM              = 1
      ;
--
      -- �ؑ֗p���[�UID�̎擾
      ln_prod_user_id := ln_login_user_id;         -- ���O�C�����[�UID
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- �ؑ֐惍�O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
--
/* 2009/11/04 Ver.1.14 Del Start */
--    -- *** ���͋��_�̎擾 ***
--    IF ( iv_base_code IS NOT NULL ) THEN
--      -- ���̓p�����[�^.���_�R�[�h����͋��_�ɐݒ�
--      lt_input_base_code := iv_base_code;
--      --
--    ELSE
--      -- ���O�C�����[�U�̏������_�R�[�h����͋��_�ɐݒ�
--      BEGIN
--      --
----****************************** 2009/05/26 1.7 T.Kitajima ADD START ******************************--
----        SELECT
----            xcav.party_number AS input_base_code
----        INTO
----            lt_input_base_code
----        FROM
----            fnd_user              fu
----           ,per_all_people_f      papf
----           ,per_all_assignments_f paaf
----           ,xxcmn_locations_v     xlv
----           ,xxcmn_cust_accounts_v xcav 
----        WHERE 
----            fu.user_id        = fnd_profile.value( cv_user_id ) 
----        AND fu.employee_id    = papf.person_id
----        AND nvl( papf.effective_start_date, TRUNC( gd_business_date ) ) <= TRUNC( gd_business_date )
----        AND nvl( papf.effective_end_date,   TRUNC( gd_business_date ) ) >= TRUNC( gd_business_date )
----        AND papf.person_id    = paaf.person_id
----        AND nvl( paaf.effective_start_date, TRUNC( gd_business_date ) ) <= TRUNC( gd_business_date )
----        AND nvl( paaf.effective_end_date,   TRUNC( gd_business_date ) ) >= TRUNC( gd_business_date )
----        AND paaf.location_id  = xlv.location_id
----        AND xlv.location_code = xcav.party_number
--        SELECT xlobi.base_code             input_base_code
--          INTO lt_input_base_code
--          FROM xxcos_login_own_base_info_v xlobi
--        ;
----****************************** 2009/05/26 1.7 T.Kitajima ADD  END  ******************************--
--      --
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_short_name,    -- XXCOS
--                         iv_name        => cv_msg_get_input_base   -- ���͋��_�擾�G���[
--                       );
--          RAISE global_api_expt;
--      END;
----
--    END IF;
/* 2009/11/04 Ver.1.14 Del End */
--
    -- ===============================
    -- ���O�C���ؑ�(���YOU��)
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
      ln_prod_user_id,          -- ���[�UID
      ln_prod_resp_id,          -- �E��ID
      ln_prod_resp_appl_id      -- �A�v���P�[�V����ID
    );
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    -- ===============================
    -- �R���J�����g�N��
    -- ===============================
    ln_request_id := fnd_request.submit_request(
                       application => cv_xxwsh_short_name,       -- XXWSH
                       program     => cv_cus_order_pkg,          -- XXWSH400002C
                       description => NULL,
                       start_time  => NULL,
                       sub_request => cb_sub_request,            -- FALSE
/* 2009/11/04 Ver.1.14 Mod Start */
                       argument1   => gt_input_base_code,            -- �����F���͋��_
--                       argument1   => lt_input_base_code,        -- �����F���͋��_
/* 2009/11/04 Ver.1.14 Mod Start */
                       argument2   => NULL                       -- �����F�Ǌ����_
                     );
--
    -- �v��ID�o��
    lv_request_id_message := xxccp_common_pkg.get_msg(
                               iv_application  => cv_xxcos_short_name,      -- XXCOS
                               iv_name         => cv_msg_request_id,        -- �R���J�����g�v��ID
                               iv_token_name1  => cv_tkn_code,              -- CODE
                               iv_token_value1 => TO_CHAR( ln_request_id )  -- �v��ID
                             );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_request_id_message
    ); 
--
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,      -- XXCOS
                     iv_name        => cv_msg_start_err_cus      -- �R���J�����g�N��(�ڋq����)�G���[
                   );
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id => ln_request_id,
/* 2009/07/28 Ver.1.11 Mod Start */
--                        interval   => cn_interval,
--                        max_wait   => cn_max_wait,
                        interval   => gt_interval,
                        max_wait   => gt_max_wait,
/* 2009/07/28 Ver.1.11 Mod End   */
                        phase      => lv_phase,
                        status     => lv_status,
                        dev_phase  => lv_dev_phase,
                        dev_status => lv_dev_status,
                        message    => lv_message
                      );
--
    -- ===============================
    -- ���O�C���ؑ�(�c��OU��)
    -- ===============================
    FND_GLOBAL.APPS_INITIALIZE(
      ln_login_user_id,         -- ���[�UID
      ln_login_resp_id,         -- �E��ID
      ln_login_resp_appl_id     -- �A�v���P�[�V����ID
    );
--
    --�R���J�����g�̏I���X�e�[�^�X
    IF ( ( lb_wait_result = FALSE )
      OR ( lv_dev_status NOT IN ( cv_con_status_normal, cv_con_status_warning ) ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,    -- XXCOS
                     iv_name        => cv_msg_standby_err      -- �R���J�����g�N��(�ڋq����)�G���[
                   );
      RAISE global_api_expt;
    END IF;
    --�x���I����
    IF ( lv_dev_status = cv_con_status_warning ) THEN
      ov_retcode := cv_status_warn;
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
  END start_production_system;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
/* 2009/09/16 Ver.1.12 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : weight_check
   * Description      : �ύڌ����œK���`�F�b�N(A-14)
   ***********************************************************************************/
  PROCEDURE weight_check(
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'weight_check'; -- �v���O������
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
    cn_status_normal          CONSTANT NUMBER       := 0;                     -- ���YAPI�X�e�C�^�X:����
    cn_status_error           CONSTANT NUMBER       := 1;                     -- ���YAPI�X�e�C�^�X:�ُ�
    cv_warehouse_code         CONSTANT VARCHAR2(1)  := '4';                   -- �R�[�h�敪:�q��
    cv_delivery_code          CONSTANT VARCHAR2(1)  := '9';                   -- �R�[�h�敪�F�z����
    cv_small_amount_class     CONSTANT VARCHAR2(1)  := '1';                   -- �����敪
    cv_tkn_whse_locat         CONSTANT VARCHAR2(30) := 'WHSE_LOCAT';          -- �o�׌��ۊǏꏊ
    cv_tkn_delivery_code      CONSTANT VARCHAR2(30) := 'DELIVERY_CODE';       -- �z����
    cv_tkn_item_div_name      CONSTANT VARCHAR2(30) := 'ITEM_DIV_NAME';       -- ���i�敪
    cv_tkn_sum_weight         CONSTANT VARCHAR2(30) := 'SUM_WEIGHT';          -- ���v�d��
    cv_tkn_sum_capacity       CONSTANT VARCHAR2(30) := 'SUM_CAPACITY';        -- ���v�e��
    cv_tkn_err_msg            CONSTANT VARCHAR2(30) := 'ERR_MSG';             -- �G���[���b�Z�[�W
    cn_efficiency_over        CONSTANT NUMBER       := 1;                     -- �I�[�o�[
    cn_efficiency_non_over    CONSTANT NUMBER       := 0;                     -- ����
--
    lv_line_key                 VARCHAR2(1000);     -- ���׃L�[
    lv_pre_line_key             VARCHAR2(1000);     -- �O���׃L�[
    lv_pre_head_sort_key        VARCHAR2(1000);     -- �w�b�_�\�[�g�L�[
    lv_index                    VARCHAR2(1000);     -- �C���f�b�N�X
    lv_small_amount_class       VARCHAR2(10);       -- �����敪
    lv_max_ship_methods         VARCHAR2(10);       -- �ő�z���敪
    lv_loading_over_class       VARCHAR2(100);      -- �ύڃI�[�o�[�敪
    lv_ship_methods             VARCHAR2(100);      -- �o�ו��@
    lv_mixed_ship_method        VARCHAR2(100);      -- ���ڔz���敪
    lv_output_msg               VARCHAR2(1000);     -- �o�̓��b�Z�[�W
    lv_index_wk                 VARCHAR2(1000);     -- �C���f�b�N�X
    ln_ret_val                  NUMBER;             -- ���^�[���l
    ln_sum_capacity             NUMBER;             -- ���Z���v�e��
    ln_sum_weight               NUMBER;             -- ���Z���v�d��
    ln_load_efficiency_weight   NUMBER;             -- �d�ʐύڌ���
    ln_load_efficiency_capacity NUMBER;             -- �e�ϐύڌ���
    ln_load_efficiency          NUMBER;             -- �ύڌ���
    ln_check_qty                NUMBER DEFAULT 0;   -- �`�F�b�N�ϐ���
    ln_drink_deadweight         NUMBER;             -- �h�����N�ύڏd��
    ln_leaf_deadweight          NUMBER;             -- ���[�t�ύڏd��
    ln_drink_loading_capacity   NUMBER;             -- �h�����N�ύڗe��
    ln_leaf_loading_capacity    NUMBER;             -- ���[�t�ύڗe��
    ln_palette_max_qty          NUMBER;             -- �p���b�g�ő喇��
    ln_save_check_qty           NUMBER;             -- �O��`�F�b�N���ʑޔ�p
    ln_save_weight              NUMBER DEFAULT 0;   -- �O��`�F�b�N�d�ʑޔ�p
    ln_palette_max_step_qty     NUMBER;             -- �i��/�p���b�g(���[�v��)
    ln_sum_pallet_weight        NUMBER;
    ln_diff_base_qty            NUMBER;
    ln_case_qty                 NUMBER;             -- �P�[�X��/�i
    ln_non_stack                NUMBER;
    ln_now_check_qty            NUMBER;
    ln_delivery_unit            NUMBER DEFAULT 0;
    ln_wk                       NUMBER;
    ld_standard_date            DATE;
    lt_checked_rec              order_data_cur%ROWTYPE;
    ld_error_flag               BOOLEAN DEFAULT TRUE;
    ln_step_stack_flag          NUMBER;
    ln_total_palette            NUMBER;
    ln_total_step               NUMBER;
    ln_total_case               NUMBER;
    ln_efficiency_over_flag     NUMBER;   -- �ύڌ����I�[�o�[�t���O(0�F�����A1�F�I�[�o�[)
    ln_check_palette            NUMBER;
    ln_check_step               NUMBER;
    ln_check_case               NUMBER;
    ln_consolidation_flag       NUMBER DEFAULT 0;
    ln_palette_over_flag        NUMBER;
    ln_order_qty                NUMBER;
    ln_set                      NUMBER;
    ln_loop_flag                NUMBER;
    --
    small_amount_class_expt    EXCEPTION;     -- �����敪�擾�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    lv_index             := gt_order_sort_wk_tbl.FIRST;
    lv_line_key          := gt_order_sort_wk_tbl(lv_index).line_key;
    lv_pre_line_key      := 'NULL';
    lv_pre_head_sort_key := 'NULL';
--
    <<check_loop>>
    WHILE lv_index IS NOT NULL LOOP
      IF ( lv_pre_line_key <> gt_order_sort_wk_tbl(lv_index).line_key ) THEN
        lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        ln_total_palette := gt_order_sort_wk_tbl(lv_index).total_conv_palette;
        ln_total_step    := gt_order_sort_wk_tbl(lv_index).total_conv_step;
        ln_total_case    := gt_order_sort_wk_tbl(lv_index).total_conv_case;
        -- �w�b�_�\�[�g�L�[���u���C�N�����ꍇ
        IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
            ln_save_weight := 0;
            ln_consolidation_flag := 0;
        END IF;
        --
        -- �ύڗ��̃`�F�b�N
        -- ==============================================
        -- �o�׌��ۊǏꏊ�E�z����Ԃ̍ő�z���敪���Z�o
        -- ==============================================
        ln_ret_val := xxwsh_common_pkg.get_max_ship_method(
               iv_code_class1                  =>  cv_warehouse_code                   -- 1.�R�[�h�敪�P
              ,iv_entering_despatching_code1   =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv           -- 2.���o�ɏꏊ�R�[�h�P
              ,iv_code_class2                  =>  cv_delivery_code                    -- 3.�R�[�h�敪�Q
              ,iv_entering_despatching_code2   =>  gt_order_sort_wk_tbl(lv_index).province                 -- 4.���o�ɏꏊ�R�[�h�Q
              ,iv_prod_class                   =>  gt_order_sort_wk_tbl(lv_index).prod_class_code       -- 5.���i�敪
              ,iv_weight_capacity_class        =>  gt_order_sort_wk_tbl(lv_index).wc_class                 -- 6.�d�ʗe�ϋ敪
              ,iv_auto_process_type            =>  NULL                                -- 7.�����z�ԑΏۋ敪
              ,id_standard_date                =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date       -- 8.���(�K�p�����)
              ,ov_max_ship_methods             =>  lv_max_ship_methods                 -- 9.�ő�z���敪
              ,on_drink_deadweight             =>  ln_drink_deadweight                 -- 10.�h�����N�ύڏd��
              ,on_leaf_deadweight              =>  ln_leaf_deadweight                  -- 11.���[�t�ύڏd��
              ,on_drink_loading_capacity       =>  ln_drink_loading_capacity           -- 12.�h�����N�ύڗe��
              ,on_leaf_loading_capacity        =>  ln_leaf_loading_capacity            -- 13.���[�t�ύڗe��
              ,on_palette_max_qty              =>  ln_palette_max_qty                  -- 14.�p���b�g�ő喇��
                            );
        -- ���^�[���R�[�h�`�F�b�N
        IF ( ln_ret_val <> cn_status_error ) THEN
          -- �ő�z���敪�擾���擾�ł����ꍇ
          -- ==============================================
          -- �h�����N�̏ꍇ�A�ő�z���敪�̏����敪�擾
          -- ==============================================
          IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
            BEGIN
              SELECT  xsmv.small_amount_class    -- �����敪
              INTO    lv_small_amount_class
              FROM    xxwsh_ship_method_v    xsmv
              WHERE   xsmv.ship_method_code = lv_max_ship_methods;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE small_amount_class_expt;
            END;
            --
            -- �����敪�̔���
            IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
              -- ���v�d�ʂɍ��v�p���b�g�d�ʂ����Z
              ln_sum_weight := gt_order_sort_wk_tbl(lv_index).add_sum_weight + gt_order_sort_wk_tbl(lv_index).add_sum_pallet_weight;
            ELSE
              ln_sum_weight := gt_order_sort_wk_tbl(lv_index).add_sum_weight;
            END IF;
          END IF;
          --
          -- ==============================================
          -- �ύڌ����Z�o
          -- ==============================================
          IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
            -- �h�����N�̏ꍇ
            ln_sum_weight := ln_sum_weight;
            ln_sum_capacity := NULL;
          ELSE
            -- ���[�t�̏ꍇ
            ln_sum_weight  := NULL;
            ln_sum_capacity := gt_order_sort_wk_tbl(lv_index).add_sum_capacity;
          END IF;
          --
          IF ( ln_consolidation_flag = 1 ) THEN
            ln_sum_weight := ln_sum_weight + ln_save_weight;
          END IF;
          --
          xxwsh_common910_pkg.calc_load_efficiency(
             in_sum_weight                   =>  ln_sum_weight                     -- 1.���v�d��
            ,in_sum_capacity                 =>  ln_sum_capacity                   -- 2.���v�e��
            ,iv_code_class1                  =>  cv_warehouse_code                 -- 3.�R�[�h�敪�P
            ,iv_entering_despatching_code1   =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv         -- 4.���o�ɏꏊ�R�[�h�P
            ,iv_code_class2                  =>  cv_delivery_code                  -- 5.�R�[�h�敪�Q
            ,iv_entering_despatching_code2   =>  gt_order_sort_wk_tbl(lv_index).province               -- 6.���o�ɏꏊ�R�[�h�Q
            ,iv_ship_method                  =>  lv_max_ship_methods               -- 7.�o�ו��@
            ,iv_prod_class                   =>  gt_order_sort_wk_tbl(lv_index).prod_class_code        -- 8.���i�敪
            ,iv_auto_process_type            =>  NULL                              -- 9.�����z�ԑΏۋ敪
            ,id_standard_date                =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date     -- 10.���(�K�p�����)
            ,ov_retcode                      =>  lv_retcode                        -- 11.���^�[���R�[�h
            ,ov_errmsg_code                  =>  lv_errbuf                         -- 12.�G���[���b�Z�[�W�R�[�h
            ,ov_errmsg                       =>  lv_errmsg                         -- 13.�G���[���b�Z�[�W
            ,ov_loading_over_class           =>  lv_loading_over_class             -- 14.�ύڃI�[�o�[�敪
            ,ov_ship_methods                 =>  lv_ship_methods                   -- 15.�o�ו��@
            ,on_load_efficiency_weight       =>  ln_load_efficiency_weight         -- 16.�d�ʐύڌ���
            ,on_load_efficiency_capacity     =>  ln_load_efficiency_capacity       -- 17.�e�ϐύڌ���
            ,ov_mixed_ship_method            =>  lv_mixed_ship_method              -- 18.���ڔz���敪
          );
          --
          -- ���^�[���R�[�h�`�F�b�N
          IF ( lv_retcode = cv_status_normal ) THEN
            -- �ύڌ����̃`�F�b�N
            IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_drink ) THEN
              -- �h�����N�̏ꍇ
              ln_load_efficiency := ln_load_efficiency_weight;
            ELSE
              -- ���[�t�̏ꍇ
              ln_load_efficiency := ln_load_efficiency_capacity;
            END IF;
            --
            IF ( ln_load_efficiency <= 100 ) THEN
              -- �ύڌ�����100%�ȉ��̏ꍇ
              IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_leaf ) THEN
                -- ���[�t�̏ꍇ
                -- ========================================
                -- �o�׈˗�I/F�쐬�pPL/SQL�\�ɐݒ�
                -- ========================================
/* 2009/11/24 Ver1.17 Add Start */
                IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
                -- �w�b�_�L�[���u���C�N�����ꍇ
/* 2009/11/24 Ver1.17 Add End */
                ln_delivery_unit := ln_delivery_unit + 1;
/* 2009/11/24 Ver1.17 Add Start */
                END IF;
/* 2009/11/24 Ver1.17 Add End */
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<head_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF (lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP head_loop;
              ELSE
                -- �h�����N�̏ꍇ
                -- ========================================
                -- �o�׈˗�I/F�쐬�pPL/SQL�\�ɐݒ�
                -- ========================================
                IF ( ln_consolidation_flag = 0 ) THEN
                  ln_delivery_unit := ln_delivery_unit + 1;
                END IF;
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<head_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF (lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP head_loop;
                -- �d�ʂ�ޔ�
                ln_consolidation_flag := 1;
                ln_save_weight := ln_sum_weight;
              END IF;
            ELSE
              -- �ύڌ�����100%���傫���ꍇ
              IF ( gt_order_sort_wk_tbl(lv_index).prod_class_code = cv_prod_class_leaf ) THEN
                -- ���[�t�̏ꍇ
                -- ========================================
                -- �o�׈˗�I/F�쐬�pPL/SQL�\�ɐݒ�
                -- ========================================
/* 2009/11/24 Ver1.17 Add Start */
                IF ( lv_pre_head_sort_key <> gt_order_sort_wk_tbl(lv_index).head_sort_key ) THEN
                -- �w�b�_�L�[���u���C�N�����ꍇ
/* 2009/11/24 Ver1.17 Add End */
                ln_delivery_unit := ln_delivery_unit + 1;
/* 2009/11/24 Ver1.17 Add Start */
                END IF;
/* 2009/11/24 Ver1.17 Add End */
                lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                <<leaf_loop>>
                WHILE  lv_index_wk IS NOT NULL LOOP
                  IF ( lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key ) THEN
                    gt_order_sort_wk_tbl(lv_index_wk).checked_quantity := gt_order_sort_wk_tbl(lv_index_wk).base_quantity;
                    gt_order_sort_wk_tbl(lv_index_wk).delivery_unit := ln_delivery_unit;
                    gt_order_sort_wk_tbl(lv_index_wk).efficiency_over_flag := 1;
                    gt_order_sort_wk_tbl(lv_index_wk).max_ship_methods := lv_max_ship_methods;
                    gt_delivery_if_wk_tbl(gn_deliv_cnt) :=  gt_order_sort_wk_tbl(lv_index_wk);
                    gn_deliv_cnt := gn_deliv_cnt + 1;
                  END IF;
                  lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                END LOOP leaf_loop;
              ELSE
                -- �h�����N�̏ꍇ
                -- ==============================================
                -- �p���b�g�P�ʂ̐ςݏグ�`�F�b�N
                -- ==============================================
                -- ������
                ln_check_qty := 0;
                ln_save_check_qty := 0;
                ln_load_efficiency_weight := 0;
                ln_check_palette := 0;
                ln_check_step := 0;
                ln_check_case := 0;
                ln_loop_flag := 1;
                --
                <<pallet_check_loop>>
                WHILE (ln_loop_flag = 1 ) LOOP
/* 2009/12/01 Ver1.18 Add Start */
                  IF ( ln_total_palette > 0 ) THEN
/* 2009/12/01 Ver1.18 Add END */
                    -- �`�F�b�N�{���ݒ�(�{��/�p���b�g + �O��`�F�b�N����)
                    ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_palette + ln_save_check_qty;
                    -- ����`�F�b�N�Őςݑ����{��
                    ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_palette;
                    --
                    -- ==============================================
                    -- ���v�d�ʁE���v�e�ρE���v�p���b�g�d�ʂ��擾
                    -- ==============================================
                    xxwsh_common910_pkg.calc_total_value(
                       iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- �i�ڃR�[�h
                      ,in_quantity           => ln_check_qty                                       -- ����
                      ,ov_retcode            => lv_retcode                                         -- ���^�[���R�[�h
                      ,ov_errmsg_code        => lv_errbuf                                          -- �G���[���b�Z�[�W�R�[�h
                      ,ov_errmsg             => lv_errmsg                                          -- �G���[���b�Z�[�W
                      ,on_sum_weight         => ln_sum_weight                                      -- ���v�d��
                      ,on_sum_capacity       => ln_sum_capacity                                    -- ���v�e��
                      ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight   -- ���v�p���b�g�d��
                      ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- ���(�K�p�����)
                    );
                    --
                    -- ���^�[���R�[�h�`�F�b�N
                    IF ( lv_retcode = cv_status_normal ) THEN
                      -- ����̏ꍇ
                      IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                        -- �����敪�������ȊO�̏ꍇ�A���v�d�ʂɍ��v�p���b�g�d�ʂ����Z
                        ln_sum_weight := ln_sum_weight + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                      END IF;
                      --
                      IF ( ln_consolidation_flag = 1 ) THEN
                         ln_sum_weight := ln_sum_weight + ln_save_weight;
                      END IF;
                      --
                      -- ==============================================
                      -- �ύڌ����Z�o
                      -- ==============================================
                      xxwsh_common910_pkg.calc_load_efficiency(
                         in_sum_weight                 =>  ln_sum_weight                                       -- 1.���v�d��
                        ,in_sum_capacity               =>  NULL                                                -- 2.���v�e��
                        ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.�R�[�h�敪�P
                        ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.���o�ɏꏊ�R�[�h�P
                        ,iv_code_class2                =>  cv_delivery_code                     -- 5.�R�[�h�敪�Q
                        ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.���o�ɏꏊ�R�[�h�Q
                        ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.�o�ו��@
                        ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.���i�敪
                        ,iv_auto_process_type          =>  NULL                                  -- 9.�����z�ԑΏۋ敪
                        ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.���(�K�p�����)
                        ,ov_retcode                    =>  lv_retcode                                          -- 11.���^�[���R�[�h
                        ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.�G���[���b�Z�[�W�R�[�h
                        ,ov_errmsg                     =>  lv_errmsg                                           -- 13.�G���[���b�Z�[�W
                        ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.�ύڃI�[�o�[�敪
                        ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.�o�ו��@
                        ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.�d�ʐύڌ���
                        ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.�e�ϐύڌ���
                        ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.���ڔz���敪
                      );
                      -- ���^�[���R�[�h�`�F�b�N
                      IF ( lv_retcode = cv_status_normal ) THEN
                        -- ����̏ꍇ
                        IF ( ln_load_efficiency_weight <= 100 ) THEN
                          -- �ύڌ�����100%�ȉ��̏ꍇ
                          ln_save_check_qty := ln_check_qty;
                          ln_total_palette := ln_total_palette - 1;
                          --
                          ln_check_palette := ln_check_palette + 1;
                        ELSE
                          -- �ύڌ�����100%���傫���ꍇ
                          ln_palette_over_flag := cn_efficiency_over;
                        END IF;
                        --
/* 2009/12/01 Ver1.18 Add Start */
                      ELSE
                        -- �ύڌ����Z�o�G���[�̏ꍇ
                        ov_retcode := cv_status_warn;
                        -- ���b�Z�[�W�쐬
                        lv_output_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_calc_load_efficiency_err     -- ���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_item_div_name            -- ���i�敪�R�[�h
                          ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                          ,iv_token_name2  => cv_tkn_sum_weight               -- ���v�d��
                          ,iv_token_value2 => ln_sum_weight
                          ,iv_token_name3  => cv_tkn_sum_capacity             -- ���v�e��
                          ,iv_token_value3 => ''
                          ,iv_token_name4  => cv_tkn_whse_locat               -- �o�׌��ۊǏꏊ
                          ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                          ,iv_token_name5  => cv_tkn_delivery_code            -- �z����R�[�h
                          ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                          ,iv_token_name6  => cv_tkn_ship_method              -- �ő�z���敪
                          ,iv_token_value6 => lv_max_ship_methods
                          ,iv_token_name7  => cv_tkn_schedule_ship_date       -- �o�ח\���
                          ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                          ,iv_token_name8  => cv_tkn_err_msg                  -- �G���[���b�Z�[�W
                          ,iv_token_value8 => lv_errmsg
                        );
                        -- ���b�Z�[�W�o��
                        fnd_file.put_line(
                           which  => FND_FILE.OUTPUT
                          ,buff   => lv_output_msg
                        );
                        -- ��s�o��
                        fnd_file.put_line(
                           which  => FND_FILE.OUTPUT
                          ,buff   => NULL
                        );
                        -- ���[�v�𔲂���
                        EXIT;
                      END IF;
                    ELSE
                      -- ���v�d�ʁE���v�e�ώ擾�G���[
                      ov_retcode := cv_status_warn;
                      -- ���b�Z�[�W�쐬
                      lv_output_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_calc_total_value_err              -- ���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_order_no             -- �󒍔ԍ�
                        ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                        ,iv_token_name2  => cv_tkn_item_code            -- �󒍕i��
                        ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                        ,iv_token_name3  => cv_tkn_ordered_quantity     -- �󒍐���
                        ,iv_token_value3 => ln_check_qty
                        ,iv_token_name4  => cv_tkn_schedule_ship_date   -- �o�ח\���
                        ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                        ,iv_token_name5  => cv_tkn_err_msg              -- �G���[���b�Z�[�W
                        ,iv_token_value5 => lv_errmsg
                      );
                      -- ���b�Z�[�W�o��
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_output_msg
                      );
                      -- ��s�o��
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => NULL
                      );
                      -- ���[�v�𔲂���
                      EXIT;
                    END IF;
                  END IF;
/* 2009/12/01 Ver1.18 Add END */
                      IF ( ln_total_palette = 0 OR  ln_palette_over_flag = cn_efficiency_over ) THEN
                        IF ( ln_total_step > 0 ) THEN
                          -- ==============================================
                          -- �i�P�ʂ̐ςݏグ�`�F�b�N
                          -- ==============================================
                          -- �ϐ�������
                          ln_non_stack := ln_save_check_qty;
                          ln_palette_max_step_qty := gt_order_sort_wk_tbl(lv_index).palette_max_step_qty;
                          ln_load_efficiency_weight := 0;
                          ln_step_stack_flag := 0;
                          --
                          <<steps_check_loop>>
                          WHILE ( ln_total_step > 0 ) LOOP
                            -- �i�P�ʂŐϏグ
                            -- �`�F�b�N���ʂ�ݒ�
                            ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_step
                                            + ln_save_check_qty;
                            -- ����`�F�b�N�Őςݑ����{��
                            ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_step;
                            --
                            -- ==============================================
                            -- ���v�d�ʁE���v�e�ρE���v�p���b�g�d�ʂ��擾
                            -- ==============================================
                            xxwsh_common910_pkg.calc_total_value(
                               iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- �i�ڃR�[�h
                              ,in_quantity           => ln_check_qty                                       -- ����
                              ,ov_retcode            => lv_retcode                                         -- ���^�[���R�[�h
                              ,ov_errmsg_code        => lv_errbuf                                          -- �G���[���b�Z�[�W�R�[�h
                              ,ov_errmsg             => lv_errmsg                                          -- �G���[���b�Z�[�W
                              ,on_sum_weight         => ln_sum_weight                                      -- ���v�d��
                              ,on_sum_capacity       => ln_sum_capacity                                    -- ���v�e��
                              ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight                               -- ���v�p���b�g�d��
                              ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- ���(�K�p�����)
                            );
                            -- ���^�[���R�[�h�`�F�b�N
                            IF ( lv_retcode = cv_status_normal ) THEN
                              -- ����̏ꍇ
                              IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                                -- �����敪������('1')�ȊO�̏ꍇ
                                -- ���v�d�ʂƍ��v�p���b�g�d�ʂ����Z
                                ln_sum_weight := ln_sum_weight
                                                 + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                              END IF;
                              --
                              IF ( ln_consolidation_flag = 1 ) THEN
                                ln_sum_weight := ln_sum_weight + ln_save_weight;
                              END IF;
                              --
                              -- ==============================================
                              -- �ύڌ����Z�o
                              -- ==============================================
                              xxwsh_common910_pkg.calc_load_efficiency(
                                 in_sum_weight                 =>  ln_sum_weight                                       -- 1.���v�d��
                                ,in_sum_capacity               =>  NULL                                                -- 2.���v�e��
                                ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.�R�[�h�敪�P
                                ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.���o�ɏꏊ�R�[�h�P
                                ,iv_code_class2                =>  cv_delivery_code                          -- 5.�R�[�h�敪�Q
                                ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.���o�ɏꏊ�R�[�h�Q
                                ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.�o�ו��@
                                ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.���i�敪
                                ,iv_auto_process_type          =>  NULL                                  -- 9.�����z�ԑΏۋ敪
                                ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.���(�K�p�����)
                                ,ov_retcode                    =>  lv_retcode                                          -- 11.���^�[���R�[�h
                                ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.�G���[���b�Z�[�W�R�[�h
                                ,ov_errmsg                     =>  lv_errmsg                                           -- 13.�G���[���b�Z�[�W
                                ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.�ύڃI�[�o�[�敪
                                ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.�o�ו��@
                                ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.�d�ʐύڌ���
                                ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.�e�ϐύڌ���
                                ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.���ڔz���敪
                              );
                              -- ���^�[���R�[�h�`�F�b�N
                              IF ( lv_retcode = cv_status_normal ) THEN
                                -- ����̏ꍇ
                                IF ( ln_load_efficiency_weight <= 100 ) THEN
                                  ln_save_check_qty := ln_check_qty;
                                  ln_total_step := ln_total_step - 1;
                                  --
                                  ln_check_step := ln_check_step + 1;
                                ELSE
                                  -- ��i���Ϗグ���Ȃ��ꍇ
                                  IF ( ln_save_check_qty = 0 ) THEN
                                    -- �`�F�b�N���ʂ�ޔ�
                                    ln_save_check_qty := ln_non_stack;
                                  END IF;
                                  -- �ύڌ�����100%���傫���ꍇ�A���גP�ʂ̐Ϗグ
                                  EXIT;
                                END IF; -- �i�P�ʃ`�F�b�N:�ύڌ����I�[�o�[�m�F
                              ELSE
                                -- �i�P�ʃ`�F�b�N:�ύڌ����Z�o�G���[
                                -- -- �ύڌ����Z�o�G���[�̏ꍇ
                                ov_retcode := cv_status_warn;
                                -- ���b�Z�[�W�쐬
                                lv_output_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
                                  ,iv_name         => cv_calc_load_efficiency_err-- �ύڌ����Z�o�G���[     -- ���b�Z�[�W
                                  ,iv_token_name1  => cv_tkn_item_div_name            -- ���i�敪�R�[�h
                                  ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                                  ,iv_token_name2  => cv_tkn_sum_weight               -- ���v�d��
                                  ,iv_token_value2 => TO_CHAR(ln_sum_weight)
                                  ,iv_token_name3  => cv_tkn_sum_capacity             -- ���v�e��
                                  ,iv_token_value3 => ''
                                  ,iv_token_name4  => cv_tkn_whse_locat               -- �o�׌��ۊǏꏊ
                                  ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                                  ,iv_token_name5  => cv_tkn_delivery_code            -- �z����R�[�h
                                  ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                                  ,iv_token_name6  => cv_tkn_ship_method              -- �ő�z���敪
                                  ,iv_token_value6 => lv_max_ship_methods
                                  ,iv_token_name7  => cv_tkn_schedule_ship_date       -- �o�ח\���
                                  ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                  ,iv_token_name8  => cv_tkn_err_msg                  -- �G���[���b�Z�[�W
                                  ,iv_token_value8 => lv_errmsg
                                );
                                -- ���b�Z�[�W�o��
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => lv_output_msg
                                );
                                -- ��s�o��
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => NULL
                                );
                                -- ���[�v�𔲂���
                                EXIT;
                              END IF;  -- �i�P�ʃ`�F�b�N:calc_load_efficiency�֐��̌��ʊm�F
                            ELSE
                              -- �i�P�ʃ`�F�b�N:���v�d�ʁE���v�e�ώ擾�G���[
                              ov_retcode := cv_status_warn;
                              -- ���b�Z�[�W�쐬
                              lv_output_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_calc_total_value_err              -- ���b�Z�[�W
                                ,iv_token_name1  => cv_tkn_order_no             -- �󒍔ԍ�
                                ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                                ,iv_token_name2  => cv_tkn_item_code            -- �󒍕i��
                                ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                                ,iv_token_name3  => cv_tkn_ordered_quantity     -- �󒍐���
                                ,iv_token_value3 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).ordered_quantity)
                                ,iv_token_name4  => cv_tkn_schedule_ship_date   -- �o�ח\���
                                ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                ,iv_token_name5  => cv_tkn_err_msg              -- �G���[���b�Z�[�W
                                ,iv_token_value5 => lv_errmsg
                              );
                              -- ���b�Z�[�W�o��
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => lv_output_msg
                              );
                              -- ��s�o��
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => NULL
                              );
                              -- ���[�v�𔲂���
                              EXIT;
                            END IF;  -- �i�P�ʃ`�F�b�N:calc_total_value�֐��̌��ʊm�F
                          END LOOP steps_check_loop;
                        END IF;  -- �i�P�ʃ`�F�b�N:�i���m�F
                        --
                        IF ( ln_total_case > 0 ) THEN
                          -- ==============================================
                          -- ���גP�ʂ̐ςݏグ�`�F�b�N
                          -- ==============================================
                          -- �i�Ϗグ�Őύڌ�����100%�������������ʂ�ݒ�
                          ln_check_qty := ln_save_check_qty;
                          ln_non_stack := ln_save_check_qty;
                          ln_save_check_qty := 0;
                          ln_case_qty := gt_order_sort_wk_tbl(lv_index).qty_case;
                          ln_load_efficiency_weight := 0;
                          <<line_check_loop>>
                          WHILE (( ln_load_efficiency_weight <= 100 )
                                   AND ( ln_total_case > 0 )) LOOP
                            ln_check_qty := gt_order_sort_wk_tbl(lv_index).qty_case + ln_check_qty + ln_save_check_qty;
                            -- ����`�F�b�N�Őςݑ����{��
                            ln_now_check_qty := gt_order_sort_wk_tbl(lv_index).qty_case;
                            --
                            -- ==============================================
                            -- ���v�d�ʁE���v�e�ρE���v�p���b�g�d�ʂ��擾
                            -- ==============================================
                            xxwsh_common910_pkg.calc_total_value(
                               iv_item_no            => gt_order_sort_wk_tbl(lv_index).item_code           -- �i�ڃR�[�h
                              ,in_quantity           => ln_check_qty                                   -- ����
                              ,ov_retcode            => lv_retcode                                         -- ���^�[���R�[�h
                              ,ov_errmsg_code        => lv_errbuf                                          -- �G���[���b�Z�[�W�R�[�h
                              ,ov_errmsg             => lv_errmsg                                          -- �G���[���b�Z�[�W
                              ,on_sum_weight         => ln_sum_weight                                      -- ���v�d��
                              ,on_sum_capacity       => ln_sum_capacity                                    -- ���v�e��
                              ,on_sum_pallet_weight  => gt_order_sort_wk_tbl(lv_index).sum_pallet_weight                               -- ���v�p���b�g�d��
                              ,id_standard_date      => gt_order_sort_wk_tbl(lv_index).schedule_ship_date  -- ���(�K�p�����)
                            );
                            -- ���^�[���R�[�h�`�F�b�N
                            IF ( lv_retcode = cv_status_normal ) THEN
                              -- �����敪�������ȊO�̏ꍇ�A���v�d�ʂɍ��v�p���b�g�d�ʂ����Z
                              IF ( lv_small_amount_class <> cv_small_amount_class ) THEN
                                ln_sum_weight := ln_sum_weight + gt_order_sort_wk_tbl(lv_index).sum_pallet_weight;
                              END IF;
                              --
                              IF ( ln_consolidation_flag = 1 ) THEN
                                ln_sum_weight := ln_sum_weight + ln_save_weight;
                              END IF;
                              -- ==============================================
                              -- �ύڌ����Z�o
                              -- ==============================================
                              xxwsh_common910_pkg.calc_load_efficiency(
                                 in_sum_weight                 =>  ln_sum_weight                                       -- 1.���v�d��
                                ,in_sum_capacity               =>  NULL                                                -- 2.���v�e��
                                ,iv_code_class1                =>  cv_warehouse_code                                   -- 3.�R�[�h�敪�P
                                ,iv_entering_despatching_code1 =>  gt_order_sort_wk_tbl(lv_index).ship_to_subinv             -- 4.���o�ɏꏊ�R�[�h�P
                                ,iv_code_class2                =>  cv_delivery_code                 -- 5.�R�[�h�敪�Q
                                ,iv_entering_despatching_code2 =>  gt_order_sort_wk_tbl(lv_index).province                               -- 6.���o�ɏꏊ�R�[�h�Q
                                ,iv_ship_method                =>  lv_max_ship_methods                                 -- 7.�o�ו��@
                                ,iv_prod_class                 =>  gt_order_sort_wk_tbl(lv_index).prod_class_code      -- 8.���i�敪
                                ,iv_auto_process_type          =>  NULL                                  -- 9.�����z�ԑΏۋ敪
                                ,id_standard_date              =>  gt_order_sort_wk_tbl(lv_index).schedule_ship_date   -- 10.���(�K�p�����)
                                ,ov_retcode                    =>  lv_retcode                                          -- 11.���^�[���R�[�h
                                ,ov_errmsg_code                =>  lv_errbuf                                           -- 12.�G���[���b�Z�[�W�R�[�h
                                ,ov_errmsg                     =>  lv_errmsg                                           -- 13.�G���[���b�Z�[�W
                                ,ov_loading_over_class         =>  lv_loading_over_class                               -- 14.�ύڃI�[�o�[�敪
                                ,ov_ship_methods               =>  lv_ship_methods                                     -- 15.�o�ו��@
                                ,on_load_efficiency_weight     =>  ln_load_efficiency_weight                           -- 16.�d�ʐύڌ���
                                ,on_load_efficiency_capacity   =>  ln_load_efficiency_capacity                         -- 17.�e�ϐύڌ���
                                ,ov_mixed_ship_method          =>  lv_mixed_ship_method                                -- 18.���ڔz���敪
                              );
                              -- ���^�[���R�[�h�`�F�b�N
                              IF ( lv_retcode = cv_status_normal ) THEN
                                IF ( ln_load_efficiency_weight <= 100 ) THEN
                                  ln_check_case := ln_check_case + 1;
                                  ln_total_case := ln_total_case - 1;
                                ELSE
                                  -- ���[�v�𔲂���
                                  EXIT;
                                END IF;
                              ELSE
                                -- �P�[�X�P�ʃ`�F�b�N:�ύڌ����擾�G���[
                                ov_retcode := cv_status_warn;
                                -- ���b�Z�[�W�쐬
                                lv_output_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
                                  ,iv_name         => cv_calc_load_efficiency_err     -- ���b�Z�[�W
                                  ,iv_token_name1  => cv_tkn_item_div_name            -- ���i�敪�R�[�h
                                  ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
                                  ,iv_token_name2  => cv_tkn_sum_weight               -- ���v�d��
                                  ,iv_token_value2 => TO_CHAR(ln_sum_weight)
                                  ,iv_token_name3  => cv_tkn_sum_capacity             -- ���v�e��
                                  ,iv_token_value3 => ''
                                  ,iv_token_name4  => cv_tkn_whse_locat               -- �o�׌��ۊǏꏊ
                                  ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
                                  ,iv_token_name5  => cv_tkn_delivery_code            -- �z����R�[�h
                                  ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
                                  ,iv_token_name6  => cv_tkn_ship_method              -- �ő�z���敪
                                  ,iv_token_value6 => lv_max_ship_methods
                                  ,iv_token_name7  => cv_tkn_schedule_ship_date       -- �o�ח\���
                                  ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                  ,iv_token_name8  => cv_tkn_err_msg                  -- �G���[���b�Z�[�W
                                  ,iv_token_value8 => lv_errmsg
                                );
                                -- ���b�Z�[�W�o��
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => lv_output_msg
                                );
                                -- ��s�o��
                                fnd_file.put_line(
                                   which  => FND_FILE.OUTPUT
                                  ,buff   => NULL
                                );
                                -- ���[�v�𔲂���
                                EXIT;
                              END IF;  -- �P�[�X�P�ʃ`�F�b�N:�ύڌ����擾�֐��̌��ʊm�F
                            ELSE
                              -- �P�[�X�P�ʃ`�F�b�N:���v�d�ʁE�e�ώ擾�G���[
                              ov_retcode := cv_status_warn;
                              -- ���b�Z�[�W�쐬
                              lv_output_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_calc_total_value_err              -- ���b�Z�[�W
                                ,iv_token_name1  => cv_tkn_order_no             -- �󒍔ԍ�
                                ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
                                ,iv_token_name2  => cv_tkn_item_code            -- �󒍕i��
                                ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
                                ,iv_token_name3  => cv_tkn_ordered_quantity     -- �󒍐���
                                ,iv_token_value3 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).ordered_quantity)
                                ,iv_token_name4  => cv_tkn_schedule_ship_date   -- �o�ח\���
                                ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
                                ,iv_token_name5  => cv_tkn_err_msg              -- �G���[���b�Z�[�W
                                ,iv_token_value5 => lv_errmsg
                              );
                              -- ���b�Z�[�W�o��
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => lv_output_msg
                              );
                              -- ��s�o��
                              fnd_file.put_line(
                                 which  => FND_FILE.OUTPUT
                                ,buff   => NULL
                              );
                              -- ���[�v�𔲂���
                              EXIT;
                            END IF;  -- �P�[�X�P�ʃ`�F�b�N:���v�d�ʁE�e�ώ擾�֐��̌��ʊm�F
                          END LOOP line_check_loop;
                        END IF;  -- �P�[�X�P�ʃ`�F�b�N:�P�[�X���m�F
                        --
                        -- ========================================
                        -- �o�׈˗��쐬
                        -- ========================================
                        IF ( ln_consolidation_flag = 0 ) THEN
                          ln_delivery_unit := ln_delivery_unit + 1;
                        END IF;
                        ln_order_qty := 0;
                        lv_index_wk := gt_order_sort_wk_tbl.FIRST;
                        <<deliv_palette_loop>>
                        WHILE  lv_index_wk IS NOT NULL LOOP
                         IF (( lv_line_key = gt_order_sort_wk_tbl(lv_index_wk).line_key )
                              AND
                             (     ( ln_check_palette > 0 AND gt_order_sort_wk_tbl(lv_index_wk).conv_palette > 0 )
                               OR  ( ln_check_step > 0    AND gt_order_sort_wk_tbl(lv_index_wk).conv_step > 0 )
                               OR  ( ln_check_case > 0    AND gt_order_sort_wk_tbl(lv_index_wk).conv_case > 0)))
                         THEN
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_palette > 0 AND ln_check_palette > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_palette >= ln_check_palette ) THEN
                               ln_set := ln_check_palette;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_palette);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_palette := gt_order_sort_wk_tbl(lv_index_wk).conv_palette - ln_check_palette;
                               ln_check_palette := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_palette;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_palette);
                               ln_check_palette := ln_check_palette - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_palette := 0;
                             END IF;
                           END IF;
                           --
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_step > 0 AND ln_check_step > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_step >= ln_check_step ) THEN
                               ln_set := ln_check_step;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_step);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_step := gt_order_sort_wk_tbl(lv_index_wk).conv_step - ln_check_step;
                               ln_check_step := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_step;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_step);
                               ln_check_step := ln_check_step - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_step := 0;
                             END IF;
                           END IF;
                           --
                           IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_case > 0 AND ln_check_case > 0 ) THEN
                             IF ( gt_order_sort_wk_tbl(lv_index_wk).conv_case >= ln_check_case ) THEN
                               ln_set := ln_check_case;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_case);
                               gt_order_sort_wk_tbl(lv_index_wk).conv_case := gt_order_sort_wk_tbl(lv_index_wk).conv_case - ln_check_case;
                               ln_check_case := 0;
                             ELSE
                               ln_set := gt_order_sort_wk_tbl(lv_index_wk).conv_case;
                               ln_order_qty := ln_order_qty + ( ln_set * gt_order_sort_wk_tbl(lv_index_wk).qty_case);
                               ln_check_case := ln_check_case - ln_set;
                               gt_order_sort_wk_tbl(lv_index_wk).conv_case := 0;
                             END IF;
                           END IF;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt) := gt_order_sort_wk_tbl(lv_index_wk);
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).max_ship_methods := lv_max_ship_methods;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).delivery_unit := ln_delivery_unit;
                           gt_delivery_if_wk_tbl(gn_deliv_cnt).checked_quantity := ln_order_qty;
                           gn_deliv_cnt := gn_deliv_cnt + 1;
                           ln_order_qty := 0;
                         END IF;
                          lv_index_wk := gt_order_sort_wk_tbl.NEXT(lv_index_wk);
                        END LOOP deliv_palette_loop;
                        --
                        -- �ϐ��N���A
                        ln_check_palette := 0;
                        ln_check_step := 0;
                        ln_check_case := 0;
                        ln_save_check_qty := 0;
                        ln_palette_over_flag := cn_efficiency_non_over;
                        --
                        IF ( ln_load_efficiency_weight <= 100) THEN
                          ln_consolidation_flag := 1;
                          ln_save_weight := ln_sum_weight;
                        ELSE
                          ln_consolidation_flag := 0;
                        END IF;
                        IF ( ln_total_palette <= 0 AND ln_total_step <= 0 AND ln_total_case <= 0) THEN
                          ln_loop_flag := 0;
                        END IF;
                      END IF;
/* 2009/12/01 Ver1.18 DEL START */
--                    ELSE
--                      -- �ύڌ����Z�o�G���[�̏ꍇ
--                      ov_retcode := cv_status_warn;
--                      -- ���b�Z�[�W�쐬
--                      lv_output_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_calc_load_efficiency_err     -- ���b�Z�[�W
--                        ,iv_token_name1  => cv_tkn_item_div_name            -- ���i�敪�R�[�h
--                        ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
--                        ,iv_token_name2  => cv_tkn_sum_weight               -- ���v�d��
--                        ,iv_token_value2 => ln_sum_weight
--                        ,iv_token_name3  => cv_tkn_sum_capacity             -- ���v�e��
--                        ,iv_token_value3 => ''
--                        ,iv_token_name4  => cv_tkn_whse_locat               -- �o�׌��ۊǏꏊ
--                        ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
--                        ,iv_token_name5  => cv_tkn_delivery_code            -- �z����R�[�h
--                        ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
--                        ,iv_token_name6  => cv_tkn_ship_method              -- �ő�z���敪
--                        ,iv_token_value6 => lv_max_ship_methods
--                        ,iv_token_name7  => cv_tkn_schedule_ship_date       -- �o�ח\���
--                        ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
--                        ,iv_token_name8  => cv_tkn_err_msg                  -- �G���[���b�Z�[�W
--                        ,iv_token_value8 => lv_errmsg
--                      );
--                      -- ���b�Z�[�W�o��
--                      fnd_file.put_line(
--                         which  => FND_FILE.OUTPUT
--                        ,buff   => lv_output_msg
--                      );
--                      -- ��s�o��
--                      fnd_file.put_line(
--                         which  => FND_FILE.OUTPUT
--                        ,buff   => NULL
--                      );
--                      -- ���[�v�𔲂���
--                      EXIT;
--                    END IF;
--                  ELSE
--                    -- ���v�d�ʁE���v�e�ώ擾�G���[
--                    ov_retcode := cv_status_warn;
--                    -- ���b�Z�[�W�쐬
--                    lv_output_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
--                      ,iv_name         => cv_calc_total_value_err              -- ���b�Z�[�W
--                      ,iv_token_name1  => cv_tkn_order_no             -- �󒍔ԍ�
--                      ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).order_number
--                      ,iv_token_name2  => cv_tkn_item_code            -- �󒍕i��
--                      ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).item_code
--                      ,iv_token_name3  => cv_tkn_ordered_quantity     -- �󒍐���
--                      ,iv_token_value3 => ln_check_qty
--                      ,iv_token_name4  => cv_tkn_schedule_ship_date   -- �o�ח\���
--                      ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
--                      ,iv_token_name5  => cv_tkn_err_msg              -- �G���[���b�Z�[�W
--                      ,iv_token_value5 => lv_errmsg
--                    );
--                    -- ���b�Z�[�W�o��
--                    fnd_file.put_line(
--                       which  => FND_FILE.OUTPUT
--                      ,buff   => lv_output_msg
--                    );
--                    -- ��s�o��
--                    fnd_file.put_line(
--                       which  => FND_FILE.OUTPUT
--                      ,buff   => NULL
--                    );
--                    -- ���[�v�𔲂���
--                    EXIT;
--                  END IF;
/* 2009/12/01 Ver1.18 DEL END */
                END LOOP pallet_check_loop;  -- �p���b�g�P�ʂ̐ςݏグ�`�F�b�N
              END IF;
            END IF;
          ELSE
            -- �ύڌ����Z�o�G���[
            ov_retcode := cv_status_warn;
            lv_output_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
              ,iv_name         => cv_calc_load_efficiency_err     -- ���b�Z�[�W
              ,iv_token_name1  => cv_tkn_item_div_name        -- ���i�敪
              ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).prod_class_code
              ,iv_token_name2  => cv_tkn_sum_weight           -- ���v�d��
              ,iv_token_value2 => TO_CHAR(ln_sum_weight)
              ,iv_token_name3  => cv_tkn_sum_capacity         -- ���v�e��
              ,iv_token_value3 => TO_CHAR(ln_sum_capacity)
              ,iv_token_name4  => cv_tkn_whse_locat           -- �o�׌��ۊǏꏊ
              ,iv_token_value4 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
              ,iv_token_name5  => cv_tkn_delivery_code        -- �z����
              ,iv_token_value5 => gt_order_sort_wk_tbl(lv_index).province
              ,iv_token_name6  => cv_tkn_ship_method          -- �o�ו��@
              ,iv_token_value6 => lv_max_ship_methods
              ,iv_token_name7  => cv_tkn_schedule_ship_date   -- �o�ח\���
              ,iv_token_value7 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
              ,iv_token_name8  => cv_tkn_err_msg              -- �G���[���b�Z�[�W
              ,iv_token_value8 => lv_errmsg
            );
            --
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_output_msg
            );
            -- ��s�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => NULL
            );
          --
          END IF;
          --
        ELSE
          -- �ő�z���敪�擾�G���[
          ov_retcode := cv_status_warn;
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
            ,iv_name         => cv_max_ship_method_err       -- ���b�Z�[�W
            ,iv_token_name1  => cv_tkn_whse_locat            -- �o�׌��ۊǏꏊ
            ,iv_token_value1 => gt_order_sort_wk_tbl(lv_index).ship_to_subinv
            ,iv_token_name2  => cv_tkn_delivery_code         -- �z����
            ,iv_token_value2 => gt_order_sort_wk_tbl(lv_index).province
            ,iv_token_name3  => cv_tkn_item_div_name         -- ���i�敪
            ,iv_token_value3 => gt_order_sort_wk_tbl(lv_index).prod_class_code
            ,iv_token_name4  => cv_tkn_schedule_ship_date    -- �o�ח\���
            ,iv_token_value4 => TO_CHAR(gt_order_sort_wk_tbl(lv_index).schedule_ship_date, cv_date_fmt_date_time)
          );
          --
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- ��s�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
        END IF;
        --
        lv_pre_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        lv_pre_head_sort_key := gt_order_sort_wk_tbl(lv_index).head_sort_key;
        lv_index := gt_order_sort_wk_tbl.NEXT(lv_index);
        IF ( lv_index IS NOT NULL ) THEN
          lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        END IF;
      ELSE
        lv_pre_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        lv_pre_head_sort_key := gt_order_sort_wk_tbl(lv_index).head_sort_key;
        lv_index := gt_order_sort_wk_tbl.NEXT(lv_index);
        IF ( lv_index IS NOT NULL ) THEN
          lv_line_key := gt_order_sort_wk_tbl(lv_index).line_key;
        END IF;
      END IF;
      -- �A�E�g�p�����[�^�̃��^�[���R�[�h�`�F�b�N
      IF ( ov_retcode = cv_status_warn ) THEN
        -- �x���̏ꍇ�A���[�v�𔲂���
        EXIT;
      END IF;
    END LOOP check_loop;
    --
  --
  EXCEPTION
    WHEN small_amount_class_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_max_ship_methods
        ,iv_token_name1  => cv_tkn_max_ship_methods
        ,iv_token_value1 => lv_max_ship_methods
      );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END weight_check;
--
  /**********************************************************************************
   * Procedure Name   : order_line_division
   * Description      : �󒍖��׃f�[�^��������(A-15)
   ***********************************************************************************/
  PROCEDURE order_line_division(
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_line_division'; -- �v���O������
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
    cv_order_source         CONSTANT VARCHAR2(2) := '98';    -- �󒍃\�[�X�Q�Ƃ̐擪����
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
    cn_pad_num_char         CONSTANT NUMBER := 10;           -- PAD�֐��Ŗ��ߍ��ޕ�����
    --
    lv_sort_key             VARCHAR2(1000);       -- �\�[�g�L�[
    ln_max_qty              NUMBER DEFAULT 0;     -- �ő����ʗp
    ln_comp_qty             NUMBER;               -- ��r�Ώې���
    ln_comp_end_qty         NUMBER;               -- ��r�ϐ���
    ln_comp_flag            NUMBER DEFAULT 0;     -- ��r�ϐ��ʐݒ�σt���O(0:���A1:�ς�)
    ln_upd_cnt              NUMBER DEFAULT 1;     -- �󒍖��׍X�V�pPL/SQL�\�̃C���f�b�N�X
    ln_ins_cnt              NUMBER DEFAULT 1;     -- �󒍖��דo�^�pPL/SQL�\�̃C���f�b�N�X
    lv_idx                  VARCHAR2(1000);
    ln_header_id            NUMBER;
    ln_delivey_unit         NUMBER;
    ln_order_source_ref     NUMBER;
    lv_order_source         VARCHAR2(12);         -- �󒍃\�[�X
    lv_output_msg           VARCHAR2(1000);
    lv_item_code            VARCHAR2(30);
    ln_delivery_id          NUMBER;
    ln_qty                  NUMBER;
    --
    lt_order_line_tbl     g_n_order_data_ttype;
    TYPE l_tab_order_line IS TABLE OF BOOLEAN INDEX BY VARCHAR2(1000);
    lt_line_check_tbl     l_tab_order_line;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF ( gt_delivery_if_wk_tbl.COUNT > 0 ) THEN
      -- ======================================
      -- �o�׈˗��p�w�b�_�[ID
      -- ======================================
      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
      INTO   ln_header_id
      FROM   dual;
      ln_delivey_unit := gt_delivery_if_wk_tbl(1).delivery_unit;
      --
      -- ======================================
      -- �o�׈˗�No
      -- ======================================
      SELECT xxcos_order_source_ref_s01.NEXTVAL
      INTO   ln_order_source_ref
      FROM   dual;
      --
      lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                 ,cn_pad_num_char
                                                 ,cv_pad_char);
      --
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF ( ln_delivey_unit <> gt_delivery_if_wk_tbl(ln_idx).delivery_unit ) THEN
          -- ======================================
          -- �o�׈˗��p�w�b�_�[ID
          -- ======================================
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
          INTO   ln_header_id
          FROM   dual;
          --
          -- ======================================
          -- �o�׈˗�No
          -- ======================================
          SELECT xxcos_order_source_ref_s01.NEXTVAL
          INTO   ln_order_source_ref
          FROM   dual;
          --
          lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                     ,cn_pad_num_char
                                                     ,cv_pad_char);
          ln_delivey_unit := gt_delivery_if_wk_tbl(ln_idx).delivery_unit;
        END IF;
        --
        gt_delivery_if_wk_tbl(ln_idx).req_header_id := ln_header_id;
        gt_delivery_if_wk_tbl(ln_idx).order_source := lv_order_source;
        --
      END LOOP line_loop;
      --
      -- ======================================
      -- �󒍖��ו����f�[�^�쐬
      -- ======================================
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF ( lt_order_line_tbl.EXISTS(TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).line_id )) = FALSE ) THEN
          -- ���݂��Ȃ��ꍇ
          -- �`�F�b�N�p�e�[�u���ɐݒ�
          lt_order_line_tbl(TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).line_id )) := gt_delivery_if_wk_tbl(ln_idx);
          -- �󒍖��׍X�VPL/SQL�\�ɑޔ�
          gt_order_upd_tbl(ln_upd_cnt) := gt_delivery_if_wk_tbl(ln_idx);
          ln_upd_cnt := ln_upd_cnt + 1;
        ELSE
          -- ���݂����ꍇ(�����̏ꍇ)
          -- �󒍖��דo�^PL/SQL�\�ɑޔ�
          gt_order_ins_tbl(ln_ins_cnt) := gt_delivery_if_wk_tbl(ln_idx);
          ln_ins_cnt := ln_ins_cnt + 1;
        END IF;
      END LOOP line_loop;
      --
      gt_order_sort_tbl.DELETE;
      lv_item_code     := gt_delivery_if_wk_tbl(1).item_code;
      ln_delivery_id   := gt_delivery_if_wk_tbl(1).req_header_id;
      ln_qty := 0;
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        lv_sort_key :=
            TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).req_header_id)
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).ordered_date , cv_date_fmt_no_sep )             -- �󒍓�
            || gt_delivery_if_wk_tbl(ln_idx).province                                                 -- �z����R�[�h
            || NVL( gt_delivery_if_wk_tbl(ln_idx).shipping_instructions ,cv_blank )                   -- �o�׎w��
            || NVL( gt_delivery_if_wk_tbl(ln_idx).cust_po_number, cv_blank )                          -- �ڋq�����ԍ�
/* 2009/10/19 Ver.1.13 Add Start */
            || gt_delivery_if_wk_tbl(ln_idx).base_code                                                -- �Ǌ����_(���㋒�_)
/* 2009/10/19 Ver.1.13 Add End */
            || gt_delivery_if_wk_tbl(ln_idx).delivery_base_code                                       -- ���͋��_
            || gt_delivery_if_wk_tbl(ln_idx).ship_to_subinv                                           -- �o�׌��ۊǏꏊ
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).schedule_ship_date , cv_date_fmt_no_sep )       -- �o�ח\���
            || TO_CHAR( gt_delivery_if_wk_tbl(ln_idx).request_date , cv_date_fmt_no_sep )             -- �[�i�\���
            || NVL( gt_delivery_if_wk_tbl(ln_idx).time_from , cv_blank )                              -- ���Ԏw��From
            || NVL( gt_delivery_if_wk_tbl(ln_idx).time_to , cv_blank )                                -- ���Ԏw��To
            || gt_delivery_if_wk_tbl(ln_idx).prod_class_code                                          -- ���i�敪
            || gt_delivery_if_wk_tbl(ln_idx).item_code;                                               -- �i�ڃR�[�h
        IF ( gt_order_sort_tbl.EXISTS(lv_sort_key) = TRUE ) THEN
          -- ���݂��Ă���ꍇ
          gt_order_sort_tbl(lv_sort_key).checked_quantity :=
               gt_order_sort_tbl(lv_sort_key).checked_quantity + gt_delivery_if_wk_tbl(ln_idx).checked_quantity;
        ELSE
          -- ���݂��Ă��Ȃ��ꍇ
          gt_order_sort_tbl(lv_sort_key) := gt_delivery_if_wk_tbl(ln_idx);
        END IF;
      END LOOP line_loop;
      --
      -- ======================================
      -- �ύڌ����I�[�o�[�`�F�b�N
      -- ======================================
      ln_delivey_unit := -1;
      <<line_loop>>
      FOR ln_idx IN 1..gt_delivery_if_wk_tbl.COUNT LOOP
        IF (( ln_delivey_unit <> gt_delivery_if_wk_tbl(ln_idx).delivery_unit )
              AND ( gt_delivery_if_wk_tbl(ln_idx).efficiency_over_flag = 1  )) THEN
          -- ===============================
          -- �ύڌ����I�[�o���b�Z�[�W�o��
          -- ===============================
          lv_output_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_xxcos_short_name           -- �A�v���P�[�V�����Z�k��
            ,iv_name         => cv_leaf_capacity_over_err     -- ���b�Z�[�W
            ,iv_token_name1  => cv_tkn_order_source           -- �o�׈˗�NO
            ,iv_token_value1 => gt_delivery_if_wk_tbl(ln_idx).order_source
            ,iv_token_name2  => cv_tkn_whse_locat             -- �o�׌��ۊǏꏊ
            ,iv_token_value2 => gt_delivery_if_wk_tbl(ln_idx).ship_to_subinv
            ,iv_token_name3  => cv_tkn_delivery_code          -- �z����
            ,iv_token_value3 => gt_delivery_if_wk_tbl(ln_idx).province
            ,iv_token_name4  => cv_tkn_ship_method            -- �o�ו��@
            ,iv_token_value4 => gt_delivery_if_wk_tbl(ln_idx).max_ship_methods
            ,iv_token_name5  => cv_tkn_schedule_ship_date     -- �o�ח\���
            ,iv_token_value5 => TO_CHAR(gt_delivery_if_wk_tbl(ln_idx).schedule_ship_date, cv_date_fmt_date_time)
          );
          --
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_output_msg
          );
          -- ��s�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => NULL
          );
          ln_delivey_unit := gt_delivery_if_wk_tbl(ln_idx).delivery_unit;
        END IF;
      END LOOP line_loop;
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
  END order_line_division;
--
  /**********************************************************************************
   * Procedure Name   : order_line_insert
   * Description      : �󒍖��דo�^(A-16)
   ***********************************************************************************/
  PROCEDURE order_line_insert(
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_line_insert'; -- �v���O������
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
    cn_index                   CONSTANT NUMBER := 1;    -- �C���f�b�N�X
    cn_version                 CONSTANT NUMBER := 1.0;  -- API�̃o�[�W����
    cv_calculate_price_flag_n  CONSTANT VARCHAR2(1) := 'N';
    --
    lv_key_info                VARCHAR2(1000);          -- �L�[���
    lv_output_msg              VARCHAR2(1000);          -- �o�̓��b�Z�[�W
    lv_table_name              VARCHAR2(100);           -- �e�[�u����
    lv_order_number            VARCHAR2(100);           -- �󒍔ԍ�
    lv_item_name               VARCHAR2(100);           -- �i��
    lv_quantity                VARCHAR2(100);           -- ����
    lv_return_status           VARCHAR2(2);
    lv_msg_data                VARCHAR2(2000);
    ln_cnt                     NUMBER DEFAULT 1;        -- �o�^�����p
    ln_max_number              NUMBER;                  -- �ő喾�הԍ��p
    ln_after_max_number        NUMBER;
    ln_msg_count               NUMBER;
    --
    -- �󒍖��דo�^API�p
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
    --
    TYPE g_tab_line_number IS TABLE OF oe_order_lines_all.line_number%TYPE INDEX BY VARCHAR2(100);
    gt_line_number_tbl             g_tab_line_number;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
/* 2009/12/07 Ver1.19 Del Start */
--    -- OM���b�Z�[�W���X�g�̏�����
--    OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 Del End */
    --
    -- �ϐ�������
    ln_msg_count := 0;
    -- ===============================
    -- ���דo�^
    -- ===============================
    <<line_ins_loop>>
    FOR ln_idx IN 1..gt_order_ins_tbl.COUNT LOOP
      SELECT  MAX(oola.line_number) + 1
      INTO    ln_max_number
      FROM    oe_order_lines_all  oola
      WHERE   oola.header_id   = gt_order_ins_tbl(ln_idx).header_id
      GROUP BY oola.header_id;
/* 2009/12/07 Ver1.19 Add Start */
      SELECT msib.inventory_item_id
      INTO   gt_order_ins_tbl(ln_idx).inventory_item_id
      FROM   mtl_system_items_b  msib
      WHERE  msib.segment1          = gt_order_ins_tbl(ln_idx).parent_item_code
      AND    msib.organization_id   = gn_organization_id;
      --
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
/* 2009/12/07 Ver1.19 End Start */
      --
      lt_line_tbl(cn_index)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation              := OE_GLOBALS.G_OPR_CREATE;                        -- �������[�h
      lt_line_tbl(cn_index).header_id              := gt_order_ins_tbl(ln_idx).header_id;             -- �w�b�_ID
      lt_line_tbl(cn_index).ship_to_org_id         := gt_order_ins_tbl(ln_idx).ship_to_org_id;        -- �g�DID
      lt_line_tbl(cn_index).line_number            := ln_max_number;                                  -- ���הԍ�
      lt_line_tbl(cn_index).inventory_item_id      := gt_order_ins_tbl(ln_idx).inventory_item_id;     -- �i��ID
      lt_line_tbl(cn_index).packing_instructions   := gt_order_ins_tbl(ln_idx).order_source;          -- ����w��
      lt_line_tbl(cn_index).line_type_id           := gt_order_ins_tbl(ln_idx).line_type_id;          -- ���׃^�C�v
      lt_line_tbl(cn_index).request_date           := gt_order_ins_tbl(ln_idx).original_request_date; -- �[�i�\���
      lt_line_tbl(cn_index).unit_selling_price     := gt_order_ins_tbl(ln_idx).unit_selling_price;    -- �̔��P��
      lt_line_tbl(cn_index).calculate_price_flag   := cv_calculate_price_flag_n;                      -- ���i�̌v�Z�t���O
      lt_line_tbl(cn_index).schedule_ship_date     := gt_order_ins_tbl(ln_idx).original_schedule_ship_date;  -- �o�ח\���
      lt_line_tbl(cn_index).subinventory           := gt_order_ins_tbl(ln_idx).subinventory;                 -- �ۊǏꏊ
      lt_line_tbl(cn_index).attribute1             := gt_order_ins_tbl(ln_idx).attribute1;
      lt_line_tbl(cn_index).attribute2             := gt_order_ins_tbl(ln_idx).attribute2;
      lt_line_tbl(cn_index).attribute3             := gt_order_ins_tbl(ln_idx).attribute3;
      lt_line_tbl(cn_index).attribute4             := gt_order_ins_tbl(ln_idx).attribute4;
      lt_line_tbl(cn_index).attribute5             := gt_order_ins_tbl(ln_idx).attribute5;
      lt_line_tbl(cn_index).attribute6             := gt_order_ins_tbl(ln_idx).attribute6;
      lt_line_tbl(cn_index).attribute7             := gt_order_ins_tbl(ln_idx).attribute7;
      lt_line_tbl(cn_index).attribute8             := gt_order_ins_tbl(ln_idx).attribute8;
      lt_line_tbl(cn_index).attribute9             := gt_order_ins_tbl(ln_idx).attribute9;
      lt_line_tbl(cn_index).attribute10            := gt_order_ins_tbl(ln_idx).attribute10;
      lt_line_tbl(cn_index).attribute11            := gt_order_ins_tbl(ln_idx).attribute11;
      lt_line_tbl(cn_index).attribute12            := gt_order_ins_tbl(ln_idx).attribute12;
      lt_line_tbl(cn_index).attribute13            := gt_order_ins_tbl(ln_idx).attribute13;
      lt_line_tbl(cn_index).attribute14            := gt_order_ins_tbl(ln_idx).attribute14;
      lt_line_tbl(cn_index).attribute15            := gt_order_ins_tbl(ln_idx).attribute15;
      lt_line_tbl(cn_index).attribute16            := gt_order_ins_tbl(ln_idx).attribute16;
      lt_line_tbl(cn_index).attribute17            := gt_order_ins_tbl(ln_idx).attribute17;
      lt_line_tbl(cn_index).attribute18            := gt_order_ins_tbl(ln_idx).attribute18;
      lt_line_tbl(cn_index).attribute19            := gt_order_ins_tbl(ln_idx).attribute19;
      lt_line_tbl(cn_index).attribute20            := gt_order_ins_tbl(ln_idx).attribute20;
      lt_line_tbl(cn_index).global_attribute1      := gt_order_ins_tbl(ln_idx).global_attribute1;
      lt_line_tbl(cn_index).global_attribute2      := gt_order_ins_tbl(ln_idx).global_attribute2;
      lt_line_tbl(cn_index).global_attribute3      := TO_CHAR(gt_order_ins_tbl(ln_idx).line_id);            -- �������󒍖���ID
      lt_line_tbl(cn_index).global_attribute4      := gt_order_ins_tbl(ln_idx).orig_sys_line_ref;           -- �������󒍖��הԍ�
      lt_line_tbl(cn_index).global_attribute5      := gt_order_ins_tbl(ln_idx).global_attribute5;
      lt_line_tbl(cn_index).global_attribute6      := gt_order_ins_tbl(ln_idx).global_attribute6;
      lt_line_tbl(cn_index).global_attribute7      := gt_order_ins_tbl(ln_idx).global_attribute7;
      lt_line_tbl(cn_index).global_attribute8      := gt_order_ins_tbl(ln_idx).global_attribute8;
      lt_line_tbl(cn_index).global_attribute9      := gt_order_ins_tbl(ln_idx).global_attribute9;
      lt_line_tbl(cn_index).global_attribute10     := gt_order_ins_tbl(ln_idx).global_attribute10;
      lt_line_tbl(cn_index).global_attribute11     := gt_order_ins_tbl(ln_idx).global_attribute11;
      lt_line_tbl(cn_index).global_attribute12     := gt_order_ins_tbl(ln_idx).global_attribute12;
      lt_line_tbl(cn_index).global_attribute13     := gt_order_ins_tbl(ln_idx).global_attribute13;
      lt_line_tbl(cn_index).global_attribute14     := gt_order_ins_tbl(ln_idx).global_attribute14;
      lt_line_tbl(cn_index).global_attribute15     := gt_order_ins_tbl(ln_idx).global_attribute15;
      lt_line_tbl(cn_index).global_attribute16     := gt_order_ins_tbl(ln_idx).global_attribute16;
      lt_line_tbl(cn_index).global_attribute17     := gt_order_ins_tbl(ln_idx).global_attribute17;
      lt_line_tbl(cn_index).global_attribute18     := gt_order_ins_tbl(ln_idx).global_attribute18;
      lt_line_tbl(cn_index).global_attribute19     := gt_order_ins_tbl(ln_idx).global_attribute19;
      lt_line_tbl(cn_index).global_attribute20     := gt_order_ins_tbl(ln_idx).global_attribute20;
      lt_line_tbl(cn_index).org_id                 := gt_org_id;                                         -- �c�ƒP��
      lt_line_tbl(cn_index).request_id             := cn_request_id;                                     -- �v��ID
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;                         -- �ݶ��ĥ��۸��ѥ���ع����ID
      lt_line_tbl(cn_index).program_id             := cn_program_id;                                     -- �ݶ��ĥ��۸���ID
      lt_line_tbl(cn_index).program_update_date    := cd_program_update_date;                            -- �v���O�����X�V��
/* 2009/12/07 Ver1.19 Add Start */
      lt_line_tbl(cn_index).context                := gt_order_ins_tbl(ln_idx).line_context;
/* 2009/12/07 Ver1.19 Add Start */
      --
      -- ���ʂ̐ݒ�
      IF ( gt_order_ins_tbl(ln_idx).order_quantity_uom = gt_order_ins_tbl(ln_idx).conv_order_quantity_uom ) THEN
        -- �󒍉�ʂ̓��͒P�ʂ���P�ʂ̏ꍇ
        lt_line_tbl(cn_index).ordered_quantity := gt_order_ins_tbl(ln_idx).checked_quantity;
        lt_line_tbl(cn_index).order_quantity_uom := gt_order_ins_tbl(ln_idx).order_quantity_uom;
      ELSE
        -- �󒍉�ʂ̓��͒P�ʂ�CS�̏ꍇ
        lt_line_tbl(cn_index).ordered_quantity := gt_order_ins_tbl(ln_idx).checked_quantity / gt_order_ins_tbl(ln_idx).qty_case;
        lt_line_tbl(cn_index).order_quantity_uom := gt_order_ins_tbl(ln_idx).order_quantity_uom;
      END IF;
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
      SELECT  MAX(oola.line_number)
      INTO    ln_after_max_number
      FROM    oe_order_lines_all  oola
      WHERE   oola.header_id   = gt_order_ins_tbl(ln_idx).header_id
      GROUP BY oola.header_id;
      --
      -- API���s���ʊm�F
      IF (( lv_return_status <> FND_API.G_RET_STS_SUCCESS )
            OR ( ln_after_max_number <> ln_max_number )) THEN
        -- ���דo�^�G���[
        IF ln_msg_count > 0 THEN
          FOR l_index IN 1..ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(p_msg_index => l_index, p_encoded =>'F');
          END LOOP;
          lv_errbuf := substrb( lv_msg_data,1,250);
        END IF;
        -- ���b�Z�[�W������擾(�󒍔ԍ�)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_order_number             -- ���b�Z�[�WID
        );
        -- ���b�Z�[�W������擾(�i��)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_item_name                -- ���b�Z�[�WID
        );
        -- ���b�Z�[�W������擾(����)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_msg_quantity                 -- ���b�Z�[�WID
        );
        -- ���b�Z�[�W������擾(�󒍖���)
        lv_table_name := xxccp_common_pkg.get_msg(
               iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
              ,iv_name        => cv_msg_line_number              -- ���b�Z�[�WID
        );
        --�L�[���̕ҏW����
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- �󒍔ԍ�
         ,iv_data_value1    => gt_order_ins_tbl(ln_idx).order_number
         ,iv_item_name2     => lv_item_name                     -- �i��
         ,iv_data_value2    => gt_order_ins_tbl(ln_idx).item_code
         ,iv_item_name3     => lv_quantity                      -- ����
         ,iv_data_value3    => TO_CHAR(lt_line_tbl(ln_cnt).ordered_quantity)
         ,ov_key_info       => lv_key_info                      -- �ҏW��L�[���
         ,ov_errbuf         => lv_errbuf                        -- �G���[�E���b�Z�[�W
         ,ov_retcode        => lv_retcode                       -- ���^�[���R�[�h
         ,ov_errmsg         => lv_errmsg                        -- ���[�U�E�G���[�E���b�Z�[�W
        );
        -- ���b�Z�[�W������쐬
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name     -- �A�v���P�[�V�����Z�k��
          ,iv_name         => cv_line_insert_err      -- ���b�Z�[�W
          ,iv_token_name1  => cv_tkn_table_name       -- �e�[�u����
          ,iv_token_value1 => lv_table_name
          ,iv_token_name2  => cv_tkn_key_data         -- �L�[���
          ,iv_token_value2 => lv_key_info
        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- ��s�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        RAISE global_api_expt;
      END IF;
      --
      --
    END LOOP line_ins_loop;
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
  END order_line_insert;
--
  /**********************************************************************************
   * Procedure Name   : get_delivery
   * Description      : �z����擾(A-17)
   ***********************************************************************************/
  PROCEDURE get_delivery(
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery'; -- �v���O������
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
    cv_site_ship                   CONSTANT VARCHAR2(10) := 'SHIP_TO';                    -- �g�p�ړI:�o�א�
    cv_status_effective            CONSTANT VARCHAR2(1)  := 'A';                          -- �X�e�C�^�X:�L��
    cv_tkn_order_no                CONSTANT VARCHAR2(30) := 'ORDER_NO';                   -- �󒍔ԍ�
    cv_tkn_account_number          CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';             -- �ڋq�R�[�h
    cv_tkn_rsv_sale_base_code      CONSTANT VARCHAR2(30) := 'RSV_SALE_BASE_CODE';         -- �\�񔄏㋒�_
    cv_tkn_delivery_base_code      CONSTANT VARCHAR2(30) := 'DELIVERY_BASE_CODE';         -- �[�i���_
    cv_tkn_rsv_sale_base_act_date  CONSTANT VARCHAR2(30) := 'RSV_SALE_BASE_ACT_DATE';     -- �\�񔄏㋒�_�K�p�J�n��
    cv_tkn_base_code               CONSTANT VARCHAR2(20) := 'BASE_CODE';                  -- ���_
    cv_tkn_request_date            CONSTANT VARCHAR2(20) := 'REQUEST_DATE';               -- �[�i�\���
    lv_output_msg                  VARCHAR2(1000);                                        -- �o�̓��b�Z�[�W�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<delivery_loop>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
--
-- ******************* 2009/11/24 1.16 N.Maeda MOD START ******************* --
      -- ===============================
      -- �o�׎w���̉��s�R�[�h�폜
      -- ===============================
      gt_order_extra_tbl(ln_idx).shipping_instructions := TRANSLATE( gt_order_extra_tbl(ln_idx).shipping_instructions
                                                                     ,CHR(10)
                                                                     ,' '
                                                                   );
-- ******************* 2009/11/24 1.16 N.Maeda MOD  END  ******************* --
      -- ===============================
      -- �Ώۋ��_�R�[�h�擾
      -- ===============================
      IF (    gt_order_extra_tbl(ln_idx).rsv_sale_base_code IS NULL        -- �\�񔄏㋒�_�R�[�h
           OR gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date IS NULL    -- �\�񔄏㋒�_�L���J�n��
           OR gt_order_extra_tbl(ln_idx).request_date < gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date ) THEN
        -- �[�i���_�̏ꍇ
/* 2009/10/19 Ver.1.13 Mod Start */
        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).sale_base_code;
--        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).delivery_base_code;
/* 2009/10/19 Ver.1.13 Mod End */
        --
      ELSIF ( gt_order_extra_tbl(ln_idx).request_date >= gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date ) THEN
        -- �\�񔄏㋒�_�̏ꍇ
        gt_order_extra_tbl(ln_idx).base_code := gt_order_extra_tbl(ln_idx).rsv_sale_base_code;
        --
      ELSE
        -- ���_�擾�G���[
        -- ���b�Z�[�W�쐬
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name                  -- �A�v���P�[�V�����Z�k��
          ,iv_name         => cv_base_code_err                     -- ���b�Z�[�W
          ,iv_token_name1  => cv_tkn_order_no                      -- �󒍔ԍ�
          ,iv_token_value1 => gt_order_extra_tbl(ln_idx).order_number
          ,iv_token_name2  => cv_tkn_account_number                -- �ڋq�R�[�h
          ,iv_token_value2 => gt_order_extra_tbl(ln_idx).account_number
          ,iv_token_name3  => cv_tkn_rsv_sale_base_code            -- �\�񔄏㋒�_
          ,iv_token_value3 => gt_order_extra_tbl(ln_idx).rsv_sale_base_code
          ,iv_token_name4  => cv_tkn_delivery_base_code            -- �[�i���_
          ,iv_token_value4 => gt_order_extra_tbl(ln_idx).base_code
          ,iv_token_name5  => cv_tkn_rsv_sale_base_act_date        -- �\�񔄏㋒�_�K�p�J�n��
          ,iv_token_value5 => TO_CHAR(gt_order_extra_tbl(ln_idx).rsv_sale_base_act_date, cv_date_fmt_date_time)
        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- ��s�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ===============================
      -- �z����R�[�h�擾
      -- ===============================
      BEGIN
        SELECT  hl.province                          -- �z����R�[�h
        INTO    gt_order_extra_tbl(ln_idx).province
        FROM   hz_cust_accounts         hca          -- �ڋq�}�X�^
               ,hz_party_sites          hps          -- �p�[�e�B�T�C�g�}�X�^
               ,hz_cust_acct_sites_all  hcasa        -- �ڋq���ݒn
               ,hz_locations            hl           -- �ڋq���Ə��}�X�^
               ,hz_cust_site_uses_all   hcsua        -- �ڋq�g�p�ړI
               ,xxcmn_party_sites       xps          -- �p�[�e�B�T�C�g�A�h�I���}�X�^
        WHERE  hca.account_number       =  gt_order_extra_tbl(ln_idx).account_number
        AND    hca.cust_account_id      =  hcasa.cust_account_id
        AND    hcasa.cust_acct_site_id  =  hcsua.cust_acct_site_id
        AND    hcsua.org_id             =  gn_prod_ou_id
        AND    hcasa.status             =  cv_status_effective
        AND    hcsua.org_id             =  gn_prod_ou_id
        AND    hcsua.site_use_code      =  cv_site_ship
        AND    hcasa.party_site_id      =  hps.party_site_id
        AND    hps.status               =  cv_status_effective
        AND    hps.location_id        =  hl.location_id
        AND    hps.party_id             =  xps.party_id
        AND    hps.party_site_id        =  xps.party_site_id
        AND    hps.location_id          =  xps.location_id
        AND    xps.base_code            =  gt_order_extra_tbl(ln_idx).base_code
        AND    xps.start_date_active    <= gt_order_extra_tbl(ln_idx).request_date
        AND    xps.end_date_active      >= gt_order_extra_tbl(ln_idx).request_date;
      EXCEPTION
        WHEN OTHERS THEN
          -- �z����擾�G���[
        -- ���b�Z�[�W�쐬
        lv_output_msg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name            -- �A�v���P�[�V�����Z�k��
          ,iv_name         => cv_delivery_code_err           -- ���b�Z�[�W
          ,iv_token_name1  => cv_tkn_order_no                -- �󒍔ԍ�
          ,iv_token_value1 => gt_order_extra_tbl(ln_idx).order_number
          ,iv_token_name2  => cv_tkn_account_number          -- �ڋq�R�[�h
          ,iv_token_value2 => gt_order_extra_tbl(ln_idx).account_number
          ,iv_token_name3  => cv_tkn_base_code               -- ���_
          ,iv_token_value3 => gt_order_extra_tbl(ln_idx).base_code
          ,iv_token_name4  => cv_tkn_request_date            -- �[�i�\���
          ,iv_token_value4 => TO_CHAR(gt_order_extra_tbl(ln_idx).request_date, cv_date_fmt_date_time)
        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_msg
        );
        -- ��s�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        --
        ov_retcode := cv_status_warn;
        --
      END;
    END LOOP delivery_loop;
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
  END get_delivery;
--
/* 2009/09/16 Ver.1.12 Add End */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN  VARCHAR2,     -- 1.���_�R�[�h
--    iv_order_number  IN  VARCHAR2,     -- 2.�󒍔ԍ�
    iv_send_flg      IN  VARCHAR2,         -- 1.�V�K/�đ��敪
    iv_base_code     IN  VARCHAR2,         -- 2.���_�R�[�h
    iv_order_number  IN  VARCHAR2,         -- 3.�󒍔ԍ�
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
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
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    lv_retcode_a12          VARCHAR2(1);    -- A-12�̃��^�[���R�[�h�i�[
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
    -- *** ���[�J����O ***
    no_data_found_expt      EXCEPTION;      -- ���o�f�[�^����
/* 2009/09/16 Ver.1.12 Add Start */
    process_warn_expt         EXCEPTION;
/* 2009/09/16 Ver.1.12 Add End */
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
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code     => iv_base_code        -- ���_�R�[�h
--      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
       iv_send_flg      => iv_send_flg         -- �V�K/�đ��敪
      ,iv_base_code     => iv_base_code        -- ���_�R�[�h
      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
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
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code     => iv_base_code        -- ���_�R�[�h
--      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
       iv_send_flg      => iv_send_flg         -- �V�K/�đ��敪
      ,iv_base_code     => iv_base_code        -- ���_�R�[�h
      ,iv_order_number  => iv_order_number     -- �󒍔ԍ�
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END ******************************--
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
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    lv_retcode_a12 := cv_status_normal;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
    --
/* 2009/09/16 Ver.1.12 Add Start */
    -- ===============================
    -- �z����擾(A-17)
    -- ===============================
    get_delivery(
       ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W
      ,ov_retcode     => lv_retcode            -- ���^�[���E�R�[�h
      ,ov_errmsg      => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE process_warn_expt;
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
    <<make_ship_data>>
    FOR ln_idx IN gt_order_extra_tbl.FIRST..gt_order_extra_tbl.LAST LOOP
/* 2009/09/16 Ver.1.12 Add Start */
      -- ������
      lv_retcode_a3 := NULL;
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
        lv_retcode_a5 := cv_status_warn;
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
        ,in_index      => ln_idx                                     -- �C���f�b�N�X
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    IF ( cv_status_warn IN ( lv_retcode_a3, lv_retcode_a5 )) THEN
      RAISE process_warn_expt;
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE process_warn_expt;
/* 2009/09/16 Ver.1.12 Add End */
    END IF;
    --
/* 2009/09/16 Ver.1.12 Add Start */
    IF ( gt_normal_order_tbl.COUNT > 0 ) THEN
      -- ===============================
      -- �ύڌ����œK���`�F�b�N(A-14)
      -- ===============================
      weight_check(
         ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W
        ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h
        ,ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���^�[���R�[�h�`�F�b�N
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        RAISE process_warn_expt;
      END IF;
      --
      -- ===============================
      -- �󒍖��׃f�[�^��������(A-15)
      -- ===============================
      order_line_division(
         ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W
        ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h
        ,ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���^�[���R�[�h�`�F�b�N
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        RAISE process_warn_expt;
      END IF;
      --
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
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
      --
/* 2009/09/16 Ver.1.12 Add Start */
      -- ====================================================
      -- �o�׈˗�I/F�w�b�_�f�[�^�쐬(A-16)
      -- ====================================================
      order_line_insert(
         ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
/* 2009/09/16 Ver.1.12 Add End */
    END IF;
--
--****************************** 2009/05/15 1.6 S.Tomita ADD START ******************************--
    -- �o�׈˗�I/F�o�^�f�[�^������ꍇ
    IF ( ( gn_header_normal_cnt > 0 ) OR ( gn_line_normal_cnt > 0 ) ) THEN
--
      -- ===============================
      -- ���Y�V�X�e���N��(A-12)
      -- ===============================
      start_production_system(
         iv_base_code       => iv_base_code        -- ���_�R�[�h
        ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
        ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
        ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a12 := cv_status_warn;
      END IF;
    END IF;
--****************************** 2009/05/15 1.6 S.Tomita ADD END   ******************************--
--
--****************************** 2009/05/15 1.6 S.Tomita MOD START ******************************--
    -- submain�̃��^�[���R�[�h����
--    IF ( cv_status_warn IN ( lv_retcode_a3
--                            ,lv_retcode_a5 ) )
--    THEN
--      ov_retcode := cv_status_warn;
--    END IF;
    IF ( cv_status_warn IN ( lv_retcode_a3
                            ,lv_retcode_a5
                            ,lv_retcode_a12 ) )
    THEN
      ov_retcode := cv_status_warn;
    END IF;
--****************************** 2009/05/15 1.6 S.Tomita MOD END   ******************************--
--
  EXCEPTION
/* 2009/09/16 Ver.1.12 Add Start */
    WHEN process_warn_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_retcode := cv_status_warn;
/* 2009/09/16 Ver.1.12 Add End */
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
--****************************** 2009/05/26 1.7 T.Kitajima MOD START ******************************--
--    iv_base_code     IN     VARCHAR2,         -- 1.���_�R�[�h
--    iv_order_number  IN     VARCHAR2          -- 2.�󒍔ԍ�
    iv_send_flg      IN     VARCHAR2,         -- 1.�V�K/�đ��敪
    iv_base_code     IN     VARCHAR2,         -- 2.���_�R�[�h
    iv_order_number  IN     VARCHAR2          -- 3.�󒍔ԍ�
--****************************** 2009/05/26 1.7 T.Kitajima MOD  END  ******************************--
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
--****************************** 2009/05/15 1.7 T.Kitajima MOD START ******************************--
--       iv_base_code       -- ���_�R�[�h
--      ,iv_order_number    -- �󒍔ԍ�
       iv_send_flg        -- �V�K/�đ��敪
      ,iv_base_code       -- ���_�R�[�h
      ,iv_order_number    -- �󒍔ԍ�
--****************************** 2009/05/15 1.7 T.Kitajima MOD  END  ******************************--
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
/* 2009/09/16 Ver.1.12 Mod Start */
                    ,iv_name         => cv_error_rec_msg
--                    ,iv_name         => cv_skip_rec_msg
/* 2009/09/16 Ver.1.12 Mod End */
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
/* 2009/09/16 Ver.1.12 Add Start */
      IF ( gn_warn_cnt > 0 ) THEN
        -- �G���[�f�[�^������ꍇ
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name
                        ,iv_name         => cv_msg_warn_end
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      ELSE
/* 2009/09/16 Ver.1.12 Add End */
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
/* 2009/09/16 Ver.1.12 Add Start */
    END IF;
/* 2009/09/16 Ver.1.12 Add End */
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
