CREATE OR REPLACE PACKAGE BODY XXCOS014A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A11C (body)
 * Description      : ���ɗ\��f�[�^�̍쐬���s��
 * MD.050           : ���ɗ\����f�[�^�쐬 (MD050_COS_014_A11)
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)(A-1)
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
 *  2009/03/16    1.0   K.Kiriu          �V�K�쐬
 *  2009/07/01    1.1   K.Kiriu          [T1_1359]���ʊ��Z�Ή�
 *  2009/08/18    1.2   K.Kiriu          [0000445]PT�Ή�
 *  2009/09/28    1.3   K.Satomura       [0001156]
 *  2010/03/16    1.4   Y.Kuboshima      [E_�{�ғ�_01833]�E�\�[�g���̕ύX (�w�b�_ID -> �`�[�ԍ�, �i�ڃR�[�h)
 *                                                       �E�w�b�_ID, �i�ڃR�[�h�̃T�}�����폜
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
  exception_name          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS014A11C'; -- �p�b�P�[�W��
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';   -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             --XXCCP:IF���R�[�h�敪_�w�b�_
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               --XXCCP:IF���R�[�h�敪_�f�[�^
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             --XXCCP:IF���R�[�h�敪_�t�b�^
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_REP_OUTBOUND_DIR_INV';  --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(�݌ɊǗ�)
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      --XXCOS:UTL_MAX�s�T�C�Y
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       --MO:�c�ƒP��
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';             --GL��v����ID
  cv_prf_orga_code      CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';     --XXCOI:�݌ɑg�D�R�[�h
  -- ���b�Z�[�W
  cv_msg_input_param1   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13751';             --�p�����[�^�o�̓��b�Z�[�W1
  cv_msg_input_param2   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13752';             --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_file_name      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00130';             --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';             --�v���t�@�C���擾�G���[
  cv_msg_prf_tkn1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';             --IF���R�[�h�敪_�w�b�_
  cv_msg_prf_tkn2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';             --IF���R�[�h�敪_�f�[�^
  cv_msg_prf_tkn3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';             --IF���R�[�h�敪_�t�b�^
  cv_msg_prf_tkn4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00112';             --���[OUTBOUND�o�̓f�B���N�g��(EBS�݌ɊǗ�)
  cv_msg_prf_tkn5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';             --UTL_MAX�s�T�C�Y
  cv_msg_prf_tkn6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';             --�c�ƒP��
  cv_msg_prf_tkn7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';             --GL��v����ID
  cv_msg_prf_tkn8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';             --�݌ɑg�D�R�[�h
  cv_msg_get_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00064';             --�擾�G���[
  cv_msg_org_id_tkn     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';             --�݌ɑg�DID
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';             --IF�t�@�C�����C�A�E�g��`���擾�G���[
  cv_msg_layout_tkn     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';             --�󒍌n���C�A�E�g
  ct_msg_notfnd_mst_err CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00065';             --�}�X�^���o�^
  ct_msg_cust_mst_tkn   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';             --�ڋq�}�X�^
  ct_msg_item_mst_tkn   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';             --�i�ڃ}�X�^
  cv_msg_edi_i_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';             --EDI�A�g�i�ڃR�[�h�敪�G���[
  cv_msg_tax_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13753';             --�ŗ��擾�G���[
  ct_msg_fopen_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';             --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             --�Ώۃf�[�^�Ȃ��G���[
/* 2009/07/01 Ver1.10 Add Start */
  cv_msg_proc_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';             -- ���ʊ֐��G���[
/* 2009/07/01 Ver1.10 Add End   */
  -- �g�[�N���R�[�h
  cv_tkn_param1         CONSTANT VARCHAR2(6)   := 'PARAM1';                       --���̓p�����[�^1
  cv_tkn_param2         CONSTANT VARCHAR2(6)   := 'PARAM2';                       --���̓p�����[�^2
  cv_tkn_param3         CONSTANT VARCHAR2(6)   := 'PARAM3';                       --���̓p�����[�^3
  cv_tkn_param4         CONSTANT VARCHAR2(6)   := 'PARAM4';                       --���̓p�����[�^4
  cv_tkn_param5         CONSTANT VARCHAR2(6)   := 'PARAM5';                       --���̓p�����[�^5
  cv_tkn_param6         CONSTANT VARCHAR2(6)   := 'PARAM6';                       --���̓p�����[�^6
  cv_tkn_param7         CONSTANT VARCHAR2(6)   := 'PARAM7';                       --���̓p�����[�^7
  cv_tkn_param8         CONSTANT VARCHAR2(6)   := 'PARAM8';                       --���̓p�����[�^8
  cv_tkn_param9         CONSTANT VARCHAR2(6)   := 'PARAM9';                       --���̓p�����[�^9
  cv_tkn_param10        CONSTANT VARCHAR2(7)   := 'PARAM10';                      --���̓p�����[�^10
  cv_tkn_filename       CONSTANT VARCHAR2(9)   := 'FILE_NAME';                    --�t�@�C����
  cv_tkn_prf            CONSTANT VARCHAR2(7)   := 'PROFILE';                      --�v���t�@�C������
  cv_tkn_date           CONSTANT VARCHAR2(4)   := 'DATA';                         --�f�[�^
  cv_tkn_layout         CONSTANT VARCHAR2(6)   := 'LAYOUT';                       --���C�A�E�g
  cv_tkn_chain_s        CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';              --�`�F�[���X
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';                        --�e�[�u��
/* 2009/07/01 Ver1.10 Add Start */
  cv_tkn_err_msg        CONSTANT VARCHAR2(6)   := 'ERRMSG';                       -- ���ʊ֐��G���[
/* 2009/07/01 Ver1.10 Add End   */
  --���t
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            --�V�X�e�����t
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; --�Ɩ�������
  --����
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                     --���t�t�H�[�}�b�g(��)
  cv_date_format10      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                   --���t�t�H�[�}�b�g(��)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';                     --���t�t�H�[�}�b�g(����)
  --�ڋq�}�X�^�擾�p
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                           --�ڋq�敪(�`�F�[���X)
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                           --�ڋq�敪(�ڋq)
  cv_cust_status        CONSTANT VARCHAR2(2)   := '90';                           --�ڋq�X�e�[�^�X(���~���ٍ�)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                            --�X�e�[�^�X(�ڋq�L��)
  --���ʊ֐��p
  gt_f_handle           UTL_FILE.FILE_TYPE;                                                 --�t�@�C���n���h��
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;                            --�t�@�C�����C�A�E�g
  cv_file_format        CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_file_type_variable;  --�ϒ�
  cv_layout_class       CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_layout_class_order;  --�󒍌n
  cv_media_class        CONSTANT VARCHAR2(2)   := '01';                                     --�}�̋敪
  cv_utl_file_mode      CONSTANT VARCHAR2(1)   := 'w';                                      --TL_FILE.�I�[�v�����[�h
  cv_siege              CONSTANT VARCHAR2(1)   := CHR(34);                                  --�_�u���N�H�[�e�[�V����
  cv_delimiter          CONSTANT VARCHAR2(1)   := CHR(44);                                  --�J���}
  cv_file_num           CONSTANT VARCHAR2(2)   := '00';                                     --�t�@�C��No
/* 2009/07/01 Ver1.10 Add Start */
  cv_uom_code_dummy     CONSTANT VARCHAR2(1)   := 'X';                           --�P�ʃR�[�h(���ʊ֐��p�̃_�~�[)
/* 2009/07/01 Ver1.10 Add End   */
  --���̑�
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                           --�Œ�l:1(VARCHAR)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                           --�Œ�l:2(VARCHAR)
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                           --�Œ�l:Y(VARCHAR)
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                           --�Œ�l:N(VARCHAR)
  cn_0                  CONSTANT NUMBER        := 0;                             --�Œ�l:0(NUMBER)
  cn_1                  CONSTANT NUMBER        := 1;                             --�Œ�l:1(NUMBER)
  cn_10                 CONSTANT NUMBER        := 10;                            --�Œ�l:10(NUMBER)
  cn_11                 CONSTANT NUMBER        := 11;                            --�Œ�l:11(NUMBER)
  cn_15                 CONSTANT NUMBER        := 15;                            --�Œ�l:15(NUMBER)
  cn_16                 CONSTANT NUMBER        := 16;                            --�Œ�l:16(NUMBER)
  -- �f�[�^�ҏW���ʊ֐��p
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  --�}�̋敪
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                --�f�[�^��R�[�h
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       --�t�@�C��No
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    --���敪
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  --������
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  --��������
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     --���_(����)�R�[�h
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     --���_��(������)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 --���_��(�J�i)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                --EDI�`�F�[���X�R�[�h
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                --EDI�`�F�[���X��(����)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            --EDI�`�F�[���X��(�J�i)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    --�`�F�[���X�R�[�h
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    --�`�F�[���X��(����)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                --�`�F�[���X��(�J�i)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   --���[�R�[�h
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              --���[�\����
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 --�ڋq�R�[�h
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 --�ڋq��(����)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             --�ڋq��(�J�i)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  --�ЃR�[�h
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  --�Ж�(����)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              --�Ж�(�J�i)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     --�X�R�[�h
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     --�X��(����)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 --�X��(�J�i)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          --�[���Z���^�[�R�[�h
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          --�[���Z���^�[��(����)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      --�[����Z���^�[��(�J�i)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    --������
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          --�Z���^�[�[�i��
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          --���[�i��
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            --�X�ܔ[�i��
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   --�f�[�^�쐬��(EDI�f�[�^��)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   --�f�[�^�쐬����(EDI�f�[�^��)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 --�`�[�敪
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     --�����ރR�[�h
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     --�����ޖ�
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    --�����ރR�[�h
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    --�����ޖ�
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       --�啪�ރR�[�h
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       --�啪�ޖ�
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   --����敔��R�[�h
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      --����攭���ԍ�
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             --�`�F�b�N�f�W�b�g�L���敪
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                --�`�[�ԍ�
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   --�`�F�b�N�f�W�b�g
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    --����
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  --��No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 --�����敪
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               --�z���敪
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                --��No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    --�A����
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   --���[�g�Z�[���X
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                --�@�l�R�[�h
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    --���[�J�[��
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     --�n��R�[�h
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     --�n�於(����)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 --�n�於(�J�i)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   --�����R�[�h
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   --����於(����)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              --����於1(�J�i)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              --����於2(�J�i)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    --�����TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 --�����S����
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                --�����Z��(����)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        --�͂���R�[�h(�ɓ���)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         --�͂���R�[�h(�`�F�[���X)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    --�͂���(����)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               --�͂���1(�J�i)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               --�͂���2(�J�i)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            --�͂���Z��(����)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        --�͂���Z��(�J�i)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                --�͂���TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         --������R�[�h
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; --������ЃR�[�h
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    --������X�R�[�h
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         --�����於(����)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     --�����於(�J�i)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      --������Z��(����)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  --������Z��(�J�i)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          --������TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           --�󒍉\��
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      --���e�\��
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 --����N����
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       --�x�����ϓ�
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    --�`���V�J�n��
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              --��������
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 --�o�׎���
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        --�[�i�\�莞��
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    --��������
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            --�ėp���t����1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            --�ėp���t����2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            --�ėp���t����3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            --�ėp���t����4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            --�ėp���t����5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        --���o�׋敪
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  --�����敪
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        --�`�[����敪
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          --�P���g�p�敪
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  --�T�u�����Z���^�[�R�[�h
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  --�T�u�����Z���^�[�R�[�h��
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        --�Z���^�[�[�i���@
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              --�Z���^�[���p�敪
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             --�Z���^�[�q�ɋ敪
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             --�Z���^�[�n��敪
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          --�Z���^�[���׋敪
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   --�f�|�敪
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    --TCDC�敪
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      --UPC�t���O
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          --��ċ敪
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   --�Ɩ�ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           --�q���敪
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          --���ڎ��
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     --�i�i���ߋ敪
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        --�߉ƐH�敪
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     --���݋敪
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     --�݌ɋ敪
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        --�ŏI�C���ꏊ�敪
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  --���[�敪
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           --�ǉ��E�v��敪
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            --�o�^�敪
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                --����敪
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                --����敪
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   --�����敪
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                --�W�v���׋敪
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       --�o�׈ē��ȊO�敪
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                --�o�׋敪
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        --���i�R�[�h�g�p�敪
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              --�ϑ��i�敪
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      --T�^A�敪
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     --��溰��
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 --�J�e�S���[�R�[�h
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                --�J�e�S���[�敪
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 --�^����i
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  --����R�[�h
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     --�ړ��T�C��
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         --EOS�E�菑�敪
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      --�[�i��ۃR�[�h
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              --�`�[����
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    --�Y�t��
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             --�t���A
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       --TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 --�C���X�g�A�R�[�h
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      --�^�O
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              --����
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 --��������
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              --�`�F�[���X�g�A�[�R�[�h
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        --���ݽı����ޗ�������
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      --���z���^���旿
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     --��`���
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   --�E�v1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 --�����R�[�h
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  --������� �[�i�J�e�S���[
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 --�d���`��
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          --�[�i�ꏊ��(�J�i)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              --�X�o�ꏊ
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  --���ꖼ
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              --�����ԍ�
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   --�S���Җ�
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     --�l�D
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      --�Ŏ�
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         --����ŋ敪
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   --BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       --ID�R�[�h
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               --�S�ݓX�R�[�h
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               --�S�ݓX��
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              --�i�ʔԍ�
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        --�E�v2
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              --�l�D���@
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 --���R��
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               --A���w�b�_
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               --D���w�b�_
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    --�u�����h�R�[�h
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     --���C���R�[�h
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    --�N���X�R�[�h
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     --A�|1��
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     --B�|1��
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     --C�|1��
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     --D�|1��
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     --E�|1��
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     --A�|2��
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     --B�|2��
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     --C�|2��
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     --D�|2��
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     --E�|2��
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     --A�|3��
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     --B�|3��
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     --C�|3��
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     --D�|3��
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     --E�|3��
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     --F�|1��
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     --G�|1��
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     --H�|1��
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     --I�|1��
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     --J�|1��
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     --K�|1��
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     --L�|1��
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     --F�|2��
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     --G�|2��
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     --H�|2��
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     --I�|2��
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     --J�|2��
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     --K�|2��
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     --L�|2��
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     --F�|3��
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     --G�|3��
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     --H�|3��
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     --I�|3��
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     --J�|3��
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     --K�|3��
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     --L�|3��
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    --�`�F�[���X�ŗL�G���A(�w�b�_)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       --�󒍊֘A�ԍ�(��)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       --�sNo
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                --���i�敪
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               --���i���R
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           --���i�R�[�h(�ɓ���)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 --���i�R�[�h1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 --���i�R�[�h2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      --JAN�R�[�h
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      --ITF�R�[�h
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            --����ITF�R�[�h
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             --�P�[�X���i�R�[�h
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             --�{�[�����i�R�[�h
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        --���i�R�[�h�i��
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    --���i�敪
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  --���i��(����)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             --���i��1(�J�i)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             --���i��2(�J�i)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                --�K�i1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                --�K�i2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   --����
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  --�P�[�X����
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   --�{�[������
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    --�F
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     --�T�C�Y
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               --�ܖ�������
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  --������
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 --�����P�ʐ�
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              --�o�גP�ʐ�
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               --����P�ʐ�
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     --����
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    --�����敪
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                --�ƍ�
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      --�P��
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              --�P���敪
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         --�e����ԍ�
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                --����ԍ�
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            --���i�Q�R�[�h
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           --�P�[�X��̕s�t���O
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    --�P�[�X�敪
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                --��������(�o��)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                --��������(�P�[�X)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                --��������(�{�[��)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 --��������(���v�A�o��)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             --�o�א���(�o��)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             --�o�א���(�P�[�X)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             --�o�א���(�{�[��)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           --�o�א���(�p���b�g)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              --�o�א���(���v�A�o��)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             --���i����(�o��)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             --���i����(�P�[�X)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             --���i����(�{�[��)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              --���i����(���v�A�o��)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      --�P�[�X����
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       --�I���R��(�o��)����
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              --���P��(����)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           --���P��(�o��)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                --�������z(����)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             --�������z(�o��)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             --�������z(���i)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 --���P��
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               --�������z(����)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            --�������z(�o��)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            --�������z(���i)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           --A��(�S�ݓX)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           --D��(�S�ݓX)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           --�K�i���E���s��
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          --�K�i���E����
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           --�K�i���E��
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          --�K�i���E�d��
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       --�ėp���p������1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       --�ėp���p������2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       --�ėp���p������3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       --�ėp���p������4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       --�ėp���p������5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       --�ėp���p������6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       --�ėp���p������7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       --�ėp���p������8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       --�ėp���p������9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      --�ėp���p������10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             --�ėp�t������1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             --�ėp�t������2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             --�ėp�t������3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             --�ėp�t������4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             --�ėp�t������5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             --�ėp�t������6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             --�ėp�t������7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             --�ėp�t������8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             --�ėp�t������9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            --�ėp�t������10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      --�`�F�[���X�ŗL�G���A(����)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        --(�`�[�v)��������(�o��)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        --(�`�[�v)��������(�P�[�X)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        --(�`�[�v)��������(�{�[��)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         --(�`�[�v)��������(���v�A�o��)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     --(�`�[�v)�o�א���(�o��)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     --(�`�[�v)�o�א���(�P�[�X)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     --(�`�[�v)�o�א���(�{�[��)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   --(�`�[�v)�o�א���(�p���b�g)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      --(�`�[�v)�o�א���(���v�A�o��)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     --(�`�[�v)���i����(�o��)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     --(�`�[�v)���i����(�P�[�X)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     --(�`�[�v)���i����(�{�[��)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      --(�`�[�v)���i����(���v�A�o��)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              --(�`�[�v)�P�[�X����
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    --(�`�[�v)�I���R��(�o��)����
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        --(�`�[�v)�������z(����)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     --(�`�[�v)�������z(�o��)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     --(�`�[�v)�������z(���i)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       --(�`�[�v)�������z(����)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    --(�`�[�v)�������z(�o��)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    --(�`�[�v)�������z(���i)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          --(�����v)��������(�o��)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          --(�����v)��������(�P�[�X)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          --(�����v)��������(�{�[��)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           --(�����v)��������(���v�A�o��)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       --(�����v)�o�א���(�o��)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       --(�����v)�o�א���(�P�[�X)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       --(�����v)�o�א���(�{�[��)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     --(�����v)�o�א���(�p���b�g)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        --(�����v)�o�א���(���v�A�o��)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       --(�����v)���i����(�o��)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       --(�����v)���i����(�P�[�X)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       --(�����v)���i����(�{�[��)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        --(�����v)���i����(���v�A�o��)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                --(�����v)�P�[�X����
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      --(�����v)�I���R��(�o��)����
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          --(�����v)�������z(����)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       --(�����v)�������z(�o��)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       --(�����v)�������z(���i)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         --(�����v)�������z(����)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      --(�����v)�������z(�o��)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      --(�����v)�������z(���i)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                --�g�[�^���s��
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             --�g�[�^���`�[����
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    --�`�F�[���X�ŗL�G���A(�t�b�^)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[���R�[�h
  TYPE g_param_rtype IS RECORD (
     file_name           VARCHAR2(100)                                    --�t�@�C����
    ,chain_code          xxcmm_cust_accounts.edi_chain_code%TYPE          --�`�F�[���X�R�[�h
    ,report_code         xxcos_report_forms_register.report_code%TYPE     --���[�R�[�h
    ,user_id             NUMBER                                           --���[�UID
    ,chain_name          hz_parties.party_name%TYPE                       --�`�F�[���X��
    ,store_code          xxcmm_cust_accounts.store_code%TYPE              --�X�܃R�[�h
    ,base_code           xxcmm_cust_accounts.delivery_base_code%TYPE      --���_�R�[�h
    ,base_name           hz_parties.party_name%TYPE                       --���_��
    ,data_type_code      xxcos_report_forms_register.data_type_code%TYPE  --���[��ʃR�[�h
    ,oprtn_series_code   fnd_lookup_values.attribute1%TYPE                --�Ɩ��n��R�[�h
    ,report_name         xxcos_report_forms_register.report_name%TYPE     --���[�l��
    ,to_subinv_code      xxcos_edi_stc_headers.to_subinventory_code%TYPE  --������ۊǏꏊ�R�[�h
    ,center_code         xxcos_edi_stc_headers.center_code%TYPE           --�Z���^�[�R�[�h
    ,invoice_number      xxcos_edi_stc_headers.invoice_number%TYPE        --�`�[�ԍ�
/* 2009/08/18 Ver1.2 Mod Start */
--    ,sch_ship_date_from  VARCHAR2(10)                                     --�o�ח\���FROM
--    ,sch_ship_date_to    VARCHAR2(10)                                     --�o�ח\���TO
--    ,sch_arrv_date_from  VARCHAR2(10)                                     --���ɗ\���FROM
--    ,sch_arrv_date_to    VARCHAR2(10)                                     --���ɗ\���TO
    ,sch_ship_date_from  xxcos_edi_stc_headers.schedule_shipping_date%TYPE --�o�ח\���FROM
    ,sch_ship_date_to    xxcos_edi_stc_headers.schedule_shipping_date%TYPE --�o�ח\���TO
    ,sch_arrv_date_from  xxcos_edi_stc_headers.schedule_arrival_date%TYPE  --���ɗ\���FROM
    ,sch_arrv_date_to    xxcos_edi_stc_headers.schedule_arrival_date%TYPE  --���ɗ\���TO
/* 2009/08/18 Ver1.2 Mod End   */
    ,move_order_number   xxcos_edi_stc_headers.move_order_num%TYPE        --�ړ��I�[�_�[�ԍ�
    ,edi_send_flag       xxcos_edi_stc_headers.edi_send_flag%TYPE         --EDI���M��
  );
  --�v���t�@�C���l�i�[���R�[�h
  TYPE g_prf_rtype IS RECORD (
     if_header                fnd_profile_option_values.profile_option_value%TYPE --�w�b�_���R�[�h���ʎq
    ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --�f�[�^���R�[�h���ʎq
    ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --�t�b�^���R�[�h���ʎq
    ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE�ő�s�T�C�Y
    ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --�o�̓f�B���N�g��
    ,set_of_books_id          NUMBER                                              --GL��v����ID
    ,org_id                   NUMBER                                              --ORG_ID
    ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --�݌ɑg�D�R�[�h
  );
  --���ɗ\����
  TYPE g_edi_stc_data_rtype IS RECORD(
    header_id                    xxcos_edi_stc_headers.header_id%TYPE,                    --�w�b�_ID
    move_order_header_id         xxcos_edi_stc_headers.move_order_header_id%TYPE,         --�ړ��I�[�_�[�w�b�_ID
    move_order_num               xxcos_edi_stc_headers.move_order_num%TYPE,               --�ړ��I�[�_�[�ԍ�
    to_subinventory_code         xxcos_edi_stc_headers.to_subinventory_code%TYPE,         --������ۊǏꏊ
    customer_code                xxcos_edi_stc_headers.customer_code%TYPE,                --�ڋq�R�[�h
    customer_name                hz_parties.party_name%TYPE,                              --�ڋq����
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,              --�ڋq���J�i
    shop_code                    xxcos_edi_stc_headers.shop_code%TYPE,                    --�X�R�[�h
    shop_name                    xxcmm_cust_accounts.cust_store_name%TYPE,                --�X��(����)
    center_code                  xxcos_edi_stc_headers.center_code%TYPE,                  --�Z���^�[�R�[�h
    invoice_number               xxcos_edi_stc_headers.invoice_number%TYPE,               --�`�[�ԍ�
    other_party_department_code  xxcos_edi_stc_headers.other_party_department_code%TYPE,  --����敔��R�[�h
    schedule_shipping_date       xxcos_edi_stc_headers.schedule_shipping_date%TYPE,       --�o�ח\���
    schedule_arrival_date        xxcos_edi_stc_headers.schedule_arrival_date%TYPE,        --���ɗ\���
    rcpt_possible_date           xxcos_edi_stc_headers.rcpt_possible_date%TYPE,           --����\��
    inspect_schedule_date        xxcos_edi_stc_headers.inspect_schedule_date%TYPE,        --���i�\���
    invoice_class                xxcos_edi_stc_headers.invoice_class%TYPE,                --�`�[�敪
    classification_class         xxcos_edi_stc_headers.classification_class%TYPE,         --���ދ敪
    whse_class                   xxcos_edi_stc_headers.whse_class%TYPE,                   --�q�ɋ敪
    regular_ar_sale_class        xxcos_edi_stc_headers.regular_ar_sale_class%TYPE,        --��ԓ����敪
    opportunity_code             xxcos_edi_stc_headers.opportunity_code%TYPE,             --�փR�[�h
    line_no                      NUMBER,                                                  --�sNo
    inventory_item_id            xxcos_edi_stc_lines.inventory_item_id%TYPE,              --�i��ID
    organization_id              xxcos_edi_stc_headers.organization_id%TYPE,              --�g�DID
    item_code                    mtl_system_items_b.segment1%TYPE,                        --�i�ڃR�[�h
    item_name                    xxcmn_item_mst_b.item_name%TYPE,                         --�i�ږ�����
    item_phonetic1               VARCHAR2(15),                                            --�i�ږ��J�i�P
    item_phonetic2               VARCHAR2(15),                                            --�i�ږ��J�i�Q
    case_inc_num                 ic_item_mst_b.attribute11%TYPE,                          --�P�[�X����
    bowl_inc_num                 xxcmm_system_items_b.bowl_inc_num%TYPE,                  --�{�[������
    jan_code                     ic_item_mst_b.attribute21%TYPE,                          --JAN�R�[�h
    itf_code                     ic_item_mst_b.attribute22%TYPE,                          --ITF�R�[�h
    item_div_code                mtl_categories_b.segment1%TYPE,                          --�{�Џ��i�敪
    customer_item_number         mtl_customer_items.customer_item_number%TYPE,            --�ڋq�i�ڃR�[�h
    case_qty                     NUMBER,                                                  --�P�[�X��
    indv_qty                     NUMBER,                                                  --�o����
    ship_qty                     NUMBER                                                   --�o�א���(���v�A�o��)
  );
  --�w�b�_���
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        hz_cust_accounts.account_number%TYPE,         --�[�i���_�R�[�h
    delivery_base_name        hz_parties.party_name%TYPE,                   --�[�i���_��
    delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE,   --�[�i���_�J�i
    delivery_base_l_phonetic  hz_locations.address_lines_phonetic%TYPE,     --�[�i���_�d�b�ԍ�
    edi_chain_name            hz_parties.party_name%TYPE,                   --EDI�`�F�[���X��
    edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE    --EDI�`�F�[���X�J�i
  );
  --�`�[�v���
  TYPE g_sum_qty_rtype IS RECORD(
    invc_case_qty_sum  NUMBER,
    invc_indv_qty_sum  NUMBER,
    invc_ship_qty_sum  NUMBER
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --���ɗ\���� �e�[�u���^
  TYPE g_edi_stc_data_ttype IS TABLE OF g_edi_stc_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_stc_date  g_edi_stc_data_ttype;
  --�`�[�v��� �e�[�u���^
  TYPE g_sum_qty_ttype IS TABLE OF g_sum_qty_rtype INDEX BY BINARY_INTEGER;
  gt_sum_qty       g_sum_qty_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --���R�[�h
  gt_param_rec    g_param_rtype;        --���̓p�����[�^�i�[���R�[�h
  gt_prf_rec      g_prf_rtype;          --�v���t�@�C���i�[���R�[�h
  gt_header_data  g_header_data_rtype;  --�w�b�_���i�[���R�[�h
  --�t�@�C���o�͍��ڗp
  gv_f_o_date           CHAR(8);                         --������
  gv_f_o_time           CHAR(6);                         --��������
  gv_csv_header         VARCHAR2(32767);                 --CSV�w�b�_
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;  --�ŗ�
  gv_cust_mst_err_msg   VARCHAR2(5000);                  --�ڋq�}�X�^�Ȃ����b�Z�[�W
  gv_item_mst_err_msg   VARCHAR2(5000);                  --�i�ڃ}�X�^�Ȃ����b�Z�[�W
  --���̑����ڎ擾�p
  gn_orga_id            NUMBER;                                        --�݌ɑg�DID
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    --EDI�A�g�i�ڃR�[�h�敪
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         --�ڋqID(�`�F�[���X)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_param_msg   VARCHAR2(5000);  --�p�����[�^�[�o�͗p
    ln_err_chk     NUMBER(1);       --�G���[�`�F�b�N�p
    lv_tkn_name1   VARCHAR2(50);    --�g�[�N���擾�p1
    lv_err_msg     VARCHAR2(5000);  --�G���[�o�͗p(�擾�G���[���Ƃɏo�͂����)
    lv_errbuf_all  VARCHAR2(32767); --���O���b�Z�[�W�i�[�ϐ�
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    --�p�����[�^�P�`�P�O�̎擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,cv_msg_input_param1
                     ,cv_tkn_param1
                     ,gt_param_rec.file_name           --�t�@�C����
                     ,cv_tkn_param2
                     ,gt_param_rec.chain_code          --�`�F�[���X�R�[�h
                     ,cv_tkn_param3
                     ,gt_param_rec.report_code         --���[�R�[�h
                     ,cv_tkn_param4
                     ,TO_CHAR( gt_param_rec.user_id )  --���[�U�[ID
                     ,cv_tkn_param5
                     ,gt_param_rec.chain_name          --�`�F�[���X��
                     ,cv_tkn_param6
                     ,gt_param_rec.store_code          --�X�܃R�[�h
                     ,cv_tkn_param7
                     ,gt_param_rec.base_code           --���_�R�[�h
                     ,cv_tkn_param8
                     ,gt_param_rec.base_name           --���_��
                     ,cv_tkn_param9 
                     ,gt_param_rec.data_type_code      --���[��ʃR�[�h
                     ,cv_tkn_param10
                     ,gt_param_rec.oprtn_series_code   --�Ɩ��n��R�[�h
                    );
    --�p�����[�^�����b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --�p�����[�^�����O�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --�p�����[�^�P�P�`�Q�O�̎擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,cv_msg_input_param2
                     ,cv_tkn_param1
                     ,gt_param_rec.report_name         --���[�l��
                     ,cv_tkn_param2
                     ,gt_param_rec.to_subinv_code      --������ۊǏꏊ
                     ,cv_tkn_param3
                     ,gt_param_rec.center_code         --�Z���^�[�R�[�h
                     ,cv_tkn_param4
                     ,gt_param_rec.invoice_number      --�`�[�ԍ�
                     ,cv_tkn_param5
/* 2009/08/18 Ver1.2 Mod Start */
--                     ,gt_param_rec.sch_ship_date_from  --�o�ח\���FROM
--                     ,cv_tkn_param6
--                     ,gt_param_rec.sch_ship_date_to    --�o�ח\���TO
--                     ,cv_tkn_param7
--                     ,gt_param_rec.sch_arrv_date_from  --���ɗ\���FROM
--                     ,cv_tkn_param8
--                     ,gt_param_rec.sch_arrv_date_to    --���ɗ\���TO
                     ,TO_CHAR( gt_param_rec.sch_ship_date_from, cv_date_format10 ) --�o�ח\���FROM
                     ,cv_tkn_param6
                     ,TO_CHAR( gt_param_rec.sch_ship_date_to, cv_date_format10 )   --�o�ח\���TO
                     ,cv_tkn_param7
                     ,TO_CHAR( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) --���ɗ\���FROM
                     ,cv_tkn_param8
                     ,TO_CHAR( gt_param_rec.sch_arrv_date_to, cv_date_format10 )   --���ɗ\���TO
/* 2009/08/18 Ver1.2 Mod End   */
                     ,cv_tkn_param9 
                     ,gt_param_rec.move_order_number   --�ړ��I�[�_�[�ԍ�
                     ,cv_tkn_param10
                     ,gt_param_rec.edi_send_flag       --EDI���M��
                    );
    --�p�����[�^�����b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --�p�����[�^�����O�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --�󔒍s�̏o��(�o��)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    --I/F�t�@�C�����o��
    --==============================================================
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,ct_msg_file_name
                     ,cv_tkn_filename
                     ,gt_param_rec.file_name  --�t�@�C����
                    );
    --�t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    --�󔒍s�̏o��(�o��)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�󔒍s�̏o��(���O)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --==============================================================
    --�V�X�e�����t�擾
    --==============================================================
    gv_f_o_date := TO_CHAR(cd_sysdate, cv_date_format);  --������
    gv_f_o_time := TO_CHAR(cd_sysdate, cv_time_format);  --��������
    --==============================================================
    --�v���t�@�C���̎擾
    --==============================================================
    ln_err_chk                   := 0;                                                --�G���[�`�F�b�N�p�ϐ��̏�����
    gt_prf_rec.if_header         := FND_PROFILE.VALUE( cv_prf_if_header );            --�w�b�_���R�[�h�敪
    gt_prf_rec.if_data           := FND_PROFILE.VALUE( cv_prf_if_data );              --�f�[�^���R�[�h�敪
    gt_prf_rec.if_footer         := FND_PROFILE.VALUE( cv_prf_if_footer );            --�t�b�^���R�[�h�敪
    gt_prf_rec.rep_outbound_dir  := FND_PROFILE.VALUE( cv_prf_outbound_d );           --�A�E�g�o�E���h�p�f�B���N�g���p�X
    gt_prf_rec.utl_max_linesize  := FND_PROFILE.VALUE( cv_prf_utl_m_line );           --UTL_MAX�s�T�C�Y
    gt_prf_rec.org_id            := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );  --�c�ƒP��
    gt_prf_rec.set_of_books_id   := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );  --GL��v����ID
    gt_prf_rec.organization_code := FND_PROFILE.VALUE( cv_prf_orga_code );            --�݌ɑg�D�R�[�h
    --�w�b�_���R�[�h�敪�̃`�F�b�N
    IF ( gt_prf_rec.if_header IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn1  --�w�b�_���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;              --�G���[�L��
    END IF;
    --�f�[�^���R�[�h�敪�̃`�F�b�N
    IF ( gt_prf_rec.if_data IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn2  --�f�[�^���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --�t�b�^���R�[�h�敪�̃`�F�b�N
    IF ( gt_prf_rec.if_footer IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn3  --�t�b�^���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --�A�E�g�o�E���h�p�f�B���N�g���p�X�̃`�F�b�N
    IF ( gt_prf_rec.rep_outbound_dir IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn4  --�A�E�g�o�E���h�p�f�B���N�g���p�X
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --UTL_MAX�s�T�C�Y�̃`�F�b�N
    IF ( gt_prf_rec.utl_max_linesize IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn5  --UTL_MAX�s�T�C�Y
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --�c�ƒP�ʂ̃`�F�b�N
    IF ( gt_prf_rec.org_id IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn6  --�c�ƒP��
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --GL��v����ID�̃`�F�b�N
    IF ( gt_prf_rec.set_of_books_id IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn7  --GL��v����ID
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --�݌ɑg�D�R�[�h�̃`�F�b�N
    IF ( gt_prf_rec.organization_code IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn8  --�݌ɑg�D�R�[�h
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                    );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
    --�݌ɑg�DID�̎擾�ƃ`�F�b�N
    IF ( gt_prf_rec.organization_code ) IS NOT NULL THEN
      --�擾
      gn_orga_id := xxcoi_common_pkg.get_organization_id( gt_prf_rec.organization_code );
      --�`�F�b�N
      IF ( gn_orga_id ) IS NULL THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_org_id_tkn  --�݌ɑg�DID
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_get_err  --�擾�G���[
                       ,iv_token_name1  => cv_tkn_date
                       ,iv_token_value1 => lv_tkn_name1    --�݌ɑg�DID
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --���O���b�Z�[�W�ҏW
        ln_err_chk := 1;                               --�G���[�L��
      END IF;
    END IF;
    --==============================================================
    --���C�A�E�g��`���̎擾
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      iv_file_type        => cv_file_format      --�t�@�C���`��(�ϒ�)
     ,iv_layout_class     => cv_layout_class     --���敪(�󒍌n)
     ,ov_data_type_table  => gt_data_type_table  --�f�[�^�^�\
     ,ov_csv_header       => gv_csv_header       --CSV�w�b�_
     ,ov_errbuf           => lv_errbuf           --�G���[���b�Z�[�W
     ,ov_retcode          => lv_retcode          --���^�[���R�[�h
     ,ov_errmsg           => lv_err_msg          --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_layout_tkn  --�󒍌n���C�A�E�g
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_file_inf_err  --IF�t�@�C�����C�A�E�g��`���擾�G���[
                     ,iv_token_name1  => cv_tkn_layout
                     ,iv_token_value1 => lv_tkn_name1         --�󒍌n���C�A�E�g
                    );
      lv_errbuf_all := lv_errbuf_all || lv_errbuf;   --���O���b�Z�[�W�ҏW
      ln_err_chk := 1;                               --�G���[�L��
    END IF;
--
    --�G���[������ꍇ
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�}�X�^�Ȃ����b�Z�[�W�擾
    --==============================================================
    --�ڋq�}�X�^
    lv_tkn_name1 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => ct_msg_cust_mst_tkn  --�ڋq�}�X�^
                    );
    gv_cust_mst_err_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => ct_msg_notfnd_mst_err  --�}�X�^���ݒ�
                            ,iv_token_name1  => cv_tkn_table
                            ,iv_token_value1 => lv_tkn_name1           --�ڋq�}�X�^
                           );
    --�i�ڃ}�X�^
    lv_tkn_name1 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => ct_msg_item_mst_tkn  --�i�ڃ}�X�^
                    );
    gv_item_mst_err_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => ct_msg_notfnd_mst_err  --�}�X�^���ݒ�
                            ,iv_token_name1  => cv_tkn_table
                            ,iv_token_value1 => lv_tkn_name1           --�i�ڃ}�X�^
                           );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf_all,1,5000);
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
   * Procedure Name   : proc_out_header_record
   * Description      : �w�b�_���R�[�h�쐬����(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    lv_if_header  VARCHAR2(32767); --�w�b�_�[�o�͗p
    ln_dummy      NUMBER;          --�w�b�_�o�͂̃��R�[�h�����p(�g�p����Ȃ�)
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
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                       gt_prf_rec.rep_outbound_dir  --OUTBOUND�f�B���N�g��
                      ,gt_param_rec.file_name       --�t�@�C����
                      ,cv_utl_file_mode             --�I�[�v�����[�h
                      ,gt_prf_rec.utl_max_linesize  --UTL_MAX�s�T�C�Y
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                      ,ct_msg_fopen_err        --�t�@�C���I�[�v���G���[
                      ,cv_tkn_filename
                      ,gt_param_rec.file_name  --�t�@�C����
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    --==============================================================
    -- ���ʊ֐��Ăяo��
    --==============================================================
    --���[�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      iv_add_area        => gt_prf_rec.if_header            --�t�^�敪
     ,iv_from_series     => gt_param_rec.oprtn_series_code  --�h�e���Ɩ��n��R�[�h
     ,iv_base_code       => gt_param_rec.base_code          --���_�R�[�h
     ,iv_base_name       => gt_param_rec.base_name          --���_����
     ,iv_chain_code      => gt_param_rec.chain_code         --�`�F�[���X�R�[�h
     ,iv_chain_name      => gt_param_rec.chain_name         --�`�F�[���X����
     ,iv_data_kind       => gt_param_rec.data_type_code     --�f�[�^��R�[�h
     ,iv_chohyo_code     => gt_param_rec.report_code        --���[�R�[�h
     ,iv_chohyo_name     => gt_param_rec.report_name        --���[�\����
     ,in_num_of_item     => gt_data_type_table.COUNT        --���ڐ�
     ,in_num_of_records  => ln_dummy                        --�f�[�^����
     ,ov_retcode         => lv_retcode                      --���^�[���R�[�h
     ,ov_output          => lv_if_header                    --�o�͒l
     ,ov_errbuf          => lv_errbuf                       --�G���[���b�Z�[�W
     ,ov_errmsg          => lv_errmsg                       --���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg; --���O���b�Z�[�W�ҏW
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�@�C���o��
    --==============================================================
    --�w�b�_�o��
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_if_header      --�o�͒l(�w�b�_)
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
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : �f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
/* 2009/07/01 Ver1.10 Add Start */
    ln_indv_shipping_qty  NUMBER;  --�o�א���(�o��)
    ln_case_shipping_qty  NUMBER;  --�o�א���(�P�[�X)
    ln_ball_shipping_qty  NUMBER;  --�o�א���(�{�[��)
    ln_indv_stockout_qty  NUMBER;  --���i����(�o��)
    ln_case_stockout_qty  NUMBER;  --���i����(�P�[�X)
    ln_ball_stockout_qty  NUMBER;  --���i����(�{�[��)
    ln_sum_stockout_qty   NUMBER;  --���i����(���v�A�o��)
/* 2009/07/01 Ver1.10 Add End   */
--
    lt_invc_break  xxcos_edi_stc_headers.header_id%TYPE;  --�u���[�N�p
    ln_line_no     NUMBER;                                --�sNo�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --EDI�A�g�i�ڃR�[�h�u�ڋq�i�ځv
    CURSOR cust_item_cur
    IS
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xesh.header_id                          header_id                    --�w�b�_ID
      SELECT  /*+
                USE_NL(xesl)
              */
              xesh.header_id                          header_id                    --�w�b�_ID
/* 2009/08/18 Ver1.2 Mod End   */
             ,xesh.move_order_header_id               move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
             ,xesh.move_order_num                     move_order_num               --�ړ��I�[�_�[�ԍ�
             ,xesh.to_subinventory_code               to_subinventory_code         --������ۊǏꏊ
             ,xesh.customer_code                      customer_code                --�ڋq�R�[�h
             ,CASE
                WHEN hca.party_name IS NULL THEN       --�ڋq���Ȃ�
                  gv_cust_mst_err_msg
                ELSE
                  hca.party_name
              END                                     customer_name                --�ڋq����
             ,hca.organization_name_phonetic          customer_phonetic            --�ڋq���J�i
             ,xesh.shop_code                          shop_code                    --�X�R�[�h
             ,CASE
                WHEN hca.account_number IS NULL THEN   --�ڋq�Ȃ�
                  gv_cust_mst_err_msg
                ELSE
                  hca.cust_store_name
              END                                     shop_name                    --�X��
             ,xesh.center_code                        center_code                  --�Z���^�[�R�[�h
             ,xesh.invoice_number                     invoice_number               --�`�[�ԍ�
             ,xesh.other_party_department_code        other_party_department_code  --����敔��R�[�h
             ,xesh.schedule_shipping_date             schedule_shipping_date       --�o�ח\���
             ,xesh.schedule_arrival_date              schedule_arrival_date        --���ɗ\���
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --����\��
             ,xesh.inspect_schedule_date              inspect_schedule_date        --���i�\���
             ,xesh.invoice_class                      invoice_class                --�`�[�敪
             ,xesh.classification_class               classification_class         --���ދ敪
             ,xesh.whse_class                         whse_class                   --�q�ɋ敪
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --��ԓ����敪
             ,xesh.opportunity_code                   opportunity_code             --�փR�[�h
             ,TO_NUMBER(NULL)                         line_no                      --�sNo
             ,xesl.inventory_item_id                  inventory_item_id            --�i��ID
             ,xesh.organization_id                    organization_id              --�g�DID
             ,sib.item_code                           item_code                    --�i�ڃR�[�h
             ,CASE
                WHEN imb.item_name IS NULL THEN              --�i���Ȃ�
                  gv_item_mst_err_msg
                ELSE
                  imb.item_name
              END                                     item_name                    --�i�ږ�����
             ,imb.item_phonetic1                      item_phonetic1               --�i�ږ��J�i�P
             ,imb.item_phonetic2                      item_phonetic2               --�i�ږ��J�i�Q
             ,imb.case_inc_num                        case_inc_num                 --�P�[�X����
             ,sib.bowl_inc_num                        bowl_inc_num                 --�{�[������
             ,imb.jan_code                            jan_code                     --JAN�R�[�h
             ,imb.itf_code                            itf_code                     --ITF�R�[�h
             ,xhpc.item_div_h_code                    item_div_code                --�{�Џ��i�敪
             ,mcis.customer_item_number               customer_item_number         --�ڋq�i��
             ,xesl.case_qty_sum                       case_qty                     --�P�[�X��
             ,xesl.indv_qty_sum                       indv_qty                     --�o����
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( imb.case_inc_num, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --�o�א���(���v�A�o��)
      FROM    xxcos_edi_stc_headers    xesh    --���ɗ\��w�b�_
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --�ڋq�X�e�[�^�X(���~���ٍψȊO)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --�X�e�[�^�X(�L��)
              )                        hca     --�ڋq
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
/* 2010/03/17 Ver1.4 Mod Start */
-- �w�b�_ID, �i�ڃR�[�h�̃T�}���̍폜
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
/* 2010/03/17 Ver1.4 Mod End   */
                FROM    xxcos_edi_stc_lines   xesl
/* 2009/08/18 Ver1.2 Add Start */
                       ,xxcos_edi_stc_headers xesh2
                WHERE   xesh2.edi_chain_code = gt_param_rec.chain_code
                AND     xesh2.fix_flag       = cv_y
                AND     xesh2.header_id      = xesl.header_id
/* 2009/08/18 Ver1.2 Add End   */
/* 2010/03/17 Ver1.4 Del Start */
-- �w�b�_ID, �i�ڃR�[�h�̃T�}���̍폜
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
/* 2010/03/17 Ver1.4 Del End   */
              )                        xesl   --���ɗ\�薾��(�i�ڃT�}��)
             ,(
                SELECT  mcix.inventory_item_id  inventory_item_id
                       ,mp.organization_id      organization_id
                       ,customer_item_number    customer_item_number
                       ,mci.attribute1          unit_of_measure
                FROM    mtl_customer_item_xrefs  mcix   --�ڋq�i�ڑ��ݎQ��
                       ,mtl_customer_items       mci    --�ڋq�i��
                       ,mtl_parameters           mp     --�݌ɑg�D
                WHERE   mci.customer_id              = gt_chain_cust_acct_id       --�ڋqID(�`�F�[���X)
                AND     mci.inactive_flag            = cv_n                        --�L��
                AND     mcix.customer_item_id        = mci.customer_item_id        --����(�ڋq�i�ڑ� = �ڋq�i��)
                AND     mcix.inactive_flag           = cv_n                        --�L��
                AND     mp.master_organization_id    = mcix.master_organization_id --����(�݌ɑg�D   = �ڋq�i�ڑ�)
/* 2009/09/28 Ver1.3 Add Start */
                AND     mcix.preference_number       =
                        (
                          SELECT MIN(cix.preference_number)
                          FROM   mtl_customer_items      cit
                                ,mtl_customer_item_xrefs cix
                          WHERE  cit.customer_id      = gt_chain_cust_acct_id
                          AND    cit.inactive_flag    = cv_n
                          AND    cit.customer_item_id = cix.customer_item_id
                          AND    cix.inactive_flag    = cv_n
                        )
/* 2009/09/28 Ver1.3 Add End   */
              )                        mcis   --�ڋq�i�ڏ��
             ,( SELECT  msib.inventory_item_id       inventory_item_id
                       ,msib.organization_id         organization_id
                       ,msib.segment1                item_code
                       ,xsib.bowl_inc_num            bowl_inc_num
                       ,msib.primary_unit_of_measure unit_of_measure
                FROM    mtl_system_items_b       msib  --Disc�i��
                       ,xxcmm_system_items_b     xsib  --Disc�i�ڃA�h�I��
                WHERE   msib.segment1        = xsib.item_code(+)
                AND     msib.organization_id = gn_orga_id  --�݌ɑg�DID(A-1�Ŏ擾)
              )                        sib    --Disc�i�ڏ��
             ,( SELECT  iimb.item_no            item_no
                       ,ximb.item_name          item_name
                       ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )   item_phonetic1
                       ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )  item_phonetic2
                       ,iimb.attribute11        case_inc_num
                       ,iimb.attribute21        jan_code
                       ,iimb.attribute22        itf_code
                FROM    ic_item_mst_b     iimb   --OPM�i��
                       ,xxcmn_item_mst_b  ximb   --OPM�i�ڃA�h�I��
                WHERE   iimb.item_id = ximb.item_id(+)
                AND     cd_process_date
                            BETWEEN NVL( ximb.start_date_active(+), cd_process_date )
                            AND NVL( ximb.end_date_active(+), cd_process_date )  --O�i��A�K�p��FROM-TO
              )                        imb    --OPM�i�ڃ}�X�^���
             ,xxcos_head_prod_class_v  xhpc   --�{�Џ��i�敪�r���[
      WHERE   xesh.fix_flag           = cv_y                       --�m��σt���O(�m���)
      AND     xesh.edi_chain_code     = gt_param_rec.chain_code    --�`�F�[���X�R�[�h(�p�����[�^)
      AND     xesh.customer_code      = hca.account_number(+)      --����(����H     = �ڋq���)
      AND     xesh.header_id          = xesl.header_id             --����(����H     = ����L)
      AND     xesl.inventory_item_id  = sib.inventory_item_id      --����(����L     = D�i�ڏ��)
      AND     sib.organization_id     = gn_orga_id                 --�݌ɑg�DID(A-1�Ŏ擾)
      AND     sib.item_code           = imb.item_no                --����(D�i�ڏ�� = O�i�ڏ��)
      AND     sib.unit_of_measure     = mcis.unit_of_measure(+)    --����(D�i�ڏ�� = �ڋq�i�ڏ��)
      AND     sib.organization_id     = mcis.organization_id(+)    --����(D�i�ڏ�� = �ڋq�i�ڏ��)
      AND     sib.inventory_item_id   = mcis.inventory_item_id(+)  --����(D�i�ڏ�� = �ڋq�i�ڏ��)
      AND     xesl.inventory_item_id  = xhpc.inventory_item_id(+)  --����(����L     = �{�Џ��i)
      --�ȉ��p�����[�^�C�ӂ̍���
      AND     (
                ( gt_param_rec.store_code IS NULL )
                OR
                ( xesh.shop_code        = gt_param_rec.store_code )
              )                                                                 --�X�R�[�h
      AND     xesh.to_subinventory_code = NVL( gt_param_rec.to_subinv_code, xesh.to_subinventory_code )  --������ۊǏꏊ
      AND     (
                ( gt_param_rec.center_code IS NULL )
                OR
                ( xesh.center_code      = gt_param_rec.center_code )
              )                                                                 --�Z���^�[�R�[�h
      AND     xesh.invoice_number       = NVL( gt_param_rec.invoice_number, xesh.invoice_number )        --�`�[�ԍ�
/* 2009/08/17 Ver1.2 Mod Start */
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                (  TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) <= xesh.schedule_shipping_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) >= xesh.schedule_shipping_date )
--              )                                                                 --�o�ח\���FROM-TO
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) <= xesh.schedule_arrival_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) >= xesh.schedule_arrival_date )
--              )                                                                 --���ɗ\���FROM-TO
      AND     (
                ( gt_param_rec.sch_ship_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_ship_date_from <= xesh.schedule_shipping_date )
              )
      AND     (
                ( gt_param_rec.sch_ship_date_to IS NULL )
                OR
                ( gt_param_rec.sch_ship_date_to >= xesh.schedule_shipping_date )
              )                                                                 --�o�ח\���FROM-TO
      AND     (
                ( gt_param_rec.sch_arrv_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_arrv_date_from <= xesh.schedule_arrival_date )
              )
      AND     (
                ( gt_param_rec.sch_arrv_date_to IS NULL )
                OR
                ( gt_param_rec.sch_arrv_date_to >= xesh.schedule_arrival_date )
              )                                                                 --���ɗ\���FROM-TO
/* 2009/08/17 Ver1.2 Mod Start */
      AND     (
                ( gt_param_rec.move_order_number IS NULL )
                OR
                ( xesh.move_order_num   = gt_param_rec.move_order_number )
              )                                                                 --�ړ��I�[�_�ԍ�
      AND     (
                ( gt_param_rec.edi_send_flag IS NULL )
                OR
                ( xesh.edi_send_flag    = gt_param_rec.edi_send_flag )
              )                                                                 --EDI���M�󋵃t���O
      ORDER BY
/* 2010/03/17 Ver1.4 Mod Start */
-- �w�b�_ID -> �`�[�ԍ�, �i�ڃR�[�h�ɏC��
--              xesh.header_id  --�`�[�ԍ����ɏ����������
              xesh.invoice_number
             ,sib.item_code
/* 2010/03/17 Ver1.4 Mod End   */
      ;
    --EDI�A�g�i�ڃR�[�h�uJAN�R�[�h�v
    CURSOR jan_item_cur
    IS
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xesh.header_id                          header_id                    --�w�b�_ID
      SELECT  /*+
                USE_NL(xesl)
              */
              xesh.header_id                          header_id                    --�w�b�_ID
/* 2009/08/18 Ver1.2 Mod End   */
             ,xesh.move_order_header_id               move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
             ,xesh.move_order_num                     move_order_num               --�ړ��I�[�_�[�ԍ�
             ,xesh.to_subinventory_code               to_subinventory_code         --������ۊǏꏊ
             ,xesh.customer_code                      customer_code                --�ڋq�R�[�h
             ,CASE
                WHEN hca.party_name IS NULL THEN       --�ڋq���Ȃ�
                  gv_cust_mst_err_msg
                ELSE
                  hca.party_name
              END                                     customer_name                --�ڋq����
             ,hca.organization_name_phonetic          customer_phonetic            --�ڋq���J�i
             ,xesh.shop_code                          shop_code                    --�X�R�[�h
             ,CASE
                WHEN hca.account_number IS NULL THEN   --�ڋq�Ȃ�
                  gv_cust_mst_err_msg
                ELSE
                  hca.cust_store_name
              END                                     shop_name                    --�X��
             ,xesh.center_code                        center_code                  --�Z���^�[�R�[�h
             ,xesh.invoice_number                     invoice_number               --�`�[�ԍ�
             ,xesh.other_party_department_code        other_party_department_code  --����敔��R�[�h
             ,xesh.schedule_shipping_date             schedule_shipping_date       --�o�ח\���
             ,xesh.schedule_arrival_date              schedule_arrival_date        --���ɗ\���
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --����\��
             ,xesh.inspect_schedule_date              inspect_schedule_date        --���i�\���
             ,xesh.invoice_class                      invoice_class                --�`�[�敪
             ,xesh.classification_class               classification_class         --���ދ敪
             ,xesh.whse_class                         whse_class                   --�q�ɋ敪
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --��ԓ����敪
             ,xesh.opportunity_code                   opportunity_code             --�փR�[�h
             ,TO_NUMBER(NULL)                         line_no                      --�sNo
             ,xesl.inventory_item_id                  inventory_item_id            --�i��ID
             ,xesh.organization_id                    organization_id              --�g�DID
             ,sib.item_code                           item_code                    --�i�ڃR�[�h
             ,CASE
                WHEN imb.item_name IS NULL THEN  --�i���Ȃ�
                  gv_item_mst_err_msg
                ELSE
                  imb.item_name
              END                                     item_name                    --�i�ږ�����
             ,imb.item_phonetic1                      item_phonetic1               --�i�ږ��J�i�P
             ,imb.item_phonetic2                      item_phonetic2               --�i�ږ��J�i�Q
             ,imb.case_inc_num                        case_inc_num                 --�P�[�X����
             ,sib.bowl_inc_num                        bowl_inc_num                 --�{�[������
             ,imb.jan_code                            jan_code                     --JAN�R�[�h
             ,imb.itf_code                            itf_code                     --ITF�R�[�h
             ,xhpc.item_div_h_code                    item_div_code                --�{�Џ��i�敪
             ,imb.jan_code                            customer_item_number         --�ڋq�i��(JAN�R�[�h)
             ,xesl.case_qty_sum                       case_qty                     --�P�[�X��
             ,xesl.indv_qty_sum                       indv_qty                     --�o����
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( imb.case_inc_num, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --�o�א���(���v�A�o��)
      FROM    xxcos_edi_stc_headers   xesh    --���ɗ\��w�b�_
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --�ڋq�X�e�[�^�X(���~���ٍψȊO)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --�X�e�[�^�X(�L��)
              )                       hca     --�ڋq
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
/* 2010/03/17 Ver1.4 Mod Start */
-- �w�b�_ID, �i�ڃR�[�h�̃T�}���̍폜
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
/* 2010/03/17 Ver1.4 Mod End   */
                FROM    xxcos_edi_stc_lines   xesl
/* 2009/08/18 Ver1.2 Add Start */
                       ,xxcos_edi_stc_headers xesh2
                WHERE   xesh2.edi_chain_code = gt_param_rec.chain_code
                AND     xesh2.fix_flag       = cv_y
                AND     xesh2.header_id      = xesl.header_id
/* 2009/08/18 Ver1.2 Add End   */
/* 2010/03/17 Ver1.4 Del Start */
-- �w�b�_ID, �i�ڃR�[�h�̃T�}���̍폜
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
/* 2010/03/17 Ver1.4 Del End   */
              )                        xesl   --���ɗ\�薾��(�i�ڃT�}��)
             ,( SELECT  msib.inventory_item_id  inventory_item_id
                       ,msib.organization_id    organization_id
                       ,msib.segment1           item_code
                       ,xsib.bowl_inc_num       bowl_inc_num
                FROM    mtl_system_items_b       msib  --Disc�i��
                       ,xxcmm_system_items_b     xsib  --Disc�i�ڃA�h�I��
                WHERE   msib.segment1        = xsib.item_code(+)
                AND     msib.organization_id = gn_orga_id  --�݌ɑg�DID(A-1�Ŏ擾)
              )                        sib     --Disc�i�ڏ��
             ,( SELECT  iimb.item_no            item_no
                       ,ximb.item_name          item_name
                       ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )   item_phonetic1
                       ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )  item_phonetic2
                       ,iimb.attribute11        case_inc_num
                       ,iimb.attribute21        jan_code
                       ,iimb.attribute22        itf_code
                FROM    ic_item_mst_b     iimb   --OPM�i��
                       ,xxcmn_item_mst_b  ximb   --OPM�i�ڃA�h�I��
                WHERE   iimb.item_id = ximb.item_id(+)
                AND     cd_process_date
                            BETWEEN NVL( ximb.start_date_active(+), cd_process_date )
                            AND NVL( ximb.end_date_active(+), cd_process_date )  --O�i��A�K�p��FROM-TO
              )                        imb    --OPM�i�ڃ}�X�^���
             ,xxcos_head_prod_class_v  xhpc   --�{�Џ��i�敪�r���[
      WHERE   xesh.fix_flag           = cv_y                       --�m��σt���O(�m���)
      AND     xesh.edi_chain_code     = gt_param_rec.chain_code    --�`�F�[���X�R�[�h(�p�����[�^)
      AND     xesh.customer_code      = hca.account_number(+)      --����(����H     = �ڋq)
      AND     xesh.header_id          = xesl.header_id             --����(����H     = ����L)
      AND     xesl.inventory_item_id  = sib.inventory_item_id      --����(����L     = D�i��)
      AND     sib.organization_id     = gn_orga_id                 --�݌ɑg�DID(A-1�Ŏ擾)
      AND     sib.item_code           = imb.item_no                --����(D�i�ڏ�� = O�i�ڏ��)
      AND     sib.inventory_item_id   = xhpc.inventory_item_id(+)  --����(D�i��     = �{�Џ��i�敪)
      --�ȉ��p�����[�^�C�ӂ̍���
      AND     (
                ( gt_param_rec.store_code IS NULL )
                OR
                ( xesh.shop_code        = gt_param_rec.store_code )
              )                                                                 --�X�R�[�h
      AND     xesh.to_subinventory_code = NVL( gt_param_rec.to_subinv_code, xesh.to_subinventory_code )  --������ۊǏꏊ
      AND     (
                ( gt_param_rec.center_code IS NULL )
                OR
                ( xesh.center_code      = gt_param_rec.center_code )
              )                                                                 --�Z���^�[�R�[�h
      AND     xesh.invoice_number       = NVL( gt_param_rec.invoice_number, xesh.invoice_number )        --�`�[�ԍ�
/* 2009/08/17 Ver1.2 Mod Start */
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                (  TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) <= xesh.schedule_shipping_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) >= xesh.schedule_shipping_date )
--              )                                                                 --�o�ח\���FROM-TO
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) <= xesh.schedule_arrival_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) >= xesh.schedule_arrival_date )
--              )                                                                 --���ɗ\���FROM-TO
      AND     (
                ( gt_param_rec.sch_ship_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_ship_date_from <= xesh.schedule_shipping_date )
              )
      AND     (
                ( gt_param_rec.sch_ship_date_to IS NULL )
                OR
                ( gt_param_rec.sch_ship_date_to >= xesh.schedule_shipping_date )
              )                                                                 --�o�ח\���FROM-TO
      AND     (
                ( gt_param_rec.sch_arrv_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_arrv_date_from <= xesh.schedule_arrival_date )
              )
      AND     (
                ( gt_param_rec.sch_arrv_date_to IS NULL )
                OR
                ( gt_param_rec.sch_arrv_date_to >= xesh.schedule_arrival_date )
              )
/* 2009/08/17 Ver1.2 Mod End   */
      AND     (
                ( gt_param_rec.move_order_number IS NULL )
                OR
                ( xesh.move_order_num   = gt_param_rec.move_order_number )
              )                                                                 --�ړ��I�[�_�ԍ�
      AND     (
                ( gt_param_rec.edi_send_flag IS NULL )
                OR
                ( xesh.edi_send_flag    = gt_param_rec.edi_send_flag )
              )                                                                 --EDI���M�󋵃t���O
      ORDER BY
/* 2010/03/17 Ver1.4 Mod Start */
-- �w�b�_ID -> �`�[�ԍ�, �i�ڃR�[�h�ɏC��
--              xesh.header_id  --�`�[�ԍ����ɏ����������
              xesh.invoice_number
             ,sib.item_code
/* 2010/03/17 Ver1.4 Mod End   */
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
--
    --==============================================================
    --�}�X�^���ڂ̎擾
    --==============================================================
    --�[�i���_���
    BEGIN
      SELECT  hca.account_number             delivery_base_code         --�[�i���_�R�[�h
             ,hp.party_name                  delivery_base_name         --�[�i���_��
             ,hp.organization_name_phonetic  delivery_base_phonetic     --�[�i���_���J�i
             ,hl.address_lines_phonetic      delivery_base_l_phonetic1  --�[�i���_�d�b�ԍ�
      INTO    gt_header_data.delivery_base_code
             ,gt_header_data.delivery_base_name
             ,gt_header_data.delivery_base_phonetic
             ,gt_header_data.delivery_base_l_phonetic
      FROM    hz_cust_accounts        hca   --���_(�ڋq)
             ,hz_parties              hp    --���_(�p�[�e�B)
             ,hz_cust_acct_sites_all  hcas  --�ڋq���ݒn
             ,hz_party_sites          hps   --�p�[�e�B�T�C�g
             ,hz_locations            hl    --�ڋq���ݒn(�A�J�E���g�T�C�g)
      WHERE   hps.location_id          = hl.location_id
      AND     hcas.org_id              = gt_prf_rec.org_id  --�c�ƒP��(A-1�Ŏ擾)
      AND     hcas.party_site_id       = hps.party_site_id
      AND     hca.cust_account_id      = hcas.cust_account_id
      AND     hca.party_id             = hp.party_id
      AND     hca.account_number       = 
                ( SELECT  xca1.delivery_base_code
                  FROM    hz_cust_accounts     hca1  --�ڋq
                         ,hz_parties           hp1   --�p�[�e�B
                         ,xxcmm_cust_accounts  xca1  --�ڋq�ǉ����
                  WHERE   hp1.duns_number_c        <> cv_cust_status     --�ڋq�X�e�[�^�X(���~���ٍψȊO)
                  AND     hca1.party_id            =  hp1.party_id
                  AND     hca1.status              =  cv_status_a        --�X�e�[�^�X(�ڋq�L��)
                  AND     hca1.customer_class_code =  cv_cust_code_cust  --�ڋq�敪(�ڋq)
                  AND     hca1.cust_account_id     =  xca1.customer_id
                  AND     xca1.chain_store_code    =  gt_param_rec.chain_code  --�`�F�[���X�R�[�h
                  AND     rownum                   =  cn_1
                )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�ڋq�}�X�^�Ȃ����b�Z�[�W��[�i���_���ɐݒ�
        gt_header_data.delivery_base_name := gv_cust_mst_err_msg;
    END;
    --EDI�`�F�[���X���
    BEGIN
      SELECT  xca.edi_item_code_div          edi_item_code_div   --EDI�A�g�i�ڃR�[�h
             ,hca.cust_account_id            cust_account_id     --�ڋqID(�`�F�[���X)
             ,hp.party_name                  edi_chain_name      --EDI�`�F�[���X��
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDI�`�F�[���X���J�i
      INTO    gt_edi_item_code_div
             ,gt_chain_cust_acct_id
             ,gt_header_data.edi_chain_name
             ,gt_header_data.edi_chain_name_phonetic
      FROM    hz_cust_accounts    hca  --�ڋq
             ,hz_parties          hp   --�p�[�e�B
             ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
      WHERE   hca.customer_class_code =  cv_cust_code_chain       --�ڋq�敪(�`�F�[���X)
      AND     hca.party_id            =  hp.party_id
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  gt_param_rec.chain_code  --�`�F�[���X�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_edi_item_code_div := NULL;
    END;
    --�擾�ł��Ȃ��ANULL�A�擾�����敪��JAN���A�ڋq�ȊO�̏ꍇ�G���[
    IF ( gt_edi_item_code_div IS NULL )
      OR ( gt_edi_item_code_div NOT IN ( cv_1, cv_2 ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_edi_i_inf_err     --EDI�A�g�i�ڃR�[�h�敪�G���[
                    ,iv_token_name1  => cv_tkn_chain_s
                    ,iv_token_value1 => gt_param_rec.chain_code  --�`�F�[���X�R�[�h
                   );
      lv_errbuf := lv_errmsg; --���O���b�Z�[�W�ҏW
      RAISE global_api_expt;
    END IF;
    -- �ŗ�
    BEGIN
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xtrv.tax_rate             --�ŗ�
      SELECT  /*+
                LEADING(xca)
              */
              xtrv.tax_rate             --�ŗ�
/* 2009/08/18 Ver1.2 Mod End   */
      INTO    gt_tax_rate
      FROM    hz_cust_accounts    hca   --�ڋq
             ,hz_parties          hp    --�p�[�e�B
             ,xxcmm_cust_accounts xca   --�ڋq�ǉ����
             ,xxcos_tax_rate_v    xtrv  --����ŗ��r���[
      WHERE   xtrv.set_of_books_id    =  gt_prf_rec.set_of_books_id  --��v����ID
      AND     (
                ( xtrv.start_date_active IS NULL )
                OR
                ( xtrv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xtrv.end_date_active IS NULL )
                OR
                ( xtrv.end_date_active >= cd_process_date )
              )                                              --�Ɩ����t��FROM-TO��
      AND     xtrv.tax_start_date <= cd_process_date         --�ŊJ�n�����Ɩ��J�n���ȑO
      AND     (
                ( xtrv.tax_end_date IS NULL )
                OR
                ( xtrv.tax_end_date >= cd_process_date )
              )                                              --�ŏI������NULL�������͋Ɩ��J�n���ȍ~
      AND     xtrv.account_number     =  hca.account_number
      AND     hp.duns_number_c        <> cv_cust_status      --�ڋq�X�e�[�^�X(���~���ٍψȊO)
      AND     hca.party_id            =  hp.party_id
      AND     hca.status              =  cv_status_a         --�X�e�[�^�X(�L��)
      AND     hca.customer_class_code =  cv_cust_code_cust   --�ڋq�敪(�ڋq)
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  gt_param_rec.chain_code  --EDI�`�F�[���X
      AND     rownum                  =  cn_1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tax_err            --�ŗ��擾�G���[
                      ,iv_token_name1  => cv_tkn_chain_s
                      ,iv_token_value1 => gt_param_rec.chain_code   --�p�����[�^��
                     );
        lv_errbuf := lv_errmsg; --���O���b�Z�[�W�ҏW
        RAISE global_api_expt;
    END;
    --==============================================================
    --���ɗ\��f�[�^���o
    --==============================================================
    --�ڋq�i�ڂ̏ꍇ
    IF ( gt_edi_item_code_div = cv_1 ) THEN
       OPEN cust_item_cur;
       FETCH cust_item_cur BULK COLLECT INTO gt_edi_stc_date;
       --�Ώی����擾
       gn_target_cnt := cust_item_cur%ROWCOUNT;
       CLOSE cust_item_cur;
    --JAN�R�[�h�̏ꍇ
    ELSIF ( gt_edi_item_code_div = cv_2 ) THEN
      OPEN jan_item_cur;
      FETCH jan_item_cur BULK COLLECT INTO gt_edi_stc_date;
      --�Ώی����擾
      gn_target_cnt := jan_item_cur%ROWCOUNT;
      CLOSE jan_item_cur;
    END IF;
    --==============================================================
    --�sNO�̕ҏW�A�`�[�v�̎Z�o
    --==============================================================
    <<sum_qty_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
/* 2009/07/01 Ver1.10 Add Start */
      -- �o�א��ʂ��擾����B
      xxcos_common2_pkg.convert_quantity(
        iv_uom_code           => cv_uom_code_dummy                --(IN)��P��
       ,in_case_qty           => gt_edi_stc_date(i).case_inc_num  --(IN)�P�[�X����
       ,in_ball_qty           => gt_edi_stc_date(i).bowl_inc_num  --(IN)�{�[������
       ,in_sum_indv_order_qty => gt_edi_stc_date(i).ship_qty      --(IN)��������(���v�E�o��)
       ,in_sum_shipping_qty   => gt_edi_stc_date(i).ship_qty      --(IN)�o�א���(���v�E�o��)
       ,on_indv_shipping_qty  => ln_indv_shipping_qty             --(OUT)�o�א���(�o��)
       ,on_case_shipping_qty  => ln_case_shipping_qty             --(OUT)�o�א���(�P�[�X)
       ,on_ball_shipping_qty  => ln_ball_shipping_qty             --(OUT)�o�א���(�{�[��)
       ,on_indv_stockout_qty  => ln_indv_stockout_qty             --(OUT)���i����(�o��)
       ,on_case_stockout_qty  => ln_case_stockout_qty             --(OUT)���i����(�P�[�X)
       ,on_ball_stockout_qty  => ln_ball_stockout_qty             --(OUT)���i����(�{�[��)
       ,on_sum_stockout_qty   => ln_sum_stockout_qty              --(OUT)���i����(�o������v)
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
--
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
/* 2009/07/01 Ver1.10 Add End   */
      --���[�v����A�������̓u���C�N�̏ꍇ
      IF ( lt_invc_break IS NULL )
        OR ( lt_invc_break <> gt_edi_stc_date(i).header_id )
      THEN
        --������
        lt_invc_break :=  gt_edi_stc_date(i).header_id;   --�u���[�N�ϐ�
        ln_line_no    :=  cn_1;                           --�sNo
/* 2009/07/01 Ver1.10 Mod Start */
--        gt_sum_qty(lt_invc_break).invc_case_qty_sum := gt_edi_stc_date(i).case_qty;  --�P�[�X��
--        gt_sum_qty(lt_invc_break).invc_indv_qty_sum := gt_edi_stc_date(i).indv_qty;  --�o����
        gt_sum_qty(lt_invc_break).invc_case_qty_sum := ln_case_shipping_qty;         --�P�[�X��
        gt_sum_qty(lt_invc_break).invc_indv_qty_sum := ln_indv_shipping_qty;         --�o����
/* 2009/07/01 Ver1.10 Mod End   */
        gt_sum_qty(lt_invc_break).invc_ship_qty_sum := gt_edi_stc_date(i).ship_qty;  --�o�א���(���v�A�o��)
      ELSE
        --���Z
        ln_line_no := ln_line_no + cn_1;  --�sNo
/* 2009/07/01 Ver1.10 Mod Start */
        gt_sum_qty(lt_invc_break).invc_case_qty_sum
--          := gt_sum_qty(lt_invc_break).invc_case_qty_sum + gt_edi_stc_date(i).case_qty;  --�P�[�X��
          := gt_sum_qty(lt_invc_break).invc_case_qty_sum + ln_case_shipping_qty;  --�P�[�X��
        gt_sum_qty(lt_invc_break).invc_indv_qty_sum
--          := gt_sum_qty(lt_invc_break).invc_indv_qty_sum + gt_edi_stc_date(i).indv_qty;  --�o����
          := gt_sum_qty(lt_invc_break).invc_indv_qty_sum + ln_indv_shipping_qty;  --�o����
/* 2009/07/01 Ver1.10 Mod End   */
        gt_sum_qty(lt_invc_break).invc_ship_qty_sum
          := gt_sum_qty(lt_invc_break).invc_ship_qty_sum + gt_edi_stc_date(i).ship_qty;  --�o�א���(���v�A�o��)
      END IF;
      --�sNo�̐ݒ�
      gt_edi_stc_date(i).line_no := ln_line_no;
    END LOOP sum_qty_loop;
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
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      :  CSV�w�b�_���R�[�h�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ---------------------------
    --CSV�w�b�_���R�[�h�o��
    ---------------------------
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => gv_csv_header     --CSV�w�b�_
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
  END proc_out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_data_record
   * Description      : �f�[�^���R�[�h�쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_out_data_record(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    lv_data_record  VARCHAR2(32767);         --�ҏW��̃f�[�^�擾�p
/* 2009/07/01 Ver1.10 Add Start */
    ln_indv_shipping_qty  NUMBER;            --�o�א���(�o��)
    ln_case_shipping_qty  NUMBER;            --�o�א���(�P�[�X)
    ln_ball_shipping_qty  NUMBER;            --�o�א���(�{�[��)
    ln_indv_stockout_qty  NUMBER;            --���i����(�o��)
    ln_case_stockout_qty  NUMBER;            --���i����(�P�[�X)
    ln_ball_stockout_qty  NUMBER;            --���i����(�{�[��)
    ln_sum_stockout_qty   NUMBER;            --���i����(���v�A�o��)
/* 2009/07/01 Ver1.10 Add End   */
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;  --�o�̓f�[�^���
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
    --�f�[�^�쐬���[�v
    --==============================================================
    <<output_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
/* 2009/07/01 Ver1.10 Add Start */
      --------------------------------
      --�o�א��ʂ̎擾
      --------------------------------
      xxcos_common2_pkg.convert_quantity(
        iv_uom_code           => cv_uom_code_dummy                --(IN)��P��
       ,in_case_qty           => gt_edi_stc_date(i).case_inc_num  --(IN)�P�[�X����
       ,in_ball_qty           => gt_edi_stc_date(i).bowl_inc_num  --(IN)�{�[������
       ,in_sum_indv_order_qty => gt_edi_stc_date(i).ship_qty      --(IN)��������(���v�E�o��)
       ,in_sum_shipping_qty   => gt_edi_stc_date(i).ship_qty      --(IN)�o�א���(���v�E�o��)
       ,on_indv_shipping_qty  => ln_indv_shipping_qty             --(OUT)�o�א���(�o��)
       ,on_case_shipping_qty  => ln_case_shipping_qty             --(OUT)�o�א���(�P�[�X)
       ,on_ball_shipping_qty  => ln_ball_shipping_qty             --(OUT)�o�א���(�{�[��)
       ,on_indv_stockout_qty  => ln_indv_stockout_qty             --(OUT)���i����(�o��)
       ,on_case_stockout_qty  => ln_case_stockout_qty             --(OUT)���i����(�P�[�X)
       ,on_ball_stockout_qty  => ln_ball_stockout_qty             --(OUT)���i����(�{�[��)
       ,on_sum_stockout_qty   => ln_sum_stockout_qty              --(OUT)���i����(�o������v)
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
--
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
/* 2009/07/01 Ver1.10 Add End   */
      --------------------------------
      --���ʊ֐��p�̕ϐ��ɒl��ݒ�
      --------------------------------
      -- �w�b�_�� --
      l_data_tab(cv_medium_class)             := cv_media_class;
      l_data_tab(cv_data_type_code)           := gt_param_rec.data_type_code;
      l_data_tab(cv_file_no)                  := cv_file_num;
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;
      l_data_tab(cv_process_time)             := gv_f_o_time;
      l_data_tab(cv_base_code)                := gt_header_data.delivery_base_code;
      l_data_tab(cv_base_name)                := gt_header_data.delivery_base_name;
      l_data_tab(cv_base_name_alt)            := gt_header_data.delivery_base_phonetic;
      l_data_tab(cv_edi_chain_code)           := gt_param_rec.chain_code;
      l_data_tab(cv_edi_chain_name)           := gt_header_data.edi_chain_name;
      l_data_tab(cv_edi_chain_name_alt)       := gt_header_data.edi_chain_name_phonetic;
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := gt_param_rec.report_code;
      l_data_tab(cv_report_show_name)         := gt_param_rec.report_name;
      l_data_tab(cv_cust_code)                := gt_edi_stc_date(i).customer_code;
      l_data_tab(cv_cust_name)                := gt_edi_stc_date(i).customer_name;
      l_data_tab(cv_cust_name_alt)            := gt_edi_stc_date(i).customer_phonetic;
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      --�ړ��I�[�_�[�̏ꍇ
      IF ( gt_edi_stc_date(i).move_order_num IS NOT NULL ) THEN
        l_data_tab(cv_shop_code)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name_alt)          := TO_CHAR(NULL);
      --��ʓ��͂̏ꍇ
      ELSE
        l_data_tab(cv_shop_code)              := gt_edi_stc_date(i).shop_code;
        l_data_tab(cv_shop_name)              := gt_edi_stc_date(i).shop_name;
        l_data_tab(cv_shop_name_alt)          := gt_edi_stc_date(i).customer_phonetic;
      END IF;
      l_data_tab(cv_delv_cent_code)           := gt_edi_stc_date(i).center_code;
      l_data_tab(cv_delv_cent_name)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name_alt)       := TO_CHAR(NULL);
      l_data_tab(cv_order_date)               := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_date)           := TO_CHAR(gt_edi_stc_date(i).schedule_arrival_date, cv_date_format);
      l_data_tab(cv_result_delv_date)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_delv_date)           := TO_CHAR(NULL);
      l_data_tab(cv_dc_date_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_dc_time_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_invc_class)               := gt_edi_stc_date(i).invoice_class;
      l_data_tab(cv_small_classif_code)       := TO_CHAR(NULL);
      l_data_tab(cv_small_classif_name)       := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_code)      := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_name)      := TO_CHAR(NULL);
      l_data_tab(cv_big_classif_code)         := gt_edi_stc_date(i).classification_class;
      l_data_tab(cv_big_classif_name)         := TO_CHAR(NULL);
      l_data_tab(cv_op_department_code)       := gt_edi_stc_date(i).other_party_department_code;
      l_data_tab(cv_op_order_number)          := TO_CHAR(NULL);
      l_data_tab(cv_check_digit_class)        := TO_CHAR(NULL);
      l_data_tab(cv_invc_number)              := gt_edi_stc_date(i).invoice_number;
      l_data_tab(cv_check_digit)              := TO_CHAR(NULL);
      l_data_tab(cv_close_date)               := TO_CHAR(NULL);
      l_data_tab(cv_order_no_ebs)             := gt_edi_stc_date(i).move_order_num;
      l_data_tab(cv_ar_sale_class)            := gt_edi_stc_date(i).regular_ar_sale_class;
      l_data_tab(cv_delv_classe)              := TO_CHAR(NULL);
      l_data_tab(cv_opportunity_no)           := gt_edi_stc_date(i).opportunity_code;
      l_data_tab(cv_contact_to)               := gt_header_data.delivery_base_l_phonetic;
      l_data_tab(cv_route_sales)              := TO_CHAR(NULL);
      l_data_tab(cv_corporate_code)           := TO_CHAR(NULL);
      l_data_tab(cv_maker_name)               := TO_CHAR(NULL);
      l_data_tab(cv_area_code)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_code)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name1_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name2_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_tel)               := TO_CHAR(NULL);
      l_data_tab(cv_vendor_charge)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_address)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_itouen)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_chain)       := TO_CHAR(NULL);
      l_data_tab(cv_delv_to)                  := TO_CHAR(NULL);
      l_data_tab(cv_delv_to1_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to2_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address)          := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_code)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_comp_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_shop_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address)          := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_order_possible_date)      := TO_CHAR(NULL);
      l_data_tab(cv_perm_possible_date)       := TO_CHAR(NULL);
      l_data_tab(cv_forward_month)            := TO_CHAR(NULL);
      l_data_tab(cv_payment_settlement_date)  := TO_CHAR(NULL);
      l_data_tab(cv_handbill_start_date_act)  := TO_CHAR(NULL);
      l_data_tab(cv_billing_due_date)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_time)                := TO_CHAR(NULL);
      l_data_tab(cv_delv_schedule_time)       := TO_CHAR(NULL);
      l_data_tab(cv_order_time)               := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item1)           := TO_CHAR(gt_edi_stc_date(i).schedule_shipping_date, cv_date_format);
      l_data_tab(cv_gen_date_item2)           := TO_CHAR(gt_edi_stc_date(i).rcpt_possible_date, cv_date_format);
      l_data_tab(cv_gen_date_item3)           := TO_CHAR(gt_edi_stc_date(i).inspect_schedule_date, cv_date_format);
      l_data_tab(cv_gen_date_item4)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item5)           := TO_CHAR(NULL);
      l_data_tab(cv_arrival_ship_class)       := TO_CHAR(NULL);
      l_data_tab(cv_vendor_class)             := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed_class)      := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_use_class)     := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_code)      := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_name)      := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_method)         := TO_CHAR(NULL);
      l_data_tab(cv_cent_use_class)           := TO_CHAR(NULL);
      l_data_tab(cv_cent_whse_class)          := gt_edi_stc_date(i).whse_class;
      l_data_tab(cv_cent_area_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_arrival_class)       := TO_CHAR(NULL);
      l_data_tab(cv_depot_class)              := TO_CHAR(NULL);
      l_data_tab(cv_tcdc_class)               := TO_CHAR(NULL);
      l_data_tab(cv_upc_flag)                 := TO_CHAR(NULL);
      l_data_tab(cv_simultaneously_class)     := TO_CHAR(NULL);
      l_data_tab(cv_business_id)              := TO_CHAR(NULL);
      l_data_tab(cv_whse_directly_class)      := TO_CHAR(NULL);
      l_data_tab(cv_premium_rebate_class)     := TO_CHAR(NULL);
      l_data_tab(cv_item_type)                := TO_CHAR(NULL);
      l_data_tab(cv_cloth_house_food_class)   := TO_CHAR(NULL);
      l_data_tab(cv_mix_class)                := TO_CHAR(NULL);
      l_data_tab(cv_stk_class)                := TO_CHAR(NULL);
      l_data_tab(cv_last_modify_site_class)   := TO_CHAR(NULL);
      l_data_tab(cv_report_class)             := TO_CHAR(NULL);
      l_data_tab(cv_addition_plan_class)      := TO_CHAR(NULL);
      l_data_tab(cv_registration_class)       := TO_CHAR(NULL);
      l_data_tab(cv_specific_class)           := TO_CHAR(NULL);
      l_data_tab(cv_dealings_class)           := TO_CHAR(NULL);
      l_data_tab(cv_order_class)              := TO_CHAR(NULL);
      l_data_tab(cv_sum_line_class)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_guidance_class)      := TO_CHAR(NULL);
      l_data_tab(cv_ship_class)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_use_class)      := TO_CHAR(NULL);
      l_data_tab(cv_cargo_item_class)         := TO_CHAR(NULL);
      l_data_tab(cv_ta_class)                 := TO_CHAR(NULL);
      l_data_tab(cv_plan_code)                := TO_CHAR(NULL);
      l_data_tab(cv_category_code)            := TO_CHAR(NULL);
      l_data_tab(cv_category_class)           := TO_CHAR(NULL);
      l_data_tab(cv_carrier_means)            := TO_CHAR(NULL);
      l_data_tab(cv_counter_code)             := TO_CHAR(NULL);
      l_data_tab(cv_move_sign)                := TO_CHAR(NULL);
      l_data_tab(cv_eos_handwriting_class)    := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_section_code)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed)            := TO_CHAR(NULL);
      l_data_tab(cv_attach_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_op_floor)                 := TO_CHAR(NULL);
      l_data_tab(cv_text_no)                  := TO_CHAR(NULL);
      l_data_tab(cv_in_store_code)            := TO_CHAR(NULL);
      l_data_tab(cv_tag_data)                 := TO_CHAR(NULL);
      l_data_tab(cv_competition_code)         := TO_CHAR(NULL);
      l_data_tab(cv_billing_chair)            := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_code)         := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_short_name)   := TO_CHAR(NULL);
      l_data_tab(cv_direct_delv_rcpt_fee)     := TO_CHAR(NULL);
      l_data_tab(cv_bill_info)                := TO_CHAR(NULL);
      l_data_tab(cv_description)              := TO_CHAR(NULL);
      l_data_tab(cv_interior_code)            := TO_CHAR(NULL);
      l_data_tab(cv_order_info_delv_category) := TO_CHAR(NULL);
      l_data_tab(cv_purchase_type)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_opened_site)         := TO_CHAR(NULL);
      l_data_tab(cv_counter_name)             := TO_CHAR(NULL);
      l_data_tab(cv_extension_number)         := TO_CHAR(NULL);
      l_data_tab(cv_charge_name)              := TO_CHAR(NULL);
      l_data_tab(cv_price_tag)                := TO_CHAR(NULL);
      l_data_tab(cv_tax_type)                 := TO_CHAR(NULL);
      l_data_tab(cv_consumption_tax_class)    := TO_CHAR(NULL);
      l_data_tab(cv_brand_class)              := TO_CHAR(NULL);
      l_data_tab(cv_id_code)                  := TO_CHAR(NULL);
      l_data_tab(cv_department_code)          := TO_CHAR(NULL);
      l_data_tab(cv_department_name)          := TO_CHAR(NULL);
      l_data_tab(cv_item_type_number)         := TO_CHAR(NULL);
      l_data_tab(cv_description_department)   := TO_CHAR(NULL);
      l_data_tab(cv_price_tag_method)         := TO_CHAR(NULL);
      l_data_tab(cv_reason_column)            := TO_CHAR(NULL);
      l_data_tab(cv_a_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_d_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_brand_code)               := TO_CHAR(NULL);
      l_data_tab(cv_line_code)                := TO_CHAR(NULL);
      l_data_tab(cv_class_code)               := TO_CHAR(NULL);
      l_data_tab(cv_a1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_header)    := TO_CHAR(NULL);
      l_data_tab(cv_order_connection_number)  := TO_CHAR(NULL);
      --���ו� --
      l_data_tab(cv_line_no)                  := TO_CHAR( gt_edi_stc_date(i).line_no );
      l_data_tab(cv_stkout_class)             := TO_CHAR(NULL);
      l_data_tab(cv_stkout_reason)            := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_itouen)         := gt_edi_stc_date(i).item_code;
      l_data_tab(cv_prod_code1)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code2)               := gt_edi_stc_date(i).customer_item_number;
      l_data_tab(cv_jan_code)                 := gt_edi_stc_date(i).jan_code;
      l_data_tab(cv_itf_code)                 := gt_edi_stc_date(i).itf_code;
      l_data_tab(cv_extension_itf_code)       := TO_CHAR(NULL);
      l_data_tab(cv_case_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_item_type)      := TO_CHAR(NULL);
      l_data_tab(cv_prod_class)               := gt_edi_stc_date(i).item_div_code;
      l_data_tab(cv_prod_name)                := gt_edi_stc_date(i).item_name;
      l_data_tab(cv_prod_name1_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_name2_alt)           := gt_edi_stc_date(i).item_phonetic1;
      l_data_tab(cv_item_standard1)           := TO_CHAR(NULL);
      l_data_tab(cv_item_standard2)           := gt_edi_stc_date(i).item_phonetic2;
      l_data_tab(cv_qty_in_case)              := TO_CHAR(NULL);
      l_data_tab(cv_num_of_cases)             := gt_edi_stc_date(i).case_inc_num;
      l_data_tab(cv_num_of_ball)              := gt_edi_stc_date(i).bowl_inc_num;
      l_data_tab(cv_item_color)               := TO_CHAR(NULL);
      l_data_tab(cv_item_size)                := TO_CHAR(NULL);
      l_data_tab(cv_expiration_date)          := TO_CHAR(NULL);
      l_data_tab(cv_prod_date)                := TO_CHAR(NULL);
      l_data_tab(cv_order_uom_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_ship_uom_qty)             := TO_CHAR(NULL);
      l_data_tab(cv_packing_uom_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_deal_code)                := TO_CHAR(NULL);
      l_data_tab(cv_deal_class)               := TO_CHAR(NULL);
      l_data_tab(cv_collation_code)           := TO_CHAR(NULL);
      l_data_tab(cv_uom_code)                 := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_class)         := TO_CHAR(NULL);
      l_data_tab(cv_parent_packing_number)    := TO_CHAR(NULL);
      l_data_tab(cv_packing_number)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_group_code)          := TO_CHAR(NULL);
      l_data_tab(cv_case_dismantle_flag)      := TO_CHAR(NULL);
      l_data_tab(cv_case_class)               := TO_CHAR(NULL);
      l_data_tab(cv_indv_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_sum_order_qty)            := TO_CHAR(NULL);
/* 2009/07/01 Ver1.1 Mod Start */
--      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).indv_qty );
--      l_data_tab(cv_case_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).case_qty );
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( ln_indv_shipping_qty );
      l_data_tab(cv_case_ship_qty)            := TO_CHAR( ln_case_shipping_qty );
/* 2009/07/01 Ver1.1 Mod End   */
      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_pallet_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_ship_qty)             := TO_CHAR( gt_edi_stc_date(i).ship_qty );
      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_qty)                 := TO_CHAR(NULL);
      l_data_tab(cv_fold_container_indv_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_order_unit_price)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_unit_price)          := TO_CHAR(NULL);
      l_data_tab(cv_order_cost_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_cost_amt)            := TO_CHAR(NULL);
      l_data_tab(cv_stkout_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_selling_price)            := TO_CHAR(NULL);
      l_data_tab(cv_order_price_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_ship_price_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_stkout_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_a_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_d_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_depth)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_height)     := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_width)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_weight)     := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item1)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item2)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item1)            := TO_CHAR( gt_tax_rate );
      l_data_tab(cv_gen_add_item2)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, cn_1, cn_10 );
      l_data_tab(cv_gen_add_item3)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, cn_11, cn_10 );
      l_data_tab(cv_gen_add_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_line)      := TO_CHAR(NULL);
      --�t�b�^�� --
      l_data_tab(cv_invc_indv_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_order_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_indv_qty_sum );
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_case_qty_sum );
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_ship_qty_sum );
      l_data_tab(cv_invc_indv_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_stkout_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_invc_fold_container_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_cost_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_cost_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_cost_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_price_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_price_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_price_amt)    := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_order_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_case_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_pallet_ship_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_ship_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_case_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_stkout_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_fold_container_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_t_order_cost_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_cost_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_order_price_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_price_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_t_line_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_invc_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_footer)    := TO_CHAR(NULL);
      --==============================================================
      --�f�[�^���R�[�h���`
      --==============================================================
      xxcos_common2_pkg.makeup_data_record(
        iv_edit_data        => l_data_tab          --�o�̓f�[�^���
       ,iv_file_type        => cv_file_format      --�t�@�C���`��(�ϒ�)
       ,iv_data_type_table  => gt_data_type_table  --���C�A�E�g��`���
       ,iv_record_type      => gt_prf_rec.if_data  --�f�[�^���R�[�h���ʎq
       ,ov_data_record      => lv_data_record      --�f�[�^���R�[�h
       ,ov_errbuf           => lv_errbuf           --�G���[���b�Z�[�W
       ,ov_retcode          => lv_retcode          --���^�[���R�[�h
       ,ov_errmsg           => lv_errmsg           --���[�U�E�G���[���b�Z�[�W
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;  --���O���b�Z�[�W�̕ҏW
        RAISE global_api_expt;
      END IF;
      --==============================================================
      --�f�[�^���R�[�h�o��
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --�t�@�C���n���h��
       ,buffer => lv_data_record  --�f�[�^���R�[�h
      );
      --���폈�������J�E���g
      gn_normal_cnt := gn_normal_cnt + cn_1;
--
    END LOOP output_loop;
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
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : �t�b�^���R�[�h�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    lv_footer_output  VARCHAR2(32767); --�t�b�^�o�͗p
    lv_dummy1         VARCHAR2(1);     --IF���Ɩ��n��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy2         VARCHAR2(1);     --���_�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy3         VARCHAR2(1);     --���_����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy4         VARCHAR2(1);     --�`�F�[���X�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy5         VARCHAR2(1);     --�`�F�[���X����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy6         VARCHAR2(1);     --�f�[�^��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy7         VARCHAR2(1);     --���[�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy8         VARCHAR2(1);     --���[�\����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy9         VARCHAR2(1);     --���ڐ�(�t�b�^�ł͎g�p���Ȃ�)
    ln_rec_cnt        NUMBER;          --�t�b�^�����p
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
    --�t�b�^�����̃C���N�������g
    --==============================================================
    IF ( gn_target_cnt > cn_0 ) THEN
      ln_rec_cnt := gn_target_cnt + cn_1;  --�Ώی�����CSV�w�b�_�̕��𑫂��ăt�b�^�����ɂ���
    ELSE
      ln_rec_cnt := cn_0;
    END IF;
    --==============================================================
    --�t�b�^���R�[�h�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      iv_add_area        => gt_prf_rec.if_footer  --�t�^�敪
     ,iv_from_series     => lv_dummy1             --IF���Ɩ��n��R�[�h
     ,iv_base_code       => lv_dummy2             --���_�R�[�h
     ,iv_base_name       => lv_dummy3             --���_����
     ,iv_chain_code      => lv_dummy4             --�`�F�[���X�R�[�h
     ,iv_chain_name      => lv_dummy5             --�`�F�[���X����
     ,iv_data_kind       => lv_dummy6             --�f�[�^��R�[�h
     ,iv_chohyo_code     => lv_dummy7             --���[�R�[�h
     ,iv_chohyo_name     => lv_dummy8             --���[�\����
     ,in_num_of_item     => lv_dummy9             --���ڐ�
     ,in_num_of_records  => ln_rec_cnt            --���R�[�h����
     ,ov_retcode         => lv_retcode            --���^�[���R�[�h
     ,ov_output          => lv_footer_output      --�o�͒l
     ,ov_errbuf          => lv_errbuf             --�G���[���b�Z�[�W
     ,ov_errmsg          => lv_errmsg             --���[�U�E�G���[���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;  --���O���b�Z�[�W�̕ҏW
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�b�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_footer_output  --�o�͒l(�t�b�^)
    );
    --==============================================================
    --�t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(
      file => gt_f_handle
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
  END proc_out_footer_record;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name          IN  VARCHAR2,   --  1.�t�@�C����
    iv_chain_code         IN  VARCHAR2,   --  2.�`�F�[���X�R�[�h
    iv_report_code        IN  VARCHAR2,   --  3.���[�R�[�h
    iv_user_id            IN  VARCHAR2,   --  4.���[�UID
    iv_chain_name         IN  VARCHAR2,   --  5.�`�F�[���X��
    iv_store_code         IN  VARCHAR2,   --  6.�X�܃R�[�h
    iv_base_code          IN  VARCHAR2,   --  7.���_�R�[�h
    iv_base_name          IN  VARCHAR2,   --  8.���_��
    iv_data_type_code     IN  VARCHAR2,   --  9.���[��ʃR�[�h
    iv_oprtn_series_code  IN  VARCHAR2,   -- 10.�Ɩ��n��R�[�h
    iv_report_name        IN  VARCHAR2,   -- 11.���[�l��
    iv_to_subinv_code     IN  VARCHAR2,   -- 12.������ۊǏꏊ�R�[�h
    iv_center_code        IN  VARCHAR2,   -- 13.�Z���^�[�R�[�h
    iv_invoice_number     IN  VARCHAR2,   -- 14.�`�[�ԍ�
    iv_sch_ship_date_from IN  VARCHAR2,   -- 15.�o�ח\���FROM
    iv_sch_ship_date_to   IN  VARCHAR2,   -- 16.�o�ח\���TO
    iv_sch_arrv_date_from IN  VARCHAR2,   -- 17.���ɗ\���FROM
    iv_sch_arrv_date_to   IN  VARCHAR2,   -- 18.���ɗ\���TO
    iv_move_order_number  IN  VARCHAR2,   -- 19.�ړ��I�[�_�[�ԍ�
    iv_edi_send_flag      IN  VARCHAR2,   -- 20.EDI���M��
    ov_errbuf             OUT VARCHAR2,   --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2 )  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_no_target_msg      VARCHAR2(5000);  --�ΏۂȂ����b�Z�[�W�擾�p
    lv_worn_status        VARCHAR2(1);     --�ΏۂȂ��̌x���X�e�[�^�X�ێ��p
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
    -- ===============================================
    -- ���̓p�����[�^�̃Z�b�g
    -- ===============================================
    gt_param_rec.file_name           := iv_file_name;             --�t�@�C����
    gt_param_rec.chain_code          := iv_chain_code;            --�`�F�[���X�R�[�h
    gt_param_rec.report_code         := iv_report_code;           --���[�R�[�h
    gt_param_rec.user_id             := TO_NUMBER( iv_user_id );  --���[�UID
    gt_param_rec.chain_name          := iv_chain_name;            --�`�F�[���X��
    gt_param_rec.store_code          := iv_store_code;            --�X�܃R�[�h
    gt_param_rec.base_code           := iv_base_code;             --���_�R�[�h
    gt_param_rec.base_name           := iv_base_name;             --���_��
    gt_param_rec.data_type_code      := iv_data_type_code;        --���[��ʃR�[�h
    gt_param_rec.oprtn_series_code   := iv_oprtn_series_code;     --�Ɩ��n��R�[�h
    gt_param_rec.report_name         := iv_report_name;           --���[�l��
    gt_param_rec.to_subinv_code      := iv_to_subinv_code;        --������ۊǏꏊ�R�[�h
    gt_param_rec.center_code         := iv_center_code;           --�Z���^�[�R�[�h
    gt_param_rec.invoice_number      := iv_invoice_number;        --�`�[�ԍ�
/* 2009/08/17 Ver1.2 Mod Start */
--    gt_param_rec.sch_ship_date_from  := iv_sch_ship_date_from;    --�o�ח\���FROM
--    gt_param_rec.sch_ship_date_to    := iv_sch_ship_date_to;      --�o�ח\���TO
--    gt_param_rec.sch_arrv_date_from  := iv_sch_arrv_date_from;    --���ɗ\���FROM
--    gt_param_rec.sch_arrv_date_to    := iv_sch_arrv_date_to;      --���ɗ\���TO
    gt_param_rec.sch_ship_date_from  := TO_DATE( iv_sch_ship_date_from, cv_date_format10);  --�o�ח\���FROM
    gt_param_rec.sch_ship_date_to    := TO_DATE( iv_sch_ship_date_to, cv_date_format10);    --�o�ח\���TO
    gt_param_rec.sch_arrv_date_from  := TO_DATE( iv_sch_arrv_date_from, cv_date_format10);  --���ɗ\���FROM
    gt_param_rec.sch_arrv_date_to    := TO_DATE( iv_sch_arrv_date_to, cv_date_format10);    --���ɗ\���TO
/* 2009/08/17 Ver1.2 Mod End   */
    gt_param_rec.move_order_number   := iv_move_order_number;     --�ړ��I�[�_�[�ԍ�
    gt_param_rec.edi_send_flag       := iv_edi_send_flag;         --EDI���M��
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --��������
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�w�b�_���R�[�h�쐬����(A-2)
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --��������
    IF (lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�f�[�^�擾����(A-3)
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --��������
    IF ( lv_retcode <> cv_status_normal ) THEN
      --��O����(A-7)
      IF ( UTL_FILE.IS_OPEN(
             file => gt_f_handle
           )
         )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�Ώۃf�[�^���ݔ���
    --==============================================================
    IF ( gn_target_cnt <> cn_0 ) THEN
      --�x���ێ��p�ϐ��F����
      lv_worn_status := cv_n;
      --============================================================
      --CSV�w�b�_���R�[�h�쐬����(A-4)
      --============================================================
      proc_out_csv_header(
        lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      --��������
      IF (lv_retcode <> cv_status_normal) THEN
        --��O����(A-7)
        IF ( UTL_FILE.IS_OPEN(
               file => gt_f_handle
             )
           )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
        RAISE global_process_expt;
      END IF;
      --============================================================
      --�f�[�^���R�[�h�쐬����(A-5)
      --============================================================
      proc_out_data_record(
        lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      --��������
      IF (lv_retcode <> cv_status_normal) THEN
        --��O����(A-7)
        IF ( UTL_FILE.IS_OPEN(
               file => gt_f_handle
             )
           )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
        RAISE global_process_expt;
      END IF;
    --�ΏۂȂ��̏ꍇ
    ELSE
      --���b�Z�[�W�擾
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_no_target   --�p�����[�^�[�o��(�����ΏۂȂ�)
                          );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
      --���O�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_no_target_msg
      );
      --�󔒍s�̏o��(�o��)
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => ''
      );
      --�x���ێ��p�ϐ��F�x��
      lv_worn_status := cv_y;
    END IF;
    --============================================================
    --�t�b�^���R�[�h�쐬����(A-6)
    --============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --��������
    IF (lv_retcode <> cv_status_normal) THEN
      --��O����(A-7)
      IF ( UTL_FILE.IS_OPEN(
             file => gt_f_handle
           )
         )
      THEN
        UTL_FILE.FCLOSE(
          file => gt_f_handle
        );
      END IF;
      RAISE global_process_expt;
    END IF;
--
    --�x���I���̔���
    IF ( lv_worn_status = cv_y ) THEN
      ov_retcode := cv_status_warn; --�x���I���ɂ���
    END IF;
--
  EXCEPTION
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name          IN  VARCHAR2,      --  1.�t�@�C����
    iv_chain_code         IN  VARCHAR2,      --  2.�`�F�[���X�R�[�h
    iv_report_code        IN  VARCHAR2,      --  3.���[�R�[�h
    iv_user_id            IN  VARCHAR2,      --  4.���[�UID
    iv_chain_name         IN  VARCHAR2,      --  5.�`�F�[���X��
    iv_store_code         IN  VARCHAR2,      --  6.�X�܃R�[�h
    iv_base_code          IN  VARCHAR2,      --  7.���_�R�[�h
    iv_base_name          IN  VARCHAR2,      --  8.���_��
    iv_data_type_code     IN  VARCHAR2,      --  9.���[��ʃR�[�h
    iv_oprtn_series_code  IN  VARCHAR2,      -- 10.�Ɩ��n��R�[�h
    iv_report_name        IN  VARCHAR2,      -- 11.���[�l��
    iv_to_subinv_code     IN  VARCHAR2,      -- 12.������ۊǏꏊ�R�[�h
    iv_center_code        IN  VARCHAR2,      -- 13.�Z���^�[�R�[�h
    iv_invoice_number     IN  VARCHAR2,      -- 14.�`�[�ԍ�
    iv_sch_ship_date_from IN  VARCHAR2,      -- 15.�o�ח\���FROM
    iv_sch_ship_date_to   IN  VARCHAR2,      -- 16.�o�ח\���TO
    iv_sch_arrv_date_from IN  VARCHAR2,      -- 17.���ɗ\���FROM
    iv_sch_arrv_date_to   IN  VARCHAR2,      -- 18.���ɗ\���TO
    iv_move_order_number  IN  VARCHAR2,      -- 19.�ړ��I�[�_�[�ԍ�
    iv_edi_send_flag      IN  VARCHAR2       -- 20.EDI���M��
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
       iv_file_name           --  �t�@�C����
      ,iv_chain_code          --  �`�F�[���X�R�[�h
      ,iv_report_code         --  ���[�R�[�h
      ,iv_user_id             --  ���[�UID
      ,iv_chain_name          --  �`�F�[���X��
      ,iv_store_code          --  �X�܃R�[�h
      ,iv_base_code           --  ���_�R�[�h
      ,iv_base_name           --  ���_��
      ,iv_data_type_code      --  ���[��ʃR�[�h
      ,iv_oprtn_series_code   -- �Ɩ��n��R�[�h
      ,iv_report_name         -- ���[�l��
      ,iv_to_subinv_code      -- ������ۊǏꏊ�R�[�h
      ,iv_center_code         -- �Z���^�[�R�[�h
      ,iv_invoice_number      -- �`�[�ԍ�
      ,iv_sch_ship_date_from  -- �o�ח\���FROM
      ,iv_sch_ship_date_to    -- �o�ח\���TO
      ,iv_sch_arrv_date_from  -- ���ɗ\���FROM
      ,iv_sch_arrv_date_to    -- ���ɗ\���TO
      ,iv_move_order_number   -- �ړ��I�[�_�[�ԍ�
      ,iv_edi_send_flag       -- EDI���M��
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --�����̐ݒ�
      gn_normal_cnt := cn_0;          --����=0��
      gn_error_cnt  := gn_target_cnt; --�ُ�=�����Ώی�
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
END XXCOS014A11C;
/
