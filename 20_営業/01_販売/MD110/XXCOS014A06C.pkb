CREATE OR REPLACE PACKAGE BODY XXCOS014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A06C (body)
 * Description      : �[�i�\��v���[�t���X�g�쐬 
 * MD.050           : �[�i�\��v���[�t���X�g�쐬 MD050_COS_014_A06
 * Version          : 1.8
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
 *  2009/01/05    1.0   H.Noda           �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/13    1.2   T.Nakamura       [��QCOS_065] ���O�o�̓v���V�[�W��out_line�̖�����
 *  2009/02/16    1.3   T.Nakamura       [��QCOS_079] �v���t�@�C���ǉ��A�J�[�\��cur_data_record�̉��C��
 *  2009/02/17    1.4   T.Nakamura       [��QCOS_094] CSV�o�͍��ڂ̏C��
 *  2009/02/18    1.5   T.Nakamura       [��QCOS_095] ���̓p�����[�^�A�Z���^�[�[�i�����J�[�\��cur_data_record�̒��o�����ɒǉ�
 *  2009/02/19    1.6   T.Nakamura       [��QCOS_109] ���O�o�͂ɃG���[���b�Z�[�W���o�͓�
 *  2009/02/20    1.7   T.Nakamura       [��QCOS_110] �t�b�^���R�[�h�쐬�������s���̃G���[�n���h�����O��ǉ�
 *                                       [��QCOS_114] CSV�o�̓��R�[�h���o�����Ɏ菑�`�[�`���敪��ǉ�
 *  2009/02/24    1.8   T.Nakamura       [��QCOS_119] CSV�o�̓��R�[�h���o�����̍݌ɑg�DID���C��
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
  sale_class_expt         EXCEPTION;     --����敪�`�F�b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A06C'; -- �p�b�P�[�W��
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --�A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:�f�[�^���R�[�h���ʎq
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM';          --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(EBS�󒍊Ǘ�)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:��Ж�
  ct_prf_company_name_kana        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME_KANA';            --XXCOS:��Ж��J�i
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX�s�T�C�Y
  ct_prf_edi_order_source         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_ORDER_SOURCE';             --XXCOS:EDI�󒍃\�[�X
  ct_prf_organization_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';            --XXCOI:�݌ɑg�D�R�[�h
  ct_prf_case_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CASE_UOM_CODE';                --XXCOS:�P�[�X�P�ʃR�[�h
  ct_prf_bowl_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BALL_UOM_CODE';                --XXCOS:�{�[���P�ʃR�[�h
  ct_prf_base_manager_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BASE_MANAGER_CODE';            --XXCOS:�x�X���R�[�h
  ct_prf_set_of_books_id          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';                    --GL��v����ID
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
--
  --���b�Z�[�W
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:�f�[�^���R�[�h���ʎq
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00097';                    --XXCOS:���[OUTBOUND�o�̓f�B���N�g��
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:��Ж�
  ct_msg_company_name_kana        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00098';                    --XXCOS:��Ж��J�i
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX�s�T�C�Y
  ct_msg_edi_order_source         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00157';                    --XXCOS:EDI�󒍃\�[�X
  ct_msg_organization_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00048';                    --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_case_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00057';                    --XXCOS:�P�[�X�P�ʃR�[�h
  ct_msg_bowl_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00059';                    --XXCOS:�{�[���P�ʃR�[�h
  ct_msg_base_manager_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00100';                    --XXCOS:�x�X���R�[�h
  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --�v���t�@�C���擾�G���[
  ct_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00063';                    --���b�Z�[�W�p������.�݌ɑg�DID
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --���b�Z�[�W�p������.�ڋq�}�X�^
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --���b�Z�[�W�p������.�i�ڃ}�X�^
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --�擾�G���[
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --�}�X�^���o�^
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13151';                    --�p�����[�^�o�̓��b�Z�[�W1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13152';                    --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --�t�@�C���I�[�v���G���[���b�Z�[�W
  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00034';                    --����敪���݃G���[���b�Z�[�W
  ct_msg_sale_class_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00111';                    --����敪�G���[
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --���b�Z�[�W�p������.�ʏ��
  ct_msg_line_type10              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --���b�Z�[�W�p������.�ʏ�o��
  ct_msg_line_type20              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00147';                    --���b�Z�[�W�p������.���^
  ct_msg_line_type30              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00148';                    --���b�Z�[�W�p������.�l��
  ct_msg_set_of_books_id          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00060';                    --���b�Z�[�W�p������.GL��v����ID
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --�Ώۃf�[�^�Ȃ����b�Z�[�W
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --�t�@�C�����o�̓��b�Z�[�W
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00158';                    --���b�Z�[�W�p������.EDI��
  ct_msg_stockout_cancel_err      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00163';                    --���R�R�[�h�G���[
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --���b�Z�[�W�p������.MO:�c�ƒP��
-- 2009/02/16 T.Nakamura Ver.1.3 add end
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
  cv_tkn_order_no                 CONSTANT VARCHAR2(8)   := 'ORDER_NO';                             --�`�[�ԍ�
--
  --�Q�ƃ^�C�v
  ct_qc_sale_class                CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';                   --�Q�ƃ^�C�v.����敪
  ct_qc_consumption_tax_class     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CONSUMPTION_TAX_CLASS';        --�Q�ƃ^�C�v.����ŋ敪
--
  --���̑�
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                    --UTL_FILE.�I�[�v�����[�h
  cv_date_fmt                     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                             --���t����
  cv_time_fmt                     CONSTANT VARCHAR2(8)   := 'HH24MISS';                             --��������
  cv_booked                       CONSTANT VARCHAR2(6)   := 'BOOKED';                               --�X�e�[�^�X.�L����
  cv_cust_class_base              CONSTANT VARCHAR2(1)   := '1';                                    --�ڋq�敪.���_
  cv_cust_class_chain             CONSTANT VARCHAR2(2)   := '18';                                   --�ڋq�敪.�`�F�[���X
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)   := '10';                                   --�ڋq�敪.�ڋq
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)   := '12';                                   --�ڋq�敪.��l
  cv_number0                      CONSTANT VARCHAR2(1)   := '0';                                    --�Œ�l0
  cv_number00                     CONSTANT VARCHAR2(2)   := '00';                                   --�Œ�l00
  cv_number01                     CONSTANT VARCHAR2(2)   := '01';                                   --�Œ�l01
  cv_edi_item_code_div01          CONSTANT VARCHAR2(1)   := '1';                                    --EDI�A�g�i�ڋ敪.�ڋq
  cv_edi_item_code_div02          CONSTANT VARCHAR2(1)   := '2';                                    --EDI�A�g�i�ڋ敪.JAN�R�[�h
  cv_entity_code_line             CONSTANT VARCHAR2(4)   := 'LINE';                                 --�G���e�B�e�B�R�[�h.LINE
  cv_reason_type                  CONSTANT VARCHAR2(11)  := 'CANCEL_CODE';                          --���R�^�C�v.���
  cv_reason_flag_ok               CONSTANT VARCHAR2(1)   := 'Y';                                    --�I���\������R
  cv_reason_flag_ng               CONSTANT VARCHAR2(1)   := 'N';                                    --�I��s�\������R
  cv_err_reason_code              CONSTANT VARCHAR2(2)   := 'XX';                                   --�G���[������R
  cv_enabled_flag                 CONSTANT VARCHAR2(1)   := 'Y';                                    --�L���t���O.�L��
  cv_space                        CONSTANT VARCHAR2(2)   := '�@';                                   --�S�p�X�y�[�X
  cv_data_type_edi_order          CONSTANT VARCHAR2(2)   := '11';                                   --�f�[�^��R�[�h(��EDI)
  cv_stockout_cancel_flag         CONSTANT VARCHAR2(1)   := 'Y';                                    --���i���R����t���O.���
-- 2009/02/20 T.Nakamura Ver.1.7 add start
  cv_handwritten_slip_div_tg      CONSTANT VARCHAR2(1)   := '1';                                    --�菑�`�[�`���敪:�`���Ώ�
-- 2009/02/20 T.Nakamura Ver.1.7 add end
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[���R�[�h
  TYPE g_input_rtype IS RECORD (
    file_name                 VARCHAR2(100)                                       --IF�t�@�C����
   ,chain_code                xxcmm_cust_accounts.edi_chain_code%TYPE             --EDI�`�F�[���X�R�[�h
   ,report_code               xxcos_report_forms_register.report_code%TYPE        --���[�R�[�h
   ,user_id                   NUMBER                                              --���[�UID
   ,chain_name                hz_parties.party_name%TYPE                          --EDI�`�F�[���X��
   ,store_code                xxcmm_cust_accounts.store_code%TYPE                 --EDI�`�F�[���X�X�܃R�[�h
   ,base_code                 xxcmm_cust_accounts.delivery_base_code%TYPE         --�[�i���_�R�[�h
   ,base_name                 hz_parties.party_name%TYPE                          --�[�i���_��
   ,data_type_code            xxcos_report_forms_register.data_type_code%TYPE     --�f�[�^��R�[�h
   ,ebs_business_series_code  VARCHAR2(100)                                       --EBS�Ɩ��n��R�[�h
   ,info_div                  xxcos_report_forms_register.info_class%TYPE         --���敪
   ,report_name               xxcos_report_forms_register.report_name%TYPE        --���[�l��
   ,shop_delivery_date_from   VARCHAR2(100)                                       --�X�ܔ[�i��(FROM)
   ,shop_delivery_date_to     VARCHAR2(100)                                       --�X�ܔ[�i��(TO)
   ,center_delivery_date_from VARCHAR2(100)                                       --�Z���^�[�[�i��(FROM)
   ,center_delivery_date_to   VARCHAR2(100)                                       --�Z���^�[�[�i��(TO)
   ,bargain_class             fnd_lookup_values.attribute8%TYPE                   --��ԓ����敪
  );
--
  --�v���t�@�C���l�i�[���R�[�h
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --�w�b�_���R�[�h���ʎq
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --�f�[�^���R�[�h���ʎq
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --�t�b�^���R�[�h���ʎq
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --�o�̓f�B���N�g��
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --��Ж�
   ,company_name_kana        fnd_profile_option_values.profile_option_value%TYPE --��Ж��J�i
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE�ő�s�T�C�Y
   ,edi_order_source         fnd_profile_option_values.profile_option_value%TYPE --EDI�󒍃\�[�X
   ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --�݌ɑg�D�R�[�h
   ,case_uom_code            fnd_profile_option_values.profile_option_value%TYPE --�P�[�X�P�ʃR�[�h
   ,bowl_uom_code            fnd_profile_option_values.profile_option_value%TYPE --�{�[���P�ʃR�[�h
   ,base_manager_code        fnd_profile_option_values.profile_option_value%TYPE --�x�X���R�[�h
   ,set_of_books_id          fnd_profile_option_values.profile_option_value%TYPE --GL��v����ID
-- 2009/02/16 T.Nakamura Ver.1.3 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  );
  --�[�i���_���i�[���R�[�h
  TYPE g_base_rtype IS RECORD (
    base_name                hz_parties.party_name%TYPE                          --���_��
   ,base_name_kana           hz_parties.organization_name_phonetic%TYPE          --���_���J�i
   ,state                    hz_locations.state%TYPE                             --�s���{��
   ,city                     hz_locations.city%TYPE                              --�s�E��
   ,address1                 hz_locations.address1%TYPE                          --�Z���P
   ,address2                 hz_locations.address2%TYPE                          --�Z���Q
   ,phone_number             hz_locations.address_lines_phonetic%TYPE            --�d�b�ԍ�
   ,customer_code            xxcmm_cust_accounts.torihikisaki_code%TYPE          --�����R�[�h
   ,manager_name_kana        VARCHAR2(300)                                       --�����S����
   ,notfound_flag            VARCHAR2(1)                                         --���_�o�^�t���O
  );
  --EDI�`�F�[���X���i�[���R�[�h
  TYPE g_chain_rtype IS RECORD (
    chain_name               hz_parties.party_name%TYPE                          --EDI�`�F�[���X��
   ,chain_name_kana          hz_parties.organization_name_phonetic%TYPE          --EDI�`�F�[���X���J�i
   ,chain_store_code         xxcmm_cust_accounts.chain_store_code%TYPE           --EDI�`�F�[���X�R�[�h
   ,edi_item_code_div        xxcmm_cust_accounts.edi_item_code_div%TYPE          --EDI�A�g�i�ڃR�[�h�敪
   ,customer_id              xxcmm_cust_accounts.customer_id%TYPE                --�ڋqID
-- 2009/02/20 T.Nakamura Ver.1.7 add start
   ,handwritten_slip_div     xxcmm_cust_accounts.customer_id%TYPE                --�菑�`�[�`���敪
-- 2009/02/20 T.Nakamura Ver.1.7 add end
  );
  --���b�Z�[�W���i�[���R�[�h
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,header_type              fnd_new_messages.message_text%TYPE
   ,line_type10              fnd_new_messages.message_text%TYPE
   ,line_type20              fnd_new_messages.message_text%TYPE
   ,line_type30              fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE
  );
  --���̑����i�[���R�[�h
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --������
   ,proc_time                VARCHAR2(6)                                         --��������
   ,organization_id          NUMBER                                              --�݌ɑg�DID
   ,csv_header               VARCHAR2(32767)                                     --CSV�w�b�_
   ,process_date             DATE                                                --�Ɩ����t
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gf_file_handle             UTL_FILE.FILE_TYPE;                                 --�t�@�C���n���h��
  g_input_rec                g_input_rtype;                                      --���̓p�����[�^���
  g_prf_rec                  g_prf_rtype;                                        --�v���t�@�C�����
  g_base_rec                 g_base_rtype;                                       --�[�i���_���
  g_chain_rec                g_chain_rtype;                                      --EDI�`�F�[���X���
  g_msg_rec                  g_msg_rtype;                                        --���b�Z�[�W���
  g_other_rec                g_other_rtype;                                      --���̑����
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --���C�A�E�g��`���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                                 --�_�u���N�H�[�e�[�V����
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                                 --�J���}
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable; --�ϒ�
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order; --�󒍌n
  cv_found                   CONSTANT VARCHAR2(1) := '0';                                     --�o�^
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                                     --���o�^
  cv_bargain_class_all       CONSTANT VARCHAR2(1) := '0';                                     --��ԓ����敪(�S��)
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := FALSE;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_debug) THEN
--      dbms_output.put_line(buff);
--    ELSE
--      FND_FILE.PUT_LINE(
--         which  => which
--        ,buff   => buff
--      );
--    END IF;
    NULL;
-- 2009/02/13 T.Nakamura Ver.1.2 mod end
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �R���J�����g�v���O�������͍��ڂ̏o��
    --==============================================================
    --���̓p�����[�^1�`10�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name , ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.chain_name
                                          ,cv_tkn_prm6 , g_input_rec.store_code
                                          ,cv_tkn_prm7 , g_input_rec.base_code
                                          ,cv_tkn_prm8 , g_input_rec.base_name
                                          ,cv_tkn_prm9 , g_input_rec.data_type_code
                                          ,cv_tkn_prm10, g_input_rec.ebs_business_series_code
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --���̓p�����[�^11�`17�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,  ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.info_div
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm15, g_input_rec.center_delivery_date_from
                                          ,cv_tkn_prm16, g_input_rec.center_delivery_date_to
                                          ,cv_tkn_prm17, g_input_rec.bargain_class
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
    lv_errbuf_all                            VARCHAR2(32767);                                       --���O�o�̓��b�Z�[�W�i�[�ϐ�
-- 2009/02/19 T.Nakamura Ver.1.6 add end
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:��Ж��J�i)
    --==============================================================
    l_prf_rec.company_name_kana := FND_PROFILE.VALUE(ct_prf_company_name_kana);
    IF (l_prf_rec.company_name_kana IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name_kana);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:EDI�󒍃\�[�X)
    --==============================================================
    l_prf_rec.edi_order_source := FND_PROFILE.VALUE(ct_prf_edi_order_source);
    IF (l_prf_rec.edi_order_source IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_edi_order_source);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    l_prf_rec.organization_code := FND_PROFILE.VALUE(ct_prf_organization_code);
    IF (l_prf_rec.organization_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_organization_code);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�P�[�X�P�ʃR�[�h)
    --==============================================================
    l_prf_rec.case_uom_code := FND_PROFILE.VALUE(ct_prf_case_uom_code);
    IF (l_prf_rec.case_uom_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_case_uom_code);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�{�[���P�ʃR�[�h)
    --==============================================================
    l_prf_rec.bowl_uom_code := FND_PROFILE.VALUE(ct_prf_bowl_uom_code);
    IF (l_prf_rec.bowl_uom_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_bowl_uom_code);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�x�X���R�[�h)
    --==============================================================
    l_prf_rec.base_manager_code := FND_PROFILE.VALUE(ct_prf_base_manager_code);
    IF (l_prf_rec.base_manager_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_base_manager_code);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(GL��v����ID)
    --==============================================================
    l_prf_rec.set_of_books_id := FND_PROFILE.VALUE(ct_prf_set_of_books_id);
    IF (l_prf_rec.set_of_books_id IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_set_of_books_id);
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    --==============================================================
    -- �������t�A���������̎擾
    --==============================================================
    l_other_rec.proc_date    := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time    := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    -- �݌ɑg�DID�̎擾
    --==============================================================
    IF (l_prf_rec.organization_code IS NOT NULL) THEN
      l_other_rec.organization_id := xxcoi_common_pkg.get_organization_id(l_prf_rec.organization_code);
      IF (l_other_rec.organization_id IS NULL) THEN
        lb_error  := TRUE;
        lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_org_id);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_get_err
                      ,cv_tkn_data
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
      END IF;
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add start
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add end
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
    IF (lv_retcode != cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
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
    --�O���[�o���ϐ��̃Z�b�g
    --==============================================================
    g_prf_rec   := l_prf_rec;
    g_other_rec := l_other_rec;
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
-- 2009/02/19 T.Nakamura Ver.1.6 mod start
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.6 mod end
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
    lv_if_header VARCHAR2(32767);
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
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          g_prf_rec.rep_outbound_dir
                         ,g_input_rec.file_name
                         ,cv_utl_file_mode
                         ,g_prf_rec.utl_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,g_input_rec.file_name
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
     ,g_input_rec.chain_name                      --�`�F�[���X����
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
      RAISE global_api_expt;
    END IF;
--
    out_line(buff => 'if_header:' || lv_if_header);
    --==============================================================
    -- �w�b�_���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
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
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
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
    it_header_id  IN  oe_order_headers_all.header_id%TYPE
   ,i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_data_record VARCHAR2(32767);
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
    --�f�[�^���R�[�h�ҏW
    --==============================================================
    xxcos_common2_pkg.makeup_data_record(
      i_data_tab                --�o�̓f�[�^���
     ,cv_file_format            --�t�@�C���`��
     ,g_record_layout_tab       --���C�A�E�g��`���
     ,g_prf_rec.if_data         --�f�[�^���R�[�h���ʎq
     ,lv_data_record            --�f�[�^���R�[�h
     ,lv_errbuf                 --�G���[���b�Z�[�W
     ,lv_retcode                --���^�[���R�[�h
     ,lv_errmsg                 --���[�U�E�G���[���b�Z�[�W
    );
-- 2009/02/20 T.Nakamura Ver.1.7 add start
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.7 add end
--
    --==============================================================
    --�f�[�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_data_record);
--
    --==============================================================
    --���R�[�h�����C���N�������g
    --==============================================================
    gn_target_cnt := gn_target_cnt + 1;
    gn_normal_cnt := gn_normal_cnt + 1;
--
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
    IF gn_target_cnt > 0 THEN
      ln_rec_cnt := gn_target_cnt + 1;
    ELSE
      ln_rec_cnt := 0;
    END IF;
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
     ,ln_rec_cnt                  --���R�[�h����
     ,lv_retcode                  --���^�[���R�[�h
     ,lv_footer_record            --�o�͒l
-- 2009/02/20 T.Nakamura Ver.1.7 mod start
--     ,ov_errbuf                   --�G���[���b�Z�[�W
--     ,ov_errmsg                   --���[�U�E�G���[���b�Z�[�W
     ,lv_errbuf
     ,lv_errmsg
-- 2009/02/20 T.Nakamura Ver.1.7 mod end
    );
-- 2009/02/20 T.Nakamura Ver.1.7 add start
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.7 add end
--
    --==============================================================
    --�t�b�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle, lv_footer_record);
--
    --==============================================================
    --�t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(gf_file_handle);
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
--
    cv_init_cust_po_number             CONSTANT VARCHAR2(04) := 'INIT';           --�Œ�lINIT
    -- *** ���[�J���ϐ� ***
    lt_header_id                       oe_order_headers_all.header_id%TYPE;       --�w�b�_ID
    lt_tkn                             fnd_new_messages.message_text%TYPE;        --���b�Z�[�W�p������
    lv_break_key_old                   VARCHAR2(100);                             --���u���C�N�L�[
    lv_break_key_new                   VARCHAR2(100);                             --�V�u���C�N�L�[
    lt_cust_po_number                  oe_order_headers_all.cust_po_number%TYPE;  --�󒍃w�b�_�i�ڋq�����j
    lt_line_number                     oe_order_lines_all.line_number%TYPE;       --�󒍖��ׁi���הԍ��j
    lt_bargain_class                   fnd_lookup_values.attribute8%TYPE;         --��ԓ����敪
    lt_last_bargain_class              fnd_lookup_values.attribute8%TYPE;         --�O���ԓ����敪
    lt_last_invoice_number             xxcos_edi_headers.invoice_number%TYPE;     --�O��`�[�ԍ�
    lt_outbound_flag                   fnd_lookup_values.attribute10%TYPE;        --OUTBOUND��
    ln_reason_id                       NUMBER;                                    --���RID
    lt_stockout_cancel_flag            fnd_lookup_values.attribute1%TYPE;         --���i���R����t���O
    lb_error                           BOOLEAN;
    lb_mix_error_order                 BOOLEAN;
    lb_out_flag_error_order            BOOLEAN;
  --�`�[�W�v�G���A
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;                  --�o�̓f�[�^���
    TYPE l_mlt_tab IS TABLE OF xxcos_common2_pkg.g_layout_ttype INDEX BY BINARY_INTEGER;
    lt_tbl                     l_mlt_tab;
    lt_tbl_init                l_mlt_tab;
    ln_cnt                             NUMBER;                                    --�e�e�[�u���p�Y��
--
  --�`�[�v�W�v�G���A
    lt_invoice_indv_order_qty          NUMBER;                                    --�������ʁi�o���j
    lt_invoice_case_order_qty          NUMBER;                                    --�������ʁi�P�[�X�j
    lt_invoice_ball_order_qty          NUMBER;                                    --�������ʁi�{�[���j
    lt_invoice_sum_order_qty           NUMBER;                                    --�������ʁi���v�A�o���j
    lt_invoice_indv_shipping_qty       NUMBER;                                    --�o�א��ʁi�o���j
    lt_invoice_case_shipping_qty       NUMBER;                                    --�o�א��ʁi�P�[�X�j
    lt_invoice_ball_shipping_qty       NUMBER;                                    --�o�א��ʁi�{�[���j
    lt_invoice_pallet_shipping_qty     NUMBER;                                    --�o�א��ʁi�p���b�g�j
    lt_invoice_sum_shipping_qty        NUMBER;                                    --�o�א��ʁi���v�A�o���j
    lt_invoice_indv_stockout_qty       NUMBER;                                    --���i���ʁi�o���j
    lt_invoice_case_stockout_qty       NUMBER;                                    --���i���ʁi�P�[�X�j
    lt_invoice_ball_stockout_qty       NUMBER;                                    --���i���ʁi�{�[���j
    lt_invoice_sum_stockout_qty        NUMBER;                                    --���i���ʁi���v�A�o���j
    lt_invoice_case_qty                NUMBER;                                    --�P�[�X����
    lt_invoice_fold_container_qty      NUMBER;                                    --�I���R���i�o���j����
    lt_invoice_order_cost_amt          NUMBER;                                    --�������z�i�����j
    lt_invoice_shipping_cost_amt       NUMBER;                                    --�������z�i�o�ׁj
    lt_invoice_stockout_cost_amt       NUMBER;                                    --�������z�i���i�j
    lt_invoice_order_price_amt         NUMBER;                                    --�������z�i�����j
    lt_invoice_shipping_price_amt      NUMBER;                                    --�������z�i�o�ׁj
    lt_invoice_stockout_price_amt      NUMBER;                                    --�������z�i���i�j
-- 2009/02/19 T.Nakamura Ver.1.6 add start
    lv_errbuf_all                      VARCHAR2(32767);                           --���O�o�̓��b�Z�[�W�i�[�ϐ�
-- 2009/02/19 T.Nakamura Ver.1.6 add end
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
      SELECT *
      FROM   (
              SELECT TO_CHAR(ooha.header_id)                                            header_id                     --�w�b�_ID(�X�V�L�[)
                    ,ooha.cust_po_number                                                cust_po_number                --�󒍃w�b�_�i�ڋq�����j
                    ,xlvv.attribute8                                                    bargain_class                 --��ԓ����敪
                    ,xlvv.attribute10                                                   outbound_flag                 --OUTBOUND��
                    ,ore.reason_id                                                      reason_id                     --���RID
                    ,xlvv3.attribute1                                                   stockout_cancel_flag          --���i���R����t���O
                    ------------------------------------------------�w�b�_���------------------------------------------------
                    ,xeh.medium_class                                                   medium_class                  --�}�̋敪
                    ,i_input_rec.data_type_code                                         data_type_code                --�f�[�^��R�[�h
                    ,xeh.file_no                                                        file_no                       --�t�@�C���m��
                    ,xeh.info_class                                                     info_class                    --���敪
                    ,i_other_rec.proc_date                                              process_date                  --������
                    ,i_other_rec.proc_time                                              process_time                  --��������
                    ,i_input_rec.base_code                                              base_code                     --���_�i����j�R�[�h
                    ,i_base_rec.base_name                                               base_name                     --���_���i�������j
                    ,i_base_rec.base_name_kana                                          base_name_alt                 --���_���i�J�i�j
                    ,xeh.edi_chain_code                                                 edi_chain_code                --�d�c�h�`�F�[���X�R�[�h
                    ,i_chain_rec.chain_name                                             edi_chain_name                --�d�c�h�`�F�[���X���i�����j
                    ,i_chain_rec.chain_name_kana                                        edi_chain_name_alt            --�d�c�h�`�F�[���X���i�J�i�j
                    ,xeh.chain_code                                                     chain_code                    --�`�F�[���X�R�[�h
                    ,xeh.chain_name                                                     chain_name                    --�`�F�[���X���i�����j
                    ,xeh.chain_name_alt                                                 chain_name_alt                --�`�F�[���X���i�J�i�j
                    ,i_input_rec.report_code                                            report_code                   --���[�R�[�h
                    ,i_input_rec.report_name                                            report_name                   --���[�\����
                    ,hca.account_number                                                 customer_code                 --�ڋq�R�[�h
                    ,hp.party_name                                                      customer_name                 --�ڋq���i�����j
                    ,hp.organization_name_phonetic                                      customer_name_alt             --�ڋq���i�J�i�j
                    ,xeh.company_code                                                   company_code                  --�ЃR�[�h
                    ,xeh.company_name                                                   company_name                  --�Ж��i�����j
                    ,xeh.company_name_alt                                               company_name_alt              --�Ж��i�J�i�j
                    ,xeh.shop_code                                                      shop_code                     --�X�R�[�h
                    ,NVL(xeh.shop_name,NVL(xca.cust_store_name
                                          ,i_msg_rec.customer_notfound))                shop_name                     --�X���i�����j
                    ,NVL(xeh.shop_name_alt,hp.organization_name_phonetic)               shop_name_alt                 --�X���i�J�i�j
                    ,NVL(xeh.delivery_center_code,xca.deli_center_code)                 delivery_center_code          --�[���Z���^�[�R�[�h
                    ,NVL(delivery_center_name,xca.deli_center_name)                     delivery_center_name          --�[���Z���^�[���i�����j
                    ,xeh.delivery_center_name_alt                                       delivery_center_name_alt      --�[���Z���^�[���i�J�i�j
                    ,TO_CHAR(xeh.order_date,cv_date_fmt)                                order_date                    --������
                    ,NVL(i_input_rec.center_delivery_date_from
                        ,TO_CHAR(xeh.center_delivery_date,cv_date_fmt))                 center_delivery_date          --�Z���^�[�[�i��
                    ,TO_CHAR(xeh.result_delivery_date,cv_date_fmt)                      result_delivery_date          --���[�i��
                    ,TO_CHAR(xeh.shop_delivery_date,cv_date_fmt)                        shop_delivery_date            --�X�ܔ[�i��
                    ,TO_CHAR(xeh.data_creation_date_edi_data,cv_date_fmt)               data_creation_date_edi_data   --�f�[�^�쐬���i�d�c�h�f�[�^���j
                    ,xeh.data_creation_time_edi_data                                    data_creation_time_edi_data   --�f�[�^�쐬�����i�d�c�h�f�[�^���j
                    ,xeh.invoice_class                                                  invoice_class                 --�`�[�敪
                    ,xeh.small_classification_code                                      small_classification_code     --�����ރR�[�h
                    ,xeh.small_classification_name                                      small_classification_name     --�����ޖ�
                    ,xeh.middle_classification_code                                     middle_classification_code    --�����ރR�[�h
                    ,xeh.middle_classification_name                                     middle_classification_name    --�����ޖ�
                    ,xeh.big_classification_code                                        big_classification_code       --�啪�ރR�[�h
                    ,xeh.big_classification_name                                        big_classification_name       --�啪�ޖ�
                    ,xeh.other_party_department_code                                    other_party_department_code   --����敔��R�[�h
                    ,xeh.other_party_order_number                                       other_party_order_number      --����攭���ԍ�
                    ,xeh.check_digit_class                                              check_digit_class             --�`�F�b�N�f�W�b�g�L���敪
                    ,xeh.invoice_number                                                 invoice_number                --�`�[�ԍ�
                    ,xeh.check_digit                                                    check_digit                   --�`�F�b�N�f�W�b�g
                    ,TO_CHAR(xeh.close_date, cv_date_fmt)                               close_date                    --����
                    ,TO_CHAR(ooha.order_number)                                         order_no_ebs                  --�󒍂m���i�d�a�r�j
                    ,xlvv.attribute8                                                    ar_sale_class                 --�����敪
                    ,xeh.delivery_classe                                                delivery_classe               --�z���敪
                    ,xeh.opportunity_no                                                 opportunity_no                --�ւm��
                    ,NVL(xeh.contact_to, i_base_rec.phone_number)                       contact_to                    --�A����
                    ,xeh.route_sales                                                    route_sales                   --���[�g�Z�[���X
                    ,xeh.corporate_code                                                 corporate_code                --�@�l�R�[�h
                    ,xeh.maker_name                                                     maker_name                    --���[�J�[��
                    ,xeh.area_code                                                      area_code                     --�n��R�[�h
                    ,NVL2(xeh.area_code,xca.edi_district_name,NULL)                     area_name                     --�n�於�i�����j
                    ,NVL2(xeh.area_code,xca.edi_district_kana,NULL)                     area_name_alt                 --�n�於�i�J�i�j
                    ,NVL(xeh.vendor_code,xca.torihikisaki_code)                         vendor_code                   --�����R�[�h
                    ,DECODE(i_base_rec.notfound_flag
                           ,cv_notfound,i_base_rec.base_name
                           ,cv_found,i_prf_rec.company_name || cv_space ||  i_base_rec.base_name)
                                                                                        vendor_name                   --����於�i�����j
                    ,CASE
                       WHEN xeh.vendor_name1_alt IS NULL
                        AND xeh.vendor_name2_alt IS NULL THEN
                         i_prf_rec.company_name_kana
                       ELSE
                         xeh.vendor_name1_alt
                     END                                                                vendor_name1_alt              --����於�P�i�J�i�j
                    ,CASE
                       WHEN xeh.vendor_name1_alt IS NULL
                        AND xeh.vendor_name2_alt IS NULL THEN
                         i_base_rec.base_name_kana
                       ELSE
                         xeh.vendor_name2_alt
                     END                                                                vendor_name2_alt              --����於�Q�i�J�i�j
                    ,i_base_rec.phone_number                                            vendor_tel                    --�����s�d�k
                    ,NVL(xeh.vendor_charge,i_base_rec.manager_name_kana)                vendor_charge                 --�����S����
                    ,i_base_rec.state ||
                     i_base_rec.city ||
                     i_base_rec.address1 ||
                     i_base_rec.address2                                                vendor_address                --�����Z���i�����j
                    ,xeh.deliver_to_code_itouen                                         deliver_to_code_itouen        --�͂���R�[�h�i�ɓ����j
                    ,xeh.deliver_to_code_chain                                          deliver_to_code_chain         --�͂���R�[�h�i�`�F�[���X�j
                    ,xeh.deliver_to                                                     deliver_to                    --�͂���i�����j
                    ,xeh.deliver_to1_alt                                                deliver_to1_alt               --�͂���P�i�J�i�j
                    ,xeh.deliver_to2_alt                                                deliver_to2_alt               --�͂���Q�i�J�i�j
                    ,xeh.deliver_to_address                                             deliver_to_address            --�͂���Z���i�����j
                    ,xeh.deliver_to_address_alt                                         deliver_to_address_alt        --�͂���Z���i�J�i�j
                    ,xeh.deliver_to_tel                                                 deliver_to_tel                --�͂���s�d�k
                    ,xeh.balance_accounts_code                                          balance_accounts_code         --������R�[�h
                    ,xeh.balance_accounts_company_code                                  balance_accounts_company_code --������ЃR�[�h
                    ,xeh.balance_accounts_shop_code                                     balance_accounts_shop_code    --������X�R�[�h
                    ,xeh.balance_accounts_name                                          balance_accounts_name         --�����於�i�����j
                    ,xeh.balance_accounts_name_alt                                      balance_accounts_name_alt     --�����於�i�J�i�j
                    ,xeh.balance_accounts_address                                       balance_accounts_address      --������Z���i�����j
                    ,xeh.balance_accounts_address_alt                                   balance_accounts_address_alt  --������Z���i�J�i�j
                    ,xeh.balance_accounts_tel                                           balance_accounts_tel          --������s�d�k
                    ,TO_CHAR(xeh.order_possible_date, cv_date_fmt)                      order_possible_date           --�󒍉\��
                    ,TO_CHAR(xeh.permission_possible_date, cv_date_fmt)                 permission_possible_date      --���e�\��
                    ,TO_CHAR(xeh.forward_month, cv_date_fmt)                            forward_month                 --����N����
                    ,TO_CHAR(xeh.payment_settlement_date, cv_date_fmt)                  payment_settlement_date       --�x�����ϓ�
                    ,TO_CHAR(xeh.handbill_start_date_active, cv_date_fmt)               handbill_start_date_active    --�`���V�J�n��
                    ,TO_CHAR(xeh.billing_due_date, cv_date_fmt)                         billing_due_date              --��������
                    ,xeh.shipping_time                                                  shipping_time                 --�o�׎���
                    ,xeh.delivery_schedule_time                                         delivery_schedule_time        --�[�i�\�莞��
                    ,xeh.order_time                                                     order_time                    --��������
                    ,TO_CHAR(xeh.general_date_item1, cv_date_fmt)                       general_date_item1            --�ėp���t���ڂP
                    ,TO_CHAR(xeh.general_date_item2, cv_date_fmt)                       general_date_item2            --�ėp���t���ڂQ
                    ,TO_CHAR(xeh.general_date_item3, cv_date_fmt)                       general_date_item3            --�ėp���t���ڂR
                    ,TO_CHAR(xeh.general_date_item4, cv_date_fmt)                       general_date_item4            --�ėp���t���ڂS
                    ,TO_CHAR(xeh.general_date_item5, cv_date_fmt)                       general_date_item5            --�ėp���t���ڂT
                    ,xeh.arrival_shipping_class                                         arrival_shipping_class        --���o�׋敪
                    ,xeh.vendor_class                                                   vendor_class                  --�����敪
                    ,xeh.invoice_detailed_class                                         invoice_detailed_class        --�`�[����敪
                    ,xeh.unit_price_use_class                                           unit_price_use_class          --�P���g�p�敪
                    ,xeh.sub_distribution_center_code                                   sub_distribution_center_code  --�T�u�����Z���^�[�R�[�h
                    ,xeh.sub_distribution_center_name                                   sub_distribution_center_name  --�T�u�����Z���^�[�R�[�h��
                    ,xeh.center_delivery_method                                         center_delivery_method        --�Z���^�[�[�i���@
                    ,xeh.center_use_class                                               center_use_class              --�Z���^�[���p�敪
                    ,xeh.center_whse_class                                              center_whse_class             --�Z���^�[�q�ɋ敪
                    ,xeh.center_area_class                                              center_area_class             --�Z���^�[�n��敪
                    ,xeh.center_arrival_class                                           center_arrival_class          --�Z���^�[���׋敪
                    ,xeh.depot_class                                                    depot_class                   --�f�|�敪
                    ,xeh.tcdc_class                                                     tcdc_class                    --�s�b�c�b�敪
                    ,xeh.upc_flag                                                       upc_flag                      --�t�o�b�t���O
                    ,xeh.simultaneously_class                                           simultaneously_class          --��ċ敪
                    ,xeh.business_id                                                    business_id                   --�Ɩ��h�c
                    ,xeh.whse_directly_class                                            whse_directly_class           --�q���敪
                    ,xeh.premium_rebate_class                                           premium_rebate_class          --���ڎ��
                    ,xeh.item_type                                                      item_type                     --�i�i���ߋ敪
                    ,xeh.cloth_house_food_class                                         cloth_house_food_class        --�߉ƐH�敪
                    ,xeh.mix_class                                                      mix_class                     --���݋敪
                    ,xeh.stk_class                                                      stk_class                     --�݌ɋ敪
                    ,xeh.last_modify_site_class                                         last_modify_site_class        --�ŏI�C���ꏊ�敪
                    ,xeh.report_class                                                   report_class                  --���[�敪
                    ,xeh.addition_plan_class                                            addition_plan_class           --�ǉ��E�v��敪
                    ,xeh.registration_class                                             registration_class            --�o�^�敪
                    ,xeh.specific_class                                                 specific_class                --����敪
                    ,xeh.dealings_class                                                 dealings_class                --����敪
                    ,xeh.order_class                                                    order_class                   --�����敪
                    ,xeh.sum_line_class                                                 sum_line_class                --�W�v���׋敪
                    ,xeh.shipping_guidance_class                                        shipping_guidance_class       --�o�׈ē��ȊO�敪
                    ,xeh.shipping_class                                                 shipping_class                --�o�׋敪
                    ,xeh.product_code_use_class                                         product_code_use_class        --���i�R�[�h�g�p�敪
                    ,xeh.cargo_item_class                                               cargo_item_class              --�ϑ��i�敪
                    ,xeh.ta_class                                                       ta_class                      --�s�^�`�敪
                    ,xeh.plan_code                                                      plan_code                     --���R�[�h
                    ,xeh.category_code                                                  category_code                 --�J�e�S���[�R�[�h
                    ,xeh.category_class                                                 category_class                --�J�e�S���[�敪
                    ,xeh.carrier_means                                                  carrier_means                 --�^����i
                    ,xeh.counter_code                                                   counter_code                  --����R�[�h
                    ,xeh.move_sign                                                      move_sign                     --�ړ��T�C��
                    ,xeh.medium_class                                                   eos_handwriting_class         --�d�n�r�E�菑�敪
                    ,xeh.delivery_to_section_code                                       delivery_to_section_code      --�[�i��ۃR�[�h
                    ,xeh.invoice_detailed                                               invoice_detailed              --�`�[����
                    ,xeh.attach_qty                                                     attach_qty                    --�Y�t��
                    ,xeh.other_party_floor                                              other_party_floor             --�t���A
                    ,xeh.text_no                                                        text_no                       --�s�d�w�s�m��
                    ,xeh.in_store_code                                                  in_store_code                 --�C���X�g�A�R�[�h
                    ,xeh.tag_data                                                       tag_data                      --�^�O
                    ,xeh.competition_code                                               competition_code              --����
                    ,xeh.billing_chair                                                  billing_chair                 --��������
                    ,xeh.chain_store_code                                               chain_store_code              --�`�F�[���X�g�A�[�R�[�h
                    ,xeh.chain_store_short_name                                         chain_store_short_name        --�`�F�[���X�g�A�[�R�[�h��������
                    ,xeh.direct_delivery_rcpt_fee                                       direct_delivery_rcpt_fee      --���z���^���旿
                    ,xeh.bill_info                                                      bill_info                     --��`���
                    ,xeh.description                                                    description                   --�E�v
                    ,xeh.interior_code                                                  interior_code                 --�����R�[�h
                    ,xeh.order_info_delivery_category                                   order_info_delivery_category  --�������@�[�i�J�e�S���[
                    ,xeh.purchase_type                                                  purchase_type                 --�d���`��
                    ,xeh.delivery_to_name_alt                                           delivery_to_name_alt          --�[�i�ꏊ���i�J�i�j
                    ,xeh.shop_opened_site                                               shop_opened_site              --�X�o�ꏊ
                    ,xeh.counter_name                                                   counter_name                  --���ꖼ
                    ,xeh.extension_number                                               extension_number              --�����ԍ�
                    ,xeh.charge_name                                                    charge_name                   --�S���Җ�
                    ,xeh.price_tag                                                      price_tag                     --�l�D
                    ,xeh.tax_type                                                       tax_type                      --�Ŏ�
                    ,xeh.consumption_tax_class                                          consumption_tax_class         --����ŋ敪
                    ,xeh.brand_class                                                    brand_class                   --�a�q
                    ,xeh.id_code                                                        id_code                       --�h�c�R�[�h
                    ,xeh.department_code                                                department_code               --�S�ݓX�R�[�h
                    ,xeh.department_name                                                department_name               --�S�ݓX��
                    ,xeh.item_type_number                                               item_type_number              --�i�ʔԍ�
                    ,xeh.description_department                                         description_department        --�E�v�i�S�ݓX�j
                    ,xeh.price_tag_method                                               price_tag_method              --�l�D���@
                    ,xeh.reason_column                                                  reason_column                 --���R��
                    ,xeh.a_column_header                                                a_column_header               --�`���w�b�_
                    ,xeh.d_column_header                                                d_column_header               --�c���w�b�_
                    ,xeh.brand_code                                                     brand_code                    --�u�����h�R�[�h
                    ,xeh.line_code                                                      line_code                     --���C���R�[�h
                    ,xeh.class_code                                                     class_code                    --�N���X�R�[�h
                    ,xeh.a1_column                                                      a1_column                     --�`�|�P��
                    ,xeh.b1_column                                                      b1_column                     --�a�|�P��
                    ,xeh.c1_column                                                      c1_column                     --�b�|�P��
                    ,xeh.d1_column                                                      d1_column                     --�c�|�P��
                    ,xeh.e1_column                                                      e1_column                     --�d�|�P��
                    ,xeh.a2_column                                                      a2_column                     --�`�|�Q��
                    ,xeh.b2_column                                                      b2_column                     --�a�|�Q��
                    ,xeh.c2_column                                                      c2_column                     --�b�|�Q��
                    ,xeh.d2_column                                                      d2_column                     --�c�|�Q��
                    ,xeh.e2_column                                                      e2_column                     --�d�|�Q��
                    ,xeh.a3_column                                                      a3_column                     --�`�|�R��
                    ,xeh.b3_column                                                      b3_column                     --�a�|�R��
                    ,xeh.c3_column                                                      c3_column                     --�b�|�R��
                    ,xeh.d3_column                                                      d3_column                     --�c�|�R��
                    ,xeh.e3_column                                                      e3_column                     --�d�|�R��
                    ,xeh.f1_column                                                      f1_column                     --�e�|�P��
                    ,xeh.g1_column                                                      g1_column                     --�f�|�P��
                    ,xeh.h1_column                                                      h1_column                     --�g�|�P��
                    ,xeh.i1_column                                                      i1_column                     --�h�|�P��
                    ,xeh.j1_column                                                      j1_column                     --�i�|�P��
                    ,xeh.k1_column                                                      k1_column                     --�j�|�P��
                    ,xeh.l1_column                                                      l1_column                     --�k�|�P��
                    ,xeh.f2_column                                                      f2_column                     --�e�|�Q��
                    ,xeh.g2_column                                                      g2_column                     --�f�|�Q��
                    ,xeh.h2_column                                                      h2_column                     --�g�|�Q��
                    ,xeh.i2_column                                                      i2_column                     --�h�|�Q��
                    ,xeh.j2_column                                                      j2_column                     --�i�|�Q��
                    ,xeh.k2_column                                                      k2_column                     --�j�|�Q��
                    ,xeh.l2_column                                                      l2_column                     --�k�|�Q��
                    ,xeh.f3_column                                                      f3_column                     --�e�|�R��
                    ,xeh.g3_column                                                      g3_column                     --�f�|�R��
                    ,xeh.h3_column                                                      h3_column                     --�g�|�R��
                    ,xeh.i3_column                                                      i3_column                     --�h�|�R��
                    ,xeh.j3_column                                                      j3_column                     --�i�|�R��
                    ,xeh.k3_column                                                      k3_column                     --�j�|�R��
                    ,xeh.l3_column                                                      l3_column                     --�k�|�R��
                    ,xeh.chain_peculiar_area_header                                     chain_peculiar_area_header    --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
                    ,xeh.order_connection_number                                        order_connection_number       --�󒍊֘A�ԍ��i���j
                    ------------------------------------------------���׏��------------------------------------------------
                    ,TO_CHAR(xel.line_no)                                               line_no                       --�s�m��
                    ,CASE
                       WHEN xel.sum_order_qty 
                          - oola.ordered_quantity = 0 THEN
                         cv_number00
                       ELSE
                         DECODE(xlvv3.attribute1
                               ,cv_reason_flag_ok,ore.reason_code
                                                 ,cv_err_reason_code)
                     END                                                                stockout_class                --���i�敪
                    ,NULL                                                               stockout_reason               --���i���R
                    ,xel.item_code                                                      item_code                     --���i�R�[�h�i�ɓ����j
                    ,xel.product_code1                                                  product_code1                 --���i�R�[�h�P
                    ,xel.product_code2                                                  product_code2                 --���i�R�[�h�Q
                    ,CASE
-- 2009/02/17 T.Nakamura Ver.1.4 mod start
--                       WHEN xel.uom_code = i_prf_rec.case_uom_code THEN
                       WHEN xel.line_uom = i_prf_rec.case_uom_code THEN
-- 2009/02/17 T.Nakamura Ver.1.4 mod end
                         xsib.case_jan_code
                       ELSE
                         iimb.attribute21
                     END                                                                jan_code                      --�i�`�m�R�[�h
                    ,NVL(xel.itf_code, iimb.attribute22)                                itf_code                      --�h�s�e�R�[�h
                    ,xel.extension_itf_code                                             extension_itf_code            --�����h�s�e�R�[�h
                    ,xel.case_product_code                                              case_product_code             --�P�[�X���i�R�[�h
                    ,xel.ball_product_code                                              ball_product_code             --�{�[�����i�R�[�h
                    ,xel.product_code_item_type                                         product_code_item_type        --���i�R�[�h�i��
                    ,xhpc.item_div_h_code                                               prod_class                    --���i�敪
                    ,NVL(ximb.item_name,i_msg_rec.item_notfound)                        product_name                  --���i���i�����j
                    ,xel.product_name1_alt                                              product_name1_alt             --���i���P�i�J�i�j
                    ,xel.product_name2_alt                                              product_name2_alt             --���i���Q�i�J�i�j
                    ,xel.item_standard1                                                 item_standard1                --�K�i�P
                    ,xel.item_standard2                                                 item_standard2                --�K�i�Q
                    ,TO_CHAR(xel.qty_in_case)                                           qty_in_case                   --����
                    ,iimb.attribute11                                                   num_of_cases                  --�P�[�X����
                    ,TO_CHAR(NVL(xel.num_of_ball,xsib.bowl_inc_num))                    num_of_ball                   --�{�[������
                    ,xel.item_color                                                     item_color                    --�F
                    ,xel.item_size                                                      item_size                     --�T�C�Y
                    ,TO_CHAR(xel.expiration_date,cv_date_fmt)                           expiration_date               --�ܖ�������
                    ,TO_CHAR(xel.product_date,cv_date_fmt)                              product_date                  --������
                    ,TO_CHAR(xel.order_uom_qty)                                         order_uom_qty                 --�����P�ʐ�
                    ,TO_CHAR(xel.shipping_uom_qty)                                      shipping_uom_qty              --�o�גP�ʐ�
                    ,TO_CHAR(xel.packing_uom_qty)                                       packing_uom_qty               --����P�ʐ�
                    ,xel.deal_code                                                      deal_code                     --����
                    ,xel.deal_class                                                     deal_class                    --�����敪
                    ,xel.collation_code                                                 collation_code                --�ƍ�
-- 2009/02/17 T.Nakamura Ver.1.4 mod start
--                    ,xel.uom_code                                                       uom_code                      --�P��
                    ,xel.line_uom                                                       uom_code                      --�P��
-- 2009/02/17 T.Nakamura Ver.1.4 mod end
                    ,xel.unit_price_class                                               unit_price_class              --�P���敪
                    ,xel.parent_packing_number                                          parent_packing_number         --�e����ԍ�
                    ,xel.packing_number                                                 packing_number                --����ԍ�
                    ,xel.product_group_code                                             product_group_code            --���i�Q�R�[�h
                    ,xel.case_dismantle_flag                                            case_dismantle_flag           --�P�[�X��̕s�t���O
                    ,xel.case_class                                                     case_class                    --�P�[�X�敪
                    ,TO_CHAR(xel.indv_order_qty)                                        indv_order_qty                --�������ʁi�o���j
                    ,TO_CHAR(xel.case_order_qty)                                        case_order_qty                --�������ʁi�P�[�X�j
                    ,TO_CHAR(xel.ball_order_qty)                                        ball_order_qty                --�������ʁi�{�[���j
                    ,TO_CHAR(xel.sum_order_qty)                                         sum_order_qty                 --�������ʁi���v�A�o���j
                    ,CASE
                       WHEN oola.order_quantity_uom != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom != i_prf_rec.bowl_uom_code THEN
                         TO_CHAR(oola.ordered_quantity)
                       ELSE
                         cv_number0
                     END                                                                indv_shipping_qty             --�o�א��ʁi�o���j
                    ,CASE
                       WHEN oola.order_quantity_uom = i_prf_rec.case_uom_code THEN
                         TO_CHAR(oola.ordered_quantity)
                       ELSE
                         cv_number0
                     END                                                                case_shipping_qty             --�o�א��ʁi�P�[�X�j
                    ,CASE
                       WHEN oola.order_quantity_uom = i_prf_rec.bowl_uom_code THEN
                         TO_CHAR(oola.ordered_quantity)
                       ELSE
                         cv_number0
                     END                                                                ball_shipping_qty             --�o�א��ʁi�{�[���j
                    ,TO_CHAR(xel.pallet_shipping_qty)                                   pallet_shipping_qty           --�o�א��ʁi�p���b�g�j
                    ,TO_CHAR(oola.ordered_quantity)                                     sum_shipping_qty              --�o�א��ʁi���v�A�o���j
                    ,TO_CHAR(xel.indv_order_qty 
                           - oola.ordered_quantity)                                     indv_stockout_qty             --���i���ʁi�o���j
                    ,TO_CHAR(xel.case_order_qty
                           - oola.ordered_quantity)                                     case_stockout_qty             --���i���ʁi�P�[�X�j
                    ,TO_CHAR(xel.ball_order_qty 
                           - oola.ordered_quantity)                                     ball_stockout_qty             --���i���ʁi�{�[���j
                    ,TO_CHAR(xel.sum_order_qty
                           - oola.ordered_quantity)                                     sum_stockout_qty              --���i���ʁi���v�A�o���j
                    ,TO_CHAR(xel.case_qty)                                              case_qty                      --�P�[�X����
                    ,TO_CHAR(xel.fold_container_indv_qty)                               fold_container_indv_qty       --�I���R���i�o���j����
                    ,TO_CHAR(xel.order_unit_price)                                      order_unit_price              --���P���i�����j
                    ,TO_CHAR(oola.unit_selling_price)                                   shipping_unit_price           --���P���i�o�ׁj
                    ,TO_CHAR(xel.order_cost_amt)                                        order_cost_amt                --�������z�i�����j
                    ,TO_CHAR(oola.unit_selling_price
                           * oola.ordered_quantity)                                     shipping_cost_amt             --�������z�i�o�ׁj
                    ,TO_CHAR(xel.stockout_cost_amt)                                     stockout_cost_amt             --�������z�i���i�j
                    ,TO_CHAR(xel.selling_price)                                         selling_price                 --���P��
                    ,TO_CHAR(xel.order_price_amt)                                       order_price_amt               --�������z�i�����j
                    ,TO_CHAR(xel.shipping_price_amt)                                    shipping_price_amt            --�������z�i�o�ׁj
                    ,TO_CHAR(xel.stockout_price_amt)                                    stockout_price_amt            --�������z�i���i�j
                    ,TO_CHAR(xel.a_column_department)                                   a_column_department           --�`���i�S�ݓX�j
                    ,TO_CHAR(xel.d_column_department)                                   d_column_department           --�c���i�S�ݓX�j
                    ,TO_CHAR(xel.standard_info_depth)                                   standard_info_depth           --�K�i���E���s��
                    ,TO_CHAR(xel.standard_info_height)                                  standard_info_height          --�K�i���E����
                    ,TO_CHAR(xel.standard_info_width)                                   standard_info_width           --�K�i���E��
                    ,TO_CHAR(xel.standard_info_weight)                                  standard_info_weight          --�K�i���E�d��
                    ,xel.general_succeeded_item1                                        general_succeeded_item1       --�ėp���p�����ڂP
                    ,xel.general_succeeded_item2                                        general_succeeded_item2       --�ėp���p�����ڂQ
                    ,xel.general_succeeded_item3                                        general_succeeded_item3       --�ėp���p�����ڂR
                    ,xel.general_succeeded_item4                                        general_succeeded_item4       --�ėp���p�����ڂS
                    ,xel.general_succeeded_item5                                        general_succeeded_item5       --�ėp���p�����ڂT
                    ,xel.general_succeeded_item6                                        general_succeeded_item6       --�ėp���p�����ڂU
                    ,xel.general_succeeded_item7                                        general_succeeded_item7       --�ėp���p�����ڂV
                    ,xel.general_succeeded_item8                                        general_succeeded_item8       --�ėp���p�����ڂW
                    ,xel.general_succeeded_item9                                        general_succeeded_item9       --�ėp���p�����ڂX
                    ,xel.general_succeeded_item10                                       general_succeeded_item10      --�ėp���p�����ڂP�O
                    ,TO_CHAR(avtab.tax_rate)                                            general_add_item1             --�ėp�t�����ڂP(�ŗ�)
                    ,SUBSTRB(i_base_rec.phone_number, 1, 10)                            general_add_item2             --�ėp�t�����ڂQ
                    ,SUBSTRB(i_base_rec.phone_number, 11, 10)                           general_add_item3             --�ėp�t�����ڂR
                    ,xel.general_add_item4                                              general_add_item4             --�ėp�t�����ڂS
                    ,xel.general_add_item5                                              general_add_item5             --�ėp�t�����ڂT
                    ,xel.general_add_item6                                              general_add_item6             --�ėp�t�����ڂU
                    ,xel.general_add_item7                                              general_add_item7             --�ėp�t�����ڂV
                    ,xel.general_add_item8                                              general_add_item8             --�ėp�t�����ڂW
                    ,xel.general_add_item9                                              general_add_item9             --�ėp�t�����ڂX
                    ,xel.general_add_item10                                             general_add_item10            --�ėp�t�����ڂP�O
                    ,xel.chain_peculiar_area_line                                       chain_peculiar_area_line      --�`�F�[���X�ŗL�G���A�i���ׁj
                    ------------------------------------------------�t�b�^���------------------------------------------------
                    ,NULL                                                               invoice_indv_order_qty        --�i�`�[�v�j�������ʁi�o���j
                    ,NULL                                                               invoice_case_order_qty        --�i�`�[�v�j�������ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_order_qty        --�i�`�[�v�j�������ʁi�{�[���j
                    ,NULL                                                               invoice_sum_order_qty         --�i�`�[�v�j�������ʁi���v�A�o���j
                    ,NULL                                                               invoice_indv_shipping_qty     --�i�`�[�v�j�o�א��ʁi�o���j
                    ,NULL                                                               invoice_case_shipping_qty     --�i�`�[�v�j�o�א��ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_shipping_qty     --�i�`�[�v�j�o�א��ʁi�{�[���j
                    ,NULL                                                               invoice_pallet_shipping_qty   --�i�`�[�v�j�o�א��ʁi�p���b�g�j
                    ,NULL                                                               invoice_sum_shipping_qty      --�i�`�[�v�j�o�א��ʁi���v�A�o���j
                    ,NULL                                                               invoice_indv_stockout_qty     --�i�`�[�v�j���i���ʁi�o���j
                    ,NULL                                                               invoice_case_stockout_qty     --�i�`�[�v�j���i���ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_stockout_qty     --�i�`�[�v�j���i���ʁi�{�[���j
                    ,NULL                                                               invoice_sum_stockout_qty      --�i�`�[�v�j���i���ʁi���v�A�o���j
                    ,NULL                                                               invoice_case_qty              --�i�`�[�v�j�P�[�X����
                    ,NULL                                                               invoice_fold_container_qty    --�i�`�[�v�j�I���R���i�o���j����
                    ,NULL                                                               invoice_order_cost_amt        --�i�`�[�v�j�������z�i�����j
                    ,NULL                                                               invoice_shipping_cost_amt     --�i�`�[�v�j�������z�i�o�ׁj
                    ,NULL                                                               invoice_stockout_cost_amt     --�i�`�[�v�j�������z�i���i�j
                    ,NULL                                                               invoice_order_price_amt       --�i�`�[�v�j�������z�i�����j
                    ,NULL                                                               invoice_shipping_price_amt    --�i�`�[�v�j�������z�i�o�ׁj
                    ,NULL                                                               invoice_stockout_price_amt    --�i�`�[�v�j�������z�i���i�j
                    ,TO_CHAR(xeh.total_indv_order_qty)                                  total_indv_order_qty          --�i�����v�j�������ʁi�o���j
                    ,TO_CHAR(xeh.total_case_order_qty)                                  total_case_order_qty          --�i�����v�j�������ʁi�P�[�X�j
                    ,TO_CHAR(xeh.total_ball_order_qty)                                  total_ball_order_qty          --�i�����v�j�������ʁi�{�[���j
                    ,TO_CHAR(xeh.total_sum_order_qty)                                   total_sum_order_qty           --�i�����v�j�������ʁi���v�A�o���j
                    ,TO_CHAR(xeh.total_indv_shipping_qty)                               total_indv_shipping_qty       --�i�����v�j�o�א��ʁi�o���j
                    ,TO_CHAR(xeh.total_case_shipping_qty)                               total_case_shipping_qty       --�i�����v�j�o�א��ʁi�P�[�X�j
                    ,TO_CHAR(xeh.total_ball_shipping_qty)                               total_ball_shipping_qty       --�i�����v�j�o�א��ʁi�{�[���j
                    ,TO_CHAR(xeh.total_pallet_shipping_qty)                             total_pallet_shipping_qty     --�i�����v�j�o�א��ʁi�p���b�g�j
                    ,TO_CHAR(xeh.total_sum_shipping_qty)                                total_sum_shipping_qty        --�i�����v�j�o�א��ʁi���v�A�o���j
                    ,TO_CHAR(xeh.total_indv_stockout_qty)                               total_indv_stockout_qty       --�i�����v�j���i���ʁi�o���j
                    ,TO_CHAR(xeh.total_case_stockout_qty)                               total_case_stockout_qty       --�i�����v�j���i���ʁi�P�[�X�j
                    ,TO_CHAR(xeh.total_ball_stockout_qty)                               total_ball_stockout_qty       --�i�����v�j���i���ʁi�{�[���j
                    ,TO_CHAR(xeh.total_sum_stockout_qty)                                total_sum_stockout_qty        --�i�����v�j���i���ʁi���v�A�o���j
                    ,TO_CHAR(xeh.total_case_qty)                                        total_case_qty                --�i�����v�j�P�[�X����
                    ,TO_CHAR(xeh.total_fold_container_qty)                              total_fold_container_qty      --�i�����v�j�I���R���i�o���j����
                    ,TO_CHAR(xeh.total_order_cost_amt)                                  total_order_cost_amt          --�i�����v�j�������z�i�����j
                    ,TO_CHAR(xeh.total_shipping_cost_amt)                               total_shipping_cost_amt       --�i�����v�j�������z�i�o�ׁj
                    ,TO_CHAR(xeh.total_stockout_cost_amt)                               total_stockout_cost_amt       --�i�����v�j�������z�i���i�j
                    ,TO_CHAR(xeh.total_order_price_amt)                                 total_order_price_amt         --�i�����v�j�������z�i�����j
                    ,TO_CHAR(xeh.total_shipping_price_amt)                              total_shipping_price_amt      --�i�����v�j�������z�i�o�ׁj
                    ,TO_CHAR(xeh.total_stockout_price_amt)                              total_stockout_price_amt      --�i�����v�j�������z�i���i�j
                    ,TO_CHAR(xeh.total_line_qty)                                        total_line_qty                --�g�[�^���s��
                    ,TO_CHAR(xeh.total_invoice_qty)                                     total_invoice_qty             --�g�[�^���`�[����
                    ,xeh.chain_peculiar_area_footer                                     chain_peculiar_area_footer    --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
              FROM   xxcos_edi_headers                                                  xeh                           --EDI�w�b�_���e�[�u��
                    ,xxcos_edi_lines                                                    xel                           --EDI���׏��e�[�u��
                    ,oe_order_headers_all                                               ooha                          --�󒍃w�b�_���e�[�u��
                    ,oe_order_lines_all                                                 oola                          --�󒍖��׏��e�[�u��
                    ,(SELECT ore.reason_id                                              reason_id
                            ,ore.reason_code                                            reason_code
                            ,ore.entity_id                                              entity_id
                      FROM oe_reasons                                         ore
                          ,(SELECT entity_id,MAX(creation_date) creation_date
                            FROM   oe_reasons
                            WHERE  reason_type = cv_reason_type
                            AND    entity_code = cv_entity_code_line
                            GROUP BY entity_id
                           )                                                  ore_max
                      WHERE ore.entity_id     = ore_max.entity_id
                      AND   ore.creation_date = ore_max.creation_date
                     )                                                                  ore                           --�󒍗��R�r���[
                    ,xxcos_lookup_values_v                                              xlvv3                         --���R�R�[�h�}�X�^
                    ,oe_order_sources                                                   oos                           --�󒍃\�[�X�e�[�u��
                    ,xxcmm_cust_accounts                                                xca                           --�ڋq�}�X�^�A�h�I��
                    ,hz_cust_accounts                                                   hca                           --�ڋq�}�X�^
                    ,hz_parties                                                         hp                            --�p�[�e�B�}�X�^
                    ,ic_item_mst_b                                                      iimb                          --OPM�i�ڃ}�X�^
                    ,xxcmn_item_mst_b                                                   ximb                          --OPM�i�ڃ}�X�^�A�h�I��
                    ,mtl_system_items_b                                                 msib                          --DISC�i�ڃ}�X�^
                    ,xxcmm_system_items_b                                               xsib                          --DISC�i�ڃ}�X�^�A�h�I��
                    ,xxcos_head_prod_class_v                                            xhpc                          --�{�Џ��i�敪�r���[
                    ,xxcos_chain_store_security_v                                       xcss                          --�`�F�[���X�X�܃Z�L�����e�B�r���[
                    ,xxcos_lookup_values_v                                              xlvv                          --����敪�}�X�^
                    ,oe_transaction_types_tl                                            ottt_l                        --�󒍃^�C�v(����)
                    ,oe_transaction_types_tl                                            ottt_h                        --�󒍃^�C�v(�w�b�_)
                    ,xxcos_lookup_values_v                                              xlvv2                         --�ŃR�[�h�}�X�^
                    ,ar_vat_tax_all_b                                                   avtab                         --�ŗ��}�X�^
              --EDI�w�b�_���e�[�u�����o����
              WHERE  xeh.data_type_code         = cv_data_type_edi_order                                              --�f�[�^��R�[�h
              AND (
                     i_input_rec.info_div       IS NULL                                                               --���敪
                OR   i_input_rec.info_div       IS NOT NULL AND xeh.info_class = i_input_rec.info_div
              )
              AND    xeh.edi_chain_code         = i_input_rec.chain_code                                              --EDI�`�F�[���X�R�[�h
              AND (
                     i_input_rec.store_code     IS NOT NULL AND xeh.shop_code = i_input_rec.store_code                --�X�܃R�[�h
                AND  xeh.shop_code              = xcss.chain_store_code
                OR   i_input_rec.store_code     IS NULL     AND xeh.shop_code = xcss.chain_store_code
              )
              AND    NVL(TRUNC(xeh.shop_delivery_date)
                        ,NVL(TRUNC(xeh.center_delivery_date)
                            ,NVL(TRUNC(xeh.order_date)
                                ,TRUNC(xeh.data_creation_date_edi_data))))
                     BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
                     AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
-- 2009/02/18 T.Nakamura Ver.1.5 add start
              AND ( 
                    i_input_rec.center_delivery_date_from IS NULL AND i_input_rec.center_delivery_date_to IS NULL
                OR  (
                      xeh.center_delivery_date IS NOT NULL
                  AND (
                         i_input_rec.center_delivery_date_to   IS NULL
                    AND  TRUNC(xeh.center_delivery_date)       >= TO_DATE(i_input_rec.center_delivery_date_from, cv_date_fmt)
                    OR   i_input_rec.center_delivery_date_from IS NULL
                    AND  TRUNC(xeh.center_delivery_date)       <= TO_DATE(i_input_rec.center_delivery_date_to, cv_date_fmt)
                    OR   TRUNC(xeh.center_delivery_date)
                         BETWEEN TO_DATE(i_input_rec.center_delivery_date_from, cv_date_fmt)
                         AND     TO_DATE(i_input_rec.center_delivery_date_to, cv_date_fmt)
                  )
                )
              )
-- 2009/02/18 T.Nakamura Ver.1.5 add end
              --EDI���׏��e�[�u�����o����
              AND    xel.edi_header_info_id     = xeh.edi_header_info_id
              --�󒍃\�[�X�e�[�u�����o����
              AND    oos.description            = i_msg_rec.order_source                                              --�󒍃\�[�X
              AND    oos.enabled_flag           = cv_enabled_flag                                                     --�L���t���O
              --�󒍃^�C�v(�w�b�_)���o����
              AND    ottt_h.language            = USERENV('LANG')
              AND    ottt_h.source_lang         = USERENV('LANG')
              AND    ottt_h.description         = i_msg_rec.header_type
              --�󒍃^�C�v(����)���o����
              AND    ottt_l.language            = USERENV('LANG')
              AND    ottt_l.source_lang         = USERENV('LANG')
              AND    ottt_l.description         = i_msg_rec.line_type10
              --�󒍃w�b�_�e�[�u�����o����
              AND    ooha.orig_sys_document_ref = xeh.order_connection_number                                         --�O���V�X�e���󒍔ԍ� = �󒍊֘A�ԍ�
              AND    ooha.order_source_id       = oos.order_source_id                                                 --�󒍃\�[�XID
              AND    ooha.order_type_id         = ottt_h.transaction_type_id                                          --�󒍃w�b�_�^�C�v
              --�󒍖��׏��e�[�u�����o����
              AND    oola.header_id             = ooha.header_id                                                      --�w�b�_ID
              AND    oola.line_number           = xel.line_no                                                         --�sNo
              AND    oola.line_type_id          = ottt_l.transaction_type_id                                          --�󒍖��׃^�C�v
              --�󒍗��R�r���[���o����
              AND    ore.entity_id(+)           = oola.line_id
              --�󒍗��R�e�[�u�����o����
              AND    xlvv3.lookup_type(+)       = 'CANCEL_CODE'
              AND    xlvv3.lookup_code(+)       = ore.reason_code
              AND    i_other_rec.process_date
                BETWEEN NVL(xlvv3.start_date_active,i_other_rec.process_date)
                AND     NVL(xlvv3.end_date_active  ,i_other_rec.process_date)
              --�ڋq�}�X�^�A�h�I��(�X��)���o����
              AND    xca.chain_store_code(+)    = xeh.edi_chain_code                                                  --EDI�`�F�[���X�R�[�h
              AND    xca.store_code(+)          = xeh.shop_code                                                       --�X�܃R�[�h
              --�ڋq�}�X�^(�X��)���o����
              AND    hca.cust_account_id(+)     = xca.customer_id                                                     --�ڋqID
              AND   (hca.cust_account_id        IS NOT NULL
                AND  hca.customer_class_code    IN (cv_cust_class_chain_store, cv_cust_class_uesama)
                OR   hca.cust_account_id        IS NULL
              )                                                                                                       --�ڋq�敪
              --�p�[�e�B�}�X�^(�X��)���o����
              AND    hp.party_id(+)             = hca.party_id                                                        --�p�[�e�BID
              --OPM�i�ڃ}�X�^���o����
              AND    iimb.item_no(+)            = xel.item_code                                                       --�i�ڃR�[�h
              --OPM�i�ڃ}�X�^�A�h�I�����o����
              AND    ximb.item_id(+)            = iimb.item_id                                                        --�i��ID
              AND    NVL(xeh.shop_delivery_date
                        ,NVL(xeh.center_delivery_date
                            ,NVL(xeh.order_date
                                ,xeh.data_creation_date_edi_data)))
                BETWEEN NVL(ximb.start_date_active
                           ,NVL(xeh.shop_delivery_date
                               ,NVL(xeh.center_delivery_date
                                   ,NVL(xeh.order_date
                                       ,xeh.data_creation_date_edi_data))))
                AND     NVL(ximb.end_date_active
                            ,NVL(xeh.shop_delivery_date
                               ,NVL(xeh.center_delivery_date
                                   ,NVL(xeh.order_date
                                       ,xeh.data_creation_date_edi_data))))
              --DISC�i�ڃ}�X�^���o����
              AND    msib.segment1(+)           = xel.item_code                                                       --�i�ڃR�[�h
              AND    msib.organization_id(+)    = i_other_rec.organization_id                                         --�݌ɑg�DID
              --DISC�i�ڃA�h�I�����o����
              AND    xsib.item_code(+)          = msib.segment1                                                       --INV�i��ID
              --�{�Џ��i�敪�r���[���o����
              AND    xhpc.segment1(+)           = iimb.item_no                                                        --�i�ڃR�[�h
              --�`�F�[���X�X�܃Z�L�����e�B�r���[���o����
              AND    xcss.chain_code            = i_input_rec.chain_code                                              --�`�F�[���X�R�[�h
              AND    xcss.user_id               = i_input_rec.user_id                                                 --���[�UID
              --����敪�}�X�^���o����
              AND    xlvv.lookup_type(+)        = ct_qc_sale_class                                                    --�Q�ƃ^�C�v������敪
              AND    xlvv.lookup_code(+)        = oola.attribute5                                                     --�Q�ƃR�[�h������敪
              AND    i_other_rec.process_date
                BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
                AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
              AND  ( i_input_rec.bargain_class  = cv_bargain_class_all
                OR   i_input_rec.bargain_class != cv_bargain_class_all
                AND  i_input_rec.bargain_class  = xlvv.attribute8
              )
              --�ŃR�[�h�}�X�^���o����
              AND xlvv2.lookup_type(+)          = ct_qc_consumption_tax_class
              AND xlvv2.attribute3(+)           = xca.tax_div
              AND    NVL(xeh.shop_delivery_date
                        ,NVL(xeh.center_delivery_date
                            ,NVL(xeh.order_date
                                ,xeh.data_creation_date_edi_data)))
              BETWEEN NVL(xlvv2.start_date_active
                         ,NVL(xeh.shop_delivery_date
                             ,NVL(xeh.center_delivery_date
                                 ,NVL(xeh.order_date
                               ,xeh.data_creation_date_edi_data))))
              AND     NVL(xlvv2.end_date_active
                          ,NVL(xeh.shop_delivery_date
                             ,NVL(xeh.center_delivery_date
                                 ,NVL(xeh.order_date
                                     ,xeh.data_creation_date_edi_data))))
              --�ŗ��}�X�^���o����
              AND avtab.tax_code(+)             = xlvv2.attribute2
              AND avtab.set_of_books_id(+)      = i_prf_rec.set_of_books_id
-- 2009/02/16 T.Nakamura Ver.1.3 add start
              AND   avtab.org_id                   = i_prf_rec.org_id                                                 --MO:�c�ƒP��
              AND   avtab.enabled_flag             = cv_enabled_flag                                                  --�g�p�\�t���O
              AND   i_other_rec.process_date
                BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
                AND     NVL( avtab.end_date   ,i_other_rec.process_date )
              AND   ooha.org_id                 = i_prf_rec.org_id                                                    --MO:�c�ƒP��
              AND   oola.org_id                 = ooha.org_id                                                         --MO:�c�ƒP��
-- 2009/02/16 T.Nakamura Ver.1.3 add end
              UNION ALL
              SELECT TO_CHAR(ooha.header_id)                                            header_id                     --�w�b�_ID(�X�V�L�[)
                    ,ooha.cust_po_number                                                cust_po_number                --�󒍃w�b�_�i�ڋq�����j
                    ,xlvv.attribute8                                                    bargain_class                 --��ԓ����敪
                    ,xlvv.attribute12                                                   outbound_flag                 --EDI�OOUTBOUND��
                    ,NULL                                                                reason_id                     --���RID(�_�~�[)
                    ,cv_stockout_cancel_flag                                            stockout_cancel_flag          --���i���R����t���O
                    ------------------------------------------------�w�b�_���------------------------------------------------
                    ,cv_number01                                                        medium_class                  --�}�̋敪
                    ,i_input_rec.data_type_code                                         data_type_code                --�f�[�^��R�[�h
                    ,cv_number00                                                        file_no                       --�t�@�C���m��
                    ,NULL                                                               info_class                    --���敪
                    ,i_other_rec.proc_date                                              process_date                  --������
                    ,i_other_rec.proc_time                                              process_time                  --��������
                    ,i_input_rec.base_code                                              base_code                     --���_�i����j�R�[�h
                    ,i_base_rec.base_name                                               base_name                     --���_���i�������j
                    ,i_base_rec.base_name_kana                                          base_name_alt                 --���_���i�J�i�j
                    ,i_chain_rec.chain_store_code                                       edi_chain_code                --�d�c�h�`�F�[���X�R�[�h
                    ,i_chain_rec.chain_name                                             edi_chain_name                --�d�c�h�`�F�[���X���i�����j
                    ,i_chain_rec.chain_name_kana                                        edi_chain_name_alt            --�d�c�h�`�F�[���X���i�J�i�j
                    ,NULL                                                               chain_code                    --�`�F�[���X�R�[�h
                    ,NULL                                                               chain_name                    --�`�F�[���X���i�����j
                    ,NULL                                                               chain_name_alt                --�`�F�[���X���i�J�i�j
                    ,i_input_rec.report_code                                            report_code                   --���[�R�[�h
                    ,i_input_rec.report_name                                            report_name                   --���[�\����
                    ,ooha.account_number                                                 customer_code                 --�ڋq�R�[�h
                    ,hp.party_name                                                      customer_name                 --�ڋq���i�����j
                    ,hp.organization_name_phonetic                                      customer_name_alt             --�ڋq���i�J�i�j
                    ,NULL                                                               company_code                  --�ЃR�[�h
                    ,NULL                                                               company_name                  --�Ж��i�����j
                    ,NULL                                                               company_name_alt              --�Ж��i�J�i�j
                    ,ooha.store_code                                                     shop_code                     --�X�R�[�h
                    ,NVL(ooha.cust_store_name,i_msg_rec.customer_notfound)               shop_name                     --�X���i�����j
                    ,hp.organization_name_phonetic                                      shop_name_alt                 --�X���i�J�i�j
                    ,ooha.deli_center_code                                               delivery_center_code          --�[���Z���^�[�R�[�h
                    ,ooha.deli_center_name                                               delivery_center_name          --�[���Z���^�[���i�����j
                    ,NULL                                                               delivery_center_name_alt      --�[���Z���^�[���i�J�i�j
                    ,TO_CHAR(ooha.ordered_date,cv_date_fmt)                             order_date                    --������
                    ,i_input_rec.center_delivery_date_from                              center_delivery_date          --�Z���^�[�[�i��
                    ,NULL                                                               result_delivery_date          --���[�i��
                    ,TO_CHAR(ooha.request_date,cv_date_fmt)                             shop_delivery_date            --�X�ܔ[�i��
                    ,NULL                                                               data_creation_date_edi_data   --�f�[�^�쐬���i�d�c�h�f�[�^���j
                    ,NULL                                                               data_creation_time_edi_data   --�f�[�^�쐬�����i�d�c�h�f�[�^���j
                    ,xlvv.attribute8                                                    invoice_class                 --�`�[�敪
                    ,NULL                                                               small_classification_code     --�����ރR�[�h
                    ,NULL                                                               small_classification_name     --�����ޖ�
                    ,NULL                                                               middle_classification_code    --�����ރR�[�h
                    ,NULL                                                               middle_classification_name    --�����ޖ�
                    ,NULL                                                               big_classification_code       --�啪�ރR�[�h
                    ,NULL                                                               big_classification_name       --�啪�ޖ�
                    ,NULL                                                               other_party_department_code   --����敔��R�[�h
                    ,ooha.attribute19                                                   other_party_order_number      --����攭���ԍ�
                    ,NULL                                                               check_digit_class             --�`�F�b�N�f�W�b�g�L���敪
                    ,ooha.cust_po_number                                                invoice_number                --�`�[�ԍ�
                    ,NULL                                                               check_digit                   --�`�F�b�N�f�W�b�g
                    ,NULL                                                               close_date                    --����
                    ,TO_CHAR(ooha.order_number)                                         order_no_ebs                  --�󒍂m���i�d�a�r�j
                    ,xlvv.attribute8                                                    ar_sale_class                 --�����敪
                    ,NULL                                                               delivery_classe               --�z���敪
                    ,NULL                                                               opportunity_no                --�ւm��
                    ,i_base_rec.phone_number                                            contact_to                    --�A����
                    ,NULL                                                               route_sales                   --���[�g�Z�[���X
                    ,NULL                                                               corporate_code                --�@�l�R�[�h
                    ,NULL                                                               maker_name                    --���[�J�[��
                    ,NULL                                                               area_code                     --�n��R�[�h
                    ,NULL                                                               area_name                     --�n�於�i�����j
                    ,NULL                                                               area_name_alt                 --�n�於�i�J�i�j
                    ,ooha.torihikisaki_code                                              vendor_code                   --�����R�[�h
                    ,DECODE(i_base_rec.notfound_flag
                           ,cv_notfound,i_base_rec.base_name
                           ,cv_found,i_prf_rec.company_name || cv_space ||  i_base_rec.base_name)    vendor_name      --����於�i�����j
                    ,i_prf_rec.company_name_kana                                        vendor_name1_alt              --����於�P�i�J�i�j
                    ,i_base_rec.base_name_kana                                          vendor_name2_alt              --����於�Q�i�J�i�j
                    ,i_base_rec.phone_number                                            vendor_tel                    --�����s�d�k
                    ,i_base_rec.manager_name_kana                                       vendor_charge                 --�����S����
                    ,i_base_rec.state ||
                     i_base_rec.city ||
                     i_base_rec.address1 ||
                     i_base_rec.address2                                                vendor_address                --�����Z���i�����j
                    ,NULL                                                               deliver_to_code_itouen        --�͂���R�[�h�i�ɓ����j
                    ,NULL                                                               deliver_to_code_chain         --�͂���R�[�h�i�`�F�[���X�j
                    ,NULL                                                               deliver_to                    --�͂���i�����j
                    ,NULL                                                               deliver_to1_alt               --�͂���P�i�J�i�j
                    ,NULL                                                               deliver_to2_alt               --�͂���Q�i�J�i�j
                    ,NULL                                                               deliver_to_address            --�͂���Z���i�����j
                    ,NULL                                                               deliver_to_address_alt        --�͂���Z���i�J�i�j
                    ,NULL                                                               deliver_to_tel                --�͂���s�d�k
                    ,NULL                                                               balance_accounts_code         --������R�[�h
                    ,NULL                                                               balance_accounts_company_code --������ЃR�[�h
                    ,NULL                                                               balance_accounts_shop_code    --������X�R�[�h
                    ,NULL                                                               balance_accounts_name         --�����於�i�����j
                    ,NULL                                                                balance_accounts_name_alt     --�����於�i�J�i�j
                    ,NULL                                                               balance_accounts_address      --������Z���i�����j
                    ,NULL                                                               balance_accounts_address_alt  --������Z���i�J�i�j
                    ,NULL                                                               balance_accounts_tel          --������s�d�k
                    ,NULL                                                               order_possible_date           --�󒍉\��
                    ,NULL                                                               permission_possible_date      --���e�\��
                    ,NULL                                                               forward_month                 --����N����
                    ,NULL                                                               payment_settlement_date       --�x�����ϓ�
                    ,NULL                                                               handbill_start_date_active    --�`���V�J�n��
                    ,NULL                                                               billing_due_date              --��������
                    ,NULL                                                               shipping_time                 --�o�׎���
                    ,NULL                                                               delivery_schedule_time        --�[�i�\�莞��
                    ,NULL                                                               order_time                    --��������
                    ,NULL                                                               general_date_item1            --�ėp���t���ڂP
                    ,NULL                                                               general_date_item2            --�ėp���t���ڂQ
                    ,NULL                                                               general_date_item3            --�ėp���t���ڂR
                    ,NULL                                                               general_date_item4            --�ėp���t���ڂS
                    ,NULL                                                               general_date_item5            --�ėp���t���ڂT
                    ,NULL                                                               arrival_shipping_class        --���o�׋敪
                    ,NULL                                                               vendor_class                  --�����敪
                    ,NULL                                                               invoice_detailed_class        --�`�[����敪
                    ,NULL                                                               unit_price_use_class          --�P���g�p�敪
                    ,NULL                                                               sub_distribution_center_code  --�T�u�����Z���^�[�R�[�h
                    ,NULL                                                               sub_distribution_center_name  --�T�u�����Z���^�[�R�[�h��
                    ,NULL                                                               center_delivery_method        --�Z���^�[�[�i���@
                    ,NULL                                                               center_use_class              --�Z���^�[���p�敪
                    ,NULL                                                               center_whse_class             --�Z���^�[�q�ɋ敪
                    ,NULL                                                               center_area_class             --�Z���^�[�n��敪
                    ,NULL                                                               center_arrival_class          --�Z���^�[���׋敪
                    ,NULL                                                               depot_class                   --�f�|�敪
                    ,NULL                                                               tcdc_class                    --�s�b�c�b�敪
                    ,NULL                                                               upc_flag                      --�t�o�b�t���O
                    ,NULL                                                               simultaneously_class          --��ċ敪
                    ,NULL                                                               business_id                   --�Ɩ��h�c
                    ,NULL                                                               whse_directly_class           --�q���敪
                    ,NULL                                                               premium_rebate_class          --���ڎ��
                    ,NULL                                                               item_type                     --�i�i���ߋ敪
                    ,NULL                                                               cloth_house_food_class        --�߉ƐH�敪
                    ,NULL                                                               mix_class                     --���݋敪
                    ,NULL                                                               stk_class                     --�݌ɋ敪
                    ,NULL                                                               last_modify_site_class        --�ŏI�C���ꏊ�敪
                    ,NULL                                                               report_class                  --���[�敪
                    ,NULL                                                               addition_plan_class           --�ǉ��E�v��敪
                    ,NULL                                                               registration_class            --�o�^�敪
                    ,NULL                                                               specific_class                --����敪
                    ,NULL                                                               dealings_class                --����敪
                    ,NULL                                                               order_class                   --�����敪
                    ,NULL                                                               sum_line_class                --�W�v���׋敪
                    ,NULL                                                               shipping_guidance_class       --�o�׈ē��ȊO�敪
                    ,NULL                                                               shipping_class                --�o�׋敪
                    ,NULL                                                               product_code_use_class        --���i�R�[�h�g�p�敪
                    ,NULL                                                               cargo_item_class              --�ϑ��i�敪
                    ,NULL                                                               ta_class                      --�s�^�`�敪
                    ,NULL                                                               plan_code                     --���R�[�h
                    ,NULL                                                               category_code                 --�J�e�S���[�R�[�h
                    ,NULL                                                               category_class                --�J�e�S���[�敪
                    ,NULL                                                               carrier_means                 --�^����i
                    ,NULL                                                               counter_code                  --����R�[�h
                    ,NULL                                                               move_sign                     --�ړ��T�C��
                    ,cv_number01                                                        eos_handwriting_class         --�d�n�r�E�菑�敪
                    ,NULL                                                               delivery_to_section_code      --�[�i��ۃR�[�h
                    ,NULL                                                               invoice_detailed              --�`�[����
                    ,NULL                                                               attach_qty                    --�Y�t��
                    ,NULL                                                               other_party_floor             --�t���A
                    ,NULL                                                               text_no                       --�s�d�w�s�m��
                    ,NULL                                                               in_store_code                 --�C���X�g�A�R�[�h
                    ,NULL                                                               tag_data                      --�^�O
                    ,NULL                                                               competition_code              --����
                    ,NULL                                                               billing_chair                 --��������
                    ,NULL                                                               chain_store_code              --�`�F�[���X�g�A�[�R�[�h
                    ,NULL                                                               chain_store_short_name        --�`�F�[���X�g�A�[�R�[�h��������
                    ,NULL                                                               direct_delivery_rcpt_fee      --���z���^���旿
                    ,NULL                                                               bill_info                     --��`���
                    ,NULL                                                               description                   --�E�v
                    ,NULL                                                               interior_code                 --�����R�[�h
                    ,NULL                                                               order_info_delivery_category  --�������@�[�i�J�e�S���[
                    ,NULL                                                               purchase_type                 --�d���`��
                    ,NULL                                                               delivery_to_name_alt          --�[�i�ꏊ���i�J�i�j
                    ,NULL                                                               shop_opened_site              --�X�o�ꏊ
                    ,NULL                                                               counter_name                  --���ꖼ
                    ,NULL                                                               extension_number              --�����ԍ�
                    ,NULL                                                               charge_name                   --�S���Җ�
                    ,NULL                                                               price_tag                     --�l�D
                    ,NULL                                                               tax_type                      --�Ŏ�
                    ,NULL                                                               consumption_tax_class         --����ŋ敪
                    ,NULL                                                               brand_class                   --�a�q
                    ,NULL                                                               id_code                       --�h�c�R�[�h
                    ,NULL                                                               department_code               --�S�ݓX�R�[�h
                    ,NULL                                                               department_name               --�S�ݓX��
                    ,NULL                                                               item_type_number              --�i�ʔԍ�
                    ,NULL                                                               description_department        --�E�v�i�S�ݓX�j
                    ,NULL                                                               price_tag_method              --�l�D���@
                    ,NULL                                                               reason_column                 --���R��
                    ,NULL                                                               a_column_header               --�`���w�b�_
                    ,NULL                                                               d_column_header               --�c���w�b�_
                    ,NULL                                                               brand_code                    --�u�����h�R�[�h
                    ,NULL                                                               line_code                     --���C���R�[�h
                    ,NULL                                                               class_code                    --�N���X�R�[�h
                    ,NULL                                                               a1_column                     --�`�|�P��
                    ,NULL                                                               b1_column                     --�a�|�P��
                    ,NULL                                                               c1_column                     --�b�|�P��
                    ,NULL                                                               d1_column                     --�c�|�P��
                    ,NULL                                                               e1_column                     --�d�|�P��
                    ,NULL                                                               a2_column                     --�`�|�Q��
                    ,NULL                                                               b2_column                     --�a�|�Q��
                    ,NULL                                                               c2_column                     --�b�|�Q��
                    ,NULL                                                               d2_column                     --�c�|�Q��
                    ,NULL                                                               e2_column                     --�d�|�Q��
                    ,NULL                                                               a3_column                     --�`�|�R��
                    ,NULL                                                               b3_column                     --�a�|�R��
                    ,NULL                                                               c3_column                     --�b�|�R��
                    ,NULL                                                               d3_column                     --�c�|�R��
                    ,NULL                                                               e3_column                     --�d�|�R��
                    ,NULL                                                               f1_column                     --�e�|�P��
                    ,NULL                                                               g1_column                     --�f�|�P��
                    ,NULL                                                               h1_column                     --�g�|�P��
                    ,NULL                                                               i1_column                     --�h�|�P��
                    ,NULL                                                               j1_column                     --�i�|�P��
                    ,NULL                                                               k1_column                     --�j�|�P��
                    ,NULL                                                               l1_column                     --�k�|�P��
                    ,NULL                                                               f2_column                     --�e�|�Q��
                    ,NULL                                                               g2_column                     --�f�|�Q��
                    ,NULL                                                               h2_column                     --�g�|�Q��
                    ,NULL                                                               i2_column                     --�h�|�Q��
                    ,NULL                                                               j2_column                     --�i�|�Q��
                    ,NULL                                                               k2_column                     --�j�|�Q��
                    ,NULL                                                               l2_column                     --�k�|�Q��
                    ,NULL                                                               f3_column                     --�e�|�R��
                    ,NULL                                                               g3_column                     --�f�|�R��
                    ,NULL                                                               h3_column                     --�g�|�R��
                    ,NULL                                                               i3_column                     --�h�|�R��
                    ,NULL                                                               j3_column                     --�i�|�R��
                    ,NULL                                                               k3_column                     --�j�|�R��
                    ,NULL                                                               l3_column                     --�k�|�R��
                    ,NULL                                                               chain_peculiar_area_header    --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
                    ,NULL                                                               order_connection_number       --�󒍊֘A�ԍ��i���j
                    ------------------------------------------------���׏��------------------------------------------------
                    ,TO_CHAR(oola.line_number)                                          line_no                       --�s�m��
                    ,cv_number00                                                        stockout_class                --���i�敪
                    ,NULL                                                               stockout_reason               --���i���R
                    ,opm.item_no                                                        item_code                     --���i�R�[�h�i�ɓ����j
                    ,NULL                                                               product_code1                 --���i�R�[�h�P
                    ,CASE
                       WHEN i_chain_rec.edi_item_code_div = cv_edi_item_code_div02 THEN
                         CASE
                           WHEN oola.order_quantity_uom = i_prf_rec.case_uom_code THEN
                             disc.case_jan_code
                           ELSE
                             opm.attribute21
                         END
                       WHEN i_chain_rec.edi_item_code_div = cv_edi_item_code_div01 THEN
                         xciv.customer_item_number
                     END                                                                product_code2                 --���i�R�[�h�Q
                    ,CASE
                       WHEN oola.order_quantity_uom = i_prf_rec.case_uom_code THEN
                         disc.case_jan_code
                       ELSE
                         opm.attribute21
                     END                                                                jan_code                      --�i�`�m�R�[�h
                    ,opm.attribute22                                                    itf_code                      --�h�s�e�R�[�h
                    ,NULL                                                               extension_itf_code            --�����h�s�e�R�[�h
                    ,NULL                                                               case_product_code             --�P�[�X���i�R�[�h
                    ,NULL                                                               ball_product_code             --�{�[�����i�R�[�h
                    ,NULL                                                               product_code_item_type        --���i�R�[�h�i��
                    ,xhpc.item_div_h_code                                               prod_class                    --���i�敪
                    ,NVL(opm.item_name,i_msg_rec.item_notfound)                         product_name                  --���i���i�����j
                    ,NULL                                                               product_name1_alt             --���i���P�i�J�i�j
                    ,SUBSTRB(opm.item_name_alt,1,15)                                    product_name2_alt             --���i���Q�i�J�i�j
                    ,NULL                                                               item_standard1                --�K�i�P
                    ,SUBSTRB(opm.item_name_alt,16)                                      item_standard2                --�K�i�Q
                    ,NULL                                                               qty_in_case                   --����
                    ,opm.attribute11                                                    num_of_cases                  --�P�[�X����
                    ,TO_CHAR(disc.bowl_inc_num)                                         num_of_ball                   --�{�[������
                    ,NULL                                                               item_color                    --�F
                    ,NULL                                                               item_size                     --�T�C�Y
                    ,NULL                                                               expiration_date               --�ܖ�������
                    ,NULL                                                               product_date                  --������
                    ,NULL                                                               order_uom_qty                 --�����P�ʐ�
                    ,NULL                                                               shipping_uom_qty              --�o�גP�ʐ�
                    ,NULL                                                               packing_uom_qty               --����P�ʐ�
                    ,NULL                                                               deal_code                     --����
                    ,NULL                                                               deal_class                    --�����敪
                    ,NULL                                                               collation_code                --�ƍ�
                    ,oola.order_quantity_uom                                            uom_code                      --�P��
                    ,NULL                                                               unit_price_class              --�P���敪
                    ,NULL                                                               parent_packing_number         --�e����ԍ�
                    ,NULL                                                               packing_number                --����ԍ�
                    ,NULL                                                               product_group_code            --���i�Q�R�[�h
                    ,NULL                                                               case_dismantle_flag           --�P�[�X��̕s�t���O
                    ,NULL                                                               case_class                    --�P�[�X�敪
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            TO_CHAR(oola.ordered_quantity)
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            NULL
                     END                                                                indv_order_qty                --�������ʁi�o���j
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            TO_CHAR(oola.ordered_quantity)
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            NULL
                     END                                                                case_order_qty                --�������ʁi�P�[�X�j
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            TO_CHAR(oola.ordered_quantity)
                     END                                                                ball_order_qty                --�������ʁi�{�[���j
                    ,TO_CHAR( oola.ordered_quantity )                                   sum_order_qty                 --�������ʁi���v�A�o���j
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            TO_CHAR(oola.ordered_quantity)
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            NULL
                     END                                                                indv_shipping_qty             --�o�א��ʁi�o���j
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            TO_CHAR(oola.ordered_quantity)
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            NULL
                     END                                                                case_shipping_qty             --�o�א��ʁi�P�[�X�j
                    ,CASE
                       WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                        AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                          THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                            NULL
                       WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                            TO_CHAR(oola.ordered_quantity)
                     END                                                                ball_shipping_qty             --�o�א��ʁi�{�[���j
                    ,NULL                                                               pallet_shipping_qty           --�o�א��ʁi�p���b�g�j
                    ,CASE
                       WHEN ottt_l.description        = i_msg_rec.line_type30 THEN --�l���̏ꍇ
                         TO_CHAR( 0 )
                       ELSE
                         TO_CHAR( oola.ordered_quantity )
                     END                                                                sum_shipping_qty              --�o�א��ʁi���v�A�o���j
                    ,cv_number0                                                         indv_stockout_qty             --���i���ʁi�o���j
                    ,cv_number0                                                         case_stockout_qty             --���i���ʁi�P�[�X�j
                    ,cv_number0                                                         ball_stockout_qty             --���i���ʁi�{�[���j
                    ,cv_number0                                                         sum_stockout_qty              --���i���ʁi���v�A�o���j
                    ,NULL                                                               case_qty                      --�P�[�X����
                    ,NULL                                                               fold_container_indv_qty       --�I���R���i�o���j����
                    ,NULL                                                               order_unit_price              --���P���i�����j
                    ,CASE
                       WHEN ottt_l.description        = i_msg_rec.line_type30 THEN --�l���̏ꍇ
                         TO_CHAR( 0 )
                       ELSE
                         TO_CHAR( oola.unit_selling_price )
                     END                                                                shipping_unit_price           --���P���i�o�ׁj
                    ,NULL                                                               order_cost_amt                --�������z�i�����j
                    ,CASE
                       WHEN ottt_l.description        = i_msg_rec.line_type30 THEN --�l���̏ꍇ
                         TO_CHAR(  oola.unit_selling_price 
                                *  oola.ordered_quantity 
                                * -1 )
                       ELSE
                         TO_CHAR(  oola.unit_selling_price 
                                *  oola.ordered_quantity  )
                     END                                                                shipping_cost_amt             --�������z�i�o�ׁj
                    ,NULL                                                               stockout_cost_amt             --�������z�i���i�j
                    ,NULL                                                               selling_price                 --���P��
                    ,NULL                                                               order_price_amt               --�������z�i�����j
                    ,NULL                                                               shipping_price_amt            --�������z�i�o�ׁj
                    ,NULL                                                               stockout_price_amt            --�������z�i���i�j
                    ,NULL                                                               a_column_department           --�`���i�S�ݓX�j
                    ,NULL                                                               d_column_department           --�c���i�S�ݓX�j
                    ,NULL                                                               standard_info_depth           --�K�i���E���s��
                    ,NULL                                                               standard_info_height          --�K�i���E����
                    ,NULL                                                               standard_info_width           --�K�i���E��
                    ,NULL                                                               standard_info_weight          --�K�i���E�d��
                    ,NULL                                                               general_succeeded_item1       --�ėp���p�����ڂP
                    ,NULL                                                               general_succeeded_item2       --�ėp���p�����ڂQ
                    ,NULL                                                               general_succeeded_item3       --�ėp���p�����ڂR
                    ,NULL                                                               general_succeeded_item4       --�ėp���p�����ڂS
                    ,NULL                                                               general_succeeded_item5       --�ėp���p�����ڂT
                    ,NULL                                                               general_succeeded_item6       --�ėp���p�����ڂU
                    ,NULL                                                               general_succeeded_item7       --�ėp���p�����ڂV
                    ,NULL                                                               general_succeeded_item8       --�ėp���p�����ڂW
                    ,NULL                                                               general_succeeded_item9       --�ėp���p�����ڂX
                    ,NULL                                                               general_succeeded_item10      --�ėp���p�����ڂP�O
                    ,TO_CHAR(avtab.tax_rate)                                            general_add_item1             --�ėp�t�����ڂP(�ŗ�)
                    ,SUBSTRB(i_base_rec.phone_number, 1, 10)                            general_add_item2             --�ėp�t�����ڂQ
                    ,SUBSTRB(i_base_rec.phone_number, 11, 10)                           general_add_item3             --�ėp�t�����ڂR
                    ,NULL                                                               general_add_item4             --�ėp�t�����ڂS
                    ,NULL                                                               general_add_item5             --�ėp�t�����ڂT
                    ,NULL                                                               general_add_item6             --�ėp�t�����ڂU
                    ,NULL                                                               general_add_item7             --�ėp�t�����ڂV
                    ,NULL                                                               general_add_item8             --�ėp�t�����ڂW
                    ,NULL                                                               general_add_item9             --�ėp�t�����ڂX
                    ,NULL                                                               general_add_item10            --�ėp�t�����ڂP�O
                    ,NULL                                                               chain_peculiar_area_line      --�`�F�[���X�ŗL�G���A�i���ׁj
                    ------------------------------------------------�t�b�^���------------------------------------------------
                    ,NULL                                                               invoice_indv_order_qty        --�i�`�[�v�j�������ʁi�o���j
                    ,NULL                                                               invoice_case_order_qty        --�i�`�[�v�j�������ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_order_qty        --�i�`�[�v�j�������ʁi�{�[���j
                    ,NULL                                                               invoice_sum_order_qty         --�i�`�[�v�j�������ʁi���v�A�o���j
                    ,NULL                                                               invoice_indv_shipping_qty     --�i�`�[�v�j�o�א��ʁi�o���j
                    ,NULL                                                               invoice_case_shipping_qty     --�i�`�[�v�j�o�א��ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_shipping_qty     --�i�`�[�v�j�o�א��ʁi�{�[���j
                    ,NULL                                                               invoice_pallet_shipping_qty   --�i�`�[�v�j�o�א��ʁi�p���b�g�j
                    ,NULL                                                               invoice_sum_shipping_qty      --�i�`�[�v�j�o�א��ʁi���v�A�o���j
                    ,NULL                                                               invoice_indv_stockout_qty     --�i�`�[�v�j���i���ʁi�o���j
                    ,NULL                                                               invoice_case_stockout_qty     --�i�`�[�v�j���i���ʁi�P�[�X�j
                    ,NULL                                                               invoice_ball_stockout_qty     --�i�`�[�v�j���i���ʁi�{�[���j
                    ,NULL                                                               invoice_sum_stockout_qty      --�i�`�[�v�j���i���ʁi���v�A�o���j
                    ,NULL                                                               invoice_case_qty              --�i�`�[�v�j�P�[�X����
                    ,NULL                                                               invoice_fold_container_qty    --�i�`�[�v�j�I���R���i�o���j����
                    ,NULL                                                               invoice_order_cost_amt        --�i�`�[�v�j�������z�i�����j
                    ,NULL                                                               invoice_shipping_cost_amt     --�i�`�[�v�j�������z�i�o�ׁj
                    ,NULL                                                               invoice_stockout_cost_amt     --�i�`�[�v�j�������z�i���i�j
                    ,NULL                                                               invoice_order_price_amt       --�i�`�[�v�j�������z�i�����j
                    ,NULL                                                               invoice_shipping_price_amt    --�i�`�[�v�j�������z�i�o�ׁj
                    ,NULL                                                               invoice_stockout_price_amt    --�i�`�[�v�j�������z�i���i�j
                    ,NULL                                                               total_indv_order_qty          --�i�����v�j�������ʁi�o���j
                    ,NULL                                                               total_case_order_qty          --�i�����v�j�������ʁi�P�[�X�j
                    ,NULL                                                               total_ball_order_qty          --�i�����v�j�������ʁi�{�[���j
                    ,NULL                                                               total_sum_order_qty           --�i�����v�j�������ʁi���v�A�o���j
                    ,NULL                                                               total_indv_shipping_qty       --�i�����v�j�o�א��ʁi�o���j
                    ,NULL                                                               total_case_shipping_qty       --�i�����v�j�o�א��ʁi�P�[�X�j
                    ,NULL                                                               total_ball_shipping_qty       --�i�����v�j�o�א��ʁi�{�[���j
                    ,NULL                                                               total_pallet_shipping_qty     --�i�����v�j�o�א��ʁi�p���b�g�j
                    ,NULL                                                               total_sum_shipping_qty        --�i�����v�j�o�א��ʁi���v�A�o���j
                    ,NULL                                                               total_indv_stockout_qty       --�i�����v�j���i���ʁi�o���j
                    ,NULL                                                               total_case_stockout_qty       --�i�����v�j���i���ʁi�P�[�X�j
                    ,NULL                                                               total_ball_stockout_qty       --�i�����v�j���i���ʁi�{�[���j
                    ,NULL                                                               total_sum_stockout_qty        --�i�����v�j���i���ʁi���v�A�o���j
                    ,NULL                                                               total_case_qty                --�i�����v�j�P�[�X����
                    ,NULL                                                               total_fold_container_qty      --�i�����v�j�I���R���i�o���j����
                    ,NULL                                                               total_order_cost_amt          --�i�����v�j�������z�i�����j
                    ,NULL                                                               total_shipping_cost_amt       --�i�����v�j�������z�i�o�ׁj
                    ,NULL                                                               total_stockout_cost_amt       --�i�����v�j�������z�i���i�j
                    ,NULL                                                               total_order_price_amt         --�i�����v�j�������z�i�����j
                    ,NULL                                                               total_shipping_price_amt      --�i�����v�j�������z�i�o�ׁj
                    ,NULL                                                               total_stockout_price_amt      --�i�����v�j�������z�i���i�j
                    ,NULL                                                               total_line_qty                --�g�[�^���s��
                    ,NULL                                                               total_invoice_qty             --�g�[�^���`�[����
                    ,NULL                                                               chain_peculiar_area_footer    --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
                    --�󒍃w�b�_���C�����C���r���[
              FROM (SELECT ooha.header_id                                               header_id
-- 2009/02/16 T.Nakamura Ver.1.3 add start
                           ,ooha.org_id                                                 org_id
-- 2009/02/16 T.Nakamura Ver.1.3 add end
                           ,ooha.cust_po_number                                         cust_po_number
                           ,ooha.ordered_date                                           ordered_date
                           ,ooha.request_date                                           request_date
                           ,ooha.attribute19                                            attribute19
                           ,ooha.order_number                                           order_number
                           ,ooha.order_type_id                                          order_type_id
                           ,oos.name                                                    name
                           ,hca.cust_account_id                                         cust_account_id
                           ,hca.party_id                                                party_id
                           ,hca.account_number                                          account_number
                           ,xca.chain_store_code                                        chain_store_code
                           ,xca.store_code                                              store_code
                           ,xca.tax_div                                                 tax_div
                           ,xca.torihikisaki_code                                       torihikisaki_code
                           ,xca.deli_center_code                                        deli_center_code
                           ,xca.deli_center_name                                        deli_center_name
                           ,xca.cust_store_name                                         cust_store_name
                    FROM    oe_order_headers_all                                        ooha                          --�󒍃w�b�_���e�[�u��
                           ,hz_cust_accounts                                            hca                           --�ڋq�}�X�^
                           ,xxcmm_cust_accounts                                         xca                           --�ڋq�}�X�^�A�h�I��
                           ,oe_order_sources                                            oos                           --�󒍃\�[�X�e�[�u��
                    WHERE   hca.cust_account_id     = ooha.sold_to_org_id
                    AND     hca.customer_class_code IN (cv_cust_class_chain_store,cv_cust_class_uesama)
                    AND     xca.customer_id         = hca.cust_account_id
                    AND     xca.chain_store_code    = i_input_rec.chain_code
                    AND     oos.name               != i_msg_rec.order_source
                    AND     oos.enabled_flag        = cv_enabled_flag
                    AND     ooha.order_source_id    = oos.order_source_id
                    AND     ooha.flow_status_code   = cv_booked
-- 2009/02/16 T.Nakamura Ver.1.3 add start
                    AND     i_chain_rec.handwritten_slip_div = cv_handwritten_slip_div_tg
-- 2009/02/16 T.Nakamura Ver.1.3 add end
                    )                                                                   ooha
                    --OPM�i�ڏ��C�����C���r���[
                  ,(SELECT  iimb.item_id                                                item_id
                           ,iimb.item_no                                                item_no
                           ,iimb.attribute21                                            attribute21
                           ,iimb.attribute22                                            attribute22
                           ,iimb.attribute11                                            attribute11
                           ,ximb.item_name                                              item_name
                           ,ximb.item_name_alt                                          item_name_alt
                           ,ximb.start_date_active                                      start_date_active
                           ,ximb.end_date_active                                        end_date_active
                    FROM    ic_item_mst_b                                               iimb                          --OPM�i�ڃ}�X�^
                           ,xxcmn_item_mst_b                                            ximb                          --OPM�i�ڃ}�X�^�A�h�I��
                    WHERE   ximb.item_id(+)         = iimb.item_id
                   )                                                                    opm
                    --DISC�i�ڏ��C�����C���r���[
                  ,(SELECT  msib.inventory_item_id                                      inventory_item_id
                           ,xsib.case_jan_code                                          case_jan_code
                           ,xsib.bowl_inc_num                                           bowl_inc_num
                    FROM    mtl_system_items_b                                          msib                          --DISC�i�ڃ}�X�^
                           ,xxcmm_system_items_b                                        xsib                          --DISC�i�ڃ}�X�^�A�h�I��
-- 2009/02/24 T.Nakamura Ver.1.8 mod start
--                    WHERE   msib.organization_id    = 1165
                    WHERE   msib.organization_id    = i_other_rec.organization_id
-- 2009/02/24 T.Nakamura Ver.1.8 mod end
                    AND     xsib.item_code(+)       = msib.segment1
                  )                                                                     disc
                  ,oe_order_lines_all                                                   oola                          --�󒍖��׏��e�[�u��
                  ,oe_transaction_types_tl                                              ottt_h                        --�󒍃^�C�v(�w�b�_)
                  ,oe_transaction_types_tl                                              ottt_l                        --�󒍃^�C�v(����)
                  ,hz_parties                                                           hp                            --�p�[�e�B�}�X�^
                  ,xxcos_head_prod_class_v                                              xhpc                          --�{�Џ��i�敪�r���[
                  ,xxcos_customer_items_v                                               xciv                          --�ڋq�i�ڃr���[
                  ,xxcos_lookup_values_v                                                xlvv                          --����敪�}�X�^
                  ,xxcos_lookup_values_v                                                xlvv2                         --�ŃR�[�h�}�X�^
                  ,ar_vat_tax_all_b                                                     avtab                         --�ŗ��}�X�^
                  ,xxcos_chain_store_security_v                                         xcss                          --�`�F�[���X�X�܃Z�L�����e�B�r���[
              --�󒍃^�C�v(�w�b�_)���o����
              WHERE ottt_h.language                 = USERENV('LANG')
              AND   ottt_h.source_lang              = USERENV('LANG')
              AND   ottt_h.description              = i_msg_rec.header_type
              --�󒍃^�C�v(����)���o����
              AND   ottt_l.language                 = USERENV('LANG')
              AND   ottt_l.source_lang              = USERENV('LANG')
              AND   ottt_l.description              IN (i_msg_rec.line_type10, i_msg_rec.line_type20, i_msg_rec.line_type30)
              --�󒍃w�b�_���C�����C���r���[���o����
              AND   ooha.order_type_id              = ottt_h.transaction_type_id
              AND   TRUNC(ooha.request_date)                                                                          --�X�ܔ[�i��
                     BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
                     AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
              --�󒍖��ג��o����
              AND   oola.header_id                  = ooha.header_id
              AND   oola.line_type_id               = ottt_l.transaction_type_id
              AND   oola.flow_status_code           = cv_booked
              --�p�[�e�B�}�X�^���o����
              AND   hp.party_id(+)                  = ooha.party_id
              --OPM�i�ڏ��C�����C���r���[���o����
              AND   opm.item_no(+)                  = oola.ordered_item
              AND   oola.request_date
                BETWEEN NVL(opm.start_date_active, oola.request_date)
                AND     NVL(opm.end_date_active, oola.request_date)
              --DISC�i�ڏ��C�����C���r���[���o����
              AND   disc.inventory_item_id(+)       = oola.inventory_item_id
              --�{�Џ��i�敪�r���[���o����
              AND   xhpc.inventory_item_id(+)       = oola.inventory_item_id
              --�ڋq�i�ڃr���[���o����
              AND   xciv.customer_id(+)             = i_chain_rec.customer_id
              AND   xciv.inventory_item_id(+)       = oola.inventory_item_id
-- 2009/02/16 T.Nakamura Ver.1.3 add start
              AND   xciv.order_uom (+)              = oola.order_quantity_uom
-- 2009/02/16 T.Nakamura Ver.1.3 add end
              --����敪�}�X�^���o����
              AND   xlvv.lookup_type(+)             = ct_qc_sale_class
              AND   xlvv.lookup_code(+)             = oola.attribute5
              AND   oola.request_date
                BETWEEN NVL(xlvv.start_date_active, oola.request_date)
                AND     NVL(xlvv.end_date_active, oola.request_date)
              AND  ( i_input_rec.bargain_class      = cv_bargain_class_all
                OR   i_input_rec.bargain_class     != cv_bargain_class_all
                AND  i_input_rec.bargain_class      = xlvv.attribute8
              )
              --�ŃR�[�h�}�X�^���o����
              AND   xlvv2.lookup_type(+)            = ct_qc_consumption_tax_class
              AND   xlvv2.attribute3(+)             = ooha.tax_div
              AND   ooha.request_date
                BETWEEN NVL(xlvv2.start_date_active, ooha.request_date)
                AND     NVL(xlvv2.end_date_active, ooha.request_date)
              --�ŗ��}�X�^���o����
              AND   avtab.tax_code(+)               = xlvv2.attribute2
              AND   avtab.set_of_books_id(+)        = i_prf_rec.set_of_books_id
              --�X�܃Z�L�����e�B�r���[���o����
              AND   xcss.chain_code                 = i_input_rec.chain_code
              AND   xcss.account_number             = ooha.account_number
              AND   xcss.user_id                    = i_input_rec.user_id
              AND  (i_input_rec.store_code          IS NOT NULL
                AND i_input_rec.store_code          = ooha.store_code
                OR  i_input_rec.store_code          IS NULL
                AND xcss.chain_store_code           = ooha.store_code
              )
              AND  (i_input_rec.info_div            IS NOT NULL
                AND 1                               = 2
                OR  i_input_rec.info_div            IS NULL
              )
-- 2009/02/16 T.Nakamura Ver.1.3 add start
              AND   avtab.org_id                    = i_prf_rec.org_id                                                 --MO:�c�ƒP��
              AND   avtab.enabled_flag              = cv_enabled_flag                                                  --�g�p�\�t���O
              AND   i_other_rec.process_date
                BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
                AND     NVL( avtab.end_date   ,i_other_rec.process_date )
              AND   ooha.org_id                     = i_prf_rec.org_id
              AND   oola.org_id                     = ooha.org_id
-- 2009/02/16 T.Nakamura Ver.1.3 add start
      )                                                                                 tbl01
      ORDER BY tbl01.invoice_number,tbl01.line_no
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_base_rec                 g_base_rtype;                        --�[�i���_���
    l_chain_rec                g_chain_rtype;                       --EDI�`�F�[���X���
    l_other_rec                g_other_rtype;                       --���̑����
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
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.6 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
--
    --���b�Z�[�W������(�ʏ��)�擾
    g_msg_rec.header_type  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type);
--
    --���b�Z�[�W������(�ʏ�o��)�擾
    g_msg_rec.line_type10  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type10);
    --���b�Z�[�W������(���^)�擾
    g_msg_rec.line_type20  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type20);
    --���b�Z�[�W������(�l��)�擾
    g_msg_rec.line_type30  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type30);
    --���b�Z�[�W������(�󒍃\�[�X)�擾
    g_msg_rec.order_source := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
    --==============================================================
    --�����S���ҏ��擾
    --==============================================================
    BEGIN
      SELECT papf.last_name || papf.first_name                                  manager_name                 --�����S����
      INTO   l_base_rec.manager_name_kana
      FROM   per_all_people_f                                                   papf                         --�]�ƈ��}�X�^
            ,per_all_assignments_f                                              paaf                         --�]�ƈ������}�X�^
      WHERE  papf.person_id      = paaf.person_id
      AND    xxccp_common_pkg2.get_process_date 
        BETWEEN papf.effective_start_date
        AND     NVL(papf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND    xxccp_common_pkg2.get_process_date
        BETWEEN paaf.effective_start_date
        AND     NVL(paaf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND   paaf.ass_attribute5  = g_input_rec.base_code
      AND   papf.attribute11     = g_prf_rec.base_manager_code
      AND ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        out_line(buff => cv_prg_name || ' ' || sqlerrm);
    END;
--
    --==============================================================
    --�[�i���_���擾
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                      base_name                    --�ڋq����
            ,hp.organization_name_phonetic                                      base_name_kana               --�ڋq����(�J�i)
            ,hl.state                                                           state                        --�s���{��
            ,hl.city                                                            city                         --�s�E��
            ,hl.address1                                                        address1                     --�Z���P
            ,hl.address2                                                        address2                     --�Z���Q
            ,hl.address_lines_phonetic                                          phone_number                 --�d�b�ԍ�
            ,xca.torihikisaki_code                                              customer_code                --�����R�[�h
      INTO   l_base_rec.base_name
            ,l_base_rec.base_name_kana
            ,l_base_rec.state
            ,l_base_rec.city
            ,l_base_rec.address1
            ,l_base_rec.address2
            ,l_base_rec.phone_number
            ,l_base_rec.customer_code
      FROM   hz_cust_accounts                                                   hca                          --�ڋq�}�X�^
            ,xxcmm_cust_accounts                                                xca                          --�ڋq�}�X�^�A�h�I��
            ,hz_parties                                                         hp                           --�p�[�e�B�}�X�^
-- 2009/02/16 T.Nakamura Ver.1.3 add start
            ,hz_cust_acct_sites_all                                             hcas                         --�ڋq���ݒn
-- 2009/02/16 T.Nakamura Ver.1.3 add end
            ,hz_party_sites                                                     hps                          --�p�[�e�B�T�C�g�}�X�^
            ,hz_locations                                                       hl                           --���Ə��}�X�^
      --�ڋq�}�X�^���o����
      WHERE  hca.account_number      = g_input_rec.base_code
      AND    hca.customer_class_code = cv_cust_class_base
      --�ڋq�}�X�^�A�h�I�����o����
      AND    xca.customer_id         = hca.cust_account_id
      --�p�[�e�B�}�X�^���o����
      AND    hp.party_id             = hca.party_id
     --�p�[�e�B�T�C�g���o����
      AND    hps.party_id            = hca.party_id
      --�ڋq���Ə��}�X�^���o����
      AND    hl.location_id          = hps.location_id
-- 2009/02/16 T.Nakamura Ver.1.3 add start
      AND    hcas.cust_account_id    = hca.cust_account_id
      AND    hps.party_site_id       = hcas.party_site_id
      AND    hcas.org_id             = g_prf_rec.org_id
-- 2009/02/16 T.Nakamura Ver.1.3 add end
and rownum = 1
      ;
--
      l_base_rec.notfound_flag   := cv_found;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_base_rec.base_name     := g_msg_rec.customer_notfound;
        l_base_rec.notfound_flag := cv_notfound;
    END;
--
    --==============================================================
    --EDI�`�F�[���X���擾
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                      chain_name                   --�`�F�[���X����
            ,hp.organization_name_phonetic                                      chain_name_kana              --�`�F�[���X����(�J�i)
            ,xca.chain_store_code                                               chain_store_code             --EDI�`�F�[���X�R�[�h
            ,xca.edi_item_code_div                                              edi_item_code_div            --EDI�A�g�i�ڃR�[�h�敪
            ,xca.customer_id                                                    customer_id                  --�ڋqID
-- 2009/02/20 T.Nakamura Ver.1.7 add start
            ,xca.handwritten_slip_div                                           handwritten_slip_div         --�菑�`�[�`���敪
-- 2009/02/20 T.Nakamura Ver.1.7 add end
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana      
            ,l_chain_rec.chain_store_code
            ,l_chain_rec.edi_item_code_div
            ,l_chain_rec.customer_id
-- 2009/02/20 T.Nakamura Ver.1.7 add start
            ,l_chain_rec.handwritten_slip_div
-- 2009/02/20 T.Nakamura Ver.1.7 add end
      FROM   xxcmm_cust_accounts                                                xca                          --�ڋq�}�X�^�A�h�I��
            ,hz_cust_accounts                                                   hca                          --�ڋq�}�X�^
            ,hz_parties                                                         hp                           --�p�[�e�B�}�X�^
      WHERE  xca.edi_chain_code      = g_input_rec.chain_code
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_chain_rec.chain_name := g_msg_rec.customer_notfound;
    END;
--
    --==============================================================
    --�O���[�o���ϐ��̐ݒ�
    --==============================================================
    g_base_rec  := l_base_rec;
    g_chain_rec := l_chain_rec;
--
    --�e�e�[�u���C���f�b�N�X�̏�����
    ln_cnt      := 0;
    --==============================================================
    --�f�[�^���R�[�h���擾
    --==============================================================
    OPEN cur_data_record(
           g_input_rec
          ,g_prf_rec
          ,g_base_rec
          ,g_chain_rec
          ,g_msg_rec
          ,g_other_rec
         );
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        lt_header_id                                                                                          --�w�b�_ID
       ,lt_cust_po_number                                                                                     --�󒍃w�b�_�i�ڋq�����j
       ,lt_bargain_class                                                                                      --��ԓ����敪
       ,lt_outbound_flag                                                                                      --OUTBOUND��
       ,ln_reason_id                                                                                          --���RID
       ,lt_stockout_cancel_flag                                                                               --���i���R����t���O
            ------------------------------------------------�w�b�_���------------------------------------------------
       ,l_data_tab('MEDIUM_CLASS')                                                                            --�}�̋敪
       ,l_data_tab('DATA_TYPE_CODE')                                                                          --�f�[�^��R�[�h
       ,l_data_tab('FILE_NO')                                                                                 --�t�@�C���m��
       ,l_data_tab('INFO_CLASS')                                                                              --���敪
       ,l_data_tab('PROCESS_DATE')                                                                            --������
       ,l_data_tab('PROCESS_TIME')                                                                            --��������
       ,l_data_tab('BASE_CODE')                                                                               --���_�i����j�R�[�h
       ,l_data_tab('BASE_NAME')                                                                               --���_���i�������j
       ,l_data_tab('BASE_NAME_ALT')                                                                           --���_���i�J�i�j
       ,l_data_tab('EDI_CHAIN_CODE')                                                                          --�d�c�h�`�F�[���X�R�[�h
       ,l_data_tab('EDI_CHAIN_NAME')                                                                          --�d�c�h�`�F�[���X���i�����j
       ,l_data_tab('EDI_CHAIN_NAME_ALT')                                                                      --�d�c�h�`�F�[���X���i�J�i�j
       ,l_data_tab('CHAIN_CODE')                                                                              --�`�F�[���X�R�[�h
       ,l_data_tab('CHAIN_NAME')                                                                              --�`�F�[���X���i�����j
       ,l_data_tab('CHAIN_NAME_ALT')                                                                          --�`�F�[���X���i�J�i�j
       ,l_data_tab('REPORT_CODE')                                                                             --���[�R�[�h
       ,l_data_tab('REPORT_SHOW_NAME')                                                                        --���[�\����
       ,l_data_tab('CUSTOMER_CODE')                                                                           --�ڋq�R�[�h
       ,l_data_tab('CUSTOMER_NAME')                                                                           --�ڋq���i�����j
       ,l_data_tab('CUSTOMER_NAME_ALT')                                                                       --�ڋq���i�J�i�j
       ,l_data_tab('COMPANY_CODE')                                                                            --�ЃR�[�h
       ,l_data_tab('COMPANY_NAME')                                                                            --�Ж��i�����j
       ,l_data_tab('COMPANY_NAME_ALT')                                                                        --�Ж��i�J�i�j
       ,l_data_tab('SHOP_CODE')                                                                               --�X�R�[�h
       ,l_data_tab('SHOP_NAME')                                                                               --�X���i�����j
       ,l_data_tab('SHOP_NAME_ALT')                                                                           --�X���i�J�i�j
       ,l_data_tab('DELIVERY_CENTER_CODE')                                                                    --�[���Z���^�[�R�[�h
       ,l_data_tab('DELIVERY_CENTER_NAME')                                                                    --�[���Z���^�[���i�����j
       ,l_data_tab('DELIVERY_CENTER_NAME_ALT')                                                                --�[���Z���^�[���i�J�i�j
       ,l_data_tab('ORDER_DATE')                                                                              --������
       ,l_data_tab('CENTER_DELIVERY_DATE')                                                                    --�Z���^�[�[�i��
       ,l_data_tab('RESULT_DELIVERY_DATE')                                                                    --���[�i��
       ,l_data_tab('SHOP_DELIVERY_DATE')                                                                      --�X�ܔ[�i��
       ,l_data_tab('DATA_CREATION_DATE_EDI_DATA')                                                             --�f�[�^�쐬���i�d�c�h�f�[�^���j
       ,l_data_tab('DATA_CREATION_TIME_EDI_DATA')                                                             --�f�[�^�쐬�����i�d�c�h�f�[�^���j
       ,l_data_tab('INVOICE_CLASS')                                                                           --�`�[�敪
       ,l_data_tab('SMALL_CLASSIFICATION_CODE')                                                               --�����ރR�[�h
       ,l_data_tab('SMALL_CLASSIFICATION_NAME')                                                               --�����ޖ�
       ,l_data_tab('MIDDLE_CLASSIFICATION_CODE')                                                              --�����ރR�[�h
       ,l_data_tab('MIDDLE_CLASSIFICATION_NAME')                                                              --�����ޖ�
       ,l_data_tab('BIG_CLASSIFICATION_CODE')                                                                 --�啪�ރR�[�h
       ,l_data_tab('BIG_CLASSIFICATION_NAME')                                                                 --�啪�ޖ�
       ,l_data_tab('OTHER_PARTY_DEPARTMENT_CODE')                                                             --����敔��R�[�h
       ,l_data_tab('OTHER_PARTY_ORDER_NUMBER')                                                                --����攭���ԍ�
       ,l_data_tab('CHECK_DIGIT_CLASS')                                                                       --�`�F�b�N�f�W�b�g�L���敪
       ,l_data_tab('INVOICE_NUMBER')                                                                          --�`�[�ԍ�
       ,l_data_tab('CHECK_DIGIT')                                                                             --�`�F�b�N�f�W�b�g
       ,l_data_tab('CLOSE_DATE')                                                                              --����
       ,l_data_tab('ORDER_NO_EBS')                                                                            --�󒍂m���i�d�a�r�j
       ,l_data_tab('AR_SALE_CLASS')                                                                           --�����敪
       ,l_data_tab('DELIVERY_CLASSE')                                                                         --�z���敪
       ,l_data_tab('OPPORTUNITY_NO')                                                                          --�ւm��
       ,l_data_tab('CONTACT_TO')                                                                              --�A����
       ,l_data_tab('ROUTE_SALES')                                                                             --���[�g�Z�[���X
       ,l_data_tab('CORPORATE_CODE')                                                                          --�@�l�R�[�h
       ,l_data_tab('MAKER_NAME')                                                                              --���[�J�[��
       ,l_data_tab('AREA_CODE')                                                                               --�n��R�[�h
       ,l_data_tab('AREA_NAME')                                                                               --�n�於�i�����j
       ,l_data_tab('AREA_NAME_ALT')                                                                           --�n�於�i�J�i�j
       ,l_data_tab('VENDOR_CODE')                                                                             --�����R�[�h
       ,l_data_tab('VENDOR_NAME')                                                                             --����於�i�����j
       ,l_data_tab('VENDOR_NAME1_ALT')                                                                        --����於�P�i�J�i�j
       ,l_data_tab('VENDOR_NAME2_ALT')                                                                        --����於�Q�i�J�i�j
       ,l_data_tab('VENDOR_TEL')                                                                              --�����s�d�k
       ,l_data_tab('VENDOR_CHARGE')                                                                           --�����S����
       ,l_data_tab('VENDOR_ADDRESS')                                                                          --�����Z���i�����j
       ,l_data_tab('DELIVER_TO_CODE_ITOUEN')                                                                  --�͂���R�[�h�i�ɓ����j
       ,l_data_tab('DELIVER_TO_CODE_CHAIN')                                                                   --�͂���R�[�h�i�`�F�[���X�j
       ,l_data_tab('DELIVER_TO')                                                                              --�͂���i�����j
       ,l_data_tab('DELIVER_TO1_ALT')                                                                         --�͂���P�i�J�i�j
       ,l_data_tab('DELIVER_TO2_ALT')                                                                         --�͂���Q�i�J�i�j
       ,l_data_tab('DELIVER_TO_ADDRESS')                                                                      --�͂���Z���i�����j
       ,l_data_tab('DELIVER_TO_ADDRESS_ALT')                                                                  --�͂���Z���i�J�i�j
       ,l_data_tab('DELIVER_TO_TEL')                                                                          --�͂���s�d�k
       ,l_data_tab('BALANCE_ACCOUNTS_CODE')                                                                   --������R�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_COMPANY_CODE')                                                           --������ЃR�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_SHOP_CODE')                                                              --������X�R�[�h
       ,l_data_tab('BALANCE_ACCOUNTS_NAME')                                                                   --�����於�i�����j
       ,l_data_tab('BALANCE_ACCOUNTS_NAME_ALT')                                                               --�����於�i�J�i�j
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS')                                                                --������Z���i�����j
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS_ALT')                                                            --������Z���i�J�i�j
       ,l_data_tab('BALANCE_ACCOUNTS_TEL')                                                                    --������s�d�k
       ,l_data_tab('ORDER_POSSIBLE_DATE')                                                                     --�󒍉\��
       ,l_data_tab('PERMISSION_POSSIBLE_DATE')                                                                --���e�\��
       ,l_data_tab('FORWARD_MONTH')                                                                           --����N����
       ,l_data_tab('PAYMENT_SETTLEMENT_DATE')                                                                 --�x�����ϓ�
       ,l_data_tab('HANDBILL_START_DATE_ACTIVE')                                                              --�`���V�J�n��
       ,l_data_tab('BILLING_DUE_DATE')                                                                        --��������
       ,l_data_tab('SHIPPING_TIME')                                                                           --�o�׎���
       ,l_data_tab('DELIVERY_SCHEDULE_TIME')                                                                  --�[�i�\�莞��
       ,l_data_tab('ORDER_TIME')                                                                              --��������
       ,l_data_tab('GENERAL_DATE_ITEM1')                                                                      --�ėp���t���ڂP
       ,l_data_tab('GENERAL_DATE_ITEM2')                                                                      --�ėp���t���ڂQ
       ,l_data_tab('GENERAL_DATE_ITEM3')                                                                      --�ėp���t���ڂR
       ,l_data_tab('GENERAL_DATE_ITEM4')                                                                      --�ėp���t���ڂS
       ,l_data_tab('GENERAL_DATE_ITEM5')                                                                      --�ėp���t���ڂT
       ,l_data_tab('ARRIVAL_SHIPPING_CLASS')                                                                  --���o�׋敪
       ,l_data_tab('VENDOR_CLASS')                                                                            --�����敪
       ,l_data_tab('INVOICE_DETAILED_CLASS')                                                                  --�`�[����敪
       ,l_data_tab('UNIT_PRICE_USE_CLASS')                                                                    --�P���g�p�敪
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_CODE')                                                            --�T�u�����Z���^�[�R�[�h
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_NAME')                                                            --�T�u�����Z���^�[�R�[�h��
       ,l_data_tab('CENTER_DELIVERY_METHOD')                                                                  --�Z���^�[�[�i���@
       ,l_data_tab('CENTER_USE_CLASS')                                                                        --�Z���^�[���p�敪
       ,l_data_tab('CENTER_WHSE_CLASS')                                                                       --�Z���^�[�q�ɋ敪
       ,l_data_tab('CENTER_AREA_CLASS')                                                                       --�Z���^�[�n��敪
       ,l_data_tab('CENTER_ARRIVAL_CLASS')                                                                    --�Z���^�[���׋敪
       ,l_data_tab('DEPOT_CLASS')                                                                             --�f�|�敪
       ,l_data_tab('TCDC_CLASS')                                                                              --�s�b�c�b�敪
       ,l_data_tab('UPC_FLAG')                                                                                --�t�o�b�t���O
       ,l_data_tab('SIMULTANEOUSLY_CLASS')                                                                    --��ċ敪
       ,l_data_tab('BUSINESS_ID')                                                                             --�Ɩ��h�c
       ,l_data_tab('WHSE_DIRECTLY_CLASS')                                                                     --�q���敪
       ,l_data_tab('PREMIUM_REBATE_CLASS')                                                                    --���ڎ��
       ,l_data_tab('ITEM_TYPE')                                                                               --�i�i���ߋ敪
       ,l_data_tab('CLOTH_HOUSE_FOOD_CLASS')                                                                  --�߉ƐH�敪
       ,l_data_tab('MIX_CLASS')                                                                               --���݋敪
       ,l_data_tab('STK_CLASS')                                                                               --�݌ɋ敪
       ,l_data_tab('LAST_MODIFY_SITE_CLASS')                                                                  --�ŏI�C���ꏊ�敪
       ,l_data_tab('REPORT_CLASS')                                                                            --���[�敪
       ,l_data_tab('ADDITION_PLAN_CLASS')                                                                     --�ǉ��E�v��敪
       ,l_data_tab('REGISTRATION_CLASS')                                                                      --�o�^�敪
       ,l_data_tab('SPECIFIC_CLASS')                                                                          --����敪
       ,l_data_tab('DEALINGS_CLASS')                                                                          --����敪
       ,l_data_tab('ORDER_CLASS')                                                                             --�����敪
       ,l_data_tab('SUM_LINE_CLASS')                                                                          --�W�v���׋敪
       ,l_data_tab('SHIPPING_GUIDANCE_CLASS')                                                                 --�o�׈ē��ȊO�敪
       ,l_data_tab('SHIPPING_CLASS')                                                                          --�o�׋敪
       ,l_data_tab('PRODUCT_CODE_USE_CLASS')                                                                  --���i�R�[�h�g�p�敪
       ,l_data_tab('CARGO_ITEM_CLASS')                                                                        --�ϑ��i�敪
       ,l_data_tab('TA_CLASS')                                                                                --�s�^�`�敪
       ,l_data_tab('PLAN_CODE')                                                                               --���R�[�h
       ,l_data_tab('CATEGORY_CODE')                                                                           --�J�e�S���[�R�[�h
       ,l_data_tab('CATEGORY_CLASS')                                                                          --�J�e�S���[�敪
       ,l_data_tab('CARRIER_MEANS')                                                                           --�^����i
       ,l_data_tab('COUNTER_CODE')                                                                            --����R�[�h
       ,l_data_tab('MOVE_SIGN')                                                                               --�ړ��T�C��
       ,l_data_tab('EOS_HANDWRITING_CLASS')                                                                   --�d�n�r�E�菑�敪
       ,l_data_tab('DELIVERY_TO_SECTION_CODE')                                                                --�[�i��ۃR�[�h
       ,l_data_tab('INVOICE_DETAILED')                                                                        --�`�[����
       ,l_data_tab('ATTACH_QTY')                                                                              --�Y�t��
       ,l_data_tab('OTHER_PARTY_FLOOR')                                                                       --�t���A
       ,l_data_tab('TEXT_NO')                                                                                 --�s�d�w�s�m��
       ,l_data_tab('IN_STORE_CODE')                                                                           --�C���X�g�A�R�[�h
       ,l_data_tab('TAG_DATA')                                                                                --�^�O
       ,l_data_tab('COMPETITION_CODE')                                                                        --����
       ,l_data_tab('BILLING_CHAIR')                                                                           --��������
       ,l_data_tab('CHAIN_STORE_CODE')                                                                        --�`�F�[���X�g�A�[�R�[�h
       ,l_data_tab('CHAIN_STORE_SHORT_NAME')                                                                  --�`�F�[���X�g�A�[�R�[�h��������
       ,l_data_tab('DIRECT_DELIVERY_RCPT_FEE')                                                                --���z���^���旿
       ,l_data_tab('BILL_INFO')                                                                               --��`���
       ,l_data_tab('DESCRIPTION')                                                                             --�E�v
       ,l_data_tab('INTERIOR_CODE')                                                                           --�����R�[�h
       ,l_data_tab('ORDER_INFO_DELIVERY_CATEGORY')                                                            --�������@�[�i�J�e�S���[
       ,l_data_tab('PURCHASE_TYPE')                                                                           --�d���`��
       ,l_data_tab('DELIVERY_TO_NAME_ALT')                                                                    --�[�i�ꏊ���i�J�i�j
       ,l_data_tab('SHOP_OPENED_SITE')                                                                        --�X�o�ꏊ
       ,l_data_tab('COUNTER_NAME')                                                                            --���ꖼ
       ,l_data_tab('EXTENSION_NUMBER')                                                                        --�����ԍ�
       ,l_data_tab('CHARGE_NAME')                                                                             --�S���Җ�
       ,l_data_tab('PRICE_TAG')                                                                               --�l�D
       ,l_data_tab('TAX_TYPE')                                                                                --�Ŏ�
       ,l_data_tab('CONSUMPTION_TAX_CLASS')                                                                   --����ŋ敪
       ,l_data_tab('BRAND_CLASS')                                                                             --�a�q
       ,l_data_tab('ID_CODE')                                                                                 --�h�c�R�[�h
       ,l_data_tab('DEPARTMENT_CODE')                                                                         --�S�ݓX�R�[�h
       ,l_data_tab('DEPARTMENT_NAME')                                                                         --�S�ݓX��
       ,l_data_tab('ITEM_TYPE_NUMBER')                                                                        --�i�ʔԍ�
       ,l_data_tab('DESCRIPTION_DEPARTMENT')                                                                  --�E�v�i�S�ݓX�j
       ,l_data_tab('PRICE_TAG_METHOD')                                                                        --�l�D���@
       ,l_data_tab('REASON_COLUMN')                                                                           --���R��
       ,l_data_tab('A_COLUMN_HEADER')                                                                         --�`���w�b�_
       ,l_data_tab('D_COLUMN_HEADER')                                                                         --�c���w�b�_
       ,l_data_tab('BRAND_CODE')                                                                              --�u�����h�R�[�h
       ,l_data_tab('LINE_CODE')                                                                               --���C���R�[�h
       ,l_data_tab('CLASS_CODE')                                                                              --�N���X�R�[�h
       ,l_data_tab('A1_COLUMN')                                                                               --�`�|�P��
       ,l_data_tab('B1_COLUMN')                                                                               --�a�|�P��
       ,l_data_tab('C1_COLUMN')                                                                               --�b�|�P��
       ,l_data_tab('D1_COLUMN')                                                                               --�c�|�P��
       ,l_data_tab('E1_COLUMN')                                                                               --�d�|�P��
       ,l_data_tab('A2_COLUMN')                                                                               --�`�|�Q��
       ,l_data_tab('B2_COLUMN')                                                                               --�a�|�Q��
       ,l_data_tab('C2_COLUMN')                                                                               --�b�|�Q��
       ,l_data_tab('D2_COLUMN')                                                                               --�c�|�Q��
       ,l_data_tab('E2_COLUMN')                                                                               --�d�|�Q��
       ,l_data_tab('A3_COLUMN')                                                                               --�`�|�R��
       ,l_data_tab('B3_COLUMN')                                                                               --�a�|�R��
       ,l_data_tab('C3_COLUMN')                                                                               --�b�|�R��
       ,l_data_tab('D3_COLUMN')                                                                               --�c�|�R��
       ,l_data_tab('E3_COLUMN')                                                                               --�d�|�R��
       ,l_data_tab('F1_COLUMN')                                                                               --�e�|�P��
       ,l_data_tab('G1_COLUMN')                                                                               --�f�|�P��
       ,l_data_tab('H1_COLUMN')                                                                               --�g�|�P��
       ,l_data_tab('I1_COLUMN')                                                                               --�h�|�P��
       ,l_data_tab('J1_COLUMN')                                                                               --�i�|�P��
       ,l_data_tab('K1_COLUMN')                                                                               --�j�|�P��
       ,l_data_tab('L1_COLUMN')                                                                               --�k�|�P��
       ,l_data_tab('F2_COLUMN')                                                                               --�e�|�Q��
       ,l_data_tab('G2_COLUMN')                                                                               --�f�|�Q��
       ,l_data_tab('H2_COLUMN')                                                                               --�g�|�Q��
       ,l_data_tab('I2_COLUMN')                                                                               --�h�|�Q��
       ,l_data_tab('J2_COLUMN')                                                                               --�i�|�Q��
       ,l_data_tab('K2_COLUMN')                                                                               --�j�|�Q��
       ,l_data_tab('L2_COLUMN')                                                                               --�k�|�Q��
       ,l_data_tab('F3_COLUMN')                                                                               --�e�|�R��
       ,l_data_tab('G3_COLUMN')                                                                               --�f�|�R��
       ,l_data_tab('H3_COLUMN')                                                                               --�g�|�R��
       ,l_data_tab('I3_COLUMN')                                                                               --�h�|�R��
       ,l_data_tab('J3_COLUMN')                                                                               --�i�|�R��
       ,l_data_tab('K3_COLUMN')                                                                               --�j�|�R��
       ,l_data_tab('L3_COLUMN')                                                                               --�k�|�R��
       ,l_data_tab('CHAIN_PECULIAR_AREA_HEADER')                                                              --�`�F�[���X�ŗL�G���A�i�w�b�_�[�j
       ,l_data_tab('ORDER_CONNECTION_NUMBER')                                                                 --�󒍊֘A�ԍ��i���j
            ------------------------------------------------���׏��------------------------------------------------
       ,l_data_tab('LINE_NO')                                                                                 --�s�m��
       ,l_data_tab('STOCKOUT_CLASS')                                                                          --���i�敪
       ,l_data_tab('STOCKOUT_REASON')                                                                         --���i���R
       ,l_data_tab('PRODUCT_CODE_ITOUEN')                                                                     --���i�R�[�h�i�ɓ����j
       ,l_data_tab('PRODUCT_CODE1')                                                                           --���i�R�[�h�P
       ,l_data_tab('PRODUCT_CODE2')                                                                           --���i�R�[�h�Q
       ,l_data_tab('JAN_CODE')                                                                                --�i�`�m�R�[�h
       ,l_data_tab('ITF_CODE')                                                                                --�h�s�e�R�[�h
       ,l_data_tab('EXTENSION_ITF_CODE')                                                                      --�����h�s�e�R�[�h
       ,l_data_tab('CASE_PRODUCT_CODE')                                                                       --�P�[�X���i�R�[�h
       ,l_data_tab('BALL_PRODUCT_CODE')                                                                       --�{�[�����i�R�[�h
       ,l_data_tab('PRODUCT_CODE_ITEM_TYPE')                                                                  --���i�R�[�h�i��
       ,l_data_tab('PROD_CLASS')                                                                              --���i�敪
       ,l_data_tab('PRODUCT_NAME')                                                                            --���i���i�����j
       ,l_data_tab('PRODUCT_NAME1_ALT')                                                                       --���i���P�i�J�i�j
       ,l_data_tab('PRODUCT_NAME2_ALT')                                                                       --���i���Q�i�J�i�j
       ,l_data_tab('ITEM_STANDARD1')                                                                          --�K�i�P
       ,l_data_tab('ITEM_STANDARD2')                                                                          --�K�i�Q
       ,l_data_tab('QTY_IN_CASE')                                                                             --����
       ,l_data_tab('NUM_OF_CASES')                                                                            --�P�[�X����
       ,l_data_tab('NUM_OF_BALL')                                                                             --�{�[������
       ,l_data_tab('ITEM_COLOR')                                                                              --�F
       ,l_data_tab('ITEM_SIZE')                                                                               --�T�C�Y
       ,l_data_tab('EXPIRATION_DATE')                                                                         --�ܖ�������
       ,l_data_tab('PRODUCT_DATE')                                                                            --������
       ,l_data_tab('ORDER_UOM_QTY')                                                                           --�����P�ʐ�
       ,l_data_tab('SHIPPING_UOM_QTY')                                                                        --�o�גP�ʐ�
       ,l_data_tab('PACKING_UOM_QTY')                                                                         --����P�ʐ�
       ,l_data_tab('DEAL_CODE')                                                                               --����
       ,l_data_tab('DEAL_CLASS')                                                                              --�����敪
       ,l_data_tab('COLLATION_CODE')                                                                          --�ƍ�
       ,l_data_tab('UOM_CODE')                                                                                --�P��
       ,l_data_tab('UNIT_PRICE_CLASS')                                                                        --�P���敪
       ,l_data_tab('PARENT_PACKING_NUMBER')                                                                   --�e����ԍ�
       ,l_data_tab('PACKING_NUMBER')                                                                          --����ԍ�
       ,l_data_tab('PRODUCT_GROUP_CODE')                                                                      --���i�Q�R�[�h
       ,l_data_tab('CASE_DISMANTLE_FLAG')                                                                     --�P�[�X��̕s�t���O
       ,l_data_tab('CASE_CLASS')                                                                              --�P�[�X�敪
       ,l_data_tab('INDV_ORDER_QTY')                                                                          --�������ʁi�o���j
       ,l_data_tab('CASE_ORDER_QTY')                                                                          --�������ʁi�P�[�X�j
       ,l_data_tab('BALL_ORDER_QTY')                                                                          --�������ʁi�{�[���j
       ,l_data_tab('SUM_ORDER_QTY')                                                                           --�������ʁi���v�A�o���j
       ,l_data_tab('INDV_SHIPPING_QTY')                                                                       --�o�א��ʁi�o���j
       ,l_data_tab('CASE_SHIPPING_QTY')                                                                       --�o�א��ʁi�P�[�X�j
       ,l_data_tab('BALL_SHIPPING_QTY')                                                                       --�o�א��ʁi�{�[���j
       ,l_data_tab('PALLET_SHIPPING_QTY')                                                                     --�o�א��ʁi�p���b�g�j
       ,l_data_tab('SUM_SHIPPING_QTY')                                                                        --�o�א��ʁi���v�A�o���j
       ,l_data_tab('INDV_STOCKOUT_QTY')                                                                       --���i���ʁi�o���j
       ,l_data_tab('CASE_STOCKOUT_QTY')                                                                       --���i���ʁi�P�[�X�j
       ,l_data_tab('BALL_STOCKOUT_QTY')                                                                       --���i���ʁi�{�[���j
       ,l_data_tab('SUM_STOCKOUT_QTY')                                                                        --���i���ʁi���v�A�o���j
       ,l_data_tab('CASE_QTY')                                                                                --�P�[�X����
       ,l_data_tab('FOLD_CONTAINER_INDV_QTY')                                                                 --�I���R���i�o���j����
       ,l_data_tab('ORDER_UNIT_PRICE')                                                                        --���P���i�����j
       ,l_data_tab('SHIPPING_UNIT_PRICE')                                                                     --���P���i�o�ׁj
       ,l_data_tab('ORDER_COST_AMT')                                                                          --�������z�i�����j
       ,l_data_tab('SHIPPING_COST_AMT')                                                                       --�������z�i�o�ׁj
       ,l_data_tab('STOCKOUT_COST_AMT')                                                                       --�������z�i���i�j
       ,l_data_tab('SELLING_PRICE')                                                                           --���P��
       ,l_data_tab('ORDER_PRICE_AMT')                                                                         --�������z�i�����j
       ,l_data_tab('SHIPPING_PRICE_AMT')                                                                      --�������z�i�o�ׁj
       ,l_data_tab('STOCKOUT_PRICE_AMT')                                                                      --�������z�i���i�j
       ,l_data_tab('A_COLUMN_DEPARTMENT')                                                                     --�`���i�S�ݓX�j
       ,l_data_tab('D_COLUMN_DEPARTMENT')                                                                     --�c���i�S�ݓX�j
       ,l_data_tab('STANDARD_INFO_DEPTH')                                                                     --�K�i���E���s��
       ,l_data_tab('STANDARD_INFO_HEIGHT')                                                                    --�K�i���E����
       ,l_data_tab('STANDARD_INFO_WIDTH')                                                                     --�K�i���E��
       ,l_data_tab('STANDARD_INFO_WEIGHT')                                                                    --�K�i���E�d��
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM1')                                                                 --�ėp���p�����ڂP
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM2')                                                                 --�ėp���p�����ڂQ
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM3')                                                                 --�ėp���p�����ڂR
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM4')                                                                 --�ėp���p�����ڂS
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM5')                                                                 --�ėp���p�����ڂT
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM6')                                                                 --�ėp���p�����ڂU
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM7')                                                                 --�ėp���p�����ڂV
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM8')                                                                 --�ėp���p�����ڂW
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM9')                                                                 --�ėp���p�����ڂX
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM10')                                                                --�ėp���p�����ڂP�O
       ,l_data_tab('GENERAL_ADD_ITEM1')                                                                       --�ėp�t�����ڂP
       ,l_data_tab('GENERAL_ADD_ITEM2')                                                                       --�ėp�t�����ڂQ
       ,l_data_tab('GENERAL_ADD_ITEM3')                                                                       --�ėp�t�����ڂR
       ,l_data_tab('GENERAL_ADD_ITEM4')                                                                       --�ėp�t�����ڂS
       ,l_data_tab('GENERAL_ADD_ITEM5')                                                                       --�ėp�t�����ڂT
       ,l_data_tab('GENERAL_ADD_ITEM6')                                                                       --�ėp�t�����ڂU
       ,l_data_tab('GENERAL_ADD_ITEM7')                                                                       --�ėp�t�����ڂV
       ,l_data_tab('GENERAL_ADD_ITEM8')                                                                       --�ėp�t�����ڂW
       ,l_data_tab('GENERAL_ADD_ITEM9')                                                                       --�ėp�t�����ڂX
       ,l_data_tab('GENERAL_ADD_ITEM10')                                                                      --�ėp�t�����ڂP�O
       ,l_data_tab('CHAIN_PECULIAR_AREA_LINE')                                                                --�`�F�[���X�ŗL�G���A�i���ׁj
            ------------------------------------------------�t�b�^���------------------------------------------------
       ,l_data_tab('INVOICE_INDV_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�o���j
       ,l_data_tab('INVOICE_CASE_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_ORDER_QTY')                                                                  --�i�`�[�v�j�������ʁi�{�[���j
       ,l_data_tab('INVOICE_SUM_ORDER_QTY')                                                                   --�i�`�[�v�j�������ʁi���v�A�o���j
       ,l_data_tab('INVOICE_INDV_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�o���j
       ,l_data_tab('INVOICE_CASE_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_SHIPPING_QTY')                                                               --�i�`�[�v�j�o�א��ʁi�{�[���j
       ,l_data_tab('INVOICE_PALLET_SHIPPING_QTY')                                                             --�i�`�[�v�j�o�א��ʁi�p���b�g�j
       ,l_data_tab('INVOICE_SUM_SHIPPING_QTY')                                                                --�i�`�[�v�j�o�א��ʁi���v�A�o���j
       ,l_data_tab('INVOICE_INDV_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�o���j
       ,l_data_tab('INVOICE_CASE_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�P�[�X�j
       ,l_data_tab('INVOICE_BALL_STOCKOUT_QTY')                                                               --�i�`�[�v�j���i���ʁi�{�[���j
       ,l_data_tab('INVOICE_SUM_STOCKOUT_QTY')                                                                --�i�`�[�v�j���i���ʁi���v�A�o���j
       ,l_data_tab('INVOICE_CASE_QTY')                                                                        --�i�`�[�v�j�P�[�X����
       ,l_data_tab('INVOICE_FOLD_CONTAINER_QTY')                                                              --�i�`�[�v�j�I���R���i�o���j����
       ,l_data_tab('INVOICE_ORDER_COST_AMT')                                                                  --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_COST_AMT')                                                               --�i�`�[�v�j�������z�i�o�ׁj
       ,l_data_tab('INVOICE_STOCKOUT_COST_AMT')                                                               --�i�`�[�v�j�������z�i���i�j
       ,l_data_tab('INVOICE_ORDER_PRICE_AMT')                                                                 --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_PRICE_AMT')                                                              --�i�`�[�v�j�������z�i�o�ׁj
       ,l_data_tab('INVOICE_STOCKOUT_PRICE_AMT')                                                              --�i�`�[�v�j�������z�i���i�j
       ,l_data_tab('TOTAL_INDV_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�o���j
       ,l_data_tab('TOTAL_CASE_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_ORDER_QTY')                                                                    --�i�����v�j�������ʁi�{�[���j
       ,l_data_tab('TOTAL_SUM_ORDER_QTY')                                                                     --�i�����v�j�������ʁi���v�A�o���j
       ,l_data_tab('TOTAL_INDV_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�o���j
       ,l_data_tab('TOTAL_CASE_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_SHIPPING_QTY')                                                                 --�i�����v�j�o�א��ʁi�{�[���j
       ,l_data_tab('TOTAL_PALLET_SHIPPING_QTY')                                                               --�i�����v�j�o�א��ʁi�p���b�g�j
       ,l_data_tab('TOTAL_SUM_SHIPPING_QTY')                                                                  --�i�����v�j�o�א��ʁi���v�A�o���j
       ,l_data_tab('TOTAL_INDV_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�o���j
       ,l_data_tab('TOTAL_CASE_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�P�[�X�j
       ,l_data_tab('TOTAL_BALL_STOCKOUT_QTY')                                                                 --�i�����v�j���i���ʁi�{�[���j
       ,l_data_tab('TOTAL_SUM_STOCKOUT_QTY')                                                                  --�i�����v�j���i���ʁi���v�A�o���j
       ,l_data_tab('TOTAL_CASE_QTY')                                                                          --�i�����v�j�P�[�X����
       ,l_data_tab('TOTAL_FOLD_CONTAINER_QTY')                                                                --�i�����v�j�I���R���i�o���j����
       ,l_data_tab('TOTAL_ORDER_COST_AMT')                                                                    --�i�����v�j�������z�i�����j
       ,l_data_tab('TOTAL_SHIPPING_COST_AMT')                                                                 --�i�����v�j�������z�i�o�ׁj
       ,l_data_tab('TOTAL_STOCKOUT_COST_AMT')                                                                 --�i�����v�j�������z�i���i�j
       ,l_data_tab('TOTAL_ORDER_PRICE_AMT')                                                                   --�i�����v�j�������z�i�����j
       ,l_data_tab('TOTAL_SHIPPING_PRICE_AMT')                                                                --�i�����v�j�������z�i�o�ׁj
       ,l_data_tab('TOTAL_STOCKOUT_PRICE_AMT')                                                                --�i�����v�j�������z�i���i�j
       ,l_data_tab('TOTAL_LINE_QTY')                                                                          --�g�[�^���s��
       ,l_data_tab('TOTAL_INVOICE_QTY')                                                                       --�g�[�^���`�[����
       ,l_data_tab('CHAIN_PECULIAR_AREA_FOOTER')                                                              --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      ;            
out_line(buff => '1');
      EXIT WHEN cur_data_record%NOTFOUND;
--
      --==============================================================
      --����敪���݃`�F�b�N
      --==============================================================
      IF (lt_last_invoice_number = l_data_tab('INVOICE_NUMBER')) AND cur_data_record%ROWCOUNT > 1 THEN
        --�O��`�[�ԍ�������`�[�ԍ��̏ꍇ
        IF (lt_last_bargain_class != lt_bargain_class AND lb_mix_error_order = FALSE) THEN
          --�O���ԓ����敪�������ԓ����敪�̏ꍇ
          lb_error           := TRUE;
          lb_mix_error_order := TRUE;
          lv_errmsg          := xxccp_common_pkg.get_msg(
                                  cv_apl_name
                                 ,ct_msg_sale_class_mixed
                                 ,cv_tkn_order_no
                                 ,l_data_tab('INVOICE_NUMBER')
                                );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
        END IF;
      ELSE
        --�O��`�[�ԍ�������`�[�ԍ��̏ꍇ
        lt_last_invoice_number  := l_data_tab('INVOICE_NUMBER');
        lt_last_bargain_class   := lt_bargain_class;
        lb_mix_error_order      := FALSE;
        lb_out_flag_error_order := FALSE;
      END IF;
--
      --==============================================================
      --����敪OUTBOUND�ۃt���O�`�F�b�N
      --==============================================================
      IF (lt_outbound_flag = 'N' AND lb_out_flag_error_order = FALSE) THEN
        lb_error                := TRUE;
        lb_out_flag_error_order := TRUE;
        lv_errmsg               := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_sale_class_err
                                    ,cv_tkn_order_no
                                    ,l_data_tab('INVOICE_NUMBER')
                                   );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
      END IF;
--
      --==============================================================
      --������R�t���O�`�F�b�N
      --==============================================================
      IF (ln_reason_id IS NOT NULL) THEN
        IF (NVL(lt_stockout_cancel_flag,'N') = 'N' AND lb_out_flag_error_order = FALSE) THEN
          lb_error                := TRUE;
          lb_out_flag_error_order := TRUE;
          lv_errmsg               := xxccp_common_pkg.get_msg(
                                       cv_apl_name
                                      ,ct_msg_stockout_cancel_err
                                      ,cv_tkn_order_no
                                      ,l_data_tab('INVOICE_NUMBER')
                                     );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
-- 2009/02/19 T.Nakamura Ver.1.6 add start
          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.6 add end
        END IF;
      END IF;
--
      --==============================================================
      --CSV�w�b�_���R�[�h�쐬����
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.7 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.7 mod end
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬�����s�`�[�P�ʂ̕ҏW�t
      --==============================================================
--
      lv_break_key_new    :=  lt_cust_po_number;                                --�u���C�N�L�[�����l�ݒ�F�V
--
      IF ( cur_data_record%ROWCOUNT = 1 ) THEN
        lv_break_key_old  :=  cv_init_cust_po_number;                           --�u���C�N�L�[�����l�ݒ�
      END IF;
out_line(buff => 'lv_break_key_old:' || lv_break_key_old || '   lv_break_key_new:' || lv_break_key_new);
      IF ( lv_break_key_old != lv_break_key_new ) THEN
    --���v���ʂ̍X�V
        FOR i IN 1..lt_tbl.COUNT LOOP
out_line(buff => 'i:' || i);
          lt_tbl(i)('INVOICE_INDV_ORDER_QTY')       := lt_invoice_indv_order_qty;           --�������ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_ORDER_QTY')       := lt_invoice_case_order_qty;           --�������ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_ORDER_QTY')       := lt_invoice_ball_order_qty;           --�������ʁi�{�[���j
          lt_tbl(i)('INVOICE_SUM_ORDER_QTY')        := lt_invoice_sum_order_qty;            --�������ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_INDV_SHIPPING_QTY')    := lt_invoice_indv_shipping_qty;        --�o�א��ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_SHIPPING_QTY')    := lt_invoice_case_shipping_qty;        --�o�א��ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_SHIPPING_QTY')    := lt_invoice_ball_shipping_qty;        --�o�א��ʁi�{�[���j
          lt_tbl(i)('INVOICE_PALLET_SHIPPING_QTY')  := lt_invoice_pallet_shipping_qty;      --�o�א��ʁi�p���b�g�j
          lt_tbl(i)('INVOICE_SUM_SHIPPING_QTY')     := lt_invoice_sum_shipping_qty;         --�o�א��ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_INDV_STOCKOUT_QTY')    := lt_invoice_indv_stockout_qty;        --���i���ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_STOCKOUT_QTY')    := lt_invoice_case_stockout_qty;        --���i���ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_STOCKOUT_QTY')    := lt_invoice_ball_stockout_qty;        --���i���ʁi�{�[���j
          lt_tbl(i)('INVOICE_SUM_STOCKOUT_QTY')     := lt_invoice_sum_stockout_qty;         --���i���ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_CASE_QTY')             := lt_invoice_case_qty;                 --�P�[�X����
          lt_tbl(i)('INVOICE_FOLD_CONTAINER_QTY')   := lt_invoice_fold_container_qty;       --�I���R���i�o���j����
          lt_tbl(i)('INVOICE_ORDER_COST_AMT')       := lt_invoice_order_cost_amt;           --�������z�i�����j
          lt_tbl(i)('INVOICE_SHIPPING_COST_AMT')    := lt_invoice_shipping_cost_amt;        --�������z�i�o�ׁj
          lt_tbl(i)('INVOICE_STOCKOUT_COST_AMT')    := lt_invoice_stockout_cost_amt;        --�������z�i���i�j
          lt_tbl(i)('INVOICE_ORDER_PRICE_AMT')      := lt_invoice_order_price_amt;          --�������z�i�����j
          lt_tbl(i)('INVOICE_SHIPPING_PRICE_AMT')   := lt_invoice_shipping_price_amt;       --�������z�i�o�ׁj
          lt_tbl(i)('INVOICE_STOCKOUT_PRICE_AMT')   := lt_invoice_stockout_price_amt;       --�������z�i���i�j
        --�f�[�^���R�[�h�쐬����
          proc_out_data_record(
            lt_header_id
           ,lt_tbl(i)
           ,lv_errbuf
           ,lv_retcode
           ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.7 mod start
--            RAISE global_process_expt;
            RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.7 mod end
          END IF;
          lv_break_key_old  :=  lv_break_key_new;                             --�u���C�N�L�[�ݒ�
        END LOOP;
    --�O��`�[�ԍ��̃Z�b�g�i�u���C�N�L�[�ݒ�j
        lv_break_key_old    := lv_break_key_new;
    --���v���ʂ̏�����
        lt_invoice_indv_order_qty      := 0;
        lt_invoice_case_order_qty      := 0;
        lt_invoice_ball_order_qty      := 0;
        lt_invoice_sum_order_qty       := 0;
        lt_invoice_indv_shipping_qty   := 0;
        lt_invoice_case_shipping_qty   := 0;
        lt_invoice_ball_shipping_qty   := 0;
        lt_invoice_pallet_shipping_qty := 0;
        lt_invoice_sum_shipping_qty    := 0;
        lt_invoice_indv_stockout_qty   := 0;
        lt_invoice_case_stockout_qty   := 0;
        lt_invoice_ball_stockout_qty   := 0;
        lt_invoice_sum_stockout_qty    := 0;
        lt_invoice_case_qty            := 0;
        lt_invoice_fold_container_qty  := 0;
        lt_invoice_order_cost_amt      := 0;
        lt_invoice_shipping_cost_amt   := 0;
        lt_invoice_stockout_cost_amt   := 0;
        lt_invoice_order_price_amt     := 0;
        lt_invoice_shipping_price_amt  := 0;
        lt_invoice_stockout_price_amt  := 0;
    --�e�e�[�u���̏�����
        lt_tbl := lt_tbl_init;
    --�e�e�[�u���C���f�b�N�X�̏�����
        ln_cnt := 0;
      END IF;
  --�e�e�[�u���C���f�b�N�X�̃C���N�������g
      ln_cnt := ln_cnt + 1;
  --���v���ʂ̉��Z
      lt_invoice_indv_order_qty      := lt_invoice_indv_order_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_ORDER_QTY') ),0 );
      lt_invoice_case_order_qty      := lt_invoice_case_order_qty   
                                      + NVL( TO_NUMBER( l_data_tab('CASE_ORDER_QTY') ),0 );
      lt_invoice_ball_order_qty      := lt_invoice_ball_order_qty   
                                      + NVL( TO_NUMBER( l_data_tab('BALL_ORDER_QTY') ),0 );
      lt_invoice_sum_order_qty       := lt_invoice_sum_order_qty    
                                      + NVL( TO_NUMBER( l_data_tab('SUM_ORDER_QTY') ),0 );
      lt_invoice_indv_shipping_qty   := lt_invoice_indv_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_SHIPPING_QTY') ),0 );
      lt_invoice_case_shipping_qty   := lt_invoice_case_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_SHIPPING_QTY') ),0 );
      lt_invoice_ball_shipping_qty   := lt_invoice_ball_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('BALL_SHIPPING_QTY') ),0 );
      lt_invoice_pallet_shipping_qty := lt_invoice_pallet_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('PALLET_SHIPPING_QTY') ),0 );
      lt_invoice_sum_shipping_qty    := lt_invoice_sum_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('SUM_SHIPPING_QTY') ),0 );
      lt_invoice_indv_stockout_qty   := lt_invoice_indv_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_STOCKOUT_QTY') ),0 );
      lt_invoice_case_stockout_qty   := lt_invoice_case_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_STOCKOUT_QTY') ),0 );
      lt_invoice_ball_stockout_qty   := lt_invoice_ball_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('BALL_STOCKOUT_QTY') ),0 );
      lt_invoice_sum_stockout_qty    := lt_invoice_sum_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('SUM_STOCKOUT_QTY') ),0 );
      lt_invoice_case_qty            := lt_invoice_case_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_QTY') ),0 );
      lt_invoice_fold_container_qty  := lt_invoice_fold_container_qty
                                      + NVL( TO_NUMBER( l_data_tab('FOLD_CONTAINER_INDV_QTY') ),0 );
      lt_invoice_order_cost_amt      := lt_invoice_order_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('ORDER_COST_AMT') ),0 );
      lt_invoice_shipping_cost_amt   := lt_invoice_shipping_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('SHIPPING_COST_AMT') ),0 );
      lt_invoice_stockout_cost_amt   := lt_invoice_stockout_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('STOCKOUT_COST_AMT') ),0 );
      lt_invoice_order_price_amt     := lt_invoice_order_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('ORDER_PRICE_AMT') ),0 );
      lt_invoice_shipping_price_amt  := lt_invoice_shipping_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('SHIPPING_PRICE_AMT') ),0 );
      lt_invoice_stockout_price_amt  := lt_invoice_stockout_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('STOCKOUT_PRICE_AMT') ),0 );
  --�e�e�[�u���Ɏq�e�[�u�����Z�b�g
      lt_tbl(ln_cnt) := l_data_tab;
--
    END LOOP data_record_loop;
    --==============================================================
    --�ŏI���R�[�h�ҏW����
    --==============================================================
    IF ( cur_data_record%ROWCOUNT != 0 )  THEN
    --�ŏI�`�[�ԍ����R�[�h���v���ʂ̍X�V
        FOR i IN 1..lt_tbl.COUNT LOOP
          lt_tbl(i)('INVOICE_INDV_ORDER_QTY')       := lt_invoice_indv_order_qty;           --�������ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_ORDER_QTY')       := lt_invoice_case_order_qty;           --�������ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_ORDER_QTY')       := lt_invoice_ball_order_qty;           --�������ʁi�{�[���j
          lt_tbl(i)('INVOICE_SUM_ORDER_QTY')        := lt_invoice_sum_order_qty;            --�������ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_INDV_SHIPPING_QTY')    := lt_invoice_indv_shipping_qty;        --�o�א��ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_SHIPPING_QTY')    := lt_invoice_case_shipping_qty;        --�o�א��ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_SHIPPING_QTY')    := lt_invoice_ball_shipping_qty;        --�o�א��ʁi�{�[���j
          lt_tbl(i)('INVOICE_PALLET_SHIPPING_QTY')  := lt_invoice_pallet_shipping_qty;      --�o�א��ʁi�p���b�g�j
          lt_tbl(i)('INVOICE_SUM_SHIPPING_QTY')     := lt_invoice_sum_shipping_qty;         --�o�א��ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_INDV_STOCKOUT_QTY')    := lt_invoice_indv_stockout_qty;        --���i���ʁi�o���j
          lt_tbl(i)('INVOICE_CASE_STOCKOUT_QTY')    := lt_invoice_case_stockout_qty;        --���i���ʁi�P�[�X�j
          lt_tbl(i)('INVOICE_BALL_STOCKOUT_QTY')    := lt_invoice_ball_stockout_qty;        --���i���ʁi�{�[���j
          lt_tbl(i)('INVOICE_SUM_STOCKOUT_QTY')     := lt_invoice_sum_stockout_qty;         --���i���ʁi���v�A�o���j
          lt_tbl(i)('INVOICE_CASE_QTY')             := lt_invoice_case_qty;                 --�P�[�X����
          lt_tbl(i)('INVOICE_FOLD_CONTAINER_QTY')   := lt_invoice_fold_container_qty;       --�I���R���i�o���j����
          lt_tbl(i)('INVOICE_ORDER_COST_AMT')       := lt_invoice_order_cost_amt;           --�������z�i�����j
          lt_tbl(i)('INVOICE_SHIPPING_COST_AMT')    := lt_invoice_shipping_cost_amt;        --�������z�i�o�ׁj
          lt_tbl(i)('INVOICE_STOCKOUT_COST_AMT')    := lt_invoice_stockout_cost_amt;        --�������z�i���i�j
          lt_tbl(i)('INVOICE_ORDER_PRICE_AMT')      := lt_invoice_order_price_amt;          --�������z�i�����j
          lt_tbl(i)('INVOICE_SHIPPING_PRICE_AMT')   := lt_invoice_shipping_price_amt;       --�������z�i�o�ׁj
          lt_tbl(i)('INVOICE_STOCKOUT_PRICE_AMT')   := lt_invoice_stockout_price_amt;       --�������z�i���i�j
        --�f�[�^���R�[�h�쐬����
          proc_out_data_record(
            lt_header_id
           ,lt_tbl(i)
           ,lv_errbuf
           ,lv_retcode
           ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.7 mod start
--            RAISE global_process_expt;
            RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.7 mod end
          END IF;
        END LOOP;
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
-- 2009/02/20 T.Nakamura Ver.1.7 mod start
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.7 mod end
    END IF;
--
    IF (lb_error) THEN
      RAISE sale_class_expt;
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
-- 2009/02/19 T.Nakamura Ver.1.6 add start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.6 add end
    END IF;
--
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ����敪�G���[�n���h�� ***
    WHEN sale_class_expt THEN
      ov_errmsg  := NULL;
-- 2009/02/19 T.Nakamura Ver.1.6 mod start
--      ov_errbuf  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.6 mod end
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
--
    --==============================================================
    --��������
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�w�b�_���R�[�h�쐬����
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
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
    iv_chain_name                IN     VARCHAR2,  --  5.�`�F�[���X��
    iv_store_code                IN     VARCHAR2,  --  6.�X�܃R�[�h
    iv_base_code                 IN     VARCHAR2,  --  7.���_�R�[�h
    iv_base_name                 IN     VARCHAR2,  --  8.���_��
    iv_data_type_code            IN     VARCHAR2,  --  9.���[��ʃR�[�h
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 10.�Ɩ��n��R�[�h
    iv_info_div                  IN     VARCHAR2,  -- 11.���敪
    iv_report_name               IN     VARCHAR2,  -- 12.���[�l��
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 13.�X�ܔ[�i��(FROM�j
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 14.�X�ܔ[�i���iTO�j
    iv_center_delivery_date_from IN     VARCHAR2,  -- 15.�Z���^�[�[�i���iFROM�j
    iv_center_delivery_date_to   IN     VARCHAR2,  -- 16.�Z���^�[�[�i���iTO�j
    iv_bargain_class             IN     VARCHAR2   -- 17.��ԓ����敪
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
    l_input_rec.user_id                   := in_user_id;
    l_input_rec.chain_code                := iv_chain_code;
    l_input_rec.chain_name                := iv_chain_name;
    l_input_rec.store_code                := iv_store_code;
    l_input_rec.base_code                 := iv_base_code;
    l_input_rec.base_name                 := iv_base_name;
    l_input_rec.file_name                 := iv_file_name;
    l_input_rec.data_type_code            := iv_data_type_code;
    l_input_rec.ebs_business_series_code  := iv_ebs_business_series_code;
    l_input_rec.info_div                  := iv_info_div;
    l_input_rec.report_code               := iv_report_code;
    l_input_rec.report_name               := iv_report_name;
    l_input_rec.shop_delivery_date_from   := iv_shop_delivery_date_from;
    l_input_rec.shop_delivery_date_to     := iv_shop_delivery_date_to;
    l_input_rec.center_delivery_date_from := iv_center_delivery_date_from;
    l_input_rec.center_delivery_date_to   := iv_center_delivery_date_to;
    l_input_rec.bargain_class             := iv_bargain_class;
--
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
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.6 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/19 T.Nakamura Ver.1.6 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/12 T.Nakamura Ver.1.1 mod end
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
END XXCOS014A06C;
/
