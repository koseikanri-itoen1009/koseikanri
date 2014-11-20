CREATE OR REPLACE PACKAGE BODY XXCOS011A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A04C (body)
 * Description      : ���ɗ\��f�[�^�̍쐬���s��
 * MD.050           : ���ɗ\��f�[�^�쐬 (MD050_COS_011_A04)
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0,A-1)
 *  output_header          �t�@�C����������(A-2)
 *  get_edi_stc_data       ���ɗ\���񒊏o(A-3)
 *  chk_line_cnt           ���׌����`�F�b�N����(A-12)
 *  edit_edi_stc_data      �f�[�^�ҏW(A-4,A-5,A-6)
 *  output_footer          �t�@�C���I������(A-7)
 *  upd_edi_send_flag      �t���O�X�V(A-8)
 *  del_edi_stc_data       ���ɗ\��p�[�W(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0  K.Kiriu          �V�K�쐬
 *  2008/02/27    1.1  K.Kiriu          [COS_147]�ŗ��̎擾�����ǉ�
 *  2009/03/10    1.2  T.Kitajima       [T1_0030]�ڋq�i�ڂ̖����G���[�Ή�
 *  2009/04/06    1.3  T.Kitajima       [T1_0043]�ڋq�i�ڂ̍i�荞�ݏ����ɒP�ʂ�ǉ�
 *  2009/04/28    1.4  K.Kiriu          [T1_0756]���R�[�h���ύX�Ή�
 *  2009/06/15    1.5  N.Maeda          [T1_1356]�o�̓f�[�^�t�@�C��No�l�C��
 *  2009/07/08         N.Maeda          [T1_1356]���r���[�w�E�Ή�
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^�`�F�b�N���̃G���[
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --���b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A04C'; -- �p�b�P�[�W��
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';        -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_edi_p_term     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';        -- XXCOS:EDI���폜����
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             -- XXCCP:IF���R�[�h�敪_�w�b�_
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               -- XXCCP:IF���R�[�h�敪_�f�[�^
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             -- XXCCP:IF���R�[�h�敪_�t�b�^
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      -- XXCOS:UTL_MAX�s�T�C�Y
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_INV_DIR';  -- XXCOS:EDI%�f�B���N�g���p�X(���̗�)
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';             -- GL��v����ID
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       -- MO:�c�ƒP��
  -- ���b�Z�[�W�R�[�h
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�Ȃ��G���[
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- �K�{���̓p�����[�^���ݒ�G���[
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_base_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12301';  -- ���_���擾�G���[
  cv_msg_edi_c_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- EDI�`�F�[���X���擾�G���[
  cv_msg_data_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12302';  -- �f�[�^����擾�G���[
  cv_msg_edi_i_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';  -- EDI�A�g�i�ڃR�[�h�敪�G���[
  cv_msg_tax_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12315';  -- �ŗ��擾�G���[
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- �o�͏��ҏW�G���[
  cv_msg_upd_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12303';  -- �f�[�^�X�V�G���[
  cv_msg_purge_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12304';  -- �p�[�W�G���[
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- �t�@�C���I�[�v���G���[
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IF�t�@�C�����C�A�E�g��`���擾�G���[
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[
  cv_msg_line_cnt_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12316';  -- ���ɗ\��f�[�^�쐬�G���[
  cv_msg_param          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12305';  -- �p�����[�^�[�o��
  cv_msg_file_nmae      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- �t�@�C�����o��
  cv_msg_l_meaning1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12308';  -- �N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
  cv_msg_param_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12309';  -- ������ۊǏꏊ
  cv_msg_param_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12310';  -- EDI�`�F�[���X�R�[�h
  cv_msg_param_tkn3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12311';  -- �t�@�C����
  cv_msg_prf_tkn1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12306';  -- EDI���폜����
  cv_msg_prf_tkn2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- IF���R�[�h�敪_�w�b�_
  cv_msg_prf_tkn3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- IF���R�[�h�敪_�f�[�^
  cv_msg_prf_tkn4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- IF���R�[�h�敪_�t�b�^
  cv_msg_prf_tkn5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';  -- UTL_MAX�s�T�C�Y
  cv_msg_prf_tkn6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00108';  -- �݌Ɍn�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_msg_prf_tkn7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';  -- GL��v����ID
  cv_msg_prf_tkn8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- �c�ƒP��
  cv_msg_layout_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';  -- �󒍌n���C�A�E�g
  cv_msg_lookup_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- �N�C�b�N�R�[�h(EDI�}�̋敪)
  cv_msg_table_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- �N�C�b�N�R�[�h
  cv_msg_tbale_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12312';  -- ���ɗ\��e�[�u��
  cv_msg_tbale_tkn3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12313';  -- �ړ��I�[�_�[�w�b�_�e�[�u��
  cv_msg_tbale_tkn4     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12314';  -- ���ɗ\��w�b�_�e�[�u��
  -- �g�[�N���R�[�h
  cv_tkn_in_param       CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- �p�����[�^����
  cv_tkn_prf            CONSTANT VARCHAR2(7)   := 'PROFILE';           -- �v���t�@�C������
  cv_tkn_sub_i          CONSTANT VARCHAR2(6)   := 'SUBINV';            -- ������ۊǏꏊ
  cv_tkn_forw_n         CONSTANT VARCHAR2(12)  := 'EDI_PARA_NUM';      -- EDI�`���ǔ�
  cv_tkn_chain_s        CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';   -- �`�F�[���X
  cv_tkn_err_m          CONSTANT VARCHAR2(6)   := 'ERRMSG';            -- �G���[���b�Z�[�W��
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';             -- �e�[�u����
  cv_tkn_file_n         CONSTANT VARCHAR2(9)   := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_file_l         CONSTANT VARCHAR2(6)   := 'LAYOUT';            -- �t�@�C�����C�A�E�g���
  cv_tkn_table_n        CONSTANT VARCHAR2(10)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_key            CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- �L�[�f�[�^
  cv_tkn_cnt            CONSTANT VARCHAR2(5)   := 'COUNT';             -- ����
  cv_tkn_pram1          CONSTANT VARCHAR2(6)   := 'PARAM1';            -- �p�����[�^�[�P
  cv_tkn_pram2          CONSTANT VARCHAR2(6)   := 'PARAM2';            -- �p�����[�^�[�Q
  cv_tkn_pram3          CONSTANT VARCHAR2(6)   := 'PARAM3';            -- �p�����[�^�[�R
  cv_tkn_invoice_num    CONSTANT VARCHAR2(11)  := 'INVOICE_NUM';       -- �`�[�ԍ�
  cv_tkn_item_code      CONSTANT VARCHAR2(20)  := 'ITEM_CODE';         -- �i�ڃR�[�h
  cv_tkn_cust_item_code CONSTANT VARCHAR2(20)  := 'CUST_ITEM_CODE';    -- �ڋq�i�ڃR�[�h
  -- ���t
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            -- �V�X�e�����t
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; -- �Ɩ�������
  -- �ڋq�}�X�^�擾�p�Œ�l
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- �ڋq�敪(�`�F�[���X)
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                -- �ڋq�敪(�ڋq)
  cv_cust_status        CONSTANT VARCHAR2(2)   := '90';                -- �ڋq�X�e�[�^�X(���~���ٍ�)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- �X�e�[�^�X(�ڋq�L��)
  -- �N�C�b�N�R�[�h�^�C�v
  cv_edi_media_class_t  CONSTANT VARCHAR2(22)  := 'XXCOS1_EDI_MEDIA_CLASS';  -- EDI�}�̋敪
  cv_data_type_code_t   CONSTANT VARCHAR2(21)  := 'XXCOS1_DATA_TYPE_CODE';   -- �f�[�^��
  -- �N�C�b�N�R�[�h
  cv_data_type_code_c   CONSTANT VARCHAR2(3)   := '050';               -- �f�[�^��(���ɗ\��)
  -- ���̑��Œ�l
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g(��)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';          -- ���t�t�H�[�}�b�g(����)
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- �Œ�l:0(VARCHAR2)
  cn_0                  CONSTANT NUMBER        := 0;                   -- �Œ�l:0(NUMBER)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- �Œ�l:1(VARCHAR2)
  cn_1                  CONSTANT NUMBER        := 1;                   -- �Œ�l:1(NUMBER)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- �Œ�l:2
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- �Œ�l:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- �Œ�l:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- �Œ�l:W
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
/* 2009/04/28 Ver1.4 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     --�\���G���A
/* 2009/04/28 Ver1.4 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gt_f_handle           UTL_FILE.FILE_TYPE;                            --�t�@�C���n���h��
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;       --�t�@�C�����C�A�E�g
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���o�͍��ڗp
  gv_f_o_date           CHAR(8);                                       --������
  gv_f_o_time           CHAR(6);                                       --��������
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;                --�ŗ�
  gt_edi_media_class    fnd_lookup_values_vl.lookup_code%TYPE;         --EDI�}�̋敪
  gt_data_type_code     fnd_lookup_values_vl.lookup_code%TYPE;         --�f�[�^��R�[�h
  -- ��������A���ʊ֐��p
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    --EDI�A�g�i�ڃR�[�h�敪
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         --�ڋqID(�`�F�[���X)
  gt_from_series        fnd_lookup_values_vl.attribute1%TYPE;          --IF���Ɩ��n��R�[�h
  gv_edi_p_term         VARCHAR2(4);                                   --EDI���폜����
  gv_if_header          VARCHAR2(2);                                   --�w�b�_���R�[�h�敪
  gv_if_data            VARCHAR2(2);                                   --�f�[�^���R�[�h�敪
  gv_if_footer          VARCHAR2(2);                                   --�t�b�^���R�[�h�敪
  gv_utl_m_line         VARCHAR2(100);                                 --UTL_MAX�s�T�C�Y
  gv_outbound_d         VARCHAR2(100);                                 --�A�E�g�o�E���h�p�f�B���N�g���p�X
  gn_bks_id             NUMBER;                                        --��v����ID
  gn_org_id             NUMBER;                                        --�c�ƒP��
--********************  2009/07/08    1.5  N.Maeda MOD Start ********************
  gt_edi_f_number       xxcmm_cust_accounts.edi_forward_number%TYPE;   --�t�@�C��No.
--********************  2009/07/08    1.5  N.Maeda MOD  End  ********************
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  --�w�b�_���
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE,  --�[�i���_�R�[�h
    delivery_base_name        hz_parties.party_name%TYPE,                   --�[�i���_��
    delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE,   --�[�i���_�J�i
    delivery_base_l_phonetic  hz_locations.address_lines_phonetic%TYPE,     --�[�i���_�d�b�ԍ�
    edi_chain_name            hz_parties.party_name%TYPE,                   --EDI�`�F�[���X��
    edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE    --EDI�`�F�[���X�J�i
  );
  gt_header_data  g_header_data_rtype;
  --���ɗ\����
  TYPE g_edi_stc_data_rtype IS RECORD(
    header_id                    xxcos_edi_stc_headers.header_id%TYPE,                    --�w�b�_ID
    move_order_header_id         xxcos_edi_stc_headers.move_order_header_id%TYPE,         --�ړ��I�[�_�[�w�b�_ID
    move_order_num               xxcos_edi_stc_headers.move_order_num%TYPE,               --�ړ��I�[�_�[�ԍ�
    to_subinventory_code         xxcos_edi_stc_headers.to_subinventory_code%TYPE,         --������ۊǏꏊ
    customer_code                xxcos_edi_stc_headers.customer_code%TYPE,                --�ڋq�R�[�h
    customer_name                hz_parties.party_name%TYPE,                              --�ڋq����
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,              --�ڋq���J�i
    edi_chain_code               xxcos_edi_stc_headers.edi_chain_code%TYPE,               --EDI�`�F�[���X�R�[�h
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
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
--    ship_qty                     NUMBER                                                   --�o�א���(���v�A�o��)
    ship_qty                     NUMBER,                                                  --�o�א���(���v�A�o��)
    inactive_flag                mtl_customer_items.inactive_flag%TYPE,                   --�ڋq�i��.�L���t���O
    inactive_ref_flag            mtl_customer_item_xrefs.inactive_flag%TYPE               --�ڋq�i�ڑ��ݎQ��.�L���t���O
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--    edi_forward_number           xxcmm_cust_accounts.edi_forward_number%TYPE              --EDI�`�[�ǔ�
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --���ɗ\���� �e�[�u���^
  TYPE g_edi_stc_data_ttype IS TABLE OF g_edi_stc_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_stc_date  g_edi_stc_data_ttype;
  --�t���O�s�i�p�`�[�ԍ� �e�[�u���^
  TYPE g_invoice_num_ttype IS TABLE OF xxcos_edi_stc_headers.invoice_number%TYPE INDEX BY BINARY_INTEGER;
  gt_invoice_num    g_invoice_num_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0,A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name        IN  VARCHAR2,                                           --  �t�@�C����
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  ������ۊǏꏊ
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  EDI�`�F�[���X�R�[�h
    iv_edi_f_number     IN  xxcmm_cust_accounts.edi_forward_number%TYPE,        --  EDI�`���ǔ�
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn_name1   VARCHAR2(50);    --�g�[�N���擾�p1
    lv_tkn_name2   VARCHAR2(50);    --�g�[�N���擾�p2
    ln_err_chk     NUMBER(1);       --�v���t�@�C���G���[�`�F�b�N�p
    lv_err_msg     VARCHAR2(5000);  --�v���t�@�C���G���[�o�͗p(�擾�G���[���Ƃɏo�͂����)
    lv_l_meaning fnd_lookup_values_vl.meaning%TYPE;  --�N�C�b�N�R�[�h�����擾�p
    lv_dummy       VARCHAR2(1);     --���C�A�E�g��`��CSV�w�b�_�[�p(�t�@�C���^�C�v���Œ蒷�Ȃ̂Ŏg�p����Ȃ�)
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
    --�R���J�����g�̋��ʂ̏����o��
    --==============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�p�����[�^�o�̓��b�Z�[�W�擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_param       --�p�����[�^�[�o��
                     ,iv_token_name1  => cv_tkn_pram1       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => it_to_s_code       --������ۊǏꏊ
                     ,iv_token_name2  => cv_tkn_pram2       --�g�[�N���R�[�h�Q
                     ,iv_token_value2 => it_edi_c_code      --EDI�`�F�[���X�R�[�h
                     ,iv_token_name3  => cv_tkn_pram3       --�g�[�N���R�[�h�R
                     ,iv_token_value3 => iv_edi_f_number    --EDI�`���ǔ�
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�t�@�C�������b�Z�[�W�擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_file_nmae   --�t�@�C�����o��
                     ,iv_token_name1  => cv_tkn_file_n      --�g�[�N���R�[�h�P
                     ,iv_token_value1 => iv_file_name       --�t�@�C����
                    );
    --�t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    --�V�X�e�����t�擾
    --==============================================================
    gv_f_o_date := TO_CHAR(cd_sysdate, cv_date_format);  --������
    gv_f_o_time := TO_CHAR(cd_sysdate, cv_time_format);  --��������
    --==============================================================
    --�p�����[�^�`�F�b�N
    --==============================================================
    -- ������ۊǏꏊ
    IF ( it_to_s_code IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn1  --������ۊǏꏊ
                      );
    -- EDI�`�F�[���X�R�[�h
    ELSIF ( it_edi_c_code IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn2  --EDI�`�F�[���X�R�[�h
                      );
    -- EDI�`���ǔ�
    ELSIF ( iv_edi_f_number IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_param_tkn3  --�t�@�C����
                      );
    END IF;
    --���b�Z�[�W�ݒ�
    IF ( it_to_s_code IS NULL )
      OR ( it_edi_c_code IS NULL )
      OR ( iv_edi_f_number IS NULL )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application   --�A�v���P�[�V����
                    ,iv_name         => cv_msg_param_err --�p�����[�^�[�K�{�G���[
                    ,iv_token_name1  => cv_tkn_in_param  --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1     --�p�����[�^��
                   );
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --�v���t�@�C�����̎擾
    --==============================================================
    ln_err_chk     := 0;                                                --�G���[�`�F�b�N�p�ϐ��̏�����
    gv_edi_p_term  := FND_PROFILE.VALUE( cv_prf_edi_p_term );           --EDI���폜����
    gv_if_header   := FND_PROFILE.VALUE( cv_prf_if_header );            --�w�b�_���R�[�h�敪
    gv_if_data     := FND_PROFILE.VALUE( cv_prf_if_data );              --�f�[�^���R�[�h�敪
    gv_if_footer   := FND_PROFILE.VALUE( cv_prf_if_footer );            --�t�b�^���R�[�h�敪
    gv_utl_m_line  := FND_PROFILE.VALUE( cv_prf_utl_m_line );           --UTL_MAX�s�T�C�Y
    gv_outbound_d  := FND_PROFILE.VALUE( cv_prf_outbound_d );           --�A�E�g�o�E���h�p�f�B���N�g���p�X
    gn_bks_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );  --GL��v����ID
    gn_org_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );  --�c�ƒP��
    --EDI���폜���Ԃ̃`�F�b�N
    IF ( gv_edi_p_term IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn1  --EDI���폜����
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�w�b�_���R�[�h�敪�̃`�F�b�N
    IF ( gv_if_header IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn2  --�w�b�_���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�f�[�^���R�[�h�敪�̃`�F�b�N
    IF ( gv_if_data IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn3  --�f�[�^���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�t�b�^���R�[�h�敪�̃`�F�b�N
    IF ( gv_if_footer IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn4  --�t�b�^���R�[�h�敪
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --UTL_MAX�s�T�C�Y�̃`�F�b�N
    IF ( gv_utl_m_line IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn5  --UTL_MAX�s�T�C�Y
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�A�E�g�o�E���h�p�f�B���N�g���p�X�̃`�F�b�N
    IF ( gv_outbound_d IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn6  --�A�E�g�o�E���h�p�f�B���N�g���p�X
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --GL��v����ID�̃`�F�b�N
    IF ( gn_bks_id IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn7  --GL��v����ID
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;
    --�c�ƒP�ʂ̃`�F�b�N
    IF ( gn_org_id IS NULL ) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --�A�v���P�[�V����
                       ,iv_name         => cv_msg_prf_tkn8  --�c�ƒP��
                      );
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --�G���[�L��
    END IF;

    --�v���t�@�C���擾�ŃG���[�̏ꍇ
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --�N�C�b�N�R�[�h���̎擾
    --==============================================================
    --���C�A�E�g��`���
    xxcos_common2_pkg.get_layout_info(
      iv_file_type        =>  cv_0                --�t�@�C���`��(�Œ蒷)
     ,iv_layout_class     =>  cv_0                --���敪(�󒍌n)
     ,ov_data_type_table  =>  gt_data_type_table  --�f�[�^�^�\
     ,ov_csv_header       =>  lv_dummy            --CSV�w�b�_
     ,ov_errbuf           =>  lv_errbuf           --�G���[���b�Z�[�W
     ,ov_retcode          =>  lv_retcode          --���^�[���R�[�h
     ,ov_errmsg           =>  lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --�g�[�N���擾
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      --�A�v���P�[�V����
                       ,iv_name         => cv_msg_layout_tkn1  --�󒍌n���C�A�E�g
                      );
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --�A�v���P�[�V����
                    ,iv_name         => cv_msg_file_inf_err  --IF�t�@�C�����C�A�E�g��`���擾�G���[
                    ,iv_token_name1  => cv_tkn_file_l        --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1         --�󒍌n���C�A�E�g
                   );
      RAISE global_data_check_expt;
    END IF;
    -- EDI�A�g�i�ڃR�[�h�敪
    BEGIN
      SELECT  xca.edi_item_code_div  edi_item_code_div  --EDI�A�g�i�ڃR�[�h
             ,hca.cust_account_id    cust_account_id    --�ڋqID(�`�F�[���X)
      INTO    gt_edi_item_code_div
             ,gt_chain_cust_acct_id
      FROM    hz_cust_accounts    hca  --�ڋq
             ,xxcmm_cust_accounts xca  --�ڋq�ǉ����
      WHERE   hca.customer_class_code =  cv_cust_code_chain  --�ڋq�敪(�`�F�[���X)
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  it_edi_c_code       --EDI�`�F�[���X�R�[�h
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gt_edi_item_code_div := NULL;
        lv_errbuf            := SQLERRM;
    END;
    --�擾�ł��Ȃ��ANULL�A�擾�����敪��JAN���A�ڋq�ȊO�̏ꍇ�G���[
    IF ( gt_edi_item_code_div IS NULL )
      OR ( gt_edi_item_code_div NOT IN ( cv_1, cv_2 ) )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --�A�v���P�[�V����
                    ,iv_name         => cv_msg_edi_i_inf_err --EDI�`�F�[���X���擾�G���[
                    ,iv_token_name1  => cv_tkn_chain_s       --�g�[�N���R�[�h�P
                    ,iv_token_value1 => it_edi_c_code        --�p�����[�^��
                   );
      RAISE global_data_check_expt;
    END IF;
    -- �ŗ�
    BEGIN
      SELECT  xtrv.tax_rate             --�ŗ�
      INTO    gt_tax_rate
      FROM    hz_cust_accounts    hca   --�ڋq
             ,hz_parties          hp    --�p�[�e�B
             ,xxcmm_cust_accounts xca   --�ڋq�ǉ����
             ,xxcos_tax_rate_v    xtrv  --����ŗ��r���[
      WHERE   xtrv.set_of_books_id    =  gn_bks_id           --��v����ID
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
      AND     xca.chain_store_code    =  it_edi_c_code       --EDI�`�F�[���X
      AND     xca.ship_storage_code   =  it_to_s_code        --������ۊǏꏊ
      AND     rownum                  =  cn_1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --�A�v���P�[�V����
                      ,iv_name         => cv_msg_tax_err  --�ŗ��擾�G���[
                      ,iv_token_name1  => cv_tkn_chain_s  --�g�[�N���R�[�h�P
                      ,iv_token_value1 => it_edi_c_code   --�p�����[�^��
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_data_check_expt;
    END;
    -- EDI�}�̋敪
    BEGIN
      --���b�Z�[�W�����e���擾
      lv_l_meaning := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_l_meaning1  --�N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
                      );
      --�N�C�b�N�R�[�h�擾
      SELECT flvv.lookup_code lookup_code
      INTO   gt_edi_media_class
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type   = cv_edi_media_class_t
      AND    flvv.meaning       = lv_l_meaning
      AND    flvv.enabled_flag  = cv_y          --�L��
      AND    (
               ( flvv.start_date_active IS NULL )
               OR
               ( flvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( flvv.end_date_active IS NULL )
               OR
               ( flvv.end_date_active >= cd_process_date )
             )  --�Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_table_tkn1  --�N�C�b�N�R�[�h
                       );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_lookup_tkn1 --�N�C�b�N�R�[�h(EDI�}�̋敪)
                       );
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       --�A�v���P�[�V����
                      ,iv_name         => cv_msg_data_get_err  --�f�[�^���o�G���[
                      ,iv_token_name1  => cv_tkn_table_n       --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name1         --�p�����[�^��
                      ,iv_token_name2  => cv_tkn_key           --�g�[�N���R�[�h�Q
                      ,iv_token_value2 => lv_tkn_name2         --�p�����[�^��
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_data_check_expt;
    END;
    -- �f�[�^����
    BEGIN
      SELECT  flvv.meaning     meaning     --�f�[�^��
             ,flvv.attribute1  attribute1  --IF���Ɩ��n��R�[�h
      INTO    gt_data_type_code
             ,gt_from_series
      FROM    fnd_lookup_values_vl flvv
      WHERE   flvv.lookup_type  = cv_data_type_code_t
      AND     flvv.lookup_code  = cv_data_type_code_c
      AND     flvv.enabled_flag = cv_y          --�L��
      AND    (
               ( flvv.start_date_active IS NULL )
               OR
               ( flvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( flvv.end_date_active IS NULL )
               OR
               ( flvv.end_date_active >= cd_process_date )
             )  --�Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       --�A�v���P�[�V����
                      ,iv_name         => cv_msg_data_inf_err  --�f�[�^���o�G���[
                     );
        lv_errbuf  := SQLERRM;
      RAISE global_data_check_expt;
    END;
--
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                       location      =>  gv_outbound_d  --�A�E�g�o�E���h�p�f�B���N�g���p�X
                      ,filename      =>  iv_file_name   --�t�@�C����
                      ,open_mode     =>  cv_w           --�I�[�v�����[�h
                      ,max_linesize  =>  gv_utl_m_line  --MAX�T�C�Y
                     );
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                      ,cv_msg_file_o_err
                      ,cv_tkn_file_n
                      ,iv_file_name
                     );
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** �N�C�b�N�R�[�h�擾�G���[ ****
    WHEN global_data_check_expt THEN
      --�l��NULL�A�������͑ΏۊO
      IF ( lv_errbuf IS NULL ) THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      --���̑���O
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
   * Procedure Name   : output_header
   * Description      : �t�@�C����������(A-2)
   ***********************************************************************************/
  PROCEDURE output_header(
    it_to_s_code     IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  1.������ۊǏꏊ
    it_edi_c_code    IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  2.EDI�`�F�[���X�R�[�h
    iv_edi_f_number  IN  xxcmm_cust_accounts.edi_forward_number%TYPE,        --  3.EDI�`���ǔ�
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header'; -- �v���O������
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
/* 2009/04/28 Ver1.4 Mod Start */
--    lv_header_output  VARCHAR2(1000);  --�w�b�_�[�o�͗p
    lv_header_output  VARCHAR2(5000);  --�w�b�_�[�o�͗p
/* 2009/04/28 Ver1.4 Mod End   */
    ln_dummy          NUMBER;          --�w�b�_�o�͂̃��R�[�h�����p(�g�p����Ȃ�)
--
    -- *** ���[�J���E�J�[�\�� ***
    --���_���
    CURSOR cust_base_cur
    IS
      SELECT  hca.account_number             delivery_base_code         --�[�i���_�R�[�h
             ,hp.party_name                  delivery_base_name         --�[�i���_��
             ,hp.organization_name_phonetic  delivery_base_phonetic     --�[�i���_���J�i
             ,hl.address_lines_phonetic      delivery_base_l_phonetic1  --�[�i���_�d�b�ԍ�
      FROM    hz_cust_accounts        hca   --���_(�ڋq)
             ,hz_parties              hp    --���_(�p�[�e�B)
             ,hz_cust_acct_sites_all  hcas  --�ڋq���ݒn
             ,hz_party_sites          hps   --�p�[�e�B�T�C�g
             ,hz_locations            hl    --�ڋq���ݒn(�A�J�E���g�T�C�g)
      WHERE   hps.location_id          = hl.location_id        --����(�p�[�e�B�T�C�g = �ڋq���ݒn(�A�J�E���g))
      AND     hcas.org_id              = gn_org_id             --�c�ƒP��
      AND     hcas.party_site_id       = hps.party_site_id     --����(�ڋq���ݒn = �p�[�e�B�T�C�g)
      AND     hca.cust_account_id      = hcas.cust_account_id  --����(���_(�ڋq) = �ڋq���ݒn)
      AND     hca.party_id             = hp.party_id           --����(���_(�ڋq) = ���_(�p�[�e�B))
      AND     hca.account_number       = 
                ( SELECT  xca1.delivery_base_code
                  FROM    hz_cust_accounts     hca1  --�ڋq
                         ,hz_parties           hp1   --�p�[�e�B
                         ,xxcmm_cust_accounts  xca1  --�ڋq�ǉ����
                  WHERE   hp1.duns_number_c        <> cv_cust_status     --�ڋq�X�e�[�^�X(���~���ٍψȊO)
                  AND     hca1.party_id            =  hp1.party_id       --����(�ڋq = �p�[�e�B)
                  AND     hca1.status              =  cv_status_a        --�X�e�[�^�X(�ڋq�L��)
                  AND     hca1.customer_class_code =  cv_cust_code_cust  --�ڋq�敪(�ڋq)
                  AND     hca1.cust_account_id     =  xca1.customer_id   --����(�ڋq = �ڋq�ǉ�)
                  AND     xca1.ship_storage_code   =  it_to_s_code       --������ۊǏꏊ
                  AND     xca1.chain_store_code    =  it_edi_c_code      --EDI�`�F�[���X�R�[�h
                  AND     ROWNUM                   =  cn_1
                )
      ;
    --EDI�`�F�[���X���
    CURSOR edi_chain_cur
    IS
      SELECT  hp.party_name                  edi_chain_name      --EDI�`�F�[���X��
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDI�`�F�[���X���J�i
      FROM    hz_parties          hp   --�p�[�e�B
             ,hz_cust_accounts    hca  --�ڋq
      WHERE   hca.party_id         =  hp.party_id            --����(�ڋq = �p�[�e�B)
      AND     hca.cust_account_id  =  gt_chain_cust_acct_id  --�ڋqID(�`�F�[���X)
      ;
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
    --�e���̎擾
    --==============================================================
    --���_���
    OPEN cust_base_cur;
    FETCH cust_base_cur
      INTO  gt_header_data.delivery_base_code        --�[�i���_�R�[�h
           ,gt_header_data.delivery_base_name        --�[�i���_��
           ,gt_header_data.delivery_base_phonetic    --�[�i���_���J�i
           ,gt_header_data.delivery_base_l_phonetic  --�[�i���_�d�b�ԍ�
    ;
    --�f�[�^���擾�ł��Ȃ��ꍇ�G���[
    IF ( cust_base_cur%NOTFOUND )THEN
      CLOSE cust_base_cur;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --�A�v���P�[�V����
                    ,iv_name         => cv_msg_base_inf_err  --���_���擾�G���[
                    ,iv_token_name1  => cv_tkn_sub_i         --�g�[�N���R�[�h�P
                    ,iv_token_value1 => it_to_s_code         --������ۊǏꏊ
                    ,iv_token_name2  => cv_tkn_chain_s       --�g�[�N���R�[�h�P
                    ,iv_token_value2 => it_edi_c_code        --EDI�`�F�[���X�R�[�h
                    ,iv_token_name3  => cv_tkn_forw_n        --�g�[�N���R�[�h�P
                    ,iv_token_value3 => iv_edi_f_number      --EDI�`���ǔ�
                    
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE cust_base_cur;
    --EDI�`�F�[���X���
    OPEN edi_chain_cur;
    FETCH edi_chain_cur
      INTO  gt_header_data.edi_chain_name           --EDI�`�F�[���X��
           ,gt_header_data.edi_chain_name_phonetic  --EDI�`�F�[���X�J�i
    ;
    --�f�[�^���擾�ł��Ȃ��ꍇ�G���[
    IF ( edi_chain_cur%NOTFOUND )THEN
      CLOSE edi_chain_cur;
      --���b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --�A�v���P�[�V����
                    ,iv_name         => cv_msg_edi_c_inf_err --EDI�`�F�[���X���擾�G���[
                    ,iv_token_name1  => cv_tkn_chain_s       --�g�[�N���R�[�h�P
                    ,iv_token_value1 => it_edi_c_code        --EDI�`�F�[���X�R�[�h
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE edi_chain_cur;
    --==============================================================
    --���ʊ֐��Ăяo��
    --==============================================================
    --EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_header    --�t�^�敪
     ,iv_from_series     =>  gt_from_series  --IF���Ɩ��n��R�[�h
     ,iv_base_code       =>  gt_header_data.delivery_base_code
     ,iv_base_name       =>  gt_header_data.delivery_base_name
     ,iv_chain_code      =>  it_edi_c_code
     ,iv_chain_name      =>  gt_header_data.edi_chain_name
     ,iv_data_kind       =>  gt_data_type_code
     ,iv_row_number      =>  iv_edi_f_number
     ,in_num_of_records  =>  ln_dummy
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�@�C���o��
    --==============================================================
    --�w�b�_�o��
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_header_output  --�o�͕���(�w�b�_)
    );
-- ********************* 2009/07/08 1.5  N.Maeda MOD Start ********************--
   -- �t�@�C��No.�p
   gt_edi_f_number := iv_edi_f_number;
-- ********************* 2009/07/08 1.5  N.Maeda MOD  End  ********************--
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
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_stc_data
   * Description      : ���ɗ\���񒊏o(A-3)
   ***********************************************************************************/
  PROCEDURE get_edi_stc_data(
    it_to_s_code   IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  1.������ۊǏꏊ
    it_edi_c_code  IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  2.EDI�`�F�[���X�R�[�h
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_stc_data'; -- �v���O������
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
    lv_tkn_name  VARCHAR2(50);  --�g�[�N���擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --EDI�A�g�i�ڃR�[�h�u�ڋq�i�ځv
    CURSOR cust_item_cur
    IS
      SELECT  xesh.header_id                          header_id                    --�w�b�_ID
             ,xesh.move_order_header_id               move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
             ,xesh.move_order_num                     move_order_num               --�ړ��I�[�_�[�ԍ�
             ,xesh.to_subinventory_code               to_subinventory_code         --������ۊǏꏊ
             ,xesh.customer_code                      customer_code                --�ڋq�R�[�h
             ,hca.party_name                          customer_name                --�ڋq����
             ,hca.organization_name_phonetic          customer_phonetic            --�ڋq���J�i
             ,xesh.edi_chain_code                     edi_chain_code               --EDI�`�F�[���X�R�[�h
             ,xesh.shop_code                          shop_code                    --�X�R�[�h
             ,hca.cust_store_name                     shop_name                    --�X��
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
             ,xesl.inventory_item_id                  inventory_item_id            --�i��ID
             ,xesh.organization_id                    organization_id              --�g�DID
             ,msib.segment1                           item_code                    --�i�ڃR�[�h
             ,ximb.item_name                          item_name                    --�i�ږ�����
             ,SUBSTRB( ximb.item_name_alt, 1, 15 )    item_phonetic1               --�i�ږ��J�i�P
             ,SUBSTRB( ximb.item_name_alt, 16, 15 )   item_phonetic2               --�i�ږ��J�i�Q
             ,iimb.attribute11                        case_inc_num                 --�P�[�X����
             ,xsib.bowl_inc_num                       bowl_inc_num                 --�{�[������
             ,iimb.attribute21                        jan_code                     --JAN�R�[�h
             ,iimb.attribute22                        itf_code                     --ITF�R�[�h
             ,xhpc.item_div_h_code                    item_div_code                --�{�Џ��i�敪
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--             ,mci.customer_item_number                customer_item_number         --�ڋq�i��
             ,mcis.customer_item_number               customer_item_number         --�ڋq�i��
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
             ,xesl.case_qty_sum                       case_qty                     --�P�[�X��
             ,xesl.indv_qty_sum                       indv_qty                     --�o����
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --�o�א���(���v�A�o��)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,mcis.inactive_flag                      inactive_flag                --�ڋq�i��.�L���t���O
             ,mcis.inactive_ref_flag                  inactive_ref_flag            --�ڋq�i�ڑ��ݎQ��.�L���t���O
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--             ,hca.edi_forward_number                  edi_forward_number           --EDI�`�[�ǔ�
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
      FROM    xxcos_edi_stc_headers   xesh    --���ɗ\��w�b�_
             ,mtl_txn_request_headers mtrh    --�ړ��I�[�_�[�w�b�_
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--                       ,xca.edi_forward_number         edi_forward_number
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
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
                       ,SUM( xesl.case_qty )    case_qty_sum
                       ,SUM( xesl.indv_qty )    indv_qty_sum
                FROM    xxcos_edi_stc_lines   xesl
                GROUP BY
                        xesl.header_id
                       ,xesl.inventory_item_id
              )                        xesl   --���ɗ\�薾��(�i�ڃT�}��)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,(
                SELECT  mci.customer_id             customer_id
                       ,customer_item_number        customer_item_number
                       ,mci.inactive_flag           inactive_flag
                       ,mcix.inactive_flag          inactive_ref_flag
                       ,mcix.inventory_item_id      inventory_item_id
                       ,mp.organization_id          organization_id
--********************  2009/04/06    1.3  T.Kitajima ADD Start ********************
                       ,mci.attribute1              attribute1
--********************  2009/04/06    1.3  T.Kitajima ADD  End  ********************
                FROM    mtl_customer_item_xrefs  mcix   --�ڋq�i�ڑ��ݎQ��
                       ,mtl_customer_items       mci    --�ڋq�i��
                       ,mtl_parameters           mp     --�݌ɑg�D
                WHERE  mcix.customer_item_id        = mci.customer_item_id        --����(�ڋq�i�ڑ� = �ڋq�i��)
                AND    mp.master_organization_id    = mcix.master_organization_id --����(�݌ɑg�D   = �ڋq�i�ڑ�)
              ) mcis
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
             ,mtl_system_items_b       msib   --Disc�i��
             ,xxcmm_system_items_b     xsib   --Disc�i�ڃA�h�I��
             ,ic_item_mst_b            iimb   --OPM�i��
             ,xxcmn_item_mst_b         ximb   --OPM�i�ڃA�h�I��
--********************  2009/03/10    1.2  T.Kitajima EDL Start ********************
--             ,mtl_customer_item_xrefs  mcix   --�ڋq�i�ڑ��ݎQ��
--             ,mtl_customer_items       mci    --�ڋq�i��
--             ,mtl_parameters           mp     --�݌ɑg�D
--********************  2009/03/10    1.2  T.Kitajima DEL  End  ********************
             ,xxcos_head_prod_class_v  xhpc   --�{�Џ��i�敪�r���[
      WHERE  msib.inventory_item_id       = xhpc.inventory_item_id       --����(D�i�� = �{�Џ��i�敪)
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      AND    mci.inactive_flag            = cv_n                         --�L���t���O(�L��)
--      AND    mci.customer_id              = gt_chain_cust_acct_id        --�`�F�[���X�̌ڋq�i��
--      AND    mcix.customer_item_id        = mci.customer_item_id         --����(�ڋq�i�ڑ� = �ڋq�i��)
--      AND    mcix.inactive_flag           = cv_n                         --�L���t���O(�L��)
--      AND    mp.master_organization_id    = mcix.master_organization_id  --����(�݌ɑg�D = �ڋq�i�ڑ�)
--      AND    msib.inventory_item_id       = mcix.inventory_item_id       --����(D�i�� = �ڋq�i�ڑ�)
--      AND    xesh.organization_id         = mp.organization_id           --����(����H = �݌ɑg�D)
      AND    mcis.customer_id(+)          = gt_chain_cust_acct_id          --�`�F�[���X�̌ڋq�i��
      AND    msib.organization_id         = mcis.organization_id(+)        --����(D�i�� = �ڋq�i�ڑ�)
      AND    msib.inventory_item_id       = mcis.inventory_item_id(+)      --����(D�i�� = �ڋq�i�ڑ�)
--********************  2009/04/06    1.3  T.Kitajima ADD Start ********************
      AND    msib.primary_unit_of_measure = mcis.attribute1(+)             --����(D�i�� = �ڋq�i�ڑ�)
--********************  2009/04/06    1.3  T.Kitajima ADD  End  ********************
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
      AND    ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --O�i��A�K�p��FROM-TO
      AND    iimb.item_id                 = ximb.item_id                 --����(O�i�� = O�i��A)
      AND    msib.segment1                = iimb.item_no                 --����(D�i�� = O�i��)
      AND    msib.segment1                = xsib.item_code               --����(D�i�� = D�i��A)
      AND    xesh.organization_id         = msib.organization_id         --����(����H = D�i�� �w�b�_�̑g�D�Ō�������)
      AND    xesl.inventory_item_id       = msib.inventory_item_id       --����(����L = D�i��)
      AND    xesh.header_id               = xesl.header_id               --����(����H = ����L)
      AND    xesh.customer_code           = hca.account_number           --����(����H = �ڋq)
      AND    NVL( mtrh.attribute1, cv_n ) = cv_n                         --���ɗ\��A�g�σt���O(���A�g)
      AND    xesh.move_order_header_id    = mtrh.header_id(+)            --����(����H = �ړ�H)
      AND    xesh.edi_send_flag           = cv_n                         --EDI���M�σt���O(�����M)
      AND    xesh.fix_flag                = cv_y                         --�m��σt���O(�m���)
      AND    xesh.edi_chain_code          = it_edi_c_code                --EDI�`�F�[���X�R�[�h
      AND    xesh.to_subinventory_code    = it_to_s_code                 --������ۊǏꏊ
      ORDER BY
             xesh.invoice_number  --�`�[�ԍ�����(A-4�œ`�[�ԍ����ɏ����������)
      FOR UPDATE OF
             xesh.header_id
            ,mtrh.header_id NOWAIT
      ;
    --EDI�A�g�i�ڃR�[�h�uJAN�R�[�h�v
    CURSOR jan_item_cur
    IS
      SELECT  xesh.header_id                          header_id                    --�w�b�_ID
             ,xesh.move_order_header_id               move_order_header_id         --�ړ��I�[�_�[�w�b�_ID
             ,xesh.move_order_num                     move_order_num               --�ړ��I�[�_�[�ԍ�
             ,xesh.to_subinventory_code               to_subinventory_code         --������ۊǏꏊ
             ,xesh.customer_code                      customer_code                --�ڋq�R�[�h
             ,hca.party_name                          customer_name                --�ڋq����
             ,hca.organization_name_phonetic          customer_phonetic            --�ڋq���J�i
             ,xesh.edi_chain_code                     edi_chain_code               --EDI�`�F�[���X�R�[�h
             ,xesh.shop_code                          shop_code                    --�X�R�[�h
             ,hca.cust_store_name                     shop_name                    --�X��
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
             ,xesl.inventory_item_id                  inventory_item_id            --�i��ID
             ,xesh.organization_id                    organization_id              --�g�DID
             ,msib.segment1                           item_code                    --�i�ڃR�[�h
             ,ximb.item_name                          item_name                    --�i�ږ�����
             ,SUBSTRB( ximb.item_name_alt, 1, 15 )    item_phonetic1               --�i�ږ��J�i�P
             ,SUBSTRB( ximb.item_name_alt, 16, 15 )   item_phonetic2               --�i�ږ��J�i�Q
             ,iimb.attribute11                        case_inc_num                 --�P�[�X����
             ,xsib.bowl_inc_num                       bowl_inc_num                 --�{�[������
             ,iimb.attribute21                        jan_code                     --JAN�R�[�h
             ,iimb.attribute22                        itf_code                     --ITF�R�[�h
             ,xhpc.item_div_h_code                    item_div_code                --�{�Џ��i�敪
             ,iimb.attribute21                        customer_item_number         --�ڋq�i��(JAN�R�[�h)
             ,xesl.case_qty_sum                       case_qty                     --�P�[�X��
             ,xesl.indv_qty_sum                       indv_qty                     --�o����
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --�o�א���(���v�A�o��)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,NULL                                    inactive_flag                --EDI�A�g�i�ڃR�[�h�u�ڋq�i�ځv�̍��ڂƍ����邽�߂̃_�~�[
             ,NULL                                    inactive_ref_flag            --EDI�A�g�i�ڃR�[�h�u�ڋq�i�ځv�̍��ڂƍ����邽�߂̃_�~�[
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--             ,hca.edi_forward_number                  edi_forward_number           --EDI�`�[�ǔ�
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
      FROM    xxcos_edi_stc_headers   xesh    --���ɗ\��w�b�_
             ,mtl_txn_request_headers mtrh    --�ړ��I�[�_�[�w�b�_
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--                       ,xca.edi_forward_number         edi_forward_number
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
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
                       ,SUM( xesl.case_qty )    case_qty_sum
                       ,SUM( xesl.indv_qty )    indv_qty_sum
                FROM    xxcos_edi_stc_lines   xesl
                GROUP BY
                        xesl.header_id
                       ,xesl.inventory_item_id
              )                        xesl   --���ɗ\�薾��(�i�ڃT�}��)
             ,mtl_system_items_b       msib   --Disc�i��
             ,xxcmm_system_items_b     xsib   --Disc�i�ڃA�h�I��
             ,ic_item_mst_b            iimb   --OPM�i��
             ,xxcmn_item_mst_b         ximb   --OPM�i�ڃA�h�I��
             ,xxcos_head_prod_class_v  xhpc   --�{�Џ��i�敪�r���[
      WHERE  msib.inventory_item_id       = xhpc.inventory_item_id       --����(D�i�� = �{�Џ��i�敪)
      AND    ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --O�i��A�K�p��FROM-TO
      AND    iimb.item_id                 = ximb.item_id                 --����(O�i�� = O�i��A)
      AND    msib.segment1                = iimb.item_no                 --����(D�i�� = O�i��)
      AND    msib.segment1                = xsib.item_code               --����(D�i�� = D�i��A)
      AND    xesh.organization_id         = msib.organization_id         --����(����H = D�i�� �w�b�_�̑g�D�Ō�������)
      AND    xesl.inventory_item_id       = msib.inventory_item_id       --����(����L = D�i��)
      AND    xesh.header_id               = xesl.header_id               --����(����H = ����L)
      AND    xesh.customer_code           = hca.account_number           --����(����H = �ڋq)
      AND    NVL( mtrh.attribute1, cv_n ) = cv_n                         --���ɗ\��A�g�σt���O(���A�g)
      AND    xesh.move_order_header_id    = mtrh.header_id(+)            --����(����H = �ړ�H)
      AND    xesh.edi_send_flag           = cv_n                         --EDI���M�σt���O(�����M)
      AND    xesh.fix_flag                = cv_y                         --�m��σt���O(�m���)
      AND    xesh.edi_chain_code          = it_edi_c_code                --EDI�`�F�[���X�R�[�h
      AND    xesh.to_subinventory_code    = it_to_s_code                 --������ۊǏꏊ
      ORDER BY
             xesh.invoice_number  --�`�[�ԍ�����(A-4�œ`�[�ԍ����ɏ����������)
      FOR UPDATE OF
             xesh.header_id
            ,mtrh.header_id NOWAIT
      ;
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
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_expt THEN
      --�J�[�\���N���[�Y
      IF ( cust_item_cur%ISOPEN ) THEN
        CLOSE cust_item_cur;
      END IF;
      IF ( jan_item_cur%ISOPEN ) THEN
        CLOSE jan_item_cur;
      END IF;
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --�A�v���P�[�V����
                      ,iv_name         => cv_msg_tbale_tkn2  --���ɗ\��e�[�u��
                     );
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application     --�A�v���P�[�V����
                    ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                    ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name        --���ɗ\��e�[�u��
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
  END get_edi_stc_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line_cnt
   * Description      : ���׌����`�F�b�N����(A-12)
   ***********************************************************************************/
  PROCEDURE chk_line_cnt(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line_cnt'; -- �v���O������
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
    lv_invc_break         xxcos_edi_stc_headers.invoice_number%TYPE;  --�`�[�ԍ��u���[�N�p
    ln_header_id          xxcos_edi_stc_headers.header_id%TYPE;       --�u���C�N�O�̃w�b�_ID�ێ��p
    ln_db_cnt             NUMBER;                                     --���ɗ\�薾�ׂ̌���
    ln_line_cnt           NUMBER;                                     --A-3�Œ��o�������ׂ̌���
    lv_err_msg            VARCHAR2(5000);                             --���b�Z�[�W�i�[�p
    lv_chk_flag           VARCHAR2(1);                                --�G���[�`�F�b�N�t���O
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
    --����������
    lv_chk_flag := cv_0;
    ln_line_cnt := cn_0;
    ln_db_cnt   := cn_0;
--
    <<check_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      --���[�v�̏����ݒ�
--      IF ( i = cn_1 ) THEN
--        lv_invc_break := gt_edi_stc_date(i).invoice_number;
--        ln_header_id  := gt_edi_stc_date(i).header_id;
--      END IF;
----
--      --�`�[�ԍ����u���C�N�A�������͍ŏI�s�̏ꍇ
--      IF ( lv_invc_break <> gt_edi_stc_date(i).invoice_number )
--        OR ( i = gn_target_cnt )
--      THEN
--        -----------------------------
--        --�u���C�N�O�̃f�[�^�`�F�b�N
--        -----------------------------
--        IF ( lv_invc_break <> gt_edi_stc_date(i).invoice_number ) THEN
--          --�u���C�N�O�̖��׌����̎擾(����i�ڂ̓T�}��)
--          SELECT  COUNT( 1 )
--          INTO    ln_db_cnt
--          FROM    ( SELECT  1
--                    FROM    xxcos_edi_stc_lines   xesl
--                    WHERE   xesl.header_id = ln_header_id
--                    GROUP BY
--                          xesl.inventory_item_id
--                  )
--          ;
--          --�u���C�N�O�̓��ɗ\�薾�ׂ�A-3�Œ��o���ꂽ����(���o����Ȃ��������ׂ��Ȃ���)�̃`�F�b�N
--          IF ( ln_db_cnt <> ln_line_cnt ) THEN
--            --���b�Z�[�W�擾
--            lv_err_msg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_application       --�A�v���P�[�V����
--                           ,iv_name         => cv_msg_line_cnt_err  --���ɗ\��f�[�^�쐬�G���[
--                           ,iv_token_name1  => cv_tkn_invoice_num   --�g�[�N���R�[�h�P
--                           ,iv_token_value1 => lv_invc_break        --�`�[�ԍ�
--                          );
--            --���b�Z�[�W�ɏo��
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_msg
--            );
--            --�`�F�b�N�t���O��ύX����B
--            lv_chk_flag := cv_1;
--          END IF;
--        END IF;
--        -----------------------------
--        --�ŏI�s�̃f�[�^�`�F�b�N
--        -----------------------------
--        --�ŏI�s(�Ō�̓`�[�ԍ�)�̊m�F
--        IF ( i = gn_target_cnt ) THEN
--          --�Ō�s���O�s�Ɠ����`�[�ԍ��̏ꍇ
--          IF ( lv_invc_break = gt_edi_stc_date(i).invoice_number ) THEN
--            --�ŏI�s���o�f�[�^���������C���N�������g
--            ln_line_cnt := ln_line_cnt + cn_1;
--          ELSE
--            --�ŏI�s�̌����̂�
--            ln_line_cnt := cn_1;
--          END IF;
--          --�ŏI�s�̓`�[�ԍ��̖��׌����擾(����i�ڂ̓T�}��)
--          SELECT  COUNT( 1 )
--          INTO    ln_db_cnt
--          FROM    ( SELECT  1
--                    FROM    xxcos_edi_stc_lines   xesl
--                    WHERE   xesl.header_id = gt_edi_stc_date(i).header_id
--                    GROUP BY
--                            xesl.inventory_item_id
--                  )
--          ;
--          --�ŏI�s�̓��ɗ\�薾�ׂ�A-3�Œ��o���ꂽ����(���o����Ȃ��������ׂ��Ȃ���)�̃`�F�b�N
--          IF ( ln_db_cnt <> ln_line_cnt ) THEN
--            --���b�Z�[�W�擾
--            lv_err_msg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_application                     --�A�v���P�[�V����
--                           ,iv_name         => cv_msg_line_cnt_err                --���ɗ\��f�[�^�쐬�G���[
--                           ,iv_token_name1  => cv_tkn_invoice_num                 --�g�[�N���R�[�h�P
--                           ,iv_token_value1 => gt_edi_stc_date(i).invoice_number  --�`�[�ԍ�
--                          );
--            --���b�Z�[�W�ɏo��
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_msg
--            );
--          --�`�F�b�N�t���O��ύX����B
--          lv_chk_flag := cv_1;
--          END IF;
--        END IF;
--        --���׌����A�w�b�_ID�Ƀu���C�N���̒l��ݒ�
--        ln_line_cnt   := cn_1;
--        ln_header_id  := gt_edi_stc_date(i).header_id;
--        --�u���C�N�p�`�[�ԍ��ݒ�
--        lv_invc_break := gt_edi_stc_date(i).invoice_number;
--      ELSE
--        --���o�f�[�^�����̃C���N�������g
--        ln_line_cnt := ln_line_cnt + cn_1;
--      END IF;
      --�ڋq�i�ڂ�NULL�܂��́A
      --�ڋq�i��.�L���t���O�������܂��́A
      --�ڋq�i�ڑ��ݎQ��.�L���t���O�������̏ꍇ�G���[�Ƃ���B
      IF ( gt_edi_stc_date(i).customer_item_number IS NULL )
        OR ( gt_edi_stc_date(i).inactive_flag = cv_y ) 
        OR ( gt_edi_stc_date(i).inactive_ref_flag = cv_y ) 
      THEN
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                           --�A�v���P�[�V����
                       ,iv_name         => cv_msg_line_cnt_err                      --���ɗ\��f�[�^�쐬�G���[
                       ,iv_token_name1  => cv_tkn_invoice_num                       --�g�[�N���R�[�h�P
                       ,iv_token_value1 => gt_edi_stc_date(i).invoice_number        --�`�[�ԍ�
                       ,iv_token_name2  => cv_tkn_item_code                         --�g�[�N���R�[�h�Q
                       ,iv_token_value2 => gt_edi_stc_date(i).item_code             --�i�ڃR�[�h
                       ,iv_token_name3  => cv_tkn_cust_item_code                    --�g�[�N���R�[�h�R
                       ,iv_token_value3 => gt_edi_stc_date(i).customer_item_number  --�ڋq�i��
                      );
            --���b�Z�[�W�ɏo��
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_msg
            );
        --�`�F�b�N�t���O��ύX����B
        lv_chk_flag := cv_1;
      END IF;
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
--
    END LOOP check_loop;
--
    --�`�F�b�N�G���[������ꍇ�A�G���[�Ƃ���B
    IF ( lv_chk_flag <> cv_0 ) THEN
      gn_warn_cnt := gn_target_cnt;  --�X�L�b�v����(�S��)��ݒ�
      RAISE global_api_others_expt;
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
  END chk_line_cnt;
--
--#####################################  �Œ蕔 END   ##########################################
--
  /**********************************************************************************
   * Procedure Name   : edit_edi_stc_data
   * Description      : �f�[�^�ҏW(A-4,A-5,A-6)
   ***********************************************************************************/
  PROCEDURE edit_edi_stc_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_edi_stc_data'; -- �v���O������
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
    lv_invc_break         xxcos_edi_stc_headers.invoice_number%TYPE;  --�`�[�ԍ��u���[�N�p
    ln_line_no            NUMBER;                                     --�sNo�p
    lv_data_record        VARCHAR2(32767);                            --�ҏW��̃f�[�^�擾�p
    ln_seq                INTEGER := 0;                               --�Y��
    ln_invc_case_qty_sum  NUMBER;                                     --(�`�[�v)�P�[�X��
    ln_invc_indv_qty_sum  NUMBER;                                     --(�`�[�v)�o����
    ln_invc_ship_qty_sum  NUMBER;                                     --(�`�[�v)�o�א���(���v�A�o��)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;    --�o�̓f�[�^���
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
    <<output_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
--
      --==============================================================
      --�f�[�^�ҏW
      --==============================================================
      --�sNo�̕ҏW�A�`�[�n�̎擾�A�t���O�X�V�p�̓`�[�ԍ��擾
      IF ( lv_invc_break IS NULL )
        OR ( lv_invc_break <> gt_edi_stc_date(i).invoice_number )
      THEN
        --�u���[�N���̐ݒ�
        lv_invc_break                   := gt_edi_stc_date(i).invoice_number;  --�u���[�N�ϐ��ɒl��ݒ�
        ln_line_no                      := cn_1;                               --�sNo��1�ɖ߂�
        ln_seq                          := ln_seq + cn_1;                      --�Y���̕ҏW
        gt_invoice_num(ln_seq)          := gt_edi_stc_date(i).invoice_number;  --�X�V�p�ɓ`�[�ԍ���ێ�
        --�`�[�v�̎擾
        SELECT  SUM( xesl.case_qty ) invc_case_qty_sum  --(�`�[�v)�P�[�X��
               ,SUM( xesl.indv_qty ) invc_indv_qty_sum  --(�`�[�v)�o����
               ,SUM(
                  ( xesl.case_qty * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty
                )                    invc_ship_qty_sum  --(�`�[�v)�o�א���(���v�A�o��)
        INTO    ln_invc_case_qty_sum
               ,ln_invc_indv_qty_sum
               ,ln_invc_ship_qty_sum
        FROM    xxcos_edi_stc_lines   xesl
               ,mtl_system_items_b    msi
               ,ic_item_mst_b         iimb
               ,xxcmn_item_mst_b      ximb
        WHERE  ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )
        AND    iimb.item_id            = ximb.item_id
        AND    msi.segment1            = iimb.item_no
        AND    msi.organization_id     = gt_edi_stc_date(i).organization_id
        AND    msi.inventory_item_id   = xesl.inventory_item_id
        AND    xesl.header_id          = gt_edi_stc_date(i).header_id
        GROUP BY
               xesl.header_id
        ;
      ELSE
        ln_line_no                      := ln_line_no + cn_1;                  --�sNo�C���N�������g
      END IF;
      --���ʊ֐��p�̕ϐ��ɒl��ݒ�
      -- �w�b�_�� --
      l_data_tab(cv_medium_class)             := gt_edi_media_class;
      l_data_tab(cv_data_type_code)           := gt_data_type_code;
--********************  2009/07/08    1.5  N.Maeda MOD Start ********************
----********************  2009/06/15    1.5  N.Maeda MOD Start ********************
----      l_data_tab(cv_file_no)                  := TO_CHAR(NULL);
--      l_data_tab(cv_file_no)                  := TO_CHAR(gt_edi_stc_date(i).edi_forward_number);
      l_data_tab(cv_file_no)                  := gt_edi_f_number;
----********************  2009/06/15    1.5  N.Maeda MOD  End  ********************
--********************  2009/07/08    1.5  N.Maeda MOD  End  ********************
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;
      l_data_tab(cv_process_time)             := gv_f_o_time;
      l_data_tab(cv_base_code)                := gt_header_data.delivery_base_code;
      l_data_tab(cv_base_name)                := gt_header_data.delivery_base_name;
      l_data_tab(cv_base_name_alt)            := gt_header_data.delivery_base_phonetic;
      l_data_tab(cv_edi_chain_code)           := gt_edi_stc_date(i).edi_chain_code;
      l_data_tab(cv_edi_chain_name)           := gt_header_data.edi_chain_name;
      l_data_tab(cv_edi_chain_name_alt)       := gt_header_data.edi_chain_name_phonetic;
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := TO_CHAR(NULL);
      l_data_tab(cv_report_show_name)         := TO_CHAR(NULL);
      l_data_tab(cv_cust_code)                := gt_edi_stc_date(i).customer_code;
      l_data_tab(cv_cust_name)                := gt_edi_stc_date(i).customer_name;
      l_data_tab(cv_cust_name_alt)            := gt_edi_stc_date(i).customer_phonetic;
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      --�ړ��I�[�_�[�̃f�[�^�̏ꍇ
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
      l_data_tab(cv_line_no)                  := ln_line_no;
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
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).indv_qty );
      l_data_tab(cv_case_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).case_qty );
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
      l_data_tab(cv_gen_add_item2)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, 1, 10 );
      l_data_tab(cv_gen_add_item3)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, 11, 10 );
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
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR( ln_invc_indv_qty_sum );
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR( ln_invc_case_qty_sum );
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR( ln_invc_ship_qty_sum );
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
/* 2009/04/28 Ver1.4 Add Start */
      l_data_tab(cv_attribute)                := TO_CHAR(NULL);
/* 2009/04/28 Ver1.4 Add End   */
      --==============================================================
      --�f�[�^���^(A-5)
      --==============================================================
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
          iv_edit_data        =>  l_data_tab          --�o�̓f�[�^���
         ,iv_file_type        =>  cv_0                --�t�@�C���`��(�Œ蒷)
         ,iv_data_type_table  =>  gt_data_type_table  --���C�A�E�g��`���
         ,iv_record_type      =>  gv_if_data          --�f�[�^���R�[�h���ʎq
         ,ov_data_record      =>  lv_data_record      --�f�[�^���R�[�h
         ,ov_errbuf           =>  lv_errbuf           --�G���[���b�Z�[�W
         ,ov_retcode          =>  lv_retcode          --���^�[���R�[�h
         ,ov_errmsg           =>  lv_errmsg           --���[�U�E�G���[���b�Z�[�W
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      --�A�v���P�[�V����
                        ,iv_name         => cv_msg_out_inf_err  --�o�͏��ҏW�G���[
                        ,iv_token_name1  => cv_tkn_err_m        --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_errmsg           --���ʊ֐��̃G���[���b�Z�[�W
                       );
        RAISE global_api_expt;
      END;
      --==============================================================
      --�t�@�C���o��(A-6)
      --==============================================================
      --�f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --�t�@�C���n���h��
       ,buffer => lv_data_record  --�o�͕���(�f�[�^)
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
  END edit_edi_stc_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : �t�@�C���I������(A-7)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer'; -- �v���O������
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
/* 2009/04/28 Ver1.4 Start */
--    lv_footer_output  VARCHAR2(1000);  --�t�b�^�o�͗p
    lv_footer_output  VARCHAR2(5000);  --�t�b�^�o�͗p
/* 2009/04/28 Ver1.4 End   */
    lv_dummy1         VARCHAR2(1);     --IF���Ɩ��n��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy2         VARCHAR2(1);     --���_�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy3         VARCHAR2(1);     --���_����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy4         VARCHAR2(1);     --�`�F�[���X�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy5         VARCHAR2(1);     --�`�F�[���X����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy6         VARCHAR2(1);     --�f�[�^��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy7         VARCHAR2(1);     --���񏈗��ԍ�(�t�b�^�ł͎g�p���Ȃ�)
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
    --���ʊ֐��Ăяo��
    --==============================================================
    --EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_footer      --�t�^�敪
     ,iv_from_series     =>  lv_dummy1         --IF���Ɩ��n��R�[�h
     ,iv_base_code       =>  lv_dummy2         --���_�R�[�h
     ,iv_base_name       =>  lv_dummy3         --���_����
     ,iv_chain_code      =>  lv_dummy4         --�`�F�[���X�R�[�h
     ,iv_chain_name      =>  lv_dummy5         --�`�F�[���X����
     ,iv_data_kind       =>  lv_dummy6         --�f�[�^��R�[�h
     ,iv_row_number      =>  lv_dummy7         --���񏈗��ԍ�
     ,in_num_of_records  =>  gn_target_cnt     --���R�[�h����
     ,ov_retcode         =>  lv_retcode        --���^�[���R�[�h
     ,ov_output          =>  lv_footer_output  --�t�b�^���R�[�h
     ,ov_errbuf          =>  lv_errbuf         --�G���[���b�Z�[�W
     ,ov_errmsg          =>  lv_errmsg         --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�@�C���o��
    --==============================================================
    --�t�b�^�o��
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_footer_output  --�o�͕���(�t�b�^)
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
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : upd_edi_send_flag
   * Description      : �t���O�X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_edi_send_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_edi_send_flag'; -- �v���O������
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
    lv_tkn_name   VARCHAR2(50);  --�g�[�N���擾�p
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
      --�ړ��I�[�_�[�w�b�_�e�[�u���X�V
      FORALL i IN 1.. gt_invoice_num.count
--
       UPDATE mtl_txn_request_headers mtrh
       SET    mtrh.attribute1 = cv_y  --���ɗ\��A�g�σt���O
       WHERE  mtrh.header_id IN
                ( SELECT xesh.move_order_header_id
                  FROM   xxcos_edi_stc_headers xesh
                  WHERE  xesh.move_order_header_id IS NOT NULL
                  AND    xesh.invoice_number       = gt_invoice_num(i)
                );
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_tbale_tkn3  --�ړ��I�[�_�[�w�b�_�e�[�u��
                       );
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --�A�v���P�[�V����
                      ,iv_name         => cv_msg_upd_err  --�f�[�^�X�V�G���[
                      ,iv_token_name1  => cv_tkn_table_n  --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name     --�ړ��I�[�_�[�w�b�_�e�[�u��
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    BEGIN
      --���ɗ\��w�b�_�e�[�u���X�V
      FORALL i IN 1.. gt_invoice_num.count
--
        UPDATE  xxcos_edi_stc_headers xesh
        SET     xesh.edi_send_date           = cd_sysdate                 --EDI���M����
               ,xesh.edi_send_flag           = cv_y                       --EDI���M�ς݃t���O
               ,xesh.last_updated_by         = cn_last_updated_by         --�ŏI�X�V��
               ,xesh.last_update_date        = cd_last_update_date        --�ŏI�X�V��
               ,xesh.last_update_login       = cn_last_update_login       --�ŏI�X�V���O�C��
               ,xesh.request_id              = cn_request_id              --�v��ID
               ,xesh.program_application_id  = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,xesh.program_id              = cn_program_id              --�R���J�����g�E�v���O����ID
               ,xesh.program_update_date     = cd_program_update_date     --�v���O�����X�V��
        WHERE   xesh.invoice_number  = gt_invoice_num(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_tbale_tkn4  --���ɗ\��w�b�_�w�b�_�e�[�u��
                       );
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --�A�v���P�[�V����
                      ,iv_name         => cv_msg_upd_err  --�f�[�^�X�V�G���[
                      ,iv_token_name1  => cv_tkn_table_n  --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name     --�ړ��I�[�_�[�w�b�_�e�[�u��
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    COMMIT;  --�t�@�C���o�́A�t���O�̍X�V�܂ł��m�肳�����COMMIT
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
  END upd_edi_send_flag;
--
  /**********************************************************************************
   * Procedure Name   : del_edi_stc_data
   * Description      : ���ɗ\��p�[�W(A-9)
   ***********************************************************************************/
  PROCEDURE del_edi_stc_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_edi_stc_data'; -- �v���O������
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
    ld_term_date  DATE;          --�폜�Ώۓ��擾�p
    lv_tkn_name   VARCHAR2(50);  --�g�[�N���擾�p
--
    -- *** ���[�J���ETABLE�^***
    --���ɗ\��w�b�_ID �e�[�u���^
    TYPE l_edi_stc_h_id_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    l_edi_stc_h_id  l_edi_stc_h_id_ttype;
    --���ɗ\�薾��ID �e�[�u���^
    TYPE l_edi_stc_l_id_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    l_edi_stc_l_id  l_edi_stc_l_id_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
    --���ɗ\��w�b�_
    CURSOR del_header_cur
    IS
      SELECT xesh.rowid  row_id
      FROM   xxcos_edi_stc_headers xesh
      WHERE  xesh.edi_send_flag          = cv_y          --EDI���M�ς݃t���O(���M��)
      AND    TRUNC(xesh.edi_send_date)  <= ld_term_date  --�Ώۓ��ȑO
      FOR UPDATE OF
             xesh.header_id NOWAIT
      ;
    --���ɗ\�薾��
    CURSOR del_line_cur
    IS
      SELECT xesl.rowid row_id
      FROM   xxcos_edi_stc_lines xesl
      WHERE  xesl.header_id IN 
        ( SELECT xesh.header_id  header_id
          FROM   xxcos_edi_stc_headers xesh
          WHERE  xesh.edi_send_flag          = cv_y          --EDI���M�ς݃t���O(���M��)
          AND    TRUNC(xesh.edi_send_date)  <= ld_term_date  --�Ώۓ��ȑO
        ) --�w�b�_�̍폜����
      FOR UPDATE OF
             xesl.line_id NOWAIT
      ;
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
    --�폜�Ώۓ��̎擾
    --==============================================================
    ld_term_date := TRUNC( cd_sysdate ) - TO_NUMBER( gv_edi_p_term ); --�V�X�e�����t-EDI���폜����
--
    --==============================================================
    --���b�N����
    --==============================================================
    --���ɗ\��w�b�_�̃��b�N
    OPEN del_header_cur;
    FETCH del_header_cur BULK COLLECT INTO l_edi_stc_h_id;
    CLOSE del_header_cur;
    --���ɗ\�薾�ׂ̃��b�N
    OPEN del_line_cur;
    FETCH del_line_cur BULK COLLECT INTO l_edi_stc_l_id;
    CLOSE del_line_cur;
    --==============================================================
    --�p�[�W����
    --==============================================================
    BEGIN
      --���ɗ\��w�b�_�̃p�[�W
      FORALL i IN 1.. l_edi_stc_h_id.count
--
        DELETE FROM xxcos_edi_stc_headers xesh
        WHERE  xesh.rowid = l_edi_stc_h_id(i)
        ;
--
      --���ɗ\�薾�ׂ̃p�[�W
      FORALL i IN 1.. l_edi_stc_l_id.count
--
        DELETE FROM xxcos_edi_stc_lines xesl
        WHERE  xesl.rowid  = l_edi_stc_l_id(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --�A�v���P�[�V����
                        ,iv_name         => cv_msg_tbale_tkn2  --���ɗ\��e�[�u��
                       );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application    --�A�v���P�[�V����
                      ,iv_name         => cv_msg_purge_err  --�p�[�W�G���[
                      ,iv_token_name1  => cv_tkn_table      --�g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_name       --���ɗ\��e�[�u��
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_expt THEN
      --�J�[�\���N���[�Y
      IF ( del_header_cur%ISOPEN ) THEN
        CLOSE del_header_cur;
      END IF;
      IF ( del_line_cur%ISOPEN ) THEN
        CLOSE del_line_cur;
      END IF;
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --�A�v���P�[�V����
                      ,iv_name         => cv_msg_tbale_tkn2  --���ɗ\��e�[�u��
                     );
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application     --�A�v���P�[�V����
                    ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                    ,iv_token_name1  => cv_tkn_table_n     --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name        --���ɗ\��e�[�u��
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
  END del_edi_stc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name      IN  VARCHAR2,     --   1.�t�@�C����
    iv_to_s_code      IN  VARCHAR2,     --   2.������ۊǏꏊ
    iv_edi_c_code     IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number   IN  VARCHAR2,     --   4.EDI�`���ǔ�
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_no_target_msg      VARCHAR2(5000);  --�ΏۂȂ����b�Z�[�W�擾�p
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
    -- ��������(A-0,A-1)
    -- ===============================
    init(
      iv_file_name     -- �t�@�C����
     ,iv_to_s_code     -- ������ۊǏꏊ
     ,iv_edi_c_code    -- EDI�`�F�[���X�R�[�h
     ,iv_edi_f_number  -- EDI�`���ǔ�
     ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �t�@�C����������(A-2)
    -- ===============================
    output_header(
      iv_to_s_code     -- ������ۊǏꏊ
     ,iv_edi_c_code    -- EDI�`�F�[���X�R�[�h
     ,iv_edi_f_number  -- EDI�`���ǔ�
     ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
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
    -- ===============================
    -- ���ɗ\���񒊏o(A-3)
    -- ===============================
    get_edi_stc_data(
      iv_to_s_code     -- ������ۊǏꏊ
     ,iv_edi_c_code    -- EDI�`�F�[���X�R�[�h
     ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
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
    --�����Ώ۔���
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================
      -- ���׌����`�F�b�N����(A-12)
      -- ===============================
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      chk_line_cnt(
--        lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
--       ,lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
--       ,lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF (lv_retcode <> cv_status_normal) THEN
--        --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
--        IF ( UTL_FILE.IS_OPEN(
--               file => gt_f_handle
--             )
--           )
--        THEN
--          UTL_FILE.FCLOSE(
--            file => gt_f_handle
--          );
--        END IF;
--        RAISE global_process_expt;
--      END IF;
      --�ڋq�i�ڂ̏ꍇ
      IF ( gt_edi_item_code_div = cv_1 ) THEN
        chk_line_cnt(
          lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
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
      END IF;
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
      -- ===============================
      -- �f�[�^�ҏW(A-4)
      -- ===============================
      edit_edi_stc_data(
        lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
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
    --�ΏۂȂ�
    ELSE
      --���b�Z�[�W�擾
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     --�A�v���P�[�V����
                           ,iv_name         => cv_msg_no_target   --�p�����[�^�[�o��(�����ΏۂȂ�)
                          );
      --���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
    END IF;
    -- ===============================
    -- �t�@�C���I������(A-7)
    -- ===============================
    output_footer(
      lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --�t�@�C����OPEN����Ă���ꍇ�N���[�Y
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
    --�����Ώ۔���
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================
      -- �t���O�X�V(A-8)
      -- ===============================
      upd_edi_send_flag(
        lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- ===============================
    -- ���ɗ\��p�[�W(A-9)
    -- ===============================
    del_edi_stc_data(
      lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name    IN  VARCHAR2,      --   1.�t�@�C����
    iv_to_s_code    IN  VARCHAR2,      --   2.������ۊǏꏊ
    iv_edi_c_code   IN  VARCHAR2,      --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number IN  VARCHAR2       --   4.EDI�`���ǔ�
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
       iv_file_name     -- �t�@�C����
      ,iv_to_s_code     -- ������ۊǏꏊ
      ,iv_edi_c_code    -- EDI�`�F�[���X�R�[�h
      ,iv_edi_f_number  -- EDI�`���ǔ�
      ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCOS011A04C;
/
