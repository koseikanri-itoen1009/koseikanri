CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A02C (body)
 * Description      : ���i�ʔ���v�Z
 * MD.050           : ���i�ʔ���v�Z MD050_COS_004_A02
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  pram_chk               �p�����[�^�`�F�b�N(A-1)
 *  get_common_data        ���ʃf�[�^�擾(A-2)
 *  get_object_data        �X�ܕʗp�����v�Z�f�[�^�擾(A-3)
 *  calc_sales             ���i�ʔ���Z����(A-4)
 *  set_lines              �̔����і��׍쐬(A-5)
 *  set_headers            �̔����уw�b�_�쐬(A-6)
 *  update_digestion       ���������ݒ�(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   T.kitajima       �V�K�쐬
 *  2009/02/05    1.1   T.miyashita      [COS_022]�P�ʊ��Z�̕s�
 *  2009/02/05    1.2   T.kitajima       [COS_023]�ԍ��t���O�ݒ�s�(�d�l�R��)
 *  2009/02/10    1.3   T.kitajima       [COS_041]�[�i�`�[�敪(1:�[�i)�ݒ�(�d�l�R��)
 *  2009/02/10    1.4   T.kitajima       [COS_047]�������ׂ̔[�i/��P��(�d�l�R��)
 *  2009/02/19    1.5   T.kitajima       �[�i�`�ԋ敪 ���C���q�ɑΉ�
 *  2009/02/24    1.6   T.kitajima       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/30    1.7   T.kitajima       [T1_0189]�̔����і���.�[�i���הԍ��̍̔ԕ��@�ύX
 *  2009/04/20    1.8   T.kitajima       [T1_0657]�f�[�^�擾0���G���[���x���I����
 *  2009/04/28    1.9   N.Maeda          [T1_0769]���ʌn�A���z�n�̎Z�o���@�̏C��
 *  2009/05/07    1.10  T.kitajima       [T1_0888]�[�i���_�擾���@�ύX
 *                                       [T1_0714]�݌ɕi�ڐ���0���O�Ή�
 *  2009/05/26    1.11  T.kitajima       [T1_1217]�P���l�̌ܓ�
 *  2009/06/09    1.12  T.kitajima       [T1_1371]�s���b�N
 *  2009/06/10    1.12  T.kitajima       [T1_1412]�[�i�`�[�ԍ��擾�����ύX
 *  2009/06/11    1.13  T.kitajima       [T1_1415]�[�i�`�[�ԍ��擾�����ύX
 *  2009/08/17    1.14  K.Kiriu          [0000430]PT�Ή�
 *  2009/09/11    1.15  M.Sano           [0001345]PT�Ή�
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
  global_common_expt          EXCEPTION; --���ʃG���[
  global_business_err_expt    EXCEPTION; --�Ɩ����t�G���[
  global_quick_err_expt       EXCEPTION; --�N�C�b�N�R�[�h�G���[
  global_base_err_expt        EXCEPTION; --���_�K�{�G���[
  global_get_profile_expt     EXCEPTION; --�v���t�@�C���擾��O
  global_no_data_expt         EXCEPTION; --�Ώۃf�[�^�O���G���[
  global_insert_expt          EXCEPTION; --�o�^
  global_up_headers_expt      EXCEPTION; --�X�ܕʗp�����v�Z�w�b�_�X�V�G���[
  global_up_inv_expt          EXCEPTION; --�I���Ǘ��e�[�u���X�V�G���[
  global_quick_salse_err_expt EXCEPTION; --����敪�擾�G���[
  global_quick_inv_err_expt   EXCEPTION; --�I���X�e�[�^�X
  global_select_err_expt      EXCEPTION; --SQL SELECT�G���[
  global_call_api_expt        EXCEPTION; --API�G���[
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  global_quick_not_inv_expt   EXCEPTION; --��݌ɕi�ڎ擾�G���[
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
  global_data_lock_expt       EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS004A02C'; -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';                   --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_pram_date          CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10951';               --�p�����[�^���b�Z�[�W
  ct_msg_class_cd_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10952';               --��������敪�`�F�b�N�G���[���b�Z�[�W
  ct_msg_base_cd_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10953';               --���_�R�[�h�K�{�G���[
  ct_msg_item_cd_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10954';               --���ٕi�ڃR�[�h�擾�G���[���b�Z�[�W
  ct_msg_making_cd_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10955';               --�쐬���敪�擾�G���[
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';               --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';               --�Ɩ����t�擾�G���[
  cv_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';               --����0���p���b�Z�[�W
  cv_msg_inser_lines_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10956';               --�̔����і��דo�^�G���[
  cv_msg_inser_headers_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10957';               --�̔����уw�b�_�o�^�G���[
  cv_msg_update_headers_err CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10958';               --�X�ܕʗp�����v�Z�w�b�_�X�V�G���[
  cv_msg_update_inv_err     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10959';               --�I���Ǘ��e�[�u���X�V�G���[
  cv_msg_salse_class_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10960';               --����敪�擾�G���[
  cv_msg_inv_status_err     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10961';               --�I���X�e�[�^�X�擾�G���[
  cv_msg_select_store_err   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10962';               --�X�ܕʗp�����v�Z�f�[�^�擾�G���[
  cv_msg_deli_err           CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10965';               --�[�i�`�Ԏ擾�G���[
  cv_msg_tan_err            CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10966';               --�P�ʊ��Z�G���[
  ct_msg_gl_id_err          CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10967';               --GL��v����ID�擾�G���[���b�Z�[�W
  ct_msg_inv_code_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10968';               --�݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  ct_msg_inv_id_err         CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10969';               --�݌ɑg�DID�擾�G���[���b�Z�[�W
  ct_msg_dvl_ptn_calss_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10971';               --���i�ʔ���v�Z�p�[�i�`�ԋ敪�擾�G���[���b�Z�[�W
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  ct_msg_delivery_base_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10973';               --�[�i���_�擾�G���[���b�Z�[�W
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
  ct_msg_shop_lock_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10974';               --�X�ܕʗp�����v�Z�e�[�u�����b�N�擾�G���[���b�Z�[�W
  ct_msg_inv_lock_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10975';               --�I���Ǘ��e�[�u�����b�N�擾�G���[���b�Z�[�W
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_regular_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_REGULAR_ANY_CLASS';       --�������
  ct_qct_making_type        CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_MK_ORG_CLS_MST_004_A02';  --�쐬���敪
  ct_qct_tax_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --HHT����ŋ敪
  ct_qct_gyo_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_GYOTAI_SHO_MST_004_A01';  --�Ƒԏ����ޓ���}�X�^_004_A01
  ct_qct_cust_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CUS_CLASS_MST_004_A02';   --�ڋq�敪����}�X�^
  ct_qct_sales_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_SALE_CLASS_MST_004_A02';  --����敪����}�X�^
  ct_qct_inv_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_INV_STATUS_MST_004_A02';  --�I���X�e�[�^�X����}�X�^
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  ct_qct_not_inv_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';        --��݌ɕi�ڃR�[�h
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
  --�N�C�b�N�R�[�h
  ct_qcc_sales_code         CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_01';               --�����v�Z�i�S�ݓX���X�j
  ct_qcc_it_code            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A01%';                 --�C���V���b�v/���В��c�X
  ct_qcc_digestion_code     CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_04';               --�����EVD����
  ct_qcc_inv_digestion_code CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_03';               --����
  ct_qcc_cust_code_1        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_10%';              --���_
  ct_qcc_cust_code_2        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_20%';              --�ڋq
  --�g�[�N��
  cv_tkn_parm_data1         CONSTANT  VARCHAR2(10) :=  'PARAM1';           --�p�����[�^1
  cv_tkn_parm_data2         CONSTANT  VARCHAR2(10) :=  'PARAM2';           --�p�����[�^2
  cv_tkn_parm_data3         CONSTANT  VARCHAR2(10) :=  'PARAM3';           --�p�����[�^3
  cv_tkn_parm_data4         CONSTANT  VARCHAR2(10) :=  'PARAM4';           --�p�����[�^4
  cv_tkn_parm_data5         CONSTANT  VARCHAR2(10) :=  'PARAM5';           --�p�����[�^5
  cv_tkn_profile            CONSTANT  VARCHAR2(10) :=  'PROFILE';          --�v���t�@�C��
  cv_tkn_quick1             CONSTANT  VARCHAR2(10) :=  'QUICK1';           --�N�C�b�N
  cv_tkn_quick2             CONSTANT  VARCHAR2(10) :=  'QUICK2';           --�N�C�b�N
  cv_tkn_table              CONSTANT  VARCHAR2(10) :=  'TABLE_NAME';       --�e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(10) :=  'KEY_DATA';         --�L�[�f�[�^
  --�v���t�@�C������
  cv_Profile_item_cd        CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DIFF_ITEM_CODE';  -- �����v�Z���ٕi�ڃR�[�h
  ct_prof_gl_set_of_bks_id  CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'GL_SET_OF_BKS_ID';                 -- GL��v����ID
  ct_prof_organization_code CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOI1_ORGANIZATION_CODE';
                                                                             -- XXCOI:�݌ɑg�D�R�[�h
  ct_prof_dlv_ptn_cls       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_PROD_SLS_CALC_DLV_PTN_CLS';
                                                                             -- XXCOS:���i�ʔ���v�Z�p�[�i�`�ԋ敪
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                              --�g�p�\
  --���_/�ڋq,��l�t���O
  ct_customer_flag_no       CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'N';                              --�ڋq,��l
  ct_customer_flag_yes      CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'Y';                              --���_
  --�X�܃w�b�_�p�t���O
  ct_make_flag_yes          CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'Y';                              --�쐬�ς�
  ct_make_flag_no           CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'N';                              --���쐬
  ct_un_calc_flag_0         CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                      := 0;                                --���v�Z�t���O
  ct_un_calc_flag_1         CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                      := 1;                                --���v�Z�t���O
  --�ԍ��t���O
  ct_red_black_flag_0       CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '0';                              --��
  ct_red_black_flag_1       CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '1';                              --��
  --�萔���v�Z�C���^�t�F�[�X�σt���O
  ct_to_calculate_fees_flag CONSTANT  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
                                      := 'N';                              --NO
  --�P���}�X�^�쐬�σt���O
  ct_unit_price_mst_flag    CONSTANT  xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
                                      := 'N';                              --NO
  --INV�C���^�t�F�[�X�σt���O
  ct_inv_interface_flag     CONSTANT  xxcos_sales_exp_lines.inv_interface_flag%TYPE
                                      := 'N';                              --NO
  --AR�C���^�t�F�[�X�σt���O
  ct_ar_interface_flag      CONSTANT  xxcos_sales_exp_headers.ar_interface_flag%TYPE
                                      := 'N';                              --NO
  --GL�C���^�t�F�[�X�σt���O
  ct_gl_interface_flag      CONSTANT  xxcos_sales_exp_headers.gl_interface_flag%TYPE
                                      := 'N';                              --NO
  --���V�X�e���C���^�t�F�[�X�σt���O
  ct_dwh_interface_flag     CONSTANT  xxcos_sales_exp_headers.dwh_interface_flag%TYPE
                                      := 'N';                              --NO
  --EDI���M�ς݃t���O
  ct_edi_interface_flag     CONSTANT  xxcos_sales_exp_headers.edi_interface_flag%TYPE
                                      := 'N';                              --NO
  --�J�[�h����敪
  ct_card_flag_cash         CONSTANT  xxcos_sales_exp_headers.card_sale_class%TYPE
                                      := '0';                              --0:����
  --AR�ŋ��}�X�^�L���t���O
  ct_tax_enabled_yes        CONSTANT  ar_vat_tax_all_b.enabled_flag%TYPE
                                      := 'Y';                              --Y:�L��
  --�[�i�`�[�敪
  ct_deliver_slip_div       CONSTANT  xxcos_sales_exp_headers.dlv_invoice_class%TYPE
                                      := '1';                              --1:�[�i
  cn_dmy                    CONSTANT  NUMBER := 0;
--******************************* 2009/04/28 1.9 N.Maeda ADD START **************************************************************
  cn_quantity_num           CONSTANT  NUMBER := 1;                         --���ʌn�Œ�l(1)
  cn_differ_business_cost   CONSTANT  NUMBER := 0;                         --���ٕi�ډc�ƌ���(0)
--******************************* 2009/04/28 1.9 N.Maeda ADD  END  **************************************************************
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  cn_sales_zero             CONSTANT  NUMBER := 0;                         --�݌�0
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--******************************* 2009/06/10 1.12 T.Kitajima ADD START ******************************--
  cv_snq_i                  CONSTANT  VARCHAR2(1) :=  'I';
--******************************* 2009/06/10 1.12 T.Kitajima ADD  END  ******************************--
/* 2009/08/17 Ver1.14 Add Start */
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
/* 2009/08/17 Ver1.14 Add End   */
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �X�ܕʗp�����v�Z�f�[�^�i�[�p�ϐ�
  TYPE g_rec_work_data IS RECORD
    (
      shop_digestion_hdr_id       xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,      --�X�ܕʗp�����v�Z�w�b�_ID
      digestion_due_date          xxcos_shop_digestion_hdrs.digestion_due_date%TYPE,         --�����v�Z���N����
      customer_number             xxcos_shop_digestion_hdrs.customer_number%TYPE,            --�ڋq�R�[�h
      sales_base_code             xxcos_shop_digestion_hdrs.sales_base_code%TYPE,            --���㋒�_�R�[�h
      cust_account_id             xxcos_shop_digestion_hdrs.cust_account_id%TYPE,            --�ڋqID
      digestion_exe_date          xxcos_shop_digestion_hdrs.digestion_exe_date%TYPE,         --�����v�Z���s��
      ar_sales_amount             xxcos_shop_digestion_hdrs.ar_sales_amount%TYPE,            --�X�ܕʔ�����z
      check_sales_amount          xxcos_shop_digestion_hdrs.check_sales_amount%TYPE,         --�`�F�b�N�p������z
      digestion_calc_rate         xxcos_shop_digestion_hdrs.digestion_calc_rate%TYPE,        --�����v�Z�|��
      master_rate                 xxcos_shop_digestion_hdrs.master_rate%TYPE,                --�}�X�^�|��
      balance_amount              xxcos_shop_digestion_hdrs.balance_amount%TYPE,             --���z
      cust_gyotai_sho             xxcos_shop_digestion_hdrs.cust_gyotai_sho%TYPE,            --�Ƒԏ�����
      performance_by_code         xxcos_shop_digestion_hdrs.performance_by_code%TYPE,        --���ю҃R�[�h
      sales_result_creation_date  xxcos_shop_digestion_hdrs.sales_result_creation_date%TYPE, --�̔����ѓo�^��
      sales_result_creation_flag  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE, --�̔����э쐬�σt���O
      pre_digestion_due_date      xxcos_shop_digestion_hdrs.pre_digestion_due_date%TYPE,     --�O������v�Z���N����
      uncalculate_class           xxcos_shop_digestion_hdrs.uncalculate_class%TYPE,          --���v�Z�敪
      shop_digestion_ln_id        xxcos_shop_digestion_lns.shop_digestion_ln_id%TYPE,        --�X�ܕʗp�����v�Z����ID
      digestion_ln_number         xxcos_shop_digestion_lns.digestion_ln_number%TYPE,         --�}��
      item_code                   xxcos_shop_digestion_lns.item_code%TYPE,                   --�i�ڃR�[�h
      invent_seq                  xxcos_shop_digestion_lns.invent_seq%TYPE,                  --�I��SEQ
      item_price                  xxcos_shop_digestion_lns.item_price%TYPE,                  --�艿
      inventory_item_id           xxcos_shop_digestion_lns.inventory_item_id%TYPE,           --�i��ID
      business_cost               xxcos_shop_digestion_lns.business_cost%TYPE,               --�c�ƌ���
      standard_cost               xxcos_shop_digestion_lns.standard_cost%TYPE,               --�W������
      item_sales_amount           xxcos_shop_digestion_lns.item_sales_amount%TYPE,           --�X�ܕi�ڕʔ̔����z
      uom_code                    xxcos_shop_digestion_lns.uom_code%TYPE,                    --�P�ʃR�[�h
      sales_quantity              xxcos_shop_digestion_lns.sales_quantity%TYPE,              --�̔���
      delivery_base_code          xxcos_shop_digestion_lns.delivery_base_code%TYPE,          --�[�i���_�R�[�h
      ship_from_subinventory_code xxcos_shop_digestion_lns.ship_from_subinventory_code%TYPE, --�o�׌��ۊǏꏊ
      past_sale_base_code         xxcmm_cust_accounts.past_sale_base_code%TYPE,              --�O�����㋒�_�R�[�h
      tax_div                     xxcmm_cust_accounts.tax_div%TYPE,                          --����ŋ敪
      tax_rounding_rule           hz_cust_site_uses_all.tax_rounding_rule%TYPE,              --�ŋ��|�[������
      tax_code                    ar_vat_tax_all_b.tax_code%TYPE,                            --AR�ŃR�[�h
      tax_rate                    ar_vat_tax_all_b.tax_rate%TYPE,                            --����ŗ�
      cash_receiv_base_code       xxcfr_cust_hierarchy_v.cash_receiv_base_code%TYPE            --�������_�R�[�h
  );
  --�X�V�p
  TYPE g_tab_shop_digestion_hdr_id IS TABLE OF xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE
    INDEX BY PLS_INTEGER;   -- �X�ܕʗp�����v�Z�w�b�_ID
  TYPE g_tab_invent_seq            IS TABLE OF xxcos_shop_digestion_lns.invent_seq%TYPE
    INDEX BY PLS_INTEGER;   -- �I��SEQ
  --�e�[�u����`
  TYPE g_tab_work_data             IS TABLE OF g_rec_work_data INDEX BY PLS_INTEGER;                     --�X�ܕʗp�����v�Z�f�[�^�i�[�p�ϐ�
  TYPE g_tab_sales_exp_headers     IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY PLS_INTEGER;     --�̔����уw�b�_
  TYPE g_tab_sales_exp_lines       IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY PLS_INTEGER;       --�̔����і���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_business_date                DATE;                                  --�Ɩ����t
  gd_last_month_date              DATE;                                  --�挎�����t
  gn_list_cnt                     NUMBER;                                --�Ώی���
  gn_gl_id                        NUMBER;                                --��v����ID
  gv_item_code                    VARCHAR2(10);                          --�����v�Z���ٕi�ڃR�[�h
  gv_dvl_ptn_class                VARCHAR2(10);                          --:���i�ʔ���v�Z�p�[�i�`�ԋ敪
  gv_item_unit                    VARCHAR2(10);                          --�����v�Z���ٕi�ڒP��
  gv_making_code                  VARCHAR2(1);                           --�쐬���敪
  gv_sales_class_vd               VARCHAR2(1);                           --�����EVD����
  gv_inv_status                   VARCHAR2(1);                           --�I���X�e�[�^�X(����)
  gt_tab_work_data                g_tab_work_data;                       --�Ώۃf�[�^�擾�p
  gt_tab_sales_exp_headers        g_tab_sales_exp_headers;               --�̔����уw�b�_
  gt_tab_sales_exp_lines          g_tab_sales_exp_lines;                 --�̔����і���
  gt_tab_sales_exp_lines_ins      g_tab_sales_exp_lines;                 --�̔����і���
  gt_tab_shop_digestion_hdr_id    g_tab_shop_digestion_hdr_id;           --�X�ܕʗp�����v�Z�w�b�_ID
  gt_tab_invent_seq               g_tab_invent_seq;                      --�I��SEQ
  gt_tab_invent_seq_up            g_tab_invent_seq;                      --�I��SEQ
  gt_organization_code            mtl_parameters.organization_code%TYPE; --�݌ɑg�D�R�[�h
  gt_organization_id              mtl_parameters.organization_id%TYPE;   --�݌ɑg�DID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_exec_div        IN         VARCHAR2,     -- 1.��������敪
    iv_base_code       IN         VARCHAR2,     -- 2.���_�R�[�h
    iv_customer_number IN         VARCHAR2,     -- 3.�ڋq�R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    --���͍��ڕ\��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data1
                    ,iv_token_value1 => iv_exec_div
                    ,iv_token_name2  => cv_tkn_parm_data2
                    ,iv_token_value2 => iv_base_code
                    ,iv_token_name3  => cv_tkn_parm_data3
                    ,iv_token_value3 => iv_customer_number
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
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
      ,buff   => NULL
    );
--
  EXCEPTION
--#####################################  �Œ蕔 START ##########################################
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
   * Procedure Name   : pram_chk
   * Description      : �p���[���[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE pram_chk(
    iv_exec_div   IN            VARCHAR2,     -- 1.��������敪
    iv_base_code  IN            VARCHAR2,     -- 2.���_�R�[�h
    ov_errbuf     OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pram_chk'; -- �v���O������
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
    ln_cnt     NUMBER;          --�J�E���^�[
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --1.�Ɩ����t�擾
    --==============================================================
    gd_business_date          := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_business_date IS NULL ) THEN
      RAISE global_business_err_expt;
    END IF;
--
    --==============================================================
    --2.���t�擾
    --==============================================================
--
    --�O���I���N�����擾
    gd_last_month_date := LAST_DAY(ADD_MONTHS( gd_business_date ,-1 ));
--
    --==============================================================
    --3.��������敪�̃`�F�b�N�����܂��B
    --==============================================================
    SELECT COUNT(flv.meaning)
    INTO   ln_cnt
/* 2009/08/17 Ver1.14 Mod Start */
--    FROM   fnd_application               fa,
--           fnd_lookup_types              flt,
--           fnd_lookup_values             flv
--    WHERE  fa.application_id                               = flt.application_id
--    AND    flt.lookup_type                                 = flv.lookup_type
--    AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--    AND    flv.lookup_type                                 = ct_qct_regular_type
--    AND    flv.lookup_code                                 = iv_exec_div
--    AND    flv.start_date_active                          <= gd_last_month_date
--    AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--    AND    flv.enabled_flag                                = ct_enabled_flag_yes
--    AND    flv.language                                    = USERENV( 'LANG' )
--    AND    ROWNUM                                          = 1
    FROM   fnd_lookup_values  flv
    WHERE  flv.lookup_type      = ct_qct_regular_type
    AND    flv.lookup_code      = iv_exec_div
    AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                AND     NVL( flv.end_date_active, gd_last_month_date )
    AND    flv.enabled_flag     = ct_enabled_flag_yes
    AND    flv.language         = ct_lang
    AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
    ;
--
    IF ( ln_cnt = 0 ) THEN
      RAISE global_quick_err_expt;
    END IF;
    --==============================================================
    --3.�������s�̏ꍇ�A���_�R�[�h�̃`�F�b�N�����܂��B
    --==============================================================
    IF ( iv_exec_div = 0 ) THEN
      IF ( iv_base_code IS NULL ) THEN
        RAISE global_base_err_expt;
      END IF;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_business_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�擾��O�n���h�� ***
    WHEN global_quick_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_class_cd_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���_�R�[�h�K�{��O�n���h�� ***
    WHEN global_base_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_base_cd_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ###################################
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
  END pram_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : ���ʃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- �v���O������
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
--
    lv_key_info VARCHAR2(5000);  --key���
    lv_gl_id    VARCHAR2(100);   --GLID
    lv_pro_id   VARCHAR2(100);   --�v���t�@�C��ID
    lv_err_code VARCHAR2(100);   --�G���[ID
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================
    -- 1.�uXXCOS1_DIGESTION_DIFF_ITEM_CODE: �����v�Z���ٕi�ڃR�[�h�v���擾���܂��B
    --==============================================
    gv_item_code := FND_PROFILE.VALUE(cv_Profile_item_cd);
    --�f�B���N�g���擾
    IF ( gv_item_code IS NULL ) THEN
      lv_err_code := ct_msg_item_cd_err;
      lv_pro_id   := cv_Profile_item_cd;
      RAISE global_get_profile_expt;
    END IF;
    --==============================================
    -- 2.�N�C�b�N�R�[�h�u�쐬���敪(�����v�Z�i�S�ݓX���X�j)�v���擾���܂��B
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_making_code
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_making_type
--      AND    flv.lookup_code                                 = ct_qcc_sales_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_making_type
      AND    flv.lookup_code      = ct_qcc_sales_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_err_expt;
    END;
    --==============================================
    -- 3.�N�C�b�N�R�[�h�u����敪(4�F�����EVD����)�v���擾���܂��B
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_sales_class_vd
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_sales_type
--      AND    flv.lookup_code                                 = ct_qcc_digestion_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_sales_type
      AND    flv.lookup_code      = ct_qcc_digestion_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_salse_err_expt;
    END;
    --==============================================
    -- 4.�N�C�b�N�R�[�h�u�I���X�e�[�^�X(3�F����)�v���擾���܂��B
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_inv_status
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_inv_type
--      AND    flv.lookup_code                                 = ct_qcc_inv_digestion_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_inv_type
      AND    flv.lookup_code      = ct_qcc_inv_digestion_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_inv_err_expt;
    END;
--
    --============================================
    -- 5. ��v����ID
    --============================================
    lv_gl_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL��v����ID
    IF ( lv_gl_id IS NULL ) THEN
      lv_err_code := ct_msg_gl_id_err;
      lv_pro_id   := ct_prof_gl_set_of_bks_id;
      RAISE global_get_profile_expt;
    ELSE
      gn_gl_id := TO_NUMBER(lv_gl_id);
    END IF;
--
    --============================================
    -- 6.XXCOI:�݌ɑg�D�R�[�h
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_organization_code IS NULL ) THEN
      lv_err_code := ct_msg_inv_code_err;
      lv_pro_id   := ct_prof_organization_code;
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 7. �݌ɑg�DID�̎擾
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      RAISE global_call_api_expt;
    END IF;

    --============================================
    -- 8. �����i�ڂ̊�P�ʎ擾
    --============================================
    BEGIN
      SELECT msi.primary_unit_of_measure 
      INTO   gv_item_unit
      FROM   mtl_system_items_b msi
      WHERE  msi.segment1 = gv_item_code
      AND    msi.organization_id = gt_organization_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code := ct_msg_item_cd_err;
        lv_pro_id   := cv_Profile_item_cd;
        RAISE global_get_profile_expt;
    END;
    --==============================================
    -- 9.�uXXCOS1_PROD_SLS_CALC_DLV_PTN_CLS:���i�ʔ���v�Z�p�[�i�`�ԋ敪�v���擾���܂��B
    --==============================================
    gv_dvl_ptn_class := FND_PROFILE.VALUE(ct_prof_dlv_ptn_cls);
    --�f�B���N�g���擾
    IF ( gv_dvl_ptn_class IS NULL ) THEN
      lv_err_code := ct_msg_dvl_ptn_calss_err;
      lv_pro_id   := ct_prof_dlv_ptn_cls;
      RAISE global_get_profile_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �v���t�@�C���擾�G���[��O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => lv_err_code,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_pro_id
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�擾�G���[��O�n���h�� ***
    WHEN global_quick_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_making_cd_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_making_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_sales_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�擾�G���[��O�n���h�� ***
    WHEN global_quick_salse_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_salse_class_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_sales_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�擾�G���[��O�n���h�� ***
    WHEN global_quick_inv_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_inv_status_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_inv_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_inv_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �݌ɑg�DID�擾�G���[��O�n���h�� ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_inv_id_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : get_object_data
   * Description      : �X�ܕʗp�����v�Z�f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_data(
    iv_base_code       IN         VARCHAR2,     -- ���_�R�[�h
    iv_customer_number IN         VARCHAR2,     -- �ڋq�R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_data'; -- �v���O������
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
    CURSOR get_data_cur
    IS
/* 2009/08/17 Ver1.14 Mod Start */
--      SELECT xsdh.shop_digestion_hdr_id         shop_digestion_hdr_id,            --�X�ܕʗp�����v�Z�w�b�_ID
/* 2009/09/11 Ver1.15 Mod Start */
--        SELECT /*+
--                 LEADING(xsdh)
--                 INDEX(xsdh xxcos_shop_digestion_hdrs_n04 )
--                 INDEX(xxca xxcmm_cust_accounts_pk)
--                 USE_NL(xchv.cust_hier.cash_hcar_3)
--                 USE_NL(xchv.cust_hier.bill_hasa_3)
--                 USE_NL(xchv.cust_hier.bill_hasa_4)
--                 USE_NL(flv xxca)
--               */
        SELECT /*+
                 LEADING(xsdh)
                 INDEX(xsdh xxcos_shop_digestion_hdrs_n04 )
                 INDEX(xxca xxcmm_cust_accounts_pk)
                 INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
                 INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
                 INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
                 INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
                 USE_NL(xchv.cust_hier.cash_hcar_3)
                 USE_NL(xchv.cust_hier.bill_hasa_3)
                 USE_NL(xchv.cust_hier.bill_hasa_4)
                 USE_NL(flv xxca)
               */
/* 2009/09/11 Ver1.15 Mod Start */
             xsdh.shop_digestion_hdr_id         shop_digestion_hdr_id,            --�X�ܕʗp�����v�Z�w�b�_ID
/* 2009/08/17 Ver1.14 Mod End   */
             xsdh.digestion_due_date            digestion_due_date,               --�����v�Z���N����
             xsdh.customer_number               customer_number,                  --�ڋq�R�[�h
             xsdh.sales_base_code               sales_base_code,                  --���㋒�_�R�[�h
             xsdh.cust_account_id               cust_account_id,                  --�ڋqID
             xsdh.digestion_exe_date            digestion_exe_date,               --�����v�Z���s��
             xsdh.ar_sales_amount               ar_sales_amount,                  --�X�ܕʔ�����z
             xsdh.check_sales_amount            check_sales_amount,               --�`�F�b�N�p������z
             xsdh.digestion_calc_rate           digestion_calc_rate,              --�����v�Z�|��
             xsdh.master_rate                   master_rate,                      --�}�X�^�|��
             xsdh.balance_amount                balance_amount,                   --���z
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --�Ƒԏ�����
             xsdh.performance_by_code           performance_by_code,              --���ю҃R�[�h
             xsdh.sales_result_creation_date    sales_result_creation_date,       --�̔����ѓo�^��
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --�̔����э쐬�σt���O
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --�O������v�Z���N����
             xsdh.uncalculate_class             uncalculate_class,                --���v�Z�敪
             xsdl.shop_digestion_ln_id          shop_digestion_ln_id,             --�X�ܕʗp�����v�Z����ID
             xsdl.digestion_ln_number           digestion_ln_number,              --�}��
             xsdl.item_code                     item_code,                        --�i�ڃR�[�h
             xsdl.invent_seq                    invent_seq,                       --�I��SEQ
             xsdl.item_price                    item_price,                       --�艿
             xsdl.inventory_item_id             inventory_item_id,                --�i��ID
             xsdl.business_cost                 business_cost,                    --�c�ƌ���
             xsdl.standard_cost                 standard_cost,                    --�W������
             xsdl.item_sales_amount             item_sales_amount,                --�X�ܕi�ڕʔ̔����z
             xsdl.uom_code                      uom_code,                         --�P�ʃR�[�h
             xsdl.sales_quantity                sales_quantity,                   --�̔���
             xsdl.delivery_base_code            delivery_base_code,               --�[�i���_�R�[�h
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --�o�׌��ۊǏꏊ
             xxca.past_sale_base_code           past_sale_base_code,              --�O�����㋒�_�R�[�h
             xxca.tax_div                       tax_div,                          --����ŋ敪
             hnas.tax_rounding_rule             tax_rounding_rule,                --�ŋ��|�[������
             avta.tax_code                      tax_code,                         --AR�ŃR�[�h
             avta.tax_rate                      tax_rate,                         --����ŗ�
             xchv.cash_receiv_base_code         cash_receiv_base_code               --�������_�R�[�h
      FROM   xxcos_shop_digestion_hdrs xsdh,    -- �X�ܕʗp�����v�Z�w�b�_�e�[�u��
             xxcos_shop_digestion_lns  xsdl,    -- �X�ܕʗp�����v�Z���׃e�[�u��
             hz_cust_accounts          hnas,    -- �ڋq�}�X�^
             xxcmm_cust_accounts       xxca,    -- �ڋq�A�h�I���}�X�^
/* 2009/08/17 Ver1.14 Mod Start */
--             xxcfr_cust_hierarchy_v    xchv,    -- �ڋq�K�wVIEW
             xxcos_cust_hierarchy_v    xchv,    -- �ڋq�K�wVIEW
/* 2009/08/17 Ver1.14 Mod End   */
             ar_vat_tax_all_b          avta,    -- AR�ŋ��}�X�^
/* 2009/08/17 Ver1.14 Mod Start */
--             (SELECT flv.attribute3  tax_class,
--                     flv.attribute2  tax_code
--              FROM   fnd_application               fa,
--                     fnd_lookup_types              flt,
--                     fnd_lookup_values             flv
--              WHERE  fa.application_id                               = flt.application_id
--              AND    flt.lookup_type                                 = flv.lookup_type
--              AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--              AND    flv.lookup_type                                 = ct_qct_tax_type
--              AND    flv.start_date_active                          <= gd_last_month_date
--              AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--              AND    flv.enabled_flag                                = ct_enabled_flag_yes
--              AND    flv.language                                    = USERENV( 'LANG' )
--             ) tcm,
             fnd_lookup_values         flv,
/* 2009/08/17 Ver1.14 Mod End   */
             (
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id --�ڋq�}�X�^.�ڋqID   = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning                                     =    hca.customer_class_code
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    EXISTS (SELECT hcae.account_number --���_�R�[�h
                               FROM   hz_cust_accounts    hcae,
/* 2009/08/17 Ver1.14 Mod Start */
--                                      xxcmm_cust_accounts xcae
                                      xxcmm_cust_accounts xcae,
                                      fnd_lookup_values   flv
/* 2009/08/17 Ver1.14 Mod End   */
                               WHERE  hcae.cust_account_id = xcae.customer_id--�ڋq�}�X�^.�ڋqID =�ڋq�A�h�I��.�ڋqID
/* 2009/08/17 Ver1.14 Mod Start */
--                               AND    EXISTS (SELECT flv.meaning
--                                              FROM   fnd_application               fa,
--                                                     fnd_lookup_types              flt,
--                                                     fnd_lookup_values             flv
--                                              WHERE  fa.application_id                               =    flt.application_id
--                                              AND    flt.lookup_type                                 =    flv.lookup_type
--                                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_1
--                                              AND    flv.start_date_active                          <=    gd_last_month_date
--                                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                                              AND    flv.language                                    =    USERENV( 'LANG' )
--                                              AND    flv.meaning                                     =    hcae.customer_class_code
--                                             ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
--                               AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                               --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
                               AND    flv.lookup_type      = ct_qct_cust_type
                               AND    flv.lookup_code      LIKE ct_qcc_cust_code_1
                               AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                           AND     NVL( flv.end_date_active, gd_last_month_date )
                               AND    flv.enabled_flag     = ct_enabled_flag_yes
                               AND    flv.language         = ct_lang
                               AND    flv.meaning          = hcae.customer_class_code
                               AND    (
                                        ( iv_base_code IS NULL )
                                        OR
                                        ( iv_base_code IS NOT NULL AND  xcae.management_base_code = iv_base_code )
                                      ) --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
/* 2009/08/17 Ver1.14 Mod End   */
                               AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                              ) --�Ǘ����_�ɏ������鋒�_�R�[�h=�ڋq�A�h�I��.�O�����_or���㋒�_
/* 2009/08/17 Ver1.14 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
/* 2009/08/17 Ver1.14 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_gyo_type
                             AND    flv.lookup_code      LIKE ct_qcc_it_code
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                            )  --�Ƒԏ�����=�C���V���b�v,���В��c�X
              UNION
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id --�ڋq�}�X�^.�ڋqID   = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning                                     =    hca.customer_class_code
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     )--�ڋq�A�h�I��.�O�����_or���㋒�_ = IN�p�����_�R�[�h
/* 2009/08/17 Ver1.14 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
/* 2009/08/17 Ver1.14 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_gyo_type
                             AND    flv.lookup_code      LIKE ct_qcc_it_code
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                            )  --�Ƒԏ�����=�C���V���b�v,���В��c�X
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --�w�b�_.�ڋq�R�[�h           = �擾�����ڋq�R�[�h
      AND    xsdh.shop_digestion_hdr_id                = xsdl.shop_digestion_hdr_id --�w�b�_.�w�b�_ID             = ����.�w�b�_ID
      AND    xsdh.sales_result_creation_flag           = ct_make_flag_no            --�w�b�_.�̔����э쐬�σt���O = �eN�f
      AND    xsdh.uncalculate_class                    = ct_un_calc_flag_0          --�w�b�_.���v�Z�敪           = 0
      AND    xsdh.cust_account_id                      = hnas.cust_account_id       --�w�b�_.�ڋqID               = �ڋq�}�X�^.�ڋqID
      AND    hnas.cust_account_id                      = xxca.customer_id           --�ڋq�}�X�^.�ڋqID           = �A�h�I��.�ڋqID
/* 2009/08/17 Ver1.14 Mod Start */
--      AND    xxca.tax_div                              = tcm.tax_class              --�ڋq�}�X�^. ����ŋ敪      = �ŃR�[�h����}�X�^.LOCKUP�R�[�h
--      AND    tcm.tax_code                              = avta.tax_code              --�ŃR�[�h����}�X�^.DFF2     = AR�ŋ��}�X�^.�ŃR�[�h
      AND    flv.lookup_type                           = ct_qct_tax_type
      AND    gd_last_month_date                        BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                       AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag                          = ct_enabled_flag_yes
      AND    flv.language                              = ct_lang
      AND    flv.attribute3                            = xxca.tax_div               --�ŃR�[�h����}�X�^.DFF3     = �ڋq�}�X�^. ����ŋ敪
      AND    flv.attribute2                            = avta.tax_code              --�ŃR�[�h����}�X�^.DFF2     = AR�ŋ��}�X�^.�ŃR�[�h
/* 2009/08/17 Ver1.14 Mod End   */
      AND    avta.set_of_books_id                      = gn_gl_id                   --AR�ŋ��}�X�^.�Z�b�g�u�b�N�X = GL��v����ID
      AND    avta.enabled_flag                         = ct_tax_enabled_yes         --AR�ŋ��}�X�^.�L��           = 'Y'
      AND    avta.start_date                          <=    gd_last_month_date      --AR�ŋ��}�X�^.�L������      <= �����v�Z����
      AND    NVL( avta.end_date, gd_last_month_date ) >=    gd_last_month_date      --AR�ŋ��}�X�^.�L������      >= �����v�Z����
      AND    xsdh.cust_account_id                      = xchv.ship_account_id       --�w�b�_.�ڋqID               = �ڋq�K�wVIEW.�o�א�ڋqID
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity                      != cn_sales_zero
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
/* 2009/08/17 Ver1.14 Mod Start */
--                        FROM   fnd_application               fa,
--                               fnd_lookup_types              flt,
--                               fnd_lookup_values             flv
--                        WHERE  fa.application_id                               = flt.application_id
--                        AND    flt.lookup_type                                 = flv.lookup_type
--                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
--                        AND    flv.start_date_active                          <= gd_last_month_date
--                        AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                        AND    flv.language                                    = USERENV( 'LANG' )
--                        AND    flv.lookup_code                                 = xsdl.item_code
                        FROM   fnd_lookup_values             flv
                        WHERE  flv.lookup_type      = ct_qct_not_inv_type
                        AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                    AND     NVL( flv.end_date_active, gd_last_month_date )
                        AND    flv.enabled_flag     = ct_enabled_flag_yes
                        AND    flv.language         = ct_lang
                        AND    flv.lookup_code      = xsdl.item_code
/* 2009/08/17 Ver1.14 Mod End   */
                      )
      ORDER BY xsdh.shop_digestion_hdr_id,xsdl.shop_digestion_ln_id
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      FOR UPDATE OF xsdh.shop_digestion_hdr_id,xsdl.invent_seq NOWAIT
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
    ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --�Ώۃf�[�^�擾�p�J�[�\��OPEN
    BEGIN
      OPEN get_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_data_cur BULK COLLECT INTO gt_tab_work_data;
      --�擾����
      gn_list_cnt := get_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_data_cur;
    EXCEPTION
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      WHEN global_data_lock_expt THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_data_cur%ISOPEN ) THEN
          CLOSE get_data_cur;
        END IF;
        RAISE global_data_lock_expt;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_data_cur%ISOPEN ) THEN
          CLOSE get_data_cur;
        END IF;
        --
        RAISE global_select_err_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --���o�Ώۂ�0���������ꍇ
    IF ( gn_list_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�O���G���[ ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--****************************** 2009/04/20 1.8 T.kitajima MOD START ******************************--
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--****************************** 2009/04/20 1.8 T.kitajima MOD  END  ******************************--
--
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_select_store_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
--
    -- *** ���b�N �G���[ ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_shop_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
--#####################################  �Œ蕔 START ##########################################
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
  END get_object_data;
--
  /**********************************************************************************
   * Procedure Name   : calc_sales
   * Description      : ���i�ʔ���Z����(A-4)
   ***********************************************************************************/
  PROCEDURE calc_sales(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_sales'; -- �v���O������
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
    ln_i                   NUMBER;        --�J�E���^�[
    ln_m                   NUMBER;        --���׃J�E���^�[
    ln_h                   NUMBER;        --�w�b�_�J�E���^�[
    ln_index               NUMBER;        --INDEX�ꎞ�ۊ�
    lv_err_work            VARCHAR2(1);   --�G���[���[�N
    lv_organization_code   VARCHAR2(10);  --�݌ɑg�D�R�[�h
    lv_organization_id     NUMBER;        --�݌ɑg�D�h�c
    lv_delivered_from      VARCHAR2(1);   --�[�i�`��
    ln_inventory_item_id   NUMBER;        --�i�ڂh�c
    lv_after_uom_code      VARCHAR2(10);  --���Z��P�ʃR�[�h
    ln_after_quantity      NUMBER;        --���Z�㐔��
    ln_content             NUMBER;        --�i����
    ln_main_body_total     NUMBER;        --�{�̋��z���v
    ln_business_cost_total NUMBER;        --�c�ƌ������v
    ln_header_id           NUMBER;        --�w�b�_ID
    ln_line_id             NUMBER;        --����ID
    ln_difference_money    NUMBER;        --���ً��z
    lv_deli_seq            VARCHAR2(12);  --�[�i�`�[�ԍ�
    ln_make_flg            NUMBER;        --�w�b�_�쐬�t���O
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
    ln_line_index          NUMBER;        --�̔����і��׃e�[�u���̔[�i���הԍ�
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
    lt_delivery_base_code  xxcos_sales_exp_lines.delivery_base_code%TYPE;
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --������
    ln_m                   := 1;
    ln_h                   := 1;
    ln_main_body_total     := 0;
    ln_business_cost_total := 0;
    ln_difference_money    := 0;
    lv_err_work            := cv_status_normal;
    ln_index               := 1;
    ln_make_flg            := 0;
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
    ln_line_index          := 1;
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
    --�w�b�_�V�[�P���X�擾
    SELECT xxcos_sales_exp_headers_s01.nextval
    INTO   ln_header_id
    FROM   DUAL;
    --�[�i�`�[�ԍ��V�[�P���X�擾
--******************************* 2009/06/10 1.12 T.Kitajima MOD START ******************************--
--    lv_deli_seq := xxcos_def_pkg.set_order_number(NULL,NULL);
    SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
      INTO lv_deli_seq
      FROM dual;
--******************************* 2009/06/10 1.12 T.Kitajima MOD  END  ******************************--
    -- ���[�v�J�n
    FOR ln_i IN 1..gn_list_cnt LOOP
--
      --���펞�P�ʊ��Z���s���B
      IF ( lv_err_work = cv_status_normal ) THEN
          lv_after_uom_code := NULL; --�K��NULL��ݒ肵�Ă������ƁB
          --�P�ʊ��Z���ݒ�
          xxcos_common_pkg.get_uom_cnv(
                                       gt_tab_work_data(ln_i).uom_code,
                                       gt_tab_work_data(ln_i).sales_quantity,
                                       gt_tab_work_data(ln_i).item_code,
                                       lv_organization_code,
                                       ln_inventory_item_id,
                                       lv_organization_id,
                                       lv_after_uom_code,
                                       ln_after_quantity,
                                       ln_content,
                                       lv_errbuf,
                                       lv_retcode,
                                       lv_errmsg
                                      );
          IF ( lv_retcode = cv_status_error ) THEN
            --�擾�G���[
            lv_err_work   := cv_status_warn;
            ov_errmsg     := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => cv_msg_tan_err,
                                         iv_token_name1        => cv_tkn_parm_data1,
                                         iv_token_value1       => gt_tab_work_data(ln_i).shop_digestion_hdr_id,
                                         iv_token_name2        => cv_tkn_parm_data2,
                                         iv_token_value2       => gt_tab_work_data(ln_i).shop_digestion_ln_id,
                                         iv_token_name3        => cv_tkn_parm_data3,
                                         iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
                                         iv_token_name4        => cv_tkn_parm_data4,
                                         iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
                                         iv_token_name5        => cv_tkn_parm_data5,
                                         iv_token_value5       => gt_tab_work_data(ln_i).item_code
                                       );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ov_errmsg
            );
          END IF;
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
          --�[�i���_�R�[�h�擾
          BEGIN
            lt_delivery_base_code := NULL;
            --
            SELECT msi.attribute7
              INTO lt_delivery_base_code
              FROM mtl_secondary_inventories msi
             --�ۊǏꏊ�}�X�^.�o�׌��ۊǏꏊ�R�[�h = �o�׌��ۊǏꏊ�R�[�h
             WHERE msi.secondary_inventory_name    = gt_tab_work_data(ln_i).ship_from_subinventory_code
               --�ۊǏꏊ�}�X�^.�g�DID             = �݌ɑg�DID
               AND msi.organization_id             = gt_organization_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              --�擾�G���[
              lv_err_work   := cv_status_warn;
              ov_errmsg     := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_delivery_base_err,
                                 iv_token_name1        => cv_tkn_parm_data1,
                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                 iv_token_name2        => cv_tkn_parm_data2,
                                 iv_token_value2       => gt_tab_work_data(ln_i).ship_from_subinventory_code
                               );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT,
                buff   => ov_errmsg
              );
          END;
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
      END IF;
      --
      --���펞�̂�.�P�ʊ��Z�ɂăG���[�ɂȂ����ꍇ�́A�ݒ菈���X���[
      IF ( lv_err_work = cv_status_normal ) THEN
        --1.�[�i�ԍ��̔�(�ۗ�)
        --��������
        --2.���׃f�[�^�ݒ�
        --���׃V�[�P���X�擾
        SELECT xxcos_sales_exp_lines_s01.nextval
        INTO   ln_line_id
        FROM   DUAL;
        --
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                         --�̔����і���ID
        gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                       --�̔����уw�b�_ID
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                        --�[�i�`�[�ԍ�
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).shop_digestion_ln_id;        --�[�i���הԍ�
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                      --�[�i���הԍ�
        ln_line_index                                             := ln_line_index + 1; 
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
        gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                               --�������הԍ�
        gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                  --����敪
        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_dvl_ptn_class;                                   --�[�i�`�ԋ敪
        gt_tab_sales_exp_lines(ln_m).item_code                    := gt_tab_work_data(ln_i).item_code;                   --�i�ڃR�[�h
        gt_tab_sales_exp_lines(ln_m).dlv_qty                      := gt_tab_work_data(ln_i).sales_quantity;              --�[�i����
        gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_after_quantity;                                  --�����
        gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gt_tab_work_data(ln_i).uom_code;                    --�[�i�P��
        gt_tab_sales_exp_lines(ln_m).standard_uom_code            := gt_tab_work_data(ln_i).uom_code;                    --��P��
--******************************* 2009/04/28 1.9 N.Maeda MOD START **************************************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := gt_tab_work_data(ln_i).item_price;                  --�[�i�P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := gt_tab_work_data(ln_i).item_price;                  --�Ŕ���P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).item_price;                  --��P��
        gt_tab_sales_exp_lines(ln_m).business_cost                := gt_tab_work_data(ln_i).business_cost;               --�c�ƌ���
        gt_tab_sales_exp_lines(ln_m).sale_amount                  := ROUND(gt_tab_work_data(ln_i).item_sales_amount *
                                                                           (gt_tab_work_data(ln_i).digestion_calc_rate / 100),0);
                                                                                                                         --������z
        gt_tab_sales_exp_lines(ln_m).pure_amount                  := gt_tab_sales_exp_lines(ln_m).sale_amount;           --�{�̋��z
--******************************* 2009/05/26 1.11 T.Kitajima MOD START *******************************--
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --�[�i�P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).pure_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --�Ŕ���P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).standard_qty ) , 2 ); --��P��
        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --�[�i�P��
        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).pure_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --�Ŕ���P��
        gt_tab_sales_exp_lines(ln_m).standard_unit_price          :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).standard_qty ) , 2 ); --��P��
--******************************* 2009/05/26 1.11 T.Kitajima MOD  END *******************************--
--******************************* 2009/04/28 1.9 N.Maeda MOD  END  **************************************************************
        --�ԍ��t���O�擾
        IF ( gt_tab_sales_exp_lines(ln_m).sale_amount < 0 ) THEN
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                                --��
        ELSE
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                                --��
        END IF;
        gt_tab_sales_exp_lines(ln_m).tax_amount                   := 0;                                                  --����ŋ��z
        gt_tab_sales_exp_lines(ln_m).cash_and_card                := 0;                                                  --����/�J�[�h���p�z
        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := gt_tab_work_data(ln_i).ship_from_subinventory_code; --�o�׌��ۊǏꏊ
--******************************* 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_work_data(ln_i).delivery_base_code;          --�[�i���_�R�[�h
        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := lt_delivery_base_code;                              --�[�i���_�R�[�h
--******************************* 2009/05/07 1.10 T.Kitajima MOD  END  ******************************--
        gt_tab_sales_exp_lines(ln_m).hot_cold_class               := NULL;                                               --�g���b
        gt_tab_sales_exp_lines(ln_m).column_no                    := NULL;                                               --�R����No
        gt_tab_sales_exp_lines(ln_m).sold_out_class               := NULL;                                               --���؋敪
        gt_tab_sales_exp_lines(ln_m).sold_out_time                := NULL;                                               --���؎���
        gt_tab_sales_exp_lines(ln_m).to_calculate_fees_flag       := ct_to_calculate_fees_flag;                          --�萔���v�Z�C���^�t�F�[�X�σt���O
        gt_tab_sales_exp_lines(ln_m).unit_price_mst_flag          := ct_unit_price_mst_flag;                             --�P���}�X�^�쐬�σt���O
        gt_tab_sales_exp_lines(ln_m).inv_interface_flag           := ct_inv_interface_flag;                              --INV�C���^�t�F�[�X�σt���O
        gt_tab_sales_exp_lines(ln_m).created_by                   := cn_created_by;                                      --�쐬��
        gt_tab_sales_exp_lines(ln_m).creation_date                := cd_creation_date;                                   --�쐬��
        gt_tab_sales_exp_lines(ln_m).last_updated_by              := cn_last_updated_by;                                 --�ŏI�X�V��
        gt_tab_sales_exp_lines(ln_m).last_update_date             := cd_last_update_date;                                --�ŏI�X�V��
        gt_tab_sales_exp_lines(ln_m).last_update_login            := cn_last_update_login;                               --�ŏI�X�V۸޲�
        gt_tab_sales_exp_lines(ln_m).request_id                   := cn_request_id;                                      --�v��ID
        gt_tab_sales_exp_lines(ln_m).program_application_id       := cn_program_application_id;                          --�ݶ��ĥ��۸��ѥ���ع����ID
        gt_tab_sales_exp_lines(ln_m).program_id                   := cn_program_id;                                      --�ݶ��ĥ��۸���ID
        gt_tab_sales_exp_lines(ln_m).program_update_date          := cd_program_update_date;                             --��۸��эX�V��
        --�I���e�[�u���X�V�p
        gt_tab_invent_seq(ln_m)                                   := gt_tab_work_data(ln_i).invent_seq;                  --�I��SEQ
        --3.����v�Z
        --�{�̋��z���v
        ln_main_body_total     := ln_main_body_total     + gt_tab_sales_exp_lines(ln_m).pure_amount;
        --�c�ƌ������v
        ln_business_cost_total := ln_business_cost_total + gt_tab_sales_exp_lines(ln_m).business_cost;
        --�擾�J�E���g���ő�𒴂�����
        IF ( gt_tab_work_data.COUNT < ln_i + 1 ) THEN
          ln_make_flg := 1;
        ELSE
          IF ( gt_tab_work_data(ln_i).shop_digestion_hdr_id != gt_tab_work_data(ln_i + 1).shop_digestion_hdr_id ) THEN
            ln_make_flg := 1;
          END IF;
        END IF;
        --�w�b�_ID���Ⴄ�ꍇ�̓w�b�_�f�[�^�ݒ�A�����v�Z�A�������ׂ��쐬����B
        IF ( ln_make_flg = 1 ) THEN
          ln_make_flg := 0;
          --4.�w�b�_�f�[�^�ݒ�
          gt_tab_sales_exp_headers(ln_h).sales_exp_header_id         := ln_header_id;                                    --�̔����уw�b�_ID
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_number          := lv_deli_seq;                                     --�[�i�`�[�ԍ�
          gt_tab_sales_exp_headers(ln_h).order_invoice_number        := NULL;                                            --�����`�[�ԍ�
          gt_tab_sales_exp_headers(ln_h).order_number                := NULL;                                            --�󒍔ԍ�
          gt_tab_sales_exp_headers(ln_h).order_no_hht                := NULL;                                            --��No�iHHT)
          gt_tab_sales_exp_headers(ln_h).digestion_ln_number         := NULL;                                            --��No�iHHT�j�}��
          gt_tab_sales_exp_headers(ln_h).order_connection_number     := NULL;                                            --�󒍊֘A�ԍ�
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_class           := ct_deliver_slip_div;                             --�[�i�`�[�敪
          gt_tab_sales_exp_headers(ln_h).cancel_correct_class        := NULL;                                            --����E�����敪
          gt_tab_sales_exp_headers(ln_h).input_class                 := NULL;                                            --���͋敪
          gt_tab_sales_exp_headers(ln_h).cust_gyotai_sho             := gt_tab_work_data(ln_i).cust_gyotai_sho;          --�Ƒԏ�����
          gt_tab_sales_exp_headers(ln_h).delivery_date               := gt_tab_work_data(ln_i).digestion_due_date;       --�[�i��
          gt_tab_sales_exp_headers(ln_h).orig_delivery_date          := gt_tab_work_data(ln_i).digestion_due_date;       --�I���W�i���[�i��
          gt_tab_sales_exp_headers(ln_h).inspect_date                := gt_tab_work_data(ln_i).digestion_due_date;       --������
          gt_tab_sales_exp_headers(ln_h).orig_inspect_date           := gt_tab_work_data(ln_i).digestion_due_date;       --�I���W�i��������
          gt_tab_sales_exp_headers(ln_h).ship_to_customer_code       := gt_tab_work_data(ln_i).customer_number;          --�ڋq�y�[�i��z
          gt_tab_sales_exp_headers(ln_h).sale_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --������z���v
          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --�{�̋��z���v
          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := 0;                                               --����ŋ��z���v
          gt_tab_sales_exp_headers(ln_h).consumption_tax_class       := gt_tab_work_data(ln_i).tax_div;                  --����ŋ敪
          gt_tab_sales_exp_headers(ln_h).tax_code                    := gt_tab_work_data(ln_i).tax_code;                 --�ŋ��R�[�h
          gt_tab_sales_exp_headers(ln_h).tax_rate                    := gt_tab_work_data(ln_i).tax_rate;                 --����ŗ�
          gt_tab_sales_exp_headers(ln_h).results_employee_code       := gt_tab_work_data(ln_i).performance_by_code;      --���ьv��҃R�[�h
          gt_tab_sales_exp_headers(ln_h).sales_base_code             := gt_tab_work_data(ln_i).sales_base_code;          --���㋒�_�R�[�h
          gt_tab_sales_exp_headers(ln_h).receiv_base_code            := gt_tab_work_data(ln_i).cash_receiv_base_code;    --�������_�R�[�h
          gt_tab_sales_exp_headers(ln_h).order_source_id             := NULL;                                            --�󒍃\�[�XID
          gt_tab_sales_exp_headers(ln_h).card_sale_class             := ct_card_flag_cash;                               --�J�[�h����敪
          gt_tab_sales_exp_headers(ln_h).invoice_class               := NULL;                                            --�`�[�敪
          gt_tab_sales_exp_headers(ln_h).invoice_classification_code := NULL;                                            --�`�[���ރR�[�h
          gt_tab_sales_exp_headers(ln_h).change_out_time_100         := NULL;                                            --��K�؂ꎞ�ԂP�O�O�~
          gt_tab_sales_exp_headers(ln_h).change_out_time_10          := NULL;                                            --��K�؂ꎞ�ԂP�O�~
          gt_tab_sales_exp_headers(ln_h).ar_interface_flag           := ct_ar_interface_flag;                            --AR�C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).gl_interface_flag           := ct_gl_interface_flag;                            --GL�C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).dwh_interface_flag          := ct_dwh_interface_flag;                           --���V�X�e���C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).edi_interface_flag          := ct_edi_interface_flag;                           --EDI���M�ς݃t���O
          gt_tab_sales_exp_headers(ln_h).edi_send_date               := NULL;                                            --EDI���M����
          gt_tab_sales_exp_headers(ln_h).hht_dlv_input_date          := NULL;                                            --HHT�[�i���͓���
          gt_tab_sales_exp_headers(ln_h).dlv_by_code                 := NULL;                                            --�[�i�҃R�[�h
          gt_tab_sales_exp_headers(ln_h).create_class                := gv_making_code;                                  --�쐬���敪
          gt_tab_sales_exp_headers(ln_h).business_date               := gd_business_date;                                --�o�^�Ɩ����t
          gt_tab_sales_exp_headers(ln_h).created_by                  := cn_created_by;                                   --�쐬��
          gt_tab_sales_exp_headers(ln_h).creation_date               := cd_creation_date;                                --�쐬��
          gt_tab_sales_exp_headers(ln_h).last_updated_by             := cn_last_updated_by;                              --�ŏI�X�V��
          gt_tab_sales_exp_headers(ln_h).last_update_date            := cd_last_update_date;                             --�ŏI�X�V��
          gt_tab_sales_exp_headers(ln_h).last_update_login           := cn_last_update_login;                            --�ŏI�X�V۸޲�
          gt_tab_sales_exp_headers(ln_h).request_id                  := cn_request_id;                                   --�v��ID
          gt_tab_sales_exp_headers(ln_h).program_application_id      := cn_program_application_id;                       --�ݶ��ĥ��۸��ѥ���ع����ID
          gt_tab_sales_exp_headers(ln_h).program_id                  := cn_program_id;                                   --�ݶ��ĥ��۸���ID
          gt_tab_sales_exp_headers(ln_h).program_update_date         := cd_program_update_date;                          --��۸��эX�V��
          --�X�܃e�[�u���X�V�p
          gt_tab_shop_digestion_hdr_id(ln_h)                         := gt_tab_work_data(ln_i).shop_digestion_hdr_id;    --�X�ܕʗp�����v�Z�w�b�_ID
          --5.�����v�Z
          ln_difference_money := gt_tab_work_data(ln_i).ar_sales_amount - ln_main_body_total;
          IF ( ln_difference_money = 0 ) THEN
            NULL; --���قȂ�
          ELSE
            --���׃V�[�P���X�擾
            SELECT xxcos_sales_exp_lines_s01.nextval
            INTO   ln_line_id
            FROM   DUAL;
            --���׃J�E���gUP
            ln_m := ln_m + 1;
            gt_tab_invent_seq(ln_m)                                   := cn_dmy;                                           --�_�~�[�Z�b�g
            --
            gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                       --�̔����і���ID
            gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                     --�̔����уw�b�_ID
            gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                      --�[�i�`�[�ԍ�
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
--            gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).shop_digestion_ln_id + 1;
            gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                    --�[�i���הԍ�
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
            gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                             --�������הԍ�
            gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                --����敪
            gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_dvl_ptn_class;                                 --�[�i�`�ԋ敪
            --�ԍ��t���O�擾
            IF ( ln_difference_money < 0 ) THEN
              gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                              --��
            ELSE
              gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                              --��
            END IF;
            gt_tab_sales_exp_lines(ln_m).item_code                    := gv_item_code;                                     --�i�ڃR�[�h
--******************************* 2009/04/28 1.9 N.Maeda MOD START **************************************************************
--            gt_tab_sales_exp_lines(ln_m).dlv_qty                      := 0;                                                --�[�i����
--            gt_tab_sales_exp_lines(ln_m).standard_qty                 := 0;                                                --�����
            gt_tab_sales_exp_lines(ln_m).dlv_qty                      := ln_difference_money;                              --�[�i����
            gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_difference_money;                              --�����
            gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gv_item_unit;                                     --�[�i�P��
            gt_tab_sales_exp_lines(ln_m).standard_uom_code            := gv_item_unit;                                     --��P��
--            gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := ln_difference_money;                              --�[�i�P��
--            gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := ln_difference_money;                              --�Ŕ���P��
            gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := cn_quantity_num;                                  --�[�i�P��
            gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := cn_quantity_num;                                  --�Ŕ���P��
--            gt_tab_sales_exp_lines(ln_m).standard_unit_price          := ln_difference_money;                              --��P��
--            gt_tab_sales_exp_lines(ln_m).business_cost                := ln_difference_money ;                             --�c�ƌ���
            gt_tab_sales_exp_lines(ln_m).standard_unit_price          := cn_quantity_num;                                  --��P��
            gt_tab_sales_exp_lines(ln_m).business_cost                := cn_differ_business_cost;                          --�c�ƌ���
            gt_tab_sales_exp_lines(ln_m).sale_amount                  := ln_difference_money;                              --������z
            gt_tab_sales_exp_lines(ln_m).pure_amount                  := ln_difference_money;                              --�{�̋��z
--******************************* 2009/04/28 1.9 N.Maeda MOD  END  **************************************************************
            gt_tab_sales_exp_lines(ln_m).tax_amount                   := 0;                                                --����ŋ��z
            gt_tab_sales_exp_lines(ln_m).cash_and_card                := 0;                                                --����/�J�[�h���p�z
            gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := NULL;                                             --�o�׌��ۊǏꏊ
            gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_sales_exp_lines(ln_m-1).delivery_base_code;--�[�i���_�R�[�h
            gt_tab_sales_exp_lines(ln_m).hot_cold_class               := NULL;                                             --�g���b
            gt_tab_sales_exp_lines(ln_m).column_no                    := NULL;                                             --�R����No
            gt_tab_sales_exp_lines(ln_m).sold_out_class               := NULL;                                             --���؋敪
            gt_tab_sales_exp_lines(ln_m).sold_out_time                := NULL;                                             --���؎���
            gt_tab_sales_exp_lines(ln_m).to_calculate_fees_flag       := ct_to_calculate_fees_flag;                        --�萔���v�Z�C���^�t�F�[�X�σt���O
            gt_tab_sales_exp_lines(ln_m).unit_price_mst_flag          := ct_unit_price_mst_flag;                           --�P���}�X�^�쐬�σt���O
            gt_tab_sales_exp_lines(ln_m).inv_interface_flag           := ct_inv_interface_flag;                            --INV�C���^�t�F�[�X�σt���O
            gt_tab_sales_exp_lines(ln_m).created_by                   := cn_created_by;                                    --�쐬��
            gt_tab_sales_exp_lines(ln_m).creation_date                := cd_creation_date;                                 --�쐬��
            gt_tab_sales_exp_lines(ln_m).last_updated_by              := cn_last_updated_by;                               --�ŏI�X�V��
            gt_tab_sales_exp_lines(ln_m).last_update_date             := cd_last_update_date;                              --�ŏI�X�V��
            gt_tab_sales_exp_lines(ln_m).last_update_login            := cn_last_update_login;                             --�ŏI�X�V۸޲�
            gt_tab_sales_exp_lines(ln_m).request_id                   := cn_request_id;                                    --�v��ID
            gt_tab_sales_exp_lines(ln_m).program_application_id       := cn_program_application_id;                        --�ݶ��ĥ��۸��ѥ���ع����ID
            gt_tab_sales_exp_lines(ln_m).program_id                   := cn_program_id;                                    --�ݶ��ĥ��۸���ID
            gt_tab_sales_exp_lines(ln_m).program_update_date          := cd_program_update_date;                           --��۸��эX�V��
          END IF;
          --���v���z������
          ln_main_body_total     := 0;
          ln_business_cost_total := 0;
          ln_difference_money    := 0;
          --�w�b�_�J�E���gUP
          ln_h := ln_h + 1;
          --�Ώی���
          gn_target_cnt := gn_target_cnt +1;
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
          --�[�i���הԍ�������
          ln_line_index := 1; 
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
          --�w�b�_�V�[�P���X�擾
          SELECT xxcos_sales_exp_headers_s01.nextval
          INTO   ln_header_id
          FROM   DUAL;
          --�[�i�`�[�ԍ��V�[�P���X�擾
--******************************* 2009/06/11 1.13 T.Kitajima MOD START ******************************--
--        lv_deli_seq := xxcos_def_pkg.set_order_number(NULL,NULL);
          SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
            INTO lv_deli_seq
            FROM dual;
--******************************* 2009/06/11 1.13 T.Kitajima MOD  END  ******************************--
          --����INDEX�l��ۊ�
          ln_index := ln_m + 1;
        END IF;
      ELSE
        --�擾�J�E���g���ő�𒴂�����
        IF ( gt_tab_work_data.COUNT < ln_i + 1 ) THEN
          ln_make_flg := 1;
        ELSE
          IF ( gt_tab_work_data(ln_i).shop_digestion_hdr_id != gt_tab_work_data(ln_i + 1).shop_digestion_hdr_id ) THEN
            ln_make_flg := 1;
          END IF;
        END IF;
        --�w�b�_ID���Ⴄ�ꍇ�̓w�b�_�f�[�^�ݒ�A�����v�Z�A�������ׂ��쐬����B
        IF ( ln_make_flg = 1 ) THEN
          ln_make_flg := 0;
          --�m�[�}����ݒ肵�ʏ폈���֖߂�
          lv_err_work := cv_status_normal;
          --�e�[�u���ϐ��̃G���[INDEX�����폜
          gt_tab_sales_exp_lines.DELETE(ln_index,ln_m);
          gt_tab_invent_seq.DELETE(ln_index,ln_m);
          --�X�L�b�v����
--****************************** 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--          gn_warn_cnt := gn_warn_cnt + ( ln_m - ln_index );
          gn_warn_cnt := gn_warn_cnt + 1;
--****************************** 2009/05/07 1.10 T.Kitajima MOD  END ******************************--
          --�Ώی���
          gn_target_cnt := gn_target_cnt +1;
          --����INDEX�l��ۊ�
          ln_index := ln_m + 1;
        END IF;
      END IF;
      --���׃J�E���gUP
      ln_m := ln_m + 1;
    END LOOP;
--
    --�e�[�u���R���N�V�����̓���ւ��B
--
    --������
    ln_index := 1;
--
    --���ו����[�v����
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_sales_exp_lines.EXISTS(ln_i) ) THEN
        gt_tab_sales_exp_lines_ins(ln_index) := gt_tab_sales_exp_lines(ln_i);
        ln_index := ln_index + 1;
      END IF;
    END LOOP;
    --������
    ln_index := 1;
    --�X�V�Ώە����[�v����
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_invent_seq.EXISTS(ln_i) ) THEN
        IF ( gt_tab_invent_seq(ln_i) != cn_dmy ) THEN
          gt_tab_invent_seq_up(ln_index)       := gt_tab_invent_seq(ln_i);
          ln_index := ln_index + 1;
        END IF;
      END IF;
    END LOOP;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF (gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--#####################################  �Œ蕔 START ##########################################
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
  END calc_sales;
--
  /**********************************************************************************
   * Procedure Name   : set_lines
   * Description      : �̔����і��׍쐬(A-5)
   ***********************************************************************************/
  PROCEDURE set_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_lines'; -- �v���O������
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
    ln_i    NUMBER;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_lines_ins.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_lines VALUES gt_tab_sales_exp_lines_ins(ln_i);
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_lines_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END set_lines;
--
  /**********************************************************************************
   * Procedure Name   : set_headers
   * Description      : �̔����уw�b�_�쐬(A-6)
   ***********************************************************************************/
  PROCEDURE set_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_headers'; -- �v���O������
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
    ln_i    NUMBER;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_headers.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers VALUES gt_tab_sales_exp_headers(ln_i);
      --�Ώی����𐳏팏����
--****************************** 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--      gn_normal_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := gt_tab_sales_exp_headers.COUNT;
--****************************** 2009/05/07 1.10 T.Kitajima MOD  END  ******************************--

    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END set_headers;
--
  /**********************************************************************************
   * Procedure Name   : update_digestion
   * Description      : ���������ݒ�(A-7)
   ***********************************************************************************/
  PROCEDURE update_digestion(
    iv_base_code       IN         VARCHAR2,     -- ���_�R�[�h
    iv_customer_number IN         VARCHAR2,     -- �ڋq�R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_digestion'; -- �v���O������
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
    ln_i  NUMBER;  --�J�E���^�[
--
    -- *** ���[�J���E�J�[�\�� ***
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
    CURSOR lock_cur( it_inventory_seq xxcoi_inv_control.inventory_seq%TYPE )
    IS
      SELECT inventory_seq
        FROM xxcoi_inv_control
       WHERE inventory_seq     = it_inventory_seq
       FOR UPDATE NOWAIT
    ;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ===============================
    -- 1.�̔����э쐬���X�V����
    -- ===============================
    BEGIN
      FORALL ln_i in 1..gt_tab_shop_digestion_hdr_id.COUNT SAVE EXCEPTIONS
        UPDATE xxcos_shop_digestion_hdrs
           SET sales_result_creation_flag = ct_make_flag_yes,
               sales_result_creation_date = gd_business_date,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE shop_digestion_hdr_id      = gt_tab_shop_digestion_hdr_id(ln_i);
    EXCEPTION
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ===============================
    -- 2.�̔����э쐬���X�V����
    -- ===============================
    BEGIN
/* 2009/08/17 Ver1.14 Mod Start */
--      UPDATE xxcos_shop_digestion_hdrs
--         SET sales_result_creation_flag = ct_make_flag_yes,
--             sales_result_creation_date = gd_business_date,
--             last_updated_by            = cn_last_updated_by,
--             last_update_date           = cd_last_update_date,
--             last_update_login          = cn_last_update_login,
--             request_id                 = cn_request_id,
--             program_application_id     = cn_program_application_id,
--             program_id                 = cn_program_id,
--             program_update_date        = cd_program_update_date
--       WHERE uncalculate_class          = ct_un_calc_flag_1
--         AND sales_result_creation_flag = ct_make_flag_no
--         AND customer_number IN (
      UPDATE xxcos_shop_digestion_hdrs xsdh
         SET xsdh.sales_result_creation_flag = ct_make_flag_yes,
             xsdh.sales_result_creation_date = gd_business_date,
             xsdh.last_updated_by            = cn_last_updated_by,
             xsdh.last_update_date           = cd_last_update_date,
             xsdh.last_update_login          = cn_last_update_login,
             xsdh.request_id                 = cn_request_id,
             xsdh.program_application_id     = cn_program_application_id,
             xsdh.program_id                 = cn_program_id,
             xsdh.program_update_date        = cd_program_update_date
       WHERE xsdh.uncalculate_class          = ct_un_calc_flag_1
         AND xsdh.sales_result_creation_flag = ct_make_flag_no
         AND EXISTS (
/* 2009/08/17 Ver1.14 Mod End   */
               SELECT hca.account_number  account_number         --�ڋq�R�[�h
               FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                      xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
               WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID   = �ڋq�A�h�I��.�ڋqID
/* 2009/08/17 Ver1.14 Add Start */
               AND    xca.customer_code       = xsdh.customer_number --�ڋq�A�h�I��.�ڋq�R�[�h = ����VD�p�����v�Z�w�b�_.�ڋq�R�[�h
/* 2009/08/17 Ver1.14 Add End   */
               AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning                                     =    hca.customer_class_code
                              FROM   fnd_lookup_values  flv
                              WHERE  flv.lookup_type      = ct_qct_cust_type
                              AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                              AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                          AND     NVL( flv.end_date_active, gd_last_month_date )
                              AND    flv.enabled_flag     = ct_enabled_flag_yes
                              AND    flv.language         = ct_lang
                              AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                             ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
               AND    EXISTS (SELECT hcae.account_number --���_�R�[�h
                                FROM   hz_cust_accounts    hcae,
/* 2009/08/17 Ver1.14 Mod Start */
--                                       xxcmm_cust_accounts xcae
                                       xxcmm_cust_accounts xcae,
                                       fnd_lookup_values   flv
/* 2009/08/17 Ver1.14 Mod End   */
                                WHERE  hcae.cust_account_id = xcae.customer_id--�ڋq�}�X�^.�ڋqID =�ڋq�A�h�I��.�ڋqID
/* 2009/08/17 Ver1.14 Mod Start */
--                                AND    EXISTS (SELECT flv.meaning
--                                               FROM   fnd_application               fa,
--                                                      fnd_lookup_types              flt,
--                                                      fnd_lookup_values             flv
--                                               WHERE  fa.application_id                               =    flt.application_id
--                                               AND    flt.lookup_type                                 =    flv.lookup_type
--                                               AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                                               AND    flv.lookup_type                                 =    ct_qct_cust_type
--                                               AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_1
--                                               AND    flv.start_date_active                          <=    gd_last_month_date
--                                               AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                                               AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                                               AND    flv.language                                    =    USERENV( 'LANG' )
--                                               AND    flv.meaning                                     =    hcae.customer_class_code
--                                              ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
--                                AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                                --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
                                AND    flv.lookup_type      = ct_qct_cust_type
                                AND    flv.lookup_code      LIKE ct_qcc_cust_code_1
                                AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                            AND     NVL( flv.end_date_active, gd_last_month_date )
                                AND    flv.enabled_flag     = ct_enabled_flag_yes
                                AND    flv.language         = ct_lang
                                AND    flv.meaning          = hcae.customer_class_code
                                AND    (
                                         ( iv_base_code IS NULL )
                                         OR
                                         ( iv_base_code IS NOT NULL AND xcae.management_base_code = iv_base_code )
                                       ) --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
/* 2009/08/17 Ver1.14 Mod End   */
                                AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                               ) --�Ǘ����_�ɏ������鋒�_�R�[�h=�ڋq�A�h�I��.�O�����_or���㋒�_
/* 2009/08/17 Ver1.14 Mod Start */
--               AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
               AND    (
                        ( iv_customer_number IS NULL )
                        OR
                        ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                      ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
/* 2009/08/17 Ver1.14 Mod End   */
               AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning = xca.business_low_type
                              FROM   fnd_lookup_values  flv
                              WHERE  flv.lookup_type      = ct_qct_gyo_type
                              AND    flv.lookup_code      LIKE ct_qcc_it_code
                              AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                          AND     NVL( flv.end_date_active, gd_last_month_date )
                              AND    flv.enabled_flag     = ct_enabled_flag_yes
                              AND    flv.language         = ct_lang
                              AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                             )  --�Ƒԏ�����=�C���V���b�v,���В��c�X
               UNION
               SELECT hca.account_number  account_number         --�ڋq�R�[�h
               FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                      xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
               WHERE  hca.cust_account_id     = xca.customer_id --�ڋq�}�X�^.�ڋqID   = �ڋq�A�h�I��.�ڋqID
/* 2009/08/17 Ver1.14 Add Start */
               AND    xca.customer_code       = xsdh.customer_number --�ڋq�}�X�^.�ڋq�R�[�h = ����VD�p�����v�Z�w�b�_.�ڋq�R�[�h
/* 2009/08/17 Ver1.14 Add End   */
               AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning                                     =    hca.customer_class_code
                              FROM   fnd_lookup_values  flv
                              WHERE  flv.lookup_type      = ct_qct_cust_type
                              AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                              AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                          AND     NVL( flv.end_date_active, gd_last_month_date )
                              AND    flv.enabled_flag     = ct_enabled_flag_yes
                              AND    flv.language         = ct_lang
                              AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                             ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
               AND    (
                       xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                       OR
                       xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                      )--�ڋq�A�h�I��.�O�����_or���㋒�_ = IN�p�����_�R�[�h
/* 2009/08/17 Ver1.14 Mod Start */
--               AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
               AND    (
                        ( iv_customer_number IS NULL )
                        OR
                        ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                      ) --�ڋq�R�[�h=IN�p��(�ڋq�R�[�h)
/* 2009/08/17 Ver1.14 Mod End   */
               AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning = xca.business_low_type
                              FROM   fnd_lookup_values  flv
                              WHERE  flv.lookup_type      = ct_qct_gyo_type
                              AND    flv.lookup_code      LIKE ct_qcc_it_code
                              AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                          AND     NVL( flv.end_date_active, gd_last_month_date )
                              AND    flv.enabled_flag     = ct_enabled_flag_yes
                              AND    flv.language         = ct_lang
                              AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                             )  --�Ƒԏ�����=�C���V���b�v,���В��c�X
             )
       ;
    EXCEPTION
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ===============================
    -- 3.�I���Ǘ��e�[�u���X�V����
    -- ===============================
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
    BEGIN
      FOR ln_i in 1..gt_tab_invent_seq_up.COUNT LOOP
          OPEN lock_cur( gt_tab_invent_seq_up(ln_i) );
          CLOSE lock_cur;
      END LOOP;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( lock_cur%ISOPEN ) THEN
          CLOSE lock_cur;
        END IF;
        RAISE global_data_lock_expt;
    END;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
   BEGIN
      FORALL ln_i in 1..gt_tab_invent_seq_up.COUNT SAVE EXCEPTIONS
        UPDATE xxcoi_inv_control
           SET inventory_status           = gv_inv_status,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE inventory_seq              = gt_tab_invent_seq_up(ln_i);
    EXCEPTION
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_up_inv_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�X�ܕʗp�����v�Z�w�b�_�X�V��O
    WHEN global_up_headers_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_update_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�I���Ǘ��e�[�u���X�V��O
    WHEN global_up_inv_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_update_inv_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
--
    -- *** ���b�N �G���[ ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_inv_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
--#####################################  �Œ蕔 START ##########################################
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
  END update_digestion;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exec_div        IN         VARCHAR2,     -- 1.��������敪
    iv_base_code       IN         VARCHAR2,     -- 2.���_�R�[�h
    iv_customer_number IN         VARCHAR2,     -- 3.�ڋq�R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_err_emp  VARCHAR2(1);     -- ���^�[���E�R�[�h�ꎞ�ۊ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-0.��������
    -- ===============================
    init(
       iv_exec_div        -- 1.��������敪
      ,iv_base_code       -- 2.���_�R�[�h
      ,iv_customer_number -- 3.�ڋq�R�[�h
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N
    -- ===============================
    pram_chk(
       iv_exec_div        -- 1.��������敪
      ,iv_base_code       -- 2.���_�R�[�h
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-2.���ʃf�[�^�擾
    -- ===============================
    get_common_data(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-3.�X�ܕʗp�����v�Z�f�[�^�擾
    -- ===============================
    get_object_data(
       iv_base_code       -- ���_�R�[�h
      ,iv_customer_number -- �ڋq�R�[�h
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
        gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      END IF;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-4�D���i�ʔ���Z����
    -- ===============================
    calc_sales(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_err_emp := lv_retcode;
    END IF;
    -- ===============================
    -- A-5�D�̔����і��׍쐬
    -- ===============================
    set_lines(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-6�D�̔����уw�b�_�쐬
    -- ===============================
    set_headers(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-7�D���������ݒ�
    -- ===============================
    update_digestion(
       iv_base_code       -- ���_�R�[�h
      ,iv_customer_number -- �ڋq�R�[�h
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    -- ===============================
    --�f�[�^�쐬���̌x���L��
    IF ( lv_err_emp = cv_status_warn ) THEN
      ov_retcode := lv_err_emp;
    END IF;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf             OUT NOCOPY VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT NOCOPY VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_exec_div        IN  VARCHAR2,             -- 1.��������敪
    iv_base_code       IN  VARCHAR2,             -- 2.���_�R�[�h
    iv_customer_number IN  VARCHAR2              -- 3.�ڋq�R�[�h
  )
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       iv_exec_div        -- 1.��������敪
      ,iv_base_code       -- 2.���_�R�[�h
      ,iv_customer_number -- 3.�ڋq�R�[�h
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
    --�G���[�o��
/*
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
*/
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
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
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
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
END XXCOS004A02C;
/
