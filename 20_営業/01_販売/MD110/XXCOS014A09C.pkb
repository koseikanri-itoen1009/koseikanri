CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A09C (body)
 * Description      : �S�ݓX�����f�[�^�쐬 
 * MD.050           : �S�ݓX�����f�[�^�쐬 MD050_COS_014_A09
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  proc_init              ��������(A-1)
 *  proc_out_header_record �w�b�_���R�[�h�쐬����(A-2)
 *  proc_get_data          �f�[�^�擾����(A-3)
 *  proc_out_csv_header    CSV�w�b�_���R�[�h�쐬����(A-4)
 *  proc_out_data_record   �f�[�^���R�[�h�쐬����(A-5)
 *  proc_out_footer_record �t�b�^���R�[�h�쐬����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/18    1.0   H.Noda           �V�K�쐬
 *  2009/03/18    1.1   Y.Tsubomatsu     [��QCOS_156] �p�����[�^�̌��g��(���[�R�[�h,���[�l��)
 *  2009/03/19    1.2   Y.Tsubomatsu     [��QCOS_158] �p�����[�^�̕ҏW(�S�ݓX�R�[�h,�S�ݓX�X�܃R�[�h,�}��)
 *  2009/04/17    1.3   T.Kitajima       [T1_0375] �G���[���b�Z�[�W�󒍔ԍ��C��(�`�[�ԍ�����No)
 *  2009/09/07    1.4   N.Maeda          [0000403] �����L�[���ڂ̔C�Ӊ��ɔ����}�Ԗ��̃��[�v�����ǉ�
 *
*** �J�����̕ύX���e ***
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
  ct_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  ct_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt      EXCEPTION;     --���b�N�G���[
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  update_expt             EXCEPTION;     --�X�V�G���[
  proc_get_data_expt      EXCEPTION;     --�f�[�^�擾�����G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A09C'; -- �p�b�P�[�W��
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --�A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:�f�[�^���R�[�h���ʎq
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM';          --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(EBS�󒍊Ǘ�)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:��Ж�
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX�s�T�C�Y
  ct_prf_phone_number             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_PHONE_NUMBER';                 --XXCOS:�d�b�ԍ�
  ct_prf_post_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_POST_CODE';                    --XXCOS:�X�֔ԍ�
  ct_prf_cmn_rep_chain_code       CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CMN_REP_CHAIN_CODE';           --XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  cv_tkn_xxcos1_dept_target_all   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DEPT_TARGET_ALL';              --XXCOS:�S�ݓX����
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --���b�Z�[�W
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:�f�[�^���R�[�h���ʎq
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00097';                    --XXCOS:���[OUTBOUND�o�̓f�B���N�g��
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:��Ж�
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX�s�T�C�Y
  ct_msg_phone_number             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00165';                    --XXCOS:�d�b�ԍ�
  ct_msg_post_code                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00166';                    --XXCOS:�X�֔ԍ�	
  ct_msg_cmn_rep_chain_code       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00101';                    --XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --���b�Z�[�W�p������.MO:�c�ƒP��
  ct_msg_cust_notfound            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13616';                    --�ڋq�}�X�^���o�^�G���[
  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --�v���t�@�C���擾�G���[
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --���b�Z�[�W�p������.�ڋq�}�X�^
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --���b�Z�[�W�p������.�i�ڃ}�X�^
  ct_msg_oe_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00069';                    --���b�Z�[�W�p������.�󒍃w�b�_���e�[�u��
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00170';                    --���b�Z�[�W�p������.Online
  ct_msg_header_type01            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00168';                    --���b�Z�[�W�p������.01_�S�ݓX��
  ct_msg_header_type02            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13610';                    --���b�Z�[�W�p������.04_�S�ݓX���{
  ct_msg_line_type_dept           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00169';                    --���b�Z�[�W�p������.10_�S�ݓX
  ct_msg_line_type_sample         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13611';                    --���b�Z�[�W�p������.50_�S�ݓX���{
  ct_msg_koguchi                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13607';                    --���b�Z�[�W�p������.������
  ct_msg_koguchi_itoen            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13608';                    --���b�Z�[�W�p������.�������i�ɓ����j
  ct_msg_koguchi_hashiba          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13609';                    --���b�Z�[�W�p������.�������i����j
  ct_msg_koguchi_can              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13612';                    --���b�Z�[�W�p������.��
  ct_msg_koguchi_dg               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13613';                    --���b�Z�[�W�p������.�c�f
  ct_msg_koguchi_g                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13614';                    --���b�Z�[�W�p������.�f
  ct_msg_koguchi_hoka             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13615';                    --���b�Z�[�W�p������.��
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --�擾�G���[
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --�}�X�^���o�^
  ct_msg_dept_mst_notfound        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13606';                    --�S�ݓX�}�X�^���o�^�G���[
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13604';                    --�p�����[�^�o�̓��b�Z�[�W1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13605';                    --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --�t�@�C���I�[�v���G���[���b�Z�[�W
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';                    --���b�N�G���[���b�Z�[�W
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --�Ώۃf�[�^�Ȃ����b�Z�[�W
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --�t�@�C�����o�̓��b�Z�[�W
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';                    --�f�[�^�X�V�G���[���b�Z�[�W
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --���b�Z�[�W�p������.�`�[�ԍ�
  ct_msg_integeral_num_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13601';                    --�����`�F�b�N�G���[
  ct_msg_koguchi_count_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13602';                    --���������ڐ��G���[
  ct_msg_line_count_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13603';                    --�d���`�[���׍s���G���[
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  ct_msg_rep_form_add_info_err    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13617';                    --���[�l���t�����̒��o�G���[
  ct_msg_dept_target_all          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13618';                    --���b�Z�[�W�p������uXXCOS:�S�ݓX���́v
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --�g�[�N��
  cv_tkn_data                     CONSTANT VARCHAR2(4)   := 'DATA';                                 --�f�[�^
  cv_tkn_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                                --�e�[�u��
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';                               --���̓p�����[�^1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';                               --���̓p�����[�^2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6)   := 'PARAM3';                               --���̓p�����[�^3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6)   := 'PARAM4';                               --���̓p�����[�^4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6)   := 'PARAM5';                               --���̓p�����[�^5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6)   := 'PARAM6';                               --���̓p�����[�^6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6)   := 'PARAM7';                               --���̓p�����[�^7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6)   := 'PARAM8';                               --���̓p�����[�^8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6)   := 'PARAM9';                               --���̓p�����[�^9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7)   := 'PARAM10';                              --���̓p�����[�^10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7)   := 'PARAM11';                              --���̓p�����[�^11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7)   := 'PARAM12';                              --���̓p�����[�^12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7)   := 'PARAM13';                              --���̓p�����[�^13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7)   := 'PARAM14';                              --���̓p�����[�^14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7)   := 'PARAM15';                              --���̓p�����[�^15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7)   := 'PARAM16';                              --���̓p�����[�^16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7)   := 'PARAM17';                              --���̓p�����[�^17
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                            --�t�@�C����
  cv_tkn_prf                      CONSTANT VARCHAR2(7)   := 'PROFILE';                              --�v���t�@�C��
  cv_tkn_order_no                 CONSTANT VARCHAR2(5)   := 'ORDER';                                --�`�[�ԍ�
  cv_tkn_item                     CONSTANT VARCHAR2(20)  := 'ITEM';                                 --���ږ�
  cv_tkn_num_of_item              CONSTANT VARCHAR2(11)  := 'NUM_OF_ITEM';                          --���ڐ�
  cv_tkn_value                    CONSTANT VARCHAR2(30)  := 'VALUE';                                --�}��
  cv_tkn_key                      CONSTANT VARCHAR2(8)   := 'KEY_DATA';                             --�L�[���
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  cv_tkn_report_code           CONSTANT VARCHAR2(30)  := 'REPORT_CODE';                       --���[��ʃR�[�h
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --�Q�ƃ^�C�v
  ct_dept_mst                     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_MST';        --�Q�ƃ^�C�v.�S�ݓX�}�X�^
  ct_dept_slip_class              CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_SLIP_CLASS'; --�Q�ƃ^�C�v.�S�ݓX�`�[�敪
  ct_dept_buy_class               CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_BUY_CLASS';  --�Q�ƃ^�C�v.�S�ݓX��������ŏo�敪
  ct_dept_tax_class               CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_TAX_CLASS';  --�Q�ƃ^�C�v.�S�ݓX�Ŏ�敪
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  ct_report_forms_add_info        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_REPORT_FORMS_ADD_INFO'; --�Q�ƃ^�C�v.���[�l���t�����
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --�Œ�l
  cn_cnt_sep_koguchi              CONSTANT NUMBER        := 3;                                      --�������̃J���}��
  cn_max_row_invoice              CONSTANT NUMBER        := 8;                                      --1���̍ő匏��(�����)
  cn_max_row_supply               CONSTANT NUMBER        := 5;                                      --1���̍ő匏��(�d���`�[)
  cn_length_footer                CONSTANT NUMBER        := 32;                                     --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j�̍s���Ƃ̃o�C�g��
  cn_length_koguchi_itoen         CONSTANT NUMBER        := 4;                                      --���������v(�ɓ���)�̌���
  cn_length_koguchi_hashiba       CONSTANT NUMBER        := 4;                                      --���������v(����)�̌���
  cn_length_koguchi_total         CONSTANT NUMBER        := 4;                                      --�������̑����v�̌���
  cn_div_item                     CONSTANT NUMBER        := 14;                                     --���i���P�E�Q�̃o�C�g�����P��
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
  cn_length_dept_code             CONSTANT NUMBER        := 3;                                      --�p�����[�^.�S�ݓX�R�[�h�̌���
  cn_length_dept_store_code       CONSTANT NUMBER        := 3;                                      --�p�����[�^.�S�ݓX�X�܃R�[�h�̌���
  cn_length_edaban                CONSTANT NUMBER        := 5;                                      --�p�����[�^.�}�Ԃ̌���
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
--
  --�l�Z�b�g
  cv_department_a_ran_class0      CONSTANT VARCHAR2(1)   := '0';                                    --�S�ݓX�����A���敪�u�`�����v
  cv_department_a_ran_class1      CONSTANT VARCHAR2(1)   := '1';                                    --�S�ݓX�����A���敪�u�`�����v
  cv_department_a_ran_class2      CONSTANT VARCHAR2(1)   := '2';                                    --�S�ݓX�����A���敪�u�������ʁv
  cv_department_a_ran_class3      CONSTANT VARCHAR2(1)   := '3';                                    --�S�ݓX�����A���敪�u�c�����v
  cv_department_show_class0       CONSTANT VARCHAR2(1)   := '0';                                    --�S�ݓX�����\���敪�u�����\������v
  cv_department_show_class1       CONSTANT VARCHAR2(1)   := '1';                                    --�S�ݓX�����\���敪�u�����\�����Ȃ��v
--
  --���̑�
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                    --UTL_FILE.�I�[�v�����[�h
  cv_date_fmt                     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                             --���t����
  cv_time_fmt                     CONSTANT VARCHAR2(8)   := 'HH24MISS';                             --��������
  cv_cancel                       CONSTANT VARCHAR2(9)   := 'CANCELLED';                            --�X�e�[�^�X.���
  cv_entered                      CONSTANT VARCHAR2(7)   := 'ENTERED';                              --�X�e�[�^�X.���͍ς�
  cv_number00                     CONSTANT VARCHAR2(2)   := '00';                                   --�Œ�l00
  cv_number01                     CONSTANT VARCHAR2(2)   := '01';                                   --�Œ�l01
  cv_number14                     CONSTANT VARCHAR2(2)   := '14';                                   --�Œ�l14
  cv_number0                      CONSTANT VARCHAR2(1)   := '0';                                    --�Œ�l0
  cv_number1                      CONSTANT VARCHAR2(1)   := '1';                                    --�Œ�l1
  cv_number2                      CONSTANT VARCHAR2(1)   := '2';                                    --�Œ�l2
  cv_number3                      CONSTANT VARCHAR2(1)   := '3';                                    --�Œ�l3
  cv_cust_class_cust              CONSTANT VARCHAR2(2)   := '10';                                   --�ڋq�敪.�ڋq
  cv_cust_class_dept              CONSTANT VARCHAR2(2)   := '19';                                   --�ڋq�敪.�S�ݓX
  cv_enabled_flag                 CONSTANT VARCHAR2(1)   := 'Y';                                    --�g�p�\�t���O
  cv_default_language             CONSTANT VARCHAR2(10)  := USERENV('LANG');                        --�W������^�C�v
  cn_number0                      CONSTANT NUMBER        := 0;                                      --�Œ�l0
  cn_number1                      CONSTANT NUMBER        := 1;                                      --�Œ�l1
  cn_number4                      CONSTANT NUMBER        := 4;                                      --�Œ�l4
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[���R�[�h
  TYPE g_input_rtype IS RECORD (
    file_name                 VARCHAR2(100)                                      --IF�t�@�C����
   ,chain_code                xxcmm_cust_accounts.edi_chain_code%TYPE            --EDI�`�F�[���X�R�[�h
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod start
--   ,report_code               xxcos_report_forms_register.report_code%TYPE       --���[�R�[�h
   ,report_code               VARCHAR2(100)                                      --���[�R�[�h
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod end
   ,user_id                   NUMBER                                             --���[�UID
   ,dept_code                 xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --�S�ݓX�R�[�h
   ,dept_name                 hz_parties.party_name%TYPE                         --�S�ݓX��
   ,dept_store_code           xxcmm_cust_accounts.store_code%TYPE                --�S�ݓX�X�܃R�[�h
   ,edaban                    VARCHAR2(100)                                      --�}��
   ,base_code                 xxcmm_cust_accounts.delivery_base_code%TYPE        --�[�i���_�R�[�h
   ,base_name                 hz_parties.party_name%TYPE                         --�[�i���_��
   ,data_type_code            xxcos_report_forms_register.data_type_code%TYPE    --���[��ʃR�[�h
   ,ebs_business_series_code  VARCHAR2(100)                                      --EBS�Ɩ��n��R�[�h
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod start
--   ,report_name               xxcos_report_forms_register.report_name%TYPE       --���[�l��
   ,report_name               VARCHAR2(100)                                      --���[�l��
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod end
   ,shop_delivery_date_from   VARCHAR2(100)                                      --�X�ܔ[�i��(FROM)
   ,shop_delivery_date_to     VARCHAR2(100)                                      --�X�ܔ[�i��(TO)
   ,publish_div               VARCHAR2(100)                                      --�[�i�����s�敪
   ,publish_flag_seq          xxcos_report_forms_register.publish_flag_seq%TYPE  --�[�i�����s�t���O����
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
--    --�����L�[
   ,key_dept_code             xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --�S�ݓX�R�[�h(�����L�[)
   ,key_dept_store_code       xxcmm_cust_accounts.store_code%TYPE                --�S�ݓX�X�܃R�[�h(�����L�[)
   ,key_edaban                VARCHAR2(100)                                      --�}��(�����L�[)
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
  );
--
    --�S�ݓX�}�X�^���R�[�h�̒�`
  TYPE g_depart_rtype IS RECORD (
    account_number           xxcos_lookup_values_v.attribute1%TYPE               --�ڋq�R�[�h
   ,item_distinction_num     xxcos_lookup_values_v.attribute2%TYPE               --�i�ʔԍ�
   ,sales_place              xxcos_lookup_values_v.attribute3%TYPE               --���ꖼ
   ,delivery_place           xxcos_lookup_values_v.attribute4%TYPE               --�[�i�ꏊ
   ,display_place            xxcos_lookup_values_v.attribute5%TYPE               --�X�o�ꏊ
   ,slip_class               xxcos_lookup_values_v.attribute6%TYPE               --�`�[�敪
   ,a_column_class           xxcos_lookup_values_v.attribute7%TYPE               --A���敪
   ,a_column                 xxcos_lookup_values_v.attribute8%TYPE               --A��
   ,cost_indication_class    xxcos_lookup_values_v.attribute9%TYPE               --�\���敪
   ,buy_digestion_class      xxcos_lookup_values_v.attribute10%TYPE              --��������ŏo�敪
   ,tax_type_class           xxcos_lookup_values_v.attribute11%TYPE              --�Ŏ�敪
   ,slip_class_name          xxcos_lookup_values_v.meaning%TYPE                  --�`�[�敪����
   ,publish_class_invoice    xxcos_lookup_values_v.attribute1%TYPE               --����󔭍s�t���O
   ,publish_class_supply     xxcos_lookup_values_v.attribute2%TYPE               --�d���`�[���s�t���O
   ,buy_digestion_class_name xxcos_lookup_values_v.meaning%TYPE                  --��������ŏo�敪����
   ,tax_type_class_name      xxcos_lookup_values_v.meaning%TYPE                  --�Ŏ�敪����
   ,cust_account_id          hz_cust_accounts.cust_account_id%TYPE               --�ڋqID
  );
--
  --�v���t�@�C���l�i�[���R�[�h
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --�w�b�_���R�[�h���ʎq
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --�f�[�^���R�[�h���ʎq
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --�t�b�^���R�[�h���ʎq
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --�o�̓f�B���N�g��
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --��Ж�
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE�ő�s�T�C�Y
   ,phone_number             fnd_profile_option_values.profile_option_value%TYPE --�d�b�ԍ�
   ,post_code                fnd_profile_option_values.profile_option_value%TYPE --�X�֔ԍ�
   ,cmn_rep_chain_code       fnd_profile_option_values.profile_option_value%TYPE --���ʒ��[�l���p�`�F�[���X�R�[�h
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
  );
--
  --�ڋq�}�X�^�i�S�ݓX�j���i�[���R�[�h
  TYPE g_cust_dept_rtype IS RECORD (
    dept_cust_id             hz_cust_accounts.cust_account_id%TYPE              --�S�ݓX�ڋqID
   ,dept_name                hz_parties.party_name%TYPE                         --�S�ݓX��
   ,dept_shop_code           xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --�S�ݓX�`��R�[�h
  );
--
  --�ڋq�}�X�^�i�X�܁j���i�[���R�[�h
  TYPE g_cust_shop_rtype IS RECORD (
    store_code               xxcmm_cust_accounts.store_code%TYPE                --�X�܃R�[�h
   ,cust_store_name          xxcmm_cust_accounts.cust_store_name%TYPE           --�X�ܖ���
   ,torihikisaki_code        xxcmm_cust_accounts.torihikisaki_code%TYPE         --�����R�[�h
  );
--
  --���b�Z�[�W���i�[���R�[�h
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE                  --Online
   ,header_type01            fnd_new_messages.message_text%TYPE                  --01_�S�ݓX��
   ,header_type02            fnd_new_messages.message_text%TYPE                  --04_�S�ݓX���{
   ,line_type_dept           fnd_new_messages.message_text%TYPE                  --10_�S�ݓX
   ,line_type_sample         fnd_new_messages.message_text%TYPE                  --50_�S�ݓX���{
  );
--
  --�W�v���i�[���R�[�h
  TYPE g_summary_rtype IS RECORD (
    total_itoen_can           NUMBER    --�ɓ�����
   ,total_itoen_dg            NUMBER    --�ɓ���DG
   ,total_itoen_g             NUMBER    --�ɓ���G
   ,total_itoen_hoka          NUMBER    --�ɓ�����
   ,total_hashiba_can         NUMBER    --�����
   ,total_hashiba_dg          NUMBER    --����DG
   ,total_hashiba_g           NUMBER    --����G
   ,total_hashiba_hoka        NUMBER    --���ꑼ
   ,total_sum_order_qty       NUMBER    --�������ʁi���v�A�o���j
   ,total_shipping_cost_amt   NUMBER    --�������z�i�o�ׁj
   ,total_shipping_price_amt  NUMBER    --�������z�i�o�ׁj
  );
--
  --���̑����i�[���R�[�h
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --������
   ,proc_time                VARCHAR2(6)                                         --��������
   ,csv_header               VARCHAR2(32767)                                     --CSV�w�b�_
   ,process_date             DATE                                                --�Ɩ����t
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                                 --�_�u���N�H�[�e�[�V����
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                                 --�J���}
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable; --�ϒ�
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order; --�󒍌n
  cv_not_issued              CONSTANT VARCHAR2(1) := 'N';                                     --�����s
  cv_publish                 CONSTANT VARCHAR2(1) := 'Y';                                     --���s��
  cv_found                   CONSTANT VARCHAR2(1) := '0';                                     --�o�^
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                                     --���o�^
  cv_divchr_filename         CONSTANT VARCHAR2(1) := ' ';                                     --�t�@�C�����̋�؂蕶��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_invoice_count           NUMBER;                                             --�����f�[�^���R�[�h����
  gn_supply_count            NUMBER;                                             --�d���`�[�f�[�^���R�[�h����
  gf_file_handle_invoice     UTL_FILE.FILE_TYPE;                                 --�t�@�C���n���h���i�����j
  gf_file_handle_supply      UTL_FILE.FILE_TYPE;                                 --�t�@�C���n���h���i�d���`�[�j
  gb_invoice                 BOOLEAN;                                            --����󔭍s�t���O
  gb_supply                  BOOLEAN;                                            --�d���`�[���s�t���O
  gv_filename1               VARCHAR2(100);                                      --�t�@�C����1
  gv_filename2               VARCHAR2(100);                                      --�t�@�C����2
  gv_invoice_file            VARCHAR2(100);                                      --�����t�@�C����
  gv_supply_file             VARCHAR2(100);                                      --�d���`�[�t�@�C����
  gt_invoice_flag            xxcos_lookup_values_v.attribute1%TYPE;              --�����o�̓t���O
  gt_supply_flag             xxcos_lookup_values_v.attribute2%TYPE;              --�d���`�[�o�̓t���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_mlt_tab       IS TABLE OF xxcos_common2_pkg.g_layout_ttype    INDEX BY BINARY_INTEGER;   --�o�̓f�[�^���
--
  -- ===============================
  -- ���[�U�[��`PL/SQL�\
  -- ===============================
  g_input_rec                g_input_rtype;                                      --���̓p�����[�^���
  g_prf_rec                  g_prf_rtype;                                        --�v���t�@�C�����
  g_depart_rec               g_depart_rtype;                                     --�S�ݓX�}�X�^���
  g_cust_dept_rec            g_cust_dept_rtype;                                  --�ڋq�}�X�^�i�S�ݓX�j���
  g_cust_shop_rec            g_cust_shop_rtype;                                  --�ڋq�}�X�^�i�X�܁j���
  g_msg_rec                  g_msg_rtype;                                        --���b�Z�[�W���
  g_other_rec                g_other_rtype;                                      --���̑����
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --���C�A�E�g��`���
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := FALSE;
  BEGIN
/*
    IF (lv_debug) THEN
      dbms_output.put_line(buff);
    ELSE
      FND_FILE.PUT_LINE(
         which  => which
        ,buff   => buff
      );
    END IF;
*/
    NULL;
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���ʏ�������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    out_line(buff => cv_prg_name || ' start');
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
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    -- �R���J�����g�v���O�������͍��ڂ̏o��
    --==============================================================
    --���̓p�����[�^1-10�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name , ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.dept_code
                                          ,cv_tkn_prm6 , g_input_rec.dept_name
                                          ,cv_tkn_prm7 , g_input_rec.dept_store_code
                                          ,cv_tkn_prm8 , g_input_rec.edaban
                                          ,cv_tkn_prm9 , g_input_rec.base_code
                                          ,cv_tkn_prm10 ,g_input_rec.base_name
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --���̓p�����[�^11-17�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,  ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.data_type_code
                                          ,cv_tkn_prm12, g_input_rec.ebs_business_series_code
                                          ,cv_tkn_prm13, g_input_rec.report_name
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm15, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm16, g_input_rec.publish_div
                                          ,cv_tkn_prm17, g_input_rec.publish_flag_seq
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- �o�̓t�@�C�����̏o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    cv_apl_name
                   ,ct_msg_file_name
                   ,cv_tkn_filename
                   ,g_input_rec.file_name
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      out_line(buff => cv_prg_name || ct_msg_part || sqlerrm);
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2        --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2        --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2        --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
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
    lb_error                                 BOOLEAN;                                               --�G���[�L��t���O
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --���b�Z�[�W�p������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_depart_rec        g_depart_rtype;
    l_prf_rec           g_prf_rtype;
    l_other_rec         g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�G���[�t���O������
    lb_error := FALSE;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�w�b�_���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_header := FND_PROFILE.VALUE(ct_prf_if_header);
    IF (l_prf_rec.if_header IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(	
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--	
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�f�[�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCCP:�t�b�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:���[OUTBOUND�o�̓f�B���N�g��)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:��Ж�)
    --==============================================================
    l_prf_rec.company_name := FND_PROFILE.VALUE(ct_prf_company_name);
    IF (l_prf_rec.company_name IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:UTL_MAX�s�T�C�Y)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    --���C�A�E�g��`���̎擾
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      cv_file_format                              --�t�@�C���`��
     ,cv_layout_class                             --���C�A�E�g�敪
     ,l_record_layout_tab                         --���C�A�E�g��`���
     ,l_other_rec.csv_header                      --CSV�w�b�_
     ,lv_errbuf                                   --�G���[���b�Z�[�W
     ,lv_retcode                                  --���^�[���R�[�h
     ,lv_errmsg                                   --���[�U�E�G���[���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �������t�A���������̎擾
    --==============================================================
    l_other_rec.proc_date    := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time    := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date); --�Ɩ����t
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�d�b�ԍ�)
    --==============================================================
    l_prf_rec.phone_number := FND_PROFILE.VALUE(ct_prf_phone_number);
    IF (l_prf_rec.phone_number IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_phone_number);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�X�֔ԍ�)
    --==============================================================
    l_prf_rec.post_code := FND_PROFILE.VALUE(ct_prf_post_code);
    IF (l_prf_rec.post_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_post_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( g_input_rec.chain_code  IS NULL )
      THEN
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:���ʒ��[�l���p�`�F�[���X�R�[�h)
    --==============================================================
        l_prf_rec.cmn_rep_chain_code := FND_PROFILE.VALUE(ct_prf_cmn_rep_chain_code);
        IF (l_prf_rec.cmn_rep_chain_code IS NULL) THEN
          lb_error := TRUE;
          lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cmn_rep_chain_code);
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_prf
                        ,cv_tkn_prf
                        ,lt_tkn
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�̎擾
    --==============================================================
    --�ڋq�}�X�^���o�^���b�Z�[�W�擾
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cust_master);
    g_msg_rec.customer_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --�i�ڃ}�X�^���o�^���b�Z�[�W�擾
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_item_master);
    g_msg_rec.item_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --==============================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    --==============================================================
    l_prf_rec.org_id := FND_PROFILE.VALUE(ct_prf_org_id);
    IF (l_prf_rec.org_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_mo_org_id);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    -- =========================================================
    -- �v���t�@�C���uXXCOS:�S�ݓX���́v�擾
    -- =========================================================
    IF ( g_input_rec.dept_name IS NULL ) THEN
      g_input_rec.dept_name := FND_PROFILE.VALUE( cv_tkn_xxcos1_dept_target_all );
--
      IF ( g_input_rec.dept_name IS NULL ) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_dept_target_all );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_prf
                      ,cv_tkn_prf
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
    END IF;
--
    -- =========================================================
    -- �o�͑Ώے��[�t���O�擾
    -- =========================================================
    BEGIN
      SELECT   rfai.attribute1  invoice_flag  -- �����o�̓t���O
              ,rfai.attribute2  supply_flag   -- �d���`�[�o�̓t���O
      INTO     gt_invoice_flag
              ,gt_supply_flag
      FROM    xxcos_lookup_values_v  rfai
      WHERE   rfai.lookup_type = ct_report_forms_add_info
      AND     rfai.lookup_code = g_input_rec.report_code
      ;
--    --==============================================================
--    --�S�ݓX�}�X�^���擾
--    --==============================================================
--    BEGIN
--      SELECT   xdm.attribute1                     account_number                --�ڋq�R�[�h
--              ,xdm.attribute2                     item_distinction_num          --�i�ʔԍ�
--              ,xdm.attribute3                     sales_place                   --����
--              ,xdm.attribute4                     delivery_place                --�[�i�ꏊ
--              ,xdm.attribute5                     display_place                 --�X�o�ꏊ
--              ,xdm.attribute6                     slip_class                    --�`�[�敪
--              ,xdm.attribute7                     a_column_class                --A���敪
--              ,xdm.attribute8                     a_column                      --A��
--              ,xdm.attribute9                     cost_indication_class         --�\���敪
--              ,xdm.attribute10                    buy_digestion_class           --��������ŏo�敪
--              ,xdm.attribute11                    tax_type_class                --�Ŏ�敪
--              ,xdsc.meaning                       slip_class_name               --�`�[�敪����
--              ,xdsc.attribute1                    publish_class_invoice         --����󔭍s�t���O
--              ,xdsc.attribute2                    publish_class_supply          --�d���`�[���s�t���O
--              ,xdbc.meaning                       buy_digestion_class_name      --��������ŏo�敪����
--              ,xdtc.meaning                       tax_type_class_name           --�Ŏ�敪����
--      INTO     l_depart_rec.account_number
--              ,l_depart_rec.item_distinction_num
--              ,l_depart_rec.sales_place
--              ,l_depart_rec.delivery_place
--              ,l_depart_rec.display_place
--              ,l_depart_rec.slip_class
--              ,l_depart_rec.a_column_class
--              ,l_depart_rec.a_column
--              ,l_depart_rec.cost_indication_class
--              ,l_depart_rec.buy_digestion_class
--              ,l_depart_rec.tax_type_class
--              ,l_depart_rec.slip_class_name
--              ,l_depart_rec.publish_class_invoice
--              ,l_depart_rec.publish_class_supply
--              ,l_depart_rec.buy_digestion_class_name
--              ,l_depart_rec.tax_type_class_name
--      FROM     xxcos_lookup_values_v              xdm                           --�S�ݓX�}�X�^
--              ,xxcos_lookup_values_v              xdsc                          --�S�ݓX�`�[�敪
--              ,xxcos_lookup_values_v              xdbc                          --��������ŏo�敪
--              ,xxcos_lookup_values_v              xdtc                          --�Ŏ�敪
--      --�S�ݓX�}�X�^���o����
--      WHERE    xdm.lookup_type  = ct_dept_mst                                   --�Q�ƃ^�C�v.�S�ݓX�}�X�^
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod start
----      AND      xdm.lookup_code = g_input_rec.dept_code || g_input_rec.dept_store_code || g_input_rec.edaban
--      AND      xdm.lookup_code = g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod end
--      AND      xxccp_common_pkg2.get_process_date
--               BETWEEN xdm.start_date_active
--               AND     NVL(xdm.end_date_active,xxccp_common_pkg2.get_process_date)
--      --�S�ݓX�`�[�敪���o����
--      AND   xdsc.lookup_type    = ct_dept_slip_class                            --�Q�ƃ^�C�v.�S�ݓX�`�[�敪
--      AND   xdsc.lookup_code    = xdm.attribute6
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdsc.start_date_active
--        AND     NVL(xdsc.end_date_active,xxccp_common_pkg2.get_process_date)
--      --��������ŏo�敪���o����
--      AND   xdbc.lookup_type    = ct_dept_buy_class                             --�Q�ƃ^�C�v.��������ŏo�敪
--      AND   xdbc.lookup_code    = xdm.attribute10
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdbc.start_date_active
--        AND     NVL(xdbc.end_date_active,xxccp_common_pkg2.get_process_date)
--      --�Ŏ�敪���̒��o����
--      AND   xdtc.lookup_type    = ct_dept_tax_class                             --�Q�ƃ^�C�v.�Ŏ�敪
--      AND   xdtc.lookup_code    = xdm.attribute11
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdtc.start_date_active
--        AND     NVL(xdtc.end_date_active,xxccp_common_pkg2.get_process_date)
--      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lb_error  := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_rep_form_add_info_err
                    ,cv_tkn_report_code
                    ,g_input_rec.report_code
                    );
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                     cv_apl_name
--                    ,ct_msg_dept_mst_notfound
--                    ,cv_tkn_value
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod start
----                    ,g_input_rec.dept_code || g_input_rec.dept_store_code || g_input_rec.edaban
--                    ,g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod end
--                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END;
----
--    --==============================================================
--    --�ڋqID�擾
--    --==============================================================
--    BEGIN
--      SELECT   hca.cust_account_id                cust_account_id               --�ڋqID
--      INTO     l_depart_rec.cust_account_id
--      FROM     hz_cust_accounts                   hca                           --�ڋq�}�X�^
--      WHERE    hca.account_number = l_depart_rec.account_number                 --�ڋq�R�[�h
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lb_error  := TRUE;
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                     cv_apl_name
--                    ,ct_msg_cust_notfound
--                    ,cv_tkn_value
--                    ,l_depart_rec.account_number
--                   );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg
--      );
--    END;
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
--
      --���[�l���t�����.����󔭍s�t���O��'Y'�̏ꍇ�A
      IF (gt_invoice_flag = cv_enabled_flag ) THEN
        gb_invoice := TRUE;
      ELSE
        gb_invoice := FALSE;
      END IF;
--
      --���[�l���t�����.����󔭍s�t���O��'Y'�łȂ����d���`�[���s�t���O��'Y'�̏ꍇ
      IF (gt_invoice_flag <> cv_enabled_flag ) AND ( gt_supply_flag = cv_enabled_flag ) THEN
        gb_supply := TRUE;
      ELSE
        gb_supply := FALSE;
      END IF;
--
--    --�S�ݓX�}�X�^.����󔭍s�t���O��'Y'�̏ꍇ�A�����
--    IF l_depart_rec.publish_class_invoice = cv_enabled_flag THEN
--      gb_invoice := TRUE;
--    ELSE
--      gb_invoice := FALSE;
--    END IF;
----
--    --�S�ݓX�}�X�^.�d���`�[���s�t���O��'Y'�̏ꍇ�A�d���`�[
--    IF l_depart_rec.publish_class_supply = cv_enabled_flag THEN
--      gb_supply := TRUE;
--    ELSE
--      gb_supply := FALSE;
--    END IF;
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
--
    --==============================================================
    --�O���[�o���ϐ��̃Z�b�g
    --==============================================================
-- ************ 2009/09/07 1.4 N.Maeda DEL START *********** --
--    g_depart_rec        := l_depart_rec;
-- ************ 2009/09/07 1.4 N.Maeda DEL  END  *********** --
    g_prf_rec           := l_prf_rec;
    g_other_rec         := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_header_record
   * Description      : �w�b�_���R�[�h�쐬����(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT VARCHAR2      --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_header_record'; -- �v���O������
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
    lv_if_header                       VARCHAR2(32767);
    ln_sep_position                    NUMBER;  --���p�X�y�[�X�̈ʒu
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    --��؂蕶��(���p�X�y�[�X)�̈ʒu���擾
    ln_sep_position := INSTRB( g_input_rec.file_name, cv_divchr_filename, cn_number1, cn_number1 );
--
    --��؂蕶��������ꍇ(�t�@�C�����Q��)
    IF ( ln_sep_position > 0 ) THEN
      --�t�@�C�����̐؂�o��(���p�X�y�[�X�łQ�ɋ�؂�)
      gv_filename1 := SUBSTRB( g_input_rec.file_name
                              ,cv_number1
                              ,INSTRB( g_input_rec.file_name, ' ', cn_number1, cn_number1 ) - cn_number1 );
      gv_filename2 := SUBSTRB( g_input_rec.file_name                                          
                              ,INSTRB( g_input_rec.file_name, ' ', cn_number1, cn_number1 ) + cn_number1 );
--
    --��؂蕶�����Ȃ��ꍇ(�t�@�C�����P��)
    ELSE
      --�p�����[�^�����̂܂܃t�@�C�����Ƃ���
      gv_filename1 := g_input_rec.file_name;
    END IF;
--
    --�t�@�C�����̊��蓖��
    -- ����󔭍s�t���O��"Y"�̏ꍇ
    IF gb_invoice THEN
      gv_invoice_file := gv_filename1;  -- �t�@�C����1�𑗂��t�@�C�����Ƃ���
      -- �d���`�[���s�t���O��"Y"�̏ꍇ
      IF gb_supply THEN
        gv_supply_file := gv_filename2;   -- �t�@�C����2���d���`�[�t�@�C�����Ƃ���
      END IF;
--
    -- ����󔭍s�t���O��"N"�̏ꍇ
    ELSE
      -- �d���`�[���s�t���O��"Y"�̏ꍇ
      IF gb_supply THEN
        gv_supply_file := gv_filename1;   -- �t�@�C����1���d���`�[�t�@�C�����Ƃ���
      END IF;
    END IF;
--
    BEGIN
      --
      IF gb_invoice THEN
        --�����t�@�C�����I�[�v��
        gf_file_handle_invoice := UTL_FILE.FOPEN(
                                    g_prf_rec.rep_outbound_dir
                                   ,gv_invoice_file
                                   ,cv_utl_file_mode
                                   ,g_prf_rec.utl_max_linesize
                                  );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,gv_invoice_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    BEGIN
      --
      IF gb_supply THEN
        --�d���`�[�t�@�C�����I�[�v��
        gf_file_handle_supply  := UTL_FILE.FOPEN(
                                    g_prf_rec.rep_outbound_dir
                                   ,gv_supply_file
                                   ,cv_utl_file_mode
                                   ,g_prf_rec.utl_max_linesize
                                  );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,gv_supply_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �w�b�_���R�[�h�ݒ�l�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --�t�^�敪
     ,g_input_rec.ebs_business_series_code        --�h�e���Ɩ��n��R�[�h
     ,g_input_rec.base_code                       --���_�R�[�h
     ,g_input_rec.base_name                       --���_����
     ,g_input_rec.chain_code                      --�`�F�[���X�R�[�h
     ,g_input_rec.dept_name                       --�S�ݓX��
     ,g_input_rec.data_type_code                  --�f�[�^��R�[�h
     ,g_input_rec.report_code                     --���[�R�[�h
     ,g_input_rec.report_name                     --���[�\����
     ,g_record_layout_tab.COUNT                   --���ڐ�
     ,NULL                                        --�f�[�^����
     ,lv_retcode                                  --���^�[���R�[�h
     ,lv_if_header                                --�o�͒l
     ,lv_errbuf                                   --�G���[���b�Z�[�W
     ,lv_errmsg                                   --���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    out_line(buff => 'if_header:' || lv_if_header);
    --==============================================================
    -- �w�b�_���R�[�h�o��
    --==============================================================
    --
    IF gb_invoice THEN
      UTL_FILE.PUT_LINE( gf_file_handle_invoice, lv_if_header );
    END IF;
--
    IF gb_supply THEN
      UTL_FILE.PUT_LINE( gf_file_handle_supply , lv_if_header );
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      : CSV�w�b�_���R�[�h�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_csv_header'; -- �v���O������
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
   lv_csv_header VARCHAR2(32767);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --CSV�w�b�_���R�[�h�̐擪�Ƀf�[�^���R�[�h���ʎq��t��
    lv_csv_header := cv_siege || g_prf_rec.if_data || cv_siege || cv_delimiter ||
                     g_other_rec.csv_header;
--
    --CSV�w�b�_���R�[�h�̏o��
    --�����
    IF gb_invoice THEN
      UTL_FILE.PUT_LINE(gf_file_handle_invoice, g_other_rec.csv_header);
    END IF;
    --�d���`�[
    IF gb_supply THEN
      UTL_FILE.PUT_LINE(gf_file_handle_supply, g_other_rec.csv_header);
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_data_record
   * Description      : �f�[�^���R�[�h�쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_out_data_record(
    in_type         IN      NUMBER              --�o�͎��(0:�����A1:�d���`�[)
   ,io_mlt_tab      IN OUT  g_mlt_tab           --�o�̓f�[�^���
   ,io_summary_rec  IN OUT  g_summary_rtype     --�W�v���
   ,ov_errbuf       OUT     VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT     VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT     VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_data_record'; -- �v���O������
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
    lv_data_record                     VARCHAR2(32767);
    lv_table_name                      all_tables.table_name%TYPE;
    ln_page_top                        NUMBER;                                    --�e�y�[�W�擪�̔ԍ�
    ln_mtl_idx                         NUMBER;                                    --�o�̓f�[�^���C���f�b�N�X
    --���������v
    ln_total_can                       NUMBER;                                    --�������̍��v(��)
    ln_total_dg                        NUMBER;                                    --�������̍��v(DG)
    ln_total_g                         NUMBER;                                    --�������̍��v(G)
    ln_total_hoka                      NUMBER;                                    --�������̍��v(��)
    ln_total_koguchi                   NUMBER;                                    --�������̑����v
    --���������v(�ҏW�p������)
    lv_total_itoen_can                 VARCHAR2(200);                             --�ɓ�����
    lv_total_itoen_dg                  VARCHAR2(200);                             --�ɓ���DG
    lv_total_itoen_g                   VARCHAR2(200);                             --�ɓ���G
    lv_total_itoen_hoka                VARCHAR2(200);                             --�ɓ�����
    lv_total_hashiba_can               VARCHAR2(200);                             --�����
    lv_total_hashiba_dg                VARCHAR2(200);                             --����DG
    lv_total_hashiba_g                 VARCHAR2(200);                             --����G
    lv_total_hashiba_hoka              VARCHAR2(200);                             --���ꑼ
    lv_total_can                       VARCHAR2(200);                             --�������̍��v(��)
    lv_total_dg                        VARCHAR2(200);                             --�������̍��v(DG)
    lv_total_g                         VARCHAR2(200);                             --�������̍��v(G)
    lv_total_hoka                      VARCHAR2(200);                             --�������̍��v(��)
    --���������v(�o�͕�����)
    lv_output_can                      VARCHAR2(200);                             --�������̍��v(��)
    lv_output_dg                       VARCHAR2(200);                             --�������̍��v(DG)
    lv_output_g                        VARCHAR2(200);                             --�������̍��v(G)
    lv_output_hoka                     VARCHAR2(200);                             --�������̍��v(��)
    lv_output_koguchi                  VARCHAR2(200);                             --�������̑����v--�t�@�C���o�͗p
    --�W�v�p
    ln_page_count_invoice              NUMBER;                                    --�����̖���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    --0��NULL�ւ̕ϊ�
    FUNCTION chg_zero_to_null(
      in_value  IN NUMBER
    )
    RETURN NUMBER IS
--
    BEGIN
      IF ( in_value = 0 ) THEN
        --�p�����[�^��0�̏ꍇ��NULL��Ԃ�
        RETURN NULL;
      ELSE
        --�p�����[�^��0�ȊO�̏ꍇ�͌��̒l�����̂܂ܕԂ�
        RETURN in_value;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN in_value;
    END;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�o�̓f�[�^��񃏁[�N�̃��[�v����
    --==============================================================
    <<tbl_invoice_loop>>
    FOR ln_mtl_idx IN io_mlt_tab.FIRST..io_mlt_tab.LAST LOOP
--
      --==============================================================
      --�����̏o�͏���
      --==============================================================
      IF ( in_type = 0 ) THEN
--
        --�e�y�[�W�̐擪�̔ԍ����擾
        ln_page_top := TRUNC( ( ln_mtl_idx - 1 ) / cn_max_row_invoice, 0 ) * cn_max_row_invoice + 1;
        --�󒍔ԍ��̓y�[�W���Ƃ̐擪���R�[�h�̒l�ɏ���������i�d���`�[�Ȃ��̏ꍇ�͕ω��Ȃ��j
        io_mlt_tab( ln_mtl_idx )('ORDER_NO_EBS') := io_mlt_tab( ln_page_top )('ORDER_NO_EBS');
--
        --�������̊e���v���Z�o
          --�������̍��v(��) = �ɓ����� + �����
        ln_total_can   := io_summary_rec.total_itoen_can  + io_summary_rec.total_hashiba_can;
          --�������̍��v(DG) = �ɓ���DG + ����DG
        ln_total_dg    := io_summary_rec.total_itoen_dg   + io_summary_rec.total_hashiba_dg;
          --�������̍��v(G)  = �ɓ���G  + ����G
        ln_total_g     := io_summary_rec.total_itoen_g    + io_summary_rec.total_hashiba_g;
          --�������̍��v(��) = �ɓ����� + ���ꑼ
        ln_total_hoka  := io_summary_rec.total_itoen_hoka + io_summary_rec.total_hashiba_hoka;
--
        --�������̑����v���Z�o
        ln_total_koguchi := ln_total_can      --�������̍��v(��)
                          + ln_total_dg       --�������̍��v(DG)
                          + ln_total_g        --�������̍��v(G)
                          + ln_total_hoka     --�������̍��v(��)
        ;
--
        --�����̖������Z�o�i�W���^���j
        ln_page_count_invoice := TRUNC( ( io_mlt_tab.COUNT - 1 ) / cn_max_row_invoice, 0 ) + 1;
--
        --==============================================================
        --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j�֏o�͂��镶����̕ҏW
        --==============================================================
        --�Q�y�[�W�ځi�X���ڈȍ~�j�ɏo�͂��Ȃ��l���N���A����
        IF ( ln_mtl_idx > cn_max_row_invoice ) THEN
          --���������v
          io_summary_rec.total_itoen_can    := NULL;  --�ɓ�����
          io_summary_rec.total_itoen_dg     := NULL;  --�ɓ���DG
          io_summary_rec.total_itoen_g      := NULL;  --�ɓ���G
          io_summary_rec.total_itoen_hoka   := NULL;  --�ɓ�����
          io_summary_rec.total_hashiba_can  := NULL;  --�����
          io_summary_rec.total_hashiba_dg   := NULL;  --����DG
          io_summary_rec.total_hashiba_g    := NULL;  --����G
          io_summary_rec.total_hashiba_hoka := NULL;  --���ꑼ
          ln_total_can                      := NULL;  --�������̍��v(��)
          ln_total_dg                       := NULL;  --�������̍��v(DG)
          ln_total_g                        := NULL;  --�������̍��v(G)
          ln_total_hoka                     := NULL;  --�������̍��v(��)
          --�����̖���
          ln_page_count_invoice             := NULL;
          --�������̑����v
          ln_total_koguchi                  := NULL;
        END IF;
--
        --������ϐ��֊i�[�i�����������v�̊e���ڂ��O�̏ꍇ�͏o�͂��Ȃ����߁ANULL�ɒu��������j
        lv_total_itoen_can    := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_can    ) );  --�ɓ�����
        lv_total_itoen_dg     := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_dg     ) );  --�ɓ���DG
        lv_total_itoen_g      := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_g      ) );  --�ɓ���G
        lv_total_itoen_hoka   := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_hoka   ) );  --�ɓ�����
        lv_total_hashiba_can  := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_can  ) );  --�����
        lv_total_hashiba_dg   := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_dg   ) );  --����DG
        lv_total_hashiba_g    := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_g    ) );  --����G
        lv_total_hashiba_hoka := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_hoka ) );  --���ꑼ
        lv_total_can          := TO_CHAR( chg_zero_to_null( ln_total_can                      ) );  --�������̍��v(��)
        lv_total_dg           := TO_CHAR( chg_zero_to_null( ln_total_dg                       ) );  --�������̍��v(DG)
        lv_total_g            := TO_CHAR( chg_zero_to_null( ln_total_g                        ) );  --�������̍��v(G)
        lv_total_hoka         := TO_CHAR( chg_zero_to_null( ln_total_hoka                     ) );  --�������̍��v(��)
--
          -- �������̌�����
        lv_total_itoen_can    := LPAD( NVL( lv_total_itoen_can   , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_dg     := LPAD( NVL( lv_total_itoen_dg    , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_g      := LPAD( NVL( lv_total_itoen_g     , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_hoka   := LPAD( NVL( lv_total_itoen_hoka  , ' ' ), cn_length_koguchi_itoen   );
        lv_total_hashiba_can  := LPAD( NVL( lv_total_hashiba_can , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_dg   := LPAD( NVL( lv_total_hashiba_dg  , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_g    := LPAD( NVL( lv_total_hashiba_g   , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_hoka := LPAD( NVL( lv_total_hashiba_hoka, ' ' ), cn_length_koguchi_hashiba );
        lv_total_can          := LPAD( NVL( lv_total_can         , ' ' ), cn_length_koguchi_total   );
        lv_total_dg           := LPAD( NVL( lv_total_dg          , ' ' ), cn_length_koguchi_total   );
        lv_total_g            := LPAD( NVL( lv_total_g           , ' ' ), cn_length_koguchi_total   );
        lv_total_hoka         := LPAD( NVL( lv_total_hoka        , ' ' ), cn_length_koguchi_total   );
          -- ��
        lv_output_can  := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_can
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_can
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_can
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_can
        );
          -- DG
        lv_output_dg   := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_dg
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_dg
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_dg
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_dg
        );
          -- G
        lv_output_g    := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_g
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_g
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_g
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_g
        );
          -- ��
        lv_output_hoka := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_hoka
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_hoka
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_hoka
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_hoka
        );
          -- �o�͕�����ҏW
        lv_output_koguchi := RPAD( g_depart_rec.buy_digestion_class_name, cn_length_footer );   --�d���`��
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_can , cn_length_footer );     --�������̍��v(��)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_dg  , cn_length_footer );     --�������̍��v(DG)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_g   , cn_length_footer );     --�������̍��v(G)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_hoka, cn_length_footer );     --�������̍��v(��)
        lv_output_koguchi := lv_output_koguchi || RPAD( ' '           , cn_length_footer );     --�󔒍s(32�o�C�g)
--
        --==============================================================
        --PL/SQL�\(�����)�D�t�b�^���ւ̊i�[
        --==============================================================
            ------------------------------------------------�t�b�^���------------------------------------------------
        io_mlt_tab( ln_mtl_idx )('TOTAL_CASE_QTY')             := ln_total_koguchi;         --�i�����v�j�P�[�X����
        io_mlt_tab( ln_mtl_idx )('TOTAL_INVOICE_QTY')          := ln_page_count_invoice;    --�g�[�^���`�[����
        io_mlt_tab( ln_mtl_idx )('CHAIN_PECULIAR_AREA_FOOTER') := lv_output_koguchi;        --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
--
      --==============================================================
      --�d���`�[�̏o�͏���
      --==============================================================
      ELSE
        --�e�y�[�W�̂Q�s�ڈȍ~�ɏo�͂��Ȃ��l���N���A����
        IF ( MOD( ln_mtl_idx, cn_max_row_invoice ) <> 1 ) THEN
          io_mlt_tab( ln_mtl_idx )('A_COLUMN_HEADER')          := NULL;   --�`���w�b�_
          io_mlt_tab( ln_mtl_idx )('D_COLUMN_HEADER')          := NULL;   --�c���w�b�_
          io_mlt_tab( ln_mtl_idx )('A_COLUMN_DEPARTMENT')      := NULL;   --�`���i�S�ݓX�j
          io_mlt_tab( ln_mtl_idx )('GENERAL_ADD_ITEM1')        := NULL;   --�ėp�t�����ڂP
        END IF;
--
        --==============================================================
        --PL/SQL�\(�d���`�[)�D�t�b�^���ւ̊i�[
        --==============================================================
            ------------------------------------------------�t�b�^���------------------------------------------------
        --�i�`�[�v�j�������ʁi���v�A�o���j
        io_mlt_tab(ln_mtl_idx)('INVOICE_SUM_ORDER_QTY')      := io_summary_rec.total_sum_order_qty;
        --�i�`�[�v�j�������z�i�o�ׁj
        io_mlt_tab(ln_mtl_idx)('INVOICE_SHIPPING_COST_AMT')  := io_summary_rec.total_shipping_cost_amt;
        --�i�`�[�v�j�������z�i�o�ׁj
        io_mlt_tab(ln_mtl_idx)('INVOICE_SHIPPING_PRICE_AMT') := io_summary_rec.total_shipping_price_amt;
--
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�ҏW(A-5.6)
      --==============================================================
      xxcos_common2_pkg.makeup_data_record(
        io_mlt_tab( ln_mtl_idx )  --�o�̓f�[�^���
       ,cv_file_format            --�t�@�C���`��
       ,g_record_layout_tab       --���C�A�E�g��`���
       ,g_prf_rec.if_data         --�f�[�^���R�[�h���ʎq
       ,lv_data_record            --�f�[�^���R�[�h
       ,lv_errbuf                 --�G���[���b�Z�[�W
       ,lv_retcode                --���^�[���R�[�h
       ,lv_errmsg                 --���[�U�E�G���[���b�Z�[�W
      );
--
      --==============================================================
      --�f�[�^���R�[�h�o��(A-5.7,8)
      --==============================================================
      --�����
      IF ( in_type = 0 ) THEN
        --�t�@�C���ւ̏o��
        UTL_FILE.PUT_LINE( gf_file_handle_invoice, lv_data_record );
        --�f�[�^���R�[�h���������Z
        gn_invoice_count := gn_invoice_count + 1;
      --�d���`�[
      ELSE
        --�t�@�C���ւ̏o��
        UTL_FILE.PUT_LINE( gf_file_handle_supply , lv_data_record );
        --�f�[�^���R�[�h���������Z
        gn_supply_count := gn_supply_count + 1;
      END IF;
--
    END LOOP tbl_invoice_loop;
--
    --�o�̓f�[�^���̏�����
    io_mlt_tab.DELETE;
--
    --==============================================================
    --�W�v���̏�����
    --==============================================================
    --�����
    IF ( in_type = 0 ) THEN
      --���������v
      io_summary_rec.total_itoen_can           := 0;  --�ɓ�����
      io_summary_rec.total_itoen_dg            := 0;  --�ɓ���DG
      io_summary_rec.total_itoen_g             := 0;  --�ɓ���G
      io_summary_rec.total_itoen_hoka          := 0;  --�ɓ�����
      io_summary_rec.total_hashiba_can         := 0;  --�����
      io_summary_rec.total_hashiba_dg          := 0;  --����DG
      io_summary_rec.total_hashiba_g           := 0;  --����G
      io_summary_rec.total_hashiba_hoka        := 0;  --���ꑼ
      ln_total_can                             := 0;  --�������̍��v(��)
      ln_total_dg                              := 0;  --�������̍��v(DG)
      ln_total_g                               := 0;  --�������̍��v(G)
      ln_total_hoka                            := 0;  --�������̍��v(��)
      --�����̖���
      ln_page_count_invoice                    := 0;
      --�������̑����v
      ln_total_koguchi                         := 0;
--
    --�d���`�[
    ELSE
      io_summary_rec.total_sum_order_qty       := 0;  --�i�`�[�v�j�������ʁi���v�A�o���j
      io_summary_rec.total_shipping_cost_amt   := 0;  --�i�`�[�v�j�������z�i�o�ׁj
      io_summary_rec.total_shipping_price_amt  := 0;  --�i�`�[�v�j�������z�i�o�ׁj
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : �t�b�^���R�[�h�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_footer_record'; -- �v���O������
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
    lv_footer_record VARCHAR2(32767);
    ln_rec_cnt       NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�����
    IF gb_invoice THEN
      --==============================================================
      --�t�b�^���R�[�h�擾
      --==============================================================
      xxccp_ifcommon_pkg.add_chohyo_header_footer(
        g_prf_rec.if_footer         --�t�^�敪
       ,NULL                        --IF���Ɩ��n��R�[�h
       ,NULL                        --���_�R�[�h
       ,NULL                        --���_����
       ,NULL                        --�`�F�[���X�R�[�h
       ,NULL                        --�`�F�[���X����
       ,NULL                        --�f�[�^��R�[�h
       ,NULL                        --���[�R�[�h
       ,NULL                        --���[�\����
       ,NULL                        --���ڐ�
       ,gn_invoice_count + 1        --���R�[�h����
       ,lv_retcode                  --���^�[���R�[�h
       ,lv_footer_record            --�o�͒l
       ,ov_errbuf                   --�G���[���b�Z�[�W
       ,ov_errmsg                   --���[�U�E�G���[���b�Z�[�W
      );
--
      --==============================================================
      --�t�b�^���R�[�h�o��
      --==============================================================
      UTL_FILE.PUT_LINE(gf_file_handle_invoice, lv_footer_record);
--
      --==============================================================
      --�t�@�C���N���[�Y
      --==============================================================
      UTL_FILE.FCLOSE(gf_file_handle_invoice);
    END IF;
--
    --�d���`�[
    IF gb_supply THEN
      --==============================================================
      --�t�b�^���R�[�h�擾
      --==============================================================
      xxccp_ifcommon_pkg.add_chohyo_header_footer(
        g_prf_rec.if_footer         --�t�^�敪
       ,NULL                        --IF���Ɩ��n��R�[�h
       ,NULL                        --���_�R�[�h
       ,NULL                        --���_����
       ,NULL                        --�`�F�[���X�R�[�h
       ,NULL                        --�`�F�[���X����
       ,NULL                        --�f�[�^��R�[�h
       ,NULL                        --���[�R�[�h
       ,NULL                        --���[�\����
       ,NULL                        --���ڐ�
       ,gn_supply_count + 1         --���R�[�h����
       ,lv_retcode                  --���^�[���R�[�h
       ,lv_footer_record            --�o�͒l
       ,ov_errbuf                   --�G���[���b�Z�[�W
       ,ov_errmsg                   --���[�U�E�G���[���b�Z�[�W
      );
--
      --==============================================================
      --�t�b�^���R�[�h�o��
      --==============================================================
      UTL_FILE.PUT_LINE(gf_file_handle_supply, lv_footer_record);
--
      --==============================================================
      --�t�@�C���N���[�Y
      --==============================================================
      UTL_FILE.FCLOSE(gf_file_handle_supply);
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_out_footer_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : �f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- �v���O������
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
    cv_init_cust_po_number             CONSTANT VARCHAR2(04) := 'INIT';           --�Œ�lINIT
--
    -- *** ���[�J���ϐ� ***
    lt_header_id                       oe_order_headers_all.header_id%TYPE;       --�w�b�_ID
    lt_order_number                    oe_order_headers_all.order_number%TYPE;    --�󒍂m���i�d�a�r�j
    lt_tkn                             fnd_new_messages.message_text%TYPE;        --���b�Z�[�W�p������
    lt_cust_po_number                  oe_order_headers_all.cust_po_number%TYPE;  --�󒍃w�b�_�i�ڋq�����j
    lt_last_invoice_number             xxcos_edi_headers.invoice_number%TYPE;     --�O��`�[�ԍ�
    lv_product_name1                   VARCHAR2(100);                             --���i���P�i�J�i�j
    lv_product_name2                   VARCHAR2(100);                             --���i���Q�i�J�i�j
    ln_data_cnt                        NUMBER;                                    --�f�[�^����
    ln_idx_invoice                     NUMBER;                                    --�o�̓f�[�^���C���f�b�N�X(�����)
    ln_idx_supply                      NUMBER;                                    --�o�̓f�[�^���C���f�b�N�X(�d���`�[)
    lv_table_name                      all_tables.table_name%TYPE;
    lv_key_info                        VARCHAR2(100);
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
    lv_key_dept_store_edaban           VARCHAR2(500);                             --KEY�}��
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
    --���ڃ`�F�b�N�G���A
    ln_koguchi_count                   NUMBER;                                    --�J���}���܂񂾌���
    ln_no_del                          NUMBER;                                    --�J���}�𖳂���������
    ln_delimiter                       NUMBER;                                    --�J���}�̐�
    ln_work                            NUMBER;                                    --�`�F�b�N�p���[�N
    lv_work                            VARCHAR2(100);                             --�`�F�b�N�p���[�N
    --������
    ln_itoen_can                       NUMBER;                                    --�ɓ�����
    ln_itoen_dg                        NUMBER;                                    --�ɓ���DG
    ln_itoen_g                         NUMBER;                                    --�ɓ���G
    ln_itoen_hoka                      NUMBER;                                    --�ɓ�����
    ln_hashiba_can                     NUMBER;                                    --�����
    ln_hashiba_dg                      NUMBER;                                    --����DG
    ln_hashiba_g                       NUMBER;                                    --����G
    ln_hashiba_hoka                    NUMBER;                                    --���ꑼ
    --����t���O
    lb_input_invoice                   BOOLEAN;                                   --���R�[�h�i�[�t���O(�����)
    lb_input_supply                    BOOLEAN;                                   --���R�[�h�i�[�t���O(�d���`�[)
    lb_summary_invoice                 BOOLEAN;                                   --�W�v�t���O(�����)
    lb_summary_supply                  BOOLEAN;                                   --�W�v�t���O(�d���`�[)
    lb_output_invoice                  BOOLEAN;                                   --�o�̓t���O(�����)
    lb_output_supply                   BOOLEAN;                                   --�o�̓t���O(�d���`�[)
--
    -- *** ���[�J�����R�[�h�^ ***
    l_data_tab_invoice                 xxcos_common2_pkg.g_layout_ttype;          --�o�̓f�[�^��񃏁[�N(�����)
    l_data_tab_supply                  xxcos_common2_pkg.g_layout_ttype;          --�o�̓f�[�^��񃏁[�N(�d���`�[)
    l_summary_rec                      g_summary_rtype;                           --�W�v���
    l_other_rec                        g_other_rtype;                             --���̑����
    l_cust_dept_rec                    g_cust_dept_rtype;                         --�ڋq�}�X�^�i�S�ݓX�j���i�[���R�[�h
    l_cust_shop_rec                    g_cust_shop_rtype;                         --�ڋq�}�X�^�i�X�܁j���i�[���R�[�h
--
    -- *** ���[�J��PL/SQL�\ ***
    lt_tbl_invoice                     g_mlt_tab;                                 --�o�̓f�[�^���(�����)
    lt_tbl_supply                      g_mlt_tab;                                 --�o�̓f�[�^���(�d���`�[)
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_data_record(i_input_rec     g_input_rtype
                          ,i_prf_rec       g_prf_rtype
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--                          ,i_depart_rec    g_depart_rtype
--                          ,i_cust_dept_rec g_cust_dept_rtype
--                          ,i_cust_shop_rec g_cust_shop_rtype
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
                          ,i_msg_rec       g_msg_rtype
                          ,i_other_rec     g_other_rtype
    )
    IS
      SELECT ooha.header_id                                                     header_id                   --�󒍃w�b�_ID
      ------------------------------------------------------�w�b�_���------------------------------------------------------------
            ,ooha.order_number                                                  order_no_ebs                --�󒍂m���i�d�a�r�j
            ,ooha.attribute15                                                   invoice_number              --�`�[�ԍ�
            ,ooha.attribute17                                                   itoen_koguchi               --�ɓ���������
            ,ooha.attribute18                                                   hashiba_koguchi             --���ꏬ����
            ,ooha.request_date                                                  shop_delivery_date          --�X�ܔ[�i��
            ,ooha.cust_po_number                                                cust_po_number              --�ڋq�����ԍ�
      -------------------------------------------------------���׏��-------------------------------------------------------------
            ,oola.line_number                                                   line_no                     --�s�m��
            ,oola.ordered_item                                                  item_code                   --�i�ڃR�[�h
            ,oola.inventory_item_id                                             inventory_item_id           --�݌ɕi��ID
            ,NVL( oola.ordered_quantity  , cn_number0 )                         sum_order_qty               --����
            ,NVL( oola.unit_selling_price, cn_number0 )                         unit_selling_price          --�P��
            ,NVL( oola.attribute10       , cn_number0 )                         selling_price               --���P��
            ,NVL( ximb.item_short_name   , g_msg_rec.item_notfound )            product_name                --�i�ڗ���
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      ------------------------------------------------------�S�ݓX���------------------------------------------------------------
            ,xdm.attribute1                                                     account_number                --�ڋq�R�[�h
            ,xdm.attribute2                                                     item_distinction_num          --�i�ʔԍ�
            ,xdm.attribute3                                                     sales_place                   --����
            ,xdm.attribute4                                                     delivery_place                --�[�i�ꏊ
            ,xdm.attribute5                                                     display_place                 --�X�o�ꏊ
            ,xdm.attribute6                                                     slip_class                    --�`�[�敪
            ,xdm.attribute7                                                     a_column_class                --A���敪
            ,xdm.attribute8                                                     a_column                      --A��
            ,xdm.attribute9                                                     cost_indication_class         --�\���敪
            ,xdm.attribute10                                                    buy_digestion_class           --��������ŏo�敪
            ,xdm.attribute11                                                    tax_type_class                --�Ŏ�敪
            ,xdsc.meaning                                                       slip_class_name               --�`�[�敪����
            ,xdsc.attribute1                                                    publish_class_invoice         --����󔭍s�t���O
            ,xdsc.attribute2                                                    publish_class_supply          --�d���`�[���s�t���O
            ,xdbc.meaning                                                       buy_digestion_class_name      --��������ŏo�敪����
            ,xdtc.meaning                                                       tax_type_class_name           --�Ŏ�敪����
            ,hca.cust_account_id                                                cust_account_id               --�ڋqID(�}��)
            ,xca_s.store_code                                                   store_code                    --�X�܃R�[�h
            ,xca_s.cust_store_name                                              cust_store_name               --�X�ܖ���
            ,xca_s.torihikisaki_code                                            torihikisaki_code             --�����R�[�h
            ,hca_d.cust_account_id                                              dept_cust_id                  --�S�ݓX�ڋqID
            ,hp_d.party_name                                                    dept_name                     --�S�ݓX��
            ,xca_d.parnt_dept_shop_code                                         dept_shop_code                --�S�ݓX�`��R�[�h
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      FROM   oe_order_headers_all                                               ooha                        --�󒍃w�b�_���e�[�u��
            ,oe_order_lines_all                                                 oola                        --�󒍖��׏��e�[�u��
            ,oe_order_sources                                                   oos                         --�󒍃\�[�X
            ,oe_transaction_types_tl                                            ottt_h                      --�󒍃^�C�v�w�b�_
            ,oe_transaction_types_tl                                            ottt_l                      --�󒍃^�C�v����
            ,ic_item_mst_b                                                      iimb                        --OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b                                                   ximb                        --OPM�i�ڃ}�X�^�A�h�I��
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
            ,(
              SELECT
                 xdm.lookup_type     lookup_type
                ,xdm.lookup_code     lookup_code
                ,xdm.attribute1      attribute1
                ,xdm.attribute2      attribute2
                ,xdm.attribute3      attribute3
                ,xdm.attribute4      attribute4
                ,xdm.attribute5      attribute5
                ,xdm.attribute6      attribute6
                ,xdm.attribute7      attribute7
                ,xdm.attribute8      attribute8
                ,xdm.attribute9      attribute9
                ,xdm.attribute10     attribute10
                ,xdm.attribute11     attribute11
                ,SUBSTRB(xdm.lookup_code,7,5) edaban_code
              FROM
                xxcos_lookup_values_v       xdm
              WHERE
                    xdm.lookup_type     = ct_dept_mst                                   --�Q�ƃ^�C�v.�S�ݓX�}�X�^
              AND   xdm.lookup_code     LIKE lv_key_dept_store_edaban
              AND   i_other_rec.process_date
                BETWEEN xdm.start_date_active
              AND     NVL(xdm.end_date_active,i_other_rec.process_date)
             )                                                                  xdm
            ,xxcos_lookup_values_v                                              xdsc                          --�S�ݓX�`�[�敪
            ,xxcos_lookup_values_v                                              xdbc                          --��������ŏo�敪
            ,xxcos_lookup_values_v                                              xdtc                          --�Ŏ�敪
            ,hz_cust_accounts                                                   hca                           --�ڋq�}�X�^(�}��)
            ,hz_cust_accounts                                                   hca_s                         --�ڋq�}�X�^�i�X�܁j
            ,xxcmm_cust_accounts                                                xca_s                         --�ڋq�}�X�^�A�h�I���i�X�܁j
            ,hz_cust_accounts                                                   hca_d                         --�ڋq�}�X�^(�S�ݓX)
            ,xxcmm_cust_accounts                                                xca_d                         --�ڋq�}�X�^�A�h�I��(�S�ݓX)
            ,hz_parties                                                         hp_d                          --�p�[�e�B�}�X�^(�S�ݓX)
            ,xxcos_dept_store_security_v                                        xdsv                        --�S�ݓX�X�܃Z�L�����e�B�r���[
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --�󒍃w�b�_���o����
      WHERE  ooha.org_id = i_prf_rec.org_id                                                                 --�g�DID
      AND    ooha.flow_status_code <> cv_cancel                                                             --�X�e�[�^�X�����
      AND    ooha.flow_status_code <> cv_entered                                                            --�X�e�[�^�X�����͍ς�
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      AND    ooha.sold_to_org_id = hca.cust_account_id                                                      --�ڋqID
--      AND    ooha.sold_to_org_id = g_depart_rec.cust_account_id                                             --�ڋqID
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      AND    TRUNC( ooha.request_date )
             BETWEEN TO_DATE( i_input_rec.shop_delivery_date_from, cv_date_fmt )
             AND     TO_DATE( i_input_rec.shop_delivery_date_to, cv_date_fmt )                              --�X�ܔ[�i��
      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                         --�[�i�����s�t���O�擾�֐�
               i_input_rec.publish_flag_seq                                                                 --�[�i�����s�t���O����
              ,ooha.global_attribute1                                                                       --���ʒ��[�l���p�[�i�����s�t���O�G���A
               ) = i_input_rec.publish_div                                                                  --���̓p�����[�^.�[�i�����s�t���O
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      AND ( i_input_rec.key_edaban IS NULL 
          OR i_input_rec.key_edaban IS NOT NULL AND ooha.attribute16 = i_input_rec.key_edaban )             --���̓p�����[�^.�}��
--      AND    ooha.attribute16       = i_input_rec.key_edaban                                                --���̓p�����[�^.�}��
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --�󒍖���
      AND    oola.header_id         = ooha.header_id                                                        --�󒍃w�b�_ID
      AND    oola.flow_status_code <> cv_cancel                                                             --�X�e�[�^�X�����
      --�󒍃\�[�X���o����
      AND    oos.name               = i_msg_rec.order_source                                                --���́�Online
      AND    oos.enabled_flag       = cv_enabled_flag
      AND    oos.order_source_id    = ooha.order_source_id                                                  --�󒍃\�[�XID
      --�󒍃^�C�v�i�w�b�_�j���o����
      AND    ottt_h.language        = cv_default_language                                                   --����
      AND    ottt_h.source_lang     = cv_default_language                                                   --����(�\�[�X)
      AND    ottt_h.description     IN ( i_msg_rec.header_type01                                            --�E�v.01_�S�ݓX��
                                        ,i_msg_rec.header_type02                                            --�E�v.04_�S�ݓX���{
                                       )
      AND    ooha.order_type_id     = ottt_h.transaction_type_id                                            --�󒍃^�C�vID
      --�󒍃^�C�v�i���ׁj���o����
      AND    ottt_l.language        = cv_default_language                                                   --����
      AND    ottt_l.source_lang     = cv_default_language                                                   --����(�\�[�X)
      AND    ottt_l.description    IN ( i_msg_rec.line_type_dept                                            --�E�v.10_�S�ݓX
                                       ,i_msg_rec.line_type_sample                                          --�E�v.50_�S�ݓX���{
                                      )
      AND    oola.line_type_id      = ottt_l.transaction_type_id                                            --�󒍖��׃^�C�vID
      --OPM�i�ڃ}�X�^���o����
      AND    iimb.item_no(+)        = oola.ordered_item                                                     --�i���R�[�h
      --OPM�i�ڃA�h�I�����o����
      AND    ximb.item_id(+)        = iimb.item_id                                                          --�i��ID
      AND    TRUNC( ooha.request_date )                                                                     --�v����
             BETWEEN NVL( ximb.start_date_active ,TRUNC( ooha.request_date ) )                              --�K�p�J�n��
             AND     NVL( ximb.end_date_active   ,TRUNC( ooha.request_date ) )                              --�K�p�I����
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      --�S�ݓX�}�X�^���o����
      AND   xdm.edaban_code     = ooha.attribute16
      --�S�ݓX�`�[�敪���o����
      AND   xdsc.lookup_type    = ct_dept_slip_class                            --�Q�ƃ^�C�v.�S�ݓX�`�[�敪
      AND   xdsc.lookup_code    = xdm.attribute6
      AND   i_other_rec.process_date
        BETWEEN xdsc.start_date_active
        AND     NVL(xdsc.end_date_active,i_other_rec.process_date)
      --��������ŏo�敪���o����
      AND   xdbc.lookup_type    = ct_dept_buy_class                             --�Q�ƃ^�C�v.��������ŏo�敪
      AND   xdbc.lookup_code    = xdm.attribute10
      AND   i_other_rec.process_date
        BETWEEN xdbc.start_date_active
        AND     NVL(xdbc.end_date_active,i_other_rec.process_date)
      --�Ŏ�敪���̒��o����
      AND   xdtc.lookup_type    = ct_dept_tax_class                             --�Q�ƃ^�C�v.�Ŏ�敪
      AND   xdtc.lookup_code    = xdm.attribute11
      AND   i_other_rec.process_date
        BETWEEN xdtc.start_date_active
        AND     NVL(xdtc.end_date_active,i_other_rec.process_date)
      AND   hca.account_number  = xdm.attribute1                                --�ڋq�R�[�h
      -- �X�ܒ��o����
      AND   hca_s.cust_account_id       = hca.cust_account_id                   --�ڋqID�i�ڋq�j= �ڋqID�i�}�ԁj
      AND   hca_s.customer_class_code   = cv_cust_class_cust                    --�ڋq�敪�i�ڋq�j
      AND   hca_s.cust_account_id       = xca_s.customer_id                     --�ڋqID�i�ڋq�j
      -- �S�ݓX���o����
      AND   xca_d.parnt_dept_shop_code  = xca_s.child_dept_shop_code           -- �ڋq�A�h�I��.�e�S�ݓX�`��(�S�ݓX) = �ڋq�A�h�I��.�q�S�ݓX�`��(�ڋq)
      AND   xca_d.customer_id           = hca_d.cust_account_id                -- �ڋq�A�h�I��(�S�ݓX)= �ڋq�}�X�^�ڋqID(�S�ݓX)
      AND   hca_d.customer_class_code   = cv_cust_class_dept                   -- �ڋq�敪�i�S�ݓX�j
      AND   ( i_input_rec.dept_code IS NULL
              OR ( i_input_rec.dept_code IS NOT NULL
                 AND xca_d.parnt_dept_shop_code  = i_input_rec.dept_code )
            )                -- �ڋq�A�h�I��(�S�ݓX).�S�ݓX�R�[�h = INPUT�S�ݓX�R�[�h
      AND   hp_d.party_id               = hca_d.party_id
      -- �S�ݓX�X�܃Z�L�����e�B�r���[���o����
      AND   xdsv.dept_code        = xca_d.parnt_dept_shop_code                 -- �S�ݓX�R�[�h
      AND   xdsv.dept_store_code  = xca_s.store_code                           -- �S�ݓX�X�܃R�[�h
      AND   xdsv.user_id          = i_input_rec.user_id                        -- �S�ݓX�X�܃Z�L�����e�B�r���[.���[�U�[ID = IN�p��.���[�U�[ID
      AND   xdsv.account_number   = hca.account_number                         -- �ڋq�R�[�h
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      ORDER BY ooha.request_date                                                                            --�󒍃w�b�_.�X�ܔ[�i��
              ,ooha.attribute15                                                                             --�󒍃w�b�_.�`�[�ԍ�
              ,oola.line_number                                                                             --�󒍖���.���הԍ�
      FOR UPDATE OF ooha.header_id NOWAIT                                                                   --���b�N
     ;
--
--
    --�������擾�֐�
    FUNCTION get_koguchi(
      iv_string IN VARCHAR2
     ,in_number IN NUMBER
    )
    RETURN NUMBER
    IS
      cv_sepa   CONSTANT VARCHAR2(1) := CHR(44); --�J���}
      lv_tmp    VARCHAR2(32767);
      ln_start  NUMBER;
      ln_end    NUMBER;
      ln_len    NUMBER;
    BEGIN
      --�J�n�ʒu�̐ݒ�
      IF in_number = 1 THEN
        ln_start := 1;
      ELSE
        ln_start := instrb( iv_string, cv_sepa, 1, in_number - 1 );
        IF ln_start = 0 THEN
          RETURN NULL;
        ELSE
          ln_start := ln_start + 1;
        END IF;
      END IF;
--
      --�I���ʒu�̐ݒ�
      ln_end := instrb( iv_string, cv_sepa, 1, in_number );
--
      --�w�肳�ꂽ�ʒu�̒l���擾
      IF ln_end = 0 THEN
        lv_tmp := SUBSTRB( iv_string, ln_start );
      ELSE
        ln_len := ln_end - ln_start;
        lv_tmp := SUBSTRB( iv_string, ln_start, ln_len );
      END IF;
--
      RETURN TO_NUMBER( lv_tmp );
--
    END get_koguchi;
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���b�Z�[�W������(01_�S�ݓX��)�擾
    g_msg_rec.header_type01     := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type01);
    --���b�Z�[�W������(04_�S�ݓX���{)�擾
    g_msg_rec.header_type02     := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type02);
    --���b�Z�[�W������(10_�S�ݓX)�擾
    g_msg_rec.line_type_dept    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type_dept);
    --���b�Z�[�W������(10_�S�ݓX���{)�擾
    g_msg_rec.line_type_sample  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type_sample);
    --���b�Z�[�W������(�󒍃\�[�X)�擾
    g_msg_rec.order_source      := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
--
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--    --==============================================================
--    --�ڋq�}�X�^�i�S�ݓX�j���擾
--    --==============================================================
--    BEGIN
--      SELECT hca.cust_account_id                                                dept_cust_id                 --�S�ݓX�ڋqID
--            ,hp.party_name                                                      dept_name                    --�S�ݓX��
--            ,xca.parnt_dept_shop_code                                           dept_shop_code               --�S�ݓX�`��R�[�h
--      INTO   l_cust_dept_rec.dept_cust_id
--            ,l_cust_dept_rec.dept_name
--            ,l_cust_dept_rec.dept_shop_code
--      FROM   hz_cust_accounts                                                   hca                          --�ڋq�}�X�^(�S�ݓX)
--            ,xxcmm_cust_accounts                                                xca                          --�ڋq�}�X�^�A�h�I��(�S�ݓX)
--            ,hz_parties                                                         hp                           --�p�[�e�B�}�X�^(�S�ݓX)
--      WHERE  hca.customer_class_code   = cv_cust_class_dept                                                  --�ڋq�敪�i�S�ݓX�j
--      AND    xca.customer_id           = hca.cust_account_id                                                 --�ڋqID
--      AND    xca.parnt_dept_shop_code  = g_input_rec.dept_code                                               --�S�ݓX�R�[�h
--      AND    hp.party_id               = hca.party_id
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_cust_dept_rec.dept_name := g_msg_rec.customer_notfound;
--    END;
----
--    --==============================================================
--    --�ڋq�}�X�^�i�X�܁j���擾
--    --==============================================================
--    BEGIN
--      SELECT xca.store_code                                                     store_code                   --�X�܃R�[�h
--            ,xca.cust_store_name                                                cust_store_name              --�X�ܖ���
--            ,xca.torihikisaki_code                                              torihikisaki_code            --�����R�[�h
--      INTO   l_cust_shop_rec.store_code
--            ,l_cust_shop_rec.cust_store_name
--            ,l_cust_shop_rec.torihikisaki_code
--      FROM   hz_cust_accounts                                                   hca                          --�ڋq�}�X�^�i�X�܁j
--            ,xxcmm_cust_accounts                                                xca                          --�ڋq�}�X�^�A�h�I���i�X�܁j
--      WHERE  hca.customer_class_code   = cv_cust_class_cust                                                  --�ڋq�敪�i�ڋq�j
--      AND    hca.cust_account_id       = xca.customer_id                                                     --�ڋqID
--      AND    hca.cust_account_id       = g_depart_rec.cust_account_id
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_cust_shop_rec.cust_store_name := g_msg_rec.customer_notfound;
--    END;
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
--
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
    IF ( ( g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban ) IS NULL ) THEN
       lv_key_dept_store_edaban := '%';
    ELSE
       IF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NULL ) AND ( g_input_rec.key_edaban IS NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || '%';
       ELSIF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NOT NULL ) AND ( g_input_rec.key_edaban IS NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || '%';
       ELSIF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NOT NULL ) AND ( g_input_rec.key_edaban IS NOT NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban;
       END IF;
    END IF;
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--    --==============================================================
--    --�O���[�o���ϐ��̐ݒ�
--    --==============================================================
--    g_cust_dept_rec  := l_cust_dept_rec;
--    g_cust_shop_rec  := l_cust_shop_rec;
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
--
    --�f�[�^�����̏�����
    ln_data_cnt := 0;
--
    --�W�v���̏�����
      --���������v
    l_summary_rec.total_itoen_can     := 0;   --�ɓ�����
    l_summary_rec.total_itoen_dg      := 0;   --�ɓ���DG
    l_summary_rec.total_itoen_g       := 0;   --�ɓ���G
    l_summary_rec.total_itoen_hoka    := 0;   --�ɓ�����
    l_summary_rec.total_hashiba_can   := 0;   --�����
    l_summary_rec.total_hashiba_dg    := 0;   --����DG
    l_summary_rec.total_hashiba_g     := 0;   --����G
    l_summary_rec.total_hashiba_hoka  := 0;   --���ꑼ
      --�������ʁi���v�A�o���j
    l_summary_rec.total_sum_order_qty      := 0;
      --�������z�i�o�ׁj
    l_summary_rec.total_shipping_cost_amt  := 0;
      --�������z�i�o�ׁj
    l_summary_rec.total_shipping_price_amt := 0;
--
    --==============================================================
    --�f�[�^���R�[�h���擾
    --==============================================================
    <<data_record_loop>>
    FOR rec_main IN cur_data_record(
      g_input_rec
     ,g_prf_rec
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--     ,g_depart_rec
--     ,g_cust_dept_rec
--     ,g_cust_shop_rec
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
     ,g_msg_rec
     ,g_other_rec
    )
--
    LOOP
      dbms_output.put_line('order,line,deliv_date :' || rec_main.order_no_ebs || ',' || rec_main.line_no || ',' || rec_main.shop_delivery_date);
--
      --�f�[�^�����J�E���g�A�b�v
      ln_data_cnt := ln_data_cnt + 1;
--
      --����t���O������
      lb_input_invoice   := FALSE;    --���R�[�h�i�[�t���O(�����)
      lb_input_supply    := FALSE;    --���R�[�h�i�[�t���O(�d���`�[)
      lb_summary_invoice := FALSE;    --�W�v�t���O(�����)
      lb_summary_supply  := FALSE;    --�W�v�t���O(�d���`�[)
      lb_output_invoice  := FALSE;    --�o�̓t���O(�����)
      lb_output_supply   := FALSE;    --�o�̓t���O(�d���`�[)
--
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      -- ������
      l_cust_dept_rec := NULL;
      l_cust_shop_rec := NULL;
      g_depart_rec    := NULL;
      -- �S�ݓX���̎擾
      l_cust_dept_rec.dept_cust_id         := rec_main.dept_cust_id;              --�S�ݓX�ڋqID
      l_cust_dept_rec.dept_name            := rec_main.dept_name;                 --�S�ݓX��
      l_cust_dept_rec.dept_shop_code       := rec_main.dept_shop_code;            --�S�ݓX�`��R�[�h
      -- �S�ݓX�X�܏��̎擾
      l_cust_shop_rec.store_code           := rec_main.store_code;                --�X�܃R�[�h
      l_cust_shop_rec.cust_store_name      := rec_main.cust_store_name;           --�X�ܖ���
      l_cust_shop_rec.torihikisaki_code    := rec_main.torihikisaki_code;         --�����R�[�h
      -- �S�ݓX�}�ԏ��̎擾
      g_depart_rec.account_number          := rec_main.account_number;            --�ڋq�R�[�h
      g_depart_rec.item_distinction_num    := rec_main.item_distinction_num;      --�i�ʔԍ�
      g_depart_rec.sales_place             := rec_main.sales_place;               --���ꖼ
      g_depart_rec.delivery_place          := rec_main.delivery_place;            --�[�i�ꏊ
      g_depart_rec.display_place           := rec_main.display_place;             --�X�o�ꏊ
      g_depart_rec.slip_class              := rec_main.slip_class;                --�`�[�敪
      g_depart_rec.a_column_class          := rec_main.a_column_class;            --A���敪
      g_depart_rec.a_column                := rec_main.a_column;                  --A��
      g_depart_rec.cost_indication_class   := rec_main.cost_indication_class;     --�\���敪
      g_depart_rec.buy_digestion_class     := rec_main.buy_digestion_class;       --��������ŏo�敪
      g_depart_rec.tax_type_class          := rec_main.tax_type_class;            --�Ŏ�敪
      g_depart_rec.slip_class_name         := rec_main.slip_class_name;           --�`�[�敪����
      g_depart_rec.publish_class_invoice   := rec_main.publish_class_invoice;     --����󔭍s�t���O
      g_depart_rec.publish_class_supply    := rec_main.publish_class_supply;      --�d���`�[���s�t���O
      g_depart_rec.buy_digestion_class_name:= rec_main.buy_digestion_class_name;  --��������ŏo�敪����
      g_depart_rec.tax_type_class_name     := rec_main.tax_type_class_name;       --�Ŏ�敪����
      g_depart_rec.cust_account_id         := rec_main.cust_account_id;           --�ڋqID
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --==============================================================
      --����t���O�Z�b�g(���R�[�h�i�[�A�o�́A�W�v)(A-5)
      --==============================================================
      --����󔭍s�t���O="Y"
      IF ( gb_invoice ) THEN
        --�擪���R�[�h
        IF ( lt_tbl_invoice.COUNT = 0 ) THEN
          --���R�[�h�i�[�ΏۂƂ���
          lb_input_invoice := TRUE;
          --�W�v�ΏۂƂ���
          lb_summary_invoice := TRUE;
--
        --2���ڈȍ~(PL/SQL�\�Ɋi�[���ꂽ�ŏI���R�[�h�Ƃ̔�r)
        ELSE
          --�󒍔ԍ����ς������W�v�ΏۂƂ���
          IF ( rec_main.order_no_ebs <> lt_tbl_invoice( ln_idx_invoice )( 'ORDER_NO_EBS' ) ) THEN
            lb_summary_invoice := TRUE;
          END IF;
--
          --�d���`�[����
          IF ( gb_supply ) THEN
            --�`�[�ԍ����ς�����烌�R�[�h�i�[�ΏۂƂ���(�`�[�ԍ�����)
            IF ( rec_main.invoice_number <> lt_tbl_invoice( ln_idx_invoice )( 'INVOICE_NUMBER' ) ) THEN
              lb_input_invoice := TRUE;
            END IF;
            --�X�ܔ[�i�����ς������o�͑ΏۂƂ���(�X�ܔ[�i������)
            IF ( TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt ) <> lt_tbl_invoice( ln_idx_invoice )( 'SHOP_DELIVERY_DATE' ) ) THEN
              lb_output_invoice := TRUE;
            END IF;
--
          --�d���`�[�Ȃ�
          ELSE
            --���R�[�h�i�[�ΏۂƂ���(1���R�[�h����)
            lb_input_invoice := TRUE;
            --�`�[�ԍ����ς������o�͑ΏۂƂ���(�`�[�ԍ�����)
            IF ( rec_main.invoice_number <> lt_tbl_invoice( ln_idx_invoice )( 'INVOICE_NUMBER' ) ) THEN
              lb_output_invoice := TRUE;
            END IF;
          END IF;
        END IF;
      END IF;
--
      --�d���`�[���s�t���O="Y"
      IF ( gb_supply ) THEN
        --���R�[�h�i�[�ΏۂƂ���
        lb_input_supply := TRUE;
        --�W�v�ΏۂƂ���
        lb_summary_supply := TRUE;
--
        --2���ڈȍ~(PL/SQL�\�Ɋi�[���ꂽ�ŏI���R�[�h�Ƃ̔�r)
        IF ( lt_tbl_supply.COUNT > 0 ) THEN
          --�`�[�ԍ����ς������o�͑ΏۂƂ���(�`�[�ԍ�����)
          IF ( rec_main.invoice_number <> lt_tbl_supply( ln_idx_supply )( 'INVOICE_NUMBER' ) ) THEN
            lb_output_supply := TRUE;
          END IF;
        END IF;
      END IF;
--
      --==============================================================
      --CSV�w�b�_���R�[�h�쐬����(A-4)
      --==============================================================
      IF ( ln_data_cnt = 1 ) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      --�ڋq�i�ړE�v�擾(A-5.1)
      --==============================================================
      BEGIN
        SELECT xciv.customer_item_desc                                            cust_item_desc               --�ڋq�i�ړK�p
        INTO   rec_main.product_name
        FROM   xxcos_customer_items_v                                             xciv                         --�ڋq�i��view
        WHERE  xciv.customer_id       = l_cust_dept_rec.dept_cust_id                                           --�S�ݓX�ڋqID
        AND    xciv.inventory_item_id = rec_main.inventory_item_id                                             --�݌ɕi��ID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          out_line(buff => cv_prg_name || ' ' || sqlerrm);
      END;
--
      --==============================================================
      --�������i���l�j�`�F�b�N(A-5.2)
      --==============================================================
      --�ɓ���������
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_integeral_num_err
                    ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                    ,cv_tkn_item
                    ,ct_msg_koguchi_itoen
                   );
      --�J���}����菜��
      lv_work := REPLACE( rec_main.itoen_koguchi, ',', '' );
      --���p�`�F�b�N
      IF LENGTH( lv_work ) <> LENGTHB( lv_work ) THEN
        RAISE proc_get_data_expt;
      END IF;
      --���l�`�F�b�N
      BEGIN
        ln_work := TO_NUMBER( lv_work );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE proc_get_data_expt;
      END;
--
      --���ꏬ����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_integeral_num_err
                    ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                    ,rec_main.invoice_number
                    ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                    ,cv_tkn_item
                    ,ct_msg_koguchi_hashiba
                   );
      --�J���}����菜��
      lv_work := REPLACE( rec_main.hashiba_koguchi, ',', '' );
      --���p�`�F�b�N
      IF LENGTH( lv_work ) <> LENGTHB( lv_work ) THEN
        RAISE proc_get_data_expt;
      END IF;
      --���l�`�F�b�N
      BEGIN
        ln_work := TO_NUMBER( lv_work );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE proc_get_data_expt;
      END;
--
      --==============================================================
      --�������i�J���}���j�`�F�b�N(A-5.3)
      --==============================================================
      --�ɓ���������
      --�J���}�̐��擾
      ln_koguchi_count     := LENGTHB( rec_main.itoen_koguchi );                          --�J���}���܂񂾌���
      ln_no_del            := LENGTHB( REPLACE( rec_main.itoen_koguchi, ',', NULL ) );    --�J���}�𖳂���������
      ln_delimiter         := ln_koguchi_count - ln_no_del;                               --�J���}�̐�
--
      IF ( ln_delimiter <> cn_cnt_sep_koguchi ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_koguchi_count_err
                      ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                      ,cv_tkn_item
                      ,ct_msg_koguchi_itoen
                      ,cv_tkn_num_of_item
                      ,cn_number4
                     );
        RAISE proc_get_data_expt;
      END IF;
--
      --���ꏬ����
      --�J���}�̐��擾
      ln_koguchi_count     := LENGTHB( rec_main.hashiba_koguchi );                        --�J���}���܂񂾌���
      ln_no_del            := LENGTHB( REPLACE( rec_main.hashiba_koguchi, ',', NULL ) );  --�J���}�𖳂���������
      ln_delimiter         := ln_koguchi_count - ln_no_del;                               --�J���}�̐�
--
      IF ( ln_delimiter <> cn_cnt_sep_koguchi ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_koguchi_count_err
                      ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                      ,cv_tkn_item
                      ,ct_msg_koguchi_hashiba
                      ,cv_tkn_num_of_item
                      ,cn_number4
                     );
        RAISE proc_get_data_expt;
      END IF;
--
      --==============================================================
      --�������擾
      --==============================================================
      ln_itoen_can         := NVL( get_koguchi( rec_main.itoen_koguchi  , 1 ), 0 );   --�ɓ�����
      ln_itoen_dg          := NVL( get_koguchi( rec_main.itoen_koguchi  , 2 ), 0 );   --�ɓ���DG
      ln_itoen_g           := NVL( get_koguchi( rec_main.itoen_koguchi  , 3 ), 0 );   --�ɓ���G
      ln_itoen_hoka        := NVL( get_koguchi( rec_main.itoen_koguchi  , 4 ), 0 );   --�ɓ�����
      ln_hashiba_can       := NVL( get_koguchi( rec_main.hashiba_koguchi, 1 ), 0 );   --�����
      ln_hashiba_dg        := NVL( get_koguchi( rec_main.hashiba_koguchi, 2 ), 0 );   --����DG
      ln_hashiba_g         := NVL( get_koguchi( rec_main.hashiba_koguchi, 3 ), 0 );   --����G
      ln_hashiba_hoka      := NVL( get_koguchi( rec_main.hashiba_koguchi, 4 ), 0 );   --���ꑼ
--
      --==============================================================
      --���R�[�h�^�ւ̊i�[(�����)(A-5.5.1)
      --==============================================================
      IF ( lb_input_invoice ) THEN
        --���R�[�h�^�̏�����
        l_data_tab_invoice.DELETE;
            ------------------------------------------------�w�b�_���------------------------------------------------
        l_data_tab_invoice('MEDIUM_CLASS')                  := cv_number01;                                           --�}�̋敪
        l_data_tab_invoice('DATA_TYPE_CODE')                := g_input_rec.data_type_code;                            --�f�[�^��R�[�h
        l_data_tab_invoice('FILE_NO')                       := cv_number00;                                           --�t�@�C���m��
        l_data_tab_invoice('PROCESS_DATE')                  := g_other_rec.proc_date;                                 --������
        l_data_tab_invoice('PROCESS_TIME')                  := g_other_rec.proc_time;                                 --��������
        l_data_tab_invoice('BASE_CODE')                     := g_input_rec.base_code;                                 --���_�i����j�R�[�h
        l_data_tab_invoice('REPORT_CODE')                   := g_input_rec.report_code;                               --���[�R�[�h
        l_data_tab_invoice('REPORT_SHOW_NAME')              := g_input_rec.report_name;                               --���[�\����
-- ************** 2009/09/07 1.4 N.Maeda MOD START *********** --
--        l_data_tab_invoice('COMPANY_NAME')                  := g_input_rec.dept_name;                                 --�Ж��i�����j
        l_data_tab_invoice('COMPANY_NAME')                  := l_cust_dept_rec.dept_name;                             --�Ж��i�����j
-- ************** 2009/09/07 1.4 N.Maeda MOD  END  *********** --
        l_data_tab_invoice('SHOP_NAME')                     := l_cust_shop_rec.cust_store_name;                       --�X���i�����j
        l_data_tab_invoice('SHOP_DELIVERY_DATE')            := TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt );   --�X�ܔ[�i��
        l_data_tab_invoice('INVOICE_NUMBER')                := rec_main.invoice_number;                               --�`�[�ԍ�
        l_data_tab_invoice('ORDER_NO_EBS')                  := rec_main.order_no_ebs;                                 --�󒍂m���i�d�a�r�j
        l_data_tab_invoice('VENDOR_NAME')                   := g_prf_rec.company_name;                                --����於�i�����j
        l_data_tab_invoice('VENDOR_TEL')                    := g_prf_rec.phone_number;                                --�����s�d�k
        l_data_tab_invoice('VENDOR_CHARGE')                 := g_prf_rec.post_code;                                   --�����S����
        l_data_tab_invoice('VENDOR_ADDRESS')                := g_depart_rec.delivery_place;                           --�����Z���i�����j
        l_data_tab_invoice('BALANCE_ACCOUNTS_NAME')         := g_depart_rec.sales_place;                              --�����於�i�����j
        l_data_tab_invoice('PURCHASE_TYPE')                 := g_depart_rec.buy_digestion_class_name;                 --�d���`��
--
            ------------------------------------------------���׏��------------------------------------------------
        -- �d���`�[�Ȃ��̏ꍇ�̂�
        IF ( NOT gb_supply ) THEN
          l_data_tab_invoice('LINE_NO')                     := rec_main.line_no;                                      --�s�m��
          l_data_tab_invoice('PRODUCT_NAME')                := rec_main.product_name;                                 --���i���i�����j
          l_data_tab_invoice('CASE_QTY')                    := rec_main.sum_order_qty;                                --�P�[�X����
        END IF;
--
      END IF;
--
      --==============================================================
      --���R�[�h�^�ւ̊i�[(�d���`�[)(A-5.5.2)
      --==============================================================
      IF ( lb_input_supply ) THEN
        --���i���̕���
        IF ( SUBSTRB( rec_main.product_name, 1, cn_div_item * 2 ) =
             SUBSTRB( rec_main.product_name, 1, cn_div_item ) || SUBSTRB( rec_main.product_name, cn_div_item + 1, cn_div_item ) )
        THEN
          -- 14-15�o�C�g�ڂ��S�p�łȂ��ꍇ
          lv_product_name1 := SUBSTRB( rec_main.product_name, 1,               cn_div_item     ); -- 1-14�o�C�g
          lv_product_name2 := SUBSTRB( rec_main.product_name, cn_div_item + 1, cn_div_item     ); -- 15-28�o�C�g
        ELSE
          -- 14-15�o�C�g�ڂ��S�p�̏ꍇ
          lv_product_name1 := SUBSTRB( rec_main.product_name, 1,               cn_div_item - 1 ); -- 1-13�o�C�g
          lv_product_name2 := SUBSTRB( rec_main.product_name, cn_div_item,     cn_div_item     ); -- 14-27�o�C�g
        END IF;
        --���R�[�h�^�̏�����
        l_data_tab_supply.DELETE;
            ------------------------------------------------�w�b�_���------------------------------------------------
        l_data_tab_supply('MEDIUM_CLASS')                   := cv_number01;                                           --�}�̋敪
        l_data_tab_supply('DATA_TYPE_CODE')                 := g_input_rec.data_type_code;                            --�f�[�^��R�[�h
        l_data_tab_supply('FILE_NO')                        := cv_number00;                                           --�t�@�C���m��
        l_data_tab_supply('PROCESS_DATE')                   := g_other_rec.proc_date;                                 --������
        l_data_tab_supply('PROCESS_TIME')                   := g_other_rec.proc_time;                                 --��������
        l_data_tab_supply('BASE_CODE')                      := g_input_rec.base_code;                                 --���_�i����j�R�[�h
        l_data_tab_supply('REPORT_CODE')                    := g_input_rec.report_code;                               --���[�R�[�h
        l_data_tab_supply('REPORT_SHOW_NAME')               := g_input_rec.report_name;                               --���[�\����
        l_data_tab_supply('COMPANY_CODE')                   := g_input_rec.dept_code;                                 --�ЃR�[�h
        l_data_tab_supply('COMPANY_NAME')                   := l_cust_dept_rec.dept_name;                             --�Ж��i�����j
        l_data_tab_supply('SHOP_CODE')                      := l_cust_shop_rec.store_code;                            --�X�R�[�h
        l_data_tab_supply('SHOP_NAME')                      := l_cust_shop_rec.cust_store_name;                       --�X���i�����j
        l_data_tab_supply('DELIVERY_CENTER_NAME')           := g_depart_rec.delivery_place;                           --�[���Z���^�[���i�����j
        l_data_tab_supply('SHOP_DELIVERY_DATE')             := TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt );   --�X�ܔ[�i��
        l_data_tab_supply('INVOICE_NUMBER')                 := rec_main.invoice_number;                               --�`�[�ԍ�
        l_data_tab_supply('VENDOR_CODE')                    := l_cust_shop_rec.torihikisaki_code;                     --�����R�[�h
        l_data_tab_supply('VENDOR_NAME')                    := g_prf_rec.company_name;                                --����於�i�����j
        l_data_tab_supply('DELIVER_TO')                     := g_depart_rec.display_place;                            --�͂���i�����j
        l_data_tab_supply('COUNTER_NAME')                   := g_depart_rec.sales_place;                              --���ꖼ
        l_data_tab_supply('TAX_TYPE')                       := g_depart_rec.tax_type_class_name;                      --�Ŏ�
        l_data_tab_supply('PRICE_TAG_METHOD')               := g_depart_rec.item_distinction_num;                     --�l�D���@
        --�`���敪���u�`�����v�̏ꍇ
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class1 ) THEN
          l_data_tab_supply('A_COLUMN_HEADER')              := g_depart_rec.a_column;                                 --�`���w�b�_
        END IF;
        --�`���敪���u�c�����v�̏ꍇ
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class3 ) THEN
          l_data_tab_supply('D_COLUMN_HEADER')              := g_depart_rec.a_column;                                 --�c���w�b�_
        END IF;
        l_data_tab_supply('D3_COLUMN')                      := rec_main.cust_po_number;                               --�c�|�R��
            ------------------------------------------------���׏��------------------------------------------------
        l_data_tab_supply('LINE_NO')                        := rec_main.line_no;                                      --�s�m��
        l_data_tab_supply('PRODUCT_NAME1_ALT')              := lv_product_name1;                                      --���i���P�i�J�i�j
        l_data_tab_supply('PRODUCT_NAME2_ALT')              := lv_product_name2;                                      --���i���Q�i�J�i�j
        l_data_tab_supply('SUM_ORDER_QTY')                  := rec_main.sum_order_qty;                                --�������ʁi���v�A�o���j
        --�\���敪���u�\������v�̏ꍇ
        IF ( g_depart_rec.cost_indication_class = cv_department_show_class0 ) THEN
          l_data_tab_supply('SHIPPING_UNIT_PRICE')          := rec_main.unit_selling_price;                           --���P���i�o�ׁj
          l_data_tab_supply('SHIPPING_COST_AMT')            := ( rec_main.sum_order_qty * rec_main.unit_selling_price );--�������z�i�o�ׁj
        --�\���敪���u�\�����Ȃ��v�̏ꍇ
        ELSE
          l_data_tab_supply('SHIPPING_UNIT_PRICE')          := 0;                                                     --���P���i�o�ׁj
          l_data_tab_supply('SHIPPING_COST_AMT')            := 0;                                                     --�������z�i�o�ׁj
        END IF;
        l_data_tab_supply('SELLING_PRICE')                  := rec_main.selling_price;                                --���P��
        l_data_tab_supply('SHIPPING_PRICE_AMT')             := ( rec_main.sum_order_qty * rec_main.selling_price );   --�������z�i�o�ׁj
        --�`���敪���u�`�����v�̏ꍇ
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class0 ) THEN
          l_data_tab_supply('A_COLUMN_DEPARTMENT')          := g_depart_rec.a_column;                                 --�`���i�S�ݓX�j
        END IF;
        --�`���敪���u�������ʁv�̏ꍇ
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class2 ) THEN
          l_data_tab_supply('GENERAL_ADD_ITEM1')            := g_depart_rec.a_column;                                 --�ėp�t�����ڂP
        END IF;
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬����(�����)(A-5.6-8)
      --==============================================================
      IF ( lb_output_invoice ) THEN
        --�f�[�^���R�[�h�쐬����(PL/SQL�\�Ɋi�[���ꂽ�f�[�^���o�͂���APL/SQL�\���N���A�����)
        proc_out_data_record(
          0                   --�o�͎��(0:�����A1:�d���`�[)
         ,lt_tbl_invoice      --�o�̓f�[�^���
         ,l_summary_rec       --���������v
         ,ov_errbuf           --�G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          --���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬����(�d���`�[)(A-5.6-8)
      --==============================================================
      IF ( lb_output_supply ) THEN
        --�f�[�^���R�[�h�쐬����(PL/SQL�\�Ɋi�[���ꂽ�f�[�^���o�͂���APL/SQL�\���N���A�����)
        proc_out_data_record(
          1                   --�o�͎��(0:�����A1:�d���`�[)
         ,lt_tbl_supply       --�o�̓f�[�^���
         ,l_summary_rec       --���������v
         ,ov_errbuf           --�G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          --���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --���R�[�h�^����PL/SQL�\�ւ̊i�[(�����)
      --==============================================================
      IF ( lb_input_invoice ) THEN
        ln_idx_invoice := lt_tbl_invoice.COUNT + 1;
        lt_tbl_invoice( ln_idx_invoice ) := l_data_tab_invoice;
      END IF;
--
      --==============================================================
      --���R�[�h�^����PL/SQL�\�ւ̊i�[(�d���`�[)
      --==============================================================
      IF ( lb_input_supply ) THEN
        ln_idx_supply := lt_tbl_supply.COUNT + 1;
        lt_tbl_supply( ln_idx_supply ) := l_data_tab_supply;
      END IF;
--
      --==============================================================
      --�d���`�[���׍s�`�F�b�N(A-5.4)
      --==============================================================
      --�d���`�[���s�t���O��"Y"�̏ꍇ
      IF gb_supply THEN
        -- �sNo��5�𒴂���ꍇ�̓G���[
        IF ( lt_tbl_supply.COUNT > cn_max_row_supply ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_line_count_err
                       );
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --�W�v���(�����)�ւ̉��Z
      --==============================================================
      --�����
      IF ( lb_summary_invoice ) THEN
        --���������v
        l_summary_rec.total_itoen_can     := l_summary_rec.total_itoen_can    + ln_itoen_can   ;  --�ɓ�����
        l_summary_rec.total_itoen_dg      := l_summary_rec.total_itoen_dg     + ln_itoen_dg    ;  --�ɓ���DG
        l_summary_rec.total_itoen_g       := l_summary_rec.total_itoen_g      + ln_itoen_g     ;  --�ɓ���G
        l_summary_rec.total_itoen_hoka    := l_summary_rec.total_itoen_hoka   + ln_itoen_hoka  ;  --�ɓ�����
        l_summary_rec.total_hashiba_can   := l_summary_rec.total_hashiba_can  + ln_hashiba_can ;  --�����
        l_summary_rec.total_hashiba_dg    := l_summary_rec.total_hashiba_dg   + ln_hashiba_dg  ;  --����DG
        l_summary_rec.total_hashiba_g     := l_summary_rec.total_hashiba_g    + ln_hashiba_g   ;  --����G
        l_summary_rec.total_hashiba_hoka  := l_summary_rec.total_hashiba_hoka + ln_hashiba_hoka;  --���ꑼ
      END IF;
--
      --==============================================================
      --�W�v���(�d���`�[)�ւ̉��Z
      --==============================================================
      --�d���`�[
      IF ( lb_summary_supply ) THEN
        --�������ʁi���v�A�o���j
        l_summary_rec.total_sum_order_qty      := l_summary_rec.total_sum_order_qty      + l_data_tab_supply('SUM_ORDER_QTY');
        --�������z�i�o�ׁj
        l_summary_rec.total_shipping_cost_amt  := l_summary_rec.total_shipping_cost_amt  + l_data_tab_supply('SHIPPING_COST_AMT');
        --�������z�i�o�ׁj
        l_summary_rec.total_shipping_price_amt := l_summary_rec.total_shipping_price_amt + l_data_tab_supply('SHIPPING_PRICE_AMT');
      END IF;
--
      --==============================================================
      --���R�[�h�����C���N�������g
      --==============================================================
      gn_target_cnt := gn_target_cnt + 1;
      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- --�󒍂m���i�d�a�r�j��ۑ��i�G���[���b�Z�[�W�p�j
      lt_order_number := rec_main.order_no_ebs;
--
      --�󒍃w�b�_ID���ς�����ꍇ
      IF ( lt_header_id IS NULL ) OR ( lt_header_id <> rec_main.header_id ) THEN
        --���̓p�����[�^.�[�i�����s�敪���u�����s�v�̏ꍇ
        IF ( g_input_rec.publish_div = cv_not_issued ) THEN
          --==============================================================
          --�[�i�����s�t���O�X�V(A-5.9)
          --==============================================================
          BEGIN
--
            UPDATE oe_order_headers_all   ooha
            SET ooha.global_attribute1 = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                           g_input_rec.publish_flag_seq
                                                          ,ooha.global_attribute1
                                                          ,cv_publish )
            WHERE ooha.header_id       = rec_main.header_id
            ;
--
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf := SQLERRM;
              RAISE update_expt;
          END;
        END IF;
--
      END IF;
--
      -- �󒍃w�b�_ID��ۑ�
      lt_header_id    := rec_main.header_id;
--
    END LOOP data_record_loop;
--
    --==============================================================
    --�ŏI���R�[�h�ҏW����
    --==============================================================
    IF ( ln_data_cnt <> 0 )  THEN
      --==============================================================
      --�f�[�^���R�[�h�쐬����(�����)
      --==============================================================
      IF ( gb_invoice ) THEN
        --�f�[�^���R�[�h�쐬����(PL/SQL�\�Ɋi�[���ꂽ�f�[�^���o�͂���APL/SQL�\���N���A�����)
        proc_out_data_record(
          0                   --�o�͎��(0:�����A1:�d���`�[)
         ,lt_tbl_invoice      --�o�̓f�[�^���
         ,l_summary_rec       --���������v
         ,ov_errbuf           --�G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          --���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬����(�d���`�[)
      --==============================================================
      IF ( gb_supply ) THEN
        --�f�[�^���R�[�h�쐬����(PL/SQL�\�Ɋi�[���ꂽ�f�[�^���o�͂���APL/SQL�\���N���A�����)
        proc_out_data_record(
          1                   --�o�͎��(0:�����A1:�d���`�[)
         ,lt_tbl_supply       --�o�̓f�[�^���
         ,l_summary_rec       --���������v
         ,ov_errbuf           --�G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          --���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
    END IF;
--
    --==============================================================
    --�t�b�^���R�[�h�쐬����
    --==============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE proc_get_data_expt;
    END IF;
--
    --�Ώۃf�[�^������
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_apl_name
                     ,iv_name         => cv_msg_nodata
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** �X�V�G���[�n���h�� ***
    WHEN update_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => cv_apl_name
                        ,iv_name          => ct_msg_oe_header
                       );
      --�L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => ct_msg_invoice_number
       ,iv_data_value1 => lt_order_number
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_update_err
                    ,cv_tkn_table
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���b�N�G���[�n���h�� ***
    WHEN resource_busy_expt THEN
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�擾�����G���[�n���h�� ***
    WHEN proc_get_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    out_line(buff => cv_prg_name || ' start');
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
    -- �f�[�^���R�[�h�����̏�����
    gn_invoice_count   := 0;  --�����f�[�^���R�[�h����
    gn_supply_count    := 0;  --�d���`�[�f�[�^���R�[�h����
--
    --==============================================================
    --��������
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
--
    --==============================================================
    --�w�b�_���R�[�h�쐬����
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�f�[�^���R�[�h�擾����
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode := lv_retcode;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name                 IN     VARCHAR2,  --  1.�t�@�C����
    iv_chain_code                IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code               IN     VARCHAR2,  --  3.���[�R�[�h
    in_user_id                   IN     NUMBER,    --  4.���[�UID
    iv_dept_code                 IN     VARCHAR2,  --  5.�S�ݓX�R�[�h
    iv_dept_name                 IN     VARCHAR2,  --  6.�S�ݓX��
    iv_dept_store_code           IN     VARCHAR2,  --  7.�S�ݓX�X�܃R�[�h
    iv_edaban                    IN     VARCHAR2,  --  8.�}��
    iv_base_code                 IN     VARCHAR2,  --  9.���_�R�[�h
    iv_base_name                 IN     VARCHAR2,  -- 10.���_��
    iv_data_type_code            IN     VARCHAR2,  -- 11.���[��ʃR�[�h
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 12.�Ɩ��n��R�[�h
    iv_report_name               IN     VARCHAR2,  -- 13.���[�l��
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 14.�X�ܔ[�i��(FROM�j
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 15.�X�ܔ[�i���iTO�j
    iv_publish_div               IN     VARCHAR2,  -- 16.�[�i�����s�敪
    in_publish_flag_seq          IN     NUMBER     -- 17.�[�i�����s�t���O����
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
    l_input_rec g_input_rtype;
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    -- ���̓p�����[�^�̃Z�b�g
    -- ===============================================
    l_input_rec.file_name                 := iv_file_name;                     --  1.�t�@�C����
    l_input_rec.chain_code                := iv_chain_code;                    --  2.�`�F�[���X�R�[�h
    l_input_rec.report_code               := iv_report_code;                   --  3.���[�R�[�h
    l_input_rec.user_id                   := in_user_id;                       --  4.���[�UID
    l_input_rec.dept_code                 := iv_dept_code;                     --  5.�S�ݓX�R�[�h
    l_input_rec.dept_name                 := iv_dept_name;                     --  6.�S�ݓX��
    l_input_rec.dept_store_code           := iv_dept_store_code;               --  7.�S�ݓX�X�܃R�[�h
    l_input_rec.edaban                    := iv_edaban;                        --  8.�}��
    l_input_rec.base_code                 := iv_base_code;                     --  9.���_�R�[�h
    l_input_rec.base_name                 := iv_base_name;                     -- 10.���_��
    l_input_rec.data_type_code            := iv_data_type_code;                -- 11.���[��ʃR�[�h
    l_input_rec.ebs_business_series_code  := iv_ebs_business_series_code;      -- 12.�Ɩ��n��R�[�h
    l_input_rec.report_name               := iv_report_name;                   -- 13.���[�l��
    l_input_rec.shop_delivery_date_from   := iv_shop_delivery_date_from;       -- 14.�X�ܔ[�i��(FROM�j
    l_input_rec.shop_delivery_date_to     := iv_shop_delivery_date_to;         -- 15.�X�ܔ[�i���iTO�j
    l_input_rec.publish_div               := iv_publish_div;                   -- 16.�[�i�����s�敪
    l_input_rec.publish_flag_seq          := in_publish_flag_seq;              -- 17.�[�i�����s�t���O����
--
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
    --�S�ݓX�R�[�h(�����L�[)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_dept_code IS NOT NULL ) THEN
      l_input_rec.key_dept_code       := LPAD( iv_dept_code, cn_length_dept_code, cv_number0 );
    ELSE
      l_input_rec.key_dept_code       := NULL;
    END IF;
--    l_input_rec.key_dept_code       := LPAD( iv_dept_code, cn_length_dept_code, cv_number0 );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
    --�S�ݓX�X�܃R�[�h(�����L�[)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_dept_store_code IS NOT NULL ) THEN
      l_input_rec.key_dept_store_code := LPAD( iv_dept_store_code, cn_length_dept_store_code, cv_number0 );
    ELSE
      l_input_rec.key_dept_store_code := NULL;
    END IF;
--    l_input_rec.key_dept_store_code := LPAD( iv_dept_store_code, cn_length_dept_store_code, cv_number0 );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
    --�}��(�����L�[)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_edaban IS NOT NULL ) THEN
      l_input_rec.key_edaban          := SUBSTRB( iv_edaban, ( LENGTHB( iv_edaban ) - cn_length_edaban + 1 ) );
    ELSE
      l_input_rec.key_edaban          := NULL;
    END IF;
--    l_input_rec.key_edaban          := SUBSTRB( iv_edaban, ( LENGTHB( iv_edaban ) - cn_length_edaban + 1 ) );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
    g_input_rec := l_input_rec;
--
    -- ===============================================
    -- ���������̌Ăяo��
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
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
    -- ===============================================
    -- �I������
    -- ===============================================
    --�G���[�̏ꍇ�̓t�@�C�����N���[�Y����
    IF (lv_retcode = cv_status_error) THEN
      --�����t�@�C�����I�[�v������Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( gf_file_handle_invoice ) ) THEN
        UTL_FILE.FCLOSE( gf_file_handle_invoice );
      END IF;
      --�d���`�[�t�@�C�����I�[�v������Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( gf_file_handle_supply ) ) THEN
        UTL_FILE.FCLOSE( gf_file_handle_supply );
      END IF;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
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
    IF (lv_retcode = cv_status_normal) THEN
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
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --�G���[�����o��
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode   = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)   THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)  THEN
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
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOS014A09C;
/
