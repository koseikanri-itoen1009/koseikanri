CREATE OR REPLACE PACKAGE BODY XXCOS008A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A02C (body)
 * Description      : ���Y�����V�X�e���̍H�꒼���o�׎��уf�[�^����̔����т��쐬���A
 *                    �̔����т��쐬�����n�l�󒍂��N���[�Y���܂��B
 * MD.050           : �o�׊m�F�i���Y�����o�ׁj  MD050_COS_008_A02
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   (A-1)  ��������
 *  set_profile            (A-2)  �v���t�@�C���l�擾
 *  get_order_data         (A-3)  �󒍃f�[�^�擾
 *  get_fiscal_period_from (A-4-1)�L����v����FROM�擾�֐�
 *  edit_item              (A-4)  ���ڕҏW
 *  check_data_row         (A-5)  �f�[�^�`�F�b�N
 *  check_summary_quantity (A-6)  ����ʃT�}���[�`�F�b�N
 *  check_sales_exp_data   (A-7)  �̔����ђP�ʃf�[�^�`�F�b�N
 *  set_plsql_table        (A-8)  �̔�����PL/SQL�\�쐬
 *  make_sales_exp_lines   (A-9)  �̔����і��׍쐬
 *  make_sales_exp_headers (A-10)  �̔����уw�b�_�쐬
 *  set_order_line_close_status (A-11)�󒍖��׃N���[�Y�ݒ�
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   K.Nakamura       �V�K�쐬
 *  2008/02/18    1.1   K.Nakamura       get_msg�̃p�b�P�[�W���C��
 *  2008/02/18    1.2   K.Nakamura       [COS_098] �w�b�_�̍쐬�P�ʂɏo�׈˗�No��ǉ�
 *  2008/02/18    1.3   K.Nakamura       [COS_099] �c�ƌ����̎擾���鏈�����C��
 *  2008/02/20    1.4   K.Nakamura       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2008/02/26    1.5   K.Nakamura       [COS_144] �󒍃f�[�^�擾���ɁA�[�i�\����ƌ����\����̎����b���폜
 *  2009/04/14    1.6   T.Kitajima       [T1_0534]�[�i�`�[�敪����}�X�^��DFF�ύX
 *  2009/05/20    1.7   K.Kiriu          [T1_1067] �w�b�_�̏���Ŋz�̒[��������ǉ�
 *                                       [T1_1121] �{�̋��z�A����Ŋz�v�Z���@�̏C��
 *                                       [T1_1122] �[�������敪���؏㎞�̌v�Z�̏C��
 *                                       [T1_1171] �󒍐��ʂ̕ԕi�̍l���R��̏C��
 *                                       [T1_1206] �w�b�_�P�ʂň�ԑ傫���{�̋��z�̏������Βl�ɏC��
 *  2009/06/01    1.8   N.Maeda          [T1_1269] ����ŋ敪3(����(�P������)):�Ŕ���P���Z�o���@�C��
 *  2009/06/09    1.9   K.Kiriu          [T1_1368] ����ŋ��z���v��DB���x�Ή�
 *  2009/07/08    1.10  K.Kiriu          [0000484] �i�ڕs��v��Q�Ή�
 *  2009/07/09    1.11  K.Kiriu          [0000063] ���敪�̉ۑ�Ή�
 *                                       [0000064] �󒍃w�b�_DFF���ژR��Ή�
 *                                       [0000435] PT�Ή�
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
  -- ���[�U�[��`��O
  -- ===============================
  --*** �Ɩ����t�擾��O�n���h�� ***
  global_proc_date_err_expt     EXCEPTION;
  --*** ���t�����擾��O�n���h�� ***
  global_format_date_err_expt   EXCEPTION;
  --*** �v���t�@�C���擾��O�n���h�� ***
  global_get_profile_expt       EXCEPTION;
  --*** ���b�N�G���[��O�n���h�� ***
  global_lock_err_expt          EXCEPTION;
  --*** �Ώۃf�[�^�����G���[��O�n���h�� ***
  global_no_data_warm_expt      EXCEPTION;
  --*** �f�[�^�o�^�G���[��O�n���h�� ***
  global_insert_data_expt       EXCEPTION;
  --*** �f�[�^�擾�G���[��O�n���h�� ***
  global_select_data_expt       EXCEPTION;
  --*** ��v���Ԏ擾�G���[��O�n���h�� ***
  global_fiscal_period_err_expt EXCEPTION;
  --*** ����ʎ擾�G���[��O�n���h�� ***
  global_base_quantity_err_expt EXCEPTION;
  --*** �[�i�`�ԋ敪�擾�G���[��O�n���h�� ***
  global_delivered_from_err_expt EXCEPTION;
  --*** API�Ăяo���G���[��O�n���h�� ***
  global_api_err_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_line_feed              CONSTANT  VARCHAR2(1) := CHR(10);    --���s�R�[�h
--
  cv_pkg_name               CONSTANT  VARCHAR2(100)
                                       := 'XXCOS008A02C';        -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  cv_xxcos_appl_short_nm    CONSTANT  fnd_application.application_short_name%TYPE
                                       :=  'XXCOS';              -- �̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_rowtable_lock_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00001';   -- ���b�N�G���[
  ct_msg_date_format_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00002';   -- ���t�����G���[
  ct_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00003';   -- �Ώۃf�[�^�����G���[
  ct_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00004';   -- �v���t�@�C���擾�G���[
  ct_msg_insert_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00010';   -- �f�[�^�o�^�G���[
  ct_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00013';   -- �f�[�^�擾�G���[
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00014';   -- �Ɩ����t�擾�G���[
  ct_msg_api_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00031';   -- API�ďo�G���[���b�Z�[�W
  ct_msg_null_column_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11651';   -- �K�{���ږ����̓G���[
  ct_msg_item_unmatch_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11652';   -- �i�ڕs��v�G���[
  ct_msg_reverse_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11653';   -- �����\����t�]�G���[���b�Z�[�W      
  ct_msg_fiscal_period_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11654';   -- ��v���Ԏ擾�G���[
  ct_msg_base_quantity_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11655';   -- ����ʎ擾�G���[
  cv_msg_parameter_note     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11656';   -- �p�����[�^�o�̓��b�Z�[�W
  ct_msg_delivered_from_err CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11657';   -- �[�i�`�ԋ敪�擾�G���[���b�Z�[�W
  ct_msg_hdr_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11658';   -- �w�b�_��������
  ct_msg_lin_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11659';   -- ���א�������
  ct_msg_select_odr_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11660';   -- �f�[�^�擾�G���[
  ct_msg_quantity_sum_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11680';   -- ����ʕs��v�G���[
  ct_msg_dlv_date_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11681';   -- �[�i���s��v�G���[
/* 2009/07/09 Ver1.11 Add Strat */
  ct_msg_close_note         CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11683';   -- �󒍖��׃N���[�Y����
/* 2009/07/09 Ver1.11 Add End   */
--
  --�g�[�N��
  cv_tkn_para_date          CONSTANT  VARCHAR2(100)  :=  'PARA_DATE';      -- �������t
  cv_tkn_profile            CONSTANT  VARCHAR2(100)  :=  'PROFILE';        -- �v���t�@�C����
  cv_tkn_table              CONSTANT  VARCHAR2(100)  :=  'TABLE';          -- �e�[�u������
  cv_tkn_order_number       CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- �󒍔ԍ�
  cv_tkn_line_number        CONSTANT  VARCHAR2(100)  :=  'LINE_NUMBER';    -- �󒍖��הԍ�
  cv_tkn_field_name         CONSTANT  VARCHAR2(100)  :=  'FIELD_NAME';     -- �t�B�[���h��
  cv_tkn_account_name       CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- ��v���Ԏ��
  cv_tkn_base_date          CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- ���
  cv_tkn_item_code          CONSTANT  VARCHAR2(100)  :=  'ITEM_CODE';      -- �i�ڃR�[�h
  cv_tkn_before_code        CONSTANT  VARCHAR2(100)  :=  'BEFORE_CODE';    -- ���Z�O�P�ʃR�[�h
  cv_tkn_before_value       CONSTANT  VARCHAR2(100)  :=  'BEFORE_VALUE';   -- ���Z�O����
  cv_tkn_after_code         CONSTANT  VARCHAR2(100)  :=  'AFTER_CODE';     -- ���Z��P�ʃR�[�h
  cv_tkn_key_data           CONSTANT  VARCHAR2(100)  :=  'KEY_DATA';       -- �L�[���
  cv_tkn_table_name         CONSTANT  VARCHAR2(100)  :=  'TABLE_NAME';     -- �e�[�u������
  cv_tkn_api_name           CONSTANT  VARCHAR2(100)  :=  'API_NAME';       -- API����
  cv_tkn_err_msg            CONSTANT  VARCHAR2(100)  :=  'ERR_MSG';        -- �G���[���b�Z�[�W
  cv_tkn_req_no             CONSTANT  VARCHAR2(100)  :=  'REQ_NO';         -- �˗�No
  cv_tkn_target_date        CONSTANT  VARCHAR2(100)  :=  'TARGET_DATE';    -- ���t���ږ�
  cv_tkn_kdate              CONSTANT  VARCHAR2(100)  :=  'KDATE';          -- �Ώۓ�
  cv_tkn_sdate              CONSTANT  VARCHAR2(100)  :=  'SDATE';          -- �o�׎��ѓ�
--
  --���b�Z�[�W�p������
  cv_str_profile_nm                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00047';  -- MO:�c�ƒP��
  cv_str_max_date_nm               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00056';  -- XXCOS:MAX���t
  cv_str_gl_id_nm                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00060';  -- GL��v����ID
  cv_lock_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11661';  -- �󒍃w�b�_�^�󒍖���
  cv_dlv_invoice_number            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11662';  -- �[�i�`�[�ԍ�
  cv_dlv_invoice_class             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11663';  -- �[�i�`�[�敪
  cv_tax_code                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11664';  -- �ŋ��R�[�h
  cv_sale_base_code                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11665';  -- ���㋒�_�R�[�h
  cv_receiv_base_code              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11666';  -- �������_�R�[�h
  cv_sales_class                   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11667';  -- ����敪
  cv_red_black_flag                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11668';  -- �ԍ��t���O
  cv_delivery_base_code            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11669';  -- �[�i���_�R�[�h
  cv_ship_from_subinventory_code   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11670';  -- �ۊǏꏊ�R�[�h  
  cv_sales_exp_header_table        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11671';  -- �̔����уw�b�_
  cv_sales_exp_line_table          CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11672';  -- �̔����і���
  cv_item_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11673';  -- OPM�i�ڃ}�X�^
  cv_person_table                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11674';  -- �]�ƈ��}�X�^
  cv_api_name                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11675';  -- �󒍃N���[�YAPI
  cv_add_status                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11676';  -- �󒍃w�b�_�A�h�I���X�e�[�^�X
  cv_dlv_date                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11677';  -- �[�i�\���
  cv_inspect_date                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11678';  -- �����\���
  cv_hokan                         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11679';  -- �ۊǏꏊ����
  cv_tax_class                     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11682';  -- ����ŋ敪
--
  --�v���t�@�C������
  --MO:�c�ƒP��
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
--
  --XXCOS:MAX���t
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';
--
  -- GL��v����ID
  cv_prf_bks_id                 CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
--
  --�N�C�b�N�R�[�h�^�C�v
  -- �o�׊m�F�i���Y�����o�ׁj���o�Ώۏ���
  ct_qct_sale_exp_condition     CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_EXP_CONDITION';
  -- ����敪
  ct_qct_sales_class_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_CLASS_MST';
  -- �ԍ��敪
  ct_qct_red_black_flag_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_RED_BLACK_FLAG';
  -- �ŃR�[�h
  ct_qct_tax_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';
  -- �[�i�`�[�敪
  ct_qct_dlv_slp_cls_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST';
  -- ��݌ɕi��
  ct_qct_no_inv_item_code_type  CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_NO_INV_ITEM_CODE';
  -- �󒍃w�b�_�A�h�I���X�e�[�^�X
  ct_qct_odr_hdr_add_sts_type   CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_ODR_ADN_STS_MST_008_A02';
  -- �ۊǏꏊ���ށi�����j       
  ct_qct_hokan_type             CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_HOKAN_DIRECT_TYPE_MST';
  -- ����ŋ敪������       
  ct_qct_tax_class_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPT_TAX_CLS_MST';
--
  --�N�C�b�N�R�[�h
  -- �o�׊m�F�i���Y�����o�ׁj���o�Ώۏ���
  ct_qcc_sale_exp_condition     CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS_008_A02%';
  -- �ԍ��敪
  ct_qcc_red_black_flag_type    CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  '1';
  -- �[�i�`�[�敪
  ct_qcc_dlv_slp_cls_type       CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST%';  
--
  --�g�p�\�t���O�萔
  ct_yes_flg                    CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y'; --�L��
  ct_no_flg                     CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'N'; --����
--
  --�󒍃w�b�_�J�e�S��
  ct_order_category             CONSTANT  oe_order_headers_all.order_category_code%TYPE := 'RETURN';  --�ԕi
--
  --�󒍃w�b�_�X�e�[�^�X
  ct_hdr_status_booked          CONSTANT  oe_order_headers_all.flow_status_code%TYPE := 'BOOKED';   --�L����
  ct_hdr_status_closed          CONSTANT  oe_order_headers_all.flow_status_code%TYPE := 'CLOSED';   --�۰��
--
  --�󒍖��׃X�e�[�^�X
  ct_ln_status_closed           CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --�N���[�Y
  ct_ln_status_cancelled        CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --���
--
  --�p�����[�^���t�w�菑��
  ct_target_date_format         CONSTANT  VARCHAR2(10) := 'yyyy/mm/dd';
--
  --���t�����i�N���j
  cv_fmt_date_default           CONSTANT  VARCHAR2(21)  := 'YYYY-MM-DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'RRRR/MM/DD';
--
  --�f�[�^�`�F�b�N�X�e�[�^�X�l
  cn_check_status_normal        CONSTANT  NUMBER := 0;  -- ����
  cn_check_status_error         CONSTANT  NUMBER := -1; -- �G���[
--
  --AR��v���ԋ敪�l
  cv_fiscal_period_ar           CONSTANT  VARCHAR2(2) := '02';  --AR
--
  --�󒍖��׃N���[�Y�p������
  cv_close_type                 CONSTANT  VARCHAR2(5) := 'OEOL';
  cv_activity                   CONSTANT  VARCHAR2(27):= 'XXCOS_R_STANDARD_LINE:BLOCK';
  cv_result                     CONSTANT  VARCHAR2(1) := NULL;
--
  --�쐬���敪
  cv_business_cost              CONSTANT  VARCHAR2(1) := '7'; -- �o�׊m�F�i���Y�����o�ׁj
--
  cv_amount_up                  CONSTANT  VARCHAR(5)  := 'UP';      -- �����_�[��(�؏�)
  cv_amount_down                CONSTANT  VARCHAR(5)  := 'DOWN';    -- �����_�[��(�؎̂�)
  cv_amount_nearest             CONSTANT  VARCHAR(10) := 'NEAREST'; -- �����_�[��(�l�̌ܓ�)
/* 2009/07/09 Ver1.11 Add Start */
  --���敪
  cv_target_order_01            CONSTANT  VARCHAR2(2) := '01';      -- �󒍍쐬�Ώ�01
  cv_target_order_02            CONSTANT  VARCHAR2(2) := '02';      -- �󒍍쐬�Ώ�02
  --LANGUAGE
  cv_lang                       CONSTANT  VARCHAR2(256) := USERENV( 'LANG' );
/* 2009/07/09 Ver1.11 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_normal_header_cnt    NUMBER;   -- ���팏��(�w�b�_)
  gn_normal_line_cnt      NUMBER;   -- ���팏��(����)
/* 2009/07/09 Ver1.11 Add Start */
  gn_line_close_cnt       NUMBER;   -- �󒍖��׃N���[�Y����
/* 2009/07/09 Ver1.11 Add End   */
  -- �o�^�Ɩ����t
  gd_business_date        DATE;
  -- �Ɩ����t
  gd_process_date         DATE;
  -- �c�ƒP��
  gn_org_id               NUMBER;
  -- MAX���t
  gd_max_date             DATE;
  -- GL��v����ID
  gn_gl_id                NUMBER;
  -- �ԍ��敪(��)
  gv_black_flag           VARCHAR2(1);
  -- �󒍃w�b�_�A�h�I���X�e�[�^�X
  gv_add_status_sum_up    fnd_lookup_values.attribute1%TYPE;  -- �o�׎��ьv���
  -- �ۊǏꏊ���ށi�����j
  gv_direct_ship_code     fnd_lookup_values.meaning%TYPE;
/* 2009/07/09 Ver1.11 Add Start */
  gn_seq_1                PLS_INTEGER;  --�̔����э쐬�p�ϐ��̓Y���ێ��p
  gn_seq_2                PLS_INTEGER;  --�󒍃N���[�Y�p�ϐ��̓Y���ێ��p
/* 2009/07/09 Ver1.11 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  --�󒍃f�[�^���R�[�h�^
  TYPE order_data_rtype IS RECORD(
    header_id                     oe_order_headers_all.header_id%TYPE               -- �󒍃w�b�_ID
    , line_id                     oe_order_lines_all.line_id%TYPE                   -- �󒍖���ID
    , order_type                  oe_transaction_types_tl.name%TYPE                 -- �󒍃^�C�v
    , line_type                   oe_transaction_types_tl.name%TYPE                 -- ���׃^�C�v
    , salesrep_id                 oe_order_headers_all.salesrep_id%TYPE             -- �c�ƒS��
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%TYPE   -- �[�i�`�[�ԍ�
    , order_invoice_number        xxcos_sales_exp_headers.order_invoice_number%TYPE -- �����`�[�ԍ�
    , order_number                xxcos_sales_exp_headers.order_number%TYPE         -- �󒍔ԍ�
    , line_number                 oe_order_lines_all.line_number%TYPE               -- �󒍖��הԍ�
    , order_no_hht                xxcos_sales_exp_headers.order_no_hht%TYPE         -- ��No�iHHT)
    , order_no_hht_seq            xxcos_sales_exp_headers.digestion_ln_number%TYPE  -- ��No�iHHT�j�}��
    , dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE    -- �[�i�`�[�敪
    , cancel_correct_class        xxcos_sales_exp_headers.cancel_correct_class%TYPE -- ��������敪
    , input_class                 xxcos_sales_exp_headers.input_class%TYPE          -- ���͋敪
    , cust_gyotai_sho             xxcos_sales_exp_headers.cust_gyotai_sho%TYPE      -- �Ƒԁi�����ށj
    , dlv_date                    xxcos_sales_exp_headers.delivery_date%TYPE        -- �[�i��
    , org_dlv_date                xxcos_sales_exp_headers.orig_delivery_date%TYPE   -- �I���W�i���[�i��
    , inspect_date                xxcos_sales_exp_headers.inspect_date%TYPE         -- ������
    , orig_inspect_date           xxcos_sales_exp_headers.orig_inspect_date%TYPE    -- �I���W�i��������
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE-- �ڋq�y�[�i��z
    , consumption_tax_class       xxcos_sales_exp_headers.consumption_tax_class%TYPE-- ����ŋ敪
    , tax_code                    xxcos_sales_exp_headers.tax_code%TYPE             -- �ŋ��R�[�h
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%TYPE             -- ����ŗ�
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%TYPE-- ���ьv��҃R�[�h
    , sale_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE      -- ���㋒�_�R�[�h
    , last_month_sale_base_code   xxcos_sales_exp_headers.sales_base_code%TYPE      -- �O�����㋒�_�R�[�h
    , rsv_sale_base_act_date      xxcmm_cust_accounts.rsv_sale_base_act_date%TYPE   -- �\�񔄏㋒�_�L���J�n��
    , receiv_base_code            xxcos_sales_exp_headers.receiv_base_code%TYPE     -- �������_�R�[�h
    , order_source_id             xxcos_sales_exp_headers.order_source_id%TYPE      -- �󒍃\�[�XID
    , order_connection_number     xxcos_sales_exp_headers.order_connection_number%TYPE-- �󒍊֘A�ԍ�
    , card_sale_class             xxcos_sales_exp_headers.card_sale_class%TYPE      -- �J�[�h����敪
    , invoice_class               xxcos_sales_exp_headers.invoice_class%TYPE        -- �`�[�敪
    , big_classification_code     xxcos_sales_exp_headers.invoice_classification_code%TYPE    -- �`�[���ރR�[�h
    , change_out_time_100         xxcos_sales_exp_headers.change_out_time_100%TYPE  -- ��K�؂ꎞ�ԂP�O�O�~
    , change_out_time_10          xxcos_sales_exp_headers.change_out_time_10%TYPE   -- ��K�؂ꎞ�ԂP�O�~
    , ar_interface_flag           xxcos_sales_exp_headers.ar_interface_flag%TYPE    -- AR�C���^�t�F�[�X�σt���O
    , gl_interface_flag           xxcos_sales_exp_headers.gl_interface_flag%TYPE    -- GL�C���^�t�F�[�X�σt���O
    , dwh_interface_flag          xxcos_sales_exp_headers.dwh_interface_flag%TYPE   -- ����Ѳ���̪���σt���O
    , edi_interface_flag          xxcos_sales_exp_headers.edi_interface_flag%TYPE   -- EDI���M�ς݃t���O
    , edi_send_date               xxcos_sales_exp_headers.edi_send_date%TYPE        -- EDI���M����
    , hht_dlv_input_date          xxcos_sales_exp_headers.hht_dlv_input_date%TYPE   -- HHT�[�i���͓���
    , dlv_by_code                 xxcos_sales_exp_headers.dlv_by_code%TYPE          -- �[�i�҃R�[�h
    , create_class                xxcos_sales_exp_headers.create_class%TYPE         -- �쐬���敪
    , dlv_invoice_line_number     xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE-- �[�i���הԍ�
    , order_invoice_line_number   xxcos_sales_exp_lines.order_invoice_line_number%TYPE  -- �������הԍ�
    , sales_class                 xxcos_sales_exp_lines.sales_class%TYPE            -- ����敪
    , delivery_pattern_class      xxcos_sales_exp_lines.delivery_pattern_class%TYPE -- �[�i�`�ԋ敪
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%TYPE         -- �ԍ��t���O
    , item_code                   xxcos_sales_exp_lines.item_code%TYPE              -- �i�ڃR�[�h
    , ordered_quantity            oe_order_lines_all.ordered_quantity%TYPE          -- �󒍐���
    , base_quantity               xxcos_sales_exp_lines.standard_qty%TYPE           -- �����
    , order_quantity_uom          oe_order_lines_all.order_quantity_uom%TYPE        -- �󒍒P��
    , base_uom                    xxcos_sales_exp_lines.standard_uom_code%TYPE      -- ��P��
    , standard_unit_price         xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE -- �Ŕ���P��
    , base_unit_price             xxcos_sales_exp_lines.standard_unit_price%TYPE    -- ��P��
    , unit_selling_price          oe_order_lines_all.unit_selling_price%TYPE        -- �̔��P��
    , business_cost               xxcos_sales_exp_lines.business_cost%TYPE          -- �c�ƌ���
    , sale_amount                 xxcos_sales_exp_lines.sale_amount%TYPE            -- ������z
    , pure_amount                 xxcos_sales_exp_lines.pure_amount%TYPE            -- �{�̋��z
    , tax_amount                  xxcos_sales_exp_lines.tax_amount%TYPE             -- ����ŋ��z
    , cash_and_card               xxcos_sales_exp_lines.cash_and_card%TYPE          -- �����E�J�[�h���p�z
    , ship_from_subinventory_code xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE  -- �o�׌��ۊǏꏊ
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%TYPE     -- �[�i���_�R�[�h
    , hot_cold_class              xxcos_sales_exp_lines.hot_cold_class%TYPE         -- �g���b
    , column_no                   xxcos_sales_exp_lines.column_no%TYPE              -- �R����No
    , sold_out_class              xxcos_sales_exp_lines.sold_out_class%TYPE         -- ���؋敪
    , sold_out_time               xxcos_sales_exp_lines.sold_out_time%TYPE          -- ���؎���
    , to_calculate_fees_flag      xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE -- �萔���v�Z�C���^�t�F�[�X�σt���O
    , unit_price_mst_flag         xxcos_sales_exp_lines.unit_price_mst_flag%TYPE    -- �P���}�X�^�쐬�σt���O
    , inv_interface_flag          xxcos_sales_exp_lines.inv_interface_flag%TYPE     -- INV�C���^�t�F�[�X�σt���O
    , bill_tax_round_rule         xxcfr_cust_hierarchy_v.bill_tax_round_rule%TYPE   -- �ŋ��|�[������
    , child_item_code             xxcos_sales_exp_lines.item_code%TYPE              -- �i�ڎq�R�[�h
    , packing_instructions        xxwsh_order_lines_all.request_no%TYPE             -- �˗�No
    , request_no                  xxwsh_order_lines_all.request_no%TYPE             -- �o�׈˗�No
    , shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE     -- �o�וi��
    , arrival_date                xxwsh_order_headers_all.arrival_date%TYPE         -- ���ד�
    , shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE       -- �o�׎��ѐ���
/* 2009/07/09 Ver1.11 Add Start */
    , info_class                  oe_order_headers_all.global_attribute3%TYPE       -- ���敪
/* 2009/07/09 Ver1.11 Add End   */
    , check_status                NUMBER                                            -- �`�F�b�N�X�e�[�^�X
  );
--
  -- ����敪
  TYPE sales_class_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values.lookup_code%TYPE     -- ����^�C�v
    , sales_class                 xxcos_sales_exp_lines.sales_class%TYPE    -- ����敪
  );
--
  -- ����ŃR�[�h
  TYPE tax_rtype IS RECORD(
    tax_class                     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����ŋ敪
    , tax_code                    xxcos_sales_exp_headers.tax_code%TYPE               -- �ŃR�[�h
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%TYPE               -- �ŗ�
    , tax_include                 fnd_lookup_values.attribute5%TYPE                   -- ���Ńt���O
  );
--
  -- ����ŋ敪
  TYPE tax_class_rtype IS RECORD(
    tax_free                      xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ��ې�
    , tax_consumption             xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- �O��
    , tax_slip                    xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����(�`�[�ې�)
    , tax_included                xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����(�P������)
   );
/* 2009/07/09 Ver1.11 Add Start */
  -- �󒍖���ID
  TYPE line_id_rtype IS RECORD(
    line_id                       oe_order_lines_all.line_id%TYPE      -- �󒍖���ID
    , line_number                 oe_order_lines_all.line_number%TYPE  -- �󒍖��הԍ�
   );
/* 2009/07/09 Ver1.11 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h�錾
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --�󒍃f�[�^
  TYPE g_n_order_data_ttype IS TABLE OF order_data_rtype INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_rtype INDEX BY VARCHAR2(100);
--
  --�̔����уw�b�_
  TYPE g_sale_results_headers_ttype IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY BINARY_INTEGER;
  --�̔����і���
  TYPE g_sale_results_lines_ttype IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY BINARY_INTEGER;
--
  --����敪
  TYPE g_sale_class_sub_ttype
        IS TABLE OF sales_class_rtype INDEX BY BINARY_INTEGER;
  TYPE g_sale_class_ttype
        IS TABLE OF sales_class_rtype INDEX BY fnd_lookup_values.lookup_code%TYPE;
  --����ŃR�[�h
  TYPE g_tax_sub_ttype
        IS TABLE OF tax_rtype INDEX BY BINARY_INTEGER;
  TYPE g_tax_ttype
        IS TABLE OF tax_rtype INDEX BY xxcos_sales_exp_headers.consumption_tax_class%TYPE;
/* 2009/07/09 Ver1.11 Add Start */
  -- �󒍖���ID
  TYPE g_line_id_ttype
        IS TABLE OF line_id_rtype INDEX BY PLS_INTEGER;
/* 2009/07/09 Ver1.11 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��PL/SQL�\
  -- ===============================
  g_sale_class_sub_tab        g_sale_class_sub_ttype;         -- ����敪
  g_sale_class_tab            g_sale_class_ttype;             -- ����敪
  g_tax_sub_tab               g_tax_sub_ttype;                -- ����ŃR�[�h
  g_tax_tab                   g_tax_ttype;                    -- ����ŃR�[�h
  g_order_data_tab            g_n_order_data_ttype;           -- �󒍃f�[�^
/* 2009/07/09 Ver1.11 Add Start */
  g_order_data_all_tab        g_n_order_data_ttype;           -- �󒍃f�[�^(�󒍍쐬�ΏۑS�f�[�^�擾�p)
  g_line_id_tab               g_line_id_ttype;                -- �󒍖���ID(�󒍃N���[�Y�p)
/* 2009/07/09 Ver1.11 Add End   */
  g_order_req_tab             g_v_order_data_ttype;           -- �󒍃f�[�^(�˗�No�E�i�ڒP�ʂ̐��ʃ`�F�b�N�p)
  g_order_exp_tab             g_v_order_data_ttype;           -- �󒍃f�[�^(�̔����э쐬�p)
  g_sale_hdr_tab              g_sale_results_headers_ttype;   -- �̔����уw�b�_
  g_sale_line_tab             g_sale_results_lines_ttype;     -- �̔����і���
  g_tax_class_rec             tax_class_rtype;                -- ����ŋ敪
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_target_date  IN      VARCHAR2,     -- �������t
    ov_errbuf       OUT     VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT     VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT     VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_para_msg     VARCHAR2(100);
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
--
    -- �o�^�Ɩ����t���擾
    gd_business_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF  ( gd_business_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 1.�p�����[�^
    --==================================
    --�������t���w�肳��Ă��Ȃ��ꍇ�́A�o�^�Ɩ����t���������t�Ƃ���
    IF ( iv_target_date IS NULL ) THEN
      -- �o�^�Ɩ����t���g�p
      gd_process_date := gd_business_date;
--
    ELSE
      -- �p�����[�^�̏��������g�p
      --�������t��yyyy/mm/dd�̏����̓��t�ƂȂ��Ă��邩�`�F�b�N����
      --������̏������t����t�^�ɕϊ��ł��Ȃ��ꍇ�́A���t�����G���[�Ƃ���
      BEGIN
        gd_process_date  :=  TO_DATE( iv_target_date, ct_target_date_format );
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_format_date_err_expt;
      END;
--
    END IF;
--
--
    --==================================
    -- 2.�p�����[�^�o��
    --==================================
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  cv_msg_parameter_note,
                       iv_token_name1   =>  cv_tkn_para_date,
                       iv_token_value1  =>  TO_CHAR( gd_process_date, ct_target_date_format )  -- �������t
                     );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  ct_msg_process_date_err
                     );
--
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
    -- *** ���t�����G���[��O�n���h�� ***
    WHEN global_format_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  ct_msg_date_format_err,
                       iv_token_name1   =>  cv_tkn_para_date,
                       iv_token_value1  =>  TO_CHAR( iv_target_date )
                      );
--
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
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
   * Procedure Name   : set_profile
   * Description      : �v���t�@�C���l�擾(A-2)
   ***********************************************************************************/
  PROCEDURE set_profile(
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_profile'; -- �v���O������
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
    lv_max_date     VARCHAR2(5000);
    lv_gl_id        VARCHAR2(5000);
    lv_profile_name VARCHAR2(5000);
    lv_table_name   VARCHAR2(100);    --  �e�[�u����
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
    --==================================
    -- 1.MO:�c�ƒP��
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_str_profile_nm
                         );
--
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX���t
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_str_max_date_nm
                         );
--
      RAISE global_get_profile_expt;
    END IF;
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.XXCOS:GL��v����ID
    --==================================
    lv_gl_id := FND_PROFILE.VALUE( cv_prf_bks_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_gl_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_nm,
                          iv_name        => cv_str_gl_id_nm
                        );
--
      RAISE global_get_profile_expt;
    END IF;
    gn_gl_id := TO_NUMBER( lv_gl_id );
--
    --==================================
    -- 4.����敪�擾
    --==================================
    BEGIN
      SELECT
        flv.meaning       AS transaction_type_id  -- ����^�C�v
      , flv.attribute1    AS sales_class          -- ����敪
      BULK COLLECT INTO
        g_sale_class_sub_tab
      FROM
        fnd_application               fa
      , fnd_lookup_types              flt
      , fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_sales_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_sales_class
                          );
        RAISE global_select_data_expt;
    END;
--
    FOR i IN 1..g_sale_class_sub_tab.COUNT LOOP
      g_sale_class_tab( g_sale_class_sub_tab(i).transaction_type_id ) := g_sale_class_sub_tab(i);
    END LOOP;
--
    --==================================
    -- 5.�ԍ��t���O�擾
    --==================================
    BEGIN
      SELECT
        flv.attribute1
      INTO
        gv_black_flag
      FROM
        fnd_application               fa
      , fnd_lookup_types              flt
      , fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_red_black_flag_type
      AND flv.lookup_code             = ct_qcc_red_black_flag_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_red_black_flag
                          );
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 6.�ŃR�[�h�擾
    --==================================
    BEGIN
--
      SELECT
        tax_code_mst.tax_class    AS tax_class    -- ����ŋ敪
      , tax_code_mst.tax_code     AS tax_code     -- �ŃR�[�h
      , avtab.tax_rate            AS tax_rate     -- �ŗ�
      , tax_code_mst.tax_include  AS tax_include  -- ���Ńt���O
      BULK COLLECT INTO
        g_tax_sub_tab
      FROM
        ar_vat_tax_all_b          avtab           -- �ŃR�[�h�}�X�^
        ,(
          SELECT
              flv.attribute3      AS tax_class    -- ����ŋ敪
            , flv.attribute2      AS tax_code     -- �ŃR�[�h
            , flv.attribute5      AS tax_include  -- ���Ńt���O
          FROM
            fnd_application       fa,
            fnd_lookup_types      flt,
            fnd_lookup_values     flv
          WHERE
              fa.application_id           = flt.application_id
          AND flt.lookup_type             = flv.lookup_type
          AND fa.application_short_name   = cv_xxcos_appl_short_nm
          AND flv.lookup_type             = ct_qct_tax_type
          AND flv.start_date_active      <= gd_process_date
          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
          AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--          AND flv.language                = USERENV( 'LANG' )
          AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
        ) tax_code_mst
      WHERE
        tax_code_mst.tax_code     = avtab.tax_code
        AND avtab.start_date     <= gd_process_date
        AND gd_process_date      <= NVL( avtab.end_date, gd_max_date )
        AND enabled_flag          = ct_yes_flg
        AND avtab.set_of_books_id = gn_gl_id;       -- GL��v����ID
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_tax_code
                          );
        RAISE global_select_data_expt;
    END;
--
    FOR i IN 1..g_tax_sub_tab.COUNT LOOP
      g_tax_tab( g_tax_sub_tab(i).tax_class ) := g_tax_sub_tab(i);
    END LOOP;
--
--
    --==================================
    -- 7.�󒍃w�b�_�A�h�I���X�e�[�^�X
    --==================================
    BEGIN
      SELECT
        flv.attribute1
      INTO
        gv_add_status_sum_up   -- �o�׎��ьv���
      FROM
        fnd_application               fa
      , fnd_lookup_types              flt
      , fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_odr_hdr_add_sts_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_add_status
                          );
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 8.�ۊǏꏊ���ށi�����j
    --==================================
    BEGIN
      SELECT
        flv.meaning
      INTO
        gv_direct_ship_code
      FROM
        fnd_application               fa
      , fnd_lookup_types              flt
      , fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_hokan_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' )
      AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
      AND ROWNUM = 1;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_hokan
                          );
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 9.����ŋ敪������
    --==================================
    BEGIN
      SELECT
        flv.attribute1      AS tax_free           -- ��ې�
        ,flv.attribute2     AS tax_consumption    -- �O��
        ,flv.attribute3     AS tax_slip           -- ����(�`�[�ې�)
        ,flv.attribute4     AS tax_included       -- ����(�P������)
      INTO
        g_tax_class_rec.tax_free                  -- ��ې�
        ,g_tax_class_rec.tax_consumption          -- �O��
        ,g_tax_class_rec.tax_slip                 -- ����(�`�[�ې�)
        ,g_tax_class_rec.tax_included             -- ����(�P������)
      FROM
        fnd_application       fa,
        fnd_lookup_types      flt,
        fnd_lookup_values     flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_tax_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_tax_class
                          );
        RAISE global_select_data_expt;
    END;
--
  EXCEPTION
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_nm,
                      iv_name               => ct_msg_get_profile_err,
                      iv_token_name1        => cv_tkn_profile,
                      iv_token_value1       => lv_profile_name
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �f�[�^�擾��O�n���h�� ***
    WHEN global_select_data_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_select_data_err,
                    iv_token_name1 => cv_tkn_table_name,
                    iv_token_value1=> lv_table_name,
                    iv_token_name2 => cv_tkn_key_data,
                    iv_token_value2=> NULL
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
  END set_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_order_data
   * Description      : �󒍃f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_order_data(
    ov_errbuf         OUT VARCHAR2,             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_lock_table   VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***    
    CURSOR order_lines_cur( iv_line_id oe_order_lines_all.line_id%TYPE )
    IS
      SELECT
        line_id
      FROM
        oe_order_lines_all
      WHERE
        line_id =iv_line_id
      FOR UPDATE OF
        line_id
      NOWAIT;
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
--
    SELECT
      ooha.header_id                        AS header_id                  -- �󒍃w�b�_ID
    , oola.line_id                          AS line_id                    -- �󒍖���ID
    , ottth.name                            AS order_type                 -- �󒍃^�C�v
    , otttl.name                            AS line_type                  -- ���׃^�C�v
    , ooha.salesrep_id                      AS salesrep_id                -- �c�ƒS��
    , ooha.cust_po_number                   AS dlv_invoice_number         -- �[�i�`�[�ԍ�
    , ooha.attribute19                      AS order_invoice_number       -- �����`�[�ԍ�
    , ooha.order_number                     AS order_number               -- �󒍔ԍ�
    , oola.line_number                      AS line_number                -- �󒍖��הԍ�
    , NULL                                  AS order_no_hht               -- ��No�iHHT)
    , NULL                                  AS order_no_hht_seq           -- ��No�iHHT�j�}��
    , NULL                                  AS dlv_invoice_class          -- �[�i�`�[�敪
    , NULL                                  AS cancel_correct_class       -- ����E�����敪
    , NULL                                  AS input_class                -- ���͋敪
    , xca.business_low_type                 AS cust_gyotai_sho            -- �Ƒԁi�����ށj
    , NULL                                  AS dlv_date                   -- �[�i��
    , TRUNC(oola.request_date)              AS org_dlv_date               -- �I���W�i���[�i��
    , NULL                                  AS inspect_date               -- ������
    , CASE 
        WHEN oola.attribute4 IS NULL THEN TRUNC(oola.request_date)
        ELSE TRUNC(TO_DATE( oola.attribute4, cv_fmt_date_default ))
      END                                   AS orig_inspect_date          -- �I���W�i��������
    , xca.customer_code                     AS ship_to_customer_code      -- �ڋq�[�i��
    , xchv.bill_tax_div                     AS consumption_tax_class      -- ����ŋ敪
    , NULL                                  AS tax_code                   -- �ŋ��R�[�h
    , NULL                                  AS tax_rate                   -- ����ŗ�
    , NULL                                  AS results_employee_code      -- ���ьv��҃R�[�h
    , xca.sale_base_code                    AS sale_base_code             -- ���㋒�_�R�[�h
    , xca.past_sale_base_code               AS last_month_sale_base_code  -- �O�����㋒�_�R�[�h
    , xca.rsv_sale_base_act_date            AS rsv_sale_base_act_date     -- �\�񔄏㋒�_�L���J�n��
    , xchv.cash_receiv_base_code            AS receiv_base_code           -- �������_�R�[�h
    , ooha.order_source_id                  AS order_source_id            -- �󒍃\�[�XID
    , ooha.orig_sys_document_ref            AS order_connection_number    -- �O���V�X�e���󒍔ԍ�
    , NULL                                  AS card_sale_class            -- �J�[�h����敪
/* 2009/07/09 Ver1.11 Mod Start */
--    , xeh.invoice_class                     AS invoice_class              -- �`�[�敪
--    , xeh.big_classification_code           AS invoice_classification_code-- �`�[���ރR�[�h
    , ooha.attribute5                       AS invoice_class              -- �`�[�敪
    , ooha.attribute20                      AS invoice_classification_code-- �`�[���ރR�[�h
/* 2009/07/09 Ver1.11 Mod End   */
    , NULL                                  AS change_out_time_100        -- ��K�؂ꎞ�ԂP�O�O�~
    , NULL                                  AS change_out_time_10         -- ��K�؂ꎞ�ԂP�O�~
    , ct_no_flg                             AS ar_interface_flag          -- AR�C���^�t�F�[�X�σt���O
    , ct_no_flg                             AS gl_interface_flag          -- GL�C���^�t�F�[�X�σt���O
    , ct_no_flg                             AS dwh_interface_flag         -- ���V�X�e���C���^�t�F�[�X�σt���O
    , ct_no_flg                             AS edi_interface_flag         -- EDI���M�ς݃t���O
    , NULL                                  AS edi_send_date              -- EDI���M����
    , NULL                                  AS hht_dlv_input_date         -- HHT�[�i���͓���
    , NULL                                  AS dlv_by_code                -- �[�i�҃R�[�h
    , cv_business_cost                      AS create_class               -- �쐬���敪
    , oola.line_number                      AS dlv_invoice_line_number    -- �[�i���הԍ�
    , oola.line_number                      AS order_invoice_line_number  -- �������הԍ�
    , oola.attribute5                       AS sales_class                -- ����敪
    , NULL                                  AS delivery_pattern_class     -- �[�i�`�ԋ敪
    , gv_black_flag                         AS red_black_flag             -- �ԍ��t���O
    , oola.ordered_item                     AS item_code                  -- �i�ڃR�[�h
/* 2009/05/20 Ver1.7 Start */
--    , oola.ordered_quantity                 AS ordered_quantity           -- �󒍐���
    , oola.ordered_quantity *
      DECODE( ottal.order_category_code
            , ct_order_category, -1, 1 )    AS ordered_quantity           -- �󒍐���
/* 2009/05/20 Ver1.7 End   */
    , 0                                     AS base_quantity              -- �����
    , oola.order_quantity_uom               AS order_quantity_uom         -- �󒍒P��
    , NULL                                  AS base_uom                   -- ��P��
    , 0                                     AS standard_unit_price        -- �Ŕ���P��
    , 0                                     AS base_unit_price            -- ��P��
    , oola.unit_selling_price               AS unit_selling_price         -- �̔��P��
    , 0                                     AS business_cost              -- �c�ƌ���
    , 0                                     AS sale_amount                -- ������z
    , 0                                     AS pure_amount                -- �{�̋��z
    , 0                                     AS tax_amount                 -- ����ŋ��z
    , NULL                                  AS cash_and_card              -- �����E�J�[�h���p�z
    , oola.subinventory                     AS ship_from_subinventory_code-- �o�׌��ۊǏꏊ
    , xca.delivery_base_code                AS delivery_base_code         -- �[�i���_�R�[�h
    , NULL                                  AS hot_cold_class             -- �g���b
    , NULL                                  AS column_no                  -- �R����No
    , NULL                                  AS sold_out_class             -- ���؋敪
    , NULL                                  AS sold_out_time              -- ���؎���
    , ct_no_flg                             AS to_calculate_fees_flag     -- �萔���v�Z�C���^�t�F�[�X�σt���O
    , ct_no_flg                             AS unit_price_mst_flag        -- �P���}�X�^�쐬�σt���O
    , ct_no_flg                             AS inv_interface_flag         -- INV�C���^�t�F�[�X�σt���O
    , xchv.bill_tax_round_rule              AS bill_tax_round_rule        -- �ŋ��|�[������
    , oola.attribute6                       AS child_item_code            -- �i�ڎq�R�[�h
    , oola.packing_instructions             AS packing_instructions       -- �˗�No
    , xola.request_no                       AS request_no                 -- �o�׈˗�No
/* 2009/07/08 Ver1.10 Mod Start */
--    , xola.shipping_item_code               AS shipping_item_code         -- �o�וi��
    , xola.request_item_code                AS shipping_item_code         -- �˗��i��
/* 2009/07/08 Ver1.10 Mod End   */
    , xoha.arrival_date                     AS arrival_date               -- ���ד�
    , xola.shipped_quantity                 AS shipped_quantity           -- �o�׎��ѐ���
/* 2009/07/09 Ver1.11 Add Start */
    , ooha.global_attribute3                AS info_class                 -- ���敪
/* 2009/07/09 Ver1.11 Add End   */
    , cn_check_status_normal                AS check_status               -- �`�F�b�N�X�e�[�^�X
    BULK COLLECT INTO
/* 2009/07/09 Ver1.11 Mod Start */
--      g_order_data_tab
      g_order_data_all_tab
/* 2009/07/09 Ver1.11 Mod End   */
    FROM
      oe_order_headers_all  ooha                        -- �󒍃w�b�_
/* 2009/07/09 Ver1.11 Del Start */
--      LEFT JOIN xxcos_edi_headers xeh                   -- EDI�w�b�_���
--        -- �󒍃w�b�_.�O���V�X�e���󒍔ԍ� = EDI�w�b�_���.�󒍊֘A�ԍ�
--        ON ooha.orig_sys_document_ref = xeh.order_connection_number     
/* 2009/07/09 Ver1.11 Del End   */
    , oe_order_lines_all  oola                          -- �󒍖���
      INNER JOIN xxwsh_order_headers_all  xoha          -- �󒍃w�b�_�A�h�I��
        ON  oola.packing_instructions = xoha.request_no -- �󒍖���.����w������ͯ�ޱ�޵�.�˗�No
        AND xoha.latest_external_flag = ct_yes_flg      -- ��ͯ�ޱ�޵�.�ŐV�׸� = 'Y'
        AND xoha.req_status = gv_add_status_sum_up      -- ��ͯ�ޱ�޵�.�ð�����o�׎��ьv���
      LEFT JOIN xxwsh_order_lines_all     xola    
        ON  xoha.order_header_id = xola.order_header_id -- ��ͯ�ޱ�޵�.ͯ��ID���󒍖��ױ�޵�.ͯ��ID
        -- NVL(�󒍖���.�i�ڎq�R�[�h�C�󒍖���.�󒍕i��)���󒍖��ױ�޵�.�o�וi��
/* 2009/07/08 Ver1.10 Mod Start */
--        AND NVL( oola.attribute6, oola.ordered_item ) = xola.shipping_item_code
        AND NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
/* 2009/07/08 Ver1.10 Mod End   */
        AND NVL( xola.delete_flag, ct_no_flg ) = ct_no_flg  -- �󒍖��ױ�޵�.�폜�׸� = 'N'
    , oe_transaction_types_tl   ottth   -- �󒍃w�b�_�E�v�p����^�C�v
    , oe_transaction_types_tl   otttl   -- �󒍖��דE�v�p����^�C�v
    , oe_transaction_types_all  ottal   -- �󒍖��׎���^�C�v
    , mtl_secondary_inventories msi     -- �ۊǏꏊ�}�X�^
    , xxcmm_cust_accounts       xca     -- �A�J�E���g�A�h�I���}�X�^
    , xxcos_cust_hierarchy_v    xchv    -- �ڋq�K�wVIEW
    WHERE
        ooha.header_id = oola.header_id -- �󒍃w�b�_.�󒍃w�b�_ID���󒍖���.�󒍃w�b�_ID
    -- �󒍃w�b�_.�󒍃^�C�vID���󒍃w�b�_�E�v�p����^�C�v.����^�C�vID
    AND ooha.order_type_id = ottth.transaction_type_id
    -- �󒍖���.���׃^�C�vID���󒍖��דE�v�p����^�C�v.����^�C�vID
    AND oola.line_type_id  = otttl.transaction_type_id
    -- �󒍖���.���׃^�C�vID���󒍖��׎���^�C�v.����^�C�vID
    AND oola.line_type_id  = ottal.transaction_type_id
/* 2009/07/09 Ver1.11 Mod Start */
--    AND ottth.language = USERENV( 'LANG' )
--    AND otttl.language = USERENV( 'LANG' )
    AND ottth.language = cv_lang
    AND otttl.language = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
    AND ooha.flow_status_code = ct_hdr_status_booked                -- �󒍃w�b�_.�X�e�[�^�X���L����(BOOKED)
    AND ooha.order_category_code != ct_order_category               -- �󒍃w�b�_.�󒍃J�e�S���R�[�h���ԕi(RETURN)
    -- �󒍖���.�X�e�[�^�X���۰��or���
    AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
    AND ooha.org_id = gn_org_id                                     -- �g�DID
    AND TRUNC( oola.request_date ) <= TRUNC( gd_process_date )      -- �󒍖���.�v�������Ɩ����t
    AND ooha.sold_to_org_id = xca.customer_id                       -- �󒍃w�b�_.�ڋqID = ����ı�޵�Ͻ�.�ڋqID
    AND ooha.sold_to_org_id = xchv.ship_account_id                  -- �󒍃w�b�_.�ڋqID = �ڋq�K�wVIEW.�o�א�ڋqID
/* 2009/07/09 Ver1.11 Mod Start */
--    AND oola.ordered_item NOT IN (                                  -- �󒍖���.�󒍕i�ځ���݌ɕi��
    AND NOT EXISTS (                                  -- �󒍖���.�󒍕i�ځ���݌ɕi��
/* 2009/07/09 Ver1.11 Mod End   */
                                  SELECT
                                    flv.lookup_code
                                  FROM
                                    fnd_application               fa
                                  , fnd_lookup_types              flt
                                  , fnd_lookup_values             flv
                                  WHERE
                                      fa.application_id           = flt.application_id
                                  AND flt.lookup_type             = flv.lookup_type
                                  AND fa.application_short_name   = cv_xxcos_appl_short_nm
                                  AND flv.lookup_type             = ct_qct_no_inv_item_code_type
                                  AND flv.start_date_active      <= gd_process_date
                                  AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                  AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--                                  AND flv.language                = USERENV( 'LANG' )
                                  AND flv.language                = cv_lang
                                  AND flv.lookup_code             = oola.ordered_item
/* 2009/07/09 Ver1.11 Mod End   */
                                 )
    AND oola.subinventory = msi.secondary_inventory_name    -- �󒍖���.�ۊǏꏊ=�ۊǏꏊ�}�X�^.�ۊǏꏊ�R�[�h
    AND oola.ship_from_org_id = msi.organization_id         -- �o�׌��g�DID = �g�DID
    AND EXISTS (
              SELECT
                'X'
              FROM (
                  SELECT
                    flv.attribute1 AS subinventory
                  , flv.attribute2 AS order_type
                  , flv.attribute3 AS line_type
                  FROM
                    fnd_application               fa
                  , fnd_lookup_types              flt
                  , fnd_lookup_values             flv
                  WHERE
                      fa.application_id           = flt.application_id
                  AND flt.lookup_type             = flv.lookup_type
                  AND fa.application_short_name   = cv_xxcos_appl_short_nm
                  AND flv.lookup_type             = ct_qct_sale_exp_condition
                  AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                  AND flv.start_date_active      <= gd_process_date
                  AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                  AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--                  AND flv.language                = USERENV( 'LANG' )
                  AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
                ) flvs
              WHERE
                  msi.attribute13 = flvs.subinventory                  -- �ۊǏꏊ����
              AND ottth.name      = NVL( flvs.order_type, ottth.name ) -- �󒍃^�C�v
              AND otttl.name      = NVL( flvs.line_type,  otttl.name ) -- ���׃^�C�v
        )
/* 2009/07/09 Ver1.11 Add Start */
    AND (
          ooha.global_attribute3 IS NULL
        OR
          ooha.global_attribute3 IN ( cv_target_order_01, cv_target_order_02 )
        )
/* 2009/07/09 Ver1.11 Add End   */
    ORDER BY
      ooha.header_id                              -- ��ͯ��.��ͯ��ID
    , oola.request_date                           -- �󒍖���.�v����
    , NVL( oola.attribute4, oola.request_date )   -- �󒍖���.������(NULL���́A�󒍖���.�v����)
    , oola.line_id                                -- �󒍖���.�󒍖���ID
    FOR UPDATE OF
      ooha.header_id
    NOWAIT;
--
    --�f�[�^���������́u�Ώۃf�[�^�Ȃ��G���[���b�Z�[�W�v
/* 2009/07/09 Ver1.11 Mod Start */
--    IF ( g_order_data_tab.COUNT = 0 ) THEN
    IF ( g_order_data_all_tab.COUNT = 0 ) THEN
/* 2009/07/09 Ver1.11 Mod End   */
      RAISE global_no_data_warm_expt;
    END IF;
--
    -- �Ώی���
/* 2009/07/09 Ver1.11 Mod Start */
--    gn_target_cnt := g_order_data_tab.COUNT;
    gn_target_cnt := g_order_data_all_tab.COUNT;
/* 2009/07/09 Ver1.11 Mod End   */
--
--
    -- �󒍖��ׂ̍s���b�N����
    -- �O�������ɑ΂���s���b�N���s�����Ƃ��ł��Ȃ����߁A�����ōs���b�N���s��
    <<loop_lock>>
/* 2009/07/09 Ver1.11 Mod Start */
--    FOR i IN 1..g_order_data_tab.COUNT LOOP
--      OPEN order_lines_cur( g_order_data_tab(i).line_id );
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
      OPEN order_lines_cur( g_order_data_all_tab(i).line_id );
/* 2009/07/09 Ver1.11 Mod End   */
      CLOSE order_lines_cur;
    END LOOP loop_lock;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�Ȃ���O�n���h�� ***
    WHEN global_no_data_warm_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_nodata_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_err_expt  THEN
      lv_lock_table := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm,
                         iv_name        => cv_lock_table
                        );
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_rowtable_lock_err,
                    iv_token_name1 => cv_tkn_table,
                    iv_token_value1=> lv_lock_table
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
  END get_order_data;
--
  /************************************************************************
   * Function Name   : get_fiscal_period_from
   * Description     : �L����v����FROM�擾�֐�(A-4-1)
   ************************************************************************/
  PROCEDURE get_fiscal_period_from(
    iv_div                  IN  VARCHAR2,     -- ��v�敪
    id_base_date            IN  DATE,         -- ���
    od_open_date            OUT DATE,         -- �L����v����FROM
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fiscal_period_from'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_status_open      CONSTANT VARCHAR2(5)  := 'OPEN';                     -- �X�e�[�^�X[OPEN]
--
    -- *** ���[�J���ϐ� ***
    lv_status    VARCHAR2(6); -- �X�e�[�^�X
    ld_date_from DATE;        -- ��v�iFROM�j
    ld_date_to   DATE;        -- ��v�iTO�j
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
    --�P�D��������
    lv_status    := NULL;  -- �X�e�[�^�X
    ld_date_from := NULL;  -- ��v�iFROM�j
    ld_date_to   := NULL;  -- ��v�iTO�j
--
    --�Q�D�����v���ԏ��擾
    xxcos_common_pkg.get_account_period(
        iv_account_period   => iv_div         -- ��v�敪
      , id_base_date        => id_base_date   -- ���
      , ov_status           => lv_status      -- �X�e�[�^�X
      , od_start_date       => ld_date_from   -- ��v(FROM)
      , od_end_date         => ld_date_to     -- ��v(TO)
      , ov_errbuf           => lv_errbuf      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode          => lv_retcode     -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg           => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
--
    --�G���[�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --�X�e�[�^�X�`�F�b�N
    IF ( lv_status = cv_status_open ) THEN
      od_open_date := id_base_date;
      RETURN;
    END IF;
--
    --�R�DOPEN��v���ԏ��擾
    xxcos_common_pkg.get_account_period(
        iv_account_period   => iv_div         -- ��v�敪
      , id_base_date        => NULL           -- ���
      , ov_status           => lv_status      -- �X�e�[�^�X
      , od_start_date       => ld_date_from   -- ��v(FROM)
      , od_end_date         => ld_date_to     -- ��v(TO)
      , ov_errbuf           => lv_errbuf      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode          => lv_retcode     -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg           => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
--
    --�G���[�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --��v����FROM
    od_open_date := ld_date_from;
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
  END get_fiscal_period_from;
--
  /**********************************************************************************
   * Procedure Name   : edit_item
   * Description      : ���ڕҏW(A-4)
   ***********************************************************************************/
  PROCEDURE edit_item(
    io_order_rec              IN OUT NOCOPY  order_data_rtype,   -- �󒍃f�[�^���R�[�h
    ov_errbuf                 OUT    VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT    VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT    VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_item'; -- �v���O������
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
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- �ڋq�����̐擪����
--
    -- *** ���[�J���ϐ� ***
    lv_item_id                ic_item_mst_b.item_id%TYPE; --  �i��ID
    lv_organization_code      VARCHAR2(100);              --  �݌ɑg�D�R�[�h
    ln_organization_id        NUMBER;                     --  �݌ɑg�D�h�c
    ln_content                NUMBER;                     --  ����
    ld_base_date              DATE;                       --  ���
    lv_table_name             VARCHAR2(100);              --  �e�[�u����
    lv_key_data               VARCHAR2(5000);             --  �L�[���
    ln_tax                    NUMBER;                     --  �����
    ln_pure_amount            NUMBER;                     --  �{�̋��z
/* 2009/06/09 Ver1.9 Add Start */
    ln_tax_amount             NUMBER;                     --  ����ŋ��z�v�Z�p(�����_�l��)
/* 2009/06/09 Ver1.9 Add End   */
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
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
    --==================================
    -- 1.�[�i���Z�o
    --==================================
    get_fiscal_period_from(
        iv_div        => cv_fiscal_period_ar             -- ��v�敪
      , id_base_date  => io_order_rec.org_dlv_date       -- ���            =  �I���W�i���[�i��
      , od_open_date  => io_order_rec.dlv_date           -- �L����v����FROM  => �[�i��
      , ov_errbuf     => lv_errbuf                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode    => lv_retcode                      -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg     => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      ld_base_date := io_order_rec.org_dlv_date;
      RAISE global_fiscal_period_err_expt;
    END IF;
--
--
    --==================================
    -- 2.�������Z�o
    --==================================
    get_fiscal_period_from(
        iv_div        => cv_fiscal_period_ar                  -- ��v�敪
      , id_base_date  => io_order_rec.orig_inspect_date       -- ���           =  �I���W�i��������
      , od_open_date  => io_order_rec.inspect_date            -- �L����v����FROM => ������
      , ov_errbuf     => lv_errbuf                            -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode    => lv_retcode                           -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg     => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      ld_base_date := io_order_rec.orig_inspect_date;
      RAISE global_fiscal_period_err_expt;
    END IF;
--
--
    --==================================
    -- 3.����ʎZ�o
    --==================================
    xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => io_order_rec.order_quantity_uom   --���Z�O�P�ʃR�[�h = �P��
      , in_before_quantity    => io_order_rec.ordered_quantity     --���Z�O����       = ����
      , iov_item_code         => io_order_rec.item_code            --�i�ڃR�[�h
      , iov_organization_code => lv_organization_code              --�݌ɑg�D�R�[�h   = NULL
      , ion_inventory_item_id => lv_item_id                        --�i�ڂh�c         = NULL
      , ion_organization_id   => ln_organization_id                --�݌ɑg�D�h�c     = NULL
      , iov_after_uom_code    => io_order_rec.base_uom             --���Z��P�ʃR�[�h =>��P��
      , on_after_quantity     => io_order_rec.base_quantity        --���Z�㐔��       =>�����
      , on_content            => ln_content                        --����
      , ov_errbuf             => lv_errbuf                         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode            => lv_retcode                        --���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg             => lv_errmsg                         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_base_quantity_err_expt;
    END IF;
--
    --==================================
    -- 4.�ŗ�
    --==================================
    IF ( g_tax_tab.EXISTS( io_order_rec.consumption_tax_class ) ) THEN
--
      io_order_rec.tax_rate := NVL( g_tax_tab( io_order_rec.consumption_tax_class ).tax_rate, 0 );
--
    ELSE
--
      io_order_rec.tax_rate := 0;
--
    END IF;
--
--
    --==================================
    -- 5.��P���Z�o
    --==================================
    IF ( ln_content = 0 ) THEN
--
      -- ��P�� �� 0
      io_order_rec.base_unit_price := 0;
--
    ELSE
--
      -- ��P�� �� �̔��P�� �� ����
      io_order_rec.base_unit_price := ROUND( io_order_rec.unit_selling_price / ln_content , 2 );
--
    END IF;
--
--
    --==================================
    -- 6.�Ŕ���P��
    --==================================
    -- ����ŋ敪 �� ����(�P������)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN    
--
/* 2009/06/01 Ver1.8 Mod Start */
--      -- ����� �� ��P�� �| ��P�� �� ( 1 �{ ����ŗ� �� 100 )
--      ln_tax := io_order_rec.base_unit_price
--              - io_order_rec.base_unit_price / ( 1 + io_order_rec.tax_rate / 100 );
----
--      -- �؏�
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--/* 2009/05/20 Ver1.7 Mod Start */
--        --�����_�����݂���ꍇ
--        IF ( ln_tax - TRUNC( ln_tax ) <> 0 ) THEN
--          ln_tax := TRUNC( ln_tax ) + 1;
--        END IF;
--/* 2009/05/20 Ver1.7 Mod End   */
--      -- �؎̂�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--        ln_tax := TRUNC( ln_tax );
--      -- �l�̌ܓ�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--        ln_tax := ROUND( ln_tax );
--      END IF;
----      
--      -- �Ŕ���P�� �� ��P�� �| �����
--      io_order_rec.standard_unit_price := io_order_rec.base_unit_price - ln_tax;
--
        -- �Ŕ���P�� = ( ��P�� / ( 100 +  ����ŗ� ) ) �~ 100
        io_order_rec.standard_unit_price := ROUND( ( (io_order_rec.base_unit_price
                                                      /( 100 + io_order_rec.tax_rate ) ) * 100 ) , 2 );
/* 2009/06/01 Ver1.8 Mod End   */
--
    ELSE
--
      -- �Ŕ���P�� �� ��P��
      io_order_rec.standard_unit_price := io_order_rec.base_unit_price;
--
    END IF;
--
--
    --==================================
    -- 7.������z�Z�o
    --==================================
    -- ������z �� �󒍐��� �~ �̔��P��
    io_order_rec.sale_amount := TRUNC( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price );
--
--
/* 2009/05/20 Ver1.7 Add Start */
    --==================================
    -- 8.����ŎZ�o
    --==================================
    -- ����ŋ敪 �� ��ې�
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_free ) THEN
--
      -- ����� �� 0
      io_order_rec.tax_amount := 0;
--
    -- ����ŋ敪 �� ����(�P������)
    ELSIF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
      -- ����� �� (�󒍐��� �~ �̔��P��) - (�󒍐��� �~ �̔��P�� �~ 100��(����ŗ��{100))
--      io_order_rec.tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
--                                   - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
--                                       * 100 / ( io_order_rec.tax_rate + 100 ) );
      --������
      ln_tax_amount := 0;
--
      ln_tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
                         - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                             * 100 / ( io_order_rec.tax_rate + 100 ) );
--
      -- �؏�
      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--
        -- �����_�ȉ������݂���ꍇ
--        IF ( io_order_rec.tax_amount - TRUNC( io_order_rec.tax_amount ) <> 0 ) THEN
        IF ( ln_tax_amount - TRUNC( ln_tax_amount ) <> 0 ) THEN
--
          -- �ԕi(���ʂ��}�C�i�X)�ȊO�̏ꍇ
--          IF ( SIGN( io_order_rec.tax_amount ) <> -1 ) THEN
          IF ( SIGN( ln_tax_amount ) <> -1 ) THEN
--
--            io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount ) + 1;
            io_order_rec.tax_amount := TRUNC( ln_tax_amount ) + 1;
--
          -- �ԕi(���ʂ��}�C�i�X)�̏ꍇ
          ELSE
--
--            io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount ) - 1;
            io_order_rec.tax_amount := TRUNC( ln_tax_amount ) - 1;
--
          END IF;
--
        --�����_�ȉ������݂��Ȃ��ꍇ
        ELSE
--
          io_order_rec.tax_amount := ln_tax_amount;
--
        END IF;
--
      -- �؎̂�
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--
--        io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount );
        io_order_rec.tax_amount := TRUNC( ln_tax_amount );
--
      -- �l�̌ܓ�
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--
--        io_order_rec.tax_amount := ROUND( io_order_rec.tax_amount );
        io_order_rec.tax_amount := ROUND( ln_tax_amount );
--
/* 2009/06/09 Ver1.9 Mod End */
      END IF;
--
    ELSE
--
      -- ����� �� �󒍐��� �~ �̔��P�� �~ �i����ŗ���100�j�������_�ȉ��l�̌ܓ�
      io_order_rec.tax_amount := ROUND( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                                   * ( io_order_rec.tax_rate / 100 ) );
--
    END IF;
/* 2009/05/20 Ver1.7 Add End   */
--
--
    --==================================
    -- 9.�{�̋��z
    --==================================
    -- ����ŋ敪 �� ����(�P������)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/05/20 Ver1.7 Mod Start */
--      -- �{�̋��z �� ������z �~ 100 �� ( 100 + �ŗ� )
--      ln_pure_amount := io_order_rec.sale_amount * 100 / ( 100 + io_order_rec.tax_rate );
--
--      -- �؏�
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--        io_order_rec.pure_amount := TRUNC( ln_pure_amount ) + 1;
--      -- �؎̂�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--        io_order_rec.pure_amount := TRUNC( ln_pure_amount );
--      -- �l�̌ܓ�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--        io_order_rec.pure_amount := ROUND( ln_pure_amount );
--      END IF;
      -- �{�̋��z �� ������z�|����Ŋz
      io_order_rec.pure_amount := io_order_rec.sale_amount - io_order_rec.tax_amount;
/* 2009/05/20 Ver1.7 Mod End   */
--
    ELSE
--
      -- �{�̋��z �� ������z
      io_order_rec.pure_amount := io_order_rec.sale_amount;
--
    END IF;
--
--
/* 2009/05/20 Ver1.7 Del Start */
--    --==================================
--    -- 9.����ŎZ�o
--    --==================================
--    -- ����ŋ敪 �� ��ې�
--    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_free ) THEN
--
--      -- ����� �� 0
--      io_order_rec.tax_amount := 0;
--
--    -- ����ŋ敪 �� ����(�P������)
--    ELSIF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
--      -- ����� �� ������z �| �{�̋��z
--      io_order_rec.tax_amount := io_order_rec.sale_amount - io_order_rec.pure_amount;
--
--    ELSE
--      
--      -- ����� �� �{�̋��z �~ �ŗ� �� 100
--      io_order_rec.tax_amount := ROUND( io_order_rec.pure_amount * ( io_order_rec.tax_rate / 100 ) );
--
--    END IF;
/* 2009/05/20 Ver1.7 Del End   */
--
--
    --==================================
    -- 10.�ŃR�[�h�擾
    --==================================
    IF ( g_tax_tab.EXISTS( io_order_rec.consumption_tax_class ) ) THEN
      io_order_rec.tax_code := g_tax_tab( io_order_rec.consumption_tax_class ).tax_code;
    ELSE
      io_order_rec.tax_code := NULL;
    END IF;
--
    --==================================
    -- 11.����敪
    --==================================
    IF ( io_order_rec.sales_class IS NULL AND g_sale_class_tab.EXISTS( io_order_rec.line_type ) ) THEN
      io_order_rec.sales_class := g_sale_class_tab( io_order_rec.line_type ).sales_class;
    END IF;
--
    --==================================
    -- 12.�[�i�`�[�敪�擾
    --==================================
    BEGIN
      SELECT
--****************************** 2009/04/14 1.6 T.kitajima MOD START ******************************--
--        flv.attribute3   --�[�i�`�[�敪
        flv.attribute4   --�[�i�`�[�敪(���Y)
--****************************** 2009/04/14 1.6 T.kitajima MOD START ******************************--
      INTO
        io_order_rec.dlv_invoice_class
      FROM
        fnd_application               fa
      , fnd_lookup_types              flt
      , fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_dlv_slp_cls_type
      AND flv.lookup_code          LIKE ct_qcc_dlv_slp_cls_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' )
      AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
      AND flv.attribute1              = io_order_rec.order_type  -- �w�b�_����^�C�v
      AND flv.attribute2              = io_order_rec.line_type   -- ���׎���^�C�v
      AND ROWNUM = 1;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_dlv_invoice_class
                          );
        io_order_rec.dlv_invoice_class := NULL;    -- �[�i�`�[�敪
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 13.���㋒�_�R�[�h
    --==================================
    IF ( TRUNC( io_order_rec.dlv_date ) < TRUNC( io_order_rec.rsv_sale_base_act_date ) ) THEN
      -- ���㋒�_�R�[�h��O�����㋒�_�R�[�h�ɐݒ肷��
      io_order_rec.sale_base_code := io_order_rec.last_month_sale_base_code;
    END IF;
--
    --==================================
    -- 14.�[�i�`�ԋ敪�擾
    --==================================
    xxcos_common_pkg.get_delivered_from(
        iv_subinventory_code  => io_order_rec.ship_from_subinventory_code -- �ۊǏꏊ�R�[�h = �o�׌��ۊǏꏊ
      , iv_sales_base_code    => io_order_rec.sale_base_code              -- ���㋒�_�R�[�h
      , iv_ship_base_code     => io_order_rec.delivery_base_code          -- �o�׋��_�R�[�h
      , iov_organization_code => lv_organization_code                     -- �݌ɑg�D�R�[�h
      , ion_organization_id   => ln_organization_id                       -- �݌ɑg�D�h�c
      , ov_delivered_from     => io_order_rec.delivery_pattern_class      -- �[�i�`��
      , ov_errbuf             => lv_errbuf                                -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode            => lv_retcode                               -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg             => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_delivered_from_err_expt;
    END IF;
--
    --==================================
    -- 15.�c�ƌ����Z�o
    --==================================
    BEGIN
      SELECT
        CASE
          WHEN iimb.attribute9 > TO_CHAR( io_order_rec.dlv_date, ct_target_date_format )
            THEN iimb.attribute7    -- �c�ƌ���(��)
          ELSE
            iimb.attribute8         -- �c�ƌ���(�V)
        END
      INTO
        io_order_rec.business_cost  -- �c�ƌ���
      FROM
        ic_item_mst_b     iimb      -- OPM�i��
      , xxcmn_item_mst_b  ximb      -- OPM�i�ڃA�h�I��
      WHERE
          iimb.item_no = io_order_rec.item_code
      AND iimb.item_id = ximb.item_id
      AND TRUNC( ximb.start_date_active ) <= io_order_rec.dlv_date
      AND NVL( ximb.end_date_active, gd_max_date ) >= io_order_rec.dlv_date;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_item_table
                          );
        io_order_rec.business_cost := NULL;    -- �c�ƌ���
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 16.�]�ƈ��}�X�^���擾
    --==================================
    BEGIN
--
      SELECT
        papf.employee_number                -- �]�ƈ��ԍ�
      INTO
        io_order_rec.results_employee_code  -- ���ьv��҃R�[�h
      FROM
        jtf_rs_resource_extns jrre        -- ���\�[�X�}�X�^
      , per_all_people_f papf             -- �]�ƈ��}�X�^
      , jtf_rs_salesreps jrs              -- 
      WHERE
          jrs.salesrep_id = io_order_rec.salesrep_id
      AND jrs.resource_id = jrre.resource_id
      AND jrre.source_id = papf.person_id
      AND TRUNC( papf.effective_start_date ) <= TRUNC( io_order_rec.dlv_date )
      AND TRUNC( NVL( papf.effective_end_date,gd_max_date ) ) >= io_order_rec.dlv_date;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_person_table
                          );
        io_order_rec.results_employee_code := NULL;    -- ���ьv��҃R�[�h
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 17.�[�i�`�[�ԍ�
    --==================================
    IF ( SUBSTR( io_order_rec.dlv_invoice_number, 1, 1 ) = cv_cust_po_number_first ) THEN
      io_order_rec.dlv_invoice_number := io_order_rec.packing_instructions;
    END IF;
--
  EXCEPTION
    -- *** ����ʎ擾��O�n���h�� ***
    WHEN global_base_quantity_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_base_quantity_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_rec.order_number,      -- �󒍔ԍ�
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_rec.line_number,       -- �󒍖��הԍ�
                    iv_token_name3 => cv_tkn_item_code,
                    iv_token_value3=> io_order_rec.item_code,         -- �i�ڃR�[�h
                    iv_token_name4 => cv_tkn_before_code,
                    iv_token_value4=> io_order_rec.order_quantity_uom,-- �󒍒P��
                    iv_token_name5 => cv_tkn_before_value,
                    iv_token_value5=> io_order_rec.unit_selling_price,-- �̔��P��
                    iv_token_name6 => cv_tkn_after_code,
                    iv_token_value6=> io_order_rec.base_uom           -- ��P��
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
    -- *** ��v���Ԏ擾��O�n���h�� ***
    WHEN global_fiscal_period_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_fiscal_period_err,
                    iv_token_name1 => cv_tkn_account_name,
                    iv_token_value1=> cv_fiscal_period_ar,        -- AR��v���ԋ敪�l
                    iv_token_name2 => cv_tkn_order_number,
                    iv_token_value2=> io_order_rec.order_number,  -- �󒍔ԍ�
                    iv_token_name3 => cv_tkn_line_number,
                    iv_token_value3=> io_order_rec.line_number,   -- �󒍖��הԍ�
                    iv_token_name4 => cv_tkn_base_date,
                    iv_token_value4=> TO_CHAR(ld_base_date, cv_fmt_date_default) -- ���
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
    -- *** �[�i�`�ԋ敪�擾��O�n���h�� ***
    WHEN global_delivered_from_err_expt THEN
      xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_ship_from_subinventory_code
                                      ),
                    iv_data_value1 => io_order_rec.ship_from_subinventory_code, -- �ۊǏꏊ�R�[�h = �o�׌��ۊǏꏊ
                    iv_item_name2  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_sale_base_code
                                      ),
                    iv_data_value2 => io_order_rec.sale_base_code,              -- ���㋒�_�R�[�h
                    iv_item_name3  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_delivery_base_code
                                      ),
                    iv_data_value3 => io_order_rec.delivery_base_code,          -- �[�i���_�R�[�h
                    ov_key_info    => lv_key_data,
                    ov_errbuf      => lv_errbuf,                                -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
                    ov_retcode     => lv_retcode,                               -- ���^�[���E�R�[�h               #�Œ�#
                    ov_errmsg      => lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
                    );
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_delivered_from_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_rec.order_number,  -- �󒍔ԍ�
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_rec.line_number,   -- �󒍖��הԍ�
                    iv_token_name3 => cv_tkn_key_data,
                    iv_token_value3=> lv_key_data
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
    -- *** �f�[�^�擾��O�n���h�� ***
    WHEN global_select_data_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_select_odr_err,
                    iv_token_name1 => cv_tkn_table_name,
                    iv_token_value1=> lv_table_name,
                    iv_token_name2 => cv_tkn_order_number,
                    iv_token_value2=> io_order_rec.order_number,  -- �󒍔ԍ�
                    iv_token_name3 => cv_tkn_line_number,
                    iv_token_value3=> io_order_rec.line_number    -- �󒍖��הԍ�
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
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
  END edit_item;
--
  /**********************************************************************************
   * Procedure Name   : check_data_row
   * Description      : �f�[�^�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_data_row(
    io_order_data_rec  IN OUT NOCOPY order_data_rtype,     -- �󒍃f�[�^���R�[�h
    ov_errbuf          OUT     VARCHAR2,             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT     VARCHAR2,             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT     VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data_row'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_delimiter    VARCHAR2(1) := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_field_name       VARCHAR2(5000);
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
    lv_field_name := NULL;
--
    -- ===============================
    -- NULL�`�F�b�N
    -- ===============================
    -- �[�i�`�[�ԍ�
    IF ( io_order_data_rec.dlv_invoice_number IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_dlv_invoice_number);
    END IF;
    -- �ŋ��R�[�h
    IF ( io_order_data_rec.tax_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_tax_code);
    END IF;
    -- ���㋒�_�R�[�h
    IF ( io_order_data_rec.sale_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_sale_base_code);
    END IF;
    -- �������_�R�[�h
    IF ( io_order_data_rec.receiv_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_receiv_base_code);
    END IF;
    -- ����敪
    IF ( io_order_data_rec.sales_class IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_sales_class);
    END IF;
    -- �[�i���_�R�[�h
    IF ( io_order_data_rec.delivery_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_delivery_base_code);
    END IF;
--
    -- ��L�̂����ꂩ�̍��ڂ�NULL�̏ꍇ�A�G���[���b�Z�[�W���o�͂���
    IF ( lv_field_name IS NOT NULL ) THEN
      lv_field_name := SUBSTR( lv_field_name , 2 ); -- �n�߂̃f���~�^���폜
--
      -- ���[�U�[�E�G���[�E���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_null_column_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_data_rec.order_number,
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_data_rec.line_number,
                    iv_token_name3 => cv_tkn_field_name,
                    iv_token_value3=> lv_field_name
                  )
                  || cv_line_feed || cv_line_feed;
      io_order_data_rec.check_status := cn_check_status_error;
    END IF;
--
    -- ===============================
    -- �i�ڕs��v�`�F�b�N
    -- ===============================
    IF ( io_order_data_rec.shipping_item_code IS NULL ) THEN      
      lv_errmsg := lv_errmsg
                  || xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_appl_short_nm,
                      iv_name        => ct_msg_item_unmatch_err,
                      iv_token_name1 => cv_tkn_item_code,
                      iv_token_value1=> NVL( io_order_data_rec.child_item_code
                                              ,io_order_data_rec.item_code ),   -- �o�וi��
                      iv_token_name2 => cv_tkn_order_number,
                      iv_token_value2=> io_order_data_rec.order_number,         -- �󒍔ԍ�
                      iv_token_name3 => cv_tkn_line_number,
                      iv_token_value3=> io_order_data_rec.line_number,          -- �󒍖���
                      iv_token_name4 => cv_tkn_req_no,
                      iv_token_value4=> io_order_data_rec.packing_instructions  -- �˗�No
                    )
                  || cv_line_feed || cv_line_feed;
      io_order_data_rec.check_status := cn_check_status_error;
    END IF;
--
    IF ( io_order_data_rec.check_status = cn_check_status_error ) THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END check_data_row;
--
  /**********************************************************************************
   * Procedure Name   : check_request_target
   * Description      : �o�׈˗��Ώۃf�[�^�`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE check_request_target(
    ov_errbuf       OUT     VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT     VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT     VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_request_target'; -- �v���O������
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
    lv_key                VARCHAR2(100);    -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
    lv_bfr                VARCHAR2(100);    -- PL/SQL�\��1�O�̓Y����
    lv_now                VARCHAR2(100);    -- PL/SQL�\�̌��ݏ������̓Y����
    ln_base_quantity_sum  NUMBER;           -- �n�l�󒍂̈˗�No�^�i�ڂ̒P�ʂŃT�}���[���������
    lv_organization_code  VARCHAR2(100);    -- �݌ɑg�D�R�[�h
    lv_item_id            VARCHAR2(100);    -- �i�ڂh�c
    ln_organization_id    VARCHAR2(100);    -- �݌ɑg�D�h�c
    ln_content            NUMBER;           -- ���� 
    ld_inspect_date       xxcos_sales_exp_headers.inspect_date%TYPE;        -- �ŏI���������\���
    ld_request_date       xxcos_sales_exp_headers.delivery_date%TYPE;       -- �ŏI����[�i�\���
    lv_base_uom           xxcos_sales_exp_lines.standard_uom_code%TYPE;     -- ��P��
    ln_base_quantity      xxcos_sales_exp_lines.standard_qty%TYPE;          -- ����� 
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    TYPE quantity_rtype IS RECORD(
        inspect_date    xxcos_sales_exp_headers.inspect_date%TYPE     -- �����\���
      , request_date    xxcos_sales_exp_headers.delivery_date%TYPE    -- �[�i�\���
      , quantity_uom    xxcos_sales_exp_lines.standard_uom_code%TYPE  -- �󒍒P��
      , quantity        xxcos_sales_exp_lines.standard_qty%TYPE       -- �󒍐���
    );
    TYPE quantity_ttype IS TABLE OF quantity_rtype INDEX BY BINARY_INTEGER;
    -- �n�l�󒍂̈˗�No�^�i�ڂ̒P�ʂ�PL/SQL�\
    quantity_tab      quantity_ttype;   -- �T�}���[�Ώۃf�[�^�i�[�p�R���N�V�����ϐ�
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
    --====================================================================
    -- OM�󒍂̈˗�No�^�i�ڂ�P�ʂƂ�������ʂ̍��v�l���Z�o���A
    -- ���Y�̏o�׎��ѐ��ʂ���v����Ȃ�ΐ���A��v���Ȃ��Ȃ�΃G���[�Ƃ���
    --====================================================================
--
    -- ����f�[�^���g�p���āA�˗�No�^�i�ځ^�󒍖���ID�Ń\�[�g�ł���悤��PL/SQL�\���쐬����
    <<loop_make_req_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      IF ( g_order_data_tab(i).check_status = cn_check_status_normal ) THEN
        -- �\�[�g�p�̃L�[�ƂȂ�Y�����̐ݒ�
        lv_key := g_order_data_tab(i).request_no            -- �˗�No
               || g_order_data_tab(i).shipping_item_code    -- �i��
               || g_order_data_tab(i).line_id;              -- �󒍖���ID
        -- �쐬�����Y��������ɁA�˗�No�^�i�ځ^�󒍖���ID�Ń\�[�g�ł���悤�ɐV����PL/SQL�\���쐬
        g_order_req_tab( lv_key ) := g_order_data_tab(i);      
      END IF;
    END LOOP loop_make_req_data;
--
    -- �쐬���̎󒍃f�[�^���폜
    g_order_data_tab.DELETE;
--
    lv_now   := g_order_req_tab.first;  -- �쐬����PL/SQL�\�̎n�߂̃��R�[�h�̓Y�������擾
    lv_bfr   := NULL;                   -- ���ݏ�������PL/SQL�\��1�O�̃��R�[�h�̓Y�����̏�����
--
    -- �쐬����PL/SQL�\�̓Y������NULL�ɂȂ�܂Ń��[�v����
    WHILE lv_now IS NOT NULL LOOP
--
      -- �ȉ��̓��e���u���C�N����L�[�Ƃ���
      -- �E���ݏ�������PL/SQL�\��1�O�̃��R�[�h�̓Y������NULL
      -- �E���ݏ������̃��R�[�h��1�O�̃��R�[�h�̈˗�No�^�i�ڂ̒P�ʂ��قȂ�
      IF ( lv_bfr IS NULL )
          OR (  g_order_req_tab( lv_now ).request_no         != g_order_req_tab( lv_bfr ).request_no
             OR g_order_req_tab( lv_now ).shipping_item_code != g_order_req_tab( lv_bfr ).shipping_item_code) THEN
--
        -- �˗�No�^�i�ڂ̒P�ʂ̃f�[�^���擾
        SELECT
          NVL2( oola.attribute4, TRUNC(TO_DATE( oola.attribute4, cv_fmt_date_default )), NULL )
                                                                          AS inspect_date -- �����\���
        , TRUNC(oola.request_date)                                        AS request_date -- �[�i�\���
        , oola.order_quantity_uom                                         AS quantity_uom -- �󒍒P��
        , oola.ordered_quantity
          * DECODE( otta.order_category_code, ct_order_category, -1, 1 )  AS quantity     -- �󒍐���
        BULK COLLECT INTO
          quantity_tab
        FROM
          oe_order_headers_all      ooha  -- ��ͯ��
        , oe_order_lines_all        oola  -- �󒍖���
        , oe_transaction_types_all  otta  -- �󒍖��׎������
        , hz_cust_accounts          hca   -- �ڋqϽ�
        , xxcmm_cust_accounts       xca   -- �ڋq�ǉ����Ͻ�
        , mtl_secondary_inventories msi   -- �ۊǏꏊϽ�
        WHERE
            ooha.header_id            = oola.header_id                -- ��ͯ��.��ͯ��ID = �󒍖���.��ͯ��ID
        -- �󒍖���.��������ID���󒍖��׎������.�������ID
        AND oola.line_type_id         = otta.transaction_type_id
        AND ooha.org_id               = gn_org_id                     -- ��ͯ��.�g�DID = A-1�擾�̉c�ƒP��
        -- ��ͯ��.�ð�� IN ('BOOKED','CLOSED')
        AND ooha.flow_status_code    IN ( ct_hdr_status_booked, ct_hdr_status_closed )  
        AND ooha.sold_to_org_id       = hca.cust_account_id           -- ��ͯ��.�o�׌��ڋqID = �ڋqϽ�.�ڋqID
        AND ooha.sold_to_org_id       = xca.customer_id               -- ��ͯ��.�o�׌��ڋqID = �ڋq�ǉ����Ͻ�.�ڋqID
        AND oola.flow_status_code    != ct_ln_status_cancelled        -- �󒍖���.�ð�� != 'CANCELLED'
        AND oola.subinventory         = msi.secondary_inventory_name  -- �󒍖���.�ۊǏꏊ = �ۊǏꏊϽ�.�ۊǏꏊ����
        AND oola.ship_from_org_id     = msi.organization_id           -- �󒍖���.�o�׌��g�DID = �ۊǏꏊϽ�.�g�DID
        AND msi.attribute13           = gv_direct_ship_code           -- �ۊǏꏊϽ�.�ۊǏꏊ���� = '11':����
        AND oola.packing_instructions = g_order_req_tab( lv_now ).request_no                -- �˗�No
        AND NVL( oola.attribute6, oola.ordered_item )
            = NVL( g_order_req_tab( lv_now ).child_item_code, g_order_req_tab( lv_now ).item_code ) -- �i��
        ORDER BY
            ooha.header_id
          , oola.line_id;
--
        ln_base_quantity_sum := 0;              -- ����ʍ��v�̏�����
--
        -- �擾�����˗�No�^�i�ڂ̒P�ʂ�PL/SQL�\�̓Y������NULL�ɂȂ�܂Ń��[�v����
        FOR i IN 1..quantity_tab.COUNT LOOP
--
          --==================================
          -- ����ʎZ�o
          --==================================
          xxcos_common_pkg.get_uom_cnv(
              iv_before_uom_code    => quantity_tab(i).quantity_uom         --���Z�O�P�ʃR�[�h = �󒍒P��
            , in_before_quantity    => quantity_tab(i).quantity             --���Z�O����       = �󒍐���
            , iov_item_code         => g_order_req_tab( lv_now ).item_code  --�i�ڃR�[�h
            , iov_organization_code => lv_organization_code                 --�݌ɑg�D�R�[�h   = NULL
            , ion_inventory_item_id => lv_item_id                           --�i�ڂh�c         = NULL
            , ion_organization_id   => ln_organization_id                   --�݌ɑg�D�h�c     = NULL
            , iov_after_uom_code    => lv_base_uom                          --���Z��P�ʃR�[�h =>��P��
            , on_after_quantity     => ln_base_quantity                     --���Z�㐔��       =>�����
            , on_content            => ln_content                           --����
            , ov_errbuf             => lv_errbuf                            --�G���[�E���b�Z�[�W�G���[       #�Œ�#
            , ov_retcode            => lv_retcode                           --���^�[���E�R�[�h               #�Œ�#
            , ov_errmsg             => lv_errmsg                            --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
          );
--
          -- ����ʍ��v�̎Z�o
          ln_base_quantity_sum  := ln_base_quantity_sum + ln_base_quantity;
          -- �ŏI���������\���
          ld_inspect_date       := quantity_tab(i).inspect_date;
          -- �ŏI����[�i�\���
          ld_request_date       := quantity_tab(i).request_date;
--
        END LOOP;
--
        -- ���[�U�E�G���[���b�Z�[�W�̏�����
        lv_errmsg := NULL;
--
        -- ===============================
        -- 1.�������t�]�`�F�b�N
        -- ===============================
        -- �ŏI���������\����ƒ��ד����r
        IF ( ld_inspect_date IS NOT NULL AND ld_inspect_date < g_order_req_tab( lv_now ).arrival_date ) THEN
          lv_errmsg := lv_errmsg
                    || xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_nm,
                        iv_name        => ct_msg_reverse_date_err,
                        iv_token_name1 => cv_tkn_target_date,
                        iv_token_value1=> xxccp_common_pkg.get_msg(
                                              iv_application => cv_xxcos_appl_short_nm,
                                              iv_name        => cv_inspect_date
                                          ),
                        iv_token_name2 => cv_tkn_kdate,
                        iv_token_value2=> TO_CHAR(ld_inspect_date, cv_fmt_date),        -- �ŏI���������\���
                        iv_token_name3 => cv_tkn_sdate,
                        iv_token_value3=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date), -- ���ד�
                        iv_token_name4 => cv_tkn_order_number,
                        iv_token_value4=> g_order_req_tab( lv_now ).order_number,       -- �󒍔ԍ�
                        iv_token_name5 => cv_tkn_line_number,
                        iv_token_value5=> g_order_req_tab( lv_now ).line_number,        -- ���הԍ�
                        iv_token_name6 => cv_tkn_req_no,
                        iv_token_value6=> g_order_req_tab( lv_now ).request_no          -- �˗�No
                      )
                    || cv_line_feed;
          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
        END IF;    
--
        -- ===============================
        -- 2.�[�i���s��v�`�F�b�N
        -- ===============================
        -- �ŏI����[�i�\����ƒ��ד����r
        IF ( ld_request_date != g_order_req_tab( lv_now ).arrival_date ) THEN
          lv_errmsg := lv_errmsg
                    || xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_nm,
                        iv_name        => ct_msg_dlv_date_err,
                        iv_token_name1 => cv_tkn_req_no,
                        iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- �˗�No
                        iv_token_name2 => cv_tkn_item_code,
                        iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code, -- �i��
                        iv_token_name3 => cv_tkn_kdate,
                        iv_token_value3=> TO_CHAR(ld_request_date, cv_fmt_date),        -- �[�i��
                        iv_token_name4 => cv_tkn_sdate,
                        iv_token_value4=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)  -- ���ד�
                      )
                    || cv_line_feed;
          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
        END IF;
--
        -- ===============================
        -- 3.����ʕs��v�`�F�b�N
        -- ===============================
        -- �n�l�󒍂̊���ʂ̍��v�Ɛ��Y���̏o�׎��ѐ��ʂ��r
        IF ( g_order_req_tab( lv_now ).shipped_quantity != ln_base_quantity_sum ) THEN
          lv_errmsg := lv_errmsg
                    || xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_nm,
                        iv_name        => ct_msg_quantity_sum_err,
                        iv_token_name1 => cv_tkn_req_no,
                        iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- �˗�No
                        iv_token_name2 => cv_tkn_item_code,
                        iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code  -- �i��
                    )
                    || cv_line_feed;
          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
        END IF;
--
        IF ( lv_errmsg IS NOT NULL ) THEN
          --���b�Z�[�W�o��
          --��s�}��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg     --�G���[���b�Z�[�W
          );
        END IF;
--
      ELSE
        -- �����˗�No�^�i�ڒP�ʂ̃X�e�[�^�X�������p��
        g_order_req_tab( lv_now ).check_status := g_order_req_tab( lv_bfr ).check_status;
      END IF;
--
      lv_bfr := lv_now;                         -- ���ݏ������̃C���f�b�N�X��ۑ�����
      lv_now := g_order_req_tab.next( lv_now ); -- ���̃C���f�b�N�X���擾����i������������NULL���Ԃ����j
--
    END LOOP;
--
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
  END check_request_target;
--
  /**********************************************************************************
   * Procedure Name   : check_sales_exp_data
   * Description      : �̔����ђP�ʃf�[�^�`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE check_sales_exp_data(
    ov_errbuf       OUT     VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT     VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT     VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sales_exp_data'; -- �v���O������
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
    lv_key      VARCHAR2(100);    -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
    lv_bfr      VARCHAR2(100);    -- PL/SQL�\��1�O�̓Y����
    lv_now      VARCHAR2(100);    -- PL/SQL�\�̌��ݏ������̓Y����
    lv_break    VARCHAR2(100);    -- �̔����уw�b�_���쐬����P�ʂƂȂ�PL/SQL�\�̓Y����
    lv_del      VARCHAR2(100);    -- PL/SQL�\�̍폜�ΏۂƂȂ郌�R�[�h�̓Y����
    ln_err_flag NUMBER;           -- �G���[�t���O
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
--
    --==================================================================
    -- �̔����т̃w�b�_���쐬����P�ʂ̃G���[�`�F�b�N���s��
    -- ����f�[�^�݂̂̎󒍃f�[�^���쐬����
    --==================================================================
--
    --�̔����т̃w�b�_���쐬����P�ʂŃ\�[�g���\�ɂȂ�悤�Ƀf�[�^���쐬����
    --�̔����уw�b�_�̍쐬�P�ʁF�w�b�_ID�^�[�i���^������
    lv_now := g_order_req_tab.first;
--
    -- PL/SQL�\�̓Y������NULL�ɂȂ�܂Ń��[�v����
    WHILE lv_now IS NOT NULL LOOP
      -- �\�[�g�p�̃L�[�ƂȂ�Y�����̐ݒ�
      lv_key := g_order_req_tab( lv_now ).header_id                                     -- �󒍃w�b�_ID
             || TO_CHAR( g_order_req_tab( lv_now ).dlv_date,     ct_target_date_format) -- �[�i��
             || TO_CHAR( g_order_req_tab( lv_now ).inspect_date, ct_target_date_format) -- ������
             || TO_CHAR( g_order_req_tab( lv_now ).request_no )                         -- �˗�No
             || g_order_req_tab( lv_now ).line_id;                                      -- �󒍖���ID
      -- �쐬�����Y��������ɁA�̔����уw�b�_���쐬����P�ʂŃ\�[�g�ł���悤�ɐV����PL/SQL�\���쐬����
      g_order_exp_tab( lv_key ) := g_order_req_tab( lv_now );
      -- �������̃��R�[�h�̎��̃��R�[�h�̓Y�������擾����i���̃��R�[�h�������ꍇ��NULL���ݒ肳���j
      lv_now := g_order_req_tab.next( lv_now );
    END LOOP;
--
    -- �쐬���̎󒍃f�[�^���폜
    g_order_req_tab.DELETE;
--
    lv_now      := g_order_exp_tab.first;   -- �쐬����PL/SQL�\�̎n�߂̃��R�[�h�̓Y�������擾
    lv_bfr      := NULL;                    -- ���ݏ�������PL/SQL�\��1�O�̃��R�[�h�̓Y�����̏�����
    lv_break    := lv_now;                  -- �̔����уw�b�_���쐬����P�ʂƂȂ�n�߂�PL/SQL�\�̓Y������ݒ�
    ln_err_flag := cn_check_status_normal;  -- �̔����уw�b�_���쐬����P�ʓ��̃f�[�^�ɃG���[���ݒ肳��Ă����
                                            -- �t���O���G���[�ɂȂ�
--
    -- �쐬����PL/SQL�\�̓Y������NULL�ɂȂ�܂Ń��[�v����
    WHILE lv_now IS NOT NULL LOOP
--
      -- �ȉ��̓��e���u���C�N����L�[�Ƃ���
      -- �E���ݏ�������PL/SQL�\��1�O�̃��R�[�h�̓Y������NULL
      -- �E���ݏ������̃��R�[�h��1�O�̃��R�[�h�̔̔����уw�b�_���쐬����P�ʂ��قȂ�
      IF ( lv_bfr IS NULL )
        OR (   g_order_exp_tab( lv_now ).header_id     != g_order_exp_tab( lv_bfr ).header_id
            OR g_order_exp_tab( lv_now ).dlv_date      != g_order_exp_tab( lv_bfr ).dlv_date
            OR g_order_exp_tab( lv_now ).inspect_date  != g_order_exp_tab( lv_bfr ).inspect_date
            OR g_order_exp_tab( lv_now ).request_no    != g_order_exp_tab( lv_bfr ).request_no   ) THEN
--
        -- �̔����уw�b�_���쐬����P�ʓ��̃f�[�^�ɃG���[���ݒ肳��Ă��鎞��
        -- ���̒P�ʓ��̃f�[�^�̃X�e�[�^�X���G���[�ɂ���
        IF ( ln_err_flag = cn_check_status_error ) THEN
          -- PL/SQL�\�̓Y���������ݏ������̃f�[�^�̓Y�����ɂȂ�܂Ń��[�v����
          WHILE ( lv_break IS NOT NULL AND lv_now > lv_break ) LOOP
            lv_del := lv_break;                           -- �폜�ΏۂƂȂ郌�R�[�h�̓Y������ݒ�
            lv_break := g_order_exp_tab.next( lv_break ); -- �폜�ΏۂƂȂ郌�R�[�h�̎��̃��R�[�h�̓Y�������擾
            g_order_exp_tab.DELETE( lv_del );             -- �폜�ΏۂƂȂ郌�R�[�h���폜
            gn_warn_cnt := gn_warn_cnt + 1;
          END LOOP;       
          ln_err_flag := cn_check_status_normal;
        END IF;
--
        -- ���ݏ������̃��R�[�h�̓Y���������̃u���C�N�L�[�̈ʒu�ƂȂ�Y�����Ƃ��ĕێ�
        lv_break := lv_now;
      END IF;
--
      -- �������̃��R�[�h���G���[�̏ꍇ�A�G���[�t���O���G���[�ɐݒ肷��
      IF ( g_order_exp_tab( lv_now ).check_status = cn_check_status_error ) THEN
        ln_err_flag := cn_check_status_error;
      END IF;
--
      lv_bfr := lv_now;                         -- ���ݏ������̃C���f�b�N�X��ۑ�����
      lv_now := g_order_exp_tab.next( lv_now ); -- ���̃C���f�b�N�X���擾����i������������NULL���Ԃ����j
--
    END LOOP;
--
    IF ( ln_err_flag = cn_check_status_error ) THEN
      -- PL/SQL�\�̓Y���������ݏ������̃f�[�^�̓Y�����ɂȂ�܂Ń��[�v����
      WHILE ( lv_break IS NOT NULL ) LOOP
        lv_del := lv_break;                           -- �폜�ΏۂƂȂ郌�R�[�h�̓Y������ݒ�
        lv_break := g_order_exp_tab.next( lv_break ); -- �폜�ΏۂƂȂ郌�R�[�h�̎��̃��R�[�h�̓Y�������擾
        g_order_exp_tab.DELETE( lv_del );             -- �폜�ΏۂƂȂ郌�R�[�h���폜
        gn_warn_cnt := gn_warn_cnt + 1;
      END LOOP;
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
  END check_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : set_plsql_table
   * Description      : �̔�����PL/SQL�\�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE set_plsql_table(
    ov_errbuf           OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,                     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_plsql_table'; -- �v���O������
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
    cv_break_ok             CONSTANT NUMBER := 1;
    cv_break_ng             CONSTANT NUMBER := 0;
    -- *** ���[�J���ϐ� ***
    lv_hdr_key              VARCHAR2(100);    -- �̔����уw�b�_�p�L�[
    ln_header_seq           NUMBER;           -- �̔����уw�b�_ID
    ln_line_seq             NUMBER;           -- ���ׂ̃V�[�P���X
    ln_bfr_index            VARCHAR2(100);
    ln_now_index            VARCHAR2(100);
    ln_first_index          VARCHAR2(100);
    j                       NUMBER;           -- �̔����уw�b�_�̓Y����
    k                       NUMBER;           -- �̔����і��ׂ̓Y����
    lv_break                NUMBER;
    ln_tax_index            NUMBER;           -- �w�b�_�P�ʂ̖��ׂň�ԋ��z���傫�����R�[�h�̓Y����
    ln_tax_amount           NUMBER;           -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
    ln_max_amount           NUMBER;           -- �w�b�_�P�ʂ̈�ԑ傫�����z
    ln_diff_amount          NUMBER;           -- �w�b�_�P�ʂ̏���ŋ��z�Ɩ��גP�ʂ̏���ł̍��v�̍��z
/* 2009/06/09 Ver1.9 Add Start */
    ln_tax_amount_sum       NUMBER;           -- �w�b�_�P�ʂ̏���ŋ��z�v�Z�p(�����_�l��)
/* 2009/06/09 Ver1.9 Add End   */
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    j := 0;                         -- �̔����уw�b�_�̓Y����
    k := 0;                         -- �̔����і��ׂ̓Y����
    ln_tax_amount := 0;             -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
--
    IF g_order_exp_tab.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_order_exp_tab.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      IF ( ln_first_index = ln_now_index ) THEN
        lv_break := cv_break_ok;
      ELSIF ( g_order_exp_tab( ln_now_index ).header_id    != g_order_exp_tab( ln_bfr_index ).header_id
           OR g_order_exp_tab( ln_now_index ).dlv_date     != g_order_exp_tab( ln_bfr_index ).dlv_date
           OR g_order_exp_tab( ln_now_index ).inspect_date != g_order_exp_tab( ln_bfr_index ).inspect_date
           OR g_order_exp_tab( ln_now_index ).request_no   != g_order_exp_tab( ln_bfr_index ).request_no  ) THEN
--
        -- �O�łƓ���(�`�[�ې�)�͖{�̋��z���v�������ŋ��z���v���Z�o����
        IF ( g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
          OR g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
          ln_tax_amount_sum := 0;  --������
--
          -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
--          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
          ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/09 Ver1.9 Mod End   */
/* 2009/05/20 Ver1.7 Add Start */
          --�؏�
          IF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
            -- �����_�ȉ������݂���ꍇ
--            IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
            IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
--
              -- �ԕi(���ʂ��}�C�i�X)�ȊO�̏ꍇ
--              IF ( SIGN( g_sale_hdr_tab(j).tax_amount_sum ) <> -1 ) THEN
              IF ( SIGN( ln_tax_amount_sum ) <> -1 ) THEN
--
--                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) + 1;
                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) + 1;
--
              -- �ԕi(���ʂ��}�C�i�X)�̏ꍇ
              ELSE
--
--                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
--
              END IF;
--
            --�����_�ȉ������݂��Ȃ��ꍇ
            ELSE
--
              g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
--
            END IF;
--
          --�؎̂�
          ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
--
          --�l�̌ܓ�
          ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
            g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
--
          END IF;
/* 2009/05/20 Ver1.7 Add End */
/* 2009/06/09 Ver1.9 Mod End */
        ELSE
          -- ����ŋ��z���v �� ������z���v �| �{�̋��z���v
          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
        END IF;
/* 2009/05/20 Ver1.7 Del Start */
        -- ����ŋ��z���v���l�̌ܓ��i�[���Ȃ��j
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);        
/* 2009/05/20 Ver1.7 Del End   */
        -- ���z�� ��  �w�b�_�P�ʂ̏���ŋ��z �| ���ׂ̏���ŋ��z�̐ςݏグ���v���z
        ln_diff_amount := g_sale_hdr_tab(j).tax_amount_sum - ln_tax_amount;
        -- ����ŋ��z �� ����ŋ��z �| ���z
        g_sale_line_tab(ln_tax_index).tax_amount := g_sale_line_tab(ln_tax_index).tax_amount + ln_diff_amount;
--           
        lv_break := cv_break_ok;
      ELSE
        lv_break := cv_break_ng;
      END IF;
--
      IF ( lv_break = cv_break_ok ) THEN
--
        j := j + 1;
--
        SELECT
          xxcos_sales_exp_headers_s01.nextval
        INTO
          ln_header_seq
        FROM
          DUAL;
--
        --�̔����уw�b�_�pPL/SQL�\�쐬
        -- �̔����уw�b�_ID
        g_sale_hdr_tab(j).sales_exp_header_id         := ln_header_seq;
        -- �[�i�`�[�ԍ�
        g_sale_hdr_tab(j).dlv_invoice_number          := g_order_exp_tab(ln_now_index).dlv_invoice_number;
        -- �����`�[�ԍ�
        g_sale_hdr_tab(j).order_invoice_number        := g_order_exp_tab(ln_now_index).order_invoice_number;
        -- �󒍔ԍ�
        g_sale_hdr_tab(j).order_number                := g_order_exp_tab(ln_now_index).order_number;
        -- ��No�iHHT)
        g_sale_hdr_tab(j).order_no_hht                := g_order_exp_tab(ln_now_index).order_no_hht;
        -- ��No�iHHT�j�}��
        g_sale_hdr_tab(j).digestion_ln_number         := g_order_exp_tab(ln_now_index).order_no_hht_seq;
        -- �󒍊֘A�ԍ�
        g_sale_hdr_tab(j).order_connection_number     := g_order_exp_tab(ln_now_index).order_connection_number;
        -- �[�i�`�[�敪
        g_sale_hdr_tab(j).dlv_invoice_class           := g_order_exp_tab(ln_now_index).dlv_invoice_class;
        -- ����E�����敪
        g_sale_hdr_tab(j).cancel_correct_class        := g_order_exp_tab(ln_now_index).cancel_correct_class;
        -- ���͋敪
        g_sale_hdr_tab(j).input_class                 := g_order_exp_tab(ln_now_index).input_class;
        -- �Ƒԏ�����
        g_sale_hdr_tab(j).cust_gyotai_sho             := g_order_exp_tab(ln_now_index).cust_gyotai_sho;
        -- �[�i��
        g_sale_hdr_tab(j).delivery_date               := g_order_exp_tab(ln_now_index).dlv_date;
        -- �I���W�i���[�i��
        g_sale_hdr_tab(j).orig_delivery_date          := g_order_exp_tab(ln_now_index).org_dlv_date;
        -- ������
        g_sale_hdr_tab(j).inspect_date                := g_order_exp_tab(ln_now_index).inspect_date;
        -- �I���W�i��������
        g_sale_hdr_tab(j).orig_inspect_date           := g_order_exp_tab(ln_now_index).orig_inspect_date;
        -- �ڋq�y�[�i��z
        g_sale_hdr_tab(j).ship_to_customer_code       := g_order_exp_tab(ln_now_index).ship_to_customer_code;
        -- ����ŋ敪
        g_sale_hdr_tab(j).consumption_tax_class       := g_order_exp_tab(ln_now_index).consumption_tax_class;
        -- �ŋ��R�[�h
        g_sale_hdr_tab(j).tax_code                    := g_order_exp_tab(ln_now_index).tax_code;
        -- ����ŗ�
        g_sale_hdr_tab(j).tax_rate                    := g_order_exp_tab(ln_now_index).tax_rate;
        -- ���ьv��҃R�[�h
        g_sale_hdr_tab(j).results_employee_code       := g_order_exp_tab(ln_now_index).results_employee_code;
        -- ���㋒�_�R�[�h
        g_sale_hdr_tab(j).sales_base_code             := g_order_exp_tab(ln_now_index).sale_base_code;
        -- �������_�R�[�h
        g_sale_hdr_tab(j).receiv_base_code            := g_order_exp_tab(ln_now_index).receiv_base_code;
        -- �󒍃\�[�XID
        g_sale_hdr_tab(j).order_source_id             := g_order_exp_tab(ln_now_index).order_source_id;
        -- �J�[�h����敪
        g_sale_hdr_tab(j).card_sale_class             := g_order_exp_tab(ln_now_index).card_sale_class;
        -- �`�[�敪
        g_sale_hdr_tab(j).invoice_class               := g_order_exp_tab(ln_now_index).invoice_class;
        -- �`�[���ރR�[�h
        g_sale_hdr_tab(j).invoice_classification_code := g_order_exp_tab(ln_now_index).big_classification_code;
        -- ��K�؂ꎞ�ԂP�O�O�~
        g_sale_hdr_tab(j).change_out_time_100         := g_order_exp_tab(ln_now_index).change_out_time_100;
        -- ��K�؂ꎞ�ԂP�O�~
        g_sale_hdr_tab(j).change_out_time_10          := g_order_exp_tab(ln_now_index).change_out_time_10;
        -- AR�C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).ar_interface_flag           := g_order_exp_tab(ln_now_index).ar_interface_flag;
        -- GL�C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).gl_interface_flag           := g_order_exp_tab(ln_now_index).gl_interface_flag;
        -- ���V�X�e���C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).dwh_interface_flag          := g_order_exp_tab(ln_now_index).dwh_interface_flag;
        -- EDI���M�ς݃t���O
        g_sale_hdr_tab(j).edi_interface_flag          := g_order_exp_tab(ln_now_index).edi_interface_flag;
        -- EDI���M����
        g_sale_hdr_tab(j).edi_send_date               := g_order_exp_tab(ln_now_index).edi_send_date;
        -- HHT�[�i���͓���
        g_sale_hdr_tab(j).hht_dlv_input_date          := g_order_exp_tab(ln_now_index).hht_dlv_input_date;
        -- �[�i�҃R�[�h
        g_sale_hdr_tab(j).dlv_by_code                 := g_order_exp_tab(ln_now_index).dlv_by_code;
        -- �쐬���敪
        g_sale_hdr_tab(j).create_class                := g_order_exp_tab(ln_now_index).create_class;
        -- �o�^�Ɩ����t
        g_sale_hdr_tab(j).business_date               := gd_business_date;
        -- �쐬��
        g_sale_hdr_tab(j).created_by                  := cn_created_by;
        -- �쐬��
        g_sale_hdr_tab(j).creation_date               := cd_creation_date;
        -- �ŏI�X�V��
        g_sale_hdr_tab(j).last_updated_by             := cn_last_updated_by;
        -- �ŏI�X�V��
        g_sale_hdr_tab(j).last_update_date            := cd_last_update_date;
        -- �ŏI�X�V۸޲�
        g_sale_hdr_tab(j).last_update_login           := cn_last_update_login;
        -- �v��ID
        g_sale_hdr_tab(j).request_id                  := cn_request_id;
        -- �ݶ��ĥ��۸��ѥ���ع����ID
        g_sale_hdr_tab(j).program_application_id      := cn_program_application_id;
        -- �ݶ��ĥ��۸���ID
        g_sale_hdr_tab(j).program_id                  := cn_program_id;
        -- ��۸��эX�V��
        g_sale_hdr_tab(j).program_update_date         := cd_program_update_date;
--
        -- ������z
        g_sale_hdr_tab(j).sale_amount_sum   := 0;   -- ������z���v
        -- �{�̋��z
        g_sale_hdr_tab(j).pure_amount_sum   := 0;   -- �{�̋��z���v
        -- ����ŋ��z
        g_sale_hdr_tab(j).tax_amount_sum    := 0;   -- ����ŋ��z���v
--
        -- �w�b�_���쐬����n�߂̃��R�[�h�̖{�̋��z��ێ�����
        ln_max_amount := g_order_exp_tab(ln_now_index).pure_amount;
--
        -- �w�b�_�P�ʂ̍ő�{�̋��z�̃��R�[�h�̓Y������ێ�
        ln_tax_index := k + 1;
--
        -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
        ln_tax_amount := 0;
--
      END IF;
--
      k := k + 1;
--
      SELECT
        xxcos_sales_exp_lines_s01.nextval
      INTO
        ln_line_seq
      FROM
        DUAL;
--
      --�̔����і��חpPL/SQL�\�쐬
      -- �̔����і���ID
      g_sale_line_tab(k).sales_exp_line_id           := ln_line_seq;
      -- �̔����уw�b�_ID
      g_sale_line_tab(k).sales_exp_header_id         := ln_header_seq;
      -- �[�i�`�[�ԍ�
      g_sale_line_tab(k).dlv_invoice_number          := g_order_exp_tab(ln_now_index).dlv_invoice_number;
      -- �[�i���הԍ�
      g_sale_line_tab(k).dlv_invoice_line_number     := g_order_exp_tab(ln_now_index).dlv_invoice_line_number;
      -- �������הԍ�
      g_sale_line_tab(k).order_invoice_line_number   := g_order_exp_tab(ln_now_index).order_invoice_line_number;
      -- ����敪
      g_sale_line_tab(k).sales_class                 := g_order_exp_tab(ln_now_index).sales_class;
      -- �[�i�`�ԋ敪
      g_sale_line_tab(k).delivery_pattern_class      := g_order_exp_tab(ln_now_index).delivery_pattern_class;
      -- �ԍ��t���O
      g_sale_line_tab(k).red_black_flag              := g_order_exp_tab(ln_now_index).red_black_flag;
      -- �i�ڃR�[�h
      g_sale_line_tab(k).item_code                   := g_order_exp_tab(ln_now_index).item_code;
      -- �󒍐���
      g_sale_line_tab(k).dlv_qty                     := g_order_exp_tab(ln_now_index).ordered_quantity;
      -- �����
      g_sale_line_tab(k).standard_qty                := g_order_exp_tab(ln_now_index).base_quantity;
      -- �󒍒P��
      g_sale_line_tab(k).dlv_uom_code                := g_order_exp_tab(ln_now_index).order_quantity_uom;
      -- ��P��
      g_sale_line_tab(k).standard_uom_code           := g_order_exp_tab(ln_now_index).base_uom;
      -- �̔��P��
      g_sale_line_tab(k).dlv_unit_price              := g_order_exp_tab(ln_now_index).unit_selling_price;
      -- �Ŕ���P��
      g_sale_line_tab(k).standard_unit_price_excluded:= g_order_exp_tab(ln_now_index).standard_unit_price;
      -- ��P��
      g_sale_line_tab(k).standard_unit_price         := g_order_exp_tab(ln_now_index).base_unit_price;
      -- �c�ƌ���
      g_sale_line_tab(k).business_cost               := g_order_exp_tab(ln_now_index).business_cost;
      -- ������z
      g_sale_line_tab(k).sale_amount                 := g_order_exp_tab(ln_now_index).sale_amount;
      -- �{�̋��z
      g_sale_line_tab(k).pure_amount                 := g_order_exp_tab(ln_now_index).pure_amount;
      -- ����ŋ��z
      g_sale_line_tab(k).tax_amount                  := g_order_exp_tab(ln_now_index).tax_amount;
      -- �����E�J�[�h���p�z
      g_sale_line_tab(k).cash_and_card               := g_order_exp_tab(ln_now_index).cash_and_card;
      -- �o�׌��ۊǏꏊ
      g_sale_line_tab(k).ship_from_subinventory_code := g_order_exp_tab(ln_now_index).ship_from_subinventory_code;
      -- �[�i���_�R�[�h
      g_sale_line_tab(k).delivery_base_code          := g_order_exp_tab(ln_now_index).delivery_base_code;
      -- �g���b
      g_sale_line_tab(k).hot_cold_class              := g_order_exp_tab(ln_now_index).hot_cold_class;
      -- �R����No
      g_sale_line_tab(k).column_no                   := g_order_exp_tab(ln_now_index).column_no;
      -- ���؋敪
      g_sale_line_tab(k).sold_out_class              := g_order_exp_tab(ln_now_index).sold_out_class;
      -- ���؎���
      g_sale_line_tab(k).sold_out_time               := g_order_exp_tab(ln_now_index).sold_out_time;
      -- �萔���v�Z�C���^�t�F�[�X�σt���O
      g_sale_line_tab(k).to_calculate_fees_flag      := g_order_exp_tab(ln_now_index).to_calculate_fees_flag;
      -- �P���}�X�^�쐬�σt���O
      g_sale_line_tab(k).unit_price_mst_flag         := g_order_exp_tab(ln_now_index).unit_price_mst_flag;
      -- INV�C���^�t�F�[�X�σt���O
      g_sale_line_tab(k).inv_interface_flag          := g_order_exp_tab(ln_now_index).inv_interface_flag;
      -- �쐬��
      g_sale_line_tab(k).created_by                  := cn_created_by;
      -- �쐬��
      g_sale_line_tab(k).creation_date               := cd_creation_date;
      -- �ŏI�X�V��
      g_sale_line_tab(k).last_updated_by             := cn_last_updated_by;
      -- �ŏI�X�V��
      g_sale_line_tab(k).last_update_date            := cd_last_update_date;
      -- �ŏI�X�V۸޲�
      g_sale_line_tab(k).last_update_login           := cn_last_update_login;
      -- �v��ID
      g_sale_line_tab(k).request_id                  := cn_request_id;
      -- �ݶ��ĥ��۸��ѥ���ع����ID
      g_sale_line_tab(k).program_application_id      := cn_program_application_id;
      -- �ݶ��ĥ��۸���ID
      g_sale_line_tab(k).program_id                  := cn_program_id;
      -- ��۸��эX�V��
      g_sale_line_tab(k).program_update_date         := cd_program_update_date;
--
      -- ������z
      g_sale_hdr_tab(j).sale_amount_sum   := g_sale_hdr_tab(j).sale_amount_sum
                                            + g_order_exp_tab(ln_now_index).sale_amount;-- ������z���v
      -- �{�̋��z
      g_sale_hdr_tab(j).pure_amount_sum   := g_sale_hdr_tab(j).pure_amount_sum
                                            + g_order_exp_tab(ln_now_index).pure_amount;-- �{�̋��z���v
      -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
      ln_tax_amount := ln_tax_amount + g_order_exp_tab(ln_now_index).tax_amount;
--
--
/* 2009/05/20 Ver1.7 Mod Start */
      -- ���ݏ������̔̔����і��ׂ̖{�̋��z���A�w�b�_�P�ʂ̖��ד������z��������
--      IF ( g_sale_line_tab(k).pure_amount > ln_max_amount ) THEN
      IF ( ABS( g_sale_line_tab(k).pure_amount ) > ABS( ln_max_amount ) ) THEN
/* 2009/05/20 Ver1.7 Mod End   */
        -- �w�b�_�P�ʂ̖{�̋��z��ێ�
        ln_max_amount := g_sale_line_tab(k).pure_amount;
        -- �w�b�_�P�ʂ̍ő�{�̋��z�̃��R�[�h�̓Y������ێ�
        ln_tax_index := k;
      END IF;
--
      -- ���ݏ������̃C���f�b�N�X��ۑ�����
      ln_bfr_index := ln_now_index;
--
      -- ���̃C���f�b�N�X���擾����
      ln_now_index := g_order_exp_tab.next( ln_now_index );
--      
    END LOOP;
--
    -- �O�łƓ���(�`�[�ې�)�͖{�̋��z���v�������ŋ��z���v���Z�o����
    IF ( g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
      OR g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
      ln_tax_amount_sum := 0;  --������
      -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
--      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
      ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/09 Ver1.9 Mod End   */
/* 2009/05/20 Ver1.7 Add Start */
      --�؏�
      IF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
/* 2009/06/09 Ver1.9 Mod Start */
        -- �����_�ȉ������݂���ꍇ
--        IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
        IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
          -- �ԕi(���ʂ��}�C�i�X)�ȊO�̏ꍇ
--          IF ( SIGN( g_sale_hdr_tab(j).tax_amount_sum ) <> -1 ) THEN
          IF ( SIGN( ln_tax_amount_sum ) <> -1 ) THEN
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) + 1;
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) + 1;
          -- �ԕi(���ʂ��}�C�i�X)�̏ꍇ
          ELSE
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
          END IF;
        --�����_�ȉ������݂��Ȃ��ꍇ
        ELSE
          g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
        END IF;
      --�؎̂�
      ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
      --�l�̌ܓ�
      ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
        g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
      END IF;
/* 2009/05/20 Ver1.7 Add End */
/* 2009/06/09 Ver1.9 Mod End */
    ELSE
      -- ����ŋ��z���v �� ������z���v �| �{�̋��z���v
      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
    END IF;
/* 2009/05/20 Ver1.7 Del Start */
    -- ����ŋ��z���v���l�̌ܓ��i�[���Ȃ��j
--    g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);  
/* 2009/05/20 Ver1.7 Del End   */
    -- ���z�� ��  �w�b�_�P�ʂ̏���ŋ��z �| ���ׂ̏���ŋ��z�̐ςݏグ���v���z
    ln_diff_amount := g_sale_hdr_tab(j).tax_amount_sum - ln_tax_amount;
    -- ����ŋ��z �� ����ŋ��z �| ���z
    g_sale_line_tab(ln_tax_index).tax_amount := g_sale_line_tab(ln_tax_index).tax_amount + ln_diff_amount;
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
  END set_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : make_sales_exp_lines
   * Description      : �̔����і��׍쐬(A-9)
   ***********************************************************************************/
  PROCEDURE make_sales_exp_lines(
    ov_errbuf           OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,                     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sales_exp_lines'; -- �v���O������
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
    lv_table_name VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
      FORALL i in 1..g_sale_line_tab.COUNT
      INSERT INTO xxcos_sales_exp_lines VALUES g_sale_line_tab(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --��������
    gn_normal_line_cnt := g_sale_line_tab.COUNT;
--
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_line_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_table_name,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END make_sales_exp_lines;
--
  /**********************************************************************************
   * Procedure Name   : make_sales_exp_headers
   * Description      : �̔����уw�b�_�쐬(A-10)
   ***********************************************************************************/
  PROCEDURE make_sales_exp_headers(
    ov_errbuf           OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,                     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sales_exp_headers'; -- �v���O������
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
    lv_table_name VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
      --�̔����уw�b�_�̍쐬
      FORALL i in 1..g_sale_hdr_tab.COUNT
      INSERT INTO xxcos_sales_exp_headers VALUES g_sale_hdr_tab(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --��������
    gn_normal_header_cnt := g_sale_hdr_tab.COUNT;
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_header_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_table_name,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END make_sales_exp_headers;
--
  /**********************************************************************************
   * Procedure Name   : set_order_line_close_status
   * Description      : �󒍖��׃N���[�Y�ݒ�(A-11)
   ***********************************************************************************/
  PROCEDURE set_order_line_close_status(
    ov_errbuf         OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_line_close_status'; -- �v���O������
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
    lv_api_name   VARCHAR2(100);
/* 2009/07/09 Ver1.11 Mod Start */
--    ln_now_index  VARCHAR2(100);
    ln_now_index   PLS_INTEGER;
    lt_line_number oe_order_lines_all.line_number%TYPE;
/* 2009/07/09 Ver1.11 Mod End   */
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
--
/* 2009/07/09 Ver1.11 Mod Start */
--    ln_now_index := g_order_exp_tab.first;
--
--    WHILE ln_now_index IS NOT NULL LOOP
    <<loop_line_update>>
    FOR ln_now_index IN 1..g_line_id_tab.COUNT LOOP
/* 2009/07/09 Ver1.11 Mod End   */
--
      BEGIN
        WF_ENGINE.COMPLETEACTIVITY(
            Itemtype => cv_close_type
/* 2009/07/09 Ver1.11 Mod Start */
--          , Itemkey  => g_order_exp_tab(ln_now_index).line_id  -- �󒍖���ID
          , Itemkey  => g_line_id_tab(ln_now_index).line_id  -- �󒍖���ID
/* 2009/07/09 Ver1.11 Mod End   */
          , Activity => cv_activity
          , Result   => cv_result
        );
--
/* 2009/07/09 Ver1.11 Del Start */
--        -- ���̃C���f�b�N�X���擾����
--        ln_now_index := g_order_exp_tab.next(ln_now_index);
--
/* 2009/07/09 Ver1.11 Del End   */
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
/* 2009/07/09 Ver1.11 Add Start */
          lt_line_number := g_line_id_tab(ln_now_index).line_number;
/* 2009/07/09 Ver1.11 Add End   */
          RAISE global_api_err_expt;
      END;
--
/* 2009/07/09 Ver1.11 Mod Start */
--    END LOOP;
    END LOOP loop_line_update;
/* 2009/07/09 Ver1.11 Mod End   */
--
/* 2009/07/09 Ver1.11 Add Start */
    --�󒍖��׃N���[�Y����
    gn_line_close_cnt := g_line_id_tab.COUNT;
--
/* 2009/07/09 Ver1.11 Add End   */
  EXCEPTION
--
    --*** API�Ăяo����O�n���h�� ***
    WHEN global_api_err_expt THEN
      lv_api_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_api_name
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_api_err,
                   iv_token_name1 => cv_tkn_api_name,
                   iv_token_value1=> lv_api_name,
                   iv_token_name2 => cv_tkn_err_msg,
                   iv_token_value2=> lv_errmsg,
                   iv_token_name3 => cv_tkn_line_number,
/* 2009/07/09 Ver1.11 Mod Start */
--                   iv_token_value3=> g_order_exp_tab(ln_now_index).line_number
                   iv_token_value3=> TO_CHAR(lt_line_number)
/* 2009/07/09 Ver1.11 Mod End   */
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
  END set_order_line_close_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date  IN      VARCHAR2,     -- �������t
    ov_errbuf       OUT     VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT     VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT     VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx                    NUMBER;       -- �̔����уw�b�_���쐬����P�ʂ̎󒍃f�[�^�R���N�V�����̓Y��
    ln_err_flag               NUMBER;       -- �̔����уw�b�_���쐬����P�ʂ̃f�[�^�ɃG���[�����邩���f����t���O
                                            -- �l�́A���[�U�[��`�O���[�o���萔�̃f�[�^�`�F�b�N�X�e�[�^�X�l�Ɉˑ�����
    lv_idx_key                VARCHAR2(100);-- PL/SQL�\�\�[�g�p�C���f�b�N�X������
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_normal_header_cnt := 0;
    gn_normal_line_cnt   := 0;
/* 2009/07/09 Ver1.11 Add Start */
    gn_line_close_cnt    := 0;
/* 2009/07/09 Ver1.11 Add End   */
--
    ln_err_flag := cn_check_status_normal;
--
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
        iv_target_date          =>  iv_target_date      -- �������t
      , ov_errbuf               =>  lv_errbuf           -- �G���[�E���b�Z�[�W
      , ov_retcode              =>  lv_retcode          -- ���^�[���E�R�[�h
      , ov_errmsg               =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�v���t�@�C���l�擾
    -- ===============================
    set_profile(
        ov_errbuf               =>  lv_errbuf           -- �G���[�E���b�Z�[�W
      , ov_retcode              =>  lv_retcode          -- ���^�[���E�R�[�h
      , ov_errmsg               =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.�󒍃f�[�^�擾
    -- ===============================
    get_order_data(
        ov_errbuf               =>  lv_errbuf           -- �G���[�E���b�Z�[�W
      , ov_retcode              =>  lv_retcode          -- ���^�[���E�R�[�h
      , ov_errmsg               =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_no_data_warm_expt;
    END IF;
--
/* 2009/07/09 Ver1.11 Add Start */
    --������
    gn_seq_1 := 0;
    gn_seq_2 := 0;
    --�̔����э쐬�Ώ۔���`�F�b�N
    <<loop_make_check_data>>
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
      IF ( NVL( g_order_data_all_tab(i).info_class, cv_target_order_01 ) <> cv_target_order_02 ) THEN
        gn_seq_1 := gn_seq_1 + 1;
        --�̔����э쐬�Ώ�
        g_order_data_tab(gn_seq_1) := g_order_data_all_tab(i);
      ELSE
        gn_seq_2 := gn_seq_2 + 1;
        --�󒍃N���[�Y�p�̕ϐ��̕ҏW(�󒍃N���[�Y�̂ݍs���f�[�^)
        g_line_id_tab(gn_seq_2).line_id     := g_order_data_all_tab(i).line_id;
        g_line_id_tab(gn_seq_2).line_number := g_order_data_all_tab(i).line_number;
      END IF;
    END LOOP loop_make_check_data;
--
/* 2009/07/09 Ver1.11 Add End   */
    ln_err_flag := cn_check_status_normal;
--
    <<loop_make_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
--
      --�̔����уw�b�_�쐬�P�ʃ`�F�b�N
      IF ( (i = 1) OR (   g_order_data_tab(i).header_id    != g_order_data_tab(i-1).header_id
                       OR g_order_data_tab(i).dlv_date     != g_order_data_tab(i-1).dlv_date
                       OR g_order_data_tab(i).inspect_date != g_order_data_tab(i-1).inspect_date
                       OR g_order_data_tab(i).request_no   != g_order_data_tab(i-1).request_no ) ) THEN
--
        --�̔����уw�b�_���쐬����P�ʂ̃f�[�^�ɃG���[������ꍇ�A
        --�R���N�V�������œ����P�ʂ̃f�[�^�ɑ΂��Ă��`�F�b�N�X�e�[�^�X���G���[�ɂ���
        IF ( ln_err_flag = cn_check_status_error ) THEN
--
          <<loop_set_check_status>>
          FOR k IN ln_idx..(i - 1) LOOP
            g_order_data_tab(k).check_status := cn_check_status_error;
            gn_warn_cnt := gn_warn_cnt + 1;
          END LOOP loop_set_check_status;
--
          ln_err_flag := cn_check_status_normal;
        END IF;
--
        ln_idx := i;
--
      END IF;
--
      -- ===============================
      -- A-4.���ڕҏW
      -- ===============================
      edit_item(
          g_order_data_tab(i) -- �󒍃f�[�^���R�[�h
        , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        --���b�Z�[�W�o��
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg     --�G���[���b�Z�[�W
        );
      END IF;
--
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================
        -- A-5.�f�[�^�`�F�b�N
        -- ===============================
        check_data_row(
            g_order_data_tab(i) -- �󒍃f�[�^���R�[�h
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --���b�Z�[�W�o��
          --��s�}��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg     --�G���[���b�Z�[�W
          );
        END IF;
      END IF;
--
      IF ( g_order_data_tab(i).check_status = cn_check_status_error ) THEN
        ln_err_flag := cn_check_status_error;
      END IF;
--
--
    END LOOP loop_make_data;
--
--
    --�̔����уw�b�_���쐬����P�ʂ̃f�[�^�ɃG���[������ꍇ�A
    --�R���N�V�������œ����P�ʂ̃f�[�^�ɑ΂��Ă��`�F�b�N�X�e�[�^�X���G���[�ɂ���
    IF ( ln_err_flag = cn_check_status_error ) THEN
      <<loop_set_check_status>>
      FOR k IN ln_idx..g_order_data_tab.COUNT LOOP
        g_order_data_tab(k).check_status := cn_check_status_error;
        gn_warn_cnt := gn_warn_cnt + 1;
      END LOOP loop_set_check_status;
    END IF;
--
    IF ( g_order_data_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-6.�o�׈˗��Ώۃf�[�^�`�F�b�N
      -- ===============================
      check_request_target(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( g_order_req_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-7.�̔����ђP�ʃf�[�^�`�F�b�N
      -- ===============================
      check_sales_exp_data(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( g_order_exp_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-8.�̔�����PL/SQL�\�쐬
      -- ===============================
      set_plsql_table(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.�̔����і��׍쐬
      -- ===============================
      make_sales_exp_lines(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-10.�̔����уw�b�_�쐬
      -- ===============================
      make_sales_exp_headers(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
/* 2009/07/09 Ver1.11 Add Start */
    END IF;
--
    lv_idx_key := g_order_exp_tab.first;
--
    --�󒍃N���[�Y�p�̕ϐ��̕ҏW(�̔����э쐬�f�[�^)
    WHILE lv_idx_key IS NOT NULL LOOP
      gn_seq_2 := gn_seq_2 + 1;
      g_line_id_tab(gn_seq_2).line_id     := g_order_exp_tab(lv_idx_key).line_id;
      g_line_id_tab(gn_seq_2).line_number := g_order_exp_tab(lv_idx_key).line_number;
      --���̃C���f�b�N�X���擾����
      lv_idx_key := g_order_exp_tab.next(lv_idx_key);
    END LOOP;
--
    --�󒍃N���[�Y�p�̕ϐ��ɒl������ꍇ�A�󒍃N���[�Y���������s
    IF ( g_line_id_tab.COUNT <> 0 ) THEN
/* 2009/07/09 Ver1.11 Add End   */
      -- ===============================
      -- A-11.�󒍃N���[�Y�ݒ�
      -- ===============================
      set_order_line_close_status(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �G���[�f�[�^������ꍇ�A�x���I���Ƃ���
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�����G���[��O�n���h�� ***
    WHEN global_no_data_warm_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    errbuf          OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT     VARCHAR2,   -- ���^�[���E�R�[�h    --# �Œ� #
    iv_target_date  IN      VARCHAR2    -- �������t
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_target_date  -- �������t
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode != cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        gn_normal_header_cnt := 0;
        gn_normal_line_cnt   := 0;
/* 2009/07/09 Ver1.11 Add Start */
        gn_line_close_cnt    := 0;
/* 2009/07/09 Ver1.11 Add End   */
        gn_error_cnt  := gn_target_cnt;
        gn_warn_cnt   := 0;
      END IF;
--
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --���������o��
    --�w�b�_
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_hdr_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_header_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --����
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_lin_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_line_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/07/09 Ver1.11 Add Start */
--
    --�󒍖��׃N���[�Y�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_close_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_line_close_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/07/09 Ver1.11 Add End   */
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
    --�x�������o��
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
--
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
--
END XXCOS008A02C;
/
