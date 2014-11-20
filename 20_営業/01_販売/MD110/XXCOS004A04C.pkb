CREATE OR REPLACE PACKAGE BODY XXCOS004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A04C (body)
 * Description      : �����u�c�[�i�f�[�^�쐬
 * MD.050           : �����u�c�[�i�f�[�^�쐬 MD050_COS_004_A04
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  roundup                �؏�֐�
 *  init                   ��������(A-0)
 *  pram_chk               �p�����[�^�`�F�b�N(A-1)
 *  get_common_data        ���ʃf�[�^�擾(A-2)
 *  get_object_data        �����u�c�p�����v�Z�f�[�^���o����(A-3)
 *  calc_sales             �[�i�f�[�^�v�Z����(A-4)
 *  set_lines              �̔����і��׍쐬(A-5)
 *  set_headers            �̔����уw�b�_�쐬(A-6)
 *  update_digestion       �����u�c�p�����v�Z�e�[�u���X�V����(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/14    1.0   T.miyashita       �V�K�쐬
 *  2009/02/04   1.1   T.miyashita       [COS_013]INV��v���Ԏ擾�s�
 *  2009/02/04   1.2   T.miyashita       [COS_017]��P���ƐŔ���P���̕s�
 *  2009/02/04   1.3   T.miyashita       [COS_024]�̔����z�̕s�
 *  2009/02/04   1.4   T.miyashita       [COS_028]�쐬���敪�̕s�
 *  2009/02/19   1.5   T.miyashita       [COS_091]�K��E�L���̌����̎捞�R��Ή�
 *  2009/02/20   1.6   T.Miyashita       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/23   1.7   T.Miyashita       [COS_116]�[�i���Z�b�g�s�
 *  2009/02/23   1.8   T.Miyashita       [COS_122]�c�ƒS�����R�[�h�Z�b�g�s�
 *  2009/03/23   1.9   T.Kitajima        [T1_0099]INV��v���ɂ��
 *                                                �o�׌��ۊǏꏊ�A�[�i�`�ԁA�[�i���_�擾���@�C��
 *  2009/03/30   1.10  T.Kitajima        [T1_0189]�̔����і���.�[�i���הԍ��̍̔ԕ��@��ύX
 *  2009/04/20   1.11  T.kitajima        [T1_0657]�f�[�^�擾0���G���[���x���I����
 *  2009/04/21   1.12  T.kitajima        [T1_0699]�[�i�`�ԌŒ�Ή�(1:�c�Ǝ�)
 *  2009/04/22   1.13  T.kitajima        [T1_0697]�Ώۃf�[�^�擾�������ύX�Ή�
 *  2009/04/27   1.13  N.Maeda           [T1_0697_0770]��������擾�����̒ǉ�
 *                                       �f�[�^�o�^�l�̏C��
 *  2009/05/07   1.14  T.kitajima        [T1_0888]�[�i���_�擾���@�ύX
 *                                       [T1_0911]����敪�N�C�b�N�R�[�h��
 *  2009/05/25   1.15  T.kitajima        [T1_1151]���z�}�C�i�X�Ή�
 *                                       [T1_1122]�؏�Ή�
 *                                       [T1_1208]�P���l�̌ܓ�
 *  2009/06/09   1.16  T.kitajima        [T1_1371]�s���b�N
 *  2009/06/10   1.16  T.kitajima        [T1_1412]�[�i�`�[�ԍ��擾�����ύX
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
  global_up_headers_expt      EXCEPTION; --�����u�c�p�����v�Z�w�b�_�X�V��O
  global_up_inv_expt          EXCEPTION; --�u�c�R�����ʎ���w�b�_�X�V��O
  global_select_err_expt      EXCEPTION; --SQL SELECT�G���[
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  global_call_api_expt        EXCEPTION;                                --API�ďo�G���[��O
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  global_quick_salse_err_expt EXCEPTION;                                --����敪�擾�G���[
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT  VARCHAR2(100) := 'XXCOS004A04C';  -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name     CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXCOS';                          --�̕��Z�k�A�v����
  --���ʃ��b�Z�[�W
  ct_msg_get_profile_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00004';               --�v���t�@�C���擾�G���[���b�Z�[�W
  ct_msg_select_data_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';               --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';               --�Ɩ����t�擾�G���[
  cv_msg_api_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';               --API�ďo�G���[���b�Z�[�W
  cv_msg_nodata_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';               --����0���p���b�Z�[�W
  cv_msg_period_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00026';               --��v���ԏ��擾�G���[���b�Z�[�W
  --
  cv_msg_delivered_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00160';               --�[�i�`�Ԏ擾
  cv_msg_uom_cnv               CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00161';               --�P�ʊ��Z�擾
  cv_msg_discrete_cost         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00162';               --�c�ƌ����擾
  cv_msg_deli_err              CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11061';               --�[�i�`�Ԏ擾�G���[
  cv_msg_tan_err               CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11062';               --�P�ʊ��Z�擾�G���[
  cv_msg_cost_err              CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11063';               --�c�ƌ����擾�G���[
  cv_msg_prd_err               CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11064';               --��v���Ԏ擾�G���[
  --�̕����b�Z�[�W
  ct_msg_pram_date             CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11051';               --�p�����[�^���b�Z�[�W
  ct_msg_class_cd_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11052';               --��������敪�`�F�b�N�G���[���b�Z�[�W
  ct_msg_base_cd_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11053';               --���_�R�[�h�K�{�G���[
  ct_msg_making_cd_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11054';               --�쐬���敪�擾�G���[
  cv_msg_inser_lines_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11055';               --�̔����і��דo�^�G���[
  cv_msg_inser_headers_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11056';               --�̔����уw�b�_�o�^�G���[
  cv_msg_update_headers_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11057';               --�����u�c�p�����v�Z�w�b�_�X�V�G���[
  cv_msg_update_inv_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11058';               --�u�c�R�����ʎ���w�b�_�X�V�G���[
  cv_msg_select_vd_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11060';               --�����u�c�p�����v�Z�f�[�^�擾�G���[
  cv_msg_select_salesreps_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10911';               --�c�ƒS�����R�[�h�擾�G���[
--****************************** 2009/03/23 1.9  T.kitajima ADD START ******************************--
  cv_msg_select_for_inv_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11065';               --�o�׌��ۊǏꏊ�擾�G���[���b�Z�[�W
  cv_msg_select_ship_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11066';               --�o�׋��_�擾�G���[���b�Z�[�W
--****************************** 2009/03/23 1.9  T.kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.12 T.Kitajima ADD START ******************************--
  ct_msg_get_organization_id   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11155';               --�݌ɑg�DID�̎擾
  ct_msg_get_calendar_code     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11156';               --�J�����_�R�[�h�̎擾
--****************************** 2009/04/22 1.12 T.Kitajima ADD START ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  cv_msg_salse_class_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11175';               --����敪�擾�G���[
  ct_msg_delivery_base_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11176';               --�[�i���_�擾�G���[���b�Z�[�W
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
  ct_msg_line_lock_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11177';               --�����u�c�p�����v�Z�e�[�u���擾�G���[���b�Z�[�W
  ct_msg_vd_lock_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11178';               --�u�c�R�����ʎ���w�b�_�e�[�u�����b�N�擾�G���[���b�Z�[�W
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_regular_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_REGULAR_ANY_CLASS';       --�������
  ct_qct_making_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_MK_ORG_CLS_MST_004_A04';  --�쐬���敪
  ct_qct_gyo_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_GYOTAI_SHO_MST_004_A04';  --�Ƒԏ����ޓ���}�X�^_004_A04
  ct_qct_cust_type             CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CUS_CLASS_MST_004_A04';   --�ڋq�敪����}�X�^
  ct_qct_tax_type2             CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --�ŃR�[�h����}�X�^
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  ct_qct_sales_type            CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_SALE_CLASS_MST_004_A04';  --����敪����}�X�^
  ct_qct_not_inv_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';        --��݌ɕi�ڃR�[�h
  ct_qct_hokan_type_mst        CONSTANT fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_HOKAN_TYPE_MST_004_A04';  --�ۊǏꏊ���ޓ���}�X�^_004_A04
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
  --�N�C�b�N�R�[�h
  ct_qcc_d_code                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04%';                 --�����EVD����
  ct_qcc_digestion_code        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_02';               --�����EVD����
  ct_qcc_digestion_code_1      CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_1%';               --�����EVD����
  ct_qcc_digestion_code_2      CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_2%';               --�����EVD����
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  ct_qcc_sales_code            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_04';               --�����EVD����
  ct_qcc_hokan_type_mst        CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS_004_A04_%';                --�ۊǏꏊ���ޓ���}�X�^
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
  --�g�[�N��
  cv_tkn_parm_data1            CONSTANT  VARCHAR2(10) :=  'PARAM1';        --�p�����[�^1
  cv_tkn_parm_data2            CONSTANT  VARCHAR2(10) :=  'PARAM2';        --�p�����[�^2
  cv_tkn_parm_data3            CONSTANT  VARCHAR2(10) :=  'PARAM3';        --�p�����[�^3
  cv_tkn_parm_data4            CONSTANT  VARCHAR2(10) :=  'PARAM4';        --�p�����[�^4
  cv_tkn_parm_data5            CONSTANT  VARCHAR2(10) :=  'PARAM5';        --�p�����[�^5
  cv_tkn_profile               CONSTANT  VARCHAR2(10) :=  'PROFILE';       --�v���t�@�C��
  cv_tkn_quick1                CONSTANT  VARCHAR2(10) :=  'QUICK1';        --�N�C�b�N
  cv_tkn_quick2                CONSTANT  VARCHAR2(10) :=  'QUICK2';        --�N�C�b�N
  cv_tkn_table                 CONSTANT  VARCHAR2(10) :=  'TABLE_NAME';    --�e�[�u������
  cv_tkn_key_data              CONSTANT  VARCHAR2(10) :=  'KEY_DATA';      --�L�[�f�[�^
  cv_tkn_account_name          CONSTANT  VARCHAR2(30) :=  'ACCOUNT_NAME';  --���Ԗ�
  cv_tkn_api_name              CONSTANT  VARCHAR2(10) :=  'API_NAME';      --API��
  --�v���t�@�C������
  cv_profile_item_cd           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DELI_DELAY_DAY';-- �����u�c�[�i�f�[�^�쐬�P�\����
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
  cv_profile_dlv_ptn           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DLV_PTN_CLS';   -- ����VD�[�i�f�[�^�쐬�p�[�i�`�ԋ敪
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  ct_prof_organization_code    CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOI1_ORGANIZATION_CODE';       --XXCOI:�݌ɑg�D�R�[�h
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                              --�g�p�\
  --���_/�ڋq�t���O
  ct_customer_flag_no          CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'N';                              --�ڋq
  ct_customer_flag_yes         CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'Y';                              --���_
  --�X�܃w�b�_�p�t���O
  ct_make_flag_yes             CONSTANT  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'Y';                              --�쐬�ς�
  ct_make_flag_no              CONSTANT  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'N';                              --���쐬
  ct_un_calc_flag_0            CONSTANT  xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                      := 0;                                --���v�Z�t���O
  ct_un_calc_flag_1            CONSTANT  xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                      := 1;                                --���v�Z�t���O
  --�ԍ��t���O
  ct_red_black_flag_0          CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '0';                              --��
  ct_red_black_flag_1          CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '1';                              --��
  --�萔���v�Z�C���^�t�F�[�X�σt���O
  ct_to_calculate_fees_flag    CONSTANT  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
                                      := 'N';                              --NO
  --�P���}�X�^�쐬�σt���O
  ct_unit_price_mst_flag       CONSTANT  xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
                                      := 'N';                              --NO
  --INV�C���^�t�F�[�X�σt���O
  ct_inv_interface_flag        CONSTANT  xxcos_sales_exp_lines.inv_interface_flag%TYPE
                                      := 'N';                              --NO
  --AR�C���^�t�F�[�X�σt���O
  ct_ar_interface_flag         CONSTANT  xxcos_sales_exp_headers.ar_interface_flag%TYPE
                                      := 'N';                              --NO
  --GL�C���^�t�F�[�X�σt���O
  ct_gl_interface_flag         CONSTANT  xxcos_sales_exp_headers.gl_interface_flag%TYPE
                                      := 'N';                              --NO
  --���V�X�e���C���^�t�F�[�X�σt���O
  ct_dwh_interface_flag        CONSTANT  xxcos_sales_exp_headers.dwh_interface_flag%TYPE
                                      := 'N';                              --NO
  --EDI���M�ς݃t���O
  ct_edi_interface_flag        CONSTANT  xxcos_sales_exp_headers.edi_interface_flag%TYPE
                                      := 'N';                              --NO
  --AR�ŋ��}�X�^�L���t���O
  ct_tax_enabled_yes           CONSTANT  ar_vat_tax_all_b.enabled_flag%TYPE
                                      := 'Y';                              --Y:�L��
  ct_apply_flag_yes            CONSTANT  xxcmm_system_items_b_hst.apply_flag%TYPE
                                      := 'Y';                              --Y:�L��
  --��v�敪
  cv_inv                       CONSTANT  VARCHAR2(10) := '01';             --INV
  --�J�[�h����敪
  cv_card_sale_class           CONSTANT  VARCHAR2(1)  := '1';              --1:����
  --�[�i�`�[�敪
  cv_dlv_invoice_class_1       CONSTANT  VARCHAR2(1)  := '1';              --1:�[�i
  --�[�i�`�[�敪
  cv_dlv_invoice_class_3       CONSTANT  VARCHAR2(1)  := '3';              --3:�[�i����
  --�[�������敪
  cv_tax_rounding_rule_UP      CONSTANT  VARCHAR2(10) := 'UP';             --�؏グ
  --�[�������敪
  cv_tax_rounding_rule_DOWN    CONSTANT  VARCHAR2(10) := 'DOWN';           --�؎̂�
  --�[�������敪
  cv_tax_rounding_rule_NEAREST CONSTANT  VARCHAR2(10) := 'NEAREST';        --�l�̌ܓ�
  --��v����
  ct_prof_gl_set_of_bks_id     CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'GL_SET_OF_BKS_ID';               --GL��v����ID
  --�J�[�h����敪
  ct_card_flag_cash            CONSTANT  xxcos_sales_exp_headers.card_sale_class%TYPE
                                      := '0';                              --0:����
  --��v���ԃI�[�v���X�e�[�^�X
  cv_open                      CONSTANT  VARCHAR2(10) := 'OPEN';           --OPEN
  --0
  cv_0                         CONSTANT  VARCHAR2(1)  := '0';              --0
  --1
  cv_1                         CONSTANT  VARCHAR2(1)  := '1';              --1
  --0
  cn_0                         CONSTANT  NUMBER       := 0;                --0
  --1
  cn_1                         CONSTANT  NUMBER       := 1;                --1
  --100
  cn_100                       CONSTANT  NUMBER       := 100;              --100
  --�_�~�[
  cn_dmy                       CONSTANT  NUMBER       := 0;
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--  --����敪
--  cv_sales_class_vd            CONSTANT  VARCHAR2(1)  := '4';              --�����EVD����
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
  --y
  cv_y                         CONSTANT  VARCHAR2(1)  := 'Y';              --Y
  --MM
  cv_mm                        CONSTANT  VARCHAR2(2)  := 'MM';             --MM
  --�o�^�敪
  cv_entry_class               CONSTANT  VARCHAR2(2)  := '5';              --����VD
--****************************** 2009/03/23 1.9  T.kitajima ADD START ******************************--
  --�I���Ώۋ敪
  ct_secondary_class_2         CONSTANT   mtl_secondary_inventories.attribute5%TYPE
                                          := '2';                     --����
  cv_exists_flag_yes            CONSTANT VARCHAR2(1) := 'Y';          --���݂���
--****************************** 2009/03/23 1.9  T.kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  --�ғ����X�e�[�^�X
  cn_sales_oprtn_day_normal     CONSTANT NUMBER       := 0;           --�ғ���
  cn_sales_oprtn_day_non        CONSTANT NUMBER       := 1;           --��ғ���
  cn_sales_oprtn_day_error      CONSTANT NUMBER       := 2;           --�G���[
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
--****************************** 2009/06/10 1.16 T.Kitajima ADD START ******************************--
  cv_snq_i                      CONSTANT VARCHAR2(1)  := 'I';
--****************************** 2009/06/10 1.16 T.Kitajima ADD  END  ******************************--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �u�c�����p�����v�Z�f�[�^�i�[�p�ϐ�
  TYPE g_rec_work_data IS RECORD
    (
      vd_digestion_hdr_id         xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,        --�����u�c�p�����v�Z�w�b�_ID
      customer_number             xxcos_vd_digestion_hdrs.customer_number%TYPE,            --�ڋq�R�[�h
      digestion_due_date          xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,         --�����v�Z���N����
      cust_account_id             xxcos_vd_digestion_hdrs.cust_account_id%TYPE,            --�ڋqID
      digestion_exe_date          xxcos_vd_digestion_hdrs.digestion_exe_date%TYPE,         --�����v�Z���s��
      ar_sales_amount             xxcos_vd_digestion_hdrs.ar_sales_amount%TYPE,            --������z
      sales_amount                xxcos_vd_digestion_hdrs.sales_amount%TYPE,               --�̔����z
      digestion_calc_rate         xxcos_vd_digestion_hdrs.digestion_calc_rate%TYPE,        --�����v�Z�|��
      master_rate                 xxcos_vd_digestion_hdrs.master_rate%TYPE,                --�}�X�^�|��
      balance_amount              xxcos_vd_digestion_hdrs.balance_amount%TYPE,             --���z
      cust_gyotai_sho             xxcos_vd_digestion_hdrs.cust_gyotai_sho%TYPE,            --�Ƒԏ�����
      tax_amount                  xxcos_vd_digestion_hdrs.tax_amount%TYPE,                 --����Ŋz
      delivery_date               xxcos_vd_digestion_hdrs.delivery_date%TYPE,              --�[�i��
      dlv_time                    xxcos_vd_digestion_hdrs.dlv_time%TYPE,                   --����
      sales_result_creation_date  xxcos_vd_digestion_hdrs.sales_result_creation_date%TYPE, --�̔����ѓo�^��
      sales_result_creation_flag  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE, --�̔����э쐬�σt���O
      pre_digestion_due_date      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE,     --�O������v�Z���N����
      uncalculate_class           xxcos_vd_digestion_hdrs.uncalculate_class%TYPE,          --���v�Z�敪
      change_out_time_100         xxcos_vd_digestion_hdrs.change_out_time_100%TYPE,        --��K�؂ꎞ��100�~
      change_out_time_10          xxcos_vd_digestion_hdrs.change_out_time_10%TYPE,         --��K�؂ꎞ��10�~
      vd_digestion_ln_id          xxcos_vd_digestion_lns.vd_digestion_ln_id%TYPE,          --�����u�c�p�����v�Z����ID
      digestion_ln_number         xxcos_vd_digestion_lns.digestion_ln_number%TYPE,         --�}��
      item_code                   xxcos_vd_digestion_lns.item_code%TYPE,                   --�i�ڃR�[�h
      inventory_item_id           xxcos_vd_digestion_lns.inventory_item_id%TYPE,           --�i��ID
      item_price                  xxcos_vd_digestion_lns.item_price%TYPE,                  --�艿
      unit_price                  xxcos_vd_digestion_lns.unit_price%TYPE,                  --�P��
      item_sales_amount           xxcos_vd_digestion_lns.item_sales_amount%TYPE,           --�i�ڕʔ̔����z
      uom_code                    xxcos_vd_digestion_lns.uom_code%TYPE,                    --�P�ʃR�[�h
      sales_quantity              xxcos_vd_digestion_lns.sales_quantity%TYPE,              --�̔���
      hot_cold_type               xxcos_vd_digestion_lns.hot_cold_type%TYPE,               --H/C
      column_no                   xxcos_vd_digestion_lns.column_no%TYPE,                   --�R����No
      delivery_base_code          xxcos_vd_digestion_lns.delivery_base_code%TYPE,          --�[�i���_�R�[�h
      ship_from_subinventory_code xxcos_vd_digestion_lns.ship_from_subinventory_code%TYPE, --�o�׌��ۊǏꏊ
      sold_out_class              xxcos_vd_digestion_lns.sold_out_class%TYPE,              --���؋敪
      sold_out_time               xxcos_vd_digestion_lns.sold_out_time%TYPE,               --���؎���
      tax_div                     xxcmm_cust_accounts.tax_div%TYPE,                        --����ŋ敪
      tax_uchizei_flag            fnd_lookup_values.attribute5%TYPE,                       --���Ńt���O
      tax_rate                    ar_vat_tax_all_b.tax_rate%TYPE,                          --����ŗ�
      tax_rounding_rule           hz_cust_site_uses_all.tax_rounding_rule%TYPE,            --�ŋ��|�[������
      tax_code                    ar_vat_tax_all_b.tax_code%TYPE,                          --AR�ŃR�[�h
      cash_receiv_base_code       xxcfr_cust_hierarchy_v.cash_receiv_base_code%TYPE,       --�������_�R�[�h
      party_id                    hz_cust_accounts.party_id%TYPE,                          --�p�[�e�BID
      party_name                  hz_parties.party_name%TYPE,                              --�ڋq��
      sale_base_code              xxcmm_cust_accounts.sale_base_code%TYPE,                 --�������㋒�_�R�[�h
      past_sale_base_code         xxcmm_cust_accounts.past_sale_base_code%TYPE,            --�O�����㋒�_�R�[�h
      duns_number_c               hz_parties.duns_number_c%TYPE,                           --�����ڋq�X�e�[�^�X
      past_customer_status        xxcmm_cust_accounts.past_customer_status%TYPE            --�O���ڋq�X�e�[�^�X
  );
  -- �̔����|�C���g�v�Z���ʊ֐��i�[�p�ϐ�
  TYPE g_rec_for_comfunc_inpara IS RECORD
    (
      resource_id                 xxcos_salesreps_v.resource_id%TYPE,                      --���\�[�XID
      party_id                    hz_cust_accounts.party_id%TYPE,                          --�p�[�e�BID
      party_name                  hz_parties.party_name%TYPE,                              --�ڋq��
      digestion_due_date          xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,         --�����v�Z���N����
      ar_sales_amount             xxcos_vd_digestion_hdrs.ar_sales_amount%TYPE,            --������z
      deli_seq                    VARCHAR2(12),                                            --�[�i�`�[�ԍ�
      cust_status                 VARCHAR2(30)                                             --�ڋq�X�e�[�^�X
  );
  --�X�V�p
  TYPE g_tab_vd_digestion_hdr_id IS TABLE OF xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    INDEX BY PLS_INTEGER;   -- �����u�c�p�����v�Z�w�b�_ID
  --�e�[�u����`
  TYPE g_tab_work_data IS TABLE OF g_rec_work_data INDEX BY PLS_INTEGER;                         --�����u�c�p�����v�Z�f�[�^�i�[�p�ϐ�
  TYPE g_tab_sales_exp_headers IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY PLS_INTEGER; --�̔����уw�b�_
  TYPE g_tab_sales_exp_lines IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY PLS_INTEGER;     --�̔����і���
  TYPE g_tab_for_comfunc_inpara IS TABLE OF g_rec_for_comfunc_inpara INDEX BY PLS_INTEGER;       --�̔����|�C���g�v�Z���ʊ֐��i�[�p�ϐ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_business_date                    DATE;                          --�Ɩ����t
  gv_delay_days                       VARCHAR2(10);                  --�����u�c�[�i�f�[�^�쐬�P�\����
  gd_delay_date                       DATE;                          --�����u�c�[�i�f�[�^�쐬�P�\��
  gv_making_code                      VARCHAR2(1);                   --�쐬���敪
  gt_tab_work_data                    g_tab_work_data;               --�Ώۃf�[�^�擾�p
  gt_tab_sales_exp_headers            g_tab_sales_exp_headers;       --�̔����уw�b�_
  gt_tab_sales_exp_lines              g_tab_sales_exp_lines;         --�̔����і���
  gt_tab_sales_exp_lines_ins          g_tab_sales_exp_lines;         --�̔����і���
  gt_tab_vd_digestion_hdr_id          g_tab_vd_digestion_hdr_id;     --�����u�c�p�����v�Z�w�b�_ID
  gt_tab_for_comfunc_inpara           g_tab_for_comfunc_inpara;      --�̔����|�C���g�v�Z���ʊ֐��p
  gv_exec_div                         VARCHAR2(100);                 --��������敪
  gv_base_code                        VARCHAR2(100);                 --���_�R�[�h
  gv_customer_number                  VARCHAR2(100);                 --�ڋq�R�[�h
  gn_gl_id                            NUMBER;                        --��v����ID
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
  gv_delay_ptn                        VARCHAR2(1);                   --�[�i�`�ԋ敪
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  gt_organization_code                mtl_parameters.organization_code%TYPE;
                                                                     --�݌ɑg�D�R�[�h
  gt_organization_id                  mtl_parameters.organization_id%TYPE;
                                                                     -- �݌ɑg�DID
  gt_calendar_code                    bom_calendars.calendar_code%TYPE;
                                                                     -- �J�����_�R�[�h
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  gv_sales_class_vd                   VARCHAR2(1);                           --�����EVD����(����敪)
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
--****************************** 2009/05/25 1.15 T.Kitajima ADD START ******************************--
  /**********************************************************************************
   * Procedure Name   : roundup
   * Description      : �؏�֐�
   ***********************************************************************************/
  FUNCTION roundup(in_number IN NUMBER, in_place IN INTEGER := 0)
  RETURN NUMBER
  IS
    ln_base NUMBER;
  BEGIN
    IF (in_number = 0)
      OR (in_number IS NULL)
    THEN
      RETURN 0;
    END IF;
--
    ln_base := 10 ** in_place ;
    RETURN CEIL( ABS( in_number ) * ln_base ) / ln_base * SIGN( in_number );
  END;
--****************************** 2009/05/25 1.15 T.Kitajima ADD  END  ******************************--
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
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => ct_msg_pram_date,
                    iv_token_name1  => cv_tkn_parm_data1,
                    iv_token_value1 => iv_exec_div,
                    iv_token_name2  => cv_tkn_parm_data2,
                    iv_token_value2 => iv_base_code,
                    iv_token_name3  => cv_tkn_parm_data3,
                    iv_token_value3 => iv_customer_number
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
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
    iv_exec_div        IN       VARCHAR2,     -- 1.��������敪
    iv_base_code       IN       VARCHAR2,     -- 2.���_�R�[�h
    iv_customer_number IN       VARCHAR2,     -- 3.�ڋq�R�[�h
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
    --2.��������敪�̃`�F�b�N�����܂��B
    --==============================================================
    SELECT COUNT(flv.meaning)
    INTO   ln_cnt
    FROM   fnd_application               fa,
           fnd_lookup_types              flt,
           fnd_lookup_values             flv
    WHERE  fa.application_id                               = flt.application_id
    AND    flt.lookup_type                                 = flv.lookup_type
    AND    fa.application_short_name                       = ct_xxcos_appl_short_name
    AND    flv.lookup_type                                 = ct_qct_regular_type
    AND    flv.lookup_code                                 = iv_exec_div
    AND    flv.start_date_active                          <= gd_business_date
    AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
    AND    flv.enabled_flag                                = ct_enabled_flag_yes
    AND    flv.language                                    = USERENV( 'LANG' )
    AND    ROWNUM                                          = cn_1
    ;
--
    IF ( ln_cnt = cn_0 ) THEN
      RAISE global_quick_err_expt;
    END IF;
--
    --==============================================================
    --3.�������s�̏ꍇ�A���_�R�[�h�̃`�F�b�N�����܂��B
    --==============================================================
    IF ( iv_exec_div = cv_0 ) THEN
      IF ( iv_base_code IS NULL ) THEN
        RAISE global_base_err_expt;
      END IF;
    END IF;
--
    gv_exec_div        := iv_exec_div;         --��������敪
    gv_base_code       := iv_base_code;        --���_�R�[�h
    gv_customer_number := iv_customer_number;  --�ڋq�R�[�h
--
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
    lv_err_code VARCHAR2(100);   --�G���[ID
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
    lv_str_api_name               VARCHAR2(5000);                     --�֐���
    lt_organization_id            mtl_parameters.organization_id%TYPE;
                                                                      --�݌ɑg�DID
    lt_organization_code          mtl_parameters.organization_code%TYPE;
                                                                      --�݌ɑg�D�R�[�h
    ln_date_index                 NUMBER;                             --���t�p�C���f�b�N�X
    ln_delay_days                 NUMBER;                             --�P�\����
    ld_work_delay_date            DATE;                               --�P�\���v�Z�p
    ln_sales_oprtn_day            NUMBER;                             --�߂�l:�ғ����`�F�b�N�p
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/27 1.13 N.Maeda ADD START ******************************--
    ln_record_date_flg            NUMBER;                             --�������p
--****************************** 2009/04/27 1.13 N.Maeda ADD  END  ******************************--
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
    --=======================================================================
    -- 1.�N�C�b�N�R�[�h�u�쐬���敪(�����v�Z�i�u�c�j)�v���擾���܂��B
    --=======================================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_making_code
      FROM   fnd_application               fa,
             fnd_lookup_types              flt,
             fnd_lookup_values             flv
      WHERE  fa.application_id                               = flt.application_id
      AND    flt.lookup_type                                 = flv.lookup_type
      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
      AND    flv.lookup_type                                 = ct_qct_making_type
      AND    flv.lookup_code                                 = ct_qcc_digestion_code
      AND    flv.start_date_active                          <= gd_business_date
      AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
      AND    flv.enabled_flag                                = ct_enabled_flag_yes
      AND    flv.language                                    = USERENV( 'LANG' )
      AND    ROWNUM                                          = cn_1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_err_expt;
    END;
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
    --============================================
    -- XXCOI:�݌ɑg�D�R�[�h
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_organization_code IS NULL ) THEN
      lv_key_info := ct_prof_organization_code;
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- �݌ɑg�DID�̎擾
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
--
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );                      -- �݌ɑg�DID�擾
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- �̔��p�J�����_�R�[�h�擾
    --============================================
    lt_organization_id        := gt_organization_id;
    lt_organization_code      := gt_organization_code;
    --
    xxcos_common_pkg.get_sales_calendar_code(
      ion_organization_id     => lt_organization_id,             -- �݌ɑg�D�h�c
      iov_organization_code   => lt_organization_code,           -- �݌ɑg�D�R�[�h
      ov_calendar_code        => gt_calendar_code,               -- �J�����_�R�[�h
      ov_errbuf               => lv_errbuf,                      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      ov_retcode              => lv_retcode,                     -- ���^�[���E�R�[�h               #�Œ�#
      ov_errmsg               => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- �J�����_�R�[�h�擾
      RAISE global_call_api_expt;
    END IF;
    --
    IF ( gt_calendar_code IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- �J�����_�R�[�h�擾
      RAISE global_call_api_expt;
    END IF;
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
    --====================================================================================
    -- 2.�uXXCOS1_DIGESTION_DELI_DELAY_DAY: �����u�c�[�i�f�[�^�쐬�P�\�����v���擾���܂��B
    --====================================================================================
--****************************** 2009/04/22 1.13 T.Kitajima MOD START ******************************--
--    --�P�\�����擾
--    gv_delay_days := FND_PROFILE.VALUE( cv_profile_item_cd );
--    --�P�\���Z�o
--    gd_delay_date             := gd_business_date - gv_delay_days;
--    --���擾
--    IF ( gv_delay_days IS NULL ) THEN
--      lv_key_info := cv_profile_item_cd;
--      RAISE global_get_profile_expt;
--    END IF;
--
    --�P�\�����擾
    gv_delay_days := FND_PROFILE.VALUE( cv_profile_item_cd );
--
    --���擾
    IF ( gv_delay_days IS NULL ) THEN
      lv_key_info := cv_profile_item_cd;
      RAISE global_get_profile_expt;
    END IF;
--
    --�P�\���Z�o
    --������
    ld_work_delay_date := gd_business_date;
    ln_delay_days      := TO_NUMBER( gv_delay_days );
    ln_date_index      := 0;
    ln_sales_oprtn_day := NULL;
--****************************** 2009/04/27 1.13 N.Maeda MOD START ******************************--
    ln_record_date_flg := 0;
    <<day_loop>>
    LOOP
      --
      EXIT WHEN ( ln_record_date_flg = 1 );
      ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                               id_check_target_date     => ld_work_delay_date,
                                               iv_calendar_code         => gt_calendar_code
                                               );
--
      --�ғ�������
      IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
        ld_work_delay_date  := ld_work_delay_date - 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
        ln_record_date_flg := 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_error ) THEN
        lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );
        RAISE global_call_api_expt;
      END IF;
--
    END LOOP day_loop;
--****************************** 2009/04/27 1.13 N.Maeda MOD  END  ******************************--
--
    ln_sales_oprtn_day := NULL;
--
    <<delay_day_loop>>
    WHILE ( ln_delay_days <> ln_date_index ) LOOP
      --
      ld_work_delay_date  := ld_work_delay_date - 1;
      ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                             id_check_target_date     => ld_work_delay_date,
                                             iv_calendar_code         => gt_calendar_code
                                           );
      --�ғ�������
      IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
        ln_date_index := ln_date_index + 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_error ) THEN
        lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );
        RAISE global_call_api_expt;
      END IF;
--
    END LOOP delay_day_loop;
--
    gd_delay_date             := ld_work_delay_date;
--
--****************************** 2009/04/22 1.13 T.Kitajima MOD  END  ******************************--
--
    --============================================
    -- 3. ��v����ID
    --============================================
    lv_gl_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL��v����ID
    IF ( lv_gl_id IS NULL ) THEN
      lv_key_info := ct_prof_gl_set_of_bks_id;
      RAISE global_get_profile_expt;
    ELSE
      gn_gl_id := TO_NUMBER( lv_gl_id );
    END IF;
--
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
    --============================================
    -- 4. �[�i�`�ԋ敪�擾
    --============================================
    gv_delay_ptn := FND_PROFILE.VALUE( cv_profile_dlv_ptn );
    --�[�i�`�ԋ敪
    IF ( gv_delay_ptn IS NULL ) THEN
      lv_key_info := cv_profile_dlv_ptn;
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
    --==============================================
    -- 5.�N�C�b�N�R�[�h�u����敪(4�F�����EVD����)�v���擾���܂��B
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_sales_class_vd
      FROM   fnd_application               fa,
             fnd_lookup_types              flt,
             fnd_lookup_values             flv
      WHERE  fa.application_id                               = flt.application_id
      AND    flt.lookup_type                                 = flv.lookup_type
      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
      AND    flv.lookup_type                                 = ct_qct_sales_type
      AND    flv.lookup_code                                 = ct_qcc_sales_code
      AND    flv.start_date_active                          <= gd_business_date
      AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
      AND    flv.enabled_flag                                = ct_enabled_flag_yes
      AND    flv.language                                    = USERENV( 'LANG' )
      AND    ROWNUM                                          = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_salse_err_expt;
    END;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
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
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_key_info
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
                                   iv_token_value2       => ct_qcc_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/04/27 1.13 N.Maeda ADD START ******************************--
  WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/04/27 1.13 N.Maeda ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  WHEN global_quick_salse_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_salse_class_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_sales_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_sales_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
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
   * Description      : �����u�c�p�����v�Z�f�[�^���o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_data(
    iv_exec_div        IN         VARCHAR2,     -- ��������敪
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
    --����p
    CURSOR get_data_cur1
    IS
      SELECT xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --�����u�c�p�����v�Z�w�b�_ID
             xsdh.customer_number               customer_number,                  --�ڋq�R�[�h
             xsdh.digestion_due_date            digestion_due_date,               --�����v�Z���N����
             xsdh.cust_account_id               cust_account_id,                  --�ڋqID
             xsdh.digestion_exe_date            digestion_exe_date,               --�����v�Z���s��
             xsdh.ar_sales_amount               ar_sales_amount,                  --������z
             xsdh.sales_amount                  sales_amount,                     --�̔����z
             xsdh.digestion_calc_rate           digestion_calc_rate,              --�����v�Z�|��
             xsdh.master_rate                   master_rate,                      --�}�X�^�|��
             xsdh.balance_amount                balance_amount,                   --���z
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --�Ƒԏ�����
             xsdh.tax_amount                    tax_amount,                       --����Ŋz
             xsdh.delivery_date                 delivery_date,                    --�[�i��
             xsdh.dlv_time                      dlv_time,                         --����
             xsdh.sales_result_creation_date    sales_result_creation_date,       --�̔����ѓo�^��
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --�̔����э쐬�σt���O
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --�O������v�Z���N����
             xsdh.uncalculate_class             uncalculate_class,                --���v�Z�敪
             xsdh.change_out_time_100           change_out_time_100,              --��K�؂ꎞ��100�~
             xsdh.change_out_time_10            change_out_time_10,               --��K�؂ꎞ��10�~
             xsdl.vd_digestion_ln_id            vd_digestion_ln_id,               --�����u�c�p�����v�Z����ID
             xsdl.digestion_ln_number           digestion_ln_number,              --�}��
             xsdl.item_code                     item_code,                        --�i�ڃR�[�h
             xsdl.inventory_item_id             inventory_item_id,                --�i��ID
             xsdl.item_price                    item_price,                       --�艿
             xsdl.unit_price                    unit_price,                       --�P��
             xsdl.item_sales_amount             item_sales_amount,                --�i�ڕʔ̔����z
             xsdl.uom_code                      uom_code,                         --�P�ʃR�[�h
             xsdl.sales_quantity                sales_quantity,                   --�̔���
             xsdl.hot_cold_type                 hot_cold_type,                    --H/C
             xsdl.column_no                     column_no,                        --�R����No
             xsdl.delivery_base_code            delivery_base_code,               --�[�i���_�R�[�h
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --�o�׌��ۊǏꏊ
             xsdl.sold_out_class                sold_out_class,                   --���؋敪
             xsdl.sold_out_time                 sold_out_time,                    --���؎���
             xxca.tax_div                       tax_div,                          --����ŋ敪
             flv.attribute5                     tax_uchizei_flag,                 --���Ńt���O
             avta.tax_rate                      tax_rate,                         --����ŗ�
             xchv.bill_tax_round_rule           bill_tax_round_rule,              --�ŋ��|�[������
             avta.tax_code                      tax_code,                         --AR�ŃR�[�h
             xchv.cash_receiv_base_code         cash_receiv_base_code,            --�������_�R�[�h
             hnas.party_id                      party_id,                         --�p�[�e�BID
             part.party_name                    party_name,                       --�p�[�e�B���i�������́j
             xxca.sale_base_code                sale_base_code,                   --�������㋒�_�R�[�h
             xxca.past_sale_base_code           past_sale_base_code,              --�O�����㋒�_�R�[�h
             part.duns_number_c                 duns_number_c,                    --�����ڋq�X�e�[�^�X
             xxca.past_customer_status          past_customer_status              --�O���ڋq�X�e�[�^�X
      FROM   xxcos_vd_digestion_hdrs   xsdh,    -- �����u�c�p�����v�Z�w�b�_�e�[�u��
             xxcos_vd_digestion_lns    xsdl,    -- �����u�c�p�����v�Z���׃e�[�u��
             hz_cust_accounts          hnas,    -- �ڋq�}�X�^
             xxcmm_cust_accounts       xxca,    -- �ڋq�A�h�I���}�X�^
             xxcfr_cust_hierarchy_v    xchv,    -- �ڋq�K�wVIEW
             ar_vat_tax_all_b          avta,    -- AR�ŋ��}�X�^
             hz_parties                part,    -- �ڋq�}�X�^
             fnd_application           fa,
             fnd_lookup_types          flt,
             fnd_lookup_values         flv,
             (
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               = flt.application_id
                             AND    flt.lookup_type                                 = flv.lookup_type
                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 = ct_qct_cust_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
                             AND    flv.start_date_active                          <= gd_delay_date
                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
                             AND    flv.language                                    = USERENV( 'LANG' )
                             AND    flv.meaning                                     = hca.customer_class_code
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    EXISTS (SELECT hcae.account_number --���_�R�[�h
                             FROM   hz_cust_accounts    hcae,
                                    xxcmm_cust_accounts xcae
                             WHERE  hcae.cust_account_id = xcae.customer_id --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
                             AND    EXISTS (SELECT flv.meaning
                                            FROM   fnd_application               fa,
                                                   fnd_lookup_types              flt,
                                                   fnd_lookup_values             flv
                                            WHERE  fa.application_id                               = flt.application_id
                                            AND    flt.lookup_type                                 = flv.lookup_type
                                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                                            AND    flv.lookup_type                                 = ct_qct_cust_type
                                            AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_1
                                            AND    flv.start_date_active                          <= gd_delay_date
                                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
                                            AND    flv.language                                    = USERENV( 'LANG' )
                                            AND    flv.meaning                                     = hcae.customer_class_code
                                           ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
                             AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
                                             --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p��(���_�R�[�h)
                             AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                            ) --�Ǘ����_�ɏ������鋒�_�R�[�h = �ڋq�A�h�I��.�O�����_or���㋒�_
              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               =    flt.application_id
                             AND    flt.lookup_type                                 =    flv.lookup_type
                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                             AND    flv.start_date_active                          <=    gd_delay_date
                             AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                             AND    flv.language                                    =    USERENV( 'LANG' )
                             AND    flv.meaning = xca.business_low_type
                            )  --�Ƒԏ����� = �����EVD����
              UNION
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               = flt.application_id
                             AND    flt.lookup_type                                 = flv.lookup_type
                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 = ct_qct_cust_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
                             AND    flv.start_date_active                          <= gd_delay_date
                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
                             AND    flv.language                                    = USERENV( 'LANG' )
                             AND    flv.meaning                                     = hca.customer_class_code
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     ) --�ڋq�A�h�I��.�O�����_or���㋒�_ = IN�p��(���_�R�[�h)
              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               =    flt.application_id
                             AND    flt.lookup_type                                 =    flv.lookup_type
                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                             AND    flv.start_date_active                          <=    gd_delay_date
                             AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                             AND    flv.language                                    =    USERENV( 'LANG' )
                             AND    flv.meaning = xca.business_low_type
                            )  --�Ƒԏ����� = �����EVD����
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --�w�b�_.�ڋq�R�[�h           = �擾�����ڋq�R�[�h
      AND    xsdh.vd_digestion_hdr_id        = xsdl.vd_digestion_hdr_id   --�w�b�_.�w�b�_ID             = ����.�w�b�_ID
      AND    xsdh.sales_result_creation_flag = ct_make_flag_no            --�w�b�_.�̔����э쐬�σt���O = 'N'
      AND    xsdh.uncalculate_class          = ct_un_calc_flag_0          --�w�b�_.���v�Z�敪           = 0
      AND    xsdh.digestion_due_date        <= gd_delay_date              --�w�b�_.�����v�Z���N����    <= �Ɩ����t�|�P�\����
      AND    xsdh.cust_account_id            = hnas.cust_account_id       --�w�b�_.�ڋqID               = �ڋq�}�X�^.�ڋqID
      AND    hnas.cust_account_id            = xxca.customer_id           --�ڋq�}�X�^.�ڋqID           = �A�h�I��.�ڋqID
      AND    xxca.tax_div                    = flv.attribute3             --�ڋq�}�X�^. ����ŋ敪      = �ŃR�[�h����}�X�^.LOOKUP�R�[�h
      AND    flv.attribute2                  = avta.tax_code              --�ŃR�[�h����}�X�^.DFF2     = AR�ŋ��}�X�^.�ŃR�[�h
      AND    avta.set_of_books_id            = gn_gl_id                   --AR�ŋ��}�X�^.�Z�b�g�u�b�N�X = GL��v����ID
      AND    avta.start_date                <= xsdh.digestion_due_date                --AR�ŋ��}�X�^.�J�n�� <= �����u�c�p�����v�Z�w�b�_.�����v�Z���N����
      AND    NVL( avta.end_date, xsdh.digestion_due_date ) >= xsdh.digestion_due_date --AR�ŋ��}�X�^.�I���� >= �����u�c�p�����v�Z�w�b�_.�����v�Z���N����
      AND    avta.enabled_flag               = ct_tax_enabled_yes         --AR�ŋ��}�X�^.�L��           = 'Y'
      AND    xsdh.cust_account_id            = xchv.ship_account_id       --�w�b�_.�ڋqID               = �ڋq�K�wVIEW.�o�א�ڋqID
      AND    xsdh.customer_number            = NVL( iv_customer_number,xsdh.customer_number )
                                                                          --�����u�c�p�����v�Z�w�b�_.�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
      AND    fa.application_id               = flt.application_id
      AND    flt.lookup_type                 = flv.lookup_type
      AND    fa.application_short_name       = ct_xxcos_appl_short_name
      AND    flv.lookup_type                 = ct_qct_tax_type2
      AND    flv.start_date_active          <= xsdh.digestion_due_date
      AND    NVL( flv.end_date_active, xsdh.digestion_due_date ) >= xsdh.digestion_due_date
      AND    flv.enabled_flag                = ct_enabled_flag_yes
      AND    flv.language                    = USERENV( 'LANG' )
      AND    hnas.party_id                   = part.party_id               --�ڋq�}�X�^.�ڋqID = �ڋq�}�X�^.�ڋqID
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity            != cn_0
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
                        FROM   fnd_application               fa,
                               fnd_lookup_types              flt,
                               fnd_lookup_values             flv
                        WHERE  fa.application_id                               = flt.application_id
                        AND    flt.lookup_type                                 = flv.lookup_type
                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
                        AND    flv.start_date_active                          <=    gd_business_date
                        AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
                        AND    flv.language                                    = USERENV( 'LANG' )
                        AND    flv.lookup_code                                 = xsdl.item_code
                      )
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
      ORDER BY xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id
      ;
    --�����p
    CURSOR get_data_cur2
    IS
      SELECT xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --�����u�c�p�����v�Z�w�b�_ID
             xsdh.customer_number               customer_number,                  --�ڋq�R�[�h
             xsdh.digestion_due_date            digestion_due_date,               --�����v�Z���N����
             xsdh.cust_account_id               cust_account_id,                  --�ڋqID
             xsdh.digestion_exe_date            digestion_exe_date,               --�����v�Z���s��
             xsdh.ar_sales_amount               ar_sales_amount,                  --������z
             xsdh.sales_amount                  sales_amount,                     --�̔����z
             xsdh.digestion_calc_rate           digestion_calc_rate,              --�����v�Z�|��
             xsdh.master_rate                   master_rate,                      --�}�X�^�|��
             xsdh.balance_amount                balance_amount,                   --���z
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --�Ƒԏ�����
             xsdh.tax_amount                    tax_amount,                       --����Ŋz
             xsdh.delivery_date                 delivery_date,                    --�[�i��
             xsdh.dlv_time                      dlv_time,                         --����
             xsdh.sales_result_creation_date    sales_result_creation_date,       --�̔����ѓo�^��
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --�̔����э쐬�σt���O
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --�O������v�Z���N����
             xsdh.uncalculate_class             uncalculate_class,                --���v�Z�敪
             xsdh.change_out_time_100           change_out_time_100,              --��K�؂ꎞ��100�~
             xsdh.change_out_time_10            change_out_time_10,               --��K�؂ꎞ��10�~
             xsdl.vd_digestion_ln_id            vd_digestion_ln_id,               --�����u�c�p�����v�Z����ID
             xsdl.digestion_ln_number           digestion_ln_number,              --�}��
             xsdl.item_code                     item_code,                        --�i�ڃR�[�h
             xsdl.inventory_item_id             inventory_item_id,                --�i��ID
             xsdl.item_price                    item_price,                       --�艿
             xsdl.unit_price                    unit_price,                       --�P��
             xsdl.item_sales_amount             item_sales_amount,                --�i�ڕʔ̔����z
             xsdl.uom_code                      uom_code,                         --�P�ʃR�[�h
             xsdl.sales_quantity                sales_quantity,                   --�̔���
             xsdl.hot_cold_type                 hot_cold_type,                    --H/C
             xsdl.column_no                     column_no,                        --�R����No
             xsdl.delivery_base_code            delivery_base_code,               --�[�i���_�R�[�h
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --�o�׌��ۊǏꏊ
             xsdl.sold_out_class                sold_out_class,                   --���؋敪
             xsdl.sold_out_time                 sold_out_time,                    --���؎���
             xxca.tax_div                       tax_div,                          --����ŋ敪
             flv.attribute5                     tax_uchizei_flag,                 --���Ńt���O
             avta.tax_rate                      tax_rate,                         --����ŗ�
             xchv.bill_tax_round_rule           bill_tax_round_rule,              --�ŋ��|�[������
             avta.tax_code                      tax_code,                         --AR�ŃR�[�h
             xchv.cash_receiv_base_code         cash_receiv_base_code,            --�������_�R�[�h
             hnas.party_id                      party_id,                         --�p�[�e�BID
             part.party_name                    party_name,                       --�p�[�e�B���i�������́j
             xxca.sale_base_code                sale_base_code,                   --�������㋒�_�R�[�h
             xxca.past_sale_base_code           past_sale_base_code,              --�O�����㋒�_�R�[�h
             part.duns_number_c                 duns_number_c,                    --�����ڋq�X�e�[�^�X
             xxca.past_customer_status          past_customer_status              --�O���ڋq�X�e�[�^�X
      FROM   xxcos_vd_digestion_hdrs   xsdh,    -- �����u�c�p�����v�Z�w�b�_�e�[�u��
             xxcos_vd_digestion_lns    xsdl,    -- �����u�c�p�����v�Z���׃e�[�u��
             hz_cust_accounts          hnas,    -- �ڋq�}�X�^
             xxcmm_cust_accounts       xxca,    -- �ڋq�A�h�I���}�X�^
             xxcfr_cust_hierarchy_v    xchv,    -- �ڋq�K�wVIEW
             ar_vat_tax_all_b          avta,    -- AR�ŋ��}�X�^
             hz_parties                part,    -- �ڋq�}�X�^
             fnd_application           fa,
             fnd_lookup_types          flt,
             fnd_lookup_values         flv,
             (
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               = flt.application_id
                             AND    flt.lookup_type                                 = flv.lookup_type
                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 = ct_qct_cust_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
                             AND    flv.start_date_active                          <= gd_business_date
                             AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
                             AND    flv.language                                    = USERENV( 'LANG' )
                             AND    flv.meaning                                     = hca.customer_class_code
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    EXISTS (SELECT hcae.account_number --���_�R�[�h
                             FROM   hz_cust_accounts    hcae,
                                    xxcmm_cust_accounts xcae
                             WHERE  hcae.cust_account_id = xcae.customer_id --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
                             AND    EXISTS (SELECT flv.meaning
                                            FROM   fnd_application               fa,
                                                   fnd_lookup_types              flt,
                                                   fnd_lookup_values             flv
                                            WHERE  fa.application_id                               = flt.application_id
                                            AND    flt.lookup_type                                 = flv.lookup_type
                                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                                            AND    flv.lookup_type                                 = ct_qct_cust_type
                                            AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_1
                                            AND    flv.start_date_active                          <= gd_business_date
                                            AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
                                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
                                            AND    flv.language                                    = USERENV( 'LANG' )
                                            AND    flv.meaning                                     = hcae.customer_class_code
                                           ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
                             AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
                                             --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p��(���_�R�[�h)
                             AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                            ) --�Ǘ����_�ɏ������鋒�_�R�[�h = �ڋq�A�h�I��.�O�����_or���㋒�_
              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               =    flt.application_id
                             AND    flt.lookup_type                                 =    flv.lookup_type
                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                             AND    flv.start_date_active                          <=    gd_business_date
                             AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                             AND    flv.language                                    =    USERENV( 'LANG' )
                             AND    flv.meaning = xca.business_low_type
                            )  --�Ƒԏ����� = �����EVD����
              UNION
              SELECT hca.account_number  account_number         --�ڋq�R�[�h
              FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                     xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
              WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               = flt.application_id
                             AND    flt.lookup_type                                 = flv.lookup_type
                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 = ct_qct_cust_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
                             AND    flv.start_date_active                          <= gd_business_date
                             AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
                             AND    flv.language                                    = USERENV( 'LANG' )
                             AND    flv.meaning                                     = hca.customer_class_code
                            ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     ) --�ڋq�A�h�I��.�O�����_or���㋒�_ = IN�p��(���_�R�[�h)
              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
              AND    EXISTS (SELECT flv.meaning
                             FROM   fnd_application               fa,
                                    fnd_lookup_types              flt,
                                    fnd_lookup_values             flv
                             WHERE  fa.application_id                               =    flt.application_id
                             AND    flt.lookup_type                                 =    flv.lookup_type
                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                             AND    flv.start_date_active                          <=    gd_business_date
                             AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                             AND    flv.language                                    =    USERENV( 'LANG' )
                             AND    flv.meaning = xca.business_low_type
                            )  --�Ƒԏ����� = �����EVD����
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --�w�b�_.�ڋq�R�[�h           = �擾�����ڋq�R�[�h
      AND    xsdh.vd_digestion_hdr_id        = xsdl.vd_digestion_hdr_id   --�w�b�_.�w�b�_ID             = ����.�w�b�_ID
      AND    xsdh.sales_result_creation_flag = ct_make_flag_no            --�w�b�_.�̔����э쐬�σt���O = 'N'
      AND    xsdh.uncalculate_class          = ct_un_calc_flag_0          --�w�b�_.���v�Z�敪           = 0
      AND    xsdh.cust_account_id            = hnas.cust_account_id       --�w�b�_.�ڋqID               = �ڋq�}�X�^.�ڋqID
      AND    hnas.cust_account_id            = xxca.customer_id           --�ڋq�}�X�^.�ڋqID           = �A�h�I��.�ڋqID
      AND    xxca.tax_div                    = flv.attribute3             --�ڋq�}�X�^. ����ŋ敪      = �ŃR�[�h����}�X�^.LOOKUP�R�[�h
      AND    flv.attribute2                  = avta.tax_code              --�ŃR�[�h����}�X�^.DFF2     = AR�ŋ��}�X�^.�ŃR�[�h
      AND    avta.set_of_books_id            = gn_gl_id                   --AR�ŋ��}�X�^.�Z�b�g�u�b�N�X = GL��v����ID
      AND    avta.start_date                <= xsdh.digestion_due_date                --AR�ŋ��}�X�^.�J�n�� <= �����u�c�p�����v�Z�w�b�_.�����v�Z���N����
      AND    NVL( avta.end_date, xsdh.digestion_due_date ) >= xsdh.digestion_due_date --AR�ŋ��}�X�^.�I���� >= �����u�c�p�����v�Z�w�b�_.�����v�Z���N����
      AND    avta.enabled_flag               = ct_tax_enabled_yes         --AR�ŋ��}�X�^.�L��           = 'Y'
      AND    xsdh.cust_account_id            = xchv.ship_account_id       --�w�b�_.�ڋqID               = �ڋq�K�wVIEW.�o�א�ڋqID
      AND    xsdh.customer_number            = NVL( iv_customer_number,xsdh.customer_number )
                                                                          --�����u�c�p�����v�Z�w�b�_.�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
      AND    fa.application_id               = flt.application_id
      AND    flt.lookup_type                 = flv.lookup_type
      AND    fa.application_short_name       = ct_xxcos_appl_short_name
      AND    flv.lookup_type                 = ct_qct_tax_type2
      AND    flv.start_date_active          <= xsdh.digestion_due_date
      AND    NVL( flv.end_date_active, xsdh.digestion_due_date ) >= xsdh.digestion_due_date
      AND    flv.enabled_flag                = ct_enabled_flag_yes
      AND    flv.language                    = USERENV( 'LANG' )
      AND    hnas.party_id                   = part.party_id               --�ڋq�}�X�^.�ڋqID = �ڋq�}�X�^.�ڋqID
 --****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity            != cn_0
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
                        FROM   fnd_application               fa,
                               fnd_lookup_types              flt,
                               fnd_lookup_values             flv
                        WHERE  fa.application_id                               = flt.application_id
                        AND    flt.lookup_type                                 = flv.lookup_type
                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
                        AND    flv.start_date_active                          <=    gd_business_date
                        AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
                        AND    flv.language                                    = USERENV( 'LANG' )
                        AND    flv.lookup_code                                 = xsdl.item_code
                      )
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
     ORDER BY xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
     FOR UPDATE OF xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id NOWAIT
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
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
      --����̏ꍇ
      IF ( iv_exec_div = cv_1 ) THEN
        OPEN get_data_cur1;
        -- �o���N�t�F�b�`
        FETCH get_data_cur1 BULK COLLECT INTO gt_tab_work_data;
        --�擾����
        gn_target_cnt := get_data_cur1%ROWCOUNT;
        -- �J�[�\��CLOSE
        CLOSE get_data_cur1;
      --�����̏ꍇ
      ELSIF ( iv_exec_div = cv_0 ) THEN
        OPEN get_data_cur2;
        -- �o���N�t�F�b�`
        FETCH get_data_cur2 BULK COLLECT INTO gt_tab_work_data;
        --�擾����
        gn_target_cnt := get_data_cur2%ROWCOUNT;
        -- �J�[�\��CLOSE
        CLOSE get_data_cur2;
      END IF;
    EXCEPTION
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
      WHEN global_data_lock_expt THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_data_cur1%ISOPEN ) THEN
          CLOSE get_data_cur1;
        END IF;
        IF ( get_data_cur2%ISOPEN ) THEN
          CLOSE get_data_cur2;
        END IF;
        RAISE global_data_lock_expt;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_data_cur1%ISOPEN ) THEN
          CLOSE get_data_cur1;
        END IF;
        IF ( get_data_cur2%ISOPEN ) THEN
          CLOSE get_data_cur2;
        END IF;
        --
        RAISE global_select_err_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --���o�Ώۂ�0���������ꍇ
    IF ( gn_target_cnt = cn_0 ) THEN
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
--****************************** 2009/04/20 1.11 T.kitajima MOD START ******************************--
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--****************************** 2009/04/20 1.11 T.kitajima MOD  END  ******************************--
    -- *** SQL SELECT �G���[ ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_select_vd_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
--
    -- *** ���b�N �G���[ ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_line_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
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
   * Description      : �[�i�f�[�^�v�Z����(A-4)
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
    ln_delete_start_index  NUMBER;        --�폜�J�n�|�C���gINDEX�ꎞ�ۊ�
    ln_index               NUMBER;        --INDEX�ꎞ�ۊ�
    lv_err_work            VARCHAR2(1);   --�G���[���[�N
    lv_organization_code   VARCHAR2(10);  --�݌ɑg�D�R�[�h
    lv_organization_id     NUMBER;        --�݌ɑg�D�h�c
--****************************** 2009/04/21 1.12 T.Kitajima DEL START ******************************--
--    lv_delivered_from      VARCHAR2(1);   --�[�i�`��
--****************************** 2009/04/21 1.12 T.Kitajima DEL  END  ******************************--
    ln_inventory_item_id   NUMBER;        --�i�ڂh�c
    lv_after_uom_code      VARCHAR2(10);  --���Z��P�ʃR�[�h
    ln_after_quantity      NUMBER;        --���Z�㐔��
    ln_content             NUMBER;        --�i����
    ln_amount_work_total   NUMBER;        --�����v�Z�|���ςݕi�ڕʔ̔����v���z
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
    ln_tax_work_total      NUMBER;        --���׏���Ŋz���v
    ln_amount_work_data    NUMBER;        -- �{�̋��z���v
    ln_count_data          NUMBER := 0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
    ln_header_id           NUMBER;        --�w�b�_ID
    ln_line_id             NUMBER;        --����ID
    ln_difference_money    NUMBER;        --���ً��z
    lv_deli_seq            VARCHAR2(12);  --�[�i�`�[�ԍ�
    ld_base_date           DATE;          --���
    lv_status              VARCHAR2(10);  --�X�e�[�^�X
    ld_from_date           DATE;          --��v(FROM)
    ld_to_date             DATE;          --��v(TO)
    ln_amount_work         NUMBER;        --������z�v�ZWORK
    ln_amount_work_max     NUMBER;        --�ő唄����z�v�ZWORK
    ln_tax_work            NUMBER;        --����ŋ��z�v�ZWORK
    ln_tax_work_calccomp   NUMBER;        --����ŋ��z�v�ZWORK�i�v�Z�����j
    ln_i_max               NUMBER;        --�e�[�u���ϐ�����ǂݍ��񂾍ő唄����z�������R�[�h�̈ꎞ�ۊǃC���f�b�N�X
    ln_m_max               NUMBER;        --�e�[�u���ϐ��ɏ����o�����ő唄����z�������R�[�h�̈ꎞ�ۊǃC���f�b�N�X
    lv_discrete_cost       VARCHAR2(12);  --�c�ƌ���
    ln_err_line_flag       NUMBER;        --�G���[���׃t���O
    lt_performance_by_code xxcos_shop_digestion_hdrs.performance_by_code%TYPE; --���ю҃R�[�h
    lt_resource_id         jtf_rs_resource_extns.resource_id%TYPE;             --���\�[�XID
--**************************** 2009/03/23 1.9  T.kitajima ADD START ****************************
    lt_ship_from_subinventory_code xxcos_vd_digestion_lns.ship_from_subinventory_code%TYPE; --�o�׌��ۊǏꏊ
    lt_delivery_base_code          xxcos_vd_digestion_lns.delivery_base_code%TYPE;          --�[�i���_�R�[�h
--**************************** 2009/03/23 1.9  T.kitajima ADD  END  ****************************
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
    ln_line_index          NUMBER;        --�[�i���הԍ�
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
--**************************** 2009/04/27 1.13 T.kitajima ADD START ****************************
    ln_amount_data         NUMBER;        -- �{�̋��z�ꎞ�i�[�p
--**************************** 2009/04/27 1.13 T.kitajima ADD  END  ****************************
    lv_out_msg             VARCHAR(5000);
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
    ln_m                   := cn_1;
    ln_h                   := cn_1;
    ln_amount_work_total   := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
    ln_tax_work_total      := cn_0;
    ln_amount_work_data    := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
    ln_difference_money    := cn_0;
    lv_err_work            := cv_status_normal;
    ln_delete_start_index  := cn_1;
    ln_index               := cn_1;
    ln_amount_work_max     := null;
    ln_err_line_flag       := cn_0;
    ln_line_index          := 1;
    --�w�b�_�V�[�P���X�擾
    SELECT xxcos_sales_exp_headers_s01.nextval
    INTO   ln_header_id
    FROM   DUAL;
    --�[�i�`�[�ԍ��V�[�P���X�擾
--******************************* 2009/06/10 1.12 T.Kitajima MOD START ******************************--
--    lv_deli_seq := xxcos_def_pkg.set_order_number( NULL,NULL );
    SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
      INTO lv_deli_seq
      FROM dual;
--******************************* 2009/06/10 1.12 T.Kitajima MOD  END  ******************************--
    -- ���[�v�J�n
    <<keisan_loop>>
    FOR ln_i IN 1..gn_target_cnt LOOP
--
      --���펞�̂ݔ[�i�`�ԁA�P�ʊ��Z���s���B
      IF ( lv_err_work = cv_status_normal ) THEN
--**************************** 2009/03/23 1.9  T.kitajima MOD START ****************************
--        --�[�i�`�Ԏ擾
--        xxcos_common_pkg.get_delivered_from(
--          gt_tab_work_data(ln_i).ship_from_subinventory_code,  --�o�׌��ۊǏꏊ(IN)
--          gt_tab_work_data(ln_i).sale_base_code,               --���㋒�_(IN)
--          gt_tab_work_data(ln_i).delivery_base_code,           --�o�׋��_(IN)
--          lv_organization_code,                                --�݌ɑg�D�R�[�h(INOUT)
--          lv_organization_id,                                  --�݌ɑg�D�h�c(INOUT)
--          lv_delivered_from,                                   --�[�i�`��(OUT)
--          lv_errbuf,                                           --�G���[����b�Z�[�W(OUT)
--          lv_retcode,                                          --���^�[���R�[�h(OUT)
--          lv_errmsg                                            --���[�U��G���[����b�Z�[�W(OUT)
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          --�擾�G���[
--          lv_err_work     := cv_status_warn;
--          ov_errmsg       := xxccp_common_pkg.get_msg(
--                               iv_application        => ct_xxcos_appl_short_name,
--                               iv_name               => cv_msg_deli_err,
--                               iv_token_name1        => cv_tkn_parm_data1,
--                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                               iv_token_name2        => cv_tkn_parm_data2,
--                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                               iv_token_name3        => cv_tkn_parm_data3,
--                               iv_token_value3       => gt_tab_work_data(ln_i).ship_from_subinventory_code,
--                               iv_token_name4        => cv_tkn_parm_data4,
--                               iv_token_value4       => gt_tab_work_data(ln_i).sale_base_code,
--                               iv_token_name5        => cv_tkn_parm_data5,
--                               iv_token_value5       => gt_tab_work_data(ln_i).delivery_base_code
--                             );
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT,
--            buff   => ov_errmsg
--          );
--        ELSE
--          --�P�ʊ��Z���ݒ�
--          --
--          lv_after_uom_code := NULL; --�K��NULL��ݒ肵�Ă������ƁB
--          --
--          xxcos_common_pkg.get_uom_cnv(
--            gt_tab_work_data(ln_i).uom_code,        --���Z�O�P�ʃR�[�h(IN)
--            gt_tab_work_data(ln_i).sales_quantity,  --���Z�O����(IN)
--            gt_tab_work_data(ln_i).item_code,       --�i�ڃR�[�h(INOUT)
--            lv_organization_code,                   --�݌ɑg�D�R�[�h(INOUT)
--            ln_inventory_item_id,                   --�i��ID(INOUT)
--            lv_organization_id,                     --�݌ɑg�D�h�c(INOUT)
--            lv_after_uom_code,                      --���Z��P�ʃR�[�h(INOUT)
--            ln_after_quantity,                      --���Z�㐔��(OUT)
--            ln_content,                             --����(OUT)
--            lv_errbuf,                              --�G���[����b�Z�[�W(OUT)
--            lv_retcode,                             --���^�[���R�[�h(OUT)
--            lv_errmsg                               --���[�U��G���[����b�Z�[�W(OUT)
--          );
--          IF ( lv_retcode = cv_status_error ) THEN
--            --�擾�G���[
--            lv_err_work   := cv_status_warn;
--            ov_errmsg     := xxccp_common_pkg.get_msg(
--                               iv_application        => ct_xxcos_appl_short_name,
--                               iv_name               => cv_msg_tan_err,
--                               iv_token_name1        => cv_tkn_parm_data1,
--                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                               iv_token_name2        => cv_tkn_parm_data2,
--                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                               iv_token_name3        => cv_tkn_parm_data3,
--                               iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
--                               iv_token_name4        => cv_tkn_parm_data4,
--                               iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
--                               iv_token_name5        => cv_tkn_parm_data5,
--                               iv_token_value5       => gt_tab_work_data(ln_i).item_code
--                             );
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT,
--              buff   => ov_errmsg
--            );
--          ELSE
--            BEGIN
--              --�c�ƌ������擾
--              SELECT
--                xsibh.discrete_cost                     discrete_cost                  --�c�ƌ���
--              INTO
--                lv_discrete_cost
--              FROM
--                (
--                  SELECT
--                    xsibh.discrete_cost                 discrete_cost                  --�c�ƌ���
--                  FROM
--                    xxcmm_system_items_b_hst          xsibh                            --�i�ډc�Ɨ����A�h�I���}�X�^
--                  WHERE
--                    xsibh.item_code                    = gt_tab_work_data(ln_i).item_code
--                  AND xsibh.apply_date                <= gt_tab_work_data(ln_i).digestion_due_date
--                  AND xsibh.apply_flag                 = ct_apply_flag_yes
--                  AND xsibh.discrete_cost             IS NOT NULL
--                  ORDER BY
--                    xsibh.apply_date                  desc
--                ) xsibh
--              WHERE
--                ROWNUM                                = 1
--              ;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_retcode := cv_status_error;
--            END;
--            IF ( lv_retcode = cv_status_error ) THEN
--              --�擾�G���[
--              lv_err_work   := cv_status_warn;
--              ov_errmsg     := xxccp_common_pkg.get_msg(
--                                 iv_application        => ct_xxcos_appl_short_name,
--                                 iv_name               => cv_msg_cost_err,
--                                 iv_token_name1        => cv_tkn_parm_data1,
--                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                 iv_token_name2        => cv_tkn_parm_data2,
--                                 iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                 iv_token_name3        => cv_tkn_parm_data3,
--                                 iv_token_value3       => gt_tab_work_data(ln_i).item_code,
--                                 iv_token_name4        => cv_tkn_parm_data4,
--                                 iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
--                               );
--              FND_FILE.PUT_LINE(
--                which  => FND_FILE.OUTPUT,
--                buff   => ov_errmsg
--              );
--            ELSE
--              --��v���ԏ��擾���ݒ�
--              xxcos_common_pkg.get_account_period(
--                cv_inv,                                    --��v�敪(IN)
--                gt_tab_work_data(ln_i).digestion_due_date, --���(IN)
--                lv_status,                                 --�X�e�[�^�X(OUT)
--                ld_from_date,                              --��v(FROM)(OUT)
--                ld_to_date,                                --��v(TO)(OUT)
--                lv_errbuf,                                 --�G���[����b�Z�[�W(OUT)
--                lv_retcode,                                --���^�[���R�[�h(OUT)
--                lv_errmsg                                  --���[�U��G���[����b�Z�[�W(OUT)
--              );
--              IF ( lv_retcode = cv_status_error ) THEN
--                --�擾�G���[
--                lv_err_work   := cv_status_warn;
--                ov_errmsg     := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => cv_msg_prd_err,
--                                   iv_token_name1        => cv_tkn_parm_data1,
--                                   iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                   iv_token_name2        => cv_tkn_parm_data2,
--                                   iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                   iv_token_name3        => cv_tkn_parm_data3,
--                                   iv_token_value3       => cv_inv,
--                                   iv_token_name4        => cv_tkn_parm_data4,
--                                   iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
--                                 );
--                FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT,
--                  buff   => ov_errmsg
--                );
--              ELSE
--                IF ( lv_status <> cv_open ) THEN
--                  --��v���ԏ��擾���ݒ�
--                  xxcos_common_pkg.get_account_period(
--                    cv_inv,           --��v�敪(IN)
--                    NULL,             --���(IN)
--                    lv_status,        --�X�e�[�^�X(OUT)
--                    ld_from_date,     --��v(FROM)(OUT)
--                    ld_to_date,       --��v(TO)(OUT)
--                    lv_errbuf,        --�G���[����b�Z�[�W(OUT)
--                    lv_retcode,       --���^�[���R�[�h(OUT)
--                    lv_errmsg         --���[�U��G���[����b�Z�[�W(OUT)
--                  );
--                  IF ( lv_retcode = cv_status_error ) THEN
--                    --�擾�G���[
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_prd_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                       iv_token_name2        => cv_tkn_parm_data2,
--                                       iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                       iv_token_name3        => cv_tkn_parm_data3,
--                                       iv_token_value3       => cv_inv,
--                                       iv_token_name4        => cv_tkn_parm_data4,
--                                       iv_token_value4       => NULL
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                  ELSE
--                    gt_tab_sales_exp_headers(ln_h).delivery_date := ld_from_date;                              --�[�i��
--                  END IF;
--                ELSE
--                  gt_tab_sales_exp_headers(ln_h).delivery_date   := gt_tab_work_data(ln_i).digestion_due_date; --�[�i��
--                END IF;
--                IF TRUNC(gt_tab_sales_exp_headers(ln_h).delivery_date, cv_mm ) = TRUNC( gd_business_date, cv_mm ) THEN --�����Ȃ�
--                  gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).sale_base_code;      --�������㋒�_�R�[�h
--                  gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).duns_number_c;       --�����ڋq�X�e�[�^�X(DFF14)
--                ELSE --�O���Ȃ�
--                  gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).past_sale_base_code;  --�O�����㋒�_�R�[�h
--                  gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).past_customer_status; --�O���ڋq�X�e�[�^�X(DFF14)
--                END IF;
--                --==================================
--                -- �c�ƒS�����R�[�h�擾
--                --==================================
--                BEGIN
--                  SELECT xsv.employee_number,
--                         xsv.resource_id
--                    INTO lt_performance_by_code,
--                         lt_resource_id
--                    FROM xxcos_salesreps_v xsv
--                   WHERE xsv.party_id                                                                 = gt_tab_work_data(ln_i).party_id
--                     AND xsv.effective_start_date                                                    <= gt_tab_sales_exp_headers(ln_h).delivery_date
--                     AND NVL( xsv.effective_end_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                    --�擾�G���[
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_select_salesreps_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                END;
--              END IF;
--            END IF;
--          END IF;
--        END IF;
        lv_after_uom_code := NULL; --�K��NULL��ݒ肵�Ă������ƁB
        lt_ship_from_subinventory_code := NULL;
--
        --==================================
        -- �P�ʊ��Z���ݒ�
        --==================================
        xxcos_common_pkg.get_uom_cnv(
          gt_tab_work_data(ln_i).uom_code,        --���Z�O�P�ʃR�[�h(IN)
          gt_tab_work_data(ln_i).sales_quantity,  --���Z�O����(IN)
          gt_tab_work_data(ln_i).item_code,       --�i�ڃR�[�h(INOUT)
          lv_organization_code,                   --�݌ɑg�D�R�[�h(INOUT)
          ln_inventory_item_id,                   --�i��ID(INOUT)
          lv_organization_id,                     --�݌ɑg�D�h�c(INOUT)
          lv_after_uom_code,                      --���Z��P�ʃR�[�h(INOUT)
          ln_after_quantity,                      --���Z�㐔��(OUT)
          ln_content,                             --����(OUT)
          lv_errbuf,                              --�G���[����b�Z�[�W(OUT)
          lv_retcode,                             --���^�[���R�[�h(OUT)
          lv_errmsg                               --���[�U��G���[����b�Z�[�W(OUT)
        );
        IF ( lv_retcode = cv_status_error ) THEN
          --�擾�G���[
          lv_err_work   := cv_status_warn;
          lv_out_msg    := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => cv_msg_tan_err,
                             iv_token_name1        => cv_tkn_parm_data1,
                             iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                             iv_token_name2        => cv_tkn_parm_data2,
                             iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                             iv_token_name3        => cv_tkn_parm_data3,
                             iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
                             iv_token_name4        => cv_tkn_parm_data4,
                             iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
                             iv_token_name5        => cv_tkn_parm_data5,
                             iv_token_value5       => gt_tab_work_data(ln_i).item_code
                           );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_out_msg
          );
          lv_out_msg := NULL;
        ELSE
          BEGIN
            --�c�ƌ������擾
            SELECT
              xsibh.discrete_cost                     discrete_cost                  --�c�ƌ���
            INTO
              lv_discrete_cost
            FROM
              (
                SELECT
                  xsibh.discrete_cost                 discrete_cost                  --�c�ƌ���
                FROM
                  xxcmm_system_items_b_hst          xsibh                            --�i�ډc�Ɨ����A�h�I���}�X�^
                WHERE
                  xsibh.item_code                    = gt_tab_work_data(ln_i).item_code
                AND xsibh.apply_date                <= gt_tab_work_data(ln_i).digestion_due_date
                AND xsibh.apply_flag                 = ct_apply_flag_yes
                AND xsibh.discrete_cost             IS NOT NULL
                ORDER BY
                  xsibh.apply_date                  desc
              ) xsibh
            WHERE
              ROWNUM                                = 1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_retcode := cv_status_error;
          END;
          IF ( lv_retcode = cv_status_error ) THEN
            --�擾�G���[
            lv_err_work   := cv_status_warn;
            lv_out_msg    := xxccp_common_pkg.get_msg(
                               iv_application        => ct_xxcos_appl_short_name,
                               iv_name               => cv_msg_cost_err,
                               iv_token_name1        => cv_tkn_parm_data1,
                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                               iv_token_name2        => cv_tkn_parm_data2,
                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                               iv_token_name3        => cv_tkn_parm_data3,
                               iv_token_value3       => gt_tab_work_data(ln_i).item_code,
                               iv_token_name4        => cv_tkn_parm_data4,
                               iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                             );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
              buff   => lv_out_msg
            );
            lv_out_msg := NULL;
          ELSE
            --��v���ԏ��擾���ݒ�
            xxcos_common_pkg.get_account_period(
              cv_inv,                                    --��v�敪(IN)
              gt_tab_work_data(ln_i).digestion_due_date, --���(IN)
              lv_status,                                 --�X�e�[�^�X(OUT)
              ld_from_date,                              --��v(FROM)(OUT)
              ld_to_date,                                --��v(TO)(OUT)
              lv_errbuf,                                 --�G���[����b�Z�[�W(OUT)
              lv_retcode,                                --���^�[���R�[�h(OUT)
              lv_errmsg                                  --���[�U��G���[����b�Z�[�W(OUT)
            );
            IF ( lv_retcode = cv_status_error ) THEN
              --�擾�G���[
              lv_err_work   := cv_status_warn;
              lv_out_msg    := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => cv_msg_prd_err,
                                 iv_token_name1        => cv_tkn_parm_data1,
                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                 iv_token_name2        => cv_tkn_parm_data2,
                                 iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                                 iv_token_name3        => cv_tkn_parm_data3,
                                 iv_token_value3       => cv_inv,
                                 iv_token_name4        => cv_tkn_parm_data4,
                                 iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                               );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT,
                buff   => lv_out_msg
              );
              lv_out_msg := NULL;
            ELSE
              IF ( lv_status <> cv_open ) THEN
                --��v���ԏ��擾���ݒ�
                xxcos_common_pkg.get_account_period(
                  cv_inv,           --��v�敪(IN)
                  NULL,             --���(IN)
                  lv_status,        --�X�e�[�^�X(OUT)
                  ld_from_date,     --��v(FROM)(OUT)
                  ld_to_date,       --��v(TO)(OUT)
                  lv_errbuf,        --�G���[����b�Z�[�W(OUT)
                  lv_retcode,       --���^�[���R�[�h(OUT)
                  lv_errmsg         --���[�U��G���[����b�Z�[�W(OUT)
                );
                IF ( lv_retcode = cv_status_error ) THEN
                  --�擾�G���[
                  lv_err_work   := cv_status_warn;
                  lv_out_msg    := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => cv_msg_prd_err,
                                     iv_token_name1        => cv_tkn_parm_data1,
                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                     iv_token_name2        => cv_tkn_parm_data2,
                                     iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                                     iv_token_name3        => cv_tkn_parm_data3,
                                     iv_token_value3       => cv_inv,
                                     iv_token_name4        => cv_tkn_parm_data4,
                                     iv_token_value4       => NULL
                                   );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT,
                    buff   => lv_out_msg
                  );
                  lv_out_msg := NULL;
                ELSE
                  gt_tab_sales_exp_headers(ln_h).delivery_date := ld_from_date;                              --�[�i��
                END IF;
              ELSE
                gt_tab_sales_exp_headers(ln_h).delivery_date   := gt_tab_work_data(ln_i).digestion_due_date; --�[�i��
              END IF;
              IF TRUNC(gt_tab_sales_exp_headers(ln_h).delivery_date, cv_mm ) = TRUNC( gd_business_date, cv_mm ) THEN --�����Ȃ�
                gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).sale_base_code;      --�������㋒�_�R�[�h
                gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).duns_number_c;       --�����ڋq�X�e�[�^�X(DFF14)
--
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--                --==================================
--                -- �o�׋��_(�[�i���_)�擾
--                --==================================
--                BEGIN
--                  SELECT xca.delivery_base_code delivery_base_code                --�ڋq�A�h�I���}�X�^.�[�i���_�R�[�h
--                    INTO lt_delivery_base_code
--                    FROM xxcmm_cust_accounts       xca                            --�ڋq�A�h�I���}�X�^
--                   --�ڋq�A�h�I��.�ڋq�R�[�h = �ڋq�R�[�h
--                   WHERE xca.customer_code      =  gt_tab_work_data(ln_i).customer_number
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                    --�擾�G���[
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_select_ship_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                END;
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
                --==================================
                -- �o�׌��ۊǏꏊ�擾
                --==================================
                BEGIN
                  SELECT msi.secondary_inventory_name    secondary_inventory_name,       --�ۊǏꏊ
                         msi.attribute7                  attribute7                      --�[�i���_�R�[�h
                    INTO lt_ship_from_subinventory_code,
                         lt_delivery_base_code
                    FROM mtl_secondary_inventories       msi                            --�ۊǏꏊ�}�X�^
                   WHERE msi.organization_id                                                    = gt_organization_id
                     AND msi.attribute7                                                         = gt_tab_sales_exp_headers(ln_h).sales_base_code
                     AND NVL( msi.disable_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
                     AND EXISTS(
                           SELECT
                             cv_exists_flag_yes            exists_flag
                           FROM
                             fnd_application               fa,
                             fnd_lookup_types              flt,
                             fnd_lookup_values             flv
                           WHERE
                             fa.application_id             = flt.application_id
                           AND flt.lookup_type             = flv.lookup_type
                           AND fa.application_short_name   = ct_xxcos_appl_short_name
                           AND flv.lookup_type             = ct_qct_hokan_type_mst
                           AND flv.lookup_code             LIKE ct_qcc_hokan_type_mst
                           AND flv.meaning                 = msi.attribute13
                           AND gt_tab_sales_exp_headers(ln_h).delivery_date >= flv.start_date_active
                           AND gt_tab_sales_exp_headers(ln_h).delivery_date <= NVL( flv.end_date_active, gt_tab_sales_exp_headers(ln_h).delivery_date )
                           AND flv.enabled_flag            = ct_enabled_flag_yes
                           AND flv.language                = USERENV( 'LANG' )
                           AND ROWNUM                      = 1
                         )
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    --�擾�G���[
                    lv_err_work   := cv_status_warn;
                    lv_out_msg    := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => cv_msg_select_for_inv_err,
                                       iv_token_name1        => cv_tkn_parm_data1,
                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                       iv_token_name2        => cv_tkn_parm_data2,
                                       iv_token_value2       => gt_tab_sales_exp_headers(ln_h).sales_base_code
                                     );
                    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT,
                      buff   => lv_out_msg
                    );
                 lv_out_msg := NULL;
                END;
--
              ELSE --�O���Ȃ�
                gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).past_sale_base_code;        --�O�����㋒�_�R�[�h
                gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).past_customer_status;       --�O���ڋq�X�e�[�^�X(DFF14)
                lt_ship_from_subinventory_code                 := gt_tab_work_data(ln_i).ship_from_subinventory_code;--�o�׌��ۊǏꏊ
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--                lt_delivery_base_code                          := gt_tab_work_data(ln_i).delivery_base_code;         --�o�׋��_
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
                 --�[�i���_�R�[�h�擾
                 BEGIN
                   lt_delivery_base_code := NULL;
                   --
                   SELECT msi.attribute7
                     INTO lt_delivery_base_code
                     FROM mtl_secondary_inventories msi
                    --�ۊǏꏊ�}�X�^.�o�׌��ۊǏꏊ�R�[�h = �o�׌��ۊǏꏊ�R�[�h
                    WHERE msi.secondary_inventory_name    = lt_ship_from_subinventory_code
                      --�ۊǏꏊ�}�X�^.�g�DID             = �݌ɑg�DID
                      AND msi.organization_id             = gt_organization_id
                   ;
                 EXCEPTION
                   WHEN OTHERS THEN
                     --�擾�G���[
                     lv_err_work   := cv_status_warn;
                     lv_out_msg    := xxccp_common_pkg.get_msg(
                                        iv_application        => ct_xxcos_appl_short_name,
                                        iv_name               => ct_msg_delivery_base_err,
                                        iv_token_name1        => cv_tkn_parm_data1,
                                        iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                        iv_token_name2        => cv_tkn_parm_data2,
                                        iv_token_value2       => lt_ship_from_subinventory_code
                                      );
                     FND_FILE.PUT_LINE(
                       which  => FND_FILE.OUTPUT,
                       buff   => lv_out_msg
                     );
                     lv_out_msg := NULL;
                END;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
              END IF;
--
--
              --==================================
              -- �c�ƒS�����R�[�h�擾
              --==================================
              BEGIN
                SELECT xsv.employee_number,
                       xsv.resource_id
                  INTO lt_performance_by_code,
                       lt_resource_id
                  FROM xxcos_salesreps_v xsv
                 WHERE xsv.party_id                                                                 = gt_tab_work_data(ln_i).party_id
                   AND xsv.effective_start_date                                                    <= gt_tab_sales_exp_headers(ln_h).delivery_date
                   AND NVL( xsv.effective_end_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  --�擾�G���[
                  lv_err_work   := cv_status_warn;
                  lv_out_msg    := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => cv_msg_select_salesreps_err,
                                     iv_token_name1        => cv_tkn_parm_data1,
                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number
                                   );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT,
                    buff   => lv_out_msg
                  );
                  lv_out_msg := NULL;
              END;
--
--****************************** 2009/04/21 1.12 T.Kitajima DEL START ******************************--
--              --==================================
--              -- �[�i�`�Ԏ擾
--              --==================================
--              xxcos_common_pkg.get_delivered_from(
--                lt_ship_from_subinventory_code,                      --�o�׌��ۊǏꏊ(IN)
--                gt_tab_sales_exp_headers(ln_h).sales_base_code,      --���㋒�_(IN)
--                lt_delivery_base_code,                               --�o�׋��_(IN)
--                lv_organization_code,                                --�݌ɑg�D�R�[�h(INOUT)
--                lv_organization_id,                                  --�݌ɑg�D�h�c(INOUT)
--                lv_delivered_from,                                   --�[�i�`��(OUT)
--                lv_errbuf,                                           --�G���[����b�Z�[�W(OUT)
--                lv_retcode,                                          --���^�[���R�[�h(OUT)
--                lv_errmsg                                            --���[�U��G���[����b�Z�[�W(OUT)
--              );
--              IF ( lv_retcode = cv_status_error ) THEN
--                --�擾�G���[
--                lv_err_work     := cv_status_warn;
--                ov_errmsg       := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => cv_msg_deli_err,
--                                     iv_token_name1        => cv_tkn_parm_data1,
--                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                     iv_token_name2        => cv_tkn_parm_data2,
--                                     iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                     iv_token_name3        => cv_tkn_parm_data3,
--                                     iv_token_value3       => lt_ship_from_subinventory_code,
--                                     iv_token_name4        => cv_tkn_parm_data4,
--                                     iv_token_value4       => gt_tab_sales_exp_headers(ln_h).sales_base_code,
--                                     iv_token_name5        => cv_tkn_parm_data5,
--                                     iv_token_value5       => lt_delivery_base_code
--                                   );
--                FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT,
--                  buff   => ov_errmsg
--                );
--              END IF;
--****************************** 2009/04/21 1.12 T.Kitajima DEL  END  ******************************--
            END IF;
          END IF;
        END IF;
--**************************** 2009/03/23 1.9  T.kitajima MOD  END  ****************************
      END IF;
      --
      --���펞�̂ݐݒ肷��
      --���ʊ֐��ŃG���[���������ꍇ�́A�ݒ菈���X���[
      IF ( lv_err_work = cv_status_normal ) THEN
        --���׃V�[�P���X�擾
        SELECT xxcos_sales_exp_lines_s01.nextval
        INTO   ln_line_id
        FROM   DUAL;
        --
        --���׃f�[�^�ݒ�
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                         --�̔����і���ID
        gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                       --�̔����уw�b�_ID
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                        --�[�i�`�[�ԍ�
--**************************** 2009/03/30 1.10 T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).vd_digestion_ln_id;          --�[�i���הԍ�
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                      --�[�i���הԍ�
        ln_line_index                                             := ln_line_index + 1;
--**************************** 2009/03/30 1.10 T.kitajima MOD  END  ****************************
        gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                               --�������הԍ�
--**************************** 2009/05/07 1.14 T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).sales_class                  := cv_sales_class_vd;                                  --����敪
        gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                  --����敪
--**************************** 2009/05/07 1.14 T.kitajima MOD  END  ****************************
--****************************** 2009/04/21 1.12 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := lv_delivered_from;                                  --�[�i�`�ԋ敪
        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_delay_ptn;                                       --�[�i�`�ԋ敪
--****************************** 2009/04/21 1.12 T.Kitajima MOD  END  ******************************--
        gt_tab_sales_exp_lines(ln_m).item_code                    := gt_tab_work_data(ln_i).item_code;                   --�i�ڃR�[�h
        gt_tab_sales_exp_lines(ln_m).dlv_qty                      := gt_tab_work_data(ln_i).sales_quantity;              --�[�i����
        gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_after_quantity;                                  --�����
        gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gt_tab_work_data(ln_i).uom_code;                    --�[�i�P��
        gt_tab_sales_exp_lines(ln_m).standard_uom_code            := lv_after_uom_code;                                  --��P��
--**************************** 2009/04/27 1.13 N.Maeda MOD START *********************************************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := gt_tab_work_data(ln_i).unit_price;                  --�[�i�P��
--        --
--        IF gt_tab_work_data(ln_i).tax_uchizei_flag = cv_y THEN --����
--          --����Ŋz�v�Z
--          ln_tax_work := gt_tab_work_data(ln_i).unit_price
--                            - ( gt_tab_work_data(ln_i).unit_price / ( cn_1 + gt_tab_work_data(ln_i).tax_rate / cn_100 ) );
--          --
--          IF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_UP ) THEN         --�؏グ
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - CEIL( ln_tax_work );
--          ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_DOWN ) THEN    --�؎̂�
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - TRUNC( ln_tax_work );
--          ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN --�l�̌ܓ�
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - ROUND( ln_tax_work );
--          ELSE
--            RAISE global_api_others_expt;
--          END IF;
--          --
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).unit_price;                --��P��
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := ln_tax_work_calccomp;                             --�Ŕ���P��
--        ELSE --�O�ł܂��͔�ې�
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).unit_price;                --��P��
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := gt_tab_work_data(ln_i).unit_price;                --�Ŕ���P��
--        END IF;
        --
        gt_tab_sales_exp_lines(ln_m).business_cost                := lv_discrete_cost;                                   --�c�ƌ���
        --
        --�����v�Z�|���ςݕi�ڕʔ̔����z��ROUND�i�i�ڕʔ̔����z���i�����v�Z�|���^�P�O�O�j�j
        ln_amount_work := ROUND( gt_tab_work_data(ln_i).item_sales_amount * ( gt_tab_work_data(ln_i).digestion_calc_rate / cn_100 ) );
        gt_tab_sales_exp_lines(ln_m).sale_amount                  := ln_amount_work;                                     --������z
        --����ŋ��z�������v�Z�|���ςݕi�ڕʔ̔����z�|�i�����v�Z�|���ςݕi�ڕʔ̔����z�^�i�P�{����ŗ��^�P�O�O�j�j
        ln_tax_work := ln_amount_work - ( ln_amount_work / ( cn_1 + gt_tab_work_data(ln_i).tax_rate / cn_100 ) );
        --
        IF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_UP ) THEN         --�؏グ
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--          gt_tab_sales_exp_lines(ln_m).tax_amount                 := CEIL( ln_tax_work );                                --����ŋ��z
----          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - CEIL( ln_tax_work );               --�{�̋��z
--          ln_amount_data                                          := ln_amount_work - CEIL( ln_tax_work );               --�{�̋��z
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := roundup( ln_tax_work );                             --����ŋ��z
          ln_amount_data                                          := ln_amount_work - roundup( ln_tax_work );            --�{�̋��z
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_DOWN ) THEN    --�؎̂�
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := TRUNC( ln_tax_work );                               --����ŋ��z
--          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - TRUNC( ln_tax_work );              --�{�̋��z
          ln_amount_data                                          := ln_amount_work - TRUNC( ln_tax_work );              --�{�̋��z
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN --�l�̌ܓ�
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := ROUND( ln_tax_work );                               --����ŋ��z
--          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - ROUND( ln_tax_work );              --�{�̋��z
          ln_amount_data                                          := ln_amount_work - ROUND( ln_tax_work );              --�{�̋��z
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSE
          RAISE global_api_others_expt;
        END IF;
        --
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
--                                                        TRUNC ( ( ln_amount_work / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --�[�i�P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
--                                                            TRUNC ( ( ln_amount_data / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --�Ŕ���P��
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := TRUNC ( ( ln_amount_work / ln_after_quantity ) , 2 ); --��P��
        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
                                                        ROUND ( ( ln_amount_work / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --�[�i�P��
        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
                                                            ROUND ( ( ln_amount_data / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --�Ŕ���P��
        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := ROUND ( ( ln_amount_work / ln_after_quantity ) , 2 ); --��P��
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
--**************************** 2009/04/27 1.13 N.Maeda MOD  END  *********************************************************************
        --�ԍ��t���O�擾
        IF ( gt_tab_sales_exp_lines(ln_m).sale_amount < cn_0 ) THEN
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                                --��
        ELSE
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                                --��
        END IF;
        --
        gt_tab_sales_exp_lines(ln_m).cash_and_card                := cn_0;                                               --����/�J�[�h���p�z
--**************************** 2009/03/23 1.9  T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := gt_tab_work_data(ln_i).ship_from_subinventory_code; --�o�׌��ۊǏꏊ
--        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_work_data(ln_i).delivery_base_code;          --�[�i���_�R�[�h
        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := lt_ship_from_subinventory_code;                     --�o�׌��ۊǏꏊ
        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := lt_delivery_base_code;                              --�[�i���_�R�[�h
--**************************** 2009/03/23 1.9  T.kitajima MOD  END  ****************************
        gt_tab_sales_exp_lines(ln_m).hot_cold_class               := gt_tab_work_data(ln_i).hot_cold_type;               --�g���b
        gt_tab_sales_exp_lines(ln_m).column_no                    := gt_tab_work_data(ln_i).column_no;                   --�R����No
        gt_tab_sales_exp_lines(ln_m).sold_out_class               := gt_tab_work_data(ln_i).sold_out_class;              --���؋敪
        gt_tab_sales_exp_lines(ln_m).sold_out_time                := gt_tab_work_data(ln_i).sold_out_time;               --���؎���
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
        --����v�Z
        --�����v�Z�|���ςݕi�ڕʔ̔����z�̍��v�z�v�Z
        ln_amount_work_total     := ln_amount_work_total     + ln_amount_work;
        --�ő�̏����v�Z�|���ςݕi�ڕʔ̔����z�Ɠǂݍ��񂾃e�[�u���C���f�b�N�X�Ə����o�����e�[�u���C���f�b�N�X��ۑ�

--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--        IF ( ln_amount_work_max <= ln_amount_work ) THEN
        IF   ( ln_amount_work_max <= ln_amount_work )
          OR ( ln_amount_work_max IS NULL )
        THEN
          ln_amount_work_max := ln_amount_work; --�ő�̏����v�Z�|���ςݕi�ڕʔ̔����z
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          ln_i_max := ln_i; --���݂̓Ǎ��e�[�u���C���f�b�N�X
          ln_m_max := ln_m; --���݂̏��o�e�[�u���C���f�b�N�X
        END IF;
        --
      ELSE --���ʊ֐��G���[�̏ꍇ
        --���׃G���[�t���O�𗧂Ă�
        ln_err_line_flag := cn_1;
        --�_�~�[���Z�b�g����
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id := cn_dmy;
        --�m�[�}����ݒ肵�ʏ폈���֖߂�
        lv_err_work := cv_status_normal;
      END IF;
      --
      --���̃��R�[�h������ �܂��� ���̃��R�[�h�ŃL�[�u���C�N����ꍇ
      IF ( gt_tab_work_data.COUNT < ln_i + cn_1 )
        OR
         ( ( gt_tab_work_data(ln_i).vd_digestion_hdr_id <> gt_tab_work_data(ln_i + cn_1).vd_digestion_hdr_id )
          OR ( gt_tab_work_data(ln_i).digestion_due_date <> gt_tab_work_data(ln_i + cn_1).digestion_due_date ) )
      THEN
        --�P�w�b�_�̒��ŃG���[���ׂ��P���ł����݂������H
        IF ( ln_err_line_flag = cn_1 ) THEN --���݂���
          --�e�[�u���ϐ��̃G���[INDEX�����폜
          gt_tab_sales_exp_lines.DELETE(ln_delete_start_index,ln_m);
          --�X�L�b�v����
          gn_warn_cnt := gn_warn_cnt + cn_1;
          --�G���[���׃t���O���Z�b�g
          ln_err_line_flag := cn_0;
--****************************** 2009/04/27 1.13 T.Kitajima ADD START ******************************--
          -- ���׃J�E���g�擾
          ln_count_data := ln_m;
--****************************** 2009/04/27 1.13 T.Kitajima ADD  END  ******************************--
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
          --�[�i���הԍ�������
          ln_line_index := 1;
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
        ELSE --���݂��Ȃ�����
          --�w�b�_�f�[�^�ݒ�
          gt_tab_vd_digestion_hdr_id(ln_h)                           := gt_tab_work_data(ln_i).vd_digestion_hdr_id;      --�̔����уw�b�_ID
          gt_tab_sales_exp_headers(ln_h).sales_exp_header_id         := ln_header_id;                                    --�̔����уw�b�_ID
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_number          := lv_deli_seq;                                     --�[�i�`�[�ԍ�
          gt_tab_sales_exp_headers(ln_h).order_invoice_number        := NULL;                                            --�����`�[�ԍ�
          gt_tab_sales_exp_headers(ln_h).order_number                := NULL;                                            --�󒍔ԍ�
          gt_tab_sales_exp_headers(ln_h).order_no_hht                := NULL;                                            --��No�iHHT)
          gt_tab_sales_exp_headers(ln_h).digestion_ln_number         := NULL;                                            --��No�iHHT�j�}��
          gt_tab_sales_exp_headers(ln_h).order_connection_number     := NULL;                                            --�󒍊֘A�ԍ�
          IF ( gt_tab_work_data(ln_i).ar_sales_amount >= cn_0 ) THEN
            gt_tab_sales_exp_headers(ln_h).dlv_invoice_class         := cv_dlv_invoice_class_1;                          --�[�i�`�[�敪
          ELSE
            gt_tab_sales_exp_headers(ln_h).dlv_invoice_class         := cv_dlv_invoice_class_3;                          --�[�i�`�[�敪
          END IF;
          gt_tab_sales_exp_headers(ln_h).cancel_correct_class        := NULL;                                            --����E�����敪
          gt_tab_sales_exp_headers(ln_h).input_class                 := NULL;                                            --���͋敪
          gt_tab_sales_exp_headers(ln_h).cust_gyotai_sho             := gt_tab_work_data(ln_i).cust_gyotai_sho;          --�Ƒԏ�����
          gt_tab_sales_exp_headers(ln_h).orig_delivery_date          := gt_tab_work_data(ln_i).delivery_date;            --�I���W�i���[�i��
          gt_tab_sales_exp_headers(ln_h).inspect_date                := gt_tab_work_data(ln_i).digestion_due_date;       --������
          gt_tab_sales_exp_headers(ln_h).orig_inspect_date           := gt_tab_work_data(ln_i).digestion_due_date;       --�I���W�i��������
          gt_tab_sales_exp_headers(ln_h).ship_to_customer_code       := gt_tab_work_data(ln_i).customer_number;          --�ڋq�y�[�i��z
          gt_tab_sales_exp_headers(ln_h).sale_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --������z���v
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
--          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount
--                                                                              - gt_tab_work_data(ln_i).tax_amount;       --�{�̋��z���v
--          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := gt_tab_work_data(ln_i).tax_amount;               --����ŋ��z���v
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
          gt_tab_sales_exp_headers(ln_h).consumption_tax_class       := gt_tab_work_data(ln_i).tax_div;                  --����ŋ敪
          gt_tab_sales_exp_headers(ln_h).tax_code                    := gt_tab_work_data(ln_i).tax_code;                 --�ŋ��R�[�h
          gt_tab_sales_exp_headers(ln_h).tax_rate                    := gt_tab_work_data(ln_i).tax_rate;                 --����ŗ�
          gt_tab_sales_exp_headers(ln_h).results_employee_code       := lt_performance_by_code;                          --���ьv��҃R�[�h
          gt_tab_sales_exp_headers(ln_h).receiv_base_code            := gt_tab_work_data(ln_i).cash_receiv_base_code;    --�������_�R�[�h
          gt_tab_sales_exp_headers(ln_h).order_source_id             := NULL;                                            --�󒍃\�[�XID
          gt_tab_sales_exp_headers(ln_h).card_sale_class             := ct_card_flag_cash;                               --�J�[�h����敪
          gt_tab_sales_exp_headers(ln_h).invoice_class               := NULL;                                            --�`�[�敪
          gt_tab_sales_exp_headers(ln_h).invoice_classification_code := NULL;                                            --�`�[���ރR�[�h
          gt_tab_sales_exp_headers(ln_h).change_out_time_100         := gt_tab_work_data(ln_i).change_out_time_100;      --��K�؂ꎞ�ԂP�O�O�~
          gt_tab_sales_exp_headers(ln_h).change_out_time_10          := gt_tab_work_data(ln_i).change_out_time_10;       --��K�؂ꎞ�ԂP�O�~
          gt_tab_sales_exp_headers(ln_h).ar_interface_flag           := ct_ar_interface_flag;                            --AR�C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).gl_interface_flag           := ct_gl_interface_flag;                            --GL�C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).dwh_interface_flag          := ct_dwh_interface_flag;                           --���V�X�e���C���^�t�F�[�X�σt���O
          gt_tab_sales_exp_headers(ln_h).edi_interface_flag          := ct_edi_interface_flag;                           --EDI���M�ς݃t���O
          gt_tab_sales_exp_headers(ln_h).edi_send_date               := NULL;                                            --EDI���M����
          gt_tab_sales_exp_headers(ln_h).hht_dlv_input_date          := TO_DATE(TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                                                                         || NVL(gt_tab_work_data(ln_i).dlv_time,'0000'),'yyyymmddhh24miss');
                                                                                                                         --HHT�[�i���͓���
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
          --
          gt_tab_for_comfunc_inpara(ln_h).resource_id                := lt_resource_id;                            -- ���\�[�XID
          gt_tab_for_comfunc_inpara(ln_h).party_id                   := gt_tab_work_data(ln_i).party_id;           -- �p�[�e�BID
          gt_tab_for_comfunc_inpara(ln_h).party_name                 := gt_tab_work_data(ln_i).party_name;         -- �p�[�e�B���́i�ڋq���́j
          gt_tab_for_comfunc_inpara(ln_h).digestion_due_date         := gt_tab_work_data(ln_i).digestion_due_date; -- �K����� �� �����v�Z����
          gt_tab_for_comfunc_inpara(ln_h).ar_sales_amount            := gt_tab_work_data(ln_i).ar_sales_amount;    -- ���v���z
          gt_tab_for_comfunc_inpara(ln_h).deli_seq                   := lv_deli_seq;                               -- DFF13�i�o�^���\�[�X�ԍ��j�� ��No.�iHHT�j
          --
          --
          --�����v�Z
          --���z �� AR������z �| �����v�Z�|���ςݕi�ڕʔ̔����z�̍��v�z
          ln_difference_money := gt_tab_work_data(ln_i).ar_sales_amount - ln_amount_work_total;
          IF ( ln_difference_money = cn_0 ) THEN
            NULL; --���قȂ�
          ELSE
            --���z���ő�̏����v�Z�|���ςݕi�ڕʔ̔����z�ɉ��Z����
            --�ő�̏����v�Z�|���ςݕi�ڕʔ̔����z�{���z
            ln_amount_work_max := ln_amount_work_max + ln_difference_money;
            --����Ŋz�̍Čv�Z
            --���z�����Z�����ő�̏����v�Z�|���ςݕi�ڕʔ̔����z�|�i���z�����Z�����ő�̏����v�Z�|���ςݕi�ڕʔ̔����z�^�i�P�{����ŗ��^�P�O�O�j�j
            ln_tax_work := ln_amount_work_max - ( ln_amount_work_max / ( cn_1 + gt_tab_work_data(ln_i_max).tax_rate / cn_100 ) );
            --������z
            gt_tab_sales_exp_lines(ln_m_max).sale_amount      := ln_amount_work_max;
            --
            --����Ŋz�̏����_��[���������A����ŋ��z�Ɩ{�̋��z���Čv�Z���A�o�͕ϐ��֍ĂуZ�b�g�������B
            IF ( gt_tab_work_data(ln_i_max).tax_rounding_rule    = cv_tax_rounding_rule_UP )      THEN    --�؏グ
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--             gt_tab_sales_exp_lines(ln_m_max).tax_amount     := CEIL( ln_tax_work );                       --����ŋ��z
--              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - CEIL( ln_tax_work );  --�{�̋��z
             gt_tab_sales_exp_lines(ln_m_max).tax_amount     := roundup( ln_tax_work );                       --����ŋ��z
              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - roundup( ln_tax_work );  --�{�̋��z
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
            ELSIF ( gt_tab_work_data(ln_i_max).tax_rounding_rule = cv_tax_rounding_rule_DOWN )    THEN    --�؎̂�
              gt_tab_sales_exp_lines(ln_m_max).tax_amount     := TRUNC( ln_tax_work );                      --����ŋ��z
              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - TRUNC( ln_tax_work ); --�{�̋��z
            ELSIF ( gt_tab_work_data(ln_i_max).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN    --�l�̌ܓ�
              gt_tab_sales_exp_lines(ln_m_max).tax_amount     := ROUND( ln_tax_work );                      --����ŋ��z
              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - ROUND( ln_tax_work ); --�{�̋��z
            ELSE
              RAISE global_api_others_expt;
            END IF;
--****************************** 2009/05/25 1.15 T.Kitajima MOD START  ******************************--
            --������P���v�Z
            gt_tab_sales_exp_lines(ln_m_max).dlv_unit_price               :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).sale_amount / gt_tab_sales_exp_lines(ln_m_max).dlv_qty ) , 2 );  --�[�i�P��
            gt_tab_sales_exp_lines(ln_m_max).standard_unit_price_excluded :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).pure_amount / gt_tab_sales_exp_lines(ln_m_max).dlv_qty ) , 2 );  --�Ŕ���P��
            gt_tab_sales_exp_lines(ln_m_max).standard_unit_price          :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).sale_amount / gt_tab_sales_exp_lines(ln_m_max).standard_qty ) , 2 );  --��P��
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END   ******************************--
          END IF;
--
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
          FOR ln_a IN (ln_count_data + 1)..ln_m LOOP
            ln_tax_work_total        := ln_tax_work_total        + gt_tab_sales_exp_lines(ln_a).tax_amount;
            ln_amount_work_data      := ln_amount_work_data      + gt_tab_sales_exp_lines(ln_a).pure_amount;
          END LOOP;
          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := ln_amount_work_data;
          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := ln_tax_work_total;
          ln_tax_work_total          := 0;
          ln_amount_work_data        := 0;
          -- ���׃J�E���g�擾
          ln_count_data              := ln_m;
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--          ln_amount_work_max         := cn_0;
          ln_amount_work_max         := NULL;
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          ln_i_max                   := cn_0;
          ln_m_max                   := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
--
          --�����v�Z�|���ςݕi�ڕʔ̔����v���z�̏�����
          ln_amount_work_total   := cn_0;
          --���z�̏�����
          ln_difference_money    := cn_0;
          --�w�b�_�J�E���gUP
          ln_h := ln_h + cn_1;
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
          --�[�i���הԍ�������
          ln_line_index := 1;
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
          --�w�b�_�V�[�P���X�擾
          SELECT xxcos_sales_exp_headers_s01.nextval
          INTO   ln_header_id
          FROM   DUAL;
          --�[�i�`�[�ԍ��V�[�P���X�擾
          lv_deli_seq := xxcos_def_pkg.set_order_number( NULL,NULL );
        END IF;
        --���̍폜�J�n�|�C���gINDEX�l��ۊ�
        ln_delete_start_index := ln_m + cn_1;
      END IF;
      --���׃J�E���gUP
      ln_m := ln_m + cn_1;
    END LOOP keisan_loop;
--
    --�e�[�u���R���N�V�����̓���ւ��B
    --���ו����[�v����
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_sales_exp_lines.EXISTS(ln_i) ) THEN
        gt_tab_sales_exp_lines_ins(ln_index) := gt_tab_sales_exp_lines(ln_i);
        ln_index := ln_index + cn_1;
      END IF;
    END LOOP;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF ( gn_warn_cnt > cn_0 ) THEN
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
                     iv_application        =>  ct_xxcos_appl_short_name,
                     iv_name               =>  cv_msg_inser_lines_err
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
    -- ���ʊ֐����K��L�����o�^��
    FOR i IN 1..gt_tab_for_comfunc_inpara.COUNT LOOP
--
      IF ( gt_tab_for_comfunc_inpara(i).ar_sales_amount > 0 ) THEN
--
        xxcos_task_pkg.task_entry(
          lv_errbuf                                       -- �G���[�E���b�Z�[�W
         ,lv_retcode                                      -- ���^�[���E�R�[�h
         ,lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,gt_tab_for_comfunc_inpara(i).resource_id        -- ���\�[�XID
         ,gt_tab_for_comfunc_inpara(i).party_id           -- �p�[�e�BID
         ,gt_tab_for_comfunc_inpara(i).party_name         -- �p�[�e�B���́i�ڋq���́j
         ,gt_tab_for_comfunc_inpara(i).digestion_due_date -- �K����� �� �����v�Z����
         ,NULL                                            -- �ڍד��e
         ,gt_tab_for_comfunc_inpara(i).ar_sales_amount    -- ���v���z
         ,cv_0                                            -- ���͋敪
         ,cv_entry_class                                  -- DFF12�i�o�^�敪�j�� 5
         ,gt_tab_for_comfunc_inpara(i).deli_seq           -- DFF13�i�o�^���\�[�X�ԍ��j�� ��No.�iHHT�j
         ,gt_tab_for_comfunc_inpara(i).cust_status        -- DFF14�i�ڋq�X�e�[�^�X�j
        );
--
        --�G���[�`�F�b�N
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP;
--
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_headers.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers VALUES gt_tab_sales_exp_headers(ln_i);
      --�Ώی����𐳏팏����
      gn_normal_cnt := gt_tab_sales_exp_headers.COUNT;
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
                     iv_application        =>  ct_xxcos_appl_short_name,
                     iv_name               =>  cv_msg_inser_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END set_headers;
--
  /**********************************************************************************
   * Procedure Name   : update_digestion
   * Description      : �����u�c�p�����v�Z�e�[�u���X�V����(A-7)
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
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
    CURSOR lock_cur
    IS
      SELECT digestion_vd_rate_maked_date
        FROM xxcos_vd_column_headers
       WHERE digestion_vd_rate_maked_date IS NOT NULL
       FOR UPDATE NOWAIT
    ;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
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
      FORALL ln_i in 1..gt_tab_vd_digestion_hdr_id.COUNT SAVE EXCEPTIONS
        UPDATE xxcos_vd_digestion_hdrs
           SET sales_result_creation_flag = ct_make_flag_yes,
               sales_result_creation_date = gd_business_date,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE vd_digestion_hdr_id        = gt_tab_vd_digestion_hdr_id(ln_i);
    EXCEPTION
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ===============================
    -- 2.�̔����э쐬���X�V����
    -- ===============================
    BEGIN
      UPDATE xxcos_vd_digestion_hdrs
         SET sales_result_creation_flag = ct_make_flag_yes,
             sales_result_creation_date = gd_business_date,
             last_updated_by            = cn_last_updated_by,
             last_update_date           = cd_last_update_date,
             last_update_login          = cn_last_update_login,
             request_id                 = cn_request_id,
             program_application_id     = cn_program_application_id,
             program_id                 = cn_program_id,
             program_update_date        = cd_program_update_date
       WHERE uncalculate_class          = ct_un_calc_flag_1
       AND   sales_result_creation_flag = ct_make_flag_no
       AND   digestion_due_date        <= DECODE( gv_exec_div, cn_0, digestion_due_date, gd_delay_date )
       AND   customer_number IN ( --�ڋq�R�[�h(9BYTE)
             SELECT hca.account_number  account_number         --�ڋq�R�[�h(30BYTE)
             FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                    xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
             WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
             AND    EXISTS (SELECT flv.meaning
                            FROM   fnd_application               fa,
                                   fnd_lookup_types              flt,
                                   fnd_lookup_values             flv
                            WHERE  fa.application_id                               = flt.application_id
                            AND    flt.lookup_type                                 = flv.lookup_type
                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                            AND    flv.lookup_type                                 = ct_qct_cust_type
                            AND    flv.start_date_active                          <= gd_delay_date
                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
                            AND    flv.language                                    = USERENV( 'LANG' )
                            AND    flv.meaning                                     = hca.customer_class_code
                           ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
             AND    EXISTS (SELECT hcae.account_number --���_�R�[�h
                              FROM   hz_cust_accounts    hcae,
                                     xxcmm_cust_accounts xcae
                              WHERE  hcae.cust_account_id = xcae.customer_id--�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
                              AND    EXISTS (SELECT flv.meaning
                                             FROM   fnd_application               fa,
                                                    fnd_lookup_types              flt,
                                                    fnd_lookup_values             flv
                                             WHERE  fa.application_id                               = flt.application_id
                                             AND    flt.lookup_type                                 = flv.lookup_type
                                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                                             AND    flv.lookup_type                                 = ct_qct_cust_type
                                             AND    flv.start_date_active                          <= gd_delay_date
                                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
                                             AND    flv.language                                    = USERENV( 'LANG' )
                                             AND    flv.meaning                                     = hcae.customer_class_code
                                            ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
                              AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
                                              --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
                              AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                           ) --�Ǘ����_�ɏ������鋒�_�R�[�h = �ڋq�A�h�I��.�O�����_or���㋒�_
             AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
             AND    EXISTS (SELECT flv.meaning
                            FROM   fnd_application               fa,
                                   fnd_lookup_types              flt,
                                   fnd_lookup_values             flv
                            WHERE  fa.application_id                               =    flt.application_id
                            AND    flt.lookup_type                                 =    flv.lookup_type
                            AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                            AND    flv.lookup_type                                 =    ct_qct_gyo_type
                            AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                            AND    flv.start_date_active                          <=    gd_delay_date
                            AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
                            AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                            AND    flv.language                                    =    USERENV( 'LANG' )
                            AND    flv.meaning                                     =    xca.business_low_type
                           )  --�Ƒԏ����� = �����EVD����
             UNION
             SELECT hca.account_number  account_number         --�ڋq�R�[�h
             FROM   hz_cust_accounts    hca,                   --�ڋq�}�X�^
                    xxcmm_cust_accounts xca                    --�ڋq�A�h�I��
             WHERE  hca.cust_account_id     = xca.customer_id  --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
             AND    EXISTS (SELECT flv.meaning
                            FROM   fnd_application               fa,
                                   fnd_lookup_types              flt,
                                   fnd_lookup_values             flv
                            WHERE  fa.application_id                               = flt.application_id
                            AND    flt.lookup_type                                 = flv.lookup_type
                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
                            AND    flv.lookup_type                                 = ct_qct_cust_type
                            AND    flv.start_date_active                          <= gd_delay_date
                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
                            AND    flv.language                                    = USERENV( 'LANG' )
                            AND    flv.meaning                                     = hca.customer_class_code
                           ) --�ڋq�}�X�^.�ڋq�敪 = 10(�ڋq)
             AND    (
                     xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                     OR
                     xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                    )--�ڋq�A�h�I��.�O�����_or���㋒�_ = IN�p�����_�R�[�h
             AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --�ڋq�R�[�h = IN�p��(�ڋq�R�[�h)
             AND    EXISTS (SELECT flv.meaning
                            FROM   fnd_application               fa,
                                   fnd_lookup_types              flt,
                                   fnd_lookup_values             flv
                            WHERE  fa.application_id                               =    flt.application_id
                            AND    flt.lookup_type                                 =    flv.lookup_type
                            AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
                            AND    flv.lookup_type                                 =    ct_qct_gyo_type
                            AND    flv.lookup_code                                 LIKE ct_qcc_d_code
                            AND    flv.start_date_active                          <=    gd_delay_date
                            AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
                            AND    flv.enabled_flag                                =    ct_enabled_flag_yes
                            AND    flv.language                                    =    USERENV( 'LANG' )
                            AND    flv.meaning                                     =    xca.business_low_type
                           )  --�Ƒԏ����� = �����EVD����
                                )
      ;
    EXCEPTION
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ========================================
    -- 3.�u�c�R�����ʎ���w�b�_�e�[�u���X�V����
    -- ========================================
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
    BEGIN
      OPEN lock_cur;
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( lock_cur%ISOPEN ) THEN
          CLOSE lock_cur;
        END IF;
        RAISE global_data_lock_expt;
    END;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
    BEGIN
      UPDATE xxcos_vd_column_headers
         SET
             forward_flag               = ct_make_flag_yes,
             forward_date               = gd_business_date,
             last_updated_by            = cn_last_updated_by,
             last_update_date           = cd_last_update_date,
             last_update_login          = cn_last_update_login,
             request_id                 = cn_request_id,
             program_application_id     = cn_program_application_id,
             program_id                 = cn_program_id,
             program_update_date        = cd_program_update_date
       WHERE digestion_vd_rate_maked_date IS NOT NULL;
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
    --�����u�c�p�����v�Z�w�b�_�X�V��O
    WHEN global_up_headers_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name,
                      iv_name               =>  cv_msg_update_headers_err
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�u�c�R�����ʎ���w�b�_�X�V��O
    WHEN global_up_inv_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name,
                      iv_name               =>  cv_msg_update_inv_err
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
--
    -- *** ���b�N �G���[ ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_vd_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
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
    gn_target_cnt := cn_0;
    gn_normal_cnt := cn_0;
    gn_error_cnt  := cn_0;
    gn_warn_cnt   := cn_0;
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
      iv_exec_div,        -- 1.��������敪
      iv_base_code,       -- 2.���_�R�[�h
      iv_customer_number, -- 3.�ڋq�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N
    -- ===============================
    pram_chk(
      iv_exec_div,        -- 1.��������敪
      iv_base_code,       -- 2.���_�R�[�h
      iv_customer_number, -- 3.�ڋq�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-2.���ʃf�[�^�擾
    -- ===============================
    get_common_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ====================================
    -- A-3.�����u�c�p�����v�Z�f�[�^���o����
    -- ====================================
    get_object_data(
      iv_exec_div,        -- ��������敪
      iv_base_code,       -- ���_�R�[�h
      iv_customer_number, -- �ڋq�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-4�D�[�i�f�[�^�v�Z����
    -- ===============================
    calc_sales(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================
    -- A-5�D�̔����і��׍쐬
    -- ===============================
    set_lines(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-6�D�̔����уw�b�_�쐬
    -- ===============================
    set_headers(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ========================================
    -- A-7�D�����u�c�p�����v�Z�e�[�u���X�V����
    -- ========================================
    update_digestion(
      iv_base_code,       -- ���_�R�[�h
      iv_customer_number, -- �ڋq�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    -- ===============================
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
      iv_which   => cv_log_header_out,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
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
      iv_exec_div,        -- 1.��������敪
      iv_base_code,       -- 2.���_�R�[�h
      iv_customer_number, -- 3.�ڋq�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    IF ( lv_retcode != cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt + gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
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
END XXCOS004A04C;
/

