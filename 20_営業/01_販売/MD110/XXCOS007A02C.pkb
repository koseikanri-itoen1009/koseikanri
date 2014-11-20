CREATE OR REPLACE PACKAGE BODY APPS.XXCOS007A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS007A02C (body)
 * Description      : �ԕi�\����̓����������_�o�ׂ̕ԕi�󒍂ɑ΂��Ĕ̔����т��쐬���A
 *                    �̔����т��쐬�����󒍂��N���[�Y���܂��B
 * MD.050           : �ԕi���уf�[�^�쐬�i�g�g�s�ȊO�j  MD050_COS_007_A02
 * Version          : 1.17
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  set_gen_err_list       �ėp�G���[���X�g�o�͏��ݒ�
 *  init                   (A-1)��������
 *  set_profile            (A-2)�v���t�@�C���l�擾
 *  get_order_data         (A-3)�󒍃f�[�^�擾
 *  get_fiscal_period_from (A-4-1)�L����v����FROM�擾�֐�
 *  edit_item              (A-4)���ڕҏW
 *  check_data_row         (A-5)�f�[�^�`�F�b�N
 *  check_results_employee (A-5-1)����v��҂̏������_�`�F�b�N 2009/09/30 Add
 *  set_plsql_table        (A-6)�̔�����PL/SQL�\�쐬
 *  make_sales_exp_lines   (A-7)�̔����і��׍쐬
 *  make_sales_exp_headers (A-8)�̔����уw�b�_�쐬
 *  set_order_line_close_status (A-9)�󒍖��׃N���[�Y�ݒ�
 *  upd_sales_exp_create_flag   (A-9-1)�̔����э쐬�σt���O�X�V
 *  make_gen_err_list      (A-10)�ėp�G���[���X�g�쐬
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   K.Nakamura       �V�K�쐬
 *  2008/02/18    1.1   K.Nakamura       get_msg�̃p�b�P�[�W���C��
 *  2009/02/19    1.2   K.Nakamura       [COS_101] �ۊǏꏊ�������̎��̔[�i�`�[�ԍ��̐ݒ�l���C��
 *                                                 �̔����уw�b�_���쐬����P�ʂɔ[�i�`�[�ԍ���ǉ�
 *  2009/02/20    1.3   K.Nakamura       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *                                       �ŃR�[�h�}�X�^�̎Q�ƕ��@���C��
 *  2009/02/26    1.4   K.Nakamura       [COS_143] �󒍃f�[�^�擾���ɁA�[�i�\����ƌ����\����̎����b���폜
 *  2009/05/18    1.5   S.Kayahara       [T1_0815] �w�b�_�P�ʂň�ԑ傫���{�̋��z�̏������Βl�ɏC��
 *                      K.Kiriu          [T1_1067] �w�b�_�̏���Ŋz�̒[��������ǉ�
 *                                       [T1_1121] �{�̋��z�A����Ŋz�v�Z���@�̏C��
 *                                       [T1_1122] �[�������敪���؏㎞�̌v�Z�̏C��
 *  2009/06/01    1.6   N.Maeda          [T1_1269] ����ŋ敪3(����(�P������)):�Ŕ���P���Z�o���@�C��
 *  2009/06/08    1.7   T.Kitajima       [T1_1368] ����Œ[�������Ή�
 *  2009/06/10    1.8   T.Kitajima       [T1_1407] ����ŏ����_�Ȃ��Ή�
 *  2009/07/08    1.9   M.Sano           [0000063] ���敪�ɂ��f�[�^�쐬�Ώۂ̐���
 *                                       [0000064] ��DFF���ڒǉ��ɔ����A�A�g���ڒǉ�
 *                                       [0000434] PT�Ή�
 *  2009/07/28    1.9   M.Sano           [0000434] PT�Ή�(�C���R��Ή�)
 *  2009/09/11    1.10  K.Kiriu          [0001211] ����Ŋ֘A���ڎ擾����C��
 *                                       [0001345] PT�Ή�
 *  2009/09/30    1.11  M.Sano           [0001275] ���㋒�_�Ɛ��ю҂̏������_�̐������`�F�b�N�̒ǉ�
 *  2009/10/20    1.12  K.Satomura       [0001381] �󒍖��ׁD�̔����э쐬�σt���O�ǉ��Ή�
 *  2009/11/05    1.13  M.Sano           [E_T4_00111] ���b�N���{�ӏ��̕ύX
 *  2010/02/01    1.14  S.Karikomi       [E_T4_00195] �J�����_�̃N���[�Y�̊m�F��INV�J�����_�ɕύX
 *  2010/03/09    1.15  N.Maeda          [E_�{�ғ�_01725] �̔����јA�g�����㋒�_-�O�����㋒�_��������C��
 *  2010/08/25    1.16  S.Arizumi        [E_�{�ғ�_01763] INV���ߓ�������INV�A�g������
 *                                       [E_�{�ғ�_02635] �N���[�Y����Ȃ��󒍂̃G���[���X�g�o��
 *  2011/02/07    1.17  Y.Nishino        [E_�{�ғ�_01010] �̔��P��0�~�̎󒍃f�[�^���N���[�Y���Ȃ��悤�ɏC��
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
  --*** �f�[�^�X�V�G���[��O�n���h�� ***
  global_update_data_expt       EXCEPTION;
  --*** �f�[�^�擾�G���[��O�n���h�� ***
  global_select_data_expt       EXCEPTION;
  --*** ��v���Ԏ擾�G���[��O�n���h�� ***
  global_fiscal_period_err_expt EXCEPTION;
  --*** ����ʎ擾�G���[��O�n���h�� ***
  global_base_quantity_err_expt EXCEPTION;
  --*** �[�i�`�ԋ敪�擾�G���[��O�n���h�� ***
  global_delivered_from_err_expt EXCEPTION;
  --*** �K�{���ڃG���[��O�n���h�� ***
  global_not_null_col_warm_expt EXCEPTION;
  --*** API�Ăяo���G���[��O�n���h�� ***
  global_api_err_expt           EXCEPTION;
--
-- ************ 2011/02/07 1.17 Y.Nishino ADD START ************ --
  --*** �P��0�~�`�F�b�N�G���[��O�n���h�� ***
  global_price_err_expt   EXCEPTION;
-- ************ 2011/02/07 1.17 Y.Nishino ADD END   ************ --
--
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100)
                                       := 'XXCOS007A02C';        -- �p�b�P�[�W��
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
                                       :=  'APP-XXCOS1-11551';   -- �K�{���ږ����̓G���[
  ct_msg_fiscal_period_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11552';   -- ��v���Ԏ擾�G���[
  ct_msg_base_quantity_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11553';   -- ����ʎ擾�G���[
  cv_msg_parameter_note     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11554';   -- �p�����[�^�o�̓��b�Z�[�W
  ct_msg_delivered_from_err CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11555';   -- �[�i�`�ԋ敪�擾�G���[���b�Z�[�W
  ct_msg_hdr_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11580';   -- �w�b�_��������
  ct_msg_lin_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11581';   -- ���א�������
  ct_msg_select_odr_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11583';   -- �f�[�^�擾�G���[
-- 2009/07/08 Ver.1.9 M.Sano Add Start --
  ct_msg_cls_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11585';   -- �f�[�^�擾�G���[
-- 2009/07/08 Ver.1.9 M.Sano Add  End  --
-- 2009/09/30 Ver.1.11 M.Sano Add Start
  cv_msg_base_mismatch_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00193';   -- ���ьv��ҏ������_�s�����G���[
  cv_msg_err_param1_note    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00194';   -- ���ьv��ҏ������_�s�����G���[�p�p�����[�^1
  cv_msg_err_param2_note    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00195';   -- ���ьv��ҏ������_�s�����G���[�p�p�����[�^2
-- ********** 2009/10/20 1.12 K.Satomura  ADD Start ************ --
  cv_order_line_all_name    CONSTANT fnd_new_messages.message_name%TYPE
                                       := 'APP-XXCOS1-10254';    -- �󒍖��׏��
  cv_msg_update_err         CONSTANT fnd_new_messages.message_name%TYPE
                                       := 'APP-XXCOS1-00011';     -- �X�V�G���[
-- ********** 2009/10/19 1.12 K.Satomura  ADD End   ************ --
-- 2009/09/30 Ver.1.11 M.Sano Add End
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  --  �ėp�G���[�p�L�[���
  ct_msg_xxcos_00206        CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00206';    -- �L�[���ځi�󒍔ԍ��A���הԍ��j
  ct_msg_xxcos_00207        CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00207';    -- �L�[���ځi�󒍔ԍ��A���הԍ��A���t�j
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
-- ************ 2011/02/07 1.17 Y.Nishino ADD START ************ --
  -- �P��0�~�`�F�b�N �G���[
  ct_price0_line_type_err   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11542';
  -- �P��0�~�`�F�b�N �ėp�G���[���X�g
  ct_line_type_err_lst      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11542';
-- ************ 2011/02/07 1.17 Y.Nishino ADD END   ************ --
--
  --�g�[�N��
  cv_tkn_para_date        CONSTANT  VARCHAR2(100)  :=  'PARA_DATE';      -- �������t
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  cv_tkn_para_regular_any_class CONSTANT  VARCHAR2(100) :=  'PARA_REGULAR_ANY_CLASS'; -- ��������敪
  cv_tkn_para_dlv_base_code     CONSTANT  VARCHAR2(100) :=  'PARA_DLV_BASE_CODE';     -- �[�i���_�R�[�h
  cv_tkn_para_edi_chain_code    CONSTANT  VARCHAR2(100) :=  'PARA_EDI_CHAIN_CODE';    -- EDI�`�F�[���X�R�[�h
  cv_tkn_para_cust_code         CONSTANT  VARCHAR2(100) :=  'PARA_CUST_CODE';         -- �ڋq�R�[�h
  cv_tkn_para_dlv_date_from     CONSTANT  VARCHAR2(100) :=  'PARA_DLV_DATE_FROM';     -- �[�i��FROM
  cv_tkn_param_dlv_date_to      CONSTANT  VARCHAR2(100) :=  'PARA_DLV_DATE_TO';       -- �[�i��TO
  cv_tkn_para_created_by        CONSTANT  VARCHAR2(100) :=  'PARA_CREATED_BY';        -- �쐬��
  cv_tkn_para_order_numer       CONSTANT  VARCHAR2(100) :=  'PARA_ORDER_NUMBER';      -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
  cv_tkn_profile          CONSTANT  VARCHAR2(100)  :=  'PROFILE';        -- �v���t�@�C����
  cv_tkn_table            CONSTANT  VARCHAR2(100)  :=  'TABLE';          -- �e�[�u������
  cv_tkn_order_number     CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- �󒍔ԍ�
  cv_tkn_line_number      CONSTANT  VARCHAR2(100)  :=  'LINE_NUMBER';    -- �󒍖��הԍ�
  cv_tkn_field_name       CONSTANT  VARCHAR2(100)  :=  'FIELD_NAME';     -- �t�B�[���h��
  cv_tkn_account_name     CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- ��v���Ԏ��
  cv_tkn_base_date        CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- ���
  cv_tkn_item_code        CONSTANT  VARCHAR2(100)  :=  'ITEM_CODE';      -- �i�ڃR�[�h
  cv_tkn_before_code      CONSTANT  VARCHAR2(100)  :=  'BEFORE_CODE';    -- ���Z�O�P�ʃR�[�h
  cv_tkn_before_value     CONSTANT  VARCHAR2(100)  :=  'BEFORE_VALUE';   -- ���Z�O����
  cv_tkn_after_code       CONSTANT  VARCHAR2(100)  :=  'AFTER_CODE';     -- ���Z��P�ʃR�[�h
  cv_tkn_key_data         CONSTANT  VARCHAR2(100)  :=  'KEY_DATA';       -- �L�[���
  cv_tkn_table_name       CONSTANT  VARCHAR2(100)  :=  'TABLE_NAME';     -- �e�[�u������
  cv_tkn_api_name         CONSTANT  VARCHAR2(100)  :=  'API_NAME';       -- API����
  cv_tkn_err_msg          CONSTANT  VARCHAR2(100)  :=  'ERR_MSG';        -- �G���[���b�Z�[�W
-- 2009/09/30 Ver.1.11 M.Sano Add Start
  cv_tkn_base_code        CONSTANT  VARCHAR2(100)  :=  'BASE_CODE';         -- ���_��
  cv_tkn_base_name        CONSTANT  VARCHAR2(100)  :=  'BASE_NAME';         -- ���_�R�[�h
  cv_tkn_invoice_num      CONSTANT  VARCHAR2(100)  :=  'INVOICE_NUM';       -- �[�i�`�[�ԍ�
  cv_tkn_customer_code    CONSTANT  VARCHAR2(100)  :=  'CUSTOMER_CODE';     -- �ڋq�R�[�h
  cv_tkn_result_emp_code  CONSTANT  VARCHAR2(100)  :=  'RESULT_EMP_CODE';   -- ���ьv��҃R�[�h
  cv_tkn_result_base_code CONSTANT  VARCHAR2(100)  :=  'RESULT_BASE_CODE';  -- ���ьv��҂̏������_�R�[�h
-- 2009/09/30 Ver.1.11 M.Sano Add End
-- ********** 2009/10/20 1.12 K.Satomura  ADD Start ************ --
  cv_key_data             CONSTANT  VARCHAR2(100)  := 'KEY_DATA';           -- �g�[�N��'KEY_DATA'
-- ********** 2009/10/20 1.12 K.Satomura  ADD End   ************ --
--
  --���b�Z�[�W�p������
  cv_str_profile_nm                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00047';  -- MO:�c�ƒP��
  cv_str_max_date_nm               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00056';  -- XXCOS:MAX���t
  cv_str_gl_id_nm                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00060';  -- GL��v����ID
  cv_lock_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11556';  -- �󒍃w�b�_�^�󒍖���
  cv_dlv_invoice_number            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11557';  -- �[�i�`�[�ԍ�
  cv_dlv_invoice_class             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11558';  -- �[�i�`�[�敪
  cv_dlv_date                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11559';  -- �[�i��
  cv_inspect_date                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11560';  -- ������
  cv_tax_code                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11561';  -- �ŋ��R�[�h
  cv_results_employee_code         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11562';  -- ���ьv��҃R�[�h
  cv_sale_base_code                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11563';  -- ���㋒�_�R�[�h
  cv_receiv_base_code              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11564';  -- �������_�R�[�h
  cv_business_cost_sum             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11565';  -- �쐬���敪
  cv_sales_class                   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11566';  -- ����敪
  cv_red_black_flag                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11567';  -- �ԍ��t���O
  cv_base_quantity                 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11568';  -- �����
  cv_base_uom                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11569';  -- ��P��
  cv_base_unit_ploce               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11570';  -- ��P��
  cv_standard_unit_price           CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11571';  -- �Ŕ���P��
  cv_delivery_base_code            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11572';  -- �[�i���_�R�[�h
  cv_ship_from_subinventory_code   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11573';  -- �ۊǏꏊ�R�[�h  
  cv_order_line_table              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11574';  -- �󒍖���
  cv_sales_exp_header_table        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11575';  -- �̔����уw�b�_
  cv_sales_exp_line_table          CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11576';  -- �̔����і���
  cv_item_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11577';  -- OPM�i�ڃ}�X�^
  cv_person_table                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11578';  -- �]�ƈ��}�X�^
  cv_api_name                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11582';  -- �󒍃N���[�YAPI
  cv_tax_class                     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11584';  -- ����ŋ敪
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  cv_fnd_user                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00214';  -- ���[�U�}�X�^
  cv_gen_err_list                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00213';  -- �ėp�G���[���X�g
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
  --�v���t�@�C������
  --MO:�c�ƒP��
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
--
  --XXCOS:MAX���t
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';
--
  -- GL��v����ID
  cv_prf_bks_id      CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
--
  --�N�C�b�N�R�[�h�^�C�v
  -- �ԕi���уf�[�^�쐬(HHT�ȊO)���o�Ώۏ���
  ct_qct_sale_exp_condition     CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_EXP_CONDITION';
  -- ����敪
  ct_qct_sales_class_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_CLASS_MST';
  -- �ԍ��敪
  ct_qct_red_black_flag_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_RED_BLACK_FLAG_007';
  -- �ŃR�[�h
  ct_qct_tax_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';
  -- �[�i�`�[�敪
  ct_qct_dlv_slp_cls_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST';
  -- �G���[�i��
  ct_qct_edi_item_err_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_EDI_ITEM_ERR_TYPE';
  -- ����ŋ敪������       
  ct_qct_tax_class_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPT_TAX_CLS_MST';
--
  --�N�C�b�N�R�[�h
  -- �ԕi���уf�[�^�쐬(HHT�ȊO)���o�Ώۏ���
  ct_qcc_sale_exp_condition     CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS_007_A02%';
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
--
  --�󒍖��׃X�e�[�^�X
  ct_ln_status_closed           CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --�N���[�Y
  ct_ln_status_cancelled        CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --���
--
  --�p�����[�^���t�w�菑��
  ct_target_date_format         CONSTANT  VARCHAR2(10) := 'yyyy/mm/dd';
--
  --���t�����i�N���j
  cv_fmt_date_yyyymm            CONSTANT  VARCHAR2(7)  := 'yyyymm';
  cv_fmt_date_default           CONSTANT  VARCHAR2(21)  := 'YYYY-MM-DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'RRRR/MM/DD';
-- 2009/09/30 Ver.1.11 M.Sano Add Start
  cv_fmt_date_rrrrmmdd          CONSTANT  VARCHAR2(10) := 'RRRRMMDD';
-- 2009/09/30 Ver.1.11 M.Sano Add End
--
  --�f�[�^�`�F�b�N�X�e�[�^�X�l
  cn_check_status_normal        CONSTANT  NUMBER := 0;  -- ����
  cn_check_status_error         CONSTANT  NUMBER := -1; -- �G���[
--
-- 2010/02/01 Ver.1.13 S.Karikomi Add Start
  --INV��v���ԋ敪�l
  cv_fiscal_period_inv          CONSTANT  VARCHAR2(2) := '01';  --INV��v���ԋ敪�l
  cv_fiscal_period_tkn_inv      CONSTANT  VARCHAR2(3) := 'INV'; --INV
-- 2010/02/01 Ver.1.13 S.Karikomi Add End
--
-- 2010/02/02 Ver.1.13 S.Karikomi Del Start
--  --AR��v���ԋ敪�l
--  cv_fiscal_period_ar           CONSTANT  VARCHAR2(2) := '02';  --AR
-- 2010/02/02 Ver.1.13 S.Karikomi Del End
--
  --����^�C�v�p����p�����[�^
  cv_transaction_lang           CONSTANT  VARCHAR2(4) := 'LANG';
--
  --�󒍖��׃N���[�Y�p������
  cv_close_type                 CONSTANT  VARCHAR2(5) := 'OEOL';
  cv_activity                   CONSTANT  VARCHAR2(27):= 'XXCOS_R_STANDARD_LINE:BLOCK';
  cv_result                     CONSTANT  VARCHAR2(1) := NULL;
--
  -- �쐬���敪
  cv_business_cost              CONSTANT  VARCHAR2(1) := '8'; -- �ԕi���уf�[�^�쐬�i�g�g�s�ȊO�j
--
  -- �ۊǏꏊ�敪
  cv_subinventory_class         CONSTANT  VARCHAR2(1) := '8'; -- ����
--
  cv_amount_up                  CONSTANT  VARCHAR(5)  := 'UP';      -- �����_�[��(�؏�)
  cv_amount_down                CONSTANT  VARCHAR(5)  := 'DOWN';    -- �����_�[��(�؎̂�)
  cv_amount_nearest             CONSTANT  VARCHAR(10) := 'NEAREST'; -- �����_�[��(�l�̌ܓ�)
-- 2009/07/08 Ver.1.9 M.Sano Add Start
--
  -- ���敪
  cv_info_class_01              CONSTANT  VARCHAR2(2) := '01';      -- ���敪:01
  cv_info_class_02              CONSTANT  VARCHAR2(2) := '02';      -- ���敪:02
--
  -- ����R�[�h
  ct_lang                       CONSTANT  fnd_lookup_values.language%TYPE := USERENV('LANG');
-- 2009/07/08 Ver.1.9 M.Sano Add End
-- 2009/09/30 Ver.1.11 M.Sano Add Start
--
  -- �ڋq�敪
  cv_cust_class_base            CONSTANT VARCHAR2(1)  := '1';     --�ڋq�敪.���_
-- 2009/09/30 Ver.1.11 M.Sano Add End
-- ****** 2010/03/09 N.Maeda 1.15 ADD START ****** --
  cv_trunc_mm                   CONSTANT VARCHAR2(2)  := 'MM';
-- ****** 2010/03/09 N.Maeda 1.15 ADD  END  ****** --
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  -- ��������敪
  cv_regular_any_class_any      CONSTANT VARCHAR2(1)  := '0'; -- ����
  cv_regular_any_class_regular  CONSTANT VARCHAR2(1)  := '1'; -- ���
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
-- 2009/07/08 Ver.1.9 M.Sano Add Start
  gn_normal_close_cnt     NUMBER;   -- ���팏��(�N���[�Y)
-- 2009/07/08 Ver.1.9 M.Sano Add End
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
--
-- ****** 2010/03/09 N.Maeda 1.15 ADD START ****** --
  -- �Ɩ����t(���t�؎�)
  gd_business_date_trunc_mm DATE;
-- ****** 2010/03/09 N.Maeda 1.15 ADD  END  ****** --
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  gn_gen_err_count        NUMBER                                      DEFAULT 0;    -- �ėp�G���[�o�͌���
--
  gt_regular_any_class    fnd_lookup_values.lookup_code%TYPE          DEFAULT NULL; -- ��������敪
  gt_dlv_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE DEFAULT NULL; -- �[�i���_�R�[�h
  gt_edi_chain_code       xxcmm_cust_accounts.chain_store_code%TYPE   DEFAULT NULL; -- EDI�`�F�[���X�R�[�h
  gt_cust_code            xxcmm_cust_accounts.customer_code%TYPE      DEFAULT NULL; -- �ڋq�R�[�h
  gt_dlv_date_from        oe_order_lines_all.request_date%TYPE        DEFAULT NULL; -- �[�i��FROM
  gt_dlv_date_to          oe_order_lines_all.request_date%TYPE        DEFAULT NULL; -- �[�i��TO
  gt_created_by           oe_order_headers_all.created_by%TYPE        DEFAULT NULL; -- �쐬��
  gt_order_number         oe_order_headers_all.order_number%TYPE      DEFAULT NULL; -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  --�󒍃f�[�^���R�[�h�^
  TYPE order_data_rtype IS RECORD(
    header_id                     oe_order_headers_all.header_id%type               -- �󒍃w�b�_ID
    , line_id                     oe_order_lines_all.line_id%type                   -- �󒍖���ID
    , order_type                  oe_transaction_types_tl.name%type                 -- �󒍃^�C�v
    , line_type                   oe_transaction_types_tl.name%type                 -- ���׃^�C�v
    , salesrep_id                 oe_order_headers_all.salesrep_id%type             -- �c�ƒS��
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%type   -- �[�i�`�[�ԍ�
    , order_invoice_number        xxcos_sales_exp_headers.order_invoice_number%type -- �����`�[�ԍ�
    , order_number                xxcos_sales_exp_headers.order_number%type         -- �󒍔ԍ�
    , line_number                 oe_order_lines_all.line_number%type               -- �󒍖��הԍ�
    , order_no_hht                xxcos_sales_exp_headers.order_no_hht%type         -- ��No�iHHT)
    , order_no_hht_seq            xxcos_sales_exp_headers.digestion_ln_number%type  -- ��No�iHHT�j�}��
    , dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%type    -- �[�i�`�[�敪
    , cancel_correct_class        xxcos_sales_exp_headers.cancel_correct_class%type -- ��������敪
    , input_class                 xxcos_sales_exp_headers.input_class%type          -- ���͋敪
    , cust_gyotai_sho             xxcos_sales_exp_headers.cust_gyotai_sho%type      -- �Ƒԁi�����ށj
    , dlv_date                    xxcos_sales_exp_headers.delivery_date%type        -- �[�i��
    , org_dlv_date                xxcos_sales_exp_headers.orig_delivery_date%type   -- �I���W�i���[�i��
    , inspect_date                xxcos_sales_exp_headers.inspect_date%type         -- ������
    , orig_inspect_date           xxcos_sales_exp_headers.orig_inspect_date%type    -- �I���W�i��������
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%type-- �ڋq�y�[�i��z
    , consumption_tax_class       xxcos_sales_exp_headers.consumption_tax_class%type-- ����ŋ敪
    , tax_code                    xxcos_sales_exp_headers.tax_code%type             -- �ŋ��R�[�h
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%type             -- ����ŗ�
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%type-- ���ьv��҃R�[�h
    , sale_base_code              xxcos_sales_exp_headers.sales_base_code%type      -- ���㋒�_�R�[�h
    , last_month_sale_base_code   xxcos_sales_exp_headers.sales_base_code%type      -- �O�����㋒�_�R�[�h
    , rsv_sale_base_act_date      xxcmm_cust_accounts.rsv_sale_base_act_date%type   -- �\�񔄏㋒�_�L���J�n��
    , receiv_base_code            xxcos_sales_exp_headers.receiv_base_code%type     -- �������_�R�[�h
    , order_source_id             xxcos_sales_exp_headers.order_source_id%type      -- �󒍃\�[�XID
    , order_connection_number     xxcos_sales_exp_headers.order_connection_number%type-- �O���V�X�e���󒍔ԍ�
    , card_sale_class             xxcos_sales_exp_headers.card_sale_class%type      -- �J�[�h����敪
    , invoice_class               xxcos_sales_exp_headers.invoice_class%type        -- �`�[�敪
    , big_classification_code     xxcos_sales_exp_headers.invoice_classification_code%type    -- �`�[���ރR�[�h
    , change_out_time_100         xxcos_sales_exp_headers.change_out_time_100%type  -- ��K�؂ꎞ�ԂP�O�O�~
    , change_out_time_10          xxcos_sales_exp_headers.change_out_time_10%type   -- ��K�؂ꎞ�ԂP�O�~
    , ar_interface_flag           xxcos_sales_exp_headers.ar_interface_flag%type    -- AR�C���^�t�F�[�X�σt���O
    , gl_interface_flag           xxcos_sales_exp_headers.gl_interface_flag%type    -- GL�C���^�t�F�[�X�σt���O
    , dwh_interface_flag          xxcos_sales_exp_headers.dwh_interface_flag%type   -- ����Ѳ���̪���σt���O
    , edi_interface_flag          xxcos_sales_exp_headers.edi_interface_flag%type   -- EDI���M�ς݃t���O
    , edi_send_date               xxcos_sales_exp_headers.edi_send_date%type        -- EDI���M����
    , hht_dlv_input_date          xxcos_sales_exp_headers.hht_dlv_input_date%type   -- HHT�[�i���͓���
    , dlv_by_code                 xxcos_sales_exp_headers.dlv_by_code%type          -- �[�i�҃R�[�h
    , create_class                xxcos_sales_exp_headers.create_class%type         -- �쐬���敪
    , dlv_invoice_line_number     xxcos_sales_exp_lines.dlv_invoice_line_number%type-- �[�i���הԍ�
    , order_invoice_line_number   xxcos_sales_exp_lines.order_invoice_line_number%type  -- �������הԍ�
    , sales_class                 xxcos_sales_exp_lines.sales_class%type            -- ����敪
    , delivery_pattern_class      xxcos_sales_exp_lines.delivery_pattern_class%type -- �[�i�`�ԋ敪
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%type         -- �ԍ��t���O
    , item_code                   xxcos_sales_exp_lines.item_code%type              -- �i�ڃR�[�h
    , ordered_quantity            oe_order_lines_all.ordered_quantity%type          -- �󒍐���
    , base_quantity               xxcos_sales_exp_lines.standard_qty%type           -- �����
    , order_quantity_uom          oe_order_lines_all.order_quantity_uom%type        -- �󒍒P��
    , base_uom                    xxcos_sales_exp_lines.standard_uom_code%type      -- ��P��
    , standard_unit_price         xxcos_sales_exp_lines.standard_unit_price_excluded%type -- �Ŕ���P��
    , base_unit_price             xxcos_sales_exp_lines.standard_unit_price%type    -- ��P��
    , unit_selling_price          oe_order_lines_all.unit_selling_price%type        -- �̔��P��
    , business_cost               xxcos_sales_exp_lines.business_cost%type          -- �c�ƌ���
    , sale_amount                 xxcos_sales_exp_lines.sale_amount%type            -- ������z
    , pure_amount                 xxcos_sales_exp_lines.pure_amount%type            -- �{�̋��z
    , tax_amount                  xxcos_sales_exp_lines.tax_amount%type             -- ����ŋ��z
    , cash_and_card               xxcos_sales_exp_lines.cash_and_card%type          -- �����E�J�[�h���p�z
    , ship_from_subinventory_code xxcos_sales_exp_lines.ship_from_subinventory_code%type  -- �o�׌��ۊǏꏊ
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%type     -- �[�i���_�R�[�h
    , hot_cold_class              xxcos_sales_exp_lines.hot_cold_class%type         -- �g���b
    , column_no                   xxcos_sales_exp_lines.column_no%type              -- �R����No
    , sold_out_class              xxcos_sales_exp_lines.sold_out_class%type         -- ���؋敪
    , sold_out_time               xxcos_sales_exp_lines.sold_out_time%type          -- ���؎���
    , to_calculate_fees_flag      xxcos_sales_exp_lines.to_calculate_fees_flag%type -- �萔���v�Z�C���^�t�F�[�X�σt���O
    , unit_price_mst_flag         xxcos_sales_exp_lines.unit_price_mst_flag%type    -- �P���}�X�^�쐬�σt���O
    , inv_interface_flag          xxcos_sales_exp_lines.inv_interface_flag%type     -- INV�C���^�t�F�[�X�σt���O
    , bill_tax_round_rule         xxcfr_cust_hierarchy_v.bill_tax_round_rule%TYPE   -- �ŋ��|�[������
    , packing_instructions        oe_order_lines_all.packing_instructions%type      -- �o�׈˗�No
    , subinventory_class          mtl_secondary_inventories.attribute1%type         -- �ۊǏꏊ�敪
    , check_status                NUMBER                                            -- �`�F�b�N�X�e�[�^�X
-- 2009/07/08 Ver.1.9 M.Sano Add Start
    , info_class                  oe_order_headers_all.global_attribute3%type       -- ���敪
-- 2009/07/08 Ver.1.9 M.Sano Add End
-- 2009/09/30 Ver.1.11 M.Sano Add Start
    , results_employee_base_code  per_all_assignments_f.ass_attribute5%TYPE         -- �������_�R�[�h
-- 2009/09/30 Ver.1.11 M.Sano Add End
  );
-- 2009/09/30 Ver.1.11 M.Sano Add Start
--
  --�������_�s��v�G���[�f�[�^(�w�b�_)���R�[�h�^
  TYPE g_base_err_order_rtype IS RECORD(
      sale_base_code              xxcos_sales_exp_headers.sales_base_code%type      -- ���㋒�_�R�[�h
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%type   -- �[�i�`�[�ԍ�
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%type-- �ڋq�y�[�i��z
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%type-- ���ьv��҃R�[�h
    , results_employee_base_code  per_all_assignments_f.ass_attribute5%TYPE         -- �������_�R�[�h
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%TYPE     -- �[�i���_�R�[�h
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
    , output_flag                 VARCHAR2(1)                                       -- �o�̓t���O
  );
-- 2009/09/30 Ver.1.11 M.Sano Add End
--
  -- ����敪
  TYPE sales_class_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values_vl.lookup_code%type     -- ����^�C�v
    , sales_class                 xxcos_sales_exp_lines.sales_class%type    -- ����敪
  );
--
  -- �ԍ��t���O
  TYPE red_black_flag_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values_vl.meaning%type         -- ����^�C�v
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%type -- �ԍ��t���O
  );
--
  -- ����ŃR�[�h
  TYPE tax_rtype IS RECORD(
    tax_class                     xxcos_sales_exp_headers.consumption_tax_class%type  -- ����ŋ敪
    , tax_code                    xxcos_sales_exp_headers.tax_code%type               -- �ŃR�[�h
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%type               -- �ŗ�
/* 2009/09/10 Ver1.10 Mod Start */
--    , tax_include                 fnd_lookup_values.attribute5%TYPE                   -- ���Ńt���O
    , start_date_active           fnd_lookup_values.start_date_active%type            -- �K�p�J�n��
    , end_date_active             fnd_lookup_values.end_date_active%type              -- �K�p�I����
/* 2009/09/10 Ver1.10 Mod End   */
  );
--
  -- ����ŋ敪
  TYPE tax_class_rtype IS RECORD(
    tax_free                      xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ��ې�
    , tax_consumption             xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- �O��
    , tax_slip                    xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����(�`�[�ې�)
    , tax_included                xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����(�P������)
   );
-- 2009/07/08 Ver.1.9 M.Sano Add Start
  -- �󒍖��׃f�[�^���R�[�h�^
  TYPE order_line_data_rtype IS RECORD(
    line_id                       oe_order_lines_all.line_id%type                     -- �󒍖���ID
  );
-- 2009/07/08 Ver.1.9 M.Sano Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h�錾
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --�󒍃f�[�^
  TYPE g_n_order_data_ttype IS TABLE OF order_data_rtype INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_rtype INDEX BY VARCHAR(100);
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
        IS TABLE OF sales_class_rtype INDEX BY fnd_lookup_values_vl.lookup_code%type;
  --�ԍ��t���O
  TYPE g_red_black_flag_sub_ttype
        IS TABLE OF red_black_flag_rtype INDEX BY BINARY_INTEGER;
  TYPE g_red_black_flag_ttype
        IS TABLE OF red_black_flag_rtype INDEX BY fnd_lookup_values_vl.meaning%type;
  --����ŃR�[�h
  TYPE g_tax_sub_ttype
        IS TABLE OF tax_rtype INDEX BY BINARY_INTEGER;
/* 2009/09/11 Ver1.10 Del Start */
--  TYPE g_tax_ttype
--        IS TABLE OF tax_rtype INDEX BY xxcos_sales_exp_headers.consumption_tax_class%type;
/* 2009/09/11 Ver1.10 Del End   */
  --�󒍖��׃f�[�^
  TYPE order_line_data_ttype IS TABLE OF order_line_data_rtype INDEX BY BINARY_INTEGER;
-- 2009/09/30 Ver.1.11 M.Sano Add Start
  --���ьv��ҕs�����G���[�f�[�^
  TYPE g_base_err_order_ttype IS TABLE OF g_base_err_order_rtype INDEX BY BINARY_INTEGER;
-- 2009/09/30 Ver.1.11 M.Sano Add End
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  -- �ėp�G���[���X�g
  TYPE g_gen_err_list_ttype IS TABLE OF xxcos_gen_err_list%ROWTYPE INDEX BY BINARY_INTEGER;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��PL/SQL�\
  -- ===============================
  g_sale_class_sub_tab        g_sale_class_sub_ttype;         -- ����敪
  g_sale_class_tab            g_sale_class_ttype;             -- ����敪
  g_red_black_flag_sub_tab    g_red_black_flag_sub_ttype;     -- �ԍ��t���O
  g_red_black_flag_tab        g_red_black_flag_ttype;         -- �ԍ��t���O
/* 2009/09/11 Ver1.10 Mod Start */
--  g_tax_sub_tab               g_tax_sub_ttype;                -- ����ŃR�[�h
--  g_tax_tab                   g_tax_ttype;                    -- ����ŃR�[�h
  g_tax_tab                   g_tax_sub_ttype;                -- ����ŃR�[�h
/* 2009/09/11 Ver1.10 Mod End   */
  g_order_data_tab            g_n_order_data_ttype;           -- �󒍃f�[�^
  g_order_data_sort_tab       g_v_order_data_ttype;           -- �󒍃f�[�^(�\�[�g��)
  g_sale_hdr_tab              g_sale_results_headers_ttype;   -- �̔����уw�b�_
  g_sale_line_tab             g_sale_results_lines_ttype;     -- �̔����і���
  g_tax_class_rec             tax_class_rtype;                -- ����ŋ敪
-- 2009/07/08 Ver.1.9 M.Sano Add Start
  g_order_all_data_tab        g_n_order_data_ttype;           -- �󒍃f�[�^(�����ΏۑS�f�[�^)
  g_order_cls_data_tab        order_line_data_ttype;          -- �󒍃f�[�^(��CLOSE�Ώ�)
-- 2009/07/08 Ver.1.9 M.Sano Add End
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  g_gen_err_list_tab          g_gen_err_list_ttype;           -- �ėp�G���[���X�g
--
  /**********************************************************************************
   * Procedure Name   : set_gen_err_list
   * Description      : �ėp�G���[���X�g�o�͏��ݒ�
   ***********************************************************************************/
  PROCEDURE set_gen_err_list(
      ov_errbuf                   OUT VARCHAR2                              -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                  OUT VARCHAR2                              -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                   OUT VARCHAR2                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , it_base_code                IN  xxcos_gen_err_list.base_code%TYPE     -- �[�i���_�R�[�h
    , it_message_name             IN  xxcos_gen_err_list.message_name%TYPE  -- �G���[���b�Z�[�W��
    , it_message_text             IN  xxcos_gen_err_list.message_text%TYPE  -- �G���[���b�Z�[�W
    , iv_output_msg_application   IN  VARCHAR2 DEFAULT NULL                 -- �A�v���P�[�V�����Z�k��
    , iv_output_msg_name          IN  VARCHAR2 DEFAULT NULL                 -- ���b�Z�[�W�R�[�h
    , iv_output_msg_token_name1   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h1
    , iv_output_msg_token_value1  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l1
    , iv_output_msg_token_name2   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h2
    , iv_output_msg_token_value2  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l2
    , iv_output_msg_token_name3   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h3
    , iv_output_msg_token_value3  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l4
    , iv_output_msg_token_name4   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h4
    , iv_output_msg_token_value4  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l4
    , iv_output_msg_token_name5   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h5
    , iv_output_msg_token_value5  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l5
    , iv_output_msg_token_name6   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h6
    , iv_output_msg_token_value6  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l6
    , iv_output_msg_token_name7   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h7
    , iv_output_msg_token_value7  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l7
    , iv_output_msg_token_name8   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h8
    , iv_output_msg_token_value8  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l8
    , iv_output_msg_token_name9   IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h9
    , iv_output_msg_token_value9  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l9
    , iv_output_msg_token_name10  IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���R�[�h10
    , iv_output_msg_token_value10 IN  VARCHAR2 DEFAULT NULL                 -- �g�[�N���l10
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'set_gen_err_list';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  #####################
    lv_errbuf   VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
--#####################  �Œ胍�[�J���ϐ��錾�� END    #####################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_out_msg  xxcos_gen_err_list.message_text%TYPE; -- �ėp�G���[���X�g�o�̓��b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--#####################  �Œ�X�e�[�^�X�������� START  #####################
    ov_retcode  := cv_status_normal;
--#####################  �Œ�X�e�[�^�X�������� END    #####################
--
    IF (     ( gt_regular_any_class IS NOT NULL                    )
         AND ( gt_regular_any_class = cv_regular_any_class_regular )
    ) THEN
      IF ( it_message_text IS NULL ) THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                           iv_application   => iv_output_msg_application
                         , iv_name          => iv_output_msg_name
                         , iv_token_name1   => iv_output_msg_token_name1
                         , iv_token_value1  => iv_output_msg_token_value1
                         , iv_token_name2   => iv_output_msg_token_name2
                         , iv_token_value2  => iv_output_msg_token_value2
                         , iv_token_name3   => iv_output_msg_token_name3
                         , iv_token_value3  => iv_output_msg_token_value3
                         , iv_token_name4   => iv_output_msg_token_name4
                         , iv_token_value4  => iv_output_msg_token_value4
                         , iv_token_name5   => iv_output_msg_token_name5
                         , iv_token_value5  => iv_output_msg_token_value5
                         , iv_token_name6   => iv_output_msg_token_name6
                         , iv_token_value6  => iv_output_msg_token_value6
                         , iv_token_name7   => iv_output_msg_token_name7
                         , iv_token_value7  => iv_output_msg_token_value7
                         , iv_token_name8   => iv_output_msg_token_name8
                         , iv_token_value8  => iv_output_msg_token_value8
                         , iv_token_name9   => iv_output_msg_token_name9
                         , iv_token_value9  => iv_output_msg_token_value9
                         , iv_token_name10  => iv_output_msg_token_name10
                         , iv_token_value10 => iv_output_msg_token_value10
                       );
      ELSE
        lv_out_msg  := it_message_text;
      END If;
--
      gn_gen_err_count  := gn_gen_err_count + 1;  -- �ėp�G���[�o�͌������C���N�������g
--
      SELECT  xxcos_gen_err_list_s01.nextval  AS gen_err_list_id
      INTO  g_gen_err_list_tab( gn_gen_err_count ).gen_err_list_id                                  -- �ėp�G���[���X�gID
      FROM    DUAL
      ;
--
      g_gen_err_list_tab( gn_gen_err_count ).base_code                := it_base_code;              -- �[�i���_�R�[�h
      g_gen_err_list_tab( gn_gen_err_count ).concurrent_program_name  := cv_pkg_name;               -- �R���J�����g��
      g_gen_err_list_tab( gn_gen_err_count ).business_date            := gd_business_date;          -- �o�^�Ɩ����t
      g_gen_err_list_tab( gn_gen_err_count ).message_name             := it_message_name;           -- �G���[���b�Z�[�W��
      g_gen_err_list_tab( gn_gen_err_count ).message_text             := lv_out_msg;                -- �G���[���b�Z�[�W
      g_gen_err_list_tab( gn_gen_err_count ).created_by               := cn_created_by;             -- �쐬��
--      g_gen_err_list_tab( gn_gen_err_count ).creation_date            := cd_creation_date;          -- �쐬��
      g_gen_err_list_tab( gn_gen_err_count ).creation_date            := SYSDATE;                   -- �쐬��
      g_gen_err_list_tab( gn_gen_err_count ).last_updated_by          := cn_last_updated_by;        -- �ŏI�X�V��
--      g_gen_err_list_tab( gn_gen_err_count ).last_update_date         := cd_last_update_date;       -- �ŏI�X�V��
      g_gen_err_list_tab( gn_gen_err_count ).last_update_date         := SYSDATE;                   -- �ŏI�X�V��
      g_gen_err_list_tab( gn_gen_err_count ).last_update_login        := cn_last_update_login;      -- �ŏI�X�V���O�C��
      g_gen_err_list_tab( gn_gen_err_count ).request_id               := cn_request_id;             -- �v��ID
      g_gen_err_list_tab( gn_gen_err_count ).program_application_id   := cn_program_application_id; -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      g_gen_err_list_tab( gn_gen_err_count ).program_id               := cn_program_id;             -- �R���J�����g�E�v���O����ID
--      g_gen_err_list_tab( gn_gen_err_count ).program_update_date      := cd_program_update_date;    -- �v���O�����X�V��
      g_gen_err_list_tab( gn_gen_err_count ).program_update_date      := SYSDATE;                   -- �v���O�����X�V��
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START  #################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END    #################################
  END set_gen_err_list;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_target_date  IN      VARCHAR2,     -- �������t
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    iv_regular_any_class  IN  VARCHAR2,   -- ��������敪
    iv_dlv_base_code      IN  VARCHAR2,   -- �[�i���_�R�[�h
    iv_edi_chain_code     IN  VARCHAR2,   -- EDI�`�F�[���X�R�[�h
    iv_cust_code          IN  VARCHAR2,   -- �ڋq�R�[�h
    iv_dlv_date_from      IN  VARCHAR2,   -- �[�i��FROM
    iv_dlv_date_to        IN  VARCHAR2,   -- �[�i��TO
    iv_user_name          IN  VARCHAR2,   -- �쐬��
    iv_order_number       IN  VARCHAR2,   -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
-- 2010/08/25 Ver.1.16 S.Arizumi Mod Start --
--    lv_para_msg     VARCHAR2(100);
    lv_para_msg     VARCHAR2(5000);   -- �p�����[�^�o�̓��b�Z�[�W
    lv_table_name   VARCHAR2(100);    --  �e�[�u����
-- 2010/08/25 Ver.1.16 S.Arizumi Mod End   --
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
-- ****** 2010/03/09 N.Maeda 1.15 ADD START ****** --
    -- ���㋒�_�ݒ蔻��p�F�Ɩ����t(���t�؎�)�ݒ�
    gd_business_date_trunc_mm := TRUNC( gd_business_date , cv_trunc_mm );
-- ****** 2010/03/09 N.Maeda 1.15 ADD  END  ****** --
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
        gd_process_date  :=  TO_DATE(iv_target_date, ct_target_date_format);
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
-- 2010/08/25 Ver.1.16 S.Arizumi Mod Start --
--                       iv_token_value1  =>  TO_CHAR(gd_process_date, ct_target_date_format)  -- �������t
                       iv_token_value1  =>  TO_CHAR( gd_process_date, ct_target_date_format ),  -- �������t
                       iv_token_name2   =>  cv_tkn_para_regular_any_class,
                       iv_token_value2  =>  iv_regular_any_class,                               -- ��������敪
                       iv_token_name3   =>  cv_tkn_para_dlv_base_code,
                       iv_token_value3  =>  iv_dlv_base_code,                                   -- �[�i���_�R�[�h
                       iv_token_name4   =>  cv_tkn_para_edi_chain_code,
                       iv_token_value4  =>  iv_edi_chain_code,                                  -- EDI�`�F�[���X�R�[�h
                       iv_token_name5   =>  cv_tkn_para_cust_code,
                       iv_token_value5  =>  iv_cust_code,                                       -- �ڋq�R�[�h
                       iv_token_name6   =>  cv_tkn_para_dlv_date_from,
                       iv_token_value6  =>  iv_dlv_date_from,                                   -- �[�i��FROM
                       iv_token_name7   =>  cv_tkn_param_dlv_date_to,
                       iv_token_value7  =>  iv_dlv_date_to,                                     -- �[�i��TO
                       iv_token_name8   =>  cv_tkn_para_created_by,
                       iv_token_value8  =>  iv_user_name,                                       -- �쐬��
                       iv_token_name9   =>  cv_tkn_para_order_numer,
                       iv_token_value9  =>  iv_order_number                                     -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Mod End   --
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
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    --===================================
    -- ���̓p�����[�^
    --===================================
    -- ��������敪
    gt_regular_any_class  := iv_regular_any_class;
--
    IF (     ( gt_regular_any_class IS NOT NULL                )
         AND ( gt_regular_any_class = cv_regular_any_class_any )
    ) THEN
      -- �[�i���_�R�[�h
      gt_dlv_base_code      := iv_dlv_base_code;
      -- EDI�`�F�[���X�R�[�h
      gt_edi_chain_code     := iv_edi_chain_code;
      -- �ڋq�R�[�h
      gt_cust_code          := iv_cust_code;
--
      BEGIN
        -- �[�i��FROM
        gt_dlv_date_from    := TO_DATE( iv_dlv_date_from, ct_target_date_format );
        -- �[�i��TO
        gt_dlv_date_to      := TO_DATE( iv_dlv_date_to  , ct_target_date_format );
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_format_date_err_expt;
      END;
--
      BEGIN
        IF ( iv_user_name IS NOT NULL ) THEN
          -- �쐬��
          SELECT  fu.user_id  AS user_id  -- ���[�UID
          INTO  gt_created_by
          FROM    fnd_user  fu  -- ���[�U�}�X�^
          WHERE   fu.user_name  =  iv_user_name
          ;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_nm,
                             iv_name        => cv_fnd_user
                           );
          RAISE global_select_data_expt;
      END;
--
      -- �󒍔ԍ�
      gt_order_number       := TO_NUMBER( iv_order_number );
    END IF;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
                       iv_token_value1  =>  TO_CHAR(iv_target_date)
                      );
--
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    -- *** �f�[�^�擾��O�n���h�� ***
    WHEN global_select_data_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm,
                     iv_name         => ct_msg_select_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_table_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => NULL
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
    gn_gl_id := TO_NUMBER(lv_gl_id);
--
    --==================================
    -- ����敪�擾
    --==================================
    BEGIN
      SELECT
        flv.meaning         AS transaction_type_id  -- ����^�C�v
        , flv.attribute1    AS sales_class          -- ����敪
      BULK COLLECT INTO
         g_sale_class_sub_tab
      FROM
-- 2009/07/28 Ver.1.9 M.Sano Del Start
--        fnd_application               fa,
--        fnd_lookup_types              flt,
-- 2009/07/28 Ver.1.9 M.Sano Del End
        fnd_lookup_values             flv
      WHERE
-- 2009/07/28 Ver.1.9 M.Sano Mod Start
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
--      AND flv.lookup_type             = ct_qct_sales_class_type
          flv.lookup_type             = ct_qct_sales_class_type
-- 2009/07/28 Ver.1.9 M.Sano Mod End
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = ct_lang
      ;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
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
      g_sale_class_tab(g_sale_class_sub_tab(i).transaction_type_id) := g_sale_class_sub_tab(i);
    END LOOP;
--
    --==================================
    -- �ԍ��t���O�擾
    --==================================
    BEGIN
      SELECT
        flv.meaning      AS transaction_type_id  -- ����^�C�v
        ,flv.attribute1  AS red_black_flag       -- �ԍ��t���O
      BULK COLLECT INTO
         g_red_black_flag_sub_tab
      FROM
-- 2009/07/28 Ver.1.9 M.Sano Del Start
--        fnd_application               fa,
--        fnd_lookup_types              flt,
-- 2009/07/28 Ver.1.9 M.Sano Del End
        fnd_lookup_values             flv
      WHERE
-- 2009/07/28 Ver.1.9 M.Sano Mod Start
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
--      AND flv.lookup_type             = ct_qct_red_black_flag_type
          flv.lookup_type             = ct_qct_red_black_flag_type
-- 2009/07/28 Ver.1.9 M.Sano Mod End
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = ct_lang
      ;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
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
    FOR i IN 1..g_red_black_flag_sub_tab.COUNT LOOP
      g_red_black_flag_tab(g_red_black_flag_sub_tab(i).transaction_type_id) := g_red_black_flag_sub_tab(i);
    END LOOP;
--
    --==================================
    -- �ŃR�[�h�擾�擾
    --==================================
    BEGIN
--
/* 2009/09/11 Ver1.10 Mod Start */
--      SELECT
--        tax_code_mst.tax_class    AS tax_class    -- ����ŋ敪
--      , tax_code_mst.tax_code     AS tax_code     -- �ŃR�[�h
--      , avtab.tax_rate            AS tax_rate     -- �ŗ�
--      , tax_code_mst.tax_include  AS tax_include  -- ���Ńt���O
--      BULK COLLECT INTO
--        g_tax_sub_tab
--      FROM
--        ar_vat_tax_all_b          avtab           -- �ŃR�[�h�}�X�^
--        ,(
--          SELECT
--              flv.attribute3      AS tax_class    -- ����ŋ敪
--            , flv.attribute2      AS tax_code     -- �ŃR�[�h
--            , flv.attribute5      AS tax_include  -- ���Ńt���O
--          FROM
---- 2009/07/28 Ver.1.9 M.Sano Del Start
----            fnd_application       fa,
----            fnd_lookup_types      flt,
---- 2009/07/28 Ver.1.9 M.Sano Del End
--            fnd_lookup_values     flv
--          WHERE
---- 2009/07/28 Ver.1.9 M.Sano Mod Start
----              fa.application_id           = flt.application_id
----          AND flt.lookup_type             = flv.lookup_type
----          AND fa.application_short_name   = cv_xxcos_appl_short_nm
----          AND flv.lookup_type             = ct_qct_tax_type
--              flv.lookup_type             = ct_qct_tax_type
---- 2009/07/28 Ver.1.9 M.Sano Mod End
--         AND flv.start_date_active      <= gd_process_date
--          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--          AND flv.enabled_flag            = ct_yes_flg
---- 2009/07/08 Ver.1.9 M.Sano Mod Start
----          AND flv.language                = USERENV( 'LANG' )
--          AND flv.language                = ct_lang
---- 2009/07/08 Ver.1.9 M.Sano Mod End
--        ) tax_code_mst
--      WHERE
--        tax_code_mst.tax_code     = avtab.tax_code
--        AND avtab.start_date     <= gd_process_date
--        AND gd_process_date      <= NVL( avtab.end_date, gd_max_date )
--        AND enabled_flag          = ct_yes_flg
--        AND avtab.set_of_books_id = gn_gl_id;       -- GL��v����ID
      SELECT  xtv.tax_class                           tax_class         -- ����ŋ敪
             ,xtv.tax_code                            tax_code          -- �ŃR�[�h
             ,xtv.tax_rate                            tax_rate          -- �ŗ�
             ,xtv.start_date_active                   start_date_active -- �K�p�J�n��
             ,NVL( xtv.end_date_active, gd_max_date)  end_date_active   -- �K�p�I����
      BULK COLLECT INTO
        g_tax_tab
      FROM   xxcos_tax_v xtv
      WHERE  xtv.set_of_books_id = gn_gl_id; -- GL��v����ID
/* 2009/09/11 Ver1.10 Mod End   */
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
/* 2009/09/11 Ver1.10 Del Start */
--    FOR i IN 1..g_tax_sub_tab.COUNT LOOP
--      g_tax_tab(g_tax_sub_tab(i).tax_class) := g_tax_sub_tab(i);
--    END LOOP;
/* 2009/09/11 Ver1.10 Del End   */
--
    --==================================
    -- ����ŋ敪������
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
-- 2009/07/28 Ver.1.9 M.Sano Del Start
--        fnd_application       fa,
--        fnd_lookup_types      flt,
-- 2009/07/28 Ver.1.9 M.Sano Del End
        fnd_lookup_values     flv
      WHERE
-- 2009/07/28 Ver.1.9 M.Sano Mod Start
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
--      AND flv.lookup_type             = ct_qct_tax_class_type
          flv.lookup_type             = ct_qct_tax_class_type
-- 2009/07/28 Ver.1.9 M.Sano Mod End
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = ct_lang
      ;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
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
    lv_lock_table   VARCHAR(5000);
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
    lv_create_data_seq NUMBER;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
-- 2009/11/05 Ver.1.13 M.Sano Add Start
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
-- 2009/11/05 Ver.1.13 M.Sano Add End
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
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    IF    ( gt_regular_any_class IS NULL                        ) THEN
      NULL;
    ELSIF ( gt_regular_any_class = cv_regular_any_class_regular ) THEN
-- 2010/08/25 Ver.1.16 S.Arizumi Add END   --
      SELECT
  /* 2009/09/11 Ver1.10 Add Start */
        /*+
          LEADING(ooha)
          USE_NL(oola ooha xca ottth otttl ottth ottal msi)
          USE_NL(ooha xchv)
          USE_NL(xchv.cust_hier.cash_hcar_3 xchv.cust_hier.ship_hzca_3)
          INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
          INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
          INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
          INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
        */
  /* 2009/09/11 Ver1.10 Add End   */
        ooha.header_id                          AS header_id                  -- �󒍃w�b�_ID
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
            ELSE TRUNC(TO_DATE(oola.attribute4,cv_fmt_date_default))
          END 
                                                AS orig_inspect_date          -- �I���W�i��������
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
  -- 2009/07/08 Ver.1.9 M.Sano Add Start
  --      , xeh.invoice_class                     AS invoice_class              -- �`�[�敪
  --      , xeh.big_classification_code           AS invoice_classification_code-- �`�[���ރR�[�h
        , ooha.attribute5                       AS invoice_class              -- �`�[�敪
        , ooha.attribute20                      AS invoice_classification_code-- �`�[���ރR�[�h
  -- 2009/07/08 Ver.1.9 M.Sano Add Start
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
        , NULL                                  AS red_black_flag             -- �ԍ��t���O
        , oola.ordered_item                     AS item_code                  -- �i�ڃR�[�h
        , oola.ordered_quantity *
          DECODE( ottal.order_category_code
                , ct_order_category, -1, 1 )    AS ordered_quantity           -- �󒍐���
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
        , DECODE(msi.attribute1
               , cv_subinventory_class
               , xca.delivery_base_code
               , msi.attribute7)                AS delivery_base_code         -- �[�i���_�R�[�h
        , NULL                                  AS hot_cold_class             -- �g���b
        , NULL                                  AS column_no                  -- �R����No
        , NULL                                  AS sold_out_class             -- ���؋敪
        , NULL                                  AS sold_out_time              -- ���؎���
        , ct_no_flg                             AS to_calculate_fees_flag     -- �萔���v�Z�C���^�t�F�[�X�σt���O
        , ct_no_flg                             AS unit_price_mst_flag        -- �P���}�X�^�쐬�σt���O
        , ct_no_flg                             AS inv_interface_flag         -- INV�C���^�t�F�[�X�σt���O
        , xchv.bill_tax_round_rule              AS bill_tax_round_rule        -- �ŋ��|�[������
        , oola.packing_instructions             AS packing_instructions       -- �o�׈˗�No
        , msi.attribute1                        AS subinventory_class         -- �ۊǏꏊ�敪
        , cn_check_status_normal                AS check_status               -- �`�F�b�N�X�e�[�^�X
  -- 2009/07/08 Ver.1.9 M.Sano Add Start
        , ooha.global_attribute3                AS info_class                 -- ���敪
  -- 2009/07/08 Ver.1.9 M.Sano Add  End 
  -- 2009/09/30 Ver.1.11 M.Sano Add Start
        , NULL                                  AS results_employee_base_code -- ���ьv��҂̋��_�R�[�h
  -- 2009/09/30 Ver.1.11 M.Sano Add Start
      BULK COLLECT INTO
  -- 2009/07/08 Ver.1.9 M.Sano Add Start
  --      g_order_data_tab
        g_order_all_data_tab
  -- 2009/07/08 Ver.1.9 M.Sano Add  End 
      FROM
        oe_order_headers_all        ooha    -- �󒍃w�b�_
        , oe_order_lines_all        oola    -- �󒍖���
        , oe_transaction_types_tl   ottth   -- �󒍃w�b�_�E�v�p����^�C�v
        , oe_transaction_types_tl   otttl   -- �󒍖��דE�v�p����^�C�v
        , oe_transaction_types_all  ottal   -- �󒍖��׎���^�C�v
        , mtl_secondary_inventories msi     -- �ۊǏꏊ�}�X�^
  -- 2009/07/08 Ver.1.9 M.Sano Del Start
  --      , xxcos_edi_headers         xeh     -- EDI�w�b�_���
  -- 2009/07/08 Ver.1.9 M.Sano Del  End 
        , xxcmm_cust_accounts       xca     -- �A�J�E���g�A�h�I���}�X�^
        , xxcos_cust_hierarchy_v    xchv    -- �ڋq�K�wVIEW
      WHERE
            ooha.header_id = oola.header_id                 -- �󒍃w�b�_.�󒍃w�b�_ID���󒍖���.�󒍃w�b�_ID
        -- �󒍃w�b�_.�󒍃^�C�vID���󒍃w�b�_�E�v�p����^�C�v.����^�C�vID
        AND ooha.order_type_id = ottth.transaction_type_id
        -- �󒍖���.���׃^�C�vID���󒍖��דE�v�p����^�C�v.����^�C�vID
        AND oola.line_type_id  = otttl.transaction_type_id
        -- �󒍖���.���׃^�C�vID���󒍖��׎���^�C�v.����^�C�vID
        AND oola.line_type_id  = ottal.transaction_type_id
  -- 2009/07/08 Ver.1.9 M.Sano Mod Start
  --      AND ottth.language = USERENV('LANG')
  --      AND otttl.language = USERENV('LANG')
        AND ottth.language = ct_lang
        AND otttl.language = ct_lang
  -- 2009/07/08 Ver.1.9 M.Sano Mod  End 
        AND ooha.flow_status_code = ct_hdr_status_booked                -- �󒍃w�b�_.�X�e�[�^�X���L����(BOOKED)
        AND ooha.order_category_code  = ct_order_category               -- �󒍃w�b�_.�󒍃J�e�S���R�[�h���ԕi(RETURN)
        -- �󒍖���.�X�e�[�^�X���۰��or���
        AND oola.flow_status_code NOT IN (ct_ln_status_closed, ct_ln_status_cancelled)
        AND ooha.org_id = gn_org_id                                     -- �g�DID
        AND TRUNC(oola.request_date) <= TRUNC(gd_process_date)          -- �󒍖���.�v�������Ɩ����t
  -- 2009/07/08 Ver.1.9 M.Sano Mod Start
  --      AND ooha.orig_sys_document_ref = xeh.order_connection_number(+) -- �󒍃w�b�_.�O���V�X�e���󒍔ԍ�
  --                                                                      --    = EDI�w�b�_���.�󒍊֘A�ԍ�
        -- �󒍃w�b�_.���敪 = NULL or 01 or 02
        AND NVL(ooha.global_attribute3, cv_info_class_01) IN (cv_info_class_01, cv_info_class_02)
  -- 2009/07/08 Ver.1.9 M.Sano Mod  End 
        AND ooha.sold_to_org_id = xca.customer_id                       -- �󒍃w�b�_.�ڋqID = ����ı�޵�Ͻ�.�ڋqID
        AND ooha.sold_to_org_id = xchv.ship_account_id                  -- �󒍃w�b�_.�ڋqID = �ڋq�K�wVIEW.�o�א�ڋqID
  -- 2009/07/08 Ver.1.9 M.Sano Mod Start
  --      AND oola.ordered_item NOT IN (                                  -- �󒍖���.�󒍕i�ځ��G���[�i��
        AND NOT EXISTS (
  -- 2009/07/08 Ver.1.9 M.Sano Mod  End 
                                      SELECT
  /* 2009/09/11 Ver1.10 Add Start */
                                        /*+
                                          USE_NL(flv)
                                        */
  /* 2009/09/11 Ver1.10 Add End   */
                                        flv.lookup_code
                                      FROM
  -- 2009/07/28 Ver.1.9 M.Sano Del Start
  --                                      fnd_application               fa,
  --                                      fnd_lookup_types              flt,
  -- 2009/07/28 Ver.1.9 M.Sano Del End
                                        fnd_lookup_values             flv
                                      WHERE
  -- 2009/07/28 Ver.1.9 M.Sano Mod Start
  --                                        fa.application_id           = flt.application_id
  --                                    AND flt.lookup_type             = flv.lookup_type
  --                                    AND fa.application_short_name   = cv_xxcos_appl_short_nm
  --                                    AND flv.lookup_type             = ct_qct_edi_item_err_type
                                          flv.lookup_type             = ct_qct_edi_item_err_type
  -- 2009/07/28 Ver.1.9 M.Sano Mod End
                                      AND flv.start_date_active      <= gd_process_date
                                      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                      AND flv.enabled_flag            = ct_yes_flg
  -- 2009/07/08 Ver.1.9 M.Sano Mod Start
  --                                    AND flv.language                = USERENV( 'LANG' )
                                      AND flv.language                = ct_lang
                                      AND flv.lookup_code             = oola.ordered_item
  -- 2009/07/08 Ver.1.9 M.Sano Mod  End 
                                   )
        AND oola.subinventory = msi.secondary_inventory_name    -- �󒍖���.�ۊǏꏊ=�ۊǏꏊ�}�X�^.�ۊǏꏊ�R�[�h
        AND oola.ship_from_org_id = msi.organization_id         -- �o�׌��g�DID = 
        AND NOT EXISTS (
                  SELECT
                    'X'
                  FROM (
                       SELECT
  /* 2009/09/11 Ver1.10 Add Start */
                           /*+
                             USE_NL(flv)
                           */
  /* 2009/09/11 Ver1.10 Add End   */
                           flv.attribute1 AS subinventory
                         , flv.attribute2 AS order_type
                         , flv.attribute3 AS line_type
                       FROM
  -- 2009/07/28 Ver.1.9 M.Sano Del Start
  --                       fnd_application               fa,
  --                       fnd_lookup_types              flt,
  -- 2009/07/28 Ver.1.9 M.Sano Del End
                         fnd_lookup_values             flv
                       WHERE
  -- 2009/07/28 Ver.1.9 M.Sano Mod Start
  --                         fa.application_id           = flt.application_id
  --                     AND flt.lookup_type             = flv.lookup_type
  --                     AND fa.application_short_name   = cv_xxcos_appl_short_nm
  --                     AND flv.lookup_type             = ct_qct_sale_exp_condition
                           flv.lookup_type             = ct_qct_sale_exp_condition
  -- 2009/07/28 Ver.1.9 M.Sano Mod End
                       AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                       AND flv.start_date_active      <= gd_process_date
                       AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            = ct_yes_flg
  -- 2009/07/08 Ver.1.9 M.Sano Mod Start
  --                     AND flv.language                = USERENV( 'LANG' )
                       AND flv.language                = ct_lang
  -- 2009/07/08 Ver.1.9 M.Sano Mod End
                    ) flvs
                  WHERE
                    msi.attribute13  = flvs.subinventory                -- �ۊǏꏊ����
                    AND ottth.name   = NVL(flvs.order_type, ottth.name) -- �󒍃^�C�v
                    AND otttl.name   = NVL(flvs.line_type,  otttl.name) -- ���׃^�C�v
            )
  -- 2009/10/20 Ver.1.12 K.Satomura Add Start
        AND oola.global_attribute5 IS NULL
  -- 2009/10/20 Ver.1.12 K.Satomura Add End
      ORDER BY
          ooha.header_id
        , oola.line_id
  -- 2009/11/05 Ver.1.13 M.Sano Mod Start
  --    FOR UPDATE OF
  --        ooha.header_id
  --      , oola.line_id
  --    NOWAIT;
      ;
  -- 2009/11/05 Ver.1.13 M.Sano Mod End
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    ELSIF ( gt_regular_any_class = cv_regular_any_class_any     ) THEN
      SELECT    /*+
                  LEADING( ooha oola ottal msi otttl ottth xca )
                  USE_NL( oola ooha xca ottth otttl ottth ottal msi )
                  USE_NL( ooha xchv )
--                  USE_NL( xchv.cust_hier.cash_hcar_3 xchv.cust_hier.ship_hzca_3 )
--                  INDEX( xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1 )
--                  INDEX( xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1 )
--                  INDEX( xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1 )
--                  INDEX( xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1 )
                 */
                ooha.header_id              AS header_id                    -- �󒍃w�b�_ID
              , oola.line_id                AS line_id                      -- �󒍖���ID
              , ottth.name                  AS order_type                   -- �󒍃^�C�v
              , otttl.name                  AS line_type                    -- ���׃^�C�v
              , ooha.salesrep_id            AS salesrep_id                  -- �c�ƒS��
              , ooha.cust_po_number         AS dlv_invoice_number           -- �[�i�`�[�ԍ�
              , ooha.attribute19            AS order_invoice_number         -- �����`�[�ԍ�
              , ooha.order_number           AS order_number                 -- �󒍔ԍ�
              , oola.line_number            AS line_number                  -- �󒍖��הԍ�
              , NULL                        AS order_no_hht                 -- ��No�iHHT)
              , NULL                        AS order_no_hht_seq             -- ��No�iHHT�j�}��
              , NULL                        AS dlv_invoice_class            -- �[�i�`�[�敪
              , NULL                        AS cancel_correct_class         -- ����E�����敪
              , NULL                        AS input_class                  -- ���͋敪
              , xca.business_low_type       AS cust_gyotai_sho              -- �Ƒԁi�����ށj
              , NULL                        AS dlv_date                     -- �[�i��
              , TRUNC( oola.request_date )  AS org_dlv_date                 -- �I���W�i���[�i��
              , NULL                        AS inspect_date                 -- ������
              , CASE WHEN oola.attribute4 IS NULL
                  THEN TRUNC( oola.request_date                               )
                  ELSE TRUNC( TO_DATE( oola.attribute4, cv_fmt_date_default ) )
                END                         AS orig_inspect_date            -- �I���W�i��������
              , xca.customer_code           AS ship_to_customer_code        -- �ڋq�[�i��
              , xchv.bill_tax_div           AS consumption_tax_class        -- ����ŋ敪
              , NULL                        AS tax_code                     -- �ŋ��R�[�h
              , NULL                        AS tax_rate                     -- ����ŗ�
              , NULL                        AS results_employee_code        -- ���ьv��҃R�[�h
              , xca.sale_base_code          AS sale_base_code               -- ���㋒�_�R�[�h
              , xca.past_sale_base_code     AS last_month_sale_base_code    -- �O�����㋒�_�R�[�h
              , xca.rsv_sale_base_act_date  AS rsv_sale_base_act_date       -- �\�񔄏㋒�_�L���J�n��
              , xchv.cash_receiv_base_code  AS receiv_base_code             -- �������_�R�[�h
              , ooha.order_source_id        AS order_source_id              -- �󒍃\�[�XID
              , ooha.orig_sys_document_ref  AS order_connection_number      -- �O���V�X�e���󒍔ԍ�
              , NULL                        AS card_sale_class              -- �J�[�h����敪
              , ooha.attribute5             AS invoice_class                -- �`�[�敪
              , ooha.attribute20            AS invoice_classification_code  -- �`�[���ރR�[�h
              , NULL                        AS change_out_time_100          -- ��K�؂ꎞ�ԂP�O�O�~
              , NULL                        AS change_out_time_10           -- ��K�؂ꎞ�ԂP�O�~
              , ct_no_flg                   AS ar_interface_flag            -- AR�C���^�t�F�[�X�σt���O
              , ct_no_flg                   AS gl_interface_flag            -- GL�C���^�t�F�[�X�σt���O
              , ct_no_flg                   AS dwh_interface_flag           -- ���V�X�e���C���^�t�F�[�X�σt���O
              , ct_no_flg                   AS edi_interface_flag           -- EDI���M�ς݃t���O
              , NULL                        AS edi_send_date                -- EDI���M����
              , NULL                        AS hht_dlv_input_date           -- HHT�[�i���͓���
              , NULL                        AS dlv_by_code                  -- �[�i�҃R�[�h
              , cv_business_cost            AS create_class                 -- �쐬���敪
              , oola.line_number            AS dlv_invoice_line_number      -- �[�i���הԍ�
              , oola.line_number            AS order_invoice_line_number    -- �������הԍ�
              , oola.attribute5             AS sales_class                  -- ����敪
              , NULL                        AS delivery_pattern_class       -- �[�i�`�ԋ敪
              , NULL                        AS red_black_flag               -- �ԍ��t���O
              , oola.ordered_item           AS item_code                    -- �i�ڃR�[�h
              ,   oola.ordered_quantity
                * DECODE( ottal.order_category_code
                        , ct_order_category, -1
                        , 1 )               AS ordered_quantity             -- �󒍐���
              , 0                           AS base_quantity                -- �����
              , oola.order_quantity_uom     AS order_quantity_uom           -- �󒍒P��
              , NULL                        AS base_uom                     -- ��P��
              , 0                           AS standard_unit_price          -- �Ŕ���P��
              , 0                           AS base_unit_price              -- ��P��
              , oola.unit_selling_price     AS unit_selling_price           -- �̔��P��
              , 0                           AS business_cost                -- �c�ƌ���
              , 0                           AS sale_amount                  -- ������z
              , 0                           AS pure_amount                  -- �{�̋��z
              , 0                           AS tax_amount                   -- ����ŋ��z
              , NULL                        AS cash_and_card                -- �����E�J�[�h���p�z
              , oola.subinventory           AS ship_from_subinventory_code  -- �o�׌��ۊǏꏊ
              , DECODE( msi.attribute1
                      , cv_subinventory_class, xca.delivery_base_code
                      , msi.attribute7 )    AS delivery_base_code           -- �[�i���_�R�[�h
              , NULL                        AS hot_cold_class               -- �g���b
              , NULL                        AS column_no                    -- �R����No
              , NULL                        AS sold_out_class               -- ���؋敪
              , NULL                        AS sold_out_time                -- ���؎���
              , ct_no_flg                   AS to_calculate_fees_flag       -- �萔���v�Z�C���^�t�F�[�X�σt���O
              , ct_no_flg                   AS unit_price_mst_flag          -- �P���}�X�^�쐬�σt���O
              , ct_no_flg                   AS inv_interface_flag           -- INV�C���^�t�F�[�X�σt���O
              , xchv.bill_tax_round_rule    AS bill_tax_round_rule          -- �ŋ��|�[������
              , oola.packing_instructions   AS packing_instructions         -- �o�׈˗�No
              , msi.attribute1              AS subinventory_class           -- �ۊǏꏊ�敪
              , cn_check_status_normal      AS check_status                 -- �`�F�b�N�X�e�[�^�X
              , ooha.global_attribute3      AS info_class                   -- ���敪
              , NULL                        AS results_employee_base_code   -- ���ьv��҂̋��_�R�[�h
      BULK COLLECT INTO g_order_all_data_tab
      FROM      oe_order_headers_all      ooha   -- �󒍃w�b�_
              , oe_order_lines_all        oola   -- �󒍖���
              , oe_transaction_types_tl   ottth  -- �󒍃w�b�_�E�v�p����^�C�v
              , oe_transaction_types_tl   otttl  -- �󒍖��דE�v�p����^�C�v
              , oe_transaction_types_all  ottal  -- �󒍖��׎���^�C�v
              , mtl_secondary_inventories msi    -- �ۊǏꏊ�}�X�^
              , xxcmm_cust_accounts       xca    -- �A�J�E���g�A�h�I���}�X�^
              , xxcos_cust_hierarchy_v    xchv   -- �ڋq�K�wVIEW
      WHERE     ooha.header_id              =  oola.header_id
        AND     ooha.order_type_id          =  ottth.transaction_type_id
        AND     ottth.language              =  ct_lang
        AND     oola.line_type_id           =  otttl.transaction_type_id
        AND     otttl.language              =  ct_lang
        AND     oola.line_type_id           =  ottal.transaction_type_id
        AND     ooha.flow_status_code       =  ct_hdr_status_booked         -- �L����
        AND     ooha.order_category_code    =  ct_order_category            -- �ԕi
        AND     oola.flow_status_code       NOT IN( ct_ln_status_closed     -- �N���[�Y
                                                  , ct_ln_status_cancelled  -- ���
                                            )
        AND     ooha.org_id                 =  gn_org_id
        AND     TRUNC( oola.request_date )  <= gd_process_date
        AND     NVL( ooha.global_attribute3
                   , cv_info_class_01 )     IN( cv_info_class_01
                                              , cv_info_class_02
                                            )
        AND     ooha.sold_to_org_id         =  xca.customer_id
        AND     ooha.sold_to_org_id         =  xchv.ship_account_id
        AND     NOT EXISTS( SELECT  /*+
--                                      USE_NL( flv )
                                     */
                                    flv.lookup_code
                            FROM    fnd_lookup_values flv
                            WHERE   flv.lookup_type       =  ct_qct_edi_item_err_type
                              AND   flv.start_date_active <= gd_process_date
                              AND   gd_process_date       <= NVL( flv.end_date_active, gd_max_date )
                              AND   flv.enabled_flag      =  ct_yes_flg
                              AND   flv.language          =  ct_lang
                              AND   flv.lookup_code       =  oola.ordered_item
                )
        AND     oola.subinventory           =  msi.secondary_inventory_name
        AND     oola.ship_from_org_id       =  msi.organization_id
        AND     NOT EXISTS( SELECT  'X'
                            FROM    ( SELECT  /*+
--                                                USE_NL(flv)
                                               */
                                              flv.attribute1  AS subinventory
                                            , flv.attribute2 AS order_type
                                            , flv.attribute3 AS line_type
                                      FROM    fnd_lookup_values flv
                                      WHERE   flv.lookup_type       =  ct_qct_sale_exp_condition
                                        AND   flv.lookup_code       LIKE ct_qcc_sale_exp_condition
                                        AND   flv.start_date_active <= gd_process_date
                                        AND   gd_process_date       <= NVL( flv.end_date_active, gd_max_date )
                                        AND   flv.enabled_flag      =  ct_yes_flg
                                        AND   flv.language          =  ct_lang
                                    ) flvs
                            WHERE   msi.attribute13 =  flvs.subinventory
                              AND   ottth.name      =  NVL( flvs.order_type, ottth.name )
                              AND   otttl.name      =  NVL( flvs.line_type , otttl.name )
                )
        AND     oola.global_attribute5      IS NULL
        AND     DECODE( msi.attribute1
                      , cv_subinventory_class, xca.delivery_base_code
                      , msi.attribute7 )    =  gt_dlv_base_code
        AND     (     gt_edi_chain_code     IS NULL
                  OR  xca.chain_store_code  =  gt_edi_chain_code
                )
        AND     xca.customer_code           =  NVL( gt_cust_code     , xca.customer_code    )
        AND     TRUNC( oola.request_date )  BETWEEN gt_dlv_date_from
                                                AND gt_dlv_date_to
        AND     ooha.created_by             =  NVL( gt_created_by    , ooha.created_by      )
        AND     ooha.order_number           =  NVL( gt_order_number  , ooha.order_number    )
      ORDER BY  ooha.header_id
              , oola.line_id
      ;
    END IF;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
    --�f�[�^���������́u�Ώۃf�[�^�Ȃ��G���[���b�Z�[�W�v
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--    IF ( g_order_data_tab.COUNT = 0 ) THEN
    IF ( g_order_all_data_tab.COUNT = 0 ) THEN
-- 2009/07/08 Ver.1.9 M.Sano Mod End
      RAISE global_no_data_warm_expt;
    END IF;
--
    -- �Ώی���
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--    gn_target_cnt := g_order_data_tab.COUNT;
    gn_target_cnt := g_order_all_data_tab.COUNT;
--
-- 2009/11/05 Ver.1.13 M.Sano Add Start
    -- �󒍖��ׂ̍s���b�N����
    <<loop_lock>>
    FOR i IN 1..g_order_all_data_tab.COUNT LOOP
      OPEN order_lines_cur( g_order_all_data_tab(i).line_id );
      CLOSE order_lines_cur;
    END LOOP loop_lock;
--
-- 2009/11/05  Ver.1.13 M.Sano Add End
    -- �擾�����󒍃f�[�^����ԕi���э쐬�Ώۂ̂��̂𒊏o����B
    lv_create_data_seq := 0;
    <<get_sales_created_data_loop>>
    FOR i in 1..g_order_all_data_tab.COUNT LOOP
      IF ( NVL(g_order_all_data_tab(i).info_class, cv_info_class_01) = cv_info_class_01 ) THEN
        lv_create_data_seq := lv_create_data_seq + 1;
        g_order_data_tab(lv_create_data_seq) := g_order_all_data_tab(i);
      END IF;
    END LOOP get_sales_created_data_loop;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
--
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
     iv_account_period         => iv_div,         -- ��v�敪
     id_base_date              => id_base_date,   -- ���
     ov_status                 => lv_status,      -- �X�e�[�^�X
     od_start_date             => ld_date_from,   -- ��v(FROM)
     od_end_date               => ld_date_to,     -- ��v(TO)
     ov_errbuf                 => lv_errbuf,      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
     ov_retcode                => lv_retcode,     -- ���^�[���E�R�[�h               #�Œ�#
     ov_errmsg                 => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
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
     iv_account_period         => iv_div,         -- ��v�敪
     id_base_date              => NULL,           -- ���
     ov_status                 => lv_status,      -- �X�e�[�^�X
     od_start_date             => ld_date_from,   -- ��v(FROM)
     od_end_date               => ld_date_to,     -- ��v(TO)
     ov_errbuf                 => lv_errbuf,      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
     ov_retcode                => lv_retcode,     -- ���^�[���E�R�[�h               #�Œ�#
     ov_errmsg                 => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
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
    cv_cust_po_number_first   CONSTANT VARCHAR2(1) := 'I';     -- �ڋq�����̐擪����
--
    -- *** ���[�J���ϐ� ***
    lv_item_id                ic_item_mst_b.item_id%type; --  �i��ID
    lv_organization_code      VARCHAR(100);               --  �݌ɑg�D�R�[�h
    ln_organization_id        NUMBER;                     --  �݌ɑg�D�h�c
    ln_content                NUMBER;                     --  ����
    ld_base_date              DATE;                       --  ���
    lv_table_name             VARCHAR(100);               --  �e�[�u����
    lv_key_data               VARCHAR(5000);              --  �L�[���
    ln_tax                    NUMBER;                     --  �����
    ln_pure_amount            NUMBER;                     --  �{�̋��z
--****************************** 2009/06/08 1.7 T.Kitajima ADD START ******************************--
    ln_tax_amount             NUMBER;                     --  ����Ōv�Z���[�N�ϐ�
--****************************** 2009/06/08 1.7 T.Kitajima ADD  END  ******************************--

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
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--        iv_div        => cv_fiscal_period_ar             -- ��v�敪
        iv_div        => cv_fiscal_period_inv            -- ��v�敪
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
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
    -- 2.����v����Z�o
    --==================================
    get_fiscal_period_from(
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--        iv_div        => cv_fiscal_period_ar                  -- ��v�敪
        iv_div        => cv_fiscal_period_inv                 -- ��v�敪
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
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
        iv_before_uom_code    => io_order_rec.order_quantity_uom   --���Z�O�P�ʃR�[�h = �󒍒P��
      , in_before_quantity    => io_order_rec.ordered_quantity     --���Z�O����       = �󒍐���
      , iov_item_code         => io_order_rec.item_code            --�i�ڃR�[�h
      , iov_organization_code => lv_organization_code              --�݌ɑg�D�R�[�h   =NULL
      , ion_inventory_item_id => lv_item_id                        --�i�ڂh�c         =NULL
      , ion_organization_id   => ln_organization_id                --�݌ɑg�D�h�c     =NULL
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
--
    --==================================
    -- 4.�ŗ��A�ŃR�[�h
    --==================================
/* 2009/09/11 Ver1.10 Mod Start */
--    IF ( g_tax_tab.EXISTS(io_order_rec.consumption_tax_class) ) THEN
--
--      io_order_rec.tax_rate := NVL(g_tax_tab(io_order_rec.consumption_tax_class).tax_rate, 0);
--
--    ELSE
--
--      io_order_rec.tax_rate := 0;
--
--    END IF;

    FOR i IN 1..g_tax_tab.COUNT LOOP
      IF ( g_tax_tab(i).tax_class = io_order_rec.consumption_tax_class )
        AND ( g_tax_tab(i).start_date_active <= io_order_rec.inspect_date )
        AND ( g_tax_tab(i).end_date_active   >= io_order_rec.inspect_date )
      THEN
         io_order_rec.tax_rate  := NVL(g_tax_tab(i).tax_rate, 0);  -- �ŗ�
         io_order_rec.tax_code  := g_tax_tab(i).tax_code;          -- �ŃR�[�h
         EXIT;
      ELSE
        io_order_rec.tax_rate  := 0;
        io_order_rec.tax_code  := NULL;
      END IF;
    END LOOP;
/* 2009/09/11 Ver1.10 Mod End   */
--
--
-- ************ 2011/02/07 1.17 Y.Nishino ADD START ************ --
    --==================================
    -- �P��0�~�`�F�b�N
    --==================================
    IF( io_order_rec.unit_selling_price = 0 ) THEN
      -- �̔��P����0�~�̏ꍇ�͊Y���f�[�^���N���[�Y���Ȃ�
      ld_base_date := io_order_rec.org_dlv_date; -- �I���W�i���[�i��
      RAISE global_price_err_expt;
    END IF;
-- ************ 2011/02/07 1.17 Y.Nishino ADD END   ************ --
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
/* 2009/06/01 Ver1.6 Mod Start */
--      -- ����� �� ��P�� �| ��P�� �� ( 1 �{ ����ŗ� �� 100 )
--      ln_tax := io_order_rec.base_unit_price
--              - io_order_rec.base_unit_price / ( 1 + io_order_rec.tax_rate / 100 );
----
--      -- �؏�
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--/* 2009/05/18 Ver1.5 Mod Start */
--        --�����_�����݂���ꍇ
--        IF ( ln_tax - TRUNC( ln_tax ) <> 0 ) THEN
--          ln_tax := TRUNC( ln_tax ) + 1;
--        END IF;
--/* 2009/05/18 Ver1.5 Mod End   */
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
/* 2009/06/01 Ver1.6 Mod End   */
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
/* 2009/05/18 Ver1.5 Add Start */
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
      -- ����� �� (�󒍐��� �~ �̔��P��) - (�󒍐��� �~ �̔��P�� �~ 100��(����ŗ��{100))
--****************************** 2009/06/08 1.7 T.Kitajima MOD START ******************************--
--      io_order_rec.tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
--                                   - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
--                                       * 100 / ( io_order_rec.tax_rate + 100 ) );
--
--      -- �؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
----
--        -- �����_�ȉ������݂���ꍇ
--        IF ( io_order_rec.tax_amount - TRUNC( io_order_rec.tax_amount ) <> 0 ) THEN
----
--          io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount ) - 1;
----
--        END IF;
----
--      -- �؎̂�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
----
--        io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount );
----
----      -- �l�̌ܓ�
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
----
----        io_order_rec.tax_amount := ROUND( io_order_rec.tax_amount );
----
--      END IF;
--
      ln_tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
                         - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                             * 100 / ( io_order_rec.tax_rate + 100 ) );
--
      -- �؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--
        -- �����_�ȉ������݂���ꍇ
        IF ( ln_tax_amount - TRUNC( ln_tax_amount ) <> 0 ) THEN
--
          io_order_rec.tax_amount := TRUNC( ln_tax_amount ) - 1;
--****************************** 2009/06/10 1.8 T.Kitajima ADD START ******************************--
        ELSE
          io_order_rec.tax_amount := ln_tax_amount;
--****************************** 2009/06/10 1.8 T.Kitajima ADD  END  ******************************--
--
        END IF;
--
      -- �؎̂�
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--
        io_order_rec.tax_amount := TRUNC( ln_tax_amount );
--
      -- �l�̌ܓ�
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--
        io_order_rec.tax_amount := ROUND( ln_tax_amount );
--
      END IF;
--****************************** 2009/06/08 1.7 T.Kitajima MOD  END  ******************************--
--
    ELSE
--
      -- ����� �� �󒍐��� �~ �̔��P�� �~ �i����ŗ���100�j�������_�ȉ��l�̌ܓ�
      io_order_rec.tax_amount := ROUND( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                                   * ( io_order_rec.tax_rate / 100 ) );
--
    END IF;
/* 2009/05/18 Ver1.5 Add End   */
--
--
    --==================================
    -- 9.�{�̋��z
    --==================================
    -- ����ŋ敪 �� ����(�P������)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/05/18 Ver1.5 Mod Start */
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
/* 2009/05/19 Ver1.5 Mod End   */
--
    ELSE
--
      -- �{�̋��z �� ������z
      io_order_rec.pure_amount := io_order_rec.sale_amount;
--
    END IF;
--
--
/* 2009/05/18 Ver1.5 Del Start */
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
/* 2009/05/18 Ver1.5 Del End   */
--
--
/* 2009/09/11 Ver1.10 Del Start */
--    --==================================
--    -- 10.�ŃR�[�h�擾
--    --==================================
--    IF ( g_tax_tab.EXISTS(io_order_rec.consumption_tax_class) ) THEN
--      io_order_rec.tax_code := g_tax_tab(io_order_rec.consumption_tax_class).tax_code;
--    ELSE
--      io_order_rec.tax_code := NULL;
--    END IF;
/* 2009/09/11 Ver1.10 Del End   */
--
    --==================================
    -- 11.����敪
    --==================================
    IF ( io_order_rec.sales_class IS NULL AND g_sale_class_tab.EXISTS(io_order_rec.line_type) ) THEN
        io_order_rec.sales_class := g_sale_class_tab(io_order_rec.line_type).sales_class;
    END IF;
--
    --==================================
    -- 12.�[�i�`�[�敪�擾
    --==================================
    BEGIN
        SELECT
          flv.attribute3   --�[�i�`�[�敪
        INTO
          io_order_rec.dlv_invoice_class
        FROM
-- 2009/07/28 Ver.1.9 M.Sano DEL Start
--          fnd_application               fa,
--          fnd_lookup_types              flt,
-- 2009/07/28 Ver.1.9 M.Sano DEL End
          fnd_lookup_values             flv
        WHERE
-- 2009/07/28 Ver.1.9 M.Sano Mod End
--              fa.application_id           = flt.application_id
--          AND flt.lookup_type             = flv.lookup_type
--          AND fa.application_short_name   = cv_xxcos_appl_short_nm
--          AND flv.lookup_type             = ct_qct_dlv_slp_cls_type
              flv.lookup_type             = ct_qct_dlv_slp_cls_type
-- 2009/07/28 Ver.1.9 M.Sano MOd End
          AND flv.lookup_code          LIKE ct_qcc_dlv_slp_cls_type
          AND flv.start_date_active      <= gd_process_date
          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
          AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--          AND flv.language                = USERENV( 'LANG' )
          AND flv.language                = ct_lang
-- 2009/07/08 Ver.1.9 M.Sano Mod End
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
-- ****** 2010/03/09 N.Maeda 1.15 MOD START ****** --
--    IF ( TRUNC(io_order_rec.dlv_date) < TRUNC(io_order_rec.rsv_sale_base_act_date) ) THEN
    IF ( TRUNC( io_order_rec.dlv_date , cv_trunc_mm ) < gd_business_date_trunc_mm ) THEN
-- ****** 2010/03/09 N.Maeda 1.15 MOD  END  ****** --
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
    -- 15.�ԍ��t���O
    --==================================
    IF ( g_red_black_flag_tab.EXISTS(io_order_rec.line_type) ) THEN
      io_order_rec.red_black_flag := g_red_black_flag_tab(io_order_rec.line_type).red_black_flag;
    ELSE
      io_order_rec.red_black_flag := NULL;
    END IF;
--
    --==================================
    -- 16.�c�ƌ����Z�o
    --==================================
    BEGIN
      SELECT
        CASE
          WHEN iimb.attribute9 > TO_CHAR(io_order_rec.dlv_date, ct_target_date_format)
            THEN iimb.attribute7    -- �c�ƌ���(��)
          ELSE
            iimb.attribute8         -- �c�ƌ���(�V)
        END
      INTO
        io_order_rec.business_cost  -- �c�ƌ���
      FROM
        ic_item_mst_b     iimb,     -- OPM�i��
        xxcmn_item_mst_b  ximb      -- OPM�i�ڃA�h�I��
      WHERE
            iimb.item_no = io_order_rec.item_code
        AND iimb.item_id = ximb.item_id
        AND TRUNC(ximb.start_date_active) <= io_order_rec.dlv_date
        AND NVL(ximb.end_date_active, gd_max_date) >= io_order_rec.dlv_date;
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
    -- 17.�]�ƈ��}�X�^���擾
    --==================================
    BEGIN
--
      SELECT
        papf.employee_number                -- �]�ƈ��ԍ�
-- 2009/09/30 Ver.1.11 M.Sano Add Start
        , CASE
            WHEN NVL( TO_DATE( paaf.ass_attribute2, cv_fmt_date_rrrrmmdd )
                    , TRUNC(io_order_rec.dlv_date) ) <= TRUNC(io_order_rec.dlv_date)
            THEN
              paaf.ass_attribute5
            ELSE
              paaf.ass_attribute6
          END                employee_base_code -- �]�ƈ��̏������_�R�[�h
-- 2009/09/30 Ver.1.11 M.Sano Add End
      INTO
        io_order_rec.results_employee_code  -- ���ьv��҃R�[�h
-- 2009/09/30 Ver.1.11 M.Sano Add Start
        , io_order_rec.results_employee_base_code -- ���ьv��҂̏������_�R�[�h
-- 2009/09/30 Ver.1.11 M.Sano Add End
      FROM
          jtf_rs_resource_extns jrre        -- ���\�[�X�}�X�^
        , per_all_people_f papf             -- �]�ƈ��}�X�^
        , jtf_rs_salesreps jrs              -- 
-- 2009/09/30 Ver.1.11 M.Sano Add Start
        , per_all_assignments_f paaf        -- �]�ƈ��^�C�v�}�X�^
-- 2009/09/30 Ver.1.11 M.Sano Add End
      WHERE
          jrs.salesrep_id = io_order_rec.salesrep_id
      AND jrs.resource_id = jrre.resource_id
      AND jrre.source_id = papf.person_id
-- 2009/09/30 Ver.1.11 M.Sano Add Start
      AND papf.person_id  = paaf.person_id
      AND TRUNC(paaf.effective_start_date) <= TRUNC(io_order_rec.dlv_date)
      AND TRUNC(paaf.effective_end_date)   >= TRUNC(io_order_rec.dlv_date)
-- 2009/09/30 Ver.1.11 M.Sano Add End
      AND TRUNC(papf.effective_start_date) <= TRUNC(io_order_rec.dlv_date)
      AND TRUNC(NVL(papf.effective_end_date,io_order_rec.dlv_date)) >= io_order_rec.dlv_date;
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
    -- 18.�[�i�`�[�ԍ�
    --==================================
    IF ( io_order_rec.subinventory_class = cv_subinventory_class
        AND SUBSTR( io_order_rec.dlv_invoice_number, 1, 1 ) = cv_cust_po_number_first
        AND io_order_rec.packing_instructions IS NOT NULL ) THEN
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
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--                    iv_token_value1=> cv_fiscal_period_ar,        -- AR��v���ԋ敪�l
                    iv_token_value1=> cv_fiscal_period_tkn_inv,   -- INV
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
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
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
      set_gen_err_list(
          ov_errbuf                   => lv_errbuf
        , ov_retcode                  => lv_retcode
        , ov_errmsg                   => lv_errmsg
        , it_base_code                => io_order_rec.delivery_base_code
        , it_message_name             => ct_msg_fiscal_period_err
        , it_message_text             => NULL
        , iv_output_msg_application   => cv_xxcos_appl_short_nm
        , iv_output_msg_name          => ct_msg_xxcos_00207
        , iv_output_msg_token_name1   => cv_tkn_order_number                          -- �g�[�N��01�F�󒍔ԍ�
        , iv_output_msg_token_value1  => TO_CHAR( io_order_rec.order_number )         -- �l01      �F�󒍔ԍ�
        , iv_output_msg_token_name2   => cv_tkn_line_number                           -- �g�[�N��02�F�󒍖��הԍ�
        , iv_output_msg_token_value2  => TO_CHAR( io_order_rec.line_number )          -- �l02      �F�󒍖��הԍ�
        , iv_output_msg_token_name3   => cv_tkn_base_date                             -- �g�[�N��03�F���
        , iv_output_msg_token_value3  => TO_CHAR( ld_base_date, cv_fmt_date_default ) -- �l03      �F���
      );
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
      set_gen_err_list(
          ov_errbuf                   => lv_errbuf
        , ov_retcode                  => lv_retcode
        , ov_errmsg                   => lv_errmsg
        , it_base_code                => io_order_rec.delivery_base_code
        , it_message_name             => ct_msg_select_odr_err
        , it_message_text             => NULL
        , iv_output_msg_application   => cv_xxcos_appl_short_nm
        , iv_output_msg_name          => ct_msg_xxcos_00206
        , iv_output_msg_token_name1   => cv_tkn_order_number                          -- �g�[�N��01�F�󒍔ԍ�
        , iv_output_msg_token_value1  => TO_CHAR( io_order_rec.order_number )         -- �l01      �F�󒍔ԍ�
        , iv_output_msg_token_name2   => cv_tkn_line_number                           -- �g�[�N��02�F�󒍖��הԍ�
        , iv_output_msg_token_value2  => TO_CHAR( io_order_rec.line_number )          -- �l02      �F�󒍖��הԍ�
      );
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
-- ************ 2011/02/07 1.17 Y.Nishino ADD START ************ --
    WHEN global_price_err_expt THEN
    -- *** �P��0�~��O�n���h�� ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_nm,
                    iv_name         => ct_price0_line_type_err,
                    iv_token_name1  => cv_tkn_order_number,
                    iv_token_value1 => io_order_rec.order_number,  -- �󒍔ԍ�
                    iv_token_name2  => cv_tkn_line_number,
                    iv_token_value2 => io_order_rec.line_number    -- �󒍖��הԍ�
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name ||
                             cv_msg_part || ov_errmsg , 1 , 5000 );
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
      set_gen_err_list(
          ov_errbuf                   => lv_errbuf
        , ov_retcode                  => lv_retcode
        , ov_errmsg                   => lv_errmsg
        , it_base_code                => io_order_rec.delivery_base_code
        , it_message_name             => ct_line_type_err_lst
        , it_message_text             => NULL
        , iv_output_msg_application   => cv_xxcos_appl_short_nm
        , iv_output_msg_name          => ct_msg_xxcos_00207
        , iv_output_msg_token_name1   => cv_tkn_order_number                          -- �g�[�N��01�F�󒍔ԍ�
        , iv_output_msg_token_value1  => TO_CHAR( io_order_rec.order_number )         -- �l01      �F�󒍔ԍ�
        , iv_output_msg_token_name2   => cv_tkn_line_number                           -- �g�[�N��02�F�󒍖��הԍ�
        , iv_output_msg_token_value2  => TO_CHAR( io_order_rec.line_number )          -- �l02      �F�󒍖��הԍ�
        , iv_output_msg_token_name3   => cv_tkn_base_date                             -- �g�[�N��03�F���
        , iv_output_msg_token_value3  => TO_CHAR( ld_base_date, cv_fmt_date )         -- �l03      �F���
      );
--
-- ************ 2011/02/07 1.17 Y.Nishino ADD END   ************ --
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
    lv_field_name   VARCHAR2(5000);
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
    -- �ԍ��t���O
    IF ( io_order_data_rec.red_black_flag IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_red_black_flag);
    END IF;
    -- �[�i���_�R�[�h
    IF ( io_order_data_rec.delivery_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_delivery_base_code);
    END IF;
--
    IF ( lv_field_name IS NOT NULL ) THEN
      lv_field_name := SUBSTR(lv_field_name , 2); -- �n�߂̃f���~�^���폜
      RAISE global_not_null_col_warm_expt;
    END IF;
--
  EXCEPTION
    -- *** �K�{���ڃG���[��O�n���h�� ***
    WHEN global_not_null_col_warm_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_null_column_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_data_rec.order_number,
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_data_rec.line_number,
                    iv_token_name3 => cv_tkn_field_name,
                    iv_token_value3=> lv_field_name
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_data_rec.check_status := cn_check_status_error;
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
-- 2009/09/30 Ver.1.11 M.Sano Add Start
--
  /**********************************************************************************
   * Procedure Name   : check_results_employee
   * Description      : ����v��҂̏������_�`�F�b�N(A-5-1)
   ***********************************************************************************/
  PROCEDURE check_results_employee(
    ov_errbuf          OUT VARCHAR2,             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_results_employee'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lt_base_name    hz_parties.party_name%TYPE;     -- ���㋒�_��
    ln_err_flag     NUMBER;                         -- �w�b�_�ɂăG���[�Ȃ����ꍇ�̌���
    ln_idx          NUMBER;
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    lv_errmsg_prefix VARCHAR2( 5000 );              -- �ėp�G���[���X�g�p���b�Z�[�W
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_base_err_order_tab  g_base_err_order_ttype;  -- ����v��ҏ������_�s�����G���[�f�[�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- ���ьv��҂̏������_�Ɣ��㋒�_������ł��邱�Ƃ��m�F����B
    -- ==============================================================
    <<loop_chek_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      --�̔����уw�b�_�쐬�P�ʂŐ��ьv��҂̏������_���`�F�b�N
      IF ((i = 1) OR (   g_order_data_tab(i).header_id          != g_order_data_tab(i-1).header_id
                      OR g_order_data_tab(i).dlv_date           != g_order_data_tab(i-1).dlv_date
                      OR g_order_data_tab(i).inspect_date       != g_order_data_tab(i-1).inspect_date
                      OR g_order_data_tab(i).dlv_invoice_number != g_order_data_tab(i-1).dlv_invoice_number ) ) THEN
-- 
        IF (    g_order_data_tab(i).sale_base_code <> g_order_data_tab(i).results_employee_base_code
            AND g_order_data_tab(i).check_status = cn_check_status_normal
           ) THEN
          --�E���ьv��ҋ��_�s��v�G���[���X�g�ɒǉ�
          --[�ǉ��ʒu���擾]
          ln_idx := l_base_err_order_tab.COUNT + 1;
          --[���㋒�_�R�[�h]
          l_base_err_order_tab(ln_idx).sale_base_code             := g_order_data_tab(i).sale_base_code;
          --[�[�i�`�[�ԍ�]
          l_base_err_order_tab(ln_idx).dlv_invoice_number         := g_order_data_tab(i).dlv_invoice_number;
          --[�ڋq�R�[�h]
          l_base_err_order_tab(ln_idx).ship_to_customer_code      := g_order_data_tab(i).ship_to_customer_code;
          --[���ьv��҃R�[�h]
          l_base_err_order_tab(ln_idx).results_employee_code      := g_order_data_tab(i).results_employee_code;
          --[���ьv��҂̋��_�R�[�h]
          l_base_err_order_tab(ln_idx).results_employee_base_code := g_order_data_tab(i).results_employee_base_code;
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
          --[�[�i���_�R�[�h]
          l_base_err_order_tab( ln_idx ).delivery_base_code       := g_order_data_tab( i ).delivery_base_code;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
          --[�o�̓t���O]
          l_base_err_order_tab(ln_idx).output_flag                := ct_yes_flg;
          --�G���[�t���O��L���֕ύX�B
          ln_err_flag := cn_check_status_error;
        ELSE
          --�G���[�t���O�𖳌��֕ύX�B
          ln_err_flag := cn_check_status_normal;
        END IF;
      END IF;
--
      -- �G���[�t���O���L���̏ꍇ�A�X�e�[�^�X���G���[�ɕύX�B
      IF ( ln_err_flag = cn_check_status_error ) THEN
        --�`�F�b�N�X�e�[�^�X���X�V
        g_order_data_tab(i).check_status := cn_check_status_error;
        --�x��������+1
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
    END LOOP g_base_err_data1_loop;
--
    -- ====================================================================
    -- ������1���ȏ㑶�݂���ꍇ�A���ьv��ҏ������_�s�����G���[���o��
    -- ====================================================================
    IF ( l_base_err_order_tab.COUNT <> 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm
                       , iv_name        => cv_msg_base_mismatch_err
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
    END IF;
    -- ====================================================================
    -- ���ьv��ҏ������_�s�����G���[�̑Ώۃp�����[�^���o��
    -- ====================================================================
    <<g_base_err_data1_loop>>
    FOR i IN 1..l_base_err_order_tab.COUNT LOOP
      -- ���ьv��҂̋��_�s��v�G���[�̃��b�Z�[�W�o�͑Ώۂ̏ꍇ�A���L�̏��������s����B
      IF ( l_base_err_order_tab(i).output_flag = ct_yes_flg ) THEN
        --�� ���_�����擾�B
        SELECT hp.party_name          -- ���_�R�[�h
        INTO   lt_base_name
        FROM   hz_cust_accounts hca   -- �ڋq�}�X�^
             , hz_parties       hp    -- �p�[�e�B�}�X�^
        WHERE  hca.account_number      = l_base_err_order_tab(i).sale_base_code
                                                            -- ����:�ڋq�}�X�^.�ڋq�R�[�h = ���㋒�_�R�[�h
        AND    hca.customer_class_code = cv_cust_class_base -- ����:�ڋq�}�X�^.�ڋq�敪   = '1'(���_)
        AND    hp.party_id             = hca.party_id       -- [��������]
        ;
        --�� ���юҏ������_�s��v�G���[�p�p�����[�^(���㋒�_)���擾���A�o�́B
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm
                       , iv_name        => cv_msg_err_param1_note
                       , iv_token_name1 => cv_tkn_base_code
                       , iv_token_value1=> l_base_err_order_tab(i).sale_base_code
                       , iv_token_name2 => cv_tkn_base_name
                       , iv_token_value2=> lt_base_name
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
        IF (     ( gt_regular_any_class IS NOT NULL                    )
             AND ( gt_regular_any_class = cv_regular_any_class_regular )
        ) THEN
          lv_errmsg_prefix := lv_errmsg;
        END IF;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
        --�� �o�͑Ώۂ̔��㋒�_�Ɠ���ł���s�����f�[�^���o�́B
        <<g_base_err_data2_loop>>
        FOR j IN i..l_base_err_order_tab.COUNT LOOP
          -- �\���Ώۂ̔��㋒�_�ƈ�v�����ꍇ�A���b�Z�[�W���o�́B
          IF (   l_base_err_order_tab(j).sale_base_code = l_base_err_order_tab(i).sale_base_code
             AND l_base_err_order_tab(j).output_flag    = ct_yes_flg
             ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_nm
                           , iv_name        => cv_msg_err_param2_note
                           , iv_token_name1 => cv_tkn_invoice_num
                           , iv_token_value1=> l_base_err_order_tab(j).dlv_invoice_number
                           , iv_token_name2 => cv_tkn_customer_code
                           , iv_token_value2=> l_base_err_order_tab(j).ship_to_customer_code
                           , iv_token_name3 => cv_tkn_result_emp_code
                           , iv_token_value3=> l_base_err_order_tab(j).results_employee_code
                           , iv_token_name4 => cv_tkn_result_base_code
                           , iv_token_value4=> l_base_err_order_tab(j).results_employee_base_code
                         );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
            set_gen_err_list(
                ov_errbuf       => lv_errbuf
              , ov_retcode      => lv_retcode
              , ov_errmsg       => lv_errmsg
              , it_base_code    => l_base_err_order_tab( j ).delivery_base_code
              , it_message_name => cv_msg_base_mismatch_err
              , it_message_text => SUBSTRB( lv_errmsg_prefix || CHR( 10 ) || lv_errmsg, 1, 2000 )
            );
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
            -- �o�͍ς̃��R�[�h�̃t���O��N�ɖ߂��B
            l_base_err_order_tab(j).output_flag := ct_no_flg;
          END IF;
        END LOOP g_base_err_data2_loop;
      END IF;
    END LOOP g_base_err_data1_loop;
--
  -- ��̏����ł́A���g�p�̂��߁A�̈�J��
  l_base_err_order_tab.DELETE;
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
  END check_results_employee;
-- 2009/09/30 Ver.1.11 M.Sano Add End
--
  /**********************************************************************************
   * Procedure Name   : set_plsql_table
   * Description      : �̔�����PL/SQL�\�쐬(A-6)
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
    cv_break_ok            CONSTANT NUMBER := 1;
    cv_break_ng            CONSTANT NUMBER := 0;
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
--****************************** 2009/06/08 1.7 T.Kitajima ADD START ******************************--
    ln_tax_amount_sum       NUMBER;           --  ����Ōv�Z���[�N�ϐ�
--****************************** 2009/06/08 1.7 T.Kitajima ADD  END  ******************************--

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
    j := 0;                      -- �̔����уw�b�_�̓Y����
    k := 0;                      -- �̔����і��ׂ̓Y����
    ln_tax_amount := 0;          -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
--
    IF g_order_data_sort_tab.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_order_data_sort_tab.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      IF ( ln_first_index = ln_now_index ) THEN
        lv_break := cv_break_ok;
      ELSIF ( g_order_data_sort_tab(ln_now_index).header_id    != g_order_data_sort_tab(ln_bfr_index).header_id
           OR g_order_data_sort_tab(ln_now_index).dlv_date     != g_order_data_sort_tab(ln_bfr_index).dlv_date
           OR g_order_data_sort_tab(ln_now_index).inspect_date != g_order_data_sort_tab(ln_bfr_index).inspect_date
           OR g_order_data_sort_tab(ln_now_index).dlv_invoice_number
                != g_order_data_sort_tab(ln_bfr_index).dlv_invoice_number) THEN
--
        -- �O�łƓ���(�`�[�ې�)�͖{�̋��z���v�������ŋ��z���v���Z�o����
        IF ( g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
          OR g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
--****************************** 2009/06/08 1.7 T.Kitajima MOD START ******************************--
--          -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
--          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
--/* 2009/05/18 Ver1.5 Add Start */
--          --�؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
--          IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
----
--            -- �����_�ȉ������݂���ꍇ
--            IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
----
--              g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
----
--            END IF;
----
--          --�؎̂�
--          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
----
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
----
--          --�l�̌ܓ�
--          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
----
--            g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
----
--          END IF;
--/* 2009/05/18 Ver1.5 Add End */
--
          -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
          ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
          --�؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
          IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
--
            -- �����_�ȉ������݂���ꍇ
            IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
--
              g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
--****************************** 2009/06/10 1.8 T.Kitajima ADD START ******************************--
            ELSE
              g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
--****************************** 2009/06/10 1.8 T.Kitajima ADD  END  ******************************--
--
            END IF;
--
          --�؎̂�
          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
--
          --�l�̌ܓ�
          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--
            g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
--
          END IF;

--****************************** 2009/06/08 1.7 T.Kitajima MOD  END  ******************************--
        ELSE
          -- ����ŋ��z���v �� ������z���v �| �{�̋��z���v
          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
        END IF;
/* 2009/05/18 Ver1.5 Del Start */
        -- ����ŋ��z���v���l�̌ܓ��i�[���Ȃ��j
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);        
/* 2009/05/18 Ver1.5 Del End   */
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
        g_sale_hdr_tab(j).dlv_invoice_number          := g_order_data_sort_tab(ln_now_index).dlv_invoice_number;
        -- �����`�[�ԍ�
        g_sale_hdr_tab(j).order_invoice_number        := g_order_data_sort_tab(ln_now_index).order_invoice_number;
        -- �󒍔ԍ�
        g_sale_hdr_tab(j).order_number                := g_order_data_sort_tab(ln_now_index).order_number;
        -- ��No�iHHT)
        g_sale_hdr_tab(j).order_no_hht                := g_order_data_sort_tab(ln_now_index).order_no_hht;
        -- ��No�iHHT�j�}��
        g_sale_hdr_tab(j).digestion_ln_number         := g_order_data_sort_tab(ln_now_index).order_no_hht_seq;
        -- �󒍊֘A�ԍ�
        g_sale_hdr_tab(j).order_connection_number     := g_order_data_sort_tab(ln_now_index).order_connection_number;
        -- �[�i�`�[�敪
        g_sale_hdr_tab(j).dlv_invoice_class           := g_order_data_sort_tab(ln_now_index).dlv_invoice_class;
        -- ����E�����敪
        g_sale_hdr_tab(j).cancel_correct_class        := g_order_data_sort_tab(ln_now_index).cancel_correct_class;
        -- ���͋敪
        g_sale_hdr_tab(j).input_class                 := g_order_data_sort_tab(ln_now_index).input_class;
        -- �Ƒԏ�����
        g_sale_hdr_tab(j).cust_gyotai_sho             := g_order_data_sort_tab(ln_now_index).cust_gyotai_sho;
        -- �[�i��
        g_sale_hdr_tab(j).delivery_date               := g_order_data_sort_tab(ln_now_index).dlv_date;
        -- �I���W�i���[�i��
        g_sale_hdr_tab(j).orig_delivery_date          := g_order_data_sort_tab(ln_now_index).org_dlv_date;
        -- ������
        g_sale_hdr_tab(j).inspect_date                := g_order_data_sort_tab(ln_now_index).inspect_date;
        -- �I���W�i��������
        g_sale_hdr_tab(j).orig_inspect_date           := g_order_data_sort_tab(ln_now_index).orig_inspect_date;
        -- �ڋq�y�[�i��z
        g_sale_hdr_tab(j).ship_to_customer_code       := g_order_data_sort_tab(ln_now_index).ship_to_customer_code;
        -- ����ŋ敪
        g_sale_hdr_tab(j).consumption_tax_class       := g_order_data_sort_tab(ln_now_index).consumption_tax_class;
        -- �ŋ��R�[�h
        g_sale_hdr_tab(j).tax_code                    := g_order_data_sort_tab(ln_now_index).tax_code;
        -- ����ŗ�
        g_sale_hdr_tab(j).tax_rate                    := g_order_data_sort_tab(ln_now_index).tax_rate;
        -- ���ьv��҃R�[�h
        g_sale_hdr_tab(j).results_employee_code       := g_order_data_sort_tab(ln_now_index).results_employee_code;
        -- ���㋒�_�R�[�h
        g_sale_hdr_tab(j).sales_base_code             := g_order_data_sort_tab(ln_now_index).sale_base_code;
        -- �������_�R�[�h
        g_sale_hdr_tab(j).receiv_base_code            := g_order_data_sort_tab(ln_now_index).receiv_base_code;
        -- �󒍃\�[�XID
        g_sale_hdr_tab(j).order_source_id             := g_order_data_sort_tab(ln_now_index).order_source_id;
        -- �J�[�h����敪
        g_sale_hdr_tab(j).card_sale_class             := g_order_data_sort_tab(ln_now_index).card_sale_class;
        -- �`�[�敪
        g_sale_hdr_tab(j).invoice_class               := g_order_data_sort_tab(ln_now_index).invoice_class;
        -- �`�[���ރR�[�h
        g_sale_hdr_tab(j).invoice_classification_code := g_order_data_sort_tab(ln_now_index).big_classification_code;
        -- ��K�؂ꎞ�ԂP�O�O�~
        g_sale_hdr_tab(j).change_out_time_100         := g_order_data_sort_tab(ln_now_index).change_out_time_100;
        -- ��K�؂ꎞ�ԂP�O�~
        g_sale_hdr_tab(j).change_out_time_10          := g_order_data_sort_tab(ln_now_index).change_out_time_10;
        -- AR�C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).ar_interface_flag           := g_order_data_sort_tab(ln_now_index).ar_interface_flag;
        -- GL�C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).gl_interface_flag           := g_order_data_sort_tab(ln_now_index).gl_interface_flag;
        -- ���V�X�e���C���^�t�F�[�X�σt���O
        g_sale_hdr_tab(j).dwh_interface_flag          := g_order_data_sort_tab(ln_now_index).dwh_interface_flag;
        -- EDI���M�ς݃t���O
        g_sale_hdr_tab(j).edi_interface_flag          := g_order_data_sort_tab(ln_now_index).edi_interface_flag;
        -- EDI���M����
        g_sale_hdr_tab(j).edi_send_date               := g_order_data_sort_tab(ln_now_index).edi_send_date;
        -- HHT�[�i���͓���
        g_sale_hdr_tab(j).hht_dlv_input_date          := g_order_data_sort_tab(ln_now_index).hht_dlv_input_date;
        -- �[�i�҃R�[�h
        g_sale_hdr_tab(j).dlv_by_code                 := g_order_data_sort_tab(ln_now_index).dlv_by_code;
        -- �쐬���敪
        g_sale_hdr_tab(j).create_class                := g_order_data_sort_tab(ln_now_index).create_class;
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
        ln_max_amount := g_order_data_sort_tab(ln_now_index).pure_amount;
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
      g_sale_line_tab(k).dlv_invoice_number          := g_order_data_sort_tab(ln_now_index).dlv_invoice_number;
      -- �[�i���הԍ�
      g_sale_line_tab(k).dlv_invoice_line_number     := g_order_data_sort_tab(ln_now_index).dlv_invoice_line_number;
      -- �������הԍ�
      g_sale_line_tab(k).order_invoice_line_number   := g_order_data_sort_tab(ln_now_index).order_invoice_line_number;
      -- ����敪
      g_sale_line_tab(k).sales_class                 := g_order_data_sort_tab(ln_now_index).sales_class;
      -- �[�i�`�ԋ敪
      g_sale_line_tab(k).delivery_pattern_class      := g_order_data_sort_tab(ln_now_index).delivery_pattern_class;
      -- �ԍ��t���O
      g_sale_line_tab(k).red_black_flag              := g_order_data_sort_tab(ln_now_index).red_black_flag;
      -- �i�ڃR�[�h
      g_sale_line_tab(k).item_code                   := g_order_data_sort_tab(ln_now_index).item_code;
      -- �󒍐���
      g_sale_line_tab(k).dlv_qty                     := g_order_data_sort_tab(ln_now_index).ordered_quantity;
      -- �����
      g_sale_line_tab(k).standard_qty                := g_order_data_sort_tab(ln_now_index).base_quantity;
      -- �󒍒P��
      g_sale_line_tab(k).dlv_uom_code                := g_order_data_sort_tab(ln_now_index).order_quantity_uom;
      -- ��P��
      g_sale_line_tab(k).standard_uom_code           := g_order_data_sort_tab(ln_now_index).base_uom;
      -- �̔��P��
      g_sale_line_tab(k).dlv_unit_price              := g_order_data_sort_tab(ln_now_index).unit_selling_price;
      -- �Ŕ���P��
      g_sale_line_tab(k).standard_unit_price_excluded:= g_order_data_sort_tab(ln_now_index).standard_unit_price;
      -- ��P��
      g_sale_line_tab(k).standard_unit_price         := g_order_data_sort_tab(ln_now_index).base_unit_price;
      -- �c�ƌ���
      g_sale_line_tab(k).business_cost               := g_order_data_sort_tab(ln_now_index).business_cost;
      -- ������z
      g_sale_line_tab(k).sale_amount                 := g_order_data_sort_tab(ln_now_index).sale_amount;
      -- �{�̋��z
      g_sale_line_tab(k).pure_amount                 := g_order_data_sort_tab(ln_now_index).pure_amount;
      -- ����ŋ��z
      g_sale_line_tab(k).tax_amount                  := g_order_data_sort_tab(ln_now_index).tax_amount;
      -- �����E�J�[�h���p�z
      g_sale_line_tab(k).cash_and_card               := g_order_data_sort_tab(ln_now_index).cash_and_card;
      -- �o�׌��ۊǏꏊ
      g_sale_line_tab(k).ship_from_subinventory_code := g_order_data_sort_tab(ln_now_index).ship_from_subinventory_code;
      -- �[�i���_�R�[�h
      g_sale_line_tab(k).delivery_base_code          := g_order_data_sort_tab(ln_now_index).delivery_base_code;
      -- �g���b
      g_sale_line_tab(k).hot_cold_class              := g_order_data_sort_tab(ln_now_index).hot_cold_class;
      -- �R����No
      g_sale_line_tab(k).column_no                   := g_order_data_sort_tab(ln_now_index).column_no;
      -- ���؋敪
      g_sale_line_tab(k).sold_out_class              := g_order_data_sort_tab(ln_now_index).sold_out_class;
      -- ���؎���
      g_sale_line_tab(k).sold_out_time               := g_order_data_sort_tab(ln_now_index).sold_out_time;
      -- �萔���v�Z�C���^�t�F�[�X�σt���O
      g_sale_line_tab(k).to_calculate_fees_flag      := g_order_data_sort_tab(ln_now_index).to_calculate_fees_flag;
      -- �P���}�X�^�쐬�σt���O
      g_sale_line_tab(k).unit_price_mst_flag         := g_order_data_sort_tab(ln_now_index).unit_price_mst_flag;
      -- INV�C���^�t�F�[�X�σt���O
      g_sale_line_tab(k).inv_interface_flag          := g_order_data_sort_tab(ln_now_index).inv_interface_flag;
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
                                            + g_order_data_sort_tab(ln_now_index).sale_amount;-- ������z���v
      -- �{�̋��z
      g_sale_hdr_tab(j).pure_amount_sum   := g_sale_hdr_tab(j).pure_amount_sum
                                            + g_order_data_sort_tab(ln_now_index).pure_amount;-- �{�̋��z���v
      -- ���ׂ̏���ŋ��z�̐ςݏグ���v���z
      ln_tax_amount := ln_tax_amount + g_order_data_sort_tab(ln_now_index).tax_amount;
      -- ����ŋ��z
      g_sale_hdr_tab(j).tax_amount_sum    := g_sale_hdr_tab(j).tax_amount_sum
                                            + g_order_data_sort_tab(ln_now_index).tax_amount;-- ����ŋ��z���v
--
--
      -- ���ݏ������̔̔����і��ׂ̖{�̋��z���A�w�b�_�P�ʂ̖��ד������z��������
--Modify 2009.05.18 Ver1.5 Start
--      IF ( g_sale_line_tab(k).pure_amount > ln_max_amount ) THEN
      IF ( ABS(g_sale_line_tab(k).pure_amount) > ABS(ln_max_amount )) THEN
--Modify 2009.05.18 Ver1.5 End
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
      ln_now_index := g_order_data_sort_tab.next(ln_now_index);
--
    END LOOP;
--
    -- �O�łƓ���(�`�[�ې�)�͖{�̋��z���v�������ŋ��z���v���Z�o����
    IF ( g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
      OR g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
--****************************** 2009/06/08 1.7 T.Kitajima MOD START ******************************--
--      -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
--      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
--/* 2009/05/18 Ver1.5 Add Start */
--      --�؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
--      IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
--        -- �����_�ȉ������݂���ꍇ
--        IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
--          g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
--        END IF;
--      --�؎̂�
--      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
--      --�l�̌ܓ�
--      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
--      END IF;
--/* 2009/05/18 Ver1.5 Add End */
--
      -- ����ŋ��z���v �� �{�̋��z���v �~ �ŗ�
      ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
      --�؏�(���z�̓}�C�i�X�Ȃ̂�-1�Ő؏�Ƃ���)
      IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
        -- �����_�ȉ������݂���ꍇ
        IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
          g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
--****************************** 2009/06/10 1.8 T.Kitajima ADD START ******************************--
        ELSE
          g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
--****************************** 2009/06/10 1.8 T.Kitajima ADD  END  ******************************--
        END IF;
      --�؎̂�
      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
      --�l�̌ܓ�
      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
        g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
      END IF;
--****************************** 2009/06/08 1.7 T.Kitajima MOD  END  ******************************--
    ELSE
      -- ����ŋ��z���v �� ������z���v �| �{�̋��z���v
      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
    END IF;
/* 2009/05/18 Ver1.5 Del Start */
    -- ����ŋ��z���v���l�̌ܓ��i�[���Ȃ��j
--    g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);  
/* 2009/05/18 Ver1.5 Del End   */
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
   * Description      : �̔����і��׍쐬(A-7)
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
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_line_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_errmsg,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Description      : �̔����уw�b�_�쐬(A-8)
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
        RAISE global_insert_data_expt;
    END;
--
    --��������
    gn_normal_header_cnt := g_sale_hdr_tab.COUNT;
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_header_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_errmsg,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
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
  END make_sales_exp_headers;
--
  /**********************************************************************************
   * Procedure Name   : set_order_line_close_status
   * Description      : �󒍖��׃N���[�Y�ݒ�(A-9)
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
    ln_now_index  VARCHAR2(100);
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
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--    ln_now_index := g_order_data_sort_tab.first;
    ln_now_index := g_order_cls_data_tab.first;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      BEGIN
--
        WF_ENGINE.COMPLETEACTIVITY(
            Itemtype => cv_close_type
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--          , Itemkey  => g_order_data_sort_tab(ln_now_index).line_id  -- �󒍖���ID
          , Itemkey  => g_order_cls_data_tab(ln_now_index).line_id  -- �󒍖���ID
-- 2009/07/08 Ver.1.9 M.Sano Mod End
          , Activity => cv_activity
          , Result   => cv_result
        );
--
        -- ���̃C���f�b�N�X���擾����
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--        ln_now_index := g_order_data_sort_tab.next(ln_now_index);
        ln_now_index := g_order_cls_data_tab.next(ln_now_index);
        gn_normal_close_cnt := gn_normal_close_cnt + 1;
-- 2009/07/08 Ver.1.9 M.Sano Mod End
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_api_err_expt;
      END;
--
    END LOOP;
--
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
                   iv_token_value2=> SQLERRM,
                   iv_token_name3 => cv_tkn_line_number,
-- 2009/07/08 Ver.1.9 M.Sano Mod Start
--                   iv_token_value3=> g_order_data_sort_tab(ln_now_index).line_id
                   iv_token_value3=> g_order_cls_data_tab(ln_now_index).line_id
-- 2009/07/08 Ver.1.9 M.Sano Mod End
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
--****************************** 2009/10/20 1.12 K.Satomura Add START  ******************************--
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_create_flag
   * Description      : �̔����э쐬�σt���O�X�V(A-9-1)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_create_flag(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sales_exp_create_flag'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_now_index VARCHAR2(100);
    lv_tkn1      VARCHAR2(1000);
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_now_index := g_order_cls_data_tab.FIRST;
    --
    <<loop_line_update>>
    WHILE ln_now_index IS NOT NULL LOOP
      BEGIN
        UPDATE oe_order_lines_all ool
        SET    ool.global_attribute5 = ct_yes_flg -- �̔����јA�g�σt���O
        WHERE  ool.line_id = g_order_cls_data_tab(ln_now_index).line_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_tkn1   := xxccp_common_pkg.get_msg(
                          cv_xxcos_appl_short_nm
                         ,cv_order_line_all_name
                       );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_xxcos_appl_short_nm
                         ,cv_msg_update_err
                         ,cv_tkn_table_name
                         ,lv_tkn1
                         ,cv_key_data
                         ,g_order_cls_data_tab(ln_now_index).line_id
                       );
          --
          RAISE global_api_err_expt;
          --
      END;
      --
      ln_now_index := g_order_cls_data_tab.NEXT(ln_now_index);
      --
    END LOOP loop_line_update;
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
  END upd_sales_exp_create_flag;
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
  /**********************************************************************************
   * Procedure Name   : make_gen_err_list
   * Description      : �ėp�G���[���X�g�쐬(A-10)
   ***********************************************************************************/
  PROCEDURE make_gen_err_list(
      ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'make_gen_err_list'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  #####################
    lv_errbuf   VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
--#####################  �Œ胍�[�J���ϐ��錾�� END    #####################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--#####################  �Œ�X�e�[�^�X�������� START  #####################
    ov_retcode  := cv_status_normal;
--#####################  �Œ�X�e�[�^�X�������� END    #####################
--
    IF (     ( gt_regular_any_class IS NOT NULL                    )
         AND ( gt_regular_any_class = cv_regular_any_class_regular )
    ) THEN
      BEGIN
        FORALL i IN 1..g_gen_err_list_tab.COUNT
        INSERT INTO xxcos_gen_err_list VALUES g_gen_err_list_tab( i );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SUBSTRB( SQLERRM, 1, 5000 );
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_nm
                         , iv_name          => cv_gen_err_list
                       );
          ov_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                    iv_application   => cv_xxcos_appl_short_nm
                                  , iv_name          => ct_msg_insert_data_err
                                  , iv_token_name1   => cv_tkn_table_name
                                  , iv_token_value1  => lv_errmsg
                                  , iv_token_name2   => cv_tkn_key_data
                                  , iv_token_value2  => lv_errbuf
                                )
                              , 1
                              , 5000
                       );
          RAISE global_insert_data_expt;
      END;
    END IF;
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START  #################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END    #################################
  END make_gen_err_list;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
--
--****************************** 2009/10/20 1.12 K.Satomura Add END  ******************************--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date  IN      VARCHAR2,     -- �������t
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    iv_regular_any_class  IN  VARCHAR2,   -- ��������敪
    iv_dlv_base_code      IN  VARCHAR2,   -- �[�i���_�R�[�h
    iv_edi_chain_code     IN  VARCHAR2,   -- EDI�`�F�[���X�R�[�h
    iv_cust_code          IN  VARCHAR2,   -- �ڋq�R�[�h
    iv_dlv_date_from      IN  VARCHAR2,   -- �[�i��FROM
    iv_dlv_date_to        IN  VARCHAR2,   -- �[�i��TO
    iv_user_name          IN  VARCHAR2,   -- �쐬��
    iv_order_number       IN  VARCHAR2,   -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
    lv_idx_key                VARCHAR(100); -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
-- 2009/07/08 Ver.1.9 M.Sano Add Start
    ln_cls_data_seq           NUMBER;       -- �󒍃N���[�Y�Ώۂ̎󒍖��׈ꗗ�̌���
-- 2009/07/08 Ver.1.9 M.Sano Add End
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
-- 2009/07/08 Ver.1.9 M.Sano Add Start
    gn_normal_close_cnt  := 0;
-- 2009/07/08 Ver.1.9 M.Sano Add End
--
    ln_err_flag := cn_check_status_normal;
--
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
      iv_target_date          =>  iv_target_date,             -- �������t
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
      iv_regular_any_class    =>  iv_regular_any_class,       -- ��������敪
      iv_dlv_base_code        =>  iv_dlv_base_code,           -- �[�i���_�R�[�h
      iv_edi_chain_code       =>  iv_edi_chain_code,          -- EDI�`�F�[���X�R�[�h
      iv_cust_code            =>  iv_cust_code,               -- �ڋq�R�[�h
      iv_dlv_date_from        =>  iv_dlv_date_from,           -- �[�i��FROM
      iv_dlv_date_to          =>  iv_dlv_date_to,             -- �[�i��TO
      iv_user_name            =>  iv_user_name,               -- �쐬��
      iv_order_number         =>  iv_order_number,            -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�v���t�@�C���l�擾
    -- ===============================
    set_profile(
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.�󒍃f�[�^�擾
    -- ===============================
    get_order_data(
      ov_errbuf               =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              =>  lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               =>  lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_no_data_warm_expt;
    END IF;
--
    ln_err_flag := cn_check_status_normal;
--
    <<loop_make_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
--
      --�̔����уw�b�_�쐬�P�ʃ`�F�b�N
      IF ((i = 1) OR (   g_order_data_tab(i).header_id    != g_order_data_tab(i-1).header_id
                      OR g_order_data_tab(i).dlv_date     != g_order_data_tab(i-1).dlv_date
                      OR g_order_data_tab(i).inspect_date != g_order_data_tab(i-1).inspect_date
                      OR g_order_data_tab(i).dlv_invoice_number != g_order_data_tab(i-1).dlv_invoice_number ) ) THEN
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
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
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
      IF (lv_retcode = cv_status_normal) THEN
        -- ===============================
        -- A-5.�f�[�^�`�F�b�N
        -- ===============================
        check_data_row(
            g_order_data_tab(i) -- �󒍃f�[�^���R�[�h
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
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
-- 2009/09/30 Ver.1.11 M.Sano Add Start
    -- ===============================
    -- A-5-1.����v��҂̏������_�`�F�b�N
    -- ===============================
    check_results_employee(
        ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/09/30 Ver.1.11 M.Sano Add End
    -- ����f�[�^�݂̂�PL/SQL�\�쐬
    <<loop_make_sort_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      IF( g_order_data_tab(i).check_status = cn_check_status_normal ) THEN
        --�̔����т��쐬����P�ʁF�󒍃w�b�_ID�E�[�i��
        lv_idx_key := g_order_data_tab(i).header_id
                      || TO_CHAR(g_order_data_tab(i).dlv_date    , ct_target_date_format)
                      || TO_CHAR(g_order_data_tab(i).inspect_date, ct_target_date_format)
                      || g_order_data_tab(i).dlv_invoice_number
                      || g_order_data_tab(i).line_id;
        g_order_data_sort_tab(lv_idx_key) := g_order_data_tab(i);
      END IF;
    END LOOP loop_make_sort_data;
--
    IF ( g_order_data_sort_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-6.�̔�����PL/SQL�\�쐬
      -- ===============================
      set_plsql_table(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-7.�̔����і��׍쐬
      -- ===============================
      make_sales_exp_lines(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-8.�̔����уw�b�_�쐬
      -- ===============================
      make_sales_exp_headers(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.�󒍃N���[�Y�ݒ�
      -- ===============================
-- 2009/07/08 Ver.1.9 M.Sano Add Start
    END IF;
    ln_cls_data_seq := 0;
--
    -- �󒍃N���[�Y�̑ΏۂƂȂ�f�[�^���擾����B
    -- (���敪���u02�v�̎󒍃f�[�^ ���`�F�b�N���������{�̎󒍃f�[�^����擾�j
    <<get_close_date_01_loop>>
    FOR i in 1..g_order_all_data_tab.COUNT LOOP
      IF ( g_order_all_data_tab(i).info_class = cv_info_class_02 ) THEN
        ln_cls_data_seq := ln_cls_data_seq + 1;
        g_order_cls_data_tab(ln_cls_data_seq).line_id := g_order_all_data_tab(i).line_id;
      END IF;
    END LOOP get_close_date_01_loop;
--
    -- (�̔����уf�[�^�쐬�ς̎󒍃f�[�^)
    lv_idx_key := g_order_data_sort_tab.first;
    <<get_close_date_02_loop>>
    WHILE lv_idx_key IS NOT NULL LOOP
      ln_cls_data_seq := ln_cls_data_seq + 1;
      g_order_cls_data_tab(ln_cls_data_seq).line_id := g_order_data_sort_tab(lv_idx_key).line_id;
      lv_idx_key      := g_order_data_sort_tab.next(lv_idx_key);
    END LOOP get_close_date_02_loop;
--
    -- �󒍖��ׂ��N���[�Y����B(������1���ȏ㑶�݂����ꍇ)
    IF ( ln_cls_data_seq > 0 ) THEN
-- 2009/07/08 Ver.1.9 M.Sano Add End
      set_order_line_close_status(
          lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/10/20 Ver.1.12 K.Satomura Add Start
      -- ===============================
      -- A-9-1.�̔����э쐬�σt���O�X�V
      -- ===============================
      upd_sales_exp_create_flag(
         lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
-- 2009/10/20 Ver.1.12 K.Satomura Add End
    END IF;
--
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
    -- ===============================
    -- A-10.�ėp�G���[���X�g�쐬
    -- ===============================
    make_gen_err_list(
        ov_errbuf   => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode  => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg   => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
    END IF;
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
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
-- 2010/08/25 Ver.1.16 S.Arizumi Mod Start --
--    iv_target_date  IN      VARCHAR2    -- �������t
    iv_target_date        IN  VARCHAR2,   -- �������t
    iv_regular_any_class  IN  VARCHAR2,   -- ��������敪
    iv_dlv_base_code      IN  VARCHAR2,   -- �[�i���_�R�[�h
    iv_edi_chain_code     IN  VARCHAR2,   -- EDI�`�F�[���X�R�[�h
    iv_cust_code          IN  VARCHAR2,   -- �ڋq�R�[�h
    iv_dlv_date_from      IN  VARCHAR2,   -- �[�i��FROM
    iv_dlv_date_to        IN  VARCHAR2,   -- �[�i��TO
    iv_user_name          IN  VARCHAR2,   -- �쐬��
    iv_order_number       IN  VARCHAR2    -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Mod End   --
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
      iv_target_date  -- �������t
-- 2010/08/25 Ver.1.16 S.Arizumi Add Start --
      ,iv_regular_any_class -- ��������敪
      ,iv_dlv_base_code     -- �[�i���_�R�[�h
      ,iv_edi_chain_code    -- EDI�`�F�[���X�R�[�h
      ,iv_cust_code         -- �ڋq�R�[�h
      ,iv_dlv_date_from     -- �[�i��FROM
      ,iv_dlv_date_to       -- �[�i��TO
      ,iv_user_name         -- �쐬��
      ,iv_order_number      -- �󒍔ԍ�
-- 2010/08/25 Ver.1.16 S.Arizumi Add End   --
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
--
      IF ( lv_retcode = cv_status_error ) THEN
        gn_normal_header_cnt := 0;
        gn_normal_line_cnt   := 0;
-- 2009/07/08 Ver.1.9 M.Sano Add Start
        gn_normal_close_cnt  := 0;
-- 2009/07/08 Ver.1.9 M.Sano Add End
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
-- 2009/07/08 Ver.1.9 M.Sano Add Start
    --���ׂ̃N���[�Y��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_cls_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_close_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/07/08 Ver.1.9 M.Sano Add End
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
--
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
--
END XXCOS007A02C;
/
